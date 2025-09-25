This smart contract, named `AetherMindCollective`, envisions a decentralized platform for orchestrating, evaluating, and rewarding AI models. It aims to create a self-improving AI ecosystem where models compete to perform tasks, build reputation, and earn rewards, with community-driven governance and verification mechanisms.

It integrates several advanced and trendy concepts:
*   **Decentralized AI Model Orchestration:** While AI computation remains off-chain, the contract manages the lifecycle of AI models, their tasks, and results on-chain.
*   **Dynamic Reputation System:** AI models gain or lose reputation based on performance, which influences future task assignments and reward distribution.
*   **Commit-Reveal Scheme for Inference:** Models commit to a result hash first, then reveal the actual result, preventing front-running and enabling robust challenges.
*   **Decentralized Inference Verification & Challenge System:** Any participant can challenge a model's output, with an economic bond, fostering accountability.
*   **Conceptual ZK-Proof Integration:** Includes a field (`zkProofReference`) to point to off-chain Zero-Knowledge Proofs, allowing for future integration of verifiable and private AI computations without the high gas costs of on-chain ZK-ML verification.
*   **Adaptive Governance:** Core parameters of the collective can be adjusted through a proposal and voting system by AETHER token holders.
*   **Tokenized Incentives:** Uses a native AETHER token for staking, bounties, and rewards, aligning economic incentives.

---

**Outline and Function Summary:**

The AetherMindCollective is a decentralized platform designed to foster a vibrant ecosystem for AI model deployment, evaluation, and reward. It enables participants to register AI models, propose and execute tasks, and earn rewards based on verified performance and reputation. The contract integrates advanced concepts like dynamic reputation, a challenge system for inference verification, and conceptual hooks for ZK-proofs to enhance trust and privacy in AI computations. Governance is decentralized, allowing the community to steer the collective's evolution.

**I. Core Infrastructure & Security**
1.  **`constructor`**: Initializes the AetherMindCollective, setting up the foundational parameters including the AETHER token address, initial owner, and core fee percentages.
2.  **`updateCoreParameter`**: Allows the owner or DAO to adjust critical system-wide parameters (e.g., minimum stake, task approval threshold, challenge periods), ensuring adaptability.
3.  **`pauseContract`**: An emergency function to temporarily halt all critical operations in case of a severe vulnerability or exploit, protecting user funds and system integrity.
4.  **`unpauseContract`**: Restores contract functionality after an emergency pause, typically once the issue has been resolved or deemed safe.
5.  **`withdrawProtocolFees`**: Enables the owner or governance to extract accumulated protocol fees from successful tasks, funding further development or rewarding the DAO.

**II. AI Model Lifecycle Management**
6.  **`registerAIModel`**: Allows an AI model owner to register their model with the collective by staking AETHER tokens and providing an IPFS hash to the model's metadata and capabilities.
7.  **`updateModelMetadata`**: Enables a registered model owner to update the IPFS metadata hash associated with their model, reflecting new versions or descriptions.
8.  **`deregisterAIModel`**: Permits a model owner to withdraw their model from the collective, potentially subject to a cool-down period or forfeiture of a portion of their stake based on active tasks or reputation.
9.  **`claimDeregisteredStake`**: Allows a model owner to claim their staked AETHER after their model has completed its deregistration lockup period.
10. **`stakeToModel`**: Allows users to stake AETHER tokens to a specific AI model, signaling trust, boosting its reputation, and potentially earning a share of its future rewards.
11. **`unstakeFromModel`**: Enables users to withdraw their staked AETHER from a model, after a defined unstaking period, or instantly if the model is inactive/deregistered.
12. **`slashModelStake`** (Internal): Initiates the process to penalize a model by reducing its staked AETHER, triggered by a successfully resolved challenge proving malicious or inaccurate behavior.

**III. Task Creation & Execution Flow**
13. **`proposeTask`**: Allows any participant to propose a new AI task to the collective, including a bounty in AETHER tokens and an IPFS hash defining the task's specifications and desired output.
14. **`approveTask`**: A governance function where the DAO or a designated committee reviews and formally approves a proposed task, making it available for assignment to AI models.
15. **`assignTaskToModel`**: Assigns an approved task to one or more registered AI models, selected based on factors like reputation, stake, and declared capabilities, initiating the inference phase.
16. **`submitInferenceCommitment`**: An assigned AI model submits a cryptographic hash of its inference result for a task, along with an optional reference to an off-chain ZK-proof proving the integrity/privacy of the computation. This acts as a commitment.
17. **`revealInferenceResult`**: After a set commitment period, the model reveals the actual inference result, which is then recorded on-chain, allowing for public verification and challenge.

**IV. Evaluation, Reputation & Rewards**
18. **`challengeInferenceResult`**: Allows any participant to dispute a revealed inference result, claiming it is incorrect, incomplete, or fraudulent, by staking AETHER tokens as a bond.
19. **`resolveChallenge`**: A critical governance function to evaluate a challenge. Based on external oracle data, aggregated model results, or committee decision, it determines the validity of the challenge, leading to slashing or rewarding.
20. **`updateModelReputation`** (Internal): Dynamically adjusts a model's reputation score based on its performance in tasks, success/failure in challenges, stake held, and the accuracy of its predictions, influencing future task assignments and reward distribution.
21. **`distributeTaskBounty`**: Disburses the AETHER bounty associated with a successfully completed and verified task to the assigned AI model(s) and their stakers, after deducting protocol fees.
22. **`claimModelRewards`**: Enables AI model owners to withdraw their accumulated AETHER rewards from successfully completed tasks and positive reputation adjustments.
23. **`claimStakerRewards`**: Allows users who staked AETHER to successful models to claim their share of rewards.

**V. Governance & Adaptive Evolution**
24. **`submitGovernanceProposal`**: Any AETHER holder can propose changes to the contract's parameters, new task categories, or other system-level decisions.
25. **`voteOnProposal`**: AETHER holders cast their votes (stake-weighted) on active governance proposals, enabling decentralized decision-making.
26. **`executeProposal`**: After a proposal has passed the voting threshold and elapsed its execution delay, this function allows for the proposed changes to be enacted on-chain.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for uint256
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For Math.min

// --- Outline and Function Summary ---
// The AetherMindCollective is a decentralized platform designed to foster a vibrant ecosystem
// for AI model deployment, evaluation, and reward. It enables participants to register AI models,
// propose and execute tasks, and earn rewards based on verified performance and reputation.
// The contract integrates advanced concepts like dynamic reputation, a challenge system for
// inference verification, and conceptual hooks for ZK-proofs to enhance trust and privacy
// in AI computations. Governance is decentralized, allowing the community to steer the collective's evolution.

// I. Core Infrastructure & Security
// 1. constructor: Initializes the AetherMindCollective, setting up the foundational parameters including the AETHER token address, initial owner, and core fee percentages.
// 2. updateCoreParameter: Allows the owner or DAO to adjust critical system-wide parameters (e.g., minimum stake, task approval threshold, challenge periods), ensuring adaptability.
// 3. pauseContract: An emergency function to temporarily halt all critical operations in case of a severe vulnerability or exploit, protecting user funds and system integrity.
// 4. unpauseContract: Restores contract functionality after an emergency pause, typically once the issue has been resolved or deemed safe.
// 5. withdrawProtocolFees: Enables the owner or governance to extract accumulated protocol fees from successful tasks, funding further development or rewarding the DAO.

// II. AI Model Lifecycle Management
// 6. registerAIModel: Allows an AI model owner to register their model with the collective by staking AETHER tokens and providing an IPFS hash to the model's metadata and capabilities.
// 7. updateModelMetadata: Enables a registered model owner to update the IPFS metadata hash associated with their model, reflecting new versions or descriptions.
// 8. deregisterAIModel: Permits a model owner to withdraw their model from the collective, potentially subject to a cool-down period or forfeiture of a portion of their stake based on active tasks or reputation.
// 9. claimDeregisteredStake: Allows a model owner to claim their staked AETHER after their model has completed its deregistration lockup period.
// 10. stakeToModel: Allows users to stake AETHER tokens to a specific AI model, signaling trust, boosting its reputation, and potentially earning a share of its future rewards.
// 11. unstakeFromModel: Enables users to withdraw their staked AETHER from a model, after a defined unstaking period, or instantly if the model is inactive/deregistered.
// 12. slashModelStake (Internal): Initiates the process to penalize a model by reducing its staked AETHER, triggered by a successfully resolved challenge proving malicious or inaccurate behavior.

// III. Task Creation & Execution Flow
// 13. proposeTask: Allows any participant to propose a new AI task to the collective, including a bounty in AETHER tokens and an IPFS hash defining the task's specifications and desired output.
// 14. approveTask: A governance function where the DAO or a designated committee reviews and formally approves a proposed task, making it available for assignment to AI models.
// 15. assignTaskToModel: Assigns an approved task to one or more registered AI models, selected based on factors like reputation, stake, and declared capabilities, initiating the inference phase.
// 16. submitInferenceCommitment: An assigned AI model submits a cryptographic hash of its inference result for a task, along with an optional reference to an off-chain ZK-proof proving the integrity/privacy of the computation. This acts as a commitment.
// 17. revealInferenceResult: After a set commitment period, the model reveals the actual inference result, which is then recorded on-chain, allowing for public verification and challenge.

// IV. Evaluation, Reputation & Rewards
// 18. challengeInferenceResult: Allows any participant to dispute a revealed inference result, claiming it is incorrect, incomplete, or fraudulent, by staking AETHER tokens as a bond.
// 19. resolveChallenge: A critical governance function to evaluate a challenge. Based on external oracle data, aggregated model results, or committee decision, it determines the validity of the challenge, leading to slashing or rewarding.
// 20. updateModelReputation (Internal): Dynamically adjusts a model's reputation score based on its performance in tasks, success/failure in challenges, stake held, and the accuracy of its predictions, influencing future task assignments and reward distribution.
// 21. distributeTaskBounty: Disburses the AETHER bounty associated with a successfully completed and verified task to the assigned AI model(s) and their stakers, after deducting protocol fees.
// 22. claimModelRewards: Enables AI model owners to withdraw their accumulated AETHER rewards from successfully completed tasks and positive reputation adjustments.
// 23. claimStakerRewards: Allows users who staked AETHER to successful models to claim their share of rewards.

// V. Governance & Adaptive Evolution
// 24. submitGovernanceProposal: Any AETHER holder can propose changes to the contract's parameters, new task categories, or other system-level decisions.
// 25. voteOnProposal: AETHER holders cast their votes (stake-weighted) on active governance proposals, enabling decentralized decision-making.
// 26. executeProposal: After a proposal has passed the voting threshold and elapsed its execution delay, this function allows for the proposed changes to be enacted on-chain.

contract AetherMindCollective is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    IERC20 public immutable AETHER_TOKEN; // The utility token for staking and rewards

    // --- State Variables ---

    // Protocol parameters, adjustable by governance
    uint256 public MIN_MODEL_REGISTRATION_STAKE;
    uint256 public MODEL_DEREGISTRATION_LOCKUP_PERIOD;
    uint256 public TASK_PROPOSAL_FEE;
    uint256 public INFERENCE_COMMITMENT_PERIOD; // Time for model to submit commitment
    uint256 public INFERENCE_REVEAL_PERIOD;    // Time for model to reveal result after commitment
    uint256 public CHALLENGE_PERIOD;           // Time window to challenge a revealed result
    uint256 public PROTOCOL_FEE_PERCENTAGE;    // Percentage of task bounty taken as protocol fee (0-100)
    uint256 public CHALLENGE_BOND_MULTIPLIER;  // Multiplier for challenge bond based on task bounty (e.g., 100 for 1x bounty)

    // Unique IDs for models, tasks, inference results, challenges, proposals
    uint256 private _nextModelId;
    uint256 private _nextTaskId;
    uint256 private _nextInferenceId;
    uint256 private _nextChallengeId;
    uint256 private _nextProposalId;

    // --- Data Structures ---

    enum ModelStatus { Active, Inactive, Deregistering, Slashed }
    struct Model {
        address owner;
        uint256 currentStake;           // Total AETHER staked by owner and others
        uint256 ownerStake;             // AETHER staked by the owner themselves
        int256 reputationScore;         // Dynamic reputation score (can be negative)
        string ipfsMetadataHash;        // IPFS hash pointing to model description/capabilities
        ModelStatus status;
        uint256 lastActivityTimestamp;  // Timestamp of last status change or key activity
        mapping(address => uint256) stakerStakes; // Individual staker contributions
        mapping(address => uint256) pendingStakerRewards; // Rewards owed to individual stakers (simplified)
    }
    mapping(uint256 => Model) public models; // modelId => Model struct
    mapping(address => uint256[]) public modelsByOwner; // owner => list of modelIds owned

    enum TaskStatus { Proposed, Approved, Assigned, Committed, Revealed, Challenged, Resolved, Completed, Failed }
    struct Task {
        address proposer;
        uint256 bounty;                // AETHER tokens offered for completing the task
        string ipfsTaskSpecHash;       // IPFS hash for detailed task specifications
        TaskStatus status;
        uint256 assignmentTimestamp;   // When task was assigned
        uint256 revealDeadline;        // Deadline for models to reveal result (after commitment period)
        uint256 challengeDeadline;     // Deadline for challenging the revealed result
        uint256[] assignedModelIds;    // IDs of models assigned to this task
        uint256[] inferenceResultIds;  // IDs of submitted inference results for this task
        uint256 winningModelId;        // ID of the model determined to be successful
        uint256 taskRewardCollected;   // How much of the bounty has been claimed
    }
    mapping(uint256 => Task) public tasks; // taskId => Task struct

    struct InferenceResult {
        uint256 taskId;
        uint256 modelId;
        bytes32 committedHash;         // Hash of the inference result, for commitment scheme
        string revealedResultIpfsHash; // IPFS hash of the actual inference result
        bytes32 zkProofReference;      // Optional: hash or identifier for an off-chain ZK-proof
        uint256 submissionTimestamp;   // When commitment was submitted
        bool revealed;
        bool challenged;
        bool verified;                 // True if result passed verification/challenge
        uint256 challengeId;           // ID of the challenge if one was made
    }
    mapping(uint256 => InferenceResult) public inferenceResults; // inferenceId => InferenceResult struct

    enum ChallengeStatus { Open, ResolvedValid, ResolvedInvalid }
    struct Challenge {
        uint256 inferenceId;
        address challenger;
        uint256 challengeBond;         // AETHER tokens staked by the challenger
        string reasonIpfsHash;         // IPFS hash for detailed challenge reason
        ChallengeStatus status;
        uint256 submissionTimestamp;
        uint256 resolutionTimestamp;
    }
    mapping(uint256 => Challenge) public challenges; // challengeId => Challenge struct

    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    struct GovernanceProposal {
        address proposer;
        string descriptionIpfsHash;    // IPFS hash for detailed proposal description
        bytes callData;                // Calldata for the function to execute if proposal passes
        address targetContract;        // The contract address to call (can be `address(this)`)
        uint256 voteThreshold;         // Minimum AETHER votes required for approval
        uint256 votesFor;              // Total AETHER voted for
        uint256 votesAgainst;          // Total AETHER voted against
        uint256 proposalEndTimestamp;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Voter => bool
    }
    mapping(uint256 => GovernanceProposal) public proposals; // proposalId => GovernanceProposal struct

    uint256 public protocolFeesCollected;

    // --- Events ---
    event ParameterUpdated(string indexed _paramName, uint256 _newValue);
    event ModelRegistered(uint256 indexed _modelId, address indexed _owner, string _ipfsHash, uint256 _stake);
    event ModelMetadataUpdated(uint256 indexed _modelId, string _newIpfsHash);
    event ModelDeregistered(uint256 indexed _modelId, address indexed _owner);
    event DeregisteredStakeClaimed(uint256 indexed _modelId, address indexed _owner, uint256 _amount);
    event StakedToModel(uint256 indexed _modelId, address indexed _staker, uint256 _amount);
    event UnstakedFromModel(uint256 indexed _modelId, address indexed _staker, uint256 _amount);
    event ModelStakeSlashed(uint256 indexed _modelId, uint256 _slashedAmount);

    event TaskProposed(uint256 indexed _taskId, address indexed _proposer, uint256 _bounty, string _ipfsHash);
    event TaskApproved(uint256 indexed _taskId, address indexed _approver);
    event TaskAssigned(uint256 indexed _taskId, uint256[] _assignedModelIds);
    event InferenceCommitmentSubmitted(uint256 indexed _inferenceId, uint256 indexed _taskId, uint256 indexed _modelId, bytes32 _commitment);
    event InferenceResultRevealed(uint256 indexed _inferenceId, uint256 indexed _taskId, uint256 indexed _modelId, string _resultIpfsHash);

    event InferenceResultChallenged(uint256 indexed _challengeId, uint256 indexed _inferenceId, address indexed _challenger, uint256 _bond);
    event ChallengeResolved(uint256 indexed _challengeId, uint256 indexed _inferenceId, ChallengeStatus _status);
    event ModelReputationUpdated(uint256 indexed _modelId, int256 _oldReputation, int256 _newReputation);
    event TaskBountyDistributed(uint256 indexed _taskId, uint256 indexed _winningModelId, uint256 _totalDistributed);
    event ModelRewardsClaimed(uint256 indexed _modelId, address indexed _claimer, uint256 _amount);
    event StakerRewardsClaimed(uint256 indexed _modelId, address indexed _staker, uint256 _amount);

    event ProtocolFeesWithdrawn(address indexed _receiver, uint256 _amount);
    event GovernanceProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer, string _descriptionIpfsHash);
    event VoteCast(uint256 indexed _proposalId, address indexed _voter, uint256 _amount, bool _support);
    event ProposalExecuted(uint256 indexed _proposalId);
    event ProposalStatusChanged(uint256 indexed _proposalId, ProposalStatus _newStatus);

    // --- Constructor ---
    constructor(
        address _aetherTokenAddress,
        uint256 _minModelRegistrationStake,
        uint256 _modelDeregistrationLockupPeriod,
        uint256 _taskProposalFee,
        uint256 _inferenceCommitmentPeriod,
        uint256 _inferenceRevealPeriod,
        uint256 _challengePeriod,
        uint256 _protocolFeePercentage,
        uint256 _challengeBondMultiplier
    ) Ownable(msg.sender) {
        require(_aetherTokenAddress != address(0), "Invalid AETHER token address");
        AETHER_TOKEN = IERC20(_aetherTokenAddress);

        MIN_MODEL_REGISTRATION_STAKE = _minModelRegistrationStake;
        MODEL_DEREGISTRATION_LOCKUP_PERIOD = _modelDeregistrationLockupPeriod;
        TASK_PROPOSAL_FEE = _taskProposalFee;
        INFERENCE_COMMITMENT_PERIOD = _inferenceCommitmentPeriod;
        INFERENCE_REVEAL_PERIOD = _inferenceRevealPeriod;
        CHALLENGE_PERIOD = _challengePeriod;
        require(_protocolFeePercentage <= 100, "Fee percentage cannot exceed 100");
        PROTOCOL_FEE_PERCENTAGE = _protocolFeePercentage;
        CHALLENGE_BOND_MULTIPLIER = _challengeBondMultiplier;

        _nextModelId = 1;
        _nextTaskId = 1;
        _nextInferenceId = 1;
        _nextChallengeId = 1;
        _nextProposalId = 1;
    }

    // --- I. Core Infrastructure & Security ---

    /**
     * @notice Allows the owner or DAO to adjust critical system-wide parameters.
     * @dev For a fully decentralized DAO, this function would typically be called via `executeProposal`.
     * @param _paramName String identifier for the parameter to update.
     * @param _newValue The new value for the parameter.
     */
    function updateCoreParameter(string calldata _paramName, uint256 _newValue)
        external
        onlyOwner // Placeholder for DAO governance
        whenNotPaused
    {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        if (paramHash == keccak256(abi.encodePacked("MIN_MODEL_REGISTRATION_STAKE"))) {
            MIN_MODEL_REGISTRATION_STAKE = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("MODEL_DEREGISTRATION_LOCKUP_PERIOD"))) {
            MODEL_DEREGISTRATION_LOCKUP_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("TASK_PROPOSAL_FEE"))) {
            TASK_PROPOSAL_FEE = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("INFERENCE_COMMITMENT_PERIOD"))) {
            INFERENCE_COMMITMENT_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("INFERENCE_REVEAL_PERIOD"))) {
            INFERENCE_REVEAL_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("CHALLENGE_PERIOD"))) {
            CHALLENGE_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("PROTOCOL_FEE_PERCENTAGE"))) {
            require(_newValue <= 100, "Fee percentage cannot exceed 100");
            PROTOCOL_FEE_PERCENTAGE = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("CHALLENGE_BOND_MULTIPLIER"))) {
            CHALLENGE_BOND_MULTIPLIER = _newValue;
        } else {
            revert("Unknown parameter");
        }
        emit ParameterUpdated(_paramName, _newValue);
    }

    /**
     * @notice Pauses contract operations in case of emergency.
     * @dev Only owner can call this.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract operations.
     * @dev Only owner can call this.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner or DAO to withdraw accumulated protocol fees.
     * @dev For a fully decentralized DAO, this would typically be called via `executeProposal`.
     * @param _amount The amount of AETHER tokens to withdraw.
     */
    function withdrawProtocolFees(uint256 _amount)
        external
        onlyOwner // Placeholder for DAO governance
        whenNotPaused
    {
        require(_amount > 0 && _amount <= protocolFeesCollected, "Invalid amount or insufficient fees");
        protocolFeesCollected = protocolFeesCollected.sub(_amount);
        require(AETHER_TOKEN.transfer(owner(), _amount), "AETHER transfer failed");
        emit ProtocolFeesWithdrawn(owner(), _amount);
    }

    // --- II. AI Model Lifecycle Management ---

    /**
     * @notice Registers a new AI model with the collective.
     * @dev Requires AETHER token approval for the stake amount prior to calling.
     * @param _ipfsMetadataHash IPFS hash pointing to the model's description and capabilities.
     * @return modelId The unique ID assigned to the new model.
     */
    function registerAIModel(string calldata _ipfsMetadataHash)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 modelId)
    {
        require(MIN_MODEL_REGISTRATION_STAKE > 0, "Registration stake is zero. Contact governance.");
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), MIN_MODEL_REGISTRATION_STAKE), "AETHER transfer failed for stake");

        modelId = _nextModelId++;
        Model storage newModel = models[modelId];
        newModel.owner = msg.sender;
        newModel.currentStake = MIN_MODEL_REGISTRATION_STAKE;
        newModel.ownerStake = MIN_MODEL_REGISTRATION_STAKE;
        newModel.reputationScore = 0; // Starting reputation
        newModel.ipfsMetadataHash = _ipfsMetadataHash;
        newModel.status = ModelStatus.Active;
        newModel.lastActivityTimestamp = block.timestamp;
        newModel.stakerStakes[msg.sender] = MIN_MODEL_REGISTRATION_STAKE;

        modelsByOwner[msg.sender].push(modelId);

        emit ModelRegistered(modelId, msg.sender, _ipfsMetadataHash, MIN_MODEL_REGISTRATION_STAKE);
    }

    /**
     * @notice Allows a registered model owner to update their model's metadata.
     * @param _modelId The ID of the model to update.
     * @param _newIpfsMetadataHash New IPFS hash for metadata.
     */
    function updateModelMetadata(uint256 _modelId, string calldata _newIpfsMetadataHash)
        external
        whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Only model owner can update metadata");
        require(model.status == ModelStatus.Active, "Model not active");
        require(bytes(_newIpfsMetadataHash).length > 0, "IPFS hash cannot be empty");

        model.ipfsMetadataHash = _newIpfsMetadataHash;
        emit ModelMetadataUpdated(_modelId, _newIpfsMetadataHash);
    }

    /**
     * @notice Allows a model owner to initiate deregistration.
     * @dev The actual stake withdrawal is subject to `MODEL_DEREGISTRATION_LOCKUP_PERIOD`.
     *      No new tasks will be assigned to a deregistering model.
     * @param _modelId The ID of the model to deregister.
     */
    function deregisterAIModel(uint256 _modelId)
        external
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Only model owner can deregister");
        require(model.status == ModelStatus.Active, "Model not active for deregistration");
        // Future improvement: prevent deregistration if model has active assignments or unresolved challenges.

        model.status = ModelStatus.Deregistering;
        model.lastActivityTimestamp = block.timestamp; // Mark start of lockup

        emit ModelDeregistered(_modelId, msg.sender);
    }

    /**
     * @notice Allows a model owner to claim their stake after deregistration lockup.
     * @param _modelId The ID of the model to claim stake from.
     */
    function claimDeregisteredStake(uint256 _modelId)
        external
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Only model owner can claim stake");
        require(model.status == ModelStatus.Deregistering, "Model is not in deregistering state");
        require(block.timestamp >= model.lastActivityTimestamp.add(MODEL_DEREGISTRATION_LOCKUP_PERIOD), "Deregistration lockup period not over");
        require(model.ownerStake > 0, "No owner stake to claim");

        uint256 amountToReturn = model.ownerStake; 

        model.currentStake = model.currentStake.sub(amountToReturn);
        model.ownerStake = 0;
        model.stakerStakes[msg.sender] = model.stakerStakes[msg.sender].sub(amountToReturn);

        // If no other stakers, change status to Inactive
        if (model.currentStake == 0) {
            model.status = ModelStatus.Inactive;
        }

        require(AETHER_TOKEN.transfer(msg.sender, amountToReturn), "AETHER transfer failed");
        emit DeregisteredStakeClaimed(_modelId, msg.sender, amountToReturn);
    }


    /**
     * @notice Allows users to stake AETHER tokens to a specific AI model.
     * @dev Requires AETHER token approval for the amount prior to calling.
     * @param _modelId The ID of the model to stake to.
     * @param _amount The amount of AETHER tokens to stake.
     */
    function stakeToModel(uint256 _modelId, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Active, "Model not active for staking");
        require(_amount > 0, "Stake amount must be greater than zero");

        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), _amount), "AETHER transfer failed for stake");

        model.currentStake = model.currentStake.add(_amount);
        model.stakerStakes[msg.sender] = model.stakerStakes[msg.sender].add(_amount);

        emit StakedToModel(_modelId, msg.sender, _amount);
    }

    /**
     * @notice Enables users to withdraw their staked AETHER from a model.
     * @param _modelId The ID of the model to unstake from.
     * @param _amount The amount of AETHER tokens to unstake.
     */
    function unstakeFromModel(uint256 _modelId, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[_modelId];
        require(model.status != ModelStatus.Inactive && model.status != ModelStatus.Slashed, "Model not available for unstaking");
        require(_amount > 0 && model.stakerStakes[msg.sender] >= _amount, "Invalid amount or insufficient stake");

        model.currentStake = model.currentStake.sub(_amount);
        model.stakerStakes[msg.sender] = model.stakerStakes[msg.sender].sub(_amount);

        // If the unstaker is the owner, also reduce ownerStake
        if (model.owner == msg.sender) {
            model.ownerStake = model.ownerStake.sub(_amount);
        }

        require(AETHER_TOKEN.transfer(msg.sender, _amount), "AETHER transfer failed");
        emit UnstakedFromModel(_modelId, msg.sender, _amount);
    }

    /**
     * @notice Initiates slashing due to proven misbehavior.
     * @dev Called internally by `resolveChallenge` or by governance directly for severe infractions.
     * @param _modelId The ID of the model to slash.
     * @param _slashAmount The amount of AETHER tokens to remove from the stake.
     * @return actualSlashAmount The actual amount of AETHER slashed.
     */
    function slashModelStake(uint256 _modelId, uint256 _slashAmount)
        internal
        returns (uint256 actualSlashAmount)
    {
        Model storage model = models[_modelId];
        require(model.status != ModelStatus.Inactive && model.status != ModelStatus.Slashed, "Cannot slash inactive or already slashed model");
        
        actualSlashAmount = Math.min(model.currentStake, _slashAmount);
        
        model.currentStake = model.currentStake.sub(actualSlashAmount);
        protocolFeesCollected = protocolFeesCollected.add(actualSlashAmount); // Slashed stake goes to protocol fees

        // Reduce owner's stake first, then proportionally from other stakers.
        if (model.ownerStake >= actualSlashAmount) {
            model.ownerStake = model.ownerStake.sub(actualSlashAmount);
            model.stakerStakes[model.owner] = model.stakerStakes[model.owner].sub(actualSlashAmount);
        } else {
            uint256 remainingSlash = actualSlashAmount.sub(model.ownerStake);
            model.stakerStakes[model.owner] = 0;
            model.ownerStake = 0;
            // Distribute remainingSlash among other stakers. This requires iterating `stakerStakes` 
            // or a more complex weighted calculation, which is gas-intensive. 
            // For simplicity here, we assume the `currentStake` accurately reflects the pool from which it's reduced.
            // A production system might require a different staking mechanism to easily prorate.
            // For this example, individual staker balances in `stakerStakes` might not be updated proportionally for external stakers.
        }

        if (model.currentStake == 0) {
            model.status = ModelStatus.Slashed; // Model is completely removed if stake goes to 0
        }
        
        emit ModelStakeSlashed(_modelId, actualSlashAmount);
    }

    // --- III. Task Creation & Execution Flow ---

    /**
     * @notice Proposes a new AI task to the collective.
     * @dev Requires AETHER token approval for the bounty and fee prior to calling.
     * @param _bounty The AETHER tokens offered for completing the task.
     * @param _ipfsTaskSpecHash IPFS hash for detailed task specifications.
     * @return taskId The unique ID assigned to the new task.
     */
    function proposeTask(uint256 _bounty, string calldata _ipfsTaskSpecHash)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 taskId)
    {
        require(_bounty > 0, "Task bounty must be greater than zero");
        require(bytes(_ipfsTaskSpecHash).length > 0, "Task spec IPFS hash cannot be empty");
        require(TASK_PROPOSAL_FEE > 0, "Task proposal fee is zero. Contact governance.");
        
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), _bounty.add(TASK_PROPOSAL_FEE)), "AETHER transfer failed for bounty and fee");

        taskId = _nextTaskId++;
        tasks[taskId] = Task({
            proposer: msg.sender,
            bounty: _bounty,
            ipfsTaskSpecHash: _ipfsTaskSpecHash,
            status: TaskStatus.Proposed,
            assignmentTimestamp: 0,
            revealDeadline: 0,
            challengeDeadline: 0,
            assignedModelIds: new uint256[](0),
            inferenceResultIds: new uint256[](0),
            winningModelId: 0,
            taskRewardCollected: 0
        });

        protocolFeesCollected = protocolFeesCollected.add(TASK_PROPOSAL_FEE);
        emit TaskProposed(taskId, msg.sender, _bounty, _ipfsTaskSpecHash);
    }

    /**
     * @notice Approves a proposed task, making it available for assignment.
     * @dev Only governance (owner or DAO) can approve tasks.
     * @param _taskId The ID of the task to approve.
     */
    function approveTask(uint256 _taskId)
        external
        onlyOwner // Placeholder for DAO governance or a designated committee role
        whenNotPaused
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Proposed, "Task not in proposed state");

        task.status = TaskStatus.Approved;
        emit TaskApproved(_taskId, msg.sender);
    }

    /**
     * @notice Assigns an approved task to one or more registered AI models.
     * @dev This function can be called by an automated system, DAO, or trusted committee.
     * @param _taskId The ID of the task to assign.
     * @param _modelIds An array of model IDs chosen to execute the task.
     */
    function assignTaskToModel(uint256 _taskId, uint256[] calldata _modelIds)
        external
        onlyOwner // Placeholder for DAO governance or a designated committee role
        whenNotPaused
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Approved, "Task not in approved state");
        require(_modelIds.length > 0, "Must assign to at least one model");

        for (uint256 i = 0; i < _modelIds.length; i++) {
            Model storage model = models[_modelIds[i]];
            require(model.status == ModelStatus.Active, "Assigned model is not active");
            task.assignedModelIds.push(_modelIds[i]);
        }

        task.status = TaskStatus.Assigned;
        task.assignmentTimestamp = block.timestamp;
        task.revealDeadline = block.timestamp.add(INFERENCE_COMMITMENT_PERIOD).add(INFERENCE_REVEAL_PERIOD);
        task.challengeDeadline = task.revealDeadline.add(CHALLENGE_PERIOD);

        emit TaskAssigned(_taskId, _modelIds);
    }

    /**
     * @notice An assigned AI model submits a cryptographic hash of its inference result.
     * @param _taskId The ID of the task.
     * @param _committedHash The keccak256 hash of the inference result to be revealed later.
     * @param _zkProofReference Optional: a hash or identifier for an off-chain ZK-proof.
     */
    function submitInferenceCommitment(uint256 _taskId, bytes32 _committedHash, bytes32 _zkProofReference)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 inferenceId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Assigned || task.status == TaskStatus.Committed, "Task not in assigned or committed state");

        // Ensure msg.sender is an owner of an assigned model for this task
        uint256 modelId = 0;
        for (uint256 i = 0; i < task.assignedModelIds.length; i++) {
            if (models[task.assignedModelIds[i]].owner == msg.sender) {
                modelId = task.assignedModelIds[i];
                break;
            }
        }
        require(modelId != 0, "Sender is not an owner of an assigned model for this task");
        require(models[modelId].status == ModelStatus.Active, "Model is not active");

        // Check if commitment period is still open
        require(block.timestamp <= task.assignmentTimestamp.add(INFERENCE_COMMITMENT_PERIOD), "Commitment period has ended");

        inferenceId = _nextInferenceId++;
        inferenceResults[inferenceId] = InferenceResult({
            taskId: _taskId,
            modelId: modelId,
            committedHash: _committedHash,
            revealedResultIpfsHash: "", // Will be filled upon reveal
            zkProofReference: _zkProofReference,
            submissionTimestamp: block.timestamp,
            revealed: false,
            challenged: false,
            verified: false,
            challengeId: 0
        });
        task.inferenceResultIds.push(inferenceId);

        // If this is the first commitment, update task status
        if (task.status == TaskStatus.Assigned) {
            task.status = TaskStatus.Committed;
        }

        emit InferenceCommitmentSubmitted(inferenceId, _taskId, modelId, _committedHash);
    }

    /**
     * @notice An assigned AI model reveals its inference result after the commitment period.
     * @param _inferenceId The ID of the inference commitment to reveal.
     * @param _revealedResultIpfsHash IPFS hash of the actual inference result.
     */
    function revealInferenceResult(uint256 _inferenceId, string calldata _revealedResultIpfsHash)
        external
        whenNotPaused
        nonReentrant
    {
        InferenceResult storage inference = inferenceResults[_inferenceId];
        require(inference.revealed == false, "Result already revealed");
        require(inference.modelId > 0, "Inference does not exist");
        require(models[inference.modelId].owner == msg.sender, "Only the committing model's owner can reveal");

        Task storage task = tasks[inference.taskId];
        require(block.timestamp > inference.submissionTimestamp.add(INFERENCE_COMMITMENT_PERIOD), "Commitment period not over yet"); 
        require(block.timestamp <= task.revealDeadline, "Reveal period has ended");

        // Verify the revealed result against the committed hash
        bytes32 actualHash = keccak256(abi.encodePacked(_revealedResultIpfsHash));
        require(inference.committedHash == actualHash, "Revealed result hash mismatch");

        inference.revealedResultIpfsHash = _revealedResultIpfsHash;
        inference.revealed = true;

        // If this is the last or only result needed, set task status to Revealed
        // More sophisticated logic would verify all assigned models have revealed.
        // For simplicity, a task transitions to Revealed if at least one result is revealed.
        if (task.status == TaskStatus.Committed) {
            task.status = TaskStatus.Revealed;
        }
        
        emit InferenceResultRevealed(_inferenceId, inference.taskId, inference.modelId, _revealedResultIpfsHash);
    }

    // --- IV. Evaluation, Reputation & Rewards ---

    /**
     * @notice Allows any participant to dispute a revealed inference result.
     * @dev Requires AETHER token approval for the challenge bond prior to calling.
     * @param _inferenceId The ID of the inference result to challenge.
     * @param _reasonIpfsHash IPFS hash for detailed reason for the challenge.
     * @return challengeId The unique ID assigned to the new challenge.
     */
    function challengeInferenceResult(uint256 _inferenceId, string calldata _reasonIpfsHash)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 challengeId)
    {
        InferenceResult storage inference = inferenceResults[_inferenceId];
        require(inference.modelId > 0, "Inference result does not exist");
        require(inference.revealed, "Result not yet revealed");
        require(inference.challenged == false, "Result already challenged");

        Task storage task = tasks[inference.taskId];
        require(block.timestamp <= task.challengeDeadline, "Challenge period has ended");
        
        uint256 challengeBond = task.bounty.mul(CHALLENGE_BOND_MULTIPLIER).div(100); // e.g., 1x bounty if multiplier is 100
        require(challengeBond > 0, "Calculated challenge bond is zero");

        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), challengeBond), "AETHER transfer failed for challenge bond");

        inference.challenged = true;
        // Task status set to Challenged to indicate active dispute
        task.status = TaskStatus.Challenged; 

        challengeId = _nextChallengeId++;
        challenges[challengeId] = Challenge({
            inferenceId: _inferenceId,
            challenger: msg.sender,
            challengeBond: challengeBond,
            reasonIpfsHash: _reasonIpfsHash,
            status: ChallengeStatus.Open,
            submissionTimestamp: block.timestamp,
            resolutionTimestamp: 0
        });
        inference.challengeId = challengeId;

        emit InferenceResultChallenged(challengeId, _inferenceId, msg.sender, challengeBond);
    }

    /**
     * @notice A critical governance function to evaluate and resolve a challenge.
     * @dev This would typically be called by a DAO vote or a trusted oracle/committee.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengeSuccessful True if the challenge is valid (model was wrong/malicious).
     */
    function resolveChallenge(uint256 _challengeId, bool _challengeSuccessful)
        external
        onlyOwner // Placeholder for DAO governance
        whenNotPaused
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "Challenge not open");

        InferenceResult storage inference = inferenceResults[challenge.inferenceId];
        Task storage task = tasks[inference.taskId];
        Model storage model = models[inference.modelId];

        challenge.resolutionTimestamp = block.timestamp;

        if (_challengeSuccessful) {
            challenge.status = ChallengeStatus.ResolvedValid;
            inference.verified = false; // Mark inference as failed
            
            // Slashing: model loses stake.
            uint256 slashAmount = task.bounty.div(10); // Example: slash 10% of task bounty (adjustable parameter)
            uint256 actualSlashedAmount = slashModelStake(model.modelId, slashAmount); 

            // Reward challenger: gets back their bond and a portion of the slashed amount.
            require(AETHER_TOKEN.transfer(challenge.challenger, challenge.challengeBond), "Challenger bond refund failed");
            uint256 rewardFromSlashed = actualSlashedAmount.div(2); // Example: 50% of slashed funds (adjustable)
            if (rewardFromSlashed > 0) {
                protocolFeesCollected = protocolFeesCollected.sub(rewardFromSlashed); // Deduct from collected fees
                require(AETHER_TOKEN.transfer(challenge.challenger, rewardFromSlashed), "Challenger reward failed");
            }
            
            updateModelReputation(model.modelId, -100); // Example: significant reputation penalty
            task.status = TaskStatus.Failed; // Mark task as failed if the winning model was challenged successfully
        } else {
            challenge.status = ChallengeStatus.ResolvedInvalid;
            inference.verified = true; // Mark inference as verified
            
            // Challenger loses bond, bond goes to protocol fees.
            protocolFeesCollected = protocolFeesCollected.add(challenge.challengeBond);

            updateModelReputation(model.modelId, 10); // Example: small reputation boost for surviving challenge
            // If this was the only challenged result, revert task status to Revealed or proceed to Completed.
            // Simplified: if task was challenged and challenge is invalid, it can proceed to distribute bounty.
            if(task.status == TaskStatus.Challenged) { 
                 task.status = TaskStatus.Resolved; // Task is resolved, can move to completion
            }
        }
        
        emit ChallengeResolved(_challengeId, inference.inferenceId, challenge.status);
    }

    /**
     * @notice Dynamically adjusts a model's reputation score.
     * @dev Internal function, called after task completion or challenge resolution.
     * @param _modelId The ID of the model to update.
     * @param _change The amount to change the reputation score by (can be negative).
     */
    function updateModelReputation(uint256 _modelId, int256 _change) internal {
        Model storage model = models[_modelId];
        int256 oldReputation = model.reputationScore;
        model.reputationScore = model.reputationScore.add(_change);
        emit ModelReputationUpdated(_modelId, oldReputation, model.reputationScore);
    }

    /**
     * @notice Disburses the AETHER bounty associated with a successfully completed and verified task.
     * @dev This function assumes a winning model has been identified (e.g., first verified inference)
     *      or that resolution of challenges has clarified the winner.
     * @param _taskId The ID of the task to distribute bounty for.
     */
    function distributeTaskBounty(uint256 _taskId)
        external
        onlyOwner // Placeholder for DAO governance or a designated committee role
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Revealed || task.status == TaskStatus.Resolved, "Task not ready for bounty distribution"); 
        require(task.bounty > task.taskRewardCollected, "Bounty already fully distributed");

        // Determine the winning inference result
        uint256 winningInferenceId = 0;
        for(uint256 i = 0; i < task.inferenceResultIds.length; i++) {
            InferenceResult storage inf = inferenceResults[task.inferenceResultIds[i]];
            if(inf.revealed && !inf.challenged) { // Revealed and not challenged
                winningInferenceId = task.inferenceResultIds[i];
                break;
            }
            if(inf.revealed && inf.challenged && challenges[inf.challengeId].status == ChallengeStatus.ResolvedInvalid) { // Challenged but challenge was invalid
                winningInferenceId = task.inferenceResultIds[i];
                break;
            }
        }
        require(winningInferenceId > 0, "No verified inference result found for task");
        InferenceResult storage winningInference = inferenceResults[winningInferenceId];
        task.winningModelId = winningInference.modelId;

        Model storage winningModel = models[task.winningModelId];
        require(winningModel.status == ModelStatus.Active || winningModel.status == ModelStatus.Deregistering, "Winning model not eligible for rewards");

        uint256 totalBounty = task.bounty;
        uint256 protocolFee = totalBounty.mul(PROTOCOL_FEE_PERCENTAGE).div(100);
        uint256 rewardForModelAndStakers = totalBounty.sub(protocolFee);

        protocolFeesCollected = protocolFeesCollected.add(protocolFee);

        // Distribute rewards based on model's reputation and individual stakers
        // Simplified distribution: A portion for model owner based on reputation, remainder to stakers.
        uint256 modelOwnerBaseShare = rewardForModelAndStakers.mul(10).div(100); // 10% base share for owner
        uint256 reputationBonus = 0;
        if (winningModel.reputationScore > 0) {
            reputationBonus = rewardForModelAndStakers.mul(uint256(winningModel.reputationScore)).div(10000); // Example: 0.01% bonus per rep point
        }
        uint256 modelOwnerTotalShare = modelOwnerBaseShare.add(reputationBonus);
        if (modelOwnerTotalShare > rewardForModelAndStakers) modelOwnerTotalShare = rewardForModelAndStakers; // Cap owner's share

        uint256 stakersShare = rewardForModelAndStakers.sub(modelOwnerTotalShare);
        
        winningModel.pendingStakerRewards[winningModel.owner] = winningModel.pendingStakerRewards[winningModel.owner].add(modelOwnerTotalShare);
        
        // A simple way to handle other stakers without iterating is to pool rewards for a later pro-rata claim.
        // In a complex system, each staker's individual share would be calculated and stored explicitly.
        if (stakersShare > 0 && winningModel.currentStake > winningModel.ownerStake) {
            // Store `stakersShare` in a special address for general stakers to claim pro-rata.
            // This is a simplification; a production-ready system needs dedicated individual reward tracking or a Merkle distributor.
            winningModel.pendingStakerRewards[address(0)] = winningModel.pendingStakerRewards[address(0)].add(stakersShare); 
        } else if (stakersShare > 0) { // If only owner staked, owner gets the remainder as well
            winningModel.pendingStakerRewards[winningModel.owner] = winningModel.pendingStakerRewards[winningModel.owner].add(stakersShare);
        }

        task.taskRewardCollected = task.bounty; // Mark as fully collected
        task.status = TaskStatus.Completed;
        updateModelReputation(winningModel.modelId, 50); // Example: positive reputation for task completion

        emit TaskBountyDistributed(_taskId, winningModel.modelId, rewardForModelAndStakers);
    }

    /**
     * @notice Enables AI model owners to withdraw their accumulated AETHER rewards.
     * @param _modelId The ID of the model from which to claim rewards.
     */
    function claimModelRewards(uint256 _modelId)
        external
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Only model owner can claim model rewards");

        uint256 amount = model.pendingStakerRewards[msg.sender];
        require(amount > 0, "No pending rewards for this model owner");

        model.pendingStakerRewards[msg.sender] = 0;
        require(AETHER_TOKEN.transfer(msg.sender, amount), "AETHER transfer failed");
        emit ModelRewardsClaimed(_modelId, msg.sender, amount);
    }

    /**
     * @notice Allows users who staked AETHER to successful models to claim their share of rewards.
     * @dev This is a simplified version; a real system would need more granular tracking of individual staker rewards.
     *      It assumes rewards for external stakers are pooled and claimed pro-rata from `address(0)`'s balance.
     * @param _modelId The ID of the model the staker contributed to.
     */
    function claimStakerRewards(uint256 _modelId)
        external
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[_modelId];
        require(model.stakerStakes[msg.sender] > 0, "Sender has no stake in this model");
        
        uint256 totalExternalStake = model.currentStake.sub(model.ownerStake);
        require(totalExternalStake > 0, "No external stakes to distribute from");

        uint256 generalStakerPool = model.pendingStakerRewards[address(0)];
        require(generalStakerPool > 0, "No general staker rewards to claim");

        uint256 stakerShare = generalStakerPool.mul(model.stakerStakes[msg.sender]).div(totalExternalStake);

        require(stakerShare > 0, "Calculated staker share is zero");

        // Deduct from general pool (approximate, potential for rounding issues or exact accounting needed)
        // A better approach would be to assign specific shares when bounties are distributed.
        model.pendingStakerRewards[address(0)] = model.pendingStakerRewards[address(0)].sub(stakerShare); 
        
        require(AETHER_TOKEN.transfer(msg.sender, stakerShare), "AETHER transfer failed");
        emit StakerRewardsClaimed(_modelId, msg.sender, stakerShare);
    }


    // --- V. Governance & Adaptive Evolution ---

    /**
     * @notice Allows any AETHER holder to propose changes to contract parameters or logic.
     * @dev Requires a minimum proposal fee.
     * @param _descriptionIpfsHash IPFS hash for detailed proposal description.
     * @param _targetContract The address of the contract the proposal will interact with (e.g., this contract).
     * @param _callData The calldata for the function call to be executed if the proposal passes.
     * @param _voteThreshold Minimum AETHER tokens required for approval (relative to total supply or active voters).
     * @param _proposalDuration The duration in seconds for which the proposal will be open for voting.
     * @return proposalId The unique ID of the submitted proposal.
     */
    function submitGovernanceProposal(
        string calldata _descriptionIpfsHash,
        address _targetContract,
        bytes calldata _callData,
        uint256 _voteThreshold,
        uint256 _proposalDuration
    )
        external
        whenNotPaused
        nonReentrant
        returns (uint256 proposalId)
    {
        // For simplicity, using TASK_PROPOSAL_FEE, but could be a separate GOVERNANCE_PROPOSAL_FEE.
        require(TASK_PROPOSAL_FEE > 0, "Proposal fee is zero. Contact governance."); 
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), TASK_PROPOSAL_FEE), "AETHER transfer failed for proposal fee");
        protocolFeesCollected = protocolFeesCollected.add(TASK_PROPOSAL_FEE);

        proposalId = _nextProposalId++;
        proposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            descriptionIpfsHash: _descriptionIpfsHash,
            callData: _callData,
            targetContract: _targetContract,
            voteThreshold: _voteThreshold,
            votesFor: 0,
            votesAgainst: 0,
            proposalEndTimestamp: block.timestamp.add(_proposalDuration),
            status: ProposalStatus.Pending
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender, _descriptionIpfsHash);
    }

    /**
     * @notice Allows AETHER holders to cast their votes on active governance proposals.
     * @dev Votes are stake-weighted based on the caller's AETHER balance at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
    {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending state");
        require(block.timestamp <= proposal.proposalEndTimestamp, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterBalance = AETHER_TOKEN.balanceOf(msg.sender); // Assuming AETHER balance determines voting power
        require(voterBalance > 0, "Voter has no AETHER tokens to vote with");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterBalance);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterBalance);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, voterBalance, _support);
    }

    /**
     * @notice Executes an approved proposal after its voting period has passed and conditions met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
        nonReentrant
    {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending state");
        require(block.timestamp > proposal.proposalEndTimestamp, "Voting period not over");

        if (proposal.votesFor >= proposal.voteThreshold && proposal.votesFor > proposal.votesAgainst) {
            // Proposal passes
            proposal.status = ProposalStatus.Approved;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Approved);
            
            // Execute the proposal's call data
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed");
            
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal fails
            proposal.status = ProposalStatus.Rejected;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Rejected);
        }
    }
}
```