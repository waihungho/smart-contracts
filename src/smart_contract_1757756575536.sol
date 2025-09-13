```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit uint256 operations, though 0.8+ has built-in checks

/**
 * @title SynergosNet
 * @dev A decentralized protocol for the collaborative creation, validation, and synthesis of verifiable knowledge,
 *      leveraging AI oracles and an adaptive reputation system. It aims to build a robust, community-driven
 *      knowledge base where contributions are transparent, validated, and incentivized.
 *
 * Core Concepts:
 * - Knowledge Artifact NFTs (KANs): Dynamic, soulbound NFTs representing verified knowledge contributions.
 *   Their metadata evolves with validation status and AI insights. KANs are non-transferable by default
 *   to ensure provenance and tie reputation directly to the contributor.
 * - Adaptive Reputation: Users earn reputation based on the quality of their submissions, successful validations,
 *   and effective challenge participation. Reputation impacts voting power, reward multipliers, and validation capacity.
 * - AI Oracle Integration: External AI services are utilized for content augmentation, summarization,
 *   cross-referencing, and potentially preliminary quality assessment of knowledge artifacts.
 * - Synthesis Bounties: Community-funded tasks for creating new knowledge by synthesizing existing KANs or
 *   addressing specific information gaps.
 * - Decentralized Governance: A DAO mechanism allows the community to evolve the protocol, register AI oracles,
 *   and set critical parameters.
 */
contract SynergosNet is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables & Data Structures ---

    IERC20 public synergosToken; // The native token for staking and rewards

    // KAN (Knowledge Artifact NFT)
    struct KAN {
        address owner;
        bytes32 artifactHash; // IPFS/Arweave hash of the core knowledge data
        string metadataURI;   // URI to off-chain metadata (e.g., description, related links)
        uint256 submissionBlock;
        bool isValidated;     // True if the KAN has passed initial validation
        bool isChallenged;    // True if the KAN is currently under dispute
        uint256 validationCount; // Number of successful validations
        uint256 challengeCount;  // Number of times this KAN has been successfully challenged
        string aiAugmentationURI; // URI to AI-generated augmentation/summary
    }
    Counters.Counter private _kanIds;
    mapping(uint256 => KAN) public kans;

    // AI Oracle
    struct AIOracle {
        string name;
        address oracleAddress;
        string capabilitiesURI; // URI describing the oracle's specific AI capabilities
        bool isActive;
    }
    Counters.Counter private _aiOracleIds;
    mapping(uint256 => AIOracle) public aiOracles;
    mapping(address => uint256) public aiOracleAddresses; // Map oracle address to ID for quick lookup

    // AI Augmentation Request
    struct AIAugmentationRequest {
        uint256 kanId;
        uint256 aiOracleId;
        address requester;
        bytes aiRequestData; // Data specific to the AI task
        uint256 requestBlock;
        bool isFulfilled;
        bytes aiResponseData; // Raw response from the AI oracle
    }
    Counters.Counter private _aiRequestIds;
    mapping(uint256 => AIAugmentationRequest) public aiAugmentationRequests;

    // Validator / Reputation System
    uint256 public MIN_STAKE_VALIDATION = 1000 * 10**18; // Example: 1000 tokens (adjust for token decimals)
    uint256 public constant REPUTATION_FOR_VALIDATION = 100; // Reputation points for correct validation
    uint256 public constant REPUTATION_FOR_CHALLENGE_WIN = 200; // Reputation points for winning a challenge
    uint256 public constant REPUTATION_FOR_KAN_SUBMISSION = 50; // Reputation points for submitting a KAN
    uint256 public constant REPUTATION_PENALTY_FOR_BAD_VALIDATION = 50; // Reputation loss for incorrect validation
    uint256 public constant REPUTATION_PENALTY_FOR_LOST_CHALLENGE = 100; // Reputation loss for losing a challenge

    mapping(address => uint256) public userStakes; // Amount of tokens staked by a user
    mapping(address => uint256) public userReputation; // Reputation score for a user
    mapping(address => uint252) private _userPendingRewards; // Placeholder for more complex reward tracking (using uint252 to save a tiny bit of storage)
    mapping(address => uint256) public unstakeCooldowns; // Block number when unstake is allowed for a user

    // Dispute System
    struct Dispute {
        uint256 kanId;
        address challenger;
        uint256 challengerStake;
        string challengeRationaleURI;
        uint256 startBlock;
        uint256 endBlock;
        bool resolved;
        uint256 votesForChallenger;
        uint256 votesAgainstChallenger;
        mapping(address => bool) hasVoted; // Tracks if a user has voted in this dispute
    }
    Counters.Counter private _disputeIds;
    mapping(uint256 => Dispute) public disputes;

    // Bounty System
    struct Bounty {
        address creator;
        string taskDescriptionURI;
        uint256 rewardAmount;
        uint256 creationBlock;
        uint256 durationBlocks;
        bool isActive;
        bool fulfilled; // True if a solution has been reviewed (approved or rejected)
        address solutionSolver;
        bytes32 solutionHash;
        string solutionMetadataURI;
        bool solutionApproved; // True if the submitted solution was approved
    }
    Counters.Counter private _bountyIds;
    mapping(uint256 => Bounty) public bounties;

    // Governance System
    struct Proposal {
        string descriptionURI;
        address targetContract;
        bytes callData;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if a user has voted in this proposal
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // Protocol Parameters (can be changed via governance)
    uint256 public disputeVotingPeriodBlocks = 500;
    uint256 public bountyReviewPeriodBlocks = 200;
    uint256 public proposalVotingPeriodBlocks = 1000;
    uint256 public proposalMinVotingPower = MIN_STAKE_VALIDATION; // Requires some stake or reputation to propose/vote
    uint256 public challengeStakeMultiplier = 2; // Challenge stake is X times MIN_STAKE_VALIDATION
    uint256 public unstakeCooldownDurationBlocks = 1000;
    uint256 public validationRewardPerCycle = 10 * 10**18; // Amount of tokens rewarded per successful validation (simplified)

    // --- Events ---
    event KANSubmitted(uint256 indexed kanId, address indexed owner, bytes32 artifactHash, string metadataURI);
    event KANMetadataUpdated(uint256 indexed kanId, string newMetadataURI);
    event AIAugmentationRequested(uint256 indexed requestId, uint256 indexed kanId, uint256 aiOracleId, address requester);
    event AIAugmentationFulfilled(uint256 indexed requestId, uint256 indexed kanId, bytes responseData);
    event StakedForValidation(address indexed user, uint256 amount);
    event UnstakeInitiated(address indexed user, uint256 amount, uint256 cooldownBlock);
    event UnstakeCompleted(address indexed user, uint256 amount);
    event KANValidated(uint256 indexed kanId, address indexed validator, bool isValid);
    event KANChallengeInitiated(uint256 indexed disputeId, uint256 indexed kanId, address indexed challenger, uint256 stakeAmount);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool supportChallenger);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed kanId, bool challengerWon);
    event ValidationRewardsClaimed(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event BountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, string descriptionURI);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed solver, bytes32 solutionHash);
    event BountySolutionReviewed(uint256 indexed bountyId, address indexed solver, bool isApproved);
    event BountyRewardClaimed(uint256 indexed bountyId, address indexed solver, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string descriptionURI);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolParameterSet(bytes32 indexed paramName, uint256 newValue);
    event AIOracleRegistered(uint256 indexed oracleId, address indexed oracleAddress, string name);
    event AIOracleUnregistered(uint256 indexed oracleId);

    // --- Modifiers ---
    modifier onlyAIOracle(uint256 _aiOracleId) {
        require(aiOracles[_aiOracleId].isActive, "SynergosNet: AI Oracle not active");
        require(msg.sender == aiOracles[_aiOracleId].oracleAddress, "SynergosNet: Not authorized AI Oracle");
        _;
    }

    modifier onlyValidator() {
        require(userStakes[msg.sender] >= MIN_STAKE_VALIDATION, "SynergosNet: Not enough stake to validate");
        _;
    }

    modifier hasVotingPower() {
        require(userStakes[msg.sender] >= proposalMinVotingPower || userReputation[msg.sender] > 0, "SynergosNet: Insufficient voting power (stake or reputation)");
        _;
    }

    // --- Constructor ---
    constructor(address _synergosTokenAddress) ERC721("KnowledgeArtifactNFT", "KAN") Ownable(msg.sender) {
        require(_synergosTokenAddress != address(0), "SynergosNet: Token address cannot be zero");
        synergosToken = IERC20(_synergosTokenAddress);
    }

    // --- Soulbound KAN Overrides (Preventing Transfers) ---
    // KANs are soulbound and cannot be transferred or approved for transfer,
    // ensuring they remain tied to the original contributor and their reputation.
    function _approve(address to, uint256 tokenId) internal override {
        revert("SynergosNet: KANs are soulbound and cannot be approved for transfer");
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert("SynergosNet: KANs are soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        revert("SynergosNet: KANs are soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        revert("SynergosNet: KANs are soulbound and cannot be transferred");
    }

    // --- I. Core Knowledge Artifact (KAN) Management (3 functions) ---

    /**
     * @dev Allows users to submit new knowledge artifacts. Mints a Soulbound KAN.
     * @param _artifactHash IPFS/Arweave hash of the core knowledge data.
     * @param _metadataURI URI to off-chain metadata (e.g., description, related links).
     */
    function submitKnowledgeArtifact(bytes32 _artifactHash, string memory _metadataURI) external {
        _kanIds.increment();
        uint256 newKanId = _kanIds.current();

        kans[newKanId] = KAN({
            owner: msg.sender,
            artifactHash: _artifactHash,
            metadataURI: _metadataURI,
            submissionBlock: block.number,
            isValidated: false,
            isChallenged: false,
            validationCount: 0,
            challengeCount: 0,
            aiAugmentationURI: ""
        });

        _mint(msg.sender, newKanId);
        _updateReputation(msg.sender, REPUTATION_FOR_KAN_SUBMISSION, true); // Increase reputation for contribution
        emit KANSubmitted(newKanId, msg.sender, _artifactHash, _metadataURI);
    }

    /**
     * @dev KAN owner can update the associated metadata URI.
     *      This allows for linking to new versions or enriched descriptions without changing the core hash.
     * @param _kanId The ID of the KAN to update.
     * @param _newMetadataURI The new URI for the metadata.
     */
    function updateKnowledgeArtifactMetadata(uint256 _kanId, string memory _newMetadataURI) external {
        require(_exists(_kanId), "SynergosNet: KAN does not exist");
        require(kans[_kanId].owner == msg.sender, "SynergosNet: Not KAN owner");
        kans[_kanId].metadataURI = _newMetadataURI;
        emit KANMetadataUpdated(_kanId, _newMetadataURI);
    }

    /**
     * @dev Retrieves detailed information about a KAN.
     * @param _kanId The ID of the KAN.
     * @return KAN struct details.
     */
    function getKANInfo(uint256 _kanId) external view returns (KAN memory) {
        require(_exists(_kanId), "SynergosNet: KAN does not exist");
        return kans[_kanId];
    }

    // --- II. AI Oracle Integration (2 functions) ---

    /**
     * @dev Requests an AI oracle to process and augment a specific KAN.
     *      In a full system, this would involve payment to the AI oracle (handled externally or via protocol fees).
     * @param _kanId The ID of the KAN to augment.
     * @param _aiOracleId The ID of the registered AI oracle.
     * @param _aiRequestData Specific data/parameters for the AI task.
     */
    function requestAI_Augmentation(uint256 _kanId, uint256 _aiOracleId, bytes memory _aiRequestData) external {
        require(_exists(_kanId), "SynergosNet: KAN does not exist");
        require(aiOracles[_aiOracleId].isActive, "SynergosNet: AI Oracle not active");
        
        // Placeholder for AI service payment. Would typically be:
        // require(synergosToken.transferFrom(msg.sender, address(this), aiServiceFee), "SynergosNet: Token transfer failed for AI service fee");
        
        _aiRequestIds.increment();
        uint256 newRequestId = _aiRequestIds.current();

        aiAugmentationRequests[newRequestId] = AIAugmentationRequest({
            kanId: _kanId,
            aiOracleId: _aiOracleId,
            requester: msg.sender,
            aiRequestData: _aiRequestData,
            requestBlock: block.number,
            isFulfilled: false,
            aiResponseData: ""
        });
        emit AIAugmentationRequested(newRequestId, _kanId, _aiOracleId, msg.sender);
    }

    /**
     * @dev Called by a registered AI oracle to deliver results for a previously requested augmentation.
     * @param _aiRequestId The ID of the augmentation request.
     * @param _aiResponseData Raw response data from the AI oracle (e.g., a new IPFS/Arweave URI).
     * @param _proof Cryptographic proof of the AI computation/result (optional, but good for verification).
     */
    function fulfillAI_Augmentation(uint256 _aiRequestId, bytes memory _aiResponseData, bytes memory _proof) external onlyAIOracle(aiAugmentationRequests[_aiRequestId].aiOracleId) {
        AIAugmentationRequest storage request = aiAugmentationRequests[_aiRequestId];
        require(!request.isFulfilled, "SynergosNet: AI Augmentation already fulfilled");

        request.isFulfilled = true;
        request.aiResponseData = _aiResponseData;
        kans[request.kanId].aiAugmentationURI = string(_aiResponseData); // Update KAN with AI-generated data link

        // In a real system, `_proof` would be verified here.
        // AI oracle can be rewarded here as well.
        // synergosToken.transfer(msg.sender, oracleRewardAmount); 

        emit AIAugmentationFulfilled(_aiRequestId, request.kanId, _aiResponseData);
    }

    // --- III. Validation & Reputation System (8 functions) ---

    /**
     * @dev Users stake tokens to participate in the validation process and earn rewards.
     * @param _amount The amount of SynergosToken to stake.
     */
    function stakeForValidation(uint256 _amount) external {
        require(_amount >= MIN_STAKE_VALIDATION, "SynergosNet: Stake amount too low");
        require(synergosToken.transferFrom(msg.sender, address(this), _amount), "SynergosNet: Token transfer failed");
        userStakes[msg.sender] = userStakes[msg.sender].add(_amount);
        emit StakedForValidation(msg.sender, _amount);
    }

    /**
     * @dev Allows validators to initiate unstaking their tokens after a cooldown period.
     *      Tokens become available after `unstakeCooldownDurationBlocks`.
     * @param _amount The amount of SynergosToken to unstake.
     */
    function unstakeValidationTokens(uint256 _amount) external {
        require(userStakes[msg.sender] >= _amount, "SynergosNet: Insufficient staked amount");
        
        if (unstakeCooldowns[msg.sender] == 0 || block.number > unstakeCooldowns[msg.sender]) {
            // If no cooldown active or cooldown has passed, initiate a new one
            unstakeCooldowns[msg.sender] = block.number.add(unstakeCooldownDurationBlocks);
            emit UnstakeInitiated(msg.sender, _amount, unstakeCooldowns[msg.sender]);
        }
        
        require(block.number > unstakeCooldowns[msg.sender], "SynergosNet: Unstake cooldown period not over");
        
        userStakes[msg.sender] = userStakes[msg.sender].sub(_amount);
        require(synergosToken.transfer(msg.sender, _amount), "SynergosNet: Failed to return staked tokens");
        
        if (userStakes[msg.sender] == 0) {
            unstakeCooldowns[msg.sender] = 0; // Reset cooldown if all stake is withdrawn
        } else {
             // For partial unstake, a new cooldown is effectively started or the existing one continued
             // For simplicity here, if there's still stake, the cooldown may remain (or refresh depending on design)
             // A more robust system would track individual unstake requests.
        }
        emit UnstakeCompleted(msg.sender, _amount);
    }


    /**
     * @dev Validators approve or disapprove a KAN, affecting their reputation.
     *      Requires the validator to be staked.
     * @param _kanId The ID of the KAN to validate.
     * @param _isValid True if the KAN is approved, false if disapproved.
     * @param _rationaleURI URI to an explanation for the validation decision.
     */
    function validateKnowledgeArtifact(uint256 _kanId, bool _isValid, string memory _rationaleURI) external onlyValidator {
        require(_exists(_kanId), "SynergosNet: KAN does not exist");
        require(!kans[_kanId].isChallenged, "SynergosNet: KAN is currently under challenge");
        
        // A more advanced system would ensure a user can only validate once per KAN
        // (e.g., using a mapping `mapping(uint256 => mapping(address => bool)) public hasValidatedKAN;`)

        if (_isValid) {
            kans[_kanId].validationCount = kans[_kanId].validationCount.add(1);
            _updateReputation(msg.sender, REPUTATION_FOR_VALIDATION, true);
            kans[_kanId].isValidated = true; // Mark as validated, this could be a threshold of validations
            _userPendingRewards[msg.sender] += validationRewardPerCycle; // Accumulate rewards
        } else {
            // Disapproval could lead to a challenge or a reputation penalty
            _updateReputation(msg.sender, REPUTATION_PENALTY_FOR_BAD_VALIDATION, false);
        }
        emit KANValidated(_kanId, msg.sender, _isValid);
    }

    /**
     * @dev Initiates a dispute by challenging a KAN's validity, requiring a stake.
     * @param _kanId The ID of the KAN to challenge.
     * @param _challengeRationaleURI URI to the challenger's detailed rationale.
     * @param _stakeAmount The amount of SynergosToken to stake for the challenge.
     */
    function challengeKnowledgeArtifact(uint256 _kanId, string memory _challengeRationaleURI, uint256 _stakeAmount) external {
        require(_exists(_kanId), "SynergosNet: KAN does not exist");
        require(!kans[_kanId].isChallenged, "SynergosNet: KAN already under challenge");
        require(_stakeAmount >= MIN_STAKE_VALIDATION.mul(challengeStakeMultiplier), "SynergosNet: Challenge stake too low");
        
        require(synergosToken.transferFrom(msg.sender, address(this), _stakeAmount), "SynergosNet: Token transfer failed");
        
        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        kans[_kanId].isChallenged = true;
        disputes[newDisputeId] = Dispute({
            kanId: _kanId,
            challenger: msg.sender,
            challengerStake: _stakeAmount,
            challengeRationaleURI: _challengeRationaleURI,
            startBlock: block.number,
            endBlock: block.number.add(disputeVotingPeriodBlocks),
            resolved: false,
            votesForChallenger: 0,
            votesAgainstChallenger: 0,
            hasVoted: new mapping(address => bool) // Initialize mapping for voters
        });
        emit KANChallengeInitiated(newDisputeId, _kanId, msg.sender, _stakeAmount);
    }

    /**
     * @dev Stakers/reputable users vote on the outcome of a challenged KAN.
     *      Voting power is a sum of staked tokens and reputation score.
     * @param _disputeId The ID of the dispute.
     * @param _supportChallenger True if voting for the challenger, false if against.
     */
    function voteOnDispute(uint256 _disputeId, bool _supportChallenger) external hasVotingPower {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "SynergosNet: Dispute already resolved");
        require(block.number <= dispute.endBlock, "SynergosNet: Voting period for dispute has ended");
        require(!dispute.hasVoted[msg.sender], "SynergosNet: Already voted in this dispute");

        uint256 votingPower = userStakes[msg.sender].add(userReputation[msg.sender]); // Combine stake and reputation
        require(votingPower > 0, "SynergosNet: Insufficient voting power");

        dispute.hasVoted[msg.sender] = true;
        if (_supportChallenger) {
            dispute.votesForChallenger = dispute.votesForChallenger.add(votingPower);
        } else {
            dispute.votesAgainstChallenger = dispute.votesAgainstChallenger.add(votingPower);
        }
        emit DisputeVoted(_disputeId, msg.sender, _supportChallenger);
    }

    /**
     * @dev Concludes a dispute based on voting, distributing stakes and adjusting reputations.
     *      Can be called by anyone after the voting period ends.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "SynergosNet: Dispute already resolved");
        require(block.number > dispute.endBlock, "SynergosNet: Voting period for dispute not over yet");

        dispute.resolved = true;
        kans[dispute.kanId].isChallenged = false; // KAN is no longer under challenge

        bool challengerWon = dispute.votesForChallenger > dispute.votesAgainstChallenger;

        if (challengerWon) {
            kans[dispute.kanId].isValidated = false; // KAN is invalidated
            kans[dispute.kanId].challengeCount = kans[dispute.kanId].challengeCount.add(1);
            _updateReputation(dispute.challenger, REPUTATION_FOR_CHALLENGE_WIN, true);
            
            // Challenger gets their stake back
            require(synergosToken.transfer(dispute.challenger, dispute.challengerStake), "SynergosNet: Failed to return challenger stake");
            // KAN owner's reputation could also be affected here.
            _updateReputation(kans[dispute.kanId].owner, REPUTATION_FOR_CHALLENGE_WIN / 2, false); 
        } else {
            // Challenger loses, their stake is distributed (e.g., to treasury or validators who voted against)
            synergosToken.transfer(owner(), dispute.challengerStake); // Send to owner (as a simplified treasury)
            _updateReputation(dispute.challenger, REPUTATION_PENALTY_FOR_LOST_CHALLENGE, false); // Challenger loses reputation
            // If the KAN was previously marked as invalid due to a challenge, it might be re-validated here.
            // For simplicity, we just ensure it's not marked as challenged.
        }
        emit DisputeResolved(_disputeId, dispute.kanId, challengerWon);
    }

    /**
     * @dev Allows active validators to claim their accumulated rewards.
     *      Rewards are based on contributions such as successful validations.
     */
    function claimValidationRewards() external {
        uint256 rewardAmount = _userPendingRewards[msg.sender];
        require(rewardAmount > 0, "SynergosNet: No pending rewards");
        require(synergosToken.balanceOf(address(this)) >= rewardAmount, "SynergosNet: Insufficient reward pool balance");
        
        _userPendingRewards[msg.sender] = 0; // Clear pending rewards before transfer
        require(synergosToken.transfer(msg.sender, rewardAmount), "SynergosNet: Failed to transfer reward");

        emit ValidationRewardsClaimed(msg.sender, rewardAmount);
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address of the user whose reputation is being updated.
     * @param _amount The amount of reputation points to add or subtract.
     * @param _increase True to increase, false to decrease.
     */
    function _updateReputation(address _user, uint256 _amount, bool _increase) internal {
        if (_increase) {
            userReputation[_user] = userReputation[_user].add(_amount);
        } else {
            userReputation[_user] = userReputation[_user].sub(_amount > userReputation[_user] ? userReputation[_user] : _amount);
        }
        emit ReputationUpdated(_user, userReputation[_user]);
    }

    // --- IV. Synthesis Bounty System (4 functions) ---

    /**
     * @dev Creates a bounty for specific knowledge synthesis tasks.
     *      Requires the reward amount to be transferred to the contract.
     * @param _taskDescriptionURI URI to the detailed description of the bounty task.
     * @param _rewardAmount The reward in SynergosToken for completing the bounty.
     * @param _durationBlocks The duration of the bounty in blocks, for solution submission.
     */
    function createSynthesisBounty(string memory _taskDescriptionURI, uint256 _rewardAmount, uint256 _durationBlocks) external {
        require(_rewardAmount > 0, "SynergosNet: Reward must be greater than zero");
        require(_durationBlocks > 0, "SynergosNet: Duration must be greater than zero");
        require(synergosToken.transferFrom(msg.sender, address(this), _rewardAmount), "SynergosNet: Token transfer failed for bounty reward");

        _bountyIds.increment();
        uint256 newBountyId = _bountyIds.current();

        bounties[newBountyId] = Bounty({
            creator: msg.sender,
            taskDescriptionURI: _taskDescriptionURI,
            rewardAmount: _rewardAmount,
            creationBlock: block.number,
            durationBlocks: _durationBlocks,
            isActive: true,
            fulfilled: false,
            solutionSolver: address(0),
            solutionHash: 0,
            solutionMetadataURI: "",
            solutionApproved: false
        });
        emit BountyCreated(newBountyId, msg.sender, _rewardAmount, _taskDescriptionURI);
    }

    /**
     * @dev Submit a solution to an active bounty.
     * @param _bountyId The ID of the bounty.
     * @param _solutionHash IPFS/Arweave hash of the solution data.
     * @param _solutionMetadataURI URI to the detailed metadata of the solution.
     */
    function submitBountySolution(uint256 _bountyId, bytes32 _solutionHash, string memory _solutionMetadataURI) external {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.isActive, "SynergosNet: Bounty is not active");
        require(block.number <= bounty.creationBlock.add(bounty.durationBlocks), "SynergosNet: Bounty submission period ended");
        require(bounty.solutionSolver == address(0), "SynergosNet: Bounty already has a solution submitted");

        bounty.solutionSolver = msg.sender;
        bounty.solutionHash = _solutionHash;
        bounty.solutionMetadataURI = _solutionMetadataURI;
        bounty.isActive = false; // Mark as inactive for new submissions, pending review.

        emit BountySolutionSubmitted(_bountyId, msg.sender, _solutionHash);
    }

    /**
     * @dev Bounty creator or DAO reviews and approves/rejects a submitted solution.
     * @param _bountyId The ID of the bounty.
     * @param _solver The address of the user who submitted the solution.
     * @param _isApproved True if the solution is approved, false if rejected.
     */
    function reviewBountySolution(uint256 _bountyId, address _solver, bool _isApproved) external {
        Bounty storage bounty = bounties[_bountyId];
        // Allow bounty creator or DAO (represented by owner for this example) to review
        require(bounty.creator == msg.sender || owner() == msg.sender, "SynergosNet: Not bounty creator or DAO");
        require(bounty.solutionSolver == _solver, "SynergosNet: Solver address mismatch");
        require(!bounty.fulfilled, "SynergosNet: Bounty already fulfilled");
        require(block.number <= bounty.creationBlock.add(bounty.durationBlocks).add(bountyReviewPeriodBlocks), "SynergosNet: Bounty review period ended");

        bounty.solutionApproved = _isApproved;
        bounty.fulfilled = true; // Mark as fulfilled, whether approved or rejected.

        if (_isApproved) {
            _updateReputation(_solver, REPUTATION_FOR_KAN_SUBMISSION * 2, true); // Reward higher reputation for bounty solution
        } else {
            // Reopen bounty if rejected
            bounty.solutionSolver = address(0);
            bounty.solutionHash = 0;
            bounty.solutionMetadataURI = "";
            bounty.isActive = true; // Re-activate for new submissions
            bounty.fulfilled = false; // Reset to allow new submissions
            bounty.creationBlock = block.number; // Reset duration for new attempts.
            bounty.solutionApproved = false;
        }
        emit BountySolutionReviewed(_bountyId, _solver, _isApproved);
    }

    /**
     * @dev Solvers claim their reward upon successful bounty approval.
     * @param _bountyId The ID of the bounty.
     */
    function claimBountyReward(uint256 _bountyId) external {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.solutionSolver == msg.sender, "SynergosNet: Not the solver of this bounty");
        require(bounty.fulfilled && bounty.solutionApproved, "SynergosNet: Bounty not approved or fulfilled");
        require(bounty.rewardAmount > 0, "SynergosNet: Reward already claimed or zero"); // Prevent double claim and zero claim
        require(synergosToken.balanceOf(address(this)) >= bounty.rewardAmount, "SynergosNet: Insufficient contract balance for reward");
        
        uint256 reward = bounty.rewardAmount;
        bounty.rewardAmount = 0; // Clear bounty reward amount to prevent re-claiming

        require(synergosToken.transfer(msg.sender, reward), "SynergosNet: Failed to transfer bounty reward");
        emit BountyRewardClaimed(_bountyId, msg.sender, reward);
    }

    // --- V. Decentralized Governance (7 functions) ---

    /**
     * @dev Proposes a generic protocol upgrade or parameter change.
     *      Requires a user with sufficient voting power.
     * @param _descriptionURI URI to the detailed description of the proposal.
     * @param _target The address of the contract to call (e.g., this contract for parameter changes).
     * @param _callData The encoded function call to execute if the proposal passes.
     */
    function proposeProtocolUpgrade(string memory _descriptionURI, address _target, bytes memory _callData) external hasVotingPower {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            descriptionURI: _descriptionURI,
            targetContract: _target,
            callData: _callData,
            startBlock: block.number,
            endBlock: block.number.add(proposalVotingPeriodBlocks),
            executed: false,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)
        });
        emit ProposalCreated(newProposalId, msg.sender, _descriptionURI);
    }

    /**
     * @dev Users with reputation or stake vote on active governance proposals.
     * @param _proposalId The ID of the proposal.
     * @param _support True if voting in favor, false if against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external hasVotingPower {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "SynergosNet: Proposal already executed");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "SynergosNet: Voting period not active");
        require(!proposal.hasVoted[msg.sender], "SynergosNet: Already voted on this proposal");

        uint256 votingPower = userStakes[msg.sender].add(userReputation[msg.sender]);
        require(votingPower > 0, "SynergosNet: Insufficient voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes an approved governance proposal.
     *      Can be called by anyone after the voting period ends and if approved.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "SynergosNet: Proposal already executed");
        require(block.number > proposal.endBlock, "SynergosNet: Voting period not over");
        require(proposal.votesFor > proposal.votesAgainst, "SynergosNet: Proposal not approved"); // Majority vote required

        proposal.executed = true;
        (bool success, bytes memory returndata) = proposal.targetContract.call(proposal.callData);
        require(success, string(abi.encodePacked("SynergosNet: Proposal execution failed: ", returndata)));

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev DAO or admin can adjust key protocol parameters. This function is designed to be called
     *      via `executeProposal` after a governance vote. It's marked `onlyOwner` for initial setup
     *      or emergency, but in a full DAO, direct owner calls would be removed.
     * @param _paramName The name of the parameter to change (e.g., "minStakeValidation").
     * @param _newValue The new value for the parameter.
     */
    function setProtocolParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner {
        if (_paramName == "minStakeValidation") {
            MIN_STAKE_VALIDATION = _newValue;
        } else if (_paramName == "disputeVotingPeriodBlocks") {
            disputeVotingPeriodBlocks = _newValue;
        } else if (_paramName == "bountyReviewPeriodBlocks") {
            bountyReviewPeriodBlocks = _newValue;
        } else if (_paramName == "proposalVotingPeriodBlocks") {
            proposalVotingPeriodBlocks = _newValue;
        } else if (_paramName == "proposalMinVotingPower") {
            proposalMinVotingPower = _newValue;
        } else if (_paramName == "challengeStakeMultiplier") {
            challengeStakeMultiplier = _newValue;
        } else if (_paramName == "unstakeCooldownDurationBlocks") {
            unstakeCooldownDurationBlocks = _newValue;
        } else if (_paramName == "validationRewardPerCycle") {
            validationRewardPerCycle = _newValue;
        }
        else {
            revert("SynergosNet: Unknown protocol parameter");
        }
        emit ProtocolParameterSet(_paramName, _newValue);
    }

    /**
     * @dev Registers a new AI oracle for the network. Intended to be called via governance.
     *      Marked `onlyOwner` for initial setup/emergency.
     * @param _name Name of the AI oracle.
     * @param _oracleAddress The contract address of the AI oracle.
     * @param _capabilitiesURI URI describing the oracle's specific AI capabilities.
     */
    function registerAI_Oracle(string memory _name, address _oracleAddress, string memory _capabilitiesURI) external onlyOwner {
        require(_oracleAddress != address(0), "SynergosNet: Oracle address cannot be zero");
        require(aiOracleAddresses[_oracleAddress] == 0, "SynergosNet: Oracle address already registered"); // Ensure unique registration
        _aiOracleIds.increment();
        uint256 newOracleId = _aiOracleIds.current();

        aiOracles[newOracleId] = AIOracle({
            name: _name,
            oracleAddress: _oracleAddress,
            capabilitiesURI: _capabilitiesURI,
            isActive: true
        });
        aiOracleAddresses[_oracleAddress] = newOracleId;

        emit AIOracleRegistered(newOracleId, _oracleAddress, _name);
    }

    /**
     * @dev Unregisters an existing AI oracle. Intended to be called via governance.
     *      Marked `onlyOwner` for initial setup/emergency.
     * @param _aiOracleId The ID of the AI oracle to unregister.
     */
    function unregisterAI_Oracle(uint256 _aiOracleId) external onlyOwner {
        require(_aiOracleId > 0 && _aiOracleId <= _aiOracleIds.current(), "SynergosNet: Invalid AI Oracle ID");
        require(aiOracles[_aiOracleId].isActive, "SynergosNet: AI Oracle not active or already unregistered");
        aiOracles[_aiOracleId].isActive = false;
        delete aiOracleAddresses[aiOracles[_aiOracleId].oracleAddress]; // Clear mapping entry
        emit AIOracleUnregistered(_aiOracleId);
    }

    // --- Helper Functions ---
    /**
     * @dev Checks if a KAN with the given ID exists.
     * @param tokenId The ID of the KAN.
     * @return True if the KAN exists, false otherwise.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        // Checks if the ID is within range and if the KAN has an owner (meaning it was minted).
        return tokenId > 0 && tokenId <= _kanIds.current() && kans[tokenId].owner != address(0);
    }
}
```