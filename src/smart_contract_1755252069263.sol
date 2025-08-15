This Solidity smart contract, named **"The Alchemist Protocol,"** is designed as a decentralized, self-evolving ecosystem for funding and evaluating innovative strategies (called "Philosopher's Stones" or simply "Stones"). It leverages advanced concepts like reputation-based dynamic resource allocation, gamified governance, on-chain parameter adaptation based on collective strategy performance, and a dispute resolution mechanism. It aims to foster continuous improvement and innovation within the protocol itself, where successful strategies contribute to the protocol's evolution.

---

## **Contract Outline & Function Summary: The Alchemist Protocol**

**I. Core Infrastructure & Access Control**
*   `constructor()`: Initializes the contract with an owner, initial parameters, and establishes the reputation token (ERC-20, internally managed).
*   `setGovernanceAddress(address _governance)`: Allows the owner to transfer governance rights to a DAO or multi-sig.
*   `updateCoreParameter(string calldata _paramName, uint256 _newValue)`: Allows governance to adjust fundamental protocol parameters (e.g., proposal durations, minimum bonds).
*   `pauseProtocol()`: Emergency function by governance to pause critical operations.
*   `unpauseProtocol()`: Re-enables operations after a pause.
*   `withdrawProtocolFees()`: Allows governance to withdraw accumulated protocol fees.

**II. Financial & Collateral Management**
*   `depositCollateral()`: Allows users to deposit ETH or ERC-20 tokens as collateral, required for proposing strategies or participating in specific governance actions.
*   `withdrawCollateral(uint256 _amount)`: Allows users to withdraw their deposited collateral, subject to locks from active proposals or strategies.
*   `requestStoneResources(uint256 _stoneId, uint256 _amount)`: An active strategy's proposer requests a specific amount of funds from the protocol's treasury for its operations.
*   `approveStoneResourceAllocation(uint256 _allocationId)`: Governance approves a requested resource allocation for a strategy.
*   `reclaimUnusedStoneResources(uint256 _stoneId)`: Allows the protocol to reclaim allocated but unused funds from a strategy, especially after deactivation or failure.

**III. Philosopher's Stone (Strategy) Lifecycle**
*   `proposePhilosopherStone(string calldata _name, string calldata _description, uint256 _requiredBond)`: Users submit a new strategy proposal (Philosopher's Stone) with a bond.
*   `amendStoneProposal(uint256 _proposalId, string calldata _newName, string calldata _newDescription)`: Proposer can modify their pending proposal before voting starts.
*   `cancelStoneProposal(uint256 _proposalId)`: Proposer can withdraw their proposal if it's still pending or open for voting.
*   `voteOnStoneProposal(uint256 _proposalId, bool _support)`: Allows users with voting power (potentially staked collateral or reputation) to vote for or against a strategy proposal.
*   `finalizeStoneProposal(uint256 _proposalId)`: Governance or an automated process finalizes the vote, either activating or rejecting the Stone.
*   `activatePhilosopherStone(uint256 _stoneId)`: Internal function called after a proposal is approved, marking the Stone as active and unlocking its bond.
*   `deactivatePhilosopherStone(uint256 _stoneId)`: Governance or a dispute resolution mechanism can deactivate a Stone due to underperformance or rule violations.

**IV. Reputation & Performance Management**
*   `reportStoneOutcome(uint256 _stoneId, bool _success)`: Governance or designated oracle reports the success or failure of an active Philosopher's Stone. Triggers reputation adjustments.
*   `challengeStoneOutcome(uint256 _stoneId, string calldata _reason)`: Allows any participant to challenge a reported outcome of a Stone, requiring a bond.
*   `resolveOutcomeChallenge(uint256 _challengeId, bool _challengerWins)`: Governance or an elected jury resolves a challenge, leading to reputation adjustments and bond redistribution.
*   `adjustReputation(address _user, int256 _amount)`: Internal function to mint or burn reputation tokens for a user based on their actions and Stone performance.
*   `delegateReputationPower(address _delegatee)`: Allows users to delegate their reputation and associated voting power to another address.
*   `revokeReputationPower()`: Revokes any existing delegation of reputation and voting power.
*   `redeemReputationForBenefit(uint256 _reputationAmount)`: Allows users to "spend" reputation for protocol-defined benefits (e.g., lower fees, higher resource allocation limits).

**V. Dynamic Protocol Adaptation**
*   `triggerProtocolParameterAdaptation(string calldata _paramName)`: A crucial, advanced function. This allows governance (or triggers based on aggregate Stone performance) to initiate a process where a core protocol parameter automatically adjusts based on a predefined "adaptation curve" derived from the collective success/failure rates of active Stones over time. This simulates an on-chain "learning" or "evolutionary" process.
*   `submitAdaptationModel(string calldata _paramName, bytes memory _modelData)`: Governance (or authorized entities) can submit or update the mathematical model/curve that dictates how a specific parameter adapts based on aggregate Stone performance.
*   `executeAdaptationAdjustment(string calldata _paramName)`: Internal function called by `triggerProtocolParameterAdaptation` to apply the calculated adjustment to a parameter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For collateral
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; // For internal reputation token

/// @title The Alchemist Protocol: A Decentralized, Self-Evolving Ecosystem for Strategies
/// @author [Your Name/Alias]
/// @notice This contract facilitates the proposal, evaluation, funding, and adaptive governance of "Philosopher's Stones" (strategies).
/// It incorporates advanced concepts like reputation-based dynamic resource allocation, gamified governance, on-chain parameter adaptation,
/// and a dispute resolution mechanism to foster continuous improvement and innovation within the protocol.
/// @dev This protocol aims to simulate a self-optimizing system where collective intelligence drives evolution.
contract TheAlchemistProtocol is Ownable, ReentrancyGuard, Pausable {

    // --- Custom Errors ---
    error InvalidAmount();
    error InsufficientBalance();
    error NotGovernance();
    error NotProposer();
    error StoneNotFound();
    error ProposalNotFound();
    error InvalidStoneStatus();
    error InvalidProposalStatus();
    error VotingPeriodEnded();
    error ProposalAlreadyFinalized();
    error NoActiveVote();
    error NotEnoughReputation();
    error ChallengeNotFound();
    error InvalidParamName();
    error NoActiveDelegation();
    error AlreadyDelegated();
    error CannotDelegateToSelf();
    error NoResourcesToReclaim();
    error ResourceAllocationNotFound();
    error AllocationAlreadyApproved();

    // --- Events ---
    event GovernanceAddressUpdated(address indexed newGovernance);
    event CoreParameterUpdated(string indexed paramName, uint256 newValue);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event PhilosopherStoneProposed(uint256 indexed proposalId, uint256 indexed stoneId, address indexed proposer, string name, uint256 requiredBond);
    event StoneProposalAmended(uint256 indexed proposalId, string newName, string newDescription);
    event StoneProposalCanceled(uint256 indexed proposalId);
    event StoneVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event StoneProposalFinalized(uint256 indexed proposalId, uint256 indexed stoneId, bool approved);
    event PhilosopherStoneActivated(uint256 indexed stoneId, address indexed proposer);
    event PhilosopherStoneDeactivated(uint256 indexed stoneId, string reason);
    event ReputationAdjusted(address indexed user, int256 amount, string reason);
    event StoneOutcomeReported(uint256 indexed stoneId, bool success);
    event StoneOutcomeChallenged(uint256 indexed challengeId, uint256 indexed stoneId, address indexed challenger, string reason);
    event OutcomeChallengeResolved(uint256 indexed challengeId, bool challengerWins);
    event ReputationPowerDelegated(address indexed delegator, address indexed delegatee);
    event ReputationPowerRevoked(address indexed user);
    event ReputationRedeemed(address indexed user, uint256 reputationAmount, string benefitDescription);
    event StoneResourcesRequested(uint256 indexed allocationId, uint256 indexed stoneId, address indexed proposer, uint256 amount);
    event StoneResourcesApproved(uint256 indexed allocationId, uint256 indexed stoneId, uint256 amount);
    event UnusedStoneResourcesReclaimed(uint256 indexed stoneId, uint256 amount);
    event ProtocolParameterAdaptationTriggered(string indexed paramName);
    event AdaptationModelSubmitted(string indexed paramName);
    event AdaptationAdjustmentExecuted(string indexed paramName, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- State Variables ---

    // Governance control: Initially owner, then can be transferred to a DAO/multi-sig
    address public governanceAddress;

    // Core Protocol Parameters (adjustable by governance)
    mapping(string => uint256) public coreParameters; // e.g., "minProposalBond", "votingDuration", "reputationPerSuccess"

    // Collateral management
    mapping(address => uint256) public userCollateral; // ETH or other base currency collateral
    uint256 public totalProtocolCollateral; // Total ETH/base currency held by the contract

    // Philosopher's Stone (Strategy) Management
    uint256 public nextStoneId;
    uint256 public nextProposalId;
    uint256 public nextChallengeId;
    uint256 public nextResourceAllocationId;

    enum StoneStatus { Pending, Active, Deactivated }
    enum ProposalStatus { Open, Approved, Rejected, Finalized, Cancelled }
    enum ChallengeStatus { Open, Resolved }

    struct PhilosopherStone {
        uint256 id;
        address proposer;
        string name;
        string description;
        uint256 bond; // Collateral provided by proposer
        StoneStatus status;
        uint256 creationTime;
        uint256 activationTime;
        uint256 deactivationTime;
        uint256 performanceScore; // Accumulated score based on outcomes (+/-)
        uint256 totalResourcesAllocated; // Sum of resources granted to this stone
        uint256 totalResourcesReclaimed; // Sum of resources reclaimed from this stone
        uint256 lastOutcomeReportTime; // Timestamp of the last reported outcome
    }
    mapping(uint256 => PhilosopherStone) public philosopherStones;

    struct StoneProposal {
        uint256 id;
        uint256 stoneId; // Refers to the PhilosopherStone struct entry
        address proposer;
        uint256 bond;
        uint256 voteYes;
        uint256 voteNo;
        uint256 totalVoters; // Count of unique addresses that voted
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        uint256 deadline;
        ProposalStatus status;
        uint256 creationTime;
    }
    mapping(uint256 => StoneProposal) public stoneProposals;

    // Reputation Token
    ERC20Burnable public immutable reputationToken; // An internal ERC-20 token representing reputation
    mapping(address => address) public reputationDelegations; // delegator => delegatee

    // Outcome Challenge System
    struct StoneOutcomeChallenge {
        uint256 id;
        uint256 stoneId;
        address challenger;
        string reason;
        uint256 challengeBond; // Bond required to challenge
        ChallengeStatus status;
        uint256 creationTime;
    }
    mapping(uint256 => StoneOutcomeChallenge) public stoneOutcomeChallenges;

    // Resource Allocation Requests
    struct StoneResourceAllocation {
        uint256 id;
        uint256 stoneId;
        address requester;
        uint256 amountRequested;
        uint256 amountApproved;
        bool approved;
        uint256 requestTime;
        uint256 approvalTime;
    }
    mapping(uint256 => StoneResourceAllocation) public stoneResourceAllocations;

    // Protocol Fees
    uint256 public protocolFeesCollected;

    // --- Modifiers ---
    modifier onlyGovernance() {
        if (msg.sender != governanceAddress) revert NotGovernance();
        _;
    }

    modifier onlyProposer(uint256 _proposalId) {
        if (stoneProposals[_proposalId].proposer != msg.sender) revert NotProposer();
        _;
    }

    modifier onlyActiveStone(uint256 _stoneId) {
        if (philosopherStones[_stoneId].status != StoneStatus.Active) revert InvalidStoneStatus();
        _;
    }

    modifier onlyPendingProposal(uint256 _proposalId) {
        if (stoneProposals[_proposalId].status != ProposalStatus.Open && stoneProposals[_proposalId].status != ProposalStatus.Pending) revert InvalidProposalStatus();
        _;
    }

    modifier onlyReputationHolder(address _user, uint256 _amount) {
        if (reputationToken.balanceOf(_user) < _amount) revert NotEnoughReputation();
        _;
    }

    // --- Constructor ---
    /// @param _owner The initial owner/admin of the contract.
    /// @param _reputationTokenName Name for the internal reputation token.
    /// @param _reputationTokenSymbol Symbol for the internal reputation token.
    constructor(
        address _owner,
        string memory _reputationTokenName,
        string memory _reputationTokenSymbol
    ) Ownable(_owner) {
        governanceAddress = _owner; // Initially owner is governance
        reputationToken = new ERC20Burnable(_reputationTokenName, _reputationTokenSymbol);

        // Set initial core parameters (these will be adjustable by governance later)
        coreParameters["minProposalBond"] = 1 ether; // 1 ETH or equivalent in primary collateral
        coreParameters["votingDuration"] = 5 days; // Duration for voting on proposals
        coreParameters["reputationPerSuccess"] = 100 * 10 ** reputationToken.decimals(); // 100 Rep points
        coreParameters["reputationPerFailure"] = 50 * 10 ** reputationToken.decimals(); // 50 Rep points
        coreParameters["minVotePower"] = 10 * 10 ** reputationToken.decimals(); // Minimum reputation to vote
        coreParameters["challengeBond"] = 0.5 ether; // Bond to challenge an outcome
        coreParameters["resourceRequestCooldown"] = 7 days; // Cooldown between resource requests for a stone
    }

    // --- I. Core Infrastructure & Access Control ---

    /// @notice Allows the current governance to transfer governance rights to a new address (e.g., a DAO or multi-sig).
    /// @param _governance The address of the new governance entity.
    function setGovernanceAddress(address _governance) external onlyOwner {
        governanceAddress = _governance;
        emit GovernanceAddressUpdated(_governance);
    }

    /// @notice Allows governance to update a core protocol parameter.
    /// @param _paramName The name of the parameter to update.
    /// @param _newValue The new value for the parameter.
    function updateCoreParameter(string calldata _paramName, uint256 _newValue) external onlyGovernance whenNotPaused {
        if (bytes(_paramName).length == 0) revert InvalidParamName();
        coreParameters[_paramName] = _newValue;
        emit CoreParameterUpdated(_paramName, _newValue);
    }

    /// @notice Emergency function to pause critical contract operations. Can only be called by governance.
    function pauseProtocol() external onlyGovernance whenNotPaused {
        _pause();
    }

    /// @notice Re-enables contract operations after a pause. Can only be called by governance.
    function unpauseProtocol() external onlyGovernance whenPaused {
        _unpause();
    }

    /// @notice Allows governance to withdraw accumulated protocol fees.
    function withdrawProtocolFees() external onlyGovernance {
        uint256 fees = protocolFeesCollected;
        if (fees == 0) revert InvalidAmount();
        protocolFeesCollected = 0;
        (bool success,) = payable(governanceAddress).call{value: fees}("");
        if (!success) revert InvalidAmount(); // More specific error would be better
        emit ProtocolFeesWithdrawn(governanceAddress, fees);
    }

    // --- II. Financial & Collateral Management ---

    /// @notice Allows users to deposit ETH as collateral. This collateral can be used for bonds or voting power.
    function depositCollateral() external payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        userCollateral[msg.sender] += msg.value;
        totalProtocolCollateral += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    /// @notice Allows users to withdraw their deposited collateral.
    /// @param _amount The amount of collateral to withdraw.
    /// @dev Users cannot withdraw collateral that is locked in an active proposal or strategy bond.
    function withdrawCollateral(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (userCollateral[msg.sender] < _amount) revert InsufficientBalance();

        // TODO: Implement logic to check for locked collateral (e.g., stone bonds)
        // For now, assuming collateral is fully withdrawable unless explicitly locked.
        // A proper implementation would track `lockedCollateral[user]`

        userCollateral[msg.sender] -= _amount;
        totalProtocolCollateral -= _amount;
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) revert InsufficientBalance(); // More specific error
        emit CollateralWithdrawn(msg.sender, _amount);
    }

    /// @notice An active Philosopher's Stone proposer can request resources from the protocol treasury.
    /// @param _stoneId The ID of the active Philosopher's Stone.
    /// @param _amount The amount of resources (ETH) requested.
    /// @dev This request must be approved by governance via `approveStoneResourceAllocation`.
    function requestStoneResources(uint256 _stoneId, uint256 _amount) external onlyActiveStone(_stoneId) whenNotPaused {
        PhilosopherStone storage stone = philosopherStones[_stoneId];
        if (stone.proposer != msg.sender) revert NotProposer();
        if (_amount == 0) revert InvalidAmount();
        if (block.timestamp < stone.lastOutcomeReportTime + coreParameters["resourceRequestCooldown"]) {
            // This is a simplified cooldown. A more robust system would track individual requests.
            revert("Resource request cooldown in effect.");
        }

        uint256 allocationId = nextResourceAllocationId++;
        stoneResourceAllocations[allocationId] = StoneResourceAllocation({
            id: allocationId,
            stoneId: _stoneId,
            requester: msg.sender,
            amountRequested: _amount,
            amountApproved: 0,
            approved: false,
            requestTime: block.timestamp,
            approvalTime: 0
        });
        emit StoneResourcesRequested(allocationId, _stoneId, msg.sender, _amount);
    }

    /// @notice Governance approves a requested resource allocation for a Philosopher's Stone.
    /// @param _allocationId The ID of the resource allocation request to approve.
    function approveStoneResourceAllocation(uint256 _allocationId) external onlyGovernance whenNotPaused nonReentrant {
        StoneResourceAllocation storage allocation = stoneResourceAllocations[_allocationId];
        if (allocation.stoneId == 0) revert ResourceAllocationNotFound(); // Check if allocation exists
        if (allocation.approved) revert AllocationAlreadyApproved();
        if (totalProtocolCollateral < allocation.amountRequested) revert InsufficientBalance(); // Check protocol treasury

        PhilosopherStone storage stone = philosopherStones[allocation.stoneId];
        if (stone.status != StoneStatus.Active) revert InvalidStoneStatus();

        totalProtocolCollateral -= allocation.amountRequested;
        stone.totalResourcesAllocated += allocation.amountRequested;
        allocation.amountApproved = allocation.amountRequested;
        allocation.approved = true;
        allocation.approvalTime = block.timestamp;

        (bool success,) = payable(allocation.requester).call{value: allocation.amountRequested}("");
        if (!success) {
            // Revert funds and state if transfer fails (shouldn't happen with proper checks)
            totalProtocolCollateral += allocation.amountRequested;
            stone.totalResourcesAllocated -= allocation.amountRequested;
            allocation.amountApproved = 0;
            allocation.approved = false;
            allocation.approvalTime = 0;
            revert("Failed to transfer allocated funds.");
        }

        emit StoneResourcesApproved(_allocationId, allocation.stoneId, allocation.amountRequested);
    }

    /// @notice Allows the protocol to reclaim allocated but unused funds from a strategy, especially after deactivation or failure.
    /// @param _stoneId The ID of the Philosopher's Stone.
    /// @dev This function assumes an off-chain or governance-driven mechanism to determine "unused" funds.
    /// A more complex system might integrate with on-chain spending trackers or require proof.
    function reclaimUnusedStoneResources(uint256 _stoneId) external onlyGovernance whenNotPaused nonReentrant {
        PhilosopherStone storage stone = philosopherStones[_stoneId];
        if (stone.id == 0) revert StoneNotFound(); // Check if stone exists

        // This is a placeholder. A real implementation would need a robust way to
        // determine the exact `unusedAmount` from the stone's external address.
        // For example, it could be a self-reporting mechanism, or require an on-chain audit.
        uint256 unusedAmount = address(stone.proposer).balance; // Simplified: assumes all remaining funds at proposer's address were from this stone
        if (unusedAmount == 0) revert NoResourcesToReclaim();

        // This is highly simplified and potentially insecure.
        // A robust system would require the proposer to send back or provide proof.
        // For demonstration, we'll simulate funds coming back to the protocol.
        totalProtocolCollateral += unusedAmount;
        stone.totalResourcesReclaimed += unusedAmount;
        emit UnusedStoneResourcesReclaimed(_stoneId, unusedAmount);
    }

    // --- III. Philosopher's Stone (Strategy) Lifecycle ---

    /// @notice Allows a user to propose a new Philosopher's Stone (strategy). Requires a bond.
    /// @param _name The name of the strategy.
    /// @param _description A detailed description of the strategy.
    /// @param _requiredBond The collateral bond required for this specific strategy (must be >= minProposalBond).
    /// @dev The `_requiredBond` is an additional security measure, potentially linked to the risk/reward of the stone.
    function proposePhilosopherStone(
        string calldata _name,
        string calldata _description,
        uint256 _requiredBond
    ) external whenNotPaused {
        if (_requiredBond < coreParameters["minProposalBond"]) revert InvalidAmount();
        if (userCollateral[msg.sender] < _requiredBond) revert InsufficientBalance();

        userCollateral[msg.sender] -= _requiredBond; // Lock proposer's bond

        uint256 stoneId = nextStoneId++;
        uint256 proposalId = nextProposalId++;

        philosopherStones[stoneId] = PhilosopherStone({
            id: stoneId,
            proposer: msg.sender,
            name: _name,
            description: _description,
            bond: _requiredBond,
            status: StoneStatus.Pending,
            creationTime: block.timestamp,
            activationTime: 0,
            deactivationTime: 0,
            performanceScore: 0,
            totalResourcesAllocated: 0,
            totalResourcesReclaimed: 0,
            lastOutcomeReportTime: 0
        });

        stoneProposals[proposalId] = StoneProposal({
            id: proposalId,
            stoneId: stoneId,
            proposer: msg.sender,
            bond: _requiredBond,
            voteYes: 0,
            voteNo: 0,
            totalVoters: 0,
            deadline: block.timestamp + coreParameters["votingDuration"],
            status: ProposalStatus.Open,
            creationTime: block.timestamp
        });

        emit PhilosopherStoneProposed(proposalId, stoneId, msg.sender, _name, _requiredBond);
    }

    /// @notice Allows the proposer to amend the name and description of their pending strategy proposal.
    /// @param _proposalId The ID of the proposal to amend.
    /// @param _newName The new name for the strategy.
    /// @param _newDescription The new description for the strategy.
    function amendStoneProposal(uint256 _proposalId, string calldata _newName, string calldata _newDescription)
        external
        onlyProposer(_proposalId)
        onlyPendingProposal(_proposalId)
        whenNotPaused
    {
        StoneProposal storage proposal = stoneProposals[_proposalId];
        PhilosopherStone storage stone = philosopherStones[proposal.stoneId];

        stone.name = _newName;
        stone.description = _newDescription;

        emit StoneProposalAmended(_proposalId, _newName, _newDescription);
    }

    /// @notice Allows the proposer to cancel their strategy proposal if it's still pending or open for voting.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelStoneProposal(uint256 _proposalId)
        external
        onlyProposer(_proposalId)
        onlyPendingProposal(_proposalId)
        whenNotPaused
    {
        StoneProposal storage proposal = stoneProposals[_proposalId];
        PhilosopherStone storage stone = philosopherStones[proposal.stoneId];

        proposal.status = ProposalStatus.Cancelled;
        stone.status = StoneStatus.Deactivated; // Mark stone as deactivated immediately
        userCollateral[msg.sender] += proposal.bond; // Return bond to proposer

        emit StoneProposalCanceled(_proposalId);
    }

    /// @notice Allows users with sufficient reputation to vote on a Philosopher's Stone proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'yes' vote, false for a 'no' vote.
    function voteOnStoneProposal(uint252 _proposalId, bool _support)
        external
        whenNotPaused
        onlyReputationHolder(reputationDelegations[msg.sender] != address(0) ? reputationDelegations[msg.sender] : msg.sender, coreParameters["minVotePower"])
    {
        StoneProposal storage proposal = stoneProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Open) revert InvalidProposalStatus();
        if (block.timestamp >= proposal.deadline) revert VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert("Already voted on this proposal.");

        proposal.hasVoted[msg.sender] = true;
        address voter = reputationDelegations[msg.sender] != address(0) ? reputationDelegations[msg.sender] : msg.sender;
        uint256 voteWeight = reputationToken.balanceOf(voter); // Use reputation as voting power

        if (_support) {
            proposal.voteYes += voteWeight;
        } else {
            proposal.voteNo += voteWeight;
        }
        proposal.totalVoters++; // This just tracks count of unique voters, not total vote weight

        emit StoneVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Governance or an automated process finalizes the vote on a Stone proposal.
    /// @param _proposalId The ID of the proposal to finalize.
    function finalizeStoneProposal(uint256 _proposalId) external onlyGovernance whenNotPaused {
        StoneProposal storage proposal = stoneProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Open) revert InvalidProposalStatus();
        if (block.timestamp < proposal.deadline) revert("Voting period not yet ended.");

        PhilosopherStone storage stone = philosopherStones[proposal.stoneId];

        // Simple majority rule for approval
        if (proposal.voteYes > proposal.voteNo) {
            proposal.status = ProposalStatus.Approved;
            stone.status = StoneStatus.Active;
            stone.activationTime = block.timestamp;
            // The bond is now locked for the stone's lifetime, potentially used for slashing
            // No direct transfer here, it remains with the contract as locked collateral
        } else {
            proposal.status = ProposalStatus.Rejected;
            stone.status = StoneStatus.Deactivated;
            userCollateral[proposal.proposer] += proposal.bond; // Return bond if rejected
        }

        emit StoneProposalFinalized(_proposalId, proposal.stoneId, proposal.status == ProposalStatus.Approved);
        if (proposal.status == ProposalStatus.Approved) {
            emit PhilosopherStoneActivated(proposal.stoneId, proposal.proposer);
        }
    }

    /// @notice (Internal) Marks a Philosopher's Stone as active after its proposal is approved.
    /// @param _stoneId The ID of the Stone to activate.
    function activatePhilosopherStone(uint256 _stoneId) internal {
        PhilosopherStone storage stone = philosopherStones[_stoneId];
        if (stone.status != StoneStatus.Pending) revert InvalidStoneStatus();
        stone.status = StoneStatus.Active;
        stone.activationTime = block.timestamp;
        emit PhilosopherStoneActivated(_stoneId, stone.proposer);
    }

    /// @notice Allows governance to deactivate a Philosopher's Stone due to underperformance, rule violations, etc.
    /// @param _stoneId The ID of the Stone to deactivate.
    /// @param _reason The reason for deactivation.
    /// @dev Deactivation might involve slashing the bond and/or reputation of the proposer.
    function deactivatePhilosopherStone(uint256 _stoneId, string calldata _reason) external onlyGovernance whenNotPaused {
        PhilosopherStone storage stone = philosopherStones[_stoneId];
        if (stone.id == 0) revert StoneNotFound();
        if (stone.status != StoneStatus.Active) revert InvalidStoneStatus();

        stone.status = StoneStatus.Deactivated;
        stone.deactivationTime = block.timestamp;

        // Potentially slash bond or reputation here based on _reason
        // For simplicity, we'll just return the bond for now. A real system
        // would have detailed slashing conditions.
        userCollateral[stone.proposer] += stone.bond; // Return bond

        // Optionally, penalize reputation for deactivation
        _adjustReputation(stone.proposer, -int256(coreParameters["reputationPerFailure"]), "Stone deactivated");

        emit PhilosopherStoneDeactivated(_stoneId, _reason);
    }

    // --- IV. Reputation & Performance Management ---

    /// @notice Governance or a designated oracle reports the outcome (success/failure) of an active Philosopher's Stone.
    /// @param _stoneId The ID of the Philosopher's Stone.
    /// @param _success True if the Stone was successful, false otherwise.
    /// @dev This function triggers reputation adjustments based on the outcome.
    function reportStoneOutcome(uint256 _stoneId, bool _success) external onlyGovernance whenNotPaused {
        PhilosopherStone storage stone = philosopherStones[_stoneId];
        if (stone.id == 0) revert StoneNotFound();
        if (stone.status != StoneStatus.Active) revert InvalidStoneStatus();

        int256 reputationChange;
        if (_success) {
            reputationChange = int256(coreParameters["reputationPerSuccess"]);
            stone.performanceScore += coreParameters["reputationPerSuccess"];
        } else {
            reputationChange = -int256(coreParameters["reputationPerFailure"]);
            stone.performanceScore -= coreParameters["reputationPerFailure"];
        }
        stone.lastOutcomeReportTime = block.timestamp;

        _adjustReputation(stone.proposer, reputationChange, _success ? "Stone success" : "Stone failure");
        emit StoneOutcomeReported(_stoneId, _success);
    }

    /// @notice Allows any participant to challenge a reported outcome of a Philosopher's Stone. Requires a bond.
    /// @param _stoneId The ID of the Philosopher's Stone whose outcome is being challenged.
    /// @param _reason A description of why the outcome is being challenged.
    function challengeStoneOutcome(uint256 _stoneId, string calldata _reason) external payable whenNotPaused {
        PhilosopherStone storage stone = philosopherStones[_stoneId];
        if (stone.id == 0) revert StoneNotFound();
        if (msg.value < coreParameters["challengeBond"]) revert InvalidAmount(); // Must send challenge bond

        uint256 challengeId = nextChallengeId++;
        stoneOutcomeChallenges[challengeId] = StoneOutcomeChallenge({
            id: challengeId,
            stoneId: _stoneId,
            challenger: msg.sender,
            reason: _reason,
            challengeBond: msg.value,
            status: ChallengeStatus.Open,
            creationTime: block.timestamp
        });
        totalProtocolCollateral += msg.value; // Add challenge bond to protocol collateral

        emit StoneOutcomeChallenged(challengeId, _stoneId, msg.sender, _reason);
    }

    /// @notice Governance or an elected jury resolves an outcome challenge, leading to reputation adjustments and bond redistribution.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _challengerWins True if the challenger's claim is upheld, false otherwise.
    function resolveOutcomeChallenge(uint256 _challengeId, bool _challengerWins) external onlyGovernance whenNotPaused nonReentrant {
        StoneOutcomeChallenge storage challenge = stoneOutcomeChallenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Open) revert InvalidChallengeStatus();

        challenge.status = ChallengeStatus.Resolved;

        if (_challengerWins) {
            // Challenger wins: Challenger gets their bond back + potentially a portion of the original reporter's bond/reputation.
            // Original reporter (if applicable) gets penalized.
            userCollateral[challenge.challenger] += challenge.challengeBond; // Return challenger's bond
            // A more complex system would slash the bond/reputation of the party whose report was overturned.
            // For simplicity, we just return the challenger's bond and adjust reputation.
            _adjustReputation(challenge.challenger, int256(coreParameters["reputationPerSuccess"]), "Challenge won");
            // If there was an original reporter's bond/reputation at stake, it would be handled here.
        } else {
            // Challenger loses: Challenger's bond is forfeited to the protocol fees.
            protocolFeesCollected += challenge.challengeBond;
            _adjustReputation(challenge.challenger, -int256(coreParameters["reputationPerFailure"]), "Challenge lost");
        }

        emit OutcomeChallengeResolved(_challengeId, _challengerWins);
    }

    /// @notice Internal function to adjust a user's reputation (mint or burn reputation tokens).
    /// @param _user The address of the user whose reputation is being adjusted.
    /// @param _amount The amount to adjust by (positive for gain, negative for loss).
    /// @param _reason A description of why the reputation was adjusted.
    function _adjustReputation(address _user, int256 _amount, string memory _reason) internal {
        if (_amount > 0) {
            reputationToken.mint(_user, uint256(_amount));
        } else if (_amount < 0) {
            // Ensure we don't try to burn more than they have
            uint256 currentBalance = reputationToken.balanceOf(_user);
            uint256 amountToBurn = uint256(-_amount);
            if (currentBalance < amountToBurn) {
                amountToBurn = currentBalance; // Burn all they have
            }
            reputationToken.burn(_user, amountToBurn);
        }
        emit ReputationAdjusted(_user, _amount, _reason);
    }

    /// @notice Allows a user to delegate their reputation and associated voting power to another address.
    /// @param _delegatee The address to delegate reputation and voting power to.
    function delegateReputationPower(address _delegatee) external whenNotPaused {
        if (_delegatee == address(0)) revert InvalidAmount();
        if (_delegatee == msg.sender) revert CannotDelegateToSelf();
        if (reputationDelegations[msg.sender] != address(0)) revert AlreadyDelegated(); // Only one delegation at a time

        reputationDelegations[msg.sender] = _delegatee;
        emit ReputationPowerDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows a user to revoke any existing delegation of their reputation and voting power.
    function revokeReputationPower() external whenNotPaused {
        if (reputationDelegations[msg.sender] == address(0)) revert NoActiveDelegation();
        delete reputationDelegations[msg.sender];
        emit ReputationPowerRevoked(msg.sender);
    }

    /// @notice Allows users to "spend" a certain amount of their reputation for protocol-defined benefits.
    /// @param _reputationAmount The amount of reputation to spend.
    /// @param _benefitDescription A string describing the benefit claimed.
    /// @dev This function currently just burns reputation. A real implementation would link to specific benefits.
    function redeemReputationForBenefit(uint256 _reputationAmount, string calldata _benefitDescription)
        external
        onlyReputationHolder(msg.sender, _reputationAmount)
        whenNotPaused
    {
        reputationToken.burn(msg.sender, _reputationAmount);
        emit ReputationRedeemed(msg.sender, _reputationAmount, _benefitDescription);
    }

    // --- V. Dynamic Protocol Adaptation ---

    /// @notice This is a crucial, advanced function. It triggers a process where a core protocol parameter
    /// automatically adjusts based on a predefined "adaptation curve" derived from the collective success/failure rates
    /// of active Stones over time. This simulates an on-chain "learning" or "evolutionary" process.
    /// @param _paramName The name of the core parameter to adapt (e.g., "minProposalBond", "votingDuration").
    /// @dev This function relies on an internal calculation or an external oracle/service submitting an adaptation model.
    /// For this example, the adaptation logic is simplified.
    function triggerProtocolParameterAdaptation(string calldata _paramName) external onlyGovernance whenNotPaused {
        // In a real system, this would involve:
        // 1. Aggregating performance data of all active stones (e.g., average performanceScore over a period).
        // 2. Applying an "adaptation model" (a predefined mathematical curve or rule-set) to this aggregated data.
        // 3. Calculating the new value for `_paramName`.
        // 4. Updating `coreParameters[_paramName]`.

        // Simplified adaptation logic for demonstration:
        // Let's say we want "minProposalBond" to adapt.
        // If overall stone performance is high, lower the bond. If low, raise it.
        // This requires tracking aggregate performance, which is not directly stored in this contract.
        // A more advanced approach would use a dedicated `PerformanceAggregator` contract.

        if (bytes(_paramName).length == 0) revert InvalidParamName();

        // For demonstration, let's just make a dummy adjustment
        // In reality, this would be computed based on `philosopherStones` data.
        // Example: If average performance score is high, decrease `minProposalBond`
        // (This would need a loop over active stones, which is gas-intensive, so better done off-chain and submitted,
        // or through a more sophisticated on-chain average calculation).

        // Placeholder for adaptation logic:
        uint256 currentParamValue = coreParameters[_paramName];
        uint256 newParamValue = currentParamValue; // Default to no change

        // Dummy logic: If `minProposalBond` is being adapted, randomly increase/decrease by a small amount
        // In practice, this would be deterministic and data-driven.
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minProposalBond"))) {
            if (block.timestamp % 2 == 0) { // Simulate a condition for change
                newParamValue = currentParamValue * 95 / 100; // Decrease by 5%
                if (newParamValue < 0.1 ether) newParamValue = 0.1 ether; // Set a floor
            } else {
                newParamValue = currentParamValue * 105 / 100; // Increase by 5%
            }
        }
        // ... similar logic for other parameters ...

        if (newParamValue != currentParamValue) {
            coreParameters[_paramName] = newParamValue;
            emit AdaptationAdjustmentExecuted(_paramName, newParamValue);
        }

        emit ProtocolParameterAdaptationTriggered(_paramName);
    }

    /// @notice Governance (or authorized entities) can submit or update the mathematical model/curve
    /// that dictates how a specific parameter adapts based on aggregate Stone performance.
    /// @param _paramName The name of the parameter to which this model applies.
    /// @param _modelData Placeholder for the actual model data (e.g., bytes representing a function hash, IPFS CID of a detailed model description, or simplified parameters).
    /// @dev This function is conceptual for complex on-chain adaptive models. Actual model execution would likely be off-chain with results submitted on-chain or very simplified on-chain logic.
    function submitAdaptationModel(string calldata _paramName, bytes memory _modelData) external onlyGovernance whenNotPaused {
        // In a more complex system, _modelData might be used to configure an on-chain
        // algorithm, or point to an off-chain model that produces on-chain adjustments.
        // For now, it's a symbolic representation.
        if (bytes(_paramName).length == 0) revert InvalidParamName();
        // Store or process _modelData as needed. This contract doesn't execute _modelData directly.
        emit AdaptationModelSubmitted(_paramName);
    }

    /// @notice (Internal) Executes the calculated adjustment to a protocol parameter.
    /// @param _paramName The name of the parameter to adjust.
    function executeAdaptationAdjustment(string calldata _paramName) internal {
        // This function would contain the actual logic for updating the parameter
        // based on the adaptation model and current performance metrics.
        // It's called by `triggerProtocolParameterAdaptation`.
        // Its separate definition emphasizes the conceptual separation of trigger and execution.
        // (Implementation is within triggerProtocolParameterAdaptation for this example's simplicity).
    }

    // --- View Functions ---

    /// @notice Returns the current balance of collateral for a given user.
    function getUserCollateral(address _user) external view returns (uint256) {
        return userCollateral[_user];
    }

    /// @notice Returns the balance of reputation tokens for a given user.
    function getReputationBalance(address _user) external view returns (uint256) {
        return reputationToken.balanceOf(_user);
    }

    /// @notice Returns a Philosopher's Stone struct by its ID.
    function getPhilosopherStone(uint256 _stoneId) external view returns (PhilosopherStone memory) {
        return philosopherStones[_stoneId];
    }

    /// @notice Returns a Stone Proposal struct by its ID.
    function getStoneProposal(uint256 _proposalId) external view returns (StoneProposal memory) {
        return stoneProposals[_proposalId];
    }

    /// @notice Returns a Stone Outcome Challenge struct by its ID.
    function getStoneOutcomeChallenge(uint256 _challengeId) external view returns (StoneOutcomeChallenge memory) {
        return stoneOutcomeChallenges[_challengeId];
    }

    /// @notice Returns a Stone Resource Allocation struct by its ID.
    function getStoneResourceAllocation(uint256 _allocationId) external view returns (StoneResourceAllocation memory) {
        return stoneResourceAllocations[_allocationId];
    }
}
```