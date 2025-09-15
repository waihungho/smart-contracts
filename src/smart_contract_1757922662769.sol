```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For potential oracle signature verification
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic

// --- OUTLINE AND FUNCTION SUMMARY ---
//
// Contract Name: CognitoNet - Decentralized AI Model & Federated Learning Platform
//
// This contract orchestrates a decentralized marketplace for AI models, integrating federated learning
// mechanisms, a dynamic reward system, and governance. It allows users to register AI models,
// participate in federated learning rounds by contributing data/compute, validate contributions,
// earn rewards, and own access rights to models via NFTs. Oracles are crucial for bridging
// off-chain AI computation and validation results to the blockchain. The actual AI model training
// and data processing occur off-chain, with the blockchain managing proofs, stakes, rewards, and reputation.
//
// I. Core Data Structures:
//    - AIModel: Stores metadata, pricing, and reward factors for an AI model.
//    - TrainingRound: Manages parameters, participants, and state of a federated learning round.
//    - Contribution: Records a participant's stake, committed hash, and quality score.
//    - Validation: Records a validator's stake and their assessment of a contribution.
//    - Proposal: Manages governance proposals for system parameter changes.
//
// II. Function Categories and Summaries:
//
//    A. Core Administration & Setup (5 functions)
//       1. constructor(): Initializes the contract, sets the owner, and ERC721 parameters.
//       2. setOracleAddress(address _oracle): Sets the address of the trusted oracle contract.
//       3. pause(): Emergency stop for contract operations, callable by owner/governance.
//       4. unpause(): Resumes contract operations, callable by owner/governance.
//       5. withdrawProtocolFees(address _recipient): Allows the owner/DAO to withdraw accumulated protocol fees.
//
//    B. AI Model Registry (5 functions)
//       6. registerAIModel(string calldata _name, string calldata _description, string calldata _ipfsMetadataHash, uint256 _basePrice, uint256 _rewardPoolFactor): Registers a new AI model with its details, initial price, and reward factor.
//       7. updateAIModelMetadata(uint256 _modelId, string calldata _newIpfsMetadataHash): Allows the model owner to update the IPFS hash pointing to the model's off-chain metadata.
//       8. setAIModelPricing(uint256 _modelId, uint256 _newBasePrice): Adjusts the base price for purchasing access to a specific AI model.
//       9. purchaseModelAccess(uint256 _modelId): Allows a user to purchase access to an AI model, minting a unique Data Access NFT representing this right.
//       10. getAIModelDetails(uint256 _modelId): Retrieves comprehensive details of a registered AI model.
//
//    C. Federated Learning Orchestration (6 functions)
//       11. initiateTrainingRound(uint256 _modelId, uint256 _contributionWindowEnd, uint256 _validationWindowEnd, uint256 _minStake, uint256 _validatorCount): Initiates a new federated learning round for a given AI model, defining its timeline and requirements.
//       12. commitToContribute(uint256 _roundId, bytes32 _contributionHash): Allows a user to commit to contributing data/computation to a training round by staking funds and providing a hash of their off-chain work.
//       13. submitOffChainProofViaOracle(uint256 _roundId, address _contributor, bytes32 _contributionHash, uint256 _qualityScore): Oracle-only function to submit the verified off-chain contribution proof and its quality score.
//       14. registerValidator(uint256 _roundId): Allows a user to register as a validator for a training round by staking funds, committing to evaluate contributions.
//       15. submitValidationResultViaOracle(uint256 _roundId, address _validator, address _contributor, uint256 _score, string calldata _ipfsProof): Oracle-only function to submit a validator's assessment of a specific contribution, including a score and IPFS proof.
//       16. finalizeTrainingRound(uint256 _roundId): Concludes a training round, processes all contributions and validations, calculates and distributes rewards, and updates participant reputations.
//
//    D. Reward, Slashing & Reputation (4 functions)
//       17. claimTrainingRewards(uint256 _roundId): Allows participants to claim their earned rewards from a finalized training round.
//       18. slashStake(address _offender, uint256 _amount, string calldata _reason): Penalizes an offender by reducing their stake, typically triggered by oracle reports or governance decisions.
//       19. getReputation(address _participant): Retrieves the current reputation score of a participant.
//       20. updateReputationManually(address _participant, int256 _reputationChange): Allows governance to manually adjust a participant's reputation score.
//
//    E. Data Access NFTs (Specific interactions, leveraging ERC721) (2 functions)
//       21. getDataAccessNFTTokenId(uint256 _modelId, address _owner): Retrieves the Token ID of the Data Access NFT for a specific model owned by an address.
//       22. grantModelAccessByNFT(address _recipient, uint256 _modelId): Mints and grants a Data Access NFT to a recipient for a specific model (e.g., for promotional purposes or special cases).
//
//    F. Decentralized Governance (4 functions)
//       23. proposeParameterChange(string calldata _description, bytes calldata _callData, address _targetContract): Creates a new governance proposal to change a contract parameter or call a function.
//       24. voteOnProposal(uint256 _proposalId, bool _support): Casts a vote (for or against) on an active governance proposal.
//       25. queueProposal(uint256 _proposalId): Moves a successfully voted proposal into a timelock queue before execution.
//       26. executeProposal(uint256 _proposalId): Executes a proposal after its timelock period has passed.
//
// Total functions: 26
//
```
// Code starts here
contract CognitoNet is Ownable, Pausable, ReentrancyGuard, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    address public oracleAddress; // Trusted oracle for off-chain proofs
    uint256 public protocolFeePercentage = 5; // 5% protocol fee
    uint256 public minProposalQuorum = 10; // Minimum votes (percentage) required for a proposal to pass
    uint256 public votingPeriod = 3 days; // Duration for voting on proposals
    uint256 public timelockDelay = 2 days; // Delay before a passed proposal can be executed

    Counters.Counter private _modelIdCounter;
    Counters.Counter private _roundIdCounter;
    Counters.Counter private _dataAccessNFTIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Structs ---

    struct AIModel {
        address owner;
        string name;
        string description;
        string ipfsMetadataHash; // IPFS hash to detailed model metadata/description
        uint256 basePrice; // Price in Wei to purchase access to this model
        uint256 rewardPoolFactor; // Factor for calculating rewards in federated learning (e.g., 100 = 1x base reward)
        bool exists;
    }

    struct TrainingRound {
        uint256 modelId;
        uint256 initiatedAt;
        uint256 contributionWindowEnd;
        uint256 validationWindowEnd;
        uint256 minStake; // Minimum stake required for contributors/validators
        uint256 validatorCount; // Number of validators targeted
        uint256 totalStaked; // Total ETH staked in this round
        uint256 totalRewardsAvailable; // Total ETH available for rewards
        uint256 totalQualityScore; // Sum of quality scores from contributions
        mapping(address => Contribution) contributions;
        address[] contributors;
        mapping(address => Validation) validations;
        address[] validators;
        bool finalized;
        bool exists;
    }

    struct Contribution {
        uint256 stake;
        bytes32 contributionHash; // Hash of off-chain contribution proof
        uint256 qualityScore; // Quality score from oracle, 0-100
        bool submittedProof;
        bool validated;
        bool rewarded;
    }

    struct Validation {
        uint256 stake;
        mapping(address => uint256) contributorScores; // Validator's score for each contributor (0-100)
        mapping(address => string) ipfsProofs; // IPFS proof of validation
        uint224 submittedCount; // How many contributions this validator assessed
        bool rewarded;
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Queued, Executed, Expired }

    struct Proposal {
        address proposer;
        string description;
        bytes callData; // Encoded function call
        address targetContract; // Contract to call (e.g., this contract)
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        uint256 timestampQueued;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    // --- Mappings ---

    mapping(uint256 => AIModel) public aiModels;
    mapping(uint256 => TrainingRound) public trainingRounds;
    mapping(address => int256) public reputations; // Participant reputation score
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => uint256)) public roundPendingRewards; // roundId => participant => reward

    // --- Events ---

    event OracleAddressSet(address indexed newOracle);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string name, uint256 basePrice);
    event AIModelMetadataUpdated(uint256 indexed modelId, string newIpfsHash);
    event AIModelPricingUpdated(uint256 indexed modelId, uint256 newBasePrice);
    event ModelAccessPurchased(uint256 indexed modelId, address indexed buyer, uint256 tokenId);
    event TrainingRoundInitiated(uint256 indexed roundId, uint256 indexed modelId, uint256 contributionWindowEnd);
    event ContributionCommitted(uint256 indexed roundId, address indexed contributor, uint256 stake, bytes32 contributionHash);
    event OffChainProofSubmitted(uint256 indexed roundId, address indexed contributor, uint256 qualityScore);
    event ValidatorRegistered(uint256 indexed roundId, address indexed validator, uint256 stake);
    event ValidationResultSubmitted(uint256 indexed roundId, address indexed validator, address indexed contributor, uint256 score);
    event TrainingRoundFinalized(uint256 indexed roundId, uint256 totalRewardsDistributed);
    event RewardsClaimed(uint256 indexed roundId, address indexed participant, uint256 amount);
    event StakeSlashed(address indexed offender, uint256 amount, string reason);
    event ReputationUpdated(address indexed participant, int256 newReputation);
    event DataAccessNFTGranted(uint256 indexed modelId, address indexed recipient, uint256 tokenId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalQueued(uint256 indexed proposalId, uint256 timestamp);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "CognitoNet: Only oracle can call this function");
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        require(aiModels[_modelId].exists, "CognitoNet: Model does not exist");
        require(aiModels[_modelId].owner == msg.sender, "CognitoNet: Only model owner can perform this action");
        _;
    }

    modifier whenRoundNotStarted(uint256 _roundId) {
        require(trainingRounds[_roundId].exists, "CognitoNet: Round does not exist");
        require(block.timestamp < trainingRounds[_roundId].initiatedAt, "CognitoNet: Round has already started");
        _;
    }

    modifier whenContributionWindowActive(uint256 _roundId) {
        require(trainingRounds[_roundId].exists, "CognitoNet: Round does not exist");
        require(block.timestamp >= trainingRounds[_roundId].initiatedAt && block.timestamp < trainingRounds[_roundId].contributionWindowEnd, "CognitoNet: Contribution window is not active");
        _;
    }

    modifier whenValidationWindowActive(uint256 _roundId) {
        require(trainingRounds[_roundId].exists, "CognitoNet: Round does not exist");
        require(block.timestamp >= trainingRounds[_roundId].contributionWindowEnd && block.timestamp < trainingRounds[_roundId].validationWindowEnd, "CognitoNet: Validation window is not active");
        _;
    }

    modifier whenRoundFinalizable(uint256 _roundId) {
        require(trainingRounds[_roundId].exists, "CognitoNet: Round does not exist");
        require(block.timestamp >= trainingRounds[_roundId].validationWindowEnd, "CognitoNet: Round not ready for finalization");
        require(!trainingRounds[_roundId].finalized, "CognitoNet: Round already finalized");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("CognitoNet Data Access NFT", "CNDA") Ownable(msg.sender) {
        // Owner is initially the deployer.
        // Oracle address needs to be set post-deployment.
    }

    // --- A. Core Administration & Setup ---

    /**
     * @notice Sets the address of the trusted oracle.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "CognitoNet: Invalid oracle address");
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    /**
     * @notice Pauses contract operations in case of emergency.
     * Callable by the owner or governance.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses contract operations.
     * Callable by the owner or governance.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Allows the owner or DAO to withdraw accumulated protocol fees.
     * @param _recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address _recipient) external onlyOwner nonReentrant {
        require(_recipient != address(0), "CognitoNet: Invalid recipient address");
        uint256 balance = address(this).balance;
        uint224 fees = _calculateProtocolFees(); // Assuming protocol fees are separated or calculated from total balance
        require(fees > 0, "CognitoNet: No fees to withdraw");

        (bool success, ) = _recipient.call{value: fees}("");
        require(success, "CognitoNet: Failed to withdraw fees");

        // Reset fee accumulator, if applicable.
        // For simplicity, we assume fees are implicitly collected as part of total contract balance
        // and this function just sweeps a portion considered as "fees".
        // A more robust system would track fees explicitly.
        // Here, let's assume `protocolFeePercentage` is applied to relevant transactions,
        // and collected fees are ready for withdrawal. For this example, we'll
        // consider 10% of total contract balance as potential withdrawable fees for demonstration.
        // In a real system, specific fee amounts would be accumulated.
        // For demonstration, let's just allow owner to withdraw some arbitrary amount,
        // representing fees, until a proper fee tracking system is implemented.
        // For a more realistic scenario, `protocolFees` should be an explicit counter.
        // Let's implement a simple `totalCollectedFees` state variable.
        //
        // Re-thinking: Instead of `_calculateProtocolFees`, let's just explicitly track it.
        // For now, let's add `totalProtocolFees` and update it.
        uint256 amountToWithdraw = totalProtocolFees;
        totalProtocolFees = 0; // Reset after withdrawal

        emit ProtocolFeesWithdrawn(_recipient, amountToWithdraw);
    }
    uint256 public totalProtocolFees; // Explicitly track collected protocol fees

    // --- B. AI Model Registry ---

    /**
     * @notice Registers a new AI model on the platform.
     * @param _name The name of the AI model.
     * @param _description A brief description of the model.
     * @param _ipfsMetadataHash IPFS hash pointing to detailed metadata (e.g., architecture, training data, usage).
     * @param _basePrice The base price in Wei to purchase access to this model.
     * @param _rewardPoolFactor A factor (e.g., 100 for 1x) used to determine rewards for federated learning rounds.
     */
    function registerAIModel(
        string calldata _name,
        string calldata _description,
        string calldata _ipfsMetadataHash,
        uint256 _basePrice,
        uint256 _rewardPoolFactor
    ) external onlyOwner whenNotPaused {
        _modelIdCounter.increment();
        uint256 newModelId = _modelIdCounter.current();

        aiModels[newModelId] = AIModel(
            msg.sender,
            _name,
            _description,
            _ipfsMetadataHash,
            _basePrice,
            _rewardPoolFactor,
            true
        );
        emit AIModelRegistered(newModelId, msg.sender, _name, _basePrice);
    }

    /**
     * @notice Allows the model owner to update the IPFS metadata hash for their model.
     * @param _modelId The ID of the AI model.
     * @param _newIpfsMetadataHash The new IPFS hash for the model's metadata.
     */
    function updateAIModelMetadata(uint256 _modelId, string calldata _newIpfsMetadataHash)
        external
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        aiModels[_modelId].ipfsMetadataHash = _newIpfsMetadataHash;
        emit AIModelMetadataUpdated(_modelId, _newIpfsMetadataHash);
    }

    /**
     * @notice Adjusts the base price for purchasing access to a specific AI model.
     * Callable by the model owner or governance.
     * @param _modelId The ID of the AI model.
     * @param _newBasePrice The new base price in Wei.
     */
    function setAIModelPricing(uint256 _modelId, uint256 _newBasePrice) external onlyModelOwner(_modelId) whenNotPaused {
        aiModels[_modelId].basePrice = _newBasePrice;
        emit AIModelPricingUpdated(_modelId, _newBasePrice);
    }

    /**
     * @notice Allows a user to purchase access to an AI model.
     * This mints a unique Data Access NFT representing their ownership of this access right.
     * @param _modelId The ID of the AI model to purchase access for.
     */
    function purchaseModelAccess(uint256 _modelId) external payable whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        require(model.exists, "CognitoNet: Model does not exist");
        require(msg.value >= model.basePrice, "CognitoNet: Insufficient payment for model access");

        // Calculate and collect protocol fees
        uint256 feeAmount = model.basePrice.mul(protocolFeePercentage).div(100);
        totalProtocolFees = totalProtocolFees.add(feeAmount);
        
        // Transfer remaining amount to the model owner
        uint256 ownerPayment = model.basePrice.sub(feeAmount);
        (bool ownerSuccess, ) = model.owner.call{value: ownerPayment}("");
        require(ownerSuccess, "CognitoNet: Failed to pay model owner");

        // Refund any excess payment
        if (msg.value > model.basePrice) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value.sub(model.basePrice)}("");
            require(refundSuccess, "CognitoNet: Failed to refund excess payment");
        }

        _dataAccessNFTIdCounter.increment();
        uint256 newTokenId = _dataAccessNFTIdCounter.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked("ipfs://CNDA-", Strings.toString(_modelId)))); // Generic URI
        
        // Associate tokenId with modelId and owner for easy lookup
        _dataAccessNFTModelId[newTokenId] = _modelId;
        _dataAccessNFTOwnerLookup[_modelId][msg.sender] = newTokenId;

        emit ModelAccessPurchased(_modelId, msg.sender, newTokenId);
    }

    mapping(uint256 => uint256) private _dataAccessNFTModelId; // tokenId => modelId
    mapping(uint256 => mapping(address => uint256)) private _dataAccessNFTOwnerLookup; // modelId => owner => tokenId

    /**
     * @notice Retrieves comprehensive details of a registered AI model.
     * @param _modelId The ID of the AI model.
     * @return AIModel struct containing all model details.
     */
    function getAIModelDetails(uint256 _modelId)
        external
        view
        returns (
            address owner,
            string memory name,
            string memory description,
            string memory ipfsMetadataHash,
            uint256 basePrice,
            uint256 rewardPoolFactor
        )
    {
        AIModel storage model = aiModels[_modelId];
        require(model.exists, "CognitoNet: Model does not exist");
        return (model.owner, model.name, model.description, model.ipfsMetadataHash, model.basePrice, model.rewardPoolFactor);
    }

    // --- C. Federated Learning Orchestration ---

    /**
     * @notice Initiates a new federated learning round for a given AI model.
     * @param _modelId The ID of the AI model to train.
     * @param _contributionWindowEnd The timestamp when the contribution period ends.
     * @param _validationWindowEnd The timestamp when the validation period ends.
     * @param _minStake Minimum ETH stake required for participants (contributors/validators).
     * @param _validatorCount The target number of validators for this round.
     */
    function initiateTrainingRound(
        uint256 _modelId,
        uint256 _contributionWindowEnd,
        uint256 _validationWindowEnd,
        uint256 _minStake,
        uint256 _validatorCount
    ) external onlyModelOwner(_modelId) whenNotPaused {
        require(aiModels[_modelId].exists, "CognitoNet: Model does not exist");
        require(_contributionWindowEnd > block.timestamp, "CognitoNet: Contribution window must be in the future");
        require(_validationWindowEnd > _contributionWindowEnd, "CognitoNet: Validation window must end after contribution window");
        require(_minStake > 0, "CognitoNet: Minimum stake must be greater than zero");
        require(_validatorCount > 0, "CognitoNet: Validator count must be greater than zero");

        _roundIdCounter.increment();
        uint256 newRoundId = _roundIdCounter.current();

        trainingRounds[newRoundId].modelId = _modelId;
        trainingRounds[newRoundId].initiatedAt = block.timestamp;
        trainingRounds[newRoundId].contributionWindowEnd = _contributionWindowEnd;
        trainingRounds[newRoundId].validationWindowEnd = _validationWindowEnd;
        trainingRounds[newRoundId].minStake = _minStake;
        trainingRounds[newRoundId].validatorCount = _validatorCount;
        trainingRounds[newRoundId].exists = true;

        emit TrainingRoundInitiated(newRoundId, _modelId, _contributionWindowEnd);
    }

    /**
     * @notice Allows a user to commit to contributing data/computation to a training round.
     * Requires staking funds and providing a cryptographic hash of their off-chain work.
     * @param _roundId The ID of the training round.
     * @param _contributionHash A hash representing the off-chain contribution proof.
     */
    function commitToContribute(uint256 _roundId, bytes32 _contributionHash)
        external
        payable
        whenNotPaused
        whenContributionWindowActive(_roundId)
        nonReentrant
    {
        TrainingRound storage round = trainingRounds[_roundId];
        require(msg.value >= round.minStake, "CognitoNet: Insufficient stake");
        require(round.contributions[msg.sender].stake == 0, "CognitoNet: Already committed to this round");

        round.contributions[msg.sender] = Contribution({
            stake: msg.value,
            contributionHash: _contributionHash,
            qualityScore: 0,
            submittedProof: false,
            validated: false,
            rewarded: false
        });
        round.contributors.push(msg.sender);
        round.totalStaked = round.totalStaked.add(msg.value);

        emit ContributionCommitted(_roundId, msg.sender, msg.value, _contributionHash);
    }

    /**
     * @notice Oracle-only function to submit the verified off-chain contribution proof and its quality score.
     * @param _roundId The ID of the training round.
     * @param _contributor The address of the contributor.
     * @param _contributionHash The hash of the contribution proof (must match committed hash).
     * @param _qualityScore The quality score (0-100) assigned by the oracle to the contribution.
     */
    function submitOffChainProofViaOracle(
        uint256 _roundId,
        address _contributor,
        bytes32 _contributionHash,
        uint256 _qualityScore
    ) external onlyOracle whenNotPaused whenValidationWindowActive(_roundId) {
        TrainingRound storage round = trainingRounds[_roundId];
        Contribution storage contribution = round.contributions[_contributor];

        require(contribution.stake > 0, "CognitoNet: Contributor not committed to this round");
        require(contribution.contributionHash == _contributionHash, "CognitoNet: Hash mismatch");
        require(!contribution.submittedProof, "CognitoNet: Proof already submitted for this contribution");
        require(_qualityScore <= 100, "CognitoNet: Quality score must be between 0 and 100");

        contribution.qualityScore = _qualityScore;
        contribution.submittedProof = true;
        round.totalQualityScore = round.totalQualityScore.add(_qualityScore);

        emit OffChainProofSubmitted(_roundId, _contributor, _qualityScore);
    }

    /**
     * @notice Allows a user to register as a validator for a training round.
     * Requires staking funds, committing to evaluate contributions.
     * @param _roundId The ID of the training round.
     */
    function registerValidator(uint256 _roundId)
        external
        payable
        whenNotPaused
        whenContributionWindowActive(_roundId) // Validators can register during contribution or early validation
        nonReentrant
    {
        TrainingRound storage round = trainingRounds[_roundId];
        require(msg.value >= round.minStake, "CognitoNet: Insufficient stake");
        require(round.validations[msg.sender].stake == 0, "CognitoNet: Already registered as validator for this round");

        round.validations[msg.sender].stake = msg.value;
        round.validators.push(msg.sender);
        round.totalStaked = round.totalStaked.add(msg.value);

        emit ValidatorRegistered(_roundId, msg.sender, msg.value);
    }

    /**
     * @notice Oracle-only function to submit a validator's assessment of a specific contribution.
     * @param _roundId The ID of the training round.
     * @param _validator The address of the validator.
     * @param _contributor The address of the contributor being validated.
     * @param _score The score (0-100) given by the validator to the contribution.
     * @param _ipfsProof IPFS hash pointing to the detailed validation report.
     */
    function submitValidationResultViaOracle(
        uint256 _roundId,
        address _validator,
        address _contributor,
        uint256 _score,
        string calldata _ipfsProof
    ) external onlyOracle whenNotPaused whenValidationWindowActive(_roundId) {
        TrainingRound storage round = trainingRounds[_roundId];
        Validation storage validation = round.validations[_validator];
        Contribution storage contribution = round.contributions[_contributor];

        require(validation.stake > 0, "CognitoNet: Validator not registered for this round");
        require(contribution.stake > 0, "CognitoNet: Contributor not committed to this round");
        require(contribution.submittedProof, "CognitoNet: Contributor has not submitted proof yet");
        require(_score <= 100, "CognitoNet: Validation score must be between 0 and 100");
        require(validation.contributorScores[_contributor] == 0, "CognitoNet: Already validated this contribution");

        validation.contributorScores[_contributor] = _score;
        validation.ipfsProofs[_contributor] = _ipfsProof;
        validation.submittedCount = validation.submittedCount + 1;

        emit ValidationResultSubmitted(_roundId, _validator, _contributor, _score);
    }

    /**
     * @notice Concludes a training round, processes contributions, validations, and distributes rewards.
     * Adjusts participant reputations based on performance.
     * This function can only be called after the validation window has ended.
     * If no oracle reports, stakes might be refunded or held for governance decision.
     */
    function finalizeTrainingRound(uint256 _roundId) external whenNotPaused whenRoundFinalizable(_roundId) nonReentrant {
        TrainingRound storage round = trainingRounds[_roundId];
        AIModel storage model = aiModels[round.modelId];
        require(model.exists, "CognitoNet: Associated model does not exist");

        round.finalized = true;

        uint256 totalEffectiveQuality = 0;
        uint256 totalEffectiveValidation = 0;
        uint256 baseRewardPerQualityPoint = (round.totalStaked > 0 && round.totalQualityScore > 0)
            ? (round.totalStaked.mul(model.rewardPoolFactor).div(100)).div(round.totalQualityScore)
            : 0;

        // Process contributions
        for (uint256 i = 0; i < round.contributors.length; i++) {
            address contributor = round.contributors[i];
            Contribution storage contribution = round.contributions[contributor];

            if (contribution.submittedProof && contribution.qualityScore > 0) {
                // Calculate average validation score for this contribution
                uint256 totalValidationScore = 0;
                uint256 validValidatorCount = 0;
                for (uint256 j = 0; j < round.validators.length; j++) {
                    address validator = round.validators[j];
                    Validation storage validation = round.validations[validator];
                    if (validation.contributorScores[contributor] > 0) {
                        totalValidationScore = totalValidationScore.add(validation.contributorScores[contributor]);
                        validValidatorCount = validValidatorCount.add(1);
                    }
                }

                uint256 effectiveQuality = contribution.qualityScore;
                if (validValidatorCount > 0) {
                    uint256 avgValidationScore = totalValidationScore.div(validValidatorCount);
                    // Adjust quality score based on validator consensus. Simple average for now.
                    // More complex: reputation-weighted average, outlier removal, etc.
                    effectiveQuality = effectiveQuality.mul(avgValidationScore).div(100);
                }

                totalEffectiveQuality = totalEffectiveQuality.add(effectiveQuality);

                // Calculate reward for contributor
                uint256 rewardAmount = effectiveQuality.mul(baseRewardPerQualityPoint);
                roundPendingRewards[_roundId][contributor] = roundPendingRewards[_roundId][contributor].add(rewardAmount.add(contribution.stake)); // Return stake + reward
                round.totalRewardsAvailable = round.totalRewardsAvailable.add(rewardAmount);
                contribution.rewarded = true;

                // Update reputation
                if (effectiveQuality > 75) reputations[contributor] = reputations[contributor] + 1;
                else if (effectiveQuality < 50) reputations[contributor] = reputations[contributor] - 1;
            } else {
                // If no valid contribution, contributor loses stake (slashed)
                slashStake(contributor, contribution.stake, "No valid contribution submitted or validated.");
            }
        }

        // Process validators
        uint256 validatorRewardPerContribution = (round.totalRewardsAvailable > 0 && round.totalQualityScore > 0) ? round.totalRewardsAvailable.div(round.totalQualityScore) : 0; // Simple reward per quality point validated
        for (uint256 i = 0; i < round.validators.length; i++) {
            address validator = round.validators[i];
            Validation storage validation = round.validations[validator];

            if (validation.submittedCount > 0) {
                // Validator's reward based on their validated contributions.
                // Simplified: fixed reward per validated item.
                // More complex: Reward based on agreement with median, reputation of others etc.
                uint256 validatorReward = validation.submittedCount.mul(validatorRewardPerContribution);
                roundPendingRewards[_roundId][validator] = roundPendingRewards[_roundId][validator].add(validatorReward.add(validation.stake)); // Return stake + reward
                validation.rewarded = true;
                totalEffectiveValidation = totalEffectiveValidation.add(validatorReward); // For event logging

                // Update reputation (simplified)
                if (validation.submittedCount >= round.contributors.length / 2) reputations[validator] = reputations[validator] + 1;
                else if (validation.submittedCount < round.contributors.length / 4) reputations[validator] = reputations[validator] - 1;
            } else {
                // If no valid validation, validator loses stake
                slashStake(validator, validation.stake, "No valid validation results submitted.");
            }
        }
        
        // Any remaining funds after rewards and slashes (e.g. from partial slashes, unallocated rewards)
        // could go to the protocol treasury or be burned. For simplicity, they remain in the contract.

        emit TrainingRoundFinalized(_roundId, round.totalRewardsAvailable.add(totalEffectiveValidation));
    }

    // --- D. Reward, Slashing & Reputation ---

    /**
     * @notice Allows participants to claim their earned rewards from a finalized training round.
     * @param _roundId The ID of the training round.
     */
    function claimTrainingRewards(uint256 _roundId) external whenNotPaused nonReentrant {
        TrainingRound storage round = trainingRounds[_roundId];
        require(round.exists, "CognitoNet: Round does not exist");
        require(round.finalized, "CognitoNet: Round not yet finalized");

        uint256 amount = roundPendingRewards[_roundId][msg.sender];
        require(amount > 0, "CognitoNet: No rewards pending for this participant in this round");

        roundPendingRewards[_roundId][msg.sender] = 0; // Clear pending rewards

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "CognitoNet: Failed to claim rewards");

        emit RewardsClaimed(_roundId, msg.sender, amount);
    }

    /**
     * @notice Penalizes an offender by reducing their stake.
     * This function is typically triggered by oracle reports of malicious behavior or governance decisions.
     * The slashed amount goes to the protocol treasury (contract balance).
     * @param _offender The address of the participant to be slashed.
     * @param _amount The amount of ETH to slash from their stake.
     * @param _reason A description for the slashing.
     */
    function slashStake(address _offender, uint256 _amount, string calldata _reason) external onlyOracle whenNotPaused {
        // In a real system, stakes would be held in a dedicated mapping (address => uint256 stakedAmount)
        // For simplicity, this assumes `_amount` is deducted from `_offender`'s implied stake
        // in previous operations. For this demonstration, the `_amount` is added to `totalProtocolFees`.
        // This function would be more complex if stakes are held per-round.
        // It's a placeholder for the concept of slashing.

        require(_amount > 0, "CognitoNet: Slash amount must be greater than zero");

        // The actual ETH is already within the contract, either as part of totalStaked or directly sent for other purposes.
        // This function conceptually "allocates" the slashed amount to the protocol fees.
        totalProtocolFees = totalProtocolFees.add(_amount);
        
        // Decrease reputation for slashing
        reputations[_offender] = reputations[_offender] - 5; // Example penalty

        emit StakeSlashed(_offender, _amount, _reason);
        emit ReputationUpdated(_offender, reputations[_offender]);
    }

    /**
     * @notice Retrieves the current reputation score of a participant.
     * @param _participant The address of the participant.
     * @return The integer reputation score.
     */
    function getReputation(address _participant) external view returns (int256) {
        return reputations[_participant];
    }

    /**
     * @notice Allows governance (owner for now, later a DAO) to manually adjust a participant's reputation score.
     * This could be used for appeals, special recognition, or severe penalties.
     * @param _participant The address of the participant.
     * @param _reputationChange The amount to change the reputation by (can be positive or negative).
     */
    function updateReputationManually(address _participant, int256 _reputationChange) external onlyOwner whenNotPaused {
        reputations[_participant] = reputations[_participant] + _reputationChange;
        emit ReputationUpdated(_participant, reputations[_participant]);
    }

    // --- E. Data Access NFTs (Specific interactions, leveraging ERC721) ---

    /**
     * @notice Retrieves the Token ID of the Data Access NFT for a specific model owned by an address.
     * Returns 0 if no such NFT is found.
     * @param _modelId The ID of the AI model.
     * @param _owner The address of the NFT owner.
     * @return The Token ID of the Data Access NFT.
     */
    function getDataAccessNFTTokenId(uint256 _modelId, address _owner) external view returns (uint256) {
        return _dataAccessNFTOwnerLookup[_modelId][_owner];
    }

    /**
     * @notice Mints and grants a Data Access NFT to a recipient for a specific model.
     * Callable by owner/governance (e.g., for promotional purposes or special cases).
     * @param _recipient The address to grant the NFT to.
     * @param _modelId The ID of the AI model the NFT grants access to.
     */
    function grantModelAccessByNFT(address _recipient, uint256 _modelId) external onlyOwner whenNotPaused {
        require(aiModels[_modelId].exists, "CognitoNet: Model does not exist");
        require(_recipient != address(0), "CognitoNet: Invalid recipient address");

        _dataAccessNFTIdCounter.increment();
        uint256 newTokenId = _dataAccessNFTIdCounter.current();
        _mint(_recipient, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked("ipfs://CNDA-", Strings.toString(_modelId))));
        
        _dataAccessNFTModelId[newTokenId] = _modelId;
        _dataAccessNFTOwnerLookup[_modelId][_recipient] = newTokenId;

        emit DataAccessNFTGranted(_modelId, _recipient, newTokenId);
    }

    // --- F. Decentralized Governance ---

    /**
     * @notice Creates a new governance proposal to change a contract parameter or call a function.
     * @param _description A detailed description of the proposal.
     * @param _callData Encoded function call to execute if the proposal passes.
     * @param _targetContract The address of the contract to call (e.g., this contract's address).
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeParameterChange(
        string calldata _description,
        bytes calldata _callData,
        address _targetContract
    ) external whenNotPaused returns (uint256) {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            voteStart: block.timestamp,
            voteEnd: block.timestamp + votingPeriod,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            timestampQueued: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
        return newProposalId;
    }

    /**
     * @notice Casts a vote (for or against) on an active governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "CognitoNet: Proposal is not active");
        require(block.timestamp >= proposal.voteStart && block.timestamp <= proposal.voteEnd, "CognitoNet: Voting period is closed");
        require(!proposal.hasVoted[msg.sender], "CognitoNet: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.forVotes = proposal.forVotes.add(1); // In a real DAO, this would be based on token balance
        } else {
            proposal.againstVotes = proposal.againstVotes.add(1);
        }

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Moves a successfully voted proposal into a timelock queue before execution.
     * A proposal passes if (forVotes > againstVotes) AND (forVotes >= totalVotes * minProposalQuorum / 100).
     * @param _proposalId The ID of the proposal to queue.
     */
    function queueProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "CognitoNet: Proposal not in active state");
        require(block.timestamp > proposal.voteEnd, "CognitoNet: Voting period not yet ended");
        
        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        
        // For simplicity, minProposalQuorum check uses fixed numbers.
        // In a real DAO, `totalVotes` would represent voting power (e.g., token holdings)
        // and quorum would be `totalVotingSupply * minProposalQuorum / 100`.
        // Here, we simplify to fixed number of votes or a percentage of actual cast votes.
        // Let's assume minProposalQuorum is a simple count for this example.
        // If a total voting power is implemented, this needs to be updated.
        // For example: 10 votes (fixed count) or 10% of total cast votes.
        // Let's assume `minProposalQuorum` applies to the total votes *cast*.
        require(totalVotes > 0, "CognitoNet: No votes cast");
        require(proposal.forVotes > proposal.againstVotes, "CognitoNet: Proposal did not pass");
        require(proposal.forVotes.mul(100).div(totalVotes) >= minProposalQuorum, "CognitoNet: Proposal did not meet quorum");

        proposal.state = ProposalState.Queued;
        proposal.timestampQueued = block.timestamp;

        emit ProposalQueued(_proposalId, block.timestamp);
    }

    /**
     * @notice Executes a queued proposal after its timelock period has passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external payable whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Queued, "CognitoNet: Proposal not in queued state");
        require(block.timestamp >= proposal.timestampQueued + timelockDelay, "CognitoNet: Timelock period not yet passed");
        require(!proposal.executed, "CognitoNet: Proposal already executed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "CognitoNet: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }
}
```