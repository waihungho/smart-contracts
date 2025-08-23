Here's a Solidity smart contract, `ChronicleForge`, designed around the concept of "Adaptive Digital Souls" (dNFTs). It combines dynamic NFTs, a "Soulbound Token" (SBT) system for achievements, AI oracle integration for semantic interpretations, decentralized community governance, and a gamified reputation and quest system. The goal is to create a dynamic, evolving on-chain experience that reacts to both user actions and external "AI-whispered" contexts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For reputation +/-

/**
 * @title ChronicleForge - Adaptive Digital Souls (dNFTs)
 * @author YourName (inspired by various advanced blockchain concepts)
 * @notice This contract manages unique, evolving "Digital Soul" NFTs (dNFTs) whose traits
 *         and visual representations dynamically change based on user actions,
 *         interpretations from an AI Whisperer Oracle, and community governance decisions.
 *
 * Outline:
 * I. Core Infrastructure & Ownership: Basic setup, pausing, and ETH management.
 * II. Digital Soul (dNFT) Management: ERC721 extension with dynamic traits and evolution mechanics.
 * III. Chronicle Shards (Soulbound Token - SBT) Management: Non-transferable tokens for achievements.
 * IV. AI Whisperer Oracle Integration & Soul Evolution Logic: Consumes semantic data from a trusted oracle
 *     to influence dNFT progression.
 * V. Lore Decisions (Decentralized Governance / Community Direction): Community voting on narrative
 *    elements or evolution parameters that affect the global state and individual dNFTs.
 * VI. Ephemeral Quests & Reputation System: Time-sensitive tasks that reward users with reputation
 *     and Chronicle Shards, influencing their capabilities and dNFT evolution.
 * VII. Dynamic Pricing / Tribute System: Adjustable fees for minting dNFTs.
 */
contract ChronicleForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For reputation and other uint256 calculations

    // --- I. Core Infrastructure & Ownership ---
    address private aiWhispererOracle;
    uint256 public forgingFee = 0.01 ether; // Default fee for forging a new Digital Soul
    uint256 public minReputationForProposal = 100; // Minimum reputation required to propose Lore Decisions

    // Events for transparency and off-chain monitoring
    event AIWhispererOracleUpdated(address indexed newOracle);
    event ForgingFeeUpdated(uint256 newFee);
    event SoulForged(address indexed owner, uint256 indexed tokenId, string initialLoreHash);
    event SoulMetamorphosed(uint256 indexed tokenId, uint256 newLevel, string newMetadataHash);
    event ChronicleShardAwarded(address indexed recipient, uint256 indexed shardId);
    event ChronicleShardBurned(address indexed burner, uint256 indexed shardId);
    event OracleInterpretationReceived(uint256 sentimentScore, uint256 trendId, string interpretationHash);
    event SoulInfluenceProcessed(uint256 indexed tokenId, uint256 newExperience, uint256 newLevel);
    event LoreDecisionProposed(uint256 indexed proposalId, address indexed proposer, string proposalHash, uint256 endTime);
    event LoreDecisionVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event LoreDecisionTallied(uint256 indexed proposalId, bool approved, string loreSegmentHash);
    event EphemeralQuestCreated(uint256 indexed questId, string questHash, uint256 endTime);
    event EphemeralQuestCompleted(uint256 indexed questId, address indexed completer, uint256 reputationReward, uint256 shardIdReward);
    event ReputationAdjusted(address indexed user, int256 delta, uint256 newReputation);

    /**
     * @notice Constructor to initialize the contract.
     * @param _oracleAddress The address of the trusted AI Whisperer Oracle contract.
     */
    constructor(address _oracleAddress) ERC721("Digital Soul", "SOUL") Ownable(msg.sender) {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        aiWhispererOracle = _oracleAddress;
        _pause(); // Contract starts paused for initial setup and security
        emit AIWhispererOracleUpdated(_oracleAddress);
    }

    /**
     * @dev Modifier to restrict calls only to the designated AI Whisperer Oracle.
     */
    modifier onlyAIWhispererOracle() {
        require(msg.sender == aiWhispererOracle, "Only AI Whisperer Oracle can call this function");
        _;
    }

    /**
     * @notice Updates the address of the AI Whisperer Oracle.
     * @dev Only the contract owner can call this.
     * @param _newOracleAddress The new address for the AI Whisperer Oracle.
     * @custom:function-number 1
     */
    function setAIWhispererOracle(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "Oracle address cannot be zero");
        aiWhispererOracle = _newOracleAddress;
        emit AIWhispererOracleUpdated(_newOracleAddress);
    }

    /**
     * @notice Pauses contract functionality in case of emergencies.
     * @dev Only the contract owner can call this.
     * @custom:function-number 2
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract functionality.
     * @dev Only the contract owner can call this.
     * @custom:function-number 3
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the contract owner to withdraw collected ETH (e.g., from forging fees).
     * @dev Only the contract owner can call this.
     * @custom:function-number 4
     */
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    // --- II. Digital Soul (dNFT) Management (ERC721 Extension) ---
    Counters.Counter private _tokenIdCounter;

    // Structure defining the dynamic traits of a Digital Soul
    struct SoulTraits {
        uint256 creationTime;
        uint256 currentLevel;
        string currentMetadataHash; // IPFS hash or similar for the dNFT's current visual/data representation
        uint256 accumulatedExperience; // XP points towards next level/metamorphosis
        uint256 lastOracleInfluenceTime; // Timestamp of last update based on oracle data
        uint256 lastMetamorphosisTime; // Timestamp of last major evolution event
        string initialLoreHash; // Immutable initial lore/seed for the soul
    }

    mapping(uint256 => SoulTraits) public soulDetails; // tokenId => SoulTraits

    /**
     * @notice Mints a new "Digital Soul" dNFT to the caller.
     * @dev Requires payment of the `forgingFee`. The `_initialLoreHash` can represent a unique
     *      starting point or theme for the dNFT.
     * @param _initialLoreHash An IPFS hash or similar identifier for the soul's initial lore/appearance.
     * @return The ID of the newly minted Digital Soul.
     * @custom:function-number 5
     */
    function forgeSoul(string memory _initialLoreHash) external payable whenNotPaused returns (uint256) {
        require(msg.value >= forgingFee, "Insufficient ETH for forging");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);

        soulDetails[newTokenId] = SoulTraits({
            creationTime: block.timestamp,
            currentLevel: 1,
            currentMetadataHash: _initialLoreHash, // Initial hash set at mint
            accumulatedExperience: 0,
            lastOracleInfluenceTime: block.timestamp,
            lastMetamorphosisTime: block.timestamp,
            initialLoreHash: _initialLoreHash
        });

        emit SoulForged(msg.sender, newTokenId, _initialLoreHash);
        return newTokenId;
    }

    /**
     * @notice Retrieves the current dynamic traits of a specific Digital Soul.
     * @param _tokenId The ID of the Digital Soul.
     * @return A `SoulTraits` struct containing all current details.
     * @custom:function-number 6
     */
    function getSoulTraits(uint256 _tokenId) public view returns (SoulTraits memory) {
        require(_exists(_tokenId), "Soul does not exist");
        return soulDetails[_tokenId];
    }

    /**
     * @notice Initiates a significant evolution step (Metamorphosis) for a Digital Soul.
     * @dev This is typically triggered by the dNFT owner when certain conditions (e.g., accumulated experience,
     *      time elapsed, specific Chronicle Shards held, global lore state) are met.
     * @param _tokenId The ID of the Digital Soul to metamorphose.
     * @custom:function-number 7
     */
    function triggerSoulMetamorphosis(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Soul does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only soul owner can trigger metamorphosis");

        SoulTraits storage soul = soulDetails[_tokenId];

        // Example complex condition for metamorphosis:
        // Requires sufficient accumulated experience AND a cooldown period since last metamorphosis.
        // In a full system, this would involve factors like:
        // - `soul.accumulatedExperience >= (soul.currentLevel.mul(1000))`
        // - `block.timestamp >= soul.lastMetamorphosisTime.add(7 days)`
        // - Checking for specific `Chronicle Shards` (e.g., `hasChronicleShard(msg.sender, SOME_SHARD_ID)`)
        // - Influence of `currentGlobalLoreSegmentHash`
        // - Latest `OracleInterpretation` parameters
        // For this example, we'll use a simplified XP and time-based condition.
        if (soul.accumulatedExperience >= (soul.currentLevel.mul(1000)) && block.timestamp >= soul.lastMetamorphosisTime.add(7 days)) {
            soul.currentLevel = soul.currentLevel.add(1);
            soul.accumulatedExperience = 0; // Reset XP or carry over remainder
            soul.lastMetamorphosisTime = block.timestamp;

            // Generate a new metadata hash based on the new level and other factors (off-chain generation implied).
            // This string would be the new IPFS CID for the dNFT's JSON metadata.
            string memory newMetadataHash = _generateNewMetadataHash(_tokenId, soul.currentLevel);
            soul.currentMetadataHash = newMetadataHash;

            emit SoulMetamorphosed(_tokenId, soul.currentLevel, newMetadataHash);
        } else {
            revert("Soul not ready for metamorphosis or conditions not met");
        }
    }

    /**
     * @dev Internal helper function to simulate generating a new metadata hash.
     *      In a real dNFT, an off-chain service would process on-chain traits to
     *      create new visual assets and JSON metadata, then upload to IPFS.
     *      This function would return the new IPFS CID.
     */
    function _generateNewMetadataHash(uint256 _tokenId, uint256 _newLevel) internal view returns (string memory) {
        // Placeholder for a complex off-chain metadata generation logic.
        // It should use _tokenId, _newLevel, currentGlobalLoreSegmentHash, and possibly
        // details from latestOracleInterpretation to produce a unique hash.
        return string(abi.encodePacked("ipfs://soul/", Strings.toString(_tokenId), "_L", Strings.toString(_newLevel), "_lore_", currentGlobalLoreSegmentHash, "_t", Strings.toString(block.timestamp)));
    }

    /**
     * @notice Manually updates the metadata hash for a Digital Soul.
     * @dev This can be called by the dNFT owner to push a new metadata hash (e.g., if an off-chain
     *      renderer created a new version) or by the contract owner for administrative purposes.
     * @param _tokenId The ID of the Digital Soul.
     * @param _newHash The new IPFS hash for the dNFT's metadata.
     * @custom:function-number 8
     */
    function updateSoulMetadataHash(uint256 _tokenId, string memory _newHash) external {
        require(_exists(_tokenId), "Soul does not exist");
        require(ownerOf(_tokenId) == msg.sender || msg.sender == owner(), "Only soul owner or contract owner can update metadata hash");
        soulDetails[_tokenId].currentMetadataHash = _newHash;
        emit SoulMetamorphosed(_tokenId, soulDetails[_tokenId].currentLevel, _newHash); // Re-use event for clarity
    }

    /**
     * @notice Overrides ERC721 `tokenURI` to provide the dynamic metadata URL.
     * @dev The URI points to the current metadata hash stored on-chain. An off-chain
     *      resolver (e.g., IPFS gateway) would use this hash to display the dNFT.
     * @param _tokenId The ID of the Digital Soul.
     * @return The URI (typically an IPFS hash) for the dNFT's current metadata.
     * @custom:function-number 9
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return soulDetails[_tokenId].currentMetadataHash;
    }
    // `renounceOwnership` and `transferOwnership` are inherited from Ownable and are available.
    // custom:function-number 10 (renounceOwnership)
    // custom:function-number 11 (transferOwnership)


    // --- III. Chronicle Shards (Soulbound Token - SBT) Management ---
    // Mapping to track which user possesses which Shard (non-transferable, "soulbound")
    mapping(uint256 => mapping(address => bool)) private userChronicleShards; // shardId => userAddress => hasShard

    /**
     * @notice Awards a specific non-transferable "Chronicle Shard" to a user.
     * @dev Shards represent achievements, temporary buffs, or access rights and cannot be transferred.
     *      Only the contract owner can award shards.
     * @param _recipient The address to receive the shard.
     * @param _shardId The ID of the shard to award.
     * @custom:function-number 12
     */
    function awardChronicleShard(address _recipient, uint256 _shardId) public onlyOwner whenNotPaused {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(!userChronicleShards[_shardId][_recipient], "User already holds this shard");
        userChronicleShards[_shardId][_recipient] = true;
        emit ChronicleShardAwarded(_recipient, _shardId);
    }

    /**
     * @notice Allows a user to burn their own Chronicle Shard.
     * @dev Burning a shard can activate a temporary effect, reset a cooldown, or unlock a new path.
     *      The specific effect of burning is part of the off-chain game logic or future contract upgrades.
     * @param _shardId The ID of the shard to burn.
     * @custom:function-number 13
     */
    function burnChronicleShard(uint256 _shardId) external whenNotPaused {
        require(userChronicleShards[_shardId][msg.sender], "Caller does not possess this shard");
        userChronicleShards[_shardId][msg.sender] = false;
        // Further logic for the effect of burning the shard could go here.
        emit ChronicleShardBurned(msg.sender, _shardId);
    }

    /**
     * @notice Checks if a user possesses a specific Chronicle Shard.
     * @param _user The address of the user.
     * @param _shardId The ID of the shard.
     * @return True if the user has the shard, false otherwise.
     * @custom:function-number 14
     */
    function hasChronicleShard(address _user, uint256 _shardId) public view returns (bool) {
        return userChronicleShards[_shardId][_user];
    }

    // --- IV. AI Whisperer Oracle Integration & Soul Evolution Logic ---
    struct OracleInterpretation {
        uint256 sentimentScore; // e.g., -100 to 100 for market sentiment, cultural mood, etc.
        uint256 trendId;        // e.g., ID representing a specific global trend detected by AI
        string interpretationHash; // IPFS hash of a detailed AI interpretation/narrative summary
        uint256 timestamp;
    }

    OracleInterpretation public latestOracleInterpretation;

    /**
     * @notice Submits new AI-driven interpretations from the designated AI Whisperer Oracle.
     * @dev This is a critical integration point for external AI models. The AI analyzes real-world
     *      data and provides a structured interpretation to the blockchain.
     * @param _sentimentScore A numerical score representing the overall sentiment or mood.
     * @param _trendId An ID representing a detected global trend or event category.
     * @param _interpretationHash IPFS hash of a detailed text interpretation or narrative.
     * @custom:function-number 15
     */
    function submitOracleInterpretation(uint256 _sentimentScore, uint256 _trendId, string memory _interpretationHash) external onlyAIWhispererOracle whenNotPaused {
        latestOracleInterpretation = OracleInterpretation({
            sentimentScore: _sentimentScore,
            trendId: _trendId,
            interpretationHash: _interpretationHash,
            timestamp: block.timestamp
        });
        emit OracleInterpretationReceived(_sentimentScore, _trendId, _interpretationHash);
    }

    /**
     * @notice Retrieves the latest submitted AI interpretation data.
     * @return The sentiment score, trend ID, interpretation hash, and timestamp of the latest oracle update.
     * @custom:function-number 16
     */
    function getLatestOracleInterpretation() public view returns (uint256 sentimentScore, uint256 trendId, string memory interpretationHash, uint256 timestamp) {
        return (latestOracleInterpretation.sentimentScore, latestOracleInterpretation.trendId, latestOracleInterpretation.interpretationHash, latestOracleInterpretation.timestamp);
    }

    /**
     * @notice Processes the latest AI oracle data to influence a specific dNFT's evolution.
     * @dev This function makes the dNFT owner responsible for "feeding" their soul with new information
     *      from the AI Whisperer Oracle. The oracle's interpretations directly impact the dNFT's accumulated
     *      experience and potentially unlock specific evolutionary paths.
     * @param _tokenId The ID of the Digital Soul to influence.
     * @custom:function-number 17
     */
    function processOracleInfluence(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Soul does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only soul owner can process oracle influence");
        require(latestOracleInterpretation.timestamp > 0, "No oracle data has been submitted yet");
        require(latestOracleInterpretation.timestamp > soulDetails[_tokenId].lastOracleInfluenceTime, "No new oracle data to process for this soul");

        SoulTraits storage soul = soulDetails[_tokenId];

        // Example logic: Oracle's sentiment score directly impacts soul's experience.
        // Positive sentiment might increase XP, negative might decrease it or add challenges.
        if (latestOracleInterpretation.sentimentScore > 50) {
            soul.accumulatedExperience = soul.accumulatedExperience.add(200); // More XP for strong positive trends
        } else if (latestOracleInterpretation.sentimentScore > 0) {
            soul.accumulatedExperience = soul.accumulatedExperience.add(50);
        } else if (latestOracleInterpretation.sentimentScore < -50) {
            if (soul.accumulatedExperience >= 100) { // Penalize for strong negative trends
                soul.accumulatedExperience = soul.accumulatedExperience.sub(100);
            } else {
                soul.accumulatedExperience = 0;
            }
        }
        // Further complex logic could involve `latestOracleInterpretation.trendId`
        // unlocking specific traits, temporary buffs/debuffs, or changing metamorphosis conditions.

        soul.lastOracleInfluenceTime = latestOracleInterpretation.timestamp;
        emit SoulInfluenceProcessed(_tokenId, soul.accumulatedExperience, soul.currentLevel);
        // Note: Direct metadata hash update from here is possible but often left to `triggerSoulMetamorphosis`
        // to bundle significant changes, or `updateSoulMetadataHash` for minor trait updates.
    }


    // --- V. Lore Decisions (Decentralized Governance / Community Direction) ---
    Counters.Counter private _proposalIdCounter;

    enum ProposalStatus { Open, Approved, Rejected, Expired }

    struct LoreDecision {
        address proposer;
        string proposalHash; // IPFS hash of proposal details (e.g., narrative, new rule set, dNFT path)
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalStatus status;
        string outcomeLoreSegmentHash; // New global lore segment if proposal is approved
    }

    mapping(uint256 => LoreDecision) public loreDecisions;
    string public currentGlobalLoreSegmentHash = "initial_lore_segment"; // Global state influenced by governance

    /**
     * @notice Allows users (with sufficient reputation) to propose new lore segments or evolutionary paths.
     * @dev A proposal can represent a community-driven decision that influences the game's narrative,
     *      dNFT evolution rules, or future contract parameters.
     * @param _proposalHash An IPFS hash detailing the proposal content.
     * @param _endTime The timestamp when voting for this proposal ends.
     * @return The ID of the newly created proposal.
     * @custom:function-number 18
     */
    function proposeLoreDecision(string memory _proposalHash, uint256 _endTime) external whenNotPaused returns (uint256) {
        require(getUserReputation(msg.sender) >= minReputationForProposal, "Insufficient reputation to propose");
        require(_endTime > block.timestamp, "End time must be in the future");
        
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        loreDecisions[proposalId] = LoreDecision({
            proposer: msg.sender,
            proposalHash: _proposalHash,
            startTime: block.timestamp,
            endTime: _endTime,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Open,
            outcomeLoreSegmentHash: ""
        });
        // `loreDecisions[proposalId].hasVoted` is automatically initialized as an empty mapping.

        emit LoreDecisionProposed(proposalId, msg.sender, _proposalHash, _endTime);
        return proposalId;
    }

    /**
     * @notice Allows users to vote on an active lore decision proposal.
     * @dev Voting power can be based on various factors (e.g., number of dNFTs owned, reputation,
     *      specific Chronicle Shards). For simplicity, this example uses 1 address = 1 vote.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for" (yes) vote, false for "against" (no) vote.
     * @custom:function-number 19
     */
    function voteOnLoreDecision(uint256 _proposalId, bool _support) external whenNotPaused {
        LoreDecision storage proposal = loreDecisions[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Open, "Proposal is not open for voting");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 votingPower = 1; // Simplistic: 1 address, 1 vote. Could be getUserReputation(msg.sender) / 100
        // Or based on count of dNFTs: `balanceOf(msg.sender)` for weighted voting.

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;
        
        emit LoreDecisionVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Tallies votes for a proposal and applies its outcome if approved.
     * @dev This can be called by anyone after the voting period has ended. If approved,
     *      the `currentGlobalLoreSegmentHash` is updated, influencing all dNFTs and future gameplay.
     * @param _proposalId The ID of the proposal to tally.
     * @custom:function-number 20
     */
    function tallyLoreDecision(uint256 _proposalId) external whenNotPaused {
        LoreDecision storage proposal = loreDecisions[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Open, "Proposal is not open for tallying");
        require(block.timestamp > proposal.endTime, "Voting period has not ended yet");

        bool approved = proposal.votesFor > proposal.votesAgainst;
        proposal.status = approved ? ProposalStatus.Approved : ProposalStatus.Rejected;

        if (approved) {
            // The proposal hash becomes the new global lore segment, affecting all dNFTs.
            proposal.outcomeLoreSegmentHash = proposal.proposalHash;
            currentGlobalLoreSegmentHash = proposal.outcomeLoreSegmentHash;
            // Optionally, grant reputation to voters or burn specific shards as part of the outcome.
        }

        emit LoreDecisionTallied(_proposalId, approved, proposal.outcomeLoreSegmentHash);
    }

    /**
     * @notice Returns the hash of the currently active "Lore Segment" influencing the world state.
     * @return The IPFS hash or identifier of the current global lore segment.
     * @custom:function-number 21
     */
    function getCurrentLoreSegment() public view returns (string memory) {
        return currentGlobalLoreSegmentHash;
    }

    /**
     * @notice Sets the minimum reputation required for a user to propose a Lore Decision.
     * @dev Only the contract owner can change this parameter.
     * @param _minRep The new minimum reputation score.
     * @custom:function-number 22
     */
    function setMinReputationForProposal(uint256 _minRep) external onlyOwner {
        minReputationForProposal = _minRep;
    }

    /**
     * @notice Returns the current minimum reputation required to propose Lore Decisions.
     * @return The minimum reputation score.
     * @custom:function-number 23
     */
    function getMinReputationForProposal() public view returns (uint256) {
        return minReputationForProposal;
    }

    // --- VI. Ephemeral Quests & Reputation System ---
    Counters.Counter private _questIdCounter;

    enum QuestStatus { Active, Completed, Expired }

    struct EphemeralQuest {
        address creator;
        string questHash; // IPFS hash of quest details (instructions, goals)
        uint256 startTime;
        uint256 endTime;
        uint256 reputationReward;
        uint256 shardIdReward; // If > 0, a Chronicle Shard is awarded upon completion
        QuestStatus status;
    }

    mapping(uint256 => EphemeralQuest) public ephemeralQuests;
    mapping(address => uint256) private userReputation; // Simple reputation score for users

    /**
     * @notice Creates a new time-sensitive "Ephemeral Quest."
     * @dev Only the contract owner can define new quests. Quests provide goals for users
     *      and reward them with reputation and/or Chronicle Shards.
     * @param _questHash IPFS hash detailing the quest objectives.
     * @param _reputationReward The amount of reputation gained upon completion.
     * @param _shardIdReward The ID of the Chronicle Shard awarded (0 if no shard).
     * @param _endTime The timestamp when the quest expires.
     * @return The ID of the newly created quest.
     * @custom:function-number 24
     */
    function createEphemeralQuest(string memory _questHash, uint256 _reputationReward, uint256 _shardIdReward, uint256 _endTime) external onlyOwner whenNotPaused returns (uint256) {
        require(_endTime > block.timestamp, "End time must be in the future");

        _questIdCounter.increment();
        uint256 questId = _questIdCounter.current();

        ephemeralQuests[questId] = EphemeralQuest({
            creator: msg.sender,
            questHash: _questHash,
            startTime: block.timestamp,
            endTime: _endTime,
            reputationReward: _reputationReward,
            shardIdReward: _shardIdReward,
            status: QuestStatus.Active
        });

        emit EphemeralQuestCreated(questId, _questHash, _endTime);
        return questId;
    }

    /**
     * @notice Allows a user to complete an Ephemeral Quest.
     * @dev The `_proof` parameter is a placeholder. In a real advanced system, this could involve:
     *      - On-chain verification of a specific transaction or contract interaction.
     *      - Submission of a ZKP proof for an off-chain action.
     *      - A signed attestation from a trusted third party.
     *      For this example, we add a simple on-chain reputation prerequisite and assume external
     *      verification for complex `_proof`s.
     * @param _questId The ID of the quest being completed.
     * @param _proof Placeholder for verifiable proof of quest completion (e.g., hash, signature, ZKP).
     * @custom:function-number 25
     */
    function completeEphemeralQuest(uint256 _questId, bytes memory _proof) external whenNotPaused {
        EphemeralQuest storage quest = ephemeralQuests[_questId];
        require(quest.creator != address(0), "Quest does not exist");
        require(quest.status == QuestStatus.Active, "Quest is not active");
        require(block.timestamp <= quest.endTime, "Quest has expired");

        // Example on-chain proof check: require user has certain reputation or specific shard.
        // The actual `_proof` could be validated by a separate `_verifyProof(questId, msg.sender, _proof)` internal function.
        // For simplicity, we just add a basic reputation check as *part* of quest completion eligibility.
        require(getUserReputation(msg.sender) > 50 || _proof.length > 0, "Not reputable enough, or no proof provided for this quest");
        // Imagine: `if (quest.id == 123) require(_verifyZKP(_proof), "Invalid ZKP");`

        quest.status = QuestStatus.Completed;

        // Reward the user with reputation and/or a Chronicle Shard
        adjustReputation(msg.sender, int256(quest.reputationReward));
        if (quest.shardIdReward != 0) {
            awardChronicleShard(msg.sender, quest.shardIdReward);
        }

        emit EphemeralQuestCompleted(_questId, msg.sender, quest.reputationReward, quest.shardIdReward);
    }

    /**
     * @notice Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's current reputation score.
     * @custom:function-number 26
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @notice Adjusts a user's reputation score.
     * @dev This function is typically called internally after quest completion or governance participation.
     *      It is exposed as `onlyOwner` for administrative adjustments. Positive `_delta` increases
     *      reputation, negative `_delta` decreases it (cannot go below zero).
     * @param _user The address of the user whose reputation is being adjusted.
     * @param _delta The amount to add or subtract from reputation (can be negative).
     * @custom:function-number 27
     */
    function adjustReputation(address _user, int256 _delta) public onlyOwner {
        uint256 currentRep = userReputation[_user];
        if (_delta > 0) {
            userReputation[_user] = currentRep.add(uint256(_delta));
        } else { // _delta is negative or zero
            uint256 absDelta = uint256(-_delta);
            if (currentRep >= absDelta) {
                userReputation[_user] = currentRep.sub(absDelta);
            } else {
                userReputation[_user] = 0; // Reputation cannot go below zero
            }
        }
        emit ReputationAdjusted(_user, _delta, userReputation[_user]);
    }

    // --- VII. Dynamic Pricing / Tribute System ---

    /**
     * @notice Sets the fee required to forge a new Digital Soul.
     * @dev Only the contract owner can update this fee.
     * @param _newFee The new forging fee in Wei.
     * @custom:function-number 28
     */
    function setForgingFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1 ether, "Forging fee cannot exceed 1 ETH for safety"); // Example sanity check
        forgingFee = _newFee;
        emit ForgingFeeUpdated(_newFee);
    }

    /**
     * @notice Returns the current fee for forging a new Digital Soul.
     * @return The current forging fee in Wei.
     * @custom:function-number 29
     */
    function getForgingFee() public view returns (uint256) {
        return forgingFee;
    }

    // Fallback and Receive functions to accept ETH
    receive() external payable {}
    fallback() external payable {}
}
```