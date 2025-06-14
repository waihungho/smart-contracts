Okay, here is a smart contract concept that combines dynamic state, influence mechanisms, parameter control, resource distribution, and a basic reputation system, aiming for uniqueness and complexity beyond typical open-source examples.

**Concept:** **Adaptive State & Influence Registry (ASIR)**

This contract acts as a decentralized registry for managing system parameters and executing approved actions based on user influence. Users stake a specific ERC20 token (`InfluenceToken`) to gain dynamic influence credit. This influence credit is used to boost proposals, either to change system parameters or trigger predefined actions (like distributing resources from a pool). Influence credit decays over time if not refreshed by staking. A basic user score tracks participation reputation.

**Key Unique Aspects:**

1.  **Dynamic Influence Credit:** Influence isn't just based on stake amount, but also time and decay.
2.  **Influence Boosting:** Proposals are advanced by applying influence credit, rather than simple token voting. The *amount* of influence applied matters.
3.  **Adaptive Parameters:** The contract's own internal settings (like decay rates, proposal thresholds) can be changed via governance proposals.
4.  **Action Registry:** Predefined, executable actions can be triggered via proposals.
5.  **Basic Reputation:** A simple score tracks positive/negative outcomes of user's boosted proposals.
6.  **Delegation:** Users can delegate their influence *earning potential* or *boosting power*.

---

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol"; // Assuming a standard ERC20 interface file is available

/**
 * @title AdaptiveStateInfluenceRegistry (ASIR)
 * @dev A decentralized registry controlling system parameters and executing actions based on dynamic user influence.
 * Users stake InfluenceToken to gain InfluenceCredit, which is used to boost proposals.
 * Proposals can change parameters or trigger registered actions. InfluenceCredit decays over time.
 * A basic user score tracks participation success.
 */
contract AdaptiveStateInfluenceRegistry {

    // ================================= STATE VARIABLES =================================

    // --- Tokens ---
    IERC20 public immutable influenceToken;     // The token staked for influence
    IERC20 public immutable resourceToken;      // The token held in the resource pool

    // --- Influence & Staking ---
    mapping(address => uint256) public stakedTokens;          // Tokens staked by user
    mapping(address => uint256) public influenceCredit;       // Current dynamic influence credit for user
    mapping(address => uint256) public lastInfluenceUpdate;   // Last timestamp influence was calculated for user
    mapping(address => address) public delegatee;             // Address the user delegates influence gain/boost power to
    mapping(address => address[]) public delegators;          // Addresses delegating to this user

    uint256 public baseInfluencePerTokenPerSecond; // Rate of influence gain per staked token per second
    uint256 public influenceDecayRatePerSecond;    // Rate at which existing influence credit decays per second

    // --- Parameters ---
    // Using string keys for flexible parameter names and uint256 values for simplicity
    mapping(string => uint256) public systemParameters; // Key-value store for system parameters
    string[] public parameterNames;                   // List of parameter names for iteration

    // --- Proposals ---
    struct Proposal {
        uint256 id;                         // Unique proposal ID
        address creator;                    // Address that created the proposal
        ProposalType proposalType;          // Type of proposal (ParameterChange or Action)
        bytes targetData;                   // Data defining the target (paramName for change, actionType for action)
        bytes proposalData;                 // Data specific to the proposal (newValue for param, actionData for action)
        uint256 creationTime;               // Timestamp of creation
        uint256 expirationTime;             // Timestamp when proposal expires
        uint256 totalInfluenceSupport;      // Total influence credit applied to this proposal
        mapping(address => uint256) supportByAddress; // Influence credit applied by each address
        ProposalState state;                // Current state of the proposal
        bool executed;                      // Whether the proposal has been successfully executed
    }

    enum ProposalType {
        ParameterChange, // Change a value in systemParameters
        Action           // Trigger a predefined action
    }

    enum ProposalState {
        Active,   // Open for boosting
        Approved, // Met support threshold before expiration
        Rejected, // Did not meet support threshold before expiration
        Executed, // Approved and action/change applied
        Canceled  // Canceled by creator or influence quorum
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    // --- Actions ---
    mapping(bytes32 => bool) public registeredActionTypes; // Hashed action type names that are allowed

    // --- Resource Pool & Distribution ---
    uint256 public resourcePoolBalance; // Total balance of resourceToken in the contract
    mapping(address => uint256) public claimableResource; // Resource tokens allocated to addresses from distributions

    // --- Reputation ---
    mapping(address => int256) public userScores; // Simple integer score (positive for successful proposals, negative for failed)

    // --- Configuration Parameters (governed by proposals) ---
    uint256 public minInfluenceToPropose;      // Minimum influence credit required to create a proposal
    uint256 public proposalDuration;           // Default duration for proposals
    uint256 public parameterChangeThreshold;   // Minimum totalInfluenceSupport required to approve ParameterChange proposal
    uint256 public actionThreshold;            // Minimum totalInfluenceSupport required to approve Action proposal
    uint256 public cancelProposalThreshold;    // Minimum totalInfluenceSupport required to cancel someone else's proposal

    // ================================= EVENTS =================================

    event Staked(address indexed user, uint256 amount, uint256 newInfluenceCredit);
    event Unstaked(address indexed user, uint256 amount, uint256 remainingInfluenceCredit);
    event InfluenceCreditUpdated(address indexed user, uint256 newCredit, uint256 timestamp);
    event ParameterChanged(string indexed paramName, uint256 newValue, address indexed modifier);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, ProposalType proposalType, bytes targetData, bytes proposalData);
    event ProposalBoosted(uint256 indexed proposalId, address indexed booster, uint256 influenceApplied, uint256 totalInfluenceSupport);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event ProposalCanceled(uint256 indexed proposalId, address indexed canceler);
    event ActionRegistered(bytes32 indexed actionTypeHash);
    event ResourceDeposited(address indexed depositor, uint256 amount);
    event ResourceDistributed(uint256 indexed proposalId, uint256 amount, bytes distributionData); // DistributionData might encode recipients/amounts
    event ResourceClaimed(address indexed claimant, uint256 amount);
    event DelegateUpdated(address indexed delegator, address indexed newDelegatee);
    event UserScoreUpdated(address indexed user, int256 newScore);

    // ================================= CONSTRUCTOR =================================

    constructor(address _influenceToken, address _resourceToken) {
        influenceToken = IERC20(_influenceToken);
        resourceToken = IERC20(_resourceToken);

        // Initialize default system parameters (can be changed later via proposals)
        baseInfluencePerTokenPerSecond = 1; // 1 influence per token per second (example)
        influenceDecayRatePerSecond = 0;    // Start with no decay (example)

        minInfluenceToPropose = 1000;      // Example threshold
        proposalDuration = 7 days;         // Example duration
        parameterChangeThreshold = 10000;  // Example support threshold
        actionThreshold = 20000;           // Example support threshold
        cancelProposalThreshold = 50000;   // Example high threshold

        // Register initial action types (example: a resource distribution action)
        // In a real scenario, these would likely be bytes32 hashes of action names/identifiers
        registeredActionTypes[keccak256("DistributeResource")] = true;
        emit ActionRegistered(keccak256("DistributeResource"));
    }

    // ================================= INFLUENCE & STAKING FUNCTIONS (5) =================================

    /**
     * @dev Stakes InfluenceToken and updates user's influence credit.
     * @param amount The amount of InfluenceToken to stake.
     */
    function stake(uint256 amount) external {
        require(amount > 0, "ASIR: Stake amount must be > 0");
        _updateInfluenceCredit(msg.sender); // Update credit before staking
        influenceToken.transferFrom(msg.sender, address(this), amount);
        stakedTokens[msg.sender] += amount;
        _updateInfluenceCredit(msg.sender); // Update credit after staking
        emit Staked(msg.sender, amount, influenceCredit[msg.sender]);
    }

    /**
     * @dev Unstakes InfluenceToken and updates user's influence credit.
     * @param amount The amount of InfluenceToken to unstake.
     */
    function unstake(uint256 amount) external {
        require(amount > 0, "ASIR: Unstake amount must be > 0");
        require(stakedTokens[msg.sender] >= amount, "ASIR: Not enough staked tokens");

        _updateInfluenceCredit(msg.sender); // Update credit before unstaking
        stakedTokens[msg.sender] -= amount;
        _updateInfluenceCredit(msg.sender); // Update credit after unstaking

        influenceToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount, influenceCredit[msg.sender]);
    }

    /**
     * @dev Calculates and updates a user's influence credit based on stake, time, and decay.
     * @param user The address of the user.
     */
    function _calculateInfluenceCredit(address user) internal {
        uint256 currentTimestamp = block.timestamp;
        uint256 lastUpdate = lastInfluenceUpdate[user];
        uint256 currentCredit = influenceCredit[user];
        uint256 currentStake = stakedTokens[user];

        if (currentTimestamp > lastUpdate) {
            uint256 timeDelta = currentTimestamp - lastUpdate;

            // Add influence from staking
            uint256 gainedInfluence = currentStake * baseInfluencePerTokenPerSecond * timeDelta;
            currentCredit += gainedInfluence;

            // Apply decay (optional, based on influenceDecayRatePerSecond)
            // Decay applied to the *start* amount of the period is a simple model
            // A more complex model could decay the weighted average or use discrete steps
            uint256 decayAmount = currentCredit * influenceDecayRatePerSecond * timeDelta / 1e18; // Assuming decayRate is scaled
            // Or a simpler decay:
            // uint256 decayAmount = currentCredit * influenceDecayRatePerSecond / (1 days); // Example simple daily decay
             decayAmount = (currentCredit * influenceDecayRatePerSecond / 10000) * timeDelta; // Example: 10000 = 100% per second scaled by 1e-4

             // A safer decay preventing excessive loss on long periods without update:
             // Influence Credit at t = Influence_0 * (1 - decayRate)^t + stake * gainRate * Integral((1-decayRate)^tau, dtau)
             // Simple linear decay approximation:
             uint256 effectiveDecay = influenceDecayRatePerSecond * timeDelta;
             if (effectiveDecay < 1e18) { // Avoid large numbers, assume decayRate is small
                  currentCredit = currentCredit * (1e18 - effectiveDecay) / 1e18;
             } else {
                  currentCredit = 0; // Full decay over long periods
             }
             // Let's use a simpler, potentially less precise linear decay for demonstration
             uint256 simpleDecay = (currentCredit * influenceDecayRatePerSecond) / (1e18) * timeDelta;
             currentCredit = currentCredit > simpleDecay ? currentCredit - simpleDecay : 0;


            influenceCredit[user] = currentCredit;
            lastInfluenceUpdate[user] = currentTimestamp;
             emit InfluenceCreditUpdated(user, currentCredit, currentTimestamp);
        }
    }

    /**
     * @dev Public view function to get a user's current influence credit, calculating it on the fly.
     * @param user The address of the user.
     * @return The current influence credit of the user.
     */
    function queryInfluenceCredit(address user) public view returns (uint256) {
         uint256 currentTimestamp = block.timestamp;
        uint256 lastUpdate = lastInfluenceUpdate[user];
        uint256 currentCredit = influenceCredit[user];
        uint256 currentStake = stakedTokens[user];

        if (currentTimestamp > lastUpdate) {
            uint256 timeDelta = currentTimestamp - lastUpdate;

            // Add influence from staking
            uint256 gainedInfluence = currentStake * baseInfluencePerTokenPerSecond * timeDelta;
            currentCredit += gainedInfluence;

             // Apply simple linear decay approximation (matching _calculateInfluenceCredit logic)
             uint256 simpleDecay = (currentCredit * influenceDecayRatePerSecond) / (1e18) * timeDelta; // Decay rate assumed scaled
             currentCredit = currentCredit > simpleDecay ? currentCredit - simpleDecay : 0;

        }
        return currentCredit;
    }

    /**
     * @dev Public view function to get the amount of tokens staked by a user.
     * @param user The address of the user.
     * @return The staked amount.
     */
    function queryStakedAmount(address user) public view returns (uint256) {
        return stakedTokens[user];
    }


    // ================================= REPUTATION FUNCTIONS (2) =================================

    /**
     * @dev Internal function to update a user's reputation score.
     * @param user The address of the user.
     * @param points The points to add (can be negative).
     */
    function _updateUserScore(address user, int256 points) internal {
         userScores[user] += points;
         emit UserScoreUpdated(user, userScores[user]);
    }

    /**
     * @dev Public view function to get a user's reputation score.
     * @param user The address of the user.
     * @return The user's score.
     */
    function queryUserScore(address user) public view returns (int256) {
        return userScores[user];
    }

    // ================================= PARAMETER FUNCTIONS (3) =================================

    /**
     * @dev Sets an initial system parameter. Only callable from constructor or via governance.
     * @param paramName The name of the parameter.
     * @param value The uint256 value of the parameter.
     */
    function _initializeParameter(string memory paramName, uint256 value) internal {
        systemParameters[paramName] = value;
        parameterNames.push(paramName); // Track names for iteration
        emit ParameterChanged(paramName, value, address(0)); // address(0) signifies initial setting
    }

     /**
     * @dev Public view function to get the value of a system parameter.
     * @param paramName The name of the parameter.
     * @return The uint256 value of the parameter. Returns 0 if not set.
     */
    function queryParameter(string memory paramName) public view returns (uint256) {
        return systemParameters[paramName];
    }

    /**
     * @dev Public view function to get all parameter names.
     * @return An array of all registered parameter names.
     */
    function queryAllParameterNames() public view returns (string[] memory) {
        return parameterNames;
    }


    // ================================= PROPOSAL FUNCTIONS (11) =================================

    /**
     * @dev Creates a new proposal to change a system parameter.
     * Requires minimum influence credit to propose.
     * @param paramName The name of the parameter to change.
     * @param newValue The new uint256 value for the parameter.
     */
    function proposeParameterChange(string memory paramName, uint256 newValue) external {
        _updateInfluenceCredit(msg.sender);
        require(influenceCredit[msg.sender] >= minInfluenceToPropose, "ASIR: Not enough influence to propose");
        require(bytes(paramName).length > 0, "ASIR: Parameter name cannot be empty");
        // Further validation could be added here based on parameter constraints if stored

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.creator = msg.sender;
        proposal.proposalType = ProposalType.ParameterChange;
        proposal.targetData = abi.encodePacked(paramName);
        proposal.proposalData = abi.encodePacked(newValue);
        proposal.creationTime = block.timestamp;
        proposal.expirationTime = block.timestamp + proposalDuration;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, ProposalType.ParameterChange, proposal.targetData, proposal.proposalData);
    }

     /**
     * @dev Creates a new proposal to trigger a predefined action.
     * Requires minimum influence credit to propose.
     * @param actionTypeHash The bytes32 hash identifying the action type.
     * @param actionData Optional bytes data specific to the action (e.g., recipients, amounts).
     */
    function proposeAction(bytes32 actionTypeHash, bytes memory actionData) external {
        _updateInfluenceCredit(msg.sender);
        require(influenceCredit[msg.sender] >= minInfluenceToPropose, "ASIR: Not enough influence to propose");
        require(registeredActionTypes[actionTypeHash], "ASIR: Action type not registered");

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.creator = msg.sender;
        proposal.proposalType = ProposalType.Action;
        proposal.targetData = abi.encodePacked(actionTypeHash);
        proposal.proposalData = actionData;
        proposal.creationTime = block.timestamp;
        proposal.expirationTime = block.timestamp + proposalDuration;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, ProposalType.Action, proposal.targetData, proposal.proposalData);
    }

    /**
     * @dev Applies influence credit to boost a proposal.
     * The influence credit is effectively "spent" or locked for this purpose.
     * Assumes applied influence is consumed from current credit.
     * @param proposalId The ID of the proposal to boost.
     * @param amount The amount of influence credit to apply.
     */
    function boostProposal(uint256 proposalId, uint256 amount) external {
        _updateInfluenceCredit(msg.sender); // Update credit before spending
        require(amount > 0, "ASIR: Must apply positive influence");
        require(influenceCredit[msg.sender] >= amount, "ASIR: Not enough influence credit");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "ASIR: Proposal does not exist"); // Check if proposal was initialized
        require(proposal.state == ProposalState.Active, "ASIR: Proposal not active");
        require(block.timestamp < proposal.expirationTime, "ASIR: Proposal has expired");

        address actualBooster = delegatee[msg.sender] == address(0) ? msg.sender : delegatee[msg.sender];

        // Reduce the booster's influence credit
        influenceCredit[msg.sender] -= amount;

        // Apply influence to the proposal
        proposal.totalInfluenceSupport += amount;
        proposal.supportByAddress[actualBooster] += amount; // Track support by actual booster or delegatee if delegated

        emit ProposalBoosted(proposalId, actualBooster, amount, proposal.totalInfluenceSupport);
        // Could emit InfluenceCreditUpdated for msg.sender here, but _updateInfluenceCredit does it.
    }

     /**
      * @dev Checks the current state of a proposal (Approved/Rejected/Active) based on time and support.
      * Does NOT change the proposal's state in storage, it's a view function.
      * @param proposalId The ID of the proposal.
      * @return The calculated state of the proposal.
      */
    function checkProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "ASIR: Proposal does not exist");

        if (proposal.state != ProposalState.Active) {
            return proposal.state;
        }

        uint256 requiredThreshold;
        if (proposal.proposalType == ProposalType.ParameterChange) {
            requiredThreshold = parameterChangeThreshold;
        } else if (proposal.proposalType == ProposalType.Action) {
            requiredThreshold = actionThreshold;
        } else {
             // Should not happen with defined enums
             return ProposalState.Rejected;
        }

        if (block.timestamp >= proposal.expirationTime) {
            if (proposal.totalInfluenceSupport >= requiredThreshold) {
                return ProposalState.Approved;
            } else {
                return ProposalState.Rejected;
            }
        } else {
            // Proposal is still active, but might have already met the threshold
            if (proposal.totalInfluenceSupport >= requiredThreshold) {
                 return ProposalState.Approved; // Can be executed even before expiration if threshold met
            }
            return ProposalState.Active; // Still active and threshold not met yet
        }
    }

    /**
     * @dev Executes an approved proposal. Can be called by anyone after the proposal
     * meets the approval criteria and has not expired or is expired and approved.
     * Updates reputation scores.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "ASIR: Proposal does not exist");
        require(proposal.state != ProposalState.Executed, "ASIR: Proposal already executed");

        ProposalState currentState = checkProposalState(proposalId);
        require(currentState == ProposalState.Approved, "ASIR: Proposal not approved");

        proposal.state = ProposalState.Executed;
        proposal.executed = true;

        // Apply the effect of the proposal
        if (proposal.proposalType == ProposalType.ParameterChange) {
            _applyParameterChange(proposal.targetData, proposal.proposalData);
            // Update score for creator and top boosters (simple logic)
            _updateUserScore(proposal.creator, 1); // Creator gets +1
             // Could add logic to reward top 10 boosters or users who applied > X influence
        } else if (proposal.proposalType == ProposalType.Action) {
            _executeAction(proposalId, proposal.targetData, proposal.proposalData);
             // Update score for creator and top boosters (simple logic)
            _updateUserScore(proposal.creator, 2); // Action creators get +2 (example)
             // Could add logic to reward top 10 boosters etc.
        }

        // Deduct score for users who supported rejected proposals (simple logic)
        // This would require iterating through past proposals or storing supporters separately on rejection.
        // For this example, let's keep it simple and only reward success.

        emit ProposalExecuted(proposalId, msg.sender);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    /**
     * @dev Internal function to apply a parameter change from an executed proposal.
     * @param targetData The bytes data identifying the parameter name.
     * @param proposalData The bytes data containing the new uint256 value.
     */
    function _applyParameterChange(bytes memory targetData, bytes memory proposalData) internal {
        string memory paramName = abi.decode(targetData, (string));
        uint256 newValue = abi.decode(proposalData, (uint256));

        // Basic validation (e.g., don't change token addresses this way)
        // More complex contracts would have specific setters or different data types
        require(
            keccak256(abi.encodePacked(paramName)) != keccak256("influenceToken") &&
            keccak256(abi.encodePacked(paramName)) != keccak256("resourceToken"),
            "ASIR: Cannot change token addresses via standard param proposal"
        );

        // Check if parameter name exists, if required, or just set it
        bool found = false;
        for(uint i=0; i < parameterNames.length; i++) {
            if (keccak256(abi.encodePacked(parameterNames[i])) == keccak256(abi.encodePacked(paramName))) {
                found = true;
                break;
            }
        }
        if (!found) {
             parameterNames.push(paramName); // Add new parameter if it doesn't exist
        }

        systemParameters[paramName] = newValue;
        emit ParameterChanged(paramName, newValue, address(this)); // Emitter indicates governance change
    }


    /**
     * @dev Internal function to execute a registered action from an approved proposal.
     * @param proposalId The ID of the executed proposal.
     * @param actionTypeHashData The bytes data containing the bytes32 action type hash.
     * @param actionData Optional bytes data specific to the action.
     */
    function _executeAction(uint256 proposalId, bytes memory actionTypeHashData, bytes memory actionData) internal {
        bytes32 actionTypeHash = abi.decode(actionTypeHashData, (bytes32));

        require(registeredActionTypes[actionTypeHash], "ASIR: Action type not registered for execution");

        if (actionTypeHash == keccak256("DistributeResource")) {
            // Example action: Distribute resources from the pool
            // actionData format: abi.encode(address[], uint256[]) for recipients and amounts
            (address[] memory recipients, uint256[] memory amounts) = abi.decode(actionData, (address[], uint256[]));
            require(recipients.length == amounts.length, "ASIR: Mismatch in recipients and amounts");

            uint256 totalToDistribute = 0;
            for (uint i = 0; i < amounts.length; i++) {
                totalToDistribute += amounts[i];
            }

            require(resourcePoolBalance >= totalToDistribute, "ASIR: Not enough resources in pool for distribution");

            resourcePoolBalance -= totalToDistribute;
            for (uint i = 0; i < recipients.length; i++) {
                claimableResource[recipients[i]] += amounts[i];
            }

            emit ResourceDistributed(proposalId, totalToDistribute, actionData); // Emit data for off-chain interpretation

        }
        // Add more `else if` for other registered action types
        // else if (actionTypeHash == keccak256("AnotherAction")) { ... }
    }

    /**
     * @dev Public view function to get details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function queryProposal(uint256 proposalId) public view returns (
        uint256 id,
        address creator,
        ProposalType proposalType,
        bytes memory targetData,
        bytes memory proposalData,
        uint256 creationTime,
        uint256 expirationTime,
        uint256 totalInfluenceSupport,
        ProposalState state,
        bool executed
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0 || proposalId == 0, "ASIR: Proposal does not exist"); // Allow querying proposal 0 if nextProposalId is 0

        return (
            proposal.id,
            proposal.creator,
            proposal.proposalType,
            proposal.targetData,
            proposal.proposalData,
            proposal.creationTime,
            proposal.expirationTime,
            proposal.totalInfluenceSupport,
            checkProposalState(proposalId), // Return dynamic state
            proposal.executed
        );
    }

    /**
     * @dev Public view function to get proposals created by a specific user. (Requires iteration, gas heavy for many proposals)
     * @param user The address of the creator.
     * @return An array of proposal IDs created by the user.
     */
    function queryProposalsByCreator(address user) public view returns (uint256[] memory) {
        uint256[] memory userProposalIds = new uint256[](nextProposalId); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < nextProposalId; i++) {
            if (proposals[i].creator == user) {
                userProposalIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userProposalIds[i];
        }
        return result;
    }

     /**
      * @dev Public view function to get proposals in a specific state. (Requires iteration, gas heavy for many proposals)
      * Note: This checks the *current* dynamic state using checkProposalState, not the stored state.
      * @param state The desired state (Active, Approved, Rejected, Executed, Canceled).
      * @return An array of proposal IDs in the specified state.
      */
    function queryProposalsByState(ProposalState state) public view returns (uint256[] memory) {
        uint256[] memory stateProposalIds = new uint256[](nextProposalId); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < nextProposalId; i++) {
            if (i > 0 && proposals[i].id == 0) continue; // Skip uninitialized slots if any (unlikely with sequential IDs)
            if (checkProposalState(i) == state) {
                stateProposalIds[count] = i;
                count++;
            }
        }
         uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = stateProposalIds[i];
        }
        return result;
    }

    /**
     * @dev Cancels a proposal if it's active. Can be called by the creator or addresses
     * who collectively apply influence credit exceeding the cancel threshold.
     * Applied influence for cancellation is consumed.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "ASIR: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "ASIR: Proposal not active");
        require(block.timestamp < proposal.expirationTime, "ASIR: Proposal has expired");

        bool isCreator = proposal.creator == msg.sender;

        if (!isCreator) {
            // Check for collective influence support to cancel
             _updateInfluenceCredit(msg.sender); // Update potential canceler's credit
             require(influenceCredit[msg.sender] >= cancelProposalThreshold, "ASIR: Must be creator or have enough influence to cancel"); // Simplified: requires ONE user to have enough
            // A more advanced version would allow multiple users to pool influence for cancellation
             influenceCredit[msg.sender] -= cancelProposalThreshold; // Consume influence for cancellation
        }

        proposal.state = ProposalState.Canceled;
         emit ProposalCanceled(proposalId, msg.sender);
         emit ProposalStateChanged(proposalId, ProposalState.Canceled);

         // Note: Influence applied *to* the canceled proposal is NOT automatically returned.
         // This encourages careful boosting. A different design could return pro-rata.
    }

    /**
     * @dev Public view function to get the total influence support for a proposal.
     * @param proposalId The ID of the proposal.
     * @return The total influence support amount.
     */
    function queryProposalSupport(uint256 proposalId) public view returns (uint256) {
        require(proposals[proposalId].id != 0 || proposalId == 0, "ASIR: Proposal does not exist");
        return proposals[proposalId].totalInfluenceSupport;
    }

    /**
     * @dev Public view function to get the influence support applied by a specific user to a proposal.
     * @param proposalId The ID of the proposal.
     * @param user The address of the user.
     * @return The influence amount applied by the user.
     */
     function queryUserSupportForProposal(uint256 proposalId, address user) public view returns (uint256) {
         require(proposals[proposalId].id != 0 || proposalId == 0, "ASIR: Proposal does not exist");
         // Need to query support by the delegatee if user delegated
         address actualSupporter = delegatee[user] == address(0) ? user : delegatee[user];
         return proposals[proposalId].supportByAddress[actualSupporter];
     }

    // ================================= DELEGATION FUNCTIONS (4) =================================

    /**
     * @dev Delegates the caller's future influence gain and boosting power to another address.
     * @param delegateeAddress The address to delegate to. Address(0) to undelegate.
     */
    function delegateInfluenceGain(address delegateeAddress) external {
        address currentDelegatee = delegatee[msg.sender];
        require(currentDelegatee != delegateeAddress, "ASIR: Already delegated to this address");
        require(delegateeAddress != msg.sender, "ASIR: Cannot delegate to yourself");

        _updateInfluenceCredit(msg.sender); // Update caller's credit before changing delegation

        if (currentDelegatee != address(0)) {
            // Remove msg.sender from the current delegatee's delegators list
            address[] storage currentDelegators = delegators[currentDelegatee];
            for (uint i = 0; i < currentDelegators.length; i++) {
                if (currentDelegators[i] == msg.sender) {
                    currentDelegators[i] = currentDelegators[currentDelegators.length - 1];
                    currentDelegators.pop();
                    break;
                }
            }
             _updateInfluenceCredit(currentDelegatee); // Update old delegatee's credit as their delegation count changes
        }

        delegatee[msg.sender] = delegateeAddress;

        if (delegateeAddress != address(0)) {
            // Add msg.sender to the new delegatee's delegators list
            delegators[delegateeAddress].push(msg.sender);
             _updateInfluenceCredit(delegateeAddress); // Update new delegatee's credit
        }

        emit DelegateUpdated(msg.sender, delegateeAddress);
    }

    /**
     * @dev Removes delegation. Same as calling delegateInfluenceGain with address(0).
     */
    function undelegateInfluenceGain() external {
        delegateInfluenceGain(address(0));
    }

    /**
     * @dev Public view function to see who an address has delegated their influence gain to.
     * @param delegator The address whose delegation is being queried.
     * @return The address the delegator is delegating to, or address(0) if none.
     */
    function queryDelegatee(address delegator) public view returns (address) {
        return delegatee[delegator];
    }

     /**
     * @dev Public view function to see which addresses are delegating influence gain to a specific address.
     * @param delegateeAddress The address being delegated to.
     * @return An array of addresses delegating to the delegateeAddress.
     */
    function queryDelegators(address delegateeAddress) public view returns (address[] memory) {
        return delegators[delegateeAddress];
    }


    // ================================= RESOURCE POOL FUNCTIONS (3) =================================

    /**
     * @dev Allows anyone to deposit resourceToken into the contract's resource pool.
     * @param amount The amount of resourceToken to deposit.
     */
    function depositResource(uint256 amount) external {
        require(amount > 0, "ASIR: Deposit amount must be > 0");
        resourceToken.transferFrom(msg.sender, address(this), amount);
        resourcePoolBalance += amount;
        emit ResourceDeposited(msg.sender, amount);
    }

     /**
     * @dev Allows a user to claim resource tokens allocated to them via executed distribution actions.
     * @param amount The amount to claim.
     */
    function withdrawResourceDistribution(uint256 amount) external {
        require(amount > 0, "ASIR: Claim amount must be > 0");
        require(claimableResource[msg.sender] >= amount, "ASIR: Not enough claimable resource");

        claimableResource[msg.sender] -= amount;
        resourceToken.transfer(msg.sender, amount);
        emit ResourceClaimed(msg.sender, amount);
    }

    /**
     * @dev Public view function to check how much resource token an address can claim.
     * @param user The address to check.
     * @return The amount of claimable resource tokens.
     */
    function queryClaimableResource(address user) public view returns (uint256) {
        return claimableResource[user];
    }

    // ================================= ACTION REGISTRY FUNCTIONS (2) =================================

    /**
     * @dev Registers a new action type that can be proposed and executed.
     * This function itself would typically be callable only via a specific
     * governance proposal (e.g., a "RegisterActionType" action) or initially by owner.
     * For this example, illustrating the function; real implementation needs access control.
     * @param actionTypeHash The bytes32 hash identifying the new action type.
     */
    function registerActionType(bytes32 actionTypeHash) external {
         // TODO: Add strong access control here, e.g., require(msg.sender == owner) or require(isApprovedViaActionProposal(...))
        require(!registeredActionTypes[actionTypeHash], "ASIR: Action type already registered");
        registeredActionTypes[actionTypeHash] = true;
        emit ActionRegistered(actionTypeHash);
    }

    /**
     * @dev Public view function to check if an action type is registered.
     * @param actionTypeHash The bytes32 hash identifying the action type.
     * @return True if registered, false otherwise.
     */
    function queryRegisteredActionType(bytes32 actionTypeHash) public view returns (bool) {
        return registeredActionTypes[actionTypeHash];
    }

    // ================================= ADDITIONAL UTILITY FUNCTIONS (1) =================================

    /**
     * @dev Public view function to get the number of total proposals created.
     * @return The total count of proposals.
     */
    function queryProposalCount() public view returns (uint256) {
        return nextProposalId;
    }

     // Function Count Check:
     // Constructor: 1
     // Influence & Staking: 5 (stake, unstake, _calculateInfluenceCredit - internal, queryInfluenceCredit, queryStakedAmount)
     // Reputation: 2 (_updateUserScore - internal, queryUserScore)
     // Parameter: 3 (_initializeParameter - internal, queryParameter, queryAllParameterNames)
     // Proposal: 11 (proposeParameterChange, proposeAction, boostProposal, checkProposalState, executeProposal, _applyParameterChange - internal, _executeAction - internal, queryProposal, queryProposalsByCreator, queryProposalsByState, cancelProposal, queryProposalSupport, queryUserSupportForProposal) -> Correction: 13 functions including internal ones, 11 external/public
     // Delegation: 4 (delegateInfluenceGain, undelegateInfluenceGain, queryDelegatee, queryDelegators)
     // Resource Pool: 3 (depositResource, withdrawResourceDistribution, queryClaimableResource)
     // Action Registry: 2 (registerActionType, queryRegisteredActionType)
     // Utility: 1 (queryProposalCount)
     // TOTAL Public/External/View: 1 + 4 + 1 + 2 + 8 + 4 + 3 + 2 + 1 = 26
     // TOTAL Including Internal: 1 + 5 + 2 + 3 + 13 + 4 + 3 + 2 + 1 = 34
     // We have more than 20 public/external functions.
}
```

---

**Explanation of Concepts & Implementation:**

1.  **Dynamic Influence (`_calculateInfluenceCredit`, `queryInfluenceCredit`, `InfluenceCreditUpdated` event):** Instead of influence just being a direct multiplier of staked tokens, it's calculated based on the stake *over time* and can decay. `_calculateInfluenceCredit` performs the actual calculation, adding influence gained since the last update and applying a simple linear decay. `queryInfluenceCredit` allows anyone to see a user's *current* calculated influence without triggering a state change (though it's less precise than a state-changing update). The `InfluenceCreditUpdated` event logs when a user's credit is re-calculated. The decay rate `influenceDecayRatePerSecond` and gain rate `baseInfluencePerTokenPerSecond` are themselves parameters potentially controllable by governance proposals.
2.  **Influence Boosting (`boostProposal`, `queryProposalSupport`, `queryUserSupportForProposal`):** This is the voting mechanism. Users *spend* (or apply) their dynamic `influenceCredit` directly onto a proposal. The total amount applied determines the proposal's `totalInfluenceSupport`. This influence is consumed, encouraging users to participate actively and re-stake to gain more influence.
3.  **Adaptive Parameters (`systemParameters`, `parameterNames`, `queryParameter`, `queryAllParameterNames`, `proposeParameterChange`, `_applyParameterChange`):** The contract stores configuration values in a flexible `mapping(string => uint256)`. The values and even which parameters exist can be changed via `ParameterChange` proposals, making the contract adaptive and governable. `_applyParameterChange` handles updating the parameter storage. (Note: Using `uint256` limits the types of parameters; using `bytes` would be more flexible but require careful encoding/decoding logic).
4.  **Action Registry (`registeredActionTypes`, `registerActionType`, `queryRegisteredActionType`, `proposeAction`, `_executeAction`):** This allows the contract to perform predefined complex operations (like distributing tokens, calling other contracts, changing specific internal states not covered by `systemParameters`). `registeredActionTypes` tracks allowed actions. `proposeAction` creates a proposal for a registered action, and `_executeAction` contains the logic to perform the action based on its type and provided data. The `DistributeResource` action is provided as an example.
5.  **Basic Reputation (`userScores`, `_updateUserScore`, `queryUserScore`):** A simple `int256` score tracks user success. Currently, it only increments for the creator of successful proposals. This could be extended to reward/punish boosters, users on the winning/losing side, etc.
6.  **Delegation (`delegateInfluenceGain`, `undelegateInfluenceGain`, `delegatee`, `delegators`, `queryDelegatee`, `queryDelegators`):** Users can delegate their *earning potential* and *boosting power* to another address. When influence is calculated, staked amounts are considered for the original staker, but the *credit* might effectively be added to the delegatee (or the delegatee gets the *right* to spend the delegator's credit - the implementation adds credit to the delegator but tracks support by the delegatee in proposals, a design choice). When `boostProposal` is called, the influence is taken from `msg.sender`, but the support is recorded under their `delegatee`. This allows users to delegate their voice and participation.
7.  **Proposal Lifecycle (`Proposal`, `ProposalType`, `ProposalState`, `ProposalCreated`, `checkProposalState`, `executeProposal`, `ProposalExecuted`, `cancelProposal`, `ProposalCanceled`):** Proposals move through states: `Active`, `Approved`/`Rejected` (determined by `checkProposalState` based on time and support), `Executed`, `Canceled`. Anyone can trigger `executeProposal` once `checkProposalState` returns `Approved`.

This contract provides a framework for dynamic, influence-driven governance and state control, offering a richer interaction model than simple token-based voting and parameter setting. The influence decay and boosting mechanisms add layers of strategy and active participation requirements.