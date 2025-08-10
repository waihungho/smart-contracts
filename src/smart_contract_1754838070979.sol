This smart contract, **MindForge Nexus**, is designed to be a decentralized hub for collective intelligence and verifiable knowledge. It simulates a system where users contribute "Knowledge Capsules" (data/insights), participate in "Consensus Hypotheses" (proposals for collective truth), and build "Cognitive Attunement" (reputation). It incorporates concepts like AI-assisted consensus, dynamic Soulbound Tokens (SBTs), and a dynamically evolving collective knowledge state.

---

## MindForge Nexus Smart Contract

**Solidity Version:** `^0.8.20`

**Core Concept:** A decentralized, evolving knowledge base powered by community contributions, AI oracle insights, and a unique reputation system, leading to a dynamic collective intelligence state.

---

### Outline & Function Summary

This contract combines elements of a custom ERC-721 for knowledge representation, a reputation system, a voting mechanism, and an interacting ERC-20 for incentives, all centered around an "AI Oracle" concept and dynamic Soulbound Tokens.

**I. Core Components:**

*   **Knowledge Capsules (ERC-721):** Unique, semi-transferable tokens representing contributed data, insights, or verifiable claims.
*   **Cognitive Attunement:** A non-transferable, dynamic reputation score for each participant, reflecting their contribution quality and consensus participation.
*   **Consensus Hypotheses:** Community-proposed statements or predictions that undergo a voting process, potentially influenced/finalized by an external AI Oracle.
*   **MindForge State:** A `bytes32` hash representing the current aggregated "truth" or collective intelligence of the network, dynamically updated upon successful hypothesis finalization.
*   **Cognitive Nexus Cores (Dynamic SBTs):** Soulbound Tokens minted per user, whose `tokenURI` (and thus visual/metadata representation) dynamically updates based on the user's Cognitive Attunement.
*   **Insight Shards (ERC-20):** An external ERC-20 token used for rewarding valuable contributions and successful consensus participation.

**II. Function Groups:**

1.  **Contract Management (Owner/Admin):**
    *   `constructor`: Initializes the contract, sets owner, `_mindForgeStateHash`.
    *   `setOracleAddress`: Sets the address of the trusted AI Oracle (off-chain service sending results).
    *   `setInsightShardTokenAddress`: Sets the address of the Insight Shards ERC-20 token.
    *   `togglePause`: Pauses/unpauses contract functionality for emergencies.
    *   `withdrawEther`: Allows owner to withdraw accidental ETH deposits.

2.  **Knowledge Capsule Management (ERC-721-like):**
    *   `mintKnowledgeCapsule`: Creates a new Knowledge Capsule NFT.
    *   `rateKnowledgeCapsule`: Allows users to rate existing capsules, influencing attunement.
    *   `updateCapsuleMetadataHash`: Allows capsule owner to update the off-chain data hash (e.g., improved dataset).

3.  **Consensus Hypothesis Management:**
    *   `submitConsensusHypothesis`: Proposes a statement for collective validation, requires a stake.
    *   `voteOnHypothesis`: Allows users to vote for or against a hypothesis.
    *   `finalizeHypothesis`: Triggered by the AI Oracle after a voting period, to validate the hypothesis and potentially update the `_mindForgeStateHash`.

4.  **Cognitive Nexus Core (Dynamic SBT) Management:**
    *   `mintCognitiveNexusCore`: Mints a unique Soulbound Token (SBT) for a user upon their first interaction, representing their identity within the Nexus.
    *   `syncNexusCoreMetadata`: Updates the `tokenURI` for the user's Cognitive Nexus Core based on their current `_cognitiveAttunement` level, reflecting their evolving status.

5.  **Incentive & Reward System:**
    *   `claimInsightShards`: Allows users to claim accumulated Insight Shard rewards.

6.  **Query & Information Retrieval:**
    *   `getKnowledgeCapsuleDetails`: Retrieves detailed information about a Knowledge Capsule.
    *   `getHypothesisDetails`: Retrieves detailed information about a Consensus Hypothesis.
    *   `getCognitiveAttunement`: Gets a user's current Cognitive Attunement score.
    *   `getMindForgeStateHash`: Retrieves the current global MindForge State hash.
    *   `getPendingInsightShards`: Checks a user's pending reward balance.
    *   `getNexusCoreMetadataURI`: Gets the current `tokenURI` for a user's Cognitive Nexus Core.
    *   `getHypothesesByStatus`: Retrieves a list of hypotheses by their current status (e.g., active, finalized).
    *   `getKnowledgeCapsulesByAuthor`: Retrieves all capsules minted by a specific author.
    *   `getKnowledgeCapsulesByTag`: Retrieves capsules associated with a given tag.
    *   `queryMindForge`: A conceptual function to simulate querying the collective intelligence, returning relevant `knowledgeCapsuleId`s based on a query hash.
    *   `getTopRatedCapsules`: Returns IDs of the highest-rated capsules (limited for practical gas use).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// --- Custom Errors ---
error MindForge__NotOracle();
error MindForge__InvalidHypothesisState();
error MindForge__VotingPeriodNotOver();
error MindForge__VotingPeriodActive();
error MindForge__AlreadyVoted();
error MindForge__NoPendingRewards();
error MindForge__HypothesisNotFound();
error MindForge__NotHypothesisProposer();
error MindForge__KnowledgeCapsuleNotFound();
error MindForge__NexusCoreAlreadyMinted();
error MindForge__NexusCoreNotMinted();
error MindForge__CannotTransferNexusCore();
error MindForge__TagLimitExceeded();
error MindForge__InvalidRating();
error MindForge__InsufficientStake();
error MindForge__InvalidOracleResponse();

// --- Main Contract ---
contract MindForgeNexus is Ownable, Pausable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // --- State Variables ---
    address private s_oracleAddress;
    IERC20 private s_insightShardToken;

    // The current collective intelligence state of the MindForge Nexus.
    // This hash represents the aggregated knowledge, insights, and validated hypotheses.
    // It's updated by the oracle after successful hypothesis finalization.
    bytes32 private s_mindForgeStateHash;

    // Counters for unique IDs
    Counters.Counter private s_knowledgeCapsuleIdCounter;
    Counters.Counter private s_hypothesisIdCounter;

    // --- Data Structures ---

    enum HypothesisStatus { Active, FinalizedPositive, FinalizedNegative, Rejected, Withdrawn }

    struct KnowledgeCapsule {
        uint256 id;
        address author;
        bytes32 metadataHash; // IPFS CID or similar hash of the off-chain data
        string[] tags;
        uint256 createdAt;
        uint256 totalRating; // Sum of all ratings
        uint256 ratingCount; // Number of ratings received
        mapping(address => bool) hasRated; // To prevent multiple ratings from same user
    }

    struct Hypothesis {
        uint256 id;
        address proposer;
        string statement; // A brief summary or question for consensus
        uint256 stakedAmount; // Tokens staked by proposer
        uint256 proposalTimestamp;
        uint256 votingEndsTimestamp;
        uint256 positiveVotes;
        uint256 negativeVotes;
        HypothesisStatus status;
        bytes32 newMindForgeStateHash; // Proposed new state hash if hypothesis is accepted
        mapping(address => bool) hasVoted; // To prevent multiple votes from same user
    }

    struct UserData {
        uint256 cognitiveAttunement; // Reputation score
        uint256 pendingInsightShards;
        bool hasNexusCore; // True if user has minted their Soulbound Token
        uint256 lastNexusCoreSyncTimestamp; // Timestamp of last metadata update
    }

    // --- Mappings ---
    mapping(uint256 => KnowledgeCapsule) private s_knowledgeCapsules;
    mapping(uint256 => Hypothesis) private s_hypotheses;
    mapping(address => UserData) private s_users;
    mapping(address => uint256) private s_cognitiveNexusCoreTokenId; // User address -> SBT ID
    mapping(uint256 => address) private s_cognitiveNexusCoreOwner; // SBT ID -> User address (for ERC721 compatibility, but non-transferable)
    mapping(bytes32 => uint256[]) private s_taggedCapsules; // Tag hash -> List of capsule IDs

    // --- Events ---
    event OracleAddressSet(address indexed newOracleAddress);
    event InsightShardTokenAddressSet(address indexed newTokenAddress);
    event KnowledgeCapsuleMinted(uint256 indexed id, address indexed author, bytes32 metadataHash, string[] tags);
    event KnowledgeCapsuleRated(uint256 indexed id, address indexed rater, uint256 rating);
    event KnowledgeCapsuleMetadataUpdated(uint256 indexed id, bytes32 newMetadataHash);
    event HypothesisSubmitted(uint256 indexed id, address indexed proposer, string statement, uint256 votingEndsTimestamp);
    event HypothesisVoted(uint256 indexed id, address indexed voter, bool voteFor);
    event HypothesisFinalized(uint256 indexed id, HypothesisStatus status, bytes32 newMindForgeStateHash);
    event CognitiveNexusCoreMinted(address indexed user, uint256 indexed tokenId);
    event CognitiveNexusCoreSynced(address indexed user, uint256 indexed tokenId, string tokenURI);
    event InsightShardsClaimed(address indexed user, uint256 amount);
    event MindForgeStateUpdated(bytes32 oldState, bytes32 newState);

    // --- Constants ---
    uint256 public constant MIN_HYPOTHESIS_STAKE = 1 ether; // Example stake amount
    uint256 public constant VOTING_PERIOD_DURATION = 3 days;
    uint256 public constant MAX_TAGS_PER_CAPSULE = 5;
    uint256 public constant BASE_ATTUNEMENT_GAIN_RATE = 10; // Per successful action
    uint256 public constant MAX_RATING_VALUE = 5;
    uint256 public constant MIN_RATING_VALUE = 1;
    uint256 public constant NEXUS_CORE_SYNC_COOLDOWN = 1 hours; // How often the SBT metadata can be synced

    // --- Constructor ---
    constructor(address initialOracleAddress, address initialInsightShardTokenAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        if (initialOracleAddress == address(0)) revert MindForge__InvalidOracleResponse();
        if (initialInsightShardTokenAddress == address(0)) revert MindForge__InvalidOracleResponse();

        s_oracleAddress = initialOracleAddress;
        s_insightShardToken = IERC20(initialInsightShardTokenAddress);
        // Initialize MindForgeStateHash with a genesis hash
        s_mindForgeStateHash = keccak256(abi.encodePacked("MindForgeGenesis"));
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != s_oracleAddress) revert MindForge__NotOracle();
        _;
    }

    // --- Admin & Management Functions ---

    /**
     * @notice Sets the address of the trusted AI Oracle. Only callable by the owner.
     * @param _newOracleAddress The new address for the AI Oracle.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        if (_newOracleAddress == address(0)) revert MindForge__InvalidOracleResponse();
        s_oracleAddress = _newOracleAddress;
        emit OracleAddressSet(_newOracleAddress);
    }

    /**
     * @notice Sets the address of the Insight Shards ERC-20 token. Only callable by the owner.
     * @param _newTokenAddress The new address for the Insight Shards token.
     */
    function setInsightShardTokenAddress(address _newTokenAddress) external onlyOwner {
        if (_newTokenAddress == address(0)) revert MindForge__InvalidOracleResponse();
        s_insightShardToken = IERC20(_newTokenAddress);
        emit InsightShardTokenAddressSet(_newTokenAddress);
    }

    /**
     * @notice Toggles the paused state of the contract. Only callable by the owner.
     * @dev When paused, most state-changing functions are blocked.
     */
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @notice Allows the contract owner to withdraw any accidentally sent Ether.
     */
    function withdrawEther() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }

    // --- Knowledge Capsule Functions (ERC-721 based) ---

    /**
     * @notice Mints a new Knowledge Capsule representing an insight or data.
     * @param _metadataHash IPFS CID or hash of the off-chain data.
     * @param _tags An array of tags for classification and search.
     * @return The ID of the newly minted Knowledge Capsule.
     */
    function mintKnowledgeCapsule(bytes32 _metadataHash, string[] calldata _tags)
        external
        whenNotPaused
        returns (uint256)
    {
        if (_tags.length == 0 || _tags.length > MAX_TAGS_PER_CAPSULE) revert MindForge__TagLimitExceeded();

        s_knowledgeCapsuleIdCounter.increment();
        uint256 newId = s_knowledgeCapsuleIdCounter.current();

        s_knowledgeCapsules[newId].id = newId;
        s_knowledgeCapsules[newId].author = msg.sender;
        s_knowledgeCapsules[newId].metadataHash = _metadataHash;
        s_knowledgeCapsules[newId].createdAt = block.timestamp;
        s_knowledgeCapsules[newId].tags = _tags; // Assign tags to the struct

        for (uint256 i = 0; i < _tags.length; i++) {
            s_taggedCapsules[keccak256(abi.encodePacked(_tags[i]))].push(newId);
        }

        _mint(msg.sender, newId); // Mints the ERC721 token
        _updateCognitiveAttunement(msg.sender, BASE_ATTUNEMENT_GAIN_RATE); // Reward for contribution

        emit KnowledgeCapsuleMinted(newId, msg.sender, _metadataHash, _tags);
        return newId;
    }

    /**
     * @notice Allows users to rate a Knowledge Capsule.
     * @param _capsuleId The ID of the capsule to rate.
     * @param _rating The rating value (e.g., 1-5).
     */
    function rateKnowledgeCapsule(uint256 _capsuleId, uint256 _rating) external whenNotPaused {
        KnowledgeCapsule storage capsule = s_knowledgeCapsules[_capsuleId];
        if (capsule.id == 0) revert MindForge__KnowledgeCapsuleNotFound();
        if (capsule.author == msg.sender) revert("MindForge: Cannot rate your own capsule");
        if (capsule.hasRated[msg.sender]) revert("MindForge: Already rated this capsule");
        if (_rating < MIN_RATING_VALUE || _rating > MAX_RATING_VALUE) revert MindForge__InvalidRating();

        capsule.totalRating = capsule.totalRating.add(_rating);
        capsule.ratingCount = capsule.ratingCount.add(1);
        capsule.hasRated[msg.sender] = true;

        // Optionally, reward rater for participation (e.g., small attunement gain)
        _updateCognitiveAttunement(msg.sender, BASE_ATTUNEMENT_GAIN_RATE.div(5));

        emit KnowledgeCapsuleRated(_capsuleId, msg.sender, _rating);
    }

    /**
     * @notice Allows the author of a Knowledge Capsule to update its off-chain metadata hash.
     * @param _capsuleId The ID of the capsule to update.
     * @param _newMetadataHash The new IPFS CID or hash.
     */
    function updateCapsuleMetadataHash(uint256 _capsuleId, bytes32 _newMetadataHash) external whenNotPaused {
        KnowledgeCapsule storage capsule = s_knowledgeCapsules[_capsuleId];
        if (capsule.id == 0) revert MindForge__KnowledgeCapsuleNotFound();
        if (capsule.author != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable error for unauthorized

        capsule.metadataHash = _newMetadataHash;
        emit KnowledgeCapsuleMetadataUpdated(_capsuleId, _newMetadataHash);
    }

    // --- Consensus Hypothesis Functions ---

    /**
     * @notice Submits a new Consensus Hypothesis for the community to vote on.
     * @param _statement The hypothesis statement (e.g., "AI will achieve AGI by 2030").
     * @param _proposedMindForgeStateHash The new MindForge state hash if this hypothesis is accepted.
     */
    function submitConsensusHypothesis(string calldata _statement, bytes32 _proposedMindForgeStateHash)
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        if (msg.value < MIN_HYPOTHESIS_STAKE) revert MindForge__InsufficientStake();

        s_hypothesisIdCounter.increment();
        uint256 newId = s_hypothesisIdCounter.current();

        s_hypotheses[newId].id = newId;
        s_hypotheses[newId].proposer = msg.sender;
        s_hypotheses[newId].statement = _statement;
        s_hypotheses[newId].stakedAmount = msg.value;
        s_hypotheses[newId].proposalTimestamp = block.timestamp;
        s_hypotheses[newId].votingEndsTimestamp = block.timestamp.add(VOTING_PERIOD_DURATION);
        s_hypotheses[newId].status = HypothesisStatus.Active;
        s_hypotheses[newId].newMindForgeStateHash = _proposedMindForgeStateHash;

        _updateCognitiveAttunement(msg.sender, BASE_ATTUNEMENT_GAIN_RATE.mul(2)); // Higher reward for proposing

        emit HypothesisSubmitted(newId, msg.sender, _statement, s_hypotheses[newId].votingEndsTimestamp);
        return newId;
    }

    /**
     * @notice Allows users to vote on an active Consensus Hypothesis.
     * @param _hypothesisId The ID of the hypothesis.
     * @param _voteFor True for a positive vote, false for a negative vote.
     */
    function voteOnHypothesis(uint256 _hypothesisId, bool _voteFor) external whenNotPaused {
        Hypothesis storage hypothesis = s_hypotheses[_hypothesisId];
        if (hypothesis.id == 0) revert MindForge__HypothesisNotFound();
        if (hypothesis.status != HypothesisStatus.Active) revert MindForge__InvalidHypothesisState();
        if (block.timestamp >= hypothesis.votingEndsTimestamp) revert MindForge__VotingPeriodOver();
        if (hypothesis.hasVoted[msg.sender]) revert MindForge__AlreadyVoted();

        if (_voteFor) {
            hypothesis.positiveVotes = hypothesis.positiveVotes.add(1);
        } else {
            hypothesis.negativeVotes = hypothesis.negativeVotes.add(1);
        }
        hypothesis.hasVoted[msg.sender] = true;

        _updateCognitiveAttunement(msg.sender, BASE_ATTUNEMENT_GAIN_RATE.div(2)); // Small reward for voting

        emit HypothesisVoted(_hypothesisId, msg.sender, _voteFor);
    }

    /**
     * @notice Finalizes a hypothesis after its voting period ends.
     *         This function is expected to be called by the trusted AI Oracle.
     * @param _hypothesisId The ID of the hypothesis to finalize.
     * @param _oracleValidation True if the oracle validates the hypothesis, false otherwise.
     */
    function finalizeHypothesis(uint256 _hypothesisId, bool _oracleValidation) external onlyOracle whenNotPaused {
        Hypothesis storage hypothesis = s_hypotheses[_hypothesisId];
        if (hypothesis.id == 0) revert MindForge__HypothesisNotFound();
        if (hypothesis.status != HypothesisStatus.Active) revert MindForge__InvalidHypothesisState();
        if (block.timestamp < hypothesis.votingEndsTimestamp) revert MindForge__VotingPeriodActive();

        HypothesisStatus finalStatus;
        bytes32 newGlobalStateHash = s_mindForgeStateHash; // Default to current state

        // Simple majority vote
        bool communityAgrees = hypothesis.positiveVotes >= hypothesis.negativeVotes;

        if (_oracleValidation && communityAgrees) {
            finalStatus = HypothesisStatus.FinalizedPositive;
            newGlobalStateHash = hypothesis.newMindForgeStateHash; // Update global state
            s_users[hypothesis.proposer].pendingInsightShards = s_users[hypothesis.proposer].pendingInsightShards.add(hypothesis.stakedAmount.mul(2)); // Reward proposer
            // Reward all who voted positive for this hypothesis (requires iterating mapping, which is expensive)
            // For simplicity, we'll assume a general reward pool or a different reward distribution mechanism.
            // Or, distribute a fixed reward to all voters, regardless of vote, just for participation in a successful consensus
        } else {
            finalStatus = HypothesisStatus.FinalizedNegative;
            s_users[hypothesis.proposer].pendingInsightShards = s_users[hypothesis.proposer].pendingInsightShards.add(hypothesis.stakedAmount.div(2)); // Return half stake
        }

        hypothesis.status = finalStatus;

        if (newGlobalStateHash != s_mindForgeStateHash) {
            emit MindForgeStateUpdated(s_mindForgeStateHash, newGlobalStateHash);
            s_mindForgeStateHash = newGlobalStateHash;
        }
        emit HypothesisFinalized(_hypothesisId, finalStatus, newGlobalStateHash);
    }

    // --- Cognitive Nexus Core (Dynamic SBT) Functions ---

    /**
     * @notice Mints a Cognitive Nexus Core Soulbound Token (SBT) for the caller.
     *         A user can only mint one Nexus Core. This token is non-transferable.
     */
    function mintCognitiveNexusCore() external whenNotPaused {
        if (s_users[msg.sender].hasNexusCore) revert MindForge__NexusCoreAlreadyMinted();

        uint256 tokenId = uint256(uint160(msg.sender)); // Use user address as token ID for uniqueness and easy lookup
        s_cognitiveNexusCoreTokenId[msg.sender] = tokenId;
        s_cognitiveNexusCoreOwner[tokenId] = msg.sender; // Store owner for ERC721 compatibility

        s_users[msg.sender].hasNexusCore = true;
        s_users[msg.sender].cognitiveAttunement = 1; // Initial attunement

        _mint(msg.sender, tokenId); // Mint the ERC721 token
        // Override _transfer to make it non-transferable (handled by `_beforeTokenTransfer`)
        emit CognitiveNexusCoreMinted(msg.sender, tokenId);

        // Sync metadata immediately after mint
        _syncAndEmitNexusCoreMetadata(msg.sender);
    }

    /**
     * @notice Forces an update to the `tokenURI` for the caller's Cognitive Nexus Core.
     *         This reflects their current Cognitive Attunement level dynamically.
     */
    function syncNexusCoreMetadata() external whenNotPaused {
        if (!s_users[msg.sender].hasNexusCore) revert MindForge__NexusCoreNotMinted();
        if (block.timestamp < s_users[msg.sender].lastNexusCoreSyncTimestamp.add(NEXUS_CORE_SYNC_COOLDOWN)) {
            revert("MindForge: Nexus Core metadata sync cooldown active");
        }
        _syncAndEmitNexusCoreMetadata(msg.sender);
    }

    // --- Incentive & Reward Functions ---

    /**
     * @notice Allows a user to claim their pending Insight Shard rewards.
     */
    function claimInsightShards() external whenNotPaused {
        uint256 amount = s_users[msg.sender].pendingInsightShards;
        if (amount == 0) revert MindForge__NoPendingRewards();

        s_users[msg.sender].pendingInsightShards = 0; // Reset pending rewards
        s_insightShardToken.safeTransfer(msg.sender, amount);

        emit InsightShardsClaimed(msg.sender, amount);
    }

    // --- Query & Information Retrieval Functions ---

    /**
     * @notice Retrieves detailed information about a Knowledge Capsule.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @return author The address of the capsule's author.
     * @return metadataHash The IPFS CID or hash of the off-chain data.
     * @return tags The array of tags associated with the capsule.
     * @return createdAt The timestamp when the capsule was minted.
     * @return averageRating The current average rating of the capsule.
     */
    function getKnowledgeCapsuleDetails(uint256 _capsuleId)
        external
        view
        returns (address author, bytes32 metadataHash, string[] memory tags, uint256 createdAt, uint256 averageRating)
    {
        KnowledgeCapsule storage capsule = s_knowledgeCapsules[_capsuleId];
        if (capsule.id == 0) revert MindForge__KnowledgeCapsuleNotFound();
        return (
            capsule.author,
            capsule.metadataHash,
            capsule.tags,
            capsule.createdAt,
            capsule.ratingCount > 0 ? capsule.totalRating.div(capsule.ratingCount) : 0
        );
    }

    /**
     * @notice Retrieves detailed information about a Consensus Hypothesis.
     * @param _hypothesisId The ID of the Hypothesis.
     * @return proposer The address of the hypothesis proposer.
     * @return statement The hypothesis statement.
     * @return stakedAmount The amount of tokens staked.
     * @return proposalTimestamp The timestamp when the hypothesis was proposed.
     * @return votingEndsTimestamp The timestamp when voting ends.
     * @return positiveVotes The number of positive votes.
     * @return negativeVotes The number of negative votes.
     * @return status The current status of the hypothesis.
     * @return newMindForgeStateHash The proposed new MindForge state hash.
     */
    function getHypothesisDetails(uint256 _hypothesisId)
        external
        view
        returns (
            address proposer,
            string memory statement,
            uint256 stakedAmount,
            uint256 proposalTimestamp,
            uint256 votingEndsTimestamp,
            uint256 positiveVotes,
            uint256 negativeVotes,
            HypothesisStatus status,
            bytes32 newMindForgeStateHash
        )
    {
        Hypothesis storage hypothesis = s_hypotheses[_hypothesisId];
        if (hypothesis.id == 0) revert MindForge__HypothesisNotFound();
        return (
            hypothesis.proposer,
            hypothesis.statement,
            hypothesis.stakedAmount,
            hypothesis.proposalTimestamp,
            hypothesis.votingEndsTimestamp,
            hypothesis.positiveVotes,
            hypothesis.negativeVotes,
            hypothesis.status,
            hypothesis.newMindForgeStateHash
        );
    }

    /**
     * @notice Gets a user's current Cognitive Attunement score.
     * @param _user The address of the user.
     * @return The Cognitive Attunement score.
     */
    function getCognitiveAttunement(address _user) external view returns (uint256) {
        return s_users[_user].cognitiveAttunement;
    }

    /**
     * @notice Retrieves the current global MindForge State hash.
     * @return The `bytes32` hash representing the current collective intelligence.
     */
    function getMindForgeStateHash() external view returns (bytes32) {
        return s_mindForgeStateHash;
    }

    /**
     * @notice Checks a user's pending Insight Shard reward balance.
     * @param _user The address of the user.
     * @return The amount of pending Insight Shards.
     */
    function getPendingInsightShards(address _user) external view returns (uint256) {
        return s_users[_user].pendingInsightShards;
    }

    /**
     * @notice Gets the current `tokenURI` for a user's Cognitive Nexus Core.
     * @dev This URI is dynamic and reflects the user's attunement level.
     * @param _user The address of the user.
     * @return The dynamic token URI.
     */
    function getNexusCoreMetadataURI(address _user) external view returns (string memory) {
        if (!s_users[_user].hasNexusCore) revert MindForge__NexusCoreNotMinted();
        uint256 tokenId = s_cognitiveNexusCoreTokenId[_user];
        return tokenURI(tokenId);
    }

    /**
     * @notice Retrieves a list of hypothesis IDs by their status.
     * @param _status The status to filter by (e.g., Active, FinalizedPositive).
     * @dev This function iterates through all hypotheses and might be gas-intensive for many entries.
     *      Consider external indexing solutions for large datasets.
     * @return An array of hypothesis IDs.
     */
    function getHypothesesByStatus(HypothesisStatus _status) external view returns (uint256[] memory) {
        uint256[] memory matchingIds = new uint256[](s_hypothesisIdCounter.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= s_hypothesisIdCounter.current(); i++) {
            if (s_hypotheses[i].status == _status) {
                matchingIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingIds[i];
        }
        return result;
    }

    /**
     * @notice Retrieves all Knowledge Capsules minted by a specific author.
     * @param _author The address of the author.
     * @dev This iterates over all capsules; use off-chain indexing for large scale.
     * @return An array of Knowledge Capsule IDs.
     */
    function getKnowledgeCapsulesByAuthor(address _author) external view returns (uint256[] memory) {
        uint256[] memory authoredCapsules = new uint256[](s_knowledgeCapsuleIdCounter.current());
        uint256 count = 0;
        for (uint256 i = 1; i <= s_knowledgeCapsuleIdCounter.current(); i++) {
            if (s_knowledgeCapsules[i].author == _author) {
                authoredCapsules[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = authoredCapsules[i];
        }
        return result;
    }

    /**
     * @notice Retrieves Knowledge Capsules associated with a specific tag.
     * @param _tag The tag to search for.
     * @return An array of Knowledge Capsule IDs.
     */
    function getKnowledgeCapsulesByTag(string calldata _tag) external view returns (uint256[] memory) {
        return s_taggedCapsules[keccak256(abi.encodePacked(_tag))];
    }

    /**
     * @notice A conceptual function to simulate querying the collective intelligence.
     *         In a real dApp, this would likely involve more sophisticated off-chain AI models
     *         and return richer results. Here, it returns relevant capsule IDs based on a query hash.
     * @param _queryHash A hash representing the user's query/topic of interest.
     * @dev For a real implementation, this would involve a complex on-chain knowledge graph or
     *      an off-chain AI service processing the query and providing verifiable responses.
     *      This simple version just returns arbitrary related capsules for demonstration.
     * @return An array of Knowledge Capsule IDs deemed "relevant" by the MindForge Nexus.
     */
    function queryMindForge(bytes32 _queryHash) external view returns (uint256[] memory relevantCapsuleIds) {
        // This is a placeholder for a complex AI-driven knowledge retrieval.
        // In a real system, an off-chain AI model, perhaps triggered by the query,
        // would analyze the queryHash against the collective knowledge (MindForgeStateHash, capsules, hypotheses)
        // and return the most relevant capsule IDs or aggregated insights.
        // For this contract, we'll return a fixed set or simply some recent capsules.
        // As a conceptual example, let's return some IDs based on the last few minted capsules.
        uint256 numCapsules = s_knowledgeCapsuleIdCounter.current();
        if (numCapsules == 0) return new uint256[](0);

        uint256 returnCount = numCapsules > 5 ? 5 : numCapsules; // Return up to 5 most recent
        relevantCapsuleIds = new uint256[](returnCount);
        for (uint256 i = 0; i < returnCount; i++) {
            relevantCapsuleIds[i] = numCapsules.sub(i);
        }
        return relevantCapsuleIds;
    }

    /**
     * @notice Retrieves the IDs of the top-rated Knowledge Capsules.
     * @dev This function iterates over all capsules and is computationally intensive for many entries.
     *      For practical use, external indexing or a more sophisticated ranking mechanism would be needed.
     * @param _limit The maximum number of top-rated capsules to return.
     * @return An array of Knowledge Capsule IDs sorted by average rating (descending).
     */
    function getTopRatedCapsules(uint256 _limit) external view returns (uint256[] memory) {
        uint256 totalCapsules = s_knowledgeCapsuleIdCounter.current();
        if (totalCapsules == 0) return new uint256[](0);

        // This simple in-contract sorting is extremely gas-inefficient for large N.
        // In a real dApp, this would be done off-chain via a subgraph or other indexing solution.
        // For demonstration purposes with a small N:
        struct CapsuleRating {
            uint256 id;
            uint256 avgRating;
        }

        CapsuleRating[] memory allRatings = new CapsuleRating[](totalCapsules);
        for (uint256 i = 1; i <= totalCapsules; i++) {
            KnowledgeCapsule storage capsule = s_knowledgeCapsules[i];
            allRatings[i - 1] = CapsuleRating(
                capsule.id,
                capsule.ratingCount > 0 ? capsule.totalRating.div(capsule.ratingCount) : 0
            );
        }

        // Bubble sort for simplicity (inefficient but works for small arrays)
        for (uint256 i = 0; i < totalCapsules; i++) {
            for (uint256 j = 0; j < totalCapsules - i - 1; j++) {
                if (allRatings[j].avgRating < allRatings[j + 1].avgRating) {
                    CapsuleRating memory temp = allRatings[j];
                    allRatings[j] = allRatings[j + 1];
                    allRatings[j + 1] = temp;
                }
            }
        }

        uint256 actualLimit = totalCapsules < _limit ? totalCapsules : _limit;
        uint256[] memory topIds = new uint256[](actualLimit);
        for (uint256 i = 0; i < actualLimit; i++) {
            topIds[i] = allRatings[i].id;
        }
        return topIds;
    }

    // --- Internal / Helper Functions ---

    /**
     * @dev Internal function to update a user's Cognitive Attunement score.
     * @param _user The address of the user.
     * @param _delta The amount to add to the attunement score.
     */
    function _updateCognitiveAttunement(address _user, uint256 _delta) internal {
        s_users[_user].cognitiveAttunement = s_users[_user].cognitiveAttunement.add(_delta);
        // If the user has a Nexus Core, trigger a sync to update its metadata
        if (s_users[_user].hasNexusCore) {
            _syncAndEmitNexusCoreMetadata(_user);
        }
    }

    /**
     * @dev Internal function to generate and update the tokenURI for a Cognitive Nexus Core.
     *      This generates a base64 encoded JSON string directly on-chain.
     * @param _user The owner of the Nexus Core.
     */
    function _syncAndEmitNexusCoreMetadata(address _user) internal {
        uint256 tokenId = s_cognitiveNexusCoreTokenId[_user];
        uint256 attunement = s_users[_user].cognitiveAttunement;

        // Determine level based on attunement (example tiers)
        uint256 level = 1;
        if (attunement >= 1000) level = 5;
        else if (attunement >= 500) level = 4;
        else if (attunement >= 200) level = 3;
        else if (attunement >= 50) level = 2;

        string memory name = string(abi.encodePacked("Cognitive Nexus Core #", tokenId.toString()));
        string memory description = string(abi.encodePacked("This Soulbound Token represents the collective intelligence attunement of ", Strings.toHexString(uint160(_user)), ". Level: ", level.toString(), ". Attunement Score: ", attunement.toString(), "."));

        // Basic SVG representation (can be much more complex off-chain)
        string memory svg = string(abi.encodePacked(
            '<svg width="350" height="350" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="100%" height="100%" fill="#1a1a2e"/>',
            '<text x="50%" y="40%" dominant-baseline="middle" text-anchor="middle" font-family="monospace" font-size="20" fill="#e0b0ff">MIND FORGE</text>',
            '<text x="50%" y="55%" dominant-baseline="middle" text-anchor="middle" font-family="monospace" font-size="16" fill="#c0c0c0">Level: ', level.toString(), '</text>',
            '<text x="50%" y="70%" dominant-baseline="middle" text-anchor="middle" font-family="monospace" font-size="12" fill="#999999">Attunement: ', attunement.toString(), '</text>',
            '<rect x="25%" y="80%" width="50%" height="5" rx="2" ry="2" fill="#5c5c8a"/>',
            '<rect x="25%" y="80%" width="', level.mul(10).toString(), '%" height="5" rx="2" ry="2" fill="#8d3dcc"/>', // Progress bar based on level
            '</svg>'
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
            '"attributes": [',
                '{"trait_type": "Attunement Level", "value": ', level.toString(), '},',
                '{"trait_type": "Attunement Score", "value": ', attunement.toString(), '}',
            ']}'
        ));

        string memory baseURI = "data:application/json;base64,";
        string memory finalURI = string(abi.encodePacked(baseURI, Base64.encode(bytes(json))));

        _setTokenURI(tokenId, finalURI); // ERC721 internal function
        s_users[_user].lastNexusCoreSyncTimestamp = block.timestamp;
        emit CognitiveNexusCoreSynced(_user, tokenId, finalURI);
    }

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to prevent transfer of Soulbound Tokens (Cognitive Nexus Cores).
     * @param from The address from which the token is being transferred.
     * @param to The address to which the token is being transferred.
     * @param tokenId The ID of the token being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Check if the token is a Cognitive Nexus Core
        // Nexus Core tokens have IDs equal to the user's address (uint160 converted to uint256)
        // Knowledge Capsules are minted incrementally starting from 1
        if (s_cognitiveNexusCoreTokenId[from] == tokenId || s_cognitiveNexusCoreTokenId[to] == tokenId) {
             if (from != address(0) && to != address(0) && from != to) {
                 revert MindForge__CannotTransferNexusCore();
             }
        }
    }

    /**
     * @dev ERC721Enumerable requires `_approve` to be overridden for `ERC721Enumerable`.
     * This is a minimal implementation, not affecting the Soulbound nature, as `_beforeTokenTransfer` handles it.
     */
    function _approve(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._approve(to, tokenId);
    }

    /**
     * @dev ERC721Enumerable requires `_setApprovalForAll` to be overridden for `ERC721Enumerable`.
     * This is a minimal implementation, not affecting the Soulbound nature.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal override(ERC721, ERC721Enumerable) {
        super._setApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev ERC721Enumerable requires `_safeTransfer` to be overridden for `ERC721Enumerable`.
     * This is a minimal implementation, not affecting the Soulbound nature.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal override(ERC721, ERC721Enumerable) {
        super._safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev ERC721Enumerable requires `_transfer` to be overridden for `ERC721Enumerable`.
     * This is a minimal implementation, not affecting the Soulbound nature.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._transfer(from, to, tokenId);
    }

    /**
     * @dev ERC721Enumerable requires `_mint` to be overridden for `ERC721Enumerable`.
     */
    function _mint(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._mint(to, tokenId);
    }

    /**
     * @dev ERC721Enumerable requires `_burn` to be overridden for `ERC721Enumerable`.
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._burn(tokenId);
    }

    // Fallback function to receive Ether
    receive() external payable {}
    fallback() external payable {}
}
```