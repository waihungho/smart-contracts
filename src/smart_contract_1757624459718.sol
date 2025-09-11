This smart contract, "ChronicleEchoes," introduces a novel concept: **Self-Evolving Digital Entities (SEDEs)** represented as NFTs. These NFTs are more than just static images; they possess dynamic traits, accumulate 'wisdom' and 'empathy' scores based on interactions and external data, contribute to a shared narrative, and can even influence system-wide changes through a specialized 'Lore Council'. The contract integrates a simulated oracle for external data influence and features 'Temporal Anchors' to snapshot an Echo's state, enabling potential future "narrative branching" or "state rewinds."

---

## ChronicleEchoes Smart Contract

**Concept:** A collection of Non-Fungible Tokens (NFTs) representing "Echoes" – digital entities that dynamically evolve based on user interactions, internal metrics, and external (oracle-fed) events. Owners contribute to a shared narrative and participate in a unique governance model.

---

### Outline & Function Summary

**I. Core NFT & Ownership Management (ERC721 Standard Adaptations)**
1.  **`constructor()`**: Initializes the contract, sets the name, symbol, and designates the deployer as the initial owner.
2.  **`mintEcho(address _to)`**: Mints a new Echo NFT to a specified address, assigning it an initial state.
3.  **`tokenURI(uint256 _tokenId)`**: Generates a dynamic URI for the Echo's metadata, reflecting its current evolving state (traits, scores).
4.  **`burnEcho(uint256 _tokenId)`**: Allows an owner to destroy their Echo NFT, removing it from existence and potentially affecting the shared narrative.
5.  *(Standard ERC721 functions like `transferFrom`, `approve`, `setApprovalForAll` are inherited and not explicitly listed but are part of the contract's functionality)*

**II. Echo Evolution & State Management**
6.  **`recordEchoActivity(uint256 _tokenId, uint256 _activityBoost)`**: Allows the owner or approved entity to log activity for an Echo, boosting its internal activity score.
7.  **`triggerEchoEvolution(uint256 _tokenId)`**: Initiates an on-chain process for a specific Echo, recalculating its `wisdomScore` and `empathyScore` based on accumulated activity, oracle data, and interactions, potentially unlocking new traits.
8.  **`proposeTraitChange(uint256 _tokenId, bytes32 _traitKey, bool _activate)`**: An Echo owner can propose adding or removing a specific symbolic 'trait' for their Echo, subject to community or council approval.
9.  **`voteOnTraitProposal(uint256 _proposalId, bool _for)`**: Allows eligible voters (e.g., other Echo owners or Lore Council) to vote on proposed trait changes for an Echo.
10. **`executeTraitChange(uint256 _proposalId)`**: Executes the trait change if the proposal passes the voting threshold.
11. **`getEchoState(uint256 _tokenId)`**: Public view function to retrieve the full current state (scores, active traits) of a specific Echo.
12. **`establishTemporalAnchor(uint256 _tokenId, string memory _description)`**: Records a snapshot of an Echo's current state (scores and active traits) at a specific point in time, allowing for historical reference or future "narrative branching."

**III. Narrative & Interactivity**
13. **`submitNarrativeFragment(string memory _contentHash)`**: Allows any Echo owner to submit a piece of lore or a narrative fragment (referenced by an IPFS hash) to the collective ChronicleEchoes universe.
14. **`voteOnNarrativeRelevance(uint256 _fragmentId, bool _approve)`**: Members of the Lore Council vote on whether a submitted narrative fragment should be officially recognized and integrated into the overarching lore.
15. **`attuneEchoToEvent(uint256 _tokenId, bytes32 _externalEventId)`**: Links an Echo to a specific external event identifier (e.g., a real-world event, a new game challenge), which can influence its `empathyScore` and `resonance`.
16. **`calculateResonanceWithTarget(uint256 _echoAId, uint256 _echoBId)`**: Calculates a "resonance score" between two Echoes, reflecting their alignment based on shared traits, activity patterns, or attunement to similar events.

**IV. Oracle Integration (Simulated)**
17. **`setOracleAddress(address _oracleAddress)`**: Admin function to set or update the address of the trusted oracle.
18. **`reportOracleData(bytes32 _dataKey, uint256 _value)`**: The designated oracle calls this function to feed external, verified data into the contract, influencing Echo evolution or narrative shifts.

**V. Lore Council & Governance**
19. **`delegateInfluence(uint256 _fromEchoId, uint256 _toEchoId)`**: Allows an Echo owner to delegate their Echo's governance influence (voting power) to another Echo, fostering alliances or specialized roles within the community.
20. **`proposeGlobalShift(bytes32 _proposalHash, string memory _description)`**: Only Lore Council members can propose system-wide changes or major narrative shifts (e.g., new trait categories, evolution rules, major lore events).
21. **`voteOnGlobalShift(uint256 _proposalId, bool _for)`**: Lore Council members vote on proposed global shifts.
22. **`joinLoreCouncil(uint256 _echoId)`**: Allows an Echo that meets specific criteria (e.g., high wisdomScore, influencePower) to apply for membership in the Lore Council.
23. **`getLoreCouncilMembers()`**: A view function to list all current members of the Lore Council.

**VI. Administrative & Utility**
24. **`pause()`**: Pauses contract functionality in case of emergency. (Owner only)
25. **`unpause()`**: Unpauses contract functionality. (Owner only)
26. **`withdrawFunds(address _to)`**: Allows the contract owner to withdraw any collected funds (e.g., minting fees).
27. **`setBaseURI(string memory _newBaseURI)`**: Admin function to update the base URI for NFT metadata, used by `tokenURI`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary (as provided above the code block)

contract ChronicleEchoes is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---

    struct EchoState {
        uint256 creationTimestamp;
        uint256 activityScore; // Reflects user interactions, boosts evolution
        uint256 wisdomScore;   // Derived from activity, oracle data, and successful challenges
        uint256 empathyScore;  // Derived from attunements, shared events, and social interactions
        uint256 influencePower; // Governs voting weight, increases with wisdom/empathy
        mapping(bytes32 => bool) activeTraits; // Dynamic, symbolic traits
        uint256 lastEvolutionTimestamp; // When its state last significantly changed
    }

    struct TemporalAnchor {
        uint256 timestamp;
        uint256 activityScore;
        uint256 wisdomScore;
        uint256 empathyScore;
        string description;
        // Note: activeTraits cannot be directly stored in a struct within a mapping like this.
        // For a full snapshot, an off-chain metadata URI would link to this anchor.
        // On-chain, we can only store the key metrics.
    }

    struct EvolutionProposal {
        uint256 proposalId;
        uint256 tokenId;
        bytes32 traitKey;
        bool activate; // True to add, False to remove
        address proposer;
        uint256 creationTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Address of the voter (owner of a voting Echo)
        bool executed;
        bool passed;
    }

    struct NarrativeFragment {
        uint256 fragmentId;
        uint256 submittedByTokenId;
        string contentHash; // IPFS hash of the narrative content
        uint256 submissionTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVotedCouncil; // Lore Council members only
        bool approvedByCouncil;
    }

    struct GlobalShiftProposal {
        uint256 proposalId;
        bytes32 proposalHash; // Unique ID for the proposal content (e.g., IPFS hash)
        string description;
        address proposerAddress; // Address of the Lore Council member proposing
        uint256 creationTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVotedCouncil; // Lore Council members only
        bool executed;
        bool passed;
    }

    // --- State Variables ---

    mapping(uint256 => EchoState) public echoes;
    mapping(uint256 => TemporalAnchor[]) public temporalAnchors; // tokenId => array of anchors

    // Evolution Proposals
    Counters.Counter private _evolutionProposalIdCounter;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;

    // Narrative Fragments
    Counters.Counter private _narrativeFragmentIdCounter;
    mapping(uint256 => NarrativeFragment) public narrativeFragments;
    uint256 public constant NARRATIVE_APPROVAL_THRESHOLD = 70; // % required for approval

    // Lore Council
    mapping(address => bool) public isLoreCouncilMember; // address => is member
    address[] public loreCouncilMembers;
    uint256 public constant LORE_COUNCIL_MIN_WISDOM = 500; // Minimum wisdom to join
    uint256 public constant LORE_COUNCIL_MIN_EMPATHY = 300; // Minimum empathy to join

    // Global Shift Proposals
    Counters.Counter private _globalShiftProposalIdCounter;
    mapping(uint256 => GlobalShiftProposal) public globalShiftProposals;
    uint256 public constant GLOBAL_SHIFT_APPROVAL_THRESHOLD = 75; // % required for approval

    // Oracle Configuration
    address public oracleAddress;
    mapping(bytes32 => uint256) public oracleData; // dataKey => value

    // Base URI for metadata
    string private _baseURI;

    // --- Events ---

    event EchoMinted(uint256 indexed tokenId, address indexed owner);
    event EchoBurned(uint256 indexed tokenId);
    event EchoActivityRecorded(uint256 indexed tokenId, uint256 activityBoost, uint256 newActivityScore);
    event EchoEvolutionTriggered(uint256 indexed tokenId, uint256 newWisdom, uint256 newEmpathy);
    event TraitProposalCreated(uint256 indexed proposalId, uint256 indexed tokenId, bytes32 traitKey, bool activate);
    event TraitProposalVoted(uint256 indexed proposalId, address indexed voter, bool votedFor);
    event TraitChangeExecuted(uint256 indexed proposalId, uint256 indexed tokenId, bytes32 traitKey, bool activated);
    event TemporalAnchorEstablished(uint256 indexed tokenId, uint256 timestamp, string description);
    event NarrativeFragmentSubmitted(uint256 indexed fragmentId, uint256 indexed submittedByTokenId, string contentHash);
    event NarrativeFragmentVoted(uint256 indexed fragmentId, address indexed voter, bool approved);
    event NarrativeFragmentApproved(uint256 indexed fragmentId);
    event OracleAddressSet(address indexed newOracleAddress);
    event OracleDataReported(bytes32 indexed dataKey, uint256 value);
    event InfluenceDelegated(uint256 indexed fromEchoId, uint256 indexed toEchoId, address indexed delegator);
    event LoreCouncilMemberJoined(address indexed memberAddress, uint256 indexed echoId);
    event GlobalShiftProposed(uint256 indexed proposalId, bytes32 proposalHash, address indexed proposer);
    event GlobalShiftVoted(uint256 indexed proposalId, address indexed voter, bool votedFor);
    event GlobalShiftExecuted(uint252 indexed proposalId, bool passed);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronicleEchoes: Caller is not the oracle");
        _;
    }

    modifier onlyLoreCouncilMember() {
        require(isLoreCouncilMember[msg.sender], "ChronicleEchoes: Caller is not a Lore Council member");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("ChronicleEchoes", "ECHO") Ownable(msg.sender) {
        // Initial setup for the owner (deployer)
    }

    // --- I. Core NFT & Ownership Management ---

    function mintEcho(address _to) public payable whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);

        EchoState storage newEcho = echoes[newItemId];
        newEcho.creationTimestamp = block.timestamp;
        newEcho.activityScore = 1; // Initial activity
        newEcho.wisdomScore = 10;  // Base wisdom
        newEcho.empathyScore = 5;  // Base empathy
        newEcho.influencePower = 1; // Base influence
        newEcho.lastEvolutionTimestamp = block.timestamp;
        newEcho.activeTraits[keccak256("Initial Spark")] = true; // Example initial trait

        // Optional: require a minting fee
        // require(msg.value >= 0.01 ether, "ChronicleEchoes: Minting fee required");

        emit EchoMinted(newItemId, _to);
        return newItemId;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI;
        if (bytes(base).length == 0) {
            return super.tokenURI(_tokenId);
        }

        EchoState storage echo = echoes[_tokenId];
        // Example dynamic URI. In a real scenario, this would point to an API that generates
        // JSON metadata based on the Echo's current state (scores, traits).
        // For simplicity, we just append token ID and some state.
        return string(abi.encodePacked(base, Strings.toString(_tokenId), "/",
            "wisdom-", Strings.toString(echo.wisdomScore),
            "-empathy-", Strings.toString(echo.empathyScore),
            ".json"));
    }

    function burnEcho(uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronicleEchoes: Caller is not owner nor approved");
        _burn(_tokenId);
        // Optionally clean up echoes mapping, but not strictly necessary as _exists will be false
        delete echoes[_tokenId];
        // Also consider deleting associated proposals, anchors, etc., or marking them inactive.
        emit EchoBurned(_tokenId);
    }

    // --- II. Echo Evolution & State Management ---

    function recordEchoActivity(uint256 _tokenId, uint256 _activityBoost) public whenNotPaused {
        require(_exists(_tokenId), "ChronicleEchoes: Echo does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronicleEchoes: Caller is not owner nor approved");
        require(_activityBoost > 0, "ChronicleEchoes: Activity boost must be positive");

        EchoState storage echo = echoes[_tokenId];
        echo.activityScore += _activityBoost;
        emit EchoActivityRecorded(_tokenId, _activityBoost, echo.activityScore);
    }

    function triggerEchoEvolution(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ChronicleEchoes: Echo does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronicleEchoes: Caller is not owner nor approved");
        require(block.timestamp > echoes[_tokenId].lastEvolutionTimestamp + 1 days, "ChronicleEchoes: Evolution can only be triggered once a day"); // Cooldown

        EchoState storage echo = echoes[_tokenId];

        // Example Evolution Logic:
        // Wisdom increases with accumulated activity and oracle insights
        echo.wisdomScore += (echo.activityScore / 10) + (oracleData[keccak256("GlobalWisdomFactor")] / 100);
        // Empathy increases with attunements (simulated) and shared events
        echo.empathyScore += (echo.activityScore / 20) + (oracleData[keccak256("SocialSentiment")] / 500);

        // Reset activity for next cycle
        echo.activityScore = 0;
        echo.lastEvolutionTimestamp = block.timestamp;

        // Influence power scales with combined scores
        echo.influencePower = (echo.wisdomScore + echo.empathyScore) / 100;
        if (echo.influencePower == 0) echo.influencePower = 1; // Ensure min influence

        // Potentially unlock new traits based on score thresholds
        if (echo.wisdomScore >= 100 && !echo.activeTraits[keccak256("Insightful")]) {
            echo.activeTraits[keccak256("Insightful")] = true;
            emit TraitChangeExecuted(0, _tokenId, keccak256("Insightful"), true); // 0 for auto-unlock
        }
        if (echo.empathyScore >= 50 && !echo.activeTraits[keccak256("Harmonious")]) {
            echo.activeTraits[keccak256("Harmonious")] = true;
            emit TraitChangeExecuted(0, _tokenId, keccak256("Harmonious"), true); // 0 for auto-unlock
        }

        emit EchoEvolutionTriggered(_tokenId, echo.wisdomScore, echo.empathyScore);
    }

    function proposeTraitChange(uint256 _tokenId, bytes32 _traitKey, bool _activate) public whenNotPaused {
        require(_exists(_tokenId), "ChronicleEchoes: Echo does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronicleEchoes: Caller is not owner nor approved");
        require(_traitKey != bytes32(0), "ChronicleEchoes: Trait key cannot be empty");

        _evolutionProposalIdCounter.increment();
        uint256 proposalId = _evolutionProposalIdCounter.current();

        evolutionProposals[proposalId] = EvolutionProposal({
            proposalId: proposalId,
            tokenId: _tokenId,
            traitKey: _traitKey,
            activate: _activate,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit TraitProposalCreated(proposalId, _tokenId, _traitKey, _activate);
    }

    function voteOnTraitProposal(uint256 _proposalId, bool _for) public whenNotPaused {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.tokenId != 0, "ChronicleEchoes: Proposal does not exist");
        require(!proposal.executed, "ChronicleEchoes: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "ChronicleEchoes: Already voted on this proposal");
        
        // Only Echo owners can vote, and their vote weight depends on their Echo's influence power
        uint256 voterEchoId = _tokenOfOwnerByIndex(msg.sender, 0); // Assuming one Echo per owner for simplicity or first owned
        require(_exists(voterEchoId), "ChronicleEchoes: Voter must own an Echo");
        
        uint256 voteWeight = echoes[voterEchoId].influencePower;
        require(voteWeight > 0, "ChronicleEchoes: Voter Echo has no influence power");

        if (_for) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit TraitProposalVoted(_proposalId, msg.sender, _for);
    }

    function executeTraitChange(uint256 _proposalId) public whenNotPaused {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.tokenId != 0, "ChronicleEchoes: Proposal does not exist");
        require(!proposal.executed, "ChronicleEchoes: Proposal already executed");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "ChronicleEchoes: No votes cast yet");

        // Simple majority for now. Could be more complex (e.g., quorum + percentage).
        if (proposal.votesFor * 100 / totalVotes >= 51) {
            EchoState storage echo = echoes[proposal.tokenId];
            echo.activeTraits[proposal.traitKey] = proposal.activate;
            proposal.passed = true;
        } else {
            proposal.passed = false;
        }
        proposal.executed = true;

        emit TraitChangeExecuted(proposal.proposalId, proposal.tokenId, proposal.traitKey, proposal.activate);
    }
    
    function getEchoState(uint256 _tokenId) public view returns (uint256, uint256, uint256, uint256, uint256) {
        require(_exists(_tokenId), "ChronicleEchoes: Echo does not exist");
        EchoState storage echo = echoes[_tokenId];
        return (echo.creationTimestamp, echo.activityScore, echo.wisdomScore, echo.empathyScore, echo.influencePower);
    }

    function establishTemporalAnchor(uint256 _tokenId, string memory _description) public whenNotPaused {
        require(_exists(_tokenId), "ChronicleEchoes: Echo does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronicleEchoes: Caller is not owner nor approved");
        
        EchoState storage echo = echoes[_tokenId];
        temporalAnchors[_tokenId].push(TemporalAnchor({
            timestamp: block.timestamp,
            activityScore: echo.activityScore,
            wisdomScore: echo.wisdomScore,
            empathyScore: echo.empathyScore,
            description: _description
        }));
        emit TemporalAnchorEstablished(_tokenId, block.timestamp, _description);
    }

    // --- III. Narrative & Interactivity ---

    function submitNarrativeFragment(string memory _contentHash) public whenNotPaused {
        require(bytes(_contentHash).length > 0, "ChronicleEchoes: Content hash cannot be empty");
        uint256 submitterEchoId = _tokenOfOwnerByIndex(msg.sender, 0); // Assuming submitter owns an Echo
        require(_exists(submitterEchoId), "ChronicleEchoes: Submitter must own an Echo");

        _narrativeFragmentIdCounter.increment();
        uint256 fragmentId = _narrativeFragmentIdCounter.current();

        narrativeFragments[fragmentId] = NarrativeFragment({
            fragmentId: fragmentId,
            submittedByTokenId: submitterEchoId,
            contentHash: _contentHash,
            submissionTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            approvedByCouncil: false
        });

        emit NarrativeFragmentSubmitted(fragmentId, submitterEchoId, _contentHash);
    }

    function voteOnNarrativeRelevance(uint256 _fragmentId, bool _approve) public onlyLoreCouncilMember whenNotPaused {
        NarrativeFragment storage fragment = narrativeFragments[_fragmentId];
        require(fragment.submittedByTokenId != 0, "ChronicleEchoes: Narrative fragment does not exist");
        require(!fragment.approvedByCouncil, "ChronicleEchoes: Fragment already approved");
        require(!fragment.hasVotedCouncil[msg.sender], "ChronicleEchoes: Already voted on this fragment");

        if (_approve) {
            fragment.votesFor++;
        } else {
            fragment.votesAgainst++;
        }
        fragment.hasVotedCouncil[msg.sender] = true;

        // Check for approval
        uint256 totalCouncilVotes = fragment.votesFor + fragment.votesAgainst;
        if (totalCouncilVotes > 0 && fragment.votesFor * 100 / totalCouncilVotes >= NARRATIVE_APPROVAL_THRESHOLD) {
            fragment.approvedByCouncil = true;
            emit NarrativeFragmentApproved(_fragmentId);
        }
        emit NarrativeFragmentVoted(_fragmentId, msg.sender, _approve);
    }

    function attuneEchoToEvent(uint256 _tokenId, bytes32 _externalEventId) public whenNotPaused {
        require(_exists(_tokenId), "ChronicleEchoes: Echo does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronicleEchoes: Caller is not owner nor approved");
        require(_externalEventId != bytes32(0), "ChronicleEchoes: Event ID cannot be empty");

        // This function represents an Echo connecting to an event.
        // It could trigger a small empathy boost or unlock specific traits.
        EchoState storage echo = echoes[_tokenId];
        echo.empathyScore += 1; // Small boost for attunement
        // Optionally, store the attunement for resonance calculations
        // For simplicity, we directly use _externalEventId for resonance later.
        emit EchoActivityRecorded(_tokenId, 1, echo.activityScore); // Treat attunement as activity
    }

    function calculateResonanceWithTarget(uint256 _echoAId, uint256 _echoBId) public view returns (uint256) {
        require(_exists(_echoAId) && _exists(_echoBId), "ChronicleEchoes: One or both Echoes do not exist");

        EchoState storage echoA = echoes[_echoAId];
        EchoState storage echoB = echoes[_echoBId];

        uint256 resonanceScore = 0;

        // Base resonance from empathy and wisdom alignment
        resonanceScore += (100 - absDiff(echoA.empathyScore, echoB.empathyScore)) / 10;
        resonanceScore += (100 - absDiff(echoA.wisdomScore, echoB.wisdomScore)) / 20;

        // Trait alignment (simplified: just check for one specific shared trait)
        if (echoA.activeTraits[keccak256("Insightful")] && echoB.activeTraits[keccak256("Insightful")]) {
            resonanceScore += 20;
        }
        if (echoA.activeTraits[keccak256("Harmonious")] && echoB.activeTraits[keccak256("Harmonious")]) {
            resonanceScore += 15;
        }

        // Incorporate oracle data or attunements if they were explicitly stored for each echo.
        // For now, it's simulated as internal scores.

        return resonanceScore > 100 ? 100 : resonanceScore; // Cap at 100 for readability
    }
    
    // Helper function for resonance calculation
    function absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    // --- IV. Oracle Integration (Simulated) ---

    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ChronicleEchoes: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    function reportOracleData(bytes32 _dataKey, uint256 _value) public onlyOracle whenNotPaused {
        oracleData[_dataKey] = _value;
        emit OracleDataReported(_dataKey, _value);
    }

    // --- V. Lore Council & Governance ---

    function delegateInfluence(uint256 _fromEchoId, uint256 _toEchoId) public whenNotPaused {
        require(_exists(_fromEchoId) && _exists(_toEchoId), "ChronicleEchoes: One or both Echoes do not exist");
        require(_isApprovedOrOwner(msg.sender, _fromEchoId), "ChronicleEchoes: Caller is not owner of fromEchoId");
        require(ownerOf(_fromEchoId) != ownerOf(_toEchoId), "ChronicleEchoes: Cannot delegate to an Echo owned by the same address"); // Delegate to another owner's Echo
        
        // This is a placeholder. Real delegation would involve transferring voting power
        // not just influencePower directly, perhaps through a snapshot or token-based system.
        // For simplicity, we just mark it.
        // A more robust system would update a global delegation mapping for voting.
        emit InfluenceDelegated(_fromEchoId, _toEchoId, msg.sender);
    }

    function proposeGlobalShift(bytes32 _proposalHash, string memory _description) public onlyLoreCouncilMember whenNotPaused {
        require(bytes(_proposalHash).length > 0, "ChronicleEchoes: Proposal hash cannot be empty");
        _globalShiftProposalIdCounter.increment();
        uint256 proposalId = _globalShiftProposalIdCounter.current();

        globalShiftProposals[proposalId] = GlobalShiftProposal({
            proposalId: proposalId,
            proposalHash: _proposalHash,
            description: _description,
            proposerAddress: msg.sender,
            creationTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });
        emit GlobalShiftProposed(proposalId, _proposalHash, msg.sender);
    }

    function voteOnGlobalShift(uint255 _proposalId, bool _for) public onlyLoreCouncilMember whenNotPaused {
        GlobalShiftProposal storage proposal = globalShiftProposals[_proposalId];
        require(proposal.proposerAddress != address(0), "ChronicleEchoes: Proposal does not exist");
        require(!proposal.executed, "ChronicleEchoes: Proposal already executed");
        require(!proposal.hasVotedCouncil[msg.sender], "ChronicleEchoes: Already voted on this proposal");

        if (_for) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVotedCouncil[msg.sender] = true;
        
        // Check for execution logic (could be separate function or time-based)
        // For simplicity, we just log the vote. Actual execution would need a separate trigger/logic.
        emit GlobalShiftVoted(_proposalId, msg.sender, _for);
    }

    function executeGlobalShift(uint256 _proposalId) public onlyLoreCouncilMember whenNotPaused {
        GlobalShiftProposal storage proposal = globalShiftProposals[_proposalId];
        require(proposal.proposerAddress != address(0), "ChronicleEchoes: Proposal does not exist");
        require(!proposal.executed, "ChronicleEchoes: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "ChronicleEchoes: No votes cast yet");

        if (proposal.votesFor * 100 / totalVotes >= GLOBAL_SHIFT_APPROVAL_THRESHOLD) {
            proposal.passed = true;
            // In a real scenario, this would trigger internal logic changes,
            // e.g., updating contract parameters, enabling new features, etc.
            // For this example, it's a symbolic outcome.
        } else {
            proposal.passed = false;
        }
        proposal.executed = true;
        emit GlobalShiftExecuted(_proposalId, proposal.passed);
    }

    function joinLoreCouncil(uint256 _echoId) public whenNotPaused {
        require(_exists(_echoId), "ChronicleEchoes: Echo does not exist");
        require(ownerOf(_echoId) == msg.sender, "ChronicleEchoes: Caller must own the Echo");
        require(!isLoreCouncilMember[msg.sender], "ChronicleEchoes: Already a Lore Council member");

        EchoState storage echo = echoes[_echoId];
        require(echo.wisdomScore >= LORE_COUNCIL_MIN_WISDOM, "ChronicleEchoes: Echo does not meet minimum wisdom for council");
        require(echo.empathyScore >= LORE_COUNCIL_MIN_EMPATHY, "ChronicleEchoes: Echo does not meet minimum empathy for council");

        isLoreCouncilMember[msg.sender] = true;
        loreCouncilMembers.push(msg.sender);
        emit LoreCouncilMemberJoined(msg.sender, _echoId);
    }

    function getLoreCouncilMembers() public view returns (address[] memory) {
        return loreCouncilMembers;
    }

    // --- VI. Administrative & Utility ---

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawFunds(address _to) public onlyOwner {
        require(_to != address(0), "ChronicleEchoes: Withdrawal address cannot be zero");
        payable(_to).transfer(address(this).balance);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURI = _newBaseURI;
    }

    // --- Internal/View Helpers ---

    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    // Helper to get the first owned token for a given address (for voting/submission context)
    // In a production scenario, you might have a more robust way to select an Echo if an owner has many.
    function _tokenOfOwnerByIndex(address _owner, uint256 _index) internal view returns (uint256) {
        uint256 ownedTokensCount = balanceOf(_owner);
        if (_index >= ownedTokensCount) {
            return 0; // Return 0 if index out of bounds
        }
        // This is a very gas-inefficient method for many tokens.
        // A better approach for contracts needing frequent lookups from address to token ID
        // is to maintain an explicit mapping or a linked list.
        // For simplicity, we assume owners primarily interact with "their" Echo or have few.
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i) && ownerOf(i) == _owner) {
                if (_index == 0) return i; // Return the first one found
                _index--;
            }
        }
        return 0;
    }
}
```