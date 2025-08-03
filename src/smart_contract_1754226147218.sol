The "Decentralized Autonomous Research & Development Lab (DARL)" smart contract is designed to be a self-governing on-chain entity that funds, manages, and executes cutting-edge research projects. It introduces several advanced concepts: a decentralized reputation system, skill-based project allocation, milestone-based verifiable funding (conceptually integrating with verifiable computation proofs like ZKPs), and an on-chain knowledge base for research outputs. The entire system is governed by its community through robust DAO mechanisms, allowing for autonomous evolution and adaptation.

---

### **Outline and Function Summary**

**Contract Name:** DARL (Decentralized Autonomous Research & Development Lab)

**Core Concept:** A community-driven platform for funding, managing, and publishing decentralized research and development projects, leveraging on-chain governance and reputation.

**Key Advanced Concepts:**
*   **Decentralized Reputation System:** Researchers earn and lose reputation based on contributions, attestations, and project outcomes. Reputation influences voting power, attestation strength, and access.
*   **Skill-Based Allocation:** Projects can specify required skills, and researchers can get their skills attested by reputable peers.
*   **Milestone-Based Verifiable Funding:** Projects are funded in stages, with payments released upon successful, verified completion of milestones. This conceptually supports integration with off-chain verifiable proofs (e.g., ZKPs).
*   **On-Chain Knowledge Base:** Metadata of research outputs (papers, code, datasets) are recorded on-chain, with options for public or access-controlled distribution and infringement reporting.
*   **Adaptive Governance:** Core parameters, upgrades, and critical decisions are managed through a decentralized autonomous organization (DAO) voting mechanism.

---

**Function Summary (28 Functions):**

**I. Core Infrastructure & Governance (6 Functions)**
1.  `constructor(address _initialAdmin)`: Initializes the contract with an admin, establishing the initial ownership that can transition to DAO control.
2.  `updateCoreParameter(string calldata _paramName, uint256 _newValue)`: Allows the DAO (via successful governance proposal execution) to update critical system parameters like fees, voting periods, or quorum thresholds.
3.  `proposeContractUpgrade(address _newImplementation)`: Initiates a governance proposal for upgrading the contract's implementation (assuming a UUPS proxy pattern for upgradability).
4.  `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Enables registered researchers with sufficient reputation to vote 'for' or 'against' a system-level governance proposal.
5.  `executeGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal once its voting period has ended and it has met the necessary quorum and approval thresholds.
6.  `adjustDynamicFeesAndRewards(uint256 _newProposalFee, uint256 _newValidatorRewardRate)`: A specific governance function to fine-tune economic parameters like project proposal fees and potential validator reward rates.

**II. Member & Reputation Management (7 Functions)**
7.  `registerResearcher(string calldata _ipfsMetadataHash)`: Allows any address to register as a researcher, providing an IPFS hash to their detailed off-chain profile.
8.  `registerSkill(string calldata _skillTag)`: Enables a registered researcher to declare a skill they possess. This declaration sets the stage for others to attest to it.
9.  `attestSkill(address _researcher, string calldata _skillTag, uint256 _attestationStrength)`: Allows reputable researchers to provide an attestation of another researcher's skill, influencing their reputation.
10. `decayReputation(address _researcher)`: Triggers a time-based decay of a researcher's reputation if they have been inactive for a specified period, preventing stale reputation.
11. `challengeSkillAttestation(address _researcher, string calldata _skillTag)`: Initiates a dispute process for a skill attestation, potentially leading to a review or vote on its validity.
12. `getResearcherProfile(address _researcher)`: Retrieves the IPFS metadata hash associated with a researcher's profile.
13. `getResearcherReputation(address _researcher)`: Calculates and returns a researcher's current reputation score, considering attestations and activity decay.

**III. Project Lifecycle Management (10 Functions)**
14. `submitProjectProposal(string calldata _ipfsProjectDetailsHash, uint256 _budgetAmount, string[] calldata _requiredSkills, uint256 _milestoneCount)`: A researcher submits a detailed project proposal, including budget, required skills, and defined milestones, paying a proposal fee.
15. `depositProposalFee()`: A payable function to deposit the required fee for submitting a project proposal.
16. `voteOnProjectProposal(uint256 _projectId, bool _approve)`: Enables reputable researchers to vote on whether to approve and fund a submitted project proposal.
17. `allocateProjectFunds(uint256 _projectId)`: Transfers the approved project budget from the DARL treasury into a dedicated escrow within the contract for the project.
18. `submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string calldata _ipfsResultHash, bytes32 _verificationProofHash, uint8 _verificationMethod)`: The project lead submits proof of a milestone's completion, including an IPFS hash of results and an optional hash of a verifiable computation proof.
19. `nominateProjectValidator(uint256 _projectId, uint256 _milestoneIndex, address _validator)`: Allows the project lead (or potentially DAO) to nominate a specific researcher to validate a milestone.
20. `validateMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _isValid)`: A designated validator or a sufficiently reputable community member verifies the completion and validity of a milestone.
21. `disputeMilestoneValidation(uint256 _projectId, uint256 _milestoneIndex)`: Allows researchers or the project lead to dispute a milestone validation decision, triggering a resolution process.
22. `releaseMilestonePayment(uint256 _projectId, uint256 _milestoneIndex)`: Releases the allocated funds for a successfully validated milestone to the project lead.
23. `cancelProject(uint256 _projectId)`: Initiates a governance vote to prematurely cancel an ongoing project, potentially returning remaining funds to the treasury.

**IV. Knowledge Base & IP Management (3 Functions)**
24. `publishResearchOutput(uint256 _projectId, string calldata _ipfsOutputHash, string[] calldata _keywords, bool _isPublic)`: Registers metadata for a research output (e.g., paper, dataset, code) associated with a project, specifying public or private access.
25. `grantIPAccess(uint256 _outputId, address _grantee)`: Grants specific on-chain access to a private research output, intended for managing access to sensitive IP or decryption keys.
26. `reportIPInfringement(uint256 _outputId, string calldata _infringementDetailsHash)`: Records an on-chain report of a suspected IP infringement related to a published output, triggering potential off-chain dispute resolution.

**V. Treasury & Funding (2 Functions)**
27. `donateToTreasury()`: Allows anyone to send native currency (ETH) to the DARL's central treasury, supporting ongoing operations and project funding.
28. `requestTreasuryGrant(string calldata _requestDetailsHash, uint256 _amount)`: Allows registered researchers to submit a proposal to the DAO for a general grant from the treasury for non-project specific needs (e.g., equipment, travel).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though 0.8.0+ has default overflow checks
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString utility

// --- Outline and Function Summary ---
// This contract, "Decentralized Autonomous Research & Development Lab (DARL)",
// aims to be a self-governing entity for funding, managing, and executing
// cutting-edge research projects. It incorporates advanced concepts such as
// a decentralized reputation system, skill-based task allocation, milestone-based
// verifiable funding, and an on-chain knowledge base for research outputs.
// It is designed to be fully controlled by its community through a robust
// governance mechanism, evolving autonomously.

// I. Core Infrastructure & Governance (6 Functions)
//    - constructor: Initializes the contract with an admin.
//    - updateCoreParameter: Allows DAO to update system parameters (e.g., fees, quorums).
//    - proposeContractUpgrade: Initiates a vote for contract upgrades (assumes UUPS proxy pattern).
//    - voteOnGovernanceProposal: Participates in governance votes for system-level changes.
//    - executeGovernanceProposal: Executes approved governance proposals.
//    - adjustDynamicFeesAndRewards: DAO-governed adjustment of economic parameters.

// II. Member & Reputation Management (7 Functions)
//    - registerResearcher: Registers a new researcher profile.
//    - registerSkill: Declares a skill by a researcher.
//    - attestSkill: Allows reputable members to vouch for a researcher's skill.
//    - decayReputation: Triggers reputation decay based on inactivity/time.
//    - challengeSkillAttestation: Initiates a dispute over a false skill attestation.
//    - getResearcherProfile: Retrieves a researcher's profile metadata.
//    - getResearcherReputation: Returns a researcher's calculated reputation score.

// III. Project Lifecycle Management (10 Functions)
//    - submitProjectProposal: Proposes a new research project to the DAO.
//    - depositProposalFee: Pays the fee required to submit a proposal.
//    - voteOnProjectProposal: Community votes on project funding and approval.
//    - allocateProjectFunds: Transfers approved funds to the project's escrow.
//    - submitMilestoneCompletion: Researchers submit proof of milestone completion.
//    - nominateProjectValidator: Project lead or DAO nominates a validator for a milestone.
//    - validateMilestone: Designated validator/community verifies milestone completion.
//    - disputeMilestoneValidation: Disputes a milestone validation decision.
//    - releaseMilestonePayment: Releases funds for a validated milestone.
//    - cancelProject: Initiates a governance vote to cancel an ongoing project.

// IV. Knowledge Base & IP Management (3 Functions)
//    - publishResearchOutput: Registers metadata for research output (e.g., IPFS hash).
//    - grantIPAccess: Controls access to private research outputs.
//    - reportIPInfringement: Records an IP infringement report on-chain.

// V. Treasury & Funding (2 Functions)
//    - donateToTreasury: Allows external parties to donate native currency to DARL.
//    - requestTreasuryGrant: Allows researchers to request general grants from the treasury.

// VI. Helper Functions (Internal/View for readability & utility, not counted in 20+ requirement)
//    - _calculateReputationScore: Internal logic for reputation.
//    - getGovernanceProposalState: Returns the state of a governance proposal.
//    - getProjectState: Returns the state of a project.
//    - getMilestoneDetails: Returns details of a specific milestone.
//    - getSkillAttestations: Returns all skill attestations for a given researcher and skill.

contract DARL is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---

    // Constants & Parameters (can be made configurable by governance)
    uint256 public constant MIN_REPUTATION_FOR_VOTING = 100;
    uint256 public constant MIN_REPUTATION_FOR_ATTESTATION = 500;
    uint256 public constant REPUTATION_DECAY_RATE = 1; // % per decay period
    uint256 public constant REPUTATION_DECAY_PERIOD = 30 days; // Decay every 30 days of inactivity

    uint256 public projectProposalFee = 0.05 ether; // 0.05 ETH
    uint256 public governanceVotingPeriod = 7 days;
    uint256 public projectVotingPeriod = 5 days;
    uint256 public milestoneValidationPeriod = 3 days;
    uint256 public disputeResolutionPeriod = 7 days;
    uint256 public governanceQuorumNumerator = 60; // 60% of total votes needed for quorum
    uint256 public governanceQuorumDenominator = 100;
    uint256 public projectApprovalThresholdNumerator = 51; // 51% of votes needed for project approval
    uint256 public projectApprovalThresholdDenominator = 100;

    // --- Structs ---

    struct Researcher {
        string ipfsMetadataHash; // IPFS hash pointing to researcher's detailed profile
        uint256 reputation; // Accumulated reputation score
        uint256 lastActivityTimestamp; // For reputation decay calculation
        bool isRegistered;
    }

    struct SkillAttestation {
        address attester;
        uint256 strength; // e.g., 1-10, higher means stronger belief in skill
        uint256 timestamp;
        bool disputed;
    }

    enum ProposalType {
        GovernanceParameterChange,
        ContractUpgrade,
        TreasuryGrant,
        ProjectCancellation
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    struct GovernanceProposal {
        ProposalType proposalType;
        string descriptionHash; // IPFS hash for proposal details
        address targetAddress; // For upgrades or specific contract calls
        bytes callData; // For upgrades or specific contract calls
        uint256 value; // For treasury grants
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Tracks voters
        ProposalState state;
        uint256 id; // Unique ID for proposal
    }

    enum ProjectState {
        PendingApproval,
        Approved,
        Active,
        Paused, // Not used in current implementation but good for future extension
        Completed,
        Cancelled
    }

    enum MilestoneState {
        PendingSubmission,
        Submitted,
        PendingValidation,
        Validated,
        Disputed,
        Paid
    }

    enum VerificationMethod {
        ManualCommunity,
        DesignatedValidator,
        ZeroKnowledgeProof, // Assumes ZKP verification happens off-chain, proof hash is submitted
        AI_Assisted // Assumes AI oracle provides verification, details in IPFS
    }

    struct Milestone {
        string ipfsResultHash; // IPFS hash for milestone output/report
        bytes32 verificationProofHash; // Hash of a ZKP or other verifiable computation proof
        VerificationMethod verificationMethod;
        MilestoneState state;
        address nominatedValidator; // Specific address nominated to validate this milestone
        uint256 validationTimestamp; // When it was validated or disputed
        bool isValidated; // Final validation decision
        uint256 paymentAmount; // Amount to be paid for this milestone
    }

    struct Project {
        string ipfsProjectDetailsHash; // IPFS hash for detailed project proposal
        address projectLead;
        uint256 budgetAmount; // Total budget for the project
        string[] requiredSkills; // Skills required for this project
        ProjectState state;
        uint252 creationTime;
        uint256 approvalDeadline;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Tracks voters for project approval
        Milestone[] milestones;
        uint256 currentMilestoneIndex; // Track progress
        uint256 fundsInEscrow; // Funds held for this project
        uint256 id; // Unique ID for project
    }

    struct ResearchOutput {
        uint256 projectId;
        string ipfsOutputHash; // IPFS hash of the research output
        string[] keywords;
        bool isPublic; // True if public, false if access controlled
        address publisher;
        uint256 publishTime;
        bool hasBeenInfringed; // Flag if an infringement report has been filed
        mapping(address => bool) grantedAccess; // For private outputs
        uint256 id; // Unique ID for research output
    }

    // --- Mappings ---

    mapping(address => Researcher) public researchers;
    mapping(address => mapping(string => SkillAttestation[])) public skillAttestations; // researcher => skillTag => attestations
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => ResearchOutput) public researchOutputs;

    // --- Counters ---

    uint256 private nextGovernanceProposalId = 0;
    uint256 private nextProjectId = 0;
    uint256 private nextResearchOutputId = 0;

    // --- Events ---

    event ResearcherRegistered(address indexed researcher, string ipfsMetadataHash);
    event SkillRegistered(address indexed researcher, string skillTag);
    event SkillAttested(address indexed researcher, address indexed attester, string skillTag, uint256 strength);
    event ReputationDecayed(address indexed researcher, uint256 oldReputation, uint256 newReputation);
    event SkillAttestationChallenged(address indexed researcher, string skillTag, address indexed challenger);

    event GovernanceProposalCreated(uint256 indexed proposalId, ProposalType proposalType, string descriptionHash);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event CoreParameterUpdated(string paramName, uint256 newValue);
    event ContractUpgradeProposed(address indexed newImplementation);
    event FeesAndRewardsAdjusted(uint256 newProposalFee, uint256 newValidatorRewardRate);

    event ProjectProposalSubmitted(uint256 indexed projectId, address indexed projectLead, string ipfsProjectDetailsHash, uint256 budgetAmount);
    event ProjectProposalVoted(uint256 indexed projectId, address indexed voter, bool approve);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState newState);
    event ProjectFundsAllocated(uint256 indexed projectId, uint256 amount);
    event MilestoneCompletionSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string ipfsResultHash);
    event MilestoneValidated(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed validator, bool isValid);
    event MilestoneDisputed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed disputer);
    event MilestonePaymentReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ProjectValidatorNominated(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed validator);
    event ProjectCancelled(uint256 indexed projectId);

    event ResearchOutputPublished(uint256 indexed outputId, uint256 indexed projectId, string ipfsOutputHash, bool isPublic);
    event IPAccessGranted(uint256 indexed outputId, address indexed grantee);
    event IPInfringementReported(uint256 indexed outputId, string infringementDetailsHash);

    event FundsDonated(address indexed donor, uint256 amount);
    event TreasuryGrantRequested(uint256 indexed proposalId, address indexed requester, uint256 amount);

    // --- Modifiers ---

    modifier onlyRegisteredResearcher() {
        require(researchers[msg.sender].isRegistered, "Caller must be a registered researcher");
        _;
    }

    modifier hasMinReputation(uint256 _minReputation) {
        require(_calculateReputationScore(msg.sender) >= _minReputation, "Insufficient reputation");
        _;
    }

    modifier isGovernanceProposalActive(uint256 _proposalId) {
        require(governanceProposals[_proposalId].state == ProposalState.Active, "Governance proposal not active");
        _;
    }

    modifier isProjectProposalActive(uint256 _projectId) {
        require(projects[_projectId].state == ProjectState.PendingApproval, "Project proposal not active");
        _;
    }

    modifier notVotedOnGovernanceProposal(uint256 _proposalId) {
        require(!governanceProposals[_proposalId].hasVoted[msg.sender], "Already voted on this governance proposal");
        _;
    }

    modifier notVotedOnProjectProposal(uint256 _projectId) {
        require(!projects[_projectId].hasVoted[msg.sender], "Already voted on this project proposal");
        _;
    }

    // --- Constructor ---

    constructor(address _initialAdmin) Ownable(_initialAdmin) {
        // Initial admin set by Ownable. This admin will typically initiate the DAO
        // structure or hand over ownership to a multi-sig / DAO governance contract.
    }

    // --- I. Core Infrastructure & Governance ---

    /**
     * @notice Allows the DAO to update critical system parameters.
     * @dev In a full DAO, this function would be called internally by `executeGovernanceProposal`
     *      after a `GovernanceParameterChange` proposal passes. For this example, it is `onlyOwner`
     *      to simulate a direct admin control for testing purposes, but conceptually it's DAO-controlled.
     * @param _paramName The name of the parameter to update (e.g., "projectProposalFee", "governanceVotingPeriod").
     * @param _newValue The new value for the parameter.
     */
    function updateCoreParameter(string calldata _paramName, uint256 _newValue) external onlyOwner {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));

        if (paramHash == keccak256(abi.encodePacked("projectProposalFee"))) {
            projectProposalFee = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("governanceVotingPeriod"))) {
            governanceVotingPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("projectVotingPeriod"))) {
            projectVotingPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("milestoneValidationPeriod"))) {
            milestoneValidationPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("disputeResolutionPeriod"))) {
            disputeResolutionPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("governanceQuorumNumerator"))) {
            require(_newValue <= governanceQuorumDenominator, "Numerator cannot exceed denominator");
            governanceQuorumNumerator = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("projectApprovalThresholdNumerator"))) {
            require(_newValue <= projectApprovalThresholdDenominator, "Numerator cannot exceed denominator");
            projectApprovalThresholdNumerator = _newValue;
        } else {
            revert("Unknown parameter name");
        }
        emit CoreParameterUpdated(_paramName, _newValue);
    }

    /**
     * @notice Initiates a governance vote for upgrading the contract implementation.
     * @dev This contract itself is the implementation. In a real UUPS proxy setup,
     *      this function would prepare a proposal for the proxy to call `upgradeTo`.
     * @param _newImplementation The address of the new contract implementation.
     */
    function proposeContractUpgrade(address _newImplementation) external onlyRegisteredResearcher nonReentrant hasMinReputation(MIN_REPUTATION_FOR_VOTING) {
        require(_newImplementation != address(0), "New implementation address cannot be zero");

        uint256 proposalId = nextGovernanceProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposalType = ProposalType.ContractUpgrade;
        proposal.descriptionHash = "Proposal to upgrade contract implementation";
        proposal.targetAddress = address(this); // Target is the proxy address in a real UUPS system
        // Store the new implementation address in callData for later execution
        proposal.callData = abi.encode(_newImplementation); 
        proposal.creationTime = block.timestamp;
        proposal.votingDeadline = block.timestamp.add(governanceVotingPeriod);
        proposal.state = ProposalState.Active;

        emit GovernanceProposalCreated(proposalId, ProposalType.ContractUpgrade, proposal.descriptionHash);
    }

    /**
     * @notice Allows registered researchers to vote on a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlyRegisteredResearcher nonReentrant hasMinReputation(MIN_REPUTATION_FOR_VOTING) notVotedOnGovernanceProposal(_proposalId) isGovernanceProposalActive(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.forVotes = proposal.forVotes.add(1); // Simplified: 1 researcher = 1 vote. Can be weighted by reputation.
        } else {
            proposal.againstVotes = proposal.againstVotes.add(1);
        }

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a governance proposal if it has succeeded.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeGovernanceProposal(uint256 _proposalId) external nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(proposal.state != ProposalState.Pending, "Proposal not active yet");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");

        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        // Simplified quorum check: Total votes cast must meet a percentage threshold.
        // A more robust DAO would track active eligible voters.
        uint256 minVotesForQuorum = totalVotes.mul(governanceQuorumNumerator).div(governanceQuorumDenominator); 

        if (totalVotes < minVotesForQuorum) { // Check if enough people participated
            proposal.state = ProposalState.Defeated;
            emit GovernanceProposalStateChanged(_proposalId, ProposalState.Defeated);
            return;
        }

        if (proposal.forVotes.mul(100).div(totalVotes) >= governanceQuorumNumerator) { // Check if 'for' votes meet approval threshold
            proposal.state = ProposalState.Succeeded;
            emit GovernanceProposalStateChanged(_proposalId, ProposalState.Succeeded);

            if (proposal.proposalType == ProposalType.ContractUpgrade) {
                address newImplementation = abi.decode(proposal.callData, (address));
                // If this contract were a UUPS proxy, you'd call `self.delegatecall(abi.encodeWithSelector(upgradeTo.selector, newImplementation))`
                // For this example, we're just emitting the event.
                emit ContractUpgradeProposed(newImplementation);
            } else if (proposal.proposalType == ProposalType.TreasuryGrant) {
                (bool success,) = payable(proposal.targetAddress).call{value: proposal.value}("");
                require(success, "Failed to send treasury grant");
            } else if (proposal.proposalType == ProposalType.ProjectCancellation) {
                uint256 projectIdToCancel = abi.decode(proposal.callData, (uint256));
                Project storage project = projects[projectIdToCancel];
                require(project.state != ProjectState.Completed && project.state != ProjectState.Cancelled, "Project already completed or cancelled.");
                project.state = ProjectState.Cancelled;
                // Refund remaining funds to treasury if any in escrow
                if (project.fundsInEscrow > 0) {
                    (bool success,) = payable(address(this)).call{value: project.fundsInEscrow}("");
                    require(success, "Failed to refund project escrow to treasury");
                    project.fundsInEscrow = 0;
                }
                emit ProjectCancelled(projectIdToCancel);
            }
            // For GovernanceParameterChange, the values would be decoded and applied here.
            // Example: `updateCoreParameter(decodedParamName, decodedNewValue)`

            proposal.state = ProposalState.Executed;
            emit GovernanceProposalStateChanged(_proposalId, ProposalState.Executed);
        } else {
            proposal.state = ProposalState.Defeated;
            emit GovernanceProposalStateChanged(_proposalId, ProposalState.Defeated);
        }
    }

    /**
     * @notice Allows the DAO to adjust dynamic fees and reward rates.
     * @dev This function would typically be called by `executeGovernanceProposal` after a relevant vote.
     *      It is `onlyOwner` for simplicity in this example.
     * @param _newProposalFee The new fee for submitting project proposals (in Wei).
     * @param _newValidatorRewardRate The new reward rate for milestone validators (e.g., in basis points).
     */
    function adjustDynamicFeesAndRewards(uint256 _newProposalFee, uint256 _newValidatorRewardRate) external onlyOwner {
        require(_newValidatorRewardRate <= 10000, "Validator reward rate cannot exceed 100%"); // Max 100%
        projectProposalFee = _newProposalFee;
        // If there were explicit validator rewards managed by the contract, they would be set here.
        // E.g., `validatorRewardRate = _newValidatorRewardRate;`
        emit FeesAndRewardsAdjusted(_newProposalFee, _newValidatorRewardRate);
    }

    // --- II. Member & Reputation Management ---

    /**
     * @notice Allows an address to register as a researcher.
     * @param _ipfsMetadataHash IPFS hash pointing to the researcher's detailed profile.
     */
    function registerResearcher(string calldata _ipfsMetadataHash) external nonReentrant {
        require(!researchers[msg.sender].isRegistered, "Already a registered researcher");
        require(bytes(_ipfsMetadataHash).length > 0, "IPFS metadata hash cannot be empty");

        researchers[msg.sender] = Researcher({
            ipfsMetadataHash: _ipfsMetadataHash,
            reputation: 1, // Initial reputation for new researchers
            lastActivityTimestamp: block.timestamp,
            isRegistered: true
        });

        emit ResearcherRegistered(msg.sender, _ipfsMetadataHash);
    }

    /**
     * @notice Allows a registered researcher to declare a skill they possess.
     * @param _skillTag A string representing the skill (e.g., "Solidity", "AI/ML", "Biotechnology").
     */
    function registerSkill(string calldata _skillTag) external onlyRegisteredResearcher {
        require(bytes(_skillTag).length > 0, "Skill tag cannot be empty");
        // This function primarily serves to update the researcher's activity timestamp
        // and signal intent for future attestations. Skills become "official" via attestations.
        researchers[msg.sender].lastActivityTimestamp = block.timestamp;
        emit SkillRegistered(msg.sender, _skillTag);
    }

    /**
     * @notice Allows a reputable researcher to attest to another researcher's skill.
     * @param _researcher The address of the researcher whose skill is being attested.
     * @param _skillTag The skill being attested.
     * @param _attestationStrength A value indicating the strength/confidence of the attestation (e.g., 1-10).
     */
    function attestSkill(address _researcher, string calldata _skillTag, uint256 _attestationStrength) external onlyRegisteredResearcher nonReentrant hasMinReputation(MIN_REPUTATION_FOR_ATTESTATION) {
        require(_researcher != msg.sender, "Cannot attest your own skill");
        require(_attestationStrength > 0 && _attestationStrength <= 10, "Attestation strength must be between 1 and 10");
        require(researchers[_researcher].isRegistered, "Target researcher is not registered");
        require(bytes(_skillTag).length > 0, "Skill tag cannot be empty");

        SkillAttestation memory newAttestation = SkillAttestation({
            attester: msg.sender,
            strength: _attestationStrength,
            timestamp: block.timestamp,
            disputed: false
        });

        skillAttestations[_researcher][_skillTag].push(newAttestation);
        researchers[msg.sender].lastActivityTimestamp = block.timestamp; // Update attester's activity

        // Simple reputation boost for attested researcher, scaled by attester's reputation.
        // The scaling factor (1000) is arbitrary for illustration.
        researchers[_researcher].reputation = researchers[_researcher].reputation.add(_attestationStrength.mul(_calculateReputationScore(msg.sender)).div(1000));
        researchers[_researcher].lastActivityTimestamp = block.timestamp; // Update attested's activity

        emit SkillAttested(_researcher, msg.sender, _skillTag, _attestationStrength);
    }

    /**
     * @notice Triggers reputation decay for an inactive researcher.
     * @dev Anyone can call this to trigger decay for another researcher who meets the decay criteria.
     * @param _researcher The address of the researcher whose reputation to decay.
     */
    function decayReputation(address _researcher) external nonReentrant {
        Researcher storage researcher = researchers[_researcher];
        require(researcher.isRegistered, "Researcher not registered");
        require(researcher.reputation > 1, "Reputation already at minimum (1)");

        uint256 timeSinceLastActivity = block.timestamp.sub(researcher.lastActivityTimestamp);
        if (timeSinceLastActivity >= REPUTATION_DECAY_PERIOD) {
            uint256 decayPeriods = timeSinceLastActivity.div(REPUTATION_DECAY_PERIOD);
            uint256 oldReputation = researcher.reputation;
            uint256 decayAmount = researcher.reputation.mul(REPUTATION_DECAY_RATE).div(100).mul(decayPeriods);
            researcher.reputation = researcher.reputation.sub(decayAmount);
            if (researcher.reputation < 1) researcher.reputation = 1; // Keep min reputation at 1
            researcher.lastActivityTimestamp = block.timestamp; // Reset activity after decay
            emit ReputationDecayed(_researcher, oldReputation, researcher.reputation);
        }
    }

    /**
     * @notice Initiates a dispute for a potentially false skill attestation.
     * @dev This would typically trigger a governance vote or a designated dispute resolver
     *      to review the challenge. For simplicity, it marks the latest attestation as disputed.
     * @param _researcher The researcher whose skill attestation is being challenged.
     * @param _skillTag The specific skill tag being challenged.
     */
    function challengeSkillAttestation(string calldata _skillTag) external onlyRegisteredResearcher nonReentrant {
        // A user challenges an attestation made *about* someone else, or a false attestation *they themselves* made.
        // For simplicity, we assume challenging an attestation that *you* made or *received*.
        // A more complex system would specify which attestation by ID.
        // This function is for challenging your *own* skill's attestation.
        // If it's about challenging *someone else's* skill attestation, the parameter `_researcher` would be added.
        // For simplicity, let's allow `msg.sender` to challenge an attestation *they received*.
        require(skillAttestations[msg.sender][_skillTag].length > 0, "No attestations for this skill tag to challenge");

        // Assume challenging the latest attestation for that skill.
        SkillAttestation storage lastAttestation = skillAttestations[msg.sender][_skillTag][skillAttestations[msg.sender][_skillTag].length - 1];
        require(!lastAttestation.disputed, "Latest attestation already disputed");
        lastAttestation.disputed = true;

        // Optionally, reduce reputation of the original attester or researcher until resolved
        // For now, just mark as disputed and emit event.
        emit SkillAttestationChallenged(msg.sender, _skillTag, msg.sender); // msg.sender is disputing about themselves
    }

    /**
     * @notice Retrieves the profile metadata hash for a registered researcher.
     * @param _researcher The address of the researcher.
     * @return string The IPFS hash of the researcher's profile.
     */
    function getResearcherProfile(address _researcher) external view returns (string memory) {
        require(researchers[_researcher].isRegistered, "Researcher not registered");
        return researchers[_researcher].ipfsMetadataHash;
    }

    /**
     * @notice Calculates and returns a researcher's current reputation score.
     * @param _researcher The address of the researcher.
     * @return uint256 The calculated reputation score.
     */
    function getResearcherReputation(address _researcher) public view returns (uint256) {
        return _calculateReputationScore(_researcher);
    }

    /**
     * @dev Internal function to calculate reputation score, including conceptual decay.
     * @param _researcher The address of the researcher.
     * @return uint256 The calculated reputation score.
     */
    function _calculateReputationScore(address _researcher) internal view returns (uint256) {
        Researcher storage researcher = researchers[_researcher];
        if (!researcher.isRegistered) {
            return 0;
        }

        uint256 tempReputation = researcher.reputation;
        uint256 timeSinceLastActivity = block.timestamp.sub(researcher.lastActivityTimestamp);
        if (timeSinceLastActivity >= REPUTATION_DECAY_PERIOD) {
            uint256 decayPeriods = timeSinceLastActivity.div(REPUTATION_DECAY_PERIOD);
            uint256 decayAmount = researcher.reputation.mul(REPUTATION_DECAY_RATE).div(100).mul(decayPeriods);
            tempReputation = tempReputation.sub(decayAmount);
            if (tempReputation < 1) tempReputation = 1;
        }
        return tempReputation;
    }


    // --- III. Project Lifecycle Management ---

    /**
     * @notice Allows a registered researcher to submit a new research project proposal.
     * @param _ipfsProjectDetailsHash IPFS hash for detailed project proposal.
     * @param _budgetAmount The total budget requested for the project (in Wei).
     * @param _requiredSkills An array of skill tags required for the project.
     * @param _milestoneCount The number of milestones in the project.
     */
    function submitProjectProposal(string calldata _ipfsProjectDetailsHash, uint256 _budgetAmount, string[] calldata _requiredSkills, uint256 _milestoneCount) external onlyRegisteredResearcher nonReentrant {
        require(msg.value >= projectProposalFee, "Insufficient proposal fee");
        require(bytes(_ipfsProjectDetailsHash).length > 0, "Project details hash cannot be empty");
        require(_budgetAmount > 0, "Budget must be greater than zero");
        require(_milestoneCount > 0, "Project must have at least one milestone");

        uint256 projectId = nextProjectId++;
        Project storage project = projects[projectId];

        project.id = projectId;
        project.ipfsProjectDetailsHash = _ipfsProjectDetailsHash;
        project.projectLead = msg.sender;
        project.budgetAmount = _budgetAmount;
        project.requiredSkills = _requiredSkills;
        project.state = ProjectState.PendingApproval;
        project.creationTime = block.timestamp;
        project.approvalDeadline = block.timestamp.add(projectVotingPeriod);
        project.currentMilestoneIndex = 0; // Initialize current milestone index
        project.fundsInEscrow = 0; // No funds until approved and allocated

        // Initialize milestones array
        project.milestones.length = _milestoneCount;
        for (uint i = 0; i < _milestoneCount; i++) {
            project.milestones[i].state = MilestoneState.PendingSubmission;
            // Milestone payment amounts are equally split for simplicity, could be dynamic per IPFS
            project.milestones[i].paymentAmount = _budgetAmount.div(_milestoneCount);
        }

        researchers[msg.sender].lastActivityTimestamp = block.timestamp; // Update project lead's activity

        emit ProjectProposalSubmitted(projectId, msg.sender, _ipfsProjectDetailsHash, _budgetAmount);
    }

    /**
     * @notice Pays the required fee for a project proposal.
     * @dev This must be called immediately after `submitProjectProposal` or as part of the same transaction.
     */
    function depositProposalFee() external payable {
        require(msg.value == projectProposalFee, "Incorrect proposal fee amount");
        // Funds are automatically added to the contract's balance (treasury).
    }

    /**
     * @notice Allows registered researchers to vote on a project proposal.
     * @param _projectId The ID of the project proposal.
     * @param _approve True for 'approve' vote, false for 'reject' vote.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _approve) external onlyRegisteredResearcher nonReentrant hasMinReputation(MIN_REPUTATION_FOR_VOTING) notVotedOnProjectProposal(_projectId) isProjectProposalActive(_projectId) {
        Project storage project = projects[_projectId];
        require(block.timestamp <= project.approvalDeadline, "Voting period has ended");

        project.hasVoted[msg.sender] = true;
        if (_approve) {
            project.forVotes = project.forVotes.add(1);
        } else {
            project.againstVotes = project.againstVotes.add(1);
        }

        researchers[msg.sender].lastActivityTimestamp = block.timestamp; // Update voter's activity

        emit ProjectProposalVoted(_projectId, msg.sender, _approve);

        // Auto-check for approval/rejection if voting period is over
        if (block.timestamp > project.approvalDeadline) {
            uint256 totalVotes = project.forVotes.add(project.againstVotes);
            if (totalVotes > 0 && project.forVotes.mul(100).div(totalVotes) >= projectApprovalThresholdNumerator) {
                project.state = ProjectState.Approved;
                emit ProjectStateChanged(_projectId, ProjectState.Approved);
            } else {
                project.state = ProjectState.Cancelled; // Or Defeated
                emit ProjectStateChanged(_projectId, ProjectState.Cancelled);
            }
        }
    }

    /**
     * @notice Allocates approved funds from the DARL treasury to a project's dedicated escrow.
     * @param _projectId The ID of the project to allocate funds for.
     */
    function allocateProjectFunds(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Approved, "Project is not in Approved state");
        require(project.fundsInEscrow == 0, "Funds already allocated");
        require(address(this).balance >= project.budgetAmount, "Insufficient funds in DARL treasury");

        // Transfer funds from contract treasury to project escrow within the contract
        project.fundsInEscrow = project.budgetAmount;
        // Optionally, could set project state to 'Active' here if allocation is the trigger
        if (project.currentMilestoneIndex == 0) project.state = ProjectState.Active;
        emit ProjectFundsAllocated(_projectId, project.budgetAmount);
    }

    /**
     * @notice Allows a project lead to submit completion details for a milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being submitted (0-indexed).
     * @param _ipfsResultHash IPFS hash for the milestone's results/report.
     * @param _verificationProofHash An optional hash of a verifiable computation proof (e.g., ZKP).
     * @param _verificationMethod The method used for verification (e.g., ManualCommunity, ZeroKnowledgeProof).
     */
    function submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string calldata _ipfsResultHash, bytes32 _verificationProofHash, uint8 _verificationMethod) external onlyRegisteredResearcher nonReentrant {
        Project storage project = projects[_projectId];
        require(project.projectLead == msg.sender, "Only project lead can submit milestones");
        require(project.state == ProjectState.Active || project.state == ProjectState.Approved, "Project not active or approved");
        require(_milestoneIndex == project.currentMilestoneIndex, "Only current milestone can be submitted");
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.PendingSubmission, "Milestone not in Pending Submission state");
        require(bytes(_ipfsResultHash).length > 0, "Milestone result hash cannot be empty");

        milestone.ipfsResultHash = _ipfsResultHash;
        milestone.verificationProofHash = _verificationProofHash;
        milestone.verificationMethod = VerificationMethod(_verificationMethod);
        milestone.state = MilestoneState.Submitted;
        milestone.validationTimestamp = block.timestamp; // Start validation period

        researchers[msg.sender].lastActivityTimestamp = block.timestamp;

        emit MilestoneCompletionSubmitted(_projectId, _milestoneIndex, _ipfsResultHash);
    }

    /**
     * @notice Allows the project lead to nominate a specific researcher to validate a milestone.
     * @dev This can also be proposed by DAO governance for critical milestones.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _validator The address of the researcher nominated as validator.
     */
    function nominateProjectValidator(uint256 _projectId, uint256 _milestoneIndex, address _validator) external onlyRegisteredResearcher {
        Project storage project = projects[_projectId];
        require(project.projectLead == msg.sender, "Only project lead can nominate validator");
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");
        require(project.milestones[_milestoneIndex].state == MilestoneState.Submitted, "Milestone not submitted for validation");
        require(researchers[_validator].isRegistered, "Validator must be a registered researcher");
        require(_calculateReputationScore(_validator) >= MIN_REPUTATION_FOR_VOTING, "Validator must have minimum reputation");
        require(project.projectLead != _validator, "Project lead cannot be validator for their own project");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        milestone.nominatedValidator = _validator;

        emit ProjectValidatorNominated(_projectId, _milestoneIndex, _validator);
    }

    /**
     * @notice Allows a designated validator or community members to validate a milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _isValid True if the milestone is valid, false otherwise.
     */
    function validateMilestone(uint256 _projectId, uint252 _milestoneIndex, bool _isValid) external onlyRegisteredResearcher nonReentrant {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.Submitted || milestone.state == MilestoneState.PendingValidation, "Milestone not ready for validation");
        require(block.timestamp <= milestone.validationTimestamp.add(milestoneValidationPeriod), "Validation period has expired");

        bool isDesignatedValidator = milestone.nominatedValidator == msg.sender;
        // For community validation, a full voting mechanism like project proposals would be needed here.
        // For this example, we'll allow designated validator OR a high-reputation community member to validate.
        bool isHighReputationValidator = _calculateReputationScore(msg.sender) >= MIN_REPUTATION_FOR_ATTESTATION;

        require(isDesignatedValidator || isHighReputationValidator, "Not authorized to validate this milestone");

        milestone.isValidated = _isValid;
        milestone.state = _isValid ? MilestoneState.Validated : MilestoneState.PendingValidation; // If false, stays pending for other validators or dispute
        milestone.validationTimestamp = block.timestamp; // Update timestamp for dispute period

        // Adjust validator's reputation (simplified)
        researchers[msg.sender].reputation = _isValid ? researchers[msg.sender].reputation.add(10) : researchers[msg.sender].reputation.sub(5);
        researchers[msg.sender].lastActivityTimestamp = block.timestamp;

        emit MilestoneValidated(_projectId, _milestoneIndex, msg.sender, _isValid);
    }

    /**
     * @notice Allows a researcher or the project lead to dispute a milestone validation decision.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function disputeMilestoneValidation(uint256 _projectId, uint256 _milestoneIndex) external onlyRegisteredResearcher nonReentrant {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.Validated || milestone.state == MilestoneState.Submitted || milestone.state == MilestoneState.PendingValidation, "Milestone not in a valid state to dispute");
        require(block.timestamp <= milestone.validationTimestamp.add(disputeResolutionPeriod), "Dispute period has expired");
        require(msg.sender == project.projectLead || _calculateReputationScore(msg.sender) >= MIN_REPUTATION_FOR_VOTING, "Only project lead or reputable researcher can dispute");

        milestone.state = MilestoneState.Disputed;
        // This would trigger a specific dispute resolution process (e.g., arbitration DAO, community re-vote)
        // For this example, just marking it as disputed.
        emit MilestoneDisputed(_projectId, _milestoneIndex, msg.sender);
    }

    /**
     * @notice Releases payment for a successfully validated milestone to the project lead.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function releaseMilestonePayment(uint256 _projectId, uint256 _milestoneIndex) external nonReentrant {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.Validated, "Milestone not validated");
        require(project.currentMilestoneIndex == _milestoneIndex, "Previous milestones not completed or paid");
        require(project.fundsInEscrow >= milestone.paymentAmount, "Insufficient funds in project escrow for this milestone");

        project.fundsInEscrow = project.fundsInEscrow.sub(milestone.paymentAmount);
        milestone.state = MilestoneState.Paid;
        project.currentMilestoneIndex = project.currentMilestoneIndex.add(1);

        (bool success,) = payable(project.projectLead).call{value: milestone.paymentAmount}("");
        require(success, "Failed to send milestone payment");

        researchers[project.projectLead].reputation = researchers[project.projectLead].reputation.add(50); // Reputation boost for project lead
        researchers[project.projectLead].lastActivityTimestamp = block.timestamp;

        emit MilestonePaymentReleased(_projectId, _milestoneIndex, milestone.paymentAmount);

        if (project.currentMilestoneIndex == project.milestones.length) {
            project.state = ProjectState.Completed;
            emit ProjectStateChanged(_projectId, ProjectState.Completed);
            if (project.fundsInEscrow > 0) { // Return any remaining funds to treasury
                 (bool successReturn,) = payable(address(this)).call{value: project.fundsInEscrow}("");
                 require(successReturn, "Failed to return remaining project funds to treasury");
                 project.fundsInEscrow = 0;
            }
        }
    }

    /**
     * @notice Initiates a governance vote to cancel an active project.
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) external onlyRegisteredResearcher nonReentrant {
        Project storage project = projects[_projectId];
        require(project.state != ProjectState.Completed && project.state != ProjectState.Cancelled, "Project already completed or cancelled.");
        
        uint256 proposalId = nextGovernanceProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposalType = ProposalType.ProjectCancellation;
        proposal.descriptionHash = string(abi.encodePacked("Proposal to cancel project ", _projectId.toString()));
        proposal.targetAddress = address(this); // The target for the execution call
        proposal.callData = abi.encode(_projectId); // Pass the project ID as call data for execution
        proposal.creationTime = block.timestamp;
        proposal.votingDeadline = block.timestamp.add(governanceVotingPeriod);
        proposal.state = ProposalState.Active;

        emit GovernanceProposalCreated(proposalId, ProposalType.ProjectCancellation, proposal.descriptionHash);
    }


    // --- IV. Knowledge Base & IP Management ---

    /**
     * @notice Registers metadata for a research output (e.g., paper, dataset, code).
     * @param _projectId The ID of the project this output belongs to.
     * @param _ipfsOutputHash IPFS hash of the actual research output.
     * @param _keywords Keywords to categorize the output.
     * @param _isPublic True if the output is publicly accessible, false if access controlled.
     */
    function publishResearchOutput(uint256 _projectId, string calldata _ipfsOutputHash, string[] calldata _keywords, bool _isPublic) external onlyRegisteredResearcher nonReentrant {
        Project storage project = projects[_projectId];
        require(project.projectLead == msg.sender, "Only project lead can publish outputs for their project");
        require(project.state == ProjectState.Completed || project.state == ProjectState.Active, "Project must be active or completed to publish output");
        require(bytes(_ipfsOutputHash).length > 0, "Output hash cannot be empty");

        uint256 outputId = nextResearchOutputId++;
        ResearchOutput storage output = researchOutputs[outputId];
        output.id = outputId;
        output.projectId = _projectId;
        output.ipfsOutputHash = _ipfsOutputHash;
        output.keywords = _keywords;
        output.isPublic = _isPublic;
        output.publisher = msg.sender;
        output.publishTime = block.timestamp;
        output.hasBeenInfringed = false;

        // If not public, grant access to the publisher by default
        if (!_isPublic) {
            output.grantedAccess[msg.sender] = true;
        }

        researchers[msg.sender].lastActivityTimestamp = block.timestamp;

        emit ResearchOutputPublished(outputId, _projectId, _ipfsOutputHash, _isPublic);
    }

    /**
     * @notice Grants specific on-chain access to a private research output.
     * @dev This could be for a specific decryption key or viewing permission for off-chain content.
     * @param _outputId The ID of the research output.
     * @param _grantee The address to grant access to.
     */
    function grantIPAccess(uint256 _outputId, address _grantee) external onlyRegisteredResearcher nonReentrant {
        ResearchOutput storage output = researchOutputs[_outputId];
        require(output.publisher == msg.sender, "Only the publisher can grant access");
        require(!output.isPublic, "Output is public, no access grant needed");
        require(!output.grantedAccess[_grantee], "Access already granted");

        output.grantedAccess[_grantee] = true;
        researchers[msg.sender].lastActivityTimestamp = block.timestamp;

        emit IPAccessGranted(_outputId, _grantee);
    }

    /**
     * @notice Allows reporting an IP infringement related to a published research output.
     * @dev This records the report on-chain. Actual dispute resolution would typically follow off-chain,
     *      potentially leveraging DARL's governance for arbitration.
     * @param _outputId The ID of the research output being infringed.
     * @param _infringementDetailsHash IPFS hash pointing to details of the infringement.
     */
    function reportIPInfringement(uint256 _outputId, string calldata _infringementDetailsHash) external onlyRegisteredResearcher nonReentrant {
        ResearchOutput storage output = researchOutputs[_outputId];
        require(bytes(_infringementDetailsHash).length > 0, "Infringement details hash cannot be empty");
        require(output.id == _outputId, "Research output does not exist");

        output.hasBeenInfringed = true; // Mark the output as having an infringement report
        researchers[msg.sender].lastActivityTimestamp = block.timestamp;

        emit IPInfringementReported(_outputId, _infringementDetailsHash);
    }

    // --- V. Treasury & Funding ---

    /**
     * @notice Allows anyone to donate native currency (ETH) to the DARL treasury.
     */
    function donateToTreasury() external payable nonReentrant {
        require(msg.value > 0, "Donation amount must be greater than zero");
        // Funds are directly sent to the contract address's balance.
        emit FundsDonated(msg.sender, msg.value);
    }

    /**
     * @notice Allows researchers to request a general grant from the treasury.
     * @dev Subject to governance approval via a TreasuryGrant proposal.
     * @param _requestDetailsHash IPFS hash for detailed grant request.
     * @param _amount The amount of native currency requested.
     */
    function requestTreasuryGrant(string calldata _requestDetailsHash, uint256 _amount) external onlyRegisteredResearcher nonReentrant hasMinReputation(MIN_REPUTATION_FOR_VOTING) {
        require(bytes(_requestDetailsHash).length > 0, "Request details hash cannot be empty");
        require(_amount > 0, "Grant amount must be greater than zero");

        uint256 proposalId = nextGovernanceProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposalType = ProposalType.TreasuryGrant;
        proposal.descriptionHash = _requestDetailsHash;
        proposal.targetAddress = msg.sender; // The recipient of the grant
        proposal.value = _amount;
        proposal.creationTime = block.timestamp;
        proposal.votingDeadline = block.timestamp.add(governanceVotingPeriod);
        proposal.state = ProposalState.Active;

        researchers[msg.sender].lastActivityTimestamp = block.timestamp;

        emit GovernanceProposalCreated(proposalId, ProposalType.TreasuryGrant, _requestDetailsHash);
        emit TreasuryGrantRequested(proposalId, msg.sender, _amount);
    }

    // --- VI. Helper Functions (Views) ---

    /**
     * @notice Returns the current state of a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @return ProposalState The current state.
     */
    function getGovernanceProposalState(uint256 _proposalId) external view returns (ProposalState) {
        return governanceProposals[_proposalId].state;
    }

    /**
     * @notice Returns the current state of a project.
     * @param _projectId The ID of the project.
     * @return ProjectState The current state.
     */
    function getProjectState(uint256 _projectId) external view returns (ProjectState) {
        return projects[_projectId].state;
    }

    /**
     * @notice Returns the details of a project milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @return Milestone struct details.
     */
    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex) external view returns (Milestone memory) {
        require(_projectId < nextProjectId, "Project does not exist");
        require(_milestoneIndex < projects[_projectId].milestones.length, "Milestone index out of bounds");
        return projects[_projectId].milestones[_milestoneIndex];
    }

    /**
     * @notice Gets all skill attestations for a given researcher and skill tag.
     * @param _researcher The address of the researcher.
     * @param _skillTag The skill tag.
     * @return An array of SkillAttestation structs.
     */
    function getSkillAttestations(address _researcher, string calldata _skillTag) external view returns (SkillAttestation[] memory) {
        return skillAttestations[_researcher][_skillTag];
    }

    // Fallback and Receive functions:
    // These allow the contract to receive native currency (ETH) implicitly,
    // useful for donations or unspecified transfers.
    receive() external payable {
        emit FundsDonated(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FundsDonated(msg.sender, msg.value);
    }
}
```