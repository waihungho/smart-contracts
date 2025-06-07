Okay, let's design a smart contract concept that incorporates several advanced ideas: **An Evolving Protocol with Decentralized Feature Unlocking based on Community Interaction, Prediction Markets, and Time-Sensitive Mechanics.**

We'll call it "The Epoch Forge". Users interact with the contract to propose "Epoch Transitions". These transitions contain proposals for changing contract parameters or unlocking new functionalities (features, like new tokenomics, governance mechanisms, etc.). The transitions are approved based on weighted voting (influence), which is earned through participation, successful predictions (linking to oracles), and holding specific time-locked stakes. The contract moves through different 'Epochs', each with its own rules and unlocked features.

This blends:
1.  **Dynamic Parameters:** Contract rules change over time based on community action.
2.  **Feature Flags/Progressive Unlocking:** Not all functionality is available at genesis.
3.  **Influence/Reputation System:** Not just token balance, but participation matters.
4.  **Prediction Market Elements:** Oracle integration for verifiable outcomes affecting influence/rewards.
5.  **Time-Sensitive Mechanics:** Epochs advance, stakes might be time-locked or yield decay.
6.  **Custom Tokenomics:** The native token (`FORGE`) is central to interactions, staking, and rewards.
7.  **Simple Governance/Proposal System:** Weighted voting for epoch transitions.

This is quite complex for a single contract example, so we'll simulate some external interactions (like oracle calls) and simplify the prediction market part. The "feature unlocking" will be represented by state variables or parameters that enable/disable certain actions or change logic.

---

**Contract Name:** `EpochForge`

**Concept:** A protocol token (`FORGE`) where users earn influence by participating in protocol activities, particularly by submitting and voting on "Epoch Transition" proposals. Successful predictions tied to oracle outcomes and prolonged staking boost influence. Influence determines voting power and access to potential future features unlocked in new epochs. The contract state and rules evolve as epochs advance.

**Outline:**

1.  **Interfaces:** None required for this self-contained example, but would need `AggregatorV3Interface` for real oracle use.
2.  **Libraries:** None required for this scope.
3.  **Events:** Signalling key actions like token transfers (internal), epoch advancement, proposal submission/voting, influence changes, prophecy resolution.
4.  **Error Handling:** Custom errors for clarity.
5.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `onlyDuringEpoch`, `requiresInfluence`.
6.  **State Variables:**
    *   Token: `FORGE` token details (name, symbol, supply, balances).
    *   Core State: Owner, paused status, current epoch number.
    *   User Data: Influence mapping, time-locked stakes mapping, prediction records, badge status.
    *   Epochs: Current epoch parameters, parameters for the next proposed epoch, epoch transition proposals data.
    *   Proposals: Proposal details, vote counts, proposer, parameters proposed.
    *   Prediction Market (Simplified): Prediction details, oracle integration addresses/feeds (simulated), outcome resolution.
    *   Parameters: Various system parameters (stake amounts, influence multipliers, voting thresholds, epoch durations).
    *   Fees/Treasury: Protocol fee balance.
7.  **Structs:** `EpochParameters`, `EpochTransitionProposal`, `UserPrediction`.
8.  **Internal Functions:** Helpers for managing token balances, updating influence, awarding badges, processing votes, resolving predictions.
9.  **Public/External Functions (Categorized):**
    *   **Token Interaction:** `balanceOf`, `totalSupply`, `stakeFORGE`, `unstakeFORGE`.
    *   **Influence & Badges:** `getUserInfluence`, `getUserBadgeStatus`, `getInfluenceParameters`.
    *   **Epochs & Transitions:** `getCurrentEpoch`, `getEpochParameters`, `submitEpochTransitionProposal`, `voteOnProposal`, `getProposalDetails`, `advanceEpoch`, `setNextEpochParameters`.
    *   **Prediction Market (Simplified):** `submitPrediction`, `resolvePrediction`, `getUserPrediction`, `setPredictionParameters`.
    *   **Staking & Time-Locking:** `stakeTimeLockedFORGE`, `claimTimeLockedStake`, `getUserTimeLockedStake`.
    *   **Admin & Parameters:** `setCoreParameters`, `setEpochParameters`, `setPredictionOracle`, `withdrawAdminFees`, `pauseContract`, `unpauseContract`.
    *   **Views:** Helper views for various data lookups.

**Function Summary (≥ 20 Functions):**

1.  `constructor()`: Initializes owner, initial parameters, mints initial token supply.
2.  `balanceOf(address account) view`: Returns the FORGE balance of an account. (Standard ERC-20 view)
3.  `totalSupply() view`: Returns the total supply of FORGE. (Standard ERC-20 view)
4.  `stakeFORGE(uint256 amount)`: Stakes a user's FORGE balance in the contract for general influence/rewards.
5.  `unstakeFORGE(uint256 amount)`: Allows a user to unstake general staked FORGE.
6.  `getUserInfluence(address account) view`: Returns the current influence score of an account.
7.  `getUserBadgeStatus(address account, uint256 badgeId) view`: Returns true if a user has earned a specific badge.
8.  `getCurrentEpoch() view`: Returns the current active epoch number.
9.  `getEpochParameters(uint256 epochNumber) view`: Returns parameters for a specific epoch number.
10. `submitEpochTransitionProposal(EpochParameters calldata newEpochParams, uint256 minInfluenceToPropose)`: Allows users with sufficient influence to propose parameters for the *next* epoch. Requires staking FORGE.
11. `voteOnProposal(uint256 proposalId, bool approve)`: Allows users to vote on an active epoch transition proposal. Vote weight is based on influence. Requires staking FORGE for voting power.
12. `getProposalDetails(uint256 proposalId) view`: Returns details of a specific epoch transition proposal (parameters, votes, status).
13. `advanceEpoch()`: Callable by anyone (or owner/trusted role) when current epoch duration ends and a qualified proposal has passed. Transitions to the next epoch, applies parameters, distributes rewards, cleans up old proposals.
14. `submitPrediction(uint256 oracleFeedId, bytes32 predictionOutcomeHash, uint256 stakeAmount, uint256 outcomeValidityTimestamp)`: Users stake FORGE to predict an outcome based on a specific oracle feed before a certain time.
15. `resolvePrediction(uint256 predictionId, uint256 oracleResult)`: Callable by owner/trusted oracle role to provide the oracle result and resolve a specific prediction. Correct predictors gain significant influence and potential rewards from incorrect predictors' stakes.
16. `getUserPrediction(uint256 predictionId) view`: Returns details of a user's specific prediction.
17. `stakeTimeLockedFORGE(uint256 amount, uint256 lockDuration) payable`: Stakes FORGE for a fixed duration. Provides higher influence gain or yield but cannot be withdrawn until lock expires. Requires sending FORGE token (or eth if we make it payable, but FORGE is better). Let's use internal token transfer.
18. `claimTimeLockedStake(uint256 stakeId)`: Allows user to claim a time-locked stake after its duration has passed.
19. `getUserTimeLockedStake(uint256 stakeId) view`: Returns details of a specific time-locked stake.
20. `setCoreParameters(...) onlyOwner`: Sets fundamental contract parameters (e.g., minimum influence to propose, voting threshold, epoch duration).
21. `setInfluenceParameters(...) onlyOwner`: Sets parameters related to influence gain/loss for different actions.
22. `setPredictionOracle(uint256 oracleFeedId, address oracleAddress, uint256 oraclePrecision) onlyOwner`: Links an oracle feed ID to a specific oracle address (simulated).
23. `withdrawAdminFees() onlyOwner`: Allows owner to withdraw collected protocol fees.
24. `pauseContract() onlyOwner`: Pauses core contract interactions.
25. `unpauseContract() onlyOwner`: Unpauses the contract.
26. `getContractState() view`: Returns a summary of key contract state variables (current epoch, total supply, paused status, etc.).
27. `getInfluenceParameters() view`: Returns current influence gain/loss parameters.
28. `getProposalCount() view`: Returns the total number of proposals ever submitted.
29. `getProposalIdsByEpoch(uint256 epochNumber) view`: Returns a list of proposal IDs submitted during a specific epoch.
30. `getUserStakedAmount(address account) view`: Returns the total general staked amount for a user.

This gives us 30 functions, covering token handling, core mechanics, state evolution, prediction, staking variations, and administration, embodying the advanced concepts requested.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EpochForge
 * @dev An evolving protocol where community interaction, influence, and predictions drive Epoch transitions
 *      and unlock new features. Utilizes a native token (FORGE), dynamic parameters, and time-based mechanics.
 *
 * Outline:
 * - Events: Signalling key state changes.
 * - Errors: Custom error definitions.
 * - Modifiers: Access control and state checks.
 * - Structs: Data structures for Epochs, Proposals, and Predictions.
 * - State Variables: Core protocol state, user data, epoch/proposal data, parameters.
 * - Internal Functions: Core logic helpers (_updateInfluence, _awardBadge, token transfers).
 * - External/Public Functions: User interactions, admin controls, data lookups.
 *   - Token Interaction: staking, unstaking.
 *   - Influence & Badges: querying influence, badge status.
 *   - Epochs & Transitions: proposing, voting, advancing epochs, getting parameters.
 *   - Prediction Market (Simplified): submitting predictions, resolving, querying.
 *   - Time-Locked Staking: staking for duration, claiming.
 *   - Admin & Parameters: setting rules, withdrawing fees, pausing.
 *   - Views: Reading various contract data.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Using interface for clarity, though we implement internally
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Standard library
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Protection for stake claims

// Mock ERC20 interface for internal use reminder - not deploying a standard ERC20 externally
// interface IERC20 {
//     function totalSupply() external view returns (uint256);
//     function balanceOf(address account) external view returns (uint256);
//     function transfer(address to, uint256 amount) external returns (bool);
//     // Add other standard functions if needed, but we keep it minimal for this concept
// }


// --- Events ---

event TokensMinted(address indexed to, uint256 amount);
event TokensBurned(address indexed from, uint224 amount); // uint224 to fit in indexed topic
event TokensStaked(address indexed user, uint256 amount, bool isTimeLocked, uint256 stakeId);
event TokensUnstaked(address indexed user, uint256 amount, bool isTimeLocked, uint256 stakeId);

event InfluenceUpdated(address indexed user, uint256 newInfluence);
event BadgeAwarded(address indexed user, uint256 badgeId);

event EpochTransitionProposed(uint256 indexed proposalId, address indexed proposer, uint256 epochNumber, uint256 proposalTimestamp);
event VoteCast(address indexed voter, uint256 indexed proposalId, bool approved, uint256 influenceWeight);
event EpochAdvanced(uint256 indexed oldEpoch, uint256 indexed newEpoch, uint256 transitionTimestamp);

event PredictionSubmitted(address indexed user, uint256 indexed predictionId, uint256 oracleFeedId, uint256 stakeAmount);
event PredictionResolved(uint256 indexed predictionId, uint256 oracleResult, bool indexed isCorrect);
event ProphecyRewardDistributed(uint256 indexed predictionId, address indexed user, uint256 rewardAmount, uint256 influenceGain);

event ParametersUpdated(string indexed paramName, address indexed sender);
event AdminFeeWithdrawn(address indexed to, uint256 amount);
event Paused(address account);
event Unpaused(address account);


// --- Errors ---

error NotOwner();
error PausedState();
error NotPausedState();
error InsufficientBalance(uint256 required, uint256 available);
error InsufficientInfluence(uint256 required, uint256 available);
error InvalidAmount();
error NothingToUnstake();
error ProposalDoesNotExist();
error AlreadyVotedOnProposal();
error EpochTransitionNotReady(string reason);
error NoWinningProposal();
error PredictionDoesNotExist();
error PredictionAlreadyResolved();
error PredictionStillPending();
error InvalidPredictionOutcome();
error OracleFeedNotConfigured();
error TimeLockNotExpired(uint256 unlockTimestamp);
error StakeDoesNotExist();
error CannotVoteOnOwnProposal();
error ProposalPeriodNotOver();
error InvalidEpochDuration();
error InvalidTimeLockDuration();


// --- Modifiers ---

modifier onlyOwner() {
    if (msg.sender != owner) revert NotOwner();
    _;
}

modifier whenNotPaused() {
    if (paused) revert PausedState();
    _;
}

modifier whenPaused() {
    if (!paused) revert NotPausedState();
    _;
}

// Only callable during a specific epoch range (e.g., feature unlocked in Epoch 2 onwards)
// modifier onlyDuringEpoch(uint256 minEpoch, uint256 maxEpoch) {
//     if (currentEpoch < minEpoch || (maxEpoch != 0 && currentEpoch > maxEpoch)) revert InvalidEpoch(); // Example of how this could work
//     _;
// }

// Requires a minimum influence score (example: proposing requires influence)
modifier requiresInfluence(uint256 minInfluence) {
    if (userInfluence[msg.sender] < minInfluence) revert InsufficientInfluence(minInfluence, userInfluence[msg.sender]);
    _;
}


// --- Structs ---

struct EpochParameters {
    uint256 epochDuration; // Duration in seconds for this epoch
    uint256 minInfluenceToPropose; // Min influence needed to submit a proposal for the *next* epoch
    uint256 proposalVotingPeriod; // Duration in seconds for voting on proposals for the *next* epoch
    uint256 minVotesForProposal; // Minimum number of votes (or influence weight) for a proposal to be eligible
    uint256 requiredVoteMajority; // Percentage (e.g., 5100 for 51%) needed for proposal approval
    uint256 stakingInfluenceMultiplier; // Multiplier for influence gain from general staking
    uint256 timeLockInfluenceMultiplier; // Multiplier for influence gain from time-locked staking
    uint256 predictionInfluenceMultiplier; // Multiplier for influence gain from correct predictions
    // Future fields could unlock features: bool featureXEnabled; uint256 featureYParameter;
}

struct EpochTransitionProposal {
    uint256 proposalId;
    address proposer;
    EpochParameters proposedParameters;
    uint256 submissionTimestamp;
    uint256 totalInfluenceVotesFor;
    uint256 totalInfluenceVotesAgainst;
    mapping(address => bool) hasVoted; // Who has voted
    bool isResolved; // Has the proposal voting period ended
    bool isApproved; // Was the proposal approved
    uint256 epochNumber; // The epoch this proposal is for (the NEXT one)
}

struct UserPrediction {
    uint256 predictionId;
    address user;
    uint256 oracleFeedId;
    bytes32 predictionOutcomeHash; // Hash of the predicted outcome (e.g., keccak256(abi.encode(true/false)))
    uint256 stakeAmount;
    uint256 outcomeValidityTimestamp; // Timestamp by which the outcome should be verifiable
    bool isResolved;
    bool isCorrect; // True if prediction was correct
    uint256 resolutionTimestamp;
}

struct TimeLockedStake {
    uint256 stakeId;
    address user;
    uint256 amount;
    uint256 lockDuration; // In seconds
    uint256 unlockTimestamp;
    bool isClaimed;
}


// --- State Variables ---

address public owner;
bool public paused;

// Token State (Internal FORGE token)
string public name = "Epoch Forge Token";
string public symbol = "FORGE";
uint8 public decimals = 18;
uint256 private _totalSupply;
mapping(address => uint256) private _balances;
mapping(address => uint256) public userStakedAmount; // General staked amount
mapping(address => uint256) public userTotalStakedAmount; // Total (general + time-locked) - for tracking
uint256 public totalProtocolFees; // FORGE collected as fees

// Influence & Badges
mapping(address => uint256) public userInfluence;
mapping(address => mapping(uint256 => bool)) public userBadgeStatus; // badgeId => bool (earned)

// Epochs & Transitions
uint256 public currentEpoch = 1;
uint256 public currentEpochStartTime;
mapping(uint256 => EpochParameters) public epochParameters; // Parameters for each epoch number
EpochParameters public nextEpochProposedParameters; // Parameters proposed for the *next* epoch if approved
uint256 public lastEpochTransitionTimestamp;

mapping(uint256 => EpochTransitionProposal) public epochTransitionProposals;
uint256 public nextProposalId = 1;
mapping(uint256 => uint256[]) public epochProposalIds; // Map epoch number to list of proposal IDs created in it

// Prediction Market (Simplified)
mapping(uint256 => UserPrediction) public userPredictions;
uint256 public nextPredictionId = 1;
// Simulate oracle feeds: feedId => oracleAddress (realistically requires AggregatorV3Interface)
mapping(uint256 => address) public simulatedOracleFeeds;
// Simulate oracle results: feedId => timestamp => result (realistically comes from chainlink VRF/Aggregator)
mapping(uint256 => mapping(uint256 => uint256)) public simulatedOracleResults;


// Time-Locked Staking
mapping(uint256 => TimeLockedStake) public timeLockedStakes;
uint256 public nextTimeLockedStakeId = 1;
mapping(address => uint256[]) public userTimeLockedStakeIds; // Track stakes per user


// Parameters (some duplicated in EpochParameters, but these are global defaults/mins)
uint256 public constant MIN_TIME_LOCK_DURATION = 1 days; // Example minimum lock duration
uint256 public proposalStakeAmount; // Amount of FORGE required to submit a proposal
uint256 public voteStakeAmount;     // Amount of FORGE required to cast a vote (per proposal)
uint256 public predictionMinStake;  // Minimum stake for a prediction


// --- Constructor ---

constructor(uint256 initialSupply) ReentrancyGuard() {
    owner = msg.sender;
    paused = false;

    // Mint initial supply to the owner
    _mint(owner, initialSupply);

    // Set initial parameters for Epoch 1
    currentEpochStartTime = block.timestamp;
    epochParameters[1] = EpochParameters({
        epochDuration: 30 days, // Example: Epoch 1 lasts 30 days
        minInfluenceToPropose: 100, // Example: Need 100 influence to propose for Epoch 2
        proposalVotingPeriod: 7 days, // Example: Voting for Epoch 2 proposals lasts 7 days
        minVotesForProposal: 10, // Example: Need at least 10 influence votes cast on a proposal
        requiredVoteMajority: 5100, // Example: 51% influence weight needed to pass
        stakingInfluenceMultiplier: 1, // Base multiplier
        timeLockInfluenceMultiplier: 2, // Time-locking is better for influence
        predictionInfluenceMultiplier: 5 // Correct predictions are highly rewarded
    });

    // Set initial global parameters
    proposalStakeAmount = 50 ether; // Example stake amounts (using 18 decimals)
    voteStakeAmount = 5 ether;
    predictionMinStake = 10 ether;

    emit TokensMinted(owner, initialSupply);
}


// --- Token Interaction (Internal FORGE) ---

function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
}

function totalSupply() external view returns (uint256) {
    return _totalSupply;
}

// Internal mint function
function _mint(address account, uint256 amount) internal {
    _totalSupply += amount;
    _balances[account] += amount;
    emit TokensMinted(account, amount);
}

// Internal burn function
function _burn(address account, uint256 amount) internal {
    uint256 accountBalance = _balances[account];
    if (accountBalance < amount) revert InsufficientBalance(amount, accountBalance);
    unchecked {
        _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;
    emit TokensBurned(account, uint224(amount)); // Safe cast due to checks
}

// Internal transfer function
function _transfer(address sender, address recipient, uint256 amount) internal {
    uint256 senderBalance = _balances[sender];
    if (senderBalance < amount) revert InsufficientBalance(amount, senderBalance);
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;
    // We could emit a Transfer event here if we fully implemented ERC20,
    // but keeping it minimal for internal use only.
}

// Standard Staking (flexible withdrawal)
function stakeFORGE(uint256 amount) external whenNotPaused {
    if (amount == 0) revert InvalidAmount();
    _transfer(msg.sender, address(this), amount);
    userStakedAmount[msg.sender] += amount;
    userTotalStakedAmount[msg.sender] += amount;
    // Base influence gain from staking (can be continuous or based on duration/amount)
    // Let's apply a small influence gain per stake for simplicity here,
    // a more advanced system might have continuous influence based on stake amount over time.
    _updateInfluence(msg.sender, amount / 10, "staking"); // Example: 1/10 influence per staked token
    emit TokensStaked(msg.sender, amount, false, 0); // Use 0 for non-time-locked stakeId
}

function unstakeFORGE(uint256 amount) external whenNotPaused nonReentrant {
    if (amount == 0) revert InvalidAmount();
    if (userStakedAmount[msg.sender] < amount) revert InsufficientBalance(amount, userStakedAmount[msg.sender]);

    userStakedAmount[msg.sender] -= amount;
     userTotalStakedAmount[msg.sender] -= amount; // Ensure total reflects this
    _transfer(address(this), msg.sender, amount);

    // Influence might decay on unstaking, or just stop accumulating.
    // For simplicity, no influence loss on unstake here.

    emit TokensUnstaked(msg.sender, amount, false, 0);
}


// --- Influence & Badges ---

function getUserInfluence(address account) external view returns (uint256) {
    return userInfluence[account];
}

function getUserBadgeStatus(address account, uint256 badgeId) external view returns (bool) {
    return userBadgeStatus[account][badgeId];
}

function getInfluenceParameters() external view returns (EpochParameters memory) {
    return epochParameters[currentEpoch];
}

// Internal function to update influence based on action type
function _updateInfluence(address account, uint256 amount, string memory actionType) internal {
    uint256 multiplier = 0;
    // Get multiplier from current epoch parameters
    EpochParameters memory currentParams = epochParameters[currentEpoch];

    if (keccak256(abi.encodePacked(actionType)) == keccak256(abi.encodePacked("staking"))) {
        multiplier = currentParams.stakingInfluenceMultiplier;
    } else if (keccak256(abi.encodePacked(actionType)) == keccak256(abi.encodePacked("timeLockStaking"))) {
        multiplier = currentParams.timeLockInfluenceMultiplier;
    } else if (keccak256(abi.encodePacked(actionType)) == keccak256(abi.encodePacked("correctPrediction"))) {
        multiplier = currentParams.predictionInfluenceMultiplier;
    } else if (keccak256(abi.encodePacked(actionType)) == keccak256(abi.encodePacked("proposalSubmitted"))) {
        multiplier = 50; // Example base influence for submitting a proposal
    }
    // Add other action types (e.g., voting, successful proposal, etc.)

    if (multiplier > 0) {
        uint256 influenceGained = amount * multiplier;
        userInfluence[account] += influenceGained;
        emit InfluenceUpdated(account, userInfluence[account]);
        _checkAndAwardBadges(account); // Check for new badge eligibility
    }
}

// Internal function to check for and award badges
function _checkAndAwardBadges(address account) internal {
    // Example badge criteria:
    // Badge 1: Reach 1000 influence
    // Badge 2: Submit 3 proposals
    // Badge 3: Make 5 correct predictions

    if (!userBadgeStatus[account][1] && userInfluence[account] >= 1000) {
        _awardBadge(account, 1);
    }
    // Add checks for other badges based on user stats (needs more state variables to track e.g., proposal count)
    // For simplicity, only influence badge here.
}

// Internal function to award a badge
function _awardBadge(address account, uint256 badgeId) internal {
    userBadgeStatus[account][badgeId] = true;
    emit BadgeAwarded(account, badgeId);
}


// --- Epochs & Transitions ---

function getCurrentEpoch() external view returns (uint256) {
    return currentEpoch;
}

function getEpochParameters(uint256 epochNumber) external view returns (EpochParameters memory) {
    return epochParameters[epochNumber];
}

function submitEpochTransitionProposal(EpochParameters calldata newEpochParams) external whenNotPaused requiresInfluence(epochParameters[currentEpoch].minInfluenceToPropose) {
    if (block.timestamp >= currentEpochStartTime + epochParameters[currentEpoch].epochDuration) {
         revert EpochTransitionNotReady("Current epoch voting period is over or epoch needs advancing");
    }
     if (block.timestamp >= currentEpochStartTime + epochParameters[currentEpoch].epochDuration - epochParameters[currentEpoch].proposalVotingPeriod) {
         revert EpochTransitionNotReady("Proposal submission period for next epoch has ended");
     }


    if (newEpochParams.epochDuration == 0) revert InvalidEpochDuration(); // Basic sanity check

    uint256 proposalId = nextProposalId++;
    epochTransitionProposals[proposalId] = EpochTransitionProposal({
        proposalId: proposalId,
        proposer: msg.sender,
        proposedParameters: newEpochParams,
        submissionTimestamp: block.timestamp,
        totalInfluenceVotesFor: 0,
        totalInfluenceVotesAgainst: 0,
        hasVoted: new mapping(address => bool), // Initialize empty map
        isResolved: false,
        isApproved: false,
        epochNumber: currentEpoch + 1 // This proposal is for the *next* epoch
    });

    epochProposalIds[currentEpoch].push(proposalId); // Track proposal ID per originating epoch

    // Proposer stakes FORGE and gains some initial influence
     if (_balances[msg.sender] < proposalStakeAmount) revert InsufficientBalance(proposalStakeAmount, _balances[msg.sender]);
    _transfer(msg.sender, address(this), proposalStakeAmount);
    userStakedAmount[msg.sender] += proposalStakeAmount; // Consider this part of general stake for tracking
     userTotalStakedAmount[msg.sender] += proposalStakeAmount;
    _updateInfluence(msg.sender, proposalStakeAmount, "proposalSubmitted");

    emit EpochTransitionProposed(proposalId, msg.sender, currentEpoch + 1, block.timestamp);
}

function voteOnProposal(uint256 proposalId, bool approve) external whenNotPaused {
    EpochTransitionProposal storage proposal = epochTransitionProposals[proposalId];
    if (proposal.proposer == address(0)) revert ProposalDoesNotExist(); // Check if proposal exists
    if (proposal.proposer == msg.sender) revert CannotVoteOnOwnProposal(); // Cannot vote on your own proposal
    if (proposal.epochNumber != currentEpoch + 1) revert EpochTransitionNotReady("Can only vote on proposals for the next epoch"); // Only vote on proposals for the *next* epoch
    if (block.timestamp >= proposal.submissionTimestamp + epochParameters[currentEpoch].proposalVotingPeriod) revert ProposalPeriodNotOver(); // Voting period is over
    if (proposal.hasVoted[msg.sender]) revert AlreadyVotedOnProposal();

    // Voting power is based on current influence
    uint256 voterInfluence = userInfluence[msg.sender];
    if (voterInfluence == 0) revert InsufficientInfluence(1, 0); // Must have some influence to vote

     // User stakes FORGE to cast a vote
    if (_balances[msg.sender] < voteStakeAmount) revert InsufficientBalance(voteStakeAmount, _balances[msg.sender]);
    _transfer(msg.sender, address(this), voteStakeAmount);
    userStakedAmount[msg.sender] += voteStakeAmount; // Consider this part of general stake for tracking
     userTotalStakedAmount[msg.sender] += voteStakeAmount;


    if (approve) {
        proposal.totalInfluenceVotesFor += voterInfluence;
    } else {
        proposal.totalInfluenceVotesAgainst += voterInfluence;
    }
    proposal.hasVoted[msg.sender] = true;

    // Influence effect from voting can be added here
    // _updateInfluence(msg.sender, voterInfluence / 100, "voted"); // Example small influence gain

    emit VoteCast(msg.sender, proposalId, approve, voterInfluence);
}

function getProposalDetails(uint256 proposalId) external view returns (
    uint256 id,
    address proposer,
    EpochParameters memory proposedParameters,
    uint265 submissionTimestamp,
    uint256 totalInfluenceVotesFor,
    uint256 totalInfluenceVotesAgainst,
    bool isResolved,
    bool isApproved,
    uint256 forEpoch
) {
    EpochTransitionProposal storage proposal = epochTransitionProposals[proposalId];
    if (proposal.proposer == address(0)) revert ProposalDoesNotExist();

    return (
        proposal.proposalId,
        proposal.proposer,
        proposal.proposedParameters,
        proposal.submissionTimestamp,
        proposal.totalInfluenceVotesFor,
        proposal.totalInfluenceVotesAgainst,
        proposal.isResolved,
        proposal.isApproved,
        proposal.epochNumber
    );
}

function advanceEpoch() external whenNotPaused nonReentrant {
    // Check if current epoch duration has passed AND voting period for next epoch is over
    if (block.timestamp < currentEpochStartTime + epochParameters[currentEpoch].epochDuration) {
        revert EpochTransitionNotReady("Current epoch duration not over");
    }
     if (block.timestamp < currentEpochStartTime + epochParameters[currentEpoch].epochDuration - epochParameters[currentEpoch].proposalVotingPeriod + epochParameters[currentEpoch].proposalVotingPeriod) {
          // This check is redundant with the first, but explicitly states voting must be finished
          revert EpochTransitionNotReady("Proposal voting period not over");
     }


    uint256 nextEpochNumber = currentEpoch + 1;
    uint256 winningProposalId = 0;
    uint256 maxVotesFor = 0;

    // Evaluate proposals submitted for the next epoch
    uint256[] memory proposalIds = epochProposalIds[currentEpoch]; // Get proposals submitted *during* the current epoch (for the next one)

    if (proposalIds.length == 0) revert NoWinningProposal(); // Need at least one proposal

    for (uint i = 0; i < proposalIds.length; i++) {
        uint256 proposalId = proposalIds[i];
        EpochTransitionProposal storage proposal = epochTransitionProposals[proposalId];

        // Mark proposal as resolved
        proposal.isResolved = true;

        uint256 totalVotes = proposal.totalInfluenceVotesFor + proposal.totalInfluenceVotesAgainst;

        // Check if proposal meets minimum votes and majority
        if (totalVotes >= epochParameters[currentEpoch].minVotesForProposal) {
            if (proposal.totalInfluenceVotesFor * 10000 >= totalVotes * epochParameters[currentEpoch].requiredVoteMajority) { // Use 10000 for percentage calculation
                proposal.isApproved = true;
                // Find the proposal with the most 'For' votes to be the winning one
                if (proposal.totalInfluenceVotesFor > maxVotesFor) {
                    maxVotesFor = proposal.totalInfluenceVotesFor;
                    winningProposalId = proposalId;
                }
            }
        }
        // Unstake proposal and vote stakes (stakes are returned regardless of outcome)
        // This requires iterating through everyone who staked/voted, which is gas-intensive.
        // A better pattern is pull-based: users claim their stakes back after the epoch advance.
        // Let's implement pull-based claiming.
        //emit ProposalResolved(proposalId, proposal.isApproved); // Assuming we had this event
    }

    if (winningProposalId == 0) revert NoWinningProposal(); // No proposal passed criteria

    // Apply winning proposal parameters
    EpochTransitionProposal storage winningProposal = epochTransitionProposals[winningProposalId];
    epochParameters[nextEpochNumber] = winningProposal.proposedParameters;

    // Transition to the next epoch
    currentEpoch = nextEpochNumber;
    currentEpochStartTime = block.timestamp;
    lastEpochTransitionTimestamp = block.timestamp;

    // Reward winning proposer and voters (optional, could be based on parameters)
    // For simplicity, influence gain is handled during submission/voting, stakes are claimed.

    emit EpochAdvanced(currentEpoch - 1, currentEpoch, block.timestamp);
    // emit WinningProposal(winningProposalId); // Assuming we had this event

    // Note: Stakes from proposals and votes are *not* automatically returned here.
    // Users must call a separate function (e.g., claimProposalStake, claimVoteStake)
    // after the epoch has advanced to retrieve their staked FORGE. This is crucial
    // for gas efficiency and security (pull-over-push).
}

// Users call this to claim their stake back from proposals/votes after an epoch advances
// This is a simplified example; real implementation needs detailed tracking of stakes per proposal/vote
function claimEpochStake() external whenNotPaused nonReentrant {
     // This function is conceptual. A real implementation needs state to track:
     // - How much FORGE is staked by this user specifically for proposals/votes
     // - Which epoch these stakes were for
     // - If the epoch they staked in has finished evaluating proposals
     // - Ensure stakes are only claimed once.

     // Simplified placeholder: This logic assumes all 'userStakedAmount' that isn't time-locked
     // becomes claimable after ANY epoch advance. This is NOT how a real system would work.
     // A proper system requires mapping user => proposalId/voteId => stake amount.

     // For this example, we will skip implementing the detailed claim logic
     // and just acknowledge that it's a necessary piece for the staking model.
     // The stakeFORGE/unstakeFORGE functions represent general staking, not
     // proposal/vote specific staking which needs separate tracking.

     // Revert placeholder to indicate this requires detailed implementation
     revert("Claiming proposal/vote stakes requires detailed state tracking not fully implemented in this example.");

     // If it were implemented, it would look something like:
     /*
     uint256 claimableAmount = _getUserClaimableEpochStake(msg.sender); // Internal function to calculate
     if (claimableAmount == 0) revert NothingToUnstake();

     // Update internal state to mark stake as claimed
     _markUserEpochStakeClaimed(msg.sender, claimableAmount);

     _transfer(address(this), msg.sender, claimableAmount);
     userStakedAmount[msg.sender] -= claimableAmount; // Deduct from the general stake tracked
     userTotalStakedAmount[msg.sender] -= claimableAmount;

     // Emit appropriate event
     // emit EpochStakeClaimed(msg.sender, claimableAmount);
     */
}


// Admin function to set parameters for the *next* epoch if no proposal passes, or as a default
function setNextEpochParameters(EpochParameters calldata params) external onlyOwner {
    nextEpochProposedParameters = params;
    emit ParametersUpdated("nextEpochProposedParameters", msg.sender);
}


// --- Prediction Market (Simplified) ---

// NOTE: A real prediction market requires secure oracle integration (like Chainlink VRF/Aggregator)
// and careful handling of outcomes and stake distribution. This is a simplified representation.

function submitPrediction(uint256 oracleFeedId, bytes32 predictionOutcomeHash, uint256 stakeAmount, uint256 outcomeValidityTimestamp) external whenNotPaused {
    if (stakeAmount < predictionMinStake) revert InvalidAmount();
     if (simulatedOracleFeeds[oracleFeedId] == address(0)) revert OracleFeedNotConfigured();
    if (block.timestamp >= outcomeValidityTimestamp) revert InvalidAmount(); // Prediction window closed

    if (_balances[msg.sender] < stakeAmount) revert InsufficientBalance(stakeAmount, _balances[msg.sender]);
    _transfer(msg.sender, address(this), stakeAmount);

    uint256 predictionId = nextPredictionId++;
    userPredictions[predictionId] = UserPrediction({
        predictionId: predictionId,
        user: msg.sender,
        oracleFeedId: oracleFeedId,
        predictionOutcomeHash: predictionOutcomeHash,
        stakeAmount: stakeAmount,
        outcomeValidityTimestamp: outcomeValidityTimestamp,
        isResolved: false,
        isCorrect: false,
        resolutionTimestamp: 0 // Will be set on resolution
    });

    // Influence gain from submitting a prediction (can be minor)
    // _updateInfluence(msg.sender, stakeAmount / 50, "predictionSubmitted"); // Example influence gain

    emit PredictionSubmitted(msg.sender, predictionId, oracleFeedId, stakeAmount);
}

// Callable by a designated oracle address or owner to resolve a prediction
// In a real system, this would be an oracle callback function
function resolvePrediction(uint256 predictionId, uint256 oracleResult) external whenNotPaused {
    UserPrediction storage prediction = userPredictions[predictionId];

    if (prediction.user == address(0)) revert PredictionDoesNotExist();
    if (prediction.isResolved) revert PredictionAlreadyResolved();
    if (block.timestamp < prediction.outcomeValidityTimestamp) revert PredictionStillPending(); // Outcome timestamp not reached

    // --- SIMULATED ORACLE RESULT CHECK ---
    // In a real system, you'd use Chainlink or similar to get verifiable results.
    // Here, we'll simulate by looking up a pre-set result for the feed and timestamp.
    // This is highly insecure for production!
    uint256 simulatedResult = simulatedOracleResults[prediction.oracleFeedId][prediction.outcomeValidityTimestamp];
    if (simulatedResult == 0) revert InvalidPredictionOutcome(); // Simulated result not set

    // Compare user's predicted hash with the hash of the actual oracle result
    // Assumes oracleResult is a value (e.g., price) and predictionOutcomeHash is keccak256(abi.encode(value))
    // This is a simplification. Real oracle proofs are complex.
    bytes32 actualOutcomeHash = keccak256(abi.encode(simulatedResult));

    prediction.isResolved = true;
    prediction.resolutionTimestamp = block.timestamp;

    // Distribute stakes/rewards and update influence
    // This is a very basic winner-takes-all from losers model. Real markets are complex.
    if (prediction.predictionOutcomeHash == actualOutcomeHash) {
        prediction.isCorrect = true;
        // Reward: User gets their stake back + potential share of losing stakes
        // Influence: Significant gain for correct prediction
         _updateInfluence(prediction.user, prediction.stakeAmount, "correctPrediction");

        // In a real system, stakes from incorrect predictions would pool and be distributed.
        // Here, we'll just return the user's stake and maybe mint extra FORGE or use protocol fees.
        // Let's just return the stake and give influence for this example.
        _transfer(address(this), prediction.user, prediction.stakeAmount);
        emit ProphecyRewardDistributed(predictionId, prediction.user, prediction.stakeAmount, prediction.stakeAmount * epochParameters[currentEpoch].predictionInfluenceMultiplier);

    } else {
        prediction.isCorrect = false;
        // User loses their stake. Stake goes to protocol fees or reward pool.
        totalProtocolFees += prediction.stakeAmount;
        // No influence gain, maybe influence loss depending on parameters
        // _updateInfluence(prediction.user, prediction.stakeAmount, "incorrectPrediction"); // Example influence loss
    }

    emit PredictionResolved(predictionId, simulatedResult, prediction.isCorrect);
}

// Admin function to simulate setting an oracle result (for testing)
function setSimulatedOracleResult(uint256 oracleFeedId, uint256 outcomeValidityTimestamp, uint256 result) external onlyOwner {
    simulatedOracleResults[oracleFeedId][outcomeValidityTimestamp] = result;
    // In a real system, this would not be a public function.
}

function getUserPrediction(uint256 predictionId) external view returns (UserPrediction memory) {
     UserPrediction storage prediction = userPredictions[predictionId];
    if (prediction.user == address(0)) revert PredictionDoesNotExist();
    return prediction;
}

function setPredictionParameters(uint256 minStake) external onlyOwner {
    predictionMinStake = minStake;
    emit ParametersUpdated("predictionMinStake", msg.sender);
}

function setPredictionOracle(uint256 oracleFeedId, address oracleAddress, uint256 oraclePrecision) external onlyOwner {
     // In a real system, this would configure how to interact with AggregatorV3Interface
     // simulatedOracleFeeds[oracleFeedId] = oracleAddress; // Just store the address for lookup example
     // (Oracle precision is unused in this mock)
     emit ParametersUpdated("predictionOracle", msg.sender);
}


// --- Time-Locked Staking ---

function stakeTimeLockedFORGE(uint256 amount, uint256 lockDuration) external whenNotPaused {
    if (amount == 0 || lockDuration < MIN_TIME_LOCK_DURATION) revert InvalidAmount();

    if (_balances[msg.sender] < amount) revert InsufficientBalance(amount, _balances[msg.sender]);
    _transfer(msg.sender, address(this), amount);

    uint256 stakeId = nextTimeLockedStakeId++;
    timeLockedStakes[stakeId] = TimeLockedStake({
        stakeId: stakeId,
        user: msg.sender,
        amount: amount,
        lockDuration: lockDuration,
        unlockTimestamp: block.timestamp + lockDuration,
        isClaimed: false
    });

    userTimeLockedStakeIds[msg.sender].push(stakeId);
     userTotalStakedAmount[msg.sender] += amount;

    // Significant influence boost for time-locked staking
    _updateInfluence(msg.sender, amount, "timeLockStaking"); // Influence proportional to amount AND duration implicitly (by locking)

    emit TokensStaked(msg.sender, amount, true, stakeId);
}

function claimTimeLockedStake(uint256 stakeId) external whenNotPaused nonReentrant {
    TimeLockedStake storage stake = timeLockedStakes[stakeId];

    if (stake.user == address(0) || stake.user != msg.sender) revert StakeDoesNotExist();
    if (stake.isClaimed) revert StakeDoesNotExist(); // Already claimed
    if (block.timestamp < stake.unlockTimestamp) revert TimeLockNotExpired(stake.unlockTimestamp);

    stake.isClaimed = true;
     userTotalStakedAmount[msg.sender] -= stake.amount; // Deduct from total staked

    _transfer(address(this), msg.sender, stake.amount);

    // Influence might decay or stop accumulating after claim.
    // For simplicity, no influence change on claim here.

    emit TokensUnstaked(msg.sender, stake.amount, true, stakeId);
}

function getUserTimeLockedStake(uint256 stakeId) external view returns (TimeLockedStake memory) {
     TimeLockedStake storage stake = timeLockedStakes[stakeId];
    if (stake.user == address(0)) revert StakeDoesNotExist();
    return stake;
}

function getUserTimeLockedStakeIds(address account) external view returns (uint256[] memory) {
    return userTimeLockedStakeIds[account];
}

function getUserStakedAmount(address account) external view returns (uint256 generalStake, uint256 totalStaked) {
     return (userStakedAmount[account], userTotalStakedAmount[account]);
}


// --- Admin & Parameters ---

function setCoreParameters(uint256 _proposalStakeAmount, uint256 _voteStakeAmount, uint256 _minTimeLockDuration) external onlyOwner {
    proposalStakeAmount = _proposalStakeAmount;
    voteStakeAmount = _voteStakeAmount;
    // MIN_TIME_LOCK_DURATION is constant, cannot be changed after deployment
    // MIN_TIME_LOCK_DURATION = _minTimeLockDuration; // This line is illustrative but would cause error
    emit ParametersUpdated("coreParameters", msg.sender);
}

function setEpochParameters(uint256 epochNumber, EpochParameters calldata params) external onlyOwner {
     // Only allow setting future epoch parameters or correcting the very next one before proposal period starts
     if (epochNumber <= currentEpoch) revert InvalidAmount(); // Cannot change past/current epoch params via this fn

    epochParameters[epochNumber] = params;
    emit ParametersUpdated("epochParameters", msg.sender);
}


function withdrawAdminFees() external onlyOwner {
    if (totalProtocolFees == 0) revert NothingToUnstake(); // Or a specific error like NoFeesCollected

    uint256 amount = totalProtocolFees;
    totalProtocolFees = 0;
    _transfer(address(this), owner, amount);
    emit AdminFeeWithdrawn(owner, amount);
}

function pauseContract() external onlyOwner whenNotPaused {
    paused = true;
    emit Paused(msg.sender);
}

function unpauseContract() external onlyOwner whenPaused {
    paused = false;
    emit Unpaused(msg.sender);
}

function getContractState() external view returns (
    uint256 currentEpoch_,
    uint256 currentEpochStartTime_,
    bool paused_,
    uint256 totalSupply_,
    uint256 totalProtocolFees_,
    uint256 nextProposalId_,
    uint256 nextPredictionId_,
    uint256 nextTimeLockedStakeId_
) {
    return (
        currentEpoch,
        currentEpochStartTime,
        paused,
        _totalSupply,
        totalProtocolFees,
        nextProposalId,
        nextPredictionId,
        nextTimeLockedStakeId
    );
}

// Helper view for number of proposals submitted in a specific epoch
function getEpochProposalCount(uint256 epochNumber) external view returns (uint256) {
    return epochProposalIds[epochNumber].length;
}

// Helper view for total number of proposals ever
function getProposalCount() external view returns (uint256) {
    return nextProposalId - 1; // proposalIds are 1-indexed
}


// Function to get specific oracle feed details (simulated)
function getSimulatedOracleFeed(uint256 oracleFeedId) external view returns (address) {
     return simulatedOracleFeeds[oracleFeedId];
}

// Function to get specific simulated oracle result (for testing/verification)
function getSimulatedOracleResult(uint256 oracleFeedId, uint256 outcomeValidityTimestamp) external view returns (uint256) {
     return simulatedOracleResults[oracleFeedId][outcomeValidityTimestamp];
}

}
```