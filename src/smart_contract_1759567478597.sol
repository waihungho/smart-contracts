This smart contract, "Aetherium Oracle & Generative Protocol," combines several advanced and trendy concepts: a decentralized, AI-augmented "truth oracle," dynamic reputation, and generative, evolving NFTs. It aims to create a unique ecosystem where verifiable insights influence the creation and evolution of digital assets.

It leverages a decentralized oracle network for off-chain AI computation and real-world data resolution, uses a staking mechanism for propositions, and implements a dynamic reputation system. The most innovative aspect is the "Aetherium Constructs" – ERC721 NFTs whose metadata and characteristics dynamically evolve based on linked verifiable propositions and AI analyses from the protocol's knowledge pool.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For uint256 clarity
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI

// Placeholder for a verifiable oracle interface that can fulfill requests
// In a real scenario, this would align with a specific oracle solution like Chainlink Functions.
interface IVerifiableOracle {
    // Function to request off-chain data/computation. Returns a requestId to track the request.
    function requestData(bytes32 _jobId, bytes calldata _payload) external returns (bytes32 requestId);
    // fulfillData function would be called by the oracle itself, via a dedicated callback function in this contract.
}

/**
 * @title Aetherium Oracle & Generative Protocol
 * @dev This smart contract is a decentralized, AI-augmented "truth oracle" and a platform for generating
 *      dynamic, evolving on-chain assets (Aetherium Constructs) based on verifiable insights and collective intelligence.
 *      It integrates off-chain AI computation via a trusted oracle network and utilizes a reputation/staking mechanism
 *      to ensure data integrity. It also features adaptive parameters to govern its own evolution.
 *      This contract strives for unique logic by combining these concepts in a novel way,
 *      avoiding direct duplication of existing open-source projects in its core functionalities.
 *      (Note: It uses standard OpenZeppelin ERC721, Ownable, IERC20, SafeMath, and Strings as building blocks,
 *      but the specific business logic for proposition resolution, AI integration flow, reputation updates,
 *      dynamic NFT mechanics, and adaptive parameter handling is custom).
 */
contract AetheriumOracleAndGenerativeProtocol is ERC721, Ownable {
    using SafeMath for uint256;
    using SafeMathInt256 for int256; // Custom library for int256 operations

    // --- Outline and Function Summary ---

    // I. Protocol Core & Governance
    // 1. constructor(): Initializes the contract, owner, base token, and initial protocol parameters.
    // 2. updateProtocolParameter(bytes32 _paramKey, uint256 _newValue): Allows governance (owner/DAO) to adjust protocol parameters.
    // 3. setOracleAddress(address _newOracle): Sets the address of the verifiable oracle gateway.
    // 4. setTrustedOracleCallback(address _callbackAddress): Sets the specific address allowed to call oracle fulfillment functions.
    // 5. setPaymentToken(address _token): Sets the ERC20 token used for staking, fees, and rewards.
    // 6. getProtocolParameter(bytes32 _paramKey): Views the current value of a given protocol parameter.

    // II. Oracle & AI Integration
    // 7. requestAIAnalysis(uint256 _propositionId, bytes32 _modelId, bytes calldata _modelInput): Requests off-chain AI analysis for a proposition, requiring payment.
    // 8. fulfillAIAnalysis(bytes32 _requestId, bytes calldata _aiOutput, uint256 _propositionId): Trusted oracle callback to deliver AI analysis results.
    // 9. registerAIModel(bytes32 _modelIdentifier, bytes32 _oracleJobId, uint256 _fee): Registers a new AI model with its oracle details and fee.
    // 10. deregisterAIModel(bytes32 _modelIdentifier): Deregisters an AI model, making it inactive.

    // III. Knowledge Pool & Proposition Management
    // 11. submitProposition(string calldata _statement, uint256 _expiryTimestamp, bytes32 _categoryHash, uint256 _initialStake): Users submit a statement/prediction, requiring an initial stake.
    // 12. attestToProposition(uint256 _propositionId, uint256 _stakeAmount): Users stake on a proposition being true/accurate.
    // 13. disputeProposition(uint256 _propositionId, uint256 _stakeAmount): Users stake on a proposition being false/inaccurate.
    // 14. requestPropositionResolution(uint256 _propositionId): Triggers the final resolution process for a proposition, sending a request to the oracle.
    // 15. fulfillPropositionResolution(bytes32 _requestId, bool _isTrue, uint256 _propositionId): Trusted oracle callback to deliver final resolution.
    // 16. claimPropositionRewards(uint256 _propositionId): Allows users to claim rewards or recover stakes after a proposition is resolved, updating their reputation.
    // 17. getPropositionDetails(uint256 _propositionId): Views comprehensive details of a specific proposition.

    // IV. Reputation System
    // 18. getUserReputation(address _user): Views a user's current reputation score.
    // 19. _updateUserReputation(address _user, int256 _change): Internal function to modify user reputation based on performance.

    // V. Generative Aetherium Constructs (NFTs)
    // 20. mintConstruct(uint256 _basePropositionId): Mints a new ERC721 Aetherium Construct linked to a foundational, resolved proposition.
    // 21. linkPropositionToConstruct(uint256 _tokenId, uint256 _propositionId): Allows the owner of a Construct to link additional resolved propositions, influencing its evolution.
    // 22. triggerConstructEvolution(uint256 _tokenId, bytes calldata _evolutionParams): Initiates a significant "evolution" of a Construct, recalculating its traits.
    // 23. tokenURI(uint256 _tokenId) override view returns (string memory): Overrides ERC721's tokenURI to provide dynamic metadata pointing to an off-chain service.

    // VI. Adaptive Protocol & Parameter Management (Simplified DAO-like)
    // 24. proposeParameterChange(bytes32 _paramKey, uint256 _newValue, uint256 _votingPeriod): Initiates a proposal for a parameter change by a user with sufficient reputation.
    // 25. voteOnParameterChange(uint256 _proposalId, bool _approve): Allows users with sufficient reputation to vote on an active parameter change proposal.
    // 26. executeParameterChange(uint256 _proposalId): Executes a passed parameter change proposal after the voting period ends.

    // --- State Variables & Data Structures ---

    IERC20 public paymentToken;
    IVerifiableOracle public verifiableOracle;
    address public trustedOracleCallback; // Address allowed to call fulfill functions (e.g., Chainlink's Oracle address)

    // Global protocol parameters, adjustable by governance or adaptive logic
    mapping(bytes32 => uint256) public protocolParameters;

    // Parameter keys (for clarity and consistency)
    bytes32 constant MIN_PROPOSITION_STAKE_PARAM = "minPropositionStake";
    bytes32 constant PROPOSITION_RESOLUTION_FEE_PARAM = "propositionResolutionFee";
    bytes32 constant REPUTATION_GAIN_PER_CORRECT_STAKE_PARAM = "reputationGainCorrect";
    bytes32 constant REPUTATION_LOSS_PER_INCORRECT_STAKE_PARAM = "reputationLossIncorrect";
    bytes32 constant VOTING_THRESHOLD_REPUTATION_PARAM = "votingThresholdReputation";
    bytes32 constant PROPOSAL_VOTING_PERIOD_PARAM = "proposalVotingPeriod";

    uint256 public nextPropositionId = 1;
    uint256 public nextProposalId = 1;

    // --- Structures ---

    enum PropositionStatus {
        Open,                 // Open for attestation/dispute
        AwaitingAI,           // AI analysis requested and pending
        AwaitingResolution,   // External oracle resolution requested and pending
        ResolvedTrue,         // Resolved as true
        ResolvedFalse,        // Resolved as false
        Cancelled             // Cancelled due to expiry, or other protocol-defined conditions
    }

    struct Proposition {
        uint256 id;
        address proposer;
        string statement;
        uint256 expiryTimestamp;
        bytes32 categoryHash; // For filtering/grouping (e.g., hash of "market_prediction", "scientific_claim")
        uint256 submissionTimestamp;
        PropositionStatus status;
        uint256 totalAttestationStake; // Sum of all stakes believing it's true
        uint256 totalDisputeStake;     // Sum of all stakes believing it's false
        mapping(address => uint256) attesters; // user => stake amount, for those who attested
        mapping(address => uint256) disputers; // user => stake amount, for those who disputed
        bool finalResolution;          // true if resolved true, false if resolved false (only valid if status is ResolvedTrue/False)
        bytes32 currentOracleRequestId; // Request ID for any pending oracle request (AI or Resolution)
        bytes aiOutput;                 // Stored raw output from AI analysis (if requested)
        uint256 resolvedTimestamp;
    }
    mapping(uint256 => Proposition) public propositions; // propositionId => Proposition details

    struct UserReputation {
        int256 score;
        uint256 lastActivityTimestamp;
        // Future extensions: correct_predictions_count, incorrect_predictions_count, etc.
    }
    mapping(address => UserReputation) public userReputations; // user address => Reputation details

    struct AIModel {
        bytes32 oracleJobId;         // The specific Job ID on the oracle network for this model
        uint256 fee;                 // Cost in paymentToken to request analysis from this model
        bool isActive;               // Whether the model is currently available for requests
    }
    mapping(bytes32 => AIModel) public registeredAIModels; // modelIdentifier (e.g., hash of "sentiment_analyzer") => AIModel details

    struct Construct {
        uint256 basePropositionId;
        uint256 mintedTimestamp;
        uint256 lastEvolutionTimestamp;
        mapping(uint256 => bool) linkedPropositions; // Mapping of linked proposition IDs (propId => true)
        bytes32 currentTraitsHash; // A unique hash representing the current dynamic traits of the NFT
    }
    mapping(uint256 => Construct) public constructs; // tokenId => Construct details
    uint256 public nextTokenId = 1;

    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    struct ParameterChangeProposal {
        uint256 id;
        address proposer;
        bytes32 paramKey;
        uint256 newValue;
        uint256 proposalTimestamp;
        uint256 votingEndsTimestamp;
        uint256 yesVotes; // Total reputation-weighted "yes" votes, simplified to count of voters for this example
        uint256 noVotes;  // Total reputation-weighted "no" votes, simplified to count of voters for this example
        ProposalStatus status;
        mapping(address => bool) hasVoted; // User => Has voted on this proposal
    }
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;


    // --- Events ---

    event ParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event OracleAddressSet(address indexed newOracle);
    event TrustedOracleCallbackSet(address indexed newCallbackAddress);
    event PaymentTokenSet(address indexed newToken);
    event PropositionSubmitted(uint256 indexed propositionId, address indexed proposer, string statement, uint256 expiryTimestamp);
    event PropositionStaked(uint256 indexed propositionId, address indexed staker, uint256 amount, bool isAttestation);
    event AIAnalysisRequested(uint256 indexed propositionId, bytes32 indexed requestId, bytes32 modelId);
    event AIAnalysisFulfilled(uint256 indexed propositionId, bytes32 indexed requestId, bytes aiOutput);
    event PropositionResolutionRequested(uint256 indexed propositionId, bytes32 indexed requestId);
    event PropositionResolved(uint256 indexed propositionId, bool indexed finalResolution);
    event PropositionRewardsClaimed(uint256 indexed propositionId, address indexed claimant, uint256 amount);
    event ReputationUpdated(address indexed user, int256 oldScore, int256 newScore);
    event ConstructMinted(uint256 indexed tokenId, address indexed owner, uint256 basePropositionId);
    event ConstructLinkedProposition(uint256 indexed tokenId, uint256 indexed propositionId);
    event ConstructEvolutionTriggered(uint256 indexed tokenId, bytes32 newTraitsHash);
    event AIModelRegistered(bytes32 indexed modelIdentifier, bytes32 oracleJobId, uint256 fee);
    event AIModelDeregistered(bytes32 indexed modelIdentifier);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 indexed paramKey, uint256 newValue, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool decision);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 indexed paramKey, uint256 newValue);


    // --- Modifiers ---

    modifier onlyTrustedOracleCallback() {
        require(msg.sender == trustedOracleCallback, "Aetherium: Not trusted oracle callback");
        _;
    }

    modifier onlyConstructOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Aetherium: Not construct owner");
        _;
    }

    // --- Constructor ---

    constructor(
        address _paymentToken,
        address _verifiableOracle,
        address _trustedOracleCallback,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_paymentToken != address(0), "Aetherium: Invalid payment token address");
        require(_verifiableOracle != address(0), "Aetherium: Invalid oracle address");
        require(_trustedOracleCallback != address(0), "Aetherium: Invalid oracle callback address");

        paymentToken = IERC20(_paymentToken);
        verifiableOracle = IVerifiableOracle(_verifiableOracle);
        trustedOracleCallback = _trustedOracleCallback;

        // Initialize default protocol parameters (can be updated by governance)
        protocolParameters[MIN_PROPOSITION_STAKE_PARAM] = 100 * 10**18; // 100 tokens
        protocolParameters[PROPOSITION_RESOLUTION_FEE_PARAM] = 10 * 10**18; // 10 tokens
        protocolParameters[REPUTATION_GAIN_PER_CORRECT_STAKE_PARAM] = 100; // 100 points
        protocolParameters[REPUTATION_LOSS_PER_INCORRECT_STAKE_PARAM] = 50; // 50 points
        protocolParameters[VOTING_THRESHOLD_REPUTATION_PARAM] = 500; // 500 reputation points (min for proposing/voting)
        protocolParameters[PROPOSAL_VOTING_PERIOD_PARAM] = 3 days; // 3 days for voting

        emit PaymentTokenSet(_paymentToken);
        emit OracleAddressSet(_verifiableOracle);
        emit TrustedOracleCallbackSet(_trustedOracleCallback);
    }

    // --- I. Protocol Core & Governance ---

    /**
     * @dev Allows governance (owner/DAO) to adjust core protocol parameters.
     *      In a full DAO implementation, this would typically follow a successful governance vote.
     * @param _paramKey The unique key identifying the parameter (e.g., "minPropositionStake").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramKey, uint256 _newValue) public onlyOwner {
        protocolParameters[_paramKey] = _newValue;
        emit ParameterUpdated(_paramKey, _newValue);
    }

    /**
     * @dev Sets the address of the verifiable oracle gateway contract. Only callable by owner.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "Aetherium: Invalid oracle address");
        verifiableOracle = IVerifiableOracle(_newOracle);
        emit OracleAddressSet(_newOracle);
    }

    /**
     * @dev Sets the specific address that is allowed to call `fulfill` functions.
     *      This is crucial for security, typically set to the oracle network's callback address.
     * @param _callbackAddress The new trusted oracle callback address.
     */
    function setTrustedOracleCallback(address _callbackAddress) public onlyOwner {
        require(_callbackAddress != address(0), "Aetherium: Invalid callback address");
        trustedOracleCallback = _callbackAddress;
        emit TrustedOracleCallbackSet(_callbackAddress);
    }

    /**
     * @dev Sets the ERC20 token used for staking, fees, and rewards within the protocol. Only callable by owner.
     * @param _token The address of the new payment token contract.
     */
    function setPaymentToken(address _token) public onlyOwner {
        require(_token != address(0), "Aetherium: Invalid payment token address");
        paymentToken = IERC20(_token);
        emit PaymentTokenSet(_token);
    }

    /**
     * @dev Views the current value of a given protocol parameter.
     * @param _paramKey The key identifying the parameter.
     * @return The current value of the parameter.
     */
    function getProtocolParameter(bytes32 _paramKey) public view returns (uint256) {
        return protocolParameters[_paramKey];
    }

    // --- II. Oracle & AI Integration ---

    /**
     * @dev Requests an off-chain AI analysis for a specific proposition.
     *      This function sends a request to the configured verifiable oracle and requires payment of the AI model's fee.
     * @param _propositionId The ID of the proposition to analyze.
     * @param _modelId The identifier of the AI model to use (must be registered).
     * @param _modelInput Additional input/payload for the AI model (e.g., specific query parameters).
     * @return requestId The request ID generated by the oracle for tracking.
     */
    function requestAIAnalysis(uint256 _propositionId, bytes32 _modelId, bytes calldata _modelInput)
        public
        returns (bytes32 requestId)
    {
        Proposition storage prop = propositions[_propositionId];
        require(prop.status == PropositionStatus.Open, "Aetherium: Proposition not open for AI analysis");
        require(registeredAIModels[_modelId].isActive, "Aetherium: AI model not registered or inactive");
        require(prop.currentOracleRequestId == bytes32(0), "Aetherium: Oracle request already pending for proposition");

        uint256 fee = registeredAIModels[_modelId].fee;
        require(paymentToken.transferFrom(msg.sender, address(this), fee), "Aetherium: Fee payment failed");

        prop.status = PropositionStatus.AwaitingAI;
        requestId = verifiableOracle.requestData(registeredAIModels[_modelId].oracleJobId, _modelInput);
        prop.currentOracleRequestId = requestId;

        emit AIAnalysisRequested(_propositionId, requestId, _modelId);
        return requestId;
    }

    /**
     * @dev Trusted oracle callback function to deliver the results of an AI analysis.
     *      Only callable by the `trustedOracleCallback` address.
     * @param _requestId The ID of the original request.
     * @param _aiOutput The raw output from the AI model (e.g., JSON, bytes).
     * @param _propositionId The ID of the proposition associated with this analysis.
     */
    function fulfillAIAnalysis(bytes32 _requestId, bytes calldata _aiOutput, uint256 _propositionId)
        public
        onlyTrustedOracleCallback
    {
        Proposition storage prop = propositions[_propositionId];
        require(prop.currentOracleRequestId == _requestId, "Aetherium: Mismatched request ID for AI analysis");
        require(prop.status == PropositionStatus.AwaitingAI, "Aetherium: Proposition not awaiting AI analysis");

        prop.aiOutput = _aiOutput;
        prop.status = PropositionStatus.Open; // Re-open for further attestation/dispute, now augmented with AI insight
        delete prop.currentOracleRequestId; // Clear request ID

        emit AIAnalysisFulfilled(_propositionId, _requestId, _aiOutput);
    }

    /**
     * @dev Registers a new AI model that can be accessed via the oracle.
     *      Only callable by owner/governance.
     * @param _modelIdentifier A unique, descriptive identifier for the AI model (e.g., hash of "GPT-3_Sentiment_V2").
     * @param _oracleJobId The Chainlink Job ID or similar identifier for the specific oracle task that invokes this model.
     * @param _fee The cost in `paymentToken` to request an analysis from this model.
     */
    function registerAIModel(bytes32 _modelIdentifier, bytes32 _oracleJobId, uint256 _fee) public onlyOwner {
        require(!registeredAIModels[_modelIdentifier].isActive, "Aetherium: AI model already registered and active");
        registeredAIModels[_modelIdentifier] = AIModel(_oracleJobId, _fee, true);
        emit AIModelRegistered(_modelIdentifier, _oracleJobId, _fee);
    }

    /**
     * @dev Deregisters an AI model, making it inactive and preventing further requests.
     *      Only callable by owner/governance.
     * @param _modelIdentifier The unique identifier of the AI model to deregister.
     */
    function deregisterAIModel(bytes32 _modelIdentifier) public onlyOwner {
        require(registeredAIModels[_modelIdentifier].isActive, "Aetherium: AI model not active");
        registeredAIModels[_modelIdentifier].isActive = false;
        emit AIModelDeregistered(_modelIdentifier);
    }

    // --- III. Knowledge Pool & Proposition Management ---

    /**
     * @dev Allows users to submit a new statement or prediction as a proposition.
     *      Requires an initial stake from the proposer to demonstrate commitment and prevent spam.
     * @param _statement The textual content of the proposition.
     * @param _expiryTimestamp The timestamp when the proposition should expire and be ready for resolution.
     * @param _categoryHash A hash for categorization (e.g., `keccak256("market_prediction")`, `keccak256("event_outcome")`).
     * @param _initialStake The initial amount of `paymentToken` provided by the proposer.
     */
    function submitProposition(string calldata _statement, uint256 _expiryTimestamp, bytes32 _categoryHash, uint256 _initialStake)
        public
    {
        require(bytes(_statement).length > 0, "Aetherium: Statement cannot be empty");
        require(_expiryTimestamp > block.timestamp, "Aetherium: Expiry must be in the future");
        require(_initialStake >= protocolParameters[MIN_PROPOSITION_STAKE_PARAM], "Aetherium: Initial stake too low");
        require(paymentToken.transferFrom(msg.sender, address(this), _initialStake), "Aetherium: Initial stake transfer failed");

        uint256 propId = nextPropositionId++;
        propositions[propId] = Proposition({
            id: propId,
            proposer: msg.sender,
            statement: _statement,
            expiryTimestamp: _expiryTimestamp,
            categoryHash: _categoryHash,
            submissionTimestamp: block.timestamp,
            status: PropositionStatus.Open,
            totalAttestationStake: 0,
            totalDisputeStake: 0,
            finalResolution: false,
            currentOracleRequestId: bytes32(0),
            aiOutput: "",
            resolvedTimestamp: 0
        });

        // Proposer's initial stake is considered an attestation
        propositions[propId].attesters[msg.sender] = _initialStake;
        propositions[propId].totalAttestationStake = _initialStake;

        emit PropositionSubmitted(propId, msg.sender, _statement, _expiryTimestamp);
    }

    /**
     * @dev Allows users to stake `paymentToken` on a proposition, asserting it to be true/accurate.
     * @param _propositionId The ID of the proposition to attest to.
     * @param _stakeAmount The amount of `paymentToken` to stake.
     */
    function attestToProposition(uint256 _propositionId, uint256 _stakeAmount) public {
        Proposition storage prop = propositions[_propositionId];
        require(prop.status == PropositionStatus.Open, "Aetherium: Proposition not open for attestation");
        require(block.timestamp < prop.expiryTimestamp, "Aetherium: Proposition has expired");
        require(_stakeAmount > 0, "Aetherium: Stake amount must be positive");
        require(paymentToken.transferFrom(msg.sender, address(this), _stakeAmount), "Aetherium: Stake transfer failed");

        prop.attesters[msg.sender] = prop.attesters[msg.sender].add(_stakeAmount);
        prop.totalAttestationStake = prop.totalAttestationStake.add(_stakeAmount);

        emit PropositionStaked(_propositionId, msg.sender, _stakeAmount, true);
    }

    /**
     * @dev Allows users to stake `paymentToken` on a proposition, asserting it to be false/inaccurate.
     * @param _propositionId The ID of the proposition to dispute.
     * @param _stakeAmount The amount of `paymentToken` to stake.
     */
    function disputeProposition(uint256 _propositionId, uint256 _stakeAmount) public {
        Proposition storage prop = propositions[_propositionId];
        require(prop.status == PropositionStatus.Open, "Aetherium: Proposition not open for dispute");
        require(block.timestamp < prop.expiryTimestamp, "Aetherium: Proposition has expired");
        require(_stakeAmount > 0, "Aetherium: Stake amount must be positive");
        require(paymentToken.transferFrom(msg.sender, address(this), _stakeAmount), "Aetherium: Stake transfer failed");

        prop.disputers[msg.sender] = prop.disputers[msg.sender].add(_stakeAmount);
        prop.totalDisputeStake = prop.totalDisputeStake.add(_stakeAmount);

        emit PropositionStaked(_propositionId, msg.sender, _stakeAmount, false);
    }

    /**
     * @dev Triggers the final resolution process for a proposition.
     *      This can only be called after the proposition's `expiryTimestamp`.
     *      It sends a resolution request to the configured verifiable oracle.
     * @param _propositionId The ID of the proposition to resolve.
     * @return requestId The request ID generated by the oracle.
     */
    function requestPropositionResolution(uint256 _propositionId) public returns (bytes32 requestId) {
        Proposition storage prop = propositions[_propositionId];
        require(prop.status == PropositionStatus.Open, "Aetherium: Proposition not in Open status");
        require(block.timestamp >= prop.expiryTimestamp, "Aetherium: Proposition has not expired yet");
        require(prop.currentOracleRequestId == bytes32(0), "Aetherium: Oracle request already pending for proposition");


        // Take a fee for resolution service
        uint256 resolutionFee = protocolParameters[PROPOSITION_RESOLUTION_FEE_PARAM];
        require(paymentToken.transferFrom(msg.sender, address(this), resolutionFee), "Aetherium: Resolution fee payment failed");

        // Craft the oracle payload: includes the statement and potentially AI output for context.
        bytes memory oraclePayload = abi.encodePacked("Resolve:", prop.statement, prop.aiOutput);
        bytes32 resolutionJobId = keccak256(abi.encodePacked("PROPOSITION_RESOLUTION_JOB")); // A generic job ID
        requestId = verifiableOracle.requestData(resolutionJobId, oraclePayload);

        prop.status = PropositionStatus.AwaitingResolution;
        prop.currentOracleRequestId = requestId;

        emit PropositionResolutionRequested(_propositionId, requestId);
        return requestId;
    }

    /**
     * @dev Trusted oracle callback to deliver the final resolution of a proposition.
     *      Only callable by the `trustedOracleCallback` address.
     * @param _requestId The ID of the original resolution request.
     * @param _isTrue The final resolution: `true` if the proposition is confirmed true, `false` otherwise.
     * @param _propositionId The ID of the proposition being resolved.
     */
    function fulfillPropositionResolution(bytes32 _requestId, bool _isTrue, uint256 _propositionId)
        public
        onlyTrustedOracleCallback
    {
        Proposition storage prop = propositions[_propositionId];
        require(prop.currentOracleRequestId == _requestId, "Aetherium: Mismatched request ID for resolution");
        require(prop.status == PropositionStatus.AwaitingResolution, "Aetherium: Proposition not awaiting resolution");

        prop.finalResolution = _isTrue;
        prop.status = _isTrue ? PropositionStatus.ResolvedTrue : PropositionStatus.ResolvedFalse;
        prop.resolvedTimestamp = block.timestamp;
        delete prop.currentOracleRequestId; // Clear request ID

        // Proposer's reputation update occurs here, as they initiated the proposition
        int256 reputationGain = int256(protocolParameters[REPUTATION_GAIN_PER_CORRECT_STAKE_PARAM]);
        int256 reputationLoss = int256(protocolParameters[REPUTATION_LOSS_PER_INCORRECT_STAKE_PARAM]);
        bool proposerWasCorrect = (prop.attesters[prop.proposer] > 0 && _isTrue) || (prop.disputers[prop.proposer] > 0 && !_isTrue);
        _updateUserReputation(prop.proposer, proposerWasCorrect ? reputationGain : -reputationLoss);


        emit PropositionResolved(_propositionId, _isTrue);
    }

    /**
     * @dev Allows users to claim rewards or recover stakes after a proposition is resolved.
     *      Users who staked correctly receive their stake back plus a proportional share of the incorrect stakes.
     *      Users who staked incorrectly lose their stake (slashed). Reputation is updated upon claiming.
     * @param _propositionId The ID of the resolved proposition.
     */
    function claimPropositionRewards(uint256 _propositionId) public {
        Proposition storage prop = propositions[_propositionId];
        require(prop.status == PropositionStatus.ResolvedTrue || prop.status == PropositionStatus.ResolvedFalse, "Aetherium: Proposition not resolved");

        // Check if user has staked and for which side
        uint256 userAttestationStake = prop.attesters[msg.sender];
        uint256 userDisputeStake = prop.disputers[msg.sender];
        require(userAttestationStake > 0 || userDisputeStake > 0, "Aetherium: User did not stake on this proposition");
        require(userAttestationStake > 0 == (userDisputeStake == 0), "Aetherium: User cannot both attest and dispute"); // Enforce one side

        uint256 rewardAmount = 0;
        int256 reputationChange = 0;
        bool isCorrect = false;

        if (prop.finalResolution) { // Proposition resolved as TRUE
            if (userAttestationStake > 0) { // User was correct (attested TRUE)
                isCorrect = true;
                uint256 totalCorrectStake = prop.totalAttestationStake;
                uint256 totalIncorrectStake = prop.totalDisputeStake;
                // Reward: user's stake back + share of incorrect stakes
                rewardAmount = userAttestationStake.add(totalCorrectStake > 0 ? totalIncorrectStake.mul(userAttestationStake).div(totalCorrectStake) : 0);
            } else { // User was incorrect (disputed FALSE)
                rewardAmount = 0; // Stake is lost
            }
        } else { // Proposition resolved as FALSE
            if (userDisputeStake > 0) { // User was correct (disputed FALSE)
                isCorrect = true;
                uint256 totalCorrectStake = prop.totalDisputeStake;
                uint256 totalIncorrectStake = prop.totalAttestationStake;
                // Reward: user's stake back + share of incorrect stakes
                rewardAmount = userDisputeStake.add(totalCorrectStake > 0 ? totalIncorrectStake.mul(userDisputeStake).div(totalCorrectStake) : 0);
            } else { // User was incorrect (attested TRUE)
                rewardAmount = 0; // Stake is lost
            }
        }

        // Determine reputation change
        if (isCorrect) {
            reputationChange = int256(protocolParameters[REPUTATION_GAIN_PER_CORRECT_STAKE_PARAM]);
        } else {
            reputationChange = -int256(protocolParameters[REPUTATION_LOSS_PER_INCORRECT_STAKE_PARAM]);
        }

        // Transfer rewards if any
        if (rewardAmount > 0) {
            require(paymentToken.transfer(msg.sender, rewardAmount), "Aetherium: Reward transfer failed");
        }

        // Clear user's stake to prevent double claims and adjust total stakes
        if (userAttestationStake > 0) {
            delete prop.attesters[msg.sender];
            prop.totalAttestationStake = prop.totalAttestationStake.sub(userAttestationStake);
        }
        if (userDisputeStake > 0) {
            delete prop.disputers[msg.sender];
            prop.totalDisputeStake = prop.totalDisputeStake.sub(userDisputeStake);
        }

        // Update user reputation
        _updateUserReputation(msg.sender, reputationChange);

        emit PropositionRewardsClaimed(_propositionId, msg.sender, rewardAmount);
    }

    /**
     * @dev Views comprehensive details of a specific proposition.
     * @param _propositionId The ID of the proposition.
     * @return A tuple containing detailed information about the proposition.
     */
    function getPropositionDetails(uint256 _propositionId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            string memory statement,
            uint256 expiryTimestamp,
            bytes32 categoryHash,
            uint256 submissionTimestamp,
            PropositionStatus status,
            uint256 totalAttestationStake,
            uint256 totalDisputeStake,
            bool finalResolution,
            bytes memory aiOutput,
            uint256 resolvedTimestamp,
            bytes32 currentOracleRequestId
        )
    {
        Proposition storage prop = propositions[_propositionId];
        return (
            prop.id,
            prop.proposer,
            prop.statement,
            prop.expiryTimestamp,
            prop.categoryHash,
            prop.submissionTimestamp,
            prop.status,
            prop.totalAttestationStake,
            prop.totalDisputeStake,
            prop.finalResolution,
            prop.aiOutput,
            prop.resolvedTimestamp,
            prop.currentOracleRequestId
        );
    }

    // --- IV. Reputation System ---

    /**
     * @dev Views a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) public view returns (int256) {
        return userReputations[_user].score;
    }

    /**
     * @dev Internal function to modify user reputation based on their protocol activities (e.g., correct/incorrect staking).
     * @param _user The address of the user whose reputation is to be updated.
     * @param _change The amount of reputation to add or subtract (can be negative).
     */
    function _updateUserReputation(address _user, int256 _change) internal {
        int256 oldScore = userReputations[_user].score;
        userReputations[_user].score = oldScore.add(_change);
        userReputations[_user].lastActivityTimestamp = block.timestamp;
        emit ReputationUpdated(_user, oldScore, userReputations[_user].score);
    }

    // --- V. Generative Aetherium Constructs (NFTs) ---

    /**
     * @dev Mints a new ERC721 Aetherium Construct NFT, linking it to a foundational, resolved proposition.
     *      The initial traits/metadata of the NFT are derived from this base proposition.
     *      Only propositions resolved as TRUE can be used as a base.
     * @param _basePropositionId The ID of the proposition this construct is based on.
     */
    function mintConstruct(uint256 _basePropositionId) public {
        Proposition storage baseProp = propositions[_basePropositionId];
        require(baseProp.status == PropositionStatus.ResolvedTrue, "Aetherium: Base proposition must be resolved TRUE");
        // Future extensions: May require certain reputation from minter, or ownership of a special token.

        uint256 tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);

        constructs[tokenId] = Construct({
            basePropositionId: _basePropositionId,
            mintedTimestamp: block.timestamp,
            lastEvolutionTimestamp: block.timestamp,
            currentTraitsHash: bytes32(0) // Will be calculated below
        });
        constructs[tokenId].linkedPropositions[_basePropositionId] = true;

        _updateConstructTraitsHash(tokenId); // Calculate initial traits hash

        emit ConstructMinted(tokenId, msg.sender, _basePropositionId);
    }

    /**
     * @dev Allows the owner of an Aetherium Construct to link additional resolved propositions to it.
     *      Linking new propositions influences the construct's dynamic metadata and potential future evolution.
     * @param _tokenId The ID of the Aetherium Construct NFT.
     * @param _propositionId The ID of the proposition to link (must be resolved).
     */
    function linkPropositionToConstruct(uint256 _tokenId, uint256 _propositionId) public onlyConstructOwner(_tokenId) {
        Proposition storage linkedProp = propositions[_propositionId];
        require(linkedProp.status == PropositionStatus.ResolvedTrue || linkedProp.status == PropositionStatus.ResolvedFalse, "Aetherium: Linked proposition must be resolved");
        require(!constructs[_tokenId].linkedPropositions[_propositionId], "Aetherium: Proposition already linked");

        constructs[_tokenId].linkedPropositions[_propositionId] = true;

        // Trigger a metadata update for the construct
        _updateConstructTraitsHash(_tokenId);

        emit ConstructLinkedProposition(_tokenId, _propositionId);
    }

    /**
     * @dev Triggers a significant "evolution" of a Construct. This function initiates a recalculation
     *      of the Construct's traits, potentially based on accumulated linked propositions,
     *      AI insights, or other time-sensitive data. This updates the `currentTraitsHash` which
     *      is reflected in its `tokenURI` and off-chain rendering.
     * @param _tokenId The ID of the Aetherium Construct NFT.
     * @param _evolutionParams Optional bytes to guide specific evolution paths (e.g., provide AI model ID for a new analysis).
     */
    function triggerConstructEvolution(uint256 _tokenId, bytes calldata _evolutionParams) public onlyConstructOwner(_tokenId) {
        // This function can be expanded to include complex logic:
        // - Request new AI analysis based on _evolutionParams and linked propositions' data.
        // - Consume some tokens/resources or require specific conditions met.
        // - In a more extreme scenario, it might even burn the old NFT and mint a new one with fundamentally different traits.

        constructs[_tokenId].lastEvolutionTimestamp = block.timestamp;
        _updateConstructTraitsHash(_tokenId); // Re-calculate traits based on all linked props and current state

        // The _evolutionParams could be used to fetch new data or trigger specific off-chain logic.
        // For this example, we'll simply update the hash.

        emit ConstructEvolutionTriggered(_tokenId, constructs[_tokenId].currentTraitsHash);
    }

    /**
     * @dev Internal function to recalculate the `currentTraitsHash` of a construct.
     *      This hash is used by the `tokenURI` to generate dynamic metadata.
     *      The logic here defines how the Construct's traits evolve based on its linked propositions
     *      and other on-chain data.
     */
    function _updateConstructTraitsHash(uint256 _tokenId) internal {
        Construct storage construct = constructs[_tokenId];
        Proposition storage baseProp = propositions[construct.basePropositionId];

        // This is a placeholder for complex, unique trait generation logic.
        // It aggregates data from the base proposition, all dynamically linked propositions,
        // and potentially their AI outputs, current timestamp, etc.
        // The more data points included, the more dynamic the NFT's traits can be.
        bytes memory traitsData = abi.encodePacked(
            _tokenId,
            construct.basePropositionId,
            baseProp.finalResolution,
            baseProp.aiOutput,
            construct.mintedTimestamp,
            construct.lastEvolutionTimestamp
            // Iterating through `linkedPropositions` directly in Solidity is gas-intensive.
            // A more scalable approach for many linked propositions might involve:
            // 1. Storing a single aggregated hash of linked proposition states.
            // 2. Passing an array of linked proposition IDs to an off-chain oracle to build the hash.
            // For simplicity, we'll limit the on-chain data to the base proposition and timestamps.
            // The off-chain `tokenURI` resolver can query all linked propositions itself.
        );
        construct.currentTraitsHash = keccak256(traitsData);
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata for Aetherium Constructs.
     *      The URI points to an off-chain service responsible for generating JSON metadata
     *      and potentially visual representations based on the Construct's current on-chain state,
     *      its `currentTraitsHash`, and all linked propositions.
     * @param _tokenId The ID of the Aetherium Construct NFT.
     * @return A URL pointing to the JSON metadata for the NFT.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        Construct storage construct = constructs[_tokenId];

        // The base URI would point to an external service (e.g., an IPFS gateway or a web server).
        // This service would interpret the token ID and the currentTraitsHash (and query the contract
        // for linked propositions) to dynamically generate the metadata JSON and potentially an image.
        string memory baseURI = "https://aetherium.io/api/constructs/"; // Example URL
        string memory tokenIdStr = Strings.toString(_tokenId);
        string memory traitsHashStr = Strings.toHexString(uint256(construct.currentTraitsHash), 32); // 32 bytes = 64 hex chars
        return string(abi.encodePacked(baseURI, tokenIdStr, "/", traitsHashStr));
    }


    // --- VI. Adaptive Protocol & Parameter Management (Simplified DAO-like) ---

    /**
     * @dev Initiates a proposal for a protocol parameter change.
     *      Requires the proposer to have at least `VOTING_THRESHOLD_REPUTATION_PARAM` reputation.
     *      (In a full DAO, voting weight would likely be tied to token holdings or more complex reputation scores).
     * @param _paramKey The key of the protocol parameter to change.
     * @param _newValue The proposed new value for the parameter.
     * @param _votingPeriod The duration (in seconds) for which the proposal will be open for voting.
     */
    function proposeParameterChange(bytes32 _paramKey, uint256 _newValue, uint256 _votingPeriod) public {
        require(userReputations[msg.sender].score >= int256(protocolParameters[VOTING_THRESHOLD_REPUTATION_PARAM]), "Aetherium: Not enough reputation to propose");
        require(_votingPeriod > 0, "Aetherium: Voting period must be positive");

        uint256 proposalId = nextProposalId++;
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            id: proposalId,
            proposer: msg.sender,
            paramKey: _paramKey,
            newValue: _newValue,
            proposalTimestamp: block.timestamp,
            votingEndsTimestamp: block.timestamp.add(_votingPeriod),
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Pending
        });

        emit ParameterChangeProposed(proposalId, _paramKey, _newValue, msg.sender);
    }

    /**
     * @dev Allows users with sufficient reputation to vote on an active parameter change proposal.
     *      A user can only vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True for a 'yes' vote (approve), false for a 'no' vote (reject).
     */
    function voteOnParameterChange(uint256 _proposalId, bool _approve) public {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Aetherium: Proposal not active");
        require(block.timestamp < proposal.votingEndsTimestamp, "Aetherium: Voting period has ended");
        require(userReputations[msg.sender].score >= int256(protocolParameters[VOTING_THRESHOLD_REPUTATION_PARAM]), "Aetherium: Not enough reputation to vote");
        require(!proposal.hasVoted[msg.sender], "Aetherium: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes = proposal.yesVotes.add(1); // Simplified: 1 user = 1 vote
        } else {
            proposal.noVotes = proposal.noVotes.add(1);
        }

        emit VoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes a passed parameter change proposal.
     *      Can be called by anyone after the voting period ends.
     *      A proposal passes if `yesVotes` are strictly greater than `noVotes`.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) public {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Aetherium: Proposal not active");
        require(block.timestamp >= proposal.votingEndsTimestamp, "Aetherium: Voting period not ended");

        if (proposal.yesVotes > proposal.noVotes) {
            protocolParameters[proposal.paramKey] = proposal.newValue;
            proposal.status = ProposalStatus.Executed;
            emit ParameterChangeExecuted(proposal.id, proposal.paramKey, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }
}

// Helper library for int256 arithmetic to prevent overflow/underflow
library SafeMathInt256 {
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SafeMathInt256: addition overflow or underflow");
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SafeMathInt256: subtraction overflow or underflow");
        return c;
    }
}
```