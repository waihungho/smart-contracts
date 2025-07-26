Okay, this is an exciting challenge! Let's build something unique, combining advanced concepts like dynamic NFTs, time-based mechanics, simulated on-chain "AI" (via complex rule sets and probabilistic outcomes), resource management, and a governance layer.

I'll call this contract **ChronoForge**.

**Concept:**
ChronoForge is a decentralized ecosystem where users can mint and evolve unique digital artifacts called "ChronoArtifacts" (NFTs). These artifacts possess dynamic properties that change over time, based on user interaction (fueling, applying knowledge), and global "knowledge discoveries" made by the community. The system also features a utility token, "TimeCrystal," used for fueling artifacts, participating in research, and governance.

**Core Advanced Concepts:**

1.  **Dynamic NFTs:** Artifacts are not static. Their internal state (`level`, `decayResistance`, `knowledgeApplied`, `entropy`) changes, and their metadata URI can be updated to reflect these changes (pointing to an off-chain API that renders the dynamic state).
2.  **Time-Based Mechanics:** Artifacts actively decay if not fueled, and evolve over time or through specific actions. Time is a fundamental resource.
3.  **Simulated On-Chain "AI" / Knowledge Base:** A "Knowledge Base" (global parameters) evolves through community "research proposals." These proposals are evaluated based on complex, probabilistic on-chain rules (simulating an AI's "discovery" process) and resource investment. Successful discoveries update global parameters, influencing all artifacts.
4.  **Resource Management (TimeCrystal):** TimeCrystal (ERC20) acts as a fuel, a research catalyst, and a governance token.
5.  **Entropic Decay & Renewal:** Artifacts constantly battle entropy. If not maintained, they decay, lose value, and can even be "reclaimed" for base resources.
6.  **Modular Governance:** Key system parameters (decay rates, fueling costs, research difficulty) are adjustable via TimeCrystal holder governance.
7.  **Batch Operations:** Gas-efficient functions for common actions like fueling multiple artifacts.

---

## ChronoForge Smart Contract Outline & Function Summary

**Contract Name:** `ChronoForge`

**Core Idea:** A decentralized system for creating, evolving, and managing dynamic, time-sensitive digital artifacts (ChronoArtifacts) and a collective knowledge base, powered by a utility token (TimeCrystal) and community governance.

---

### **I. Core Components & Data Structures**

*   `ChronoArtifact`: NFT struct holding dynamic properties (level, XP, decay, last fueled, knowledge applied).
*   `KnowledgeDiscovery`: Struct for community-proposed "research" (updates to global parameters).
*   `SystemProposal`: Struct for governance proposals to change contract parameters.
*   `GlobalKnowledge`: Mapping for key system parameters that evolve.

---

### **II. Function Categories & Summary**

#### **A. ChronoArtifact (Dynamic NFT) Management (ERC721 Compliant)**

1.  **`mintChronoArtifact(address _to)`:**
    *   Mints a new ChronoArtifact NFT to the specified address.
    *   Initializes its state: level 0, full decay resistance, sets creation time.
    *   *Concept:* Entry point for users to acquire a dynamic asset.
2.  **`getChronoArtifactDetails(uint256 _tokenId) view`:**
    *   Retrieves the full, current state of a ChronoArtifact (level, XP, decay, last fueled time, etc.).
    *   *Concept:* Allows users and off-chain UIs to inspect the dynamic properties of an NFT.
3.  **`getCurrentArtifactEntropy(uint256 _tokenId) view`:**
    *   Calculates the current "decay" or "entropy" level of an artifact based on `block.timestamp` and `lastFueledTime`.
    *   *Concept:* Exposes the critical time-sensitive decay mechanism.
4.  **`updateArtifactMetadataURI(uint256 _tokenId, string memory _newURI)`:**
    *   Allows the artifact's owner to update its metadata URI.
    *   *Note:* In a real dApp, this would point to an API that dynamically renders the artifact's current state.
    *   *Concept:* Enables the dynamic visual representation of the NFT based on its on-chain state.
5.  **`safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data)` / `safeTransferFrom(address _from, address _to, uint256 _tokenId)`:**
    *   Standard ERC721 transfer function.
    *   *Concept:* Basic ownership transfer of the dynamic NFT.

#### **B. TimeCrystal (ERC20) Management**

6.  **`distributeTimeCrystals(address _to, uint256 _amount)`:**
    *   Admin/owner function to distribute TimeCrystal tokens.
    *   *Concept:* Initial token distribution or reward mechanism.
7.  **`transfer(address _to, uint256 _amount)`:**
    *   Standard ERC20 transfer function.
    *   *Concept:* Allows users to send TimeCrystals to each other.
8.  **`approve(address _spender, uint256 _amount)`:**
    *   Standard ERC20 approve function.
    *   *Concept:* Allows other contracts or addresses to spend TimeCrystals on behalf of the owner.
9.  **`stakeTimeCrystals(uint256 _amount)`:**
    *   Users can stake TimeCrystals to gain voting power and potentially earn rewards (not explicitly coded reward distribution but implied).
    *   *Concept:* DeFi integration, governance participation.
10. **`unstakeTimeCrystals(uint256 _amount)`:**
    *   Allows users to withdraw their staked TimeCrystals after a cool-down period.
    *   *Concept:* Manages liquidity and participation in staking/governance.

#### **C. ChronoArtifact Evolution & Maintenance**

11. **`fuelChronoArtifact(uint256 _tokenId, uint256 _fuelAmount)`:**
    *   Consumes TimeCrystals to reset an artifact's `lastFueledTime`, preventing or reversing decay.
    *   Can also accelerate "evolution" or XP gain.
    *   *Concept:* Core maintenance mechanic, resource sink, and enabler for progression.
12. **`batchFuelChronoArtifacts(uint256[] calldata _tokenIds, uint256 _fuelPerArtifact)`:**
    *   Allows fueling multiple artifacts in a single transaction, saving gas.
    *   *Concept:* Gas optimization for users with many artifacts.
13. **`evolveChronoArtifact(uint256 _tokenId)`:**
    *   Triggers an evolution attempt for an artifact. Success depends on `fuel` status, `knowledgeApplied`, and internal `XP`. Increases `level` and potentially unlocks new properties.
    *   *Concept:* The core progression mechanic for the dynamic NFT.
14. **`applyGlobalKnowledge(uint256 _tokenId)`:**
    *   Allows an artifact owner to apply the current global knowledge parameters to their artifact, potentially boosting its stats or resetting its entropy based on new discoveries.
    *   *Concept:* Connects individual artifacts to the collective "AI" knowledge base.
15. **`redeemDecayedArtifact(uint256 _tokenId)`:**
    *   If an artifact's entropy reaches a critical threshold, it can be "redeemed" for a fraction of its initial TimeCrystal cost or base materials. The NFT is burned.
    *   *Concept:* Resource sink, adds risk, and incentivizes active management.

#### **D. Knowledge Base & Research (Simulated On-Chain AI)**

16. **`proposeKnowledgeDiscovery(string memory _parameterName, uint256 _newValue, string memory _description)`:**
    *   Any TimeCrystal staker can propose a "discovery" to update a specific global knowledge parameter. Requires a TimeCrystal deposit.
    *   *Concept:* Initiates the "research" process, allows community to suggest improvements/changes.
17. **`evaluateKnowledgeDiscovery(uint256 _discoveryId)`:**
    *   Triggers the simulated "AI" evaluation process. This function consumes TimeCrystals (as computational cost) and its success probability is based on current system parameters (difficulty) and the staked TimeCrystals for the discovery.
    *   *Concept:* The "AI" engine. Simulates complex computation and probabilistic outcomes on-chain.
18. **`finalizeKnowledgeDiscovery(uint256 _discoveryId)`:**
    *   If a discovery passes its evaluation, this function updates the global `_knowledgeBase` with the new parameter value. Proposer gets deposit back + potential reward.
    *   *Concept:* Integrates successful research into the ecosystem, changing rules for all artifacts.
19. **`getGlobalKnowledgeParameter(string memory _parameterName) view`:**
    *   Retrieves the current value of a global knowledge parameter.
    *   *Concept:* Allows users and contracts to query the current state of the "AI" knowledge.

#### **E. Governance & System Configuration**

20. **`proposeSystemParameterChange(string memory _parameterName, uint256 _newValue, string memory _description)`:**
    *   TimeCrystal stakers can propose changes to core contract parameters (e.g., decay rate, fueling cost, research difficulty). Requires TimeCrystal deposit.
    *   *Concept:* DAO-like governance for the entire system.
21. **`voteOnProposal(uint256 _proposalId, bool _for)`:**
    *   Staked TimeCrystal holders can vote on active system proposals. Voting power proportional to staked amount.
    *   *Concept:* Direct participation in the system's evolution.
22. **`executeProposal(uint256 _proposalId)`:**
    *   If a proposal meets the voting quorum and threshold, this function executes the proposed parameter change.
    *   *Concept:* Decentralized execution of community decisions.
23. **`setBaseParameters(uint256 _baseFuelCost, uint256 _baseDecayRate, uint256 _baseResearchDifficulty)`:**
    *   Admin function (or via governance initially) to set foundational parameters.
    *   *Concept:* Initial setup and emergency override.
24. **`withdrawAdminFunds(address _recipient, uint256 _amount)`:**
    *   Owner can withdraw accumulated fees/funds from the contract.
    *   *Concept:* Basic fund management.

---

### **III. Code Structure & Notes**

*   **Solidity Version:** `^0.8.0` for safety and gas efficiency.
*   **Libraries:** Mimics some ERC721/ERC20 functionality but implements custom logic for the core concepts. In a production scenario, OpenZeppelin's `ERC721` and `ERC20` would be inherited.
*   **Gas Optimizations:** Batch operations, careful use of storage.
*   **Security:** `Ownable` for admin functions, reentrancy guards for critical state changes, extensive `require` statements.
*   **"Randomness":** Simulated using `keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))` for "AI" evaluations. Acknowledged as not truly random but sufficient for on-chain deterministic outcomes in a demo.
*   **Off-chain Integration:** Dynamic NFT metadata would require an off-chain server that renders an image/JSON based on the artifact's on-chain state.

---
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: For a real production system, you would inherit from OpenZeppelin's ERC721 and ERC20
// libraries directly. For the purpose of showcasing custom advanced functionality and avoiding direct
// duplication of open source, I've implemented minimal necessary interfaces and functions here.

// IChronoERC721 minimal interface for dynamic NFT
interface IChronoERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// ITimeCrystal minimal interface for ERC20 utility token
interface ITimeCrystal {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract ChronoForge is Ownable, ReentrancyGuard, IChronoERC721, ITimeCrystal {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ChronoArtifacts (NFTs)
    struct ChronoArtifact {
        uint256 id;
        uint256 creationTime; // block.timestamp when minted
        uint256 lastFueledTime; // block.timestamp when last fueled
        uint256 level;
        uint256 xp; // Experience points
        uint256 decayResistance; // A multiplier for decay resistance, can increase with level/knowledge
        uint256 knowledgeAppliedMask; // Bitmask of applied global knowledge types
        uint256 entropy; // Current decay level, increases over time if not fueled
        string metadataURI; // URI to dynamic metadata API
    }
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => ChronoArtifact) private _chronoArtifacts;
    mapping(uint256 => address) private _owners; // tokenId => owner
    mapping(address => uint256) private _balances; // owner => count of NFTs
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // TimeCrystal (ERC20)
    string public constant name = "TimeCrystal";
    string public constant symbol = "TTC";
    uint256 public constant decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balancesTimeCrystal; // address => TimeCrystal balance
    mapping(address => mapping(address => uint256)) private _allowancesTimeCrystal; // owner => spender => amount

    // Staking for Governance/Research
    mapping(address => uint256) public stakedTimeCrystals;
    uint256 public constant UNSTAKE_COOLDOWN_PERIOD = 7 days; // Cooldown for unstaking
    mapping(address => uint256) public lastUnstakeRequestTime;

    // Global Knowledge Base (Simulated AI / Protocol Parameters)
    mapping(string => uint256) public globalKnowledgeParameters; // e.g., "baseDecayRate", "evolutionXPThreshold", "researchDifficulty"

    // Knowledge Discovery & System Proposals (Governance)
    struct KnowledgeDiscovery {
        uint256 id;
        address proposer;
        string parameterName;
        uint256 newValue;
        string description;
        uint256 submissionTime;
        uint256 depositAmount;
        uint256 evaluationAttempts; // How many times it has been "evaluated"
        uint256 lastEvaluationTime;
        uint256 successChanceMultiplier; // Multiplier from previous evaluations/fueling
        bool finalized;
        bool successful;
    }
    Counters.Counter private _discoveryIdCounter;
    mapping(uint256 => KnowledgeDiscovery) public knowledgeDiscoveries;

    struct SystemProposal {
        uint256 id;
        address proposer;
        string parameterName;
        uint256 newValue;
        string description;
        uint256 submissionTime;
        uint256 depositAmount;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => true if voted
        bool finalized;
        bool passed;
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => SystemProposal) public systemProposals;
    uint256 public constant VOTING_PERIOD = 5 days;
    uint256 public constant QUORUM_PERCENTAGE = 10; // 10% of total staked supply needed for quorum

    // Configuration Parameters (adjustable via governance)
    uint256 public BASE_FUEL_COST = 100 * (10 ** decimals); // Cost in TimeCrystals
    uint256 public BASE_DECAY_RATE_PER_DAY = 1; // Amount entropy increases per day
    uint256 public BASE_EVOLUTION_XP_THRESHOLD = 1000; // XP needed for level 1
    uint256 public BASE_RESEARCH_DIFFICULTY = 1000; // Lower is easier for research success
    uint256 public MAX_ENTROPY = 1000; // Max entropy before artifact is considered decayed
    uint256 public REDEEM_VALUE_PERCENTAGE = 20; // % of initial cost to redeem decayed artifact

    // --- Events ---
    event ChronoArtifactMinted(uint256 indexed tokenId, address indexed owner, uint256 creationTime);
    event ChronoArtifactFueled(uint256 indexed tokenId, address indexed fueler, uint256 amount);
    event ChronoArtifactEvolved(uint256 indexed tokenId, uint256 newLevel);
    event ChronoArtifactDecayed(uint256 indexed tokenId, uint256 currentEntropy);
    event ChronoArtifactRedeemed(uint256 indexed tokenId, address indexed redeemer, uint256 reimbursedAmount);
    event GlobalKnowledgeApplied(uint256 indexed tokenId, uint256 knowledgeMask);

    event TimeCrystalStaked(address indexed staker, uint256 amount);
    event TimeCrystalUnstaked(address indexed staker, uint256 amount);

    event KnowledgeDiscoveryProposed(uint256 indexed discoveryId, address indexed proposer, string parameterName, uint256 newValue);
    event KnowledgeDiscoveryEvaluated(uint256 indexed discoveryId, bool success);
    event KnowledgeDiscoveryFinalized(uint256 indexed discoveryId, bool success, string parameterName, uint256 newValue);

    event SystemProposalProposed(uint256 indexed proposalId, address indexed proposer, string parameterName, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    // --- Constructor ---
    constructor(uint256 initialTimeCrystalSupply) Ownable(msg.sender) {
        _totalSupply = initialTimeCrystalSupply * (10 ** decimals);
        _balancesTimeCrystal[msg.sender] = _totalSupply; // Mint initial supply to deployer

        // Initialize some default global knowledge parameters
        globalKnowledgeParameters["baseDecayRate"] = BASE_DECAY_RATE_PER_DAY;
        globalKnowledgeParameters["evolutionXPThreshold"] = BASE_EVOLUTION_XP_THRESHOLD;
        globalKnowledgeParameters["researchDifficulty"] = BASE_RESEARCH_DIFFICULTY;
    }

    // --- ITimeCrystal (ERC20) Implementations ---

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balancesTimeCrystal[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balancesTimeCrystal[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balancesTimeCrystal[msg.sender] -= amount;
        _balancesTimeCrystal[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowancesTimeCrystal[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowancesTimeCrystal[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balancesTimeCrystal[from] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowancesTimeCrystal[from][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");

        _balancesTimeCrystal[from] -= amount;
        _balancesTimeCrystal[to] += amount;
        _allowancesTimeCrystal[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // --- IChronoERC721 (NFT) Implementations ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return _chronoArtifacts[tokenId].metadataURI;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        delete _tokenApprovals[tokenId]; // Clear approvals when transferred
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        // Optional: _checkOnERC721Received(from, to, tokenId, data) for ERC721Receiver compatibility
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    // --- A. ChronoArtifact (Dynamic NFT) Management ---

    /**
     * @notice Mints a new ChronoArtifact NFT to the specified address.
     * @param _to The address to mint the artifact to.
     */
    function mintChronoArtifact(address _to) public nonReentrant {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        require(_to != address(0), "Mint to zero address not allowed");
        require(_balancesTimeCrystal[msg.sender] >= BASE_FUEL_COST, "Insufficient TimeCrystals to mint artifact");
        _balancesTimeCrystal[msg.sender] -= BASE_FUEL_COST; // Cost to mint

        _chronoArtifacts[newItemId] = ChronoArtifact({
            id: newItemId,
            creationTime: block.timestamp,
            lastFueledTime: block.timestamp,
            level: 0,
            xp: 0,
            decayResistance: 100, // Initial decay resistance
            knowledgeAppliedMask: 0,
            entropy: 0,
            metadataURI: "ipfs://QmbF6tT4d3gV5r.../initial_artifact.json" // Placeholder, should be a base URI
        });

        _balances[_to]++;
        _owners[newItemId] = _to;
        emit ChronoArtifactMinted(newItemId, _to, block.timestamp);
    }

    /**
     * @notice Retrieves the full, current state of a ChronoArtifact.
     * @param _tokenId The ID of the ChronoArtifact.
     * @return ChronoArtifact struct containing its current properties.
     */
    function getChronoArtifactDetails(uint256 _tokenId) public view returns (
        uint256 id,
        uint256 creationTime,
        uint256 lastFueledTime,
        uint256 level,
        uint256 xp,
        uint256 decayResistance,
        uint256 knowledgeAppliedMask,
        uint256 entropy,
        string memory metadataURI
    ) {
        require(_exists(_tokenId), "ChronoForge: Artifact does not exist");
        ChronoArtifact storage artifact = _chronoArtifacts[_tokenId];
        return (
            artifact.id,
            artifact.creationTime,
            artifact.lastFueledTime,
            artifact.level,
            artifact.xp,
            artifact.decayResistance,
            artifact.knowledgeAppliedMask,
            getCurrentArtifactEntropy(_tokenId), // Always return calculated current entropy
            artifact.metadataURI
        );
    }

    /**
     * @notice Calculates the current "decay" or "entropy" level of an artifact.
     * @param _tokenId The ID of the ChronoArtifact.
     * @return The current entropy level.
     */
    function getCurrentArtifactEntropy(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ChronoForge: Artifact does not exist");
        ChronoArtifact storage artifact = _chronoArtifacts[_tokenId];
        uint256 timeSinceLastFuel = block.timestamp - artifact.lastFueledTime;
        uint256 daysSinceLastFuel = timeSinceLastFuel / 1 days;

        uint256 effectiveDecayRate = globalKnowledgeParameters["baseDecayRate"] * 100 / artifact.decayResistance; // Decay resistance reduces effective rate
        if (effectiveDecayRate == 0) effectiveDecayRate = 1; // Prevent division by zero

        uint256 calculatedEntropy = artifact.entropy + (daysSinceLastFuel * effectiveDecayRate);
        return calculatedEntropy > MAX_ENTROPY ? MAX_ENTROPY : calculatedEntropy;
    }

    /**
     * @notice Allows the artifact's owner to update its metadata URI.
     * @dev In a real dApp, this would point to an API that dynamically renders the artifact's current state.
     * @param _tokenId The ID of the ChronoArtifact.
     * @param _newURI The new URI pointing to the dynamic metadata.
     */
    function updateArtifactMetadataURI(uint256 _tokenId, string memory _newURI) public {
        require(ownerOf(_tokenId) == msg.sender, "ChronoForge: Only artifact owner can update URI");
        _chronoArtifacts[_tokenId].metadataURI = _newURI;
    }

    // --- C. ChronoArtifact Evolution & Maintenance ---

    /**
     * @notice Consumes TimeCrystals to reset an artifact's lastFueledTime, preventing or reversing decay.
     * Also contributes to XP gain.
     * @param _tokenId The ID of the ChronoArtifact.
     * @param _fuelAmount The amount of TimeCrystals to fuel with.
     */
    function fuelChronoArtifact(uint256 _tokenId, uint256 _fuelAmount) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "ChronoForge: Only artifact owner can fuel");
        require(_fuelAmount > 0, "ChronoForge: Fuel amount must be greater than zero");
        require(_balancesTimeCrystal[msg.sender] >= _fuelAmount, "ChronoForge: Insufficient TimeCrystals for fueling");

        ChronoArtifact storage artifact = _chronoArtifacts[_tokenId];
        _balancesTimeCrystal[msg.sender] -= _fuelAmount; // Deduct fuel cost

        // Reduce entropy based on fuel amount
        uint256 entropyToReduce = _fuelAmount / (BASE_FUEL_COST / 10); // Example: 10% of fuel value reduces entropy
        if (artifact.entropy > entropyToReduce) {
            artifact.entropy -= entropyToReduce;
        } else {
            artifact.entropy = 0;
        }

        artifact.lastFueledTime = block.timestamp;
        artifact.xp += _fuelAmount / (BASE_FUEL_COST / 100); // Example: 100 XP per base fuel cost

        emit ChronoArtifactFueled(_tokenId, msg.sender, _fuelAmount);
    }

    /**
     * @notice Allows fueling multiple artifacts in a single transaction.
     * @param _tokenIds Array of ChronoArtifact IDs to fuel.
     * @param _fuelPerArtifact Amount of TimeCrystals to fuel each artifact with.
     */
    function batchFuelChronoArtifacts(uint256[] calldata _tokenIds, uint256 _fuelPerArtifact) public nonReentrant {
        require(_fuelPerArtifact > 0, "ChronoForge: Fuel amount must be greater than zero");
        require(_tokenIds.length > 0, "ChronoForge: No token IDs provided");
        require(_tokenIds.length * _fuelPerArtifact <= _balancesTimeCrystal[msg.sender], "ChronoForge: Insufficient TimeCrystals for batch fueling");

        uint256 totalFuelCost = _tokenIds.length * _fuelPerArtifact;
        _balancesTimeCrystal[msg.sender] -= totalFuelCost;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "ChronoForge: Not owner of all artifacts in batch");

            ChronoArtifact storage artifact = _chronoArtifacts[tokenId];
            uint256 entropyToReduce = _fuelPerArtifact / (BASE_FUEL_COST / 10);
            if (artifact.entropy > entropyToReduce) {
                artifact.entropy -= entropyToReduce;
            } else {
                artifact.entropy = 0;
            }
            artifact.lastFueledTime = block.timestamp;
            artifact.xp += _fuelPerArtifact / (BASE_FUEL_COST / 100);
            emit ChronoArtifactFueled(tokenId, msg.sender, _fuelPerArtifact);
        }
    }

    /**
     * @notice Triggers an evolution attempt for an artifact.
     * Success depends on fuel status, knowledge applied, and internal XP.
     * @param _tokenId The ID of the ChronoArtifact.
     */
    function evolveChronoArtifact(uint256 _tokenId) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "ChronoForge: Only artifact owner can evolve");

        ChronoArtifact storage artifact = _chronoArtifacts[_tokenId];
        uint256 currentEntropy = getCurrentArtifactEntropy(_tokenId);
        require(currentEntropy < MAX_ENTROPY / 2, "ChronoForge: Artifact too decayed to evolve"); // Must be healthy enough
        require(artifact.xp >= globalKnowledgeParameters["evolutionXPThreshold"], "ChronoForge: Not enough XP to evolve");

        artifact.level++;
        artifact.xp -= globalKnowledgeParameters["evolutionXPThreshold"]; // Consume XP
        artifact.decayResistance += artifact.level * 5; // Example: Leveling increases resistance

        // Increase XP threshold for next level (simple scaling)
        globalKnowledgeParameters["evolutionXPThreshold"] = globalKnowledgeParameters["evolutionXPThreshold"] * 110 / 100;

        emit ChronoArtifactEvolved(_tokenId, artifact.level);
    }

    /**
     * @notice Allows an artifact owner to apply the current global knowledge parameters to their artifact.
     * This might boost its stats or reduce entropy based on new discoveries.
     * @param _tokenId The ID of the ChronoArtifact.
     */
    function applyGlobalKnowledge(uint256 _tokenId) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "ChronoForge: Only artifact owner can apply knowledge");

        ChronoArtifact storage artifact = _chronoArtifacts[_tokenId];

        // Example: Applying knowledge might reset entropy or boost stats
        // This logic would be more complex in a full system, based on specific knowledge types
        uint256 preEntropy = artifact.entropy;
        artifact.entropy = 0; // Freshly applied knowledge fully restores health
        artifact.decayResistance = globalKnowledgeParameters["baseDecayRate"] * 2; // Knowledge makes it more resilient

        artifact.knowledgeAppliedMask = block.timestamp; // Simply mark last application time for this demo
        emit GlobalKnowledgeApplied(_tokenId, artifact.knowledgeAppliedMask);
    }

    /**
     * @notice If an artifact's entropy reaches a critical threshold, it can be "redeemed" for a fraction of its
     * initial TimeCrystal cost or base materials. The NFT is burned.
     * @param _tokenId The ID of the ChronoArtifact.
     */
    function redeemDecayedArtifact(uint256 _tokenId) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "ChronoForge: Only artifact owner can redeem");
        ChronoArtifact storage artifact = _chronoArtifacts[_tokenId];
        require(getCurrentArtifactEntropy(_tokenId) >= MAX_ENTROPY, "ChronoForge: Artifact not sufficiently decayed for redemption");

        uint256 reimburseAmount = BASE_FUEL_COST * REDEEM_VALUE_PERCENTAGE / 100;
        _balancesTimeCrystal[msg.sender] += reimburseAmount;

        // "Burn" the NFT
        _balances[msg.sender]--;
        delete _owners[_tokenId];
        delete _chronoArtifacts[_tokenId];
        delete _tokenApprovals[_tokenId]; // Clear any approvals

        emit ChronoArtifactRedeemed(_tokenId, msg.sender, reimburseAmount);
    }


    // --- D. Knowledge Base & Research (Simulated On-Chain AI) ---

    /**
     * @notice Any TimeCrystal staker can propose a "discovery" to update a specific global knowledge parameter.
     * @param _parameterName The name of the global parameter to propose changing (e.g., "baseDecayRate").
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposed discovery.
     */
    function proposeKnowledgeDiscovery(
        string memory _parameterName,
        uint256 _newValue,
        string memory _description
    ) public nonReentrant {
        require(stakedTimeCrystals[msg.sender] > 0, "ChronoForge: Only stakers can propose discoveries");
        require(bytes(_parameterName).length > 0, "ChronoForge: Parameter name cannot be empty");
        uint256 deposit = 1000 * (10 ** decimals); // Example deposit for a proposal

        require(_balancesTimeCrystal[msg.sender] >= deposit, "ChronoForge: Insufficient TimeCrystals for deposit");
        _balancesTimeCrystal[msg.sender] -= deposit; // Take deposit

        _discoveryIdCounter.increment();
        uint256 newDiscoveryId = _discoveryIdCounter.current();

        knowledgeDiscoveries[newDiscoveryId] = KnowledgeDiscovery({
            id: newDiscoveryId,
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            description: _description,
            submissionTime: block.timestamp,
            depositAmount: deposit,
            evaluationAttempts: 0,
            lastEvaluationTime: 0,
            successChanceMultiplier: 100, // Initial 100% base chance for simplicity, modified by fuel/logic
            finalized: false,
            successful: false
        });

        emit KnowledgeDiscoveryProposed(newDiscoveryId, msg.sender, _parameterName, _newValue);
    }

    /**
     * @notice Triggers the simulated "AI" evaluation process for a knowledge discovery.
     * This function consumes TimeCrystals (as computational cost) and its success probability
     * is based on current system parameters (difficulty) and the discovery's investment.
     * @param _discoveryId The ID of the knowledge discovery to evaluate.
     */
    function evaluateKnowledgeDiscovery(uint256 _discoveryId) public nonReentrant {
        KnowledgeDiscovery storage discovery = knowledgeDiscoveries[_discoveryId];
        require(discovery.proposer != address(0), "ChronoForge: Discovery does not exist");
        require(!discovery.finalized, "ChronoForge: Discovery already finalized");
        require(block.timestamp >= discovery.lastEvaluationTime + 1 days || discovery.evaluationAttempts == 0, "ChronoForge: Too soon to re-evaluate"); // Cooldown for evaluations

        uint256 evaluationCost = 50 * (10 ** decimals); // Cost for each evaluation attempt
        require(_balancesTimeCrystal[msg.sender] >= evaluationCost, "ChronoForge: Insufficient TimeCrystals for evaluation");
        _balancesTimeCrystal[msg.sender] -= evaluationCost; // Deduct cost

        discovery.evaluationAttempts++;
        discovery.lastEvaluationTime = block.timestamp;

        // Simulated AI logic: Success probability
        // Factors: Time since submission, number of attempts, invested fuel (implicit from evaluation cost)
        // This uses a very basic on-chain pseudo-randomness. A robust system might use Chainlink VRF.
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, _discoveryId, discovery.evaluationAttempts, msg.sender))) % 1000;

        uint256 currentDifficulty = globalKnowledgeParameters["researchDifficulty"];
        if (currentDifficulty == 0) currentDifficulty = 1;

        // Success chance calculation (more complex logic here for realism):
        // Higher attempts slightly increase chance, lower difficulty means higher chance
        uint256 chance = (discovery.successChanceMultiplier + (discovery.evaluationAttempts * 10)) * 1000 / currentDifficulty; // Scale for 1000 base
        if (chance > 999) chance = 999; // Cap at 99.9% success

        bool success = (pseudoRandom < chance);

        if (success) {
            discovery.successful = true;
        } else {
            // For failed attempts, we could decrease successChanceMultiplier or increase difficulty temporarily
            discovery.successChanceMultiplier = discovery.successChanceMultiplier * 90 / 100; // Makes future attempts harder
        }

        emit KnowledgeDiscoveryEvaluated(_discoveryId, success);
    }

    /**
     * @notice If a discovery passes its evaluation, this function updates the global _knowledgeBase.
     * Proposer gets deposit back + potential reward.
     * @param _discoveryId The ID of the knowledge discovery to finalize.
     */
    function finalizeKnowledgeDiscovery(uint256 _discoveryId) public nonReentrant {
        KnowledgeDiscovery storage discovery = knowledgeDiscoveries[_discoveryId];
        require(discovery.proposer != address(0), "ChronoForge: Discovery does not exist");
        require(!discovery.finalized, "ChronoForge: Discovery already finalized");
        require(discovery.successful, "ChronoForge: Discovery has not been successfully evaluated");

        globalKnowledgeParameters[discovery.parameterName] = discovery.newValue;
        discovery.finalized = true;

        // Return deposit and provide a reward
        _balancesTimeCrystal[discovery.proposer] += discovery.depositAmount;
        _balancesTimeCrystal[discovery.proposer] += 500 * (10 ** decimals); // Example reward

        emit KnowledgeDiscoveryFinalized(_discoveryId, true, discovery.parameterName, discovery.newValue);
    }

    /**
     * @notice Retrieves the current value of a global knowledge parameter.
     * @param _parameterName The name of the parameter.
     * @return The current value of the parameter.
     */
    function getGlobalKnowledgeParameter(string memory _parameterName) public view returns (uint256) {
        return globalKnowledgeParameters[_parameterName];
    }


    // --- E. Governance & System Configuration ---

    /**
     * @notice Allows TimeCrystal holders to stake their tokens to gain voting power.
     * @param _amount The amount of TimeCrystals to stake.
     */
    function stakeTimeCrystals(uint256 _amount) public nonReentrant {
        require(_amount > 0, "ChronoForge: Stake amount must be greater than zero");
        require(_balancesTimeCrystal[msg.sender] >= _amount, "ChronoForge: Insufficient TimeCrystals to stake");

        _balancesTimeCrystal[msg.sender] -= _amount;
        stakedTimeCrystals[msg.sender] += _amount;
        emit TimeCrystalStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows TimeCrystal holders to unstake their tokens after a cooldown period.
     * @param _amount The amount of TimeCrystals to unstake.
     */
    function unstakeTimeCrystals(uint256 _amount) public nonReentrant {
        require(_amount > 0, "ChronoForge: Unstake amount must be greater than zero");
        require(stakedTimeCrystals[msg.sender] >= _amount, "ChronoForge: Insufficient staked TimeCrystals");
        require(block.timestamp >= lastUnstakeRequestTime[msg.sender] + UNSTAKE_COOLDOWN_PERIOD, "ChronoForge: Unstake cooldown period not over");

        stakedTimeCrystals[msg.sender] -= _amount;
        _balancesTimeCrystal[msg.sender] += _amount;
        lastUnstakeRequestTime[msg.sender] = block.timestamp; // Reset cooldown
        emit TimeCrystalUnstaked(msg.sender, _amount);
    }

    /**
     * @notice TimeCrystal stakers can propose changes to core contract parameters.
     * @param _parameterName The name of the parameter to change (e.g., "BASE_FUEL_COST").
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposal.
     */
    function proposeSystemParameterChange(
        string memory _parameterName,
        uint256 _newValue,
        string memory _description
    ) public nonReentrant {
        require(stakedTimeCrystals[msg.sender] > 0, "ChronoForge: Only stakers can propose system changes");
        uint256 deposit = 5000 * (10 ** decimals); // Example deposit for a system proposal
        require(_balancesTimeCrystal[msg.sender] >= deposit, "ChronoForge: Insufficient TimeCrystals for deposit");
        _balancesTimeCrystal[msg.sender] -= deposit; // Take deposit

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        systemProposals[newProposalId] = SystemProposal({
            id: newProposalId,
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            description: _description,
            submissionTime: block.timestamp,
            depositAmount: deposit,
            votesFor: 0,
            votesAgainst: 0,
            finalized: false,
            passed: false
        });

        emit SystemProposalProposed(newProposalId, msg.sender, _parameterName, _newValue);
    }

    /**
     * @notice Staked TimeCrystal holders can vote on active system proposals.
     * Voting power proportional to staked amount.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) public nonReentrant {
        SystemProposal storage proposal = systemProposals[_proposalId];
        require(proposal.proposer != address(0), "ChronoForge: Proposal does not exist");
        require(!proposal.finalized, "ChronoForge: Proposal already finalized");
        require(block.timestamp < proposal.submissionTime + VOTING_PERIOD, "ChronoForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "ChronoForge: Already voted on this proposal");
        require(stakedTimeCrystals[msg.sender] > 0, "ChronoForge: Must have staked TimeCrystals to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.votesFor += stakedTimeCrystals[msg.sender];
        } else {
            proposal.votesAgainst += stakedTimeCrystals[msg.sender];
        }
        emit VoteCast(_proposalId, msg.sender, _for);
    }

    /**
     * @notice If a proposal meets the voting quorum and threshold, this function executes the proposed parameter change.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant {
        SystemProposal storage proposal = systemProposals[_proposalId];
        require(proposal.proposer != address(0), "ChronoForge: Proposal does not exist");
        require(!proposal.finalized, "ChronoForge: Proposal already finalized");
        require(block.timestamp >= proposal.submissionTime + VOTING_PERIOD, "ChronoForge: Voting period has not ended yet");

        uint256 totalStaked = 0;
        // In a real scenario, you'd iterate through all stakers or track total staked supply
        // For this demo, we'll use _totalSupply as a proxy for max possible staked supply
        // assuming most of it is staked for quorum calculation.
        // A more robust solution would track `totalActiveStakedSupply`.
        totalStaked = _totalSupply; // Simplified for demo, assume _totalSupply is total staked if all minted are staked

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes >= (totalStaked * QUORUM_PERCENTAGE / 100), "ChronoForge: Quorum not met");

        bool passed = (proposal.votesFor > proposal.votesAgainst);

        proposal.finalized = true;
        proposal.passed = passed;

        if (passed) {
            // Apply the change to the system parameter
            if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("BASE_FUEL_COST"))) {
                BASE_FUEL_COST = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("BASE_DECAY_RATE_PER_DAY"))) {
                BASE_DECAY_RATE_PER_DAY = proposal.newValue;
                globalKnowledgeParameters["baseDecayRate"] = proposal.newValue; // Also update global knowledge
            } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("BASE_EVOLUTION_XP_THRESHOLD"))) {
                 BASE_EVOLUTION_XP_THRESHOLD = proposal.newValue;
                 globalKnowledgeParameters["evolutionXPThreshold"] = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("BASE_RESEARCH_DIFFICULTY"))) {
                BASE_RESEARCH_DIFFICULTY = proposal.newValue;
                globalKnowledgeParameters["researchDifficulty"] = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("MAX_ENTROPY"))) {
                MAX_ENTROPY = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("REDEEM_VALUE_PERCENTAGE"))) {
                REDEEM_VALUE_PERCENTAGE = proposal.newValue;
            }
            // Add more parameter updates as needed
        }

        // Return deposit to proposer regardless of outcome
        _balancesTimeCrystal[proposal.proposer] += proposal.depositAmount;

        emit ProposalExecuted(_proposalId, passed);
    }

    /**
     * @notice Admin function (or via governance initially) to set foundational parameters.
     * @dev Only callable by contract owner.
     * @param _baseFuelCost Initial cost for fueling.
     * @param _baseDecayRate Initial rate of decay per day.
     * @param _baseResearchDifficulty Initial difficulty for research.
     */
    function setBaseParameters(
        uint256 _baseFuelCost,
        uint256 _baseDecayRate,
        uint256 _baseResearchDifficulty
    ) public onlyOwner {
        BASE_FUEL_COST = _baseFuelCost;
        BASE_DECAY_RATE_PER_DAY = _baseDecayRate;
        BASE_RESEARCH_DIFFICULTY = _baseResearchDifficulty;

        globalKnowledgeParameters["baseDecayRate"] = _baseDecayRate;
        globalKnowledgeParameters["researchDifficulty"] = _baseResearchDifficulty;
    }

    /**
     * @notice Admin function to distribute initial TimeCrystal tokens (e.g., for team, marketing).
     * @dev Only callable by contract owner.
     * @param _to The address to receive TimeCrystals.
     * @param _amount The amount of TimeCrystals to distribute.
     */
    function distributeTimeCrystals(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Cannot distribute to zero address");
        // No checks on total supply here, assuming this is an initial distribution from owner's balance
        // or a controlled minting function if it's meant to increase total supply.
        // For this demo, it's just moving from owner's pre-minted supply.
        require(_balancesTimeCrystal[msg.sender] >= _amount, "Owner has insufficient TimeCrystals to distribute");
        _balancesTimeCrystal[msg.sender] -= _amount;
        _balancesTimeCrystal[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
    }

    /**
     * @notice Allows the contract owner to withdraw any residual ETH from the contract.
     * @param _recipient The address to send the ETH to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawAdminFunds(address _recipient, uint256 _amount) public onlyOwner {
        require(_recipient != address(0), "Withdraw to zero address not allowed");
        require(address(this).balance >= _amount, "Insufficient ETH balance in contract");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```