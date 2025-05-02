Okay, here is a Solidity smart contract concept called `CryptoForge`. It's designed around a digital crafting/forging theme, incorporating several mechanics: internal token/NFT-like asset management, a skill system, time-based asset decay, delegation of rights, and a discovery mechanism.

It does *not* use standard libraries like ERC-20 or ERC-721 directly (implementing simplified internal versions instead to avoid duplication), nor does it replicate common DeFi protocols. It focuses on internal state manipulation and interactions within the contract itself.

**Outline & Function Summary:**

**Project Name:** CryptoForge

**Description:**
A smart contract serving as a decentralized digital forge. Users can deposit 'Material Tokens' (MTL), manage internal 'Artifact NFTs' (ART) with dynamic properties (Quality, Durability, Age), and use the forging process to create new artifacts, enhance existing ones, or disassemble them. The system includes a user skill level that affects outcomes, a time-based decay mechanism for artifacts, and a delegation system for forging rights.

**Assets Managed (Internally):**
1.  **Material Tokens (MTL):** A simple fungible token balance tracker within the contract. Used for costs, rewards, and skill progression.
2.  **Artifact NFTs (ART):** Non-fungible assets tracked by ownership and properties within the contract. Each artifact has a unique ID, owner, quality, durability, and time-based attributes.

**Core Mechanics:**
*   **Forging:** Creating new artifacts from materials and potential other artifacts.
*   **Enhancement:** Improving properties (Quality, Durability) of existing artifacts.
*   **Repair:** Restoring Durability of artifacts.
*   **Disassembly:** Breaking down artifacts into materials.
*   **Combination:** Merging multiple artifacts into one.
*   **Skill System:** Users gain skill by interacting, affecting crafting outcomes.
*   **Time Decay:** Artifact Durability decays over time if not maintained.
*   **Delegation:** Owners can delegate forging/interaction rights for their artifacts and materials.
*   **Discovery:** A probabilistic mechanism to find materials or basic artifacts.
*   **Parameterized Forge:** Owner can adjust costs and rates.

**Function Summary (Minimum 20+ functions):**

**Administrative (Owner Only):**
1.  `constructor()`: Sets initial contract owner.
2.  `transferOwnership(address newOwner)`: Transfers ownership of the contract.
3.  `renounceOwnership()`: Renounces ownership (sets owner to zero address).
4.  `withdrawContractBalance(uint256 amount)`: Allows owner to withdraw ETH held by the contract (if any).
5.  `withdrawMaterialTokens(uint256 amount)`: Allows owner to withdraw MTL held by the contract.
6.  `setForgeParameter(bytes32 parameterName, uint256 value)`: Sets system parameters like costs, rates, etc.

**Material Token Management (Internal MTL):**
7.  `depositMaterialTokens()`: Users send ETH to mint internal MTL (simple exchange rate).
8.  `getMaterialBalance(address account)`: Checks an account's internal MTL balance.
9.  `transferMaterialTokens(address recipient, uint256 amount)`: Transfers internal MTL between users.
10. `approveMaterialSpending(address spender, uint256 amount)`: Approves a spender to withdraw MTL.
11. `transferMaterialTokensFrom(address sender, address recipient, uint256 amount)`: Spends approved MTL.

**Artifact NFT Management (Internal ART):**
12. `getArtifactOwner(uint256 artifactId)`: Gets the owner of an artifact.
13. `getArtifactProperties(uint256 artifactId)`: Gets the detailed properties of an artifact.
14. `transferArtifact(address to, uint256 artifactId)`: Transfers ownership of an artifact.
15. `approveArtifactTransfer(address approved, uint256 artifactId)`: Approves an address to transfer an artifact.
16. `transferArtifactFrom(address from, address to, uint256 artifactId)`: Transfers an approved artifact.
17. `getTotalArtifactsMinted()`: Gets the total number of artifacts created.

**Core Forging & Crafting:**
18. `forgeNewArtifact(uint256 materialCost, uint256 baseQuality)`: Creates a new artifact, consuming MTL. Skill affects outcome.
19. `enhanceArtifact(uint256 artifactId, uint256 materialCost)`: Improves an existing artifact's quality/durability, consuming MTL. Skill affects outcome.
20. `repairArtifact(uint256 artifactId, uint256 materialCost)`: Restores durability of an artifact, consuming MTL.
21. `disassembleArtifact(uint256 artifactId)`: Breaks down an artifact into MTL, consuming the artifact. Output depends on properties.
22. `combineArtifacts(uint256 artifactId1, uint256 artifactId2, uint256 materialCost)`: Combines two artifacts into a potentially new/enhanced one. Consumes inputs.

**Advanced & Utility:**
23. `delegateForgeRights(address delegatee, bool approved)`: Delegates the right to perform forging actions on the caller's behalf.
24. `checkForgeDelegation(address delegator, address delegatee)`: Checks if delegation is active.
25. `getForgeSkill(address account)`: Gets a user's current forge skill level.
26. `gainSkillExperience(uint256 materialCost)`: Allows users to spend MTL to gain forge skill experience.
27. `applyArtifactDecay(uint256 artifactId)`: Allows anyone to trigger time-based durability decay for an artifact (if applicable).
28. `queryPotentialDecay(uint256 artifactId)`: Checks how much durability decay is pending for an artifact.
29. `performDiscoveryAttempt(uint256 materialCost)`: Attempts a discovery roll for materials/basic artifacts, consuming MTL. Probabilistic outcome.
30. `getForgeParameter(bytes32 parameterName)`: Gets the value of a system parameter.
31. `getRequiredMaterialsEstimate(bytes32 operationType, uint256 desiredOutcome)`: Provides an estimated MTL cost for an operation based on type and desired quality/etc. (Conceptual/view function).
32. `predictForgeOutcome(uint256 materialInput, uint256 userSkill)`: Predicts the potential range of outcomes (e.g., quality) for a forging operation given inputs and skill. (Conceptual/view function).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- CryptoForge Smart Contract ---
//
// Outline & Function Summary:
//
// Project Name: CryptoForge
// Description:
// A smart contract serving as a decentralized digital forge. Users can deposit
// 'Material Tokens' (MTL), manage internal 'Artifact NFTs' (ART) with dynamic
// properties (Quality, Durability, Age), and use the forging process to
// create new artifacts, enhance existing ones, or disassemble them. The system
// includes a user skill level that affects outcomes, a time-based decay
// mechanism for artifacts, and a delegation system for forging rights.
//
// Assets Managed (Internally):
// 1. Material Tokens (MTL): Simple fungible token balance tracker within the contract.
// 2. Artifact NFTs (ART): Non-fungible assets tracked by ownership and properties.
//
// Core Mechanics:
// - Forging, Enhancement, Repair, Disassembly, Combination
// - Skill System
// - Time Decay for Artifacts
// - Delegation of Forging Rights
// - Discovery Mechanism
// - Parameterized Costs/Rates
//
// Function Summary:
//
// Administrative (Owner Only):
// 1.  constructor()
// 2.  transferOwnership(address newOwner)
// 3.  renounceOwnership()
// 4.  withdrawContractBalance(uint256 amount)
// 5.  withdrawMaterialTokens(uint256 amount)
// 6.  setForgeParameter(bytes32 parameterName, uint256 value)
//
// Material Token Management (Internal MTL):
// 7.  depositMaterialTokens() (Payable)
// 8.  getMaterialBalance(address account) (View)
// 9.  transferMaterialTokens(address recipient, uint256 amount)
// 10. approveMaterialSpending(address spender, uint256 amount)
// 11. transferMaterialTokensFrom(address sender, address recipient, uint256 amount)
//
// Artifact NFT Management (Internal ART):
// 12. getArtifactOwner(uint256 artifactId) (View)
// 13. getArtifactProperties(uint256 artifactId) (View)
// 14. transferArtifact(address to, uint256 artifactId)
// 15. approveArtifactTransfer(address approved, uint256 artifactId)
// 16. transferArtifactFrom(address from, address to, uint256 artifactId)
// 17. getTotalArtifactsMinted() (View)
//
// Core Forging & Crafting:
// 18. forgeNewArtifact(uint256 materialCost, uint256 baseQuality)
// 19. enhanceArtifact(uint256 artifactId, uint256 materialCost)
// 20. repairArtifact(uint256 artifactId, uint256 materialCost)
// 21. disassembleArtifact(uint256 artifactId)
// 22. combineArtifacts(uint256 artifactId1, uint256 artifactId2, uint256 materialCost)
//
// Advanced & Utility:
// 23. delegateForgeRights(address delegatee, bool approved)
// 24. checkForgeDelegation(address delegator, address delegatee) (View)
// 25. getForgeSkill(address account) (View)
// 26. gainSkillExperience(uint256 materialCost)
// 27. applyArtifactDecay(uint256 artifactId)
// 28. queryPotentialDecay(uint256 artifactId) (View)
// 29. performDiscoveryAttempt(uint256 materialCost)
// 30. getForgeParameter(bytes32 parameterName) (View)
// 31. getRequiredMaterialsEstimate(bytes32 operationType, uint256 desiredOutcome) (View)
// 32. predictForgeOutcome(uint256 materialInput, uint256 userSkill) (View)
//
// ---

contract CryptoForge {

    // --- State Variables ---

    address private _owner;

    // Material Token (MTL) System - Internal Balances
    mapping(address => uint256) private _materialBalances;
    // Allowances for spending material tokens
    mapping(address => mapping(address => uint256)) private _materialAllowances;

    // Artifact NFT (ART) System - Internal Tracking
    struct ArtifactProperties {
        uint256 quality;         // Affects performance, outcome likelihoods
        uint256 durability;      // Decreases with use/time, needs repair
        uint256 maxDurability;   // Max durability capacity
        uint256 creationTime;    // Timestamp of creation
        uint256 lastInteractionTime; // Timestamp of last forge/enhance/repair
        address creator;         // Address that originally forged it
        // Could add parent IDs, type, etc. for more complexity
    }
    uint256 private _nextArtifactId;
    mapping(uint256 => address) private _artifactOwners;
    mapping(uint256 => ArtifactProperties) private _artifactProperties;
    // Allowances for transferring artifacts (ERC-721 style)
    mapping(uint256 => address) private _artifactApprovals;

    // User Skill System
    mapping(address => uint256) private _userSkill; // Simple skill level/experience

    // Delegation System (Who can forge/interact on whose behalf)
    mapping(address => mapping(address => bool)) private _forgeDelegation; // delegator => delegatee => approved

    // Forge Parameters (Owner configurable)
    mapping(bytes32 => uint256) private _parameters;

    // Constants (for parameter names)
    bytes32 public constant PARAM_MTL_EXCHANGE_RATE = "MTL_EXCHANGE_RATE";
    bytes32 public constant PARAM_FORGE_BASE_COST = "FORGE_BASE_COST";
    bytes32 public constant PARAM_ENHANCE_BASE_COST = "ENHANCE_BASE_COST";
    bytes32 public constant PARAM_REPAIR_BASE_COST = "REPAIR_BASE_COST";
    bytes32 public constant PARAM_DISASSEMBLE_YIELD_RATE = "DISASSEMBLE_YIELD_RATE"; // Percentage
    bytes32 public constant PARAM_COMBINE_BASE_COST = "COMBINE_BASE_COST";
    bytes32 public constant PARAM_SKILL_GAIN_COST = "SKILL_GAIN_COST";
    bytes32 public constant PARAM_SKILL_GAIN_AMOUNT = "SKILL_GAIN_AMOUNT";
    bytes32 public constant PARAM_DECAY_RATE_PER_DAY = "DECAY_RATE_PER_DAY"; // Durability points per day
    bytes32 public constant PARAM_DISCOVERY_BASE_COST = "DISCOVERY_BASE_COST";
    bytes32 public constant PARAM_DISCOVERY_SUCCESS_CHANCE = "DISCOVERY_SUCCESS_CHANCE"; // Percentage
    bytes32 public constant PARAM_DISCOVERY_MAX_MTL_YIELD = "DISCOVERY_MAX_MTL_YIELD";
     bytes32 public constant PARAM_QUALITY_SKILL_MULTIPLIER = "QUALITY_SKILL_MULTIPLIER"; // How much skill affects quality

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MaterialTokensDeposited(address indexed account, uint256 ethAmount, uint256 mtlAmount);
    event MaterialTokensTransferred(address indexed from, address indexed to, uint256 amount);
    event MaterialTokensApproved(address indexed owner, address indexed spender, uint256 amount);
    event ArtifactMinted(address indexed owner, uint256 indexed artifactId, uint256 quality, uint256 durability);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed artifactId);
    event ArtifactApproved(address indexed owner, address indexed approved, uint256 indexed artifactId);
    event ArtifactPropertiesUpdated(uint256 indexed artifactId, uint256 quality, uint256 durability, uint256 lastInteractionTime);
    event ArtifactBurned(address indexed owner, uint256 indexed artifactId, uint256 materialYield); // For disassembly
    event ForgeDelegationUpdated(address indexed delegator, address indexed delegatee, bool approved);
    event SkillGained(address indexed account, uint256 newSkillLevel);
    event ArtifactDecayed(uint256 indexed artifactId, uint256 decayAmount, uint256 newDurability);
    event DiscoveryAttempted(address indexed account, uint256 materialCost, bool success, uint256 yieldAmount);
    event ParameterSet(bytes32 parameterName, uint256 value);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier onlyArtifactOwnerOrDelegate(uint256 artifactId) {
        address owner = _artifactOwners[artifactId];
        require(owner != address(0), "Artifact does not exist");
        require(msg.sender == owner || _forgeDelegation[owner][msg.sender], "Not artifact owner or authorized delegate");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _nextArtifactId = 1; // Start artifact IDs from 1
        // Set initial default parameters
        _parameters[PARAM_MTL_EXCHANGE_RATE] = 1e16; // 0.01 ETH = 1 MTL (adjust units as needed, using 1e18 for ETH typically)
        _parameters[PARAM_FORGE_BASE_COST] = 10 * 1e18; // Example: 10 MTL
        _parameters[PARAM_ENHANCE_BASE_COST] = 5 * 1e18; // Example: 5 MTL
        _parameters[PARAM_REPAIR_BASE_COST] = 2 * 1e18; // Example: 2 MTL
        _parameters[PARAM_DISASSEMBLE_YIELD_RATE] = 70; // 70% yield
        _parameters[PARAM_COMBINE_BASE_COST] = 15 * 1e18; // Example: 15 MTL
        _parameters[PARAM_SKILL_GAIN_COST] = 5 * 1e18; // Example: 5 MTL to gain skill
        _parameters[PARAM_SKILL_GAIN_AMOUNT] = 1; // Gain 1 skill point
        _parameters[PARAM_DECAY_RATE_PER_DAY] = 5; // Lose 5 durability per day
        _parameters[PARAM_DISCOVERY_BASE_COST] = 1 * 1e18; // Example: 1 MTL per attempt
        _parameters[PARAM_DISCOVERY_SUCCESS_CHANCE] = 30; // 30% chance
        _parameters[PARAM_DISCOVERY_MAX_MTL_YIELD] = 20 * 1e18; // Max 20 MTL yield
        _parameters[PARAM_QUALITY_SKILL_MULTIPLIER] = 10; // 10x skill points increase quality
    }

    // --- Administrative Functions ---

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @notice Relinquishes ownership of the contract.
    function renounceOwnership() external onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    /// @notice Allows the owner to withdraw accumulated ETH from the contract.
    /// @param amount The amount of ETH to withdraw.
    function withdrawContractBalance(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient contract balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH withdrawal failed");
    }

    /// @notice Allows the owner to withdraw accumulated internal Material Tokens from the contract's balance.
    /// @param amount The amount of MTL to withdraw.
    function withdrawMaterialTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(_materialBalances[address(this)] >= amount, "Insufficient contract MTL balance");
        _materialBalances[address(this)] -= amount;
        _materialBalances[_owner] += amount; // Withdraws to the owner's MTL balance
        emit MaterialTokensTransferred(address(this), _owner, amount);
    }

     /// @notice Sets a configurable parameter for the forge system.
    /// @param parameterName The keccak256 hash of the parameter name string.
    /// @param value The new value for the parameter.
    function setForgeParameter(bytes32 parameterName, uint256 value) external onlyOwner {
        _parameters[parameterName] = value;
        emit ParameterSet(parameterName, value);
    }

    // --- Material Token Management ---

    /// @notice Allows users to deposit ETH to receive internal Material Tokens based on the exchange rate.
    function depositMaterialTokens() external payable {
        require(msg.value > 0, "ETH amount must be greater than zero");
        uint256 exchangeRate = _parameters[PARAM_MTL_EXCHANGE_RATE];
        require(exchangeRate > 0, "MTL exchange rate not set or zero");
        uint256 mtlAmount = (msg.value * (10**18)) / exchangeRate; // Assuming exchangeRate is in ETH units per MTL
        require(mtlAmount > 0, "Calculated MTL amount is zero");

        _materialBalances[msg.sender] += mtlAmount;
        emit MaterialTokensDeposited(msg.sender, msg.value, mtlAmount);
    }

    /// @notice Returns the internal Material Token balance for an account.
    /// @param account The address to query.
    /// @return The balance of Material Tokens.
    function getMaterialBalance(address account) external view returns (uint256) {
        return _materialBalances[account];
    }

    /// @notice Transfers internal Material Tokens from the caller's balance to another account.
    /// @param recipient The address to transfer MTL to.
    /// @param amount The amount of MTL to transfer.
    function transferMaterialTokens(address recipient, uint256 amount) external {
        require(recipient != address(0), "Recipient cannot be the zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(_materialBalances[msg.sender] >= amount, "Insufficient material token balance");

        _materialBalances[msg.sender] -= amount;
        _materialBalances[recipient] += amount;
        emit MaterialTokensTransferred(msg.sender, recipient, amount);
    }

    /// @notice Approves an address to spend a specified amount of internal Material Tokens on behalf of the caller.
    /// @param spender The address to approve.
    /// @param amount The amount of MTL that can be spent.
    function approveMaterialSpending(address spender, uint256 amount) external {
        require(spender != address(0), "Spender cannot be the zero address");
        _materialAllowances[msg.sender][spender] = amount;
        emit MaterialTokensApproved(msg.sender, spender, amount);
    }

    /// @notice Transfers internal Material Tokens from one account to another using the spender's allowance.
    /// @param sender The address from which to transfer MTL.
    /// @param recipient The address to transfer MTL to.
    /// @param amount The amount of MTL to transfer.
    function transferMaterialTokensFrom(address sender, address recipient, uint256 amount) external {
        require(sender != address(0), "Sender cannot be the zero address");
        require(recipient != address(0), "Recipient cannot be the zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(_materialBalances[sender] >= amount, "Insufficient material token balance");
        require(_materialAllowances[sender][msg.sender] >= amount, "Insufficient allowance");

        _materialBalances[sender] -= amount;
        _materialBalances[recipient] += amount;
        _materialAllowances[sender][msg.sender] -= amount;
        emit MaterialTokensTransferred(sender, recipient, amount);
    }

    // --- Artifact NFT Management ---

    /// @notice Returns the owner of a specific artifact.
    /// @param artifactId The ID of the artifact.
    /// @return The address of the artifact owner, or address(0) if not found.
    function getArtifactOwner(uint256 artifactId) external view returns (address) {
        return _artifactOwners[artifactId];
    }

    /// @notice Returns the detailed properties of a specific artifact.
    /// @param artifactId The ID of the artifact.
    /// @return A struct containing the artifact's properties.
    function getArtifactProperties(uint256 artifactId) external view returns (ArtifactProperties memory) {
        require(_artifactOwners[artifactId] != address(0), "Artifact does not exist");
        return _artifactProperties[artifactId];
    }

    /// @notice Transfers ownership of an artifact. Only the owner or approved address can call this.
    /// @param to The recipient address.
    /// @param artifactId The ID of the artifact to transfer.
    function transferArtifact(address to, uint256 artifactId) external {
        require(to != address(0), "Recipient cannot be the zero address");
        address owner = _artifactOwners[artifactId];
        require(owner != address(0), "Artifact does not exist");
        require(msg.sender == owner || _artifactApprovals[artifactId] == msg.sender, "Not artifact owner or approved");

        _transferArtifact(owner, to, artifactId);
        _artifactApprovals[artifactId] = address(0); // Clear approval after transfer
    }

    /// @notice Approves an address to transfer a specific artifact on behalf of the owner.
    /// @param approved The address to approve.
    /// @param artifactId The ID of the artifact to approve.
    function approveArtifactTransfer(address approved, uint256 artifactId) external {
        address owner = _artifactOwners[artifactId];
        require(owner != address(0), "Artifact does not exist");
        require(msg.sender == owner, "Only artifact owner can approve");
        _artifactApprovals[artifactId] = approved;
        emit ArtifactApproved(owner, approved, artifactId);
    }

    /// @notice Transfers an artifact using the caller's approval rights.
    /// @param from The address from which to transfer the artifact (must be the owner).
    /// @param to The recipient address.
    /// @param artifactId The ID of the artifact to transfer.
    function transferArtifactFrom(address from, address to, uint256 artifactId) external {
        require(from != address(0), "Sender cannot be the zero address");
        require(to != address(0), "Recipient cannot be the zero address");
        address owner = _artifactOwners[artifactId];
        require(owner != address(0), "Artifact does not exist");
        require(from == owner, "Artifact must be owned by 'from' address");
        require(msg.sender == owner || _artifactApprovals[artifactId] == msg.sender, "Not artifact owner or approved");

        _transferArtifact(owner, to, artifactId);
        _artifactApprovals[artifactId] = address(0); // Clear approval after transfer
    }

    /// @notice Internal helper for transferring artifact ownership.
    function _transferArtifact(address from, address to, uint256 artifactId) internal {
        _artifactOwners[artifactId] = to;
        emit ArtifactTransferred(from, to, artifactId);
    }

    /// @notice Returns the total number of artifacts minted by the contract.
    /// @return The total count of artifacts.
    function getTotalArtifactsMinted() external view returns (uint256) {
        return _nextArtifactId - 1;
    }

    // --- Core Forging & Crafting ---

    /// @notice Forges a new artifact, consuming materials and affected by skill.
    /// @param materialCost The amount of MTL to consume for forging.
    /// @param baseQuality The base quality level to attempt for the new artifact.
    /// @return The ID of the newly minted artifact.
    function forgeNewArtifact(uint256 materialCost, uint256 baseQuality) external {
        require(materialCost > 0, "Material cost must be greater than zero");
        require(_materialBalances[msg.sender] >= materialCost, "Insufficient material tokens");

        uint256 totalCost = materialCost + _parameters[PARAM_FORGE_BASE_COST];
        require(_materialBalances[msg.sender] >= totalCost, "Insufficient material tokens for base cost");

        _materialBalances[msg.sender] -= totalCost;
        _materialBalances[address(this)] += totalCost; // Send consumed MTL to contract balance

        uint256 skill = _userSkill[msg.sender];
        uint256 qualityMultiplier = _parameters[PARAM_QUALITY_SKILL_MULTIPLIER];
        uint256 finalQuality = baseQuality + (skill / qualityMultiplier); // Skill provides a bonus
        // Add some variation based on skill or other factors for advanced versions

        uint256 newArtifactId = _nextArtifactId++;
        _artifactOwners[newArtifactId] = msg.sender;
        ArtifactProperties storage props = _artifactProperties[newArtifactId];
        props.quality = finalQuality;
        props.durability = 100; // Start with full durability
        props.maxDurability = 100;
        props.creationTime = block.timestamp;
        props.lastInteractionTime = block.timestamp;
        props.creator = msg.sender;

        emit ArtifactMinted(msg.sender, newArtifactId, props.quality, props.durability);
    }

    /// @notice Enhances an existing artifact, consuming materials and affected by skill.
    /// @param artifactId The ID of the artifact to enhance.
    /// @param materialCost The amount of MTL to consume for enhancement.
    function enhanceArtifact(uint256 artifactId, uint256 materialCost) external onlyArtifactOwnerOrDelegate(artifactId) {
        require(materialCost > 0, "Material cost must be greater than zero");
        require(_materialBalances[msg.sender] >= materialCost, "Insufficient material tokens");

        uint256 totalCost = materialCost + _parameters[PARAM_ENHANCE_BASE_COST];
         require(_materialBalances[msg.sender] >= totalCost, "Insufficient material tokens for base cost");

        ArtifactProperties storage props = _artifactProperties[artifactId];
        // Ensure artifact exists and is owned by msg.sender or delegated
        // Modifier `onlyArtifactOwnerOrDelegate` handles owner/delegation check
        require(props.durability > 0, "Artifact durability is zero, needs repair first"); // Can't enhance broken item

        _materialBalances[msg.sender] -= totalCost;
        _materialBalances[address(this)] += totalCost; // Send consumed MTL to contract balance

        uint256 skill = _userSkill[msg.sender];
        uint256 qualityImprovement = materialCost / _parameters[PARAM_ENHANCE_BASE_COST]; // Simple scale
        qualityImprovement = qualityImprovement + (skill / _parameters[PARAM_QUALITY_SKILL_MULTIPLIER] / 2); // Skill gives lesser bonus than forging

        props.quality += qualityImprovement;
        props.durability = props.maxDurability; // Enhancement also fully repairs
        props.lastInteractionTime = block.timestamp;

        emit ArtifactPropertiesUpdated(artifactId, props.quality, props.durability, props.lastInteractionTime);
    }

    /// @notice Repairs an artifact's durability, consuming materials.
    /// @param artifactId The ID of the artifact to repair.
    /// @param materialCost The amount of MTL to consume for repair.
    function repairArtifact(uint256 artifactId, uint256 materialCost) external onlyArtifactOwnerOrDelegate(artifactId) {
         require(materialCost > 0, "Material cost must be greater than zero");
        require(_materialBalances[msg.sender] >= materialCost, "Insufficient material tokens");

        uint256 totalCost = materialCost + _parameters[PARAM_REPAIR_BASE_COST];
        require(_materialBalances[msg.sender] >= totalCost, "Insufficient material tokens for base cost");

        ArtifactProperties storage props = _artifactProperties[artifactId];
        // Modifier `onlyArtifactOwnerOrDelegate` handles owner/delegation check

        uint256 durabilityNeeded = props.maxDurability - props.durability;
        require(durabilityNeeded > 0, "Artifact durability is already full");

        _materialBalances[msg.sender] -= totalCost;
        _materialBalances[address(this)] += totalCost; // Send consumed MTL to contract balance

        // Simple repair amount calculation
        uint256 repairAmount = (materialCost * 100) / _parameters[PARAM_REPAIR_BASE_COST]; // 100% repair per base cost
        props.durability = uint256(int256(props.durability) + int256(repairAmount)); // Safe add within uint bounds implicitly checked by min(maxDurability)
        if (props.durability > props.maxDurability) {
            props.durability = props.maxDurability;
        }
        props.lastInteractionTime = block.timestamp;

        emit ArtifactPropertiesUpdated(artifactId, props.quality, props.durability, props.lastInteractionTime);
    }

    /// @notice Disassembles an artifact back into materials, consuming the artifact.
    /// @param artifactId The ID of the artifact to disassemble.
    /// @return The amount of MTL yielded from disassembly.
    function disassembleArtifact(uint256 artifactId) external onlyArtifactOwnerOrDelegate(artifactId) {
        ArtifactProperties storage props = _artifactProperties[artifactId];
        address owner = _artifactOwners[artifactId];
        // Modifier `onlyArtifactOwnerOrDelegate` handles owner/delegation check

        // Calculate material yield based on quality and durability
        uint256 yieldRate = _parameters[PARAM_DISASSEMBLE_YIELD_RATE]; // Percentage
        // Example yield calculation: Quality * Durability / MaxDurability * BaseValue * YieldRate
        // Let's simplify: Yield based on initial cost/value scaled by quality and durability percentage
        uint256 estimatedBaseValue = _parameters[PARAM_FORGE_BASE_COST]; // Approximation
        uint256 yieldAmount = (estimatedBaseValue * props.quality) / 100; // Quality adds value
        yieldAmount = (yieldAmount * props.durability) / props.maxDurability; // Durability affects yield
        yieldAmount = (yieldAmount * yieldRate) / 100; // Apply the disassembly rate

        // Burn the artifact
        delete _artifactOwners[artifactId];
        delete _artifactProperties[artifactId];
        delete _artifactApprovals[artifactId]; // Clear any approvals

        // Transfer yielded materials back to the owner/caller (delegatee)
        _materialBalances[msg.sender] += yieldAmount;

        emit ArtifactBurned(owner, artifactId, yieldAmount);
    }

    /// @notice Combines two artifacts into one, consuming materials and the input artifacts.
    /// @param artifactId1 The ID of the first artifact.
    /// @param artifactId2 The ID of the second artifact.
    /// @param materialCost The amount of MTL to consume for combination.
    /// @return The ID of the resulting artifact (can be new or one of the inputs enhanced).
    function combineArtifacts(uint256 artifactId1, uint256 artifactId2, uint256 materialCost) external {
        require(artifactId1 != artifactId2, "Cannot combine an artifact with itself");
        require(materialCost > 0, "Material cost must be greater than zero");

        address owner1 = _artifactOwners[artifactId1];
        address owner2 = _artifactOwners[artifactId2];
        require(owner1 != address(0), "Artifact 1 does not exist");
        require(owner2 != address(0), "Artifact 2 does not exist");
        // Both artifacts must be owned by or delegated to the caller
        require(msg.sender == owner1 || _forgeDelegation[owner1][msg.sender], "Not owner/delegate of Artifact 1");
        require(msg.sender == owner2 || _forgeDelegation[owner2][msg.sender], "Not owner/delegate of Artifact 2");

        require(_materialBalances[msg.sender] >= materialCost, "Insufficient material tokens");

        uint256 totalCost = materialCost + _parameters[PARAM_COMBINE_BASE_COST];
        require(_materialBalances[msg.sender] >= totalCost, "Insufficient material tokens for base cost");

        _materialBalances[msg.sender] -= totalCost;
        _materialBalances[address(this)] += totalCost; // Send consumed MTL to contract balance

        ArtifactProperties storage props1 = _artifactProperties[artifactId1];
        ArtifactProperties storage props2 = _artifactProperties[artifactId2];

        // Decide outcome: new artifact vs. enhance one of the inputs.
        // For simplicity, let's combine into a NEW artifact, taking traits from both.
        // More complex logic could involve probabilities, specific recipes, etc.

        uint256 newArtifactId = _nextArtifactId++;
        _artifactOwners[newArtifactId] = msg.sender; // New artifact goes to the caller

        ArtifactProperties storage newProps = _artifactProperties[newArtifactId];

        // Simple property combination: average quality, summed durability (up to a new max?)
        newProps.quality = (props1.quality + props2.quality) / 2;
        newProps.maxDurability = props1.maxDurability + props2.maxDurability;
        newProps.durability = newProps.maxDurability; // Start with full new durability
        newProps.creationTime = block.timestamp;
        newProps.lastInteractionTime = block.timestamp;
        newProps.creator = msg.sender; // New creator is the one who combined them

        // Burn the input artifacts
        delete _artifactOwners[artifactId1];
        delete _artifactProperties[artifactId1];
        delete _artifactApprovals[artifactId1];

        delete _artifactOwners[artifactId2];
        delete _artifactProperties[artifactId2];
        delete _artifactApprovals[artifactId2];

        emit ArtifactBurned(owner1, artifactId1, 0); // No material yield on combination
        emit ArtifactBurned(owner2, artifactId2, 0);
        emit ArtifactMinted(msg.sender, newArtifactId, newProps.quality, newProps.durability); // Emit minted for the new one

        return newArtifactId;
    }


    // --- Advanced & Utility ---

    /// @notice Delegates the right to perform forging/crafting actions on the caller's behalf.
    /// @param delegatee The address to delegate rights to.
    /// @param approved True to grant rights, false to revoke.
    function delegateForgeRights(address delegatee, bool approved) external {
        require(delegatee != address(0), "Delegatee cannot be the zero address");
        _forgeDelegation[msg.sender][delegatee] = approved;
        emit ForgeDelegationUpdated(msg.sender, delegatee, approved);
    }

    /// @notice Checks if a delegatee has forging rights from a delegator.
    /// @param delegator The address granting rights.
    /// @param delegatee The address potentially holding rights.
    /// @return True if approved, false otherwise.
    function checkForgeDelegation(address delegator, address delegatee) external view returns (bool) {
        return _forgeDelegation[delegator][delegatee];
    }

    /// @notice Gets the current forge skill level for an account.
    /// @param account The address to query.
    /// @return The skill level.
    function getForgeSkill(address account) external view returns (uint256) {
        return _userSkill[account];
    }

    /// @notice Allows a user to spend materials to gain forge skill experience.
    /// @param materialCost The amount of MTL to spend for skill gain.
    function gainSkillExperience(uint256 materialCost) external {
        require(materialCost > 0, "Material cost must be greater than zero");
        uint256 skillGainCost = _parameters[PARAM_SKILL_GAIN_COST];
        require(skillGainCost > 0, "Skill gain cost parameter not set");
        require(_materialBalances[msg.sender] >= materialCost, "Insufficient material tokens");

        uint256 effectiveCost = (materialCost / skillGainCost) * skillGainCost; // Pay in increments of skillGainCost
        require(effectiveCost > 0, "Material cost is less than the skill gain cost unit");

        _materialBalances[msg.sender] -= effectiveCost;
        _materialBalances[address(this)] += effectiveCost; // Send consumed MTL to contract balance

        uint256 skillAmountGained = (effectiveCost / skillGainCost) * _parameters[PARAM_SKILL_GAIN_AMOUNT];
        _userSkill[msg.sender] += skillAmountGained;

        emit SkillGained(msg.sender, _userSkill[msg.sender]);
    }

    /// @notice Applies time-based durability decay to an artifact. Can be called by anyone.
    /// @param artifactId The ID of the artifact to decay.
    function applyArtifactDecay(uint256 artifactId) external {
        ArtifactProperties storage props = _artifactProperties[artifactId];
        require(_artifactOwners[artifactId] != address(0), "Artifact does not exist"); // Check existence

        uint256 decayRatePerDay = _parameters[PARAM_DECAY_RATE_PER_DAY];
        if (decayRatePerDay == 0) {
            // No decay configured
            return;
        }

        uint256 timeElapsed = block.timestamp - props.lastInteractionTime;
        uint256 secondsPerDay = 24 * 60 * 60;

        if (timeElapsed < secondsPerDay) {
            // Not enough time passed for a full day's decay
            return;
        }

        uint256 daysElapsed = timeElapsed / secondsPerDay;
        uint256 potentialDecay = daysElapsed * decayRatePerDay;

        if (potentialDecay == 0) {
             // Should not happen if daysElapsed > 0 and rate > 0, but safety check
            return;
        }

        uint256 actualDecay = potentialDecay;
        if (props.durability < actualDecay) {
            actualDecay = props.durability;
        }

        if (actualDecay > 0) {
            props.durability -= actualDecay;
            props.lastInteractionTime = block.timestamp; // Reset interaction time after applying decay

            emit ArtifactDecayed(artifactId, actualDecay, props.durability);

            // Optional: Reward caller for applying decay (e.g., small amount of MTL from contract balance)
            // uint256 reward = actualDecay / 10; // Example
            // if (_materialBalances[address(this)] >= reward) {
            //     _materialBalances[msg.sender] += reward;
            //     emit MaterialTokensTransferred(address(this), msg.sender, reward);
            // }
        }
    }

    /// @notice Queries the potential durability decay for an artifact based on time elapsed since last interaction.
    /// @param artifactId The ID of the artifact to query.
    /// @return The calculated potential decay amount (won't exceed current durability).
    function queryPotentialDecay(uint256 artifactId) external view returns (uint256) {
        ArtifactProperties storage props = _artifactProperties[artifactId];
        if (_artifactOwners[artifactId] == address(0)) {
             return 0; // Artifact does not exist
        }

        uint256 decayRatePerDay = _parameters[PARAM_DECAY_RATE_PER_DAY];
         if (decayRatePerDay == 0) {
            return 0; // No decay configured
        }

        uint256 timeElapsed = block.timestamp - props.lastInteractionTime;
        uint256 secondsPerDay = 24 * 60 * 60;

        if (timeElapsed < secondsPerDay) {
            return 0; // Not enough time passed for a full day's decay
        }

        uint256 daysElapsed = timeElapsed / secondsPerDay;
        uint256 potentialDecay = daysElapsed * decayRatePerDay;

        // Return decay, capped by current durability
        return potentialDecay > props.durability ? props.durability : potentialDecay;
    }

    /// @notice Performs a discovery attempt, potentially yielding materials or a basic artifact.
    /// @param materialCost The amount of MTL to spend on the attempt.
    function performDiscoveryAttempt(uint256 materialCost) external {
        require(materialCost > 0, "Material cost must be greater than zero");
        uint256 discoveryBaseCost = _parameters[PARAM_DISCOVERY_BASE_COST];
        require(discoveryBaseCost > 0, "Discovery base cost parameter not set");
        require(_materialBalances[msg.sender] >= materialCost, "Insufficient material tokens");

        uint256 totalCost = materialCost + discoveryBaseCost;
        require(_materialBalances[msg.sender] >= totalCost, "Insufficient material tokens for base cost");

        _materialBalances[msg.sender] -= totalCost;
        _materialBalances[address(this)] += totalCost; // Send consumed MTL to contract balance

        // Simple Pseudo-Randomness using block data
        // NOTE: block.timestamp and block.difficulty/block.prevrandao can be manipulated by miners.
        // For real-world randomness, use Chainlink VRF or similar oracle.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalCost)));

        uint256 successChance = _parameters[PARAM_DISCOVERY_SUCCESS_CHANCE]; // Percentage
        bool success = (randomNumber % 100) < successChance;

        uint256 yieldAmount = 0;
        if (success) {
            // Simple success: yield some MTL
            uint256 maxMtlYield = _parameters[PARAM_DISCOVERY_MAX_MTL_YIELD];
            yieldAmount = (randomNumber % maxMtlYield) + (materialCost / 2); // Yield scales with input and randomness

            _materialBalances[msg.sender] += yieldAmount;

            // Could also add a chance to mint a basic artifact here
            // if (randomNumber % 10 == 0) {
            //     // Mint a basic artifact with low quality
            //     uint256 newArtifactId = _nextArtifactId++;
            //     _artifactOwners[newArtifactId] = msg.sender;
            //     ArtifactProperties storage props = _artifactProperties[newArtifactId];
            //     props.quality = 1; // Basic quality
            //     props.durability = 50; // Used durability
            //     props.maxDurability = 100;
            //     props.creationTime = block.timestamp;
            //     props.lastInteractionTime = block.timestamp;
            //     props.creator = address(this); // Created by discovery
            //     emit ArtifactMinted(msg.sender, newArtifactId, props.quality, props.durability);
            // }

        } // Else: yield is 0

        emit DiscoveryAttempted(msg.sender, totalCost, success, yieldAmount);
    }

    /// @notice Returns the value of a configurable parameter.
    /// @param parameterName The keccak256 hash of the parameter name string.
    /// @return The value of the parameter.
    function getForgeParameter(bytes32 parameterName) external view returns (uint256) {
        return _parameters[parameterName];
    }

    /// @notice Provides an estimated material cost for a specific type of operation and desired outcome.
    /// @param operationType A string representing the operation type (e.g., "forge", "enhance", "repair", "combine").
    /// @param desiredOutcome A value indicating the desired quality, repair amount, etc. (Interpretation depends on type).
    /// @return The estimated material cost.
    function getRequiredMaterialsEstimate(bytes32 operationType, uint256 desiredOutcome) external view returns (uint256) {
        // This is a simplified estimation based on current parameters
        if (operationType == "forge") {
            // Estimate based on desired quality - inverse of skill effect + base cost
             uint256 qualityMultiplier = _parameters[PARAM_QUALITY_SKILL_MULTIPLIER];
             uint256 baseQualityNeeded = desiredOutcome;
             if (baseQualityNeeded > (_userSkill[msg.sender] / qualityMultiplier)) {
                 baseQualityNeeded -= (_userSkill[msg.sender] / qualityMultiplier);
             } else {
                 baseQualityNeeded = 0; // Skill covers the base
             }
             // This estimation is complex; for simplicity, let's just return a base cost + desired outcome influence
             return _parameters[PARAM_FORGE_BASE_COST] + (desiredOutcome * 5); // Example: higher quality costs more
        } else if (operationType == "enhance") {
            // Estimate based on desired quality gain - inverse of skill effect + base cost
            return _parameters[PARAM_ENHANCE_BASE_COST] + (desiredOutcome * 3); // Example: enhancing by N quality costs M MTL
        } else if (operationType == "repair") {
             // Estimate based on desired repair amount (durability points)
             uint256 repairCostPerPoint = _parameters[PARAM_REPAIR_BASE_COST] / 100; // Assuming base cost repairs 100 points
             if (repairCostPerPoint == 0) repairCostPerPoint = 1; // Avoid division by zero
             return _parameters[PARAM_REPAIR_BASE_COST] + (desiredOutcome * repairCostPerPoint); // Base cost + cost per point
        } else if (operationType == "combine") {
             // Estimate based on complexity or number of inputs/desired quality
             return _parameters[PARAM_COMBINE_BASE_COST] + (desiredOutcome * 8); // Example: combining for higher quality costs more
        }
        return 0; // Unknown operation type
    }

    /// @notice Predicts the potential range of outcomes (e.g., quality) for a forging operation given inputs and skill.
    /// @param materialInput The amount of material tokens planned for input.
    /// @param userSkill The skill level of the user performing the operation.
    /// @return minOutcome - The estimated minimum outcome (e.g., quality).
    /// @return maxOutcome - The estimated maximum outcome (e.g., quality).
    /// @dev This is a conceptual estimation and not guaranteed.
    function predictForgeOutcome(uint256 materialInput, uint256 userSkill) external view returns (uint256 minOutcome, uint256 maxOutcome) {
        // Simple prediction based on forgeNewArtifact logic
        uint256 baseQualityInfluence = materialInput / 100; // Simple scaling by input material
        uint256 skillInfluence = (userSkill * _parameters[PARAM_QUALITY_SKILL_MULTIPLIER]) / 100; // Skill bonus scaled

        // Basic range: lower bound is base + skill, upper bound adds some material influence again
        minOutcome = baseQualityInfluence + skillInfluence;
        maxOutcome = baseQualityInfluence + skillInfluence + (materialInput / 50); // Potential bonus from materials

        // Ensure a minimum quality if params allow
        if (minOutcome == 0 && maxOutcome == 0) {
            minOutcome = 1; maxOutcome = 5; // Small default range
        }
    }

     /// @notice Returns the internal Material Token balance held by the contract itself.
    /// @return The contract's MTL balance.
    function getContractMaterialBalance() external view returns (uint256) {
        return _materialBalances[address(this)];
    }

    // Fallback function to receive ETH for deposits
    receive() external payable {
        depositMaterialTokens(); // Automatically call deposit when ETH is sent
    }
}
```