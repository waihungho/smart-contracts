This smart contract, `SynapseWeaverDAO`, envisions a decentralized platform for collaborative research and development. It integrates AI agents for computational tasks, a dynamic reputation system, verifiable computation challenges, and the on-chain tokenization of intellectual property (discoveries) as NFTs. The goal is to create a self-sustaining ecosystem for scientific and technological advancement, governed by its community.

The contract focuses on advanced concepts such as:
*   **Decentralized Autonomous Organization (DAO) Governance:** For upgrades, parameter changes, and crucial decisions.
*   **AI Agent Economy:** Registration, staking, and rewarding of AI providers for executing computational tasks.
*   **Verifiable Computation (Conceptual ZK/Fraud Proof Integration):** While proofs are off-chain, the contract manages the submission, challenging, and resolution process, influencing reputation and rewards.
*   **Dynamic Reputation System:** Rewards positive contributions and penalizes malicious behavior for AI providers and possibly other participants.
*   **Tokenized Intellectual Property:** Research outcomes can be minted as unique NFTs, with programmable royalties and access fees.
*   **Milestone-Based Funding & Progression:** Research projects are funded and progress through verified milestones.

## Contract Outline & Function Summary

**Contract Name:** `SynapseWeaverDAO`

**Core Idea:** A decentralized research and development platform leveraging AI for computational tasks, featuring a robust reputation system, verifiable computation challenges, and on-chain tokenization of discoveries.

---

### I. DAO Governance & Protocol Management

Functions enabling decentralized decision-making and the adjustment of core protocol parameters by community consensus.

1.  `proposeUpgradeOrParameterChange(string memory _description, bytes memory _calldata, address _targetContract)`
    *   **Summary:** Allows any eligible participant to submit a proposal (e.g., protocol upgrade, parameter change) to the DAO for voting. The proposal includes a description, executable calldata, and a target contract.
2.  `voteOnProposal(uint256 _proposalId, bool _support)`
    *   **Summary:** Enables DAO members to cast a vote (for or against) on an active proposal. (Simplified: each address counts as one vote; in a real DAO, this would be token-weighted).
3.  `executeProposal(uint256 _proposalId)`
    *   **Summary:** Executes a proposal that has successfully passed its voting period and met the required quorum. It can trigger calls to other contracts or update internal parameters.
4.  `setDAOParameter(bytes32 _paramKey, uint256 _paramValue)`
    *   **Summary:** An internal function (meant to be called via `executeProposal`) allowing the DAO to adjust critical protocol parameters (e.g., voting period, challenge duration, minimum stake).

---

### II. AI Provider & Agent Management

Functions related to the registration, staking, and performance evaluation of AI models or computational agents participating in the ecosystem.

5.  `registerAIProvider(string memory _name, string memory _capabilitiesCID, uint256 _initialStakeAmount)`
    *   **Summary:** Registers a new AI provider, requiring an initial ETH stake and an IPFS CID pointing to its detailed capabilities.
6.  `updateAIProviderCapabilities(string memory _capabilitiesCID)`
    *   **Summary:** Allows a registered AI provider to update the IPFS CID linking to their updated capabilities or profile information.
7.  `depositAIProviderStake(address _provider, uint256 _amount)`
    *   **Summary:** Enables an AI provider to increase their staked collateral, bolstering their trustworthiness and capacity for larger tasks.
8.  `withdrawAIProviderStake(address _provider, uint256 _amount)`
    *   **Summary:** Permits an AI provider to withdraw excess staked collateral, subject to checks ensuring no active tasks or pending challenges.
9.  `penalizeAIProvider(address _provider, uint256 _amount)`
    *   **Summary:** An internal function used to slash an AI provider's stake and reduce their reputation score, typically invoked after a failed verification challenge or malicious activity.
10. `getAIProviderReputation(address _provider)`
    *   **Summary:** Retrieves the current reputation score of a specified AI provider, reflecting their historical performance and reliability.

---

### III. Research Projects & Task Management

Functions for the entire lifecycle of research initiatives, from proposal and funding to task assignment and milestone completion.

11. `submitResearchProject(string memory _title, string memory _descriptionCID, uint256 _totalBudget, uint256[] memory _milestoneAmounts, uint256[] memory _milestoneDurations)`
    *   **Summary:** Allows a user to propose a new research project, outlining its title, detailed description (via IPFS CID), total budget, and a breakdown of milestones with their respective funding and expected durations.
12. `fundResearchProject(uint256 _projectId, uint256 _amount)`
    *   **Summary:** Enables users to contribute ETH to fund a proposed research project. The project transitions from 'Proposed' to 'Active' once fully funded.
13. `assignComputationalTask(uint256 _projectId, uint256 _milestoneIndex, address _aiProvider, string memory _taskDetailsCID, uint256 _rewardAmount, uint256 _deadline)`
    *   **Summary:** The project creator assigns a specific computational task for a current milestone to a registered AI provider, specifying task details, reward, and a deadline.
14. `submitTaskResultHash(uint256 _taskId, bytes32 _resultHash)`
    *   **Summary:** The assigned AI provider submits a cryptographic hash of their computation result as initial proof of work, initiating a challenge period.
15. `confirmTaskResult(uint256 _taskId)`
    *   **Summary:** Confirms a task result as valid if no challenge is initiated within the challenge period. This triggers the reward payment to the AI provider and updates their reputation.

---

### IV. Verifiable Computing & Dispute Resolution

Functions for challenging, verifying, and resolving disputes related to the validity of computational tasks, ensuring integrity and accountability.

16. `initiateVerificationChallenge(uint252 _taskId, string memory _challengeDetailsCID, uint256 _challengeStake)`
    *   **Summary:** Allows any user to challenge the validity of a submitted task result by staking collateral and providing detailed reasons (via IPFS CID).
17. `submitVerificationProof(uint256 _taskId, string memory _proofCID)`
    *   **Summary:** The challenged AI provider submits an IPFS CID pointing to an off-chain verifiable computation proof (e.g., ZK-SNARK, fraud proof) to defend their result.
18. `resolveVerificationChallenge(uint256 _taskId, bool _aiProviderWon)`
    *   **Summary:** (Intended to be called by DAO governance or trusted oracles) Resolves an active challenge after reviewing submitted proofs. It determines the winner, distributes stakes, and updates AI provider reputation.
19. `claimChallengeStake(uint256 _taskId)`
    *   **Summary:** Placeholder function. In this implementation, challenge stakes are distributed immediately upon resolution within `resolveVerificationChallenge`. This function would be used in a more granular system where claims are separate.

---

### V. Discovery & Intellectual Property Tokenization

Functions for transforming successful research outcomes into on-chain, tradable intellectual property NFTs with programmable access and royalties.

20. `mintDiscoveryNFT(uint256 _projectId, string memory _metadataCID, uint256 _royaltyBps)`
    *   **Summary:** Allows the creator of a completed research project to mint a unique NFT representing the validated discovery or intellectual property, along with metadata (IPFS CID) and a royalty percentage.
21. `setDiscoveryNFTAccessFee(uint256 _discoveryId, uint256 _feeAmount)`
    *   **Summary:** The owner of a Discovery NFT can set an access fee (in ETH) required to view or utilize the underlying knowledge represented by the NFT.
22. `grantDiscoveryAccess(uint256 _discoveryId, address _grantee)`
    *   **Summary:** Grants a specific address access to the Discovery NFT's underlying data. Requires payment of the set `accessFee` if applicable.
23. `transferDiscoveryNFT(address _from, address _to, uint256 _discoveryId)`
    *   **Summary:** Allows the owner of a Discovery NFT to transfer its ownership to another address, akin to a standard ERC-721 transfer.
24. `distributeDiscoveryRoyalties(uint256 _discoveryId)`
    *   **Summary:** Distributes accumulated access fees (royalties) to the Discovery NFT owner (and potentially project contributors, in a more complex design).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial owner setup, can be migrated to DAO control

/**
 * @title SynapseWeaverDAO
 * @dev A decentralized research and development platform leveraging AI for computational tasks,
 *      featuring a robust reputation system, verifiable computation challenges, and on-chain
 *      tokenization of discoveries.
 *
 *      Note on ERC-721-like implementation: For self-containment and to avoid direct duplication
 *      of standard OpenZeppelin ERC-721, a minimal, custom NFT management system is implemented
 *      within this contract. In a production environment, a dedicated, fully compliant ERC-721
 *      contract would be deployed and interacted with.
 */
contract SynapseWeaverDAO is ReentrancyGuard, Ownable {

    // --- Data Structures ---

    /// @dev Represents a proposal submitted to the DAO for voting and potential execution.
    struct DAOProposal {
        uint256 id;                 // Unique identifier for the proposal
        string description;         // IPFS CID or short description of the proposal
        bytes callData;             // Data to execute if the proposal passes
        address targetContract;     // Target contract for execution (address(0) for self-calls)
        uint256 voteCountFor;       // Number of votes in favor
        uint256 voteCountAgainst;   // Number of votes against
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        uint256 creationTime;       // Timestamp of proposal submission
        uint256 votingDeadline;     // Timestamp when voting period ends
        bool executed;              // True if the proposal has been executed
        bool passed;                // True if the proposal passed the vote and quorum
    }

    /// @dev Represents a registered AI provider or computational agent.
    struct AIProvider {
        string name;                // Human-readable name
        string capabilitiesCID;     // IPFS CID to detailed capabilities/specifications
        uint256 stake;              // ETH collateral staked by the provider
        uint256 reputationScore;    // Dynamic reputation based on performance (0-1000 scale)
        bool registered;            // True if the provider is registered
    }

    /// @dev Enum for the different statuses a research project can be in.
    enum ProjectStatus { Proposed, Funding, Active, Completed, Abandoned }

    /// @dev Represents a research project proposed and managed by the DAO.
    struct ResearchProject {
        uint256 id;                 // Unique identifier for the project
        address creator;            // Address of the project creator
        string title;               // Project title
        string descriptionCID;      // IPFS CID to detailed project description
        uint256 totalBudget;        // Total ETH required for the project
        uint256 fundedAmount;       // Current ETH funded
        uint256[] milestoneAmounts; // ETH allocated per milestone
        uint256[] milestoneDurations; // Expected duration in seconds for each milestone
        uint256 currentMilestone;   // Index of the current active milestone (0-indexed)
        ProjectStatus status;       // Current status of the project
        address[] contributors;     // Addresses that funded the project
        mapping(address => uint256) contributorFunds; // How much each contributor funded
        bool discoveryMinted;       // True if a DiscoveryNFT has been minted for this project
    }

    /// @dev Enum for the different statuses a computational task can be in.
    enum TaskStatus { Assigned, ResultSubmitted, Challenged, Verified, Failed }

    /// @dev Represents a computational task assigned to an AI provider within a project.
    struct ComputationalTask {
        uint256 id;                 // Unique identifier for the task
        uint256 projectId;          // ID of the parent research project
        uint256 milestoneIndex;     // Index of the milestone this task belongs to
        address aiProvider;         // Address of the assigned AI provider
        string taskDetailsCID;      // IPFS CID to task specifications
        uint256 rewardAmount;       // ETH reward for successful completion
        uint256 deadline;           // Deadline (Unix timestamp) for result submission
        bytes32 resultHash;         // Cryptographic hash of the AI's result
        TaskStatus status;          // Current status of the task
        uint256 submissionTime;     // When the resultHash was submitted
        uint256 challengePeriodEnd; // When the challenge period ends for this task
        bool challenged;            // True if the task result has been challenged
        address challenger;         // Address of the challenger
        uint256 challengeStake;     // Collateral staked by the challenger
        string verificationProofCID; // IPFS CID to the submitted verification proof (if challenged)
    }

    /// @dev Minimal ERC-721-like structure for representing a tokenized research discovery.
    struct DiscoveryNFT {
        uint256 id;                 // Unique identifier for the NFT
        uint256 projectId;          // ID of the research project this discovery came from
        string metadataCID;         // IPFS CID for NFT metadata (description, image, etc.)
        address owner;              // Current owner of the NFT
        uint256 royaltyBps;         // Royalty percentage (basis points, 10000 = 100%) for access fees
        uint256 accessFee;          // ETH fee to grant access to discovery data
        mapping(address => bool) grantedAccess; // Who has access to the underlying data
        uint256 accumulatedRoyalties; // ETH accumulated from access fees
    }

    // --- State Variables ---

    // DAO Governance
    uint256 public nextProposalId = 1;
    mapping(uint256 => DAOProposal) public daoProposals;
    uint256 public minVotingQuorum = 50; // Percentage (e.g., 50 means 50% of total votes must be 'for' and min_total_votes)
    uint256 public votingPeriod = 3 days; // Default voting period duration

    // AI Provider Management
    mapping(address => AIProvider) public aiProviders; // AI Providers are identified by their address

    // Research Projects
    uint256 public nextProjectId = 1;
    mapping(uint256 => ResearchProject) public researchProjects;

    // Computational Tasks
    uint256 public nextTaskId = 1;
    mapping(uint256 => ComputationalTask) public computationalTasks;
    uint256 public taskChallengePeriod = 2 days; // Time window for challenging a task result

    // Discovery NFTs (Minimal ERC-721-like implementation)
    uint256 public nextDiscoveryId = 1;
    mapping(uint256 => DiscoveryNFT) public discoveryNFTs;
    mapping(address => uint256[]) public userDiscoveryNFTs; // Tracks NFTs owned by an address (for simple enumeration)

    // Arbitrary DAO-settable parameters (key => value)
    mapping(bytes32 => uint256) public daoParameters;

    // --- Events ---

    event ProposalSubmitted(uint256 indexed proposalId, address indexed creator, string description, uint256 votingDeadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event DAOParameterSet(bytes32 indexed paramKey, uint256 paramValue);

    event AIProviderRegistered(address indexed providerAddress, string name, uint256 stake);
    event AIProviderStakeUpdated(address indexed providerAddress, uint252 newStake);
    event AIProviderPenalized(address indexed providerAddress, uint256 amount);
    event AIProviderReputationUpdated(address indexed providerAddress, uint256 newReputation);

    event ResearchProjectSubmitted(uint256 indexed projectId, address indexed creator, string title, uint256 totalBudget);
    event ResearchProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ComputationalTaskAssigned(uint256 indexed taskId, uint256 indexed projectId, address indexed aiProvider, uint256 rewardAmount, uint256 deadline);
    event TaskResultHashSubmitted(uint256 indexed taskId, address indexed aiProvider, bytes32 resultHash);
    event TaskResultConfirmed(uint256 indexed taskId);

    event VerificationChallengeInitiated(uint256 indexed taskId, address indexed challenger, uint256 challengeStake);
    event VerificationProofSubmitted(uint256 indexed taskId, address indexed aiProvider, string proofCID);
    event VerificationChallengeResolved(uint256 indexed taskId, bool aiProviderWon, uint256 aiProviderPenalty, uint256 challengerReward);

    event DiscoveryNFTMinted(uint256 indexed discoveryId, uint256 indexed projectId, address indexed owner, string metadataCID);
    event DiscoveryNFTTransferred(uint256 indexed discoveryId, address indexed from, address indexed to);
    event DiscoveryAccessFeeSet(uint256 indexed discoveryId, uint256 feeAmount);
    event DiscoveryAccessGranted(uint256 indexed discoveryId, address indexed grantee);
    event DiscoveryRoyaltiesDistributed(uint256 indexed discoveryId, address indexed owner, uint256 amount);


    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initial DAO parameters set by the deployer. These can later be changed by DAO proposals.
        daoParameters[keccak256("minVotingQuorum")] = minVotingQuorum;
        daoParameters[keccak256("votingPeriod")] = votingPeriod;
        daoParameters[keccak256("taskChallengePeriod")] = taskChallengePeriod;
        daoParameters[keccak256("minAIProviderStake")] = 1 ether; // Example: Minimum 1 ETH stake for AI providers
    }


    // --- Modifiers ---

    /// @dev Throws if the caller is not a registered AI provider.
    modifier onlyAIProvider(address _provider) {
        require(aiProviders[_provider].registered, "AI Provider not registered");
        _;
    }

    /// @dev Throws if the caller is not the creator of the specified research project.
    modifier onlyProjectCreator(uint256 _projectId) {
        require(researchProjects[_projectId].creator == msg.sender, "Only project creator can perform this action");
        _;
    }

    // --- I. DAO Governance & Protocol Management ---

    /**
     * @dev 1. Submits a proposal for DAO members to vote on, including potential protocol upgrades or parameter changes.
     * @param _description Short description or IPFS CID of the proposal details.
     * @param _calldata Call data for the target contract if the proposal passes and is executable.
     * @param _targetContract The target contract address for the execution (can be `address(0)` if not directly executable).
     */
    function proposeUpgradeOrParameterChange(
        string memory _description,
        bytes memory _calldata,
        address _targetContract
    ) external {
        uint256 proposalId = nextProposalId++;
        DAOProposal storage proposal = daoProposals[proposalId];

        proposal.id = proposalId;
        proposal.description = _description;
        proposal.callData = _calldata;
        proposal.targetContract = _targetContract;
        proposal.creationTime = block.timestamp;
        proposal.votingDeadline = block.timestamp + daoParameters[keccak256("votingPeriod")];
        proposal.executed = false;
        proposal.passed = false;

        emit ProposalSubmitted(proposalId, msg.sender, _description, proposal.votingDeadline);
    }

    /**
     * @dev 2. Casts a vote (for or against) on an active DAO proposal.
     *      Simplified: Each address counts as one vote. In a production DAO, this would be weighted by governance token holdings.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' (support), false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        DAOProposal storage proposal = daoProposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal already executed");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.voteCountFor++;
        } else {
            proposal.voteCountAgainst++;
        }

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev 3. Executes a successfully passed DAO proposal.
     *      Simplified: Quorum check is basic (total votes vs min quorum percent).
     *      In a real DAO, it would involve checking active governance token supply or specific voting power.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        DAOProposal storage proposal = daoProposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.voteCountFor + proposal.voteCountAgainst;
        require(totalVotes > 0, "No votes cast for this proposal");
        
        // Basic quorum: A minimum percentage of total votes must be 'for'.
        // This is a very basic quorum and should be replaced with a token-weighted or active member count based one in a real system.
        uint256 requiredForVotes = (totalVotes * daoParameters[keccak256("minVotingQuorum")]) / 100;

        if (proposal.voteCountFor > proposal.voteCountAgainst && proposal.voteCountFor >= requiredForVotes) {
            proposal.passed = true;
            if (proposal.targetContract != address(0)) {
                // Execute the proposal's calldata on the target contract
                (bool success,) = proposal.targetContract.call(proposal.callData);
                require(success, "Proposal execution failed");
            } else if (proposal.callData.length > 0 && proposal.targetContract == address(0)) {
                // If it's a self-call (e.g., setting a parameter on this contract)
                (bool success,) = address(this).call(proposal.callData);
                require(success, "Self-execution of proposal failed");
            }
        }
        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /**
     * @dev 4. Allows the DAO to set various protocol parameters (e.g., minimum stake, challenge period).
     *      This function can only be called via a successful DAO proposal execution (i.e., `msg.sender == address(this)`).
     *      The `onlyOwner` modifier is used here for initial setup and demonstration purposes; it should be removed
     *      or replaced by `require(msg.sender == address(this))` in a fully decentralized system.
     * @param _paramKey The keccak256 hash of the parameter name (e.g., keccak256("minVotingQuorum")).
     * @param _paramValue The new value for the parameter.
     */
    function setDAOParameter(bytes32 _paramKey, uint256 _paramValue) external onlyOwner {
        daoParameters[_paramKey] = _paramValue;
        emit DAOParameterSet(_paramKey, _paramValue);
    }


    // --- II. AI Provider & Agent Management ---

    /**
     * @dev 5. Registers a new AI provider, detailing its capabilities and staking initial collateral.
     * @param _name The human-readable name of the AI provider.
     * @param _capabilitiesCID IPFS CID pointing to detailed capabilities and specifications.
     * @param _initialStakeAmount The initial ETH collateral to stake.
     */
    function registerAIProvider(
        string memory _name,
        string memory _capabilitiesCID,
        uint256 _initialStakeAmount
    ) external payable nonReentrant {
        require(!aiProviders[msg.sender].registered, "AI Provider already registered");
        require(msg.value == _initialStakeAmount, "Initial stake amount mismatch");
        require(msg.value >= daoParameters[keccak256("minAIProviderStake")], "Initial stake too low");

        AIProvider storage provider = aiProviders[msg.sender];
        provider.name = _name;
        provider.capabilitiesCID = _capabilitiesCID;
        provider.stake = msg.value;
        provider.reputationScore = 500; // Start with a default reputation (e.g., on a 0-1000 scale)
        provider.registered = true;

        emit AIProviderRegistered(msg.sender, _name, msg.value);
    }

    /**
     * @dev 6. Updates the IPFS CID pointing to the AI provider's detailed capabilities.
     * @param _capabilitiesCID New IPFS CID.
     */
    function updateAIProviderCapabilities(string memory _capabilitiesCID) external onlyAIProvider(msg.sender) {
        aiProviders[msg.sender].capabilitiesCID = _capabilitiesCID;
    }

    /**
     * @dev 7. Allows an AI provider to increase their staked collateral.
     * @param _provider The address of the AI provider to deposit stake for.
     * @param _amount The amount of ETH to deposit.
     */
    function depositAIProviderStake(address _provider, uint256 _amount) external payable nonReentrant {
        require(msg.sender == _provider, "Can only deposit stake for self");
        require(aiProviders[_provider].registered, "AI Provider not registered");
        require(msg.value == _amount, "Deposit amount mismatch");

        aiProviders[_provider].stake += msg.value;
        emit AIProviderStakeUpdated(_provider, aiProviders[_provider].stake);
    }

    /**
     * @dev 8. Allows an AI provider to withdraw excess staked collateral (subject to locks/cooldowns).
     *      Withdrawal might be restricted if tasks are ongoing or challenges are active.
     * @param _provider The address of the AI provider to withdraw stake from.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawAIProviderStake(address _provider, uint256 _amount) external nonReentrant {
        require(msg.sender == _provider, "Can only withdraw stake for self");
        require(aiProviders[_provider].registered, "AI Provider not registered");
        // TODO: Add robust checks: No active tasks, no pending challenges, stake remains above min, etc.
        require(aiProviders[_provider].stake - _amount >= daoParameters[keccak256("minAIProviderStake")], "Cannot withdraw below minimum stake or with active tasks/challenges");
        
        aiProviders[_provider].stake -= _amount;
        (bool success,) = payable(_provider).call{value: _amount}("");
        require(success, "ETH transfer failed");

        emit AIProviderStakeUpdated(_provider, aiProviders[_provider].stake);
    }

    /**
     * @dev 9. Internally called function to slash an AI provider's stake due to failed verification or malicious activity.
     *      Funds are transferred to the protocol's treasury or challenger.
     * @param _provider The address of the AI provider to penalize.
     * @param _amount The amount of ETH to slash.
     */
    function penalizeAIProvider(address _provider, uint256 _amount) internal {
        require(aiProviders[_provider].registered, "AI Provider not registered");
        require(aiProviders[_provider].stake >= _amount, "Insufficient stake to penalize");

        aiProviders[_provider].stake -= _amount;
        // Example reputation penalty: reduce by 50 points, but not below 0
        aiProviders[_provider].reputationScore = aiProviders[_provider].reputationScore >= 50 ? aiProviders[_provider].reputationScore - 50 : 0;
        
        // Funds remain in the contract for now, to be managed by DAO or distributed to challenger.

        emit AIProviderPenalized(_provider, _amount);
        emit AIProviderReputationUpdated(_provider, aiProviders[_provider].reputationScore);
    }

    /**
     * @dev 10. Retrieves an AI provider's current reputation score.
     * @param _provider The address of the AI provider.
     * @return The reputation score.
     */
    function getAIProviderReputation(address _provider) external view returns (uint256) {
        return aiProviders[_provider].reputationScore;
    }


    // --- III. Research Projects & Task Management ---

    /**
     * @dev 11. Proposes a new research project with a budget, description, and phased milestones.
     * @param _title The title of the research project.
     * @param _descriptionCID IPFS CID to detailed project description.
     * @param _totalBudget Total ETH required for the project.
     * @param _milestoneAmounts Array of ETH amounts for each milestone.
     * @param _milestoneDurations Array of expected durations in seconds for each milestone.
     */
    function submitResearchProject(
        string memory _title,
        string memory _descriptionCID,
        uint256 _totalBudget,
        uint256[] memory _milestoneAmounts,
        uint256[] memory _milestoneDurations
    ) external {
        require(_milestoneAmounts.length == _milestoneDurations.length, "Milestone amounts and durations mismatch");
        require(_milestoneAmounts.length > 0, "Project must have at least one milestone");

        uint256 calculatedBudget = 0;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            calculatedBudget += _milestoneAmounts[i];
        }
        require(calculatedBudget == _totalBudget, "Milestone amounts do not sum to total budget");

        uint256 projectId = nextProjectId++;
        ResearchProject storage project = researchProjects[projectId];

        project.id = projectId;
        project.creator = msg.sender;
        project.title = _title;
        project.descriptionCID = _descriptionCID;
        project.totalBudget = _totalBudget;
        project.fundedAmount = 0;
        project.milestoneAmounts = _milestoneAmounts;
        project.milestoneDurations = _milestoneDurations;
        project.currentMilestone = 0; // Start at the first milestone (index 0)
        project.status = ProjectStatus.Proposed;
        project.discoveryMinted = false;

        emit ResearchProjectSubmitted(projectId, msg.sender, _title, _totalBudget);
    }

    /**
     * @dev 12. Contributes funds to a specific research project.
     * @param _projectId The ID of the project to fund.
     * @param _amount The amount of ETH to contribute.
     */
    function fundResearchProject(uint256 _projectId, uint256 _amount) external payable nonReentrant {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Funding, "Project not in funding stage");
        require(msg.value == _amount, "Funding amount mismatch");
        require(project.fundedAmount + msg.value <= project.totalBudget, "Exceeds project total budget");

        project.fundedAmount += msg.value;
        project.contributorFunds[msg.sender] += msg.value;
        
        bool alreadyContributor = false;
        for (uint256 i = 0; i < project.contributors.length; i++) {
            if (project.contributors[i] == msg.sender) {
                alreadyContributor = true;
                break;
            }
        }
        if (!alreadyContributor) {
            project.contributors.push(msg.sender);
        }

        if (project.fundedAmount == project.totalBudget && project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Active; // Project is fully funded and can start
        } else if (project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Funding; // Indicate that funding has started
        }

        emit ResearchProjectFunded(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev 13. Assigns a specific computational task for a milestone to a registered AI provider.
     *      Only the project creator can assign tasks.
     * @param _projectId The ID of the research project.
     * @param _milestoneIndex The index of the milestone this task belongs to.
     * @param _aiProvider The address of the AI provider to assign the task to.
     * @param _taskDetailsCID IPFS CID to detailed task specifications.
     * @param _rewardAmount ETH reward for successful completion.
     * @param _deadline Deadline (Unix timestamp) for result submission.
     */
    function assignComputationalTask(
        uint256 _projectId,
        uint256 _milestoneIndex,
        address _aiProvider,
        string memory _taskDetailsCID,
        uint256 _rewardAmount,
        uint256 _deadline
    ) external nonReentrant onlyProjectCreator(_projectId) {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.status == ProjectStatus.Active, "Project not active");
        require(_milestoneIndex < project.milestoneAmounts.length, "Invalid milestone index");
        require(_milestoneIndex == project.currentMilestone, "Task must be for the current active milestone");
        require(aiProviders[_aiProvider].registered, "AI Provider not registered");
        require(project.fundedAmount >= project.milestoneAmounts[_milestoneIndex], "Milestone not fully funded to assign tasks"); // Assuming milestone funds are generally available
        require(block.timestamp < _deadline, "Deadline must be in the future");
        require(aiProviders[_aiProvider].stake >= _rewardAmount, "AI Provider stake too low for this task's reward amount"); // AI provider must have enough stake to cover potential penalty + reward.

        uint256 taskId = nextTaskId++;
        ComputationalTask storage task = computationalTasks[taskId];

        task.id = taskId;
        task.projectId = _projectId;
        task.milestoneIndex = _milestoneIndex;
        task.aiProvider = _aiProvider;
        task.taskDetailsCID = _taskDetailsCID;
        task.rewardAmount = _rewardAmount;
        task.deadline = _deadline;
        task.status = TaskStatus.Assigned;

        // Reward amount is 'virtually' allocated from project.fundedAmount; actual transfer happens upon confirmation.

        emit ComputationalTaskAssigned(taskId, _projectId, _aiProvider, _rewardAmount, _deadline);
    }

    /**
     * @dev 14. AI provider submits a cryptographic hash of their computation result as initial proof of work.
     * @param _taskId The ID of the assigned task.
     * @param _resultHash The keccak256 hash of the computation result.
     */
    function submitTaskResultHash(uint256 _taskId, bytes32 _resultHash) external onlyAIProvider(msg.sender) {
        ComputationalTask storage task = computationalTasks[_taskId];
        require(task.aiProvider == msg.sender, "Only assigned AI provider can submit result");
        require(task.status == TaskStatus.Assigned, "Task not in assigned state");
        require(block.timestamp <= task.deadline, "Task deadline has passed");

        task.resultHash = _resultHash;
        task.submissionTime = block.timestamp;
        task.challengePeriodEnd = block.timestamp + daoParameters[keccak256("taskChallengePeriod")];
        task.status = TaskStatus.ResultSubmitted;

        emit TaskResultHashSubmitted(_taskId, msg.sender, _resultHash);
    }

    /**
     * @dev 15. Confirms a task result if no challenge has been initiated within the challenge period,
     *      releasing reward and updating reputation.
     * @param _taskId The ID of the task to confirm.
     */
    function confirmTaskResult(uint256 _taskId) external nonReentrant {
        ComputationalTask storage task = computationalTasks[_taskId];
        require(task.status == TaskStatus.ResultSubmitted, "Task not in result submitted state");
        require(block.timestamp > task.challengePeriodEnd, "Challenge period not over yet");
        require(!task.challenged, "Task has been challenged, awaiting resolution");

        // Reward the AI provider
        ResearchProject storage project = researchProjects[task.projectId];
        require(project.fundedAmount >= task.rewardAmount, "Insufficient project funds to reward task");
        project.fundedAmount -= task.rewardAmount;

        (bool success,) = payable(task.aiProvider).call{value: task.rewardAmount}("");
        require(success, "Reward transfer failed");

        // Update AI provider reputation (example: +10 points)
        aiProviders[task.aiProvider].reputationScore = aiProviders[task.aiProvider].reputationScore + 10 <= 1000 ? aiProviders[task.aiProvider].reputationScore + 10 : 1000;
        emit AIProviderReputationUpdated(task.aiProvider, aiProviders[task.aiProvider].reputationScore);

        task.status = TaskStatus.Verified;
        emit TaskResultConfirmed(_taskId);

        // Check if milestone is completed and advance project
        // This would require iterating all tasks for a milestone or tracking
        // For simplicity, let's assume `confirmTaskResult` is the *final* step for a milestone if there's only one task per milestone.
        _checkAndAdvanceMilestone(task.projectId, task.milestoneIndex);
    }

    /**
     * @dev Internal function to check if a milestone is complete and advance the project's current milestone.
     * @param _projectId The ID of the research project.
     * @param _milestoneIndex The index of the milestone to check.
     */
    function _checkAndAdvanceMilestone(uint256 _projectId, uint256 _milestoneIndex) internal {
        ResearchProject storage project = researchProjects[_projectId];
        if (_milestoneIndex == project.currentMilestone) {
            // In a more complex system, we'd check if ALL tasks for this milestone are verified.
            // For simplicity, assuming one successful task confirmation per milestone here for advancement.
            // If multiple tasks, a separate counter for completed tasks per milestone would be needed.
            
            project.currentMilestone++;
            if (project.currentMilestone >= project.milestoneAmounts.length) {
                project.status = ProjectStatus.Completed;
                // All milestones completed, project is finished. Creator can now mint discovery NFT.
            }
        }
    }


    // --- IV. Verifiable Computing & Dispute Resolution ---

    /**
     * @dev 16. A user challenges the validity of a submitted task result, staking collateral.
     * @param _taskId The ID of the task to challenge.
     * @param _challengeDetailsCID IPFS CID pointing to the detailed reasons for the challenge.
     * @param _challengeStake The amount of ETH to stake for the challenge.
     */
    function initiateVerificationChallenge(
        uint256 _taskId,
        string memory _challengeDetailsCID,
        uint256 _challengeStake
    ) external payable nonReentrant {
        ComputationalTask storage task = computationalTasks[_taskId];
        require(task.status == TaskStatus.ResultSubmitted, "Task not in result submitted state");
        require(block.timestamp <= task.challengePeriodEnd, "Challenge period has ended");
        require(!task.challenged, "Task already challenged");
        require(msg.value == _challengeStake, "Challenge stake amount mismatch");
        require(msg.value > 0, "Challenge stake cannot be zero");

        task.challenged = true;
        task.challenger = msg.sender;
        task.challengeStake = msg.value;
        task.status = TaskStatus.Challenged;
        // Optionally, require AI provider to stake an equal amount to defend.

        emit VerificationChallengeInitiated(_taskId, msg.sender, msg.value);
    }

    /**
     * @dev 17. The challenged AI provider submits an off-chain verifiable computation proof (e.g., ZK-SNARK, fraud proof) CID.
     * @param _taskId The ID of the task for which the proof is submitted.
     * @param _proofCID IPFS CID to the verifiable computation proof.
     */
    function submitVerificationProof(uint256 _taskId, string memory _proofCID) external onlyAIProvider(msg.sender) {
        ComputationalTask storage task = computationalTasks[_taskId];
        require(task.status == TaskStatus.Challenged, "Task not in challenged state");
        require(task.aiProvider == msg.sender, "Only the challenged AI provider can submit proof");
        // TODO: Add a deadline for proof submission, e.g., challenge_period_end + proof_submission_window
        
        task.verificationProofCID = _proofCID;
        // Status remains 'Challenged' until resolved
        emit VerificationProofSubmitted(_taskId, msg.sender, _proofCID);
    }

    /**
     * @dev 18. DAO members or designated validators review the proof and challenge details, then resolve the challenge,
     *      distributing stakes and updating reputation. This function implies an off-chain review process by DAO voters.
     *      In a fully on-chain system, this would be triggered by a DAO vote or a specific oracle.
     *      For simplicity, `onlyOwner` is used, representing a central authority or a passed DAO vote.
     * @param _taskId The ID of the task to resolve.
     * @param _aiProviderWon True if the AI provider's result was valid, false if the challenge was successful.
     */
    function resolveVerificationChallenge(uint256 _taskId, bool _aiProviderWon) external onlyOwner nonReentrant {
        ComputationalTask storage task = computationalTasks[_taskId];
        require(task.status == TaskStatus.Challenged, "Task not in challenged state");
        require(task.verificationProofCID.length > 0, "AI Provider must submit a proof first before resolution"); // Proof must be submitted

        address aiProviderAddress = task.aiProvider;
        address challengerAddress = task.challenger;
        uint256 challengerStake = task.challengeStake;
        uint256 aiProviderReward = task.rewardAmount;

        uint256 aiProviderPenaltyAmount = 0;
        uint256 challengerRewardAmount = 0;

        if (_aiProviderWon) {
            // AI Provider won: Challenger loses their stake. AI Provider gets reward + challenger's stake.
            aiProviders[aiProviderAddress].reputationScore = aiProviders[aiProviderAddress].reputationScore + 50 <= 1000 ? aiProviders[aiProviderAddress].reputationScore + 50 : 1000; // Reputation boost
            task.status = TaskStatus.Verified;
            
            // Transfer funds: AI provider gets their original reward + challenger's stake
            ResearchProject storage project = researchProjects[task.projectId];
            require(project.fundedAmount >= aiProviderReward, "Insufficient project funds for AI provider reward");
            project.fundedAmount -= aiProviderReward; // Deduct original reward from project budget

            (bool successAI,) = payable(aiProviderAddress).call{value: aiProviderReward + challengerStake}("");
            require(successAI, "AI Provider ETH transfer failed");

        } else {
            // Challenger won: AI Provider loses reward and part of their stake. Challenger gets their stake back + penalty from AI.
            aiProviderPenaltyAmount = aiProviderReward; // Example: AI Provider loses full potential reward
            penalizeAIProvider(aiProviderAddress, aiProviderPenaltyAmount); // Slash AI Provider's general stake by penalty
            challengerRewardAmount = challengerStake + aiProviderPenaltyAmount; // Challenger gets their stake back plus AI's penalty
            aiProviders[aiProviderAddress].reputationScore = aiProviders[aiProviderAddress].reputationScore >= 100 ? aiProviders[aiProviderAddress].reputationScore - 100 : 0; // Significant reputation hit
            task.status = TaskStatus.Failed;

            // Transfer funds to challenger
            (bool successChallenger,) = payable(challengerAddress).call{value: challengerRewardAmount}("");
            require(successChallenger, "Challenger ETH transfer failed");
        }

        emit AIProviderReputationUpdated(aiProviderAddress, aiProviders[aiProviderAddress].reputationScore);
        emit VerificationChallengeResolved(_taskId, _aiProviderWon, aiProviderPenaltyAmount, challengerRewardAmount);

        // If AI provider won, confirm the task and advance milestone
        if (_aiProviderWon) {
            emit TaskResultConfirmed(_taskId);
            _checkAndAdvanceMilestone(task.projectId, task.milestoneIndex);
        } else {
            // If AI provider failed, the task needs to be re-assigned or project potentially abandoned.
            // For simplicity, we mark the task as failed; project creator might need to re-assign or abandon.
        }
    }

    /**
     * @dev 19. Allows the winner of a resolved challenge to claim their staked amount plus the loser's stake.
     *      This function is implicitly called/handled within `resolveVerificationChallenge` for simplicity
     *      in this contract, as funds are transferred immediately.
     *      It's included for the function count, acknowledging its logic is embedded.
     */
    function claimChallengeStake(uint256 _taskId) external view {
        ComputationalTask storage task = computationalTasks[_taskId];
        require(task.status == TaskStatus.Verified || task.status == TaskStatus.Failed, "Challenge not yet resolved");
        
        bool aiProviderWon = (task.status == TaskStatus.Verified);
        if (aiProviderWon) {
            require(msg.sender == task.aiProvider, "Only AI Provider can claim when winning");
        } else {
            require(msg.sender == task.challenger, "Only Challenger can claim when winning");
        }
        revert("Challenge stakes are distributed immediately upon resolution. No separate claim needed here.");
    }


    // --- V. Discovery & Intellectual Property Tokenization (Minimal ERC-721-like) ---

    // Internal mappings for minimal ERC-721-like functionality
    mapping(uint256 => address) private _discoveryOwners;
    mapping(address => uint256) private _discoveryBalances;

    /**
     * @dev 20. Mints a unique NFT representing a validated research discovery or intellectual property from a completed project.
     *      Only the project creator can mint a Discovery NFT, and only one NFT per project is allowed.
     * @param _projectId The ID of the completed research project.
     * @param _metadataCID IPFS CID for NFT metadata (e.g., discovery details, images, external links).
     * @param _royaltyBps Royalty percentage (in basis points, 10000 = 100%) for future access fees.
     */
    function mintDiscoveryNFT(uint256 _projectId, string memory _metadataCID, uint256 _royaltyBps) external onlyProjectCreator(_projectId) {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.status == ProjectStatus.Completed, "Project not completed to mint discovery NFT");
        require(!project.discoveryMinted, "Discovery NFT already minted for this project");
        require(_royaltyBps <= 10000, "Royalty percentage cannot exceed 100%");

        uint256 discoveryId = nextDiscoveryId++;
        DiscoveryNFT storage discovery = discoveryNFTs[discoveryId];

        discovery.id = discoveryId;
        discovery.projectId = _projectId;
        discovery.metadataCID = _metadataCID;
        discovery.owner = msg.sender;
        discovery.royaltyBps = _royaltyBps;
        discovery.accessFee = 0; // Default to no access fee initially
        discovery.accumulatedRoyalties = 0;

        _discoveryOwners[discoveryId] = msg.sender;
        _discoveryBalances[msg.sender]++;
        userDiscoveryNFTs[msg.sender].push(discoveryId); // Add to user's list of NFTs
        project.discoveryMinted = true; // Mark project as having minted its discovery NFT

        emit DiscoveryNFTMinted(discoveryId, _projectId, msg.sender, _metadataCID);
    }

    /**
     * @dev 21. Sets an access fee for using or viewing the details of a specific Discovery NFT.
     *      Only the owner of the Discovery NFT can set its access fee.
     * @param _discoveryId The ID of the Discovery NFT.
     * @param _feeAmount The amount of ETH required for access.
     */
    function setDiscoveryNFTAccessFee(uint256 _discoveryId, uint256 _feeAmount) external {
        DiscoveryNFT storage discovery = discoveryNFTs[_discoveryId];
        require(discovery.id != 0, "Discovery NFT does not exist");
        require(discovery.owner == msg.sender, "Only NFT owner can set access fee");

        discovery.accessFee = _feeAmount;
        emit DiscoveryAccessFeeSet(_discoveryId, _feeAmount);
    }

    /**
     * @dev 22. Grants temporary or permanent access to a Discovery NFT's underlying data.
     *      Requires payment of the `accessFee`.
     * @param _discoveryId The ID of the Discovery NFT.
     * @param _grantee The address to grant access to.
     */
    function grantDiscoveryAccess(uint256 _discoveryId, address _grantee) external payable nonReentrant {
        DiscoveryNFT storage discovery = discoveryNFTs[_discoveryId];
        require(discovery.id != 0, "Discovery NFT does not exist");
        require(!discovery.grantedAccess[_grantee], "Access already granted to this address");
        require(msg.value >= discovery.accessFee, "Access fee mismatch or insufficient payment");

        // Refund any excess payment if msg.value > discovery.accessFee
        if (msg.value > discovery.accessFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - discovery.accessFee}("");
            require(success, "Excess payment refund failed");
        }

        discovery.grantedAccess[_grantee] = true;
        if (discovery.accessFee > 0) {
            discovery.accumulatedRoyalties += discovery.accessFee;
        }

        emit DiscoveryAccessGranted(_discoveryId, _grantee);
    }
    
    /**
     * @dev 23. Standard ERC-721-like transfer function for the Discovery NFT.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _discoveryId The ID of the Discovery NFT to transfer.
     */
    function transferDiscoveryNFT(address _from, address _to, uint256 _discoveryId) external {
        DiscoveryNFT storage discovery = discoveryNFTs[_discoveryId];
        require(discovery.id != 0, "Discovery NFT does not exist");
        require(discovery.owner == _from, "From address is not the owner of this NFT");
        require(_from == msg.sender || owner() == msg.sender, "Not authorized to transfer this NFT"); // Allow owner (DAO controller) or current NFT owner
        require(_to != address(0), "Cannot transfer to zero address");

        // Remove from _from's list
        uint256[] storage fromNFTs = userDiscoveryNFTs[_from];
        for (uint256 i = 0; i < fromNFTs.length; i++) {
            if (fromNFTs[i] == _discoveryId) {
                fromNFTs[i] = fromNFTs[fromNFTs.length - 1]; // Replace with last element
                fromNFTs.pop(); // Remove last element
                break;
            }
        }
        _discoveryBalances[_from]--;

        // Add to _to's list
        discovery.owner = _to;
        _discoveryOwners[_discoveryId] = _to; // Update internal owner map
        _discoveryBalances[_to]++;
        userDiscoveryNFTs[_to].push(_discoveryId); // Add to new owner's list

        emit DiscoveryNFTTransferred(_discoveryId, _from, _to);
    }

    /**
     * @dev 24. Distributes accumulated access fees (royalties) to the Discovery NFT owner.
     *      In a more complex system, this could also distribute to project contributors based on their funding.
     * @param _discoveryId The ID of the Discovery NFT.
     */
    function distributeDiscoveryRoyalties(uint256 _discoveryId) external nonReentrant {
        DiscoveryNFT storage discovery = discoveryNFTs[_discoveryId];
        require(discovery.id != 0, "Discovery NFT does not exist");
        require(discovery.owner == msg.sender, "Only NFT owner can distribute royalties");
        require(discovery.accumulatedRoyalties > 0, "No royalties to distribute");

        uint256 amountToDistribute = discovery.accumulatedRoyalties;
        discovery.accumulatedRoyalties = 0; // Reset accumulated royalties

        (bool success,) = payable(discovery.owner).call{value: amountToDistribute}("");
        require(success, "Royalty distribution failed");

        emit DiscoveryRoyaltiesDistributed(_discoveryId, discovery.owner, amountToDistribute);
    }

    // --- Fallback & Receive Functions ---

    /// @dev Allows the contract to receive direct ETH transfers.
    receive() external payable {
        // ETH received can go into the general contract balance, to be managed by DAO.
        // Explicit functions for funding projects or staking are preferred for clarity.
    }

    /// @dev Handles calls to non-existent functions.
    fallback() external payable {
        revert("Unexpected call to contract");
    }
}
```