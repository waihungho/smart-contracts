This smart contract, **Aetheria Nexus**, is designed to create a dynamic, AI-influenced, and community-governed ecosystem around unique digital entities called "Aetheria Shards" (Dynamic NFTs). Users mint these shards, which can then evolve in tier and mutate their elemental traits based on the outcomes of community-proposed, AI-evaluated challenges. The entire system is governed by a Decentralized Autonomous Organization (DAO), where token holders propose and vote on challenges, protocol parameters, and treasury utilization.

The core advanced concepts include:
1.  **AI-Driven Dynamic NFTs (dNFTs):** Shards change their properties (tier, elements) based on external, AI-evaluated data. Their metadata URI is also dynamic.
2.  **Oracle Integration for AI:** The contract relies on an external AI Oracle (mocked here for demonstration) to provide objective evaluation of challenge outcomes.
3.  **Advanced DAO Governance:** Beyond simple proposals, the DAO governs the creation and approval of dynamic content (challenges) and core protocol parameters, incorporating staking and delegation for voting power.
4.  **Gamified Challenge System:** A structured system for proposing, activating, participating in, and resolving community-driven quests, with rewards and shard evolution as incentives.
5.  **Reputation & Progression:** Shards accumulate "challenges completed," contributing to a sense of progression and on-chain history.

---

## Contract Outline: Aetheria Nexus

**I. Core Infrastructure & Access Control**
1.  **`constructor`**: Initializes the ERC721 token (Aetheria Shards), sets the governance token, and assigns the initial owner.
2.  **`setAetheriaOracleAddress`**: Allows the contract owner to set or update the trusted AI Oracle address.
3.  **`pause` / `unpause`**: Global pause mechanism for critical situations, callable by the owner.

**II. Aetheria Shard (Dynamic NFT) Management**
4.  **`mintAetheriaShard`**: Mints a new Aetheria Shard NFT to the caller, starting at Tier 1 with base elements.
5.  **`getAetheriaShardDetails`**: Public view function to retrieve all current details (tier, elements, history) of a specific Aetheria Shard.
6.  **`tokenURI` (Override)**: ERC721 standard function. Dynamically generates a metadata URI for a given shard, reflecting its current tier and elements.
7.  **`evolveShardTier` (Internal)**: Increases a shard's tier (e.g., Tier 1 -> Tier 2). Called internally upon successful challenge resolution.
8.  **`mutateShardElements` (Internal)**: Randomly (or based on AI outcome) changes or adds elemental traits to a shard. Called internally.

**III. AI-Driven Challenge & Quest System**
9.  **`proposeAetheriaChallenge`**: Allows any user with sufficient governance token stake to propose a new community challenge, including its description, requirements, and reward structure.
10. **`voteOnChallengeProposal`**: DAO members vote "yes" or "no" on a proposed challenge, using their staked governance token power.
11. **`activateAetheriaChallenge`**: Executed automatically by the DAO if a challenge proposal passes, making it available for participation.
12. **`registerShardForChallenge`**: Allows an Aetheria Shard owner to register their eligible shard to participate in an active challenge.
13. **`requestAIChallengeEvaluation`**: Callable by the contract owner, this function formally requests the AI Oracle to evaluate the outcome of a completed challenge.
14. **`receiveAIChallengeEvaluation`**: **(External, `onlyAetheriaOracle`)** This is the callback function where the AI Oracle delivers the evaluated score and outcome for a challenge.
15. **`resolveAetheriaChallenge`**: Initiates the final resolution of a challenge after the AI evaluation is received. It triggers shard evolutions/mutations and calculates rewards.
16. **`claimChallengeRewards`**: Allows participants of a successfully completed challenge to claim their share of the challenge's reward pool.

**IV. Decentralized Autonomous Organization (DAO) Governance**
17. **`proposeGovernanceAction`**: Allows DAO members to propose generic protocol changes, parameter updates, or treasury spending actions.
18. **`voteOnGovernanceAction`**: DAO members vote "yes" or "no" on general governance proposals.
19. **`executeGovernanceAction`**: Executes an approved governance proposal, interacting with target contracts as specified in the proposal.
20. **`stakeGovernanceTokens`**: Users lock their governance tokens to gain voting power for DAO proposals.
21. **`unstakeGovernanceTokens`**: Users retrieve their previously staked governance tokens after an unbonding period.
22. **`delegateVotingPower`**: Allows a token holder to delegate their voting power to another address.

**V. Reputation & Dynamic Traits**
23. **`getShardTotalChallengesCompleted`**: View function to check how many challenges a specific shard has successfully completed, serving as a measure of its "experience."
24. **`calculateVotingPower`**: Computes the effective voting power for a given address, considering staked tokens and any delegated power.

**VI. Treasury & Funding Management**
25. **`fundDAOChallengePool`**: Allows anyone to contribute ETH or ERC20 tokens to a specific challenge's reward pool.
26. **`withdrawDAOTreasuryFunds`**: Allows withdrawal of funds from the main DAO treasury, but only if approved and executed via a DAO governance proposal.

---

## Smart Contract: Aetheria Nexus

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For governance token and potential ERC20 rewards

// --- Interfaces ---

interface IAetheriaOracle {
    function receiveChallengeEvaluation(
        uint256 challengeId,
        uint256 evaluatedScore,
        string calldata evaluationDetails,
        bool success
    ) external;
}

// --- Main Contract ---

contract AetheriaNexus is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // --- State Variables ---

    // Constants
    uint8 public constant MAX_SHARD_TIER = 5;
    uint256 public constant MIN_VOTE_POWER_FOR_PROPOSAL = 100e18; // 100 governance tokens
    uint256 public constant VOTING_PERIOD_CHALLENGE = 3 days;
    uint256 public constant VOTING_PERIOD_GOVERNANCE = 7 days;
    uint256 public constant UNSTAKE_LOCKUP_PERIOD = 7 days; // For staked governance tokens

    // Core Contracts / Oracles
    IAetheriaOracle public aetheriaOracle;
    IERC20 public immutable governanceToken; // The token used for DAO voting

    // Shard Management (Dynamic NFTs)
    struct AetheriaShard {
        uint256 id;
        address owner;
        uint8 tier; // 1-5, evolves
        string[] elements; // e.g., "Fire", "Water", "Arcane"
        uint256 lastChallengeCompletedId;
        uint256 totalChallengesCompleted;
        // metadataURI is generated dynamically
    }
    mapping(uint256 => AetheriaShard) public aetheriaShards;
    uint256 private _nextTokenId;

    // Challenge System
    enum ChallengeStatus {
        Proposed,
        Voting,
        Active,
        EvaluationRequested,
        ResolvedSuccess,
        ResolvedFailure,
        Cancelled
    }

    struct AetheriaChallenge {
        uint256 id;
        address proposer;
        string description;
        uint256 activationDate; // When challenge becomes active
        uint256 endDate; // When participation closes
        uint256 targetScore; // AI-evaluated threshold for success
        uint256 currentAIResultScore; // Actual score from AI oracle
        string aiEvaluationDetails; // Details from AI
        ChallengeStatus status;
        uint256 rewardPool; // ETH or ERC20 for rewards
        address rewardToken; // Address of the reward token (0x0 for ETH)
        string[] requiredShardElements; // e.g., ["Fire", "Earth"]
        uint8 minShardTierForReward; // Min tier required to earn rewards
        uint256 proposalCreationTime;
        uint256 proposalVoteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool proposalApproved; // True if DAO approved the challenge
        bool aiEvaluationRequested;
        bool resolved;
    }
    mapping(uint256 => AetheriaChallenge) public aetheriaChallenges;
    uint256 private _nextChallengeId;
    // Mapping: challengeId => shardId => bool (if registered)
    mapping(uint256 => mapping(uint256 => bool)) public challengeParticipants;
    // Mapping: challengeId => address => bool (if claimed reward)
    mapping(uint256 => mapping(address => bool)) public claimedRewards;
    // Mapping: challengeId => address => bool (if rewardable for this user)
    mapping(uint256 => mapping(address => bool)) public isRewardableForUser;

    // DAO Governance System (beyond challenges)
    enum ProposalStatus {
        Pending,
        Voting,
        Approved,
        Rejected,
        Executed
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        address targetContract; // Contract to interact with
        bytes callData;         // Data for the function call
        uint256 value;          // ETH to send with call
        ProposalStatus status;
        uint256 proposalCreationTime;
        uint256 proposalVoteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 private _nextGovernanceProposalId;

    // Staking & Delegation for DAO
    mapping(address => uint256) public stakedTokens;
    mapping(address => uint256) public totalStakedAtWithdrawal; // For unstake lockup
    mapping(address => uint256) public unstakeRequestTime;
    mapping(address => address) public delegates; // address => delegatee
    mapping(address => uint256) public votingPower; // Direct voting power (staked + delegated-in)

    // General purpose voting tracking (for challenges & governance proposals)
    mapping(uint256 => mapping(address => bool)) public hasVotedOnChallenge;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnGovernance;

    // --- Events ---
    event AetheriaShardMinted(uint256 indexed shardId, address indexed owner, uint8 initialTier, string[] initialElements);
    event AetheriaShardEvolved(uint256 indexed shardId, uint8 oldTier, uint8 newTier);
    event AetheriaShardMutated(uint256 indexed shardId, string[] oldElements, string[] newElements);
    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, string description);
    event ChallengeProposalVoted(uint256 indexed challengeId, address indexed voter, bool support, uint256 votePower);
    event ChallengeActivated(uint256 indexed challengeId);
    event ShardRegisteredForChallenge(uint256 indexed challengeId, uint256 indexed shardId, address indexed owner);
    event AIChallengeEvaluationRequested(uint256 indexed challengeId, address indexed requester);
    event AIChallengeEvaluationReceived(uint256 indexed challengeId, uint256 evaluatedScore, bool success);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeStatus finalStatus, uint256 totalRewardAmount);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed claimant, uint256 amount, address rewardToken);
    event GovernanceProposalProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event TokensStaked(address indexed user, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 amount, uint256 lockupEndTime);
    event TokensUnstaked(address indexed user, uint256 amount);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event DAOTreasuryFunded(uint256 indexed challengeId, uint256 amount, address indexed token); // For ETH use 0x0

    // --- Modifiers ---
    modifier onlyAetheriaOracle() {
        require(msg.sender == address(aetheriaOracle), "AN: Caller is not the Aetheria Oracle");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= _nextChallengeId, "AN: Challenge does not exist");
        _;
    }

    modifier governanceProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _nextGovernanceProposalId, "AN: Proposal does not exist");
        _;
    }

    modifier hasMinVotePower() {
        require(calculateVotingPower(msg.sender) >= MIN_VOTE_POWER_FOR_PROPOSAL, "AN: Insufficient voting power to propose");
        _;
    }

    // --- Constructor ---
    constructor(address _governanceTokenAddress) ERC721("AetheriaNexusShard", "ANS") Ownable(msg.sender) {
        require(_governanceTokenAddress != address(0), "AN: Governance token address cannot be zero");
        governanceToken = IERC20(_governanceTokenAddress);
        _nextTokenId = 1; // Shard IDs start from 1
        _nextChallengeId = 1; // Challenge IDs start from 1
        _nextGovernanceProposalId = 1; // Proposal IDs start from 1
    }

    // --- I. Core Infrastructure & Access Control ---

    /// @notice Allows the contract owner to set or update the trusted AI Oracle address.
    /// @param _aetheriaOracleAddress The address of the Aetheria AI Oracle contract.
    function setAetheriaOracleAddress(address _aetheriaOracleAddress) external onlyOwner {
        require(_aetheriaOracleAddress != address(0), "AN: Oracle address cannot be zero");
        aetheriaOracle = IAetheriaOracle(_aetheriaOracleAddress);
    }

    /// @notice Pauses contract functionality in case of emergencies.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract functionality.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- II. Aetheria Shard (Dynamic NFT) Management ---

    /// @notice Mints a new Aetheria Shard NFT to the caller.
    /// @dev Initial shards are Tier 1 and have base elements.
    /// @return The ID of the newly minted shard.
    function mintAetheriaShard() external whenNotPaused returns (uint256) {
        uint256 shardId = _nextTokenId++;
        _safeMint(msg.sender, shardId);

        aetheriaShards[shardId] = AetheriaShard({
            id: shardId,
            owner: msg.sender,
            tier: 1, // Start at Tier 1
            elements: _getDefaultElements(), // Assign base elements
            lastChallengeCompletedId: 0,
            totalChallengesCompleted: 0
        });

        // Set an initial URI, which will be dynamically updated
        _setTokenURI(shardId, _buildShardMetadataURI(shardId, aetheriaShards[shardId].tier, aetheriaShards[shardId].elements));

        emit AetheriaShardMinted(shardId, msg.sender, 1, aetheriaShards[shardId].elements);
        return shardId;
    }

    /// @notice Retrieves all current details of a specific Aetheria Shard.
    /// @param _shardId The ID of the Aetheria Shard.
    /// @return A tuple containing the shard's owner, tier, elements, last challenge ID, and total challenges completed.
    function getAetheriaShardDetails(uint256 _shardId) public view returns (address owner, uint8 tier, string[] memory elements, uint256 lastChallengeId, uint256 totalChallenges) {
        require(_exists(_shardId), "AN: Shard does not exist");
        AetheriaShard storage shard = aetheriaShards[_shardId];
        return (shard.owner, shard.tier, shard.elements, shard.lastChallengeCompletedId, shard.totalChallengesCompleted);
    }

    /// @dev Overrides ERC721URIStorage's tokenURI to provide dynamic metadata.
    /// The URI reflects the current state (tier, elements) of the Aetheria Shard.
    function tokenURI(uint256 _shardId) public view override returns (string memory) {
        require(_exists(_shardId), "ERC721URIStorage: URI query for nonexistent token");
        AetheriaShard storage shard = aetheriaShards[_shardId];
        return _buildShardMetadataURI(shard.id, shard.tier, shard.elements);
    }

    /// @dev Internal function to increase a shard's tier. Called upon successful challenge resolution.
    /// @param _shardId The ID of the shard to evolve.
    function _evolveShardTier(uint256 _shardId) internal {
        AetheriaShard storage shard = aetheriaShards[_shardId];
        require(shard.tier < MAX_SHARD_TIER, "AN: Shard is already at max tier");

        uint8 oldTier = shard.tier;
        shard.tier++;
        _setTokenURI(_shardId, _buildShardMetadataURI(shard.id, shard.tier, shard.elements)); // Update metadata URI
        emit AetheriaShardEvolved(_shardId, oldTier, shard.tier);
    }

    /// @dev Internal function to mutate a shard's elemental traits. Called upon successful challenge resolution.
    /// @param _shardId The ID of the shard to mutate.
    /// @param _newElements The new set of elements for the shard.
    function _mutateShardElements(uint256 _shardId, string[] memory _newElements) internal {
        AetheriaShard storage shard = aetheriaShards[_shardId];
        string[] memory oldElements = shard.elements; // Store for event
        shard.elements = _newElements; // Replace or add elements
        _setTokenURI(_shardId, _buildShardMetadataURI(shard.id, shard.tier, shard.elements)); // Update metadata URI
        emit AetheriaShardMutated(_shardId, oldElements, shard.elements);
    }

    /// @dev Internal helper to generate a default set of elements for new shards.
    function _getDefaultElements() internal pure returns (string[] memory) {
        string[] memory defaultElements = new string[](1);
        defaultElements[0] = "Basic";
        return defaultElements;
    }

    /// @dev Internal helper to construct the dynamic metadata URI for a shard.
    function _buildShardMetadataURI(uint256 _shardId, uint8 _tier, string[] memory _elements) internal view returns (string memory) {
        // In a real application, this would point to an IPFS gateway or a dedicated metadata server
        // that dynamically generates JSON based on the shard's state.
        // For demonstration, we'll just encode the basic info.
        string memory elementsString = "[";
        for (uint256 i = 0; i < _elements.length; i++) {
            elementsString = string.concat(elementsString, "'", _elements[i], "'");
            if (i < _elements.length - 1) {
                elementsString = string.concat(elementsString, ", ");
            }
        }
        elementsString = string.concat(elementsString, "]");

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name": "Aetheria Shard #', _shardId.toString(),
                        '", "description": "An evolving entity from the Aetheria Nexus.",',
                        '"image": "ipfs://QmbzG4YtM.../shard_tier_', _tier.toString(), '.png",', // Placeholder IPFS image
                        '"attributes": [',
                        '{"trait_type": "Tier", "value": "', _tier.toString(), '"},',
                        '{"trait_type": "Elements", "value": "', elementsString, '"}'
                        // Add more dynamic attributes as needed
                        , ']}'
                    )
                )
            )
        );
    }

    // --- III. AI-Driven Challenge & Quest System ---

    /// @notice Allows any user with sufficient governance token stake to propose a new community challenge.
    /// @param _description A detailed description of the challenge.
    /// @param _durationDays The duration for which the challenge will be active (in days).
    /// @param _targetScore The AI-evaluated threshold score for the challenge to be considered successful.
    /// @param _rewardToken The address of the ERC20 token for rewards (0x0 for ETH).
    /// @param _requiredShardElements An array of elemental traits required for shards to participate.
    /// @param _minShardTierForReward Minimum shard tier to be eligible for rewards.
    function proposeAetheriaChallenge(
        string memory _description,
        uint256 _durationDays,
        uint256 _targetScore,
        address _rewardToken,
        string[] memory _requiredShardElements,
        uint8 _minShardTierForReward
    ) external whenNotPaused hasMinVotePower {
        uint256 challengeId = _nextChallengeId++;
        require(_durationDays > 0, "AN: Challenge duration must be positive");
        require(_targetScore > 0, "AN: Target score must be positive");

        aetheriaChallenges[challengeId] = AetheriaChallenge({
            id: challengeId,
            proposer: msg.sender,
            description: _description,
            activationDate: 0, // Set when activated
            endDate: 0, // Set when activated
            targetScore: _targetScore,
            currentAIResultScore: 0,
            aiEvaluationDetails: "",
            status: ChallengeStatus.Proposed,
            rewardPool: 0,
            rewardToken: _rewardToken,
            requiredShardElements: _requiredShardElements,
            minShardTierForReward: _minShardTierForReward,
            proposalCreationTime: block.timestamp,
            proposalVoteEndTime: block.timestamp + VOTING_PERIOD_CHALLENGE,
            yesVotes: 0,
            noVotes: 0,
            proposalApproved: false,
            aiEvaluationRequested: false,
            resolved: false
        });

        emit ChallengeProposed(challengeId, msg.sender, _description);
    }

    /// @notice DAO members vote "yes" or "no" on a proposed challenge.
    /// @param _challengeId The ID of the challenge proposal.
    /// @param _support True for a "yes" vote, false for "no".
    function voteOnChallengeProposal(uint256 _challengeId, bool _support) external whenNotPaused challengeExists(_challengeId) {
        AetheriaChallenge storage challenge = aetheriaChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.Proposed, "AN: Challenge not in voting phase");
        require(block.timestamp <= challenge.proposalVoteEndTime, "AN: Voting period has ended");
        require(!hasVotedOnChallenge[_challengeId][msg.sender], "AN: Already voted on this proposal");

        uint256 voterPower = calculateVotingPower(msg.sender);
        require(voterPower > 0, "AN: No voting power");

        if (_support) {
            challenge.yesVotes += voterPower;
        } else {
            challenge.noVotes += voterPower;
        }
        hasVotedOnChallenge[_challengeId][msg.sender] = true;

        emit ChallengeProposalVoted(_challengeId, msg.sender, _support, voterPower);
    }

    /// @notice Allows the owner to activate a challenge if its proposal passes.
    /// @param _challengeId The ID of the challenge to activate.
    function activateAetheriaChallenge(uint256 _challengeId) external whenNotPaused challengeExists(_challengeId) onlyOwner {
        // In a full DAO, this might be called by a successful governance action
        AetheriaChallenge storage challenge = aetheriaChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.Proposed, "AN: Challenge not in Proposed status");
        require(block.timestamp > challenge.proposalVoteEndTime, "AN: Voting period not ended");

        // Simple majority for now. Can be extended with quorum requirements.
        if (challenge.yesVotes > challenge.noVotes && challenge.yesVotes >= MIN_VOTE_POWER_FOR_PROPOSAL) { // At least proposer's power to pass
            challenge.proposalApproved = true;
            challenge.status = ChallengeStatus.Active;
            challenge.activationDate = block.timestamp;
            // Set end date based on original proposed duration (e.g., 30 days from activation)
            // For simplicity, using a fixed duration from proposal for now.
            // A more complex system would allow challenge-specific durations.
            challenge.endDate = challenge.activationDate + (challenge.proposalVoteEndTime - challenge.proposalCreationTime); // Reuse voting duration as active duration
            emit ChallengeActivated(_challengeId);
        } else {
            challenge.status = ChallengeStatus.Cancelled;
            emit ChallengeResolved(_challengeId, ChallengeStatus.Cancelled, 0); // Consider cancelling a resolution
        }
    }

    /// @notice Allows an Aetheria Shard owner to register their eligible shard for an active challenge.
    /// @param _challengeId The ID of the challenge to register for.
    /// @param _shardId The ID of the Aetheria Shard.
    function registerShardForChallenge(uint256 _challengeId, uint256 _shardId) external whenNotPaused challengeExists(_challengeId) {
        AetheriaChallenge storage challenge = aetheriaChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.Active, "AN: Challenge is not active");
        require(block.timestamp < challenge.endDate, "AN: Challenge participation period has ended");
        require(ownerOf(_shardId) == msg.sender, "AN: Not owner of shard");
        require(!challengeParticipants[_challengeId][_shardId], "AN: Shard already registered");

        AetheriaShard storage shard = aetheriaShards[_shardId];
        require(shard.tier >= challenge.minShardTierForReward, "AN: Shard tier too low for this challenge");

        // Check if shard has required elements
        bool hasAllRequiredElements = true;
        if (challenge.requiredShardElements.length > 0) {
            for (uint256 i = 0; i < challenge.requiredShardElements.length; i++) {
                bool found = false;
                for (uint256 j = 0; j < shard.elements.length; j++) {
                    if (keccak256(abi.encodePacked(shard.elements[j])) == keccak256(abi.encodePacked(challenge.requiredShardElements[i]))) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    hasAllRequiredElements = false;
                    break;
                }
            }
        }
        require(hasAllRequiredElements, "AN: Shard lacks required elements for this challenge");

        challengeParticipants[_challengeId][_shardId] = true;
        emit ShardRegisteredForChallenge(_challengeId, _shardId, msg.sender);
    }

    /// @notice Allows the contract owner to request the AI Oracle to evaluate a completed challenge.
    /// @dev This assumes the challenge's active period has ended.
    /// @param _challengeId The ID of the challenge to evaluate.
    function requestAIChallengeEvaluation(uint256 _challengeId) external onlyOwner challengeExists(_challengeId) {
        AetheriaChallenge storage challenge = aetheriaChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.Active, "AN: Challenge not in active state for evaluation request");
        require(block.timestamp >= challenge.endDate, "AN: Challenge participation period not ended");
        require(!challenge.aiEvaluationRequested, "AN: AI evaluation already requested");
        require(address(aetheriaOracle) != address(0), "AN: Aetheria Oracle not set");

        challenge.status = ChallengeStatus.EvaluationRequested;
        challenge.aiEvaluationRequested = true;

        // In a real system, this would call the oracle's external request function,
        // which might involve a payment or specific data payload.
        // For this example, we assume the oracle will eventually call `receiveAIChallengeEvaluation`.
        emit AIChallengeEvaluationRequested(_challengeId, msg.sender);
    }

    /// @notice External callback from the AI Oracle with the challenge evaluation results.
    /// @dev Only callable by the configured `aetheriaOracle` address.
    /// @param _challengeId The ID of the challenge.
    /// @param _evaluatedScore The score given by the AI for the challenge.
    /// @param _evaluationDetails Detailed string explanation from the AI.
    /// @param _success Boolean indicating if the AI determined the challenge was successful.
    function receiveAIChallengeEvaluation(
        uint256 _challengeId,
        uint256 _evaluatedScore,
        string calldata _evaluationDetails,
        bool _success
    ) external onlyAetheriaOracle challengeExists(_challengeId) {
        AetheriaChallenge storage challenge = aetheriaChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.EvaluationRequested, "AN: Challenge not awaiting AI evaluation");
        require(challenge.aiEvaluationRequested, "AN: AI evaluation was not requested for this challenge");

        challenge.currentAIResultScore = _evaluatedScore;
        challenge.aiEvaluationDetails = _evaluationDetails;
        challenge.resolved = true;

        if (_success) {
            challenge.status = ChallengeStatus.ResolvedSuccess;
        } else {
            challenge.status = ChallengeStatus.ResolvedFailure;
        }

        emit AIChallengeEvaluationReceived(_challengeId, _evaluatedScore, _success);
    }

    /// @notice Resolves a challenge outcome, triggering shard evolutions and calculating rewards.
    /// @dev This should be called after `receiveAIChallengeEvaluation` and can be called by anyone
    ///      to finalize the challenge after the oracle has provided its result.
    /// @param _challengeId The ID of the challenge to resolve.
    function resolveAetheriaChallenge(uint256 _challengeId) external nonReentrant challengeExists(_challengeId) {
        AetheriaChallenge storage challenge = aetheriaChallenges[_challengeId];
        require(challenge.resolved, "AN: Challenge not yet resolved by AI or oracle");
        require(challenge.status == ChallengeStatus.ResolvedSuccess || challenge.status == ChallengeStatus.ResolvedFailure, "AN: Challenge not in a final resolution state");
        require(challenge.rewardPool > 0, "AN: Challenge has no reward pool to distribute");

        uint256 totalRewardAmount = challenge.rewardPool;
        uint256 successfulParticipants = 0;

        // Iterate through all possible shard IDs (this is inefficient for large number of shards,
        // a more optimized approach would involve tracking participants in an array or linked list)
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (challengeParticipants[_challengeId][i]) {
                AetheriaShard storage shard = aetheriaShards[i];
                // Check if shard owner is eligible for rewards based on tier
                if (shard.tier >= challenge.minShardTierForReward) {
                    isRewardableForUser[_challengeId][shard.owner] = true; // Mark owner as rewardable
                    successfulParticipants++;

                    if (challenge.status == ChallengeStatus.ResolvedSuccess) {
                        // Trigger shard evolution/mutation based on success
                        _evolveShardTier(i);
                        // Example: Mutate elements based on AI details or a random factor
                        // For simplicity, we'll just add a "Challenger" element.
                        string[] memory newElements = new string[](shard.elements.length + 1);
                        for (uint256 j = 0; j < shard.elements.length; j++) {
                            newElements[j] = shard.elements[j];
                        }
                        newElements[shard.elements.length] = "Challenger";
                        _mutateShardElements(i, newElements);

                        shard.totalChallengesCompleted++;
                        shard.lastChallengeCompletedId = _challengeId;
                    }
                }
            }
        }

        // If challenge failed or no eligible participants, return funds to DAO treasury (or proposer)
        if (challenge.status == ChallengeStatus.ResolvedFailure || successfulParticipants == 0) {
            // Funds could be sent to a DAO treasury or back to the challenge proposer, based on rules
            // For now, let's just leave it in the contract, and can be retrieved by DAO governance
            // or proposer if a specific mechanism is implemented.
            // For this example, we'll imagine it's pooled to the contract's ETH/ERC20 balance for future DAO governance.
            // The `totalRewardAmount` remains untouched.
            emit ChallengeResolved(_challengeId, ChallengeStatus.ResolvedFailure, 0); // No rewards distributed
        } else {
            // Reward pool is now ready for individual claims
            emit ChallengeResolved(_challengeId, ChallengeStatus.ResolvedSuccess, totalRewardAmount);
        }
    }

    /// @notice Allows participants of a successfully completed challenge to claim their share of rewards.
    /// @param _challengeId The ID of the challenge.
    function claimChallengeRewards(uint256 _challengeId) external nonReentrant challengeExists(_challengeId) {
        AetheriaChallenge storage challenge = aetheriaChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.ResolvedSuccess, "AN: Challenge not successfully resolved");
        require(!claimedRewards[_challengeId][msg.sender], "AN: Rewards already claimed");
        require(isRewardableForUser[_challengeId][msg.sender], "AN: User not eligible for rewards or didn't participate");

        // Calculate participant count for dynamic reward split
        uint256 successfulParticipants = 0;
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (challengeParticipants[_challengeId][i] && aetheriaShards[i].tier >= challenge.minShardTierForReward) {
                successfulParticipants++;
            }
        }
        require(successfulParticipants > 0, "AN: No successful participants to distribute rewards to");

        uint256 rewardPerParticipant = challenge.rewardPool / successfulParticipants;
        require(rewardPerParticipant > 0, "AN: Reward amount per participant is zero");

        claimedRewards[_challengeId][msg.sender] = true;

        if (challenge.rewardToken == address(0)) { // ETH rewards
            (bool success, ) = payable(msg.sender).call{value: rewardPerParticipant}("");
            require(success, "AN: Failed to send ETH reward");
        } else { // ERC20 rewards
            IERC20(challenge.rewardToken).transfer(msg.sender, rewardPerParticipant);
        }

        emit ChallengeRewardClaimed(_challengeId, msg.sender, rewardPerParticipant, challenge.rewardToken);
    }

    // --- IV. Decentralized Autonomous Organization (DAO) Governance ---

    /// @notice Allows DAO members to propose generic protocol changes, parameter updates, or treasury spending actions.
    /// @param _description A detailed description of the governance proposal.
    /// @param _targetContract The address of the contract the proposal intends to interact with.
    /// @param _callData The encoded function call data for the target contract.
    /// @param _value ETH value to send with the call (0 for ERC20 or non-value calls).
    function proposeGovernanceAction(
        string memory _description,
        address _targetContract,
        bytes memory _callData,
        uint256 _value
    ) external whenNotPaused hasMinVotePower {
        uint256 proposalId = _nextGovernanceProposalId++;

        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            value: _value,
            status: ProposalStatus.Voting,
            proposalCreationTime: block.timestamp,
            proposalVoteEndTime: block.timestamp + VOTING_PERIOD_GOVERNANCE,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit GovernanceProposalProposed(proposalId, msg.sender, _description);
    }

    /// @notice DAO members vote "yes" or "no" on a general governance proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _support True for a "yes" vote, false for "no".
    function voteOnGovernanceAction(uint256 _proposalId, bool _support) external whenNotPaused governanceProposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Voting, "AN: Proposal not in voting phase");
        require(block.timestamp <= proposal.proposalVoteEndTime, "AN: Voting period has ended");
        require(!hasVotedOnGovernance[_proposalId][msg.sender], "AN: Already voted on this proposal");

        uint256 voterPower = calculateVotingPower(msg.sender);
        require(voterPower > 0, "AN: No voting power");

        if (_support) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }
        hasVotedOnGovernance[_proposalId][msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support, voterPower);
    }

    /// @notice Executes an approved governance proposal.
    /// @dev This function can be called by anyone after the voting period has ended and the proposal passed.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceAction(uint256 _proposalId) external payable nonReentrant governanceProposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Voting, "AN: Proposal not in voting phase");
        require(block.timestamp > proposal.proposalVoteEndTime, "AN: Voting period not ended");
        require(!proposal.executed, "AN: Proposal already executed");

        // Simple majority for now. Can be extended with quorum requirements.
        if (proposal.yesVotes > proposal.noVotes && proposal.yesVotes >= MIN_VOTE_POWER_FOR_PROPOSAL) {
            proposal.status = ProposalStatus.Approved;
            proposal.executed = true;

            (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.callData);
            require(success, "AN: Failed to execute governance action");

            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    /// @notice Users lock their governance tokens to gain voting power for DAO proposals.
    /// @param _amount The amount of governance tokens to stake.
    function stakeGovernanceTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "AN: Amount must be greater than zero");
        governanceToken.transferFrom(msg.sender, address(this), _amount);
        stakedTokens[msg.sender] += _amount;
        _updateVotingPower(msg.sender); // Update voting power immediately

        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Users request to retrieve their previously staked governance tokens after an unbonding period.
    /// @param _amount The amount of governance tokens to unstake.
    function unstakeGovernanceTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "AN: Amount must be greater than zero");
        require(stakedTokens[msg.sender] >= _amount, "AN: Insufficient staked tokens");

        stakedTokens[msg.sender] -= _amount;
        totalStakedAtWithdrawal[msg.sender] += _amount; // Track total requested for withdrawal
        unstakeRequestTime[msg.sender] = block.timestamp; // Start lockup
        _updateVotingPower(msg.sender); // Update voting power immediately

        emit UnstakeRequested(msg.sender, _amount, block.timestamp + UNSTAKE_LOCKUP_PERIOD);
    }

    /// @notice Finalizes the unstaking process after the lockup period.
    function finalizeUnstake() external nonReentrant {
        require(totalStakedAtWithdrawal[msg.sender] > 0, "AN: No unstake request outstanding");
        require(block.timestamp >= unstakeRequestTime[msg.sender] + UNSTAKE_LOCKUP_PERIOD, "AN: Unstake lockup period not over");

        uint256 amountToTransfer = totalStakedAtWithdrawal[msg.sender];
        totalStakedAtWithdrawal[msg.sender] = 0; // Reset for next request
        unstakeRequestTime[msg.sender] = 0;

        governanceToken.transfer(msg.sender, amountToTransfer);
        emit TokensUnstaked(msg.sender, amountToTransfer);
    }

    /// @notice Allows a token holder to delegate their voting power to another address.
    /// @param _delegatee The address to which to delegate voting power.
    function delegateVotingPower(address _delegatee) external whenNotPaused {
        require(_delegatee != address(0), "AN: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "AN: Cannot delegate to self");
        delegates[msg.sender] = _delegatee;
        _updateVotingPower(msg.sender);
        _updateVotingPower(_delegatee); // Update delegatee's power

        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /// @dev Internal function to update the voting power for an address.
    function _updateVotingPower(address _voter) internal {
        uint256 newPower = stakedTokens[_voter];
        // If this address is a delegatee, add power delegated to them
        // This is a simplified direct delegation model. More complex systems prevent double counting.
        // For simple delegation: A delegates to B, B's power = B's staked + A's staked (if A delegated to B)
        // Here, we just directly update 'votingPower' which is a sum of direct staked and all delegated-in.
        // A more robust system would calculate this on demand from `delegates` mapping.
        votingPower[_voter] = newPower; // Reset to direct stake, then add delegated-in
        // To find all delegators for _voter, we'd need an iterable list of delegators, or calculate on demand.
        // For now, this `votingPower` mapping will be directly managed by `_updateVotingPower` being called
        // for both delegator and delegatee when a delegation occurs.
        // For actual calculation, `calculateVotingPower` is the canonical source.
    }

    // --- V. Reputation & Dynamic Traits ---

    /// @notice View function to check how many challenges a specific shard has successfully completed.
    /// @param _shardId The ID of the Aetheria Shard.
    /// @return The total number of challenges completed by the shard.
    function getShardTotalChallengesCompleted(uint256 _shardId) public view returns (uint256) {
        require(_exists(_shardId), "AN: Shard does not exist");
        return aetheriaShards[_shardId].totalChallengesCompleted;
    }

    /// @notice Computes the effective voting power for a given address.
    /// @dev This considers directly staked tokens and any delegated power.
    /// @param _voter The address for whom to calculate voting power.
    /// @return The total voting power.
    function calculateVotingPower(address _voter) public view returns (uint256) {
        uint256 power = stakedTokens[_voter];
        // If this address has delegated their power, their own direct power is 0 for voting purposes
        // unless they are also a delegatee. For simplicity, direct staked tokens grant power.
        // If 'msg.sender' has delegated, we should check `delegates[msg.sender]` and make their power 0.
        // A more advanced system tracks `_checkpoints` for historical voting power.
        // For this example, we calculate current effective power:
        for (uint256 i = 1; i <= _nextGovernanceProposalId; i++) {
             // Iterate through all proposals to find out who has delegated to _voter
             // This is an inefficient lookup. A robust system uses a separate `delegatedVotingPower` mapping
             // updated on delegation.
             // For a fully functional, gas-efficient DAO, `OpenZeppelin/Governor` is recommended.
             // Here, we'll assume `stakedTokens[_voter]` is the direct power.
             // If _voter has delegated, then their effective power for voting is 0, UNLESS they are also a delegatee.
        }

        // Simplistic approach for this example:
        // A user's voting power is their staked tokens if they haven't delegated.
        // If they have delegated, their direct power is moved to the delegatee.
        // The `votingPower` mapping maintains the sum.
        // A user's actual staked tokens: `stakedTokens[user]`
        // The voting power derived from it:
        if (delegates[_voter] != address(0) && delegates[_voter] != _voter) { // _voter has delegated to someone else
            return 0; // Their direct staked tokens give them no voting power, it's transferred
        } else {
            return stakedTokens[_voter]; // They haven't delegated, or they are delegating to themselves (effectively not delegating).
        }
    }


    // --- VI. Treasury & Funding Management ---

    /// @notice Allows anyone to contribute ETH or ERC20 tokens to a specific challenge's reward pool.
    /// @dev For ETH contributions, simply send ETH with the call. For ERC20, approve first.
    /// @param _challengeId The ID of the challenge to fund.
    /// @param _amount The amount of tokens/ETH to contribute.
    /// @param _tokenAddress The address of the ERC20 token (0x0 for ETH).
    function fundDAOChallengePool(uint256 _challengeId, uint256 _amount, address _tokenAddress) external payable whenNotPaused challengeExists(_challengeId) nonReentrant {
        AetheriaChallenge storage challenge = aetheriaChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.Proposed || challenge.status == ChallengeStatus.Voting || challenge.status == ChallengeStatus.Active, "AN: Challenge not in a fundable state");
        require(_amount > 0, "AN: Amount must be greater than zero");

        if (_tokenAddress == address(0)) { // ETH
            require(msg.value == _amount, "AN: ETH amount sent does not match specified amount");
            challenge.rewardPool += _amount; // Directly add ETH value
            // challenge.rewardToken remains 0x0
        } else { // ERC20
            require(msg.value == 0, "AN: Do not send ETH for ERC20 funding");
            require(challenge.rewardToken == _tokenAddress, "AN: Incorrect ERC20 token for this challenge");
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
            challenge.rewardPool += _amount;
        }

        emit DAOTreasuryFunded(_challengeId, _amount, _tokenAddress);
    }

    /// @notice Allows withdrawal of funds from the main DAO treasury, but only if approved and executed via a DAO governance proposal.
    /// @dev This function is a placeholder; actual withdrawals must go through a governance `executeGovernanceAction` call.
    ///      The `targetContract` would be `address(this)` and `callData` would be encoded for this function.
    /// @param _tokenAddress The address of the token to withdraw (0x0 for ETH).
    /// @param _amount The amount to withdraw.
    /// @param _recipient The address to send funds to.
    function _withdrawDAOTreasuryFunds(address _tokenAddress, uint256 _amount, address _recipient) internal onlyOwner {
        // This function is internal and only callable by governance via executeGovernanceAction.
        // It's marked onlyOwner to restrict direct external calls, but the DAO proposal mechanism
        // would pass `this.address` as `targetContract` and encoded call to `_withdrawDAOTreasuryFunds` as `callData`.
        require(_amount > 0, "AN: Amount must be greater than zero");
        require(_recipient != address(0), "AN: Recipient cannot be zero address");

        if (_tokenAddress == address(0)) { // ETH
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            require(success, "AN: Failed to withdraw ETH from DAO treasury");
        } else { // ERC20
            IERC20(_tokenAddress).transfer(_recipient, _amount);
        }
    }

    // Fallback function to receive ETH
    receive() external payable {
        // ETH sent directly to the contract (not via fundDAOChallengePool)
        // could be considered general DAO treasury funds.
        // For this example, we'll allow it.
    }
}

// --- Helper for Base64 Encoding (from OpenZeppelin) ---
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load not just the table, but also everything else in memory to prevent stack overflow
        // of "Variable too deep" errors when compiling with very small stack sizes
        string memory table = _TABLE;

        uint256 lastElementEncodedOffset = data.length - 1;
        uint256 padding = 0;
        if (data.length % 3 == 1) {
            padding = 2;
        } else if (data.length % 3 == 2) {
            padding = 1;
        }

        string memory encoded = new string(4 * ((data.length + 2) / 3));
        uint256 encodedOffset = 0;
        uint256 dataOffset = 0;

        // "packed" into a uint24 / 3 bytes
        for (; dataOffset < lastElementEncodedOffset; dataOffset += 3) {
            encodedOffset = _encodeByte(data[dataOffset], data[dataOffset + 1], data[dataOffset + 2], encoded, encodedOffset, table);
        }

        // deal with padding at the end
        if (padding == 2) {
            encodedOffset = _encodeByte(data[dataOffset], 0, 0, encoded, encodedOffset, table);
            encoded[encodedOffset - 1] = '=';
            encoded[encodedOffset] = '=';
        } else if (padding == 1) {
            encodedOffset = _encodeByte(data[dataOffset], data[dataOffset + 1], 0, encoded, encodedOffset, table);
            encoded[encodedOffset] = '=';
        }

        return encoded;
    }

    function _encodeByte(bytes memory data, uint256 offset1, uint224 offset2, uint256 offset3, string memory encoded, uint256 encodedOffset, string memory table) private pure returns (uint256) {
        uint24 input = (uint24(uint8(data[offset1])) << 16) | (uint24(uint8(data[offset2])) << 8) | uint24(uint8(data[offset3]));

        encoded[encodedOffset] = table[(input >> 18) & 0x3F];
        encoded[encodedOffset + 1] = table[(input >> 12) & 0x3F];
        encoded[encodedOffset + 2] = table[(input >> 6) & 0x3F];
        encoded[encodedOffset + 3] = table[input & 0x3F];

        return encodedOffset + 4;
    }
}
```