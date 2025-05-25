Okay, here is a Solidity smart contract incorporating multiple advanced, creative, and potentially trendy concepts: dynamic NFTs, staking with yield based on time and governance-controlled rates, a basic on-chain crafting/upgrading system for NFTs, and a minimal governance module to control parameters.

It focuses on a hypothetical "ChronoForge" where users stake tokens to earn crafting components, which are then used to forge or upgrade evolving "Artifact" NFTs whose properties can change over time or through actions. Governance allows the community to propose and vote on system parameters.

This contract is complex and designed to showcase various concepts. It is **not audited** and should **not be used in production** without rigorous security review.

---

**Contract Name:** ChronoForgeAndGovernance

**Outline:**

1.  **License and Version:** SPDX license and Solidity version.
2.  **Imports:** ERC-20 interface, ERC-721 base contract (using OpenZeppelin for robustness and standard functions), Ownable (for initial setup), Pausable (for emergencies).
3.  **Interfaces:** Define minimal interfaces for the external ERC-20 tokens (Stake Token, Component Token).
4.  **Libraries:** (Not strictly needed for this structure, but could be used for complex math or data structures).
5.  **Errors:** Custom errors for clarity.
6.  **Events:** Announce key state changes (Staked, Unstaked, ComponentsClaimed, ArtifactMinted, ArtifactUpgraded, ProposalCreated, Voted, ProposalQueued, ProposalExecuted, DecayApplied).
7.  **Structs:**
    *   `Artifact`: Represents an evolving NFT with properties, level, and time tracking.
    *   `Proposal`: Represents a governance proposal with state, votes, target data.
8.  **Enums:** `ProposalState` to track governance proposal lifecycle.
9.  **State Variables:**
    *   Addresses of external tokens (Stake, Component).
    *   Mapping for staked balances (`stakes`).
    *   Mapping for tracking last component claim time (`lastClaimTime`).
    *   Global system parameters (staking yield rate, proposal threshold, voting period, queue period, decay rate multipliers, etc.). These will be governance-controlled.
    *   Mapping for Artifact data (`artifacts`).
    *   Counter for total artifacts minted (`_nextTokenId`).
    *   Mapping for governance proposals (`proposals`).
    *   Counter for total proposals (`_nextProposalId`).
    *   Mapping to track user votes on proposals (`hasVoted`).
10. **Inheritance:** Inherit `ERC721`, `Ownable`, `Pausable`.
11. **Constructor:** Initialize contract owner, token addresses, and initial parameters.
12. **Modifiers:** Custom modifiers (e.g., `onlyProposer`, `whenInVotingPeriod`, `whenInQueuePeriod`, `whenExecutable`).
13. **Functions:**
    *   **Admin (Ownable/Pausable):**
        *   `pause()`
        *   `unpause()`
        *   `emergencyWithdrawStaked()` (Only owner, when paused)
        *   `setTokenAddresses()` (Initial setup, perhaps later governance)
    *   **Parameter Configuration (Target of Governance):**
        *   `setStakeYieldRate()`
        *   `setProposalThreshold()`
        *   `setVotingPeriod()`
        *   `setQueuePeriod()`
        *   `setArtifactCraftingCost()`
        *   `setArtifactUpgradeCost()`
        *   `setArtifactDecayRate()`
        *   `setArtifactBaseProperties()`
        *   `setArtifactPropertiesPerLevel()`
    *   **Staking:**
        *   `stakeTokens()` (Requires approval of Stake Token)
        *   `unstakeTokens()`
        *   `claimComponents()` (Calculates and mints/transfers earned components)
        *   `calculatePendingComponents()` (View function)
    *   **Artifacts (ERC721 functions - inherited):**
        *   `balanceOf(address owner)`
        *   `ownerOf(uint256 tokenId)`
        *   `approve(address to, uint256 tokenId)`
        *   `getApproved(uint256 tokenId)`
        *   `setApprovalForAll(address operator, bool approved)`
        *   `isApprovedForAll(address owner, address operator)`
        *   `transferFrom(address from, address to, uint256 tokenId)`
        *   `safeTransferFrom(address from, address to, uint256 tokenId)`
    *   **Artifacts (Custom):**
        *   `mintArtifact()` (Uses components, sets base properties)
        *   `upgradeArtifact()` (Uses components, increases level, updates properties, resets last upgrade time)
        *   `getArtifactProperties()` (View function to get current state)
        *   `checkArtifactTimeDecay()` (View function to see potential decay)
        *   `applyArtifactTimeDecay()` (Applies decay based on time elapsed)
        *   `tokenURI(uint256 tokenId)` (Generates dynamic metadata URI)
    *   **Crafting:**
        *   `getCraftingCost(uint256 artifactLevel, uint256 upgradeLevel)` (View function)
    *   **Governance:**
        *   `proposeChange()` (Creates a new proposal to call a specific function with data, requires stake)
        *   `voteOnProposal()` (Votes for/against, vote weight based on staked amount)
        *   `getProposalState()` (View function)
        *   `getProposalDetails()` (View function)
        *   `getVoteDetails()` (View function for user's vote)
        *   `queueProposal()` (Moves successful proposal to timed queue)
        *   `executeProposal()` (Executes the proposed function call after queue time)
    *   **Utility:**
        *   `getStakedBalance()` (View function)
        *   `getSystemParameters()` (View function for all configurable params)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Interface for Stake/Component tokens

// --- CONTRACT NAME ---
/// @title ChronoForgeAndGovernance
/// @author Your Name/Alias
/// @notice A smart contract managing staking for yield, crafting/upgrading dynamic NFTs (Artifacts),
/// and a governance system for parameter control. Artifact properties can decay over time.

// --- OUTLINE ---
// 1. License and Version
// 2. Imports (ERC721, Ownable, Pausable, Counters, Address, IERC20)
// 3. Interfaces (IERC20 - implicitly used via import)
// 4. Errors
// 5. Events
// 6. Structs (Artifact, Proposal)
// 7. Enums (ProposalState)
// 8. State Variables (Token addresses, staking data, artifact data, proposal data, parameters)
// 9. Inheritance (ERC721, Ownable, Pausable)
// 10. Constructor
// 11. Modifiers
// 12. Functions:
//    - Admin (pause, unpause, emergencyWithdrawStaked, setTokenAddresses)
//    - Parameter Configuration (setters for various params - target of governance)
//    - Staking (stakeTokens, unstakeTokens, claimComponents, calculatePendingComponents)
//    - Artifacts (ERC721: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom)
//    - Artifacts (Custom: mintArtifact, upgradeArtifact, getArtifactProperties, checkArtifactTimeDecay, applyArtifactTimeDecay, tokenURI)
//    - Crafting (getCraftingCost)
//    - Governance (proposeChange, voteOnProposal, getProposalState, getProposalDetails, getVoteDetails, queueProposal, executeProposal)
//    - Utility (getStakedBalance, getSystemParameters)

// --- FUNCTION SUMMARY ---
/// @dev Inherited ERC721 functions: `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`
/// @dev Inherited Ownable functions: `owner`, `renounceOwnership`, `transferOwnership`
/// @dev Inherited Pausable functions: `paused`
/// @dev Note: Functions marked with `_` are internal helper functions.

// Admin Functions:
/// @notice Pauses the contract, preventing state-changing actions. Only owner.
function pause() external onlyOwner whenNotPaused
/// @notice Unpauses the contract, allowing state-changing actions again. Only owner.
function unpause() external onlyOwner whenPaused
/// @notice Allows owner to withdraw staked tokens in case of emergency pause. Only owner, when paused.
function emergencyWithdrawStaked() external onlyOwner whenPaused
/// @notice Sets the addresses for stake and component tokens. Initial setup by owner.
function setTokenAddresses(address _stakeToken, address _componentToken) external onlyOwner

// Parameter Configuration (Intended targets for Governance Execution):
/// @notice Sets the rate at which components are earned per staked token per second.
function setStakeYieldRate(uint256 _newRate) external onlyGovernanceExecutor
/// @notice Sets the minimum staked amount required to create a proposal.
function setProposalThreshold(uint256 _threshold) external onlyGovernanceExecutor
/// @notice Sets the duration of the voting period for proposals (in seconds).
function setVotingPeriod(uint256 _period) external onlyGovernanceExecutor
/// @notice Sets the duration of the queue period before a successful proposal can be executed (in seconds).
function setQueuePeriod(uint256 _period) external onlyGovernanceExecutor
/// @notice Sets the cost in component tokens to mint a new artifact.
function setArtifactMintCost(uint256 _cost) external onlyGovernanceExecutor
/// @notice Sets the base cost multiplier for upgrading an artifact. Actual cost depends on level.
function setArtifactUpgradeCostMultiplier(uint256 _multiplier) external onlyGovernanceExecutor
/// @notice Sets the rate at which artifact properties decay per second if not recently upgraded.
function setArtifactDecayRate(uint256 _decayRate) external onlyGovernanceExecutor
/// @notice Sets the base property values for a newly minted artifact.
function setArtifactBaseProperties(uint256 _basePower, uint256 _baseSpeed, uint256 _baseWisdom) external onlyGovernanceExecutor
/// @notice Sets the property increase per level when an artifact is upgraded.
function setArtifactPropertiesPerLevel(uint256 _powerPerLevel, uint256 _speedPerLevel, uint256 _wisdomPerLevel) external onlyGovernanceExecutor

// Staking Functions:
/// @notice Stakes the caller's stake tokens in the contract. Requires prior approval.
/// @param amount The amount of stake tokens to stake.
function stakeTokens(uint256 amount) external whenNotPaused
/// @notice Unstakes a specified amount of tokens from the caller's stake.
/// @param amount The amount of stake tokens to unstake.
function unstakeTokens(uint256 amount) external whenNotPaused
/// @notice Claims pending component token yield based on staked amount and time.
function claimComponents() external whenNotPaused
/// @notice Calculates the amount of component tokens currently available for claiming by the caller.
/// @return The amount of pending component tokens.
function calculatePendingComponents(address user) public view returns (uint256)

// Artifact Functions (Custom):
/// @notice Mints a new Artifact NFT. Costs component tokens.
/// @param initialName The initial name for the artifact.
function mintArtifact(string calldata initialName) external whenNotPaused
/// @notice Upgrades an existing Artifact NFT owned by the caller. Costs components based on level.
/// @param tokenId The ID of the artifact to upgrade.
function upgradeArtifact(uint256 tokenId) external whenNotPaused
/// @notice Gets the current dynamic properties of an artifact.
/// @param tokenId The ID of the artifact.
/// @return level, power, speed, wisdom, lastUpgradeTimestamp, timeSinceLastUpgrade
function getArtifactProperties(uint256 tokenId) public view returns (uint256 level, uint256 power, uint256 speed, uint256 wisdom, uint256 lastUpgradeTimestamp, uint256 timeSinceLastUpgrade)
/// @notice Calculates how much decay would be applied if `applyArtifactTimeDecay` was called now.
/// @param tokenId The ID of the artifact.
/// @return potentialDecayAmount The amount of property points potentially lost due to decay.
function checkArtifactTimeDecay(uint256 tokenId) public view returns (uint256 potentialDecayAmount)
/// @notice Applies time-based property decay to an artifact. Can be called by anyone, but only applies if decay is due.
/// @param tokenId The ID of the artifact.
function applyArtifactTimeDecay(uint256 tokenId) external whenNotPaused
/// @notice Generates a dynamic URI for the artifact's metadata based on its current state.
/// @param tokenId The ID of the artifact.
/// @return The URI pointing to the metadata.
function tokenURI(uint256 tokenId) public view override returns (string memory)

// Crafting/Cost Functions:
/// @notice Calculates the component cost to upgrade an artifact to a specific level.
/// @param currentLevel The current level of the artifact.
/// @return The cost in component tokens.
function getCraftingCost(uint256 currentLevel) public view returns (uint256)

// Governance Functions:
/// @notice Creates a new governance proposal. Requires staking above threshold.
/// @param description A brief description of the proposal.
/// @param target The address of the contract to call (usually `address(this)`).
/// @param signature The function signature to call (e.g., "setStakeYieldRate(uint256)").
/// @param callData The encoded call data for the function parameters.
/// @return proposalId The ID of the newly created proposal.
function proposeChange(string calldata description, address target, string calldata signature, bytes calldata callData) external whenNotPaused returns (uint256 proposalId)
/// @notice Casts a vote on an active proposal. Vote weight is based on staked amount at time of voting.
/// @param proposalId The ID of the proposal to vote on.
/// @param support True for 'for', False for 'against'.
function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused
/// @notice Gets the current state of a governance proposal.
/// @param proposalId The ID of the proposal.
/// @return state The current state of the proposal.
function getProposalState(uint256 proposalId) public view returns (ProposalState)
/// @notice Gets the details of a specific proposal.
/// @param proposalId The ID of the proposal.
/// @return description, target, signature, callData, proposer, votesFor, votesAgainst, creationTimestamp, votingPeriodEnd, queuePeriodEnd, state
function getProposalDetails(uint256 proposalId) public view returns (string memory description, address target, string memory signature, bytes memory callData, address proposer, uint256 votesFor, uint256 votesAgainst, uint256 creationTimestamp, uint256 votingPeriodEnd, uint256 queuePeriodEnd, ProposalState state)
/// @notice Gets the voting details for a user on a specific proposal.
/// @param proposalId The ID of the proposal.
/// @param user The address of the user.
/// @return hasVoted, support, voteWeight
function getVoteDetails(uint256 proposalId, address user) public view returns (bool hasVoted, bool support, uint256 voteWeight)
/// @notice Transitions a successful proposal from Succeeded to Queued state, starting the queue period.
/// @param proposalId The ID of the proposal.
function queueProposal(uint256 proposalId) external whenNotPaused
/// @notice Executes the proposed function call for a proposal that is in the Executable state.
/// @param proposalId The ID of the proposal.
function executeProposal(uint256 proposalId) external whenNotPaused

// Utility Functions:
/// @notice Gets the staked balance for a specific user.
/// @param user The address of the user.
/// @return The staked amount.
function getStakedBalance(address user) public view returns (uint256)
/// @notice Gets all current configurable system parameters.
/// @return stakeYieldRate, proposalThreshold, votingPeriod, queuePeriod, artifactMintCost, artifactUpgradeCostMultiplier, artifactDecayRate, basePower, baseSpeed, baseWisdom, powerPerLevel, speedPerLevel, wisdomPerLevel
function getSystemParameters() public view returns (uint256 stakeYieldRate, uint256 proposalThreshold, uint256 votingPeriod, uint256 queuePeriod, uint256 artifactMintCost, uint256 artifactUpgradeCostMultiplier, uint256 artifactDecayRate, uint256 basePower, uint256 baseSpeed, uint256 baseWisdom, uint256 powerPerLevel, uint256 speedPerLevel, uint256 wisdomPerLevel)

// --- SMART CONTRACT CODE ---

contract ChronoForgeAndGovernance is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Address for address;

    // --- ERRORS ---
    error InvalidAmount();
    error InsufficientStake();
    error AlreadyStaked(); // Unlikely, but good practice
    error NothingToClaim();
    error InsufficientComponents();
    error ArtifactDoesNotExist();
    error NotArtifactOwner();
    error InvalidArtifactLevel();
    error DecayNotDue();
    error DecayAlreadyApplied();
    error BelowProposalThreshold();
    error ProposalNotFound();
    error AlreadyVoted();
    error InvalidProposalState();
    error VotingPeriodNotActive();
    error VotingPeriodActive();
    error VotingPeriodNotEnded();
    error ProposalFailed();
    error NotInQueuePeriod();
    error QueuePeriodNotEnded();
    error ProposalAlreadyExecuted();
    error ExecutionFailed();
    error InvalidTargetAddress();
    error CannotVoteZeroStake();
    error TokenAddressesNotSet();

    // --- EVENTS ---
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ComponentsClaimed(address indexed user, uint256 amount);
    event ArtifactMinted(address indexed owner, uint256 indexed tokenId, string initialName);
    event ArtifactUpgraded(uint256 indexed tokenId, uint256 newLevel, uint256 componentsUsed);
    event ArtifactDecayApplied(uint256 indexed tokenId, uint256 decayAmount, uint256 newPower, uint256 newSpeed, uint256 newWisdom);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);

    // --- STRUCTS ---
    struct Artifact {
        string name;
        uint256 level;
        uint256 basePower; // Base stats set upon minting or last upgrade
        uint256 baseSpeed;
        uint256 baseWisdom;
        uint256 lastUpgradeTimestamp; // Timestamp of last upgrade or mint
    }

    struct Proposal {
        string description;
        address target;         // The contract address to call
        string signature;       // The function signature (e.g., "setParam(uint256)")
        bytes callData;         // The ABI encoded parameters

        address proposer;
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        uint256 queuePeriodEnd; // Time after voting ends that execution is allowed

        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalThreshold; // Threshold required for THIS proposal

        ProposalState state;
    }

    // --- ENUMS ---
    enum ProposalState {
        Pending,   // Proposal created, waiting for voting period to start (or starts immediately)
        Active,    // Voting is open
        Succeeded, // Voting ended, quorum/threshold met, For > Against
        Failed,    // Voting ended, quorum/threshold not met, or Against >= For
        Queued,    // Succeeded proposal is queued for execution
        Executed,  // Proposal successfully executed
        Expired    // Queued proposal not executed within time window
    }

    // --- STATE VARIABLES ---
    address public immutable STAKE_TOKEN;
    address public immutable COMPONENT_TOKEN;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public lastClaimTime; // Timestamp of last component claim

    // Parameters controlled by Governance
    uint256 public stakeYieldRate; // Components per staked token per second
    uint256 public proposalThreshold; // Minimum staked amount to create a proposal
    uint256 public votingPeriod; // Duration of voting in seconds
    uint256 public queuePeriod; // Duration before execution is allowed after voting ends (seconds)

    uint256 public artifactMintCost; // Cost in component tokens to mint
    uint256 public artifactUpgradeCostMultiplier; // Multiplier for upgrade cost (cost increases with level)
    uint256 public artifactDecayRate; // Amount properties decay per second if not upgraded

    // Artifact base properties and properties gained per level
    uint256 public artifactBasePower;
    uint256 public artifactBaseSpeed;
    uint256 public artifactBaseWisdom;
    uint256 public artifactPowerPerLevel;
    uint256 public artifactSpeedPerLevel;
    uint256 public artifactWisdomPerLevel;


    Counters.Counter private _nextTokenId;
    mapping(uint256 => Artifact) public artifacts; // token ID => Artifact data

    Counters.Counter private _nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    // proposalId => voter address => { hasVoted: bool, support: bool, weight: uint256 }
    mapping(uint256 => mapping(address => tuple(bool hasVoted, bool support, uint256 weight))) public hasVoted;

    // Special address/role that can execute governance proposals
    address private constant GOVERNANCE_EXECUTOR_ROLE = address(0x1); // Placeholder/Concept: Could be a multisig or another contract

    // --- CONSTRUCTOR ---
    /// @param name_ ERC721 name
    /// @param symbol_ ERC721 symbol
    /// @param _stakeToken Address of the ERC20 token to stake
    /// @param _componentToken Address of the ERC20 token earned as yield/used for crafting
    constructor(
        string memory name_,
        string memory symbol_,
        address _stakeToken,
        address _componentToken
    ) ERC721(name_, symbol_) Ownable(msg.sender) Pausable(false) {
        if (_stakeToken == address(0) || _componentToken == address(0)) {
             revert TokenAddressesNotSet();
        }
        STAKE_TOKEN = _stakeToken;
        COMPONENT_TOKEN = _componentToken;

        // Set initial parameters (can be changed via governance later)
        stakeYieldRate = 100; // Example: 100 components per stake token per second
        proposalThreshold = 100e18; // Example: 100 tokens needed to propose
        votingPeriod = 7 days;      // Example: 7 days for voting
        queuePeriod = 2 days;       // Example: 2 days execution delay

        artifactMintCost = 500e18; // Example: 500 components to mint
        artifactUpgradeCostMultiplier = 1e18; // Example: Cost increases by 1 * level * multiplier
        artifactDecayRate = 1; // Example: Decay 1 property point per second

        artifactBasePower = 10;
        artifactBaseSpeed = 10;
        artifactBaseWisdom = 10;
        artifactPowerPerLevel = 2;
        artifactSpeedPerLevel = 3;
        artifactWisdomPerLevel = 1;
    }

    // --- MODIFIERS ---
    modifier onlyGovernanceExecutor() {
        // In a real system, this would check if msg.sender is the designated executor
        // (e.g., a timelock contract controlled by governance votes).
        // For this example, we'll allow the owner to execute for testing,
        // but mark it conceptually for governance execution.
        // require(msg.sender == GOVERNANCE_EXECUTOR_ROLE, "Not governance executor");
        require(msg.sender == owner(), "Not governance executor (Owner placeholder)");
        _;
    }

    modifier whenInVotingPeriod(uint256 proposalId) {
        require(proposals[proposalId].state == ProposalState.Active, "Proposal not in active voting period");
        require(block.timestamp <= proposals[proposalId].votingPeriodEnd, "Voting period has ended");
        _;
    }

    modifier whenInQueuePeriod(uint256 proposalId) {
        require(proposals[proposalId].state == ProposalState.Queued, "Proposal not in queued state");
        require(block.timestamp > proposals[proposalId].votingPeriodEnd, "Voting period not ended yet");
        require(block.timestamp >= proposals[proposalId].queuePeriodEnd - queuePeriod, "Queue period not started"); // Ensure correct time check
        require(block.timestamp < proposals[proposalId].queuePeriodEnd + votingPeriod, "Execution window closed"); // Add execution window
        _;
    }


    // --- ADMIN FUNCTIONS ---
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function emergencyWithdrawStaked() external onlyOwner whenPaused {
        uint256 totalStaked = IERC20(STAKE_TOKEN).balanceOf(address(this));
        if (totalStaked > 0) {
            // Transfer all staked tokens back to owner in emergency
            IERC20(STAKE_TOKEN).transfer(owner(), totalStaked);
            // Note: This doesn't track individual user stakes. This is purely for emergencies.
            // A production system might require users to unstake themselves even if paused,
            // or have a more complex emergency withdrawal that distributes proportionally.
        }
    }

    function setTokenAddresses(address _stakeToken, address _componentToken) external onlyOwner {
         if (STAKE_TOKEN != address(0) || COMPONENT_TOKEN != address(0)) {
             revert("Token addresses already set"); // Prevent resetting after initial setup
         }
         if (_stakeToken == address(0) || _componentToken == address(0)) {
             revert TokenAddressesNotSet();
         }
         STAKE_TOKEN = _stakeToken;
         COMPONENT_TOKEN = _componentToken;
    }

    // --- PARAMETER CONFIGURATION FUNCTIONS (TARGETS FOR GOVERNANCE) ---
    // These functions are intended to be called by the governance execution module
    function setStakeYieldRate(uint256 _newRate) external onlyGovernanceExecutor {
        stakeYieldRate = _newRate;
    }

    function setProposalThreshold(uint256 _threshold) external onlyGovernanceExecutor {
        proposalThreshold = _threshold;
    }

    function setVotingPeriod(uint256 _period) external onlyGovernanceExecutor {
        votingPeriod = _period;
    }

    function setQueuePeriod(uint256 _period) external onlyGovernanceExecutor {
        queuePeriod = _period;
    }

    function setArtifactMintCost(uint256 _cost) external onlyGovernanceExecutor {
        artifactMintCost = _cost;
    }

    function setArtifactUpgradeCostMultiplier(uint256 _multiplier) external onlyGovernanceExecutor {
        artifactUpgradeCostMultiplier = _multiplier;
    }

    function setArtifactDecayRate(uint256 _decayRate) external onlyGovernanceExecutor {
        artifactDecayRate = _decayRate;
    }

    function setArtifactBaseProperties(uint256 _basePower, uint256 _baseSpeed, uint256 _baseWisdom) external onlyGovernanceExecutor {
        artifactBasePower = _basePower;
        artifactBaseSpeed = _baseSpeed;
        artifactBaseWisdom = _baseWisdom;
    }

     function setArtifactPropertiesPerLevel(uint256 _powerPerLevel, uint256 _speedPerLevel, uint256 _wisdomPerLevel) external onlyGovernanceExecutor {
        artifactPowerPerLevel = _powerPerLevel;
        artifactSpeedPerLevel = _speedPerLevel;
        artifactWisdomPerLevel = _wisdomPerLevel;
    }


    // --- STAKING FUNCTIONS ---
    function stakeTokens(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (STAKE_TOKEN == address(0)) revert TokenAddressesNotSet();

        // Calculate and claim pending components before staking more
        _claimPending(msg.sender);

        IERC20(STAKE_TOKEN).transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] += amount;
        lastClaimTime[msg.sender] = block.timestamp; // Reset timer after claiming and staking
        emit Staked(msg.sender, amount);
    }

    function unstakeTokens(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (stakes[msg.sender] < amount) revert InsufficientStake();
         if (STAKE_TOKEN == address(0)) revert TokenAddressesNotSet();

        // Calculate and claim pending components before unstaking
        _claimPending(msg.sender);

        stakes[msg.sender] -= amount;
        IERC20(STAKE_TOKEN).transfer(msg.sender, amount);
        lastClaimTime[msg.sender] = block.timestamp; // Reset timer after claiming and unstaking
        emit Unstaked(msg.sender, amount);
    }

    function claimComponents() external whenNotPaused {
        _claimPending(msg.sender);
    }

    function calculatePendingComponents(address user) public view returns (uint256) {
        uint256 stakedAmount = stakes[user];
        if (stakedAmount == 0 || stakeYieldRate == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - lastClaimTime[user];
        return (stakedAmount * timeElapsed * stakeYieldRate) / 1e18; // Assuming stakeYieldRate is fixed point (e.g., 1e18 for 1 component/sec)
    }

    function _claimPending(address user) internal {
        uint256 pending = calculatePendingComponents(user);
        if (pending == 0) {
            // revert NothingToClaim(); // Decide if claiming zero should revert
             lastClaimTime[user] = block.timestamp; // Still update timestamp even if zero to prevent future calculation issues
             return;
        }
         if (COMPONENT_TOKEN == address(0)) revert TokenAddressesNotSet();

        lastClaimTime[user] = block.timestamp;
        IERC20(COMPONENT_TOKEN).transfer(user, pending);
        emit ComponentsClaimed(user, pending);
    }

     function getStakedBalance(address user) public view returns (uint256) {
         return stakes[user];
     }


    // --- ARTIFACT FUNCTIONS (CUSTOM) ---
    function mintArtifact(string calldata initialName) external whenNotPaused {
        if (COMPONENT_TOKEN == address(0)) revert TokenAddressesNotSet();
        if (IERC20(COMPONENT_TOKEN).balanceOf(msg.sender) < artifactMintCost) {
            revert InsufficientComponents();
        }

        _nextTokenId.increment();
        uint256 newItemId = _nextTokenId.current();

        // Burn components
        IERC20(COMPONENT_TOKEN).transferFrom(msg.sender, address(this), artifactMintCost);
        // Note: In a real system, decide if components are burned or sent to treasury

        // Mint NFT
        _safeMint(msg.sender, newItemId);

        // Initialize artifact properties
        artifacts[newItemId] = Artifact({
            name: initialName,
            level: 1,
            basePower: artifactBasePower,
            baseSpeed: artifactBaseSpeed,
            baseWisdom: artifactBaseWisdom,
            lastUpgradeTimestamp: block.timestamp
        });

        emit ArtifactMinted(msg.sender, newItemId, initialName);
    }

    function upgradeArtifact(uint256 tokenId) external whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert NotArtifactOwner();
        if (COMPONENT_TOKEN == address(0)) revert TokenAddressesNotSet();

        Artifact storage artifact = artifacts[tokenId];
        if (artifact.level == 0) revert ArtifactDoesNotExist(); // Check if artifact exists

        uint256 cost = getCraftingCost(artifact.level);
        if (IERC20(COMPONENT_TOKEN).balanceOf(msg.sender) < cost) {
            revert InsufficientComponents();
        }

        // Burn components
        IERC20(COMPONENT_TOKEN).transferFrom(msg.sender, address(this), cost);
        // Note: Decide if components are burned or sent to treasury

        // Apply any pending decay BEFORE upgrading
        // This prevents users from upgrading to reset timer and avoid decay
        applyArtifactTimeDecay(tokenId); // Internal call

        // Increase level and update base properties
        artifact.level += 1;
        artifact.basePower += artifactPowerPerLevel;
        artifact.baseSpeed += artifactSpeedPerLevel;
        artifact.baseWisdom += artifactWisdomPerLevel;
        artifact.lastUpgradeTimestamp = block.timestamp; // Reset decay timer

        emit ArtifactUpgraded(tokenId, artifact.level, cost);
    }

    function getArtifactProperties(uint256 tokenId) public view returns (uint256 level, uint256 power, uint256 speed, uint256 wisdom, uint256 lastUpgradeTimestamp, uint256 timeSinceLastUpgrade) {
         Artifact storage artifact = artifacts[tokenId];
         if (artifact.level == 0) revert ArtifactDoesNotExist();

         uint256 timeElapsed = block.timestamp - artifact.lastUpgradeTimestamp;
         uint256 currentPower = artifact.basePower;
         uint256 currentSpeed = artifact.baseSpeed;
         uint256 currentWisdom = artifact.baseWisdom;

         // Apply decay calculation (but don't change state)
         uint256 potentialDecay = (timeElapsed * artifactDecayRate) / 1e18; // Assuming decayRate is fixed point
         currentPower = currentPower > potentialDecay ? currentPower - potentialDecay : 0;
         currentSpeed = currentSpeed > potentialDecay ? currentSpeed - potentialDecay : 0;
         currentWisdom = currentWisdom > potentialDecay ? currentWisdom - potentialDecay : 0;

         return (
             artifact.level,
             currentPower,
             currentSpeed,
             currentWisdom,
             artifact.lastUpgradeTimestamp,
             timeElapsed
         );
    }

    function checkArtifactTimeDecay(uint256 tokenId) public view returns (uint256 potentialDecayAmount) {
        Artifact storage artifact = artifacts[tokenId];
        if (artifact.level == 0) revert ArtifactDoesNotExist();

        uint256 timeElapsed = block.timestamp - artifact.lastUpgradeTimestamp;
        // Calculate potential decay amount (don't apply)
        return (timeElapsed * artifactDecayRate) / 1e18; // Assuming decayRate is fixed point
    }


    function applyArtifactTimeDecay(uint256 tokenId) public whenNotPaused {
        Artifact storage artifact = artifacts[tokenId];
        if (artifact.level == 0) revert ArtifactDoesNotExist();
        // Allow anyone to trigger decay application to keep stats up-to-date

        uint256 timeElapsed = block.timestamp - artifact.lastUpgradeTimestamp;
        if (timeElapsed == 0) {
             // Decay not due yet, or already applied very recently
            return; // Do not revert, allow passive check
        }

        uint256 decayAmount = (timeElapsed * artifactDecayRate) / 1e18; // Assuming decayRate is fixed point

        // Apply decay to base properties
        artifact.basePower = artifact.basePower > decayAmount ? artifact.basePower - decayAmount : 0;
        artifact.baseSpeed = artifact.baseSpeed > decayAmount ? artifact.baseSpeed - decayAmount : 0;
        artifact.baseWisdom = artifact.baseWisdom > decayAmount ? artifact.baseWisdom - decayAmount : 0;

        // Reset decay timer
        artifact.lastUpgradeTimestamp = block.timestamp;

        emit ArtifactDecayApplied(tokenId, decayAmount, artifact.basePower, artifact.baseSpeed, artifact.baseWisdom);
    }


    /// @dev See {ERC721-tokenURI}. Overridden to provide dynamic metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned

        // Get dynamic properties
        (uint256 level, uint256 power, uint256 speed, uint256 wisdom, , ) = getArtifactProperties(tokenId);
        Artifact storage artifact = artifacts[tokenId]; // Access stored data for name etc.

        // Basic JSON metadata structure (requires off-chain service to serve this URI)
        // For a purely on-chain solution, you would encode JSON directly or use a library
        // Example structure:
        // {
        //   "name": "Artifact #<tokenId>",
        //   "description": "An evolving ChronoForge artifact.",
        //   "image": "ipfs://...", // Static or dynamic image based on properties
        //   "attributes": [
        //     { "trait_type": "Level", "value": <level> },
        //     { "trait_type": "Power", "value": <power> },
        //     { "trait_type": "Speed", "value": <speed> },
        //     { "trait_type": "Wisdom", "value": <wisdom> },
        //     { "trait_type": "Last Upgraded", "value": <lastUpgradeTimestamp> }
        //   ]
        // }

        // This is a placeholder. A real implementation would use `string.concat`,
        // integer to string conversion, and possibly Base64 encoding for data URIs,
        // or integrate with a metadata service.
        string memory baseURI = _baseURI(); // Use inherited _baseURI if set
        if (bytes(baseURI).length > 0) {
             // Append token ID to base URI
             // Requires helper function or library for int to string and concatenation
             return string(abi.encodePacked(baseURI, "token/", Strings.toString(tokenId)));
        } else {
             // If no base URI, construct a data URI (simplified placeholder)
             // This is complex to do fully on-chain. Example:
             return string(abi.encodePacked(
                 "data:application/json;base64,",
                 "BASE64_ENCODED_JSON_HERE" // Replace with actual encoding logic
             ));
        }
    }

    // --- CRAFTING/COST FUNCTIONS ---
    function getCraftingCost(uint256 currentLevel) public view returns (uint256) {
        // Example cost calculation: Mint cost for level 1, then cost increases per level
        if (currentLevel == 0) revert InvalidArtifactLevel(); // Level 0 means doesn't exist

        // Cost to upgrade from level N to N+1
        // Simple example: Base cost + (level * multiplier)
        return artifactMintCost + (currentLevel * artifactUpgradeCostMultiplier) / 1e18; // Adjust for multiplier precision
    }

    // --- GOVERNANCE FUNCTIONS ---
    function proposeChange(string calldata description, address target, string calldata signature, bytes calldata callData) external whenNotPaused returns (uint256 proposalId) {
        if (stakes[msg.sender] < proposalThreshold) revert BelowProposalThreshold();
        if (target == address(0)) revert InvalidTargetAddress();

        _nextProposalId.increment();
        uint256 newProposalId = _nextProposalId.current();

        proposals[newProposalId] = Proposal({
            description: description,
            target: target,
            signature: signature,
            callData: callData,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriod,
            queuePeriodEnd: 0, // Set when queued
            votesFor: 0,
            votesAgainst: 0,
            proposalThreshold: proposalThreshold, // Capture threshold at time of proposal
            state: ProposalState.Active // Start voting immediately
        });

        emit ProposalCreated(newProposalId, msg.sender, description);

        return newProposalId;
    }

    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creationTimestamp == 0) revert ProposalNotFound(); // Check existence

        if (proposal.state != ProposalState.Active || block.timestamp > proposal.votingPeriodEnd) {
            revert VotingPeriodNotActive();
        }
        if (hasVoted[proposalId][msg.sender].hasVoted) revert AlreadyVoted();

        uint256 voterStake = stakes[msg.sender];
        if (voterStake == 0) revert CannotVoteZeroStake();

        hasVoted[proposalId][msg.sender] = tuple(true, support, voterStake);

        if (support) {
            proposal.votesFor += voterStake;
        } else {
            proposal.votesAgainst += voterStake;
        }

        emit Voted(proposalId, msg.sender, support, voterStake);

        // Check if voting period ended immediately after this vote (unlikely but possible if period is 0 or very short)
        if (block.timestamp >= proposal.votingPeriodEnd) {
             _endVotingPeriod(proposalId);
        }
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creationTimestamp == 0) return ProposalState.Expired; // Consider non-existent as expired state

        // Re-evaluate state based on time if it's not final
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingPeriodEnd) {
             return _evaluateVotingResult(proposalId); // Check if succeeded/failed
        }
        if (proposal.state == ProposalState.Queued && block.timestamp >= proposal.queuePeriodEnd + votingPeriod) { // Check execution window
             return ProposalState.Expired; // Expired if not executed in time
        }

        return proposal.state;
    }

    function getProposalDetails(uint256 proposalId) public view returns (
        string memory description,
        address target,
        string memory signature,
        bytes memory callData,
        address proposer,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 creationTimestamp,
        uint256 votingPeriodEnd,
        uint256 queuePeriodEnd,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.creationTimestamp == 0) revert ProposalNotFound();

        return (
            proposal.description,
            proposal.target,
            proposal.signature,
            proposal.callData,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.creationTimestamp,
            proposal.votingPeriodEnd,
            proposal.queuePeriodEnd,
            getProposalState(proposalId) // Get current state based on time
        );
    }

    function getVoteDetails(uint256 proposalId, address user) public view returns (bool hasVoted_, bool support_, uint256 voteWeight) {
         if (proposals[proposalId].creationTimestamp == 0) revert ProposalNotFound();
         tuple(bool hasVoted, bool support, uint256 weight) memory voteInfo = hasVoted[proposalId][user];
         return (voteInfo.hasVoted, voteInfo.support, voteInfo.weight);
    }


    function _evaluateVotingResult(uint256 proposalId) internal view returns (ProposalState) {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.state != ProposalState.Active || block.timestamp < proposal.votingPeriodEnd) {
             return proposal.state; // Voting not over yet
         }

         // Simple check: votesFor > votesAgainst AND minimum threshold of participation (e.g., 10% of total stake voted)
         // A real DAO needs quorum calculation based on total supply/staked or similar
         // For simplicity here, let's just require For > Against
         if (proposal.votesFor > proposal.votesAgainst) {
             // Add a simple quorum check: total votes must be > some percentage of proposal threshold
             // uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
             // if (totalVotes * 100 >= proposal.proposalThreshold) { // Example: 1% quorum based on proposer threshold
                return ProposalState.Succeeded;
             // }
         }
         return ProposalState.Failed;
    }

    function _endVotingPeriod(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Active || block.timestamp < proposal.votingPeriodEnd) {
            return; // Only process if voting just ended
        }

        ProposalState result = _evaluateVotingResult(proposalId);
        proposal.state = result;
        emit ProposalStateChanged(proposalId, result);
    }


    function queueProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creationTimestamp == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Succeeded) revert InvalidProposalState(); // Only Succeeded proposals can be queued

        proposal.state = ProposalState.Queued;
        proposal.queuePeriodEnd = block.timestamp + queuePeriod; // Set execution window start
        emit ProposalStateChanged(proposalId, ProposalState.Queued);
    }


    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creationTimestamp == 0) revert ProposalNotFound();

        // Re-check state based on time
        ProposalState currentState = getProposalState(proposalId); // Use the time-aware getter
        if (currentState == ProposalState.Expired) revert ProposalAlreadyExecuted(); // Or expired
        if (currentState != ProposalState.Queued) revert InvalidProposalState(); // Must be Queued
        if (block.timestamp < proposal.queuePeriodEnd) revert NotInQueuePeriod(); // Queue period must have passed


        // Execute the proposed function call
        (bool success, bytes memory result) = proposal.target.call(proposal.callData);

        proposal.state = ProposalState.Executed; // Mark as executed regardless of success for simplicity here
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
        emit ProposalExecuted(proposalId, success, result);

        if (!success) {
            // In a real system, handle execution failure (e.g., revert or log error)
            // For this example, we'll revert.
            revert ExecutionFailed();
        }
    }


    // --- UTILITY FUNCTIONS ---

    function getSystemParameters() public view returns (
        uint256 stakeYieldRate_,
        uint256 proposalThreshold_,
        uint256 votingPeriod_,
        uint256 queuePeriod_,
        uint256 artifactMintCost_,
        uint256 artifactUpgradeCostMultiplier_,
        uint256 artifactDecayRate_,
        uint256 basePower_,
        uint256 baseSpeed_,
        uint256 baseWisdom_,
        uint256 powerPerLevel_,
        uint256 speedPerLevel_,
        uint256 wisdomPerLevel_
    ) {
        return (
            stakeYieldRate,
            proposalThreshold,
            votingPeriod,
            queuePeriod,
            artifactMintCost,
            artifactUpgradeCostMultiplier,
            artifactDecayRate,
            artifactBasePower,
            artifactBaseSpeed,
            artifactBaseWisdom,
            artifactPowerPerLevel,
            artifactSpeedPerLevel,
            artifactWisdomPerLevel
        );
    }

    // --- PRIVATE/INTERNAL FUNCTIONS ---
    // _baseURI is inherited from ERC721 and can be set by owner for metadata server
    // _beforeTokenTransfer and _afterTokenTransfer are also inherited for hooks if needed

}
```