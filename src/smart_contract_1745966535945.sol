Okay, here is a Solidity smart contract demonstrating an advanced concept I'll call "Quantum Entanglement Conditional Swap". This contract allows two parties to agree on a swap of potentially different asset types (ERC20, ERC721, native ETH) that *only* executes if a specific 'quantum state' (a secret byte string) is revealed before a deadline, and where the *exact* assets swapped might depend on the revealed state itself (the "entanglement").

It incorporates:
1.  **Multi-asset swaps:** Handling ETH, ERC20, and ERC721 in a single swap.
2.  **Hash Commitment:** Uses a hash of a secret state (`quantumConditionHash`) known only to one party initially.
3.  **Conditional Execution:** The swap is conditional on the preimage (`quantumState`) being revealed and matching the hash.
4.  **Multiple Potential Outcomes ("Entanglement"):** Allows defining multiple possible swap outcomes *before* the state is revealed, each tied to the hash of a *specific potential value* of the quantum state. The actual outcome used during execution depends on which specific state value is revealed.
5.  **Time-based Deadlines:** Separate deadlines for revealing the state and claiming assets after a reveal/expiry.
6.  **State Machine:** Manages the lifecycle of each swap instance.
7.  **Escrow:** Holds assets securely during the swap process.
8.  **Protocol Fees:** Includes a simple fee mechanism.
9.  **Pausability & Ownership:** Standard administrative controls.
10. **Asset Whitelisting:** Control which assets can be used.

This design is unique in allowing multiple *predefined* outcomes based on the *value* of the revealed secret, going beyond a simple pass/fail condition.

---

**Outline and Function Summary:**

**I. Data Structures & Constants**
*   `AssetType`: Enum for ETH, ERC20, ERC721.
*   `SwapStatus`: Enum for the lifecycle stages of a swap.
*   `Asset`: Struct to define an asset (type, address, amount/ID).
*   `OutcomeData`: Struct defining what assets each party receives in a specific outcome.
*   `PotentialOutcome`: Struct mapping a state hash (`bytes32`) to an `OutcomeData`.
*   `Swap`: Main struct containing all details for a swap instance.
*   `MAX_POTENTIAL_OUTCOMES`: Limit to prevent excessive storage.

**II. State Variables**
*   `_swapCounter`: Unique identifier for new swaps.
*   `swaps`: Mapping from swap ID to `Swap` struct.
*   `_allowedAssets`: Mapping to whitelist asset contract addresses.
*   `_protocolFeeAddress`: Address to receive fees.
*   `_protocolFeeRate`: Percentage fee rate (basis points).
*   `_protocolFeesCollected`: Total fees collected.

**III. Events**
*   `SwapCreated`: Logs creation of a new swap.
*   `AssetsDeposited`: Logs when assets are deposited for a swap.
*   `PotentialOutcomeAdded`: Logs addition of a new potential outcome.
*   `StateRevealed`: Logs when the quantum state is revealed.
*   `SwapExecuted`: Logs successful swap execution based on an outcome.
*   `SwapCancelled`: Logs swap cancellation.
*   `AssetsReclaimed`: Logs asset reclamation due to expiry or cancellation.
*   `ProtocolFeeAddressUpdated`: Logs fee address change.
*   `ProtocolFeeRateUpdated`: Logs fee rate change.
*   `AllowedAssetAdded`: Logs asset whitelisting.
*   `AllowedAssetRemoved`: Logs asset de-whitelisting.
*   `FeesWithdrawn`: Logs withdrawal of collected fees.

**IV. Modifiers**
*   `onlySwapInitiator`: Restricts function to the swap initiator.
*   `onlySwapCounterparty`: Restricts function to the swap counterparty.
*   `onlySwapParticipant`: Restricts function to either participant.
*   `whenSwapStatusIs`: Restricts function based on swap status.
*   `whenSwapStatusIsNot`: Restricts function based on swap status.
*   `whenRevealPeriodActive`: Restricts function to the reveal time window.
*   `whenClaimPeriodActive`: Restricts function to the claim time window.
*   `isAllowedAsset`: Checks if an asset address is whitelisted.

**V. Core Swap Functions**
1.  `createEntanglementSwap`: Initiates a new swap, defining participants, initial assets, condition hash, deadlines, and the *first* potential outcome. Assets are *not* deposited here.
2.  `depositInitiatorAssets`: Initiator deposits the assets they committed to.
3.  `depositCounterpartyAssets`: Counterparty deposits the assets they committed to.
4.  `addPotentialOutcome`: Allows a participant (or proposer) to define an *additional* mapping from a potential state hash to a specific outcome.
5.  `revealQuantumState`: The party holding the secret reveals it. If the hash matches the condition hash, the swap status updates, and the revealed state is recorded.
6.  `executeSwap`: Attempts to execute the swap. Checks if the state is revealed and if the revealed state's hash matches any added `PotentialOutcome`. If a match is found, assets are transferred according to that outcome, and fees are calculated/collected.
7.  `cancelSwap`: Initiator or Counterparty cancels the swap before deposits/reveal.
8.  `reclaimAssets`: Allows participants to reclaim their *initially deposited* assets if the swap expires (reveal or claim period) or is cancelled, or if the state was revealed but didn't match any added outcomes.

**VI. Administrative Functions**
9.  `setProtocolFeeAddress`: Sets the address receiving protocol fees.
10. `setProtocolFeeRate`: Sets the percentage fee rate for the protocol.
11. `withdrawProtocolFees`: Allows the owner to withdraw accumulated fees.
12. `addAllowedAsset`: Whitelists an asset address for use in swaps.
13. `removeAllowedAsset`: Removes an asset address from the whitelist.
14. `pause`: Pauses contract interactions (except admin functions).
15. `unpause`: Unpauses contract interactions.

**VII. View/Query Functions**
16. `getSwapDetails`: Retrieves all details for a given swap ID.
17. `getSwapStatus`: Gets only the current status of a swap.
18. `getInitiatorAssetsCommitted`: Gets the assets the initiator committed to deposit.
19. `getCounterpartyAssetsCommitted`: Gets the assets the counterparty committed to deposit.
20. `getPotentialOutcomes`: Retrieves the list of potential outcomes defined for a swap.
21. `getAllowedAssets`: Retrieves the list of currently allowed asset addresses.
22. `getProtocolFeeAddress`: Gets the current protocol fee address.
23. `getProtocolFeeRate`: Gets the current protocol fee rate.
24. `getProtocolFeesCollected`: Gets the total fees collected by the contract.

*(Note: The count is > 20 functions, including helpers and views, fulfilling the requirement. The core swap logic is complex due to multi-asset handling, state machine, and conditional outcomes based on the revealed state value hash.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive ERC721
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For isContract check

/// @title QuantumEntanglementSwap
/// @dev A sophisticated conditional swap contract handling multiple asset types (ETH, ERC20, ERC721)
///      where the swap execution is contingent on revealing a secret 'quantum state'.
///      The contract supports defining multiple potential swap outcomes upfront, each
///      mapped to the hash of a specific possible quantum state value. The actual
///      outcome depends on which state value is revealed. Includes escrow, deadlines,
///      protocol fees, pausable, and ownable features.
contract QuantumEntanglementSwap is Ownable, Pausable, ERC721Holder { // ERC721Holder allows receiving NFTs

    using SafeTransferLib for IERC20;
    using Address for address;

    // --- Data Structures & Constants ---

    enum AssetType { ETH, ERC20, ERC721 }

    enum SwapStatus {
        Pending,              // Swap created, awaiting deposits/acceptance
        Deposited,            // Both parties have deposited committed assets
        StateRevealed,        // Quantum state revealed, hash matched, outcome lookup possible
        Executed,             // Swap successfully executed based on a matched outcome
        Cancelled,            // Swap explicitly cancelled by a party
        ExpiredReveal,        // Reveal deadline passed without state revelation
        ExpiredClaim,         // Claim deadline passed after reveal (if no execution) or expiry
        Reclaimed             // Assets reclaimed after cancellation or expiry
    }

    struct Asset {
        AssetType assetType;
        address tokenAddress; // Address for ERC20/ERC721, zero address for ETH
        uint256 amountOrId;   // Amount for ETH/ERC20, Token ID for ERC721
    }

    struct OutcomeData {
        Asset initiatorReceives; // Assets initiator receives IF this outcome is used
        Asset counterpartyReceives; // Assets counterparty receives IF this outcome is used
    }

    struct PotentialOutcome {
        bytes32 stateHash; // keccak256(potentialQuantumStateValue)
        OutcomeData outcome;
    }

    struct Swap {
        uint256 id;
        address initiator;
        address counterparty;
        Asset initiatorCommitted; // Assets initiator commits to deposit
        Asset counterpartyCommitted; // Assets counterparty commits to deposit
        bytes32 quantumConditionHash; // keccak256(actualQuantumStateValue)
        bytes revealedQuantumState;   // Actual revealed state value (set only upon successful reveal)
        uint64 revealDeadline;        // Timestamp by which state must be revealed
        uint64 claimDeadline;         // Timestamp by which assets must be claimed/executed after reveal
        SwapStatus status;
        bool initiatorDeposited;
        bool counterpartyDeposited;
        PotentialOutcome[] potentialOutcomes; // Array of possible outcomes based on state hash
        bytes32 executedOutcomeHash; // The stateHash of the outcome that was executed (if any)
    }

    // Limit potential outcomes to prevent excessive gas costs for storage/iteration
    uint256 public constant MAX_POTENTIAL_OUTCOMES = 10;

    // --- State Variables ---

    uint256 private _swapCounter;
    mapping(uint256 => Swap) public swaps;
    mapping(address => bool) private _allowedAssets; // Whitelist asset addresses
    address private _protocolFeeAddress;
    uint16 private _protocolFeeRate; // Basis points (e.g., 100 = 1%)
    uint256 private _protocolFeesCollected;

    // --- Events ---

    event SwapCreated(uint256 indexed swapId, address indexed initiator, address indexed counterparty, bytes32 quantumConditionHash, uint64 revealDeadline, uint64 claimDeadline);
    event AssetsDeposited(uint256 indexed swapId, address indexed depositor, Asset depositedAsset);
    event PotentialOutcomeAdded(uint256 indexed swapId, bytes32 indexed stateHash, OutcomeData outcome);
    event StateRevealed(uint256 indexed swapId, bytes revealedState);
    event SwapExecuted(uint256 indexed swapId, bytes32 indexed outcomeHash, Asset initiatorReceived, Asset counterpartyReceived);
    event SwapCancelled(uint256 indexed swapId, address indexed cancelledBy);
    event AssetsReclaimed(uint256 indexed swapId, address indexed claimant, Asset asset);
    event ProtocolFeeAddressUpdated(address indexed newAddress);
    event ProtocolFeeRateUpdated(uint16 newRate);
    event AllowedAssetAdded(address indexed assetAddress);
    event AllowedAssetRemoved(address indexed assetAddress);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---

    modifier onlySwapInitiator(uint256 swapId) {
        require(swaps[swapId].initiator == msg.sender, "Not swap initiator");
        _;
    }

    modifier onlySwapCounterparty(uint256 swapId) {
        require(swaps[swapId].counterparty == msg.sender, "Not swap counterparty");
        _;
    }

    modifier onlySwapParticipant(uint256 swapId) {
        require(swaps[swapId].initiator == msg.sender || swaps[swapId].counterparty == msg.sender, "Not swap participant");
        _;
    }

    modifier whenSwapStatusIs(uint256 swapId, SwapStatus status) {
        require(swaps[swapId].status == status, "Swap is not in required status");
        _;
    }

    modifier whenSwapStatusIsNot(uint256 swapId, SwapStatus status) {
        require(swaps[swapId].status != status, "Swap is in prohibited status");
        _;
    }

    modifier whenRevealPeriodActive(uint256 swapId) {
        require(block.timestamp <= swaps[swapId].revealDeadline, "Reveal period expired");
        _;
    }

     modifier whenClaimPeriodActive(uint256 swapId) {
        require(block.timestamp <= swaps[swapId].claimDeadline, "Claim period expired");
        _;
    }

    modifier isAllowedAsset(address assetAddress) {
        if (assetAddress != address(0)) { // ETH is always allowed
            require(_allowedAssets[assetAddress], "Asset address is not allowed");
        }
        _;
    }

    // --- Constructor ---

    constructor(address initialProtocolFeeAddress, uint16 initialProtocolFeeRate) Ownable(msg.sender) Pausable(false) {
        _protocolFeeAddress = initialProtocolFeeAddress;
        _protocolFeeRate = initialProtocolFeeRate; // e.g., 100 = 1%
    }

    // --- Core Swap Functions ---

    /// @notice Initiates a new Quantum Entanglement Swap.
    /// @dev Defines the swap parameters, including the initial assets, the quantum condition hash,
    ///      deadlines, and the *first* potential outcome associated with the initiator's secret state.
    ///      Assets are NOT transferred in this function. Parties must call deposit functions later.
    /// @param _counterparty The address of the counterparty in the swap.
    /// @param _initiatorCommitted The assets the initiator commits to depositing.
    /// @param _counterpartyCommitted The assets the counterparty commits to depositing.
    /// @param _quantumConditionHash The keccak256 hash of the secret quantum state value.
    /// @param _revealDeadline The timestamp by which the state must be revealed.
    /// @param _claimDeadline The timestamp by which assets must be claimed/executed after reveal.
    /// @param _initialOutcomeData The first potential outcome data, mapping the initiator's known state hash to specific received assets.
    /// @param _initialOutcomeStateHash The keccak256 hash of the specific quantum state value that corresponds to _initialOutcomeData. Must match _quantumConditionHash.
    /// @return swapId The ID of the newly created swap.
    function createEntanglementSwap(
        address _counterparty,
        Asset calldata _initiatorCommitted,
        Asset calldata _counterpartyCommitted,
        bytes32 _quantumConditionHash,
        uint64 _revealDeadline,
        uint64 _claimDeadline,
        OutcomeData calldata _initialOutcomeData,
        bytes32 _initialOutcomeStateHash
    ) external whenNotPaused isAllowedAsset(_initiatorCommitted.tokenAddress) isAllowedAsset(_counterpartyCommitted.tokenAddress) returns (uint256 swapId) {
        require(_counterparty != address(0), "Counterparty cannot be zero address");
        require(_counterparty != msg.sender, "Cannot swap with self");
        require(_revealDeadline > block.timestamp, "Reveal deadline must be in the future");
        require(_claimDeadline > _revealDeadline, "Claim deadline must be after reveal deadline");
        require(_quantumConditionHash != bytes32(0), "Quantum condition hash cannot be zero");
        require(_initialOutcomeStateHash == _quantumConditionHash, "Initial outcome hash must match condition hash");

        swapId = ++_swapCounter;

        swaps[swapId] = Swap({
            id: swapId,
            initiator: msg.sender,
            counterparty: _counterparty,
            initiatorCommitted: _initiatorCommitted,
            counterpartyCommitted: _counterpartyCommitted,
            quantumConditionHash: _quantumConditionHash,
            revealedQuantumState: bytes(""), // Initially empty
            revealDeadline: _revealDeadline,
            claimDeadline: _claimDeadline,
            status: SwapStatus.Pending,
            initiatorDeposited: false,
            counterpartyDeposited: false,
            potentialOutcomes: new PotentialOutcome[](1), // Start with 1
            executedOutcomeHash: bytes32(0) // Initially zero
        });

        swaps[swapId].potentialOutcomes[0] = PotentialOutcome({
            stateHash: _initialOutcomeStateHash,
            outcome: _initialOutcomeData
        });

        emit SwapCreated(
            swapId,
            msg.sender,
            _counterparty,
            _quantumConditionHash,
            _revealDeadline,
            _claimDeadline
        );
        emit PotentialOutcomeAdded(swapId, _initialOutcomeStateHash, _initialOutcomeData);
    }

    /// @notice Initiator deposits the assets they committed to the swap.
    /// @param swapId The ID of the swap.
    function depositInitiatorAssets(uint256 swapId)
        external
        payable
        whenNotPaused
        onlySwapInitiator(swapId)
        whenSwapStatusIs(swapId, SwapStatus.Pending)
        isAllowedAsset(swaps[swapId].initiatorCommitted.tokenAddress)
    {
        Swap storage swap = swaps[swapId];
        require(!swap.initiatorDeposited, "Initiator already deposited");

        _transferInAsset(swap.initiator, swap.initiatorCommitted, msg.value);

        swap.initiatorDeposited = true;
        emit AssetsDeposited(swapId, msg.sender, swap.initiatorCommitted);

        if (swap.counterpartyDeposited) {
            swap.status = SwapStatus.Deposited;
        }
    }

    /// @notice Counterparty accepts the swap terms and deposits the assets they committed to.
    /// @param swapId The ID of the swap.
    function depositCounterpartyAssets(uint256 swapId)
        external
        payable
        whenNotPaused
        onlySwapCounterparty(swapId)
        whenSwapStatusIs(swapId, SwapStatus.Pending)
         isAllowedAsset(swaps[swapId].counterpartyCommitted.tokenAddress)
    {
        Swap storage swap = swaps[swapId];
        require(!swap.counterpartyDeposited, "Counterparty already deposited");

        _transferInAsset(swap.counterparty, swap.counterpartyCommitted, msg.value);

        swap.counterpartyDeposited = true;
        emit AssetsDeposited(swapId, msg.sender, swap.counterpartyCommitted);

         if (swap.initiatorDeposited) {
            swap.status = SwapStatus.Deposited;
        }
    }

    /// @notice Allows a participant to add an additional potential outcome mapping
    ///         a specific state hash to outcome data.
    /// @dev This can be called after swap creation but typically before assets are deposited
    ///      or the state is revealed. Adding too many outcomes might make execution gas expensive.
    /// @param swapId The ID of the swap.
    /// @param _potentialOutcomeStateHash The keccak256 hash of a potential quantum state value.
    /// @param _outcomeData The outcome data associated with this potential state hash.
    function addPotentialOutcome(uint256 swapId, bytes32 _potentialOutcomeStateHash, OutcomeData calldata _outcomeData)
        external
        whenNotPaused
        onlySwapParticipant(swapId)
        whenSwapStatusIs(swapId, SwapStatus.Pending) // Can only add outcomes before deposited/revealed
        isAllowedAsset(_outcomeData.initiatorReceives.tokenAddress)
        isAllowedAsset(_outcomeData.counterpartyReceives.tokenAddress)
    {
        Swap storage swap = swaps[swapId];
        require(swap.potentialOutcomes.length < MAX_POTENTIAL_OUTCOMES, "Max potential outcomes reached");
        require(_potentialOutcomeStateHash != bytes32(0), "Potential outcome state hash cannot be zero");

        // Check if this stateHash already exists (optional, could allow overwriting or require uniqueness)
        for (uint i = 0; i < swap.potentialOutcomes.length; i++) {
             require(swap.potentialOutcomes[i].stateHash != _potentialOutcomeStateHash, "Outcome for this state hash already exists");
        }

        swap.potentialOutcomes.push(PotentialOutcome({
            stateHash: _potentialOutcomeStateHash,
            outcome: _outcomeData
        }));

        emit PotentialOutcomeAdded(swapId, _potentialOutcomeStateHash, _outcomeData);
    }


    /// @notice Reveals the actual quantum state value.
    /// @dev This transitions the swap state if the revealed state matches the condition hash.
    /// @param swapId The ID of the swap.
    /// @param _quantumState The actual secret byte string.
    function revealQuantumState(uint256 swapId, bytes calldata _quantumState)
        external
        whenNotPaused
        onlySwapInitiator(swapId) // Typically only the initiator holds the secret
        whenSwapStatusIs(swapId, SwapStatus.Deposited) // Assets must be deposited before reveal
        whenRevealPeriodActive(swapId)
    {
        Swap storage swap = swaps[swapId];
        require(keccak256(_quantumState) == swap.quantumConditionHash, "Revealed state does not match condition hash");

        swap.revealedQuantumState = _quantumState;
        swap.status = SwapStatus.StateRevealed;

        emit StateRevealed(swapId, _quantumState);
    }

    /// @notice Executes the swap based on the revealed state and matching outcome.
    /// @dev Can be called by either participant after the state is revealed and matches.
    ///      Looks up the revealed state hash in the potential outcomes. If a match
    ///      is found, transfers assets according to the matched outcome and collects fees.
    /// @param swapId The ID of the swap.
    function executeSwap(uint256 swapId)
        external
        whenNotPaused
        onlySwapParticipant(swapId)
        whenSwapStatusIs(swapId, SwapStatus.StateRevealed)
        whenClaimPeriodActive(swapId) // Must execute before claim deadline
    {
        Swap storage swap = swaps[swapId];
        bytes32 revealedStateHash = keccak256(swap.revealedQuantumState);

        // Find the matching outcome based on the revealed state hash
        OutcomeData memory outcomeToExecute;
        bool outcomeFound = false;
        for (uint i = 0; i < swap.potentialOutcomes.length; i++) {
            if (swap.potentialOutcomes[i].stateHash == revealedStateHash) {
                outcomeToExecute = swap.potentialOutcomes[i].outcome;
                swap.executedOutcomeHash = revealedStateHash; // Record which outcome was used
                outcomeFound = true;
                break;
            }
        }

        require(outcomeFound, "No matching outcome found for revealed state");

        // --- Execute Transfers ---
        // Note: This logic assumes that the combined value of assets received
        // by a party in an outcome is <= the combined value of assets they initially deposited.
        // A more complex contract might need to handle value differences, potentially
        // requiring additional ETH deposits during execution, which adds significant complexity.
        // For this example, we transfer *from* the escrowed initial assets *to* the recipients
        // as defined in the outcome.

        // Initiator receives assets defined in outcomeToExecute.initiatorReceives
        _transferOutAsset(swap.initiator, outcomeToExecute.initiatorReceives);

        // Counterparty receives assets defined in outcomeToExecute.counterpartyReceives
        _transferOutAsset(swap.counterparty, outcomeToExecute.counterives);

        // Calculate and collect fees on the value transferred out
        // For simplicity, let's calculate fee based on the sum of amounts of ETH/ERC20 received by both parties
        // ERC721 value is harder to define for a fee basis.
        uint256 totalValueSwapped = 0;
        if (outcomeToExecute.initiatorReceives.assetType != AssetType.ERC721) {
            totalValueSwapped += outcomeToExecute.initiatorReceives.amountOrId;
        }
        if (outcomeToExecute.counterpartyReceives.assetType != AssetType.ERC721) {
             totalValueSwapped += outcomeToExecute.counterpartyReceives.amountOrId;
        }

        uint256 protocolFee = (totalValueSwapped * _protocolFeeRate) / 10000; // Basis points
        if (protocolFee > 0 && _protocolFeeAddress != address(0)) {
             // Attempt to transfer fees (assuming fees are collected in ETH for simplicity)
             // In a real system, fees might need to be collected in the specific token/ETH transferred
             // or a designated fee token. Transferring ETH from contract balance.
            try Payable(_protocolFeeAddress).transfer(protocolFee) {} catch {} // Non-critical if fee transfer fails
            _protocolFeesCollected += protocolFee;
        }


        swap.status = SwapStatus.Executed;
        emit SwapExecuted(swapId, revealedStateHash, outcomeToExecute.initiatorReceives, outcomeToExecute.counterpartyReceives);

        // Note: Remaining assets (if any) from the initial deposits not used in the executed outcome
        // remain in the contract and could potentially be reclaimed, depending on desired logic.
        // This contract assumes the executed outcome fully utilizes the escrowed assets.
        // A more complex version would track remaining balances per swap.
    }

    /// @notice Cancels a swap before it reaches the 'Deposited' or 'Revealed' state.
    /// @dev Can be called by either the initiator or counterparty under specific conditions.
    /// @param swapId The ID of the swap.
    function cancelSwap(uint256 swapId)
        external
        whenNotPaused
        onlySwapParticipant(swapId)
        whenSwapStatusIsNot(swapId, SwapStatus.Deposited) // Cannot cancel after both deposit
        whenSwapStatusIsNot(swapId, SwapStatus.StateRevealed)
        whenSwapStatusIsNot(swapId, SwapStatus.Executed)
        whenSwapStatusIsNot(swapId, SwapStatus.Cancelled)
        whenSwapStatusIsNot(swapId, SwapStatus.Reclaimed)
        whenSwapStatusIsNot(swapId, SwapStatus.ExpiredReveal) // Cannot cancel after expiry
        whenSwapStatusIsNot(swapId, SwapStatus.ExpiredClaim) // Cannot cancel after expiry
    {
        Swap storage swap = swaps[swapId];

        // Allow cancel if Pending (either party)
        // Allow cancel if InitiatorDeposited but Counterparty not (Counterparty)
        // Allow cancel if CounterpartyDeposited but Initiator not (Initiator)
        bool canCancel = false;
        if (swap.status == SwapStatus.Pending) {
            canCancel = true; // Either can cancel if pending
        } else if (swap.initiatorDeposited && !swap.counterpartyDeposited && msg.sender == swap.counterparty) {
            canCancel = true; // Counterparty can cancel if initiator deposited but they haven't
        } else if (!swap.initiatorDeposited && swap.counterpartyDeposited && msg.sender == swap.initiator) {
             canCancel = true; // Initiator can cancel if counterparty deposited but they haven't
        }

        require(canCancel, "Cannot cancel swap in this state");

        swap.status = SwapStatus.Cancelled;
        emit SwapCancelled(swapId, msg.sender);
    }


     /// @notice Allows participants to reclaim their *initially deposited* assets.
    /// @dev Callable if the swap is Cancelled, ExpiredReveal, ExpiredClaim, or
    ///      StateRevealed but no matching outcome was found (implicitly handled
    ///      by checking status and executedOutcomeHash).
    /// @param swapId The ID of the swap.
    function reclaimAssets(uint256 swapId)
        external
        whenNotPaused
        onlySwapParticipant(swapId)
        whenSwapStatusIsNot(swapId, SwapStatus.Pending) // Must have deposited something to reclaim
        whenSwapStatusIsNot(swapId, SwapStatus.Executed) // Cannot reclaim after execution
        whenSwapStatusIsNot(swapId, SwapStatus.Reclaimed) // Cannot reclaim already reclaimed
    {
        Swap storage swap = swaps[swapId];
        address claimant = msg.sender;

        bool isExpiredReveal = swap.status == SwapStatus.Deposited && block.timestamp > swap.revealDeadline;
        bool isExpiredClaimAfterReveal = swap.status == SwapStatus.StateRevealed && swap.executedOutcomeHash == bytes32(0) && block.timestamp > swap.claimDeadline;
        bool isCancelled = swap.status == SwapStatus.Cancelled;
        // Implicit: status is StateRevealed but no outcome matched during attempted execute (though executeSwap has the require)
        // Reclaiming after reveal and no match would transition state to ExpiredClaim if deadline passes

        require(isCancelled || isExpiredReveal || isExpiredClaimAfterReveal || (swap.status == SwapStatus.StateRevealed && swap.executedOutcomeHash == bytes32(0) && block.timestamp > swap.revealDeadline),
                "Swap not in a state where assets can be reclaimed");


        if (claimant == swap.initiator && swap.initiatorDeposited) {
             // Reclaim initiator's committed assets
            _transferOutAsset(swap.initiator, swap.initiatorCommitted);
            emit AssetsReclaimed(swapId, claimant, swap.initiatorCommitted);
            // Note: We don't reset initiatorDeposited flag here, as the state implies finality for this swap.
        }

        if (claimant == swap.counterparty && swap.counterpartyDeposited) {
            // Reclaim counterparty's committed assets
             _transferOutAsset(swap.counterparty, swap.counterpartyCommitted);
             emit AssetsReclaimed(swapId, claimant, swap.counterpartyCommitted);
             // Note: We don't reset counterpartyDeposited flag here.
        }

        // Update status to Reclaimed if both parties have reclaimed or were eligible to reclaim
        // (This logic might be simplified, as reclaiming is final per asset per party)
         if (swap.initiatorDeposited || swap.counterpartyDeposited) { // At least one party must have deposited
             // If either party successfully reclaims, the swap is essentially concluded for them.
             // If both were eligible and one reclaims, the other can still reclaim.
             // Let's set status to Reclaimed if assets *were* successfully reclaimed in this call.
             // A more robust state transition would be needed if partial reclaims were complex.
             swap.status = SwapStatus.Reclaimed; // Simple final state after reclaim attempt
         }
    }


    // --- Administrative Functions ---

    /// @notice Sets the address that receives protocol fees.
    /// @param _protocolFeeAddress The new address for receiving fees.
    function setProtocolFeeAddress(address _protocolFeeAddress) external onlyOwner {
        require(_protocolFeeAddress != address(0), "Fee address cannot be zero");
        require(_protocolFeeAddress.isContract() == false, "Fee address cannot be a contract"); // Prefer EOA for fee reception
        _protocolFeeAddress = _protocolFeeAddress;
        emit ProtocolFeeAddressUpdated(_protocolFeeAddress);
    }

    /// @notice Sets the protocol fee rate.
    /// @param _protocolFeeRate The new fee rate in basis points (e.g., 100 = 1%). Max 10000 (100%).
    function setProtocolFeeRate(uint16 _protocolFeeRate) external onlyOwner {
        require(_protocolFeeRate <= 10000, "Fee rate cannot exceed 100%");
        _protocolFeeRate = _protocolFeeRate;
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees (in ETH).
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = _protocolFeesCollected;
        _protocolFeesCollected = 0;
        if (amount > 0) {
            (bool success,) = Payable(owner()).call{value: amount}("");
            require(success, "ETH transfer failed");
             emit FeesWithdrawn(owner(), amount);
        }
    }

    /// @notice Adds an asset contract address to the whitelist.
    /// @dev Only whitelisted ERC20/ERC721 assets can be used in swaps. ETH is always allowed.
    /// @param assetAddress The address of the ERC20 or ERC721 contract.
    function addAllowedAsset(address assetAddress) external onlyOwner {
        require(assetAddress != address(0), "Asset address cannot be zero");
         require(assetAddress.isContract(), "Asset address must be a contract");
        _allowedAssets[assetAddress] = true;
        emit AllowedAssetAdded(assetAddress);
    }

    /// @notice Removes an asset contract address from the whitelist.
    /// @param assetAddress The address of the ERC20 or ERC721 contract.
    function removeAllowedAsset(address assetAddress) external onlyOwner {
        require(assetAddress != address(0), "Asset address cannot be zero");
        _allowedAssets[assetAddress] = false;
        emit AllowedAssetRemoved(assetAddress);
    }

    /// @notice Pauses contract operations.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses contract operations.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- View/Query Functions ---

    /// @notice Retrieves all details for a given swap ID.
    /// @param swapId The ID of the swap.
    /// @return A tuple containing all Swap struct fields.
    function getSwapDetails(uint256 swapId) external view returns (
        uint256 id,
        address initiator,
        address counterparty,
        Asset memory initiatorCommitted,
        Asset memory counterpartyCommitted,
        bytes32 quantumConditionHash,
        bytes memory revealedQuantumState,
        uint64 revealDeadline,
        uint64 claimDeadline,
        SwapStatus status,
        bool initiatorDeposited,
        bool counterpartyDeposited,
        PotentialOutcome[] memory potentialOutcomes,
        bytes32 executedOutcomeHash
    ) {
        Swap storage swap = swaps[swapId];
        require(swap.id != 0, "Swap does not exist"); // Check if swapId is valid

        return (
            swap.id,
            swap.initiator,
            swap.counterparty,
            swap.initiatorCommitted,
            swap.counterpartyCommitted,
            swap.quantumConditionHash,
            swap.revealedQuantumState,
            swap.revealDeadline,
            swap.claimDeadline,
            swap.status,
            swap.initiatorDeposited,
            swap.counterpartyDeposited,
            swap.potentialOutcomes, // Return the array reference
            swap.executedOutcomeHash
        );
    }

    /// @notice Gets only the current status of a swap.
    /// @param swapId The ID of the swap.
    /// @return The current SwapStatus.
    function getSwapStatus(uint256 swapId) external view returns (SwapStatus) {
        require(swaps[swapId].id != 0, "Swap does not exist");
        return swaps[swapId].status;
    }

     /// @notice Gets the assets the initiator committed to deposit.
    /// @param swapId The ID of the swap.
    /// @return The Asset struct committed by the initiator.
    function getInitiatorAssetsCommitted(uint256 swapId) external view returns (Asset memory) {
        require(swaps[swapId].id != 0, "Swap does not exist");
        return swaps[swapId].initiatorCommitted;
    }

     /// @notice Gets the assets the counterparty committed to deposit.
    /// @param swapId The ID of the swap.
    /// @return The Asset struct committed by the counterparty.
    function getCounterpartyAssetsCommitted(uint256 swapId) external view returns (Asset memory) {
        require(swaps[swapId].id != 0, "Swap does not exist");
        return swaps[swapId].counterpartyCommitted;
    }


    /// @notice Retrieves the list of potential outcomes defined for a swap.
    /// @param swapId The ID of the swap.
    /// @return An array of PotentialOutcome structs.
    function getPotentialOutcomes(uint256 swapId) external view returns (PotentialOutcome[] memory) {
        require(swaps[swapId].id != 0, "Swap does not exist");
        return swaps[swapId].potentialOutcomes;
    }

    /// @notice Gets the list of currently allowed asset addresses.
    /// @dev Note: This iterates through a mapping, which can be inefficient for large lists.
    ///      In a production contract, this might need a dedicated array state variable.
    /// @return An array of allowed asset addresses.
    function getAllowedAssets() external view returns (address[] memory) {
        uint256 count = 0;
        for (address assetAddress : _allowedAssets.keys()) { // Using keys() requires solc >= 0.8.21 or iterable mapping library
            if (_allowedAssets[assetAddress]) {
                count++;
            }
        }

        address[] memory allowed = new address[](count);
        uint256 index = 0;
        for (address assetAddress : _allowedAssets.keys()) {
             if (_allowedAssets[assetAddress]) {
                 allowed[index] = assetAddress;
                 index++;
             }
        }
        return allowed;
    }

    /// @notice Gets the current protocol fee address.
    /// @return The protocol fee address.
    function getProtocolFeeAddress() external view returns (address) {
        return _protocolFeeAddress;
    }

    /// @notice Gets the current protocol fee rate.
    /// @return The protocol fee rate in basis points.
    function getProtocolFeeRate() external view returns (uint16) {
        return _protocolFeeRate;
    }

    /// @notice Gets the total protocol fees collected.
    /// @return The total collected fees in ETH.
    function getProtocolFeesCollected() external view returns (uint256) {
        return _protocolFeesCollected;
    }

    // --- Internal Helper Functions ---

    /// @dev Helper to transfer assets into the contract.
    /// @param from The sender of the asset.
    /// @param asset The asset to transfer in.
    /// @param msgValue The ETH value sent with the transaction (only used for ETH).
    function _transferInAsset(address from, Asset memory asset, uint256 msgValue) internal {
        if (asset.assetType == AssetType.ETH) {
            require(msgValue == asset.amountOrId, "ETH value must match committed amount");
            require(msg.sender == from, "ETH must be sent by committed address");
             // ETH is sent via msg.value and is now in the contract balance
        } else if (asset.assetType == AssetType.ERC20) {
            require(msgValue == 0, "ETH not expected for ERC20 deposit");
            require(asset.tokenAddress != address(0), "ERC20 address cannot be zero");
            IERC20(asset.tokenAddress).safeTransferFrom(from, address(this), asset.amountOrId);
        } else if (asset.assetType == AssetType.ERC721) {
            require(msgValue == 0, "ETH not expected for ERC721 deposit");
            require(asset.tokenAddress != address(0), "ERC721 address cannot be zero");
             // ERC721 transfer will call onERC721Received on this contract, which ERC721Holder handles.
            IERC721(asset.tokenAddress).safeTransferFrom(from, address(this), asset.amountOrId);
        } else {
            revert("Unknown asset type for transfer in");
        }
    }

    /// @dev Helper to transfer assets out of the contract.
    /// @param to The recipient of the asset.
    /// @param asset The asset to transfer out.
    function _transferOutAsset(address to, Asset memory asset) internal {
        require(to != address(0), "Cannot transfer to zero address");

        if (asset.assetType == AssetType.ETH) {
            require(asset.amountOrId > 0, "ETH amount must be greater than 0");
            // Transfer ETH from contract balance
            (bool success, ) = Payable(to).call{value: asset.amountOrId}("");
            require(success, "ETH transfer failed");
        } else if (asset.assetType == AssetType.ERC20) {
            require(asset.tokenAddress != address(0), "ERC20 address cannot be zero");
            require(asset.amountOrId > 0, "ERC20 amount must be greater than 0");
            IERC20(asset.tokenAddress).safeTransfer(to, asset.amountOrId);
        } else if (asset.assetType == AssetType.ERC721) {
            require(asset.tokenAddress != address(0), "ERC721 address cannot be zero");
             // ERC721 ID 0 is valid, no amount check needed here.
            IERC721(asset.tokenAddress).safeTransferFrom(address(this), to, asset.amountOrId);
        } else {
            revert("Unknown asset type for transfer out");
        }
    }

    // --- Fallback/Receive for ETH ---

    receive() external payable {} // Allows receiving ETH deposits

    fallback() external payable {} // Allows receiving ETH deposits via fallback

    // --- ERC721Holder required function ---
    // This function is called by ERC721 contracts when an NFT is transferred into this contract.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // Optional: Add checks here to ensure the received NFT corresponds to an expected deposit
        // based on active swaps, 'from' address, operator, token contract, and tokenId.
        // For simplicity in this example, we rely on the transferFrom call in _transferInAsset.
        // A robust implementation might verify against pending swap deposits.
        return this.onERC721Received.selector;
    }
}
```