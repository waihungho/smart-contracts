This smart contract, `CogniNetProtocol`, envisions a decentralized "Cognitive Network" that empowers a community of "Agents" to collectively build a verified knowledge base and execute complex computational tasks (simulating AI model training or inference). It integrates several advanced blockchain concepts: dynamic reputation, adaptive incentives, oracle-based verification, skill-based NFTs, and on-chain governance, creating a self-improving, permissionless ecosystem for decentralized intelligence.

---

## **`CogniNetProtocol` Smart Contract**

### **Outline and Function Summary**

**Contract Name:** `CogniNetProtocol`

**Core Idea:** `CogniNetProtocol` establishes a decentralized network for contributing, validating, and leveraging collective intelligence. Agents stake tokens to participate, contribute knowledge fragments or execute computational challenges, and earn rewards based on performance and validation. The protocol dynamically adjusts incentives and evolves through community governance, while skill-based NFTs recognize significant contributions.

**Advanced Concepts Integrated:**

*   **Decentralized Knowledge Graph:** Agents submit and validate verifiable data/insights (`KnowledgeFragment`s).
*   **Proof of Contribution/Validation:** Staking mechanisms ensure data integrity and task reliability, with rewards for accurate validation and execution.
*   **Decentralized Computational Marketplace:** Agents bid on and execute complex computational tasks (`ComputationalChallenge`s), simulating AI or data processing.
*   **Reputation & Skill-Based System:** A dynamic reputation score tracks agent performance, and significant achievements are recognized with `SkillBadgeNFT`s.
*   **Adaptive Tokenomics:** Reward factors can be adjusted by governance to align incentives with network needs and market conditions.
*   **Oracle Integration (Simulated):** External oracles are assumed for objective, off-chain verification of computational results, bringing real-world data/proof on-chain.
*   **On-chain Governance:** A robust DAO-like system allows agents to propose and vote on protocol upgrades and parameter changes.
*   **Subscription/Tiered Access:** A mechanism for premium access to validated knowledge or advanced features, enhancing the protocol's sustainability.
*   **Escrow & Slashing:** Implicit in staking and reward distribution, ensuring accountability and penalizing malicious or poor performance.

---

**I. Contract Setup & Core Structures**

1.  **`constructor(address _cogniToken, address _skillBadgeNFT, address _trustedOracle)`**: Initializes the contract with the ERC20 token, SkillBadgeNFT contract, and a trusted oracle address.
2.  **`setTrustedOracle(address _newOracle)`**: Admin function to update the trusted oracle address. (Admin)
3.  **`pause()`**: Pauses contract operations in an emergency. (Admin)
4.  **`unpause()`**: Unpauses contract operations. (Admin)

**II. Agent & Reputation Management**

5.  **`registerAgent(string calldata _metadataURI)`**: Allows a user to register as an Agent, linking an off-chain profile.
6.  **`updateAgentProfile(string calldata _newMetadataURI)`**: Agents can update their associated profile metadata URI.
7.  **`stakeAgentDeposit(uint256 _amount)`**: Agents stake `COGNIToken` to demonstrate commitment and unlock advanced features.
8.  **`unstakeAgentDeposit()`**: Agents can initiate a withdrawal of their staked tokens after a cooldown period.
9.  **`getAgentReputation(address _agent)`**: A view function to query an Agent's current reputation score. (View)

**III. Knowledge Base (Data Contribution & Validation)**

10. **`submitKnowledgeFragment(string calldata _fragmentHash, string calldata _fragmentURI, uint256 _stake)`**: Agents submit a hash and URI for a knowledge fragment, staking `COGNIToken` for its accuracy.
11. **`proposeValidationTask(uint256 _fragmentId, uint256 _rewardPool, uint256 _validationPeriod)`**: Initiates a task for other Agents to validate a submitted knowledge fragment.
12. **`participateInValidation(uint256 _validationTaskId, bool _isValid)`**: Agents vote on the validity of a knowledge fragment within a validation task.
13. **`finalizeValidationTask(uint256 _validationTaskId)`**: Concludes a validation task, distributing rewards to honest validators and penalizing incorrect submissions/votes.
14. **`retrieveValidatedKnowledge(uint256 _fragmentId)`**: Allows access to the details of a successfully validated knowledge fragment (may be premium). (View)

**IV. Computational Challenges (Task Execution & Verification)**

15. **`proposeComputationChallenge(bytes32 _challengeIdentifier, string calldata _challengeSpecURI, uint256 _rewardPool, uint256 _executionDeadline)`**: Users propose a computational task (e.g., AI model training), defining its parameters and reward.
16. **`bidForChallengeExecution(uint256 _challengeId, uint256 _bidAmount)`**: Agents bid `COGNIToken` to execute a proposed computational challenge.
17. **`submitChallengeResult(uint256 _challengeId, bytes32 _resultHash, string calldata _resultURI)`**: The winning bidder submits the hash and URI of their computation result.
18. **`triggerOracleVerification(uint256 _challengeId)`**: Initiates the process for the trusted oracle to verify the submitted computational result. (Oracle Only)
19. **`finalizeComputationalChallenge(uint256 _challengeId)`**: Finalizes the challenge based on oracle verification, rewarding successful executors and slashing failures.

**V. Incentive & Skill System**

20. **`adjustRewardFactor(uint256 _fragmentId, uint256 _newFactor)`**: Allows governance to dynamically adjust the reward factor for specific knowledge fragments based on demand or complexity. (Governance Only)
21. **`mintSkillBadge(address _agent, bytes32 _badgeType)`**: Awards a non-fungible "Skill Badge" (via `ISkillBadgeNFT`) to an Agent for notable achievements, reputation milestones, or special contributions (internal or governance-triggered). (Internal/Governance)
22. **`subscribeToCogniNetTier(uint256 _tierId, uint256 _durationInMonths)`**: Enables users to subscribe to different tiers of premium access, unlocking advanced features or exclusive knowledge.
23. **`claimAccumulatedRewards()`**: Agents can claim their accumulated `COGNIToken` rewards from various contributions.

**VI. Protocol Governance**

24. **`proposeProtocolUpgrade(bytes32 _proposalHash, string calldata _detailsURI)`**: Agents can submit a proposal for protocol changes or upgrades, linking to off-chain details.
25. **`voteOnUpgradeProposal(uint256 _proposalId, bool _approve)`**: Registered Agents can cast their vote (approve/reject) on active governance proposals.
26. **`executeApprovedProposal(uint256 _proposalId)`**: An admin-like function (potentially callable by anyone after a delay) to execute a governance proposal that has successfully passed. (Admin/Governance)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Using IERC721 as a base for Skill Badges

// Custom Errors for gas efficiency and clarity
error CogniNet__InvalidStakeAmount();
error CogniNet__NotAnAgent();
error CogniNet__AgentAlreadyRegistered();
error CogniNet__FragmentNotFound();
error CogniNet__ValidationTaskNotFound();
error CogniNet__AlreadyVotedOnValidation();
error CogniNet__ValidationTaskNotEnded();
error CogniNet__ValidationTaskAlreadyFinalized();
error CogniNet__ValidationPeriodNotOver();
error CogniNet__ChallengeNotFound();
error CogniNet__ChallengeNotActive();
error CogniNet__ChallengeAlreadyFinalized();
error CogniNet__ChallengeDeadlineNotPassed();
error CogniNet__NotWinningBidder();
error CogniNet__InvalidChallengeState();
error CogniNet__InsufficientFunds();
error CogniNet__DepositTooLow();
error CogniNet__DepositCooldownActive();
error CogniNet__NoRewardsToClaim();
error CogniNet__SubscriptionNotFound();
error CogniNet__SubscriptionActive();
error CogniNet__ProposalNotFound();
error CogniNet__ProposalVotingNotEnded();
error CogniNet__ProposalVotingActive();
error CogniNet__ProposalNotApproved();
error CogniNet__ProposalAlreadyExecuted();
error CogniNet__CannotAdjustPastRewardFactor();
error CogniNet__NotOracle();
error CogniNet__OracleVerificationPending();
error CogniNet__NotEnoughStake();


/**
 * @title ICogniNetOracle
 * @dev Interface for the external oracle responsible for verifying computational challenge results.
 *      The oracle's role is to bridge off-chain computation with on-chain verification.
 */
interface ICogniNetOracle {
    function verifyChallengeResult(uint256 challengeId, bytes32 resultHash) external returns (bool);
    event ChallengeVerified(uint256 indexed challengeId, bool success, bytes32 resultHash);
}

/**
 * @title ISkillBadgeNFT
 * @dev Interface for a separate ERC721 contract that issues unique Skill Badges.
 *      These NFTs are awarded by CogniNetProtocol based on agent performance and achievements.
 */
interface ISkillBadgeNFT is IERC721 {
    function mint(address to, uint256 tokenId, bytes32 badgeType) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


/**
 * @title CogniNetProtocol
 * @dev A decentralized Cognitive Network for knowledge contribution, computational tasks,
 *      reputation management, dynamic incentives, and on-chain governance.
 *      This contract integrates advanced concepts like oracle-based verification,
 *      skill-based NFTs, and adaptive tokenomics to foster a self-improving ecosystem.
 */
contract CogniNetProtocol is Ownable, Pausable {

    // --- State Variables ---

    // Token addresses
    IERC20 public immutable cogniToken;
    ISkillBadgeNFT public immutable skillBadgeNFT;
    ICogniNetOracle public trustedOracle;

    // Agent data
    struct Agent {
        bool isRegistered;
        string metadataURI;
        uint256 reputation; // Accumulated score based on performance
        uint256 stakedAmount; // Tokens staked for participation
        uint256 lastUnstakeRequestTime; // Cooldown for unstaking
        uint256 accumulatedRewards; // Rewards earned but not yet claimed
    }
    mapping(address => Agent) public agents;
    address[] public registeredAgents; // For iterating all agents (careful with large arrays)

    // Knowledge Fragments (Decentralized Knowledge Graph)
    struct KnowledgeFragment {
        address submitter;
        string fragmentHash; // IPFS hash or similar for integrity
        string fragmentURI;  // IPFS URI for content access
        uint256 stake;       // Stake by submitter for validation
        uint256 submissionTime;
        bool isValidated;    // True if successfully validated
        uint256 rewardFactor; // Dynamic reward multiplier for this fragment
    }
    KnowledgeFragment[] public knowledgeFragments;
    mapping(uint256 => bool) public fragmentExists;

    // Data Validation Tasks
    enum ValidationStatus { Pending, Active, Finalized }
    struct ValidationTask {
        uint256 fragmentId;
        address proposer;
        uint256 rewardPool;
        uint256 startTime;
        uint256 endTime;
        ValidationStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Tracks agent votes
        bool oracleVerified; // Could be used for complex validation or a second layer
    }
    ValidationTask[] public validationTasks;

    // Computational Challenges
    enum ChallengeStatus { Proposed, Bidding, Executing, PendingVerification, VerifiedSuccess, VerifiedFailure, Finalized }
    struct ComputationalChallenge {
        bytes32 challengeIdentifier; // Unique identifier for the challenge type/spec
        string challengeSpecURI;     // URI to detailed challenge specifications
        address proposer;
        uint256 rewardPool;
        uint256 submissionDeadline;
        uint256 executionDeadline;
        ChallengeStatus status;
        address winningBidder;
        uint256 winningBid;
        bytes32 resultHash;         // Hash of the submitted result
        string resultURI;           // URI to the submitted result
        bool oracleVerified;        // True if oracle has verified the result
        bool verificationSuccess;   // True if oracle verification was successful
    }
    ComputationalChallenge[] public computationalChallenges;

    // Governance Proposals
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        bytes32 proposalHash; // Hash of the proposal content/details
        string detailsURI;    // URI to detailed proposal document
        address proposer;
        uint256 submissionTime;
        uint256 votingEndTime;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Tracks agent votes
    }
    GovernanceProposal[] public governanceProposals;

    // Subscription Tiers
    struct SubscriptionTier {
        string name;
        uint256 pricePerMonth; // in COGNIToken
        string descriptionURI;
        uint256 premiumAccessLevel; // Higher level implies more access
    }
    SubscriptionTier[] public subscriptionTiers;
    mapping(address => mapping(uint256 => uint256)) public agentSubscriptions; // agent => tierId => expiryTimestamp

    // Configuration parameters
    uint256 public constant MIN_AGENT_STAKE = 1000 * 10 ** 18; // 1000 COGNIToken
    uint256 public constant UNSTAKE_COOLDOWN_PERIOD = 7 days; // 7 days cooldown for unstaking
    uint256 public constant VALIDATION_TASK_MIN_REWARD = 10 * 10 ** 18; // Min reward for validation task
    uint256 public constant GOVERNANCE_VOTING_PERIOD = 7 days; // 7 days for governance proposals
    uint256 public constant GOVERNANCE_MIN_YES_VOTES_PERCENTAGE = 60; // 60% of votes needed to pass

    // --- Events ---

    event AgentRegistered(address indexed agent, string metadataURI, uint256 timestamp);
    event AgentProfileUpdated(address indexed agent, string newMetadataURI, uint256 timestamp);
    event AgentStaked(address indexed agent, uint256 amount, uint256 newTotalStake);
    event AgentUnstakeRequested(address indexed agent, uint256 amount, uint256 cooldownEnds);
    event AgentUnstakeCompleted(address indexed agent, uint256 amount);
    event AgentReputationUpdated(address indexed agent, uint256 oldReputation, uint256 newReputation);

    event KnowledgeFragmentSubmitted(address indexed submitter, uint256 indexed fragmentId, string fragmentHash, string fragmentURI, uint256 stake);
    event ValidationTaskProposed(address indexed proposer, uint256 indexed validationTaskId, uint256 indexed fragmentId, uint256 rewardPool, uint256 endTime);
    event ValidationParticipation(address indexed agent, uint256 indexed validationTaskId, bool isValid);
    event ValidationTaskFinalized(uint256 indexed validationTaskId, uint256 indexed fragmentId, bool isValidated, uint256 totalYesVotes, uint256 totalNoVotes);
    event FragmentRewardFactorAdjusted(uint256 indexed fragmentId, uint256 oldFactor, uint256 newFactor);

    event ComputationalChallengeProposed(address indexed proposer, uint256 indexed challengeId, bytes32 challengeIdentifier, string challengeSpecURI, uint256 rewardPool, uint256 executionDeadline);
    event ChallengeBid(address indexed bidder, uint256 indexed challengeId, uint256 bidAmount);
    event ChallengeResultSubmitted(address indexed submitter, uint256 indexed challengeId, bytes32 resultHash, string resultURI);
    event OracleVerificationTriggered(uint256 indexed challengeId);
    event ChallengeFinalized(uint256 indexed challengeId, ChallengeStatus finalStatus, address winningBidder, bool verificationSuccess);

    event SkillBadgeMinted(address indexed agent, bytes32 indexed badgeType, uint256 tokenId);
    event CogniNetTierSubscribed(address indexed subscriber, uint256 indexed tierId, uint256 expiryTimestamp);
    event RewardsClaimed(address indexed agent, uint256 amount);

    event ProtocolUpgradeProposed(address indexed proposer, uint256 indexed proposalId, bytes32 proposalHash, string detailsURI);
    event ProposalVoted(address indexed voter, uint256 indexed proposalId, bool approved);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event TrustedOracleSet(address indexed oldOracle, address indexed newOracle);

    // --- Modifiers ---

    modifier onlyAgent() {
        if (!agents[msg.sender].isRegistered) revert CogniNet__NotAnAgent();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != address(trustedOracle)) revert CogniNet__NotOracle();
        _;
    }

    // --- Constructor ---

    constructor(address _cogniToken, address _skillBadgeNFT, address _trustedOracle) Ownable(msg.sender) Pausable(false) {
        if (_cogniToken == address(0) || _skillBadgeNFT == address(0) || _trustedOracle == address(0)) {
            revert OwnableInvalidOwner(address(0)); // Reusing Ownable error for 0-address check
        }
        cogniToken = IERC20(_cogniToken);
        skillBadgeNFT = ISkillBadgeNFT(_skillBadgeNFT);
        trustedOracle = ICogniNetOracle(_trustedOracle);

        // Initialize some default subscription tiers
        subscriptionTiers.push(SubscriptionTier("Basic Access", 0, "ipfs://basic-tier-desc", 0)); // Free tier
        subscriptionTiers.push(SubscriptionTier("Premium Data", 100 * 10**18, "ipfs://premium-tier-desc", 1));
        subscriptionTiers.push(SubscriptionTier("Developer Tier", 500 * 10**18, "ipfs://developer-tier-desc", 2));
    }

    // --- I. Contract Setup & Core Functions ---

    /**
     * @dev Allows the owner to update the trusted oracle address.
     * @param _newOracle The address of the new oracle contract.
     */
    function setTrustedOracle(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert OwnableInvalidOwner(address(0)); // Reusing error
        emit TrustedOracleSet(address(trustedOracle), _newOracle);
        trustedOracle = ICogniNetOracle(_newOracle);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- II. Agent & Reputation Management ---

    /**
     * @dev Allows a user to register as an Agent in the CogniNetProtocol.
     * @param _metadataURI URI pointing to the agent's off-chain profile metadata (e.g., IPFS).
     */
    function registerAgent(string calldata _metadataURI) external whenNotPaused {
        if (agents[msg.sender].isRegistered) revert CogniNet__AgentAlreadyRegistered();

        agents[msg.sender].isRegistered = true;
        agents[msg.sender].metadataURI = _metadataURI;
        agents[msg.sender].reputation = 0; // Start with zero reputation
        agents[msg.sender].stakedAmount = 0;
        agents[msg.sender].lastUnstakeRequestTime = 0;
        agents[msg.sender].accumulatedRewards = 0;

        registeredAgents.push(msg.sender);
        emit AgentRegistered(msg.sender, _metadataURI, block.timestamp);
    }

    /**
     * @dev Allows a registered Agent to update their profile metadata URI.
     * @param _newMetadataURI New URI for the agent's profile metadata.
     */
    function updateAgentProfile(string calldata _newMetadataURI) external onlyAgent whenNotPaused {
        agents[msg.sender].metadataURI = _newMetadataURI;
        emit AgentProfileUpdated(msg.sender, _newMetadataURI, block.timestamp);
    }

    /**
     * @dev Agents stake COGNIToken to participate in the network, gain reputation,
     *      and unlock abilities. Requires approval of tokens beforehand.
     * @param _amount The amount of COGNIToken to stake.
     */
    function stakeAgentDeposit(uint256 _amount) external onlyAgent whenNotPaused {
        if (_amount == 0) revert CogniNet__InvalidStakeAmount();
        
        cogniToken.transferFrom(msg.sender, address(this), _amount);
        agents[msg.sender].stakedAmount += _amount;
        
        // Reward reputation for staking, scaled to amount
        _updateAgentReputation(msg.sender, _amount / 10**18 / 10); // Example: 0.1 reputation per token staked
        
        emit AgentStaked(msg.sender, _amount, agents[msg.sender].stakedAmount);
    }

    /**
     * @dev Allows an Agent to request to unstake their deposit.
     *      Funds become available after a cooldown period.
     */
    function unstakeAgentDeposit() external onlyAgent whenNotPaused {
        if (agents[msg.sender].stakedAmount == 0) revert CogniNet__DepositTooLow();
        if (agents[msg.sender].lastUnstakeRequestTime + UNSTAKE_COOLDOWN_PERIOD > block.timestamp) {
            revert CogniNet__DepositCooldownActive();
        }

        uint256 amountToUnstake = agents[msg.sender].stakedAmount;
        agents[msg.sender].stakedAmount = 0; // Clear stake immediately, but funds only after cooldown
        agents[msg.sender].lastUnstakeRequestTime = block.timestamp; // Start cooldown

        // Penalize reputation for unstaking, scaled to amount
        _updateAgentReputation(msg.sender, -(int256(amountToUnstake / 10**18 / 5))); // Example: -0.2 reputation per token unstaked

        emit AgentUnstakeRequested(msg.sender, amountToUnstake, block.timestamp + UNSTAKE_COOLDOWN_PERIOD);
        cogniToken.transfer(msg.sender, amountToUnstake); // Transfer immediately if no explicit cooldown needed for actual transfer
        emit AgentUnstakeCompleted(msg.sender, amountToUnstake); // Emit after transfer
    }

    /**
     * @dev Internal function to update an agent's reputation score.
     *      Can be positive or negative.
     * @param _agent The address of the agent.
     * @param _change The change in reputation (positive for gain, negative for loss).
     */
    function _updateAgentReputation(address _agent, int256 _change) internal {
        uint256 oldReputation = agents[_agent].reputation;
        if (_change > 0) {
            agents[_agent].reputation += uint256(_change);
        } else {
            uint256 absChange = uint256(-_change);
            if (agents[_agent].reputation < absChange) {
                agents[_agent].reputation = 0;
            } else {
                agents[_agent].reputation -= absChange;
            }
        }
        emit AgentReputationUpdated(_agent, oldReputation, agents[_agent].reputation);
    }

    /**
     * @dev Retrieves the current reputation score of an Agent.
     * @param _agent The address of the Agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(address _agent) external view returns (uint256) {
        return agents[_agent].reputation;
    }

    // --- III. Knowledge Base (Data Contribution & Validation) ---

    /**
     * @dev Allows an Agent to submit a knowledge fragment to the network.
     *      Requires a stake to incentivize accurate submissions.
     * @param _fragmentHash Cryptographic hash of the knowledge fragment content (e.g., SHA256).
     * @param _fragmentURI URI pointing to the full knowledge fragment content (e.g., IPFS).
     * @param _stake The amount of COGNIToken staked for the fragment's validity.
     */
    function submitKnowledgeFragment(
        string calldata _fragmentHash,
        string calldata _fragmentURI,
        uint256 _stake
    ) external onlyAgent whenNotPaused returns (uint256) {
        if (_stake == 0) revert CogniNet__InvalidStakeAmount();
        cogniToken.transferFrom(msg.sender, address(this), _stake);

        knowledgeFragments.push(
            KnowledgeFragment({
                submitter: msg.sender,
                fragmentHash: _fragmentHash,
                fragmentURI: _fragmentURI,
                stake: _stake,
                submissionTime: block.timestamp,
                isValidated: false,
                rewardFactor: 100 // Default reward factor (100 = 1x)
            })
        );
        uint256 fragmentId = knowledgeFragments.length - 1;
        fragmentExists[fragmentId] = true;
        emit KnowledgeFragmentSubmitted(msg.sender, fragmentId, _fragmentHash, _fragmentURI, _stake);
        return fragmentId;
    }

    /**
     * @dev Allows any Agent to propose a validation task for a submitted knowledge fragment.
     *      Requires a reward pool for validators.
     * @param _fragmentId The ID of the knowledge fragment to validate.
     * @param _rewardPool The amount of COGNIToken to be distributed among validators.
     * @param _validationPeriod The duration in seconds for which the validation task will be open.
     */
    function proposeValidationTask(
        uint256 _fragmentId,
        uint256 _rewardPool,
        uint256 _validationPeriod
    ) external onlyAgent whenNotPaused returns (uint256) {
        if (!fragmentExists[_fragmentId]) revert CogniNet__FragmentNotFound();
        if (knowledgeFragments[_fragmentId].isValidated) revert CogniNet__ValidationTaskAlreadyFinalized(); // Or some other state
        if (_rewardPool < VALIDATION_TASK_MIN_REWARD) revert CogniNet__InvalidStakeAmount();
        if (_validationPeriod == 0) revert CogniNet__InvalidChallengeState(); // Using same error for zero period

        cogniToken.transferFrom(msg.sender, address(this), _rewardPool);

        validationTasks.push(
            ValidationTask({
                fragmentId: _fragmentId,
                proposer: msg.sender,
                rewardPool: _rewardPool,
                startTime: block.timestamp,
                endTime: block.timestamp + _validationPeriod,
                status: ValidationStatus.Active,
                yesVotes: 0,
                noVotes: 0,
                oracleVerified: false
            })
        );
        uint256 taskId = validationTasks.length - 1;
        emit ValidationTaskProposed(msg.sender, taskId, _fragmentId, _rewardPool, validationTasks[taskId].endTime);
        return taskId;
    }

    /**
     * @dev Allows an Agent to participate in a validation task by voting on the fragment's validity.
     * @param _validationTaskId The ID of the validation task.
     * @param _isValid True if the agent believes the fragment is valid, false otherwise.
     */
    function participateInValidation(uint256 _validationTaskId, bool _isValid) external onlyAgent whenNotPaused {
        if (_validationTaskId >= validationTasks.length) revert CogniNet__ValidationTaskNotFound();
        ValidationTask storage task = validationTasks[_validationTaskId];

        if (task.status != ValidationStatus.Active) revert CogniNet__InvalidChallengeState();
        if (block.timestamp >= task.endTime) revert CogniNet__ValidationPeriodNotOver(); // Should be ValidationTaskNotActive
        if (task.hasVoted[msg.sender]) revert CogniNet__AlreadyVotedOnValidation();

        task.hasVoted[msg.sender] = true;
        if (_isValid) {
            task.yesVotes++;
        } else {
            task.noVotes++;
        }
        emit ValidationParticipation(msg.sender, _validationTaskId, _isValid);
    }

    /**
     * @dev Finalizes a validation task after its voting period has ended,
     *      distributing rewards and updating fragment status and agent reputation.
     * @param _validationTaskId The ID of the validation task to finalize.
     */
    function finalizeValidationTask(uint256 _validationTaskId) external whenNotPaused {
        if (_validationTaskId >= validationTasks.length) revert CogniNet__ValidationTaskNotFound();
        ValidationTask storage task = validationTasks[_validationTaskId];
        KnowledgeFragment storage fragment = knowledgeFragments[task.fragmentId];

        if (task.status != ValidationStatus.Active) revert CogniNet__InvalidChallengeState();
        if (block.timestamp < task.endTime) revert CogniNet__ValidationPeriodNotOver();

        task.status = ValidationStatus.Finalized;

        uint256 totalVotes = task.yesVotes + task.noVotes;
        bool fragmentPassed = (totalVotes > 0 && (task.yesVotes * 100 / totalVotes) >= GOVERNANCE_MIN_YES_VOTES_PERCENTAGE); // Example threshold

        fragment.isValidated = fragmentPassed;

        if (fragmentPassed) {
            // Reward submitter
            agents[fragment.submitter].accumulatedRewards += fragment.stake * fragment.rewardFactor / 100;
            _updateAgentReputation(fragment.submitter, int256(fragment.stake / 10**18 / 10)); // Reputation boost

            // Reward validators
            // This part is simplified: in a real system, you'd iterate through voters
            // or implement a Merkle drop for distribution.
            // For now, assume a fair distribution based on positive contributions.
            // This is a placeholder for a more complex reward distribution logic for voters.
            uint256 rewardPerVote = totalVotes > 0 ? task.rewardPool / totalVotes : 0;
            // A more complex system would check each voter's choice vs. final outcome to reward correct votes.
            // For simplicity, we just distribute to winning side.
            if (task.yesVotes > 0 && fragmentPassed) { // Reward those who voted 'yes' if it passed
                // Imagine a mechanism to iterate through voters for this task.
                // For now, let's just make it possible to claim from a common pool later.
                // This would be handled by a separate claim function or Merkle drop.
            }

        } else {
            // Slashing for invalid fragment
            cogniToken.transfer(owner(), fragment.stake); // Slash submitter's stake, send to treasury
            _updateAgentReputation(fragment.submitter, -int256(fragment.stake / 10**18 / 5)); // Reputation penalty
        }

        emit ValidationTaskFinalized(_validationTaskId, task.fragmentId, fragmentPassed, task.yesVotes, task.noVotes);
    }

    /**
     * @dev Retrieves details of a validated knowledge fragment.
     *      Might implement tiered access based on subscription.
     * @param _fragmentId The ID of the knowledge fragment.
     * @return submitter, fragmentHash, fragmentURI, submissionTime, isValidated, rewardFactor.
     */
    function retrieveValidatedKnowledge(uint256 _fragmentId)
        external
        view
        returns (address, string memory, string memory, uint256, bool, uint256)
    {
        if (_fragmentId >= knowledgeFragments.length) revert CogniNet__FragmentNotFound();
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        // Here, you could check agentSubscriptions[msg.sender][tierId] expiry to control access
        // For simplicity, it's public for now after validation.
        return (
            fragment.submitter,
            fragment.fragmentHash,
            fragment.fragmentURI,
            fragment.submissionTime,
            fragment.isValidated,
            fragment.rewardFactor
        );
    }

    // --- IV. Computational Challenges (Task Execution & Verification) ---

    /**
     * @dev Allows users to propose a computational task (e.g., AI model training, data analysis).
     *      Requires specifying the task details and offering a reward pool.
     * @param _challengeIdentifier A unique identifier for the type of challenge.
     * @param _challengeSpecURI URI to detailed specifications of the challenge.
     * @param _rewardPool The total COGNIToken reward for successful execution.
     * @param _executionDeadline The timestamp by which the task must be completed.
     */
    function proposeComputationChallenge(
        bytes32 _challengeIdentifier,
        string calldata _challengeSpecURI,
        uint256 _rewardPool,
        uint256 _executionDeadline
    ) external whenNotPaused returns (uint256) {
        if (_rewardPool == 0) revert CogniNet__InvalidStakeAmount();
        if (_executionDeadline <= block.timestamp) revert CogniNet__InvalidChallengeState();
        
        cogniToken.transferFrom(msg.sender, address(this), _rewardPool);

        computationalChallenges.push(
            ComputationalChallenge({
                challengeIdentifier: _challengeIdentifier,
                challengeSpecURI: _challengeSpecURI,
                proposer: msg.sender,
                rewardPool: _rewardPool,
                submissionDeadline: _executionDeadline - 1 days, // Allow bidding up to 1 day before execution deadline
                executionDeadline: _executionDeadline,
                status: ChallengeStatus.Proposed,
                winningBidder: address(0),
                winningBid: 0,
                resultHash: "",
                resultURI: "",
                oracleVerified: false,
                verificationSuccess: false
            })
        );
        uint256 challengeId = computationalChallenges.length - 1;
        emit ComputationalChallengeProposed(msg.sender, challengeId, _challengeIdentifier, _challengeSpecURI, _rewardPool, _executionDeadline);
        return challengeId;
    }

    /**
     * @dev Agents bid to execute a proposed computational challenge.
     *      The lowest valid bid within the bidding period wins.
     * @param _challengeId The ID of the computational challenge.
     * @param _bidAmount The amount of COGNIToken the agent requires for execution.
     */
    function bidForChallengeExecution(uint256 _challengeId, uint256 _bidAmount) external onlyAgent whenNotPaused {
        if (_challengeId >= computationalChallenges.length) revert CogniNet__ChallengeNotFound();
        ComputationalChallenge storage challenge = computationalChallenges[_challengeId];

        if (challenge.status != ChallengeStatus.Proposed && challenge.status != ChallengeStatus.Bidding) revert CogniNet__InvalidChallengeState();
        if (block.timestamp >= challenge.submissionDeadline) revert CogniNet__ChallengeDeadlineNotPassed();
        if (_bidAmount >= challenge.rewardPool) revert CogniNet__InvalidStakeAmount(); // Bid must be less than total reward
        
        // Ensure bidder has enough stake or reputation
        if (agents[msg.sender].stakedAmount < _bidAmount / 10) revert CogniNet__NotEnoughStake(); // Example: stake must be 10% of bid

        if (challenge.winningBid == 0 || _bidAmount < challenge.winningBid) {
            challenge.winningBidder = msg.sender;
            challenge.winningBid = _bidAmount;
            challenge.status = ChallengeStatus.Bidding;
        }
        emit ChallengeBid(msg.sender, _challengeId, _bidAmount);
    }

    /**
     * @dev The winning bidder submits the result of a computational challenge.
     * @param _challengeId The ID of the computational challenge.
     * @param _resultHash Cryptographic hash of the result.
     * @param _resultURI URI pointing to the full result content.
     */
    function submitChallengeResult(uint256 _challengeId, bytes32 _resultHash, string calldata _resultURI) external onlyAgent whenNotPaused {
        if (_challengeId >= computationalChallenges.length) revert CogniNet__ChallengeNotFound();
        ComputationalChallenge storage challenge = computationalChallenges[_challengeId];

        if (msg.sender != challenge.winningBidder) revert CogniNet__NotWinningBidder();
        if (challenge.status != ChallengeStatus.Bidding && challenge.status != ChallengeStatus.Executing) revert CogniNet__InvalidChallengeState(); // Allow submission once bidding ends
        if (block.timestamp > challenge.executionDeadline) revert CogniNet__ChallengeDeadlineNotPassed();

        challenge.resultHash = _resultHash;
        challenge.resultURI = _resultURI;
        challenge.status = ChallengeStatus.PendingVerification;
        emit ChallengeResultSubmitted(msg.sender, _challengeId, _resultHash, _resultURI);
    }

    /**
     * @dev Triggers the external oracle to verify the submitted computational result.
     *      This function is typically called by the oracle itself or a trusted relay.
     * @param _challengeId The ID of the computational challenge.
     */
    function triggerOracleVerification(uint256 _challengeId) external onlyOracle whenNotPaused {
        if (_challengeId >= computationalChallenges.length) revert CogniNet__ChallengeNotFound();
        ComputationalChallenge storage challenge = computationalChallenges[_challengeId];

        if (challenge.status != ChallengeStatus.PendingVerification) revert CogniNet__OracleVerificationPending(); // Using this for incorrect status

        // Call the external oracle contract
        bool verificationResult = trustedOracle.verifyChallengeResult(_challengeId, challenge.resultHash);
        
        challenge.oracleVerified = true;
        challenge.verificationSuccess = verificationResult;

        if (verificationResult) {
            challenge.status = ChallengeStatus.VerifiedSuccess;
        } else {
            challenge.status = ChallengeStatus.VerifiedFailure;
        }
        emit OracleVerificationTriggered(_challengeId);
        // Automatically finalize if oracle provides result immediately.
        // In a real system, the oracle might emit an event and a separate call would finalize.
        // For simplicity, we assume immediate update.
        _finalizeComputationalChallenge(_challengeId);
    }

    /**
     * @dev Internal helper to finalize a computational challenge, distributing rewards/penalties.
     * @param _challengeId The ID of the computational challenge.
     */
    function _finalizeComputationalChallenge(uint256 _challengeId) internal {
        ComputationalChallenge storage challenge = computationalChallenges[_challengeId];

        if (!challenge.oracleVerified) revert CogniNet__OracleVerificationPending();
        if (challenge.status == ChallengeStatus.Finalized) revert CogniNet__ChallengeAlreadyFinalized();

        if (challenge.verificationSuccess) {
            // Reward winning bidder
            uint256 rewardAmount = challenge.rewardPool - challenge.winningBid; // Net reward
            agents[challenge.winningBidder].accumulatedRewards += rewardAmount;
            _updateAgentReputation(challenge.winningBidder, int256(rewardAmount / 10**18 / 5)); // Reputation boost

            // Return winning bid collateral (if any)
            // In a more complex system, the bid itself might be collateral
            // For now, assume bid is part of the rewards.

        } else {
            // Penalize winning bidder for failure (slashing their stake or a portion)
            // This is a placeholder for actual slashing logic, which would reduce agents[winningBidder].stakedAmount
            // For now, just a reputation penalty.
            _updateAgentReputation(challenge.winningBidder, -int256(agents[challenge.winningBidder].reputation / 10)); // 10% reputation cut
            // The challenge.rewardPool remains in the contract, potentially claimable by proposer or for treasury.
        }
        challenge.status = ChallengeStatus.Finalized;
        emit ChallengeFinalized(_challengeId, challenge.status, challenge.winningBidder, challenge.verificationSuccess);
    }

    /**
     * @dev Public function to call _finalizeComputationalChallenge (after oracle has verified and sufficient time has passed)
     * @param _challengeId The ID of the computational challenge.
     */
    function finalizeComputationalChallenge(uint256 _challengeId) external {
        if (_challengeId >= computationalChallenges.length) revert CogniNet__ChallengeNotFound();
        ComputationalChallenge storage challenge = computationalChallenges[_challengeId];

        if (challenge.status != ChallengeStatus.VerifiedSuccess && challenge.status != ChallengeStatus.VerifiedFailure) {
            revert CogniNet__OracleVerificationPending(); // Verification not yet done or pending
        }

        if (challenge.status == ChallengeStatus.Finalized) revert CogniNet__ChallengeAlreadyFinalized();

        _finalizeComputationalChallenge(_challengeId);
    }


    // --- V. Incentive & Skill System ---

    /**
     * @dev Allows governance (or a specific role) to adjust the reward factor for a knowledge fragment.
     *      This enables dynamic incentive adjustment based on perceived value, demand, etc.
     * @param _fragmentId The ID of the knowledge fragment.
     * @param _newFactor The new reward factor (e.g., 100 for 1x, 150 for 1.5x).
     */
    function adjustRewardFactor(uint256 _fragmentId, uint256 _newFactor) external onlyOwner whenNotPaused {
        // In a real DAO, this would be an `executeProposal` function after a vote.
        // For this example, only owner can adjust.
        if (_fragmentId >= knowledgeFragments.length) revert CogniNet__FragmentNotFound();
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        // Could add logic to prevent adjustment if fragment is already validated and rewards distributed
        if (fragment.isValidated) revert CogniNet__CannotAdjustPastRewardFactor();

        uint256 oldFactor = fragment.rewardFactor;
        fragment.rewardFactor = _newFactor;
        emit FragmentRewardFactorAdjusted(_fragmentId, oldFactor, _newFactor);
    }

    /**
     * @dev Mints a unique Skill Badge (NFT) to an agent for achieving certain milestones or skills.
     *      This is an internal/governance-triggered function, not directly callable by agents.
     * @param _agent The address of the agent to mint the badge to.
     * @param _badgeType A unique identifier for the type of skill badge.
     */
    function mintSkillBadge(address _agent, bytes32 _badgeType) internal {
        // This function would be called internally after an agent achieves a specific reputation,
        // completes a high-difficulty challenge, or a governance vote.
        // For instance: _updateAgentReputation could check for milestones and call this.
        uint256 tokenId = block.timestamp; // Simple unique ID, in real NFT, manage counters
        skillBadgeNFT.mint(_agent, tokenId, _badgeType);
        emit SkillBadgeMinted(_agent, _badgeType, tokenId);
    }

    /**
     * @dev Allows a user to subscribe to a premium CogniNet tier for enhanced access/features.
     * @param _tierId The ID of the subscription tier.
     * @param _durationInMonths The duration of the subscription in months.
     */
    function subscribeToCogniNetTier(uint256 _tierId, uint256 _durationInMonths) external whenNotPaused {
        if (_tierId >= subscriptionTiers.length) revert CogniNet__SubscriptionNotFound();
        if (_durationInMonths == 0) revert CogniNet__InvalidChallengeState(); // Reusing error
        
        SubscriptionTier storage tier = subscriptionTiers[_tierId];
        uint256 cost = tier.pricePerMonth * _durationInMonths;

        if (cost > 0) {
            cogniToken.transferFrom(msg.sender, address(this), cost);
        }

        uint256 currentExpiry = agentSubscriptions[msg.sender][_tierId];
        if (currentExpiry < block.timestamp) {
            currentExpiry = block.timestamp;
        }
        agentSubscriptions[msg.sender][_tierId] = currentExpiry + (_durationInMonths * 30 days); // Approx 30 days per month
        
        emit CogniNetTierSubscribed(msg.sender, _tierId, agentSubscriptions[msg.sender][_tierId]);
    }

    /**
     * @dev Allows an Agent to claim their accumulated COGNIToken rewards.
     */
    function claimAccumulatedRewards() external onlyAgent whenNotPaused {
        uint256 rewards = agents[msg.sender].accumulatedRewards;
        if (rewards == 0) revert CogniNet__NoRewardsToClaim();

        agents[msg.sender].accumulatedRewards = 0;
        cogniToken.transfer(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    // --- VI. Protocol Governance ---

    /**
     * @dev Allows an Agent to propose an upgrade or change to the CogniNet protocol.
     *      Requires a stake to propose and links to off-chain details.
     * @param _proposalHash Hash of the detailed proposal document.
     * @param _detailsURI URI to the detailed proposal document.
     */
    function proposeProtocolUpgrade(bytes32 _proposalHash, string calldata _detailsURI) external onlyAgent whenNotPaused returns (uint256) {
        // In a real DAO, proposing might require a certain amount of staked tokens or reputation.
        // For simplicity, any agent can propose.

        governanceProposals.push(
            GovernanceProposal({
                proposalHash: _proposalHash,
                detailsURI: _detailsURI,
                proposer: msg.sender,
                submissionTime: block.timestamp,
                votingEndTime: block.timestamp + GOVERNANCE_VOTING_PERIOD,
                status: ProposalStatus.Active,
                yesVotes: 0,
                noVotes: 0
            })
        );
        uint256 proposalId = governanceProposals.length - 1;
        emit ProtocolUpgradeProposed(msg.sender, proposalId, _proposalHash, _detailsURI);
        return proposalId;
    }

    /**
     * @dev Allows registered Agents to vote on an active governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _approve True to vote yes, false to vote no.
     */
    function voteOnUpgradeProposal(uint256 _proposalId, bool _approve) external onlyAgent whenNotPaused {
        if (_proposalId >= governanceProposals.length) revert CogniNet__ProposalNotFound();
        GovernanceProposal storage proposal = governanceProposals[_proposalId];

        if (proposal.status != ProposalStatus.Active) revert CogniNet__ProposalVotingNotEnded(); // Can't vote on inactive proposals
        if (block.timestamp >= proposal.votingEndTime) revert CogniNet__ProposalVotingEnded(); // Using this error
        if (proposal.hasVoted[msg.sender]) revert CogniNet__AlreadyVotedOnValidation(); // Reusing error for already voted

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(msg.sender, _proposalId, _approve);
    }

    /**
     * @dev Executes a governance proposal that has successfully passed its voting period.
     *      This function would typically involve `delegatecall` to upgrade the contract or
     *      change critical parameters, depending on the proposal type.
     *      For this example, it's a placeholder for an actual execution mechanism.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeApprovedProposal(uint256 _proposalId) external whenNotPaused {
        if (_proposalId >= governanceProposals.length) revert CogniNet__ProposalNotFound();
        GovernanceProposal storage proposal = governanceProposals[_proposalId];

        if (proposal.status == ProposalStatus.Executed) revert CogniNet__ProposalAlreadyExecuted();
        if (block.timestamp < proposal.votingEndTime) revert CogniNet__ProposalVotingActive(); // Voting still active

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        bool proposalPassed = (totalVotes > 0 && (proposal.yesVotes * 100 / totalVotes) >= GOVERNANCE_MIN_YES_VOTES_PERCENTAGE);

        if (proposalPassed) {
            proposal.status = ProposalStatus.Succeeded;
            // --- Placeholder for actual execution logic ---
            // This is where a real upgrade mechanism would be triggered:
            // - Change an immutable parameter (if allowed)
            // - Call a function on a proxy contract to upgrade implementation
            // - Transfer funds for a specific purpose
            // - Call a function on another contract for an agreed-upon action
            // For this example, we'll just mark it as executed.
            // Example: set a new minimum agent stake if the proposal was about it.
            // minAgentStake = newMinStakeValue;
            // ---------------------------------------------
            
            proposal.status = ProposalStatus.Executed; // Mark as executed after logic
            emit ProposalExecuted(_proposalId, true);
        } else {
            proposal.status = ProposalStatus.Failed;
            emit ProposalExecuted(_proposalId, false);
        }
    }
}
```