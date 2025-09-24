Here's a smart contract written in Solidity, incorporating advanced concepts, creative features, and trendy functionalities, with a minimum of 20 functions. It aims to avoid direct duplication of existing open-source projects by combining unique elements into a cohesive system.

**Contract Name:** `AetherForge`

**Description:**
`AetherForge` is a decentralized Research & Development (R&D) platform that leverages AI-powered oracles for objective proposal evaluation, continuous progress tracking, and verifiable outcome validation. It creates a meritocratic ecosystem for innovation by combining robust decentralized governance with a dynamic reputation system for both human contributors and AI agents. The contract facilitates milestone-based funding, ensures transparency through a knowledge registry for successful outcomes, and utilizes non-transferable Soulbound Tokens (SBTs) to acknowledge human contributions.

**Core Concepts:**

*   **AI-Assisted Evaluation:** Utilizes specialized external oracles to provide initial evaluation scores for research proposals and continuous progress reports for active projects, enhancing objectivity.
*   **Decentralized Governance:** Token holders govern critical platform parameters, funding approvals, and major strategic decisions through a voting mechanism.
*   **Milestone-Based Funding:** Approved projects receive funds incrementally upon successful, AI-verified completion of predefined milestones, ensuring accountability and efficient resource allocation.
*   **Dynamic Reputation System:**
    *   **Human Contributors:** Earn non-transferable Soulbound Tokens (SBTs) as proof of successful project involvement and achievement.
    *   **AI Agents:** Maintain an on-chain reputation score that dynamically adjusts based on verifiable performance feedback from governance or high-reputation members, influencing their eligibility for evaluation tasks.
*   **Knowledge Registry:** An immutable on-chain record for IPFS hashes of successfully completed research outcomes and their metadata, fostering open science and discoverability.
*   **Dynamic Parameters:** Key system thresholds (e.g., minimum AI scores, collateral amounts, reputation requirements) are adjustable via governance proposals, allowing the DAO to evolve.

**Key Features:**

*   **Multi-Stage Proposal Approval:** Proposals undergo initial collateralization, AI evaluation, and then governance approval (potentially via voting) before receiving funding.
*   **On-Demand AI Progress Reports:** Project proposers or governance can request AI reports for specific milestones.
*   **Collateral & Penalties:** Proposers deposit collateral, which can be slashed if the project fails or is deemed fraudulent.
*   **AI Agent Registration & Feedback:** Trusted AI services can register and have their performance reviewed on-chain.
*   **SBTs for Contributors:** A non-transferable badge of honor and proof of contribution for successful project participants.
*   **Secure Oracle Integration:** Dedicated interfaces for AI oracles ensure secure and verifiable callbacks.

---

**Function Summary (28 Functions):**

**I. Core Setup & Governance Parameters (4 functions)**
1.  `constructor()`: Initializes the contract with an owner, governance token, oracle addresses, and SBT contract address.
2.  `setGovernanceToken(address _token)`: Updates the ERC20 token used for governance. Callable by governance.
3.  `setAIEvaluationOracle(address _oracle)`: Sets the address of the AI Evaluation Oracle contract. Callable by governance.
4.  `setAIProgressOracle(address _oracle)`: Sets the address of the AI Progress Tracking Oracle contract. Callable by governance.

**II. Proposal Management (4 functions)**
5.  `submitResearchProposal(string memory _ipfsHash, uint256 _totalFundingRequested, string[] memory _milestoneIPFSHashes, uint256[] memory _milestoneAmounts, uint256 _collateralAmount)`: Allows users to submit new R&D proposals with details, funding requests, and milestones. Requires collateral.
6.  `updateProposalDetails(uint256 _proposalId, string memory _newIpfsHash)`: Allows a proposal's owner to update non-critical aspects of their proposal before approval.
7.  `getProposalDetails(uint256 _proposalId)`: Retrieves comprehensive details for a given proposal ID.
8.  `depositProposalCollateral(uint256 _proposalId)`: Allows a proposer to deposit additional required collateral for their proposal.

**III. AI Oracle Integration & Evaluation (6 functions)**
9.  `requestAIEvaluation(uint256 _proposalId)`: Triggers an off-chain request to the AI Evaluation Oracle for a proposal's initial score.
10. `receiveAIEvaluation(uint256 _proposalId, uint256 _evaluationScore)`: Oracle callback function to record the AI's initial evaluation score for a proposal.
11. `requestAIProgressReport(uint256 _proposalId, uint256 _milestoneIndex)`: Triggers an off-chain request to the AI Progress Oracle for a project's milestone progress.
12. `receiveAIProgressReport(uint256 _proposalId, uint256 _milestoneIndex, uint256 _progressScore)`: Oracle callback function to record the AI's progress report for a specific milestone.
13. `registerAIAgentReputation(address _agentAddress, string memory _agentName)`: Allows a trusted AI agent service to register and receive an initial reputation score.
14. `submitAIAgentPerformanceFeedback(address _agentAddress, int256 _reputationDelta, string memory _reasonHash)`: Allows governance or high-reputation members to provide feedback on an AI agent's performance, affecting its reputation.

**IV. Governance & Funding (7 functions)**
15. `submitGovernanceProposal(string memory _descriptionHash, address _target, bytes memory _calldata, uint256 _voteDuration)`: Allows token holders to propose changes to contract parameters, budget allocations, or other critical decisions.
16. `voteOnGovernanceProposal(uint256 _govProposalId, bool _support)`: Enables token holders to cast their votes on active governance proposals.
17. `approveResearchProposal(uint256 _proposalId)`: Governance function to formally approve a research proposal after sufficient AI evaluation and community review/voting.
18. `fundResearchProposal(uint256 _proposalId)`: Transfers approved funds (native currency) from the treasury to an approved proposal (internally managed).
19. `releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex)`: Releases funds for a successfully completed and AI-verified milestone.
20. `slashProposalCollateral(uint256 _proposalId)`: Penalizes a failed or fraudulent proposal by seizing its deposited collateral.
21. `disburseFinalProjectRewards(uint256 _proposalId)`: Distributes final rewards to the project team upon full, successful completion and verification (placeholder for additional rewards beyond milestones).

**V. Reputation & Rewards (3 functions)**
22. `mintContributorReputationNFT(address _contributor, uint256 _proposalId, string memory _tokenURI)`: Mints a non-transferable Soulbound Token (SBT) as an achievement badge for key contributors to successful projects.
23. `awardAIAgentBoost(address _agentAddress, uint256 _boostAmount)`: Increases an AI agent's reputation score for exceptional, verified performance.
24. `updateReputationThresholds(uint256 _minAIReviewRep, uint256 _minGovVoteRep)`: Governance function to adjust thresholds for reputation-based access or rewards.

**VI. Knowledge & Utility (4 functions)**
25. `registerSuccessfulOutcome(uint256 _proposalId, string memory _outcomeIpfsHash, string memory _outcomeMetadataHash)`: Records the IPFS hash and metadata of a successfully completed and validated research outcome or discovery.
26. `retrieveOutcomeMetadata(uint256 _proposalId)`: Retrieves the stored metadata for a registered outcome.
27. `getContractBalance()`: Returns the current balance of the contract's treasury (in native currency).
28. `withdrawExcessFunds(address _recipient, uint256 _amount)`: Allows governance to withdraw surplus native currency from the contract's treasury to a designated address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for explicit safety, though 0.8.0+ handles overflow for uint.

// Custom Errors
error Unauthorized();
error InsufficientBalance();
error ProposalNotFound(uint256 proposalId);
error ProposalAlreadyApproved(uint256 proposalId);
error ProposalNotApproved(uint256 proposalId);
error InvalidMilestone(uint256 proposalId, uint256 milestoneIndex);
error MilestoneAlreadyPaid(uint256 proposalId, uint256 milestoneIndex);
error NoFundsForMilestone();
error NotYetEvaluated(uint256 proposalId);
error GovernanceProposalNotFound(uint256 proposalId);
error GovernanceProposalNotActive(uint256 proposalId);
error AlreadyVoted(uint256 proposalId, address voter);
error VotingPeriodExpired(uint256 proposalId);
error VotingPeriodNotStarted(uint256 proposalId);
error LowReputation();
error InvalidOracleCall();
error NotEnoughCollateral(uint256 required, uint256 provided);
error OracleNotSet();
error GovernanceTokenNotSet();
error AIProgressReportPending();
error AIAgentNotFound(address agentAddress);
error SBTContractNotSet();
error InvalidSBTParameters();

// Oracle Interface for AI evaluations and progress reports
interface IAetherForgeOracle {
    function requestEvaluation(uint256 proposalId, string memory ipfsHash, address callbackAddress) external;
    function requestProgressReport(uint256 proposalId, uint256 milestoneIndex, string memory milestoneHash, address callbackAddress) external;
}

// Soulbound Token (SBT) Interface for Contributor Reputation
// This interface defines the expected functions of an external SBT contract.
interface ISoulboundToken {
    function mint(address to, uint256 tokenId, string memory tokenURI) external;
    function exists(uint256 tokenId) external view returns (bool);
    function getTokenURI(uint256 tokenId) external view returns (string memory); // Added for completeness
    // Assuming a simple SBT does not have transfer functionality, hence no transfer-related functions.
}

contract AetherForge is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    // Governance
    IERC20 public governanceToken;
    address public governanceCommittee; // An address or a multi-sig, representing the governing body
    uint256 public constant MIN_VOTE_POWER_FOR_GOV_PROPOSAL = 1000 * (10 ** 18); // Example: 1000 tokens

    // Oracles
    IAetherForgeOracle public aiEvaluationOracle;
    IAetherForgeOracle public aiProgressOracle;

    // Proposal Management
    uint256 public nextProposalId;
    uint256 public minProposalCollateral = 1 ether; // Example: 1 native token
    uint256 public minAIEvaluationScore = 70; // Proposals need at least 70/100 from AI to proceed
    uint256 public minAIProgressScore = 75; // Milestones need at least 75/100 from AI to release funds

    struct Milestone {
        string ipfsHash;
        uint256 amount;
        bool paid;
        bool progressReportRequested;
        uint256 progressScore;
        bool progressApproved; // Reflects AI score met threshold
    }

    enum ProposalStatus { Pending, CollateralDeposited, AwaitingAIEval, AwaitingGovApproval, Approved, Active, Completed, Failed, Slashed }

    struct ResearchProposal {
        address proposer;
        string ipfsHash; // Hash to detailed proposal document
        uint256 totalFundingRequested;
        uint256 collateralDeposited;
        Milestone[] milestones;
        ProposalStatus status;
        uint256 aiEvaluationScore; // 0-100 scale
        uint256 approvalTimestamp;
        uint256 fundingDistributed; // Sum of amounts paid for milestones
        string outcomeIpfsHash; // Hash to final outcome/report
        string outcomeMetadataHash; // Hash to metadata about the outcome
    }
    mapping(uint256 => ResearchProposal) public researchProposals;

    // Governance Proposals
    uint256 public nextGovProposalId;
    enum GovProposalStatus { Pending, Active, Passed, Failed, Executed }

    struct GovernanceProposal {
        string descriptionHash; // IPFS hash for proposal details
        address target; // Address of contract to call
        bytes calldata; // Data to call with
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        GovProposalStatus status;
        mapping(address => bool) hasVoted; // Keep track of voters
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Reputation System for AI Agents
    uint256 public minAIAgentReputationForReview = 100; // Minimum reputation for an AI agent to be considered for evaluation tasks
    uint256 public minHumanReputationForGovFeedback = 50; // Minimum reputation (placeholder for humans) for giving AI agent feedback

    struct AIAgent {
        string name;
        int256 reputationScore; // Can be positive or negative
        uint256 lastActivity;
        bool registered;
    }
    mapping(address => AIAgent) public aiAgents;

    // Contributor Reputation (SBTs) - assuming an external SBT contract
    ISoulboundToken public contributorSBT; // Address of the deployed SBT contract

    // Events
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string ipfsHash, uint256 fundingRequested, uint256 collateral);
    event ProposalDetailsUpdated(uint256 indexed proposalId, string newIpfsHash);
    event CollateralDeposited(uint256 indexed proposalId, address indexed depositor, uint256 amount);
    event AIEvaluationRequested(uint256 indexed proposalId, address indexed requestor);
    event AIEvaluationReceived(uint256 indexed proposalId, uint256 score);
    event AIProgressReportRequested(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed requestor);
    event AIProgressReportReceived(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 score);
    event ResearchProposalApproved(uint256 indexed proposalId, address indexed approver);
    event ResearchProposalFunded(uint256 indexed proposalId, uint256 amount);
    event MilestoneFundsReleased(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount);
    event ProposalCollateralSlashed(uint256 indexed proposalId, uint256 amount);
    event FinalProjectRewardsDisbursed(uint256 indexed proposalId, uint256 amount);
    event ContributorReputationMinted(uint256 indexed proposalId, address indexed contributor, uint256 indexed tokenId);
    event AIAgentRegistered(address indexed agentAddress, string name, int256 initialReputation);
    event AIAgentReputationUpdated(address indexed agentAddress, int256 newReputation, string reasonHash);
    event GovernanceProposalSubmitted(uint256 indexed govProposalId, address indexed proposer, string descriptionHash);
    event VoteCast(uint256 indexed govProposalId, address indexed voter, bool support, uint256 votePower);
    event GovernanceProposalPassed(uint256 indexed govProposalId);
    event GovernanceProposalExecuted(uint256 indexed govProposalId);
    event OutcomeRegistered(uint256 indexed proposalId, string outcomeIpfsHash, string outcomeMetadataHash);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event GovernanceCommitteeSet(address indexed newCommittee);
    event OracleAddressSet(address indexed oracleAddress, bool isEvaluationOracle);
    event ReputationThresholdsUpdated(uint256 minAIReviewRep, uint256 minGovVoteRep);

    // Modifier to check if the caller is the governance committee
    modifier onlyGovernance() {
        if (msg.sender != governanceCommittee) revert Unauthorized();
        _;
    }

    // Modifier for Oracle callbacks
    modifier onlyOracle() {
        if (msg.sender != address(aiEvaluationOracle) && msg.sender != address(aiProgressOracle)) revert InvalidOracleCall();
        _;
    }

    // --- Constructor ---
    constructor(address _governanceToken, address _initialGovernanceCommittee, address _aiEvaluationOracle, address _aiProgressOracle, address _contributorSBT) Ownable(msg.sender) {
        if (_governanceToken == address(0)) revert GovernanceTokenNotSet();
        if (_initialGovernanceCommittee == address(0)) revert Unauthorized();
        if (_aiEvaluationOracle == address(0) || _aiProgressOracle == address(0)) revert OracleNotSet();
        if (_contributorSBT == address(0)) revert SBTContractNotSet();

        governanceToken = IERC20(_governanceToken);
        governanceCommittee = _initialGovernanceCommittee;
        aiEvaluationOracle = IAetherForgeOracle(_aiEvaluationOracle);
        aiProgressOracle = IAetherForgeOracle(_aiProgressOracle);
        contributorSBT = ISoulboundToken(_contributorSBT);

        nextProposalId = 1;
        nextGovProposalId = 1;

        emit GovernanceCommitteeSet(_initialGovernanceCommittee);
        emit OracleAddressSet(_aiEvaluationOracle, true);
        emit OracleAddressSet(_aiProgressOracle, false);
    }

    // --- I. Core Setup & Governance Parameters ---

    /// @notice Sets the ERC20 token used for governance. Only callable by the governance committee.
    /// @param _token The address of the new ERC20 governance token.
    function setGovernanceToken(address _token) external onlyGovernance {
        if (_token == address(0)) revert GovernanceTokenNotSet();
        governanceToken = IERC20(_token);
    }

    /// @notice Sets the address of the AI Evaluation Oracle contract. Only callable by the governance committee.
    /// @param _oracle The address of the new AI Evaluation Oracle.
    function setAIEvaluationOracle(address _oracle) external onlyGovernance {
        if (_oracle == address(0)) revert OracleNotSet();
        aiEvaluationOracle = IAetherForgeOracle(_oracle);
        emit OracleAddressSet(_oracle, true);
    }

    /// @notice Sets the address of the AI Progress Tracking Oracle contract. Only callable by the governance committee.
    /// @param _oracle The address of the new AI Progress Tracking Oracle.
    function setAIProgressOracle(address _oracle) external onlyGovernance {
        if (_oracle == address(0)) revert OracleNotSet();
        aiProgressOracle = IAetherForgeOracle(_oracle);
        emit OracleAddressSet(_oracle, false);
    }

    // --- II. Proposal Management ---

    /// @notice Allows users to submit new R&D proposals. Requires an initial collateral deposit.
    /// @param _ipfsHash IPFS hash pointing to the detailed proposal document.
    /// @param _totalFundingRequested Total funding requested for the project.
    /// @param _milestoneIPFSHashes Array of IPFS hashes for each milestone's details.
    /// @param _milestoneAmounts Array of funding amounts for each milestone.
    /// @param _collateralAmount The amount of native token to deposit as collateral.
    function submitResearchProposal(
        string memory _ipfsHash,
        uint256 _totalFundingRequested,
        string[] memory _milestoneIPFSHashes,
        uint256[] memory _milestoneAmounts,
        uint256 _collateralAmount
    ) external payable nonReentrant {
        if (bytes(_ipfsHash).length == 0 || _totalFundingRequested == 0 || _milestoneIPFSHashes.length == 0 || _milestoneIPFSHashes.length != _milestoneAmounts.length) {
            revert("Invalid proposal parameters");
        }
        if (msg.value < _collateralAmount) revert NotEnoughCollateral(minProposalCollateral, msg.value);
        if (_collateralAmount < minProposalCollateral) revert NotEnoughCollateral(minProposalCollateral, _collateralAmount);

        uint256 proposalId = nextProposalId++;
        Milestone[] memory newMilestones = new Milestone[](_milestoneIPFSHashes.length);
        uint256 totalMilestoneAmount;
        for (uint256 i = 0; i < _milestoneIPFSHashes.length; i++) {
            newMilestones[i] = Milestone({
                ipfsHash: _milestoneIPFSHashes[i],
                amount: _milestoneAmounts[i],
                paid: false,
                progressReportRequested: false,
                progressScore: 0,
                progressApproved: false
            });
            totalMilestoneAmount = totalMilestoneAmount.add(_milestoneAmounts[i]);
        }
        if (totalMilestoneAmount != _totalFundingRequested) revert("Milestone amounts must sum to total funding");

        researchProposals[proposalId] = ResearchProposal({
            proposer: msg.sender,
            ipfsHash: _ipfsHash,
            totalFundingRequested: _totalFundingRequested,
            collateralDeposited: msg.value,
            milestones: newMilestones,
            status: ProposalStatus.CollateralDeposited,
            aiEvaluationScore: 0,
            approvalTimestamp: 0,
            fundingDistributed: 0,
            outcomeIpfsHash: "",
            outcomeMetadataHash: ""
        });

        emit ProposalSubmitted(proposalId, msg.sender, _ipfsHash, _totalFundingRequested, msg.value);
    }

    /// @notice Allows a proposal's owner to update non-critical aspects of their proposal before approval.
    /// @param _proposalId The ID of the proposal to update.
    /// @param _newIpfsHash The new IPFS hash for the detailed proposal document.
    function updateProposalDetails(uint256 _proposalId, string memory _newIpfsHash) external {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.proposer != msg.sender) revert Unauthorized();
        if (proposal.status != ProposalStatus.CollateralDeposited && proposal.status != ProposalStatus.AwaitingAIEval) {
            revert("Proposal can only be updated in initial stages");
        }
        if (bytes(_newIpfsHash).length == 0) revert("New IPFS hash cannot be empty");

        proposal.ipfsHash = _newIpfsHash;
        emit ProposalDetailsUpdated(_proposalId, _newIpfsHash);
    }

    /// @notice Retrieves comprehensive details for a given proposal ID.
    /// @param _proposalId The ID of the proposal to retrieve.
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            address proposer,
            string memory ipfsHash,
            uint256 totalFundingRequested,
            uint256 collateralDeposited,
            ProposalStatus status,
            uint256 aiEvaluationScore,
            uint256 approvalTimestamp,
            uint256 fundingDistributed
        )
    {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);

        return (
            proposal.proposer,
            proposal.ipfsHash,
            proposal.totalFundingRequested,
            proposal.collateralDeposited,
            proposal.status,
            proposal.aiEvaluationScore,
            proposal.approvalTimestamp,
            proposal.fundingDistributed
        );
    }

    /// @notice Allows a proposer to deposit additional collateral for their proposal if initial deposit was insufficient.
    /// @param _proposalId The ID of the proposal to deposit collateral for.
    function depositProposalCollateral(uint256 _proposalId) external payable nonReentrant {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.proposer != msg.sender) revert Unauthorized();
        if (proposal.status != ProposalStatus.CollateralDeposited && proposal.status != ProposalStatus.AwaitingAIEval) {
            revert("Collateral cannot be adjusted at this stage.");
        }

        proposal.collateralDeposited = proposal.collateralDeposited.add(msg.value);
        emit CollateralDeposited(_proposalId, msg.sender, msg.value);
    }

    // --- III. AI Oracle Integration & Evaluation ---

    /// @notice Triggers an off-chain request to the AI Evaluation Oracle for a proposal's initial score.
    ///         Can be called by any registered AI Agent (meeting reputation) or governance after collateral is deposited.
    /// @param _proposalId The ID of the proposal to evaluate.
    function requestAIEvaluation(uint256 _proposalId) external {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.CollateralDeposited && proposal.status != ProposalStatus.AwaitingAIEval) {
            revert("Proposal is not in a state to be evaluated by AI.");
        }

        // Only allow registered AI agents or governance to request initial evaluation
        bool isAIAgent = aiAgents[msg.sender].registered;
        if (!isAIAgent && msg.sender != governanceCommittee) {
            revert Unauthorized();
        }
        if (isAIAgent && aiAgents[msg.sender].reputationScore < int256(minAIAgentReputationForReview)) {
            revert LowReputation();
        }

        proposal.status = ProposalStatus.AwaitingAIEval;
        aiEvaluationOracle.requestEvaluation(_proposalId, proposal.ipfsHash, address(this));
        emit AIEvaluationRequested(_proposalId, msg.sender);
    }

    /// @notice Oracle callback function to record the AI's initial evaluation score for a proposal.
    ///         Only callable by the registered AI Evaluation Oracle.
    /// @param _proposalId The ID of the proposal.
    /// @param _evaluationScore The AI's evaluation score (0-100).
    function receiveAIEvaluation(uint256 _proposalId, uint256 _evaluationScore) external onlyOracle {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.AwaitingAIEval) revert("Proposal is not awaiting AI evaluation.");
        if (_evaluationScore > 100) revert("Evaluation score must be between 0 and 100.");

        proposal.aiEvaluationScore = _evaluationScore;
        proposal.status = ProposalStatus.AwaitingGovApproval; // Now ready for human governance
        emit AIEvaluationReceived(_proposalId, _evaluationScore);
    }

    /// @notice Triggers an off-chain request to the AI Progress Oracle for a project's milestone progress.
    ///         Callable by the project proposer or governance for active projects.
    /// @param _proposalId The ID of the active proposal.
    /// @param _milestoneIndex The index of the milestone to report on.
    function requestAIProgressReport(uint256 _proposalId, uint256 _milestoneIndex) external {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.Active) revert("Proposal is not active.");
        if (_milestoneIndex >= proposal.milestones.length) revert InvalidMilestone(_proposalId, _milestoneIndex);
        if (proposal.milestones[_milestoneIndex].paid) revert MilestoneAlreadyPaid(_proposalId, _milestoneIndex);

        // Allow proposer or governance to request
        if (msg.sender != proposal.proposer && msg.sender != governanceCommittee) revert Unauthorized();

        proposal.milestones[_milestoneIndex].progressReportRequested = true;
        aiProgressOracle.requestProgressReport(_proposalId, _milestoneIndex, proposal.milestones[_milestoneIndex].ipfsHash, address(this));
        emit AIProgressReportRequested(_proposalId, _milestoneIndex, msg.sender);
    }

    /// @notice Oracle callback function to record the AI's progress report for a specific milestone.
    ///         Only callable by the registered AI Progress Oracle.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _progressScore The AI's progress score (0-100).
    function receiveAIProgressReport(uint256 _proposalId, uint256 _milestoneIndex, uint256 _progressScore) external onlyOracle {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (_milestoneIndex >= proposal.milestones.length) revert InvalidMilestone(_proposalId, _milestoneIndex);
        if (!proposal.milestones[_milestoneIndex].progressReportRequested) revert AIProgressReportPending();
        if (_progressScore > 100) revert("Progress score must be between 0 and 100.");

        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        milestone.progressScore = _progressScore;
        milestone.progressApproved = (_progressScore >= minAIProgressScore);
        milestone.progressReportRequested = false; // Reset for potential re-request if needed

        emit AIProgressReportReceived(_proposalId, _milestoneIndex, _progressScore);
    }

    /// @notice Allows a trusted AI agent service to register and receive an initial reputation score.
    ///         Only callable by the governance committee.
    /// @param _agentAddress The address of the AI agent contract or EOA.
    /// @param _agentName The name of the AI agent.
    function registerAIAgentReputation(address _agentAddress, string memory _agentName) external onlyGovernance {
        if (_agentAddress == address(0) || bytes(_agentName).length == 0) revert("Invalid AI Agent parameters");
        if (aiAgents[_agentAddress].registered) revert("AI Agent already registered");

        aiAgents[_agentAddress] = AIAgent({
            name: _agentName,
            reputationScore: 100, // Initial reputation
            lastActivity: block.timestamp,
            registered: true
        });
        emit AIAgentRegistered(_agentAddress, _agentName, 100);
    }

    /// @notice Allows governance or high-reputation members to provide feedback on an AI agent's performance, affecting its reputation.
    /// @param _agentAddress The address of the AI agent.
    /// @param _reputationDelta The change in reputation score (can be positive or negative).
    /// @param _reasonHash IPFS hash for the detailed reason/evidence of the feedback.
    function submitAIAgentPerformanceFeedback(address _agentAddress, int256 _reputationDelta, string memory _reasonHash) external {
        if (!aiAgents[_agentAddress].registered) revert AIAgentNotFound(_agentAddress);

        // For this example, only governance can provide feedback.
        // In a more complex system, human reputation (e.g., from SBTs or other metrics) could grant this power.
        if (msg.sender != governanceCommittee) revert Unauthorized();

        aiAgents[_agentAddress].reputationScore += _reputationDelta;
        aiAgents[_agentAddress].lastActivity = block.timestamp;

        emit AIAgentReputationUpdated(_agentAddress, aiAgents[_agentAddress].reputationScore, _reasonHash);
    }

    // --- IV. Governance & Funding ---

    /// @notice Allows token holders to propose changes to contract parameters, budget allocations, or other critical decisions.
    /// @param _descriptionHash IPFS hash for the detailed governance proposal.
    /// @param _target The address of the contract to call if the proposal passes.
    /// @param _calldata The calldata to send to the target contract.
    /// @param _voteDuration The duration of the voting period in seconds.
    function submitGovernanceProposal(
        string memory _descriptionHash,
        address _target,
        bytes memory _calldata,
        uint256 _voteDuration
    ) external nonReentrant {
        if (governanceToken.balanceOf(msg.sender) < MIN_VOTE_POWER_FOR_GOV_PROPOSAL) {
            revert LowReputation();
        }
        if (bytes(_descriptionHash).length == 0 || _voteDuration == 0) revert("Invalid governance proposal parameters.");

        uint256 govProposalId = nextGovProposalId++;
        governanceProposals[govProposalId] = GovernanceProposal({
            descriptionHash: _descriptionHash,
            target: _target,
            calldata: _calldata,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + _voteDuration,
            forVotes: 0,
            againstVotes: 0,
            status: GovProposalStatus.Active,
            hasVoted: new mapping(address => bool)
        });

        emit GovernanceProposalSubmitted(govProposalId, msg.sender, _descriptionHash);
    }

    /// @notice Enables token holders to cast their votes on active governance proposals.
    /// @param _govProposalId The ID of the governance proposal.
    /// @param _support True for "for" vote, false for "against" vote.
    function voteOnGovernanceProposal(uint256 _govProposalId, bool _support) external nonReentrant {
        GovernanceProposal storage govProposal = governanceProposals[_govProposalId];
        if (govProposal.voteStartTime == 0) revert GovernanceProposalNotFound(_govProposalId);
        if (govProposal.status != GovProposalStatus.Active) revert GovernanceProposalNotActive(_govProposalId);
        if (block.timestamp < govProposal.voteStartTime) revert VotingPeriodNotStarted(_govProposalId);
        if (block.timestamp > govProposal.voteEndTime) revert VotingPeriodExpired(_govProposalId);
        if (govProposal.hasVoted[msg.sender]) revert AlreadyVoted(_govProposalId, msg.sender);

        uint256 voterPower = governanceToken.balanceOf(msg.sender); // Snapshot balance at time of vote
        if (voterPower == 0) revert("No vote power");

        if (_support) {
            govProposal.forVotes = govProposal.forVotes.add(voterPower);
        } else {
            govProposal.againstVotes = govProposal.againstVotes.add(voterPower);
        }
        govProposal.hasVoted[msg.sender] = true;

        emit VoteCast(_govProposalId, msg.sender, _support, voterPower);

        // Optional: If voting period ends right after this vote, resolve it
        if (block.timestamp >= govProposal.voteEndTime) {
            _resolveGovernanceProposal(_govProposalId);
        }
    }

    /// @notice Resolves a governance proposal after its voting period has ended.
    ///         Can be called by anyone. This is an internal helper.
    /// @param _govProposalId The ID of the governance proposal.
    function _resolveGovernanceProposal(uint256 _govProposalId) internal {
        GovernanceProposal storage govProposal = governanceProposals[_govProposalId];
        if (govProposal.status != GovProposalStatus.Active) revert GovernanceProposalNotActive(_govProposalId);
        if (block.timestamp < govProposal.voteEndTime) revert VotingPeriodNotStarted(_govProposalId); // Reusing error here

        if (govProposal.forVotes > govProposal.againstVotes) {
            govProposal.status = GovProposalStatus.Passed;
            emit GovernanceProposalPassed(_govProposalId);
        } else {
            govProposal.status = GovProposalStatus.Failed;
        }
    }
    
    /// @notice Executes a passed governance proposal. Callable by governance committee.
    /// @param _govProposalId The ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _govProposalId) external onlyGovernance nonReentrant {
        GovernanceProposal storage govProposal = governanceProposals[_govProposalId];
        if (govProposal.voteStartTime == 0) revert GovernanceProposalNotFound(_govProposalId);
        if (govProposal.status != GovProposalStatus.Passed) revert("Governance proposal not passed.");
        if (govProposal.target == address(0)) revert("Target address not set for execution.");

        (bool success,) = govProposal.target.call(govProposal.calldata);
        if (!success) revert("Governance proposal execution failed.");

        govProposal.status = GovProposalStatus.Executed;
        emit GovernanceProposalExecuted(_govProposalId);
    }


    /// @notice Governance function to formally approve a research proposal after sufficient AI evaluation and community review.
    ///         Requires the AI evaluation score to meet the minimum threshold.
    /// @param _proposalId The ID of the research proposal to approve.
    function approveResearchProposal(uint256 _proposalId) external onlyGovernance {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.AwaitingGovApproval) revert("Proposal not awaiting governance approval.");
        if (proposal.aiEvaluationScore < minAIEvaluationScore) revert NotYetEvaluated(_proposalId); // Reusing error for low score

        // A full DAO would have a governance vote for research proposals here,
        // but for this contract, `onlyGovernance` implies the committee's decision.

        proposal.status = ProposalStatus.Approved;
        proposal.approvalTimestamp = block.timestamp;
        emit ResearchProposalApproved(_proposalId, msg.sender);
    }

    /// @notice Transfers approved funds (native currency) from the treasury to an approved proposal's internal escrow.
    ///         Only callable by governance. The `msg.value` sent with this transaction *is* the total funding for the proposal.
    /// @param _proposalId The ID of the proposal to fund.
    function fundResearchProposal(uint256 _proposalId) external payable onlyGovernance nonReentrant {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.Approved) revert ProposalNotApproved(_proposalId);
        if (msg.value < proposal.totalFundingRequested) revert InsufficientBalance(); // Requires full funding to be sent

        // The funds are now part of the contract's total balance, earmarked conceptually for this proposal.
        proposal.status = ProposalStatus.Active;
        // No explicit transfer happens here, `msg.value` simply increases the contract's balance.
        // The funds will be disbursed in milestones from this contract's balance.

        emit ResearchProposalFunded(_proposalId, msg.value);
    }

    /// @notice Releases funds for a successfully completed and AI-verified milestone.
    ///         Callable by the project proposer or governance.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone to release funds for.
    function releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex) external nonReentrant {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.Active && proposal.status != ProposalStatus.Completed) {
            revert("Proposal is not active.");
        }
        if (_milestoneIndex >= proposal.milestones.length) revert InvalidMilestone(_proposalId, _milestoneIndex);
        if (proposal.milestones[_milestoneIndex].paid) revert MilestoneAlreadyPaid(_proposalId, _milestoneIndex);
        if (!proposal.milestones[_milestoneIndex].progressApproved) revert("Milestone not yet approved by AI.");

        // Allow proposer or governance to trigger release
        if (msg.sender != proposal.proposer && msg.sender != governanceCommittee) revert Unauthorized();

        uint256 amountToRelease = proposal.milestones[_milestoneIndex].amount;
        if (address(this).balance < amountToRelease) revert NoFundsForMilestone();

        (bool success, ) = payable(proposal.proposer).call{value: amountToRelease}("");
        if (!success) revert("Milestone fund transfer failed.");

        proposal.milestones[_milestoneIndex].paid = true;
        proposal.fundingDistributed = proposal.fundingDistributed.add(amountToRelease);

        // Check if all milestones are paid to update proposal status
        bool allMilestonesPaid = true;
        for (uint256 i = 0; i < proposal.milestones.length; i++) {
            if (!proposal.milestones[i].paid) {
                allMilestonesPaid = false;
                break;
            }
        }
        if (allMilestonesPaid) {
            proposal.status = ProposalStatus.Completed;
        }

        emit MilestoneFundsReleased(_proposalId, _milestoneIndex, amountToRelease);
    }

    /// @notice Penalizes a failed or fraudulent proposal by seizing its deposited collateral.
    ///         Only callable by governance. The seized collateral remains in the contract's treasury.
    /// @param _proposalId The ID of the proposal whose collateral to slash.
    function slashProposalCollateral(uint256 _proposalId) external onlyGovernance nonReentrant {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status == ProposalStatus.Completed || proposal.status == ProposalStatus.Slashed) {
            revert("Cannot slash collateral for a completed or already slashed proposal.");
        }

        uint256 collateral = proposal.collateralDeposited;
        proposal.collateralDeposited = 0; // Collateral is seized by the contract
        proposal.status = ProposalStatus.Slashed; // Mark as slashed
        // The funds remain in the contract's general treasury.

        emit ProposalCollateralSlashed(_proposalId, collateral);
    }

    /// @notice Distributes final rewards to the project team upon full, successful completion and verification.
    ///         This function is a placeholder for additional bonuses beyond milestone payments.
    /// @param _proposalId The ID of the completed proposal.
    function disburseFinalProjectRewards(uint256 _proposalId) external onlyGovernance nonReentrant {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.Completed) revert("Proposal is not completed.");

        // In a real system, this could involve calculation of bonus rewards
        // based on over-performance, specific contract revenue, or a dedicated reward pool.
        // For this example, we'll simply emit an event to signify the completion and potential for additional off-chain recognition.
        // If a separate reward pool (e.g., in a reward token) existed, the transfer logic would be here.
        // Example: rewardToken.transfer(proposal.proposer, bonusAmount);

        emit FinalProjectRewardsDisbursed(_proposalId, 0); // Amount 0 indicates this is for symbolic completion/off-chain rewards
    }

    // --- V. Reputation & Rewards ---

    /// @notice Mints a non-transferable Soulbound Token (SBT) as an achievement badge for key contributors to successful projects.
    ///         Only callable by governance.
    /// @param _contributor The address of the contributor to award the SBT to.
    /// @param _proposalId The ID of the project the contributor helped complete.
    /// @param _tokenURI IPFS hash for the metadata of the SBT.
    function mintContributorReputationNFT(address _contributor, uint256 _proposalId, string memory _tokenURI) external onlyGovernance {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.Completed) revert("SBT can only be minted for completed projects.");
        if (_contributor == address(0) || bytes(_tokenURI).length == 0) revert InvalidSBTParameters();

        // Generate a unique tokenId based on contributor and proposal for uniqueness
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_contributor, _proposalId)));
        
        // Prevent minting the same SBT twice for the same contributor+proposal
        if (contributorSBT.exists(tokenId)) revert("SBT already minted for this contributor and proposal.");

        contributorSBT.mint(_contributor, tokenId, _tokenURI);
        emit ContributorReputationMinted(_proposalId, _contributor, tokenId);
    }

    /// @notice Increases an AI agent's reputation score for exceptional, verified performance.
    ///         Only callable by governance.
    /// @param _agentAddress The address of the AI agent.
    /// @param _boostAmount The amount to increase the reputation score by.
    function awardAIAgentBoost(address _agentAddress, uint256 _boostAmount) external onlyGovernance {
        if (!aiAgents[_agentAddress].registered) revert AIAgentNotFound(_agentAddress);
        if (_boostAmount == 0) revert("Boost amount must be greater than zero.");

        // Safe addition for int256 needs explicit handling or a check if it might overflow
        // For simplicity, we assume boostAmount won't cause overflow given practical limits.
        aiAgents[_agentAddress].reputationScore += int256(_boostAmount);
        aiAgents[_agentAddress].lastActivity = block.timestamp;
        emit AIAgentReputationUpdated(_agentAddress, aiAgents[_agentAddress].reputationScore, "Boost awarded by governance");
    }

    /// @notice Governance function to adjust thresholds for reputation-based access or rewards.
    /// @param _minAIReviewRep New minimum reputation for an AI agent to perform reviews.
    /// @param _minGovFeedbackRep New minimum human reputation (e.g., based on activity or SBTs) to provide governance feedback on AI agents.
    function updateReputationThresholds(uint256 _minAIReviewRep, uint256 _minGovFeedbackRep) external onlyGovernance {
        minAIAgentReputationForReview = _minAIReviewRep;
        minHumanReputationForGovFeedback = _minGovFeedbackRep; // This would link to a more complex human reputation system
        emit ReputationThresholdsUpdated(_minAIReviewRep, _minGovFeedbackRep);
    }

    // --- VI. Knowledge & Utility ---

    /// @notice Records the IPFS hash and metadata of a successfully completed and validated research outcome or discovery.
    ///         Only callable by governance for a completed proposal.
    /// @param _proposalId The ID of the proposal whose outcome is being registered.
    /// @param _outcomeIpfsHash IPFS hash for the final research outcome document.
    /// @param _outcomeMetadataHash IPFS hash for metadata about the outcome (e.g., summary, tags).
    function registerSuccessfulOutcome(uint256 _proposalId, string memory _outcomeIpfsHash, string memory _outcomeMetadataHash) external onlyGovernance {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.Completed) revert("Outcome can only be registered for completed proposals.");
        if (bytes(_outcomeIpfsHash).length == 0 || bytes(_outcomeMetadataHash).length == 0) revert("Outcome hashes cannot be empty.");

        proposal.outcomeIpfsHash = _outcomeIpfsHash;
        proposal.outcomeMetadataHash = _outcomeMetadataHash;
        emit OutcomeRegistered(_proposalId, _outcomeIpfsHash, _outcomeMetadataHash);
    }

    /// @notice Retrieves the stored metadata for a registered outcome.
    /// @param _proposalId The ID of the proposal.
    /// @return outcomeIpfsHash IPFS hash of the final research outcome.
    /// @return outcomeMetadataHash IPFS hash of the outcome's metadata.
    function retrieveOutcomeMetadata(uint256 _proposalId) external view returns (string memory outcomeIpfsHash, string memory outcomeMetadataHash) {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.status != ProposalStatus.Completed) revert("Outcome not registered for this proposal yet.");
        if (bytes(proposal.outcomeIpfsHash).length == 0) revert("Outcome IPFS hash not set.");


        return (proposal.outcomeIpfsHash, proposal.outcomeMetadataHash);
    }

    /// @notice Returns the current balance of the contract's treasury (in native currency).
    /// @return The contract's native currency balance.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Allows governance to withdraw surplus native currency from the contract's treasury to a designated address.
    ///         This should be used carefully, e.g., for operating costs or distributing profits.
    /// @param _recipient The address to send the funds to.
    /// @param _amount The amount of native currency to withdraw.
    function withdrawExcessFunds(address _recipient, uint256 _amount) external onlyGovernance nonReentrant {
        if (_recipient == address(0)) revert("Invalid recipient address.");
        if (_amount == 0) revert("Withdrawal amount must be greater than zero.");
        if (address(this).balance < _amount) revert InsufficientBalance();

        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) revert("Failed to withdraw funds.");
        emit FundsWithdrawn(_recipient, _amount);
    }

    // Fallback function to receive native token
    receive() external payable {}
}
```