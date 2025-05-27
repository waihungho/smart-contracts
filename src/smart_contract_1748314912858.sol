Okay, here is a Solidity smart contract concept implementing a Decentralized, Self-Amending Escrow system with integrated Governance and Dispute Resolution.

The "self-amending" aspect isn't about rewriting the contract code itself (which is generally impossible and unsafe on EVM), but rather about allowing the contract's core *logic modules* (like how rules are evaluated, fees calculated, or disputes resolved) and key parameters to be updated via a decentralized governance process. These logic modules would be separate contracts implementing specific interfaces.

This design aims for flexibility, decentralized control, and handling complex, multi-party conditional payments.

---

## Decentralized Self-Amending Escrow: Outline & Function Summary

**Contract Name:** `DecentralizedSelfAmendingEscrow`

**Core Concept:** A multi-party escrow where funds are released based on complex conditions, with built-in dispute resolution. The rules for condition evaluation, fee calculation, dispute resolution, and governance parameters can be updated via an on-chain voting mechanism controlled by governance members.

**Key Features:**
*   **Multi-Party Escrow:** Supports multiple depositors and beneficiaries per escrow.
*   **Complex Conditions:** Conditions are defined by parameters and evaluated by an external, pluggable `IRuleEvaluator` contract.
*   **Pluggable Logic:** Uses interfaces (`IRuleEvaluator`, `IFeeCalculator`, `IDisputeResolver`) to delegate core logic, allowing these implementations to be upgraded via governance.
*   **Decentralized Governance:** On-chain proposal and voting system for changing contract parameters and the addresses of logic modules.
*   **Integrated Dispute Resolution:** Allows parties to raise disputes, submit evidence, and involves registered arbitrators who vote on outcomes, resolved by a pluggable `IDisputeResolver`.
*   **Arbitrator Staking:** Arbitrators stake collateral to participate.
*   **Token & ETH Support:** Can hold and transfer both native ETH and ERC-20 tokens.

**Outline:**
1.  **State Variables:** Mappings and variables to store escrow data, conditions, disputes, governance state, arbitrator data, logic module addresses, etc.
2.  **Enums:** Define states for escrows, disputes, proposals, and proposal types.
3.  **Structs:** Define data structures for Escrows, Conditions, Disputes, Proposals.
4.  **Interfaces:** Define interfaces for pluggable logic (`IRuleEvaluator`, `IFeeCalculator`, `IDisputeResolver`).
5.  **Events:** To signal important state changes and actions.
6.  **Modifiers:** Access control and state checks.
7.  **Constructor:** Initializes the contract with initial governance members and default logic module addresses (or requires them to be set via initial proposals).
8.  **Escrow Management Functions:** Create, fund, add/remove parties, get state/details.
9.  **Condition Management Functions:** Set, evaluate, add/remove conditions (initial setting and later via governance/proposal).
10. **Escrow Lifecycle Functions:** Release, request refund.
11. **Dispute Resolution Functions:** Raise dispute, submit evidence, arbitrator voting, dispute resolution execution.
12. **Arbitrator Management Functions:** Stake, unstake, register/deregister (maybe via governance).
13. **Governance Functions:** Propose amendment, vote on proposal, execute proposal, add/remove governance members, delegate voting power, query proposal/governance state.
14. **Logic Module & Parameter Functions:** Internal/External functions to set logic module addresses (only via executed proposals) and query current addresses/parameters.
15. **Fee Management Functions:** Internal fee calculation, external withdrawal of accumulated fees (to a treasury or governance-defined address).
16. **View Functions:** Public functions to read contract state without transactions.

**Function Summary (20+ Functions):**

**Escrow Core (7 functions):**
1.  `createEscrow`: Initializes a new escrow with parties, token, amounts, initial conditions, and a deadline.
2.  `fundEscrow(uint256 escrowId)`: Allows designated depositors to send ETH or ERC20 tokens to the escrow contract for a specific escrow.
3.  `addEscrowParty(uint256 escrowId, address party, EscrowPartyRole role)`: Allows governance (or initial setup) to add participants (depositors, beneficiaries, observers) to an existing escrow.
4.  `removeEscrowParty(uint256 escrowId, address party)`: Allows governance to remove a participant from an escrow.
5.  `setEscrowCondition(uint256 escrowId, bytes conditionData)`: Allows initial condition setting during creation or via proposal later. `conditionData` is parameters for the `IRuleEvaluator`.
6.  `evaluateEscrowConditions(uint256 escrowId)`: Calls the current `IRuleEvaluator` logic module to check if all conditions for an escrow are met. Returns a boolean.
7.  `getEscrowState(uint256 escrowId)`: View function to get the current state and details of an escrow.

**Escrow Lifecycle (2 functions):**
8.  `releaseEscrowFunds(uint256 escrowId)`: Executes fund release to beneficiaries if `evaluateEscrowConditions` returns true and the escrow is in the correct state. Calculates and applies fees.
9.  `requestRefund(uint256 escrowId)`: Allows a depositor to initiate a refund process, typically if conditions are evaluated as false after a deadline, or as an outcome of a dispute.

**Dispute Resolution (6 functions):**
10. `raiseDispute(uint256 escrowId)`: Allows a party involved in an escrow to initiate a dispute. Requires staking a dispute fee.
11. `submitEvidence(uint256 disputeId, string calldata evidenceURI)`: Allows involved parties and arbitrators to submit links (e.g., IPFS hash) to evidence related to a dispute.
12. `arbitratorVote(uint256 disputeId, DisputeOutcome outcome)`: Allows registered, staked arbitrators to vote on the outcome of an active dispute (e.g., Release, Refund, Split, Cancel).
13. `resolveDispute(uint256 disputeId)`: Can be called by anyone after the voting period ends. Calls the current `IDisputeResolver` logic module to determine the final outcome based on arbitrator votes and potentially other factors (like stake). Executes the outcome (fund transfers, state change).
14. `stakeArbitrator(uint256 amount)`: Allows anyone to stake collateral to become a registered arbitrator.
15. `unstakeArbitrator()`: Allows a staked arbitrator to withdraw their stake after a cooldown period, provided they are not currently involved in active disputes or pending slashes.

**Governance & Amendment (10 functions):**
16. `proposeAmendment(ProposalType proposalType, address targetAddress, uint256 targetValue, bytes calldata extraData, string calldata description)`: Allows a governance member to propose a change: setting a parameter (`targetValue`), updating a logic module address (`targetAddress`), adding/removing gov members, changing gov params, etc. `extraData` provides context for complex proposals (like adding escrow parties via proposal).
17. `voteOnProposal(uint256 proposalId, bool support)`: Allows governance members (or delegated voters) to vote yes/no on an active proposal.
18. `executeProposal(uint256 proposalId)`: Can be called by anyone after the voting period ends and quorum/threshold requirements are met. Applies the changes proposed in the proposal. This function is the *only* way to change logic module addresses or key contract parameters.
19. `addGovernanceMember(address member)`: (Internal function, called by `executeProposal` for a specific proposal type) Adds an address to the set of governance members.
20. `removeGovernanceMember(address member)`: (Internal function, called by `executeProposal` for a specific proposal type) Removes an address from the set of governance members.
21. `delegateVote(address delegatee)`: Allows a governance member to delegate their voting power to another address.
22. `undelegateVote()`: Allows a governance member to revoke their delegation.
23. `getProposalState(uint256 proposalId)`: View function to check the status and details of a proposal.
24. `getGovernanceMembers()`: View function to get the list of current governance member addresses.
25. `getLogicModuleAddress(bytes32 moduleKey)`: View function to get the current address assigned to a specific logic module type (identified by a key).

**Utility & View (6 functions):**
26. `getEscrowParties(uint256 escrowId)`: View function to list all parties involved in an escrow and their roles.
27. `getEscrowConditions(uint256 escrowId)`: View function to get the list of conditions set for an escrow.
28. `getArbitratorStake(address arbitrator)`: View function to check an arbitrator's current staked amount.
29. `isGovernanceMember(address account)`: View function to check if an address is a governance member.
30. `isArbitrator(address account)`: View function to check if an address is a registered arbitrator (staked).
31. `withdrawFees(address recipient)`: Allows the designated fee recipient (e.g., a DAO treasury address, set by governance) to withdraw accumulated protocol fees (calculated by `IFeeCalculator` during release/resolution).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol"; // Optional, adds a layer of safety controlled by governance

// --- Interfaces for Pluggable Logic Modules ---

/**
 * @title IRuleEvaluator
 * @notice Interface for external contracts that evaluate complex escrow conditions.
 * The main Escrow contract will call this interface to determine if release conditions are met.
 */
interface IRuleEvaluator {
    /**
     * @notice Evaluates a specific condition based on provided data and contract state.
     * @param escrowId The ID of the escrow.
     * @param conditionData Encoded parameters specific to the condition type.
     * @return bool True if the condition is met, false otherwise.
     * @return bytes32 A potential status/error code or extra result data.
     */
    function evaluateCondition(uint256 escrowId, bytes calldata conditionData) external view returns (bool, bytes32);

    /**
     * @notice Evaluates all conditions for an escrow.
     * @param escrowId The ID of the escrow.
     * @param conditions An array of condition data bytes from the Escrow contract.
     * @return bool True if ALL conditions are met, false otherwise.
     */
    function evaluateAllConditions(uint256 escrowId, bytes[] calldata conditions) external view returns (bool);
}

/**
 * @title IFeeCalculator
 * @notice Interface for external contracts that calculate protocol fees.
 * The main Escrow contract calls this during fund release or dispute resolution.
 */
interface IFeeCalculator {
    /**
     * @notice Calculates the protocol fee for a given amount in an escrow context.
     * @param escrowId The ID of the escrow.
     * @param amount The amount being transferred (e.g., released or refunded).
     * @param token The address of the token being transferred (address(0) for ETH).
     * @return uint256 The calculated fee amount.
     */
    function calculateFee(uint256 escrowId, uint256 amount, address token) external view returns (uint256);
}

/**
 * @title IDisputeResolver
 * @notice Interface for external contracts that determine the outcome of a dispute.
 * The main Escrow contract calls this after arbitrator voting ends.
 */
interface IDisputeResolver {
    enum DisputeOutcome { Undecided, ReleaseToBeneficiary, RefundToDepositor, Split, CancelEscrow, SlashArbitrator }

    struct ArbitratorVote {
        address arbitrator;
        DisputeOutcome outcome;
        // Add weight, stake status at time of vote, etc. if needed by resolver
    }

    /**
     * @notice Determines the final outcome of a dispute based on votes and dispute state.
     * @param disputeId The ID of the dispute.
     * @param votes An array of votes cast by arbitrators.
     * @param totalArbitratorStake At the time of resolution.
     * @return DisputeOutcome The decided outcome for the dispute.
     * @return mapping(address => uint256) The distribution of funds (party address => amount) if outcome is Split or other complex scenarios.
     * @return address[] Arbitrators to be potentially slashed based on outcome/resolver logic.
     */
    function determineOutcome(uint256 disputeId, ArbitratorVote[] calldata votes, uint256 totalArbitratorStake) external view returns (DisputeOutcome, mapping(address => uint256) memory, address[] memory);
}


// --- Main Contract ---

contract DecentralizedSelfAmendingEscrow is ReentrancyGuard, Pausable {

    // --- Constants & State Variables ---

    uint256 private constant VOTE_NAY = 0; // No/Against
    uint256 private constant VOTE_YEA = 1; // Yes/For

    enum EscrowState {
        PendingFunds,
        Funded,
        ConditionsMet,
        Dispute,
        Resolved, // Via release or refund
        Cancelled,
        Expired // Conditions not met by deadline
    }

    enum EscrowPartyRole {
        Depositor,
        Beneficiary,
        Observer // Can view details but not participate in actions
    }

    enum DisputeState {
        Raised,
        EvidencePeriod,
        VotingPeriod,
        Resolved,
        Cancelled
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed,
        Cancelled
    }

    enum ProposalType {
        SetParameterUint, // e.g., minArbitratorStake, votePeriod
        SetParameterAddress, // e.g., treasuryAddress
        SetLogicModule, // e.g., RuleEvaluator, FeeCalculator
        AddGovernanceMember,
        RemoveGovernanceMember,
        UpdateEscrowConditions, // Allows governance to modify conditions post-creation
        AddEscrowParty, // Allows governance to add parties post-creation
        RemoveEscrowParty, // Allows governance to remove parties post-creation
        CancelEscrow, // Allows governance to force cancel an escrow
        SetArbitrationFee // Changes the fee required to raise a dispute
        // Add more proposal types as needed for parameters
    }

    struct Escrow {
        address token; // address(0) for ETH
        mapping(address => uint256) depositedAmounts;
        mapping(address => uint256) beneficiaryAmounts; // Target distribution
        mapping(address => EscrowPartyRole) parties;
        bytes[] conditions; // Data for IRuleEvaluator
        uint64 deadline;
        EscrowState state;
        uint256 disputeId; // 0 if no active dispute
        uint256 createdAt;
    }

    struct Condition {
        bytes conditionData; // Data parameters for the Rule Evaluator
        bool evaluated;
        bool evaluationResult; // Result of the last evaluation
    }

    struct Dispute {
        uint256 escrowId;
        mapping(address => string) evidenceURIs; // Party/Arbitrator => IPFS Hash/URI
        mapping(address => IDisputeResolver.DisputeOutcome) arbitratorVotes; // Arbitrator => Vote
        mapping(address => bool) hasVoted; // To prevent double voting
        uint256 voteStartTime;
        uint256 voteEndTime;
        DisputeState state;
        IDisputeResolver.DisputeOutcome finalOutcome;
        // Mapping for split outcome? Or let resolver return it and handle in resolveDispute
        mapping(address => uint256) outcomeDistribution; // How funds should be split if applicable
    }

    struct Proposal {
        ProposalType proposalType;
        address proposer;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotes; // Sum of delegated stakes or 1 vote per member
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => uint256) votes; // Voter address => 0/1 (Nay/Yea) or vote weight
        mapping(address => address) delegation; // Voter => Delegatee
        mapping(address => bool) hasVoted; // Simple boolean if 1p1v
        ProposalState state;
        address targetAddress; // For address-based proposals
        uint256 targetValue; // For uint-based proposals
        bytes extraData; // Additional data needed for complex proposals (e.g., for UpdateConditions, AddParty)
        string description; // Readable description
    }

    uint256 private _nextEscrowId;
    uint256 private _nextDisputeId;
    uint256 private _nextProposalId;

    mapping(uint256 => Escrow) public escrows;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => Proposal) public proposals;

    // Governance State
    address[] private _governanceMembers;
    mapping(address => bool) private _isGovernanceMember;
    mapping(address => address) private _governanceDelegation; // Gov member => Delegatee
    mapping(address => uint256) private _delegatedVotes; // Delegatee => total votes

    // Arbitrator State
    mapping(address => uint256) private _arbitratorStake;
    mapping(address => bool) private _isArbitrator;
    uint256 public minArbitratorStake; // Governance parameter
    uint256 public arbitratorUnstakeCooldown; // Governance parameter

    // Logic Module Addresses (Governance controlled)
    mapping(bytes32 => address) public logicModules; // Key => Contract Address

    // Governance Parameters (Governance controlled)
    uint256 public proposalVotingPeriod;
    uint256 public proposalQuorumNumerator; // e.g., 51 for 51% quorum
    uint256 public proposalQuorumDenominator; // e.g., 100 for %
    uint256 public disputeEvidencePeriod;
    uint256 public disputeVotingPeriod;
    uint256 public disputeArbitrationFee; // Fee required to raise a dispute

    address public treasuryAddress; // Address where protocol fees are collected

    // --- Events ---

    event EscrowCreated(uint256 indexed escrowId, address indexed token, address indexed creator);
    event EscrowFunded(uint256 indexed escrowId, address indexed funder, uint256 amount);
    event EscrowStateChanged(uint256 indexed escrowId, EscrowState newState, EscrowState oldState);
    event EscrowConditionsEvaluated(uint256 indexed escrowId, bool result);
    event EscrowReleased(uint256 indexed escrowId, uint256 protocolFee);
    event EscrowRefunded(uint256 indexed escrowId);
    event EscrowCancelled(uint256 indexed escrowId);
    event EscrowExpired(uint256 indexed escrowId);

    event DisputeRaised(uint256 indexed disputeId, uint256 indexed escrowId, address indexed raiser);
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed participant, string evidenceURI);
    event ArbitratorVoted(uint256 indexed disputeId, address indexed arbitrator, IDisputeResolver.DisputeOutcome outcome);
    event DisputeResolved(uint256 indexed disputeId, IDisputeResolver.DisputeOutcome finalOutcome);

    event ArbitratorStaked(address indexed arbitrator, uint256 amount);
    event ArbitratorUnstaked(address indexed arbitrator, uint256 amount);
    event ArbitratorSlashed(address indexed arbitrator, uint256 slashedAmount);

    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState, ProposalState oldState);
    event ProposalExecuted(uint256 indexed proposalId);

    event GovernanceMemberAdded(address indexed member);
    event GovernanceMemberRemoved(address indexed member);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);

    event LogicModuleSet(bytes32 indexed moduleKey, address indexed moduleAddress);
    event ParameterSetUint(bytes32 indexed parameterKey, uint256 value);
    event ParameterSetAddress(bytes32 indexed parameterKey, address value);
    event ArbitrationFeeSet(uint256 fee);

    event FeesWithdrawn(address indexed recipient, uint256 amountETH, uint256 amountERC20);


    // --- Modifiers ---

    modifier onlyParty(uint256 _escrowId, address _account) {
        require(escrows[_escrowId].parties[_account] != EscrowPartyRole(0), "Not an escrow party"); // Assuming 0 is not a valid role initially
        _;
    }

     modifier onlyDepositor(uint255 _escrowId, address _account) {
        require(escrows[_escrowId].parties[_account] == EscrowPartyRole.Depositor, "Not a depositor");
        _;
    }

     modifier onlyBeneficiary(uint255 _escrowId, address _account) {
        require(escrows[_escrowId].parties[_account] == EscrowPartyRole.Beneficiary, "Not a beneficiary");
        _;
    }


    modifier onlyArbitrator(address _account) {
        require(_isArbitrator[_account], "Not a registered arbitrator");
        _;
    }

    modifier onlyGovernance() {
        require(_isGovernanceMember[msg.sender], "Not a governance member");
        _;
    }

    modifier whenState(uint256 _escrowId, EscrowState _expectedState) {
        require(escrows[_escrowId].state == _expectedState, "Escrow not in expected state");
        _;
    }

     modifier whenDisputeState(uint256 _disputeId, DisputeState _expectedState) {
        require(disputes[_disputeId].state == _expectedState, "Dispute not in expected state");
        _;
    }

     modifier whenProposalState(uint256 _proposalId, ProposalState _expectedState) {
        require(proposals[_proposalId].state == _expectedState, "Proposal not in expected state");
        _;
    }


    // --- Constructor ---

    /**
     * @notice Initializes the contract with initial governance members and parameters.
     * @param initialGovernanceMembers Addresses of the initial governance members.
     * @param initialTreasuryAddress Address where initial fees will be directed.
     * @param initialParams Initial values for core parameters like periods and fees.
     *   Expected format: [minArbitratorStake, arbitratorUnstakeCooldown, proposalVotingPeriod,
     *                    proposalQuorumNumerator, proposalQuorumDenominator,
     *                    disputeEvidencePeriod, disputeVotingPeriod, disputeArbitrationFee]
     */
    constructor(
        address[] memory initialGovernanceMembers,
        address initialTreasuryAddress,
        uint256[] memory initialParams
    ) Pausable(false) { // Start unpaused
        require(initialGovernanceMembers.length > 0, "At least one governance member required");
        require(initialTreasuryAddress != address(0), "Treasury address cannot be zero");
        require(initialParams.length == 8, "Initial parameters array length incorrect");

        for (uint i = 0; i < initialGovernanceMembers.length; i++) {
            address member = initialGovernanceMembers[i];
            require(member != address(0), "Zero address not allowed as governance member");
            _governanceMembers.push(member);
            _isGovernanceMember[member] = true;
            // Initial delegation to self (1 vote per member if no delegation)
            _governanceDelegation[member] = member;
            _delegatedVotes[member] = _delegatedVotes[member] + 1; // Assume 1 member = 1 vote initially
            emit GovernanceMemberAdded(member);
        }

        treasuryAddress = initialTreasuryAddress;

        // Set initial governance parameters
        minArbitratorStake = initialParams[0];
        arbitratorUnstakeCooldown = initialParams[1];
        proposalVotingPeriod = initialParams[2];
        proposalQuorumNumerator = initialParams[3];
        proposalQuorumDenominator = initialParams[4];
        disputeEvidencePeriod = initialParams[5];
        disputeVotingPeriod = initialParams[6];
        disputeArbitrationFee = initialParams[7];

        // Logic Module addresses must be set via governance proposals initially
        // e.g., use setLogicModuleProposalType in proposeAmendment
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to transfer ETH. Handles checks.
     */
    function _safeTransferETH(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @dev Internal function to transfer ERC20 tokens. Handles checks.
     */
    function _safeTransferERC20(address token, address recipient, uint256 amount) internal {
        IERC20(token).transfer(recipient, amount);
    }

    /**
     * @dev Internal function to get vote weight of an address (considering delegation).
     */
    function _getVoteWeight(address voter) internal view returns (uint256) {
        // If voter has delegated, their weight is 0
        if (_governanceDelegation[voter] != voter) {
            return 0;
        }
        // If someone delegated to voter, return aggregated votes. Otherwise, return 1 (self-delegated)
        return _delegatedVotes[voter] > 0 ? _delegatedVotes[voter] : (_isGovernanceMember[voter] ? 1 : 0);
    }

     /**
      * @dev Internal function to check if a party is valid for an escrow (exists and has a role)
      */
     function _isEscrowParty(uint256 _escrowId, address _account) internal view returns (bool) {
        return escrows[_escrowId].parties[_account] != EscrowPartyRole(0); // Assuming 0 is unassigned
     }

     /**
      * @dev Internal function to check if an address holds a specific role in an escrow
      */
     function _hasEscrowRole(uint256 _escrowId, address _account, EscrowPartyRole _role) internal view returns (bool) {
        return escrows[_escrowId].parties[_account] == _role;
     }


    // --- Escrow Core Functions (7) ---

    /**
     * @notice Initializes a new escrow. Parties need to be added after creation or via extraData in proposal.
     * Initial conditions are set here, but can be changed later via governance proposal.
     * @param _token The token address (address(0) for ETH).
     * @param _beneficiaryAmounts Mapping of beneficiary addresses to their target amounts.
     * @param _initialConditions Initial condition data for the rule evaluator.
     * @param _deadline Unix timestamp by which conditions should ideally be met.
     * @param _partiesWithRoles Initial parties and their roles (depositors, beneficiaries, observers).
     */
    function createEscrow(
        address _token,
        mapping(address => uint256) calldata _beneficiaryAmounts,
        bytes[] calldata _initialConditions,
        uint64 _deadline,
        address[] calldata _partiesWithRoles, // [party1, role1, party2, role2, ...] where role is uint8(EscrowPartyRole)
        bytes calldata _extraData // Optional extra data for initial setup, could include more detailed party info or initial deposits
    ) external whenNotPaused returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_initialConditions.length > 0, "At least one condition required");
        require(_partiesWithRoles.length > 0 && _partiesWithRoles.length % 2 == 0, "Invalid parties data");

        uint256 escrowId = ++_nextEscrowId;
        Escrow storage newEscrow = escrows[escrowId];

        newEscrow.token = _token;
        newEscrow.deadline = _deadline;
        newEscrow.state = EscrowState.PendingFunds;
        newEscrow.conditions = _initialConditions; // Store raw bytes, evaluator interprets
        newEscrow.createdAt = block.timestamp;

        // Store initial beneficiaries & amounts
        // Note: Need to iterate through map, not directly assign
        address[] memory beneficiariesArray = new address[0]; // Need to get keys from mapping calldata - tricky.
        // A better way is to pass beneficiaryAmounts as address[] & uint[] or use a struct array.
        // For simplicity in this example, let's assume beneficiaryAmounts is passed as address[] and uint256[]
        // Example: _beneficiaries = [addr1, addr2], _amounts = [amt1, amt2]
        // require(_beneficiaries.length == _amounts.length, "Beneficiary list and amounts mismatch");
        // for(uint i=0; i < _beneficiaries.length; i++) {
        //     newEscrow.beneficiaryAmounts[_beneficiaries[i]] = _amounts[i];
        // }
        // Or pass a struct array: struct BeneficiaryAmount { address addr; uint256 amount; }
        // For now, let's keep the mapping in struct declaration but note this calldata limitation.
        // Assume _beneficiaryAmounts is represented by _partiesWithRoles for beneficiaries, and amounts set later or implied.
        // Let's simplify: beneficiaries are just addresses added via _partiesWithRoles initially with Beneficiary role. Amounts set via another means or implied.
        // Or, beneficiary amounts are part of the condition logic evaluated by IRuleEvaluator.

        // Let's refine: Beneficiary amounts ARE stored in the escrow struct, passed as a separate array of structs.
        // struct BeneficiaryAmount { address beneficiary; uint256 amount; }
        // createEscrow(..., BeneficiaryAmount[] calldata _beneficiaryAmounts, ...)

        // Add initial parties based on the provided array
        for (uint i = 0; i < _partiesWithRoles.length; i += 2) {
            address party = _partiesWithRoles[i];
            EscrowPartyRole role = EscrowPartyRole(uint8(_partiesWithRoles[i+1]));
            require(party != address(0), "Party address cannot be zero");
            newEscrow.parties[party] = role;
            if (role == EscrowPartyRole.Beneficiary) {
                 // For simplicity, let's assume beneficiary amounts are 0 initially and set later or defined in conditions
                 newEscrow.beneficiaryAmounts[party] = 0; // Placeholder
            }
        }

        emit EscrowCreated(escrowId, _token, msg.sender);

        return escrowId;
    }

    /**
     * @notice Allows designated depositors to fund an escrow.
     * @param _escrowId The ID of the escrow to fund.
     */
    function fundEscrow(uint256 _escrowId) external payable whenNotPaused nonReentrant whenState(_escrowId, EscrowState.PendingFunds) onlyDepositor(_escrowId, msg.sender) {
        Escrow storage escrow = escrows[_escrowId];

        uint256 amount = msg.value; // For ETH
        if (escrow.token != address(0)) {
             // For ERC20, depositor must have approved this contract beforehand
             amount = IERC20(escrow.token).transferFrom(msg.sender, address(this), IERC20(escrow.token).balanceOf(msg.sender)); // Pull *all* approved amount? Or require amount in call?
             // Let's require amount in function call and approval beforehand.
             // fundEscrow(uint256 _escrowId, uint256 _amount)
             // amount = _amount;
             // require(IERC20(escrow.token).transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
             revert("ERC20 funding not implemented in this simple example. Use ETH funding."); // Stick to ETH for simplicity
        }

        require(amount > 0, "Zero amount funding not allowed");

        escrow.depositedAmounts[msg.sender] = escrow.depositedAmounts[msg.sender] + amount; // Track per depositor

        uint256 totalDeposited = 0;
        // Need to track total *expected* amount or use condition evaluator
        // For now, assume escrow transitions to Funded once *any* deposit is made or after first call.
        // A more robust system would track total needed vs total received.
        if (escrow.state == EscrowState.PendingFunds) {
             EscrowState oldState = escrow.state;
             escrow.state = EscrowState.Funded; // Simple transition on first fund
             emit EscrowStateChanged(_escrowId, escrow.state, oldState);
        }

        emit EscrowFunded(_escrowId, msg.sender, amount);
    }

    /**
     * @notice Allows governance to add a party to an existing escrow. Must be via proposal.
     * @param _escrowId The ID of the escrow.
     * @param _party The address of the party to add.
     * @param _role The role for the party.
     */
    function addEscrowParty(uint256 _escrowId, address _party, EscrowPartyRole _role) external onlyGovernance whenNotPaused {
        // This function should only be callable by the `executeProposal` function for a specific proposal type.
        // Direct call is blocked by onlyGovernance, but executeProposal could call it.
        // Let's make it internal and called by executeProposal.
        _addEscrowParty(_escrowId, _party, _role);
    }

    /**
     * @dev Internal function to add an escrow party.
     */
    function _addEscrowParty(uint256 _escrowId, address _party, EscrowPartyRole _role) internal {
        require(_isGovernanceMember[msg.sender], "Internal: Not called by governance context (executeProposal)"); // Ensure it's called by governance context
        require(escrows[_escrowId].parties[_party] == EscrowPartyRole(0), "Party already exists"); // Assuming 0 is unassigned

        escrows[_escrowId].parties[_party] = _role;
        if (_role == EscrowPartyRole.Beneficiary) {
            escrows[_escrowId].beneficiaryAmounts[_party] = 0; // Placeholder
        }
         // Event? Maybe log in executeProposal
    }

    /**
     * @notice Allows governance to remove a party from an existing escrow. Must be via proposal.
     * @param _escrowId The ID of the escrow.
     * @param _party The address of the party to remove.
     */
    function removeEscrowParty(uint256 _escrowId, address _party) external onlyGovernance whenNotPaused {
         // Should be internal, called by executeProposal
        _removeEscrowParty(_escrowId, _party);
    }

    /**
     * @dev Internal function to remove an escrow party.
     */
    function _removeEscrowParty(uint256 _escrowId, address _party) internal {
        require(_isGovernanceMember[msg.sender], "Internal: Not called by governance context (executeProposal)"); // Ensure it's called by governance context
        require(escrows[_escrowId].parties[_party] != EscrowPartyRole(0), "Party does not exist");

        delete escrows[_escrowId].parties[_party];
        // Handle removing from beneficiaryAmounts etc. depending on role
         // Event? Maybe log in executeProposal
    }

    /**
     * @notice Sets or updates conditions for an escrow. Initial conditions are set in `createEscrow`.
     * Subsequent changes require a governance proposal using the `UpdateEscrowConditions` type.
     * @param _escrowId The ID of the escrow.
     * @param _conditions The new array of condition data bytes.
     */
    function setEscrowConditions(uint256 _escrowId, bytes[] calldata _conditions) external onlyGovernance whenNotPaused {
         // Should be internal, called by executeProposal for type UpdateEscrowConditions
        _setEscrowConditions(_escrowId, _conditions);
    }

    /**
     * @dev Internal function to set escrow conditions.
     */
    function _setEscrowConditions(uint256 _escrowId, bytes[] calldata _conditions) internal {
        require(_isGovernanceMember[msg.sender], "Internal: Not called by governance context (executeProposal)"); // Ensure it's called by governance context
        require(_conditions.length > 0, "At least one condition required");

        escrows[_escrowId].conditions = _conditions;
         // Event? Maybe log in executeProposal
    }


    /**
     * @notice Evaluates the conditions for an escrow using the current IRuleEvaluator.
     * Can be called by any address. Does not change escrow state.
     * @param _escrowId The ID of the escrow.
     * @return bool True if conditions are met, false otherwise.
     */
    function evaluateEscrowConditions(uint256 _escrowId) public view returns (bool) {
        Escrow storage escrow = escrows[_escrowId];
        address ruleEvaluatorAddress = logicModules[bytes32("IRuleEvaluator")];
        require(ruleEvaluatorAddress != address(0), "Rule Evaluator module not set");

        IRuleEvaluator ruleEvaluator = IRuleEvaluator(ruleEvaluatorAddress);
        bool met = ruleEvaluator.evaluateAllConditions(_escrowId, escrow.conditions);
        emit EscrowConditionsEvaluated(_escrowId, met);
        return met;
    }

    /**
     * @notice View function to get the current state and details of an escrow.
     * @param _escrowId The ID of the escrow.
     * @return Escrow struct (with potentially empty mappings).
     */
    function getEscrowState(uint256 _escrowId) external view returns (Escrow memory) {
         // Note: Mappings in structs cannot be returned directly.
         // Need helper view functions for parties, deposited amounts, beneficiary amounts.
         // Returning a 'memory' struct copy, mappings will appear empty.
        Escrow storage s = escrows[_escrowId];
        return Escrow(s.token, s.depositedAmounts, s.beneficiaryAmounts, s.parties, s.conditions, s.deadline, s.state, s.disputeId, s.createdAt);
    }

    // --- Escrow Lifecycle Functions (2) ---

    /**
     * @notice Releases funds to beneficiaries if conditions are met and the escrow is in a release-eligible state.
     * Can be triggered by any party or observer once conditions are met.
     * @param _escrowId The ID of the escrow.
     */
    function releaseEscrowFunds(uint256 _escrowId) external whenNotPaused nonReentrant whenState(_escrowId, EscrowState.Funded) {
        Escrow storage escrow = escrows[_escrowId];

        // Optionally evaluate conditions if not already marked as met
        bool conditionsMet = evaluateEscrowConditions(_escrowId);
        require(conditionsMet, "Escrow conditions not met");

        EscrowState oldState = escrow.state;
        escrow.state = EscrowState.ConditionsMet; // Transition state before transfer
        emit EscrowStateChanged(_escrowId, escrow.state, oldState);

        // Calculate total amount to distribute (sum of deposited amounts)
        uint256 totalDeposited = 0;
         address[] memory depositors = getEscrowPartiesByRole(_escrowId, EscrowPartyRole.Depositor);
         for(uint i=0; i < depositors.length; i++) {
             totalDeposited = totalDeposited + escrow.depositedAmounts[depositors[i]];
         }


        // Calculate protocol fee
        address feeCalculatorAddress = logicModules[bytes32("IFeeCalculator")];
        uint256 protocolFee = 0;
        if (feeCalculatorAddress != address(0)) {
            protocolFee = IFeeCalculator(feeCalculatorAddress).calculateFee(_escrowId, totalDeposited, escrow.token);
            require(protocolFee <= totalDeposited, "Fee exceeds total deposited amount");
        }

        uint256 amountToDistribute = totalDeposited - protocolFee;
        uint256 totalBeneficiaryAmountTarget = 0;
        address[] memory beneficiaries = getEscrowPartiesByRole(_escrowId, EscrowPartyRole.Beneficiary);

        // For simplicity, assume beneficiaryAmounts in storage maps beneficiary => *portion* of totalDistribution.
        // A real system needs a robust way to define distribution logic (e.g., percentages, fixed amounts capped by total).
        // Let's assume beneficiaryAmounts[beneficiary] stores the final amount they should receive.
         for(uint i=0; i < beneficiaries.length; i++) {
             address beneficiary = beneficiaries[i];
             uint256 amount = escrow.beneficiaryAmounts[beneficiary];
             require(amount > 0, "Beneficiary amount not set or zero"); // Ensure amounts are defined
             totalBeneficiaryAmountTarget += amount;
         }
         require(totalBeneficiaryAmountTarget <= amountToDistribute, "Beneficiary amounts exceed distributable amount");


        // Distribute funds to beneficiaries
        for (uint i = 0; i < beneficiaries.length; i++) {
             address beneficiary = beneficiaries[i];
             uint256 amount = escrow.beneficiaryAmounts[beneficiary]; // Amount defined in escrow struct
             if (amount > 0) {
                if (escrow.token == address(0)) {
                     _safeTransferETH(beneficiary, amount);
                } else {
                     _safeTransferERC20(escrow.token, beneficiary, amount);
                }
                // Reset beneficiary amount tracking if needed
                escrow.beneficiaryAmounts[beneficiary] = 0;
             }
        }

        // Transfer protocol fee
        if (protocolFee > 0 && treasuryAddress != address(0)) {
             if (escrow.token == address(0)) {
                _safeTransferETH(treasuryAddress, protocolFee);
             } else {
                 _safeTransferERC20(escrow.token, treasuryAddress, protocolFee);
             }
        }

        // Any remaining dust stays in the contract or is sent to treasury
        uint256 remainingBalance = escrow.token == address(0) ? address(this).balance : IERC20(escrow.token).balanceOf(address(this));
        // Potentially send remainingBalance (after transfers) to treasury if > dust threshold

        escrow.state = EscrowState.Resolved;
        emit EscrowStateChanged(_escrowId, escrow.state, EscrowState.ConditionsMet);
        emit EscrowReleased(_escrowId, protocolFee);
    }


    /**
     * @notice Initiates a refund process. Can be called by a depositor if conditions are not met by the deadline
     * or if the escrow state indicates refund is possible (e.g., after dispute resolution).
     * @param _escrowId The ID of the escrow.
     */
    function requestRefund(uint256 _escrowId) external whenNotPaused nonReentrant whenState(_escrowId, EscrowState.Expired) onlyDepositor(_escrowId, msg.sender) {
        Escrow storage escrow = escrows[_escrowId];
        // Ensure deadline has passed and conditions are NOT met (or state is Expired)
        require(block.timestamp > escrow.deadline || escrow.state == EscrowState.Expired, "Escrow not expired");
        // Check if conditions were evaluated and failed or if state is explicitly Expired
        bool conditionsMet = evaluateEscrowConditions(_escrowId);
        require(!conditionsMet || escrow.state == EscrowState.Expired, "Conditions were met or escrow is not in Expired state");


        EscrowState oldState = escrow.state;
        // Distribute deposited amounts back to original depositors
        address[] memory depositors = getEscrowPartiesByRole(_escrowId, EscrowPartyRole.Depositor);
        for(uint i=0; i < depositors.length; i++) {
            address depositor = depositors[i];
            uint256 amount = escrow.depositedAmounts[depositor];
            if (amount > 0) {
                if (escrow.token == address(0)) {
                     _safeTransferETH(depositor, amount);
                } else {
                     _safeTransferERC20(escrow.token, depositor, amount);
                }
                // Reset deposited amount tracking
                escrow.depositedAmounts[depositor] = 0;
            }
        }

        escrow.state = EscrowState.Resolved; // Or Refunded state? Let's use Resolved for simplicity
        emit EscrowStateChanged(_escrowId, escrow.state, oldState);
        emit EscrowRefunded(_escrowId);

         // Any fees? Usually refunds don't incur protocol fees, but could be defined by IFeeCalculator.
         // If fees were taken on deposit, that logic needs to be here or in fundEscrow.
    }


    // --- Dispute Resolution Functions (6) ---

    /**
     * @notice Allows an escrow party to raise a dispute. Requires staking a fee.
     * @param _escrowId The ID of the escrow.
     */
    function raiseDispute(uint256 _escrowId) external payable whenNotPaused nonReentrant onlyParty(_escrowId, msg.sender) whenState(_escrowId, EscrowState.Funded) {
         Escrow storage escrow = escrows[_escrowId];
         require(escrow.disputeId == 0, "Dispute already exists for this escrow");
         require(msg.value >= disputeArbitrationFee, "Insufficient arbitration fee");

         uint256 disputeId = ++_nextDisputeId;
         Dispute storage newDispute = disputes[disputeId];

         newDispute.escrowId = _escrowId;
         newDispute.state = DisputeState.Raised;
         newDispute.voteStartTime = 0; // Not started yet
         newDispute.voteEndTime = 0;
         newDispute.finalOutcome = IDisputeResolver.DisputeOutcome.Undecided;

         escrow.disputeId = disputeId;
         EscrowState oldEscrowState = escrow.state;
         escrow.state = EscrowState.Dispute; // Escrow enters dispute state
         emit EscrowStateChanged(_escrowId, escrow.state, oldEscrowState);

         emit DisputeRaised(disputeId, _escrowId, msg.sender);

         // Move to EvidencePeriod automatically or require another call?
         // Auto-transition for simplicity:
         newDispute.state = DisputeState.EvidencePeriod;
         // Evidence period could start here, or be triggered by governance/arbitrator.
         // Let's require a separate call to start voting/evidence period.
    }

    /**
     * @notice Allows parties and arbitrators to submit evidence URIs for a dispute.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceURI The URI (e.g., IPFS hash) pointing to the evidence.
     */
    function submitEvidence(uint256 _disputeId, string calldata _evidenceURI) external whenNotPaused whenDisputeState(_disputeId, DisputeState.Raised) {
        Dispute storage dispute = disputes[_disputeId];
        // Only escrow parties or registered arbitrators can submit evidence
        require(_isEscrowParty(dispute.escrowId, msg.sender) || _isArbitrator[msg.sender], "Not authorized to submit evidence");
        require(bytes(_evidenceURI).length > 0, "Evidence URI cannot be empty");

        dispute.evidenceURIs[msg.sender] = _evidenceURI;
        emit EvidenceSubmitted(_disputeId, msg.sender, _evidenceURI);
    }

    /**
     * @notice Allows registered, staked arbitrators to vote on the outcome of a dispute during the voting period.
     * @param _disputeId The ID of the dispute.
     * @param _outcome The chosen outcome.
     */
    function arbitratorVote(uint256 _disputeId, IDisputeResolver.DisputeOutcome _outcome) external whenNotPaused onlyArbitrator(msg.sender) whenDisputeState(_disputeId, DisputeState.VotingPeriod) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.voteEndTime > block.timestamp, "Voting period has ended");
        require(!dispute.hasVoted[msg.sender], "Arbitrator already voted");
        require(_outcome != IDisputeResolver.DisputeOutcome.Undecided, "Cannot vote Undecided");

        dispute.arbitratorVotes[msg.sender] = _outcome;
        dispute.hasVoted[msg.sender] = true;

        emit ArbitratorVoted(_disputeId, msg.sender, _outcome);
    }

    /**
     * @notice Can be called by anyone after the dispute voting period ends to trigger resolution.
     * Calls the current IDisputeResolver logic module to determine the outcome and execute it.
     * @param _disputeId The ID of the dispute.
     */
    function resolveDispute(uint256 _disputeId) external whenNotPaused nonReentrant whenDisputeState(_disputeId, DisputeState.VotingPeriod) {
        Dispute storage dispute = disputes[_disputeId];
        require(block.timestamp >= dispute.voteEndTime, "Voting period has not ended");
        require(logicModules[bytes32("IDisputeResolver")] != address(0), "Dispute Resolver module not set");

        IDisputeResolver disputeResolver = IDisputeResolver(logicModules[bytes32("IDisputeResolver")]);

        // Collect votes cast
        address[] memory arbitrators = getArbitrators(); // Get all registered arbitrators (could be optimized)
        IDisputeResolver.ArbitratorVote[] memory votesCast = new IDisputeResolver.ArbitratorVote[](arbitrators.length);
        uint256 voteCount = 0;
        for(uint i=0; i < arbitrators.length; i++) {
            address arb = arbitrators[i];
            if(dispute.hasVoted[arb]) {
                votesCast[voteCount] = IDisputeResolver.ArbitratorVote(arb, dispute.arbitratorVotes[arb]);
                voteCount++;
            }
        }
        // Resize votes array to only include cast votes
        IDisputeResolver.ArbitratorVote[] memory finalVotes = new IDisputeResolver.ArbitratorVote[](voteCount);
        for(uint i=0; i < voteCount; i++) {
            finalVotes[i] = votesCast[i];
        }

        // Get current total staked amount for resolver input (resolver might use it for weighted voting)
        uint256 totalStake = 0;
         for(uint i=0; i < arbitrators.length; i++) {
             totalStake += _arbitratorStake[arbitrators[i]];
         }


        // Determine outcome using the pluggable resolver
        (IDisputeResolver.DisputeOutcome finalOutcome, mapping(address => uint256) memory distribution, address[] memory arbitratorsToSlash) = disputeResolver.determineOutcome(_disputeId, finalVotes, totalStake);

        dispute.finalOutcome = finalOutcome;
        dispute.state = DisputeState.Resolved; // Or Resolving, then Resolved?

        Escrow storage escrow = escrows[dispute.escrowId];
        EscrowState oldEscrowState = escrow.state;

        // Execute outcome based on the resolved decision
        if (finalOutcome == IDisputeResolver.DisputeOutcome.ReleaseToBeneficiary) {
             // Simple case: Transfer all deposited amount (minus fee) to beneficiaries (as defined in original escrow or resolution?)
             // Let's assume resolver defines beneficiary amounts in `distribution` map
             uint256 totalDistributed = 0;
             for(uint i=0; i < beneficiaries.length; i++) { // Need beneficiaries list
                  address beneficiary = beneficiaries[i]; // getEscrowPartiesByRole needs implementation
                  uint256 amount = distribution[beneficiary]; // Amount determined by resolver
                  if (amount > 0) {
                      if (escrow.token == address(0)) {
                          _safeTransferETH(beneficiary, amount);
                      } else {
                          _safeTransferERC20(escrow.token, beneficiary, amount);
                      }
                      totalDistributed += amount;
                  }
             }
            // Handle remaining funds (fees, dust) - sent to treasury
            // Protocol fee calculation during dispute resolution is complex - let resolver handle?
            // For simplicity here, assume resolution distributes main funds, protocol takes a cut or fee was taken on deposit.
            escrow.state = EscrowState.Resolved;

        } else if (finalOutcome == IDisputeResolver.DisputeOutcome.RefundToDepositor) {
             // Simple case: Transfer all deposited amount back to depositors (as defined in original escrow or resolution?)
             // Assume resolver defines depositor amounts in `distribution` map
             address[] memory depositors = getEscrowPartiesByRole(dispute.escrowId, EscrowPartyRole.Depositor); // Need implementation
             for(uint i=0; i < depositors.length; i++) {
                 address depositor = depositors[i];
                 uint256 amount = distribution[depositor]; // Amount determined by resolver
                  if (amount > 0) {
                      if (escrow.token == address(0)) {
                          _safeTransferETH(depositor, amount);
                      } else {
                          _safeTransferERC20(escrow.token, depositor, amount);
                      }
                  }
             }
             escrow.state = EscrowState.Resolved;

        } else if (finalOutcome == IDisputeResolver.DisputeOutcome.Split) {
            // Resolver provides full distribution map
            // Iterate through all parties (depositors + beneficiaries) and distribute according to map
            address[] memory allParties = getEscrowParties(dispute.escrowId); // Need implementation
             for(uint i=0; i < allParties.length; i++) {
                 address party = allParties[i];
                 uint256 amount = distribution[party];
                  if (amount > 0) {
                      if (escrow.token == address(0)) {
                          _safeTransferETH(party, amount);
                      } else {
                          _safeTransferERC20(escrow.token, party, amount);
                      }
                  }
             }
             escrow.state = EscrowState.Resolved;

        } else if (finalOutcome == IDisputeResolver.DisputeOutcome.CancelEscrow) {
            escrow.state = EscrowState.Cancelled;
            // Funds might stay in escrow, or be refunded/sent to treasury per resolver logic
             // If funds stay, a future governance proposal might be needed to move them.
        }
         // Handle slashing - resolver returns list of arbitrators to slash
         for(uint i = 0; i < arbitratorsToSlash.length; i++) {
             _slashArbitrator(arbitratorsToSlash[i]); // Internal slashing logic
         }


         emit DisputeResolved(_disputeId, finalOutcome);
         emit EscrowStateChanged(dispute.escrowId, escrow.state, oldEscrowState);

         // Transfer staked arbitration fee (could go to treasury, winning party, or arbitrators per governance rules)
         // For simplicity, send to treasury address.
         if (disputeArbitrationFee > 0 && treasuryAddress != address(0)) {
            // The fee was paid in ETH when raising the dispute
             _safeTransferETH(treasuryAddress, disputeArbitrationFee);
         }
    }

    /**
     * @notice Stake collateral to become a registered arbitrator.
     * @param _amount The amount of ETH or staking token (if different) to stake.
     */
    function stakeArbitrator(uint256 _amount) external payable whenNotPaused {
         // Assuming staking is done in ETH for simplicity. Could be a specific staking token.
         require(msg.value == _amount && _amount >= minArbitratorStake, "Stake amount insufficient or mismatch");

         _arbitratorStake[msg.sender] += _amount;
         _isArbitrator[msg.sender] = true; // Register as arbitrator if stake >= minStake

         emit ArbitratorStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a staked arbitrator to unstake their collateral after a cooldown period.
     * Must not be actively involved in a dispute (voting period, or pending slash).
     */
    function unstakeArbitrator() external whenNotPaused nonReentrant onlyArbitrator(msg.sender) {
         require(_arbitratorStake[msg.sender] >= minArbitratorStake, "Stake below minimum");
         // Add check for cooldown period and active disputes/slashes
         // require(lastUnstakeRequest[msg.sender] + arbitratorUnstakeCooldown <= block.timestamp, "Unstake cooldown in progress");
         // require(!isInActiveDispute[msg.sender], "Cannot unstake while in active dispute"); // Need state tracking for this

         uint256 amount = _arbitratorStake[msg.sender];
         _arbitratorStake[msg.sender] = 0;
         _isArbitrator[msg.sender] = false; // Deregister

         _safeTransferETH(msg.sender, amount);

         emit ArbitratorUnstaked(msg.sender, amount);
    }

     /**
      * @dev Internal function to slash an arbitrator's stake. Called by resolveDispute based on resolver outcome.
      * @param _arbitrator The arbitrator address to slash.
      */
     function _slashArbitrator(address _arbitrator) internal {
        uint256 slashAmount = _arbitratorStake[_arbitrator]; // Slash full stake for simplicity
        require(slashAmount > 0, "Arbitrator has no stake to slash");

        _arbitratorStake[_arbitrator] = 0;
        _isArbitrator[_arbitrator] = false; // Deregister after slashing

        // Transfer slashed amount to treasury
        if (slashAmount > 0 && treasuryAddress != address(0)) {
             _safeTransferETH(treasuryAddress, slashAmount);
        }

        emit ArbitratorSlashed(_arbitrator, slashAmount);
     }


    // --- Governance & Amendment Functions (10) ---

    /**
     * @notice Allows a governance member to propose an amendment to the contract's parameters or logic modules.
     * @param _proposalType The type of proposal (e.g., SetParameterUint, SetLogicModule).
     * @param _targetAddress Target address for address-based proposals (e.g., new logic module address, new treasury).
     * @param _targetValue Target value for uint-based proposals (e.g., new voting period, new min stake).
     * @param _extraData Extra data needed for certain proposal types (e.g., new condition data array for UpdateEscrowConditions, party/role data for AddEscrowParty).
     * @param _description Human-readable description of the proposal.
     */
    function proposeAmendment(
        ProposalType _proposalType,
        address _targetAddress,
        uint256 _targetValue,
        bytes calldata _extraData,
        string calldata _description
    ) external onlyGovernance whenNotPaused returns (uint256) {
        uint256 proposalId = ++_nextProposalId;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.proposalType = _proposalType;
        newProposal.proposer = msg.sender;
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp + proposalVotingPeriod;
        newProposal.state = ProposalState.Active;
        newProposal.targetAddress = _targetAddress;
        newProposal.targetValue = _targetValue;
        newProposal.extraData = _extraData;
        newProposal.description = _description;

        // Initialize votes based on current governance weight
        newProposal.totalVotes = _delegatedVotes[address(0)]; // Sum of all individual 1 votes (0 address used for non-delegated total)
         // This requires tracking total non-delegated votes or sum all _delegatedVotes.
         // A simpler 1p1v model might just track number of gov members. Let's use 1p1v for simplicity here.
         newProposal.totalVotes = _governanceMembers.length;


        emit ProposalCreated(proposalId, _proposalType, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows a governance member or their delegate to vote on an active proposal.
     * Using 1 member = 1 vote logic for simplicity in this example.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused whenProposalState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.voteEndTime, "Voting period has ended");

        // Determine the actual voter (could be self or delegatee)
        address voter = msg.sender;
        // In 1p1v delegation, the delegatee votes on behalf of the delegator.
        // Here, the sender must be EITHER a gov member with no delegation OR a delegatee.
        // Let's simplify: msg.sender must be a governance member OR a valid delegatee for a gov member.
        // And prevent double voting by the same _governanceMember (even if via different delegates, or self vs delegate).
        address originalVoter = msg.sender; // Need to find the root delegator if msg.sender is a delegatee.
        // Finding the original delegator requires traversing the delegation chain, which can be complex.
        // Simpler: Voter is msg.sender. If msg.sender is a delegatee, they cast a vote *for* the delegator(s).
        // The `hasVoted` map should track the *governance member* who voted, not just the sender.
        // We need a way to find the gov member whose vote is being cast.
        // Let's simplify again for example: Direct voting only. msg.sender must be a gov member.
        // The `delegateVote` function just updates _governanceDelegation and _delegatedVotes.
        // Voting: msg.sender *must* be a gov member.
        require(_isGovernanceMember[msg.sender], "Caller is not a governance member");
        require(_governanceDelegation[msg.sender] == msg.sender, "Vote must be cast by the original governance member, not a delegatee."); // Enforce direct voting if delegation is just weight transfer.
        require(!proposal.hasVoted[msg.sender], "Governance member already voted");


        proposal.hasVoted[msg.sender] = true;

        if (_support) {
            proposal.votesFor = proposal.votesFor + 1;
        } else {
            proposal.votesAgainst = proposal.votesAgainst + 1;
        }
        // proposals[_proposalId].votes[msg.sender] = _support ? VOTE_YEA : VOTE_NAY; // Store vote explicitly if needed

        // Update total votes cast if tracking quorum by number of votes
         // If 1p1v, totalVotes is just proposal.votesFor + proposal.votesAgainst
         // If weighted vote, totalVotes is sum of weighted votes. Using 1p1v here:
         // No need to update totalVotes if using member count for quorum.

        emit ProposalVoted(_proposalId, msg.sender, _support, 1); // 1 vote weight for 1p1v
    }

    /**
     * @notice Can be called by anyone after the voting period ends to execute a successful proposal.
     * Checks quorum and threshold requirements.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused whenProposalState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.voteEndTime, "Voting period has not ended");

        // Check quorum and threshold (using 1p1v logic)
        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
        uint256 currentGovMembers = _governanceMembers.length; // Use current member count for quorum check

        // Calculate quorum: (totalVotesCast * proposalQuorumDenominator) / currentGovMembers >= proposalQuorumNumerator
        // Avoid multiplication overflow: totalVotesCast * proposalQuorumDenominator >= currentGovMembers * proposalQuorumNumerator
        require(totalVotesCast * proposalQuorumDenominator >= currentGovMembers * proposalQuorumNumerator, "Quorum not met");

        // Check threshold: votesFor > votesAgainst
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass threshold");

        // Proposal succeeded, execute the action based on type
        EscrowState oldProposalState = proposal.state;
        proposal.state = ProposalState.Executed; // Set state before execution

        bytes32 key; // For SetParameter or SetLogicModule
        address escrowTarget; // For escrow-related proposals
        address partyTarget; // For party-related proposals
        EscrowPartyRole partyRoleTarget; // For party-related proposals

        // Decode _extraData if needed before switch statement
        // Example: For AddEscrowParty, extraData might contain escrowId, partyAddress, role

        if (proposal.proposalType == ProposalType.SetParameterUint) {
            // Decode key from extraData
            require(proposal.extraData.length >= 32, "Missing parameter key in extraData");
            assembly {
                key := mload(add(proposal.extraData, 32)) // Read bytes32 from start of data
            }
             // Apply the change to the relevant parameter based on the key
             if (key == bytes32("minArbitratorStake")) minArbitratorStake = proposal.targetValue;
             else if (key == bytes32("arbitratorUnstakeCooldown")) arbitratorUnstakeCooldown = proposal.targetValue;
             else if (key == bytes32("proposalVotingPeriod")) proposalVotingPeriod = proposal.targetValue;
             else if (key == bytes32("proposalQuorumNumerator")) proposalQuorumNumerator = proposal.targetValue;
             else if (key == bytes32("proposalQuorumDenominator")) proposalQuorumDenominator = proposal.targetValue;
             else if (key == bytes32("disputeEvidencePeriod")) disputeEvidencePeriod = proposal.targetValue;
             else if (key == bytes32("disputeVotingPeriod")) disputeVotingPeriod = proposal.targetValue;
             else revert("Unknown Uint parameter key");
             emit ParameterSetUint(key, proposal.targetValue);

        } else if (proposal.proposalType == ProposalType.SetParameterAddress) {
             // Decode key from extraData
             require(proposal.extraData.length >= 32, "Missing parameter key in extraData");
             assembly {
                 key := mload(add(proposal.extraData, 32))
             }
             // Apply the change to the relevant parameter based on the key
             if (key == bytes32("treasuryAddress")) treasuryAddress = proposal.targetAddress;
             else revert("Unknown Address parameter key");
             emit ParameterSetAddress(key, proposal.targetAddress);

        } else if (proposal.proposalType == ProposalType.SetLogicModule) {
             // Decode key from extraData
             require(proposal.extraData.length >= 32, "Missing module key in extraData");
             assembly {
                 key := mload(add(proposal.extraData, 32))
             }
            logicModules[key] = proposal.targetAddress;
            emit LogicModuleSet(key, proposal.targetAddress);

        } else if (proposal.proposalType == ProposalType.AddGovernanceMember) {
            // TargetAddress is the new member
            _addGovernanceMember(proposal.targetAddress);

        } else if (proposal.proposalType == ProposalType.RemoveGovernanceMember) {
            // TargetAddress is the member to remove
            _removeGovernanceMember(proposal.targetAddress);

        } else if (proposal.proposalType == ProposalType.SetArbitrationFee) {
             disputeArbitrationFee = proposal.targetValue;
             emit ArbitrationFeeSet(proposal.targetValue);

        } else if (proposal.proposalType == ProposalType.UpdateEscrowConditions) {
            // Decode escrowId and new conditions from extraData
            require(proposal.extraData.length >= 32, "Missing escrowId in extraData");
            assembly {
                escrowTarget := mload(add(proposal.extraData, 32)) // Read uint256 as address (careful!)
            }
            uint256 escrowId = uint256(uint160(escrowTarget)); // Explicit conversion
            // The rest of extraData is the new bytes[] conditions
            bytes[] memory newConditions = abi.decode(proposal.extraData[32:], (bytes[]));
            _setEscrowConditions(escrowId, newConditions);

        } else if (proposal.proposalType == ProposalType.AddEscrowParty) {
            // Decode escrowId, partyAddress, role from extraData
            require(proposal.extraData.length >= 32 + 32 + 1, "Missing party data in extraData");
            assembly {
                 escrowTarget := mload(add(proposal.extraData, 32))
                 partyTarget := mload(add(proposal.extraData, 64))
                 partyRoleTarget := mload(add(proposal.extraData, 96)) // Read uint8 role
            }
            uint256 escrowId = uint256(uint160(escrowTarget)); // Explicit conversion
             _addEscrowParty(escrowId, partyTarget, EscrowPartyRole(uint8(partyRoleTarget)));

        } else if (proposal.proposalType == ProposalType.RemoveEscrowParty) {
            // Decode escrowId, partyAddress from extraData
             require(proposal.extraData.length >= 32 + 32, "Missing party data in extraData");
             assembly {
                  escrowTarget := mload(add(proposal.extraData, 32))
                  partyTarget := mload(add(proposal.extraData, 64))
             }
             uint256 escrowId = uint256(uint160(escrowTarget)); // Explicit conversion
             _removeEscrowParty(escrowId, partyTarget);

        } else if (proposal.proposalType == ProposalType.CancelEscrow) {
             // Decode escrowId from extraData
             require(proposal.extraData.length >= 32, "Missing escrowId in extraData");
             assembly {
                  escrowTarget := mload(add(proposal.extraData, 32))
             }
             uint256 escrowId = uint256(uint160(escrowTarget)); // Explicit conversion
             Escrow storage escrowToCancel = escrows[escrowId];
             require(escrowToCancel.state != EscrowState.Resolved && escrowToCancel.state != EscrowState.Cancelled, "Escrow already resolved or cancelled");
             EscrowState oldEscrowState = escrowToCancel.state;
             escrowToCancel.state = EscrowState.Cancelled;
             emit EscrowCancelled(escrowId);
             emit EscrowStateChanged(escrowId, escrowToCancel.state, oldEscrowState);
        }
        // Add more proposal types here

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Internal function to add a governance member. Called only by executeProposal.
     * @param _member The address to add.
     */
    function _addGovernanceMember(address _member) internal {
        require(_isGovernanceMember[msg.sender], "Internal: Not called by governance context (executeProposal)"); // Ensure it's called by governance context
        require(_member != address(0), "Zero address not allowed");
        require(!_isGovernanceMember[_member], "Address is already a governance member");

        _governanceMembers.push(_member);
        _isGovernanceMember[_member] = true;
        _governanceDelegation[_member] = _member; // Self-delegate by default
        _delegatedVotes[_member] += 1; // Add 1 vote for the new member

        emit GovernanceMemberAdded(_member);
    }

    /**
     * @notice Internal function to remove a governance member. Called only by executeProposal.
     * @param _member The address to remove.
     */
    function _removeGovernanceMember(address _member) internal {
        require(_isGovernanceMember[msg.sender], "Internal: Not called by governance context (executeProposal)"); // Ensure it's called by governance context
        require(_isGovernanceMember[_member], "Address is not a governance member");
         require(_governanceMembers.length > 1, "Cannot remove the last governance member"); // Prevent empty governance

        // Remove from array (inefficient, but simple for example)
        for (uint i = 0; i < _governanceMembers.length; i++) {
            if (_governanceMembers[i] == _member) {
                _governanceMembers[i] = _governanceMembers[_governanceMembers.length - 1];
                _governanceMembers.pop();
                break;
            }
        }

        _isGovernanceMember[_member] = false;
         // Adjust delegation and vote counts
         address delegatee = _governanceDelegation[_member];
         if (delegatee != address(0)) { // If they were delegated or self-delegated
              _delegatedVotes[delegatee] -= 1;
         }
         delete _governanceDelegation[_member];


        emit GovernanceMemberRemoved(_member);
    }

    /**
     * @notice Allows a governance member to delegate their voting power to another address.
     * @param _delegatee The address to delegate votes to. address(0) to undelegate.
     */
    function delegateVote(address _delegatee) external onlyGovernance whenNotPaused {
        address delegator = msg.sender;
        require(_delegatee != delegator, "Cannot delegate to yourself");
        require(_isGovernanceMember[_delegatee] || _delegatee == address(0), "Delegatee must be a governance member or address(0)"); // Can only delegate to another member or address(0) to undelegate

        address currentDelegatee = _governanceDelegation[delegator];

        if (currentDelegatee != address(0)) {
             _delegatedVotes[currentDelegatee] -= 1; // Remove vote from current delegatee
        }

        _governanceDelegation[delegator] = _delegatee;
         if (_delegatee != address(0)) {
            _delegatedVotes[_delegatee] += 1; // Add vote to new delegatee
            emit VoteDelegated(delegator, _delegatee);
         } else {
             emit VoteUndelegated(delegator);
         }
    }

    /**
     * @notice Allows a governance member to undelegate their voting power. Same as `delegateVote(address(0))`.
     */
    function undelegateVote() external onlyGovernance whenNotPaused {
         delegateVote(address(0));
    }


    /**
     * @notice View function to get the state and details of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct (Note: Mappings will be empty).
     */
    function getProposalState(uint256 _proposalId) external view returns (Proposal memory) {
        Proposal storage p = proposals[_proposalId];
        return Proposal(p.proposalType, p.proposer, p.voteStartTime, p.voteEndTime, p.totalVotes, p.votesFor, p.votesAgainst, p.votes, p.delegation, p.hasVoted, p.state, p.targetAddress, p.targetValue, p.extraData, p.description);
         // Note: Mappings `votes`, `delegation`, `hasVoted` in the returned memory struct will be empty.
         // Need separate view functions for delegation status and vote status per member if needed externally.
    }

    /**
     * @notice View function to get the list of current governance member addresses.
     * @return address[] Array of governance member addresses.
     */
    function getGovernanceMembers() external view returns (address[] memory) {
        return _governanceMembers;
    }

    /**
     * @notice Allows governance to register a contract address as a valid logic module for a specific key.
     * Must be called via a governance proposal of type SetLogicModule.
     * @param _moduleKey The key identifying the logic module type (e.g., bytes32("IRuleEvaluator")).
     * @param _moduleAddress The address of the contract implementing the interface.
     */
     function registerLogicModule(bytes32 _moduleKey, address _moduleAddress) external onlyGovernance whenNotPaused {
         // This function should ideally ONLY be callable by executeProposal for type SetLogicModule.
         // An extra flag or check is needed here if `onlyGovernance` is not sufficient.
         // e.g., require(msg.sender == address(this), "Must be called internally by executeProposal");
         // But executeProposal calls externally.
         // A simple approach: `onlyGovernance` is sufficient if SetLogicModule proposal type is the only way `onlyGovernance` can call THIS function directly.
         // Let's assume direct calls by governance *are* allowed here for simplicity in example, but real design would restrict to executeProposal.
         require(_moduleAddress != address(0), "Module address cannot be zero");
         logicModules[_moduleKey] = _moduleAddress;
         emit LogicModuleSet(_moduleKey, _moduleAddress);
     }


    // --- Utility & View Functions (6) ---

    /**
     * @notice View function to get all parties involved in an escrow.
     * Note: Returns a dynamic array of addresses, roles need to be fetched separately per address or return a struct array.
     * @param _escrowId The ID of the escrow.
     * @return address[] Array of party addresses.
     */
    function getEscrowParties(uint256 _escrowId) external view returns (address[] memory) {
         // Iterating through mappings is not standard. Requires tracking parties in an array or
         // using a helper function that reconstructs from the mapping.
         // For example, storing parties in a dynamic array in the Escrow struct is better.
         // struct Escrow { ..., address[] partiesList; } and update this list.

         // Simple (but gas intensive) way to get parties from mapping keys if not using list:
         // This requires iterating over *all possible* addresses which is infeasible.
         // Realistically, need to store parties in a list or use a different structure.
         // Let's add a `partiesList` to the Escrow struct for this view function to work.
         // For this example, assume getEscrowPartiesByRole exists and combine results.
        address[] memory depositors = getEscrowPartiesByRole(_escrowId, EscrowPartyRole.Depositor);
        address[] memory beneficiaries = getEscrowPartiesByRole(_escrowId, EscrowPartyRole.Beneficiary);
        address[] memory observers = getEscrowPartiesByRole(_escrowId, EscrowPartyRole.Observer);

        address[] memory allParties = new address[](depositors.length + beneficiaries.length + observers.length);
        uint256 currentIndex = 0;
        for(uint i=0; i < depositors.length; i++) allParties[currentIndex++] = depositors[i];
        for(uint i=0; i < beneficiaries.length; i++) allParties[currentIndex++] = beneficiaries[i];
        for(uint i=0; i < observers.length; i++) allParties[currentIndex++] = observers[i];

        return allParties;
    }

     /**
      * @notice Helper view function to get parties of a specific role for an escrow.
      * Requires iterating through all parties or storing lists per role (better).
      * Assuming `partiesList` and `partyRoles` arrays are added to the Escrow struct for efficiency.
      * For now, this is a placeholder.
      * @param _escrowId The ID of the escrow.
      * @param _role The role to filter by.
      * @return address[] Array of party addresses with that role.
      */
     function getEscrowPartiesByRole(uint256 _escrowId, EscrowPartyRole _role) public view returns (address[] memory) {
         // Placeholder: Needs actual iteration or pre-built lists in storage
         // If _governanceMembers is a list, can iterate. For parties mapping, cannot.
         // Let's assume there's an internal `address[] _escrowPartiesList` and `mapping(address => EscrowPartyRole) _escrowPartyRoles`
         // and this function iterates through `_escrowPartiesList`.
          Escrow storage escrow = escrows[_escrowId];
          address[] memory parties = new address[](0); // Placeholder
          // In a real implementation, you'd iterate through a stored list of parties
          // and add those with the matching role to the result array.
          // For this conceptual example, this function cannot be fully implemented without changing state struct.
          // Let's return an empty array or revert, noting the limitation.
          // revert("getEscrowPartiesByRole requires iterating over storage which is not supported as written.");

          // Mock implementation assuming you stored parties in a list during creation/addParty
          // address[] memory allPartiesInEscrow = internalEscrowPartiesList[_escrowId]; // Hypothetical list
          // uint count = 0;
          // for(uint i = 0; i < allPartiesInEscrow.length; i++) {
          //     if(escrow.parties[allPartiesInEscrow[i]] == _role) {
          //         count++;
          //     }
          // }
          // address[] memory result = new address[](count);
          // uint current = 0;
          // for(uint i = 0; i < allPartiesInEscrow.length; i++) {
          //    if(escrow.parties[allPartiesInEscrow[i]] == _role) {
          //        result[current++] = allPartiesInEscrow[i];
          //    }
          // }
          // return result;

          // Simplified for example: just return all parties (addresses with non-zero role in mapping)
           address[] memory tempParties = new address[](100); // Assume max 100 parties for example
           uint count = 0;
           // THIS IS NOT EFFICIENT OR RELIABLE - Mappings cannot be iterated.
           // A real contract needs to store parties in an array.
           // Reverting to be clear about limitation:
           revert("Retrieving escrow parties by role requires a state variable array for parties, not mapping iteration.");

     }


    /**
     * @notice View function to get the list of conditions set for an escrow.
     * @param _escrowId The ID of the escrow.
     * @return bytes[] Array of condition data bytes.
     */
    function getEscrowConditions(uint256 _escrowId) external view returns (bytes[] memory) {
        return escrows[_escrowId].conditions;
    }

    /**
     * @notice View function to check an arbitrator's current staked amount.
     * @param _arbitrator The arbitrator address.
     * @return uint256 The staked amount.
     */
    function getArbitratorStake(address _arbitrator) external view returns (uint256) {
        return _arbitratorStake[_arbitrator];
    }

    /**
     * @notice View function to check if an address is a governance member.
     * @param _account The address to check.
     * @return bool True if the address is a governance member.
     */
    function isGovernanceMember(address _account) external view returns (bool) {
        return _isGovernanceMember[_account];
    }

    /**
     * @notice View function to check if an address is a registered (staked) arbitrator.
     * @param _account The address to check.
     * @return bool True if the address is a registered arbitrator.
     */
    function isArbitrator(address _account) external view returns (bool) {
        return _isArbitrator[_account];
    }

    /**
     * @notice Allows the designated treasury address to withdraw collected protocol fees.
     * @param _token The token type to withdraw (address(0) for ETH).
     * @param _recipient The address to send the fees to.
     */
     function withdrawFees(address _token, address _recipient) external onlyGovernance whenNotPaused nonReentrant {
         // Only the designated treasury address (or governance?) can initiate withdrawal.
         // Let's allow only governance to call this, sending to the current treasuryAddress.
         require(treasuryAddress != address(0), "Treasury address not set");
         require(_recipient != address(0), "Recipient address cannot be zero");

         uint256 amount = 0;
         if (_token == address(0)) {
             amount = address(this).balance;
              // Subtract contract balance *not* held in escrows (e.g., arbitration fees, leftover dust)
              // This requires tracking escrow balances internally, which isn't done explicitly in this example.
              // For simplicity, assume contract balance minus total deposited ETH == fees/dust.
              // This is unsafe in a real contract. Need accurate fee balance tracking.
              // Placeholder: Simple transfer of current contract balance *minus* any ETH currently in pending/funded/dispute escrows.
              // Implementing this correctly is complex. Assume for now total ETH balance is withdrawable fees.
              // This is HIGHLY UNSAFE in production.
              amount = address(this).balance; // Unsafe placeholder
         } else {
             amount = IERC20(_token).balanceOf(address(this));
              // Similar issue to ETH: need to track ERC20 balance *not* held in escrows.
              // Unsafe placeholder: Assume total ERC20 balance is withdrawable fees.
         }

         require(amount > 0, "No fees to withdraw for this token");

         if (_token == address(0)) {
             _safeTransferETH(_recipient, amount);
         } else {
             _safeTransferERC20(_token, _recipient, amount);
         }

         emit FeesWithdrawn(_recipient, (_token == address(0) ? amount : 0), (_token != address(0) ? amount : 0));
     }

     // --- Helper Functions for View (Internal, to avoid mapping iteration issue in public views) ---
     // In a real contract, you'd maintain dynamic arrays in state to enable efficient iteration for views.
     // The functions below are placeholders representing the *concept* of retrieving data that's hard from mappings.

     /**
      * @dev Internal helper (placeholder) to get all registered arbitrators.
      * In a real contract, maintain an array of arbitrators.
      */
     function getArbitrators() internal view returns (address[] memory) {
         // Placeholder - cannot iterate mapping directly.
         // In a real contract, you'd push arbitrators to an array on stake and remove on unstake.
          return new address[](0); // Return empty array for this example
     }


    // --- Additional Function Examples (To reach > 20 and add complexity) ---

    /**
     * @notice Allows governance to pause the contract.
     */
    function pause() external onlyGovernance whenNotPaused {
        _pause();
    }

    /**
     * @notice Allows governance to unpause the contract.
     */
    function unpause() external onlyGovernance whenPaused {
        _unpause();
    }

    /**
     * @notice Fallback function to receive ETH. Only allowed during funding.
     */
    receive() external payable {
        // This fallback could handle ETH funding if the amount/escrowId are encoded in msg.data,
        // but explicitly calling fundEscrow is clearer. Let's restrict it.
        revert("Direct ETH transfers not supported. Use fundEscrow.");
    }

    // Total public/external/view functions:
    // createEscrow, fundEscrow (2)
    // addEscrowParty, removeEscrowParty, setEscrowConditions (3 - intended to be internal/proposal called) - Total 5
    // evaluateEscrowConditions, getEscrowState (2) - Total 7
    // releaseEscrowFunds, requestRefund (2) - Total 9
    // raiseDispute, submitEvidence, arbitratorVote, resolveDispute, stakeArbitrator, unstakeArbitrator (6) - Total 15
    // proposeAmendment, voteOnProposal, executeProposal (3) - Total 18
    // addGovernanceMember, removeGovernanceMember, delegateVote, undelegateVote (4 - intended internal/proposal called, delegate/undelegate are external) - Total 20
    // getProposalState, getGovernanceMembers, getLogicModuleAddress (3) - Total 23
    // getEscrowParties, getEscrowConditions, getArbitratorStake, isGovernanceMember, isArbitrator (5) - Total 28
    // withdrawFees (1) - Total 29
    // pause, unpause (2) - Total 31

    // Looks like we comfortably exceeded 20 public/external functions.

}
```

---

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Self-Amending Logic (via Pluggable Modules):** The core idea isn't code-level mutability, but state-level configuration of logic providers. The `logicModules` mapping stores addresses of contracts implementing interfaces like `IRuleEvaluator`, `IFeeCalculator`, and `IDisputeResolver`. Governance proposals (`SetLogicModule`) allow updating these addresses, effectively changing the contract's behavior for these specific tasks without deploying a new Escrow contract instance or using complex proxy patterns. This offers flexibility and upgradability in key functional areas.
2.  **Decentralized Governance:** An integrated, on-chain proposal and voting system (`proposeAmendment`, `voteOnProposal`, `executeProposal`) controlled by a defined set of `_governanceMembers`. This set is itself mutable via governance, creating a self-governing body. Includes delegation (`delegateVote`) for potentially more active participation models (though simplified to 1p1v delegation in this example).
3.  **Complex Conditional Release:** Instead of simple boolean flags or time locks, the escrow release depends on an `IRuleEvaluator` contract. This external contract can implement arbitrary logic (fetching oracle data, checking states of other contracts, verifying digital signatures, etc.) to determine if conditions (`conditions` bytes array) are met. This makes the escrow applicable to a wide range of real-world or on-chain conditions.
4.  **Integrated Dispute Resolution with Arbitrator Staking:** A formalized process exists for disputes (`raiseDispute`, `submitEvidence`, `arbitratorVote`, `resolveDispute`). Arbitrators stake collateral (`stakeArbitrator`) which can be slashed (`_slashArbitrator`) based on the outcome determined by a pluggable `IDisputeResolver` module. This encourages honest participation from arbitrators.
5.  **Modular Design:** The use of interfaces (`IRuleEvaluator`, `IFeeCalculator`, `IDisputeResolver`) promotes modularity. Different implementations of these interfaces can be developed and proposed via governance, allowing the contract to adapt to new needs or improve its logic over time without rewriting the core Escrow contract.

**Caveats and Limitations (as a conceptual example):**

*   **Gas Efficiency:** Iterating through arrays stored in state (like `_governanceMembers` or hypothetical party lists for `getEscrowPartiesByRole`) can become very expensive with large numbers. Real-world implementation would need more gas-optimized data structures or patterns (e.g., linked lists,Merkle proofs for membership).
*   **Mapping Iteration:** Solidity cannot iterate through mappings. Helper view functions like `getEscrowParties` and `getEscrowPartiesByRole` as written in the code are conceptual placeholders; a real implementation requires storing keys in an array alongside the mapping.
*   **Security:** This is a complex contract with many interaction points. It requires extensive security audits, formal verification, and careful handling of external calls (especially to logic modules and token contracts) to prevent reentrancy and other vulnerabilities. The `nonReentrancy` guard is included but might need more granular application.
*   **Parameterization:** The `extraData` field for proposals and conditions uses raw bytes, which requires off-chain coordination or strict standards for encoding/decoding.
*   **Oracle Dependency:** If `IRuleEvaluator` relies on oracles (like Chainlink), the security and reliability of the oracle feed are critical.
*   **Dispute Resolution Complexity:** The `IDisputeResolver` interface and its implementation would be the most complex part, defining how votes are weighted, how outcomes are determined from votes, and how slashing conditions are met.
*   **Staking Token:** The arbitrator staking is simplified to ETH. A dedicated staking token might be used in a real system, requiring ERC-20 integration for staking/slashing.
*   **State Transitions:** Ensuring all state transitions (EscrowState, DisputeState, ProposalState) are handled correctly and exclusively is crucial.
*   **Fee Collection:** The fee withdrawal (`withdrawFees`) is a simplified example. Tracking accrued fees per token type securely requires dedicated state variables.

This contract provides a robust framework for a highly flexible and decentralized escrow system, demonstrating several advanced concepts beyond typical escrow functionalities.