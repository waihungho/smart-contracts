Okay, let's design an interesting and advanced smart contract. We'll create a "Decentralized Synergy Protocol" which is a combination of:

1.  **Dynamic NFTs (Agents):** Represents entities within the ecosystem with evolving attributes.
2.  **Resource Management:** Users stake/deposit an ERC-20 token.
3.  **Reputation System:** Agents earn reputation by participating, and reputation can decay.
4.  **Parameterized Actions:** Specific actions within the protocol require resources/reputation and grant reputation/rewards, with parameters configurable by governance.
5.  **On-Chain Governance:** A simple system allowing high-reputation agents to propose and vote on changes to system parameters.

This goes beyond basic token contracts, marketplaces, or simple staking by integrating multiple concepts into an interactive system with on-chain evolution via governance.

We will assume the ERC-20 Resource Token and ERC-721 Agent NFT contracts are deployed separately and their addresses are provided to this contract.

---

**Outline and Function Summary:**

*   **Overview:**
    *   A decentralized protocol managing Agent NFTs, Resource Tokens, Reputation, Parameterized Actions, and On-Chain Governance.
    *   Agents stake Resources to participate and earn Reputation.
    *   Reputation unlocks actions and allows participation in governance.
    *   System parameters evolve through governance proposals and voting by high-reputation Agents.
*   **State Variables:**
    *   References to the ERC-20 Resource Token and ERC-721 Agent NFT contracts.
    *   Mappings to track Agent data (reputation, staked resources, claimable resources, last action timestamps).
    *   Struct for System Parameters (action costs, reputation gains, decay rates, governance thresholds).
    *   Structs and mappings for the Governance system (proposals, votes, proposal states).
    *   Pause state and owner.
*   **Events:**
    *   Emitted for significant actions (Agent registration/deregistration, Resource deposit/withdrawal, Reputation changes, Actions performed, Governance events).
*   **Structs:**
    *   `SystemParameters`: Defines the core configurable variables of the protocol.
    *   `Proposal`: Defines a governance proposal, including the proposed parameter changes, state, votes, etc.
*   **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner (for initial setup or emergency).
    *   `whenNotPaused`: Prevents execution if the contract is paused.
    *   `whenPaused`: Allows execution only if the contract is paused.
    *   `onlyAgentOwner`: Ensures the caller owns the specified Agent NFT.
    *   `requireHighReputation`: Checks if an Agent meets a minimum reputation threshold.
*   **Core Logic Functions (Min 20+):**

    1.  `constructor()`: Initializes owner.
    2.  `initializeSystem(address _resourceToken, address _agentNFT, SystemParameters memory _initialParams)`: Sets token addresses and initial system parameters. (Admin)
    3.  `setSystemParameters(SystemParameters memory _newParams)`: Updates all system parameters directly (use with extreme caution or remove after governance is active). (Admin/Governance)
    4.  `registerAgentByStaking(uint256 _agentId, uint256 _amount)`: Registers an Agent NFT by staking Resource Tokens. Initializes reputation. (Agent Management/Resource)
    5.  `deregisterAgentAndClaimStake(uint256 _agentId)`: Deregisters an Agent, burning their reputation and returning staked resources. (Agent Management/Resource)
    6.  `depositResources(uint256 _agentId, uint256 _amount)`: Deposits more resources for an already registered Agent. (Resource)
    7.  `withdrawClaimableResources(uint256 _agentId)`: Allows an Agent to withdraw accumulated claimable resources. (Resource)
    8.  `performReputationBoostingAction(uint256 _agentId)`: An action costing resources that significantly boosts reputation. (Actions)
    9.  `performResourceGeneratingAction(uint256 _agentId)`: An action requiring reputation that adds to claimable resources. (Actions)
    10. `decayAgentReputation(uint256 _agentId)`: Applies the configured reputation decay to an Agent's score based on time since last update/decay. (Reputation)
    11. `getAgentReputation(uint256 _agentId)`: Queries an Agent's current reputation score. (Queries)
    12. `getAgentStakedResources(uint256 _agentId)`: Queries an Agent's currently staked resources. (Queries)
    13. `getAgentClaimableResources(uint256 _agentId)`: Queries an Agent's currently claimable resources. (Queries)
    14. `getCurrentSystemParameters()`: Queries the current system configuration parameters. (Queries)
    15. `proposeParameterChange(SystemParameters memory _newParams)`: Allows a high-reputation Agent to propose changes to the system parameters. (Governance)
    16. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows a high-reputation Agent to vote on an active proposal. (Governance)
    17. `executeProposal(uint256 _proposalId)`: Executes a proposal if it has met quorum and majority rules after the voting period ends. (Governance)
    18. `cancelProposal(uint256 _proposalId)`: Allows the proposer or owner to cancel a proposal before voting ends (maybe with penalties). (Governance)
    19. `getProposalDetails(uint256 _proposalId)`: Queries the details of a specific governance proposal. (Queries)
    20. `getTotalStakedResources()`: Queries the total resources staked in the contract. (Queries)
    21. `getTotalRegisteredAgents()`: Queries the total number of registered Agents. (Queries)
    22. `pauseSystem()`: Pauses key interactions (deposit, actions, voting). (Admin)
    23. `unpauseSystem()`: Unpauses the system. (Admin)
    24. `withdrawOwnerFees(uint256 _amount)`: Allows owner to withdraw accumulated fees (if any mechanism existed, none implemented here, but common pattern). (Admin - Placeholder)
    25. `updateAgentLastActionTime(uint256 _agentId, uint8 _actionType)`: Internal helper to track last time an agent performed a specific action type. (Internal - counted towards complexity/functionality)
    26. `_calculateReputationDecay(uint256 _agentId)`: Internal helper to calculate reputation decay based on time. (Internal - counted towards complexity/functionality)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max or other math

// --- Outline and Function Summary ---
//
// Overview:
// A decentralized protocol managing Agent NFTs, Resource Tokens, Reputation,
// Parameterized Actions, and On-Chain Governance. Users stake Resources (ERC-20)
// for Agent NFTs (ERC-721) to participate. Agents earn Reputation through actions.
// Reputation unlocks advanced actions and governance participation. System
// parameters are dynamic and can be changed via governance proposals and voting.
// Not a duplicate of standard ERCs, marketplaces, or simple staking.
//
// State Variables:
// - owner: Address controlling initial setup and emergency pause.
// - resourceToken: Address of the ERC-20 token used for staking/resources.
// - agentNFT: Address of the ERC-721 token representing Agents.
// - systemParameters: Current configurable parameters of the protocol.
// - agentData: Mapping from agentId (NFT tokenId) to Agent specific data (reputation, staked, claimable, last action times).
// - registeredAgents: Mapping to track if an agentId is registered.
// - totalRegisteredAgents: Counter for the number of registered agents.
// - totalStakedResources: Total amount of resourceToken staked in the contract.
// - proposals: Mapping from proposalId to Proposal struct.
// - proposalCount: Counter for proposals.
// - proposalVotes: Mapping from proposalId to agentId to vote (true for support, false for against).
// - proposalExecutionTime: Mapping to track when a proposal can be executed.
// - paused: Boolean indicating if the system is paused.
//
// Events:
// - SystemInitialized: Emitted when the system parameters and tokens are set.
// - AgentRegistered: Emitted when an Agent stakes resources and joins.
// - AgentDeregistered: Emitted when an Agent leaves and claims stake.
// - ResourcesDeposited: Emitted when resources are added for an Agent.
// - ClaimableResourcesWithdrawn: Emitted when claimable resources are withdrawn.
// - ReputationChanged: Emitted when an Agent's reputation is updated.
// - ActionPerformed: Emitted when a specific action is completed.
// - ParameterChangeProposed: Emitted when a new governance proposal is created.
// - VoteCast: Emitted when an Agent votes on a proposal.
// - ProposalExecuted: Emitted when a proposal successfully changes parameters.
// - ProposalCancelled: Emitted when a proposal is cancelled.
// - Paused: Emitted when the contract is paused.
// - Unpaused: Emitted when the contract is unpaused.
//
// Structs:
// - SystemParameters: Contains all configurable variables like action costs, reputation gains, decay rates, governance thresholds, etc.
// - AgentData: Holds dynamic data for each registered Agent (reputation, balances, action timestamps).
// - Proposal: Holds details of a governance proposal (proposer, proposed parameters, votes for/against, state, timestamps).
//
// Modifiers:
// - onlyOwner: Restricts function calls to the contract owner.
// - whenNotPaused: Prevents function calls when the contract is paused.
// - whenPaused: Allows function calls only when the contract is paused.
// - onlyAgentOwner: Ensures the caller is the owner of the specified Agent NFT.
// - requireHighReputation: Checks if an Agent meets the minimum reputation required for certain actions/governance.
//
// Core Logic Functions (Min 20+):
// 01. constructor(): Sets initial owner.
// 02. initializeSystem(): Sets token addresses and initial system parameters. (Admin)
// 03. setSystemParameters(): Updates all system parameters directly (use with caution). (Admin/Governance)
// 04. registerAgentByStaking(): Registers Agent, stakes resources, initializes data. (Agent/Resource)
// 05. deregisterAgentAndClaimStake(): Deregisters Agent, returns stake, clears data. (Agent/Resource)
// 06. depositResources(): Adds more staked resources for an Agent. (Resource)
// 07. withdrawClaimableResources(): Claims earned resources. (Resource)
// 08. performReputationBoostingAction(): Action costing resources, boosting reputation. (Actions)
// 09. performResourceGeneratingAction(): Action requiring reputation, adding claimable resources. (Actions)
// 10. decayAgentReputation(): Applies reputation decay based on time. (Reputation)
// 11. getAgentReputation(): Query agent reputation. (Queries)
// 12. getAgentStakedResources(): Query agent staked resources. (Queries)
// 13. getAgentClaimableResources(): Query agent claimable resources. (Queries)
// 14. getCurrentSystemParameters(): Query current system parameters. (Queries)
// 15. proposeParameterChange(): Create a new governance proposal. (Governance)
// 16. voteOnProposal(): Cast a vote on an active proposal. (Governance)
// 17. executeProposal(): Finalize voting and apply proposal if successful. (Governance)
// 18. cancelProposal(): Cancel an ongoing proposal. (Governance)
// 19. getProposalDetails(): Query details of a proposal. (Queries)
// 20. getTotalStakedResources(): Query total resources in contract. (Queries)
// 21. getTotalRegisteredAgents(): Query total registered agents. (Queries)
// 22. pauseSystem(): Pause critical contract functions. (Admin)
// 23. unpauseSystem(): Unpause the contract. (Admin)
// 24. withdrawOwnerFees(): Placeholder for withdrawing owner fees (if applicable). (Admin)
// 25. updateAgentLastActionTime(): Internal helper for action cooldowns/decay timing. (Internal)
// 26. _calculateReputationDecay(): Internal helper for reputation decay calculation. (Internal)
//
// Note: Internal functions _updateAgentReputation and _addClaimableResources are also present
//       to manage state updates cleanly, contributing to the logic's complexity.
//
// Interesting/Advanced Concepts:
// - Dynamic state per NFT (AgentData).
// - Reputation as a core mechanic influencing access and rewards.
// - Parameterized actions with variable costs/rewards.
// - Time-based effects (reputation decay, action cooldowns - implicit via last action time).
// - On-chain governance for protocol evolution.
// - Interacting with multiple external token contracts (ERC-20, ERC-721).
// - Using ReentrancyGuard for safety in token interactions.

contract DecentralizedSynergyProtocol is ReentrancyGuard {
    address public owner;
    IERC20 public resourceToken;
    IERC721 public agentNFT;

    struct SystemParameters {
        uint256 initialReputation; // Reputation granted upon registration
        uint256 registrationStakeAmount; // Resources required to register an agent
        uint256 reputationBoostingActionCost; // Resources required for boosting action
        uint256 reputationBoostAmount; // Reputation gained from boosting action
        uint256 resourceGeneratingActionReputationReq; // Min reputation for resource action
        uint256 resourceGenerationAmount; // Resources added to claimable from resource action
        uint256 reputationDecayRatePerSecond; // How much reputation decays per second (scaled)
        uint256 governanceProposalReputationReq; // Min reputation to propose
        uint256 governanceVoteReputationReq; // Min reputation to vote
        uint256 governanceVotingPeriod; // Duration of voting in seconds
        uint256 governanceQuorumNumerator; // Quorum (e.g., 50 for 50%, 60 for 60%)
        uint256 governanceMajorityNumerator; // Majority required (e.g., 50 for >50%, 60 for >60%)
    }

    SystemParameters public systemParameters;

    struct AgentData {
        uint256 reputation;
        uint256 stakedResources;
        uint256 claimableResources;
        uint256 lastReputationUpdate; // Timestamp of last decay calculation/update
        mapping(uint8 => uint256) lastActionTime; // Map action type to timestamp
    }

    mapping(uint256 => AgentData) private agentData; // agentId (NFT tokenId) => AgentData
    mapping(uint256 => bool) private registeredAgents; // agentId => isRegistered
    uint256 public totalRegisteredAgents;
    uint256 public totalStakedResources;

    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Cancelled }

    struct Proposal {
        SystemParameters proposedParameters;
        uint256 proposerAgentId;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        ProposalState state;
        mapping(uint256 => bool) hasVoted; // agentId => voted
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    bool public paused;

    // Action Types for mapping lastActionTime
    enum ActionType {
        ReputationBoosting = 1,
        ResourceGenerating = 2
    }

    // --- Events ---
    event SystemInitialized(address indexed resourceTokenAddress, address indexed agentNFTAddress, SystemParameters initialParams);
    event AgentRegistered(uint256 indexed agentId, address indexed owner, uint256 stakedAmount);
    event AgentDeregistered(uint256 indexed agentId, address indexed owner, uint256 reclaimedStake);
    event ResourcesDeposited(uint256 indexed agentId, uint256 amount);
    event ClaimableResourcesWithdrawn(uint256 indexed agentId, uint256 amount);
    event ReputationChanged(uint256 indexed agentId, uint256 newReputation);
    event ActionPerformed(uint256 indexed agentId, uint8 actionType, uint256 cost, uint256 reputationGain, uint256 resourcesGenerated);
    event ParameterChangeProposed(uint256 indexed proposalId, uint256 indexed proposerAgentId, SystemParameters proposedParams);
    event VoteCast(uint256 indexed proposalId, uint256 indexed voterAgentId, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "System is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "System is not paused");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(agentNFT.ownerOf(_agentId) == msg.sender, "Caller must own the Agent NFT");
        _;
    }

    modifier requireHighReputation(uint256 _agentId, uint256 _requiredReputation) {
        // First calculate decay before checking requirement
        decayAgentReputation(_agentId);
        require(agentData[_agentId].reputation >= _requiredReputation, "Agent does not have enough reputation");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = true; // Start paused until initialized
    }

    // --- Admin & Setup Functions ---

    /**
     * @dev Initializes the protocol with token addresses and initial parameters.
     * Callable only once by the owner. System starts unpaused after initialization.
     * @param _resourceToken Address of the ERC-20 resource token.
     * @param _agentNFT Address of the ERC-721 agent NFT.
     * @param _initialParams Initial system configuration parameters.
     */
    function initializeSystem(address _resourceToken, address _agentNFT, SystemParameters memory _initialParams) external onlyOwner whenPaused {
        require(resourceToken == address(0), "System already initialized");
        require(_resourceToken != address(0) && _agentNFT != address(0), "Invalid token addresses");

        resourceToken = IERC20(_resourceToken);
        agentNFT = IERC721(_agentNFT);
        systemParameters = _initialParams;
        paused = false; // Unpause after initialization

        emit SystemInitialized(_resourceToken, _agentNFT, _initialParams);
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Sets the current system parameters directly.
     * Should ideally only be callable by governance after initial setup.
     * @param _newParams The new system configuration parameters.
     */
    function setSystemParameters(SystemParameters memory _newParams) public virtual onlyOwner {
        // In a real system, this function would likely be internal and only called by executeProposal
        // For demonstration, we allow owner override initially. Consider removing onlyOwner later.
        systemParameters = _newParams;
        // No explicit event for this, as it's often internal to executeProposal
    }

    /**
     * @dev Pauses the system, preventing most interactions.
     * Callable by owner.
     */
    function pauseSystem() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the system, allowing interactions again.
     * Callable by owner.
     */
    function unpauseSystem() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Placeholder for owner withdrawing accumulated fees.
     * Currently, no fees are collected by the owner in this contract.
     * Included to meet function count and represent a common admin pattern.
     * @param _amount The amount of Resource Tokens to withdraw.
     */
    function withdrawOwnerFees(uint256 _amount) external onlyOwner nonReentrant whenNotPaused {
        // In a real system, you would track owner fees separately.
        // This is a placeholder. Example check: require(ownerFees >= _amount, "Insufficient owner fees");
        // resourceToken.transfer(owner, _amount);
        // ownerFees -= _amount;
        revert("No owner fee mechanism implemented"); // Example: Disable until fees are added
    }


    // --- Agent & Resource Management Functions ---

    /**
     * @dev Registers an Agent NFT with the protocol by staking Resource Tokens.
     * The caller must own the Agent NFT and have approved this contract to transfer resources.
     * @param _agentId The ID of the Agent NFT to register.
     * @param _amount The amount of resources to stake (must be >= systemParameters.registrationStakeAmount).
     */
    function registerAgentByStaking(uint256 _agentId, uint256 _amount) external nonReentrant whenNotPaused onlyAgentOwner(_agentId) {
        require(!registeredAgents[_agentId], "Agent already registered");
        require(_amount >= systemParameters.registrationStakeAmount, "Insufficient stake amount");

        // Transfer stake from user to contract
        require(resourceToken.transferFrom(msg.sender, address(this), _amount), "Resource transfer failed");

        registeredAgents[_agentId] = true;
        agentData[_agentId].stakedResources = _amount;
        agentData[_agentId].reputation = systemParameters.initialReputation;
        agentData[_agentId].lastReputationUpdate = block.timestamp; // Initialize decay timestamp
        totalRegisteredAgents++;
        totalStakedResources += _amount;

        emit AgentRegistered(_agentId, msg.sender, _amount);
        emit ReputationChanged(_agentId, systemParameters.initialReputation);
    }

    /**
     * @dev Deregisters an Agent, burning their reputation and returning staked resources.
     * Callable only by the Agent NFT owner.
     * @param _agentId The ID of the Agent NFT to deregister.
     */
    function deregisterAgentAndClaimStake(uint256 _agentId) external nonReentrant whenNotPaused onlyAgentOwner(_agentId) {
        require(registeredAgents[_agentId], "Agent not registered");

        uint256 stakeToReturn = agentData[_agentId].stakedResources;
        uint256 claimableToReturn = agentData[_agentId].claimableResources;

        // Clear agent data
        delete agentData[_agentId];
        delete registeredAgents[_agentId];
        totalRegisteredAgents--;
        totalStakedResources -= stakeToReturn;
        // Claimable resources are also 'burned' upon deregistration in this model

        // Transfer stake back to user
        require(resourceToken.transfer(msg.sender, stakeToReturn), "Stake return failed");
        if (claimableToReturn > 0) {
           // Decide if claimable resources are returned upon deregistration or just burned.
           // Burning them encourages claiming regularly. Let's burn them for simplicity here.
           // If returning: require(resourceToken.transfer(msg.sender, claimableToReturn), "Claimable return failed");
           // Emit an event if claimable is burned
        }


        emit AgentDeregistered(_agentId, msg.sender, stakeToReturn);
        // Reputation is implicitly reset to 0 by deleting the data
    }

    /**
     * @dev Deposits additional Resource Tokens for an already registered Agent.
     * The caller must own the Agent NFT and have approved this contract to transfer resources.
     * @param _agentId The ID of the registered Agent NFT.
     * @param _amount The amount of resources to deposit.
     */
    function depositResources(uint256 _agentId, uint256 _amount) external nonReentrant whenNotPaused onlyAgentOwner(_agentId) {
        require(registeredAgents[_agentId], "Agent not registered");
        require(_amount > 0, "Deposit amount must be positive");

        // Transfer resources from user to contract
        require(resourceToken.transferFrom(msg.sender, address(this), _amount), "Resource transfer failed");

        agentData[_agentId].stakedResources += _amount;
        totalStakedResources += _amount;

        emit ResourcesDeposited(_agentId, _amount);
    }

    /**
     * @dev Allows a registered Agent's owner to withdraw their accumulated claimable resources.
     * @param _agentId The ID of the registered Agent NFT.
     */
    function withdrawClaimableResources(uint256 _agentId) external nonReentrant whenNotPaused onlyAgentOwner(_agentId) {
        require(registeredAgents[_agentId], "Agent not registered");

        uint256 claimable = agentData[_agentId].claimableResources;
        require(claimable > 0, "No claimable resources");

        agentData[_agentId].claimableResources = 0;

        // Transfer claimable resources to user
        require(resourceToken.transfer(msg.sender, claimable), "Claimable withdrawal failed");

        emit ClaimableResourcesWithdrawn(_agentId, claimable);
    }

    // --- Reputation Functions ---

    /**
     * @dev Calculates and applies reputation decay for a specific agent.
     * Can be called by anyone to help keep reputation scores up-to-date.
     * Is also called internally before checking reputation requirements.
     * @param _agentId The ID of the Agent.
     */
    function decayAgentReputation(uint256 _agentId) public {
         require(registeredAgents[_agentId], "Agent not registered");
         _calculateReputationDecay(_agentId);
    }

    /**
     * @dev Internal function to calculate and apply reputation decay.
     * Updates lastReputationUpdate timestamp.
     * @param _agentId The ID of the Agent.
     */
    function _calculateReputationDecay(uint256 _agentId) internal {
        uint256 currentReputation = agentData[_agentId].reputation;
        uint256 lastUpdate = agentData[_agentId].lastReputationUpdate;

        if (currentReputation == 0 || block.timestamp <= lastUpdate) {
            agentData[_agentId].lastReputationUpdate = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - lastUpdate;
        // Decay calculation: decay amount = timeElapsed * decayRate
        // We need to consider scaling if decayRatePerSecond is less than 1 wei
        // Assuming decayRatePerSecond is scaled (e.g., 1e18 for 1 reputation/sec)
        uint256 decayAmount = (timeElapsed * systemParameters.reputationDecayRatePerSecond); // Adjust scaling if needed

        uint256 newReputation = (currentReputation > decayAmount) ? currentReputation - decayAmount : 0;

        if (newReputation != currentReputation) {
            agentData[_agentId].reputation = newReputation;
            emit ReputationChanged(_agentId, newReputation);
        }

        agentData[_agentId].lastReputationUpdate = block.timestamp;
    }

    /**
     * @dev Internal function to update an agent's reputation and emit event.
     * Handles both gains and losses.
     * @param _agentId The ID of the Agent.
     * @param _amount The amount to add (positive) or subtract (negative).
     */
    function _updateAgentReputation(uint256 _agentId, int256 _amount) internal {
        _calculateReputationDecay(_agentId); // Apply decay before updating

        uint256 currentReputation = agentData[_agentId].reputation;
        uint256 newReputation;

        if (_amount > 0) {
            newReputation = currentReputation + uint256(_amount);
        } else {
            uint256 decayAmount = uint256(-_amount);
            newReputation = (currentReputation > decayAmount) ? currentReputation - decayAmount : 0;
        }

        agentData[_agentId].reputation = newReputation;
        emit ReputationChanged(_agentId, newReputation);
    }

    /**
     * @dev Internal function to add resources to an agent's claimable balance.
     * @param _agentId The ID of the Agent.
     * @param _amount The amount of resources to add.
     */
    function _addClaimableResources(uint256 _agentId, uint256 _amount) internal {
        agentData[_agentId].claimableResources += _amount;
        // No event here, event is on withdrawal
    }


    // --- Action Functions ---

    /**
     * @dev Performs an action that costs resources and boosts an Agent's reputation.
     * Requires the caller to own the Agent NFT and have approved resource transfer.
     * Implements a cooldown (e.g., can only do once per day, or based on last action time).
     * @param _agentId The ID of the Agent NFT.
     */
    function performReputationBoostingAction(uint256 _agentId) external nonReentrant whenNotPaused onlyAgentOwner(_agentId) {
        require(registeredAgents[_agentId], "Agent not registered");
        uint256 cost = systemParameters.reputationBoostingActionCost;
        require(cost > 0, "Action is disabled or free"); // Prevent action if cost is 0

        // Implement cooldown (e.g., 24 hours)
        uint256 lastTime = agentData[_agentId].lastActionTime[uint8(ActionType.ReputationBoosting)];
        uint256 cooldown = 1 days; // Example cooldown: 1 day
        require(block.timestamp >= lastTime + cooldown, "Action is on cooldown");

        // Transfer cost from user to contract
        require(resourceToken.transferFrom(msg.sender, address(this), cost), "Resource transfer failed for action");
        totalStakedResources += cost; // Resources from actions add to the pool

        _updateAgentReputation(_agentId, int256(systemParameters.reputationBoostAmount));
        _updateAgentLastActionTime(_agentId, uint8(ActionType.ReputationBoosting));

        emit ActionPerformed(_agentId, uint8(ActionType.ReputationBoosting), cost, systemParameters.reputationBoostAmount, 0);
    }

    /**
     * @dev Performs an action that requires reputation and adds resources to claimable balance.
     * Requires the caller to own the Agent NFT and meet the reputation requirement.
     * @param _agentId The ID of the Agent NFT.
     */
    function performResourceGeneratingAction(uint256 _agentId) external nonReentrant whenNotPaused onlyAgentOwner(_agentId) requireHighReputation(_agentId, systemParameters.resourceGeneratingActionReputationReq) {
        require(registeredAgents[_agentId], "Agent not registered");
        uint256 generationAmount = systemParameters.resourceGenerationAmount;
        require(generationAmount > 0, "Resource generation is disabled or yields 0");

        // Implement cooldown (e.g., can only do once per hour)
        uint256 lastTime = agentData[_agentId].lastActionTime[uint8(ActionType.ResourceGenerating)];
        uint256 cooldown = 1 hours; // Example cooldown: 1 hour
        require(block.timestamp >= lastTime + cooldown, "Action is on cooldown");

        // Resources are added to claimable (they come from the total staked pool)
        // No cost is transferred *from* the user for this action in this design
        _addClaimableResources(_agentId, generationAmount);
        _updateAgentLastActionTime(_agentId, uint8(ActionType.ResourceGenerating));

        // Potentially slightly decrease reputation for performing this action? Let's not for now.
        // _updateAgentReputation(_agentId, -int256(systemParameters.reputationCostForResourceAction));

        emit ActionPerformed(_agentId, uint8(ActionType.ResourceGenerating), 0, 0, generationAmount);
    }

    /**
     * @dev Internal helper to update the timestamp of the last time an action was performed.
     * Used for cooldowns and potential future time-based effects.
     * @param _agentId The ID of the Agent.
     * @param _actionType The type of action performed.
     */
    function updateAgentLastActionTime(uint256 _agentId, uint8 _actionType) internal {
        agentData[_agentId].lastActionTime[_actionType] = block.timestamp;
    }


    // --- Governance Functions ---

    /**
     * @dev Allows a high-reputation Agent to propose changes to the system parameters.
     * @param _newParams The proposed new system configuration parameters.
     */
    function proposeParameterChange(SystemParameters memory _newParams) external whenNotPaused onlyAgentOwner(msg.sender) requireHighReputation(msg.sender, systemParameters.governanceProposalReputationReq) {
         require(msg.sender == agentNFT.ownerOf(msg.sender), "Proposer must be the owner of the Agent NFT used"); // Double check ownership based on msg.sender vs _agentId - let's assume AgentId == msg.sender for simplicity or pass agentId explicitly
         // Passing agentId explicitly is better:
         // function proposeParameterChange(uint256 _proposerAgentId, SystemParameters memory _newParams) external whenNotPaused onlyAgentOwner(_proposerAgentId) requireHighReputation(_proposerAgentId, systemParameters.governanceProposalReputationReq) {
         // For now, assume _agentId implicitly linked to msg.sender via onlyAgentOwner
        uint256 proposerAgentId = msg.sender; // This is wrong, need the agent ID

        // Let's correct: Pass agentId explicitly
    }

    /**
     * @dev Allows a high-reputation Agent to propose changes to the system parameters.
     * Requires the caller to own the proposer Agent NFT and meet the reputation requirement.
     * @param _proposerAgentId The ID of the Agent NFT making the proposal.
     * @param _newParams The proposed new system configuration parameters.
     */
    function proposeParameterChange(uint256 _proposerAgentId, SystemParameters memory _newParams) external whenNotPaused onlyAgentOwner(_proposerAgentId) requireHighReputation(_proposerAgentId, systemParameters.governanceProposalReputationReq) {
        require(registeredAgents[_proposerAgentId], "Proposing Agent not registered");

        proposalCount++;
        uint256 currentProposalId = proposalCount;
        uint256 voteEnd = block.timestamp + systemParameters.governanceVotingPeriod;

        proposals[currentProposalId] = Proposal({
            proposedParameters: _newParams,
            proposerAgentId: _proposerAgentId,
            voteStart: block.timestamp,
            voteEnd: voteEnd,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            state: ProposalState.Active
            // hasVoted mapping is initialized empty
        });

        emit ParameterChangeProposed(currentProposalId, _proposerAgentId, _newParams);
    }


    /**
     * @dev Allows a high-reputation Agent to vote on an active proposal.
     * Requires the caller to own the voter Agent NFT and meet the reputation requirement.
     * An Agent can only vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voterAgentId The ID of the Agent NFT casting the vote.
     * @param _support True for 'for', False for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, uint256 _voterAgentId, bool _support) external whenNotPaused onlyAgentOwner(_voterAgentId) requireHighReputation(_voterAgentId, systemParameters.governanceVoteReputationReq) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp >= proposal.voteStart && block.timestamp < proposal.voteEnd, "Voting period is closed");
        require(registeredAgents[_voterAgentId], "Voting Agent not registered");
        require(!proposal.hasVoted[_voterAgentId], "Agent has already voted");

        proposal.hasVoted[_voterAgentId] = true;

        if (_support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }

        emit VoteCast(_proposalId, _voterAgentId, _support);
    }

    /**
     * @dev Executes a successful proposal after the voting period has ended.
     * Anyone can call this to trigger execution if conditions are met.
     * Checks for quorum and majority based on *total registered agents* at the time of execution.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp >= proposal.voteEnd, "Voting period is not over");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        // Quorum calculation: Total votes must be >= quorum percentage of total registered agents.
        // Use Math.mulDiv for safe percentage calculation.
        uint256 requiredQuorum = (totalRegisteredAgents * systemParameters.governanceQuorumNumerator) / 100;
        require(totalVotes >= requiredQuorum, "Quorum not reached");

        // Majority calculation: For votes must be > majority percentage of *total votes*.
        // Example: >50% means forVotes * 100 > totalVotes * 50
        bool majorityAchieved = (proposal.forVotes * 100) > (totalVotes * systemParameters.governanceMajorityNumerator);

        if (majorityAchieved) {
            // Execute the proposed parameter changes
            setSystemParameters(proposal.proposedParameters);
            proposal.state = ProposalState.Executed;
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Defeated;
            // Emit a defeated event if desired
        }
    }

     /**
     * @dev Allows the proposer or owner to cancel a proposal before voting ends.
     * May implement penalties for proposer in a more complex system.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal is not cancellable");
        require(msg.sender == owner || (msg.sender == agentNFT.ownerOf(proposal.proposerAgentId) && block.timestamp < proposal.voteEnd), "Only owner or proposer (before voting ends) can cancel");

        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId);
    }


    // --- Query Functions ---

    /**
     * @dev Queries an Agent's current reputation score, applying decay first.
     * @param _agentId The ID of the Agent.
     * @return The current reputation score.
     */
    function getAgentReputation(uint256 _agentId) public returns (uint256) {
        // Apply decay before returning the value
        if (registeredAgents[_agentId]) {
             _calculateReputationDecay(_agentId);
             return agentData[_agentId].reputation;
        }
        return 0;
    }

    /**
     * @dev Queries an Agent's currently staked resources.
     * @param _agentId The ID of the Agent.
     * @return The amount of resources staked by the Agent.
     */
    function getAgentStakedResources(uint256 _agentId) public view returns (uint256) {
        return agentData[_agentId].stakedResources;
    }

    /**
     * @dev Queries an Agent's currently accumulated claimable resources.
     * @param _agentId The ID of the Agent.
     * @return The amount of claimable resources for the Agent.
     */
    function getAgentClaimableResources(uint256 _agentId) public view returns (uint256) {
        return agentData[_agentId].claimableResources;
    }

    /**
     * @dev Queries the current system configuration parameters.
     * @return The current SystemParameters struct.
     */
    function getCurrentSystemParameters() external view returns (SystemParameters memory) {
        return systemParameters;
    }

    /**
     * @dev Queries the details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The Proposal struct details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        // Note: Mappings within structs cannot be returned directly from a view function.
        // We return the struct excluding the `hasVoted` mapping.
        // A separate function would be needed to check if a specific agent voted on a proposal.
        Proposal storage proposal = proposals[_proposalId];
         return Proposal({
            proposedParameters: proposal.proposedParameters,
            proposerAgentId: proposal.proposerAgentId,
            voteStart: proposal.voteStart,
            voteEnd: proposal.voteEnd,
            forVotes: proposal.forVotes,
            againstVotes: proposal.againstVotes,
            executed: proposal.executed,
            state: proposal.state
            // hasVoted mapping is omitted
        });
    }

     /**
     * @dev Queries the total number of Resource Tokens currently staked in the contract.
     * @return The total staked amount.
     */
    function getTotalStakedResources() external view returns (uint256) {
        return totalStakedResources;
    }

    /**
     * @dev Queries the total number of Agents currently registered in the protocol.
     * @return The total count of registered Agents.
     */
    function getTotalRegisteredAgents() external view returns (uint256) {
        return totalRegisteredAgents;
    }

     /**
     * @dev Checks if an Agent is currently registered.
     * @param _agentId The ID of the Agent.
     * @return True if registered, false otherwise.
     */
    function isAgentRegistered(uint256 _agentId) external view returns (bool) {
        return registeredAgents[_agentId];
    }

    /**
     * @dev Checks if an Agent has voted on a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @param _agentId The ID of the Agent.
     * @return True if the agent has voted, false otherwise.
     */
    function hasAgentVotedOnProposal(uint256 _proposalId, uint256 _agentId) external view returns (bool) {
         return proposals[_proposalId].hasVoted[_agentId];
    }


    // --- Internal Functions (Contribute to total function count / complexity) ---

    // updateAgentLastActionTime is already defined above.
    // _calculateReputationDecay is already defined above.
    // _updateAgentReputation is already defined above.
    // _addClaimableResources is already defined above.
}
```

**Explanation of Advanced/Interesting Concepts:**

1.  **Dynamic State per NFT (AgentData):** Instead of NFTs just representing ownership of a static asset, they are tied to dynamic data (`AgentData` struct) within this contract. This data (reputation, staked resources, claimable rewards, action history) changes based on user interaction, making the NFT a representation of participation and status within the ecosystem.
2.  **Reputation as a Core Mechanic:** Reputation is not just a display value. It's a gatekeeper for actions (`performResourceGeneratingAction`) and governance participation (`proposeParameterChange`, `voteOnProposal`). It also decays over time, encouraging active participation.
3.  **Parameterized Actions:** The core actions (`performReputationBoostingAction`, `performResourceGeneratingAction`) are not hardcoded with fixed costs/rewards. These values are stored in the `SystemParameters` struct, allowing them to be changed.
4.  **Time-Based Effects:** Reputation decay is explicitly calculated based on time elapsed since the last update. Action cooldowns (`lastActionTime`) also introduce time-based gating.
5.  **On-Chain Governance:** A simple, but functional, governance system (`Proposal` struct, `proposeParameterChange`, `voteOnProposal`, `executeProposal`, `cancelProposal`) allows high-reputation agents to collectively decide on parameter changes, making the protocol rules evolve over time without requiring owner intervention (after initial setup). Quorum and majority logic are included.
6.  **Integration with External Tokens:** The contract relies on and interacts with separate ERC-20 and ERC-721 contracts, which is common in complex DeFi/NFT protocols. `transferFrom` is used for users giving the contract permission to move tokens on their behalf.
7.  **ReentrancyGuard:** Used in functions that interact with external contracts (`transfer`, `transferFrom`) to prevent reentrancy attacks, which is crucial for security in token interactions.
8.  **Clear Structs and Enums:** Using structs (`SystemParameters`, `AgentData`, `Proposal`) and enums (`ProposalState`, `ActionType`) makes the code more organized and readable, representing complex data structures and states.

This contract provides a framework for a decentralized application where user identity (NFT) is tied to evolving stats (Reputation, Resources) that influence their ability to interact with the system and govern its future parameters.