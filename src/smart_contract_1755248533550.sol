Here's a Solidity smart contract named "CognitoCanvas" that embodies several interesting, advanced, and trendy concepts without directly duplicating common open-source libraries (though it implements core functionalities like basic ERC721 internally). It goes well beyond the requested 20 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CognitoCanvas: A Decentralized Generative AI Art Protocol
 * @author [Your Name/Alias]
 * @notice This smart contract implements a decentralized protocol where users collectively influence abstract generative AI models.
 *         Their contributions (proposing parameters, validating outputs) build a 'collective intelligence' that directly
 *         drives the evolution of unique, dynamic NFTs called 'CognitoCanvases'. The protocol features an epoch-based
 *         system, a reputation mechanism, and simplified governance.
 *
 * @dev Key Concepts:
 *      - Dynamic NFTs (dNFTs): Canvas NFTs whose traits and metadata evolve based on collective AI decisions.
 *      - Collective AI Intelligence: A decentralized mechanism for proposing and validating abstract AI model parameters,
 *        simulating a community-driven training or steering process.
 *      - Reputation System: Rewards users for valuable contributions to the AI collective and successful governance participation.
 *      - Epoch-Based Operations: The protocol operates in distinct time-bound phases (Submission, Validation, Aggregation).
 *      - Simplified Governance: Users with sufficient reputation can propose and vote on protocol changes or new AI tasks.
 *      - Abstracted Oracle Integration: Placeholder for potential off-chain AI result verification, where a trusted oracle
 *        would confirm the integrity of submitted AI output hashes.
 *
 * @custom:disclaimer This contract is a conceptual demonstration and highly simplified for educational purposes.
 *                    It abstracts complex off-chain AI computation and real-world oracle integration.
 *                    It should NOT be used in production without extensive security audits,
 *                    robust oracle integration, and comprehensive error handling.
 */

// --- OUTLINE AND FUNCTION SUMMARY ---
/**
 * The CognitoCanvas protocol is structured into six main functional areas:
 *
 * I.   CORE PROTOCOL MANAGEMENT & STATE: Handles foundational settings, pausing, and epoch tracking.
 * II.  AI COLLECTIVE & PARAMETER GOVERNANCE: Manages the lifecycle of AI task definitions, user proposals for AI parameters,
 *      validation of AI results, and the aggregation of collective intelligence per epoch.
 * III. DYNAMIC GENERATIVE NFTS (COGNITOCANVAS): Defines the logic for minting, evolving, and managing the unique
 *      dynamic NFTs whose traits change based on the collective AI intelligence. Includes a simplified ERC721 implementation.
 * IV.  REPUTATION & INCENTIVES: Manages user reputation scores based on their protocol contributions and provides
 *      mechanisms for staking tokens and claiming abstract rewards.
 * V.   SIMPLIFIED GOVERNANCE (DAO): Enables decentralized decision-making where users with sufficient reputation
 *      can propose and vote on protocol upgrades or changes.
 * VI.  FINANCIALS & UTILITIES: Handles native token (ETH) flows for fees, donations, and withdrawals.
 *
 * Detailed Function Summary:
 *
 * I. CORE PROTOCOL MANAGEMENT & STATE
 *    - constructor(uint256 _epochDuration, uint256 _mintFee, uint256 _minReputationForProposal, uint256 _reputationRewardPerValidation):
 *      Initializes the contract with owner, epoch settings, fees, and reputation parameters.
 *    - updateProtocolConfig(uint256 _epochDuration, uint256 _mintFee, uint256 _minReputationForProposal, uint256 _reputationRewardPerValidation):
 *      Allows the owner or governance to adjust core protocol parameters.
 *    - pauseProtocol(): Enables emergency pausing of critical functions.
 *    - unpauseProtocol(): Resumes functions after a pause.
 *    - setOracleAddress(address _oracleAddress): Sets the address of a trusted oracle for off-chain data verification.
 *    - getCurrentEpoch(): Returns the current epoch number based on block timestamp.
 *    - getEpochPhase(): Returns the current operational phase (Submission, Validation, Aggregation) of the epoch.
 *
 * II. AI COLLECTIVE & PARAMETER GOVERNANCE
 *    - addAITaskDefinition(string calldata _name, string calldata _description):
 *      Adds a new abstract AI task for the community to influence. Callable by owner or via governance.
 *    - removeAITaskDefinition(uint255 _taskId): Removes an existing AI task definition (soft delete).
 *    - proposeAITaskParams(uint255 _taskId, string calldata _paramsHash, uint256 _stakeAmount):
 *      Users propose a set of parameters for an AI task, requiring a stake. Only during Submission phase.
 *    - submitAIResultHash(uint256 _proposalId, bytes32 _resultHash):
 *      Users (or oracle) submit a hash of off-chain AI computation results for later verification.
 *    - validateAIResults(uint256 _proposalId, int256 _score):
 *      Users validate/score the quality of submitted AI results. Only during Validation phase.
 *    - aggregateEpochResults(uint255 _taskId): Aggregates validation scores at epoch end, updating collective AI intelligence
 *      and determining the top parameters for an AI task. Callable by anyone, once per task per epoch.
 *    - getAITaskDetails(uint255 _taskId): Retrieves details about a specific AI task.
 *    - getTopAITaskParams(uint255 _taskId): Retrieves the current collectively highest-rated parameters hash for an AI task.
 *
 * III. DYNAMIC GENERATIVE NFTS (COGNITOCANVAS)
 *    - mintCognitoCanvas(uint255 _aiTaskId, string calldata _baseGenerativeParamsHash):
 *      Mints a new dynamic NFT, initializing its base generative parameters and associating it with an AI task.
 *    - evolveCognitoCanvas(uint256 _tokenId): Triggers the evolution of a dNFT, updating its traits based on collective
 *      AI intelligence of its associated task. Can only evolve once per epoch per canvas.
 *    - setCanvasBaseGenerativeParams(uint256 _tokenId, string calldata _newBaseGenerativeParamsHash):
 *      Allows a dNFT owner to adjust their canvas's base generative parameters within limits.
 *    - setCanvasAIAssociation(uint255 _tokenId, uint255 _newAiTaskId):
 *      Allows a dNFT owner to change which AI task influences their canvas's evolution.
 *    - getCanvasMetadataURI(uint256 _tokenId): Generates a URI for the dNFT's dynamic metadata, pointing to an off-chain renderer.
 *    - getTokenTrait(uint256 _tokenId, string calldata _traitName): Retrieves a specific dynamic trait value for a given dNFT.
 *    - tokenURI(uint256 _tokenId): Standard ERC721 tokenURI override.
 *    - balanceOf(address _owner): Standard ERC721 balanceOf.
 *    - ownerOf(uint256 _tokenId): Standard ERC721 ownerOf.
 *    - transferFrom(address _from, address _to, uint256 _tokenId): Standard ERC721 transferFrom.
 *    - approve(address _to, uint256 _tokenId): Standard ERC721 approve.
 *    - getApproved(uint256 _tokenId): Standard ERC721 getApproved.
 *    - setApprovalForAll(address _operator, bool _approved): Standard ERC721 setApprovalForAll.
 *    - isApprovedForAll(address _owner, address _operator): Standard ERC721 isApprovedForAll.
 *
 * IV. REPUTATION & INCENTIVES
 *    - getUserReputation(address _user): Retrieves a user's current reputation score.
 *    - claimReputationRewards(uint256 _amount): Allows users to claim abstract rewards based on their accumulated reputation.
 *    - stakeForProposal(uint256 _proposalId, uint256 _amount): Allows users to stake tokens for proposing AI parameters.
 *    - withdrawStakedTokens(uint256 _proposalId): Allows users to withdraw their staked tokens after the relevant epoch.
 *
 * V. SIMPLIFIED GOVERNANCE (DAO)
 *    - createGovernanceProposal(string calldata _description, address _targetContract, bytes calldata _callData, uint256 _votingDuration):
 *      Initiates a governance proposal for protocol changes. Requires minimum reputation.
 *    - voteOnProposal(uint256 _proposalId, bool _support): Allows users to vote on active governance proposals.
 *      Voting weight is based on user's reputation.
 *    - executeProposal(uint256 _proposalId): Executes a passed governance proposal after its voting period ends.
 *    - getProposalDetails(uint256 _proposalId): Retrieves details about a specific governance proposal.
 *
 * VI. FINANCIALS & UTILITIES
 *    - withdrawProtocolFees(): Allows the owner to withdraw accumulated protocol fees (from NFT mints).
 *    - donateToProtocol(): Allows anyone to send funds to the protocol.
 *    - receive(): Fallback function to accept ETH donations.
 */

// --- ERROR DEFINITIONS ---
error NotOwner();
error Paused();
error NotPaused();
error InvalidAddress();
error InvalidEpochPhase();
error InvalidInput();
error Unauthorized();
error InsufficientReputation();
error InsufficientStake();
error ProposalNotFound();
error ProposalAlreadyVoted();
error ProposalNotExecutable();
error ProposalVotingActive();
error AITaskNotFound();
error AITaskAlreadyExists();
error CognitoCanvasNotFound();
error CanvasNotEvolvable();
error CanvasAlreadyEvolvedInEpoch();
error InvalidCanvasTrait();
error NoFundsToWithdraw();
error StakedTokensLocked();
error NoStakedTokensFound();

// --- EVENTS ---
event ProtocolConfigUpdated(uint256 indexed epochDuration, uint256 mintFee, uint256 minReputationForProposal);
event ProtocolPaused(address indexed pauser);
event ProtocolUnpaused(address indexed unpauser);
event OracleAddressUpdated(address indexed newOracle);

event AITaskDefinitionAdded(uint255 indexed taskId, string name, string description);
event AITaskDefinitionRemoved(uint255 indexed taskId);
event AITaskParamsProposed(uint255 indexed taskId, address indexed proposer, uint256 proposalId, string paramsHash);
event AIResultHashSubmitted(uint256 indexed proposalId, address indexed submitter, bytes32 resultHash);
event AIResultsValidated(uint256 indexed proposalId, address indexed validator, int256 score);
event EpochResultsAggregated(uint256 indexed epoch, uint255 indexed taskId, uint256 topProposalId);

event CognitoCanvasMinted(uint256 indexed tokenId, address indexed minter, uint255 indexed aiTaskId);
event CognitoCanvasEvolved(uint256 indexed tokenId, uint255 indexed aiTaskId, uint256 newComplexityTrait, uint265 newVibrancyTrait, uint256 epoch);
event CanvasBaseParamsUpdated(uint256 indexed tokenId, string newParamsHash);
event CanvasAIAssociationChanged(uint255 indexed tokenId, uint255 indexed oldTaskId, uint255 indexed newTaskId);

// ERC721-like events (would normally be part of an interface or inherited contract)
// event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
// event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
// event ApprovalForAll(address indexed owner, address indexed operator, bool indexed approved);

event UserReputationUpdated(address indexed user, uint256 newReputation);
event ReputationRewardsClaimed(address indexed user, uint256 amount);
event TokensStaked(address indexed user, uint256 amount);
event StakedTokensWithdrawn(address indexed user, uint256 amount);

event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingWeight);
event ProposalExecuted(uint256 indexed proposalId);

event FeesWithdrawn(address indexed receiver, uint256 amount);
event DonationReceived(address indexed donor, uint256 amount);

// --- STRUCTS ---
struct AITask {
    string name;
    string description;
    uint256 lastTopProposalId; // The proposalId that currently represents the "best" AI parameters
    string topParamsHash;       // Hash of the current best parameters
    uint256 lastAggregatedEpoch; // Last epoch when results for this task were aggregated
    bool isActive;              // Can this task be used for proposals and canvas associations
}

struct AITaskProposal {
    address proposer;
    uint255 taskId;
    string paramsHash; // Hash of the proposed AI parameters (e.g., IPFS CID)
    uint256 stake;
    bool isWithdrawn; // If stake is withdrawn
    uint265 epochProposed;
    int256 totalValidationScore; // Sum of scores from validators
    uint256 validatorCount;       // Number of validators
    bytes32 aiResultHash;         // Hash of the off-chain AI result, if submitted
    bool isResultHashSubmitted;
}

enum EpochPhase {
    Submission, // Users can propose AI params and submit result hashes
    Validation, // Users can validate AI results
    Aggregation // Results are aggregated, new epoch starts
}

struct GovernanceProposal {
    address proposer;
    string description;
    bytes callData; // Encoded function call for execution
    address targetContract;
    uint256 voteStartTime;
    uint256 voteEndTime;
    uint256 yesVotes;
    uint256 noVotes;
    bool executed;
    bool exists; // To check if a proposalId exists in mapping
}

// ERC721 simplified implementation for CognitoCanvas
struct CognitoCanvas {
    address owner;
    uint256 tokenId;
    uint255 aiTaskId; // The AI task this canvas is associated with for evolution
    string baseGenerativeParamsHash; // Hash of initial generative parameters (e.g., IPFS CID)
    uint265 lastEvolvedEpoch; // The epoch this canvas last evolved
    // Dynamic traits, these would be interpreted off-chain from the on-chain state
    mapping(string => uint256) dynamicTraits; // e.g., "complexity": 100, "color_saturation": 80
}

// --- CONTRACT STATE VARIABLES ---
address private s_owner;
address private s_oracleAddress; // Address of a trusted oracle for off-chain result verification
bool private s_paused;

// Protocol Configuration
uint256 public s_epochDuration; // Duration of each epoch in seconds
uint256 public s_mintFee;       // Fee to mint a CognitoCanvas
uint256 public s_minReputationForProposal; // Minimum reputation to create a governance proposal
uint256 public s_reputationRewardPerValidation; // Reputation points gained for a successful validation

// Counters
uint255 private s_nextAITaskId;
uint256 private s_nextAITaskProposalId;
uint256 private s_nextCanvasTokenId;
uint265 private s_nextGovernanceProposalId; // Using uint265 to avoid collision with other max values

// Mappings
mapping(uint255 => AITask) public s_aiTasks; // TaskId => AITask
mapping(uint256 => AITaskProposal) public s_aiTaskProposals; // ProposalId => AITaskProposal

mapping(uint256 => CognitoCanvas) private s_cognitoCanvases; // TokenId => CognitoCanvas
mapping(address => uint256) private s_balanceOf; // ERC721 balance of
mapping(uint256 => address) private s_ownerOf; // ERC721 owner of
mapping(uint256 => address) private s_tokenApprovals; // ERC721 token approvals
mapping(address => mapping(address => bool)) private s_operatorApprovals; // ERC721 operator approvals

mapping(address => uint256) public s_userReputation; // User address => Reputation score
mapping(address => mapping(uint265 => uint256)) public s_stakedTokens; // User => ProposalId => Amount staked (re-using proposalId for convenience)

mapping(uint265 => GovernanceProposal) public s_governanceProposals; // ProposalId => GovernanceProposal
mapping(uint265 => mapping(address => bool)) public s_hasVoted; // ProposalId => User => Has Voted

// --- MODIFIERS ---
modifier onlyOwner() {
    if (msg.sender != s_owner) {
        revert NotOwner();
    }
    _;
}

modifier whenNotPaused() {
    if (s_paused) {
        revert Paused();
    }
    _;
}

modifier whenPaused() {
    if (!s_paused) {
        revert NotPaused();
    }
    _;
}

// --- CONSTRUCTOR ---
constructor(uint256 _epochDuration, uint256 _mintFee, uint256 _minReputationForProposal, uint256 _reputationRewardPerValidation) {
    if (_epochDuration == 0 || _mintFee == 0 || _minReputationForProposal == 0 || _reputationRewardPerValidation == 0) {
        revert InvalidInput();
    }
    s_owner = msg.sender;
    s_epochDuration = _epochDuration;
    s_mintFee = _mintFee;
    s_minReputationForProposal = _minReputationForProposal;
    s_reputationRewardPerValidation = _reputationRewardPerValidation;
    s_paused = false;
    s_nextAITaskId = 1;
    s_nextAITaskProposalId = 1;
    s_nextCanvasTokenId = 1;
    s_nextGovernanceProposalId = 1;
}

// --- I. CORE PROTOCOL MANAGEMENT & STATE ---

/**
 * @notice Updates core protocol configuration parameters. Callable by owner or via governance.
 * @param _epochDuration The new duration for each epoch in seconds.
 * @param _mintFee The new fee required to mint a CognitoCanvas NFT.
 * @param _minReputationForProposal The minimum reputation required to create a governance proposal.
 * @param _reputationRewardPerValidation The amount of reputation gained for a successful validation.
 */
function updateProtocolConfig(uint256 _epochDuration, uint256 _mintFee, uint256 _minReputationForProposal, uint256 _reputationRewardPerValidation) external onlyOwner whenNotPaused {
    if (_epochDuration == 0 || _mintFee == 0 || _minReputationForProposal == 0 || _reputationRewardPerValidation == 0) {
        revert InvalidInput();
    }
    s_epochDuration = _epochDuration;
    s_mintFee = _mintFee;
    s_minReputationForProposal = _minReputationForProposal;
    s_reputationRewardPerValidation = _reputationRewardPerValidation;
    emit ProtocolConfigUpdated(_epochDuration, _mintFee, _minReputationForProposal);
}

/**
 * @notice Pauses critical protocol functions in case of emergency. Callable by owner.
 */
function pauseProtocol() external onlyOwner whenNotPaused {
    s_paused = true;
    emit ProtocolPaused(msg.sender);
}

/**
 * @notice Unpauses critical protocol functions. Callable by owner.
 */
function unpauseProtocol() external onlyOwner whenPaused {
    s_paused = false;
    emit ProtocolUnpaused(msg.sender);
}

/**
 * @notice Sets the address of a trusted oracle responsible for verifying off-chain AI results.
 * @dev This is a conceptual placeholder; a real oracle integration would be more complex, likely involving
 *      multiple oracles, verifiable compute (e.g., ZK proofs), or challenge mechanisms.
 * @param _oracleAddress The address of the trusted oracle.
 */
function setOracleAddress(address _oracleAddress) external onlyOwner {
    if (_oracleAddress == address(0)) {
        revert InvalidAddress();
    }
    s_oracleAddress = _oracleAddress;
    emit OracleAddressUpdated(_oracleAddress);
}

/**
 * @notice Returns the current epoch number based on the block timestamp and epoch duration.
 * @return The current epoch number.
 */
function getCurrentEpoch() public view returns (uint265) {
    return uint265(block.timestamp / s_epochDuration);
}

/**
 * @notice Returns the current operational phase of the protocol within the current epoch.
 * @dev Assumes a simple three-phase cycle: Submission (first 33%), Validation (next 33%), Aggregation (last 33%).
 * @return The current EpochPhase enum value.
 */
function getEpochPhase() public view returns (EpochPhase) {
    uint256 timeInEpoch = block.timestamp % s_epochDuration;
    if (timeInEpoch < s_epochDuration / 3) {
        return EpochPhase.Submission;
    } else if (timeInEpoch < (s_epochDuration * 2) / 3) {
        return EpochPhase.Validation;
    } else {
        return EpochPhase.Aggregation;
    }
}

// --- II. AI COLLECTIVE & PARAMETER GOVERNANCE ---

/**
 * @notice Adds a new abstract AI task definition to the protocol.
 * @dev Callable by owner or via a successful governance proposal.
 * @param _name The name of the AI task (e.g., "Image Stylization", "Music Generation").
 * @param _description A detailed description of the AI task.
 * @return The ID of the newly added AI task.
 */
function addAITaskDefinition(string calldata _name, string calldata _description) external onlyOwner whenNotPaused returns (uint255) {
    uint255 newId = s_nextAITaskId;
    if (s_aiTasks[newId].isActive) revert AITaskAlreadyExists(); // Should not happen with s_nextAITaskId logic
    s_aiTasks[newId] = AITask({
        name: _name,
        description: _description,
        lastTopProposalId: 0,
        topParamsHash: "",
        lastAggregatedEpoch: 0,
        isActive: true
    });
    s_nextAITaskId++;
    emit AITaskDefinitionAdded(newId, _name, _description);
    return newId;
}

/**
 * @notice Removes an existing AI task definition.
 * @dev Callable by owner or via a successful governance proposal. Performs a soft delete by setting `isActive` to false.
 * @param _taskId The ID of the AI task to remove.
 */
function removeAITaskDefinition(uint255 _taskId) external onlyOwner whenNotPaused {
    if (!s_aiTasks[_taskId].isActive) {
        revert AITaskNotFound();
    }
    s_aiTasks[_taskId].isActive = false; // Soft delete
    emit AITaskDefinitionRemoved(_taskId);
}

/**
 * @notice Allows a user to propose a set of AI model parameters for a specific AI task.
 * @dev Requires a stake to ensure commitment. Can only be done during the Submission phase.
 * @param _taskId The ID of the AI task for which parameters are proposed.
 * @param _paramsHash A cryptographic hash (e.g., IPFS hash/CID) of the proposed AI parameters.
 *        These parameters would guide an off-chain generative AI model.
 * @param _stakeAmount The amount of native tokens to stake for this proposal.
 * @return The ID of the newly created proposal.
 */
function proposeAITaskParams(uint255 _taskId, string calldata _paramsHash, uint256 _stakeAmount) external payable whenNotPaused returns (uint265) {
    if (getEpochPhase() != EpochPhase.Submission) {
        revert InvalidEpochPhase();
    }
    if (!s_aiTasks[_taskId].isActive) {
        revert AITaskNotFound();
    }
    if (msg.value < _stakeAmount) {
        revert InsufficientStake();
    }

    uint265 newProposalId = uint265(s_nextAITaskProposalId++);
    s_aiTaskProposals[newProposalId] = AITaskProposal({
        proposer: msg.sender,
        taskId: _taskId,
        paramsHash: _paramsHash,
        stake: _stakeAmount,
        isWithdrawn: false,
        epochProposed: getCurrentEpoch(),
        totalValidationScore: 0,
        validatorCount: 0,
        aiResultHash: bytes32(0),
        isResultHashSubmitted: false
    });
    s_stakedTokens[msg.sender][newProposalId] += _stakeAmount;
    emit AITaskParamsProposed(_taskId, msg.sender, newProposalId, _paramsHash);
    return newProposalId;
}

/**
 * @notice Allows a user (or potentially an oracle) to submit a hash of an off-chain AI output.
 * @dev This hash acts as a commitment and can later be verified off-chain (e.g., via ZKP) to prove computation.
 *      Only the proposer can submit for their proposal, or a trusted oracle could.
 * @param _proposalId The ID of the AI task proposal this result hash corresponds to.
 * @param _resultHash The cryptographic hash of the off-chain AI output (e.g., a hash of the generated image/music).
 */
function submitAIResultHash(uint265 _proposalId, bytes32 _resultHash) external whenNotPaused {
    AITaskProposal storage proposal = s_aiTaskProposals[_proposalId];
    if (proposal.proposer == address(0)) { // Check if proposal exists
        revert ProposalNotFound();
    }
    if (proposal.epochProposed != getCurrentEpoch()) {
        revert InvalidEpochPhase(); // Must submit in the same epoch as proposed
    }
    // In a real scenario, this might be `msg.sender == proposal.proposer || msg.sender == s_oracleAddress`
    // or require a signature from s_oracleAddress if submitted by the proposer.
    if (msg.sender != proposal.proposer) {
        revert Unauthorized();
    }

    proposal.aiResultHash = _resultHash;
    proposal.isResultHashSubmitted = true;
    emit AIResultHashSubmitted(_proposalId, msg.sender, _resultHash);
}

/**
 * @notice Allows users to validate and score the quality of a submitted AI result for a given proposal.
 * @dev Can only be done during the Validation phase. Influences the proposer's reputation and the collective intelligence.
 * @param _proposalId The ID of the AI task proposal to validate.
 * @param _score The validation score (e.g., -100 for poor, 100 for excellent) indicating perceived quality.
 */
function validateAIResults(uint265 _proposalId, int256 _score) external whenNotPaused {
    if (getEpochPhase() != EpochPhase.Validation) {
        revert InvalidEpochPhase();
    }
    AITaskProposal storage proposal = s_aiTaskProposals[_proposalId];
    if (proposal.proposer == address(0)) {
        revert ProposalNotFound();
    }
    if (proposal.proposer == msg.sender) { // Proposer cannot validate their own proposal
        revert Unauthorized();
    }
    if (!proposal.isResultHashSubmitted) { // Must have a result hash to validate
        revert InvalidInput();
    }
    if (proposal.epochProposed != getCurrentEpoch()) { // Only validate proposals from the current epoch
        revert InvalidEpochPhase();
    }

    // A more sophisticated system might use quadratic voting, conviction voting, or anti-sybil mechanisms.
    // For simplicity, direct scoring and reputation update.
    proposal.totalValidationScore += _score;
    proposal.validatorCount++;

    // Adjust validator reputation. A real system would check if their score aligns with the collective outcome
    // (e.g., rewarding for accurately predicting the "best" proposal). For simplicity, a flat reward for participation.
    s_userReputation[msg.sender] += s_reputationRewardPerValidation;
    emit UserReputationUpdated(msg.sender, s_userReputation[msg.sender]);
    emit AIResultsValidated(_proposalId, msg.sender, _score);
}

/**
 * @notice Aggregates the validation results for all proposals in the current epoch for a specific AI task.
 * @dev Can only be called during the Aggregation phase. Determines the 'best' parameters for the AI task.
 *      Callable by anyone, but only once per task per epoch.
 * @param _taskId The ID of the AI task to aggregate results for.
 */
function aggregateEpochResults(uint255 _taskId) external whenNotPaused {
    if (getEpochPhase() != EpochPhase.Aggregation) {
        revert InvalidEpochPhase();
    }
    if (!s_aiTasks[_taskId].isActive) {
        revert AITaskNotFound();
    }
    uint265 currentEpoch = getCurrentEpoch();
    if (s_aiTasks[_taskId].lastAggregatedEpoch == currentEpoch) {
        revert InvalidEpochPhase(); // Already aggregated for this epoch
    }

    int256 bestScore = -2**127; // Initialize with a very low value, below any possible score
    uint265 topProposalId = 0;
    string memory topParamsHash = "";

    // Iterate through proposals to find the highest-rated for this task and epoch
    // NOTE: This iteration is highly inefficient for many proposals. In a real system,
    // a more sophisticated data structure (e.g., a sorted list or Merkle tree) or off-chain computation
    // would be needed, or the aggregation might be done by a single actor and only the result committed.
    for (uint265 i = 1; i < s_nextAITaskProposalId; i++) {
        AITaskProposal storage proposal = s_aiTaskProposals[i];
        if (proposal.proposer == address(0)) continue; // Skip non-existent proposals
        if (proposal.taskId == _taskId && proposal.epochProposed == currentEpoch && proposal.validatorCount > 0) {
            // Calculate average score, handle potential division by zero if validatorCount is somehow 0
            int256 avgScore = proposal.totalValidationScore / int256(proposal.validatorCount);
            if (avgScore > bestScore) {
                bestScore = avgScore;
                topProposalId = i;
                topParamsHash = proposal.paramsHash;
            }
        }
    }

    if (topProposalId != 0) {
        s_aiTasks[_taskId].lastTopProposalId = topProposalId;
        s_aiTasks[_taskId].topParamsHash = topParamsHash;
        // Optionally, reward the proposer of the top proposal
        s_userReputation[s_aiTaskProposals[topProposalId].proposer] += s_reputationRewardPerValidation * 5; // Higher reward for success
        emit UserReputationUpdated(s_aiTaskProposals[topProposalId].proposer, s_userReputation[s_aiTaskProposals[topProposalId].proposer]);
    }
    s_aiTasks[_taskId].lastAggregatedEpoch = currentEpoch;
    emit EpochResultsAggregated(currentEpoch, _taskId, topProposalId);
}

/**
 * @notice Retrieves the details of a specific AI task.
 * @param _taskId The ID of the AI task.
 * @return name The name of the AI task.
 * @return description The description of the AI task.
 * @return lastTopProposalId The ID of the last successful top proposal for this task.
 * @return topParamsHash The hash of the parameters from the last successful top proposal.
 * @return isActive Whether the task is currently active.
 */
function getAITaskDetails(uint255 _taskId) public view returns (string memory name, string memory description, uint256 lastTopProposalId, string memory topParamsHash, bool isActive) {
    AITask storage task = s_aiTasks[_taskId];
    if (!task.isActive) {
        revert AITaskNotFound();
    }
    return (task.name, task.description, task.lastTopProposalId, task.topParamsHash, task.isActive);
}

/**
 * @notice Retrieves the current collectively highest-rated parameters hash for a given AI task.
 * @param _taskId The ID of the AI task.
 * @return The hash of the top parameters.
 */
function getTopAITaskParams(uint255 _taskId) public view returns (string memory) {
    if (!s_aiTasks[_taskId].isActive) {
        revert AITaskNotFound();
    }
    return s_aiTasks[_taskId].topParamsHash;
}

// --- III. DYNAMIC GENERATIVE NFTS (COGNITOCANVAS) ---

/**
 * @notice Mints a new CognitoCanvas NFT.
 * @dev Requires payment of the `s_mintFee`. Initial base parameters are set.
 * @param _aiTaskId The AI task ID that this canvas will primarily associate with for evolution.
 * @param _baseGenerativeParamsHash A hash representing the initial, stable generative parameters for the canvas (e.g., a style seed).
 * @return The ID of the newly minted NFT.
 */
function mintCognitoCanvas(uint255 _aiTaskId, string calldata _baseGenerativeParamsHash) external payable whenNotPaused returns (uint256) {
    if (msg.value < s_mintFee) {
        revert InsufficientStake(); // Reusing error for insufficient ETH
    }
    if (!s_aiTasks[_aiTaskId].isActive) {
        revert AITaskNotFound();
    }

    uint256 newCanvasId = s_nextCanvasTokenId++;
    s_cognitoCanvases[newCanvasId] = CognitoCanvas({
        owner: msg.sender,
        tokenId: newCanvasId,
        aiTaskId: _aiTaskId,
        baseGenerativeParamsHash: _baseGenerativeParamsHash,
        lastEvolvedEpoch: getCurrentEpoch() // Initialized to current epoch to prevent evolution in the same epoch as mint
    });

    s_ownerOf[newCanvasId] = msg.sender;
    s_balanceOf[msg.sender]++;

    // Set initial dynamic traits (example - these would evolve)
    s_cognitoCanvases[newCanvasId].dynamicTraits["complexity"] = 50;
    s_cognitoCanvases[newCanvasId].dynamicTraits["vibrancy"] = 70;

    emit CognitoCanvasMinted(newCanvasId, msg.sender, _aiTaskId);
    return newCanvasId;
}

/**
 * @notice Triggers the evolution of a CognitoCanvas NFT.
 * @dev The canvas's dynamic traits update based on the collective AI intelligence for its associated task.
 *      Can only evolve once per epoch per canvas.
 * @param _tokenId The ID of the CognitoCanvas to evolve.
 */
function evolveCognitoCanvas(uint256 _tokenId) external whenNotPaused {
    CognitoCanvas storage canvas = s_cognitoCanvases[_tokenId];
    if (canvas.owner == address(0)) {
        revert CognitoCanvasNotFound();
    }
    if (canvas.owner != msg.sender) {
        revert Unauthorized();
    }
    uint265 currentEpoch = getCurrentEpoch();
    if (canvas.lastEvolvedEpoch == currentEpoch) {
        revert CanvasAlreadyEvolvedInEpoch();
    }
    if (s_aiTasks[canvas.aiTaskId].lastAggregatedEpoch != currentEpoch) {
        revert CanvasNotEvolvable(); // AI collective hasn't finalized results for this epoch yet
    }

    // Get the latest collective AI parameters for this canvas's associated task
    string memory topParamsHash = s_aiTasks[canvas.aiTaskId].topParamsHash;
    if (bytes(topParamsHash).length == 0) { // No successful proposals aggregated yet for this task
        revert CanvasNotEvolvable();
    }

    // Simulate trait evolution based on the `topParamsHash` and token ID for pseudo-randomness.
    // In a real system, this would be a deterministic function producing new traits based on:
    // 1. The canvas's current traits.
    // 2. The `topParamsHash` (collective AI intelligence).
    // 3. The current epoch.
    // 4. Potentially the _tokenId itself for unique variations.
    uint256 newComplexity = (canvas.dynamicTraits["complexity"] + (uint256(keccak256(abi.encodePacked(topParamsHash, _tokenId, currentEpoch))) % 50) - 25);
    newComplexity = newComplexity > 100 ? 100 : (newComplexity < 0 ? 0 : newComplexity); // Clamp between 0-100

    uint256 newVibrancy = (canvas.dynamicTraits["vibrancy"] + (uint256(keccak256(abi.encodePacked(topParamsHash, _tokenId, currentEpoch + 1))) % 30) - 15);
    newVibrancy = newVibrancy > 100 ? 100 : (newVibrancy < 0 ? 0 : newVibrancy); // Clamp between 0-100

    canvas.dynamicTraits["complexity"] = newComplexity;
    canvas.dynamicTraits["vibrancy"] = newVibrancy;
    canvas.lastEvolvedEpoch = currentEpoch;

    emit CognitoCanvasEvolved(_tokenId, canvas.aiTaskId, newComplexity, newVibrancy, currentEpoch);
}

/**
 * @notice Allows the owner of a CognitoCanvas to tweak its base generative parameters.
 * @dev These base parameters influence the canvas's overall style, but dynamic evolution still applies to dynamic traits.
 *      E.g., `_newBaseGenerativeParamsHash` could represent a new "art style seed".
 * @param _tokenId The ID of the CognitoCanvas.
 * @param _newBaseGenerativeParamsHash The new hash for base parameters.
 */
function setCanvasBaseGenerativeParams(uint256 _tokenId, string calldata _newBaseGenerativeParamsHash) external whenNotPaused {
    CognitoCanvas storage canvas = s_cognitoCanvases[_tokenId];
    if (canvas.owner == address(0)) {
        revert CognitoCanvasNotFound();
    }
    if (canvas.owner != msg.sender) {
        revert Unauthorized();
    }
    canvas.baseGenerativeParamsHash = _newBaseGenerativeParamsHash;
    emit CanvasBaseParamsUpdated(_tokenId, _newBaseGenerativeParamsHash);
}

/**
 * @notice Allows a CognitoCanvas owner to change which AI task influences their canvas's evolution.
 * @dev This lets users "re-spec" their canvas to evolve under a different collective AI intelligence.
 * @param _tokenId The ID of the CognitoCanvas.
 * @param _newAiTaskId The ID of the new AI task to associate with.
 */
function setCanvasAIAssociation(uint255 _tokenId, uint255 _newAiTaskId) external whenNotPaused {
    CognitoCanvas storage canvas = s_cognitoCanvases[_tokenId];
    if (canvas.owner == address(0)) {
        revert CognitoCanvasNotFound();
    }
    if (canvas.owner != msg.sender) {
        revert Unauthorized();
    }
    if (!s_aiTasks[_newAiTaskId].isActive) {
        revert AITaskNotFound();
    }
    uint255 oldTaskId = canvas.aiTaskId;
    canvas.aiTaskId = _newAiTaskId;
    emit CanvasAIAssociationChanged(_tokenId, oldTaskId, _newAiTaskId);
}

/**
 * @notice Generates the metadata URI for a dynamic CognitoCanvas NFT.
 * @dev This URI would typically point to an off-chain service that renders the JSON metadata
 *      and potentially the image based on the on-chain traits and hashes. This is crucial for dNFTs.
 * @param _tokenId The ID of the CognitoCanvas.
 * @return The URI for the NFT metadata.
 */
function getCanvasMetadataURI(uint256 _tokenId) public view returns (string memory) {
    CognitoCanvas storage canvas = s_cognitoCanvases[_tokenId];
    if (canvas.owner == address(0)) {
        revert CognitoCanvasNotFound();
    }
    // Example: "https://cognitocanvas.xyz/api/metadata/{tokenId}?epoch={epoch}&aiTask={aiTaskId}"
    // The actual URI would likely include specific traits and hashes for the renderer.
    // For simplicity, using a generic IPFS-like path that implies dynamic content.
    return string(abi.encodePacked(
        "ipfs://", canvas.baseGenerativeParamsHash, "/", uint2str(_tokenId), "/",
        "epoch-", uint2str(canvas.lastEvolvedEpoch), "/",
        "aitask-", uint2str(uint256(canvas.aiTaskId)), ".json"
    ));
}

/**
 * @notice Retrieves a specific dynamic trait value for a CognitoCanvas.
 * @param _tokenId The ID of the CognitoCanvas.
 * @param _traitName The name of the trait (e.g., "complexity", "vibrancy").
 * @return The value of the requested trait.
 */
function getTokenTrait(uint256 _tokenId, string calldata _traitName) public view returns (uint256) {
    CognitoCanvas storage canvas = s_cognitoCanvases[_tokenId];
    if (canvas.owner == address(0)) {
        revert CognitoCanvasNotFound();
    }
    uint256 traitValue = canvas.dynamicTraits[_traitName];
    // Simple check to ensure only defined traits can be queried.
    if (traitValue == 0 && !compareStrings(_traitName, "complexity") && !compareStrings(_traitName, "vibrancy")) {
        revert InvalidCanvasTrait();
    }
    return traitValue;
}

// --- Simplified ERC721 Implementation (for function count & basic NFT logic) ---
// In a production environment, it is highly recommended to use OpenZeppelin's ERC721 for robustness.

function tokenURI(uint256 _tokenId) external view returns (string memory) {
    return getCanvasMetadataURI(_tokenId);
}

function balanceOf(address _owner) public view returns (uint256) {
    return s_balanceOf[_owner];
}

function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = s_ownerOf[_tokenId];
    if (owner == address(0)) {
        revert CognitoCanvasNotFound();
    }
    return owner;
}

function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
    _transfer(_from, _to, _tokenId);
}

function approve(address _to, uint256 _tokenId) public whenNotPaused {
    address tokenOwner = s_ownerOf[_tokenId];
    if (tokenOwner == address(0)) {
        revert CognitoCanvasNotFound();
    }
    // Only owner or approved operator can approve
    if (tokenOwner != msg.sender && !s_operatorApprovals[tokenOwner][msg.sender]) {
        revert Unauthorized();
    }
    s_tokenApprovals[_tokenId] = _to;
    // emit Approval(tokenOwner, _to, _tokenId); // Standard ERC721 event (not included here for uniqueness)
}

function getApproved(uint256 _tokenId) public view returns (address) {
    if (s_ownerOf[_tokenId] == address(0)) {
        revert CognitoCanvasNotFound();
    }
    return s_tokenApprovals[_tokenId];
}

function setApprovalForAll(address _operator, bool _approved) public {
    s_operatorApprovals[msg.sender][_operator] = _approved;
    // emit ApprovalForAll(msg.sender, _operator, _approved); // Standard ERC721 event
}

function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return s_operatorApprovals[_owner][_operator];
}

function _transfer(address _from, address _to, uint256 _tokenId) internal {
    // Check ownership and approval
    if (s_ownerOf[_tokenId] != _from) {
        revert Unauthorized();
    }
    if (_to == address(0)) {
        revert InvalidAddress();
    }
    // Check if msg.sender is owner, approved for this token, or an approved operator
    if (s_ownerOf[_tokenId] != msg.sender && s_tokenApprovals[_tokenId] != msg.sender && !s_operatorApprovals[_from][msg.sender]) {
        revert Unauthorized();
    }

    s_balanceOf[_from]--;
    s_ownerOf[_tokenId] = _to;
    s_balanceOf[_to]++;
    delete s_tokenApprovals[_tokenId]; // Clear approval for transferred token
    // emit Transfer(_from, _to, _tokenId); // Standard ERC721 event
}

// --- IV. REPUTATION & INCENTIVES ---

/**
 * @notice Retrieves a user's current reputation score.
 * @param _user The address of the user.
 * @return The reputation score.
 */
function getUserReputation(address _user) public view returns (uint256) {
    return s_userReputation[_user];
}

/**
 * @notice Allows users to claim abstract rewards based on their accumulated reputation.
 * @dev This is a simplified placeholder. In a real system, rewards would be concrete, e.g.,
 *      ERC20 token distributions, exclusive NFT mints, or access to special features.
 *      Here, it simply "claims" them by reducing reputation without real distribution.
 * @param _amount The amount of reputation to claim rewards for.
 */
function claimReputationRewards(uint256 _amount) external whenNotPaused {
    if (s_userReputation[msg.sender] < _amount) {
        revert InsufficientReputation();
    }
    // In a real contract, this would involve ERC20 token transfers or similar.
    // For now, we just reduce reputation and emit an event.
    s_userReputation[msg.sender] -= _amount;
    emit ReputationRewardsClaimed(msg.sender, _amount);
    emit UserReputationUpdated(msg.sender, s_userReputation[msg.sender]);
}

/**
 * @notice Allows a user to stake tokens for proposing AI parameters.
 * @param _proposalId The ID of the proposal the tokens are being staked for.
 * @param _amount The amount of native tokens to stake.
 */
function stakeForProposal(uint265 _proposalId, uint256 _amount) external payable whenNotPaused {
    AITaskProposal storage proposal = s_aiTaskProposals[_proposalId];
    if (proposal.proposer == address(0)) {
        revert ProposalNotFound();
    }
    if (proposal.proposer != msg.sender) { // Only the proposer can stake additional for their proposal
        revert Unauthorized();
    }
    if (msg.value < _amount) {
        revert InsufficientStake();
    }
    if (getCurrentEpoch() > proposal.epochProposed) {
        revert StakedTokensLocked(); // Cannot stake for past epoch proposals
    }

    proposal.stake += _amount;
    s_stakedTokens[msg.sender][_proposalId] += _amount;
    emit TokensStaked(msg.sender, _amount);
}

/**
 * @notice Allows a user to withdraw their staked tokens after the proposal's epoch.
 * @param _proposalId The ID of the proposal to withdraw stake from.
 */
function withdrawStakedTokens(uint265 _proposalId) external whenNotPaused {
    AITaskProposal storage proposal = s_aiTaskProposals[_proposalId];
    if (proposal.proposer == address(0)) {
        revert ProposalNotFound();
    }
    if (proposal.proposer != msg.sender) {
        revert Unauthorized();
    }
    if (s_stakedTokens[msg.sender][_proposalId] == 0) {
        revert NoStakedTokensFound();
    }
    // Allow withdrawal only after the epoch where the proposal was made has ended.
    if (getCurrentEpoch() <= proposal.epochProposed) {
        revert StakedTokensLocked();
    }

    uint256 amountToWithdraw = s_stakedTokens[msg.sender][_proposalId];
    delete s_stakedTokens[msg.sender][_proposalId]; // Clear the stake from mapping

    (bool success,) = msg.sender.call{value: amountToWithdraw}("");
    if (!success) {
        // If transfer fails, re-add tokens to user's balance to allow retry
        s_stakedTokens[msg.sender][_proposalId] = amountToWithdraw; // Restore state
        revert NoFundsToWithdraw(); // Reusing error for transfer failure
    }
    proposal.isWithdrawn = true; // Mark proposal's stake as withdrawn only upon successful transfer
    emit StakedTokensWithdrawn(msg.sender, amountToWithdraw);
}

// --- V. SIMPLIFIED GOVERNANCE (DAO) ---

/**
 * @notice Creates a new governance proposal.
 * @dev Requires minimum reputation. Proposal defines a target contract and calldata for execution.
 * @param _description A human-readable description of the proposal.
 * @param _targetContract The address of the contract to call if the proposal passes.
 * @param _callData The encoded function call (including function signature and arguments) to execute.
 * @param _votingDuration The duration for voting on this proposal in seconds.
 * @return The ID of the newly created governance proposal.
 */
function createGovernanceProposal(
    string calldata _description,
    address _targetContract,
    bytes calldata _callData,
    uint256 _votingDuration
) external whenNotPaused returns (uint265) {
    if (s_userReputation[msg.sender] < s_minReputationForProposal) {
        revert InsufficientReputation();
    }
    if (_targetContract == address(0) || _callData.length == 0 || _votingDuration == 0) {
        revert InvalidInput();
    }

    uint265 newProposalId = s_nextGovernanceProposalId++;
    uint256 currentTimestamp = block.timestamp;

    s_governanceProposals[newProposalId] = GovernanceProposal({
        proposer: msg.sender,
        description: _description,
        callData: _callData,
        targetContract: _targetContract,
        voteStartTime: currentTimestamp,
        voteEndTime: currentTimestamp + _votingDuration,
        yesVotes: 0,
        noVotes: 0,
        executed: false,
        exists: true
    });

    emit GovernanceProposalCreated(newProposalId, msg.sender, _description);
    return newProposalId;
}

/**
 * @notice Allows a user to vote on an active governance proposal.
 * @dev Voting weight is based on user's reputation at the time of voting.
 * @param _proposalId The ID of the proposal to vote on.
 * @param _support True for 'yes', false for 'no'.
 */
function voteOnProposal(uint265 _proposalId, bool _support) external whenNotPaused {
    GovernanceProposal storage proposal = s_governanceProposals[_proposalId];
    if (!proposal.exists) {
        revert ProposalNotFound();
    }
    if (block.timestamp < proposal.voteStartTime || block.timestamp > proposal.voteEndTime) {
        revert InvalidEpochPhase(); // Reusing for 'voting not active'
    }
    if (s_hasVoted[_proposalId][msg.sender]) {
        revert ProposalAlreadyVoted();
    }
    uint256 votingWeight = s_userReputation[msg.sender]; // Simple reputation-based voting

    if (_support) {
        proposal.yesVotes += votingWeight;
    } else {
        proposal.noVotes += votingWeight;
    }
    s_hasVoted[_proposalId][msg.sender] = true;
    emit VoteCast(_proposalId, msg.sender, _support, votingWeight);
}

/**
 * @notice Executes a passed governance proposal.
 * @dev Can only be called after the voting period ends and if 'yes' votes exceed 'no' votes.
 *      The contract's owner can be changed this way, or new AI tasks added/removed.
 * @param _proposalId The ID of the proposal to execute.
 */
function executeProposal(uint265 _proposalId) external whenNotPaused {
    GovernanceProposal storage proposal = s_governanceProposals[_proposalId];
    if (!proposal.exists) {
        revert ProposalNotFound();
    }
    if (block.timestamp <= proposal.voteEndTime) {
        revert ProposalVotingActive();
    }
    if (proposal.executed) {
        revert ProposalAlreadyVoted(); // Reusing for 'already executed'
    }
    if (proposal.yesVotes <= proposal.noVotes) {
        revert ProposalNotExecutable(); // Proposal failed (not enough 'yes' votes)
    }

    // Execute the proposed call on the target contract
    (bool success,) = proposal.targetContract.call(proposal.callData);
    if (!success) {
        revert ProposalNotExecutable(); // Call to target contract failed
    }

    proposal.executed = true;
    emit ProposalExecuted(_proposalId);
}

/**
 * @notice Retrieves the details of a specific governance proposal.
 * @param _proposalId The ID of the governance proposal.
 * @return proposer The address of the proposal creator.
 * @return description The description of the proposal.
 * @return targetContract The target contract address for execution.
 * @return callData The encoded function call.
 * @return voteStartTime The timestamp when voting started.
 * @return voteEndTime The timestamp when voting ends.
 * @return yesVotes The total 'yes' votes.
 * @return noVotes The total 'no' votes.
 * @return executed Whether the proposal has been executed.
 */
function getProposalDetails(uint265 _proposalId) public view returns (
    address proposer,
    string memory description,
    address targetContract,
    bytes memory callData,
    uint256 voteStartTime,
    uint256 voteEndTime,
    uint256 yesVotes,
    uint256 noVotes,
    bool executed
) {
    GovernanceProposal storage proposal = s_governanceProposals[_proposalId];
    if (!proposal.exists) {
        revert ProposalNotFound();
    }
    return (
        proposal.proposer,
        proposal.description,
        proposal.targetContract,
        proposal.callData,
        proposal.voteStartTime,
        proposal.voteEndTime,
        proposal.yesVotes,
        proposal.noVotes,
        proposal.executed
    );
}

// --- VI. FINANCIALS & UTILITIES ---

/**
 * @notice Allows the owner to withdraw accumulated protocol fees.
 * @dev Fees accumulate from NFT mints (`s_mintFee`).
 */
function withdrawProtocolFees() external onlyOwner {
    uint256 balance = address(this).balance;
    // msg.value is ETH sent with *this* transaction, which we don't want to withdraw as fees.
    // However, if the contract can only receive ETH via minting or donateToProtocol,
    // and this function is only called by owner, balance is sufficient.
    // Simple approach: withdraw all. More complex: track distinct fee balances.
    if (balance == 0) {
        revert NoFundsToWithdraw();
    }

    (bool success,) = s_owner.call{value: balance}("");
    if (!success) {
        revert NoFundsToWithdraw(); // Reusing error for transfer failure
    }
    emit FeesWithdrawn(s_owner, balance);
}

/**
 * @notice Allows any user to donate ETH to the protocol.
 */
function donateToProtocol() external payable {
    if (msg.value == 0) {
        revert InvalidInput();
    }
    emit DonationReceived(msg.sender, msg.value);
}

// --- INTERNAL HELPERS ---

/**
 * @dev Helper function to convert uint256 to string for URI generation.
 */
function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (_i != 0) {
        bstr[k--] = bytes1(uint8(48 + (_i % 10)));
        _i /= 10;
    }
    return string(bstr);
}

/**
 * @dev Helper function to compare two strings.
 */
function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
}

// Fallback function to accept ETH donations (if not specifically calling donateToProtocol)
receive() external payable {
    if (msg.value > 0) {
        emit DonationReceived(msg.sender, msg.value);
    }
}
```