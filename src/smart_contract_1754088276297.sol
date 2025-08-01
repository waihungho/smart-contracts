This Solidity smart contract, named "Epochal Nexus Protocol" (ENP), proposes a novel decentralized system for creating self-evolving, reputation-bound digital identities (Epochal Soulbound Constructs - ESCs). These ESCs are non-transferable NFTs that adapt and grow based on user interaction, on-chain activity, and curated external insights (e.g., AI-driven sentiment analysis) delivered via an oracle.

The protocol integrates a gamified quest system, a dynamic governance model where ESC holders influence protocol parameters, and an oracle-driven 'sentiment' or 'insight' layer that influences both individual ESC evolution and the overall protocol's adaptive behavior. It aims to foster long-term engagement, community health, and a truly decentralized, sentient ecosystem.

---

**Outline:**

*   **I. Core Epochal Soulbound Construct (ESC) Management:**
    *   Functions for minting unique, non-transferable ESCs (Soulbound Tokens) and retrieving their basic information.
*   **II. ESC Evolution & Dynamic Attributes:**
    *   Mechanisms for tracking user activities, integrating oracle-delivered external insights (e.g., AI sentiment scores), and enabling ESCs to "ascend" (level up) based on accumulated experience and positive attributes.
*   **III. Gamified Quest & Challenge System:**
    *   A framework for the protocol's governance to propose various quests, allowing users to accept, complete, and claim rewards. Quest completion contributes to ESC evolution.
*   **IV. Adaptive Protocol Parameters & Governance:**
    *   A DAO-like system where qualified ESC holders can propose and vote on changes to core protocol parameters. These adjustments can be influenced by global insights from the oracle, making the protocol adaptive.
*   **V. Oracle Integration & Insight Management:**
    *   Defines the interface and mechanism for a trusted oracle to inject external data, particularly AI-driven insights, which are crucial for the dynamic evolution of ESCs and the protocol's adaptive parameters.
*   **VI. Reward & Treasury Management:**
    *   Functions for managing the native currency (e.g., ETH) reward pool and allowing controlled withdrawals from the protocol's treasury.
*   **VII. Access Control & Whitelisting:**
    *   Functions for managing permissions, such as who is authorized to mint new ESCs.

---

**Function Summary:**

**I. Core Epochal Soulbound Construct (ESC) Management:**
1.  `mintEpochalConstruct(string _initialMetadataURI)`: Mints a new non-transferable Epochal Soulbound Construct (ESC) for the caller, provided they are a whitelisted minter and do not already own an ESC.
2.  `getEpochalConstructDetails(uint256 _tokenId)`: Retrieves essential details (owner, level, XP, last activity, metadata URI) for a specific ESC.
3.  `getEpochalConstructOwner(uint256 _tokenId)`: Returns the blockchain address of the owner of a given ESC token ID.
4.  `getTotalConstructsMinted()`: Returns the total count of ESCs that have been minted in the protocol's lifetime.

**II. ESC Evolution & Dynamic Attributes:**
5.  `recordActivityMetric(uint256 _tokenId, ActivityType _type, uint256 _value)`: Allows an ESC owner to record a specific type of on-chain activity (e.g., voting participation, liquidity provision), which contributes to their ESC's experience points and internal metrics.
6.  `syncExternalInsight(uint256 _tokenId, InsightType _type, int256 _score, bytes32 _insightHash)`: An authorized oracle uses this function to push AI-generated insights (e.g., sentiment scores, anomaly detections) relevant to a specific ESC, influencing its dynamic attributes.
7.  `triggerConstructAscension(uint256 _tokenId)`: Allows an ESC owner to attempt an "ascension" (leveling up) if their construct meets certain experience point thresholds and other conditions (e.g., positive insights).
8.  `getConstructLevel(uint256 _tokenId)`: Returns the current evolutionary level of a specific ESC.
9.  `getConstructAttribute(uint256 _tokenId, AttributeType _type)`: Retrieves the current value of a specific dynamic attribute (e.g., Wisdom, Agility, Community Affinity) for an ESC.
10. `updateConstructMetadata(uint256 _tokenId, string _newMetadataURI)`: Allows an ESC owner to update the display metadata URI associated with their construct, enabling dynamic representation.

**III. Gamified Quest & Challenge System:**
11. `proposeQuest(QuestType _type, uint256 _rewardAmount, uint256 _threshold, string _ipfsHash)`: The protocol owner (or eventually governance) can propose new quests, specifying their type, reward, completion threshold, and a detailed IPFS hash.
12. `acceptQuest(uint256 _questId)`: Allows an ESC owner to formally accept a proposed quest, registering their intent to participate.
13. `verifyQuestCompletion(uint256 _questId, uint256 _tokenId)`: An authorized oracle or relayer uses this function to mark a quest as complete for a specific ESC after off-chain verification of the conditions.
14. `claimQuestReward(uint256 _questId, uint256 _tokenId)`: Allows an ESC owner to claim native currency rewards for a quest once it has been verified as completed for their construct.
15. `getAvailableQuests()`: Returns a list of all currently active and open quests that users can accept.

**IV. Adaptive Protocol Parameters & Governance:**
16. `proposeParameterAdjustment(ParameterType _param, int256 _newValue, string _description)`: Qualified ESC holders can propose changes to core protocol parameters (e.g., quest difficulty multipliers, ascension requirements) to be voted upon by the community.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows ESC holders to cast their vote (yes/no) on an active governance proposal. Voting power is weighted by their ESC's level and attributes.
18. `executeProposal(uint256 _proposalId)`: Executes a governance proposal if it has successfully passed the voting period and met the necessary vote thresholds.
19. `setOracleAddress(address _newOracle)`: The protocol owner/governance can update the address of the trusted oracle responsible for injecting external insights.
20. `adjustEpochalMetrics(int256 _globalSentimentScore)`: The trusted oracle can call this to adjust protocol-wide metrics or reward distributions based on a global sentiment score, making the protocol's behavior dynamic.

**V. Reward & Treasury Management:**
21. `depositRewardFunds()`: Allows anyone to deposit native currency into the contract, which serves as a reward pool for quests and other protocol incentives.
22. `withdrawProtocolTreasury(address _to, uint256 _amount)`: Allows the protocol owner/governance to withdraw native currency from the contract's treasury for operational purposes.

**VI. Access Control & Whitelisting:**
23. `addWhitelistedMinter(address _minter)`: The protocol owner can add addresses to a whitelist, granting them permission to mint new ESCs.
24. `removeWhitelistedMinter(address _minter)`: The protocol owner can remove addresses from the whitelisted minters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// I. Core Epochal Soulbound Construct (ESC) Management:
//    - Minting, basic retrieval for non-transferable ERC721 (SBT).
// II. ESC Evolution & Dynamic Attributes:
//    - Tracking user activities, integrating oracle-delivered insights,
//      and enabling construct 'ascension' (leveling up) based on these factors.
// III. Gamified Quest & Challenge System:
//    - A framework for governance to propose quests, users to accept and complete them,
//      and claim rewards, contributing to ESC evolution.
// IV. Adaptive Protocol Parameters & Governance:
//    - A DAO-like system where ESC holders can propose and vote on changes
//      to protocol parameters, potentially influenced by global insights.
// V. Oracle Integration & Insight Management:
//    - Mechanism for a trusted oracle to inject external data (e.g., AI-driven sentiment)
//      that influences both individual ESCs and global protocol parameters.
// VI. Reward & Treasury Management:
//    - Functions for depositing and withdrawing funds for quest rewards and protocol operations.
// VII. Access Control & Whitelisting:
//    - Managing who can perform specific privileged actions, like minting or setting the oracle.

// Function Summary:
// I. Core Epochal Soulbound Construct (ESC) Management:
// 1.  mintEpochalConstruct(string _initialMetadataURI): Mints a new non-transferable ESC for the caller.
// 2.  getEpochalConstructDetails(uint256 _tokenId): Retrieves all current details for a given ESC.
// 3.  getEpochalConstructOwner(uint256 _tokenId): Returns the owner address of an ESC.
// 4.  getTotalConstructsMinted(): Returns the total number of ESCs minted.

// II. ESC Evolution & Dynamic Attributes:
// 5.  recordActivityMetric(uint256 _tokenId, ActivityType _type, uint256 _value): Records specific on-chain activity contributing to an ESC's metrics.
// 6.  syncExternalInsight(uint256 _tokenId, InsightType _type, int256 _score, bytes32 _insightHash): Oracle pushes AI-generated sentiment/insight for an ESC.
// 7.  triggerConstructAscension(uint256 _tokenId): Allows an ESC owner to attempt an "ascension" based on accumulated metrics/insights.
// 8.  getConstructLevel(uint256 _tokenId): Returns the current evolutionary level of an ESC.
// 9.  getConstructAttribute(uint256 _tokenId, AttributeType _type): Retrieves the value of a specific dynamic attribute for an ESC.
// 10. updateConstructMetadata(uint256 _tokenId, string _newMetadataURI): Allows ESC owner to update their construct's display metadata.

// III. Gamified Quest & Challenge System:
// 11. proposeQuest(QuestType _type, uint256 _rewardAmount, uint256 _threshold, string _ipfsHash): Governance proposes a new quest.
// 12. acceptQuest(uint256 _questId): User formally accepts a quest, registering their intent.
// 13. verifyQuestCompletion(uint256 _questId, uint256 _tokenId): Internal or authorized relayer verifies quest conditions for an ESC.
// 14. claimQuestReward(uint256 _questId, uint256 _tokenId): Allows an ESC owner to claim rewards after successful verification.
// 15. getAvailableQuests(): Returns a list of currently active and available quests.

// IV. Adaptive Protocol Parameters & Governance:
// 16. proposeParameterAdjustment(ParameterType _param, int256 _newValue, string _description): ESC holders propose parameter changes.
// 17. voteOnProposal(uint256 _proposalId, bool _support): ESC holders vote on active proposals.
// 18. executeProposal(uint256 _proposalId): Executes a successfully passed governance proposal.
// 19. setOracleAddress(address _newOracle): Owner/governance sets the trusted oracle address for insights.
// 20. adjustEpochalMetrics(int256 _globalSentimentScore): Governance or oracle-triggered adjustment of protocol-wide metrics based on global sentiment.

// V. Reward & Treasury Management:
// 21. depositRewardFunds(): Allows anyone to deposit native currency into the contract's reward pool.
// 22. withdrawProtocolTreasury(address _to, uint256 _amount): Governance-controlled withdrawal of native currency from treasury.

// VI. Access Control & Whitelisting:
// 23. addWhitelistedMinter(address _minter): Owner/governance can whitelist addresses allowed to mint ESCs.
// 24. removeWhitelistedMinter(address _minter): Removes a whitelisted minter.

contract EpochalNexusProtocol is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    // --- Enums ---

    enum ActivityType {
        VOTING_PARTICIPATION,
        QUEST_COMPLETION,
        TOKEN_HOLDING_DURATION,
        LIQUIDITY_PROVISION,
        PROTOCOL_INTERACTION
    }

    enum InsightType {
        SENTIMENT_SCORE,
        ANOMALY_DETECTION,
        COMMUNITY_HEALTH,
        ADOPTION_RATE
    }

    enum QuestType {
        GOVERNANCE_PARTICIPATION,
        LEVEL_ACHIEVEMENT,
        TOKEN_STAKE_DURATION,
        LP_CONTRIBUTION,
        SPECIFIC_INTERACTION
    }

    enum ParameterType {
        QUEST_DIFFICULTY_MULTIPLIER,
        ASCENSION_XP_REQUIREMENT,
        GOVERNANCE_VOTE_THRESHOLD,
        REWARD_POOL_DISTRIBUTION_WEIGHTS,
        ORACLE_TRUST_SCORE
    }

    enum AttributeType {
        WISDOM,       // Related to governance participation & insights
        AGILITY,      // Related to quest completion speed & interaction frequency
        COMMUNITY_AFFINITY, // Related to positive sentiment & collaboration
        RESILIENCE,   // Related to overcoming challenges or negative events
        INNOVATION    // Related to proposing new ideas/quests
    }

    // --- Structs ---

    struct EpochalConstruct {
        address owner;
        uint256 level;
        uint256 xp; // Experience points
        uint256 lastActivityTimestamp;
        mapping(AttributeType => uint256) attributes;
        mapping(InsightType => int256) externalInsights; // Stores latest score
        string metadataURI;
        mapping(ActivityType => uint256) activityMetrics; // Raw activity data
    }

    struct Quest {
        uint256 id;
        QuestType questType;
        uint256 rewardAmount; // In native currency (ETH)
        uint256 threshold;    // Generic threshold (e.g., number of votes, level)
        string ipfsHash;      // IPFS hash for detailed quest description
        bool isActive;
        address proposer;
        uint256 expirationTime;
        mapping(uint256 => bool) participants; // tokenId => accepted
        mapping(uint256 => bool) completions;  // tokenId => completed
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ParameterType paramType;
        int256 newValue;
        string description;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 snapshotBlock; // Block number at which voting power is calculated
        uint256 expirationTime;
        bool executed;
        mapping(uint256 => bool) hasVoted; // tokenId => voted (to prevent double voting per proposal)
        mapping(uint224 => uint256) voterWeight; // tokenId => weight used for vote (uint224 used to pack for storage optimization)
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _questIdCounter;
    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => EpochalConstruct) public epochalConstructs; // tokenId => EpochalConstruct details
    mapping(address => uint256) public addressToTokenId; // owner address => tokenId (assuming 1 ESC per address for simplicity)

    mapping(uint256 => Quest) public quests; // questId => Quest details
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal details

    address public trustedOracle;
    mapping(address => bool) public whitelistedMinters; // Addresses allowed to mint new ESCs
    uint256 public constant ASCENSION_BASE_XP_REQUIREMENT = 1000;
    uint256 public constant BASE_VOTING_POWER = 100; // Base voting power per ESC
    uint256 public globalEpochalSentimentScore; // Protocol-wide sentiment from oracle (stored as uint, positive only)

    // --- Events ---

    event EpochalConstructMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event ConstructActivityRecorded(uint256 indexed tokenId, ActivityType activityType, uint256 value);
    event ExternalInsightSynced(uint256 indexed tokenId, InsightType insightType, int256 score);
    event ConstructAscended(uint256 indexed tokenId, uint256 newLevel);
    event ConstructMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);

    event QuestProposed(uint256 indexed questId, QuestType questType, uint256 rewardAmount);
    event QuestAccepted(uint256 indexed questId, uint256 indexed tokenId);
    event QuestCompleted(uint256 indexed questId, uint256 indexed tokenId);
    event QuestRewardClaimed(uint256 indexed questId, uint256 indexed tokenId, uint256 rewardAmount);

    event ProposalCreated(uint256 indexed proposalId, ParameterType paramType, int256 newValue, address indexed proposer);
    event VotedOnProposal(uint256 indexed proposalId, uint256 indexed tokenId, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, ParameterType paramType, int256 newValue);

    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event GlobalEpochalMetricsAdjusted(int256 newGlobalSentimentScore);

    event RewardFundsDeposited(address indexed depositor, uint256 amount);
    event ProtocolTreasuryWithdrawn(address indexed recipient, uint256 amount);

    event WhitelistedMinterAdded(address indexed minter);
    event WhitelistedMinterRemoved(address indexed minter);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "ENP: Not the trusted oracle");
        _;
    }

    modifier onlyWhitelistedMinter() {
        require(whitelistedMinters[msg.sender], "ENP: Not a whitelisted minter");
        _;
    }

    modifier onlyConstructOwner(uint256 _tokenId) {
        require(_exists(_tokenId) && ownerOf(_tokenId) == msg.sender, "ENP: Not construct owner");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle) ERC721("Epochal Nexus Construct", "ESC") Ownable(msg.sender) {
        require(_initialOracle != address(0), "ENP: Initial oracle cannot be zero address");
        trustedOracle = _initialOracle;
        whitelistedMinters[msg.sender] = true; // Owner is a whitelisted minter by default
    }

    // --- ERC721 Overrides for Soulbound (Non-Transferable) Tokens ---

    /// @dev Overrides the internal _beforeTokenTransfer function to enforce non-transferability.
    ///      Allows minting (from == address(0)) and burning (to == address(0)), but reverts
    ///      for any other transfer (from != address(0) && to != address(0)).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            revert("ENP: Epochal Constructs are soulbound and non-transferable");
        }
    }

    // --- I. Core Epochal Soulbound Construct (ESC) Management ---

    /// @notice Mints a new non-transferable ESC for the caller.
    ///         Requires the caller to be a whitelisted minter and not already own an ESC.
    /// @param _initialMetadataURI The initial URI for the ESC's metadata, pointing to off-chain data.
    function mintEpochalConstruct(string calldata _initialMetadataURI) external onlyWhitelistedMinter {
        require(addressToTokenId[msg.sender] == 0, "ENP: Caller already owns an ESC");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _initialMetadataURI);

        EpochalConstruct storage newConstruct = epochalConstructs[newTokenId];
        newConstruct.owner = msg.sender;
        newConstruct.level = 1; // Start at level 1
        newConstruct.xp = 0;
        newConstruct.lastActivityTimestamp = block.timestamp;
        newConstruct.metadataURI = _initialMetadataURI;

        addressToTokenId[msg.sender] = newTokenId;

        emit EpochalConstructMinted(newTokenId, msg.sender, _initialMetadataURI);
    }

    /// @notice Retrieves all current basic details for a given ESC.
    /// @param _tokenId The ID of the ESC.
    /// @return owner_ The owner address of the ESC.
    /// @return level_ The current evolutionary level of the ESC.
    /// @return xp_ The current experience points accumulated by the ESC.
    /// @return lastActivityTimestamp_ The timestamp of the last recorded activity for this ESC.
    /// @return metadataURI_ The current metadata URI of the ESC.
    function getEpochalConstructDetails(
        uint256 _tokenId
    ) public view returns (
        address owner_,
        uint256 level_,
        uint256 xp_,
        uint256 lastActivityTimestamp_,
        string memory metadataURI_
    ) {
        require(_exists(_tokenId), "ENP: ESC does not exist");
        EpochalConstruct storage esc = epochalConstructs[_tokenId];
        return (
            esc.owner,
            esc.level,
            esc.xp,
            esc.lastActivityTimestamp,
            esc.metadataURI
        );
    }

    /// @notice Returns the owner address of a specific ESC token ID.
    /// @param _tokenId The ID of the ESC.
    /// @return The owner's address.
    function getEpochalConstructOwner(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId);
    }

    /// @notice Returns the total number of ESCs that have been minted to date.
    /// @return The total count of minted ESCs.
    function getTotalConstructsMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- II. ESC Evolution & Dynamic Attributes ---

    /// @notice Records a specific type of on-chain activity for an ESC, contributing to its internal metrics and XP.
    ///         Only the owner of the ESC can record activity for their construct.
    /// @param _tokenId The ID of the ESC for which to record activity.
    /// @param _type The type of activity (e.g., VOTING_PARTICIPATION, LIQUIDITY_PROVISION).
    /// @param _value The quantitative value associated with the activity (e.g., number of votes, amount of tokens).
    function recordActivityMetric(uint256 _tokenId, ActivityType _type, uint256 _value) external onlyConstructOwner(_tokenId) {
        EpochalConstruct storage esc = epochalConstructs[_tokenId];
        esc.activityMetrics[_type] += _value;
        esc.xp += _value / 10; // Simple XP gain: 10 units of activity = 1 XP
        esc.lastActivityTimestamp = block.timestamp;
        emit ConstructActivityRecorded(_tokenId, _type, _value);
    }

    /// @notice Authorized oracle pushes AI-generated sentiment or other insights for an ESC.
    ///         This function allows external, potentially off-chain AI analysis to influence an ESC's attributes.
    /// @param _tokenId The ID of the ESC to update.
    /// @param _type The type of insight (e.g., SENTIMENT_SCORE, COMMUNITY_HEALTH).
    /// @param _score The integer score of the insight (can be positive or negative).
    /// @param _insightHash A unique hash to ensure data integrity and prevent replay attacks for insights.
    function syncExternalInsight(uint256 _tokenId, InsightType _type, int256 _score, bytes32 _insightHash) external onlyOracle {
        // In a production system, _insightHash could be stored to prevent duplicate insight processing.
        require(_exists(_tokenId), "ENP: ESC does not exist for insight sync");
        EpochalConstruct storage esc = epochalConstructs[_tokenId];
        esc.externalInsights[_type] = _score;

        // Example: Positive sentiment contributes to Community Affinity attribute
        if (_type == InsightType.SENTIMENT_SCORE) {
            if (_score > 0) {
                esc.attributes[AttributeType.COMMUNITY_AFFINITY] += uint256(_score);
            } else {
                // If sentiment is negative, decrease affinity, preventing underflow
                if (esc.attributes[AttributeType.COMMUNITY_AFFINITY] > uint256(uint256(-_score))) {
                    esc.attributes[AttributeType.COMMUNITY_AFFINITY] -= uint256(-_score);
                } else {
                    esc.attributes[AttributeType.COMMUNITY_AFFINITY] = 0;
                }
            }
        }
        emit ExternalInsightSynced(_tokenId, _type, _score);
    }

    /// @notice Allows an ESC owner to attempt an "ascension" (leveling up) if conditions are met.
    ///         Ascension consumes XP and may require certain positive insights or attributes.
    /// @param _tokenId The ID of the ESC to ascend.
    function triggerConstructAscension(uint256 _tokenId) external onlyConstructOwner(_tokenId) {
        EpochalConstruct storage esc = epochalConstructs[_tokenId];
        uint256 requiredXP = ASCENSION_BASE_XP_REQUIREMENT * esc.level; // XP requirement increases with level
        
        require(esc.xp >= requiredXP, "ENP: Not enough XP for ascension");
        
        // Example: Require positive community health insight for ascension
        require(esc.externalInsights[InsightType.COMMUNITY_HEALTH] > 0, "ENP: Community Health insight must be positive for ascension");

        esc.xp -= requiredXP;
        esc.level += 1;
        // Apply attribute gains on ascension, making the ESC more powerful or versatile
        esc.attributes[AttributeType.WISDOM] += 1;
        esc.attributes[AttributeType.AGILITY] += 1;

        emit ConstructAscended(_tokenId, esc.level);
    }

    /// @notice Returns the current evolutionary level of an ESC.
    /// @param _tokenId The ID of the ESC.
    /// @return The level of the construct.
    function getConstructLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ENP: ESC does not exist");
        return epochalConstructs[_tokenId].level;
    }

    /// @notice Retrieves the value of a specific dynamic attribute for an ESC.
    /// @param _tokenId The ID of the ESC.
    /// @param _type The type of attribute to retrieve (e.g., WISDOM, AGILITY).
    /// @return The current value of the specified attribute.
    function getConstructAttribute(uint256 _tokenId, AttributeType _type) public view returns (uint256) {
        require(_exists(_tokenId), "ENP: ESC does not exist");
        return epochalConstructs[_tokenId].attributes[_type];
    }

    /// @notice Allows the ESC owner to update their construct's display metadata URI.
    ///         This could be used for dynamic visuals or to reflect on-chain state.
    /// @param _tokenId The ID of the ESC.
    /// @param _newMetadataURI The new URI for the ESC's metadata.
    function updateConstructMetadata(string calldata _newMetadataURI, uint256 _tokenId) external onlyConstructOwner(_tokenId) {
        // Potential future feature: Add a cooldown, cost, or level requirement for updates.
        _setTokenURI(_tokenId, _newMetadataURI);
        epochalConstructs[_tokenId].metadataURI = _newMetadataURI;
        emit ConstructMetadataUpdated(_tokenId, _newMetadataURI);
    }

    // --- III. Gamified Quest & Challenge System ---

    /// @notice Governance proposes a new quest for ESC holders to complete.
    ///         This function can be called by the contract owner, or eventually, via a passed governance proposal.
    /// @param _type The type of quest (e.g., GOVERNANCE_PARTICIPATION, LEVEL_ACHIEVEMENT).
    /// @param _rewardAmount The reward in native currency (ETH) for successful completion of the quest.
    /// @param _threshold A generic threshold for quest completion (e.g., target level, minimum vote count).
    /// @param _ipfsHash IPFS hash linking to a detailed off-chain description of the quest rules.
    function proposeQuest(
        QuestType _type,
        uint256 _rewardAmount,
        uint256 _threshold,
        string calldata _ipfsHash
    ) external onlyOwner { // In a full DAO, this would be `onlyRole(GOVERNANCE_ADMIN_ROLE)`
        _questIdCounter.increment();
        uint256 newQuestId = _questIdCounter.current();

        quests[newQuestId] = Quest({
            id: newQuestId,
            questType: _type,
            rewardAmount: _rewardAmount,
            threshold: _threshold,
            ipfsHash: _ipfsHash,
            isActive: true,
            proposer: msg.sender,
            expirationTime: block.timestamp + 7 days, // Quests are active for 7 days by default
            participants: new mapping(uint256 => bool), // Initialize empty mapping
            completions: new mapping(uint256 => bool)   // Initialize empty mapping
        });

        emit QuestProposed(newQuestId, _type, _rewardAmount);
    }

    /// @notice Allows an ESC owner to formally accept a quest, registering their intent to participate.
    /// @param _questId The ID of the quest to accept.
    function acceptQuest(uint256 _questId) external {
        require(quests[_questId].id != 0, "ENP: Quest does not exist");
        require(quests[_questId].isActive && block.timestamp < quests[_questId].expirationTime, "ENP: Quest is not active or has expired");
        uint256 tokenId = addressToTokenId[msg.sender];
        require(tokenId != 0, "ENP: Caller does not own an ESC to accept quests");
        require(!quests[_questId].participants[tokenId], "ENP: ESC has already accepted this quest");

        quests[_questId].participants[tokenId] = true;
        emit QuestAccepted(_questId, tokenId);
    }

    /// @notice Called by an authorized oracle or a designated verifier to mark a quest as complete for a specific ESC.
    ///         This function relies on off-chain verification logic for complex quest conditions.
    /// @param _questId The ID of the quest.
    /// @param _tokenId The ID of the ESC for which to verify completion.
    function verifyQuestCompletion(uint256 _questId, uint256 _tokenId) external onlyOracle { // Or a specific VERIFIER_ROLE
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "ENP: Quest does not exist");
        require(quest.isActive || block.timestamp < quest.expirationTime + 1 days, "ENP: Quest is expired for verification"); // Small grace period
        require(quest.participants[_tokenId], "ENP: ESC did not accept this quest");
        require(!quest.completions[_tokenId], "ENP: Quest already marked as complete for this ESC");
        
        // This section is a simplified placeholder for complex off-chain verification.
        // In a real dApp, the oracle would provide a proof of completion for the specific quest type
        // (e.g., signed message confirming X governance votes by tokenId).
        bool completed = false;
        if (quest.questType == QuestType.LEVEL_ACHIEVEMENT) {
            completed = epochalConstructs[_tokenId].level >= quest.threshold;
        } else if (quest.questType == QuestType.GOVERNANCE_PARTICIPATION) {
            completed = epochalConstructs[_tokenId].activityMetrics[ActivityType.VOTING_PARTICIPATION] >= quest.threshold;
        } else {
            // For other quest types (e.g., TOKEN_STAKE_DURATION, LP_CONTRIBUTION),
            // a sophisticated oracle system like Chainlink would fetch real-world data or on-chain state.
            // For this example, we assume the oracle's call implies verification for other types.
            completed = true; // Oracle confirms completion for generic types
        }

        require(completed, "ENP: Quest conditions not met (as per oracle check)");

        quest.completions[_tokenId] = true;
        emit QuestCompleted(_questId, _tokenId);
    }

    /// @notice Allows an ESC owner to claim rewards for a quest once it has been verified as complete.
    /// @param _questId The ID of the quest.
    /// @param _tokenId The ID of the ESC claiming the reward.
    function claimQuestReward(uint256 _questId, uint256 _tokenId) external onlyConstructOwner(_tokenId) {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "ENP: Quest does not exist");
        require(quest.completions[_tokenId], "ENP: Quest not verified complete for this ESC");
        require(quest.rewardAmount > 0, "ENP: Reward already claimed or no reward set"); 

        uint256 reward = quest.rewardAmount;
        quest.rewardAmount = 0; // Set reward to 0 for this quest instance to prevent re-claiming
        
        (bool success,) = payable(msg.sender).call{value: reward}("");
        require(success, "ENP: Failed to send reward");

        // Record quest completion as an activity metric for the ESC
        recordActivityMetric(_tokenId, ActivityType.QUEST_COMPLETION, 1); // Mark one quest completion
        
        emit QuestRewardClaimed(_questId, _tokenId, reward);
    }

    /// @notice Returns a list of currently active and available quests.
    /// @return An array of active quest IDs that are still within their expiration time.
    function getAvailableQuests() public view returns (uint256[] memory) {
        uint256 currentCount = _questIdCounter.current();
        uint256[] memory tempActiveQuestIds = new uint256[](currentCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= currentCount; i++) {
            // Check if quest exists, is active, and not expired
            if (quests[i].id != 0 && quests[i].isActive && block.timestamp < quests[i].expirationTime) {
                tempActiveQuestIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempActiveQuestIds[i];
        }
        return result;
    }

    // --- IV. Adaptive Protocol Parameters & Governance ---

    /// @notice Allows qualified ESC holders to propose changes to core protocol parameters.
    ///         Requires a minimum ESC level to propose.
    /// @param _param The type of parameter to be adjusted (e.g., QUEST_DIFFICULTY_MULTIPLIER).
    /// @param _newValue The proposed new integer value for the parameter (can be positive or negative for adjustments).
    /// @param _description A detailed description of the proposal.
    function proposeParameterAdjustment(
        ParameterType _param,
        int256 _newValue,
        string calldata _description
    ) external {
        uint256 proposerTokenId = addressToTokenId[msg.sender];
        require(proposerTokenId != 0, "ENP: Proposer must own an ESC");
        require(epochalConstructs[proposerTokenId].level >= 5, "ENP: ESC level too low to propose (min level 5)"); // Example requirement

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            paramType: _param,
            newValue: _newValue,
            description: _description,
            voteCountYes: 0,
            voteCountNo: 0,
            snapshotBlock: block.number, // Voting power snapshot at proposal creation
            expirationTime: block.timestamp + 3 days, // 3-day voting period
            executed: false,
            hasVoted: new mapping(uint256 => bool),
            voterWeight: new mapping(uint224 => uint256) // uint224 for token ID
        });

        emit ProposalCreated(newProposalId, _param, _newValue, msg.sender);
    }

    /// @notice Allows ESC holders to vote on active governance proposals.
    ///         Voting power is dynamically weighted by the ESC's level and attributes at the time of voting.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote 'yes' (support), false to vote 'no' (against).
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ENP: Proposal does not exist");
        require(block.timestamp < proposal.expirationTime, "ENP: Voting period has ended");

        uint256 voterTokenId = addressToTokenId[msg.sender];
        require(voterTokenId != 0, "ENP: Voter must own an ESC");
        require(!proposal.hasVoted[voterTokenId], "ENP: Already voted on this proposal");

        // Calculate dynamic voting power based on current ESC attributes.
        // A more advanced system might use a historical snapshot of attributes.
        uint256 votingPower = BASE_VOTING_POWER;
        votingPower += epochalConstructs[voterTokenId].level * 5; // Higher level = more power
        votingPower += epochalConstructs[voterTokenId].attributes[AttributeType.COMMUNITY_AFFINITY] / 100; // Community affinity boosts power

        if (_support) {
            proposal.voteCountYes += votingPower;
        } else {
            proposal.voteCountNo += votingPower;
        }
        proposal.hasVoted[voterTokenId] = true;
        
        // Store the exact weight used by this voter for transparency and potential re-counting.
        // Cast voterTokenId to uint224 as keys in a mapping can be smaller than 256
        proposal.voterWeight[uint224(voterTokenId)] = votingPower; 

        emit VotedOnProposal(_proposalId, voterTokenId, _support, votingPower);
    }

    /// @notice Executes a successfully passed governance proposal, applying the proposed parameter change.
    ///         Can only be called after the voting period has ended and if the proposal passed.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ENP: Proposal does not exist");
        require(!proposal.executed, "ENP: Proposal already executed");
        require(block.timestamp >= proposal.expirationTime, "ENP: Voting period not ended");

        // Simple majority rule: more 'yes' votes than 'no' votes.
        require(proposal.voteCountYes > proposal.voteCountNo, "ENP: Proposal did not pass (not enough 'yes' votes)");
        
        // Additional threshold: Require a minimum total 'yes' votes to prevent low-participation proposals from passing.
        require(proposal.voteCountYes >= 1000, "ENP: Not enough total 'yes' votes to meet quorum (min 1000)");

        proposal.executed = true;

        // Apply the parameter change based on the proposal type.
        // In a real system, these would update relevant state variables.
        if (proposal.paramType == ParameterType.QUEST_DIFFICULTY_MULTIPLIER) {
            // _questDifficultyMultiplier = uint256(proposal.newValue); // Example: updates a state variable
        } else if (proposal.paramType == ParameterType.ASCENSION_XP_REQUIREMENT) {
            // baseAscensionXPRequirement = uint256(proposal.newValue); // Example: updates a state variable
        } else if (proposal.paramType == ParameterType.GOVERNANCE_VOTE_THRESHOLD) {
            // minVoteThreshold = uint256(proposal.newValue); // Example: updates a state variable
        }
        // Add more `else if` conditions for other `ParameterType` values.

        emit ProposalExecuted(_proposalId, proposal.paramType, proposal.newValue);
    }

    /// @notice Allows the protocol owner/governance to update the trusted oracle address.
    /// @param _newOracle The address of the new trusted oracle.
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "ENP: New oracle address cannot be zero");
        address oldOracle = trustedOracle;
        trustedOracle = _newOracle;
        emit OracleAddressUpdated(oldOracle, _newOracle);
    }

    /// @notice Authorized by the oracle, this function adjusts protocol-wide metrics or parameters based on global sentiment.
    ///         This introduces a layer of automated adaptability to the protocol based on external data.
    /// @param _globalSentimentScore The overall sentiment score for the protocol, provided by the oracle (can be negative).
    function adjustEpochalMetrics(int256 _globalSentimentScore) external onlyOracle {
        // Store the sentiment score. Convert to uint for storage, handling negative as zero for positive-only metrics.
        globalEpochalSentimentScore = _globalSentimentScore > 0 ? uint256(_globalSentimentScore) : 0;
        
        // This score can be used to dynamically adjust various protocol behaviors:
        // - Increase/decrease future quest rewards based on positive/negative sentiment.
        // - Modify the difficulty of challenges.
        // - Influence attribute decay or growth rates.
        // Example: If sentiment is very positive, next quest might have a bonus reward.
        // If sentiment is negative, some penalties or harder quests might appear.

        emit GlobalEpochalMetricsAdjusted(_globalSentimentScore);
    }

    // --- V. Reward & Treasury Management ---

    /// @notice Allows any user to deposit native currency (e.g., ETH) into the contract's reward pool.
    ///         These funds will be used to pay out quest rewards.
    function depositRewardFunds() external payable {
        require(msg.value > 0, "ENP: Must deposit a positive amount");
        emit RewardFundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the protocol owner/governance to withdraw native currency from the contract's treasury.
    ///         This is for managing operational costs or unallocated funds.
    /// @param _to The recipient address for the withdrawn funds.
    /// @param _amount The amount of native currency to withdraw.
    function withdrawProtocolTreasury(address _to, uint252 _amount) external onlyOwner { // Using uint252 to demonstrate different int sizes
        require(_amount > 0, "ENP: Amount must be positive");
        require(address(this).balance >= _amount, "ENP: Insufficient contract balance");
        
        (bool success,) = payable(_to).call{value: _amount}("");
        require(success, "ENP: Failed to withdraw from treasury");
        emit ProtocolTreasuryWithdrawn(_to, _amount);
    }

    // --- VI. Access Control & Whitelisting ---

    /// @notice Allows the protocol owner to add an address to the whitelist of minters.
    ///         Whitelisted addresses can mint new ESCs.
    /// @param _minter The address to whitelist.
    function addWhitelistedMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "ENP: Minter address cannot be zero");
        whitelistedMinters[_minter] = true;
        emit WhitelistedMinterAdded(_minter);
    }

    /// @notice Allows the protocol owner to remove an address from the whitelist of minters.
    /// @param _minter The address to remove from the whitelist.
    function removeWhitelistedMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "ENP: Minter address cannot be zero");
        whitelistedMinters[_minter] = false;
        emit WhitelistedMinterRemoved(_minter);
    }
}
```