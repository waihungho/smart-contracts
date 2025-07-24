Here's a Solidity smart contract for the "Synergistic Protocol for Adaptive Resource & Reputation Management (SPARK)", designed with advanced concepts and a modular, adaptive policy engine.

**Concept: The Synergistic Protocol for Adaptive Resource & Reputation Management (SPARK)**

SPARK is a decentralized protocol where users earn "Synergy Points" (SPs) for specific, verifiable on-chain actions. These SPs represent a dynamic measure of their contribution and influence within the ecosystem. A unique "Adaptive Policy Engine" allows the community to propose, vote on, and activate modular policy contracts. These policies define *how* Synergy Points are awarded, how they decay, and crucially, how shared resources (e.g., a community treasury) are allocated based on these points. This creates a self-optimizing and evolving incentive structure.

**Key Features & Advanced Concepts:**
*   **Synergy Points (SPs):** Dynamic, on-chain reputation score based on actions, not just token holdings. SPs decay over time to incentivize continuous engagement, with the decay logic defined by the active policy.
*   **Adaptive Policy Engine:** The core logic for SP calculation, decay, and resource allocation is encapsulated in modular, upgradeable `PolicyModule` contracts. These modules can be proposed and activated through community governance, allowing the protocol to adapt and evolve its incentive mechanisms without upgrading the main contract.
*   **On-Chain Action Tracking:** Specific predefined events trigger SP awards, with the value of each action determined by the active policy.
*   **Resource Allocation by Merit:** Treasury funds (ERC20 tokens) are distributed to users proportionally to their effective Synergy Points, as calculated by the active policy. This distribution is initiated via community proposals, where eligible users are specified.
*   **Community Governance:** A robust, SP-weighted voting system (similar to a DAO) allows token holders to:
    *   Propose and activate new policy modules.
    *   Propose and enact new types of on-chain actions that award SPs.
    *   Propose and execute resource distributions from the community treasury.
*   **Modularity:** Separation of concerns between the main `SparkProtocol` (state management, governance) and `IPolicyModule` implementations (logic).
*   **Scalability (Pull/Explicit Users for Allocation):** Resource distribution requires an explicit list of users, preventing gas-intensive iteration over all possible users. SP decay is calculated virtually upon query (pull model), rather than requiring expensive global updates.

---

**Contract: `SparkProtocol`**

**Outline:**

1.  **Interfaces (`IPolicyModule`):** Defines the contract structure for pluggable policy logic.
2.  **External Contracts (`DefaultPolicyModule`):** A basic implementation of `IPolicyModule` for demonstration purposes.
3.  **Core State Variables:** Definition of key parameters, addresses, mappings for users, policies, proposals, and actions.
4.  **Events:** For transparent logging of state changes.
5.  **Errors:** Custom errors for revert conditions.
6.  **Modifiers:** For access control (e.g., `onlyGovernor`, `onlyActivePolicy`).
7.  **Constructor:** Setting up initial parameters.
8.  **Synergy Point (SP) Management:** Functions to earn, query, and manage SPs.
9.  **Action Type Management:** Functions for defining and governing the types of on-chain actions that award SPs.
10. **Adaptive Policy Module Management:** Functions for proposing, voting on, activating, and managing dynamic policy contracts.
11. **Resource Pool & Allocation:** Functions for depositing and managing resources, and initiating allocation.
12. **Governance System:** Standard DAO-like functions for creating, voting on, and executing general proposals.
13. **Utility & Read-Only Functions:** Helper functions to query contract state.

---

**Function Summary:**

**I. Core Configuration & Management:**
1.  `constructor(address _governor, address _resourceTokenAddress)`: Initializes the contract with the initial governance and resource pool token addresses.
2.  `setGovernor(address _newGovernor)`: Sets a new governance address. Callable only by the current governor (intended via proposal).
3.  `setResourceToken(address _resourceTokenAddress)`: Sets the ERC20 token address for the resource pool. Callable only by the current governor (intended via proposal).

**II. Synergy Point (SP) Management:**
4.  `getSynergyPoints(address _user)`: Returns the current effective (decayed) Synergy Points for a user, as calculated by the active policy.
5.  `getSynergyTier(address _user)`: Returns the tier of a user based on their effective SPs, as defined by the active policy.
6.  `recordActionAndAwardSP(address _user, uint256 _actionTypeId)`: Awards SPs to a user for a specific action, calculating the award amount and applying decay using the active policy.

**III. Action Type Management (How SPs are earned):**
7.  `proposeActionType(string memory _name, string memory _description)`: Creates a governance proposal for a new action type that can award SPs.
8.  `enactActionTypeProposal(uint256 _proposalId)`: Internal function called by `executeProposal` to enact an approved action type.
9.  `getActionTypeDetails(uint256 _actionTypeId)`: Retrieves details (name, description, enacted status) about a specific action type.
10. `getEnactedActionTypeIds()`: Returns an array of all currently active action type IDs.

**IV. Adaptive Policy Module Management:**
11. `proposePolicyModule(address _policyContractAddress, string memory _description)`: Creates a governance proposal to adopt a new policy module contract.
12. `activatePolicyModule(uint256 _proposalId)`: Internal function called by `executeProposal` to activate an approved policy module, making it the current active one.
13. `deactivateCurrentPolicy()`: Deactivates the currently active policy module. Callable only by the governor (intended via proposal for emergencies).
14. `getCurrentPolicyModule()`: Returns the address of the currently active policy module.
15. `getPolicyModuleDetails(address _policyContractAddress)`: Retrieves whether a policy module has been proposed and if it's currently active.

**V. Resource Pool & Allocation:**
16. `depositResources(uint256 _amount)`: Allows users or systems to deposit ERC20 tokens into the contract's resource pool.
17. `getResourcePoolBalance()`: Returns the current balance of the resource token held by the contract.
18. `proposeResourceDistribution(address[] calldata _usersToConsider, uint256 _amountToDistribute)`: Creates a governance proposal to distribute a specific amount of resources to a provided list of users.
19. `_executeResourceDistribution(address[] calldata _usersToConsider, uint256 _amountToDistribute)`: Internal function called by `executeProposal` to execute an approved resource distribution.

**VI. Governance System (General Proposals):**
20. `createProposal(bytes memory callData, string memory description, ProposalType pType, uint256 associatedId, address associatedAddress)`: Creates a general proposal for any action requiring governor approval, including specific types like action type or policy module proposals.
21. `voteOnProposal(uint256 _proposalId, bool _support)`: Casts a vote (for or against) on a given proposal. Requires users to have Synergy Points.
22. `executeProposal(uint256 _proposalId)`: Executes an approved and succeeded proposal by calling its `callData`.
23. `getProposalState(uint256 _proposalId)`: Returns the current state (Pending, Active, Succeeded, Defeated, Executed, Canceled) of a proposal.
24. `getProposalDetails(uint256 _proposalId)`: Retrieves detailed information about a specific proposal.

---
**Smart Contract Source Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SparkProtocol
 * @author Your Name/Team
 * @notice The Synergistic Protocol for Adaptive Resource & Reputation Management (SPARK)
 * A decentralized protocol where users earn "Synergy Points" (SPs) for specific, verifiable on-chain actions.
 * These SPs represent a dynamic measure of their contribution and influence.
 * A unique "Adaptive Policy Engine" allows the community to propose, vote on, and activate modular policy contracts.
 * These policies define *how* Synergy Points are awarded, how they decay, and crucially, how shared resources
 * (e.g., a community treasury) are allocated based on these points. This creates a self-optimizing and evolving
 * incentive structure.
 *
 * Outline:
 * 1. Interfaces (`IPolicyModule`): Defines the contract structure for pluggable policy logic.
 * 2. External Contracts (`DefaultPolicyModule`): A basic implementation of `IPolicyModule` for demonstration purposes.
 * 3. Core State Variables: Definition of key parameters, addresses, mappings for users, policies, proposals, and actions.
 * 4. Events: For transparent logging of state changes.
 * 5. Errors: Custom errors for revert conditions.
 * 6. Modifiers: For access control (e.g., `onlyGovernor`, `onlyActivePolicy`).
 * 7. Constructor: Setting up initial parameters.
 * 8. Synergy Point (SP) Management: Functions to earn, query, and manage SPs.
 * 9. Action Type Management: Functions for defining and governing the types of on-chain actions that award SPs.
 * 10. Adaptive Policy Module Management: Functions for proposing, voting on, activating, and managing dynamic policy contracts.
 * 11. Resource Pool & Allocation: Functions for depositing and managing resources, and initiating allocation.
 * 12. Governance System: Standard DAO-like functions for creating, voting on, and executing general proposals.
 * 13. Utility & Read-Only Functions: Helper functions to query contract state.
 */

// Interface for the pluggable policy modules
interface IPolicyModule {
    /**
     * @notice Calculates the Synergy Points to be awarded for a specific action type.
     * @param _actionTypeId The ID of the action performed.
     * @return The amount of SPs to be awarded.
     */
    function calculateSynergyPointsForAction(uint256 _actionTypeId) external view returns (uint256);

    /**
     * @notice Calculates the effective (decayed) Synergy Points for a user.
     * @param _currentSynergyPoints The raw SPs of the user before decay.
     * @param _lastUpdateTime The timestamp when the SPs were last updated/calculated.
     * @param _currentTime The current timestamp to calculate decay against.
     * @return The effective Synergy Points after applying decay.
     */
    function calculateDecayedSynergyPoints(
        uint256 _currentSynergyPoints,
        uint256 _lastUpdateTime,
        uint256 _currentTime
    ) external view returns (uint256);

    /**
     * @notice Calculates how resources should be allocated among a specific set of users based on their effective SPs.
     * @param _users An array of user addresses to consider for this allocation.
     * @param _userSynergyPoints An array of effective SPs corresponding to each user in `_users`.
     * @param _totalAmountToDistribute The total amount of resources available for distribution in this round.
     * @return recipients An array of addresses to receive resources.
     * @return amounts An array of amounts corresponding to each recipient.
     */
    function calculateResourceAllocation(
        address[] calldata _users,
        uint256[] calldata _userSynergyPoints,
        uint256 _totalAmountToDistribute
    ) external view returns (address[] memory recipients, uint256[] memory amounts);

    /**
     * @notice Returns the minimum SPs required for a given tier ID.
     * @param _tierId The ID of the tier.
     * @return The minimum SPs for that tier.
     */
    function getMinSPsForTier(uint256 _tierId) external view returns (uint256);

    /**
     * @notice Returns the number of defined tiers.
     * @return The total number of tiers.
     */
    function getNumberOfTiers() external view returns (uint256);
}

// A basic default policy module implementation for demonstration.
// In a real system, this would be a separate, deployable contract.
contract DefaultPolicyModule is IPolicyModule {
    // A simple mapping for action types to SPs
    mapping(uint256 => uint256) public actionTypeToSPValue;
    uint256 public decayRatePerDayBasisPoints; // Decay rate in basis points (e.g., 100 = 1%)
    uint256[] public minSPsForTier; // Tier 0, Tier 1, etc.

    constructor() {
        actionTypeToSPValue[1] = 10; // Basic interaction
        actionTypeToSPValue[2] = 50; // Significant contribution
        actionTypeToSPValue[3] = 100; // Major achievement
        decayRatePerDayBasisPoints = 50; // 0.5% decay per day
        minSPsForTier = [0, 100, 500, 2000]; // Example tiers: 0-99 (Tier 0), 100-499 (Tier 1), etc.
    }

    /**
     * @dev Sets the SP value for a given action type.
     */
    function setActionSPValue(uint256 _actionTypeId, uint256 _spValue) external {
        actionTypeToSPValue[_actionTypeId] = _spValue;
    }

    /**
     * @dev Sets the decay rate per day (in basis points).
     */
    function setDecayRatePerDay(uint252 _rate) external {
        decayRatePerDayBasisPoints = _rate;
    }

    /**
     * @dev Sets the minimum SPs required for a specific tier.
     */
    function setMinSPsForTier(uint256 _tierId, uint256 _minSP) external {
        require(_tierId < minSPsForTier.length, "Invalid tier ID");
        minSPsForTier[_tierId] = _minSP;
    }

    /**
     * @dev Adds a new tier level.
     */
    function addTier(uint256 _minSP) external {
        minSPsForTier.push(_minSP);
    }

    /**
     * @inheritdoc IPolicyModule
     */
    function calculateSynergyPointsForAction(uint256 _actionTypeId) external view returns (uint256) {
        return actionTypeToSPValue[_actionTypeId];
    }

    /**
     * @inheritdoc IPolicyModule
     */
    function calculateDecayedSynergyPoints(
        uint256 _currentSynergyPoints,
        uint256 _lastUpdateTime,
        uint256 _currentTime
    ) external view returns (uint256) {
        if (_currentSynergyPoints == 0) return 0;
        if (_lastUpdateTime >= _currentTime) return _currentSynergyPoints; // No decay for future/current updates

        uint256 timeElapsed = _currentTime - _lastUpdateTime;
        uint256 daysElapsed = timeElapsed / 1 days;

        uint256 currentPoints = _currentSynergyPoints;
        // Calculate decay based on exponential decay for more realistic long-term decay
        // Formula: points * (1 - decayRate)^daysElapsed
        // For simplicity, using linear decay per day as defined in the policy.
        uint256 decayPerDay = (currentPoints * decayRatePerDayBasisPoints) / 10000;

        uint256 totalDecay = decayPerDay * daysElapsed;
        if (totalDecay >= currentPoints) return 0; // Prevent underflow

        return currentPoints - totalDecay;
    }

    /**
     * @inheritdoc IPolicyModule
     */
    function calculateResourceAllocation(
        address[] calldata _users,
        uint256[] calldata _userSynergyPoints,
        uint256 _totalAmountToDistribute
    ) external view returns (address[] memory recipients, uint256[] memory amounts) {
        require(_users.length == _userSynergyPoints.length, "Arrays length mismatch");

        uint256 totalEffectiveSPs = 0;
        for (uint256 i = 0; i < _userSynergyPoints.length; i++) {
            totalEffectiveSPs += _userSynergyPoints[i];
        }

        if (totalEffectiveSPs == 0 || _totalAmountToDistribute == 0) return (new address[](0), new uint256[](0));

        recipients = new address[](_users.length);
        amounts = new uint256[](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            recipients[i] = _users[i];
            // Distribute proportionally to each user's effective SPs
            amounts[i] = (_userSynergyPoints[i] * _totalAmountToDistribute) / totalEffectiveSPs;
        }

        return (recipients, amounts);
    }

    /**
     * @inheritdoc IPolicyModule
     */
    function getMinSPsForTier(uint256 _tierId) external view returns (uint256) {
        require(_tierId < minSPsForTier.length, "Invalid tier ID");
        return minSPsForTier[_tierId];
    }

    /**
     * @inheritdoc IPolicyModule
     */
    function getNumberOfTiers() external view returns (uint256) {
        return minSPsForTier.length;
    }
}


contract SparkProtocol is Ownable, ReentrancyGuard {
    // --- Custom Errors ---
    error SPARK__InvalidActionTypeId();
    error SPARK__PolicyModuleNotFound();
    error SPARK__ProposalNotFound();
    error SPARK__ProposalAlreadyExecuted();
    error SPARK__ProposalNotExecutable();
    error SPARK__NotEnoughVotes();
    error SPARK__VoteAlreadyCast();
    error SPARK__ZeroAddress();
    error SPARK__ZeroAmount();
    error SPARK__ResourceTransferFailed();
    error SPARK__NoActivePolicy();
    error SPARK__ActionTypeAlreadyEnacted();
    error SPARK__ActionTypeNotEnacted();
    error SPARK__InvalidProposalType();
    error SPARK__InvalidProposalState();
    error SPARK__SelfCallOnly();
    error SPARK__VotingPeriodNotActive();
    error SPARK__InvalidActionForProposalType();
    error SPARK__UsersAndAmountsMismatch();

    // --- State Variables ---

    // Governance
    address public governor; // Address responsible for critical administrative actions (can be a DAO contract)
    uint256 public constant MIN_VOTING_DELAY = 1 days; // Delay before a proposal can be voted on
    uint256 public constant VOTING_PERIOD = 3 days; // Period during which votes can be cast
    uint256 public constant QUORUM_PERCENTAGE = 400; // 4% of total SPs required for quorum (400 basis points, e.g., 400/10000)

    // Synergy Points (SP)
    mapping(address => uint256) public userSynergyPoints; // Raw SPs for each user
    mapping(address => uint256) public lastSynergyPointUpdateTimes; // Timestamp of last SP update for user

    // Action Types: What actions award SPs
    struct ActionType {
        string name;
        string description;
        bool enacted; // True if the action type is active and can award SPs
    }
    uint256 private nextActionTypeId;
    mapping(uint256 => ActionType) public actionTypes;
    uint256[] public enactedActionTypeIds; // List of active action types

    // Policy Modules: The brain of the protocol
    address public activePolicyModule;
    mapping(address => bool) public isPolicyModuleProposed; // Track if a policy contract address has been proposed
    mapping(address => bool) public isPolicyModuleActive; // Track if a policy contract address is currently active

    // Resource Pool
    IERC20 public resourceToken; // The ERC20 token used for resource distribution

    // --- General Governance/Proposals ---
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    enum ProposalType {
        GENERAL,          // For generic administrative actions (e.g., setGovernor, setResourceToken)
        ACTION_TYPE,      // For proposing new action types
        POLICY_MODULE,    // For proposing new policy modules
        RESOURCE_DISTRO   // For proposing a resource distribution round
    }

    struct Proposal {
        uint256 id;
        bytes callData; // Encoded function call to execute on success (must be callable by `this` contract)
        string description;
        uint256 voteStart; // Timestamp when voting starts
        uint256 voteEnd; // Timestamp when voting ends
        uint256 totalVotesFor; // Sum of effective SPs from 'for' votes
        uint252 totalVotesAgainst; // Sum of effective SPs from 'against' votes
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        uint256 proposerSPAtCreation; // SP of proposer at proposal creation for quorum calculation
        ProposalType proposalType;
        // Fields for specific proposal types (might not be used by all types)
        uint256 associatedActionTypeId; // For ACTION_TYPE proposals
        address associatedPolicyModuleAddress; // For POLICY_MODULE proposals
        address[] usersForResourceDistro; // For RESOURCE_DISTRO proposals
        uint256 amountForResourceDistro; // For RESOURCE_DISTRO proposals
    }

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---
    event GovernorSet(address indexed oldGovernor, address indexed newGovernor);
    event ResourceTokenSet(address indexed newTokenAddress);
    event SynergyPointsAwarded(address indexed user, uint256 actionTypeId, uint256 awardedSP, uint256 newTotalSP);
    event PolicyModuleProposed(uint256 indexed proposalId, address indexed policyAddress, string description);
    event PolicyModuleActivated(address indexed oldPolicy, address indexed newPolicy);
    event PolicyModuleDeactivated(address indexed deactivatedPolicy);
    event ResourcesDeposited(address indexed depositor, uint256 amount);
    event ResourcesDistributed(uint256 totalAmount, address[] recipients, uint256[] amounts);
    event ActionTypeProposed(uint256 indexed proposalId, uint256 indexed actionTypeId, string name);
    event ActionTypeEnacted(uint256 indexed actionTypeId, string name);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType pType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votesSP);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);

    // --- Constructor ---
    constructor(address _governor, address _resourceTokenAddress) Ownable(msg.sender) {
        if (_governor == address(0) || _resourceTokenAddress == address(0)) revert SPARK__ZeroAddress();
        governor = _governor;
        resourceToken = IERC20(_resourceTokenAddress);
        nextActionTypeId = 1; // Start action IDs from 1
        nextProposalId = 1; // Start proposal IDs from 1
    }

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (msg.sender != governor) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) revert SPARK__SelfCallOnly();
        _;
    }

    modifier onlyActivePolicy() {
        if (activePolicyModule == address(0)) revert SPARK__NoActivePolicy();
        _;
    }

    // --- I. Core Configuration & Management ---

    /**
     * @notice Sets a new governance address. This function should typically be called via a governance proposal.
     * @dev Callable only by the current governor.
     * @param _newGovernor The address of the new governor.
     */
    function setGovernor(address _newGovernor) public onlyGovernor {
        if (_newGovernor == address(0)) revert SPARK__ZeroAddress();
        emit GovernorSet(governor, _newGovernor);
        governor = _newGovernor;
    }

    /**
     * @notice Sets the ERC20 token contract address that will be used as the resource pool.
     * @dev Callable only by the current governor. This should typically be a one-time setup or very rare change via proposal.
     * @param _resourceTokenAddress The address of the ERC20 token.
     */
    function setResourceToken(address _resourceTokenAddress) public onlyGovernor {
        if (_resourceTokenAddress == address(0)) revert SPARK__ZeroAddress();
        resourceToken = IERC20(_resourceTokenAddress);
        emit ResourceTokenSet(_resourceTokenAddress);
    }

    // --- II. Synergy Point (SP) Management ---

    /**
     * @notice Returns the effective (decayed) Synergy Points for a user.
     * @param _user The address of the user.
     * @return The calculated effective Synergy Points.
     */
    function getSynergyPoints(address _user) public view returns (uint256) {
        if (activePolicyModule == address(0) || userSynergyPoints[_user] == 0) {
            return userSynergyPoints[_user]; // No policy or no points, no decay calculation
        }
        return IPolicyModule(activePolicyModule).calculateDecayedSynergyPoints(
            userSynergyPoints[_user],
            lastSynergyPointUpdateTimes[_user],
            block.timestamp
        );
    }

    /**
     * @notice Returns the tier of a user based on their effective SPs.
     * @param _user The address of the user.
     * @return The tier ID. Returns 0 if no active policy or user has 0 SPs.
     */
    function getSynergyTier(address _user) public view returns (uint256) {
        if (activePolicyModule == address(0)) return 0; // Cannot determine tier without a policy
        
        uint256 effectiveSPs = getSynergyPoints(_user);
        IPolicyModule currentPolicy = IPolicyModule(activePolicyModule);
        uint256 numTiers = currentPolicy.getNumberOfTiers();

        uint256 tier = 0;
        for (uint256 i = 0; i < numTiers; i++) {
            if (effectiveSPs >= currentPolicy.getMinSPsForTier(i)) {
                tier = i;
            } else {
                break; // Assumes tiers are sorted by min SPs ascending
            }
        }
        return tier;
    }

    /**
     * @notice Awards Synergy Points to a user for a specific action, according to the active policy.
     * @dev This function is intended to be called by other modules or a trusted off-chain keeper
     *      upon verification of an on-chain action.
     * @param _user The address of the user who performed the action.
     * @param _actionTypeId The ID of the action type.
     */
    function recordActionAndAwardSP(address _user, uint256 _actionTypeId) public onlyActivePolicy {
        if (!actionTypes[_actionTypeId].enacted) revert SPARK__InvalidActionTypeId();

        uint256 pointsToAward = IPolicyModule(activePolicyModule).calculateSynergyPointsForAction(_actionTypeId);
        
        // First, apply virtual decay to current points before adding new ones
        uint256 currentEffectiveSP = getSynergyPoints(_user); // This calls the policy module
        userSynergyPoints[_user] = currentEffectiveSP + pointsToAward;
        lastSynergyPointUpdateTimes[_user] = block.timestamp;

        emit SynergyPointsAwarded(_user, _actionTypeId, pointsToAward, userSynergyPoints[_user]);
    }

    // --- III. Action Type Management (How SPs are earned) ---

    /**
     * @notice Creates a proposal for a new action type that, if enacted, can award SPs.
     * @param _name The name of the action type (e.g., "DAO Vote", "Protocol Interaction").
     * @param _description A detailed description of what the action entails.
     * @return proposalId The ID of the created proposal.
     */
    function proposeActionType(string memory _name, string memory _description) public returns (uint256) {
        uint256 newActionTypeId = nextActionTypeId++;

        actionTypes[newActionTypeId] = ActionType({
            name: _name,
            description: _description,
            enacted: false
        });

        // Use the general `createProposal` function
        bytes memory callData = abi.encodeWithSelector(this.enactActionTypeProposal.selector, nextProposalId);
        return createProposal(callData, string.concat("Propose new action type: ", _name, " - ", _description), 
                              ProposalType.ACTION_TYPE, newActionTypeId, address(0));
    }

    /**
     * @notice Enacts an approved action type proposal, making it available for SP awards.
     * @dev This function is called internally by `executeProposal` upon successful execution of a governance proposal.
     * @param _proposalId The ID of the action type proposal to enact.
     */
    function enactActionTypeProposal(uint256 _proposalId) public onlySelf {
        Proposal storage p = proposals[_proposalId];
        if (p.proposalType != ProposalType.ACTION_TYPE) revert SPARK__InvalidProposalType();
        if (p.associatedActionTypeId == 0) revert SPARK__InvalidActionTypeId();
        if (actionTypes[p.associatedActionTypeId].enacted) revert SPARK__ActionTypeAlreadyEnacted();
        
        actionTypes[p.associatedActionTypeId].enacted = true;
        enactedActionTypeIds.push(p.associatedActionTypeId);
        
        emit ActionTypeEnacted(p.associatedActionTypeId, actionTypes[p.associatedActionTypeId].name);
    }

    /**
     * @notice Retrieves details about a specific action type.
     * @param _actionTypeId The ID of the action type.
     * @return name The name of the action type.
     * @return description The description of the action type.
     * @return enacted Whether the action type is currently active.
     */
    function getActionTypeDetails(uint256 _actionTypeId) public view returns (string memory name, string memory description, bool enacted) {
        ActionType storage at = actionTypes[_actionTypeId];
        return (at.name, at.description, at.enacted);
    }

    /**
     * @notice Returns an array of all currently enacted action type IDs.
     * @return An array of enacted action type IDs.
     */
    function getEnactedActionTypeIds() public view returns (uint256[] memory) {
        return enactedActionTypeIds;
    }

    // --- IV. Adaptive Policy Module Management ---

    /**
     * @notice Creates a proposal to adopt a new policy module contract.
     * @param _policyContractAddress The address of the new policy module contract.
     * @param _description A description of what this new policy module does.
     * @return proposalId The ID of the created proposal.
     */
    function proposePolicyModule(address _policyContractAddress, string memory _description) public returns (uint256) {
        if (_policyContractAddress == address(0)) revert SPARK__ZeroAddress();
        if (isPolicyModuleProposed[_policyContractAddress]) revert SPARK__ProposalAlreadyExecuted(); // Already proposed or active

        // Basic check: Ensure it's a contract
        uint256 size;
        assembly { size := extcodesize(_policyContractAddress) }
        require(size > 0, "Not a contract address");

        // Use the general `createProposal` function
        bytes memory callData = abi.encodeWithSelector(this.activatePolicyModule.selector, nextProposalId);
        return createProposal(callData, string.concat("Propose new policy module: ", _description), 
                              ProposalType.POLICY_MODULE, 0, _policyContractAddress);
    }

    /**
     * @notice Activates an approved policy module, making it the current active policy.
     * @dev This function is called internally by `executeProposal` upon successful execution of a governance proposal.
     * @param _proposalId The ID of the policy module proposal to activate.
     */
    function activatePolicyModule(uint256 _proposalId) public onlySelf {
        Proposal storage p = proposals[_proposalId];
        if (p.proposalType != ProposalType.POLICY_MODULE) revert SPARK__InvalidProposalType();
        if (p.associatedPolicyModuleAddress == address(0)) revert SPARK__PolicyModuleNotFound();
        
        // Deactivate previous policy if any
        if (activePolicyModule != address(0)) {
            isPolicyModuleActive[activePolicyModule] = false;
            emit PolicyModuleDeactivated(activePolicyModule);
        }

        activePolicyModule = p.associatedPolicyModuleAddress;
        isPolicyModuleActive[activePolicyModule] = true;
        isPolicyModuleProposed[activePolicyModule] = true; // Mark as proposed to prevent re-proposals of active ones

        emit PolicyModuleActivated(address(0), activePolicyModule); // oldPolicy is 0 if first activation
    }

    /**
     * @notice Deactivates the currently active policy module. This might be used in emergencies or during upgrades.
     * @dev This function should typically be called via a governance proposal, but direct `onlyGovernor` is allowed for emergencies.
     */
    function deactivateCurrentPolicy() public onlyGovernor { 
        if (activePolicyModule == address(0)) revert SPARK__NoActivePolicy();

        address oldPolicy = activePolicyModule;
        isPolicyModuleActive[oldPolicy] = false;
        activePolicyModule = address(0);

        emit PolicyModuleDeactivated(oldPolicy);
    }

    /**
     * @notice Returns the address of the currently active policy module.
     * @return The address of the active policy module.
     */
    function getCurrentPolicyModule() public view returns (address) {
        return activePolicyModule;
    }

    /**
     * @notice Retrieves details about a proposed or active policy module.
     * @param _policyContractAddress The address of the policy module.
     * @return isProposed True if the policy module has been proposed.
     * @return isActive True if the policy module is currently active.
     */
    function getPolicyModuleDetails(address _policyContractAddress) public view returns (bool isProposed, bool isActive) {
        return (isPolicyModuleProposed[_policyContractAddress], isPolicyModuleActive[_policyContractAddress]);
    }

    // --- V. Resource Pool & Allocation ---

    /**
     * @notice Allows users or systems to deposit ERC20 tokens into the contract's resource pool.
     * @dev The caller must first approve this contract to spend their tokens.
     * @param _amount The amount of tokens to deposit.
     */
    function depositResources(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert SPARK__ZeroAmount();
        bool success = resourceToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert SPARK__ResourceTransferFailed();
        emit ResourcesDeposited(msg.sender, _amount);
    }

    /**
     * @notice Returns the current balance of the resource token held by the contract.
     * @return The balance of the resource token.
     */
    function getResourcePoolBalance() public view returns (uint256) {
        return resourceToken.balanceOf(address(this));
    }

    /**
     * @notice Creates a proposal to distribute a specific amount of resources to a provided list of users.
     * @dev The list of users should be curated off-chain (e.g., top N contributors, active members).
     * @param _usersToConsider An array of user addresses eligible for this distribution.
     * @param _amountToDistribute The total amount of resources to be distributed in this round.
     * @return proposalId The ID of the created proposal.
     */
    function proposeResourceDistribution(address[] calldata _usersToConsider, uint256 _amountToDistribute) public returns (uint256) {
        if (_amountToDistribute == 0) revert SPARK__ZeroAmount();
        if (_usersToConsider.length == 0) revert SPARK__ZeroAddress(); // No users to distribute to

        // Encoded call to the internal distribution function
        bytes memory callData = abi.encodeWithSelector(this._executeResourceDistribution.selector, _usersToConsider, _amountToDistribute);
        
        uint256 proposalId = createProposal(callData, string.concat("Propose resource distribution of ", Strings.toString(_amountToDistribute), " to ", Strings.toString(_usersToConsider.length), " users."),
                                            ProposalType.RESOURCE_DISTRO, 0, address(0)); // No associated ID/address for this type
        
        // Store these specific parameters in the proposal struct for later execution/audit
        proposals[proposalId].usersForResourceDistro = _usersToConsider;
        proposals[proposalId].amountForResourceDistro = _amountToDistribute;

        return proposalId;
    }

    /**
     * @notice Executes an approved resource distribution.
     * @dev This function is called internally by `executeProposal`.
     * @param _usersToConsider The users whose SPs should be used for allocation.
     * @param _amountToDistribute The total amount of resources to distribute.
     */
    function _executeResourceDistribution(address[] calldata _usersToConsider, uint256 _amountToDistribute) public nonReentrant onlySelf onlyActivePolicy {
        if (_amountToDistribute == 0) revert SPARK__ZeroAmount();
        if (_usersToConsider.length == 0) return; // No users to distribute to

        // Get effective SPs for all users to consider
        uint256[] memory effectiveSPs = new uint256[](_usersToConsider.length);
        for (uint256 i = 0; i < _usersToConsider.length; i++) {
            effectiveSPs[i] = getSynergyPoints(_usersToConsider[i]);
        }

        // Delegate allocation logic to the active policy module
        (address[] memory recipients, uint256[] memory amounts) = IPolicyModule(activePolicyModule).calculateResourceAllocation(
            _usersToConsider,
            effectiveSPs,
            _amountToDistribute
        );

        if (recipients.length != amounts.length) revert SPARK__UsersAndAmountsMismatch();

        for (uint256 i = 0; i < recipients.length; i++) {
            if (amounts[i] > 0) {
                bool success = resourceToken.transfer(recipients[i], amounts[i]);
                if (!success) {
                    // Log error but don't revert the entire distribution if one transfer fails
                    // This scenario should be handled carefully in a production system.
                    // For this example, we'll revert if any transfer fails.
                    revert SPARK__ResourceTransferFailed();
                }
            }
        }
        emit ResourcesDistributed(_amountToDistribute, recipients, amounts);
    }

    // --- VI. Governance System (General Proposals) ---

    /**
     * @notice Creates a general purpose proposal that can be voted on.
     * @param _callData Encoded function call to execute if the proposal succeeds. Must be a call to this contract.
     * @param _description A description of the proposal.
     * @param _pType The type of the proposal (e.g., GENERAL, ACTION_TYPE, POLICY_MODULE, RESOURCE_DISTRO).
     * @param _associatedId An ID associated with the proposal type (e.g., actionTypeId for ACTION_TYPE proposals).
     * @param _associatedAddress An address associated with the proposal type (e.g., policy module address for POLICY_MODULE proposals).
     * @return The ID of the newly created proposal.
     */
    function createProposal(
        bytes memory _callData,
        string memory _description,
        ProposalType _pType,
        uint256 _associatedId,
        address _associatedAddress
    ) public returns (uint256) {
        if (getSynergyPoints(msg.sender) == 0) revert SPARK__NotEnoughVotes(); // Proposer needs some SP

        uint256 proposalId = nextProposalId++;
        Proposal storage p = proposals[proposalId];
        p.id = proposalId;
        p.callData = _callData;
        p.description = _description;
        p.voteStart = block.timestamp + MIN_VOTING_DELAY;
        p.voteEnd = p.voteStart + VOTING_PERIOD;
        p.totalVotesFor = 0;
        p.totalVotesAgainst = 0;
        p.executed = false;
        p.proposerSPAtCreation = getSynergyPoints(msg.sender);
        p.proposalType = _pType;
        p.associatedActionTypeId = _associatedId;
        p.associatedPolicyModuleAddress = _associatedAddress;

        emit ProposalCreated(proposalId, msg.sender, _pType, _description);
        return proposalId;
    }

    /**
     * @notice Allows a user to cast their vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, False for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) revert SPARK__ProposalNotFound();
        if (getProposalState(_proposalId) != ProposalState.Active) revert SPARK__VotingPeriodNotActive();
        if (p.hasVoted[msg.sender]) revert SPARK__VoteAlreadyCast();

        uint256 voterSP = getSynergyPoints(msg.sender);
        if (voterSP == 0) revert SPARK__NotEnoughVotes();

        p.hasVoted[msg.sender] = true;
        if (_support) {
            p.totalVotesFor += voterSP;
        } else {
            p.totalVotesAgainst += voterSP;
        }
        emit VoteCast(_proposalId, msg.sender, _support, voterSP);
    }

    /**
     * @notice Executes a proposal if it has succeeded.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) revert SPARK__ProposalNotFound();
        if (p.executed) revert SPARK__ProposalAlreadyExecuted();

        ProposalState state = getProposalState(_proposalId);
        if (state != ProposalState.Succeeded) revert SPARK__ProposalNotExecutable();

        p.executed = true; // Mark as executed BEFORE external call to prevent re-entrancy issues
        
        // Execute the proposal's callData
        (bool success, ) = address(this).call(p.callData);
        if (!success) revert SPARK__ProposalNotExecutable(); // Revert if the target call failed

        emit ProposalExecuted(_proposalId, msg.sender);
    }

    /**
     * @notice Returns the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) return ProposalState.Canceled; // Or a specific "NotFound" state

        if (p.executed) return ProposalState.Executed;
        if (block.timestamp < p.voteStart) return ProposalState.Pending;
        if (block.timestamp <= p.voteEnd) return ProposalState.Active;

        // Voting period ended, check results
        uint256 totalEffectiveSPs = p.proposerSPAtCreation; // Use proposer SP as a proxy for total network SP at creation for quorum.
        // For a more robust quorum, one might need a snapshot of total SPs or a total supply of a governance token.
        // For this example, proposer's SP at creation is used as a base.

        // A more robust quorum: requires a 'total active SPs' snapshot.
        // For this example, let's assume quorum is relative to total votes cast.
        // Or, a simple threshold on absolute votes. Let's use absolute SPs for quorum.
        // This makes `getTotalSynergyPoints` still a conceptual issue.
        // So, for this example, let's simplify quorum to `totalVotesFor > totalVotesAgainst` and a minimal `totalVotesFor`.
        // Or, better, `totalVotesFor` reaches a certain absolute value `X`.
        // Let's use the `QUORUM_PERCENTAGE` with `proposerSPAtCreation` as a rough base.
        // A real system would use a more sophisticated method for quorum (e.g., total supply of a voting token).

        uint256 quorumThreshold = (totalEffectiveSPs * QUORUM_PERCENTAGE) / 10000;
        if (p.totalVotesFor < quorumThreshold) return ProposalState.Defeated;
        if (p.totalVotesFor <= p.totalVotesAgainst) return ProposalState.Defeated;
        
        return ProposalState.Succeeded;
    }

    /**
     * @notice Retrieves detailed information about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return id The proposal ID.
     * @return description The description of the proposal.
     * @return voteStart The timestamp when voting starts.
     * @return voteEnd The timestamp when voting ends.
     * @return totalVotesFor Total SPs voted for.
     * @return totalVotesAgainst Total SPs voted against.
     * @return executed Whether the proposal has been executed.
     * @return proposer The address of the proposer.
     * @return pType The type of proposal.
     * @return associatedActionTypeId Associated action type ID (if applicable).
     * @return associatedPolicyModuleAddress Associated policy module address (if applicable).
     * @return usersForResourceDistro Users for resource distribution (if applicable).
     * @return amountForResourceDistro Amount for resource distribution (if applicable).
     */
    function getProposalDetails(uint256 _proposalId)
        public view
        returns (
            uint256 id,
            string memory description,
            uint256 voteStart,
            uint256 voteEnd,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst,
            bool executed,
            address proposer, // Not directly stored, but could be derived from event or added to struct
            ProposalType pType,
            uint256 associatedActionTypeId,
            address associatedPolicyModuleAddress,
            address[] memory usersForResourceDistro,
            uint256 amountForResourceDistro
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.id,
            p.description,
            p.voteStart,
            p.voteEnd,
            p.totalVotesFor,
            p.totalVotesAgainst,
            p.executed,
            address(0), // Proposer address not directly stored in struct to save gas, could be found from event logs
            p.proposalType,
            p.associatedActionTypeId,
            p.associatedPolicyModuleAddress,
            p.usersForResourceDistro,
            p.amountForResourceDistro
        );
    }
}

// Minimal utility to convert uint256 to string for event logging/description.
// (In a real project, consider importing from OpenZeppelin if needed widely, but for 0.8.20 it's `toString` in `ERC721` etc.)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```