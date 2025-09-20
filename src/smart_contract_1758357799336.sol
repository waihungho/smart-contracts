```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity for admin roles. A full DAO might replace this.

/**
 * @title AdaptiveSynergyProtocol
 * @dev This contract implements a Decentralized Adaptive Protocol for Synergistic Ecosystems (DAPSE).
 *      It aims to foster collaboration and intelligent resource allocation by integrating:
 *      1.  **Reputation System (Impact Points):** Non-transferable tokens earned through contributions and successful proposals,
 *          dynamically adjusted by the observed impact of actions.
 *      2.  **Collective Intelligence Fund:** A shared treasury governed by reputation-weighted proposals.
 *      3.  **Dynamic Parameter Governance:** Protocol parameters (e.g., voting thresholds, reputation decay)
 *          can be proposed and adjusted, adapting the protocol's behavior over time.
 *      4.  **Adaptive Feedback Loop:** A unique mechanism where participants provide subjective feedback on past
 *          proposal outcomes, directly influencing proposer/voter reputation and a global 'Ecosystem Health Score'.
 *          This allows the protocol to "learn" from its history.
 *      5.  **Heuristic Decision Support:** "AI-like" calculations for proposal success probability and dynamic funding rates
 *          based on proposer reputation and overall ecosystem health.
 *      The goal is to create a self-improving, resilient ecosystem that learns from its past actions and adapts its rules.
 */

// Outline for AdaptiveSynergyProtocol

// I. Core Protocol Administration
//    Functions for setup, emergency controls, and basic access management.
// II. Participant & Reputation Management
//    Functions related to user registration, earning non-transferable reputation (Impact Points),
//    and reputation delegation for voting.
// III. Collective Intelligence Fund Operations
//    Functions for managing the protocol's treasury, submitting funding proposals,
//    and executing approved grants.
// IV. Dynamic Parameter Governance
//    Functions for proposing and enacting changes to the protocol's core operational parameters
//    based on collective input and reputation-weighted voting.
// V. Adaptive Feedback Loop & Ecosystem Health
//    Functions enabling participants to provide feedback on proposal outcomes, which dynamically
//    adjusts individual reputation and the overall Ecosystem Health Score, influencing future decisions and parameters.
// VI. Advanced Analytics & Incentives
//    Functions for retrieving key metrics, calculating dynamic rates based on ecosystem health,
//    and allowing active, high-reputation participants to claim periodic incentives.
// VII. Emergency & Utilities
//    Functions for pausing, emergency shutdown, and various view functions to inspect the protocol's state.

// Function Summary

// I. Core Protocol Administration
// 1.  constructor(): Initializes the protocol with an admin, a designated funding token, and initial parameters.
// 2.  setProtocolAdmin(address _newAdmin): Allows the current protocol admin to transfer administrative control. (Implemented via Ownable.transferOwnership).
// 3.  addContributionVerifier(address _verifier): Grants an address the role to verify off-chain contributions.
// 4.  removeContributionVerifier(address _verifier): Revokes the contribution verifier role from an address.

// II. Participant & Reputation Management
// 5.  registerParticipant(): Allows an address to join the protocol, initiating their Impact Points (IP) record.
// 6.  submitContribution(string memory _proofHash): Allows a registered participant to submit a proof of an off-chain contribution for review.
// 7.  verifyContribution(address _participant, uint256 _impactPoints, uint256 _contributionId): A designated verifier approves a contribution and awards Impact Points.
// 8.  delegateImpactPower(address _delegatee): Allows a participant to delegate their voting power, derived from Impact Points, to another address (liquid democracy).
// 9.  getParticipantImpactPoints(address _participant): Returns the current (raw) Impact Points of a participant.

// III. Collective Intelligence Fund Operations
// 10. depositToFund(uint256 _amount): Allows anyone to deposit Funding Tokens into the collective fund.
// 11. proposeFundingGrant(address _targetRecipient, uint256 _amount, string memory _description): Allows a participant to propose a grant from the collective fund.
// 12. voteOnProposal(uint256 _proposalId, bool _support): Registered participants vote on proposals (funding grants or parameter changes) using their delegated or own Impact Power.
// 13. executeProposal(uint256 _proposalId): Finalizes the voting for a proposal and executes it if it passes quorum and majority checks.
// 14. reclaimProposalDeposit(uint256 _proposalId): Allows the proposer to reclaim their deposit if their proposal fails or has not been claimed yet after passing.

// IV. Dynamic Parameter Governance
// 15. proposeParameterChange(uint256 _paramType, uint256 _newValue, string memory _description): Allows a participant to propose a change to a core protocol parameter (e.g., voting period, reputation decay rate).
// 16. voteOnParameterChange(uint256 _proposalId, bool _support): Integrated into `voteOnProposal`.
// 17. enactParameterChange(uint256 _proposalId): Integrated into `executeProposal` (internal helper `_enactParameterChange`).

// V. Adaptive Feedback Loop & Ecosystem Health
// 18. submitOutcomeFeedback(uint256 _proposalId, uint8 _score): Allows designated participants to provide a subjective outcome score (1-10) for executed proposals, assessing their actual impact.
// 19. challengeOutcomeFeedback(uint256 _proposalId, address _feedbackReviewer, string memory _reason): Allows challenging potentially malicious or inaccurate outcome feedback.
// 20. finalizeOutcomeFeedback(uint256 _proposalId): Aggregates all valid feedback for a proposal, updates the proposer's and voters' Impact Points based on the outcome, and influences the global Ecosystem Health Score.
// 21. _updateEcosystemHealthScore(): An internal (or periodically triggered) function that recalculates the global Ecosystem Health Score based on recent proposal outcomes and overall activity.

// VI. Advanced Analytics & Incentives
// 22. getEcosystemHealthScore(): Returns the current calculated Ecosystem Health Score (0-100).
// 23. getDynamicFundingRate(): Returns a dynamic multiplier for funding based on the current Ecosystem Health Score (e.g., higher health = higher multiplier).
// 24. calculateProposalSuccessProbability(uint256 _proposalId): Provides a heuristic prediction (0-100%) of a proposal's likelihood of passing, based on the proposer's reputation and current ecosystem health.
// 25. claimActiveParticipantIncentive(): Allows active, high-reputation participants to claim a periodic incentive in Funding Tokens, encouraging continued engagement.

// VII. Emergency & Utilities
// 26. pauseProtocol(): Pauses critical functions of the protocol in case of an emergency. (Inherited from Pausable).
// 27. unpauseProtocol(): Unpauses the protocol. (Inherited from Pausable).
// 28. emergencyShutdown(): Initiates a full protocol shutdown by the admin, typically preceding a grace period for fund withdrawals.
// 29. withdrawFundsAfterShutdown(uint256 _proposalId): Allows proposers to withdraw their deposits after an emergency shutdown.
// 30. getProtocolParameters(): A view function to retrieve all current configurable protocol parameters.
// 31. getEffectiveImpactPower(address _participant): Returns the participant's effective Impact Points for voting, considering any delegation.

contract AdaptiveSynergyProtocol is Ownable, Pausable {

    IERC20 public immutable fundingToken; // The ERC20 token used for the collective fund

    // --- Structs ---

    enum ProposalType { FundingGrant, ParameterChange }
    enum ParameterType {
        MinReputationToPropose,
        MinReputationToVote,
        ProposalQuorumNumerator, // e.g., for 50%, quorum numerator is 50
        ProposalQuorumDenominator, // e.g., for 50%, quorum denominator is 100
        ProposalVotingPeriod, // in seconds
        ReputationDecayRate, // percentage (e.g., 5 for 5%)
        ReputationDecayPeriod, // seconds (e.g., weekly)
        OutcomeFeedbackPeriod, // in seconds, period after execution for feedback submission
        FeedbackChallengePeriod, // in seconds, period after feedback submission for challenges
        MinFeedbackToFinalize, // min unique feedback entries required
        ProposalDepositAmount, // amount of fundingToken required for proposal
        ActiveParticipantIncentiveAmount, // incentive amount for active users
        ActiveParticipantIncentivePeriod // how often incentive can be claimed
    }

    struct Proposal {
        uint256 id;
        ProposalType pType;
        address proposer;
        address targetAddress; // Recipient for funding, or address(0) for param change
        uint256 amountOrNewValue; // Amount for funding, or new value for parameter
        string description;
        uint256 submissionTime;
        uint256 voteEndTime;
        uint256 executionTime; // When the proposal was executed (for grants) or enacted (for param changes)
        bool executed; // True if voting period ended and executeProposal was called
        bool passed; // True if the proposal passed voting
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        address[] votersFor; // Track voters for dynamic reputation adjustment
        address[] votersAgainst;
        uint256 depositAmount; // Required deposit to prevent spam
        bool feedbackCollected; // True when enough feedback is in and finalized
        uint8 aggregatedOutcomeScore; // 1-10, 0 if not yet finalized
    }

    struct OutcomeFeedback {
        address reviewer;
        uint8 score; // 1 to 10 (1=very poor, 10=excellent)
        uint256 timestamp;
        bool challenged;
        bool challengeUpheld; // If challenged, whether the challenge was successful (not fully implemented in this example)
    }

    // --- State Variables ---

    uint256 public nextProposalId;
    uint256 public nextContributionId;

    // Reputation System (Impact Points - non-transferable)
    mapping(address => uint256) public impactPoints; // raw IP
    mapping(address => address) public delegatedImpactPower; // who delegates to whom (address => delegatee)
    mapping(address => bool) public isRegisteredParticipant;

    // Contribution Verifiers
    mapping(address => bool) public contributionVerifiers;

    // Proposals storage
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => bool
    mapping(uint256 => mapping(address => bool)) public hasProvidedFeedback; // proposalId => reviewer => bool

    // Parameter Change Proposals (stores the parameter type for each proposal)
    mapping(uint256 => ParameterType) public parameterChangeTypes; // proposalId => parameter type being changed

    // Outcome Feedback storage
    mapping(uint256 => mapping(address => OutcomeFeedback)) public outcomeFeedbacks; // proposalId => reviewer => feedback details

    // Current Protocol Parameters (configurable via governance)
    struct ProtocolParameters {
        uint256 minReputationToPropose;
        uint256 minReputationToVote;
        uint256 proposalQuorumNumerator;
        uint256 proposalQuorumDenominator;
        uint256 proposalVotingPeriod; // seconds
        uint256 reputationDecayRate; // percentage (e.g., 5 for 5%) per decay period
        uint256 reputationDecayPeriod; // seconds (e.g., monthly)
        uint256 outcomeFeedbackPeriod; // seconds after execution
        uint256 feedbackChallengePeriod; // seconds after feedback submission
        uint256 minFeedbackToFinalize; // min unique feedback entries
        uint256 proposalDepositAmount; // amount of fundingToken for proposal
        uint256 activeParticipantIncentiveAmount; // incentive for active users
        uint256 activeParticipantIncentivePeriod; // how often incentive can be claimed
    }
    ProtocolParameters public params;
    uint256 public ecosystemHealthScore; // 0-100, impacts dynamic rates
    uint256 public lastHealthScoreUpdate; // Timestamp of the last health score update

    mapping(address => uint256) public lastParticipantIncentiveClaim; // Per-participant cooldown for incentives

    // --- Events ---

    event ParticipantRegistered(address indexed participant);
    event ContributionSubmitted(address indexed participant, uint256 contributionId, string proofHash);
    event ContributionVerified(address indexed participant, uint256 contributionId, uint256 awardedImpactPoints);
    event ImpactPowerDelegated(address indexed delegator, address indexed delegatee);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundingProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event ParameterChangeProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ParameterType paramType, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weightedVotes);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event FundingGrantExecuted(uint256 indexed proposalId, address recipient, uint256 amount);
    event ParameterChangeEnacted(uint256 indexed proposalId, ParameterType paramType, uint256 newValue);
    event ProposalDepositReclaimed(uint256 indexed proposalId, address indexed proposer, uint256 amount);
    event OutcomeFeedbackSubmitted(uint256 indexed proposalId, address indexed reviewer, uint8 score);
    event OutcomeFeedbackChallenged(uint256 indexed proposalId, address indexed challenger, address indexed reviewer);
    event OutcomeFeedbackFinalized(uint256 indexed proposalId, uint8 aggregatedScore);
    event EcosystemHealthScoreUpdated(uint256 newScore);
    event ActiveParticipantIncentiveClaimed(address indexed participant, uint256 amount);
    event EmergencyShutdownInitiated();

    // --- Modifiers ---

    modifier onlyContributionVerifier() {
        require(contributionVerifiers[msg.sender], "Not a contribution verifier");
        _;
    }

    modifier onlyRegisteredParticipant() {
        require(isRegisteredParticipant[msg.sender], "Caller is not a registered participant");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");
        require(block.timestamp <= proposals[_proposalId].voteEndTime, "Voting period has ended");
        _;
    }

    modifier onlyExecutedProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");
        require(proposals[_proposalId].executed, "Proposal not yet executed");
        _;
    }

    // --- Constructor ---

    constructor(address _fundingToken, address _admin) Ownable(_admin) Pausable() {
        require(_fundingToken != address(0), "Funding token address cannot be zero");
        fundingToken = IERC20(_fundingToken);

        // Initial Protocol Parameters
        params = ProtocolParameters({
            minReputationToPropose: 100, // Min IP to submit a proposal
            minReputationToVote: 10,    // Min IP to vote on a proposal
            proposalQuorumNumerator: 50, // 50% quorum of total votes cast
            proposalQuorumDenominator: 100,
            proposalVotingPeriod: 3 days, // 3 days for voting
            reputationDecayRate: 5, // 5% decay of IP
            reputationDecayPeriod: 30 days, // Every 30 days
            outcomeFeedbackPeriod: 7 days, // 7 days after execution to submit feedback
            feedbackChallengePeriod: 3 days, // 3 days after feedback submission to challenge
            minFeedbackToFinalize: 3, // Min unique feedback entries to finalize a proposal's outcome
            proposalDepositAmount: 100000000000000000, // 0.1 Funding Tokens (example)
            activeParticipantIncentiveAmount: 10000000000000000, // 0.01 Funding Tokens
            activeParticipantIncentivePeriod: 7 days // Weekly incentive claim
        });

        ecosystemHealthScore = 75; // Initial health score (out of 100)
        lastHealthScoreUpdate = block.timestamp;
        nextProposalId = 1;
        nextContributionId = 1;

        // Register the deployer as a participant and initial verifier
        isRegisteredParticipant[msg.sender] = true;
        impactPoints[msg.sender] = 500; // Give initial IP to deployer
        contributionVerifiers[msg.sender] = true;
        emit ParticipantRegistered(msg.sender);
    }

    // --- I. Core Protocol Administration ---

    // 2. setProtocolAdmin is handled by Ownable.transferOwnership() and Ownable.renounceOwnership().
    // The protocol admin can transfer ownership to a DAO or multisig after deployment.

    /**
     * @dev Grants an address the role to verify contributions. Only callable by the protocol admin.
     * @param _verifier The address to grant the verifier role.
     */
    function addContributionVerifier(address _verifier) public onlyOwner {
        require(_verifier != address(0), "Verifier address cannot be zero");
        contributionVerifiers[_verifier] = true;
    }

    /**
     * @dev Revokes the contribution verifier role from an address. Only callable by the protocol admin.
     * @param _verifier The address to revoke the verifier role from.
     */
    function removeContributionVerifier(address _verifier) public onlyOwner {
        require(_verifier != address(0), "Verifier address cannot be zero");
        contributionVerifiers[_verifier] = false;
    }

    // --- II. Participant & Reputation Management ---

    /**
     * @dev Allows an address to register as a participant in the protocol.
     *      Initializes their Impact Points to zero and marks them as a registered participant.
     */
    function registerParticipant() public whenNotPaused {
        require(!isRegisteredParticipant[msg.sender], "Already a registered participant");
        isRegisteredParticipant[msg.sender] = true;
        // Impact points start at 0. They are earned through contributions or proposals.
        // impactPoints[msg.sender] = 0; // Already default to 0
        emit ParticipantRegistered(msg.sender);
    }

    /**
     * @dev Allows a registered participant to submit a proof of an off-chain contribution for review.
     *      This proof hash can refer to external documentation, IPFS links, etc.
     * @param _proofHash A hash or URI pointing to the proof of contribution.
     */
    function submitContribution(string memory _proofHash) public onlyRegisteredParticipant whenNotPaused {
        uint256 currentContributionId = nextContributionId++;
        // In a real system, contributions would be stored in a mapping or array for verifiers to review.
        // For simplicity here, we just emit an event, implying off-chain storage/lookup for the actual proof.
        emit ContributionSubmitted(msg.sender, currentContributionId, _proofHash);
    }

    /**
     * @dev A contribution verifier approves a submitted contribution and awards Impact Points.
     *      This is a critical function for reputation building.
     * @param _participant The address of the participant whose contribution is being verified.
     * @param _impactPoints The amount of Impact Points to award for this contribution.
     * @param _contributionId The ID of the contribution being verified (from `ContributionSubmitted` event).
     */
    function verifyContribution(address _participant, uint256 _impactPoints, uint256 _contributionId) public onlyContributionVerifier whenNotPaused {
        require(isRegisteredParticipant[_participant], "Participant not registered");
        require(_impactPoints > 0, "Impact Points must be positive");
        // For this example, we assume the verifier knows what _contributionId refers to off-chain.
        // In a more robust system, `_contributionId` would map to an on-chain `Contribution` struct.
        _applyImpactPoints(_participant, _impactPoints);
        emit ContributionVerified(_participant, _contributionId, _impactPoints);
    }

    /**
     * @dev Allows a participant to delegate their voting power (derived from Impact Points) to another address.
     *      This enables "liquid democracy" or proxy voting for reputation-weighted decisions.
     * @param _delegatee The address to which the sender's Impact Power will be delegated.
     */
    function delegateImpactPower(address _delegatee) public onlyRegisteredParticipant whenNotPaused {
        require(_delegatee != address(0), "Delegatee cannot be the zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");
        require(isRegisteredParticipant[_delegatee], "Delegatee must be a registered participant");
        delegatedImpactPower[msg.sender] = _delegatee;
        emit ImpactPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Returns the current Impact Points of a participant.
     *      A more advanced system might apply decay here based on `last_activity` and `reputationDecayRate`.
     * @param _participant The address of the participant.
     * @return The participant's current Impact Points.
     */
    function getParticipantImpactPoints(address _participant) public view returns (uint256) {
        if (!isRegisteredParticipant[_participant]) {
            return 0;
        }
        // Simplified: decay is not applied on-the-fly for view functions to save gas.
        // A full decay system would track `last_activity` timestamp for each user
        // and apply decay when IP is used or on a periodic update.
        return impactPoints[_participant];
    }

    // Internal helper for applying IP (e.g., from contributions or positive outcomes)
    function _applyImpactPoints(address _participant, uint256 _amount) internal {
        impactPoints[_participant] += _amount;
    }

    // Internal helper for deducting IP (e.g., from negative outcomes)
    function _deductImpactPoints(address _participant, uint256 _amount) internal {
        impactPoints[_participant] = impactPoints[_participant] < _amount ? 0 : impactPoints[_participant] - _amount;
    }

    // --- III. Collective Intelligence Fund Operations ---

    /**
     * @dev Allows anyone to deposit Funding Tokens into the collective fund.
     * @param _amount The amount of Funding Tokens to deposit.
     */
    function depositToFund(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Deposit amount must be greater than zero");
        // ERC20 approval is required before calling this function
        require(fundingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows a participant to propose a grant from the collective fund.
     *      Requires a minimum reputation and a deposit.
     * @param _targetRecipient The address to receive the grant.
     * @param _amount The amount of Funding Tokens to grant.
     * @param _description A description of the proposal.
     */
    function proposeFundingGrant(address _targetRecipient, uint256 _amount, string memory _description)
        public
        onlyRegisteredParticipant
        whenNotPaused
        returns (uint256 proposalId)
    {
        require(getParticipantImpactPoints(msg.sender) >= params.minReputationToPropose, "Not enough Impact Points to propose");
        require(_targetRecipient != address(0), "Target recipient cannot be zero address");
        require(_amount > 0, "Grant amount must be greater than zero");
        require(fundingToken.balanceOf(address(this)) >= _amount, "Insufficient funds in the collective fund");
        
        // Proposer must approve this contract to take the deposit
        require(fundingToken.transferFrom(msg.sender, address(this), params.proposalDepositAmount), "Deposit transfer failed");

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            pType: ProposalType.FundingGrant,
            proposer: msg.sender,
            targetAddress: _targetRecipient,
            amountOrNewValue: _amount,
            description: _description,
            submissionTime: block.timestamp,
            voteEndTime: block.timestamp + params.proposalVotingPeriod,
            executionTime: 0,
            executed: false,
            passed: false,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            votersFor: new address[](0),
            votersAgainst: new address[](0),
            depositAmount: params.proposalDepositAmount,
            feedbackCollected: false,
            aggregatedOutcomeScore: 0
        });

        emit FundingProposalSubmitted(proposalId, msg.sender, _targetRecipient, _amount);
    }

    /**
     * @dev Allows a participant to propose a change to a core protocol parameter.
     *      Requires a minimum reputation and a deposit.
     * @param _paramType The type of parameter to change.
     * @param _newValue The new value for the parameter.
     * @param _description A description of the parameter change.
     */
    function proposeParameterChange(uint256 _paramType, uint256 _newValue, string memory _description)
        public
        onlyRegisteredParticipant
        whenNotPaused
        returns (uint256 proposalId)
    {
        require(getParticipantImpactPoints(msg.sender) >= params.minReputationToPropose, "Not enough Impact Points to propose");
        require(_newValue > 0, "New parameter value must be greater than zero"); // Most parameters have positive values
        // Check if _paramType is within the valid enum range
        require(uint8(_paramType) <= uint8(ParameterType.ActiveParticipantIncentivePeriod), "Invalid parameter type");

        require(fundingToken.transferFrom(msg.sender, address(this), params.proposalDepositAmount), "Deposit transfer failed");

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            pType: ProposalType.ParameterChange,
            proposer: msg.sender,
            targetAddress: address(0), // Not applicable for parameter change
            amountOrNewValue: _newValue,
            description: _description,
            submissionTime: block.timestamp,
            voteEndTime: block.timestamp + params.proposalVotingPeriod,
            executionTime: 0,
            executed: false,
            passed: false,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            votersFor: new address[](0),
            votersAgainst: new address[](0),
            depositAmount: params.proposalDepositAmount,
            feedbackCollected: false,
            aggregatedOutcomeScore: 0
        });
        parameterChangeTypes[proposalId] = ParameterType(_paramType);

        emit ParameterChangeProposalSubmitted(proposalId, msg.sender, ParameterType(_paramType), _newValue);
    }

    /**
     * @dev Registered participants vote on proposals using their Impact Power.
     *      Voters must meet a minimum reputation threshold.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRegisteredParticipant onlyActiveProposal(_proposalId) whenNotPaused {
        require(getParticipantImpactPoints(msg.sender) >= params.minReputationToVote, "Not enough Impact Points to vote");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");

        address effectiveVoter = getEffectiveVoter(msg.sender); // Handles delegation
        uint256 votingPower = getParticipantImpactPoints(effectiveVoter);
        require(votingPower > 0, "Effective voter has no Impact Points");

        Proposal storage proposal = proposals[_proposalId];
        if (_support) {
            proposal.totalVotesFor += votingPower;
            proposal.votersFor.push(effectiveVoter);
        } else {
            proposal.totalVotesAgainst += votingPower;
            proposal.votersAgainst.push(effectiveVoter);
        }
        hasVoted[_proposalId][msg.sender] = true; // Mark original sender as having voted

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @dev Finalizes the voting for a proposal and executes it if it passes.
     *      Anyone can call this after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended yet");

        uint256 totalVotesCast = proposal.totalVotesFor + proposal.totalVotesAgainst;
        require(totalVotesCast > 0, "No votes cast for this proposal"); // Proposal must have votes to be executed

        // Quorum check: total votes for must meet a percentage of total votes cast
        uint256 minRequiredVotes = (totalVotesCast * params.proposalQuorumNumerator) / params.proposalQuorumDenominator;
        bool passedQuorum = proposal.totalVotesFor >= minRequiredVotes;

        // Simple majority check
        bool passedMajority = proposal.totalVotesFor > proposal.totalVotesAgainst;

        proposal.passed = passedQuorum && passedMajority;
        proposal.executed = true;
        proposal.executionTime = block.timestamp;

        if (proposal.passed) {
            if (proposal.pType == ProposalType.FundingGrant) {
                // Execute funding grant
                require(fundingToken.transfer(proposal.targetAddress, proposal.amountOrNewValue), "Funding grant transfer failed");
                emit FundingGrantExecuted(_proposalId, proposal.targetAddress, proposal.amountOrNewValue);
            } else if (proposal.pType == ProposalType.ParameterChange) {
                // Enact parameter change
                _enactParameterChange(parameterChangeTypes[_proposalId], proposal.amountOrNewValue);
                emit ParameterChangeEnacted(_proposalId, parameterChangeTypes[_proposalId], proposal.amountOrNewValue);
            }
            // Return deposit to proposer if proposal passed
            require(fundingToken.transfer(proposal.proposer, proposal.depositAmount), "Failed to return deposit");
            proposal.depositAmount = 0; // Mark as reclaimed
        }
        // If the proposal failed, the proposer's deposit remains in the contract,
        // and they can call reclaimProposalDeposit later.

        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /**
     * @dev Allows the proposer to reclaim their deposit if the proposal failed or has not been claimed yet after passing.
     *      Anyone can call this for a failed proposal, but only the proposer for a passed one (if they haven't received it).
     * @param _proposalId The ID of the proposal.
     */
    function reclaimProposalDeposit(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.depositAmount > 0, "Deposit already reclaimed or not applicable");
        require(proposal.executed, "Proposal not yet executed (call executeProposal first)");
        require(proposal.proposer == msg.sender || !proposal.passed, "Only proposer can reclaim deposit for passed proposals if not already done");

        uint256 deposit = proposal.depositAmount;
        proposal.depositAmount = 0; // Mark as reclaimed

        require(fundingToken.transfer(proposal.proposer, deposit), "Failed to transfer deposit back");
        emit ProposalDepositReclaimed(_proposalId, proposal.proposer, deposit);
    }

    // --- IV. Dynamic Parameter Governance ---

    // 15. proposeParameterChange is defined above.
    // 16. voteOnParameterChange is handled by voteOnProposal.

    // 17. Enacts a parameter change if the proposal passes. Internal function.
    function _enactParameterChange(ParameterType _paramType, uint256 _newValue) internal {
        if (_paramType == ParameterType.MinReputationToPropose) {
            params.minReputationToPropose = _newValue;
        } else if (_paramType == ParameterType.MinReputationToVote) {
            params.minReputationToVote = _newValue;
        } else if (_paramType == ParameterType.ProposalQuorumNumerator) {
            params.proposalQuorumNumerator = _newValue;
        } else if (_paramType == ParameterType.ProposalQuorumDenominator) {
            params.proposalQuorumDenominator = _newValue;
        } else if (_paramType == ParameterType.ProposalVotingPeriod) {
            params.proposalVotingPeriod = _newValue;
        } else if (_paramType == ParameterType.ReputationDecayRate) {
            params.reputationDecayRate = _newValue;
        } else if (_paramType == ParameterType.ReputationDecayPeriod) {
            params.reputationDecayPeriod = _newValue;
        } else if (_paramType == ParameterType.OutcomeFeedbackPeriod) {
            params.outcomeFeedbackPeriod = _newValue;
        } else if (_paramType == ParameterType.FeedbackChallengePeriod) {
            params.feedbackChallengePeriod = _newValue;
        } else if (_paramType == ParameterType.MinFeedbackToFinalize) {
            params.minFeedbackToFinalize = _newValue;
        } else if (_paramType == ParameterType.ProposalDepositAmount) {
            params.proposalDepositAmount = _newValue;
        } else if (_paramType == ParameterType.ActiveParticipantIncentiveAmount) {
            params.activeParticipantIncentiveAmount = _newValue;
        } else if (_paramType == ParameterType.ActiveParticipantIncentivePeriod) {
            params.activeParticipantIncentivePeriod = _newValue;
        } else {
            revert("Invalid parameter type for enactment");
        }
    }

    // --- V. Adaptive Feedback Loop & Ecosystem Health ---

    /**
     * @dev Allows designated participants to provide a subjective outcome score (1-10) for executed proposals.
     *      This feedback is crucial for the adaptive learning mechanism.
     *      Only participants with sufficient reputation can provide feedback.
     * @param _proposalId The ID of the executed proposal.
     * @param _score The subjective outcome score (1=very poor, 10=excellent).
     */
    function submitOutcomeFeedback(uint256 _proposalId, uint8 _score) public onlyRegisteredParticipant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.executed, "Proposal not yet executed to provide feedback");
        require(block.timestamp >= proposal.executionTime && block.timestamp <= proposal.executionTime + params.outcomeFeedbackPeriod, "Feedback period has expired or not started");
        require(_score >= 1 && _score <= 10, "Score must be between 1 and 10");
        require(!hasProvidedFeedback[_proposalId][msg.sender], "Already provided feedback for this proposal");

        // Only participants with enough reputation to vote can submit feedback
        require(getParticipantImpactPoints(msg.sender) >= params.minReputationToVote, "Not enough Impact Points to submit feedback");

        outcomeFeedbacks[_proposalId][msg.sender] = OutcomeFeedback({
            reviewer: msg.sender,
            score: _score,
            timestamp: block.timestamp,
            challenged: false,
            challengeUpheld: false
        });
        hasProvidedFeedback[_proposalId][msg.sender] = true;
        emit OutcomeFeedbackSubmitted(_proposalId, msg.sender, _score);
    }

    /**
     * @dev Allows challenging potentially malicious or incorrect outcome feedback.
     *      A challenge would conceptually require a reputation stake or a deposit.
     *      If successful, the challenged feedback is ignored. If unsuccessful, the challenger might be penalized.
     * @param _proposalId The ID of the proposal.
     * @param _feedbackReviewer The address of the participant whose feedback is being challenged.
     * @param _reason A description or hash of the reason for the challenge. (Not stored on-chain for gas efficiency)
     */
    function challengeOutcomeFeedback(uint256 _proposalId, address _feedbackReviewer, string memory _reason) public onlyRegisteredParticipant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.executed, "Proposal not yet executed");
        OutcomeFeedback storage feedback = outcomeFeedbacks[_proposalId][_feedbackReviewer];
        require(feedback.reviewer != address(0), "Feedback not found");
        require(!feedback.challenged, "Feedback already challenged");
        require(block.timestamp >= feedback.timestamp && block.timestamp <= feedback.timestamp + params.feedbackChallengePeriod, "Challenge period expired or not started");

        // Conceptually, a stake/deposit would be required here.
        // For simplicity, we just mark it as challenged. A DAO vote or arbitration system would resolve `challengeUpheld`.
        feedback.challenged = true;
        _reason; // suppress unused variable warning if not storing
        emit OutcomeFeedbackChallenged(_proposalId, msg.sender, _feedbackReviewer);
    }

    /**
     * @dev Aggregates feedback for a proposal, updates proposer/voter reputation, and influences Ecosystem Health Score.
     *      Can be called by anyone after the feedback period and minimum feedback count are met.
     * @param _proposalId The ID of the proposal to finalize feedback for.
     */
    function finalizeOutcomeFeedback(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.executed, "Proposal not executed");
        require(!proposal.feedbackCollected, "Feedback already finalized for this proposal");
        require(block.timestamp > proposal.executionTime + params.outcomeFeedbackPeriod, "Feedback period not over");

        uint256 totalScore = 0;
        uint256 feedbackCount = 0;

        // Collect feedback from all participants who voted and provided feedback.
        // This is not fully scalable if `votersFor` and `votersAgainst` are very large.
        // A more efficient design would involve off-chain indexing or a dedicated feedback storage map.
        address[] memory uniqueFeedbackProviders;
        mapping(address => bool) private _seenFeedbackProviders; // Local temporary to check uniqueness

        for (uint256 i = 0; i < proposal.votersFor.length; i++) {
            address voter = proposal.votersFor[i];
            if (hasProvidedFeedback[_proposalId][voter] && !_seenFeedbackProviders[voter]) {
                uniqueFeedbackProviders.push(voter);
                _seenFeedbackProviders[voter] = true;
            }
        }
        for (uint256 i = 0; i < proposal.votersAgainst.length; i++) {
            address voter = proposal.votersAgainst[i];
            if (hasProvidedFeedback[_proposalId][voter] && !_seenFeedbackProviders[voter]) {
                uniqueFeedbackProviders.push(voter);
                _seenFeedbackProviders[voter] = true;
            }
        }
        // Also allow feedback from the proposer if they weren't a voter or want to self-rate
        if (hasProvidedFeedback[_proposalId][proposal.proposer] && !_seenFeedbackProviders[proposal.proposer]) {
             uniqueFeedbackProviders.push(proposal.proposer);
             _seenFeedbackProviders[proposal.proposer] = true;
        }

        for (uint256 i = 0; i < uniqueFeedbackProviders.length; i++) {
            OutcomeFeedback storage feedback = outcomeFeedbacks[_proposalId][uniqueFeedbackProviders[i]];
            if (feedback.reviewer != address(0) && !feedback.challenged) { // Only aggregate unchallenged feedback
                totalScore += feedback.score;
                feedbackCount++;
            }
        }

        require(feedbackCount >= params.minFeedbackToFinalize, "Not enough unique feedback to finalize");

        proposal.aggregatedOutcomeScore = uint8(totalScore / feedbackCount);
        proposal.feedbackCollected = true;

        // Dynamic Impact Points adjustment based on outcome
        int256 reputationChange = _calculateReputationChange(proposal.aggregatedOutcomeScore);

        // Adjust proposer's IP
        if (reputationChange > 0) {
            _applyImpactPoints(proposal.proposer, uint256(reputationChange));
        } else if (reputationChange < 0) {
            _deductImpactPoints(proposal.proposer, uint256(-reputationChange));
        }

        // Adjust voters' IP: reward those who voted for successful proposals, penalize those who voted against it
        // Or penalize those who voted for failed ones, reward those who voted against failed ones.
        // This rewards good judgment in voting.
        uint256 voterReputationImpact = uint256(reputationChange) / 10; // Smaller impact for voters

        if (reputationChange > 0) { // Good outcome
            for (uint256 i = 0; i < proposal.votersFor.length; i++) {
                _applyImpactPoints(proposal.votersFor[i], voterReputationImpact);
            }
            for (uint256 i = 0; i < proposal.votersAgainst.length; i++) {
                _deductImpactPoints(proposal.votersAgainst[i], voterReputationImpact / 2); // Small penalty for opposing success
            }
        } else if (reputationChange < 0) { // Bad outcome
            for (uint256 i = 0; i < proposal.votersFor.length; i++) {
                _deductImpactPoints(proposal.votersFor[i], voterReputationImpact); // Penalty for supporting failure
            }
            for (uint256 i = 0; i < proposal.votersAgainst.length; i++) {
                _applyImpactPoints(proposal.votersAgainst[i], voterReputationImpact / 2); // Small reward for opposing failure
            }
        }

        _updateEcosystemHealthScore(); // Update global health score
        emit OutcomeFeedbackFinalized(_proposalId, proposal.aggregatedOutcomeScore);
    }

    /**
     * @dev Calculates the reputation change for a proposer/voter based on the aggregated outcome score.
     *      This is a core "learning" heuristic that can be adjusted via parameter proposals.
     * @param _outcomeScore The aggregated outcome score (1-10).
     * @return The change in Impact Points (can be negative).
     */
    function _calculateReputationChange(uint8 _outcomeScore) internal pure returns (int256) {
        // Example heuristic for proposer:
        // Score 1-3: -100 IP
        // Score 4: -50 IP
        // Score 5: -25 IP
        // Score 6: 0 IP (neutral)
        // Score 7: +25 IP
        // Score 8: +50 IP
        // Score 9: +75 IP
        // Score 10: +100 IP
        if (_outcomeScore <= 3) return -100;
        if (_outcomeScore == 4) return -50;
        if (_outcomeScore == 5) return -25;
        if (_outcomeScore == 6) return 0;
        if (_outcomeScore == 7) return 25;
        if (_outcomeScore == 8) return 50;
        if (_outcomeScore == 9) return 75;
        if (_outcomeScore == 10) return 100;
        return 0; // Should not be reached
    }

    /**
     * @dev Internally updates the global Ecosystem Health Score based on recent proposal outcomes,
     *      fund utilization, and overall engagement. This demonstrates on-chain adaptive analytics.
     *      Can be triggered by `finalizeOutcomeFeedback` or other key events.
     */
    function _updateEcosystemHealthScore() internal {
        // This is a placeholder for a complex, gas-optimized calculation.
        // A robust system would use a data structure (e.g., a fixed-size array or a linked list)
        // to efficiently track recent outcomes without iterating through all proposals.

        // For simplicity, we calculate a weighted average of recent outcomes.
        uint256 sumRecentOutcomeScores = 0;
        uint256 numberOfRelevantProposals = 0;
        uint256 lookbackPeriod = params.reputationDecayPeriod; // Look back same period as reputation decay

        // Iterate through recent proposals backwards
        for (uint256 i = nextProposalId - 1; i > 0 && numberOfRelevantProposals < 10; i--) { // Max 10 recent proposals for gas
            Proposal storage p = proposals[i];
            if (p.feedbackCollected && p.executionTime > block.timestamp - lookbackPeriod) {
                sumRecentOutcomeScores += p.aggregatedOutcomeScore;
                numberOfRelevantProposals++;
            }
        }

        uint256 newHealthScore = ecosystemHealthScore;
        if (numberOfRelevantProposals > 0) {
            uint256 averageRecentOutcome = sumRecentOutcomeScores / numberOfRelevantProposals;
            // Dampen the change to avoid wild fluctuations: 80% old score, 20% influence from new average outcome
            newHealthScore = (ecosystemHealthScore * 80 + averageRecentOutcome * 20) / 100;
        }

        // Ensure score stays within bounds [0, 100]
        if (newHealthScore > 100) newHealthScore = 100;
        // The average outcome score is 1-10, so multiplying by 20/100 will keep it roughly in range.
        // It's possible to go below 0 with negative influences, but current score is 0-100.
        // If the calculation leads to `newHealthScore < 0`, it needs to be floored at 0.
        // Given `averageRecentOutcome` is uint, it won't directly cause `newHealthScore` to go below 0 with current formula.
        
        ecosystemHealthScore = newHealthScore;
        lastHealthScoreUpdate = block.timestamp;
        emit EcosystemHealthScoreUpdated(ecosystemHealthScore);
    }

    // --- VI. Advanced Analytics & Incentives ---

    /**
     * @dev Returns the current calculated Ecosystem Health Score (0-100).
     */
    function getEcosystemHealthScore() public view returns (uint256) {
        return ecosystemHealthScore;
    }

    /**
     * @dev Returns a dynamic multiplier for funding based on the current Ecosystem Health Score.
     *      A higher health score might lead to more generous funding or lower fees.
     * @return A multiplier (e.g., 100 for 1x, 120 for 1.2x). Returns as percentage (e.g., 150 for 1.5x).
     */
    function getDynamicFundingRate() public view returns (uint256) {
        // Example: Base rate 100 (1x).
        // Health < 50: Rate scales down from 100 to 50 (e.g., 50 + health)
        // Health >= 50: Rate scales up from 100 to 150 (e.g., 100 + (health-50))
        if (ecosystemHealthScore < 50) {
            return 50 + ecosystemHealthScore; // Ranges from 50 (health=0) to 99 (health=49)
        } else {
            return 100 + (ecosystemHealthScore - 50); // Ranges from 100 (health=50) to 150 (health=100)
        }
    }

    /**
     * @dev Provides a heuristic prediction of a proposal's likelihood of success.
     *      This is an "AI-like" decision assist, combining proposer reputation and ecosystem health.
     * @param _proposalId The ID of the proposal to predict.
     * @return A probability score (0-100).
     */
    function calculateProposalSuccessProbability(uint256 _proposalId) public view returns (uint256) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        if (block.timestamp > proposal.voteEndTime) {
            return proposal.passed ? 100 : 0; // If voting ended, actual result is known
        }

        uint256 proposerIP = getParticipantImpactPoints(proposal.proposer);
        uint256 baseProbability = 50; // Start with 50% chance

        // Influence of proposer's reputation: Higher IP, higher perceived success chance
        // For every 100 IP above minReputationToPropose, add 5% to probability, capped at +25%
        // For every 100 IP below minReputationToPropose, subtract 5% to probability, capped at -25%
        if (proposerIP > params.minReputationToPropose) {
            baseProbability += Math.min((proposerIP - params.minReputationToPropose) / 100 * 5, 25);
        } else if (proposerIP < params.minReputationToPropose) {
            baseProbability -= Math.min((params.minReputationToPropose - proposerIP) / 100 * 5, 25);
        }

        // Influence of Ecosystem Health Score: Healthier ecosystem implies higher success rates
        // If health > 80, add 10%; if health < 20, subtract 10%
        if (ecosystemHealthScore > 80) {
            baseProbability += 10;
        } else if (ecosystemHealthScore < 20) {
            baseProbability -= 10;
        }

        // Clamp between 0 and 100
        if (baseProbability > 100) return 100;
        if (baseProbability < 0) return 0; // This path won't be taken as baseProbability is uint256. Needs careful math if negative
        return baseProbability;
    }

    // Helper library for Math operations (e.g., min, max)
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }

    /**
     * @dev Allows active, high-reputation participants to claim a periodic incentive.
     *      This incentivizes continuous positive engagement.
     *      Requires a minimum reputation and respects a cooldown period.
     */
    function claimActiveParticipantIncentive() public onlyRegisteredParticipant whenNotPaused {
        require(getParticipantImpactPoints(msg.sender) >= params.minReputationToVote, "Not enough Impact Points to claim incentive");
        require(block.timestamp >= lastParticipantIncentiveClaim[msg.sender] + params.activeParticipantIncentivePeriod, "Incentive cooldown not over");
        
        uint256 incentiveAmount = params.activeParticipantIncentiveAmount;
        // Make incentive amount dynamic based on ecosystem health
        incentiveAmount = (incentiveAmount * getDynamicFundingRate()) / 100;

        require(fundingToken.balanceOf(address(this)) >= incentiveAmount, "Insufficient funds in the collective fund for incentive");
        require(fundingToken.transfer(msg.sender, incentiveAmount), "Incentive token transfer failed");

        lastParticipantIncentiveClaim[msg.sender] = block.timestamp;
        emit ActiveParticipantIncentiveClaimed(msg.sender, incentiveAmount);
    }

    // --- VII. Emergency & Utilities ---

    // 26. pauseProtocol() is inherited from Pausable
    // 27. unpauseProtocol() is inherited from Pausable

    /**
     * @dev Initiates a full protocol shutdown in critical situations.
     *      This function can only be called by the protocol admin.
     */
    function emergencyShutdown() public onlyOwner {
        _pause(); // Pause all operations first
        emit EmergencyShutdownInitiated();
        // In a full system, this might trigger a specific shutdown state allowing withdrawals only.
    }

    /**
     * @dev Allows participants to withdraw their un-reclaimed proposal deposits after an emergency shutdown.
     *      This function ensures funds are not locked if the main `reclaimProposalDeposit` path is blocked.
     */
    function withdrawFundsAfterShutdown(uint256 _proposalId) public {
        require(paused(), "Protocol is not in emergency shutdown state");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "Only proposer can withdraw their deposit");
        require(proposal.depositAmount > 0, "No deposit to reclaim or already reclaimed");

        uint256 deposit = proposal.depositAmount;
        proposal.depositAmount = 0; // Mark as reclaimed

        require(fundingToken.transfer(msg.sender, deposit), "Failed to transfer deposit back");
        emit ProposalDepositReclaimed(_proposalId, msg.sender, deposit);
    }

    /**
     * @dev Returns the current parameters of the protocol.
     */
    function getProtocolParameters() public view returns (
        uint256 minReputationToPropose,
        uint256 minReputationToVote,
        uint256 proposalQuorumNumerator,
        uint256 proposalQuorumDenominator,
        uint256 proposalVotingPeriod,
        uint256 reputationDecayRate,
        uint256 reputationDecayPeriod,
        uint256 outcomeFeedbackPeriod,
        uint256 feedbackChallengePeriod,
        uint256 minFeedbackToFinalize,
        uint256 proposalDepositAmount,
        uint256 activeParticipantIncentiveAmount,
        uint256 activeParticipantIncentivePeriod
    ) {
        return (
            params.minReputationToPropose,
            params.minReputationToVote,
            params.proposalQuorumNumerator,
            params.proposalQuorumDenominator,
            params.proposalVotingPeriod,
            params.reputationDecayRate,
            params.reputationDecayPeriod,
            params.outcomeFeedbackPeriod,
            params.feedbackChallengePeriod,
            params.minFeedbackToFinalize,
            params.proposalDepositAmount,
            params.activeParticipantIncentiveAmount,
            params.activeParticipantIncentivePeriod
        );
    }

    /**
     * @dev Gets the effective voting power of a participant, considering delegation.
     * @param _participant The participant's address.
     * @return The effective Impact Points for voting.
     */
    function getEffectiveImpactPower(address _participant) public view returns (uint256) {
        return getParticipantImpactPoints(getEffectiveVoter(_participant));
    }

    /**
     * @dev Internal helper to resolve the effective voter in case of delegation.
     * @param _participant The original participant.
     * @return The address whose IP should be used for voting.
     */
    function getEffectiveVoter(address _participant) internal view returns (address) {
        address delegatedTo = delegatedImpactPower[_participant];
        // If delegatedTo is a registered participant and not zero, use their IP
        if (delegatedTo != address(0) && isRegisteredParticipant[delegatedTo]) {
            return delegatedTo;
        }
        return _participant;
    }
}
```