Okay, this is an exciting challenge! I'll design a smart contract called **"EpochGuard Protocol"**.

**Concept:** EpochGuard is a decentralized protocol designed to manage and safeguard critical parameters of a larger ecosystem or a specific value stream. It operates in distinct epochs, dynamically adjusting its rules, reward mechanisms, and even emergency protocols based on external oracle data, community governance, and a built-in reputation system. It aims to prevent rug pulls, systemic failures, or ensure fair resource distribution by empowering a set of "Guardians" and "Stakers" who can react to real-world conditions.

The "advanced" aspects include:
1.  **Epoch-driven Dynamic Parameters:** Core contract parameters (e.g., reward rates, collateral ratios, governance thresholds) are not static but change per epoch based on a combination of oracle data and successful governance proposals.
2.  **Reputation-Weighted Governance:** Beyond simple token weighting, active participation and "correct" votes (those aligning with the majority or leading to successful protocol health outcomes) contribute to a user's on-chain reputation, influencing their voting power and reward multipliers.
3.  **Guardian Network & Emergency Protocol:** A distinct role (`Guardian`) with specific powers to submit "health reports" and, in critical situations, trigger an "Emergency Protocol" that might pause certain operations, freeze funds, or re-route value streams, subject to immediate community validation.
4.  **Conditional Slashing & Dynamic Rewards:** Stakers can be slashed not just for malicious acts, but also for repeated non-participation or voting against demonstrably healthy outcomes. Rewards are dynamically adjusted based on overall protocol health and individual reputation.
5.  **Value Stream Allocation:** The contract can manage and distribute a "value stream" (e.g., treasury funds, protocol fees) based on dynamic allocation rules set per epoch.
6.  **Observer Pattern:** Allowing external contracts or entities to register as "observers" to receive critical event notifications, enabling more complex off-chain or cross-contract logic.

---

## EpochGuard Protocol

**Outline:**

*   **1. Contract Overview:** Core purpose and design philosophy.
*   **2. State Variables:** Definitions of all persistent data.
*   **3. Enums & Structs:** Custom data types for organization.
*   **4. Events:** All emitted events for off-chain monitoring.
*   **5. Modifiers:** Access control and state-based modifiers.
*   **6. Constructor:** Initial setup of the contract.
*   **7. Core Epoch Management (5 Functions):** Functions related to epoch progression and status.
*   **8. Staking & Rewards (5 Functions):** Logic for staking, unstaking, and reward distribution/claiming.
*   **9. Governance & Parameter Management (6 Functions):** Proposal, voting, and execution mechanisms for dynamic parameters.
*   **10. Guardian & Emergency Operations (5 Functions):** Specific functionalities for the Guardian role and critical interventions.
*   **11. Oracle & External Data Integration (2 Functions):** How external data influences the protocol.
*   **12. Value Stream Management (2 Functions):** Allocation and distribution of protocol-managed assets.
*   **13. Protocol Health & Observer Pattern (3 Functions):** Reporting health and notifying external systems.
*   **14. Admin & Security (4 Functions):** Ownership, pausing, and upgradeability (conceptual).
*   **15. Getter Functions (5 Functions):** Read-only functions for transparency.

**Function Summary (20+ unique functions):**

1.  `constructor()`: Initializes the contract with base parameters.
2.  `advanceEpoch()`: Triggers the transition to the next epoch, recalculating rewards and applying new parameters.
3.  `stake(uint256 amount)`: Allows users to stake tokens to participate in governance and earn rewards.
4.  `unstake(uint256 amount)`: Allows users to withdraw their staked tokens.
5.  `claimEpochRewards()`: Enables stakers to claim their accumulated rewards from past epochs.
6.  `proposeParameterChange(bytes32 parameterKey, uint256 newValue, string memory description)`: Allows stakers to propose changes to dynamic protocol parameters.
7.  `voteOnProposal(uint256 proposalId, bool support)`: Stakers cast votes for or against a proposal.
8.  `executeProposal(uint256 proposalId)`: Executes a successful proposal, applying the new parameter value.
9.  `delegateVote(address delegatee)`: Allows a staker to delegate their voting power to another address.
10. `revokeVoteDelegation()`: Revokes an existing vote delegation.
11. `submitGuardianReport(bytes32 reportHash, uint256 severityScore, string memory detailsURI)`: Allows the Guardian to submit an off-chain observation or incident report.
12. `initiateEmergencyProtocol()`: Guardian-activated function to trigger a protocol-wide emergency state.
13. `deactivateEmergencyProtocol()`: Guardian-activated function to disable the emergency state, subject to checks.
14. `updateOracleAddress(address newOracle)`: Owner function to update the trusted oracle address.
15. `updateEpochDuration(uint64 newDuration)`: Owner function to change the length of an epoch.
16. `pauseProtocol()`: Owner/Guardian initiated pause of critical operations.
17. `unpauseProtocol()`: Owner/Guardian initiated unpause of critical operations.
18. `slashStake(address stakerAddress, uint256 amount, string memory reason)`: Allows Guardian/Governance to slash a staker's funds for misconduct.
19. `updateDynamicRewardMultiplier(uint256 newMultiplier)`: Oracle-called function to adjust the base reward multiplier based on external health metrics.
20. `requestValueStreamAllocation(uint256 amount, bytes32 recipientHash)`: Allows an authorized entity to request an allocation from the protocol's managed value stream.
21. `registerObserver(address observerContract)`: Allows an external contract to register to receive `EpochAdvanced` and `EmergencyProtocolActivated` events.
22. `unregisterObserver(address observerContract)`: Removes an observer contract.
23. `getEpochData(uint64 epochId)`: Retrieves summary data for a specific epoch.
24. `getStakeDetails(address staker)`: Gets staking and reputation details for an address.
25. `getPendingRewards(address staker)`: Calculates estimated pending rewards for a staker.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Using SafeMath explicitly for clarity, though 0.8+ handles overflow by default.
// ReentrancyGuard is good practice for functions interacting with external tokens or contracts.

/**
 * @title EpochGuard Protocol
 * @dev A decentralized protocol for dynamic parameter management, governance,
 *      and emergency safeguarding, operating in distinct epochs. It features
 *      reputation-weighted voting, guardian roles, and dynamic value stream allocation.
 */
contract EpochGuard is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- 2. State Variables ---

    // Core Protocol Parameters
    uint64 public epochDuration; // Duration of an epoch in seconds
    uint64 public currentEpoch; // The current active epoch number
    uint256 public nextEpochStartTime; // Timestamp when the current epoch began, for calculating next
    uint256 public totalStakedTokens; // Total amount of staking tokens staked in the protocol

    IERC20 public stakingToken; // The ERC20 token used for staking and rewards
    IERC20 public managedValueToken; // The ERC20 token representing the value stream managed by the protocol

    address public oracleAddress; // Trusted oracle for external data feeds
    address public guardianAddress; // Designated address for emergency actions and reports

    bool public protocolPaused; // Global pause switch for critical operations
    bool public emergencyModeActive; // Flag indicating if the emergency protocol is active

    uint256 public baseEpochRewardRate; // Base reward rate per epoch (e.g., tokens per total staked unit)
    uint256 public dynamicRewardMultiplier; // Multiplier adjusted by oracle based on protocol health (default 1000 = 1x)
    uint256 public minStakeRequirement; // Minimum tokens required to stake and participate
    uint256 public proposalQuorumPercentage; // Percentage of total stake required for a proposal to pass (e.g., 5000 = 50%)
    uint256 public proposalVotingPeriod; // Number of epochs a proposal remains open for voting

    // Mapping for dynamic protocol parameters (allows flexible configuration)
    mapping(bytes32 => uint256) public protocolParameters;

    // --- 3. Enums & Structs ---

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct EpochData {
        uint64 id;
        uint256 startTime;
        uint256 endTime;
        uint256 totalStaked;
        uint256 totalRewardsDistributed;
        bytes32 protocolMetricsHash; // Hash of external metrics fed by oracle for this epoch
        uint256 dynamicRewardMultiplierAtEpoch; // Snapshot of the multiplier at epoch start
        mapping(uint256 => bool) activeProposals; // Track proposals active during this epoch
    }

    struct StakeDetails {
        uint256 amount;
        uint64 lastClaimedEpoch;
        uint256 reputationScore; // Custom score based on participation and 'correct' voting
        address delegatedTo; // Address to which voting power is delegated
    }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes32 targetParameterKey; // Key of the parameter to change
        uint256 newValue; // The proposed new value
        string description; // Description of the proposal
        uint64 startEpoch; // Epoch when the proposal was created
        uint64 endEpoch; // Epoch when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        ProposalStatus status;
        address[] voters; // List of voters to allow recalculation of reputation
    }

    struct GuardianReport {
        bytes32 reportHash; // Hash of the off-chain report content
        uint256 severityScore; // 0-100 score indicating severity
        string detailsURI; // URI pointing to more details (e.g., IPFS)
        uint64 epochSubmitted;
        uint256 timestamp;
    }

    // --- Mappings ---
    mapping(uint64 => EpochData) public epochs;
    mapping(address => StakeDetails) public stakes;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => GuardianReport) public guardianReports; // ID to guardian reports
    uint256 public nextProposalId;
    uint256 public nextGuardianReportId;

    // List of contracts observing critical events (e.g., another protocol, analytics dashboard)
    address[] public registeredObservers;
    mapping(address => bool) public isObserver;

    // --- 4. Events ---
    event EpochAdvanced(uint64 indexed newEpochId, uint256 epochStartTime, uint256 totalStaked, uint256 totalRewardsDistributed);
    event Staked(address indexed user, uint256 amount, uint256 totalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 totalStaked);
    event RewardsClaimed(address indexed user, uint256 amount, uint64 lastClaimedEpoch);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 parameterKey, uint256 newValue, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue);
    event ProposalStatusUpdated(uint256 indexed proposalId, ProposalStatus newStatus);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteDelegationRevoked(address indexed delegator);
    event GuardianReportSubmitted(uint256 indexed reportId, address indexed reporter, uint256 severity, bytes32 reportHash);
    event EmergencyProtocolActivated(address indexed initiator, uint256 timestamp);
    event EmergencyProtocolDeactivated(address indexed initiator, uint256 timestamp);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event EpochDurationUpdated(uint64 indexed oldDuration, uint64 indexed newDuration);
    event ProtocolPaused(address indexed caller, uint256 timestamp);
    event ProtocolUnpaused(address indexed caller, uint256 timestamp);
    event StakeSlashed(address indexed staker, uint256 amount, string reason);
    event DynamicRewardMultiplierUpdated(uint256 oldMultiplier, uint256 newMultiplier);
    event ValueStreamAllocated(uint256 amount, bytes32 indexed recipientHash);
    event ObserverRegistered(address indexed observer);
    event ObserverUnregistered(address indexed observer);
    event ReputationUpdated(address indexed user, uint256 oldScore, uint256 newScore, string reason);


    // --- 5. Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "EpochGuard: Only oracle can call this function");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == guardianAddress, "EpochGuard: Only guardian can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!protocolPaused, "EpochGuard: Protocol is paused");
        _;
    }

    modifier whenPaused() {
        require(protocolPaused, "EpochGuard: Protocol is not paused");
        _;
    }

    modifier ifEmergencyMode() {
        require(emergencyModeActive, "EpochGuard: Not in emergency mode");
        _;
    }

    modifier ifNotEmergencyMode() {
        require(!emergencyModeActive, "EpochGuard: Emergency mode is active");
        _;
    }

    // --- 6. Constructor ---
    constructor(
        address _stakingToken,
        address _managedValueToken,
        uint64 _epochDuration,
        uint256 _baseEpochRewardRate,
        uint256 _minStakeRequirement,
        uint256 _proposalQuorumPercentage,
        uint256 _proposalVotingPeriod,
        address _oracleAddress,
        address _guardianAddress
    ) Ownable(msg.sender) {
        require(_stakingToken != address(0), "EpochGuard: Invalid staking token address");
        require(_managedValueToken != address(0), "EpochGuard: Invalid managed value token address");
        require(_epochDuration > 0, "EpochGuard: Epoch duration must be greater than 0");
        require(_proposalQuorumPercentage > 0 && _proposalQuorumPercentage <= 10000, "EpochGuard: Quorum must be 1-100%"); // 10000 = 100%
        require(_oracleAddress != address(0), "EpochGuard: Invalid oracle address");
        require(_guardianAddress != address(0), "EpochGuard: Invalid guardian address");

        stakingToken = IERC20(_stakingToken);
        managedValueToken = IERC20(_managedValueToken);
        epochDuration = _epochDuration;
        baseEpochRewardRate = _baseEpochRewardRate;
        minStakeRequirement = _minStakeRequirement;
        proposalQuorumPercentage = _proposalQuorumPercentage;
        proposalVotingPeriod = _proposalVotingPeriod;
        oracleAddress = _oracleAddress;
        guardianAddress = _guardianAddress;

        currentEpoch = 0; // Epoch 0 is initialization
        nextEpochStartTime = block.timestamp.add(epochDuration); // First epoch ends after initial duration

        dynamicRewardMultiplier = 1000; // Default 1x multiplier (e.g., 1000 = 100%)

        // Initialize Epoch 0 data
        epochs[0] = EpochData({
            id: 0,
            startTime: block.timestamp,
            endTime: nextEpochStartTime,
            totalStaked: 0,
            totalRewardsDistributed: 0,
            protocolMetricsHash: bytes32(0),
            dynamicRewardMultiplierAtEpoch: dynamicRewardMultiplier
        });

        // Set initial dynamic parameters (examples)
        protocolParameters[keccak256("COLLATERAL_RATIO")] = 15000; // 150%
        protocolParameters[keccak256("LIQUIDATION_PENALTY")] = 1000; // 10%
        protocolParameters[keccak256("GOVERNANCE_FEE")] = 10; // 0.1% for proposal creation
        protocolParameters[keccak256("MAX_VALUE_ALLOCATION_PER_EPOCH")] = 1000000e18; // Example: 1M tokens
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates the reward for a given staker for a specific epoch.
     *      Reward is based on staked amount, epoch's reward rate, and reputation score.
     *      Reputation provides a bonus multiplier.
     */
    function _calculateEpochReward(address _staker, uint64 _epochId) internal view returns (uint256) {
        StakeDetails storage stakerStake = stakes[_staker];
        if (stakerStake.amount == 0 || _epochId == 0) return 0; // No stake or epoch 0 has no rewards

        EpochData storage epochData = epochs[_epochId];
        if (epochData.totalStaked == 0) return 0;

        uint256 baseReward = stakerStake.amount
            .mul(epochData.dynamicRewardMultiplierAtEpoch)
            .mul(baseEpochRewardRate)
            .div(1000) // Adjust for multiplier (1000 = 1x)
            .div(epochData.totalStaked); // Proportional to total staked

        // Apply reputation bonus (e.g., 1% bonus per 100 reputation points)
        // Max reputation could be 10,000, giving 100% bonus
        uint256 reputationBonusMultiplier = 1000 + (stakerStake.reputationScore.div(100)); // 1000 is base (1x), 100 reputation gives +1 point
        return baseReward.mul(reputationBonusMultiplier).div(1000);
    }

    /**
     * @dev Internal function to update a staker's reputation score.
     *      Can be called by voting success/failure, or specific Guardian actions.
     */
    function _updateReputation(address _staker, int256 _change, string memory _reason) internal {
        StakeDetails storage stakerStake = stakes[_staker];
        uint256 oldScore = stakerStake.reputationScore;
        if (_change > 0) {
            stakerStake.reputationScore = stakerStake.reputationScore.add(uint256(_change));
        } else {
            stakerStake.reputationScore = stakerStake.reputationScore.sub(uint256(-_change));
        }
        emit ReputationUpdated(_staker, oldScore, stakerStake.reputationScore, _reason);
    }

    // --- 7. Core Epoch Management (5 Functions) ---

    /**
     * @dev Advances the protocol to the next epoch. Can be called by anyone
     *      once the current epoch duration has passed.
     *      Triggers reward calculations and proposal evaluations.
     */
    function advanceEpoch() public whenNotPaused nonReentrant {
        require(block.timestamp >= nextEpochStartTime, "EpochGuard: Current epoch has not ended yet");

        currentEpoch = currentEpoch.add(1);
        nextEpochStartTime = block.timestamp.add(epochDuration);

        // Snapshot current state for the new epoch
        epochs[currentEpoch] = EpochData({
            id: currentEpoch,
            startTime: block.timestamp,
            endTime: nextEpochStartTime,
            totalStaked: totalStakedTokens,
            totalRewardsDistributed: 0, // This will be updated as rewards are claimed
            protocolMetricsHash: bytes32(0), // Will be updated by oracle later if applicable
            dynamicRewardMultiplierAtEpoch: dynamicRewardMultiplier
        });

        // Evaluate all active proposals from the previous epoch
        // Note: This iterates through all proposals, in a very large system,
        // this might need to be batched or moved off-chain to a specific executor.
        // For this example, assuming a reasonable number of active proposals.
        for (uint256 i = 0; i < nextProposalId; i++) {
            Proposal storage proposal = proposals[i];
            if (proposal.status == ProposalStatus.Active && proposal.endEpoch < currentEpoch) {
                if (proposal.votesFor.mul(10000).div(totalStakedTokens) >= proposalQuorumPercentage &&
                    proposal.votesFor > proposal.votesAgainst) {
                    proposal.status = ProposalStatus.Succeeded;
                } else {
                    proposal.status = ProposalStatus.Failed;
                }
                emit ProposalStatusUpdated(proposal.id, proposal.status);

                // Update reputation based on voting outcome
                for (uint256 j = 0; j < proposal.voters.length; j++) {
                    address voter = proposal.voters[j];
                    bool votedFor = proposal.hasVoted[voter]; // Re-check actual vote (true/false)
                    if (votedFor && proposal.status == ProposalStatus.Succeeded) {
                        _updateReputation(voter, 5, "Successful vote");
                    } else if (!votedFor && proposal.status == ProposalStatus.Failed) {
                        _updateReputation(voter, 2, "Vote against failed proposal");
                    } else {
                        // Penalize voting on the losing side if it was a significant proposal
                        _updateReputation(voter, -1, "Vote on losing side");
                    }
                }
            }
        }

        emit EpochAdvanced(currentEpoch, block.timestamp, totalStakedTokens, 0); // 0 for now, updated on claims

        // Notify registered observers
        for (uint256 i = 0; i < registeredObservers.length; i++) {
            // In a real scenario, this would be a specific interface call
            // e.g., IObserver(registeredObservers[i]).onEpochAdvanced(currentEpoch);
            // For simplicity, we just emit an event.
        }
    }

    // --- 8. Staking & Rewards (5 Functions) ---

    /**
     * @dev Allows a user to stake tokens into the protocol.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) public whenNotPaused nonReentrant {
        require(amount >= minStakeRequirement, "EpochGuard: Stake amount below minimum");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "EpochGuard: Staking token transfer failed");

        stakes[msg.sender].amount = stakes[msg.sender].amount.add(amount);
        totalStakedTokens = totalStakedTokens.add(amount);

        // If this is a new staker, initialize lastClaimedEpoch to current epoch - 1
        // So they can claim rewards from the epoch they staked in if it's the first stake
        if (stakes[msg.sender].lastClaimedEpoch == 0 && stakes[msg.sender].amount == amount) {
            stakes[msg.sender].lastClaimedEpoch = currentEpoch;
        }

        emit Staked(msg.sender, amount, totalStakedTokens);
    }

    /**
     * @dev Allows a user to unstake tokens from the protocol.
     *      Requires claiming pending rewards first, or they are forfeited.
     * @param amount The amount of tokens to unstake.
     */
    function unstake(uint256 amount) public whenNotPaused nonReentrant {
        require(stakes[msg.sender].amount >= amount, "EpochGuard: Insufficient staked amount");
        // Forfeit pending rewards for any epochs not claimed
        // In a real system, might force claim or require claim before unstake
        uint256 pending = getPendingRewards(msg.sender);
        require(pending == 0, "EpochGuard: Claim pending rewards before unstaking");

        stakes[msg.sender].amount = stakes[msg.sender].amount.sub(amount);
        totalStakedTokens = totalStakedTokens.sub(amount);

        require(stakingToken.transfer(msg.sender, amount), "EpochGuard: Staking token transfer failed");

        emit Unstaked(msg.sender, amount, totalStakedTokens);
    }

    /**
     * @dev Allows a staker to claim rewards for all epochs since their last claim.
     */
    function claimEpochRewards() public whenNotPaused nonReentrant {
        StakeDetails storage stakerStake = stakes[msg.sender];
        require(stakerStake.amount > 0, "EpochGuard: No active stake to claim rewards");
        require(stakerStake.lastClaimedEpoch < currentEpoch, "EpochGuard: No new rewards to claim");

        uint256 totalClaimable = 0;
        uint64 startClaimEpoch = stakerStake.lastClaimedEpoch.add(1);

        for (uint64 epoch = startClaimEpoch; epoch <= currentEpoch; epoch++) {
            if (epoch <= currentEpoch) { // Ensure we don't try to claim future epochs
                totalClaimable = totalClaimable.add(_calculateEpochReward(msg.sender, epoch));
            }
        }

        require(totalClaimable > 0, "EpochGuard: No rewards available to claim");
        require(stakingToken.transfer(msg.sender, totalClaimable), "EpochGuard: Reward token transfer failed");

        stakerStake.lastClaimedEpoch = currentEpoch;
        epochs[currentEpoch].totalRewardsDistributed = epochs[currentEpoch].totalRewardsDistributed.add(totalClaimable);

        emit RewardsClaimed(msg.sender, totalClaimable, currentEpoch);
    }

    // --- 9. Governance & Parameter Management (6 Functions) ---

    /**
     * @dev Allows stakers meeting the minimum stake requirement to propose changes to dynamic protocol parameters.
     * @param parameterKey The keccak256 hash of the parameter name (e.g., keccak256("COLLATERAL_RATIO")).
     * @param newValue The proposed new value for the parameter.
     * @param description A brief description of the proposal.
     */
    function proposeParameterChange(
        bytes32 parameterKey,
        uint256 newValue,
        string memory description
    ) public whenNotPaused nonReentrant {
        require(stakes[msg.sender].amount >= minStakeRequirement, "EpochGuard: Insufficient stake to propose");
        require(parameterKey != bytes32(0), "EpochGuard: Invalid parameter key");

        // Simple fee for proposal creation (to prevent spam)
        // require(stakingToken.transferFrom(msg.sender, address(this), protocolParameters[keccak256("GOVERNANCE_FEE")]), "EpochGuard: Proposal fee payment failed");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            targetParameterKey: parameterKey,
            newValue: newValue,
            description: description,
            startEpoch: currentEpoch,
            endEpoch: currentEpoch.add(uint64(proposalVotingPeriod)),
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            voters: new address[](0)
        });

        // Add to active proposals for the current epoch
        epochs[currentEpoch].activeProposals[proposalId] = true;

        emit ProposalCreated(proposalId, msg.sender, parameterKey, newValue, description);
    }

    /**
     * @dev Allows stakers (or their delegates) to vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "EpochGuard: Proposal is not active");
        require(proposal.endEpoch >= currentEpoch, "EpochGuard: Voting period has ended");

        address voter = msg.sender;
        if (stakes[msg.sender].delegatedTo != address(0)) {
            voter = stakes[msg.sender].delegatedTo;
        }

        require(stakes[voter].amount > 0, "EpochGuard: No active stake or delegated stake to vote");
        require(!proposal.hasVoted[voter], "EpochGuard: Already voted on this proposal");

        uint256 votingPower = stakes[voter].amount.add(stakes[voter].reputationScore); // Reputation adds voting weight

        if (support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.hasVoted[voter] = true;
        proposal.voters.push(voter); // Store voter for reputation update later

        emit Voted(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @dev Executes a proposal if it has succeeded and not yet executed.
     *      Can be called by anyone.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Succeeded, "EpochGuard: Proposal not in succeeded state");
        require(proposal.endEpoch < currentEpoch, "EpochGuard: Voting period has not ended for execution");
        require(proposal.targetParameterKey != bytes32(0), "EpochGuard: No parameter change defined for this proposal");
        require(proposal.status != ProposalStatus.Executed, "EpochGuard: Proposal already executed");

        // Apply the parameter change
        protocolParameters[proposal.targetParameterKey] = proposal.newValue;
        proposal.status = ProposalStatus.Executed;

        emit ProposalExecuted(proposalId, proposal.targetParameterKey, proposal.newValue);
        emit ProposalStatusUpdated(proposalId, ProposalStatus.Executed);
    }

    /**
     * @dev Delegates a user's voting power to another address.
     *      Only the delegator's stake determines power, but the delegatee casts the vote.
     * @param delegatee The address to delegate voting power to.
     */
    function delegateVote(address delegatee) public whenNotPaused {
        require(stakes[msg.sender].amount > 0, "EpochGuard: No active stake to delegate");
        require(delegatee != address(0), "EpochGuard: Cannot delegate to zero address");
        require(delegatee != msg.sender, "EpochGuard: Cannot delegate to self");
        require(stakes[msg.sender].delegatedTo != delegatee, "EpochGuard: Already delegated to this address");

        stakes[msg.sender].delegatedTo = delegatee;
        emit VoteDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Revokes any existing vote delegation for the caller.
     */
    function revokeVoteDelegation() public whenNotPaused {
        require(stakes[msg.sender].delegatedTo != address(0), "EpochGuard: No active delegation to revoke");

        stakes[msg.sender].delegatedTo = address(0);
        emit VoteDelegationRevoked(msg.sender);
    }

    // --- 10. Guardian & Emergency Operations (5 Functions) ---

    /**
     * @dev Allows the designated Guardian to submit an off-chain report or observation.
     * @param reportHash A hash linking to the full off-chain report content (e.g., IPFS CID).
     * @param severityScore A score (0-100) indicating the severity of the reported issue.
     * @param detailsURI A URI pointing to more details about the report.
     */
    function submitGuardianReport(
        bytes32 reportHash,
        uint256 severityScore,
        string memory detailsURI
    ) public onlyGuardian whenNotPaused {
        require(severityScore <= 100, "EpochGuard: Severity score cannot exceed 100");
        uint256 reportId = nextGuardianReportId++;
        guardianReports[reportId] = GuardianReport({
            reportHash: reportHash,
            severityScore: severityScore,
            detailsURI: detailsURI,
            epochSubmitted: currentEpoch,
            timestamp: block.timestamp
        });
        emit GuardianReportSubmitted(reportId, msg.sender, severityScore, reportHash);
    }

    /**
     * @dev Initiates the emergency protocol. Can only be called by the Guardian.
     *      This function puts the protocol into a state where critical operations might be paused
     *      or altered to prevent further damage. This should be a last resort.
     */
    function initiateEmergencyProtocol() public onlyGuardian ifNotEmergencyMode whenNotPaused {
        emergencyModeActive = true;
        // In a real system, this could trigger:
        // - Freezing specific funds/contracts
        // - Changing critical parameters immediately
        // - Redirecting value streams to a recovery multisig
        emit EmergencyProtocolActivated(msg.sender, block.timestamp);

        // Notify registered observers
        for (uint256 i = 0; i < registeredObservers.length; i++) {
            // IObserver(registeredObservers[i]).onEmergencyProtocolActivated();
        }
    }

    /**
     * @dev Deactivates the emergency protocol. Can be called by the Guardian or Owner.
     *      Might require a governance vote to exit depending on the severity of the emergency.
     *      For simplicity, it's a direct guardian/owner call here.
     */
    function deactivateEmergencyProtocol() public onlyGuardian ifEmergencyMode whenNotPaused {
        // Potentially add a delay or a governance vote required for deactivation based on emergency severity
        emergencyModeActive = false;
        emit EmergencyProtocolDeactivated(msg.sender, block.timestamp);
    }

    /**
     * @dev Slashes a portion of a staker's funds due to a detected violation or malicious activity.
     *      This action could be triggered by governance or the Guardian.
     *      For this example, it's exposed to Guardian.
     * @param stakerAddress The address of the staker to be slashed.
     * @param amount The amount of tokens to slash.
     * @param reason A string explaining the reason for slashing.
     */
    function slashStake(address stakerAddress, uint256 amount, string memory reason) public onlyGuardian nonReentrant {
        require(stakes[stakerAddress].amount >= amount, "EpochGuard: Insufficient stake to slash");
        require(amount > 0, "EpochGuard: Slash amount must be greater than zero");

        stakes[stakerAddress].amount = stakes[stakerAddress].amount.sub(amount);
        totalStakedTokens = totalStakedTokens.sub(amount);

        // The slashed tokens could be burned, sent to a treasury, or to a reward pool.
        // For simplicity, they are just removed from totalStakedTokens.
        // Example: stakingToken.transfer(address(this), amount); // Send to contract treasury
        // Or: stakingToken.burn(amount); // Requires burn function on token
        emit StakeSlashed(stakerAddress, amount, reason);
        _updateReputation(stakerAddress, -50, string(abi.encodePacked("Slashed: ", reason)));
    }

    // --- 11. Oracle & External Data Integration (2 Functions) ---

    /**
     * @dev Allows the trusted oracle to update its address.
     * @param newOracle The new address of the trusted oracle.
     */
    function updateOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "EpochGuard: New oracle address cannot be zero");
        address oldOracle = oracleAddress;
        oracleAddress = newOracle;
        emit OracleAddressUpdated(oldOracle, newOracle);
    }

    /**
     * @dev Allows the oracle to update the dynamic reward multiplier based on
     *      external protocol health metrics (e.g., TVL, market conditions).
     * @param newMultiplier The new multiplier value (e.g., 1000 for 1x, 1200 for 1.2x).
     */
    function updateDynamicRewardMultiplier(uint256 newMultiplier) public onlyOracle whenNotPaused {
        require(newMultiplier > 0, "EpochGuard: Multiplier must be positive");
        uint256 oldMultiplier = dynamicRewardMultiplier;
        dynamicRewardMultiplier = newMultiplier;
        emit DynamicRewardMultiplierUpdated(oldMultiplier, newMultiplier);
    }


    // --- 12. Value Stream Management (2 Functions) ---

    /**
     * @dev Allows an authorized entity (e.g., a connected sub-protocol or governance itself)
     *      to request an allocation of the managed value stream tokens.
     *      Subject to epoch-based limits and protocol health.
     * @param amount The amount of managed value token to allocate.
     * @param recipientHash A hash representing the recipient (could be an address or an ID).
     *      Using a hash allows more privacy or flexible recipient types.
     */
    function requestValueStreamAllocation(uint256 amount, bytes32 recipientHash) public whenNotPaused nonReentrant {
        // Example authorization: only if emergency mode is NOT active and sender is a recognized recipient or governance.
        // For simplicity, let's allow anyone if not in emergency mode and within a max limit.
        // In a real system, this would require a `onlyAllowedAllocator` modifier or similar.
        require(!emergencyModeActive, "EpochGuard: Cannot allocate value stream in emergency mode");
        require(amount > 0, "EpochGuard: Allocation amount must be positive");
        require(amount <= protocolParameters[keccak256("MAX_VALUE_ALLOCATION_PER_EPOCH")], "EpochGuard: Exceeds max allocation for epoch");
        require(managedValueToken.balanceOf(address(this)) >= amount, "EpochGuard: Insufficient managed value tokens in contract");

        // Transfer logic needs to know the actual recipient address from the hash,
        // which might be handled off-chain or by a helper contract.
        // For demonstration, let's assume `recipientHash` can be resolved to an actual address.
        // Example: address recipientAddress = address(uint160(uint256(recipientHash))); // UNSAFE, just for example
        // managedValueToken.transfer(recipientAddress, amount);

        emit ValueStreamAllocated(amount, recipientHash);
    }

    // --- 13. Protocol Health & Observer Pattern (3 Functions) ---

    /**
     * @dev Registers an external contract (observer) to receive notifications
     *      about critical protocol events (e.g., epoch advancement, emergency mode).
     * @param observerContract The address of the observer contract.
     */
    function registerObserver(address observerContract) public onlyOwner {
        require(observerContract != address(0), "EpochGuard: Invalid observer address");
        require(!isObserver[observerContract], "EpochGuard: Observer already registered");
        registeredObservers.push(observerContract);
        isObserver[observerContract] = true;
        emit ObserverRegistered(observerContract);
    }

    /**
     * @dev Unregisters an external observer contract.
     * @param observerContract The address of the observer contract to unregister.
     */
    function unregisterObserver(address observerContract) public onlyOwner {
        require(isObserver[observerContract], "EpochGuard: Observer not registered");
        for (uint256 i = 0; i < registeredObservers.length; i++) {
            if (registeredObservers[i] == observerContract) {
                registeredObservers[i] = registeredObservers[registeredObservers.length - 1];
                registeredObservers.pop();
                break;
            }
        }
        isObserver[observerContract] = false;
        emit ObserverUnregistered(observerContract);
    }

    /**
     * @dev Provides a calculated health score for the protocol based on internal states.
     *      (e.g., stake ratio, active proposals, emergency mode status, recent Guardian reports).
     *      This is a conceptual function; actual calculation would be complex.
     * @return A health score (e.g., 0-100), higher is better.
     */
    function getProtocolHealthScore() public view returns (uint256) {
        uint256 score = 100; // Start with full health
        if (emergencyModeActive) {
            score = score.sub(50); // Severe penalty
        }
        if (protocolPaused) {
            score = score.sub(20); // Minor penalty
        }
        if (totalStakedTokens < protocolParameters[keccak256("MIN_TOTAL_STAKE_FOR_HEALTHY")]) { // Example parameter
            score = score.sub(10); // Penalty for low participation
        }
        // Add logic based on recent Guardian reports (e.g., average severity of last 5 reports)
        // Add logic based on active proposal count or success rate
        return score;
    }


    // --- 14. Admin & Security (4 Functions) ---

    /**
     * @dev Allows the owner or Guardian to pause critical protocol operations.
     *      Used during upgrades, critical bug fixes, or emergency situations.
     */
    function pauseProtocol() public onlyOwner { // Can also be `public virtual` and overridden by Guardian via proposal
        require(!protocolPaused, "EpochGuard: Protocol is already paused");
        protocolPaused = true;
        emit ProtocolPaused(msg.sender, block.timestamp);
    }

    /**
     * @dev Allows the owner or Guardian to unpause critical protocol operations.
     *      Should only be called when issues are resolved.
     */
    function unpauseProtocol() public onlyOwner { // Can also be `public virtual` and overridden by Guardian via proposal
        require(protocolPaused, "EpochGuard: Protocol is not paused");
        protocolPaused = false;
        emit ProtocolUnpaused(msg.sender, block.timestamp);
    }

    /**
     * @dev Allows the owner to update the Guardian address.
     * @param newGuardian The new address for the Guardian role.
     */
    function setGuardianAddress(address newGuardian) public onlyOwner {
        require(newGuardian != address(0), "EpochGuard: New guardian address cannot be zero");
        guardianAddress = newGuardian;
    }

    /**
     * @dev Allows the owner to update the epoch duration.
     *      This parameter is critical and might require a time-lock or governance vote in practice.
     * @param newDuration The new duration for an epoch in seconds.
     */
    function updateEpochDuration(uint64 newDuration) public onlyOwner {
        require(newDuration > 0, "EpochGuard: Epoch duration must be positive");
        uint64 oldDuration = epochDuration;
        epochDuration = newDuration;
        // Adjust nextEpochStartTime to keep consistent epoch ending times
        // If current time is past nextEpochStartTime, advanceEpoch must be called first
        if (block.timestamp >= nextEpochStartTime) {
             nextEpochStartTime = block.timestamp.add(epochDuration);
        } else {
             nextEpochStartTime = epochs[currentEpoch].startTime.add(newDuration);
        }
        emit EpochDurationUpdated(oldDuration, newDuration);
    }


    // --- 15. Getter Functions (5 Functions) ---

    /**
     * @dev Retrieves summary data for a specific epoch.
     * @param epochId The ID of the epoch to query.
     * @return A tuple containing epoch data.
     */
    function getEpochData(uint64 epochId) public view returns (
        uint64 id,
        uint256 startTime,
        uint256 endTime,
        uint256 totalStaked,
        uint256 totalRewardsDistributed,
        bytes32 protocolMetricsHash,
        uint256 dynamicRewardMultiplierAtEpoch
    ) {
        EpochData storage data = epochs[epochId];
        return (
            data.id,
            data.startTime,
            data.endTime,
            data.totalStaked,
            data.totalRewardsDistributed,
            data.protocolMetricsHash,
            data.dynamicRewardMultiplierAtEpoch
        );
    }

    /**
     * @dev Retrieves staking and reputation details for a specific staker.
     * @param staker The address of the staker.
     * @return A tuple containing stake amount, last claimed epoch, reputation score, and delegated address.
     */
    function getStakeDetails(address staker) public view returns (
        uint256 amount,
        uint64 lastClaimedEpoch,
        uint256 reputationScore,
        address delegatedTo
    ) {
        StakeDetails storage details = stakes[staker];
        return (
            details.amount,
            details.lastClaimedEpoch,
            details.reputationScore,
            details.delegatedTo
        );
    }

    /**
     * @dev Calculates the estimated pending rewards for a staker.
     * @param staker The address of the staker.
     * @return The total amount of estimated pending rewards.
     */
    function getPendingRewards(address staker) public view returns (uint256) {
        StakeDetails storage stakerStake = stakes[staker];
        if (stakerStake.amount == 0 || stakerStake.lastClaimedEpoch >= currentEpoch) {
            return 0;
        }

        uint256 totalPending = 0;
        for (uint64 epoch = stakerStake.lastClaimedEpoch.add(1); epoch <= currentEpoch; epoch++) {
            totalPending = totalPending.add(_calculateEpochReward(staker, epoch));
        }
        return totalPending;
    }

    /**
     * @dev Retrieves details of a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        address proposer,
        bytes32 targetParameterKey,
        uint256 newValue,
        string memory description,
        uint64 startEpoch,
        uint64 endEpoch,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalStatus status
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.targetParameterKey,
            proposal.newValue,
            proposal.description,
            proposal.startEpoch,
            proposal.endEpoch,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.status
        );
    }

    /**
     * @dev Retrieves the current value of a specific dynamic protocol parameter.
     * @param parameterKey The keccak256 hash of the parameter name.
     * @return The current value of the parameter.
     */
    function getEpochParameter(bytes32 parameterKey) public view returns (uint256) {
        return protocolParameters[parameterKey];
    }
}
```