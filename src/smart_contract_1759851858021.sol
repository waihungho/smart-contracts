Okay, this is an exciting challenge! Creating a smart contract with 20+ unique, advanced, and creative functions without duplicating existing open-source projects requires combining several cutting-edge concepts.

My idea is **"CognitoNet: Dynamic AI-Enhanced Collective Intelligence Protocol"**.

**Core Concept:** CognitoNet is a decentralized protocol where users contribute data/insights (contributions) on various "Topics." An "AI Decision Oracle" (simulated via an interface, as true on-chain AI is currently prohibitive) periodically assesses the accuracy of these contributions. Based on this AI feedback, users' reputation scores are dynamically adjusted, and global protocol parameters (like stake and reward multipliers) change adaptively. The protocol also features "Knowledge Agent" NFTs, which are functional tokens that provide reputation boosts and can have their influence delegated.

**Key Advanced/Creative Concepts:**

1.  **AI Oracle Integration (Simulated):** The contract provides an interface for an off-chain AI to submit feedback on contributions, directly influencing on-chain state and user reputation.
2.  **Dynamic Protocol Parameters:** Core economic parameters (stake requirements, reward rates) are not fixed but adapt based on aggregated AI insights, creating a self-optimizing system.
3.  **Reputation-Weighted Influence:** User influence (e.g., in reward distribution) is directly tied to a dynamic reputation score, which is built on the accuracy of their past contributions as judged by the AI.
4.  **Functional & Delegatable NFTs ("Knowledge Agents"):** NFTs are not just collectibles; they provide tangible boosts to a user's reputation and can be delegated to another address, allowing for advanced trust and collaboration patterns.
5.  **Epoch-based Operations:** The protocol operates in defined epochs for managing AI feedback cycles, reward distributions, and parameter adjustments, ensuring periodic synchronization.
6.  **Topic-Based Contribution System:** Users stake on their insights within specific topics, creating micro-prediction or information markets where accuracy is incentivized.

---

### **CognitoNet: Dynamic AI-Enhanced Collective Intelligence Protocol**

**Outline:**

**I. Core Infrastructure & Access Control:** Basic contract setup, ownership, pausing, and global configuration for the AI Oracle and epoch timings.
**II. Topic & Contribution Management:** Functions for creating new topics for collective intelligence and submitting data/insights (contributions) with a financial stake.
**III. Reputation & Rewards:** Mechanisms for adjusting user reputation based on AI feedback, calculating a user's influence weight, and allowing users to claim epoch-based rewards.
**IV. AI Oracle & Dynamic Parameter Integration:** The crucial interface for the AI Oracle to submit its judgments and the internal logic for adjusting dynamic system parameters.
**V. Knowledge Agent (NFT) Management:** Functions to mint, configure, and manage special NFTs that grant reputation boosts and can be delegated.
**VI. Epoch Advancement & System Maintenance:** Functions for advancing the protocol to the next operational epoch.

**Function Summary:**

1.  **`constructor()`**: Initializes the contract with an owner, setting up basic parameters and the ERC721 for Knowledge Agents.
2.  **`pause()`**: Pauses core contract operations, preventing new contributions or epoch advancements. *(Owner only)*
3.  **`unpause()`**: Unpauses core contract operations. *(Owner only)*
4.  **`setAIDecisionOracle(address _newOracle)`**: Sets the address of the trusted AI Decision Oracle that provides accuracy feedback. *(Owner only)*
5.  **`setEpochDuration(uint256 _duration)`**: Sets the duration (in seconds) of each operational epoch. *(Owner only)*
6.  **`withdrawProtocolFees(address _to, uint256 _amount)`**: Allows the owner to withdraw accumulated protocol fees (e.g., from inaccurate contributions). *(Owner only)*
7.  **`createTopic(string memory _title, string memory _description, uint256 _contributionDeadline)`**: Allows a user to propose a new topic for collective intelligence, setting a deadline for contributions.
8.  **`submitContribution(uint256 _topicId, string memory _dataHash, uint256 _stakeAmount)`**: Users contribute data/insights to an active topic, backing their contribution with a native token stake. The `_dataHash` points to off-chain data (e.g., IPFS).
9.  **`finalizeTopicOutcome(uint256 _topicId, string memory _finalOutcomeHash)`**: Owner/curator finalizes a topic, marking its resolution and recording the hash of the final, agreed-upon outcome. *(Owner/Curator only)*
10. **`getContributionDetails(uint256 _contributionId)`**: Retrieves detailed information about a specific contribution. *(View)*
11. **`updateReputationBasedOnAI(address _user, int256 _reputationDelta)`**: *(Internal)* Adjusts a user's reputation score based on AI feedback, called during the processing of AI decisions.
12. **`claimEpochRewards(uint256 _epochId)`**: Allows users to claim their proportional rewards for a past epoch based on their accurately judged contributions and reputation weight.
13. **`getUserReputation(address _user)`**: Returns the current reputation score of a specific user. *(View)*
14. **`getReputationWeight(address _user)`**: Returns the calculated influence weight of a user, combining their base reputation and boosts from delegated Knowledge Agents. *(View)*
15. **`submitAIDecisionFeedback(uint256 _topicId, uint256[] memory _contributionIds, bool[] memory _isAccurate, int256 _dynamicParamModifier)`**: AI Oracle submits its periodic feedback on the accuracy of contributions within a topic and provides a modifier to adjust global dynamic parameters. *(AI Oracle only)*
16. **`_adjustDynamicParameters(int256 _modifier)`**: *(Internal)* Dynamically adjusts system parameters (stake and reward multipliers) based on the AI Oracle's feedback modifier.
17. **`getDynamicStakeMultiplier()`**: Returns the current dynamically adjusted stake multiplier. *(View)*
18. **`getDynamicRewardMultiplier()`**: Returns the current dynamically adjusted reward multiplier. *(View)*
19. **`mintKnowledgeAgent(address _to, uint256 _initialReputationBoost)`**: Mints a new Knowledge Agent NFT to an address, granting an initial reputation boost. *(Owner only)*
20. **`setAgentReputationBoost(uint256 _tokenId, uint256 _newBoost)`**: Adjusts the reputation boost provided by a specific Knowledge Agent NFT. *(Agent Owner or Approved only)*
21. **`delegateAgentInfluence(uint256 _tokenId, address _delegatee)`**: Allows a Knowledge Agent owner to delegate the agent's reputation boost and influence to another address.
22. **`undelegateAgentInfluence(uint256 _tokenId)`**: Removes delegation for a specific Knowledge Agent, returning its influence to the owner.
23. **`advanceEpoch()`**: Triggers the advancement to the next epoch, initiating reward calculations and processing pending AI feedback.
24. **`getCurrentEpoch()`**: Returns the current epoch number. *(View)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For int256 operations
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- CONTRACT: CognitoNet: Dynamic AI-Enhanced Collective Intelligence Protocol ---

// Outline:
// I. Core Infrastructure & Access Control: Setup, pausing, ownership, fee withdrawal.
// II. Topic & Contribution Management: Creating topics, submitting contributions, finalizing outcomes.
// III. Reputation & Rewards: Managing user reputation, claiming epoch-based rewards, calculating influence.
// IV. AI Oracle & Dynamic Parameter Integration: Interface for AI feedback, dynamic parameter adjustments.
// V. Knowledge Agent (NFT) Management: Minting, boosting, and delegating functional NFTs.
// VI. Epoch Advancement & System Maintenance: Advancing epochs, current epoch query.

// Function Summary:
// 1. constructor(): Initializes the contract with an owner, setting up basic parameters and the ERC721 for Knowledge Agents.
// 2. pause(): Pauses core contract operations, preventing new contributions or epoch advancements. (Owner only)
// 3. unpause(): Unpauses core contract operations. (Owner only)
// 4. setAIDecisionOracle(address _newOracle): Sets the address of the trusted AI Decision Oracle. (Owner only)
// 5. setEpochDuration(uint256 _duration): Sets the duration (in seconds) of each operational epoch. (Owner only)
// 6. withdrawProtocolFees(address _to, uint256 _amount): Allows the owner to withdraw accumulated protocol fees. (Owner only)
// 7. createTopic(string memory _title, string memory _description, uint256 _contributionDeadline): Allows a user to propose a new topic for collective intelligence, setting a deadline for contributions.
// 8. submitContribution(uint256 _topicId, string memory _dataHash, uint256 _stakeAmount): Users contribute data/insights to an active topic, backing their contribution with a stake in the native token.
// 9. finalizeTopicOutcome(uint256 _topicId, string memory _finalOutcomeHash): Owner/curator finalizes a topic, marking its resolution and recording the final outcome hash. (Owner/Curator only)
// 10. getContributionDetails(uint256 _contributionId): Retrieves detailed information about a specific contribution. (View)
// 11. updateReputationBasedOnAI(address _user, int256 _reputationDelta): Internal function, called by the AI Oracle during feedback processing, to adjust a user's reputation score. (Internal/Oracle only)
// 12. claimEpochRewards(uint256 _epochId): Allows users to claim their proportional rewards for a past epoch based on their calculated reputation and contributions.
// 13. getUserReputation(address _user): Returns the current reputation score of a specific user. (View)
// 14. getReputationWeight(address _user): Returns the calculated influence weight of a user, combining their base reputation and boosts from delegated Knowledge Agents. (View)
// 15. submitAIDecisionFeedback(uint256 _topicId, uint256[] memory _contributionIds, bool[] memory _isAccurate, int256 _dynamicParamModifier): AI Oracle submits its periodic feedback on contributions' accuracy and an overall dynamic parameter modifier. (AI Oracle only)
// 16. _adjustDynamicParameters(int256 _modifier): Internal function to dynamically adjust system parameters (stake/reward multipliers) based on the AI Oracle's feedback modifier.
// 17. getDynamicStakeMultiplier(): Returns the current dynamically adjusted stake multiplier. (View)
// 18. getDynamicRewardMultiplier(): Returns the current dynamically adjusted reward multiplier. (View)
// 19. mintKnowledgeAgent(address _to, uint256 _initialReputationBoost): Mints a new Knowledge Agent NFT to an address, granting an initial reputation boost. (Owner only)
// 20. setAgentReputationBoost(uint256 _tokenId, uint256 _newBoost): Adjusts the reputation boost provided by a specific Knowledge Agent NFT. (Agent Owner or Approved only)
// 21. delegateAgentInfluence(uint256 _tokenId, address _delegatee): Allows a Knowledge Agent owner to delegate the agent's reputation boost and influence to another address.
// 22. undelegateAgentInfluence(uint256 _tokenId): Removes delegation for a specific Knowledge Agent.
// 23. advanceEpoch(): Triggers the advancement to the next epoch, initiating reward calculations and processing pending AI feedback.
// 24. getCurrentEpoch(): Returns the current epoch number. (View)


contract CognitoNet is Ownable, Pausable, ERC721Burnable, ReentrancyGuard {
    using SafeMath for uint256; // OpenZeppelin's SafeMath for uint256
    using SafeMath for int256;  // Using SafeMath for int256 operations (requires custom SafeMath or similar for int types)
                                // NOTE: Standard OpenZeppelin SafeMath is for uint256. For int256,
                                // a custom library would be needed. For this example, we assume SafeMath
                                // like behavior for int256 as well, to prevent under/overflows conceptually.
                                // In a production environment, one might use PRBMath.

    // --- State Variables ---

    address public aiDecisionOracle;
    uint256 public epochDuration; // Duration of an epoch in seconds (e.g., 1 day = 86400)
    uint256 public currentEpoch;
    uint256 public nextEpochStartTime;

    uint256 public totalProtocolFunds; // Total funds managed by the protocol (staked, rewards, fees)
    uint256 public protocolFeesCollected; // Specific funds designated as protocol fees

    // Dynamic parameters adjusted by AI feedback
    // Base 10000 means 1x. E.g., 12000 means 1.2x, 8000 means 0.8x.
    uint256 public dynamicStakeMultiplier;
    uint256 public dynamicRewardMultiplier;

    uint256 public constant BASE_MULTIPLIER = 10_000;      // Used for fixed-point math multipliers
    uint256 public constant INITIAL_REPUTATION = 1_000;     // Base reputation for new users
    uint256 public constant MIN_STAKE_AMOUNT = 1e16;       // 0.01 native token (e.g., 0.01 ETH)

    // --- Structs ---

    struct Topic {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 creationTime;
        uint256 contributionDeadline;
        bool isFinalized;
        string finalOutcomeHash; // Hash of the final resolved outcome or data
        uint256 totalContributions;
        uint256 totalStakedForTopic;
    }

    struct Contribution {
        uint256 id;
        uint256 topicId;
        address contributor;
        string dataHash; // IPFS hash or similar of the actual data
        uint256 stakeAmount; // Actual amount staked by contributor (before multiplier)
        uint256 effectiveStake; // Stake amount after dynamicStakeMultiplier applied
        uint256 submissionTime;
        bool isAccurate;    // Set by AI Oracle feedback
        bool judgedByAI;    // True if AI Oracle has provided feedback
        int256 reputationImpact; // Reputation delta for this contribution, applied upon AI judgment
        bool rewardsClaimed; // To prevent double claiming
    }

    // Knowledge Agent NFT specific struct (additional attributes)
    struct KnowledgeAgent {
        uint256 reputationBoost; // e.g., 100 = 100 reputation points boost
        address delegatedTo;     // The address this agent's influence is delegated to
    }

    // --- Mappings ---

    mapping(uint256 => Topic) public topics;
    uint256 public nextTopicId;

    mapping(uint256 => Contribution) public contributions;
    uint256 public nextContributionId;

    mapping(address => int256) public userReputation; // int256 to allow for penalties/negative reputation

    mapping(uint256 => KnowledgeAgent) public knowledgeAgents; // tokenId => KnowledgeAgent attributes
    mapping(address => uint256[]) public userOwnedKnowledgeAgents; // user => array of tokenIds they own

    // Used for simplified epoch reward tracking, a full system would need more complex indexers
    mapping(uint256 => uint256) public epochRewardPool; // Total reward pool for a specific epoch
    mapping(address => mapping(uint256 => bool)) public hasClaimedEpochRewards; // User has claimed for epoch

    // --- Events ---

    event AIDecisionOracleSet(address indexed _oldOracle, address indexed _newOracle);
    event EpochDurationSet(uint256 _newDuration);
    event ProtocolFeesWithdrawn(address indexed _to, uint256 _amount);

    event TopicCreated(uint256 indexed _topicId, address indexed _proposer, string _title, uint256 _deadline);
    event ContributionSubmitted(uint256 indexed _contributionId, uint256 indexed _topicId, address indexed _contributor, uint256 _effectiveStake);
    event TopicFinalized(uint256 indexed _topicId, string _finalOutcomeHash);

    event ReputationUpdated(address indexed _user, int256 _oldReputation, int256 _newReputation, int256 _delta);
    event RewardsClaimed(address indexed _user, uint256 indexed _epochId, uint256 _amount);

    event AIDecisionFeedbackSubmitted(uint256 indexed _topicId, int256 _dynamicParamModifier);
    event DynamicParametersAdjusted(uint256 _oldStakeMultiplier, uint256 _newStakeMultiplier, uint256 _oldRewardMultiplier, uint256 _newRewardMultiplier);

    event KnowledgeAgentMinted(uint256 indexed _tokenId, address indexed _to, uint256 _boost);
    event AgentReputationBoostSet(uint256 indexed _tokenId, uint256 _oldBoost, uint256 _newBoost);
    event AgentInfluenceDelegated(uint256 indexed _tokenId, address indexed _from, address indexed _to);
    event AgentInfluenceUndelegated(uint256 indexed _tokenId, address indexed _from);

    event EpochAdvanced(uint256 indexed _newEpoch, uint256 _nextEpochStartTime);

    // --- Modifiers ---

    modifier onlyAIDecisionOracle() {
        require(msg.sender == aiDecisionOracle, "CognitoNet: Only AI Decision Oracle can call this function");
        _;
    }

    modifier onlyAgentOwnerOrApproved(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CognitoNet: Only agent owner or approved can perform this action");
        _;
    }

    // --- Constructor ---

    constructor(address _aiOracleAddress, uint256 _epochDuration)
        ERC721("KnowledgeAgent", "KNA")
        Ownable(msg.sender)
    {
        require(_aiOracleAddress != address(0), "CognitoNet: AI Oracle address cannot be zero");
        require(_epochDuration > 0, "CognitoNet: Epoch duration must be greater than zero");

        aiDecisionOracle = _aiOracleAddress;
        epochDuration = _epochDuration;
        currentEpoch = 1;
        nextEpochStartTime = block.timestamp + epochDuration;
        dynamicStakeMultiplier = BASE_MULTIPLIER; // Start at 1x
        dynamicRewardMultiplier = BASE_MULTIPLIER; // Start at 1x

        nextTopicId = 1;
        nextContributionId = 1;
        nextKnowledgeAgentId = 1;

        // Initialize reputation for potential future genesis members, or it starts at 0 for all
        // For new users, reputation will be 0 until their first contribution is judged.
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Pauses core contract operations. Only callable by the owner.
     * Prevents new topics, contributions, and epoch advancements.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses core contract operations. Only callable by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the address of the trusted AI Decision Oracle.
     * This address is responsible for submitting AI feedback.
     * @param _newOracle The new address for the AI Decision Oracle.
     */
    function setAIDecisionOracle(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "CognitoNet: AI Oracle address cannot be zero");
        emit AIDecisionOracleSet(aiDecisionOracle, _newOracle);
        aiDecisionOracle = _newOracle;
    }

    /**
     * @dev Sets the duration (in seconds) of each operational epoch.
     * A new epoch cannot be shorter than 1 hour.
     * @param _duration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _duration) public onlyOwner {
        require(_duration >= 3600, "CognitoNet: Epoch duration must be at least 1 hour"); // Min 1 hour
        emit EpochDurationSet(_duration);
        epochDuration = _duration;
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "CognitoNet: Cannot withdraw to zero address");
        require(_amount > 0, "CognitoNet: Amount must be greater than zero");
        require(protocolFeesCollected >= _amount, "CognitoNet: Insufficient protocol fees");

        protocolFeesCollected = protocolFeesCollected.sub(_amount);
        totalProtocolFunds = totalProtocolFunds.sub(_amount);
        payable(_to).transfer(_amount);
        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    // --- II. Topic & Contribution Management ---

    /**
     * @dev Allows a user to propose a new topic for collective intelligence.
     * @param _title The title of the topic.
     * @param _description A detailed description of the topic.
     * @param _contributionDeadline The timestamp by which contributions must be submitted.
     */
    function createTopic(
        string memory _title,
        string memory _description,
        uint256 _contributionDeadline
    ) public whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "CognitoNet: Topic title cannot be empty");
        require(_contributionDeadline > block.timestamp, "CognitoNet: Contribution deadline must be in the future");

        uint256 topicId = nextTopicId++;
        topics[topicId] = Topic({
            id: topicId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            creationTime: block.timestamp,
            contributionDeadline: _contributionDeadline,
            isFinalized: false,
            finalOutcomeHash: "",
            totalContributions: 0,
            totalStakedForTopic: 0
        });

        emit TopicCreated(topicId, msg.sender, _title, _contributionDeadline);
        return topicId;
    }

    /**
     * @dev Users contribute data/insights to an active topic, backed by a stake.
     * The actual data is referenced by `_dataHash` (e.g., IPFS hash) and stored off-chain.
     * @param _topicId The ID of the topic to contribute to.
     * @param _dataHash The hash referencing the off-chain data/insight.
     * @param _stakeAmount The amount of native tokens staked with this contribution.
     */
    function submitContribution(
        uint256 _topicId,
        string memory _dataHash,
        uint256 _stakeAmount
    ) public payable whenNotPaused nonReentrant {
        Topic storage topic = topics[_topicId];
        require(topic.id != 0, "CognitoNet: Topic does not exist");
        require(block.timestamp <= topic.contributionDeadline, "CognitoNet: Contribution deadline passed");
        require(!topic.isFinalized, "CognitoNet: Topic is already finalized");
        require(_stakeAmount >= MIN_STAKE_AMOUNT, "CognitoNet: Stake amount too low");
        require(msg.value == _stakeAmount, "CognitoNet: Msg value must match stake amount");

        // Apply dynamic stake multiplier
        uint256 effectiveStake = _stakeAmount.mul(dynamicStakeMultiplier).div(BASE_MULTIPLIER);

        uint256 contributionId = nextContributionId++;
        contributions[contributionId] = Contribution({
            id: contributionId,
            topicId: _topicId,
            contributor: msg.sender,
            dataHash: _dataHash,
            stakeAmount: _stakeAmount,
            effectiveStake: effectiveStake, // Store effective stake for calculations
            submissionTime: block.timestamp,
            isAccurate: false, // Default, to be set by AI
            judgedByAI: false,
            reputationImpact: 0,
            rewardsClaimed: false
        });

        topic.totalContributions = topic.totalContributions.add(1);
        topic.totalStakedForTopic = topic.totalStakedForTopic.add(effectiveStake);
        totalProtocolFunds = totalProtocolFunds.add(effectiveStake); // Add to general pool

        emit ContributionSubmitted(contributionId, _topicId, msg.sender, effectiveStake);
    }

    /**
     * @dev Owner/curator finalizes a topic, marking its resolution and recording the final outcome hash.
     * This function should ideally be called after the contribution deadline and AI feedback.
     * @param _topicId The ID of the topic to finalize.
     * @param _finalOutcomeHash The hash representing the final, agreed-upon outcome or data.
     */
    function finalizeTopicOutcome(uint256 _topicId, string memory _finalOutcomeHash) public onlyOwner { // Can be extended to a curator role
        Topic storage topic = topics[_topicId];
        require(topic.id != 0, "CognitoNet: Topic does not exist");
        require(!topic.isFinalized, "CognitoNet: Topic is already finalized");
        require(bytes(_finalOutcomeHash).length > 0, "CognitoNet: Final outcome hash cannot be empty");

        topic.isFinalized = true;
        topic.finalOutcomeHash = _finalOutcomeHash;

        emit TopicFinalized(_topicId, _finalOutcomeHash);
    }

    /**
     * @dev Retrieves detailed information about a specific contribution.
     * @param _contributionId The ID of the contribution.
     * @return A tuple containing contribution details.
     */
    function getContributionDetails(uint256 _contributionId)
        public
        view
        returns (
            uint256 id,
            uint256 topicId,
            address contributor,
            string memory dataHash,
            uint256 stakeAmount,
            uint256 effectiveStake,
            uint256 submissionTime,
            bool isAccurate,
            bool judgedByAI,
            int256 reputationImpact,
            bool rewardsClaimed
        )
    {
        Contribution storage c = contributions[_contributionId];
        require(c.id != 0, "CognitoNet: Contribution does not exist");
        return (c.id, c.topicId, c.contributor, c.dataHash, c.stakeAmount, c.effectiveStake, c.submissionTime, c.isAccurate, c.judgedByAI, c.reputationImpact, c.rewardsClaimed);
    }


    // --- III. Reputation & Rewards ---

    /**
     * @dev Internal function, called by the AI Oracle during feedback processing, to adjust a user's reputation score.
     * This function is crucial for linking AI feedback to user standing.
     * @param _user The address of the user whose reputation is being updated.
     * @param _reputationDelta The change in reputation (can be positive or negative).
     */
    function updateReputationBasedOnAI(address _user, int256 _reputationDelta) internal {
        int256 oldReputation = userReputation[_user];
        userReputation[_user] = SafeMath.max(0, oldReputation.add(_reputationDelta)); // Reputation cannot go below 0
        emit ReputationUpdated(_user, oldReputation, userReputation[_user], _reputationDelta);
    }

    /**
     * @dev Allows users to claim their proportional rewards for accurate contributions made in a specific epoch.
     * Rewards are based on the user's reputation-weighted effective stake in that epoch.
     * @param _epochId The ID of the epoch for which to claim rewards.
     */
    function claimEpochRewards(uint256 _epochId) public nonReentrant {
        require(_epochId < currentEpoch, "CognitoNet: Cannot claim rewards for current or future epochs");
        require(!hasClaimedEpochRewards[msg.sender][_epochId], "CognitoNet: Rewards already claimed for this epoch");

        uint256 totalClaimableReward = 0;
        uint256 epochStartTime = nextEpochStartTime - (_epochId * epochDuration);
        uint256 epochEndTime = epochStartTime + epochDuration;

        // Iterate through all contributions to find user's contributions in _epochId.
        // NOTE: For a production system, iterating through all contributions is highly inefficient.
        // A robust solution would involve mapping contributions to epochs, or pre-calculating rewards.
        for (uint256 i = 1; i < nextContributionId; i++) {
            Contribution storage c = contributions[i];
            if (c.contributor == msg.sender &&
                c.submissionTime >= epochStartTime &&
                c.submissionTime < epochEndTime &&
                c.judgedByAI &&
                !c.rewardsClaimed) // Check if already processed for rewards
            {
                if (c.isAccurate) {
                    // Return effective stake + reputation-weighted bonus
                    uint256 reputationWeight = getReputationWeight(msg.sender);
                    uint256 bonus = c.effectiveStake
                                        .mul(reputationWeight)
                                        .div(INITIAL_REPUTATION) // Normalize by initial reputation
                                        .mul(dynamicRewardMultiplier)
                                        .div(BASE_MULTIPLIER); // Apply dynamic reward multiplier

                    totalClaimableReward = totalClaimableReward.add(c.effectiveStake).add(bonus);
                } else {
                    // Inaccurate contribution: Stake goes to protocol fees
                    protocolFeesCollected = protocolFeesCollected.add(c.effectiveStake);
                    // Funds are already in totalProtocolFunds, just re-categorize
                }
                c.rewardsClaimed = true; // Mark contribution as processed for rewards
            }
        }

        require(totalClaimableReward > 0, "CognitoNet: No rewards to claim for this epoch or contributions were inaccurate");
        require(totalProtocolFunds >= totalClaimableReward, "CognitoNet: Insufficient protocol funds to distribute rewards");

        totalProtocolFunds = totalProtocolFunds.sub(totalClaimableReward);
        hasClaimedEpochRewards[msg.sender][_epochId] = true;
        payable(msg.sender).transfer(totalClaimableReward);

        emit RewardsClaimed(msg.sender, _epochId, totalClaimableReward);
    }

    /**
     * @dev Returns the current reputation score of a specific user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }

    /**
     * @dev Returns the calculated influence weight of a user, combining their base reputation and boosts from delegated Knowledge Agents.
     * Influence is directly proportional to reputation and boosted by agents.
     * @param _user The address of the user.
     * @return The user's total reputation weight.
     */
    function getReputationWeight(address _user) public view returns (uint256) {
        int256 currentReputation = userReputation[_user];
        uint256 totalBoostFromAgents = 0;

        // Iterate through all Knowledge Agents to find those delegated to _user
        // NOTE: For a large number of agents, this iteration can be gas-intensive.
        // A more efficient approach would be to maintain a mapping:
        // mapping(address => uint256[]) public delegatedAgentsToUser;
        for (uint256 i = 1; i < nextKnowledgeAgentId; i++) {
            if (knowledgeAgents[i].delegatedTo == _user) {
                totalBoostFromAgents = totalBoostFromAgents.add(knowledgeAgents[i].reputationBoost);
            }
        }

        // Calculate final effective reputation, capping at a reasonable max if desired
        uint256 finalReputation = uint256(SafeMath.max(0, currentReputation.add(int256(totalBoostFromAgents))));
        // The weight is normalized against INITIAL_REPUTATION to give a multiplier.
        // E.g., if INITIAL_REPUTATION is 1000, and user has 2000, weight is 2x.
        return finalReputation.mul(BASE_MULTIPLIER).div(INITIAL_REPUTATION);
    }

    // --- IV. AI Oracle & Dynamic Parameter Integration ---

    /**
     * @dev AI Oracle submits its periodic feedback on contributions' accuracy and an overall dynamic parameter modifier.
     * This function is central to the AI-enhanced aspect of the protocol.
     * @param _topicId The ID of the topic being judged.
     * @param _contributionIds An array of contribution IDs for the given topic.
     * @param _isAccurate An array of booleans indicating accuracy for each contribution.
     * @param _dynamicParamModifier A modifier value (e.g., -100 to 100) that influences global system parameters.
     */
    function submitAIDecisionFeedback(
        uint256 _topicId,
        uint256[] memory _contributionIds,
        bool[] memory _isAccurate,
        int256 _dynamicParamModifier
    ) public onlyAIDecisionOracle whenNotPaused {
        require(_contributionIds.length == _isAccurate.length, "CognitoNet: Mismatched array lengths");
        require(topics[_topicId].id != 0, "CognitoNet: Topic does not exist");

        for (uint256 i = 0; i < _contributionIds.length; i++) {
            uint256 cId = _contributionIds[i];
            Contribution storage c = contributions[cId];
            require(c.id != 0 && c.topicId == _topicId, "CognitoNet: Invalid contribution ID for topic");
            require(!c.judgedByAI, "CognitoNet: Contribution already judged by AI");

            c.isAccurate = _isAccurate[i];
            c.judgedByAI = true;

            // Calculate reputation impact based on accuracy
            int256 reputationDelta;
            if (c.isAccurate) {
                reputationDelta = 50; // Positive reputation for accurate contribution
            } else {
                reputationDelta = -25; // Negative reputation for inaccurate contribution
            }
            c.reputationImpact = reputationDelta; // Store for transparency
            updateReputationBasedOnAI(c.contributor, reputationDelta);
        }

        _adjustDynamicParameters(_dynamicParamModifier);
        emit AIDecisionFeedbackSubmitted(_topicId, _dynamicParamModifier);
    }

    /**
     * @dev Internal function to dynamically adjust system parameters (stake/reward multipliers)
     * based on the AI Oracle's feedback modifier.
     * @param _modifier The modifier value from the AI Oracle (e.g., -100 to 100).
     */
    function _adjustDynamicParameters(int256 _modifier) internal {
        uint256 oldStakeMultiplier = dynamicStakeMultiplier;
        uint256 oldRewardMultiplier = dynamicRewardMultiplier;

        // Example adjustment logic: linear scaling based on modifier
        // Modifier range -100 to 100 maps to an adjustment of -1000 to 1000 on multipliers (10% of BASE_MULTIPLIER)
        int256 adjustment = _modifier.mul(BASE_MULTIPLIER).div(1000); // Scale modifier to affect 10% range

        int256 newStakeMultiplier = int256(dynamicStakeMultiplier).add(adjustment);
        int256 newRewardMultiplier = int256(dynamicRewardMultiplier).add(adjustment);

        // Ensure multipliers don't go below a certain threshold (e.g., 50% of base) or above (e.g., 200% of base)
        dynamicStakeMultiplier = uint256(SafeMath.max(int256(BASE_MULTIPLIER.div(2)), newStakeMultiplier)); // Min 0.5x
        dynamicStakeMultiplier = uint256(SafeMath.min(int256(BASE_MULTIPLIER.mul(2)), int256(dynamicStakeMultiplier))); // Max 2x

        dynamicRewardMultiplier = uint256(SafeMath.max(int256(BASE_MULTIPLIER.div(2)), newRewardMultiplier)); // Min 0.5x
        dynamicRewardMultiplier = uint256(SafeMath.min(int256(BASE_MULTIPLIER.mul(2)), int256(dynamicRewardMultiplier))); // Max 2x

        emit DynamicParametersAdjusted(oldStakeMultiplier, dynamicStakeMultiplier, oldRewardMultiplier, dynamicRewardMultiplier);
    }

    /**
     * @dev Returns the current dynamically adjusted stake multiplier.
     * @return The current stake multiplier (e.g., 12000 for 1.2x).
     */
    function getDynamicStakeMultiplier() public view returns (uint256) {
        return dynamicStakeMultiplier;
    }

    /**
     * @dev Returns the current dynamically adjusted reward multiplier.
     * @return The current reward multiplier (e.g., 8000 for 0.8x).
     */
    function getDynamicRewardMultiplier() public view returns (uint256) {
        return dynamicRewardMultiplier;
    }


    // --- V. Knowledge Agent (NFT) Management ---

    uint256 private nextKnowledgeAgentId; // Internal counter for KNA token IDs

    /**
     * @dev Mints a new Knowledge Agent NFT to an address, granting an initial reputation boost.
     * This NFT represents enhanced participation rights.
     * @param _to The address to mint the NFT to.
     * @param _initialReputationBoost The initial reputation boost (e.g., 50 for +50 reputation points).
     */
    function mintKnowledgeAgent(address _to, uint256 _initialReputationBoost) public onlyOwner {
        _safeMint(_to, nextKnowledgeAgentId);
        knowledgeAgents[nextKnowledgeAgentId] = KnowledgeAgent({
            reputationBoost: _initialReputationBoost,
            delegatedTo: _to // Initially delegated to its owner
        });
        userOwnedKnowledgeAgents[_to].push(nextKnowledgeAgentId);
        emit KnowledgeAgentMinted(nextKnowledgeAgentId, _to, _initialReputationBoost);
        nextKnowledgeAgentId++;
    }

    /**
     * @dev Adjusts the reputation boost provided by a specific Knowledge Agent NFT.
     * Can be called by the agent's owner or an approved address.
     * @param _tokenId The ID of the Knowledge Agent NFT.
     * @param _newBoost The new reputation boost value.
     */
    function setAgentReputationBoost(uint256 _tokenId, uint256 _newBoost) public onlyAgentOwnerOrApproved(_tokenId) {
        KnowledgeAgent storage agent = knowledgeAgents[_tokenId];
        // Ensure agent exists by checking initial boost, or a more explicit flag
        require(agent.reputationBoost != 0 || _newBoost != 0, "CognitoNet: Agent does not exist");
        uint256 oldBoost = agent.reputationBoost;
        agent.reputationBoost = _newBoost;
        emit AgentReputationBoostSet(_tokenId, oldBoost, _newBoost);
    }

    /**
     * @dev Allows a Knowledge Agent owner to delegate the agent's reputation boost and influence to another address.
     * The `_delegatee` will gain the reputation boost when their `getReputationWeight` is calculated.
     * @param _tokenId The ID of the Knowledge Agent NFT.
     * @param _delegatee The address to delegate the influence to.
     */
    function delegateAgentInfluence(uint256 _tokenId, address _delegatee) public onlyAgentOwnerOrApproved(_tokenId) {
        KnowledgeAgent storage agent = knowledgeAgents[_tokenId];
        require(_delegatee != address(0), "CognitoNet: Cannot delegate to zero address");
        require(agent.delegatedTo != _delegatee, "CognitoNet: Agent already delegated to this address");

        address oldDelegatee = agent.delegatedTo;
        agent.delegatedTo = _delegatee;
        emit AgentInfluenceDelegated(_tokenId, oldDelegatee, _delegatee);
    }

    /**
     * @dev Removes delegation for a specific Knowledge Agent, returning its influence to the owner.
     * Can be called by the agent's owner or an approved address.
     * @param _tokenId The ID of the Knowledge Agent NFT.
     */
    function undelegateAgentInfluence(uint256 _tokenId) public onlyAgentOwnerOrApproved(_tokenId) {
        KnowledgeAgent storage agent = knowledgeAgents[_tokenId];
        address owner = ownerOf(_tokenId);
        require(agent.delegatedTo != owner, "CognitoNet: Agent influence not delegated or delegated to owner");

        address oldDelegatee = agent.delegatedTo;
        agent.delegatedTo = owner; // Influence returns to the owner
        emit AgentInfluenceUndelegated(_tokenId, oldDelegatee);
    }

    // Override _beforeTokenTransfer to handle userOwnedKnowledgeAgents mapping updates and delegation reset
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0)) {
            _removeAgentFromUserOwnedList(from, tokenId);
        }
        if (to != address(0)) {
            _addAgentToUserOwnedList(to, tokenId);
            // If transferred, delegation should also revert to new owner
            knowledgeAgents[tokenId].delegatedTo = to;
        }
    }

    function _removeAgentFromUserOwnedList(address _user, uint256 _tokenId) internal {
        uint256[] storage agents = userOwnedKnowledgeAgents[_user];
        for (uint256 i = 0; i < agents.length; i++) {
            if (agents[i] == _tokenId) {
                agents[i] = agents[agents.length - 1]; // Replace with last element
                agents.pop(); // Remove last element
                break;
            }
        }
    }

    function _addAgentToUserOwnedList(address _user, uint256 _tokenId) internal {
        userOwnedKnowledgeAgents[_user].push(_tokenId);
    }


    // --- VI. Epoch Advancement & System Maintenance ---

    /**
     * @dev Triggers the advancement to the next epoch.
     * Can only be called once the current epoch duration has passed.
     * This function is crucial for periodically processing AI feedback and moving the protocol state forward.
     */
    function advanceEpoch() public whenNotPaused nonReentrant {
        require(block.timestamp >= nextEpochStartTime, "CognitoNet: Current epoch has not yet ended");

        currentEpoch = currentEpoch.add(1);
        nextEpochStartTime = nextEpochStartTime.add(epochDuration);

        // A real system would potentially trigger aggregated reward calculations or
        // further AI feedback processing here for the *previous* epoch's data.
        // For this example, individual `claimEpochRewards` handles distribution.

        emit EpochAdvanced(currentEpoch, nextEpochStartTime);
    }

    /**
     * @dev Returns the current epoch number.
     * @return The current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }
}
```