Here's a Solidity smart contract for a decentralized grants and impact funding platform, incorporating advanced concepts like AI-assisted evaluation, Soulbound Impact Tokens (SITs) for reputation, and an "Impact Intents" system for micro-tasks. It exceeds the 20-function requirement with 30 distinct functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Interface for a simplified AI Oracle ---
// In a real-world scenario, this would likely be a Chainlink oracle
// or a more complex decentralized AI network interface.
interface IAIOracle {
    // Requests an AI score for a given entity, specifying a callback contract and function.
    function requestAIScore(
        uint256 _entityId,
        string calldata _dataHash, // Hash of the data for AI to analyze (e.g., proposal IPFS hash)
        address _callbackContract,
        bytes4 _callbackFunction // Selector of the function on _callbackContract to call with the score
    ) external;
}

/**
 * @title SyntheticaGrantsDAO
 * @dev An advanced, AI-assisted, decentralized grant and impact funding platform.
 * It features a unique Soulbound Impact Token (SIT) for reputation, an 'Impact Intents' system
 * for micro-tasks, and integrates AI oracle scoring for proposal evaluation, all governed by the community.
 */
contract SyntheticaGrantsDAO is Ownable {
    using SafeMath for uint256; // Provides overflow/underflow checks for arithmetic operations

    // --- Outline and Function Summary ---
    // This contract orchestrates a decentralized autonomous organization (DAO) focused on funding
    // projects and tasks that generate verifiable impact. It introduces innovative mechanisms
    // to enhance fairness, accountability, and participation.

    // I. Core DAO Configuration & Treasury (Admin/Governance)
    //    These functions manage the DAO's foundational parameters and its treasury funds.
    // 1. constructor(address _governanceTokenAddress): Initializes the DAO with the deployer as owner,
    //    sets the ERC-20 token used for governance and funding, and establishes initial DAO parameters.
    // 2. depositToTreasury(uint256 _amount): Allows any user to deposit `governanceToken` into the DAO's treasury.
    // 3. proposeTreasuryWithdrawal(address _recipient, uint256 _amount): Creates a governance proposal
    //    for the DAO to withdraw a specified amount of tokens to a given recipient.
    // 4. executeTreasuryWithdrawal(uint256 _proposalId): Executes an approved treasury withdrawal proposal.
    //    Requires the voting period to be over and the proposal to have met approval thresholds.
    // 5. proposeParameterUpdate(bytes32 _paramName, uint256 _newValue): Creates a governance proposal
    //    to update a configurable DAO parameter (e.g., voting period, stake amounts).
    // 6. executeParameterUpdate(uint256 _proposalId): Executes an approved DAO parameter update proposal.
    // 7. voteOnDaoProposal(uint256 _proposalId, bool _support): Allows users to cast their vote (for or against)
    //    on a DAO governance proposal (treasury withdrawal or parameter update). Voting power is dynamic.

    // II. AI Oracle & External Data Integration
    //    These functions manage the integration with an external AI oracle for objective scoring.
    // 8. setAIOracleAddress(address _newOracle): Sets the address of the AI Oracle contract. Only callable by owner.
    // 9. requestAIScoreForGrant(uint256 _grantId, string calldata _proposalHash): Initiates a request to the
    //    configured AI oracle for an initial score of a specific grant proposal.
    // 10. receiveAIScore(uint256 _grantId, uint256 _score, bytes32 _detailsHash): Callback function invoked
    //    by the AI Oracle to deliver the computed score for a grant proposal. Only callable by the AI oracle.

    // III. Soulbound Impact Tokens (SITs) - Reputation System
    //    Manages the non-transferable SITs, which represent a user's reputation and influence.
    // 11. getSITBalance(address _user): Returns the SIT balance of a given user.
    // 12. calculateEffectiveVotingPower(address _voter): Calculates a user's total voting power, combining
    //    their `governanceToken` balance with a boosted value derived from their SIT balance.
    // 13. _mintSIT(address _recipient, uint256 _amount, bytes32 _reasonHash): Internal function to mint SITs
    //    to a user, typically for positive contributions (e.g., successful project, good evaluations).
    // 14. _burnSIT(address _holder, uint256 _amount, bytes32 _reasonHash): Internal function to burn SITs
    //    from a user, typically as a penalty for negative actions (e.g., failed project, malicious behavior).

    // IV. Grant Proposal Lifecycle
    //    Functions guiding a grant proposal from submission through funding and impact verification.
    // 15. submitGrantProposal(string calldata _title, string calldata _descriptionHash, uint256 _requestedAmount):
    //    Allows a user to submit a new grant proposal, requiring a deposit of `governanceToken`.
    // 16. stakeAndEvaluateGrant(uint256 _grantId, uint256 _score, bytes32 _justificationHash): Allows a user
    //    to stake tokens, evaluate an active grant proposal, and assign a score.
    // 17. voteOnGrantProposal(uint256 _grantId, bool _support): Enables users to vote on a grant proposal,
    //    with voting power calculated dynamically based on SITs and `governanceToken` balance.
    // 18. finalizeGrantVoting(uint256 _grantId): Concludes the voting period for a grant proposal,
    //    determines its final status (Approved/Rejected), and potentially refunds deposits.
    // 19. releaseGrantFunds(uint256 _grantId): Releases approved grant funds from the treasury to the proposer.
    //    Mint SITs for the proposer upon successful funding.
    // 20. submitImpactReport(uint256 _grantId, bytes32 _reportHash): Allows the funded proposer to submit a report
    //    documenting the impact of their project.
    // 21. verifyGrantImpact(uint256 _grantId, uint256 _finalImpactScore): A designated verifier (or DAO vote)
    //    assesses the impact report and assigns a final impact score, influencing the proposer's SITs.

    // V. Impact Intents - Micro-Task System
    //    A system for proposing and fulfilling smaller, specific, measurable tasks.
    // 22. proposeImpactIntent(string calldata _description, uint256 _rewardAmount, uint256 _deadline, bytes32 _challengeHash):
    //    Creates a new, specific micro-task (Intent) with a defined reward and deadline.
    // 23. bidOnImpactIntent(uint256 _intentId, uint256 _stakeAmount): A solver stakes tokens to bid on an Intent,
    //    demonstrating commitment to fulfill the task.
    // 24. assignIntentSolver(uint256 _intentId, address _solver): The Intent proposer (or DAO) selects and
    //    assigns a solver from the bidders.
    // 25. submitIntentFulfillmentProof(uint256 _intentId, bytes32 _proofHash): The assigned solver submits
    //    proof of completing the task.
    // 26. verifyIntentFulfillment(uint256 _intentId, bool _isFulfilled): The Intent proposer (or verifier)
    //    confirms task fulfillment, releasing rewards and stakes, and adjusting SITs.

    // VI. Dispute Resolution
    //    A mechanism for challenging outcomes and resolving disputes within the DAO.
    // 27. challengeOutcome(uint256 _entityId, EntityType _entityType, bytes32 _challengeDetailsHash):
    //    Initiates a challenge against an outcome (e.g., grant impact score, intent fulfillment).
    // 28. voteOnChallenge(uint256 _challengeId, bool _supportUpheld): Allows users to vote on an ongoing challenge,
    //    deciding whether to uphold or reject the challenger's claim.
    // 29. resolveChallenge(uint256 _challengeId, bytes32 _resolutionDetailsHash): A designated arbitrator (or DAO vote)
    //    officially resolves a challenge, applying consequences based on the outcome.

    // VII. View Functions
    //    Functions to retrieve information from the contract state.
    // 30. getGrantDetails(uint256 _grantId): Retrieves comprehensive details for a specific grant proposal.
    // 31. getIntentDetails(uint256 _intentId): Retrieves comprehensive details for a specific impact intent.
    // 32. getDaoParameter(bytes32 _paramName): Retrieves the current value of a DAO parameter by its name hash.

    // --- State Variables & Data Structures ---

    IERC20 public immutable governanceToken; // The ERC-20 token used for staking, rewards, and voting power calculation
    address public aiOracleAddress; // Address of the external AI Oracle contract

    // DAO Parameters: Configurable settings for the DAO, stored as mapping of bytes32 (param name) to uint256 (value).
    mapping(bytes32 => uint256) public daoParameters;

    // Enum to define named constants for DAO parameters, aiding readability and preventing typos.
    enum ParamNames {
        MIN_GRANT_PROPOSAL_DEPOSIT,         // Minimum tokens required to submit a grant proposal
        GRANT_VOTING_PERIOD,                // Duration of the voting period for grant proposals
        GRANT_EVALUATION_STAKE,             // Tokens required for an evaluator to stake
        MIN_GRANT_APPROVAL_THRESHOLD_PERCENT, // Minimum percentage of 'for' votes needed for grant approval
        MIN_EVALUATORS_PER_GRANT,           // Minimum number of evaluators required before voting starts
        SIT_MULTIPLIER_FOR_VOTING,          // Multiplier for SITs when calculating voting power
        INTENT_BID_STAKE,                   // Minimum stake required to bid on an Impact Intent
        CHALLENGE_STAKE,                    // Tokens required to initiate a dispute challenge
        CHALLENGE_VOTING_PERIOD             // Duration of the voting period for challenges
    }

    // --- Governance Proposals (for DAO Parameters & Treasury Actions) ---
    uint256 public nextDaoProposalId; // Counter for unique DAO proposal IDs
    struct DaoProposal {
        address proposer;                   // Address of the user who submitted the proposal
        bytes32 paramName;                  // Name of the parameter to update (if parameter update proposal)
        uint256 newValue;                   // New value for the parameter (if parameter update proposal)
        address recipient;                  // Recipient for treasury withdrawal (if treasury withdrawal proposal)
        uint256 amount;                     // Amount for treasury withdrawal (if treasury withdrawal proposal)
        uint256 submissionTime;             // Timestamp when the proposal was submitted
        uint256 votingPeriodEnd;            // Timestamp when the voting period for this proposal ends
        uint256 votesFor;                   // Total voting power cast 'for' the proposal
        uint256 votesAgainst;               // Total voting power cast 'against' the proposal
        mapping(address => bool) hasVoted;  // Tracks if an address has already voted on this proposal
        bool executed;                      // True if the proposal has been successfully executed
        bool isTreasuryWithdrawal;          // True if it's a treasury withdrawal, false if parameter update
    }
    mapping(uint256 => DaoProposal) public daoProposals; // Stores all DAO proposals by ID

    // --- Soulbound Impact Tokens (SITs) ---
    mapping(address => uint256) private s_sitBalances; // Non-transferable SIT balances for users
    bytes32 public constant SIT_NAME = "Soulbound Impact Token";   // Name for SITs
    bytes32 public constant SIT_SYMBOL = "SIT";                   // Symbol for SITs

    // --- Grants System ---
    uint256 public nextGrantId; // Counter for unique grant proposal IDs
    enum GrantStatus { PendingAI, PendingEvaluation, PendingVoting, Approved, Rejected, Funded, ImpactReportSubmitted, ImpactVerified, Withdrawn, Challenged }
    struct GrantProposal {
        address proposer;                   // Address of the user who submitted the grant
        string title;                       // Title of the grant proposal
        string descriptionHash;             // IPFS/Arweave hash for detailed proposal document
        uint256 requestedAmount;            // Amount of `governanceToken` requested
        uint256 submittedTime;              // Timestamp of submission
        uint256 aiScore;                    // Score provided by the AI Oracle
        uint256 avgEvaluatorScore;          // Average score from human evaluators
        uint256 evaluationStakeTotal;       // Total stake from all evaluators
        uint256 evaluationCount;            // Number of evaluators who have reviewed the proposal
        mapping(address => bool) hasEvaluated; // Tracks if an address has evaluated this grant
        mapping(address => uint256) evaluatorScores; // Stores individual evaluator scores
        uint256 votesFor;                   // Total voting power 'for' the grant
        uint256 votesAgainst;               // Total voting power 'against' the grant
        mapping(address => bool) hasVoted;  // Tracks if an address has voted on this grant
        uint256 votingPeriodEnd;            // Timestamp when voting ends
        GrantStatus status;                 // Current status of the grant proposal
        bytes32 impactReportHash;           // IPFS/Arweave hash for the project's impact report
        uint256 finalImpactScore;           // Score assigned after impact verification
    }
    mapping(uint256 => GrantProposal) public grantProposals; // Stores all grant proposals by ID

    // --- Impact Intents System ---
    uint256 public nextIntentId; // Counter for unique Impact Intent IDs
    enum IntentStatus { Proposed, Bidding, Assigned, ProofSubmitted, Fulfilled, Challenged, Rejected }
    struct ImpactIntent {
        address proposer;                   // The user who created this intent (task)
        string description;                 // Short description of the intent/task
        uint256 rewardAmount;               // Amount of `governanceToken` to be paid upon fulfillment
        uint256 deadline;                   // Deadline for the intent to be fulfilled
        bytes32 initialChallengeHash;       // Hash of detailed requirements or success criteria
        uint256 creationTime;               // Timestamp of intent creation
        IntentStatus status;                // Current status of the intent
        address assignedSolver;             // Address of the user assigned to fulfill the intent
        mapping(address => uint256) bids;   // Map of solver addresses to their staked bid amounts
        bytes32 fulfillmentProofHash;       // IPFS/Arweave hash for proof of fulfillment
        uint256 fulfillmentVerificationTime; // Timestamp when fulfillment was verified
        uint256 totalBidStake;              // Total amount of stakes from all bidders
    }
    mapping(uint256 => ImpactIntent) public impactIntents; // Stores all Impact Intents by ID

    // --- Challenge System (for general disputes) ---
    uint256 public nextChallengeId; // Counter for unique challenge IDs
    enum EntityType { GrantProposal, ImpactIntent, EvaluatorScore } // Types of entities that can be challenged
    enum ChallengeOutcome { Pending, Upheld, Rejected } // Possible outcomes of a challenge
    struct Challenge {
        address challenger;                 // Address of the user who initiated the challenge
        uint256 entityId;                   // ID of the challenged entity (e.g., grantId, intentId)
        EntityType entityType;              // Type of the entity being challenged
        bytes32 challengeDetailsHash;       // IPFS/Arweave hash for detailed challenge description
        uint256 submissionTime;             // Timestamp of challenge submission
        uint256 challengeStake;             // Amount of `governanceToken` staked by the challenger
        uint256 votesForUpheld;             // Total voting power for upholding the challenge
        uint256 votesForRejected;           // Total voting power for rejecting the challenge
        mapping(address => bool) hasVoted;  // Tracks if an address has voted on this challenge
        uint256 votingPeriodEnd;            // Timestamp when voting for the challenge ends
        ChallengeOutcome outcome;            // Final outcome of the challenge
        bool resolved;                      // True if the challenge has been resolved
    }
    mapping(uint256 => Challenge) public challenges; // Stores all challenges by ID

    // --- Events ---
    // Events allow external applications (frontends, indexing services) to react to state changes.
    event DepositedToTreasury(address indexed user, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event TreasuryWithdrawalExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event ParameterUpdateProposed(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);
    event ParameterUpdateExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, bool isDaoProposal);

    event AIOracleAddressSet(address indexed newAddress);
    event AIScoreRequested(uint256 indexed grantId, string proposalHash);
    event AIScoreReceived(uint256 indexed grantId, uint256 score);

    event SITMinted(address indexed recipient, uint256 amount, bytes32 reasonHash);
    event SITBurned(address indexed holder, uint256 amount, bytes32 reasonHash);

    event GrantProposalSubmitted(uint256 indexed grantId, address indexed proposer, uint256 requestedAmount, string title);
    event GrantEvaluated(uint256 indexed grantId, address indexed evaluator, uint256 score);
    event GrantVotingFinalized(uint256 indexed grantId, GrantStatus newStatus);
    event GrantFundsReleased(uint256 indexed grantId, uint256 amount);
    event ImpactReportSubmitted(uint256 indexed grantId, address indexed proposer, bytes32 reportHash);
    event GrantImpactVerified(uint256 indexed grantId, uint256 finalImpactScore);

    event ImpactIntentProposed(uint256 indexed intentId, address indexed proposer, uint256 rewardAmount);
    event ImpactIntentBid(uint256 indexed intentId, address indexed bidder, uint256 stakeAmount);
    event ImpactIntentAssigned(uint256 indexed intentId, address indexed solver);
    event IntentProofSubmitted(uint256 indexed intentId, address indexed solver, bytes32 proofHash);
    event IntentFulfillmentVerified(uint256 indexed intentId, bool isFulfilled);

    event ChallengeProposed(uint256 indexed challengeId, address indexed challenger, uint256 entityId, EntityType entityType);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeOutcome outcome);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "SyntheticaGrantsDAO: Only AI Oracle can call this function");
        _;
    }

    /**
     * @dev Constructor for the SyntheticaGrantsDAO.
     * @param _governanceTokenAddress The address of the ERC-20 token used for governance and funding.
     */
    constructor(address _governanceTokenAddress) Ownable(msg.sender) {
        require(_governanceTokenAddress != address(0), "SyntheticaGrantsDAO: Governance token address cannot be zero");
        governanceToken = IERC20(_governanceTokenAddress);

        // Set initial configurable DAO parameters
        daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_GRANT_PROPOSAL_DEPOSIT))] = 100 ether; // 100 tokens
        daoParameters[bytes32(abi.encodePacked(ParamNames.GRANT_VOTING_PERIOD))] = 7 days;            // 7 days
        daoParameters[bytes32(abi.encodePacked(ParamNames.GRANT_EVALUATION_STAKE))] = 10 ether;       // 10 tokens
        daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_GRANT_APPROVAL_THRESHOLD_PERCENT))] = 51; // 51% approval
        daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_EVALUATORS_PER_GRANT))] = 3;             // Minimum 3 evaluators
        daoParameters[bytes32(abi.encodePacked(ParamNames.SIT_MULTIPLIER_FOR_VOTING))] = 10;           // 1 SIT gives 10x base token voting power
        daoParameters[bytes32(abi.encodePacked(ParamNames.INTENT_BID_STAKE))] = 5 ether;              // 5 tokens
        daoParameters[bytes32(abi.encodePacked(ParamNames.CHALLENGE_STAKE))] = 20 ether;             // 20 tokens
        daoParameters[bytes32(abi.encodePacked(ParamNames.CHALLENGE_VOTING_PERIOD))] = 3 days;        // 3 days
    }

    // --- I. Core DAO Configuration & Treasury ---

    /**
     * @dev Allows users to deposit `governanceToken` into the DAO's treasury.
     * Requires prior approval of tokens to the DAO contract.
     * @param _amount The amount of tokens to deposit.
     */
    function depositToTreasury(uint256 _amount) external {
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "SyntheticaGrantsDAO: Token transfer failed");
        emit DepositedToTreasury(msg.sender, _amount);
    }

    /**
     * @dev Proposes a withdrawal of `governanceToken` from the DAO treasury.
     * This action requires community governance approval.
     * @param _recipient The address to which the tokens will be withdrawn.
     * @param _amount The amount of tokens to withdraw.
     */
    function proposeTreasuryWithdrawal(address _recipient, uint256 _amount) external {
        uint256 proposalId = nextDaoProposalId++;
        DaoProposal storage proposal = daoProposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.recipient = _recipient;
        proposal.amount = _amount;
        proposal.submissionTime = block.timestamp;
        proposal.votingPeriodEnd = block.timestamp + daoParameters[bytes32(abi.encodePacked(ParamNames.GRANT_VOTING_PERIOD))]; // Using general voting period
        proposal.isTreasuryWithdrawal = true;

        emit TreasuryWithdrawalProposed(proposalId, _recipient, _amount);
    }

    /**
     * @dev Executes a treasury withdrawal proposal if it has passed the voting phase.
     * Requires the voting period to be over and the proposal to have achieved the minimum approval threshold.
     * @param _proposalId The ID of the treasury withdrawal proposal to execute.
     */
    function executeTreasuryWithdrawal(uint256 _proposalId) external {
        DaoProposal storage proposal = daoProposals[_proposalId];
        require(proposal.isTreasuryWithdrawal, "SyntheticaGrantsDAO: Not a treasury withdrawal proposal");
        require(block.timestamp > proposal.votingPeriodEnd, "SyntheticaGrantsDAO: Voting period not ended");
        require(!proposal.executed, "SyntheticaGrantsDAO: Proposal already executed");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "SyntheticaGrantsDAO: No votes cast on this proposal");
        uint256 approvalThreshold = daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_GRANT_APPROVAL_THRESHOLD_PERCENT))];

        require(
            proposal.votesFor.mul(100) / totalVotes >= approvalThreshold,
            "SyntheticaGrantsDAO: Proposal did not meet approval threshold"
        );
        require(governanceToken.transfer(proposal.recipient, proposal.amount), "SyntheticaGrantsDAO: Withdrawal failed");

        proposal.executed = true;
        emit TreasuryWithdrawalExecuted(_proposalId, proposal.recipient, proposal.amount);
    }

    /**
     * @dev Proposes an update to a configurable DAO parameter.
     * This action requires community governance approval.
     * @param _paramName The `bytes32` hash of the parameter name (e.g., `keccak256(abi.encodePacked(ParamNames.GRANT_VOTING_PERIOD))`).
     * @param _newValue The new `uint256` value for the parameter.
     */
    function proposeParameterUpdate(bytes32 _paramName, uint256 _newValue) external {
        uint256 proposalId = nextDaoProposalId++;
        DaoProposal storage proposal = daoProposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.paramName = _paramName;
        proposal.newValue = _newValue;
        proposal.submissionTime = block.timestamp;
        proposal.votingPeriodEnd = block.timestamp + daoParameters[bytes32(abi.encodePacked(ParamNames.GRANT_VOTING_PERIOD))];
        proposal.isTreasuryWithdrawal = false;

        emit ParameterUpdateProposed(proposalId, _paramName, _newValue);
    }

    /**
     * @dev Executes a parameter update proposal if it has passed the voting phase.
     * Requires the voting period to be over and the proposal to have achieved the minimum approval threshold.
     * @param _proposalId The ID of the parameter update proposal to execute.
     */
    function executeParameterUpdate(uint256 _proposalId) external {
        DaoProposal storage proposal = daoProposals[_proposalId];
        require(!proposal.isTreasuryWithdrawal, "SyntheticaGrantsDAO: Not a parameter update proposal");
        require(block.timestamp > proposal.votingPeriodEnd, "SyntheticaGrantsDAO: Voting period not ended");
        require(!proposal.executed, "SyntheticaGrantsDAO: Proposal already executed");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "SyntheticaGrantsDAO: No votes cast on this proposal");
        uint256 approvalThreshold = daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_GRANT_APPROVAL_THRESHOLD_PERCENT))];

        require(
            proposal.votesFor.mul(100) / totalVotes >= approvalThreshold,
            "SyntheticaGrantsDAO: Proposal did not meet approval threshold"
        );

        daoParameters[proposal.paramName] = proposal.newValue;
        proposal.executed = true;
        emit ParameterUpdateExecuted(_proposalId, proposal.paramName, proposal.newValue);
    }

    /**
     * @dev Allows a user to cast their vote on a DAO governance proposal (treasury withdrawal or parameter update).
     * Voting power is calculated using `calculateEffectiveVotingPower`.
     * @param _proposalId The ID of the DAO proposal to vote on.
     * @param _support True for 'for' the proposal, false for 'against'.
     */
    function voteOnDaoProposal(uint256 _proposalId, bool _support) external {
        DaoProposal storage proposal = daoProposals[_proposalId];
        require(block.timestamp <= proposal.votingPeriodEnd, "SyntheticaGrantsDAO: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "SyntheticaGrantsDAO: Already voted on this proposal");

        uint256 votingPower = calculateEffectiveVotingPower(msg.sender);
        require(votingPower > 0, "SyntheticaGrantsDAO: Caller has no voting power");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, true);
    }

    // --- II. AI Oracle & External Data Integration ---

    /**
     * @dev Sets the address of the AI Oracle contract. Only callable by the contract owner.
     * In a full DAO, this might become a governance-controlled parameter.
     * @param _newOracle The address of the new AI Oracle contract.
     */
    function setAIOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "SyntheticaGrantsDAO: AI Oracle address cannot be zero");
        aiOracleAddress = _newOracle;
        emit AIOracleAddressSet(_newOracle);
    }

    /**
     * @dev Initiates a request to the configured AI oracle for an initial score of a grant proposal.
     * This function is typically called internally after a grant proposal is submitted.
     * @param _grantId The ID of the grant proposal.
     * @param _proposalHash IPFS/Arweave hash of the detailed proposal document for the AI to analyze.
     */
    function requestAIScoreForGrant(uint256 _grantId, string calldata _proposalHash) internal {
        require(aiOracleAddress != address(0), "SyntheticaGrantsDAO: AI Oracle not set");
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
        require(grant.status == GrantStatus.PendingAI, "SyntheticaGrantsDAO: Grant not in PendingAI status");
        
        // This simulates a call to an external AI oracle.
        // The oracle would then perform its analysis and call `receiveAIScore` back on this contract.
        IAIOracle(aiOracleAddress).requestAIScore(_grantId, _proposalHash, address(this), this.receiveAIScore.selector);
        
        emit AIScoreRequested(_grantId, _proposalHash);
    }

    /**
     * @dev Callback function for the AI Oracle to deliver a score for a grant proposal.
     * This function can only be called by the `aiOracleAddress`.
     * @param _grantId The ID of the grant proposal for which the score is provided.
     * @param _score The AI-generated score (e.g., 0-100).
     * @param _detailsHash An optional hash for more detailed AI analysis reports.
     */
    function receiveAIScore(uint256 _grantId, uint256 _score, bytes32 _detailsHash) external onlyAIOracle {
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
        require(grant.status == GrantStatus.PendingAI, "SyntheticaGrantsDAO: Grant not awaiting AI score");

        grant.aiScore = _score;
        grant.status = GrantStatus.PendingEvaluation; // Move to the next stage after AI scoring
        // The _detailsHash can store a hash of the full AI report if needed
        
        emit AIScoreReceived(_grantId, _score);
    }

    // --- III. Soulbound Impact Tokens (SITs) - Reputation System ---

    /**
     * @dev Returns the Soulbound Impact Token (SIT) balance of a given user.
     * SITs are non-transferable and represent a user's accumulated reputation and impact.
     * @param _user The address of the user.
     * @return The SIT balance of the user.
     */
    function getSITBalance(address _user) public view returns (uint256) {
        return s_sitBalances[_user];
    }

    /**
     * @dev Calculates a user's effective voting power within the DAO.
     * This power is a combination of their `governanceToken` balance and a boosted value
     * derived from their SIT balance, making SITs a powerful, non-transferable influence factor.
     * @param _voter The address of the voter.
     * @return The calculated effective voting power.
     */
    function calculateEffectiveVotingPower(address _voter) public view returns (uint256) {
        uint256 tokenBalance = governanceToken.balanceOf(_voter);
        uint256 sitBalance = getSITBalance(_voter);
        uint256 sitMultiplier = daoParameters[bytes32(abi.encodePacked(ParamNames.SIT_MULTIPLIER_FOR_VOTING))];
        
        // Base voting power is governance token balance + (SIT balance * multiplier)
        return tokenBalance.add(sitBalance.mul(sitMultiplier));
    }

    /**
     * @dev Internal function to mint Soulbound Impact Tokens (SITs) to a recipient.
     * This is called by the contract's logic upon verifiable positive actions.
     * @param _recipient The address to mint SITs to.
     * @param _amount The amount of SITs to mint.
     * @param _reasonHash A hash detailing the reason for minting (e.g., project success, good evaluation).
     */
    function _mintSIT(address _recipient, uint256 _amount, bytes32 _reasonHash) internal {
        s_sitBalances[_recipient] = s_sitBalances[_recipient].add(_amount);
        emit SITMinted(_recipient, _amount, _reasonHash);
    }

    /**
     * @dev Internal function to burn Soulbound Impact Tokens (SITs) from a holder.
     * This is called by the contract's logic upon verifiable negative actions or failures.
     * @param _holder The address from which to burn SITs.
     * @param _amount The amount of SITs to burn.
     * @param _reasonHash A hash detailing the reason for burning (e.g., project failure, malicious behavior).
     */
    function _burnSIT(address _holder, uint256 _amount, bytes32 _reasonHash) internal {
        s_sitBalances[_holder] = s_sitBalances[_holder].sub(_amount); // Subtraction with underflow check by SafeMath
        emit SITBurned(_holder, _amount, _reasonHash);
    }

    // --- IV. Grant Proposal Lifecycle ---

    /**
     * @dev Allows a user to submit a new grant proposal to the DAO.
     * Requires a deposit of `MIN_GRANT_PROPOSAL_DEPOSIT` tokens, which is refunded if the grant is rejected.
     * The proposal immediately enters the `PendingAI` or `PendingEvaluation` status.
     * @param _title The title of the grant proposal.
     * @param _descriptionHash IPFS/Arweave hash for detailed proposal content.
     * @param _requestedAmount The amount of `governanceToken` requested for the grant.
     */
    function submitGrantProposal(
        string calldata _title,
        string calldata _descriptionHash,
        uint256 _requestedAmount
    ) external {
        require(_requestedAmount > 0, "SyntheticaGrantsDAO: Requested amount must be greater than zero");
        uint256 proposalDeposit = daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_GRANT_PROPOSAL_DEPOSIT))];
        require(governanceToken.transferFrom(msg.sender, address(this), proposalDeposit), "SyntheticaGrantsDAO: Deposit failed");

        uint256 grantId = nextGrantId++;
        GrantProposal storage grant = grantProposals[grantId];
        grant.proposer = msg.sender;
        grant.title = _title;
        grant.descriptionHash = _descriptionHash;
        grant.requestedAmount = _requestedAmount;
        grant.submittedTime = block.timestamp;
        grant.status = GrantStatus.PendingAI; // Initial state: Awaiting AI score

        // Automatically request AI score if an oracle is configured, otherwise skip to PendingEvaluation
        if (aiOracleAddress != address(0)) {
            requestAIScoreForGrant(grantId, _descriptionHash);
        } else {
            grant.status = GrantStatus.PendingEvaluation; // Skip AI if no oracle
        }

        emit GrantProposalSubmitted(grantId, msg.sender, _requestedAmount, _title);
    }

    /**
     * @dev Allows a user to stake tokens and evaluate an active grant proposal.
     * Evaluators provide a score (1-100) and a justification (via hash).
     * The evaluation stake is non-refundable for this simplified example, acting as an evaluation fee.
     * @param _grantId The ID of the grant proposal to evaluate.
     * @param _score The evaluation score (1-100).
     * @param _justificationHash IPFS/Arweave hash for the detailed evaluation justification.
     */
    function stakeAndEvaluateGrant(uint256 _grantId, uint256 _score, bytes32 _justificationHash) external {
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
        require(grant.status == GrantStatus.PendingEvaluation, "SyntheticaGrantsDAO: Grant not in evaluation stage");
        require(_score <= 100 && _score > 0, "SyntheticaGrantsDAO: Score must be between 1 and 100");
        require(!grant.hasEvaluated[msg.sender], "SyntheticaGrantsDAO: Already evaluated this grant");

        uint256 evaluationStake = daoParameters[bytes32(abi.encodePacked(ParamNames.GRANT_EVALUATION_STAKE))];
        require(governanceToken.transferFrom(msg.sender, address(this), evaluationStake), "SyntheticaGrantsDAO: Stake transfer failed");

        grant.evaluatorScores[msg.sender] = _score;
        grant.hasEvaluated[msg.sender] = true;
        grant.evaluationCount = grant.evaluationCount.add(1);
        grant.evaluationStakeTotal = grant.evaluationStakeTotal.add(evaluationStake); // Staked tokens for evaluation go to treasury

        // Update average score: simplified average calculation.
        // A weighted average (e.g., by evaluator's SITs) could be more advanced.
        grant.avgEvaluatorScore = (grant.avgEvaluatorScore.mul(grant.evaluationCount.sub(1)).add(_score)) / grant.evaluationCount;

        emit GrantEvaluated(_grantId, msg.sender, _score);

        // If enough evaluators have submitted, move the grant to the voting stage
        if (grant.evaluationCount >= daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_EVALUATORS_PER_GRANT))]) {
            grant.status = GrantStatus.PendingVoting;
            grant.votingPeriodEnd = block.timestamp + daoParameters[bytes32(abi.encodePacked(ParamNames.GRANT_VOTING_PERIOD))];
        }
    }

    /**
     * @dev Allows users to cast their vote on a grant proposal that is in the `PendingVoting` stage.
     * Voting power is determined by `calculateEffectiveVotingPower`.
     * @param _grantId The ID of the grant proposal to vote on.
     * @param _support True for 'for' the proposal, false for 'against'.
     */
    function voteOnGrantProposal(uint256 _grantId, bool _support) external {
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
        require(grant.status == GrantStatus.PendingVoting, "SyntheticaGrantsDAO: Grant not in voting stage");
        require(block.timestamp <= grant.votingPeriodEnd, "SyntheticaGrantsDAO: Voting period has ended");
        require(!grant.hasVoted[msg.sender], "SyntheticaGrantsDAO: Already voted on this grant");

        uint256 votingPower = calculateEffectiveVotingPower(msg.sender);
        require(votingPower > 0, "SyntheticaGrantsDAO: Caller has no voting power");

        if (_support) {
            grant.votesFor = grant.votesFor.add(votingPower);
        } else {
            grant.votesAgainst = grant.votesAgainst.add(votingPower);
        }
        grant.hasVoted[msg.sender] = true;

        emit VoteCast(_grantId, msg.sender, _support, false);
    }

    /**
     * @dev Finalizes the voting period for a grant proposal, determining its final status.
     * If approved, it moves to `Approved`, otherwise `Rejected`.
     * The proposer's initial deposit is refunded if the grant is not funded.
     * @param _grantId The ID of the grant proposal to finalize.
     */
    function finalizeGrantVoting(uint256 _grantId) external {
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
        require(grant.status == GrantStatus.PendingVoting, "SyntheticaGrantsDAO: Grant not in voting stage");
        require(block.timestamp > grant.votingPeriodEnd, "SyntheticaGrantsDAO: Voting period has not ended");

        uint256 totalVotes = grant.votesFor.add(grant.votesAgainst);
        GrantStatus newStatus;

        if (totalVotes == 0) {
            newStatus = GrantStatus.Rejected; // No voting participation leads to rejection
        } else {
            uint256 approvalThreshold = daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_GRANT_APPROVAL_THRESHOLD_PERCENT))];
            if (grant.votesFor.mul(100) / totalVotes >= approvalThreshold) {
                newStatus = GrantStatus.Approved;
            } else {
                newStatus = GrantStatus.Rejected;
            }
        }
        
        grant.status = newStatus;
        
        // Refund proposer's deposit if not approved, or if approved but not funded (will be refunded on rejection)
        if (newStatus == GrantStatus.Rejected || newStatus == GrantStatus.Withdrawn) { // Add Withdrawn for completeness, though not explicitly used here
            uint256 proposalDeposit = daoParameters[bytes32(abi.encodePacked(ParamNames.MIN_GRANT_PROPOSAL_DEPOSIT))];
            require(governanceToken.transfer(grant.proposer, proposalDeposit), "SyntheticaGrantsDAO: Proposer deposit refund failed");
        }
        // Evaluator stakes are implicitly handled (remain in treasury as a fee). A claim system would be needed for refunds.

        emit GrantVotingFinalized(_grantId, newStatus);
    }

    /**
     * @dev Releases the requested funds to an approved grant proposal.
     * Requires the grant to be in the `Approved` status and sufficient funds in the treasury.
     * Mint SITs to the proposer for successful funding.
     * @param _grantId The ID of the grant proposal to fund.
     */
    function releaseGrantFunds(uint256 _grantId) external {
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
        require(grant.status == GrantStatus.Approved, "SyntheticaGrantsDAO: Grant not in Approved status");
        require(governanceToken.balanceOf(address(this)) >= grant.requestedAmount, "SyntheticaGrantsDAO: Insufficient treasury funds");
        
        // Transfer funds to the proposer
        require(governanceToken.transfer(grant.proposer, grant.requestedAmount), "SyntheticaGrantsDAO: Fund release failed");
        
        grant.status = GrantStatus.Funded;
        // Mint SITs for the proposer as a reward for getting funded
        _mintSIT(grant.proposer, grant.requestedAmount.div(1000), keccak256(abi.encodePacked("GrantFundingSuccess", _grantId))); // Example: 1 SIT per 1000 tokens funded
        
        emit GrantFundsReleased(_grantId, grant.requestedAmount);
    }

    /**
     * @dev Allows the proposer of a funded grant to submit an impact report.
     * @param _grantId The ID of the funded grant.
     * @param _reportHash IPFS/Arweave hash for the detailed impact report.
     */
    function submitImpactReport(uint256 _grantId, bytes32 _reportHash) external {
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer == msg.sender, "SyntheticaGrantsDAO: Only proposer can submit impact report");
        require(grant.status == GrantStatus.Funded, "SyntheticaGrantsDAO: Grant not yet funded or impact already reported");
        require(_reportHash != bytes32(0), "SyntheticaGrantsDAO: Report hash cannot be empty");

        grant.impactReportHash = _reportHash;
        grant.status = GrantStatus.ImpactReportSubmitted;
        emit ImpactReportSubmitted(_grantId, msg.sender, _reportHash);
    }

    /**
     * @dev Verifies the impact report of a funded grant and assigns a final impact score.
     * This function's caller should be a trusted entity or governed by another DAO mechanism.
     * SITs are minted or burned from the proposer based on the final impact score.
     * @param _grantId The ID of the grant to verify impact for.
     * @param _finalImpactScore The final impact score (0-100) assigned to the project.
     */
    function verifyGrantImpact(uint256 _grantId, uint256 _finalImpactScore) external {
        // In a more decentralized system, this would be a governance action or a challenge resolution,
        // rather than owner-only or a single designated role.
        require(msg.sender == owner(), "SyntheticaGrantsDAO: Only owner can verify impact (simplified)");
        
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
        require(grant.status == GrantStatus.ImpactReportSubmitted, "SyntheticaGrantsDAO: Impact report not submitted or already verified");
        require(_finalImpactScore <= 100, "SyntheticaGrantsDAO: Impact score must be between 0 and 100");

        grant.finalImpactScore = _finalImpactScore;
        grant.status = GrantStatus.ImpactVerified;

        // Reward / penalize proposer based on impact score
        if (_finalImpactScore >= 70) { // Example: Good impact threshold
            _mintSIT(grant.proposer, grant.requestedAmount.mul(_finalImpactScore).div(100000), keccak256(abi.encodePacked("GrantImpactSuccess", _grantId)));
        } else if (_finalImpactScore < 30) { // Example: Poor impact threshold
            _burnSIT(grant.proposer, s_sitBalances[grant.proposer].div(10), keccak256(abi.encodePacked("GrantImpactFailure", _grantId)));
        }
        // Additional logic could be added here to reward evaluators whose initial scores were accurate.

        emit GrantImpactVerified(_grantId, _finalImpactScore);
    }

    // --- V. Impact Intents - Micro-Task System ---

    /**
     * @dev Creates a new "Impact Intent" - a specific, smaller task with a defined reward and deadline.
     * Requires the DAO treasury to hold sufficient funds for the reward.
     * @param _description A brief description of the intent/task.
     * @param _rewardAmount The amount of `governanceToken` to be paid to the solver.
     * @param _deadline The timestamp by which the task must be completed.
     * @param _challengeHash IPFS/Arweave hash for detailed requirements and success criteria.
     */
    function proposeImpactIntent(
        string calldata _description,
        uint256 _rewardAmount,
        uint256 _deadline,
        bytes32 _challengeHash
    ) external {
        require(_rewardAmount > 0, "SyntheticaGrantsDAO: Reward amount must be greater than zero");
        require(_deadline > block.timestamp, "SyntheticaGrantsDAO: Deadline must be in the future");
        require(governanceToken.balanceOf(address(this)) >= _rewardAmount, "SyntheticaGrantsDAO: Insufficient treasury funds for reward");

        uint256 intentId = nextIntentId++;
        ImpactIntent storage intent = impactIntents[intentId];
        intent.proposer = msg.sender;
        intent.description = _description;
        intent.rewardAmount = _rewardAmount;
        intent.deadline = _deadline;
        intent.initialChallengeHash = _challengeHash;
        intent.creationTime = block.timestamp;
        intent.status = IntentStatus.Proposed;

        emit ImpactIntentProposed(intentId, msg.sender, _rewardAmount);
    }

    /**
     * @dev Allows a user to bid on an Impact Intent, staking tokens to show commitment.
     * The staked amount is added to the intent's total bid stake.
     * @param _intentId The ID of the Impact Intent to bid on.
     * @param _stakeAmount The amount of `governanceToken` to stake with the bid.
     */
    function bidOnImpactIntent(uint256 _intentId, uint256 _stakeAmount) external {
        ImpactIntent storage intent = impactIntents[_intentId];
        require(intent.proposer != address(0), "SyntheticaGrantsDAO: Intent does not exist");
        require(intent.status == IntentStatus.Proposed || intent.status == IntentStatus.Bidding, "SyntheticaGrantsDAO: Intent not in bidding stage");
        require(block.timestamp < intent.deadline, "SyntheticaGrantsDAO: Bidding period for this intent has ended");
        require(governanceToken.transferFrom(msg.sender, address(this), _stakeAmount), "SyntheticaGrantsDAO: Stake transfer failed");
        
        intent.bids[msg.sender] = intent.bids[msg.sender].add(_stakeAmount);
        intent.totalBidStake = intent.totalBidStake.add(_stakeAmount);
        intent.status = IntentStatus.Bidding; // Ensure status reflects bidding is open
        
        emit ImpactIntentBid(_intentId, msg.sender, _stakeAmount);
    }

    /**
     * @dev Assigns a solver to an Impact Intent from the pool of bidders.
     * Only the intent proposer can assign a solver. Other bidders' stakes are effectively forfeited to the treasury.
     * @param _intentId The ID of the Impact Intent.
     * @param _solver The address of the chosen solver.
     */
    function assignIntentSolver(uint256 _intentId, address _solver) external {
        ImpactIntent storage intent = impactIntents[_intentId];
        require(intent.proposer != address(0), "SyntheticaGrantsDAO: Intent does not exist");
        require(intent.proposer == msg.sender, "SyntheticaGrantsDAO: Only intent proposer can assign a solver");
        require(intent.status == IntentStatus.Bidding || intent.status == IntentStatus.Proposed, "SyntheticaGrantsDAO: Intent not in bidding/proposed stage");
        require(block.timestamp < intent.deadline, "SyntheticaGrantsDAO: Cannot assign solver after deadline");
        require(intent.bids[_solver] > 0, "SyntheticaGrantsDAO: Solver has not placed a bid");
        
        intent.assignedSolver = _solver;
        intent.status = IntentStatus.Assigned;

        // In this simplified model, other bidders' stakes remain in the treasury.
        // A more complex system could implement a claim function for non-assigned bidders.

        emit ImpactIntentAssigned(_intentId, _solver);
    }

    /**
     * @dev Allows the assigned solver to submit proof of fulfilling an Impact Intent.
     * @param _intentId The ID of the Impact Intent.
     * @param _proofHash IPFS/Arweave hash for the detailed proof of fulfillment.
     */
    function submitIntentFulfillmentProof(uint256 _intentId, bytes32 _proofHash) external {
        ImpactIntent storage intent = impactIntents[_intentId];
        require(intent.proposer != address(0), "SyntheticaGrantsDAO: Intent does not exist");
        require(intent.assignedSolver == msg.sender, "SyntheticaGrantsDAO: Only assigned solver can submit proof");
        require(intent.status == IntentStatus.Assigned, "SyntheticaGrantsDAO: Intent not in assigned status");
        require(block.timestamp <= intent.deadline, "SyntheticaGrantsDAO: Deadline passed for submission");
        require(_proofHash != bytes32(0), "SyntheticaGrantsDAO: Proof hash cannot be empty");

        intent.fulfillmentProofHash = _proofHash;
        intent.status = IntentStatus.ProofSubmitted;

        emit IntentProofSubmitted(_intentId, msg.sender, _proofHash);
    }

    /**
     * @dev Verifies the fulfillment of an Impact Intent.
     * This function's caller should be the intent proposer or a designated verifier.
     * If fulfilled, the solver receives the reward and their stake back, and both proposer and solver get SITs.
     * If not fulfilled, the solver's stake is slashed (remains in treasury), and SITs are burned.
     * @param _intentId The ID of the Impact Intent.
     * @param _isFulfilled True if the intent is considered fulfilled, false otherwise.
     */
    function verifyIntentFulfillment(uint256 _intentId, bool _isFulfilled) external {
        // This function's caller should be a trusted entity or governed by another DAO mechanism.
        require(impactIntents[_intentId].proposer == msg.sender, "SyntheticaGrantsDAO: Only intent proposer can verify fulfillment (simplified)");
        
        ImpactIntent storage intent = impactIntents[_intentId];
        require(intent.proposer != address(0), "SyntheticaGrantsDAO: Intent does not exist");
        require(intent.status == IntentStatus.ProofSubmitted, "SyntheticaGrantsDAO: Intent not in ProofSubmitted status");
        
        intent.fulfillmentVerificationTime = block.timestamp;

        if (_isFulfilled) {
            intent.status = IntentStatus.Fulfilled;
            // Transfer reward to solver
            require(governanceToken.transfer(intent.assignedSolver, intent.rewardAmount), "SyntheticaGrantsDAO: Reward transfer failed");
            // Return solver's stake
            require(governanceToken.transfer(intent.assignedSolver, intent.bids[intent.assignedSolver]), "SyntheticaGrantsDAO: Solver stake refund failed");
            // Mint SITs for solver for successful fulfillment
            _mintSIT(intent.assignedSolver, intent.rewardAmount.div(100), keccak256(abi.encodePacked("IntentFulfillmentSuccess", _intentId))); // Example: 1 SIT per 100 tokens
            // Mint SITs for proposer for successful intent execution
            _mintSIT(intent.proposer, intent.rewardAmount.div(500), keccak256(abi.encodePacked("IntentProposerSuccess", _intentId))); // Proposer gets some SITs too
        } else {
            intent.status = IntentStatus.Rejected;
            // Solver's stake is slashed (remains in treasury); no explicit transfer needed as it's already there.
            // Burn SITs from solver for failure
            _burnSIT(intent.assignedSolver, s_sitBalances[intent.assignedSolver].div(5), keccak256(abi.encodePacked("IntentFulfillmentFailure", _intentId)));
        }
        emit IntentFulfillmentVerified(_intentId, _isFulfilled);
    }

    // --- VI. Dispute Resolution ---

    /**
     * @dev Initiates a challenge against an outcome (e.g., grant impact score, intent fulfillment).
     * Requires a `CHALLENGE_STAKE` to be deposited, which is at risk.
     * The challenged entity's status is updated to `Challenged`.
     * @param _entityId The ID of the entity being challenged (e.g., `grantId`, `intentId`).
     * @param _entityType The type of the entity being challenged (GrantProposal, ImpactIntent, etc.).
     * @param _challengeDetailsHash IPFS/Arweave hash for detailed reasons for the challenge.
     */
    function challengeOutcome(uint256 _entityId, EntityType _entityType, bytes32 _challengeDetailsHash) external {
        require(_challengeDetailsHash != bytes32(0), "SyntheticaGrantsDAO: Challenge details hash cannot be empty");
        uint256 challengeStake = daoParameters[bytes32(abi.encodePacked(ParamNames.CHALLENGE_STAKE))];
        require(governanceToken.transferFrom(msg.sender, address(this), challengeStake), "SyntheticaGrantsDAO: Challenge stake transfer failed");

        uint256 challengeId = nextChallengeId++;
        Challenge storage challenge = challenges[challengeId];
        challenge.challenger = msg.sender;
        challenge.entityId = _entityId;
        challenge.entityType = _entityType;
        challenge.challengeDetailsHash = _challengeDetailsHash;
        challenge.submissionTime = block.timestamp;
        challenge.challengeStake = challengeStake;
        challenge.votingPeriodEnd = block.timestamp + daoParameters[bytes32(abi.encodePacked(ParamNames.CHALLENGE_VOTING_PERIOD))];
        challenge.outcome = ChallengeOutcome.Pending;

        // Update status of the challenged entity to reflect that it's under dispute
        if (_entityType == EntityType.GrantProposal) {
            GrantProposal storage grant = grantProposals[_entityId];
            require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
            require(grant.status != GrantStatus.Challenged, "SyntheticaGrantsDAO: Grant already challenged");
            grant.status = GrantStatus.Challenged;
        } else if (_entityType == EntityType.ImpactIntent) {
            ImpactIntent storage intent = impactIntents[_entityId];
            require(intent.proposer != address(0), "SyntheticaGrantsDAO: Intent does not exist");
            require(intent.status != IntentStatus.Challenged, "SyntheticaGrantsDAO: Intent already challenged");
            intent.status = IntentStatus.Challenged;
        }
        // Additional entity types (e.g., EvaluatorScore) would have specific logic here.

        emit ChallengeProposed(challengeId, msg.sender, _entityId, _entityType);
    }

    /**
     * @dev Allows users to vote on an ongoing challenge.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _supportUpheld True to vote to uphold the challenger's claim, false to reject it.
     */
    function voteOnChallenge(uint256 _challengeId, bool _supportUpheld) external {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "SyntheticaGrantsDAO: Challenge does not exist");
        require(challenge.outcome == ChallengeOutcome.Pending, "SyntheticaGrantsDAO: Challenge already resolved");
        require(block.timestamp <= challenge.votingPeriodEnd, "SyntheticaGrantsDAO: Voting period has ended");
        require(!challenge.hasVoted[msg.sender], "SyntheticaGrantsDAO: Already voted on this challenge");

        uint256 votingPower = calculateEffectiveVotingPower(msg.sender);
        require(votingPower > 0, "SyntheticaGrantsDAO: Caller has no voting power");

        if (_supportUpheld) {
            challenge.votesForUpheld = challenge.votesForUpheld.add(votingPower);
        } else {
            challenge.votesForRejected = challenge.votesForRejected.add(votingPower);
        }
        challenge.hasVoted[msg.sender] = true;
    }

    /**
     * @dev Resolves a challenge after its voting period has ended.
     * This function's caller should be a trusted arbitrator or governed by a specific DAO role.
     * Based on the voting outcome, the challenger's stake is either returned (if upheld) or forfeited (if rejected).
     * The status of the challenged entity is updated accordingly.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _resolutionDetailsHash IPFS/Arweave hash for detailed resolution notes.
     */
    function resolveChallenge(uint256 _challengeId, bytes32 _resolutionDetailsHash) external {
        // In a more decentralized system, this would be a governance action or require a specific role.
        require(msg.sender == owner(), "SyntheticaGrantsDAO: Only owner can resolve challenges (simplified)");
        
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "SyntheticaGrantsDAO: Challenge does not exist");
        require(challenge.outcome == ChallengeOutcome.Pending, "SyntheticaGrantsDAO: Challenge already resolved");
        require(block.timestamp > challenge.votingPeriodEnd, "SyntheticaGrantsDAO: Challenge voting not ended");

        uint256 totalVotes = challenge.votesForUpheld.add(challenge.votesForRejected);
        ChallengeOutcome finalOutcome;

        if (totalVotes == 0) {
            finalOutcome = ChallengeOutcome.Rejected; // No votes, default to rejecting the challenge
        } else {
            if (challenge.votesForUpheld > challenge.votesForRejected) {
                finalOutcome = ChallengeOutcome.Upheld;
            } else {
                finalOutcome = ChallengeOutcome.Rejected;
            }
        }
        challenge.outcome = finalOutcome;
        challenge.resolved = true;

        // Handle consequences based on resolution
        if (finalOutcome == ChallengeOutcome.Upheld) {
            // Challenger wins, gets their stake back
            require(governanceToken.transfer(challenge.challenger, challenge.challengeStake), "SyntheticaGrantsDAO: Challenger stake refund failed");
            // Specific actions based on entity type would go here
            // Example: If a grant's 'ImpactVerified' status was challenged and upheld, it might lead to _burnSIT for the original verifier or reverse previous SIT mints.
        } else { // Challenge Rejected
            // Challenger loses their stake (remains in treasury); no explicit transfer needed as it's already there.
        }

        // Restore or update the status of the challenged entity
        if (challenge.entityType == EntityType.GrantProposal) {
            GrantProposal storage grant = grantProposals[challenge.entityId];
            if (grant.status == GrantStatus.Challenged) {
                // If the challenge was upheld, the grant might be moved to 'Rejected'
                // If rejected, it might revert to its previous status or a new 'ControversyResolved' status
                grant.status = (finalOutcome == ChallengeOutcome.Upheld) ? GrantStatus.Rejected : GrantStatus.ImpactVerified; // Simplified example
            }
        } else if (challenge.entityType == EntityType.ImpactIntent) {
            ImpactIntent storage intent = impactIntents[challenge.entityId];
            if (intent.status == IntentStatus.Challenged) {
                intent.status = (finalOutcome == ChallengeOutcome.Upheld) ? IntentStatus.Rejected : IntentStatus.Fulfilled; // Simplified example
            }
        }

        emit ChallengeResolved(_challengeId, finalOutcome);
    }

    // --- VII. View Functions ---

    /**
     * @dev Retrieves all relevant details for a specific grant proposal.
     * @param _grantId The ID of the grant proposal.
     * @return All fields of the `GrantProposal` struct.
     */
    function getGrantDetails(uint256 _grantId) public view returns (
        address proposer,
        string memory title,
        string memory descriptionHash,
        uint256 requestedAmount,
        uint256 submittedTime,
        uint256 aiScore,
        uint256 avgEvaluatorScore,
        uint256 evaluationCount,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votingPeriodEnd,
        GrantStatus status,
        bytes32 impactReportHash,
        uint256 finalImpactScore
    ) {
        GrantProposal storage grant = grantProposals[_grantId];
        require(grant.proposer != address(0), "SyntheticaGrantsDAO: Grant does not exist");
        return (
            grant.proposer,
            grant.title,
            grant.descriptionHash,
            grant.requestedAmount,
            grant.submittedTime,
            grant.aiScore,
            grant.avgEvaluatorScore,
            grant.evaluationCount,
            grant.votesFor,
            grant.votesAgainst,
            grant.votingPeriodEnd,
            grant.status,
            grant.impactReportHash,
            grant.finalImpactScore
        );
    }

    /**
     * @dev Retrieves all relevant details for a specific Impact Intent.
     * @param _intentId The ID of the Impact Intent.
     * @return All fields of the `ImpactIntent` struct.
     */
    function getIntentDetails(uint256 _intentId) public view returns (
        address proposer,
        string memory description,
        uint256 rewardAmount,
        uint256 deadline,
        bytes32 initialChallengeHash,
        uint256 creationTime,
        IntentStatus status,
        address assignedSolver,
        bytes32 fulfillmentProofHash,
        uint256 fulfillmentVerificationTime,
        uint256 totalBidStake
    ) {
        ImpactIntent storage intent = impactIntents[_intentId];
        require(intent.proposer != address(0), "SyntheticaGrantsDAO: Intent does not exist");
        return (
            intent.proposer,
            intent.description,
            intent.rewardAmount,
            intent.deadline,
            intent.initialChallengeHash,
            intent.creationTime,
            intent.status,
            intent.assignedSolver,
            intent.fulfillmentProofHash,
            intent.fulfillmentVerificationTime,
            intent.totalBidStake
        );
    }

    /**
     * @dev Retrieves the current value of a DAO parameter.
     * @param _paramName The `bytes32` hash of the parameter name.
     * @return The `uint256` value of the parameter.
     */
    function getDaoParameter(bytes32 _paramName) public view returns (uint256) {
        return daoParameters[_paramName];
    }
}
```