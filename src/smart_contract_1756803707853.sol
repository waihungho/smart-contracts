```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CognitoNet - A Decentralized AI Model & Data Collaboration Network
/// @author [Your Name/Alias]
/// @notice This contract enables decentralized collaboration on AI models and datasets,
///         featuring bounty funding, a dynamic reputation system, IP management,
///         and a simulated integration for ZK-enhanced performance verification.
///         It aims to foster open innovation in AI while providing mechanisms for
///         verifiable contributions and fair compensation.
///
/// @dev This contract is designed for demonstration purposes. Actual ZK-proof
///      verification on-chain would require complex cryptographic primitives
///      and significant gas, typically handled by specialized precompiles or
///      off-chain services. The ZK verification here is a simplified simulation.
///      All IDs are sequential and managed internally.
///
/// @custom:version 1.0.0

// --- OUTLINE AND FUNCTION SUMMARY ---
//
// I.  Core Configuration & Access Control
//     - constructor(): Initializes the contract owner and sets initial service fee.
//     - updateServiceFee(uint256 newFeeBps): Allows owner to adjust the service fee percentage (in basis points).
//     - withdrawFees(): Allows owner to withdraw accumulated service fees.
//
// II. User & Profile Management
//     - registerUser(string calldata name, string calldata bio): Creates a unique profile for a new user.
//     - updateUserProfile(string calldata newName, string calldata newBio): Updates an existing user's profile information.
//     - getUserProfile(address userAddress) view: Retrieves the profile details for a given address.
//
// III. AI Model Management
//      - proposeAIModel(string calldata name, string calldata description, string calldata ipfsHash, uint256 suggestedLicenseFee): Allows users to propose new AI models to the network.
//      - updateAIModel(uint256 modelId, string calldata newDescription, string calldata newIpfsHash): Allows model owners to update their proposed models.
//      - deprecateAIModel(uint256 modelId): Marks an AI model as deprecated, preventing new licenses or bounties.
//      - getAIModel(uint256 modelId) view: Retrieves the details of a specific AI model.
//
// IV. Dataset Management
//     - proposeDataset(string calldata name, string calldata description, string calldata ipfsHash, bool isPrivate): Allows users to propose new datasets.
//     - updateDataset(uint256 datasetId, string calldata newDescription, string calldata newIpfsHash): Allows dataset owners to update their proposed datasets.
//     - getDataset(uint256 datasetId) view: Retrieves the details of a specific dataset.
//
// V.  Research Bounties
//     - createResearchBounty(string calldata title, string calldata description, uint256 rewardAmount, uint256 submissionDeadline): Creates a new research bounty with a specified reward.
//     - fundResearchBounty(uint256 bountyId) payable: Allows users to contribute funds to an existing research bounty.
//     - submitBountySolution(uint256 bountyId, string calldata solutionIpfsHash, uint256 modelId): Users can submit their AI model solutions for a bounty.
//     - approveBountySolution(uint256 bountyId, uint256 solutionIndex): Bounty creator approves a solution, distributes rewards, and assigns reputation.
//     - getResearchBounty(uint256 bountyId) view: Retrieves the details of a specific research bounty.
//
// VI. Reputation System (Soulbound-like)
//     - issueReputationPoint(address recipient, string calldata reason, int256 points): Owner or designated council can manually issue reputation points.
//     - challengeReputation(address target, uint256 entryIndex, string calldata reason): Allows users to challenge specific reputation entries.
//     - getTotalReputation(address userAddress) view: Calculates and returns the total reputation score for a user.
//
// VII. Intellectual Property (IP) & Licensing
//      - requestIPLicense(uint256 modelId, uint256 datasetId, uint256 paymentAmount) payable: Allows users to request a license to use a model or dataset.
//      - approveIPLicense(uint256 licenseId): IP owner approves a pending license request.
//      - revokeIPLicense(uint256 licenseId): IP owner revokes an existing license.
//      - getIPLicense(uint256 licenseId) view: Retrieves the details of a specific IP license.
//
// VIII. ZK-Proof Integration (Simulated)
//       - submitZKPerformanceProof(uint256 modelId, string calldata proofIpfsHash, uint256 claimedPerformanceMetric): Simulates submission of a ZK-proof for a model's performance.
//       - verifyZKProof(uint256 modelId, uint256 proofIndex): Simulates the verification of a ZK-proof, updating model performance and reputation.
//
// IX. Utility & Queries
//     - getBountySolution(uint256 bountyId, uint256 solutionIndex) view: Retrieves a specific solution for a bounty.
//     - getOwner() view: Returns the address of the contract owner.
//
// Total Functions: 27 (Exceeds minimum of 20)

contract CognitoNet {

    // --- State Variables ---
    address private _owner;
    uint256 public serviceFeeBps; // Service fee in basis points (e.g., 100 = 1%)
    uint256 public totalCollectedFees;

    // --- ID Counters ---
    uint256 private nextModelId;
    uint256 private nextDatasetId;
    uint256 private nextBountyId;
    uint256 private nextLicenseId;
    uint256 private nextZKProofSubmissionId;

    // --- Data Structures ---

    struct UserProfile {
        string name;
        string bio;
        address userAddress;
        uint256 registeredTimestamp;
        bool isRegistered;
    }

    struct AIModel {
        uint256 id;
        address owner;
        string name;
        string description;
        string ipfsHash; // Link to model manifest/metadata (e.g., architecture, training params)
        uint256 suggestedLicenseFee; // ETH amount
        uint256 proposedTimestamp;
        bool isActive; // Can be deprecated
        uint256 latestVerifiedPerformance; // Example: accuracy, F1 score. 0 if not verified.
        string latestVerifiedProofIpfsHash; // Link to the ZK-proof that verified performance.
    }

    struct Dataset {
        uint256 id;
        address owner;
        string name;
        string description;
        string ipfsHash; // Link to dataset manifest/metadata
        bool isPrivate; // Indicates if data is sensitive, potentially requiring ZK-proofs for usage/training
        uint256 proposedTimestamp;
        bool isActive;
    }

    struct ResearchBounty {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 rewardAmount; // Total amount to be distributed to the winner
        uint256 fundedAmount; // Actual amount collected so far
        uint256 submissionDeadline; // Timestamp
        uint256 creationTimestamp;
        bool isOpen; // True until solution is approved
        uint256 winnerSolutionIndex; // Index of the winning solution, type(uint256).max if no winner
        Solution[] solutions;
    }

    struct Solution {
        address submitter;
        string solutionIpfsHash; // Link to solution manifest/metadata (e.g., link to trained model, code)
        uint256 modelId; // The AI Model ID used/developed in the solution
        uint256 submittedTimestamp;
        bool approved;
    }

    struct ReputationEntry {
        address entity; // The address that earned/lost reputation
        string reason;
        int256 points; // Can be positive or negative
        uint256 timestamp;
        bool challenged; // Indicates if this entry is under dispute
        string challengeReason;
    }

    struct IPLicense {
        uint256 id;
        address licensor; // Owner of the IP (model or dataset)
        address licensee; // User requesting to use the IP
        uint256 modelId; // If licensing a model, 0 if not applicable
        uint256 datasetId; // If licensing a dataset, 0 if not applicable
        uint256 agreedPaymentAmount; // Amount licensee paid/agreed to pay
        uint256 requestTimestamp;
        uint256 approvalTimestamp; // 0 if not yet approved
        bool approved;
        bool revoked;
    }

    struct ZKProofSubmission {
        uint256 id;
        uint256 modelId; // The model this proof is about
        address submitter;
        string proofIpfsHash; // Link to the actual ZK-proof data and related metadata
        uint256 claimedPerformanceMetric;
        bool verified; // Status after conceptual off-chain verification
        uint256 verificationTimestamp; // 0 if not yet verified
        address verifier; // Address that conceptually verified the proof (e.g., owner or oracle)
    }

    // --- Mappings ---
    mapping(address => UserProfile) public users;
    mapping(uint256 => AIModel) public aiModels;
    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => ResearchBounty) public researchBounties;
    mapping(address => ReputationEntry[]) public userReputation; // Stores all reputation entries for a user
    mapping(uint256 => IPLicense) public ipLicenses;
    mapping(uint256 => ZKProofSubmission) public zkProofSubmissions;
    mapping(uint256 => uint256[]) public modelZKProofs; // modelId => array of ZKProofSubmission IDs


    // --- Events ---
    event ServiceFeeUpdated(uint256 newFeeBps);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event UserRegistered(address indexed userAddress, string name);
    event UserProfileUpdated(address indexed userAddress, string newName);
    event AIModelProposed(uint256 indexed modelId, address indexed owner, string name, string ipfsHash);
    event AIModelUpdated(uint256 indexed modelId, string newDescription, string newIpfsHash);
    event AIModelDeprecated(uint256 indexed modelId);
    event DatasetProposed(uint256 indexed datasetId, address indexed owner, string name, string ipfsHash);
    event DatasetUpdated(uint256 indexed datasetId, string newDescription, string newIpfsHash);
    event ResearchBountyCreated(uint256 indexed bountyId, address indexed creator, string title, uint256 rewardAmount, uint256 submissionDeadline);
    event ResearchBountyFunded(uint256 indexed bountyId, address indexed funder, uint256 amount);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed submitter, uint256 solutionIndex, string solutionIpfsHash);
    event BountySolutionApproved(uint256 indexed bountyId, uint256 indexed solutionIndex, address indexed winner, uint256 reward);
    event ReputationPointsIssued(address indexed recipient, address indexed issuer, string reason, int256 points);
    event ReputationChallenged(address indexed target, uint256 indexed entryIndex, string reason);
    event IPLicenseRequested(uint256 indexed licenseId, address indexed licensor, address indexed licensee, uint256 modelId, uint256 datasetId, uint256 agreedPaymentAmount);
    event IPLicenseApproved(uint256 indexed licenseId, address indexed licensor, address indexed licensee);
    event IPLicenseRevoked(uint256 indexed licenseId, address indexed licensor, address indexed licensee);
    event ZKPerformanceProofSubmitted(uint256 indexed proofId, uint256 indexed modelId, address indexed submitter, uint256 claimedPerformanceMetric);
    event ZKPerformanceProofVerified(uint256 indexed proofId, uint256 indexed modelId, uint256 verifiedPerformanceMetric);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "CognitoNet: Only owner can call this function");
        _;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "CognitoNet: User not registered");
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        require(aiModels[_modelId].id == _modelId, "CognitoNet: Model does not exist");
        require(aiModels[_modelId].owner == msg.sender, "CognitoNet: Not model owner");
        _;
    }

    modifier onlyDatasetOwner(uint256 _datasetId) {
        require(datasets[_datasetId].id == _datasetId, "CognitoNet: Dataset does not exist");
        require(datasets[_datasetId].owner == msg.sender, "CognitoNet: Not dataset owner");
        _;
    }

    modifier onlyBountyCreator(uint256 _bountyId) {
        require(researchBounties[_bountyId].id == _bountyId, "CognitoNet: Bounty does not exist");
        require(researchBounties[_bountyId].creator == msg.sender, "CognitoNet: Not bounty creator");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        serviceFeeBps = 500; // 5% fee in basis points (500/10000)
        nextModelId = 1;
        nextDatasetId = 1;
        nextBountyId = 1;
        nextLicenseId = 1;
        nextZKProofSubmissionId = 1;
    }

    // --- I. Core Configuration & Access Control ---

    /// @notice Allows the contract owner to update the service fee percentage.
    /// @param newFeeBps The new fee in basis points (e.g., 100 for 1%, 500 for 5%). Max 10000 (100%).
    function updateServiceFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 10000, "CognitoNet: Fee cannot exceed 100%");
        serviceFeeBps = newFeeBps;
        emit ServiceFeeUpdated(newFeeBps);
    }

    /// @notice Allows the contract owner to withdraw accumulated service fees.
    function withdrawFees() external onlyOwner {
        uint256 amount = totalCollectedFees;
        require(amount > 0, "CognitoNet: No fees to withdraw");
        totalCollectedFees = 0;
        (bool success, ) = payable(_owner).call{value: amount}("");
        require(success, "CognitoNet: Fee withdrawal failed");
        emit FeesWithdrawn(_owner, amount);
    }

    // --- II. User & Profile Management ---

    /// @notice Registers a new user profile on the platform.
    /// @param name The user's chosen display name.
    /// @param bio A short biography or description for the user.
    function registerUser(string calldata name, string calldata bio) external {
        require(!users[msg.sender].isRegistered, "CognitoNet: User already registered");
        require(bytes(name).length > 0, "CognitoNet: Name cannot be empty");

        users[msg.sender] = UserProfile({
            name: name,
            bio: bio,
            userAddress: msg.sender,
            registeredTimestamp: block.timestamp,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, name);
    }

    /// @notice Updates an existing user's profile information.
    /// @param newName The user's new display name.
    /// @param newBio The user's new biography.
    function updateUserProfile(string calldata newName, string calldata newBio) external onlyRegisteredUser {
        require(bytes(newName).length > 0, "CognitoNet: Name cannot be empty");
        users[msg.sender].name = newName;
        users[msg.sender].bio = newBio;
        emit UserProfileUpdated(msg.sender, newName);
    }

    /// @notice Retrieves the profile details for a given user address.
    /// @param userAddress The address of the user.
    /// @return A UserProfile struct containing the user's details.
    function getUserProfile(address userAddress) external view returns (UserProfile memory) {
        require(users[userAddress].isRegistered, "CognitoNet: User not registered");
        return users[userAddress];
    }

    // --- III. AI Model Management ---

    /// @notice Proposes a new AI model to the network.
    /// @param name The name of the AI model.
    /// @param description A description of the model and its capabilities.
    /// @param ipfsHash IPFS hash linking to the model's manifest or metadata.
    /// @param suggestedLicenseFee The suggested ETH amount for licensing this model.
    /// @return The ID of the newly proposed AI model.
    function proposeAIModel(
        string calldata name,
        string calldata description,
        string calldata ipfsHash,
        uint256 suggestedLicenseFee
    ) external onlyRegisteredUser returns (uint256) {
        require(bytes(name).length > 0, "CognitoNet: Model name cannot be empty");
        require(bytes(ipfsHash).length > 0, "CognitoNet: IPFS hash cannot be empty");

        uint256 modelId = nextModelId++;
        aiModels[modelId] = AIModel({
            id: modelId,
            owner: msg.sender,
            name: name,
            description: description,
            ipfsHash: ipfsHash,
            suggestedLicenseFee: suggestedLicenseFee,
            proposedTimestamp: block.timestamp,
            isActive: true,
            latestVerifiedPerformance: 0,
            latestVerifiedProofIpfsHash: ""
        });
        emit AIModelProposed(modelId, msg.sender, name, ipfsHash);
        return modelId;
    }

    /// @notice Allows the owner of an AI model to update its description or IPFS hash.
    /// @param modelId The ID of the AI model to update.
    /// @param newDescription The new description for the model.
    /// @param newIpfsHash The new IPFS hash for the model's manifest.
    function updateAIModel(
        uint256 modelId,
        string calldata newDescription,
        string calldata newIpfsHash
    ) external onlyModelOwner(modelId) {
        require(aiModels[modelId].isActive, "CognitoNet: Model is deprecated");
        require(bytes(newDescription).length > 0, "CognitoNet: Description cannot be empty");
        require(bytes(newIpfsHash).length > 0, "CognitoNet: IPFS hash cannot be empty");

        aiModels[modelId].description = newDescription;
        aiModels[modelId].ipfsHash = newIpfsHash;
        emit AIModelUpdated(modelId, newDescription, newIpfsHash);
    }

    /// @notice Marks an AI model as deprecated, preventing new uses or licenses.
    /// @param modelId The ID of the AI model to deprecate.
    function deprecateAIModel(uint256 modelId) external onlyModelOwner(modelId) {
        require(aiModels[modelId].isActive, "CognitoNet: Model already deprecated");
        aiModels[modelId].isActive = false;
        emit AIModelDeprecated(modelId);
    }

    /// @notice Retrieves the details of a specific AI model.
    /// @param modelId The ID of the AI model.
    /// @return An AIModel struct containing the model's details.
    function getAIModel(uint256 modelId) external view returns (AIModel memory) {
        require(aiModels[modelId].id == modelId, "CognitoNet: Model does not exist");
        return aiModels[modelId];
    }

    // --- IV. Dataset Management ---

    /// @notice Proposes a new dataset to the network.
    /// @param name The name of the dataset.
    /// @param description A description of the dataset and its contents.
    /// @param ipfsHash IPFS hash linking to the dataset's manifest or metadata.
    /// @param isPrivate A flag indicating if the dataset contains sensitive/private data.
    /// @return The ID of the newly proposed dataset.
    function proposeDataset(
        string calldata name,
        string calldata description,
        string calldata ipfsHash,
        bool isPrivate
    ) external onlyRegisteredUser returns (uint256) {
        require(bytes(name).length > 0, "CognitoNet: Dataset name cannot be empty");
        require(bytes(ipfsHash).length > 0, "CognitoNet: IPFS hash cannot be empty");

        uint256 datasetId = nextDatasetId++;
        datasets[datasetId] = Dataset({
            id: datasetId,
            owner: msg.sender,
            name: name,
            description: description,
            ipfsHash: ipfsHash,
            isPrivate: isPrivate,
            proposedTimestamp: block.timestamp,
            isActive: true
        });
        emit DatasetProposed(datasetId, msg.sender, name, ipfsHash);
        return datasetId;
    }

    /// @notice Allows the owner of a dataset to update its description or IPFS hash.
    /// @param datasetId The ID of the dataset to update.
    /// @param newDescription The new description for the dataset.
    /// @param newIpfsHash The new IPFS hash for the dataset's manifest.
    function updateDataset(
        uint256 datasetId,
        string calldata newDescription,
        string calldata newIpfsHash
    ) external onlyDatasetOwner(datasetId) {
        require(datasets[datasetId].isActive, "CognitoNet: Dataset is deprecated");
        require(bytes(newDescription).length > 0, "CognitoNet: Description cannot be empty");
        require(bytes(newIpfsHash).length > 0, "CognitoNet: IPFS hash cannot be empty");

        datasets[datasetId].description = newDescription;
        datasets[datasetId].ipfsHash = newIpfsHash;
        emit DatasetUpdated(datasetId, newDescription, newIpfsHash);
    }

    /// @notice Retrieves the details of a specific dataset.
    /// @param datasetId The ID of the dataset.
    /// @return A Dataset struct containing the dataset's details.
    function getDataset(uint256 datasetId) external view returns (Dataset memory) {
        require(datasets[datasetId].id == datasetId, "CognitoNet: Dataset does not exist");
        return datasets[datasetId];
    }

    // --- V. Research Bounties ---

    /// @notice Creates a new research bounty for AI model or data development.
    /// @param title The title of the research bounty.
    /// @param description A detailed description of the bounty's objectives.
    /// @param rewardAmount The target ETH reward for the winning solution.
    /// @param submissionDeadline The timestamp by which solutions must be submitted.
    /// @return The ID of the newly created research bounty.
    function createResearchBounty(
        string calldata title,
        string calldata description,
        uint256 rewardAmount,
        uint256 submissionDeadline
    ) external onlyRegisteredUser returns (uint256) {
        require(bytes(title).length > 0, "CognitoNet: Bounty title cannot be empty");
        require(rewardAmount > 0, "CognitoNet: Reward must be greater than zero");
        require(submissionDeadline > block.timestamp, "CognitoNet: Deadline must be in the future");

        uint256 bountyId = nextBountyId++;
        researchBounties[bountyId] = ResearchBounty({
            id: bountyId,
            creator: msg.sender,
            title: title,
            description: description,
            rewardAmount: rewardAmount,
            fundedAmount: 0,
            submissionDeadline: submissionDeadline,
            creationTimestamp: block.timestamp,
            isOpen: true,
            winnerSolutionIndex: type(uint256).max, // Sentinel value for no winner
            solutions: new Solution[](0)
        });
        emit ResearchBountyCreated(bountyId, msg.sender, title, rewardAmount, submissionDeadline);
        return bountyId;
    }

    /// @notice Allows users to fund a specific research bounty.
    /// @param bountyId The ID of the bounty to fund.
    function fundResearchBounty(uint256 bountyId) external payable onlyRegisteredUser {
        ResearchBounty storage bounty = researchBounties[bountyId];
        require(bounty.id == bountyId, "CognitoNet: Bounty does not exist");
        require(bounty.isOpen, "CognitoNet: Bounty is not open for funding");
        require(msg.value > 0, "CognitoNet: Must send ETH to fund bounty");

        bounty.fundedAmount += msg.value;
        emit ResearchBountyFunded(bountyId, msg.sender, msg.value);
    }

    /// @notice Submits a solution to an open research bounty.
    /// @param bountyId The ID of the bounty.
    /// @param solutionIpfsHash IPFS hash linking to the solution details (e.g., model, code, report).
    /// @param modelId The ID of an existing AI model on the platform that the solution uses or creates.
    function submitBountySolution(
        uint256 bountyId,
        string calldata solutionIpfsHash,
        uint256 modelId
    ) external onlyRegisteredUser {
        ResearchBounty storage bounty = researchBounties[bountyId];
        require(bounty.id == bountyId, "CognitoNet: Bounty does not exist");
        require(bounty.isOpen, "CognitoNet: Bounty is not open for submissions");
        require(block.timestamp <= bounty.submissionDeadline, "CognitoNet: Submission deadline passed");
        require(aiModels[modelId].id == modelId, "CognitoNet: Provided AI Model does not exist");
        require(aiModels[modelId].isActive, "CognitoNet: Provided AI Model is deprecated");

        bounty.solutions.push(Solution({
            submitter: msg.sender,
            solutionIpfsHash: solutionIpfsHash,
            modelId: modelId,
            submittedTimestamp: block.timestamp,
            approved: false
        }));
        emit BountySolutionSubmitted(bountyId, msg.sender, bounty.solutions.length - 1, solutionIpfsHash);
    }

    /// @notice Approves a submitted solution for a bounty, distributes rewards, and assigns reputation.
    /// @param bountyId The ID of the bounty.
    /// @param solutionIndex The index of the winning solution in the bounty's solutions array.
    function approveBountySolution(uint256 bountyId, uint256 solutionIndex) external onlyBountyCreator(bountyId) {
        ResearchBounty storage bounty = researchBounties[bountyId];
        require(bounty.isOpen, "CognitoNet: Bounty is already closed");
        require(solutionIndex < bounty.solutions.length, "CognitoNet: Invalid solution index");
        Solution storage winningSolution = bounty.solutions[solutionIndex];
        require(!winningSolution.approved, "CognitoNet: Solution already approved");

        winningSolution.approved = true;
        bounty.isOpen = false;
        bounty.winnerSolutionIndex = solutionIndex;

        // Calculate service fee
        uint256 fee = (bounty.fundedAmount * serviceFeeBps) / 10000;
        totalCollectedFees += fee;
        uint256 payoutAmount = bounty.fundedAmount - fee;

        // Distribute reward
        (bool success, ) = payable(winningSolution.submitter).call{value: payoutAmount}("");
        require(success, "CognitoNet: Reward payout failed");

        // Issue reputation points for bounty winner
        _issueReputationPointInternal(winningSolution.submitter, "Bounty Winner", 50);
        _issueReputationPointInternal(bounty.creator, "Bounty Creator", 10); // Creator also gets some rep

        emit BountySolutionApproved(bountyId, solutionIndex, winningSolution.submitter, payoutAmount);
    }

    /// @notice Retrieves the details of a specific research bounty.
    /// @param bountyId The ID of the bounty.
    /// @return A ResearchBounty struct containing the bounty's details.
    function getResearchBounty(uint256 bountyId) external view returns (ResearchBounty memory) {
        require(researchBounties[bountyId].id == bountyId, "CognitoNet: Bounty does not exist");
        return researchBounties[bountyId];
    }

    /// @notice Retrieves a specific solution for a given bounty.
    /// @param bountyId The ID of the bounty.
    /// @param solutionIndex The index of the solution within the bounty's solutions array.
    /// @return A Solution struct containing the solution's details.
    function getBountySolution(uint256 bountyId, uint256 solutionIndex) external view returns (Solution memory) {
        ResearchBounty storage bounty = researchBounties[bountyId];
        require(bounty.id == bountyId, "CognitoNet: Bounty does not exist");
        require(solutionIndex < bounty.solutions.length, "CognitoNet: Invalid solution index");
        return bounty.solutions[solutionIndex];
    }

    // --- VI. Reputation System (Soulbound-like) ---

    /// @dev Internal helper function to issue reputation points, called by other contract functions.
    /// @param recipient The address to which reputation points are issued.
    /// @param reason A string describing why the points were issued.
    /// @param points The number of points (can be positive or negative).
    function _issueReputationPointInternal(address recipient, string memory reason, int256 points) internal {
        userReputation[recipient].push(ReputationEntry({
            entity: recipient,
            reason: reason,
            points: points,
            timestamp: block.timestamp,
            challenged: false,
            challengeReason: ""
        }));
        emit ReputationPointsIssued(recipient, address(this), reason, points); // Issuer is contract for internal calls
    }

    /// @notice Allows the contract owner (or a designated reputation council) to manually issue reputation points.
    /// @param recipient The address to which reputation points are issued.
    /// @param reason A string describing why the points were issued.
    /// @param points The number of points (can be positive or negative).
    function issueReputationPoint(address recipient, string calldata reason, int256 points) external onlyOwner {
        require(users[recipient].isRegistered, "CognitoNet: Recipient not registered");
        userReputation[recipient].push(ReputationEntry({
            entity: recipient,
            reason: reason,
            points: points,
            timestamp: block.timestamp,
            challenged: false,
            challengeReason: ""
        }));
        emit ReputationPointsIssued(recipient, msg.sender, reason, points);
    }

    /// @notice Allows a user to challenge a specific reputation entry on another user's profile.
    /// @param target The address of the user whose reputation entry is being challenged.
    /// @param entryIndex The index of the specific reputation entry to challenge.
    /// @param reason A detailed reason for challenging the entry.
    function challengeReputation(address target, uint256 entryIndex, string calldata reason) external onlyRegisteredUser {
        require(users[target].isRegistered, "CognitoNet: Target user not registered");
        require(entryIndex < userReputation[target].length, "CognitoNet: Invalid reputation entry index");
        ReputationEntry storage entry = userReputation[target][entryIndex];
        require(!entry.challenged, "CognitoNet: Reputation entry already challenged");
        require(bytes(reason).length > 0, "CognitoNet: Challenge reason cannot be empty");

        entry.challenged = true;
        entry.challengeReason = reason;
        // In a real system, this would trigger a dispute resolution process (e.g., via a DAO or oracle)
        emit ReputationChallenged(target, entryIndex, reason);
    }

    /// @notice Calculates and returns the total active reputation score for a user.
    ///         Challenged entries are not included in the total.
    /// @param userAddress The address of the user.
    /// @return The total reputation score as an int256.
    function getTotalReputation(address userAddress) external view returns (int256) {
        int256 total = 0;
        for (uint256 i = 0; i < userReputation[userAddress].length; i++) {
            if (!userReputation[userAddress][i].challenged) {
                total += userReputation[userAddress][i].points;
            }
        }
        return total;
    }

    // --- VII. Intellectual Property (IP) & Licensing ---

    /// @notice Allows a user to request a license to use an AI model or a dataset.
    /// @param modelId The ID of the model to license (0 if not applicable).
    /// @param datasetId The ID of the dataset to license (0 if not applicable).
    /// @param paymentAmount The ETH amount to be paid for the license.
    /// @return The ID of the newly created IP license.
    function requestIPLicense(
        uint256 modelId,
        uint256 datasetId,
        uint256 paymentAmount
    ) external payable onlyRegisteredUser returns (uint256) {
        require(modelId > 0 || datasetId > 0, "CognitoNet: Must specify a model or a dataset to license");
        require(modelId == 0 || (aiModels[modelId].id == modelId && aiModels[modelId].isActive), "CognitoNet: Invalid or deprecated model ID");
        require(datasetId == 0 || (datasets[datasetId].id == datasetId && datasets[datasetId].isActive), "CognitoNet: Invalid or deprecated dataset ID");
        require(paymentAmount == msg.value, "CognitoNet: Sent ETH must match agreed payment amount");
        
        address licensorAddress;
        if (modelId > 0) {
            licensorAddress = aiModels[modelId].owner;
            require(msg.value >= aiModels[modelId].suggestedLicenseFee, "CognitoNet: Payment below suggested model license fee");
        } else { // datasetId > 0
            licensorAddress = datasets[datasetId].owner;
        }
        require(licensorAddress != address(0), "CognitoNet: Licensor address not found");
        require(licensorAddress != msg.sender, "CognitoNet: Cannot license your own IP");

        uint256 licenseId = nextLicenseId++;
        ipLicenses[licenseId] = IPLicense({
            id: licenseId,
            licensor: licensorAddress,
            licensee: msg.sender,
            modelId: modelId,
            datasetId: datasetId,
            agreedPaymentAmount: paymentAmount,
            requestTimestamp: block.timestamp,
            approvalTimestamp: 0,
            approved: false,
            revoked: false
        });

        // Transfer funds to licensor, deducting service fee
        uint256 fee = (paymentAmount * serviceFeeBps) / 10000;
        totalCollectedFees += fee;
        uint256 netPayout = paymentAmount - fee;
        (bool success, ) = payable(licensorAddress).call{value: netPayout}("");
        require(success, "CognitoNet: Payment to licensor failed");

        emit IPLicenseRequested(licenseId, licensorAddress, msg.sender, modelId, datasetId, paymentAmount);
        return licenseId;
    }

    /// @notice Allows the IP owner (licensor) to approve a pending license request.
    /// @param licenseId The ID of the license to approve.
    function approveIPLicense(uint256 licenseId) external {
        IPLicense storage license = ipLicenses[licenseId];
        require(license.id == licenseId, "CognitoNet: License does not exist");
        require(!license.approved, "CognitoNet: License already approved");
        require(!license.revoked, "CognitoNet: License revoked");

        // Check if caller is the licensor of the model or dataset
        bool isLicensor = false;
        if (license.modelId > 0 && aiModels[license.modelId].owner == msg.sender) {
            isLicensor = true;
        } else if (license.datasetId > 0 && datasets[license.datasetId].owner == msg.sender) {
            isLicensor = true;
        }
        require(isLicensor, "CognitoNet: Only the IP owner can approve this license");

        license.approved = true;
        license.approvalTimestamp = block.timestamp;
        _issueReputationPointInternal(license.licensor, "IP Licensed", 5); // Licensor gets rep for successful licensing
        _issueReputationPointInternal(license.licensee, "Acquired IP License", 2); // Licensee gets rep for acquiring

        emit IPLicenseApproved(licenseId, license.licensor, license.licensee);
    }

    /// @notice Allows the IP owner (licensor) to revoke an existing license.
    /// @param licenseId The ID of the license to revoke.
    function revokeIPLicense(uint256 licenseId) external {
        IPLicense storage license = ipLicenses[licenseId];
        require(license.id == licenseId, "CognitoNet: License does not exist");
        require(license.approved, "CognitoNet: License not yet approved or already revoked");
        require(!license.revoked, "CognitoNet: License already revoked");

        // Check if caller is the licensor of the model or dataset
        bool isLicensor = false;
        if (license.modelId > 0 && aiModels[license.modelId].owner == msg.sender) {
            isLicensor = true;
        } else if (license.datasetId > 0 && datasets[license.datasetId].owner == msg.sender) {
            isLicensor = true;
        }
        require(isLicensor, "CognitoNet: Only the IP owner can revoke this license");

        license.revoked = true;
        _issueReputationPointInternal(license.licensor, "IP License Revoked", -3); // Minor rep loss for revocation
        emit IPLicenseRevoked(licenseId, license.licensor, license.licensee);
    }

    /// @notice Retrieves the details of a specific IP license.
    /// @param licenseId The ID of the license.
    /// @return An IPLicense struct containing the license's details.
    function getIPLicense(uint256 licenseId) external view returns (IPLicense memory) {
        require(ipLicenses[licenseId].id == licenseId, "CognitoNet: License does not exist");
        return ipLicenses[licenseId];
    }

    // --- VIII. ZK-Proof Integration (Simulated) ---

    /// @notice Allows a model owner to submit a simulated ZK-proof for a model's performance.
    ///         This proof, in a real system, would cryptographically attest to performance
    ///         without revealing the underlying data or exact model parameters.
    /// @param modelId The ID of the AI model the proof pertains to.
    /// @param proofIpfsHash IPFS hash linking to the full ZK-proof data.
    /// @param claimedPerformanceMetric The performance metric claimed by the proof (e.g., accuracy, F1 score).
    /// @return The ID of the newly submitted ZK proof.
    function submitZKPerformanceProof(
        uint256 modelId,
        string calldata proofIpfsHash,
        uint256 claimedPerformanceMetric
    ) external onlyModelOwner(modelId) returns (uint256) {
        require(aiModels[modelId].isActive, "CognitoNet: Model is deprecated");
        require(bytes(proofIpfsHash).length > 0, "CognitoNet: Proof IPFS hash cannot be empty");
        require(claimedPerformanceMetric > 0, "CognitoNet: Claimed performance must be positive");

        uint256 proofId = nextZKProofSubmissionId++;
        zkProofSubmissions[proofId] = ZKProofSubmission({
            id: proofId,
            modelId: modelId,
            submitter: msg.sender,
            proofIpfsHash: proofIpfsHash,
            claimedPerformanceMetric: claimedPerformanceMetric,
            verified: false,
            verificationTimestamp: 0,
            verifier: address(0)
        });
        modelZKProofs[modelId].push(proofId);
        emit ZKPerformanceProofSubmitted(proofId, modelId, msg.sender, claimedPerformanceMetric);
        return proofId;
    }

    /// @notice Simulates the verification of a ZK-proof. In a real application, this would involve
    ///         complex on-chain cryptographic verification or an oracle. Here, the contract owner
    ///         acts as the verifier for demonstration purposes.
    ///         Upon successful (simulated) verification, the model's performance is updated,
    ///         and reputation points are awarded.
    /// @param modelId The ID of the model associated with the proof.
    /// @param proofIndex The index of the ZK-proof submission within the model's proofs array.
    function verifyZKProof(uint256 modelId, uint256 proofIndex) external onlyOwner {
        require(aiModels[modelId].id == modelId, "CognitoNet: Model does not exist");
        require(proofIndex < modelZKProofs[modelId].length, "CognitoNet: Invalid proof index for model");

        uint256 proofId = modelZKProofs[modelId][proofIndex];
        ZKProofSubmission storage proofSubmission = zkProofSubmissions[proofId];

        require(!proofSubmission.verified, "CognitoNet: Proof already verified");

        // --- SIMULATION START ---
        // In a real scenario, this block would contain the actual ZK-SNARK/STARK verification logic.
        // For example: `require(verifierContract.verify(proofSubmission.proofData), "ZK-Proof verification failed");`
        // Or: `(bool isValid) = IOracle(oracleAddress).requestVerification(proofSubmission.proofIpfsHash);`
        // For this example, we simply set it to verified by the owner.
        proofSubmission.verified = true; // Assume verification is successful
        // --- SIMULATION END ---

        proofSubmission.verificationTimestamp = block.timestamp;
        proofSubmission.verifier = msg.sender; // The owner acts as the conceptual verifier

        // Update the model's latest verified performance
        aiModels[modelId].latestVerifiedPerformance = proofSubmission.claimedPerformanceMetric;
        aiModels[modelId].latestVerifiedProofIpfsHash = proofSubmission.proofIpfsHash;

        // Issue reputation points for successful ZK proof verification
        _issueReputationPointInternal(proofSubmission.submitter, "ZK Proof Verified", 25);
        _issueReputationPointInternal(aiModels[modelId].owner, "Model Performance Verified", 5);

        emit ZKPerformanceProofVerified(proofId, modelId, proofSubmission.claimedPerformanceMetric);
    }

    // --- IX. Utility & Queries ---

    /// @notice Returns the address of the contract owner.
    function getOwner() public view returns (address) {
        return _owner;
    }
}
```