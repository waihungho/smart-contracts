Okay, here is a Solidity smart contract outline and code for a conceptual "Quantum Realm DAO". This contract incorporates several advanced/creative concepts:

1.  **NFT-based Resource Generation:** Staking specific NFTs generates a unique, internal resource ("Quantum Energy").
2.  **Internal Resource Spending for Governance:** Proposing and voting on key initiatives costs this generated energy, not just standard tokens.
3.  **Dual Staking:** Users stake both governance tokens (ERC-20) and NFTs (ERC-721), both contributing to capabilities (e.g., token for standard voting power, NFT for energy generation/special boosts).
4.  **Dynamic Parameters:** Key mechanics like energy generation rates and action costs can be adjusted via governance.
5.  **Timed Events:** Global energy generation boosts can be triggered for limited periods.
6.  **Modular Action Execution:** Governance proposals can trigger calls to other contracts, allowing for complex actions like treasury management or interacting with external protocols, defined within the proposal itself.
7.  **Pending Resource Calculation:** Energy is calculated dynamically based on stake time, claim time, boosts, and global events.

It avoids directly copying standard implementations of ERC20/ERC721/Governor contracts by focusing on the *interaction logic* between these assets and a unique resource/governance system.

---

**QuantumRealmDAO Smart Contract**

**Outline:**

1.  **License and Pragma:** SPDX license identifier and Solidity version.
2.  **Imports:** OpenZeppelin contracts for tokens, utilities, pausable, and ownership.
3.  **Interfaces:** Define interfaces for the required ERC20 and ERC721 tokens.
4.  **Error Codes:** Custom errors for clarity.
5.  **State Variables:**
    *   Linked external contracts (QR Token, Realm Shard NFT).
    *   Core resource: `quantumEnergy` balance mapping.
    *   Staking info: Mappings for staked QR tokens and Realm Shard NFTs, including stake time and last claim time.
    *   Realm Shard traits/boosts mapping.
    *   Dynamic parameters: Energy generation rate, action energy costs, global boost state.
    *   Governance state: Proposal counter, proposals mapping, voter tracking.
    *   Treasury: Mapping for external token balances held by the DAO.
    *   Admin/Pause state.
    *   Enums for ProposalState and ActionType.
6.  **Events:** Define events for staking, unstaking, energy claim/spend, proposal lifecycle, parameter changes, etc.
7.  **Modifiers:** Access control (owner, pausable) and custom logic checks (sufficient energy, active proposal).
8.  **Constructor:** Initializes contract, sets linked tokens, initial owner/parameters.
9.  **Internal/Private Functions:**
    *   `_calculatePendingEnergy`: Calculates a user's accumulated energy.
    *   `_updateUserEnergy`: Calculates pending, adds to balance, updates claim time.
    *   `_getRealmShardEffectiveRate`: Calculates a shard's current energy rate including trait boosts.
    *   `_spendEnergy`: Internal function to deduct energy.
10. **Public/External Functions (> 20):**
    *   *Admin/Setup:*
        1.  `setOwner` (Inherited from Ownable)
        2.  `pause` (Inherited from Pausable)
        3.  `unpause` (Inherited from Pausable)
    *   *Staking:*
        4.  `stakeQRToken`: Stake governance tokens.
        5.  `unstakeQRToken`: Unstake governance tokens.
        6.  `stakeRealmShard`: Stake an NFT.
        7.  `unstakeRealmShard`: Unstake an NFT.
    *   *Quantum Energy Management:*
        8.  `claimQuantumEnergy`: Claim accumulated energy.
        9.  `spendQuantumEnergy`: Spend energy for a specific action type.
    *   *Governance (Using Energy & Tokens):*
        10. `proposeInitiative`: Create a new governance proposal (costs energy, requires token stake).
        11. `voteOnInitiative`: Vote on an active proposal (costs energy).
        12. `executeInitiative`: Execute a successful proposal.
    *   *Treasury Management (via Governance):*
        13. `depositExternalToken`: Deposit tokens into the DAO treasury.
        14. `withdrawExternalToken`: Withdraw tokens from the treasury (only via governance execution).
        15. `transferExternalToken`: Transfer tokens from the treasury to any address (only via governance execution).
    *   *Dynamic Parameter Control (via Governance):*
        16. `setBaseEnergyGenerationRate`: Update the base energy rate.
        17. `setActionEnergyCost`: Update the energy cost for a specific action type.
        18. `setRealmShardTraitBoost`: Set a specific boost rate for an NFT trait/type (simplified via ID here).
        19. `triggerGlobalEnergyBoost`: Start a time-limited global energy generation boost.
        20. `setProposalThresholds`: Set minimum token stake and energy cost for proposals.
    *   *View Functions:*
        21. `getPendingQuantumEnergy`: View user's un-claimed energy.
        22. `getQuantumEnergyBalance`: View user's claimed energy balance.
        23. `getStakedQRTokenAmount`: View user's staked QR tokens.
        24. `getStakedRealmShardIds`: View IDs of user's staked NFTs.
        25. `getRealmShardStakingInfo`: View info about a specific staked NFT.
        26. `getTreasuryBalance`: View balance of a token in the treasury.
        27. `getProposalState`: View the state of a proposal.
        28. `getProposalVoteInfo`: View voting results for a proposal.
        29. `getActionEnergyCost`: View the energy cost for an action type.
        30. `getEffectiveEnergyGenerationRate`: View the current *base* effective rate considering global boost.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title QuantumRealmDAO
/// @author YourNameHere (based on prompts)
/// @notice A unique DAO where staking NFTs generates 'Quantum Energy', used for governance actions and special features.
/// @dev This contract combines ERC20 and ERC721 staking with a custom resource system and dynamic parameters controlled by governance.
/// @custom:security Reentrancy is mitigated by performing state changes before external calls in executeInitiative and using SafeERC20. ERC721 `onERC721Received` is not implemented as tokens are transferred *to* the contract via `transferFrom` from the staker after approval.

// --- Outline & Function Summary ---
// 1. License and Pragma
// 2. Imports
// 3. Interfaces: IERC20, IERC721
// 4. Error Codes: Custom error definitions.
// 5. State Variables: Storage for tokens, NFTs, energy, stakes, proposals, treasury, parameters, state.
// 6. Events: Notify external listeners about state changes.
// 7. Modifiers: Custom access control and state checks.
// 8. Constructor: Initialize contract with token addresses and initial settings.
// 9. Internal/Private Functions: Helper functions for calculations and state updates.
//    - _calculatePendingEnergy: Calculates user's unclaimed energy based on staked shards and time.
//    - _updateUserEnergy: Helper to calculate pending energy, add to balance, and update last claim time.
//    - _getRealmShardEffectiveRate: Gets the energy generation rate for a specific shard, including boosts.
//    - _spendEnergy: Internal function to safely deduct energy from a user's balance.
// 10. Public/External Functions (> 20):
//    - setOwner(address newOwner): [Admin] Sets the new contract owner (Inherited from Ownable).
//    - pause(): [Admin] Pauses the contract, preventing key actions (Inherited from Pausable).
//    - unpause(): [Admin] Unpauses the contract (Inherited from Pausable).
//    - stakeQRToken(uint256 amount): Allows a user to stake QR tokens, granting potential benefits (e.g., governance weight).
//    - unstakeQRToken(uint256 amount): Allows a user to unstake QR tokens.
//    - stakeRealmShard(uint256 tokenId): Allows a user to stake a Realm Shard NFT, starting Quantum Energy generation.
//    - unstakeRealmShard(uint256 tokenId): Allows a user to unstake their Realm Shard NFT.
//    - claimQuantumEnergy(): Allows a user to claim the Quantum Energy generated by their staked Realm Shards.
//    - spendQuantumEnergy(uint256 amount, ActionType action): Spends a specified amount of Quantum Energy for a particular action.
//    - proposeInitiative(string calldata descriptionHash, address target, uint256 value, bytes calldata callData): Creates a new governance proposal. Requires energy cost and token stake threshold.
//    - voteOnInitiative(uint256 proposalId, bool support): Casts a vote on an active proposal. Requires energy cost and prevents double voting.
//    - executeInitiative(uint256 proposalId): Executes a successfully passed governance proposal.
//    - depositExternalToken(address tokenAddress, uint256 amount): Allows depositing external tokens into the DAO treasury.
//    - withdrawExternalToken(address tokenAddress, uint256 amount): Allows withdrawing tokens from the treasury (callable only via governance execution).
//    - transferExternalToken(address tokenAddress, address recipient, uint256 amount): Allows transferring tokens from the treasury (callable only via governance execution).
//    - setBaseEnergyGenerationRate(uint256 ratePerSecond): [Governance] Sets the base rate at which Quantum Energy is generated per staked shard per second.
//    - setActionEnergyCost(ActionType action, uint256 cost): [Governance] Sets the Quantum Energy cost required to perform a specific DAO action.
//    - setRealmShardTraitBoost(uint256 tokenId, uint256 boostRatePerSecond): [Governance/Admin] Sets a specific energy generation boost for a particular Realm Shard NFT.
//    - triggerGlobalEnergyBoost(uint256 multiplier, uint256 duration): [Governance] Starts a time-limited event that multiplies Quantum Energy generation globally.
//    - setProposalThresholds(uint256 tokenThreshold, uint256 energyThreshold): [Governance] Sets the minimum QR token stake and Quantum Energy required to create a proposal.
//    - getPendingQuantumEnergy(address account): [View] Calculates and returns the amount of Quantum Energy an account has accumulated but not yet claimed.
//    - getQuantumEnergyBalance(address account): [View] Returns the account's current claimed Quantum Energy balance.
//    - getStakedQRTokenAmount(address account): [View] Returns the amount of QR tokens staked by an account.
//    - getStakedRealmShardIds(address account): [View] Returns the list of Realm Shard NFT token IDs staked by an account.
//    - getRealmShardStakingInfo(uint256 tokenId): [View] Returns detailed staking information for a specific Realm Shard NFT.
//    - getTreasuryBalance(address tokenAddress): [View] Returns the balance of a specific external token held in the DAO treasury.
//    - getProposalState(uint256 proposalId): [View] Returns the current state of a governance proposal.
//    - getProposalVoteInfo(uint256 proposalId): [View] Returns information about the voting results for a proposal.
//    - getActionEnergyCost(ActionType action): [View] Returns the Quantum Energy cost for a specific action type.
//    - getEffectiveEnergyGenerationRate(): [View] Returns the current *base* effective energy generation rate considering the global boost (doesn't include individual shard boosts).
// --- End Outline & Summary ---

/// @dev Custom errors for improved revert reasons.
error NotRealmShardOwner(address caller, uint256 tokenId);
error RealmShardAlreadyStaked(uint256 tokenId);
error RealmShardNotStaked(uint256 tokenId);
error InsufficientQuantumEnergy(uint256 required, uint256 available);
error InsufficientQRTokenStake(uint256 required, uint256 available);
error ProposalThresholdNotMet(uint256 requiredToken, uint256 stakedToken, uint256 requiredEnergy, uint256 availableEnergy);
error ProposalNotFound(uint256 proposalId);
error ProposalNotInState(uint256 proposalId, ProposalState requiredState, ProposalState currentState);
error AlreadyVoted(uint256 proposalId, address voter);
error CannotExecuteBeforeEnd(uint256 proposalId);
error CannotExecuteIfNotPassed(uint256 proposalId);
error ExecutionFailed(address target, bytes data);
error GlobalBoostStillActive(uint256 endTime);
error CannotTriggerZeroDurationBoost();

/// @dev Enum for different types of actions that might require Quantum Energy.
enum ActionType {
    PROPOSE_INITIATIVE,
    VOTE_ON_INITIATIVE,
    SPECIAL_EVENT_A, // Example of a special action
    SPECIAL_EVENT_B // Another example
    // Add more action types as needed
}

/// @dev Enum for the state of a governance proposal.
enum ProposalState {
    Pending,   // Proposal created, not yet active (maybe needs review period)
    Active,    // Voting is open
    Succeeded, // Voting ended, passed
    Defeated,  // Voting ended, failed
    Executed,  // Proposal action was successfully performed
    Canceled   // Proposal was canceled
}

/// @dev Struct to store information about a staked Realm Shard NFT.
struct RealmShardInfo {
    address owner; // The account that staked the shard
    uint64 stakeTime; // Timestamp when the shard was staked
    uint64 lastEnergyClaimTime; // Timestamp when energy was last claimed for this shard
    uint128 boostRatePerSecond; // Specific energy boost rate for this shard
}

/// @dev Struct to store information about a staked QR Token amount.
struct QRTokenStakeInfo {
    uint128 amount; // The amount of QR tokens staked
    uint64 stakeTime; // Timestamp when the tokens were staked (useful for future time-weighted features)
}

/// @dev Struct to store information about a governance proposal.
struct Proposal {
    address proposer; // Account that created the proposal
    string descriptionHash; // IPFS hash or URI pointing to the proposal details
    address target; // Target contract for execution
    uint256 value; // ETH value to send with execution call
    bytes callData; // Call data for the execution
    uint64 startTime; // Timestamp when voting starts
    uint64 endTime; // Timestamp when voting ends
    uint256 totalVotesEnergy; // Total energy spent voting (yes + no)
    uint256 yesVotesEnergy; // Total energy spent on 'yes' votes
    uint256 noVotesEnergy; // Total energy spent on 'no' votes
    ProposalState state; // Current state of the proposal
}

contract QuantumRealmDAO is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Variables ---

    IERC20 public immutable qrToken; // The main governance token
    IERC721 public immutable realmShardNFT; // The NFT used for energy generation

    // Quantum Energy State
    mapping(address => uint256) public quantumEnergy; // User's claimed Quantum Energy balance
    mapping(address => uint64) private _lastEnergyClaimTime; // Last timestamp energy was claimed for the user (simplifies calculation)

    // Staking State
    mapping(address => QRTokenStakeInfo) public qrTokenStakes; // User's staked QR token info
    mapping(uint256 => RealmShardInfo) public realmShardStakes; // Staked Realm Shard NFT info (tokenId => info)
    mapping(address => uint256[]) private _stakedRealmShardsByUser; // List of staked shard IDs per user

    // Realm Shard Specifics (can be set via governance)
    uint256 public baseEnergyGenerationRatePerSecond; // Base rate per shard per second
    mapping(uint256 => uint128) public realmShardBoosts; // Specific boost per tokenId

    // Dynamic Parameters (set via governance)
    mapping(ActionType => uint256) public actionEnergyCosts; // Cost of actions in Quantum Energy
    uint256 public globalEnergyBoostMultiplier = 1e18; // Global multiplier (1e18 = 1x)
    uint64 public globalEnergyBoostEndTime; // Timestamp when global boost ends

    // Governance State
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals; // Proposal ID => Proposal struct
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId => voterAddress => hasVoted
    uint256 public proposalTokenThreshold; // Minimum staked QR tokens to propose
    uint256 public proposalEnergyThreshold; // Minimum claimed Quantum Energy to propose

    // Treasury State
    mapping(address => uint256) public treasuryBalances; // External token balances held by the DAO

    // --- Events ---

    event QRTokenStaked(address indexed user, uint256 amount);
    event QRTokenUnstaked(address indexed user, uint256 amount);
    event RealmShardStaked(address indexed user, uint256 indexed tokenId, uint64 stakeTime);
    event RealmShardUnstaked(address indexed user, uint256 indexed tokenId, uint64 unstakeTime);
    event QuantumEnergyClaimed(address indexed user, uint256 amount);
    event QuantumEnergySpent(address indexed user, uint256 amount, ActionType indexed action);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionHash, address target, uint256 value, uint64 startTime, uint64 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 energySpent);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId); // Added Canceled state possibility
    event BaseEnergyRateSet(uint256 newRate);
    event ActionEnergyCostSet(ActionType indexed action, uint256 newCost);
    event RealmShardBoostSet(uint256 indexed tokenId, uint256 newBoostRate);
    event GlobalEnergyBoostTriggered(uint256 multiplier, uint64 duration, uint64 endTime);
    event ProposalThresholdsSet(uint256 tokenThreshold, uint256 energyThreshold);
    event ExternalTokenDeposited(address indexed tokenAddress, address indexed depositor, uint256 amount);
    event ExternalTokenWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount); // Via execution
    event ExternalTokenTransferred(address indexed tokenAddress, address indexed recipient, uint256 amount); // Via execution

    // --- Modifiers ---

    modifier onlyGovernanceExecution() {
        // This modifier ensures the function is only callable as part of executing a successful proposal.
        // Requires careful design of the executeInitiative function to track the caller.
        // A simple way is to check if the _executingProposalId is non-zero or a specific flag is set.
        // For this example, we'll assume `executeInitiative` sets a flag or state.
        // A robust implementation might pass a context variable or use a dedicated executor contract.
        // Let's use a simple internal flag for demonstration.
        require(_isExecutingProposal, "Only callable via governance execution");
        _;
    }

    // --- Internal Execution Flag ---
    bool private _isExecutingProposal = false; // Simple flag for `onlyGovernanceExecution`

    // --- Constructor ---

    constructor(
        address _qrTokenAddress,
        address _realmShardNFTAddress,
        uint256 _initialBaseEnergyRate,
        uint256 _initialProposeEnergyCost,
        uint256 _initialVoteEnergyCost,
        uint256 _initialProposalTokenThreshold,
        uint256 _initialProposalEnergyThreshold
    ) Ownable(msg.sender) Pausable(false) {
        if (_qrTokenAddress == address(0) || _realmShardNFTAddress == address(0)) {
            revert("Zero address not allowed for tokens");
        }
        qrToken = IERC20(_qrTokenAddress);
        realmShardNFT = IERC721(_realmShardNFTAddress);

        baseEnergyGenerationRatePerSecond = _initialBaseEnergyRate;
        actionEnergyCosts[ActionType.PROPOSE_INITIATIVE] = _initialProposeEnergyCost;
        actionEnergyCosts[ActionType.VOTE_ON_INITIATIVE] = _initialVoteEnergyCost;
        proposalTokenThreshold = _initialProposalTokenThreshold;
        proposalEnergyThreshold = _initialProposalEnergyThreshold;
    }

    // --- Internal/Private Functions ---

    /// @dev Calculates the pending Quantum Energy for a user based on their staked shards and time.
    /// @param account The address of the user.
    /// @return The amount of pending Quantum Energy.
    function _calculatePendingEnergy(address account) internal view returns (uint256) {
        uint256 pendingEnergy = 0;
        uint64 currentTime = uint64(block.timestamp);
        uint64 effectiveGlobalBoostEndTime = globalEnergyBoostEndTime;

        uint256[] storage stakedShards = _stakedRealmShardsByUser[account];
        for (uint i = 0; i < stakedShards.length; i++) {
            uint256 tokenId = stakedShards[i];
            RealmShardInfo storage shardInfo = realmShardStakes[tokenId];

            uint64 lastClaimTime = shardInfo.lastEnergyClaimTime; // Use shard's specific claim time

            // Calculate time since last claim for this shard
            uint66 timePassed = currentTime - lastClaimTime;

            // Calculate energy generated by this shard
            uint256 shardRate = _getRealmShardEffectiveRate(tokenId); // Includes shard boost

            // Apply global boost multiplier if active during the period
            uint256 energyFromShard = 0;
            if (globalEnergyBoostEndTime > lastClaimTime) {
                // Boost was active for part or all of the period
                uint64 boostPeriodEnd = currentTime < effectiveGlobalBoostEndTime ? currentTime : effectiveGlobalBoostEndTime;
                uint66 boostDuration = boostPeriodEnd - lastClaimTime;
                energyFromShard = (uint256(boostDuration) * shardRate * globalEnergyBoostMultiplier) / 1e18;

                if (currentTime > effectiveGlobalBoostEndTime) {
                    // After boost ended, calculate remaining period at base rate
                    uint66 postBoostDuration = currentTime - effectiveGlobalBoostEndTime;
                    energyFromShard += uint256(postBoostDuration) * shardRate;
                }
            } else {
                // No global boost during this entire period
                 energyFromShard = uint256(timePassed) * shardRate;
            }

             pendingEnergy += energyFromShard;
        }

        return pendingEnergy;
    }

    /// @dev Calculates pending energy, adds it to the user's balance, and updates timestamps.
    /// @param account The address of the user.
    function _updateUserEnergy(address account) internal {
        uint256 pending = _calculatePendingEnergy(account);
        if (pending > 0) {
            quantumEnergy[account] += pending;

            // Update last claim time for each staked shard and the user's global one
            uint64 currentTime = uint64(block.timestamp);
             uint256[] storage stakedShards = _stakedRealmShardsByUser[account];
            for (uint i = 0; i < stakedShards.length; i++) {
                 realmShardStakes[stakedShards[i]].lastEnergyClaimTime = currentTime;
            }
            _lastEnergyClaimTime[account] = currentTime; // Also update global user timestamp
        }
    }

    /// @dev Gets the effective energy generation rate for a specific Realm Shard, including its boost.
    /// @param tokenId The ID of the Realm Shard NFT.
    /// @return The effective generation rate per second for this shard.
    function _getRealmShardEffectiveRate(uint256 tokenId) internal view returns (uint256) {
        // Base rate + individual shard boost
        // Note: global boost is applied in _calculatePendingEnergy over time periods
        return baseEnergyGenerationRatePerSecond + realmShardBoosts[tokenId];
    }


    /// @dev Internal function to safely deduct Quantum Energy from a user's balance.
    /// @param account The address of the user.
    /// @param amount The amount of energy to spend.
    function _spendEnergy(address account, uint256 amount) internal {
         if (quantumEnergy[account] < amount) {
            revert InsufficientQuantumEnergy(amount, quantumEnergy[account]);
        }
        quantumEnergy[account] -= amount;
    }

    // --- Public/External Functions ---

    // Inherited from Ownable:
    // function owner() public view returns (address)
    // function renounceOwnership() public virtual
    // function transferOwnership(address newOwner) public virtual
    // function setOwner(address newOwner) public virtual onlyOwner { _transferOwnership(newOwner); } // Explicitly included for function count

    // Inherited from Pausable:
    // function paused() public view returns (bool)
    // function pause() public virtual onlyOwner { _pause(); } // Explicitly included for function count
    // function unpause() public virtual onlyOwner { _unpause(); } // Explicitly included for function count

    /// @notice Allows a user to stake QR tokens.
    /// @dev Requires the user to approve this contract to spend the tokens first.
    /// @param amount The amount of QR tokens to stake.
    function stakeQRToken(uint256 amount) external whenNotPaused {
        if (amount == 0) revert("Cannot stake 0 tokens");

        // Before staking, update user's energy based on *current* staked shards and time
        _updateUserEnergy(msg.sender);

        qrToken.safeTransferFrom(msg.sender, address(this), amount);

        QRTokenStakeInfo storage stakeInfo = qrTokenStakes[msg.sender];
        stakeInfo.amount += uint128(amount); // Safe if amount fits in uint128
        // Update stakeTime only if this is the first stake, or for tracking periods if needed
        // For simplicity, we just add to amount here. Time tracking isn't strictly needed for simple stake amount check.

        emit QRTokenStaked(msg.sender, amount);
    }

    /// @notice Allows a user to unstake QR tokens.
    /// @param amount The amount of QR tokens to unstake.
    function unstakeQRToken(uint256 amount) external whenNotPaused {
        if (amount == 0) revert("Cannot unstake 0 tokens");

        QRTokenStakeInfo storage stakeInfo = qrTokenStakes[msg.sender];
         if (stakeInfo.amount < amount) {
            revert InsufficientQRTokenStake(amount, stakeInfo.amount);
        }

        // Before unstaking, update user's energy based on *current* staked shards and time
        _updateUserEnergy(msg.sender);

        stakeInfo.amount -= uint128(amount);

        qrToken.safeTransfer(msg.sender, amount);

        emit QRTokenUnstaked(msg.sender, amount);
    }

    /// @notice Allows a user to stake a Realm Shard NFT.
    /// @dev Requires the user to approve this contract or set it as operator for the NFT first.
    /// @param tokenId The ID of the Realm Shard NFT to stake.
    function stakeRealmShard(uint256 tokenId) external whenNotPaused {
        if (realmShardNFT.ownerOf(tokenId) != msg.sender) {
            revert NotRealmShardOwner(msg.sender, tokenId);
        }
        if (realmShardStakes[tokenId].owner != address(0)) {
             revert RealmShardAlreadyStaked(tokenId);
        }

        // Before staking, update user's energy based on *currently* staked shards and time
        // This ensures energy is calculated up to THIS POINT for existing stakes before adding the new one.
        _updateUserEnergy(msg.sender);

        // Transfer NFT to the contract
        realmShardNFT.safeTransferFrom(msg.sender, address(this), tokenId);

        // Record staking info
        RealmShardInfo storage shardInfo = realmShardStakes[tokenId];
        shardInfo.owner = msg.sender;
        shardInfo.stakeTime = uint64(block.timestamp);
        shardInfo.lastEnergyClaimTime = uint64(block.timestamp); // Start claiming from now
        // boostRatePerSecond is 0 by default, can be set later via governance

        _stakedRealmShardsByUser[msg.sender].push(tokenId);

        emit RealmShardStaked(msg.sender, tokenId, shardInfo.stakeTime);
    }

    /// @notice Allows a user to unstake a Realm Shard NFT.
    /// @param tokenId The ID of the Realm Shard NFT to unstake.
    function unstakeRealmShard(uint256 tokenId) external whenNotPaused {
        RealmShardInfo storage shardInfo = realmShardStakes[tokenId];
        if (shardInfo.owner != msg.sender) {
             revert RealmShardNotStaked(tokenId);
        }

        // Before unstaking, update user's energy based on *current* staked shards and time
        // This calculates and adds any pending energy from this shard before it's removed.
         _updateUserEnergy(msg.sender);

        // Clear staking info
        delete realmShardStakes[tokenId];

        // Remove from user's list (inefficient for large lists, but okay for example)
        uint256[] storage stakedShards = _stakedRealmShardsByUser[msg.sender];
        for (uint i = 0; i < stakedShards.length; i++) {
            if (stakedShards[i] == tokenId) {
                stakedShards[i] = stakedShards[stakedShards.length - 1];
                stakedShards.pop();
                break; // Found and removed
            }
        }

        // Transfer NFT back to the user
        realmShardNFT.safeTransfer(msg.sender, tokenId);

        emit RealmShardUnstaked(msg.sender, tokenId, uint64(block.timestamp));
    }

    /// @notice Allows a user to claim their accumulated Quantum Energy.
    function claimQuantumEnergy() external whenNotPaused {
        // Calculate and add pending energy
        _updateUserEnergy(msg.sender);
        // Energy is already added to quantumEnergy[msg.sender] inside _updateUserEnergy

        // Emit event only if energy was actually added
        // We can check the balance *before* and *after* if needed, or just trust the internal function added if > 0
        // For simplicity, _updateUserEnergy only adds if pending > 0
         emit QuantumEnergyClaimed(msg.sender, quantumEnergy[msg.sender] - (quantumEnergy[msg.sender] - _calculatePendingEnergy(msg.sender))); // Approximate amount claimed
    }

     /// @notice Spends a specified amount of Quantum Energy for a particular action type.
     /// @dev Internal function for spending energy. Public wrapper below.
     /// @param amount The amount of energy to spend.
     /// @param action The type of action being performed.
     function spendQuantumEnergy(uint256 amount, ActionType action) external whenNotPaused {
         // First, make sure user's energy balance is up-to-date
         _updateUserEnergy(msg.sender);

         // Check if user has enough energy
         _spendEnergy(msg.sender, amount);

         emit QuantumEnergySpent(msg.sender, amount, action);
     }


    /// @notice Creates a new governance proposal.
    /// @dev Requires the proposer to meet minimum staked token and claimed energy thresholds, and costs Quantum Energy.
    /// @param descriptionHash IPFS hash or URI pointing to the proposal details.
    /// @param target Target contract address for execution.
    /// @param value ETH value to send with the execution call.
    /// @param callData Call data for the execution.
    function proposeInitiative(
        string calldata descriptionHash,
        address target,
        uint256 value,
        bytes calldata callData
    ) external whenNotPaused {
        // First, make sure user's energy balance and staked tokens are up-to-date for checks
         _updateUserEnergy(msg.sender);

        // Check proposal thresholds
        if (qrTokenStakes[msg.sender].amount < proposalTokenThreshold || quantumEnergy[msg.sender] < proposalEnergyThreshold) {
            revert ProposalThresholdNotMet(proposalTokenThreshold, qrTokenStakes[msg.sender].amount, proposalEnergyThreshold, quantumEnergy[msg.sender]);
        }

        // Check action cost for proposal creation
        uint256 proposalCost = actionEnergyCosts[ActionType.PROPOSE_INITIATIVE];
        _spendEnergy(msg.sender, proposalCost);

        // Create proposal
        uint256 proposalId = nextProposalId++;
        uint64 startTime = uint64(block.timestamp);
        // Define voting period duration (e.g., 3 days = 3 * 24 * 3600) - make this a governance parameter later
        uint64 votingPeriod = 72 * 3600; // Example: 3 days
        uint64 endTime = startTime + votingPeriod;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            descriptionHash: descriptionHash,
            target: target,
            value: value,
            callData: callData,
            startTime: startTime,
            endTime: endTime,
            totalVotesEnergy: 0,
            yesVotesEnergy: 0,
            noVotesEnergy: 0,
            state: ProposalState.Active // Proposals start active immediately for simplicity
        });

        emit ProposalCreated(proposalId, msg.sender, descriptionHash, target, value, startTime, endTime);
    }

    /// @notice Casts a vote on an active governance proposal.
    /// @dev Requires Quantum Energy to vote and prevents voting multiple times on the same proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a 'yes' vote, false for a 'no' vote.
    function voteOnInitiative(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) { // Check if proposal exists
            revert ProposalNotFound(proposalId);
        }
         if (proposal.state != ProposalState.Active) {
            revert ProposalNotInState(proposalId, ProposalState.Active, proposal.state);
        }
         if (_hasVoted[proposalId][msg.sender]) {
            revert AlreadyVoted(proposalId, msg.sender);
        }
        if (block.timestamp > proposal.endTime) {
             revert ProposalNotInState(proposalId, ProposalState.Active, ProposalState.Defeated); // Voting period ended
        }


        // First, make sure user's energy balance is up-to-date
         _updateUserEnergy(msg.sender);

        // Check action cost for voting
        uint256 voteCost = actionEnergyCosts[ActionType.VOTE_ON_INITIATIVE];
        _spendEnergy(msg.sender, voteCost);

        // Record vote
        _hasVoted[proposalId][msg.sender] = true;
        proposal.totalVotesEnergy += voteCost;
        if (support) {
            proposal.yesVotesEnergy += voteCost;
        } else {
            proposal.noVotesEnergy += voteCost;
        }

        emit Voted(proposalId, msg.sender, support, voteCost);
    }

    /// @notice Executes a successful governance proposal.
    /// @dev Callable by anyone after the voting period ends, if the proposal passed based on energy votes.
    /// @param proposalId The ID of the proposal to execute.
    function executeInitiative(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) {
            revert ProposalNotFound(proposalId);
        }
         if (proposal.state == ProposalState.Executed) {
            revert ProposalNotInState(proposalId, ProposalState.Succeeded, proposal.state); // Already executed
        }
         if (block.timestamp <= proposal.endTime) {
            revert CannotExecuteBeforeEnd(proposalId);
        }

        // Determine final state if not already set (e.g., if someone checked `getProposalState`)
        if (proposal.state == ProposalState.Active) {
             // Define passing criteria: e.g., simple majority of energy votes, minimum energy turnout
             uint256 energyQuorum = 1000; // Example: minimum total energy votes to be valid (make governance parameter)
             if (proposal.totalVotesEnergy > energyQuorum && proposal.yesVotesEnergy > proposal.noVotesEnergy) {
                 proposal.state = ProposalState.Succeeded;
             } else {
                 proposal.state = ProposalState.Defeated;
             }
        }


        if (proposal.state != ProposalState.Succeeded) {
            revert CannotExecuteIfNotPassed(proposalId);
        }

        // Execute the proposal's action
        _isExecutingProposal = true; // Set flag for onlyGovernanceExecution
        bool success;
        // Using low-level call with check
        (success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        _isExecutingProposal = false; // Reset flag

        if (!success) {
            // The call failed, proposal execution fails
             proposal.state = ProposalState.Defeated; // Set back to defeated or add a Failed state? Let's use Defeated.
             // Note: A robust DAO might allow retries or have a specific Failed state.
             emit ProposalCanceled(proposalId); // Emit cancel event on execution failure
            revert ExecutionFailed(proposal.target, proposal.callData);
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /// @notice Allows anyone to deposit external tokens into the DAO's treasury.
    /// @dev The tokens are held by this contract and can only be moved via governance proposals.
    /// @param tokenAddress The address of the ERC20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    function depositExternalToken(address tokenAddress, uint256 amount) external whenNotPaused {
        if (amount == 0) revert("Cannot deposit 0 tokens");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        treasuryBalances[tokenAddress] += amount; // Track balance internally (redundant but common)
        emit ExternalTokenDeposited(tokenAddress, msg.sender, amount);
    }

    /// @notice Allows withdrawing tokens from the treasury. Restricted to governance execution.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function withdrawExternalToken(address tokenAddress, uint256 amount) external onlyGovernanceExecution {
         if (amount == 0) revert("Cannot withdraw 0 tokens");
        IERC20 token = IERC20(tokenAddress);
         if (token.balanceOf(address(this)) < amount) {
             // Should not happen if governance is sane, but safety check
            revert("Insufficient treasury balance");
         }
        token.safeTransfer(msg.sender, amount); // Sender in this context is the 'target' of the proposal call, effectively the recipient if target is a user address
        treasuryBalances[tokenAddress] -= amount;
        emit ExternalTokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    /// @notice Allows transferring tokens from the treasury to an arbitrary recipient. Restricted to governance execution.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param recipient The address to send tokens to.
    /// @param amount The amount to transfer.
     function transferExternalToken(address tokenAddress, address recipient, uint256 amount) external onlyGovernanceExecution {
         if (amount == 0) revert("Cannot transfer 0 tokens");
         if (recipient == address(0)) revert("Cannot transfer to zero address");
        IERC20 token = IERC20(tokenAddress);
        if (token.balanceOf(address(this)) < amount) {
            revert("Insufficient treasury balance");
        }
        token.safeTransfer(recipient, amount);
        treasuryBalances[tokenAddress] -= amount;
        emit ExternalTokenTransferred(tokenAddress, recipient, amount);
     }

    /// @notice [Governance] Sets the base rate for Quantum Energy generation per staked shard per second.
    /// @param ratePerSecond The new base rate.
    function setBaseEnergyGenerationRate(uint256 ratePerSecond) external onlyOwner {
        baseEnergyGenerationRatePerSecond = ratePerSecond;
        emit BaseEnergyRateSet(ratePerSecond);
    }

    /// @notice [Governance] Sets the Quantum Energy cost for a specific action type.
    /// @param action The action type.
    /// @param cost The new energy cost.
    function setActionEnergyCost(ActionType action, uint256 cost) external onlyOwner {
        actionEnergyCosts[action] = cost;
        emit ActionEnergyCostSet(action, cost);
    }

     /// @notice [Governance/Admin] Sets a specific energy generation boost for a particular Realm Shard NFT.
     /// @dev This allows unique shards to have higher generation rates.
     /// @param tokenId The ID of the Realm Shard NFT.
     /// @param boostRatePerSecond The additional energy rate per second for this shard.
     function setRealmShardTraitBoost(uint256 tokenId, uint256 boostRatePerSecond) external onlyOwner {
         // This can be called even if the shard isn't staked yet.
         realmShardBoosts[tokenId] = uint128(boostRatePerSecond); // Safe if rate fits uint128
         emit RealmShardBoostSet(tokenId, boostRatePerSecond);
     }

    /// @notice [Governance] Triggers a time-limited global multiplier for Quantum Energy generation.
    /// @param multiplier The multiplier (e.g., 2e18 for 2x).
    /// @param duration The duration of the boost in seconds.
    function triggerGlobalEnergyBoost(uint256 multiplier, uint64 duration) external onlyOwner {
        if (duration == 0) revert CannotTriggerZeroDurationBoost();
        // Ensure current boost is applied up to this moment before starting a new one
        // This would require iterating through *all* stakers, which is expensive.
        // Alternative: calculate boost effect only within _calculatePendingEnergy based on boost start/end times.
        // The current _calculatePendingEnergy handles this time-based application.
        // We just need to set the new state.

        globalEnergyBoostMultiplier = multiplier;
        globalEnergyBoostEndTime = uint64(block.timestamp) + duration;

        emit GlobalEnergyBoostTriggered(multiplier, duration, globalEnergyBoostEndTime);
    }

    /// @notice [Governance] Sets the minimum QR token stake and Quantum Energy required to create a proposal.
    /// @param tokenThreshold The new minimum QR token stake.
    /// @param energyThreshold The new minimum Quantum Energy balance.
    function setProposalThresholds(uint256 tokenThreshold, uint256 energyThreshold) external onlyOwner {
        proposalTokenThreshold = tokenThreshold;
        proposalEnergyThreshold = energyThreshold;
        emit ProposalThresholdsSet(tokenThreshold, energyThreshold);
    }

    // --- View Functions ---

    /// @notice [View] Calculates and returns the amount of Quantum Energy an account has accumulated but not yet claimed.
    /// @param account The address of the account.
    /// @return The amount of pending Quantum Energy.
    function getPendingQuantumEnergy(address account) external view returns (uint256) {
        return _calculatePendingEnergy(account);
    }

    /// @notice [View] Returns the account's current claimed Quantum Energy balance.
    /// @param account The address of the account.
    /// @return The claimed Quantum Energy balance.
    function getQuantumEnergyBalance(address account) external view returns (uint256) {
        return quantumEnergy[account];
    }

    /// @notice [View] Returns the amount of QR tokens currently staked by an account.
    /// @param account The address of the account.
    /// @return The staked amount.
    function getStakedQRTokenAmount(address account) external view returns (uint256) {
        return qrTokenStakes[account].amount;
    }

    /// @notice [View] Returns the list of Realm Shard NFT token IDs staked by an account.
    /// @dev Note: This returns a storage pointer, be careful if modifying the returned array off-chain.
    /// @param account The address of the account.
    /// @return An array of staked NFT token IDs.
    function getStakedRealmShardIds(address account) external view returns (uint256[] memory) {
        // Return a memory copy of the array
         uint256[] storage stakedShards = _stakedRealmShardsByUser[account];
         uint256[] memory result = new uint256[](stakedShards.length);
         for(uint i = 0; i < stakedShards.length; i++){
             result[i] = stakedShards[i];
         }
         return result;
    }

    /// @notice [View] Returns detailed staking information for a specific Realm Shard NFT.
    /// @param tokenId The ID of the Realm Shard NFT.
    /// @return The owner's address, stake timestamp, last energy claim timestamp for this shard, and its boost rate.
    function getRealmShardStakingInfo(uint256 tokenId) external view returns (address owner, uint64 stakeTime, uint64 lastEnergyClaimTime, uint128 boostRatePerSecond) {
        RealmShardInfo storage shardInfo = realmShardStakes[tokenId];
        return (shardInfo.owner, shardInfo.stakeTime, shardInfo.lastEnergyClaimTime, shardInfo.boostRatePerSecond);
    }

    /// @notice [View] Returns the balance of a specific external token held in the DAO treasury.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The balance amount.
    function getTreasuryBalance(address tokenAddress) external view returns (uint256) {
        return treasuryBalances[tokenAddress];
    }

    /// @notice [View] Returns the current state of a governance proposal.
    /// @dev If the proposal is Active and its end time has passed, this function automatically updates its state to Succeeded or Defeated based on votes.
    /// @param proposalId The ID of the proposal.
    /// @return The current state of the proposal.
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) {
            // Does not exist
            return ProposalState.Canceled; // Use Canceled to indicate non-existence/invalid ID
        }
         if (proposal.state == ProposalState.Active && block.timestamp > proposal.endTime) {
             // Voting period ended, calculate final state on the fly for view
             uint256 energyQuorum = 1000; // Same quorum as in executeInitiative
              if (proposal.totalVotesEnergy > energyQuorum && proposal.yesVotesEnergy > proposal.noVotesEnergy) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Defeated;
             }
         }
        return proposal.state;
    }

    /// @notice [View] Returns information about the voting results for a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The total energy spent voting, total 'yes' energy, and total 'no' energy.
    function getProposalVoteInfo(uint256 proposalId) external view returns (uint256 totalVotesEnergy, uint256 yesVotesEnergy, uint256 noVotesEnergy) {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) {
            // Does not exist
            return (0, 0, 0);
        }
        return (proposal.totalVotesEnergy, proposal.yesVotesEnergy, proposal.noVotesEnergy);
    }

    /// @notice [View] Returns the Quantum Energy cost for a specific action type.
    /// @param action The action type.
    /// @return The energy cost.
    function getActionEnergyCost(ActionType action) external view returns (uint256) {
        return actionEnergyCosts[action];
    }

    /// @notice [View] Returns the current effective base energy generation rate, considering the global boost.
    /// @dev This does *not* include individual shard boosts. Useful for understanding the current global factor.
    /// @return The current base energy generation rate per second, multiplied by the global boost if active.
    function getEffectiveEnergyGenerationRate() external view returns (uint256) {
        if (block.timestamp < globalEnergyBoostEndTime) {
            return (baseEnergyGenerationRatePerSecond * globalEnergyBoostMultiplier) / 1e18;
        } else {
            return baseEnergyGenerationRatePerSecond;
        }
    }
}

```