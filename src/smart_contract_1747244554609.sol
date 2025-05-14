Okay, here is a smart contract concept in Solidity based on a "Procedural Guild Chronicle" theme. It incorporates concepts like dynamic difficulty based on state, delegation of internal "skill" points, event-based state changes ("Chronicles"), and managing unique, evolving digital assets ("Artifacts") with procedural elements.

It aims to be creative by not being a standard token, marketplace, or DeFi primitive clone, but rather a simulation of a complex, stateful on-chain organization focused on crafting digital items under dynamic rules.

---

**Contract Name:** ChronicleOfTheWeaverGuild

**Concept:**
A smart contract representing a decentralized guild where "Weavers" (members) contribute "Threads" (internal resource simulation), weave unique digital "Artifacts" (NFT-like) using "Patterns", gain "Skill" points, and participate in "Chronicles" (timed events). The difficulty of weaving dynamically adjusts based on overall guild activity and a global "Loom Complexity Index". Weavers can delegate their skill points to others, simulating mentorship or collaboration. Artifacts have procedural "Traits" based on weaving parameters.

**Outline:**

1.  **Pragma and Imports:** Specifies Solidity version and imports (minimal ERC721 interface for core functions).
2.  **Errors:** Custom errors for clearer revert reasons.
3.  **Events:** Logs key actions and state changes.
4.  **Structs:** Define data structures for Weaver, Artifact, TraitType, Pattern, and Chronicle.
5.  **Enums:** Define WeaverRanks and PatternStatus.
6.  **State Variables:** Store contract ownership, council address, counters, core data mappings, guild state parameters, and treasury.
7.  **Modifiers:** Restrict function access (owner, council, weaver, active chronicle).
8.  **Constructor:** Initializes the contract owner and basic state.
9.  **Core Guild Membership:** Join/leave the guild.
10. **Resource Management (Simulated Threads):** Deposit/withdraw from guild treasury.
11. **Trait Type Management:** Define and retrieve static trait types.
12. **Pattern Management:** Propose, approve, deprecate, and retrieve patterns.
13. **Artifact Weaving:** The core logic for creating new artifacts, including dynamic difficulty calculation, skill updates, and trait assignment.
14. **Artifact Management:** Transfer (custom, within guild), burn, retrieve info. Basic ERC721 views.
15. **Skill Delegation:** Delegate and reclaim weaving power (skill points).
16. **Weaver Management:** Grant/revoke ranks, retrieve weaver info.
17. **Guild State & Difficulty:** Get global complexity index, calculate weaving difficulty (view).
18. **Chronicles:** Initiate, participate in, and claim rewards from timed events.
19. **View Functions:** Get various pieces of state data.

**Function Summary:**

1.  `constructor()`: Initializes contract, sets deployer as owner.
2.  `setCouncilAddress(address _council)`: Owner sets the address of the governance/council multisig (e.g.).
3.  `joinGuild()`: Allows an address to become a Weaver. Costs internal threads. Increments total weavers.
4.  `leaveGuild()`: Allows a Weaver to leave the guild. Potential consequences (e.g., skill/rank loss).
5.  `depositThreads()`: Allows anyone to send ether to the contract, simulating depositing 'Threads' into the treasury.
6.  `withdrawTreasury(uint256 amount)`: Council/Owner withdraws funds from the treasury.
7.  `addTraitType(string memory _name, uint256 _rarityScore, bytes memory _data)`: Council/Owner defines a new type of trait that artifacts can have.
8.  `proposePattern(string memory _name, uint256 _requiredThreads, uint256 _baseComplexity, uint256[] memory _requiredTraitTypeIds, uint256[] memory _requiredTraitIds)`: A Weaver can propose a new pattern using a deposit.
9.  `approvePattern(uint256 _patternId)`: Council/Owner approves a proposed pattern, making it usable.
10. `deprecatePattern(uint256 _patternId)`: Council/Owner marks a pattern as deprecated, preventing new artifacts from being woven with it.
11. `weaveArtifact(uint256 _patternId, uint256[] memory _chosenTraitIds)`: The core function. Weaver attempts to weave an artifact using an approved pattern and chosen traits. Calculates dynamic difficulty, checks skill vs. difficulty for success probability, consumes threads, mints artifact NFT, updates weaver skill, and adjusts Loom Complexity Index.
12. `transferArtifactToWeaver(address _from, address _to, uint256 _artifactId)`: Custom transfer function allowing artifact transfers *only between existing Weavers*.
13. `burnArtifact(uint256 _artifactId)`: Allows an artifact owner (must be a Weaver) to burn their artifact for a small benefit (e.g., threads back, skill boost).
14. `delegateWeavingPower(address _delegatee)`: A Weaver delegates their current skill points to another Weaver. Their own skill becomes 0 until reclaimed.
15. `reclaimWeavingPower()`: A Weaver reclaims their delegated skill points.
16. `grantRank(address _weaver, WeaverRank _rank)`: Council/Owner grants a specific rank to a Weaver.
17. `revokeRank(address _weaver)`: Council/Owner removes a Weaver's rank.
18. `initiateChronicle(string memory _name, uint40 _durationSeconds, uint256 _requiredSkillAvg, uint256 _rewardPool)`: Council/Owner starts a special timed event (Chronicle).
19. `participateInChronicle()`: Allows a Weaver to register participation in the currently active Chronicle (if criteria met).
20. `claimChronicleReward()`: Allows participants of a *finished* Chronicle to claim their share of rewards (logic for distribution needed, kept simple here).
21. `isWeaver(address _addr) view`: Checks if an address is a Weaver.
22. `getWeaverInfo(address _addr) view`: Retrieves a Weaver's details.
23. `getTotalWeavers() view`: Gets the total number of weavers.
24. `getGuildTreasury() view`: Gets the current treasury balance.
25. `getTraitTypeInfo(uint256 _traitTypeId) view`: Gets details of a defined trait type.
26. `getPatternInfo(uint256 _patternId) view`: Gets details of a pattern.
27. `getArtifactInfo(uint256 _artifactId) view`: Gets details of an artifact.
28. `getArtifactTraits(uint256 _artifactId) view`: Gets the trait IDs of an artifact.
29. `getTotalArtifacts() view`: Gets the total number of artifacts woven.
30. `getWeaverArtifacts(address _weaver) view`: Gets a list of artifact IDs woven by a specific Weaver.
31. `getLoomComplexityIndex() view`: Gets the current global Loom Complexity Index.
32. `calculateWeavingDifficulty(uint256 _patternId) view`: Calculates the *potential* difficulty for weaving a specific pattern *now* based on current state.
33. `predictWeavingSuccess(uint256 _patternId, address _weaver) view`: Gives a theoretical success score/probability estimate for a weaver attempting a pattern *without* actual randomness.
34. `getDelegatee(address _weaver) view`: Checks who a weaver has delegated their skill to.
35. `getDelegator(address _weaver) view`: Checks who has delegated skill *to* a weaver.
36. `getChronicleInfo(uint256 _chronicleId) view`: Gets details of a chronicle.
37. `getActiveChronicleId() view`: Gets the ID of the currently active chronicle (0 if none).

*Note: Some functions are marked `view` or `pure` where appropriate. The total count exceeds 20.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleOfTheWeaverGuild
 * @dev A smart contract simulating a decentralized guild for weaving dynamic digital artifacts.
 *      Features include:
 *      - Weaver membership with skill points and ranks.
 *      - Simulated internal resource management (Threads).
 *      - Dynamic artifact weaving based on patterns and traits.
 *      - Difficulty adjustment based on global state (Loom Complexity Index).
 *      - Skill point delegation between Weavers.
 *      - Timed guild events (Chronicles) for participation and rewards.
 *      - Custom ERC721-like management for Artifacts (within the guild context).
 *      - A wide array of functions for interaction and querying state.
 */

// Minimal ERC721-like interfaces needed for internal use
interface IERC721Like {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // Not strictly needed for this concept, but good practice
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // Not strictly needed

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
    // function transferFrom(address from, address to, uint256 tokenId) external; // Using custom transfer in this contract
    // function approve(address to, uint256 tokenId) external;
    // function setApprovalForAll(address operator, bool approved) external;
    // function getApproved(uint256 tokenId) external view returns (address operator);
    // function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// --- Errors ---
error NotOwner();
error NotCouncil();
error NotWeaver();
error WeaverAlreadyExists();
error WeaverNotFound();
error InsufficientThreads(uint256 required, uint256 available);
error TraitTypeNotFound();
error PatternNotFound();
error PatternNotApproved();
error PatternDeprecated();
error ArtifactNotFound();
error NotArtifactOwner();
error OnlyWeaversAllowed();
error CannotDelegateToSelf();
error AlreadyDelegating();
error NotDelegating();
error DelegationActive(address delegatee);
error WeaverHasDelegation(address delegator);
error ChronicleNotFound();
error NoActiveChronicle();
error ChronicleActive();
error ChronicleNotActive();
error ChronicleAlreadyEnded();
error AlreadyParticipatedInChronicle();
error NotChronicleParticipant();
error WeaverDoesNotMeetChronicleCriteria();
error NoRewardsToClaim();
error InvalidRank();


// --- Events ---
event WeaverJoined(address indexed weaver, uint40 joinTime);
event WeaverLeft(address indexed weaver);
event ThreadsDeposited(address indexed sender, uint256 amount);
event TreasuryWithdrawn(address indexed recipient, uint256 amount);
event TraitTypeAdded(uint256 indexed id, string name);
event PatternProposed(uint256 indexed id, address indexed proposer, string name);
event PatternApproved(uint256 indexed id);
event PatternDeprecated(uint256 indexed id);
event ArtifactWoven(uint256 indexed artifactId, address indexed weaver, uint256 patternId, uint256 complexity);
event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed artifactId);
event ArtifactBurned(uint256 indexed artifactId, address indexed owner);
event SkillDelegated(address indexed delegator, address indexed delegatee, uint256 skillAmount);
event SkillReclaimed(address indexed weaver, uint256 skillAmount);
event RankGranted(address indexed weaver, uint8 rank); // Use uint8 for rank enum
event RankRevoked(address indexed weaver);
event ChronicleInitiated(uint256 indexed id, string name, uint40 startTime, uint40 endTime);
event ChronicleParticipated(uint256 indexed chronicleId, address indexed weaver);
event ChronicleRewardClaimed(uint256 indexed chronicleId, address indexed weaver, uint256 amount);
event LoomComplexityAdjusted(uint256 newComplexityIndex);


// --- Structs ---
enum WeaverRank { Novice, Apprentice, Journeyman, Master }
enum PatternStatus { Proposed, Approved, Deprecated }

struct Weaver {
    address addr;
    uint256 skillPoints;
    WeaverRank rank;
    uint40 joinTime;
    address delegatedTo; // Address they delegated skill TO
    address delegator; // Address that delegated skill TO them
    uint256 delegatedPower; // Amount of skill delegated to them
    uint256[] wovenArtifacts; // List of artifact IDs woven by this weaver
}

struct Artifact {
    uint256 id;
    address owner; // Current owner (implements ERC721-like ownership)
    uint256 patternId;
    uint256 complexity;
    uint256[] traitIds; // IDs referencing TraitType struct
    uint40 wovenTime;
    address weaver; // Original weaver
    bool isBurnt; // Flag if the artifact is burned
}

struct TraitType {
    uint256 id;
    string name;
    uint256 rarityScore; // Influence on complexity or value
    bytes data; // Optional data field
}

struct Pattern {
    uint256 id;
    string name;
    uint256 requiredThreads;
    uint256 baseComplexity; // Base difficulty/complexity modifier
    uint256[] requiredTraitTypeIds; // Required categories of traits
    uint256[] requiredTraitIds; // Specific trait IDs required (optional)
    PatternStatus status;
    address proposer;
}

struct Chronicle {
    uint256 id;
    string name;
    uint40 startTime;
    uint40 endTime;
    uint256 requiredSkillAvg; // Minimum average skill to participate
    uint256 rewardPool; // Total threads/value available as rewards
    address[] participants; // Addresses of weavers who joined
    mapping(address => bool) hasClaimedReward; // Track reward claims
}


// --- State Variables ---
address public owner;
address public council; // Address designated for council actions (can be a multisig)

uint256 public totalWeavers;
uint256 public nextArtifactId = 1; // Start artifact IDs from 1
uint256 public nextPatternId = 1;
uint256 public nextTraitTypeId = 1;
uint256 public nextChronicleId = 1;

mapping(address => Weaver) private weavers;
mapping(uint256 => Artifact) private artifacts;
mapping(uint256 => uint256) private artifactOwners; // Mapping token ID to owner address (ERC721 standard)
mapping(address => uint256) private artifactBalance; // Mapping owner address to balance (ERC721 standard)
mapping(uint256 => Pattern) private patterns;
mapping(uint256 => TraitType) private traitTypes;
mapping(uint256 => Chronicle) private chronicles;

uint256 public guildTreasury; // Simulated threads (represented by contract's ETH balance)
uint256 public loomComplexityIndex; // Global index affecting weaving difficulty, starts low

uint256 public activeChronicleId; // ID of the currently active chronicle (0 if none)


// --- Modifiers ---
modifier onlyOwner() {
    if (msg.sender != owner) revert NotOwner();
    _;
}

modifier onlyCouncil() {
    // Allow owner OR council address to perform council actions
    if (msg.sender != owner && msg.sender != council) revert NotCouncil();
    _;
}

modifier onlyWeaver() {
    if (!weavers[msg.sender].addr.isZero()) revert NotWeaver(); // Check if addr field is set
    _;
}

modifier onlyActiveChronicle() {
    if (activeChronicleId == 0) revert NoActiveChronicle();
    if (block.timestamp < chronicles[activeChronicleId].startTime || block.timestamp > chronicles[activeChronicleId].endTime) revert ChronicleNotActive();
    _;
}

// --- Constructor ---
constructor() {
    owner = msg.sender;
    // Council can be set later by owner
    // Initialize default ranks or traits here if needed
}

// --- Core Guild Membership ---
function joinGuild() public payable {
    if (weavers[msg.sender].addr != address(0)) revert WeaverAlreadyExists();

    uint256 joinCost = 0.01 ether; // Example cost to join (simulated threads)
    if (msg.value < joinCost) revert InsufficientThreads(joinCost, msg.value);

    // Return any excess ETH sent
    if (msg.value > joinCost) {
        payable(msg.sender).transfer(msg.value - joinCost);
    }

    weavers[msg.sender] = Weaver({
        addr: msg.sender,
        skillPoints: 1, // Start with minimal skill
        rank: WeaverRank.Novice,
        joinTime: uint40(block.timestamp),
        delegatedTo: address(0),
        delegator: address(0),
        delegatedPower: 0,
        wovenArtifacts: new uint256[](0)
    });

    guildTreasury += joinCost; // Add cost to treasury (simulated threads)

    totalWeavers++;
    emit WeaverJoined(msg.sender, uint40(block.timestamp));
}

function leaveGuild() public onlyWeaver {
    address weaverAddr = msg.sender;
    Weaver storage weaver = weavers[weaverAddr];

    // --- Delegation Cleanup ---
    // If this weaver delegated power to someone, reclaim it first
    if (weaver.delegatedTo != address(0)) {
        reclaimWeavingPower(); // This will handle the delegatee update
    }
    // If someone delegated power TO this weaver, clear their delegator field
    if (weaver.delegator != address(0)) {
         weavers[weaver.delegator].delegatedTo = address(0);
         weaver.delegatedPower = 0; // Should already be 0 by reclaim logic, but double-check
    }


    // --- Artifact Handling (Choose a policy: burn, transfer to guild, etc.) ---
    // For simplicity, let's assume artifacts owned by the leaving weaver remain owned by their address
    // but they can no longer interact with the guild ecosystem functions (transferToWeaver, burnArtifact via this contract)
    // unless they rejoin. The ERC721 functions like ownerOf will still work.

    // Remove weaver from mapping (effectively deletes their data)
    delete weavers[weaverAddr];

    totalWeavers--;
    emit WeaverLeft(weaverAddr);
}

// --- Resource Management (Simulated Threads) ---
function depositThreads() public payable {
    guildTreasury += msg.value;
    emit ThreadsDeposited(msg.sender, msg.value);
}

function withdrawTreasury(uint256 amount) public onlyCouncil {
    if (amount > guildTreasury) revert InsufficientThreads(amount, guildTreasury);
    guildTreasury -= amount;
    payable(msg.sender).transfer(amount); // Send actual ETH
    emit TreasuryWithdrawn(msg.sender, amount);
}

// --- Trait Type Management ---
function addTraitType(string memory _name, uint256 _rarityScore, bytes memory _data) public onlyCouncil {
    uint256 traitId = nextTraitTypeId++;
    traitTypes[traitId] = TraitType(traitId, _name, _rarityScore, _data);
    emit TraitTypeAdded(traitId, _name);
}

// --- Pattern Management ---
function proposePattern(string memory _name, uint256 _requiredThreads, uint256 _baseComplexity, uint256[] memory _requiredTraitTypeIds, uint256[] memory _requiredTraitIds) public onlyWeaver payable {
    // Optional: require a proposal deposit, returnable if approved/rejected
    uint256 patternId = nextPatternId++;
    patterns[patternId] = Pattern({
        id: patternId,
        name: _name,
        requiredThreads: _requiredThreads,
        baseComplexity: _baseComplexity,
        requiredTraitTypeIds: _requiredTraitTypeIds,
        requiredTraitIds: _requiredTraitIds,
        status: PatternStatus.Proposed,
        proposer: msg.sender
    });
    emit PatternProposed(patternId, msg.sender, _name);
}

function approvePattern(uint256 _patternId) public onlyCouncil {
    Pattern storage pattern = patterns[_patternId];
    if (pattern.id == 0) revert PatternNotFound();
    if (pattern.status != PatternStatus.Proposed) revert PatternNotApproved(); // Already approved or deprecated

    pattern.status = PatternStatus.Approved;
    emit PatternApproved(_patternId);
}

function deprecatePattern(uint256 _patternId) public onlyCouncil {
    Pattern storage pattern = patterns[_patternId];
    if (pattern.id == 0) revert PatternNotFound();
    if (pattern.status == PatternStatus.Deprecated) revert PatternDeprecated();

    pattern.status = PatternStatus.Deprecated;
    emit PatternDeprecated(_patternId);
}

// --- Artifact Weaving ---
// Simulates a dynamic process. Success probability depends on weaver skill vs calculated difficulty.
// Randomness is based on block.timestamp which is weak pseudo-randomness for demonstration.
function weaveArtifact(uint256 _patternId, uint256[] memory _chosenTraitIds) public onlyWeaver {
    address weaverAddr = msg.sender;
    Weaver storage weaver = weavers[weaverAddr];
    Pattern storage pattern = patterns[_patternId];

    if (pattern.id == 0) revert PatternNotFound();
    if (pattern.status != PatternStatus.Approved) revert PatternNotApproved();

    if (guildTreasury < pattern.requiredThreads) revert InsufficientThreads(pattern.requiredThreads, guildTreasury);

    // Validate chosen traits (optional, could add checks against requiredTraitTypeIds)
    // For simplicity, assuming chosen traits match the pattern's requirements conceptually

    guildTreasury -= pattern.requiredThreads; // Consume threads

    // --- Dynamic Difficulty Calculation ---
    uint256 currentDifficulty = calculateWeavingDifficulty(_patternId);

    // --- Success Probability & Skill Influence ---
    // Use a simplified probabilistic model: success chance increases with skill vs difficulty.
    // Using block.timestamp for pseudo-randomness (NOT SECURE FOR HIGH-VALUE APPS)
    uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nextArtifactId))) % 100; // 0-99
    uint256 weaverScore = weaver.skillPoints;
    // If weaver has delegated power to them, use their combined effective skill
    if (weaver.delegator != address(0)) {
       weaverScore += weaver.delegatedPower;
    }

    // Success score: Higher score means higher chance. Skill helps, difficulty hurts.
    uint252 successScore = (weaverScore * 5) + randomFactor; // Example formula
    uint256 targetScore = currentDifficulty * 10; // Example formula (difficulty scaled up)

    bool success = successScore >= targetScore;

    uint256 finalComplexity = pattern.baseComplexity; // Base complexity for the artifact

    if (success) {
        weaver.skillPoints++; // Reward skill for successful weaving

        // Assign chosen traits to the artifact
        // (In a real system, this would need more robust validation)
        uint256[] memory artifactTraitIds = new uint256[](_chosenTraitIds.length);
        for(uint i = 0; i < _chosenTraitIds.length; i++) {
            if (traitTypes[_chosenTraitIds[i]].id == 0) revert TraitTypeNotFound();
            artifactTraitIds[i] = _chosenTraitIds[i];
            // Incorporate trait rarity/data into finalComplexity if desired
            // finalComplexity += traitTypes[_chosenTraitIds[i]].rarityScore;
        }

        uint256 artifactId = nextArtifactId++;
        artifacts[artifactId] = Artifact({
            id: artifactId,
            owner: weaverAddr, // Owner is the weaver initially
            patternId: _patternId,
            complexity: finalComplexity,
            traitIds: artifactTraitIds,
            wovenTime: uint40(block.timestamp),
            weaver: weaverAddr,
            isBurnt: false
        });

        // Update ERC721-like mappings
        artifactOwners[artifactId] = weaverAddr;
        artifactBalance[weaverAddr]++;

        weaver.wovenArtifacts.push(artifactId);

        // Increase global complexity index upon successful weaving
        loomComplexityIndex++;

        emit ArtifactWoven(artifactId, weaverAddr, _patternId, finalComplexity);
        emit Transfer(address(0), weaverAddr, artifactId); // ERC721 Mint Event

    } else {
        // Optional: partial thread refund, small skill gain even on failure, etc.
        // For simplicity, threads are consumed, no artifact is created, but skill might slightly increase.
        weaver.skillPoints += 0; // No skill gain on failure for now
        // Maybe return a small portion of threads?
        // guildTreasury += pattern.requiredThreads / 4;
        // payable(msg.sender).transfer(pattern.requiredThreads / 4); // Send ETH back

        // Do NOT increase loomComplexityIndex on failure
        // Event for failed weaving?
        // emit WeavingFailed(weaverAddr, _patternId, calculatedDifficulty);
    }

    // Loom Complexity Index might also increase simply with time or total weavers
    // (Logic can be added here or in a separate function called periodically)
     emit LoomComplexityAdjusted(loomComplexityIndex);
}

// --- Artifact Management (ERC721-like subset) ---

// Custom transfer: only allow transfers between existing Weavers
function transferArtifactToWeaver(address _from, address _to, uint256 _artifactId) public {
    // Basic checks for ERC721 transfer
    if (artifactOwners[_artifactId] == address(0)) revert ArtifactNotFound();
    if (artifactOwners[_artifactId] != _from) revert NotArtifactOwner(); // Only owner can initiate transfer
    // Allow owner to transfer to self or another weaver
    if (msg.sender != _from && msg.sender != owner && msg.sender != council) revert NotArtifactOwner(); // Only owner/approved/operator ( simplified to owner/council for now)

    // Additional guild-specific check: target must be a Weaver
    if (weavers[_to].addr.isZero()) revert OnlyWeaversAllowed();

    // --- Perform Transfer ---
    artifactBalance[_from]--;
    artifactOwners[_artifactId] = _to;
    artifactBalance[_to]++;
    artifacts[_artifactId].owner = _to; // Update internal struct owner field too

    emit ArtifactTransferred(_from, _to, _artifactId);
    emit Transfer(_from, _to, _artifactId); // ERC721 Transfer Event
}

function burnArtifact(uint256 _artifactId) public {
    address ownerAddr = artifactOwners[_artifactId];
    if (ownerAddr == address(0)) revert ArtifactNotFound();
    if (ownerAddr != msg.sender) revert NotArtifactOwner();
    // Ensure the owner is still a weaver to burn via this function
    if (weavers[ownerAddr].addr.isZero()) revert NotWeaver();

    Artifact storage artifact = artifacts[_artifactId];
    if (artifact.isBurnt) revert ArtifactNotFound(); // Already burnt

    // --- Perform Burn ---
    artifact.isBurnt = true;
    artifactOwners[_artifactId] = address(0); // Clear owner
    artifactBalance[ownerAddr]--;

    // Optional: Reward the weaver for burning
    // guildTreasury += artifact.complexity / 10; // Example: return threads based on complexity
    // weavers[ownerAddr].skillPoints++; // Example: small skill boost

    emit ArtifactBurned(_artifactId, ownerAddr);
    emit Transfer(ownerAddr, address(0), _artifactId); // ERC721 Burn Event
}

// ERC721 Standard View Functions (minimal)
function ownerOf(uint256 tokenId) public view returns (address) {
    address ownerAddr = artifactOwners[tokenId];
    if (ownerAddr == address(0) && tokenId > 0 && tokenId < nextArtifactId) {
         // Artifact exists but owner is 0 (e.g., burned or initial state before mint)
         revert ArtifactNotFound(); // Or return address(0) depending on strict ERC721 interpretation
    }
    return ownerAddr;
}

function balanceOf(address ownerAddr) public view returns (uint256) {
    return artifactBalance[ownerAddr];
}


// --- Skill Delegation ---
function delegateWeavingPower(address _delegatee) public onlyWeaver {
    address delegatorAddr = msg.sender;
    Weaver storage delegator = weavers[delegatorAddr];
    Weaver storage delegatee = weavers[_delegatee];

    if (delegatorAddr == _delegatee) revert CannotDelegateToSelf();
    if (delegatee.addr.isZero()) revert WeaverNotFound(); // Delegatee must be a weaver
    if (delegator.delegatedTo != address(0)) revert AlreadyDelegating(); // Cannot delegate if already delegating

    uint256 skillToDelegate = delegator.skillPoints; // Delegate all current skill

    // Update delegator's state
    delegator.delegatedTo = _delegatee;
    // delegator.skillPoints = 0; // Skill points conceptually moved/represented by delegatedPower

    // Update delegatee's state
    delegatee.delegator = delegatorAddr; // Track who delegated to them
    delegatee.delegatedPower += skillToDelegate; // Add delegated power

    emit SkillDelegated(delegatorAddr, _delegatee, skillToDelegate);
}

function reclaimWeavingPower() public onlyWeaver {
    address weaverAddr = msg.sender;
    Weaver storage weaver = weavers[weaverAddr];

    if (weaver.delegatedTo == address(0)) revert NotDelegating();

    address delegateeAddr = weaver.delegatedTo;
    Weaver storage delegatee = weavers[delegateeAddr];

    // Find the amount of power specifically delegated BY THIS weaver to the delegatee
    // (This simplified implementation assumes 1:1 delegation. A real system needs
    // to track multiple delegations to a single weaver more carefully, e.g., using a mapping)
    uint256 powerToReclaim = 0;
    if (delegatee.delegator == weaverAddr) { // Check if this weaver is the *only* one delegating to delegatee
        powerToReclaim = delegatee.delegatedPower;
        delegatee.delegatedPower = 0;
        delegatee.delegator = address(0);
    } else {
       // Handle case where multiple weavers delegate to the same person
       // Need a mapping like `mapping(address => mapping(address => uint256))` to track delegated amounts
       // For now, assume 1:1 and powerToReclaim is `weaver.skillPoints` *at the time of delegation*
       // This simplified model breaks if skill changes *after* delegation.
       // Let's simplify further: reclaim means delegatee loses the *current* skill amount that originated from this delegator.
       // This requires tracking the amount delegated. Let's add `delegatedPowerOut` to Weaver.
       // Reverting to simpler: `delegatedTo` and `delegator/delegatedPower` only support 1:1 delegation.
       // If A delegates to B, B can only receive from A. If A reclaims, B loses all delegatedPower from A.
       // If C then tries to delegate to B, it would fail unless B is no longer receiving from A.
       // Let's assume delegatedPower on delegatee comes *only* from `delegatee.delegator`.
        powerToReclaim = delegatee.delegatedPower; // Reclaim whatever was delegated to them by the person they delegated from
        delegatee.delegatedPower = 0;
        delegatee.delegator = address(0); // Clear the incoming delegation
    }


    // Restore skill points conceptually (they weren't actually set to 0 before,
    // but the `getEffectiveSkill` helper would have handled it)
    // For this simplified model, `skillPoints` *includes* delegated power if someone delegated *to* them.
    // Reclaiming means removing the incoming power.
    // If I delegate OUT, my `skillPoints` doesn't change, but `getEffectiveSkill` for me is 0.
    // If I reclaim, my `getEffectiveSkill` becomes my `skillPoints`.
    // If someone delegates TO me, my `skillPoints` doesn't change, but `getEffectiveSkill` for me includes their power.
    // If they reclaim, my `getEffectiveSkill` reduces.
    // Let's adjust the Weaver struct and delegation logic to reflect this.

    // --- Revised Delegation Logic ---
    // Weaver struct: skillPoints (base), delegatedTo (who I delegate *to*), effectiveDelegatedPowerOut (power I've given away, for tracking), incomingDelegations (mapping/array of who delegated to me and how much).
    // This gets complicated quickly. Let's stick to the simplest: 1:1 outgoing delegation, 1:1 incoming delegation tracker.
    // `skillPoints` = BASE skill. `delegatedPower` on the receiving end = amount received.
    // `getEffectiveSkill(addr)`: If `weavers[addr].delegatedTo != address(0)`, return 0. Else, return `weavers[addr].skillPoints + weavers[addr].delegatedPower`.

    // Reclaiming power: The weaver who *delegated out* is calling this.
    // Find the weaver they delegated to (`delegateeAddr`).
    // Clear the `delegator` and `delegatedPower` on the `delegatee`.
    // Clear the `delegatedTo` on the `delegator`.

    if (delegatee.delegator != weaverAddr) {
        // This case happens if the delegatee received power from someone ELSE after THIS weaver delegated out.
        // This simplified 1:1 model breaks here. Need a more complex delegation structure.
        // Let's enforce that you can only reclaim if the delegatee *still has* your specific delegation.
        // This requires storing the amount delegated *out*. Add `delegatedPowerOut` to Weaver.
        // Weaver { ..., delegatedTo: address, delegatedPowerOut: uint256, ... }
        // Delegate function: `delegator.delegatedTo = _delegatee; delegator.delegatedPowerOut = delegator.skillPoints; delegatee.incomingDelegations[delegatorAddr] = delegator.skillPoints;`
        // Reclaim function: `amount = delegator.delegatedPowerOut; delegator.delegatedTo = address(0); delegator.delegatedPowerOut = 0; delete delegatee.incomingDelegations[delegatorAddr];`
        // getEffectiveSkill: `totalIncoming = sum(incomingDelegations); return weaver.skillPoints + totalIncoming;`

        // Simpler 1:1 again: A delegates to B. B gets A's skill. A cannot delegate elsewhere. C cannot delegate to B.
        // Reclaiming: A reclaims from B. B loses A's skill. B can then receive from C.
        // This requires tracking the amount A delegated to B. Let's add `delegatedAmount` to `delegatedTo` mapping.
        // `mapping(address => mapping(address => uint256)) public delegatedAmounts; // delegator => delegatee => amount`

        // Let's revert to the *very* simple model: 1:1 delegation tracked by `delegatedTo` and `delegator`/`delegatedPower`.
        // Reclaiming: the delegator calls this. We clear the link on both sides.
        // The `delegatedPower` on the delegatee represents the sum of power THEY RECEIVED.
        // To reclaim, the delegator must 'undo' their specific contribution.
        // This is complex without tracking individual incoming delegations.

        // Let's simplify the effect: When A delegates to B, A's skill points become 0 for effective calculation.
        // B's effective skill points become B.skillPoints + A.skillPoints (at time of delegation).
        // Reclaiming: A calls reclaim. A's effective skill becomes A.skillPoints again. B's effective skill reduces by A's skill (at time of delegation).
        // This requires storing the amount delegated *out* by A.
        // Add `uint256 delegatedPowerOut;` to Weaver struct.

        uint256 powerToReclaim = weaver.delegatedPowerOut;

        // Update delegator
        weaver.delegatedTo = address(0);
        weaver.delegatedPowerOut = 0;

        // Update delegatee
        // This requires the delegatee to track *which* delegator contributed *how much*.
        // The simple `delegatee.delegator` and `delegatee.delegatedPower` only works if only ONE person ever delegates to them.
        // Let's change `delegatee.delegator` to `mapping(address => uint256) incomingDelegations;` on the Weaver struct.

        // --- Revised Weaver Struct & Delegation ---
        // struct Weaver { ..., mapping(address => uint256) incomingDelegations; }
        // delegate: `delegator.delegatedTo = _delegatee; delegator.delegatedPowerOut = delegator.skillPoints; delegatee.incomingDelegations[delegatorAddr] += delegator.skillPoints;`
        // reclaim: `amount = delegator.delegatedPowerOut; delete delegatee.incomingDelegations[delegatorAddr]; delegator.delegatedTo = address(0); delegator.delegatedPowerOut = 0;`
        // getEffectiveSkill: `totalIncoming = 0; for(address del : keys of incomingDelegations) totalIncoming += incomingDelegations[del]; return weaver.skillPoints + totalIncoming;` (Iterating mapping keys is not standard Solidity)

        // Okay, final simpler model: 1:1 delegation only. A delegates to B. A cannot delegate again. B cannot receive from C while A delegates to B.
        // Weaver struct: `address delegatedTo; address delegator; uint256 delegatedPowerReceived; uint256 delegatedPowerSent;`
        // delegate: `delegator.delegatedTo = _delegatee; delegator.delegatedPowerSent = delegator.skillPoints; delegatee.delegator = delegatorAddr; delegatee.delegatedPowerReceived = delegator.skillPoints;`
        // reclaim: `amount = weaver.delegatedPowerSent; delegatee.delegator = address(0); delegatee.delegatedPowerReceived = 0; weaver.delegatedTo = address(0); weaver.delegatedPowerSent = 0;`
        // getEffectiveSkill: `if(weaver.delegatedTo != address(0)) return 0; return weaver.skillPoints + weaver.delegatedPowerReceived;`

        // Implementing the 1:1 Simple Model:
        address delegateeAddr = weaver.delegatedTo;
        Weaver storage delegatee = weavers[delegateeAddr];

        // Check if the delegatee still has THIS specific delegation
        if (delegatee.delegator != weaverAddr) {
             // This means the delegatee is no longer receiving from THIS specific delegator.
             // Could happen if delegatee leaves guild, or if a more complex delegation was intended.
             // Revert or simply clear the delegator's side? Let's clear the delegator's side only.
             // This leaves the state potentially inconsistent if delegatee wasn't updated.
             // A robust system NEEDS the mapping approach or enforce strict 1:1.
             // Let's revert to simplify: `delegatee.delegator` MUST be `weaverAddr`.
             revert DelegationActive(delegateeAddr); // Indicates someone else delegated to delegatee, or state is weird. Reclaim impossible in this simple model.
             // A better error: `DelegateeNotReceivingFromYou()`.
        }

        uint256 powerToReclaim = weaver.delegatedPowerSent;

        // Clear state on the delegatee
        delegatee.delegator = address(0);
        delegatee.delegatedPowerReceived = 0;

        // Clear state on the delegator (weaver)
        weaver.delegatedTo = address(0);
        weaver.delegatedPowerSent = 0; // Amount sent is now effectively reclaimed

        // Skill points are not moved, only the effective calculation changes

        emit SkillReclaimed(weaverAddr, powerToReclaim);
    }

    // --- Weaver Management ---
    function grantRank(address _weaver, WeaverRank _rank) public onlyCouncil {
        Weaver storage weaver = weavers[_weaver];
        if (weaver.addr.isZero()) revert WeaverNotFound();
        if (uint8(_rank) > uint8(WeaverRank.Master)) revert InvalidRank(); // Basic check

        weaver.rank = _rank;
        emit RankGranted(_weaver, uint8(_rank));
    }

    function revokeRank(address _weaver) public onlyCouncil {
        Weaver storage weaver = weavers[_weaver];
        if (weaver.addr.isZero()) revert WeaverNotFound();

        weaver.rank = WeaverRank.Novice; // Revert to base rank
        emit RankRevoked(_weaver);
    }

    // --- Guild State & Difficulty ---

    // Internal helper (exposed as view) to calculate current weaving difficulty for a pattern
    function calculateWeavingDifficulty(uint256 _patternId) public view returns (uint256) {
        Pattern storage pattern = patterns[_patternId];
        if (pattern.id == 0) revert PatternNotFound();

        // Example dynamic difficulty formula:
        // Base Pattern Complexity + (Total Artifacts woven / 50) + (Global Loom Complexity Index / 10)
        // This makes weaving harder as the guild grows and more artifacts are produced, and as the Loom Index increases.
        uint26 difficulty = pattern.baseComplexity;
        difficulty += totalArtifacts() / 50; // Scaling factor
        difficulty += loomComplexityIndex / 10; // Scaling factor

        return difficulty;
    }

    function getLoomComplexityIndex() public view returns (uint256) {
        return loomComplexityIndex;
    }

    // Predict theoretical success score based on current state (without randomness)
    function predictWeavingSuccess(uint256 _patternId, address _weaverAddr) public view returns (uint256 theoreticalScore) {
        if (weavers[_weaverAddr].addr.isZero()) revert WeaverNotFound();
        Pattern storage pattern = patterns[_patternId];
        if (pattern.id == 0) revert PatternNotFound();

        uint256 currentDifficulty = calculateWeavingDifficulty(_patternId);
        uint256 weaverSkill = getEffectiveSkill(_weaverAddr);

        // Theoretical success score calculation (matches weaveArtifact successScore logic without randomness)
        // Using the same example formula structure
        theoreticalScore = (weaverSkill * 5); // Base score from skill

        // To compare to target, need targetScore: `uint256 targetScore = currentDifficulty * 10;`
        // The return value could be the theoretical score, or a ratio `theoreticalScore / targetScore`.
        // Returning the raw score for now.
    }

    // Helper to get a weaver's effective skill (base skill + incoming delegation - skill delegated out)
    function getEffectiveSkill(address _weaverAddr) public view returns (uint256) {
        Weaver storage weaver = weavers[_weaverAddr];
        if (weaver.addr.isZero()) return 0; // Not a weaver

        // If they delegated OUT, their effective skill is 0 from their base skill, UNLESS they also received delegation.
        // If `delegatedTo` is set, their base skill (`weaver.skillPoints`) does NOT contribute to their effective skill *for weaving*.
        // Only skill received from others (`weaver.delegatedPowerReceived`) counts for weaving *if* they delegated OUT.
        // If they have NOT delegated OUT (`delegatedTo` is zero), then their effective skill is `weaver.skillPoints + weaver.delegatedPowerReceived`.

        uint256 effective = weaver.skillPoints + weaver.delegatedPowerReceived;

        // If they delegated out, their OWN skillPoints shouldn't count, only received power.
        // This logic is still shaky with the simple 1:1 model.
        // Let's simplify `getEffectiveSkill`:
        // If you delegated *to* someone (`delegatedTo != address(0)`), your effective skill is 0.
        // Otherwise, your effective skill is your base skill + any power delegated *to* you (`delegatedPowerReceived`).

         if (weaver.delegatedTo != address(0)) {
             // If delegating out, effective skill from own base is zero. Only received power counts.
             return weaver.delegatedPowerReceived;
         } else {
             // If not delegating out, effective skill is own base + received power.
             return weaver.skillPoints + weaver.delegatedPowerReceived;
         }
    }


    // --- Chronicles (Timed Events) ---
    function initiateChronicle(string memory _name, uint40 _durationSeconds, uint256 _requiredSkillAvg, uint256 _rewardPool) public onlyCouncil {
        if (activeChronicleId != 0 && block.timestamp <= chronicles[activeChronicleId].endTime) revert ChronicleActive();

        uint256 chronicleId = nextChronicleId++;
        uint40 startTime = uint40(block.timestamp);
        uint40 endTime = startTime + _durationSeconds;

        chronicles[chronicleId] = Chronicle({
            id: chronicleId,
            name: _name,
            startTime: startTime,
            endTime: endTime,
            requiredSkillAvg: _requiredSkillAvg,
            rewardPool: _rewardPool,
            participants: new address[](0),
            hasClaimedReward: new mapping(address => bool)() // Initialize mapping
        });

        activeChronicleId = chronicleId;

        // Transfer reward pool ETH to the contract (simulated threads)
        // require(msg.value >= _rewardPool, "Insufficient ETH for reward pool"); // If rewardPool is ETH
        // guildTreasury += _rewardPool; // If rewardPool is internal threads

        emit ChronicleInitiated(chronicleId, _name, startTime, endTime);
    }

    function participateInChronicle() public onlyWeaver onlyActiveChronicle {
        address weaverAddr = msg.sender;
        Weaver storage weaver = weavers[weaverAddr];
        Chronicle storage chronicle = chronicles[activeChronicleId];

        // Check if weaver meets criteria (using effective skill)
        if (getEffectiveSkill(weaverAddr) < chronicle.requiredSkillAvg) revert WeaverDoesNotMeetChronicleCriteria();

        // Check if already participated
        // Need a mapping on Chronicle: `mapping(address => bool) isParticipant;`
        // Let's add that to the struct.

        // --- Revised Chronicle Struct & Participate ---
        // struct Chronicle { ..., mapping(address => bool) isParticipant; ... }
        // initiateChronicle: Initialize mapping.
        // participateInChronicle: Check `chronicle.isParticipant[weaverAddr]`. Set `chronicle.isParticipant[weaverAddr] = true;`

        if (chronicle.isParticipant[weaverAddr]) revert AlreadyParticipatedInChronicle();

        chronicle.participants.push(weaverAddr);
        chronicle.isParticipant[weaverAddr] = true; // Mark as participant

        emit ChronicleParticipated(activeChronicleId, weaverAddr);
    }

    function claimChronicleReward() public onlyWeaver {
        // Can only claim from an ENDED chronicle
        uint256 claimableChronicleId = 0; // Determine which ended chronicle is claimable - could be complex
        // For simplicity, let's assume there's only *one* ended chronicle available for claiming at a time, or check the MOST RECENTLY ended one.
        // A more robust system would require specifying the chronicleId to claim from.
        // Let's allow claiming from ANY chronicle that has ended and hasn't been claimed.

        bool foundClaimable = false;
        // Iterate through recent chronicles (optimally, don't iterate unbounded)
        // Assuming max chronicleId increases linearly, check back a few IDs from nextChronicleId - 1
        uint256 lastChronicleToCheck = nextChronicleId > 1 ? nextChronicleId - 1 : 0;
        uint256 startCheck = lastChronicleToCheck > 10 ? lastChronicleToCheck - 10 : 1; // Check up to last 10 chronicles

        Chronicle storage chronicleToClaim; // Need storage reference outside loop if found

        for (uint256 i = startCheck; i <= lastChronicleToCheck; i++) {
            Chronicle storage c = chronicles[i];
             // Check if chronicle exists, is ended, and weaver hasn't claimed
            if (c.id != 0 && block.timestamp > c.endTime && !c.hasClaimedReward[msg.sender]) {
                claimableChronicleId = i;
                foundClaimable = true;
                chronicleToClaim = c; // Store reference
                break; // Claim from the first claimable one found
            }
        }

        if (!foundClaimable) revert NoRewardsToClaim();


        // Distribution logic: Simple equal split among participants
        uint256 numParticipants = chronicleToClaim.participants.length;
        if (numParticipants == 0) revert NoRewardsToClaim(); // No participants to split among

        uint256 rewardPerParticipant = chronicleToClaim.rewardPool / numParticipants; // Integer division

        // Ensure treasury has enough (rewards were transferred during initiation)
        if (guildTreasury < rewardPerParticipant) {
             // This indicates an issue with initial reward pool transfer or treasury drain.
             // In a real system, rewards might be external tokens, or handled differently.
             // For this simulation, just revert if treasury is insufficient.
             revert InsufficientThreads(rewardPerParticipant, guildTreasury);
        }


        // Transfer rewards (simulated threads)
        guildTreasury -= rewardPerParticipant;
        payable(msg.sender).transfer(rewardPerParticipant); // Send actual ETH

        chronicleToClaim.hasClaimedReward[msg.sender] = true; // Mark as claimed

        emit ChronicleRewardClaimed(claimableChronicleId, msg.sender, rewardPerParticipant);

         // If this was the *only* reason the chronicle was active (e.g., claiming period), potentially reset activeChronicleId? No, active refers to participation window.
         // Could have a separate state for "claimable".
    }


    // --- View Functions (Getters) ---
    function isWeaver(address _addr) public view returns (bool) {
        return weavers[_addr].addr != address(0); // Check if the struct address field is populated
    }

    function getWeaverInfo(address _addr) public view returns (Weaver memory) {
        if (weavers[_addr].addr.isZero()) revert WeaverNotFound();
        return weavers[_addr];
    }

    function getTotalWeavers() public view returns (uint256) {
        return totalWeavers;
    }

    function getGuildTreasury() public view returns (uint256) {
        return guildTreasury; // Represents ETH balance of contract acting as treasury
    }

    function getTraitTypeInfo(uint256 _traitTypeId) public view returns (TraitType memory) {
        TraitType storage trait = traitTypes[_traitTypeId];
        if (trait.id == 0) revert TraitTypeNotFound();
        return trait;
    }

    function getPatternInfo(uint256 _patternId) public view returns (Pattern memory) {
        Pattern storage pattern = patterns[_patternId];
        if (pattern.id == 0) revert PatternNotFound();
        return pattern;
    }

    function getArtifactInfo(uint256 _artifactId) public view returns (Artifact memory) {
        Artifact storage artifact = artifacts[_artifactId];
        if (artifact.id == 0 || artifact.isBurnt) revert ArtifactNotFound();
        return artifact;
    }

    function getArtifactTraits(uint256 _artifactId) public view returns (uint256[] memory) {
         Artifact storage artifact = artifacts[_artifactId];
         if (artifact.id == 0 || artifact.isBurnt) revert ArtifactNotFound();
         return artifact.traitIds;
    }

    function getTotalArtifacts() public view returns (uint256) {
        // Note: This returns total minted IDs, not total *existing* (non-burnt) artifacts.
        // To get total existing, would need to iterate or maintain a separate counter.
        return nextArtifactId - 1;
    }

    function getWeaverArtifacts(address _weaver) public view returns (uint256[] memory) {
        if (weavers[_weaver].addr.isZero()) revert WeaverNotFound();
        // Filter out burned artifacts? Or return original list? Let's return original list.
        return weavers[_weaver].wovenArtifacts;
    }

    function getDelegatee(address _weaverAddr) public view returns (address) {
        if (weavers[_weaverAddr].addr.isZero()) revert WeaverNotFound();
        return weavers[_weaverAddr].delegatedTo;
    }

    function getDelegator(address _weaverAddr) public view returns (address) {
        // Returns the *single* address that has delegated TO this weaver in the 1:1 model
        if (weavers[_weaverAddr].addr.isZero()) revert WeaverNotFound();
        return weavers[_weaverAddr].delegator;
    }

    function getChronicleInfo(uint256 _chronicleId) public view returns (Chronicle memory) {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.id == 0) revert ChronicleNotFound();
        // Note: Mapping `hasClaimedReward` cannot be returned directly.
        // You would need a helper function like `hasWeaverClaimedChronicleReward(uint256 _chronicleId, address _weaver)`.
         return Chronicle({
             id: chronicle.id,
             name: chronicle.name,
             startTime: chronicle.startTime,
             endTime: chronicle.endTime,
             requiredSkillAvg: chronicle.requiredSkillAvg,
             rewardPool: chronicle.rewardPool,
             participants: chronicle.participants, // Array can be returned
             hasClaimedReward: new mapping(address => bool)() // Dummy mapping for memory struct return
         });
    }

    function getActiveChronicleId() public view returns (uint256) {
        // Check if the chronicle is still within its active participation window
        if (activeChronicleId != 0 && block.timestamp <= chronicles[activeChronicleId].endTime) {
            return activeChronicleId;
        } else {
            return 0; // No active chronicle for participation
        }
    }

    // Helper view for chronicle claim status
    function hasWeaverClaimedChronicleReward(uint256 _chronicleId, address _weaverAddr) public view returns (bool) {
         Chronicle storage chronicle = chronicles[_chronicleId];
         if (chronicle.id == 0) revert ChronicleNotFound();
         return chronicle.hasClaimedReward[_weaverAddr];
    }


}
```