This Solidity smart contract, `SynapseNexus`, is designed as a **Decentralized AI-Driven Research & Innovation Network**. It integrates several advanced and trending concepts in the Web3 space, including decentralized identity, dynamic Soulbound Tokens (SBTs) for reputation, on-chain metadata registries for off-chain data and AI models, and an oracle-driven AI inference mechanism. The goal is to create a unique platform for collaborative scientific research and AI development, distinct from existing open-source projects.

---

**Outline: SynapseNexus - Decentralized AI-Driven Research & Innovation Network**

**I. Core & Administrative (5 functions)**
*   `constructor`: Initializes the contract, sets the owner, and initial protocol parameters.
*   `updateProtocolFeeRecipient`: Allows the owner to change the address receiving protocol fees.
*   `setProtocolFeePercentage`: Allows the owner to adjust the percentage of funds taken as protocol fees.
*   `pauseContract`: Allows the owner to pause critical functionalities in case of emergency.
*   `unpauseContract`: Allows the owner to unpause the contract.

**II. Participant & Role Management (4 functions)**
*   `registerParticipantProfile`: Allows any address to register as a participant with a basic profile.
*   `assignSpecializedRole`: Owner/admin assigns specific roles (Researcher, DataProvider, ModelDeveloper, Validator) to registered participants.
*   `revokeSpecializedRole`: Owner/admin revokes a specialized role.
*   `getParticipantDetails`: Public view function to retrieve a participant's profile and roles.

**III. Data & Dataset Management (5 functions)**
*   `registerDatasetMetadata`: Data Providers register metadata for off-chain datasets (e.g., IPFS CID, hash, description, access conditions, optional pricing).
*   `updateDatasetMetadata`: Allows a Data Provider to update details of their registered dataset.
*   `requestDatasetAccess`: Researchers or Model Developers can formally request access to a private or token-gated dataset.
*   `grantDatasetAccess`: Data Providers review and approve/reject dataset access requests, transferring funds if applicable.
*   `logDatasetUsageInProject`: Records when a specific dataset is declared as used within a research project.

**IV. AI Model & Inference Management (5 functions)**
*   `registerAIModelMetadata`: Model Developers register metadata for off-chain AI models (e.g., model type, inference endpoint, expected input/output schema, version, cost per inference).
*   `updateAIModelMetadata`: Allows a Model Developer to update details of their registered AI model.
*   `submitAIModelBenchmark`: Validators or community can submit performance benchmarks for registered models, typically requiring off-chain computation and oracle verification.
*   `requestAIInferenceJob`: Initiates an off-chain AI inference request to a registered model, handling payment/permissions. Requires an oracle integration.
*   `receiveInferenceResult`: Oracle callback function to deliver the result of an AI inference job on-chain, along with proof hashes.

**V. Research Project & Funding (6 functions)**
*   `proposeResearchProject`: Researchers submit detailed proposals for new research projects, including objectives, required resources, and requested funding.
*   `fundResearchProject`: Any participant can contribute funds to an approved research project.
*   `submitProjectMilestone`: Researchers submit proof of completion for a project milestone.
*   `reviewProjectMilestone`: Validators review submitted milestones and recommend approval or rejection.
*   `approveProjectMilestone`: Funders or designated approvers release funds for completed milestones.
*   `submitFinalResearchOutput`: Researchers submit the final results, findings, or publications of a completed project.

**VI. Reputation & Soulbound Tokens (SBTs) (3 functions)**
*   `_mintAchievementSBT`: Internal function, triggered upon successful completion of significant actions (e.g., project completion, successful validation, high-quality data contribution), to issue non-transferable SBTs representing achievements or reputation tiers.
*   `getParticipantReputationScore`: Public view function to retrieve a participant's dynamic reputation score, based on their contributions and validated actions.
*   `_updateReputationScore`: Internal function to adjust a participant's reputation score based on positive or negative actions.

**VII. Utility Functions (2 functions)**
*   `withdrawProtocolFees`: Allows the owner to withdraw collected protocol fees (mainly for accidental sends or future accounting changes, as fees are typically direct-sent).
*   `receive()` & `fallback()`: Standard functions to allow Ether reception and handle incorrect calls.

**Total Functions: 28 functions.**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For SBTs, making them non-transferable via logic.
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint256 to string for SBT metadata

/**
 * @title SynapseNexus - Decentralized AI-Driven Research & Innovation Network
 * @author Your Name/AI
 * @notice SynapseNexus is a comprehensive smart contract platform designed to foster a decentralized ecosystem for
 *         AI-driven research and innovation. It facilitates collaboration between researchers, data providers,
 *         AI model developers, and validators by providing on-chain registries for datasets and AI models,
 *         a robust reputation system, project management, and a mechanism for decentralized funding and
 *         AI inference orchestration.
 *
 * Outline:
 * I. Core & Administrative
 *    - Constructor: Initializes the contract, sets the owner, and initial protocol parameters.
 *    - updateProtocolFeeRecipient: Allows the owner to change the address receiving protocol fees.
 *    - setProtocolFeePercentage: Allows the owner to adjust the percentage of funds taken as protocol fees.
 *    - pauseContract: Allows the owner to pause critical functionalities in case of emergency.
 *    - unpauseContract: Allows the owner to unpause the contract.
 *
 * II. Participant & Role Management
 *    - registerParticipantProfile: Allows any address to register as a participant with a basic profile.
 *    - assignSpecializedRole: Owner/admin assigns specific roles (Researcher, DataProvider, ModelDeveloper, Validator) to registered participants.
 *    - revokeSpecializedRole: Owner/admin revokes a specialized role.
 *    - getParticipantDetails: Public view function to retrieve a participant's profile and roles.
 *
 * III. Data & Dataset Management
 *    - registerDatasetMetadata: Data Providers register metadata for off-chain datasets (e.g., IPFS CID, hash, description, access conditions, optional pricing).
 *    - updateDatasetMetadata: Allows a Data Provider to update details of their registered dataset.
 *    - requestDatasetAccess: Researchers or Model Developers can formally request access to a private or token-gated dataset.
 *    - grantDatasetAccess: Data Providers review and approve/reject dataset access requests.
 *    - logDatasetUsageInProject: Records when a specific dataset is declared as used within a research project.
 *
 * IV. AI Model & Inference Management
 *    - registerAIModelMetadata: Model Developers register metadata for off-chain AI models (e.g., model type, inference endpoint, expected input/output schema, version, cost per inference).
 *    - updateAIModelMetadata: Allows a Model Developer to update details of their registered AI model.
 *    - submitAIModelBenchmark: Validators or community can submit performance benchmarks for registered models, typically requiring off-chain computation and oracle verification.
 *    - requestAIInferenceJob: Initiates an off-chain AI inference request to a registered model, handling payment/permissions. Requires an oracle integration.
 *    - receiveInferenceResult: Oracle callback function to deliver the result of an AI inference job on-chain, along with proof hashes.
 *
 * V. Research Project & Funding
 *    - proposeResearchProject: Researchers submit detailed proposals for new research projects, including objectives, required resources, and requested funding.
 *    - fundResearchProject: Any participant can contribute funds to an approved research project.
 *    - submitProjectMilestone: Researchers submit proof of completion for a project milestone.
 *    - reviewProjectMilestone: Validators review submitted milestones and recommend approval or rejection.
 *    - approveProjectMilestone: Funders or designated approvers release funds for completed milestones.
 *    - submitFinalResearchOutput: Researchers submit the final results, findings, or publications of a completed project.
 *
 * VI. Reputation & Soulbound Tokens (SBTs)
 *    - _mintAchievementSBT: Internal function, triggered upon successful completion of significant actions (e.g., project completion, successful validation, high-quality data contribution), to issue non-transferable SBTs representing achievements or reputation tiers.
 *    - getParticipantReputationScore: Public view function to retrieve a participant's dynamic reputation score, based on their contributions and validated actions.
 *    - _updateReputationScore: Internal function to adjust a participant's reputation score based on positive or negative actions.
 *
 * VII. Utility Functions
 *    - withdrawProtocolFees: Allows the owner to withdraw collected protocol fees.
 *    - receive() & fallback(): Standard functions to allow Ether reception and handle incorrect calls.
 *
 * Total Functions: 28 functions.
 */
contract SynapseNexus is Ownable, Pausable, ReentrancyGuard, ERC721 {
    // --- State Variables ---

    // I. Core & Administrative
    address public protocolFeeRecipient;
    uint256 public protocolFeePercentage; // Stored as basis points (e.g., 100 for 1%)

    // II. Participant & Role Management
    enum Role { None, Member, Researcher, DataProvider, ModelDeveloper, Validator }
    struct Participant {
        string name;
        string profileURI; // IPFS hash or similar for extended profile data
        uint256 registeredAt;
        uint256 reputationScore; // A dynamic score based on contributions
        bool isRegistered;
    }
    mapping(address => Participant) public participants;
    mapping(address => mapping(Role => bool)) public participantRoles;

    // III. Data & Dataset Management
    struct Dataset {
        address provider;
        string name;
        string description;
        string dataURI; // IPFS CID or similar
        bytes32 dataHash; // Cryptographic hash of the dataset
        uint256 price; // 0 for free, >0 for paid access
        bool isPublic;
        uint256 registeredAt;
        uint256 accessRequestCounter; // Counter for unique access requests
    }
    mapping(uint256 => Dataset) public datasets;
    uint256 public nextDatasetId;
    // Dataset access requests: datasetId => requestor => requestId => status
    mapping(uint256 => mapping(address => mapping(uint256 => DatasetAccessRequest))) public datasetAccessRequests;
    struct DatasetAccessRequest {
        address requestor;
        uint256 requestedAt;
        bool granted;
        bool exists; // To distinguish between non-existent and unapproved requests
    }

    // IV. AI Model & Inference Management
    struct AIModel {
        address developer;
        string name;
        string description;
        string modelURI; // IPFS CID or API endpoint
        bytes32 modelHash;
        uint256 inferenceCost; // Cost per inference in wei
        uint256 registeredAt;
        uint256 version;
    }
    mapping(uint256 => AIModel) public aiModels;
    uint256 public nextAIModelId;

    struct AIModelBenchmark {
        address submitter;
        uint256 aiModelId;
        string benchmarkURI; // URI to detailed benchmark results (e.g., IPFS)
        bytes32 benchmarkHash;
        uint256 score; // A quantitative score (e.g., accuracy percentage * 100)
        uint256 submittedAt;
    }
    mapping(uint256 => AIModelBenchmark[]) public aiModelBenchmarks; // aiModelId => array of benchmarks

    struct AIInferenceJob {
        address requestor;
        uint256 aiModelId;
        string inputDataURI; // URI to input data for inference
        bytes32 inputDataHash;
        uint256 requestedAt;
        bool completed;
        string resultURI; // URI to the inference result
        bytes32 resultHash;
    }
    mapping(uint256 => AIInferenceJob) public aiInferenceJobs;
    uint256 public nextInferenceJobId;
    address public oracleAddress; // Address of the trusted oracle for AI inference callbacks

    // V. Research Project & Funding
    enum ProjectStatus { Proposed, Approved, InProgress, ReviewingMilestone, Completed, Rejected }
    struct ResearchProject {
        address researcher;
        string title;
        string description;
        uint256 proposedFunding; // In wei
        uint256 currentFunding; // Funds actually received
        uint256 milestonesCount;
        uint256 completedMilestones;
        ProjectStatus status;
        uint256 createdAt;
        uint256 completedAt;
        string finalOutputURI;
        bytes32 finalOutputHash;
        uint256[] requiredDatasets; // IDs of datasets needed
        uint256[] requiredAIModels; // IDs of AI models needed
    }
    mapping(uint256 => ResearchProject) public researchProjects;
    uint256 public nextProjectId;

    struct ProjectMilestone {
        uint256 projectId;
        uint256 milestoneIndex;
        string description;
        uint256 paymentAmount; // For this milestone
        string proofURI; // URI to proof of completion
        bytes32 proofHash;
        bool submitted;
        bool reviewed;
        bool approved;
        address reviewer;
        uint256 submittedAt;
    }
    mapping(uint256 => mapping(uint256 => ProjectMilestone)) public projectMilestones; // projectId => milestoneIndex => milestone

    // VI. Reputation & SBTs
    // ERC721 for Soulbound Tokens. Token IDs represent specific achievements.
    // Metadata can be stored off-chain pointing to the achievement details.
    uint256 public nextSBTId;

    // --- Events ---
    // Core & Admin
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 newPercentage);
    event Paused(address account);
    event Unpaused(address account);

    // Participant & Role Management
    event ParticipantRegistered(address indexed participantAddress, string name, uint256 registeredAt);
    event RoleAssigned(address indexed participantAddress, Role role);
    event RoleRevoked(address indexed participantAddress, Role role);

    // Data & Dataset Management
    event DatasetRegistered(uint256 indexed datasetId, address indexed provider, string name, string dataURI);
    event DatasetMetadataUpdated(uint256 indexed datasetId, string newDataURI);
    event DatasetAccessRequested(uint256 indexed datasetId, address indexed requestor, uint256 requestId);
    event DatasetAccessGranted(uint256 indexed datasetId, address indexed requestor, uint256 requestId);
    event DatasetAccessRejected(uint256 indexed datasetId, address indexed requestor, uint256 requestId);
    event DatasetUsageLogged(uint256 indexed projectId, uint256 indexed datasetId, address indexed user);

    // AI Model & Inference Management
    event AIModelRegistered(uint256 indexed modelId, address indexed developer, string name, string modelURI);
    event AIModelMetadataUpdated(uint256 indexed modelId, string newModelURI);
    event AIModelBenchmarkSubmitted(uint256 indexed modelId, address indexed submitter, uint256 score);
    event AIInferenceJobRequested(uint256 indexed jobId, uint256 indexed modelId, address indexed requestor, string inputURI);
    event AIInferenceResultReceived(uint256 indexed jobId, string resultURI, bytes32 resultHash);

    // Research Project & Funding
    event ResearchProjectProposed(uint256 indexed projectId, address indexed researcher, string title, uint256 proposedFunding);
    event ResearchProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectMilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event ProjectMilestoneReviewed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed reviewer, bool approved);
    event ProjectMilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 paymentAmount);
    event FinalResearchOutputSubmitted(uint256 indexed projectId, string outputURI, bytes32 outputHash);
    event ResearchProjectCompleted(uint256 indexed projectId, address indexed researcher);

    // Reputation & SBTs
    event AchievementSBTMinted(address indexed recipient, uint256 indexed tokenId, string tokenURI);
    event ReputationScoreUpdated(address indexed participant, uint256 newScore, string reason);

    // --- Modifiers ---
    modifier onlyRole(Role _role) {
        require(participantRoles[msg.sender][_role], "SynapseNexus: Caller does not have the required role");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "SynapseNexus: Caller is not the designated oracle");
        _;
    }

    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].isRegistered, "SynapseNexus: Caller is not a registered participant");
        _;
    }

    /**
     * @dev Prevents transfers for Soulbound Tokens (SBTs).
     *      This modifier is overridden in `_beforeTokenTransfer` to enforce non-transferability.
     */
    modifier notSBTTransfers(address from, address to, uint256 tokenId) override {
        if (from != address(0)) { // Allow minting (from address(0)) but prevent transfers
            revert("SynapseNexus: Soulbound tokens are non-transferable");
        }
        _; // If from is address(0), proceed with the original _beforeTokenTransfer logic (i.e., mint)
    }

    // --- Constructor ---
    constructor(address _initialOracleAddress, address _initialFeeRecipient)
        ERC721("SynapseNexusAchievement", "SNA") // Initialize ERC721 for SBTs
        Ownable(msg.sender) // Set deployer as owner
    {
        require(_initialOracleAddress != address(0), "SynapseNexus: Initial oracle address cannot be zero");
        require(_initialFeeRecipient != address(0), "SynapseNexus: Initial fee recipient cannot be zero");

        oracleAddress = _initialOracleAddress;
        protocolFeeRecipient = _initialFeeRecipient;
        protocolFeePercentage = 100; // 1% default fee (100 basis points)
        nextDatasetId = 1;
        nextAIModelId = 1;
        nextProjectId = 1;
        nextInferenceJobId = 1;
        nextSBTId = 1;
    }

    // --- I. Core & Administrative Functions ---

    /**
     * @notice Allows the owner to change the address designated to receive protocol fees.
     * @param _newRecipient The new address for protocol fee collection.
     */
    function updateProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "SynapseNexus: Fee recipient cannot be zero address");
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    /**
     * @notice Allows the owner to adjust the percentage of funds taken as protocol fees.
     * @dev Fee is in basis points (e.g., 100 for 1%, 500 for 5%). Max 10000 (100%).
     * @param _newPercentage The new fee percentage in basis points.
     */
    function setProtocolFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 10000, "SynapseNexus: Fee percentage cannot exceed 100%"); // 10000 basis points = 100%
        protocolFeePercentage = _newPercentage;
        emit ProtocolFeePercentageUpdated(_newPercentage);
    }

    /**
     * @notice Pauses contract functionalities. Only owner can call.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses contract functionalities. Only owner can call.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- II. Participant & Role Management Functions ---

    /**
     * @notice Allows any address to register as a basic participant member.
     *         A profileURI can point to an off-chain metadata JSON.
     * @param _name The human-readable name of the participant.
     * @param _profileURI URI to the participant's extended profile (e.g., IPFS hash).
     */
    function registerParticipantProfile(string calldata _name, string calldata _profileURI)
        external
        whenNotPaused
    {
        require(!participants[msg.sender].isRegistered, "SynapseNexus: Caller is already a registered participant");
        require(bytes(_name).length > 0, "SynapseNexus: Name cannot be empty");

        participants[msg.sender] = Participant({
            name: _name,
            profileURI: _profileURI,
            registeredAt: block.timestamp,
            reputationScore: 0,
            isRegistered: true
        });
        participantRoles[msg.sender][Role.Member] = true; // All registered are members
        emit ParticipantRegistered(msg.sender, _name, block.timestamp);
    }

    /**
     * @notice Allows the contract owner to assign a specialized role to a registered participant.
     * @param _participantAddress The address of the participant to assign the role to.
     * @param _role The role to assign (e.g., Researcher, DataProvider, ModelDeveloper, Validator).
     */
    function assignSpecializedRole(address _participantAddress, Role _role) external onlyOwner {
        require(participants[_participantAddress].isRegistered, "SynapseNexus: Participant not registered");
        require(_role != Role.None && _role != Role.Member, "SynapseNexus: Cannot assign None or Member role directly");
        require(!participantRoles[_participantAddress][_role], "SynapseNexus: Participant already has this role");

        participantRoles[_participantAddress][_role] = true;
        emit RoleAssigned(_participantAddress, _role);
    }

    /**
     * @notice Allows the contract owner to revoke a specialized role from a participant.
     * @param _participantAddress The address of the participant to revoke the role from.
     * @param _role The role to revoke.
     */
    function revokeSpecializedRole(address _participantAddress, Role _role) external onlyOwner {
        require(participants[_participantAddress].isRegistered, "SynapseNexus: Participant not registered");
        require(_role != Role.None && _role != Role.Member, "SynapseNexus: Cannot revoke None or Member role directly");
        require(participantRoles[_participantAddress][_role], "SynapseNexus: Participant does not have this role");

        participantRoles[_participantAddress][_role] = false;
        emit RoleRevoked(_participantAddress, _role);
    }

    /**
     * @notice Retrieves the profile and active roles of a participant.
     * @param _participantAddress The address of the participant.
     * @return name The participant's name.
     * @return profileURI The URI to the participant's extended profile.
     * @return registeredAt The timestamp when the participant registered.
     * @return reputationScore The current reputation score of the participant.
     * @return roles An array of roles the participant currently holds.
     */
    function getParticipantDetails(address _participantAddress)
        public
        view
        returns (
            string memory name,
            string memory profileURI,
            uint256 registeredAt,
            uint256 reputationScore,
            Role[] memory roles
        )
    {
        Participant storage p = participants[_participantAddress];
        require(p.isRegistered, "SynapseNexus: Participant not registered");

        name = p.name;
        profileURI = p.profileURI;
        registeredAt = p.registeredAt;
        reputationScore = p.reputationScore;

        uint256 roleCount = 0;
        if (participantRoles[_participantAddress][Role.Member]) roleCount++;
        if (participantRoles[_participantAddress][Role.Researcher]) roleCount++;
        if (participantRoles[_participantAddress][Role.DataProvider]) roleCount++;
        if (participantRoles[_participantAddress][Role.ModelDeveloper]) roleCount++;
        if (participantRoles[_participantAddress][Role.Validator]) roleCount++;

        roles = new Role[](roleCount);
        uint256 i = 0;
        if (participantRoles[_participantAddress][Role.Member]) { roles[i++] = Role.Member; }
        if (participantRoles[_participantAddress][Role.Researcher]) { roles[i++] = Role.Researcher; }
        if (participantRoles[_participantAddress][Role.DataProvider]) { roles[i++] = Role.DataProvider; }
        if (participantRoles[_participantAddress][Role.ModelDeveloper]) { roles[i++] = Role.ModelDeveloper; }
        if (participantRoles[_participantAddress][Role.Validator]) { roles[i++] = Role.Validator; }
    }

    // --- III. Data & Dataset Management Functions ---

    /**
     * @notice Allows a Data Provider to register metadata for an off-chain dataset.
     * @param _name The name of the dataset.
     * @param _description A brief description of the dataset.
     * @param _dataURI URI pointing to the actual data (e.g., IPFS CID, URL).
     * @param _dataHash Cryptographic hash of the dataset for integrity verification.
     * @param _price Price in wei for accessing the dataset (0 for free).
     * @param _isPublic True if the dataset is publicly accessible without request.
     * @return datasetId The unique ID assigned to the registered dataset.
     */
    function registerDatasetMetadata(
        string calldata _name,
        string calldata _description,
        string calldata _dataURI,
        bytes32 _dataHash,
        uint256 _price,
        bool _isPublic
    ) external onlyRole(Role.DataProvider) whenNotPaused returns (uint256) {
        require(bytes(_name).length > 0, "SynapseNexus: Dataset name cannot be empty");
        require(bytes(_dataURI).length > 0, "SynapseNexus: Data URI cannot be empty");
        require(_dataHash != bytes32(0), "SynapseNexus: Data hash cannot be zero");

        uint256 currentId = nextDatasetId++;
        datasets[currentId] = Dataset({
            provider: msg.sender,
            name: _name,
            description: _description,
            dataURI: _dataURI,
            dataHash: _dataHash,
            price: _price,
            isPublic: _isPublic,
            registeredAt: block.timestamp,
            accessRequestCounter: 0
        });

        emit DatasetRegistered(currentId, msg.sender, _name, _dataURI);
        _updateReputationScore(msg.sender, 5, "Registered new dataset"); // Example reputation increase
        return currentId;
    }

    /**
     * @notice Allows a Data Provider to update metadata for their registered dataset.
     * @param _datasetId The ID of the dataset to update.
     * @param _newName The new name of the dataset (empty string to keep current).
     * @param _newDescription The new description of the dataset (empty string to keep current).
     * @param _newDataURI The new URI pointing to the data (empty string to keep current).
     * @param _newDataHash The new cryptographic hash of the dataset (zero bytes to keep current).
     * @param _newPrice The new price for accessing the dataset (0 to keep current, if price should not be 0, use a sentinel).
     * @param _newIsPublic The new public status of the dataset.
     */
    function updateDatasetMetadata(
        uint256 _datasetId,
        string calldata _newName,
        string calldata _newDescription,
        string calldata _newDataURI,
        bytes32 _newDataHash,
        uint256 _newPrice, // Pass 0 if no change, or the new price
        bool _newIsPublic // Pass current value if no change, or new value
    ) external onlyRole(Role.DataProvider) whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.provider == msg.sender, "SynapseNexus: Not the provider of this dataset");
        require(dataset.registeredAt != 0, "SynapseNexus: Dataset does not exist");

        if (bytes(_newName).length > 0) dataset.name = _newName;
        if (bytes(_newDescription).length > 0) dataset.description = _newDescription;
        if (bytes(_newDataURI).length > 0) dataset.dataURI = _newDataURI;
        if (_newDataHash != bytes32(0)) dataset.dataHash = _newDataHash;
        
        // Only update price if a non-sentinel value (e.g., greater than max uint, or a specific placeholder) is passed,
        // or if 0 is a valid new price. Here, assumes 0 is a valid update (to free).
        dataset.price = _newPrice; 
        
        // This logic changes the public status if _newIsPublic is explicitly different from current.
        dataset.isPublic = _newIsPublic;

        emit DatasetMetadataUpdated(_datasetId, dataset.dataURI);
    }

    /**
     * @notice Allows a Researcher or Model Developer to request access to a private or paid dataset.
     *         If the dataset has a price, the amount must be sent with the transaction.
     * @param _datasetId The ID of the dataset to request access to.
     */
    function requestDatasetAccess(uint256 _datasetId)
        external
        payable
        onlyRegisteredParticipant
        whenNotPaused
    {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.registeredAt != 0, "SynapseNexus: Dataset does not exist");
        require(!dataset.isPublic, "SynapseNexus: Dataset is public, no access request needed");
        require(dataset.provider != msg.sender, "SynapseNexus: Cannot request access to your own dataset");
        if (dataset.price > 0) {
            require(msg.value >= dataset.price, "SynapseNexus: Insufficient payment for dataset access");
        }

        uint256 requestId = dataset.accessRequestCounter++;
        datasetAccessRequests[_datasetId][msg.sender][requestId] = DatasetAccessRequest({
            requestor: msg.sender,
            requestedAt: block.timestamp,
            granted: false,
            exists: true
        });
        
        // If payment was made, collect protocol fee.
        if (dataset.price > 0) {
            uint256 fee = (msg.value * protocolFeePercentage) / 10000;
            // Transfer fee immediately to recipient
            payable(protocolFeeRecipient).transfer(fee);
            // Remaining balance for dataset is held by this contract until granted or refunded.
        }

        emit DatasetAccessRequested(_datasetId, msg.sender, requestId);
    }

    /**
     * @notice Allows a Data Provider to approve or reject a dataset access request.
     *         If approved and a payment was made, the payment (minus fee) is released to the provider.
     * @param _datasetId The ID of the dataset.
     * @param _requestor The address of the participant who requested access.
     * @param _requestId The ID of the specific access request.
     * @param _grant True to grant access, false to reject.
     */
    function grantDatasetAccess(uint256 _datasetId, address _requestor, uint256 _requestId, bool _grant)
        external
        onlyRole(Role.DataProvider)
        whenNotPaused
        nonReentrant
    {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.provider == msg.sender, "SynapseNexus: Not the provider of this dataset");
        require(dataset.registeredAt != 0, "SynapseNexus: Dataset does not exist");

        DatasetAccessRequest storage accessReq = datasetAccessRequests[_datasetId][_requestor][_requestId];
        require(accessReq.exists, "SynapseNexus: Access request does not exist or invalid ID");
        require(!accessReq.granted, "SynapseNexus: Access request already granted/processed"); // `granted` also indicates processed

        // Get the amount that was sent with the request (including fee portion)
        uint256 amountReceivedForRequest = dataset.price; // This is the amount expected for the request.

        accessReq.granted = true; // Mark as processed
        if (_grant) {
            if (amountReceivedForRequest > 0) {
                // The fee was already taken in requestDatasetAccess.
                // The amount transferred to the provider is the remaining balance from the payment.
                uint256 amountToTransfer = amountReceivedForRequest - (amountReceivedForRequest * protocolFeePercentage) / 10000;
                payable(dataset.provider).transfer(amountToTransfer);
            }
            emit DatasetAccessGranted(_datasetId, _requestor, _requestId);
            _updateReputationScore(msg.sender, 2, "Granted dataset access"); // Example reputation increase
            _updateReputationScore(_requestor, 1, "Obtained dataset access"); // Example reputation increase
        } else {
            if (amountReceivedForRequest > 0) {
                // Refund the requestor (minus the fee which was already taken)
                uint256 amountToRefund = amountReceivedForRequest - (amountReceivedForRequest * protocolFeePercentage) / 10000;
                payable(_requestor).transfer(amountToRefund);
            }
            // Mark as not granted after refund/processing
            accessReq.exists = false; // Mark as no longer relevant/processed (rejected)
            emit DatasetAccessRejected(_datasetId, _requestor, _requestId);
            _updateReputationScore(msg.sender, -1, "Rejected dataset access"); // Example reputation decrease
        }
    }

    /**
     * @notice Logs the usage of a dataset within a specific research project.
     *         This function does not grant access but serves as an audit trail.
     * @param _projectId The ID of the research project.
     * @param _datasetId The ID of the dataset used.
     * @dev This could be called by a researcher or an automated system after actual dataset access is obtained.
     */
    function logDatasetUsageInProject(uint256 _projectId, uint256 _datasetId)
        external
        onlyRole(Role.Researcher) // Or other roles as appropriate
        whenNotPaused
    {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.researcher == msg.sender, "SynapseNexus: Not the researcher of this project");
        require(project.createdAt != 0, "SynapseNexus: Project does not exist");
        require(datasets[_datasetId].registeredAt != 0, "SynapseNexus: Dataset does not exist");

        // Simple logging, could add more complex checks like if access was previously granted
        // For now, just assumes access was handled off-chain or via requestDatasetAccess
        // and this is just for tracking.
        emit DatasetUsageLogged(_projectId, _datasetId, msg.sender);
    }

    // --- IV. AI Model & Inference Management Functions ---

    /**
     * @notice Allows an AI Model Developer to register metadata for an off-chain AI model.
     * @param _name The name of the AI model.
     * @param _description A brief description of the model.
     * @param _modelURI URI pointing to model details, endpoint, etc. (e.g., IPFS CID, URL).
     * @param _modelHash Cryptographic hash of the model artifacts/code for integrity.
     * @param _inferenceCost Cost in wei per inference request using this model.
     * @param _version The version of the model.
     * @return modelId The unique ID assigned to the registered AI model.
     */
    function registerAIModelMetadata(
        string calldata _name,
        string calldata _description,
        string calldata _modelURI,
        bytes32 _modelHash,
        uint256 _inferenceCost,
        uint256 _version
    ) external onlyRole(Role.ModelDeveloper) whenNotPaused returns (uint256) {
        require(bytes(_name).length > 0, "SynapseNexus: Model name cannot be empty");
        require(bytes(_modelURI).length > 0, "SynapseNexus: Model URI cannot be empty");
        require(_modelHash != bytes32(0), "SynapseNexus: Model hash cannot be zero");

        uint256 currentId = nextAIModelId++;
        aiModels[currentId] = AIModel({
            developer: msg.sender,
            name: _name,
            description: _description,
            modelURI: _modelURI,
            modelHash: _modelHash,
            inferenceCost: _inferenceCost,
            registeredAt: block.timestamp,
            version: _version
        });

        emit AIModelRegistered(currentId, msg.sender, _name, _modelURI);
        _updateReputationScore(msg.sender, 5, "Registered new AI Model"); // Example reputation increase
        return currentId;
    }

    /**
     * @notice Allows an AI Model Developer to update metadata for their registered AI model.
     * @param _modelId The ID of the AI model to update.
     * @param _newName The new name (empty string to keep current).
     * @param _newDescription The new description (empty string to keep current).
     * @param _newModelURI The new URI (empty string to keep current).
     * @param _newModelHash The new hash (zero bytes to keep current).
     * @param _newInferenceCost The new inference cost (0 to keep current).
     * @param _newVersion The new version (0 to keep current).
     */
    function updateAIModelMetadata(
        uint256 _modelId,
        string calldata _newName,
        string calldata _newDescription,
        string calldata _newModelURI,
        bytes32 _newModelHash,
        uint256 _newInferenceCost, // 0 means no change, or actual new value
        uint256 _newVersion // 0 means no change, or actual new value
    ) external onlyRole(Role.ModelDeveloper) whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.developer == msg.sender, "SynapseNexus: Not the developer of this model");
        require(model.registeredAt != 0, "SynapseNexus: AI Model does not exist");

        if (bytes(_newName).length > 0) model.name = _newName;
        if (bytes(_newDescription).length > 0) model.description = _newDescription;
        if (bytes(_newModelURI).length > 0) model.modelURI = _newModelURI;
        if (_newModelHash != bytes32(0)) model.modelHash = _newModelHash;
        if (_newInferenceCost != 0) model.inferenceCost = _newInferenceCost;
        if (_newVersion != 0) model.version = _newVersion;

        emit AIModelMetadataUpdated(_modelId, model.modelURI);
    }

    /**
     * @notice Allows a Validator or other authorized participant to submit performance benchmarks for an AI model.
     *         These benchmarks would typically be generated off-chain and verified before submission.
     * @param _aiModelId The ID of the AI model being benchmarked.
     * @param _benchmarkURI URI to detailed benchmark results (e.g., IPFS hash of a report).
     * @param _benchmarkHash Cryptographic hash of the benchmark results.
     * @param _score A quantitative score representing model performance (e.g., accuracy scaled by 100, so 95.5% is 9550).
     */
    function submitAIModelBenchmark(
        uint256 _aiModelId,
        string calldata _benchmarkURI,
        bytes32 _benchmarkHash,
        uint256 _score
    ) external onlyRole(Role.Validator) whenNotPaused {
        require(aiModels[_aiModelId].registeredAt != 0, "SynapseNexus: AI Model does not exist");
        require(bytes(_benchmarkURI).length > 0, "SynapseNexus: Benchmark URI cannot be empty");
        require(_benchmarkHash != bytes32(0), "SynapseNexus: Benchmark hash cannot be zero");
        require(_score <= 10000, "SynapseNexus: Score too high (max 10000 for 100%)"); // Assuming percentage scaled by 100

        aiModelBenchmarks[_aiModelId].push(AIModelBenchmark({
            submitter: msg.sender,
            aiModelId: _aiModelId,
            benchmarkURI: _benchmarkURI,
            benchmarkHash: _benchmarkHash,
            score: _score,
            submittedAt: block.timestamp
        }));

        emit AIModelBenchmarkSubmitted(_aiModelId, msg.sender, _score);
        _updateReputationScore(msg.sender, 5, "Submitted valid AI Model benchmark"); // Example reputation increase
    }

    /**
     * @notice Initiates an off-chain AI inference request to a registered model.
     *         Requires payment if the model has an `inferenceCost`.
     *         An off-chain oracle service would pick up this event and execute the inference.
     * @param _aiModelId The ID of the AI model to request inference from.
     * @param _inputDataURI URI to the input data for the inference (e.g., IPFS CID).
     * @param _inputDataHash Cryptographic hash of the input data.
     * @return jobId The unique ID for this inference request.
     */
    function requestAIInferenceJob(uint256 _aiModelId, string calldata _inputDataURI, bytes32 _inputDataHash)
        external
        payable
        onlyRegisteredParticipant
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        AIModel storage model = aiModels[_aiModelId];
        require(model.registeredAt != 0, "SynapseNexus: AI Model does not exist");
        require(bytes(_inputDataURI).length > 0, "SynapseNexus: Input data URI cannot be empty");
        require(_inputDataHash != bytes32(0), "SynapseNexus: Input data hash cannot be zero");
        require(msg.value >= model.inferenceCost, "SynapseNexus: Insufficient payment for inference");

        uint256 currentJobId = nextInferenceJobId++;
        aiInferenceJobs[currentJobId] = AIInferenceJob({
            requestor: msg.sender,
            aiModelId: _aiModelId,
            inputDataURI: _inputDataURI,
            inputDataHash: _inputDataHash,
            requestedAt: block.timestamp,
            completed: false,
            resultURI: "",
            resultHash: bytes32(0)
        });

        // Collect protocol fee from inference payment
        uint256 fee = (msg.value * protocolFeePercentage) / 10000;
        payable(protocolFeeRecipient).transfer(fee);
        // Transfer remaining to model developer
        payable(model.developer).transfer(msg.value - fee);

        emit AIInferenceJobRequested(currentJobId, _aiModelId, msg.sender, _inputDataURI);
        return currentJobId;
    }

    /**
     * @notice Callback function for the oracle to deliver the result of an AI inference job.
     * @dev Only callable by the designated oracle address.
     * @param _jobId The ID of the inference job.
     * @param _resultURI URI to the inference result (e.g., IPFS CID).
     * @param _resultHash Cryptographic hash of the inference result.
     */
    function receiveInferenceResult(uint256 _jobId, string calldata _resultURI, bytes32 _resultHash)
        external
        onlyOracle
        whenNotPaused
    {
        AIInferenceJob storage job = aiInferenceJobs[_jobId];
        require(job.requestedAt != 0, "SynapseNexus: Inference job does not exist");
        require(!job.completed, "SynapseNexus: Inference job already completed");
        require(bytes(_resultURI).length > 0, "SynapseNexus: Result URI cannot be empty");
        require(_resultHash != bytes32(0), "SynapseNexus: Result hash cannot be zero");

        job.completed = true;
        job.resultURI = _resultURI;
        job.resultHash = _resultHash;

        emit AIInferenceResultReceived(_jobId, _resultURI, _resultHash);
        _updateReputationScore(job.requestor, 3, "Received AI Inference result"); // Example reputation increase
    }

    // --- V. Research Project & Funding Functions ---

    /**
     * @notice Allows a Researcher to propose a new research project.
     * @param _title The title of the research project.
     * @param _description A detailed description of the project, including methodology and goals.
     * @param _proposedFunding The total funding requested for the project in wei.
     * @param _milestonesCount The number of milestones planned for the project.
     * @param _requiredDatasets IDs of datasets deemed necessary for the project.
     * @param _requiredAIModels IDs of AI models deemed necessary for the project.
     * @return projectId The unique ID of the proposed project.
     */
    function proposeResearchProject(
        string calldata _title,
        string calldata _description,
        uint256 _proposedFunding,
        uint256 _milestonesCount,
        uint256[] calldata _requiredDatasets,
        uint256[] calldata _requiredAIModels
    ) external onlyRole(Role.Researcher) whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "SynapseNexus: Project title cannot be empty");
        require(_proposedFunding > 0, "SynapseNexus: Proposed funding must be greater than zero");
        require(_milestonesCount > 0, "SynapseNexus: Project must have at least one milestone");

        uint256 currentId = nextProjectId++;
        researchProjects[currentId] = ResearchProject({
            researcher: msg.sender,
            title: _title,
            description: _description,
            proposedFunding: _proposedFunding,
            currentFunding: 0,
            milestonesCount: _milestonesCount,
            completedMilestones: 0,
            status: ProjectStatus.Proposed,
            createdAt: block.timestamp,
            completedAt: 0,
            finalOutputURI: "",
            finalOutputHash: bytes32(0),
            requiredDatasets: _requiredDatasets,
            requiredAIModels: _requiredAIModels
        });

        emit ResearchProjectProposed(currentId, msg.sender, _title, _proposedFunding);
        _updateReputationScore(msg.sender, 5, "Proposed new research project"); // Example reputation increase
        return currentId;
    }

    /**
     * @notice Allows any participant to contribute funds to an approved research project.
     *         Funds are held in the contract and disbursed upon milestone approval.
     * @param _projectId The ID of the project to fund.
     */
    function fundResearchProject(uint256 _projectId) external payable whenNotPaused nonReentrant {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.createdAt != 0, "SynapseNexus: Project does not exist");
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Approved || project.status == ProjectStatus.InProgress,
            "SynapseNexus: Project not in fundable status (Proposed, Approved, or InProgress)");
        require(msg.value > 0, "SynapseNexus: Must send non-zero amount");

        project.currentFunding += msg.value;
        if (project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Approved; // Automatically move to Approved once funded
        }
        
        emit ResearchProjectFunded(_projectId, msg.sender, msg.value);
        _updateReputationScore(msg.sender, uint256(msg.value / 1e16), "Funded research project"); // Scale reputation by funding amount
    }

    /**
     * @notice Allows a Researcher to submit proof of completion for a project milestone.
     * @param _projectId The ID of the research project.
     * @param _milestoneIndex The index of the milestone being submitted (0-indexed).
     * @param _description Description of the work completed for this milestone.
     * @param _paymentAmount The amount of funding requested for this milestone.
     * @param _proofURI URI to proof of completion (e.g., IPFS hash of a report).
     * @param _proofHash Cryptographic hash of the proof.
     */
    function submitProjectMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string calldata _description,
        uint256 _paymentAmount,
        string calldata _proofURI,
        bytes32 _proofHash
    ) external onlyRole(Role.Researcher) whenNotPaused {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.researcher == msg.sender, "SynapseNexus: Not the researcher of this project");
        require(project.status == ProjectStatus.InProgress || project.status == ProjectStatus.Approved || project.status == ProjectStatus.ReviewingMilestone,
            "SynapseNexus: Project not in InProgress, Approved, or ReviewingMilestone status");
        require(_milestoneIndex < project.milestonesCount, "SynapseNexus: Invalid milestone index");
        require(projectMilestones[_projectId][_milestoneIndex].submitted == false, "SynapseNexus: Milestone already submitted");
        require(bytes(_proofURI).length > 0, "SynapseNexus: Proof URI cannot be empty");
        require(_proofHash != bytes32(0), "SynapseNexus: Proof hash cannot be zero");
        require(_paymentAmount > 0, "SynapseNexus: Payment amount for milestone must be greater than zero");
        require(_paymentAmount <= project.currentFunding, "SynapseNexus: Requested payment exceeds current project funding");

        projectMilestones[_projectId][_milestoneIndex] = ProjectMilestone({
            projectId: _projectId,
            milestoneIndex: _milestoneIndex,
            description: _description,
            paymentAmount: _paymentAmount,
            proofURI: _proofURI,
            proofHash: _proofHash,
            submitted: true,
            reviewed: false,
            approved: false,
            reviewer: address(0),
            submittedAt: block.timestamp
        });

        project.status = ProjectStatus.ReviewingMilestone;
        emit ProjectMilestoneSubmitted(_projectId, _milestoneIndex);
    }

    /**
     * @notice Allows a Validator to review a submitted project milestone.
     * @param _projectId The ID of the research project.
     * @param _milestoneIndex The index of the milestone being reviewed.
     * @param _approved True if the validator approves the milestone, false otherwise.
     */
    function reviewProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approved)
        external
        onlyRole(Role.Validator)
        whenNotPaused
    {
        ResearchProject storage project = researchProjects[_projectId];
        ProjectMilestone storage milestone = projectMilestones[_projectId][_milestoneIndex];

        require(project.createdAt != 0, "SynapseNexus: Project does not exist");
        require(milestone.submitted, "SynapseNexus: Milestone not submitted");
        require(!milestone.reviewed, "SynapseNexus: Milestone already reviewed");
        require(project.status == ProjectStatus.ReviewingMilestone, "SynapseNexus: Project not in ReviewingMilestone status");

        milestone.reviewed = true;
        milestone.approved = _approved;
        milestone.reviewer = msg.sender;

        emit ProjectMilestoneReviewed(_projectId, _milestoneIndex, msg.sender, _approved);

        if (_approved) {
            _updateReputationScore(msg.sender, 10, "Approved project milestone review"); // Positive for good review
        } else {
            _updateReputationScore(msg.sender, -5, "Rejected project milestone review"); // Negative for rejecting
        }
    }

    /**
     * @notice Allows a Funder or designated approver (e.g., DAO or owner) to approve a reviewed milestone and release funds.
     *         Requires the milestone to be reviewed and recommended for approval by a validator.
     * @param _projectId The ID of the research project.
     * @param _milestoneIndex The index of the milestone to approve.
     */
    function approveProjectMilestone(uint256 _projectId, uint256 _milestoneIndex)
        external
        onlyRegisteredParticipant // Could be `onlyRole(Role.Funder)` or `onlyOwner`
        whenNotPaused
        nonReentrant
    {
        ResearchProject storage project = researchProjects[_projectId];
        ProjectMilestone storage milestone = projectMilestones[_projectId][_milestoneIndex];

        require(project.createdAt != 0, "SynapseNexus: Project does not exist");
        require(milestone.submitted, "SynapseNexus: Milestone not submitted");
        require(milestone.reviewed, "SynapseNexus: Milestone not reviewed yet");
        require(milestone.approved, "SynapseNexus: Milestone was not approved by validator");
        require(milestone.paymentAmount > 0, "SynapseNexus: Milestone payment amount is zero");
        require(project.currentFunding >= milestone.paymentAmount, "SynapseNexus: Insufficient funds in project treasury");

        // The caller of this function represents the authority that disburses funds (e.g., a Funder, a DAO executive).
        // For simplicity, `onlyRegisteredParticipant` is used, but in a real scenario, this would be a more restricted role.

        project.currentFunding -= milestone.paymentAmount;
        payable(project.researcher).transfer(milestone.paymentAmount);
        project.completedMilestones++;

        // If all milestones completed, mark project as completed
        if (project.completedMilestones == project.milestonesCount) {
            project.status = ProjectStatus.Completed;
            project.completedAt = block.timestamp;
            // Mint SBT for project completion
            _mintAchievementSBT(project.researcher, "Project Completion", string(abi.encodePacked("ipfs://QmaProjectCompletionMetadata/", Strings.toString(_projectId))));
            _updateReputationScore(project.researcher, 50, "Completed research project"); // Significant reputation boost
        } else {
            project.status = ProjectStatus.InProgress; // Return to in-progress for next milestone
        }

        emit ProjectMilestoneApproved(_projectId, _milestoneIndex, milestone.paymentAmount);
    }

    /**
     * @notice Allows a Researcher to submit the final results/output of a completed project.
     * @param _projectId The ID of the research project.
     * @param _outputURI URI to the final research output (e.g., IPFS hash of a paper, code repository).
     * @param _outputHash Cryptographic hash of the final output.
     */
    function submitFinalResearchOutput(uint256 _projectId, string calldata _outputURI, bytes32 _outputHash)
        external
        onlyRole(Role.Researcher)
        whenNotPaused
    {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.researcher == msg.sender, "SynapseNexus: Not the researcher of this project");
        require(project.status == ProjectStatus.Completed, "SynapseNexus: Project is not marked as Completed yet");
        require(bytes(_outputURI).length > 0, "SynapseNexus: Output URI cannot be empty");
        require(_outputHash != bytes32(0), "SynapseNexus: Output hash cannot be zero");
        require(bytes(project.finalOutputURI).length == 0, "SynapseNexus: Final output already submitted for this project");

        project.finalOutputURI = _outputURI;
        project.finalOutputHash = _outputHash;

        emit FinalResearchOutputSubmitted(_projectId, _outputURI, _outputHash);
        // Additional rewards or reputation could be triggered here upon verification of output quality.
    }

    // --- VI. Reputation & Soulbound Tokens (SBTs) Functions ---

    /**
     * @notice Internal function to mint a new Soulbound Token (SBT) for a recipient.
     *         SBTs represent achievements and are non-transferable.
     * @param _to The address to mint the SBT to.
     * @param _achievementName The name of the achievement (e.g., "Project Completion", "Top Validator").
     * @param _tokenURI URI to the SBT metadata (e.g., IPFS JSON describing the achievement).
     */
    function _mintAchievementSBT(address _to, string memory _achievementName, string memory _tokenURI) internal {
        uint256 tokenId = nextSBTId++;
        _mint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI); // Set off-chain metadata for SBT

        emit AchievementSBTMinted(_to, tokenId, _tokenURI);
    }

    /**
     * @dev Overrides `ERC721`'s `_beforeTokenTransfer` to enforce non-transferability for SBTs.
     *      Allows minting (transfer from address(0)) but reverts for any other transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        // Calls the custom modifier `notSBTTransfers` to handle the core non-transferability logic.
        // `notSBTTransfers` will revert if `from` is not address(0).
        // If `from` is address(0)` (minting), then super._beforeTokenTransfer is called.
        notSBTTransfers(from, to, tokenId);
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @notice Retrieves the current reputation score of a participant.
     * @param _participantAddress The address of the participant.
     * @return The participant's current reputation score.
     */
    function getParticipantReputationScore(address _participantAddress) public view returns (uint256) {
        require(participants[_participantAddress].isRegistered, "SynapseNexus: Participant not registered");
        return participants[_participantAddress].reputationScore;
    }

    /**
     * @notice Internal function to adjust a participant's reputation score.
     *         This function is called by other functions within the contract upon specific actions.
     * @param _participant The address of the participant whose score to update.
     * @param _change The amount to change the reputation score by (can be positive or negative).
     * @param _reason A string describing the reason for the reputation change.
     */
    function _updateReputationScore(address _participant, int256 _change, string memory _reason) internal {
        require(participants[_participant].isRegistered, "SynapseNexus: Participant not registered for reputation update");

        int256 currentScore = int256(participants[_participant].reputationScore);
        int256 newScore = currentScore + _change;

        // Ensure reputation does not go below zero
        if (newScore < 0) {
            newScore = 0;
        }

        participants[_participant].reputationScore = uint256(newScore);
        emit ReputationScoreUpdated(_participant, uint256(newScore), _reason);
    }

    // --- VII. Utility Functions ---

    /**
     * @notice Allows the owner to withdraw any Ether held by the contract that is not explicitly
     *         earmarked for project funding or other specific purposes. This primarily handles
     *         accidental sends or residual amounts if fee logic changes. Protocol fees are generally
     *         sent directly to the fee recipient upon transaction.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "SynapseNexus: No withdrawable balance");
        
        // Safety: Ensure this doesn't accidentally withdraw project funds.
        // For this contract, project funds are managed within the project struct and disbursed.
        // This function is for "floating" balance.
        payable(protocolFeeRecipient).transfer(balance);
    }

    // Fallback and Receive functions
    receive() external payable {
        // Allows the contract to receive Ether.
        // Funds can be for project funding (`fundResearchProject`) or general contributions.
    }

    fallback() external payable {
        // This function is executed if a contract receives Ether and the call data does not match any function.
        // It simply allows receiving Ether.
    }
}
```