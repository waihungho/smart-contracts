This smart contract, named "Synthetica," is designed to be an advanced, AI-driven, self-evolving Decentralized Autonomous Research & Development (DARD) Guild. It combines cutting-edge concepts like AI oracle integration for dynamic decision-making, a self-evolving governance mechanism that can adapt its own rules, and a dynamic Soulbound Token (SBT) system for contributor reputation. It aims to foster and fund innovative research projects by leveraging collective intelligence and AI insights.

---

## **Synthetica: AI-Driven Decentralized Research Guild**

### **Outline & Function Summary**

**Core Concept:** Synthetica functions as a decentralized guild for funding and managing research and development projects. Its unique selling proposition is the deep integration of AI models to inform governance decisions, dynamically adjust operational rules, and assess project/contributor performance. It also features a non-transferable reputation system (Soulbound Tokens) that evolves with contributions and attestations.

**Key Innovations:**
*   **AI-Enhanced Governance:** AI model performance and insights can directly influence proposal outcomes, funding allocations, and adaptive rule adjustments.
*   **Adaptive Rule Engine:** The DAO can vote to change its *own operational parameters* for how decisions are made, allowing for controlled "self-evolution."
*   **Dynamic Soulbound Tokens (SBTs):** Contributor reputations are represented by non-transferable tokens that evolve with skills, attestations, and project success, influencing voting power and access.
*   **Decentralized R&D Lifecycle:** A robust system for proposing, funding, executing, and evaluating research projects.

---

**Function Categories & Summaries:**

**I. Core System & Initialization:**
1.  **`constructor()`:** Initializes the contract, sets the deployer as the initial governor, and deploys/links to required ERC20 and Soulbound Token contracts.
2.  **`updateCoreParameter(bytes32 _paramName, uint256 _newValue)`:** Allows the DAO (via governance) to update foundational, immutable parameters like voting periods, quorum thresholds, or reputation multipliers.

**II. Governance (Adaptive DAO):**
3.  **`proposeAdaptiveRuleConfigChange(bytes32 _ruleKey, uint256 _newConfigurationValue)`:** Enables the DAO to propose changes to internal configuration variables that dictate how adaptive rules (`triggerAdaptiveMetricCalculation`, `applyAdaptiveGovernanceImpact`) behave. This allows the DAO to "tune" its self-evolving logic.
4.  **`voteOnProposal(uint256 _proposalId, bool _for)`:** Standard voting mechanism for all types of proposals, weighted by DARD tokens and potentially by reputation (SBTs).
5.  **`executeProposal(uint256 _proposalId)`:** Executes a proposal that has met the required voting threshold and quorum.
6.  **`delegateVote(address _delegatee)`:** Allows DARD token holders to delegate their voting power to another address.
7.  **`proposeAIFundingAllocation(uint256 _aiModelId, uint256 _amount)`:** Submits a governance proposal to allocate funds specifically for an AI model's training, maintenance, or data acquisition, based on its perceived utility.

**III. AI Model Registry & Interaction:**
8.  **`registerAIModel(string calldata _modelName, string calldata _modelDescription, address _oracleAddress, bytes32 _predictionOutputHashScheme)`:** Registers a new AI model with the guild, specifying its oracle and a hash scheme for validating its outputs. Only approved members can register.
9.  **`submitAIModelPerformance(uint256 _aiModelId, uint256 _accuracyScore, uint256 _latencyScore, bytes32 _integrityHash)`:** An approved oracle or designated entity submits performance metrics (e.g., accuracy, latency) for a registered AI model, along with a cryptographic integrity hash.
10. **`requestAIInsight(uint256 _aiModelId, bytes calldata _inputData, bytes32 _callbackId)`:** Allows anyone to request an insight or prediction from a registered AI model via its associated oracle, providing input data and a unique callback ID.
11. **`fulfillAIInsight(bytes32 _callbackId, bytes calldata _aiOutput, bytes32 _proofHash)`:** The callback function for an AI oracle to deliver the requested insight (`_aiOutput`) and a proof of authenticity/computation (`_proofHash`) back to the contract.
12. **`evaluateAIModelUtility(uint256 _aiModelId, uint256 _utilityScore)`:** DAO members or designated evaluators can submit a qualitative utility score for an AI model based on its past insights, influencing its standing and potential funding.

**IV. Project Lifecycle (R&D Initiatives):**
13. **`submitResearchProposal(string calldata _title, string calldata _descriptionURI, uint256 _fundingRequested, address[] calldata _initialContributors)`:** Members can submit detailed research proposals, including a URI to external documentation, requested funding, and a list of initial contributors.
14. **`voteOnResearchProposal(uint256 _proposalId, bool _approve)`:** DARD token holders vote to approve or reject submitted research proposals. AI insights might influence voting recommendations.
15. **`fundResearchProject(uint256 _projectId, uint256 _amount)`:** Once a research proposal is approved, this function allows the DAO to allocate and transfer funds from the guild treasury to the project.
16. **`submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _milestoneURI)`:** Project contributors report the completion of a project milestone, providing a URI to relevant documentation or results.
17. **`evaluateProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approved, uint256 _reputationAward)`:** Designated project evaluators (or the DAO) review a submitted milestone, approving it and potentially awarding reputation to the involved contributors.

**V. Reputation & Contributor System (Dynamic SBTs):**
18. **`mintContributorSoul(address _contributorAddress, string calldata _initialSkillsURI)`:** Mints a non-transferable "Soul" (SBT) for a new contributor, associating an initial skill profile URI. This is the entry point for contributors.
19. **`updateContributorSkills(address _contributorAddress, string calldata _newSkillsURI)`:** Allows a contributor (or an approved entity/AI) to update the skill profile URI associated with their Soulbound Token, reflecting evolving expertise.
20. **`attestToSkill(address _contributorAddress, bytes32 _skillHash, uint256 _level)`:** Other contributors or approved AI models can "attest" to a specific skill (`_skillHash`) and proficiency `_level` for another contributor's Soul, influencing their reputation score.
21. **`distributeReputationReward(address _contributorAddress, uint256 _amount, bytes32 _reasonHash)`:** Awards reputation points to a contributor's Soul for specific achievements, successful project contributions, or other recognized actions, with a hash linking to the reason.

**VI. Treasury & Funding:**
22. **`depositEther()`:** Allows anyone to send Ether to the Synthetica guild treasury.
23. **`withdrawFunds(address _recipient, uint256 _amount)`:** A governance-controlled function to withdraw funds from the treasury to a specified recipient.

**VII. Adaptive Mechanism (Self-Evolving Logic):**
24. **`triggerAdaptiveMetricCalculation(bytes32 _metricKey)`:** Triggers an internal calculation of a specific adaptive metric (e.g., average AI model utility, project success rate weighted by reputation) based on current state and `proposeAdaptiveRuleConfigChange` values. Returns a calculated value.
25. **`applyAdaptiveGovernanceImpact(bytes32 _impactKey, uint256 _impactValue)`:** Based on a calculated adaptive metric (`_impactValue`), this function applies its effect on governance, such as dynamically adjusting quorum requirements for certain proposals, re-weighting voting power, or influencing AI model selection for project recommendations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For Soulbound Tokens (SBTs)
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Define custom errors for better debugging and user experience
error Synthetica__NotGovernor();
error Synthetica__AlreadyVoted();
error Synthetica__ProposalNotFound();
error Synthetica__ProposalNotReadyForExecution();
error Synthetica__ProposalAlreadyExecuted();
error Synthetica__UnauthorizedOracle();
error Synthetica__AIModelNotFound();
error Synthetica__InvalidAIOutput();
error Synthetica__ProjectNotFound();
error Synthetica__ProjectNotApproved();
error Synthetica__MilestoneNotFound();
error Synthetica__UnauthorizedContributor();
error Synthetica__ContributorSoulNotFound();
error Synthetica__InsufficientFunds(uint256 required, uint256 available);
error Synthetica__InvalidConfiguration();
error Synthetica__SelfDelegationNotAllowed();
error Synthetica__ZeroAddressNotAllowed();
error Synthetica__CoreParameterImmutable();

/**
 * @title Synthetica
 * @dev An AI-Driven Decentralized Research & Development (DARD) Guild.
 * This contract enables governance, AI model integration, project management,
 * and a dynamic Soulbound Token (SBT) reputation system.
 */
contract Synthetica is Context, Ownable, ReentrancyGuard {

    // --- State Variables & Structs ---

    // DARD Token (Governance Token)
    IERC20 public immutable i_dardToken;
    // Synthetica Soul (Soulbound Token - non-transferable ERC721)
    IERC721 public immutable i_syntheticaSoul;

    // --- Governance ---
    struct Proposal {
        uint256 id;
        address proposer;
        bytes data; // Encoded function call to execute
        string descriptionURI; // URI to detailed proposal description
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        bool executed;
        bool cancelled;
        // The target contract and selector for execution, useful for transparency
        address targetContract;
        bytes4 selector;
    }

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => voted

    // Core governance parameters (can be updated via governance proposals)
    uint256 public votingPeriodBlocks; // In blocks
    uint256 public minQuorumNumerator; // e.g., 40 for 40% quorum, denominator is 100
    uint256 public minApprovalThresholdNumerator; // e.g., 51 for 51% approval, denominator is 100

    // Adaptive rule configurations (tuned via `proposeAdaptiveRuleConfigChange`)
    mapping(bytes32 => uint256) public adaptiveRuleConfigs; // e.g., "ai_model_weight_factor" => 100 (for 100%)

    // --- AI Model Registry ---
    struct AIModel {
        uint256 id;
        string name;
        string description;
        address oracleAddress; // Address of the trusted oracle for this model
        bytes32 predictionOutputHashScheme; // Identifier for output validation
        uint256 latestAccuracyScore; // 0-10000, e.g., 9500 for 95%
        uint256 latestLatencyScore;  // e.g., milliseconds
        uint256 totalUtilityScore; // Aggregated utility from evaluations
        uint256 evaluationCount;
        bool registered;
        address owner; // The address that registered the model
    }

    uint256 public nextAIModelId;
    mapping(uint256 => AIModel) public aiModels;
    mapping(address => bool) public isApprovedOracle; // Whitelist for oracles

    // AI Insight Request tracking
    struct AIInsightRequest {
        uint256 aiModelId;
        address requester;
        bytes calldata inputData;
        bool fulfilled;
        bytes aiOutput;
        bytes32 proofHash;
    }
    mapping(bytes32 => AIInsightRequest) public aiInsightRequests; // callbackId => AIInsightRequest

    // --- Research & Development Projects ---
    enum ProjectStatus { Proposed, Approved, Funded, InProgress, Completed, Cancelled }

    struct ResearchProject {
        uint256 id;
        string title;
        string descriptionURI;
        uint256 fundingRequested;
        uint256 fundingReceived;
        address[] contributors;
        ProjectStatus status;
        address projectLead;
        uint256[] milestoneReputationAwards; // Reputation awarded per milestone
        mapping(uint256 => Milestone) milestones;
        uint256 nextMilestoneIndex;
    }

    struct Milestone {
        uint256 index;
        string milestoneURI;
        bool approved;
        uint256 reputationAwarded;
    }

    uint256 public nextProjectId;
    mapping(uint256 => ResearchProject) public projects;

    // --- Contributor Reputation (Synthetica Soul SBTs) ---
    // The actual SBT token data is managed by i_syntheticaSoul.
    // This contract tracks additional reputation specific to the Synthetica ecosystem.
    struct ContributorProfile {
        address soulHolder;
        uint256 reputationScore;
        string skillsURI; // URI to IPFS/Arweave for detailed skill profile
        mapping(bytes32 => mapping(address => uint256)) skillAttestations; // skillHash => attester => level
    }
    mapping(address => ContributorProfile) public contributorProfiles; // soulHolderAddress => ContributorProfile

    // --- Events ---
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionURI, uint256 voteStartTime, uint256 voteEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event DelegateVote(address indexed delegator, address indexed delegatee);
    event CoreParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event AdaptiveRuleConfigChanged(bytes32 indexed ruleKey, uint256 newConfigurationValue);

    event AIModelRegistered(uint256 indexed modelId, string modelName, address oracleAddress);
    event AIModelPerformanceSubmitted(uint256 indexed modelId, uint256 accuracy, uint256 latency, bytes32 integrityHash);
    event AIInsightRequested(uint256 indexed modelId, bytes32 indexed callbackId, address indexed requester);
    event AIInsightFulfilled(bytes32 indexed callbackId, bytes aiOutput, bytes32 proofHash);
    event AIModelUtilityEvaluated(uint256 indexed modelId, address indexed evaluator, uint256 score);
    event AIFundingAllocated(uint256 indexed aiModelId, uint256 amount);

    event ResearchProposalSubmitted(uint256 indexed projectId, address indexed proposer, string title, uint256 fundingRequested);
    event ResearchProposalApproved(uint256 indexed projectId, address indexed approver);
    event ResearchProjectFunded(uint256 indexed projectId, uint256 amount);
    event ProjectMilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed contributor);
    event ProjectMilestoneEvaluated(uint256 indexed projectId, uint256 indexed milestoneIndex, bool approved, uint256 reputationAward);

    event ContributorSoulMinted(address indexed contributorAddress, uint256 indexed tokenId, string initialSkillsURI);
    event ContributorSkillsUpdated(address indexed contributorAddress, string newSkillsURI);
    event SkillAttested(address indexed contributorAddress, bytes32 indexed skillHash, address indexed attester, uint256 level);
    event ReputationRewarded(address indexed contributorAddress, uint256 amount, bytes32 reasonHash);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event AdaptiveMetricCalculated(bytes32 indexed metricKey, uint256 calculatedValue);
    event AdaptiveGovernanceImpactApplied(bytes32 indexed impactKey, uint256 impactValue);

    // --- Constructor ---
    constructor(address _dardTokenAddress, address _syntheticaSoulAddress) Ownable(_msgSender()) {
        if (_dardTokenAddress == address(0) || _syntheticaSoulAddress == address(0)) {
            revert Synthetica__ZeroAddressNotAllowed();
        }
        i_dardToken = IERC20(_dardTokenAddress);
        i_syntheticaSoul = IERC721(_syntheticaSoulAddress);

        // Initial default governance parameters
        votingPeriodBlocks = 1000; // Approximately 3-4 hours on Ethereum mainnet (12s/block)
        minQuorumNumerator = 40; // 40% quorum
        minApprovalThresholdNumerator = 51; // 51% approval needed

        // Initialize some adaptive rule configs
        adaptiveRuleConfigs[bytes32("ai_model_weight_factor")] = 100; // Default 100% influence
        adaptiveRuleConfigs[bytes32("reputation_voting_multiplier")] = 1; // Default 1x
    }

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (!i_dardToken.delegatee(_msgSender()).isZero()) { // Check if sender is a delegatee of DARD
            // This is a simplified check. A full Governor contract would have its own `hasRole` or `isGovernor` logic.
            // For this example, let's assume `owner()` acts as the initial governor, and further governor roles are
            // managed by a dedicated Governor contract interacting with this.
            // For now, let's use a placeholder that the deployer can manage critical functions directly.
            // In a real scenario, this would check against a list of governor addresses or roles within a DAO framework.
            _;
        } else if (_msgSender() == owner()) { // Fallback for initial owner to act as governor
            _;
        } else {
            revert Synthetica__NotGovernor();
        }
    }

    modifier onlyOracle(uint256 _aiModelId) {
        if (!aiModels[_aiModelId].registered || aiModels[_aiModelId].oracleAddress != _msgSender()) {
            revert Synthetica__UnauthorizedOracle();
        }
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        if (projects[_projectId].projectLead != _msgSender()) {
            revert Synthetica__UnauthorizedContributor();
        }
        _;
    }

    modifier onlyContributorWithSoul(address _contributor) {
        if (contributorProfiles[_contributor].soulHolder != _contributor) {
            revert Synthetica__ContributorSoulNotFound();
        }
        _;
    }

    // --- I. Core System & Initialization Functions ---

    /**
     * @dev Allows the DAO to update core governance parameters.
     * @param _paramName The name of the parameter to update (e.g., "votingPeriodBlocks").
     * @param _newValue The new value for the parameter.
     */
    function updateCoreParameter(bytes32 _paramName, uint256 _newValue) external onlyGovernor {
        if (_paramName == bytes32("votingPeriodBlocks")) {
            votingPeriodBlocks = _newValue;
        } else if (_paramName == bytes32("minQuorumNumerator")) {
            minQuorumNumerator = _newValue;
        } else if (_paramName == bytes32("minApprovalThresholdNumerator")) {
            minApprovalThresholdNumerator = _newValue;
        } else {
            revert Synthetica__CoreParameterImmutable();
        }
        emit CoreParameterUpdated(_paramName, _newValue);
    }

    // --- II. Governance (Adaptive DAO) Functions ---

    /**
     * @dev Allows the DAO to propose changes to the configuration of adaptive rules.
     * This tunes how the contract's "self-evolving" logic operates.
     * @param _ruleKey Identifier for the adaptive rule configuration (e.g., "ai_model_weight_factor").
     * @param _newConfigurationValue The new value for the configuration.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeAdaptiveRuleConfigChange(bytes32 _ruleKey, uint256 _newConfigurationValue) external returns (uint256) {
        uint256 proposalId = nextProposalId++;
        bytes memory data = abi.encodeWithSelector(
            this.setAdaptiveRuleConfig.selector,
            _ruleKey,
            _newConfigurationValue
        );

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.data = data;
        newProposal.descriptionURI = string(abi.encodePacked("Proposed adaptive rule config change for ", _ruleKey)); // Generic description
        newProposal.voteStartTime = block.number;
        newProposal.voteEndTime = block.number + votingPeriodBlocks;
        newProposal.targetContract = address(this);
        newProposal.selector = this.setAdaptiveRuleConfig.selector;

        emit ProposalCreated(proposalId, _msgSender(), newProposal.descriptionURI, newProposal.voteStartTime, newProposal.voteEndTime);
        return proposalId;
    }

    /**
     * @dev Internal function to set adaptive rule configuration, only callable via governance execution.
     */
    function setAdaptiveRuleConfig(bytes32 _ruleKey, uint256 _newConfigurationValue) external onlyGovernor { // `onlyGovernor` here means it must be executed by the governor/DAO
        adaptiveRuleConfigs[_ruleKey] = _newConfigurationValue;
        emit AdaptiveRuleConfigChanged(_ruleKey, _newConfigurationValue);
    }

    /**
     * @dev Allows a DARD token holder to vote on a proposal.
     * Voting power is determined by DARD token balance and potentially reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) revert Synthetica__ProposalNotFound();
        if (block.number < proposal.voteStartTime || block.number > proposal.voteEndTime) revert Synthetica__ProposalNotReadyForExecution(); // Check if voting is active
        if (hasVoted[_proposalId][_msgSender()]) revert Synthetica__AlreadyVoted();

        uint256 voteWeight = i_dardToken.balanceOf(_msgSender()); // Base voting power from DARD
        // Optionally, integrate reputation from Synthetica Soul
        if (contributorProfiles[_msgSender()].soulHolder == _msgSender()) {
            voteWeight += (contributorProfiles[_msgSender()].reputationScore * adaptiveRuleConfigs[bytes32("reputation_voting_multiplier")]) / 100; // Example: 100 rep = 1 DARD
        }

        if (_for) {
            proposal.totalForVotes += voteWeight;
        } else {
            proposal.totalAgainstVotes += voteWeight;
        }
        hasVoted[_proposalId][_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), _for, voteWeight);
    }

    /**
     * @dev Executes a proposal if it has passed the voting phase and meets quorum/thresholds.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyGovernor nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) revert Synthetica__ProposalNotFound();
        if (block.number <= proposal.voteEndTime) revert Synthetica__ProposalNotReadyForExecution(); // Voting still active or not ended
        if (proposal.executed) revert Synthetica__ProposalAlreadyExecuted();

        // Calculate total votes and check quorum
        uint256 totalVotes = proposal.totalForVotes + proposal.totalAgainstVotes;
        uint256 totalDardSupply = i_dardToken.totalSupply(); // Total eligible voting power

        if (totalDardSupply == 0) revert Synthetica__InvalidConfiguration(); // Avoid division by zero

        // Check quorum: percentage of total supply participated
        if ((totalVotes * 100) / totalDardSupply < minQuorumNumerator) {
            revert Synthetica__ProposalNotReadyForExecution(); // Does not meet quorum
        }

        // Check approval threshold: percentage of 'for' votes out of total votes cast
        if (totalVotes == 0 || (proposal.totalForVotes * 100) / totalVotes < minApprovalThresholdNumerator) {
            revert Synthetica__ProposalNotReadyForExecution(); // Does not meet approval threshold
        }

        // Execute the proposal's action
        (bool success, ) = proposal.targetContract.call(proposal.data);
        if (!success) {
            // Revert execution if the internal call fails
            // This could be improved with more granular error handling depending on the data called
            revert("Synthetica: Proposal execution failed");
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows a DARD token holder to delegate their voting power.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external {
        if (_delegatee == _msgSender()) revert Synthetica__SelfDelegationNotAllowed();
        if (_delegatee == address(0)) revert Synthetica__ZeroAddressNotAllowed();
        i_dardToken.delegate(_delegatee); // Assumes DARD token implements OpenZeppelin's ERC20Votes
        emit DelegateVote(_msgSender(), _delegatee);
    }

    /**
     * @dev Creates a governance proposal to allocate funds for a specific AI model.
     * @param _aiModelId The ID of the AI model to fund.
     * @param _amount The amount of DARD tokens to allocate.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeAIFundingAllocation(uint256 _aiModelId, uint256 _amount) external returns (uint256) {
        if (!aiModels[_aiModelId].registered) revert Synthetica__AIModelNotFound();
        if (_amount == 0) revert Synthetica__InvalidConfiguration();

        uint256 proposalId = nextProposalId++;
        bytes memory data = abi.encodeWithSelector(
            this.allocateAIFunding.selector,
            _aiModelId,
            _amount
        );

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.data = data;
        newProposal.descriptionURI = string(abi.encodePacked("Allocate ", _amount, " DARD to AI Model ID ", _aiModelId));
        newProposal.voteStartTime = block.number;
        newProposal.voteEndTime = block.number + votingPeriodBlocks;
        newProposal.targetContract = address(this);
        newProposal.selector = this.allocateAIFunding.selector;

        emit ProposalCreated(proposalId, _msgSender(), newProposal.descriptionURI, newProposal.voteStartTime, newProposal.voteEndTime);
        return proposalId;
    }

    /**
     * @dev Internal function to allocate AI funding, callable only via governance execution.
     */
    function allocateAIFunding(uint256 _aiModelId, uint256 _amount) internal onlyGovernor {
        if (i_dardToken.balanceOf(address(this)) < _amount) {
            revert Synthetica__InsufficientFunds( _amount, i_dardToken.balanceOf(address(this)));
        }
        // In a real scenario, this would transfer to the AI model's wallet or an escrow.
        // For simplicity, let's assume it's "spent" from the guild's balance.
        // i_dardToken.transfer(_aiModel.owner, _amount); // Assuming AI models can have owners
        emit AIFundingAllocated(_aiModelId, _amount);
    }

    // --- III. AI Model Registry & Interaction Functions ---

    /**
     * @dev Registers a new AI model with the guild. Only approved entities can register.
     * @param _modelName Name of the AI model.
     * @param _modelDescription Description of the AI model.
     * @param _oracleAddress The address of the trusted oracle responsible for this model.
     * @param _predictionOutputHashScheme An identifier for how to hash/validate the oracle's outputs.
     * @return aiModelId The ID of the newly registered AI model.
     */
    function registerAIModel(
        string calldata _modelName,
        string calldata _modelDescription,
        address _oracleAddress,
        bytes32 _predictionOutputHashScheme
    ) external onlyGovernor returns (uint256) { // Only governor can register new AI models
        if (_oracleAddress == address(0)) revert Synthetica__ZeroAddressNotAllowed();

        uint256 newId = nextAIModelId++;
        aiModels[newId] = AIModel({
            id: newId,
            name: _modelName,
            description: _modelDescription,
            oracleAddress: _oracleAddress,
            predictionOutputHashScheme: _predictionOutputHashScheme,
            latestAccuracyScore: 0,
            latestLatencyScore: type(uint256).max, // Max value indicates not yet scored
            totalUtilityScore: 0,
            evaluationCount: 0,
            registered: true,
            owner: _msgSender()
        });
        isApprovedOracle[_oracleAddress] = true; // Automatically approve the oracle
        emit AIModelRegistered(newId, _modelName, _oracleAddress);
        return newId;
    }

    /**
     * @dev An approved oracle submits performance metrics for a registered AI model.
     * @param _aiModelId The ID of the AI model.
     * @param _accuracyScore The accuracy score (e.g., 0-10000 for 0-100%).
     * @param _latencyScore The latency score (e.g., in milliseconds).
     * @param _integrityHash A cryptographic hash to verify data integrity of the metrics.
     */
    function submitAIModelPerformance(
        uint256 _aiModelId,
        uint256 _accuracyScore,
        uint256 _latencyScore,
        bytes32 _integrityHash
    ) external onlyOracle(_aiModelId) {
        AIModel storage model = aiModels[_aiModelId];
        model.latestAccuracyScore = _accuracyScore;
        model.latestLatencyScore = _latencyScore;

        emit AIModelPerformanceSubmitted(_aiModelId, _accuracyScore, _latencyScore, _integrityHash);
    }

    /**
     * @dev Requests an insight or prediction from a registered AI model via its oracle.
     * @param _aiModelId The ID of the AI model to query.
     * @param _inputData The input data for the AI model.
     * @param _callbackId A unique ID for this specific request, to link with the fulfillment.
     */
    function requestAIInsight(uint256 _aiModelId, bytes calldata _inputData, bytes32 _callbackId) external {
        if (!aiModels[_aiModelId].registered) revert Synthetica__AIModelNotFound();
        if (aiModels[_aiModelId].oracleAddress == address(0)) revert Synthetica__InvalidConfiguration();

        aiInsightRequests[_callbackId] = AIInsightRequest({
            aiModelId: _aiModelId,
            requester: _msgSender(),
            inputData: _inputData,
            fulfilled: false,
            aiOutput: "",
            proofHash: bytes32(0)
        });

        // In a real system, this would trigger an off-chain call to the oracle.
        // For demonstration, we simply record the request.
        // A dedicated Chainlink adapter or similar pattern would be used here.

        emit AIInsightRequested(_aiModelId, _callbackId, _msgSender());
    }

    /**
     * @dev Callback function for an AI oracle to deliver a requested insight.
     * This function is expected to be called by the registered oracle address.
     * @param _callbackId The unique ID of the request.
     * @param _aiOutput The AI model's output or prediction.
     * @param _proofHash A cryptographic proof to verify the output.
     */
    function fulfillAIInsight(bytes32 _callbackId, bytes calldata _aiOutput, bytes32 _proofHash) external {
        AIInsightRequest storage request = aiInsightRequests[_callbackId];
        if (!aiModels[request.aiModelId].registered || aiModels[request.aiModelId].oracleAddress != _msgSender()) {
            revert Synthetica__UnauthorizedOracle(); // Ensure only the correct oracle fulfills
        }
        if (request.fulfilled) revert("Synthetica: Insight already fulfilled.");

        // TODO: Implement actual output validation using _proofHash and predictionOutputHashScheme
        // For now, we assume _proofHash is sufficient.
        // Example: check(keccak256(_aiOutput) == _proofHash) or more complex ZKP verification.

        request.fulfilled = true;
        request.aiOutput = _aiOutput;
        request.proofHash = _proofHash;

        emit AIInsightFulfilled(_callbackId, _aiOutput, _proofHash);
    }

    /**
     * @dev Allows DAO members or designated evaluators to score the utility of an AI model.
     * This influences the model's overall standing and potential for funding.
     * @param _aiModelId The ID of the AI model being evaluated.
     * @param _utilityScore A qualitative score (e.g., 0-100) reflecting the model's perceived usefulness.
     */
    function evaluateAIModelUtility(uint256 _aiModelId, uint256 _utilityScore) external onlyContributorWithSoul(_msgSender()) {
        if (!aiModels[_aiModelId].registered) revert Synthetica__AIModelNotFound();
        if (_utilityScore > 100) revert Synthetica__InvalidConfiguration(); // Score from 0 to 100

        AIModel storage model = aiModels[_aiModelId];
        model.totalUtilityScore += _utilityScore;
        model.evaluationCount++;

        emit AIModelUtilityEvaluated(_aiModelId, _msgSender(), _utilityScore);
    }

    // --- IV. Project Lifecycle (R&D Initiatives) Functions ---

    /**
     * @dev Submits a new research proposal to the guild for review and potential funding.
     * @param _title The title of the research proposal.
     * @param _descriptionURI URI pointing to detailed external documentation (e.g., IPFS).
     * @param _fundingRequested The total DARD token amount requested for the project.
     * @param _initialContributors List of initial contributors to the project (must have Souls).
     * @return proposalId The ID of the governance proposal created for this project.
     */
    function submitResearchProposal(
        string calldata _title,
        string calldata _descriptionURI,
        uint256 _fundingRequested,
        address[] calldata _initialContributors
    ) external onlyContributorWithSoul(_msgSender()) returns (uint256) {
        if (_fundingRequested == 0) revert Synthetica__InvalidConfiguration();
        if (bytes(_title).length == 0 || bytes(_descriptionURI).length == 0) revert Synthetica__InvalidConfiguration();

        uint256 newProjectId = nextProjectId++;
        projects[newProjectId] = ResearchProject({
            id: newProjectId,
            title: _title,
            descriptionURI: _descriptionURI,
            fundingRequested: _fundingRequested,
            fundingReceived: 0,
            contributors: _initialContributors,
            status: ProjectStatus.Proposed,
            projectLead: _msgSender(),
            milestoneReputationAwards: new uint256[](0),
            nextMilestoneIndex: 0
        });

        // Create a governance proposal for the DAO to vote on this research project
        uint256 proposalId = nextProposalId++;
        bytes memory data = abi.encodeWithSelector(
            this.approveResearchProject.selector,
            newProjectId
        );

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.data = data;
        newProposal.descriptionURI = string(abi.encodePacked("Approve research project: ", _title, " (ID: ", newProjectId, ")"));
        newProposal.voteStartTime = block.number;
        newProposal.voteEndTime = block.number + votingPeriodBlocks;
        newProposal.targetContract = address(this);
        newProposal.selector = this.approveResearchProject.selector;


        emit ResearchProposalSubmitted(newProjectId, _msgSender(), _title, _fundingRequested);
        emit ProposalCreated(proposalId, _msgSender(), newProposal.descriptionURI, newProposal.voteStartTime, newProposal.voteEndTime);
        return proposalId;
    }

    /**
     * @dev Internal function to approve a research project, callable only via governance execution.
     */
    function approveResearchProject(uint256 _projectId) external onlyGovernor {
        if (projects[_projectId].id == 0 && _projectId != 0) revert Synthetica__ProjectNotFound();
        if (projects[_projectId].status != ProjectStatus.Proposed) revert Synthetica__InvalidConfiguration(); // Already approved or invalid state

        projects[_projectId].status = ProjectStatus.Approved;
        emit ResearchProposalApproved(_projectId, _msgSender());
    }

    /**
     * @dev Funds an approved research project from the guild's treasury.
     * This is typically triggered by a governance proposal execution.
     * @param _projectId The ID of the project to fund.
     * @param _amount The amount of DARD tokens to transfer to the project.
     */
    function fundResearchProject(uint256 _projectId, uint256 _amount) external onlyGovernor nonReentrant {
        ResearchProject storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert Synthetica__ProjectNotFound();
        if (project.status != ProjectStatus.Approved && project.status != ProjectStatus.Funded) revert Synthetica__ProjectNotApproved();
        if (i_dardToken.balanceOf(address(this)) < _amount) {
            revert Synthetica__InsufficientFunds(_amount, i_dardToken.balanceOf(address(this)));
        }

        project.fundingReceived += _amount;
        project.status = ProjectStatus.Funded; // Change status to Funded if it was just Approved

        // In a full implementation, this might transfer to a multi-sig or dedicated project wallet.
        // For simplicity, we just track the received amount in the contract.
        // i_dardToken.transfer(project.projectLead, _amount); // Example: transfer to project lead
        emit ResearchProjectFunded(_projectId, _amount);
    }

    /**
     * @dev Project lead submits a completed milestone for a project.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being submitted.
     * @param _milestoneURI URI pointing to external documentation for the milestone.
     */
    function submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _milestoneURI) external onlyProjectLead(_projectId) {
        ResearchProject storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert Synthetica__ProjectNotFound();
        if (project.status != ProjectStatus.Funded && project.status != ProjectStatus.InProgress) revert Synthetica__InvalidConfiguration();
        if (_milestoneIndex != project.nextMilestoneIndex) revert Synthetica__InvalidConfiguration(); // Milestones must be submitted in order

        project.milestones[_milestoneIndex] = Milestone({
            index: _milestoneIndex,
            milestoneURI: _milestoneURI,
            approved: false,
            reputationAwarded: 0
        });
        project.nextMilestoneIndex++;
        project.status = ProjectStatus.InProgress; // Ensure status is InProgress

        emit ProjectMilestoneSubmitted(_projectId, _milestoneIndex, _msgSender());
    }

    /**
     * @dev Evaluators (e.g., governor or other approved members) evaluate a submitted project milestone.
     * If approved, reputation is awarded to contributors.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to evaluate.
     * @param _approved True if the milestone is approved, false otherwise.
     * @param _reputationAward The amount of reputation to award to contributors if approved.
     */
    function evaluateProjectMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _approved,
        uint256 _reputationAward
    ) external onlyGovernor { // Only governor can evaluate
        ResearchProject storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert Synthetica__ProjectNotFound();
        Milestone storage milestone = project.milestones[_milestoneIndex];
        if (milestone.index == 0 && _milestoneIndex != 0) revert Synthetica__MilestoneNotFound();

        milestone.approved = _approved;
        if (_approved) {
            milestone.reputationAwarded = _reputationAward;
            // Distribute reputation to all contributors listed for the project
            // This could be made more granular with per-contributor awards
            for (uint256 i = 0; i < project.contributors.length; i++) {
                address contributor = project.contributors[i];
                if (contributorProfiles[contributor].soulHolder == contributor) {
                    contributorProfiles[contributor].reputationScore += _reputationAward;
                    emit ReputationRewarded(contributor, _reputationAward, bytes32("milestone_completion"));
                }
            }
        }

        emit ProjectMilestoneEvaluated(_projectId, _milestoneIndex, _approved, _reputationAward);

        // If all milestones are completed and approved, mark project as completed
        if (_milestoneIndex == project.nextMilestoneIndex - 1 && _approved) {
             // This needs a way to define total milestones for a project
             // For simplicity, let's assume the last submitted milestone closes the project for now.
             // A real system would have a `totalMilestones` field.
            // project.status = ProjectStatus.Completed;
        }
    }

    // --- V. Reputation & Contributor System (Dynamic SBTs) Functions ---

    /**
     * @dev Mints a new non-transferable "Soul" (SBT) for a new contributor.
     * This is the entry point for becoming a recognized contributor in Synthetica.
     * @param _contributorAddress The address of the contributor.
     * @param _initialSkillsURI URI pointing to the contributor's initial skill profile.
     */
    function mintContributorSoul(address _contributorAddress, string calldata _initialSkillsURI) external onlyGovernor { // Only governor can mint new souls
        if (_contributorAddress == address(0)) revert Synthetica__ZeroAddressNotAllowed();
        if (contributorProfiles[_contributorAddress].soulHolder == _contributorAddress) revert("Synthetica: Contributor already has a Soul.");

        // Mint the actual ERC721 SBT
        // Assumes i_syntheticaSoul has a mint function callable by this contract
        // i_syntheticaSoul.mint(_contributorAddress);
        // For simplicity, we just track the profile here. In a real scenario, this
        // would involve an actual ERC721 mint where the `Synthetica` contract is the minter.

        contributorProfiles[_contributorAddress] = ContributorProfile({
            soulHolder: _contributorAddress,
            reputationScore: 0,
            skillsURI: _initialSkillsURI,
            skillAttestations: new mapping(bytes32 => mapping(address => uint256))()
        });

        // In a real SBT, the tokenId would be returned by the mint function.
        // For demonstration, let's just log the address.
        emit ContributorSoulMinted(_contributorAddress, 0, _initialSkillsURI); // 0 is placeholder for tokenId
    }

    /**
     * @dev Allows a contributor (or an approved entity/AI) to update their skill profile URI.
     * @param _contributorAddress The address of the contributor.
     * @param _newSkillsURI The new URI for the skill profile.
     */
    function updateContributorSkills(address _contributorAddress, string calldata _newSkillsURI) external onlyContributorWithSoul(_contributorAddress) {
        if (_contributorAddress != _msgSender()) { // Only contributor or explicitly approved entity can update
            revert Synthetica__UnauthorizedContributor();
        }
        contributorProfiles[_contributorAddress].skillsURI = _newSkillsURI;
        emit ContributorSkillsUpdated(_contributorAddress, _newSkillsURI);
    }

    /**
     * @dev Allows other contributors or approved AI to attest to a specific skill of another contributor.
     * This directly impacts the target contributor's reputation.
     * @param _contributorAddress The address of the contributor receiving the attestation.
     * @param _skillHash A hash representing the skill (e.g., keccak256("Solidity Programming")).
     * @param _level The proficiency level for the skill (e.g., 1-5).
     */
    function attestToSkill(address _contributorAddress, bytes32 _skillHash, uint256 _level) external onlyContributorWithSoul(_msgSender()) {
        if (_contributorAddress == address(0)) revert Synthetica__ZeroAddressNotAllowed();
        if (_contributorAddress == _msgSender()) revert("Synthetica: Cannot attest to your own skill.");
        if (contributorProfiles[_contributorAddress].soulHolder != _contributorAddress) revert Synthetica__ContributorSoulNotFound();
        if (_level == 0 || _level > 5) revert Synthetica__InvalidConfiguration();

        ContributorProfile storage profile = contributorProfiles[_contributorAddress];
        profile.skillAttestations[_skillHash][_msgSender()] = _level;

        // Influence reputation based on attestation (example logic)
        profile.reputationScore += _level; // Add level directly to reputation
        // More complex logic could be: (old_avg * count + new_level) / (count + 1)
        
        emit SkillAttested(_contributorAddress, _skillHash, _msgSender(), _level);
        emit ReputationRewarded(_contributorAddress, _level, bytes32("skill_attestation"));
    }

    /**
     * @dev Awards reputation points to a contributor's Soul.
     * Can be used for specific achievements, successful project contributions, etc.
     * @param _contributorAddress The address of the contributor to reward.
     * @param _amount The amount of reputation points to award.
     * @param _reasonHash A hash linking to the reason for the reward (e.g., IPFS CID).
     */
    function distributeReputationReward(address _contributorAddress, uint256 _amount, bytes32 _reasonHash) external onlyGovernor {
        if (contributorProfiles[_contributorAddress].soulHolder != _contributorAddress) revert Synthetica__ContributorSoulNotFound();
        if (_amount == 0) revert Synthetica__InvalidConfiguration();

        contributorProfiles[_contributorAddress].reputationScore += _amount;
        emit ReputationRewarded(_contributorAddress, _amount, _reasonHash);
    }

    // --- VI. Treasury & Funding Functions ---

    /**
     * @dev Allows anyone to deposit Ether into the Synthetica guild treasury.
     */
    receive() external payable {
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Allows the DAO to withdraw funds (Ether) from the treasury.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawFunds(address _recipient, uint256 _amount) external onlyGovernor nonReentrant {
        if (_recipient == address(0)) revert Synthetica__ZeroAddressNotAllowed();
        if (address(this).balance < _amount) {
            revert Synthetica__InsufficientFunds(_amount, address(this).balance);
        }

        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) {
            revert("Synthetica: Ether withdrawal failed.");
        }
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- VII. Adaptive Mechanism (Self-Evolving Logic) Functions ---

    /**
     * @dev Triggers an internal calculation of a specific adaptive metric based on current state
     * and `adaptiveRuleConfigs`.
     * @param _metricKey Identifier for the metric to calculate (e.g., "ai_model_avg_utility").
     * @return calculatedValue The calculated value of the metric.
     */
    function triggerAdaptiveMetricCalculation(bytes32 _metricKey) external view returns (uint256 calculatedValue) {
        if (_metricKey == bytes32("ai_model_avg_utility")) {
            uint256 totalUtility = 0;
            uint256 totalEvaluations = 0;
            for (uint256 i = 0; i < nextAIModelId; i++) {
                if (aiModels[i].registered && aiModels[i].evaluationCount > 0) {
                    totalUtility += aiModels[i].totalUtilityScore;
                    totalEvaluations += aiModels[i].evaluationCount;
                }
            }
            calculatedValue = (totalEvaluations > 0) ? (totalUtility * 100) / totalEvaluations : 0; // Average utility score out of 100
        } else if (_metricKey == bytes32("avg_project_milestone_success_rate")) {
            // Placeholder: calculate average milestone approval rate across projects
            uint256 approvedMilestones = 0;
            uint256 totalMilestones = 0;
            for (uint256 i = 0; i < nextProjectId; i++) {
                if (projects[i].status == ProjectStatus.Completed || projects[i].status == ProjectStatus.InProgress) {
                    for (uint256 j = 0; j < projects[i].nextMilestoneIndex; j++) {
                        totalMilestones++;
                        if (projects[i].milestones[j].approved) {
                            approvedMilestones++;
                        }
                    }
                }
            }
            calculatedValue = (totalMilestones > 0) ? (approvedMilestones * 100) / totalMilestones : 0; // Success rate out of 100
        } else {
            revert Synthetica__InvalidConfiguration(); // Unknown metric key
        }
        emit AdaptiveMetricCalculated(_metricKey, calculatedValue);
        return calculatedValue;
    }

    /**
     * @dev Applies the effect of an adaptive metric calculation on governance or operational parameters.
     * This function can dynamically adjust quorum, voting power multipliers, or other factors.
     * @param _impactKey Identifier for the impact to apply (e.g., "adjust_quorum_based_on_ai").
     * @param _impactValue The calculated value from `triggerAdaptiveMetricCalculation` or similar.
     */
    function applyAdaptiveGovernanceImpact(bytes32 _impactKey, uint256 _impactValue) external onlyGovernor {
        if (_impactKey == bytes32("adjust_quorum_based_on_ai")) {
            // Example: Adjust minimum quorum based on AI model average utility.
            // If AI models are performing well (_impactValue is high), quorum might be slightly reduced
            // or approval threshold increased, assuming more informed decisions.
            // This is a placeholder for actual complex logic.
            uint256 aiWeightFactor = adaptiveRuleConfigs[bytes32("ai_model_weight_factor")]; // 0-100
            uint256 currentMinQuorum = minQuorumNumerator;

            if (_impactValue > 75) { // If AI utility is high (e.g., >75%)
                // Reduce quorum slightly, e.g., by 10% of the AI's influence
                minQuorumNumerator = (currentMinQuorum * (1000 - (aiWeightFactor * 10)/100)) / 1000; // Example: if factor is 100, reduce quorum by 10%
            } else if (_impactValue < 50) { // If AI utility is low
                // Increase quorum slightly, requiring more human consensus
                minQuorumNumerator = (currentMinQuorum * (1000 + (aiWeightFactor * 10)/100)) / 1000;
            }
            // Ensure quorum doesn't go below a certain minimum or above a maximum
            if (minQuorumNumerator < 20) minQuorumNumerator = 20;
            if (minQuorumNumerator > 80) minQuorumNumerator = 80;

        } else if (_impactKey == bytes32("re_weight_project_selection_ai_bias")) {
            // Example: Adjust AI's influence on project selection based on project success rate.
            // If projects are succeeding (high _impactValue), AI recommendations gain more weight.
            // This would influence off-chain project recommendation systems or future governance proposals.
            adaptiveRuleConfigs[bytes32("project_ai_selection_bias")] = _impactValue; // Store the bias factor
        } else {
            revert Synthetica__InvalidConfiguration(); // Unknown impact key
        }
        emit AdaptiveGovernanceImpactApplied(_impactKey, _impactValue);
    }

    // --- View Functions ---

    /**
     * @dev Returns the current voting power of an address.
     * @param _voter The address to check.
     * @return The calculated voting power.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 power = i_dardToken.balanceOf(_voter);
        if (contributorProfiles[_voter].soulHolder == _voter) {
            power += (contributorProfiles[_voter].reputationScore * adaptiveRuleConfigs[bytes32("reputation_voting_multiplier")]) / 100;
        }
        return power;
    }

    /**
     * @dev Returns the current status of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return A string indicating the proposal's status.
     */
    function getProposalStatus(uint256 _proposalId) public view returns (string memory) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) return "NotFound";
        if (proposal.executed) return "Executed";
        if (proposal.cancelled) return "Cancelled";
        if (block.number <= proposal.voteEndTime) return "Voting Active";
        // Voting ended, check if it passed
        uint256 totalVotes = proposal.totalForVotes + proposal.totalAgainstVotes;
        uint256 totalDardSupply = i_dardToken.totalSupply();

        if (totalDardSupply == 0 || (totalVotes * 100) / totalDardSupply < minQuorumNumerator) {
            return "Failed (No Quorum)";
        }
        if (totalVotes == 0 || (proposal.totalForVotes * 100) / totalVotes < minApprovalThresholdNumerator) {
            return "Failed (Not Approved)";
        }
        return "Succeeded (Ready for Execution)";
    }
}
```