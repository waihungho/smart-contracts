Here's a smart contract written in Solidity, incorporating advanced concepts like an AI Oracle for adaptive parameters, a non-transferable reputation system (SBT-like), delegated conviction voting, and decentralized proposal management for "intellectual assets." The goal is to create a dynamic, self-evolving governance system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol"; // For uint256.mulDiv

// --- Interfaces ---

/**
 * @title IAIOracle
 * @dev Interface for an AI Oracle that provides recommendations or triggers for EchelonForge.
 *      In a real-world scenario, this would likely be a Chainlink AI Oracle or a similar decentralized AI service.
 */
interface IAIOracle {
    /**
     * @dev Returns a new adaptive fee rate recommendation in basis points.
     *      e.g., 100 for 1%, 50 for 0.5%.
     */
    function getAdaptiveFeeRecommendation() external view returns (uint256);

    /**
     * @dev Returns a new reputation reward rate recommendation in basis points.
     *      e.g., 1000 for 10 reputation points, representing how much reputation is
     *      awarded per unit of contribution quality.
     */
    function getContributionRewardRecommendation() external view returns (uint256);

    /**
     * @dev Returns true if an emergency protocol brake is recommended by the AI.
     *      This could be based on detected anomalies, security threats, or market instability.
     */
    function getEmergencyBrakeSignal() external view returns (bool);
}

/**
 * @title EchelonForge
 * @dev A decentralized protocol for collaborative intelligence and adaptive governance.
 *      Users earn non-transferable reputation (SBT-like points) for contributing "intellectual assets"
 *      (e.g., proposals, research reviews). This reputation influences their governance power
 *      via a delegated conviction voting mechanism. An integrated AI oracle dynamically
 *      adjusts core protocol parameters (fees, contribution rewards) to optimize ecosystem
 *      health, responsiveness, and resilience, and can trigger emergency safeguards.
 *
 *      The contract aims for uniqueness by combining these advanced features into a cohesive
 *      protocol, rather than just implementing a single popular pattern (e.g., simple DAO, NFT, DeFi pool).
 *      It focuses on evolving governance and incentivized, quality-driven contributions.
 */
contract EchelonForge is Ownable, Pausable, ReentrancyGuard {
    using SafeCast for uint256; // Enables .mulDiv() for safer arithmetic with basis points

    // --- Outline & Function Summary ---

    // I. Core Infrastructure & Access Control
    //    1.  constructor: Initializes the contract with an owner, AI Oracle address, and an emergency guardian.
    //    2.  setAIOracleAddress: Sets or updates the address of the AI Oracle (Owner only).
    //    3.  pauseProtocol: Pauses critical protocol functions, preventing most state-changing operations (Owner/Guardian only).
    //    4.  unpauseProtocol: Unpauses critical protocol functions, restoring normal operations (Owner/Guardian only).
    //    5.  setGuardian: Sets an address authorized to pause/unpause the protocol in emergencies (Owner only).
    //    6.  transferOwnership: Transfers contract ownership to a new address (inherited from OpenZeppelin's Ownable).

    // II. Reputation & Delegation System (Non-transferable "Soulbound" points)
    //    7.  delegateReputation: Allows a user to delegate their reputation's voting power to another address.
    //    8.  undelegateReputation: Allows a user to revoke their active reputation delegation.
    //    9.  getReputationBalance: Returns the total effective reputation points of a given address, including any points delegated to it.
    //    10. getEffectiveVotingPower: Calculates an address's current voting power, considering its total reputation and a user-specified conviction duration for a vote.

    // III. Dynamic Parameters & AI Oracle Interaction
    //    11. updateAdaptiveFeeRate: Called exclusively by the AI Oracle to adjust the protocol's ETH fee rate for new proposals.
    //    12. updateContributionRewardRate: Called exclusively by the AI Oracle to adjust the reputation reward rate for constructive reviews.
    //    13. getAdaptiveFeeRate: Returns the current adaptive fee rate in basis points.
    //    14. getContributionRewardRate: Returns the current reputation reward rate for contributions in basis points.

    // IV. Decentralized Proposal & Conviction Voting
    //    15. submitProposal: Allows users with sufficient reputation to submit a new "intellectual asset" proposal, requiring an ETH deposit.
    //    16. reviewProposal: Allows qualified users to review a pending proposal, earning reputation points for their constructive input.
    //    17. voteOnProposal: Allows users to cast a 'yay' or 'nay' vote on an active proposal, with voting power dynamically adjusted by a conviction duration.
    //    18. executeProposal: Processes a proposal after its voting period and execution delay, marking it as Succeeded, Failed, or Executed.
    //    19. withdrawProposalDeposit: Allows a proposer to reclaim their initial ETH deposit after a proposal's lifecycle is complete (succeeded, failed, or executed).

    // V. Emergency & Protocol Management
    //    20. emergencyBrakeProtocol: Initiates an immediate, AI Oracle-triggered pause of the protocol in response to critical signals.
    //    21. collectProtocolFees: Allows the owner (or authorized treasury) to collect accumulated ETH protocol fees.
    //    22. setProposalThreshold: Sets the minimum reputation required to submit a proposal (governance-controlled).
    //    23. setReviewThreshold: Sets the minimum reputation required to review a proposal (governance-controlled).
    //    24. setMinVotingConvictionPeriod: Sets the minimum time (in seconds) for reputation commitment to achieve full conviction weight in voting (governance-controlled).
    //    25. receive() fallback: Handles direct ETH transfers to the contract, adding them to accumulated protocol fees.

    // --- State Variables ---

    IAIOracle public aiOracle;            // Address of the AI Oracle contract
    address public guardian;              // An address authorized to pause/unpause in emergencies (besides owner)

    // Reputation System: Non-transferable "Soulbound" points
    mapping(address => uint256) public reputationPoints;
    mapping(address => address) public delegates;           // Mapping from delegator to delegatee
    mapping(address => uint256) public delegatedReputation; // Amount of reputation delegated *to* an address

    // Protocol Parameters (adjustable by AI Oracle or Governance)
    uint256 public adaptiveFeeRateBp;        // Protocol fee rate in basis points (e.g., 50 for 0.5%)
    uint256 public contributionRewardRateBp; // Reputation points awarded per review score point (e.g., 1000 for 10 points)
    uint256 public proposalThreshold;        // Minimum reputation to submit a proposal
    uint256 public reviewThreshold;          // Minimum reputation to review a proposal
    uint256 public minVotingConvictionPeriod; // Time (in seconds) for reputation to gain full conviction weight

    // Proposal Management Constants
    uint256 public nextProposalId;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;      // How long proposals are open for voting
    uint256 public constant PROPOSAL_EXECUTION_DELAY = 2 days;    // Delay after voting ends before execution can occur
    uint256 public constant MIN_PROPOSAL_DEPOSIT = 0.1 ether;     // Minimum ETH deposit required for a proposal
    uint256 public constant MAX_CONVICTION_DURATION = 30 days;    // Max commitment duration for full conviction bonus in voting

    // Enum to define the lifecycle states of a proposal
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Withdrawn }

    // Struct to hold details of each proposal
    struct Proposal {
        address proposer;
        uint256 deposit;            // ETH deposit made by the proposer (reduced by protocol fee)
        uint256 submissionTime;
        uint256 votingEndTime;      // Timestamp when voting period ends
        uint256 executionTime;      // Timestamp when the proposal can be executed
        bytes32 contentHash;        // IPFS hash or similar for detailed proposal content
        uint256 yayVotes;           // Total weighted 'yay' votes
        uint256 nayVotes;           // Total weighted 'nay' votes
        uint256 totalReputationAtSnapshot; // Sum of all *effective voting power* cast for this proposal
        mapping(address => bool) hasVoted;    // Tracks if an address has already voted on this proposal
        mapping(address => bool) hasReviewed; // Tracks if an address has already reviewed this proposal
        uint256 reviewScoreSum;     // Sum of scores from all reviews
        uint256 reviewerCount;      // Number of unique reviewers
        ProposalState state;
    }
    mapping(uint256 => Proposal) public proposals;

    uint256 public totalProtocolFees; // Accumulated ETH from proposal fees and direct transfers

    // --- Events ---
    event AIOracleAddressUpdated(address indexed newAIOracle);
    event GuardianUpdated(address indexed newGuardian);
    event ReputationMinted(address indexed recipient, uint256 amount);
    event ReputationBurned(address indexed holder, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator, address indexed previousDelegatee);
    event AdaptiveFeeRateUpdated(uint256 newRateBp);
    event ContributionRewardRateUpdated(uint256 newRateBp);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 contentHash, uint256 initialDeposit);
    event ProposalReviewed(uint256 indexed proposalId, address indexed reviewer, uint256 reviewScore, uint256 reputationAwarded);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool isYay, uint256 effectiveVotingPower, uint256 convictionDuration);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalDepositWithdrawn(uint256 indexed proposalId, address indexed proposer, uint256 amount);
    event EmergencyBrakeActivated(address indexed triggeredBy);
    event ProtocolFeeCollected(address indexed collector, uint256 amount);
    event ProposalThresholdUpdated(uint256 newThreshold);
    event ReviewThresholdUpdated(uint256 newThreshold);
    event MinVotingConvictionPeriodUpdated(uint256 newPeriod);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "EchelonForge: Caller is not the AI oracle");
        _;
    }

    modifier onlyGuardianOrOwner() {
        require(msg.sender == owner() || msg.sender == guardian, "EchelonForge: Caller is not owner or guardian");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the EchelonForge contract.
     * @param _aiOracle The address of the AI Oracle contract.
     * @param _guardian An address designated as an emergency guardian to pause/unpause.
     */
    constructor(address _aiOracle, address _guardian) Ownable(msg.sender) Pausable() {
        require(_aiOracle != address(0), "EchelonForge: AI Oracle cannot be zero address");
        require(_guardian != address(0), "EchelonForge: Guardian cannot be zero address");

        aiOracle = IAIOracle(_aiOracle);
        guardian = _guardian;

        // Set initial protocol parameters
        adaptiveFeeRateBp = 50;   // 0.5% fee on proposal deposits
        contributionRewardRateBp = 1000; // 10 reputation points per score point (e.g., score 5 -> 50 rep)
        proposalThreshold = 1000; // 1000 reputation points to submit a proposal
        reviewThreshold = 500;    // 500 reputation points to review a proposal
        minVotingConvictionPeriod = 7 days; // 7 days commitment for full conviction bonus

        nextProposalId = 1; // Initialize proposal ID counter

        emit AIOracleAddressUpdated(_aiOracle);
        emit GuardianUpdated(_guardian);
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Sets or updates the address of the AI Oracle. Only callable by the contract owner.
     * @param _newAIOracle The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newAIOracle) external onlyOwner {
        require(_newAIOracle != address(0), "EchelonForge: AI Oracle cannot be zero address");
        aiOracle = IAIOracle(_newAIOracle);
        emit AIOracleAddressUpdated(_newAIOracle);
    }

    /**
     * @dev Pauses critical protocol functions. Callable by the owner or the designated guardian.
     *      Prevents most state-changing user interactions during emergencies.
     */
    function pauseProtocol() external onlyGuardianOrOwner {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses critical protocol functions. Callable by the owner or the designated guardian.
     *      Restores normal operations after an emergency pause.
     */
    function unpauseProtocol() external onlyGuardianOrOwner {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @dev Sets an address authorized to pause/unpause the protocol in emergencies. Only callable by the owner.
     * @param _newGuardian The new guardian address.
     */
    function setGuardian(address _newGuardian) external onlyOwner {
        require(_newGuardian != address(0), "EchelonForge: Guardian cannot be zero address");
        guardian = _newGuardian;
        emit GuardianUpdated(_newGuardian);
    }

    // `transferOwnership` is inherited from OpenZeppelin's Ownable contract, fulfilling function #6.

    // --- Internal Reputation Management Functions ---
    // These functions are intended for internal use by the contract logic, not direct user calls.

    /**
     * @dev Internally mints reputation points to a recipient.
     * @param _recipient The address to mint reputation for.
     * @param _amount The amount of reputation points to mint.
     */
    function _mintReputationInternal(address _recipient, uint256 _amount) internal {
        require(_recipient != address(0), "EchelonForge: Cannot mint to zero address");
        require(_amount > 0, "EchelonForge: Mint amount must be greater than zero");
        reputationPoints[_recipient] += _amount;
        emit ReputationMinted(_recipient, _amount);
    }

    /**
     * @dev Internally burns reputation points from a holder.
     * @param _holder The address to burn reputation from.
     * @param _amount The amount of reputation points to burn.
     */
    function _burnReputationInternal(address _holder, uint256 _amount) internal {
        require(_holder != address(0), "EchelonForge: Cannot burn from zero address");
        require(_amount > 0, "EchelonForge: Burn amount must be greater than zero");
        require(reputationPoints[_holder] >= _amount, "EchelonForge: Insufficient reputation to burn");
        reputationPoints[_holder] -= _amount;
        // Note: This does not automatically update `delegatedReputation` if the burned reputation was delegated.
        // The `getReputationBalance` and `getEffectiveVotingPower` functions dynamically recalculate,
        // so inconsistencies in `delegatedReputation` for a delegatee will be overridden by the delegator's actual balance.
        emit ReputationBurned(_holder, _amount);
    }

    // --- II. Reputation & Delegation System ---

    /**
     * @dev Allows a user to delegate their reputation's voting power to another address.
     *      A user can only delegate their power to one address at a time.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateReputation(address _delegatee) external nonReentrant whenNotPaused {
        require(_delegatee != address(0), "EchelonForge: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "EchelonForge: Cannot delegate to self");

        address currentDelegatee = delegates[msg.sender];
        if (currentDelegatee != address(0)) {
            // Remove previous delegation's effect
            delegatedReputation[currentDelegatee] -= reputationPoints[msg.sender];
        }

        delegates[msg.sender] = _delegatee;
        delegatedReputation[_delegatee] += reputationPoints[msg.sender];

        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows a user to revoke their active reputation delegation.
     */
    function undelegateReputation() external nonReentrant whenNotPaused {
        address currentDelegatee = delegates[msg.sender];
        require(currentDelegatee != address(0), "EchelonForge: No active delegation to undelegate");

        delegatedReputation[currentDelegatee] -= reputationPoints[msg.sender];
        delete delegates[msg.sender]; // Clear the delegation

        emit ReputationUndelegated(msg.sender, currentDelegatee);
    }

    /**
     * @dev Returns the total effective reputation points of a given address.
     *      This sum includes the address's own non-transferable points and any points
     *      that have been delegated *to* this address.
     * @param _addr The address to query.
     * @return The total effective reputation points for governance.
     */
    function getReputationBalance(address _addr) public view returns (uint256) {
        return reputationPoints[_addr] + delegatedReputation[_addr];
    }

    /**
     * @dev Calculates an address's current effective voting power.
     *      This considers their total effective reputation (own + delegated-in)
     *      and a potential conviction multiplier based on the `_convictionDuration`
     *      the voter commits for a specific vote. Longer commitment, up to
     *      `MAX_CONVICTION_DURATION`, yields higher voting power.
     * @param _voter The address whose voting power is to be calculated.
     * @param _convictionDuration The duration (in seconds) the voter commits their
     *                            reputation for this specific vote.
     * @return The calculated effective voting power, weighted by conviction.
     */
    function getEffectiveVotingPower(address _voter, uint256 _convictionDuration) public view returns (uint256) {
        uint256 baseReputation = getReputationBalance(_voter);
        if (baseReputation == 0) return 0;

        uint256 actualConvictionDuration = _convictionDuration;
        if (actualConvictionDuration > MAX_CONVICTION_DURATION) {
            actualConvictionDuration = MAX_CONVICTION_DURATION;
        }

        // Conviction multiplier: ranges from 1x (no conviction) to 2x (full conviction).
        // Formula: baseReputation * (1 + (actualConvictionDuration / MAX_CONVICTION_DURATION))
        // Scaled by 1e18 to handle division with precision:
        // baseReputation * (1e18 + (actualConvictionDuration * 1e18 / MAX_CONVICTION_DURATION)) / 1e18
        uint256 multiplier = (uint256(1e18) + (actualConvictionDuration * 1e18 / MAX_CONVICTION_DURATION));
        return (baseReputation * multiplier) / 1e18;
    }

    // --- III. Dynamic Parameters & AI Oracle Interaction ---

    /**
     * @dev Adjusts the protocol's adaptive fee rate based on the AI Oracle's recommendation.
     *      This function is restricted to calls from the designated `aiOracle` address.
     * @param _newRateBp The new fee rate in basis points (e.g., 100 for 1%).
     */
    function updateAdaptiveFeeRate(uint256 _newRateBp) external onlyAIOracle {
        require(_newRateBp <= 1000, "EchelonForge: Fee rate cannot exceed 10%"); // Sanity check for max 10%
        adaptiveFeeRateBp = _newRateBp;
        emit AdaptiveFeeRateUpdated(_newRateBp);
    }

    /**
     * @dev Adjusts the reputation reward rate for contributions based on the AI Oracle's recommendation.
     *      This function is restricted to calls from the designated `aiOracle` address.
     * @param _newRateBp The new reputation reward rate in basis points (e.g., 1000 for 10 reputation points
     *                   per review score point).
     */
    function updateContributionRewardRate(uint256 _newRateBp) external onlyAIOracle {
        require(_newRateBp <= 10000, "EchelonForge: Reward rate cannot exceed 100 reputation points per score point"); // Sanity check
        contributionRewardRateBp = _newRateBp;
        emit ContributionRewardRateUpdated(_newRateBp);
    }

    /**
     * @dev Returns the current adaptive fee rate applied to new proposal deposits.
     * @return The current adaptive fee rate in basis points.
     */
    function getAdaptiveFeeRate() public view returns (uint256) {
        return adaptiveFeeRateBp;
    }

    /**
     * @dev Returns the current reputation reward rate applied to successful reviews.
     * @return The current contribution reward rate in basis points.
     */
    function getContributionRewardRate() public view returns (uint256) {
        return contributionRewardRateBp;
    }

    // --- IV. Decentralized Proposal & Conviction Voting ---

    /**
     * @dev Allows users to submit a new "intellectual asset" proposal.
     *      Requires the sender to have sufficient reputation and to send an ETH deposit.
     *      A portion of the deposit is collected as a protocol fee.
     * @param _contentHash An IPFS hash or similar identifier pointing to the proposal's detailed content.
     */
    function submitProposal(bytes32 _contentHash) external payable nonReentrant whenNotPaused {
        require(msg.value >= MIN_PROPOSAL_DEPOSIT, "EchelonForge: Insufficient deposit");
        require(getReputationBalance(msg.sender) >= proposalThreshold, "EchelonForge: Insufficient reputation to submit proposal");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        uint256 feeAmount = msg.value.mulDiv(adaptiveFeeRateBp, 10000); // Calculate fee
        totalProtocolFees += feeAmount; // Accumulate fee
        uint256 netDeposit = msg.value - feeAmount; // Net deposit remaining for the proposal

        newProposal.proposer = msg.sender;
        newProposal.deposit = netDeposit;
        newProposal.submissionTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + PROPOSAL_VOTING_PERIOD;
        newProposal.executionTime = newProposal.votingEndTime + PROPOSAL_EXECUTION_DELAY;
        newProposal.contentHash = _contentHash;
        newProposal.state = ProposalState.Pending; // Starts as Pending, moves to Active upon first vote

        emit ProposalSubmitted(proposalId, msg.sender, _contentHash, msg.value);
    }

    /**
     * @dev Allows users with sufficient reputation to review a pending proposal,
     *      earning reputation points for their constructive input. A user can only review a proposal once.
     * @param _proposalId The ID of the proposal to review.
     * @param _reviewScore A score reflecting the quality and constructiveness of the review (e.g., 1-10).
     */
    function reviewProposal(uint256 _proposalId, uint256 _reviewScore) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EchelonForge: Proposal does not exist");
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "EchelonForge: Proposal not in reviewable state");
        require(getReputationBalance(msg.sender) >= reviewThreshold, "EchelonForge: Insufficient reputation to review proposal");
        require(!proposal.hasReviewed[msg.sender], "EchelonForge: Already reviewed this proposal");
        require(_reviewScore > 0 && _reviewScore <= 10, "EchelonForge: Review score must be between 1 and 10");

        proposal.hasReviewed[msg.sender] = true;
        proposal.reviewScoreSum += _reviewScore;
        proposal.reviewerCount++;

        // Mint reputation for the reviewer based on review score and reward rate
        uint256 reputationAwarded = _reviewScore.mulDiv(contributionRewardRateBp, 10000);
        _mintReputationInternal(msg.sender, reputationAwarded);

        emit ProposalReviewed(_proposalId, msg.sender, _reviewScore, reputationAwarded);
    }

    /**
     * @dev Allows users to cast a 'yay' or 'nay' vote on a proposal.
     *      Voting power is calculated based on the user's effective reputation and a specified conviction duration.
     *      A user can only vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _isYay True for a 'yay' vote, false for a 'nay' vote.
     * @param _convictionDuration The duration (in seconds) the voter commits their reputation for this vote.
     *                            Longer duration, up to `MAX_CONVICTION_DURATION`, increases voting power.
     */
    function voteOnProposal(uint256 _proposalId, bool _isYay, uint256 _convictionDuration) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EchelonForge: Proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "EchelonForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "EchelonForge: Already voted on this proposal");
        require(getReputationBalance(msg.sender) > 0, "EchelonForge: No reputation to vote with");

        // If the proposal is in Pending state, transition it to Active upon the first vote.
        if (proposal.state == ProposalState.Pending) {
            proposal.state = ProposalState.Active;
        }

        uint256 effectiveVotingPower = getEffectiveVotingPower(msg.sender, _convictionDuration);
        require(effectiveVotingPower > 0, "EchelonForge: Effective voting power is zero");

        proposal.hasVoted[msg.sender] = true;
        proposal.totalReputationAtSnapshot += effectiveVotingPower; // Sum of weighted voting power

        if (_isYay) {
            proposal.yayVotes += effectiveVotingPower;
        } else {
            proposal.nayVotes += effectiveVotingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _isYay, effectiveVotingPower, _convictionDuration);
    }

    /**
     * @dev Executes a proposal after its voting period has ended and execution delay has passed.
     *      A proposal passes if it has more 'yay' votes than 'nay' votes.
     *      In a real system, successful proposals would trigger specific on-chain actions
     *      (e.g., calling another contract). Here, it updates the proposal's state.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EchelonForge: Proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "EchelonForge: Voting period not yet ended");
        require(block.timestamp > proposal.executionTime, "EchelonForge: Execution delay not passed");
        require(proposal.state == ProposalState.Active || proposal.state == ProposalState.Pending, "EchelonForge: Proposal not in executable state");

        // Determine the outcome of the vote
        if (proposal.totalReputationAtSnapshot == 0) { // No votes were cast
            proposal.state = ProposalState.Failed;
        } else if (proposal.yayVotes > proposal.nayVotes) {
            proposal.state = ProposalState.Succeeded;
            // Placeholder for actual execution logic.
            // In a full DAO, this might involve calling an interface:
            // IExecutable(proposal.targetContract).execute(proposal.callData);
        } else {
            proposal.state = ProposalState.Failed;
        }

        require(proposal.state == ProposalState.Succeeded, "EchelonForge: Proposal did not pass or already failed");

        proposal.state = ProposalState.Executed; // Mark as executed after successful passage
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows a proposer to withdraw their initial ETH deposit after a proposal's lifecycle is complete.
     *      This can occur if the proposal succeeded, failed, or was executed. The protocol fee is NOT returned.
     * @param _proposalId The ID of the proposal.
     */
    function withdrawProposalDeposit(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EchelonForge: Proposal does not exist");
        require(msg.sender == proposal.proposer, "EchelonForge: Only proposer can withdraw deposit");
        require(proposal.state == ProposalState.Succeeded ||
                proposal.state == ProposalState.Failed ||
                proposal.state == ProposalState.Executed,
                "EchelonForge: Proposal still active or pending execution");
        require(proposal.deposit > 0, "EchelonForge: Deposit already withdrawn or zero");

        uint256 amountToReturn = proposal.deposit;
        proposal.deposit = 0; // Prevent re-withdrawal by setting deposit to zero
        proposal.state = ProposalState.Withdrawn; // Mark proposal as withdrawn

        payable(msg.sender).transfer(amountToReturn);
        emit ProposalDepositWithdrawn(_proposalId, msg.sender, amountToReturn);
    }

    // --- V. Emergency & Protocol Management ---

    /**
     * @dev Initiates an immediate emergency pause of the protocol, triggered by the AI Oracle.
     *      This acts as a critical safety override, suspending most state-changing operations.
     */
    function emergencyBrakeProtocol() external onlyAIOracle nonReentrant {
        require(aiOracle.getEmergencyBrakeSignal(), "EchelonForge: AI Oracle did not signal emergency");
        _pause();
        emit EmergencyBrakeActivated(msg.sender);
    }

    /**
     * @dev Allows the contract owner (or authorized treasury address) to collect accumulated ETH protocol fees.
     * @param _amount The amount of ETH fees to collect.
     */
    function collectProtocolFees(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "EchelonForge: Amount must be greater than zero");
        require(totalProtocolFees >= _amount, "EchelonForge: Insufficient total protocol fees available");

        totalProtocolFees -= _amount;
        payable(msg.sender).transfer(_amount); // Transfer collected fees to the owner
        emit ProtocolFeeCollected(msg.sender, _amount);
    }

    /**
     * @dev Sets the minimum reputation required for an address to submit a new proposal.
     *      Callable only by the contract owner (or via a governance proposal in a full DAO).
     * @param _newThreshold The new minimum reputation threshold.
     */
    function setProposalThreshold(uint256 _newThreshold) external onlyOwner {
        proposalThreshold = _newThreshold;
        emit ProposalThresholdUpdated(_newThreshold);
    }

    /**
     * @dev Sets the minimum reputation required for an address to review a proposal.
     *      Callable only by the contract owner (or via a governance proposal).
     * @param _newThreshold The new minimum reputation threshold.
     */
    function setReviewThreshold(uint256 _newThreshold) external onlyOwner {
        reviewThreshold = _newThreshold;
        emit ReviewThresholdUpdated(_newThreshold);
    }

    /**
     * @dev Sets the minimum time (in seconds) a voter's reputation must be committed
     *      to achieve the maximum conviction weight bonus during voting.
     *      Callable only by the contract owner (or via a governance proposal).
     * @param _newPeriod The new minimum conviction period in seconds.
     */
    function setMinVotingConvictionPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "EchelonForge: Period must be greater than zero");
        minVotingConvictionPeriod = _newPeriod;
        emit MinVotingConvictionPeriodUpdated(_newPeriod);
    }

    /**
     * @dev Fallback function to receive ETH. Any direct ETH transfers to the contract
     *      are automatically added to the `totalProtocolFees` pool.
     */
    receive() external payable {
        totalProtocolFees += msg.value;
    }
}
```