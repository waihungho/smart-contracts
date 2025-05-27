Okay, here is a Solidity smart contract called "AuraNexus". It's designed around a concept of decentralized reputation ("Aura") earned through staking a native token ("NXS"), and using that Aura in an "Alchemy" process to potentially generate unique, dynamic "Seed" NFTs. Aura decays over time, encouraging active participation.

This contract aims for a creative blend of staking, reputation systems, and probabilistic/dynamic NFT minting, going beyond basic ERC-20/721 implementations or standard DeFi primitives by introducing decay mechanics, internal reputation, and a specific crafting-like process.

**Concept:**

AuraNexus is a protocol centered around:
1.  **NXS Token:** The native token users stake.
2.  **Aura:** A non-transferable, internal reputation score earned by staking NXS. Aura decays over time if not maintained by staking or interaction.
3.  **Alchemy:** A process where users commit staked NXS and consumed Aura to attempt to synthesize a unique digital asset (a "Seed" NFT). The outcome (success/failure, Seed traits) is influenced by the user's Aura, committed resources, and probabilistic elements.
4.  **Seeds:** Unique ERC721 tokens generated through successful Alchemy. Seeds can have dynamic traits potentially influenced by the Alchemy process and user's Aura at the time of creation. Seeds might also have a "vitality" trait that can be maintained (repaired).
5.  **Treasury:** A community pool accumulating small fees or direct contributions.

**Advanced/Creative/Trendy Concepts Used:**

*   **Decaying Reputation:** Aura score isn't static; it diminishes over time, requiring active engagement.
*   **Resource Sinks:** Alchemy consumes both staked tokens (locked during process) and *burned* (committed/spent) Aura. Seed repair also consumes resources.
*   **Probabilistic Outcome & Dynamic Traits:** Alchemy success and resulting Seed traits involve pseudo-random elements influenced by user state (Aura).
*   **Internal State Driven NFTs:** Seed traits are determined by on-chain factors during minting.
*   **Staking for Non-Monetary Reward:** While staking locks value, the primary direct reward is non-transferable Aura, used for utility within the protocol (Alchemy).
*   **Simplified Role-Based Access Control:** Basic admin roles for setting core parameters.

---

**Contract Outline & Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: This contract is a conceptual example.
// For production use, proper security audits,
// robust external dependencies (like Chainlink VRF for true randomness),
// and gas optimizations would be essential.

// --- Contract: AuraNexus ---
// A protocol centered around staking NXS token to earn decaying Aura reputation,
// which is used in an "Alchemy" process to generate dynamic "Seed" NFTs.

// --- State Variables ---
// - NXS token state (balance, total supply, allowances)
// - Staking state (staked amounts, time of last stake/unstake)
// - Aura state (current calculated Aura score, time of last Aura update)
// - Alchemy state (structs for ongoing processes, counter)
// - Seed state (ERC721-like owner tracking, Seed data including traits, total seeds)
// - Admin/Role state
// - Pausing state
// - Protocol Parameters (staking yield rate, aura decay rate, alchemy costs/probabilities, seed repair cost/effect)
// - Treasury state

// --- Modifiers ---
// - onlyAdmin: Restricts access to admin addresses.
// - whenNotPaused: Prevents execution when paused.
// - seedExists: Checks if a seed ID is valid.

// --- Events ---
// - NXSMinted: Token minting event.
// - Staked: User staked NXS.
// - Unstaked: User unstaked NXS.
// - AuraUpdated: User's Aura score was calculated/updated.
// - AlchemyInitiated: An alchemy process started.
// - AlchemyFinalized: An alchemy process completed (success/failure).
// - AlchemyCancelled: An alchemy process was cancelled.
// - SeedMinted: A new Seed NFT was created.
// - SeedTransfer: Seed NFT transferred (ERC721-like).
// - Approval: Seed NFT approval granted (ERC721-like).
// - ApprovalForAll: Seed NFT operator approval granted (ERC721-like).
// - SeedRepaired: A Seed's vitality was increased.
// - DepositedToTreasury: Funds added to treasury.
// - DistributedFromTreasury: Funds distributed from treasury.
// - AdminStatusChanged: Admin role granted/revoked.
// - Paused: Contract paused.
// - Unpaused: Contract unpaused.
// - ParametersUpdated: Generic event for parameter changes (could be more specific).
// - AuraDelegated: User delegated Aura.
// - AuraUndelegated: User undelegated Aura.

// --- Functions ---

// --- NXS Token (Simplified ERC-20 internal implementation for concept) ---
// 1. totalSupply() external view returns (uint256): Get total NXS supply.
// 2. balanceOf(address account) external view returns (uint256): Get NXS balance of an account.
// 3. transfer(address to, uint256 amount) external returns (bool): Transfer NXS.
// 4. allowance(address owner, address spender) external view returns (uint256): Get allowance.
// 5. approve(address spender, uint256 amount) external returns (bool): Set allowance.
// 6. transferFrom(address from, address to, uint256 amount) external returns (bool): Transfer NXS using allowance.
// (Note: Basic ERC20 functions included for completeness of the integrated token)

// --- Staking & Aura ---
// 7. setStakingSettings(uint256 yieldPerSecond, uint256 cooldownDuration) external onlyAdmin: Set staking parameters.
// 8. getStakingSettings() external view returns (uint256 yieldPerSecond, uint256 cooldownDuration): View staking parameters.
// 9. stake(uint256 amount) external whenNotPaused: Stake NXS to earn Aura.
// 10. unstake(uint256 amount) external whenNotPaused: Unstake NXS. Requires cooldown.
// 11. getStakedBalance(address account) external view returns (uint256): Get current staked NXS for an account.
// 12. getCurrentAura(address account) public view returns (uint256): Get calculated current Aura score considering decay.
// 13. setAuraDecayRate(uint256 decayPerSecond) external onlyAdmin: Set Aura decay rate.
// 14. getAuraDecayRate() external view returns (uint256): Get current Aura decay rate.
// 15. calculateAuraYield(address account, uint256 durationSeconds) external view returns (uint256): Estimate Aura yield from current stake over duration.

// --- Aura Delegation (Conceptual - does not affect score used for Alchemy in this version) ---
// 16. delegateAura(address delegatee) external whenNotPaused: Delegate Aura reputation to another address.
// 17. undelegateAura() external whenNotPaused: Remove Aura delegation.
// 18. getDelegatedAura(address account) external view returns (address): Get who an account has delegated their Aura to.

// --- Alchemy (Seed Generation) ---
// 19. setAlchemySettings(uint256 baseNxsCost, uint256 baseAuraCost, uint256 successProbabilityBasisPoints) external onlyAdmin: Set alchemy base parameters.
// 20. getAlchemySettings() external view returns (uint256 baseNxsCost, uint256 baseAuraCost, uint256 successProbabilityBasisPoints): View alchemy parameters.
// 21. initiateAlchemy(uint256 nxsToLock, uint256 auraToCommit) external whenNotPaused: Start a new alchemy process by locking NXS and committing Aura.
// 22. finalizeAlchemy(uint256 alchemyId) external whenNotPaused: Complete an alchemy process, potentially minting a Seed NFT based on probability and Aura.
// 23. cancelAlchemy(uint256 alchemyId) external whenNotPaused: Cancel an ongoing alchemy process (might incur penalty).
// 24. getAlchemyStatus(uint256 alchemyId) external view returns (uint8 status, address owner, uint256 nxsLocked, uint256 auraCommitted): Get details of an alchemy process.
// 25. getPendingAlchemy(address account) external view returns (uint256[] memory): Get list of alchemy IDs pending for an account.

// --- Seed (Dynamic ERC-721-like) ---
// 26. getSeedTraits(uint256 seedId) external view seedExists returns (uint256 affinity, uint256 potency, uint256 vitality): Get the dynamic traits of a Seed.
// 27. repairSeed(uint256 seedId) external whenNotPaused seedExists: Use NXS to increase a Seed's vitality.
// 28. setSeedRepairCost(uint256 cost, uint256 vitalityBoost) external onlyAdmin: Set parameters for seed repair.
// 29. getSeedRepairCost() external view returns (uint256 cost, uint256 vitalityBoost): View seed repair parameters.
// 30. ownerOf(uint256 seedId) public view returns (address): Get owner of a Seed (ERC721-like).
// 31. transferFrom(address from, address to, uint256 seedId) public whenNotPaused seedExists: Transfer Seed (ERC721-like).
// 32. approve(address to, uint256 seedId) public whenNotPaused seedExists: Approve transfer for a specific Seed (ERC721-like).
// 33. getApproved(uint256 seedId) public view seedExists returns (address): Get approved address for a Seed (ERC721-like).
// 34. setApprovalForAll(address operator, bool approved) public whenNotPaused: Set operator approval for all Seeds (ERC721-like).
// 35. isApprovedForAll(address owner, address operator) public view returns (bool): Check operator approval (ERC721-like).
// 36. getTokenUri(uint256 seedId) external view seedExists returns (string memory): Get metadata URI for a Seed (ERC721 hook).
// 37. totalSupplySeeds() external view returns (uint256): Get total number of Seeds minted.

// --- Treasury ---
// 38. depositToTreasury(uint256 amount) external whenNotPaused: Deposit NXS to the treasury.
// 39. getTreasuryBalance() external view returns (uint256): Get current NXS balance in the treasury.
// 40. distributeFromTreasury(address recipient, uint256 amount) external onlyAdmin: Distribute NXS from the treasury.

// --- Admin & Control ---
// 41. setAdmin(address account, bool status) external onlyAdmin: Grant or revoke admin status.
// 42. isAdmin(address account) external view returns (bool): Check admin status.
// 43. pause() external onlyAdmin: Pause contract functionality.
// 44. unpause() external onlyAdmin: Unpause contract functionality.
// 45. paused() external view returns (bool): Check if the contract is paused.

```

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Using interface for clarity, actual impl is internal
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Using interface for clarity, actual impl is internal
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // Using interface for clarity
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial admin simplicity
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max
import "@openzeppelin/contracts/utils/Counters.sol"; // For seed IDs

// Note: This contract is a conceptual example demonstrating features.
// For production use, it would require significant hardening,
// gas optimization, and potentially external components like Chainlink VRF
// for secure random number generation. The pseudo-randomness used here
// is for illustration only and is not secure.

contract AuraNexus is Ownable {
    using Counters for Counters.Counter;

    // --- NXS Token State (Simplified Internal ERC-20) ---
    mapping(address => uint256) private _nxsBalances;
    mapping(address => mapping(address => uint256)) private _nxsAllowances;
    uint256 private _nxsTotalSupply;
    event NXS Minted(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value); // ERC-20 Event
    event Approval(address indexed owner, address indexed spender, uint256 value); // ERC-20 Event

    // --- Staking & Aura State ---
    mapping(address => uint256) private _stakedBalances;
    mapping(address => uint256) private _lastStakeUpdateTime; // For yield calculation
    uint256 private _stakingYieldPerSecond; // NXS stake -> Aura yield rate
    uint256 private _stakingCooldownDuration = 0; // Time user must wait after unstake request

    mapping(address => uint256) private _auraScores; // Raw Aura score before decay
    mapping(address => uint256) private _lastAuraUpdateTime; // For decay calculation
    uint256 private _auraDecayPerSecond; // Rate at which Aura decays

    event Staked(address indexed account, uint256 amount, uint256 newStakedBalance);
    event Unstaked(address indexed account, uint256 amount, uint256 newStakedBalance);
    event AuraUpdated(address indexed account, uint256 oldAura, uint256 newAura);

    // --- Aura Delegation State (Conceptual) ---
    // Maps delegator => delegatee.
    // In this version, this mapping is stored but not actively used in Aura calculations
    // for core mechanics like Alchemy, serving as a placeholder for future features.
    mapping(address => address) private _auraDelegations;
    event AuraDelegated(address indexed delegator, address indexed delegatee);
    event AuraUndelegated(address indexed delegator, address indexed oldDelegatee);

    // --- Alchemy State ---
    enum AlchemyStatus { Invalid, Initiated, FinalizedSuccess, FinalizedFailure, Cancelled }

    struct AlchemyProcess {
        address owner;
        uint256 nxsLocked;
        uint256 auraCommitted;
        uint256 startTime;
        AlchemyStatus status;
        uint256 mintedSeedId; // 0 if no seed minted or failed
    }

    Counters.Counter private _alchemyIdCounter;
    mapping(uint256 => AlchemyProcess) private _alchemyProcesses;
    mapping(address => uint256[]) private _userAlchemyProcesses; // Track active/pending processes per user

    uint256 private _alchemyBaseNxsCost;
    uint256 private _alchemyBaseAuraCost;
    uint256 private _alchemySuccessProbabilityBasisPoints; // 0-10000 (0% to 100%)

    event AlchemyInitiated(uint256 indexed alchemyId, address indexed owner, uint256 nxsLocked, uint256 auraCommitted);
    event AlchemyFinalized(uint256 indexed alchemyId, address indexed owner, AlchemyStatus status, uint256 mintedSeedId);
    event AlchemyCancelled(uint256 indexed alchemyId, address indexed owner, uint256 nxsRefunded);

    // --- Seed State (Dynamic ERC-721-like) ---
    struct SeedData {
        uint256 affinity; // Trait 1 (e.g., 0-100)
        uint256 potency;  // Trait 2 (e.g., 0-100)
        uint256 vitality; // Trait 3 (decays, can be repaired)
        uint256 mintedTime; // For vitality decay calculation
    }

    Counters.Counter private _seedIdCounter;
    mapping(uint256 => address) private _seedOwners; // SeedId => Owner Address
    mapping(uint256 => address) private _seedApprovals; // SeedId => Approved Address
    mapping(address => mapping(address => bool)) private _seedOperatorApprovals; // Owner => Operator => Approved

    mapping(uint256 => SeedData) private _seedData; // SeedId => SeedData

    uint256 private _seedRepairCostNxs; // NXS cost to repair vitality
    uint256 private _seedRepairVitalityBoost; // How much vitality increases per repair

    event SeedMinted(uint256 indexed seedId, address indexed owner, uint256 indexed alchemyId, uint256 affinity, uint256 potency, uint256 vitality);
    event SeedRepaired(uint256 indexed seedId, address indexed owner, uint256 oldVitality, uint256 newVitality);

    // --- Treasury State ---
    address public constant TREASURY_ADDRESS = address(this); // Treasury is the contract itself
    event DepositedToTreasury(address indexed account, uint256 amount);
    event DistributedFromTreasury(address indexed recipient, uint256 amount);

    // --- Admin & Control State ---
    mapping(address => bool) private _admins;
    bool private _paused = false;

    event AdminStatusChanged(address indexed account, bool status);
    event Paused(address account);
    event Unpaused(address account);
    event ParametersUpdated(string paramName); // Generic event for parameter changes

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(_admins[msg.sender], "AuraNexus: Not an admin");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "AuraNexus: Paused");
        _;
    }

    modifier seedExists(uint256 seedId) {
        require(_seedOwners[seedId] != address(0), "AuraNexus: Seed does not exist");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialNxsSupply) Ownable(msg.sender) {
        // Mint initial supply of NXS to the contract creator (or a specified address)
        _nxsTotalSupply = initialNxsSupply;
        _nxsBalances[msg.sender] = initialNxsSupply;
        emit NXS Minted(msg.sender, initialNxsSupply);
        emit Transfer(address(0), msg.sender, initialNxsSupply);

        // Set deployer as initial admin
        _admins[msg.sender] = true;
        emit AdminStatusChanged(msg.sender, true);

        // Set initial parameters (example values)
        _stakingYieldPerSecond = 10; // Example: 10 Aura per NXS staked per second
        _auraDecayPerSecond = 1;     // Example: 1 Aura decay per second
        _alchemyBaseNxsCost = 100 * (10**18); // Example: 100 NXS base cost
        _alchemyBaseAuraCost = 1000;         // Example: 1000 Aura base cost
        _alchemySuccessProbabilityBasisPoints = 6000; // Example: 60% base success rate
        _seedRepairCostNxs = 50 * (10**18);  // Example: 50 NXS to repair
        _seedRepairVitalityBoost = 50;       // Example: +50 vitality per repair
    }

    // --- Internal Helpers ---

    // @dev Calculates current Aura score considering decay and staking yield
    function _calculateCurrentAura(address account) internal view returns (uint256) {
        uint256 currentRawAura = _auraScores[account];
        uint256 lastAuraUpdate = _lastAuraUpdateTime[account];
        uint256 stakedNxs = _stakedBalances[account];
        uint256 lastStakeUpdate = _lastStakeUpdateTime[account];

        uint256 timeElapsed = block.timestamp - lastAuraUpdate;
        uint256 timeStaked = block.timestamp - lastStakeUpdate;

        // Calculate earned Aura from staking since last update
        // Note: This yield calculation is simplified. A more complex model might track stake duration.
        uint256 earnedAura = stakedNxs > 0 ? (stakedNxs * _stakingYieldPerSecond * timeStaked) : 0;

        // Apply decay
        uint256 decayedAura = currentRawAura > 0 ? Math.min(currentRawAura, timeElapsed * _auraDecayPerSecond) : 0;

        // The effective current Aura is raw + earned - decayed. Cannot go below 0.
        // Ensure raw score doesn't go below decayed amount before adding earned.
        // A safer approach is to update the raw score when accessed.
        return Math.max(0, currentRawAura + earnedAura - decayedAura);
    }

    // @dev Updates the raw Aura score and the last update timestamp
    function _updateAuraScore(address account, uint256 newRawAura) internal {
        uint256 oldAura = getCurrentAura(account); // Calculate current before update
        _auraScores[account] = newRawAura;
        _lastAuraUpdateTime[account] = block.timestamp;
        _lastStakeUpdateTime[account] = block.timestamp; // Reset stake time as well for yield calc continuity
        emit AuraUpdated(account, oldAura, getCurrentAura(account)); // Emit with calculated current
    }

    // @dev Pseudo-random number generation (NOT secure for critical applications)
    function _generatePseudoRandom(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
    }

    // --- NXS Token Functions (Simplified ERC-20) ---
    // Note: These are simplified internal implementations for the contract's native token.
    // A real application might use a separate, standard ERC20 contract.

    function totalSupply() external view returns (uint256) {
        return _nxsTotalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == TREASURY_ADDRESS) {
            // Treasury balance is the contract's own balance excluding staked NXS
            return _nxsBalances[TREASURY_ADDRESS] - _stakedBalances[TREASURY_ADDRESS]; // Simple model assumes contract holds staked funds
        }
        return _nxsBalances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _nxsAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _nxsAllowances[from][msg.sender];
        require(currentAllowance >= amount, "AuraNexus: transfer amount exceeds allowance");
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "AuraNexus: transfer from the zero address");
        require(to != address(0), "AuraNexus: transfer to the zero address");

        uint256 fromBalance = _nxsBalances[from];
        require(fromBalance >= amount, "AuraNexus: transfer amount exceeds balance");

        unchecked {
            _nxsBalances[from] = fromBalance - amount;
            _nxsBalances[to] = _nxsBalances[to] + amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "AuraNexus: mint to the zero address");
        _nxsTotalSupply += amount;
        _nxsBalances[account] += amount;
        emit NXS Minted(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "AuraNexus: burn from the zero address");
        uint256 accountBalance = _nxsBalances[account];
        require(accountBalance >= amount, "AuraNexus: burn amount exceeds balance");
        unchecked {
            _nxsBalances[account] = accountBalance - amount;
        }
        _nxsTotalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "AuraNexus: approve from the zero address");
        require(spender != address(0), "AuraNexus: approve to the zero address");
        _nxsAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- Staking & Aura Functions ---

    function setStakingSettings(uint256 yieldPerSecond, uint256 cooldownDuration) external onlyAdmin {
        _stakingYieldPerSecond = yieldPerSecond;
        _stakingCooldownDuration = cooldownDuration;
        emit ParametersUpdated("StakingSettings");
    }

    function getStakingSettings() external view returns (uint256 yieldPerSecond, uint256 cooldownDuration) {
        return (_stakingYieldPerSecond, _stakingCooldownDuration);
    }

    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "AuraNexus: Stake amount must be > 0");
        _transfer(msg.sender, address(this), amount); // Transfer NXS to contract

        uint256 currentStaked = _stakedBalances[msg.sender];
        uint256 currentAura = getCurrentAura(msg.sender); // Capture current Aura before update

        _stakedBalances[msg.sender] += amount;
        _lastStakeUpdateTime[msg.sender] = block.timestamp; // Reset staking yield timer

        // Update Aura score based on yield earned since last update and apply decay
        uint256 rawAura = _auraScores[msg.sender];
        uint256 timeElapsed = block.timestamp - _lastAuraUpdateTime[msg.sender];
        uint256 decayedAura = rawAura > 0 ? Math.min(rawAura, timeElapsed * _auraDecayPerSecond) : 0;
        // Staking increases the raw score directly for immediate boost consideration
        _auraScores[msg.sender] = rawAura - decayedAura; // Apply decay to raw score first
        _lastAuraUpdateTime[msg.sender] = block.timestamp; // Reset Aura decay timer

        emit Staked(msg.sender, amount, _stakedBalances[msg.sender]);
        emit AuraUpdated(msg.sender, currentAura, getCurrentAura(msg.sender));
    }

    function unstake(uint256 amount) external whenNotPaused {
        require(amount > 0, "AuraNexus: Unstake amount must be > 0");
        uint256 currentStaked = _stakedBalances[msg.sender];
        require(currentStaked >= amount, "AuraNexus: Insufficient staked balance");

        // Simple cooldown check (could be more complex, e.g., per-unstake cooldown)
        // For simplicity here, we just check the last stake update time.
        // A more robust version would track specific unstake requests.
        // uint256 timeSinceLastStakeUpdate = block.timestamp - _lastStakeUpdateTime[msg.sender];
        // require(timeSinceLastStakeUpdate >= _stakingCooldownDuration, "AuraNexus: Staking cooldown active");
        // NOTE: The above simple cooldown on _lastStakeUpdateTime is flawed if stake() is called multiple times.
        // A proper cooldown requires tracking time since last *unstake* or specific cooldown entry.
        // For *this* concept contract, we'll omit the strict cooldown check on _lastStakeUpdateTime for simplicity,
        // but acknowledge this is a simplification.

        uint256 currentAura = getCurrentAura(msg.sender); // Capture current Aura before update

        // Update Aura score based on yield earned and apply decay before reducing stake
        uint256 rawAura = _auraScores[msg.sender];
        uint256 timeElapsed = block.timestamp - _lastAuraUpdateTime[msg.sender];
        uint256 decayedAura = rawAura > 0 ? Math.min(rawAura, timeElapsed * _auraDecayPerSecond) : 0;
        _auraScores[msg.sender] = rawAura - decayedAura; // Apply decay to raw score
        _lastAuraUpdateTime[msg.sender] = block.timestamp; // Reset Aura decay timer
        _lastStakeUpdateTime[msg.sender] = block.timestamp; // Reset stake yield timer as stake changes

        _stakedBalances[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount); // Transfer NXS back to user

        emit Unstaked(msg.sender, amount, _stakedBalances[msg.sender]);
        emit AuraUpdated(msg.sender, currentAura, getCurrentAura(msg.sender));
    }

    function getStakedBalance(address account) external view returns (uint256) {
        return _stakedBalances[account];
    }

    function getCurrentAura(address account) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - _lastAuraUpdateTime[account];
        uint256 timeStaked = block.timestamp - _lastStakeUpdateTime[account];

        uint256 rawAura = _auraScores[account];
        uint256 earnedAura = _stakedBalances[account] > 0 ? (_stakedBalances[account] * _stakingYieldPerSecond * timeStaked) : 0;
        uint256 decayedAura = rawAura > 0 ? Math.min(rawAura, timeElapsed * _auraDecayPerSecond) : 0;

        // Return the *calculated* current effective Aura
        return Math.max(0, rawAura + earnedAura - decayedAura);
    }

    function setAuraDecayRate(uint256 decayPerSecond) external onlyAdmin {
        _auraDecayPerSecond = decayPerSecond;
        emit ParametersUpdated("AuraDecayRate");
    }

    function getAuraDecayRate() external view returns (uint256) {
        return _auraDecayPerSecond;
    }

    function calculateAuraYield(address account, uint256 durationSeconds) external view returns (uint256) {
        uint256 stakedNxs = _stakedBalances[account];
        if (stakedNxs == 0 || durationSeconds == 0) {
            return 0;
        }
        // Simplified calculation: yield rate * stake * duration
        // Does NOT account for decay or changes in stake during the duration.
        // This is an *estimation*.
        return stakedNxs * _stakingYieldPerSecond * durationSeconds;
    }

    // --- Aura Delegation Functions ---

    function delegateAura(address delegatee) external whenNotPaused {
        require(delegatee != address(0), "AuraNexus: Cannot delegate to zero address");
        require(delegatee != msg.sender, "AuraNexus: Cannot delegate to self");
        _auraDelegations[msg.sender] = delegatee;
        emit AuraDelegated(msg.sender, delegatee);
    }

    function undelegateAura() external whenNotPaused {
        address oldDelegatee = _auraDelegations[msg.sender];
        require(oldDelegatee != address(0), "AuraNexus: No active delegation to remove");
        _auraDelegations[msg.sender] = address(0);
        emit AuraUndelegated(msg.sender, oldDelegatee);
    }

    function getDelegatedAura(address account) external view returns (address) {
        return _auraDelegations[account];
    }


    // --- Alchemy Functions ---

    function setAlchemySettings(uint256 baseNxsCost, uint256 baseAuraCost, uint256 successProbabilityBasisPoints) external onlyAdmin {
        _alchemyBaseNxsCost = baseNxsCost;
        _alchemyBaseAuraCost = baseAuraCost;
        require(successProbabilityBasisPoints <= 10000, "AuraNexus: Probability cannot exceed 100%");
        _alchemySuccessProbabilityBasisPoints = successProbabilityBasisPoints;
        emit ParametersUpdated("AlchemySettings");
    }

    function getAlchemySettings() external view returns (uint256 baseNxsCost, uint256 baseAuraCost, uint256 successProbabilityBasisPoints) {
        return (_alchemyBaseNxsCost, _alchemyBaseAuraCost, _alchemySuccessProbabilityBasisPoints);
    }

    function initiateAlchemy(uint256 nxsToLock, uint256 auraToCommit) external whenNotPaused {
        require(nxsToLock > 0 || auraToCommit > 0, "AuraNexus: Must commit NXS or Aura");
        require(_stakedBalances[msg.sender] >= nxsToLock, "AuraNexus: Not enough staked NXS");
        uint256 currentAura = getCurrentAura(msg.sender);
        require(currentAura >= auraToCommit, "AuraNexus: Not enough Aura");

        // Lock NXS (simply reduce staked balance, keep track of locked amount)
        _stakedBalances[msg.sender] -= nxsToLock;

        // Consume Aura (reduce raw Aura score)
        // Must update raw score first by applying decay
        uint256 rawAura = _auraScores[msg.sender];
        uint256 timeElapsed = block.timestamp - _lastAuraUpdateTime[msg.sender];
        uint256 decayedAura = rawAura > 0 ? Math.min(rawAura, timeElapsed * _auraDecayPerSecond) : 0;
        uint256 rawAuraAfterDecay = rawAura - decayedAura;

        require(rawAuraAfterDecay >= auraToCommit, "AuraNexus: Not enough Aura after decay for commitment"); // Double check after decay calc
        _auraScores[msg.sender] = rawAuraAfterDecay - auraToCommit; // Reduce raw score by committed amount
        _lastAuraUpdateTime[msg.sender] = block.timestamp; // Reset Aura decay timer
         _lastStakeUpdateTime[msg.sender] = block.timestamp; // Reset stake timer as staked balance changed

        // Create Alchemy Process entry
        _alchemyIdCounter.increment();
        uint256 newAlchemyId = _alchemyIdCounter.current();

        _alchemyProcesses[newAlchemyId] = AlchemyProcess({
            owner: msg.sender,
            nxsLocked: nxsToLock,
            auraCommitted: auraToCommit,
            startTime: block.timestamp,
            status: AlchemyStatus.Initiated,
            mintedSeedId: 0
        });

        _userAlchemyProcesses[msg.sender].push(newAlchemyId);

        emit AlchemyInitiated(newAlchemyId, msg.sender, nxsToLock, auraToCommit);
        emit AuraUpdated(msg.sender, currentAura, getCurrentAura(msg.sender)); // Emit Aura update event
    }

    function finalizeAlchemy(uint256 alchemyId) external whenNotPaused {
        AlchemyProcess storage process = _alchemyProcesses[alchemyId];
        require(process.status == AlchemyStatus.Initiated, "AuraNexus: Alchemy not in initiated state");
        require(process.owner == msg.sender, "AuraNexus: Not the owner of this alchemy process");

        // Calculate success probability based on parameters and user's Aura
        // Higher Aura -> higher probability (example logic)
        uint256 currentAura = getCurrentAura(msg.sender); // Use calculated current Aura
        uint256 baseProb = _alchemySuccessProbabilityBasisPoints;
        // Example: Add 1 basis point per 100 Aura beyond base cost
        uint256 auraBonusProb = currentAura > _alchemyBaseAuraCost ? (currentAura - _alchemyBaseAuraCost) / 100 : 0;
        uint256 finalProb = Math.min(10000, baseProb + auraBonusProb); // Cap probability at 100%

        // Pseudo-random outcome (UNSECURE - use Chainlink VRF for production)
        uint256 randomValue = _generatePseudoRandom(alchemyId);
        uint256 roll = randomValue % 10001; // Roll between 0 and 10000

        bool success = roll <= finalProb;

        if (success) {
            // Success: Mint a Seed NFT
            _seedIdCounter.increment();
            uint256 newSeedId = _seedIdCounter.current();

            // Determine Seed traits based on process inputs and Aura (example logic)
            uint256 affinity = (process.auraCommitted + process.nxsLocked) % 101; // Max 100
            uint256 potency = (currentAura / 100) % 101; // Max 100, scaled by Aura
            uint256 vitality = 100; // Start with max vitality

            _seedOwners[newSeedId] = msg.sender;
            _seedData[newSeedId] = SeedData({
                affinity: affinity,
                potency: potency,
                vitality: vitality,
                mintedTime: block.timestamp
            });

            process.status = AlchemyStatus.FinalizedSuccess;
            process.mintedSeedId = newSeedId;

            // NXS locked in process goes to treasury (example fee)
            // Alternatively, it could be burned or partly returned.
            _nxsBalances[TREASURY_ADDRESS] += process.nxsLocked; // Transfer from contract balance
            emit DepositedToTreasury(address(this), process.nxsLocked);

            emit AlchemyFinalized(alchemyId, msg.sender, AlchemyStatus.FinalizedSuccess, newSeedId);
            emit SeedMinted(newSeedId, msg.sender, alchemyId, affinity, potency, vitality);

        } else {
            // Failure: Lose committed Aura (already consumed) and potentially some NXS locked
            // Example: 50% of locked NXS is lost (goes to treasury), 50% returned to staked balance.
            uint256 nxsRefunded = process.nxsLocked / 2;
            uint256 nxsToTreasury = process.nxsLocked - nxsRefunded;

            _stakedBalances[msg.sender] += nxsRefunded; // Return NXS to staked balance

            _nxsBalances[TREASURY_ADDRESS] += nxsToTreasury; // Transfer lost NXS to treasury
            emit DepositedToTreasury(address(this), nxsToTreasury);

            process.status = AlchemyStatus.FinalizedFailure;
            process.mintedSeedId = 0; // Indicate no seed minted

            emit AlchemyFinalized(alchemyId, msg.sender, AlchemyStatus.FinalizedFailure, 0);
            emit Staked(msg.sender, nxsRefunded, _stakedBalances[msg.sender]); // Emit staked event for refund
        }

        // Remove alchemy ID from user's pending list (simple implementation)
        _removeAlchemyIdForUser(msg.sender, alchemyId);
    }

    function cancelAlchemy(uint256 alchemyId) external whenNotPaused {
        AlchemyProcess storage process = _alchemyProcesses[alchemyId];
        require(process.status == AlchemyStatus.Initiated, "AuraNexus: Alchemy not in initiated state");
        require(process.owner == msg.sender, "AuraNexus: Not the owner of this alchemy process");

        // Cancellation penalty: Lose committed Aura (already consumed), 80% of NXS locked is returned
        uint256 nxsRefunded = (process.nxsLocked * 80) / 100;
        uint256 nxsToTreasury = process.nxsLocked - nxsRefunded;

        _stakedBalances[msg.sender] += nxsRefunded; // Return NXS to staked balance

        _nxsBalances[TREASURY_ADDRESS] += nxsToTreasury; // Transfer penalty to treasury
        emit DepositedToTreasury(address(this), nxsToTreasury);

        process.status = AlchemyStatus.Cancelled;
        process.mintedSeedId = 0; // Indicate no seed minted

        emit AlchemyCancelled(alchemyId, msg.sender, nxsRefunded);
        emit Staked(msg.sender, nxsRefunded, _stakedBalances[msg.sender]); // Emit staked event for refund

         // Remove alchemy ID from user's pending list
        _removeAlchemyIdForUser(msg.sender, alchemyId);
    }

    function getAlchemyStatus(uint256 alchemyId) external view returns (uint8 status, address owner, uint256 nxsLocked, uint256 auraCommitted) {
        AlchemyProcess storage process = _alchemyProcesses[alchemyId];
        return (uint8(process.status), process.owner, process.nxsLocked, process.auraCommitted);
    }

     function getPendingAlchemy(address account) external view returns (uint256[] memory) {
        return _userAlchemyProcesses[account];
    }

    // Helper to remove alchemy ID from user's array (simple but potentially gas-inefficient for large arrays)
    function _removeAlchemyIdForUser(address account, uint256 alchemyId) internal {
        uint256[] storage pending = _userAlchemyProcesses[account];
        for (uint i = 0; i < pending.length; i++) {
            if (pending[i] == alchemyId) {
                pending[i] = pending[pending.length - 1];
                pending.pop();
                break;
            }
        }
    }

    // --- Seed Functions (Dynamic ERC-721-like) ---

    function getSeedTraits(uint256 seedId) external view seedExists returns (uint256 affinity, uint256 potency, uint256 vitality) {
        SeedData storage data = _seedData[seedId];
        // Calculate current vitality considering decay
        uint256 timeElapsed = block.timestamp - data.mintedTime;
        uint256 vitalityDecay = timeElapsed / (24 * 3600); // Example: 1 vitality decay per day
        uint256 currentVitality = data.vitality > vitalityDecay ? data.vitality - vitalityDecay : 0;

        return (data.affinity, data.potency, currentVitality);
    }

    function repairSeed(uint256 seedId) external whenNotPaused seedExists {
        require(_seedOwners[seedId] == msg.sender, "AuraNexus: Not the owner of this Seed");
        require(_nxsBalances[msg.sender] >= _seedRepairCostNxs, "AuraNexus: Not enough NXS to repair");

        SeedData storage data = _seedData[seedId];
        uint256 oldVitality = data.vitality;

        // Update vitality considering decay before boosting
        uint256 timeElapsed = block.timestamp - data.mintedTime;
        uint256 vitalityDecay = timeElapsed / (24 * 3600);
        data.vitality = data.vitality > vitalityDecay ? data.vitality - vitalityDecay : 0;

        // Boost vitality, capped at 100
        data.vitality = Math.min(100, data.vitality + _seedRepairVitalityBoost);
        data.mintedTime = block.timestamp; // Reset vitality decay timer

        _transfer(msg.sender, TREASURY_ADDRESS, _seedRepairCostNxs); // Transfer NXS cost to treasury
        emit DepositedToTreasury(msg.sender, _seedRepairCostNxs);

        emit SeedRepaired(seedId, msg.sender, oldVitality, data.vitality);
    }

    function setSeedRepairCost(uint256 cost, uint256 vitalityBoost) external onlyAdmin {
        _seedRepairCostNxs = cost;
        _seedRepairVitalityBoost = vitalityBoost;
         emit ParametersUpdated("SeedRepairCost");
    }

    function getSeedRepairCost() external view returns (uint256 cost, uint256 vitalityBoost) {
        return (_seedRepairCostNxs, _seedRepairVitalityBoost);
    }

    // ERC-721 like minimal implementation
    function ownerOf(uint256 seedId) public view returns (address) {
         address owner = _seedOwners[seedId];
         require(owner != address(0), "AuraNexus: Seed does not exist");
         return owner;
    }

    function transferFrom(address from, address to, uint256 seedId) public whenNotPaused seedExists {
        require(_isApprovedOrOwner(msg.sender, seedId), "AuraNexus: Transfer not authorized");
        require(from == _seedOwners[seedId], "AuraNexus: From address is not owner");
        require(to != address(0), "AuraNexus: Transfer to the zero address");

        _transferSeed(from, to, seedId);
    }

    function approve(address to, uint256 seedId) public whenNotPaused seedExists {
        address owner = _seedOwners[seedId];
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "AuraNexus: Approval not authorized");
        _approveSeed(to, seedId);
    }

    function getApproved(uint256 seedId) public view seedExists returns (address) {
        return _seedApprovals[seedId];
    }

    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        require(operator != msg.sender, "AuraNexus: Cannot approve self as operator");
        _seedOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _seedOperatorApprovals[owner][operator];
    }

    // Internal Seed transfer logic
    function _transferSeed(address from, address to, uint256 seedId) internal {
        require(from == _seedOwners[seedId], "AuraNexus: From address is not owner");

        // Clear approval for the transferred token
        _approveSeed(address(0), seedId);

        _seedOwners[seedId] = to;

        // Note: ERC721Enumerable usually tracks owned tokens per user here.
        // For simplicity, we'll skip that and provide a helper `getSeedsOwnedBy` later.

        emit Transfer(from, to, seedId); // ERC-721 Transfer event
    }

    // Internal Seed approval logic
    function _approveSeed(address to, uint256 seedId) internal {
        _seedApprovals[seedId] = to;
        emit Approval(_seedOwners[seedId], to, seedId); // ERC-721 Approval event
    }

    // Helper to check if caller is approved or owner
    function _isApprovedOrOwner(address spender, uint256 seedId) internal view returns (bool) {
        address owner = _seedOwners[seedId];
        return (spender == owner || getApproved(seedId) == spender || isApprovedForAll(owner, spender));
    }

    // ERC721Metadata hook (simplified)
    function getTokenUri(uint256 seedId) external view seedExists returns (string memory) {
        // In a real scenario, this would return a URI pointing to a metadata JSON file.
        // The JSON could include the traits from getSeedTraits.
        // For this concept, we return a placeholder indicating the Seed ID.
        string memory baseURI = "ipfs://aura-nexus/seed/"; // Example base URI
        return string(abi.encodePacked(baseURI, Strings.toString(seedId)));
    }

    function totalSupplySeeds() external view returns (uint256) {
        return _seedIdCounter.current();
    }

     // Helper (potentially gas-inefficient for many tokens)
     // In a production ERC721Enumerable, this would be handled by indexed token lists.
     // This version requires iterating through all possible IDs.
    function getSeedsOwnedBy(address account) external view returns (uint256[] memory) {
        uint256 total = _seedIdCounter.current();
        uint256[] memory ownedSeeds = new uint256[](total); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (_seedOwners[i] == account) {
                ownedSeeds[count] = i;
                count++;
            }
        }
        // Trim the array to the actual number of owned tokens
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = ownedSeeds[i];
        }
        return result;
    }


    // --- Treasury Functions ---

    function depositToTreasury(uint256 amount) external whenNotPaused {
         require(amount > 0, "AuraNexus: Deposit amount must be > 0");
        _transfer(msg.sender, TREASURY_ADDRESS, amount);
        emit DepositedToTreasury(msg.sender, amount);
    }

    function getTreasuryBalance() external view returns (uint256) {
        // Treasury balance is the contract's balance minus staked tokens.
        // This is a simplified model where the contract holds staked funds.
        // A more complex model might use separate vaults.
        return _nxsBalances[TREASURY_ADDRESS] - _stakedBalances[TREASURY_ADDRESS];
    }

    function distributeFromTreasury(address recipient, uint256 amount) external onlyAdmin {
        require(recipient != address(0), "AuraNexus: Cannot distribute to zero address");
        uint256 treasuryBalance = getTreasuryBalance();
        require(treasuryBalance >= amount, "AuraNexus: Insufficient treasury balance");

        // Transfer directly from the contract's NXS balance (which represents treasury funds)
        _transfer(TREASURY_ADDRESS, recipient, amount); // Use internal transfer
        emit DistributedFromTreasury(recipient, amount);
    }

    // --- Admin & Control Functions ---

    function setAdmin(address account, bool status) external onlyAdmin {
        require(account != address(0), "AuraNexus: Cannot set zero address as admin");
        _admins[account] = status;
        emit AdminStatusChanged(account, status);
    }

    function isAdmin(address account) external view returns (bool) {
        return _admins[account];
    }

    function pause() external onlyAdmin {
        require(!_paused, "AuraNexus: Already paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyAdmin {
        require(_paused, "AuraNexus: Not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() external view returns (bool) {
        return _paused;
    }
}

// Simple helper library for converting uint256 to string (for metadata URI)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        unchecked {
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
    }
}
```