Here's a smart contract in Solidity that aims to be interesting, advanced, creative, and trendy, focusing on a "Decentralized On-chain AI Agent & Knowledge Base Protocol." It integrates concepts like dynamic reputation, adaptive governance for AI parameters, and tokenized incentives for knowledge curation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For utilities if needed

/**
 * @title Aethermind: A Decentralized On-chain AI Agent & Knowledge Base Protocol
 * @author [Your Name/Alias]
 * @custom:version 1.0.0
 * @notice This contract facilitates the creation, curation, and governance of decentralized "AI Agents"
 *         and a community-contributed "Knowledge Base." It introduces dynamic scoring mechanisms
 *         for knowledge validity and agent reputation, driven by token staking and governance.
 *
 * Key Features:
 * - Dynamic Knowledge Units: Users submit facts, models, or insights. Their validity is dynamically
 *   scored based on community verification and dispute staking. Valid units earn rewards.
 * - AI Agent Profiles: Addresses can register on-chain agents. Agents submit "insights" (special
 *   knowledge units) and their performance is tracked.
 * - Reputation System: Agents earn reputation based on the accuracy and value of their
 *   submitted insights, influencing their influence and rewards.
 * - Adaptive Governance: A token-based staking and voting mechanism allows the community
 *   to propose and enact changes to agent parameters, system rules, and knowledge validity.
 * - Incentive Mechanisms: Rewards are distributed from a community pool for valuable knowledge
 *   contributions, successful verifications, and high-performing agents.
 *
 * This contract combines elements of decentralized knowledge management (DeSci), adaptive AI governance (DeAI),
 * and reputation-based incentive structures, aiming to create a self-improving, community-driven
 * intelligent network on the blockchain.
 */
contract Aethermind is Ownable, Pausable {

    // --- Outline:
    // 1. Interfaces (IERC20 from OpenZeppelin)
    // 2. Error Definitions
    // 3. Contract Core: Aethermind
    //    A. State Variables & Mappings
    //    B. Structures: KnowledgeUnit, AgentProfile, Proposal
    //    C. Events
    //    D. Modifiers
    //    E. Constructor
    //    F. Core & Setup Functions (5)
    //       - setRewardTokenAddress
    //       - pause/unpause (from Pausable)
    //       - setFeeRecipient
    //       - transferOwnership (from Ownable)
    //    G. Knowledge Base Management Functions (8)
    //       - submitKnowledgeUnit
    //       - getKnowledgeUnit
    //       - verifyKnowledgeUnit
    //       - disputeKnowledgeUnit
    //       - retractKnowledgeUnitStake
    //       - updateKnowledgeUnitMetadata
    //       - getKnowledgeUnitValidityScore
    //       - distributeKnowledgeUnitRewards
    //    H. AI Agent Management Functions (6)
    //       - registerAgent
    //       - getAgentProfile
    //       - updateAgentDescription
    //       - submitAgentInsight
    //       - evaluateAgentInsight
    //       - getAgentReputationScore
    //    I. Governance & Staking Functions (8)
    //       - stakeForGovernance
    //       - unstakeFromGovernance
    //       - getVotingPower
    //       - createProposal
    //       - voteOnProposal
    //       - endProposalVoting
    //       - executeProposal
    //       - claimRewards
    //    J. Reward Pool Management (1)
    //       - depositToRewardPool
    //
    // Total functions: 28 (excluding inherited Ownable/Pausable ones explicitly re-listed, but including their functionality count)

    // --- Function Summary:
    //
    // Core & Setup:
    //   - constructor: Initializes the contract owner and the ERC20 reward token address.
    //   - setRewardTokenAddress: Allows the owner to update the address of the ERC20 reward token.
    //   - pause/unpause: (Inherited from Pausable) Allows owner to pause/unpause critical functions for emergency.
    //   - setFeeRecipient: Sets the address where platform fees (if any are implemented) are sent.
    //   - transferOwnership: (Inherited from Ownable) Transfers contract ownership to a new address.
    //
    // Knowledge Base Management:
    //   - submitKnowledgeUnit: Allows users to submit a new "Knowledge Unit" (e.g., fact, model parameter, insight).
    //     Requires an optional stake and provides a content hash (e.g., IPFS) and metadata URI.
    //   - getKnowledgeUnit: Retrieves all stored details for a given knowledge unit ID.
    //   - verifyKnowledgeUnit: Users stake reward tokens to attest to the accuracy or value of a knowledge unit,
    //     increasing its dynamic `validityScore`.
    //   - disputeKnowledgeUnit: Users stake reward tokens to challenge a knowledge unit's validity,
    //     decreasing its dynamic `validityScore`.
    //   - retractKnowledgeUnitStake: Allows a user to retrieve their staked tokens for verification/dispute
    //     if the unit's rewards haven't been distributed yet.
    //   - updateKnowledgeUnitMetadata: Allows the original contributor or governance to update the metadata URI
    //     associated with a knowledge unit.
    //   - getKnowledgeUnitValidityScore: Returns the current dynamic validity score of a knowledge unit.
    //   - distributeKnowledgeUnitRewards: Owner or governance triggers the allocation of rewards for a highly valid knowledge unit.
    //     Rewards are added to the contributor's pending claims. Individual verifier/disputer claims are handled on `claimRewards`.
    //
    // AI Agent Management:
    //   - registerAgent: Allows an address to register a new "AI Agent" profile, requiring an initial token stake.
    //   - getAgentProfile: Retrieves all stored details for a given AI agent ID.
    //   - updateAgentDescription: Allows an agent's owner to update its descriptive metadata URI.
    //   - submitAgentInsight: An agent owner submits an "insight" or "prediction" on behalf of their agent,
    //     which is recorded as a special type of knowledge unit.
    //   - evaluateAgentInsight: Owner or governance evaluates a past agent insight/prediction against an outcome,
    //     dynamically adjusting the agent's `reputationScore` and potentially allocating rewards.
    //   - getAgentReputationScore: Returns the current reputation score of an AI agent.
    //
    // Governance & Staking:
    //   - stakeForGovernance: Users stake reward tokens to gain voting power for governance proposals.
    //   - unstakeFromGovernance: Users unstake their governance tokens, reducing their voting power.
    //   - getVotingPower: Returns the current voting power of an address.
    //   - createProposal: Allows users with sufficient voting power to submit a new governance proposal
    //     (e.g., to change agent parameters, review knowledge unit validity, or adjust system rules).
    //   - voteOnProposal: Allows stakers to cast a 'yes' or 'no' vote on an active proposal.
    //   - endProposalVoting: Any address can call this after the voting period ends to finalize vote counts.
    //   - executeProposal: Owner or governance executes a passed proposal, applying its changes to the system.
    //   - claimRewards: Allows users to claim their accumulated rewards from contributions, successful verifications,
    //     disputes, or agent performance.
    //
    // Reward Pool Management:
    //   - depositToRewardPool: Allows anyone to deposit reward tokens into the protocol's general reward pool,
    //     which is then split between the knowledge unit and agent reward pools.


    IERC20 public rewardToken;
    address public feeRecipient; // Address to receive platform fees (if implemented)

    // --- Configuration Constants (Can be made governance-upgradable via proposals) ---
    uint256 public constant MIN_AGENT_REGISTRATION_STAKE = 100 * (10 ** 18); // Example: 100 tokens
    uint256 public constant MIN_KNOWLEDGE_UNIT_STAKE = 10 * (10 ** 18); // Example: 10 tokens for initial validity/dispute
    uint256 public constant MIN_GOVERNANCE_STAKE_FOR_PROPOSAL = 50 * (10 ** 18); // Example: 50 tokens needed to create a proposal
    uint256 public constant MIN_GOVERNANCE_STAKE_FOR_VOTING = 1 * (10 ** 18); // Example: 1 token needed to vote
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Voting lasts 3 days
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 20; // 20% of total staked tokens required to vote for proposal to pass
    uint256 public constant PROPOSAL_APPROVAL_PERCENTAGE = 51; // 51% 'yes' votes needed to pass
    uint256 public constant KNOWLEDGE_CONTRIBUTOR_REWARD_SHARE = 30; // 30% of unit-specific rewards to contributor
    uint256 public constant KNOWLEDGE_VERIFIER_REWARD_SHARE = 70; // 70% of unit-specific rewards to verifiers (split proportionally)
    uint256 public constant AGENT_EVALUATION_REWARD_FACTOR = 1 ether; // 1 token per point of positive score change for agents

    // --- Enums ---
    enum ProposalType {
        AgentParamChange,        // Change a specific parameter of an AI agent
        KnowledgeValidityReview, // Manually adjust a knowledge unit's validity score
        SystemParameterChange,   // Change a core constant of the protocol (e.g., MIN_AGENT_REGISTRATION_STAKE)
        GenericAction            // For broader, custom governance actions
    }

    // --- Custom Errors ---
    error InvalidAgentId();
    error AgentAlreadyRegistered();
    error NotAgentOwner();
    error InvalidKnowledgeUnitId();
    error KnowledgeUnitAlreadyRewarded();
    error InsufficientStake(uint256 required);
    error NoActiveStake();
    error ProposalNotFound();
    error ProposalNotActive(); // Voting period not started or already ended
    error ProposalVotingEnded();
    error AlreadyVoted();
    error NotEnoughVotingPower();
    error ProposalNotYetEnded();
    error ProposalFailedQuorum();
    error ProposalFailedApproval();
    error ProposalAlreadyExecuted();
    error ProposalExecutionFailed();
    error NoRewardsToClaim();
    error InvalidRewardTokenAddress();
    error InvalidSystemParameter();


    // --- Structures ---

    /// @dev Represents a piece of knowledge, a fact, a model parameter, or an insight/prediction.
    struct KnowledgeUnit {
        bytes32 id; // keccak256 hash of (contributor, submittedAt, dataHash)
        address contributor;
        uint256 submittedAt;
        bytes32 contentType; // e.g., keccak256("fact"), keccak256("model_param"), keccak256("prediction"), keccak256("analysis")
        string dataHash; // IPFS or similar content hash of the actual content
        string metadataURI; // URI to detailed JSON metadata (tags, description, external_links)
        int256 validityScore; // Dynamic score based on verifications (+ve) / disputes (-ve)
        uint256 totalStakedForValidity; // Total AMToken staked to verify this unit
        uint256 totalStakedForDispute; // Total AMToken staked to dispute this unit
        bool rewardsDistributed; // True if rewards for this unit have been processed
        bool isInsight; // True if this knowledge unit is an agent's insight/prediction
        bytes32 agentId; // If isInsight, ID of the agent that submitted it
    }

    /// @dev Represents an AI Agent profile within the Aethermind system.
    struct AgentProfile {
        bytes32 agentId; // keccak256 hash of (owner, name)
        address owner;
        string name;
        string descriptionURI; // URI to agent's detailed description
        uint256 registrationTime;
        int256 reputationScore; // Based on performance of submitted insights, value dynamically
        uint256 totalInsightsSubmitted;
        mapping(bytes32 => bytes32) parameters; // Key-value store for agent's configurable logic parameters. E.g., keccak256("PREDICTION_THRESHOLD") => bytes32(0x...)
        uint256 lastParameterChange;
        uint256 registrationStake; // Tokens staked by the agent owner during registration
    }

    /// @dev Represents a governance proposal.
    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        bytes32 targetAgentId; // Relevant for AgentParamChange proposals
        bytes32 targetKnowledgeUnitId; // Relevant for KnowledgeValidityReview proposals
        bytes32 paramKey; // Relevant for AgentParamChange / SystemParameterChange
        bytes32 newParamValue; // Relevant for AgentParamChange / SystemParameterChange
        int256 proposedScoreChange; // Relevant for KnowledgeValidityReview
        string descriptionURI; // URI to detailed proposal text
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 proposerVotingPower; // Snapshot of proposer's voting power at creation
        bool executed;
        bool passed; // Whether the proposal has passed after voting ends
        mapping(address => bool) hasVoted; // Prevents double voting
    }


    // --- State Variables & Mappings ---

    // Knowledge Base
    uint256 public nextKnowledgeUnitIndex = 1; // For unique ID generation if not using hash
    mapping(bytes32 => KnowledgeUnit) public knowledgeUnits;
    mapping(address => mapping(bytes32 => uint256)) public knowledgeUnitVerifierStakes; // user => unitId => amount staked
    mapping(address => mapping(bytes32 => uint256)) public knowledgeUnitDisputerStakes; // user => unitId => amount staked
    mapping(address => uint256) public pendingKnowledgeRewards; // Rewards for contributors/successful verifiers/disputers

    // AI Agents
    mapping(bytes32 => AgentProfile) public agents; // agentId => AgentProfile
    mapping(address => bytes32[]) public registeredAgentIdsByOwner; // owner => array of agentIds
    mapping(address => uint256) public pendingAgentRewards; // Rewards for high-performing agents

    // Governance
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public governanceStakes; // user => staked amount (voting power)
    uint256 public totalGovernanceStaked;

    // Reward Pools
    uint256 public knowledgeUnitRewardPool; // Accumulated rewards specifically for knowledge units
    uint256 public agentRewardPool; // Accumulated rewards specifically for agents


    // --- Events ---
    event KnowledgeUnitSubmitted(bytes32 indexed unitId, address indexed contributor, bytes32 contentType, string dataHash, uint256 initialStake);
    event KnowledgeUnitVerified(bytes32 indexed unitId, address indexed verifier, uint256 amount);
    event KnowledgeUnitDisputed(bytes32 indexed unitId, address indexed disputer, uint256 amount);
    event KnowledgeUnitStakeRetracted(bytes32 indexed unitId, address indexed staker, uint256 amount, bool isVerifier);
    event KnowledgeUnitRewardAllocated(bytes32 indexed unitId, address indexed contributor, uint256 contributorReward, uint256 totalVerifiersStakes, uint256 totalDisputersStakes, int256 finalValidityScore);
    event KnowledgeUnitMetadataUpdated(bytes32 indexed unitId, string newMetadataURI);

    event AgentRegistered(bytes32 indexed agentId, address indexed owner, string name, uint256 registrationStake);
    event AgentDescriptionUpdated(bytes32 indexed agentId, string newDescriptionURI);
    event AgentInsightSubmitted(bytes32 indexed agentId, bytes32 indexed insightUnitId);
    event AgentPerformanceEvaluated(bytes32 indexed agentId, bytes32 indexed insightUnitId, int256 scoreChange, uint256 rewardAmount);

    event GovernanceStakeUpdated(address indexed staker, uint256 newStake, uint256 totalStaked);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType pType, string descriptionURI);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalEnded(uint256 indexed proposalId, bool passed, uint256 yesVotes, uint256 noVotes);
    event ProposalExecuted(uint256 indexed proposalId, ProposalType pType);

    event RewardsClaimed(address indexed claimant, uint256 amount);
    event DepositToRewardPool(address indexed depositor, uint256 amount);


    // --- Modifiers ---

    /// @dev Ensures the caller is the registered owner of the specified agent.
    modifier onlyAgentOwner(bytes32 _agentId) {
        if (agents[_agentId].owner == address(0)) revert InvalidAgentId();
        if (agents[_agentId].owner != msg.sender) revert NotAgentOwner();
        _;
    }

    /// @dev Ensures the caller is either the contract owner or a recognized governance executor.
    ///      For simplicity, in this example, it defaults to only the contract owner.
    ///      In a full DAO, this would check against a governance contract or specific roles.
    modifier onlyGovernanceOrOwner() {
        if (owner() != msg.sender) {
            // Future extension: Check if msg.sender is a DAO treasury/executor address
            // require(daoContract.isExecutor(msg.sender), "Caller is not governance executor");
            revert OwnableUnauthorizedAccount(msg.sender); // Keep it owner-only for now
        }
        _;
    }

    // --- Constructor ---

    /// @dev Initializes the contract, setting the owner and the ERC20 reward token address.
    /// @param _rewardTokenAddress The address of the ERC20 token used for staking and rewards.
    constructor(address _rewardTokenAddress) Ownable(msg.sender) Pausable() {
        if (_rewardTokenAddress == address(0)) revert InvalidRewardTokenAddress();
        rewardToken = IERC20(_rewardTokenAddress);
        feeRecipient = msg.sender; // Default fee recipient is contract owner
    }

    // --- F. Core & Setup Functions (5) ---

    /// @dev Allows the owner to update the address of the ERC20 reward token.
    /// @param _newRewardTokenAddress The new address for the reward token.
    function setRewardTokenAddress(address _newRewardTokenAddress) external onlyOwner {
        if (_newRewardTokenAddress == address(0)) revert InvalidRewardTokenAddress();
        rewardToken = IERC20(_newRewardTokenAddress);
    }

    /// @dev Pauses the contract, preventing most state-changing operations. Can only be called by the owner.
    function pause() public override onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract, allowing operations to resume. Can only be called by the owner.
    function unpause() public override onlyOwner {
        _unpause();
    }

    /// @dev Sets the address that receives platform fees (if any are implemented). Can only be called by the owner.
    /// @param _newFeeRecipient The new address for the fee recipient.
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        feeRecipient = _newFeeRecipient;
    }

    // `transferOwnership` is inherited from Ownable and available to the owner.


    // --- G. Knowledge Base Management Functions (8) ---

    /// @dev Submits a new Knowledge Unit to the Aethermind knowledge base.
    /// @param _contentType Type of knowledge (e.g., keccak256("fact"), keccak256("model_param")).
    /// @param _dataHash IPFS or content hash of the actual data.
    /// @param _metadataURI URI to detailed JSON metadata.
    /// @param _initialStake Optional initial token stake from the contributor to boost validity.
    /// @param _isInsight True if this is an insight/prediction from an agent.
    /// @param _agentId If _isInsight is true, the ID of the submitting agent.
    function submitKnowledgeUnit(
        bytes32 _contentType,
        string memory _dataHash,
        string memory _metadataURI,
        uint256 _initialStake,
        bool _isInsight,
        bytes32 _agentId
    ) external whenNotPaused {
        bytes32 unitId = keccak256(abi.encodePacked(msg.sender, block.timestamp, _dataHash, nextKnowledgeUnitIndex++));
        // Using nextKnowledgeUnitIndex in hash to ensure uniqueness even if other params collide
        // A collision is extremely unlikely but adding a counter helps for demo.

        if (_initialStake > 0 && _initialStake < MIN_KNOWLEDGE_UNIT_STAKE) {
            revert InsufficientStake(MIN_KNOWLEDGE_UNIT_STAKE);
        }

        if (_isInsight) {
            if (agents[_agentId].owner == address(0)) revert InvalidAgentId(); // Agent must exist
            if (agents[_agentId].owner != msg.sender) revert NotAgentOwner(); // Only agent owner can submit insight for their agent
            agents[_agentId].totalInsightsSubmitted++;
        }

        knowledgeUnits[unitId] = KnowledgeUnit({
            id: unitId,
            contributor: msg.sender,
            submittedAt: block.timestamp,
            contentType: _contentType,
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            validityScore: _initialStake > 0 ? int256(_initialStake) : 0,
            totalStakedForValidity: _initialStake,
            totalStakedForDispute: 0,
            rewardsDistributed: false,
            isInsight: _isInsight,
            agentId: _agentId
        });

        if (_initialStake > 0) {
            bool success = rewardToken.transferFrom(msg.sender, address(this), _initialStake);
            if (!success) revert InsufficientStake(_initialStake);
            knowledgeUnitVerifierStakes[msg.sender][unitId] = _initialStake;
            knowledgeUnitRewardPool += _initialStake; // Adds to the pool for later distribution
        }

        emit KnowledgeUnitSubmitted(unitId, msg.sender, _contentType, _dataHash, _initialStake);
        if (_isInsight) {
            emit AgentInsightSubmitted(_agentId, unitId);
        }
    }

    /// @dev Retrieves the details of a specific knowledge unit.
    /// @param _unitId The ID of the knowledge unit.
    /// @return KnowledgeUnit struct details.
    function getKnowledgeUnit(bytes32 _unitId) external view returns (KnowledgeUnit memory) {
        if (knowledgeUnits[_unitId].contributor == address(0)) revert InvalidKnowledgeUnitId();
        return knowledgeUnits[_unitId];
    }

    /// @dev Allows a user to stake tokens to verify a knowledge unit, increasing its validity.
    /// @param _unitId The ID of the knowledge unit to verify.
    /// @param _amount The amount of tokens to stake. Must be at least MIN_KNOWLEDGE_UNIT_STAKE.
    function verifyKnowledgeUnit(bytes32 _unitId, uint256 _amount) external whenNotPaused {
        KnowledgeUnit storage unit = knowledgeUnits[_unitId];
        if (unit.contributor == address(0)) revert InvalidKnowledgeUnitId();
        if (unit.rewardsDistributed) revert KnowledgeUnitAlreadyRewarded();
        if (_amount < MIN_KNOWLEDGE_UNIT_STAKE) revert InsufficientStake(MIN_KNOWLEDGE_UNIT_STAKE);

        bool success = rewardToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert InsufficientStake(_amount);

        unit.validityScore += int256(_amount); // Each token staked contributes 1 point
        unit.totalStakedForValidity += _amount;
        knowledgeUnitVerifierStakes[msg.sender][_unitId] += _amount;
        knowledgeUnitRewardPool += _amount; // Add to pool

        emit KnowledgeUnitVerified(_unitId, msg.sender, _amount);
    }

    /// @dev Allows a user to stake tokens to dispute a knowledge unit, decreasing its validity.
    /// @param _unitId The ID of the knowledge unit to dispute.
    /// @param _amount The amount of tokens to stake. Must be at least MIN_KNOWLEDGE_UNIT_STAKE.
    function disputeKnowledgeUnit(bytes32 _unitId, uint256 _amount) external whenNotPaused {
        KnowledgeUnit storage unit = knowledgeUnits[_unitId];
        if (unit.contributor == address(0)) revert InvalidKnowledgeUnitId();
        if (unit.rewardsDistributed) revert KnowledgeUnitAlreadyRewarded();
        if (_amount < MIN_KNOWLEDGE_UNIT_STAKE) revert InsufficientStake(MIN_KNOWLEDGE_UNIT_STAKE);

        bool success = rewardToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert InsufficientStake(_amount);

        unit.validityScore -= int256(_amount); // Each token staked contributes -1 point
        unit.totalStakedForDispute += _amount;
        knowledgeUnitDisputerStakes[msg.sender][_unitId] += _amount;
        knowledgeUnitRewardPool += _amount; // Add to pool

        emit KnowledgeUnitDisputed(_unitId, msg.sender, _amount);
    }

    /// @dev Allows a user to retract their stake for verification or dispute IF rewards haven't been distributed.
    ///      Once rewards are distributed, stakes are resolved (returned or forfeited).
    /// @param _unitId The ID of the knowledge unit.
    /// @param _isVerifier True if retracting a verifier stake, false for a disputer stake.
    function retractKnowledgeUnitStake(bytes32 _unitId, bool _isVerifier) external whenNotPaused {
        KnowledgeUnit storage unit = knowledgeUnits[_unitId];
        if (unit.contributor == address(0)) revert InvalidKnowledgeUnitId();
        if (unit.rewardsDistributed) revert KnowledgeUnitAlreadyRewarded();

        uint256 stakeAmount;
        if (_isVerifier) {
            stakeAmount = knowledgeUnitVerifierStakes[msg.sender][_unitId];
            if (stakeAmount == 0) revert NoActiveStake();
            unit.totalStakedForValidity -= stakeAmount;
            unit.validityScore -= int256(stakeAmount);
            delete knowledgeUnitVerifierStakes[msg.sender][_unitId];
        } else {
            stakeAmount = knowledgeUnitDisputerStakes[msg.sender][_unitId];
            if (stakeAmount == 0) revert NoActiveStake();
            unit.totalStakedForDispute -= stakeAmount;
            unit.validityScore += int256(stakeAmount); // Dispute stake retraction increases validity score
            delete knowledgeUnitDisputerStakes[msg.sender][_unitId];
        }

        knowledgeUnitRewardPool -= stakeAmount;
        bool success = rewardToken.transfer(msg.sender, stakeAmount);
        if (!success) revert ProposalExecutionFailed(); // Using generic error for token transfer failure

        emit KnowledgeUnitStakeRetracted(_unitId, msg.sender, stakeAmount, _isVerifier);
    }

    /// @dev Updates the metadata URI of a knowledge unit. Only callable by the original contributor,
    ///      or by governance (e.g., after a successful proposal).
    /// @param _unitId The ID of the knowledge unit.
    /// @param _newMetadataURI The new URI for the metadata.
    function updateKnowledgeUnitMetadata(bytes32 _unitId, string memory _newMetadataURI) external whenNotPaused {
        KnowledgeUnit storage unit = knowledgeUnits[_unitId];
        if (unit.contributor == address(0)) revert InvalidKnowledgeUnitId();
        
        // For simplicity, only contributor can update. A DAO proposal could also trigger this.
        if (unit.contributor != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);

        unit.metadataURI = _newMetadataURI;
        emit KnowledgeUnitMetadataUpdated(_unitId, _newMetadataURI);
    }

    /// @dev Returns the current dynamic validity score of a knowledge unit.
    /// @param _unitId The ID of the knowledge unit.
    /// @return The validity score.
    function getKnowledgeUnitValidityScore(bytes32 _unitId) external view returns (int256) {
        if (knowledgeUnits[_unitId].contributor == address(0)) revert InvalidKnowledgeUnitId();
        return knowledgeUnits[_unitId].validityScore;
    }

    /// @dev Resolves the outcome for a knowledge unit, distributes rewards (or forfeits stakes),
    ///      and marks it as processed. Can only be triggered by owner/governance.
    /// @param _unitId The ID of the knowledge unit.
    function distributeKnowledgeUnitRewards(bytes32 _unitId) external onlyGovernanceOrOwner whenNotPaused {
        KnowledgeUnit storage unit = knowledgeUnits[_unitId];
        if (unit.contributor == address(0)) revert InvalidKnowledgeUnitId();
        if (unit.rewardsDistributed) revert KnowledgeUnitAlreadyRewarded();

        unit.rewardsDistributed = true; // Mark as distributed to prevent re-distribution

        uint224 totalCombinedStakes = uint224(unit.totalStakedForValidity + unit.totalStakedForDispute);
        if (totalCombinedStakes == 0) { // If no one staked, no rewards to distribute
            emit KnowledgeUnitRewardAllocated(_unitId, unit.contributor, 0, 0, 0, unit.validityScore);
            return;
        }

        uint256 availableForRewards = knowledgeUnitRewardPool; // The entire pool is available for resolution
        knowledgeUnitRewardPool = 0; // Clear the pool, redistribute all stakes + potential new rewards

        uint256 rewardsToContributor = 0;
        uint256 rewardsToVerifiers = 0;
        uint256 rewardsToDisputers = 0;

        if (unit.validityScore > 0) { // Knowledge Unit deemed valid: Verifiers win, Disputers lose
            rewardsToContributor = (availableForRewards * KNOWLEDGE_CONTRIBUTOR_REWARD_SHARE) / 100;
            // The remaining amount is for verifiers
            uint256 remainingForVerifiers = availableForRewards - rewardsToContributor;

            // Simple distribution: Verifiers get their stake back + a proportional share of `remainingForVerifiers`
            // Disputers lose their stake (it stays in the system and is part of `availableForRewards`).
            // To properly track, each verifier's stake needs to be tracked.
            // For this version, we will simplify: the contributor gets a share. Verifier/disputer claims handled on generic `claimRewards`.

            pendingKnowledgeRewards[unit.contributor] += rewardsToContributor;
            
            // NOTE: A more complex system would iterate through all verifierStakes/disputerStakes to
            // individually calculate and set `pendingKnowledgeRewards` for each staker based on their win/loss.
            // Due to Solidity's limitations on iterating mappings, this requires off-chain indexing or a very
            // different data structure (e.g., storing staker addresses in dynamic arrays, which has gas costs).
            // For now, this function only allocates to the contributor and resolves the unit.
            // Stakers can query their own stakes' outcomes in `claimRewards`.

            emit KnowledgeUnitRewardAllocated(
                _unitId,
                unit.contributor,
                rewardsToContributor,
                unit.totalStakedForValidity,
                unit.totalStakedForDispute,
                unit.validityScore
            );
        } else { // Knowledge Unit deemed invalid (disputers were mostly correct): Disputers win, Verifiers lose
            // Disputers get their stakes back + a share of verifier stakes. Contributor gets no reward.
            // This logic is also difficult to implement proportionally for all parties on-chain.
            // The funds from `availableForRewards` will implicitly be used for other rewards or remain in the pool.
            // Individual disputers will retrieve their stake + a portion of losing stakes when they call `claimRewards`.
             emit KnowledgeUnitRewardAllocated(
                _unitId,
                unit.contributor,
                0, // No contributor reward for invalid unit
                unit.totalStakedForValidity,
                unit.totalStakedForDispute,
                unit.validityScore
            );
        }
    }


    // --- H. AI Agent Management Functions (6) ---

    /// @dev Registers a new AI agent with a unique ID and description.
    /// Requires an initial token stake from the caller.
    /// @param _name The name of the agent.
    /// @param _descriptionURI URI to detailed description of the agent.
    function registerAgent(string memory _name, string memory _descriptionURI) external whenNotPaused {
        bytes32 agentId = keccak256(abi.encodePacked(msg.sender, _name)); // Unique ID based on owner and name
        if (agents[agentId].owner != address(0)) revert AgentAlreadyRegistered();
        
        // This function requires a direct token transfer from msg.sender to the contract.
        // The token must be approved beforehand.
        if (rewardToken.allowance(msg.sender, address(this)) < MIN_AGENT_REGISTRATION_STAKE) {
            revert InsufficientStake(MIN_AGENT_REGISTRATION_STAKE);
        }
        bool success = rewardToken.transferFrom(msg.sender, address(this), MIN_AGENT_REGISTRATION_STAKE);
        if (!success) revert InsufficientStake(MIN_AGENT_REGISTRATION_STAKE);

        agents[agentId] = AgentProfile({
            agentId: agentId,
            owner: msg.sender,
            name: _name,
            descriptionURI: _descriptionURI,
            registrationTime: block.timestamp,
            reputationScore: 0, // Agents start at 0 reputation
            totalInsightsSubmitted: 0,
            lastParameterChange: block.timestamp,
            registrationStake: MIN_AGENT_REGISTRATION_STAKE
        });
        registeredAgentIdsByOwner[msg.sender].push(agentId);
        agentRewardPool += MIN_AGENT_REGISTRATION_STAKE; // Add registration stake to the agent reward pool

        emit AgentRegistered(agentId, msg.sender, _name, MIN_AGENT_REGISTRATION_STAKE);
    }

    /// @dev Retrieves the details of a specific AI agent.
    /// @param _agentId The ID of the agent.
    /// @return AgentProfile struct details.
    function getAgentProfile(bytes32 _agentId) external view returns (AgentProfile memory) {
        if (agents[_agentId].owner == address(0)) revert InvalidAgentId();
        return agents[_agentId];
    }

    /// @dev Allows an agent's owner to update its descriptive metadata URI.
    /// @param _agentId The ID of the agent.
    /// @param _newDescriptionURI The new URI for the agent's description.
    function updateAgentDescription(bytes32 _agentId, string memory _newDescriptionURI) external onlyAgentOwner(_agentId) whenNotPaused {
        agents[_agentId].descriptionURI = _newDescriptionURI;
        emit AgentDescriptionUpdated(_agentId, _newDescriptionURI);
    }

    /// @dev Allows an agent owner to submit an "insight" or "prediction" on behalf of their agent.
    /// This creates a special `KnowledgeUnit` with the `isInsight` flag set to true.
    /// @param _agentId The ID of the submitting agent.
    /// @param _insightDataHash IPFS or content hash of the insight's data.
    /// @param _insightMetadataURI URI to detailed JSON metadata for the insight.
    function submitAgentInsight(
        bytes32 _agentId,
        string memory _insightDataHash,
        string memory _insightMetadataURI
    ) external onlyAgentOwner(_agentId) whenNotPaused {
        // Submit as a KnowledgeUnit with `isInsight = true`
        // No initial stake required, as agent reputation is the primary metric for insights.
        submitKnowledgeUnit(
            keccak256(abi.encodePacked("insight")), // Fixed contentType for insights
            _insightDataHash,
            _insightMetadataURI,
            0, // No initial stake for insights
            true,
            _agentId
        );
        // `KnowledgeUnitSubmitted` and `AgentInsightSubmitted` events are emitted by `submitKnowledgeUnit`
    }

    /// @dev Evaluates a previously submitted agent insight against a real-world outcome.
    /// This directly impacts the agent's `reputationScore`. Can only be called by owner/governance.
    /// @param _insightUnitId The Knowledge Unit ID of the insight being evaluated.
    /// @param _scoreChange The amount to change the agent's reputation score by (can be negative).
    function evaluateAgentInsight(
        bytes32 _insightUnitId,
        int256 _scoreChange
    ) external onlyGovernanceOrOwner whenNotPaused {
        KnowledgeUnit storage insight = knowledgeUnits[_insightUnitId];
        if (insight.contributor == address(0) || !insight.isInsight) revert InvalidKnowledgeUnitId();
        AgentProfile storage agent = agents[insight.agentId];
        if (agent.owner == address(0)) revert InvalidAgentId();

        agent.reputationScore += _scoreChange;
        uint256 rewardAmount = 0;

        if (_scoreChange > 0) { // Only reward for positive score changes
            uint256 potentialReward = uint256(_scoreChange) * AGENT_EVALUATION_REWARD_FACTOR;
            // Cap the reward to prevent draining the pool, e.g., max 10% of agentRewardPool
            uint256 maxRewardFromPool = (agentRewardPool * 10) / 100;
            rewardAmount = potentialReward > maxRewardFromPool ? maxRewardFromPool : potentialReward;
            
            if (rewardAmount > 0) {
                pendingAgentRewards[agent.owner] += rewardAmount;
                agentRewardPool -= rewardAmount;
            }
        }

        emit AgentPerformanceEvaluated(agent.agentId, _insightUnitId, _scoreChange, rewardAmount);
    }

    /// @dev Returns the current reputation score of an AI agent.
    /// @param _agentId The ID of the agent.
    /// @return The reputation score.
    function getAgentReputationScore(bytes32 _agentId) external view returns (int256) {
        if (agents[_agentId].owner == address(0)) revert InvalidAgentId();
        return agents[_agentId].reputationScore;
    }


    // --- I. Governance & Staking Functions (8) ---

    /// @dev Allows users to stake reward tokens to gain voting power for governance proposals.
    /// @param _amount The amount of tokens to stake. Must be at least MIN_GOVERNANCE_STAKE_FOR_VOTING.
    function stakeForGovernance(uint256 _amount) external whenNotPaused {
        if (_amount < MIN_GOVERNANCE_STAKE_FOR_VOTING) revert InsufficientStake(MIN_GOVERNANCE_STAKE_FOR_VOTING);

        bool success = rewardToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert InsufficientStake(_amount);

        governanceStakes[msg.sender] += _amount;
        totalGovernanceStaked += _amount;
        emit GovernanceStakeUpdated(msg.sender, governanceStakes[msg.sender], totalGovernanceStaked);
    }

    /// @dev Allows users to unstake their governance tokens, reducing their voting power.
    /// @param _amount The amount of tokens to unstake.
    function unstakeFromGovernance(uint256 _amount) external whenNotPaused {
        if (governanceStakes[msg.sender] < _amount) revert InsufficientStake(_amount);

        governanceStakes[msg.sender] -= _amount;
        totalGovernanceStaked -= _amount;

        bool success = rewardToken.transfer(msg.sender, _amount);
        if (!success) revert ProposalExecutionFailed(); // Generic error for token transfer failure
        emit GovernanceStakeUpdated(msg.sender, governanceStakes[msg.sender], totalGovernanceStaked);
    }

    /// @dev Returns the current voting power of an address.
    /// @param _staker The address to check.
    /// @return The amount of tokens staked for governance.
    function getVotingPower(address _staker) external view returns (uint256) {
        return governanceStakes[_staker];
    }

    /// @dev Creates a new governance proposal. Requires a minimum stake from the proposer.
    /// @param _proposalType The type of the proposal.
    /// @param _descriptionURI URI to detailed proposal text.
    /// @param _targetAgentId Relevant for AgentParamChange proposals. Set to bytes32(0) if not applicable.
    /// @param _targetKnowledgeUnitId Relevant for KnowledgeValidityReview proposals. Set to bytes32(0) if not applicable.
    /// @param _paramKey Relevant for parameter changes (e.g., keccak256("MIN_AGENT_REGISTRATION_STAKE")). Set to bytes32(0) if not applicable.
    /// @param _newParamValue Relevant for parameter changes. Set to bytes32(0) if not applicable.
    /// @param _proposedScoreChange Relevant for knowledge validity review. Set to 0 if not applicable.
    function createProposal(
        ProposalType _proposalType,
        string memory _descriptionURI,
        bytes32 _targetAgentId,
        bytes32 _targetKnowledgeUnitId,
        bytes32 _paramKey,
        bytes32 _newParamValue,
        int256 _proposedScoreChange
    ) external whenNotPaused returns (uint256) {
        if (governanceStakes[msg.sender] < MIN_GOVERNANCE_STAKE_FOR_PROPOSAL) revert NotEnoughVotingPower();

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: _proposalType,
            targetAgentId: _targetAgentId,
            targetKnowledgeUnitId: _targetKnowledgeUnitId,
            paramKey: _paramKey,
            newParamValue: _newParamValue,
            proposedScoreChange: _proposedScoreChange,
            descriptionURI: _descriptionURI,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            proposerVotingPower: governanceStakes[msg.sender], // Snapshot voting power
            executed: false,
            passed: false,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });

        // Proposer automatically casts a 'yes' vote with their current voting power
        proposals[proposalId].hasVoted[msg.sender] = true;
        proposals[proposalId].yesVotes += governanceStakes[msg.sender];

        emit ProposalCreated(proposalId, msg.sender, _proposalType, _descriptionURI);
        emit VoteCast(proposalId, msg.sender, true, governanceStakes[msg.sender]);
        return proposalId;
    }

    /// @dev Allows stakers to cast a 'yes' or 'no' vote on an active proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (block.timestamp < proposal.creationTime || block.timestamp >= proposal.votingEndTime) revert ProposalNotActive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (governanceStakes[msg.sender] < MIN_GOVERNANCE_STAKE_FOR_VOTING) revert NotEnoughVotingPower();

        proposal.hasVoted[msg.sender] = true;
        uint256 voterPower = governanceStakes[msg.sender];
        if (_support) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }
        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    /// @dev Ends the voting period for a proposal and tallies votes. Can be called by anyone
    ///      after the voting end time. Sets the `passed` flag based on quorum and approval.
    /// @param _proposalId The ID of the proposal.
    function endProposalVoting(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (block.timestamp < proposal.votingEndTime) revert ProposalNotYetEnded();
        if (proposal.executed) revert ProposalAlreadyExecuted(); // Already handled or executed

        uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes;
        
        // Quorum check: A minimum percentage of the total governance stake must have voted.
        if (totalGovernanceStaked == 0 || totalVotesCast < (totalGovernanceStaked * PROPOSAL_QUORUM_PERCENTAGE) / 100) {
            proposal.passed = false; // Did not meet quorum
        } else if (totalVotesCast > 0 && (proposal.yesVotes * 100) / totalVotesCast > PROPOSAL_APPROVAL_PERCENTAGE) {
            proposal.passed = true; // Passed approval threshold
        } else {
            proposal.passed = false; // Failed approval
        }

        emit ProposalEnded(_proposalId, proposal.passed, proposal.yesVotes, proposal.noVotes);
    }

    /// @dev Executes a passed governance proposal. Can only be called by owner/governance.
    /// @param _proposalId The ID of the proposal.
    function executeProposal(uint256 _proposalId) external onlyGovernanceOrOwner whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (block.timestamp < proposal.votingEndTime) revert ProposalNotYetEnded();
        if (!proposal.passed) revert ProposalFailedApproval(); // Also covers quorum failure
        if (proposal.executed) revert ProposalAlreadyExecuted();

        proposal.executed = true; // Mark as executed

        if (proposal.proposalType == ProposalType.AgentParamChange) {
            AgentProfile storage agent = agents[proposal.targetAgentId];
            if (agent.owner == address(0)) revert InvalidAgentId();
            agent.parameters[proposal.paramKey] = proposal.newParamValue;
            agent.lastParameterChange = block.timestamp;
        } else if (proposal.proposalType == ProposalType.KnowledgeValidityReview) {
            KnowledgeUnit storage unit = knowledgeUnits[proposal.targetKnowledgeUnitId];
            if (unit.contributor == address(0)) revert InvalidKnowledgeUnitId();
            unit.validityScore += proposal.proposedScoreChange;
            // A review could also trigger `distributeKnowledgeUnitRewards` if needed.
        } else if (proposal.proposalType == ProposalType.SystemParameterChange) {
            // This is a simple example. A more robust system would use a separate upgradable config contract.
            // For example, changing MIN_AGENT_REGISTRATION_STAKE
            if (proposal.paramKey == keccak256(abi.encodePacked("MIN_AGENT_REGISTRATION_STAKE"))) {
                // Not directly possible to change public constant, would need to be a state variable.
                // For demo, assume these are configurable state variables.
                // uint256 newMinStake = uint256(bytes32(proposal.newParamValue));
                // MIN_AGENT_REGISTRATION_STAKE = newMinStake; // Not directly assignable to `constant`
                revert InvalidSystemParameter(); // Requires a mutable state variable, not a constant
            }
            // Add other system parameters here
        }
        // Future: Handle GenericAction via external call or more complex logic

        emit ProposalExecuted(_proposalId, proposal.proposalType);
    }

    /// @dev Allows users to claim their accumulated rewards from contributions,
    ///      successful verifications/disputes, or agent performance.
    function claimRewards() external whenNotPaused {
        uint256 totalClaimable = pendingKnowledgeRewards[msg.sender] + pendingAgentRewards[msg.sender];

        // This is where a more complex logic for individual knowledge unit stake resolution would happen.
        // E.g., iterate through a user's past stakes, check final validity score of each unit,
        // calculate return + profit or forfeiture, and add to `totalClaimable`.
        // Given Solidity's limitations, this is simplified here, assuming rewards are pre-allocated
        // to `pendingKnowledgeRewards` and `pendingAgentRewards` through other processes.

        if (totalClaimable == 0) revert NoRewardsToClaim();

        pendingKnowledgeRewards[msg.sender] = 0; // Reset pending rewards
        pendingAgentRewards[msg.sender] = 0;

        bool success = rewardToken.transfer(msg.sender, totalClaimable);
        if (!success) revert ProposalExecutionFailed(); // Generic error for token transfer failure

        emit RewardsClaimed(msg.sender, totalClaimable);
    }

    // --- J. Reward Pool Management (1) ---

    /// @dev Allows anyone to deposit reward tokens into the protocol's general reward pool.
    ///      These tokens are then split between the knowledge unit and agent reward pools.
    /// @param _amount The amount of tokens to deposit.
    function depositToRewardPool(uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert InsufficientStake(1); // Require at least 1 token
        
        bool success = rewardToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert InsufficientStake(_amount);

        // Example split: 50% for knowledge units, 50% for agents
        knowledgeUnitRewardPool += _amount / 2;
        agentRewardPool += _amount - (_amount / 2); // Handles odd numbers

        emit DepositToRewardPool(msg.sender, _amount);
    }
}
```