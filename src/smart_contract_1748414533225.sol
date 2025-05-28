Okay, let's craft a unique smart contract that combines elements of dynamic NFTs, fractionalization, yield farming, governance, and external data integration (via Chainlink VRF). We'll call it "Ethereal Shards".

The core idea is a fixed set of "Genesis Crystals" (like dynamic NFTs) that can be "shattered" into tradeable "Ethereal Shards" (like ERC-20 tokens). Shards represent fractional ownership and yield-earning potential from the pool of remaining, unshattered, or staked Crystals. Crystals themselves have dynamic properties updated via on-chain logic and randomness. Staking either Shards or Crystals provides different benefits. A governance mechanism allows Shard stakers to control key parameters.

This design touches upon:
*   **Dynamic NFTs:** Crystals changing properties.
*   **Fractionalization:** Shattering Crystals into Shards.
*   **Yield Farming:** Earning Shards by staking Shards.
*   **Staking (different asset):** Staking Crystals for different benefits/system participation.
*   **Governance:** Shard stakers control parameters.
*   **External Data:** Using Chainlink VRF for dynamic properties.
*   **Custom Logic:** Implementing core token/asset logic without inheriting full OpenZeppelin (to avoid direct duplication while acknowledging the standards).
*   **Gas Efficiency:** Some operations (like yield calculation) use pull patterns.

---

**Contract Name:** EtherealShards

**Concept:** A protocol centered around dynamic, fractionalized, and yield-generating assets. "Genesis Crystals" (unique, dynamic assets) can be shattered into "Ethereal Shards" (fungible tokens). Shards represent a claim on the protocol's value and yield. Staking Shards earns yield; staking Crystals enables dynamic updates via randomness and potentially boosts yield. Governance is based on staked Shards.

**Outline:**

1.  **State Variables:**
    *   General parameters (names, symbols, decimals).
    *   Crystal data (struct, mappings for ownership, properties, state).
    *   Shard data (mappings for balances, allowances, total supply).
    *   Staking data (mappings for staked balances, yield tracking, staked crystals).
    *   Yield parameters and tracking (rate, accumulated yield).
    *   Governance data (struct, mappings for proposals, voting, thresholds).
    *   VRF data (coordinator, key hash, subscription, request tracking).
    *   Pausable state.
    *   Owner/Governor addresses.
    *   Fee collector address.

2.  **Events:**
    *   Standard ERC-20/721-like events (Transfer, Approval).
    *   Crystal-specific events (CrystalMinted, CrystalShattered, CrystalPropertiesUpdated, CrystalStaked, CrystalUnstaked).
    *   Shard-specific events (ShardsStaked, ShardsUnstaked, YieldClaimed).
    *   Governance events (ProposalCreated, Voted, ProposalExecuted, ParameterChanged).
    *   VRF event (RandomnessRequested).
    *   Paused/Unpaused.

3.  **Modifiers:**
    *   `onlyOwner`
    *   `onlyGovernor`
    *   `whenNotPaused`
    *   `whenPaused`
    *   `onlyVRFCoordinator`

4.  **Structs:**
    *   `Crystal` (properties like purity, energy, last update time, state).
    *   `Proposal` (details, state, votes, calldata).

5.  **Enums:**
    *   `ProposalState` (Pending, Active, Succeeded, Failed, Executed).
    *   `CrystalState` (Minted, Shattered, Staked).

6.  **Functions (20+):**

    *   **Initialization/Setup:**
        *   `constructor`: Sets initial parameters, mints initial crystals to owner.
        *   `initializeGovernor`: Sets initial governor (can be same as owner, or a separate contract/multisig).
        *   `setFeeCollector`: Sets address for collected ETH fees.

    *   **Crystal Management (NFT-like):**
        *   `mintCrystal`: Callable by governor to mint new crystals (e.g., from a treasury).
        *   `getCrystal(uint256 crystalId)`: View crystal details.
        *   `getCrystalOwner(uint256 crystalId)`: Get current owner.
        *   `shatterCrystal(uint256 crystalId) payable`: Burn crystal, mint shards, collect ETH fee.
        *   `updateCrystalProperties(uint256 crystalId)`: Update properties based on time passing. Callable by anyone.
        *   `requestCrystalRandomUpdate(uint256 crystalId)`: Request VRF for a staked crystal. Caller pays VRF gas.
        *   `rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: VRF callback to apply randomness.

    *   **Shard Management (ERC-20-like):**
        *   `balanceOf(address account)`: Get shard balance.
        *   `transfer(address recipient, uint256 amount)`: Transfer shards (potentially with a dynamic fee).
        *   `approve(address spender, uint256 amount)`: Approve shard transfer.
        *   `transferFrom(address sender, address recipient, uint256 amount)`: Transfer approved shards (potentially with a dynamic fee).
        *   `allowance(address owner, address spender)`: Get allowance.
        *   `totalSupply()`: Get total shard supply.

    *   **Staking:**
        *   `stakeShards(uint256 amount)`: Stake shards to earn yield and gain voting power.
        *   `unstakeShards(uint256 amount)`: Unstake shards.
        *   `claimStakedShardYield()`: Claim accumulated shard yield.
        *   `calculatePendingShardYield(address account)`: View pending yield.
        *   `stakeCrystal(uint256 crystalId)`: Stake crystal (must own it, not shattered). Makes crystal eligible for randomness updates.
        *   `unstakeCrystal(uint256 crystalId)`: Unstake crystal.

    *   **Governance:**
        *   `submitProposal(string memory description, address target, bytes memory callData)`: Submit a proposal (requires minimum staked shards).
        *   `voteOnProposal(uint256 proposalId, bool support)`: Vote on a proposal using staked shard power.
        *   `queueAndExecuteProposal(uint256 proposalId)`: Execute a successful proposal after a timelock.
        *   `getProposalState(uint256 proposalId)`: View proposal state.
        *   `getProposalVoteCounts(uint256 proposalId)`: View vote counts.

    *   **Parameter Control (via Governance):**
        *   `setShardYieldRate(uint256 newRatePerSecond)`: Governable function to change yield rate.
        *   `setShatteringFeeRate(uint256 newFeeRate)`: Governable function to change fee rate applied during shattering.
        *   `setProposalThreshold(uint256 newThresholdBPS)`: Governable function to change minimum staked shard percentage needed to submit/pass proposals.
        *   `setVRFConfig(bytes32 keyHash, uint64 subscriptionId)`: Governable function to update VRF config.

    *   **Utility/Admin:**
        *   `pause()`: Governor can pause sensitive operations.
        *   `unpause()`: Governor can unpause.
        *   `withdrawETH()`: Governor can withdraw collected ETH fees.
        *   `getShatteringFeeRate()`: View current shattering fee rate.
        *   `getProposalThreshold()`: View current proposal threshold.
        *   `getTotalStakedShards()`: View total staked shards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Use interface for clarity, not inheritance
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Use interface for clarity, not inheritance
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Example Oracle interface if needed later, but focusing on VRF for dynamics

// --- Outline and Function Summary ---
//
// Contract: EtherealShards
// Concept: Dynamic, fractionalized, yield-generating assets with integrated governance and VRF-based dynamics.
//
// 1. State Variables: Stores all core data for Crystals, Shards, Staking, Governance, VRF, and parameters.
// 2. Events: Announces key actions (Mint, Shatter, Transfer, Stake, Vote, etc.).
// 3. Modifiers: Access control and state checks.
// 4. Structs: Data structures for Complex types (Crystal, Proposal).
// 5. Enums: Defines possible states (CrystalState, ProposalState).
// 6. Functions (37+ functions including getters for state visibility):
//    - Constructor: Initialize contract, mint initial crystals.
//    - Initialization/Setup: Set initial governor, fee collector.
//    - Crystal Management:
//      - mintCrystal: Create new crystals (governance).
//      - getCrystal: View full crystal data struct.
//      - getCrystalOwner: Get owner address.
//      - getCrystalPurity: Get purity property.
//      - getCrystalEnergy: Get energy property.
//      - getCrystalState: Get current state (Minted, Shattered, Staked).
//      - shatterCrystal: Destroy crystal, mint shards (payable ETH fee).
//      - updateCrystalProperties: Update properties based on time.
//      - requestCrystalRandomUpdate: Request randomness for a staked crystal (caller pays VRF gas).
//      - rawFulfillRandomWords: VRF callback to apply random properties.
//      - getVRFRequestIdForCrystal: Get request ID associated with a crystal update.
//    - Shard Management (ERC-20 like):
//      - name: Get shard name.
//      - symbol: Get shard symbol.
//      - decimals: Get shard decimals.
//      - balanceOf: Get shard balance.
//      - transfer: Transfer shards (includes dynamic fee logic).
//      - approve: Approve shard transfer.
//      - transferFrom: Transfer approved shards (includes dynamic fee logic).
//      - allowance: Get shard allowance.
//      - totalSupply: Get total shard supply.
//      - getShardTransferFeeRate: View current transfer fee rate.
//    - Staking:
//      - stakeShards: Stake shards for yield and voting power.
//      - unstakeShards: Unstake shards.
//      - claimStakedShardYield: Claim pending yield.
//      - calculatePendingShardYield: View pending yield.
//      - stakeCrystal: Stake a crystal (must own it, makes it eligible for VRF updates).
//      - unstakeCrystal: Unstake a crystal.
//      - getCrystalIsStaked: Check if a crystal is staked.
//      - getTotalStakedShards: View total staked shards.
//      - getStakedShards: View staked shards for an account.
//    - Governance:
//      - submitProposal: Create a new governance proposal (requires staked shards).
//      - voteOnProposal: Cast vote on a proposal.
//      - queueAndExecuteProposal: Execute a successful proposal.
//      - getProposal: View full proposal data struct.
//      - getProposalState: View proposal state.
//      - getProposalVoteCounts: View proposal vote counts.
//      - getProposalThreshold: View current proposal threshold.
//      - hasVoted: Check if an account has voted on a proposal.
//    - Parameter Control (via Governance):
//      - setShardYieldRate: Set yield rate (governance).
//      - setShatteringFeeRate: Set shattering fee rate (governance).
//      - setProposalThreshold: Set proposal threshold (governance).
//      - setVRFConfig: Set VRF parameters (governance).
//      - setQuorumThreshold: Set proposal quorum (governance).
//    - Utility/Admin:
//      - pause: Pause sensitive operations (governor).
//      - unpause: Unpause operations (governor).
//      - withdrawETH: Withdraw collected ETH fees (governor).
//
// Advanced Concepts:
// - Dynamic Properties: Crystals update based on time and VRF.
// - Fractionalization: Shattering process converts unique asset to fungible tokens.
// - Yield Farming: Shard staking with yield calculation (pull-based).
// - Dual Staking: Separate staking mechanisms for Shards and Crystals with different roles.
// - Integrated Governance: On-chain proposal and voting system based on staked Shards.
// - Chainlink VRF: Secure on-chain randomness for dynamic properties.
// - Custom Token Logic: Implementing ERC-20/721-like behaviour directly vs. inheritance to demonstrate understanding and allow custom modifications (like transfer fees).
// - Pausability: Emergency stop mechanism.
// - Fee Collection: Handling native token fees.

// --- Contract Code ---

// Libraries or interfaces might be imported here if needed, e.g., SafeMath (though 0.8+ handles overflow), IERC20, IERC721 etc.
// For uniqueness, we define structs and basic mappings instead of inheriting standard OpenZeppelin implementations directly.

interface IVRFCoordinatorV2 {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint32 requestConfirmations,
        uint32 callbackGasLimit,
        uint16 numWords
    ) external returns (uint256 requestId);

    // Function to get subscription details if needed, e.g., subId.getSubscription(subId)
    // function getSubscription(uint64 subId) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);
}


contract EtherealShards is Ownable, Pausable, VRFConsumerBaseV2 {

    // --- Constants ---
    string public constant NAME = "Ethereal Shard";
    string public constant SYMBOL = "ESHARD";
    uint8 public constant DECIMALS = 18;
    uint256 private constant SHARD_MINT_AMOUNT_PER_CRYSTAL = 1000 * (10**DECIMALS); // Example: 1000 Shards per shattered crystal
    uint256 private constant CRYSTAL_PROPERTY_TIME_FACTOR = 1 days; // How often time-based property updates are significant
    uint256 private constant PROPOSAL_VOTING_PERIOD = 3 days; // Voting duration for proposals
    uint256 private constant PROPOSAL_TIMELOCK = 1 days; // Delay before a successful proposal can be executed

    // --- Enums ---
    enum CrystalState { Minted, Shattered, Staked }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---
    struct Crystal {
        uint256 purity; // Dynamic property 1
        uint256 energy; // Dynamic property 2
        uint48 lastPropertiesUpdateTime; // Using uint48 for efficiency
        CrystalState state;
    }

    struct Proposal {
        string description;
        address proposer;
        uint256 createdTime;
        uint256 voteEndTime;
        address target;
        bytes callData; // The function call to execute if successful
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
    }

    // --- State Variables ---

    // Shard Data (ERC-20 like)
    mapping(address => uint256) private _shardBalances;
    mapping(address => mapping(address => uint256)) private _shardAllowances;
    uint256 private _totalShardsMinted; // Total supply of shards
    uint256 private _shardTransferFeeRate = 0; // Fee in basis points (e.g., 10 = 0.1%)

    // Crystal Data (NFT like)
    mapping(uint256 => Crystal) private _crystals;
    mapping(uint256 => address) private _crystalOwners; // Explicit owner mapping
    uint256 private _crystalCount; // Total number of crystals ever minted
    uint256 private _nextTokenId; // Counter for next crystal ID

    // Staking Data
    mapping(address => uint256) private _stakedShards;
    mapping(address => uint256) private _lastShardStakeTime; // For yield calculation
    mapping(address => uint256) private _accumulatedShardYieldPerUnit; // For yield calculation (per staked share)
    uint256 private _totalStakedShards;
    uint256 private _accumulatedGlobalYieldPerUnit; // Global yield tracking

    mapping(uint256 => bool) private _crystalIsStaked; // Tracks which crystals are staked

    uint256 private _shardYieldRatePerSecond = 100; // Example rate: 100 wei of shards per staked shard per second (very low, adjust as needed)

    // Governance Data
    mapping(uint256 => Proposal) private _proposals;
    uint256 private _nextProposalId; // Counter for proposals
    uint256 private _proposalThresholdBPS = 100; // Min % of total staked shards (in BPS) to submit/pass proposal (100 BPS = 1%)
    uint256 private _quorumBPS = 400; // Min % of total staked shards (in BPS) that must vote 'for' to pass (400 BPS = 4%)
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // To prevent double voting

    address private _governor; // Address/Contract that can execute governance functions

    // VRF Data (Chainlink VRF v2)
    IVRFCoordinatorV2 private immutable i_vrfCoordinator;
    bytes32 private i_keyHash;
    uint64 private i_subscriptionId;
    uint32 private constant VRF_CALLBACK_GAS_LIMIT = 500000; // Gas limit for VRF callback
    uint16 private constant VRF_NUM_WORDS = 2; // Number of random words requested (for 2 properties)

    mapping(uint256 => uint256) private _vrfRequestIdToCrystalId; // Map request ID to crystal ID

    // Fees
    address payable private _ethFeeCollector;

    // --- Events ---

    // ERC20-like
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ShardTransferFee(address indexed from, uint256 feeAmount);

    // ERC721-like (simplified)
    event CrystalMinted(uint256 indexed crystalId, address indexed owner);
    event CrystalShattered(uint256 indexed crystalId, address indexed previousOwner, uint256 shardsMinted, uint256 ethFeePaid);
    event CrystalPropertiesUpdated(uint256 indexed crystalId, uint256 newPurity, uint256 newEnergy, bool isRandom);

    // Staking
    event ShardsStaked(address indexed account, uint256 amount);
    event ShardsUnstaked(address indexed account, uint256 amount);
    event YieldClaimed(address indexed account, uint256 amount);
    event CrystalStaked(uint256 indexed crystalId, address indexed owner);
    event CrystalUnstaked(uint256 indexed crystalId, address indexed owner);

    // Governance
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChanged(string parameterName, uint256 newValue);

    // VRF
    event RandomnessRequested(uint256 indexed crystalId, uint256 indexed requestId);

    // Pausability
    event Paused(address account);
    event Unpaused(address account);

    // --- Constructor ---

    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint256 initialCrystalCount,
        address initialGovernor,
        address payable ethFeeCollector
    ) VRFConsumerBaseV2(vrfCoordinator) Ownable(msg.sender) Pausable() {
        i_vrfCoordinator = IVRFCoordinatorV2(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;

        _governor = initialGovernor;
        _ethFeeCollector = ethFeeCollector;

        require(initialCrystalCount > 0, "Initial crystal count must be > 0");
        require(initialGovernor != address(0), "Initial governor cannot be zero address");
        require(ethFeeCollector != address(0), "Fee collector cannot be zero address");

        // Mint initial crystals to the contract deployer (owner)
        for (uint256 i = 0; i < initialCrystalCount; i++) {
            _mintCrystal(msg.sender);
        }
    }

    // --- Modifiers ---
    modifier onlyGovernor() {
        require(_governor == _msgSender(), "Not authorized governor");
        _;
    }

    // --- Initial Configuration (can be set by owner once then governance takes over) ---

    function initializeGovernor(address initialGovernor) external onlyOwner {
        require(_governor == address(0), "Governor already initialized");
        require(initialGovernor != address(0), "Initial governor cannot be zero address");
        _governor = initialGovernor;
        transferOwnership(address(0)); // Renounce ownership after setting governor
    }

    function setFeeCollector(address payable newFeeCollector) external onlyGovernor {
        require(newFeeCollector != address(0), "Fee collector cannot be zero address");
        _ethFeeCollector = newFeeCollector;
    }

    // --- Crystal Management (NFT-like) ---

    function _mintCrystal(address to) internal {
        uint256 crystalId = _nextTokenId++;
        _crystals[crystalId] = Crystal({
            purity: 100, // Initial properties
            energy: 100,
            lastPropertiesUpdateTime: uint48(block.timestamp),
            state: CrystalState.Minted
        });
        _crystalOwners[crystalId] = to;
        _crystalCount++;
        emit CrystalMinted(crystalId, to);
    }

    function mintCrystal(address to) external onlyGovernor whenNotPaused {
         require(to != address(0), "Cannot mint to zero address");
        _mintCrystal(to);
    }

    function getCrystal(uint256 crystalId) external view returns (uint256 purity, uint256 energy, uint48 lastUpdateTime, CrystalState state) {
        Crystal storage crystal = _crystals[crystalId];
        // Note: This getter doesn't apply time-based updates lazily. Call updateCrystalProperties() explicitly.
        return (crystal.purity, crystal.energy, crystal.lastPropertiesUpdateTime, crystal.state);
    }

    function getCrystalOwner(uint256 crystalId) external view returns (address) {
        return _crystalOwners[crystalId];
    }

    function getCrystalPurity(uint256 crystalId) external view returns (uint256) {
        return _crystals[crystalId].purity;
    }

    function getCrystalEnergy(uint256 crystalId) external view returns (uint256) {
        return _crystals[crystalId].energy;
    }

    function getCrystalState(uint256 crystalId) external view returns (CrystalState) {
        return _crystals[crystalId].state;
    }

    function shatterCrystal(uint256 crystalId) external payable whenNotPaused {
        address owner = _crystalOwners[crystalId];
        require(owner == _msgSender(), "Not crystal owner");
        require(_crystals[crystalId].state == CrystalState.Minted, "Crystal not in mintable state"); // Can only shatter Minted ones
        require(msg.value > 0, "Must send ETH fee to shatter"); // Require some ETH fee

        uint256 ethFee = msg.value;
        uint256 shardsToMint = (SHARD_MINT_AMOUNT_PER_CRYSTAL * (10000 - _shatteringFeeRate)) / 10000; // Apply fee in BPS
        uint256 feeAmountShards = SHARD_MINT_AMOUNT_PER_CRYSTAL - shardsToMint; // Shards burned as fee

        // Conceptually "burn" the crystal and update state
        delete _crystalOwners[crystalId]; // Remove owner
        _crystals[crystalId].state = CrystalState.Shattered;
        // Crystal properties remain recorded but are no longer relevant to an owner

        // Mint shards to the owner
        _mintShards(owner, shardsToMint);

        // Transfer ETH fee
        (bool success, ) = _ethFeeCollector.call{value: ethFee}("");
        require(success, "ETH transfer failed");

        emit CrystalShattered(crystalId, owner, shardsToMint, ethFee);
         // Emit Transfer event for shards minted
        emit Transfer(address(0), owner, shardsToMint);
    }

    // Callable by anyone - incentivizes users to refresh crystal data
    function updateCrystalProperties(uint256 crystalId) external whenNotPaused {
        Crystal storage crystal = _crystals[crystalId];
        require(crystal.state != CrystalState.Shattered, "Cannot update properties of shattered crystal");

        uint256 timeElapsed = block.timestamp - crystal.lastPropertiesUpdateTime;
        if (timeElapsed >= CRYSTAL_PROPERTY_TIME_FACTOR) {
             // Simple time-based decay/growth example
            uint256 periods = timeElapsed / CRYSTAL_PROPERTY_TIME_FACTOR;
            // Decay Purity slightly, grow Energy
            crystal.purity = crystal.purity > periods ? crystal.purity - periods : 0;
            crystal.energy = crystal.energy < (200 - periods) ? crystal.energy + periods : 200; // Max 200 energy
            crystal.lastPropertiesUpdateTime = uint48(block.timestamp);
            emit CrystalPropertiesUpdated(crystalId, crystal.purity, crystal.energy, false);
        }
        // No-op if not enough time has passed
    }

     // Callable by anyone - requests VRF for a staked crystal
     // Requires subscription to be funded
    function requestCrystalRandomUpdate(uint256 crystalId) external whenNotPaused {
        require(_crystalIsStaked[crystalId], "Crystal must be staked for random update");
        // Ensure VRF config is set
        require(i_keyHash != bytes32(0), "VRF key hash not set");
        require(i_subscriptionId > 0, "VRF subscription ID not set");

        // Request randomness
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            3, // requestConfirmations
            VRF_CALLBACK_GAS_LIMIT,
            VRF_NUM_WORDS // number of random words
        );
        _vrfRequestIdToCrystalId[requestId] = crystalId;
        emit RandomnessRequested(crystalId, requestId);
    }

    // VRF Callback function - only callable by VRF Coordinator
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 crystalId = _vrfRequestIdToCrystalId[requestId];
        require(crystalId != 0, "Crystal ID not found for request ID"); // Should not happen if mapping is correct
        delete _vrfRequestIdToCrystalId[requestId]; // Clean up mapping

        Crystal storage crystal = _crystals[crystalId];
        // Apply randomness to properties (example logic)
        uint256 rand1 = randomWords[0];
        uint256 rand2 = randomWords[1];

        crystal.purity = (crystal.purity + (rand1 % 20)) % 200; // Example: Add up to 20, max 200
        crystal.energy = (crystal.energy + (rand2 % 30)) % 300; // Example: Add up to 30, max 300
        crystal.lastPropertiesUpdateTime = uint48(block.timestamp);

        emit CrystalPropertiesUpdated(crystalId, crystal.purity, crystal.energy, true);
    }

    function getVRFRequestIdForCrystal(uint256 requestId) external view returns (uint256) {
        return _vrfRequestIdToCrystalId[requestId];
    }


    // --- Shard Management (ERC-20 like, custom transfer with fee) ---

    // ERC-20 Standard Getters
    function name() public pure returns (string memory) { return NAME; }
    function symbol() public pure returns (string memory) { return SYMBOL; }
    function decimals() public pure returns (uint8) { return DECIMALS; }
    function totalSupply() public view returns (uint256) { return _totalShardsMinted; }
    function balanceOf(address account) public view returns (uint256) { return _shardBalances[account]; }
    function allowance(address owner, address spender) public view returns (uint256) { return _shardAllowances[owner][spender]; }

    function _mintShards(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: mint to the zero address");
        _totalShardsMinted += amount;
        _shardBalances[to] += amount;
    }

     function _burnShards(address from, uint256 amount) internal {
        require(from != address(0), "ERC20: burn from the zero address");
        require(_shardBalances[from] >= amount, "ERC20: burn amount exceeds balance");
        _shardBalances[from] -= amount;
        _totalShardsMinted -= amount;
    }


    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_shardBalances[from] >= amount, "ERC20: transfer amount exceeds balance");

        uint256 feeAmount = (amount * _shardTransferFeeRate) / 10000; // Calculate fee
        uint256 amountAfterFee = amount - feeAmount;

        _shardBalances[from] -= amount;
        _shardBalances[to] += amountAfterFee; // Recipient gets amount after fee

        if (feeAmount > 0) {
            // Decide where fees go - let's burn them for simplicity or send to collector
             _burnShards(from, feeAmount); // Burn the fee
             emit ShardTransferFee(from, feeAmount);
        }

        emit Transfer(from, to, amountAfterFee); // Emit transfer event for amount received
        if (feeAmount > 0) {
             // Optional: Emit a separate event for the fee transfer/burn if needed
             // emit Transfer(from, address(0), feeAmount); // If burning
        }
    }

    function transfer(address recipient, uint256 amount) public virtual whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual whenNotPaused returns (bool) {
        _shardAllowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual whenNotPaused returns (bool) {
        uint256 currentAllowance = _shardAllowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);

        // Decrease allowance. Using checked arithmetic is safe in 0.8+
        _shardAllowances[sender][_msgSender()] = currentAllowance - amount;

        return true;
    }

     function getShardTransferFeeRate() external view returns (uint256) {
        return _shardTransferFeeRate; // In Basis Points (BPS)
    }


    // --- Staking ---

    // Internal function to update yield state before any staking/unstaking/claiming action
    function _updateYieldState(address account) internal {
        if (_stakedShards[account] == 0) {
            _lastShardStakeTime[account] = block.timestamp;
            _accumulatedShardYieldPerUnit[account] = _accumulatedGlobalYieldPerUnit;
            return;
        }

        uint256 timeElapsed = block.timestamp - _lastShardStakeTime[account];
        if (timeElapsed > 0) {
            // Calculate new global yield per unit since last update
            uint256 newGlobalYield = (_totalStakedShards * _shardYieldRatePerSecond * timeElapsed);
            _accumulatedGlobalYieldPerUnit += newGlobalYield / _totalStakedShards; // Assumes _totalStakedShards > 0

            // Calculate pending yield for this account
            uint256 pending = (_accumulatedGlobalYieldPerUnit - _accumulatedShardYieldPerUnit[account]) * _stakedShards[account];
             // Mint pending yield to user's balance before updating state
            if (pending > 0) {
                 _mintShards(account, pending);
                 emit YieldClaimed(account, pending); // Emit yield claim event here
            }

            _accumulatedShardYieldPerUnit[account] = _accumulatedGlobalYieldPerUnit; // Update account's marker
            _lastShardStakeTime[account] = block.timestamp; // Update timestamp
        }
    }


    function stakeShards(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot stake 0");
        require(_shardBalances[_msgSender()] >= amount, "Insufficient shard balance");

        _updateYieldState(_msgSender()); // Update user's yield before changing stake

        _shardBalances[_msgSender()] -= amount;
        _stakedShards[_msgSender()] += amount;
        _totalStakedShards += amount;

        emit ShardsStaked(_msgSender(), amount);
    }

    function unstakeShards(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot unstake 0");
        require(_stakedShards[_msgSender()] >= amount, "Insufficient staked shards");

        _updateYieldState(_msgSender()); // Update user's yield before changing stake (yield is minted in here)

        _stakedShards[_msgSender()] -= amount;
        _totalStakedShards -= amount;
        _shardBalances[_msgSender()] += amount; // Return unstaked amount to balance

        emit ShardsUnstaked(_msgSender(), amount);
    }

    // Users can claim yield without unstaking
    function claimStakedShardYield() external whenNotPaused {
         _updateYieldState(_msgSender()); // This function *mints* and *emits* yield if any
    }

     // View function to see pending yield without claiming
    function calculatePendingShardYield(address account) public view returns (uint256) {
         uint256 staked = _stakedShards[account];
         if (staked == 0) {
             return 0;
         }
         uint256 currentGlobalYieldPerUnit = _accumulatedGlobalYieldPerUnit;
         uint256 timeElapsed = block.timestamp - _lastShardStakeTime[account];
         if (timeElapsed > 0 && _totalStakedShards > 0) {
              uint256 newGlobalYield = (_totalStakedShards * _shardYieldRatePerSecond * timeElapsed);
              currentGlobalYieldPerUnit += newGlobalYield / _totalStakedShards;
         }

         return (currentGlobalYieldPerUnit - _accumulatedShardYieldPerUnit[account]) * staked;
    }

    function stakeCrystal(uint256 crystalId) external whenNotPaused {
        address owner = _crystalOwners[crystalId];
        require(owner == _msgSender(), "Not crystal owner");
        require(_crystals[crystalId].state == CrystalState.Minted, "Crystal not in stakeable state"); // Only stake Minted ones
        require(!_crystalIsStaked[crystalId], "Crystal is already staked");

        _crystalIsStaked[crystalId] = true;
        _crystals[crystalId].state = CrystalState.Staked; // Update crystal state

        // Optional: Transfer crystal ownership to the contract here if needed for stricter control
        // _crystalOwners[crystalId] = address(this); // Or a designated staking address

        emit CrystalStaked(crystalId, owner);
    }

    function unstakeCrystal(uint256 crystalId) external whenNotPaused {
        address owner = _crystalOwners[crystalId]; // Get original owner (if ownership wasn't transferred)
        if(owner == address(0)) owner = _msgSender(); // If ownership was transferred, check msg.sender
        require(_msgSender() == owner || _crystals[crystalId].state == CrystalState.Staked, "Not crystal owner or not staked"); // Allow original owner or current staker to unstake
         require(_crystalIsStaked[crystalId], "Crystal is not staked");
        require(_crystals[crystalId].state == CrystalState.Staked, "Crystal is not in staked state");

        _crystalIsStaked[crystalId] = false;
         _crystals[crystalId].state = CrystalState.Minted; // Revert state to Minted

        // Optional: Transfer crystal ownership back if it was transferred to the contract
        // _crystalOwners[crystalId] = _msgSender();

        emit CrystalUnstaked(crystalId, owner);
    }

    function getCrystalIsStaked(uint256 crystalId) external view returns (bool) {
        return _crystalIsStaked[crystalId];
    }

    function getTotalStakedShards() external view returns (uint256) {
        return _totalStakedShards;
    }

    function getStakedShards(address account) external view returns (uint256) {
        return _stakedShards[account];
    }

    // --- Governance ---

    function submitProposal(string memory description, address target, bytes memory callData) external whenNotPaused returns (uint256 proposalId) {
        require(_totalStakedShards > 0, "No shards staked yet"); // Prevent proposals before staking begins
        uint256 proposerVotingPower = _stakedShards[_msgSender()];
        uint256 requiredThreshold = (_totalStakedShards * _proposalThresholdBPS) / 10000;
        require(proposerVotingPower >= requiredThreshold, "Insufficient staked shards to submit proposal");

        proposalId = _nextProposalId++;
        _proposals[proposalId] = Proposal({
            description: description,
            proposer: _msgSender(),
            createdTime: block.timestamp,
            voteEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            target: target,
            callData: callData,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, _msgSender(), description);
    }

    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended");
        require(!_hasVoted[proposalId][_msgSender()], "Already voted on this proposal");

        // Voting power is based on current staked shards
        uint256 votingPower = _stakedShards[_msgSender()];
        require(votingPower > 0, "Must stake shards to vote");

        _hasVoted[proposalId][_msgSender()] = true;

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit Voted(proposalId, _msgSender(), support, votingPower);
    }

    // Can transition state based on time and votes
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];
         if (proposal.target == address(0) && proposal.proposer == address(0)) return ProposalState.Pending; // Assuming proposal 0 is invalid

        if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
             // Calculate result after voting ends
             uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
             if (totalVotes == 0) return ProposalState.Failed; // No votes = failed

             // Check quorum (minimum total staked shards must vote FOR)
             uint256 requiredQuorum = (_totalStakedShards * _quorumBPS) / 10000;
             if (proposal.votesFor < requiredQuorum) return ProposalState.Failed; // Did not meet quorum threshold

            // Check majority
            if (proposal.votesFor > proposal.votesAgainst) {
                // Check threshold against total staked supply (or just votes cast?)
                 // Using total staked supply for threshold check, but quorum is minimum FOR votes
                 uint256 requiredVotesToPass = (_totalStakedShards * _proposalThresholdBPS) / 10000;
                 if (proposal.votesFor >= requiredVotesToPass) return ProposalState.Succeeded;
                 else return ProposalState.Failed; // Did not meet simple majority percentage threshold
            } else {
                 return ProposalState.Failed;
            }
        }
         return proposal.state; // Return stored state if still Pending, Active before end, or already Succeeded/Failed/Executed
    }

     // External getter for proposal state that updates if voting period ended
     function getCurrentProposalState(uint256 proposalId) external view returns (ProposalState) {
         return getProposalState(proposalId);
     }


    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        // No need to update state here, use getCurrentProposalState for that
        return _proposals[proposalId];
    }

     function getProposalVoteCounts(uint256 proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
         Proposal storage proposal = _proposals[proposalId];
         return (proposal.votesFor, proposal.votesAgainst);
     }

     function getProposalThreshold() external view returns (uint256) {
         return _proposalThresholdBPS; // In Basis Points (BPS)
     }

     function getQuorumThreshold() external view returns (uint256) {
         return _quorumBPS; // In Basis Points (BPS)
     }

    function hasVoted(uint256 proposalId, address account) external view returns (bool) {
        return _hasVoted[proposalId][account];
    }


    // Execution of a successful proposal - often done after a timelock
    function queueAndExecuteProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal must have succeeded"); // Check current state
        require(block.timestamp >= proposal.voteEndTime + PROPOSAL_TIMELOCK, "Timelock period not passed");
        require(proposal.state != ProposalState.Executed, "Proposal already executed");

        proposal.state = ProposalState.Executed;

        // Execute the proposed action
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Proposal execution failed"); // Revert if the target call fails

        emit ProposalExecuted(proposalId);
    }


    // --- Parameter Control (via Governance) ---

    // These functions are designed to be called by the governance mechanism (e.g., via queueAndExecuteProposal)
    // The 'onlyGovernor' modifier might be used on the *target* contract function if governance lives elsewhere,
    // but here they are internal and called by the contract itself via governance execution.
    // For simplicity in this example, we'll add an internal modifier or rely on the call being from the governance execute function.
    // Let's make them external and secured by `onlyGovernor` assuming the `_governor` address *is* the governance execution contract.

    function setShardYieldRate(uint256 newRatePerSecond) external onlyGovernor {
         // Consider adding validation for reasonable rates
        _shardYieldRatePerSecond = newRatePerSecond;
        emit ParameterChanged("ShardYieldRate", newRatePerSecond);
    }

    function setShatteringFeeRate(uint256 newFeeRate) external onlyGovernor {
         require(newFeeRate <= 10000, "Fee rate cannot exceed 100%"); // 10000 BPS = 100%
        _shatteringFeeRate = newFeeRate;
        emit ParameterChanged("ShatteringFeeRate", newFeeRate);
    }

    function setProposalThreshold(uint256 newThresholdBPS) external onlyGovernor {
        require(newThresholdBPS <= 10000, "Threshold cannot exceed 100%");
        _proposalThresholdBPS = newThresholdBPS;
        emit ParameterChanged("ProposalThreshold", newThresholdBPS);
    }

    function setQuorumThreshold(uint256 newQuorumBPS) external onlyGovernor {
         require(newQuorumBPS <= 10000, "Quorum cannot exceed 100%");
        _quorumBPS = newQuorumBPS;
        emit ParameterChanged("QuorumThreshold", newQuorumBPS);
    }


    function setVRFConfig(bytes32 keyHash, uint64 subscriptionId) external onlyGovernor {
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        // Emit event or log?
        // emit ParameterChanged("VRFConfig", ...); // Hard to represent bytes32/uint64 as single uint256
    }


    // --- Utility/Admin ---

    function pause() external onlyGovernor {
        _pause();
    }

    function unpause() external onlyGovernor {
        _unpause();
    }

    function withdrawETH() external onlyGovernor {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = _ethFeeCollector.call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }

    function getCrystalCount() external view returns (uint256) {
        return _crystalCount;
    }

    // Get current governor address
    function getGovernor() external view returns (address) {
        return _governor;
    }

     // Get current fee collector address
    function getFeeCollector() external view returns (address payable) {
        return _ethFeeCollector;
    }
}
```