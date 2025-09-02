The `VeritasProtocol` is an AI-augmented decentralized policy engine designed to create a self-evolving, community-governed knowledge and policy base. It leverages a trusted off-chain AI oracle to provide insights and propose policies, which are then subject to community ratification through a dynamic voting mechanism. Credibility, reputation, and adaptive parameters are central to its operation, fostering an ecosystem where valuable knowledge and effective policies emerge through incentivized participation and AI guidance.

---

**Contract: VeritasProtocol (AI-Augmented Decentralized Policy Engine)**

**Purpose:**
The Veritas Protocol establishes a decentralized, community-curated knowledge and policy base augmented by a trusted AI Oracle. It aims to create a self-evolving governance system where AI provides insights and proposals, which are then refined and approved by the community. Credibility, reputation, and dynamic parameters are central to its operation.

**Key Concepts:**
1.  **AI Oracle Integration:** A designated off-chain AI service provides signed data for policy suggestions, knowledge updates, and parameter adjustments. This integration allows the protocol to react to external data and complex analyses that are not feasible for on-chain computation.
2.  **Dynamic Credibility Scoring:** Knowledge entries are assigned a credibility score that dynamically adjusts based on user staking, the outcome of community challenges (votes on truthfulness), and insights provided by the AI Oracle.
3.  **Adaptive Governance:** Policy parameters (e.g., voting thresholds, staking requirements, challenge periods) can evolve. Both users and the AI Oracle can propose changes, and once approved by the community, these policies can be executed directly by the contract, leading to a truly adaptive and self-modifying system.
4.  **Incentivized Knowledge Curation:** Users are rewarded with `VERITAS_TOKEN` and reputation for submitting valuable knowledge, successfully challenging misinformation, and actively participating in governance and validation processes.
5.  **Policy Execution Engine:** Approved policy proposals can trigger various on-chain actions, from updating the protocol's internal parameters to initiating external calls to other integrated contracts, enabling broad and flexible governance.

**Outline:**
*   **I. Core System Setup & Access Control:** Initializes the protocol, sets up initial governance and AI oracle addresses, and includes emergency pause mechanisms.
*   **II. Knowledge Base Management:** Functions for users to submit new knowledge, stake tokens to support existing knowledge, challenge entries, and participate in resolving truthfulness disputes.
*   **III. Policy & Governance:** Mechanisms for users and the AI Oracle to propose new policies or parameter changes, for the community to vote on these proposals, and for the protocol to execute approved policies.
*   **IV. AI Oracle Interaction & Insights:** Dedicated endpoints for the trusted AI Oracle to securely submit data, update knowledge credibility, and suggest reputation adjustments based on its off-chain analysis.
*   **V. Reputation & Rewards:** Logic for tracking user reputation (a key factor in voting power and proposal eligibility) and allowing users to claim earned `VERITAS_TOKEN` rewards.
*   **VI. View Functions:** Read-only functions to query the state of knowledge entries, policy proposals, challenges, and user profiles.

---

**Function Summary (23 Functions):**

**A. Core System Setup & Access Control**
1.  `constructor(address _veritasTokenAddress)`: Initializes the contract, sets the `VERITAS_TOKEN` address, and assigns the deployer as initial governance.
2.  `setGovernanceAddress(address _newGovernance)`: **[Governance]** Transfers the primary governance role to a new address (e.g., a DAO multisig).
3.  `setAIOracleAddress(address _newAIOracle)`: **[Governance]** Sets the trusted address of the off-chain AI Oracle.
4.  `updateSystemParameters(...)`: **[Governance]** Allows the governance entity to directly adjust core protocol parameters like minimum stakes and voting periods.
5.  `pauseProtocol(bool _isPaused)`: **[Governance]** An emergency switch to pause/unpause critical protocol functions.

**B. Knowledge Base Management**
6.  `submitKnowledgeEntry(string memory _contentHash, string[] memory _tags)`: Allows a user to submit a new piece of knowledge, implicitly staking the `minKnowledgeStake`.
7.  `stakeOnKnowledgeEntry(uint256 _entryId, uint256 _amount)`: Users can stake additional `VERITAS_TOKEN` on an existing knowledge entry to boost its perceived credibility.
8.  `unstakeFromKnowledgeEntry(uint256 _entryId, uint256 _amount)`: Allows users to withdraw their staked tokens from a knowledge entry, provided they are not locked in an active challenge.
9.  `challengeKnowledgeEntry(uint256 _entryId, string memory _reasonHash)`: Initiates a formal challenge against a knowledge entry's truthfulness, requiring a `minChallengeStake` and sufficient reputation.
10. `voteOnChallenge(uint256 _challengeId, bool _challengerWins)`: Community members vote on the outcome of an ongoing knowledge challenge.
11. `finalizeChallenge(uint256 _challengeId)`: Finalizes a challenge once its voting period ends, updates the knowledge entry's credibility, and distributes rewards/penalties.
12. `updateKnowledgeEntryTags(uint256 _entryId, string[] memory _newTags)`: **[Governance]** Allows governance or an approved policy to update the tags of a knowledge entry.

**C. Policy & Governance**
13. `proposeUserPolicy(string memory _contentHash, uint256 _executionType, bytes memory _executionData)`: Allows a user with sufficient reputation and stake to propose a new policy or system parameter change.
14. `proposeAIPolicy(string memory _contentHash, uint256 _executionType, bytes memory _executionData, bytes memory _aiSignature)`: **[AI Oracle]** The trusted AI Oracle proposes a new policy, verified by its cryptographic signature.
15. `voteOnPolicyProposal(uint256 _proposalId, bool _voteFor)`: Community members vote on an active policy proposal.
16. `executePolicyProposal(uint256 _proposalId)`: Executes a policy proposal if it has successfully passed the community vote and met all thresholds.
17. `cancelPolicyProposal(uint256 _proposalId)`: Allows the proposer to cancel their own policy proposal if no votes have been cast and before the voting period begins.

**D. AI Oracle Interaction & Insights**
18. `submitAIKnowledgeInsight(uint256 _entryId, uint256 _suggestedCredibilityScore, bytes memory _aiSignature)`: **[AI Oracle]** Allows the AI Oracle to provide an insight to adjust a knowledge entry's credibility score.
19. `submitAIReputationAdjustment(address _user, int256 _reputationDelta, bytes memory _aiSignature)`: **[AI Oracle]** Allows the AI Oracle to suggest reputation adjustments for users based on off-chain analysis of their contributions and behavior.

**E. Reputation & Rewards**
20. `claimRewards()`: Allows users to claim their accumulated `VERITAS_TOKEN` rewards earned from successful protocol participation.
21. `getUserReputation(address _user)`: **[View]** Retrieves a user's current reputation score.

**F. View Functions**
22. `getKnowledgeEntry(uint256 _entryId)`: **[View]** Retrieves the full details of a specific knowledge entry.
23. `getPolicyProposal(uint256 _proposalId)`: **[View]** Retrieves the full details of a specific policy proposal.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Custom errors for gas efficiency and clarity
error Unauthorized();
error InvalidSignature();
error ProposalNotFound();
error ChallengeNotFound();
error KnowledgeEntryNotFound();
error InvalidState();
error InsufficientStake();
error VotingPeriodNotActive();
error ChallengePeriodNotActive();
error AlreadyVoted();
error NotEnoughReputation();
error EmptyContentHash();
error InvalidExecutionType();
error NotPaused();
error IsPaused();
error NoRewardsToClaim();
error CannotCancelActiveProposal();
error InvalidSignatureRecoveredAddress();

/**
 * @title VeritasProtocol (AI-Augmented Decentralized Policy Engine)
 * @author Your Name/Company
 * @dev This contract establishes a decentralized, community-curated knowledge and policy base augmented by a trusted AI Oracle.
 *      It aims to create a self-evolving governance system where AI provides insights and proposals, which are then refined and approved by the community.
 *      Credibility, reputation, and dynamic parameters are central to its operation.
 *
 * Key Concepts:
 * 1.  AI Oracle Integration: A designated off-chain AI service provides signed data for policy suggestions, knowledge updates, and parameter adjustments.
 * 2.  Dynamic Credibility Scoring: Knowledge entries have a score influenced by staking, successful challenges, and AI insights.
 * 3.  Adaptive Governance: Policy parameters (voting thresholds, staking requirements) can evolve based on community votes on AI or user-generated proposals.
 * 4.  Incentivized Knowledge Curation: Users are rewarded for submitting valuable knowledge, successfully challenging misinformation, and participating in governance.
 * 5.  Policy Execution: Approved proposals can directly modify contract parameters or trigger predefined actions.
 */
contract VeritasProtocol is Ownable {
    IERC20 public immutable VERITAS_TOKEN; // The protocol's native utility token

    address public aiOracleAddress; // Address of the trusted off-chain AI oracle
    address public governanceAddress; // Address with governance control, initially deployer, can be changed by governance proposal.

    uint256 public knowledgeEntryIdCounter;
    uint256 public policyProposalIdCounter;
    uint256 public challengeIdCounter;

    // System Parameters - adjustable via governance proposals or direct governance calls
    uint256 public minKnowledgeStake;           // Minimum stake required to submit knowledge
    uint256 public minProposalStake;            // Minimum stake required to submit a policy proposal
    uint256 public minChallengeStake;           // Minimum stake required to initiate a challenge
    uint256 public proposalVotingPeriod;        // Duration for policy proposal voting
    uint256 public challengeVotingPeriod;       // Duration for knowledge challenge voting
    uint256 public minReputationForProposing;   // Minimum reputation for user to propose policy
    uint256 public minReputationForVoting;      // Minimum reputation for user to vote on policies/challenges
    uint256 public reputationRewardForSuccess;  // Amount of reputation gained for successful actions
    uint256 public reputationPenaltyForFailure; // Amount of reputation lost for failed actions
    uint256 public constant INITIAL_CREDIBILITY = 1000; // Starting credibility for new knowledge entries

    bool public paused; // Emergency pause switch

    // Enums
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed, Canceled }
    enum ChallengeStatus { Pending, Active, Resolved }
    enum ExecutionType {
        None,             // No direct on-chain execution, purely informational
        UpdateParameter,  // Updates a contract parameter (e.g., minKnowledgeStake)
        ExternalCall,     // Makes an external call to another contract
        ModifyKnowledge   // Modifies a knowledge entry's state (e.g., tags, active status)
    }
    // Sub-types for ExecutionType.UpdateParameter to specify which parameter
    enum ParameterType {
        MinKnowledgeStake, MinProposalStake, MinChallengeStake,
        ProposalVotingPeriod, ChallengeVotingPeriod,
        MinReputationForProposing, MinReputationForVoting,
        ReputationRewardForSuccess, ReputationPenaltyForFailure
    }
    // Sub-types for ExecutionType.ModifyKnowledge to specify which action
    enum KnowledgeActionType { UpdateTags, SetActiveStatus, AdjustCredibility }

    // Structs
    struct KnowledgeEntry {
        uint256 id;
        bytes32 contentHash; // Hash of the knowledge content (off-chain)
        address creator;
        uint256 timestamp;
        string[] tags;
        uint256 credibilityScore; // Dynamic score, influenced by stakes, challenges, AI
        uint256 totalStaked; // Total VERITAS_TOKEN staked on this entry
        bool isActive; // Can be deactivated if proven false
        uint256 lastUpdated;
    }

    struct PolicyProposal {
        uint256 id;
        address proposer;
        bytes32 contentHash; // Hash of the policy text (off-chain)
        ExecutionType executionType;
        bytes executionData; // Data for on-chain execution (e.g., function signature + args)
        ProposalStatus status;
        uint256 startVoteTime;
        uint256 endVoteTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        bool executed;
    }

    struct Challenge {
        uint256 id;
        uint256 knowledgeEntryId;
        address challenger;
        bytes32 reasonHash; // Hash of the reason for challenge (off-chain)
        uint256 challengeStake; // Stake from the challenger (locked)
        ChallengeStatus status;
        uint256 startVoteTime;
        uint256 endVoteTime;
        uint256 votesForChallenger;
        uint256 votesAgainstChallenger;
    }

    struct UserProfile {
        int256 reputationScore; // Can be negative for penalization
        uint256 totalVERITASStaked; // Total VERITAS tokens actively staked by this user across entries/proposals
        uint256 earnedRewards; // VERITAS_TOKEN rewards claimable by the user
        mapping(uint256 => bool) votedOnProposal; // proposalId => voted
        mapping(uint256 => bool) votedOnChallenge; // challengeId => voted
    }

    // Mappings
    mapping(uint256 => KnowledgeEntry) public knowledgeEntries;
    mapping(uint256 => PolicyProposal) public policyProposals;
    mapping(uint256 => Challenge) public challenges;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => mapping(address => uint256)) public userStakesOnKnowledge; // knowledgeEntryId => userAddress => amount

    // Events
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event AIOracleAddressUpdated(address indexed previousOracle, address indexed newOracle);
    event ParametersUpdated(uint256 minKnowledgeStake, uint256 minProposalStake, uint256 minChallengeStake, uint256 proposalVotingPeriod, uint256 challengeVotingPeriod, uint256 minReputationForProposing, uint256 minReputationForVoting);
    event ProtocolPaused(bool isPaused);

    event KnowledgeEntrySubmitted(uint256 indexed entryId, address indexed creator, bytes32 contentHash, string[] tags, uint256 initialCredibility);
    event KnowledgeStaked(uint256 indexed entryId, address indexed staker, uint256 amount);
    event KnowledgeUnstaked(uint256 indexed entryId, address indexed unstaker, uint256 amount);
    event KnowledgeEntryTagsUpdated(uint256 indexed entryId, string[] newTags);

    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed entryId, address indexed challenger, bytes32 reasonHash, uint256 stake);
    event ChallengeVoteCast(uint256 indexed challengeId, address indexed voter, bool challengerWins);
    event ChallengeFinalized(uint256 indexed challengeId, uint256 indexed entryId, bool challengerWon, uint256 newCredibilityScore);

    event PolicyProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 contentHash, ExecutionType executionType);
    event PolicyVoteCast(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event PolicyProposalExecuted(uint256 indexed proposalId, ExecutionType executionType);
    event PolicyProposalCanceled(uint256 indexed proposalId);

    event AIInsightSubmitted(uint256 indexed entryId, uint256 suggestedCredibility, bytes aiSignature);
    event AIReputationAdjusted(address indexed user, int256 reputationDelta, bytes aiSignature);

    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationAdjusted(address indexed user, int256 newReputation);

    // Modifiers
    modifier onlyGovernance() {
        if (msg.sender != governanceAddress) revert Unauthorized();
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert IsPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    /**
     * @dev Constructor to initialize the contract with the VERITAS_TOKEN address.
     * @param _veritasTokenAddress The address of the VERITAS ERC20 token.
     */
    constructor(address _veritasTokenAddress) Ownable(msg.sender) {
        VERITAS_TOKEN = IERC20(_veritasTokenAddress);
        governanceAddress = msg.sender; // Initial governance is the deployer (owner)
        aiOracleAddress = address(0); // Must be set by governance later

        // Set initial system parameters (can be changed by governance later)
        minKnowledgeStake = 100 * (10 ** 18); // Example: 100 VERITAS tokens
        minProposalStake = 200 * (10 ** 18); // Example: 200 VERITAS tokens
        minChallengeStake = 150 * (10 ** 18); // Example: 150 VERITAS tokens
        proposalVotingPeriod = 7 days;
        challengeVotingPeriod = 3 days;
        minReputationForProposing = 100;
        minReputationForVoting = 10;
        reputationRewardForSuccess = 20;
        reputationPenaltyForFailure = 10;

        knowledgeEntryIdCounter = 0;
        policyProposalIdCounter = 0;
        challengeIdCounter = 0;
        paused = false;
    }

    /**
     * I. Core System Setup & Access Control
     */

    /**
     * @dev Transfers governance ownership. Only current governance can call this.
     *      The initial `owner()` from Ownable can set the first non-EOA governance (e.g., a DAO multisig).
     *      After that, the `governanceAddress` can self-perpetuate.
     * @param _newGovernance The address of the new governance.
     */
    function setGovernanceAddress(address _newGovernance) external onlyGovernance {
        if (_newGovernance == address(0)) revert Unauthorized();
        address oldGovernance = governanceAddress;
        governanceAddress = _newGovernance;
        emit GovernanceTransferred(oldGovernance, _newGovernance);
    }

    /**
     * @dev Sets the address of the trusted AI oracle. Only governance can call this.
     * @param _newAIOracle The address of the new AI oracle.
     */
    function setAIOracleAddress(address _newAIOracle) external onlyGovernance {
        if (_newAIOracle == address(0)) revert Unauthorized();
        address oldOracle = aiOracleAddress;
        aiOracleAddress = _newAIOracle;
        emit AIOracleAddressUpdated(oldOracle, _newAIOracle);
    }

    /**
     * @dev Updates core system parameters. Can be called by governance directly or via policy execution.
     * @param _minKnowledgeStake Minimum stake for knowledge submission.
     * @param _minProposalStake Minimum stake for policy proposal.
     * @param _minChallengeStake Minimum stake for challenge initiation.
     * @param _proposalVotingPeriod Duration for policy proposal voting.
     * @param _challengeVotingPeriod Duration for knowledge challenge voting.
     * @param _minReputationForProposing Minimum reputation for user to propose policy.
     * @param _minReputationForVoting Minimum reputation for user to vote on policies/challenges.
     */
    function updateSystemParameters(
        uint256 _minKnowledgeStake,
        uint256 _minProposalStake,
        uint256 _minChallengeStake,
        uint256 _proposalVotingPeriod,
        uint256 _challengeVotingPeriod,
        uint256 _minReputationForProposing,
        uint256 _minReputationForVoting
    ) external onlyGovernance {
        minKnowledgeStake = _minKnowledgeStake;
        minProposalStake = _minProposalStake;
        minChallengeStake = _minChallengeStake;
        proposalVotingPeriod = _proposalVotingPeriod;
        challengeVotingPeriod = _challengeVotingPeriod;
        minReputationForProposing = _minReputationForProposing;
        minReputationForVoting = _minReputationForVoting;
        emit ParametersUpdated(
            _minKnowledgeStake,
            _minProposalStake,
            _minChallengeStake,
            _proposalVotingPeriod,
            _challengeVotingPeriod,
            _minReputationForProposing,
            _minReputationForVoting
        );
    }

    /**
     * @dev Emergency pause/unpause of critical functions. Only governance can call this.
     * @param _isPaused True to pause, false to unpause.
     */
    function pauseProtocol(bool _isPaused) external onlyGovernance {
        if (paused == _isPaused) {
            if (_isPaused) revert IsPaused();
            else revert NotPaused();
        }
        paused = _isPaused;
        emit ProtocolPaused(_isPaused);
    }

    /**
     * II. Knowledge Base Management
     */

    /**
     * @dev Allows a user to submit a new piece of knowledge, implicitly staking the `minKnowledgeStake`.
     * @param _contentHash Hash of the knowledge content (e.g., IPFS CID).
     * @param _tags Array of tags for categorization.
     */
    function submitKnowledgeEntry(string memory _contentHash, string[] memory _tags) external whenNotPaused {
        if (bytes(_contentHash).length == 0) revert EmptyContentHash();
        
        // Ensure the user has enough tokens to cover the stake
        // This implicitly assumes the user has approved the contract to spend minKnowledgeStake
        if (VERITAS_TOKEN.balanceOf(msg.sender) < minKnowledgeStake) revert InsufficientStake();

        uint256 newEntryId = ++knowledgeEntryIdCounter;
        knowledgeEntries[newEntryId] = KnowledgeEntry({
            id: newEntryId,
            contentHash: keccak256(abi.encodePacked(_contentHash)),
            creator: msg.sender,
            timestamp: block.timestamp,
            tags: _tags,
            credibilityScore: INITIAL_CREDIBILITY, // Initial credibility
            totalStaked: 0,
            isActive: true,
            lastUpdated: block.timestamp
        });

        // Stake the required tokens for the entry
        _stakeTokens(msg.sender, newEntryId, minKnowledgeStake);
        userProfiles[msg.sender].totalVERITASStaked += minKnowledgeStake;
        
        emit KnowledgeEntrySubmitted(newEntryId, msg.sender, keccak256(abi.encodePacked(_contentHash)), _tags, INITIAL_CREDIBILITY);
    }

    /**
     * @dev Users can stake additional tokens on an existing knowledge entry to vouch for its credibility.
     * @param _entryId The ID of the knowledge entry.
     * @param _amount The amount of VERITAS_TOKEN to stake.
     */
    function stakeOnKnowledgeEntry(uint256 _entryId, uint256 _amount) external whenNotPaused {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        if (entry.id == 0) revert KnowledgeEntryNotFound();
        if (!entry.isActive) revert InvalidState(); // Cannot stake on an inactive/disproven entry
        if (_amount == 0) revert InsufficientStake();

        _stakeTokens(msg.sender, _entryId, _amount);
        userProfiles[msg.sender].totalVERITASStaked += _amount;
        entry.totalStaked += _amount;
        emit KnowledgeStaked(_entryId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to withdraw their stake from a knowledge entry.
     *      Requires that the tokens are not locked in an active challenge.
     * @param _entryId The ID of the knowledge entry.
     * @param _amount The amount of VERITAS_TOKEN to unstake.
     */
    function unstakeFromKnowledgeEntry(uint256 _entryId, uint256 _amount) external whenNotPaused {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        if (entry.id == 0) revert KnowledgeEntryNotFound();
        if (userStakesOnKnowledge[_entryId][msg.sender] < _amount) revert InsufficientStake();
        
        // TODO: In a real system, iterate through challenges to see if this stake is locked.
        // For simplicity, this example assumes stakes are not locked by challenges at this level.
        // A more robust system would track active challenges per entry and block unstaking or only allow partial unstaking.

        userStakesOnKnowledge[_entryId][msg.sender] -= _amount;
        userProfiles[msg.sender].totalVERITASStaked -= _amount;
        entry.totalStaked -= _amount;
        _transferTokens(msg.sender, _amount);
        emit KnowledgeUnstaked(_entryId, msg.sender, _amount);
    }

    /**
     * @dev Initiates a challenge against a knowledge entry's truthfulness, requiring a stake and sufficient reputation.
     * @param _entryId The ID of the knowledge entry to challenge.
     * @param _reasonHash Hash of the reason/evidence for the challenge (off-chain).
     */
    function challengeKnowledgeEntry(uint256 _entryId, string memory _reasonHash) external whenNotPaused {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        if (entry.id == 0) revert KnowledgeEntryNotFound();
        if (!entry.isActive) revert InvalidState();
        if (userProfiles[msg.sender].reputationScore < minReputationForProposing) revert NotEnoughReputation();
        
        // Ensure challenger has enough tokens to cover the stake
        if (VERITAS_TOKEN.balanceOf(msg.sender) < minChallengeStake) revert InsufficientStake();
        if (bytes(_reasonHash).length == 0) revert EmptyContentHash();

        uint256 newChallengeId = ++challengeIdCounter;
        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            knowledgeEntryId: _entryId,
            challenger: msg.sender,
            reasonHash: keccak256(abi.encodePacked(_reasonHash)),
            challengeStake: minChallengeStake,
            status: ChallengeStatus.Active,
            startVoteTime: block.timestamp,
            endVoteTime: block.timestamp + challengeVotingPeriod,
            votesForChallenger: 0,
            votesAgainstChallenger: 0
        });

        // The challenger stakes tokens, which are held by the contract during the challenge
        VERITAS_TOKEN.transferFrom(msg.sender, address(this), minChallengeStake);
        userProfiles[msg.sender].totalVERITASStaked += minChallengeStake; // Tokens are still 'staked' but locked for this specific challenge

        emit ChallengeInitiated(newChallengeId, _entryId, msg.sender, keccak256(abi.encodePacked(_reasonHash)), minChallengeStake);
    }

    /**
     * @dev Community members vote on the outcome of an ongoing challenge.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _challengerWins True if voting that the challenger is correct (knowledge is false), false otherwise.
     */
    function voteOnChallenge(uint256 _challengeId, bool _challengerWins) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Active) revert InvalidState();
        if (block.timestamp < challenge.startVoteTime || block.timestamp > challenge.endVoteTime) revert VotingPeriodNotActive();
        if (userProfiles[msg.sender].reputationScore < minReputationForVoting) revert NotEnoughReputation();
        if (userProfiles[msg.sender].votedOnChallenge[_challengeId]) revert AlreadyVoted();

        userProfiles[msg.sender].votedOnChallenge[_challengeId] = true;
        if (_challengerWins) {
            challenge.votesForChallenger++;
        } else {
            challenge.votesAgainstChallenger++;
        }

        emit ChallengeVoteCast(_challengeId, msg.sender, _challengerWins);
    }

    /**
     * @dev Finalizes a challenge, updates credibility, and distributes rewards/penalties based on voting outcome.
     *      Anyone can call this after the voting period ends.
     * @param _challengeId The ID of the challenge to finalize.
     */
    function finalizeChallenge(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Active) revert InvalidState();
        if (block.timestamp <= challenge.endVoteTime) revert ChallengePeriodNotActive();

        KnowledgeEntry storage entry = knowledgeEntries[challenge.knowledgeEntryId];
        bool challengerWon = challenge.votesForChallenger > challenge.votesAgainstChallenger;

        // Challenger's stake is no longer "locked" in the specific challenge.
        userProfiles[challenge.challenger].totalVERITASStaked -= challenge.challengeStake; 

        if (challengerWon) {
            // Challenger wins: knowledge is (likely) false. Challenger gets stake back + reward.
            // Original stakers on knowledge entries would be penalized in a more complex system.
            entry.credibilityScore = entry.credibilityScore * 3 / 4; // Reduce credibility significantly
            entry.isActive = false; // Mark as inactive/disproven
            _adjustReputation(challenge.challenger, reputationRewardForSuccess);
            
            // Return challenger's stake. A reward could come from a pool or a percentage of total staked on the entry.
            // For simplicity, challenger gets their stake back.
            _transferTokens(challenge.challenger, challenge.challengeStake);
            userProfiles[challenge.challenger].earnedRewards += challenge.challengeStake; // Add to claimable rewards

            // Penalize creator for false knowledge
            _adjustReputation(entry.creator, -reputationPenaltyForFailure);

            // TODO: Penalize users who staked on the disproven entry (e.g., reduce credibility/stake).
            // This is complex as it requires iterating through `userStakesOnKnowledge[entryId]`.
            // For now, only the creator is directly penalized in this example.

        } else {
            // Challenger loses: knowledge is (likely) true. Challenger loses stake. Creator/stakers on knowledge gain.
            entry.credibilityScore = entry.credibilityScore + (INITIAL_CREDIBILITY / 5); // Increase credibility
            _adjustReputation(challenge.challenger, -reputationPenaltyForFailure);
            _adjustReputation(entry.creator, reputationRewardForSuccess);

            // Challenger's stake is effectively burned (stays in contract, could be used for a reward pool).
        }

        challenge.status = ChallengeStatus.Resolved;
        entry.lastUpdated = block.timestamp;
        emit ChallengeFinalized(challenge.id, entry.id, challengerWon, entry.credibilityScore);
    }

    /**
     * @dev Allows governance (or potentially an AI-approved process) to update tags of a knowledge entry.
     * @param _entryId The ID of the knowledge entry.
     * @param _newTags The new array of tags.
     */
    function updateKnowledgeEntryTags(uint256 _entryId, string[] memory _newTags) external onlyGovernance whenNotPaused {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        if (entry.id == 0) revert KnowledgeEntryNotFound();
        entry.tags = _newTags; // Overwrite current tags
        entry.lastUpdated = block.timestamp;
        emit KnowledgeEntryTagsUpdated(_entryId, _newTags);
    }

    /**
     * III. Policy & Governance
     */

    /**
     * @dev A user proposes a new policy or system parameter change, requiring a stake and sufficient reputation.
     * @param _contentHash Hash of the policy text (off-chain).
     * @param _executionType The type of action this policy proposes.
     * @param _executionData Encoded function call data for `ExternalCall` or parameter data for `UpdateParameter`.
     */
    function proposeUserPolicy(string memory _contentHash, uint256 _executionType, bytes memory _executionData) external whenNotPaused {
        if (userProfiles[msg.sender].reputationScore < minReputationForProposing) revert NotEnoughReputation();
        
        // Ensure the user has enough tokens to cover the stake
        if (VERITAS_TOKEN.balanceOf(msg.sender) < minProposalStake) revert InsufficientStake();
        if (bytes(_contentHash).length == 0) revert EmptyContentHash();

        _proposePolicy(msg.sender, keccak256(abi.encodePacked(_contentHash)), ExecutionType(_executionType), _executionData);

        // Deduct proposal stake (it's held by the contract, returned if proposal succeeds, lost if fails).
        VERITAS_TOKEN.transferFrom(msg.sender, address(this), minProposalStake);
        userProfiles[msg.sender].totalVERITASStaked += minProposalStake; // Tokens are still 'staked' but locked for this specific proposal
    }

    /**
     * @dev The trusted AI Oracle proposes a new policy, verified by its signature.
     *      The AI oracle must craft the message and sign it off-chain.
     *      The message should typically include relevant data to prevent replay attacks and ensure context.
     *      Example message content for signing: `keccak256(abi.encodePacked(block.chainid, address(this), _contentHash, _executionType, _executionData, block.timestamp))`
     * @param _contentHash Hash of the policy text (off-chain).
     * @param _executionType The type of action this policy proposes.
     * @param _executionData Encoded function call data for `ExternalCall` or parameter data for `UpdateParameter`.
     * @param _aiSignature The signature from the AI oracle.
     */
    function proposeAIPolicy(
        string memory _contentHash,
        uint256 _executionType,
        bytes memory _executionData,
        bytes memory _aiSignature
    ) external onlyAIOracle whenNotPaused {
        if (bytes(_contentHash).length == 0) revert EmptyContentHash();

        // Reconstruct the message hash that the AI signed
        bytes32 messageHash = keccak256(abi.encodePacked(
            block.chainid,
            address(this),
            keccak256(abi.encodePacked(_contentHash)),
            _executionType,
            _executionData,
            block.timestamp
        ));

        // Verify the signature against the AI oracle address
        address signer = _recoverSigner(messageHash, _aiSignature);
        if (signer != aiOracleAddress) revert InvalidSignatureRecoveredAddress();

        _proposePolicy(address(this), keccak256(abi.encodePacked(_contentHash)), ExecutionType(_executionType), _executionData);
    }

    // Internal helper for policy proposal creation
    function _proposePolicy(address _proposer, bytes32 _contentHash, ExecutionType _executionType, bytes memory _executionData) internal {
        uint256 newProposalId = ++policyProposalIdCounter;
        policyProposals[newProposalId] = PolicyProposal({
            id: newProposalId,
            proposer: _proposer,
            contentHash: _contentHash,
            executionType: _executionType,
            executionData: _executionData,
            status: ProposalStatus.Active,
            startVoteTime: block.timestamp,
            endVoteTime: block.timestamp + proposalVotingPeriod,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false
        });
        emit PolicyProposalSubmitted(newProposalId, _proposer, _contentHash, _executionType);
    }

    /**
     * @dev Community members vote on an active policy proposal. Voting power is influenced by reputation.
     * @param _proposalId The ID of the policy proposal.
     * @param _voteFor True to vote for, false to vote against.
     */
    function voteOnPolicyProposal(uint256 _proposalId, bool _voteFor) external whenNotPaused {
        PolicyProposal storage proposal = policyProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert InvalidState();
        if (block.timestamp < proposal.startVoteTime || block.timestamp > proposal.endVoteTime) revert VotingPeriodNotActive();
        if (userProfiles[msg.sender].reputationScore < minReputationForVoting) revert NotEnoughReputation();
        if (userProfiles[msg.sender].votedOnProposal[_proposalId]) revert AlreadyVoted();

        userProfiles[msg.sender].votedOnProposal[_proposalId] = true;
        // Voting power could be weighted by reputation or staked tokens, for simplicity, 1 address = 1 vote.
        // For an advanced contract, consider: `uint256 voteWeight = _getVotingPower(msg.sender);`
        if (_voteFor) {
            proposal.totalVotesFor++;
        } else {
            proposal.totalVotesAgainst++;
        }

        emit PolicyVoteCast(_proposalId, msg.sender, _voteFor);
    }

    /**
     * @dev Executes a policy proposal if it has passed the voting phase and met thresholds.
     *      Anyone can call this after the voting period ends.
     * @param _proposalId The ID of the policy proposal.
     */
    function executePolicyProposal(uint256 _proposalId) external whenNotPaused {
        PolicyProposal storage proposal = policyProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert InvalidState();
        if (block.timestamp <= proposal.endVoteTime) revert VotingPeriodNotActive();
        if (proposal.executed) revert InvalidState();

        // Determine if the proposal passed (simple majority for now)
        bool passed = proposal.totalVotesFor > proposal.totalVotesAgainst;

        // Unlock proposer's stake
        if (proposal.proposer != address(this) && proposal.proposer != aiOracleAddress) {
            userProfiles[proposal.proposer].totalVERITASStaked -= minProposalStake;
        }

        if (passed) {
            proposal.status = ProposalStatus.Succeeded;
            _executePolicyAction(proposal.executionType, proposal.executionData);
            proposal.executed = true;
            
            // Reward proposer with reputation
            _adjustReputation(proposal.proposer, reputationRewardForSuccess);

            // Return proposer's stake if it was a user proposal
            if (proposal.proposer != address(this) && proposal.proposer != aiOracleAddress) {
                userProfiles[proposal.proposer].earnedRewards += minProposalStake; // Add to claimable rewards
            }
        } else {
            proposal.status = ProposalStatus.Failed;
            _adjustReputation(proposal.proposer, -reputationPenaltyForFailure);
            // If the proposer's stake was held, it is conceptually "burned" or reallocated to a reward pool.
            // In this example, it stays in the contract.
        }

        emit PolicyProposalExecuted(_proposalId, proposal.executionType);
    }

    /**
     * @dev Internal function to execute the proposed action.
     * @param _executionType The type of execution.
     * @param _executionData The data for execution.
     */
    function _executePolicyAction(ExecutionType _executionType, bytes memory _executionData) internal {
        if (_executionType == ExecutionType.UpdateParameter) {
            (uint256 paramType, uint256 newValue) = abi.decode(_executionData, (uint256, uint256));
            if (paramType == uint256(ParameterType.MinKnowledgeStake)) minKnowledgeStake = newValue;
            else if (paramType == uint256(ParameterType.MinProposalStake)) minProposalStake = newValue;
            else if (paramType == uint256(ParameterType.MinChallengeStake)) minChallengeStake = newValue;
            else if (paramType == uint256(ParameterType.ProposalVotingPeriod)) proposalVotingPeriod = newValue;
            else if (paramType == uint256(ParameterType.ChallengeVotingPeriod)) challengeVotingPeriod = newValue;
            else if (paramType == uint256(ParameterType.MinReputationForProposing)) minReputationForProposing = newValue;
            else if (paramType == uint256(ParameterType.MinReputationForVoting)) minReputationForVoting = newValue;
            else if (paramType == uint256(ParameterType.ReputationRewardForSuccess)) reputationRewardForSuccess = newValue;
            else if (paramType == uint256(ParameterType.ReputationPenaltyForFailure)) reputationPenaltyForFailure = newValue;
            else revert InvalidExecutionType();
            emit ParametersUpdated(minKnowledgeStake, minProposalStake, minChallengeStake, proposalVotingPeriod, challengeVotingPeriod, minReputationForProposing, minReputationForVoting);
        } else if (_executionType == ExecutionType.ExternalCall) {
            (address target, bytes memory callData) = abi.decode(_executionData, (address, bytes));
            (bool success, ) = target.call(callData);
            if (!success) revert InvalidState(); // External call failed
        } else if (_executionType == ExecutionType.ModifyKnowledge) {
            (uint256 entryId, uint256 actionType, bytes memory actionData) = abi.decode(_executionData, (uint256, uint256, bytes));
            KnowledgeEntry storage entry = knowledgeEntries[entryId];
            if (entry.id == 0) revert KnowledgeEntryNotFound();

            if (actionType == uint256(KnowledgeActionType.UpdateTags)) {
                string[] memory newTags = abi.decode(actionData, (string[]));
                entry.tags = newTags;
                emit KnowledgeEntryTagsUpdated(entryId, newTags);
            } else if (actionType == uint256(KnowledgeActionType.SetActiveStatus)) {
                bool newStatus = abi.decode(actionData, (bool));
                entry.isActive = newStatus;
            } else if (actionType == uint256(KnowledgeActionType.AdjustCredibility)) {
                 int256 delta = abi.decode(actionData, (int256));
                 // Prevent credibility from going below zero, or having excessive jumps
                 if (int256(entry.credibilityScore) + delta < 0) entry.credibilityScore = 0;
                 else entry.credibilityScore = uint256(int256(entry.credibilityScore) + delta);
            } else {
                revert InvalidExecutionType();
            }
        } else if (_executionType == ExecutionType.None) {
            // No on-chain action, just a policy passed for informational purposes
        } else {
            revert InvalidExecutionType();
        }
    }

    /**
     * @dev Allows the proposer to cancel their policy proposal before voting ends,
     *      but only if no votes have been cast yet.
     * @param _proposalId The ID of the policy proposal to cancel.
     */
    function cancelPolicyProposal(uint256 _proposalId) external whenNotPaused {
        PolicyProposal storage proposal = policyProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.proposer != msg.sender) revert Unauthorized();
        if (proposal.status != ProposalStatus.Active) revert InvalidState();
        if (block.timestamp > proposal.startVoteTime) revert CannotCancelActiveProposal(); // Voting has already started
        if (proposal.totalVotesFor > 0 || proposal.totalVotesAgainst > 0) revert CannotCancelActiveProposal(); // Votes are cast

        proposal.status = ProposalStatus.Canceled;

        // Return proposer's stake
        userProfiles[proposal.proposer].totalVERITASStaked -= minProposalStake;
        userProfiles[proposal.proposer].earnedRewards += minProposalStake; // Add to claimable rewards

        emit PolicyProposalCanceled(_proposalId);
    }

    /**
     * IV. AI Oracle Interaction & Insights
     */

    /**
     * @dev AI Oracle provides an insight to update a knowledge entry's credibility.
     *      The AI must sign the message: `keccak256(abi.encodePacked(block.chainid, address(this), _entryId, _suggestedCredibilityScore, block.timestamp))`
     * @param _entryId The ID of the knowledge entry to update.
     * @param _suggestedCredibilityScore The new credibility score suggested by the AI.
     * @param _aiSignature The signature from the AI oracle.
     */
    function submitAIKnowledgeInsight(uint256 _entryId, uint256 _suggestedCredibilityScore, bytes memory _aiSignature) external onlyAIOracle whenNotPaused {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        if (entry.id == 0) revert KnowledgeEntryNotFound();

        // Reconstruct message hash for signature verification
        bytes32 messageHash = keccak256(abi.encodePacked(
            block.chainid,
            address(this),
            _entryId,
            _suggestedCredibilityScore,
            block.timestamp
        ));

        address signer = _recoverSigner(messageHash, _aiSignature);
        if (signer != aiOracleAddress) revert InvalidSignatureRecoveredAddress();

        entry.credibilityScore = _suggestedCredibilityScore;
        entry.lastUpdated = block.timestamp;
        emit AIInsightSubmitted(_entryId, _suggestedCredibilityScore, _aiSignature);
    }

    /**
     * @dev AI Oracle suggests an adjustment to a user's reputation score based on off-chain analysis.
     *      The AI must sign the message: `keccak256(abi.encodePacked(block.chainid, address(this), _user, _reputationDelta, block.timestamp))`
     * @param _user The address of the user whose reputation is to be adjusted.
     * @param _reputationDelta The amount to adjust the reputation by (can be positive or negative).
     * @param _aiSignature The signature from the AI oracle.
     */
    function submitAIReputationAdjustment(address _user, int256 _reputationDelta, bytes memory _aiSignature) external onlyAIOracle whenNotPaused {
        // Reconstruct message hash for signature verification
        bytes32 messageHash = keccak256(abi.encodePacked(
            block.chainid,
            address(this),
            _user,
            _reputationDelta,
            block.timestamp
        ));

        address signer = _recoverSigner(messageHash, _aiSignature);
        if (signer != aiOracleAddress) revert InvalidSignatureRecoveredAddress();

        _adjustReputation(_user, _reputationDelta);
        emit AIReputationAdjusted(_user, _reputationDelta, _aiSignature);
    }

    /**
     * V. Reputation & Rewards
     */

    /**
     * @dev Allows users to claim accumulated rewards from successful contributions, staking, and challenges.
     *      Rewards are managed internally by the contract and transferred to the user.
     */
    function claimRewards() external whenNotPaused {
        uint256 rewards = userProfiles[msg.sender].earnedRewards;
        if (rewards == 0) revert NoRewardsToClaim();

        userProfiles[msg.sender].earnedRewards = 0;
        _transferTokens(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Internal function to modify user reputation.
     * @param _user The address of the user.
     * @param _delta The amount to adjust reputation by (can be positive or negative).
     */
    function _adjustReputation(address _user, int252 _delta) internal {
        // Prevent integer overflow/underflow for reputation, keep it within reasonable bounds.
        // For simplicity, directly add/subtract.
        userProfiles[_user].reputationScore = userProfiles[_user].reputationScore + _delta;
        emit ReputationAdjusted(_user, userProfiles[_user].reputationScore);
    }

    /**
     * VI. View Functions
     */

    /**
     * @dev Retrieves details of a specific knowledge entry.
     * @param _entryId The ID of the knowledge entry.
     * @return KnowledgeEntry struct data.
     */
    function getKnowledgeEntry(uint256 _entryId) external view returns (KnowledgeEntry memory) {
        KnowledgeEntry memory entry = knowledgeEntries[_entryId];
        if (entry.id == 0) revert KnowledgeEntryNotFound();
        return entry;
    }

    /**
     * @dev Retrieves details of a specific policy proposal.
     * @param _proposalId The ID of the policy proposal.
     * @return PolicyProposal struct data.
     */
    function getPolicyProposal(uint256 _proposalId) external view returns (PolicyProposal memory) {
        PolicyProposal memory proposal = policyProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        return proposal;
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (int256) {
        return userProfiles[_user].reputationScore;
    }

    /**
     * @dev Retrieves a user's current total staked VERITAS tokens (across all purposes).
     * @param _user The address of the user.
     * @return The user's total staked amount.
     */
    function getUserTotalStaked(address _user) external view returns (uint256) {
        return userProfiles[_user].totalVERITASStaked;
    }

    /**
     * @dev Retrieves the amount a specific user has staked on a specific knowledge entry.
     * @param _entryId The ID of the knowledge entry.
     * @param _user The address of the user.
     * @return The amount staked by the user on the entry.
     */
    function getUserStakeOnKnowledge(uint256 _entryId, address _user) external view returns (uint256) {
        return userStakesOnKnowledge[_entryId][_user];
    }


    /**
     * Internal Utility Functions
     */

    /**
     * @dev Internal function to handle token transfers into the contract for staking.
     * @param _from The address from which to transfer tokens.
     * @param _entryId The knowledge entry ID (for tracking individual stakes).
     * @param _amount The amount of VERITAS_TOKEN to stake.
     */
    function _stakeTokens(address _from, uint256 _entryId, uint256 _amount) internal {
        // This assumes the `_from` address has already approved this contract to spend `_amount` tokens.
        VERITAS_TOKEN.transferFrom(_from, address(this), _amount);
        userStakesOnKnowledge[_entryId][_from] += _amount;
    }

    /**
     * @dev Internal function to handle token transfers out of the contract.
     * @param _to The address to which to transfer tokens.
     * @param _amount The amount of VERITAS_TOKEN to transfer.
     */
    function _transferTokens(address _to, uint256 _amount) internal {
        // Ensure the contract has enough balance
        if (VERITAS_TOKEN.balanceOf(address(this)) < _amount) revert InsufficientStake(); // Or more specific error like InsufficientContractBalance
        VERITAS_TOKEN.transfer(_to, _amount);
    }

    /**
     * @dev Recovers the signer's address from a message hash and signature.
     *      The message hash should be prefixed with "\x19Ethereum Signed Message:\n32" before signing by the off-chain entity.
     * @param _messageHash The hash of the message that was signed.
     * @param _signature The signature generated by the signer.
     * @return The address of the signer.
     */
    function _recoverSigner(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Splits an Ethereum signature into its r, s, and v components.
     * @param _signature The concatenated R, S, and V values.
     * @return r, s, v as bytes32, bytes32, uint8.
     */
    function _splitSignature(bytes memory _signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_signature.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 95)))
        }
        return (r, s, v);
    }
}
```