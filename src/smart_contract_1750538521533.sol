Okay, here is a Solidity smart contract for a concept I'm calling "Reputation-Gated Community Goal & Contribution Protocol".

This contract allows a community to contribute resources (ERC-20 tokens) and perform off-chain "positive actions" (validated via on-chain data/proof) towards a common goal. Contributions build on-chain reputation, and reputation unlocks access to special functions, voting power (simulated), and potential rewards upon goal achievement. It includes features like dynamic action values, simulated external factors affecting progress, phase transitions, goal proposals, and tiered access based on reputation.

It aims to be more complex than standard ERC-20/721 or simple staking/vault contracts by incorporating reputation mechanics, state transitions, and configurable contribution logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for basic admin control, but adding reputation-based control too.
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Reputation-Gated Community Goal & Contribution Protocol
 * @dev This contract facilitates community collaboration towards a goal via ERC-20 contributions and
 *      validated off-chain actions. Participants earn reputation which grants tiered access
 *      and potential rewards upon goal achievement.
 *
 * @outline
 * 1. State Variables
 * 2. Enums and Structs
 * 3. Events
 * 4. Modifiers
 * 5. Core Logic (Contributions, Actions, Reputation)
 * 6. Goal Management
 * 7. Phase & State Control
 * 8. Access Control & Reputation Tiers
 * 9. Redemption & Rewards
 * 10. Admin & Utility Functions
 * 11. Getters
 *
 * @functionSummary
 * --- Core Logic (Contributions, Actions, Reputation) ---
 * - `contributeERC20(address tokenAddress, uint256 amount)`: Allows users to contribute eligible ERC-20 tokens. Updates progress and grants reputation.
 * - `performPositiveAction(bytes32 actionHash, uint256 actionValue)`: Users submit proof of off-chain action. Updates progress and grants reputation based on configurable action value and simulated factors.
 * - `getReputation(address user)`: Get the reputation points of a user.
 * - `getUserActionContribution(address user)`: Get the total 'value' contributed by a user via actions.
 * - `getUserERC20Contribution(address user, address tokenAddress)`: Get the total contribution amount by a user for a specific token.
 * - `getTotalERC20Contributions(address tokenAddress)`: Get the total amount contributed for a specific token across all users.
 *
 * --- Goal Management ---
 * - `setGoalTarget(uint256 _target)`: Set the target value for the current goal (reputation-gated).
 * - `setGoalDescription(string calldata _description)`: Set the description for the current goal (reputation-gated).
 * - `submitGoalProposal(bytes32 proposalHash, uint256 target, string calldata description)`: High-reputation users can propose future goals.
 * - `approveGoalProposal(bytes32 proposalHash)`: Owner or high-reputation user approves a pending goal proposal.
 * - `rejectGoalProposal(bytes32 proposalHash)`: Owner or high-reputation user rejects a pending goal proposal.
 * - `activateApprovedGoalProposal()`: Owner or high-reputation user activates the currently approved proposal, setting it as the new goal.
 * - `getCurrentGoalProposalHash()`: Get the hash of the current pending goal proposal.
 *
 * --- Phase & State Control ---
 * - `setCurrentPhase(Phase _phase)`: Transition the contract to a new phase (reputation-gated). Includes logic for phase-specific requirements/effects.
 * - `getCurrentPhase()`: Get the current phase of the contract.
 * - `checkGoalAchieved()`: Internal/Helper function (exposed publicly for check) to determine if the goal has been met.
 *
 * --- Access Control & Reputation Tiers ---
 * - `setReputationThreshold(AccessLevel level, uint256 threshold)`: Owner sets reputation point requirements for different access levels.
 * - `getReputationThreshold(AccessLevel level)`: Get the reputation threshold for a specific access level.
 * - `hasMinReputation(address user, AccessLevel requiredLevel)`: Check if a user meets the reputation requirement for a given level.
 *
 * --- Redemption & Rewards ---
 * - `redeemGoalAchievementBadge()`: Allows participants (meeting min reputation/contribution) to claim a status/badge upon goal achievement (prevents double claiming).
 * - `claimExcessFundsShare(address tokenAddress)`: Allows high-reputation participants to claim a proportional share of excess funds contributed beyond the goal target (if applicable and configured).
 * - `canRedeemGoalAchievementBadge(address user)`: Check if a user is eligible to redeem the badge.
 * - `hasRedeemedBadge(address user)`: Check if a user has already redeemed the badge.
 * - `hasClaimedExcessFundsShare(address user, address tokenAddress)`: Check if a user has claimed their share of excess funds for a specific token.
 *
 * --- Admin & Utility Functions ---
 * - `pauseContract()`: Owner can pause core contribution functions in emergency.
 * - `unpauseContract()`: Owner can unpause the contract.
 * - `withdrawExcessFundsAdmin(address tokenAddress, uint256 amount)`: Owner can withdraw protocol-level excess/residual funds (careful use).
 * - `simulateExternalFactor(int256 factor)`: Owner can simulate an external influence affecting the value of actions (e.g., difficulty).
 * - `getSimulatedFactor()`: Get the current simulated external factor.
 * - `setTokenEligibility(address tokenAddress, bool isEligible)`: Owner can configure which ERC-20 tokens are accepted for contribution.
 * - `isTokenEligible(address tokenAddress)`: Check if a token is eligible.
 * - `getEligibleTokens()`: Get list of eligible tokens.
 * - `configureActionValueMapping(bytes32 actionHash, uint256 reputationEarned, uint256 progressContributed)`: Owner configures how specific action types contribute to reputation and progress.
 * - `getActionMapping(bytes32 actionHash)`: Get the configuration for a specific action hash.
 *
 * --- Internal/Helper Functions (Not directly callable externally, but part of logic) ---
 * - `_updateProgress(uint256 value)`: Updates the current goal progress, potentially triggering phase change.
 * - `_grantReputation(address user, uint256 points)`: Grants reputation points to a user.
 * - `_checkReputation(address user, AccessLevel requiredLevel)`: Checks if a user meets a minimum reputation threshold.
 * - `_isEligibleForRedemption(address user)`: Determines if a user meets min criteria to redeem achievement badge.
 */
contract CommunityGoalProtocol is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- 1. State Variables ---

    // Goal State
    uint256 public goalTarget;
    uint256 public currentProgress;
    string public goalDescription;
    bool public goalAchieved;

    // Reputation State
    mapping(address => uint256) public reputationPoints;
    enum AccessLevel { None, Basic, Contributor, Core, Council } // Tiered access levels
    mapping(AccessLevel => uint256) public reputationThresholds;

    // Contribution State
    mapping(address => mapping(address => uint256)) public userERC20Contributions; // user => token => amount
    mapping(address => address[]) private userContributedTokens; // Track tokens per user for getters
    mapping(address => uint256) public userActionContributionValue; // user => total_action_value
    mapping(address => uint256) public totalERC20Contributions; // token => total amount

    // Protocol Configuration
    mapping(address => bool) public eligibleTokens; // Allowed ERC20 tokens
    address[] private eligibleTokenList; // For listing eligible tokens

    struct ActionConfig {
        uint256 reputationEarned;
        uint256 progressContributed;
        bool configured; // Flag to check if hash is configured
    }
    mapping(bytes32 => ActionConfig) public actionConfigs; // Configuration for different action types

    int256 public simulatedFactor; // A dynamic factor influencing action value/difficulty

    // Contract State/Phase
    enum Phase { Setup, Funding, Active, GoalAchieved, Paused }
    Phase public currentPhase;

    // Goal Proposal State
    struct GoalProposal {
        bytes32 proposalHash;
        uint256 target;
        string description;
        bool exists;
        bool approved; // Approved by owner/council
    }
    bytes32 public currentGoalProposalHash; // Hash of the proposal currently under consideration or approved
    mapping(bytes32 => GoalProposal) public goalProposals;

    // Redemption State
    mapping(address => bool) public hasRedeemedBadge; // User has claimed achievement badge
    mapping(address => mapping(address => bool)) public hasClaimedExcessFundsShare; // User claimed excess funds for a token

    // Minimum requirements for goal achievement benefits (badge, etc.)
    uint256 public minReputationForRedemption;
    uint256 public minContributionValueForRedemption; // Sum of ERC20 contribution USD value (simulated/abstract) + Action value

    // --- 2. Enums and Structs (Defined above for clarity) ---

    // --- 3. Events ---
    event ERC20Contributed(address indexed user, address indexed token, uint256 amount, uint256 currentProgress, uint256 reputationEarned);
    event PositiveActionPerformed(address indexed user, bytes32 actionHash, uint256 actionValue, uint256 effectiveValue, uint256 currentProgress, uint256 reputationEarned);
    event ReputationGranted(address indexed user, uint256 points);
    event GoalTargetUpdated(uint256 newTarget);
    event GoalDescriptionUpdated(string newDescription);
    event GoalAchieved(uint256 finalProgress);
    event PhaseChanged(Phase oldPhase, Phase newPhase);
    event ReputationThresholdSet(AccessLevel level, uint256 threshold);
    event GoalProposalSubmitted(address indexed submitter, bytes32 proposalHash, uint256 target, string description);
    event GoalProposalApproved(bytes32 proposalHash);
    event GoalProposalRejected(bytes32 proposalHash);
    event GoalProposalActivated(bytes32 proposalHash);
    event AchievementBadgeRedeemed(address indexed user);
    event ExcessFundsShareClaimed(address indexed user, address indexed token, uint256 amount);
    event ExternalFactorSimulated(int256 factor);
    event TokenEligibilitySet(address indexed token, bool isEligible);
    event ActionConfigured(bytes32 actionHash, uint256 reputationEarned, uint256 progressContributed);
    event FundsWithdrawnAdmin(address indexed token, uint256 amount);

    // --- 4. Modifiers ---

    modifier inPhase(Phase _requiredPhase) {
        require(currentPhase == _requiredPhase, "CGP: Not in required phase");
        _;
    }

    modifier notInPhase(Phase _restrictedPhase) {
        require(currentPhase != _restrictedPhase, "CGP: Restricted in current phase");
        _;
    }

    modifier hasMinReputation(AccessLevel requiredLevel) {
        require(_checkReputation(_msgSender(), requiredLevel), "CGP: Insufficient reputation");
        _;
    }

    // --- 5. Core Logic (Contributions, Actions, Reputation) ---

    constructor(uint256 _initialGoalTarget, string memory _initialGoalDescription) Ownable(_msgSender()) Pausable() {
        goalTarget = _initialGoalTarget;
        goalDescription = _initialGoalDescription;
        currentPhase = Phase.Setup; // Start in Setup phase
        simulatedFactor = 100; // Default simulated factor (e.g., 100 means 100%)

        // Set initial reputation thresholds (can be updated later)
        reputationThresholds[AccessLevel.Basic] = 1;
        reputationThresholds[AccessLevel.Contributor] = 100;
        reputationThresholds[AccessLevel.Core] = 1000;
        reputationThresholds[AccessLevel.Council] = 5000;

        // Set minimum requirements for redemption (can be updated later)
        minReputationForRedemption = 50;
        minContributionValueForRedemption = 0; // Requires external value mapping or simple action value check
    }

    /**
     * @dev Allows users to contribute eligible ERC-20 tokens towards the goal.
     * @param tokenAddress The address of the ERC-20 token.
     * @param amount The amount of tokens to contribute.
     */
    function contributeERC20(address tokenAddress, uint256 amount)
        external
        payable // Allow receiving native currency if needed for future versions, but currently only ERC20 handled
        whenNotPaused
        notInPhase(Phase.Setup)
        notInPhase(Phase.GoalAchieved) // Cannot contribute after goal reached
        nonReentrant
    {
        require(eligibleTokens[tokenAddress], "CGP: Token not eligible");
        require(amount > 0, "CGP: Amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);

        // Check allowance before transferFrom
        uint256 allowance = token.allowance(_msgSender(), address(this));
        require(allowance >= amount, "CGP: ERC20 allowance insufficient");

        token.safeTransferFrom(_msgSender(), address(this), amount);

        userERC20Contributions[_msgSender()][tokenAddress] += amount;
        totalERC20Contributions[tokenAddress] += amount;

        // Track which tokens a user contributed to simplify lookup
        bool tokenAlreadyTracked = false;
        for (uint i = 0; i < userContributedTokens[_msgSender()].length; i++) {
            if (userContributedTokens[_msgSender()][i] == tokenAddress) {
                tokenAlreadyTracked = true;
                break;
            }
        }
        if (!tokenAlreadyTracked) {
            userContributedTokens[_msgSender()].push(tokenAddress);
        }

        // Grant reputation based on ERC20 contribution (simplified: 1 point per unit, adjust as needed)
        // This could be made more complex, e.g., based on USD value via oracle, or diminishing returns
        uint256 reputationEarned = amount; // Example: 1 token unit = 1 reputation point
        _grantReputation(_msgSender(), reputationEarned);

        // Update progress (simplified: sum of token amounts contributes to progress)
        // This should ideally map token value to progress value, perhaps via oracle or fixed rates
        // For simplicity, we'll just add token amount to progress. Real dApp needs value mapping.
        _updateProgress(amount); // Example: 1 token unit contributes 1 to progress

        emit ERC20Contributed(_msgSender(), tokenAddress, amount, currentProgress, reputationEarned);
    }

    /**
     * @dev Allows users to submit proof of a positive off-chain action.
     *      Action value and reputation earned are based on configured mappings and simulated factor.
     * @param actionHash A unique identifier for the type of action (e.g., keccak256("ReportBug"), keccak256("CreateContent")).
     * @param actionValue A value associated with the specific instance of the action (e.g., complexity score, upvotes).
     */
    function performPositiveAction(bytes32 actionHash, uint256 actionValue)
        external
        whenNotPaused
        notInPhase(Phase.Setup)
        notInPhase(Phase.GoalAchieved) // Cannot perform actions towards this goal after it's reached
        nonReentrant
    {
        ActionConfig storage config = actionConfigs[actionHash];
        require(config.configured, "CGP: Action hash not configured");
        require(actionValue > 0, "CGP: Action value must be positive");

        // Calculate effective value considering simulated factor (e.g., difficulty)
        // Factor could be > 100 for easier, < 100 for harder. Formula: value * factor / 100
        // Use integer division, could lose precision, or use SafeCast if needed.
        uint256 effectiveValue = (actionValue * uint256(simulatedFactor)) / 100;
        require(effectiveValue > 0, "CGP: Effective action value is zero"); // Prevent actions with zero effective value

        userActionContributionValue[_msgSender()] += effectiveValue;

        // Grant reputation based on configured value and effective action value
        uint256 reputationEarned = config.reputationEarned * effectiveValue;
        _grantReputation(_msgSender(), reputationEarned);

        // Update progress based on configured value and effective action value
        uint256 progressContributed = config.progressContributed * effectiveValue;
        _updateProgress(progressContributed);

        emit PositiveActionPerformed(_msgSender(), actionHash, actionValue, effectiveValue, currentProgress, reputationEarned);
    }

    /**
     * @dev Internal function to grant reputation points and emit event.
     * @param user The address to grant reputation to.
     * @param points The amount of reputation points to grant.
     */
    function _grantReputation(address user, uint256 points) internal {
        if (points > 0) {
            reputationPoints[user] += points;
            emit ReputationGranted(user, points);
        }
    }

    /**
     * @dev Get the reputation points for a given user.
     * @param user The address of the user.
     * @return The reputation points of the user.
     */
    function getReputation(address user) public view returns (uint256) {
        return reputationPoints[user];
    }

    /**
     * @dev Get the total effective value contributed by a user via positive actions.
     * @param user The address of the user.
     * @return The total action value contributed by the user.
     */
    function getUserActionContribution(address user) public view returns (uint256) {
        return userActionContributionValue[user];
    }

    /**
     * @dev Get the total contribution amount by a user for a specific token.
     * @param user The address of the user.
     * @param tokenAddress The address of the token.
     * @return The total amount contributed by the user for that token.
     */
    function getUserERC20Contribution(address user, address tokenAddress) public view returns (uint256) {
        return userERC20Contributions[user][tokenAddress];
    }

    /**
     * @dev Get the list of tokens a user has contributed to.
     * @param user The address of the user.
     * @return An array of token addresses contributed by the user.
     */
    function getUserContributedTokens(address user) external view returns (address[] memory) {
        return userContributedTokens[user];
    }

    /**
     * @dev Get the total amount contributed for a specific token across all users.
     * @param tokenAddress The address of the token.
     * @return The total amount contributed for that token.
     */
    function getTotalERC20Contributions(address tokenAddress) public view returns (uint256) {
        return totalERC20Contributions[tokenAddress];
    }

    // --- 6. Goal Management ---

    /**
     * @dev Sets the target value for the current goal. Only callable by high-reputation users.
     *      Can only be set in Setup or specific Proposal/Voting phases (not currently implemented).
     * @param _target The new goal target value.
     */
    function setGoalTarget(uint256 _target) external whenNotPaused onlyOwner { // Simplified to onlyOwner for now, add reputation logic
        require(currentPhase == Phase.Setup, "CGP: Goal target can only be set in Setup phase");
        require(_target > currentProgress, "CGP: New target must be greater than current progress");
        goalTarget = _target;
        emit GoalTargetUpdated(goalTarget);
    }

    /**
     * @dev Sets the description for the current goal. Only callable by high-reputation users.
     * @param _description The new goal description.
     */
    function setGoalDescription(string calldata _description) external whenNotPaused onlyOwner { // Simplified to onlyOwner
        require(currentPhase == Phase.Setup, "CGP: Goal description can only be set in Setup phase");
        goalDescription = _description;
        emit GoalDescriptionUpdated(goalDescription);
    }

    /**
     * @dev High-reputation users can submit a proposal for a future goal.
     *      Replaces any existing pending proposal.
     * @param proposalHash A unique hash for the proposal (e.g., keccak256(abi.encode(target, description, nonce))).
     * @param target The proposed goal target.
     * @param description The proposed goal description.
     */
    function submitGoalProposal(bytes32 proposalHash, uint256 target, string calldata description)
        external
        whenNotPaused
        notInPhase(Phase.GoalAchieved)
        hasMinReputation(AccessLevel.Core) // Example: requires Core reputation to propose
    {
        require(target > 0, "CGP: Proposal target must be positive");
        // Optionally add checks against current progress if proposals can lower target
        // require(target > currentProgress, "CGP: Proposed target must be greater than current progress"); // Maybe not required if changing goals mid-way is allowed

        // Replace any existing pending proposal
        if (currentGoalProposalHash != bytes32(0) && goalProposals[currentGoalProposalHash].exists && !goalProposals[currentGoalProposalHash].approved) {
             // Optionally emit an event about overwriting
        }

        currentGoalProposalHash = proposalHash;
        goalProposals[proposalHash] = GoalProposal({
            proposalHash: proposalHash,
            target: target,
            description: description,
            exists: true,
            approved: false
        });

        emit GoalProposalSubmitted(_msgSender(), proposalHash, target, description);
    }

    /**
     * @dev Approves the current pending goal proposal. Can be called by Owner or Council level rep holders.
     *      Requires a proposal to exist and not yet be approved.
     */
    function approveGoalProposal(bytes32 proposalHash)
        external
        whenNotPaused
        notInPhase(Phase.GoalAchieved)
        nonReentrant
    {
        // Allow Owner OR Council rep holders to approve
        require(owner() == _msgSender() || _checkReputation(_msgSender(), AccessLevel.Council), "CGP: Only owner or council can approve proposals");
        require(proposalHash != bytes32(0), "CGP: Invalid proposal hash");
        GoalProposal storage proposal = goalProposals[proposalHash];
        require(proposal.exists, "CGP: Proposal does not exist");
        require(!proposal.approved, "CGP: Proposal already approved");
        require(proposalHash == currentGoalProposalHash, "CGP: Not the current proposal under consideration"); // Ensure we approve the active proposal hash

        proposal.approved = true;
        emit GoalProposalApproved(proposalHash);
    }

    /**
     * @dev Rejects the current pending goal proposal. Can be called by Owner or Council level rep holders.
     *      Requires a proposal to exist and not yet be approved.
     */
    function rejectGoalProposal(bytes32 proposalHash)
        external
        whenNotPaused
        notInPhase(Phase.GoalAchieved)
        nonReentrant
    {
        // Allow Owner OR Council rep holders to reject
        require(owner() == _msgSender() || _checkReputation(_msgSender(), AccessLevel.Council), "CGP: Only owner or council can reject proposals");
        require(proposalHash != bytes32(0), "CGP: Invalid proposal hash");
        GoalProposal storage proposal = goalProposals[proposalHash];
        require(proposal.exists, "CGP: Proposal does not exist");
        require(!proposal.approved, "CGP: Proposal already approved");
         require(proposalHash == currentGoalProposalHash, "CGP: Not the current proposal under consideration"); // Ensure we reject the active proposal hash

        // Simply mark as not existing or reset the current proposal hash
        delete goalProposals[proposalHash];
        currentGoalProposalHash = bytes32(0); // Clear the current proposal hash
        emit GoalProposalRejected(proposalHash);
    }

    /**
     * @dev Activates the currently approved goal proposal, setting it as the new goal.
     *      Can be called by Owner or Council level rep holders.
     *      Requires a proposal to be approved and not yet activated. Resets progress.
     */
    function activateApprovedGoalProposal()
        external
        whenNotPaused
        notInPhase(Phase.GoalAchieved)
        inPhase(Phase.Active) // Or a dedicated 'ProposalActivation' phase
        nonReentrant
    {
        // Allow Owner OR Council rep holders to activate
        require(owner() == _msgSender() || _checkReputation(_msgSender(), AccessLevel.Council), "CGP: Only owner or council can activate proposals");
        require(currentGoalProposalHash != bytes32(0), "CGP: No proposal is currently under consideration");
        GoalProposal storage proposal = goalProposals[currentGoalProposalHash];
        require(proposal.exists, "CGP: Current proposal hash is invalid or deleted");
        require(proposal.approved, "CGP: Current proposal is not approved");

        // Set the new goal and reset progress for the new goal
        goalTarget = proposal.target;
        goalDescription = proposal.description;
        currentProgress = 0; // Reset progress for the new goal

        // Optionally reset reputation or give bonus for achieving previous goal

        // Clean up the activated proposal
        delete goalProposals[currentGoalProposalHash];
        currentGoalProposalHash = bytes32(0);

        // Optionally transition phase back to Funding/Active for the new goal
        // setCurrentPhase(Phase.Funding); // Example: start funding again

        emit GoalProposalActivated(currentGoalProposalHash); // Emitting old hash might be confusing, consider new event structure
        emit GoalTargetUpdated(goalTarget);
        emit GoalDescriptionUpdated(goalDescription);
        emit PhaseChanged(currentPhase, currentPhase); // Or new phase if transitioned
    }


    /**
     * @dev Get the hash of the current pending or approved goal proposal.
     * @return The hash of the current goal proposal.
     */
    function getCurrentGoalProposalHash() external view returns (bytes32) {
        return currentGoalProposalHash;
    }

    // --- 7. Phase & State Control ---

    /**
     * @dev Transitions the contract to a new phase. Certain transitions may have requirements.
     *      Only callable by Owner or high-reputation users.
     * @param _phase The target phase.
     */
    function setCurrentPhase(Phase _phase)
        external
        whenNotPaused
        nonReentrant
    {
        // Add reputation gate: only owner or council level can change phases
        require(owner() == _msgSender() || _checkReputation(_msgSender(), AccessLevel.Council), "CGP: Only owner or council can change phases");

        Phase oldPhase = currentPhase;

        // Add transition logic requirements here
        if (_phase == Phase.Funding) {
             require(oldPhase == Phase.Setup || oldPhase == Phase.Active, "CGP: Invalid phase transition to Funding");
             require(goalTarget > 0, "CGP: Goal target must be set before Funding");
        } else if (_phase == Phase.Active) {
             require(oldPhase == Phase.Setup || oldPhase == Phase.Funding, "CGP: Invalid phase transition to Active");
             // Can start Active even if goal isn't fully funded, if contributions are ongoing
        } else if (_phase == Phase.GoalAchieved) {
             require(oldPhase != Phase.Setup, "CGP: Cannot transition to GoalAchieved from Setup");
             require(!goalAchieved, "CGP: Goal already marked as achieved"); // Prevent explicit transition if already achieved via progress
             require(checkGoalAchieved(), "CGP: Goal not yet achieved"); // Explicit check
             goalAchieved = true; // Mark explicitly achieved if transitioning this way
        } else if (_phase == Phase.Setup) {
            // Resetting to Setup might require specific conditions, e.g., after goal failure or before a new goal
             revert("CGP: Transition to Setup not allowed via this function"); // Prevent easy reset
        } else if (_phase == Phase.Paused) {
            // Pausing is handled by Pausable modifier, this transition is for explicit state
            // Ensure only owner/council can transition TO Paused here if needed
        }


        currentPhase = _phase;
        emit PhaseChanged(oldPhase, currentPhase);

        // Execute logic upon entering a new phase
        if (currentPhase == Phase.GoalAchieved && oldPhase != Phase.GoalAchieved) {
             // Goal just achieved logic
             // e.g., Lock further contributions, unlock redemption functions
        }
    }

    /**
     * @dev Internal helper to update progress and check for goal achievement.
     * @param value The value to add to current progress.
     */
    function _updateProgress(uint256 value) internal {
        if (!goalAchieved) { // Only update progress if goal hasn't been marked achieved
            uint256 oldProgress = currentProgress;
            currentProgress += value;

            if (currentProgress >= goalTarget && goalTarget > 0) {
                goalAchieved = true;
                // Automatically transition to GoalAchieved phase? Or require manual transition?
                // Auto-transition is simpler for a single goal, manual for multi-goal phases.
                // Let's auto-transition if not already in a terminal phase.
                if (currentPhase != Phase.GoalAchieved) {
                     Phase oldPhase = currentPhase;
                     currentPhase = Phase.GoalAchieved;
                     emit PhaseChanged(oldPhase, currentPhase);
                }
                emit GoalAchieved(currentProgress);
            }
        }
    }

    /**
     * @dev Check if the goal has been achieved.
     * @return True if the goal target has been met or surpassed.
     */
    function checkGoalAchieved() public view returns (bool) {
        return goalAchieved || (goalTarget > 0 && currentProgress >= goalTarget);
    }

    /**
     * @dev Get the current phase of the contract.
     * @return The current phase enum value.
     */
    function getCurrentPhase() public view returns (Phase) {
        return currentPhase;
    }

    // --- 8. Access Control & Reputation Tiers ---

    /**
     * @dev Set the minimum reputation threshold required for a specific access level.
     *      Only callable by Owner.
     * @param level The access level to configure.
     * @param threshold The minimum reputation points required.
     */
    function setReputationThreshold(AccessLevel level, uint256 threshold) external onlyOwner {
        reputationThresholds[level] = threshold;
        emit ReputationThresholdSet(level, threshold);
    }

    /**
     * @dev Get the minimum reputation threshold for a specific access level.
     * @param level The access level.
     * @return The minimum reputation points required.
     */
    function getReputationThreshold(AccessLevel level) public view returns (uint256) {
        return reputationThresholds[level];
    }

    /**
     * @dev Check if a user meets the reputation requirement for a given level.
     * @param user The address of the user.
     * @param requiredLevel The access level to check against.
     * @return True if the user's reputation meets or exceeds the threshold.
     */
    function hasMinReputation(address user, AccessLevel requiredLevel) public view returns (bool) {
        return _checkReputation(user, requiredLevel);
    }

     /**
     * @dev Internal helper to check if a user meets a minimum reputation threshold.
     * @param user The address of the user.
     * @param requiredLevel The access level to check against.
     * @return True if the user's reputation meets or exceeds the threshold.
     */
    function _checkReputation(address user, AccessLevel requiredLevel) internal view returns (bool) {
        return reputationPoints[user] >= reputationThresholds[requiredLevel];
    }


    // --- 9. Redemption & Rewards ---

    /**
     * @dev Allows eligible participants to claim a status/badge upon goal achievement.
     *      Eligibility based on minimum reputation and/or contribution.
     *      Can only be called in the GoalAchieved phase and only once per user.
     */
    function redeemGoalAchievementBadge()
        external
        whenNotPaused
        inPhase(Phase.GoalAchieved)
        nonReentrant
    {
        require(_isEligibleForRedemption(_msgSender()), "CGP: Not eligible for redemption");
        require(!hasRedeemedBadge[_msgSender()], "CGP: Badge already redeemed");

        hasRedeemedBadge[_msgSender()] = true;

        // Future integration: Mint an NFT badge, update a status in another contract, etc.
        // For this example, it's just an internal flag.

        emit AchievementBadgeRedeemed(_msgSender());
    }

    /**
     * @dev Allows high-reputation participants to claim a proportional share of excess funds
     *      contributed beyond the goal target. Requires GoalAchieved phase.
     *      Distribution logic needs careful definition (e.g., based on reputation relative to others).
     * @param tokenAddress The token to claim excess funds from.
     */
    function claimExcessFundsShare(address tokenAddress)
        external
        whenNotPaused
        inPhase(Phase.GoalAchieved)
        hasMinReputation(AccessLevel.Contributor) // Example: requires Contributor rep to claim
        nonReentrant
    {
        require(eligibleTokens[tokenAddress], "CGP: Token not eligible");
        require(!hasRedeemedBadge[_msgSender()], "CGP: Must redeem badge first"); // Example dependency
        require(!hasClaimedExcessFundsShare[_msgSender()][tokenAddress], "CGP: Excess funds already claimed for this token");

        // --- Complex Distribution Logic (Simplified Example) ---
        // This is a Placeholder. Real distribution needs a defined mechanism:
        // 1. Calculate total "claimable" excess funds for this token: totalERC20Contributions[tokenAddress] - (some amount tied to goal target, this is complex)
        // 2. Calculate user's "share" based on their contribution / reputation relative to other claimants.
        // 3. Transfer the calculated share.

        // Simplified Example: Distribute 10% of total contributions *beyond* the goal target to top 10% reputation holders?
        // Or distribute all funds proportionally to reputation among high-rep users?
        // This simple example grants a fixed small amount for demonstration. A real contract needs precise logic.
        uint256 userShare = 1 * 1e18; // EXAMPLE: A fixed small amount like 1 token unit

        // Check contract balance holds enough for this user's calculated share
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= userShare, "CGP: Insufficient token balance for claim");

        hasClaimedExcessFundsShare[_msgSender()][tokenAddress] = true;
        token.safeTransfer(_msgSender(), userShare);

        emit ExcessFundsShareClaimed(_msgSender(), tokenAddress, userShare);
    }

    /**
     * @dev Internal helper to check if a user is eligible to redeem the achievement badge.
     *      Based on minimum reputation and/or total contribution value.
     * @param user The address of the user.
     * @return True if the user meets eligibility criteria.
     */
    function _isEligibleForRedemption(address user) internal view returns (bool) {
        bool hasMinRep = reputationPoints[user] >= minReputationForRedemption;

        // Calculate total contribution value (simplified: sum of ERC20 contributions + action value)
        // This needs mapping ERC20 amounts to a common value unit (e.g., USD) in a real app,
        // or simply checking if user contributed *any* amount/action above zero.
        uint256 totalUserContributionValue = userActionContributionValue[user];
        // Adding ERC20 contribution value is complex without oracle/fixed rates.
        // Let's simplify: just require min reputation AND any contribution (ERC20 or Action).
        bool hasAnyContribution = userActionContributionValue[user] > 0;
        for(uint i = 0; i < userContributedTokens[user].length; i++) {
            if (userERC20Contributions[user][userContributedTokens[user][i]] > 0) {
                 hasAnyContribution = true;
                 break;
            }
        }

        // Example eligibility: Must have minimum reputation AND have made any contribution (ERC20 or Action)
        return hasMinRep && hasAnyContribution;
    }

     /**
     * @dev Check if a user is eligible to redeem the goal achievement badge based on current settings.
     * @param user The address of the user.
     * @return True if the user meets eligibility criteria.
     */
    function canRedeemGoalAchievementBadge(address user) external view returns (bool) {
        return _isEligibleForRedemption(user);
    }

    /**
     * @dev Check if a user has already redeemed the achievement badge.
     * @param user The address of the user.
     * @return True if the user has redeemed the badge.
     */
    function hasRedeemedBadge(address user) external view returns (bool) {
        return hasRedeemedBadge[user];
    }

    /**
     * @dev Check if a user has claimed their share of excess funds for a specific token.
     * @param user The address of the user.
     * @param tokenAddress The address of the token.
     * @return True if the user has claimed for this token.
     */
    function hasClaimedExcessFundsShare(address user, address tokenAddress) external view returns (bool) {
        return hasClaimedExcessFundsShare[user][tokenAddress];
    }


    // --- 10. Admin & Utility Functions ---

    /**
     * @dev Pauses core contribution functions. Only callable by Owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
        setCurrentPhase(Phase.Paused); // Explicitly set phase to Paused
    }

    /**
     * @dev Unpauses core contribution functions. Only callable by Owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        // Need logic to determine which phase to return to, maybe the phase before pausing
        // For simplicity, let's just return to Active or Funding if goal not achieved
        if (goalAchieved) {
             setCurrentPhase(Phase.GoalAchieved);
        } else if (currentPhase == Phase.Paused) { // Only transition from Paused
             // This is a simplification. A real system would need to store the pre-paused phase.
             // Let's hardcode return to Active/Funding based on goalTarget for demo.
             if (goalTarget > 0) {
                 setCurrentPhase(Phase.Funding); // Or Active
             } else {
                 setCurrentPhase(Phase.Setup); // If no goal target was set
             }
        }
    }

    /**
     * @dev Allows Owner to withdraw excess funds from the contract, e.g., unclaimed rewards, protocol fees.
     *      Use with caution. Does not affect funds potentially claimable by users via claimExcessFundsShare.
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawExcessFundsAdmin(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(eligibleTokens[tokenAddress], "CGP: Token not eligible for withdrawal management");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "CGP: Insufficient contract balance");

        // This withdrawal logic is complex in a real scenario.
        // How to distinguish 'admin withdrawable' funds from 'user claimable' excess funds?
        // A robust system tracks ear-marked funds.
        // For simplicity, this just allows Owner to pull funds. Use *very* carefully.
        // It might be safer to disable this function and only allow `claimExcessFundsShare`.

        token.safeTransfer(owner(), amount);
        emit FundsWithdrawnAdmin(tokenAddress, amount);
    }

    /**
     * @dev Simulates an external factor that affects the value/difficulty of positive actions.
     *      Callable by Owner. Affects `performPositiveAction` calculations.
     * @param factor A percentage value (e.g., 100 for 100%, 50 for 50%, 200 for 200%).
     */
    function simulateExternalFactor(int256 factor) external onlyOwner {
        require(factor >= 0, "CGP: Factor cannot be negative");
        simulatedFactor = factor;
        emit ExternalFactorSimulated(factor);
    }

    /**
     * @dev Get the current simulated external factor.
     * @return The current simulated factor value.
     */
    function getSimulatedFactor() external view returns (int256) {
        return simulatedFactor;
    }

    /**
     * @dev Configures which ERC-20 tokens are accepted for contributions. Callable by Owner.
     * @param tokenAddress The address of the token.
     * @param isEligible True to make the token eligible, false otherwise.
     */
    function setTokenEligibility(address tokenAddress, bool isEligible) external onlyOwner {
        require(tokenAddress != address(0), "CGP: Invalid token address");
        bool wasEligible = eligibleTokens[tokenAddress];
        if (wasEligible == isEligible) {
             return; // No change
        }

        eligibleTokens[tokenAddress] = isEligible;

        // Update eligibleTokenList
        if (isEligible) {
             eligibleTokenList.push(tokenAddress);
        } else {
             // Simple removal: swap with last element and pop. Order is not guaranteed.
             for (uint i = 0; i < eligibleTokenList.length; i++) {
                  if (eligibleTokenList[i] == tokenAddress) {
                       eligibleTokenList[i] = eligibleTokenList[eligibleTokenList.length - 1];
                       eligibleTokenList.pop();
                       break; // Assume tokens are unique in the list
                  }
             }
        }
        emit TokenEligibilitySet(tokenAddress, isEligible);
    }

    /**
     * @dev Check if a token is currently eligible for contributions.
     * @param tokenAddress The address of the token.
     * @return True if the token is eligible.
     */
    function isTokenEligible(address tokenAddress) external view returns (bool) {
        return eligibleTokens[tokenAddress];
    }

    /**
     * @dev Get the list of currently eligible tokens.
     * @return An array of eligible token addresses.
     */
    function getEligibleTokens() external view returns (address[] memory) {
        return eligibleTokenList;
    }

    /**
     * @dev Configures how a specific positive action type contributes to reputation and progress. Callable by Owner.
     * @param actionHash The identifier hash for the action type.
     * @param reputationEarned Reputation points earned PER UNIT of actionValue.
     * @param progressContributed Progress points contributed PER UNIT of actionValue.
     */
    function configureActionValueMapping(bytes32 actionHash, uint256 reputationEarned, uint256 progressContributed) external onlyOwner {
        actionConfigs[actionHash] = ActionConfig({
            reputationEarned: reputationEarned,
            progressContributed: progressContributed,
            configured: true
        });
        emit ActionConfigured(actionHash, reputationEarned, progressContributed);
    }

    /**
     * @dev Get the configuration for a specific action hash.
     * @param actionHash The identifier hash for the action type.
     * @return ActionConfig struct containing reputationEarned, progressContributed, and configured status.
     */
    function getActionMapping(bytes32 actionHash) external view returns (ActionConfig memory) {
        return actionConfigs[actionHash];
    }

    // --- 11. Getters (Defined alongside functions above for relevant data) ---
    // Explicit getters for public state variables are automatically generated by the compiler.
    // Custom getters: getReputation, getUserActionContribution, getUserERC20Contribution,
    // getTotalERC20Contributions, getCurrentGoalProposalHash, getCurrentPhase, checkGoalAchieved,
    // getReputationThreshold, hasMinReputation, canRedeemGoalAchievementBadge,
    // hasRedeemedBadge, hasClaimedExcessFundsShare, getSimulatedFactor,
    // isTokenEligible, getEligibleTokens, getActionMapping, getUserContributedTokens.
}
```