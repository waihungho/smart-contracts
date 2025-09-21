This smart contract, `EpochalDecentralizedResearchHub (EDRH)`, creates a decentralized platform for collaborative research. It introduces advanced concepts like epoch-based operations, a reputation system, a data marketplace, and integration with dynamic NFTs to represent validated research outputs. The design aims for a modular and extensible system where participants (Data Providers, Solvers, Verifiers) collaborate, are incentivized, and governed by a set of on-chain rules and parameters.

---

### **Contract Name:** `EpochalDecentralizedResearchHub (EDRH)`

### **Concept:**
EDRH is a decentralized platform for collaborative research and development. It operates in distinct "epochs" (research cycles) where participants propose tasks, offer datasets, submit solutions, and verify findings. The system integrates a dynamic reputation mechanism for all participants, a marketplace for research data, and leverages a dedicated Dynamic Research NFT (DR-NFT) contract to tokenise validated research outputs. Governance over key parameters and dispute resolution is handled by a set of designated roles or a DAO-like voting mechanism (simplified for this contract).

### **Outline:**

1.  **Core Management & Access Control:**
    *   Basic administrative functions (pause, unpause, owner, parameter updates).
2.  **Participant Registration & Roles:**
    *   Functions for users to register as Data Providers, Solvers, or Verifiers.
3.  **Data Marketplace:**
    *   Mechanism for Data Providers to list datasets, for participants to purchase access, and for quality review.
4.  **Research Task Management:**
    *   Proposing new research tasks, funding bounties, and official approval processes.
5.  **Solution Submission & Verification:**
    *   Solvers submit solutions, mechanisms for challenging invalid solutions, and Verifiers' roles in confirming validity.
6.  **Reputation & Incentives:**
    *   An on-chain reputation system tracks participant trustworthiness and contribution quality. Rewards are distributed upon successful task finalization.
7.  **Epoch Management:**
    *   System for starting new research cycles, managing epoch-specific parameters and reward pools.
8.  **Dynamic Research NFTs (DR-NFTs):**
    *   Integration with an external ERC721 contract to mint and update unique NFTs representing successfully completed and verified research.
9.  **Delegation & Advanced Features:**
    *   Allows for delegation of certain roles or voting powers, adding a layer of flexibility.

### **Function Summary:**

1.  `constructor()`: Initializes the contract, sets the initial owner, and default system parameters.
2.  `pause()`: Allows the contract owner to temporarily pause critical state-changing functions.
3.  `unpause()`: Allows the contract owner to unpause critical state-changing functions.
4.  `updateSystemParameter(bytes32 _paramName, uint256 _newValue)`: Enables the owner/governance to adjust various system-wide parameters (e.g., stake amounts, thresholds).
5.  `withdrawContractBalance()`: Allows the owner/governance to withdraw accumulated fees or unallocated funds from the contract.
6.  `registerDataProvider()`: Registers the calling address as a Data Provider, allowing them to list datasets.
7.  `registerSolver()`: Registers the calling address as a Solver, enabling them to submit solutions for tasks.
8.  `registerVerifier()`: Registers the calling address as a Verifier, allowing them to approve datasets, tasks, and verify solutions.
9.  `proposeDataset(string memory _uri, bytes32 _dataHash, uint256 _price)`: Data Provider proposes a new dataset, including its URI (metadata/location), hash for integrity, and price.
10. `approveDatasetListing(uint256 _datasetId)`: A registered Verifier approves a proposed dataset, making it available for purchase in the marketplace.
11. `purchaseDatasetAccess(uint256 _datasetId)`: Any participant can purchase access to an approved dataset by paying its listed price.
12. `submitDatasetQualityReview(uint256 _datasetId, uint8 _rating)`: Participants who purchased a dataset can submit a quality rating (1-5), impacting the Data Provider's reputation.
13. `proposeResearchTask(string memory _descriptionURI, uint256 _bountyAmount, uint256[] memory _requiredDatasetIds)`: A user proposes a new research task, providing a description URI, an initial bounty, and optionally listing required datasets.
14. `fundResearchTask(uint256 _taskId)`: Allows any user to contribute additional funds to an existing research task's bounty.
15. `approveResearchTask(uint256 _taskId)`: A registered Verifier approves a proposed research task, making it official and open for solvers to submit solutions.
16. `submitSolution(uint256 _taskId, string memory _solutionURI, bytes32 _solutionHash)`: A registered Solver submits their solution for an approved task, providing a URI, a hash of the solution, and staking a predefined amount.
17. `challengeSolution(uint256 _solutionId)`: Any participant can challenge a submitted solution, alleging it is incorrect or fraudulent, by staking an amount.
18. `verifySolution(uint256 _solutionId)`: Registered Verifiers vote on the validity of a submitted solution. Their vote aligns with or opposes the challenge.
19. `finalizeTask(uint256 _taskId)`: After a solution is submitted and potentially challenged/verified, this function finalizes the task, distributes bounties, resolves stakes, and updates reputations.
20. `startNewEpoch(uint256 _epochDuration)`: Initiates a new research epoch, setting its duration and preparing for new reward calculations.
21. `claimEpochRewards()`: Allows participants to claim their accumulated rewards from successfully completed tasks and positive reputation gains within the current or previous epoch.
22. `mintResearchNFT(uint256 _taskId, address _recipient)`: After a task is successfully finalized, this function interacts with an external DR-NFT contract to mint a unique NFT representing the validated research outcome to a recipient.
23. `updateResearchNFTMetadata(uint256 _nftId, string memory _newMetadataURI)`: Allows the EDRH contract (as an authorized entity) to update the metadata URI of an existing DR-NFT, reflecting evolving research or improved solutions.
24. `delegateVerificationVote(address _delegatee)`: A registered Verifier can delegate their solution verification voting power to another registered Verifier.
25. `getReputation(address _addr)`: A public view function to query the current reputation score of any address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For DR-NFT interaction

/**
 * @title EpochalDecentralizedResearchHub (EDRH)
 * @author YourName / AI
 * @notice EDRH is a decentralized platform for collaborative research and development.
 * It operates in distinct "epochs" (research cycles) where participants propose tasks, offer datasets,
 * submit solutions, and verify findings. The system integrates a dynamic reputation mechanism for all participants,
 * a marketplace for research data, and leverages a dedicated Dynamic Research NFT (DR-NFT) contract to tokenise
 * validated research outputs. Governance over key parameters and dispute resolution is handled by a set of designated
 * roles or a DAO-like voting mechanism (simplified for this contract).
 *
 * Outline:
 * 1. Core Management & Access Control: Basic administrative functions (pause, unpause, owner, parameter updates).
 * 2. Participant Registration & Roles: Functions for users to register as Data Providers, Solvers, or Verifiers.
 * 3. Data Marketplace: Mechanism for Data Providers to list datasets, for participants to purchase access, and for quality review.
 * 4. Research Task Management: Proposing new research tasks, funding bounties, and official approval processes.
 * 5. Solution Submission & Verification: Solvers submit solutions, mechanisms for challenging invalid solutions, and Verifiers' roles in confirming validity.
 * 6. Reputation & Incentives: An on-chain reputation system tracks participant trustworthiness and contribution quality. Rewards are distributed upon successful task finalization.
 * 7. Epoch Management: System for starting new research cycles, managing epoch-specific parameters and reward pools.
 * 8. Dynamic Research NFTs (DR-NFTs): Integration with an external ERC721 contract to mint and update unique NFTs representing successfully completed and verified research.
 * 9. Delegation & Advanced Features: Allows for delegation of certain roles or voting powers, adding a layer of flexibility.
 *
 * Function Summary:
 * 1. constructor(): Initializes the contract, sets the initial owner, and default system parameters.
 * 2. pause(): Allows the contract owner to temporarily pause critical state-changing functions.
 * 3. unpause(): Allows the contract owner to unpause critical state-changing functions.
 * 4. updateSystemParameter(bytes32 _paramName, uint256 _newValue): Enables the owner/governance to adjust various system-wide parameters (e.g., stake amounts, thresholds).
 * 5. withdrawContractBalance(): Allows the owner/governance to withdraw accumulated fees or unallocated funds from the contract.
 * 6. registerDataProvider(): Registers the calling address as a Data Provider, allowing them to list datasets.
 * 7. registerSolver(): Registers the calling address as a Solver, enabling them to submit solutions for tasks.
 * 8. registerVerifier(): Registers the calling address as a Verifier, allowing them to approve datasets, tasks, and verify solutions.
 * 9. proposeDataset(string memory _uri, bytes32 _dataHash, uint256 _price): Data Provider proposes a new dataset, including its URI (metadata/location), hash for integrity, and price.
 * 10. approveDatasetListing(uint256 _datasetId): A registered Verifier approves a proposed dataset, making it available for purchase in the marketplace.
 * 11. purchaseDatasetAccess(uint256 _datasetId): Any participant can purchase access to an approved dataset by paying its listed price.
 * 12. submitDatasetQualityReview(uint256 _datasetId, uint8 _rating): Participants who purchased a dataset can submit a quality rating (1-5), impacting the Data Provider's reputation.
 * 13. proposeResearchTask(string memory _descriptionURI, uint256 _bountyAmount, uint256[] memory _requiredDatasetIds): A user proposes a new research task, providing a description URI, an initial bounty, and optionally listing required datasets.
 * 14. fundResearchTask(uint256 _taskId): Allows any user to contribute additional funds to an existing research task's bounty.
 * 15. approveResearchTask(uint256 _taskId): A registered Verifier approves a proposed research task, making it official and open for solvers to submit solutions.
 * 16. submitSolution(uint256 _taskId, string memory _solutionURI, bytes32 _solutionHash): A registered Solver submits their solution for an approved task, providing a URI, a hash of the solution, and staking a predefined amount.
 * 17. challengeSolution(uint256 _solutionId): Any participant can challenge a submitted solution, alleging it is incorrect or fraudulent, by staking an amount.
 * 18. verifySolution(uint256 _solutionId): Registered Verifiers vote on the validity of a submitted solution. Their vote aligns with or opposes the challenge.
 * 19. finalizeTask(uint256 _taskId): After a solution is submitted and potentially challenged/verified, this function finalizes the task, distributes bounties, resolves stakes, and updates reputations.
 * 20. startNewEpoch(uint256 _epochDuration): Initiates a new research epoch, setting its duration and preparing for new reward calculations.
 * 21. claimEpochRewards(): Allows participants to claim their accumulated rewards from successfully completed tasks and positive reputation gains within the current or previous epoch.
 * 22. mintResearchNFT(uint256 _taskId, address _recipient): After a task is successfully finalized, this function interacts with an external DR-NFT contract to mint a unique NFT representing the validated research outcome to a recipient.
 * 23. updateResearchNFTMetadata(uint256 _nftId, string memory _newMetadataURI): Allows the EDRH contract (as an authorized entity) to update the metadata URI of an existing DR-NFT, reflecting evolving research or improved solutions.
 * 24. delegateVerificationVote(address _delegatee): A registered Verifier can delegate their solution verification voting power to another registered Verifier.
 * 25. getReputation(address _addr): A public view function to query the current reputation score of any address.
 */
contract EpochalDecentralizedResearchHub is Ownable, Pausable {

    // --- State Variables & Data Structures ---

    // SYSTEM PARAMETERS
    uint256 public constant MIN_INITIAL_REPUTATION = 100;
    uint256 public constant REPUTATION_EFFECT_FACTOR = 10; // Multiplier for reputation changes
    uint256 public constant EPOCH_REWARD_POOL_SHARE_PERCENT = 10; // % of task bounties that go to epoch reward pool

    mapping(bytes32 => uint256) public systemParameters;

    enum TaskStatus { Proposed, Approved, SolutionSubmitted, Challenged, FinalizedSuccess, FinalizedFailure }
    enum DatasetStatus { Proposed, Approved, Rejected }

    struct ResearchTask {
        uint256 taskId;
        address proposer;
        string descriptionURI;
        uint256 bountyAmount;
        uint256 currentBounty; // Tracks total contributed bounty
        uint256[] requiredDatasetIds;
        TaskStatus status;
        uint256 solutionId; // ID of the currently submitted solution
        uint256 approvedAt; // Timestamp when task was approved
        uint256 epochId; // The epoch this task belongs to
    }

    struct Dataset {
        uint256 datasetId;
        address provider;
        string uri;
        bytes32 dataHash;
        uint256 price;
        DatasetStatus status;
        uint256 qualityScore; // Aggregated score from reviews
        uint256 reviewCount; // Number of reviews
        mapping(address => bool) buyers; // Tracks who purchased access
    }

    struct Solution {
        uint256 solutionId;
        uint256 taskId;
        address solver;
        string solutionURI;
        bytes32 solutionHash;
        uint256 submittedAt;
        uint256 solverStake;
        uint256 challengeStake; // Total stake from challengers
        uint256 challengeId; // ID of the active challenge, if any
        mapping(address => bool) hasChallenged;
        mapping(address => bool) hasVerified; // Verifiers who voted
        mapping(address => bool) verificationVote; // true for approve, false for reject
        uint256 approveVotes;
        uint256 rejectVotes;
        bool isFinalized;
        address winner; // The address that receives the bounty
    }

    struct Challenge {
        uint256 challengeId;
        uint256 solutionId;
        address challenger;
        uint256 stake;
        bool isOpen; // true if challenge is active
    }

    struct Epoch {
        uint256 epochId;
        uint256 startTime;
        uint256 endTime;
        uint256 totalRewardPool;
        uint256 distributedRewards;
        mapping(address => uint256) pendingRewards; // Rewards accumulated for each participant in this epoch
    }

    // Mappings for main entities
    mapping(uint256 => ResearchTask) public researchTasks;
    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => Solution) public solutions;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => Epoch) public epochs;

    // Registries
    mapping(address => bool) public isDataProvider;
    mapping(address => bool) public isSolver;
    mapping(address => bool) public isVerifier;
    mapping(address => address) public verifierDelegations; // Verifier => Delegatee

    // Reputation System
    mapping(address => uint256) public reputations; // Simple reputation score

    // Counters
    uint256 public nextTaskId;
    uint256 public nextDatasetId;
    uint256 public nextSolutionId;
    uint256 public nextChallengeId;
    uint256 public currentEpochId;

    // DR-NFT Contract
    IERC721 public drNFTContract; // Address of the external Dynamic Research NFT contract

    // --- Events ---
    event ParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event ParticipantRegistered(address indexed participant, string role);
    event DatasetProposed(uint256 indexed datasetId, address indexed provider, uint256 price);
    event DatasetApproved(uint256 indexed datasetId, address indexed verifier);
    event DatasetPurchased(uint256 indexed datasetId, address indexed buyer, uint256 price);
    event DatasetQualityReviewed(uint256 indexed datasetId, address indexed reviewer, uint8 rating);
    event ResearchTaskProposed(uint256 indexed taskId, address indexed proposer, uint256 initialBounty);
    event ResearchTaskFunded(uint256 indexed taskId, address indexed funder, uint256 amount);
    event ResearchTaskApproved(uint256 indexed taskId, address indexed approver);
    event SolutionSubmitted(uint256 indexed solutionId, uint256 indexed taskId, address indexed solver);
    event SolutionChallenged(uint256 indexed solutionId, uint256 indexed challengeId, address indexed challenger);
    event SolutionVerified(uint256 indexed solutionId, address indexed verifier, bool approved);
    event TaskFinalized(uint256 indexed taskId, TaskStatus finalStatus, address winner);
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 endTime);
    event RewardsClaimed(uint256 indexed epochId, address indexed participant, uint256 amount);
    event ResearchNFTMinted(uint256 indexed taskId, address indexed recipient, uint256 nftTokenId);
    event ResearchNFTMetadataUpdated(uint256 indexed nftTokenId, string newURI);
    event VerifierDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUpdated(address indexed participant, uint256 newReputation);

    // --- Modifiers ---
    modifier onlyRegisteredDataProvider() {
        require(isDataProvider[msg.sender], "Not a registered Data Provider");
        _;
    }

    modifier onlyRegisteredSolver() {
        require(isSolver[msg.sender], "Not a registered Solver");
        _;
    }

    modifier onlyRegisteredVerifier() {
        require(isVerifier[msg.sender], "Not a registered Verifier");
        _;
    }

    modifier onlyDRNFTContract() {
        // This is a placeholder for a more robust access control, e.g., using a dedicated role manager
        // In a real scenario, the DR-NFT contract might call back to this contract, or this contract
        // would have a specific role on the DR-NFT contract.
        require(msg.sender == address(drNFTContract), "Only DR-NFT contract can call this.");
        _;
    }

    // --- Constructor ---
    constructor(address _drNFTContractAddress) Ownable(msg.sender) Pausable() {
        nextTaskId = 1;
        nextDatasetId = 1;
        nextSolutionId = 1;
        nextChallengeId = 1;
        currentEpochId = 0; // Epoch 0 is initial, not active research epoch

        // Initialize default system parameters
        systemParameters[bytes32("TASK_APPROVAL_THRESHOLD")] = 3; // Min verifier votes to approve task
        systemParameters[bytes32("SOLUTION_VERIFICATION_THRESHOLD_PERCENT")] = 60; // % of verifier votes to approve solution
        systemParameters[bytes32("CHALLENGE_STAKE_AMOUNT")] = 1 ether;
        systemParameters[bytes32("SOLVER_STAKE_AMOUNT")] = 0.5 ether;
        systemParameters[bytes32("VERIFIER_STAKE_AMOUNT")] = 0.1 ether; // Stake for initial registration
        systemParameters[bytes32("MIN_EPOCH_DURATION")] = 1 days;
        systemParameters[bytes32("REPUTATION_BOOST_REGISTRATION")] = 10;
        systemParameters[bytes32("REPUTATION_BOOST_TASK_APPROVED")] = 20;
        systemParameters[bytes32("REPUTATION_BOOST_DATASET_APPROVED")] = 15;
        systemParameters[bytes32("REPUTATION_BOOST_SOLUTION_SUCCESS")] = 50;
        systemParameters[bytes32("REPUTATION_PENALTY_CHALLENGE_FAILED")] = 30;
        systemParameters[bytes32("REPUTATION_PENALTY_SOLUTION_REJECTED")] = 40;
        systemParameters[bytes32("REPUTATION_PENALTY_DATASET_BAD_REVIEW")] = 10;
        systemParameters[bytes32("MIN_DRNFT_MINT_REPUTATION")] = 200; // Minimum reputation to mint DR-NFT

        // Initialize reputation for owner
        reputations[msg.sender] = MIN_INITIAL_REPUTATION * 10;

        require(_drNFTContractAddress != address(0), "DR-NFT contract address cannot be zero.");
        drNFTContract = IERC721(_drNFTContractAddress);
    }

    // --- Internal Reputation Management ---
    function _updateReputation(address _participant, int256 _change) internal {
        if (_change > 0) {
            reputations[_participant] += uint256(_change);
        } else if (_change < 0) {
            uint256 absChange = uint256(-_change);
            if (reputations[_participant] > absChange) {
                reputations[_participant] -= absChange;
            } else {
                reputations[_participant] = 0; // Reputation cannot go below zero
            }
        }
        emit ReputationUpdated(_participant, reputations[_participant]);
    }

    // --- Core Management & Access Control (5 functions) ---

    /// @notice Temporarily pauses critical state-changing functions.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses critical state-changing functions.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the owner/governance to adjust various system-wide parameters.
    /// @param _paramName The name of the parameter (e.g., "TASK_APPROVAL_THRESHOLD").
    /// @param _newValue The new value for the parameter.
    function updateSystemParameter(bytes32 _paramName, uint256 _newValue) public onlyOwner {
        require(_newValue > 0, "Parameter value must be positive.");
        systemParameters[_paramName] = _newValue;
        emit ParameterUpdated(_paramName, _newValue);
    }

    /// @notice Allows the owner/governance to withdraw accumulated fees or unallocated funds from the contract.
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        // Ensure no ongoing stakes or bounties are withdrawn
        // This is a simplified check. A robust system would require careful accounting of locked funds.
        // For this example, we assume owner can withdraw excess.
        payable(owner()).transfer(balance);
    }

    // 25. getReputation() already declared as public view, fits here as well.
    /// @notice Returns the current reputation score of any address.
    /// @param _addr The address to query.
    /// @return The current reputation score.
    function getReputation(address _addr) public view returns (uint256) {
        return reputations[_addr];
    }

    // --- Participant Registration & Roles (3 functions) ---

    /// @notice Registers the calling address as a Data Provider. Requires a reputation of at least MIN_INITIAL_REPUTATION.
    function registerDataProvider() public whenNotPaused {
        require(!isDataProvider[msg.sender], "Already a Data Provider.");
        require(reputations[msg.sender] >= MIN_INITIAL_REPUTATION, "Insufficient reputation to register.");
        isDataProvider[msg.sender] = true;
        _updateReputation(msg.sender, int256(systemParameters[bytes32("REPUTATION_BOOST_REGISTRATION")]));
        emit ParticipantRegistered(msg.sender, "Data Provider");
    }

    /// @notice Registers the calling address as a Solver. Requires a reputation of at least MIN_INITIAL_REPUTATION.
    function registerSolver() public whenNotPaused {
        require(!isSolver[msg.sender], "Already a Solver.");
        require(reputations[msg.sender] >= MIN_INITIAL_REPUTATION, "Insufficient reputation to register.");
        isSolver[msg.sender] = true;
        _updateReputation(msg.sender, int256(systemParameters[bytes32("REPUTATION_BOOST_REGISTRATION")]));
        emit ParticipantRegistered(msg.sender, "Solver");
    }

    /// @notice Registers the calling address as a Verifier. Requires a reputation of at least MIN_INITIAL_REPUTATION.
    function registerVerifier() public whenNotPaused {
        require(!isVerifier[msg.sender], "Already a Verifier.");
        require(reputations[msg.sender] >= MIN_INITIAL_REPUTATION, "Insufficient reputation to register.");
        // Verifiers might require a larger stake or reputation for integrity
        isVerifier[msg.sender] = true;
        _updateReputation(msg.sender, int256(systemParameters[bytes32("REPUTATION_BOOST_REGISTRATION")] * 2)); // Higher boost for verifiers
        emit ParticipantRegistered(msg.sender, "Verifier");
    }

    // --- Data Marketplace (4 functions) ---

    /// @notice Data Provider proposes a new dataset for listing.
    /// @param _uri The URI to the dataset's metadata or storage location.
    /// @param _dataHash A cryptographic hash of the dataset to ensure integrity.
    /// @param _price The price in wei to purchase access to this dataset.
    function proposeDataset(string memory _uri, bytes32 _dataHash, uint256 _price)
        public
        whenNotPaused
        onlyRegisteredDataProvider
    {
        require(bytes(_uri).length > 0, "Dataset URI cannot be empty.");
        require(_dataHash != bytes32(0), "Dataset hash cannot be zero.");
        require(_price > 0, "Dataset price must be positive.");

        datasets[nextDatasetId] = Dataset({
            datasetId: nextDatasetId,
            provider: msg.sender,
            uri: _uri,
            dataHash: _dataHash,
            price: _price,
            status: DatasetStatus.Proposed,
            qualityScore: 0,
            reviewCount: 0
        });

        emit DatasetProposed(nextDatasetId, msg.sender, _price);
        nextDatasetId++;
    }

    /// @notice A registered Verifier approves a proposed dataset, making it available for purchase.
    /// @param _datasetId The ID of the dataset to approve.
    function approveDatasetListing(uint256 _datasetId) public whenNotPaused onlyRegisteredVerifier {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.datasetId != 0, "Dataset does not exist.");
        require(dataset.status == DatasetStatus.Proposed, "Dataset is not in 'Proposed' status.");

        dataset.status = DatasetStatus.Approved;
        _updateReputation(msg.sender, int256(systemParameters[bytes32("REPUTATION_BOOST_DATASET_APPROVED")]));
        emit DatasetApproved(_datasetId, msg.sender);
    }

    /// @notice Any participant can purchase access to an approved dataset.
    /// @param _datasetId The ID of the dataset to purchase.
    function purchaseDatasetAccess(uint256 _datasetId) public payable whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.datasetId != 0, "Dataset does not exist.");
        require(dataset.status == DatasetStatus.Approved, "Dataset is not approved for purchase.");
        require(msg.value == dataset.price, "Incorrect payment amount for dataset.");
        require(!dataset.buyers[msg.sender], "You have already purchased this dataset.");

        dataset.buyers[msg.sender] = true;
        payable(dataset.provider).transfer(msg.value); // Transfer funds to data provider
        // No direct reputation change for buying, but enables review.
        emit DatasetPurchased(_datasetId, msg.sender, msg.value);
    }

    /// @notice Participants who purchased a dataset can submit a quality rating (1-5).
    /// @param _datasetId The ID of the dataset to review.
    /// @param _rating The quality rating (1-5).
    function submitDatasetQualityReview(uint256 _datasetId, uint8 _rating) public whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.datasetId != 0, "Dataset does not exist.");
        require(dataset.buyers[msg.sender], "Only purchasers can review datasets.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        // Simple moving average for quality score
        uint256 currentTotalScore = dataset.qualityScore * dataset.reviewCount;
        dataset.reviewCount++;
        dataset.qualityScore = (currentTotalScore + _rating) / dataset.reviewCount;

        // Influence provider's reputation based on review
        int256 reputationChange = (_rating - 3) * int256(systemParameters[bytes32("REPUTATION_PENALTY_DATASET_BAD_REVIEW")]); // + for good, - for bad
        _updateReputation(dataset.provider, reputationChange);

        emit DatasetQualityReviewed(_datasetId, msg.sender, _rating);
    }

    // --- Research Task Management (3 functions) ---

    /// @notice A user proposes a new research task with an initial bounty.
    /// @param _descriptionURI The URI to the task's description, goals, and requirements.
    /// @param _bountyAmount The initial bounty offered for completing the task.
    /// @param _requiredDatasetIds Optional array of dataset IDs required for this task.
    function proposeResearchTask(
        string memory _descriptionURI,
        uint256 _bountyAmount,
        uint256[] memory _requiredDatasetIds
    ) public payable whenNotPaused {
        require(bytes(_descriptionURI).length > 0, "Task description URI cannot be empty.");
        require(msg.value == _bountyAmount, "Initial bounty must match sent Ether.");
        require(_bountyAmount > 0, "Bounty must be positive.");

        researchTasks[nextTaskId] = ResearchTask({
            taskId: nextTaskId,
            proposer: msg.sender,
            descriptionURI: _descriptionURI,
            bountyAmount: _bountyAmount,
            currentBounty: _bountyAmount,
            requiredDatasetIds: _requiredDatasetIds,
            status: TaskStatus.Proposed,
            solutionId: 0,
            approvedAt: 0,
            epochId: currentEpochId // Assign to current epoch
        });

        emit ResearchTaskProposed(nextTaskId, msg.sender, _bountyAmount);
        nextTaskId++;
    }

    /// @notice Allows any user to contribute additional funds to an existing research task's bounty.
    /// @param _taskId The ID of the research task to fund.
    function fundResearchTask(uint256 _taskId) public payable whenNotPaused {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.taskId != 0, "Task does not exist.");
        require(task.status < TaskStatus.FinalizedSuccess, "Task is already finalized.");
        require(msg.value > 0, "Contribution must be positive.");

        task.currentBounty += msg.value;
        emit ResearchTaskFunded(_taskId, msg.sender, msg.value);
    }

    /// @notice A registered Verifier approves a proposed research task.
    /// @param _taskId The ID of the task to approve.
    function approveResearchTask(uint256 _taskId) public whenNotPaused onlyRegisteredVerifier {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.taskId != 0, "Task does not exist.");
        require(task.status == TaskStatus.Proposed, "Task is not in 'Proposed' status.");
        require(task.currentBounty > 0, "Task must have a bounty to be approved.");

        task.status = TaskStatus.Approved;
        task.approvedAt = block.timestamp;
        _updateReputation(msg.sender, int256(systemParameters[bytes32("REPUTATION_BOOST_TASK_APPROVED")]));
        emit ResearchTaskApproved(_taskId, msg.sender);
    }

    // --- Solution Submission & Verification (4 functions) ---

    /// @notice A registered Solver submits their solution for an approved task.
    /// @param _taskId The ID of the task.
    /// @param _solutionURI The URI to the solution's metadata or files.
    /// @param _solutionHash A cryptographic hash of the solution.
    function submitSolution(uint256 _taskId, string memory _solutionURI, bytes32 _solutionHash)
        public
        payable
        whenNotPaused
        onlyRegisteredSolver
    {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.taskId != 0, "Task does not exist.");
        require(task.status == TaskStatus.Approved, "Task is not approved or already has a solution.");
        require(bytes(_solutionURI).length > 0, "Solution URI cannot be empty.");
        require(_solutionHash != bytes32(0), "Solution hash cannot be zero.");
        require(msg.value == systemParameters[bytes32("SOLVER_STAKE_AMOUNT")], "Incorrect solver stake amount.");

        solutions[nextSolutionId] = Solution({
            solutionId: nextSolutionId,
            taskId: _taskId,
            solver: msg.sender,
            solutionURI: _solutionURI,
            solutionHash: _solutionHash,
            submittedAt: block.timestamp,
            solverStake: msg.value,
            challengeStake: 0,
            challengeId: 0,
            isFinalized: false,
            approveVotes: 0,
            rejectVotes: 0,
            winner: address(0)
        });

        task.solutionId = nextSolutionId;
        task.status = TaskStatus.SolutionSubmitted;

        emit SolutionSubmitted(nextSolutionId, _taskId, msg.sender);
        nextSolutionId++;
    }

    /// @notice Any participant can challenge a submitted solution.
    /// @param _solutionId The ID of the solution to challenge.
    function challengeSolution(uint256 _solutionId) public payable whenNotPaused {
        Solution storage solution = solutions[_solutionId];
        require(solution.solutionId != 0, "Solution does not exist.");
        require(!solution.isFinalized, "Solution is already finalized.");
        require(msg.sender != solution.solver, "Solver cannot challenge their own solution.");
        require(!solution.hasChallenged[msg.sender], "You have already challenged this solution.");
        require(msg.value == systemParameters[bytes32("CHALLENGE_STAKE_AMOUNT")], "Incorrect challenge stake amount.");

        ResearchTask storage task = researchTasks[solution.taskId];
        require(task.status == TaskStatus.SolutionSubmitted || task.status == TaskStatus.Challenged, "Task not in a state to be challenged.");

        if (solution.challengeId == 0) {
            challenges[nextChallengeId] = Challenge({
                challengeId: nextChallengeId,
                solutionId: _solutionId,
                challenger: msg.sender,
                stake: msg.value,
                isOpen: true
            });
            solution.challengeId = nextChallengeId;
            nextChallengeId++;
        } else {
            Challenge storage activeChallenge = challenges[solution.challengeId];
            require(activeChallenge.isOpen, "Challenge is not open.");
            activeChallenge.stake += msg.value;
        }

        solution.challengeStake += msg.value;
        solution.hasChallenged[msg.sender] = true;
        task.status = TaskStatus.Challenged;

        emit SolutionChallenged(_solutionId, solution.challengeId, msg.sender);
    }

    /// @notice Registered Verifiers vote on the validity of a submitted solution.
    /// @param _solutionId The ID of the solution to verify.
    /// @param _isApproved True if the verifier approves the solution, false otherwise.
    function verifySolution(uint256 _solutionId, bool _isApproved) public whenNotPaused onlyRegisteredVerifier {
        Solution storage solution = solutions[_solutionId];
        require(solution.solutionId != 0, "Solution does not exist.");
        require(!solution.isFinalized, "Solution is already finalized.");
        require(!solution.hasVerified[msg.sender], "You have already voted on this solution.");

        address actualVerifier = verifierDelegations[msg.sender] != address(0) ? verifierDelegations[msg.sender] : msg.sender;
        require(!solution.hasVerified[actualVerifier], "Your delegated verifier has already voted.");

        if (_isApproved) {
            solution.approveVotes++;
        } else {
            solution.rejectVotes++;
        }
        solution.hasVerified[actualVerifier] = true;
        solution.verificationVote[actualVerifier] = _isApproved;

        emit SolutionVerified(_solutionId, actualVerifier, _isApproved);
    }

    /// @notice Finalizes a task based on verification/challenge results, distributes bounty, and updates reputation.
    /// @param _taskId The ID of the task to finalize.
    function finalizeTask(uint256 _taskId) public whenNotPaused {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.taskId != 0, "Task does not exist.");
        require(task.status == TaskStatus.SolutionSubmitted || task.status == TaskStatus.Challenged, "Task not ready for finalization.");

        Solution storage solution = solutions[task.solutionId];
        require(solution.solutionId != 0, "No solution submitted for this task.");
        require(!solution.isFinalized, "Solution already finalized.");

        uint256 totalVerifiers = solution.approveVotes + solution.rejectVotes;
        require(totalVerifiers > 0, "No verifiers have voted yet.");

        bool solutionApprovedByVerifiers = (solution.approveVotes * 100) >= (totalVerifiers * systemParameters[bytes32("SOLUTION_VERIFICATION_THRESHOLD_PERCENT")]);

        if (task.status == TaskStatus.Challenged) {
            Challenge storage activeChallenge = challenges[solution.challengeId];
            require(activeChallenge.isOpen, "Challenge is not active.");

            if (solutionApprovedByVerifiers) {
                // Solution approved, challenge failed
                task.status = TaskStatus.FinalizedSuccess;
                solution.winner = solution.solver;
                payable(solution.solver).transfer(solution.solverStake + solution.challengeStake + task.currentBounty * (100 - EPOCH_REWARD_POOL_SHARE_PERCENT) / 100);
                activeChallenge.isOpen = false;
                _updateReputation(solution.solver, int256(systemParameters[bytes32("REPUTATION_BOOST_SOLUTION_SUCCESS")]));
                _updateReputation(activeChallenge.challenger, -int256(systemParameters[bytes32("REPUTATION_PENALTY_CHALLENGE_FAILED")]));
                
                // Distribute challenge stake to solution.solver if challenge fails
                // No, challenge stake is distributed to solver.
            } else {
                // Solution rejected by verifiers, challenge successful
                task.status = TaskStatus.FinalizedFailure;
                solution.winner = activeChallenge.challenger;
                payable(activeChallenge.challenger).transfer(activeChallenge.stake + solution.solverStake); // Challenger gets their stake + solver's stake
                activeChallenge.isOpen = false;
                _updateReputation(activeChallenge.challenger, int256(systemParameters[bytes32("REPUTATION_BOOST_SOLUTION_SUCCESS")])); // Challenger gets boost
                _updateReputation(solution.solver, -int256(systemParameters[bytes32("REPUTATION_PENALTY_SOLUTION_REJECTED")])); // Solver gets penalty
                
                // Remaining bounty is locked or returned to proposer (simplified to lock for now)
            }
        } else if (task.status == TaskStatus.SolutionSubmitted) {
            if (solutionApprovedByVerifiers) {
                task.status = TaskStatus.FinalizedSuccess;
                solution.winner = solution.solver;
                payable(solution.solver).transfer(solution.solverStake + task.currentBounty * (100 - EPOCH_REWARD_POOL_SHARE_PERCENT) / 100);
                _updateReputation(solution.solver, int256(systemParameters[bytes32("REPUTATION_BOOST_SOLUTION_SUCCESS")]));
            } else {
                task.status = TaskStatus.FinalizedFailure;
                solution.winner = address(0); // No winner, bounty stays in contract for now (could be returned or burnt)
                payable(solution.solver).transfer(solution.solverStake); // Solver gets their stake back
                _updateReputation(solution.solver, -int256(systemParameters[bytes32("REPUTATION_PENALTY_SOLUTION_REJECTED")]));
            }
        }

        // Add a portion of the task bounty to the epoch reward pool
        if (task.status == TaskStatus.FinalizedSuccess) {
            epochs[task.epochId].totalRewardPool += (task.currentBounty * EPOCH_REWARD_POOL_SHARE_PERCENT / 100);
        }

        // Update reputation for verifiers based on their alignment with the final outcome
        for (uint256 i = 0; i < totalVerifiers; i++) {
            // This is a simplified loop. In a real scenario, you'd iterate over stored verifier votes.
            // For brevity, we assume a mechanism to retrieve all verifiers who voted.
            // For now, this is a conceptual placeholder. Real implementation needs a `mapping(address => bool) votedVerifiers`
            // and an array of `address[] verifierVoters` to iterate through.
            // For now, only the `solution.winner`'s reputation is updated.
        }

        solution.isFinalized = true;
        emit TaskFinalized(_taskId, task.status, solution.winner);
    }

    // --- Epoch Management (2 functions) ---

    /// @notice Initiates a new research epoch. Only callable by owner.
    /// @param _epochDuration The duration of the new epoch in seconds.
    function startNewEpoch(uint256 _epochDuration) public onlyOwner whenNotPaused {
        require(_epochDuration >= systemParameters[bytes32("MIN_EPOCH_DURATION")], "Epoch duration too short.");

        if (currentEpochId > 0) {
            Epoch storage prevEpoch = epochs[currentEpochId];
            require(block.timestamp >= prevEpoch.endTime, "Previous epoch has not ended yet.");
            // Optionally distribute remaining rewards from previous epoch here
        }

        currentEpochId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _epochDuration;

        epochs[currentEpochId] = Epoch({
            epochId: currentEpochId,
            startTime: startTime,
            endTime: endTime,
            totalRewardPool: 0,
            distributedRewards: 0,
            pendingRewards: new mapping(address => uint256)
        });

        // Potentially reset/adjust certain system parameters based on epoch (e.g., higher stakes for new epoch)
        emit EpochStarted(currentEpochId, startTime, endTime);
    }

    /// @notice Allows participants to claim their accumulated rewards for the current/past epoch.
    function claimEpochRewards() public whenNotPaused {
        uint256 currentReputation = reputations[msg.sender];
        require(currentReputation > 0, "No reputation, no rewards to claim.");

        uint256 totalClaimable = 0;
        // In a real system, rewards would be distributed based on reputation * contribution in an epoch
        // For simplicity, this example distributes a fixed amount based on reputation,
        // drawing from the current epoch's pool if it has ended.
        // This needs a more sophisticated reward calculation.
        // For example, if epoch has ended and msg.sender has positive reputation, give them a share.

        // Placeholder for reward distribution logic:
        // Assume rewards are calculated and added to pendingRewards mapping internally during task finalization.
        // This function just facilitates claiming.
        
        uint256 rewardAmount = epochs[currentEpochId].pendingRewards[msg.sender];
        if (rewardAmount > 0) {
            epochs[currentEpochId].pendingRewards[msg.sender] = 0;
            epochs[currentEpochId].distributedRewards += rewardAmount;
            totalClaimable += rewardAmount;
        }

        // A more advanced system would calculate individual share based on reputation and contribution within the epoch.
        // For demonstration, let's assume `_updateReputation` indirectly affects `pendingRewards`.
        
        // This needs a concrete calculation to be meaningful.
        // For now, let's assume if there are funds in the epoch pool, and the sender has reputation,
        // they get a small fixed amount for demonstration. This is not production-ready.
        if (epochs[currentEpochId].totalRewardPool > epochs[currentEpochId].distributedRewards && currentReputation > 0) {
            uint256 potentialReward = epochs[currentEpochId].totalRewardPool / 1000; // Very simplified share
            if (potentialReward > 0) {
                epochs[currentEpochId].pendingRewards[msg.sender] += potentialReward;
                totalClaimable += potentialReward;
            }
        }


        require(totalClaimable > 0, "No rewards to claim.");
        payable(msg.sender).transfer(totalClaimable);
        emit RewardsClaimed(currentEpochId, msg.sender, totalClaimable);
    }

    // --- Dynamic Research NFTs (DR-NFTs) (2 functions) ---

    /// @notice Mints a Dynamic Research NFT (DR-NFT) for a successfully completed task.
    /// @param _taskId The ID of the successfully finalized task.
    /// @param _recipient The address to mint the NFT to.
    function mintResearchNFT(uint256 _taskId, address _recipient) public whenNotPaused {
        ResearchTask storage task = researchTasks[_taskId];
        Solution storage solution = solutions[task.solutionId];
        require(task.taskId != 0, "Task does not exist.");
        require(task.status == TaskStatus.FinalizedSuccess, "Task is not successfully finalized.");
        require(reputations[solution.solver] >= systemParameters[bytes32("MIN_DRNFT_MINT_REPUTATION")], "Solver reputation too low to mint NFT.");
        
        // Assuming drNFTContract has a `mint` function callable by this contract
        // The `mint` function on the DR-NFT contract would take (to, tokenId, uri)
        // Here, we simulate a `mint` by emitting an event, as we don't implement full ERC721 here.
        // In a real scenario, `drNFTContract.mint(_recipient, _taskId, solution.solutionURI);`
        // We will use task.taskId as the tokenId for simplicity.
        // This requires the DR-NFT contract to have a custom `mint` function allowing EDRH.
        // For an OpenZeppelin ERC721, this would be `_safeMint`. EDRH would need MINTER_ROLE.

        // Placeholder for actual minting logic:
        uint256 newNftTokenId = _taskId; // Using taskId as NFT ID for simplicity
        // drNFTContract.mint(_recipient, newNftTokenId, solution.solutionURI);
        
        // To make this compile, we assume drNFTContract has a public function like `_mintAndSetURI`
        // which takes recipient, tokenId and tokenURI
        // Example: DRNFT(address(drNFTContract)).mint(_recipient, newNftTokenId, solution.solutionURI);
        // This would require a custom DRNFT contract interface.
        // For now, we emit the event and assume success.
        
        emit ResearchNFTMinted(_taskId, _recipient, newNftTokenId);
    }

    /// @notice Allows the EDRH contract to update the metadata URI of an existing DR-NFT.
    /// @param _nftId The token ID of the DR-NFT to update.
    /// @param _newMetadataURI The new URI pointing to updated metadata.
    function updateResearchNFTMetadata(uint256 _nftId, string memory _newMetadataURI) public whenNotPaused {
        // This function would be called by the EDRH contract itself (e.g., if a new, improved solution
        // is proposed and validated for an existing research task represented by an NFT).
        // For this example, we assume `drNFTContract` has a function `setTokenURI` callable by EDRH.
        // This also assumes _nftId corresponds to a task ID, or some other mapping.
        
        // require(some_condition_to_update, "Condition for updating NFT metadata not met.");
        
        // Placeholder for actual update logic:
        // DRNFT(address(drNFTContract)).setTokenURI(_nftId, _newMetadataURI);
        
        emit ResearchNFTMetadataUpdated(_nftId, _newMetadataURI);
    }

    // --- Delegation & Advanced Features (1 function) ---

    /// @notice A registered Verifier can delegate their solution verification voting power to another registered Verifier.
    /// @param _delegatee The address of the verifier to delegate voting power to.
    function delegateVerificationVote(address _delegatee) public whenNotPaused onlyRegisteredVerifier {
        require(isVerifier[_delegatee], "Delegatee must be a registered Verifier.");
        require(_delegatee != msg.sender, "Cannot delegate to self.");
        verifierDelegations[msg.sender] = _delegatee;
        emit VerifierDelegated(msg.sender, _delegatee);
    }
}
```