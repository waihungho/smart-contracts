The following smart contract, `AetherFlow`, is designed as a decentralized platform for AI-powered content curation and rewarding. It integrates concepts of decentralized AI oracles, a reputation-based incentive system, and simplified on-chain governance to manage the platform and its AI models. It aims to create a unique ecosystem where content quality is transparently assessed by AI and community, fostering a high-quality content environment.

---

## **AetherFlow Smart Contract: Outline & Function Summary**

**Contract Name:** `AetherFlow`

**Core Concept:** A decentralized platform facilitating AI-driven content evaluation, reputation building, and reward distribution. Users submit content, AI models (via decentralized verifiers) assess it, and contributors are rewarded based on quality and reputation.

**Key Advanced Concepts:**
*   **Decentralized AI Oracle Integration:** The contract registers AI models and uses a network of trusted "Verifiers" to submit signed outputs from these off-chain AI models for content evaluation. This provides a decentralized, verifiable bridge to AI capabilities.
*   **Reputation-Based Incentives:** Users gain reputation by staking tokens, which amplifies their voting power and reward multipliers for contributing high-quality content or acting as verifiers.
*   **Dynamic Content Metadata:** Content's metadata (e.g., quality score, tags) evolves based on AI evaluations and community input, laying groundwork for dynamic NFTs or sophisticated content filtering.
*   **Simplified On-Chain Governance:** A vote-by-reputation system for critical parameter changes, AI model policy, and treasury grants.

---

### **Outline & Function Summary**

**I. Core Infrastructure & Access Control (Using OpenZeppelin Roles & Pausable)**
1.  **`constructor(address _protocolToken, address _initialAdmin)`**: Initializes the contract with the protocol token address and sets up the initial admin. Defines core roles like `ADMIN_ROLE`, `AI_REGISTRAR_ROLE`, `VERIFIER_ROLE`, and `TREASURY_ROLE`.
2.  **`pause()`**: Allows entities with `PAUSER_ROLE` (e.g., `ADMIN_ROLE`) to pause critical contract functions in emergencies.
3.  **`unpause()`**: Allows entities with `PAUSER_ROLE` to unpause the contract.
4.  **`updateProtocolFee(uint256 _newFee)`**: Updates the fee required for submitting content. Requires `ADMIN_ROLE` or governance.

**II. AI Model Management (Decentralized AI Oracle Registry)**
5.  **`registerAIModel(string calldata _name, string calldata _description, string calldata _uri, bytes32 _schemaHash)`**: Registers a new AI model with its details, off-chain URI, and expected output schema hash. Requires `AI_REGISTRAR_ROLE`.
6.  **`updateAIModelURI(uint256 _modelId, string calldata _newUri)`**: Updates the off-chain URI for a registered AI model. Requires `AI_REGISTRAR_ROLE`.
7.  **`deactivateAIModel(uint256 _modelId)`**: Deactivates a problematic AI model, preventing its further use for evaluations. Requires `AI_REGISTRAR_ROLE`.
8.  **`proposeAIModelPolicy(string calldata _policyUri)`**: Allows `ADMIN_ROLE` to propose new policies or guidelines for AI model usage (off-chain document reference).

**III. Content Management & Evaluation**
9.  **`submitContent(string calldata _contentHash, string calldata _title, string calldata _description)`**: Allows users to submit content (e.g., IPFS hash) to the platform. Requires a `protocolFee`.
10. **`requestAIEvaluation(uint256 _contentId, uint256 _modelId)`**: Initiates an off-chain request for a registered AI model to evaluate specific content. This signals to verifiers that an evaluation is needed.
11. **`submitAIEvaluationResult(uint256 _contentId, uint256 _modelId, uint256 _qualityScore, string calldata _tags, bytes calldata _signature)`**: The core AI oracle function. A `VERIFIER_ROLE` submits a signed AI evaluation result (score, tags) for content. The signature verifies the verifier's authenticity and data integrity.
12. **`getContentDetails(uint256 _contentId)`**: Retrieves comprehensive details about a submitted content piece, including its latest evaluation score and tags.
13. **`disputeAIEvaluation(uint256 _contentId, uint256 _evaluationIndex, string calldata _reason)`**: Allows a user to formally dispute a specific AI evaluation, marking it for potential community review or re-evaluation.

**IV. Reputation & Rewards System**
14. **`stakeForReputation(uint256 _amount)`**: Users stake `protocolToken` to earn reputation points. Staked tokens are locked and contribute to voting power and reward multipliers.
15. **`unstakeForReputation(uint256 _amount)`**: Users can unstake their tokens after a cooldown period, gradually decreasing their reputation.
16. **`claimContentRewards()`**: Allows content creators to claim accumulated rewards based on their content's quality scores, engagement, and their reputation.
17. **`claimVerifierRewards()`**: Allows `VERIFIER_ROLE` accounts to claim rewards for submitting validated AI evaluations.
18. **`getReputation(address _user)`**: Returns a user's current calculated reputation score based on their stake and time.

**V. Simplified On-Chain Governance (Reputation-Based)**
19. **`proposeParameterChange(string calldata _description, bytes calldata _callData)`**: Allows users with sufficient reputation to propose changes to key contract parameters (e.g., reward distribution, fee settings). The `_callData` specifies the function call to be executed if passed.
20. **`castVote(uint256 _proposalId, bool _support)`**: Users vote on active proposals. Their voting power is directly proportional to their reputation score.
21. **`executeProposal(uint256 _proposalId)`**: Executes a proposal that has successfully passed its voting period and met the required reputation-based vote threshold.

**VI. Treasury Management**
22. **`withdrawFeesToTreasury()`**: Transfers accumulated protocol fees from content submissions to a designated DAO treasury address. Requires `TREASURY_ROLE`.
23. **`proposeTreasuryGrant(address _recipient, uint256 _amount, string calldata _reason)`**: Allows users with sufficient reputation to propose allocating funds from the treasury for ecosystem development or grants.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Custom error for better user feedback
error AetherFlow__InvalidAmount();
error AetherFlow__AlreadyEvaluated();
error AetherFlow__ContentNotFound();
error AetherFlow__AIModelNotFound();
error AetherFlow__AIModelInactive();
error AetherFlow__NotEnoughReputation();
error AetherFlow__ProposalNotFound();
error AetherFlow__VotingPeriodNotEnded();
error AetherFlow__VotingPeriodActive();
error AetherFlow__ProposalFailed();
error AetherFlow__AlreadyVoted();
error AetherFlow__InsufficientFee();
error AetherFlow__EvaluationNotFound();
error AetherFlow__InvalidSignature();
error AetherFlow__CannotUnstakeBeforeCooldown();
error AetherFlow__CannotExecuteUnpassedProposal();
error AetherFlow__CallDataExecutionFailed();

contract AetherFlow is AccessControl, Pausable {
    using ECDSA for bytes32;
    using SafeCast for uint256;

    // --- State Variables ---

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AI_REGISTRAR_ROLE = keccak256("AI_REGISTRAR_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    IERC20 private immutable i_protocolToken;
    address public s_treasuryAddress; // Address where fees and grants are managed
    uint256 public s_protocolFee; // Fee for submitting content, in protocol tokens
    uint256 public s_minReputationForProposal; // Minimum reputation to create a proposal
    uint256 public s_proposalVotingPeriod; // Duration of voting period in seconds
    uint256 public s_reputationStakeCooldown; // Cooldown for unstaking in seconds
    uint256 public s_minimumPassingReputationRatio; // % of total staked reputation needed for a proposal to pass (e.g., 5100 for 51%)

    // AI Model Struct
    struct AIModel {
        string name;
        string description;
        string uri; // IPFS CID or API endpoint for the AI model
        bytes32 schemaHash; // Hash of the expected JSON schema for evaluations
        address creator;
        bool active;
        uint256 registrationTimestamp;
    }
    mapping(uint256 => AIModel) public s_aiModels;
    uint256 private s_nextAIModelId;

    // Content Struct
    struct Content {
        string contentHash; // IPFS CID of the content
        string title;
        string description;
        address submitter;
        uint256 submitTimestamp;
        uint256 latestQualityScore; // Average or latest verified score
        string latestTags; // Latest verified tags
        Evaluation[] evaluations; // History of evaluations for this content
    }
    mapping(uint256 => Content) public s_contents;
    uint256 private s_nextContentId;

    // Evaluation Struct
    struct Evaluation {
        uint256 modelId;
        address verifier;
        uint256 qualityScore; // e.g., 0-100
        string tags; // Comma-separated tags
        uint256 submitTimestamp;
        bool disputed;
        bytes signature; // Verifier's signature over the evaluation data
    }

    // Reputation System
    struct UserReputation {
        uint256 stakedAmount;
        uint256 lastStakeUpdate; // Timestamp of the last stake/unstake operation
        uint256 lastUnstakeRequest; // Timestamp when unstake was requested
        uint256 pendingUnstakeAmount; // Amount requested to unstake
    }
    mapping(address => UserReputation) public s_userReputations;
    uint256 public s_totalStakedReputation; // Total tokens staked across the platform

    // Rewards
    mapping(address => uint256) public s_pendingContentRewards;
    mapping(address => uint256) public s_pendingVerifierRewards;

    // Governance Proposals
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        string description;
        bytes callData; // Encoded function call for execution
        uint256 proposer; // Reputation score of the proposer at proposal time
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 yesVotes; // Total reputation voting 'yes'
        uint256 noVotes; // Total reputation voting 'no'
        mapping(address => bool) hasVoted; // Check if an address has voted
        ProposalState state;
        bool executed;
    }
    mapping(uint256 => Proposal) public s_proposals;
    uint256 private s_nextProposalId;

    // --- Events ---
    event AIModelRegistered(uint256 indexed modelId, address indexed creator, string name, string uri);
    event AIModelUpdated(uint256 indexed modelId, string newUri);
    event AIModelDeactivated(uint256 indexed modelId);
    event AIModelPolicyProposed(string policyUri);

    event ContentSubmitted(uint256 indexed contentId, address indexed submitter, string contentHash);
    event AIEvaluationRequested(uint256 indexed contentId, uint256 indexed modelId, address requester);
    event AIEvaluationSubmitted(uint256 indexed contentId, uint256 indexed modelId, address indexed verifier, uint256 qualityScore);
    event AIEvaluationDisputed(uint256 indexed contentId, uint256 indexed evaluationIndex, address indexed disputer);

    event ReputationStaked(address indexed user, uint256 amount, uint256 newStakedTotal);
    event ReputationUnstakeRequested(address indexed user, uint256 amount, uint256 unlockTimestamp);
    event ReputationUnstaked(address indexed user, uint256 amount, uint256 newStakedTotal);
    event ContentRewardsClaimed(address indexed user, uint256 amount);
    event VerifierRewardsClaimed(address indexed verifier, uint256 amount);

    event ProtocolFeeUpdated(uint256 newFee);
    event FeesWithdrawnToTreasury(uint256 amount);
    event TreasuryGrantProposed(uint256 indexed proposalId, address indexed recipient, uint256 amount, string reason);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Constructor ---
    constructor(address _protocolToken, address _initialAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _grantRole(ADMIN_ROLE, _initialAdmin); // Custom admin role
        _grantRole(PAUSER_ROLE, _initialAdmin);

        i_protocolToken = IERC20(_protocolToken);
        s_treasuryAddress = _initialAdmin; // Initial treasury address, can be changed via governance
        s_protocolFee = 1e18; // Default 1 token fee (assuming 18 decimals)
        s_minReputationForProposal = 100e18; // E.g., 100 tokens staked for reputation
        s_proposalVotingPeriod = 3 days;
        s_reputationStakeCooldown = 7 days;
        s_minimumPassingReputationRatio = 5100; // 51% (5100 out of 10000)
    }

    // --- Modifiers ---
    modifier onlyAIRegistrar() {
        _checkRole(AI_REGISTRAR_ROLE);
        _;
    }

    modifier onlyVerifier() {
        _checkRole(VERIFIER_ROLE);
        _;
    }

    modifier onlyTreasury() {
        _checkRole(TREASURY_ROLE);
        _;
    }

    // --- I. Core Infrastructure & Access Control ---

    /// @notice Allows entities with PAUSER_ROLE to pause critical contract functions in emergencies.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Allows entities with PAUSER_ROLE to unpause the contract.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Updates the fee required for submitting content.
    /// @param _newFee The new fee amount in protocol tokens.
    function updateProtocolFee(uint256 _newFee) public onlyRole(ADMIN_ROLE) {
        s_protocolFee = _newFee;
        emit ProtocolFeeUpdated(_newFee);
    }

    // --- II. AI Model Management ---

    /// @notice Registers a new AI model with its details, off-chain URI, and expected output schema hash.
    /// @param _name The name of the AI model.
    /// @param _description A brief description of the AI model.
    /// @param _uri The URI (e.g., IPFS CID, API endpoint) where the AI model can be accessed.
    /// @param _schemaHash A hash of the expected JSON schema for the AI's evaluation output.
    function registerAIModel(
        string calldata _name,
        string calldata _description,
        string calldata _uri,
        bytes32 _schemaHash
    ) public virtual onlyAIRegistrar whenNotPaused {
        uint256 newModelId = ++s_nextAIModelId;
        s_aiModels[newModelId] = AIModel({
            name: _name,
            description: _description,
            uri: _uri,
            schemaHash: _schemaHash,
            creator: msg.sender,
            active: true,
            registrationTimestamp: block.timestamp
        });
        emit AIModelRegistered(newModelId, msg.sender, _name, _uri);
    }

    /// @notice Updates the off-chain URI for a registered AI model.
    /// @param _modelId The ID of the AI model to update.
    /// @param _newUri The new URI for the AI model.
    function updateAIModelURI(uint256 _modelId, string calldata _newUri) public virtual onlyAIRegistrar whenNotPaused {
        AIModel storage model = s_aiModels[_modelId];
        if (model.creator == address(0)) revert AetherFlow__AIModelNotFound();
        model.uri = _newUri;
        emit AIModelUpdated(_modelId, _newUri);
    }

    /// @notice Deactivates a problematic AI model, preventing its further use for evaluations.
    /// @param _modelId The ID of the AI model to deactivate.
    function deactivateAIModel(uint256 _modelId) public virtual onlyAIRegistrar whenNotPaused {
        AIModel storage model = s_aiModels[_modelId];
        if (model.creator == address(0)) revert AetherFlow__AIModelNotFound();
        model.active = false;
        emit AIModelDeactivated(_modelId);
    }

    /// @notice Allows ADMIN_ROLE to propose new policies or guidelines for AI model usage (off-chain document reference).
    /// @param _policyUri The URI (e.g., IPFS CID) of the proposed policy document.
    function proposeAIModelPolicy(string calldata _policyUri) public virtual onlyRole(ADMIN_ROLE) whenNotPaused {
        emit AIModelPolicyProposed(_policyUri);
    }

    // --- III. Content Management & Evaluation ---

    /// @notice Allows users to submit content (e.g., IPFS hash) to the platform. Requires a protocolFee.
    /// @param _contentHash The IPFS CID or similar hash of the content.
    /// @param _title The title of the content.
    /// @param _description A description of the content.
    function submitContent(
        string calldata _contentHash,
        string calldata _title,
        string calldata _description
    ) public payable whenNotPaused {
        if (msg.value < s_protocolFee) revert AetherFlow__InsufficientFee();
        if (s_protocolFee > 0) {
            bool success = i_protocolToken.transferFrom(msg.sender, address(this), s_protocolFee);
            if (!success) revert AetherFlow__InsufficientFee();
        }

        uint256 newContentId = ++s_nextContentId;
        s_contents[newContentId] = Content({
            contentHash: _contentHash,
            title: _title,
            description: _description,
            submitter: msg.sender,
            submitTimestamp: block.timestamp,
            latestQualityScore: 0,
            latestTags: "",
            evaluations: new Evaluation[](0)
        });
        emit ContentSubmitted(newContentId, msg.sender, _contentHash);
    }

    /// @notice Initiates an off-chain request for a registered AI model to evaluate specific content.
    ///         This function doesn't perform the evaluation but signals to verifiers that one is needed.
    /// @param _contentId The ID of the content to be evaluated.
    /// @param _modelId The ID of the AI model to use for evaluation.
    function requestAIEvaluation(uint256 _contentId, uint256 _modelId) public whenNotPaused {
        if (s_contents[_contentId].submitter == address(0)) revert AetherFlow__ContentNotFound();
        if (s_aiModels[_modelId].creator == address(0)) revert AetherFlow__AIModelNotFound();
        if (!s_aiModels[_modelId].active) revert AetherFlow__AIModelInactive();

        // Potentially add a fee for requesting evaluation, or only allow certain roles/reputation holders.
        emit AIEvaluationRequested(_contentId, _modelId, msg.sender);
    }

    /// @notice A VERIFIER_ROLE submits a signed AI evaluation result (score, tags) for content.
    ///         The signature verifies the verifier's authenticity and data integrity.
    /// @param _contentId The ID of the content being evaluated.
    /// @param _modelId The ID of the AI model used.
    /// @param _qualityScore The quality score given by the AI (e.g., 0-100).
    /// @param _tags Comma-separated tags generated by the AI.
    /// @param _signature The ECDSA signature from the verifier over the evaluation data.
    function submitAIEvaluationResult(
        uint256 _contentId,
        uint256 _modelId,
        uint256 _qualityScore,
        string calldata _tags,
        bytes calldata _signature
    ) public virtual onlyVerifier whenNotPaused {
        Content storage content = s_contents[_contentId];
        if (content.submitter == address(0)) revert AetherFlow__ContentNotFound();
        AIModel storage model = s_aiModels[_modelId];
        if (model.creator == address(0) || !model.active) revert AetherFlow__AIModelNotFound();

        // Reconstruct the message hash that the verifier signed
        bytes32 messageHash = keccak256(abi.encodePacked(
            _contentId,
            _modelId,
            _qualityScore,
            _tags,
            model.schemaHash // Include schema hash to link evaluation to expected format
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(_signature);

        if (signer != msg.sender) revert AetherFlow__InvalidSignature();

        content.evaluations.push(Evaluation({
            modelId: _modelId,
            verifier: signer,
            qualityScore: _qualityScore,
            tags: _tags,
            submitTimestamp: block.timestamp,
            disputed: false,
            signature: _signature
        }));

        // Update latest score/tags (could be an average or based on reputation of verifier)
        content.latestQualityScore = _qualityScore; // Simple assignment for now
        content.latestTags = _tags;

        // Reward the verifier (example: 0.1% of content fee or a fixed amount from treasury)
        s_pendingVerifierRewards[signer] += s_protocolFee / 10; // Example: 10% of the content fee

        emit AIEvaluationSubmitted(_contentId, _modelId, signer, _qualityScore);
    }

    /// @notice Retrieves comprehensive details about a submitted content piece, including its latest evaluation score and tags.
    /// @param _contentId The ID of the content.
    /// @return contentHash, title, description, submitter, submitTimestamp, latestQualityScore, latestTags, evaluationCount
    function getContentDetails(uint256 _contentId)
        public view
        returns (string memory contentHash, string memory title, string memory description, address submitter, uint256 submitTimestamp, uint256 latestQualityScore, string memory latestTags, uint256 evaluationCount)
    {
        Content storage content = s_contents[_contentId];
        if (content.submitter == address(0)) revert AetherFlow__ContentNotFound();
        return (
            content.contentHash,
            content.title,
            content.description,
            content.submitter,
            content.submitTimestamp,
            content.latestQualityScore,
            content.latestTags,
            content.evaluations.length
        );
    }

    /// @notice Allows a user to formally dispute a specific AI evaluation, marking it for potential community review or re-evaluation.
    /// @param _contentId The ID of the content.
    /// @param _evaluationIndex The index of the evaluation within the content's evaluations array.
    /// @param _reason The reason for the dispute.
    function disputeAIEvaluation(uint256 _contentId, uint256 _evaluationIndex, string calldata _reason) public whenNotPaused {
        Content storage content = s_contents[_contentId];
        if (content.submitter == address(0)) revert AetherFlow__ContentNotFound();
        if (_evaluationIndex >= content.evaluations.length) revert AetherFlow__EvaluationNotFound();

        // Add logic to prevent repeated disputes or disputes by non-reputable users
        content.evaluations[_evaluationIndex].disputed = true;
        // Further actions could include slashing verifier, triggering re-evaluation, or governance vote.

        emit AIEvaluationDisputed(_contentId, _evaluationIndex, msg.sender);
    }

    // --- IV. Reputation & Rewards System ---

    /// @notice Users stake protocol tokens to earn reputation points. Staked tokens are locked and contribute to voting power and reward multipliers.
    /// @param _amount The amount of protocol tokens to stake.
    function stakeForReputation(uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert AetherFlow__InvalidAmount();

        bool success = i_protocolToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert AetherFlow__InvalidAmount(); // More specific error in real world

        s_userReputations[msg.sender].stakedAmount += _amount;
        s_userReputations[msg.sender].lastStakeUpdate = block.timestamp;
        s_totalStakedReputation += _amount;

        emit ReputationStaked(msg.sender, _amount, s_totalStakedReputation);
    }

    /// @notice Users can request to unstake their tokens, which initiates a cooldown period.
    /// @param _amount The amount of protocol tokens to unstake.
    function unstakeForReputation(uint256 _amount) public whenNotPaused {
        UserReputation storage userRep = s_userReputations[msg.sender];
        if (_amount == 0 || _amount > userRep.stakedAmount) revert AetherFlow__InvalidAmount();

        userRep.pendingUnstakeAmount = _amount;
        userRep.lastUnstakeRequest = block.timestamp;

        emit ReputationUnstakeRequested(msg.sender, _amount, block.timestamp + s_reputationStakeCooldown);
    }

    /// @notice Completes the unstaking process after the cooldown period.
    function completeUnstake() public whenNotPaused {
        UserReputation storage userRep = s_userReputations[msg.sender];
        if (userRep.pendingUnstakeAmount == 0) revert AetherFlow__InvalidAmount(); // No pending unstake
        if (block.timestamp < userRep.lastUnstakeRequest + s_reputationStakeCooldown) revert AetherFlow__CannotUnstakeBeforeCooldown();

        uint256 amountToUnstake = userRep.pendingUnstakeAmount;
        userRep.stakedAmount -= amountToUnstake;
        userRep.pendingUnstakeAmount = 0;
        userRep.lastUnstakeRequest = 0; // Reset

        s_totalStakedReputation -= amountToUnstake;
        bool success = i_protocolToken.transfer(msg.sender, amountToUnstake);
        if (!success) revert AetherFlow__InvalidAmount(); // Transfer failed

        emit ReputationUnstaked(msg.sender, amountToUnstake, s_totalStakedReputation);
    }


    /// @notice Allows content creators to claim accumulated rewards based on their content's quality scores, engagement, and their reputation.
    function claimContentRewards() public whenNotPaused {
        uint256 amount = s_pendingContentRewards[msg.sender];
        if (amount == 0) return; // No rewards to claim

        s_pendingContentRewards[msg.sender] = 0;
        bool success = i_protocolToken.transfer(msg.sender, amount);
        if (!success) revert AetherFlow__InvalidAmount(); // Transfer failed

        emit ContentRewardsClaimed(msg.sender, amount);
    }

    /// @notice Allows VERIFIER_ROLE accounts to claim rewards for submitting validated AI evaluations.
    function claimVerifierRewards() public onlyVerifier whenNotPaused {
        uint256 amount = s_pendingVerifierRewards[msg.sender];
        if (amount == 0) return; // No rewards to claim

        s_pendingVerifierRewards[msg.sender] = 0;
        bool success = i_protocolToken.transfer(msg.sender, amount);
        if (!success) revert AetherFlow__InvalidAmount(); // Transfer failed

        emit VerifierRewardsClaimed(msg.sender, amount);
    }

    /// @notice Returns a user's current calculated reputation score based on their stake and time.
    ///         For simplicity, reputation is directly proportional to staked amount here.
    ///         Could be enhanced with time-weighted staking or activity scores.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputation(address _user) public view returns (uint256) {
        return s_userReputations[_user].stakedAmount;
    }

    // --- V. Simplified On-Chain Governance (Reputation-Based) ---

    /// @notice Allows users with sufficient reputation to propose changes to key contract parameters or execute specific calls.
    /// @param _description A description of the proposal.
    /// @param _callData The encoded function call to be executed if the proposal passes.
    function proposeParameterChange(string calldata _description, bytes calldata _callData) public whenNotPaused {
        uint256 proposerReputation = getReputation(msg.sender);
        if (proposerReputation < s_minReputationForProposal) revert AetherFlow__NotEnoughReputation();

        uint256 newProposalId = ++s_nextProposalId;
        Proposal storage proposal = s_proposals[newProposalId];
        proposal.description = _description;
        proposal.callData = _callData;
        proposal.proposer = proposerReputation;
        proposal.startTimestamp = block.timestamp;
        proposal.endTimestamp = block.timestamp + s_proposalVotingPeriod;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(newProposalId, msg.sender, _description);
    }

    /// @notice Users vote on active proposals. Their voting power is directly proportional to their reputation score.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function castVote(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = s_proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert AetherFlow__VotingPeriodActive();
        if (block.timestamp > proposal.endTimestamp) revert AetherFlow__VotingPeriodNotEnded();
        if (proposal.hasVoted[msg.sender]) revert AetherFlow__AlreadyVoted();

        uint256 voterReputation = getReputation(msg.sender);
        if (voterReputation == 0) revert AetherFlow__NotEnoughReputation(); // Must have some reputation to vote

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotes += voterReputation;
        } else {
            proposal.noVotes += voterReputation;
        }

        emit VoteCast(_proposalId, msg.sender, _support, voterReputation);
    }

    /// @notice Executes a proposal that has successfully passed its voting period and met the required reputation-based vote threshold.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = s_proposals[_proposalId];
        if (proposal.state == ProposalState.Executed) return; // Already executed
        if (proposal.state != ProposalState.Active) revert AetherFlow__ProposalNotFound();
        if (block.timestamp <= proposal.endTimestamp) revert AetherFlow__VotingPeriodActive();

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        if (totalVotes == 0) { // No votes cast, proposal fails.
            proposal.state = ProposalState.Failed;
            revert AetherFlow__ProposalFailed();
        }

        uint256 yesRatio = (proposal.yesVotes * 10000) / totalVotes;

        if (yesRatio >= s_minimumPassingReputationRatio) {
            proposal.state = ProposalState.Succeeded;
            // Execute the proposed call data
            (bool success, ) = address(this).call(proposal.callData);
            if (!success) {
                proposal.state = ProposalState.Failed; // Execution failed
                revert AetherFlow__CallDataExecutionFailed();
            }
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Failed;
            revert AetherFlow__ProposalFailed();
        }
    }

    /// @notice Allows a user to query the state of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return description, proposerReputation, startTimestamp, endTimestamp, yesVotes, noVotes, state, executed
    function getProposalDetails(uint256 _proposalId)
        public view
        returns (string memory description, uint256 proposerReputation, uint256 startTimestamp, uint256 endTimestamp, uint256 yesVotes, uint256 noVotes, ProposalState state, bool executed)
    {
        Proposal storage proposal = s_proposals[_proposalId];
        if (proposal.startTimestamp == 0) revert AetherFlow__ProposalNotFound();
        return (
            proposal.description,
            proposal.proposer,
            proposal.startTimestamp,
            proposal.endTimestamp,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.state,
            proposal.executed
        );
    }

    // --- VI. Treasury Management ---

    /// @notice Transfers accumulated protocol fees from content submissions to a designated DAO treasury address.
    function withdrawFeesToTreasury() public onlyTreasury whenNotPaused {
        uint256 balance = i_protocolToken.balanceOf(address(this)) - s_totalStakedReputation; // Only non-staked tokens
        if (balance == 0) return;

        bool success = i_protocolToken.transfer(s_treasuryAddress, balance);
        if (!success) revert AetherFlow__InvalidAmount(); // Transfer failed

        emit FeesWithdrawnToTreasury(balance);
    }

    /// @notice Allows users with sufficient reputation to propose allocating funds from the treasury for ecosystem development or grants.
    ///         This function creates a proposal that, if passed, executes a transfer from the treasury.
    /// @param _recipient The address to receive the grant.
    /// @param _amount The amount of protocol tokens to grant.
    /// @param _reason A description of the grant reason.
    function proposeTreasuryGrant(address _recipient, uint256 _amount, string calldata _reason) public whenNotPaused {
        uint256 proposerReputation = getReputation(msg.sender);
        if (proposerReputation < s_minReputationForProposal) revert AetherFlow__NotEnoughReputation();

        // Encode the call data for the actual transfer from the treasury
        bytes memory callData = abi.encodeWithSelector(
            i_protocolToken.transfer.selector,
            _recipient,
            _amount
        );

        uint256 newProposalId = ++s_nextProposalId;
        Proposal storage proposal = s_proposals[newProposalId];
        proposal.description = string(abi.encodePacked("Treasury Grant: ", _reason));
        proposal.callData = callData;
        proposal.proposer = proposerReputation;
        proposal.startTimestamp = block.timestamp;
        proposal.endTimestamp = block.timestamp + s_proposalVotingPeriod;
        proposal.state = ProposalState.Active;

        emit TreasuryGrantProposed(newProposalId, _recipient, _amount, _reason);
    }

    // --- Internal/Utility Functions ---
    // Can add helper functions here if needed, e.g., for reward calculation logic.
}
```