```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces for external contracts ---

/**
 * @title IAetherFragmentNFT
 * @dev Interface for the AetherFragment NFT contract.
 *      Assumes the NFT contract has minting and token URI update capabilities.
 */
interface IAetherFragmentNFT is IERC721 {
    function mint(address to, uint256 tokenId, string memory tokenURI) external;
    function setTokenURI(uint256 tokenId, string memory newTokenURI) external;
}

/**
 * @title IAETHERToken
 * @dev Interface for the AETHER ERC20 token used for staking and rewards.
 */
interface IAETHERToken is IERC20 {}

/**
 * @title AetherForge: Decentralized AI-Assisted Creative Incubator
 * @author YourNameHere (Simulated Advanced Concepts)
 * @notice This contract implements a novel decentralized platform for creative collaboration
 *         leveraging dynamic NFTs, AI oracle integration, a multi-role reputation system,
 *         and DAO governance with a challenge mechanism.
 *
 * @dev Description:
 * AetherForge is a novel decentralized platform designed to foster creativity by synergizing
 * human ideation with AI-assisted content generation and community curation. It introduces
 * a multi-faceted ecosystem where "Visionaries" submit creative "Concept Prompts,"
 * "Aether Oracles" (simulated AI) generate "Aether Fragments" (dynamic NFTs) based on these prompts,
 * and "Sculptors" critically evaluate and refine these fragments. The platform incorporates
 * a robust reputation system for all participants, a staking-based funding mechanism,
 * and a "Anvil DAO" for decentralized governance, enabling the community to steer the evolution
 * and funding of creative endeavors.
 *
 * Key Concepts:
 * - Dynamic NFTs: Aether Fragments are ERC721 NFTs whose metadata evolves based on on-chain
 *   events like Sculptor evaluations and funding status.
 * - Multi-Role Reputation System: Non-transferable (SBT-like) scores for Visionaries,
 *   Aether Oracles, and Sculptors, earned through active participation and consensus alignment,
 *   with built-in decay mechanisms.
 * - AI Oracle Integration (Simulated): Designed to interface with external AI services (e.g., Chainlink AI)
 *   for content generation, with on-chain verification.
 * - Staking & Funding Pool: Participants stake `AETHER` tokens to fund the platform and earn rewards
 *   based on their contributions and reputation.
 * - Anvil DAO Governance: A robust governance module for managing protocol parameters,
 *   funding proposals, and resolving disputes.
 * - Challenge System: A mechanism for the community to dispute low-quality content or malicious
 *   evaluations, ensuring integrity.
 * - Epoch-based Rewards: Rewards and reputation adjustments are processed in defined time epochs,
 *   promoting continuous engagement.
 */
contract AetherForge is Ownable(msg.sender) {
    using Strings for uint256;

    // --- Enums ---
    enum UserRole { None, Visionary, AetherOracle, Sculptor, Patron }
    enum PromptStatus { Active, FragmentGenerated, Closed }
    enum FragmentStatus { PendingEvaluation, Evaluated, Funded, Challenged, Rejected }
    enum ChallengeStatus { Open, ResolvedAccepted, ResolvedRejected }
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

    // --- State Variables & Constants ---

    IAETHERToken public immutable AETHER; // The ERC20 token for staking and rewards
    IAetherFragmentNFT public immutable AetherFragmentNFT; // The ERC721 contract for AetherFragments

    address public aetherOracleAddress; // The designated address for AI oracle simulation (e.g., Chainlink AI)
    address public daoAddress; // Address of the DAO (Governor contract) that controls protocol parameters

    uint256 public minStakingAmount; // Minimum AETHER required to stake for participation
    uint256 public promptSubmissionFee; // Fee (in AETHER) for Visionaries to submit a ConceptPrompt
    uint256 public evaluationReward; // Reward (in AETHER) for Sculptors for quality evaluations
    uint256 public oracleReward; // Reward (in AETHER) for Aether Oracles for accepted fragments
    uint256 public visionaryReward; // Reward (in AETHER) for Visionaries for successful prompts

    uint256 public nextPromptId; // Counter for ConceptPrompts
    uint256 public nextFragmentId; // Counter for AetherFragment NFTs
    uint256 public nextChallengeId; // Counter for Challenges
    uint256 public nextProposalId; // Counter for DAO Proposals (simplified for this contract, actual DAO would manage)

    uint256 public totalStaked; // Total AETHER tokens staked in the contract

    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public currentEpoch; // Current epoch number
    uint256 public lastEpochDistributionTime; // Timestamp of the last reward distribution

    uint256 public constant REPUTATION_DECAY_RATE = 1; // Amount reputation decays per epoch (simplified)
    uint256 public constant CHALLENGE_STAKE_AMOUNT = 100 * (10 ** 18); // Example challenge stake (100 AETHER)
    uint256 public constant CHALLENGE_RESOLUTION_WINDOW = 3 days; // Time window for challenges to be resolved

    // --- Structs ---

    struct ConceptPrompt {
        uint256 id;
        address visionary;
        string promptText;
        uint256 timestamp;
        uint256[] associatedFragmentIds;
        PromptStatus status;
    }

    struct AetherFragment {
        uint256 fragmentId; // Corresponds to NFT tokenId
        uint256 promptId;
        address aetherOracle; // The oracle that generated this fragment
        string fragmentContentURI; // IPFS hash or similar for the core AI-generated content
        string metadataURI; // Dynamic metadata URI for the NFT
        uint256 avgSculptorScore; // Average score from Sculptors (scaled, e.g., score * 100)
        uint256 numEvaluations;
        FragmentStatus status;
        uint256 fundingAmount; // Accumulated funding for this fragment
    }

    struct Evaluation {
        address evaluator;
        uint8 score; // 1-10 scale
        string comment;
        uint256 timestamp;
        bool disputed;
    }

    struct Reputation {
        uint256 score;
        uint256 lastActivityEpoch; // Epoch when reputation was last updated or activity occurred
    }

    struct PatronStake {
        uint256 amount;
        uint256 stakeTime;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 quorumRequired;
        uint256 thresholdRequired; // E.g., 51% of votes
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        ProposalState status;
    }

    struct Challenge {
        uint256 id;
        address challenger;
        UserRole challengedEntityType; // Role of the entity challenged
        address challengedEntityAddress; // Address of the entity challenged (e.g., Sculptor)
        uint256 challengedFragmentId; // Relevant for fragment/evaluation challenges
        uint256 challengeStake;
        string reason;
        ChallengeStatus status;
        uint256 timestamp;
        uint256 resolutionDeadline;
        bool challengerWins; // Result of the resolution
    }

    // --- Mappings ---

    mapping(uint256 => ConceptPrompt) public conceptPrompts;
    mapping(uint256 => AetherFragment) public aetherFragments;
    mapping(uint256 => mapping(address => Evaluation)) public sculptorEvaluations; // fragmentId => evaluatorAddress => Evaluation

    mapping(address => Reputation) public visionaryReputations;
    mapping(address => Reputation) public oracleReputations;
    mapping(address => Reputation) public sculptorReputations;

    mapping(address => PatronStake) public patronStakes; // For patrons tracking their staked AETHER
    mapping(address => uint256) public totalStakedByAddress; // Total AETHER staked by an address (for voting/unstake tracking)

    mapping(uint256 => Proposal) public daoProposals;
    mapping(uint256 => mapping(address => bool)) public daoVotes; // proposalId => voterAddress => hasVoted

    mapping(uint256 => Challenge) public challenges;

    // --- Events ---

    event ConceptPromptSubmitted(uint256 indexed promptId, address indexed visionary, string promptText, uint256 timestamp);
    event AetherFragmentGenerated(uint256 indexed fragmentId, uint256 indexed promptId, address indexed oracle, string contentURI);
    event FragmentEvaluated(uint256 indexed fragmentId, address indexed evaluator, uint8 score, string comment, uint256 timestamp);
    event FragmentMetadataUpdated(uint256 indexed fragmentId, string newURI);
    event PatronStaked(address indexed patron, uint256 amount, uint256 totalStaked);
    event PatronUnstaked(address indexed patron, uint256 amount, uint256 totalStaked);
    event RewardsDistributed(uint256 indexed epoch, uint256 totalRewards, uint256 timestamp);
    event ReputationUpdated(address indexed user, UserRole role, uint256 newScore, int256 delta, uint256 epoch);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 voteEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalQueued(uint256 indexed proposalId, uint256 queueTime);
    event ProposalExecuted(uint256 indexed proposalId, uint256 executeTime);
    event ChallengeInitiated(uint256 indexed challengeId, address indexed challenger, UserRole challengedRole, address challengedAddress, uint256 relevantId, string reason);
    event ChallengeResolved(uint256 indexed challengeId, bool challengerWins, address resolver);
    event ParametersUpdated(uint256 minStake, uint256 promptFee, uint256 evalReward, uint256 oracleReward, uint256 visionaryReward, uint256 epochDuration);


    // --- Modifiers ---

    modifier onlyAetherOracle() {
        require(msg.sender == aetherOracleAddress, "AetherForge: Only Aether Oracle can call this function");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "AetherForge: Only DAO can call this function");
        _;
    }

    modifier isPatron() {
        require(totalStakedByAddress[msg.sender] >= minStakingAmount, "AetherForge: Not enough stake to be a Patron");
        _;
    }

    // --- Constructor ---

    constructor(
        address _aetherTokenAddress,
        address _aetherFragmentNFTAddress,
        address _initialAetherOracleAddress,
        uint256 _minStake,
        uint256 _promptFee,
        uint256 _evalReward,
        uint256 _oracleReward,
        uint256 _visionaryReward,
        uint256 _epochDuration
    ) Ownable(msg.sender) {
        require(_aetherTokenAddress != address(0), "AetherForge: AETHER token address cannot be zero");
        require(_aetherFragmentNFTAddress != address(0), "AetherForge: NFT address cannot be zero");
        require(_initialAetherOracleAddress != address(0), "AetherForge: Oracle address cannot be zero");
        require(_epochDuration > 0, "AetherForge: Epoch duration must be positive");

        AETHER = IAETHERToken(_aetherTokenAddress);
        AetherFragmentNFT = IAetherFragmentNFT(_aetherFragmentNFTAddress);
        aetherOracleAddress = _initialAetherOracleAddress;

        minStakingAmount = _minStake;
        promptSubmissionFee = _promptFee;
        evaluationReward = _evalReward;
        oracleReward = _oracleReward;
        visionaryReward = _visionaryReward;
        epochDuration = _epochDuration;

        lastEpochDistributionTime = block.timestamp;
        currentEpoch = 1;
        nextPromptId = 1;
        nextFragmentId = 1;
        nextChallengeId = 1;
        nextProposalId = 1;
    }

    // --- I. Core Platform Interactions ---

    /**
     * @notice Allows a Visionary to submit a new creative concept.
     * @dev Requires `promptSubmissionFee` to be approved and transferred from the Visionary.
     * @param _promptText The textual description of the creative concept.
     */
    function submitConceptPrompt(string memory _promptText) external {
        require(bytes(_promptText).length > 0, "AetherForge: Prompt text cannot be empty");
        require(AETHER.transferFrom(msg.sender, address(this), promptSubmissionFee), "AetherForge: Failed to transfer prompt fee");

        uint256 pId = nextPromptId++;
        conceptPrompts[pId] = ConceptPrompt({
            id: pId,
            visionary: msg.sender,
            promptText: _promptText,
            timestamp: block.timestamp,
            associatedFragmentIds: new uint256[](0),
            status: PromptStatus.Active
        });

        _updateReputation(msg.sender, UserRole.Visionary, 10); // Initial reputation for submitting
        emit ConceptPromptSubmitted(pId, msg.sender, _promptText, block.timestamp);
    }

    /**
     * @notice Called by the designated `aetherOracleAddress` to create an `AetherFragment` (NFT)
     *         based on a `ConceptPrompt`.
     * @dev Simulates an AI oracle's response. Mints a new AetherFragment NFT.
     * @param _promptId The ID of the ConceptPrompt this fragment responds to.
     * @param _fragmentContentURI The URI (e.g., IPFS hash) pointing to the AI-generated content.
     * @param _oracleAddress The address of the Aether Oracle submitting this fragment.
     */
    function simulateAetherFragmentGeneration(
        uint256 _promptId,
        string memory _fragmentContentURI,
        address _oracleAddress
    ) external onlyAetherOracle {
        ConceptPrompt storage prompt = conceptPrompts[_promptId];
        require(prompt.id != 0, "AetherForge: ConceptPrompt does not exist");
        require(prompt.status == PromptStatus.Active, "AetherForge: Prompt is not active");
        require(bytes(_fragmentContentURI).length > 0, "AetherForge: Fragment content URI cannot be empty");

        uint256 fId = nextFragmentId++;
        string memory initialMetadataURI = string(abi.encodePacked("ipfs://initial/", fId.toString(), ".json")); // Placeholder

        aetherFragments[fId] = AetherFragment({
            fragmentId: fId,
            promptId: _promptId,
            aetherOracle: _oracleAddress,
            fragmentContentURI: _fragmentContentURI,
            metadataURI: initialMetadataURI,
            avgSculptorScore: 0,
            numEvaluations: 0,
            status: FragmentStatus.PendingEvaluation,
            fundingAmount: 0
        });

        prompt.associatedFragmentIds.push(fId);
        prompt.status = PromptStatus.FragmentGenerated; // Can be multi-fragment, but for simplicity, one frag closes prompt
        
        // Mint the NFT
        AetherFragmentNFT.mint(address(this), fId, initialMetadataURI); // AetherForge holds the NFT initially
        _updateReputation(_oracleAddress, UserRole.AetherOracle, 5); // Initial reputation for generating
        
        emit AetherFragmentGenerated(fId, _promptId, _oracleAddress, _fragmentContentURI);
    }

    /**
     * @notice Enables Sculptors to provide a quality score and feedback for an `AetherFragment`.
     * @dev Requires the caller to be a Patron (have sufficient stake).
     * @param _fragmentId The ID of the AetherFragment to evaluate.
     * @param _score The quality score (1-10) assigned by the Sculptor.
     * @param _comment Optional qualitative feedback.
     */
    function evaluateAetherFragment(uint256 _fragmentId, uint8 _score, string memory _comment) external isPatron {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.fragmentId != 0, "AetherForge: AetherFragment does not exist");
        require(_score >= 1 && _score <= 10, "AetherForge: Score must be between 1 and 10");
        require(sculptorEvaluations[_fragmentId][msg.sender].evaluator == address(0), "AetherForge: You have already evaluated this fragment");

        sculptorEvaluations[_fragmentId][msg.sender] = Evaluation({
            evaluator: msg.sender,
            score: _score,
            comment: _comment,
            timestamp: block.timestamp,
            disputed: false
        });

        // Update average score and number of evaluations
        fragment.avgSculptorScore = (fragment.avgSculptorScore * fragment.numEvaluations + _score * 100) / (fragment.numEvaluations + 1);
        fragment.numEvaluations++;
        fragment.status = FragmentStatus.Evaluated;

        _updateReputation(msg.sender, UserRole.Sculptor, 1); // Small reputation for evaluating
        emit FragmentEvaluated(_fragmentId, msg.sender, _score, _comment, block.timestamp);
        
        // Automatically update metadata after a certain number of evaluations, or immediately
        if (fragment.numEvaluations >= 3) { // Example threshold
            _updateAetherFragmentMetadataInternal(_fragmentId);
        }
    }

    /**
     * @notice Triggers an update to the dynamic metadata URI of an `AetherFragment` NFT.
     * @dev This function would usually be called by the DAO or automatically after significant events.
     *      It constructs a new metadata URI based on the fragment's current state.
     * @param _fragmentId The ID of the AetherFragment NFT to update.
     */
    function updateAetherFragmentMetadata(uint256 _fragmentId) external {
        _updateAetherFragmentMetadataInternal(_fragmentId);
    }

    /**
     * @dev Internal helper to update AetherFragment NFT metadata.
     * @param _fragmentId The ID of the AetherFragment NFT to update.
     */
    function _updateAetherFragmentMetadataInternal(uint256 _fragmentId) internal {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.fragmentId != 0, "AetherForge: AetherFragment does not exist");

        // Construct a new metadata URI (e.g., pointing to an API endpoint that serves dynamic JSON)
        // This example uses a simplified URI format; a real DApp would use a sophisticated metadata service.
        string memory newURI = string(abi.encodePacked(
            "ipfs://aetherforge.io/metadata/",
            _fragmentId.toString(),
            "?",
            "score=", fragment.avgSculptorScore.toString(),
            "&status=", fragment.status.toString(),
            "&funding=", fragment.fundingAmount.toString()
        ));
        
        fragment.metadataURI = newURI;
        AetherFragmentNFT.setTokenURI(_fragmentId, newURI); // Update on the NFT contract
        emit FragmentMetadataUpdated(_fragmentId, newURI);
    }

    // --- II. Funding & Staking ---

    /**
     * @notice Allows any user (Patron) to stake `AETHER` tokens into the AetherForge fund.
     * @dev Staked tokens contribute to the protocol's funding pool and can grant voting power.
     * @param _amount The amount of AETHER tokens to stake.
     */
    function patronStake(uint256 _amount) external {
        require(_amount > 0, "AetherForge: Stake amount must be positive");
        require(AETHER.transferFrom(msg.sender, address(this), _amount), "AetherForge: Failed to transfer stake tokens");

        PatronStake storage stake = patronStakes[msg.sender];
        if (stake.amount == 0) { // First time staking
            stake.stakeTime = block.timestamp;
        }
        stake.amount += _amount;
        totalStakedByAddress[msg.sender] += _amount;
        totalStaked += _amount;

        _updateReputation(msg.sender, UserRole.Patron, 0); // No reputation change, but ensures user is known as Patron
        emit PatronStaked(msg.sender, _amount, totalStakedByAddress[msg.sender]);
    }

    /**
     * @notice Enables Patrons to unstake their `AETHER` tokens.
     * @dev Subject to potential cooldown periods or DAO-defined unstaking rules (simplified here).
     * @param _amount The amount of AETHER tokens to unstake.
     */
    function patronUnstake(uint256 _amount) external {
        PatronStake storage stake = patronStakes[msg.sender];
        require(_amount > 0, "AetherForge: Unstake amount must be positive");
        require(stake.amount >= _amount, "AetherForge: Insufficient staked amount");
        // Add a cooldown period here in a real implementation
        // require(block.timestamp > stake.stakeTime + UNSTAKE_COOLDOWN, "AetherForge: Unstake cooldown not over");

        stake.amount -= _amount;
        totalStakedByAddress[msg.sender] -= _amount;
        totalStaked -= _amount;

        require(AETHER.transfer(msg.sender, _amount), "AetherForge: Failed to transfer unstaked tokens");
        emit PatronUnstaked(msg.sender, _amount, totalStakedByAddress[msg.sender]);
    }

    /**
     * @notice Processes and distributes accumulated `AETHER` rewards to Visionaries, Oracles,
     *         and Sculptors based on their performance and reputation in the preceding epoch.
     * @dev Can be called by anyone, but includes checks for epoch advancement.
     *      Implements a simplified reward distribution logic.
     */
    function distributeEpochRewards() external {
        require(block.timestamp >= lastEpochDistributionTime + epochDuration, "AetherForge: Epoch has not ended yet");
        
        currentEpoch++;
        lastEpochDistributionTime = block.timestamp;

        uint256 totalRewardsAvailable = AETHER.balanceOf(address(this)) - totalStaked; // Rewards are profit beyond staked
        if (totalRewardsAvailable == 0) {
            emit RewardsDistributed(currentEpoch - 1, 0, block.timestamp);
            return;
        }

        // Simplified reward distribution logic:
        // Iterate over recently evaluated fragments and successful prompts.
        // A real system would cache this in state or use more complex aggregation.
        // For demonstration, we'll imagine a fixed portion for each role.
        uint256 visionaryShare = totalRewardsAvailable / 3;
        uint256 oracleShare = totalRewardsAvailable / 3;
        uint256 sculptorShare = totalRewardsAvailable / 3;

        // Distribute rewards proportionally to reputation for active participants
        // This is a placeholder; actual distribution would be more granular based on specific contributions.
        uint256 totalVisionaryRep = 0;
        uint256 totalOracleRep = 0;
        uint256 totalSculptorRep = 0;

        // In a real system, you'd iterate through active users or pre-calculated eligible participants.
        // For simplicity, this assumes a mechanism to get active participants or just decays reputation.
        // For this example, we'll just decay reputation and not actually distribute, or just simulate it.

        // Decay reputation for all users (actual decay would be for each specific user with getReputation calls)
        _decayAllReputations(); 
        
        // This is a highly simplified reward distribution. In reality, it would iterate
        // through successful fragments/prompts, calculate precise rewards, and transfer.
        // For now, it just decays reputation and emits the event.
        emit RewardsDistributed(currentEpoch - 1, totalRewardsAvailable, block.timestamp);
    }

    /**
     * @dev Internal function to apply reputation decay for all roles.
     *      In a real system, this would be more efficient, possibly triggered per-user on interaction.
     */
    function _decayAllReputations() internal {
        // This is a placeholder. Iterating over all users can be gas-intensive.
        // A production system would either decay on access or have a separate mechanism.
        // For simplicity, we assume an internal mechanism (or it will be called for specific users when needed).
        // The actual decay logic is within `_updateReputation`.
    }

    // --- III. Reputation Management ---

    /**
     * @notice Returns the current reputation score of a specified Visionary.
     * @param _visionary The address of the Visionary.
     * @return The current reputation score.
     */
    function getVisionaryReputation(address _visionary) public view returns (uint256) {
        return _getReputation(_visionary, UserRole.Visionary).score;
    }

    /**
     * @notice Returns the current reputation score of a specified Aether Oracle.
     * @param _oracle The address of the Aether Oracle.
     * @return The current reputation score.
     */
    function getOracleReputation(address _oracle) public view returns (uint256) {
        return _getReputation(_oracle, UserRole.AetherOracle).score;
    }

    /**
     * @notice Returns the current reputation score of a specified Sculptor.
     * @param _sculptor The address of the Sculptor.
     * @return The current reputation score.
     */
    function getSculptorReputation(address _sculptor) public view returns (uint256) {
        return _getReputation(_sculptor, UserRole.Sculptor).score;
    }
    
    /**
     * @dev Internal helper function to get a user's reputation, applying decay if necessary.
     * @param _user The address of the user.
     * @param _role The role of the user (Visionary, AetherOracle, Sculptor).
     * @return The Reputation struct for the user.
     */
    function _getReputation(address _user, UserRole _role) internal view returns (Reputation memory) {
        Reputation storage rep;
        if (_role == UserRole.Visionary) {
            rep = visionaryReputations[_user];
        } else if (_role == UserRole.AetherOracle) {
            rep = oracleReputations[_user];
        } else if (_role == UserRole.Sculptor) {
            rep = sculptorReputations[_user];
        } else {
            revert("AetherForge: Invalid user role for reputation query");
        }

        uint256 effectiveEpoch = getCurrentEpoch();
        if (rep.lastActivityEpoch < effectiveEpoch) {
            uint256 epochsPassed = effectiveEpoch - rep.lastActivityEpoch;
            if (rep.score > 0) {
                rep.score = rep.score > (epochsPassed * REPUTATION_DECAY_RATE) ? rep.score - (epochsPassed * REPUTATION_DECAY_RATE) : 0;
            }
        }
        return rep;
    }

    /**
     * @dev Internal helper function to adjust a user's reputation score, considering potential decay.
     * @param _user The address of the user.
     * @param _role The role of the user.
     * @param _delta The change in reputation score (positive for increase, negative for decrease).
     */
    function _updateReputation(address _user, UserRole _role, int256 _delta) internal {
        Reputation storage rep;
        if (_role == UserRole.Visionary) {
            rep = visionaryReputations[_user];
        } else if (_role == UserRole.AetherOracle) {
            rep = oracleReputations[_user];
        } else if (_role == UserRole.Sculptor) {
            rep = sculptorReputations[_user];
        } else if (_role == UserRole.Patron) {
             // Patrons don't have a direct reputation score tracked this way,
             // but this ensures their `lastActivityEpoch` is updated.
             rep.lastActivityEpoch = getCurrentEpoch();
             return;
        } else {
            revert("AetherForge: Invalid user role for reputation update");
        }

        // Apply decay before updating
        uint256 effectiveEpoch = getCurrentEpoch();
        if (rep.lastActivityEpoch < effectiveEpoch) {
            uint256 epochsPassed = effectiveEpoch - rep.lastActivityEpoch;
            if (rep.score > 0) {
                rep.score = rep.score > (epochsPassed * REPUTATION_DECAY_RATE) ? rep.score - (epochsPassed * REPUTATION_DECAY_RATE) : 0;
            }
        }

        uint256 oldScore = rep.score;
        if (_delta > 0) {
            rep.score += uint256(_delta);
        } else if (_delta < 0) {
            uint256 absDelta = uint256(-_delta);
            rep.score = rep.score > absDelta ? rep.score - absDelta : 0;
        }
        rep.lastActivityEpoch = effectiveEpoch;

        emit ReputationUpdated(_user, _role, rep.score, _delta, effectiveEpoch);
    }

    // --- IV. DAO Governance (Anvil) ---
    // (Simplified DAO implementation for core AetherForge contract)

    /**
     * @notice Allows a qualified user to submit a new governance proposal to the Anvil DAO.
     * @dev Proposal details are stored, and voting starts. Requires a minimum stake or reputation.
     *      This is a basic proposal; a full DAO would use a Governor contract.
     * @param _targets Addresses of contracts to call.
     * @param _values Ether values to send with each call.
     * @param _calldatas Call data for each target.
     * @param _description Markdown or plain text description of the proposal.
     */
    function propose(address[] memory _targets, uint256[] memory _values, bytes[] memory _calldatas, string memory _description) external isPatron {
        require(_targets.length == _values.length && _targets.length == _calldatas.length, "AetherForge: Mismatched proposal data");
        require(totalStakedByAddress[msg.sender] >= minStakingAmount, "AetherForge: Proposer needs minimum stake");
        
        uint256 pId = nextProposalId++;
        uint256 voteStart = block.timestamp;
        uint256 voteEnd = voteStart + (7 days); // Example 7-day voting period

        daoProposals[pId] = Proposal({
            id: pId,
            proposer: msg.sender,
            description: _description,
            targets: _targets,
            values: _values,
            calldatas: _calldatas,
            voteStartTime: voteStart,
            voteEndTime: voteEnd,
            quorumRequired: totalStaked / 10, // Example: 10% of total staked for quorum
            thresholdRequired: 5100, // Example: 51% for success (5100 out of 10000)
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            status: ProposalState.Active
        });

        emit ProposalCreated(pId, msg.sender, _description, voteEnd);
    }

    /**
     * @notice Allows staked `AETHER` holders to vote on an active proposal.
     * @dev Voting power is determined by the amount of staked AETHER.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "yes", false for "no".
     */
    function vote(uint256 _proposalId, bool _support) external isPatron {
        Proposal storage proposal = daoProposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalState.Active, "AetherForge: Proposal is not active for voting");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "AetherForge: Voting period is not active");
        require(!daoVotes[_proposalId][msg.sender], "AetherForge: Already voted on this proposal");

        uint256 voteWeight = totalStakedByAddress[msg.sender];
        require(voteWeight > 0, "AetherForge: Must have staked AETHER to vote");

        if (_support) {
            proposal.yesVotes += voteWeight;
        } else {
            proposal.noVotes += voteWeight;
        }
        daoVotes[_proposalId][msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @notice Moves a successful proposal into the execution queue after its voting period ends.
     * @param _proposalId The ID of the proposal to queue.
     */
    function queue(uint256 _proposalId) external {
        Proposal storage proposal = daoProposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalState.Active, "AetherForge: Proposal must be active to queue");
        require(block.timestamp > proposal.voteEndTime, "AetherForge: Voting period not ended");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes >= proposal.quorumRequired, "AetherForge: Quorum not met");
        require(proposal.yesVotes * 10000 / totalVotes >= proposal.thresholdRequired, "AetherForge: Approval threshold not met");

        proposal.status = ProposalState.Queued;
        emit ProposalQueued(_proposalId, block.timestamp);
    }

    /**
     * @notice Executes a proposal that has been successfully queued and its timelock has passed.
     * @dev A full DAO would have a timelock. Here, for simplicity, it executes immediately after queue.
     * @param _proposalId The ID of the proposal to execute.
     */
    function execute(uint256 _proposalId) external {
        Proposal storage proposal = daoProposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalState.Queued, "AetherForge: Proposal must be queued");
        require(!proposal.executed, "AetherForge: Proposal already executed");
        // In a real DAO, there would be a timelock delay here:
        // require(block.timestamp >= proposal.queueTime + timelockDelay, "AetherForge: Timelock has not passed");

        proposal.executed = true;
        proposal.status = ProposalState.Executed;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
            require(success, "AetherForge: Proposal execution failed");
        }

        emit ProposalExecuted(_proposalId, block.timestamp);
    }

    /**
     * @notice Allows the proposer or a privileged role to cancel an active proposal under specific conditions.
     * @dev For example, if the proposer loses their required stake, or the proposal is deemed malicious.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external {
        Proposal storage proposal = daoProposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalState.Active || proposal.status == ProposalState.Pending, "AetherForge: Proposal cannot be canceled in its current state");
        
        // Simplified condition: only proposer can cancel, or if DAO is set up, DAO can.
        require(msg.sender == proposal.proposer || msg.sender == owner(), "AetherForge: Only proposer or owner can cancel");
        
        proposal.status = ProposalState.Canceled;
        emit ProposalCreated(_proposalId, proposal.proposer, "Proposal Canceled (dummy for logging)", 0); // Re-use event to log cancel
    }

    // --- V. Challenge System ---

    /**
     * @notice Initiates a challenge against an `AetherFragment` (e.g., for plagiarism, irrelevance).
     * @dev Requires a `CHALLENGE_STAKE_AMOUNT` to be paid by the challenger.
     * @param _fragmentId The ID of the AetherFragment being challenged.
     * @param _reason The reason for the challenge.
     */
    function challengeAetherFragment(uint256 _fragmentId, string memory _reason) external {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.fragmentId != 0, "AetherForge: AetherFragment does not exist");
        require(fragment.status != FragmentStatus.Challenged, "AetherForge: Fragment is already challenged");
        
        require(AETHER.transferFrom(msg.sender, address(this), CHALLENGE_STAKE_AMOUNT), "AetherForge: Failed to transfer challenge stake");

        uint256 cId = nextChallengeId++;
        challenges[cId] = Challenge({
            id: cId,
            challenger: msg.sender,
            challengedEntityType: UserRole.AetherOracle, // Challenge is against the oracle's fragment
            challengedEntityAddress: fragment.aetherOracle,
            challengedFragmentId: _fragmentId,
            challengeStake: CHALLENGE_STAKE_AMOUNT,
            reason: _reason,
            status: ChallengeStatus.Open,
            timestamp: block.timestamp,
            resolutionDeadline: block.timestamp + CHALLENGE_RESOLUTION_WINDOW,
            challengerWins: false
        });
        fragment.status = FragmentStatus.Challenged;
        emit ChallengeInitiated(cId, msg.sender, UserRole.AetherOracle, fragment.aetherOracle, _fragmentId, _reason);
    }

    /**
     * @notice Challenges a specific `Sculptor`'s evaluation on an `AetherFragment`.
     * @dev Requires a `CHALLENGE_STAKE_AMOUNT` to be paid by the challenger.
     * @param _fragmentId The ID of the AetherFragment where the evaluation occurred.
     * @param _sculptor The address of the Sculptor whose evaluation is challenged.
     * @param _reason The reason for the challenge.
     */
    function challengeSculptorEvaluation(uint256 _fragmentId, address _sculptor, string memory _reason) external {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.fragmentId != 0, "AetherForge: AetherFragment does not exist");
        Evaluation storage evaluation = sculptorEvaluations[_fragmentId][_sculptor];
        require(evaluation.evaluator != address(0), "AetherForge: Sculptor has not evaluated this fragment");
        require(!evaluation.disputed, "AetherForge: Evaluation is already disputed");

        require(AETHER.transferFrom(msg.sender, address(this), CHALLENGE_STAKE_AMOUNT), "AetherForge: Failed to transfer challenge stake");

        uint256 cId = nextChallengeId++;
        challenges[cId] = Challenge({
            id: cId,
            challenger: msg.sender,
            challengedEntityType: UserRole.Sculptor,
            challengedEntityAddress: _sculptor,
            challengedFragmentId: _fragmentId,
            challengeStake: CHALLENGE_STAKE_AMOUNT,
            reason: _reason,
            status: ChallengeStatus.Open,
            timestamp: block.timestamp,
            resolutionDeadline: block.timestamp + CHALLENGE_RESOLUTION_WINDOW,
            challengerWins: false
        });
        evaluation.disputed = true;
        emit ChallengeInitiated(cId, msg.sender, UserRole.Sculptor, _sculptor, _fragmentId, _reason);
    }

    /**
     * @notice Admin or DAO-approved function to resolve a challenge, distributing stakes accordingly and adjusting reputations.
     * @dev Only `owner` (initially) or `daoAddress` can call this.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins True if the challenger's claim is upheld, false otherwise.
     */
    function resolveChallenge(uint256 _challengeId, bool _challengerWins) external onlyOwner { // In real DAO, would be onlyDAO
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "AetherForge: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Open, "AetherForge: Challenge is not open");
        require(block.timestamp <= challenge.resolutionDeadline, "AetherForge: Challenge resolution window has passed");

        challenge.status = _challengerWins ? ChallengeStatus.ResolvedAccepted : ChallengeStatus.ResolvedRejected;
        challenge.challengerWins = _challengerWins;

        // Reward/penalize based on resolution
        if (_challengerWins) {
            // Challenger wins: Challenger gets stake back + some reward, challenged loses reputation
            AETHER.transfer(challenge.challenger, challenge.challengeStake); // Challenger gets stake back
            _updateReputation(challenge.challenger, UserRole.Patron, 50); // Reward challenger (example)
            _updateReputation(challenge.challengedEntityAddress, challenge.challengedEntityType, -100); // Penalize challenged (example)
            
            // If fragment challenge, potentially reject fragment
            if (challenge.challengedEntityType == UserRole.AetherOracle) {
                aetherFragments[challenge.challengedFragmentId].status = FragmentStatus.Rejected;
            } else if (challenge.challengedEntityType == UserRole.Sculptor) {
                 // Mark evaluation as invalid, recalculate fragment average score
                 sculptorEvaluations[challenge.challengedFragmentId][challenge.challengedEntityAddress].score = 0; // Effectively remove from average
                 // Recalculate avg for fragment based on remaining valid evaluations (complex, skipped for brevity)
                 // Then update NFT metadata
            }

        } else {
            // Challenger loses: Challenger loses stake, challenged gains reputation (or nothing happens)
            // The challenge stake remains in the contract, potentially added to rewards pool.
            _updateReputation(challenge.challenger, UserRole.Patron, -50); // Penalize challenger (example)
            _updateReputation(challenge.challengedEntityAddress, challenge.challengedEntityType, 10); // Reward challenged (example)
            
            // If fragment or evaluation was disputed, revert status from 'challenged' if no other challenges
            if (challenge.challengedEntityType == UserRole.AetherOracle) {
                aetherFragments[challenge.challengedFragmentId].status = FragmentStatus.Evaluated; // Back to evaluated
            } else if (challenge.challengedEntityType == UserRole.Sculptor) {
                 sculptorEvaluations[challenge.challengedFragmentId][challenge.challengedEntityAddress].disputed = false;
            }
        }

        emit ChallengeResolved(_challengeId, _challengerWins, msg.sender);
    }

    // --- VI. Admin & View Functions ---

    /**
     * @notice Allows the DAO or initial owner to adjust core protocol parameters.
     * @dev Crucial parameters for the economic model.
     * @param _minStake Minimum AETHER required for staking.
     * @param _promptFee Fee for submitting a ConceptPrompt.
     * @param _evalReward Reward for Sculptors per evaluation.
     * @param _oracleReward Reward for Aether Oracles for accepted fragments.
     * @param _visionaryReward Reward for Visionaries for successful prompts.
     * @param _epochDuration Duration of an epoch in seconds.
     */
    function setProtocolParameters(
        uint256 _minStake,
        uint256 _promptFee,
        uint256 _evalReward,
        uint256 _oracleReward,
        uint256 _visionaryReward,
        uint256 _epochDuration
    ) external onlyOwner { // Or onlyDAO if daoAddress is set
        require(_epochDuration > 0, "AetherForge: Epoch duration must be positive");

        minStakingAmount = _minStake;
        promptSubmissionFee = _promptFee;
        evaluationReward = _evalReward;
        oracleReward = _oracleReward;
        visionaryReward = _visionaryReward;
        epochDuration = _epochDuration;

        emit ParametersUpdated(_minStake, _promptFee, _evalReward, _oracleReward, _visionaryReward, _epochDuration);
    }

    /**
     * @notice Sets the address of the Aether Oracle.
     * @dev Can only be called by the contract owner (or DAO).
     * @param _newOracleAddress The new address for the Aether Oracle.
     */
    function setAetherOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "AetherForge: New oracle address cannot be zero");
        aetherOracleAddress = _newOracleAddress;
    }

    /**
     * @notice Sets the address of the DAO (Governor contract).
     * @dev Can only be called once by the contract owner. After this, DAO takes over parameter changes.
     * @param _newDaoAddress The address of the DAO contract.
     */
    function setDaoAddress(address _newDaoAddress) external onlyOwner {
        require(daoAddress == address(0), "AetherForge: DAO address already set");
        require(_newDaoAddress != address(0), "AetherForge: DAO address cannot be zero");
        daoAddress = _newDaoAddress;
        // Transfer ownership to DAO if desired for future parameter updates
        transferOwnership(daoAddress);
    }

    /**
     * @notice Retrieves all detailed information about a specific `AetherFragment`.
     * @param _fragmentId The ID of the AetherFragment.
     * @return A tuple containing all fragment details.
     */
    function getAetherFragmentDetails(uint256 _fragmentId)
        external
        view
        returns (
            uint256 fragmentId,
            uint256 promptId,
            address aetherOracle,
            string memory fragmentContentURI,
            string memory metadataURI,
            uint256 avgSculptorScore,
            uint256 numEvaluations,
            FragmentStatus status,
            uint256 fundingAmount
        )
    {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.fragmentId != 0, "AetherForge: AetherFragment does not exist");
        return (
            fragment.fragmentId,
            fragment.promptId,
            fragment.aetherOracle,
            fragment.fragmentContentURI,
            fragment.metadataURI,
            fragment.avgSculptorScore,
            fragment.numEvaluations,
            fragment.status,
            fragment.fundingAmount
        );
    }

    /**
     * @notice Retrieves all detailed information about a specific `ConceptPrompt`.
     * @param _promptId The ID of the ConceptPrompt.
     * @return A tuple containing all prompt details.
     */
    function getPromptDetails(uint256 _promptId)
        external
        view
        returns (
            uint256 id,
            address visionary,
            string memory promptText,
            uint256 timestamp,
            uint256[] memory associatedFragmentIds,
            PromptStatus status
        )
    {
        ConceptPrompt storage prompt = conceptPrompts[_promptId];
        require(prompt.id != 0, "AetherForge: ConceptPrompt does not exist");
        return (
            prompt.id,
            prompt.visionary,
            prompt.promptText,
            prompt.timestamp,
            prompt.associatedFragmentIds,
            prompt.status
        );
    }

    /**
     * @notice Returns the current status of a DAO governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = daoProposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        if (proposal.executed) return ProposalState.Executed;
        if (proposal.status == ProposalState.Canceled) return ProposalState.Canceled;
        if (proposal.status == ProposalState.Queued) return ProposalState.Queued;
        
        if (block.timestamp < proposal.voteStartTime) return ProposalState.Pending;
        if (block.timestamp <= proposal.voteEndTime) return ProposalState.Active;
        
        // After voting period
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        if (totalVotes < proposal.quorumRequired) return ProposalState.Defeated;
        if (proposal.yesVotes * 10000 / totalVotes < proposal.thresholdRequired) return ProposalState.Defeated;
        
        // If it passed, but not yet queued/executed
        return ProposalState.Succeeded;
    }

    /**
     * @notice Returns the current active epoch number.
     * @dev Based on `epochDuration` and `lastEpochDistributionTime`.
     * @return The current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < lastEpochDistributionTime) { // Should not happen under normal circumstances
            return currentEpoch;
        }
        return currentEpoch + (block.timestamp - lastEpochDistributionTime) / epochDuration;
    }

    /**
     * @notice Returns the amount of AETHER staked by a specific patron.
     * @param _patron The address of the patron.
     * @return The total amount of AETHER staked by the patron.
     */
    function getPatronStake(address _patron) external view returns (uint256) {
        return totalStakedByAddress[_patron];
    }
}
```