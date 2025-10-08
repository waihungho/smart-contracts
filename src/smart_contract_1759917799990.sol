This smart contract, `DecentralizedAdaptiveIntelligenceNetwork (DAIN)`, is designed to foster a decentralized ecosystem around AI agents, knowledge sharing, and dynamic NFTs. It introduces concepts like on-chain representation of AI "agents," a reputation system for data providers and evaluators, and a unique prediction market. The contract aims to be a creative and advanced example, featuring a comprehensive set of functions beyond typical open-source patterns.

---

### **Contract Name:** `DecentralizedAdaptiveIntelligenceNetwork (DAIN)`

### **Core Concepts:**
*   **AI Agent Management:** On-chain registration, updating, and staking for "AI agents" (representing model interfaces or capabilities).
*   **Knowledge Capsules:** A system for users to submit data/information hashes and have them attested or challenged by the community, building a decentralized knowledge base.
*   **Reputation System:** A fundamental layer tracking contributions and behavior for users (data providers, evaluators) and AI agents, influencing rewards and privileges.
*   **Dynamic Utility NFTs (DU-NFTs):** ERC-721 NFTs that can "evolve" or change their metadata based on the holder's on-chain reputation and network activity.
*   **Decentralized Prediction Market:** A mechanism for users to request AI predictions on topics, and for agents to submit results, which are then evaluated by the community.
*   **Adaptive Parameters:** Key protocol settings mutable by the owner (or future DAO), allowing the network to adapt its economic and governance parameters over time.
*   **Tokenomics:** Utilizes an external ERC-20 token (DAIN_TOKEN) for staking, fees, and rewards, incentivizing participation and quality contributions.

### **Function Summary:**

**I. Protocol Management & Access Control**
1.  **`constructor`**: Initializes the contract with an owner, DAIN token address, fee recipient, and all core protocol parameters.
2.  **`setProtocolFeeRecipient`**: Allows the owner to change the address where protocol fees are collected.
3.  **`pauseContract`**: Initiates an emergency pause for critical operations, callable by the owner.
4.  **`unpauseContract`**: Resumes contract operations after a pause, callable by the owner.
5.  **`withdrawProtocolFees`**: Enables the owner to withdraw accumulated protocol fees in any specified token.

**II. AI Agent Lifecycle Management**
6.  **`registerAIAgent`**: Registers a new AI agent by an owner, requiring a minimum stake in DAIN tokens and a URI for its off-chain model description.
7.  **`updateAIAgentParameters`**: Allows an agent's owner to update their agent's associated off-chain parameters or metadata URI.
8.  **`deactivateAIAgent`**: Initiates the deactivation process for an agent, entering a cooldown period before stake withdrawal is possible.
9.  **`withdrawAgentStake`**: Allows an agent's owner to withdraw their initial staked DAIN tokens after the deactivation cooldown period.
10. **`delegateAgentStake`**: Enables any user to delegate DAIN tokens to an active AI agent, boosting its influence and potential rewards.
11. **`undelegateAgentStake`**: Allows a delegator to withdraw their previously delegated DAIN tokens from an AI agent.

**III. Knowledge Capsule & Data Attestation**
12. **`submitKnowledgeCapsule`**: Users submit a cryptographic hash of off-chain data/information (a "knowledge capsule"), paying a fee, and becoming a 'data provider'.
13. **`attestToKnowledgeCapsule`**: Users can attest to the validity or quality of a submitted knowledge capsule, earning reputation for accurate attestations.
14. **`challengeKnowledgeCapsule`**: Initiates a dispute over a knowledge capsule's validity within a specific challenge window, requiring a challenge bond.
15. **`resolveKnowledgeCapsuleDispute`**: The owner (or a future DAO) resolves a challenged capsule, distributing or burning bonds and adjusting reputation for both the submitter and the challenger based on the outcome.

**IV. Dynamic Utility NFTs (DU-NFTs)**
16. **`mintDU_NFT`**: Mints a new DU-NFT, requiring a minimum user reputation. These NFTs represent a user's standing or specific role within the network.
17. **`evolveDU_NFT`**: A function callable by the NFT owner (or approved operator) to update a DU-NFT's metadata, reflecting changes in the associated user's reputation or other network states.
18. **`burnDU_NFT`**: Allows a user to burn their DU-NFT.

**V. Decentralized Inference & Prediction Market**
19. **`requestPrediction`**: Users request an AI prediction on a specific topic, paying a fee and defining parameters, including rewards for the winning agent and evaluators.
20. **`submitPredictionResult`**: An active AI agent submits its prediction result for an open request within the submission deadline.
21. **`evaluatePredictionResult`**: Users (evaluators) assess the accuracy/quality of a submitted prediction, earning reputation for accurate evaluations.
22. **`finalizePrediction`**: After the evaluation period ends, this function determines the winning AI agent based on aggregated evaluation scores and finalizes the prediction market.
23. **`claimPredictionReward`**: Allows the winning AI agent's owner to claim the DAIN token rewards allocated for that prediction.

**VI. Reputation & Adaptive Tokenomics**
24. **`getAgentReputation`**: Retrieves the current reputation score of a specific AI agent.
25. **`getUserReputation`**: Retrieves the current reputation score of a specific user address.
26. **`distributeNetworkRewards`**: The owner (or DAO) can periodically distribute a pool of DAIN token rewards to top contributors (agents, data providers, evaluators) based on their accumulated reputation.
27. **`updateProtocolParameter`**: Allows the owner/DAO to adjust various mutable protocol parameters (e.g., fee rates, staking minimums, cooldown periods) to adapt the network's economics and rules.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though Solidity 0.8+ handles overflow by default.

// --- Custom Error Definitions ---
error DAIN__InsufficientStake(uint256 required, uint256 provided);
error DAIN__AgentNotFound();
error DAIN__NotAgentOwner();
error DAIN__AgentAlreadyActive();
error DAIN__AgentInactive();
error DAIN__AgentNotReadyForWithdrawal();
error DAIN__InvalidAttestation();
error DAIN__KnowledgeCapsuleNotFound();
error DAIN__ChallengePeriodEnded();
error DAIN__ChallengePeriodNotStarted();
error DAIN__AlreadyAttested();
error DAIN__PredictionNotFound();
error DAIN__PredictionAlreadySubmitted();
error DAIN__PredictionNotOpen();
error DAIN__PredictionNotReadyForEvaluation();
error DAIN__AlreadyEvaluatedPrediction();
error DAIN__EvaluationPeriodNotOver();
error DAIN__NotEnoughFunds();
error DAIN__ZeroAmount();
error DAIN__NoRewardsToClaim();
error DAIN__PredictionNotFinalized();
error DAIN__Unauthorized();
error DAIN__DU_NFTNotFound();
error DAIN__InsufficientReputation();
error DAIN__UnknownParameter();
error DAIN__SelfAttestationDenied();
error DAIN__AgentCannotEvaluateOwnPrediction();
error DAIN__InvalidAgentForPrediction();
error DAIN__NoChallengerRecorded();
error DAIN__NoReputationForRewards();


contract DecentralizedAdaptiveIntelligenceNetwork is Ownable, Pausable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public immutable DAIN_TOKEN; // The native DAIN token used for staking, fees, and rewards.
    address public protocolFeeRecipient; // Address to receive protocol fees.

    Counters.Counter private _agentIdCounter;
    Counters.Counter private _capsuleIdCounter;
    Counters.Counter private _predictionIdCounter;
    Counters.Counter private _duNftIdCounter;

    // --- Configuration Parameters (Adaptive & Mutable by Owner/DAO) ---
    uint256 public minAgentStake; // Minimum DAIN token stake required to register an AI agent.
    uint256 public knowledgeCapsuleFee; // Fee (in native currency, ETH) for submitting a knowledge capsule.
    uint256 public predictionRequestFee; // Fee (in native currency, ETH) for requesting a prediction.
    uint256 public challengeBond; // DAIN token bond required to challenge a knowledge capsule.
    uint256 public attestationRewardReputation; // Reputation points awarded for a successful knowledge capsule attestation.
    uint256 public challengeReputationPenalty; // Reputation points penalized for an unsuccessful challenge or awarded for a successful one.
    uint256 public predictionEvaluationReputation; // Reputation points awarded for evaluating a prediction.
    uint256 public minDU_NFTSlotReputation; // Minimum reputation required to mint a DU-NFT.

    uint256 public agentCooldownPeriod; // Time duration an agent must remain deactivated before its stake can be withdrawn.
    uint256 public capsuleChallengePeriod; // Time window (from submission) during which a knowledge capsule can be challenged.
    uint256 public predictionSubmissionPeriod; // Time window for AI agents to submit predictions for a request.
    uint256 public predictionEvaluationPeriod; // Time window for users to evaluate submitted predictions.

    // --- Data Structures ---

    enum AgentStatus { Active, Inactive, Cooldown }
    struct AIAgent {
        address owner;
        string metadataURI; // URI to off-chain model description, API endpoint, etc.
        uint256 stakedAmount; // Total DAIN tokens staked (owner's initial + delegated).
        AgentStatus status;
        uint256 reputation; // Accumulated reputation score.
        uint256 lastDeactivationTimestamp; // Timestamp when deactivation was initiated.
        mapping(address => uint256) delegatedStakes; // delegator address => amount delegated.
    }
    mapping(uint256 => AIAgent) public agents; // agentId => AIAgent data.
    mapping(address => uint256) public agentOfOwner; // owner address => agentId (assuming 1 active agent per owner for simplicity).
    mapping(address => uint256) public userReputation; // address => reputation score.

    enum CapsuleStatus { Active, Challenged, Validated, Invalidated }
    struct KnowledgeCapsule {
        address submitter;
        bytes32 dataHash; // Cryptographic hash of the off-chain data.
        string metadataURI; // URI to context or description of the data.
        uint256 submissionTimestamp;
        CapsuleStatus status;
        address lastChallenger; // The address of the last user who challenged this capsule.
        uint256 challengeBondStaked; // The amount of bond staked by the last challenger.
        uint256 attestationCount; // Number of attestations received.
        mapping(address => bool) hasAttested; // user address => true if attested.
    }
    mapping(uint256 => KnowledgeCapsule) public knowledgeCapsules; // capsuleId => KnowledgeCapsule data.

    enum PredictionStatus { Open, Evaluating, Finalized }
    struct PredictionRequest {
        address requester;
        string requestMetadataURI; // URI to detailed prediction request, data, etc.
        uint256 requestTimestamp;
        uint256 feePaid;
        PredictionStatus status;
        uint256 winningAgentId; // ID of the agent that provided the winning prediction.
        uint256 winningAgentReward; // DAIN token reward for the winning agent.
        uint256 totalEvaluatorReward; // DAIN token pool for evaluators (distributed via general network rewards).
        uint256 submissionDeadline; // Timestamp when prediction submissions are no longer accepted.
        uint252 evaluationDeadline; // Timestamp when prediction evaluations are no longer accepted.
        uint256[] submittedAgentIds; // List of agent IDs who submitted predictions for this request.
    }
    mapping(uint256 => PredictionRequest) public predictionRequests; // predictionId => PredictionRequest data.

    struct AgentPrediction {
        uint256 agentId;
        bytes32 predictionResultHash; // Hash of the prediction result.
        string predictionMetadataURI; // URI to description or confidence score of the prediction.
        uint256 submissionTimestamp;
        uint256 totalEvaluationScore; // Sum of scores from evaluators for this specific prediction.
        uint256 evaluatorCount; // Number of evaluators for this specific prediction.
        mapping(address => bool) hasEvaluated; // user address => true if evaluated this specific prediction.
    }
    mapping(uint256 => mapping(uint256 => AgentPrediction)) public predictionSubmissions; // predictionId => agentId => AgentPrediction data.

    // Store DU-NFT related info
    struct DU_NFTData {
        address owner;
        uint256 associatedReputation; // Snapshot of owner's reputation at mint/last evolution.
        string currentURI; // Current metadata URI for the NFT.
    }
    mapping(uint256 => DU_NFTData) public duNftData; // tokenId => DU_NFTData.

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event AIAgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI, uint256 stakeAmount);
    event AIAgentUpdated(uint256 indexed agentId, string newMetadataURI);
    event AIAgentDeactivated(uint256 indexed agentId, address indexed owner, uint256 timestamp);
    event AgentStakeWithdrawn(uint256 indexed agentId, address indexed owner, uint256 amount);
    event AgentStakeDelegated(uint256 indexed agentId, address indexed delegator, uint256 amount);
    event AgentStakeUndelegated(uint256 indexed agentId, address indexed delegator, uint256 amount);

    event KnowledgeCapsuleSubmitted(uint256 indexed capsuleId, address indexed submitter, bytes32 dataHash, string metadataURI);
    event KnowledgeCapsuleAttested(uint256 indexed capsuleId, address indexed attestor, uint256 newReputation);
    event KnowledgeCapsuleChallenged(uint256 indexed capsuleId, address indexed challenger, uint256 bondAmount);
    event KnowledgeCapsuleResolved(uint256 indexed capsuleId, CapsuleStatus newStatus, address indexed resolver, address indexed challenger, address indexed submitter);

    event DU_NFTMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);
    event DU_NFTEvolved(uint256 indexed tokenId, string newTokenURI, uint256 newReputation);
    event DU_NFTBurned(uint256 indexed tokenId, address indexed owner);

    event PredictionRequested(uint256 indexed predictionId, address indexed requester, string requestMetadataURI, uint256 feePaid, uint256 agentReward, uint256 evaluatorReward);
    event PredictionResultSubmitted(uint256 indexed predictionId, uint256 indexed agentId, bytes32 resultHash, string metadataURI);
    event PredictionResultEvaluated(uint256 indexed predictionId, uint256 indexed agentId, address indexed evaluator, uint256 evaluationScore, uint256 evaluatorReputation);
    event PredictionFinalized(uint256 indexed predictionId, uint256 indexed winningAgentId, uint256 winningScore);
    event PredictionRewardsClaimed(uint256 indexed predictionId, uint256 indexed winningAgentId, uint256 agentReward);

    event UserReputationUpdated(address indexed user, uint256 newReputation);
    event AgentReputationUpdated(uint256 indexed agentId, uint256 newReputation);
    event ProtocolParameterUpdated(string indexed paramName, uint256 newValue);
    event NetworkRewardsDistributed(uint256 totalAmount, uint256 indexed distributionRound);

    // --- Constructor ---
    constructor(
        address _dainTokenAddress,
        address _protocolFeeRecipient,
        uint256 _minAgentStake,
        uint256 _knowledgeCapsuleFee,
        uint256 _predictionRequestFee,
        uint256 _challengeBond,
        uint256 _attestationRewardReputation,
        uint256 _challengeReputationPenalty,
        uint256 _predictionEvaluationReputation,
        uint256 _minDU_NFTSlotReputation,
        uint256 _agentCooldownPeriod,
        uint256 _capsuleChallengePeriod,
        uint256 _predictionSubmissionPeriod,
        uint256 _predictionEvaluationPeriod
    ) ERC721("DAIN Dynamic Utility NFT", "DU-NFT") Ownable(msg.sender) {
        if (_dainTokenAddress == address(0)) revert DAIN__ZeroAmount();
        if (_protocolFeeRecipient == address(0)) revert DAIN__ZeroAmount();

        DAIN_TOKEN = IERC20(_dainTokenAddress);
        protocolFeeRecipient = _protocolFeeRecipient;

        minAgentStake = _minAgentStake;
        knowledgeCapsuleFee = _knowledgeCapsuleFee;
        predictionRequestFee = _predictionRequestFee;
        challengeBond = _challengeBond;
        attestationRewardReputation = _attestationRewardReputation;
        challengeReputationPenalty = _challengeReputationPenalty;
        predictionEvaluationReputation = _predictionEvaluationReputation;
        minDU_NFTSlotReputation = _minDU_NFTSlotReputation;

        agentCooldownPeriod = _agentCooldownPeriod;
        capsuleChallengePeriod = _capsuleChallengePeriod;
        predictionSubmissionPeriod = _predictionSubmissionPeriod;
        predictionEvaluationPeriod = _predictionEvaluationPeriod;
    }

    // --- I. Protocol Management & Access Control ---

    /// @notice Allows the owner to change the address where protocol fees are collected.
    /// @param _newRecipient The new address for fee collection.
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert DAIN__ZeroAmount();
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    /// @notice Initiates an emergency pause for critical operations, callable by the owner.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Resumes contract operations after a pause, callable by the owner.
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Enables the owner to withdraw accumulated protocol fees of a specific token.
    /// @param _tokenAddress The address of the ERC-20 token to withdraw.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawProtocolFees(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert DAIN__ZeroAmount();
        IERC20 token = IERC20(_tokenAddress);
        if (token.balanceOf(address(this)) < _amount) revert DAIN__NotEnoughFunds();
        require(token.transfer(msg.sender, _amount), "DAIN: Token transfer failed");
    }

    // --- II. AI Agent Lifecycle Management ---

    /// @notice Registers a new AI agent, requiring a stake in DAIN tokens and an identifier for its off-chain model.
    ///         An owner can only register one agent.
    /// @param _metadataURI A URI pointing to the agent's off-chain description, model hash, or API endpoint.
    function registerAIAgent(string calldata _metadataURI) external whenNotPaused {
        if (agentOfOwner[msg.sender] != 0 && agents[agentOfOwner[msg.sender]].status == AgentStatus.Active) revert DAIN__AgentAlreadyActive();
        
        if (DAIN_TOKEN.transferFrom(msg.sender, address(this), minAgentStake) == false) revert DAIN__NotEnoughFunds();

        _agentIdCounter.increment();
        uint256 newAgentId = _agentIdCounter.current();

        agents[newAgentId].owner = msg.sender;
        agents[newAgentId].metadataURI = _metadataURI;
        agents[newAgentId].stakedAmount = minAgentStake;
        agents[newAgentId].status = AgentStatus.Active;
        agents[newAgentId].reputation = 0; // Starts with zero reputation

        agentOfOwner[msg.sender] = newAgentId;

        emit AIAgentRegistered(newAgentId, msg.sender, _metadataURI, minAgentStake);
    }

    /// @notice Allows an agent owner to update their agent's associated off-chain parameters or model hash.
    /// @param _agentId The ID of the agent to update.
    /// @param _newMetadataURI The new URI for the agent's metadata.
    function updateAIAgentParameters(uint256 _agentId, string calldata _newMetadataURI) external whenNotPaused {
        if (agents[_agentId].owner != msg.sender) revert DAIN__NotAgentOwner();
        if (agents[_agentId].status != AgentStatus.Active) revert DAIN__AgentInactive();

        agents[_agentId].metadataURI = _newMetadataURI;
        emit AIAgentUpdated(_agentId, _newMetadataURI);
    }

    /// @notice Allows an agent owner to deactivate their agent, initiating a cooldown period before stake withdrawal.
    /// @param _agentId The ID of the agent to deactivate.
    function deactivateAIAgent(uint256 _agentId) external whenNotPaused {
        if (agents[_agentId].owner != msg.sender) revert DAIN__NotAgentOwner();
        if (agents[_agentId].status != AgentStatus.Active) revert DAIN__AgentInactive();

        agents[_agentId].status = AgentStatus.Cooldown;
        agents[_agentId].lastDeactivationTimestamp = block.timestamp;
        
        agentOfOwner[msg.sender] = 0; // Mark as no longer having an active agent

        emit AIAgentDeactivated(_agentId, msg.sender, block.timestamp);
    }

    /// @notice Allows an agent owner to withdraw their initial stake after the cooldown period has passed.
    ///         Delegated stakes are not included here and must be withdrawn by delegators.
    /// @param _agentId The ID of the agent whose stake to withdraw.
    function withdrawAgentStake(uint256 _agentId) external whenNotPaused {
        if (agents[_agentId].owner != msg.sender) revert DAIN__NotAgentOwner();
        if (agents[_agentId].status != AgentStatus.Cooldown) revert DAIN__AgentNotReadyForWithdrawal();
        if (block.timestamp < agents[_agentId].lastDeactivationTimestamp.add(agentCooldownPeriod)) revert DAIN__AgentNotReadyForWithdrawal();

        uint256 ownerStake = minAgentStake; // Assuming minAgentStake is the owner's initial stake
        if (DAIN_TOKEN.transfer(msg.sender, ownerStake) == false) revert DAIN__NotEnoughFunds();
        
        agents[_agentId].stakedAmount = agents[_agentId].stakedAmount.sub(ownerStake);
        agents[_agentId].status = AgentStatus.Inactive; 

        emit AgentStakeWithdrawn(_agentId, msg.sender, ownerStake);
    }


    /// @notice Enables any user to delegate DAIN tokens to an AI agent, boosting its influence and potential rewards.
    /// @param _agentId The ID of the agent to delegate to.
    /// @param _amount The amount of DAIN tokens to delegate.
    function delegateAgentStake(uint256 _agentId, uint256 _amount) external whenNotPaused {
        if (agents[_agentId].owner == address(0)) revert DAIN__AgentNotFound();
        if (agents[_agentId].status != AgentStatus.Active) revert DAIN__AgentInactive();
        if (_amount == 0) revert DAIN__ZeroAmount();

        if (DAIN_TOKEN.transferFrom(msg.sender, address(this), _amount) == false) revert DAIN__NotEnoughFunds();

        agents[_agentId].stakedAmount = agents[_agentId].stakedAmount.add(_amount);
        agents[_agentId].delegatedStakes[msg.sender] = agents[_agentId].delegatedStakes[msg.sender].add(_amount);

        emit AgentStakeDelegated(_agentId, msg.sender, _amount);
    }

    /// @notice Allows a delegator to withdraw their delegated stake.
    /// @param _agentId The ID of the agent from which to undelegate.
    /// @param _amount The amount of DAIN tokens to undelegate.
    function undelegateAgentStake(uint256 _agentId, uint256 _amount) external whenNotPaused {
        if (agents[_agentId].owner == address(0)) revert DAIN__AgentNotFound();
        if (_amount == 0) revert DAIN__ZeroAmount();
        if (agents[_agentId].delegatedStakes[msg.sender] < _amount) revert DAIN__NotEnoughFunds();

        if (DAIN_TOKEN.transfer(msg.sender, _amount) == false) revert DAIN__NotEnoughFunds();

        agents[_agentId].stakedAmount = agents[_agentId].stakedAmount.sub(_amount);
        agents[_agentId].delegatedStakes[msg.sender] = agents[_agentId].delegatedStakes[msg.sender].sub(_amount);

        emit AgentStakeUndelegated(_agentId, msg.sender, _amount);
    }

    // --- III. Knowledge Capsule & Data Attestation ---

    /// @notice Users submit a hash of off-chain data/information, paying a fee, becoming a 'data provider'.
    /// @param _dataHash A cryptographic hash of the off-chain data.
    /// @param _metadataURI A URI pointing to context or description of the data.
    function submitKnowledgeCapsule(bytes32 _dataHash, string calldata _metadataURI) external payable whenNotPaused {
        if (msg.value < knowledgeCapsuleFee) revert DAIN__NotEnoughFunds();
        
        (bool success, ) = payable(protocolFeeRecipient).call{value: knowledgeCapsuleFee}("");
        if (!success) revert DAIN__NotEnoughFunds();

        _capsuleIdCounter.increment();
        uint256 newCapsuleId = _capsuleIdCounter.current();

        knowledgeCapsules[newCapsuleId] = KnowledgeCapsule({
            submitter: msg.sender,
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            submissionTimestamp: block.timestamp,
            status: CapsuleStatus.Active,
            lastChallenger: address(0),
            challengeBondStaked: 0,
            attestationCount: 0
        });

        emit KnowledgeCapsuleSubmitted(newCapsuleId, msg.sender, _dataHash, _metadataURI);
    }

    /// @notice Users can attest to the validity or quality of a submitted knowledge capsule, earning reputation.
    /// @param _capsuleId The ID of the knowledge capsule to attest to.
    function attestToKnowledgeCapsule(uint256 _capsuleId) external whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        if (capsule.submitter == address(0)) revert DAIN__KnowledgeCapsuleNotFound();
        if (capsule.status != CapsuleStatus.Active) revert DAIN__InvalidAttestation();
        if (capsule.hasAttested[msg.sender]) revert DAIN__AlreadyAttested();
        
        if (capsule.submitter == msg.sender) revert DAIN__SelfAttestationDenied();

        capsule.attestationCount = capsule.attestationCount.add(1);
        capsule.hasAttested[msg.sender] = true;

        userReputation[msg.sender] = userReputation[msg.sender].add(attestationRewardReputation);
        emit UserReputationUpdated(msg.sender, userReputation[msg.sender]);
        emit KnowledgeCapsuleAttested(_capsuleId, msg.sender, userReputation[msg.sender]);
    }

    /// @notice Initiates a dispute over a knowledge capsule's validity, requiring a challenge bond.
    /// @param _capsuleId The ID of the knowledge capsule to challenge.
    function challengeKnowledgeCapsule(uint256 _capsuleId) external whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        if (capsule.submitter == address(0)) revert DAIN__KnowledgeCapsuleNotFound();
        if (capsule.status != CapsuleStatus.Active) revert DAIN__InvalidAttestation();
        
        // Ensure challenge is within the valid period
        if (block.timestamp < capsule.submissionTimestamp) revert DAIN__ChallengePeriodNotStarted(); // Prevents challenges before submission (edge case)
        if (block.timestamp > capsule.submissionTimestamp.add(capsuleChallengePeriod)) revert DAIN__ChallengePeriodEnded();

        if (DAIN_TOKEN.transferFrom(msg.sender, address(this), challengeBond) == false) revert DAIN__NotEnoughFunds();

        capsule.status = CapsuleStatus.Challenged;
        capsule.lastChallenger = msg.sender;
        capsule.challengeBondStaked = challengeBond;

        emit KnowledgeCapsuleChallenged(_capsuleId, msg.sender, challengeBond);
    }

    /// @notice Owner/DAO resolves a challenged capsule, distributing or burning bonds and adjusting reputation.
    /// @param _capsuleId The ID of the challenged capsule.
    /// @param _isValid True if the capsule is deemed valid, false otherwise.
    function resolveKnowledgeCapsuleDispute(uint256 _capsuleId, bool _isValid) external onlyOwner whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        if (capsule.submitter == address(0)) revert DAIN__KnowledgeCapsuleNotFound();
        if (capsule.status != CapsuleStatus.Challenged) revert DAIN__InvalidAttestation();
        if (capsule.lastChallenger == address(0)) revert DAIN__NoChallengerRecorded();

        address challenger = capsule.lastChallenger;
        uint256 bondAmount = capsule.challengeBondStaked;

        if (_isValid) {
            // Capsule is valid: Challenger loses bond, submitter gains reputation.
            if (DAIN_TOKEN.transfer(protocolFeeRecipient, bondAmount) == false) revert DAIN__NotEnoughFunds();
            
            userReputation[challenger] = userReputation[challenger].sub(challengeReputationPenalty);
            userReputation[capsule.submitter] = userReputation[capsule.submitter].add(attestationRewardReputation.mul(2));
            capsule.status = CapsuleStatus.Validated;
        } else {
            // Capsule is invalid: Challenger gets bond back, submitter loses reputation.
            if (DAIN_TOKEN.transfer(challenger, bondAmount) == false) revert DAIN__NotEnoughFunds();
            userReputation[challenger] = userReputation[challenger].add(challengeReputationPenalty.mul(2));
            userReputation[capsule.submitter] = userReputation[capsule.submitter].sub(attestationRewardReputation.mul(2));
            capsule.status = CapsuleStatus.Invalidated;
        }
        
        // Reset challenger data regardless of outcome
        capsule.lastChallenger = address(0); 
        capsule.challengeBondStaked = 0;

        emit UserReputationUpdated(challenger, userReputation[challenger]);
        emit UserReputationUpdated(capsule.submitter, userReputation[capsule.submitter]);
        emit KnowledgeCapsuleResolved(_capsuleId, capsule.status, msg.sender, challenger, capsule.submitter);
    }
    
    // --- IV. Dynamic Utility NFTs (DU-NFTs) ---
    // DU-NFTs are standard ERC721 but their metadata can be updated (evolved) based on reputation.

    /// @notice Mints a new DU-NFT, representing a user's standing or specific role within the network.
    /// @param _initialURI The initial metadata URI for the NFT.
    function mintDU_NFT(string calldata _initialURI) external whenNotPaused {
        if (userReputation[msg.sender] < minDU_NFTSlotReputation) revert DAIN__InsufficientReputation();

        _duNftIdCounter.increment();
        uint256 newTokenId = _duNftIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _initialURI);

        duNftData[newTokenId] = DU_NFTData({
            owner: msg.sender,
            associatedReputation: userReputation[msg.sender],
            currentURI: _initialURI
        });

        emit DU_NFTMinted(newTokenId, msg.sender, _initialURI);
    }

    /// @notice An internal or owner-triggered function to update a DU-NFT's metadata based on associated reputation or network state.
    ///         Callable by the contract owner, the NFT owner, or an approved operator.
    /// @param _tokenId The ID of the DU-NFT to evolve.
    /// @param _newURI The new metadata URI for the NFT.
    function evolveDU_NFT(uint256 _tokenId, string calldata _newURI) public whenNotPaused {
        address tokenOwner = ownerOf(_tokenId);
        if (tokenOwner == address(0)) revert DAIN__DU_NFTNotFound();
        
        // Access control: Only contract owner, NFT owner, or approved operator.
        require(msg.sender == owner() || msg.sender == tokenOwner || getApproved(_tokenId) == msg.sender || isApprovedForAll(tokenOwner, msg.sender), "DAIN: Not owner or approved for NFT modification");

        duNftData[_tokenId].currentURI = _newURI;
        duNftData[_tokenId].associatedReputation = userReputation[tokenOwner]; // Update snapshot of reputation
        _setTokenURI(_tokenId, _newURI);

        emit DU_NFTEvolved(_tokenId, _newURI, duNftData[_tokenId].associatedReputation);
    }
    
    /// @notice Allows a user to burn their DU-NFT.
    /// @param _tokenId The ID of the DU-NFT to burn.
    function burnDU_NFT(uint256 _tokenId) external whenNotPaused {
        if (ownerOf(_tokenId) != msg.sender) revert DAIN__Unauthorized();
        
        _burn(_tokenId);
        delete duNftData[_tokenId]; // Remove associated data

        emit DU_NFTBurned(_tokenId, msg.sender);
    }

    // --- V. Decentralized Inference & Prediction Market ---

    /// @notice Users request a prediction on a specific topic, paying a fee and defining rewards.
    /// @param _requestMetadataURI A URI pointing to the detailed request, data for prediction.
    /// @param _specificAgentId Optional: If 0, any active agent can submit. If > 0, only that agent.
    /// @param _agentReward Amount of DAIN tokens to reward the winning agent.
    /// @param _evaluatorReward Amount of DAIN tokens to reward evaluators (added to general pool).
    function requestPrediction(
        string calldata _requestMetadataURI,
        uint256 _specificAgentId,
        uint256 _agentReward,
        uint256 _evaluatorReward
    ) external payable whenNotPaused {
        if (msg.value < predictionRequestFee) revert DAIN__NotEnoughFunds();
        if (_agentReward == 0) revert DAIN__ZeroAmount();
        if (_evaluatorReward == 0) revert DAIN__ZeroAmount();

        // Transfer native currency fee to protocol fee recipient
        (bool success, ) = payable(protocolFeeRecipient).call{value: predictionRequestFee}("");
        if (!success) revert DAIN__NotEnoughFunds();

        // Transfer reward tokens from requester to contract
        if (DAIN_TOKEN.transferFrom(msg.sender, address(this), _agentReward.add(_evaluatorReward)) == false) revert DAIN__NotEnoughFunds();

        _predictionIdCounter.increment();
        uint256 newPredictionId = _predictionIdCounter.current();

        predictionRequests[newPredictionId] = PredictionRequest({
            requester: msg.sender,
            requestMetadataURI: _requestMetadataURI,
            requestTimestamp: block.timestamp,
            feePaid: predictionRequestFee,
            status: PredictionStatus.Open,
            winningAgentId: _specificAgentId, 
            winningAgentReward: _agentReward,
            totalEvaluatorReward: _evaluatorReward,
            submissionDeadline: block.timestamp.add(predictionSubmissionPeriod),
            evaluationDeadline: 0, // Set after submission period (or after first submission for simplicity here)
            submittedAgentIds: new uint256[](0)
        });

        emit PredictionRequested(newPredictionId, msg.sender, _requestMetadataURI, predictionRequestFee, _agentReward, _evaluatorReward);
    }

    /// @notice An AI agent submits its prediction result for an open request.
    /// @param _predictionId The ID of the prediction request.
    /// @param _agentId The ID of the submitting agent.
    /// @param _resultHash A hash of the prediction result (off-chain).
    /// @param _predictionMetadataURI A URI pointing to details of the prediction.
    function submitPredictionResult(
        uint256 _predictionId,
        uint256 _agentId,
        bytes32 _resultHash,
        string calldata _predictionMetadataURI
    ) external whenNotPaused {
        PredictionRequest storage request = predictionRequests[_predictionId];
        if (request.requester == address(0)) revert DAIN__PredictionNotFound();
        if (request.status != PredictionStatus.Open) revert DAIN__PredictionNotOpen();
        if (block.timestamp > request.submissionDeadline) revert DAIN__ChallengePeriodEnded(); // Submission period ended

        if (agents[_agentId].owner == address(0)) revert DAIN__AgentNotFound();
        if (agents[_agentId].status != AgentStatus.Active) revert DAIN__AgentInactive();
        if (agents[_agentId].owner != msg.sender) revert DAIN__NotAgentOwner(); // Only agent owner can submit

        // If a specific agent was requested, ensure it's that agent
        if (request.winningAgentId != 0 && request.winningAgentId != _agentId) revert DAIN__InvalidAgentForPrediction();

        // Check if agent already submitted for this prediction
        if (predictionSubmissions[_predictionId][_agentId].submissionTimestamp != 0) revert DAIN__PredictionAlreadySubmitted();

        predictionSubmissions[_predictionId][_agentId] = AgentPrediction({
            agentId: _agentId,
            predictionResultHash: _resultHash,
            predictionMetadataURI: _predictionMetadataURI,
            submissionTimestamp: block.timestamp,
            totalEvaluationScore: 0,
            evaluatorCount: 0
        });

        request.submittedAgentIds.push(_agentId);
        // If this is the first submission, or if we define evaluation window starts after submission period
        if (request.evaluationDeadline == 0) { // Can be set after submission period ends for a collective evaluation phase
             request.evaluationDeadline = request.submissionDeadline.add(predictionEvaluationPeriod);
        }

        emit PredictionResultSubmitted(_predictionId, _agentId, _resultHash, _predictionMetadataURI);
    }

    /// @notice Users (evaluators) assess the accuracy/quality of a submitted prediction, earning reputation.
    /// @param _predictionId The ID of the prediction request.
    /// @param _agentId The ID of the agent whose prediction is being evaluated.
    /// @param _score An integer score (e.g., 1-10) for the prediction's accuracy.
    function evaluatePredictionResult(uint256 _predictionId, uint256 _agentId, uint256 _score) external whenNotPaused {
        PredictionRequest storage request = predictionRequests[_predictionId];
        if (request.requester == address(0)) revert DAIN__PredictionNotFound();
        if (request.status != PredictionStatus.Open) revert DAIN__PredictionNotOpen(); // Must be in open for evaluation.
        if (block.timestamp <= request.submissionDeadline) revert DAIN__PredictionNotReadyForEvaluation(); // Must be after submission period.
        if (block.timestamp > request.evaluationDeadline) revert DAIN__EvaluationPeriodNotOver();

        AgentPrediction storage agentPrediction = predictionSubmissions[_predictionId][_agentId];
        if (agentPrediction.submissionTimestamp == 0) revert DAIN__PredictionNotFound(); // Agent didn't submit for this prediction
        if (agentPrediction.hasEvaluated[msg.sender]) revert DAIN__AlreadyEvaluatedPrediction();
        
        if (agents[_agentId].owner == msg.sender) revert DAIN__AgentCannotEvaluateOwnPrediction();

        agentPrediction.totalEvaluationScore = agentPrediction.totalEvaluationScore.add(_score);
        agentPrediction.evaluatorCount = agentPrediction.evaluatorCount.add(1);
        agentPrediction.hasEvaluated[msg.sender] = true;

        userReputation[msg.sender] = userReputation[msg.sender].add(predictionEvaluationReputation);
        emit UserReputationUpdated(msg.sender, userReputation[msg.sender]);
        emit PredictionResultEvaluated(_predictionId, _agentId, msg.sender, _score, userReputation[msg.sender]);
    }

    /// @notice Finalizes a prediction market after evaluation period and sets the winning agent.
    /// @param _predictionId The ID of the prediction request.
    function finalizePrediction(uint256 _predictionId) external whenNotPaused {
        PredictionRequest storage request = predictionRequests[_predictionId];
        if (request.requester == address(0)) revert DAIN__PredictionNotFound();
        if (request.status != PredictionStatus.Open) revert DAIN__PredictionNotOpen();
        if (block.timestamp <= request.evaluationDeadline) revert DAIN__EvaluationPeriodNotOver();

        request.status = PredictionStatus.Finalized;

        uint256 highestScore = 0;
        uint256 winningAgentId = 0;
        
        for (uint i = 0; i < request.submittedAgentIds.length; i++) {
            uint256 agentId = request.submittedAgentIds[i];
            AgentPrediction storage agentPrediction = predictionSubmissions[_predictionId][agentId];
            
            // Winning agent must have at least one evaluation and the highest total score
            if (agentPrediction.evaluatorCount > 0 && agentPrediction.totalEvaluationScore > highestScore) {
                highestScore = agentPrediction.totalEvaluationScore;
                winningAgentId = agentId;
            }
        }

        request.winningAgentId = winningAgentId; // Will be 0 if no winning agent found
        
        // Winning agent gains reputation (proportionally to score/reward)
        if (winningAgentId != 0) {
            agents[winningAgentId].reputation = agents[winningAgentId].reputation.add(request.winningAgentReward.div(1e18).mul(100)); // Scaled for DAIN token value
            emit AgentReputationUpdated(winningAgentId, agents[winningAgentId].reputation);
        }

        // Evaluator rewards (totalEvaluatorReward) are handled through the general distributeNetworkRewards,
        // as their individual evaluations give them reputation points directly.

        emit PredictionFinalized(_predictionId, winningAgentId, highestScore);
    }

    /// @notice Allows the winning AI agent to claim their DAIN token rewards.
    /// @param _predictionId The ID of the prediction request.
    function claimPredictionReward(uint256 _predictionId) external whenNotPaused {
        PredictionRequest storage request = predictionRequests[_predictionId];
        if (request.requester == address(0)) revert DAIN__PredictionNotFound();
        if (request.status != PredictionStatus.Finalized) revert DAIN__PredictionNotFinalized();
        if (request.winningAgentId == 0) revert DAIN__NoRewardsToClaim();
        if (agents[request.winningAgentId].owner != msg.sender) revert DAIN__Unauthorized();

        uint256 rewardAmount = request.winningAgentReward;
        if (rewardAmount == 0) revert DAIN__NoRewardsToClaim();
        
        // Prevent double claiming
        request.winningAgentReward = 0; 
        
        if (DAIN_TOKEN.transfer(msg.sender, rewardAmount) == false) revert DAIN__NotEnoughFunds();
        
        emit PredictionRewardsClaimed(_predictionId, request.winningAgentId, rewardAmount);
    }


    // --- VI. Reputation & Adaptive Tokenomics ---

    /// @notice Retrieves the current reputation score of a specific AI agent.
    /// @param _agentId The ID of the AI agent.
    /// @return The reputation score of the agent.
    function getAgentReputation(uint256 _agentId) external view returns (uint256) {
        if (agents[_agentId].owner == address(0)) revert DAIN__AgentNotFound();
        return agents[_agentId].reputation;
    }

    /// @notice Retrieves the current reputation score of a specific user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Owner/DAO distributes periodic DAIN token rewards to top contributors (agents, data providers, evaluators) based on reputation.
    ///         This function allows flexible reward distribution to specific addresses and agent owners.
    /// @param _totalRewardAmount The total amount of DAIN tokens to distribute in this round.
    /// @param _contributorAddresses An array of addresses of individual contributors (data providers, evaluators) to reward.
    /// @param _agentIds An array of agent IDs whose owners will receive rewards.
    function distributeNetworkRewards(uint256 _totalRewardAmount, address[] calldata _contributorAddresses, uint256[] calldata _agentIds) external onlyOwner whenNotPaused {
        if (_totalRewardAmount == 0) revert DAIN__ZeroAmount();
        if (DAIN_TOKEN.balanceOf(address(this)) < _totalRewardAmount) revert DAIN__NotEnoughFunds();

        uint256 totalReputation = 0;
        // Calculate total reputation for specified contributors and agents
        for (uint i = 0; i < _contributorAddresses.length; i++) {
            totalReputation = totalReputation.add(userReputation[_contributorAddresses[i]]);
        }
        for (uint i = 0; i < _agentIds.length; i++) {
            totalReputation = totalReputation.add(agents[_agentIds[i]].reputation);
        }

        if (totalReputation == 0) {
            // No reputation among specified, potentially send rewards to protocol fees or burn.
            if (DAIN_TOKEN.transfer(protocolFeeRecipient, _totalRewardAmount) == false) revert DAIN__NotEnoughFunds();
            return;
        }

        uint256 rewardFactor = _totalRewardAmount.div(totalReputation); // Reward per reputation point

        // Distribute to individual users
        for (uint i = 0; i < _contributorAddresses.length; i++) {
            address contributor = _contributorAddresses[i];
            uint256 individualReward = userReputation[contributor].mul(rewardFactor);
            if (individualReward > 0) {
                if (DAIN_TOKEN.transfer(contributor, individualReward) == false) revert DAIN__NotEnoughFunds();
            }
        }

        // Distribute to agents (to their owners)
        for (uint i = 0; i < _agentIds.length; i++) {
            uint256 agentId = _agentIds[i];
            uint256 agentReward = agents[agentId].reputation.mul(rewardFactor);
            if (agentReward > 0) {
                if (DAIN_TOKEN.transfer(agents[agentId].owner, agentReward) == false) revert DAIN__NotEnoughFunds();
            }
        }

        emit NetworkRewardsDistributed(_totalRewardAmount, block.timestamp);
    }

    /// @notice Allows the owner/DAO to adjust various mutable protocol parameters (e.g., fee rates, staking minimums).
    /// @param _paramName The string name of the parameter to update (e.g., "minAgentStake").
    /// @param _newValue The new value for the parameter.
    function updateProtocolParameter(string calldata _paramName, uint256 _newValue) external onlyOwner whenNotPaused {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        if (paramHash == keccak256(abi.encodePacked("minAgentStake"))) {
            minAgentStake = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("knowledgeCapsuleFee"))) {
            knowledgeCapsuleFee = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("predictionRequestFee"))) {
            predictionRequestFee = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("challengeBond"))) {
            challengeBond = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("attestationRewardReputation"))) {
            attestationRewardReputation = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("challengeReputationPenalty"))) {
            challengeReputationPenalty = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("predictionEvaluationReputation"))) {
            predictionEvaluationReputation = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minDU_NFTSlotReputation"))) {
            minDU_NFTSlotReputation = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("agentCooldownPeriod"))) {
            agentCooldownPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("capsuleChallengePeriod"))) {
            capsuleChallengePeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("predictionSubmissionPeriod"))) {
            predictionSubmissionPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("predictionEvaluationPeriod"))) {
            predictionEvaluationPeriod = _newValue;
        } else {
            revert DAIN__UnknownParameter();
        }
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }
}
```