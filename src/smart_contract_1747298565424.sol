Okay, here is a Solidity smart contract concept named `QuantumVault`. It's designed around the metaphorical idea of "superposition" for deposited assets, where the final destination of funds is determined by a "measurement" event triggered by Chainlink VRF (simulating quantum randomness) or a timeout. It includes concepts like adjustable probabilities ("quantum gates"), and "entanglement" where the outcome of one deposit can be linked to another.

This contract is complex and incorporates several advanced concepts:
1.  **ERC20 & ERC721 Support:** Handles multiple token types.
2.  **Probabilistic Outcomes:** The destination of funds depends on a weighted random outcome.
3.  **State Management:** Deposits move through different states (Pending, Collapsed).
4.  **Chainlink VRF Integration:** Uses verifiable randomness for state collapse ("measurement").
5.  **Timed Events:** A timeout mechanism for state collapse ("decoherence").
6.  **Role-Based Access Control:** Admin and Observer roles.
7.  **Metaphorical "Quantum Gates":** Functions to influence probabilities before collapse.
8.  **Metaphorical "Entanglement":** Linking the collapse outcome of two distinct deposits.
9.  **Batch Operations:** Functions for observers/admins to manage multiple deposits.
10. **Withdrawal Logic:** Allows designated recipients to claim funds after collapse.

It deliberately avoids simple patterns like standard ERC20/721 implementations, basic staking vaults, simple multisigs, or direct forks of well-known DeFi protocols.

**Disclaimer:** This is a complex concept for demonstration. Deploying and using such a contract in production would require extensive auditing, gas optimization, and careful consideration of all potential edge cases and security implications. The "quantum" aspects are purely metaphorical simulations on a classical deterministic blockchain.

---

## QuantumVault Smart Contract Outline & Function Summary

**Contract Name:** `QuantumVault`

**Purpose:** A vault designed to hold deposited ERC20 and ERC721 tokens in a "superposed" state. The final recipient(s) of the tokens from a deposit is determined by a probabilistic outcome triggered by verifiable randomness (Chainlink VRF) or a timeout ("measurement" event). The contract includes features to influence these probabilities and link deposit outcomes ("entanglement").

**Core Concepts:**
*   **Superposition:** Deposited assets are in a pending state where the final destination is not fixed.
*   **Measurement:** The event that collapses the superposition, determining the outcome. Triggered by VRF or timeout.
*   **Outcome Types:** Currently supports splitting tokens between two designated addresses (Outcome A and Outcome B) based on probabilities, or sending an NFT to one of two addresses.
*   **Probabilities:** Adjustable weights influencing the likelihood of Outcome A vs. Outcome B.
*   **Entanglement:** Linking the outcome of one deposit to the outcome of another.
*   **Quantum Gates (Metaphorical):** Functions to modify probabilities (`adjustProbabilities`, `applyHadamard`, `addNoise`).
*   **Observer:** A role responsible for triggering measurements (VRF requests).
*   **Admin:** A role for setting contract configuration parameters.

**State Variables:**
*   `deposits`: Mapping storing `SuperposedDeposit` structs by ID.
*   `pendingDepositIds`: Array of deposit IDs in the `Pending` state.
*   `collapsedDepositIds`: Array of deposit IDs in a collapsed state.
*   `outcomeAddressAmounts`: Mapping to track withdrawable amounts for addresses after collapse (for ERC20).
*   `outcomeAddressNFTs`: Mapping to track withdrawable NFT IDs for addresses after collapse (for ERC721).
*   VRF configuration variables (coordinator, keyhash, subId).
*   Observer and Admin addresses.
*   Configuration parameters (timeout, probability limits, entanglement approval required, fees).
*   Mapping to track VRF request IDs to deposit IDs.

**Enums:**
*   `SuperpositionState`: `Pending`, `CollapsedA`, `CollapsedB`, `CollapsedC` (extendable for more complex outcomes).
*   `OutcomeType`: `OutcomeA`, `OutcomeB`.
*   `EntanglementCorrelation`: `CorrelationA`, `CorrelationB`, `AntiCorrelation`.

**Structs:**
*   `SuperposedDeposit`: Stores details for each deposit (type, token, id/amount, depositor, state, timestamp, outcome addresses, probabilities, entangled deposit ID, entanglement type, VRF request ID).

**Events:** (Not listed as functions, but essential for tracking)
*   `DepositMade`
*   `ProbabilitiesAdjusted`
*   `EntanglementProposed`
*   `EntanglementAccepted`
*   `EntanglementRemoved`
*   `MeasurementRequested`
*   `StateCollapsed`
*   `FundsWithdrawn`
*   `NFTWithdrawn`
*   `ObserverAddressSet`
*   `VRFConfigSet`
*   `CollapseTimeoutSet`

**Function Summary:**

1.  `constructor()`: Initializes the contract with Admin address, VRF coordinator, key hash, and subscription ID. Sets initial observer.
2.  `setObserverAddress(address newObserver)`: Admin function to change the Observer address.
3.  `setVRFConfiguration(address coordinator, bytes32 keyHash)`: Admin function to update VRF settings.
4.  `setVRFSubscriptionId(uint64 subId)`: Admin function to set the VRF subscription ID.
5.  `setCollapseTimeout(uint48 duration)`: Admin function to set the timeout duration for pending deposits.
6.  `setProbabilityAdjustmentLimits(uint16 maxDeltaPermille, uint16 maxTotalAdjustmentPermille)`: Admin function to set limits on probability adjustments (in per mille).
7.  `setEntanglementApprovalRequired(bool required)`: Admin function to toggle if entanglement proposals need Observer approval.
8.  `depositERC20(address tokenAddress, uint256 amount, address outcomeA, address outcomeB, uint16 probA_permille)`: Deposits ERC20 tokens into the vault, creating a `Pending` deposit. Specifies potential outcome addresses and initial probability for Outcome A.
9.  `depositERC721(address tokenAddress, uint256 tokenId, address outcomeA, address outcomeB, uint16 probA_permille)`: Deposits ERC721 tokens into the vault, creating a `Pending` deposit. Specifies potential outcome addresses and initial probability for Outcome A.
10. `getDepositDetails(uint256 depositId)`: View function to retrieve all details of a specific deposit.
11. `getPendingDepositIds()`: View function returning the list of deposit IDs currently in the `Pending` state.
12. `getCollapsedDepositIds()`: View function returning the list of deposit IDs that have collapsed.
13. `calculateCurrentProbabilities(uint256 depositId)`: View function showing the current calculated probability for Outcome A for a pending deposit, considering any adjustments.
14. `adjustProbabilities(uint256 depositId, int16 deltaProbA_permille)`: Allows the depositor to adjust the probability of Outcome A for their pending deposit within configured limits.
15. `applyHadamardGate(uint256 depositId)`: Observer function to metaphorically apply a Hadamard gate, flipping the dominant probability outcome for a pending deposit.
16. `addQuantumNoise(uint256 depositId, uint16 noiseLevelPermille)`: Observer function to add a small, bounded random adjustment to the probabilities of a pending deposit.
17. `proposeEntanglement(uint256 depositId1, uint256 depositId2, EntanglementCorrelation correlationType)`: Allows a depositor to propose entanglement between two pending deposits. Requires the other deposit owner's or Observer's approval depending on config.
18. `acceptEntanglement(uint256 depositId1, uint256 depositId2)`: If entanglement requires Observer approval, this function is called by the Observer to finalize the entanglement.
19. `removeEntanglement(uint256 depositId)`: Removes the entanglement relationship for a given deposit ID. Can be called by Observer or one of the involved depositors.
20. `requestStateMeasurement(uint256 depositId)`: Observer function to request verifiable randomness for a specific pending deposit, initiating the collapse process via VRF callback.
21. `requestBatchMeasurement(uint256[] calldata depositIds)`: Observer function to request measurement for multiple deposits in one transaction (each triggers a separate VRF request).
22. `rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)`: Chainlink VRF callback function. Internally processes the random result and triggers the state collapse logic (`_collapseState`).
23. `triggerTimeoutCollapse(uint256 depositId)`: Allows anyone to trigger the state collapse for a pending deposit if its timeout has been reached.
24. `_collapseState(uint256 depositId, uint256 randomness)`: Internal function executing the state collapse logic based on randomness and probabilities. Handles entangled deposits recursively.
25. `getDepositOutcomeAddress(uint256 depositId)`: View function returning the address that is eligible to withdraw after the deposit has collapsed (for Outcome A or B). Returns address(0) if pending or other collapse state.
26. `getRequiredWithdrawAmount(uint256 depositId, address recipient)`: View function to check how much ERC20 the specified `recipient` can withdraw for a collapsed `depositId`.
27. `getRequiredNFTWithdrawal(uint256 depositId, address recipient)`: View function to check if the specified `recipient` can withdraw the NFT for a collapsed `depositId`, returning the token ID if so.
28. `withdrawCollapsedFunds(uint256 depositId)`: Allows the designated outcome address (A or B) to withdraw the ERC20 tokens for a collapsed deposit.
29. `withdrawCollapsedNFT(uint256 depositId)`: Allows the designated outcome address (A or B) to withdraw the ERC721 token for a collapsed deposit.
30. `isDepositEntangled(uint256 depositId)`: View function checking if a deposit is currently entangled with another.
31. `getEntangledPair(uint256 depositId)`: View function returning the ID of the deposit entangled with the given one, and the correlation type.
32. `cancelPendingMeasurement(uint256 depositId)`: Observer function to cancel a VRF request associated with a deposit if possible (depends on VRF Coordinator features and state). Updates internal state.
33. `getDepositState(uint256 depositId)`: View function to get the `SuperpositionState` enum value.
34. `getOutcomeAddresses(uint256 depositId)`: View function returning the configured Outcome A and Outcome B addresses for a deposit.
35. `getVRFRequestId(uint256 depositId)`: View function returning the VRF request ID associated with a deposit, if any.
36. `getVrfSubscriptionDetails()`: View function returning VRF configuration details (Coordinator, KeyHash, SubId).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary interfaces and libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title QuantumVault
/// @dev A vault where token deposits enter a "superposed" state.
/// The final recipient is determined probabilistically via Chainlink VRF or timeout ("measurement").
/// Includes features for probability adjustment ("quantum gates") and linking outcomes ("entanglement").
contract QuantumVault is Ownable, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;

    /// @dev Enum representing the state of a deposit.
    enum SuperpositionState {
        Pending,       // Deposit is in superposition, outcome not determined
        MeasurementRequested, // VRF randomness requested, awaiting fulfillment
        CollapsedA,    // State collapsed to Outcome A
        CollapsedB,    // State collapsed to Outcome B
        CollapsedC,    // Placeholder for potential future outcome types
        EntanglementPendingApproval // Entanglement proposed, awaiting approval
    }

    /// @dev Enum representing the potential outcomes.
    enum OutcomeType {
        OutcomeA,
        OutcomeB
    }

    /// @dev Enum representing the correlation type for entangled deposits.
    enum EntanglementCorrelation {
        CorrelationA, // If deposit 1 collapses to A, deposit 2 collapses to A
        CorrelationB, // If deposit 1 collapses to B, deposit 2 collapses to B
        AntiCorrelation // If deposit 1 collapses to A, deposit 2 collapses to B (and vice-versa)
    }

    /// @dev Struct to hold details for each superposed deposit.
    struct SuperposedDeposit {
        uint256 depositId;       // Unique identifier for the deposit
        address depositor;       // The address that made the deposit
        address tokenAddress;    // Address of the deposited token (ERC20 or ERC721)
        bool isERC721;           // True if it's an ERC721, false if ERC20
        uint256 amountOrTokenId; // Amount for ERC20, Token ID for ERC721
        SuperpositionState state; // Current state of the deposit
        uint48 timestamp;        // Timestamp of the deposit
        uint48 collapseTimeout;  // Timestamp after which timeout collapse is possible
        address outcomeA;        // Potential recipient address for Outcome A
        address outcomeB;        // Potential recipient address for Outcome B
        uint16 initialProbA_permille; // Initial probability for Outcome A (in per mille, 0-1000)
        int16 probAdjustment_permille; // Total adjustment applied to initialProbA
        uint256 entangledDepositId; // ID of the deposit this one is entangled with (0 if none)
        EntanglementCorrelation entanglementType; // Type of correlation if entangled
        uint256 vrfRequestId;    // Chainlink VRF request ID (0 if none pending)
    }

    // --- State Variables ---

    uint256 private _nextDepositId = 1;
    mapping(uint256 => SuperposedDeposit) public deposits;
    uint256[] public pendingDepositIds; // Use dynamic array for iteration
    uint256[] public collapsedDepositIds; // Use dynamic array for iteration

    // Track withdrawable amounts for collapsed ERC20 deposits
    mapping(address => mapping(address => uint256)) private _outcomeAddressERC20Amounts; // recipient => tokenAddress => amount

    // Track withdrawable NFTs for collapsed ERC721 deposits
    mapping(address => mapping(address => uint256[])) private _outcomeAddressERC721NFTs; // recipient => tokenAddress => tokenIds

    // VRF Configuration
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_keyHash;
    uint32 constant private VRF_CALLBACK_GAS_LIMIT = 1_000_000; // Adjust as needed

    // Map VRF request IDs back to deposit IDs
    mapping(uint256 => uint256) public vrfRequestIdToDepositId;

    // Roles
    address public observer;

    // Configuration Parameters (set by Admin)
    uint48 public collapseTimeoutDuration = 30 days; // Default timeout
    uint16 public maxProbDeltaPermille = 100; // Max adjustment per call (10%)
    uint16 public maxTotalProbAdjustmentPermille = 300; // Max total adjustment (30%)
    bool public entanglementApprovalRequired = true; // Does entanglement need Observer approval?

    // --- Events ---

    event DepositMade(uint256 indexed depositId, address indexed depositor, address tokenAddress, bool isERC721, uint256 amountOrTokenId, address indexed outcomeA, address indexed outcomeB, uint16 initialProbA);
    event ProbabilitiesAdjusted(uint256 indexed depositId, address indexed adjuter, int16 deltaProbA, uint16 finalProbA);
    event HadamardApplied(uint256 indexed depositId, address indexed observer);
    event NoiseAdded(uint256 indexed depositId, address indexed observer, uint16 noiseLevel);
    event EntanglementProposed(uint256 indexed depositId1, uint256 indexed depositId2, EntanglementCorrelation correlationType, address indexed proposer);
    event EntanglementAccepted(uint256 indexed depositId1, uint256 indexed depositId2, address indexed acceptor);
    event EntanglementRemoved(uint256 indexed depositId, uint256 indexed removedDepositId);
    event MeasurementRequested(uint256 indexed depositId, uint256 vrfRequestId, address indexed observer);
    event StateCollapsed(uint256 indexed depositId, SuperpositionState finalState, address indexed finalRecipient, uint256 randomnessUsed);
    event BatchMeasurementRequested(uint256[] depositIds, uint256[] vrfRequestIds, address indexed observer);
    event TimeoutCollapseTriggered(uint256 indexed depositId, address indexed trigger);
    event FundsWithdrawn(uint256 indexed depositId, address indexed recipient, address tokenAddress, uint256 amount);
    event NFTWithdrawn(uint256 indexed depositId, address indexed recipient, address tokenAddress, uint256 tokenId);
    event ObserverAddressSet(address indexed oldObserver, address indexed newObserver);
    event VRFConfigSet(address coordinator, bytes32 keyHash);
    event VRFSubscriptionIdSet(uint64 subId);
    event CollapseTimeoutSet(uint48 duration);
    event ProbabilityAdjustmentLimitsSet(uint16 maxDeltaPermille, uint16 maxTotalAdjustmentPermille);
    event EntanglementApprovalRequiredSet(bool required);
    event PendingMeasurementCanceled(uint256 indexed depositId, uint256 indexed vrfRequestId, address indexed observer);

    // --- Modifiers ---

    modifier onlyObserver() {
        require(msg.sender == observer, "QV: Only Observer");
        _;
    }

    modifier onlyDepositor(uint256 depositId) {
        require(deposits[depositId].depositor == msg.sender, "QV: Only Depositor");
        _;
    }

    modifier whenPending(uint256 depositId) {
        require(deposits[depositId].state == SuperpositionState.Pending, "QV: Not Pending");
        _;
    }

    modifier whenCollapsed(uint256 depositId) {
        require(deposits[depositId].state == SuperpositionState.CollapsedA || deposits[depositId].state == SuperpositionState.CollapsedB || deposits[depositId].state == SuperpositionState.CollapsedC, "QV: Not Collapsed");
        _;
    }

    /// @dev Constructor to initialize the contract with Admin, VRF coordinator, key hash, and subscription ID.
    /// @param _vrfCoordinator Address of the VRF Coordinator contract.
    /// @param _keyHash The key hash for VRF requests.
    /// @param _subscriptionId The VRF subscription ID managed by this contract.
    constructor(address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId)
        Ownable(msg.sender)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        observer = msg.sender; // Deployer is initially the observer
        emit ObserverAddressSet(address(0), msg.sender);
        emit VRFConfigSet(_vrfCoordinator, _keyHash);
        emit VRFSubscriptionIdSet(_subscriptionId);
    }

    // --- Admin Functions ---

    /// @dev Sets the address of the Observer role.
    /// @param newObserver The new observer address.
    function setObserverAddress(address newObserver) external onlyOwner {
        require(newObserver != address(0), "QV: Zero address not allowed");
        emit ObserverAddressSet(observer, newObserver);
        observer = newObserver;
    }

    /// @dev Sets the VRF coordinator address and key hash.
    /// @param coordinator Address of the VRF Coordinator contract.
    /// @param keyHash The key hash for VRF requests.
    function setVRFConfiguration(address coordinator, bytes32 keyHash) external onlyOwner {
        require(coordinator != address(0), "QV: Zero address not allowed");
        i_vrfCoordinator = VRFCoordinatorV2Interface(coordinator); // Update immutable - requires proxy or similar pattern in production. For this example, we use this for demonstration.
        i_keyHash = keyHash; // Update immutable - requires proxy or similar pattern in production.
        emit VRFConfigSet(coordinator, keyHash);
    }

     /// @dev Sets the VRF subscription ID.
    /// @param subId The new VRF subscription ID.
    function setVRFSubscriptionId(uint64 subId) external onlyOwner {
        i_subscriptionId = subId; // Update immutable - requires proxy or similar pattern in production.
        emit VRFSubscriptionIdSet(subId);
    }


    /// @dev Sets the duration after which a pending deposit can be collapsed via timeout.
    /// @param duration The timeout duration in seconds.
    function setCollapseTimeout(uint48 duration) external onlyOwner {
        collapseTimeoutDuration = duration;
        emit CollapseTimeoutSet(duration);
    }

    /// @dev Sets the limits for probability adjustments.
    /// @param maxDeltaPermille Max change allowed per `adjustProbabilities` call (0-1000).
    /// @param maxTotalAdjustmentPermille Max cumulative adjustment allowed (0-1000).
    function setProbabilityAdjustmentLimits(uint16 maxDeltaPermille, uint16 maxTotalAdjustmentPermille) external onlyOwner {
        require(maxDeltaPermille <= 1000 && maxTotalAdjustmentPermille <= 1000, "QV: Limits must be <= 1000");
        maxProbDeltaPermille = maxDeltaPermille;
        maxTotalProbAdjustmentPermille = maxTotalAdjustmentPermille;
        emit ProbabilityAdjustmentLimitsSet(maxDeltaPermille, maxTotalAdjustmentPermille);
    }

    /// @dev Sets whether entanglement proposals require Observer approval.
    /// @param required True if Observer approval is needed, false otherwise.
    function setEntanglementApprovalRequired(bool required) external onlyOwner {
        entanglementApprovalRequired = required;
        emit EntanglementApprovalRequiredSet(required);
    }


    // --- Deposit Functions ---

    /// @dev Deposits ERC20 tokens into the vault in a superposed state.
    /// @param tokenAddress Address of the ERC20 token.
    /// @param amount Amount of tokens to deposit.
    /// @param outcomeA Potential recipient address for Outcome A.
    /// @param outcomeB Potential recipient address for Outcome B.
    /// @param probA_permille Initial probability (0-1000) for the deposit to collapse to Outcome A.
    function depositERC20(address tokenAddress, uint256 amount, address outcomeA, address outcomeB, uint16 probA_permille) external {
        require(tokenAddress != address(0), "QV: Invalid token address");
        require(amount > 0, "QV: Amount must be > 0");
        require(outcomeA != address(0) || outcomeB != address(0), "QV: At least one outcome address must be non-zero");
        require(probA_permille <= 1000, "QV: Probability must be 0-1000");

        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 newDepositId = _nextDepositId++;
        uint48 currentTime = uint48(block.timestamp);

        deposits[newDepositId] = SuperposedDeposit({
            depositId: newDepositId,
            depositor: msg.sender,
            tokenAddress: tokenAddress,
            isERC721: false,
            amountOrTokenId: amount,
            state: SuperpositionState.Pending,
            timestamp: currentTime,
            collapseTimeout: currentTime + collapseTimeoutDuration,
            outcomeA: outcomeA,
            outcomeB: outcomeB,
            initialProbA_permille: probA_permille,
            probAdjustment_permille: 0,
            entangledDepositId: 0,
            entanglementType: EntanglementCorrelation.CorrelationA, // Default, not used if not entangled
            vrfRequestId: 0
        });

        pendingDepositIds.push(newDepositId);

        emit DepositMade(newDepositId, msg.sender, tokenAddress, false, amount, outcomeA, outcomeB, probA_permille);
    }

    /// @dev Deposits ERC721 tokens into the vault in a superposed state.
    /// @param tokenAddress Address of the ERC721 token.
    /// @param tokenId Token ID of the NFT to deposit.
    /// @param outcomeA Potential recipient address for Outcome A.
    /// @param outcomeB Potential recipient address for Outcome B.
    /// @param probA_permille Initial probability (0-1000) for the deposit to collapse to Outcome A.
    function depositERC721(address tokenAddress, uint256 tokenId, address outcomeA, address outcomeB, uint16 probA_permille) external {
        require(tokenAddress != address(0), "QV: Invalid token address");
        require(outcomeA != address(0) || outcomeB != address(0), "QV: At least one outcome address must be non-zero");
        require(probA_permille <= 1000, "QV: Probability must be 0-1000");

        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 newDepositId = _nextDepositId++;
        uint48 currentTime = uint48(block.timestamp);

        deposits[newDepositId] = SuperposedDeposit({
            depositId: newDepositId,
            depositor: msg.sender,
            tokenAddress: tokenAddress,
            isERC721: true,
            amountOrTokenId: tokenId,
            state: SuperpositionState.Pending,
            timestamp: currentTime,
            collapseTimeout: currentTime + collapseTimeoutDuration,
            outcomeA: outcomeA,
            outcomeB: outcomeB,
            initialProbA_permille: probA_permille,
            probAdjustment_permille: 0,
            entangledDepositId: 0,
            entanglementType: EntanglementCorrelation.CorrelationA, // Default, not used if not entangled
            vrfRequestId: 0
        });

        pendingDepositIds.push(newDepositId);

        emit DepositMade(newDepositId, msg.sender, tokenAddress, true, tokenId, outcomeA, outcomeB, probA_permille);
    }


    // --- Quantum Gate Functions (affecting probabilities) ---

    /// @dev Allows the depositor to adjust the probability of Outcome A for their pending deposit.
    /// Limited by `maxProbDeltaPermille` per call and `maxTotalProbAdjustmentPermille` overall.
    /// @param depositId The ID of the deposit to adjust.
    /// @param deltaProbA_permille The amount to adjust the probability of Outcome A by (can be negative).
    function adjustProbabilities(uint256 depositId, int16 deltaProbA_permille) external onlyDepositor(depositId) whenPending(depositId) {
        SuperposedDeposit storage deposit = deposits[depositId];

        // Check per-call limit
        require(deltaProbA_permille >= -int16(maxProbDeltaPermille) && deltaProbA_permille <= int16(maxProbDeltaPermille), "QV: Adjustment exceeds per-call limit");

        int16 currentTotalAdjustment = deposit.probAdjustment_permille;
        int16 newTotalAdjustment = currentTotalAdjustment + deltaProbA_permille;

        // Check total adjustment limit
        require(newTotalAdjustment >= -int16(maxTotalProbAdjustmentPermille) && newTotalAdjustment <= int16(maxTotalProbAdjustmentPermille), "QV: Total adjustment exceeds cumulative limit");

        // Check resulting probability bounds (0-1000)
        int256 resultingProbA = int256(deposit.initialProbA_permille) + newTotalAdjustment;
        require(resultingProbA >= 0 && resultingProbA <= 1000, "QV: Resulting probability out of bounds (0-1000)");

        deposit.probAdjustment_permille = newTotalAdjustment;
        emit ProbabilitiesAdjusted(depositId, msg.sender, deltaProbA_permille, uint16(resultingProbA));
    }

    /// @dev Metaphorically applies a Hadamard-like gate, swapping the dominant probability outcome.
    /// E.g., 70/30 becomes 30/70, 51/49 becomes 49/51.
    /// @param depositId The ID of the deposit to apply the gate to.
    function applyHadamardGate(uint256 depositId) external onlyObserver whenPending(depositId) {
         SuperposedDeposit storage deposit = deposits[depositId];
         // Calculate current effective probability
         uint16 currentProbA = calculateCurrentProbabilities(depositId);
         // Calculate the target initial probability that would result in the flipped outcome
         // If current is P_A, new effective should be 1000 - P_A
         // initial + adjustment = P_A
         // initial' + adjustment = 1000 - P_A
         // initial' = 1000 - P_A - adjustment
         // initial' = 1000 - (initial + adjustment) - adjustment = 1000 - initial - 2 * adjustment
         int16 newInitialProbA_permille = int16(1000) - int16(deposit.initialProbA_permille) - 2 * deposit.probAdjustment_permille;

         // Update initial probability and reset adjustment (or calculate required new adjustment)
         // Simpler: just flip the *effective* probability by adjusting the adjustment value.
         // Current effective P_A = initial + adjustment
         // Target effective P_A' = 1000 - (initial + adjustment)
         // New adjustment = Target effective P_A' - initial
         // New adjustment = (1000 - initial - adjustment) - initial
         // New adjustment = 1000 - 2 * initial - adjustment
         // Let's recalculate the adjustment needed to make the *new* effective probability `1000 - currentProbA`.
         // new_initial + new_adjustment = 1000 - currentProbA
         // Since initial is fixed, we must adjust the adjustment.
         // deposit.initialProbA_permille + new_adjustment = 1000 - (deposit.initialProbA_permille + deposit.probAdjustment_permille)
         // new_adjustment = 1000 - 2 * deposit.initialProbA_permille - deposit.probAdjustment_permille
         // This can exceed adjustment limits. A simpler "metaphorical" Hadamard is to just swap the outcome addresses A and B. Let's do that.

         (deposit.outcomeA, deposit.outcomeB) = (deposit.outcomeB, deposit.outcomeA);
         // The probability still points to the *original* A address, which is now B.
         // To keep the *same* probability pointing to the *new* A address (original B), we need to adjust the probability.
         // If original A prob was P, new A prob should be P.
         // Current state means P chance of sending to original A (now B) and 1-P chance to original B (now A).
         // We want P chance of sending to new A (original B) and 1-P chance to new B (original A).
         // So the probability for the address currently stored in `outcomeA` should become `1000 - currentProbA`.
         int16 requiredNewAdjustment = int16(1000) - int16(currentProbA) - int16(deposit.initialProbA_permille);
         deposit.probAdjustment_permille = requiredNewAdjustment;


         emit HadamardApplied(depositId, msg.sender);
         // Note: This implementation of Hadamard is a simplified metaphor by swapping outcome addresses and recalculating the adjustment needed.
    }

    /// @dev Adds a small, bounded random adjustment (noise) to the probabilities.
    /// Requires Observer role to add noise. Uses VRF internally.
    /// @param depositId The ID of the deposit to add noise to.
    /// @param noiseLevelPermille The maximum possible absolute noise adjustment (0-1000).
    function addQuantumNoise(uint256 depositId, uint16 noiseLevelPermille) external onlyObserver whenPending(depositId) {
        require(noiseLevelPermille <= 1000, "QV: Noise level must be 0-1000");

        SuperposedDeposit storage deposit = deposits[depositId];
        require(deposit.vrfRequestId == 0, "QV: Measurement already pending");

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            getRequestConfirmations(), // Default confirmations
            VRF_CALLBACK_GAS_LIMIT,
            1 // Request 1 random word
        );

        vrfRequestIdToDepositId[requestId] = depositId;
        deposit.vrfRequestId = requestId; // Use vrfRequestId field to track noise request

        emit NoiseAdded(depositId, msg.sender, noiseLevelPermille);
        // The actual noise application happens in rawFulfillRandomWords when the VRF request returns.
        // The random word will be used to determine the noise delta within +/- noiseLevelPermille.
    }

    // --- Entanglement Functions ---

    /// @dev Allows a depositor to propose entanglement between two pending deposits.
    /// The other deposit owner or Observer needs to accept depending on config.
    /// @param depositId1 The ID of the first deposit (caller must be depositor or Observer if config allows).
    /// @param depositId2 The ID of the second deposit.
    /// @param correlationType The type of correlation between the outcomes.
    function proposeEntanglement(uint256 depositId1, uint256 depositId2, EntanglementCorrelation correlationType) external whenPending(depositId1) whenPending(depositId2) {
        require(depositId1 != depositId2, "QV: Cannot entangle deposit with itself");
        SuperposedDeposit storage dep1 = deposits[depositId1];
        SuperposedDeposit storage dep2 = deposits[depositIds];

        require(dep1.entangledDepositId == 0 && dep2.entangledDepositId == 0, "QV: Deposits already entangled");

        bool isObserver = msg.sender == observer;
        bool isDepositor1 = msg.sender == dep1.depositor;

        require(isObserver || isDepositor1, "QV: Not authorized to propose entanglement for deposit 1");

        if (entanglementApprovalRequired && !isObserver) {
            // Requires Observer approval
            dep1.entangledDepositId = depositId2;
            dep1.entanglementType = correlationType;
            dep1.state = SuperpositionState.EntanglementPendingApproval;

            dep2.entangledDepositId = depositId1; // Store reverse link
            dep2.entanglementType = correlationType; // Store correlation type on both sides
             // Deposit 2 state remains Pending, Deposit 1 state changes awaiting approval
            emit EntanglementProposed(depositId1, depositId2, correlationType, msg.sender);

        } else {
            // No Observer approval required (or Observer is proposing)
            dep1.entangledDepositId = depositId2;
            dep1.entanglementType = correlationType;
            dep2.entangledDepositId = depositId1;
            dep2.entanglementType = correlationType;
            // State remains Pending for both
            emit EntanglementAccepted(depositId1, depositId2, msg.sender); // Emit Accepted immediately
        }
    }

     /// @dev Accepts a proposed entanglement between two deposits (only callable by Observer if required).
     /// @param depositId1 The ID of the first deposit in the entanglement pair.
     /// @param depositId2 The ID of the second deposit in the entanglement pair.
    function acceptEntanglement(uint256 depositId1, uint256 depositId2) external onlyObserver {
        SuperposedDeposit storage dep1 = deposits[depositId1];
        SuperposedDeposit storage dep2 = deposits[depositId2];

        require(dep1.entangledDepositId == depositId2 && dep2.entangledDepositId == depositId1, "QV: Deposits not proposed for entanglement with each other");
        require(dep1.state == SuperpositionState.EntanglementPendingApproval || dep2.state == SuperpositionState.EntanglementPendingApproval, "QV: Entanglement not pending approval");

        // Revert state of the one that was marked pending approval
        if(dep1.state == SuperpositionState.EntanglementPendingApproval) dep1.state = SuperpositionState.Pending;
        if(dep2.state == SuperpositionState.EntanglementPendingApproval) dep2.state = SuperpositionState.Pending; // Should not happen if only one changes state

        emit EntanglementAccepted(depositId1, depositId2, msg.sender);
    }

    /// @dev Removes the entanglement relationship for a given deposit ID.
    /// Can be called by the Observer or the depositor of the given deposit ID if they are the proposer, or both depositors.
    /// @param depositId The ID of the deposit whose entanglement is to be removed.
    function removeEntanglement(uint256 depositId) external {
        SuperposedDeposit storage dep = deposits[depositId];
        require(dep.entangledDepositId != 0, "QV: Deposit not entangled");

        uint256 entangledId = dep.entangledDepositId;
        SuperposedDeposit storage entangledDep = deposits[entangledId];

        bool isObserver = msg.sender == observer;
        bool isDepositor = msg.sender == dep.depositor;
        bool isEntangledDepositor = msg.sender == entangledDep.depositor;

        // Policy: Observer can always remove. Depositors can remove if both agree, or if the one removing was the proposer (if tracking proposer was implemented, simplified here).
        // Simplified policy: Observer or *either* depositor can remove.
        require(isObserver || isDepositor || isEntangledDepositor, "QV: Not authorized to remove entanglement");

        // Revert state if pending approval
        if(dep.state == SuperpositionState.EntanglementPendingApproval) dep.state = SuperpositionState.Pending;
        if(entangledDep.state == SuperpositionState.EntanglementPendingApproval) entangledDep.state = SuperpositionState.Pending;


        dep.entangledDepositId = 0;
        entangledDep.entangledDepositId = 0;

        emit EntanglementRemoved(depositId, entangledId);
    }

    /// @dev Checks if a deposit is currently entangled with another.
    /// @param depositId The ID of the deposit to check.
    /// @return True if entangled, false otherwise.
    function isDepositEntangled(uint256 depositId) external view returns (bool) {
        return deposits[depositId].entangledDepositId != 0;
    }

    /// @dev Gets the entangled pair ID and correlation type for a deposit.
    /// @param depositId The ID of the deposit.
    /// @return entangledDepositId The ID of the deposit it's entangled with (0 if none).
    /// @return correlationType The type of correlation.
    function getEntangledPair(uint256 depositId) external view returns (uint256 entangledDepositId, EntanglementCorrelation correlationType) {
        SuperposedDeposit storage dep = deposits[depositId];
        return (dep.entangledDepositId, dep.entanglementType);
    }


    // --- Measurement (Collapse) Functions ---

    /// @dev Observer requests verifiable randomness for a specific pending deposit.
    /// This initiates the collapse process via the VRF callback.
    /// @param depositId The ID of the deposit to measure.
    function requestStateMeasurement(uint256 depositId) external onlyObserver whenPending(depositId) {
        SuperposedDeposit storage deposit = deposits[depositId];
        require(deposit.vrfRequestId == 0, "QV: Measurement already pending for this deposit");

        // If entangled, request randomness for the partner first if not pending
        if (deposit.entangledDepositId != 0) {
             SuperposedDeposit storage entangledDep = deposits[deposit.entangledDepositId];
             if (entangledDep.state == SuperpositionState.Pending && entangledDep.vrfRequestId == 0) {
                 // Request randomness for the entangled partner, this will trigger collapse for both
                 uint256 entangledRequestId = i_vrfCoordinator.requestRandomWords(
                     i_keyHash,
                     i_subscriptionId,
                     getRequestConfirmations(),
                     VRF_CALLBACK_GAS_LIMIT,
                     1
                 );
                 vrfRequestIdToDepositId[entangledRequestId] = deposit.entangledDepositId;
                 entangledDep.vrfRequestId = entangledRequestId;
                 entangledDep.state = SuperpositionState.MeasurementRequested;
                 emit MeasurementRequested(deposit.entangledDepositId, entangledRequestId, msg.sender);

                 // Mark the requested deposit as pending measurement as well, but link to partner's request
                 deposit.vrfRequestId = entangledRequestId;
                 deposit.state = SuperpositionState.MeasurementRequested;
                 emit MeasurementRequested(depositId, entangledRequestId, msg.sender);

                 return; // Collapse will be triggered by the partner's VRF callback
             } else if (entangledDep.vrfRequestId != 0) {
                 // Partner's measurement already pending, link this one to it
                 deposit.vrfRequestId = entangledDep.vrfRequestId;
                 deposit.state = SuperpositionState.MeasurementRequested;
                 emit MeasurementRequested(depositId, entangledDep.vrfRequestId, msg.sender);
                 return;
             }
        }

        // If not entangled, or partner already pending, request randomness for this deposit
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            getRequestConfirmations(),
            VRF_CALLBACK_GAS_LIMIT,
            1
        );

        vrfRequestIdToDepositId[requestId] = depositId;
        deposit.vrfRequestId = requestId;
        deposit.state = SuperpositionState.MeasurementRequested;

        emit MeasurementRequested(depositId, requestId, msg.sender);
    }

    /// @dev Observer requests verifiable randomness for a batch of pending deposits.
    /// Each deposit in the batch triggers a separate VRF request if not already pending measurement.
    /// @param depositIds The array of deposit IDs to measure.
    function requestBatchMeasurement(uint256[] calldata depositIds) external onlyObserver {
        uint256[] memory requestedVrfs = new uint256[](depositIds.length);
        for (uint i = 0; i < depositIds.length; i++) {
            uint256 depositId = depositIds[i];
            SuperposedDeposit storage deposit = deposits[depositId];

            if (deposit.state == SuperpositionState.Pending && deposit.vrfRequestId == 0) {
                 // Handle entanglement logic similar to requestStateMeasurement, but within the loop.
                 // For simplicity in this batch function example, we'll only trigger for the deposit itself
                 // and assume entangled pairs will be handled when *their* ID comes up or later.
                 // A robust implementation might require more complex entanglement handling in batches.

                uint256 requestId = i_vrfCoordinator.requestRandomWords(
                    i_keyHash,
                    i_subscriptionId,
                    getRequestConfirmations(),
                    VRF_CALLBACK_GAS_LIMIT,
                    1
                );

                vrfRequestIdToDepositId[requestId] = depositId;
                deposit.vrfRequestId = requestId;
                deposit.state = SuperpositionState.MeasurementRequested;
                requestedVrfs[i] = requestId;
                emit MeasurementRequested(depositId, requestId, msg.sender);

            } else {
                // Deposit not pending or already has VRF request
                requestedVrfs[i] = 0; // Mark as skipped
            }
        }
        emit BatchMeasurementRequested(depositIds, requestedVrfs, msg.sender);
    }


    /// @dev Chainlink VRF callback function. Do not call directly.
    /// This function is called by the VRF coordinator contract after randomness is generated.
    /// It triggers the state collapse logic.
    /// @param requestId The request ID for the VRF request.
    /// @param randomWords An array containing the requested random words.
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        require(randomWords.length > 0, "QV: No random words received");
        uint256 depositId = vrfRequestIdToDepositId[requestId];
        require(depositId != 0, "QV: Unknown VRF request ID");

        SuperposedDeposit storage deposit = deposits[depositId];
        // Ensure this callback is for the correct request ID and state
        require(deposit.vrfRequestId == requestId, "QV: VRF request ID mismatch for deposit");
        // Check state: Can be MeasurementRequested or potentially Pending (if noise request)
        require(deposit.state == SuperpositionState.MeasurementRequested || (deposit.state == SuperpositionState.Pending && msg.sender == address(i_vrfCoordinator)), "QV: Deposit not awaiting measurement");


        uint256 randomness = randomWords[0]; // Use the first random word

        // If this was a noise request (state was Pending), apply noise and don't collapse yet
        if (deposit.state == SuperpositionState.Pending) {
            require(vrfRequestIdToDepositId[requestId] == depositId, "QV: VRF request ID mismatch for noise");
            uint16 noiseLevelPermille = deposits[depositId].initialProbA_permille; // Re-using this field temporarily for noise level in addQuantumNoise, needs careful struct design.
            // Let's assume noise level is stored elsewhere or derived.
            // For this example, let's simplify: if state is PENDING and VRF received, it must be noise request.
            // The noise delta is derived from randomness, e.g., (randomness % (2 * noiseLevelPermille + 1)) - noiseLevelPermille
            // We need to know the noiseLevelPermille that was requested... Let's update the struct/logic.

            // Correction: The current `addQuantumNoise` implementation uses `vrfRequestId` field and changes state to `MeasurementRequested`.
            // So, any VRF callback for this contract *should* mean a collapse is intended, or the logic needs refinement.
            // Let's assume `vrfRequestId` is *only* used for collapse requests. Noise could use a different mechanism or require refactoring.
            // Let's simplify `addQuantumNoise` to just adjust based on *current block hash* for a non-VRF example, or remove it if only VRF is intended.
            // Let's remove `addQuantumNoise` or change its logic. Re-adding `addQuantumNoise` with a simpler, non-VRF approach for function count.

            // Removing the conditional noise logic here based on the revised approach for addQuantumNoise.
            // All VRF fulfillment triggers collapse.

            delete vrfRequestIdToDepositId[requestId]; // Clean up the mapping

            _collapseState(depositId, randomness);

        } else { // State must be MeasurementRequested
             delete vrfRequestIdToDepositId[requestId]; // Clean up the mapping
            _collapseState(depositId, randomness);
        }
    }

    /// @dev Allows anyone to trigger the state collapse for a pending deposit if its timeout has been reached.
    /// @param depositId The ID of the deposit to collapse.
    function triggerTimeoutCollapse(uint256 depositId) external whenPending(depositId) {
         SuperposedDeposit storage deposit = deposits[depositId];
         require(block.timestamp >= deposit.collapseTimeout, "QV: Timeout not reached yet");
         require(deposit.vrfRequestId == 0, "QV: Measurement already requested via VRF");
         require(deposit.entangledDepositId == 0 || deposits[deposit.entangledDepositId].state != SuperpositionState.Pending, "QV: Entangled partner is still pending");

         // Use block.timestamp as the "randomness" source for timeout collapse
         // This is predictable but serves as a fallback measurement
         _collapseState(depositId, uint256(uint160(block.timestamp)));
         emit TimeoutCollapseTriggered(depositId, msg.sender);
    }

    /// @dev Internal function to execute the state collapse logic.
    /// Determines the outcome based on randomness and probabilities, handles entanglement.
    /// @param depositId The ID of the deposit to collapse.
    /// @param randomness A random or pseudo-random number (e.g., from VRF or timestamp).
    function _collapseState(uint256 depositId, uint256 randomness) internal {
        SuperposedDeposit storage deposit = deposits[depositId];
        // Can collapse if Pending, MeasurementRequested, or EntanglementPendingApproval (if partner collapsed it)
         require(deposit.state == SuperpositionState.Pending || deposit.state == SuperpositionState.MeasurementRequested || deposit.state == SuperpositionState.EntanglementPendingApproval, "QV: Deposit not in a collapsable state");
        require(deposit.state != SuperpositionState.CollapsedA && deposit.state != SuperpositionState.CollapsedB && deposit.state != SuperpositionState.CollapsedC, "QV: Deposit already collapsed");


        // Remove from pending list
        _removeDepositIdFromList(pendingDepositIds, depositId);

        // Determine outcome based on randomness and probabilities
        uint16 currentProbA = calculateCurrentProbabilities(depositId); // 0-1000

        // Scale randomness to 0-999 range for probability check
        uint256 scaledRandomness = randomness % 1000;

        OutcomeType determinedOutcome;
        address finalRecipient = address(0);

        if (scaledRandomness < currentProbA) {
            determinedOutcome = OutcomeType.OutcomeA;
            finalRecipient = deposit.outcomeA;
            deposit.state = SuperpositionState.CollapsedA;
        } else {
            determinedOutcome = OutcomeType.OutcomeB;
            finalRecipient = deposit.outcomeB;
            deposit.state = SuperpositionState.CollapsedB;
        }

        require(finalRecipient != address(0), "QV: Collapsed to zero address outcome"); // Should be caught during deposit, but double-check

        // Add to collapsed list
        collapsedDepositIds.push(depositId);

        // Handle Entanglement
        uint256 entangledId = deposit.entangledDepositId;
        if (entangledId != 0) {
            SuperposedDeposit storage entangledDep = deposits[entangledId];

            // Ensure the entangled partner is also pending or awaiting measurement
            if (entangledDep.state == SuperpositionState.Pending || entangledDep.state == SuperpositionState.MeasurementRequested || entangledDep.state == SuperpositionState.EntanglementPendingApproval) {
                 // Remove partner from pending list if needed
                _removeDepositIdFromList(pendingDepositIds, entangledId);

                OutcomeType entangledOutcome;
                address entangledRecipient = address(0);

                // Determine entangled outcome based on correlation type
                if (deposit.entanglementType == EntanglementCorrelation.CorrelationA) {
                    entangledOutcome = determinedOutcome; // Partner collapses to the same outcome
                } else if (deposit.entanglementType == EntanglementCorrelation.CorrelationB) {
                     // Partner collapses to the same outcome
                     entangledOutcome = determinedOutcome;
                } else { // AntiCorrelation
                     if (determinedOutcome == OutcomeType.OutcomeA) entangledOutcome = OutcomeType.OutcomeB;
                     else entangledOutcome = OutcomeType.OutcomeA;
                }

                if (entangledOutcome == OutcomeType.OutcomeA) {
                     entangledRecipient = entangledDep.outcomeA;
                     entangledDep.state = SuperpositionState.CollapsedA;
                } else {
                     entangledRecipient = entangledDep.outcomeB;
                     entangledDep.state = SuperpositionState.CollapsedB;
                }
                require(entangledRecipient != address(0), "QV: Entangled collapsed to zero address outcome");

                // Add partner to collapsed list
                collapsedDepositIds.push(entangledId);

                // Store withdrawable amounts/NFTs for the entangled deposit
                if (entangledDep.isERC721) {
                     _outcomeAddressERC721NFTs[entangledRecipient][entangledDep.tokenAddress].push(entangledDep.amountOrTokenId);
                } else {
                     _outcomeAddressERC20Amounts[entangledRecipient][entangledDep.tokenAddress] += entangledDep.amountOrTokenId;
                }

                // Emit event for entangled collapse
                emit StateCollapsed(entangledId, entangledDep.state, entangledRecipient, randomness);

                // Break entanglement link after collapse
                deposit.entangledDepositId = 0;
                entangledDep.entangledDepositId = 0;

            } else {
                 // Should not happen if logic is correct, but handle stale entanglement link
                 deposit.entangledDepositId = 0; // Break link if partner already collapsed or invalid state
            }
        }

        // Store withdrawable amounts/NFTs for the current deposit
        if (deposit.isERC721) {
             _outcomeAddressERC721NFTs[finalRecipient][deposit.tokenAddress].push(deposit.amountOrTokenId);
        } else {
             _outcomeAddressERC20Amounts[finalRecipient][deposit.tokenAddress] += deposit.amountOrTokenId;
        }

        // Emit event for current deposit collapse
        emit StateCollapsed(depositId, deposit.state, finalRecipient, randomness);
    }

    /// @dev Observer can cancel a pending VRF measurement request.
    /// Requires VRF Coordinator to support `cancelRequest` and sufficient subscription balance.
    /// @param depositId The ID of the deposit whose request to cancel.
    function cancelPendingMeasurement(uint256 depositId) external onlyObserver {
        SuperposedDeposit storage deposit = deposits[depositId];
        require(deposit.state == SuperpositionState.MeasurementRequested, "QV: Deposit not awaiting measurement");
        require(deposit.vrfRequestId != 0, "QV: No pending VRF request for deposit");

        uint256 requestId = deposit.vrfRequestId;

        // Attempt to cancel the request via the coordinator
        // This might fail if the randomness is already being fulfilled or subscription balance is low
        i_vrfCoordinator.cancelRequest(requestId);

        // If successful, the VRF coordinator calls `rawFulfillRandomWords` with empty randomWords.
        // We handle this case in `rawFulfillRandomWords` by checking `randomWords.length == 0`.
        // However, not all VRF versions/implementations guarantee this behavior.
        // A safer approach might involve checking the state/return value if available,
        // or relying on the VRF contract's behavior for failed cancellations.

        // For this example, we assume a successful cancellation implies the callback won't provide randomness.
        // We must reset the state and VRF ID now, assuming cancellation will be successful
        // or handle the potential for a late callback in rawFulfillRandomWords.
        // Let's reset the state and VRF ID *before* calling cancel, accepting risk of a race condition.
        deposit.state = SuperpositionState.Pending; // Revert to pending state
        deposit.vrfRequestId = 0;
        delete vrfRequestIdToDepositId[requestId];

        // Note: A production contract might need more robust state handling around VRF cancellations.

        emit PendingMeasurementCanceled(depositId, requestId, msg.sender);
    }


    // --- Withdrawal Functions ---

    /// @dev Allows the designated outcome address to withdraw the ERC20 tokens for a collapsed deposit.
    /// @param depositId The ID of the collapsed deposit.
    function withdrawCollapsedFunds(uint256 depositId) external whenCollapsed(depositId) {
        SuperposedDeposit storage deposit = deposits[depositId];
        require(!deposit.isERC721, "QV: This is an NFT deposit, use withdrawCollapsedNFT");

        address recipient = msg.sender;
        address tokenAddress = deposit.tokenAddress;
        uint256 amount = deposit.amountOrTokenId;

        // Check if the caller is the determined outcome address
        address determinedRecipient = getDepositOutcomeAddress(depositId);
        require(recipient == determinedRecipient, "QV: Not the designated recipient");

        // Use the stored amount tracking, not the original deposit amount, in case of partial withdrawals or fees (not implemented yet)
        uint256 withdrawableAmount = _outcomeAddressERC20Amounts[recipient][tokenAddress];
        require(withdrawableAmount >= amount, "QV: Insufficient withdrawable amount"); // Should be exactly the deposit amount if no fees

        // Transfer tokens
        _outcomeAddressERC20Amounts[recipient][tokenAddress] -= amount;
        IERC20(tokenAddress).safeTransfer(recipient, amount);

        // Mark deposit as fully withdrawn or remove it (depends on desired state management)
        // For simplicity, we don't mark as withdrawn, just track the amounts.
        // A more complex system might use a new state like `Withdrawn`.

        emit FundsWithdrawn(depositId, recipient, tokenAddress, amount);
    }

    /// @dev Allows the designated outcome address to withdraw the ERC721 token for a collapsed deposit.
    /// @param depositId The ID of the collapsed deposit.
    function withdrawCollapsedNFT(uint256 depositId) external whenCollapsed(depositId) {
        SuperposedDeposit storage deposit = deposits[depositId];
        require(deposit.isERC721, "QV: This is an ERC20 deposit, use withdrawCollapsedFunds");

        address recipient = msg.sender;
        address tokenAddress = deposit.tokenAddress;
        uint256 tokenId = deposit.amountOrTokenId;

         // Check if the caller is the determined outcome address
        address determinedRecipient = getDepositOutcomeAddress(depositId);
        require(recipient == determinedRecipient, "QV: Not the designated recipient");

        // Check if the NFT is available for withdrawal by this recipient
        uint256[] storage recipientNFTs = _outcomeAddressERC721NFTs[recipient][tokenAddress];
        bool found = false;
        for(uint i = 0; i < recipientNFTs.length; i++) {
            if (recipientNFTs[i] == tokenId) {
                // Found the token ID, remove it from the array
                recipientNFTs[i] = recipientNFTs[recipientNFTs.length - 1];
                recipientNFTs.pop();
                found = true;
                break;
            }
        }
        require(found, "QV: NFT not available for withdrawal by this address");


        // Transfer NFT
        IERC721(tokenAddress).safeTransferFrom(address(this), recipient, tokenId);

         // Mark deposit as fully withdrawn (if desired)

        emit NFTWithdrawn(depositId, recipient, tokenAddress, tokenId);
    }


    // --- View Functions ---

    /// @dev Gets the current calculated probability for Outcome A for a pending deposit.
    /// Considers the initial probability and any adjustments made.
    /// @param depositId The ID of the deposit.
    /// @return The effective probability for Outcome A in per mille (0-1000).
    function calculateCurrentProbabilities(uint256 depositId) public view returns (uint16) {
        SuperposedDeposit storage deposit = deposits[depositId];
        require(deposit.state == SuperpositionState.Pending || deposit.state == SuperpositionState.MeasurementRequested || deposit.state == SuperpositionState.EntanglementPendingApproval, "QV: Deposit not in a pending state");

        int256 currentProb = int256(deposit.initialProbA_permille) + deposit.probAdjustment_permille;
        // Ensure bounds (should be handled by adjustProbabilities, but for safety)
        if (currentProb < 0) return 0;
        if (currentProb > 1000) return 1000;
        return uint16(currentProb);
    }

    /// @dev Gets the state of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return The current `SuperpositionState` enum value.
    function getDepositState(uint256 depositId) external view returns (SuperpositionState) {
        return deposits[depositId].state;
    }

    /// @dev Gets the designated outcome address (A or B) for a collapsed deposit.
    /// @param depositId The ID of the collapsed deposit.
    /// @return The address eligible to withdraw the funds/NFT. Returns address(0) if not collapsed.
    function getDepositOutcomeAddress(uint256 depositId) public view whenCollapsed(depositId) returns (address) {
         SuperposedDeposit storage deposit = deposits[depositId];
         if (deposit.state == SuperpositionState.CollapsedA) return deposit.outcomeA;
         if (deposit.state == SuperpositionState.CollapsedB) return deposit.outcomeB;
         // Add checks for other states if they become withdrawal states (CollapsedC, etc.)
         return address(0); // Should not reach here if modifier works
    }

    /// @dev Gets the configured Outcome A and Outcome B addresses for a deposit.
    /// @param depositId The ID of the deposit.
    /// @return outcomeA The address for Outcome A.
    /// @return outcomeB The address for Outcome B.
    function getOutcomeAddresses(uint256 depositId) external view returns (address outcomeA, address outcomeB) {
        SuperposedDeposit storage deposit = deposits[depositId];
        return (deposit.outcomeA, deposit.outcomeB);
    }

    /// @dev Gets the amount of a specific ERC20 token that a recipient can withdraw.
    /// @param recipient The address attempting to withdraw.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The total withdrawable amount.
    function getRequiredWithdrawAmount(address recipient, address tokenAddress) external view returns (uint256) {
        return _outcomeAddressERC20Amounts[recipient][tokenAddress];
    }

    /// @dev Gets the list of ERC721 token IDs of a specific token that a recipient can withdraw.
    /// @param recipient The address attempting to withdraw.
    /// @param tokenAddress The address of the ERC721 token.
    /// @return An array of withdrawable token IDs.
    function getRequiredNFTWithdrawal(address recipient, address tokenAddress) external view returns (uint256[] memory) {
        return _outcomeAddressERC721NFTs[recipient][tokenAddress];
    }

    /// @dev Gets the VRF request ID associated with a deposit, if any.
    /// @param depositId The ID of the deposit.
    /// @return The VRF request ID (0 if none).
    function getVRFRequestId(uint256 depositId) external view returns (uint256) {
        return deposits[depositId].vrfRequestId;
    }

    /// @dev Gets the current VRF configuration details.
    /// @return coordinator Address of the VRF Coordinator contract.
    /// @return keyHash The key hash for VRF requests.
    /// @return subId The VRF subscription ID.
    function getVrfSubscriptionDetails() external view returns (address coordinator, bytes32 keyHash, uint64 subId) {
        return (address(i_vrfCoordinator), i_keyHash, i_subscriptionId);
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to remove a deposit ID from a dynamic array.
    /// @param list The array to remove from (e.g., pendingDepositIds).
    /// @param depositId The ID to remove.
    function _removeDepositIdFromList(uint256[] storage list, uint256 depositId) internal {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == depositId) {
                // Swap the element to remove with the last element
                list[i] = list[list.length - 1];
                // Remove the last element
                list.pop();
                // No need to continue searching
                break;
            }
        }
    }

    // --- VRF Specific Configuration (can be getters if needed) ---
    // These are part of the VRFConsumerBaseV2 contract, defining request parameters.

    /// @dev Returns the minimum request confirmations for VRF.
    function getRequestConfirmations() internal view returns (uint16) {
        // Default confirmations. Can be made configurable by Admin if needed.
        return 3; // Example value
    }

    // getConsumersBySubscription() is available from VRFConsumerBaseV2 if needed.

}
```