Okay, here is a smart contract in Solidity focusing on a unique dynamic resource and strategy system with built-in governance and a reputation-like score. It aims to be distinct from standard token/NFT/DAO templates by integrating these concepts tightly around a core loop of resource generation/decay and strategic actions influenced by dynamic parameters controlled by governance.

**Concept:** **ChronoForge Protocol**

A decentralized protocol managing a scarce resource called "ChronoEssence". Users accrue ChronoEssence over time based on their "TemporalAlignment" (a reputation/participation score) and dynamic protocol parameters. They can spend ChronoEssence on strategic actions that modify their TemporalAlignment, accrue further benefits, or interact with other users. Key protocol parameters (like essence generation rate, alignment decay rate, action costs/benefits) are dynamically adjusted through on-chain governance, where voting power is linked to ChronoEssence holdings with a custom delegation mechanism.

**Advanced Concepts & Features:**

1.  **Dynamic Parameters:** Core protocol values are stored and mutable via governance, not fixed constants.
2.  **Time-Based Resource Accrual:** ChronoEssence is generated over time, calculated based on user's state (`lastSyncTimestamp`) and dynamic rates.
3.  **TemporalAlignment (Reputation):** A score that influences essence accrual and is affected by strategic actions and time-based decay.
4.  **Strategic Actions:** Defined actions with specific costs (Essence), effects (Alignment change, resource generation activation), cooldowns, and yields, configurable via governance.
5.  **On-Chain Governance over Dynamics:** Users holding ChronoEssence can propose changes to dynamic parameters and vote.
6.  **Custom Voting Delegation:** Users can delegate their ChronoEssence-based voting power to another address.
7.  **User State Synchronization:** Users' time-dependent state (essence accrual, alignment decay) is updated upon interaction or via helper sync functions callable by anyone (paying gas).
8.  **Internal Balance System:** ChronoEssence is managed internally within the contract, not as a standard ERC-20 (though it could potentially integrate one later), simplifying interactions and potentially gas costs for internal transfers/deductions.
9.  **Action Cooldowns:** Prevents spamming specific actions.
10. **Parameter Hashing:** Uses `bytes32` hashes to identify dynamic parameters generically.

---

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoForge Protocol
 * @dev A dynamic resource and strategy protocol with governance over dynamic parameters.
 * Users manage ChronoEssence resource and TemporalAlignment reputation score.
 * Time-based mechanics and strategic actions influence user state.
 * Protocol parameters are controlled via on-chain governance.
 */
contract ChronoForge {

    // --- State Variables ---
    // Core user state (Essence balance, Alignment score, time tracking, action states)
    // Dynamic protocol parameters
    // Action definitions
    // Governance proposals and voting state
    // Delegation mapping

    // --- Events ---
    // Signaling key state changes and actions (Essence transfer, Alignment update, Proposal, Vote, Parameter Change)

    // --- Data Structures ---
    // Structs for User, ActionState, ActionDefinition, DynamicParameter, Proposal

    // --- Modifiers ---
    // Access control (e.g., onlyOwner, onlyGovernor - or check within function for governance)
    // State checks (e.g., requires essence, requires cooldown, requires proposal active)

    // --- Constructor ---
    // Initializes owner, initial dynamic parameters, initial action definitions

    // --- Core State Views (Read-Only) ---
    // 1. getUserEssenceBalance(address user)
    // 2. getUserTemporalAlignment(address user)
    // 3. getProtocolEssenceSupply()
    // 4. getCurrentEpoch()
    // 5. getDynamicParameter(bytes32 paramNameHash)
    // 6. getActionDefinition(uint256 actionId)
    // 7. getUserActionState(address user, uint256 actionId)
    // 8. getTotalStakedEssence()
    // 9. getUserStakedEssence(address user)

    // --- User Actions (State-Changing) ---
    // 10. claimEssence() - Claims accrued essence and applies time-based alignment decay
    // 11. performAction_ForgeNode() - Example strategic action: Initiate time-based essence generation
    // 12. performAction_AlignFlux() - Example strategic action: Boost alignment with potential risk/cost
    // 13. performAction_StakeAnchor(uint256 amount) - Example strategic action: Stake essence for rewards/alignment
    // 14. performAction_UnstakeAnchor() - Example strategic action: Unstake essence
    // 15. performAction_SyncPattern(address targetUser) - Example strategic action: Interact strategically with another user's state
    // 16. burnEssence(uint256 amount) - User voluntarily burns essence

    // --- Governance Actions (State-Changing) ---
    // 17. proposeParameterChange(bytes32 paramNameHash, uint256 newValue) - Create a new governance proposal
    // 18. voteOnProposal(bytes32 proposalHash, bool support) - Cast a vote on a proposal (by self)
    // 19. voteForProposal(address delegator, bytes32 proposalHash, bool support) - Cast a vote on behalf of a delegator
    // 20. executeProposal(bytes32 proposalHash) - Execute a successful proposal
    // 21. cancelProposal(bytes32 proposalHash) - Cancel a proposal (if conditions met)

    // --- Governance Views (Read-Only) ---
    // 22. getProposalDetails(bytes32 proposalHash)
    // 23. getProposalVoteCount(bytes32 proposalHash)
    // 24. getVoterVote(bytes32 proposalHash, address voter) - Check direct vote
    // 25. getProposalVotePowerUsed(bytes32 proposalHash, address voter) - Check voting power used by a direct voter or delegatee on behalf of user

    // --- Utility & Delegation ---
    // 26. syncUserTimedState(address user) - Public helper to trigger timed state updates for a user
    // 27. syncBatchUserTimedStates(address[] users) - Public helper to batch trigger timed state updates
    // 28. getActionName(uint256 actionId) - Get human-readable name for action ID
    // 29. getTotalProposals() - Get total number of proposals
    // 30. getLatestExecutedParameterValue(bytes32 paramNameHash) - Get value of a param set by last successful proposal
    // 31. delegateVoting(address delegatee_) - Delegate voting power
    // 32. getDelegatedVotingFor(address user) - Check who a user delegated to

    // --- Internal Functions ---
    // _updateUserTimedState(address user) - Handles essence accrual and alignment decay
    // _calculateEssenceAccrual(address user, uint256 duration)
    // _applyAlignmentDecay(address user, uint256 duration)
    // _applyEssenceCost(address user, uint256 amount)
    // _addEssence(address user, uint256 amount)
    // _updateUserActionTimestamp(address user, uint256 actionId)
    // _calculateVotingPower(address user, bytes32 proposalHash) - Calculate power for a user based on snapshot/current state
    // (And other helpers for action execution, parameter updates, proposal state checks)
}
```

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial setup, governance takes over dynamic control

// Note: In a real advanced contract, you might use fixed-point math libraries for rates and decay
// or scale integers significantly to avoid floating-point issues. Using uint256 directly here for simplicity.

contract ChronoForge is Ownable {
    using SafeMath for uint256;

    // --- Constants & Configuration ---
    uint256 public constant EPOCH_DURATION_BLOCKS = 100; // Define epoch length in blocks
    uint256 public constant MIN_ALIGNMENT = 0;
    uint256 public constant MAX_ALIGNMENT = 10000; // Alignment is scaled (e.g., 100.00 is 10000)
    uint256 public constant ALIGNMENT_SCALE = 100; // For displaying 2 decimal places

    // Governance Parameters
    uint256 public constant PROPOSAL_VOTING_PERIOD_EPOCHS = 5; // How long voting lasts
    uint256 public constant PROPOSAL_MIN_VOTING_POWER_PERCENT = 5; // Min % of total essence supply needed to pass (simplified check)

    // Action IDs (Arbitrary mapping for demonstration)
    uint256 public constant ACTION_FORGE_NODE = 1;
    uint256 public constant ACTION_ALIGN_FLUX = 2;
    uint256 public constant ACTION_STAKE_ANCHOR = 3;
    uint256 public constant ACTION_UNSTAKE_ANCHOR = 4;
    uint256 public constant ACTION_SYNC_PATTERN = 5;


    // --- State Variables ---

    address public protocolFeeRecipient; // Address to receive any protocol fees (set by governance)
    uint256 public totalProtocolEssence; // Total ChronoEssence in the system (sum of user balances and staked)
    uint256 public totalStakedEssence; // Total ChronoEssence staked in Anchor action

    struct User {
        uint256 essenceBalance;
        uint256 temporalAlignment; // Scaled by ALIGNMENT_SCALE
        uint256 lastSyncBlock; // Block number of last state update
        mapping(uint256 => ActionState) actionStates;
    }
    mapping(address => User) private users;

    struct ActionState {
        uint256 lastPerformedBlock;
        uint256 accruedYield; // For actions that generate yield over time
        uint256 stakedAmount; // For staking actions
    }

    struct ActionDefinition {
        uint256 id;
        string name;
        uint256 essenceCost;
        int256 alignmentEffect; // Can be positive or negative (scaled by ALIGNMENT_SCALE)
        uint256 cooldownBlocks; // Cooldown duration in blocks
        // Add other action-specific params here (e.g., yield rate ID, target type, etc.)
    }
    // Action definitions are also dynamic parameters potentially, but defined separately for clarity
    mapping(uint256 => ActionDefinition) private actionDefinitions;

    struct DynamicParameter {
        uint256 value; // Current value of the parameter
        // Add historical tracking if needed (e.g., uint256 lastUpdatedBlock)
    }
    // Using bytes32 hash of parameter name as key (e.g., keccak256("ESSENCE_GENERATION_RATE"))
    mapping(bytes32 => DynamicParameter) private dynamicParameters;
    bytes32[] private dynamicParameterNames; // To list available parameters

    // Example Parameter Name Hashes
    bytes32 public constant PARAM_ESSENCE_GENERATION_RATE_PER_EPOCH = keccak256("ESSENCE_GENERATION_RATE_PER_EPOCH");
    bytes32 public constant PARAM_ALIGNMENT_DECAY_RATE_PER_EPOCH = keccak256("ALIGNMENT_DECAY_RATE_PER_EPOCH");
    bytes32 public constant PARAM_ACTION_FORGE_NODE_YIELD_RATE_PER_EPOCH = keccak256("ACTION_FORGE_NODE_YIELD_RATE_PER_EPOCH");
    bytes32 public constant PARAM_STAKE_ANCHOR_REWARD_RATE_PER_EPOCH = keccak256("PARAM_STAKE_ANCHOR_REWARD_RATE_PER_EPOCH");
    bytes32 public constant PARAM_GOVERNANCE_EXECUTION_THRESHOLD_PERCENT = keccak256("PARAM_GOVERNANCE_EXECUTION_THRESHOLD_PERCENT");


    struct Proposal {
        bytes32 paramNameHash; // Parameter to change
        uint256 newValue; // New value proposed
        uint256 proposer; // Index of proposer? Or address? Let's use address.
        address proposerAddress;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        bool canceled;
        uint256 forVotes; // Total voting power for the proposal
        uint256 againstVotes; // Total voting power against
        // Mapping to track which addresses (or their delegates) have voted
        mapping(address => bool) hasVoted; // Tracks if a voting address (self or delegatee casting for self) has voted
        mapping(address => bool) hasVotedForDelegator; // Tracks if a delegatee voted for a specific delegator (address -> delegator -> voted)
        // Note: Tracking votes for each delegator efficiently requires more complex state or different voting mechanism
        // Simplified: We only track if the *account casting the vote* (self or delegatee) has cast *a* vote related to their power.
        // The vote counting logic will need to resolve delegation.
    }
    mapping(bytes32 => Proposal) private proposals;
    bytes32[] private activeProposals; // List of current proposals
    uint256 private proposalCounter; // Unique ID for proposals

    // Voting Delegation: user => who they delegated their voting right to
    mapping(address => address) public votingDelegatee;


    // --- Events ---

    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceBurned(address indexed user, uint256 amount);
    event AlignmentUpdated(address indexed user, uint256 newAlignment);
    event TimedStateSynced(address indexed user, uint256 essenceAccrued, int256 alignmentChange, uint256 syncedBlock);
    event ActionPerformed(address indexed user, uint256 actionId, bytes data);
    event ParameterProposed(bytes32 indexed proposalHash, bytes32 indexed paramNameHash, uint256 newValue, address indexed proposer, uint256 startBlock, uint256 endBlock);
    event ParameterVoted(bytes32 indexed proposalHash, address indexed voter, bool support, uint256 votingPowerUsed);
    event ParameterExecuted(bytes32 indexed proposalHash, bytes32 indexed paramNameHash, uint256 newValue);
    event ProposalCanceled(bytes32 indexed proposalHash);
    event VotingDelegated(address indexed delegator, address indexed delegatee);
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);

    // --- Constructor ---

    constructor(address initialFeeRecipient) Ownable(msg.sender) {
        protocolFeeRecipient = initialFeeRecipient;

        // Initialize some starting dynamic parameters
        _setDynamicParameter(PARAM_ESSENCE_GENERATION_RATE_PER_EPOCH, 10 * 1e18); // 10 Essence per epoch base rate (using 18 decimals scale internally)
        _setDynamicParameter(PARAM_ALIGNMENT_DECAY_RATE_PER_EPOCH, 10 * ALIGNMENT_SCALE); // 10 alignment decay per epoch base rate
        _setDynamicParameter(PARAM_ACTION_FORGE_NODE_YIELD_RATE_PER_EPOCH, 5 * 1e18); // 5 Essence per epoch yield
        _setDynamicParameter(PARAM_STAKE_ANCHOR_REWARD_RATE_PER_EPOCH, 2 * 1e18); // 2 Essence per epoch reward per unit staked (scaled)
        _setDynamicParameter(PARAM_GOVERNANCE_EXECUTION_THRESHOLD_PERCENT, 5 * 1e18); // 5% threshold (scaled)

        // Initialize action definitions
        actionDefinitions[ACTION_FORGE_NODE] = ActionDefinition(ACTION_FORGE_NODE, "Forge Node", 50 * 1e18, 50 * ALIGNMENT_SCALE, EPOCH_DURATION_BLOCKS * 2); // Cost 50E, +50 Alignment, 2 epoch cooldown
        actionDefinitions[ACTION_ALIGN_FLUX] = ActionDefinition(ACTION_ALIGN_FLUX, "Align Flux", 20 * 1e18, 150 * ALIGNMENT_SCALE, EPOCH_DURATION_BLOCKS / 2); // Cost 20E, +150 Alignment, 0.5 epoch cooldown
        actionDefinitions[ACTION_STAKE_ANCHOR] = ActionDefinition(ACTION_STAKE_ANCHOR, "Stake Anchor", 0, 10 * ALIGNMENT_SCALE, 0); // Cost 0, +10 Alignment initially, no cooldown (managed by stake/unstake)
        actionDefinitions[ACTION_UNSTAKE_ANCHOR] = ActionDefinition(ACTION_UNSTAKE_ANCHOR, "Unstake Anchor", 0, -20 * ALIGNMENT_SCALE, 0); // Cost 0, -20 Alignment, no cooldown
        actionDefinitions[ACTION_SYNC_PATTERN] = ActionDefinition(ACTION_SYNC_PATTERN, "Sync Pattern", 10 * 1e18, 0, EPOCH_DURATION_BLOCKS); // Cost 10E, 0 Alignment effect, 1 epoch cooldown (effect handled internally)

        // Note: Initial ChronoEssence distribution or minting mechanism would be needed.
        // For this example, users start with 0 and must gain it via the protocol.
        // A 'mintInitialUserEssence(address user, uint256 amount)' function restricted to owner could be added initially.
    }

    // --- Internal Helpers ---

    /**
     * @dev Gets or creates a user's state object.
     * @param user The address of the user.
     * @return Reference to the user's state.
     */
    function _getUser(address user) private view returns (User storage) {
        // Note: This pattern requires users to exist in the mapping.
        // A more robust approach might initialize user state upon first interaction.
        // For simplicity, assume users implicitly exist after some initial interaction or distribution.
        // If users can start with 0 and interact, the mapping access is fine.
        return users[user];
    }

    /**
     * @dev Calculates and updates user's time-dependent state (essence accrual, alignment decay).
     * Should be called before any action that depends on current state.
     * @param user The address of the user.
     */
    function _updateUserTimedState(address user) internal {
        User storage u = users[user]; // Access directly after potential check elsewhere or assume existence
        uint256 currentBlock = block.number;
        uint256 lastSyncBlock = u.lastSyncBlock == 0 ? block.number : u.lastSyncBlock; // Sync from current block if never synced
        uint256 blocksPassed = currentBlock.sub(lastSyncBlock);

        if (blocksPassed == 0) {
            return; // Nothing to update
        }

        uint256 syncedEpochs = blocksPassed.div(EPOCH_DURATION_BLOCKS);
        uint256 remainingBlocks = blocksPassed.mod(EPOCH_DURATION_BLOCKS);

        // Calculate Essence Accrual
        uint256 essenceAccrued = _calculateEssenceAccrual(user, syncedEpochs);
        _addEssence(user, essenceAccrued);

        // Apply Alignment Decay
        int256 alignmentChange = _applyAlignmentDecay(user, syncedEpochs);

        // Update Action Yields for time-based actions (e.g., Forge Node, Stake Anchor)
        _updateActionYields(user, blocksPassed);

        // Update last sync block to account for full epochs and remaining blocks
        u.lastSyncBlock = currentBlock; // Simplistic: syncs fully to current block

        emit TimedStateSynced(user, essenceAccrued, alignmentChange, currentBlock);
    }

     /**
     * @dev Calculates essence accrued based on time and alignment.
     * @param user The address of the user.
     * @param epochsPassed Number of epochs passed since last calculation.
     * @return The amount of essence accrued.
     */
    function _calculateEssenceAccrual(address user, uint256 epochsPassed) internal view returns (uint256) {
        if (epochsPassed == 0) return 0;

        User storage u = users[user];
        uint256 baseRate = dynamicParameters[PARAM_ESSENCE_GENERATION_RATE_PER_EPOCH].value;

        // Example logic: Accrual rate is base rate influenced by alignment
        // (Alignment / Max Alignment) * baseRate * epochs
        // Need to handle scaling ALIGNMENT_SCALE
        uint256 alignmentFactor = u.temporalAlignment.mul(1e18).div(MAX_ALIGNMENT); // Scale alignment to 1e18 base
        uint256 accrualPerEpoch = baseRate.mul(alignmentFactor).div(1e18); // Apply alignment factor

        return accrualPerEpoch.mul(epochsPassed);
    }

    /**
     * @dev Applies alignment decay based on time.
     * @param user The address of the user.
     * @param epochsPassed Number of epochs passed since last calculation.
     * @return The change in alignment.
     */
    function _applyAlignmentDecay(address user, uint256 epochsPassed) internal returns (int256) {
         if (epochsPassed == 0) return 0;

        User storage u = users[user];
        uint256 decayRate = dynamicParameters[PARAM_ALIGNMENT_DECAY_RATE_PER_EPOCH].value;

        uint256 decayAmount = decayRate.mul(epochsPassed); // Simple linear decay per epoch

        int256 initialAlignment = int256(u.temporalAlignment);
        int256 newAlignment = initialAlignment.sub(int256(decayAmount));

        // Ensure alignment stays within bounds
        if (newAlignment < int256(MIN_ALIGNMENT)) {
            newAlignment = int256(MIN_ALIGNMENT);
        }
        u.temporalAlignment = uint256(newAlignment);

        emit AlignmentUpdated(user, u.temporalAlignment);
        return newAlignment.sub(initialAlignment);
    }

    /**
     * @dev Updates yields for timed actions (e.g., staking rewards, forging).
     * @param user The address of the user.
     * @param blocksPassed The number of blocks passed since last sync.
     */
    function _updateActionYields(address user, uint256 blocksPassed) internal {
        // Example: Update yield for Forge Node
        ActionState storage forgeNodeState = users[user].actionStates[ACTION_FORGE_NODE];
        if (forgeNodeState.lastPerformedBlock > 0 && forgeNodeState.stakedAmount == 0) { // Only accrues if active and not "staked" (stakedAmount used here to indicate active timed action)
            uint256 blocksSinceLastUpdate = blocksPassed; // simplified: use total blocks passed for sync
            uint256 epochsSinceLastUpdate = blocksSinceLastUpdate.div(EPOCH_DURATION_BLOCKS);
            if (epochsSinceLastUpdate > 0) {
                 uint256 yieldRate = dynamicParameters[PARAM_ACTION_FORGE_NODE_YIELD_RATE_PER_EPOCH].value;
                 forgeNodeState.accruedYield = forgeNodeState.accruedYield.add(yieldRate.mul(epochsSinceLastUpdate));
            }
        }

        // Example: Update yield for Stake Anchor
        ActionState storage stakeAnchorState = users[user].actionStates[ACTION_STAKE_ANCHOR];
        if (stakeAnchorState.stakedAmount > 0) { // Accrues if essence is staked
             uint256 blocksSinceLastUpdate = blocksPassed;
             uint256 epochsSinceLastUpdate = blocksSinceLastUpdate.div(EPOCH_DURATION_BLOCKS);
             if (epochsSinceLastUpdate > 0) {
                uint256 rewardRate = dynamicParameters[PARAM_STAKE_ANCHOR_REWARD_RATE_PER_EPOCH].value;
                // Reward scales with staked amount (simple linear scale)
                uint256 rewardsAccrued = stakeAnchorState.stakedAmount.mul(rewardRate).mul(epochsSinceLastUpdate).div(1e18); // Need careful scaling
                stakeAnchorState.accruedYield = stakeAnchorState.accruedYield.add(rewardsAccrued);
             }
        }
    }


    /**
     * @dev Deducts essence from user balance.
     * @param user The address of the user.
     * @param amount The amount of essence to deduct.
     */
    function _applyEssenceCost(address user, uint256 amount) internal {
        User storage u = users[user];
        require(u.essenceBalance >= amount, "ChronoForge: Insufficient essence");
        u.essenceBalance = u.essenceBalance.sub(amount);
        emit EssenceTransferred(user, address(0), amount); // Signal burn or cost
    }

    /**
     * @dev Adds essence to user balance.
     * @param user The address of the user.
     * @param amount The amount of essence to add.
     */
    function _addEssence(address user, uint256 amount) internal {
        User storage u = users[user];
        u.essenceBalance = u.essenceBalance.add(amount);
        emit EssenceTransferred(address(0), user, amount); // Signal mint or gain
    }

    /**
     * @dev Updates the last performed block for an action.
     * @param user The address of the user.
     * @param actionId The ID of the action.
     */
    function _updateUserActionTimestamp(address user, uint256 actionId) internal {
        users[user].actionStates[actionId].lastPerformedBlock = block.number;
    }

    /**
     * @dev Sets a dynamic parameter value. Internal, used by constructor and governance execution.
     * @param paramNameHash The hash of the parameter name.
     * @param newValue The new value for the parameter.
     */
    function _setDynamicParameter(bytes32 paramNameHash, uint256 newValue) internal {
        // Check if parameter exists, add if not (only allowed in constructor or specific governance actions)
        bool exists = false;
        for(uint i = 0; i < dynamicParameterNames.length; i++) {
            if (dynamicParameterNames[i] == paramNameHash) {
                exists = true;
                break;
            }
        }
        if (!exists && block.number != 0) { // Allow adding only in constructor (block.number 0 check is heuristic) or specific setup phase
             // In a real system, adding new params via governance would be a distinct proposal type
             revert("ChronoForge: Cannot add new parameters after initialization");
        } else if (!exists) { // Only in constructor
             dynamicParameterNames.push(paramNameHash);
        }

        dynamicParameters[paramNameHash].value = newValue;
        // Maybe add an event here? ParameterUpdated(paramNameHash, newValue);
    }

    /**
     * @dev Calculates the voting power for a user on a specific proposal.
     * Simplified: Based on current essence balance. Delegation is handled in vote casting.
     * @param user The address of the user.
     * @param proposalHash The hash of the proposal (can be ignored in this simple model).
     * @return The voting power.
     */
    function _calculateVotingPower(address user, bytes32 proposalHash) internal view returns (uint256) {
        // For simplicity, voting power is current essence balance.
        // More advanced: snapshot balance at proposal creation, include staked amount, etc.
        return users[user].essenceBalance;
    }

    // --- Core State Views ---

    /**
     * @dev Gets the ChronoEssence balance for a user.
     * @param user The address of the user.
     * @return The user's essence balance.
     */
    function getUserEssenceBalance(address user) external view returns (uint256) {
        return users[user].essenceBalance;
    }

    /**
     * @dev Gets the TemporalAlignment score for a user.
     * @param user The address of the user.
     * @return The user's temporal alignment (scaled).
     */
    function getUserTemporalAlignment(address user) external view returns (uint256) {
        return users[user].temporalAlignment;
    }

    /**
     * @dev Gets the total ChronoEssence supply in the protocol.
     * Note: This requires summing up all balances + staked + in protocol pools.
     * Keeping track in `totalProtocolEssence` state variable.
     * @return The total protocol essence supply.
     */
    function getProtocolEssenceSupply() external view returns (uint256) {
        // This state variable needs to be maintained whenever essence enters/leaves the protocol
        // (mint, burn, fees, user deposits/withdrawals if applicable).
        // In this contract, essence is only 'minted' via claimEssence.
        // Need to update totalProtocolEssence in _addEssence and _applyEssenceCost/burnEssence.
        return totalProtocolEssence;
    }

    /**
     * @dev Gets the current protocol epoch based on block number.
     * @return The current epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return block.number.div(EPOCH_DURATION_BLOCKS);
    }

    /**
     * @dev Gets the current value of a dynamic parameter.
     * @param paramNameHash The hash of the parameter name.
     * @return The current value.
     */
    function getDynamicParameter(bytes32 paramNameHash) external view returns (uint256) {
        return dynamicParameters[paramNameHash].value;
    }

    /**
     * @dev Gets the definition details for a specific action ID.
     * @param actionId The ID of the action.
     * @return The ActionDefinition struct.
     */
    function getActionDefinition(uint256 actionId) external view returns (ActionDefinition memory) {
        return actionDefinitions[actionId];
    }

    /**
     * @dev Gets the current state of a specific action for a user.
     * @param user The address of the user.
     * @param actionId The ID of the action.
     * @return The ActionState struct.
     */
    function getUserActionState(address user, uint256 actionId) external view returns (ActionState memory) {
        return users[user].actionStates[actionId];
    }

     /**
     * @dev Gets the total amount of essence currently staked in the Anchor action across all users.
     * @return The total staked essence.
     */
    function getTotalStakedEssence() external view returns (uint256) {
        return totalStakedEssence;
    }

    /**
     * @dev Gets the amount of essence currently staked by a specific user in the Anchor action.
     * @param user The address of the user.
     * @return The user's staked essence amount.
     */
    function getUserStakedEssence(address user) external view returns (uint256) {
        return users[user].actionStates[ACTION_STAKE_ANCHOR].stakedAmount;
    }


    // --- User Actions ---

    /**
     * @dev Allows a user to claim accrued essence and update their time-dependent state.
     */
    function claimEssence() external {
        _updateUserTimedState(msg.sender);
        // Yield from timed actions like Forge Node and Stake Anchor is accrued in actionStates.accruedYield
        // Claiming this yield could be part of this function or separate 'claimYield' functions.
        // Let's make it part of the sync/claim process for simplicity.
        User storage u = users[msg.sender];
        uint256 totalYield = 0;
        // Claim yield from Forge Node
        if (u.actionStates[ACTION_FORGE_NODE].accruedYield > 0) {
            uint256 forgeYield = u.actionStates[ACTION_FORGE_NODE].accruedYield;
            totalYield = totalYield.add(forgeYield);
            u.actionStates[ACTION_FORGE_NODE].accruedYield = 0;
        }
        // Claim yield from Stake Anchor
         if (u.actionStates[ACTION_STAKE_ANCHOR].accruedYield > 0) {
            uint256 stakeYield = u.actionStates[ACTION_STAKE_ANCHOR].accruedYield;
            totalYield = totalYield.add(stakeYield);
            u.actionStates[ACTION_STAKE_ANCHOR].accruedYield = 0;
        }

        if (totalYield > 0) {
            _addEssence(msg.sender, totalYield);
        }
        // Essence from base generation is added within _updateUserTimedState
    }

    /**
     * @dev Performs the Forge Node strategic action.
     * Cost: Essence. Effect: Boosts alignment, starts timed essence generation.
     */
    function performAction_ForgeNode() external {
        _updateUserTimedState(msg.sender); // Sync state before action
        ActionDefinition storage actionDef = actionDefinitions[ACTION_FORGE_NODE];
        ActionState storage userActionState = users[msg.sender].actionStates[ACTION_FORGE_NODE];

        require(block.number >= userActionState.lastPerformedBlock.add(actionDef.cooldownBlocks), "ChronoForge: Action is on cooldown");
        _applyEssenceCost(msg.sender, actionDef.essenceCost);

        // Apply alignment effect
        int256 currentAlignment = int256(users[msg.sender].temporalAlignment);
        int256 newAlignment = currentAlignment.add(actionDef.alignmentEffect);
         if (newAlignment > int256(MAX_ALIGNMENT)) newAlignment = int256(MAX_ALIGNMENT);
         if (newAlignment < int256(MIN_ALIGNMENT)) newAlignment = int256(MIN_ALIGNMENT);
        users[msg.sender].temporalAlignment = uint256(newAlignment);
        emit AlignmentUpdated(msg.sender, users[msg.sender].temporalAlignment);


        // Mark action as performed and activate timed yield (stakedAmount > 0 indicates active for this action)
        _updateUserActionTimestamp(msg.sender, ACTION_FORGE_NODE);
        userActionState.stakedAmount = 1; // Sentinel value to indicate active state, not actual stake

        emit ActionPerformed(msg.sender, ACTION_FORGE_NODE, "");
    }

     /**
     * @dev Performs the Align Flux strategic action.
     * Cost: Essence. Effect: Significant alignment boost, but maybe higher alignment decay risk? (Not implemented here)
     */
    function performAction_AlignFlux() external {
         _updateUserTimedState(msg.sender); // Sync state before action
        ActionDefinition storage actionDef = actionDefinitions[ACTION_ALIGN_FLUX];
        ActionState storage userActionState = users[msg.sender].actionStates[ACTION_ALIGN_FLUX];

        require(block.number >= userActionState.lastPerformedBlock.add(actionDef.cooldownBlocks), "ChronoForge: Action is on cooldown");
        _applyEssenceCost(msg.sender, actionDef.essenceCost);

        // Apply alignment effect
        int256 currentAlignment = int256(users[msg.sender].temporalAlignment);
        int256 newAlignment = currentAlignment.add(actionDef.alignmentEffect);
         if (newAlignment > int256(MAX_ALIGNMENT)) newAlignment = int256(MAX_ALIGNMENT);
         if (newAlignment < int256(MIN_ALIGNMENT)) newAlignment = int256(MIN_ALIGNMENT);
        users[msg.sender].temporalAlignment = uint256(newAlignment);
        emit AlignmentUpdated(msg.sender, users[msg.sender].temporalAlignment);

        _updateUserActionTimestamp(msg.sender, ACTION_ALIGN_FLUX);

        emit ActionPerformed(msg.sender, ACTION_ALIGN_FLUX, "");
    }

     /**
     * @dev Performs the Stake Anchor strategic action.
     * Cost: Transfer essence into stake. Effect: Boosts alignment, starts timed staking rewards.
     * @param amount The amount of essence to stake.
     */
    function performAction_StakeAnchor(uint256 amount) external {
         _updateUserTimedState(msg.sender); // Sync state before action
        ActionDefinition storage actionDef = actionDefinitions[ACTION_STAKE_ANCHOR];
        ActionState storage userActionState = users[msg.sender].actionStates[ACTION_STAKE_ANCHOR];

        require(amount > 0, "ChronoForge: Must stake a positive amount");
        // No cooldown check, staking is managing a position

        // Apply alignment effect (only on initial stake or significant increase?)
        // Let's apply it linearly based on amount staked for simplicity
        int256 alignmentEffect = actionDef.alignmentEffect; // Base alignment effect per stake action call?
        // Or scale alignment effect by amount staked? e.g., (amount / 1e18) * baseEffect?
        // Let's use the base effect per call, and rewards are amount-scaled.
        int256 currentAlignment = int256(users[msg.sender].temporalAlignment);
        int256 newAlignment = currentAlignment.add(alignmentEffect);
         if (newAlignment > int256(MAX_ALIGNMENT)) newAlignment = int256(MAX_ALIGNMENT);
         if (newAlignment < int256(MIN_ALIGNMENT)) newAlignment = int256(MIN_ALIGNMENT);
        users[msg.sender].temporalAlignment = uint256(newAlignment);
        emit AlignmentUpdated(msg.sender, users[msg.sender].temporalAlignment);

        // Transfer essence to the protocol's stake pool (internal transfer)
        _applyEssenceCost(msg.sender, amount);
        userActionState.stakedAmount = userActionState.stakedAmount.add(amount);
        totalStakedEssence = totalStakedEssence.add(amount);

        _updateUserActionTimestamp(msg.sender, ACTION_STAKE_ANCHOR); // Mark last stake/unstake time for yield calcs

        emit ActionPerformed(msg.sender, ACTION_STAKE_ANCHOR, abi.encode(amount));
    }

     /**
     * @dev Performs the Unstake Anchor strategic action.
     * Cost: None. Effect: Reduces alignment, returns staked essence.
     */
    function performAction_UnstakeAnchor() external {
         _updateUserTimedState(msg.sender); // Sync state before action
        ActionDefinition storage actionDef = actionDefinitions[ACTION_UNSTAKE_ANCHOR];
        ActionState storage userActionState = users[msg.sender].actionStates[ACTION_STAKE_ANCHOR]; // Unstaking affects the STAKE_ANCHOR state

        require(userActionState.stakedAmount > 0, "ChronoForge: No essence staked");

        uint256 amountToUnstake = userActionState.stakedAmount;

        // Apply alignment effect (negative)
        int256 currentAlignment = int256(users[msg.sender].temporalAlignment);
        int256 newAlignment = currentAlignment.add(actionDef.alignmentEffect); // Negative effect
         if (newAlignment > int256(MAX_ALIGNMENT)) newAlignment = int256(MAX_ALIGNMENT);
         if (newAlignment < int256(MIN_ALIGNMENT)) newAlignment = int256(MIN_ALIGNMENT);
        users[msg.sender].temporalAlignment = uint256(newAlignment);
        emit AlignmentUpdated(msg.sender, users[msg.sender].temporalAlignment);

        // Return staked essence
        userActionState.stakedAmount = 0; // Unstake all
        totalStakedEssence = totalStakedEssence.sub(amountToUnstake);
        _addEssence(msg.sender, amountToUnstake); // Return essence

        _updateUserActionTimestamp(msg.sender, ACTION_UNSTAKE_ANCHOR); // Mark time

        emit ActionPerformed(msg.sender, ACTION_UNSTAKE_ANCHOR, abi.encode(amountToUnstake));
    }

    /**
     * @dev Performs the Sync Pattern strategic action.
     * Cost: Essence. Effect: Interacts with another user's state (e.g., give them a temporary alignment boost, or drain a small amount of essence).
     * This is a creative/advanced action. Let's make it transfer a small amount of essence and give target a minor alignment boost.
     * @param targetUser The address of the user to target.
     */
    function performAction_SyncPattern(address targetUser) external {
        _updateUserTimedState(msg.sender); // Sync self
        _updateUserTimedState(targetUser); // Sync target user too

        ActionDefinition storage actionDef = actionDefinitions[ACTION_SYNC_PATTERN];
        ActionState storage userActionState = users[msg.sender].actionStates[ACTION_SYNC_PATTERN];

        require(msg.sender != targetUser, "ChronoForge: Cannot sync pattern with yourself");
        require(block.number >= userActionState.lastPerformedBlock.add(actionDef.cooldownBlocks), "ChronoForge: Action is on cooldown");
        _applyEssenceCost(msg.sender, actionDef.essenceCost);

        // Example effect: Transfer a small amount of essence (e.g., 10% of cost) to target
        uint256 transferAmount = actionDef.essenceCost.div(10);
        _addEssence(targetUser, transferAmount);

        // Example effect: Give target a minor alignment boost (e.g., 20 Alignment)
        uint256 alignmentBoost = 20 * ALIGNMENT_SCALE;
         int256 currentTargetAlignment = int256(users[targetUser].temporalAlignment);
        int256 newTargetAlignment = currentTargetAlignment.add(int256(alignmentBoost));
         if (newTargetAlignment > int256(MAX_ALIGNMENT)) newTargetAlignment = int256(MAX_ALIGNMENT);
         if (newTargetAlignment < int256(MIN_ALIGNMENT)) newTargetAlignment = int256(MIN_ALIGNMENT);
        users[targetUser].temporalAlignment = uint256(newTargetAlignment);
        emit AlignmentUpdated(targetUser, users[targetUser].temporalAlignment);


        _updateUserActionTimestamp(msg.sender, ACTION_SYNC_PATTERN);

        emit ActionPerformed(msg.sender, ACTION_SYNC_PATTERN, abi.encode(targetUser));
    }

    /**
     * @dev Allows a user to voluntarily burn essence.
     * Useful for deflationary mechanics or hypothetical in-game costs not tied to specific actions.
     * @param amount The amount of essence to burn.
     */
    function burnEssence(uint256 amount) external {
        require(amount > 0, "ChronoForge: Cannot burn zero");
         _updateUserTimedState(msg.sender); // Sync state before checking balance
        _applyEssenceCost(msg.sender, amount); // This handles the balance check
        totalProtocolEssence = totalProtocolEssence.sub(amount); // Update total supply

        emit EssenceBurned(msg.sender, amount);
    }


    // --- Governance Actions ---

    /**
     * @dev Allows a user to propose a change to a dynamic parameter.
     * Requires a certain amount of essence to prevent spam (not implemented here, but could be a cost).
     * @param paramNameHash The hash of the parameter name to change.
     * @param newValue The proposed new value.
     * @return The hash of the created proposal.
     */
    function proposeParameterChange(bytes32 paramNameHash, uint256 newValue) external returns (bytes32) {
        // Check if paramNameHash is valid (exists in dynamicParameterNames)
        bool paramExists = false;
         for(uint i = 0; i < dynamicParameterNames.length; i++) {
            if (dynamicParameterNames[i] == paramNameHash) {
                paramExists = true;
                break;
            }
        }
        require(paramExists, "ChronoForge: Invalid parameter name hash");

        // Optional: require minimum alignment or essence to propose
        // require(users[msg.sender].essenceBalance >= MIN_ESSENCE_TO_PROPOSE, "ChronoForge: Insufficient essence to propose");

        proposalCounter = proposalCounter.add(1);
        bytes32 proposalHash = keccak256(abi.encodePacked(paramNameHash, newValue, msg.sender, proposalCounter));

        uint256 startBlock = block.number;
        uint256 endBlock = startBlock.add(PROPOSAL_VOTING_PERIOD_EPOCHS.mul(EPOCH_DURATION_BLOCKS));

        proposals[proposalHash] = Proposal({
            paramNameHash: paramNameHash,
            newValue: newValue,
            proposer: proposalCounter, // Use counter as proposer ID if needed, address is clearer
            proposerAddress: msg.sender,
            startBlock: startBlock,
            endBlock: endBlock,
            executed: false,
            canceled: false,
            forVotes: 0,
            againstVotes: 0,
            hasVoted: new mapping(address => bool),
            hasVotedForDelegator: new mapping(address => bool) // Simplified, ideally maps delegatee -> delegator -> bool
        });

        activeProposals.push(proposalHash); // Add to active list

        emit ParameterProposed(proposalHash, paramNameHash, newValue, msg.sender, startBlock, endBlock);
        return proposalHash;
    }

    /**
     * @dev Allows a user (or their delegatee) to cast a vote on a proposal.
     * Voting power is based on the voter's (or delegator's) current ChronoEssence balance.
     * @param proposalHash The hash of the proposal.
     * @param support True for 'for', False for 'against'.
     */
    function voteOnProposal(bytes32 proposalHash, bool support) external {
        _updateUserTimedState(msg.sender); // Sync voter state

        Proposal storage proposal = proposals[proposalHash];
        require(proposal.proposerAddress != address(0), "ChronoForge: Proposal does not exist");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(!proposal.canceled, "ChronoForge: Proposal canceled");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "ChronoForge: Proposal voting period is not active");

        // Check if msg.sender has delegated out. If so, they cannot vote directly.
        require(votingDelegatee[msg.sender] == address(0) || votingDelegatee[msg.sender] == msg.sender, "ChronoForge: User has delegated voting power");

        // Check if this specific address has already voted
        require(!proposal.hasVoted[msg.sender], "ChronoForge: Address has already voted");

        // Get voting power for this direct vote
        uint256 votingPower = _calculateVotingPower(msg.sender, proposalHash);
        require(votingPower > 0, "ChronoForge: User has no voting power"); // Must have some essence to vote

        // Record the vote
        if (support) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votingPower);
        }

        // Mark this address as having voted directly
        proposal.hasVoted[msg.sender] = true;

        emit ParameterVoted(proposalHash, msg.sender, support, votingPower);
    }

    /**
     * @dev Allows a delegatee to cast a vote on behalf of a delegator.
     * Voting power is based on the delegator's current ChronoEssence balance.
     * @param delegator The address of the user who delegated.
     * @param proposalHash The hash of the proposal.
     * @param support True for 'for', False for 'against'.
     */
    function voteForProposal(address delegator, bytes32 proposalHash, bool support) external {
        _updateUserTimedState(msg.sender); // Sync delegatee state
        _updateUserTimedState(delegator); // Sync delegator state to get current essence balance

        Proposal storage proposal = proposals[proposalHash];
        require(proposal.proposerAddress != address(0), "ChronoForge: Proposal does not exist");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(!proposal.canceled, "ChronoForge: Proposal canceled");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "ChronoForge: Proposal voting period is not active");

        // Check if msg.sender is the designated delegatee for the delegator
        require(votingDelegatee[delegator] == msg.sender, "ChronoForge: msg.sender is not the delegatee for this address");

        // Check if this specific delegator's power has already been used by their delegatee
        // This simple check prevents the delegatee from voting multiple times for the same delegator on the same proposal
        require(!proposal.hasVoted[delegator], "ChronoForge: Delegator's power has already been used on this proposal");
        // Note: The 'hasVoted' mapping tracks if the _power for that address_ has been cast, either directly or via delegatee.

        // Get voting power for the delegator
        uint256 votingPower = _calculateVotingPower(delegator, proposalHash);
        require(votingPower > 0, "ChronoForge: Delegator has no voting power"); // Must have some essence to vote

        // Record the vote
        if (support) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.sub(votingPower); // Corrected from add in brainstorm
        }

        // Mark the delegator's power as used on this proposal
        proposal.hasVoted[delegator] = true; // Mark the delegator's slot as voted

        emit ParameterVoted(proposalHash, msg.sender, support, votingPower); // Event signer is delegatee, power is delegator's
    }


    /**
     * @dev Allows anyone to execute a successful proposal after the voting period ends.
     * Success criteria: Voting period ended, not executed/canceled, meets minimum voting power threshold, more 'for' votes than 'against'.
     * @param proposalHash The hash of the proposal.
     */
    function executeProposal(bytes32 proposalHash) external {
        Proposal storage proposal = proposals[proposalHash];
        require(proposal.proposerAddress != address(0), "ChronoForge: Proposal does not exist");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(!proposal.canceled, "ChronoForge: Proposal canceled");
        require(block.number > proposal.endBlock, "ChronoForge: Voting period has not ended");

        // Calculate total participating voting power for this proposal
        // In this simple model, total power is sum of power used by addresses who voted directly or whose delegatee voted for them.
        // A more robust model would snapshot total essence supply at proposal creation.
        // Simple approach: Check if 'for' votes exceed 'against' and if total votes meet a percentage of current supply.
        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);

        // Simplified threshold check: Total votes > 0 and For votes > Against votes
        // And total votes must exceed a percentage of *current* total protocol essence
        uint256 currentTotalEssence = getProtocolEssenceSupply(); // Requires accurate tracking of total supply
        uint256 minVotingPowerNeeded = currentTotalEssence.mul(dynamicParameters[PARAM_GOVERNANCE_EXECUTION_THRESHOLD_PERCENT].value).div(1e18); // Assuming threshold is scaled 0-1e18 for 0-100%

        require(totalVotes > 0, "ChronoForge: No votes cast");
        require(proposal.forVotes > proposal.againstVotes, "ChronoForge: Proposal did not pass");
        require(totalVotes >= minVotingPowerNeeded, "ChronoForge: Insufficient total voting power engaged");


        // Execute the parameter change
        _setDynamicParameter(proposal.paramNameHash, proposal.newValue);

        proposal.executed = true;

        // Remove from active proposals list (efficiently by swapping with last and popping)
        for(uint i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == proposalHash) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }


        emit ParameterExecuted(proposalHash, proposal.paramNameHash, proposal.newValue);
    }

    /**
     * @dev Allows the proposer or a privileged address (owner, or governance itself) to cancel a proposal.
     * Might have conditions (e.g., only before voting starts, or if no votes yet).
     * @param proposalHash The hash of the proposal to cancel.
     */
    function cancelProposal(bytes32 proposalHash) external {
        Proposal storage proposal = proposals[proposalHash];
        require(proposal.proposerAddress != address(0), "ChronoForge: Proposal does not exist");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(!proposal.canceled, "ChronoForge: Proposal already canceled");

        // Cancellation logic: Only proposer OR owner can cancel, and only if voting hasn't ended yet.
        require(msg.sender == proposal.proposerAddress || msg.sender == owner(), "ChronoForge: Not authorized to cancel proposal");
        require(block.number <= proposal.endBlock, "ChronoForge: Cannot cancel after voting ends");
        // Optional: require no votes yet, or proposer pays a penalty if votes exist.
        // require(proposal.forVotes == 0 && proposal.againstVotes == 0, "ChronoForge: Cannot cancel after voting has started");

        proposal.canceled = true;

         // Remove from active proposals list
         for(uint i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == proposalHash) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }

        emit ProposalCanceled(proposalHash);
    }

    // --- Governance Views ---

    /**
     * @dev Gets the details of a specific proposal.
     * @param proposalHash The hash of the proposal.
     * @return The Proposal struct details.
     */
    function getProposalDetails(bytes32 proposalHash) external view returns (
        bytes32 paramNameHash,
        uint256 newValue,
        address proposerAddress,
        uint256 startBlock,
        uint256 endBlock,
        bool executed,
        bool canceled
    ) {
        Proposal storage proposal = proposals[proposalHash];
        require(proposal.proposerAddress != address(0), "ChronoForge: Proposal does not exist");
        return (
            proposal.paramNameHash,
            proposal.newValue,
            proposal.proposerAddress,
            proposal.startBlock,
            proposal.endBlock,
            proposal.executed,
            proposal.canceled
        );
    }

    /**
     * @dev Gets the current vote counts for a specific proposal.
     * @param proposalHash The hash of the proposal.
     * @return forVotes Total 'for' votes.
     * @return againstVotes Total 'against' votes.
     */
    function getProposalVoteCount(bytes32 proposalHash) external view returns (uint256 forVotes, uint256 againstVotes) {
         Proposal storage proposal = proposals[proposalHash];
        require(proposal.proposerAddress != address(0), "ChronoForge: Proposal does not exist");
        return (proposal.forVotes, proposal.againstVotes);
    }

    /**
     * @dev Checks if a specific address (who voted directly or whose delegatee voted for them) has voted on a proposal.
     * @param proposalHash The hash of the proposal.
     * @param voter The address to check.
     * @return True if the address's power has been used to vote, False otherwise.
     */
    function getVoterVote(bytes32 proposalHash, address voter) external view returns (bool hasVoted) {
         Proposal storage proposal = proposals[proposalHash];
        require(proposal.proposerAddress != address(0), "ChronoForge: Proposal does not exist");
        return proposal.hasVoted[voter]; // This map tracks if power for 'voter' was used
    }

     /**
     * @dev Gets the voting power an address could potentially use (their current balance).
     * Note: This does *not* return the accumulated delegated power for a delegatee.
     * @param user The address of the user.
     * @return The potential voting power.
     */
    function getUserPotentialVotingPower(address user) external view returns (uint256) {
        // This uses the simple voting power calculation
        return _calculateVotingPower(user, bytes32(0)); // Proposal hash not needed for this model
    }


    // --- Utility & Delegation ---

    /**
     * @dev Public helper to trigger time-dependent state updates for a single user.
     * Can be called by anyone, paying the gas, to sync a user's state.
     * @param user The address of the user to sync.
     */
    function syncUserTimedState(address user) external {
        _updateUserTimedState(user);
    }

    /**
     * @dev Public helper to trigger time-dependent state updates for a batch of users.
     * Useful for a service or bot to sync many users efficiently (within gas limits).
     * @param users_ Array of addresses to sync.
     */
    function syncBatchUserTimedStates(address[] calldata users_) external {
        // Add a reasonable limit to prevent OOG errors
        require(users_.length <= 50, "ChronoForge: Batch size too large");
        for (uint i = 0; i < users_.length; i++) {
            _updateUserTimedState(users_[i]);
        }
    }

    /**
     * @dev Gets the human-readable name for an action ID.
     * @param actionId The ID of the action.
     * @return The name of the action.
     */
    function getActionName(uint256 actionId) external view returns (string memory) {
        return actionDefinitions[actionId].name;
    }

    /**
     * @dev Gets the total number of proposals ever created.
     * @return The total proposal count.
     */
    function getTotalProposals() external view returns (uint256) {
        return proposalCounter;
    }

    /**
     * @dev Gets the latest executed value for a dynamic parameter.
     * This reads the currently active value, which is the result of the last successful proposal.
     * @param paramNameHash The hash of the parameter name.
     * @return The latest executed value.
     */
    function getLatestExecutedParameterValue(bytes32 paramNameHash) external view returns (uint256) {
        // This simply returns the current value stored in the dynamicParameters mapping.
        // If you needed history, you'd need a separate state variable/mapping.
        require(dynamicParameters[paramNameHash].value != 0 || paramNameHash == bytes32(0), "ChronoForge: Parameter not found or zero"); // Basic check
        return dynamicParameters[paramNameHash].value;
    }

    /**
     * @dev Delegates voting power from msg.sender to a delegatee.
     * Setting delegatee to address(0) removes delegation.
     * @param delegatee_ The address to delegate voting power to.
     */
    function delegateVoting(address delegatee_) external {
        // Prevent self-delegation effectively
        if (delegatee_ == msg.sender) delegatee_ = address(0); // Delegate to 0x0 to clear

        address currentDelegatee = votingDelegatee[msg.sender];
        require(currentDelegatee != delegatee_, "ChronoForge: Delegation target unchanged");

        // In a complex system, delegation changes might affect active votes or require checkpoints.
        // In this simple model, it just changes *who* can cast the vote using msg.sender's power going forward.

        votingDelegatee[msg.sender] = delegatee_;
        emit VotingDelegated(msg.sender, delegatee_);
    }

    /**
     * @dev Gets the address that a user has delegated their voting power to.
     * address(0) means no delegation.
     * @param user The address to check.
     * @return The delegatee's address, or address(0) if no delegation.
     */
    function getDelegatedVotingFor(address user) external view returns (address) {
        return votingDelegatee[user];
    }

    // --- Admin (Minimal, Governance takes over most controls) ---

    /**
     * @dev Allows the owner to set the protocol fee recipient. Should ideally be governed.
     * Added as an example admin function, but governance should likely handle this long-term.
     * @param recipient The address to set as the fee recipient.
     */
    function setProtocolFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "ChronoForge: Invalid recipient address");
        protocolFeeRecipient = recipient;
        emit ProtocolFeeRecipientUpdated(recipient);
    }

    // Note: A function to withdraw accumulated protocol fees to the fee recipient would also be needed.
    // function withdrawProtocolFees() external { ... }
    // Need to define how/where protocol fees accumulate (e.g., percentage of action costs).
    // This would require adding a fee mechanism to _applyEssenceCost or specific actions.

    // --- Fallback/Receive (Optional) ---
    // Add receive() external payable {} if you want the contract to receive Ether
    // Add fallback() external payable {} if you want to handle calls to undefined functions (be careful)
}
```