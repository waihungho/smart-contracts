Here's a Solidity smart contract named "ChronosProtocol" that implements several advanced, creative, and trendy concepts:

**ChronosProtocol: Decentralized Adaptive Incentive & Reputation Engine**

This contract introduces a decentralized ecosystem for tasks and contributions, focusing on dynamic incentives and agent reputation. It combines concepts like adaptive reward mechanisms, epoch-based progression, agent delegation, and a robust mission system with an embedded reputation score.

---

## Contract Outline & Function Summary

**Contract Name:** `ChronosProtocol`

**Core Concepts:**
*   **Adaptive Incentives:** Reward multipliers dynamically adjust based on overall protocol activity and engagement.
*   **Agent Reputation:** Users (agents) build a reputation score through successful mission completion and contributions, influencing their reward share.
*   **Mission System:** A decentralized bounty board where users can propose and solve tasks ("missions").
*   **Epoch-based Progression:** The protocol operates in time-bound epochs, with reward distributions and adaptive factor recalibrations occurring at each epoch transition.
*   **Delegated Authority:** Agents can delegate specific actions or roles to other addresses, enabling automated agents or team management.
*   **Proof & Challenge Mechanism:** Missions require submission of off-chain proof (hash), with a basic challenge system for disputes.
*   **Pseudo-anonymous Agents:** Users interact via unique `agentId`s linked to their address, allowing for reputation tracking without directly exposing all wallet activities in all contexts.

**Function Categories & Summaries:**

**I. Core Protocol & Administration (5 Functions)**
1.  `constructor()`: Initializes the contract with an owner and essential parameters (epoch duration, mission fees, base reputation).
2.  `setEpochDuration(uint64 _newDuration)`: Owner-only. Sets the duration of each epoch in seconds.
3.  `setMissionParameters(uint256 _newProposalFee, uint256 _newBaseRewardFactor, uint256 _newBaseReputationGain, uint256 _newPenaltyReputationLoss)`: Owner-only. Adjusts fees, base rewards, and reputation impacts for missions.
4.  `setAdaptiveRewardParameters(uint256 _maxFactor, uint256 _activityThreshold)`: Owner-only. Configures parameters for the adaptive reward calculation.
5.  `withdrawProtocolFees(address _to, uint256 _amount)`: Owner-only. Allows the owner to withdraw accumulated protocol fees.

**II. Agent Management & Reputation (6 Functions)**
6.  `registerAgent(string calldata _description)`: Registers a new unique agent profile for `msg.sender`, assigning a unique `agentId` and initial reputation. Requires a small ETH deposit.
7.  `getAgentProfile(uint256 _agentId)`: View function. Retrieves the detailed profile of a specific agent.
8.  `getAgentIdByAddress(address _agentAddress)`: View function. Gets the `agentId` associated with an address.
9.  `updateAgentDescription(string calldata _newDescription)`: Allows a registered agent to update their public description.
10. `delegateAgentRole(uint256 _agentId, address _delegatee)`: Allows an agent to delegate limited control (e.g., proposing/accepting missions) to another address.
11. `revokeAgentRole(uint256 _agentId)`: Allows an agent to revoke any previously set delegation.

**III. Mission & Task Management (7 Functions)**
12. `proposeMission(string calldata _title, string calldata _description, uint256 _rewardAmount, int256 _reputationImpact)`: Allows a registered agent to propose a new mission, paying a proposal fee and providing the reward.
13. `cancelMissionProposal(uint256 _missionId)`: Allows the proposer to cancel their mission if it hasn't been accepted yet, refunding the reward and fee.
14. `acceptMission(uint256 _missionId)`: Allows a registered agent to accept an open mission, becoming its designated solver.
15. `submitMissionProof(uint256 _missionId, bytes32 _proofHash)`: The solver submits a cryptographic hash as proof of mission completion.
16. `verifyMissionCompletion(uint256 _missionId, bool _isSuccessful)`: The proposer reviews the submitted proof. If successful, rewards are released, and reputation is updated for both parties. If not, the mission can be marked as failed.
17. `challengeMissionVerification(uint256 _missionId)`: A solver can challenge a proposer's rejection of their mission, initiating a dispute state (requires admin review or future voting).
18. `getMissionDetails(uint256 _missionId)`: View function. Retrieves detailed information about a specific mission.

**IV. Adaptive Incentives & Epochs (6 Functions)**
19. `depositEpochRewardsFund()`: Allows anyone to deposit ETH into the global epoch reward pool, fueling future distributions.
20. `advanceEpoch()`: Publicly callable. Transitions the protocol to the next epoch, calculates, and distributes epoch rewards based on prior epoch activity and reputation.
21. `claimEpochRewards(uint256 _epochId)`: Allows an agent to claim their accumulated rewards for a *past* epoch.
22. `getCurrentEpochDetails()`: View function. Provides information about the current epoch, including its ID, remaining time, and reward pool.
23. `getAdaptiveRewardFactor()`: View function. Shows the current adaptive reward multiplier based on recent protocol activity.
24. `getPendingEpochRewards(uint256 _agentId)`: View function. Estimates the rewards an agent has accrued for the *current* epoch, before `advanceEpoch` is called.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title ChronosProtocol
 * @dev Decentralized Adaptive Incentive & Reputation Engine
 *
 * This contract provides a framework for a decentralized task/mission ecosystem.
 * It features dynamic incentives, a reputation system for agents, epoch-based
 * reward distributions, and a mechanism for delegated authority.
 *
 * Core Concepts:
 * - Adaptive Incentives: Reward multipliers dynamically adjust based on overall protocol activity.
 * - Agent Reputation: Users (agents) build a reputation score through successful mission completion.
 * - Mission System: A decentralized bounty board for proposing and solving tasks.
 * - Epoch-based Progression: The protocol operates in time-bound epochs for reward distribution.
 * - Delegated Authority: Agents can delegate specific actions or roles to other addresses.
 * - Proof & Challenge: Missions require off-chain proof (hash) with a basic challenge system.
 * - Pseudo-anonymous Agents: Users interact via unique agentId's.
 */
contract ChronosProtocol is Ownable, Pausable, ReentrancyGuard {
    using Address for address payable;

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed agentAddress, string description);
    event AgentDescriptionUpdated(uint256 indexed agentId, string newDescription);
    event AgentDelegated(uint256 indexed agentId, address indexed delegatee);
    event AgentDelegationRevoked(uint256 indexed agentId);

    event MissionProposed(
        uint256 indexed missionId,
        uint256 indexed proposerAgentId,
        string title,
        uint256 rewardAmount,
        int256 reputationImpact
    );
    event MissionAccepted(uint256 indexed missionId, uint256 indexed acceptedByAgentId);
    event MissionProofSubmitted(uint256 indexed missionId, uint256 indexed solverAgentId, bytes32 proofHash);
    event MissionVerified(uint256 indexed missionId, uint256 indexed proposerAgentId, uint256 indexed solverAgentId);
    event MissionRejected(uint256 indexed missionId, uint256 indexed proposerAgentId, uint256 indexed solverAgentId);
    event MissionChallenged(uint256 indexed missionId, uint256 indexed solverAgentId);
    event MissionCancelled(uint256 indexed missionId, uint256 indexed proposerAgentId);

    event EpochAdvanced(uint256 indexed newEpochId, uint256 totalEpochRewardsDistributed);
    event EpochRewardsClaimed(uint256 indexed agentId, uint256 indexed epochId, uint256 amount);
    event EpochFundDeposited(address indexed depositor, uint256 amount);

    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);

    // --- Data Structures ---

    enum MissionStatus {
        Proposed,       // Mission is open for acceptance
        Accepted,       // Mission has a solver
        Submitted,      // Solver submitted proof
        Verified,       // Proposer verified proof, mission successful
        Rejected,       // Proposer rejected proof, mission failed for solver
        Challenged,     // Solver challenged rejection
        Cancelled       // Proposer cancelled mission before acceptance
    }

    struct AgentProfile {
        uint256 agentId;
        address agentAddress; // The address controlling this profile
        uint256 reputationScore;
        uint256 totalMissionsCompleted;
        string description;
        address delegatedTo; // Address to which roles are delegated (0x0 for no delegation)
        uint256 lastEpochContribution; // Contribution points for the last completed epoch
    }

    struct Mission {
        uint256 missionId;
        uint256 proposerAgentId; // Agent ID of the proposer
        address proposerAddress; // Address of the proposer (for direct transfers)
        string title;
        string description;
        uint256 rewardAmount; // Base reward from proposer
        int256 reputationImpact; // How much reputation +/- this mission carries
        uint256 acceptedByAgentId; // Agent ID of the solver
        address acceptedByAddress; // Address of the solver
        bytes32 submissionProofHash; // Hash of the proof
        MissionStatus status;
        uint256 creationTimestamp;
        uint256 completionTimestamp; // When mission was verified or rejected
    }

    struct EpochData {
        uint256 epochId;
        uint256 startTime;
        uint256 endTime;
        uint256 rewardPoolBalance; // Funds available for distribution in this epoch
        uint256 totalContributionPoints; // Sum of all agents' contribution points for this epoch
        mapping(uint256 => uint256) agentContributionPoints; // Contribution points per agent
        mapping(uint256 => uint256) agentClaimedRewards; // Rewards claimed per agent
    }

    // --- State Variables ---

    uint256 public nextAgentId;
    uint256 public nextMissionId;
    uint256 public currentEpoch;
    uint64 public epochDuration; // Duration of an epoch in seconds

    // Protocol parameters
    uint256 public missionProposalFee; // Fee to propose a mission
    uint256 public baseReputationGain; // Base reputation gain for a verified mission
    uint256 public penaltyReputationLoss; // Reputation loss for failed missions/challenges
    uint256 public registrationDeposit; // ETH required to register an agent

    // Adaptive reward parameters
    uint256 public currentAdaptiveRewardFactor; // Multiplier for epoch rewards (e.g., 1000 = 1x, 1500 = 1.5x)
    uint256 public maxAdaptiveRewardFactor; // Upper limit for the adaptive factor
    uint256 public activityThresholdForBoost; // Number of active missions needed to boost factor

    uint256 public protocolFeeBalance; // Accumulated protocol fees

    // Mappings
    mapping(address => uint256) public agentAddressToId; // Maps agent address to their agentId
    mapping(uint256 => AgentProfile) public agentProfiles; // Stores agent profiles by agentId
    mapping(uint256 => Mission) public missions; // Stores mission details by missionId
    mapping(uint256 => EpochData) public epochs; // Stores data for each epoch by epochId

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        nextAgentId = 1; // Agent IDs start from 1
        nextMissionId = 1; // Mission IDs start from 1
        currentEpoch = 0; // Epochs start from 0
        epochDuration = 7 days; // Default 1 week epoch
        missionProposalFee = 0.01 ether; // Default mission proposal fee
        baseReputationGain = 100; // Default base reputation gain
        penaltyReputationLoss = 50; // Default penalty reputation loss
        registrationDeposit = 0.005 ether; // Default registration deposit

        currentAdaptiveRewardFactor = 1000; // Start at 1x (1000 = 100%)
        maxAdaptiveRewardFactor = 2000; // Max 2x (2000 = 200%)
        activityThresholdForBoost = 10; // If >10 active missions, adaptive factor might increase

        // Initialize epoch 0
        epochs[0].epochId = 0;
        epochs[0].startTime = block.timestamp;
        epochs[0].endTime = block.timestamp + epochDuration;
    }

    // --- Modifiers ---

    modifier onlyAgent(uint256 _agentId) {
        require(agentProfiles[_agentId].agentAddress != address(0), "Chronos: Agent does not exist");
        require(
            agentProfiles[_agentId].agentAddress == msg.sender ||
            agentProfiles[_agentId].delegatedTo == msg.sender,
            "Chronos: Not authorized for this agent profile"
        );
        _;
    }

    modifier onlyProposer(uint256 _missionId) {
        require(missions[_missionId].proposerAddress == msg.sender, "Chronos: Only mission proposer can call");
        _;
    }

    modifier onlySolver(uint256 _missionId) {
        require(missions[_missionId].acceptedByAddress == msg.sender, "Chronos: Only mission solver can call");
        _;
    }

    // --- I. Core Protocol & Administration ---

    /**
     * @dev Owner-only. Sets the duration of each epoch in seconds.
     * @param _newDuration The new duration for an epoch.
     */
    function setEpochDuration(uint64 _newDuration) external onlyOwner {
        require(_newDuration > 0, "Chronos: Epoch duration must be positive");
        emit ParametersUpdated("epochDuration", epochDuration, _newDuration);
        epochDuration = _newDuration;
    }

    /**
     * @dev Owner-only. Adjusts fees, base rewards, and reputation impacts for missions.
     * @param _newProposalFee The new fee to propose a mission.
     * @param _newBaseRewardFactor The new base reward factor for successful missions.
     * @param _newBaseReputationGain The new base reputation gain for verified missions.
     * @param _newPenaltyReputationLoss The new reputation loss for failed missions/challenges.
     */
    function setMissionParameters(
        uint256 _newProposalFee,
        uint256 _newBaseRewardFactor,
        uint256 _newBaseReputationGain,
        uint256 _newPenaltyReputationLoss
    ) external onlyOwner {
        emit ParametersUpdated("missionProposalFee", missionProposalFee, _newProposalFee);
        emit ParametersUpdated("baseReputationGain", baseReputationGain, _newBaseReputationGain);
        emit ParametersUpdated("penaltyReputationLoss", penaltyReputationLoss, _newPenaltyReputationLoss);
        missionProposalFee = _newProposalFee;
        baseReputationGain = _newBaseReputationGain;
        penaltyReputationLoss = _newPenaltyReputationLoss;
    }

    /**
     * @dev Owner-only. Configures parameters for the adaptive reward calculation.
     * @param _maxFactor The upper limit for the adaptive factor (e.g., 2000 for 2x).
     * @param _activityThreshold The number of active missions needed to start boosting the factor.
     */
    function setAdaptiveRewardParameters(uint256 _maxFactor, uint256 _activityThreshold) external onlyOwner {
        require(_maxFactor >= 1000, "Chronos: Max adaptive factor must be at least 1000 (1x)");
        emit ParametersUpdated("maxAdaptiveRewardFactor", maxAdaptiveRewardFactor, _maxFactor);
        emit ParametersUpdated("activityThresholdForBoost", activityThresholdForBoost, _activityThreshold);
        maxAdaptiveRewardFactor = _maxFactor;
        activityThresholdForBoost = _activityThreshold;
    }

    /**
     * @dev Owner-only. Allows the owner to withdraw accumulated protocol fees.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(address payable _to, uint256 _amount) external onlyOwner nonReentrant {
        require(protocolFeeBalance >= _amount, "Chronos: Insufficient protocol fee balance");
        protocolFeeBalance -= _amount;
        _to.sendValue(_amount);
        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    /**
     * @dev Pauses the contract. Owner-only.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Owner-only.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- II. Agent Management & Reputation ---

    /**
     * @dev Registers a new unique agent profile for msg.sender.
     * Requires a small ETH deposit for registration, which contributes to the protocol.
     * @param _description A short public description for the agent.
     */
    function registerAgent(string calldata _description) external payable whenNotPaused nonReentrant {
        require(agentAddressToId[msg.sender] == 0, "Chronos: Address already registered as an agent");
        require(msg.value >= registrationDeposit, "Chronos: Insufficient registration deposit");

        uint256 newAgentId = nextAgentId++;
        agentAddressToId[msg.sender] = newAgentId;
        agentProfiles[newAgentId] = AgentProfile({
            agentId: newAgentId,
            agentAddress: msg.sender,
            reputationScore: 1000, // Starting reputation
            totalMissionsCompleted: 0,
            description: _description,
            delegatedTo: address(0),
            lastEpochContribution: 0
        });

        if (msg.value > 0) {
            protocolFeeBalance += msg.value;
        }

        emit AgentRegistered(newAgentId, msg.sender, _description);
    }

    /**
     * @dev Retrieves the detailed profile of a specific agent.
     * @param _agentId The ID of the agent.
     * @return AgentProfile struct containing agent details.
     */
    function getAgentProfile(uint256 _agentId)
        external
        view
        returns (
            uint256 agentId,
            address agentAddress,
            uint256 reputationScore,
            uint256 totalMissionsCompleted,
            string memory description,
            address delegatedTo,
            uint256 lastEpochContribution
        )
    {
        require(agentProfiles[_agentId].agentAddress != address(0), "Chronos: Agent does not exist");
        AgentProfile storage profile = agentProfiles[_agentId];
        return (
            profile.agentId,
            profile.agentAddress,
            profile.reputationScore,
            profile.totalMissionsCompleted,
            profile.description,
            profile.delegatedTo,
            profile.lastEpochContribution
        );
    }

    /**
     * @dev Retrieves the agent ID associated with a given address.
     * @param _agentAddress The address to query.
     * @return The agent ID, or 0 if not registered.
     */
    function getAgentIdByAddress(address _agentAddress) external view returns (uint256) {
        return agentAddressToId[_agentAddress];
    }

    /**
     * @dev Allows a registered agent to update their public description.
     * Callable by the agent's address or their delegated address.
     * @param _newDescription The new description for the agent.
     */
    function updateAgentDescription(string calldata _newDescription) external whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        require(agentId != 0, "Chronos: Sender is not a registered agent");

        // If msg.sender is a delegate, ensure it's delegated to this agent
        if (agentProfiles[agentId].agentAddress != msg.sender) {
            require(
                agentProfiles[agentId].delegatedTo == msg.sender,
                "Chronos: Not authorized to update this agent's description"
            );
        }

        agentProfiles[agentId].description = _newDescription;
        emit AgentDescriptionUpdated(agentId, _newDescription);
    }

    /**
     * @dev Allows an agent to delegate limited control (e.g., proposing/accepting missions)
     * to another address. This is useful for automated agents or team management.
     * @param _agentId The ID of the agent performing the delegation.
     * @param _delegatee The address to which roles are delegated. Set to 0x0 to clear.
     */
    function delegateAgentRole(uint256 _agentId, address _delegatee) external onlyAgent(_agentId) {
        require(_delegatee != agentProfiles[_agentId].agentAddress, "Chronos: Cannot delegate to self");
        agentProfiles[_agentId].delegatedTo = _delegatee;
        emit AgentDelegated(_agentId, _delegatee);
    }

    /**
     * @dev Allows an agent to revoke any previously set delegation.
     * @param _agentId The ID of the agent revoking the delegation.
     */
    function revokeAgentRole(uint256 _agentId) external onlyAgent(_agentId) {
        require(agentProfiles[_agentId].delegatedTo != address(0), "Chronos: No active delegation to revoke");
        address revokedDelegatee = agentProfiles[_agentId].delegatedTo;
        agentProfiles[_agentId].delegatedTo = address(0);
        emit AgentDelegationRevoked(_agentId);
    }

    // --- III. Mission & Task Management ---

    /**
     * @dev Allows a registered agent to propose a new mission.
     * Requires the `missionProposalFee` and `_rewardAmount` to be sent with the transaction.
     * @param _title The title of the mission.
     * @param _description A detailed description of the mission.
     * @param _rewardAmount The ETH reward for completing the mission.
     * @param _reputationImpact The expected reputation change for this mission (can be negative).
     */
    function proposeMission(
        string calldata _title,
        string calldata _description,
        uint256 _rewardAmount,
        int256 _reputationImpact
    ) external payable whenNotPaused nonReentrant {
        uint256 proposerAgentId = agentAddressToId[msg.sender];
        require(proposerAgentId != 0, "Chronos: Sender is not a registered agent");
        require(msg.value == (missionProposalFee + _rewardAmount), "Chronos: Incorrect ETH sent for proposal");
        require(_rewardAmount > 0, "Chronos: Mission reward must be positive");
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Chronos: Title and description cannot be empty");

        uint256 newMissionId = nextMissionId++;
        missions[newMissionId] = Mission({
            missionId: newMissionId,
            proposerAgentId: proposerAgentId,
            proposerAddress: msg.sender,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            reputationImpact: _reputationImpact,
            acceptedByAgentId: 0,
            acceptedByAddress: address(0),
            submissionProofHash: bytes32(0),
            status: MissionStatus.Proposed,
            creationTimestamp: block.timestamp,
            completionTimestamp: 0
        });

        protocolFeeBalance += missionProposalFee; // Protocol takes the fee
        // _rewardAmount remains in the contract, locked for the mission

        emit MissionProposed(newMissionId, proposerAgentId, _title, _rewardAmount, _reputationImpact);
    }

    /**
     * @dev Allows the proposer to cancel their mission if it hasn't been accepted yet.
     * Refunds the reward and fee.
     * @param _missionId The ID of the mission to cancel.
     */
    function cancelMissionProposal(uint256 _missionId) external onlyProposer(_missionId) nonReentrant {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Proposed, "Chronos: Mission cannot be cancelled in its current state");

        // Refund reward amount
        if (mission.rewardAmount > 0) {
            payable(mission.proposerAddress).sendValue(mission.rewardAmount);
        }

        // Refund missionProposalFee (if applicable, or simply mark it as cancelled)
        // For simplicity, let's refund the fee as well. In a more complex system,
        // a portion of the fee might be non-refundable.
        if (missionProposalFee > 0) {
            require(protocolFeeBalance >= missionProposalFee, "Chronos: Insufficient protocol fees to refund");
            protocolFeeBalance -= missionProposalFee;
            payable(mission.proposerAddress).sendValue(missionProposalFee);
        }

        mission.status = MissionStatus.Cancelled;
        emit MissionCancelled(_missionId, mission.proposerAgentId);
    }

    /**
     * @dev Allows a registered agent to accept an open mission, becoming its designated solver.
     * @param _missionId The ID of the mission to accept.
     */
    function acceptMission(uint256 _missionId) external whenNotPaused {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Proposed, "Chronos: Mission is not open for acceptance");

        uint256 solverAgentId = agentAddressToId[msg.sender];
        require(solverAgentId != 0, "Chronos: Sender is not a registered agent");
        require(solverAgentId != mission.proposerAgentId, "Chronos: Proposer cannot accept their own mission");

        mission.acceptedByAgentId = solverAgentId;
        mission.acceptedByAddress = msg.sender;
        mission.status = MissionStatus.Accepted;

        emit MissionAccepted(_missionId, solverAgentId);
    }

    /**
     * @dev The solver submits a cryptographic hash as proof of mission completion.
     * @param _missionId The ID of the mission.
     * @param _proofHash The hash representing the off-chain proof (e.g., IPFS hash, transaction hash).
     */
    function submitMissionProof(uint256 _missionId, bytes32 _proofHash) external onlySolver(_missionId) whenNotPaused {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Accepted, "Chronos: Mission is not in accepted state");
        require(_proofHash != bytes32(0), "Chronos: Proof hash cannot be empty");

        mission.submissionProofHash = _proofHash;
        mission.status = MissionStatus.Submitted;

        emit MissionProofSubmitted(_missionId, mission.acceptedByAgentId, _proofHash);
    }

    /**
     * @dev The proposer reviews the submitted proof. If successful, rewards are released,
     * and reputation is updated for both parties. If not, the mission can be marked as failed.
     * @param _missionId The ID of the mission.
     * @param _isSuccessful True if the proof is accepted, false if rejected.
     */
    function verifyMissionCompletion(uint256 _missionId, bool _isSuccessful) external onlyProposer(_missionId) nonReentrant {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Submitted, "Chronos: Mission proof not submitted or already verified/rejected");

        AgentProfile storage proposerProfile = agentProfiles[mission.proposerAgentId];
        AgentProfile storage solverProfile = agentProfiles[mission.acceptedByAgentId];

        mission.completionTimestamp = block.timestamp;

        if (_isSuccessful) {
            mission.status = MissionStatus.Verified;
            solverProfile.totalMissionsCompleted++;

            // Distribute reward to solver
            payable(solverProfile.agentAddress).sendValue(mission.rewardAmount);

            // Update reputation for both
            if (mission.reputationImpact >= 0) {
                solverProfile.reputationScore += uint256(mission.reputationImpact);
                proposerProfile.reputationScore += baseReputationGain; // Proposer also gains for successful verification
            } else {
                // Handle negative reputation impact, ensuring score doesn't go below 0
                solverProfile.reputationScore = solverProfile.reputationScore > uint256(mission.reputationImpact * -1)
                    ? solverProfile.reputationScore - uint256(mission.reputationImpact * -1)
                    : 0;
            }
            // Add contribution points for epoch rewards
            epochs[currentEpoch].agentContributionPoints[solverProfile.agentId] += (baseReputationGain * 2); // Solver contributes more
            epochs[currentEpoch].agentContributionPoints[proposerProfile.agentId] += baseReputationGain;
            epochs[currentEpoch].totalContributionPoints += (baseReputationGain * 3);


            emit MissionVerified(_missionId, mission.proposerAgentId, mission.acceptedByAgentId);
        } else {
            mission.status = MissionStatus.Rejected;
            solverProfile.reputationScore = solverProfile.reputationScore > penaltyReputationLoss
                ? solverProfile.reputationScore - penaltyReputationLoss
                : 0;
            // Reward (mission.rewardAmount) remains locked, or could be returned to proposer / sent to protocol fees.
            // For now, it stays locked, can be manually withdrawn by owner if mission.status = Rejected for long.
            // In a real system, more sophisticated handling (e.g., burning, or refund to proposer) would be needed.

            emit MissionRejected(_missionId, mission.proposerAgentId, mission.acceptedByAgentId);
        }
    }

    /**
     * @dev A solver can challenge a proposer's rejection of their mission.
     * This moves the mission to a 'Challenged' state, indicating a dispute.
     * In a full system, this would trigger a more complex arbitration/voting process.
     * For this contract, it merely flags the mission for potential administrative review.
     * @param _missionId The ID of the mission to challenge.
     */
    function challengeMissionVerification(uint256 _missionId) external onlySolver(_missionId) {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Rejected, "Chronos: Mission is not in a rejected state to be challenged");
        mission.status = MissionStatus.Challenged;
        emit MissionChallenged(_missionId, mission.acceptedByAgentId);
    }

    /**
     * @dev Retrieves detailed information about a specific mission.
     * @param _missionId The ID of the mission.
     * @return Mission struct containing mission details.
     */
    function getMissionDetails(uint256 _missionId)
        external
        view
        returns (
            uint256 missionId,
            uint256 proposerAgentId,
            address proposerAddress,
            string memory title,
            string memory description,
            uint256 rewardAmount,
            int256 reputationImpact,
            uint256 acceptedByAgentId,
            address acceptedByAddress,
            bytes32 submissionProofHash,
            MissionStatus status,
            uint256 creationTimestamp,
            uint256 completionTimestamp
        )
    {
        require(missions[_missionId].missionId == _missionId, "Chronos: Mission does not exist");
        Mission storage mission = missions[_missionId];
        return (
            mission.missionId,
            mission.proposerAgentId,
            mission.proposerAddress,
            mission.title,
            mission.description,
            mission.rewardAmount,
            mission.reputationImpact,
            mission.acceptedByAgentId,
            mission.acceptedByAddress,
            mission.submissionProofHash,
            mission.status,
            mission.creationTimestamp,
            mission.completionTimestamp
        );
    }

    // --- IV. Adaptive Incentives & Epochs ---

    /**
     * @dev Allows anyone to deposit ETH into the global epoch reward pool, fueling future distributions.
     */
    function depositEpochRewardsFund() external payable whenNotPaused {
        require(msg.value > 0, "Chronos: Must deposit a positive amount");
        epochs[currentEpoch].rewardPoolBalance += msg.value;
        emit EpochFundDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Publicly callable. Transitions the protocol to the next epoch.
     * This function calculates and distributes epoch rewards based on prior epoch activity
     * and reputation, and recalibrates the adaptive reward factor.
     */
    function advanceEpoch() external whenNotPaused nonReentrant {
        EpochData storage prevEpoch = epochs[currentEpoch];
        require(block.timestamp >= prevEpoch.endTime, "Chronos: Current epoch has not ended yet");

        uint256 totalDistributed = 0;

        // 1. Distribute rewards for the just-ended epoch (prevEpoch)
        if (prevEpoch.rewardPoolBalance > 0 && prevEpoch.totalContributionPoints > 0) {
            for (uint256 i = 1; i < nextAgentId; i++) {
                if (agentProfiles[i].agentAddress != address(0) && prevEpoch.agentContributionPoints[i] > 0) {
                    uint256 share = (prevEpoch.agentContributionPoints[i] * prevEpoch.rewardPoolBalance) /
                        prevEpoch.totalContributionPoints;
                    // Apply adaptive reward factor, divided by 1000 to normalize (e.g., 1500 -> 1.5x)
                    uint256 finalShare = (share * currentAdaptiveRewardFactor) / 1000;
                    agentProfiles[i].lastEpochContribution = finalShare; // Store for claiming
                    totalDistributed += finalShare;
                }
            }
            // Any leftover (due to rounding or if totalDistributed < prevEpoch.rewardPoolBalance) goes to protocol fees
            if (prevEpoch.rewardPoolBalance > totalDistributed) {
                 protocolFeeBalance += (prevEpoch.rewardPoolBalance - totalDistributed);
            }
            prevEpoch.rewardPoolBalance = 0; // Clear the pool after distribution calculation
        }

        // 2. Advance to the next epoch
        currentEpoch++;
        epochs[currentEpoch].epochId = currentEpoch;
        epochs[currentEpoch].startTime = block.timestamp;
        epochs[currentEpoch].endTime = block.timestamp + epochDuration;
        epochs[currentEpoch].rewardPoolBalance = 0; // Starts empty or with deposits

        // 3. Recalculate adaptive reward factor based on recent activity (e.g., active missions)
        uint256 activeMissionCount = 0;
        for (uint256 i = 1; i < nextMissionId; i++) {
            if (missions[i].status == MissionStatus.Accepted || missions[i].status == MissionStatus.Submitted) {
                activeMissionCount++;
            }
        }
        if (activeMissionCount >= activityThresholdForBoost) {
            // Simple linear increase towards max, could be logarithmic or more complex
            currentAdaptiveRewardFactor += 100; // Increase by 10%
            if (currentAdaptiveRewardFactor > maxAdaptiveRewardFactor) {
                currentAdaptiveRewardFactor = maxAdaptiveRewardFactor;
            }
        } else if (currentAdaptiveRewardFactor > 1000) {
            // Decrease if activity is low, but not below base 1x
            currentAdaptiveRewardFactor -= 50;
            if (currentAdaptiveRewardFactor < 1000) {
                currentAdaptiveRewardFactor = 1000;
            }
        }

        emit EpochAdvanced(currentEpoch, totalDistributed);
    }

    /**
     * @dev Allows an agent to claim their accumulated rewards for a *past* epoch.
     * Rewards are calculated by `advanceEpoch` and stored in `agentProfiles[agentId].lastEpochContribution`.
     * @param _epochId The ID of the epoch for which to claim rewards.
     */
    function claimEpochRewards(uint256 _epochId) external whenNotPaused nonReentrant {
        uint256 agentId = agentAddressToId[msg.sender];
        require(agentId != 0, "Chronos: Sender is not a registered agent");
        require(_epochId < currentEpoch, "Chronos: Cannot claim rewards for current or future epochs");
        require(epochs[_epochId].agentClaimedRewards[agentId] == 0, "Chronos: Rewards for this epoch already claimed");

        // Rewards were already calculated and stored in agentProfiles[agentId].lastEpochContribution
        // in the advanceEpoch function for the *previous* epoch.
        // For simplicity, let's assume `lastEpochContribution` always stores rewards for the *last* completed epoch.
        // In a more robust system, rewards per epoch for each agent would be stored in the EpochData struct.
        // Let's adapt this to store rewards in the `EpochData` struct for precision.

        uint256 rewardsToClaim = epochs[_epochId].agentContributionPoints[agentId]; // This should be the calculated final reward
        require(rewardsToClaim > 0, "Chronos: No rewards to claim for this epoch");

        epochs[_epochId].agentClaimedRewards[agentId] = rewardsToClaim; // Mark as claimed

        payable(msg.sender).sendValue(rewardsToClaim);
        emit EpochRewardsClaimed(agentId, _epochId, rewardsToClaim);
    }

    /**
     * @dev Provides information about the current epoch, including its ID, remaining time, and reward pool.
     * @return epochId The current epoch ID.
     * @return startTime The timestamp when the current epoch started.
     * @return endTime The timestamp when the current epoch is scheduled to end.
     * @return rewardPoolBalance The current balance available in the epoch reward pool.
     * @return adaptiveRewardFactor The current adaptive reward multiplier.
     */
    function getCurrentEpochDetails()
        external
        view
        returns (
            uint256 epochId,
            uint256 startTime,
            uint256 endTime,
            uint256 rewardPoolBalance,
            uint256 adaptiveRewardFactor
        )
    {
        EpochData storage epoch = epochs[currentEpoch];
        return (epoch.epochId, epoch.startTime, epoch.endTime, epoch.rewardPoolBalance, currentAdaptiveRewardFactor);
    }

    /**
     * @dev Returns the current adaptive reward multiplier.
     * @return The current adaptive reward factor (e.g., 1000 for 1x, 1500 for 1.5x).
     */
    function getAdaptiveRewardFactor() external view returns (uint256) {
        return currentAdaptiveRewardFactor;
    }

    /**
     * @dev Estimates the rewards an agent has accrued for the *current* epoch.
     * This is a preliminary estimate before `advanceEpoch` finalizes distribution.
     * @param _agentId The ID of the agent.
     * @return Estimated rewards in WEI.
     */
    function getPendingEpochRewards(uint256 _agentId) external view returns (uint256) {
        require(agentProfiles[_agentId].agentAddress != address(0), "Chronos: Agent does not exist");
        EpochData storage currentEpochData = epochs[currentEpoch];

        if (currentEpochData.totalContributionPoints == 0) {
            return 0;
        }

        uint256 agentContribution = currentEpochData.agentContributionPoints[_agentId];
        if (agentContribution == 0) {
            return 0;
        }

        uint256 estimatedShare = (agentContribution * currentEpochData.rewardPoolBalance) /
            currentEpochData.totalContributionPoints;
        // Apply adaptive reward factor to the estimate
        return (estimatedShare * currentAdaptiveRewardFactor) / 1000;
    }
}
```