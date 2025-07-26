Okay, this is an exciting challenge! Creating something truly unique and advanced while avoiding existing open-source patterns requires blending multiple concepts in a novel way.

Let's design a "Synergistic Policy Engine (SPE)" smart contract. This contract will function as a self-adaptive decentralized autonomous entity that dynamically adjusts its parameters, rewards, and governance mechanisms based on internal "System Health Metrics" and participant "Reputation Scores." It will also feature "Ephemeral Policy Committees" for targeted, adaptive governance.

---

## **The Synergistic Policy Engine (SPE)**

### **Outline & Function Summary**

The Synergistic Policy Engine (SPE) is a next-generation decentralized protocol designed for adaptive governance and resource allocation. It moves beyond static rules by incorporating real-time system health data, a nuanced reputation system, and dynamic policy adjustments. Its core innovation lies in the "Ephemeral Policy Committees" (EPCs), which are short-lived, task-specific governance groups formed to address specific challenges or opportunities, fostering agile and focused decision-making.

**Core Concepts:**

1.  **System Health Metrics (SHM):** On-chain and potentially off-chain (via Oracle) data points indicating the protocol's "health" (e.g., unique participant count, transaction volume, stability of internal values).
2.  **Reputation System (RS):** A multi-faceted system where users earn/lose reputation based on contributions, staking, participation in EPCs, and adherence to protocol values. Reputation dictates access tiers, voting weight, and reward multipliers.
3.  **Dynamic Policy Adjustment (DPA):** Key protocol parameters (e.g., operation fees, reward rates, access thresholds) are not fixed but automatically adjusted based on the current System Health Score and aggregate Reputation Scores.
4.  **Ephemeral Policy Committees (EPCs):** Temporary, highly-focused groups that can be proposed, voted on, and formed to address specific challenges or implement particular features. Members are chosen based on reputation and expertise, and their successful completion of tasks earns them significant reputation and rewards.
5.  **Adaptive Resource Allocation:** Rewards from the protocol's treasury are dynamically distributed based on an individual's reputation, contribution to EPCs, and overall engagement.

---

### **Function Summary (Total: 23 Functions)**

**I. Core Infrastructure & Access Control:**
1.  `constructor()`: Initializes the contract with `owner` and initial parameters.
2.  `updateOracleAddress(address _newOracle)`: Allows owner/governance to update the address of the external oracle for SHM.
3.  `pauseContract()`: Emergency pause mechanism (governance controlled).
4.  `unpauseContract()`: Emergency unpause mechanism (governance controlled).
5.  `withdrawExcessFunds(uint256 amount)`: Allows governance to withdraw surplus funds from the contract treasury (e.g., for upgrades or external initiatives).

**II. Reputation System (RS):**
6.  `stakeForReputation(uint256 amount)`: Users stake tokens to gain initial reputation and participate.
7.  `unstakeReputation(uint256 amount)`: Users can unstake tokens, potentially reducing reputation over time or after a cooldown.
8.  `delegateReputation(address delegatee, uint256 amount)`: Allows users to delegate a portion of their reputation to another address, enhancing collective decision-making.
9.  `awardReputation(address user, uint256 amount)`: Grants reputation to a user, typically automated after successful EPC completion or manual by high-tier governance.
10. `penalizeReputation(address user, uint256 amount)`: Deducts reputation, e.g., for malicious behavior or non-compliance (governance controlled).
11. `getReputationScore(address user)`: Retrieves the current reputation score of a user.

**III. System Health Metrics (SHM) & Dynamic Policy Adjustment (DPA):**
12. `submitExternalHealthMetric(string calldata metricName, int256 value)`: Allows the designated Oracle to submit specific external health metrics (e.g., market volatility, gas prices).
13. `updateInternalHealthMetrics()`: A public function that anyone can call to trigger an update of internal metrics (e.g., unique participant count, transaction volume, TVL) based on contract state, impacting the overall System Health Score.
14. `getSystemHealthScore()`: Calculates and returns the current aggregate System Health Score based on all metrics.
15. `getDynamicOperationFee()`: Returns the current operation fee, dynamically adjusted based on the System Health Score.
16. `getAdjustedRewardMultiplier()`: Returns a multiplier for rewards, dynamically adjusted based on the System Health Score.

**IV. Ephemeral Policy Committees (EPCs):**
17. `proposeEphemeralPolicyCommittee(string calldata _purpose, uint256 _requiredReputation, uint256 _committeeSize, uint256 _rewardPool)`: Allows eligible users to propose a new EPC for a specific task.
18. `voteForEphemeralPolicyCommittee(uint256 proposalId)`: Allows eligible users to vote on proposed EPCs.
19. `joinActiveEphemeralPolicyCommittee(uint256 proposalId)`: Allows eligible (by reputation) users to join an approved and active EPC, filling its size requirement.
20. `submitEPCDraftPolicy(uint256 proposalId, string calldata _policyHash, bytes calldata _additionalData)`: EPC members submit their proposed policy (e.g., hash of off-chain document, parameters to update).
21. `evaluateSubmittedPolicy(uint256 proposalId, bool _approved)`: High-reputation users or automated checks evaluate and vote on the submitted policy, triggering its enactment or rejection.
22. `enactEphemeralPolicy(uint256 proposalId)`: Executes the approved policy from a successfully completed EPC, e.g., updates contract parameters, distributes rewards.

**V. General & Utility:**
23. `depositFunds()`: Allows users to deposit funds into the contract's treasury, which can be used for rewards or policy execution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title The Synergistic Policy Engine (SPE)
/// @author Your Name/DAO
/// @notice This contract implements a self-adaptive decentralized protocol
///         featuring dynamic policy adjustments based on System Health Metrics (SHM),
///         a nuanced Reputation System (RS), and agile governance via
///         Ephemeral Policy Committees (EPCs).
/// @dev This is a conceptual contract. A production-ready version would require
///      extensive security audits, gas optimizations, and more robust oracle integration.

/// @dev Error types for cleaner error handling
error SPE_NotOwner();
error SPE_Paused();
error SPE_Unauthorized();
error SPE_InsufficientFunds();
error SPE_InvalidAmount();
error SPE_NotEnoughReputation();
error SPE_InvalidProposalId();
error SPE_ProposalAlreadyExists();
error SPE_ProposalNotActive();
error SPE_AlreadyVoted();
error SPE_NotEPCMember();
error SPE_EPCFull();
error SPE_EPCDraftNotSubmitted();
error SPE_PolicyAlreadyEnacted();
error SPE_CannotUnstakeDueToLock(); // Example, could be part of a cooldown
error SPE_CannotPenalizeSelf();

contract SynergisticPolicyEngine {

    // --- State Variables ---

    address public owner; // Contract deployer or initial governance multisig
    address public oracleAddress; // Address of the trusted oracle for external data

    bool public paused; // Emergency pause switch

    // --- Reputation System (RS) ---
    mapping(address => uint256) public reputationScores;
    mapping(address => uint256) public stakedTokens;
    mapping(address => address) public delegatedReputation; // Who a user delegates their reputation to

    uint256 public constant MIN_STAKE_FOR_REPUTATION = 1 ether; // Example minimum stake
    uint256 public constant REPUTATION_PER_STAKE_UNIT = 100; // Reputation points per 1 ether staked

    // --- System Health Metrics (SHM) ---
    struct SystemMetric {
        string name;
        int256 value;
        uint256 lastUpdated;
    }
    mapping(string => SystemMetric) public systemMetrics; // Stores named metrics
    uint256 public uniqueParticipants; // Example internal metric
    uint256 public totalTransactions;  // Example internal metric
    uint256 public totalValueLocked;   // Example internal metric (simple sum of stakedTokens)

    uint256 public systemHealthThresholdGood; // Threshold for 'good' health (e.g., 80)
    uint256 public systemHealthThresholdWarning; // Threshold for 'warning' health (e.g., 50)

    // --- Dynamic Policy Adjustment (DPA) ---
    uint256 public baseOperationFee = 0.01 ether; // 0.01 ETH as base fee
    uint256 public baseRewardMultiplier = 1e18; // 1.0 (as 1e18 for fixed point)

    // --- Ephemeral Policy Committees (EPCs) ---
    enum EPCStatus { Pending, Approved, Active, DraftSubmitted, Evaluated, Enacted, Rejected, Cancelled }

    struct EPCProposal {
        uint256 id;
        string purpose;
        uint256 proposerReputation;
        uint256 requiredReputation; // Min reputation to join committee
        uint256 committeeSize;      // Max number of members
        uint256 rewardPool;         // Funds allocated if successful
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTime;
        uint256 votingEndTime;
        EPCStatus status;
        address proposer;
        mapping(address => bool) hasVoted; // For voting on proposal
        address[] committeeMembers; // Members who joined the active committee
        mapping(address => bool) isCommitteeMember; // Quick lookup for member check
        string policyHash;         // Hash of the proposed policy document
        bytes additionalData;      // Additional parameters or calldata for policy execution
        bool policyApproved;       // Result of policy evaluation
    }

    uint256 public nextEPCProposalId = 1;
    mapping(uint256 => EPCProposal) public epcProposals;

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracle);
    event Paused(address indexed caller);
    event Unpaused(address indexed caller);
    event FundsWithdrawn(address indexed to, uint256 amount);

    event ReputationStaked(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationUnstaked(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationAwarded(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationPenalized(address indexed user, uint256 amount, uint256 newReputation);

    event ExternalHealthMetricSubmitted(string indexed metricName, int256 value, uint256 timestamp);
    event InternalMetricsUpdated(uint256 uniqueParticipants, uint256 totalTransactions, uint256 totalValueLocked);
    event SystemHealthScoreCalculated(uint256 score);
    event DynamicFeeAdjusted(uint256 newFee);
    event RewardMultiplierAdjusted(uint256 newMultiplier);

    event EPCProposed(uint256 indexed proposalId, string purpose, address indexed proposer);
    event EPCVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event EPCApproved(uint256 indexed proposalId);
    event EPCMemberJoined(uint256 indexed proposalId, address indexed member);
    event EPCDraftPolicySubmitted(uint256 indexed proposalId, string policyHash, bytes additionalData);
    event EPCPolicyEvaluated(uint256 indexed proposalId, bool approved);
    event EPCPolicyEnacted(uint256 indexed proposalId);
    event EPCCancelled(uint256 indexed proposalId, string reason);

    event FundsDeposited(address indexed depositor, uint256 amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert SPE_NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert SPE_Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert SPE_Paused();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert SPE_Unauthorized();
        _;
    }

    // High reputation modifier, example threshold
    modifier onlyHighReputation(uint256 _minReputation) {
        if (reputationScores[msg.sender] < _minReputation) revert SPE_NotEnoughReputation();
        _;
    }

    // --- Constructor ---
    constructor(address _oracleAddress) {
        owner = msg.sender;
        oracleAddress = _oracleAddress;
        paused = false;

        systemHealthThresholdGood = 80;
        systemHealthThresholdWarning = 50;
    }

    // --- I. Core Infrastructure & Access Control ---

    /// @notice Updates the address of the external oracle. Only callable by the owner.
    /// @param _newOracle The new address for the oracle.
    function updateOracleAddress(address _newOracle) external onlyOwner {
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /// @notice Pauses the contract in case of emergency. Only callable by the owner.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract after an emergency. Only callable by the owner.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Allows the owner to withdraw excess funds from the contract treasury.
    ///         This could be for upgrades, external initiatives, or recovery.
    /// @param amount The amount of Ether to withdraw.
    function withdrawExcessFunds(uint256 amount) external onlyOwner {
        if (amount == 0) revert SPE_InvalidAmount();
        if (address(this).balance < amount) revert SPE_InsufficientFunds();
        payable(owner).transfer(amount);
        emit FundsWithdrawn(owner, amount);
    }

    // --- II. Reputation System (RS) ---

    /// @notice Allows a user to stake ETH to gain reputation.
    /// @param amount The amount of ETH to stake.
    function stakeForReputation(uint256 amount) external payable whenNotPaused {
        if (msg.value != amount || amount < MIN_STAKE_FOR_REPUTATION) revert SPE_InvalidAmount();

        stakedTokens[msg.sender] += amount;
        uint256 reputationGained = (amount * REPUTATION_PER_STAKE_UNIT) / 1 ether; // Assuming ETH is 1e18
        reputationScores[msg.sender] += reputationGained;
        totalValueLocked += amount; // Update internal metric

        emit ReputationStaked(msg.sender, amount, reputationScores[msg.sender]);
        updateInternalHealthMetrics(); // Trigger update for SHM
    }

    /// @notice Allows a user to unstake ETH, reducing their reputation.
    /// @param amount The amount of ETH to unstake.
    function unstakeReputation(uint256 amount) external whenNotPaused {
        if (amount == 0 || stakedTokens[msg.sender] < amount) revert SPE_InvalidAmount();

        stakedTokens[msg.sender] -= amount;
        uint256 reputationLost = (amount * REPUTATION_PER_STAKE_UNIT) / 1 ether;
        // Ensure reputation doesn't go negative
        reputationScores[msg.sender] = reputationScores[msg.sender] > reputationLost ? reputationScores[msg.sender] - reputationLost : 0;
        totalValueLocked -= amount; // Update internal metric

        payable(msg.sender).transfer(amount);
        emit ReputationUnstaked(msg.sender, amount, reputationScores[msg.sender]);
        updateInternalHealthMetrics(); // Trigger update for SHM
    }

    /// @notice Allows a user to delegate a portion of their reputation to another address.
    ///         This can be used for proxy voting or empowering experts.
    /// @param delegatee The address to delegate reputation to.
    /// @param amount The amount of reputation to delegate (not token amount, but reputation points).
    function delegateReputation(address delegatee, uint256 amount) external whenNotPaused {
        if (reputationScores[msg.sender] < amount) revert SPE_NotEnoughReputation();
        if (msg.sender == delegatee) revert SPE_InvalidAmount();

        // This is a simplistic delegation model, a more advanced one would track delegations
        // and allow for revocation. For simplicity, we just set the delegatee.
        // A more advanced system would transfer actual reputation or voting power.
        // For this example, it sets a preference, actual voting logic would read this.
        delegatedReputation[msg.sender] = delegatee;

        // In a real system, you might reduce sender's direct influence while increasing delegatee's effective influence.
        // Here, it's just a mapping for potential off-chain or advanced on-chain use.
        emit ReputationDelegated(msg.sender, delegatee, amount);
    }

    /// @notice Awards reputation to a specific user. Can be called by high-reputation members or automatically.
    /// @param user The address to award reputation to.
    /// @param amount The amount of reputation points to award.
    function awardReputation(address user, uint256 amount) external onlyHighReputation(getSystemHealthScore()) whenNotPaused {
        // The `onlyHighReputation` threshold here implies a dynamic threshold based on system health.
        // For example, if system health is good, lower reputation users can award. If bad, only super-high.
        if (user == address(0)) revert SPE_InvalidAmount();
        reputationScores[user] += amount;
        emit ReputationAwarded(user, amount, reputationScores[user]);
    }

    /// @notice Penalizes (deducts) reputation from a specific user. Can be called by high-reputation members or automatically.
    /// @param user The address to penalize.
    /// @param amount The amount of reputation points to deduct.
    function penalizeReputation(address user, uint256 amount) external onlyHighReputation(getSystemHealthScore() * 2) whenNotPaused {
        if (user == address(0) || user == msg.sender) revert SPE_CannotPenalizeSelf(); // Prevent self-penalization in governance context
        reputationScores[user] = reputationScores[user] > amount ? reputationScores[user] - amount : 0;
        emit ReputationPenalized(user, amount, reputationScores[user]);
    }

    /// @notice Retrieves the current reputation score of a user.
    /// @param user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address user) public view returns (uint256) {
        return reputationScores[user];
    }

    // --- III. System Health Metrics (SHM) & Dynamic Policy Adjustment (DPA) ---

    /// @notice Allows the designated Oracle to submit specific external health metrics.
    /// @param metricName The name of the metric (e.g., "gasPriceAvg", "marketVolatilityIndex").
    /// @param value The integer value of the metric.
    function submitExternalHealthMetric(string calldata metricName, int256 value) external onlyOracle whenNotPaused {
        systemMetrics[metricName] = SystemMetric(metricName, value, block.timestamp);
        emit ExternalHealthMetricSubmitted(metricName, value, block.timestamp);
        // Automatically trigger internal metric update as external data might influence it
        updateInternalHealthMetrics();
    }

    /// @notice Public function to update internal metrics based on contract state.
    ///         Can be called by anyone, incentivizing frequent updates.
    /// @dev This function could be further refined to prevent spam calls or have a cooldown.
    function updateInternalHealthMetrics() public {
        uniqueParticipants = 0; // Reset and recount or use a more complex tracking (e.g., set of addresses)
        // For simplicity, unique participants is approximated by counting non-zero stakers.
        // In a real system, this would be more complex (e.g., tracking first interaction).
        // totalTransactions could be incremented on relevant operations.
        // totalValueLocked is already updated on stake/unstake.

        // This is a placeholder. A real implementation would iterate through
        // a set of unique participants or maintain a bloom filter/Merkle tree.
        // For a public function, it shouldn't iterate large mappings directly for gas.
        // Let's just assume `uniqueParticipants` and `totalTransactions` are updated
        // by other relevant functions (e.g., `stakeForReputation` increments `uniqueParticipants`
        // if user is new, every transaction increments `totalTransactions`).
        // For this example, `totalValueLocked` is accurately maintained.

        emit InternalMetricsUpdated(uniqueParticipants, totalTransactions, totalValueLocked);
        getSystemHealthScore(); // Recalculate and emit score
    }

    /// @notice Calculates and returns the current aggregate System Health Score.
    ///         This score influences dynamic parameters.
    /// @dev This is a simplified calculation. A real system would use a weighted average
    ///      of various on-chain and off-chain metrics.
    /// @return The calculated System Health Score (e.g., 0-100).
    function getSystemHealthScore() public returns (uint256) {
        uint256 healthScore = 0;
        uint256 metricCount = 0;

        // Example calculation:
        // Influence from unique participants (proxy for network adoption)
        if (uniqueParticipants > 100) healthScore += 20; // Example threshold
        else if (uniqueParticipants > 10) healthScore += 10;

        // Influence from TVL (proxy for economic security/trust)
        if (totalValueLocked > 1000 ether) healthScore += 30; // Example threshold
        else if (totalValueLocked > 100 ether) healthScore += 15;

        // Influence from external metrics (if available)
        SystemMetric storage gasPriceAvg = systemMetrics["gasPriceAvg"];
        if (gasPriceAvg.value > 0) { // Assuming lower gas price is better
            // Example: gasPriceAvg is in Gwei (e.g., 20 Gwei = 20e9 wei)
            if (gasPriceAvg.value < 30e9) healthScore += 20; // Very good
            else if (gasPriceAvg.value < 60e9) healthScore += 10; // Good
            // If high, penalize
            else if (gasPriceAvg.value > 100e9) healthScore = healthScore > 5 ? healthScore - 5 : 0;
            metricCount++;
        }

        // Add influence from aggregated reputation (proxy for governance health)
        // This would require iterating through `reputationScores` which is gas-intensive.
        // For a real implementation, aggregate reputation would be updated incrementally.
        // For now, let's assume a rough estimate or a specific high-reputation pool.
        // Let's use `totalValueLocked` as a proxy for engagement.
        if (totalValueLocked > 500 ether) healthScore += 10;


        // Cap score at 100 for simplicity
        if (healthScore > 100) healthScore = 100;

        emit SystemHealthScoreCalculated(healthScore);
        return healthScore;
    }


    /// @notice Returns the current operation fee, dynamically adjusted based on the System Health Score.
    ///         Lower health score => higher fees (to incentivize stabilization or slow down activity).
    /// @return The calculated dynamic operation fee in wei.
    function getDynamicOperationFee() public view returns (uint256) {
        uint256 currentHealth = getSystemHealthScore(); // This calls a view function, so re-calculates
        uint256 fee = baseOperationFee; // Start with base fee

        if (currentHealth < systemHealthThresholdWarning) { // Bad health
            fee = fee * 2; // Double fee
        } else if (currentHealth < systemHealthThresholdGood) { // Warning health
            fee = (fee * 15) / 10; // 50% increase
        }
        // If good health, fee remains baseOperationFee

        emit DynamicFeeAdjusted(fee);
        return fee;
    }

    /// @notice Returns a multiplier for rewards, dynamically adjusted based on the System Health Score.
    ///         Higher health score => higher rewards (to incentivize participation when things are good).
    /// @return The calculated dynamic reward multiplier (scaled by 1e18).
    function getAdjustedRewardMultiplier() public view returns (uint256) {
        uint256 currentHealth = getSystemHealthScore(); // This calls a view function, so re-calculates
        uint256 multiplier = baseRewardMultiplier; // Start with 1.0

        if (currentHealth > systemHealthThresholdGood) { // Good health
            multiplier = (multiplier * 12) / 10; // 20% increase
        } else if (currentHealth > systemHealthThresholdWarning) { // Warning health
            // No change, or slight increase
        } else { // Bad health
            multiplier = (multiplier * 8) / 10; // 20% decrease
        }

        emit RewardMultiplierAdjusted(multiplier);
        return multiplier;
    }

    // --- IV. Ephemeral Policy Committees (EPCs) ---

    /// @notice Allows eligible users to propose a new Ephemeral Policy Committee for a specific task.
    /// @param _purpose A description of the EPC's goal (e.g., "Review and optimize gas fees").
    /// @param _requiredReputation Minimum reputation required for members to join this specific EPC.
    /// @param _committeeSize The desired number of members for this EPC.
    /// @param _rewardPool The amount of ETH to be allocated to the EPC members upon successful completion.
    function proposeEphemeralPolicyCommittee(
        string calldata _purpose,
        uint256 _requiredReputation,
        uint256 _committeeSize,
        uint256 _rewardPool
    ) external payable whenNotPaused onlyHighReputation(500) { // Example: must have 500 reputation to propose
        if (msg.value < _rewardPool) revert SPE_InsufficientFunds();
        if (_committeeSize == 0 || _requiredReputation == 0) revert SPE_InvalidAmount();

        uint256 proposalId = nextEPCProposalId++;
        epcProposals[proposalId].id = proposalId;
        epcProposals[proposalId].purpose = _purpose;
        epcProposals[proposalId].proposerReputation = reputationScores[msg.sender];
        epcProposals[proposalId].requiredReputation = _requiredReputation;
        epcProposals[proposalId].committeeSize = _committeeSize;
        epcProposals[proposalId].rewardPool = _rewardPool;
        epcProposals[proposalId].creationTime = block.timestamp;
        epcProposals[proposalId].votingEndTime = block.timestamp + 3 days; // Example: 3 days for voting
        epcProposals[proposalId].status = EPCStatus.Pending;
        epcProposals[proposalId].proposer = msg.sender;

        emit EPCProposed(proposalId, _purpose, msg.sender);
    }

    /// @notice Allows eligible users to vote on proposed EPCs. Reputation-weighted voting.
    /// @param proposalId The ID of the EPC proposal to vote on.
    function voteForEphemeralPolicyCommittee(uint256 proposalId, bool _support) external whenNotPaused {
        EPCProposal storage proposal = epcProposals[proposalId];
        if (proposal.id == 0) revert SPE_InvalidProposalId();
        if (proposal.status != EPCStatus.Pending) revert SPE_ProposalNotActive();
        if (block.timestamp > proposal.votingEndTime) revert SPE_ProposalNotActive(); // Voting period ended
        if (proposal.hasVoted[msg.sender]) revert SPE_AlreadyVoted();
        if (reputationScores[msg.sender] == 0) revert SPE_NotEnoughReputation();

        proposal.hasVoted[msg.sender] = true;
        uint256 effectiveReputation = reputationScores[msg.sender];
        if (delegatedReputation[msg.sender] != address(0)) {
            // If reputation is delegated, the delegatee gets the vote weight.
            // For simplicity, here we'll assume the delegator can still vote if they choose,
            // but in a real system, the power might shift.
            // Or, if delegated, the delegatee's vote counts more.
            // For this example, if delegated, the delegator's vote counts their base reputation.
            // More advanced: The delegated amount is added to the delegatee's voting power.
        }

        if (_support) {
            proposal.votesFor += effectiveReputation;
        } else {
            proposal.votesAgainst += effectiveReputation;
        }

        emit EPCVoted(proposalId, msg.sender, _support);

        // Auto-approve if threshold met
        if (proposal.votesFor >= proposal.votesAgainst * 2 && proposal.votesFor > 1000) { // Example: 2:1 ratio and min total votes
            proposal.status = EPCStatus.Approved;
            emit EPCApproved(proposalId);
        }
        // Could also have an auto-reject if votesAgainst is too high.
    }

    /// @notice Allows eligible users (by reputation) to join an approved and active EPC.
    /// @param proposalId The ID of the EPC to join.
    function joinActiveEphemeralPolicyCommittee(uint256 proposalId) external whenNotPaused {
        EPCProposal storage proposal = epcProposals[proposalId];
        if (proposal.id == 0) revert SPE_InvalidProposalId();
        if (proposal.status != EPCStatus.Approved && proposal.status != EPCStatus.Active) revert SPE_ProposalNotActive();
        if (reputationScores[msg.sender] < proposal.requiredReputation) revert SPE_NotEnoughReputation();
        if (proposal.committeeMembers.length >= proposal.committeeSize) revert SPE_EPCFull();
        if (proposal.isCommitteeMember[msg.sender]) revert SPE_EPCFull(); // Already a member

        proposal.committeeMembers.push(msg.sender);
        proposal.isCommitteeMember[msg.sender] = true;
        proposal.status = EPCStatus.Active; // Set to active once first member joins or based on other criteria

        emit EPCMemberJoined(proposalId, msg.sender);
    }

    /// @notice EPC members submit their proposed policy (e.g., hash of off-chain document, parameters to update).
    /// @param proposalId The ID of the EPC.
    /// @param _policyHash The IPFS hash or similar identifier for the off-chain policy document.
    /// @param _additionalData Optional, bytes to encode parameters for on-chain execution.
    function submitEPCDraftPolicy(
        uint256 proposalId,
        string calldata _policyHash,
        bytes calldata _additionalData
    ) external whenNotPaused {
        EPCProposal storage proposal = epcProposals[proposalId];
        if (proposal.id == 0) revert SPE_InvalidProposalId();
        if (!proposal.isCommitteeMember[msg.sender]) revert SPE_NotEPCMember();
        if (proposal.status != EPCStatus.Active) revert SPE_ProposalNotActive();
        if (bytes(proposal.policyHash).length != 0) revert SPE_EPCDraftNotSubmitted(); // Only one submission per EPC

        proposal.policyHash = _policyHash;
        proposal.additionalData = _additionalData;
        proposal.status = EPCStatus.DraftSubmitted;

        emit EPCDraftPolicySubmitted(proposalId, _policyHash, _additionalData);
    }

    /// @notice High-reputation users or automated checks evaluate and vote on the submitted policy.
    /// @param proposalId The ID of the EPC proposal.
    /// @param _approved True if the policy is approved, false otherwise.
    function evaluateSubmittedPolicy(uint256 proposalId, bool _approved) external whenNotPaused onlyHighReputation(getSystemHealthScore() * 10) {
        // Requires very high reputation to evaluate (e.g., 10x current system health score)
        EPCProposal storage proposal = epcProposals[proposalId];
        if (proposal.id == 0) revert SPE_InvalidProposalId();
        if (proposal.status != EPCStatus.DraftSubmitted) revert SPE_ProposalNotActive();

        proposal.policyApproved = _approved;
        proposal.status = EPCStatus.Evaluated;

        emit EPCPolicyEvaluated(proposalId, _approved);

        if (_approved) {
            enactEphemeralPolicy(proposalId);
        } else {
            // Handle rejection: e.g., allow re-submission, or mark as cancelled.
            proposal.status = EPCStatus.Rejected;
            emit EPCCancelled(proposalId, "Policy rejected by evaluators");
        }
    }

    /// @notice Executes the approved policy from a successfully completed EPC, distributes rewards.
    ///         Only callable after a policy has been evaluated and approved.
    /// @param proposalId The ID of the EPC.
    function enactEphemeralPolicy(uint256 proposalId) public whenNotPaused { // Public to be called internally after evaluation
        EPCProposal storage proposal = epcProposals[proposalId];
        if (proposal.id == 0) revert SPE_InvalidProposalId();
        if (proposal.status != EPCStatus.Evaluated || !proposal.policyApproved) revert SPE_PolicyAlreadyEnacted(); // Or not approved
        if (proposal.committeeMembers.length == 0) revert SPE_EPCFull(); // No members to reward

        // Example: Execute policy based on _additionalData
        // This is highly specific to the policy type. For this example, we just log it.
        // A real implementation would parse `additionalData` and call other contract functions.
        // Example: `(bool success,) = address(this).call(proposal.additionalData);`
        // if (!success) revert PolicyExecutionFailed();

        // Distribute rewards to committee members
        uint256 rewardPerMember = (proposal.rewardPool * getAdjustedRewardMultiplier()) / (1e18 * proposal.committeeMembers.length);
        for (uint256 i = 0; i < proposal.committeeMembers.length; i++) {
            address member = proposal.committeeMembers[i];
            if (address(this).balance < rewardPerMember) revert SPE_InsufficientFunds();
            payable(member).transfer(rewardPerMember);
            // Award reputation for successful participation
            awardReputation(member, 100); // Example: 100 reputation points for successful EPC participation
        }

        proposal.status = EPCStatus.Enacted;
        emit EPCPolicyEnacted(proposalId);
    }


    // --- V. General & Utility ---

    /// @notice Allows users to deposit funds into the contract's treasury.
    ///         These funds can be used for rewards, development, or specific policy executions.
    function depositFunds() external payable whenNotPaused {
        if (msg.value == 0) revert SPE_InvalidAmount();
        emit FundsDeposited(msg.sender, msg.value);
        totalTransactions++; // Increment internal metric
    }
}
```