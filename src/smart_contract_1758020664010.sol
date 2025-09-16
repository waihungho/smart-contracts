Here's a smart contract in Solidity called `AetherMindProtocol` that aims to be interesting, advanced, creative, and trendy. It focuses on a decentralized AI-powered research and development platform, incorporating concepts like dynamic reputation via SoulBound Tokens (SBTs), community-driven solution validation (akin to a prediction market), and a decentralized knowledge base.

The contract aims for uniqueness by combining these elements into a cohesive platform, rather than merely implementing a single common pattern (like a basic ERC20 or NFT).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender() with a twist
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion

// Custom Errors for gas efficiency and clarity
error AetherMind__NotResearcher();
error AetherMind__ResearcherAlreadyRegistered();
error AetherMind__ResearcherNotFound();
error AetherMind__TaskNotFound();
error AetherMind__TaskNotActive();
error AetherMind__TaskAlreadyHasSolution();
error AetherMind__SolutionNotFound();
error AetherMind__NotTaskCreatorOrOwner();
error AetherMind__InsufficientFunds();
error AetherMind__InvalidStakeAmount();
error AetherMind__ValidationPeriodNotEnded();
error AetherMind__ValidationPeriodActive();
error AetherMind__AlreadyStakedForSolution();
error AetherMind__NoClaimableStake();
error AetherMind__AIModelNotFound();
error AetherMind__KnowledgeAssetNotFound();
error AetherMind__KnowledgeAssetNotPrivate();
error AetherMind__AccessDenied();
error AetherMind__AccessAlreadyGranted();
error AetherMind__ProposalNotFound();
error AetherMind__VotingPeriodNotEnded();
error AetherMind__VotingPeriodActive();
error AetherMind__ProposalNotExecutable();
error AetherMind__AlreadyVoted();
error AetherMind__SBTContractNotSet();
error AetherMind__SBTAlreadyMinted();
error AetherMind__InvalidParameterName();
error AetherMind__InvalidOracleAddress();
error AetherMind__OracleAlreadyRegistered();
error AetherMind__InvalidInputData();
error AetherMind__NotSufficientReputation(); // Added this custom error

/**
 * @title IReputationSBT
 * @dev Interface for the SoulBound Token (SBT) contract.
 *      This contract is external and responsible for managing non-transferable tokens
 *      that represent a researcher's on-chain reputation and identity.
 */
interface IReputationSBT {
    function mint(address to, string calldata tokenURI) external returns (uint256 tokenId);
    function updateTokenURI(uint256 tokenId, string calldata newTokenURI) external;
    function getTokenId(address owner) external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @title AetherMindProtocol
 * @dev A Decentralized AI-Powered Research & Development Platform with dynamic reputation,
 *      verifiable outputs, and a community-driven validation/challenge system.
 *      This contract orchestrates AI task bounties, solution submissions, decentralized
 *      validation, a knowledge base, and governance, all tied into a researcher's
 *      dynamic SoulBound Token (SBT) reputation.
 *
 * Outline and Function Summary:
 *
 * I. Core Infrastructure & Access Control
 *    1. constructor(address _tokenAddress, address _reputationSBTAddress): Initializes owner, sets the main utility token and ReputationSBT contract addresses, and initial protocol parameters.
 *    2. pauseProtocol(): Pauses core functions (callable by `OWNER_ROLE` or DAO-controlled in a full setup).
 *    3. unpauseProtocol(): Unpauses core functions (callable by `OWNER_ROLE` or DAO-controlled).
 *    4. updateProtocolParameter(bytes32 _paramName, uint256 _newValue): Allows `OWNER_ROLE` or DAO to update various protocol constants (e.g., `minStakeForResearcher`, `validationPeriodDuration`).
 *    5. recoverStuckFunds(address _token, address _to, uint256 _amount): Allows `OWNER_ROLE` or DAO to recover accidentally sent tokens (excluding core utility/SBT tokens).
 *
 * II. Researcher Profile & Dynamic Reputation System
 *    6. registerResearcher(string memory _profileCID): Allows users to create a researcher profile, requiring an initial stake. Stores IPFS CID of off-chain profile.
 *    7. updateResearcherProfile(string memory _newProfileCID): Researchers can update their profile metadata CID.
 *    8. getResearcherProfile(address _researcher): Retrieves a researcher's profile data (CID, reputation, SBT ID).
 *    9. mintReputationSBT(address _researcher): Mints a non-transferable ERC721-like token (SBT) for a researcher, representing their initial on-chain identity and reputation.
 *   10. updateReputationSBT(address _researcher, string memory _newSBTMetadataCID): Internal function to update the metadata URI of a researcher's SBT to reflect changes in reputation or achievements.
 *   11. getResearcherReputation(address _researcher): Public function to get a researcher's current reputation score.
 *
 * III. AI Task & Project Management
 *   12. createAITaskBounty(string memory _taskDescriptionCID, uint256 _bountyAmount, uint256 _validationPeriod): Users propose and fund AI-driven research tasks with a utility token bounty.
 *   13. submitAITaskSolution(uint256 _taskId, string memory _solutionCID, string memory _proofCID): Researchers submit solutions (e.g., IPFS CIDs of results, proof-of-computations, data references) for an active task.
 *   14. registerAIModelOracle(bytes32 _modelId, string memory _modelMetadataCID, address _oracleAddress): `OWNER_ROLE`/DAO registers external AI model endpoints (metadata CID) and their associated oracle address for task processing.
 *   15. requestAIModelComputation(uint256 _taskId, bytes32 _modelId, bytes memory _inputData): Researchers or project creators can request an AI model registered on the platform to perform a computation for a specific task via its oracle.
 *   16. receiveAIModelComputationResult(uint256 _taskId, bytes32 _modelId, bytes memory _outputData, string memory _outputCID): Callback function for the AI Model Oracle to submit computation results.
 *
 * IV. Decentralized Validation & Challenge System
 *   17. stakeForSolutionValidation(uint256 _taskId, uint256 _solutionId, bool _isChallenging, uint256 _stakeAmount): Community members stake tokens to either validate (agree) or challenge (disagree) a submitted solution. This initiates or participates in the validation period.
 *   18. resolveSolutionChallenge(uint256 _taskId, uint256 _solutionId): Callable after the validation period ends. Based on the majority stake, determines if the solution is valid or challenged, distributes bounties/stakes, and updates researcher reputation.
 *   19. claimValidationStake(uint256 _taskId, uint256 _solutionId): Allows stakers (both successful validators and challengers) to claim their proportional rewards or recover their stake after a solution is resolved.
 *
 * V. Knowledge Base & Data Contribution
 *   20. contributeKnowledgeAsset(string memory _assetCID, string memory _metadataCID, bool _isPrivate, uint256 _accessFee): Researchers contribute datasets/knowledge (represented by CIDs). Can be public or private with an access fee.
 *   21. requestKnowledgeAssetAccess(uint256 _assetId): Users can request access to a private knowledge asset, paying the `_accessFee` if applicable. This logs a request for the asset owner to approve.
 *   22. approveKnowledgeAssetAccess(uint256 _assetId, address _requester): The owner of a private asset approves an access request, granting the `_requester` permission and receiving any associated fees.
 *
 * VI. DAO Governance (Simplified)
 *   23. createParameterUpdateProposal(bytes32 _paramName, uint256 _newValue): Allows high-reputation researchers or designated DAO members to create a proposal to update a protocol parameter.
 *   24. voteOnProposal(uint256 _proposalId, bool _support): Community members vote on proposals, with voting power currently based on reputation score.
 *   25. executeProposal(uint256 _proposalId): Executed by DAO/trusted role after voting period ends and proposal passes, applies the parameter change.
 *
 * Additional Functions:
 *    26. setReputationSBTContract(address _newSBTAddress): Emergency/upgrade function to set the SBT contract address.
 *    27. getTaskStatus(uint256 _taskId): Helper function to retrieve the current status of a task.
 */
contract AetherMindProtocol is Ownable, Pausable {
    using Counters for Counters.Counter;

    IERC20 public immutable i_utilityToken;
    IReputationSBT public i_reputationSBT; // Address of the external Reputation SBT contract

    // --- Configuration Parameters (updatable by DAO/Owner) ---
    mapping(bytes32 => uint256) public protocolParameters;

    bytes32 public constant MIN_RESEARCHER_STAKE = keccak256("MIN_RESEARCHER_STAKE");
    bytes32 public constant INITIAL_REPUTATION_SCORE = keccak256("INITIAL_REPUTATION_SCORE");
    bytes32 public constant REPUTATION_GAIN_SUCCESSFUL_TASK = keccak256("REPUTATION_GAIN_SUCCESSFUL_TASK");
    bytes32 public constant REPUTATION_LOSS_FAILED_TASK = keccak256("REPUTATION_LOSS_FAILED_TASK");
    bytes32 public constant REPUTATION_GAIN_SUCCESSFUL_VALIDATION = keccak256("REPUTATION_GAIN_SUCCESSFUL_VALIDATION");
    bytes32 public constant REPUTATION_LOSS_FAILED_VALIDATION = keccak256("REPUTATION_LOSS_FAILED_VALIDATION");
    bytes32 public constant CHALLENGE_FEE_PERCENTAGE = keccak256("CHALLENGE_FEE_PERCENTAGE"); // e.g., 500 = 5% of losing stake goes to treasury/burn
    bytes32 public constant MIN_PROPOSAL_VOTING_POWER = keccak256("MIN_PROPOSAL_VOTING_POWER"); // Minimum reputation/stake to create a proposal
    bytes32 public constant PROPOSAL_VOTING_PERIOD = keccak256("PROPOSAL_VOTING_PERIOD"); // Duration of proposal voting in seconds
    bytes32 public constant PROPOSAL_PASS_THRESHOLD_PERCENTAGE = keccak256("PROPOSAL_PASS_THRESHOLD_PERCENTAGE"); // e.g., 5100 = 51%

    // --- Structs ---

    struct Researcher {
        string profileCID; // IPFS CID for off-chain profile data
        uint256 reputationScore;
        bool isRegistered;
        uint256 sbtTokenId; // ID of the reputation SBT for this researcher (0 if not minted)
    }

    enum TaskStatus {
        Active,              // Task is open for solution submissions
        SolutionSubmitted,   // A solution has been submitted, but validation hasn't started
        ValidationInProgress, // Solution is undergoing community validation/challenge
        CompletedValid,      // Solution validated as correct, bounty distributed
        CompletedChallenged, // Solution challenged and deemed incorrect
        Cancelled            // Task was cancelled (e.g., by creator before solution)
    }

    struct AITask {
        address creator;
        string descriptionCID; // IPFS CID for detailed task description
        uint256 bountyAmount;
        uint256 creationTime;
        uint256 validationPeriodDuration; // How long validation/challenge is open after solution submission
        TaskStatus status;
        uint256 solutionId; // Points to the latest (or only) solution for this task, 0 if none
    }

    struct Solution {
        uint256 taskId;
        address submitter;
        string solutionCID; // IPFS CID for the submitted solution details
        string proofCID; // IPFS CID for any proof-of-computation or verifiable claims
        uint256 submissionTime; // Timestamp when the solution was submitted
        uint256 totalValidationStake; // Total tokens staked for 'validating' this solution
        uint256 totalChallengeStake; // Total tokens staked for 'challenging' this solution
        bool isResolved; // True if the validation period has ended and outcome determined
        bool isValid; // Final outcome: true if deemed valid, false if challenged successfully
        mapping(address => StakeInfo) stakers; // Stakers for this specific solution
    }

    struct StakeInfo {
        uint256 amount;
        bool isChallenging; // True if staked to challenge, false if to validate
        bool hasClaimed;    // True if the staker has claimed their rewards/stake
    }

    struct AIModelOracle {
        string modelMetadataCID; // IPFS CID for model details (e.g., API endpoint, version, terms)
        address oracleAddress; // The trusted address of the off-chain oracle service for this model
        bool isRegistered;
    }

    struct KnowledgeAsset {
        address contributor;
        string assetCID;     // IPFS CID of the actual data/asset content
        string metadataCID;  // IPFS CID of metadata for the asset (description, licensing)
        bool isPrivate;      // If true, requires explicit access or fee
        uint256 accessFee;   // Fee in utility token for accessing this asset if private
        uint256 creationTime;
        mapping(address => bool) hasAccess; // Addresses that have been granted access
    }

    enum ProposalStatus {
        Pending, // Not yet started (could be used if there's a queue)
        Active,  // Currently in voting period
        Passed,  // Voted 'for' and met threshold
        Failed,  // Voted 'against' or did not meet threshold
        Executed // Passed and the change has been applied
    }

    struct Proposal {
        address creator;
        bytes32 paramName; // The protocol parameter to be updated
        uint256 newValue;  // The proposed new value for the parameter
        uint256 creationTime;
        uint256 votingPeriodEnd;
        uint256 totalVotesFor;    // Weighted sum of votes 'for'
        uint256 totalVotesAgainst; // Weighted sum of votes 'against'
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address has voted for this proposal
    }

    // --- Counters ---
    Counters.Counter private _taskIdCounter;
    Counters.Counter private _solutionIdCounter;
    Counters.Counter private _knowledgeAssetIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Mappings ---
    mapping(address => Researcher) public researchers;
    mapping(uint256 => AITask) public aiTasks;
    mapping(uint256 => Solution) public solutions;
    mapping(bytes32 => AIModelOracle) public aiModelOracles; // modelId => AIModelOracle configuration
    mapping(uint256 => KnowledgeAsset) public knowledgeAssets;
    mapping(address => mapping(uint256 => bool)) public researcherAssetRequests; // researcher => assetId => requested (true if pending)

    // --- Governance ---
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---
    event ResearcherRegistered(address indexed researcher, string profileCID, uint256 initialReputation);
    event ResearcherProfileUpdated(address indexed researcher, string newProfileCID);
    event ReputationSBTMinted(address indexed researcher, uint256 sbtTokenId);
    event ReputationSBTUpdated(address indexed researcher, uint256 sbtTokenId, string newSBTMetadataCID);

    event AITaskCreated(uint256 indexed taskId, address indexed creator, uint256 bountyAmount, string descriptionCID);
    event SolutionSubmitted(uint256 indexed taskId, uint256 indexed solutionId, address indexed submitter, string solutionCID);
    event AIModelOracleRegistered(bytes32 indexed modelId, string modelMetadataCID, address oracleAddress);
    event AIModelComputationRequested(uint256 indexed taskId, bytes32 indexed modelId, address indexed requester, bytes inputData);
    event AIModelComputationResult(uint256 indexed taskId, bytes32 indexed modelId, bytes outputData, string outputCID); // Oracle sends this back

    event SolutionValidationStaked(uint256 indexed taskId, uint256 indexed solutionId, address indexed staker, uint256 amount, bool isChallenging);
    event SolutionResolved(uint256 indexed taskId, uint256 indexed solutionId, bool isValid, uint256 totalValidationStake, uint256 totalChallengeStake);
    event ValidationStakeClaimed(uint256 indexed taskId, uint256 indexed solutionId, address indexed staker, uint256 amount);

    event KnowledgeAssetContributed(uint256 indexed assetId, address indexed contributor, string assetCID, bool isPrivate, uint256 accessFee);
    event KnowledgeAssetAccessRequested(uint256 indexed assetId, address indexed requester, uint256 feePaid);
    event KnowledgeAssetAccessApproved(uint256 indexed assetId, address indexed approver, address indexed requester);

    event ProposalCreated(uint256 indexed proposalId, address indexed creator, bytes32 paramName, uint256 newValue, uint256 votingPeriodEnd);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);


    // --- Modifiers ---
    modifier onlyRegisteredResearcher() {
        if (!researchers[_msgSender()].isRegistered) {
            revert AetherMind__NotResearcher();
        }
        _;
    }

    modifier onlySufficientReputation(uint256 _requiredReputation) {
        if (researchers[_msgSender()].reputationScore < _requiredReputation) {
            revert AetherMind__NotSufficientReputation();
        }
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        if (aiTasks[_taskId].creator != _msgSender()) {
            revert AetherMind__NotTaskCreatorOrOwner();
        }
        _;
    }

    /**
     * @dev Constructor to initialize the contract.
     * @param _tokenAddress The address of the ERC20 utility token used for bounties and staking.
     * @param _reputationSBTAddress The address of the external ReputationSBT contract.
     */
    constructor(address _tokenAddress, address _reputationSBTAddress) Ownable(msg.sender) Pausable(msg.sender) {
        require(_tokenAddress != address(0), "AetherMind: Token address cannot be zero");
        require(_reputationSBTAddress != address(0), "AetherMind: SBT address cannot be zero");

        i_utilityToken = IERC20(_tokenAddress);
        i_reputationSBT = IReputationSBT(_reputationSBTAddress);

        // Set initial protocol parameters
        // Values are typically in smallest unit (e.g., wei for tokens, 100 = 1%)
        protocolParameters[MIN_RESEARCHER_STAKE] = 1000 * 10 ** 18; // 1000 tokens required to register
        protocolParameters[INITIAL_REPUTATION_SCORE] = 100; // Starting reputation for new researchers
        protocolParameters[REPUTATION_GAIN_SUCCESSFUL_TASK] = 50; // Reputation points gained for successful task
        protocolParameters[REPUTATION_LOSS_FAILED_TASK] = 30; // Reputation points lost for failed task
        protocolParameters[REPUTATION_GAIN_SUCCESSFUL_VALIDATION] = 10; // Reputation for successful validation
        protocolParameters[REPUTATION_LOSS_FAILED_VALIDATION] = 5; // Reputation loss for incorrect validation
        protocolParameters[CHALLENGE_FEE_PERCENTAGE] = 500; // 5% (500 basis points) of losing stake goes to treasury/burn
        protocolParameters[MIN_PROPOSAL_VOTING_POWER] = 500; // Minimum reputation to create a proposal
        protocolParameters[PROPOSAL_VOTING_PERIOD] = 7 days; // Voting period duration for proposals
        protocolParameters[PROPOSAL_PASS_THRESHOLD_PERCENTAGE] = 5100; // 51% (5100 basis points) of votes needed to pass a proposal
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Pauses the protocol. Only callable by owner.
     *      In a full DAO setup, this would be managed by DAO governance.
     */
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the protocol. Only callable by owner.
     *      In a full DAO setup, this would be managed by DAO governance.
     */
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner (or DAO in a full setup) to update core protocol parameters.
     *      This function can also be invoked via a successful governance proposal.
     * @param _paramName The keccak256 hash of the parameter name (e.g., keccak256("MIN_RESEARCHER_STAKE")).
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) public onlyOwner {
        // In a full DAO setup, this would be executed by a successful proposal.
        // Basic check for valid parameter names before update.
        if (_paramName != MIN_RESEARCHER_STAKE && _paramName != INITIAL_REPUTATION_SCORE &&
            _paramName != REPUTATION_GAIN_SUCCESSFUL_TASK && _paramName != REPUTATION_LOSS_FAILED_TASK &&
            _paramName != REPUTATION_GAIN_SUCCESSFUL_VALIDATION && _paramName != REPUTATION_LOSS_FAILED_VALIDATION &&
            _paramName != CHALLENGE_FEE_PERCENTAGE && _paramName != MIN_PROPOSAL_VOTING_POWER &&
            _paramName != PROPOSAL_VOTING_PERIOD && _paramName != PROPOSAL_PASS_THRESHOLD_PERCENTAGE) {
            revert AetherMind__InvalidParameterName();
        }
        protocolParameters[_paramName] = _newValue;
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    /**
     * @dev Allows owner/DAO to recover accidentally sent ERC20 tokens.
     *      Crucially, it prevents recovery of the main utility token or SBT contract
     *      to avoid disrupting protocol functionality.
     * @param _token The address of the ERC20 token to recover.
     * @param _to The address to send the recovered tokens to.
     * @param _amount The amount of tokens to recover.
     */
    function recoverStuckFunds(address _token, address _to, uint256 _amount) public onlyOwner {
        if (_token == address(i_utilityToken) || _token == address(i_reputationSBT)) {
            revert AetherMind__InvalidInputData(); // Prevents recovering essential protocol tokens
        }
        require(IERC20(_token).transfer(_to, _amount), "AetherMind: Failed to recover funds");
    }

    // --- II. Researcher Profile & Dynamic Reputation System ---

    /**
     * @dev Allows a user to register as a researcher. Requires an initial stake in the utility token.
     *      The stake serves as a commitment and prevents sybil attacks.
     * @param _profileCID IPFS CID of the researcher's off-chain profile data (e.g., bio, expertise).
     */
    function registerResearcher(string memory _profileCID) public whenNotPaused {
        if (researchers[_msgSender()].isRegistered) {
            revert AetherMind__ResearcherAlreadyRegistered();
        }

        uint256 minStake = protocolParameters[MIN_RESEARCHER_STAKE];
        if (minStake > 0) {
            if (!i_utilityToken.transferFrom(_msgSender(), address(this), minStake)) {
                revert AetherMind__InsufficientFunds(); // Ensure user approved tokens
            }
        }

        researchers[_msgSender()] = Researcher({
            profileCID: _profileCID,
            reputationScore: protocolParameters[INITIAL_REPUTATION_SCORE],
            isRegistered: true,
            sbtTokenId: 0 // Will be set upon minting SBT
        });

        emit ResearcherRegistered(_msgSender(), _profileCID, protocolParameters[INITIAL_REPUTATION_SCORE]);
    }

    /**
     * @dev Allows a registered researcher to update their profile CID.
     * @param _newProfileCID New IPFS CID for the researcher's profile.
     */
    function updateResearcherProfile(string memory _newProfileCID) public whenNotPaused onlyRegisteredResearcher {
        researchers[_msgSender()].profileCID = _newProfileCID;
        // Optionally, update SBT metadata here if the profile CID is part of it.
        // updateReputationSBT(_msgSender(), string(abi.encodePacked("ipfs://", _newProfileCID, "/sbt/", Strings.toString(researchers[_msgSender()].reputationScore))));
        emit ResearcherProfileUpdated(_msgSender(), _newProfileCID);
    }

    /**
     * @dev Retrieves a researcher's profile data.
     * @param _researcher The address of the researcher.
     * @return profileCID IPFS CID of the researcher's profile.
     * @return reputationScore The current reputation score of the researcher.
     * @return isRegistered True if the address is a registered researcher.
     * @return sbtTokenId The token ID of their ReputationSBT (0 if not minted).
     */
    function getResearcherProfile(address _researcher) public view returns (string memory profileCID, uint256 reputationScore, bool isRegistered, uint256 sbtTokenId) {
        Researcher storage r = researchers[_researcher];
        return (r.profileCID, r.reputationScore, r.isRegistered, r.sbtTokenId);
    }

    /**
     * @dev Mints a SoulBound Token (SBT) for a researcher. Can only be minted once per researcher.
     *      The SBT token URI should encode initial reputation or a link to a dynamic metadata source.
     * @param _researcher The address of the researcher to mint the SBT for.
     */
    function mintReputationSBT(address _researcher) public whenNotPaused onlyRegisteredResearcher {
        if (address(i_reputationSBT) == address(0)) {
            revert AetherMind__SBTContractNotSet();
        }
        if (researchers[_researcher].sbtTokenId != 0) {
            revert AetherMind__SBTAlreadyMinted();
        }

        // Generate a base URI for the SBT metadata, referencing off-chain profile and reputation.
        // This makes the SBT dynamic, as its URI can be updated as reputation changes.
        string memory initialSBTURI = string(abi.encodePacked(
            "ipfs://", researchers[_researcher].profileCID, "/sbt_data/", Strings.toString(researchers[_researcher].reputationScore)
        ));

        uint256 tokenId = i_reputationSBT.mint(_researcher, initialSBTURI);
        researchers[_researcher].sbtTokenId = tokenId;
        emit ReputationSBTMinted(_researcher, tokenId);
    }

    /**
     * @dev INTERNAL FUNCTION: Updates the metadata URI of a researcher's existing ReputationSBT.
     *      This is called internally when a researcher's reputation changes due to protocol actions.
     * @param _researcher The address of the researcher whose SBT to update.
     * @param _newSBTMetadataCID New IPFS CID for the SBT metadata, reflecting updated stats.
     */
    function updateReputationSBT(address _researcher, string memory _newSBTMetadataCID) internal {
        if (address(i_reputationSBT) == address(0) || researchers[_researcher].sbtTokenId == 0) {
            return; // No SBT contract set or SBT not yet minted, skip update
        }
        i_reputationSBT.updateTokenURI(researchers[_researcher].sbtTokenId, _newSBTMetadataCID);
        emit ReputationSBTUpdated(_researcher, researchers[_researcher].sbtTokenId, _newSBTMetadataCID);
    }

    /**
     * @dev Retrieves the current reputation score for a researcher.
     * @param _researcher The address of the researcher.
     * @return The current reputation score.
     */
    function getResearcherReputation(address _researcher) public view returns (uint256) {
        return researchers[_researcher].reputationScore;
    }

    // --- III. AI Task & Project Management ---

    /**
     * @dev Creates a new AI task bounty. Requires the bounty amount to be transferred to the contract.
     *      Only registered researchers can create tasks.
     * @param _taskDescriptionCID IPFS CID of the detailed task description.
     * @param _bountyAmount The amount of utility tokens offered as a bounty for successful completion.
     * @param _validationPeriod The duration in seconds for the validation/challenge phase after a solution is submitted.
     */
    function createAITaskBounty(string memory _taskDescriptionCID, uint256 _bountyAmount, uint256 _validationPeriod) public whenNotPaused onlyRegisteredResearcher {
        if (_bountyAmount == 0 || _validationPeriod == 0) {
            revert AetherMind__InvalidInputData();
        }

        // Transfer bounty from creator to contract
        if (!i_utilityToken.transferFrom(_msgSender(), address(this), _bountyAmount)) {
            revert AetherMind__InsufficientFunds(); // Ensure user approved tokens
        }

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        aiTasks[newTaskId] = AITask({
            creator: _msgSender(),
            descriptionCID: _taskDescriptionCID,
            bountyAmount: _bountyAmount,
            creationTime: block.timestamp,
            validationPeriodDuration: _validationPeriod,
            status: TaskStatus.Active,
            solutionId: 0 // No solution submitted yet
        });

        emit AITaskCreated(newTaskId, _msgSender(), _bountyAmount, _taskDescriptionCID);
    }

    /**
     * @dev Allows a registered researcher to submit a solution for an active AI task.
     *      Only one solution can be active for validation at a time for a given task.
     * @param _taskId The ID of the task.
     * @param _solutionCID IPFS CID of the solution details/results.
     * @param _proofCID IPFS CID of any proof-of-computation or verifiable claims supporting the solution.
     */
    function submitAITaskSolution(uint256 _taskId, string memory _solutionCID, string memory _proofCID) public whenNotPaused onlyRegisteredResearcher {
        AITask storage task = aiTasks[_taskId];
        if (task.creator == address(0)) {
            revert AetherMind__TaskNotFound();
        }
        if (task.status != TaskStatus.Active) {
            revert AetherMind__TaskNotActive();
        }
        if (task.solutionId != 0) {
            revert AetherMind__TaskAlreadyHasSolution();
        }

        _solutionIdCounter.increment();
        uint256 newSolutionId = _solutionIdCounter.current();

        solutions[newSolutionId] = Solution({
            taskId: _taskId,
            submitter: _msgSender(),
            solutionCID: _solutionCID,
            proofCID: _proofCID,
            submissionTime: block.timestamp,
            totalValidationStake: 0,
            totalChallengeStake: 0,
            isResolved: false,
            isValid: false,
            stakers: new mapping(address => StakeInfo) // Initialize mapping
        });

        task.status = TaskStatus.SolutionSubmitted; // Mark task for validation
        task.solutionId = newSolutionId;

        emit SolutionSubmitted(_taskId, newSolutionId, _msgSender(), _solutionCID);
    }

    /**
     * @dev Registers an external AI model oracle with the platform. Callable by owner/DAO.
     *      This allows task creators/researchers to request computations from registered AI models.
     * @param _modelId A unique identifier (e.g., hash, name) for the AI model.
     * @param _modelMetadataCID IPFS CID for metadata of the AI model (description, capabilities).
     * @param _oracleAddress The address of the oracle contract/service responsible for interacting with this model.
     */
    function registerAIModelOracle(bytes32 _modelId, string memory _modelMetadataCID, address _oracleAddress) public onlyOwner {
        if (_oracleAddress == address(0)) {
            revert AetherMind__InvalidOracleAddress();
        }
        if (aiModelOracles[_modelId].isRegistered) {
            revert AetherMind__OracleAlreadyRegistered();
        }

        aiModelOracles[_modelId] = AIModelOracle({
            modelMetadataCID: _modelMetadataCID,
            oracleAddress: _oracleAddress,
            isRegistered: true
        });

        emit AIModelOracleRegistered(_modelId, _modelMetadataCID, _oracleAddress);
    }

    /**
     * @dev Requests an AI model registered on the platform to perform a computation.
     *      This function emits an event which an off-chain oracle listener would pick up
     *      to trigger the actual AI computation.
     * @param _taskId The ID of the task this computation is related to.
     * @param _modelId The unique ID of the AI model to use.
     * @param _inputData The input data for the AI model (e.g., encoded parameters, data CIDs).
     */
    function requestAIModelComputation(uint256 _taskId, bytes32 _modelId, bytes memory _inputData) public whenNotPaused onlyRegisteredResearcher {
        AITask storage task = aiTasks[_taskId];
        if (task.creator == address(0)) {
            revert AetherMind__TaskNotFound();
        }
        if (!aiModelOracles[_modelId].isRegistered) {
            revert AetherMind__AIModelNotFound();
        }
        // A more advanced implementation might include payment to the oracle and a request ID.

        emit AIModelComputationRequested(_taskId, _modelId, _msgSender(), _inputData);
    }

    /**
     * @dev Callback function for the AI Model Oracle to submit the computation result.
     *      This function is called by the registered `oracleAddress` of a specific `_modelId`.
     * @param _taskId The ID of the task for which the computation was performed.
     * @param _modelId The unique ID of the AI model used.
     * @param _outputData The raw output data from the AI model (e.g., a small summary).
     * @param _outputCID IPFS CID of a more extensive output/report from the AI model.
     */
    function receiveAIModelComputationResult(uint256 _taskId, bytes32 _modelId, bytes memory _outputData, string memory _outputCID) public {
        AIModelOracle storage modelOracle = aiModelOracles[_modelId];
        if (!modelOracle.isRegistered || modelOracle.oracleAddress != _msgSender()) {
            revert AetherMind__AccessDenied(); // Only the registered oracle can submit results
        }

        AITask storage task = aiTasks[_taskId];
        if (task.creator == address(0)) {
            revert AetherMind__TaskNotFound();
        }

        // The AI result can be used by researchers to refine their solutions, or
        // in a more advanced scenario, directly update a task's solution.
        // For this contract, we simply emit an event.
        emit AIModelComputationResult(_taskId, _modelId, _outputData, _outputCID);
    }


    // --- IV. Decentralized Validation & Challenge System ---

    /**
     * @dev Allows community members (registered researchers) to stake tokens to either validate (agree)
     *      or challenge (disagree) a submitted solution. This initiates or participates in the
     *      validation period.
     * @param _taskId The ID of the task.
     * @param _solutionId The ID of the solution being validated/challenged.
     * @param _isChallenging True to stake for challenging the solution, false for validating it.
     * @param _stakeAmount The amount of utility tokens to stake.
     */
    function stakeForSolutionValidation(uint256 _taskId, uint256 _solutionId, bool _isChallenging, uint256 _stakeAmount) public whenNotPaused onlyRegisteredResearcher {
        AITask storage task = aiTasks[_taskId];
        Solution storage solution = solutions[_solutionId];

        if (task.creator == address(0) || task.solutionId != _solutionId) {
            revert AetherMind__TaskNotFound(); // Task must exist and _solutionId must be its active solution
        }
        if (solution.submitter == address(0)) {
            revert AetherMind__SolutionNotFound();
        }
        if (solution.isResolved) {
            revert AetherMind__ValidationPeriodNotEnded(); // Solution already resolved
        }
        // Task must be in a state where validation is possible
        if (task.status != TaskStatus.SolutionSubmitted && task.status != TaskStatus.ValidationInProgress) {
            revert AetherMind__ValidationPeriodNotEnded();
        }
        // Check if the validation period is still active
        if (block.timestamp >= solution.submissionTime + task.validationPeriodDuration) {
            revert AetherMind__ValidationPeriodNotEnded();
        }
        if (_stakeAmount == 0) {
            revert AetherMind__InvalidStakeAmount();
        }
        if (solution.stakers[_msgSender()].amount > 0) {
            revert AetherMind__AlreadyStakedForSolution(); // One stake per solution per staker
        }

        // Transfer stake from staker to contract
        if (!i_utilityToken.transferFrom(_msgSender(), address(this), _stakeAmount)) {
            revert AetherMind__InsufficientFunds(); // Ensure user approved tokens
        }

        if (task.status == TaskStatus.SolutionSubmitted) {
            task.status = TaskStatus.ValidationInProgress; // Transition task to validation state
        }

        solution.stakers[_msgSender()] = StakeInfo({
            amount: _stakeAmount,
            isChallenging: _isChallenging,
            hasClaimed: false
        });

        if (_isChallenging) {
            solution.totalChallengeStake += _stakeAmount;
        } else {
            solution.totalValidationStake += _stakeAmount;
        }

        emit SolutionValidationStaked(_taskId, _solutionId, _msgSender(), _stakeAmount, _isChallenging);
    }

    /**
     * @dev Resolves a solution's validity after the validation period ends.
     *      Distributes bounties and updates researcher reputation. Callable by anyone after the period.
     * @param _taskId The ID of the task.
     * @param _solutionId The ID of the solution.
     */
    function resolveSolutionChallenge(uint256 _taskId, uint256 _solutionId) public whenNotPaused {
        AITask storage task = aiTasks[_taskId];
        Solution storage solution = solutions[_solutionId];

        if (task.creator == address(0) || task.solutionId != _solutionId) {
            revert AetherMind__TaskNotFound();
        }
        if (solution.submitter == address(0)) {
            revert AetherMind__SolutionNotFound();
        }
        if (solution.isResolved) {
            return; // Already resolved, idempotent call
        }
        if (block.timestamp < solution.submissionTime + task.validationPeriodDuration) {
            revert AetherMind__ValidationPeriodActive(); // Validation period still active
        }

        // Determine solution validity based on majority stake (simple prediction market logic)
        bool solutionIsValid = (solution.totalValidationStake >= solution.totalChallengeStake);

        solution.isResolved = true;
        solution.isValid = solutionIsValid;
        task.status = solutionIsValid ? TaskStatus.CompletedValid : TaskStatus.CompletedChallenged;

        // --- Distribute Bounty and Update Researcher Reputation ---
        if (solutionIsValid) {
            // Reward submitter with bounty
            if (!i_utilityToken.transfer(solution.submitter, task.bountyAmount)) {
                // If transfer fails, log it but don't revert to allow stakers to claim rewards.
                // In a production system, this would require robust error handling or a retry mechanism.
            }
            researchers[solution.submitter].reputationScore += protocolParameters[REPUTATION_GAIN_SUCCESSFUL_TASK];
        } else {
            // Penalize submitter for an incorrect/failed solution
            researchers[solution.submitter].reputationScore = researchers[solution.submitter].reputationScore > protocolParameters[REPUTATION_LOSS_FAILED_TASK] ?
                                                                researchers[solution.submitter].reputationScore - protocolParameters[REPUTATION_LOSS_FAILED_TASK] : 0;
            // The bounty for a challenged solution could be returned to the task creator,
            // or moved to a DAO treasury. For now, it remains in the contract.
        }

        // Update the submitter's SBT metadata to reflect their new reputation
        updateReputationSBT(solution.submitter, string(abi.encodePacked("ipfs://", researchers[solution.submitter].profileCID, "/sbt_data/", Strings.toString(researchers[solution.submitter].reputationScore))));

        emit SolutionResolved(_taskId, _solutionId, solutionIsValid, solution.totalValidationStake, solution.totalChallengeStake);
    }

    /**
     * @dev Allows stakers to claim their proportional rewards (or recover stake) after a solution is resolved.
     *      Successful validators/challengers earn a share of the losing side's stakes,
     *      minus a `CHALLENGE_FEE_PERCENTAGE` that goes to the protocol treasury/burn.
     * @param _taskId The ID of the task.
     * @param _solutionId The ID of the solution.
     */
    function claimValidationStake(uint256 _taskId, uint256 _solutionId) public whenNotPaused {
        Solution storage solution = solutions[_solutionId];
        StakeInfo storage stakerInfo = solution.stakers[_msgSender()];

        if (solution.submitter == address(0)) {
            revert AetherMind__SolutionNotFound();
        }
        if (!solution.isResolved) {
            revert AetherMind__ValidationPeriodActive(); // Solution not yet resolved
        }
        if (stakerInfo.amount == 0 || stakerInfo.hasClaimed) {
            revert AetherMind__NoClaimableStake(); // No stake or already claimed
        }

        uint256 stakeToReturn = 0;
        uint256 reward = 0;

        // Determine if the staker was on the winning side
        bool stakerWasCorrect = (stakerInfo.isChallenging == !solution.isValid); // Challenging a valid solution is wrong, validating a valid solution is right, etc.

        if (stakerWasCorrect) {
            // Winning stakers get their original stake back PLUS a reward from the losing pool
            stakeToReturn = stakerInfo.amount;

            uint256 totalWinningStake = stakerInfo.isChallenging ? solution.totalChallengeStake : solution.totalValidationStake;
            uint256 totalLosingStake = stakerInfo.isChallenging ? solution.totalValidationStake : solution.totalChallengeStake;

            if (totalWinningStake > 0 && totalLosingStake > 0) {
                // Calculate the portion of losing stake available for rewards (after challenge fee)
                uint256 availableForRewards = (totalLosingStake * (10000 - protocolParameters[CHALLENGE_FEE_PERCENTAGE])) / 10000;
                reward = (stakerInfo.amount * availableForRewards) / totalWinningStake;
            }
            researchers[_msgSender()].reputationScore += protocolParameters[REPUTATION_GAIN_SUCCESSFUL_VALIDATION];
        } else {
            // Losing stakers lose their entire stake (or a portion if `CHALLENGE_FEE_PERCENTAGE` is designed differently)
            // For simplicity, their stake is consumed and not returned. The `CHALLENGE_FEE_PERCENTAGE` of this
            // losing stake would go to the protocol treasury (or be burned), the rest to winners.
            stakeToReturn = 0; // Stake is lost to the reward pool / treasury
            researchers[_msgSender()].reputationScore = researchers[_msgSender()].reputationScore > protocolParameters[REPUTATION_LOSS_FAILED_VALIDATION] ?
                                                          researchers[_msgSender()].reputationScore - protocolParameters[REPUTATION_LOSS_FAILED_VALIDATION] : 0;
        }

        // Update the staker's SBT metadata to reflect their new reputation
        updateReputationSBT(_msgSender(), string(abi.encodePacked("ipfs://", researchers[_msgSender()].profileCID, "/sbt_data/", Strings.toString(researchers[_msgSender()].reputationScore))));

        uint256 totalClaim = stakeToReturn + reward;
        if (totalClaim > 0) {
            if (!i_utilityToken.transfer(_msgSender(), totalClaim)) {
                // If transfer fails, log but mark as claimed to prevent re-attempts.
            }
        }
        stakerInfo.hasClaimed = true;
        emit ValidationStakeClaimed(_taskId, _solutionId, _msgSender(), totalClaim);
    }

    // --- V. Knowledge Base & Data Contribution ---

    /**
     * @dev Allows researchers to contribute knowledge assets (datasets, code, research papers, etc.)
     *      to the platform. Assets are represented by IPFS CIDs.
     * @param _assetCID IPFS CID of the actual knowledge asset content.
     * @param _metadataCID IPFS CID of additional metadata for the asset (description, licensing).
     * @param _isPrivate If true, access requires explicit approval or payment. If false, it's public.
     * @param _accessFee The fee in utility tokens for accessing this asset if `_isPrivate` is true.
     */
    function contributeKnowledgeAsset(string memory _assetCID, string memory _metadataCID, bool _isPrivate, uint256 _accessFee) public whenNotPaused onlyRegisteredResearcher {
        if (bytes(_assetCID).length == 0 || bytes(_metadataCID).length == 0) {
            revert AetherMind__InvalidInputData();
        }

        _knowledgeAssetIdCounter.increment();
        uint256 newAssetId = _knowledgeAssetIdCounter.current();

        knowledgeAssets[newAssetId] = KnowledgeAsset({
            contributor: _msgSender(),
            assetCID: _assetCID,
            metadataCID: _metadataCID,
            isPrivate: _isPrivate,
            accessFee: _accessFee,
            creationTime: block.timestamp,
            hasAccess: new mapping(address => bool) // Initialize
        });
        // Contributor always has access to their own asset
        knowledgeAssets[newAssetId].hasAccess[_msgSender()] = true;

        emit KnowledgeAssetContributed(newAssetId, _msgSender(), _assetCID, _isPrivate, _accessFee);
    }

    /**
     * @dev Allows a user to request access to a private knowledge asset.
     *      If there's an `_accessFee`, it's paid to the contract for later distribution to the contributor.
     * @param _assetId The ID of the knowledge asset.
     */
    function requestKnowledgeAssetAccess(uint256 _assetId) public whenNotPaused onlyRegisteredResearcher {
        KnowledgeAsset storage asset = knowledgeAssets[_assetId];
        if (asset.contributor == address(0)) {
            revert AetherMind__KnowledgeAssetNotFound();
        }
        if (!asset.isPrivate) {
            revert AetherMind__KnowledgeAssetNotPrivate(); // No need to request access for public assets
        }
        if (asset.hasAccess[_msgSender()]) {
            revert AetherMind__AccessAlreadyGranted(); // Already has access
        }
        if (researcherAssetRequests[_msgSender()][_assetId]) {
            revert AetherMind__AccessAlreadyGranted(); // Already requested, awaiting approval
        }

        uint256 feePaid = 0;
        if (asset.accessFee > 0) {
            if (!i_utilityToken.transferFrom(_msgSender(), address(this), asset.accessFee)) {
                revert AetherMind__InsufficientFunds(); // Ensure user approved tokens
            }
            feePaid = asset.accessFee;
        }

        researcherAssetRequests[_msgSender()][_assetId] = true; // Mark as requested, awaiting contributor approval

        emit KnowledgeAssetAccessRequested(_assetId, _msgSender(), feePaid);
    }

    /**
     * @dev Allows the contributor of a private knowledge asset to approve an access request.
     *      If an access fee was paid, it's transferred to the contributor upon approval.
     * @param _assetId The ID of the knowledge asset.
     * @param _requester The address of the researcher requesting access.
     */
    function approveKnowledgeAssetAccess(uint256 _assetId, address _requester) public whenNotPaused onlyRegisteredResearcher {
        KnowledgeAsset storage asset = knowledgeAssets[_assetId];
        if (asset.contributor == address(0)) {
            revert AetherMind__KnowledgeAssetNotFound();
        }
        if (asset.contributor != _msgSender()) {
            revert AetherMind__AccessDenied(); // Only the asset contributor can approve
        }
        if (!asset.isPrivate) {
            revert AetherMind__KnowledgeAssetNotPrivate();
        }
        if (!researcherAssetRequests[_requester][_assetId]) {
            revert AetherMind__AccessDenied(); // No pending request from this user
        }
        if (asset.hasAccess[_requester]) {
            revert AetherMind__AccessAlreadyGranted(); // Already granted
        }

        asset.hasAccess[_requester] = true;
        researcherAssetRequests[_requester][_assetId] = false; // Clear the pending request

        if (asset.accessFee > 0) {
            // Transfer the collected fee from the contract to the asset contributor
            if (!i_utilityToken.transfer(asset.contributor, asset.accessFee)) {
                // Handle failed transfer, maybe log, but don't revert to keep access granted
            }
        }

        emit KnowledgeAssetAccessApproved(_assetId, _msgSender(), _requester);
    }

    // --- VI. DAO Governance (Simplified) ---

    /**
     * @dev Creates a proposal to update a protocol parameter.
     *      Requires a minimum reputation score to prevent spam.
     * @param _paramName The keccak256 hash of the parameter name to update.
     * @param _newValue The proposed new value for the parameter.
     */
    function createParameterUpdateProposal(bytes32 _paramName, uint256 _newValue) public whenNotPaused onlyRegisteredResearcher {
        if (researchers[_msgSender()].reputationScore < protocolParameters[MIN_PROPOSAL_VOTING_POWER]) {
            revert AetherMind__NotSufficientReputation();
        }
        // Basic whitelist check for valid parameter names that can be proposed for update.
        if (_paramName != MIN_RESEARCHER_STAKE && _paramName != INITIAL_REPUTATION_SCORE &&
            _paramName != REPUTATION_GAIN_SUCCESSFUL_TASK && _paramName != REPUTATION_LOSS_FAILED_TASK &&
            _paramName != REPUTATION_GAIN_SUCCESSFUL_VALIDATION && _paramName != REPUTATION_LOSS_FAILED_VALIDATION &&
            _paramName != CHALLENGE_FEE_PERCENTAGE && _paramName != MIN_PROPOSAL_VOTING_POWER &&
            _paramName != PROPOSAL_VOTING_PERIOD && _paramName != PROPOSAL_PASS_THRESHOLD_PERCENTAGE) {
            revert AetherMind__InvalidParameterName();
        }

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            creator: _msgSender(),
            paramName: _paramName,
            newValue: _newValue,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + protocolParameters[PROPOSAL_VOTING_PERIOD],
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit ProposalCreated(newProposalId, _msgSender(), _paramName, _newValue, proposals[newProposalId].votingPeriodEnd);
    }

    /**
     * @dev Allows registered researchers to vote on an active proposal.
     *      Voting power is currently based on the researcher's current reputation score.
     * @param _proposalId The ID of the proposal.
     * @param _support True to vote 'for' the proposal, false to vote 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused onlyRegisteredResearcher {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0) || proposal.status != ProposalStatus.Active) {
            revert AetherMind__ProposalNotFound();
        }
        if (block.timestamp >= proposal.votingPeriodEnd) {
            revert AetherMind__VotingPeriodNotEnded();
        }
        if (proposal.hasVoted[_msgSender()]) {
            revert AetherMind__AlreadyVoted(); // One vote per researcher per proposal
        }

        uint256 votingPower = researchers[_msgSender()].reputationScore; // Using reputation as voting power
        if (votingPower == 0) { // Should not happen with onlyRegisteredResearcher but good safeguard
            revert AetherMind__NotSufficientReputation();
        }

        if (_support) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VotedOnProposal(_proposalId, _msgSender(), _support, votingPower);
    }

    /**
     * @dev Executes a proposal if its voting period has ended and it met the approval threshold.
     *      Anyone can call this function to trigger the execution.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0) || proposal.status != ProposalStatus.Active) {
            revert AetherMind__ProposalNotFound();
        }
        if (block.timestamp < proposal.votingPeriodEnd) {
            revert AetherMind__VotingPeriodActive(); // Voting period still active
        }

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        if (totalVotes == 0) {
            proposal.status = ProposalStatus.Failed;
            revert AetherMind__ProposalNotExecutable(); // No votes, cannot determine outcome
        }

        // Calculate percentage of 'for' votes
        uint256 votesForPercentage = (proposal.totalVotesFor * 10000) / totalVotes; // Multiply by 10000 for basis points

        if (votesForPercentage >= protocolParameters[PROPOSAL_PASS_THRESHOLD_PERCENTAGE]) {
            // Proposal passes, execute the parameter update
            protocolParameters[proposal.paramName] = proposal.newValue;
            proposal.status = ProposalStatus.Executed;
            emit ProtocolParameterUpdated(proposal.paramName, proposal.newValue);
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
            revert AetherMind__ProposalNotExecutable(); // Did not meet the required threshold
        }
    }

    // --- Additional Management/Helper Functions ---

    /**
     * @dev Emergency/upgrade function to set the ReputationSBT contract address.
     *      Only callable by the owner. Useful for upgrading the SBT contract.
     * @param _newSBTAddress The address of the new ReputationSBT contract.
     */
    function setReputationSBTContract(address _newSBTAddress) public onlyOwner {
        require(_newSBTAddress != address(0), "AetherMind: New SBT address cannot be zero");
        i_reputationSBT = IReputationSBT(_newSBTAddress);
    }

    /**
     * @dev Helper function to retrieve the current status of a task.
     * @param _taskId The ID of the task.
     * @return The current TaskStatus enum value.
     */
    function getTaskStatus(uint256 _taskId) public view returns(TaskStatus) {
        return aiTasks[_taskId].status;
    }
}
```