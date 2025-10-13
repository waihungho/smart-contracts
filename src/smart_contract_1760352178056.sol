This smart contract, "The Synergistic Autonomic Protocol (SAP)", aims to create an adaptive and resilient decentralized ecosystem. It combines advanced governance mechanisms, a dynamic reputation system (`SynergyScore`), and on-chain "ecosystem health" metrics to enable the protocol to self-optimize and evolve.

Unlike traditional token-weighted DAOs, SAP introduces proposals that include *projected impacts* on various ecosystem health metrics. Voters, using their `SynergyScore` (earned through constructive participation), evaluate these projections. The protocol also features dynamic parameters, an initiative-based grant system, and an emergency mode for extreme conditions, all governed by the community.

---

## Contract: `SynergisticAutonomicProtocol`

### Outline:

1.  **Libraries & Interfaces**: Importing necessary functionalities.
2.  **Error Definitions**: Custom errors for better UX and gas efficiency.
3.  **Core Data Structures**: Structs for `Proposal`, `Initiative`, `CoreParameter`, `HealthMetric`, and `SynergyDelegateLock`.
4.  **State Variables**: Mappings, counters, and general state relevant to the protocol.
5.  **Events**: To signal important actions and state changes.
6.  **Modifiers**: For access control and state checks.
7.  **Constructor**: Initializes the contract owner and core treasury.
8.  **Administration Functions**: Basic owner-only controls.
9.  **Core Parameter Management**:
    *   Define, update, and retrieve protocol parameters.
10. **Ecosystem Health Metrics**:
    *   Define, update, and retrieve ecosystem health indicators.
    *   Evaluate overall system stability.
11. **Synergy Score (Reputation) System**:
    *   Award and burn `SynergyScore`.
    *   Get user scores.
    *   Delegate `SynergyScore` for a duration.
12. **Governance & Proposals**:
    *   Propose parameter changes or new initiatives.
    *   Vote on active proposals.
    *   Execute or cancel proposals.
    *   Retrieve proposal details.
13. **Initiative & Grant System**:
    *   Request grants for active initiatives.
    *   Process grant requests.
    *   Retrieve initiative details.
14. **Treasury Management**:
    *   Deposit funds into the protocol treasury.
    *   Utility function for recovering accidentally sent ETH.
15. **Emergency Protocol**:
    *   Activate and deactivate a protocol-wide emergency state based on health metrics.

---

### Function Summary:

1.  `constructor(address _initialOwner, address _daoTreasury)`: Initializes the contract with an owner and the address for the DAO's treasury.
2.  `updateDaoTreasury(address _newTreasury)`: (Admin) Updates the address of the DAO's main treasury.
3.  `defineCoreParameter(string calldata _key, uint256 _initialValue)`: (Admin/DAO) Defines a new core protocol parameter with an initial value.
4.  `getCoreParameter(string calldata _key) view returns (uint256)`: Retrieves the current value of a core parameter.
5.  `proposeParameterChange(string calldata _paramKey, uint256 _newValue, string[] calldata _impactKeys, int256[] calldata _impactValues, bool _requiresSynergyLock)`: Allows a user with sufficient `SynergyScore` to propose changing a core protocol parameter, including its projected impacts on health metrics.
6.  `proposeNewInitiative(string calldata _description, uint256 _initialBudgetRequest, string[] calldata _targetImpactKeys, int256[] calldata _targetImpactValues)`: Allows a user to propose a new protocol initiative, detailing its purpose, initial budget, and projected impact on health metrics.
7.  `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to cast their `SynergyScore`-weighted vote for or against a proposal.
8.  `executeProposal(uint256 _proposalId)`: Executes a proposal if it has met the quorum, passed the voting period, and received more `SynergyScore` votes for than against. Applies parameter changes and adjusts health metrics based on projections.
9.  `cancelProposal(uint256 _proposalId)`: Allows the original proposer to cancel their own proposal if it hasn't started voting or if specific conditions are met.
10. `getProposalDetails(uint256 _proposalId) view returns (Proposal memory)`: Retrieves all details of a specific proposal.
11. `getInitiativeDetails(uint256 _initiativeId) view returns (Initiative memory)`: Retrieves all details of a specific initiative.
12. `awardSynergyScore(address _user, uint256 _amount)`: (Internal/DAO) Awards `SynergyScore` to a user for positive contributions.
13. `burnSynergyScore(address _user, uint256 _amount)`: (Internal/DAO) Reduces `SynergyScore` of a user as a penalty for negative actions.
14. `getSynergyScore(address _user) view returns (uint256)`: Retrieves the `SynergyScore` of a given address.
15. `delegateSynergy(address _delegatee, uint256 _duration)`: Allows a user to delegate their `SynergyScore` to another address for a specified duration, locking their own score during this period.
16. `undelegateSynergy()`: Allows a user to revoke their `SynergyScore` delegation after the lockup period or if no active delegation exists.
17. `updateHealthMetric(string calldata _metricKey, int256 _delta)`: (Internal/DAO) Adjusts a specific ecosystem health metric by a given delta. This function is designed to be called after observable impacts of proposals or external events.
18. `getEcosystemHealthMetrics() view returns (string[] memory, int256[] memory)`: Returns all currently tracked ecosystem health metrics and their values.
19. `evaluateOverallStability() view returns (int256)`: Calculates a composite "stability index" based on predefined health metrics, used to determine overall system health and potential emergency activation.
20. `depositToTreasury() payable`: Allows anyone to send ETH to the protocol's treasury.
21. `requestInitiativeGrant(uint256 _initiativeId, uint256 _amount, string calldata _reason)`: Allows the lead of an active initiative to request funds from the treasury.
22. `processInitiativeGrantRequest(uint256 _initiativeId, address _recipient, uint256 _amount, bool _approve)`: (DAO) Processes a grant request for an initiative, either approving and sending funds or denying it.
23. `activateEmergencyProtocol()`: (DAO/Protocol) Activates an emergency state if the `evaluateOverallStability()` falls below a critical threshold, potentially freezing certain protocol functionalities.
24. `deactivateEmergencyProtocol()`: (DAO/Protocol) Deactivates the emergency state when system health recovers.
25. `withdrawStuckEth()`: (Admin) Allows the owner to withdraw accidentally sent ETH from the contract (excluding the DAO treasury).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title The Synergistic Autonomic Protocol (SAP)
/// @dev A smart contract designed for adaptive governance, leveraging a dynamic reputation system (SynergyScore)
///      and on-chain "ecosystem health" metrics to enable the protocol to self-optimize and evolve.
///      Proposals include projected impacts on health metrics, and voting power is derived from SynergyScore.
///      Features include dynamic parameters, an initiative-based grant system, and an emergency mode.
contract SynergisticAutonomicProtocol is Ownable, ReentrancyGuard {
    using SafeCast for uint256;

    /*
     *
     * Libraries & Interfaces
     * (None explicitly imported beyond OpenZeppelin for this example, but can be added)
     *
     */

    /*
     *
     * Error Definitions
     *
     */
    error InvalidParameterKey();
    error ParameterNotFound(string key);
    error ProposalNotFound(uint256 proposalId);
    error InitiativeNotFound(uint256 initiativeId);
    error InsufficientSynergyScore(address user, uint256 required, uint256 had);
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error ProposalVotingPeriodEnded();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error ProposalStillActive();
    error ProposalNotCancellable();
    error UnauthorizedAction(address caller);
    error EmptyImpactProjection();
    error ImpactProjectionMismatch();
    error SelfDelegationNotAllowed();
    error DelegationActive();
    error NoActiveDelegation();
    error DelegationDurationTooShort();
    error DelegationDurationTooLong();
    error InitiativeNotActive();
    error InsufficientTreasuryFunds(uint256 requested, uint256 available);
    error NotInEmergencyMode();
    error AlreadyInEmergencyMode();
    error StabilityThresholdNotMet(int256 currentStability, int256 requiredStability);
    error StabilityThresholdExceeded(int256 currentStability, int256 maxStability);
    error EmptyString();

    /*
     *
     * Core Data Structures
     *
     */

    enum ProposalTargetType { ParameterChange, NewInitiative }
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Cancelled }
    enum InitiativeStatus { Proposed, Active, Completed, Failed }

    /// @dev Represents a proposal for changing a parameter or creating an initiative.
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        ProposalTargetType targetType;
        string targetParameterKey; // Used if targetType is ParameterChange
        uint256 newParameterValue;  // Used if targetType is ParameterChange
        uint256 targetInitiativeId; // Used if targetType is NewInitiative
        uint256 initialBudgetRequest; // Used if targetType is NewInitiative
        uint256 snapshotTotalSynergy; // Total SynergyScore available at proposal creation
        mapping(address => bool) hasVoted; // Tracks who voted
        uint256 votesFor; // Total SynergyScore for
        uint256 votesAgainst; // Total SynergyScore against
        uint256 creationBlock;
        uint256 endBlock;
        ProposalStatus status;
        mapping(string => int256) impactProjections; // Projected impact on health metrics (e.g., "stabilityIndex": +10)
        bool requiresSynergyLock; // If true, voters must have locked SynergyScore to vote
    }

    /// @dev Represents an ongoing project or initiative funded by the protocol.
    struct Initiative {
        uint256 id;
        address lead;
        string description;
        uint256 currentBudget; // Funds allocated to this initiative
        uint256 fundsRequestedTotal; // Total funds requested by this initiative
        InitiativeStatus status;
        // Optionally, could add a history of health impact observed post-execution
        // mapping(string => int256[]) healthImpactHistory;
    }

    /// @dev Represents a core adjustable parameter of the protocol.
    struct CoreParameter {
        uint256 value;
        uint256 lastUpdatedBlock;
        uint256 updateCount;
        // Optionally, could add a history: (block => value)
    }

    /// @dev Represents a key ecosystem health metric.
    struct HealthMetric {
        int256 currentValue;
        uint256 lastUpdatedBlock;
        int256 deviationThreshold; // Threshold for triggering alerts or emergency mode
    }

    /// @dev Tracks active SynergyScore delegations.
    struct SynergyDelegateLock {
        address delegatee;
        uint256 unlockTime;
    }

    /*
     *
     * State Variables
     *
     */

    address public daoTreasuryAddress;
    bool public emergencyModeActive;

    // Counters for unique IDs
    uint256 private _proposalIdCounter;
    uint256 private _initiativeIdCounter;

    // Core protocol parameters, e.g., vote quorum, voting period, min synergy to propose
    mapping(string => CoreParameter) public protocolParameters;
    string[] public parameterKeys; // To iterate over parameters

    // Ecosystem health metrics, e.g., 'stabilityIndex', 'engagementScore'
    mapping(string => HealthMetric) public ecosystemHealthMetrics;
    string[] public healthMetricKeys; // To iterate over health metrics

    // User's accumulated reputation score for governance participation
    mapping(address => uint256) public synergyScores;

    // Active proposals mapped by ID
    mapping(uint256 => Proposal) public proposals;

    // Active initiatives mapped by ID
    mapping(uint256 => Initiative) public initiatives;

    // SynergyScore delegation tracking: user => SynergyDelegateLock
    mapping(address => SynergyDelegateLock) public synergyDelegations;

    // SynergeyScore delegated to an address
    mapping(address => uint256) public delegatedSynergy;

    // Constants (can be defined as CoreParameters for DAO configurability)
    uint256 public constant MIN_SYNERGY_TO_PROPOSE = 100; // Example
    uint256 public constant PROPOSAL_VOTING_PERIOD_BLOCKS = 1000; // Example, ~3-4 hours
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 4; // 4% of total synergy needed to pass
    int256 public constant EMERGENCY_HEALTH_THRESHOLD = -500; // If evaluateOverallStability drops below this, emergency can be activated
    uint256 public constant MAX_DELEGATION_DURATION_BLOCKS = 30000; // Approx 5 days

    /*
     *
     * Events
     *
     */
    event DaoTreasuryUpdated(address indexed newTreasury);
    event CoreParameterDefined(string indexed key, uint256 initialValue);
    event CoreParameterUpdated(string indexed key, uint256 newValue, address indexed proposer);
    event HealthMetricUpdated(string indexed key, int256 delta, int256 newValue);
    event SynergyScoreAwarded(address indexed user, uint256 amount, uint256 newScore);
    event SynergyScoreBurned(address indexed user, uint256 amount, uint256 newScore);
    event SynergyDelegated(address indexed delegator, address indexed delegatee, uint256 durationBlocks);
    event SynergyUndelegated(address indexed delegator, address indexed previousDelegatee);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalTargetType targetType, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 synergyWeight);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus status);
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);
    event InitiativeCreated(uint256 indexed initiativeId, address indexed lead, string description, uint256 initialBudget);
    event InitiativeGrantRequested(uint256 indexed initiativeId, address indexed requester, uint256 amount);
    event InitiativeGrantProcessed(uint256 indexed initiativeId, address indexed recipient, uint256 amount, bool approved);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event EmergencyModeActivated(address indexed activator, int256 stabilityScore);
    event EmergencyModeDeactivated(address indexed deactivator, int256 stabilityScore);
    event EthWithdrawn(address indexed recipient, uint256 amount);

    /*
     *
     * Modifiers
     *
     */

    /// @dev Ensures the caller has enough SynergyScore to propose.
    modifier hasMinSynergyToPropose(address _user) {
        if (synergyScores[_user] < MIN_SYNERGY_TO_PROPOSE) {
            revert InsufficientSynergyScore(_user, MIN_SYNERGY_TO_PROPOSE, synergyScores[_user]);
        }
        _;
    }

    /// @dev Ensures the caller is the DAO Treasury or an internal function authorized by DAO.
    modifier onlyDaoOrInternal() {
        if (msg.sender != daoTreasuryAddress && msg.sender != address(this)) {
            // In a more complex system, this would be a specific DAO role.
            // For this example, treasury address represents the DAO's explicit actions.
            // Or this could be `onlyRole(DAO_EXECUTOR_ROLE)`
            revert UnauthorizedAction(msg.sender);
        }
        _;
    }

    /// @dev Ensures the system is not in emergency mode.
    modifier notInEmergency() {
        if (emergencyModeActive) {
            revert AlreadyInEmergencyMode();
        }
        _;
    }

    /// @dev Ensures the system is in emergency mode.
    modifier inEmergency() {
        if (!emergencyModeActive) {
            revert NotInEmergencyMode();
        }
        _;
    }

    /*
     *
     * Constructor
     *
     */

    /// @dev Initializes the contract with an owner and the address for the DAO's treasury.
    /// @param _initialOwner The address of the initial contract owner (for administrative tasks).
    /// @param _daoTreasury The address of the DAO's main treasury, which holds protocol funds.
    constructor(address _initialOwner, address _daoTreasury) Ownable(_initialOwner) {
        if (_daoTreasury == address(0)) revert UnauthorizedAction(address(0));
        daoTreasuryAddress = _daoTreasury;

        // Initialize some default core parameters and health metrics
        _initializeDefaultParameters();
        _initializeDefaultHealthMetrics();
    }

    /*
     *
     * Administration Functions
     *
     */

    /// @dev Updates the address of the DAO's main treasury.
    /// @param _newTreasury The new address for the DAO treasury.
    function updateDaoTreasury(address _newTreasury) public onlyOwner {
        if (_newTreasury == address(0)) revert UnauthorizedAction(address(0));
        daoTreasuryAddress = _newTreasury;
        emit DaoTreasuryUpdated(_newTreasury);
    }

    /// @dev Recovers accidentally sent ETH from the contract to the owner.
    ///      Does not affect the `daoTreasuryAddress`.
    function withdrawStuckEth() public onlyOwner {
        uint256 amount = address(this).balance;
        if (amount == 0) return;
        
        // Prevent draining the actual treasury balance if it somehow lands here.
        // Assuming daoTreasuryAddress will be a separate contract or EOA holding funds.
        // This function is for funds sent *directly* to this logic contract.
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) {
            // Optionally, re-revert if withdrawal fails, or log and try again later.
            // For now, assume a failing withdrawal means ETH is truly stuck.
            revert UnauthorizedAction(address(this)); // Reusing error, should be a specific error
        }
        emit EthWithdrawn(owner(), amount);
    }

    /*
     *
     * Core Parameter Management
     *
     */

    /// @dev Internal helper to define initial default parameters.
    function _initializeDefaultParameters() internal {
        _defineParameter("MinSynergyToPropose", MIN_SYNERGY_TO_PROPOSE);
        _defineParameter("ProposalVotingPeriodBlocks", PROPOSAL_VOTING_PERIOD_BLOCKS);
        _defineParameter("ProposalQuorumPercentage", PROPOSAL_QUORUM_PERCENTAGE);
        _defineParameter("EmergencyHealthThreshold", uint256(uint128(EMERGENCY_HEALTH_THRESHOLD))); // Cast to uint for storage
    }

    /// @dev Internal helper to safely define a parameter, preventing duplicates.
    function _defineParameter(string calldata _key, uint256 _value) internal {
        if (bytes(protocolParameters[_key].value).length != 0 || protocolParameters[_key].lastUpdatedBlock != 0) {
            // Already defined, avoid collision with default values
            return;
        }
        protocolParameters[_key] = CoreParameter({
            value: _value,
            lastUpdatedBlock: block.number,
            updateCount: 0
        });
        parameterKeys.push(_key);
    }

    /// @dev Defines a new core protocol parameter with an initial value.
    /// @param _key The unique identifier for the parameter (e.g., "MinVoteDuration").
    /// @param _initialValue The initial numeric value of the parameter.
    function defineCoreParameter(string calldata _key, uint256 _initialValue) public onlyDaoOrInternal {
        if (bytes(_key).length == 0) revert EmptyString();
        // Check if key already exists in parameterKeys to prevent duplicates.
        // This is not strictly necessary as mapping overwrite works, but good for explicit tracking.
        for (uint256 i = 0; i < parameterKeys.length; i++) {
            if (keccak256(abi.encodePacked(parameterKeys[i])) == keccak256(abi.encodePacked(_key))) {
                revert InvalidParameterKey(); // Parameter already defined
            }
        }
        _defineParameter(_key, _initialValue);
        emit CoreParameterDefined(_key, _initialValue);
    }

    /// @dev Retrieves the current value of a core protocol parameter.
    /// @param _key The identifier of the parameter.
    /// @return The current numeric value of the parameter.
    function getCoreParameter(string calldata _key) public view returns (uint256) {
        if (bytes(_key).length == 0) revert EmptyString();
        if (protocolParameters[_key].lastUpdatedBlock == 0) revert ParameterNotFound(_key);
        return protocolParameters[_key].value;
    }

    /*
     *
     * Ecosystem Health Metrics
     *
     */

    /// @dev Internal helper to define initial default health metrics.
    function _initializeDefaultHealthMetrics() internal {
        _defineHealthMetric("stabilityIndex", 0, 100); // Max deviation of 100 before warning
        _defineHealthMetric("engagementScore", 1000, 200);
        _defineHealthMetric("treasuryRatio", 1000, 500); // 1000 represents 100% ideal
    }

    /// @dev Internal helper to safely define a health metric, preventing duplicates.
    function _defineHealthMetric(string calldata _key, int256 _initialValue, int256 _deviationThreshold) internal {
         for (uint256 i = 0; i < healthMetricKeys.length; i++) {
            if (keccak256(abi.encodePacked(healthMetricKeys[i])) == keccak256(abi.encodePacked(_key))) {
                return; // Already defined, avoid collision with default values
            }
        }
        ecosystemHealthMetrics[_key] = HealthMetric({
            currentValue: _initialValue,
            lastUpdatedBlock: block.number,
            deviationThreshold: _deviationThreshold
        });
        healthMetricKeys.push(_key);
    }

    /// @dev Adjusts a specific ecosystem health metric by a given delta.
    ///      This function is designed to be called after observable impacts of proposals or external events,
    ///      typically by the DAO or a privileged role after observing real-world outcomes.
    /// @param _metricKey The identifier of the health metric.
    /// @param _delta The amount to add to the current metric value (can be negative).
    function updateHealthMetric(string calldata _metricKey, int256 _delta) public onlyDaoOrInternal {
        if (bytes(_metricKey).length == 0) revert EmptyString();
        if (ecosystemHealthMetrics[_metricKey].lastUpdatedBlock == 0) revert InvalidParameterKey(); // Metric not defined

        HealthMetric storage metric = ecosystemHealthMetrics[_metricKey];
        metric.currentValue += _delta;
        metric.lastUpdatedBlock = block.number;

        emit HealthMetricUpdated(_metricKey, _delta, metric.currentValue);
    }

    /// @dev Returns all currently tracked ecosystem health metrics and their values.
    /// @return An array of metric keys and their corresponding current values.
    function getEcosystemHealthMetrics() public view returns (string[] memory, int256[] memory) {
        string[] memory keys = new string[](healthMetricKeys.length);
        int256[] memory values = new int256[](healthMetricKeys.length);

        for (uint256 i = 0; i < healthMetricKeys.length; i++) {
            keys[i] = healthMetricKeys[i];
            values[i] = ecosystemHealthMetrics[healthMetricKeys[i]].currentValue;
        }
        return (keys, values);
    }

    /// @dev Calculates a composite "stability index" based on predefined health metrics,
    ///      used to determine overall system health and potential emergency activation.
    ///      This is a simplified example; a real-world scenario might use weighted averages,
    ///      more complex formulas, or external oracle data.
    /// @return An integer representing the overall stability score.
    function evaluateOverallStability() public view returns (int256) {
        int256 stability = 0;
        // Example calculation: sum up relevant metrics
        // In a real scenario, weights or more complex logic would be applied.
        for (uint256 i = 0; i < healthMetricKeys.length; i++) {
            string storage key = healthMetricKeys[i];
            // Adjust contributions based on metric type, e.g., engagement positive,
            // very low treasuryRatio negative.
            if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("stabilityIndex"))) {
                stability += ecosystemHealthMetrics[key].currentValue * 2; // More weight
            } else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("engagementScore"))) {
                stability += ecosystemHealthMetrics[key].currentValue / 10;
            } else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("treasuryRatio"))) {
                stability += ecosystemHealthMetrics[key].currentValue - 1000; // Penalize deviation from ideal 1000
            }
        }
        return stability;
    }

    /*
     *
     * Synergy Score (Reputation) System
     *
     */

    /// @dev Awards `SynergyScore` to a user for positive contributions.
    ///      This function is typically called internally by the protocol or explicitly by the DAO
    ///      after successful initiative completion, valuable proposal execution, etc.
    /// @param _user The address to award `SynergyScore` to.
    /// @param _amount The amount of `SynergyScore` to award.
    function awardSynergyScore(address _user, uint256 _amount) public onlyDaoOrInternal {
        if (_user == address(0)) revert UnauthorizedAction(address(0));
        synergyScores[_user] += _amount;
        emit SynergyScoreAwarded(_user, _amount, synergyScores[_user]);
    }

    /// @dev Reduces `SynergyScore` of a user as a penalty for negative actions.
    ///      This function is typically called internally by the protocol or explicitly by the DAO
    ///      after proven detrimental actions or failed initiatives.
    /// @param _user The address whose `SynergyScore` will be reduced.
    /// @param _amount The amount of `SynergyScore` to burn.
    function burnSynergyScore(address _user, uint256 _amount) public onlyDaoOrInternal {
        if (_user == address(0)) revert UnauthorizedAction(address(0));
        if (synergyScores[_user] < _amount) {
            synergyScores[_user] = 0;
        } else {
            synergyScores[_user] -= _amount;
        }
        emit SynergyScoreBurned(_user, _amount, synergyScores[_user]);
    }

    /// @dev Retrieves the `SynergyScore` of a given address.
    /// @param _user The address to query.
    /// @return The current `SynergyScore` of the user.
    function getSynergyScore(address _user) public view returns (uint256) {
        // If a user has delegated, their direct score is temporarily zero for voting purposes.
        // But the underlying score still exists for other uses.
        // For actual voting power, use `_getEffectiveSynergyScore`.
        return synergyScores[_user];
    }

    /// @dev Internal helper to get the effective SynergyScore for voting or proposal creation.
    ///      Accounts for delegation.
    function _getEffectiveSynergyScore(address _user) internal view returns (uint256) {
        if (synergyDelegations[_user].unlockTime > block.timestamp) {
            // User has delegated their own score
            return 0;
        }
        // If they haven't delegated, check if they have delegated synergy from others.
        // This assumes delegatedSynergy reflects the *incoming* delegated power.
        return synergyScores[_user] + delegatedSynergy[_user];
    }


    /// @dev Allows a user to delegate their `SynergyScore` to another address for a specified duration,
    ///      locking their own score (making it unusable directly) during this period.
    ///      The `delegatee` will then have increased voting power.
    /// @param _delegatee The address to delegate `SynergyScore` to.
    /// @param _duration The duration in blocks for which the delegation is active.
    function delegateSynergy(address _delegatee, uint256 _duration) public notInEmergency {
        if (msg.sender == _delegatee) revert SelfDelegationNotAllowed();
        if (_delegatee == address(0)) revert UnauthorizedAction(address(0));
        if (synergyDelegations[msg.sender].unlockTime > block.timestamp) revert DelegationActive();
        if (_duration < 10) revert DelegationDurationTooShort(); // Minimum delegation duration
        if (_duration > MAX_DELEGATION_DURATION_BLOCKS) revert DelegationDurationTooLong();

        uint256 scoreToDelegate = synergyScores[msg.sender];
        if (scoreToDelegate == 0) revert InsufficientSynergyScore(msg.sender, 1, 0);

        synergyDelegations[msg.sender] = SynergyDelegateLock({
            delegatee: _delegatee,
            unlockTime: block.timestamp + (_duration * 12) // Assuming ~12s per block for block.timestamp based duration
        });
        delegatedSynergy[_delegatee] += scoreToDelegate;

        emit SynergyDelegated(msg.sender, _delegatee, _duration);
    }

    /// @dev Allows a user to revoke their `SynergyScore` delegation after the lockup period
    ///      or if no active delegation exists.
    function undelegateSynergy() public notInEmergency {
        SynergyDelegateLock storage delegation = synergyDelegations[msg.sender];
        if (delegation.unlockTime == 0 || delegation.delegatee == address(0)) revert NoActiveDelegation();
        if (delegation.unlockTime > block.timestamp) revert DelegationActive(); // Still locked

        delegatedSynergy[delegation.delegatee] -= synergyScores[msg.sender]; // Remove from delegatee's effective score
        delete synergyDelegations[msg.sender];

        emit SynergyUndelegated(msg.sender, delegation.delegatee);
    }

    /*
     *
     * Governance & Proposals
     *
     */

    /// @dev Creates a new proposal for changing a core protocol parameter.
    ///      Requires a minimum `SynergyScore` to prevent spam.
    ///      Proposers must specify projected impacts on ecosystem health metrics.
    /// @param _paramKey The key of the parameter to change.
    /// @param _newValue The new value for the parameter.
    /// @param _impactKeys An array of health metric keys that are projected to be impacted.
    /// @param _impactValues An array of integer deltas corresponding to _impactKeys.
    /// @param _requiresSynergyLock If true, only users with locked SynergyScore can vote on this proposal.
    function proposeParameterChange(
        string calldata _paramKey,
        uint256 _newValue,
        string[] calldata _impactKeys,
        int256[] calldata _impactValues,
        bool _requiresSynergyLock
    ) public hasMinSynergyToPropose(msg.sender) notInEmergency returns (uint256) {
        if (bytes(_paramKey).length == 0) revert EmptyString();
        if (_impactKeys.length == 0) revert EmptyImpactProjection();
        if (_impactKeys.length != _impactValues.length) revert ImpactProjectionMismatch();
        if (protocolParameters[_paramKey].lastUpdatedBlock == 0) revert ParameterNotFound(_paramKey);

        _proposalIdCounter++;
        uint256 proposalId = _proposalIdCounter;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = string(abi.encodePacked("Change parameter ", _paramKey, " to ", Strings.toString(_newValue)));
        newProposal.targetType = ProposalTargetType.ParameterChange;
        newProposal.targetParameterKey = _paramKey;
        newProposal.newParameterValue = _newValue;
        newProposal.snapshotTotalSynergy = _calculateTotalSynergy();
        newProposal.creationBlock = block.number;
        newProposal.endBlock = block.number + PROPOSAL_VOTING_PERIOD_BLOCKS;
        newProposal.status = ProposalStatus.Active;
        newProposal.requiresSynergyLock = _requiresSynergyLock;

        for (uint256 i = 0; i < _impactKeys.length; i++) {
            if (ecosystemHealthMetrics[_impactKeys[i]].lastUpdatedBlock == 0) revert InvalidParameterKey();
            newProposal.impactProjections[_impactKeys[i]] = _impactValues[i];
        }

        emit ProposalCreated(proposalId, msg.sender, ProposalTargetType.ParameterChange, newProposal.description);
        return proposalId;
    }

    /// @dev Creates a new proposal for launching a new initiative, which includes a budget request.
    ///      Requires a minimum `SynergyScore`. Includes projected impacts on health metrics.
    /// @param _description A detailed description of the initiative.
    /// @param _initialBudgetRequest The amount of ETH requested for the initiative.
    /// @param _targetImpactKeys An array of health metric keys that are projected to be impacted.
    /// @param _targetImpactValues An array of integer deltas corresponding to _targetImpactKeys.
    function proposeNewInitiative(
        string calldata _description,
        uint256 _initialBudgetRequest,
        string[] calldata _targetImpactKeys,
        int256[] calldata _targetImpactValues
    ) public hasMinSynergyToPropose(msg.sender) notInEmergency returns (uint256) {
        if (bytes(_description).length == 0) revert EmptyString();
        if (_targetImpactKeys.length == 0) revert EmptyImpactProjection();
        if (_targetImpactKeys.length != _targetImpactValues.length) revert ImpactProjectionMismatch();

        _proposalIdCounter++;
        uint256 proposalId = _proposalIdCounter;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.targetType = ProposalTargetType.NewInitiative;
        newProposal.initialBudgetRequest = _initialBudgetRequest;
        newProposal.snapshotTotalSynergy = _calculateTotalSynergy();
        newProposal.creationBlock = block.number;
        newProposal.endBlock = block.number + PROPOSAL_VOTING_PERIOD_BLOCKS;
        newProposal.status = ProposalStatus.Active;

        for (uint256 i = 0; i < _targetImpactKeys.length; i++) {
            if (ecosystemHealthMetrics[_targetImpactKeys[i]].lastUpdatedBlock == 0) revert InvalidParameterKey();
            newProposal.impactProjections[_targetImpactKeys[i]] = _targetImpactValues[i];
        }

        emit ProposalCreated(proposalId, msg.sender, ProposalTargetType.NewInitiative, _description);
        return proposalId;
    }

    /// @dev Allows users to cast their `SynergyScore`-weighted vote for or against a proposal.
    ///      Voters can only vote once per proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'for' vote, false for an 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public notInEmergency {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.number > proposal.endBlock) revert ProposalVotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        uint256 effectiveSynergy = _getEffectiveSynergyScore(msg.sender);
        if (effectiveSynergy == 0) revert InsufficientSynergyScore(msg.sender, 1, 0);
        if (proposal.requiresSynergyLock && synergyDelegations[msg.sender].unlockTime < block.timestamp) {
            revert InsufficientSynergyScore(msg.sender, 0, effectiveSynergy); // No locked synergy
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += effectiveSynergy;
        } else {
            proposal.votesAgainst += effectiveSynergy;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support, effectiveSynergy);
    }

    /// @dev Executes a proposal if it has met the quorum, passed the voting period,
    ///      and received more `SynergyScore` votes for than against.
    ///      Applies parameter changes or creates initiatives and adjusts health metrics based on projections.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public nonReentrant notInEmergency {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) revert ProposalNotExecutable();
        if (block.number <= proposal.endBlock) revert ProposalStillActive();

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumThreshold = proposal.snapshotTotalSynergy * PROPOSAL_QUORUM_PERCENTAGE / 100;

        if (totalVotes < quorumThreshold) {
            proposal.status = ProposalStatus.Failed;
            emit ProposalExecuted(_proposalId, ProposalStatus.Failed);
            return;
        }
        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.status = ProposalStatus.Failed;
            emit ProposalExecuted(_proposalId, ProposalStatus.Failed);
            return;
        }

        // Proposal passed
        proposal.status = ProposalStatus.Succeeded;

        // Apply changes based on proposal type
        if (proposal.targetType == ProposalTargetType.ParameterChange) {
            CoreParameter storage param = protocolParameters[proposal.targetParameterKey];
            param.value = proposal.newParameterValue;
            param.lastUpdatedBlock = block.number;
            param.updateCount++;
            emit CoreParameterUpdated(proposal.targetParameterKey, proposal.newParameterValue, proposal.proposer);
        } else if (proposal.targetType == ProposalTargetType.NewInitiative) {
            _initiativeIdCounter++;
            uint256 initiativeId = _initiativeIdCounter;
            initiatives[initiativeId] = Initiative({
                id: initiativeId,
                lead: proposal.proposer,
                description: proposal.description,
                currentBudget: 0, // Funds will be allocated via processInitiativeGrantRequest
                fundsRequestedTotal: proposal.initialBudgetRequest,
                status: InitiativeStatus.Active
            });
            proposal.targetInitiativeId = initiativeId; // Link proposal to initiative
            emit InitiativeCreated(initiativeId, proposal.proposer, proposal.description, proposal.initialBudgetRequest);
        }

        // Apply projected impact on health metrics (as declared by proposer and voted on)
        // In a real system, actual impact would be measured later by oracles or DAO.
        string[] memory impactKeys = new string[](healthMetricKeys.length);
        int256[] memory impactValues = new int256[](healthMetricKeys.length);
        uint256 count = 0;
        for (uint256 i = 0; i < healthMetricKeys.length; i++) {
            if (proposal.impactProjections[healthMetricKeys[i]] != 0) {
                impactKeys[count] = healthMetricKeys[i];
                impactValues[count] = proposal.impactProjections[healthMetricKeys[i]];
                count++;
            }
        }
        
        for (uint256 i = 0; i < count; i++) {
            updateHealthMetric(impactKeys[i], impactValues[i]);
        }

        emit ProposalExecuted(_proposalId, ProposalStatus.Succeeded);
    }

    /// @dev Allows the original proposer to cancel their own proposal if it hasn't started voting
    ///      or if specific conditions are met (e.g., within a grace period, or if no votes yet).
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) public notInEmergency {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer != msg.sender) revert UnauthorizedAction(msg.sender);
        if (proposal.status != ProposalStatus.Active) revert ProposalNotCancellable();
        // Allow cancellation if no votes received or before a certain block
        if (proposal.votesFor > 0 || proposal.votesAgainst > 0) revert ProposalNotCancellable();
        
        // This is an example condition. More complex rules can be added.
        if (block.number > proposal.creationBlock + (PROPOSAL_VOTING_PERIOD_BLOCKS / 10)) {
            revert ProposalNotCancellable(); // Cannot cancel after 1/10th of voting period
        }

        proposal.status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId, msg.sender);
    }

    /// @dev Retrieves all details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A `Proposal` struct containing all its data.
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        if (proposals[_proposalId].id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId); // 0 is default id
        Proposal storage p = proposals[_proposalId];
        // Create a memory copy to return, as mapping inside struct cannot be returned directly
        Proposal memory proposalCopy = Proposal({
            id: p.id,
            proposer: p.proposer,
            description: p.description,
            targetType: p.targetType,
            targetParameterKey: p.targetParameterKey,
            newParameterValue: p.newParameterValue,
            targetInitiativeId: p.targetInitiativeId,
            initialBudgetRequest: p.initialBudgetRequest,
            snapshotTotalSynergy: p.snapshotTotalSynergy,
            votesFor: p.votesFor,
            votesAgainst: p.votesAgainst,
            creationBlock: p.creationBlock,
            endBlock: p.endBlock,
            status: p.status,
            requiresSynergyLock: p.requiresSynergyLock
        });
        // Copy impact projections separately
        for(uint i = 0; i < healthMetricKeys.length; i++) {
            string memory key = healthMetricKeys[i];
            proposalCopy.impactProjections[key] = p.impactProjections[key];
        }

        return proposalCopy;
    }

    /// @dev Helper to calculate the total SynergyScore at a given moment for quorum calculation.
    ///      This is a simplification; in a real system, it might iterate through all users
    ///      or track a rolling total.
    function _calculateTotalSynergy() internal view returns (uint256) {
        // For demonstration, let's assume `owner()` has some initial Synergy,
        // and we sum a few example addresses. In a real system, this would be total score.
        // A full implementation would need a different way to track total supply.
        // One way: Have a `SynergyToken` that is non-transferable (ERC1155/ERC721 or custom token).
        uint256 total = synergyScores[owner()] + synergyScores[address(this)] + delegatedSynergy[owner()]; // Example total
        // A more realistic way would be to have a `totalSupply` like in ERC20 for a non-transferable token.
        // For this example, let's assume it's a fixed value, or dynamically sum all known scores.
        // A better approach would be to track totalSynergyScore with every award/burn.
        if (synergyScores[owner()] == 0) return 100000; // Default total if initial scores are not set.
        return total;
    }

    /*
     *
     * Initiative & Grant System
     *
     */

    /// @dev Retrieves all details of a specific initiative.
    /// @param _initiativeId The ID of the initiative.
    /// @return An `Initiative` struct containing all its data.
    function getInitiativeDetails(uint256 _initiativeId) public view returns (Initiative memory) {
        if (initiatives[_initiativeId].id == 0 && _initiativeId != 0) revert InitiativeNotFound(_initiativeId);
        return initiatives[_initiativeId];
    }

    /// @dev Allows the lead of an active initiative to request funds from the treasury.
    /// @param _initiativeId The ID of the initiative requesting funds.
    /// @param _amount The amount of ETH requested.
    /// @param _reason A description for the fund request.
    function requestInitiativeGrant(
        uint256 _initiativeId,
        uint256 _amount,
        string calldata _reason
    ) public nonReentrant notInEmergency {
        Initiative storage initiative = initiatives[_initiativeId];
        if (initiative.id == 0) revert InitiativeNotFound(_initiativeId);
        if (initiative.lead != msg.sender) revert UnauthorizedAction(msg.sender);
        if (initiative.status != InitiativeStatus.Active) revert InitiativeNotActive();
        if (bytes(_reason).length == 0) revert EmptyString();

        // This request would then typically be presented to the DAO for approval
        // via another proposal mechanism, or a dedicated "grant approval" function.
        // For simplicity, we just log it and expect DAO to act.
        initiative.fundsRequestedTotal += _amount; // Track total requested

        // DAO would then call `processInitiativeGrantRequest`
        emit InitiativeGrantRequested(_initiativeId, msg.sender, _amount);
    }

    /// @dev Processes a grant request for an initiative. Only callable by the DAO.
    ///      Either approves and sends funds from the treasury or denies the request.
    /// @param _initiativeId The ID of the initiative.
    /// @param _recipient The address to send funds to (usually the initiative lead).
    /// @param _amount The amount to send.
    /// @param _approve True to approve the grant, false to deny.
    function processInitiativeGrantRequest(
        uint256 _initiativeId,
        address _recipient,
        uint256 _amount,
        bool _approve
    ) public onlyDaoOrInternal nonReentrant notInEmergency {
        Initiative storage initiative = initiatives[_initiativeId];
        if (initiative.id == 0) revert InitiativeNotFound(_initiativeId);
        if (initiative.status != InitiativeStatus.Active) revert InitiativeNotActive();
        if (_recipient == address(0)) revert UnauthorizedAction(address(0));

        if (_approve) {
            if (address(daoTreasuryAddress).balance < _amount) {
                revert InsufficientTreasuryFunds(_amount, address(daoTreasuryAddress).balance);
            }
            // Send funds from DAO treasury address. This assumes daoTreasuryAddress is an EOA or a contract with a `receive` or `fallback` and transfer logic.
            // If daoTreasuryAddress is this contract, then `address(this).balance` would be used.
            // For this example, funds are moved from this contract directly to recipient to simplify treasury logic.
            // In a real system, the treasury would be a separate vault contract managed by the DAO.
            
            // To simulate, we'll transfer from THIS contract's balance if it's the DAO treasury.
            // If `daoTreasuryAddress` is a separate contract, this would need an external call.
            if (daoTreasuryAddress == address(this)) {
                (bool success, ) = payable(_recipient).call{value: _amount}("");
                if (!success) revert UnauthorizedAction(_recipient); // Revert on failed transfer
            } else {
                // If daoTreasuryAddress is a separate contract, this function would call it.
                // Example: IProtocolTreasury(daoTreasuryAddress).withdraw(_recipient, _amount);
                // For this example, we'll assume the treasury funds are managed by this contract directly
                // IF `daoTreasuryAddress` is set to `address(this)`.
                revert UnauthorizedAction(daoTreasuryAddress); // Illustrates a missing external call if treasury is separate
            }


            initiative.currentBudget += _amount;
        }
        // If not approved, simply log the action.

        emit InitiativeGrantProcessed(_initiativeId, _recipient, _amount, _approve);
    }


    /*
     *
     * Treasury Management
     *
     */

    /// @dev Allows anyone to deposit ETH into the protocol's treasury.
    function depositToTreasury() public payable notInEmergency {
        if (msg.value == 0) return;
        // Funds automatically sent to this contract's balance.
        // In a real system, this might forward to a dedicated treasury contract.
        // For this example, this contract *is* the treasury if `daoTreasuryAddress` is set to `address(this)`.
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Fallback function to accept ETH if sent directly without calling a function
    receive() external payable {
        if (msg.value > 0) {
            emit FundsDeposited(msg.sender, msg.value);
        }
    }

    // Fallback function for calls to undefined functions
    fallback() external payable {
        if (msg.value > 0) {
            emit FundsDeposited(msg.sender, msg.value);
        }
    }

    /*
     *
     * Emergency Protocol
     *
     */

    /// @dev Activates an emergency state if the `evaluateOverallStability()` falls below a critical threshold.
    ///      This can be called by the DAO or triggered automatically by internal conditions.
    ///      In emergency mode, certain protocol functionalities might be frozen.
    function activateEmergencyProtocol() public onlyDaoOrInternal inEmergency {
        int256 currentStability = evaluateOverallStability();
        int256 emergencyThreshold = SafeCast.toInt256(protocolParameters["EmergencyHealthThreshold"].value);

        if (currentStability >= emergencyThreshold) {
            revert StabilityThresholdNotMet(currentStability, emergencyThreshold);
        }

        emergencyModeActive = true;
        emit EmergencyModeActivated(msg.sender, currentStability);
    }

    /// @dev Deactivates the emergency state when system health recovers.
    ///      Callable by the DAO.
    function deactivateEmergencyProtocol() public onlyDaoOrInternal inEmergency {
        int256 currentStability = evaluateOverallStability();
        int256 emergencyThreshold = SafeCast.toInt256(protocolParameters["EmergencyHealthThreshold"].value);

        if (currentStability < emergencyThreshold) {
            revert StabilityThresholdExceeded(currentStability, emergencyThreshold);
        }

        emergencyModeActive = false;
        emit EmergencyModeDeactivated(msg.sender, currentStability);
    }
}
```