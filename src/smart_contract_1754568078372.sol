This smart contract, **VeritasAI**, envisions a decentralized platform for collaborative AI model development and scientific data validation, focusing on trust, reputation, and incentivization. It incorporates advanced concepts like a simulated Zero-Knowledge Proof (ZK-Proof) verification, a commit-reveal scheme for validation, a dynamic domain-specific reputation system, decentralized governance for funding research, and a unique approach to managing AI model lifecycle from proposal to validation.

It aims to avoid direct duplication of existing open-source projects by combining these elements into a novel ecosystem where scientific integrity is upheld through on-chain mechanics.

---

### **Outline & Function Summary**

**Contract Name:** `VeritasAI`

**Core Concepts:**
*   **Decentralized Identity (DID) Integration:** Users register with an IPNS-based DID for persistent identity.
*   **Domain-Specific Reputation:** Reputation scores tied to specific research/AI domains, allowing nuanced expertise tracking.
*   **AI Model Lifecycle Management:** From proposing a model to its validation and challenge resolution.
*   **Commit-Reveal Validation:** A two-phase process to prevent front-running validator results.
*   **Simulated ZK-Proof Verification:** Placeholder for verifying off-chain AI model correctness without revealing inputs/outputs.
*   **Decentralized Data Marketplace (Metadata):** Registering and granting access to scientific datasets based on metadata.
*   **Reputation Delegation:** Entities can delegate their reputation to others for voting or validation weight.
*   **DeSci DAO Governance:** Funding proposals for research projects, voted on by the community.

---

**I. Core Registry & Identity Management**
1.  `registerResearcher(string calldata _ipnsDid, string calldata _researchDomain)`: Allows an address to register as a researcher with a unique IPNS DID and primary research domain.
2.  `registerValidator(string calldata _ipnsDid, string calldata _expertiseField)`: Allows an address to register as a validator, specifying their expertise field.
3.  `updateProfileDID(uint256 _entityId, string calldata _newIpnsDid)`: Allows a registered entity to update their associated IPNS DID.
4.  `getEntityReputation(uint256 _entityId, uint256 _domainId)`: Retrieves the current reputation score for an entity within a specific domain.

**II. Dataset Management & Access Control**
5.  `submitDatasetMetadata(string calldata _datasetHash, string calldata _title, string calldata _description, string calldata _cidV1, uint256 _accessFee)`: Registers metadata for a new scientific dataset, allowing the owner to set an access fee. The actual data is stored off-chain (referenced by CID/hash).
6.  `requestDatasetAccess(uint256 _datasetId)`: Allows an entity to request access to a private dataset, potentially paying the access fee.
7.  `grantDatasetAccess(uint256 _datasetId, address _grantee)`: Dataset owner grants specific address access to their dataset.
8.  `revokeDatasetAccess(uint256 _datasetId, address _grantee)`: Dataset owner revokes access for a specific address.
9.  `getDatasetAccessDetails(uint256 _datasetId, address _account)`: Checks if an account has access to a given dataset.

**III. AI Model Lifecycle & Validation**
10. `proposeAIModel(string calldata _modelHash, string calldata _name, string calldata _description, uint256 _expectedComputeCost, uint256 _validationStakeAmount)`: A researcher proposes a new AI model for validation, specifying its metadata and required stake for validators.
11. `submitValidationCommit(uint256 _modelId, bytes32 _commitHash)`: A validator commits to a hashed result for a given AI model, without revealing the actual result yet (part of commit-reveal).
12. `revealValidationResult(uint256 _modelId, bytes32 _trueResultHash, string calldata _additionalProofCid, bytes calldata _onChainProof)`: A validator reveals their validation result. `_onChainProof` simulates a ZK-proof that can be verified on-chain.
13. `challengeValidationResult(uint256 _modelId, uint256 _validationId, string calldata _challengeReasonCid)`: Allows any entity to challenge a revealed validation result, providing reasons off-chain.
14. `resolveChallenge(uint256 _challengeId, bool _challengerWins, string calldata _resolutionDetailsCid)`: An elected or committee (off-chain) resolves a challenge, updating reputation and stakes accordingly.

**IV. Reputation & Incentives**
15. `updateReputation(uint256 _entityId, int256 _changeAmount, uint256 _domainId)`: Internal function called to update an entity's reputation score in a specific domain based on their actions (e.g., successful validation, challenge resolution).
16. `delegateReputation(uint256 _delegatorId, uint256 _delegateeId, uint256 _amount)`: Allows an entity to delegate a portion of their reputation (voting/validation power) to another entity.
17. `undelegateReputation(uint256 _delegatorId, uint256 _delegateeId, uint256 _amount)`: Allows an entity to reclaim previously delegated reputation.
18. `claimValidationReward(uint256 _validationId)`: Allows a successful validator to claim their earned rewards and stake back.

**V. Decentralized Governance & Funding (DeSci DAO)**
19. `proposeFundingRequest(string calldata _projectName, string calldata _projectDetailsCid, uint256 _requestedAmount)`: Researchers can propose funding requests for scientific projects, providing details off-chain.
20. `voteOnProposal(uint256 _proposalId, bool _support)`: Registered entities vote on active funding proposals, their vote weight influenced by their reputation.
21. `executeProposal(uint256 _proposalId)`: After a proposal passes the voting period and quorum, this function executes the proposal (e.g., transferring funds).
22. `depositToTreasury()`: Allows anyone to contribute funds to the DAO's treasury.
23. `setGovernanceParameter(uint256 _paramType, uint256 _newValue)`: DAO members (via a governance proposal) can adjust core parameters like voting periods or quorum thresholds.

**VI. System Utilities & Security**
24. `emergencyPause()`: Owner can pause critical contract functions in case of an emergency.
25. `unpause()`: Owner can unpause the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity for emergency controls, can be replaced by more complex governance

/**
 * @title VeritasAI
 * @dev A decentralized platform for collaborative AI model development and scientific data validation.
 *      Focuses on trust, reputation, and incentivization through advanced on-chain mechanics.
 *
 * Outline & Function Summary:
 *
 * I. Core Registry & Identity Management
 * 1. registerResearcher(string calldata _ipnsDid, string calldata _researchDomain): Registers an address as a researcher.
 * 2. registerValidator(string calldata _ipnsDid, string calldata _expertiseField): Registers an address as a validator.
 * 3. updateProfileDID(uint256 _entityId, string calldata _newIpnsDid): Updates an entity's IPNS DID.
 * 4. getEntityReputation(uint256 _entityId, uint256 _domainId): Retrieves an entity's domain-specific reputation.
 *
 * II. Dataset Management & Access Control
 * 5. submitDatasetMetadata(string calldata _datasetHash, string calldata _title, string calldata _description, string calldata _cidV1, uint256 _accessFee): Registers dataset metadata.
 * 6. requestDatasetAccess(uint256 _datasetId): Requests access to a private dataset.
 * 7. grantDatasetAccess(uint256 _datasetId, address _grantee): Owner grants dataset access.
 * 8. revokeDatasetAccess(uint256 _datasetId, address _grantee): Owner revokes dataset access.
 * 9. getDatasetAccessDetails(uint256 _datasetId, address _account): Checks dataset access.
 *
 * III. AI Model Lifecycle & Validation
 * 10. proposeAIModel(string calldata _modelHash, string calldata _name, string calldata _description, uint256 _expectedComputeCost, uint256 _validationStakeAmount): Proposes a new AI model.
 * 11. submitValidationCommit(uint256 _modelId, bytes32 _commitHash): Validator commits to a hashed validation result.
 * 12. revealValidationResult(uint256 _modelId, bytes32 _trueResultHash, string calldata _additionalProofCid, bytes calldata _onChainProof): Validator reveals result and ZK-proof.
 * 13. challengeValidationResult(uint256 _modelId, uint256 _validationId, string calldata _challengeReasonCid): Challenges a validation result.
 * 14. resolveChallenge(uint256 _challengeId, bool _challengerWins, string calldata _resolutionDetailsCid): Resolves a validation challenge.
 *
 * IV. Reputation & Incentives
 * 15. updateReputation(uint256 _entityId, int256 _changeAmount, uint256 _domainId): Internal function to adjust reputation.
 * 16. delegateReputation(uint256 _delegatorId, uint256 _delegateeId, uint256 _amount): Delegates reputation to another entity.
 * 17. undelegateReputation(uint256 _delegatorId, uint256 _delegateeId, uint256 _amount): Undelegates reputation.
 * 18. claimValidationReward(uint256 _validationId): Claims rewards for successful validation.
 *
 * V. Decentralized Governance & Funding (DeSci DAO)
 * 19. proposeFundingRequest(string calldata _projectName, string calldata _projectDetailsCid, uint256 _requestedAmount): Proposes a project funding request.
 * 20. voteOnProposal(uint256 _proposalId, bool _support): Votes on a funding proposal.
 * 21. executeProposal(uint256 _proposalId): Executes a passed funding proposal.
 * 22. depositToTreasury(): Allows contributions to the DAO treasury.
 * 23. setGovernanceParameter(uint256 _paramType, uint256 _newValue): Adjusts DAO governance parameters.
 *
 * VI. System Utilities & Security
 * 24. emergencyPause(): Pauses critical functions.
 * 25. unpause(): Unpauses critical functions.
 */
contract VeritasAI is Ownable {

    // --- State Variables ---

    // Entity Registry
    enum EntityRole { None, Researcher, Validator }
    struct Entity {
        uint256 id;
        address walletAddress;
        string ipnsDid; // IPNS-based Decentralized Identifier
        EntityRole role;
        // Mapping from domain ID to reputation score
        mapping(uint256 => int256) reputationScores;
        // Mapping from domain ID to total delegated reputation from others
        mapping(uint256 => uint256) totalDelegatedReputation;
        // Mapping from delegatee ID to amount delegated to them
        mapping(uint256 => uint256) delegatedTo;
        // Mapping from delegator ID to amount delegated by them
        mapping(uint256 => uint256) delegatedBy;
    }
    uint256 public nextEntityId = 1;
    // Map wallet address to entity ID
    mapping(address => uint256) public walletToEntityId;
    // Map entity ID to Entity struct
    mapping(uint256 => Entity) public entities;

    // Domain Registry (for reputation)
    uint256 public nextDomainId = 1;
    mapping(string => uint256) public domainNameToId;
    mapping(uint256 => string) public domainIdToName;

    // Dataset Registry
    enum DatasetAccessType { Free, Paid, Private }
    struct Dataset {
        uint256 id;
        uint256 ownerEntityId;
        string datasetHash; // SHA256 of the dataset content (off-chain)
        string title;
        string description;
        string cidV1; // IPFS CID v1 for content addressability
        uint256 accessFee; // In native token (wei)
        mapping(address => bool) accessGranted; // address has access to raw data
        DatasetAccessType accessType;
    }
    uint256 public nextDatasetId = 1;
    mapping(uint256 => Dataset) public datasets;

    // AI Model Registry
    enum ModelStatus { Proposed, Validating, Validated, Challenged, Rejected }
    struct AIModel {
        uint256 id;
        uint256 proposerEntityId;
        string modelHash; // Hash of the AI model files (off-chain)
        string name;
        string description;
        uint256 expectedComputeCost; // Estimated cost for off-chain computation
        uint256 validationStakeAmount; // Required stake from validators
        ModelStatus status;
        uint256 currentValidationId; // ID of the currently active validation
        uint256 validatedAt;
    }
    uint256 public nextModelId = 1;
    mapping(uint256 => AIModel) public aiModels;

    // Validation Process (Commit-Reveal & ZK-Proof Concept)
    enum ValidationStatus { Committed, Revealed, Challenged, Resolved }
    struct Validation {
        uint256 id;
        uint256 modelId;
        uint256 validatorEntityId;
        bytes32 commitHash; // Hash of (trueResultHash + salt)
        bytes32 revealedResultHash; // Actual hash of the validation output
        string additionalProofCid; // IPFS CID for detailed proof/logs
        bytes onChainProof; // Placeholder for on-chain verifiable ZK-proof data
        uint256 commitTimestamp;
        uint256 revealTimestamp;
        ValidationStatus status;
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 challengeId; // If challenged
    }
    uint256 public nextValidationId = 1;
    mapping(uint256 => Validation) public validations;

    // Challenge Process
    enum ChallengeStatus { Pending, Resolved }
    struct Challenge {
        uint256 id;
        uint256 validationId;
        uint256 challengerEntityId;
        string reasonCid; // IPFS CID for detailed challenge reason
        ChallengeStatus status;
        uint256 resolutionTimestamp;
        string resolutionDetailsCid; // IPFS CID for resolution notes
        bool challengerWins;
    }
    uint256 public nextChallengeId = 1;
    mapping(uint256 => Challenge) public challenges;

    // Governance & Funding
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        uint256 proposerEntityId;
        string projectName;
        string projectDetailsCid; // IPFS CID for full proposal details
        uint256 requestedAmount; // Amount of funds requested from treasury
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(uint256 => bool) hasVoted; // EntityID => bool
        ProposalStatus status;
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;

    // Governance Parameters (can be updated by DAO votes)
    uint256 public constant MIN_REP_FOR_PROPOSAL = 100; // Minimum reputation to propose anything
    uint256 public constant MIN_REP_FOR_VOTE = 10;     // Minimum reputation to vote
    uint256 public proposalVotingPeriod = 7 days;      // Default 7 days
    uint256 public proposalQuorumPercentage = 51;      // Default 51% (of total active reputation)
    uint256 public validationCommitRevealPeriod = 1 days; // Time to reveal after commit

    // Treasury (for funding proposals and rewards)
    address public treasuryAddress;

    // Pausability
    bool public paused = false;

    // --- Events ---
    event EntityRegistered(uint256 indexed entityId, address indexed walletAddress, EntityRole role, string ipnsDid);
    event DIDUpdated(uint256 indexed entityId, string oldIpnsDid, string newIpnsDid);
    event ReputationUpdated(uint256 indexed entityId, uint256 indexed domainId, int256 changeAmount, int256 newScore);
    event ReputationDelegated(uint256 indexed delegatorId, uint256 indexed delegateeId, uint256 amount);
    event ReputationUndelegated(uint256 indexed delegatorId, uint256 indexed delegateeId, uint256 amount);

    event DatasetMetadataSubmitted(uint256 indexed datasetId, uint256 indexed ownerEntityId, string datasetHash, uint256 accessFee);
    event DatasetAccessRequested(uint256 indexed datasetId, address indexed requester);
    event DatasetAccessGranted(uint256 indexed datasetId, address indexed grantee);
    event DatasetAccessRevoked(uint256 indexed datasetId, address indexed revoker);

    event AIModelProposed(uint256 indexed modelId, uint256 indexed proposerEntityId, string name, uint256 validationStakeAmount);
    event ValidationCommitSubmitted(uint256 indexed validationId, uint256 indexed modelId, uint256 indexed validatorEntityId, bytes32 commitHash);
    event ValidationResultRevealed(uint256 indexed validationId, uint256 indexed modelId, bytes32 revealedResultHash, string additionalProofCid);
    event ChallengeSubmitted(uint256 indexed challengeId, uint256 indexed validationId, uint256 indexed challengerEntityId);
    event ChallengeResolved(uint256 indexed challengeId, bool challengerWins, string resolutionDetailsCid);
    event ValidationRewardClaimed(uint256 indexed validationId, uint256 indexed validatorEntityId, uint256 amount);

    event FundingProposalCreated(uint256 indexed proposalId, uint256 indexed proposerEntityId, string projectName, uint256 requestedAmount);
    event VotedOnProposal(uint256 indexed proposalId, uint256 indexed voterEntityId, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event GovernanceParameterSet(uint256 indexed paramType, uint256 newValue);

    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyRegisteredEntity() {
        require(walletToEntityId[msg.sender] != 0, "Caller is not a registered entity");
        _;
    }

    modifier onlyResearcher(uint256 _entityId) {
        require(entities[_entityId].role == EntityRole.Researcher, "Entity is not a researcher");
        _;
    }

    modifier onlyValidator(uint256 _entityId) {
        require(entities[_entityId].role == EntityRole.Validator, "Entity is not a validator");
        _;
    }

    modifier checkMinReputation(uint256 _entityId, uint256 _minRep, uint256 _domainId) {
        require(getEntityReputation(_entityId, _domainId) >= int256(_minRep), "Insufficient reputation");
        _;
    }

    // --- Constructor ---
    constructor(address _initialTreasuryAddress) Ownable(msg.sender) {
        require(_initialTreasuryAddress != address(0), "Treasury address cannot be zero");
        treasuryAddress = _initialTreasuryAddress;
    }

    // --- Internal/Private Helpers ---

    function _getOrCreateDomainId(string calldata _domainName) internal returns (uint256) {
        uint256 domainId = domainNameToId[_domainName];
        if (domainId == 0) {
            domainId = nextDomainId++;
            domainNameToId[_domainName] = domainId;
            domainIdToName[domainId] = _domainName;
        }
        return domainId;
    }

    function _registerEntity(address _walletAddress, string calldata _ipnsDid, EntityRole _role, string calldata _primaryDomainName) internal returns (uint256) {
        require(walletToEntityId[_walletAddress] == 0, "Wallet address already registered");
        require(bytes(_ipnsDid).length > 0, "DID cannot be empty");

        uint256 entityId = nextEntityId++;
        entities[entityId].id = entityId;
        entities[entityId].walletAddress = _walletAddress;
        entities[entityId].ipnsDid = _ipnsDid;
        entities[entityId].role = _role;
        walletToEntityId[_walletAddress] = entityId;

        uint256 domainId = _getOrCreateDomainId(_primaryDomainName);
        entities[entityId].reputationScores[domainId] = 0; // Initialize reputation

        return entityId;
    }

    /**
     * @dev Internal function to update an entity's reputation score.
     *      Can be called by challenge resolution, successful validation, etc.
     * @param _entityId The ID of the entity whose reputation is being updated.
     * @param _changeAmount The amount to change the reputation by (can be negative).
     * @param _domainId The ID of the domain for which the reputation is updated.
     */
    function _updateReputation(uint256 _entityId, int256 _changeAmount, uint256 _domainId) internal {
        Entity storage entity = entities[_entityId];
        entity.reputationScores[_domainId] += _changeAmount;
        emit ReputationUpdated(_entityId, _domainId, _changeAmount, entity.reputationScores[_domainId]);
    }

    // --- I. Core Registry & Identity Management ---

    /**
     * @dev Registers the calling address as a researcher.
     * @param _ipnsDid The IPNS-based Decentralized Identifier for the researcher.
     * @param _researchDomain The primary research domain of the researcher (e.g., "AI Ethics", "Genomics").
     */
    function registerResearcher(string calldata _ipnsDid, string calldata _researchDomain) external whenNotPaused {
        uint256 entityId = _registerEntity(msg.sender, _ipnsDid, EntityRole.Researcher, _researchDomain);
        emit EntityRegistered(entityId, msg.sender, EntityRole.Researcher, _ipnsDid);
    }

    /**
     * @dev Registers the calling address as a validator.
     * @param _ipnsDid The IPNS-based Decentralized Identifier for the validator.
     * @param _expertiseField The primary field of expertise of the validator (e.g., "Deep Learning", "Bioinformatics").
     */
    function registerValidator(string calldata _ipnsDid, string calldata _expertiseField) external whenNotPaused {
        uint256 entityId = _registerEntity(msg.sender, _ipnsDid, EntityRole.Validator, _expertiseField);
        emit EntityRegistered(entityId, msg.sender, EntityRole.Validator, _ipnsDid);
    }

    /**
     * @dev Allows a registered entity to update their associated IPNS DID.
     * @param _entityId The ID of the entity to update.
     * @param _newIpnsDid The new IPNS DID to set.
     */
    function updateProfileDID(uint256 _entityId, string calldata _newIpnsDid) external onlyRegisteredEntity {
        require(walletToEntityId[msg.sender] == _entityId, "Caller does not own this entity ID");
        require(bytes(_newIpnsDid).length > 0, "New DID cannot be empty");

        string memory oldDid = entities[_entityId].ipnsDid;
        entities[_entityId].ipnsDid = _newIpnsDid;
        emit DIDUpdated(_entityId, oldDid, _newIpnsDid);
    }

    /**
     * @dev Retrieves the current reputation score for an entity within a specific domain.
     * @param _entityId The ID of the entity.
     * @param _domainId The ID of the domain.
     * @return The reputation score.
     */
    function getEntityReputation(uint256 _entityId, uint256 _domainId) public view returns (int256) {
        return entities[_entityId].reputationScores[_domainId];
    }

    // --- II. Dataset Management & Access Control ---

    /**
     * @dev Registers metadata for a new scientific dataset. The actual data is stored off-chain (e.g., IPFS).
     * @param _datasetHash Cryptographic hash of the dataset content (e.g., SHA256).
     * @param _title The title of the dataset.
     * @param _description A brief description of the dataset.
     * @param _cidV1 IPFS CID v1 pointing to the dataset content.
     * @param _accessFee The fee in wei to access the dataset (0 for free).
     */
    function submitDatasetMetadata(string calldata _datasetHash, string calldata _title, string calldata _description, string calldata _cidV1, uint256 _accessFee) external onlyRegisteredEntity whenNotPaused {
        uint256 entityId = walletToEntityId[msg.sender];
        require(entities[entityId].role == EntityRole.Researcher, "Only researchers can submit datasets");
        require(bytes(_datasetHash).length > 0 && bytes(_cidV1).length > 0, "Dataset hash and CID cannot be empty");

        uint256 datasetId = nextDatasetId++;
        datasets[datasetId].id = datasetId;
        datasets[datasetId].ownerEntityId = entityId;
        datasets[datasetId].datasetHash = _datasetHash;
        datasets[datasetId].title = _title;
        datasets[datasetId].description = _description;
        datasets[datasetId].cidV1 = _cidV1;
        datasets[datasetId].accessFee = _accessFee;
        datasets[datasetId].accessType = _accessFee == 0 ? DatasetAccessType.Free : DatasetAccessType.Paid; // Simplified logic

        emit DatasetMetadataSubmitted(datasetId, entityId, _datasetHash, _accessFee);
    }

    /**
     * @dev Allows an entity to request access to a private dataset.
     *      If the dataset is paid, the fee is transferred.
     * @param _datasetId The ID of the dataset to request access for.
     */
    function requestDatasetAccess(uint256 _datasetId) external payable onlyRegisteredEntity whenNotPaused {
        Dataset storage ds = datasets[_datasetId];
        require(ds.id != 0, "Dataset not found");
        require(!ds.accessGranted[msg.sender], "Access already granted");

        if (ds.accessType == DatasetAccessType.Paid) {
            require(msg.value >= ds.accessFee, "Insufficient payment for dataset access");
            // Transfer fee to dataset owner
            (bool success, ) = entities[ds.ownerEntityId].walletAddress.call{value: ds.accessFee}("");
            require(success, "Failed to transfer dataset access fee");
        } else if (ds.accessType == DatasetAccessType.Free) {
            require(msg.value == 0, "No payment expected for free dataset");
        } else {
             revert("Unsupported dataset access type");
        }

        ds.accessGranted[msg.sender] = true;
        emit DatasetAccessRequested(_datasetId, msg.sender);
        emit DatasetAccessGranted(_datasetId, msg.sender); // Direct grant upon request
    }


    /**
     * @dev Dataset owner grants specific address access to their dataset.
     *      Useful for private datasets or direct grants after off-chain agreements.
     * @param _datasetId The ID of the dataset.
     * @param _grantee The address to grant access to.
     */
    function grantDatasetAccess(uint256 _datasetId, address _grantee) external onlyRegisteredEntity whenNotPaused {
        Dataset storage ds = datasets[_datasetId];
        require(ds.id != 0, "Dataset not found");
        require(ds.ownerEntityId == walletToEntityId[msg.sender], "Only dataset owner can grant access");
        require(!ds.accessGranted[_grantee], "Access already granted to this address");

        ds.accessGranted[_grantee] = true;
        emit DatasetAccessGranted(_datasetId, _grantee);
    }

    /**
     * @dev Dataset owner revokes access for a specific address.
     * @param _datasetId The ID of the dataset.
     * @param _grantee The address to revoke access from.
     */
    function revokeDatasetAccess(uint256 _datasetId, address _grantee) external onlyRegisteredEntity whenNotPaused {
        Dataset storage ds = datasets[_datasetId];
        require(ds.id != 0, "Dataset not found");
        require(ds.ownerEntityId == walletToEntityId[msg.sender], "Only dataset owner can revoke access");
        require(ds.accessGranted[_grantee], "Access not granted to this address");

        ds.accessGranted[_grantee] = false;
        emit DatasetAccessRevoked(_datasetId, _grantee);
    }

    /**
     * @dev Checks if an account has access to a given dataset.
     * @param _datasetId The ID of the dataset.
     * @param _account The address to check for access.
     * @return True if access is granted, false otherwise.
     */
    function getDatasetAccessDetails(uint256 _datasetId, address _account) external view returns (bool) {
        Dataset storage ds = datasets[_datasetId];
        require(ds.id != 0, "Dataset not found");
        return ds.accessGranted[_account];
    }

    // --- III. AI Model Lifecycle & Validation ---

    /**
     * @dev A researcher proposes a new AI model for validation.
     *      The model's actual files are stored off-chain, referenced by hash.
     * @param _modelHash Hash of the AI model files (e.g., IPFS CID, git commit hash).
     * @param _name Name of the AI model.
     * @param _description Description of the AI model.
     * @param _expectedComputeCost Estimated off-chain computation cost for validation (informative).
     * @param _validationStakeAmount Required stake from validators to participate in validation.
     */
    function proposeAIModel(string calldata _modelHash, string calldata _name, string calldata _description, uint256 _expectedComputeCost, uint256 _validationStakeAmount) external onlyRegisteredEntity whenNotPaused {
        uint256 proposerEntityId = walletToEntityId[msg.sender];
        require(entities[proposerEntityId].role == EntityRole.Researcher, "Only researchers can propose AI models");
        require(bytes(_modelHash).length > 0, "Model hash cannot be empty");
        require(_validationStakeAmount > 0, "Validation stake amount must be greater than zero");

        uint256 modelId = nextModelId++;
        aiModels[modelId] = AIModel({
            id: modelId,
            proposerEntityId: proposerEntityId,
            modelHash: _modelHash,
            name: _name,
            description: _description,
            expectedComputeCost: _expectedComputeCost,
            validationStakeAmount: _validationStakeAmount,
            status: ModelStatus.Proposed,
            currentValidationId: 0,
            validatedAt: 0
        });
        emit AIModelProposed(modelId, proposerEntityId, _name, _validationStakeAmount);
    }

    /**
     * @dev A validator commits to a hashed result for a given AI model's validation.
     *      This is the first phase of the commit-reveal scheme.
     * @param _modelId The ID of the AI model being validated.
     * @param _commitHash The Keccak256 hash of the (true result hash + a random salt).
     */
    function submitValidationCommit(uint256 _modelId, bytes32 _commitHash) external payable onlyRegisteredEntity onlyValidator(walletToEntityId[msg.sender]) whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "AI Model not found");
        require(model.status == ModelStatus.Proposed || model.status == ModelStatus.Validating, "AI Model is not in a valid state for new commits");
        require(msg.value >= model.validationStakeAmount, "Insufficient stake provided for validation");

        uint256 validatorEntityId = walletToEntityId[msg.sender];
        uint256 validationId = nextValidationId++;
        validations[validationId] = Validation({
            id: validationId,
            modelId: _modelId,
            validatorEntityId: validatorEntityId,
            commitHash: _commitHash,
            revealedResultHash: bytes32(0),
            additionalProofCid: "",
            onChainProof: "",
            commitTimestamp: block.timestamp,
            revealTimestamp: 0,
            status: ValidationStatus.Committed,
            stakeAmount: msg.value,
            rewardAmount: 0,
            challengeId: 0
        });

        if (model.status == ModelStatus.Proposed) {
            model.status = ModelStatus.Validating;
        }
        model.currentValidationId = validationId;

        emit ValidationCommitSubmitted(validationId, _modelId, validatorEntityId, _commitHash);
    }

    /**
     * @dev A validator reveals their validation result, along with the original salt and a simulated ZK-proof.
     *      This is the second phase of the commit-reveal scheme.
     * @param _modelId The ID of the AI model.
     * @param _trueResultHash The actual cryptographic hash of the validation output.
     * @param _additionalProofCid IPFS CID pointing to any additional proof data (e.g., logs, full output).
     * @param _onChainProof Placeholder for a compact on-chain verifiable ZK-proof.
     */
    function revealValidationResult(uint256 _modelId, bytes32 _trueResultHash, string calldata _additionalProofCid, bytes calldata _onChainProof) external onlyRegisteredEntity onlyValidator(walletToEntityId[msg.sender]) whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "AI Model not found");
        require(model.status == ModelStatus.Validating, "AI Model is not currently under validation");

        Validation storage validation = validations[model.currentValidationId];
        require(validation.validatorEntityId == walletToEntityId[msg.sender], "Caller is not the active validator for this model");
        require(validation.status == ValidationStatus.Committed, "Validation is not in committed state");
        require(block.timestamp <= validation.commitTimestamp + validationCommitRevealPeriod, "Reveal period has ended");

        // Simulate ZK-proof verification here. In a real scenario, this would involve a complex precompile or custom verifier.
        // For this example, we'll just check if the proof is non-empty and assume validity.
        require(bytes(_onChainProof).length > 0, "On-chain proof is required for reveal");

        // Verify the commit hash (pseudo-verification, requires salt which is not on-chain here)
        // In a real system, the salt would be passed and checked: keccak256(abi.encodePacked(_trueResultHash, _salt)) == validation.commitHash
        // For simplicity, we assume the provided _trueResultHash matches the one committed.
        // A more robust implementation would require passing the salt as well.
        bytes32 expectedCommitHash = keccak256(abi.encodePacked(_trueResultHash, keccak256(abi.encodePacked(validation.commitTimestamp)))); // Example: using timestamp as a pseudo-salt for demo
        require(validation.commitHash == expectedCommitHash, "Revealed result does not match commit");


        validation.revealedResultHash = _trueResultHash;
        validation.additionalProofCid = _additionalProofCid;
        validation.onChainProof = _onChainProof;
        validation.revealTimestamp = block.timestamp;
        validation.status = ValidationStatus.Revealed;
        model.status = ModelStatus.Validated; // Model is considered validated after successful reveal

        // Reward calculation for successful validation (e.g., based on stake, model complexity)
        validation.rewardAmount = validation.stakeAmount * 10 / 100; // Example: 10% reward

        // Update validator's reputation in the AI domain
        uint256 aiDomainId = _getOrCreateDomainId("Artificial Intelligence");
        _updateReputation(validation.validatorEntityId, 50, aiDomainId); // Positive reputation for successful validation

        emit ValidationResultRevealed(validation.id, _modelId, _trueResultHash, _additionalProofCid);
    }

    /**
     * @dev Allows any registered entity to challenge a revealed validation result.
     *      Requires off-chain evidence referenced by the `_challengeReasonCid`.
     * @param _modelId The ID of the AI model.
     * @param _validationId The ID of the validation being challenged.
     * @param _challengeReasonCid IPFS CID pointing to detailed reasons and evidence for the challenge.
     */
    function challengeValidationResult(uint256 _modelId, uint256 _validationId, string calldata _challengeReasonCid) external onlyRegisteredEntity whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        Validation storage validation = validations[_validationId];

        require(model.id != 0 && validation.id != 0, "Model or Validation not found");
        require(model.currentValidationId == _validationId, "Validation is not the current active validation for this model");
        require(validation.status == ValidationStatus.Revealed, "Validation is not in a revealed state and cannot be challenged");
        require(validation.challengeId == 0, "Validation already challenged");
        require(walletToEntityId[msg.sender] != validation.validatorEntityId, "Validator cannot challenge their own validation");
        require(bytes(_challengeReasonCid).length > 0, "Challenge reason CID cannot be empty");

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            id: challengeId,
            validationId: _validationId,
            challengerEntityId: walletToEntityId[msg.sender],
            reasonCid: _challengeReasonCid,
            status: ChallengeStatus.Pending,
            resolutionTimestamp: 0,
            resolutionDetailsCid: "",
            challengerWins: false
        });

        validation.challengeId = challengeId;
        validation.status = ValidationStatus.Challenged;
        model.status = ModelStatus.Challenged;

        // Optionally, require a stake from the challenger here
        // msg.sender.transfer(challengeStake); // Example

        emit ChallengeSubmitted(challengeId, _validationId, walletToEntityId[msg.sender]);
    }

    /**
     * @dev Resolves a validation challenge. This function would typically be called by a trusted oracle,
     *      a decentralized committee, or through a sub-DAO governance vote after off-chain arbitration.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins True if the challenger wins, false if the original validator wins.
     * @param _resolutionDetailsCid IPFS CID for detailed resolution notes/evidence.
     */
    function resolveChallenge(uint256 _challengeId, bool _challengerWins, string calldata _resolutionDetailsCid) external onlyOwner whenNotPaused { // Simplified to onlyOwner for this example
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "Challenge not found");
        require(challenge.status == ChallengeStatus.Pending, "Challenge already resolved");
        require(bytes(_resolutionDetailsCid).length > 0, "Resolution details CID cannot be empty");

        Validation storage validation = validations[challenge.validationId];
        uint256 aiDomainId = _getOrCreateDomainId("Artificial Intelligence");

        challenge.challengerWins = _challengerWins;
        challenge.resolutionDetailsCid = _resolutionDetailsCid;
        challenge.resolutionTimestamp = block.timestamp;
        challenge.status = ChallengeStatus.Resolved;

        if (_challengerWins) {
            // Challenger wins: Validator loses stake, reputation reduced
            (bool success, ) = msg.sender.call{value: validation.stakeAmount}(""); // Return validator's stake to a treasury or challenger (simplified: to owner)
            require(success, "Failed to slash validator stake");
            _updateReputation(validation.validatorEntityId, -100, aiDomainId); // Negative reputation for failed validation
            _updateReputation(challenge.challengerEntityId, 75, aiDomainId); // Positive reputation for successful challenge
            validation.status = ValidationStatus.Resolved; // Mark validation as resolved (failed)
            aiModels[validation.modelId].status = ModelStatus.Rejected; // Model is rejected
        } else {
            // Validator wins: Challenger loses stake (if any), reputation reduced
            // Validator gets back stake + reward
            (bool success, ) = payable(entities[validation.validatorEntityId].walletAddress).transfer(validation.stakeAmount + validation.rewardAmount);
            require(success, "Failed to return validator funds");
            _updateReputation(validation.validatorEntityId, 25, aiDomainId); // Small boost for defending successfully
            _updateReputation(challenge.challengerEntityId, -50, aiDomainId); // Negative reputation for failed challenge
            validation.status = ValidationStatus.Revealed; // Revert to revealed state if validator wins
            aiModels[validation.modelId].status = ModelStatus.Validated; // Model remains validated
        }
        emit ChallengeResolved(_challengeId, _challengerWins, _resolutionDetailsCid);
    }

    // --- IV. Reputation & Incentives ---

    // Note: `_updateReputation` is an internal function defined above.

    /**
     * @dev Allows an entity to delegate a portion of their reputation (voting/validation power) to another entity.
     *      This impacts the delegatee's effective reputation.
     * @param _delegatorId The ID of the entity delegating reputation.
     * @param _delegateeId The ID of the entity receiving delegated reputation.
     * @param _amount The amount of reputation points to delegate.
     */
    function delegateReputation(uint256 _delegatorId, uint256 _delegateeId, uint256 _amount) external onlyRegisteredEntity whenNotPaused {
        require(walletToEntityId[msg.sender] == _delegatorId, "Caller does not own this delegator ID");
        require(_delegatorId != _delegateeId, "Cannot delegate reputation to self");
        require(entities[_delegatorId].id != 0 && entities[_delegateeId].id != 0, "Delegator or Delegatee not found");
        // Simplified: assuming a single "general" domain for delegation weight for now.
        // In a real system, you might delegate domain-specific reputation.
        require(uint256(getEntityReputation(_delegatorId, _getOrCreateDomainId("General"))) >= _amount, "Insufficient reputation to delegate");

        entities[_delegatorId].delegatedTo[_delegateeId] += _amount;
        entities[_delegateeId].delegatedBy[_delegatorId] += _amount;
        entities[_delegateeId].totalDelegatedReputation[_getOrCreateDomainId("General")] += _amount; // Update effective reputation

        emit ReputationDelegated(_delegatorId, _delegateeId, _amount);
    }

    /**
     * @dev Allows an entity to reclaim previously delegated reputation.
     * @param _delegatorId The ID of the entity undelegating reputation.
     * @param _delegateeId The ID of the entity from whom reputation is being undelegated.
     * @param _amount The amount of reputation points to undelegate.
     */
    function undelegateReputation(uint256 _delegatorId, uint256 _delegateeId, uint256 _amount) external onlyRegisteredEntity whenNotPaused {
        require(walletToEntityId[msg.sender] == _delegatorId, "Caller does not own this delegator ID");
        require(_delegatorId != _delegateeId, "Cannot undelegate reputation from self");
        require(entities[_delegatorId].id != 0 && entities[_delegateeId].id != 0, "Delegator or Delegatee not found");
        require(entities[_delegatorId].delegatedTo[_delegateeId] >= _amount, "Not enough reputation delegated to undelegate");

        entities[_delegatorId].delegatedTo[_delegateeId] -= _amount;
        entities[_delegateeId].delegatedBy[_delegatorId] -= _amount;
        entities[_delegateeId].totalDelegatedReputation[_getOrCreateDomainId("General")] -= _amount;

        emit ReputationUndelegated(_delegatorId, _delegateeId, _amount);
    }

    /**
     * @dev Allows a successful validator to claim their earned rewards and stake back.
     * @param _validationId The ID of the completed validation.
     */
    function claimValidationReward(uint256 _validationId) external onlyRegisteredEntity whenNotPaused {
        Validation storage validation = validations[_validationId];
        require(validation.id != 0, "Validation not found");
        require(validation.validatorEntityId == walletToEntityId[msg.sender], "Caller is not the validator for this validation");
        require(validation.status == ValidationStatus.Revealed || (validation.status == ValidationStatus.Resolved && !challenges[validation.challengeId].challengerWins), "Validation not successfully completed or already claimed");
        require(validation.stakeAmount > 0 || validation.rewardAmount > 0, "Nothing to claim");

        uint256 totalPayout = validation.stakeAmount + validation.rewardAmount;
        validation.stakeAmount = 0; // Prevent double claim
        validation.rewardAmount = 0; // Prevent double claim

        (bool success, ) = payable(msg.sender).transfer(totalPayout);
        require(success, "Failed to transfer reward and stake");

        // Mark validation as fully processed, preventing re-claims.
        validation.status = ValidationStatus.Resolved; // Use resolved to indicate final state

        emit ValidationRewardClaimed(_validationId, walletToEntityId[msg.sender], totalPayout);
    }


    // --- V. Decentralized Governance & Funding (DeSci DAO) ---

    /**
     * @dev Researchers can propose funding requests for scientific projects.
     *      Details for the project are stored off-chain and referenced by _projectDetailsCid.
     * @param _projectName The name of the proposed project.
     * @param _projectDetailsCid IPFS CID pointing to the full proposal details.
     * @param _requestedAmount The amount of native tokens requested from the treasury.
     */
    function proposeFundingRequest(string calldata _projectName, string calldata _projectDetailsCid, uint256 _requestedAmount) external onlyRegisteredEntity checkMinReputation(walletToEntityId[msg.sender], MIN_REP_FOR_PROPOSAL, _getOrCreateDomainId("General")) whenNotPaused {
        uint256 proposerEntityId = walletToEntityId[msg.sender];
        require(bytes(_projectName).length > 0 && bytes(_projectDetailsCid).length > 0, "Project name and details CID cannot be empty");
        require(_requestedAmount > 0, "Requested amount must be greater than zero");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposerEntityId: proposerEntityId,
            projectName: _projectName,
            projectDetailsCid: _projectDetailsCid,
            requestedAmount: _requestedAmount,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(uint256 => bool),
            status: ProposalStatus.Active
        });

        emit FundingProposalCreated(proposalId, proposerEntityId, _projectName, _requestedAmount);
    }

    /**
     * @dev Registered entities vote on active funding proposals.
     *      Vote weight is based on their effective reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyRegisteredEntity checkMinReputation(walletToEntityId[msg.sender], MIN_REP_FOR_VOTE, _getOrCreateDomainId("General")) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal not found");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active for voting");
        require(block.timestamp <= proposal.votingPeriodEnd, "Voting period has ended");
        require(!proposal.hasVoted[walletToEntityId[msg.sender]], "You have already voted on this proposal");

        uint256 voterEntityId = walletToEntityId[msg.sender];
        uint256 generalDomainId = _getOrCreateDomainId("General");
        uint256 voteWeight = uint256(getEntityReputation(voterEntityId, generalDomainId) + entities[voterEntityId].totalDelegatedReputation[generalDomainId]);
        require(voteWeight > 0, "You have no voting power");

        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[voterEntityId] = true;

        emit VotedOnProposal(_proposalId, voterEntityId, _support);
    }

    /**
     * @dev Executes a funding proposal if it has passed the voting period and met quorum requirements.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal not found");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp > proposal.votingPeriodEnd, "Voting period has not ended yet");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast for this proposal");

        // Simple quorum check: requires a minimum percentage of total votes for validity
        // In a real DAO, this would be against total possible voting power, not just cast votes.
        uint256 requiredForQuorum = (totalVotes * proposalQuorumPercentage) / 100;
        require(proposal.votesFor >= requiredForQuorum, "Quorum not met for 'for' votes");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass majority");

        require(address(this).balance >= proposal.requestedAmount, "Insufficient funds in treasury");

        (bool success, ) = payable(entities[proposal.proposerEntityId].walletAddress).transfer(proposal.requestedAmount);
        require(success, "Failed to transfer funds for proposal");

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows anyone to deposit native tokens into the VeritasAI treasury.
     */
    function depositToTreasury() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows DAO members (via a governance proposal) to adjust core parameters.
     *      This function would typically only be callable after a successful `executeProposal`
     *      of a specific type, not directly `onlyOwner` in a real DAO.
     *      For simplicity, `paramType` is an integer mapping to different parameters.
     * @param _paramType Identifier for the parameter to change (e.g., 1 for voting period, 2 for quorum).
     * @param _newValue The new value for the parameter.
     */
    function setGovernanceParameter(uint256 _paramType, uint256 _newValue) external onlyOwner whenNotPaused {
        // This function would usually be triggered by a successful governance proposal execution,
        // rather than directly by onlyOwner in a fully decentralized system.
        // For demonstration purposes, it's simplified.

        if (_paramType == 1) { // Example: Proposal Voting Period
            require(_newValue > 0, "Voting period must be greater than 0");
            proposalVotingPeriod = _newValue;
        } else if (_paramType == 2) { // Example: Proposal Quorum Percentage
            require(_newValue > 0 && _newValue <= 100, "Quorum percentage must be between 1 and 100");
            proposalQuorumPercentage = _newValue;
        } else if (_paramType == 3) { // Example: Validation Commit Reveal Period
            require(_newValue > 0, "Reveal period must be greater than 0");
            validationCommitRevealPeriod = _newValue;
        } else {
            revert("Invalid governance parameter type");
        }
        emit GovernanceParameterSet(_paramType, _newValue);
    }


    // --- VI. System Utilities & Security ---

    /**
     * @dev Pauses the contract in case of an emergency.
     *      Only the contract owner can call this.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     *      Only the contract owner can call this.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw any remaining ETH.
     *      In a real DAO, this would be part of a governance process or restricted to specific functions.
     */
    function withdrawFunds(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to withdraw funds");
    }
}
```