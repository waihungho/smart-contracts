```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CognitoDAO: Decentralized Collective Intelligence Protocol
 * @dev This contract establishes a protocol for fostering collective knowledge creation,
 *      insight validation, and resource allocation through a novel combination of
 *      Knowledge Tokens (KWT), dynamic Aura Reputation NFTs, and a simulated
 *      AI-driven evaluation mechanism.
 *      The contract aims to be innovative by integrating dynamic reputation NFTs,
 *      a deterministic on-chain "AI Oracle" for initial proposal scoring, and
 *      a robust proposal/resource allocation system without duplicating existing
 *      open-source implementations of core standards (ERC20/ERC721),
 *      instead providing minimalist, in-house implementations for specific needs.
 *
 * Outline:
 * 1.  Core Infrastructure & Access Control: Manages protocol ownership, pausing, and key parameter updates.
 * 2.  Knowledge Token (KWT) Interface: Implements a basic ERC20-like token for economic participation and rewards.
 * 3.  Aura Reputation NFT Interface: Implements a dynamic, semi-soulbound ERC721-like token to represent and track contributor reputation.
 * 4.  Collective Intelligence & Proposal System: Enables users to submit insights, which are then evaluated by a
 *     deterministic "AI Oracle" and subsequently voted upon by the community.
 * 5.  Wisdom Pool (Treasury) & Resource Allocation: Manages a collective treasury and allows for decentralized
 *     proposals and voting on resource expenditure.
 * 6.  Advanced & Unique Features: Includes mechanisms for reputation decay, challenging AI evaluations, and claiming rewards.
 *
 * Function Summary:
 *
 * I. Core Infrastructure & Access Control:
 *    - constructor(): Initializes the contract, sets the deployer as owner, and sets initial protocol parameters.
 *    - updateProtocolParameter(bytes32 _paramName, uint256 _value): Allows the owner/governance to adjust key numeric protocol parameters.
 *    - pauseProtocol(): Emergency function to pause critical contract operations.
 *    - unpauseProtocol(): Unpauses the contract's operations.
 *    - addTrustedValidator(address _validator): Grants a trusted validator role, typically for AI oracle triggers or dispute resolution.
 *
 * II. Knowledge Token (KWT) - ERC20-Like Functions:
 *    - mintKnowledgeTokens(address _to, uint256 _amount): Mints KWT to a specified address; restricted to protocol owner/trusted roles (e.g., for rewards).
 *    - transferKnowledgeTokens(address _to, uint256 _amount): Allows users to transfer their KWT tokens.
 *    - stakeKnowledgeTokens(uint256 _amount): Users stake KWT to gain voting power and submit proposals.
 *    - unstakeKnowledgeTokens(uint256 _amount): Users can unstake their KWT after a defined cool-down period.
 *    - getKnowledgeTokenBalance(address _user): Returns the KWT balance of a user.
 *    - getStakedKnowledgeTokens(address _user): Returns the amount of KWT staked by a user.
 *
 * III. Aura Reputation NFTs (Semi-Soulbound, Dynamic ERC721):
 *    - issueAuraNFT(address _recipient): Mints a new, non-transferable Aura NFT to a user upon their first significant contribution.
 *    - updateAuraReputation(uint256 _tokenId, int256 _delta): Adjusts the reputation score associated with an Aura NFT, influencing its dynamic metadata.
 *    - getAuraReputationScore(uint256 _tokenId): Returns the current reputation score for a given Aura NFT.
 *    - burnAuraNFTAndReset(uint256 _tokenId): Allows a user to burn their Aura NFT, effectively resetting their reputation.
 *
 * IV. Collective Intelligence & Proposal System:
 *    - submitInsightProposal(bytes32 _contentHash, uint256 _category, uint256 _stakeAmount): Users submit a new insight proposal, attaching off-chain content hash, category, and staking KWT.
 *    - evaluateProposalByAIOracle(uint256 _proposalId): A deterministic function simulating an "AI" evaluation, assigning an initial score to a proposal based on defined criteria.
 *    - voteOnProposal(uint256 _proposalId, bool _support): Community members vote on active proposals, with voting power influenced by staked KWT and Aura reputation.
 *    - finalizeProposal(uint256 _proposalId): Concludes a proposal's lifecycle, distributing rewards, and updating reputations based on the outcome of votes and AI score.
 *
 * V. Wisdom Pool (Treasury) & Resource Allocation:
 *    - depositToWisdomPool(uint256 _amount): Allows KWT to be deposited into the collective treasury.
 *    - proposeResourceAllocation(bytes32 _descriptionHash, uint256 _amount): Submits a proposal for how to allocate KWT from the Wisdom Pool.
 *    - voteOnResourceAllocation(uint256 _allocationProposalId, bool _support): Allows community members to vote on resource allocation proposals.
 *
 * VI. Advanced & Unique Features:
 *    - decayAuraReputation(uint256 _tokenId): Applies a periodic decay to an Aura NFT's reputation score if the associated user is inactive.
 *    - challengeAIOracleEvaluation(uint256 _proposalId): Enables a formal challenge to the AI Oracle's initial evaluation, potentially triggering a community review or re-evaluation process.
 *    - claimIncentiveRewards(uint256 _proposalId): Allows participants (proposer, successful voters) to claim their KWT rewards after a proposal is successfully finalized.
 */
contract CognitoDAO {

    // --- State Variables ---

    // Access Control
    address public owner;
    bool private _paused;
    mapping(address => bool) private _trustedValidators;

    // KWT Token
    string public constant KWT_NAME = "Knowledge Token";
    string public constant KWT_SYMBOL = "KWT";
    uint256 public constant KWT_DECIMALS = 18;
    uint256 private _totalSupplyKWT;
    mapping(address => uint256) private _balancesKWT;
    mapping(address => uint256) private _stakedKWT;
    mapping(address => uint256) private _unstakeCooldowns;

    // Aura NFT
    string public constant AURA_NAME = "Aura Reputation NFT";
    string public constant AURA_SYMBOL = "AURA";
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _ownerAuraTokenId; // Map address to their single Aura NFT ID
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) private _isSoulbound; // Aura NFTs are soulbound (non-transferable)
    mapping(uint256 => int256) private _auraReputationScore; // Reputation score for each Aura NFT

    // Protocol Parameters (configurable by governance)
    mapping(bytes32 => uint256) public protocolParameters;

    // Proposal System
    enum ProposalState { PendingEvaluation, Evaluated, Voting, Finalized, Challenged, Rejected }

    struct Proposal {
        address proposer;
        bytes32 contentHash; // IPFS hash or similar for off-chain content
        uint256 category; // Categorization for AI evaluation
        uint256 stakeAmount; // KWT staked by proposer
        uint256 submissionTime;
        uint256 evaluationTime; // Time AI Oracle evaluation was completed
        uint256 votingStartTime;
        uint256 votingEndTime;
        int256 aiOracleScore; // Score assigned by the AI Oracle (deterministic logic)
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        uint256 totalVoterWeight; // Sum of KWT staked + Aura reputation weight
        ProposalState state;
        bool rewardsClaimed;
    }
    Proposal[] public proposals;
    mapping(uint256 => uint256) private _proposalIdToRewards; // KWT rewards for successful proposal

    // Resource Allocation System (for Wisdom Pool funds)
    enum AllocationState { PendingVote, Approved, Rejected }

    struct AllocationProposal {
        address proposer;
        bytes32 descriptionHash;
        uint256 amount; // KWT amount to allocate from Wisdom Pool
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        uint256 totalVoterWeight;
        AllocationState state;
    }
    AllocationProposal[] public allocationProposals;

    // Wisdom Pool (KWT Treasury)
    uint256 public wisdomPoolBalance;

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event TrustedValidatorAdded(address indexed validator);
    event KWTMinted(address indexed to, uint256 amount);
    event KWTTransfer(address indexed from, address indexed to, uint256 amount);
    event KWTStaked(address indexed user, uint256 amount);
    event KWTUnstaked(address indexed user, uint256 amount);
    event AuraNFTIssued(address indexed recipient, uint256 tokenId, int256 initialScore);
    event AuraReputationUpdated(uint256 indexed tokenId, int256 oldScore, int256 newScore);
    event AuraNFTBurned(uint256 indexed tokenId, address indexed owner);
    event ProtocolParameterUpdated(bytes32 paramName, uint256 oldValue, uint256 newValue);
    event InsightProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 contentHash, uint256 stakeAmount);
    event ProposalEvaluated(uint256 indexed proposalId, int256 aiOracleScore);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voterWeight);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState finalState, uint256 rewards);
    event ResourceAllocationProposed(uint256 indexed allocationId, address indexed proposer, uint256 amount);
    event ResourceAllocationVoted(uint256 indexed allocationId, address indexed voter, bool support, uint256 voterWeight);
    event ResourceAllocationFinalized(uint256 indexed allocationId, AllocationState finalState);
    event WisdomPoolDeposited(address indexed depositor, uint256 amount);
    event WisdomPoolWithdrawn(address indexed recipient, uint256 amount);
    event AIOracleEvaluationChallenged(uint256 indexed proposalId, address indexed challenger);
    event IncentiveRewardsClaimed(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    // --- Custom Errors ---
    error NotOwner();
    error PausedContract();
    error NotTrustedValidator();
    error InsufficientBalance();
    error InsufficientStakedKWT();
    error UnstakeCooldownActive();
    error InvalidAuraTokenId();
    error AlreadyHasAuraNFT();
    error AuraNFTNotSoulbound();
    error AuraNFTTransferForbidden(); // Though not explicitly used due to _isSoulbound, good to have.
    error ProposalNotFound();
    error InvalidProposalState();
    error AlreadyVoted();
    error VotingPeriodNotActive();
    error ProposalNotFinalizable();
    error AmountTooLow();
    error NotEnoughFundsInPool();
    error ChallengeNotAllowed();
    error RewardsAlreadyClaimed();
    error ParameterNotFound();
    error InvalidParameterValue();
    error AuraNFTInactive(); // For decay if last active time becomes a thing.

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert PausedContract();
        _;
    }

    modifier onlyTrustedValidator() {
        if (!_trustedValidators[msg.sender]) revert NotTrustedValidator();
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _paused = false;

        // Set initial protocol parameters
        protocolParameters[keccak256("MIN_PROPOSAL_STAKE")] = 100 * (10 ** KWT_DECIMALS); // 100 KWT
        protocolParameters[keccak256("VOTING_PERIOD_DURATION")] = 3 days; // 3 days for voting
        protocolParameters[keccak256("UNSTAKE_COOLDOWN_PERIOD")] = 7 days; // 7 days cooldown for unstaking
        protocolParameters[keccak256("AURA_REPUTATION_DECAY_PERIOD")] = 30 days; // Decay every 30 days
        protocolParameters[keccak256("AURA_DECAY_RATE")] = 10; // 10% decay per period (out of 100)
        protocolParameters[keccak256("INITIAL_REPUTATION_SCORE")] = 100; // Initial score for new Aura NFT
        protocolParameters[keccak256("MIN_AURA_FOR_CHALLENGE")] = 500; // Min Aura score to challenge AI
        protocolParameters[keccak256("AI_STAKE_WEIGHT_FACTOR")] = 10; // AI score weight for stake
        protocolParameters[keccak256("AI_REPUTATION_WEIGHT_FACTOR")] = 5; // AI score weight for reputation
        protocolParameters[keccak256("SUCCESSFUL_PROPOSAL_REWARD_PERCENT")] = 15; // 15% of staked KWT as reward (if successful)
        protocolParameters[keccak256("SUCCESSFUL_VOTER_REWARD_PERCENT")] = 5; // 5% of staked KWT as reward for voters
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Allows the owner to update key numeric protocol parameters.
     * @param _paramName The name of the parameter to update (e.g., "MIN_PROPOSAL_STAKE").
     * @param _value The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _value) external onlyOwner {
        uint256 oldValue = protocolParameters[_paramName];
        if (oldValue == 0 && _value == 0 && _paramName != keccak256("MIN_PROPOSAL_STAKE")) revert ParameterNotFound(); // Basic check
        protocolParameters[_paramName] = _value;
        emit ProtocolParameterUpdated(_paramName, oldValue, _value);
    }

    /**
     * @dev Pauses the contract operations in an emergency.
     * Only the owner can call this.
     */
    function pauseProtocol() external onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract operations.
     * Only the owner can call this.
     */
    function unpauseProtocol() external onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Adds an address to the list of trusted validators.
     * Trusted validators can trigger certain backend processes like initial AI evaluation.
     * @param _validator The address to grant trusted validator role.
     */
    function addTrustedValidator(address _validator) external onlyOwner {
        _trustedValidators[_validator] = true;
        emit TrustedValidatorAdded(_validator);
    }

    // --- II. Knowledge Token (KWT) - ERC20-Like Functions ---

    /**
     * @dev Returns the total supply of KWT tokens.
     */
    function totalSupplyKWT() public view returns (uint256) {
        return _totalSupplyKWT;
    }

    /**
     * @dev Returns the KWT balance of a specific user.
     * @param _user The address to query the balance for.
     */
    function getKnowledgeTokenBalance(address _user) public view returns (uint256) {
        return _balancesKWT[_user];
    }

    /**
     * @dev Mints new KWT tokens to a specified address. Restricted to owner/trusted roles (e.g., for rewards).
     * @param _to The address to mint tokens to.
     * @param _amount The amount of KWT to mint.
     */
    function mintKnowledgeTokens(address _to, uint256 _amount) internal { // Changed to internal, callable by protocol logic
        if (_amount == 0) revert AmountTooLow();
        _totalSupplyKWT += _amount;
        _balancesKWT[_to] += _amount;
        emit KWTMinted(_to, _amount);
    }

    /**
     * @dev Transfers KWT tokens from the caller's balance to another address.
     * @param _to The recipient address.
     * @param _amount The amount of KWT to transfer.
     */
    function transferKnowledgeTokens(address _to, uint256 _amount) public whenNotPaused returns (bool) {
        if (_balancesKWT[msg.sender] < _amount) revert InsufficientBalance();
        _balancesKWT[msg.sender] -= _amount;
        _balancesKWT[_to] += _amount;
        emit KWTTransfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev Allows a user to stake KWT tokens to gain voting power and submit proposals.
     * @param _amount The amount of KWT to stake.
     */
    function stakeKnowledgeTokens(uint256 _amount) public whenNotPaused {
        if (_balancesKWT[msg.sender] < _amount) revert InsufficientBalance();
        if (_amount == 0) revert AmountTooLow();

        _balancesKWT[msg.sender] -= _amount;
        _stakedKWT[msg.sender] += _amount;
        emit KWTStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to unstake KWT tokens after a defined cool-down period.
     * @param _amount The amount of KWT to unstake.
     */
    function unstakeKnowledgeTokens(uint256 _amount) public whenNotPaused {
        if (_stakedKWT[msg.sender] < _amount) revert InsufficientStakedKWT();
        if (block.timestamp < _unstakeCooldowns[msg.sender]) revert UnstakeCooldownActive();
        if (_amount == 0) revert AmountTooLow();

        _stakedKWT[msg.sender] -= _amount;
        _balancesKWT[msg.sender] += _amount;
        _unstakeCooldowns[msg.sender] = block.timestamp + protocolParameters[keccak256("UNSTAKE_COOLDOWN_PERIOD")];
        emit KWTUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Returns the amount of KWT staked by a user.
     * @param _user The address to query.
     */
    function getStakedKnowledgeTokens(address _user) public view returns (uint256) {
        return _stakedKWT[_user];
    }

    // --- III. Aura Reputation NFTs (Semi-Soulbound, Dynamic ERC721) ---

    /**
     * @dev Returns the owner of a specific Aura NFT.
     * @param _tokenId The ID of the Aura NFT.
     */
    function ownerOfAura(uint256 _tokenId) public view returns (address) {
        return _tokenOwners[_tokenId];
    }

    /**
     * @dev Returns the URI for a given Aura NFT, representing its dynamic metadata.
     * The URI is constructed based on its current reputation score.
     * @param _tokenId The ID of the Aura NFT.
     */
    function tokenURIAura(uint256 _tokenId) public view returns (string memory) {
        if (_tokenOwners[_tokenId] == address(0)) revert InvalidAuraTokenId();
        // This is a simplified dynamic URI. In a real scenario, this would point to an IPFS CID
        // that's dynamically generated based on the reputation score, perhaps by an off-chain service.
        // For demonstration, we'll just reflect the score.
        string memory baseURI = "ipfs://cognitodao/aura/";
        return string(abi.encodePacked(baseURI, uint256(_auraReputationScore[_tokenId]).toString(), ".json"));
    }

    /**
     * @dev Mints a new, non-transferable Aura NFT to a user upon their first significant contribution.
     * Each address can only hold one Aura NFT.
     * @param _recipient The address to mint the Aura NFT to.
     */
    function issueAuraNFT(address _recipient) internal { // Made internal, will be called by finalizeProposal
        if (_ownerAuraTokenId[_recipient] != 0) revert AlreadyHasAuraNFT();

        uint256 tokenId = _nextTokenId++;
        _tokenOwners[tokenId] = _recipient;
        _ownerAuraTokenId[_recipient] = tokenId;
        _isSoulbound[tokenId] = true; // Mark as soulbound
        int256 initialScore = int256(protocolParameters[keccak256("INITIAL_REPUTATION_SCORE")]);
        _auraReputationScore[tokenId] = initialScore;
        _tokenURIs[tokenId] = tokenURIAura(tokenId); // Update URI on mint

        emit AuraNFTIssued(_recipient, tokenId, initialScore);
    }

    /**
     * @dev Adjusts the reputation score associated with an Aura NFT.
     * This function is intended to be called by protocol logic (e.g., after successful proposals).
     * @param _tokenId The ID of the Aura NFT.
     * @param _delta The amount to change the reputation score by (can be positive or negative).
     */
    function updateAuraReputation(uint256 _tokenId, int256 _delta) internal {
        if (_tokenOwners[_tokenId] == address(0)) revert InvalidAuraTokenId();

        int256 oldScore = _auraReputationScore[_tokenId];
        _auraReputationScore[_tokenId] = oldScore + _delta;
        if (_auraReputationScore[_tokenId] < 0) { // Reputation cannot go below 0
            _auraReputationScore[_tokenId] = 0;
        }

        _tokenURIs[_tokenId] = tokenURIAura(_tokenId); // Update URI
        emit AuraReputationUpdated(_tokenId, oldScore, _auraReputationScore[_tokenId]);
    }

    /**
     * @dev Returns the current reputation score for a given Aura NFT.
     * @param _tokenId The ID of the Aura NFT.
     */
    function getAuraReputationScore(uint256 _tokenId) public view returns (int256) {
        if (_tokenOwners[_tokenId] == address(0)) revert InvalidAuraTokenId();
        return _auraReputationScore[_tokenId];
    }

    /**
     * @dev Allows a user to burn their Aura NFT, effectively resetting their reputation.
     * This is the only way to "transfer" or remove the soulbound NFT.
     * @param _tokenId The ID of the Aura NFT to burn.
     */
    function burnAuraNFTAndReset(uint256 _tokenId) public whenNotPaused {
        if (_tokenOwners[_tokenId] != msg.sender) revert InvalidAuraTokenId(); // Only owner can burn their Aura

        address ownerAddress = _tokenOwners[_tokenId];
        delete _tokenOwners[_tokenId];
        delete _ownerAuraTokenId[ownerAddress];
        delete _auraReputationScore[_tokenId];
        delete _tokenURIs[_tokenId];
        delete _isSoulbound[_tokenId]; // Remove soulbound status (since it's gone)

        emit AuraNFTBurned(_tokenId, ownerAddress);
    }

    // --- IV. Collective Intelligence & Proposal System ---

    /**
     * @dev Submits a new insight proposal.
     * Requires the proposer to stake a minimum amount of KWT.
     * @param _contentHash IPFS hash or similar for off-chain proposal content.
     * @param _category Categorization for AI evaluation (e.g., 0 for Research, 1 for Development, 2 for Community).
     * @param _stakeAmount The amount of KWT to stake for this proposal.
     */
    function submitInsightProposal(
        bytes32 _contentHash,
        uint256 _category,
        uint256 _stakeAmount
    ) external whenNotPaused {
        if (_stakeAmount < protocolParameters[keccak256("MIN_PROPOSAL_STAKE")]) revert AmountTooLow();
        if (_stakedKWT[msg.sender] < _stakeAmount) revert InsufficientStakedKWT();

        // Deduct staked KWT from user's staked balance
        _stakedKWT[msg.sender] -= _stakeAmount;

        proposals.push(
            Proposal({
                proposer: msg.sender,
                contentHash: _contentHash,
                category: _category,
                stakeAmount: _stakeAmount,
                submissionTime: block.timestamp,
                evaluationTime: 0,
                votingStartTime: 0,
                votingEndTime: 0,
                aiOracleScore: 0,
                votesFor: 0,
                votesAgainst: 0,
                hasVoted: new mapping(address => bool),
                totalVoterWeight: 0,
                state: ProposalState.PendingEvaluation,
                rewardsClaimed: false
            })
        );
        uint256 proposalId = proposals.length - 1;
        emit InsightProposalSubmitted(proposalId, msg.sender, _contentHash, _stakeAmount);
    }

    /**
     * @dev A deterministic function simulating an "AI" evaluation.
     * Calculates an initial score for a proposal based on proposer's reputation, stake, category, etc.
     * This function is intended to be called by a trusted validator or automatically after submission.
     * @param _proposalId The ID of the proposal to evaluate.
     */
    function evaluateProposalByAIOracle(uint256 _proposalId) external onlyTrustedValidator whenNotPaused {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.PendingEvaluation) revert InvalidProposalState();

        int256 score = 0;
        // Factor 1: Proposer's KWT stake (higher stake, higher initial score)
        score += int256(proposal.stakeAmount / (10 ** KWT_DECIMALS)) * int256(protocolParameters[keccak256("AI_STAKE_WEIGHT_FACTOR")]);

        // Factor 2: Proposer's Aura Reputation (higher reputation, higher initial score)
        uint256 proposerAuraTokenId = _ownerAuraTokenId[proposal.proposer];
        if (proposerAuraTokenId != 0) {
            score += _auraReputationScore[proposerAuraTokenId] * int256(protocolParameters[keccak256("AI_REPUTATION_WEIGHT_FACTOR")]);
        }

        // Factor 3: Category specific boosts/penalties (example logic)
        if (proposal.category == 0) { // Category "Research" might get a boost
            score += 50;
        } else if (proposal.category == 1) { // Category "Development" might have a different boost
            score += 75;
        } else if (proposal.category == 2) { // Category "Community" might have a moderate boost
            score += 30;
        }

        // TODO: Add more complex AI logic here, e.g., based on historical success of similar proposals,
        // or other on-chain metrics. This is just a basic example.

        proposal.aiOracleScore = score;
        proposal.evaluationTime = block.timestamp;
        proposal.votingStartTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + protocolParameters[keccak256("VOTING_PERIOD_DURATION")];
        proposal.state = ProposalState.Voting;

        emit ProposalEvaluated(_proposalId, score);
    }

    /**
     * @dev Community members vote on active proposals.
     * Voting power is influenced by staked KWT and Aura reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', False for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Voting) revert InvalidProposalState();
        if (block.timestamp > proposal.votingEndTime) revert VotingPeriodNotActive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (_stakedKWT[msg.sender] == 0 && _ownerAuraTokenId[msg.sender] == 0) revert InsufficientStakedKWT(); // Must have stake or Aura

        uint256 voterWeight = _stakedKWT[msg.sender];
        uint256 voterAuraTokenId = _ownerAuraTokenId[msg.sender];
        if (voterAuraTokenId != 0) {
            voterWeight += uint256(_auraReputationScore[voterAuraTokenId]) * 10; // Aura provides a multiplier to voting weight
        }

        if (_support) {
            proposal.votesFor += voterWeight;
        } else {
            proposal.votesAgainst += voterWeight;
        }
        proposal.totalVoterWeight += voterWeight;
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support, voterWeight);
    }

    /**
     * @dev Concludes a proposal's lifecycle, distributing rewards, and updating reputations based on outcome.
     * Can only be called after the voting period ends.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) public whenNotPaused {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Voting) revert InvalidProposalState();
        if (block.timestamp <= proposal.votingEndTime) revert ProposalNotFinalizable(); // Voting period not over

        // Determine outcome based on AI score and community votes
        // Example logic:
        // AI score must be > 0.
        // For votes must be > Against votes AND For votes must be > 50% of total possible votes (staked KWT + Aura)
        bool aiPass = proposal.aiOracleScore > 0;
        bool communityPass = proposal.votesFor > proposal.votesAgainst;
        // A more complex check could involve a threshold on total voter weight, or minimum participation.

        ProposalState finalState;
        uint256 rewards = 0;

        if (aiPass && communityPass) {
            finalState = ProposalState.Finalized;
            // Reward calculation: a percentage of the initially staked amount
            rewards = (proposal.stakeAmount * protocolParameters[keccak256("SUCCESSFUL_PROPOSAL_REWARD_PERCENT")]) / 100;
            // Mint rewards to the proposer
            mintKnowledgeTokens(proposal.proposer, rewards);
            _proposalIdToRewards[_proposalId] += rewards; // Track rewards for claim

            // Update proposer's reputation
            uint256 proposerAuraTokenId = _ownerAuraTokenId[proposal.proposer];
            if (proposerAuraTokenId == 0) {
                // Issue a new Aura NFT if proposer doesn't have one
                issueAuraNFT(proposal.proposer);
                proposerAuraTokenId = _ownerAuraTokenId[proposal.proposer];
            }
            updateAuraReputation(proposerAuraTokenId, 50); // Example: +50 reputation for success

            // Return proposer's staked KWT
            _stakedKWT[proposal.proposer] += proposal.stakeAmount;
            
            // Reward successful voters (simplified: 5% of proposer stake distributed to voters)
            uint256 voterRewardsPool = (proposal.stakeAmount * protocolParameters[keccak256("SUCCESSFUL_VOTER_REWARD_PERCENT")]) / 100;
            if (proposal.votesFor > 0) {
                // This is a placeholder. Realistically, voter rewards would be distributed
                // proportionally or claimable by voters who voted "for".
                // For simplicity, we add it to the wisdom pool or just log for now.
                // A better approach would be to calculate individual voter rewards inside the claimIncentiveRewards function.
                wisdomPoolBalance += voterRewardsPool; // Add to pool for general use
            }

        } else {
            finalState = ProposalState.Rejected;
            // Return proposer's staked KWT
            _stakedKWT[proposal.proposer] += proposal.stakeAmount;
            // Optionally: reduce proposer's reputation for failed proposal
            uint256 proposerAuraTokenId = _ownerAuraTokenId[proposal.proposer];
            if (proposerAuraTokenId != 0) {
                updateAuraReputation(proposerAuraTokenId, -20); // Example: -20 reputation for failure
            }
        }

        proposal.state = finalState;
        emit ProposalFinalized(_proposalId, finalState, rewards);
    }
    
    /**
     * @dev Allows participants (proposer, successful voters) to claim KWT rewards after a proposal's finalization.
     * Currently only for proposer. Voter rewards logic needs to be more granular.
     * @param _proposalId The ID of the proposal.
     */
    function claimIncentiveRewards(uint256 _proposalId) public whenNotPaused {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Finalized) revert InvalidProposalState();
        if (proposal.rewardsClaimed) revert RewardsAlreadyClaimed();
        
        uint256 amountToClaim = _proposalIdToRewards[_proposalId];
        
        // Only the proposer can claim the proposer's reward
        if (msg.sender != proposal.proposer) revert NotOwner(); // Simple check for now, can be extended for voters

        if (amountToClaim == 0) revert AmountTooLow();

        // KWT was already minted to proposer in finalizeProposal, this is just a flag
        proposal.rewardsClaimed = true;
        emit IncentiveRewardsClaimed(_proposalId, msg.sender, amountToClaim);
    }


    // --- V. Wisdom Pool (Treasury) & Resource Allocation ---

    /**
     * @dev Allows KWT to be deposited into the collective treasury (Wisdom Pool).
     * @param _amount The amount of KWT to deposit.
     */
    function depositToWisdomPool(uint256 _amount) public whenNotPaused {
        if (_balancesKWT[msg.sender] < _amount) revert InsufficientBalance();
        if (_amount == 0) revert AmountTooLow();

        _balancesKWT[msg.sender] -= _amount;
        wisdomPoolBalance += _amount;
        emit WisdomPoolDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows the owner to withdraw KWT from the Wisdom Pool for specific, approved initiatives.
     * This should ideally be subject to a governance vote in a full DAO setup.
     * @param _recipient The address to send the KWT to.
     * @param _amount The amount of KWT to withdraw.
     */
    function _withdrawFromWisdomPool(address _recipient, uint256 _amount) internal { // Internal helper
        if (wisdomPoolBalance < _amount) revert NotEnoughFundsInPool();
        if (_amount == 0) revert AmountTooLow();

        wisdomPoolBalance -= _amount;
        _balancesKWT[_recipient] += _amount; // Transfer KWT from pool to recipient
        emit WisdomPoolWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Submits a proposal for how to allocate KWT from the Wisdom Pool.
     * @param _descriptionHash IPFS hash or similar for off-chain description of the allocation.
     * @param _amount The amount of KWT proposed to be allocated.
     */
    function proposeResourceAllocation(bytes32 _descriptionHash, uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert AmountTooLow();
        if (_stakedKWT[msg.sender] == 0) revert InsufficientStakedKWT(); // Requires stake to propose

        allocationProposals.push(
            AllocationProposal({
                proposer: msg.sender,
                descriptionHash: _descriptionHash,
                amount: _amount,
                submissionTime: block.timestamp,
                votingEndTime: block.timestamp + protocolParameters[keccak256("VOTING_PERIOD_DURATION")],
                votesFor: 0,
                votesAgainst: 0,
                hasVoted: new mapping(address => bool),
                totalVoterWeight: 0,
                state: AllocationState.PendingVote
            })
        );
        uint256 allocationId = allocationProposals.length - 1;
        emit ResourceAllocationProposed(allocationId, msg.sender, _amount);
    }

    /**
     * @dev Allows community members to vote on resource allocation proposals.
     * Voting power is based on staked KWT and Aura reputation.
     * @param _allocationProposalId The ID of the allocation proposal.
     * @param _support True for 'for', False for 'against'.
     */
    function voteOnResourceAllocation(uint256 _allocationProposalId, bool _support) public whenNotPaused {
        if (_allocationProposalId >= allocationProposals.length) revert ProposalNotFound();
        AllocationProposal storage allocation = allocationProposals[_allocationProposalId];

        if (allocation.state != AllocationState.PendingVote) revert InvalidProposalState();
        if (block.timestamp > allocation.votingEndTime) revert VotingPeriodNotActive();
        if (allocation.hasVoted[msg.sender]) revert AlreadyVoted();
        if (_stakedKWT[msg.sender] == 0 && _ownerAuraTokenId[msg.sender] == 0) revert InsufficientStakedKWT();

        uint256 voterWeight = _stakedKWT[msg.sender];
        uint256 voterAuraTokenId = _ownerAuraTokenId[msg.sender];
        if (voterAuraTokenId != 0) {
            voterWeight += uint256(_auraReputationScore[voterAuraTokenId]) * 10;
        }

        if (_support) {
            allocation.votesFor += voterWeight;
        } else {
            allocation.votesAgainst += voterWeight;
        }
        allocation.totalVoterWeight += voterWeight;
        allocation.hasVoted[msg.sender] = true;

        emit ResourceAllocationVoted(_allocationProposalId, msg.sender, _support, voterWeight);

        // Auto-finalize if voting period ends or certain conditions are met
        if (block.timestamp > allocation.votingEndTime) {
            _finalizeResourceAllocation(_allocationProposalId);
        }
    }

    /**
     * @dev Internal function to finalize a resource allocation proposal.
     * @param _allocationProposalId The ID of the allocation proposal.
     */
    function _finalizeResourceAllocation(uint256 _allocationProposalId) internal {
        if (_allocationProposalId >= allocationProposals.length) revert ProposalNotFound();
        AllocationProposal storage allocation = allocationProposals[_allocationProposalId];

        if (allocation.state != AllocationState.PendingVote) revert InvalidProposalState();
        if (block.timestamp <= allocation.votingEndTime) revert VotingPeriodNotActive(); // Ensure voting is over

        AllocationState finalState;
        if (allocation.votesFor > allocation.votesAgainst && allocation.amount <= wisdomPoolBalance) {
            _withdrawFromWisdomPool(allocation.proposer, allocation.amount); // Allocate funds to proposer
            finalState = AllocationState.Approved;
        } else {
            finalState = AllocationState.Rejected;
        }

        allocation.state = finalState;
        emit ResourceAllocationFinalized(_allocationProposalId, finalState);
    }

    // --- VI. Advanced & Unique Features ---

    /**
     * @dev Applies a periodic decay to a user's Aura reputation score if they are inactive.
     * Designed to be called by a keeper network or as part of other user interactions.
     * @param _tokenId The ID of the Aura NFT to decay.
     */
    function decayAuraReputation(uint256 _tokenId) public whenNotPaused {
        if (_tokenOwners[_tokenId] == address(0)) revert InvalidAuraTokenId();
        // In a real system, you'd track last activity time. For simplicity, this is a callable function.
        // Assume external keeper calls this regularly based on AURA_REPUTATION_DECAY_PERIOD
        // A more robust implementation would check `block.timestamp - lastActivityTime[_tokenId] > DECAY_PERIOD`
        // and calculate decay based on how many periods have passed.

        int256 currentScore = _auraReputationScore[_tokenId];
        if (currentScore == 0) return; // No decay if already 0

        int256 decayAmount = (currentScore * int256(protocolParameters[keccak256("AURA_DECAY_RATE")])) / 100;
        if (decayAmount < 1) decayAmount = 1; // Ensure at least 1 point decay

        updateAuraReputation(_tokenId, -decayAmount);
    }

    /**
     * @dev Enables a formal challenge to the AI Oracle's initial evaluation of a proposal.
     * Requires a minimum Aura reputation score from the challenger.
     * @param _proposalId The ID of the proposal whose AI evaluation is being challenged.
     */
    function challengeAIOracleEvaluation(uint256 _proposalId) public whenNotPaused {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Evaluated && proposal.state != ProposalState.Voting) revert InvalidProposalState();
        
        uint256 challengerAuraTokenId = _ownerAuraTokenId[msg.sender];
        if (challengerAuraTokenId == 0) revert InvalidAuraTokenId(); // Must have an Aura NFT
        if (_auraReputationScore[challengerAuraTokenId] < int256(protocolParameters[keccak256("MIN_AURA_FOR_CHALLENGE")])) revert InsufficientStakedKWT(); // Using InsufficientStakedKWT as a generic "insufficient power"

        // For simplicity, a challenge moves the proposal to a 'Challenged' state
        // In a real system, this would trigger a more complex dispute resolution mechanism,
        // potentially involving a jury, re-evaluation, or a specific vote.
        proposal.state = ProposalState.Challenged;
        // Optionally, refund a portion of the proposer's stake if challenged successfully, or adjust reputation.

        emit AIOracleEvaluationChallenged(_proposalId, msg.sender);
    }

    // --- Utility Functions (not counted in 20+) ---

    /**
     * @dev Converts a uint256 to its string representation.
     * Minimal implementation, not for general purpose, but to build tokenURI.
     */
    function uint256ToString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }
}
```