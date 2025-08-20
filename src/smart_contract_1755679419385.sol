Here's a Solidity smart contract named "CognitoNet," designed with advanced, creative, and trending concepts. It aims to create a decentralized AI-driven research and innovation network.

**Key Advanced Concepts & Uniqueness:**

1.  **AI-Driven Evaluation (via Oracle):** Leverages an external AI oracle for nuanced evaluation of research proposals, milestone completions, and even the quality/impact of research outputs. This allows for complex, off-chain computations that inform on-chain decisions, significantly beyond simple peer voting.
2.  **Dynamic Reputation System (SBT-like):** Implements a non-transferable reputation score (akin to a Soulbound Token's non-transferability) that dynamically adjusts based on verifiable research contributions and AI evaluations, not just staking or generic activity. Reputation can even become negative for poor performance.
3.  **Reputation as "Redeemable Governance Power":** Introduces a unique governance mechanic where researchers can *burn* a portion of their reputation to cast "weighted votes" on governance proposals, augmenting their standard one-person-one-vote power. This encourages active participation and commitment.
4.  **Verifiable Research Output & IP Management:** Provides a mechanism to register cryptographic hashes of research outputs (e.g., scientific papers, datasets) on-chain, creating immutable proofs of existence and timestamping for intellectual property. Includes a peer-attestation system for credibility.
5.  **Epoch-Based Dynamics:** All core activities (funding, evaluation cycles, reward distribution) are structured around distinct epochs, providing a predictable and rhythmic flow to the network's operations.
6.  **Milestone-Based Funding with AI Gates:** Project funding is released milestone by milestone, each requiring successful AI evaluation of submitted proofs before the next tranche of funds is unlocked.

This contract intentionally combines these elements in a novel way to avoid direct duplication of existing open-source projects, while individual components (like ERC-20 interaction, basic voting) are standard.

---

### **Contract: CognitoNet**

**Description:**
CognitoNet is a decentralized autonomous organization (DAO) designed to accelerate scientific and technological innovation. It provides an on-chain framework for researchers to propose, fund, and manage research projects. The network integrates with an off-chain AI Oracle to facilitate objective evaluation of research proposals and milestone completions, dynamically adjusting researcher reputations based on their contributions and the impact of their work. It also enables the registration of verifiable research outputs, fostering a transparent and trustworthy knowledge economy.

---

**Outline:**

*   **I. Core Components:** Foundation of the network, including ERC-20 token integration and epoch management.
*   **II. Project Management & Funding:** Lifecycle of research projects from proposal to funding and milestone completion.
*   **III. Reputation & Contribution:** Dynamic, AI-influenced reputation system for researchers.
*   **IV. AI Oracle & Evaluation:** Secure interaction with an off-chain AI oracle for advanced assessments.
*   **V. Governance & Network Dynamics:** Decentralized decision-making and adaptive system parameters.
*   **VI. Data & IP Management:** On-chain registration of research outputs and intellectual property hashes.
*   **VII. Incentives & Rewards:** Mechanisms for distributing rewards to active contributors.

---

**Function Summary (27 functions):**

**I. Core Components**
1.  `constructor(address _tokenAddress, address _initialOracle, uint256 _epochDurationSeconds)`: Initializes the contract with an ERC-20 token for funding, an initial AI Oracle address, and the duration of an epoch.
2.  `setOracleAddress(address _newOracle)`: Admin function to update the AI Oracle's address.
3.  `setEpochDuration(uint256 _newDurationSeconds)`: Admin function to set the duration of an epoch in seconds.
4.  `getCurrentEpoch()`: Returns the current epoch number based on the contract's start time and epoch duration.

**II. Project Management & Funding**
5.  `proposeResearchProject(string memory _title, string memory _descriptionHash, uint256 _fundingRequested, uint256 _milestoneCount, bytes32[] memory _milestoneHashes)`: Allows a registered researcher to propose a new research project, specifying funding needs, milestones, and hashes of milestone descriptions.
6.  `voteOnProjectProposal(uint256 _projectId, bool _approve)`: Allows DAO members to vote on a research project proposal. This function primarily records votes; actual project approval is often AI-influenced or follows a more complex governance process.
7.  `fundProjectMilestone(uint256 _projectId, uint256 _milestoneIndex)`: Releases funds for a specific milestone of an approved and funded project, once the previous milestone is completed and evaluated. Only callable by the project lead.
8.  `submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bytes32 _proofHash)`: Project lead submits cryptographic proof of milestone completion, triggering AI evaluation.
9.  `requestProjectExtension(uint256 _projectId, uint256 _additionalFunding, uint256 _additionalEpochs)`: Project lead can request an extension to project timeline or funding, subject to governance approval.

**III. Reputation & Contribution**
10. `registerResearcherProfile(string memory _name, string memory _contactInfoHash)`: Allows a new user to register as a researcher, creating a unique, non-transferable profile and initializing their reputation.
11. `getResearcherReputation(address _researcher)`: Returns the current reputation score for a specific researcher.
12. `updateResearcherReputation(address _researcher, int256 _reputationDelta)`: Internal function called by the AI Oracle after evaluation to adjust a researcher's reputation. Not directly callable by external users.
13. `stakeForContributionCommitment(uint256 _projectId, uint256 _amount)`: Allows a researcher to stake tokens on a project they are committed to, potentially boosting their reputation gain for successful contributions.
14. `slashStakedCommitment(uint256 _projectId, address _researcher, uint256 _amount)`: Internal function to slash a researcher's staked commitment due to failure to meet obligations, typically triggered by evaluation.

**IV. AI Oracle & Evaluation**
15. `_requestAIEvaluation(uint256 _evalType, uint256 _entityId, bytes32 _dataHash)`: Internal function to request an AI evaluation for a project, milestone, or output. (Emits event for off-chain listener).
16. `receiveAIEvaluationResult(bytes32 _hash, bytes memory _signature, uint256 _evalType, uint256 _entityId, int256 _score, string memory _feedbackHash)`: Callable only by the registered AI Oracle. Receives a signed AI evaluation result and applies it to the corresponding entity (project/milestone/researcher). Includes signature for verifiability (conceptual in this simplified version).
17. `setAIDecisionThresholds(uint256 _proposalApprovalThreshold, uint256 _milestonePassThreshold)`: Admin function to set AI score thresholds required for automatic approval of proposals or milestone passes.

**V. Governance & Network Dynamics**
18. `submitGovernanceProposal(string memory _descriptionHash, address _targetContract, bytes memory _callData)`: Allows any researcher with sufficient reputation to submit a governance proposal for system changes.
19. `voteOnGovernanceProposal(uint256 _proposalId, bool _approve)`: Allows reputation-holding researchers to cast their primary vote on governance proposals.
20. `executeGovernanceProposal(uint256 _proposalId)`: Executes an approved governance proposal after its voting period has ended and criteria are met (e.g., majority votes).
21. `distributeEpochRewards(uint256 _epoch)`: Admin function to trigger the distribution of accumulated rewards to researchers based on their contributions and reputation during the past epoch.
22. `redeemReputationAsGovernancePower(uint256 _proposalId, uint256 _reputationAmount, bool _voteForYes)`: Allows a researcher to burn a portion of their reputation to contribute a weighted vote to a specific governance proposal, independent of their single primary vote.

**VI. Data & IP Management**
23. `registerVerifiableOutputHash(uint256 _projectId, bytes32 _outputHash, string memory _descriptionHash)`: Allows project leads to register a cryptographic hash of their research output (e.g., scientific paper, dataset) on-chain for proof of existence and timestamping.
24. `attestToOutputTruthfulness(uint256 _outputId, bool _isTrue)`: Allows other researchers to attest to the truthfulness or validity of a registered output hash, contributing to their own reputation and the output's credibility score.

**VII. Incentives & Rewards**
25. `claimEpochRewards()`: Allows researchers to claim their accumulated rewards from the current or previous epochs.
26. `setRewardDistributionFormula(bytes32 _formulaHash)`: Admin function to update the hash of the off-chain formula used to calculate reward distribution, subject to governance.
27. `getResearcherActiveContributions(address _researcher)`: Returns the number of active projects a researcher is currently involved in. (Note: For large-scale applications, this specific function might be optimized with off-chain indexing due to gas costs of on-chain iteration).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString, needed for events/debugging

// Note: This contract leverages an external AI Oracle for advanced evaluation.
// The AI Oracle is an off-chain service that performs complex computations
// (e.g., assessing research quality, impact, novelty) and provides a signed,
// verifiable result back to the blockchain. The contract verifies the oracle's
// signature and acts upon the received data. This pattern avoids complex
// on-chain AI computation while maintaining trust and verifiability.

// Outline:
// I. Core Components: Foundation of the network, including ERC-20 token integration and epoch management.
// II. Project Management & Funding: Lifecycle of research projects from proposal to funding and milestone completion.
// III. Reputation & Contribution: Dynamic, AI-influenced reputation system for researchers.
// IV. AI Oracle & Evaluation: Secure interaction with an off-chain AI oracle for advanced assessments.
// V. Governance & Network Dynamics: Decentralized decision-making and adaptive system parameters.
// VI. Data & IP Management: On-chain registration of research outputs and intellectual property hashes.
// VII. Incentives & Rewards: Mechanisms for distributing rewards to active contributors.

// Function Summary (27 functions):

// I. Core Components
// 1. constructor(address _tokenAddress, address _initialOracle, uint256 _epochDurationSeconds): Initializes the contract with an ERC-20 token for funding, an initial AI Oracle address, and the duration of an epoch.
// 2. setOracleAddress(address _newOracle): Admin function to update the AI Oracle's address.
// 3. setEpochDuration(uint256 _newDurationSeconds): Admin function to set the duration of an epoch in seconds.
// 4. getCurrentEpoch(): Returns the current epoch number based on the contract's start time and epoch duration.

// II. Project Management & Funding
// 5. proposeResearchProject(string memory _title, string memory _descriptionHash, uint256 _fundingRequested, uint256 _milestoneCount, bytes32[] memory _milestoneHashes): Allows a registered researcher to propose a new research project, specifying funding needs, milestones, and hashes of milestone descriptions.
// 6. voteOnProjectProposal(uint256 _projectId, bool _approve): Allows DAO members to vote on a research project proposal.
// 7. fundProjectMilestone(uint256 _projectId, uint256 _milestoneIndex): Releases funds for a specific milestone of an approved and funded project, once the previous milestone is completed and evaluated. Only callable by the project lead.
// 8. submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bytes32 _proofHash): Project lead submits cryptographic proof of milestone completion, triggering AI evaluation.
// 9. requestProjectExtension(uint256 _projectId, uint256 _additionalFunding, uint256 _additionalEpochs): Project lead can request an extension to project timeline or funding, subject to governance approval.

// III. Reputation & Contribution
// 10. registerResearcherProfile(string memory _name, string memory _contactInfoHash): Allows a new user to register as a researcher, creating a unique, non-transferable profile and initializing their reputation.
// 11. getResearcherReputation(address _researcher): Returns the current reputation score for a specific researcher.
// 12. updateResearcherReputation(address _researcher, int256 _reputationDelta): Internal function called by the AI Oracle after evaluation to adjust a researcher's reputation. Not directly callable by external users.
// 13. stakeForContributionCommitment(uint256 _projectId, uint256 _amount): Allows a researcher to stake tokens on a project they are committed to, potentially boosting their reputation gain for successful contributions.
// 14. slashStakedCommitment(uint256 _projectId, address _researcher, uint256 _amount): Internal function to slash a researcher's staked commitment due to failure to meet obligations, triggered by evaluation.

// IV. AI Oracle & Evaluation
// 15. _requestAIEvaluation(uint256 _evalType, uint256 _entityId, bytes32 _dataHash): Internal function to request an AI evaluation from the oracle.
// 16. receiveAIEvaluationResult(bytes32 _hash, bytes memory _signature, uint256 _evalType, uint256 _entityId, int256 _score, string memory _feedbackHash): Callable only by the registered AI Oracle. Receives a signed AI evaluation result and applies it to the corresponding entity (project/milestone/researcher).
// 17. setAIDecisionThresholds(uint256 _proposalApprovalThreshold, uint256 _milestonePassThreshold): Admin function to set AI score thresholds required for automatic approval of proposals or milestone passes.

// V. Governance & Network Dynamics
// 18. submitGovernanceProposal(string memory _descriptionHash, address _targetContract, bytes memory _callData): Allows any researcher with sufficient reputation to submit a governance proposal for system changes.
// 19. voteOnGovernanceProposal(uint256 _proposalId, bool _approve): Allows reputation-holding researchers to vote on governance proposals.
// 20. executeGovernanceProposal(uint256 _proposalId): Executes an approved governance proposal. Only callable by the admin or an internal function after a successful vote.
// 21. distributeEpochRewards(uint256 _epoch): Admin function to trigger the distribution of accumulated rewards to researchers based on their contributions and reputation during the past epoch.
// 22. redeemReputationAsGovernancePower(uint256 _proposalId, uint256 _reputationAmount, bool _voteForYes): Allows a researcher to temporarily convert a portion of their current reputation into voting power for a specific governance proposal.

// VI. Data & IP Management
// 23. registerVerifiableOutputHash(uint256 _projectId, bytes32 _outputHash, string memory _descriptionHash): Allows project leads to register a cryptographic hash of their research output (e.g., scientific paper, dataset) on-chain for proof of existence and timestamping.
// 24. attestToOutputTruthfulness(uint256 _outputId, bool _isTrue): Allows other researchers to attest to the truthfulness or validity of a registered output hash, contributing to their own reputation and the output's credibility score.

// VII. Incentives & Rewards
// 25. claimEpochRewards(): Allows researchers to claim their accumulated rewards from the current or previous epochs.
// 26. setRewardDistributionFormula(bytes32 _formulaHash): Admin function to update the hash of the off-chain formula used to calculate reward distribution, subject to governance.
// 27. getResearcherActiveContributions(address _researcher): Returns the number of active projects a researcher is currently involved in and contributing to.

contract CognitoNet is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for int256;
    using Strings for uint256; // For converting uint256 to string for event descriptions

    // --- State Variables ---
    IERC20 public fundingToken; // The ERC-20 token used for funding projects and rewards
    address public aiOracle; // Address of the trusted AI Oracle
    uint256 public epochDurationSeconds; // Duration of an epoch in seconds
    uint256 public constant INITIAL_REPUTATION = 100; // Initial reputation for new researchers
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 500; // Minimum reputation to submit governance/research proposals

    // Epoch tracking
    uint256 public contractLaunchTime;

    // AI Decision Thresholds
    uint256 public aiProposalApprovalThreshold = 70; // AI score % required for automatic project approval
    uint256 public aiMilestonePassThreshold = 60; // AI score % required for milestone pass

    // --- Structs & Enums ---

    enum ProjectStatus { Proposed, Approved, FundingActive, Completed, Rejected, Extended, Suspended }
    enum MilestoneStatus { Pending, SubmittedForEvaluation, Passed, Failed }
    enum EvalEntityType { Project, Milestone, ResearchOutput, ResearcherProfile }
    enum GovernanceProposalStatus { Pending, Approved, Rejected, Executed }

    struct ResearcherProfile {
        string name;
        string contactInfoHash; // IPFS CID or similar for contact details
        int256 reputation; // Can be negative for severely bad actors
        uint256 lastActivityEpoch; // Epoch of last significant activity/contribution
        mapping(uint256 => uint256) stakedCommitments; // projectId => amount
    }

    struct Project {
        address lead;
        string title;
        string descriptionHash; // IPFS CID for detailed description
        uint256 fundingRequested;
        uint256 fundingReceived;
        ProjectStatus status;
        uint256 proposalEpoch;
        uint256 approvalEpoch;
        uint256 completionEpoch;
        int256 aiScore; // Latest AI evaluation score for the overall project
        uint256 milestoneCount;
        mapping(uint256 => Milestone) milestones;
        mapping(address => bool) hasVotedOnProposal; // For project proposals
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct Milestone {
        uint256 index;
        bytes32 contentHash; // Hash of milestone description/requirements
        MilestoneStatus status;
        uint256 fundingAmount;
        bytes32 proofHash; // Hash of submitted proof of completion
        uint256 evaluationEpoch;
        int256 aiScore; // Latest AI evaluation score for this milestone
        address[] contributors; // Researchers who actively contributed to this milestone
    }

    struct GovernanceProposal {
        address proposer;
        string descriptionHash; // IPFS CID for proposal details
        address targetContract; // Contract to call if proposal is executable
        bytes callData; // Encoded function call
        GovernanceProposalStatus status;
        uint256 submissionEpoch;
        uint256 expirationEpoch;
        uint256 yesVotes; // Count of 1-vote-per-researcher
        uint256 noVotes;
        uint256 weightedYesVotes; // Total reputation burned for 'yes'
        uint256 weightedNoVotes; // Total reputation burned for 'no'
        mapping(address => bool) hasVoted; // For 1-vote-per-researcher
    }

    struct VerifiableOutput {
        uint256 projectId;
        address creator;
        bytes32 outputHash; // Hash of the research output (e.g., paper, dataset)
        string descriptionHash; // IPFS CID for metadata
        uint256 registrationEpoch;
        int256 credibilityScore; // Aggregated score from attestations and AI
        mapping(address => bool) hasAttested; // User => Attestation status (true if attested)
        uint256 trueAttestations;
        uint256 falseAttestations;
    }

    // --- Mappings ---
    mapping(address => ResearcherProfile) public researcherProfiles;
    mapping(address => bool) public isResearcher; // Quick lookup for registered researchers
    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public nextGovernanceProposalId;
    mapping(uint256 => VerifiableOutput) public verifiableOutputs;
    uint256 public nextOutputId;
    mapping(address => uint256) public claimableRewards; // Rewards accumulated for researchers

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracle);
    event EpochDurationUpdated(uint256 newDuration);
    event ResearchProjectProposed(uint256 indexed projectId, address indexed proposer, uint256 fundingRequested, uint256 milestoneCount);
    event ProjectProposalVoted(uint256 indexed projectId, address indexed voter, bool approved);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, bytes32 proofHash);
    event MilestoneStatusUpdated(uint256 indexed projectId, uint256 indexed milestoneIndex, MilestoneStatus newStatus);
    event FundsReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ResearcherRegistered(address indexed researcher, string name);
    event ResearcherReputationUpdated(address indexed researcher, int256 newReputation, int256 reputationDelta);
    event StakedForContribution(address indexed researcher, uint256 indexed projectId, uint256 amount);
    event StakedCommitmentSlashed(address indexed researcher, uint256 indexed projectId, uint256 amount);
    event AIEvaluationRequested(uint256 indexed evalType, uint256 indexed entityId, bytes32 dataHash);
    event AIEvaluationReceived(uint256 indexed evalType, uint256 indexed entityId, int256 score, string feedbackHash);
    event AIDecisionThresholdsUpdated(uint256 proposalApproval, uint256 milestonePass);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string descriptionHash);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ReputationRedeemedForPower(address indexed researcher, uint256 indexed proposalId, uint256 amount);
    event RewardsDistributed(uint256 indexed epoch, uint256 totalAmount);
    event RewardsClaimed(address indexed researcher, uint256 amount);
    event VerifiableOutputRegistered(uint256 indexed outputId, uint256 indexed projectId, address indexed creator, bytes32 outputHash);
    event OutputAttested(uint256 indexed outputId, address indexed attester, bool isTrue);
    event RewardDistributionFormulaUpdated(bytes32 formulaHash);
    event ProjectExtensionRequested(uint256 indexed projectId, uint256 additionalFunding, uint256 additionalEpochs);

    // --- Modifiers ---
    modifier onlyResearcher() {
        require(isResearcher[msg.sender], "CognitoNet: Caller is not a registered researcher.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == aiOracle, "CognitoNet: Caller is not the AI Oracle.");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].lead == msg.sender, "CognitoNet: Only project lead can call this function.");
        _;
    }

    modifier proposalNotExpired(uint256 _proposalId) {
        require(getCurrentEpoch() <= governanceProposals[_proposalId].expirationEpoch, "CognitoNet: Proposal has expired.");
        _;
    }

    modifier proposalPending(uint256 _proposalId) {
        require(governanceProposals[_proposalId].status == GovernanceProposalStatus.Pending, "CognitoNet: Proposal is not pending.");
        _;
    }

    // --- Constructor ---
    constructor(address _tokenAddress, address _initialOracle, uint256 _epochDurationSeconds) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "CognitoNet: Token address cannot be zero.");
        require(_initialOracle != address(0), "CognitoNet: Initial Oracle address cannot be zero.");
        require(_epochDurationSeconds > 0, "CognitoNet: Epoch duration must be greater than zero.");

        fundingToken = IERC20(_tokenAddress);
        aiOracle = _initialOracle;
        epochDurationSeconds = _epochDurationSeconds;
        contractLaunchTime = block.timestamp;
        nextProjectId = 1;
        nextGovernanceProposalId = 1;
        nextOutputId = 1;
    }

    // --- I. Core Components ---

    /**
     * @dev Sets the address of the trusted AI Oracle. Only callable by the contract owner.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "CognitoNet: New Oracle address cannot be zero.");
        aiOracle = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @dev Sets the duration of an epoch in seconds. Only callable by the contract owner.
     * @param _newDurationSeconds The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _newDurationSeconds) public onlyOwner {
        require(_newDurationSeconds > 0, "CognitoNet: Epoch duration must be positive.");
        epochDurationSeconds = _newDurationSeconds;
        emit EpochDurationUpdated(_newDurationSeconds);
    }

    /**
     * @dev Returns the current epoch number based on contract launch time and epoch duration.
     * @return The current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        if (epochDurationSeconds == 0) return 0; // Prevent division by zero if not initialized
        return (block.timestamp.sub(contractLaunchTime)).div(epochDurationSeconds);
    }

    // --- II. Project Management & Funding ---

    /**
     * @dev Allows a registered researcher to propose a new research project.
     * Requires minimum reputation.
     * @param _title The title of the research project.
     * @param _descriptionHash IPFS CID or hash of the detailed project description.
     * @param _fundingRequested Total funding requested for the project.
     * @param _milestoneCount The number of milestones in the project.
     * @param _milestoneHashes Array of IPFS CIDs or hashes for each milestone's description/requirements.
     */
    function proposeResearchProject(
        string memory _title,
        string memory _descriptionHash,
        uint256 _fundingRequested,
        uint256 _milestoneCount,
        bytes32[] memory _milestoneHashes
    ) public onlyResearcher nonReentrant returns (uint256) {
        require(researcherProfiles[msg.sender].reputation >= int256(MIN_REPUTATION_FOR_PROPOSAL), "CognitoNet: Insufficient reputation to propose projects.");
        require(_milestoneCount > 0 && _milestoneCount == _milestoneHashes.length, "CognitoNet: Milestone count must match hashes array length and be greater than zero.");
        require(_fundingRequested > 0, "CognitoNet: Funding requested must be greater than zero.");

        uint256 projectId = nextProjectId++;
        Project storage newProject = projects[projectId];
        newProject.lead = msg.sender;
        newProject.title = _title;
        newProject.descriptionHash = _descriptionHash;
        newProject.fundingRequested = _fundingRequested;
        newProject.status = ProjectStatus.Proposed;
        newProject.proposalEpoch = getCurrentEpoch();
        newProject.milestoneCount = _milestoneCount;

        uint256 fundingPerMilestone = _fundingRequested.div(_milestoneCount);
        for (uint256 i = 0; i < _milestoneCount; i++) {
            newProject.milestones[i] = Milestone({
                index: i,
                contentHash: _milestoneHashes[i],
                status: MilestoneStatus.Pending,
                fundingAmount: fundingPerMilestone,
                proofHash: bytes32(0),
                evaluationEpoch: 0,
                aiScore: 0,
                contributors: new address[](0) // Initialize empty
            });
        }
        
        // After proposing, request AI evaluation for the project itself to determine if it gets approved.
        _requestAIEvaluation(uint256(EvalEntityType.Project), projectId, keccak256(abi.encodePacked(_title, _descriptionHash)));

        emit ResearchProjectProposed(projectId, msg.sender, _fundingRequested, _milestoneCount);
        return projectId;
    }

    /**
     * @dev Allows registered researchers (DAO members) to vote on a research project proposal.
     * This function's primary role is to record community sentiment. The final project approval
     * decision may also be influenced by AI evaluation (as handled in `receiveAIEvaluationResult`).
     * @param _projectId The ID of the project proposal to vote on.
     * @param _approve True for 'yes' vote, false for 'no' vote.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _approve) public onlyResearcher {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "CognitoNet: Project is not in proposed status.");
        require(!project.hasVotedOnProposal[msg.sender], "CognitoNet: Already voted on this proposal.");
        
        project.hasVotedOnProposal[msg.sender] = true;
        if (_approve) {
            project.yesVotes++;
        } else {
            project.noVotes++;
        }
        
        emit ProjectProposalVoted(_projectId, msg.sender, _approve);
    }

    /**
     * @dev Releases funds for a specific milestone of an approved and funded project.
     * Only callable by the project lead after previous milestones are completed and evaluated as 'Passed'.
     * The very first milestone doesn't require a previous milestone check.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to fund.
     */
    function fundProjectMilestone(uint256 _projectId, uint256 _milestoneIndex) public onlyProjectLead(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.FundingActive || project.status == ProjectStatus.Extended, "CognitoNet: Project is not active for funding.");
        require(_milestoneIndex < project.milestoneCount, "CognitoNet: Invalid milestone index.");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Passed, "CognitoNet: Milestone must be passed evaluation to release funds.");
        
        if (_milestoneIndex > 0) {
            Milestone storage prevMilestone = project.milestones[_milestoneIndex.sub(1)];
            require(prevMilestone.status == MilestoneStatus.Passed, "CognitoNet: Previous milestone must be passed.");
        }

        // Transfer funds from contract treasury to project lead
        require(fundingToken.transfer(msg.sender, milestone.fundingAmount), "CognitoNet: Token transfer failed.");
        project.fundingReceived = project.fundingReceived.add(milestone.fundingAmount);

        emit FundsReleased(_projectId, _milestoneIndex, milestone.fundingAmount);

        // If all milestones funded, mark project as completed
        if (project.fundingReceived >= project.fundingRequested) {
            project.status = ProjectStatus.Completed;
            project.completionEpoch = getCurrentEpoch();
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Completed);
        }
    }

    /**
     * @dev Project lead submits proof of milestone completion, triggering AI evaluation.
     * The `_proofHash` could be an IPFS CID pointing to detailed proofs (e.g., code, data, report).
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone completed.
     * @param _proofHash The cryptographic hash of the proof of completion.
     */
    function submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bytes32 _proofHash) public onlyProjectLead(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.FundingActive || project.status == ProjectStatus.Extended, "CognitoNet: Project is not active.");
        require(_milestoneIndex < project.milestoneCount, "CognitoNet: Invalid milestone index.");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Pending, "CognitoNet: Milestone not in pending status for submission.");
        require(_proofHash != bytes32(0), "CognitoNet: Proof hash cannot be zero.");

        milestone.proofHash = _proofHash;
        milestone.status = MilestoneStatus.SubmittedForEvaluation;
        milestone.evaluationEpoch = getCurrentEpoch();

        // Request AI evaluation for this milestone
        _requestAIEvaluation(uint256(EvalEntityType.Milestone), (_projectId * 1000) + _milestoneIndex, _proofHash);

        emit MilestoneSubmitted(_projectId, _milestoneIndex, _proofHash);
    }

    /**
     * @dev Allows project lead to request an extension for project timeline or additional funding.
     * This triggers a governance proposal that needs to be voted on by the DAO.
     * @param _projectId The ID of the project requesting extension.
     * @param _additionalFunding Amount of additional funding requested.
     * @param _additionalEpochs Number of additional epochs requested for completion.
     */
    function requestProjectExtension(uint256 _projectId, uint256 _additionalFunding, uint256 _additionalEpochs) public onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.FundingActive || project.status == ProjectStatus.Suspended, "CognitoNet: Project must be active or suspended to request extension.");
        require(_additionalFunding > 0 || _additionalEpochs > 0, "CognitoNet: Must request either additional funding or epochs.");

        // Encode the extension details into calldata for a conceptual internal function (e.g., `_applyProjectExtension`).
        // The actual application would occur if the governance proposal passes and is executed.
        bytes memory callData = abi.encodeWithSignature(
            "_applyProjectExtension(uint256,uint256,uint256)",
            _projectId,
            _additionalFunding,
            _additionalEpochs
        );
        
        string memory descriptionString = string(abi.encodePacked("Extension request for project ", _projectId.toString(), ": ", Strings.toString(_additionalFunding), " tokens, ", Strings.toString(_additionalEpochs), " epochs."));
        bytes32 descriptionHash = keccak256(abi.encodePacked(descriptionString));

        // Submit as a governance proposal targeting this contract
        submitGovernanceProposal(Strings.fromBytes32(descriptionHash), address(this), callData);

        emit ProjectExtensionRequested(_projectId, _additionalFunding, _additionalEpochs);
    }

    /**
     * @dev Internal function to apply a project extension if a governance proposal passes.
     * This function is only intended to be called via `executeGovernanceProposal`.
     * @param _projectId The ID of the project.
     * @param _additionalFunding Amount of additional funding approved.
     * @param _additionalEpochs Number of additional epochs approved.
     */
    function _applyProjectExtension(uint256 _projectId, uint256 _additionalFunding, uint256 _additionalEpochs) internal {
        // This function is called via governance. Access control is handled by `executeGovernanceProposal`.
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.FundingActive || project.status == ProjectStatus.Suspended, "CognitoNet: Project not in state to be extended.");

        project.fundingRequested = project.fundingRequested.add(_additionalFunding);
        // Assuming a project has an "end epoch" or similar, it would be extended here.
        // For simplicity, we just mark status as extended.
        project.status = ProjectStatus.Extended; 
        
        // Transfer additional funding to the contract to be available for milestones
        if (_additionalFunding > 0) {
            // In a real scenario, the DAO treasury or a separate fund needs to approve transfer to this contract.
            // For this example, we assume the DAO's main contract would handle the transfer.
            // This function would then just record the *approved* amount.
        }

        emit ProjectStatusUpdated(_projectId, ProjectStatus.Extended);
    }


    // --- III. Reputation & Contribution ---

    /**
     * @dev Allows a new user to register as a researcher.
     * Creates a unique, non-transferable profile and initializes reputation.
     * @param _name The name of the researcher.
     * @param _contactInfoHash IPFS CID or hash for contact information.
     */
    function registerResearcherProfile(string memory _name, string memory _contactInfoHash) public nonReentrant {
        require(!isResearcher[msg.sender], "CognitoNet: Caller is already a registered researcher.");
        require(bytes(_name).length > 0, "CognitoNet: Name cannot be empty.");

        researcherProfiles[msg.sender] = ResearcherProfile({
            name: _name,
            contactInfoHash: _contactInfoHash,
            reputation: int256(INITIAL_REPUTATION),
            lastActivityEpoch: getCurrentEpoch()
        });
        isResearcher[msg.sender] = true;

        emit ResearcherRegistered(msg.sender, _name);
        emit ResearcherReputationUpdated(msg.sender, int256(INITIAL_REPUTATION), int256(INITIAL_REPUTATION));
    }

    /**
     * @dev Returns the current reputation score for a specific researcher.
     * @param _researcher The address of the researcher.
     * @return The reputation score.
     */
    function getResearcherReputation(address _researcher) public view returns (int256) {
        require(isResearcher[_researcher], "CognitoNet: Researcher not registered.");
        return researcherProfiles[_researcher].reputation;
    }

    /**
     * @dev Internal function called by the AI Oracle (via `receiveAIEvaluationResult`)
     * to adjust a researcher's reputation based on their contributions.
     * Not directly callable by external users.
     * @param _researcher The address of the researcher whose reputation is updated.
     * @param _reputationDelta The amount to change reputation by (can be positive or negative).
     */
    function updateResearcherReputation(address _researcher, int256 _reputationDelta) internal {
        require(isResearcher[_researcher], "CognitoNet: Researcher not registered.");
        
        int256 oldReputation = researcherProfiles[_researcher].reputation;
        researcherProfiles[_researcher].reputation = oldReputation.add(_reputationDelta);
        researcherProfiles[_researcher].lastActivityEpoch = getCurrentEpoch();

        emit ResearcherReputationUpdated(_researcher, researcherProfiles[_researcher].reputation, _reputationDelta);
    }

    /**
     * @dev Allows a researcher to stake tokens to commit to a project they are contributing to.
     * This stake could act as a bond and a multiplier for reputation gain on successful contributions.
     * Tokens are transferred to the contract's custody.
     * @param _projectId The ID of the project to commit to.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForContributionCommitment(uint256 _projectId, uint256 _amount) public onlyResearcher nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.FundingActive || project.status == ProjectStatus.Proposed, "CognitoNet: Project not in active or proposed status.");
        require(_amount > 0, "CognitoNet: Stake amount must be greater than zero.");
        
        require(fundingToken.transferFrom(msg.sender, address(this), _amount), "CognitoNet: Token transfer for staking failed.");
        
        researcherProfiles[msg.sender].stakedCommitments[_projectId] = researcherProfiles[msg.sender].stakedCommitments[_projectId].add(_amount);

        emit StakedForContribution(msg.sender, _projectId, _amount);
    }

    /**
     * @dev Internal function to slash a researcher's staked commitment.
     * Triggered by AI/peer evaluation failure or non-compliance. Slashed funds remain in contract treasury.
     * @param _projectId The ID of the project.
     * @param _researcher The researcher whose stake is to be slashed.
     * @param _amount The amount to slash.
     */
    function slashStakedCommitment(uint256 _projectId, address _researcher, uint256 _amount) internal {
        require(isResearcher[_researcher], "CognitoNet: Researcher not registered.");
        require(researcherProfiles[_researcher].stakedCommitments[_projectId] >= _amount, "CognitoNet: Insufficient staked amount to slash.");

        researcherProfiles[_researcher].stakedCommitments[_projectId] = researcherProfiles[_researcher].stakedCommitments[_projectId].sub(_amount);
        // Slashed funds remain in contract treasury, potentially adding to rewards pool.

        emit StakedCommitmentSlashed(_researcher, _projectId, _amount);
    }

    // --- IV. AI Oracle & Evaluation ---

    /**
     * @dev Internal function to request an AI evaluation from the oracle.
     * This function emits an event which is expected to be picked up by an off-chain listener
     * that then interacts with the AI service and calls `receiveAIEvaluationResult`.
     * @param _evalType Type of entity being evaluated (Project, Milestone, Output, Researcher).
     * @param _entityId The ID of the entity being evaluated (projectId, milestone ID (packed), outputId).
     * @param _dataHash A hash pointing to the data for AI evaluation (e.g., IPFS CID of proof).
     */
    function _requestAIEvaluation(uint256 _evalType, uint256 _entityId, bytes32 _dataHash) internal {
        emit AIEvaluationRequested(_evalType, _entityId, _dataHash);
    }

    /**
     * @dev Callable only by the registered AI Oracle. Receives a signed AI evaluation result.
     * This function should ideally verify a signature from the AI Oracle using `ECDSA.recover`
     * to ensure the result's authenticity. For simplicity, only `onlyOracle` is used here.
     * @param _hash The hash of the data that was evaluated (for context/verification).
     * @param _signature The signature from the AI Oracle for the result. (Placeholder; crucial for production).
     * @param _evalType The type of entity evaluated (from EvalEntityType enum).
     * @param _entityId The ID of the entity (projectId, milestoneId, outputId etc.).
     * @param _score The AI's evaluation score (e.g., 0-100).
     * @param _feedbackHash IPFS CID or hash for detailed AI feedback.
     */
    function receiveAIEvaluationResult(
        bytes32 _hash,
        bytes memory _signature, // Placeholder for signature verification (e.g., ECDSA.recover)
        uint256 _evalType,
        uint256 _entityId,
        int256 _score,
        string memory _feedbackHash
    ) public onlyOracle nonReentrant {
        // In a production system, verify the signature:
        // address signer = ECDSA.recover(keccak256(abi.encodePacked(_hash, _evalType, _entityId, _score, keccak256(abi.encodePacked(_feedbackHash)))), _signature);
        // require(signer == aiOracle, "CognitoNet: Invalid oracle signature.");

        emit AIEvaluationReceived(_evalType, _entityId, _score, _feedbackHash);

        if (_evalType == uint256(EvalEntityType.Milestone)) {
            uint256 projectId = _entityId / 1000; // Assuming _entityId = projectId * 1000 + milestoneIndex
            uint256 milestoneIndex = _entityId % 1000;

            Project storage project = projects[projectId];
            require(project.status == ProjectStatus.FundingActive || project.status == ProjectStatus.Extended, "CognitoNet: Project not in active state for milestone evaluation.");
            require(milestoneIndex < project.milestoneCount, "CognitoNet: Invalid milestone index for evaluation result.");

            Milestone storage milestone = project.milestones[milestoneIndex];
            require(milestone.status == MilestoneStatus.SubmittedForEvaluation, "CognitoNet: Milestone not submitted for evaluation.");
            require(milestone.proofHash == _hash, "CognitoNet: Hash mismatch for milestone evaluation."); // Ensure the evaluated hash matches what was submitted

            milestone.aiScore = _score;
            if (_score >= int256(aiMilestonePassThreshold)) {
                milestone.status = MilestoneStatus.Passed;
                emit MilestoneStatusUpdated(projectId, milestoneIndex, MilestoneStatus.Passed);
                updateResearcherReputation(project.lead, 50); // Example: Add 50 reputation for passing milestone
            } else {
                milestone.status = MilestoneStatus.Failed;
                emit MilestoneStatusUpdated(projectId, milestoneIndex, MilestoneStatus.Failed);
                updateResearcherReputation(project.lead, -50); // Example: Deduct reputation for failed milestone
                slashStakedCommitment(projectId, project.lead, researcherProfiles[project.lead].stakedCommitments[projectId].div(2)); // Slash half stake for failure
            }

        } else if (_evalType == uint256(EvalEntityType.Project)) {
            uint256 projectId = _entityId;
            Project storage project = projects[projectId];
            require(project.status == ProjectStatus.Proposed, "CognitoNet: Project not in proposed state for evaluation.");
            
            project.aiScore = _score;
            if (_score >= int256(aiProposalApprovalThreshold)) {
                project.status = ProjectStatus.Approved;
                project.approvalEpoch = getCurrentEpoch();
                emit ProjectStatusUpdated(projectId, ProjectStatus.Approved);
                // After AI approval, a project typically moves to a 'FundingActive' state or awaits initial token deposit.
                // For simplicity, let's mark it as 'FundingActive' directly if AI approves.
                project.status = ProjectStatus.FundingActive;
                emit ProjectStatusUpdated(projectId, ProjectStatus.FundingActive);
            } else {
                project.status = ProjectStatus.Rejected;
                emit ProjectStatusUpdated(projectId, ProjectStatus.Rejected);
            }

        } else if (_evalType == uint256(EvalEntityType.ResearchOutput)) {
            uint256 outputId = _entityId;
            VerifiableOutput storage output = verifiableOutputs[outputId];
            require(output.creator != address(0), "CognitoNet: Output does not exist for evaluation.");
            require(output.outputHash == _hash, "CognitoNet: Hash mismatch for output evaluation.");

            output.credibilityScore = output.credibilityScore.add(int256(_score / 10)); // AI score influences credibility
        }
        // EvalEntityType.ResearcherProfile could be used for periodic AI-driven performance reviews of researchers.
    }

    /**
     * @dev Sets the AI score thresholds for automatic project proposal approval and milestone passing.
     * Only callable by the contract owner.
     * @param _proposalApprovalThreshold The new threshold for project proposal approval (0-100).
     * @param _milestonePassThreshold The new threshold for milestone passing (0-100).
     */
    function setAIDecisionThresholds(uint256 _proposalApprovalThreshold, uint256 _milestonePassThreshold) public onlyOwner {
        require(_proposalApprovalThreshold <= 100, "CognitoNet: Approval threshold cannot exceed 100.");
        require(_milestonePassThreshold <= 100, "CognitoNet: Pass threshold cannot exceed 100.");
        aiProposalApprovalThreshold = _proposalApprovalThreshold;
        aiMilestonePassThreshold = _milestonePassThreshold;
        emit AIDecisionThresholdsUpdated(_proposalApprovalThreshold, _milestonePassThreshold);
    }

    // --- V. Governance & Network Dynamics ---

    /**
     * @dev Allows any researcher with sufficient reputation to submit a governance proposal.
     * @param _descriptionHash IPFS CID or hash for detailed proposal description.
     * @param _targetContract The address of the contract the proposal targets (e.g., this contract).
     * @param _callData The encoded function call to be executed if the proposal passes.
     */
    function submitGovernanceProposal(
        string memory _descriptionHash,
        address _targetContract,
        bytes memory _callData
    ) public onlyResearcher nonReentrant returns (uint256) {
        require(researcherProfiles[msg.sender].reputation >= int256(MIN_REPUTATION_FOR_PROPOSAL), "CognitoNet: Insufficient reputation to submit governance proposals.");
        
        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            descriptionHash: _descriptionHash,
            targetContract: _targetContract,
            callData: _callData,
            status: GovernanceProposalStatus.Pending,
            submissionEpoch: getCurrentEpoch(),
            expirationEpoch: getCurrentEpoch().add(3), // Example: Proposal lasts for 3 epochs
            yesVotes: 0,
            noVotes: 0,
            weightedYesVotes: 0,
            weightedNoVotes: 0
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender, _descriptionHash);
        return proposalId;
    }

    /**
     * @dev Allows reputation-holding researchers to cast their primary (1-vote-per-researcher) vote on governance proposals.
     * @param _proposalId The ID of the governance proposal.
     * @param _approve True for 'yes' vote, false for 'no' vote.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _approve) public onlyResearcher proposalPending(_proposalId) proposalNotExpired(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "CognitoNet: Already cast primary vote on this proposal.");
        
        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Allows a researcher to burn a portion of their reputation to contribute a weighted vote
     * to a specific governance proposal. This acts as a "super-vote" on top of the regular 1-vote.
     * The reputation is permanently reduced (burned).
     * @param _proposalId The ID of the governance proposal.
     * @param _reputationAmount The amount of reputation to burn for additional voting power.
     * @param _voteForYes True if the burned reputation contributes to 'yes' weighted votes, false for 'no'.
     */
    function redeemReputationAsGovernancePower(uint256 _proposalId, uint256 _reputationAmount, bool _voteForYes) public onlyResearcher proposalPending(_proposalId) proposalNotExpired(_proposalId) {
        ResearcherProfile storage researcher = researcherProfiles[msg.sender];
        require(researcher.reputation >= int256(_reputationAmount), "CognitoNet: Insufficient reputation to redeem.");
        require(_reputationAmount > 0, "CognitoNet: Must redeem a positive amount of reputation.");
        
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        
        // Deduct reputation (burn it)
        researcher.reputation = researcher.reputation.sub(int256(_reputationAmount));
        
        // Add to weighted votes. This is a "super-vote" on top of the regular 1-vote.
        if (_voteForYes) {
            proposal.weightedYesVotes = proposal.weightedYesVotes.add(_reputationAmount);
        } else {
            proposal.weightedNoVotes = proposal.weightedNoVotes.add(_reputationAmount);
        }

        emit ReputationRedeemedForPower(msg.sender, _proposalId, _reputationAmount);
        emit ResearcherReputationUpdated(msg.sender, researcher.reputation, int256(-_reputationAmount));
    }

    /**
     * @dev Executes an approved governance proposal.
     * Can be called by anyone after the proposal's voting period ends and it's approved.
     * Checks if proposal passed based on combined simple and weighted votes, and is ready for execution.
     */
    function executeGovernanceProposal(uint256 _proposalId) public nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == GovernanceProposalStatus.Pending, "CognitoNet: Proposal not in pending status.");
        require(getCurrentEpoch() > proposal.expirationEpoch, "CognitoNet: Voting period not yet ended.");
        
        uint256 totalYes = proposal.yesVotes.add(proposal.weightedYesVotes);
        uint256 totalNo = proposal.noVotes.add(proposal.weightedNoVotes);

        if (totalYes > totalNo) {
            proposal.status = GovernanceProposalStatus.Approved; // Mark as approved first
            // Execute the payload (caution: re-entrancy, unchecked external calls)
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "CognitoNet: Proposal execution failed.");
            proposal.status = GovernanceProposalStatus.Executed;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.status = GovernanceProposalStatus.Rejected;
            emit GovernanceProposalExecuted(_proposalId); // Still emit for rejected, but status is rejected.
        }
    }

    /**
     * @dev Admin function to trigger the distribution of accumulated rewards to researchers.
     * Rewards are calculated based on an off-chain formula (referenced by `_formulaHash`)
     * considering researcher reputation, contributions, staked amounts, and potentially AI scores.
     * Funds are moved from the contract's balance to individual claimable balances.
     * @param _epoch The epoch for which rewards are being distributed.
     */
    function distributeEpochRewards(uint256 _epoch) public onlyOwner nonReentrant {
        // This is a simplified example of reward distribution.
        // In a real system, the reward calculation would be more complex and potentially
        // involve iterating over all researchers' contributions in the specified epoch.
        // For production, iteration over all researchers/projects might exceed gas limits.
        // It's often handled by off-chain computation populating on-chain claimable balances.

        uint256 totalRewardsPool = fundingToken.balanceOf(address(this)); // Use all funds in contract as pool for simplicity

        if (totalRewardsPool == 0) {
            emit RewardsDistributed(_epoch, 0);
            return;
        }

        uint256 totalPositiveReputation = 0;
        // In a full system, you would iterate over all researchers or have a list of active ones.
        // For demonstration, let's iterate through known researchers (e.g., those who submitted proposals).
        // This loop is for concept and would be inefficient for many users.
        address[] memory activeResearchers = new address[](nextGovernanceProposalId); // Placeholder
        uint256 activeCount = 0;
        for (uint256 i = 1; i < nextGovernanceProposalId; i++) {
            address researcherAddr = governanceProposals[i].proposer;
            if (isResearcher[researcherAddr]) {
                if (researcherProfiles[researcherAddr].reputation > 0) {
                    totalPositiveReputation = totalPositiveReputation.add(uint256(researcherProfiles[researcherAddr].reputation));
                    activeResearchers[activeCount++] = researcherAddr;
                }
            }
        }
        
        if (totalPositiveReputation == 0) {
            emit RewardsDistributed(_epoch, 0);
            return;
        }

        for (uint256 i = 0; i < activeCount; i++) {
            address researcherAddr = activeResearchers[i];
            uint256 rewardShare = (totalRewardsPool.mul(uint256(researcherProfiles[researcherAddr].reputation))).div(totalPositiveReputation);
            claimableRewards[researcherAddr] = claimableRewards[researcherAddr].add(rewardShare);
        }
        
        // Remaining small dust might be left or distributed to a community treasury.
        emit RewardsDistributed(_epoch, totalRewardsPool);
    }

    // --- VI. Data & IP Management ---

    /**
     * @dev Allows project leads to register a cryptographic hash of their research output.
     * This provides on-chain proof of existence, timestamping, and immutability for IP.
     * @param _projectId The ID of the project the output belongs to.
     * @param _outputHash The cryptographic hash of the research output (e.g., IPFS CID).
     * @param _descriptionHash IPFS CID or hash for metadata/description of the output.
     */
    function registerVerifiableOutputHash(uint256 _projectId, bytes32 _outputHash, string memory _descriptionHash) public onlyProjectLead(_projectId) nonReentrant returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Completed || project.status == ProjectStatus.FundingActive, "CognitoNet: Project not in active or completed state.");
        require(_outputHash != bytes32(0), "CognitoNet: Output hash cannot be zero.");

        uint256 outputId = nextOutputId++;
        verifiableOutputs[outputId] = VerifiableOutput({
            projectId: _projectId,
            creator: msg.sender,
            outputHash: _outputHash,
            descriptionHash: _descriptionHash,
            registrationEpoch: getCurrentEpoch(),
            credibilityScore: 0, // Initial credibility score
            hasAttested: new mapping(address => bool)(), // Initialize empty mapping
            trueAttestations: 0,
            falseAttestations: 0
        });

        // Optionally, trigger AI evaluation for the output's quality/impact
        _requestAIEvaluation(uint256(EvalEntityType.ResearchOutput), outputId, _outputHash);

        emit VerifiableOutputRegistered(outputId, _projectId, msg.sender, _outputHash);
        return outputId;
    }

    /**
     * @dev Allows other researchers to attest to the truthfulness or validity of a registered output hash.
     * This contributes to the output's credibility score and the attester's reputation.
     * @param _outputId The ID of the verifiable output to attest to.
     * @param _isTrue True if attesting to truthfulness/validity, false otherwise.
     */
    function attestToOutputTruthfulness(uint256 _outputId, bool _isTrue) public onlyResearcher {
        VerifiableOutput storage output = verifiableOutputs[_outputId];
        require(output.creator != address(0), "CognitoNet: Output does not exist.");
        require(output.creator != msg.sender, "CognitoNet: Cannot attest to your own output.");
        require(!output.hasAttested[msg.sender], "CognitoNet: Already attested to this output.");

        output.hasAttested[msg.sender] = true;
        
        int256 reputationGain = 0;
        if (_isTrue) {
            output.trueAttestations++;
            output.credibilityScore = output.credibilityScore.add(1); // Increment score
            reputationGain = 5; // Example: small reputation gain for positive attestation
        } else {
            output.falseAttestations++;
            output.credibilityScore = output.credibilityScore.sub(1); // Decrement score
            reputationGain = -2; // Example: small reputation loss for negative attestation (could be higher if proven wrong)
        }

        updateResearcherReputation(msg.sender, reputationGain);
        emit OutputAttested(_outputId, msg.sender, _isTrue);
    }

    // --- VII. Incentives & Rewards ---

    /**
     * @dev Allows researchers to claim their accumulated rewards from the current or previous epochs.
     * Rewards are accumulated by `distributeEpochRewards`.
     */
    function claimEpochRewards() public onlyResearcher nonReentrant {
        uint256 amount = claimableRewards[msg.sender];
        require(amount > 0, "CognitoNet: No rewards to claim.");
        
        claimableRewards[msg.sender] = 0; // Reset claimable balance
        require(fundingToken.transfer(msg.sender, amount), "CognitoNet: Reward transfer failed.");
        
        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev Sets the hash of the off-chain formula used to calculate reward distribution.
     * This formula guides the `distributeEpochRewards` function conceptually.
     * @param _formulaHash IPFS CID or hash for the reward distribution formula.
     */
    function setRewardDistributionFormula(bytes32 _formulaHash) public onlyOwner {
        // This hash can be used by off-chain logic or future on-chain governance to verify the formula.
        // The actual implementation of reward distribution would reference this formula's logic.
        // For this contract, it's a symbolic reference.
        emit RewardDistributionFormulaUpdated(_formulaHash);
    }

    /**
     * @dev Returns the number of active projects a researcher is currently involved in as a lead.
     * Note: Iterating over all projects (`nextProjectId`) can be gas-intensive for large numbers.
     * In a production system, this data would typically be indexed and queried off-chain.
     * @param _researcher The address of the researcher.
     * @return The count of active projects where the researcher is the lead.
     */
    function getResearcherActiveContributions(address _researcher) public view returns (uint256) {
        require(isResearcher[_researcher], "CognitoNet: Researcher not registered.");
        
        uint256 activeCount = 0;
        for (uint256 i = 1; i < nextProjectId; i++) {
            Project storage project = projects[i];
            if (project.lead == _researcher && (
                project.status == ProjectStatus.FundingActive || 
                project.status == ProjectStatus.Proposed || 
                project.status == ProjectStatus.Extended
            )) {
                activeCount++;
            }
        }
        return activeCount;
    }
}
```