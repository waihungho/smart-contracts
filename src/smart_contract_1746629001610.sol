Okay, let's design a smart contract that represents a kind of "Quantum Entanglement Swap". The core idea is to have two parties lock assets contingent on an external, observable "quantum state" resolving to a specific value within a time limit, managed by a designated "resolver". The "entanglement" is the state of their assets being linked and dependent on this external factor. This goes beyond simple escrows or token swaps by introducing a specific, external, state-dependent resolution mechanism per pair.

It will involve:
1.  **Defining Entanglement Pairs:** Structures holding details of each potential swap (parties, assets, condition, duration, resolver).
2.  **State Management:** Tracking the status of each pair (proposed, entangled, condition met, expired, finalized, cancelled).
3.  **Conditional Resolution:** Allowing a designated resolver to update the external "quantum state" value on-chain. The contract checks if the condition is met based on this update.
4.  **Asset Locking/Withdrawal:** Parties lock assets upon accepting the entanglement, and can withdraw them based on the final resolved state (swap or return).
5.  **Mutual Agreement:** Features for mutual cancellation and potentially mutual updates (like changing the resolver).

Let's aim for flexibility with different asset types (ETH, ERC20, ERC721) and different condition types.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Smart Contract Outline ---
// 1. State Variables & Enums: Defines the types of assets, conditions, and the status of an entanglement pair. Stores the core data for each pair.
// 2. Events: Signals key state transitions and actions for off-chain monitoring.
// 3. Errors: Custom errors for clearer failure reasons.
// 4. Structs: Defines the structure for assets and the entanglement pair itself.
// 5. Mappings: Stores entanglement pairs indexed by a unique ID, and potentially track proposals/updates.
// 6. Constructor: Initializes the contract owner.
// 7. Utility Functions: Internal helpers for asset transfers, condition checking, status checks.
// 8. Core Entanglement Lifecycle Functions:
//    - proposeEntanglementSwap: Initiates a new swap proposal.
//    - acceptEntanglementSwap: Accepts a proposal, locks assets, starts entanglement.
//    - cancelProposal: Cancels a proposal before acceptance.
//    - updateQuantumState: Called by the resolver to update the external state value.
//    - finalizeSwap: Resolves the entanglement based on state and time, enabling withdrawals.
// 9. Mutual Agreement Functions:
//    - initiateMutualCancellation: Starts a process for mutual cancellation.
//    - confirmMutualCancellation: Completes the mutual cancellation.
//    - proposeResolverUpdate: Proposes changing the resolver for an active pair.
//    - acceptResolverUpdate: Accepts a resolver update proposal.
//    - rejectResolverUpdate: Rejects a resolver update proposal.
// 10. Withdrawal Function: Allows parties to withdraw their rightful assets after resolution/cancellation.
// 11. View Functions: Provides read access to pair details and status information.
// 12. Admin Functions: Standard owner functionalities (Ownable, ReentrancyGuard).

// --- Function Summary ---
// 1. constructor(): Initializes contract owner.
// 2. proposeEntanglementSwap(): Party A proposes a swap with Party B, conditions, and assets.
// 3. acceptEntanglementSwap(): Party B accepts the proposal, locks their assets, and locks Party A's assets (if applicable).
// 4. cancelProposal(): Party A cancels a proposal before Party B accepts.
// 5. updateQuantumState(): The designated resolver updates the external state value for a specific pair.
// 6. finalizeSwap(): Resolves the entanglement pair's outcome (swap or return) after expiry or condition met, marking assets ready for withdrawal.
// 7. withdrawAssets(): Allows a party to withdraw the assets they are entitled to after finalization or cancellation.
// 8. initiateMutualCancellation(): One party initiates the mutual cancellation process for an entangled pair.
// 9. confirmMutualCancellation(): The other party confirms mutual cancellation, marking assets ready for withdrawal.
// 10. proposeResolverUpdate(): One party proposes a new resolver address for an entangled pair.
// 11. acceptResolverUpdate(): The other party accepts the proposed resolver update.
// 12. rejectResolverUpdate(): The other party rejects the proposed resolver update.
// 13. getPairDetails(): Returns the full struct details for a specific pair ID. (View)
// 14. getAssetDetails(): Helper view function to decode asset details from the struct. (View)
// 15. getConditionDetails(): Helper view function to decode condition details from the struct. (View)
// 16. getCurrentStateValue(): Returns the latest updated quantum state value for a pair. (View)
// 17. getPairStatus(): Returns the current status enum of a pair. (View)
// 18. isEntangled(): Checks if a pair is currently in the Entangled status. (View)
// 19. isConditionMet(): Checks if the condition has been met for a pair based on the current state. (View)
// 20. isExpired(): Checks if the entanglement period has expired for a pair. (View)
// 21. isSwapPossible(): Checks if the condition was met before expiry, potentially leading to a swap. (View)
// 22. isReadyForWithdrawal(): Checks if assets for a pair are ready to be withdrawn by participants. (View)
// 23. getPartyALockedAsset(): Returns the asset details Party A committed. (View)
// 24. getPartyBLockedAsset(): Returns the asset details Party B committed. (View)
// 25. getPairResolver(): Returns the current resolver address for a pair. (View)
// 26. pause(): Pauses contract operations (Admin).
// 27. unpause(): Unpauses contract operations (Admin).
// 28. transferOwnership(): Transfers contract ownership (Admin).
// 29. supportsInterface(): (Optional but good practice for ERC compliance if needed, maybe skip for function count focus) - Let's skip this one.

contract QuantumEntanglementSwap is Ownable, ReentrancyGuard {
    using Address for address;

    // --- State Variables & Enums ---

    enum AssetType {
        ETH,
        ERC20,
        ERC721
    }

    // Define types of conditions that can trigger the swap
    enum ConditionType {
        NumericEquals, // Compare bytes32 as uint256
        BooleanTrue,   // Interpret bytes32 as bool (non-zero is true)
        StringMatch,   // Compare bytes32 as keccak256 hash of a string
        TimestampReached // Compare bytes32 as uint256 timestamp (resolver provides target timestamp, not current time)
    }

    enum PairStatus {
        Proposed,            // Party A created, waiting for Party B
        Entangled,           // Party B accepted, assets locked, waiting for condition or expiry
        ConditionMet,        // Condition was met before expiry, ready for finalization
        Expired,             // Time expired before condition was met, ready for finalization
        FinalizedSwap,       // Finalized resulting in a swap, assets ready for withdrawal
        FinalizedReturn,     // Finalized resulting in asset return, assets ready for withdrawal
        CancelledProposal,   // Party A cancelled before acceptance, ready for withdrawal
        CancelledMutual,     // Parties mutually cancelled, assets ready for withdrawal
        PartiesDisagree,     // One party initiated mutual cancellation, waiting for other
        ResolverUpdateProposed // One party proposed new resolver, waiting for other
    }

    uint256 private nextPairId;

    // --- Events ---

    event PairProposed(
        uint256 indexed pairId,
        address indexed partyA,
        address indexed partyB,
        AssetType assetAType,
        address assetAAddress,
        uint256 assetAAmountOrId,
        AssetType assetBType,
        address assetBAddress,
        uint256 assetBAmountOrId,
        ConditionType conditionType,
        bytes32 targetValue,
        uint256 expiresAt,
        address resolver
    );

    event PairAccepted(uint256 indexed pairId, address indexed partyA, address indexed partyB, uint256 acceptedAt);
    event ProposalCancelled(uint256 indexed pairId, address indexed partyA);
    event QuantumStateUpdated(uint256 indexed pairId, bytes32 newStateValue, bool conditionMet);
    event PairFinalized(uint256 indexed pairId, PairStatus finalStatus);
    event AssetsWithdrawn(uint256 indexed pairId, address indexed receiver);

    event MutualCancellationInitiated(uint256 indexed pairId, address indexed initiator);
    event MutualCancellationConfirmed(uint256 indexed pairId, address indexed confirmer);

    event ResolverUpdateProposed(uint256 indexed pairId, address indexed proposer, address newResolver);
    event ResolverUpdateAccepted(uint256 indexed pairId, address indexed accepter, address newResolver);
    event ResolverUpdateRejected(uint256 indexed pairId, address indexed rejecter);

    // --- Errors ---

    error InvalidPairId();
    error InvalidPairStatus();
    error NotPartyA();
    error NotPartyB();
    error NotPartyAOrB();
    error NotResolver();
    error AssetsAlreadyLocked();
    error AssetsNotLocked();
    error InvalidDuration();
    error AlreadyProposedResolverUpdate();
    error NotResolverUpdateProposer();
    error NotPendingMutualCancellation();
    error MutualCancellationAlreadyInitiated();
    error AssetsNotReadyForWithdrawal();
    error NothingToWithdraw();
    error TransferFailed();
    error InsufficientERC20Allowance();
    error ERC721NotOwnedOrApproved();
    error ETHTransferFailed();
    error ETHNotSentWithAccept();
    error InvalidConditionValue();
    error ReentrancyDetected(); // Via ReentrancyGuard

    // --- Structs ---

    struct Asset {
        AssetType assetType;
        address tokenAddress; // Address of the ERC20 or ERC721 contract (zero address for ETH)
        uint256 amountOrTokenId; // Amount for ETH/ERC20, tokenId for ERC721
    }

    struct Pair {
        uint256 pairId;
        address partyA;
        address partyB;
        Asset assetA;
        Asset assetB;
        ConditionType conditionType;
        bytes32 targetValue; // The value the 'quantum state' needs to match
        bytes32 currentStateValue; // The latest reported state value
        uint256 proposedAt;
        uint256 acceptedAt; // 0 if not yet accepted
        uint256 expiresAt; // Time when entanglement ends
        address resolver; // Address allowed to call updateQuantumState

        PairStatus status;
        bool isConditionMet; // Set to true once condition is met by updateQuantumState
        bool assetsLocked;   // True if assets have been transferred to the contract

        // Fields for mutual agreements
        uint256 mutualCancelInitiatedAt; // Timestamp when mutual cancellation was initiated
        address mutualCancelInitiator; // Address who initiated mutual cancellation

        address proposedNewResolver; // Address proposed for resolver update
        address resolverUpdateProposer; // Address who proposed the resolver update
    }

    // --- Mappings ---

    mapping(uint256 => Pair) public pairs;
    mapping(uint256 => mapping(address => bool)) private assetsWithdrawn; // pairId => party => withdrawn

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Core Entanglement Lifecycle Functions ---

    /**
     * @notice Party A proposes a Quantum Entanglement Swap with Party B.
     * @param _partyB The address of the second party.
     * @param _assetA The details of the asset Party A commits.
     * @param _assetB The details of the asset Party B must commit.
     * @param _conditionType The type of condition that must be met.
     * @param _targetValue The target value for the condition.
     * @param _duration The duration of the entanglement period in seconds, starting upon acceptance.
     * @param _resolver The address authorized to update the quantum state for this pair.
     * @return pairId The unique ID of the newly created proposal.
     */
    function proposeEntanglementSwap(
        address _partyB,
        Asset memory _assetA,
        Asset memory _assetB,
        ConditionType _conditionType,
        bytes32 _targetValue,
        uint256 _duration,
        address _resolver
    ) external onlyOwner {
        // ReentrancyGuard not needed here as no external calls with state changes happen after checks
        if (_partyB == address(0)) revert InvalidPartyB();
        if (_duration == 0) revert InvalidDuration();
        if (_resolver == address(0)) revert InvalidResolver();

        uint256 currentPairId = nextPairId++;
        pairs[currentPairId] = Pair({
            pairId: currentPairId,
            partyA: msg.sender,
            partyB: _partyB,
            assetA: _assetA,
            assetB: _assetB,
            conditionType: _conditionType,
            targetValue: _targetValue,
            currentStateValue: bytes32(0), // Initial state is zero
            proposedAt: block.timestamp,
            acceptedAt: 0,
            expiresAt: 0, // Set upon acceptance
            resolver: _resolver,
            status: PairStatus.Proposed,
            isConditionMet: false,
            assetsLocked: false,
            mutualCancelInitiatedAt: 0,
            mutualCancelInitiator: address(0),
            proposedNewResolver: address(0),
            resolverUpdateProposer: address(0)
        });

        // Require Party A to lock assets immediately upon proposing if ETH
        if (_assetA.assetType == AssetType.ETH) {
            if (msg.value < _assetA.amountOrTokenId) revert ETHNotSentWithProposal();
            // No need to explicitly transfer ETH here, it's already sent with the call.
            // Contract balance increases. It will be tracked as locked implicitly
            // until the pair is finalized/cancelled/expired and withdrawn.
            // The `assetsLocked` flag tracks if BOTH assets are locked (Party B's action)
        } else {
            // If Party A offers ERC20/ERC721, they must grant allowance to the contract *before* proposing
            // or separately call a function to lock *after* proposing but before acceptance.
            // Let's require allowance *before* acceptance, handled in acceptEntanglementSwap.
            if (msg.value > 0) revert ETHUnexpected(); // Cannot send ETH if not offering ETH
        }

        emit PairProposed(
            currentPairId,
            msg.sender,
            _partyB,
            _assetA.assetType,
            _assetA.tokenAddress,
            _assetA.amountOrTokenId,
            _assetB.assetType,
            _assetB.tokenAddress,
            _assetB.amountOrTokenId,
            _conditionType,
            _targetValue,
            _duration,
            _resolver
        );
    }

    /**
     * @notice Party B accepts a swap proposal.
     * @param _pairId The ID of the proposal to accept.
     */
    function acceptEntanglementSwap(uint256 _pairId) external payable nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId(); // Check if pair exists
        if (pair.status != PairStatus.Proposed) revert InvalidPairStatus();
        if (msg.sender != pair.partyB) revert NotPartyB();
        if (pair.assetsLocked) revert AssetsAlreadyLocked();

        // Handle asset transfers/locking for both parties
        _lockAssets(_pairId, msg.value);

        pair.acceptedAt = block.timestamp;
        pair.expiresAt = block.timestamp + (pair.expiresAt); // expiresAt field in struct was duration, now set expiry
        pair.status = PairStatus.Entangled;
        pair.assetsLocked = true;

        emit PairAccepted(_pairId, pair.partyA, pair.partyB, block.timestamp);
    }

    /**
     * @notice Party A cancels their proposal before it is accepted.
     * @param _pairId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _pairId) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.Proposed) revert InvalidPairStatus();
        if (msg.sender != pair.partyA) revert NotPartyA();
        if (pair.assetsLocked) revert AssetsAlreadyLocked(); // Should not be locked in Proposed state

        // If Party A committed ETH, it needs to be marked for withdrawal.
        // Since ETH was sent with propose, it's already in contract balance.
        // No need to transfer out immediately, mark ready for withdrawal.
        pair.status = PairStatus.CancelledProposal;

        emit ProposalCancelled(_pairId, msg.sender);
    }

    /**
     * @notice The designated resolver updates the quantum state value for an entangled pair.
     * @param _pairId The ID of the pair.
     * @param _newStateValue The new value of the quantum state.
     */
    function updateQuantumState(uint256 _pairId, bytes32 _newStateValue) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        // Only allow updates while entangled or waiting for mutual agreement/update
        if (pair.status != PairStatus.Entangled &&
            pair.status != PairStatus.PartiesDisagree &&
            pair.status != PairStatus.ResolverUpdateProposed)
        {
             revert InvalidPairStatus();
        }
        if (msg.sender != pair.resolver) revert NotResolver();
        if (pair.isConditionMet) revert ConditionAlreadyMet(); // Condition already satisfied

        pair.currentStateValue = _newStateValue;

        bool conditionMetNow = _checkCondition(_pairId, pair.conditionType, pair.targetValue, _newStateValue);

        if (conditionMetNow) {
            pair.isConditionMet = true;
            pair.status = PairStatus.ConditionMet; // Move to ConditionMet status
            emit QuantumStateUpdated(_pairId, _newStateValue, true);
            // Optionally finalize immediately? No, let finalizeSwap be the explicit step.
        } else {
            emit QuantumStateUpdated(_pairId, _newStateValue, false);
        }
    }

    /**
     * @notice Finalizes the entanglement pair, determining the outcome (swap or return)
     * and marking assets ready for withdrawal. Can be called by anyone after expiry or condition met.
     * @param _pairId The ID of the pair to finalize.
     */
    function finalizeSwap(uint256 _pairId) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        // Can only finalize from Entangled, ConditionMet, or Expired states
        if (pair.status != PairStatus.Entangled &&
            pair.status != PairStatus.ConditionMet &&
            pair.status != PairStatus.Expired)
        {
             revert InvalidPairStatus();
        }
        if (!pair.assetsLocked) revert AssetsNotLocked(); // Should not happen if status is Entangled/ConditionMet/Expired

        bool isExpired = block.timestamp >= pair.expiresAt;

        if (pair.status == PairStatus.Entangled) {
             // Must be expired OR condition met to leave Entangled
             if (!isExpired && !pair.isConditionMet) revert NotReadyToFinalize();
        }

        if (pair.isConditionMet) {
            // Condition met --> Swap occurs
            pair.status = PairStatus.FinalizedSwap;
        } else if (isExpired) {
            // Expired before condition met --> Return assets
             pair.status = PairStatus.FinalizedReturn;
        } else {
            // Neither expired nor condition met, and status wasn't Entangled (implies ConditionMet already), this case shouldn't be reachable if logic is correct
             revert InvalidPairStatus(); // Should already be in ConditionMet status if condition was met
        }

        emit PairFinalized(_pairId, pair.status);
    }

    /**
     * @notice Allows parties to withdraw their entitled assets after a pair is finalized or cancelled.
     * @param _pairId The ID of the pair.
     */
    function withdrawAssets(uint256 _pairId) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (!isReadyForWithdrawal(_pairId)) revert AssetsNotReadyForWithdrawal();
        if (assetsWithdrawn[_pairId][msg.sender]) revert AssetsAlreadyWithdrawn();

        address receiver = msg.sender;
        address partyA = pair.partyA;
        address partyB = pair.partyB;

        // Determine which asset the receiver is entitled to based on the final status
        Asset memory assetToTransfer;
        bool isPartyA = (receiver == partyA);
        bool isPartyB = (receiver == partyB);

        if (!isPartyA && !isPartyB) revert NotPartyAOrB();

        bool transferRequested = false;

        if (pair.status == PairStatus.FinalizedSwap) {
            // Swap occurred: Party A gets Asset B, Party B gets Asset A
            if (isPartyA) {
                assetToTransfer = pair.assetB;
                transferRequested = true;
            } else if (isPartyB) {
                assetToTransfer = pair.assetA;
                transferRequested = true;
            }
        } else if (pair.status == PairStatus.FinalizedReturn ||
                   pair.status == PairStatus.CancelledMutual ||
                   pair.status == PairStatus.CancelledProposal)
        {
            // Assets returned: Party A gets Asset A, Party B gets Asset B
            if (isPartyA) {
                assetToTransfer = pair.assetA;
                transferRequested = true;
            } else if (isPartyB) {
                 assetToTransfer = pair.assetB;
                 transferRequested = true;
            }
        } else {
             revert InvalidPairStatus(); // Should not be in withdrawal state otherwise
        }

        if (!transferRequested) revert NothingToWithdraw(); // Should not happen if logic above is correct

        // Execute the transfer
        _transferAsset(
            assetToTransfer.assetType,
            assetToTransfer.tokenAddress,
            assetToTransfer.amountOrTokenId,
            receiver
        );

        assetsWithdrawn[_pairId][receiver] = true;

        emit AssetsWithdrawn(_pairId, receiver);
    }

    // --- Mutual Agreement Functions ---

    /**
     * @notice Initiates the process for mutual cancellation of an entangled pair.
     * Either party can call this.
     * @param _pairId The ID of the pair to cancel.
     */
    function initiateMutualCancellation(uint256 _pairId) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.Entangled) revert InvalidPairStatus();
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();
        if (pair.mutualCancelInitiatedAt != 0) revert MutualCancellationAlreadyInitiated();

        pair.mutualCancelInitiatedAt = block.timestamp;
        pair.mutualCancelInitiator = msg.sender;
        pair.status = PairStatus.PartiesDisagree; // Use PartiesDisagree to indicate pending agreement

        emit MutualCancellationInitiated(_pairId, msg.sender);
    }

    /**
     * @notice Confirms the mutual cancellation process. The other party must call this after initiation.
     * @param _pairId The ID of the pair to cancel.
     */
    function confirmMutualCancellation(uint256 _pairId) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.PartiesDisagree) revert NotPendingMutualCancellation();
        if (msg.sender == pair.mutualCancelInitiator) revert CannotConfirmOwnInitiation();
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();

        pair.status = PairStatus.CancelledMutual;
        // Assets are marked ready for withdrawal via the withdrawAssets function
        // No need to reset mutualCancelInitiatedAt/Initiator, they serve as history/proof

        emit MutualCancellationConfirmed(_pairId, msg.sender);
    }

     /**
     * @notice Proposes a new resolver address for an entangled pair.
     * Either party can call this.
     * @param _pairId The ID of the pair.
     * @param _newResolver The address of the proposed new resolver.
     */
    function proposeResolverUpdate(uint256 _pairId, address _newResolver) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.Entangled) revert InvalidPairStatus();
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();
        if (pair.proposedNewResolver != address(0)) revert AlreadyProposedResolverUpdate();
        if (_newResolver == address(0)) revert InvalidResolver();
         if (_newResolver == pair.resolver) revert ResolverNotChanged();


        pair.proposedNewResolver = _newResolver;
        pair.resolverUpdateProposer = msg.sender;
        pair.status = PairStatus.ResolverUpdateProposed;

        emit ResolverUpdateProposed(_pairId, msg.sender, _newResolver);
    }

    /**
     * @notice Accepts a proposed new resolver address. The other party must call this.
     * @param _pairId The ID of the pair.
     */
    function acceptResolverUpdate(uint256 _pairId) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.ResolverUpdateProposed) revert InvalidPairStatus();
        if (msg.sender == pair.resolverUpdateProposer) revert CannotAcceptOwnProposal();
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();
        if (pair.proposedNewResolver == address(0)) revert NoResolverUpdateProposed(); // Should be covered by status check but safety

        pair.resolver = pair.proposedNewResolver; // Update the resolver
        pair.proposedNewResolver = address(0); // Clear proposal
        pair.resolverUpdateProposer = address(0); // Clear proposer
        pair.status = PairStatus.Entangled; // Return to Entangled state

        emit ResolverUpdateAccepted(_pairId, msg.sender, pair.resolver);
    }

     /**
     * @notice Rejects a proposed new resolver address. The other party must call this.
     * @param _pairId The ID of the pair.
     */
    function rejectResolverUpdate(uint256 _pairId) external nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.ResolverUpdateProposed) revert InvalidPairStatus();
        if (msg.sender == pair.resolverUpdateProposer) revert CannotRejectOwnProposal();
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();
        if (pair.proposedNewResolver == address(0)) revert NoResolverUpdateProposed(); // Should be covered by status check but safety

        pair.proposedNewResolver = address(0); // Clear proposal
        pair.resolverUpdateProposer = address(0); // Clear proposer
        pair.status = PairStatus.Entangled; // Return to Entangled state

        emit ResolverUpdateRejected(_pairId, msg.sender);
    }


    // --- View Functions ---

    /**
     * @notice Gets the full details of an entanglement pair.
     * @param _pairId The ID of the pair.
     * @return Pair struct
     */
    function getPairDetails(uint256 _pairId) external view returns (Pair memory) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair;
    }

     /**
     * @notice Helper to get details of Party A's committed asset.
     * @param _pairId The ID of the pair.
     * @return Asset struct
     */
    function getPartyALockedAsset(uint256 _pairId) external view returns (Asset memory) {
         Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
         return pair.assetA;
    }

    /**
     * @notice Helper to get details of Party B's committed asset.
     * @param _pairId The ID of the pair.
     * @return Asset struct
     */
    function getPartyBLockedAsset(uint256 _pairId) external view returns (Asset memory) {
         Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
         return pair.assetB;
    }

     /**
     * @notice Gets the resolver address for a pair.
     * @param _pairId The ID of the pair.
     * @return address The resolver address.
     */
    function getPairResolver(uint256 _pairId) external view returns (address) {
         Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
         return pair.resolver;
    }


    /**
     * @notice Gets the current status of an entanglement pair.
     * @param _pairId The ID of the pair.
     * @return PairStatus The current status.
     */
    function getPairStatus(uint256 _pairId) external view returns (PairStatus) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair.status;
    }

    /**
     * @notice Checks if a pair is currently in the Entangled status.
     * @param _pairId The ID of the pair.
     * @return bool True if entangled, false otherwise.
     */
    function isEntangled(uint256 _pairId) external view returns (bool) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair.status == PairStatus.Entangled;
    }

     /**
     * @notice Gets the latest reported quantum state value for a pair.
     * @param _pairId The ID of the pair.
     * @return bytes32 The current state value.
     */
    function getCurrentStateValue(uint256 _pairId) external view returns (bytes32) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair.currentStateValue;
    }

     /**
     * @notice Helper to decode asset details.
     * @param _asset The Asset struct.
     * @return assetType The type of asset.
     * @return tokenAddress The token address (zero for ETH).
     * @return amountOrTokenId The amount (ETH/ERC20) or token ID (ERC721).
     */
    function getAssetDetails(Asset memory _asset) external pure returns (AssetType assetType, address tokenAddress, uint256 amountOrTokenId) {
        return (_asset.assetType, _asset.tokenAddress, _asset.amountOrTokenId);
    }

    /**
     * @notice Helper to decode condition details.
     * @param _pairId The ID of the pair.
     * @return conditionType The type of condition.
     * @return targetValue The target value for the condition.
     */
    function getConditionDetails(uint256 _pairId) external view returns (ConditionType conditionType, bytes32 targetValue) {
        Pair memory pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return (pair.conditionType, pair.targetValue);
    }


    /**
     * @notice Checks if the condition has been met for a pair based on the latest state update.
     * @param _pairId The ID of the pair.
     * @return bool True if the condition is met, false otherwise.
     */
    function isConditionMet(uint256 _pairId) external view returns (bool) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair.isConditionMet;
    }

    /**
     * @notice Checks if the entanglement period has expired for a pair.
     * @param _pairId The ID of the pair.
     * @return bool True if expired, false otherwise.
     */
    function isExpired(uint256 _pairId) external view returns (bool) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
         if (pair.status == PairStatus.Proposed) return false; // Not started yet
        return block.timestamp >= pair.expiresAt;
    }

    /**
     * @notice Checks if the condition was met before the expiry, indicating a potential swap outcome.
     * @param _pairId The ID of the pair.
     * @return bool True if a swap outcome is possible (condition met before or at expiry), false otherwise.
     */
    function isSwapPossible(uint256 _pairId) external view returns (bool) {
        Pair memory pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        // Swap is possible if condition was met AND not finalized yet as return
        return pair.isConditionMet && pair.status != PairStatus.FinalizedReturn;
    }

    /**
     * @notice Checks if assets for a pair are in a state where they can be withdrawn by participants.
     * @param _pairId The ID of the pair.
     * @return bool True if ready for withdrawal, false otherwise.
     */
    function isReadyForWithdrawal(uint256 _pairId) public view returns (bool) {
        Pair memory pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) return false; // Invalid pair ID cannot be ready
        return pair.status == PairStatus.FinalizedSwap ||
               pair.status == PairStatus.FinalizedReturn ||
               pair.status == PairStatus.CancelledMutual ||
               pair.status == PairStatus.CancelledProposal;
    }

    // --- Internal Utility Functions ---

    /**
     * @dev Handles locking assets for both parties upon acceptance.
     * Called internally by acceptEntanglementSwap.
     * @param _pairId The ID of the pair.
     * @param _msgValue The amount of ETH sent with the accept call.
     */
    function _lockAssets(uint256 _pairId, uint256 _msgValue) internal {
        Pair storage pair = pairs[_pairId];

        // Lock Party A's asset (if not ETH sent with propose)
        if (pair.assetA.assetType != AssetType.ETH) {
            _transferAsset(
                pair.assetA.assetType,
                pair.assetA.tokenAddress,
                pair.assetA.amountOrTokenId,
                address(this) // Transfer to this contract
            );
        } else {
             // ETH from Party A was sent with propose. Check balance later if needed, or trust the initial check.
        }

        // Lock Party B's asset
        if (pair.assetB.assetType == AssetType.ETH) {
            if (_msgValue < pair.assetB.amountOrTokenId) revert ETHNotSentWithAccept();
             // ETH is already sent with the call. Contract balance increases.
        } else {
            if (_msgValue > 0) revert ETHUnexpected(); // Cannot send ETH if not offering ETH
            _transferAsset(
                pair.assetB.assetType,
                pair.assetB.tokenAddress,
                pair.assetB.amountOrTokenId,
                address(this) // Transfer to this contract
            );
        }
    }


    /**
     * @dev Checks if the current state value meets the target condition.
     * This function interprets the bytes32 values based on ConditionType.
     * @param _pairId The ID of the pair.
     * @param _conditionType The type of condition.
     * @param _targetValue The target value.
     * @param _currentStateValue The current state value reported by the resolver.
     * @return bool True if the condition is met, false otherwise.
     */
    function _checkCondition(
        uint256 _pairId,
        ConditionType _conditionType,
        bytes32 _targetValue,
        bytes32 _currentStateValue
    ) internal view returns (bool) {
        // Using a temporary pair reference to avoid state changes in a view helper,
        // although this internal function is called by state-changing functions.
        // This pattern helps keep the logic isolated.
        Pair memory pair = pairs[_pairId]; // Load from storage to memory for comparison

        if (_conditionType == ConditionType.NumericEquals) {
            return uint256(_currentStateValue) == uint256(_targetValue);
        } else if (_conditionType == ConditionType.BooleanTrue) {
            // Any non-zero bytes32 is considered true
            return uint256(_currentStateValue) != 0;
        } else if (_conditionType == ConditionType.StringMatch) {
            // Compare keccak256 hashes of strings
            // Resolver should provide keccak256(_string) as _newStateValue
            return _currentStateValue == _targetValue;
        } else if (_conditionType == ConditionType.TimestampReached) {
            // Compare bytes32 as timestamps
            // Resolver should provide the target timestamp as _targetValue
            // The current state value isn't directly used for this condition type,
            // except perhaps as an identifier or proof related to the event, but the
            // check is based on block.timestamp vs _targetValue.
            // Re-evaluating: Let's make TimestampReached mean the *resolver* reports a timestamp
            // that is *equal to or greater than* the target timestamp. This keeps the logic
            // driven by the resolver's update function.
             return uint256(_currentStateValue) >= uint256(_targetValue);
        } else {
            revert InvalidConditionType(); // Should not happen with enum
        }
    }

    /**
     * @dev Handles transferring assets (ETH, ERC20, ERC721).
     * @param _assetType The type of asset.
     * @param _tokenAddress The token address (zero address for ETH).
     * @param _amountOrTokenId The amount (ETH/ERC20) or token ID (ERC721).
     * @param _to The recipient address.
     */
    function _transferAsset(
        AssetType _assetType,
        address _tokenAddress,
        uint256 _amountOrTokenId,
        address _to
    ) internal {
        if (_assetType == AssetType.ETH) {
            // Transfer ETH
            (bool success, ) = _to.call{value: _amountOrTokenId}("");
            if (!success) revert ETHTransferFailed();
        } else if (_assetType == AssetType.ERC20) {
            // Transfer ERC20
            IERC20 token = IERC20(_tokenAddress);
             // For transfers *from* the contract balance (withdrawal), use token.transfer()
             // For transfers *to* the contract balance (locking), use token.transferFrom()
             // This internal helper is used by _lockAssets (transferFrom) and withdrawAssets (transfer)
             // We need to know if it's locking or withdrawing context, or handle both.
             // Let's make it handle transfer *from* the contract balance (withdrawal scenario)
             // and assume lockAssets handles transferFrom separately.
             // Re-structuring: Let's make _lockAssets handle the transferFrom part,
             // and this function handle the transfer *out* of the contract.

             // This function is called *only* by withdrawAssets, so it's always transferring *out* of the contract.
             bool success = token.transfer(_to, _amountOrTokenId);
             if (!success) revert TransferFailed(); // Generic ERC20 transfer failure

        } else if (_assetType == AssetType.ERC721) {
            // Transfer ERC721
            IERC721 token = IERC721(_tokenAddress);
             // Ensure the contract owns the token
             if (token.ownerOf(_amountOrTokenId) != address(this)) revert ERC721NotOwnedByContract();
            token.safeTransferFrom(address(this), _to, _amountOrTokenId);
        } else {
            revert InvalidAssetType(); // Should not happen with enum
        }
    }

     /**
     * @dev Internal helper to lock assets for a pair upon acceptance.
     * @param _pairId The ID of the pair.
     * @param _msgValue The amount of ETH sent with the accept call.
     */
    function _lockAssets(uint256 _pairId, uint256 _msgValue) internal {
        Pair storage pair = pairs[_pairId];

        // Lock Party A's asset
        if (pair.assetA.assetType == AssetType.ERC20) {
            IERC20 token = IERC20(pair.assetA.tokenAddress);
            // Party A must have approved this contract *before* Party B accepts
            if (token.allowance(pair.partyA, address(this)) < pair.assetA.amountOrTokenId) revert InsufficientERC20Allowance();
            bool success = token.transferFrom(pair.partyA, address(this), pair.assetA.amountOrTokenId);
            if (!success) revert TransferFailed();
        } else if (pair.assetA.assetType == AssetType.ERC721) {
            IERC721 token = IERC721(pair.assetA.tokenAddress);
            // Party A must have approved this contract or universally approved *before* Party B accepts
            if (token.ownerOf(pair.assetA.amountOrTokenId) != pair.partyA ||
                !token.isApprovedForAll(pair.partyA, address(this)) && token.getApproved(pair.assetA.amountOrTokenId) != address(this))
            {
                revert ERC721NotOwnedOrApproved();
            }
            token.safeTransferFrom(pair.partyA, address(this), pair.assetA.amountOrTokenId);
        } else if (pair.assetA.assetType == AssetType.ETH) {
             // ETH sent with propose is already here. No transfer needed in accept.
             // Could add a check here that the contract balance is sufficient based on Party A's commitment,
             // but the ETH is received at the time of propose.
        }


        // Lock Party B's asset
        if (pair.assetB.assetType == AssetType.ERC20) {
             IERC20 token = IERC20(pair.assetB.tokenAddress);
            // Party B must have approved this contract *before* calling accept
             if (token.allowance(pair.partyB, address(this)) < pair.assetB.amountOrTokenId) revert InsufficientERC20Allowance();
            bool success = token.transferFrom(pair.partyB, address(this), pair.assetB.amountOrTokenId);
            if (!success) revert TransferFailed();

        } else if (pair.assetB.assetType == AssetType.ERC721) {
             IERC721 token = IERC721(pair.assetB.tokenAddress);
             // Party B must have approved this contract or universally approved *before* calling accept
             if (token.ownerOf(pair.assetB.amountOrTokenId) != pair.partyB ||
                !token.isApprovedForAll(pair.partyB, address(this)) && token.getApproved(pair.assetB.amountOrTokenId) != address(this))
            {
                revert ERC721NotOwnedOrApproved();
            }
            token.safeTransferFrom(pair.partyB, address(this), pair.assetB.amountOrTokenId);

        } else if (pair.assetB.assetType == AssetType.ETH) {
            if (_msgValue < pair.assetB.amountOrTokenId) revert ETHNotSentWithAccept();
            // ETH is sent with the accept call itself. No explicit transfer needed here.
        } else {
             revert InvalidAssetType(); // Should not happen with enum
        }
    }


    // --- Admin Functions (from Ownable) ---
    // Included in function count as they are callable contract functions

    // Inherits Ownable functions:
    // - owner()
    // - renounceOwnership()
    // - transferOwnership(address newOwner)

    // --- ReentrancyGuard (modifier) ---
    // Used on state-changing functions involving external calls (like transfers)

    // --- Additional Error Definitions ---
     error InvalidPartyB();
     error InvalidResolver();
     error ETHNotSentWithProposal();
     error ETHUnexpected();
     error ConditionAlreadyMet();
     error NotReadyToFinalize();
     error AssetsAlreadyWithdrawn();
     error CannotConfirmOwnInitiation();
     error CannotAcceptOwnProposal();
     error NoResolverUpdateProposed();
     error CannotRejectOwnProposal();
     error InvalidConditionType();
     error InvalidAssetType();
     error ERC721NotOwnedByContract();
     error ResolverNotChanged();


     // Need to make sure these are added to the count.
     // Count:
     // 1 constructor
     // 2 proposeEntanglementSwap
     // 3 acceptEntanglementSwap
     // 4 cancelProposal
     // 5 updateQuantumState
     // 6 finalizeSwap
     // 7 withdrawAssets
     // 8 initiateMutualCancellation
     // 9 confirmMutualCancellation
     // 10 proposeResolverUpdate
     // 11 acceptResolverUpdate
     // 12 rejectResolverUpdate
     // 13 getPairDetails (view)
     // 14 getPartyALockedAsset (view)
     // 15 getPartyBLockedAsset (view)
     // 16 getPairResolver (view)
     // 17 getPairStatus (view)
     // 18 isEntangled (view)
     // 19 getCurrentStateValue (view)
     // 20 getAssetDetails (pure view)
     // 21 getConditionDetails (view)
     // 22 isConditionMet (view)
     // 23 isExpired (view)
     // 24 isSwapPossible (view)
     // 25 isReadyForWithdrawal (public view, used internally and externally)
     // 26 pause (inherited from Ownable)
     // 27 unpause (inherited from Ownable) - Let's use a Pausable contract base instead of manual, adds 2
     // 28 transferOwnership (inherited from Ownable)
     // 29 owner (inherited from Ownable)
     // 30 renounceOwnership (inherited from Ownable)

     // Okay, already > 20 functions just with core logic and inherited Ownable.
     // Let's add Pausable for pause/unpause for better practice.

    // Let's add Pausable
     import "@openzeppelin/contracts/security/Pausable.sol";
     contract QuantumEntanglementSwap is Ownable, ReentrancyGuard, Pausable { ... } // Update inheritance
     // Then need to add `whenNotPaused` modifier to relevant functions:
     // proposeEntanglementSwap, acceptEntanglementSwap, cancelProposal, updateQuantumState,
     // finalizeSwap, withdrawAssets, initiateMutualCancellation, confirmMutualCancellation,
     // proposeResolverUpdate, acceptResolverUpdate, rejectResolverUpdate.

     // Add pause() and unpause() methods to call the inherited ones:
     // function pause() external onlyOwner { _pause(); }
     // function unpause() external onlyOwner { _unpause(); }
     // These count as callable functions.

     // Let's re-count with Pausable and correct inheritance:
     // 1 constructor
     // 2 proposeEntanglementSwap (whenNotPaused)
     // 3 acceptEntanglementSwap (whenNotPaused, nonReentrant)
     // 4 cancelProposal (whenNotPaused, nonReentrant)
     // 5 updateQuantumState (whenNotPaused, nonReentrant)
     // 6 finalizeSwap (whenNotPaused, nonReentrant)
     // 7 withdrawAssets (whenNotPaused, nonReentrant)
     // 8 initiateMutualCancellation (whenNotPaused, nonReentrant)
     // 9 confirmMutualCancellation (whenNotPaused, nonReentrant)
     // 10 proposeResolverUpdate (whenNotPaused, nonReentrant)
     // 11 acceptResolverUpdate (whenNotPaused, nonReentrant)
     // 12 rejectResolverUpdate (whenNotPaused, nonReentrant)
     // 13 getPairDetails (view)
     // 14 getPartyALockedAsset (view)
     // 15 getPartyBLockedAsset (view)
     // 16 getPairResolver (view)
     // 17 getPairStatus (view)
     // 18 isEntangled (view)
     // 19 getCurrentStateValue (view)
     // 20 getAssetDetails (pure view)
     // 21 getConditionDetails (view)
     // 22 isConditionMet (view)
     // 23 isExpired (view)
     // 24 isSwapPossible (view)
     // 25 isReadyForWithdrawal (public view)
     // 26 pause() - calls _pause()
     // 27 unpause() - calls _unpause()
     // 28 owner() (inherited view)
     // 29 renounceOwnership() (inherited)
     // 30 transferOwnership() (inherited)

     // Looks good. 30 functions listed, including inherited/wrapped ones.
     // Ensure all required modifiers are added.

     // Need to fix the `expiresAt` logic in `proposeEntanglementSwap` and `acceptEntanglementSwap`.
     // `proposeEntanglementSwap` takes `_duration`.
     // `acceptEntanglementSwap` should set `pair.expiresAt = block.timestamp + pair.duration;`
     // The struct should store `duration`, not `expiresAt` initially.

     // Corrected Struct and Propose/Accept:
     // struct Pair { ... uint256 duration; ... uint256 expiresAt; ... }
     // proposeEntanglementSwap: pair.duration = _duration; pair.expiresAt = 0;
     // acceptEntanglementSwap: pair.acceptedAt = block.timestamp; pair.expiresAt = block.timestamp + pair.duration; pair.duration = 0; // Clear duration after setting expiry

     // Update Error names for consistency:
     // InvalidPartyB
     // InvalidResolver
     // ETHNotSentWithAccept
     // ETHUnexpected (e.g., sending ETH on propose but not offering ETH)
     // ConditionAlreadyMet
     // NotReadyToFinalize
     // AssetsAlreadyWithdrawn
     // CannotConfirmOwnInitiation
     // CannotAcceptOwnProposal
     // NoResolverUpdateProposed
     // CannotRejectOwnProposal
     // InvalidConditionType
     // InvalidAssetType
     // ERC721NotOwnedByContract
     // ResolverNotChanged

     // Need to add the ETHNotSentWithProposal error back into propose function and logic.

     // Final check of includes: Ownable, ReentrancyGuard, Pausable, IERC20, IERC721, Address

}
```

---
**(Self-Correction during coding):**
1.  Initially, I planned to put `expiresAt` in the `Pair` struct directly in `proposeEntanglementSwap`. It's better to store the `duration` there and calculate `expiresAt` *only* when Party B accepts, using `block.timestamp + duration`. This ensures the timer starts from the moment of mutual agreement/entanglement, not proposal. Updated struct and `propose`/`accept` logic.
2.  Realized `_transferAsset` was trying to handle both `transferFrom` (locking *to* contract) and `transfer` (withdrawing *from* contract). Separated the logic into `_lockAssets` (using `transferFrom` or `safeTransferFrom` or handling ETH `msg.value`) and kept `_transferAsset` purely for transferring *out* of the contract (using `transfer` or `safeTransferFrom` from `address(this)` or ETH `call{value}`). Updated `_lockAssets` internal helper.
3.  Added checks for ETH being sent (`msg.value`) only when the corresponding party is offering ETH, both in `propose` and `accept`.
4.  Added `Pausable` contract inheritance and modifiers (`whenNotPaused`) and wrapper functions (`pause`, `unpause`) to meet the function count and add a standard security feature.
5.  Refined error names for clarity.
6.  Updated the function summary and outline to reflect the final structure and function names/count. Added ReentrancyGuard modifier explicitly to relevant functions.

This refined process leads to the final code structure provided below.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Smart Contract Outline ---
// 1. State Variables & Enums: Defines types for assets, conditions, pair status, and core contract data.
// 2. Events: Signals key state changes and actions.
// 3. Errors: Custom errors for specific failure conditions.
// 4. Structs: Defines structures for Asset details and the main Entanglement Pair data.
// 5. Mappings: Stores entanglement pairs by ID and tracks asset withdrawal status per party.
// 6. Constructor: Initializes the contract with an owner.
// 7. Utility Functions: Internal helpers for condition checking, asset transfers (in and out).
// 8. Core Entanglement Lifecycle Functions:
//    - proposeEntanglementSwap: Party A initiates a swap proposal.
//    - acceptEntanglementSwap: Party B accepts the proposal, locks assets, begins entanglement.
//    - cancelProposal: Party A cancels their proposal before acceptance.
//    - updateQuantumState: The designated resolver updates the external 'quantum state' value.
//    - finalizeSwap: Resolves the pair based on condition/expiry, setting final status.
// 9. Withdrawal Function: Allows parties to claim assets after resolution or cancellation.
// 10. Mutual Agreement Functions: Handles multi-party consent for cancellation or resolver changes.
//    - initiateMutualCancellation: Start mutual cancellation process.
//    - confirmMutualCancellation: Confirm mutual cancellation.
//    - proposeResolverUpdate: Propose changing the pair's resolver.
//    - acceptResolverUpdate: Accept resolver update proposal.
//    - rejectResolverUpdate: Reject resolver update proposal.
// 11. View Functions: Provides read-only access to pair data and status.
// 12. Admin Functions: Owner-controlled functions for pausing and ownership transfer.

// --- Function Summary (Total: 30) ---
// 1. constructor(): Initializes the contract owner.
// 2. proposeEntanglementSwap(): Party A proposes a swap, defining terms and committing assetA (if ETH).
// 3. acceptEntanglementSwap(): Party B accepts, commits assetB, and locks both assets in the contract.
// 4. cancelProposal(): Party A cancels the proposal before Party B accepts.
// 5. updateQuantumState(): The designated resolver provides a new value for the external state, potentially meeting the condition.
// 6. finalizeSwap(): Settles the pair's outcome based on whether the condition was met before expiry (swap) or not (return assets).
// 7. withdrawAssets(): Allows participants to retrieve their owed assets after finalization or cancellation.
// 8. initiateMutualCancellation(): One party starts the two-step mutual cancellation process.
// 9. confirmMutualCancellation(): The other party agrees to the mutual cancellation.
// 10. proposeResolverUpdate(): One party proposes a new resolver address for the pair.
// 11. acceptResolverUpdate(): The other party agrees to the resolver update.
// 12. rejectResolverUpdate(): The other party declines the resolver update.
// 13. getPairDetails(): Retrieves the full data struct for a given pair ID. (View)
// 14. getPartyALockedAsset(): Gets details of asset A committed by Party A. (View)
// 15. getPartyBLockedAsset(): Gets details of asset B committed by Party B. (View)
// 16. getPairResolver(): Gets the current resolver address for a pair. (View)
// 17. getPairStatus(): Gets the current lifecycle status of a pair. (View)
// 18. isEntangled(): Checks if a pair is currently in the Entangled state. (View)
// 19. getCurrentStateValue(): Gets the latest reported external state value for a pair. (View)
// 20. getAssetDetails(): Helper view to decode an Asset struct. (Pure View)
// 21. getConditionDetails(): Gets the condition type and target value for a pair. (View)
// 22. isConditionMet(): Checks if the condition has been met based on the current state value. (View)
// 23. isExpired(): Checks if the entanglement duration has passed. (View)
// 24. isSwapPossible(): Checks if the condition was met, leading to a potential swap outcome. (View)
// 25. isReadyForWithdrawal(): Checks if the pair's status allows assets to be withdrawn. (Public View)
// 26. pause(): Pauses the contract, preventing most state-changing operations (Owner).
// 27. unpause(): Unpauses the contract (Owner).
// 28. owner(): Gets the current contract owner (Inherited View).
// 29. renounceOwnership(): Relinquishes ownership of the contract (Owner).
// 30. transferOwnership(): Transfers ownership to a new address (Owner).

contract QuantumEntanglementSwap is Ownable, ReentrancyGuard, Pausable {
    using Address for address;

    // --- State Variables & Enums ---

    enum AssetType {
        ETH,
        ERC20,
        ERC721
    }

    enum ConditionType {
        NumericEquals,   // Compare bytes32 as uint256
        BooleanTrue,     // Interpret bytes32 as bool (non-zero is true)
        StringMatchHash, // Compare bytes32 as keccak256 hash of a string
        TimestampReached // Compare bytes32 as uint256 timestamp (resolver provides target or event timestamp)
    }

    enum PairStatus {
        Proposed,            // Party A created, waiting for Party B
        Entangled,           // Party B accepted, assets locked, waiting for condition or expiry
        ConditionMet,        // Condition was met before expiry, waiting for finalization
        Expired,             // Time expired before condition met, waiting for finalization
        FinalizedSwap,       // Finalized resulting in a swap, assets ready for withdrawal
        FinalizedReturn,     // Finalized resulting in asset return, assets ready for withdrawal
        CancelledProposal,   // Party A cancelled before acceptance, assets ready for withdrawal
        CancelledMutual,     // Parties mutually cancelled, assets ready for withdrawal
        PartiesDisagree,     // One party initiated mutual cancellation, waiting for other's confirmation
        ResolverUpdateProposed // One party proposed new resolver, waiting for other's confirmation
    }

    uint256 private nextPairId;

    // --- Events ---

    event PairProposed(
        uint256 indexed pairId,
        address indexed partyA,
        address indexed partyB,
        AssetType assetAType,
        address assetAAddress,
        uint256 assetAAmountOrId,
        AssetType assetBType,
        address assetBAddress,
        uint256 assetBAmountOrId,
        ConditionType conditionType,
        bytes32 targetValue,
        uint256 duration,
        address resolver
    );

    event PairAccepted(uint256 indexed pairId, address indexed partyA, address indexed partyB, uint256 acceptedAt, uint256 expiresAt);
    event ProposalCancelled(uint256 indexed pairId, address indexed partyA);
    event QuantumStateUpdated(uint256 indexed pairId, bytes32 newStateValue, bool conditionMet);
    event PairFinalized(uint256 indexed pairId, PairStatus finalStatus);
    event AssetsWithdrawn(uint256 indexed pairId, address indexed receiver);

    event MutualCancellationInitiated(uint256 indexed pairId, address indexed initiator);
    event MutualCancellationConfirmed(uint256 indexed pairId, address indexed confirmer);

    event ResolverUpdateProposed(uint256 indexed pairId, address indexed proposer, address newResolver);
    event ResolverUpdateAccepted(uint256 indexed pairId, address indexed accepter, address newResolver);
    event ResolverUpdateRejected(uint256 indexed pairId, address indexed rejecter);

    // --- Errors ---

    error InvalidPairId();
    error InvalidPairStatus();
    error NotPartyA();
    error NotPartyB();
    error NotPartyAOrB();
    error NotResolver();
    error AssetsAlreadyLocked();
    error AssetsNotLocked();
    error InvalidDuration();
    error InvalidPartyB(); // Party B is address(0)
    error InvalidResolver(); // Resolver is address(0)
    error ETHNotSentWithProposal(); // ETH needed for Party A's asset but not sent
    error ETHNotSentWithAccept(); // ETH needed for Party B's asset but not sent
    error ETHUnexpected(); // ETH sent when not offering ETH
    error ConditionAlreadyMet(); // Attempted to update state after condition met
    error NotReadyToFinalize(); // Attempted to finalize before expiry or condition met
    error AssetsAlreadyWithdrawn(); // Already withdrew for this pair
    error NothingToWithdraw(); // Called withdraw but there are no assets to withdraw
    error TransferFailed(); // Generic token transfer failed
    error InsufficientERC20Allowance(); // ERC20 approval needed before locking
    error ERC721NotOwnedOrApproved(); // ERC721 not owned or approved before locking
    error ERC721NotOwnedByContract(); // Contract does not own the ERC721 being withdrawn
    error InvalidConditionType(); // Should not happen with enum
    error InvalidAssetType(); // Should not happen with enum
    error AlreadyProposedResolverUpdate(); // Resolver update already pending
    error NotResolverUpdateProposer(); // Msg.sender is not the one who proposed the update
    error NotPendingMutualCancellation(); // Not in state where mutual cancellation can be confirmed
    error MutualCancellationAlreadyInitiated(); // Mutual cancellation already started
    error CannotConfirmOwnInitiation(); // Party cannot confirm their own mutual cancellation initiation
    error CannotAcceptOwnProposal(); // Party cannot accept their own resolver update proposal
    error NoResolverUpdateProposed(); // No resolver update proposal is pending
    error CannotRejectOwnProposal(); // Party cannot reject their own resolver update proposal
    error ResolverNotChanged(); // Proposed resolver is the same as current

    // --- Structs ---

    struct Asset {
        AssetType assetType;
        address tokenAddress; // Address of the ERC20 or ERC721 contract (zero address for ETH)
        uint256 amountOrTokenId; // Amount for ETH/ERC20, tokenId for ERC721
    }

    struct Pair {
        uint256 pairId;
        address partyA;
        address partyB;
        Asset assetA;
        Asset assetB;
        ConditionType conditionType;
        bytes32 targetValue; // The value the 'quantum state' needs to match
        bytes32 currentStateValue; // The latest reported state value
        uint256 proposedAt;
        uint256 acceptedAt; // 0 if not yet accepted
        uint256 duration;   // Duration in seconds from acceptance
        uint256 expiresAt;  // Timestamp when entanglement ends (acceptedAt + duration)
        address resolver; // Address allowed to call updateQuantumState

        PairStatus status;
        bool isConditionMet; // Set to true once condition is met by updateQuantumState
        bool assetsLocked;   // True if assets have been transferred to the contract

        // Fields for mutual agreements
        uint256 mutualCancelInitiatedAt; // Timestamp when mutual cancellation was initiated (0 if not)
        address mutualCancelInitiator;   // Address who initiated mutual cancellation (address(0) if not)

        address proposedNewResolver;    // Address proposed for resolver update (address(0) if not)
        address resolverUpdateProposer; // Address who proposed the resolver update (address(0) if not)
    }

    // --- Mappings ---

    mapping(uint256 => Pair) public pairs;
    mapping(uint256 => mapping(address => bool)) private assetsWithdrawn; // pairId => party => withdrawn

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Pausable Wrappers ---
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }


    // --- Core Entanglement Lifecycle Functions ---

    /**
     * @notice Party A proposes a Quantum Entanglement Swap with Party B.
     * Defines assets, condition, duration, and the resolver. Party A commits ETH here if applicable.
     * @param _partyB The address of the second party.
     * @param _assetA The details of the asset Party A commits.
     * @param _assetB The details of the asset Party B must commit.
     * @param _conditionType The type of condition that must be met.
     * @param _targetValue The target value for the condition.
     * @param _duration The duration of the entanglement period in seconds, starting upon acceptance.
     * @param _resolver The address authorized to update the quantum state for this pair.
     * @return pairId The unique ID of the newly created proposal.
     */
    function proposeEntanglementSwap(
        address _partyB,
        Asset memory _assetA,
        Asset memory _assetB,
        ConditionType _conditionType,
        bytes32 _targetValue,
        uint256 _duration,
        address _resolver
    ) external payable whenNotPaused {
        if (_partyB == address(0)) revert InvalidPartyB();
        if (_duration == 0) revert InvalidDuration();
        if (_resolver == address(0)) revert InvalidResolver();
        // Prevent proposing with self
        if (msg.sender == _partyB) revert SelfProposal();

        uint256 currentPairId = nextPairId++;
        pairs[currentPairId] = Pair({
            pairId: currentPairId,
            partyA: msg.sender,
            partyB: _partyB,
            assetA: _assetA,
            assetB: _assetB,
            conditionType: _conditionType,
            targetValue: _targetValue,
            currentStateValue: bytes32(0), // Initial state is zero
            proposedAt: block.timestamp,
            acceptedAt: 0,
            duration: _duration, // Store duration, calculate expiresAt upon acceptance
            expiresAt: 0,
            resolver: _resolver,
            status: PairStatus.Proposed,
            isConditionMet: false,
            assetsLocked: false,
            mutualCancelInitiatedAt: 0,
            mutualCancelInitiator: address(0),
            proposedNewResolver: address(0),
            resolverUpdateProposer: address(0)
        });

        // If Party A is offering ETH, it must be sent with this call
        if (_assetA.assetType == AssetType.ETH) {
            if (msg.value < _assetA.amountOrTokenId) revert ETHNotSentWithProposal();
        } else {
            if (msg.value > 0) revert ETHUnexpected(); // Cannot send ETH if not offering ETH
        }

        emit PairProposed(
            currentPairId,
            msg.sender,
            _partyB,
            _assetA.assetType,
            _assetA.tokenAddress,
            _assetA.amountOrTokenId,
            _assetB.assetType,
            _assetB.tokenAddress,
            _assetB.amountOrTokenId,
            _conditionType,
            _targetValue,
            _duration,
            _resolver
        );
    }

    /**
     * @notice Party B accepts a swap proposal. Locks both parties' assets.
     * Party B commits ETH here if applicable.
     * @param _pairId The ID of the proposal to accept.
     */
    function acceptEntanglementSwap(uint256 _pairId) external payable whenNotPaused nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.Proposed) revert InvalidPairStatus();
        if (msg.sender != pair.partyB) revert NotPartyB();
        if (pair.assetsLocked) revert AssetsAlreadyLocked(); // Should not be locked in Proposed state

        // Handle asset transfers/locking for both parties
        _lockAssets(_pairId, msg.value);

        pair.acceptedAt = block.timestamp;
        pair.expiresAt = block.timestamp + pair.duration; // Set expiry based on duration
        pair.duration = 0; // Clear duration as it's now an expiry timestamp
        pair.status = PairStatus.Entangled;
        pair.assetsLocked = true;

        emit PairAccepted(_pairId, pair.partyA, pair.partyB, block.timestamp, pair.expiresAt);
    }

    /**
     * @notice Party A cancels their proposal before it is accepted by Party B.
     * @param _pairId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _pairId) external whenNotPaused nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.Proposed) revert InvalidPairStatus();
        if (msg.sender != pair.partyA) revert NotPartyA();
        if (pair.assetsLocked) revert AssetsAlreadyLocked(); // Should not be locked in Proposed state

        // If Party A committed ETH, it's in contract balance and needs to be withdrawable.
        // Mark status as cancelled proposal to allow withdrawal.
        pair.status = PairStatus.CancelledProposal;

        emit ProposalCancelled(_pairId, msg.sender);
    }

    /**
     * @notice The designated resolver updates the quantum state value for an entangled pair.
     * This may cause the condition to be met.
     * @param _pairId The ID of the pair.
     * @param _newStateValue The new value of the quantum state.
     */
    function updateQuantumState(uint256 _pairId, bytes32 _newStateValue) external whenNotPaused nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        // Only allow updates while waiting for resolution
        if (pair.status != PairStatus.Entangled &&
            pair.status != PairStatus.PartiesDisagree &&
            pair.status != PairStatus.ResolverUpdateProposed)
        {
             revert InvalidPairStatus();
        }
        // Allow update if expired but not yet finalized
         if (block.timestamp >= pair.expiresAt && pair.status != PairStatus.Entangled) {
              revert PairExpiredCannotUpdate();
         }

        if (msg.sender != pair.resolver) revert NotResolver();
        if (pair.isConditionMet) revert ConditionAlreadyMet(); // Condition already satisfied

        pair.currentStateValue = _newStateValue;

        bool conditionMetNow = _checkCondition(pair.conditionType, pair.targetValue, _newStateValue);

        if (conditionMetNow) {
            pair.isConditionMet = true;
            // If condition is met before expiry, move to ConditionMet status
            if (block.timestamp < pair.expiresAt) {
                pair.status = PairStatus.ConditionMet;
            } else {
                 // If condition is met *at or after* expiry, it still resolves to swap
                 // but no need to set ConditionMet status as expiry already determined outcome path (which is swap if conditionMet is true)
                 // Let finalization handle the actual status change based on isConditionMet at that time.
                 // Keep status as Entangled if expired but condition met. Finalize handles the transition to FinalizedSwap.
            }
            emit QuantumStateUpdated(_pairId, _newStateValue, true);
        } else {
            emit QuantumStateUpdated(_pairId, _newStateValue, false);
        }
    }

    /**
     * @notice Finalizes the entanglement pair based on the final state (condition met vs expiry).
     * Determines the outcome (swap or return) and marks assets ready for withdrawal.
     * Can be called by anyone once the pair is ready for finalization.
     * @param _pairId The ID of the pair to finalize.
     */
    function finalizeSwap(uint256 _pairId) external whenNotPaused nonReentrant {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        // Can only finalize from states waiting for resolution
        if (pair.status != PairStatus.Entangled &&
            pair.status != PairStatus.ConditionMet &&
            pair.status != PairStatus.Expired) // Expired status is implicitly set by isExpired check in view, need to update state here
        {
             revert InvalidPairStatus();
        }
        if (!pair.assetsLocked) revert AssetsNotLocked(); // Should be locked in these states

        bool isExpiredNow = block.timestamp >= pair.expiresAt;

        // Check if ready to finalize
        if (pair.status == PairStatus.Entangled) {
             if (!isExpiredNow && !pair.isConditionMet) revert NotReadyToFinalize();
        } else if (pair.status == PairStatus.ConditionMet) {
             // Ready if status is ConditionMet (means condition met BEFORE expiry)
        } else if (pair.status == PairStatus.Expired) {
             // This state should technically not be reached if we handle it in finalize.
             // Let's remove Expired status as a distinct state and handle it within finalize logic.
             // If status is Entangled and isExpiredNow, it's handled below.
             revert InvalidPairStatus(); // Remove this branch if removing Expired status
        }

        // Determine final status based on whether condition was met
        if (pair.isConditionMet) { // If condition was met *at any point before or at expiry*
            pair.status = PairStatus.FinalizedSwap;
        } else if (isExpiredNow) { // If expired AND condition was NOT met
             pair.status = PairStatus.FinalizedReturn;
        } else {
            // Should not be reachable if NotReadyToFinalize check passes
             revert NotReadyToFinalize(); // Double check
        }

        emit PairFinalized(_pairId, pair.status);
    }

    /**
     * @notice Allows parties to withdraw their entitled assets after a pair is finalized or cancelled.
     * @param _pairId The ID of the pair.
     */
    function withdrawAssets(uint256 _pairId) external nonReentrant whenNotPaused {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (!isReadyForWithdrawal(_pairId)) revert AssetsNotReadyForWithdrawal();
        if (assetsWithdrawn[_pairId][msg.sender]) revert AssetsAlreadyWithdrawn();

        address receiver = msg.sender;
        address partyA = pair.partyA;
        address partyB = pair.partyB;

        // Determine which asset the receiver is entitled to based on the final status
        Asset memory assetToTransfer;
        bool isPartyA = (receiver == partyA);
        bool isPartyB = (receiver == partyB);

        if (!isPartyA && !isPartyB) revert NotPartyAOrB();

        bool transferRequested = false;

        if (pair.status == PairStatus.FinalizedSwap) {
            // Swap occurred: Party A gets Asset B, Party B gets Asset A
            if (isPartyA) {
                assetToTransfer = pair.assetB;
                transferRequested = true;
            } else if (isPartyB) {
                assetToTransfer = pair.assetA;
                transferRequested = true;
            }
        } else if (pair.status == PairStatus.FinalizedReturn ||
                   pair.status == PairStatus.CancelledMutual ||
                   pair.status == PairStatus.CancelledProposal)
        {
            // Assets returned: Party A gets Asset A, Party B gets Asset B
            if (isPartyA) {
                assetToTransfer = pair.assetA;
                transferRequested = true;
            } else if (isPartyB) {
                 assetToTransfer = pair.assetB;
                 transferRequested = true;
            }
        } else {
             revert InvalidPairStatus(); // Should not be in withdrawal state otherwise
        }

        if (!transferRequested) revert NothingToWithdraw(); // Should not happen if logic above is correct

        // Execute the transfer from the contract's balance
        _transferAssetFromContract(
            assetToTransfer.assetType,
            assetToTransfer.tokenAddress,
            assetToTransfer.amountOrTokenId,
            receiver
        );

        assetsWithdrawn[_pairId][receiver] = true;

        emit AssetsWithdrawn(_pairId, receiver);
    }

    // --- Mutual Agreement Functions ---

    /**
     * @notice Initiates the process for mutual cancellation of an entangled pair.
     * Either party can call this.
     * @param _pairId The ID of the pair to cancel.
     */
    function initiateMutualCancellation(uint256 _pairId) external nonReentrant whenNotPaused {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.Entangled) revert InvalidPairStatus(); // Only from Entangled state
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();
        if (pair.mutualCancelInitiatedAt != 0) revert MutualCancellationAlreadyInitiated();

        pair.mutualCancelInitiatedAt = block.timestamp;
        pair.mutualCancelInitiator = msg.sender;
        pair.status = PairStatus.PartiesDisagree; // Use PartiesDisagree to indicate pending agreement

        emit MutualCancellationInitiated(_pairId, msg.sender);
    }

    /**
     * @notice Confirms the mutual cancellation process. The other party must call this after initiation.
     * @param _pairId The ID of the pair to cancel.
     */
    function confirmMutualCancellation(uint256 _pairId) external nonReentrant whenNotPaused {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.PartiesDisagree) revert NotPendingMutualCancellation();
        if (msg.sender == pair.mutualCancelInitiator) revert CannotConfirmOwnInitiation();
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();

        pair.status = PairStatus.CancelledMutual;
        // Assets are marked ready for withdrawal via the withdrawAssets function
        // No need to reset mutualCancelInitiatedAt/Initiator, they serve as history/proof

        emit MutualCancellationConfirmed(_pairId, msg.sender);
    }

     /**
     * @notice Proposes a new resolver address for an entangled pair.
     * Either party can call this from the Entangled state.
     * @param _pairId The ID of the pair.
     * @param _newResolver The address of the proposed new resolver.
     */
    function proposeResolverUpdate(uint256 _pairId, address _newResolver) external nonReentrant whenNotPaused {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.Entangled) revert InvalidPairStatus(); // Only from Entangled state
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();
        if (pair.proposedNewResolver != address(0)) revert AlreadyProposedResolverUpdate();
        if (_newResolver == address(0)) revert InvalidResolver();
         if (_newResolver == pair.resolver) revert ResolverNotChanged();

        pair.proposedNewResolver = _newResolver;
        pair.resolverUpdateProposer = msg.sender;
        pair.status = PairStatus.ResolverUpdateProposed;

        emit ResolverUpdateProposed(_pairId, msg.sender, _newResolver);
    }

    /**
     * @notice Accepts a proposed new resolver address. The other party must call this.
     * @param _pairId The ID of the pair.
     */
    function acceptResolverUpdate(uint256 _pairId) external nonReentrant whenNotPaused {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.ResolverUpdateProposed) revert InvalidPairStatus();
        if (msg.sender == pair.resolverUpdateProposer) revert CannotAcceptOwnProposal();
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();
        if (pair.proposedNewResolver == address(0)) revert NoResolverUpdateProposed(); // Should be covered by status check

        pair.resolver = pair.proposedNewResolver; // Update the resolver
        pair.proposedNewResolver = address(0); // Clear proposal
        pair.resolverUpdateProposer = address(0); // Clear proposer
        pair.status = PairStatus.Entangled; // Return to Entangled state

        emit ResolverUpdateAccepted(_pairId, msg.sender, pair.resolver);
    }

     /**
     * @notice Rejects a proposed new resolver address. The other party must call this.
     * @param _pairId The ID of the pair.
     */
    function rejectResolverUpdate(uint256 _pairId) external nonReentrant whenNotPaused {
        Pair storage pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        if (pair.status != PairStatus.ResolverUpdateProposed) revert InvalidPairStatus();
        if (msg.sender == pair.resolverUpdateProposer) revert CannotRejectOwnProposal();
        if (msg.sender != pair.partyA && msg.sender != pair.partyB) revert NotPartyAOrB();
        if (pair.proposedNewResolver == address(0)) revert NoResolverUpdateProposed(); // Should be covered by status check

        pair.proposedNewResolver = address(0); // Clear proposal
        pair.resolverUpdateProposer = address(0); // Clear proposer
        pair.status = PairStatus.Entangled; // Return to Entangled state

        emit ResolverUpdateRejected(_pairId, msg.sender);
    }


    // --- View Functions ---

    /**
     * @notice Gets the full details of an entanglement pair.
     * @param _pairId The ID of the pair.
     * @return Pair struct
     */
    function getPairDetails(uint256 _pairId) external view returns (Pair memory) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair;
    }

     /**
     * @notice Helper to get details of Party A's committed asset.
     * @param _pairId The ID of the pair.
     * @return Asset struct
     */
    function getPartyALockedAsset(uint256 _pairId) external view returns (Asset memory) {
         Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
         return pair.assetA;
    }

    /**
     * @notice Helper to get details of Party B's committed asset.
     * @param _pairId The ID of the pair.
     * @return Asset struct
     */
    function getPartyBLockedAsset(uint256 _pairId) external view returns (Asset memory) {
         Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
         return pair.assetB;
    }

     /**
     * @notice Gets the resolver address for a pair.
     * @param _pairId The ID of the pair.
     * @return address The resolver address.
     */
    function getPairResolver(uint256 _pairId) external view returns (address) {
         Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
         return pair.resolver;
    }


    /**
     * @notice Gets the current status of an entanglement pair.
     * @param _pairId The ID of the pair.
     * @return PairStatus The current status.
     */
    function getPairStatus(uint256 _pairId) external view returns (PairStatus) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair.status;
    }

    /**
     * @notice Checks if a pair is currently in the Entangled status.
     * @param _pairId The ID of the pair.
     * @return bool True if entangled, false otherwise.
     */
    function isEntangled(uint256 _pairId) external view returns (bool) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair.status == PairStatus.Entangled;
    }

     /**
     * @notice Gets the latest reported quantum state value for a pair.
     * @param _pairId The ID of the pair.
     * @return bytes32 The current state value.
     */
    function getCurrentStateValue(uint256 _pairId) external view returns (bytes32) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair.currentStateValue;
    }

     /**
     * @notice Helper to decode asset details from an Asset struct.
     * Useful for off-chain interpretation of the struct data.
     * @param _asset The Asset struct.
     * @return assetType The type of asset.
     * @return tokenAddress The token address (zero for ETH).
     * @return amountOrTokenId The amount (ETH/ERC20) or token ID (ERC721).
     */
    function getAssetDetails(Asset memory _asset) external pure returns (AssetType assetType, address tokenAddress, uint256 amountOrTokenId) {
        return (_asset.assetType, _asset.tokenAddress, _asset.amountOrTokenId);
    }

    /**
     * @notice Gets the condition type and target value for a pair.
     * @param _pairId The ID of the pair.
     * @return conditionType The type of condition.
     * @return targetValue The target value for the condition.
     */
    function getConditionDetails(uint256 _pairId) external view returns (ConditionType conditionType, bytes32 targetValue) {
        Pair memory pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return (pair.conditionType, pair.targetValue);
    }


    /**
     * @notice Checks if the condition has been met for a pair based on the latest state update.
     * This value is set by `updateQuantumState`.
     * @param _pairId The ID of the pair.
     * @return bool True if the condition is met, false otherwise.
     */
    function isConditionMet(uint256 _pairId) external view returns (bool) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        return pair.isConditionMet;
    }

    /**
     * @notice Checks if the entanglement period has expired for a pair based on current block timestamp.
     * Only relevant after the pair has been accepted (status >= Entangled).
     * @param _pairId The ID of the pair.
     * @return bool True if expired, false otherwise.
     */
    function isExpired(uint256 _pairId) external view returns (bool) {
        Pair memory pair = pairs[_pairId];
         if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
         if (pair.status < PairStatus.Entangled) return false; // Not started yet
        return block.timestamp >= pair.expiresAt;
    }

    /**
     * @notice Checks if the condition was met before or at the expiry time, indicating a swap outcome is possible.
     * This checks the stored `isConditionMet` flag.
     * @param _pairId The ID of the pair.
     * @return bool True if a swap outcome is possible, false otherwise.
     */
    function isSwapPossible(uint256 _pairId) external view returns (bool) {
        Pair memory pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) revert InvalidPairId();
        // Swap is possible if condition was met AND the pair is not yet finalized as a return
        // (a pair can only be FinalizedReturn if isConditionMet was false)
        return pair.isConditionMet && pair.status != PairStatus.FinalizedReturn;
    }

    /**
     * @notice Checks if assets for a pair are in a state where they can be withdrawn by participants.
     * This includes Finalized (Swap/Return) and Cancelled (Proposal/Mutual) states.
     * @param _pairId The ID of the pair.
     * @return bool True if ready for withdrawal, false otherwise.
     */
    function isReadyForWithdrawal(uint256 _pairId) public view returns (bool) {
        Pair memory pair = pairs[_pairId];
        if (pair.pairId == 0 && _pairId != 0) return false; // Invalid pair ID cannot be ready
        return pair.status == PairStatus.FinalizedSwap ||
               pair.status == PairStatus.FinalizedReturn ||
               pair.status == PairStatus.CancelledMutual ||
               pair.status == PairStatus.CancelledProposal;
    }


    // --- Internal Utility Functions ---

    /**
     * @dev Handles locking assets for both parties upon acceptance by transferring them to the contract.
     * Called internally by acceptEntanglementSwap.
     * Assumes ERC20/ERC721 approvals were granted beforehand.
     * @param _pairId The ID of the pair.
     * @param _msgValue The amount of ETH sent with the accept call (Party B's ETH contribution).
     */
    function _lockAssets(uint256 _pairId, uint256 _msgValue) internal {
        Pair storage pair = pairs[_pairId];

        // Lock Party A's asset (if not ETH sent with propose)
        if (pair.assetA.assetType == AssetType.ERC20) {
            IERC20 token = IERC20(pair.assetA.tokenAddress);
            // Party A must have approved this contract *before* Party B accepts
            if (token.allowance(pair.partyA, address(this)) < pair.assetA.amountOrTokenId) revert InsufficientERC20Allowance();
            bool success = token.transferFrom(pair.partyA, address(this), pair.assetA.amountOrTokenId);
            if (!success) revert TransferFailed();
        } else if (pair.assetA.assetType == AssetType.ERC721) {
            IERC721 token = IERC721(pair.assetA.tokenAddress);
            // Party A must have approved this contract or universally approved *before* Party B accepts
            if (token.ownerOf(pair.assetA.amountOrTokenId) != pair.partyA ||
                (!token.isApprovedForAll(pair.partyA, address(this)) && token.getApproved(pair.assetA.amountOrTokenId) != address(this)))
            {
                revert ERC721NotOwnedOrApproved();
            }
            token.safeTransferFrom(pair.partyA, address(this), pair.assetA.amountOrTokenId);
        } else if (pair.assetA.assetType == AssetType.ETH) {
             // ETH sent by Party A with the propose call is already in the contract balance.
             // No transferFrom needed here. Check that the correct amount was sent initially is done in propose.
        } else {
             revert InvalidAssetType(); // Should not happen with enum
        }

        // Lock Party B's asset
        if (pair.assetB.assetType == AssetType.ERC20) {
             IERC20 token = IERC20(pair.assetB.tokenAddress);
            // Party B must have approved this contract *before* calling accept
             if (token.allowance(pair.partyB, address(this)) < pair.assetB.amountOrTokenId) revert InsufficientERC20Allowance();
            bool success = token.transferFrom(pair.partyB, address(this), pair.assetB.amountOrTokenId);
            if (!success) revert TransferFailed();

        } else if (pair.assetB.assetType == AssetType.ERC721) {
             IERC721 token = IERC721(pair.assetB.tokenAddress);
             // Party B must have approved this contract or universally approved *before* calling accept
             if (token.ownerOf(pair.assetB.amountOrTokenId) != pair.partyB ||
                (!token.isApprovedForAll(pair.partyB, address(this)) && token.getApproved(pair.assetB.amountOrTokenId) != address(this)))
            {
                revert ERC721NotOwnedOrApproved();
            }
            token.safeTransferFrom(pair.partyB, address(this), pair.assetB.amountOrTokenId);

        } else if (pair.assetB.assetType == AssetType.ETH) {
            if (_msgValue < pair.assetB.amountOrTokenId) revert ETHNotSentWithAccept();
            // ETH is sent with the accept call itself (msg.value). No explicit transfer needed here.
        } else {
             revert InvalidAssetType(); // Should not happen with enum
        }
    }


    /**
     * @dev Checks if the current state value meets the target condition based on the ConditionType.
     * @param _conditionType The type of condition.
     * @param _targetValue The target value.
     * @param _currentStateValue The current state value reported by the resolver.
     * @return bool True if the condition is met, false otherwise.
     */
    function _checkCondition(
        ConditionType _conditionType,
        bytes32 _targetValue,
        bytes32 _currentStateValue
    ) internal pure returns (bool) {
        if (_conditionType == ConditionType.NumericEquals) {
            return uint256(_currentStateValue) == uint256(_targetValue);
        } else if (_conditionType == ConditionType.BooleanTrue) {
            // Any non-zero bytes32 is considered true
            return uint256(_currentStateValue) != 0;
        } else if (_conditionType == ConditionType.StringMatchHash) {
            // Compare keccak256 hashes of strings
            // Resolver should provide keccak256(string) as _newStateValue
            return _currentStateValue == _targetValue;
        } else if (_conditionType == ConditionType.TimestampReached) {
            // Compare bytes32 as timestamps. The resolver provides the timestamp.
            // The condition is met if the reported timestamp is >= the target timestamp.
             return uint256(_currentStateValue) >= uint256(_targetValue);
        } else {
            revert InvalidConditionType(); // Should not happen with enum
        }
    }

    /**
     * @dev Handles transferring assets (ETH, ERC20, ERC721) *from* the contract's balance *to* a recipient.
     * Called internally by withdrawAssets.
     * @param _assetType The type of asset.
     * @param _tokenAddress The token address (zero address for ETH).
     * @param _amountOrTokenId The amount (ETH/ERC20) or token ID (ERC721).
     * @param _to The recipient address.
     */
    function _transferAssetFromContract(
        AssetType _assetType,
        address _tokenAddress,
        uint256 _amountOrTokenId,
        address _to
    ) internal {
        if (_assetType == AssetType.ETH) {
            // Transfer ETH
            (bool success, ) = _to.call{value: _amountOrTokenId}("");
            if (!success) revert ETHTransferFailed();
        } else if (_assetType == AssetType.ERC20) {
            // Transfer ERC20 from contract balance
            IERC20 token = IERC20(_tokenAddress);
             bool success = token.transfer(_to, _amountOrTokenId);
             if (!success) revert TransferFailed(); // Generic ERC20 transfer failure

        } else if (_assetType == AssetType.ERC721) {
            // Transfer ERC721 from contract balance
            IERC721 token = IERC721(_tokenAddress);
             // Ensure the contract owns the token before transferring
             if (token.ownerOf(_amountOrTokenId) != address(this)) revert ERC721NotOwnedByContract();
            token.safeTransferFrom(address(this), _to, _amountOrTokenId);
        } else {
            revert InvalidAssetType(); // Should not happen with enum
        }
    }

    // Fallback function to receive ETH not associated with a specific pair proposal/acceptance
    // Could be used for accidental sends or future features.
    // Marking payable and leaving empty is standard practice if not intended for direct use.
    receive() external payable {}
    fallback() external payable {}

    // --- Additional Error Definitions (moved from above for clarity) ---
     error PairExpiredCannotUpdate(); // Attempted to update state after expiry
     error SelfProposal(); // Party A == Party B proposal

     // Total Functions Count: 30
}
```