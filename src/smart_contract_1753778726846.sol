This smart contract, `CognitoNet`, is designed as a decentralized knowledge and insight network. It aims to create a self-sustaining ecosystem for verified, AI-augmented knowledge by facilitating the submission, validation, and curation of knowledge modules. It leverages a unique reputation-based governance model using Soul-Bound Tokens (SBTs) and integrates with off-chain AI computation providers for generating and verifying complex insights.

---

**Contract: CognitoNet**

**Outline:**

1.  **Core Data Structures & State Management:** Defines the fundamental units of knowledge (Knowledge Modules, Insight Proposals, Insight Packs) and the various participant roles (Contributors, Validators, Curators, AI Providers).
2.  **Reputation & Governance (SBT-based):** Implements a non-transferable reputation system (`SBT_REP`) that influences participant privileges, voting power, and rewards. It includes mechanisms for earning, losing, and utilizing this reputation.
3.  **Knowledge Module Lifecycle:** Governs the process of submitting atomic knowledge units, their validation by the community of validators, and their eventual approval or rejection.
4.  **Insight Proposal Lifecycle (AI-Assisted):** Manages the proposing of complex insights that may require off-chain AI computation. This section includes functionalities for AI providers to submit results and for validators to verify these AI-generated outputs.
5.  **Curation & Marketplace:** Enables high-reputation "Curators" to assemble approved insights into marketable "Insight Packs" (represented as unique, purchasable NFTs), forming a decentralized knowledge marketplace.
6.  **Economic & Incentive Layer:** Details the `COG` token mechanics for staking, rewarding accurate contributions and validations, and applying penalties (slashing) for malicious or inaccurate actions.
7.  **Access Control & Utilities:** Provides administrative functions for contract parameters and helpful view functions for querying state.

---

**Function Summary (26 functions):**

**I. Core Data Management & Submission**

1.  `submitKnowledgeModule(string _hash, string _metadataURI)`: Allows a user to submit a new atomic piece of knowledge (e.g., a factual statement, a dataset reference) to the network for validation. The content is referenced by an IPFS/Arweave hash, with additional metadata.
2.  `updateKnowledgeModule(uint256 _kmId, string _newHash, string _newMetadataURI)`: Enables the original contributor to update their submitted Knowledge Module, typically when it's still in a pending state, allowing for corrections or improvements.
3.  `proposeInsight(string _title, string _description, uint256[] _sourceKMs, string _expectedOutcomeHash, uint256 _rewardBounty)`: A user proposes a complex insight (e.g., a prediction, an analysis, a synthesis) that might require sophisticated off-chain AI computation. They link to approved Knowledge Modules as sources and set a `COG` token bounty for an AI provider.

**II. Validator & Curator Operations (Reputation-Driven)**

4.  `stakeAsValidator(uint256 _amount)`: A user stakes `COG` tokens to become an active validator. Validators participate in the voting process for KMs and IPs and are eligible for rewards and subject to slashing.
5.  `unstakeAsValidator(uint256 _amount)`: Initiates the process for a validator to withdraw a portion or all of their staked `COG` tokens, subject to a cooldown period.
6.  `withdrawUnstakedAmount()`: Allows a validator to finalize the withdrawal of their unstaked `COG` tokens after the cooldown period has elapsed.
7.  `voteOnKnowledgeModule(uint256 _kmId, bool _approval, string _reasonHash)`: An active validator casts a vote (approve/reject) on a submitted Knowledge Module, influencing its status and their own reputation.
8.  `voteOnInsightProposal(uint256 _ipId, bool _approval, string _reasonHash)`: An active validator casts a vote on the correctness of an AI-generated result for a specific Insight Proposal.
9.  `challengeValidatorVote(address _validatorAddress, uint256 _targetId, bool _isKM, string _proofHash)`: Allows any user with reputation to challenge a validator's vote on a Knowledge Module or an AI result, providing evidence for their claim. This initiates a challenge period.
10. `finalizeChallenge(address _challengedValidator, uint256 _targetId, bool _isKM)`: Called by anyone after a challenge period ends to resolve a challenge. Based on predefined criteria (e.g., outcome of majority vote vs. challenged vote), reputation is adjusted, and stakes may be slashed.
11. `becomeCurator()`: Enables a validator who has accumulated sufficient reputation (`SBT_REP` score) to upgrade to a Curator role, granting them the ability to create Insight Packs.
12. `curateInsightPack(uint256[] _ipIds, string _title, string _description, string _coverURI, uint256 _price)`: A Curator assembles a collection of verified Insight Proposals into a new, unique "Insight Pack" (represented as an NFT) and sets its price.

**III. AI Oracle & Off-chain Integration**

13. `registerAIOffchainProvider(address _providerAddress, string _serviceURI)`: The contract owner registers an off-chain AI service provider, allowing them to participate in the network by computing insights.
14. `submitAIOffchainResult(uint256 _ipId, string _resultHash, uint256 _computationFee)`: A registered AI provider submits the hash of their computed result for an Insight Proposal, claiming the associated bounty.
15. `verifyAIOffchainResult(uint256 _ipId, bool _isCorrect, string _reasonHash)`: (Conceptual) This function represents the validator's role in assessing the correctness of an AI's submitted result. In practice, `voteOnInsightProposal` performs this verification.
16. `rewardAIOffchainProvider(uint256 _ipId)`: Distributes the `COG` token bounty to the AI provider once their submitted result for an Insight Proposal has been successfully verified by validators.

**IV. Reputation, Rewards & Economy**

17. `getReputationScore(address _user)`: Retrieves the non-transferable `SBT_REP` score for a given user, reflecting their standing and influence in the network.
18. `distributeValidationRewards()`: An owner-callable function that periodically distributes `COG` token rewards to active validators based on their accumulated accurate votes since the last distribution.
19. `slashStake(address _validatorAddress, uint256 _amount)`: An internal function used to penalize validators by reducing their staked `COG` tokens, typically triggered by a successful challenge.
20. `claimCuratorFees(uint256 _insightPackId)`: Allows the Curator of an Insight Pack to claim their percentage of the revenue generated from its sales.

**V. Marketplace & Access**

21. `purchaseInsightPack(uint256 _insightPackId)`: Enables any user to purchase an Insight Pack NFT using `COG` tokens, gaining ownership of the curated knowledge product.
22. `getInsightPackDetails(uint256 _insightPackId)`: Provides comprehensive details about a specific Insight Pack, including its curator, content (linked IPs), pricing, and ownership.
23. `setInsightPackPrice(uint256 _insightPackId, uint256 _newPrice)`: Allows the Curator of an Insight Pack to adjust its selling price.
24. `isKnowledgeModuleApproved(uint256 _kmId)`: A view function to check if a specific Knowledge Module has been approved by the validator community.
25. `isInsightProposalVerified(uint256 _ipId)`: A view function to check if an Insight Proposal and its associated AI-generated result have been successfully verified.
26. `getApprovedSourceKMs(uint256 _ipId)`: Returns an array of approved Knowledge Module IDs that were cited as sources for a specific Insight Proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// This smart contract, CognitoNet, is designed as a decentralized knowledge and insight network.
// It facilitates the submission, validation, and curation of knowledge modules,
// leveraging reputation-based governance and integrating with off-chain AI computation providers.
// The core idea is to create a self-sustaining ecosystem for verified, AI-augmented knowledge.

// Outline:
// I. Core Data Structures & State Management: Defines the fundamental units of knowledge, proposals, packs, and participant roles.
// II. Reputation & Governance (SBT-based): Mechanisms for earning, losing, and utilizing non-transferable reputation.
// III. Knowledge Module Lifecycle: Submission, validation, and approval of atomic knowledge units.
// IV. Insight Proposal Lifecycle (AI-Assisted): Proposing complex insights, engaging off-chain AI for computation, and on-chain verification of AI results.
// V. Curation & Marketplace: Assembling validated insights into marketable "Insight Packs" (NFTs).
// VI. Economic & Incentive Layer: Staking, rewards, fees, and slashing mechanisms using the native COG token.
// VII. Access Control & Utilities: Permissions, administrative functions, and helper views.

// Function Summary:
// I. Core Data Management & Submission
// 1.  submitKnowledgeModule(string _hash, string _metadataURI): Contributor submits a new atomic piece of knowledge for validation.
// 2.  updateKnowledgeModule(uint256 _kmId, string _newHash, string _newMetadataURI): Allows a KM contributor to update their module under specific conditions.
// 3.  proposeInsight(string _title, string _description, uint256[] _sourceKMs, string _expectedOutcomeHash, uint256 _rewardBounty): Proposer submits a high-level insight idea, potentially requiring AI computation, linking source KMs.

// II. Validator & Curator Operations (Reputation-Driven)
// 4.  stakeAsValidator(uint256 _amount): Stakes COG tokens to become an active validator, enabling voting rights.
// 5.  unstakeAsValidator(uint256 _amount): Initiates the unstaking process with a cooldown period.
// 6.  withdrawUnstakedAmount(): Allows validators to withdraw their unstaked COG tokens after the cooldown period.
// 7.  voteOnKnowledgeModule(uint256 _kmId, bool _approval, string _reasonHash): Validator casts a vote on a submitted Knowledge Module.
// 8.  voteOnInsightProposal(uint256 _ipId, bool _approval, string _reasonHash): Validator casts a vote on an Insight Proposal's AI result.
// 9.  challengeValidatorVote(address _validatorAddress, uint256 _targetId, bool _isKM, string _proofHash): Allows any user to challenge a validator's vote with evidence, risking their own reputation/stake.
// 10. finalizeChallenge(address _challengedValidator, uint256 _targetId, bool _isKM): Called after a challenge period to apply reputation changes and potential slashes based on outcome.
// 11. becomeCurator(): Allows a highly reputed validator to upgrade to a Curator role.
// 12. curateInsightPack(uint256[] _ipIds, string _title, string _description, string _coverURI, uint256 _price): Curator assembles approved Insight Proposals into a saleable Insight Pack NFT.

// III. AI Oracle & Off-chain Integration
// 13. registerAIOffchainProvider(address _providerAddress, string _serviceURI): An AI service provider registers to offer computation services.
// 14. submitAIOffchainResult(uint256 _ipId, string _resultHash, uint256 _computationFee): Registered AI provider submits the computed result for an Insight Proposal.
// 15. verifyAIOffchainResult(uint256 _ipId, bool _isCorrect, string _reasonHash): Validators vote on the correctness of a submitted AI result (function internally calls voteOnInsightProposal).
// 16. rewardAIOffchainProvider(uint256 _ipId): Distributes bounty to the AI provider once their result is verified and accepted.

// IV. Reputation, Rewards & Economy
// 17. getReputationScore(address _user): Retrieves the non-transferable reputation score of a user.
// 18. distributeValidationRewards(): Periodically called by the owner to reward validators based on their accurate voting.
// 19. slashStake(address _validatorAddress, uint256 _amount): Internally called function to reduce a validator's stake due to penalties.
// 20. claimCuratorFees(uint256 _insightPackId): Curator claims accumulated fees from sales of their curated Insight Pack.

// V. Marketplace & Access
// 21. purchaseInsightPack(uint256 _insightPackId): User buys an Insight Pack NFT, gaining access to its contents.
// 22. getInsightPackDetails(uint256 _insightPackId): Retrieves details of a specific Insight Pack.
// 23. setInsightPackPrice(uint256 _insightPackId, uint256 _newPrice): Curator adjusts the price of their Insight Pack.
// 24. isKnowledgeModuleApproved(uint256 _kmId): Checks if a knowledge module has been approved by validators.
// 25. isInsightProposalVerified(uint256 _ipId): Checks if an insight proposal and its AI result have been verified.
// 26. getApprovedSourceKMs(uint256 _ipId): Returns an array of approved Knowledge Module IDs linked to a specific Insight Proposal.

contract CognitoNet is Ownable, ReentrancyGuard {
    IERC20 public immutable COG_TOKEN; // The utility token for staking, rewards, and payments

    // --- Configuration Constants ---
    uint256 public MIN_VALIDATOR_STAKE; // Example: 1000 COG tokens (set by owner)
    uint256 public MIN_REPUTATION_FOR_CURATOR; // (set by owner)
    uint256 public constant VALIDATION_PERIOD_SECONDS = 7 days;
    uint256 public constant CHALLENGE_PERIOD_SECONDS = 3 days;
    uint256 public constant UNSTAKE_COOLDOWN_SECONDS = 14 days;
    uint256 public constant REPUTATION_GAIN_PER_ACCURATE_VOTE = 5;
    uint256 public constant REPUTATION_LOSS_PER_INACCURATE_VOTE = 10;
    uint256 public constant REPUTATION_LOSS_ON_CHALLENGE = 20; // For challenged validator
    uint256 public constant REPUTATION_GAIN_ON_CHALLENGE = 15; // For successful challenger

    uint256 public curatorFeePercentage = 5; // 5% of Insight Pack sales go to the curator (adjustable by owner)

    // --- State Variables ---

    // Reputation (SBT_REP) - non-transferable
    mapping(address => uint256) private _sbtRepScores; // Represents reputation, a non-transferable Soul-Bound Token score
    mapping(address => bool) private _hasSbtRepToken; // Indicates if an address has been issued an SBT_REP

    // Knowledge Module (KM)
    enum KnowledgeModuleStatus { Pending, Approved, Rejected, Challenged }
    struct KnowledgeModule {
        address contributor;
        string hash; // IPFS/Arweave hash of the KM content
        string metadataURI; // URI for additional metadata (e.g., description, tags)
        KnowledgeModuleStatus status;
        uint256 creationTime;
        mapping(address => bool) voted; // Track if a validator has voted
        mapping(address => bool) voteApproval; // True for approval, false for rejection
        uint256 upvotes;
        uint256 downvotes;
        uint256 validationEndTime;
        address challenger; // Address of the challenger if currently challenged
        uint256 challengeEndTime;
        string challengeProofHash;
    }
    uint256 public nextKnowledgeModuleId;
    mapping(uint256 => KnowledgeModule) public knowledgeModules;

    // Insight Proposal (IP)
    enum InsightProposalStatus { Pending, AI_AwaitingResult, AI_ResultSubmitted, AI_ResultVerified, Rejected }
    struct InsightProposal {
        address proposer;
        string title;
        string description;
        uint256[] sourceKMs; // Array of approved Knowledge Module IDs
        string expectedOutcomeHash; // Hash of the expected AI computation result
        uint256 rewardBounty; // COG tokens allocated for AI provider
        InsightProposalStatus status;
        uint256 creationTime;
        address aiProvider;
        string aiResultHash;
        uint256 aiComputationFee;
        mapping(address => bool) votedForAIResult; // Track validator votes on AI result
        mapping(address => bool) aiResultApproval; // True for approval of AI result
        uint256 aiResultUpvotes;
        uint256 aiResultDownvotes;
        uint256 verificationEndTime;
        address challenger; // Address of the challenger if AI result is challenged
        uint256 challengeEndTime;
        string challengeProofHash;
    }
    uint256 public nextInsightProposalId;
    mapping(uint256 => InsightProposal) public insightProposals;

    // Validator
    struct Validator {
        uint259 stakedAmount;
        bool isActive;
        uint259 pendingUnstakeAmount;
        uint256 unstakeCooldownEndTime;
        uint259 accurateVotesCount; // For reward calculation
        uint259 inaccurateVotesCount; // For potential future penalty scaling
    }
    mapping(address => Validator) public validators;
    address[] public activeValidators; // To iterate over active validators for reward distribution

    // Curator
    mapping(address => bool) public isCurator;

    // AI Provider
    struct AIProvider {
        string serviceURI; // URI pointing to the AI service details
        bool isActive;
    }
    mapping(address => AIProvider) public aiProviders;

    // Insight Pack (NFT-like)
    struct InsightPack {
        address curator;
        uint256[] ipIds; // Array of verified Insight Proposal IDs
        string title;
        string description;
        string coverURI; // URI for pack's visual representation
        uint256 price; // Price in COG tokens
        uint256 creationTime;
        uint256 totalSalesRevenue;
    }
    uint256 public nextInsightPackId;
    mapping(uint256 => InsightPack) public insightPacks;
    mapping(uint256 => address) private _ownerOfInsightPack; // NFT ownership tracking
    mapping(address => uint256[]) private _insightPacksOwned; // Track NFTs owned by an address

    // --- Events ---
    event KnowledgeModuleSubmitted(uint256 indexed kmId, address indexed contributor, string hash, string metadataURI);
    event KnowledgeModuleStatusChanged(uint256 indexed kmId, KnowledgeModuleStatus newStatus);
    event InsightProposalSubmitted(uint256 indexed ipId, address indexed proposer, string title, uint256 rewardBounty);
    event InsightProposalStatusChanged(uint256 indexed ipId, InsightProposalStatus newStatus);
    event ValidatorStaked(address indexed validator, uint256 amount, uint256 currentStake);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event VoteCast(address indexed voter, uint256 indexed targetId, bool isKM, bool approval);
    event ChallengeInitiated(address indexed challenger, address indexed challenged, uint256 indexed targetId, bool isKM, string proofHash);
    event ChallengeFinalized(address indexed challenger, address indexed challenged, uint256 indexed targetId, bool isKM, bool challengerWon);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event CuratorPromoted(address indexed newCurator);
    event InsightPackCurated(uint256 indexed packId, address indexed curator, uint256 price);
    event InsightPackPurchased(uint256 indexed packId, address indexed buyer, uint256 price);
    event AIOffchainProviderRegistered(address indexed provider, string serviceURI);
    event AIOffchainResultSubmitted(uint256 indexed ipId, address indexed provider, string resultHash, uint256 fee);
    event AIOffchainResultVerified(uint256 indexed ipId, bool verified);
    event RewardsDistributed(address indexed validator, uint256 amount);
    event FeesClaimed(address indexed curator, uint256 amount);

    // --- Constructor ---
    constructor(address _cogTokenAddress, uint256 _minValidatorStake, uint256 _minReputationForCurator) Ownable(msg.sender) {
        require(_cogTokenAddress != address(0), "Invalid COG token address");
        COG_TOKEN = IERC20(_cogTokenAddress);
        MIN_VALIDATOR_STAKE = _minValidatorStake;
        MIN_REPUTATION_FOR_CURATOR = _minReputationForCurator;
        nextKnowledgeModuleId = 1;
        nextInsightProposalId = 1;
        nextInsightPackId = 1;
    }

    // --- Modifiers ---
    modifier onlyValidator() {
        require(validators[msg.sender].isActive, "Caller is not an active validator");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Caller is not a curator");
        _;
    }

    modifier onlyAIProvider() {
        require(aiProviders[msg.sender].isActive, "Caller is not a registered AI provider");
        _;
    }

    modifier ensureHasReputation() {
        if (!_hasSbtRepToken[msg.sender]) {
            _mintSBTRepToken(msg.sender);
        }
        _;
    }

    // --- Internal SBT-like (Reputation) Functions ---
    function _mintSBTRepToken(address _user) internal {
        require(!_hasSbtRepToken[_user], "SBT_REP already issued");
        _hasSbtRepToken[_user] = true;
        _sbtRepScores[_user] = 0; // Start with a base score, or 0
        emit ReputationUpdated(_user, _sbtRepScores[_user]);
    }

    function _updateReputation(address _user, int256 _points) internal {
        if (!_hasSbtRepToken[_user]) {
            _mintSBTRepToken(_user);
        }
        unchecked { // Safe for uint256 if _points can be negative, ensures it doesn't underflow below 0.
            if (_points < 0) {
                _sbtRepScores[_user] = _sbtRepScores[_user] > uint256(-_points) ? _sbtRepScores[_user] - uint256(-_points) : 0;
            } else {
                _sbtRepScores[_user] += uint256(_points);
            }
        }
        emit ReputationUpdated(_user, _sbtRepScores[_user]);
    }

    // --- Internal Insight Pack (NFT-like) Functions ---
    function _mintInsightPack(address _to, uint256 _packId) internal {
        require(_ownerOfInsightPack[_packId] == address(0), "InsightPack already minted");
        _ownerOfInsightPack[_packId] = _to;
        _insightPacksOwned[_to].push(_packId);
    }

    function _transferInsightPack(address _from, address _to, uint256 _packId) internal {
        require(_ownerOfInsightPack[_packId] == _from, "Not owner of InsightPack");
        _ownerOfInsightPack[_packId] = _to;
        // Simplified array manipulation for ownership transfer. In a full ERC721, this is handled by _beforeTokenTransfer, _afterTokenTransfer hooks.
        uint256 indexToRemove = type(uint256).max;
        for (uint256 i = 0; i < _insightPacksOwned[_from].length; i++) {
            if (_insightPacksOwned[_from][i] == _packId) {
                indexToRemove = i;
                break;
            }
        }
        require(indexToRemove != type(uint256).max, "Pack not found in owner's list"); // Should not happen if _ownerOfInsightPack is correct

        if (indexToRemove != _insightPacksOwned[_from].length - 1) {
            _insightPacksOwned[_from][indexToRemove] = _insightPacksOwned[_from][_insightPacksOwned[_from].length - 1];
        }
        _insightPacksOwned[_from].pop();
        
        _insightPacksOwned[_to].push(_packId);
    }

    // --- I. Core Data Management & Submission ---

    /// @notice Contributor submits a new atomic piece of knowledge for validation.
    /// @param _hash IPFS/Arweave hash of the KM content.
    /// @param _metadataURI URI for additional metadata.
    function submitKnowledgeModule(string calldata _hash, string calldata _metadataURI) external ensureHasReputation {
        uint256 kmId = nextKnowledgeModuleId++;
        KnowledgeModule storage km = knowledgeModules[kmId];
        km.contributor = msg.sender;
        km.hash = _hash;
        km.metadataURI = _metadataURI;
        km.status = KnowledgeModuleStatus.Pending;
        km.creationTime = block.timestamp;
        km.validationEndTime = block.timestamp + VALIDATION_PERIOD_SECONDS;
        emit KnowledgeModuleSubmitted(kmId, msg.sender, _hash, _metadataURI);
    }

    /// @notice Allows a KM contributor to update their module under specific conditions (e.g., if pending).
    /// @param _kmId The ID of the Knowledge Module to update.
    /// @param _newHash New IPFS/Arweave hash.
    /// @param _newMetadataURI New metadata URI.
    function updateKnowledgeModule(uint256 _kmId, string calldata _newHash, string calldata _newMetadataURI) external {
        KnowledgeModule storage km = knowledgeModules[_kmId];
        require(km.contributor == msg.sender, "Only KM contributor can update");
        require(km.status == KnowledgeModuleStatus.Pending, "KM must be in Pending status to update");
        km.hash = _newHash;
        km.metadataURI = _newMetadataURI;
        // No new event for update, as it essentially modifies the existing submission.
        // Can add a specific event if detailed history of updates is required.
    }

    /// @notice Proposer submits a high-level insight idea, potentially requiring AI computation, linking source KMs.
    /// @param _title Title of the insight.
    /// @param _description Description of the insight.
    /// @param _sourceKMs Array of IDs of approved Knowledge Modules relevant to this insight.
    /// @param _expectedOutcomeHash Hash of the expected AI computation result.
    /// @param _rewardBounty COG tokens allocated as a bounty for the AI provider.
    function proposeInsight(
        string calldata _title,
        string calldata _description,
        uint256[] calldata _sourceKMs,
        string calldata _expectedOutcomeHash,
        uint256 _rewardBounty
    ) external nonReentrant ensureHasReputation {
        for (uint256 i = 0; i < _sourceKMs.length; i++) {
            require(knowledgeModules[_sourceKMs[i]].status == KnowledgeModuleStatus.Approved, "All source KMs must be approved");
        }
        require(COG_TOKEN.transferFrom(msg.sender, address(this), _rewardBounty), "Token transfer failed for bounty");

        uint256 ipId = nextInsightProposalId++;
        InsightProposal storage ip = insightProposals[ipId];
        ip.proposer = msg.sender;
        ip.title = _title;
        ip.description = _description;
        ip.sourceKMs = _sourceKMs;
        ip.expectedOutcomeHash = _expectedOutcomeHash;
        ip.rewardBounty = _rewardBounty;
        ip.status = InsightProposalStatus.Pending;
        ip.creationTime = block.timestamp;
        emit InsightProposalSubmitted(ipId, msg.sender, _title, _rewardBounty);
    }

    // --- II. Validator & Curator Operations (Reputation-Driven) ---

    /// @notice Stakes COG tokens to become an active validator.
    /// @param _amount The amount of COG tokens to stake.
    function stakeAsValidator(uint256 _amount) external nonReentrant ensureHasReputation {
        require(_amount >= MIN_VALIDATOR_STAKE, "Stake amount too low");
        require(COG_TOKEN.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        Validator storage validator = validators[msg.sender];
        if (!validator.isActive) {
            validator.isActive = true;
            activeValidators.push(msg.sender);
        }
        validator.stakedAmount += _amount;
        emit ValidatorStaked(msg.sender, _amount, validator.stakedAmount);
    }

    /// @notice Initiates the unstaking process with a cooldown period.
    /// @param _amount The amount of COG tokens to unstake.
    function unstakeAsValidator(uint256 _amount) external nonReentrant {
        Validator storage validator = validators[msg.sender];
        require(validator.isActive, "Not an active validator");
        require(validator.stakedAmount >= _amount, "Insufficient staked amount");
        require(validator.stakedAmount - _amount >= MIN_VALIDATOR_STAKE || _amount == validator.stakedAmount, "Remaining stake too low or not unstaking all");
        require(validator.pendingUnstakeAmount == 0, "Already have a pending unstake request");

        validator.stakedAmount -= _amount;
        validator.pendingUnstakeAmount = _amount;
        validator.unstakeCooldownEndTime = block.timestamp + UNSTAKE_COOLDOWN_SECONDS;

        if (validator.stakedAmount < MIN_VALIDATOR_STAKE) {
            validator.isActive = false; // Deactivate if stake falls below minimum
            // Remove from activeValidators array (simplified)
            for (uint256 i = 0; i < activeValidators.length; i++) {
                if (activeValidators[i] == msg.sender) {
                    activeValidators[i] = activeValidators[activeValidators.length - 1];
                    activeValidators.pop();
                    break;
                }
            }
        }
        emit ValidatorUnstaked(msg.sender, _amount);
    }

    /// @notice Allows validators to withdraw their unstaked COG tokens after the cooldown period.
    function withdrawUnstakedAmount() external nonReentrant {
        Validator storage validator = validators[msg.sender];
        require(validator.pendingUnstakeAmount > 0, "No pending unstake amount");
        require(block.timestamp >= validator.unstakeCooldownEndTime, "Unstake cooldown not over yet");

        uint256 amountToWithdraw = validator.pendingUnstakeAmount;
        validator.pendingUnstakeAmount = 0;
        validator.unstakeCooldownEndTime = 0; // Reset

        require(COG_TOKEN.transfer(msg.sender, amountToWithdraw), "Withdrawal failed");
    }

    /// @notice Validator casts a vote on a submitted Knowledge Module.
    /// @param _kmId The ID of the Knowledge Module.
    /// @param _approval True for approval, false for rejection.
    /// @param _reasonHash IPFS hash of the reason for the vote (optional, but good practice).
    function voteOnKnowledgeModule(uint256 _kmId, bool _approval, string calldata _reasonHash) external onlyValidator {
        KnowledgeModule storage km = knowledgeModules[_kmId];
        require(km.contributor != address(0), "KM does not exist");
        require(km.status == KnowledgeModuleStatus.Pending, "KM is not in pending status");
        require(block.timestamp <= km.validationEndTime, "Voting period has ended");
        require(!km.voted[msg.sender], "Already voted on this KM");

        km.voted[msg.sender] = true;
        km.voteApproval[msg.sender] = _approval;
        if (_approval) {
            km.upvotes++;
        } else {
            km.downvotes++;
        }
        emit VoteCast(msg.sender, _kmId, true, _approval);

        _tryFinalizeKnowledgeModule(_kmId);
    }

    /// @notice Validator casts a vote on an Insight Proposal's AI result.
    /// @param _ipId The ID of the Insight Proposal.
    /// @param _approval True for approval, false for rejection.
    /// @param _reasonHash IPFS hash of the reason for the vote.
    function voteOnInsightProposal(uint256 _ipId, bool _approval, string calldata _reasonHash) external onlyValidator {
        InsightProposal storage ip = insightProposals[_ipId];
        require(ip.proposer != address(0), "IP does not exist");
        require(ip.status == InsightProposalStatus.AI_ResultSubmitted, "IP is not awaiting AI result verification");
        require(block.timestamp <= ip.verificationEndTime, "Verification period has ended");
        require(!ip.votedForAIResult[msg.sender], "Already voted on this AI result");

        ip.votedForAIResult[msg.sender] = true;
        ip.aiResultApproval[msg.sender] = _approval;
        if (_approval) {
            ip.aiResultUpvotes++;
        } else {
            ip.aiResultDownvotes++;
        }
        emit VoteCast(msg.sender, _ipId, false, _approval);

        _tryFinalizeInsightProposal(_ipId);
    }

    /// @dev Internal function to try and finalize KM status after a vote.
    function _tryFinalizeKnowledgeModule(uint256 _kmId) internal {
        KnowledgeModule storage km = knowledgeModules[_kmId];
        // Finalize if voting period is over OR if a quorum/significant number of votes has been reached.
        // For simplicity, let's use a dynamic quorum based on active validators.
        uint256 totalVotes = km.upvotes + km.downvotes;
        uint256 requiredQuorum = (activeValidators.length * 70) / 100; // Example: 70% of active validators

        if (block.timestamp > km.validationEndTime || (totalVotes >= requiredQuorum && totalVotes > 0)) {
            _finalizeKnowledgeModule(_kmId);
        }
    }

    /// @dev Internal function to finalize KM status.
    function _finalizeKnowledgeModule(uint256 _kmId) internal {
        KnowledgeModule storage km = knowledgeModules[_kmId];
        require(km.status == KnowledgeModuleStatus.Pending, "KM not in pending status for finalization");

        // Iterate through all validators who voted and update their reputation
        for (uint256 i = 0; i < activeValidators.length; i++) {
            address validatorAddress = activeValidators[i];
            if (km.voted[validatorAddress]) {
                if (km.upvotes > km.downvotes) { // KM is approved by majority
                    if (km.voteApproval[validatorAddress]) { // Validator voted correctly (Approve)
                        _updateReputation(validatorAddress, int256(REPUTATION_GAIN_PER_ACCURATE_VOTE));
                        validators[validatorAddress].accurateVotesCount++;
                    } else { // Validator voted incorrectly (Reject)
                        _updateReputation(validatorAddress, -int256(REPUTATION_LOSS_PER_INACCURATE_VOTE));
                        validators[validatorAddress].inaccurateVotesCount++;
                    }
                } else if (km.downvotes > km.upvotes) { // KM is rejected by majority
                    if (!km.voteApproval[validatorAddress]) { // Validator voted correctly (Reject)
                        _updateReputation(validatorAddress, int256(REPUTATION_GAIN_PER_ACCURATE_VOTE));
                        validators[validatorAddress].accurateVotesCount++;
                    } else { // Validator voted incorrectly (Approve)
                        _updateReputation(validatorAddress, -int256(REPUTATION_LOSS_PER_INACCURATE_VOTE));
                        validators[validatorAddress].inaccurateVotesCount++;
                    }
                }
                // If votes are tied, reputation change might be neutral or defined otherwise.
                // For this example, if tied, no reputation change based on this specific vote.
            }
        }

        if (km.upvotes > km.downvotes) {
            km.status = KnowledgeModuleStatus.Approved;
        } else {
            km.status = KnowledgeModuleStatus.Rejected;
        }
        emit KnowledgeModuleStatusChanged(_kmId, km.status);
    }

    /// @dev Internal function to try and finalize IP status after an AI result vote.
    function _tryFinalizeInsightProposal(uint256 _ipId) internal {
        InsightProposal storage ip = insightProposals[_ipId];
        uint256 totalVotes = ip.aiResultUpvotes + ip.aiResultDownvotes;
        uint256 requiredQuorum = (activeValidators.length * 70) / 100;

        if (block.timestamp > ip.verificationEndTime || (totalVotes >= requiredQuorum && totalVotes > 0)) {
            _finalizeInsightProposal(_ipId);
        }
    }

    /// @dev Internal function to finalize IP status.
    function _finalizeInsightProposal(uint256 _ipId) internal {
        InsightProposal storage ip = insightProposals[_ipId];
        require(ip.status == InsightProposalStatus.AI_ResultSubmitted, "IP not awaiting AI result verification");

        // Similar reputation logic for validators on AI results
        for (uint256 i = 0; i < activeValidators.length; i++) {
            address validatorAddress = activeValidators[i];
            if (ip.votedForAIResult[validatorAddress]) {
                if (ip.aiResultUpvotes > ip.aiResultDownvotes) { // AI Result is approved by majority
                    if (ip.aiResultApproval[validatorAddress]) { // Validator voted correctly (Approve)
                        _updateReputation(validatorAddress, int256(REPUTATION_GAIN_PER_ACCURATE_VOTE));
                        validators[validatorAddress].accurateVotesCount++;
                    } else { // Validator voted incorrectly (Reject)
                        _updateReputation(validatorAddress, -int256(REPUTATION_LOSS_PER_INACCURATE_VOTE));
                        validators[validatorAddress].inaccurateVotesCount++;
                    }
                } else if (ip.aiResultDownvotes > ip.aiResultUpvotes) { // AI Result is rejected by majority
                    if (!ip.aiResultApproval[validatorAddress]) { // Validator voted correctly (Reject)
                        _updateReputation(validatorAddress, int256(REPUTATION_GAIN_PER_ACCURATE_VOTE));
                        validators[validatorAddress].accurateVotesCount++;
                    } else { // Validator voted incorrectly (Approve)
                        _updateReputation(validatorAddress, -int256(REPUTATION_LOSS_PER_INACCURATE_VOTE));
                        validators[validatorAddress].inaccurateVotesCount++;
                    }
                }
            }
        }

        if (ip.aiResultUpvotes > ip.aiResultDownvotes) {
            ip.status = InsightProposalStatus.AI_ResultVerified;
        } else {
            ip.status = InsightProposalStatus.Rejected;
        }
        emit InsightProposalStatusChanged(_ipId, ip.status);
    }


    /// @notice Allows any user to challenge a validator's vote on a KM or AI result with evidence.
    /// @param _validatorAddress The address of the validator being challenged.
    /// @param _targetId The ID of the Knowledge Module or Insight Proposal.
    /// @param _isKM True if challenging a KM, false if challenging an IP's AI result.
    /// @param _proofHash IPFS hash of the proof supporting the challenge.
    function challengeValidatorVote(address _validatorAddress, uint256 _targetId, bool _isKM, string calldata _proofHash) external nonReentrant ensureHasReputation {
        require(getReputationScore(msg.sender) > 0, "Challenger must have reputation");
        require(validators[_validatorAddress].isActive, "Challenged validator is not active");

        if (_isKM) {
            KnowledgeModule storage km = knowledgeModules[_targetId];
            require(km.contributor != address(0), "KM does not exist");
            require(km.status == KnowledgeModuleStatus.Pending, "KM is not in a challengable state"); // Can only challenge during voting period
            require(block.timestamp <= km.validationEndTime, "KM validation period ended");
            require(km.voted[_validatorAddress], "Challenged validator has not voted on this KM");
            require(km.challenger == address(0), "KM already under challenge"); // Only one challenge at a time per KM

            km.challenger = msg.sender;
            km.challengeEndTime = block.timestamp + CHALLENGE_PERIOD_SECONDS;
            km.challengeProofHash = _proofHash;
            km.status = KnowledgeModuleStatus.Challenged;
            emit ChallengeInitiated(msg.sender, _validatorAddress, _targetId, true, _proofHash);
        } else {
            InsightProposal storage ip = insightProposals[_targetId];
            require(ip.proposer != address(0), "IP does not exist");
            require(ip.status == InsightProposalStatus.AI_ResultSubmitted, "IP AI result is not in a challengable state"); // Can only challenge during verification period
            require(block.timestamp <= ip.verificationEndTime, "AI verification period ended");
            require(ip.votedForAIResult[_validatorAddress], "Challenged validator has not voted on this AI result");
            require(ip.challenger == address(0), "IP already under challenge"); // Only one challenge at a time per IP

            ip.challenger = msg.sender;
            ip.challengeEndTime = block.timestamp + CHALLENGE_PERIOD_SECONDS;
            ip.challengeProofHash = _proofHash;
            // InsightProposal does not have a 'Challenged' status like KnowledgeModule.
            emit ChallengeInitiated(msg.sender, _validatorAddress, _targetId, false, _proofHash);
        }
    }

    /// @notice Called after a challenge period to apply reputation changes and potential slashes based on outcome.
    ///         This function should be called by any participant after the challenge period expires.
    /// @param _challengedValidator The address of the validator whose vote was challenged.
    /// @param _targetId The ID of the Knowledge Module or Insight Proposal.
    /// @param _isKM True if it's a KM challenge, false if an IP AI result challenge.
    function finalizeChallenge(address _challengedValidator, uint256 _targetId, bool _isKM) external nonReentrant {
        address challengerAddress = address(0);
        bool challengerWon = false;

        if (_isKM) {
            KnowledgeModule storage km = knowledgeModules[_targetId];
            require(km.contributor != address(0), "KM does not exist");
            require(km.challenger != address(0), "No active challenge for this KM");
            require(block.timestamp > km.challengeEndTime, "Challenge period not over yet");

            challengerAddress = km.challenger;

            // Simplified challenge outcome: Challenger wins if the challenged validator's vote
            // goes against the final majority consensus after the voting period ends.
            // In a real system, this would involve a decentralized court or more complex oracle for truth.
            
            // First, ensure the KM is finalized if its voting period is over
            if (block.timestamp > km.validationEndTime && km.status == KnowledgeModuleStatus.Challenged) {
                _finalizeKnowledgeModule(_targetId); // Finalize KM state first
            }
            
            bool kmApprovedByMajority = km.status == KnowledgeModuleStatus.Approved;
            bool kmRejectedByMajority = km.status == KnowledgeModuleStatus.Rejected;

            if (km.voted[_challengedValidator]) { // Ensure challenged validator actually voted
                if (kmApprovedByMajority && !km.voteApproval[_challengedValidator]) { // KM approved but validator voted NO
                    challengerWon = true; // Challenger argued validator was wrong to vote NO
                } else if (kmRejectedByMajority && km.voteApproval[_challengedValidator]) { // KM rejected but validator voted YES
                    challengerWon = true; // Challenger argued validator was wrong to vote YES
                }
            } else { // Challenged validator did not vote on this KM, challenge cannot be evaluated on vote accuracy.
                     // Could implement a specific rule for this, e.g., challenge fails or is void.
                challengerWon = false; 
            }

            km.challenger = address(0); // Reset challenge state
            km.challengeEndTime = 0;
            km.challengeProofHash = "";
            // The KM status should already be finalized by _finalizeKnowledgeModule if voting period is over.
            // If challenged during pending, it might return to pending if no clear consensus or tie.
            // For now, assume it transitions to Approved/Rejected if majority reached or time over.


        } else { // IP AI result challenge
            InsightProposal storage ip = insightProposals[_targetId];
            require(ip.proposer != address(0), "IP does not exist");
            require(ip.challenger != address(0), "No active challenge for this IP AI result");
            require(block.timestamp > ip.challengeEndTime, "Challenge period not over yet");

            challengerAddress = ip.challenger;

            // First, ensure the IP's AI result verification is finalized if its period is over
            if (block.timestamp > ip.verificationEndTime && ip.status == InsightProposalStatus.AI_ResultSubmitted) {
                _finalizeInsightProposal(_targetId); // Finalize IP state first
            }

            bool aiResultApprovedByMajority = ip.status == InsightProposalStatus.AI_ResultVerified;
            bool aiResultRejectedByMajority = ip.status == InsightProposalStatus.Rejected;

            if (ip.votedForAIResult[_challengedValidator]) {
                if (aiResultApprovedByMajority && !ip.aiResultApproval[_challengedValidator]) { // AI result approved but validator voted NO
                    challengerWon = true;
                } else if (aiResultRejectedByMajority && ip.aiResultApproval[_challengedValidator]) { // AI result rejected but validator voted YES
                    challengerWon = true;
                }
            } else {
                challengerWon = false;
            }

            ip.challenger = address(0); // Reset challenge state
            ip.challengeEndTime = 0;
            ip.challengeProofHash = "";
        }

        if (challengerWon) {
            _updateReputation(challengerAddress, int256(REPUTATION_GAIN_ON_CHALLENGE));
            _updateReputation(_challengedValidator, -int256(REPUTATION_LOSS_ON_CHALLENGE));
            slashStake(_challengedValidator, validators[_challengedValidator].stakedAmount / 20); // Slash 5% of stake
        } else {
            // Challenger loses reputation if the challenge fails or if it was invalid
            _updateReputation(challengerAddress, -int256(REPUTATION_LOSS_ON_CHALLENGE / 2)); // Half penalty for failed challenge
        }

        emit ChallengeFinalized(challengerAddress, _challengedValidator, _targetId, _isKM, challengerWon);
    }

    /// @notice Allows a highly reputed validator to upgrade to a Curator role.
    function becomeCurator() external ensureHasReputation {
        require(validators[msg.sender].isActive, "Only active validators can become curators");
        require(_sbtRepScores[msg.sender] >= MIN_REPUTATION_FOR_CURATOR, "Not enough reputation to become a curator");
        require(!isCurator[msg.sender], "Already a curator");
        isCurator[msg.sender] = true;
        emit CuratorPromoted(msg.sender);
    }

    /// @notice Curator assembles approved Insight Proposals into a saleable Insight Pack NFT.
    /// @param _ipIds Array of IDs of verified Insight Proposals.
    /// @param _title Title of the Insight Pack.
    /// @param _description Description of the Insight Pack.
    /// @param _coverURI URI for the pack's visual representation.
    /// @param _price Price in COG tokens.
    function curateInsightPack(
        uint256[] calldata _ipIds,
        string calldata _title,
        string calldata _description,
        string calldata _coverURI,
        uint256 _price
    ) external onlyCurator nonReentrant {
        require(_ipIds.length > 0, "Insight Pack must contain at least one Insight Proposal");
        for (uint256 i = 0; i < _ipIds.length; i++) {
            require(insightProposals[_ipIds[i]].status == InsightProposalStatus.AI_ResultVerified, "All IPs must be AI-verified");
        }

        uint256 packId = nextInsightPackId++;
        InsightPack storage pack = insightPacks[packId];
        pack.curator = msg.sender;
        pack.ipIds = _ipIds;
        pack.title = _title;
        pack.description = _description;
        pack.coverURI = _coverURI;
        pack.price = _price;
        pack.creationTime = block.timestamp;

        _mintInsightPack(msg.sender, packId); // Mint the NFT to the curator
        emit InsightPackCurated(packId, msg.sender, _price);
    }

    // --- III. AI Oracle & Off-chain Integration ---

    /// @notice An AI service provider registers to offer computation services.
    /// @param _providerAddress The address of the AI provider.
    /// @param _serviceURI URI pointing to the AI service details (e.g., API endpoint, documentation).
    function registerAIOffchainProvider(address _providerAddress, string calldata _serviceURI) external onlyOwner {
        require(!aiProviders[_providerAddress].isActive, "AI provider already registered");
        aiProviders[_providerAddress] = AIProvider({
            serviceURI: _serviceURI,
            isActive: true
        });
        emit AIOffchainProviderRegistered(_providerAddress, _serviceURI);
    }

    /// @notice Registered AI provider submits the computed result for an Insight Proposal.
    /// @param _ipId The ID of the Insight Proposal.
    /// @param _resultHash The hash of the AI's computed result.
    /// @param _computationFee The fee for the AI computation (should match the bounty).
    function submitAIOffchainResult(uint256 _ipId, string calldata _resultHash, uint256 _computationFee) external onlyAIProvider nonReentrant {
        InsightProposal storage ip = insightProposals[_ipId];
        require(ip.proposer != address(0), "IP does not exist");
        require(ip.status == InsightProposalStatus.Pending, "IP is not in Pending status");
        require(ip.rewardBounty == _computationFee, "Computation fee must match bounty");

        ip.aiProvider = msg.sender;
        ip.aiResultHash = _resultHash;
        ip.aiComputationFee = _computationFee;
        ip.status = InsightProposalStatus.AI_ResultSubmitted;
        ip.verificationEndTime = block.timestamp + VALIDATION_PERIOD_SECONDS; // Validators verify AI result
        emit AIOffchainResultSubmitted(_ipId, msg.sender, _resultHash, _computationFee);
    }

    /// @notice Validators vote on the correctness of a submitted AI result.
    /// @param _ipId The ID of the Insight Proposal.
    /// @param _isCorrect True if the AI result is deemed correct, false otherwise.
    /// @param _reasonHash IPFS hash for the reason of the vote.
    // NOTE: This function's logic is primarily handled by `voteOnInsightProposal`.
    // It's included here to directly match the summary, acting as a direct callable entry for AI result verification.
    function verifyAIOffchainResult(uint256 _ipId, bool _isCorrect, string calldata _reasonHash) external onlyValidator {
        voteOnInsightProposal(_ipId, _isCorrect, _reasonHash); // Direct call to the actual voting function
        emit AIOffchainResultVerified(_ipId, _isCorrect);
    }

    /// @notice Distributes bounty to the AI provider once their result is verified and accepted.
    /// @param _ipId The ID of the Insight Proposal.
    function rewardAIOffchainProvider(uint256 _ipId) external nonReentrant {
        InsightProposal storage ip = insightProposals[_ipId];
        require(ip.proposer != address(0), "IP does not exist");
        require(ip.status == InsightProposalStatus.AI_ResultVerified, "AI result not yet verified");
        require(ip.aiProvider != address(0), "No AI provider associated with this IP");
        require(ip.rewardBounty > 0, "No bounty set for this IP or already claimed");
        require(COG_TOKEN.transfer(ip.aiProvider, ip.rewardBounty), "Reward transfer failed");
        ip.rewardBounty = 0; // Prevent double claims
    }

    // --- IV. Reputation, Rewards & Economy ---

    /// @notice Retrieves the non-transferable reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address _user) public view returns (uint256) {
        return _sbtRepScores[_user];
    }

    /// @notice Periodically called by the owner to reward validators based on their accurate voting.
    function distributeValidationRewards() external onlyOwner nonReentrant {
        // This is a simplified example. In a real system, reward pool would be funded,
        // and rewards would be calculated dynamically based on staked amount, uptime, etc.
        // This example rewards based on 'accurateVotesCount' accumulated since last distribution.
        uint256 rewardPerAccurateVote = 10 * (10**18); // Example: 10 COG per accurate vote (can be parameter)

        for (uint256 i = 0; i < activeValidators.length; i++) {
            address validatorAddress = activeValidators[i];
            Validator storage validator = validators[validatorAddress];

            uint259 rewardAmount = validator.accurateVotesCount * rewardPerAccurateVote;

            if (rewardAmount > 0) {
                // Ensure contract has enough COG_TOKEN balance to distribute rewards
                require(COG_TOKEN.balanceOf(address(this)) >= rewardAmount, "Contract has insufficient COG for rewards");
                require(COG_TOKEN.transfer(validatorAddress, rewardAmount), "Reward transfer failed");
                emit RewardsDistributed(validatorAddress, rewardAmount);
                validator.accurateVotesCount = 0; // Reset for next period
            }
        }
    }

    /// @notice Internally called function to reduce a validator's stake due to penalties.
    /// @param _validatorAddress The address of the validator to slash.
    /// @param _amount The amount of COG tokens to slash.
    function slashStake(address _validatorAddress, uint256 _amount) internal {
        Validator storage validator = validators[_validatorAddress];
        require(validator.stakedAmount >= _amount, "Cannot slash more than staked amount");
        validator.stakedAmount -= _amount;
        // Slashed tokens could be burned, sent to treasury, or added to reward pool.
        // For simplicity, they remain in the contract's balance but are removed from validator's stake.
    }

    /// @notice Curator claims accumulated fees from sales of their curated Insight Pack.
    /// @param _insightPackId The ID of the Insight Pack.
    function claimCuratorFees(uint256 _insightPackId) external nonReentrant {
        InsightPack storage pack = insightPacks[_insightPackId];
        require(pack.curator == msg.sender, "Only the curator can claim fees");
        require(pack.totalSalesRevenue > 0, "No revenue to claim");

        uint256 feesToClaim = (pack.totalSalesRevenue * curatorFeePercentage) / 100;
        pack.totalSalesRevenue -= feesToClaim; // Deduct claimed fees from total revenue

        require(COG_TOKEN.transfer(msg.sender, feesToClaim), "Fee transfer failed");
        emit FeesClaimed(msg.sender, feesToClaim);
    }

    // --- V. Marketplace & Access ---

    /// @notice User buys an Insight Pack NFT, gaining access to its contents.
    /// @param _insightPackId The ID of the Insight Pack to purchase.
    function purchaseInsightPack(uint256 _insightPackId) external nonReentrant ensureHasReputation {
        InsightPack storage pack = insightPacks[_insightPackId];
        require(pack.curator != address(0), "Insight Pack does not exist");
        require(pack.price > 0, "Insight Pack is not for sale or free");
        require(_ownerOfInsightPack[_insightPackId] != address(0), "Insight Pack NFT must be minted first");

        require(COG_TOKEN.transferFrom(msg.sender, address(this), pack.price), "Token transfer failed for purchase");

        // Transfer ownership of the Insight Pack NFT
        _transferInsightPack(_ownerOfInsightPack[_insightPackId], msg.sender, _insightPackId);

        pack.totalSalesRevenue += pack.price; // Accumulate revenue for curator fees
        emit InsightPackPurchased(_insightPackId, msg.sender, pack.price);
    }

    /// @notice Retrieves details of a specific Insight Pack.
    /// @param _insightPackId The ID of the Insight Pack.
    /// @return pack details.
    function getInsightPackDetails(uint256 _insightPackId) public view returns (
        address curator,
        uint256[] memory ipIds,
        string memory title,
        string memory description,
        string memory coverURI,
        uint256 price,
        uint256 creationTime,
        uint256 totalSalesRevenue,
        address owner
    ) {
        InsightPack storage pack = insightPacks[_insightPackId];
        require(pack.curator != address(0), "Insight Pack does not exist");
        return (
            pack.curator,
            pack.ipIds,
            pack.title,
            pack.description,
            pack.coverURI,
            pack.price,
            pack.creationTime,
            pack.totalSalesRevenue,
            _ownerOfInsightPack[_insightPackId]
        );
    }

    /// @notice Curator adjusts the price of their Insight Pack.
    /// @param _insightPackId The ID of the Insight Pack.
    /// @param _newPrice The new price in COG tokens.
    function setInsightPackPrice(uint256 _insightPackId, uint256 _newPrice) external onlyCurator {
        InsightPack storage pack = insightPacks[_insightPackId];
        require(pack.curator == msg.sender, "Only the curator can set the price");
        pack.price = _newPrice;
    }

    /// @notice Checks if a knowledge module has been approved by validators.
    /// @param _kmId The ID of the Knowledge Module.
    /// @return True if approved, false otherwise.
    function isKnowledgeModuleApproved(uint256 _kmId) public view returns (bool) {
        return knowledgeModules[_kmId].status == KnowledgeModuleStatus.Approved;
    }

    /// @notice Checks if an insight proposal and its AI result have been verified.
    /// @param _ipId The ID of the Insight Proposal.
    /// @return True if verified, false otherwise.
    function isInsightProposalVerified(uint256 _ipId) public view returns (bool) {
        return insightProposals[_ipId].status == InsightProposalStatus.AI_ResultVerified;
    }

    /// @notice Returns an array of approved Knowledge Module IDs linked to a specific Insight Proposal.
    /// @param _ipId The ID of the Insight Proposal.
    /// @return An array of approved Knowledge Module IDs.
    function getApprovedSourceKMs(uint256 _ipId) public view returns (uint256[] memory) {
        InsightProposal storage ip = insightProposals[_ipId];
        require(ip.proposer != address(0), "IP does not exist");
        require(ip.status == InsightProposalStatus.AI_ResultVerified, "IP not yet verified");
        return ip.sourceKMs;
    }

    // --- Admin/Owner Functions ---
    function setCuratorFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 100, "Percentage cannot exceed 100");
        curatorFeePercentage = _newPercentage;
    }

    function setMinValidatorStake(uint256 _newStake) external onlyOwner {
        MIN_VALIDATOR_STAKE = _newStake;
    }

    function setMinReputationForCurator(uint256 _newReputation) external onlyOwner {
        MIN_REPUTATION_FOR_CURATOR = _newReputation;
    }
}
```