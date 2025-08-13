```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
                                VeritasNexus Protocol

Concept:
VeritasNexus is a decentralized protocol designed to create, validate, and curate
"Dynamic Knowledge NFTs" (DKNs). It integrates AI assistance, human curation,
a reputation system, and a gamified "Falsification Game" within a decentralized
autonomous organization (DAO) framework. The goal is to build a robust,
community-driven repository of verifiable and evolving knowledge artifacts.

Key Features:
- AI-Assisted Knowledge Generation: Leverage AI (via oracle) to bootstrap knowledge content.
- Human Refinement & Curation: Community members propose and vote on improvements
  to AI-generated or existing DKNs.
- Dynamic Knowledge NFTs (DKNs): ERC-721 compliant NFTs whose metadata and
  internal "veracity score" evolve based on community interactions (refinements,
  falsification challenges).
- Reputation System: Users earn non-transferable reputation for constructive
  contributions, accurate votes, and successful challenges, influencing their
  governance weight and rewards.
- Falsification Game: A gamified mechanism where participants stake tokens to
  challenge the veracity of DKNs. Successful falsifications improve knowledge
  accuracy and reward challengers.
- DAO Governance: The community governs protocol parameters, treasury funds, and
  approves major changes through a reputation-weighted voting system.
- Knowledge Licensing: DKN owners (contributors) can license their knowledge
  artifacts, generating royalties.

Outline:

1.  Interfaces:
    *   `IOracle`: Interface for the external AI Oracle.
2.  Events: Crucial for off-chain monitoring.
3.  Error Definitions: Custom errors for clarity and gas efficiency.
4.  Data Structures (Structs):
    *   `KnowledgeNFT`: Represents a DKN with its core properties and dynamic attributes.
    *   `AIRequest`: Tracks the state of AI knowledge generation requests.
    *   `RefinementProposal`: Details a proposed change to a DKN.
    *   `FalsificationChallenge`: Details a challenge to a DKN's veracity.
    *   `DAOProposal`: Details a governance proposal.
5.  State Variables: Stores the protocol's state.
6.  Modifiers: Access control and condition checks.
7.  Constructor: Initializes core parameters.
8.  ERC-721 Overrides: Standard functions for NFT management.
9.  Core Functionality Categories:
    *   I. AI-Assisted Knowledge Generation & DKN Minting
    *   II. Human Refinement & DKN Evolution
    *   III. Reputation System
    *   IV. "Falsification Game" & Veracity Challenges
    *   V. DAO Governance
    *   VI. Staking & Utility

*/

// --- Interfaces ---

interface IOracle {
    function requestAI(uint256 _requestId, string calldata _prompt) external returns (bool);
    // Potentially more functions for different AI models or tasks
}

// --- Errors ---

error VeritasNexus__InvalidRequestId();
error VeritasNexus__AIRequestNotCompleted();
error VeritasNexus__RefinementAlreadyVoted();
error VeritasNexus__RefinementVotingPeriodActive();
error VeritasNexus__RefinementVotingPeriodExpired();
error VeritasNexus__RefinementNotApproved();
error VeritasNexus__RefinementAlreadyExecuted();
error VeritasNexus__RefinementNotFound();
error VeritasNexus__ChallengeVotingPeriodActive();
error VeritasNexus__ChallengeVotingPeriodExpired();
error VeritasNexus__ChallengeNotFound();
error VeritasNexus__ChallengeAlreadyResolved();
error VeritasNexus__AlreadyStaked();
error VeritasNexus__InsufficientStake();
error VeritasNexus__NoStakeFound();
error VeritasNexus__CannotUnstakeWhileParticipating();
error VeritasNexus__CannotVoteOnOwnProposal();
error VeritasNexus__ProposalAlreadyVoted();
error VeritasNexus__ProposalVotingPeriodActive();
error VeritasNexus__ProposalVotingPeriodExpired();
error VeritasNexus__ProposalNotApproved();
error VeritasNexus__ProposalAlreadyExecuted();
error VeritasNexus__InvalidDAOProposalCall();
error VeritasNexus__InsufficientReputation();
error VeritasNexus__DKNNotFound();
error VeritasNexus__NotDKNOwner();
error VeritasNexus__LicensingNotActive();
error VeritasNexus__NoFeesToCollect();
error VeritasNexus__LicensingAlreadyActive();


contract VeritasNexus is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Global counters for unique IDs
    Counters.Counter private _dknIdCounter;
    Counters.Counter private _aiRequestIdCounter;
    Counters.Counter private _refinementIdCounter;
    Counters.Counter private _challengeIdCounter;
    Counters.Counter private _daoProposalIdCounter;

    // Address of the trusted AI oracle contract
    address public oracleAddress;

    // DKN Storage: Mapping from DKN ID to its struct
    mapping(uint256 => KnowledgeNFT) public knowledgeNFTs;

    // AI Request Storage: Mapping from AI Request ID to its struct
    mapping(uint256 => AIRequest) public aiRequests;

    // Refinement Proposal Storage: Mapping from Refinement ID to its struct
    mapping(uint256 => RefinementProposal) public refinementProposals;
    // Tracks votes on refinement proposals: proposalId => voterAddress => hasVoted
    mapping(uint256 => mapping(address => bool)) public hasVotedOnRefinement;

    // Falsification Challenge Storage: Mapping from Challenge ID to its struct
    mapping(uint256 => FalsificationChallenge) public falsificationChallenges;
    // Tracks stakes on falsification challenges: challengeId => stakerAddress => stakedAmount
    mapping(uint256 => mapping(address => uint256)) public userFalsificationStakes;
    // Tracks vote for falsification: challengeId => stakerAddress => supportsFalsification
    mapping(uint256 => mapping(address => bool)) public userFalsificationVote;


    // DAO Proposal Storage: Mapping from DAO Proposal ID to its struct
    mapping(uint256 => DAOProposal) public daoProposals;
    // Tracks votes on DAO proposals: proposalId => voterAddress => hasVoted
    mapping(uint256 => mapping(address => bool)) public hasVotedOnDAOProposal;

    // Reputation System: Mapping from user address to their reputation score (SBT-like)
    mapping(address => uint256) public userReputation;

    // Staking System: Mapping from user address to their staked ETH/MATIC
    mapping(address => uint256) public stakedFunds;

    // Protocol Parameters (DAO-governed)
    uint256 public minStakingAmount;           // Minimum stake to participate in voting/challenges
    uint256 public refinementVotingPeriod;     // Duration in seconds for refinement voting
    uint256 public falsificationVotingPeriod;  // Duration in seconds for falsification voting
    uint256 public daoVotingPeriod;            // Duration in seconds for DAO proposal voting
    uint256 public licensingFeePercentage;     // Percentage of fees taken for DKN licensing (e.g., 500 for 5%)
    uint256 public constant MAX_VERACITY_SCORE = 1000; // Max score for DKN veracity
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 100; // Min reputation to propose DAO change

    // --- Enums ---
    enum RequestStatus { PENDING, COMPLETED, FAILED }
    enum ProposalStatus { PENDING, APPROVED, REJECTED, EXECUTED }
    enum ChallengeStatus { PENDING, RESOLVED_TRUE, RESOLVED_FALSE }

    // --- Data Structures (Structs) ---

    struct KnowledgeNFT {
        uint256 dknId;
        string name;          // Name derived from topic or initial refinement
        string contentUri;    // URI to the DKN's current IPFS/Arweave content
        address owner;        // ERC721 owner
        uint256 veracityScore; // A score from 0 to MAX_VERACITY_SCORE (initially 500), reflecting accuracy
        uint256 refinementCount; // Number of times the DKN has been successfully refined
        uint256 initialAIRequestId; // Reference to the AI request that started it

        // Licensing
        bool isLicensed;
        address licensedTo;
        uint256 licenseExpiry;
        uint256 totalLicensedFees; // Accumulates fees for this DKN
    }

    struct AIRequest {
        uint256 requestId;
        address requester;
        string topicPrompt;
        string aiResponseData; // URI or direct data if small
        RequestStatus status;
        uint256 timestamp;
    }

    struct RefinementProposal {
        uint256 proposalId;
        uint256 dknId;
        address proposer;
        string refinementText; // Proposed new content or changes
        string rationale;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Internal tracker for individual votes
        uint256 startTime;
        ProposalStatus status;
        bool executed;
    }

    struct FalsificationChallenge {
        uint256 challengeId;
        uint256 dknId;
        address challenger;
        string challengeStatement;
        string evidenceUri;
        uint256 totalStakeForFalsification;
        uint256 totalStakeAgainstFalsification;
        uint256 startTime;
        ChallengeStatus status;
        bool resolved;
    }

    struct DAOProposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes targetCallData; // ABI-encoded function call for the proposal
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Internal tracker for individual votes
        uint256 startTime;
        ProposalStatus status;
        bool executed;
    }

    // --- Events ---

    event AIKnowledgeRequested(uint256 indexed requestId, address indexed requester, string topicPrompt);
    event AIResponseReceived(uint256 indexed requestId, string aiResponseData);
    event DKNMinted(uint256 indexed dknId, address indexed owner, string name, uint256 initialAIRequestId);
    event DKNRefinementProposed(uint256 indexed refinementId, uint256 indexed dknId, address indexed proposer);
    event DKNRefinementVoted(uint256 indexed refinementId, address indexed voter, bool approved, uint256 reputationWeight);
    event DKNRefinementExecuted(uint256 indexed refinementId, uint256 indexed dknId, ProposalStatus status);
    event DKNLicensingActivated(uint256 indexed dknId, address indexed licensedTo, uint256 expiryTime, uint256 feePercentage);
    event DKNLicenseFeesCollected(uint256 indexed dknId, address indexed collector, uint256 amount);

    event ReputationUpdated(address indexed user, uint256 newReputation, string reason);

    event FalsificationProposed(uint256 indexed challengeId, uint256 indexed dknId, address indexed challenger);
    event FalsificationStaked(uint256 indexed challengeId, address indexed staker, uint256 amount, bool supportsFalsification);
    event FalsificationResolved(uint256 indexed challengeId, uint256 indexed dknId, ChallengeStatus status, int256 veracityChange);

    event DAOProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event DAOProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 reputationWeight);
    event DAOProposalExecuted(uint256 indexed proposalId, ProposalStatus status);

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert OwnableUnauthorizedAccount(msg.sender); // Reusing Ownable error for unauthorized access
        }
        _;
    }

    modifier onlyStaked() {
        if (stakedFunds[msg.sender] < minStakingAmount) {
            revert VeritasNexus__InsufficientStake();
        }
        _;
    }

    modifier hasEnoughReputation(uint256 _requiredReputation) {
        if (userReputation[msg.sender] < _requiredReputation) {
            revert VeritasNexus__InsufficientReputation();
        }
        _;
    }

    // --- Constructor ---

    constructor(address _oracleAddress, uint256 _minStakingAmount, uint256 _refinementPeriod, uint256 _falsificationPeriod, uint256 _daoPeriod, uint256 _licensingFee)
        ERC721("VeritasNexus DKN", "VNDKN")
        Ownable(msg.sender)
    {
        oracleAddress = _oracleAddress;
        minStakingAmount = _minStakingAmount;
        refinementVotingPeriod = _refinementPeriod;
        falsificationVotingPeriod = _falsificationPeriod;
        daoVotingPeriod = _daoPeriod;
        licensingFeePercentage = _licensingFee;
        // Initial reputation for deployer, or perhaps first contributors
        _addReputation(msg.sender, 1000, "Initial Protocol Creator");
    }

    // --- ERC-721 Overrides (Standard, for DKNs) ---
    // ERC721Enumerable handles _approve, _transfer, _safeTransfer, tokenOfOwnerByIndex, totalSupply, tokenByIndex.

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Placeholder base URI for DKN content
    }

    // We override tokenURI to fetch the specific DKN's contentUri
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return knowledgeNFTs[tokenId].contentUri;
    }

    // --- Internal Reputation Management ---

    function _addReputation(address _user, uint256 _amount, string memory _reason) internal {
        userReputation[_user] = userReputation[_user].add(_amount);
        emit ReputationUpdated(_user, userReputation[_user], _reason);
    }

    function _deductReputation(address _user, uint256 _amount, string memory _reason) internal {
        userReputation[_user] = userReputation[_user].sub(_amount);
        emit ReputationUpdated(_user, userReputation[_user], _reason);
    }

    // --- I. AI-Assisted Knowledge Generation & DKN Minting ---

    /**
     * @notice Initiates a request to the AI oracle for knowledge generation on a given topic.
     * @param _topicPrompt The prompt or topic for the AI.
     * @return requestId The ID of the generated AI request.
     */
    function requestAIKnowledgeGeneration(string calldata _topicPrompt)
        external
        returns (uint256 requestId)
    {
        requestId = _aiRequestIdCounter.current();
        _aiRequestIdCounter.increment();

        aiRequests[requestId] = AIRequest({
            requestId: requestId,
            requester: msg.sender,
            topicPrompt: _topicPrompt,
            aiResponseData: "",
            status: RequestStatus.PENDING,
            timestamp: block.timestamp
        });

        // Call the external AI oracle contract
        IOracle(oracleAddress).requestAI(requestId, _topicPrompt);

        emit AIKnowledgeRequested(requestId, msg.sender, _topicPrompt);
    }

    /**
     * @notice (Callable by Oracle) Receives and stores the AI's generated knowledge data.
     * @dev This function is called by the trusted AI oracle after it processes the request.
     * @param _requestId The ID of the AI request.
     * @param _aiResponseData The AI-generated knowledge data (e.g., IPFS hash, direct text).
     * @param _estimatedGas An optional parameter from oracle for gas cost feedback (not used in logic).
     */
    function submitAIResponse(uint256 _requestId, string calldata _aiResponseData, uint256 _estimatedGas)
        external
        onlyOracle
    {
        AIRequest storage req = aiRequests[_requestId];
        if (req.requester == address(0) || req.status != RequestStatus.PENDING) {
            revert VeritasNexus__InvalidRequestId();
        }

        req.aiResponseData = _aiResponseData;
        req.status = RequestStatus.COMPLETED;

        emit AIResponseReceived(_requestId, _aiResponseData);
    }

    /**
     * @notice Mints a new Dynamic Knowledge NFT (DKN) from a completed AI generation request and initial human refinement.
     * @dev The caller becomes the initial DKN owner. Initial veracity is MAX_VERACITY_SCORE/2 (500).
     * @param _aiRequestId The ID of the completed AI request.
     * @param _initialRefinement The initial human curation/refinement of the AI's output (e.g., cleaned text, summary). This will be the initial contentURI.
     * @return dknId The ID of the newly minted DKN.
     */
    function mintDKN(uint256 _aiRequestId, string calldata _initialRefinement)
        external
        returns (uint256 dknId)
    {
        AIRequest storage aiReq = aiRequests[_aiRequestId];
        if (aiReq.status != RequestStatus.COMPLETED) {
            revert VeritasNexus__AIRequestNotCompleted();
        }
        if (aiReq.requester == address(0)) { // Ensure request exists
            revert VeritasNexus__InvalidRequestId();
        }

        dknId = _dknIdCounter.current();
        _dknIdCounter.increment();

        _safeMint(msg.sender, dknId); // Mints the ERC721 token

        // The name could be derived from _topicPrompt or _initialRefinement
        string memory dknName = string(abi.encodePacked("DKN #", Strings.toString(dknId), " - ", aiReq.topicPrompt));

        knowledgeNFTs[dknId] = KnowledgeNFT({
            dknId: dknId,
            name: dknName,
            contentUri: _initialRefinement, // Initial content from human refinement
            owner: msg.sender,
            veracityScore: MAX_VERACITY_SCORE / 2, // Start in the middle
            refinementCount: 0,
            initialAIRequestId: _aiRequestId,
            isLicensed: false,
            licensedTo: address(0),
            licenseExpiry: 0,
            totalLicensedFees: 0
        });

        // Mark AI request as used to prevent re-minting from same request
        aiReq.status = RequestStatus.FAILED; // Or a new status like 'USED'

        _addReputation(msg.sender, 50, "Minted DKN with initial refinement");
        emit DKNMinted(dknId, msg.sender, dknName, _aiRequestId);
    }

    // --- II. Human Refinement & DKN Evolution ---

    /**
     * @notice Proposes an improvement or correction to an existing DKN's content.
     * @dev Requires the proposer to be staked.
     * @param _dknId The ID of the DKN to be refined.
     * @param _refinementText The proposed new content or changes for the DKN (e.g., new IPFS hash).
     * @param _rationale A brief explanation for the proposed refinement.
     * @return refinementId The ID of the created refinement proposal.
     */
    function proposeRefinement(uint256 _dknId, string calldata _refinementText, string calldata _rationale)
        external
        onlyStaked
        returns (uint256 refinementId)
    {
        if (knowledgeNFTs[_dknId].owner == address(0)) {
            revert VeritasNexus__DKNNotFound();
        }

        refinementId = _refinementIdCounter.current();
        _refinementIdCounter.increment();

        refinementProposals[refinementId] = RefinementProposal({
            proposalId: refinementId,
            dknId: _dknId,
            proposer: msg.sender,
            refinementText: _refinementText,
            rationale: _rationale,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(), // Initialize mapping
            startTime: block.timestamp,
            status: ProposalStatus.PENDING,
            executed: false
        });

        emit DKNRefinementProposed(refinementId, _dknId, msg.sender);
    }

    /**
     * @notice Allows staked users to vote on a proposed DKN refinement. Votes are weighted by reputation.
     * @param _refinementId The ID of the refinement proposal.
     * @param _approve True to vote for approval, false for rejection.
     */
    function voteOnRefinement(uint256 _refinementId, bool _approve)
        external
        onlyStaked
    {
        RefinementProposal storage proposal = refinementProposals[_refinementId];
        if (proposal.proposer == address(0)) {
            revert VeritasNexus__RefinementNotFound();
        }
        if (proposal.status != ProposalStatus.PENDING) {
            revert VeritasNexus__RefinementVotingPeriodActive(); // Already resolved
        }
        if (block.timestamp >= proposal.startTime + refinementVotingPeriod) {
            revert VeritasNexus__RefinementVotingPeriodExpired();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert VeritasNexus__RefinementAlreadyVoted();
        }
        if (proposal.proposer == msg.sender) {
             revert VeritasNexus__CannotVoteOnOwnProposal();
        }

        uint256 weight = userReputation[msg.sender];
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(weight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(weight);
        }
        proposal.hasVoted[msg.sender] = true;

        emit DKNRefinementVoted(_refinementId, msg.sender, _approve, weight);
    }

    /**
     * @notice Finalizes a refinement proposal. Updates the DKN's content and `refinementCount`.
     * @dev Rewards voters and proposer, updates reputation. Anyone can call after voting period ends.
     * @param _refinementId The ID of the refinement proposal.
     */
    function executeRefinement(uint256 _refinementId)
        external
        nonReentrant
    {
        RefinementProposal storage proposal = refinementProposals[_refinementId];
        if (proposal.proposer == address(0)) {
            revert VeritasNexus__RefinementNotFound();
        }
        if (proposal.executed) {
            revert VeritasNexus__RefinementAlreadyExecuted();
        }
        if (block.timestamp < proposal.startTime + refinementVotingPeriod) {
            revert VeritasNexus__RefinementVotingPeriodActive(); // Voting period not over
        }

        KnowledgeNFT storage dkn = knowledgeNFTs[proposal.dknId];
        if (dkn.owner == address(0)) { // Sanity check
            revert VeritasNexus__DKNNotFound();
        }

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalVotes == 0) { // No votes, proposal expires without effect
            proposal.status = ProposalStatus.REJECTED;
        } else if (proposal.votesFor > proposal.votesAgainst) {
            // Refinement approved
            dkn.contentUri = proposal.refinementText;
            dkn.refinementCount = dkn.refinementCount.add(1);
            proposal.status = ProposalStatus.APPROVED;
            _addReputation(proposal.proposer, 20, "Successful DKN refinement proposal");
            // Reward all voters proportionately or a fixed amount. For simplicity, just add reputation.
        } else {
            // Refinement rejected
            proposal.status = ProposalStatus.REJECTED;
            _deductReputation(proposal.proposer, 5, "Unsuccessful DKN refinement proposal");
        }
        proposal.executed = true;

        emit DKNRefinementExecuted(_refinementId, proposal.dknId, proposal.status);
    }

    /**
     * @notice Allows the DKN owner to set up a licensing agreement for the knowledge artifact.
     * @dev Sets a recipient for licensing, a duration, and activates licensing.
     * @param _dknId The ID of the DKN to license.
     * @param _durationInDays The duration of the license in days.
     */
    function licenseDKN(uint256 _dknId, uint256 _durationInDays)
        external
        nonReentrant
    {
        KnowledgeNFT storage dkn = knowledgeNFTs[_dknId];
        if (dkn.owner == address(0)) {
            revert VeritasNexus__DKNNotFound();
        }
        if (dkn.owner != msg.sender) {
            revert VeritasNexus__NotDKNOwner();
        }
        if (dkn.isLicensed && dkn.licenseExpiry > block.timestamp) {
            revert VeritasNexus__LicensingAlreadyActive();
        }

        dkn.isLicensed = true;
        dkn.licensedTo = msg.sender; // The owner licenses it, they collect fees
        dkn.licenseExpiry = block.timestamp.add(_durationInDays.mul(1 days));

        emit DKNLicensingActivated(_dknId, msg.sender, dkn.licenseExpiry, licensingFeePercentage);
    }

    /**
     * @notice Allows the DKN owner and original contributors to collect accumulated licensing fees.
     * @dev The contract would need to receive ETH/MATIC for licensing. For simplicity,
     *      this function assumes external payments were made and registered, or
     *      it collects from a dedicated fee pool that VeritasNexus manages.
     *      For this example, we assume `totalLicensedFees` is incremented by some
     *      off-chain or external process.
     * @param _dknId The ID of the DKN.
     */
    function collectLicenseFees(uint256 _dknId)
        external
        nonReentrant
    {
        KnowledgeNFT storage dkn = knowledgeNFTs[_dknId];
        if (dkn.owner == address(0)) {
            revert VeritasNexus__DKNNotFound();
        }
        if (dkn.owner != msg.sender) {
            revert VeritasNexus__NotDKNOwner();
        }
        if (!dkn.isLicensed || dkn.licenseExpiry < block.timestamp) {
            revert VeritasNexus__LicensingNotActive();
        }
        if (dkn.totalLicensedFees == 0) {
            revert VeritasNexus__NoFeesToCollect();
        }

        uint256 amountToCollect = dkn.totalLicensedFees;
        dkn.totalLicensedFees = 0; // Reset accumulated fees

        (bool success, ) = payable(msg.sender).call{value: amountToCollect}("");
        require(success, "VeritasNexus: Failed to send collected fees");

        emit DKNLicenseFeesCollected(_dknId, msg.sender, amountToCollect);
    }

    // --- III. Reputation System ---
    // (Internal functions for reputation updates, external for viewing)

    /**
     * @notice Returns the current reputation score of a given user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    // --- IV. "Falsification Game" & Veracity Challenges ---

    /**
     * @notice Initiates a challenge against the veracity or accuracy of a DKN.
     * @dev Requires a statement outlining the challenge and external evidence URI. Requires proposer to be staked.
     * @param _dknId The ID of the DKN to challenge.
     * @param _challengeStatement A statement detailing the inaccuracy.
     * @param _evidenceUri URI to external evidence supporting the challenge.
     * @return challengeId The ID of the created falsification challenge.
     */
    function proposeFalsification(uint256 _dknId, string calldata _challengeStatement, string calldata _evidenceUri)
        external
        onlyStaked
        returns (uint256 challengeId)
    {
        if (knowledgeNFTs[_dknId].owner == address(0)) {
            revert VeritasNexus__DKNNotFound();
        }

        challengeId = _challengeIdCounter.current();
        _challengeIdCounter.increment();

        falsificationChallenges[challengeId] = FalsificationChallenge({
            challengeId: challengeId,
            dknId: _dknId,
            challenger: msg.sender,
            challengeStatement: _challengeStatement,
            evidenceUri: _evidenceUri,
            totalStakeForFalsification: 0,
            totalStakeAgainstFalsification: 0,
            startTime: block.timestamp,
            status: ChallengeStatus.PENDING,
            resolved: false
        });

        emit FalsificationProposed(challengeId, _dknId, msg.sender);
    }

    /**
     * @notice Allows users to stake funds to support or refute a falsification claim.
     * @dev Staking amount is deducted from user's `stakedFunds`.
     * @param _challengeId The ID of the falsification challenge.
     * @param _supportsFalsification True if supporting the challenge, false if refuting it.
     */
    function stakeOnFalsification(uint256 _challengeId, bool _supportsFalsification)
        external
        payable
        onlyStaked
        nonReentrant
    {
        FalsificationChallenge storage challenge = falsificationChallenges[_challengeId];
        if (challenge.challenger == address(0)) {
            revert VeritasNexus__ChallengeNotFound();
        }
        if (challenge.resolved) {
            revert VeritasNexus__ChallengeAlreadyResolved();
        }
        if (block.timestamp >= challenge.startTime + falsificationVotingPeriod) {
            revert VeritasNexus__ChallengeVotingPeriodExpired();
        }
        if (msg.value == 0) { // Require some stake
            revert VeritasNexus__InsufficientStake(); // Or custom error
        }

        if (userFalsificationStakes[_challengeId][msg.sender] > 0) {
            // Already staked, update stake
            if (userFalsificationVote[_challengeId][msg.sender] != _supportsFalsification) {
                revert VeritasNexus__RefinementAlreadyVoted(); // Cant change vote on same challenge
            }
        }

        userFalsificationStakes[_challengeId][msg.sender] = userFalsificationStakes[_challengeId][msg.sender].add(msg.value);
        if (_supportsFalsification) {
            challenge.totalStakeForFalsification = challenge.totalStakeForFalsification.add(msg.value);
        } else {
            challenge.totalStakeAgainstFalsification = challenge.totalStakeAgainstFalsification.add(msg.value);
        }
        userFalsificationVote[_challengeId][msg.sender] = _supportsFalsification; // Record voter's stance

        stakedFunds[msg.sender] = stakedFunds[msg.sender].add(msg.value); // Add to user's total staked funds

        emit FalsificationStaked(_challengeId, msg.sender, msg.value, _supportsFalsification);
    }

    /**
     * @notice Resolves a falsification challenge based on the majority stake.
     * @dev Updates the DKN's `veracityScore`, distributes rewards/penalties, and adjusts reputations.
     *      Anyone can call after voting period ends.
     * @param _challengeId The ID of the falsification challenge.
     */
    function resolveFalsificationChallenge(uint256 _challengeId)
        external
        nonReentrant
    {
        FalsificationChallenge storage challenge = falsificationChallenges[_challengeId];
        if (challenge.challenger == address(0)) {
            revert VeritasNexus__ChallengeNotFound();
        }
        if (challenge.resolved) {
            revert VeritasNexus__ChallengeAlreadyResolved();
        }
        if (block.timestamp < challenge.startTime + falsificationVotingPeriod) {
            revert VeritasNexus__ChallengeVotingPeriodActive();
        }

        KnowledgeNFT storage dkn = knowledgeNFTs[challenge.dknId];
        if (dkn.owner == address(0)) {
            revert VeritasNexus__DKNNotFound(); // Sanity check
        }

        uint256 veracityChange = 0;
        int256 veracityDelta = 0;
        ChallengeStatus newStatus;

        if (challenge.totalStakeForFalsification > challenge.totalStakeAgainstFalsification) {
            // Falsification successful: DKN's veracity score decreases
            newStatus = ChallengeStatus.RESOLVED_TRUE;
            veracityChange = 50; // Example value, could be dynamic
            if (dkn.veracityScore > veracityChange) {
                dkn.veracityScore = dkn.veracityScore.sub(veracityChange);
            } else {
                dkn.veracityScore = 0;
            }
            veracityDelta = -int256(veracityChange);

            // Reward supporters of falsification, penalize refuters
            _addReputation(challenge.challenger, 30, "Successful falsification challenge");
            // Distribute staked funds to winners proportionally (complex, simplified for example)
            // For simplicity, just return stakes to winners and burn/DAO collect losers' stakes
            // Or better, winners split losers' stakes + a base reward.
        } else if (challenge.totalStakeAgainstFalsification > challenge.totalStakeForFalsification) {
            // Falsification failed: DKN's veracity score increases (it withstood challenge)
            newStatus = ChallengeStatus.RESOLVED_FALSE;
            veracityChange = 20; // Example value
            if (dkn.veracityScore.add(veracityChange) <= MAX_VERACITY_SCORE) {
                dkn.veracityScore = dkn.veracityScore.add(veracityChange);
            } else {
                dkn.veracityScore = MAX_VERACITY_SCORE;
            }
            veracityDelta = int256(veracityChange);

            // Reward refuters of falsification, penalize challenger
            _deductReputation(challenge.challenger, 10, "Unsuccessful falsification challenge");
            // Distribute staked funds to winners proportionally
        } else {
            // Tie or no stakes: No change, funds returned (simple example: no change, no rewards/penalties)
            newStatus = ChallengeStatus.RESOLVED_FALSE; // Or a specific 'TIED' status
            // All stakes returned for simplicity if tie or no stakes
        }

        challenge.status = newStatus;
        challenge.resolved = true;

        // Simplified stake distribution: In real system, this would iterate through stakers
        // For actual implementation, would need to store all individual stakes and their stance
        // For now, we assume stakes are transferred/managed by the DAO for rewards/penalties

        emit FalsificationResolved(_challengeId, challenge.dknId, newStatus, veracityDelta);
    }

    // --- V. DAO Governance ---

    /**
     * @notice Allows a user with sufficient reputation to propose a change to protocol parameters or treasury operations.
     * @param _description A human-readable description of the proposal.
     * @param _targetCallData ABI-encoded function call to be executed on `VeritasNexus` contract upon approval.
     * @return proposalId The ID of the created DAO proposal.
     */
    function proposeProtocolChange(string calldata _description, bytes calldata _targetCallData)
        external
        hasEnoughReputation(MIN_REPUTATION_FOR_PROPOSAL)
        returns (uint256 proposalId)
    {
        proposalId = _daoProposalIdCounter.current();
        _daoProposalIdCounter.increment();

        daoProposals[proposalId] = DAOProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            targetCallData: _targetCallData,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(), // Initialize mapping
            startTime: block.timestamp,
            status: ProposalStatus.PENDING,
            executed: false
        });

        emit DAOProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @notice Allows staked users to vote on a DAO governance proposal. Votes are weighted by reputation.
     * @param _proposalId The ID of the DAO proposal.
     * @param _approve True to vote for approval, false for rejection.
     */
    function voteOnProtocolChange(uint256 _proposalId, bool _approve)
        external
        onlyStaked
    {
        DAOProposal storage proposal = daoProposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert VeritasNexus__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.PENDING) {
            revert VeritasNexus__ProposalVotingPeriodActive(); // Already resolved
        }
        if (block.timestamp >= proposal.startTime + daoVotingPeriod) {
            revert VeritasNexus__ProposalVotingPeriodExpired();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert VeritasNexus__ProposalAlreadyVoted();
        }
        if (proposal.proposer == msg.sender) {
            revert VeritasNexus__CannotVoteOnOwnProposal();
        }

        uint256 weight = userReputation[msg.sender];
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(weight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(weight);
        }
        proposal.hasVoted[msg.sender] = true;

        emit DAOProposalVoted(_proposalId, msg.sender, _approve, weight);
    }

    /**
     * @notice Executes a successfully voted-on DAO proposal.
     * @dev Anyone can call after voting period ends.
     * @param _proposalId The ID of the DAO proposal.
     */
    function executeProtocolChange(uint256 _proposalId)
        external
        nonReentrant
    {
        DAOProposal storage proposal = daoProposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert VeritasNexus__ProposalNotFound();
        }
        if (proposal.executed) {
            revert VeritasNexus__ProposalAlreadyExecuted();
        }
        if (block.timestamp < proposal.startTime + daoVotingPeriod) {
            revert VeritasNexus__ProposalVotingPeriodActive();
        }

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalVotes == 0) {
            proposal.status = ProposalStatus.REJECTED; // No votes, proposal expires
        } else if (proposal.votesFor > proposal.votesAgainst) {
            // Proposal approved, execute the call
            (bool success, ) = address(this).call(proposal.targetCallData);
            if (!success) {
                revert VeritasNexus__InvalidDAOProposalCall();
            }
            proposal.status = ProposalStatus.APPROVED;
            _addReputation(proposal.proposer, 50, "Successful DAO proposal");
        } else {
            // Proposal rejected
            proposal.status = ProposalStatus.REJECTED;
            _deductReputation(proposal.proposer, 10, "Unsuccessful DAO proposal");
        }
        proposal.executed = true;

        emit DAOProposalExecuted(_proposalId, proposal.status);
    }

    /**
     * @notice (Callable by DAO via `executeProtocolChange`) Updates the trusted AI oracle address.
     * @param _newOracleAddress The new address for the AI oracle.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner { // Changed from onlyDAO for simplicity with initial setup
        oracleAddress = _newOracleAddress;
        // In a full DAO, this would be callable only by executeProtocolChange
        // For now, it's owned by deployer to allow initial setup.
        // A real DAO would transfer ownership of this function to the DAO contract itself.
    }

    /**
     * @notice (Callable by DAO via `executeProtocolChange`) Adjusts the minimum ETH/MATIC required for staking.
     * @param _newAmount The new minimum staking amount in wei.
     */
    function setMinimumStakingAmount(uint256 _newAmount) external onlyOwner { // Same as above, temporary onlyOwner
        minStakingAmount = _newAmount;
    }

    /**
     * @notice Allows the DAO to withdraw funds from the contract treasury.
     * @dev This function would typically be called by `executeProtocolChange` as part of a DAO proposal.
     *      It's marked `onlyOwner` for initial testing/setup, but the intention is for DAO control.
     * @param _to The address to send funds to.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawDAOFunds(address _to, uint256 _amount) external onlyOwner nonReentrant { // Temporary onlyOwner
        require(address(this).balance >= _amount, "VeritasNexus: Insufficient contract balance");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "VeritasNexus: Failed to withdraw DAO funds");
    }

    // --- VI. Staking & Utility ---

    /**
     * @notice Allows users to stake native currency (ETH/MATIC) to participate in voting, proposals, and challenges.
     */
    function stakeForParticipation() external payable nonReentrant {
        if (msg.value == 0) {
            revert VeritasNexus__InsufficientStake();
        }
        stakedFunds[msg.sender] = stakedFunds[msg.sender].add(msg.value);
        emit Staked(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to unstake their native currency.
     * @dev Users cannot unstake if they are actively participating in a challenge or proposal (simplified).
     * @param _amount The amount to unstake.
     */
    function unstakeParticipation(uint256 _amount) external nonReentrant {
        if (stakedFunds[msg.sender] == 0 || stakedFunds[msg.sender] < _amount) {
            revert VeritasNexus__NoStakeFound();
        }
        // In a real system, you'd check active participation:
        // iterate through active proposals/challenges to ensure user isn't needed.
        // For simplicity, this is omitted.
        // For example:
        // require(user not actively staking on falsification challenge and is not active voter on DAO/Refinement)
        // This is complex logic that would require more state tracking.
        // For this example, we assume users manage their unstaking wisely.

        stakedFunds[msg.sender] = stakedFunds[msg.sender].sub(_amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "VeritasNexus: Failed to unstake");

        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @notice View function to retrieve all dynamic properties of a specific DKN.
     * @param _dknId The ID of the DKN.
     * @return name The name of the DKN.
     * @return contentUri The current content URI of the DKN.
     * @return owner The current owner of the DKN.
     * @return veracityScore The current veracity score.
     * @return refinementCount The number of times the DKN has been refined.
     * @return initialAIRequestId The ID of the initial AI request.
     * @return isLicensed True if the DKN is currently licensed.
     * @return licensedTo The address the DKN is licensed to.
     * @return licenseExpiry The timestamp when the license expires.
     * @return totalLicensedFees The total fees accumulated for this DKN.
     */
    function getDKNProperties(uint256 _dknId)
        external
        view
        returns (string memory name, string memory contentUri, address owner, uint256 veracityScore, uint256 refinementCount, uint256 initialAIRequestId, bool isLicensed, address licensedTo, uint256 licenseExpiry, uint256 totalLicensedFees)
    {
        KnowledgeNFT storage dkn = knowledgeNFTs[_dknId];
        if (dkn.owner == address(0)) {
            revert VeritasNexus__DKNNotFound();
        }
        return (
            dkn.name,
            dkn.contentUri,
            dkn.owner,
            dkn.veracityScore,
            dkn.refinementCount,
            dkn.initialAIRequestId,
            dkn.isLicensed,
            dkn.licensedTo,
            dkn.licenseExpiry,
            dkn.totalLicensedFees
        );
    }

    /**
     * @notice View function to retrieve the current content URI of a specific DKN.
     * @param _dknId The ID of the DKN.
     * @return The content URI (e.g., IPFS hash).
     */
    function getDKNContent(uint256 _dknId) external view returns (string memory) {
        if (knowledgeNFTs[_dknId].owner == address(0)) {
            revert VeritasNexus__DKNNotFound();
        }
        return knowledgeNFTs[_dknId].contentUri;
    }

    /**
     * @notice View function to get the status of an AI generation request.
     * @param _requestId The ID of the AI request.
     * @return requester The address that made the request.
     * @return topicPrompt The original prompt.
     * @return aiResponseData The AI's response data (if completed).
     * @return status The current status of the request.
     */
    function getAIRequestStatus(uint256 _requestId)
        external
        view
        returns (address requester, string memory topicPrompt, string memory aiResponseData, RequestStatus status)
    {
        AIRequest storage req = aiRequests[_requestId];
        if (req.requester == address(0)) {
            revert VeritasNexus__InvalidRequestId();
        }
        return (req.requester, req.topicPrompt, req.aiResponseData, req.status);
    }

    /**
     * @notice View function to get the status and details of a refinement proposal.
     * @param _refinementId The ID of the refinement proposal.
     * @return dknId The DKN ID it targets.
     * @return proposer The address of the proposer.
     * @return refinementText The proposed text.
     * @return votesFor Current votes for.
     * @return votesAgainst Current votes against.
     * @return startTime The start time of voting.
     * @return status The current status.
     * @return executed True if executed.
     */
    function getRefinementProposalStatus(uint256 _refinementId)
        external
        view
        returns (uint256 dknId, address proposer, string memory refinementText, uint256 votesFor, uint256 votesAgainst, uint256 startTime, ProposalStatus status, bool executed)
    {
        RefinementProposal storage proposal = refinementProposals[_refinementId];
        if (proposal.proposer == address(0)) {
            revert VeritasNexus__RefinementNotFound();
        }
        return (proposal.dknId, proposal.proposer, proposal.refinementText, proposal.votesFor, proposal.votesAgainst, proposal.startTime, proposal.status, proposal.executed);
    }
}
```