I'm excited to present "AetherForge," a smart contract designed to be a decentralized marketplace and orchestration layer for AI model inference. This concept blends several advanced and trendy blockchain functionalities: **NFTs for AI models**, **Staking for inferencers and validators**, a **Reputation System**, an **Escrow-based payment system**, and a **Challenge/Dispute mechanism** to ensure result integrity.

It aims to facilitate the discovery, access, and payment for AI models, while providing on-chain mechanisms to incentivize honest behavior from service providers (inferencers) and verifiers (validators), even though the actual AI computation happens off-chain.

---

## Contract Name: `AetherForge`

### Outline and Function Summary:

AetherForge is a decentralized marketplace and orchestration layer for AI model inference. It allows AI model creators to register and tokenize their models as NFTs, inferencers to stake collateral and provide inference services, and requestors to pay for and receive inference results. A decentralized validator network ensures the integrity of results, and a reputation system incentivizes honest participation. The contract integrates advanced concepts like NFT-based model ownership, staking, a challenge/dispute mechanism, and a reputation scoring system.

#### I. Core Setup & Governance (5 functions)
1.  **`constructor(address initialDAOAddress_)`**: Initializes the contract, setting the deployer as the initial owner and defining the initial DAO address. Sets default parameters for fees and staking.
2.  **`updateDAOAddress(address newDAOAddress_)`**: Allows the current owner or DAO to update the address of the decentralized autonomous organization responsible for governance.
3.  **`pauseContract()`**: Emergency function to pause all critical contract operations, callable by the owner or DAO. Inherits from OpenZeppelin's Pausable.
4.  **`unpauseContract()`**: Re-enables contract operations after a pause, callable by the owner or DAO.
5.  **`setPlatformFee(uint256 newFeeBps_)`**: Sets the percentage platform fee (in basis points) to be collected from each successful inference. Callable by the DAO.

#### II. Model Registry (NFTs & Metadata) (6 functions)
6.  **`registerAIModel(string memory uri_, uint256 initialInferenceFee_)`**: Allows an AI model creator to mint a new ERC-721 NFT representing their AI model. Requires specifying a metadata URI and an initial per-inference fee.
7.  **`updateModelMetadataURI(uint256 modelId_, string memory newUri_)`**: Enables the model owner to update the off-chain metadata URI for their registered AI model NFT.
8.  **`setModelInferenceFee(uint256 modelId_, uint256 newFee_)`**: Allows the model owner to adjust the per-inference fee for their model.
9.  **`setModelAvailability(uint256 modelId_, bool available_)`**: Toggles the availability status of a model, determining if it can accept new inference requests.
10. **`proposeModelDeprecation(uint256 modelId_)`**: Initiates a proposal by the model creator to deprecate their model, setting a cooldown period (e.g., 30 days) before final deprecation.
11. **`executeModelDeprecation(uint256 modelId_)`**: Finalizes the deprecation of a model after its cooldown period, revoking its ability to accept new requests and burning its NFT. Callable by the DAO.

#### III. Inferencer Management & Staking (5 functions)
12. **`registerInferencer(string memory capabilitiesUri_)`**: Allows a participant to stake collateral (ETH) and register as an inferencer, providing a URI for their capabilities.
13. **`updateInferencerCapabilitiesURI(string memory newCapabilitiesUri_)`**: Inferencers can update their capabilities/endpoint URI.
14. **`requestInferencerDeregistration()`**: Inferencers initiate a cooldown period to unstake their collateral and deregister from the network.
15. **`confirmInferencerDeregistration()`**: After the cooldown, inferencers can finalize deregistration and withdraw their staked ETH.
16. **`slashInferencerStake(address inferencer_)`**: Function to penalize an inferencer by slashing a portion of their stake (e.g., 10%), typically invoked by the challenge resolution system or DAO.

#### IV. Inference Request & Workflow (5 functions)
17. **`requestInference(uint256 modelId_, bytes32 inputDataHash_, uint256 maxLatencySeconds_)`**: A requestor pays the model's inference fee and deposits collateral to request an inference for a specific model, providing input data hash and desired latency.
18. **`claimInferenceJob(uint256 jobId_)`**: An eligible inferencer claims an available inference job, committing to perform the computation.
19. **`submitInferenceResult(uint256 jobId_, bytes32 resultHash_, string memory proofUri_)`**: The claiming inferencer submits the hash of the inference result and a URI to a proof or the full result.
20. **`confirmInferenceResult(uint256 jobId_)`**: The requestor confirms the submitted result is satisfactory, triggering payment distribution to the model creator, inferencer, and platform, and returning requestor's collateral.
21. **`cancelInferenceRequest(uint256 jobId_)`**: A requestor can cancel an inference request if it hasn't been claimed or submitted, receiving a refund. Penalties may apply if claimed.

#### V. Validator & Challenge System (5 functions)
22. **`registerValidator()`**: Allows a participant to stake collateral (ETH) and register as a validator.
23. **`requestValidatorDeregistration()`**: Validators initiate a cooldown period to unstake their collateral and deregister.
24. **`confirmValidatorDeregistration()`**: After the cooldown, validators can finalize deregistration and withdraw their staked ETH.
25. **`initiateResultChallenge(uint256 jobId_, bytes32 actualResultHash_, string memory challengeProofUri_)`**: A requestor or another validator can challenge an inference result, providing their version of the correct result hash and a proof URI, and staking challenge collateral.
26. **`submitChallengeVote(uint256 challengeId_, bool isValid_)`**: Registered validators vote on an active challenge, indicating if the original result was valid or invalid.
27. **`resolveChallenge(uint256 challengeId_)`**: Resolves a challenge based on validator votes. If the original result was valid, the challenger loses collateral, and the inferencer is rewarded. If invalid, the inferencer's stake is slashed, and the challenger/correct voters are rewarded. Platform fees are collected.

#### VI. Reputation & Withdrawals (4 functions)
28. **`getReputationScore(address participant_)`**: Retrieves the current reputation score for a given inferencer or validator address.
29. **`claimModelCreatorEarnings(uint256 modelId_)`**: Model creators can withdraw their accumulated earnings from inferences for a specific model.
30. **`claimInferencerEarnings()`**: Inferencers can withdraw their accumulated earnings from successfully completed inferences.
31. **`claimPlatformFees()`**: The DAO can withdraw the accumulated platform fees.

*(Additionally, several setter functions are included for DAO to configure staking amounts, cooldowns, and challenge parameters, making the contract highly configurable.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
    Contract Name: AetherForge

    Outline and Function Summary:

    AetherForge is a decentralized marketplace and orchestration layer for AI model inference.
    It allows AI model creators to register and tokenize their models as NFTs, inferencers to
    stake collateral and provide inference services, and requestors to pay for and receive
    inference results. A decentralized validator network ensures the integrity of results,
    and a reputation system incentivizes honest participation. The contract integrates
    advanced concepts like NFT-based model ownership, staking, a challenge/dispute mechanism,
    and a reputation scoring system.

    I. Core Setup & Governance (5 functions)
    --------------------------------------
    1.  constructor(address initialDAOAddress_): Initializes the contract, setting the deployer
        as the initial owner and defining the initial DAO address. Sets default parameters for fees and staking.
    2.  updateDAOAddress(address newDAOAddress_): Allows the current owner or DAO to update the
        address of the decentralized autonomous organization responsible for governance.
    3.  pauseContract(): Emergency function to pause all critical contract operations, callable
        by the owner or DAO. Inherits from OpenZeppelin's Pausable.
    4.  unpauseContract(): Re-enables contract operations after a pause, callable by the owner or DAO.
    5.  setPlatformFee(uint256 newFeeBps_): Sets the percentage platform fee (in basis points)
        to be collected from each successful inference. Callable by the DAO.

    II. Model Registry (NFTs & Metadata) (6 functions)
    -------------------------------------------------
    6.  registerAIModel(string memory uri_, uint256 initialInferenceFee_):
        Allows an AI model creator to mint a new ERC-721 NFT representing their AI model.
        Requires specifying a metadata URI and an initial per-inference fee.
    7.  updateModelMetadataURI(uint256 modelId_, string memory newUri_): Enables the model
        owner to update the off-chain metadata URI for their registered AI model NFT.
    8.  setModelInferenceFee(uint256 modelId_, uint256 newFee_): Allows the model owner to
        adjust the per-inference fee for their model.
    9.  setModelAvailability(uint256 modelId_, bool available_): Toggles the availability status
        of a model, determining if it can accept new inference requests.
    10. proposeModelDeprecation(uint256 modelId_): Initiates a proposal by the model creator
        to deprecate their model, setting a cooldown period (e.g., 30 days) before final deprecation.
    11. executeModelDeprecation(uint256 modelId_): Finalizes the deprecation of a model
        after its cooldown period, revoking its ability to accept new requests and burning its NFT. Callable by the DAO.

    III. Inferencer Management & Staking (5 functions)
    --------------------------------------------------
    12. registerInferencer(string memory capabilitiesUri_): Allows a participant to stake
        collateral (ETH) and register as an inferencer, providing a URI for their capabilities.
    13. updateInferencerCapabilitiesURI(string memory newCapabilitiesUri_): Inferencers can
        update their capabilities/endpoint URI.
    14. requestInferencerDeregistration(): Inferencers initiate a cooldown period to unstake
        their collateral and deregister from the network.
    15. confirmInferencerDeregistration(): After the cooldown, inferencers can finalize
        deregistration and withdraw their staked ETH.
    16. slashInferencerStake(address inferencer_): Function to penalize an inferencer by
        slashing a portion of their stake (e.g., 10%), typically invoked by the challenge resolution system or DAO.

    IV. Inference Request & Workflow (5 functions)
    --------------------------------------------
    17. requestInference(uint256 modelId_, bytes32 inputDataHash_, uint256 maxLatencySeconds_):
        A requestor pays the model's inference fee and deposits collateral to request an
        inference for a specific model, providing input data hash and desired latency.
    18. claimInferenceJob(uint256 jobId_): An eligible inferencer claims an available inference
        job, committing to perform the computation.
    19. submitInferenceResult(uint256 jobId_, bytes32 resultHash_, string memory proofUri_):
        The claiming inferencer submits the hash of the inference result and a URI to a proof
        or the full result.
    20. confirmInferenceResult(uint256 jobId_): The requestor confirms the submitted result
        is satisfactory, triggering payment distribution to the model creator, inferencer,
        and platform, and returning requestor's collateral.
    21. cancelInferenceRequest(uint256 jobId_): A requestor can cancel an inference request
        if it hasn't been claimed or submitted, receiving a refund. Penalties may apply if claimed.

    V. Validator & Challenge System (5 functions)
    --------------------------------------------
    22. registerValidator(): Allows a participant to stake collateral (ETH) and register as a validator.
    23. requestValidatorDeregistration(): Validators initiate a cooldown period to unstake
        their collateral and deregister.
    24. confirmValidatorDeregistration(): After the cooldown, validators can finalize
        deregistration and withdraw their staked ETH.
    25. initiateResultChallenge(uint256 jobId_, bytes32 actualResultHash_, string memory challengeProofUri_):
        A requestor or another validator can challenge an inference result, providing their
        version of the correct result hash and a proof URI, and staking challenge collateral.
    26. submitChallengeVote(uint256 challengeId_, bool isValid_): Registered validators
        vote on an active challenge, indicating if the original result was valid or invalid.
    27. resolveChallenge(uint256 challengeId_): Resolves a challenge based on validator votes.
        If the original result was valid, the challenger loses collateral, and the inferencer is rewarded.
        If invalid, the inferencer's stake is slashed, and the challenger/correct voters are rewarded.
        Platform fees are collected.

    VI. Reputation & Withdrawals (4 functions)
    ----------------------------------------
    28. getReputationScore(address participant_): Retrieves the current reputation score
        for a given inferencer or validator address.
    29. claimModelCreatorEarnings(uint256 modelId_): Model creators can withdraw their
        accumulated earnings from inferences for a specific model.
    30. claimInferencerEarnings(): Inferencers can withdraw their accumulated earnings
        from successfully completed inferences.
    31. claimPlatformFees(): The DAO can withdraw the accumulated platform fees.

    (Additional DAO configuration functions for parameters are also included)
*/

contract AetherForge is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Governance
    address public daoAddress;
    uint256 public platformFeeBps; // Platform fee in basis points (e.g., 100 = 1%)
    uint256 public accumulatedPlatformFees; // Explicitly tracks platform fees

    // Staking parameters (Configurable by DAO)
    uint256 public inferencerStakeAmount; // Minimum ETH required for inferencer stake
    uint256 public validatorStakeAmount; // Minimum ETH required for validator stake
    uint256 public inferencerDeregistrationCooldown; // Time in seconds
    uint256 public validatorDeregistrationCooldown; // Time in seconds
    uint256 public challengeVotePeriod; // Time in seconds for validators to vote on a challenge
    uint256 public minValidatorsForChallenge; // Minimum validators required to participate in a challenge vote
    uint256 public modelDeprecationCooldown; // Time in seconds for model deprecation grace period

    // Nonce for job and challenge IDs
    Counters.Counter private _jobIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _modelIds; // ERC721 token IDs for models

    // --- Data Structures ---

    // AI Model
    struct AIModel {
        address creator;
        string metadataURI;
        uint256 inferenceFee; // Per inference in wei
        bool available; // Whether the model is open for new requests
        uint256 deprecationInitiatedAt; // Timestamp when deprecation was proposed (0 if not proposed)
        uint256 accumulatedEarnings; // Earnings for the model creator
    }
    mapping(uint256 => AIModel) public aiModels; // modelId => AIModel struct

    // Inferencer
    struct Inferencer {
        string capabilitiesURI;
        uint256 stake;
        uint256 registeredAt;
        uint256 deregistrationInitiatedAt; // Timestamp when deregistration was requested
        uint256 reputationScore; // Higher is better
        uint256 accumulatedEarnings; // Earnings for the inferencer
    }
    mapping(address => Inferencer) public inferencers;
    mapping(address => bool) public isInferencer; // Quick lookup

    // Validator
    struct Validator {
        uint256 stake;
        uint256 registeredAt;
        uint256 deregistrationInitiatedAt;
        uint256 reputationScore;
    }
    mapping(address => Validator) public validators;
    mapping(address => bool) public isValidator; // Quick lookup

    // Inference Job
    enum JobStatus { Pending, Claimed, ResultSubmitted, Confirmed, Challenged, Cancelled }
    struct InferenceJob {
        uint256 modelId;
        address requestor;
        address inferencer; // 0x0 if not yet claimed
        bytes32 inputDataHash;
        uint256 requestorCollateral; // Collateral for honest request
        uint256 inferenceFee; // Fee at time of request
        uint256 maxLatencySeconds; // Max latency requested by requestor
        uint256 createdAt;
        uint256 claimedAt;
        uint256 submittedAt;
        bytes32 resultHash;
        string proofUri;
        JobStatus status;
        uint256 challengeId; // If challenged
    }
    mapping(uint256 => InferenceJob) public inferenceJobs;

    // Challenge
    enum ChallengeStatus { Active, Resolved }
    struct Challenge {
        uint256 jobId;
        address challenger;
        bytes32 actualResultHash; // Challenger's proposed correct hash
        string challengeProofUri;
        uint256 initiatedAt;
        mapping(address => bool) hasVoted; // validator => voted?
        uint256 votesForOriginal;
        uint256 votesForChallenge;
        ChallengeStatus status;
        uint256 challengerCollateral; // Amount of collateral put up by challenger
    }
    mapping(uint256 => Challenge) public challenges;

    // --- Events ---
    event DAOAddressUpdated(address indexed newDAOAddress);
    event PlatformFeeUpdated(uint256 newFeeBps);

    event AIModelRegistered(uint256 indexed modelId, address indexed creator, string metadataURI, uint256 inferenceFee);
    event ModelMetadataURIUpdated(uint256 indexed modelId, string newUri);
    event ModelInferenceFeeUpdated(uint256 indexed modelId, uint256 newFee);
    event ModelAvailabilityToggled(uint256 indexed modelId, bool available);
    event ModelDeprecationProposed(uint256 indexed modelId, address indexed creator, uint256 deprecationEndsAt);
    event ModelDeprecationExecuted(uint256 indexed modelId);

    event InferencerRegistered(address indexed inferencer, uint256 stakeAmount, string capabilitiesUri);
    event InferencerCapabilitiesURIUpdated(address indexed inferencer, string newCapabilitiesUri);
    event InferencerDeregistrationRequested(address indexed inferencer, uint256 cooldownEnds);
    event InferencerDeregistrationConfirmed(address indexed inferencer);
    event InferencerStakedAmountSlashed(address indexed inferencer, uint256 slashedAmount);

    event InferenceRequested(uint256 indexed jobId, uint256 indexed modelId, address indexed requestor, uint256 fee, bytes32 inputHash);
    event InferenceJobClaimed(uint256 indexed jobId, address indexed inferencer);
    event InferenceResultSubmitted(uint256 indexed jobId, address indexed inferencer, bytes32 resultHash);
    event InferenceResultConfirmed(uint256 indexed jobId, address indexed requestor);
    event InferenceRequestCancelled(uint256 indexed jobId, address indexed requestor, string reason);

    event ValidatorRegistered(address indexed validator, uint256 stakeAmount);
    event ValidatorDeregistrationRequested(address indexed validator, uint256 cooldownEnds);
    event ValidatorDeregistrationConfirmed(address indexed validator);

    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed jobId, address indexed challenger, bytes32 actualResultHash);
    event ChallengeVoteSubmitted(uint256 indexed challengeId, address indexed validator, bool isValid);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed jobId, bool originalResultValid);

    event EarningsClaimed(address indexed receiver, uint256 amount, string assetType); // e.g., "ModelCreator", "Inferencer", "Platform"

    // --- Modifiers ---
    modifier onlyOwnerOrDAO() {
        require(msg.sender == owner() || msg.sender == daoAddress, "AetherForge: Only owner or DAO can call this function");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "AetherForge: Only DAO can call this function");
        _;
    }

    modifier onlyInferencer() {
        require(isInferencer[msg.sender], "AetherForge: Only registered inferencers can call this function");
        _;
    }

    modifier onlyValidator() {
        require(isValidator[msg.sender], "AetherForge: Only registered validators can call this function");
        _;
    }

    modifier onlyModelCreator(uint256 _modelId) {
        require(_exists(_modelId), "AetherForge: Model does not exist");
        require(ownerOf(_modelId) == msg.sender, "AetherForge: Only model creator can call this function");
        _;
    }

    // --- Constructor ---
    constructor(address initialDAOAddress_) ERC721("AetherForge AI Model", "AFMOD") Ownable(msg.sender) {
        require(initialDAOAddress_ != address(0), "AetherForge: DAO address cannot be zero");
        daoAddress = initialDAOAddress_;
        platformFeeBps = 100; // 1%

        // Default configurable parameters (can be changed by DAO)
        inferencerStakeAmount = 1 ether; // 1 ETH
        validatorStakeAmount = 0.5 ether; // 0.5 ETH
        inferencerDeregistrationCooldown = 7 days;
        validatorDeregistrationCooldown = 7 days;
        challengeVotePeriod = 3 days;
        minValidatorsForChallenge = 3;
        modelDeprecationCooldown = 30 days;
    }

    // --- I. Core Setup & Governance ---

    function updateDAOAddress(address newDAOAddress_) public onlyOwnerOrDAO nonReentrant {
        require(newDAOAddress_ != address(0), "AetherForge: New DAO address cannot be zero");
        daoAddress = newDAOAddress_;
        emit DAOAddressUpdated(newDAOAddress_);
    }

    function pauseContract() public onlyOwnerOrDAO {
        _pause();
    }

    function unpauseContract() public onlyOwnerOrDAO {
        _unpause();
    }

    function setPlatformFee(uint256 newFeeBps_) public onlyDAO nonReentrant {
        require(newFeeBps_ <= 1000, "AetherForge: Platform fee cannot exceed 10%"); // Max 10%
        platformFeeBps = newFeeBps_;
        emit PlatformFeeUpdated(newFeeBps_);
    }

    // DAO configurable parameters setters
    function setInferencerStakeAmount(uint256 amount_) public onlyDAO {
        inferencerStakeAmount = amount_;
    }
    function setValidatorStakeAmount(uint256 amount_) public onlyDAO {
        validatorStakeAmount = amount_;
    }
    function setInferencerDeregistrationCooldown(uint256 seconds_) public onlyDAO {
        inferencerDeregistrationCooldown = seconds_;
    }
    function setValidatorDeregistrationCooldown(uint256 seconds_) public onlyDAO {
        validatorDeregistrationCooldown = seconds_;
    }
    function setChallengeVotePeriod(uint256 seconds_) public onlyDAO {
        challengeVotePeriod = seconds_;
    }
    function setMinValidatorsForChallenge(uint256 count_) public onlyDAO {
        minValidatorsForChallenge = count_;
    }
    function setModelDeprecationCooldown(uint256 seconds_) public onlyDAO {
        modelDeprecationCooldown = seconds_;
    }

    // --- II. Model Registry (NFTs & Metadata) ---

    function registerAIModel(
        string memory uri_,
        uint256 initialInferenceFee_
    ) public payable whenNotPaused nonReentrant returns (uint256) {
        require(initialInferenceFee_ > 0, "AetherForge: Inference fee must be positive");

        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        // Mint the ERC721 token
        _safeMint(msg.sender, newModelId);
        _setTokenURI(newModelId, uri_);

        aiModels[newModelId] = AIModel({
            creator: msg.sender, // The model creator is the initial NFT owner
            metadataURI: uri_,
            inferenceFee: initialInferenceFee_,
            available: true,
            deprecationInitiatedAt: 0,
            accumulatedEarnings: 0
        });

        emit AIModelRegistered(newModelId, msg.sender, uri_, initialInferenceFee_);
        return newModelId;
    }

    function updateModelMetadataURI(uint256 modelId_, string memory newUri_) public onlyModelCreator(modelId_) whenNotPaused nonReentrant {
        aiModels[modelId_].metadataURI = newUri_;
        _setTokenURI(modelId_, newUri_); // Also update the ERC721 token URI
        emit ModelMetadataURIUpdated(modelId_, newUri_);
    }

    function setModelInferenceFee(uint256 modelId_, uint256 newFee_) public onlyModelCreator(modelId_) whenNotPaused nonReentrant {
        require(newFee_ > 0, "AetherForge: Inference fee must be positive");
        aiModels[modelId_].inferenceFee = newFee_;
        emit ModelInferenceFeeUpdated(modelId_, newFee_);
    }

    function setModelAvailability(uint256 modelId_, bool available_) public onlyModelCreator(modelId_) whenNotPaused nonReentrant {
        // Cannot make a model available if it's proposed for deprecation and cooldown has passed.
        if (available_) {
            require(aiModels[modelId_].deprecationInitiatedAt == 0 || block.timestamp < aiModels[modelId_].deprecationInitiatedAt, "AetherForge: Model is deprecated or pending deprecation");
        }
        aiModels[modelId_].available = available_;
        emit ModelAvailabilityToggled(modelId_, available_);
    }

    function proposeModelDeprecation(uint256 modelId_) public onlyModelCreator(modelId_) whenNotPaused nonReentrant {
        require(aiModels[modelId_].deprecationInitiatedAt == 0, "AetherForge: Deprecation already proposed or executed");
        aiModels[modelId_].deprecationInitiatedAt = block.timestamp + modelDeprecationCooldown;
        aiModels[modelId_].available = false; // Make it unavailable for new requests immediately
        emit ModelDeprecationProposed(modelId_, msg.sender, aiModels[modelId_].deprecationInitiatedAt);
    }

    function executeModelDeprecation(uint256 modelId_) public onlyDAO whenNotPaused nonReentrant {
        require(_exists(modelId_), "AetherForge: Model does not exist");
        require(aiModels[modelId_].deprecationInitiatedAt != 0, "AetherForge: Deprecation not proposed for this model");
        require(block.timestamp >= aiModels[modelId_].deprecationInitiatedAt, "AetherForge: Deprecation cooldown not yet passed");

        // Ensure no active jobs for this model (difficult to check comprehensively on-chain)
        // For simplicity, we assume that by setting `available = false` earlier, new jobs ceased.
        // It's up to off-chain actors to ensure all existing jobs for this model are resolved before this.
        _burn(modelId_); // Burn the NFT
        delete aiModels[modelId_]; // Clear model data

        emit ModelDeprecationExecuted(modelId_);
    }

    // --- III. Inferencer Management & Staking ---

    function registerInferencer(string memory capabilitiesUri_) public payable whenNotPaused nonReentrant {
        require(!isInferencer[msg.sender], "AetherForge: Already an inferencer");
        require(msg.value >= inferencerStakeAmount, "AetherForge: Insufficient stake amount");

        inferencers[msg.sender] = Inferencer({
            capabilitiesURI: capabilitiesUri_,
            stake: msg.value,
            registeredAt: block.timestamp,
            deregistrationInitiatedAt: 0,
            reputationScore: 100, // Initial reputation
            accumulatedEarnings: 0
        });
        isInferencer[msg.sender] = true;
        emit InferencerRegistered(msg.sender, msg.value, capabilitiesUri_);
    }

    function updateInferencerCapabilitiesURI(string memory newCapabilitiesUri_) public onlyInferencer whenNotPaused nonReentrant {
        inferencers[msg.sender].capabilitiesURI = newCapabilitiesUri_;
        emit InferencerCapabilitiesURIUpdated(msg.sender, newCapabilitiesUri_);
    }

    function requestInferencerDeregistration() public onlyInferencer whenNotPaused nonReentrant {
        require(inferencers[msg.sender].deregistrationInitiatedAt == 0, "AetherForge: Deregistration already requested");
        inferencers[msg.sender].deregistrationInitiatedAt = block.timestamp + inferencerDeregistrationCooldown;
        emit InferencerDeregistrationRequested(msg.sender, inferencers[msg.sender].deregistrationInitiatedAt);
    }

    function confirmInferencerDeregistration() public onlyInferencer nonReentrant {
        require(inferencers[msg.sender].deregistrationInitiatedAt != 0, "AetherForge: Deregistration not requested");
        require(block.timestamp >= inferencers[msg.sender].deregistrationInitiatedAt, "AetherForge: Deregistration cooldown not yet passed");

        uint256 stakeToReturn = inferencers[msg.sender].stake;
        delete inferencers[msg.sender];
        isInferencer[msg.sender] = false;

        (bool success, ) = payable(msg.sender).call{value: stakeToReturn}("");
        require(success, "AetherForge: Failed to return inferencer stake");

        emit InferencerDeregistrationConfirmed(msg.sender);
    }

    function slashInferencerStake(address inferencer_) public onlyDAO nonReentrant {
        require(isInferencer[inferencer_], "AetherForge: Address is not a registered inferencer");
        uint256 inferencerCurrentStake = inferencers[inferencer_].stake;
        require(inferencerCurrentStake > 0, "AetherForge: Inferencer has no stake to slash");

        uint256 slashAmount = inferencerCurrentStake.div(10); // Example: 10% slash
        inferencers[inferencer_].stake = inferencerCurrentStake.sub(slashAmount);
        inferencers[inferencer_].reputationScore = inferencers[inferencer_].reputationScore.sub(20); // Decrease reputation

        accumulatedPlatformFees = accumulatedPlatformFees.add(slashAmount); // Slashing benefits platform
        emit InferencerStakedAmountSlashed(inferencer_, slashAmount);
    }

    // --- IV. Inference Request & Workflow ---

    function requestInference(
        uint256 modelId_,
        bytes32 inputDataHash_,
        uint256 maxLatencySeconds_
    ) public payable whenNotPaused nonReentrant returns (uint256) {
        require(_exists(modelId_), "AetherForge: Model does not exist");
        require(aiModels[modelId_].available, "AetherForge: Model is not available for new requests");
        require(aiModels[modelId_].deprecationInitiatedAt == 0 || block.timestamp < aiModels[modelId_].deprecationInitiatedAt, "AetherForge: Model pending deprecation, no new requests");

        uint256 fee = aiModels[modelId_].inferenceFee;
        uint256 requestorCollateral = fee.div(2); // Example: 50% of fee as requestor collateral
        require(msg.value >= fee + requestorCollateral, "AetherForge: Insufficient funds for fee and collateral");

        _jobIds.increment();
        uint256 newJobId = _jobIds.current();

        inferenceJobs[newJobId] = InferenceJob({
            modelId: modelId_,
            requestor: msg.sender,
            inferencer: address(0),
            inputDataHash: inputDataHash_,
            requestorCollateral: requestorCollateral,
            inferenceFee: fee,
            maxLatencySeconds: maxLatencySeconds_,
            createdAt: block.timestamp,
            claimedAt: 0,
            submittedAt: 0,
            resultHash: bytes32(0),
            proofUri: "",
            status: JobStatus.Pending,
            challengeId: 0
        });

        // Any excess value sent by msg.sender is implicitly kept in the contract and will be returned with collateral on confirmation or cancellation
        uint256 refundExcess = msg.value.sub(fee).sub(requestorCollateral);
        if (refundExcess > 0) {
            (bool success, ) = payable(msg.sender).call{value: refundExcess}("");
            require(success, "AetherForge: Failed to refund excess payment");
        }

        emit InferenceRequested(newJobId, modelId_, msg.sender, fee, inputDataHash_);
        return newJobId;
    }

    function claimInferenceJob(uint256 jobId_) public onlyInferencer whenNotPaused nonReentrant {
        InferenceJob storage job = inferenceJobs[jobId_];
        require(job.status == JobStatus.Pending, "AetherForge: Job is not pending");
        require(job.modelId > 0, "AetherForge: Job does not exist"); // Check modelId to ensure job is initialized
        require(aiModels[job.modelId].available, "AetherForge: Model for this job is no longer available"); // Double check model availability
        require(aiModels[job.modelId].deprecationInitiatedAt == 0 || block.timestamp < aiModels[job.modelId].deprecationInitiatedAt, "AetherForge: Model for this job pending deprecation");

        job.inferencer = msg.sender;
        job.claimedAt = block.timestamp;
        job.status = JobStatus.Claimed;

        emit InferenceJobClaimed(jobId_, msg.sender);
    }

    function submitInferenceResult(
        uint256 jobId_,
        bytes32 resultHash_,
        string memory proofUri_
    ) public onlyInferencer whenNotPaused nonReentrant {
        InferenceJob storage job = inferenceJobs[jobId_];
        require(job.inferencer == msg.sender, "AetherForge: Only the assigned inferencer can submit results");
        require(job.status == JobStatus.Claimed, "AetherForge: Job is not in claimed status");
        require(job.createdAt + job.maxLatencySeconds >= block.timestamp, "AetherForge: Result submitted too late (exceeded max latency)");

        job.resultHash = resultHash_;
        job.proofUri = proofUri_;
        job.submittedAt = block.timestamp;
        job.status = JobStatus.ResultSubmitted;

        emit InferenceResultSubmitted(jobId_, msg.sender, resultHash_);
    }

    function confirmInferenceResult(uint256 jobId_) public whenNotPaused nonReentrant {
        InferenceJob storage job = inferenceJobs[jobId_];
        require(job.requestor == msg.sender, "AetherForge: Only the requestor can confirm results");
        require(job.status == JobStatus.ResultSubmitted, "AetherForge: Result not yet submitted or already handled");

        // Calculate fees
        uint256 totalFee = job.inferenceFee;
        uint256 platformShare = totalFee.mul(platformFeeBps).div(10000); // platformFeeBps is in basis points
        uint256 inferencerShare = totalFee.sub(platformShare).div(2); // Example: 50% of remaining to inferencer
        uint256 modelCreatorShare = totalFee.sub(platformShare).sub(inferencerShare); // Remaining to model creator

        // Distribute funds
        aiModels[job.modelId].accumulatedEarnings = aiModels[job.modelId].accumulatedEarnings.add(modelCreatorShare);
        inferencers[job.inferencer].accumulatedEarnings = inferencers[job.inferencer].accumulatedEarnings.add(inferencerShare);
        accumulatedPlatformFees = accumulatedPlatformFees.add(platformShare);

        // Return requestor's collateral
        (bool success, ) = payable(job.requestor).call{value: job.requestorCollateral}("");
        require(success, "AetherForge: Failed to return requestor collateral");

        job.status = JobStatus.Confirmed;
        inferencers[job.inferencer].reputationScore = inferencers[job.inferencer].reputationScore.add(1); // Reward reputation

        emit InferenceResultConfirmed(jobId_, msg.sender);
    }

    function cancelInferenceRequest(uint256 jobId_) public whenNotPaused nonReentrant {
        InferenceJob storage job = inferenceJobs[jobId_];
        require(job.requestor == msg.sender, "AetherForge: Only the requestor can cancel their request");
        require(job.modelId > 0, "AetherForge: Job does not exist");
        require(job.status != JobStatus.Confirmed && job.status != JobStatus.Challenged, "AetherForge: Job cannot be cancelled in its current state");

        uint256 refundAmount;
        string memory reason;

        if (job.status == JobStatus.Pending) {
            refundAmount = job.inferenceFee.add(job.requestorCollateral);
            job.status = JobStatus.Cancelled;
            reason = "Unclaimed";
        } else if (job.status == JobStatus.Claimed || job.status == JobStatus.ResultSubmitted) {
            // Inferencer claimed/submitted but requestor cancels. Inferencer gets a small cut, rest to requestor.
            uint256 inferencerCancellationFee = job.inferenceFee.div(10); // Inferencer gets 10% of fee
            inferencers[job.inferencer].accumulatedEarnings = inferencers[job.inferencer].accumulatedEarnings.add(inferencerCancellationFee);
            inferencers[job.inferencer].reputationScore = inferencers[job.inferencer].reputationScore.sub(5); // Inferencer reputation hit
            job.status = JobStatus.Cancelled;
            reason = "Claimed/Submitted but cancelled by requestor";
            refundAmount = job.inferenceFee.sub(inferencerCancellationFee).add(job.requestorCollateral);
        } else {
             revert("AetherForge: Job cannot be cancelled in its current state");
        }

        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "AetherForge: Failed to refund requestor");

        emit InferenceRequestCancelled(jobId_, msg.sender, reason);
    }


    // --- V. Validator & Challenge System ---

    function registerValidator() public payable whenNotPaused nonReentrant {
        require(!isValidator[msg.sender], "AetherForge: Already a validator");
        require(msg.value >= validatorStakeAmount, "AetherForge: Insufficient stake amount");

        validators[msg.sender] = Validator({
            stake: msg.value,
            registeredAt: block.timestamp,
            deregistrationInitiatedAt: 0,
            reputationScore: 100 // Initial reputation
        });
        isValidator[msg.sender] = true;
        emit ValidatorRegistered(msg.sender, msg.value);
    }

    function requestValidatorDeregistration() public onlyValidator whenNotPaused nonReentrant {
        require(validators[msg.sender].deregistrationInitiatedAt == 0, "AetherForge: Deregistration already requested");
        validators[msg.sender].deregistrationInitiatedAt = block.timestamp + validatorDeregistrationCooldown;
        emit ValidatorDeregistrationRequested(msg.sender, validators[msg.sender].deregistrationInitiatedAt);
    }

    function confirmValidatorDeregistration() public onlyValidator nonReentrant {
        require(validators[msg.sender].deregistrationInitiatedAt != 0, "AetherForge: Deregistration not requested");
        require(block.timestamp >= validators[msg.sender].deregistrationInitiatedAt, "AetherForge: Deregistration cooldown not yet passed");

        uint256 stakeToReturn = validators[msg.sender].stake;
        delete validators[msg.sender];
        isValidator[msg.sender] = false;

        (bool success, ) = payable(msg.sender).call{value: stakeToReturn}("");
        require(success, "AetherForge: Failed to return validator stake");

        emit ValidatorDeregistrationConfirmed(msg.sender);
    }

    function initiateResultChallenge(
        uint256 jobId_,
        bytes32 actualResultHash_,
        string memory challengeProofUri_
    ) public payable whenNotPaused nonReentrant returns (uint256) {
        InferenceJob storage job = inferenceJobs[jobId_];
        require(job.status == JobStatus.ResultSubmitted, "AetherForge: Job is not in ResultSubmitted state");
        require(msg.sender == job.requestor || isValidator[msg.sender], "AetherForge: Only requestor or registered validator can initiate challenge");
        require(actualResultHash_ != job.resultHash, "AetherForge: Challenger's result is identical to original");

        uint256 challengeCollateral = job.inferenceFee.mul(2); // Example: 2x the inference fee as challenge collateral
        require(msg.value >= challengeCollateral, "AetherForge: Insufficient challenge collateral");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            jobId: jobId_,
            challenger: msg.sender,
            actualResultHash: actualResultHash_,
            challengeProofUri: challengeProofUri_,
            initiatedAt: block.timestamp,
            // hasVoted: will be initialized with default value
            votesForOriginal: 0,
            votesForChallenge: 0,
            status: ChallengeStatus.Active,
            challengerCollateral: challengeCollateral
        });

        job.status = JobStatus.Challenged;
        job.challengeId = newChallengeId;

        // Refund any excess collateral sent
        uint256 refundExcess = msg.value.sub(challengeCollateral);
        if (refundExcess > 0) {
            (bool success, ) = payable(msg.sender).call{value: refundExcess}("");
            require(success, "AetherForge: Failed to refund excess challenge payment");
        }

        emit ChallengeInitiated(newChallengeId, jobId_, msg.sender, actualResultHash_);
        return newChallengeId;
    }

    function submitChallengeVote(uint256 challengeId_, bool isValid_) public onlyValidator whenNotPaused nonReentrant {
        Challenge storage challenge = challenges[challengeId_];
        require(challenge.status == ChallengeStatus.Active, "AetherForge: Challenge is not active");
        require(!challenge.hasVoted[msg.sender], "AetherForge: Validator already voted in this challenge");
        require(block.timestamp < challenge.initiatedAt + challengeVotePeriod, "AetherForge: Voting period has ended");

        challenge.hasVoted[msg.sender] = true;
        if (isValid_) {
            challenge.votesForOriginal++;
        } else {
            challenge.votesForChallenge++;
        }

        emit ChallengeVoteSubmitted(challengeId_, msg.sender, isValid_);
    }

    function resolveChallenge(uint256 challengeId_) public whenNotPaused nonReentrant {
        Challenge storage challenge = challenges[challengeId_];
        require(challenge.status == ChallengeStatus.Active, "AetherForge: Challenge is not active");
        require(block.timestamp >= challenge.initiatedAt + challengeVotePeriod, "AetherForge: Voting period has not ended");
        require(challenge.votesForOriginal + challenge.votesForChallenge >= minValidatorsForChallenge, "AetherForge: Not enough validators voted");

        InferenceJob storage job = inferenceJobs[challenge.jobId];

        // Determine outcome
        bool originalResultValid = (challenge.votesForOriginal >= challenge.votesForChallenge);
        uint256 totalJobFee = job.inferenceFee;
        uint256 platformShare = totalJobFee.mul(platformFeeBps).div(10000);

        if (originalResultValid) {
            // Original inferencer was correct. Challenger loses collateral.
            // Inferencer gets a bonus from challenger's collateral. Requestor (if not challenger) gets collateral back.
            uint256 inferencerBonus = challenge.challengerCollateral.div(2); // 50% of challenger's collateral to inferencer
            accumulatedPlatformFees = accumulatedPlatformFees.add(challenge.challengerCollateral.sub(inferencerBonus)); // Remaining 50% to platform

            inferencers[job.inferencer].accumulatedEarnings = inferencers[job.inferencer].accumulatedEarnings.add(inferencerBonus);
            inferencers[job.inferencer].reputationScore = inferencers[job.inferencer].reputationScore.add(10); // Reward inferencer reputation

            // Now, finalize the original job payment as if confirmed
            uint256 inferencerShare = totalJobFee.sub(platformShare).div(2);
            uint256 modelCreatorShare = totalJobFee.sub(platformShare).sub(inferencerShare);

            aiModels[job.modelId].accumulatedEarnings = aiModels[job.modelId].accumulatedEarnings.add(modelCreatorShare);
            inferencers[job.inferencer].accumulatedEarnings = inferencers[job.inferencer].accumulatedEarnings.add(inferencerShare);
            accumulatedPlatformFees = accumulatedPlatformFees.add(platformShare);

            // Return requestor's collateral (only if requestor was NOT the challenger, or if requestor was challenger and won, but here they lost)
            // If requestor was challenger, their collateral for *request* is still held, but their challenge collateral is lost.
            // The `requestorCollateral` for the original inference request is returned in all successful cases where result is confirmed.
            (bool success, ) = payable(job.requestor).call{value: job.requestorCollateral}("");
            require(success, "AetherForge: Failed to return requestor collateral");

            job.status = JobStatus.Confirmed; // Job is considered confirmed
        } else {
            // Original inferencer was wrong. Inferencer's stake is slashed. Challenger and correct voting validators are rewarded.
            // Slashed amount is 10% of inferencer's stake (as per `slashInferencerStake`).
            // It will be added to `accumulatedPlatformFees` by `slashInferencerStake`.
            slashInferencerStake(job.inferencer); // Slashing function handles reputation and sends to platform fees
            inferencers[job.inferencer].reputationScore = inferencers[job.inferencer].reputationScore.sub(20); // Heavier penalty

            uint256 rewardPool = challenge.challengerCollateral.add(job.inferenceFee); // Total reward pool from challenger's stake and original job fee

            uint256 challengerReward = rewardPool.div(2); // 50% to challenger
            uint256 validatorsRewardPool = rewardPool.sub(challengerReward); // Remaining 50% for validators & platform

            // Reward challenger
            (bool success, ) = payable(challenge.challenger).call{value: challengerReward}("");
            require(success, "AetherForge: Failed to reward challenger");
            if (isValidator[challenge.challenger]) {
                validators[challenge.challenger].reputationScore = validators[challenge.challenger].reputationScore.add(10);
            }

            // Validators' reward pool goes to accumulatedPlatformFees, DAO decides distribution.
            accumulatedPlatformFees = accumulatedPlatformFees.add(validatorsRewardPool);

            // Return requestor's collateral
            (bool success, ) = payable(job.requestor).call{value: job.requestorCollateral}("");
            require(success, "AetherForge: Failed to return requestor collateral after winning challenge");

            job.status = JobStatus.Cancelled; // Job is considered cancelled due to invalid result.
        }

        // Mark challenge as resolved
        challenge.status = ChallengeStatus.Resolved;
        emit ChallengeResolved(challengeId_, job.modelId, originalResultValid);
    }

    // --- VI. Reputation & Withdrawals ---

    function getReputationScore(address participant_) public view returns (uint256) {
        if (isInferencer[participant_]) {
            return inferencers[participant_].reputationScore;
        }
        if (isValidator[participant_]) {
            return validators[participant_].reputationScore;
        }
        return 0; // Not an inferencer or validator
    }

    function claimModelCreatorEarnings(uint256 modelId_) public onlyModelCreator(modelId_) nonReentrant {
        uint256 amount = aiModels[modelId_].accumulatedEarnings;
        require(amount > 0, "AetherForge: No earnings to claim");

        aiModels[modelId_].accumulatedEarnings = 0; // Reset earnings before transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "AetherForge: Failed to claim model creator earnings");

        emit EarningsClaimed(msg.sender, amount, "ModelCreator");
    }

    function claimInferencerEarnings() public onlyInferencer nonReentrant {
        uint256 amount = inferencers[msg.sender].accumulatedEarnings;
        require(amount > 0, "AetherForge: No earnings to claim");

        inferencers[msg.sender].accumulatedEarnings = 0; // Reset earnings before transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "AetherForge: Failed to claim inferencer earnings");

        emit EarningsClaimed(msg.sender, amount, "Inferencer");
    }

    function claimPlatformFees() public onlyDAO nonReentrant {
        uint256 amount = accumulatedPlatformFees;
        require(amount > 0, "AetherForge: No platform fees to claim");

        accumulatedPlatformFees = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "AetherForge: Failed to claim platform fees");

        emit EarningsClaimed(msg.sender, amount, "Platform");
    }
}
```