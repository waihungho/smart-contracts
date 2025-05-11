Okay, here is a smart contract concept called `ChronoEscrow` that attempts to be interesting, advanced, and creative by combining multi-party involvement, time-based and event-based conditions, dynamic penalties, and internal role delegation within an escrow context. It's designed to be more complex than a standard 2-party escrow.

**Concept:** `ChronoEscrow` is a versatile, multi-party escrow contract that facilitates secure exchanges of value (ETH or ERC-20 tokens) based on a predefined sequence of milestones. Milestones can be time-based (vesting-like) or event-based (requiring confirmation from specific parties). The contract includes features for dynamic penalties, role assignment, internal delegation of rights, and a basic dispute resolution mechanism.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoEscrow
 * @notice A complex, multi-party escrow contract with time-based, event-based,
 *         and dynamic conditions for value release.
 *
 * Outline:
 * 1. State Variables & Constants
 * 2. Enums for State, Milestone Types, Roles, Dispute Outcomes
 * 3. Structs for Milestones and the main Escrow agreement
 * 4. Events to track key actions
 * 5. Modifiers for access control
 * 6. Internal helper functions
 * 7. Admin Functions
 * 8. Core Escrow Lifecycle Functions (Creation, Funding, Milestone Management, Release, Cancellation)
 * 9. Participant Management Functions (Roles, Delegation)
 * 10. Dispute Resolution Functions
 * 11. View Functions
 * 12. Fallback/Receive (for ETH funding)
 *
 * Function Summary:
 * - Admin Functions:
 *   - addApprovedToken(ERC20 token): Allows the owner to whitelist ERC20 tokens for escrow.
 *   - removeApprovedToken(ERC20 token): Allows the owner to remove whitelisted ERC20 tokens.
 *   - updateAdmin(address newAdmin): Transfers ownership/admin rights.
 *
 * - Core Escrow Lifecycle:
 *   - createEscrow(params...): Initializes a new escrow agreement. Defines participants, total amount, token, and initial milestones.
 *   - fundEscrowETH(uint256 escrowId): Sends ETH to fund an existing ETH-based escrow.
 *   - fundEscrowERC20(uint256 escrowId, uint256 amount): Transfers ERC20 tokens to fund an existing ERC20-based escrow.
 *   - addMilestone(uint256 escrowId, params...): Adds a new milestone to an existing, non-active escrow.
 *   - updateMilestone(uint256 escrowId, uint256 milestoneIndex, params...): Modifies details of a future milestone in an existing escrow.
 *   - removeMilestone(uint256 escrowId, uint256 milestoneIndex): Removes a future milestone from an existing escrow.
 *   - confirmMilestoneCompletion(uint256 escrowId, uint256 milestoneIndex): Marks an event-based milestone as completed (requires specific role).
 *   - requestMilestoneRelease(uint256 escrowId, uint256 milestoneIndex): Initiates the release of funds for a specific milestone if conditions (time OR confirmation) are met.
 *   - claimRemainingFunds(uint256 escrowId): Allows participants to claim any remaining funds after all milestones are processed or escrow is completed/cancelled.
 *   - cancelEscrow(uint256 escrowId, string reason): Allows authorized participants to initiate cancellation, potentially triggering penalties.
 *   - forceCancelExpiredEscrow(uint256 escrowId): Allows anyone to force cancel an escrow stuck past its final deadline, applying penalties.
 *
 * - Participant Management:
 *   - addParticipant(uint256 escrowId, address participant, ParticipantRole role): Adds a new participant to an escrow (e.g., adding an Arbiter).
 *   - removeParticipant(uint256 escrowId, address participant): Removes a participant from an escrow (if not critical role/creator).
 *   - setParticipantRole(uint256 escrowId, address participant, ParticipantRole role): Changes the role of an existing participant.
 *   - delegateActionRight(uint256 escrowId, address delegatee, string actionKey): Delegates a specific action right (like confirming a milestone) to another address for this escrow.
 *   - revokeActionRight(uint256 escrowId, string actionKey): Revokes a previously delegated action right.
 *
 * - Dispute Resolution:
 *   - initiateDispute(uint256 escrowId, string reason): Changes the escrow state to Disputed.
 *   - recordDisputeOutcome(uint256 escrowId, DisputeOutcome outcome, address winningParty, uint256 winningAmount, uint256 losingPenaltyAmount): Records the outcome of an off-chain dispute resolution process and distributes funds accordingly (requires specific role).
 *
 * - State Management:
 *   - pauseEscrow(uint256 escrowId, string reason): Temporarily pauses an active escrow (requires specific role).
 *   - unpauseEscrow(uint256 escrowId): Resumes a paused escrow (requires specific role).
 *
 * - View Functions:
 *   - getEscrowDetails(uint256 escrowId): Returns high-level details of an escrow.
 *   - getMilestoneDetails(uint256 escrowId, uint256 milestoneIndex): Returns details of a specific milestone.
 *   - getParticipantRole(uint256 escrowId, address participant): Returns the role of a participant in an escrow.
 *   - getActionDelegate(uint256 escrowId, address delegator, string actionKey): Returns the address delegated to perform a specific action for a delegator.
 *   - getEscrowState(uint256 escrowId): Returns the current state of an escrow.
 *   - getTotalReleased(uint256 escrowId): Returns the total amount of funds released for an escrow.
 *   - getRemainingAmount(uint256 escrowId): Returns the amount of funds still held in escrow.
 *   - isApprovedToken(address token): Checks if an ERC20 token is approved for use.
 */

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice for sends

/**
 * @title ChronoEscrow
 * @notice A complex, multi-party escrow contract with time-based, event-based,
 *         and dynamic conditions for value release.
 *
 * Outline (See summary block above the contract code)
 */
contract ChronoEscrow is Ownable, ReentrancyGuard {

    // --- 1. State Variables & Constants ---
    uint256 private nextEscrowId = 1;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => bool) private approvedTokens; // ERC20 tokens allowed for escrow

    // --- 2. Enums ---
    enum EscrowState {
        PendingFunding,   // Created, waiting for funds
        Active,           // Funded and running
        Paused,           // Temporarily halted
        Disputed,         // In dispute resolution
        Completed,        // All milestones processed, funds distributed
        Cancelled         // Cancelled prematurely
    }

    enum MilestoneType {
        TimeBased,        // Released after a specific timestamp
        EventBased        // Released after a specific event is confirmed by required parties
    }

    enum ParticipantRole {
        None,             // No role assigned for this escrow
        Creator,          // Initiator of the escrow
        Recipient,        // Primary receiver of funds
        Verifier,         // Role to confirm event-based milestones
        Arbiter,          // Role to handle disputes
        Watcher           // Can view details but not interact
    }

    enum DisputeOutcome {
        Undecided,
        CreatorWins,
        RecipientWins,
        Split
    }

    // --- 3. Structs ---
    struct Milestone {
        MilestoneType milestoneType; // Type of milestone
        uint256 amount;             // Amount to be released at this milestone
        uint256 releaseTime;        // For TimeBased: Timestamp when funds become available
        bool isCompleted;           // For EventBased: Whether the event has been confirmed
        address[] requiredConfirmers; // For EventBased: Addresses required to confirm
        mapping(address => bool) confirmations; // For EventBased: Tracks confirmations
        bool isReleased;            // Whether this milestone's funds have been released
    }

    struct Escrow {
        address payable creator;       // The initiator (often sender)
        address payable recipient;     // The primary receiver
        bool isERC20;                  // True if using ERC20, false for ETH
        address tokenAddress;          // Address of the ERC20 token (address(0) for ETH)
        uint256 totalAmount;           // Total amount locked in escrow
        uint256 releasedAmount;        // Total amount released across all milestones
        EscrowState state;             // Current state of the escrow
        uint256 creationTime;          // Timestamp when escrow was created
        uint256 lastUpdateTime;        // Timestamp of last state change or significant update
        Milestone[] milestones;        // List of milestones for this escrow
        mapping(address => ParticipantRole) participants; // Roles assigned to addresses for this escrow
        mapping(address => mapping(string => address)) delegatedActions; // delegator => actionKey => delegatee
        DisputeOutcome disputeOutcome; // Outcome if in dispute
        address payable winningParty;   // Party designated to receive funds if Split/resolved
        uint256 winningAmount;        // Amount allocated to winningParty in case of Split
        uint256 losingPenaltyAmount;  // Amount allocated as penalty from losing party's share
        uint256 finalDeadline;        // Overall deadline for the escrow process
    }

    // --- 4. Events ---
    event EscrowCreated(uint256 indexed escrowId, address indexed creator, address indexed recipient, bool isERC20, address tokenAddress, uint256 totalAmount, uint256 finalDeadline);
    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    event MilestoneAdded(uint256 indexed escrowId, uint256 indexed milestoneIndex, MilestoneType milestoneType, uint256 amount, uint256 releaseTime);
    event MilestoneUpdated(uint256 indexed escrowId, uint256 indexed milestoneIndex, MilestoneType milestoneType, uint256 amount, uint256 releaseTime);
    event MilestoneRemoved(uint256 indexed escrowId, uint256 indexed milestoneIndex);
    event MilestoneCompleted(uint256 indexed escrowId, uint256 indexed milestoneIndex, address indexed confirmer);
    event MilestoneReleased(uint256 indexed escrowId, uint256 indexed milestoneIndex, uint256 amount);
    event FundsClaimed(uint256 indexed escrowId, address indexed claimant, uint256 amount);
    event EscrowStateChanged(uint256 indexed escrowId, EscrowState oldState, EscrowState newState);
    event ParticipantAdded(uint256 indexed escrowId, address indexed participant, ParticipantRole role);
    event ParticipantRemoved(uint256 indexed escrowId, address indexed participant);
    event ParticipantRoleUpdated(uint256 indexed escrowId, address indexed participant, ParticipantRole oldRole, ParticipantRole newRole);
    event ActionDelegated(uint256 indexed escrowId, address indexed delegator, address indexed delegatee, string actionKey);
    event ActionRevoked(uint256 indexed escrowId, address indexed delegator, string actionKey);
    event DisputeInitiated(uint256 indexed escrowId, address indexed initiator, string reason);
    event DisputeOutcomeRecorded(uint256 indexed escrowId, DisputeOutcome outcome, address winningParty, uint256 winningAmount, uint256 losingPenaltyAmount);
    event EscrowCancelled(uint256 indexed escrowId, address indexed initiator, string reason);
    event EscrowPaused(uint256 indexed escrowId, address indexed initiator, string reason);
    event EscrowUnpaused(uint256 indexed escrowId, address indexed initiator);
    event TokenApproved(address indexed token);
    event TokenRemoved(address indexed token);

    // --- 5. Modifiers ---
    modifier onlyEscrowParticipant(uint256 _escrowId) {
        require(_isParticipant(_escrowId, msg.sender), "Not an escrow participant");
        _;
    }

    modifier onlyEscrowRole(uint256 _escrowId, ParticipantRole _requiredRole) {
        require(_hasRole(_escrowId, msg.sender, _requiredRole), "Insufficient escrow role");
        _;
    }

    modifier onlyEscrowRoleOrDelegate(uint256 _escrowId, ParticipantRole _requiredRole, string memory _actionKey) {
        require(_hasRole(_escrowId, msg.sender, _requiredRole) || _isDelegated(_escrowId, msg.sender, _requiredRole, _actionKey), "Insufficient role or delegation");
        _;
    }

    modifier onlyState(uint256 _escrowId, EscrowState _requiredState) {
        require(escrows[_escrowId].state == _requiredState, "Escrow not in required state");
        _;
    }

    modifier notState(uint256 _escrowId, EscrowState _forbiddenState) {
        require(escrows[_escrowId].state != _forbiddenState, "Escrow in forbidden state");
        _;
    }

    modifier onlyActiveOrPaused(uint256 _escrowId) {
        require(escrows[_escrowId].state == EscrowState.Active || escrows[_escrowId].state == EscrowState.Paused, "Escrow not active or paused");
        _;
    }

    // --- 6. Internal Helper Functions ---
    function _isParticipant(uint256 _escrowId, address _addr) internal view returns (bool) {
        Escrow storage escrow = escrows[_escrowId];
        return escrow.participants[_addr] != ParticipantRole.None;
    }

    function _hasRole(uint256 _escrowId, address _addr, ParticipantRole _role) internal view returns (bool) {
        Escrow storage escrow = escrows[_escrowId];
        return escrow.participants[_addr] == _role;
    }

     function _isDelegated(uint256 _escrowId, address _delegatee, ParticipantRole _requiredDelegatorRole, string memory _actionKey) internal view returns (bool) {
        Escrow storage escrow = escrows[_escrowId];
        // Find if any participant with _requiredDelegatorRole has delegated this action to _delegatee
        // This requires iterating or having a direct lookup, which is complex. A simpler approach is
        // to assume the action key *implies* the delegator role (e.g., "confirm:verifier:milestoneX").
        // For this example, we'll use a simpler mapping where the action key directly maps
        // from the original delegator (e.g., the Verifier's address) to the delegatee.
        // Let's refine the delegation map and check: delegatee must be listed by *some* participant
        // who *could* perform the action inherently (e.g., the Verifier for 'confirmMilestoneCompletion').
        // Simpler approach: delegation map is `delegatorAddress => actionKey => delegateeAddress`.
        // So, the caller (delegatee) must be the target of a delegation from the participant *who should*
        // have performed the action.
        // The check should be: Does someone with the required role (_requiredDelegatorRole) for this escrow
        // have a delegation for _actionKey where the delegatee is _addr?
        // We can't efficiently check this without iterating through participants.
        // Let's simplify delegation: `delegatorAddress => actionKey => delegateeAddress`.
        // The check becomes: Is there a participant with the _requiredDelegatorRole
        // who has delegated _actionKey to msg.sender?
        address potentialDelegator = address(0);
        // We need to find who *could* perform this action without delegation.
        // This requires knowing which role corresponds to which actionKey.
        // Let's assume actionKey is specific enough, e.g., "confirm_milestone_<index>".
        // The delegator must be someone assigned the 'Verifier' role for that escrow.
        // This check is still complex without iterating participants.

        // ALTERNATIVE SIMPLER DELEGATION CHECK:
        // `delegatedActions` maps `delegator => actionKey => delegatee`.
        // The modifier `onlyEscrowRoleOrDelegate` checks if msg.sender *is* the required role OR
        // if msg.sender is the delegatee for the required role's action.
        // The `_actionKey` should be constructed to include context, e.g., "confirm_milestone_<index>".
        // The delegator is the address holding the original right (e.g., the Verifier).
        // We need to check if the *actual* Verifier for this escrow has delegated this specific key to msg.sender.
        address actualVerifier = address(0);
        // This still requires finding the Verifier.
        // Let's adjust the delegation map to be `escrowId => delegator => actionKey => delegatee`.
        // The check is: `escrows[_escrowId].delegatedActions[delegatorAddress][actionKey] == msg.sender`.
        // But *who* is the `delegatorAddress`? It must be the address with the *original* right.
        // This mapping should probably be `escrowId => actionKey => delegateeAddress`.
        // The contract logic then checks if the *actual* participant with the role corresponding to actionKey
        // has delegated this key. This is still complex.

        // Let's rethink delegation: `escrowId => actionKey => delegateeAddress`.
        // The key `actionKey` is a string representing the *type* of action (e.g., "confirm_milestone", "initiate_dispute").
        // The contract functions themselves define *which* role can perform an action.
        // So, delegation allows *anyone* (as defined by the delegator) to perform a specific action *on behalf of*
        // the delegator *if* the delegator had the right.
        // Check: Is msg.sender the delegatee for this actionKey for this escrow?
        // AND, did the *delegator* (the one who set the delegation) actually have the right (`_requiredDelegatorRole`)?
        // This requires knowing the delegator address.

        // Let's use a simpler mapping: `escrowId => delegator => actionKey => delegatee`.
        // The modifier then checks: `_hasRole(_escrowId, msg.sender, _requiredRole)` OR
        // Does ANY participant with `_requiredRole` have `delegatedActions[participantAddress][_actionKey] == msg.sender`?
        // STILL requires iterating participants.

        // Simplest approach for this example: `escrowId => string actionKey => delegateeAddress`.
        // The actionKey must uniquely identify the action *and* the delegator's intent/original right.
        // Example: "confirm_milestone_verifier". The contract logic enforces only Verifiers can confirm.
        // Delegation allows a Verifier to give the "confirm_milestone_verifier" right to someone else.
        // The check becomes: `escrows[_escrowId].delegatedActions[actionKey] == msg.sender`.
        // But who set this delegation? The delegator *must* have had the right.
        // The `delegateActionRight` function must enforce that `msg.sender` (the one *setting* delegation)
        // has the necessary role to perform the action identified by `actionKey`.

        // Okay, let's stick to `escrows[_escrowId].delegatedActions[delegatorAddress][actionKey] == delegateeAddress`.
        // The modifier needs to check if `msg.sender` is the delegatee for `_actionKey` *delegated by*
        // someone who *actually has* the `_requiredRole`.
        // This is still inefficient without iterating.

        // REVISED SIMPLER DELEGATION: `escrowId => actionKey => delegatee`. `actionKey` implicitly linked to roles.
        // `actionKey` is a string like "confirmMilestone:verifier:<milestoneIndex>".
        // Delegation mapping: `escrows[_escrowId].delegatedActions[string actionKey] => delegateeAddress`.
        // `delegateActionRight` must be called by someone with the implicit role for `actionKey`.
        // Modifier check: `_hasRole(_escrowId, msg.sender, _requiredRole)` OR
        // `escrows[_escrowId].delegatedActions[_actionKey] == msg.sender`. This is simpler.

        address delegatee = escrows[_escrowId].delegatedActions[_actionKey];
        if (delegatee == msg.sender) {
             // Now, verify if the *original* delegator had the right.
             // This requires knowing who set the delegation.
             // Let's add a mapping: `escrowId => actionKey => delegator`.
             // `escrows[_escrowId].actionDelegators[actionKey]`
             // Check: `escrows[_escrowId].delegatedActions[actionKey] == msg.sender` AND
             // `_hasRole(_escrowId, escrows[_escrowId].actionDelegators[actionKey], _requiredRole)`?

             // This is adding too much complexity. Let's simplify delegation.
             // Delegation means `A` gives `B` permission to do action `X` *on A's behalf*.
             // The simpler pattern is `msg.sender` checks *if* they have the required role.
             // If not, they check if they are the delegatee *for that specific right* from the person *who should have had* that right.
             // This still requires knowing who *should* have had the right.

             // FINAL SIMPLIFICATION: Delegation mapping is `escrowId => delegator_address => actionKey => delegatee_address`.
             // The modifier checks: `_hasRole(_escrowId, msg.sender, _requiredRole)` OR
             // Iterate through *all* participants of the escrow. If a participant `P` has role `_requiredRole`,
             // check if `escrows[_escrowId].delegatedActions[P][_actionKey] == msg.sender`.
             // This is still inefficient.

             // Let's go back to: `escrowId => string actionKey => delegateeAddress`.
             // The `actionKey` implicitly defines the role needed by the *delegator*.
             // E.g., `actionKey = "confirmMilestone_verifier_2"` (for milestone index 2). Only a Verifier can delegate this.
             // The modifier checks `_hasRole(_escrowId, msg.sender, _requiredRole)` OR `escrows[_escrowId].delegatedActions[_actionKey] == msg.sender`.
             // The `delegateActionRight` function must ensure `msg.sender` has the role implied by `actionKey` (or the key includes the role explicitly).
             // Let's assume `actionKey` includes the required delegator role and milestone index if applicable, e.g., "confirmMilestone_Verifier_2".
             // The modifier `onlyEscrowRoleOrDelegate` needs to check if `msg.sender` has `_requiredRole` OR
             // if `msg.sender` is the delegatee for `_actionKey` as set by someone who *could* delegate that key (i.e., someone with the role implied by the key).

            // This requires the actionKey string format to be standardized and parsed.
            // Example: actionKey = "confirm:milestone:<index>". Role needed = Verifier.
            // Delegation set by a Verifier: `delegateActionRight(_escrowId, delegatee, "confirm:milestone:2")`
            // Modifier check for `confirmMilestoneCompletion(2)`: `_requiredRole = Verifier`.
            // Check: `_hasRole(_escrowId, msg.sender, Verifier)` OR `escrows[_escrowId].delegatedActions["confirm:milestone:2"] == msg.sender`.
            // This still needs the mapping `escrows[_escrowId].delegatedActions[actionKey] => delegatee`.
            // Let's use this simpler delegation mapping: `escrows[_escrowId].delegatedActions[string actionKey] => delegateeAddress`.

            // Implementation:
            // The modifier `onlyEscrowRoleOrDelegate` takes `_requiredRole` (the role usually allowed) and `_actionKey`.
            // It checks if `msg.sender` has `_requiredRole` OR if `msg.sender` is the delegatee stored for `_actionKey` in the escrow's delegation map.
            // `delegateActionRight` needs to ensure `msg.sender` *has the right* to delegate that key.
            // This implies `msg.sender` must have the role associated with the `_actionKey`.
            // This means `delegateActionRight` function signature should be `delegateActionRight(uint256 escrowId, address delegatee, string actionKey, ParticipantRole requiredDelegatorRole)`.
            // And the modifier will check `_hasRole(_escrowId, msg.sender, _requiredRole)` OR (`escrows[_escrowId].delegatedActions[_actionKey] == msg.sender` AND the original delegator had the right - need to store delegator).

            // Okay, mapping: `escrowId => string actionKey => delegateeAddress`.
            // `delegateActionRight(escrowId, delegatee, actionKey)`: check if `msg.sender` has the role implicit in `actionKey`.
            // Modifier `onlyEscrowRoleOrDelegate(escrowId, requiredRole, actionKey)`: check `_hasRole(escrowId, msg.sender, requiredRole)` OR `escrows[escrowId].delegatedActions[actionKey] == msg.sender`.
            // THIS IS THE SIMPLEST USABLE APPROACH FOR THIS EXAMPLE.
            // The burden of constructing correct actionKeys and calling `delegateActionRight` with the right role is on the caller.

            address delegateeAddress = escrows[_escrowId].delegatedActions[_actionKey];
            return delegateeAddress != address(0) && delegateeAddress == _delegatee; // Checks if _delegatee is the one currently assigned to actionKey
        }
        return false; // If delegateeAddress is address(0), no delegation exists for this key.
        // The modifier needs to check if msg.sender is the delegatee *appointed for this specific key*.
        // Modifier logic: require(_hasRole(_escrowId, msg.sender, _requiredRole) || escrows[_escrowId].delegatedActions[_actionKey] == msg.sender);
        // This is cleaner. Let's use this.
    }

    function _calculateDynamicPenalty(uint256 _escrowId, uint256 _delayDuration) internal view returns (uint256 penaltyAmount) {
        // Simple example penalty: 0.1% of remaining amount per day of delay
        // In a real scenario, this could be based on milestone importance, total duration, etc.
        Escrow storage escrow = escrows[_escrowId];
        uint256 remaining = escrow.totalAmount - escrow.releasedAmount;
        uint256 delayDays = _delayDuration / 1 days;
        if (delayDays == 0) return 0;

        // Avoid large numbers overflow - cap penalty percentage or delay days
        uint256 penaltyPercentage = delayDays * 10; // 0.1% per day = 10 basis points (10000 basis points = 100%)
        if (penaltyPercentage > 10000) penaltyPercentage = 10000; // Max 100% penalty

        penaltyAmount = (remaining * penaltyPercentage) / 10000;
        return penaltyAmount;
    }

    function _transferFunds(address payable _to, uint256 _amount, address _tokenAddress, bool _isERC20) internal nonReentrant {
        if (_amount == 0) return;

        if (_isERC20) {
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(_to, _amount), "Token transfer failed");
        } else {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "ETH transfer failed");
        }
    }

    // --- 7. Admin Functions ---
    function addApprovedToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address not allowed");
        approvedTokens[_token] = true;
        emit TokenApproved(_token);
    }

    function removeApprovedToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address not allowed");
        approvedTokens[_token] = false;
        emit TokenRemoved(_token);
    }

    // Ownable already provides transferOwnership, which acts as updateAdmin

    // --- 8. Core Escrow Lifecycle Functions ---

    /**
     * @notice Creates a new escrow agreement.
     * @param _recipient The primary recipient of the funds.
     * @param _isERC20 True if using ERC20, false for ETH.
     * @param _tokenAddress The ERC20 token address (address(0) for ETH).
     * @param _totalAmount The total amount of funds for the escrow.
     * @param _finalDeadline The final timestamp by which the escrow should ideally be completed or cancelled.
     * @param _initialMilestones Array of initial milestone definitions.
     * @param _additionalParticipants Array of additional participant addresses.
     * @param _additionalRoles Array of roles corresponding to additional participants.
     */
    function createEscrow(
        address payable _recipient,
        bool _isERC20,
        address _tokenAddress,
        uint256 _totalAmount,
        uint256 _finalDeadline,
        Milestone[] calldata _initialMilestones, // Use calldata for external calls
        address[] calldata _additionalParticipants,
        ParticipantRole[] calldata _additionalRoles
    ) external payable returns (uint256 escrowId) {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_totalAmount > 0, "Total amount must be positive");
        require(_finalDeadline > block.timestamp, "Final deadline must be in the future");
        require(_initialMilestones.length > 0, "Must include at least one milestone");
        require(_additionalParticipants.length == _additionalRoles.length, "Participant/Role array mismatch");

        if (_isERC20) {
            require(_tokenAddress != address(0), "ERC20 token address required");
            require(approvedTokens[_tokenAddress], "ERC20 token not approved");
            require(msg.value == 0, "Cannot send ETH for ERC20 escrow");
        } else {
            require(_tokenAddress == address(0), "ETH escrow does not need token address");
            // ETH is funded separately via receive() or fundEscrowETH after creation
            require(msg.value == 0, "ETH should be funded separately");
        }

        escrowId = nextEscrowId++;

        Escrow storage newEscrow = escrows[escrowId];
        newEscrow.creator = payable(msg.sender);
        newEscrow.recipient = _recipient;
        newEscrow.isERC20 = _isERC20;
        newEscrow.tokenAddress = _tokenAddress;
        newEscrow.totalAmount = _totalAmount;
        newEscrow.releasedAmount = 0;
        newEscrow.state = EscrowState.PendingFunding;
        newEscrow.creationTime = block.timestamp;
        newEscrow.lastUpdateTime = block.timestamp;
        newEscrow.finalDeadline = _finalDeadline;

        // Add initial participants
        newEscrow.participants[msg.sender] = ParticipantRole.Creator;
        newEscrow.participants[_recipient] = ParticipantRole.Recipient;

        for (uint i = 0; i < _additionalParticipants.length; i++) {
             address participant = _additionalParticipants[i];
             ParticipantRole role = _additionalRoles[i];
             require(participant != address(0), "Additional participant cannot be zero address");
             require(role != ParticipantRole.None, "Additional participant must have a role");
             require(newEscrow.participants[participant] == ParticipantRole.None, "Participant already has a default role"); // Avoid overwriting Creator/Recipient
             newEscrow.participants[participant] = role;
             emit ParticipantAdded(escrowId, participant, role);
        }

        // Add initial milestones
        for (uint i = 0; i < _initialMilestones.length; i++) {
            Milestone calldata currentMilestone = _initialMilestones[i];
            if (currentMilestone.milestoneType == MilestoneType.TimeBased) {
                 require(currentMilestone.releaseTime > block.timestamp, "Milestone time must be in the future");
                 require(currentMilestone.requiredConfirmers.length == 0, "Time-based milestones cannot have confirmers");
            } else { // EventBased
                 require(currentMilestone.releaseTime == 0, "Event-based milestones do not use releaseTime");
                 require(currentMilestone.requiredConfirmers.length > 0, "Event-based milestones require at least one confirmer");
                 for(uint j=0; j < currentMilestone.requiredConfirmers.length; j++) {
                     require(newEscrow.participants[currentMilestone.requiredConfirmers[j]] != ParticipantRole.None, "Confirmer must be an escrow participant");
                 }
            }
            require(currentMilestone.amount > 0, "Milestone amount must be positive");

            newEscrow.milestones.push(Milestone({
                milestoneType: currentMilestone.milestoneType,
                amount: currentMilestone.amount,
                releaseTime: currentMilestone.releaseTime,
                isCompleted: false,
                requiredConfirmers: currentMilestone.requiredConfirmers, // Copy addresses
                isReleased: false
            }));
            // Note: confirmations mapping is implicitly initialized empty
            emit MilestoneAdded(escrowId, newEscrow.milestones.length - 1, currentMilestone.milestoneType, currentMilestone.amount, currentMilestone.releaseTime);
        }

        emit EscrowCreated(escrowId, msg.sender, _recipient, _isERC20, _tokenAddress, _totalAmount, _finalDeadline);
    }

    /**
     * @notice Funds an existing ETH-based escrow. Can be called by anyone.
     * @param _escrowId The ID of the escrow to fund.
     */
    function fundEscrowETH(uint256 _escrowId) external payable onlyState(_escrowId, EscrowState.PendingFunding) {
        Escrow storage escrow = escrows[_escrowId];
        require(!escrow.isERC20, "Escrow is ERC20 based");
        require(msg.value > 0, "Must send non-zero ETH");

        // Check if overfunding
        uint256 currentBalance = address(this).balance - msg.value; // Current balance before this tx value
        uint256 needed = escrow.totalAmount - currentBalance;

        require(msg.value <= needed, "Funding amount exceeds needed amount");

        if (currentBalance + msg.value >= escrow.totalAmount) {
            escrow.state = EscrowState.Active;
            escrow.lastUpdateTime = block.timestamp;
            emit EscrowStateChanged(_escrowId, EscrowState.PendingFunding, EscrowState.Active);
        }
        // Excess ETH sent? This shouldn't happen with the 'needed' check.
        // If the check was removed, handle excess ETH return here or in fallback.
        // With the strict check `msg.value <= needed`, we are okay.

        emit EscrowFunded(_escrowId, msg.value);
    }

    /**
     * @notice Funds an existing ERC20-based escrow. Requires prior approval. Called by the funder.
     * @param _escrowId The ID of the escrow to fund.
     * @param _amount The amount of ERC20 tokens to transfer.
     */
    function fundEscrowERC20(uint256 _escrowId, uint256 _amount) external onlyState(_escrowId, EscrowState.PendingFunding) {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.isERC20, "Escrow is ETH based");
        require(_amount > 0, "Amount must be positive");

        IERC20 token = IERC20(escrow.tokenAddress);

        // Check if overfunding based on tokens currently held by THIS contract for this escrow
        // This is tricky to track precisely without per-escrow token balances.
        // Assuming the *total* amount needed is `escrow.totalAmount`, we check if adding `_amount`
        // would exceed this. We'll need to track tokens held *per escrow*.
        // Let's add `currentBalance` to the Escrow struct for ERC20.
        // This requires a struct modification, or tracking in a mapping `mapping(uint256 => uint256) erc20EscrowBalances;`.
        // Let's use the mapping for simplicity without modifying the struct.

        mapping(uint256 => uint256) private erc20EscrowBalances; // Add this state variable

        require(erc20EscrowBalances[_escrowId] + _amount <= escrow.totalAmount, "Funding amount exceeds total amount needed");

        // Transfer tokens from the caller (who must have approved this contract)
        require(token.transferFrom(msg.sender, address(this), _amount), "ERC20 transfer failed");

        erc20EscrowBalances[_escrowId] += _amount;

        if (erc20EscrowBalances[_escrowId] >= escrow.totalAmount) {
            escrow.state = EscrowState.Active;
            escrow.lastUpdateTime = block.timestamp;
            emit EscrowStateChanged(_escrowId, EscrowState.PendingFunding, EscrowState.Active);
        }

        emit EscrowFunded(_escrowId, _amount);
    }

    /**
     * @notice Adds a new milestone to an escrow. Only allowed before funding or in certain states (complex).
     *         For simplicity, allowed only in PendingFunding state in this example.
     * @param _escrowId The ID of the escrow.
     * @param _milestone The milestone details to add.
     */
    function addMilestone(uint256 _escrowId, Milestone calldata _milestone)
        external
        onlyEscrowParticipant(_escrowId)
        onlyState(_escrowId, EscrowState.PendingFunding) // Simplified: only before funding
    {
        Escrow storage escrow = escrows[_escrowId];
        // Additional complex logic could allow adding milestones in Active state
        // if signed by Creator and Recipient, or within a time window, etc.
        // require(_hasRole(_escrowId, msg.sender, ParticipantRole.Creator), "Only Creator can add milestones"); // Example restriction

        if (_milestone.milestoneType == MilestoneType.TimeBased) {
             require(_milestone.releaseTime > block.timestamp, "Milestone time must be in the future");
             require(_milestone.requiredConfirmers.length == 0, "Time-based milestones cannot have confirmers");
        } else { // EventBased
             require(_milestone.releaseTime == 0, "Event-based milestones do not use releaseTime");
             require(_milestone.requiredConfirmers.length > 0, "Event-based milestones require at least one confirmer");
             for(uint j=0; j < _milestone.requiredConfirmers.length; j++) {
                 require(escrow.participants[_milestone.requiredConfirmers[j]] != ParticipantRole.None, "Confirmer must be an escrow participant");
             }
        }
         require(_milestone.amount > 0, "Milestone amount must be positive");
        // Ensure total milestone amounts don't exceed total escrow amount
        uint256 currentMilestoneSum = 0;
        for(uint i=0; i<escrow.milestones.length; i++) {
            currentMilestoneSum += escrow.milestones[i].amount;
        }
        require(currentMilestoneSum + _milestone.amount <= escrow.totalAmount, "Adding milestone exceeds total escrow amount");


        escrow.milestones.push(Milestone({
            milestoneType: _milestone.milestoneType,
            amount: _milestone.amount,
            releaseTime: _milestone.releaseTime,
            isCompleted: false,
            requiredConfirmers: _milestone.requiredConfirmers,
            isReleased: false
        }));
        // confirmations mapping is implicitly initialized empty

        emit MilestoneAdded(_escrowId, escrow.milestones.length - 1, _milestone.milestoneType, _milestone.amount, _milestone.releaseTime);
    }

    /**
     * @notice Updates a future milestone in an escrow. Only allowed before funding or in certain states (complex).
     *         For simplicity, allowed only in PendingFunding state in this example.
     * @param _escrowId The ID of the escrow.
     * @param _milestoneIndex The index of the milestone to update.
     * @param _milestone The updated milestone details.
     */
     function updateMilestone(uint256 _escrowId, uint256 _milestoneIndex, Milestone calldata _milestone)
        external
        onlyEscrowParticipant(_escrowId)
        onlyState(_escrowId, EscrowState.PendingFunding) // Simplified: only before funding
     {
        Escrow storage escrow = escrows[_escrowId];
        require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
        require(!escrow.milestones[_milestoneIndex].isReleased, "Cannot update a released milestone");

        // Check if over/under total amount
        uint256 currentMilestoneSum = 0;
        for(uint i=0; i<escrow.milestones.length; i++) {
            if (i != _milestoneIndex) {
                currentMilestoneSum += escrow.milestones[i].amount;
            }
        }
        require(currentMilestoneSum + _milestone.amount <= escrow.totalAmount, "Updating milestone exceeds total escrow amount");
        require(_milestone.amount > 0, "Milestone amount must be positive");


        if (_milestone.milestoneType == MilestoneType.TimeBased) {
             require(_milestone.releaseTime > block.timestamp, "Milestone time must be in the future");
             require(_milestone.requiredConfirmers.length == 0, "Time-based milestones cannot have confirmers");
        } else { // EventBased
             require(_milestone.releaseTime == 0, "Event-based milestones do not use releaseTime");
             require(_milestone.requiredConfirmers.length > 0, "Event-based milestones require at least one confirmer");
             for(uint j=0; j < _milestone.requiredConfirmers.length; j++) {
                 require(escrow.participants[_milestone.requiredConfirmers[j]] != ParticipantRole.None, "Confirmer must be an escrow participant");
             }
             // Reset confirmations if type or confirmers change
             if (escrow.milestones[_milestoneIndex].milestoneType != _milestone.milestoneType ||
                 escrow.milestones[_milestoneIndex].requiredConfirmers.length != _milestone.requiredConfirmers.length ||
                 !_compareAddresses(escrow.milestones[_milestoneIndex].requiredConfirmers, _milestone.requiredConfirmers))
             {
                 escrow.milestones[_milestoneIndex].isCompleted = false;
                 // Cannot easily clear mapping, will need to track confirmations differently or disallow changing confirmers/type while confirmations exist
                 // For simplicity, this example will disallow changing type or required confirmers if any confirmations exist.
                 // A proper solution would involve removing/resetting the mapping entries.
                 // Let's make a simple check: if it was EventBased, check if isCompleted is true or if any confirmations were recorded.
                 if (escrow.milestones[_milestoneIndex].milestoneType == MilestoneType.EventBased && escrow.milestones[_milestoneIndex].isCompleted) {
                      revert("Cannot update event-based milestone after completion");
                 }
                 // Cannot check if confirmations mapping is non-empty easily. Assume if isCompleted is false, no confirmations matter yet.
             }
        }

        escrow.milestones[_milestoneIndex].milestoneType = _milestone.milestoneType;
        escrow.milestones[_milestoneIndex].amount = _milestone.amount;
        escrow.milestones[_milestoneIndex].releaseTime = _milestone.releaseTime;
        escrow.milestones[_milestoneIndex].requiredConfirmers = _milestone.requiredConfirmers; // Overwrites previous array
        // Confirmations mapping is NOT overwritten automatically. Need to handle reset if confirmers change significantly.
        // For this example, assuming update is done before any confirmation activity for event-based.

        emit MilestoneUpdated(_escrowId, _milestoneIndex, _milestone.milestoneType, _milestone.amount, _milestone.releaseTime);
     }

     // Helper for updateMilestone confirmer comparison
     function _compareAddresses(address[] storage a, address[] memory b) internal pure returns (bool) {
        if (a.length != b.length) return false;
        for (uint i = 0; i < a.length; i++) {
            bool found = false;
            for (uint j = 0; j < b.length; j++) {
                if (a[i] == b[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) return false;
        }
        return true; // Assumes unique addresses in each array
     }


    /**
     * @notice Removes a future milestone from an escrow. Only allowed before funding.
     * @param _escrowId The ID of the escrow.
     * @param _milestoneIndex The index of the milestone to remove.
     */
    function removeMilestone(uint256 _escrowId, uint256 _milestoneIndex)
        external
        onlyEscrowParticipant(_escrowId)
        onlyState(_escrowId, EscrowState.PendingFunding) // Simplified: only before funding
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
        require(!escrow.milestones[_milestoneIndex].isReleased, "Cannot remove a released milestone");
         // Cannot remove if it's the only milestone
        require(escrow.milestones.length > 1, "Cannot remove the only milestone");


        // Shift elements after the removed one
        for (uint i = _milestoneIndex; i < escrow.milestones.length - 1; i++) {
            escrow.milestones[i] = escrow.milestones[i + 1];
            // Note: Mappings (like confirmations) are NOT copied with struct assignment. This is a limitation.
            // A robust implementation needs to handle mapping data explicitly or avoid deleting array elements with mappings.
            // For this example, assuming remove happens before any confirmations are relevant.
        }
        // Remove the last element (which is a duplicate of the second to last now)
        escrow.milestones.pop();

        emit MilestoneRemoved(_escrowId, _milestoneIndex);
    }

    /**
     * @notice Marks an event-based milestone as completed. Requires the Verifier role or delegation.
     * @param _escrowId The ID of the escrow.
     * @param _milestoneIndex The index of the milestone to confirm.
     */
    function confirmMilestoneCompletion(uint256 _escrowId, uint256 _milestoneIndex)
        external
        onlyActiveOrPaused(_escrowId)
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
        Milestone storage milestone = escrow.milestones[_milestoneIndex];

        require(milestone.milestoneType == MilestoneType.EventBased, "Milestone is not event-based");
        require(!milestone.isCompleted, "Milestone already completed");
        require(!milestone.isReleased, "Milestone already released");

        // Check if msg.sender is a required confirmer OR is delegated the right
        bool isRequiredConfirmer = false;
        for(uint i=0; i < milestone.requiredConfirmers.length; i++) {
            if(milestone.requiredConfirmers[i] == msg.sender) {
                isRequiredConfirmer = true;
                break;
            }
        }
        // Delegation check: Check if msg.sender is delegated the action "confirm:<milestoneIndex>" by any required confirmer
        bool isDelegatedConfirmer = false;
        string memory actionKey = string.concat("confirm:milestone:", Strings.toString(_milestoneIndex));
         for(uint i=0; i < milestone.requiredConfirmers.length; i++) {
             if(escrow.delegatedActions[milestone.requiredConfirmers[i]][actionKey] == msg.sender) {
                 isDelegatedConfirmer = true;
                 break;
             }
         }

        require(isRequiredConfirmer || isDelegatedConfirmer, "Not authorized to confirm this milestone");

        milestone.confirmations[msg.sender] = true;

        // Check if all required confirmers have confirmed
        bool allConfirmed = true;
        for(uint i=0; i < milestone.requiredConfirmers.length; i++) {
            if(!milestone.confirmations[milestone.requiredConfirmers[i]]) {
                allConfirmed = false;
                break;
            }
        }

        if(allConfirmed) {
            milestone.isCompleted = true;
            emit MilestoneCompleted(_escrowId, _milestoneIndex, msg.sender);
            // Funds are released via requestMilestoneRelease, not automatically here
        }
    }

    /**
     * @notice Requests the release of funds for a specific milestone. Anyone can call, but release only happens if conditions met.
     * @param _escrowId The ID of the escrow.
     * @param _milestoneIndex The index of the milestone to request release for.
     */
    function requestMilestoneRelease(uint256 _escrowId, uint256 _milestoneIndex)
        external
        nonReentrant
        onlyActiveOrPaused(_escrowId)
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
        Milestone storage milestone = escrow.milestones[_milestoneIndex];

        require(!milestone.isReleased, "Milestone already released");

        bool conditionsMet = false;
        if (milestone.milestoneType == MilestoneType.TimeBased) {
            conditionsMet = block.timestamp >= milestone.releaseTime;
             if (!conditionsMet && block.timestamp >= escrow.finalDeadline) {
                 // Apply penalty if time-based milestone missed final deadline
                 uint256 delay = block.timestamp - milestone.releaseTime; // How long overdue based on milestone time
                 uint256 penalty = _calculateDynamicPenalty(_escrowId, delay); // Penalty based on total delay or delay since milestone?
                 // Let's simplify: penalty based on delay *since the milestone release time* if past final deadline.
                 // Or penalty based on duration *past the finalDeadline* if the milestone is not completed/released.
                 // Let's use the latter: penalty if finalDeadline is past AND milestone not released.
                  if (block.timestamp > escrow.finalDeadline) {
                     uint256 delayPastDeadline = block.timestamp - escrow.finalDeadline;
                     penalty = _calculateDynamicPenalty(_escrowId, delayPastDeadline); // Penalty based on how late the escrow is overall
                     // Apply penalty logic later during distribution/cancellation/dispute
                     // For now, just prevent release if past final deadline UNLESS dispute handled?
                     // Let's allow release even past deadline but note penalty context.
                     // Or disallow release via this function if past final deadline, forcing cancel/dispute?
                     // Let's allow release but _calculateDynamicPenalty might be used elsewhere.
                  }
            }

        } else { // EventBased
            conditionsMet = milestone.isCompleted;
             if (!conditionsMet && block.timestamp >= escrow.finalDeadline) {
                  // Apply penalty if event-based milestone not completed by final deadline
                  // Similar penalty logic as above.
             }
        }

        require(conditionsMet, "Milestone conditions not met");

        // Calculate release amount. Could be milestone.amount, minus penalties if applicable.
        // For simplicity, this release does not apply penalties directly. Penalties are handled on dispute/cancel.
        uint256 amountToRelease = milestone.amount;

        require(escrow.releasedAmount + amountToRelease <= escrow.totalAmount, "Release amount exceeds total");

        milestone.isReleased = true;
        escrow.releasedAmount += amountToRelease;
        escrow.lastUpdateTime = block.timestamp;

        address payable recipient = escrow.recipient; // Funds go to recipient for milestones
        address token = escrow.tokenAddress;
        bool isERC20 = escrow.isERC20;

        _transferFunds(recipient, amountToRelease, token, isERC20);

        emit MilestoneReleased(_escrowId, _milestoneIndex, amountToRelease);

        // Check if all milestones are released
        bool allMilestonesReleased = true;
        for(uint i=0; i < escrow.milestones.length; i++) {
            if(!escrow.milestones[i].isReleased) {
                allMilestonesReleased = false;
                break;
            }
        }

        if(allMilestonesReleased) {
            escrow.state = EscrowState.Completed;
            escrow.lastUpdateTime = block.timestamp;
            emit EscrowStateChanged(_escrowId, escrow.state, EscrowState.Completed);
            // Any remaining dust is handled by claimRemainingFunds
        }
    }

     /**
      * @notice Allows participants to claim any remaining funds in the escrow after completion or cancellation.
      *         Handles dust or remaining balance after all planned releases/penalties.
      * @param _escrowId The ID of the escrow.
      */
     function claimRemainingFunds(uint256 _escrowId)
        external
        nonReentrant
        onlyEscrowParticipant(_escrowId)
        notState(_escrowId, EscrowState.PendingFunding) // Cannot claim before funding
        notState(_escrowId, EscrowState.Active)       // Cannot claim while active
        notState(_escrowId, EscrowState.Paused)       // Cannot claim while paused
        notState(_escrowId, EscrowState.Disputed)     // Cannot claim while disputed
     {
         Escrow storage escrow = escrows[_escrowId];
         uint256 remainingBalance;
         address tokenAddress = escrow.tokenAddress;
         bool isERC20 = escrow.isERC20;

         if (isERC20) {
             remainingBalance = erc20EscrowBalances[_escrowId];
             // This assumes erc20EscrowBalances[_escrowId] accurately tracks tokens for this escrow.
             // A more robust approach tracks per-escrow balance via state variables or a detailed mapping during transfers.
             // For this example, let's assume `erc20EscrowBalances` is correctly updated.
             require(remainingBalance > 0, "No ERC20 funds remaining for this escrow");
             // Reset balance after claiming
             erc20EscrowBalances[_escrowId] = 0;

         } else {
             remainingBalance = address(this).balance; // This is the contract's total ETH balance.
             // Need to track per-escrow ETH balance. Let's add a mapping.
             mapping(uint256 => uint256) private ethEscrowBalances; // Add this state variable
             remainingBalance = ethEscrowBalances[_escrowId];
             require(remainingBalance > 0, "No ETH funds remaining for this escrow");
              // Reset balance after claiming
             ethEscrowBalances[_escrowId] = 0;
         }


         // Funds go back to creator if cancelled, or handled by dispute outcome, or recipient if completed with dust
         address payable recipient = escrow.recipient;
         address payable creator = escrow.creator;
         address payable claimTo = payable(address(0));

         if (escrow.state == EscrowState.Completed) {
             // If completed, any remaining dust goes to the recipient
             claimTo = recipient;
         } else if (escrow.state == EscrowState.Cancelled) {
             // If cancelled, remaining goes back to creator (after any penalties were applied elsewhere)
             claimTo = creator;
         }
         // If state was Disputed and now resolved/split, recordDisputeOutcome handles distribution directly.
         // This function is for claiming leftovers after the primary resolution mechanism.

         require(claimTo != address(0), "Claim destination not determined for this state");

         _transferFunds(claimTo, remainingBalance, tokenAddress, isERC20);

         emit FundsClaimed(_escrowId, claimTo, remainingBalance);

         // Note: this doesn't delete the escrow struct, only empties the balance.
     }


     /**
      * @notice Allows authorized participants to cancel the escrow prematurely.
      *         May trigger penalty calculation and fund distribution logic.
      * @param _escrowId The ID of the escrow.
      * @param _reason A brief reason for cancellation.
      */
     function cancelEscrow(uint256 _escrowId, string memory _reason)
        external
        nonReentrant
        onlyEscrowParticipant(_escrowId)
        onlyActiveOrPaused(_escrowId) // Only active or paused can be cancelled this way
     {
         Escrow storage escrow = escrows[_escrowId];
         // Define who can cancel: Creator, Recipient, or Arbiter perhaps?
         // Let's allow Creator or Recipient for simplicity.
         require(_hasRole(_escrowId, msg.sender, ParticipantRole.Creator) || _hasRole(_escrowId, msg.sender, ParticipantRole.Recipient), "Only Creator or Recipient can initiate cancellation");

         // Penalty logic: A simple example - penalize the initiator if the other party hasn't breached yet?
         // Or calculate based on completion percentage?
         // For simplicity, calculate a fixed percentage penalty or a penalty based on state/initiator role.
         // Let's say 5% penalty if cancelled by creator, 10% if by recipient (example logic).
         uint256 totalHeld;
         address token = escrow.tokenAddress;
         bool isERC20 = escrow.isERC20;

         if (isERC20) {
             totalHeld = erc20EscrowBalances[_escrowId];
             erc20EscrowBalances[_escrowId] = 0; // Clear balance map entry
         } else {
             totalHeld = ethEscrowBalances[_escrowId];
             ethEscrowBalances[_escrowId] = 0; // Clear balance map entry
         }

         require(totalHeld > 0, "No funds held in escrow to cancel");

         uint256 penaltyAmount = 0;
         address payable penaltyRecipient = payable(address(0)); // Where penalty goes (e.g., owner, or the other party)

         if (_hasRole(_escrowId, msg.sender, ParticipantRole.Creator)) {
             // Example: Creator cancels, potentially penalize Creator
             penaltyAmount = (totalHeld * 5) / 100; // 5% penalty
             penaltyRecipient = escrow.recipient; // Penalty goes to recipient (simplified)
         } else if (_hasRole(_escrowId, msg.sender, ParticipantRole.Recipient)) {
             // Example: Recipient cancels, potentially penalize Recipient
             penaltyAmount = (totalHeld * 10) / 100; // 10% penalty
             penaltyRecipient = escrow.creator; // Penalty goes to creator (simplified)
         }
         // Arbiter cancellation logic could be different

         uint256 returnAmount = totalHeld - penaltyAmount;

         // Distribute funds
         if (penaltyAmount > 0 && penaltyRecipient != address(0)) {
             _transferFunds(penaltyRecipient, penaltyAmount, token, isERC20);
         }
          if (returnAmount > 0) {
              address payable returnTo = _hasRole(_escrowId, msg.sender, ParticipantRole.Creator) ? escrow.creator : escrow.recipient;
             _transferFunds(returnTo, returnAmount, token, isERC20);
          }


         escrow.state = EscrowState.Cancelled;
         escrow.lastUpdateTime = block.timestamp;
         emit EscrowStateChanged(_escrowId, escrow.state, EscrowState.Cancelled);
         emit EscrowCancelled(_escrowId, msg.sender, _reason);

         // Note: Remaining funds not released via milestones are handled here.
         // If some milestones were released, `escrow.releasedAmount` tracks that separately.
     }

      /**
       * @notice Allows anyone to force cancel an escrow if it's past its final deadline AND not completed/cancelled/disputed.
       *         Applies a penalty and returns funds primarily to the creator.
       * @param _escrowId The ID of the escrow.
       */
      function forceCancelExpiredEscrow(uint256 _escrowId) external nonReentrant {
          Escrow storage escrow = escrows[_escrowId];
          require(escrow.state != EscrowState.Completed && escrow.state != EscrowState.Cancelled && escrow.state != EscrowState.Disputed, "Escrow already finalized or in dispute");
          require(block.timestamp > escrow.finalDeadline, "Escrow has not passed its final deadline");

          // Calculate penalty based on time past deadline
          uint256 delayPastDeadline = block.timestamp - escrow.finalDeadline;
          uint256 penaltyAmount = _calculateDynamicPenalty(_escrowId, delayPastDeadline);

          uint256 totalHeld;
          address token = escrow.tokenAddress;
          bool isERC20 = escrow.isERC20;

          if (isERC20) {
              totalHeld = erc20EscrowBalances[_escrowId];
              erc20EscrowBalances[_escrowId] = 0; // Clear balance map entry
          } else {
              totalHeld = ethEscrowBalances[_escrowId];
              ethEscrowBalances[_escrowId] = 0; // Clear balance map entry
          }

          require(totalHeld > 0, "No funds held in escrow to force cancel");

          uint256 returnAmount = totalHeld - penaltyAmount;

          // Funds primarily return to creator, penalty could go to owner or be burned (example: owner)
          address payable returnTo = escrow.creator;
          address payable penaltyTo = payable(owner()); // Penalty goes to contract owner

          if (penaltyAmount > 0 && penaltyTo != address(0)) {
              // Ensure penalty doesn't exceed held amount
              uint256 actualPenalty = penaltyAmount > totalHeld ? totalHeld : penaltyAmount;
              _transferFunds(penaltyTo, actualPenalty, token, isERC20);
              returnAmount = totalHeld - actualPenalty;
          }

          if (returnAmount > 0) {
             _transferFunds(returnTo, returnAmount, token, isERC20);
          }

          escrow.state = EscrowState.Cancelled; // Mark as cancelled due to expiration
          escrow.lastUpdateTime = block.timestamp;
          emit EscrowStateChanged(_escrowId, escrow.state, EscrowState.Cancelled);
          emit EscrowCancelled(_escrowId, msg.sender, "Force cancelled due to expiry");
           // Could add a specific event for force cancellation
      }


    // --- 9. Participant Management Functions ---

    /**
     * @notice Adds a new participant to an escrow. Only allowed before funding or by Creator/Arbiter (example logic).
     * @param _escrowId The ID of the escrow.
     * @param _participant The address to add.
     * @param _role The role to assign.
     */
    function addParticipant(uint256 _escrowId, address _participant, ParticipantRole _role)
        external
        onlyEscrowParticipant(_escrowId)
        notState(_escrowId, EscrowState.Completed)
        notState(_escrowId, EscrowState.Cancelled)
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_participant != address(0), "Participant address cannot be zero");
        require(_role != ParticipantRole.None, "Role must be specified");
         require(escrow.participants[_participant] == ParticipantRole.None, "Address is already a participant");

        // Example: Only creator can add participants before funding, or Arbiter/Creator after.
        bool canAdd = false;
        if (escrow.state == EscrowState.PendingFunding) {
            canAdd = _hasRole(_escrowId, msg.sender, ParticipantRole.Creator);
        } else { // Active, Paused, Disputed
             canAdd = _hasRole(_escrowId, msg.sender, ParticipantRole.Creator) || _hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter);
        }
        require(canAdd, "Not authorized to add participant");

        escrow.participants[_participant] = _role;
        emit ParticipantAdded(_escrowId, _participant, _role);
    }

     /**
      * @notice Removes a participant from an escrow. Only allowed by Creator/Arbiter (example logic).
      *         Cannot remove Creator, Recipient, or themselves if they initiated removal.
      * @param _escrowId The ID of the escrow.
      * @param _participant The address to remove.
      */
     function removeParticipant(uint256 _escrowId, address _participant)
         external
         onlyEscrowParticipant(_escrowId)
         notState(_escrowId, EscrowState.Completed)
         notState(_escrowId, EscrowState.Cancelled)
     {
        Escrow storage escrow = escrows[_escrowId];
        require(_participant != address(0), "Participant address cannot be zero");
        require(_isParticipant(_escrowId, _participant), "Address is not an escrow participant");
         require(escrow.participants[_participant] != ParticipantRole.Creator && escrow.participants[_participant] != ParticipantRole.Recipient, "Cannot remove Creator or Recipient");
         require(_participant != msg.sender, "Cannot remove yourself");

        // Example: Only creator or Arbiter can remove participants.
        bool canRemove = _hasRole(_escrowId, msg.sender, ParticipantRole.Creator) || _hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter);
        require(canRemove, "Not authorized to remove participant");

        ParticipantRole oldRole = escrow.participants[_participant];
        delete escrow.participants[_participant]; // Removes the participant's role entry
        emit ParticipantRemoved(_escrowId, _participant);
        emit ParticipantRoleUpdated(_escrowId, _participant, oldRole, ParticipantRole.None); // Signal role change to None
     }

    /**
     * @notice Sets or updates the role of an existing participant. Only allowed by Creator/Arbiter (example logic).
     *         Cannot change Creator/Recipient roles directly via this function.
     * @param _escrowId The ID of the escrow.
     * @param _participant The address whose role to set.
     * @param _role The new role to assign.
     */
    function setParticipantRole(uint256 _escrowId, address _participant, ParticipantRole _role)
        external
        onlyEscrowParticipant(_escrowId)
        notState(_escrowId, EscrowState.Completed)
        notState(_escrowId, EscrowState.Cancelled)
    {
        Escrow storage escrow = escrows[_escrowId];
         require(_participant != address(0), "Participant address cannot be zero");
        require(_isParticipant(_escrowId, _participant), "Address is not an escrow participant");
         require(_role != ParticipantRole.Creator && _role != ParticipantRole.Recipient, "Cannot set role to Creator or Recipient via this function");
        require(escrow.participants[_participant] != ParticipantRole.Creator && escrow.participants[_participant] != ParticipantRole.Recipient, "Cannot change Creator or Recipient roles");


        // Example: Only creator or Arbiter can set roles.
        bool canSet = _hasRole(_escrowId, msg.sender, ParticipantRole.Creator) || _hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter);
        require(canSet, "Not authorized to set participant role");

        ParticipantRole oldRole = escrow.participants[_participant];
        require(oldRole != _role, "Participant already has this role");

        escrow.participants[_participant] = _role;
        emit ParticipantRoleUpdated(_escrowId, _participant, oldRole, _role);
    }

    /**
     * @notice Allows a participant to delegate a specific action right to another address for this escrow.
     *         The delegator must have the inherent right to perform the action.
     * @param _escrowId The ID of the escrow.
     * @param _delegatee The address to delegate the right to.
     * @param _actionKey A string identifier for the action (e.g., "confirm:milestone:2", "initiate:dispute").
     */
    function delegateActionRight(uint256 _escrowId, address _delegatee, string memory _actionKey)
        external
        onlyEscrowParticipant(_escrowId)
        notState(_escrowId, EscrowState.Completed)
        notState(_escrowId, EscrowState.Cancelled)
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");

        // Check if msg.sender has the inherent right to perform the action implied by _actionKey.
        // This requires parsing _actionKey or having a predefined mapping.
        // For this example, we will use a simplified check: `msg.sender` must have the 'Verifier' role to delegate 'confirm:milestone:*'
        // and 'Creator' or 'Recipient' or 'Arbiter' to delegate 'initiate:dispute'.
        // A more complex contract might use a lookup table or interface for this.

        bool canDelegate = false;
        if (keccak256(bytes(_actionKey)) == keccak256(bytes("initiate:dispute"))) {
             canDelegate = _hasRole(_escrowId, msg.sender, ParticipantRole.Creator) ||
                           _hasRole(_escrowId, msg.sender, ParticipantRole.Recipient) ||
                           _hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter);
        } else if (bytes(_actionKey).length >= 17 && keccak256(bytes(_actionKey)[:17]) == keccak256(bytes("confirm:milestone:"))) {
             // Requires parsing milestone index from actionKey string - complex in Solidity
             // Simplified check: requires Verifier role
             canDelegate = _hasRole(_escrowId, msg.sender, ParticipantRole.Verifier);
        } else {
             // Unknown action key
             revert("Unsupported action key for delegation check");
        }

        require(canDelegate, "Not authorized to delegate this action");

        escrow.delegatedActions[msg.sender][_actionKey] = _delegatee;
        emit ActionDelegated(_escrowId, msg.sender, _delegatee, _actionKey);
    }

    /**
     * @notice Revokes a previously delegated action right.
     * @param _escrowId The ID of the escrow.
     * @param _actionKey The string identifier for the action to revoke.
     */
    function revokeActionRight(uint256 _escrowId, string memory _actionKey)
        external
        onlyEscrowParticipant(_escrowId)
        notState(_escrowId, EscrowState.Completed)
        notState(_escrowId, EscrowState.Cancelled)
    {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.delegatedActions[msg.sender][_actionKey] != address(0), "No such delegation exists from you");

        delete escrow.delegatedActions[msg.sender][_actionKey];
        emit ActionRevoked(_escrowId, msg.sender, _actionKey);
    }


    // --- 10. Dispute Resolution Functions ---

    /**
     * @notice Initiates a dispute for the escrow. Requires Creator, Recipient, or Arbiter role or delegation.
     * @param _escrowId The ID of the escrow.
     * @param _reason A brief reason for initiating the dispute.
     */
    function initiateDispute(uint256 _escrowId, string memory _reason)
        external
        onlyEscrowParticipant(_escrowId)
        onlyActiveOrPaused(_escrowId) // Only active or paused can go into dispute
        notState(_escrowId, EscrowState.Disputed) // Cannot initiate if already disputed
    {
        Escrow storage escrow = escrows[_escrowId];
        // Define who can initiate: Creator, Recipient, or Arbiter
        string memory actionKey = "initiate:dispute";
        require(
             _hasRole(_escrowId, msg.sender, ParticipantRole.Creator) ||
             _hasRole(_escrowId, msg.sender, ParticipantRole.Recipient) ||
             _hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter) ||
             escrow.delegatedActions[msg.sender][actionKey] == msg.sender, // Check if msg.sender is delegated by self? No, check if delegated by someone with the role.
             // Delegation check needs rethinking here. Let's revert to just role check for initiateDispute.
             // require(_hasRole(_escrowId, msg.sender, ParticipantRole.Creator) || _hasRole(_escrowId, msg.sender, ParticipantRole.Recipient) || _hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter), "Not authorized to initiate dispute");
             // Re-integrating the modifier: onlyEscrowRoleOrDelegate(_escrowId, ParticipantRole.Creator, "initiate:dispute") - this needs the specific role passed to the modifier, which is complex here.
             // Let's just manually check roles for simplicity in this function.
             // Okay, manual check based on allowed roles:
             _hasRole(_escrowId, msg.sender, ParticipantRole.Creator) || _hasRole(_escrowId, msg.sender, ParticipantRole.Recipient) || _hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter),
             "Not authorized to initiate dispute"
         );

        EscrowState oldState = escrow.state;
        escrow.state = EscrowState.Disputed;
        escrow.lastUpdateTime = block.timestamp;
        escrow.disputeOutcome = DisputeOutcome.Undecided; // Reset outcome

        emit EscrowStateChanged(_escrowId, oldState, EscrowState.Disputed);
        emit DisputeInitiated(_escrowId, msg.sender, _reason);
    }

    /**
     * @notice Records the outcome of an off-chain dispute resolution process and distributes funds.
     *         Requires the Arbiter role or delegation.
     * @param _escrowId The ID of the escrow.
     * @param _outcome The outcome of the dispute (CreatorWins, RecipientWins, Split).
     * @param _winningParty The address designated to receive the main portion (needed for Split).
     * @param _winningAmount The amount for the winning party in a Split outcome.
     * @param _losingPenaltyAmount The amount designated as penalty from the losing party's share.
     */
    function recordDisputeOutcome(
        uint256 _escrowId,
        DisputeOutcome _outcome,
        address payable _winningParty,
        uint256 _winningAmount,
        uint256 _losingPenaltyAmount
    ) external nonReentrant onlyState(_escrowId, EscrowState.Disputed) {
        Escrow storage escrow = escrows[_escrowId];
         // Only Arbiter or delegated party can record outcome
        string memory actionKey = "record:dispute:outcome";
        require(_hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter) || escrow.delegatedActions[msg.sender][actionKey] == msg.sender, "Not authorized to record dispute outcome");


        require(_outcome != DisputeOutcome.Undecided, "Outcome cannot be Undecided");

        uint256 totalHeld;
        address token = escrow.tokenAddress;
        bool isERC20 = escrow.isERC20;

         if (isERC20) {
              totalHeld = erc20EscrowBalances[_escrowId];
             erc20EscrowBalances[_escrowId] = 0; // Clear balance map entry
         } else {
             totalHeld = ethEscrowBalances[_escrowId];
             ethEscrowBalances[_escrowId] = 0; // Clear balance map entry
         }

         require(totalHeld > 0, "No funds held in escrow to distribute");


        escrow.disputeOutcome = _outcome;
        escrow.winningParty = _winningParty; // Store for record keeping if needed
        escrow.winningAmount = _winningAmount; // Store for record keeping if needed
        escrow.losingPenaltyAmount = _losingPenaltyAmount; // Store for record keeping if needed

        uint256 creatorShare = 0;
        uint256 recipientShare = 0;
        uint256 penaltyShare = 0; // Example: penalty goes to Arbiter or owner

        if (_outcome == DisputeOutcome.CreatorWins) {
            creatorShare = totalHeld - _losingPenaltyAmount;
            penaltyShare = _losingPenaltyAmount;
        } else if (_outcome == DisputeOutcome.RecipientWins) {
            recipientShare = totalHeld - _losingPenaltyAmount;
             penaltyShare = _losingPenaltyAmount;
        } else if (_outcome == DisputeOutcome.Split) {
            require(_winningParty != address(0), "Winning party must be specified for Split");
            uint256 otherPartyShare = totalHeld - _winningAmount - _losingPenaltyAmount;
            penaltyShare = _losingPenaltyAmount;

            if (_winningParty == escrow.creator) {
                creatorShare = _winningAmount;
                recipientShare = otherPartyShare;
            } else if (_winningParty == escrow.recipient) {
                recipientShare = _winningAmount;
                creatorShare = otherPartyShare;
            } else {
                // Winning party is neither Creator nor Recipient? Invalid split.
                // Or maybe winningParty *is* the Arbiter receiving a fee?
                // Let's simplify: Split is always between Creator and Recipient. _winningParty indicates who gets the larger share.
                require(_winningParty == escrow.creator || _winningParty == escrow.recipient, "Winning party must be Creator or Recipient for Split");
                 // Recalculate shares based on _winningAmount only
                 if (_winningParty == escrow.creator) {
                     creatorShare = _winningAmount;
                     recipientShare = totalHeld > creatorShare ? totalHeld - creatorShare : 0;
                 } else { // winningParty is recipient
                     recipientShare = _winningAmount;
                     creatorShare = totalHeld > recipientShare ? totalHeld - recipientShare : 0;
                 }
                 // Total distributed should not exceed totalHeld. Penalty logic needs care.
                 // A common model: Penalty comes off the loser's share and goes to the winner or arbiter.
                 // Let's assume `_winningAmount` + `_losingPenaltyAmount` <= `totalHeld` is *intended distribution* from original total.
                 // Simplified: Winner gets `_winningAmount`. Loser gets `totalHeld - _winningAmount - _losingPenaltyAmount`. Penalty amount goes to Arbiter.
                 // This requires knowing who is the loser. The outcome "Split" and `_winningParty` implies the other is the loser.
                 address payable losingParty = (_winningParty == escrow.creator) ? escrow.recipient : escrow.creator;
                 creatorShare = (_winningParty == escrow.creator) ? _winningAmount : totalHeld - _winningAmount - _losingPenaltyAmount;
                 recipientShare = (_winningParty == escrow.recipient) ? _winningAmount : totalHeld - _winningAmount - _losingPenaltyAmount;
                 penaltyShare = _losingPenaltyAmount;
                 // Ensure total distributed doesn't exceed held
                 uint256 totalToDistribute = creatorShare + recipientShare + penaltyShare;
                 if (totalToDistribute > totalHeld) {
                      // Adjust shares proportionally or revert? Let's revert for clarity.
                      revert("Dispute distribution amounts exceed total held funds");
                 }
                 // If totalToDistribute < totalHeld, dust remains. Can be claimed later by Arbiter/Owner? Or sent back to creator?
                 // Let's send remainder to the contract owner for simplicity.
                 uint256 remainder = totalHeld - totalToDistribute;
                 if (remainder > 0) {
                      _transferFunds(payable(owner()), remainder, token, isERC20);
                 }
            }
        }

        // Distribute the calculated shares
        if (creatorShare > 0) {
            _transferFunds(escrow.creator, creatorShare, token, isERC20);
        }
        if (recipientShare > 0) {
            _transferFunds(escrow.recipient, recipientShare, token, isERC20);
        }
        if (penaltyShare > 0) {
            // Where does the penalty go? Let's send it to the Arbiter who recorded the outcome.
            _transferFunds(payable(msg.sender), penaltyShare, token, isERC20); // Penalty to arbiter/delegated recorder
        }


        escrow.state = EscrowState.Completed; // Dispute is resolved, escrow is completed
        escrow.lastUpdateTime = block.timestamp;
        emit EscrowStateChanged(_escrowId, EscrowState.Disputed, EscrowState.Completed);
        emit DisputeOutcomeRecorded(_escrowId, _outcome, _winningParty, _winningAmount, _losingPenaltyAmount);
    }

     // --- 11. State Management ---

     /**
      * @notice Pauses an active escrow. Requires Arbiter role or delegation.
      * @param _escrowId The ID of the escrow.
      * @param _reason A brief reason for pausing.
      */
     function pauseEscrow(uint256 _escrowId, string memory _reason)
        external
        onlyActiveOrPaused(_escrowId)
     {
         Escrow storage escrow = escrows[_escrowId];
         require(escrow.state != EscrowState.Paused, "Escrow is already paused");
         require(escrow.state != EscrowState.PendingFunding, "Cannot pause pending escrow"); // Pause only applies to active states

         // Only Arbiter or delegated can pause
         string memory actionKey = "pause:escrow";
         require(_hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter) || escrow.delegatedActions[msg.sender][actionKey] == msg.sender, "Not authorized to pause escrow");


         EscrowState oldState = escrow.state;
         escrow.state = EscrowState.Paused;
         escrow.lastUpdateTime = block.timestamp;
         emit EscrowStateChanged(_escrowId, oldState, EscrowState.Paused);
         emit EscrowPaused(_escrowId, msg.sender, _reason);
     }

     /**
      * @notice Unpauses a paused escrow. Requires Arbiter role or delegation.
      * @param _escrowId The ID of the escrow.
      */
     function unpauseEscrow(uint256 _escrowId)
        external
        onlyState(_escrowId, EscrowState.Paused)
     {
         Escrow storage escrow = escrows[_escrowId];

         // Only Arbiter or delegated can unpause
         string memory actionKey = "unpause:escrow";
         require(_hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter) || escrow.delegatedActions[msg.sender][actionKey] == msg.sender, "Not authorized to unpause escrow");

         // Restore state to Active after unpausing
         EscrowState oldState = escrow.state;
         escrow.state = EscrowState.Active;
         escrow.lastUpdateTime = block.timestamp;
         emit EscrowStateChanged(_escrowId, oldState, EscrowState.Active);
         emit EscrowUnpaused(_escrowId, msg.sender);
     }


    // --- 12. View Functions ---

    function getEscrowDetails(uint256 _escrowId)
        external
        view
        onlyEscrowParticipant(_escrowId) // Only participants can view details
        returns (
            address creator,
            address recipient,
            bool isERC20,
            address tokenAddress,
            uint256 totalAmount,
            uint256 releasedAmount,
            EscrowState state,
            uint256 creationTime,
            uint256 lastUpdateTime,
            uint256 milestoneCount,
            uint256 finalDeadline
        )
    {
        Escrow storage escrow = escrows[_escrowId];
        return (
            escrow.creator,
            escrow.recipient,
            escrow.isERC20,
            escrow.tokenAddress,
            escrow.totalAmount,
            escrow.releasedAmount,
            escrow.state,
            escrow.creationTime,
            escrow.lastUpdateTime,
            escrow.milestones.length,
            escrow.finalDeadline
        );
    }

     function getMilestoneDetails(uint256 _escrowId, uint256 _milestoneIndex)
         external
         view
         onlyEscrowParticipant(_escrowId) // Only participants can view details
         returns (
             MilestoneType milestoneType,
             uint256 amount,
             uint256 releaseTime,
             bool isCompleted,
             address[] memory requiredConfirmers,
             bool isReleased
         )
     {
         Escrow storage escrow = escrows[_escrowId];
         require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
         Milestone storage milestone = escrow.milestones[_milestoneIndex];

         return (
             milestone.milestoneType,
             milestone.amount,
             milestone.releaseTime,
             milestone.isCompleted,
             milestone.requiredConfirmers,
             milestone.isReleased
         );
     }

     function getParticipantRole(uint256 _escrowId, address _participant) external view returns (ParticipantRole) {
         require(escrows[_escrowId].creator != address(0), "Escrow does not exist"); // Basic check
         return escrows[_escrowId].participants[_participant];
     }

    /**
     * @notice Gets the address an action right has been delegated to by a specific delegator.
     * @param _escrowId The ID of the escrow.
     * @param _delegator The address that potentially delegated the right.
     * @param _actionKey The string identifier for the action.
     * @return The address of the delegatee, or address(0) if not delegated by this delegator.
     */
     function getActionDelegate(uint256 _escrowId, address _delegator, string memory _actionKey) external view returns (address) {
        require(escrows[_escrowId].creator != address(0), "Escrow does not exist"); // Basic check
        // Only the delegator themselves, or perhaps an Arbiter/Owner should see this?
        // For simplicity, make it public view, but in a real app, restrict viewing delegation info.
        // Adding an access control check: onlyEscrowParticipant(_escrowId) || msg.sender == owner()
        // Let's keep it simple public view for now.
        return escrows[_escrowId].delegatedActions[_delegator][_actionKey];
     }


     function getEscrowState(uint256 _escrowId) external view returns (EscrowState) {
         require(escrows[_escrowId].creator != address(0), "Escrow does not exist"); // Basic check
         return escrows[_escrowId].state;
     }

     function getTotalReleased(uint256 _escrowId) external view returns (uint256) {
         require(escrows[_escrowId].creator != address(0), "Escrow does not exist"); // Basic check
         return escrows[_escrowId].releasedAmount;
     }

     function getRemainingAmount(uint256 _escrowId) external view returns (uint256) {
        require(escrows[_escrowId].creator != address(0), "Escrow does not exist"); // Basic check
        Escrow storage escrow = escrows[_escrowId];
        if (escrow.isERC20) {
            return erc20EscrowBalances[_escrowId];
        } else {
            return ethEscrowBalances[_escrowId];
        }
     }

    function isApprovedToken(address _token) external view onlyOwner returns (bool) {
        // Making this onlyOwner prevents just anyone from seeing the approved list directly,
        // but it could be public depending on desired transparency.
        return approvedTokens[_token];
    }

    // --- 13. Fallback/Receive ---
    receive() external payable {
        // This allows sending ETH to the contract address.
        // Ideally, ETH funding should happen via `fundEscrowETH` with an ID.
        // Unaccompanied ETH sends could be problematic.
        // We'll allow it but recommend using `fundEscrowETH`.
        // It's impossible to know which escrow this ETH is for without the ID.
        // A robust contract might reject bare ETH sends or require a specific data payload.
        // For this example, it's here but not the recommended way to fund.
        // It's safer to require funding via a function with an ID.
        // Removing the receive() allows only funding via fundEscrowETH.
        // Let's remove it to enforce funded via function call.
    }

     // Need String conversion for actionKey in confirmMilestoneCompletion
     // Import openzeppelin Strings library
}

// Need String conversion for actionKey in confirmMilestoneCompletion
// Import openzeppelin Strings library
// pragma solidity ^0.8.20; // Already declared
// import "@openzeppelin/contracts/utils/Strings.sol"; // Add this import

// Re-adding the Strings import and fallback after the main contract code block for clarity based on initial outline.
// In a single file, it would be at the top.

// @openzeppelin/contracts/utils/Strings.sol needs to be imported for Strings.toString()
// Add `import "@openzeppelin/contracts/utils/Strings.sol";` at the top.
```

**Explanation of Advanced Concepts:**

1.  **Multi-Party & Roles:** The contract explicitly defines and manages different participant roles (`Creator`, `Recipient`, `Verifier`, `Arbiter`, `Watcher`) beyond a simple sender/receiver setup. Access to functions is controlled by these roles.
2.  **Hybrid Milestones:** Release of funds is not just time-based (vesting) but can also be event-based, requiring confirmation from designated participants (e.g., a `Verifier` confirming work completion). This allows for complex conditional releases.
3.  **Dynamic Conditions/Penalties (Abstract):** The `_calculateDynamicPenalty` function is included as a placeholder for logic that could dynamically determine penalties based on time delays past deadlines or other factors. While the example implementation is simple (percentage based on delay), the structure allows for sophisticated penalty curves or external data feeds (via oracles, though not fully implemented here) to influence outcomes. The penalty is applied during cancellation or dispute resolution, not necessarily on milestone release itself.
4.  **Internal Role Delegation:** Participants with specific roles can delegate their right to perform certain actions (like confirming a milestone or initiating a dispute) to another address *specifically for that escrow*. This allows for flexible management and temporary transfer of responsibilities without changing the core participant's role.
5.  **Flexible State Transitions & Dispute Resolution:** The contract includes multiple states (`PendingFunding`, `Active`, `Paused`, `Disputed`, `Completed`, `Cancelled`) and defined transitions between them. A basic `Disputed` state and `recordDisputeOutcome` function are included, representing the integration point for an off-chain dispute resolution process (like arbitration or a DAO) to dictate the final fund distribution.
6.  **Atomic Operations:** Uses `ReentrancyGuard` and the `call` method for ETH transfers (though `transfer` is often preferred for safety) and standard ERC20 `transferFrom`/`transfer` to minimize reentrancy risks during fund movements.
7.  **Configurable ERC20:** Allows the owner to whitelist approved ERC20 tokens, preventing arbitrary tokens from being used in escrows.

This contract provides a framework for much more sophisticated escrow agreements than typical examples, incorporating multiple dimensions of control, conditionality, and participant interaction. Remember that complex smart contracts require rigorous testing and auditing before deployment.```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString in action keys

/**
 * @title ChronoEscrow
 * @notice A complex, multi-party escrow contract with time-based, event-based,
 *         and dynamic conditions for value release.
 *
 * Outline:
 * 1. State Variables & Constants
 * 2. Enums for State, Milestone Types, Roles, Dispute Outcomes
 * 3. Structs for Milestones and the main Escrow agreement
 * 4. Events to track key actions
 * 5. Modifiers for access control
 * 6. Internal helper functions
 * 7. Admin Functions
 * 8. Core Escrow Lifecycle Functions (Creation, Funding, Milestone Management, Release, Cancellation)
 * 9. Participant Management Functions (Roles, Delegation)
 * 10. Dispute Resolution Functions
 * 11. State Management Functions (Pause/Unpause)
 * 12. View Functions
 *
 * Function Summary:
 * - Admin Functions:
 *   - addApprovedToken(ERC20 token): Allows the owner to whitelist ERC20 tokens for escrow.
 *   - removeApprovedToken(ERC20 token): Allows the owner to remove whitelisted ERC20 tokens.
 *   - transferOwnership(address newOwner): Transfers ownership/admin rights (from Ownable).
 *
 * - Core Escrow Lifecycle:
 *   - createEscrow(params...): Initializes a new escrow agreement. Defines participants, total amount, token, and initial milestones.
 *   - fundEscrowETH(uint256 escrowId): Sends ETH to fund an existing ETH-based escrow.
 *   - fundEscrowERC20(uint256 escrowId, uint256 amount): Transfers ERC20 tokens to fund an existing ERC20-based escrow (requires prior approval).
 *   - addMilestone(uint256 escrowId, params...): Adds a new milestone to an existing, non-active escrow (simplified state).
 *   - updateMilestone(uint256 escrowId, uint256 milestoneIndex, params...): Modifies details of a future milestone (simplified state).
 *   - removeMilestone(uint256 escrowId, uint256 milestoneIndex): Removes a future milestone (simplified state).
 *   - confirmMilestoneCompletion(uint256 escrowId, uint256 milestoneIndex): Marks an event-based milestone as completed (requires specific role/delegation).
 *   - requestMilestoneRelease(uint256 escrowId, uint256 milestoneIndex): Initiates the release of funds for a specific milestone if conditions (time OR confirmation) are met.
 *   - claimRemainingFunds(uint256 escrowId): Allows participants to claim any remaining funds after all primary distributions (e.g., dust).
 *   - cancelEscrow(uint256 escrowId, string reason): Authorized participants can initiate cancellation, potentially triggering penalties/returns.
 *   - forceCancelExpiredEscrow(uint256 escrowId): Allows anyone to force cancel an escrow stuck past its final deadline, applying penalties.
 *
 * - Participant Management:
 *   - addParticipant(uint256 escrowId, address participant, ParticipantRole role): Adds a new participant to an escrow.
 *   - removeParticipant(uint256 escrowId, address participant): Removes a participant from an escrow.
 *   - setParticipantRole(uint256 escrowId, address participant, ParticipantRole role): Changes the role of an existing participant.
 *   - delegateActionRight(uint256 escrowId, address delegatee, string actionKey): Delegates a specific action right to another address.
 *   - revokeActionRight(uint256 escrowId, string actionKey): Revokes a previously delegated action right.
 *
 * - Dispute Resolution:
 *   - initiateDispute(uint256 escrowId, string reason): Changes the escrow state to Disputed (requires specific role).
 *   - recordDisputeOutcome(uint256 escrowId, DisputeOutcome outcome, address winningParty, uint256 winningAmount, uint256 losingPenaltyAmount): Records the outcome of an off-chain dispute and distributes funds (requires specific role/delegation).
 *
 * - State Management:
 *   - pauseEscrow(uint256 escrowId, string reason): Temporarily pauses an active escrow (requires specific role/delegation).
 *   - unpauseEscrow(uint256 escrowId): Resumes a paused escrow (requires specific role/delegation).
 *
 * - View Functions:
 *   - getEscrowDetails(uint256 escrowId): Returns high-level details of an escrow.
 *   - getMilestoneDetails(uint256 escrowId, uint256 milestoneIndex): Returns details of a specific milestone.
 *   - getParticipantRole(uint256 escrowId, address participant): Returns the role of a participant in an escrow.
 *   - getActionDelegate(uint256 escrowId, address delegator, string actionKey): Returns the delegatee for a specific action key by a delegator.
 *   - getEscrowState(uint256 escrowId): Returns the current state of an escrow.
 *   - getTotalReleased(uint256 escrowId): Returns the total amount of funds released for an escrow.
 *   - getRemainingAmount(uint256 escrowId): Returns the amount of funds still held in escrow.
 *   - isApprovedToken(address token): Checks if an ERC20 token is approved for use.
 */
contract ChronoEscrow is Ownable, ReentrancyGuard {

    // --- 1. State Variables & Constants ---
    uint256 private nextEscrowId = 1;
    mapping(uint256 => Escrow) public escrows;

    // Track balances per escrow (needed because contract holds multiple escrows' funds)
    mapping(uint256 => uint256) private ethEscrowBalances;
    mapping(uint256 => uint256) private erc20EscrowBalances;

    mapping(address => bool) private approvedTokens; // ERC20 tokens allowed for escrow

    // --- 2. Enums ---
    enum EscrowState {
        PendingFunding,   // Created, waiting for funds
        Active,           // Funded and running
        Paused,           // Temporarily halted
        Disputed,         // In dispute resolution
        Completed,        // All milestones processed, funds distributed
        Cancelled         // Cancelled prematurely
    }

    enum MilestoneType {
        TimeBased,        // Released after a specific timestamp
        EventBased        // Released after a specific event is confirmed by required parties
    }

    enum ParticipantRole {
        None,             // No role assigned for this escrow
        Creator,          // Initiator of the escrow
        Recipient,        // Primary receiver of funds
        Verifier,         // Role to confirm event-based milestones
        Arbiter,          // Role to handle disputes
        Watcher           // Can view details but not interact
    }

    enum DisputeOutcome {
        Undecided,
        CreatorWins,
        RecipientWins,
        Split
    }

    // --- 3. Structs ---
    struct Milestone {
        MilestoneType milestoneType; // Type of milestone
        uint256 amount;             // Amount to be released at this milestone
        uint256 releaseTime;        // For TimeBased: Timestamp when funds become available
        bool isCompleted;           // For EventBased: Whether the event has been confirmed
        address[] requiredConfirmers; // For EventBased: Addresses required to confirm
        mapping(address => bool) confirmations; // For EventBased: Tracks confirmations
        bool isReleased;            // Whether this milestone's funds have been released
    }

    struct Escrow {
        address payable creator;       // The initiator (often sender)
        address payable recipient;     // The primary receiver
        bool isERC20;                  // True if using ERC20, false for ETH
        address tokenAddress;          // Address of the ERC20 token (address(0) for ETH)
        uint256 totalAmount;           // Total amount locked in escrow
        uint256 releasedAmount;        // Total amount released across all milestones
        EscrowState state;             // Current state of the escrow
        uint256 creationTime;          // Timestamp when escrow was created
        uint256 lastUpdateTime;        // Timestamp of last state change or significant update
        Milestone[] milestones;        // List of milestones for this escrow
        mapping(address => ParticipantRole) participants; // Roles assigned to addresses for this escrow
        mapping(address => mapping(string => address)) delegatedActions; // delegator => actionKey => delegatee
        DisputeOutcome disputeOutcome; // Outcome if in dispute
        address payable winningParty;   // Party designated to receive funds if Split/resolved
        uint256 winningAmount;        // Amount allocated to winningParty in case of Split
        uint256 losingPenaltyAmount;  // Amount designated as penalty from losing party's share
        uint256 finalDeadline;        // Overall deadline for the escrow process
    }

    // --- 4. Events ---
    event EscrowCreated(uint256 indexed escrowId, address indexed creator, address indexed recipient, bool isERC20, address tokenAddress, uint256 totalAmount, uint256 finalDeadline);
    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    event MilestoneAdded(uint256 indexed escrowId, uint256 indexed milestoneIndex, MilestoneType milestoneType, uint256 amount, uint256 releaseTime);
    event MilestoneUpdated(uint256 indexed escrowId, uint256 indexed milestoneIndex, MilestoneType milestoneType, uint256 amount, uint256 releaseTime);
    event MilestoneRemoved(uint256 indexed escrowId, uint256 indexed milestoneIndex);
    event MilestoneCompleted(uint256 indexed escrowId, uint256 indexed milestoneIndex, address indexed confirmer);
    event MilestoneReleased(uint256 indexed escrowId, uint256 indexed milestoneIndex, uint256 amount);
    event FundsClaimed(uint256 indexed escrowId, address indexed claimant, uint256 amount);
    event EscrowStateChanged(uint256 indexed escrowId, EscrowState oldState, EscrowState newState);
    event ParticipantAdded(uint256 indexed escrowId, address indexed participant, ParticipantRole role);
    event ParticipantRemoved(uint256 indexed escrowId, address indexed participant);
    event ParticipantRoleUpdated(uint256 indexed escrowId, address indexed participant, ParticipantRole oldRole, ParticipantRole newRole);
    event ActionDelegated(uint256 indexed escrowId, address indexed delegator, address indexed delegatee, string actionKey);
    event ActionRevoked(uint256 indexed escrowId, address indexed delegator, string actionKey);
    event DisputeInitiated(uint256 indexed escrowId, address indexed initiator, string reason);
    event DisputeOutcomeRecorded(uint256 indexed escrowId, DisputeOutcome outcome, address winningParty, uint256 winningAmount, uint256 losingPenaltyAmount);
    event EscrowCancelled(uint256 indexed escrowId, address indexed initiator, string reason);
    event EscrowPaused(uint256 indexed escrowId, address indexed initiator, string reason);
    event EscrowUnpaused(uint256 indexed escrowId, address indexed initiator);
    event TokenApproved(address indexed token);
    event TokenRemoved(address indexed token);
     // Add event for penalty distribution? E.g., EventPenaltyDistributed(uint256 indexed escrowId, uint256 amount, address indexed recipient);


    // --- 5. Modifiers ---
    modifier onlyEscrowParticipant(uint256 _escrowId) {
        require(_isParticipant(_escrowId, msg.sender), "Not an escrow participant");
        _;
    }

    modifier onlyEscrowRole(uint256 _escrowId, ParticipantRole _requiredRole) {
        require(_hasRole(_escrowId, msg.sender, _requiredRole), "Insufficient escrow role");
        _;
    }

    modifier onlyEscrowRoleOrDelegate(uint256 _escrowId, ParticipantRole _requiredRole, string memory _actionKey) {
        Escrow storage escrow = escrows[_escrowId];
        // Check if msg.sender has the required role OR if they are the delegatee for the action key
        require(_hasRole(_escrowId, msg.sender, _requiredRole) || escrow.delegatedActions[msg.sender][_actionKey] == msg.sender, "Insufficient role or delegation");
        _;
    }

    modifier onlyState(uint256 _escrowId, EscrowState _requiredState) {
        require(escrows[_escrowId].state == _requiredState, "Escrow not in required state");
        _;
    }

    modifier notState(uint256 _escrowId, EscrowState _forbiddenState) {
        require(escrows[_escrowId].state != _forbiddenState, "Escrow in forbidden state");
        _;
    }

    modifier onlyActiveOrPaused(uint256 _escrowId) {
        require(escrows[_escrowId].state == EscrowState.Active || escrows[_escrowId].state == EscrowState.Paused, "Escrow not active or paused");
        _;
    }

    // --- 6. Internal Helper Functions ---
    function _isParticipant(uint256 _escrowId, address _addr) internal view returns (bool) {
        Escrow storage escrow = escrows[_escrowId];
        return escrow.participants[_addr] != ParticipantRole.None;
    }

    function _hasRole(uint256 _escrowId, address _addr, ParticipantRole _role) internal view returns (bool) {
        Escrow storage escrow = escrows[_escrowId];
        return escrow.participants[_addr] == _role;
    }

     function _calculateDynamicPenalty(uint256 _escrowId, uint256 _delayDuration) internal view returns (uint256 penaltyAmount) {
        // Simple example penalty: 0.1% of total amount per day of delay past deadline, capped at 100%
        // In a real scenario, this could be based on remaining amount, milestone importance, etc.
        Escrow storage escrow = escrows[_escrowId];
        uint256 total = escrow.totalAmount;
        uint256 delayDays = _delayDuration / 1 days;

        if (delayDays == 0) return 0;

        // Penalty rate: 10 basis points (0.1%) per day
        uint256 penaltyRateBasisPoints = delayDays * 10;
        if (penaltyRateBasisPoints > 10000) penaltyRateBasisPoints = 10000; // Cap at 100%

        penaltyAmount = (total * penaltyRateBasisPoints) / 10000;
        return penaltyAmount;
    }

    function _transferFunds(address payable _to, uint256 _amount, address _tokenAddress, bool _isERC20) internal nonReentrant {
        if (_amount == 0) return;

        if (_isERC20) {
            IERC20 token = IERC20(_tokenAddress);
            // Assuming contract has sufficient balance from funding
            require(token.transfer(_to, _amount), "Token transfer failed");
        } else {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "ETH transfer failed");
        }
    }

    // --- 7. Admin Functions ---
    function addApprovedToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address not allowed");
        approvedTokens[_token] = true;
        emit TokenApproved(_token);
    }

    function removeApprovedToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address not allowed");
        approvedTokens[_token] = false;
        emit TokenRemoved(_token);
    }

    // Ownable provides transferOwnership(address newOwner)

    // --- 8. Core Escrow Lifecycle Functions ---

    /**
     * @notice Creates a new escrow agreement. Defines participants, total amount, token, and initial milestones.
     *         Funds are added separately after creation.
     * @param _recipient The primary recipient of the funds.
     * @param _isERC20 True if using ERC20, false for ETH.
     * @param _tokenAddress The ERC20 token address (address(0) for ETH).
     * @param _totalAmount The total amount of funds for the escrow.
     * @param _finalDeadline The final timestamp by which the escrow should ideally be completed or cancelled.
     * @param _initialMilestones Array of initial milestone definitions.
     * @param _additionalParticipants Array of additional participant addresses.
     * @param _additionalRoles Array of roles corresponding to additional participants.
     */
    function createEscrow(
        address payable _recipient,
        bool _isERC20,
        address _tokenAddress,
        uint256 _totalAmount,
        uint256 _finalDeadline,
        Milestone[] calldata _initialMilestones, // Use calldata for external calls
        address[] calldata _additionalParticipants,
        ParticipantRole[] calldata _additionalRoles
    ) external returns (uint256 escrowId) {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_totalAmount > 0, "Total amount must be positive");
        require(_finalDeadline > block.timestamp, "Final deadline must be in the future");
        require(_initialMilestones.length > 0, "Must include at least one milestone");
        require(_additionalParticipants.length == _additionalRoles.length, "Participant/Role array mismatch");
        require(msg.sender != _recipient, "Creator and recipient cannot be the same");

        if (_isERC20) {
            require(_tokenAddress != address(0), "ERC20 token address required");
            require(approvedTokens[_tokenAddress], "ERC20 token not approved");
        } else {
            require(_tokenAddress == address(0), "ETH escrow does not need token address");
        }
        require(msg.value == 0, "Funds must be added via fundEscrow functions");


        escrowId = nextEscrowId++;

        Escrow storage newEscrow = escrows[escrowId];
        newEscrow.creator = payable(msg.sender);
        newEscrow.recipient = _recipient;
        newEscrow.isERC20 = _isERC20;
        newEscrow.tokenAddress = _tokenAddress;
        newEscrow.totalAmount = _totalAmount;
        newEscrow.releasedAmount = 0;
        newEscrow.state = EscrowState.PendingFunding;
        newEscrow.creationTime = block.timestamp;
        newEscrow.lastUpdateTime = block.timestamp;
        newEscrow.finalDeadline = _finalDeadline;

        // Add initial participants
        newEscrow.participants[msg.sender] = ParticipantRole.Creator;
        newEscrow.participants[_recipient] = ParticipantRole.Recipient;

        for (uint i = 0; i < _additionalParticipants.length; i++) {
             address participant = _additionalParticipants[i];
             ParticipantRole role = _additionalRoles[i];
             require(participant != address(0), "Additional participant cannot be zero address");
             require(role != ParticipantRole.None, "Additional participant must have a role");
             require(newEscrow.participants[participant] == ParticipantRole.None, "Participant already has a default role"); // Avoid overwriting Creator/Recipient
             newEscrow.participants[participant] = role;
             emit ParticipantAdded(escrowId, participant, role);
        }

        // Add initial milestones
        uint256 totalMilestoneAmount = 0;
        for (uint i = 0; i < _initialMilestones.length; i++) {
            Milestone calldata currentMilestone = _initialMilestones[i];
            if (currentMilestone.milestoneType == MilestoneType.TimeBased) {
                 require(currentMilestone.releaseTime > block.timestamp, "Milestone time must be in the future");
                 require(currentMilestone.requiredConfirmers.length == 0, "Time-based milestones cannot have confirmers");
            } else { // EventBased
                 require(currentMilestone.releaseTime == 0, "Event-based milestones do not use releaseTime");
                 require(currentMilestone.requiredConfirmers.length > 0, "Event-based milestones require at least one confirmer");
                 for(uint j=0; j < currentMilestone.requiredConfirmers.length; j++) {
                     require(newEscrow.participants[currentMilestone.requiredConfirmers[j]] != ParticipantRole.None, "Confirmer must be an escrow participant");
                 }
            }
            require(currentMilestone.amount > 0, "Milestone amount must be positive");

            newEscrow.milestones.push(Milestone({
                milestoneType: currentMilestone.milestoneType,
                amount: currentMilestone.amount,
                releaseTime: currentMilestone.releaseTime,
                isCompleted: false,
                requiredConfirmers: currentMilestone.requiredConfirmers, // Copy addresses
                isReleased: false
            }));
            // Note: confirmations mapping is implicitly initialized empty
            totalMilestoneAmount += currentMilestone.amount;
            emit MilestoneAdded(escrowId, newEscrow.milestones.length - 1, currentMilestone.milestoneType, currentMilestone.amount, currentMilestone.releaseTime);
        }
         require(totalMilestoneAmount <= _totalAmount, "Sum of milestone amounts exceeds total escrow amount");
         // Leftover amount can be claimed at the end by recipient or handled in dispute/cancellation.

        emit EscrowCreated(escrowId, msg.sender, _recipient, _isERC20, _tokenAddress, _totalAmount, _finalDeadline);
    }

    /**
     * @notice Funds an existing ETH-based escrow. Can be called by anyone.
     * @param _escrowId The ID of the escrow to fund.
     */
    function fundEscrowETH(uint256 _escrowId) external payable onlyState(_escrowId, EscrowState.PendingFunding) {
        Escrow storage escrow = escrows[_escrowId];
        require(!escrow.isERC20, "Escrow is ERC20 based");
        require(msg.value > 0, "Must send non-zero ETH");

        uint256 currentBalance = ethEscrowBalances[_escrowId];
        uint256 needed = escrow.totalAmount - currentBalance;

        require(msg.value <= needed, "Funding amount exceeds needed amount");

        ethEscrowBalances[_escrowId] += msg.value;

        if (ethEscrowBalances[_escrowId] >= escrow.totalAmount) {
            escrow.state = EscrowState.Active;
            escrow.lastUpdateTime = block.timestamp;
            emit EscrowStateChanged(_escrowId, EscrowState.PendingFunding, EscrowState.Active);
        }

        emit EscrowFunded(_escrowId, msg.value);
    }

    /**
     * @notice Funds an existing ERC20-based escrow. Requires prior approval. Called by the funder.
     * @param _escrowId The ID of the escrow to fund.
     * @param _amount The amount of ERC20 tokens to transfer.
     */
    function fundEscrowERC20(uint256 _escrowId, uint256 _amount) external onlyState(_escrowId, EscrowState.PendingFunding) {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.isERC20, "Escrow is ETH based");
        require(_amount > 0, "Amount must be positive");

        IERC20 token = IERC20(escrow.tokenAddress);

        uint256 currentBalance = erc20EscrowBalances[_escrowId];
        require(currentBalance + _amount <= escrow.totalAmount, "Funding amount exceeds total amount needed");

        // Transfer tokens from the caller (who must have approved this contract)
        require(token.transferFrom(msg.sender, address(this), _amount), "ERC20 transferFrom failed");

        erc20EscrowBalances[_escrowId] += _amount;

        if (erc20EscrowBalances[_escrowId] >= escrow.totalAmount) {
            escrow.state = EscrowState.Active;
            escrow.lastUpdateTime = block.timestamp;
            emit EscrowStateChanged(_escrowId, EscrowState.PendingFunding, EscrowState.Active);
        }

        emit EscrowFunded(_escrowId, _amount);
    }

    /**
     * @notice Adds a new milestone to an escrow. Simplified to allow only in PendingFunding state.
     * @param _escrowId The ID of the escrow.
     * @param _milestone The milestone details to add.
     */
    function addMilestone(uint256 _escrowId, Milestone calldata _milestone)
        external
        onlyEscrowParticipant(_escrowId)
        onlyState(_escrowId, EscrowState.PendingFunding) // Simplified: only before funding
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_hasRole(_escrowId, msg.sender, ParticipantRole.Creator), "Only Creator can add milestones before funding"); // Example restriction


        if (_milestone.milestoneType == MilestoneType.TimeBased) {
             require(_milestone.releaseTime > block.timestamp, "Milestone time must be in the future");
             require(_milestone.requiredConfirmers.length == 0, "Time-based milestones cannot have confirmers");
        } else { // EventBased
             require(_milestone.releaseTime == 0, "Event-based milestones do not use releaseTime");
             require(_milestone.requiredConfirmers.length > 0, "Event-based milestones require at least one confirmer");
             for(uint j=0; j < _milestone.requiredConfirmers.length; j++) {
                 require(escrow.participants[_milestone.requiredConfirmers[j]] != ParticipantRole.None, "Confirmer must be an escrow participant");
             }
        }
         require(_milestone.amount > 0, "Milestone amount must be positive");
        // Ensure total milestone amounts don't exceed total escrow amount after adding
        uint256 currentMilestoneSum = 0;
        for(uint i=0; i<escrow.milestones.length; i++) {
            currentMilestoneSum += escrow.milestones[i].amount;
        }
        require(currentMilestoneSum + _milestone.amount <= escrow.totalAmount, "Adding milestone exceeds total escrow amount");

        escrow.milestones.push(Milestone({
            milestoneType: _milestone.milestoneType,
            amount: _milestone.amount,
            releaseTime: _milestone.releaseTime,
            isCompleted: false,
            requiredConfirmers: _milestone.requiredConfirmers, // Copy addresses
            isReleased: false
        }));
        // confirmations mapping is implicitly initialized empty
        emit MilestoneAdded(_escrowId, escrow.milestones.length - 1, _milestone.milestoneType, _milestone.amount, _milestone.releaseTime);
    }

    /**
     * @notice Updates a future milestone in an escrow. Simplified to allow only in PendingFunding state.
     * @param _escrowId The ID of the escrow.
     * @param _milestoneIndex The index of the milestone to update.
     * @param _milestone The updated milestone details.
     */
     function updateMilestone(uint256 _escrowId, uint256 _milestoneIndex, Milestone calldata _milestone)
        external
        onlyEscrowParticipant(_escrowId)
        onlyState(_escrowId, EscrowState.PendingFunding) // Simplified: only before funding
     {
        Escrow storage escrow = escrows[_escrowId];
        require(_hasRole(_escrowId, msg.sender, ParticipantRole.Creator), "Only Creator can update milestones before funding"); // Example restriction
        require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
        require(!escrow.milestones[_milestoneIndex].isReleased, "Cannot update a released milestone");

        // Check if over/under total amount
        uint256 currentMilestoneSum = 0;
        for(uint i=0; i<escrow.milestones.length; i++) {
            if (i != _milestoneIndex) {
                currentMilestoneSum += escrow.milestones[i].amount;
            }
        }
        require(currentMilestoneSum + _milestone.amount <= escrow.totalAmount, "Updating milestone exceeds total escrow amount");
        require(_milestone.amount > 0, "Milestone amount must be positive");


        if (_milestone.milestoneType == MilestoneType.TimeBased) {
             require(_milestone.releaseTime > block.timestamp, "Milestone time must be in the future");
             require(_milestone.requiredConfirmers.length == 0, "Time-based milestones cannot have confirmers");
        } else { // EventBased
             require(_milestone.releaseTime == 0, "Event-based milestones do not use releaseTime");
             require(_milestone.requiredConfirmers.length > 0, "Event-based milestones require at least one confirmer");
             for(uint j=0; j < _milestone.requiredConfirmers.length; j++) {
                 require(escrow.participants[_milestone.requiredConfirmers[j]] != ParticipantRole.None, "Confirmer must be an escrow participant");
             }
             // If it was EventBased and confirmers are changing, assume no confirmations were made yet.
             if (escrow.milestones[_milestoneIndex].milestoneType == MilestoneType.EventBased && !_compareAddresses(escrow.milestones[_milestoneIndex].requiredConfirmers, _milestone.requiredConfirmers)) {
                 // Note: Clearing confirmations mapping is not straightforward. A proper implementation
                 // would handle this by re-initializing the milestone struct or tracking confirmations differently.
                 // For simplicity, we assume updates happen before any confirmation activity.
                  escrow.milestones[_milestoneIndex].isCompleted = false; // Reset completion status
             }
        }

        escrow.milestones[_milestoneIndex].milestoneType = _milestone.milestoneType;
        escrow.milestones[_milestoneIndex].amount = _milestone.amount;
        escrow.milestones[_milestoneIndex].releaseTime = _milestone.releaseTime;
        escrow.milestones[_milestoneIndex].requiredConfirmers = _milestone.requiredConfirmers; // Overwrites previous array


        emit MilestoneUpdated(_escrowId, _milestoneIndex, _milestone.milestoneType, _milestone.amount, _milestone.releaseTime);
     }

     // Helper for updateMilestone confirmer comparison
     function _compareAddresses(address[] storage a, address[] memory b) internal pure returns (bool) {
        if (a.length != b.length) return false;
        // Simple element-wise comparison assuming consistent order.
        // For order-independent comparison, sort or use a set-like approach (more complex).
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
     }


    /**
     * @notice Removes a future milestone from an escrow. Simplified to allow only in PendingFunding state.
     * @param _escrowId The ID of the escrow.
     * @param _milestoneIndex The index of the milestone to remove.
     */
    function removeMilestone(uint256 _escrowId, uint256 _milestoneIndex)
        external
        onlyEscrowParticipant(_escrowId)
        onlyState(_escrowId, EscrowState.PendingFunding) // Simplified: only before funding
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_hasRole(_escrowId, msg.sender, ParticipantRole.Creator), "Only Creator can remove milestones before funding"); // Example restriction
        require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
        require(!escrow.milestones[_milestoneIndex].isReleased, "Cannot remove a released milestone");
         // Cannot remove if it's the only milestone
        require(escrow.milestones.length > 1, "Cannot remove the only milestone");


        // Shift elements after the removed one
        for (uint i = _milestoneIndex; i < escrow.milestones.length - 1; i++) {
            escrow.milestones[i] = escrow.milestones[i + 1];
            // Mappings (like confirmations) are NOT copied. This assumes remove happens before any confirmation activity.
        }
        // Remove the last element (which is a duplicate of the second to last now)
        escrow.milestones.pop();

        emit MilestoneRemoved(_escrowId, _milestoneIndex);
    }

    /**
     * @notice Marks an event-based milestone as completed. Requires being a required confirmer or having delegation.
     * @param _escrowId The ID of the escrow.
     * @param _milestoneIndex The index of the milestone to confirm.
     */
    function confirmMilestoneCompletion(uint256 _escrowId, uint256 _milestoneIndex)
        external
        onlyActiveOrPaused(_escrowId)
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
        Milestone storage milestone = escrow.milestones[_milestoneIndex];

        require(milestone.milestoneType == MilestoneType.EventBased, "Milestone is not event-based");
        require(!milestone.isCompleted, "Milestone already completed");
        require(!milestone.isReleased, "Milestone already released");

        // Check if msg.sender is a required confirmer OR is delegated the right by a required confirmer
        bool isRequiredConfirmer = false;
        address requiredConfirmerAddress = address(0); // To find which confirmer the sender might be
        for(uint i=0; i < milestone.requiredConfirmers.length; i++) {
            if(milestone.requiredConfirmers[i] == msg.sender) {
                isRequiredConfirmer = true;
                requiredConfirmerAddress = msg.sender;
                break;
            }
        }

        bool isDelegatedConfirmer = false;
        string memory actionKey = string.concat("confirm:milestone:", Strings.toString(_milestoneIndex));
        // Check if msg.sender is delegated by *any* required confirmer
         for(uint i=0; i < milestone.requiredConfirmers.length; i++) {
             if(escrow.delegatedActions[milestone.requiredConfirmers[i]][actionKey] == msg.sender) {
                 isDelegatedConfirmer = true;
                 requiredConfirmerAddress = milestone.requiredConfirmers[i]; // The actual confirmer who delegated
                 break;
             }
         }

        require(isRequiredConfirmer || isDelegatedConfirmer, "Not authorized to confirm this milestone");

        // Record confirmation using the *original confirmer's* address, not the delegatee's
        milestone.confirmations[requiredConfirmerAddress] = true;

        // Check if all required confirmers have confirmed
        bool allConfirmed = true;
        for(uint i=0; i < milestone.requiredConfirmers.length; i++) {
            if(!milestone.confirmations[milestone.requiredConfirmers[i]]) {
                allConfirmed = false;
                break;
            }
        }

        if(allConfirmed) {
            milestone.isCompleted = true;
            emit MilestoneCompleted(_escrowId, _milestoneIndex, msg.sender); // Emit msg.sender who triggered it
            // Funds are released via requestMilestoneRelease, not automatically here
        }
    }

    /**
     * @notice Requests the release of funds for a specific milestone. Anyone can call, but release only happens if conditions met.
     * @param _escrowId The ID of the escrow.
     * @param _milestoneIndex The index of the milestone to request release for.
     */
    function requestMilestoneRelease(uint256 _escrowId, uint256 _milestoneIndex)
        external
        nonReentrant
        onlyActiveOrPaused(_escrowId)
    {
        Escrow storage escrow = escrows[_escrowId];
        require(_milestoneIndex < escrow.milestones.length, "Invalid milestone index");
        Milestone storage milestone = escrow.milestones[_milestoneIndex];

        require(!milestone.isReleased, "Milestone already released");
        require(escrow.releasedAmount < escrow.totalAmount, "All funds already released or claimed");

        bool conditionsMet = false;
        if (milestone.milestoneType == MilestoneType.TimeBased) {
            conditionsMet = block.timestamp >= milestone.releaseTime;
        } else { // EventBased
            conditionsMet = milestone.isCompleted;
        }

        require(conditionsMet, "Milestone conditions not met");

        uint256 amountToRelease = milestone.amount;

        // Ensure total released doesn't exceed total amount due to floating point or calculation errors elsewhere (safety)
        uint256 maxReleasePossible = escrow.totalAmount - escrow.releasedAmount;
        amountToRelease = amountToRelease > maxReleasePossible ? maxReleasePossible : amountToRelease;

        require(amountToRelease > 0, "Calculated amount to release is zero");

        milestone.isReleased = true;
        escrow.releasedAmount += amountToRelease;
        escrow.lastUpdateTime = block.timestamp;

        address payable recipient = escrow.recipient;
        address token = escrow.tokenAddress;
        bool isERC20 = escrow.isERC20;

        if (isERC20) {
            // Decrement the ERC20 balance tracked by the contract for this escrow
            require(erc20EscrowBalances[_escrowId] >= amountToRelease, "Insufficient ERC20 balance in escrow");
            erc20EscrowBalances[_escrowId] -= amountToRelease;
        } else {
             // Decrement the ETH balance tracked by the contract for this escrow
            require(ethEscrowBalances[_escrowId] >= amountToRelease, "Insufficient ETH balance in escrow");
            ethEscrowBalances[_escrowId] -= amountToRelease;
        }

        _transferFunds(recipient, amountToRelease, token, isERC20);

        emit MilestoneReleased(_escrowId, _milestoneIndex, amountToRelease);

        // Check if all milestones are released
        bool allMilestonesReleased = true;
        for(uint i=0; i < escrow.milestones.length; i++) {
            if(!escrow.milestones[i].isReleased) {
                allMilestonesReleased = false;
                break;
            }
        }

        // If all milestones released AND remaining balance is dust (or zero)
        uint256 remainingBalance = isERC20 ? erc20EscrowBalances[_escrowId] : ethEscrowBalances[_escrowId];
        if(allMilestonesReleased && remainingBalance < 1000) { // Define "dust" threshold
            escrow.state = EscrowState.Completed;
            escrow.lastUpdateTime = block.timestamp;
            emit EscrowStateChanged(_escrowId, escrow.state, EscrowState.Completed);
            // Remaining dust can be claimed by recipient via claimRemainingFunds
        }
    }

     /**
      * @notice Allows participants (Creator/Recipient/Arbiter) to claim any remaining non-distributed funds.
      *         Typically used after completion/cancellation/dispute resolution for dust or unallocated amounts.
      * @param _escrowId The ID of the escrow.
      */
     function claimRemainingFunds(uint256 _escrowId)
        external
        nonReentrant
        onlyEscrowParticipant(_escrowId)
        notState(_escrowId, EscrowState.PendingFunding) // Cannot claim before funding
        notState(_escrowId, EscrowState.Active)       // Cannot claim while active
        notState(_escrowId, EscrowState.Paused)       // Cannot claim while paused
        notState(_escrowId, EscrowState.Disputed)     // Cannot claim while disputed
     {
         Escrow storage escrow = escrows[_escrowId];

         // Only Creator, Recipient, or Arbiter can claim leftovers
         require(
             _hasRole(_escrowId, msg.sender, ParticipantRole.Creator) ||
             _hasRole(_escrowId, msg.sender, ParticipantRole.Recipient) ||
             _hasRole(_escrowId, msg.sender, ParticipantRole.Arbiter),
             "Not authorized to claim remaining funds"
         );

         uint256 remainingBalance;
         address tokenAddress = escrow.tokenAddress;
         bool isERC20 = escrow.isERC20;

         if (isERC20) {
             remainingBalance = erc20EscrowBalances[_escrowId];
             erc20EscrowBalances[_escrowId] = 0; // Clear balance map entry
         } else {
             remainingBalance = ethEscrowBalances[_escrowId];
             ethEscrowBalances[_escrow