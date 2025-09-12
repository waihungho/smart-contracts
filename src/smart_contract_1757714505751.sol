This smart contract, named **ChronicleForge**, pioneers a unique approach to decentralized collaborative storytelling. It allows a community to collectively build and evolve a shared narrative ("lore") through "Chronicle Fragments." The lore is brought to life with "Relic" NFTs, which are dynamic and can evolve their attributes based on the story's progression, decided by community consensus and optionally informed by an AI oracle's qualitative analysis. A robust reputation system ("Insight" and "Memory Shards") empowers contributors and drives DAO governance, enabling the community to steer the narrative's direction, manage the protocol, and even mint new Relics.

---

## Outline: ChronicleForge - Decentralized Autonomous Narratives & Evolving Lore

This contract creates a platform for a decentralized community to collaboratively build, curate, and evolve a shared on-chain narrative or "lore." It integrates dynamic NFTs ("Relics") whose attributes change based on story progression, an AI-assisted oracle for narrative analysis, and a sophisticated reputation system for contributors.

**I. Core Narrative Management (Chronicle Fragments):**
   Users submit narrative pieces (fragments). These fragments are voted upon by the community, with their quality potentially assessed by an AI oracle. Approved fragments become part of the official lore.

**II. Relic (Dynamic NFT) Management:**
   Relics are unique ERC721 NFTs representing key characters, artifacts, or locations within the lore. Their metadata (attributes) can be proposed to evolve based on significant narrative developments, requiring community vote and AI insight.

**III. Reputation & Rewards (Insight & Memory Shards):**
   Contributors gain "Insight" (a non-transferable reputation score) for successful narrative contributions. Special achievements are recognized with "Memory Shards" (Soulbound NFTs), granting unique governance weight or access.

**IV. AI Oracle Integration (Simulated):**
   An external AI oracle can be requested to analyze submitted fragments or relic evolution justifications for sentiment, coherence, or thematic consistency. The results aid community voting.

**V. DAO Governance & Treasury:**
   A robust DAO allows "Insight" holders to propose and vote on major protocol changes, treasury management, and significant plot twists or story arc directions.

**VI. Story Arc & Event Management:**
   The community, via DAO, defines major story "arcs" to organize the narrative flow. Specific events or quests can be initiated.

---

## Function Summary:

**I. Core Narrative Management:**
1.  `submitChronicleFragment(string memory content, uint256 parentFragmentId)`: Proposes a new piece of lore.
2.  `voteOnFragment(uint256 fragmentId, bool approve)`: Allows Insight holders to vote on a fragment.
3.  `finalizeFragment(uint256 fragmentId)`: Makes an approved fragment official. Callable by anyone after the voting period ends.
4.  `getFragmentDetails(uint256 fragmentId)`: Retrieves comprehensive details about a fragment.
5.  `getFragmentVotes(uint256 fragmentId)`: Retrieves vote counts for a specific fragment.

**II. Relic (Dynamic NFT) Management:**
6.  `mintRelic(uint256 storyArcId, string memory name, string memory initialMetadataURI)`: Mints a new Relic NFT, linked to a specific story arc. *Intended for DAO governance execution.*
7.  `proposeRelicEvolution(uint256 relicId, string memory newMetadataURI, string memory justification)`: Proposes an update to a Relic's metadata, reflecting narrative changes.
8.  `voteOnRelicEvolution(uint256 proposalId, bool approve)`: Votes on a Relic evolution proposal.
9.  `finalizeRelicEvolution(uint256 proposalId)`: Applies the metadata update to a Relic if approved. Callable by anyone after the voting period ends.
10. `getRelicDetails(uint256 relicId)`: Retrieves current details of a Relic NFT, including its URI and owner.

**III. Reputation & Rewards:**
11. `claimFragmentInsight(uint256 fragmentId)`: Allows the author of a finalized fragment to claim their "Insight" points.
12. `getParticipantInsight(address participant)`: Returns the total Insight score for an address.
13. `mintMemoryShard(address to, string memory shardType, string memory loreContext)`: Mints a special, non-transferable Memory Shard NFT for significant achievements. *Intended for DAO governance execution.*
14. `getMemoryShardDetails(uint256 shardId)`: Retrieves details about a Memory Shard.
15. `getMemoryShardsOfOwner(address owner)`: Returns a list of Memory Shard IDs owned by an address.

**IV. AI Oracle Integration (Simulated):**
16. `setOracleAddress(address _oracleAddress)`: Sets the address of the trusted AI Oracle. *Intended for DAO governance execution.*
17. `requestFragmentAnalysis(uint256 fragmentId)`: Requests the AI oracle to analyze a specific fragment.
18. `receiveOracleAnalysis(uint256 fragmentId, int256 sentimentScore, uint256 cohesionScore)`: Callback function for the oracle to submit analysis results.

**V. DAO Governance & Treasury:**
19. `proposeGeneralVote(string memory proposalTitle, string memory proposalDescription, address targetContract, bytes memory callData)`: Creates a general governance proposal (e.g., treasury, new story arc).
20. `voteOnGeneralProposal(uint256 proposalId, bool approve)`: Votes on a general governance proposal.
21. `executeGeneralProposal(uint256 proposalId)`: Executes a general proposal that has passed and met quorum.
22. `transferTreasuryFunds(address recipient, uint256 amount)`: Allows DAO to transfer funds from contract treasury. *Intended for DAO governance execution.*

**VI. Story Arc & Event Management:**
23. `createStoryArc(string memory title, string memory description)`: Creates a new major story arc. *Intended for DAO governance execution.*
24. `setCurrentStoryArc(uint256 arcId)`: Sets the active story arc for new fragment submissions. *Intended for DAO governance execution.*
25. `getStoryArcDetails(uint256 arcId)`: Retrieves details about a specific story arc.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Outline and Function Summary as described above.

contract ChronicleForge is Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Governance & Treasury
    address public treasuryAddress; // Where funds accumulate, managed by DAO
    // address public immutable governanceToken; // Placeholder for a dedicated governance token if used, otherwise Insight is primary.

    // AI Oracle
    address public aiOracleAddress;

    // Counters for unique IDs
    Counters.Counter private _fragmentIds;
    Counters.Counter private _relicIds;
    Counters.Counter private _relicEvolutionProposalIds;
    Counters.Counter private _memoryShardIds;
    Counters.Counter private _generalProposalIds;
    Counters.Counter private _storyArcIds;

    // Data Structures

    // 1. Chronicle Fragments
    struct Fragment {
        uint256 id;
        address author;
        string content; // For simplicity, content is stored on-chain. For large content, use IPFS hash.
        uint256 parentFragmentId; // 0 for root fragments
        uint256 storyArcId;
        uint256 submissionTimestamp;
        bool isFinalized; // True if approved and added to official lore
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 totalVotes;
        bool insightClaimed; // To prevent double claiming Insight
        int256 oracleSentimentScore; // From AI oracle, e.g., -100 to 100
        uint256 oracleCohesionScore; // From AI oracle, e.g., 0 to 100
        bool oracleAnalysisReceived;
    }
    mapping(uint256 => Fragment) public fragments;
    mapping(uint256 => mapping(address => bool)) public fragmentVoters; // fragmentId => voterAddress => hasVoted

    // 2. Relics (Dynamic NFTs)
    struct Relic {
        uint256 id;
        uint256 storyArcId;
        string name;
        address creator; // The address that initiated the relic mint (via governance)
        uint256 mintTimestamp;
    }
    mapping(uint256 => Relic) public relics; // Stores info about Relics minted under this contract (ERC721)

    struct RelicEvolutionProposal {
        uint256 id;
        uint256 relicId;
        string newMetadataURI; // New metadata URI for the ERC721 token
        string justification; // Narrative justification for the evolution
        address proposer;
        uint256 submissionTimestamp;
        bool isFinalized;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 totalVotes;
    }
    mapping(uint256 => RelicEvolutionProposal) public relicEvolutionProposals;
    mapping(uint256 => mapping(address => bool)) public relicEvolutionVoters; // proposalId => voterAddress => hasVoted

    // 3. Reputation (Insight & Memory Shards)
    mapping(address => uint256) public participantInsight; // Non-transferable reputation score

    // Memory Shards (Soulbound NFTs)
    struct MemoryShard {
        uint256 id;
        address owner; // The current (and usually only) owner
        string shardType; // e.g., "FirstChronicler", "OracleWhisperer", "ArcArchitect"
        string loreContext; // e.g., "Fragment #10", "Relic Evolution #5"
        uint256 mintTimestamp;
    }
    mapping(uint256 => MemoryShard) public memoryShards; // Stores info about MemoryShards minted under this contract (ERC721)
    mapping(address => uint256[]) public ownerMemoryShards; // For efficient lookup of shards by owner

    // 4. General DAO Proposals
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct GeneralProposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 submissionTimestamp;
        uint256 votingEndTime;
        address targetContract; // Contract to call if proposal passes
        bytes callData; // Encoded function call for execution
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 totalVotes; // Sum of approval + rejection votes with Insight weight
        uint256 quorumRequired; // Minimum total votes (Insight) to pass
        ProposalState state;
        bool executed;
    }
    mapping(uint256 => GeneralProposal) public generalProposals;
    mapping(uint256 => mapping(address => bool)) public generalProposalVoters; // proposalId => voterAddress => hasVoted

    // 5. Story Arcs
    struct StoryArc {
        uint256 id;
        string title;
        string description;
        address creator; // Who proposed its creation via governance
        uint256 creationTimestamp;
        bool isActive; // Can new fragments be submitted under this arc?
    }
    mapping(uint256 => StoryArc) public storyArcs;
    uint256 public currentStoryArcId; // The ID of the currently active story arc

    // --- Configuration Constants ---
    uint256 public constant FRAGMENT_INSIGHT_REWARD = 100;
    uint256 public constant VOTING_PERIOD_SECONDS = 7 days;
    uint256 public constant MIN_INSIGHT_FOR_PROPOSAL = 500; // Minimum Insight to propose anything
    uint256 public constant MIN_INSIGHT_FOR_VOTE = 1; // Minimum Insight to vote on anything
    uint256 public constant GENERAL_PROPOSAL_QUORUM_PERCENT = 5; // e.g., 5% of hypothetical total Insight required as total votes

    // --- Events ---
    event ChronicleFragmentSubmitted(uint256 indexed fragmentId, address indexed author, uint256 storyArcId, uint256 parentFragmentId);
    event FragmentVoted(uint256 indexed fragmentId, address indexed voter, bool approved, uint256 insightWeight);
    event FragmentFinalized(uint256 indexed fragmentId, bool success);
    event InsightClaimed(uint256 indexed fragmentId, address indexed author, uint256 amount);
    event OracleAnalysisReceived(uint256 indexed fragmentId, int256 sentimentScore, uint256 cohesionScore);

    event RelicMinted(uint256 indexed tokenId, address indexed creator, uint256 storyArcId, string name);
    event RelicEvolutionProposed(uint256 indexed proposalId, uint256 indexed relicId, address indexed proposer, string newMetadataURI);
    event RelicEvolutionVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 insightWeight);
    event RelicEvolutionFinalized(uint256 indexed proposalId, uint256 indexed relicId, string newMetadataURI);

    event MemoryShardMinted(uint256 indexed shardId, address indexed to, string shardType, string loreContext);

    event GeneralProposalCreated(uint256 indexed proposalId, address indexed proposer, string title);
    event GeneralProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 insightWeight);
    event GeneralProposalExecuted(uint256 indexed proposalId);

    event StoryArcCreated(uint256 indexed arcId, string title, address indexed creator);
    event CurrentStoryArcSet(uint256 indexed oldArcId, uint256 indexed newArcId);

    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event TreasuryFundsTransferred(address indexed recipient, uint256 amount);


    // --- Constructor ---
    /// @notice Deploys the ChronicleForge contract, initializing the treasury and the first story arc.
    /// @param _treasuryAddress The address where collected ETH/funds will be held, managed by DAO.
    constructor(address _treasuryAddress) ERC721("ChronicleForgeRelic", "CFR") Ownable(msg.sender) {
        require(_treasuryAddress != address(0), "Treasury address cannot be zero");
        treasuryAddress = _treasuryAddress;

        // Create an initial story arc by the deployer (acting as initial governance)
        _storyArcIds.increment();
        uint256 initialArcId = _storyArcIds.current();
        storyArcs[initialArcId] = StoryArc({
            id: initialArcId,
            title: "The Genesis Chapter",
            description: "The very beginning of our shared lore.",
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            isActive: true
        });
        currentStoryArcId = initialArcId;
        emit StoryArcCreated(initialArcId, "The Genesis Chapter", msg.sender);
        emit CurrentStoryArcSet(0, initialArcId);
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Caller is not the AI Oracle");
        _;
    }

    modifier onlyInsightHolder() {
        require(participantInsight[msg.sender] >= MIN_INSIGHT_FOR_VOTE, "Not enough Insight to vote");
        _;
    }

    modifier onlyProposer() {
        require(participantInsight[msg.sender] >= MIN_INSIGHT_FOR_PROPOSAL, "Not enough Insight to propose");
        _;
    }

    // --- Internal/Helper Functions ---
    /// @notice Calculates the voting weight of an address based on their Insight score.
    /// @param voter The address of the voter.
    /// @return The voting weight (Insight score).
    function _getVotingWeight(address voter) internal view returns (uint256) {
        // In a more advanced system, Memory Shards could provide bonus voting weight.
        // e.g., for (uint256 shardId : ownerMemoryShards[voter]) { if (memoryShards[shardId].shardType == "ArcArchitect") weight += 500; }
        return participantInsight[voter];
    }

    /// @notice Calculates the quorum required for a general proposal based on a percentage of hypothetical total Insight.
    /// @dev In a live system, `hypotheticalTotalInsight` would be dynamic, reflecting the total 'Insight' in circulation.
    /// @return The required total Insight votes for quorum.
    function _calculateGeneralProposalQuorum() internal pure returns (uint256) {
        // This is a placeholder for `totalInsightSupply()` from an Insight token or a snapshot of active users.
        // For demonstration, we use a fixed hypothetical total Insight.
        uint256 hypotheticalTotalInsight = 100000;
        return (hypotheticalTotalInsight * GENERAL_PROPOSAL_QUORUM_PERCENT) / 100;
    }

    // --- I. Core Narrative Management (Chronicle Fragments) ---

    /// @notice Submits a new chronicle fragment to be voted on by the community.
    /// @param _content The narrative content of the fragment.
    /// @param _parentFragmentId The ID of the fragment this new fragment builds upon (0 for a root fragment).
    function submitChronicleFragment(string memory _content, uint256 _parentFragmentId) external {
        require(currentStoryArcId != 0, "No active story arc to submit fragments to.");
        require(bytes(_content).length > 0, "Fragment content cannot be empty.");
        if (_parentFragmentId != 0) {
            require(fragments[_parentFragmentId].id != 0, "Parent fragment does not exist.");
            require(fragments[_parentFragmentId].isFinalized, "Parent fragment must be finalized to build upon.");
        }

        _fragmentIds.increment();
        uint256 newFragmentId = _fragmentIds.current();

        fragments[newFragmentId] = Fragment({
            id: newFragmentId,
            author: msg.sender,
            content: _content,
            parentFragmentId: _parentFragmentId,
            storyArcId: currentStoryArcId,
            submissionTimestamp: block.timestamp,
            isFinalized: false,
            approvalVotes: 0,
            rejectionVotes: 0,
            totalVotes: 0,
            insightClaimed: false,
            oracleSentimentScore: 0,
            oracleCohesionScore: 0,
            oracleAnalysisReceived: false
        });

        emit ChronicleFragmentSubmitted(newFragmentId, msg.sender, currentStoryArcId, _parentFragmentId);
    }

    /// @notice Allows an Insight holder to vote on a submitted fragment.
    /// @param _fragmentId The ID of the fragment to vote on.
    /// @param _approve True for approval, false for rejection.
    function voteOnFragment(uint256 _fragmentId, bool _approve) external onlyInsightHolder {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "Fragment does not exist.");
        require(!fragment.isFinalized, "Fragment has already been finalized.");
        require(fragmentVoters[_fragmentId][msg.sender] == false, "Already voted on this fragment.");
        require(block.timestamp < fragment.submissionTimestamp + VOTING_PERIOD_SECONDS, "Voting period has ended.");

        uint256 voteWeight = _getVotingWeight(msg.sender);
        // require(voteWeight >= MIN_INSIGHT_FOR_VOTE, "Insufficient Insight to vote."); // Covered by onlyInsightHolder

        if (_approve) {
            fragment.approvalVotes += voteWeight;
        } else {
            fragment.rejectionVotes += voteWeight;
        }
        fragment.totalVotes += voteWeight;
        fragmentVoters[_fragmentId][msg.sender] = true;

        emit FragmentVoted(_fragmentId, msg.sender, _approve, voteWeight);
    }

    /// @notice Finalizes a fragment if it meets voting thresholds after its voting period.
    /// @dev Can be called by anyone. Approved fragments become part of the official lore.
    /// @param _fragmentId The ID of the fragment to finalize.
    function finalizeFragment(uint256 _fragmentId) external {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "Fragment does not exist.");
        require(!fragment.isFinalized, "Fragment already finalized.");
        require(block.timestamp >= fragment.submissionTimestamp + VOTING_PERIOD_SECONDS, "Voting period has not ended.");
        require(fragment.totalVotes > 0, "No votes cast on this fragment.");

        // Decision logic: A simple majority for now. Can be expanded with quorum, AI scores, etc.
        // Example: `bool approved = (fragment.approvalVotes > fragment.rejectionVotes) && (fragment.oracleAnalysisReceived ? fragment.oracleCohesionScore >= 60 : true);`
        bool approved = fragment.approvalVotes > fragment.rejectionVotes;

        fragment.isFinalized = approved;
        emit FragmentFinalized(_fragmentId, approved);
    }

    /// @notice Retrieves the detailed information for a specific fragment.
    /// @param _fragmentId The ID of the fragment.
    /// @return Fragment struct containing all details.
    function getFragmentDetails(uint256 _fragmentId) external view returns (Fragment memory) {
        require(fragments[_fragmentId].id != 0, "Fragment does not exist.");
        return fragments[_fragmentId];
    }

    /// @notice Retrieves the vote counts for a specific fragment.
    /// @param _fragmentId The ID of the fragment.
    /// @return approvalVotes The total approval votes.
    /// @return rejectionVotes The total rejection votes.
    /// @return totalVotes The sum of all votes cast (approval + rejection).
    function getFragmentVotes(uint256 _fragmentId) external view returns (uint256 approvalVotes, uint256 rejectionVotes, uint256 totalVotes) {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "Fragment does not exist.");
        return (fragment.approvalVotes, fragment.rejectionVotes, fragment.totalVotes);
    }

    // --- II. Relic (Dynamic NFT) Management ---

    /// @notice Mints a new Relic NFT, which represents a key item or character in the lore.
    /// @dev This function is intended to be called by `executeGeneralProposal` after a successful DAO vote.
    /// @param _storyArcId The ID of the story arc this relic belongs to.
    /// @param _name The name of the relic.
    /// @param _initialMetadataURI The initial URI for the relic's metadata (e.g., IPFS hash).
    function mintRelic(uint256 _storyArcId, string memory _name, string memory _initialMetadataURI) external onlyOwner { // Placeholder: Should be called by `executeGeneralProposal`
        require(storyArcs[_storyArcId].id != 0, "Story Arc does not exist.");
        _relicIds.increment();
        uint256 newRelicId = _relicIds.current();

        _mint(address(this), newRelicId); // Mint to contract itself, then governance can transfer it or keep it as DAO owned.
        _setTokenURI(newRelicId, _initialMetadataURI);

        relics[newRelicId] = Relic({
            id: newRelicId,
            storyArcId: _storyArcId,
            name: _name,
            creator: msg.sender, // The proposer of the DAO vote, or the executor.
            mintTimestamp: block.timestamp
        });

        emit RelicMinted(newRelicId, msg.sender, _storyArcId, _name);
    }

    /// @notice Proposes an evolution (metadata update) for a Relic based on narrative progression.
    /// @param _relicId The ID of the Relic to evolve.
    /// @param _newMetadataURI The new URI for the relic's metadata (e.g., updated IPFS hash).
    /// @param _justification A description of why this evolution is narratively significant.
    function proposeRelicEvolution(uint256 _relicId, string memory _newMetadataURI, string memory _justification) external onlyProposer {
        require(relics[_relicId].id != 0, "Relic does not exist.");
        require(ownerOf(_relicId) == address(this), "Relic must be owned by the contract (DAO) to propose evolution.");
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty.");
        require(bytes(_justification).length > 0, "Justification cannot be empty.");

        _relicEvolutionProposalIds.increment();
        uint256 newProposalId = _relicEvolutionProposalIds.current();

        relicEvolutionProposals[newProposalId] = RelicEvolutionProposal({
            id: newProposalId,
            relicId: _relicId,
            newMetadataURI: _newMetadataURI,
            justification: _justification,
            proposer: msg.sender,
            submissionTimestamp: block.timestamp,
            isFinalized: false,
            approvalVotes: 0,
            rejectionVotes: 0,
            totalVotes: 0
        });

        emit RelicEvolutionProposed(newProposalId, _relicId, msg.sender, _newMetadataURI);
    }

    /// @notice Allows Insight holders to vote on a Relic evolution proposal.
    /// @param _proposalId The ID of the evolution proposal.
    /// @param _approve True for approval, false for rejection.
    function voteOnRelicEvolution(uint256 _proposalId, bool _approve) external onlyInsightHolder {
        RelicEvolutionProposal storage proposal = relicEvolutionProposals[_proposalId];
        require(proposal.id != 0, "Relic evolution proposal does not exist.");
        require(!proposal.isFinalized, "Proposal has already been finalized.");
        require(relicEvolutionVoters[_proposalId][msg.sender] == false, "Already voted on this proposal.");
        require(block.timestamp < proposal.submissionTimestamp + VOTING_PERIOD_SECONDS, "Voting period has ended.");

        uint256 voteWeight = _getVotingWeight(msg.sender);
        // require(voteWeight >= MIN_INSIGHT_FOR_VOTE, "Insufficient Insight to vote."); // Covered by onlyInsightHolder

        if (_approve) {
            proposal.approvalVotes += voteWeight;
        } else {
            proposal.rejectionVotes += voteWeight;
        }
        proposal.totalVotes += voteWeight;
        relicEvolutionVoters[_proposalId][msg.sender] = true;

        emit RelicEvolutionVoted(_proposalId, msg.sender, _approve, voteWeight);
    }

    /// @notice Finalizes a Relic evolution proposal if it meets voting thresholds and applies the new metadata.
    /// @dev Can be called by anyone after voting period.
    /// @param _proposalId The ID of the evolution proposal.
    function finalizeRelicEvolution(uint256 _proposalId) external {
        RelicEvolutionProposal storage proposal = relicEvolutionProposals[_proposalId];
        require(proposal.id != 0, "Relic evolution proposal does not exist.");
        require(!proposal.isFinalized, "Proposal already finalized.");
        require(block.timestamp >= proposal.submissionTimestamp + VOTING_PERIOD_SECONDS, "Voting period has not ended.");
        require(proposal.totalVotes > 0, "No votes cast on this proposal.");

        bool approved = proposal.approvalVotes > proposal.rejectionVotes;

        proposal.isFinalized = true;

        if (approved) {
            _setTokenURI(proposal.relicId, proposal.newMetadataURI); // Apply the new metadata URI to the Relic NFT
            emit RelicEvolutionFinalized(_proposalId, proposal.relicId, proposal.newMetadataURI);
        } else {
            emit RelicEvolutionFinalized(_proposalId, proposal.relicId, "Rejected");
        }
    }

    /// @notice Retrieves the current details of a specific Relic NFT, including its URI.
    /// @param _relicId The ID of the Relic.
    /// @return Relic struct, metadataURI, owner.
    function getRelicDetails(uint256 _relicId) external view returns (Relic memory, string memory metadataURI, address currentOwner) {
        require(relics[_relicId].id != 0, "Relic does not exist.");
        return (relics[_relicId], tokenURI(_relicId), ownerOf(_relicId));
    }

    // --- III. Reputation & Rewards (Insight & Memory Shards) ---

    /// @notice Allows the author of a finalized fragment to claim their Insight reward.
    /// @param _fragmentId The ID of the finalized fragment.
    function claimFragmentInsight(uint256 _fragmentId) external {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "Fragment does not exist.");
        require(fragment.author == msg.sender, "Only the author can claim insight for this fragment.");
        require(fragment.isFinalized, "Fragment must be finalized to claim insight.");
        require(!fragment.insightClaimed, "Insight for this fragment has already been claimed.");

        participantInsight[msg.sender] += FRAGMENT_INSIGHT_REWARD;
        fragment.insightClaimed = true;

        emit InsightClaimed(_fragmentId, msg.sender, FRAGMENT_INSIGHT_REWARD);
    }

    /// @notice Retrieves the total Insight score for a given participant address.
    /// @param _participant The address to query.
    /// @return The Insight score.
    function getParticipantInsight(address _participant) external view returns (uint256) {
        return participantInsight[_participant];
    }

    /// @notice Mints a special, non-transferable Memory Shard NFT for significant achievements.
    /// @dev This function is intended to be called by `executeGeneralProposal` after a successful DAO vote.
    /// Memory Shards are conceptual Soulbound Tokens (SBTs) under this ERC721.
    /// @param _to The recipient of the Memory Shard.
    /// @param _shardType A string describing the type of shard (e.g., "FirstChronicler", "ArcArchitect").
    /// @param _loreContext A string providing context for the shard (e.g., "Fragment #1", "Story Arc: The Genesis").
    function mintMemoryShard(address _to, string memory _shardType, string memory _loreContext) external onlyOwner { // Placeholder: Should be called by `executeGeneralProposal`
        require(_to != address(0), "Recipient cannot be zero address.");
        require(bytes(_shardType).length > 0, "Shard type cannot be empty.");

        _memoryShardIds.increment();
        uint256 newShardId = _memoryShardIds.current();
        // To avoid ID collisions with Relics if they share the same base ERC721,
        // Memory Shards are given IDs in a separate, high range (e.g., starting from 1,000,000).
        // For simplicity here, they use their own counter, assuming the token ID space is large enough.
        // A true production setup would likely use distinct ERC721 contracts for Relics and Shards or careful ID management.

        _mint(_to, newShardId);
        _setTokenURI(newShardId, string(abi.encodePacked("ipfs://memoryshard/", _shardType, ".json")));

        memoryShards[newShardId] = MemoryShard({
            id: newShardId,
            owner: _to,
            shardType: _shardType,
            loreContext: _loreContext,
            mintTimestamp: block.timestamp
        });

        ownerMemoryShards[_to].push(newShardId);

        emit MemoryShardMinted(newShardId, _to, _shardType, _loreContext);
    }

    /// @notice Retrieves details about a specific Memory Shard.
    /// @param _shardId The ID of the Memory Shard.
    /// @return MemoryShard struct.
    function getMemoryShardDetails(uint256 _shardId) external view returns (MemoryShard memory) {
        require(memoryShards[_shardId].id != 0, "Memory Shard does not exist.");
        return memoryShards[_shardId];
    }

    /// @notice Returns a list of Memory Shard IDs owned by a specific address.
    /// @param _owner The address to query.
    /// @return An array of Memory Shard IDs.
    function getMemoryShardsOfOwner(address _owner) external view returns (uint256[] memory) {
        return ownerMemoryShards[_owner];
    }

    // --- IV. AI Oracle Integration (Simulated) ---

    /// @notice Sets the address of the trusted AI Oracle.
    /// @dev This function is intended to be called by `executeGeneralProposal` after a successful DAO vote.
    /// @param _oracleAddress The new address for the AI Oracle.
    function setOracleAddress(address _oracleAddress) external onlyOwner { // Placeholder: Should be called by `executeGeneralProposal`
        require(_oracleAddress != address(0), "Oracle address cannot be zero.");
        address oldAddress = aiOracleAddress;
        aiOracleAddress = _oracleAddress;
        emit OracleAddressSet(oldAddress, aiOracleAddress);
    }

    /// @notice Requests the AI oracle to analyze a specific fragment.
    /// @dev In a real system, this would involve calling an external oracle contract (e.g., Chainlink Functions)
    /// which would then perform off-chain AI analysis and callback this contract.
    /// @param _fragmentId The ID of the fragment to analyze.
    function requestFragmentAnalysis(uint256 _fragmentId) external {
        require(fragments[_fragmentId].id != 0, "Fragment does not exist.");
        require(!fragments[_fragmentId].oracleAnalysisReceived, "Analysis already requested or received for this fragment.");
        // A real implementation would send a request to the oracle contract, e.g.:
        // IChainlinkOracle(aiOracleAddress).requestAnalysis(address(this), _fragmentId, fragments[_fragmentId].content);
        // For this example, we just signal the intent. The oracle calls back directly.
    }

    /// @notice Callback function for the AI oracle to submit analysis results.
    /// @dev Only callable by the designated AI Oracle address.
    /// @param _fragmentId The ID of the fragment that was analyzed.
    /// @param _sentimentScore The sentiment score from the AI (e.g., -100 for very negative to 100 for very positive).
    /// @param _cohesionScore The narrative cohesion score from the AI (e.g., 0 for very low to 100 for very high).
    function receiveOracleAnalysis(uint256 _fragmentId, int256 _sentimentScore, uint256 _cohesionScore) external onlyAIOracle {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "Fragment does not exist.");
        require(!fragment.oracleAnalysisReceived, "Oracle analysis already received for this fragment.");

        fragment.oracleSentimentScore = _sentimentScore;
        fragment.oracleCohesionScore = _cohesionScore;
        fragment.oracleAnalysisReceived = true;

        emit OracleAnalysisReceived(_fragmentId, _sentimentScore, _cohesionScore);
    }

    // --- V. DAO Governance & Treasury ---

    /// @notice Creates a general governance proposal for the community to vote on.
    /// @param _title The title of the proposal.
    /// @param _description A detailed description of the proposal.
    /// @param _targetContract The address of the contract to call if the proposal passes (can be `address(this)`).
    /// @param _callData The encoded function call to execute if the proposal passes (e.g., `abi.encodeWithSignature("functionName(uint256)", value)`).
    function proposeGeneralVote(string memory _title, string memory _description, address _targetContract, bytes memory _callData) external onlyProposer {
        _generalProposalIds.increment();
        uint252 newProposalId = _generalProposalIds.current();

        generalProposals[newProposalId] = GeneralProposal({
            id: newProposalId,
            title: _title,
            description: _description,
            proposer: msg.sender,
            submissionTimestamp: block.timestamp,
            votingEndTime: block.timestamp + VOTING_PERIOD_SECONDS,
            targetContract: _targetContract,
            callData: _callData,
            approvalVotes: 0,
            rejectionVotes: 0,
            totalVotes: 0,
            quorumRequired: _calculateGeneralProposalQuorum(),
            state: ProposalState.Active,
            executed: false
        });

        emit GeneralProposalCreated(newProposalId, msg.sender, _title);
    }

    /// @notice Allows Insight holders to vote on a general governance proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _approve True for approval, false for rejection.
    function voteOnGeneralProposal(uint256 _proposalId, bool _approve) external onlyInsightHolder {
        GeneralProposal storage proposal = generalProposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist.");
        require(proposal.state == ProposalState.Active, "Proposal is not active for voting.");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended.");
        require(generalProposalVoters[_proposalId][msg.sender] == false, "Already voted on this proposal.");

        uint256 voteWeight = _getVotingWeight(msg.sender);
        // require(voteWeight >= MIN_INSIGHT_FOR_VOTE, "Insufficient Insight to vote."); // Covered by onlyInsightHolder

        if (_approve) {
            proposal.approvalVotes += voteWeight;
        } else {
            proposal.rejectionVotes += voteWeight;
        }
        proposal.totalVotes += voteWeight;
        generalProposalVoters[_proposalId][msg.sender] = true;

        emit GeneralProposalVoted(_proposalId, msg.sender, _approve, voteWeight);
    }

    /// @notice Executes a general governance proposal if it has passed and met quorum.
    /// @dev Can be called by anyone after the voting period ends.
    /// @param _proposalId The ID of the proposal to execute.
    function executeGeneralProposal(uint256 _proposalId) external {
        GeneralProposal storage proposal = generalProposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist.");
        require(proposal.state != ProposalState.Executed, "Proposal already executed.");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended.");

        if (proposal.totalVotes < proposal.quorumRequired) {
            proposal.state = ProposalState.Failed;
            revert("Quorum not met.");
        }

        if (proposal.approvalVotes <= proposal.rejectionVotes) {
            proposal.state = ProposalState.Failed;
            revert("Proposal rejected by majority.");
        }

        // If it reaches here, proposal passed
        proposal.state = ProposalState.Succeeded;

        // Execute the call data
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed.");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit GeneralProposalExecuted(_proposalId);
    }

    /// @notice Allows the DAO to transfer funds from the contract's treasury to a specified recipient.
    /// @dev This function is intended to be called by `executeGeneralProposal` after a successful DAO vote.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of funds to transfer.
    function transferTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner { // Placeholder: Should be called by `executeGeneralProposal`
        require(_recipient != address(0), "Recipient cannot be zero address.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(address(this).balance >= _amount, "Insufficient balance in treasury.");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to transfer treasury funds.");

        emit TreasuryFundsTransferred(_recipient, _amount);
    }

    /// @notice Fallback function to receive ETH into the contract's treasury.
    receive() external payable {
        // Funds sent directly to the contract will accumulate in its balance, managed by DAO governance.
    }

    // --- VI. Story Arc & Event Management ---

    /// @notice Creates a new major story arc.
    /// @dev This function is intended to be called by `executeGeneralProposal` after a successful DAO vote.
    /// @param _title The title of the new story arc.
    /// @param _description A description of the story arc.
    function createStoryArc(string memory _title, string memory _description) external onlyOwner { // Placeholder: Should be called by `executeGeneralProposal`
        require(bytes(_title).length > 0, "Story arc title cannot be empty.");

        _storyArcIds.increment();
        uint256 newArcId = _storyArcIds.current();

        storyArcs[newArcId] = StoryArc({
            id: newArcId,
            title: _title,
            description: _description,
            creator: msg.sender, // The proposer of the DAO vote, or the executor.
            creationTimestamp: block.timestamp,
            isActive: false // Must be set active by a separate governance vote (or can be combined)
        });

        emit StoryArcCreated(newArcId, _title, msg.sender);
    }

    /// @notice Sets the active story arc, under which new fragments will be submitted by default.
    /// @dev This function is intended to be called by `executeGeneralProposal` after a successful DAO vote.
    /// @param _arcId The ID of the story arc to set as active.
    function setCurrentStoryArc(uint256 _arcId) external onlyOwner { // Placeholder: Should be called by `executeGeneralProposal`
        require(storyArcs[_arcId].id != 0, "Story Arc does not exist.");
        require(!storyArcs[_arcId].isActive, "Story Arc is already active. No change needed.");

        // Deactivate previous active arc if any
        if (currentStoryArcId != 0) {
            storyArcs[currentStoryArcId].isActive = false;
        }

        storyArcs[_arcId].isActive = true;
        uint256 oldArcId = currentStoryArcId;
        currentStoryArcId = _arcId;
        emit CurrentStoryArcSet(oldArcId, currentStoryArcId);
    }

    /// @notice Retrieves details about a specific story arc.
    /// @param _arcId The ID of the story arc.
    /// @return StoryArc struct.
    function getStoryArcDetails(uint256 _arcId) external view returns (StoryArc memory) {
        require(storyArcs[_arcId].id != 0, "Story Arc does not exist.");
        return storyArcs[_arcId];
    }

    // --- ERC721 Overrides for Soulbound Shards (Conceptual) ---
    // For a truly non-transferable Memory Shard, the `_beforeTokenTransfer` function would be overridden.
    // However, since this contract also manages "Relic" NFTs which are ERC721s that might be transferable
    // by governance, carefully distinguishing between token IDs for Relics and Shards is crucial.
    // For this example, the concept of Soulbound Memory Shards is conveyed by their role and minting process,
    // assuming a separate or carefully managed ERC721 implementation would enforce non-transferability.

    /*
    // Example of how to make Memory Shards non-transferable if they share the same ERC721 base as Relics
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Assuming Memory Shards have a distinct ID range or can be identified
        // This is a simplified check; a real system would need more robust ID management
        // to differentiate between Relics and Shards if they are both in the same ERC721.
        if (memoryShards[tokenId].id != 0) { // Check if `tokenId` belongs to a MemoryShard
            require(from == address(0) || to == address(0), "Memory Shards are soulbound and cannot be transferred.");
        }
    }
    */
}
```