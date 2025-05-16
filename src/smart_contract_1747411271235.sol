Okay, let's design a smart contract that goes beyond standard tokens, staking, or simple vaults. We'll create a "Quantum Vault" - leveraging the concept of quantum superposition and collapse as a metaphor for managing investment strategies with phases of uncertainty and commitment, incorporating elements of randomness, multi-asset handling, and dynamic parameters.

This concept avoids direct copies of well-known open-source protocols like Uniswap, Aave, Compound, standard ERC20/721 implementations, or basic staking/farming contracts. It focuses on a unique state management flow and combining different concepts (multi-asset, dynamic strategy, randomness).

**Outline and Function Summary**

**Contract Name:** `QuantumVault`

**Description:**
A complex vault designed to hold multiple types of assets (ERC20 and ERC721) and manage them through distinct strategic phases inspired by quantum mechanics:
1.  **Initial/Idle:** Ready to accept deposits or initiate a new strategy cycle.
2.  **Superposition:** Multiple potential investment strategies (Superposition States) are proposed and potentially voted upon. Assets are locked in the vault but not yet deployed into external protocols. Includes an option to use verifiable randomness (VRF) to influence state selection or outcome.
3.  **Active State:** One Superposition State is 'collapsed' (selected), and the vault attempts to execute the chosen strategy (e.g., deposit assets into approved external DeFi protocols). Assets are actively managed according to the selected strategy.
4.  **Collapsing:** A transition phase where the vault is withdrawing assets from external protocols to return to the Idle state.
5.  **Paused:** An emergency state where most operations are frozen.

**Core Concepts:**
*   **Multi-Asset Handling:** Manages both ERC20 tokens and ERC721 NFTs within a single vault context.
*   **Superposition States:** Defines multiple potential future strategies the vault *could* adopt.
*   **State Collapse:** The mechanism to choose and commit to one Superposition State, triggered by votes or randomness.
*   **Verifiable Randomness (VRF):** Integrates Chainlink VRF to add an unpredictable element to state selection or outcome influencing.
*   **Dynamic Fees:** Allows governance to set fee structures based on performance or state duration.
*   **Approved Protocols:** White-lists external smart contracts the vault is allowed to interact with for strategies.
*   **Governance Control:** Key parameters and state transitions are controlled by a governance address.

**State Machine:**
`Idle` -> `Superposition` (propose/vote/VRF request) -> `ActiveState` (execute/rebalance/exit) -> `Collapsing` -> `Idle`

**Key Data Structures:**
*   `SuperpositionState`: Struct containing strategy details, status, votes, VRF request ID if applicable.
*   `UserDeposit`: Struct tracking a user's deposited ERC20 balances (mapping token address to amount) and ERC721 token IDs (mapping token address to array of IDs).

**Function Categories & Summary:**

1.  **Vault Core & State Management:**
    *   `getVaultStatus()`: Returns the current operational status of the vault (enum).
    *   `proposeSuperpositionState(strategyDetails, collateralRatio)`: Allows governance to propose a new potential strategy, entering the `Superposition` phase if currently `Idle`.
    *   `voteOnSuperpositionState(stateId, support)`: Allows governance or potentially whitelisted voters to vote on a proposed state.
    *   `triggerSuperpositionCollapse(stateId)`: Allows governance to initiate the state collapse based on voting results or other criteria (or trigger VRF).
    *   `requestRandomnessForCollapse()`: Allows governance to request VRF randomness to influence state selection/collapse.
    *   `fulfillRandomness(requestId, randomWords)`: VRF callback function to receive random number(s).
    *   `executeStateAction(actionType, data)`: Allows governance to execute a specific action defined by the active state strategy (e.g., deposit into a protocol).
    *   `rebalanceCurrentState(rebalanceData)`: Allows governance to adjust assets within the active state's strategy.
    *   `exitCurrentState()`: Allows governance to start unwinding the active strategy, moving towards the `Collapsing` phase.

2.  **Asset Deposits & Withdrawals:**
    *   `depositERC20(tokenAddress, amount)`: Allows a user to deposit a specified amount of an approved ERC20 token. Requires prior approval.
    *   `depositERC721(tokenAddress, tokenId)`: Allows a user to deposit an approved ERC721 NFT. Requires prior approval.
    *   `withdrawERC20(tokenAddress, amount)`: Allows a user to withdraw their deposited ERC20 tokens when the vault is in `Idle` or `Paused` state.
    *   `withdrawERC721(tokenAddress, tokenId)`: Allows a user to withdraw their deposited ERC721 NFT when the vault is in `Idle` or `Paused` state.
    *   `claimYield()`: Allows users to claim harvested yield distributed back to the vault (yield handling simplified for this example).

3.  **Information Retrieval:**
    *   `getTotalERC20Holdings(tokenAddress)`: Returns the total amount of a specific ERC20 token held by the vault.
    *   `getERC721Holdings(tokenAddress)`: Returns the list of token IDs for a specific ERC721 token held by the vault.
    *   `getUserDepositDetails(userAddress)`: Returns the details of a user's total deposits.
    *   `getSuperpositionStateDetails(stateId)`: Returns the details of a specific proposed Superposition State.
    *   `getViewableSuperpositionStates()`: Returns a list of proposed Superposition States currently in consideration.
    *   `getCurrentActiveStateId()`: Returns the ID of the currently active strategy state.
    *   `getPendingYield(userAddress, tokenAddress)`: Returns the amount of a specific token yield pending for a user.

4.  **Governance & Configuration:**
    *   `setGovernanceAddress(newGovernance)`: Transfers governance control.
    *   `pauseContract()`: Puts the vault into the `Paused` state (emergency stop).
    *   `unpauseContract()`: Resumes operations from the `Paused` state (returns to `Idle`).
    *   `addApprovedAsset(assetType, assetAddress)`: Allows governance to whitelist ERC20/ERC721 tokens for deposit.
    *   `removeApprovedAsset(assetType, assetAddress)`: Allows governance to de-whitelist assets.
    *   `addApprovedStrategyProtocol(protocolAddress)`: Allows governance to whitelist external protocols for strategy execution.
    *   `removeApprovedStrategyProtocol(protocolAddress)`: Allows governance to de-whitelist protocols.
    *   `setDynamicFeeParameters(yieldPercentage, performanceFee)`: Sets parameters for dynamic fees on yield.

5.  **Utility:**
    *   `getVersion()`: Returns the contract version.

**Total Functions:** 28 (Exceeds 20)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for a simple governance representation
import {IVRFConsumerV2} from "@chainlink/contracts/src/v0.8/interfaces/IVRFConsumerV2.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// --- Outline and Function Summary ---
// Contract Name: QuantumVault
// Description: A complex vault managing multi-asset deposits (ERC20, ERC721) through
// phases inspired by quantum mechanics: Idle, Superposition (strategy proposal/voting/randomness),
// Active State (strategy execution), Collapsing (unwinding), Paused.
// Core Concepts: Multi-Asset, Superposition States, State Collapse, VRF Integration, Dynamic Fees, Approved Protocols, Governance.
// State Machine: Idle -> Superposition -> ActiveState -> Collapsing -> Idle -> Paused (and back)

// Key Data Structures:
// - SuperpositionState: Defines a potential strategy (ID, details, votes, VRF req ID, status).
// - UserDeposit: Tracks user's ERC20 balances and ERC721 token IDs.

// Function Categories & Summary (Total: 28 Functions):

// 1. Vault Core & State Management:
//    - getVaultStatus(): Returns current vault status (enum).
//    - proposeSuperpositionState(strategyDetails, collateralRatio): Governance proposes new state, enters Superposition.
//    - voteOnSuperpositionState(stateId, support): Vote on proposed state (governance/whitelisted).
//    - triggerSuperpositionCollapse(stateId): Governance triggers state selection/collapse based on votes/criteria.
//    - requestRandomnessForCollapse(): Governance requests VRF for state selection/influence.
//    - fulfillRandomness(requestId, randomWords): VRF callback to process random number(s).
//    - executeStateAction(actionType, data): Governance executes specific action for active state strategy.
//    - rebalanceCurrentState(rebalanceData): Governance adjusts assets within active state strategy.
//    - exitCurrentState(): Governance starts unwinding active strategy, moves to Collapsing.

// 2. Asset Deposits & Withdrawals:
//    - depositERC20(tokenAddress, amount): User deposits ERC20 (requires approval).
//    - depositERC721(tokenAddress, tokenId): User deposits ERC721 (requires approval).
//    - withdrawERC20(tokenAddress, amount): User withdraws ERC20 (only in Idle/Paused).
//    - withdrawERC721(tokenAddress, tokenId): User withdraws ERC721 (only in Idle/Paused).
//    - claimYield(): User claims accumulated yield.

// 3. Information Retrieval:
//    - getTotalERC20Holdings(tokenAddress): Total vault holdings of an ERC20.
//    - getERC721Holdings(tokenAddress): List of token IDs for an ERC721 in vault.
//    - getUserDepositDetails(userAddress): Details of user's total deposits.
//    - getSuperpositionStateDetails(stateId): Details of a specific proposed state.
//    - getViewableSuperpositionStates(): List of currently proposed states.
//    - getCurrentActiveStateId(): ID of the active strategy state.
//    - getPendingYield(userAddress, tokenAddress): Pending yield for a user in a specific token.

// 4. Governance & Configuration:
//    - setGovernanceAddress(newGovernance): Transfer governance ownership.
//    - pauseContract(): Emergency pause (governance).
//    - unpauseContract(): Unpause contract (governance).
//    - addApprovedAsset(assetType, assetAddress): Whitelist deposit assets (governance).
//    - removeApprovedAsset(assetType, assetAddress): De-whitelist assets (governance).
//    - addApprovedStrategyProtocol(protocolAddress): Whitelist external protocols for strategies (governance).
//    - removeApprovedStrategyProtocol(protocolAddress): De-whitelist protocols (governance).
//    - setDynamicFeeParameters(yieldPercentage, performanceFee): Set fee parameters (governance).

// 5. Utility:
//    - getVersion(): Returns contract version string.
// --- End of Outline and Summary ---


contract QuantumVault is Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    enum VaultStatus {
        Idle,           // Ready for deposits, no active strategy
        Superposition,  // Strategies are being proposed/voted on/randomness pending
        ActiveState,    // A specific strategy is being executed
        Collapsing,     // Actively unwinding the current strategy
        Paused          // Emergency pause
    }

    enum SuperpositionStateStatus {
        Proposed,      // State has been proposed
        VotingOpen,    // Voting is active
        RandomnessPending, // VRF requested for this state's selection/outcome
        VotingClosed,  // Voting ended, awaiting collapse
        Selected,      // This state was chosen for collapse
        Rejected,      // This state was not chosen
        Executed       // This state is now the ActiveState
    }

    struct SuperpositionState {
        uint256 id;
        bytes strategyDetails; // Encoded data specific to the strategy (e.g., target protocol, asset allocation)
        uint256 collateralRatioBps; // BPS (basis points) of vault value allocated to this strategy (max 10000)
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        uint256 positiveVotes;
        uint256 negativeVotes;
        SuperpositionStateStatus status;
        uint64 vrfRequestId; // Chainlink VRF request ID if randomness is used for this state
        uint256 selectionRandomness; // The random number received from VRF if used for selection
        uint256 creationTimestamp;
    }

    struct UserDeposit {
        mapping(address => uint256) erc20Balances; // tokenAddress => amount
        mapping(address => uint256[]) erc721TokenIds; // tokenAddress => array of token IDs
        address[] depositedERC721Tokens; // To keep track of which ERC721 addresses the user deposited
    }

    VaultStatus public currentVaultStatus;

    // --- Asset Management ---
    mapping(address => bool) public isApprovedERC20;
    mapping(address => bool) public isApprovedERC721;
    mapping(address => uint256) public totalERC20Holdings; // tokenAddress => total amount in vault
    mapping(address => uint256[]) public totalERC721Holdings; // tokenAddress => list of token IDs
    mapping(address => UserDeposit) public userDeposits; // userAddress => UserDeposit struct

    // --- State Management ---
    SuperpositionState[] public superpositionStates;
    uint256 public nextSuperpositionStateId = 1;
    uint256 public currentActiveStateId; // ID of the state currently being executed (0 if none)
    uint256 public minVoteThreshold = 5; // Minimum votes required to consider a state (example)
    uint258 public voteQuorumBps = 5000; // 50% quorum example (BPS) - % of total voting power

    // --- VRF Integration ---
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 s_callbackGasLimit;
    uint16 s_requestConfirmations;
    uint32 constant NUM_WORDS = 1; // Number of random words to request

    mapping(uint64 => uint256) public vrfRequestIdToStateId; // Map VRF request ID back to the superposition state ID

    // --- Strategy Execution ---
    mapping(address => bool) public isApprovedStrategyProtocol;

    // --- Dynamic Fees ---
    uint256 public yieldFeePercentage = 0; // Basis points (BPS), e.g., 1000 = 10%
    uint256 public performanceFee = 0; // Fixed fee amount (example, could be token-specific)

    // --- Events ---
    event VaultStatusChanged(VaultStatus indexed oldStatus, VaultStatus indexed newStatus);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed token, uint256 tokenId);
    event ERC20Withdrawal(address indexed user, address indexed token, uint256 amount);
    event ERC721Withdrawal(address indexed user, address indexed token, uint252 tokenId);
    event YieldClaimed(address indexed user, address indexed token, uint256 amount);
    event SuperpositionStateProposed(uint256 indexed stateId, address indexed proposer, bytes strategyDetails);
    event SuperpositionStateVoted(uint256 indexed stateId, address indexed voter, bool support);
    event SuperpositionCollapseTriggered(uint256 indexed selectedStateId);
    event SuperpositionCollapseRandomnessRequested(uint256 indexed stateId, uint64 indexed requestId);
    event SuperpositionCollapseRandomnessReceived(uint64 indexed requestId, uint256 indexed randomWord, uint256 stateId);
    event ActiveStateActionExecuted(uint256 indexed stateId, bytes actionType, bytes data);
    event ActiveStateRebalanced(uint256 indexed stateId, bytes rebalanceData);
    event ActiveStateExited(uint256 indexed stateId);
    event AssetApproved(uint256 assetType, address assetAddress, bool approved); // assetType: 0=ERC20, 1=ERC721
    event ProtocolApproved(address indexed protocolAddress, bool approved);
    event DynamicFeeParametersSet(uint256 yieldPercentage, uint256 performanceFee);

    // --- Modifiers ---
    modifier whenStatus(VaultStatus status) {
        require(currentVaultStatus == status, "QuantumVault: Incorrect status");
        _;
    }

    modifier notWhenStatus(VaultStatus status) {
        require(currentVaultStatus != status, "QuantumVault: Invalid status");
        _;
    }

    modifier whenNotPaused() {
        require(currentVaultStatus != VaultStatus.Paused, "QuantumVault: Paused");
        _;
    }

    modifier whenPaused() {
        require(currentVaultStatus == VaultStatus.Paused, "QuantumVault: Not paused");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == owner(), "QuantumVault: Only governance"); // Using Ownable's owner for simplicity
        _;
    }

    // --- Constructor ---
    constructor(
        address initialGovernance,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint16 requestConfirmations
    ) Ownable(initialGovernance) VRFConsumerBaseV2(vrfCoordinator) {
        currentVaultStatus = VaultStatus.Idle;
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
    }

    // --- 1. Vault Core & State Management ---

    function getVaultStatus() public view returns (VaultStatus) {
        return currentVaultStatus;
    }

    /// @notice Allows governance to propose a new strategy, moving to Superposition.
    /// @param strategyDetails Encoded details of the proposed strategy.
    /// @param collateralRatioBps The percentage (in BPS) of total vault value to commit to this strategy.
    function proposeSuperpositionState(bytes memory strategyDetails, uint256 collateralRatioBps)
        public
        onlyGovernance
        whenStatus(VaultStatus.Idle)
    {
        require(collateralRatioBps > 0 && collateralRatioBps <= 10000, "QuantumVault: Invalid collateral ratio");

        uint256 stateId = nextSuperpositionStateId++;
        superpositionStates.push(SuperpositionState({
            id: stateId,
            strategyDetails: strategyDetails,
            collateralRatioBps: collateralRatioBps,
            positiveVotes: 0,
            negativeVotes: 0,
            status: SuperpositionStateStatus.Proposed,
            vrfRequestId: 0,
            selectionRandomness: 0,
            creationTimestamp: block.timestamp
        }));

        // Transition to Superposition state
        VaultStatus oldStatus = currentVaultStatus;
        currentVaultStatus = VaultStatus.Superposition;
        emit VaultStatusChanged(oldStatus, currentVaultStatus);
        emit SuperpositionStateProposed(stateId, msg.sender, strategyDetails);
    }

    /// @notice Allows governance (or potentially whitelisted voters) to vote on a proposed state.
    /// Voting power could be based on deposits or another system (simplified here).
    /// @param stateId The ID of the state to vote on.
    /// @param support True for yes, false for no.
    function voteOnSuperpositionState(uint256 stateId, bool support)
        public
        onlyGovernance // Simplified: only governance can vote. Could be extended to users based on deposits.
        whenStatus(VaultStatus.Superposition)
    {
        require(stateId > 0 && stateId < nextSuperpositionStateId, "QuantumVault: Invalid state ID");
        SuperpositionState storage state = superpositionStates[stateId - 1]; // Adjust for 0-based array index

        require(state.status == SuperpositionStateStatus.Proposed || state.status == SuperpositionStateStatus.VotingOpen, "QuantumVault: State not open for voting");
        require(!state.hasVoted[msg.sender], "QuantumVault: Already voted");

        // If voting is just starting for this state, update status
        if (state.status == SuperpositionStateStatus.Proposed) {
             state.status = SuperpositionStateStatus.VotingOpen;
        }

        state.hasVoted[msg.sender] = true;
        if (support) {
            state.positiveVotes++;
        } else {
            state.negativeVotes++;
        }

        emit SuperpositionStateVoted(stateId, msg.sender, support);
    }

    /// @notice Allows governance to trigger the collapse to an ActiveState.
    /// Logic for selecting the state can vary (e.g., based on votes, or trigger randomness).
    /// @param stateId The ID of the state to trigger collapse for (could be 0 to trigger VRF if configured).
    function triggerSuperpositionCollapse(uint256 stateId)
        public
        onlyGovernance
        whenStatus(VaultStatus.Superposition)
    {
         require(stateId > 0 && stateId < nextSuperpositionStateId, "QuantumVault: Invalid state ID");
         SuperpositionState storage state = superpositionStates[stateId - 1];

         require(state.status == SuperpositionStateStatus.Proposed || state.status == SuperpositionStateStatus.VotingOpen || state.status == SuperpositionStateStatus.VotingClosed, "QuantumVault: State not ready for collapse");

         // --- Collapse Logic (Example) ---
         // This is simplified. A real contract might have complex voting thresholds,
         // tie-breaking, or mandatory VRF after a certain time/quorum.

         // Option 1: Direct selection by Governance (needs specific governance logic)
         // Example: Require minimum votes and positive majority, then governance can select.
         // require(state.positiveVotes + state.negativeVotes >= minVoteThreshold, "QuantumVault: Not enough votes");
         // require(state.positiveVotes > state.negativeVotes, "QuantumVault: State did not get majority support");
         // require(stateId == some logic selected state, "QuantumVault: Invalid state selection");

         // Option 2: Trigger VRF for this state's selection/outcome
         if (state.status != SuperpositionStateStatus.RandomnessPending && state.vrfRequestId == 0) {
             uint64 requestId = requestRandomness(s_keyHash, s_subscriptionId, s_requestConfirmations, s_callbackGasLimit, NUM_WORDS);
             state.vrfRequestId = requestId;
             state.status = SuperpositionStateStatus.RandomnessPending;
             vrfRequestIdToStateId[requestId] = stateId;
             emit SuperpositionCollapseRandomnessRequested(stateId, requestId);
             return; // Wait for VRF fulfillment
         }

         // Option 3: Collapse based on votes *after* potential randomness/voting period ended
         // Simplified: Just set the state as Selected. A real implementation needs selection logic.
         // This assumes 'stateId' is somehow determined by vote outcome or randomness already processed
         // or governance forcefully picking.
         require(state.status != SuperpositionStateStatus.Selected && state.status != SuperpositionStateStatus.Executed, "QuantumVault: State already selected or executed");

         state.status = SuperpositionStateStatus.Selected;
         currentActiveStateId = stateId;

         // Mark other proposed states as Rejected (simplified: just loop through others)
         for(uint i = 0; i < superpositionStates.length; i++) {
             if (superpositionStates[i].id != stateId &&
                 (superpositionStates[i].status == SuperpositionStateStatus.Proposed ||
                  superpositionStates[i].status == SuperpositionStateStatus.VotingOpen ||
                  superpositionStates[i].status == SuperpositionStateStatus.VotingClosed)) {
                 superpositionStates[i].status = SuperpositionStateStatus.Rejected;
             }
         }

         // Transition to ActiveState
         VaultStatus oldStatus = currentVaultStatus;
         currentVaultStatus = VaultStatus.ActiveState;
         emit VaultStatusChanged(oldStatus, currentVaultStatus);
         emit SuperpositionCollapseTriggered(stateId);
    }

     /// @notice Request randomness for a specific superposition state.
     /// This function might be called by triggerSuperpositionCollapse internally or directly
     /// by governance depending on the desired flow.
     function requestRandomnessForCollapse()
        public
        onlyGovernance
        whenStatus(VaultStatus.Superposition)
     {
         // Find the state that triggered the randomness request if needed, or request general randomness.
         // This implementation assumes randomness is tied to a specific state's selection/outcome.
         // A more complex implementation could have randomness select *which* state wins.
         // For simplicity, let's assume this function is a step *before* triggerSuperpositionCollapse selects the winner
         // based *partially* on this randomness. Or it influences an *outcome* within a pre-selected state.

         // Example: Find a state awaiting randomness (simplified)
         uint256 stateIdAwaitingRandomness = 0;
         for(uint i = 0; i < superpositionStates.length; i++) {
             if (superpositionStates[i].status == SuperpositionStateStatus.VotingClosed && superpositionStates[i].vrfRequestId == 0) {
                  stateIdAwaitingRandomness = superpositionStates[i].id;
                  break; // Found one
             }
         }

         require(stateIdAwaitingRandomness > 0, "QuantumVault: No state awaiting randomness request");

         uint64 requestId = requestRandomness(s_keyHash, s_subscriptionId, s_requestConfirmations, s_callbackGasLimit, NUM_WORDS);
         SuperpositionState storage state = superpositionStates[stateIdAwaitingRandomness - 1];
         state.vrfRequestId = requestId;
         state.status = SuperpositionStateStatus.RandomnessPending;
         vrfRequestIdToStateId[requestId] = stateIdAwaitingRandomness;
         emit SuperpositionCollapseRandomnessRequested(stateIdAwaitingRandomness, requestId);
     }


    /// @notice Callback function for Chainlink VRF. Processes the random result.
    function fulfillRandomness(uint64 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 stateId = vrfRequestIdToStateId[requestId];
        if (stateId == 0) {
            // This request ID wasn't for a known state, or was already processed. Ignore.
            return;
        }
        delete vrfRequestIdToStateId[requestId]; // Prevent double processing

        uint256 randomNumber = randomWords[0]; // Use the first random number

        require(stateId > 0 && stateId < nextSuperpositionStateId, "QuantumVault: Invalid state ID from VRF request");
        SuperpositionState storage state = superpositionStates[stateId - 1];

        require(state.status == SuperpositionStateStatus.RandomnessPending, "QuantumVault: State not awaiting randomness");
        require(state.vrfRequestId == requestId, "QuantumVault: VRF Request ID mismatch");

        state.selectionRandomness = randomNumber;
        state.status = SuperpositionStateStatus.VotingClosed; // Move to closed, governance can then call triggerCollapse

        // Note: The actual collapse/selection logic using this randomness happens in triggerSuperpositionCollapse
        // or a separate function called by governance *after* randomness is fulfilled.
        // This callback just provides the random number.

        emit SuperpositionCollapseRandomnessReceived(requestId, randomNumber, stateId);
    }


    /// @notice Allows governance to execute a specific action defined by the active state strategy.
    /// This function would contain the logic to interact with approved external protocols.
    /// @param actionType Identifier for the type of action (e.g., "deposit", "invest").
    /// @param data Encoded parameters for the specific action.
    function executeStateAction(bytes memory actionType, bytes memory data)
        public
        onlyGovernance
        whenStatus(VaultStatus.ActiveState)
        nonReentrant // Crucial if interacting with external protocols
    {
        require(currentActiveStateId > 0 && currentActiveStateId < nextSuperpositionStateId, "QuantumVault: No active state set");
        SuperpositionState storage activeState = superpositionStates[currentActiveStateId - 1];
        require(activeState.status == SuperpositionStateStatus.Executed, "QuantumVault: Active state not marked as Executed yet");

        // --- Placeholder for external protocol interaction logic ---
        // Example: Decode actionType and data to determine which approved protocol to call
        // and with what parameters.
        // address targetProtocol = ...; // Get from strategyDetails or data
        // require(isApprovedStrategyProtocol[targetProtocol], "QuantumVault: Target protocol not approved");
        // (bool success, bytes memory result) = targetProtocol.call(data);
        // require(success, string(result)); // Check external call success

        // In a real system, this would handle depositing assets into yield farms, lending protocols, etc.
        // based on the specific strategy defined in `activeState.strategyDetails`.

        // For this example, we just emit an event.
        emit ActiveStateActionExecuted(currentActiveStateId, actionType, data);
    }

    /// @notice Allows governance to rebalance assets within the active strategy.
    /// Similar to executeStateAction, this interacts with approved protocols.
    /// @param rebalanceData Encoded parameters for the rebalancing action.
    function rebalanceCurrentState(bytes memory rebalanceData)
        public
        onlyGovernance
        whenStatus(VaultStatus.ActiveState)
        nonReentrant // Crucial if interacting with external protocols
    {
        require(currentActiveStateId > 0 && currentActiveStateId < nextSuperpositionStateId, "QuantumVault: No active state set");

        // --- Placeholder for external protocol rebalancing logic ---
        // This would handle adjusting positions within the strategy.
        // Example: Selling one asset to buy another, moving between different yield pools.

        emit ActiveStateRebalanced(currentActiveStateId, rebalanceData);
    }

    /// @notice Allows governance to start unwinding the current strategy, moving towards Idle.
    /// This involves withdrawing assets from external protocols.
    function exitCurrentState()
        public
        onlyGovernance
        whenStatus(VaultStatus.ActiveState)
        nonReentrant // Crucial if interacting with external protocols
    {
        require(currentActiveStateId > 0 && currentActiveStateId < nextSuperpositionStateId, "QuantumVault: No active state set");

        // --- Placeholder for external protocol withdrawal logic ---
        // This would handle withdrawing assets from yield farms, lending protocols, etc.
        // It might take time depending on the external protocol.
        // Once assets are back in the vault, governance would transition to Idle.

        VaultStatus oldStatus = currentVaultStatus;
        currentVaultStatus = VaultStatus.Collapsing; // Transition to Collapsing
        emit VaultStatusChanged(oldStatus, currentVaultStatus);
        emit ActiveStateExited(currentActiveStateId);

        // After assets are fully unwound (which might require multiple external calls
        // managed off-chain or by another helper contract), governance would manually
        // call a function (e.g., `transitionToIdleAfterCollapse`) to move back to Idle.
        // For simplicity, let's add a placeholder for that transition.
    }

    /// @notice Placeholder: Governance manually confirms collapse is complete and transitions to Idle.
    /// A real system might verify balances before allowing this.
    function transitionToIdleAfterCollapse()
        public
        onlyGovernance
        whenStatus(VaultStatus.Collapsing)
    {
        currentActiveStateId = 0; // No active state anymore
        // Reset superposition states status? Or keep history? Decide based on needs.
        // For simplicity, let's not clear history here.

        VaultStatus oldStatus = currentVaultStatus;
        currentVaultStatus = VaultStatus.Idle; // Transition to Idle
        emit VaultStatusChanged(oldStatus, currentVaultStatus);
    }


    // --- 2. Asset Deposits & Withdrawals ---

    /// @notice Allows a user to deposit an approved ERC20 token.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to deposit.
    function depositERC20(address tokenAddress, uint256 amount)
        public
        whenNotPaused
        notWhenStatus(VaultStatus.Collapsing) // Don't allow new deposits while collapsing
    {
        require(isApprovedERC20[tokenAddress], "QuantumVault: ERC20 asset not approved");
        require(amount > 0, "QuantumVault: Amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        userDeposits[msg.sender].erc20Balances[tokenAddress] += amount;
        totalERC20Holdings[tokenAddress] += amount;

        emit ERC20Deposited(msg.sender, tokenAddress, amount);
    }

    /// @notice Allows a user to deposit an approved ERC721 NFT.
    /// @param tokenAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the token to deposit.
    function depositERC721(address tokenAddress, uint256 tokenId)
        public
        whenNotPaused
        notWhenStatus(VaultStatus.Collapsing) // Don't allow new deposits while collapsing
    {
        require(isApprovedERC721[tokenAddress], "QuantumVault: ERC721 asset not approved");

        IERC721 token = IERC721(tokenAddress);
        // Transfer ownership to the vault
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        // Check if this is the first time the user deposits this ERC721 type
        bool tokenTypeFound = false;
        for (uint i = 0; i < userDeposits[msg.sender].depositedERC721Tokens.length; i++) {
            if (userDeposits[msg.sender].depositedERC721Tokens[i] == tokenAddress) {
                tokenTypeFound = true;
                break;
            }
        }
        if (!tokenTypeFound) {
             userDeposits[msg.sender].depositedERC721Tokens.push(tokenAddress);
        }

        userDeposits[msg.sender].erc721TokenIds[tokenAddress].push(tokenId);
        totalERC721Holdings[tokenAddress].push(tokenId);

        emit ERC721Deposited(msg.sender, tokenAddress, tokenId);
    }

    /// @notice Allows a user to withdraw their deposited ERC20 tokens.
    /// Only allowed when the vault is Idle or Paused (assets are not deployed).
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount)
        public
        nonReentrant // Standard security for withdrawal
        whenStatus(VaultStatus.Idle) // Only allowed when Idle
        // Can add OR whenStatus(VaultStatus.Paused) if withdrawals are safe in Paused
    {
        require(isApprovedERC20[tokenAddress], "QuantumVault: ERC20 asset not approved");
        require(amount > 0, "QuantumVault: Amount must be greater than 0");
        require(userDeposits[msg.sender].erc20Balances[tokenAddress] >= amount, "QuantumVault: Insufficient deposit balance");

        userDeposits[msg.sender].erc20Balances[tokenAddress] -= amount;
        totalERC20Holdings[tokenAddress] -= amount;

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);

        emit ERC20Withdrawal(msg.sender, tokenAddress, amount);
    }

     /// @notice Allows a user to withdraw their deposited ERC721 NFT.
     /// Only allowed when the vault is Idle or Paused (assets are not deployed).
     /// @param tokenAddress The address of the ERC721 contract.
     /// @param tokenId The ID of the token to withdraw.
    function withdrawERC721(address tokenAddress, uint256 tokenId)
        public
        nonReentrant // Standard security
        whenStatus(VaultStatus.Idle) // Only allowed when Idle
        // Can add OR whenStatus(VaultStatus.Paused)
    {
        require(isApprovedERC721[tokenAddress], "QuantumVault: ERC721 asset not approved");

        // Find the token ID in the user's deposit list and remove it
        uint256[] storage userTokenIds = userDeposits[msg.sender].erc721TokenIds[tokenAddress];
        bool found = false;
        for (uint i = 0; i < userTokenIds.length; i++) {
            if (userTokenIds[i] == tokenId) {
                // Swap with last and pop (efficient removal)
                userTokenIds[i] = userTokenIds[userTokenIds.length - 1];
                userTokenIds.pop();
                found = true;
                break;
            }
        }
        require(found, "QuantumVault: User does not own this NFT in the vault");

        // Find the token ID in the vault's total holdings list and remove it
        uint256[] storage totalTokenIds = totalERC721Holdings[tokenAddress];
         found = false; // Reset found flag for vault holdings
         for (uint i = 0; i < totalTokenIds.length; i++) {
             if (totalTokenIds[i] == tokenId) {
                 totalTokenIds[i] = totalTokenIds[totalTokenIds.length - 1];
                 totalTokenIds.pop();
                 found = true;
                 break;
             }
         }
         // Should always be found if found in user's list, but defensive check
         require(found, "QuantumVault: NFT not found in vault holdings (internal error)");


        IERC721(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit ERC721Withdrawal(msg.sender, tokenAddress, tokenId);
    }

    /// @notice Allows users to claim accumulated yield.
    /// Yield distribution mechanism is simplified; this function just acts as a claim entry point.
    function claimYield() public {
        // --- Placeholder for actual yield calculation and distribution ---
        // In a real system, harvested yield tokens would be held by the vault,
        // and a calculation would determine how much yield each user is owed
        // based on their share of deposits and the duration of deposit during yield generation.

        // Example: Claiming a specific reward token (WETH in this case)
        address rewardToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Example WETH address
        uint256 pendingAmount = getPendingYield(msg.sender, rewardToken); // Need logic for this view function

        require(pendingAmount > 0, "QuantumVault: No pending yield to claim");

        // Reset pending yield for the user (internal logic needed)
        // userPendingYield[msg.sender][rewardToken] = 0;

        // Transfer the yield tokens
        // IERC20(rewardToken).safeTransfer(msg.sender, pendingAmount);

        // Emit event (using placeholder values)
        emit YieldClaimed(msg.sender, rewardToken, pendingAmount);
    }

    // --- 3. Information Retrieval ---

    /// @notice Returns the total amount of a specific ERC20 token held by the vault.
    function getTotalERC20Holdings(address tokenAddress) public view returns (uint256) {
        return totalERC20Holdings[tokenAddress];
    }

    /// @notice Returns the list of token IDs for a specific ERC721 token held by the vault.
    function getERC721Holdings(address tokenAddress) public view returns (uint256[] memory) {
        return totalERC721Holdings[tokenAddress];
    }

    /// @notice Returns the details of a user's total deposits.
    /// Note: This returns copies of mappings, which can be inefficient for large data.
    /// For production, consider paginated retrieval or separate functions for specific tokens.
    function getUserDepositDetails(address userAddress) public view returns (address[] memory erc20Tokens, uint256[] memory erc20Amounts, address[] memory erc721Tokens, uint256[][] memory erc721TokenIdsList) {
        // Retrieve ERC20s
        address[] memory _erc20Tokens = new address[](0);
        uint256[] memory _erc20Amounts = new uint256[](0);
        // Iterating mapping keys is not standard in Solidity. You need a list of deposited tokens.
        // Let's assume we add a list of deposited ERC20 token addresses per user or globally.
        // For this example, we'll return empty lists for ERC20. A real contract would need a helper mapping or list.

        // Retrieve ERC721s
        UserDeposit storage user = userDeposits[userAddress];
        address[] memory _erc721Tokens = new address[](user.depositedERC721Tokens.length);
        uint256[][] memory _erc721TokenIdsList = new uint256[][](user.depositedERC721Tokens.length);

        for (uint i = 0; i < user.depositedERC721Tokens.length; i++) {
            address tokenAddr = user.depositedERC721Tokens[i];
            _erc721Tokens[i] = tokenAddr;
            _erc721TokenIdsList[i] = user.erc721TokenIds[tokenAddr]; // Copies the array
        }

         // Placeholder for ERC20s: Need a better way to list deposited ERC20 tokens per user
        address[] memory actualERC20Tokens = new address[](0); // Example: ERC20 iteration not implemented
        uint256[] memory actualERC20Amounts = new uint256[](0); // Example: ERC20 iteration not implemented


        return (actualERC20Tokens, actualERC20Amounts, _erc721Tokens, _erc721TokenIdsList);
    }

     /// @notice Returns the details of a specific proposed Superposition State.
     /// @param stateId The ID of the state.
    function getSuperpositionStateDetails(uint256 stateId)
        public
        view
        returns (
            uint256 id,
            bytes memory strategyDetails,
            uint256 collateralRatioBps,
            uint256 positiveVotes,
            uint256 negativeVotes,
            SuperpositionStateStatus status,
            uint64 vrfRequestId,
            uint256 selectionRandomness,
            uint256 creationTimestamp
        )
    {
        require(stateId > 0 && stateId < nextSuperpositionStateId, "QuantumVault: Invalid state ID");
        SuperpositionState storage state = superpositionStates[stateId - 1]; // Adjust for 0-based array index

        return (
            state.id,
            state.strategyDetails,
            state.collateralRatioBps,
            state.positiveVotes,
            state.negativeVotes,
            state.status,
            state.vrfRequestId,
            state.selectionRandomness,
            state.creationTimestamp
        );
    }

    /// @notice Returns a list of proposed Superposition States currently in consideration.
    /// Does not return details of states that have already been Selected, Rejected, or Executed.
    function getViewableSuperpositionStates()
        public
        view
        returns (uint256[] memory stateIds)
    {
        uint256[] memory _stateIds = new uint256[](superpositionStates.length);
        uint256 count = 0;
        for (uint i = 0; i < superpositionStates.length; i++) {
            SuperpositionStateStatus status = superpositionStates[i].status;
            if (status == SuperpositionStateStatus.Proposed ||
                status == SuperpositionStateStatus.VotingOpen ||
                status == SuperpositionStateStatus.RandomnessPending ||
                status == SuperpositionStateStatus.VotingClosed)
            {
                _stateIds[count] = superpositionStates[i].id;
                count++;
            }
        }
        assembly {
            mstore(stateIds, count) // Set array length
            mstore(add(stateIds, 0x20), _stateIds) // Copy data
        }
    }


    /// @notice Returns the ID of the currently active strategy state.
    function getCurrentActiveStateId() public view returns (uint256) {
        return currentActiveStateId;
    }

    /// @notice Returns the amount of a specific token yield pending for a user.
    /// Placeholder: Actual calculation logic is needed.
    function getPendingYield(address userAddress, address tokenAddress) public view returns (uint256) {
        // --- Placeholder for yield calculation ---
        // This would query internal state or perform calculation based on
        // user's deposit history and the yield generated during the active state.
        // For now, returns 0.
        userAddress; tokenAddress; // Suppress unused variable warnings
        return 0;
    }


    // --- 4. Governance & Configuration ---

    /// @notice Transfers governance ownership.
    /// @param newGovernance The address of the new governance account.
    function setGovernanceAddress(address newGovernance) public onlyGovernance {
        transferOwnership(newGovernance); // Using Ownable's transferOwnership
    }

    /// @notice Puts the vault into the Paused state (emergency stop).
    function pauseContract() public onlyGovernance whenNotPaused {
        VaultStatus oldStatus = currentVaultStatus;
        currentVaultStatus = VaultStatus.Paused;
        emit VaultStatusChanged(oldStatus, currentVaultStatus);
    }

    /// @notice Resumes operations from the Paused state (returns to Idle).
    function unpauseContract() public onlyGovernance whenPaused {
        VaultStatus oldStatus = currentVaultStatus;
        currentVaultStatus = VaultStatus.Idle; // Returns to Idle after unpausing
        emit VaultStatusChanged(oldStatus, currentVaultStatus);
    }

    /// @notice Allows governance to whitelist ERC20 or ERC721 tokens for deposit.
    /// @param assetType 0 for ERC20, 1 for ERC721.
    /// @param assetAddress The address of the asset contract.
    function addApprovedAsset(uint256 assetType, address assetAddress) public onlyGovernance {
        if (assetType == 0) { // ERC20
            require(!isApprovedERC20[assetAddress], "QuantumVault: ERC20 already approved");
            isApprovedERC20[assetAddress] = true;
        } else if (assetType == 1) { // ERC721
            require(!isApprovedERC721[assetAddress], "QuantumVault: ERC721 already approved");
            isApprovedERC721[assetAddress] = true;
        } else {
            revert("QuantumVault: Invalid asset type");
        }
        emit AssetApproved(assetType, assetAddress, true);
    }

     /// @notice Allows governance to de-whitelist ERC20 or ERC721 tokens.
     /// Does not affect assets already deposited. Withdrawals of delisted assets might be restricted or require special handling.
     /// @param assetType 0 for ERC20, 1 for ERC721.
     /// @param assetAddress The address of the asset contract.
    function removeApprovedAsset(uint256 assetType, address assetAddress) public onlyGovernance {
         if (assetType == 0) { // ERC20
             require(isApprovedERC20[assetAddress], "QuantumVault: ERC20 not approved");
             isApprovedERC20[assetAddress] = false;
         } else if (assetType == 1) { // ERC721
             require(isApprovedERC721[assetAddress], "QuantumVault: ERC721 not approved");
             isApprovedERC721[assetAddress] = false;
         } else {
             revert("QuantumVault: Invalid asset type");
         }
         emit AssetApproved(assetType, assetAddress, false);
    }

    /// @notice Allows governance to whitelist external smart contracts for strategy execution.
    /// @param protocolAddress The address of the external protocol contract.
    function addApprovedStrategyProtocol(address protocolAddress) public onlyGovernance {
        require(!isApprovedStrategyProtocol[protocolAddress], "QuantumVault: Protocol already approved");
        isApprovedStrategyProtocol[protocolAddress] = true;
        emit ProtocolApproved(protocolAddress, true);
    }

    /// @notice Allows governance to de-whitelist external strategy protocols.
    /// Should not be called while an active strategy is using this protocol.
    /// @param protocolAddress The address of the external protocol contract.
    function removeApprovedStrategyProtocol(address protocolAddress) public onlyGovernance {
        require(isApprovedStrategyProtocol[protocolAddress], "QuantumVault: Protocol not approved");
        // Add check: require(currentActiveStateId == 0 || !isProtocolUsedInActiveState(protocolAddress), ...)
        // (Need a helper function isProtocolUsedInActiveState if strategyDetails contain protocol addresses)
        isApprovedStrategyProtocol[protocolAddress] = false;
        emit ProtocolApproved(protocolAddress, false);
    }

    /// @notice Sets parameters for dynamic fees.
    /// @param yieldPercentageBps Fee percentage on harvested yield (in basis points).
    /// @param performanceFeeAmount Placeholder for a fixed performance fee (e.g., in a specific token).
    function setDynamicFeeParameters(uint256 yieldPercentageBps, uint256 performanceFeeAmount) public onlyGovernance {
        require(yieldPercentageBps <= 10000, "QuantumVault: Yield percentage cannot exceed 100%");
        yieldFeePercentage = yieldPercentageBps;
        performanceFee = performanceFeeAmount; // Simple fixed amount example
        emit DynamicFeeParametersSet(yieldPercentageBps, performanceFeeAmount);
    }

    // --- 5. Utility ---

    /// @notice Returns the contract version string.
    function getVersion() public pure returns (string memory) {
        return "QuantumVault v1.0";
    }

    // --- Internal/Helper Functions (Could be made external if needed for specific views) ---

     /// @dev Internal helper to get a mutable reference to a SuperpositionState.
     /// Assumes stateId is valid. Used to avoid repeated checks and array index math.
     function _getSuperpositionState(uint256 stateId) internal view returns (SuperpositionState storage) {
         // Assumes stateId > 0 and stateId < nextSuperpositionStateId checked by caller
         return superpositionStates[stateId - 1];
     }

     // Note: More complex internal logic for yield calculation, state transition conditions,
     // and external protocol interaction would be needed in a production contract.
     // This provides the structure and function definitions.
}
```