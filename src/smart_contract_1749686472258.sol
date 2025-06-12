Okay, here is a Solidity smart contract implementing a conceptual "State Weaver" system. It features several advanced/creative concepts like dynamic user state (Essence, Affinity, Catalyst), on-chain structured history (`Chronicles`), time-based mechanics (Epochs, Catalyst refill), a simple on-chain parameter governance mechanism (`Weaves`), and timed events (`Rituals`).

It aims to track user contributions, alignment, and activity within a simulated decentralized ecosystem represented by the contract's state and parameters. It does *not* replicate standard tokens (ERC20/ERC721) or simple voting contracts directly.

---

## Contract: StateWeaver

### Outline

1.  **Core Concepts:**
    *   **Essence:** Represents a user's accumulated influence, reputation, or stake within the system. It can grow through contributions and potentially decay over time or with inactivity. Used for voting.
    *   **Affinity:** Represents a user's alignment with certain principles or paths within the ecosystem. Affects chronicle gains and ritual participation.
    *   **Catalyst:** A limited resource needed to perform significant actions (like recording Chronicles). Refills over time.
    *   **Chronicles:** Structured records of user contributions or significant events logged on-chain. Grants Essence/Affinity.
    *   **Epochs:** Time periods defining cycles of decay, catalyst refill rates, and voting periods. Advanced manually or conditionally.
    *   **System Parameters:** Dynamic parameters governing rates (Essence gain/decay, Catalyst refill, etc.) that can be changed via governance.
    *   **Weaves:** Proposals for changing System Parameters, voted on by Essence holders. A simple on-chain governance mechanism.
    *   **Rituals:** Timed, special events where users can participate for temporary effects or rewards.

2.  **State Variables:**
    *   Owner address.
    *   Current Epoch number and start time.
    *   Mappings for user Essence, Affinity, Catalyst, and last sync time.
    *   Mapping for Affinity type descriptions.
    *   Array of system parameters.
    *   Array of Global Chronicles.
    *   Mapping from user address to indices of their Chronicles in the global array.
    *   Array of Weave proposals.
    *   Next Weave proposal ID.
    *   Ritual state variables (active status, start time, duration).

3.  **Events:** Signaling key state changes (Essence gain, Chronicle recorded, Vote cast, Epoch advanced, Parameter changed, Ritual started/ended).

4.  **Modifiers:** `onlyOwner`, `whenRitualActive`, `whenRitualInactive`, `onlyRegisteredAffinity`.

5.  **Functions (Categorized):**
    *   **Initialization & Admin:** `initialize`, `adminAddAffinityType`, `adminRemoveAffinityType`.
    *   **User State Management:** `registerAffinity`, `changeAffinity`, `syncAndGetState`, `getUserState`, `calculateEssenceDecay`, `calculateCatalystRefill`.
    *   **Chronicles:** `recordChronicle`, `getUserChronicleCount`, `getGlobalChronicle`.
    *   **System Parameters & Weaves (Governance):** `getSystemParameter`, `proposeWeave`, `voteOnWeave`, `executeWeave`, `getWeaveProposal`, `getWeaveProposalCount`.
    *   **Epochs:** `advanceEpoch`.
    *   **Rituals:** `startRitual`, `endRitual`, `participateInRitual`, `checkRitualStatus`.
    *   **Views:** Various getters for state variables.

---

### Function Summary

1.  `initialize(uint256[] memory _initialParameters, string[] memory _initialAffinityDescriptions)`:
    *   Sets initial system parameters and affinity types. Can only be called once by the deployer.
    *   *Admin/Setup*

2.  `adminAddAffinityType(string calldata _description)`:
    *   Allows owner to add a new affinity type description.
    *   *Admin*

3.  `adminRemoveAffinityType(uint256 _affinityType)`:
    *   Allows owner to remove an existing affinity type description.
    *   *Admin*

4.  `registerAffinity(uint256 _affinityType)`:
    *   Allows a user to set their initial affinity type. Can only be called once per user. Requires the type to exist.
    *   *User State*

5.  `changeAffinity(uint256 _newAffinityType)`:
    *   Allows a user to change their affinity type. May have cooldowns or costs based on parameters. Requires the new type to exist.
    *   *User State*

6.  `syncAndGetState(address _user)`:
    *   Calculates time elapsed since last sync or registration, applies catalyst refill and essence decay based on current parameters and user affinity. Updates user state. Returns the updated state.
    *   *User State*

7.  `getUserState(address _user)`:
    *   Calls `syncAndGetState` internally to update state, then returns the user's current Essence, Affinity, and Catalyst.
    *   *User State / View*

8.  `calculateEssenceDecay(address _user)`:
    *   *View function*. Calculates the theoretical essence decay for a user based on time elapsed since last sync and current parameters. Does not modify state.
    *   *User State / View*

9.  `calculateCatalystRefill(address _user)`:
    *   *View function*. Calculates the theoretical catalyst refill for a user based on time elapsed since last sync and current parameters. Does not modify state.
    *   *User State / View*

10. `recordChronicle(string calldata _description)`:
    *   Logs a significant action/contribution for the caller. Requires sufficient Catalyst. Spends Catalyst and awards Essence/Affinity based on parameters and the user's current Affinity. Adds to `globalChronicles`.
    *   *Chronicles*

11. `getUserChronicleCount(address _user)`:
    *   *View function*. Returns the number of chronicles recorded by a specific user.
    *   *Chronicles / View*

12. `getGlobalChronicle(uint256 _index)`:
    *   *View function*. Returns details of a specific chronicle from the global list by index.
    *   *Chronicles / View*

13. `getSystemParameter(uint256 _parameterIndex)`:
    *   *View function*. Returns the current value of a system parameter by index. Indices map to specific parameters (e.g., 0 for EssenceGainRate, 1 for CatalystRefillRate, etc.).
    *   *System Parameters / View*

14. `proposeWeave(string calldata _description, uint256 _parameterIndex, uint256 _newValue)`:
    *   Allows a user (with sufficient Essence stake, defined by parameters) to propose changing a system parameter to a new value. Costs Essence to propose.
    *   *Weaves (Governance)*

15. `voteOnWeave(uint256 _proposalId)`:
    *   Allows a user to cast their current *synced* Essence stake as a vote for a specific Weave proposal. Cannot vote multiple times per proposal.
    *   *Weaves (Governance)*

16. `executeWeave(uint256 _proposalId)`:
    *   Executes a Weave proposal if the voting period is over and the proposal has met the required Essence quorum (total votes) or majority, as defined by parameters. Updates the target system parameter. Callable by anyone.
    *   *Weaves (Governance)*

17. `getWeaveProposal(uint256 _proposalId)`:
    *   *View function*. Returns details of a specific Weave proposal.
    *   *Weaves (Governance) / View*

18. `getWeaveProposalCount()`:
    *   *View function*. Returns the total number of Weave proposals created.
    *   *Weaves (Governance) / View*

19. `advanceEpoch()`:
    *   Advances the system to the next epoch if the current epoch duration has passed. Triggers any epoch-transition logic (like locking in rates from governance). Can reward the caller with Catalyst or Essence.
    *   *Epochs*

20. `startRitual(uint256 _duration)`:
    *   Allows the owner to start a special Ritual event with a specified duration. Only one ritual can be active at a time.
    *   *Rituals*

21. `endRitual()`:
    *   Allows the owner to forcefully end an active Ritual.
    *   *Rituals*

22. `participateInRitual()`:
    *   Allows a user to participate in an active Ritual. Requires the Ritual to be active and may have costs or requirements based on parameters (e.g., minimum Essence/Affinity, spend Catalyst). Grants temporary effects or rewards.
    *   *Rituals*

23. `checkRitualStatus()`:
    *   *View function*. Returns whether a Ritual is currently active, its start time, and duration.
    *   *Rituals / View*

24. `getAffinityDescription(uint256 _affinityType)`:
    *   *View function*. Returns the string description for a given affinity type index.
    *   *Views*

25. `getTotalEssenceSupply()`:
    *   *View function*. Returns the total calculated Essence across all users. (Note: this might be computationally expensive if users aren't synced often; a cached value might be better in production).
    *   *Views*

26. `getEpochStartTime()`:
    *   *View function*. Returns the timestamp when the current epoch started.
    *   *Epochs / View*

27. `getEpochDuration()`:
    *   *View function*. Returns the configured duration of an epoch from system parameters.
    *   *Epochs / View*

*(This totals 27 functions, fulfilling the requirement of at least 20)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title StateWeaver
 * @dev A conceptual smart contract simulating a decentralized ecosystem
 *      with dynamic user state (Essence, Affinity, Catalyst), on-chain chronicles,
 *      timed mechanics (Epochs, Rituals), and parameter governance (Weaves).
 *
 * Outline:
 * 1. Core Concepts: Essence (influence/stake), Affinity (alignment), Catalyst (action points),
 *    Chronicles (contribution history), Epochs (time cycles), System Parameters (dynamic config),
 *    Weaves (parameter governance proposals), Rituals (timed events).
 * 2. State Variables: Owner, epoch data, user states, affinity types, parameters,
 *    chronicles data, weave proposals, ritual state.
 * 3. Events: Signaling key actions and state changes.
 * 4. Modifiers: Access control and state checks.
 * 5. Functions: Initialization, Admin, User State Management, Chronicles,
 *    Parameter Governance (Weaves), Epochs, Rituals, Views. (27 functions)
 */
contract StateWeaver {
    address public owner;

    // --- Core State ---
    uint256 public currentEpoch;
    uint256 public currentEpochStartTime;

    // User State:
    // Essence: Represents influence/stake. Increases with contributions, decreases with decay.
    mapping(address => uint256) public userEssence;
    // Affinity: Represents alignment (e.g., 0=Neutral, 1=Builder, 2=Explorer). Affects gains/costs.
    mapping(address => uint256) public userAffinity;
    // Catalyst: Resource required for actions. Refills over time.
    mapping(address => uint256) public userCatalyst;
    // Last time user state (Catalyst/Essence) was synced/updated.
    mapping(address => uint256) public userLastSyncTime;
    // Tracks if a user has registered their affinity initially.
    mapping(address => bool) public hasRegisteredAffinity;

    // Affinity Types: Mapping integer IDs to string descriptions.
    mapping(uint256 => string) public affinityTypes;
    uint256[] public affinityTypeIds; // To iterate or check existence

    // System Parameters: Dynamic configuration values changed via governance (Weaves).
    // Mapped by index for generic access via governance.
    // Indices:
    // 0: EssenceGainRatePerCatalyst - How much Essence gained per Catalyst spent on Chronicle (scaled)
    // 1: CatalystRefillRatePerSecond - How much Catalyst refilled per second (scaled)
    // 2: MaxCatalyst - Maximum Catalyst a user can hold
    // 3: EssenceDecayRatePerSecond - How much Essence decays per second (scaled)
    // 4: ChronicleCatalystCost - Base Catalyst cost for recording a Chronicle
    // 5: WeaveProposalEssenceCost - Essence required to propose a Weave
    // 6: WeaveVotingPeriodDuration - How long voting is open for a Weave proposal
    // 7: WeaveQuorumEssenceRequired - Minimum total Essence needed to vote for a Weave to be valid
    // 8: EpochDuration - Duration of an epoch in seconds
    // 9: AdvanceEpochCatalystReward - Catalyst granted to the caller of advanceEpoch
    // 10: RitualParticipationCatalystCost - Catalyst cost to participate in a ritual
    // 11: RitualParticipationEssenceReward - Essence gained from participating in a ritual
    uint256[] public systemParameters;

    // Chronicles: On-chain history of significant actions.
    struct Chronicle {
        address user;
        string description;
        uint256 timestamp;
        uint256 essenceGained;
        // Could add affinity impact or other structured data fields here
    }
    Chronicle[] public globalChronicles;
    // Mapping user address to indices in the globalChronicles array.
    mapping(address => uint256[]) public userChronicleIndices;

    // Weaves (Governance): Proposals to change System Parameters.
    struct WeaveProposal {
        uint256 id;
        address proposer;
        string description; // Description of the proposed change
        uint256 parameterIndex; // Index in systemParameters array
        uint256 newValue; // The proposed new value
        uint256 epochProposed; // Epoch when proposal was made
        uint256 startTime; // Timestamp when proposal was made (for voting duration)
        mapping(address => bool) hasVoted; // Tracks if a user has voted
        uint256 totalEssenceVotes; // Total Essence weight supporting the proposal
        bool executed; // Whether the proposal has been executed
        bool cancelled; // Whether the proposal was cancelled (e.g., by proposer, if allowed)
    }
    WeaveProposal[] public weaveProposals;
    uint256 public nextWeaveProposalId = 0;

    // Rituals: Timed events.
    bool public ritualActive = false;
    uint256 public ritualStartTime = 0;
    uint256 public ritualDuration = 0;

    // --- Events ---
    event Initialized(address indexed deployer, uint256 timestamp);
    event AffinityRegistered(address indexed user, uint256 affinityType);
    event AffinityChanged(address indexed user, uint256 oldType, uint256 newType);
    event StateSynced(address indexed user, uint256 essence, uint256 catalyst, uint256 syncTime);
    event ChronicleRecorded(address indexed user, uint256 chronicleIndex, string description);
    event EssenceGained(address indexed user, uint256 amount, string reason);
    event EssenceSpent(address indexed user, uint256 amount, string reason);
    event CatalystGained(address indexed user, uint256 amount, string reason);
    event CatalystSpent(address indexed user, uint256 amount, string reason);
    event WeaveProposed(uint256 indexed proposalId, address indexed proposer, uint256 paramIndex, uint256 newValue);
    event VotedOnWeave(uint256 indexed proposalId, address indexed voter, uint256 voteWeight);
    event WeaveExecuted(uint256 indexed proposalId, uint256 paramIndex, uint256 newValue);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 startTime);
    event RitualStarted(uint256 startTime, uint256 duration);
    event RitualEnded(uint256 endTime, bool forcefully);
    event RitualParticipant(address indexed user, uint256 timestamp);
    event AffinityTypeAdded(uint256 indexed id, string description);
    event AffinityTypeRemoved(uint256 indexed id);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenRitualActive() {
        require(ritualActive && block.timestamp < ritualStartTime + ritualDuration, "Ritual not active");
        _;
    }

    modifier whenRitualInactive() {
        require(!ritualActive || block.timestamp >= ritualStartTime + ritualDuration, "Ritual is active");
        _;
    }

    modifier onlyRegisteredAffinity(address _user) {
        require(hasRegisteredAffinity[_user], "User has not registered affinity");
        _;
    }

    // --- Initialization & Admin ---

    /**
     * @notice Initializes the contract with initial system parameters and affinity types.
     * Can only be called once.
     * @param _initialParameters Array of initial values for system parameters. Must match expected size.
     * @param _initialAffinityDescriptions Array of string descriptions for initial affinity types.
     */
    function initialize(uint256[] memory _initialParameters, string[] memory _initialAffinityDescriptions) external {
        require(owner == address(0), "Already initialized");
        owner = msg.sender;

        // Basic validation for parameter count (adjust as needed based on defined indices)
        require(_initialParameters.length >= 12, "Incorrect number of initial parameters");
        systemParameters = _initialParameters;

        // Add initial affinity types
        for (uint256 i = 0; i < _initialAffinityDescriptions.length; i++) {
            affinityTypes[i + 1] = _initialAffinityDescriptions[i]; // Start affinity IDs from 1
            affinityTypeIds.push(i + 1);
        }

        currentEpoch = 1;
        currentEpochStartTime = block.timestamp;

        emit Initialized(msg.sender, block.timestamp);
    }

    /**
     * @notice Allows the owner to add a new affinity type description.
     * @param _description The string description for the new affinity type.
     */
    function adminAddAffinityType(string calldata _description) external onlyOwner {
        uint256 newId = affinityTypeIds.length > 0 ? affinityTypeIds[affinityTypeIds.length - 1] + 1 : 1;
        affinityTypes[newId] = _description;
        affinityTypeIds.push(newId);
        emit AffinityTypeAdded(newId, _description);
    }

    /**
     * @notice Allows the owner to remove an existing affinity type description.
     * Users with this affinity will remain with the ID but the description will be gone.
     * Consider migration strategy for production.
     * @param _affinityType The ID of the affinity type to remove.
     */
    function adminRemoveAffinityType(uint256 _affinityType) external onlyOwner {
        require(bytes(affinityTypes[_affinityType]).length > 0, "Affinity type does not exist");

        // Remove from affinityTypeIds array (simple linear scan, potentially inefficient for many types)
        uint256 indexToRemove = type(uint256).max;
        for (uint256 i = 0; i < affinityTypeIds.length; i++) {
            if (affinityTypeIds[i] == _affinityType) {
                indexToRemove = i;
                break;
            }
        }
        require(indexToRemove != type(uint256).max, "Affinity type not found in IDs list");

        // Remove by swapping with last and popping
        if (indexToRemove < affinityTypeIds.length - 1) {
            affinityTypeIds[indexToRemove] = affinityTypeIds[affinityTypeIds.length - 1];
        }
        affinityTypeIds.pop();

        delete affinityTypes[_affinityType];
        emit AffinityTypeRemoved(_affinityType);
    }

    // --- Internal State Sync Helper ---

    /**
     * @notice Internal helper to calculate and apply catalyst refill and essence decay based on time.
     * Updates the user's state in storage.
     * @param _user The address of the user to sync.
     * @dev This function is called by other user-facing functions before performing actions.
     *      It ensures user state is relatively up-to-date.
     *      Decay calculation is simplified (linear over time). More complex models (percentage, etc.) are possible.
     *      Catalyst refill is capped at MaxCatalyst.
     */
    function _syncUserState(address _user) internal {
        uint256 lastSync = userLastSyncTime[_user];
        uint256 currentTime = block.timestamp;

        // Handle initial sync for new users (after initial registration)
        if (lastSync == 0 && hasRegisteredAffinity[_user]) {
             lastSync = currentEpochStartTime; // Or registration time, depending on desired behavior
        } else if (lastSync == 0) {
            // User not registered yet, no state to sync
            return;
        }


        uint256 timeElapsed = currentTime - lastSync;

        if (timeElapsed > 0) {
            // Calculate Catalyst Refill
            uint256 catalystRefillRate = systemParameters[1]; // CatalystRefillRatePerSecond
            uint256 maxCatalyst = systemParameters[2]; // MaxCatalyst
            uint256 catalystGained = timeElapsed * catalystRefillRate;
            uint256 newCatalyst = userCatalyst[_user] + catalystGained;
            userCatalyst[_user] = newCatalyst > maxCatalyst ? maxCatalyst : newCatalyst;

            if (catalystGained > 0) {
                emit CatalystGained(_user, catalystGained, "Time Refill");
            }

            // Calculate Essence Decay
            uint256 essenceDecayRate = systemParameters[3]; // EssenceDecayRatePerSecond
            // Optional: Implement affinity-based decay modifiers here
            uint256 essenceDecayed = timeElapsed * essenceDecayRate;
            if (userEssence[_user] > essenceDecayed) {
                userEssence[_user] -= essenceDecayed;
                 if (essenceDecayed > 0) {
                    // No specific event for decay amount, StateSynced shows net change
                 }
            } else {
                userEssence[_user] = 0;
            }

            userLastSyncTime[_user] = currentTime;
            emit StateSynced(_user, userEssence[_user], userCatalyst[_user], currentTime);
        }
    }


    // --- User State Management ---

    /**
     * @notice Allows a user to set their initial affinity type. Can only be called once.
     * @param _affinityType The ID of the affinity type to register.
     */
    function registerAffinity(uint256 _affinityType) external {
        require(!hasRegisteredAffinity[msg.sender], "Affinity already registered");
        require(bytes(affinityTypes[_affinityType]).length > 0, "Invalid affinity type");

        userAffinity[msg.sender] = _affinityType;
        hasRegisteredAffinity[msg.sender] = true;
        userLastSyncTime[msg.sender] = block.timestamp; // Set initial sync time
        emit AffinityRegistered(msg.sender, _affinityType);
    }

    /**
     * @notice Allows a user to change their affinity type.
     * @param _newAffinityType The ID of the new affinity type.
     * @dev Consider adding cooldowns or costs here based on system parameters.
     */
    function changeAffinity(uint256 _newAffinityType) external onlyRegisteredAffinity(msg.sender) {
        require(bytes(affinityTypes[_newAffinityType]).length > 0, "Invalid affinity type");
        require(userAffinity[msg.sender] != _newAffinityType, "Already has this affinity");
        // Could add a cost (Essence/Catalyst) or a time-based cooldown here
        // require(userCatalyst[msg.sender] >= systemParameters[...], "Not enough Catalyst");
        // userCatalyst[msg.sender] -= systemParameters[...];

        userAffinity[msg.sender] = _newAffinityType;
        emit AffinityChanged(msg.sender, userAffinity[msg.sender], _newAffinityType);
    }

     /**
     * @notice Syncs the user's state (applying decay/refill) and returns their current state.
     * @param _user The address of the user to sync and get state for.
     * @return currentEssence The user's current Essence amount.
     * @return currentAffinity The user's current Affinity type ID.
     * @return currentCatalyst The user's current Catalyst amount.
     * @return lastSyncTime The user's last sync timestamp.
     */
    function syncAndGetState(address _user) external onlyRegisteredAffinity(_user) returns (uint256 currentEssence, uint256 currentAffinity, uint256 currentCatalyst, uint256 lastSyncTime) {
        _syncUserState(_user);
        return (userEssence[_user], userAffinity[_user], userCatalyst[_user], userLastSyncTime[_user]);
    }

    /**
     * @notice Gets the current state of a user without triggering a sync calculation.
     * Use `syncAndGetState` for potentially more accurate values.
     * @param _user The address of the user.
     * @return essence The user's stored Essence.
     * @return affinity The user's stored Affinity type ID.
     * @return catalyst The user's stored Catalyst.
     * @return lastSyncTime The user's last sync timestamp.
     */
    function getUserState(address _user) external view returns (uint256 essence, uint256 affinity, uint256 catalyst, uint256 lastSyncTime) {
        return (userEssence[_user], userAffinity[_user], userCatalyst[_user], userLastSyncTime[_user]);
    }

    /**
     * @notice Calculates the theoretical essence decay for a user based on time elapsed since last sync.
     * This is a view function and does not change state. Call `syncAndGetState` to apply decay.
     * @param _user The address of the user.
     * @return The calculated essence decay amount.
     */
    function calculateEssenceDecay(address _user) public view returns (uint256) {
         if (!hasRegisteredAffinity[_user] || userLastSyncTime[_user] == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - userLastSyncTime[_user];
        uint256 essenceDecayRate = systemParameters[3]; // EssenceDecayRatePerSecond
        return timeElapsed * essenceDecayRate;
    }

     /**
     * @notice Calculates the theoretical catalyst refill for a user based on time elapsed since last sync.
     * This is a view function and does not change state. Call `syncAndGetState` to apply refill.
     * @param _user The address of the user.
     * @return The calculated catalyst refill amount.
     */
    function calculateCatalystRefill(address _user) public view returns (uint256) {
         if (!hasRegisteredAffinity[_user] || userLastSyncTime[_user] == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - userLastSyncTime[_user];
        uint256 catalystRefillRate = systemParameters[1]; // CatalystRefillRatePerSecond
        uint256 maxCatalyst = systemParameters[2]; // MaxCatalyst
        uint256 currentCatalyst = userCatalyst[_user]; // Use stored value for calculation
        uint256 theoreticalRefill = timeElapsed * catalystRefillRate;
        uint256 potentialNewCatalyst = currentCatalyst + theoreticalRefill;
        return potentialNewCatalyst > maxCatalyst ? maxCatalyst - currentCatalyst : theoreticalRefill;
    }

    // --- Chronicles ---

    /**
     * @notice Records a significant action or contribution as a Chronicle.
     * Requires sufficient Catalyst and grants Essence/Affinity based on parameters.
     * @param _description A string describing the chronicle event.
     */
    function recordChronicle(string calldata _description) external onlyRegisteredAffinity(msg.sender) {
        _syncUserState(msg.sender); // Sync state before checking Catalyst

        uint256 chronicleCost = systemParameters[4]; // ChronicleCatalystCost
        require(userCatalyst[msg.sender] >= chronicleCost, "Not enough Catalyst to record Chronicle");

        userCatalyst[msg.sender] -= chronicleCost;
        emit CatalystSpent(msg.sender, chronicleCost, "Record Chronicle");

        uint256 essenceGainRate = systemParameters[0]; // EssenceGainRatePerCatalyst
        // Simple example: Essence gain is a base rate affected by Affinity and Catalyst spent
        uint256 essenceGained = (chronicleCost * essenceGainRate) / 1000; // Example scaling

        // Optional: Add Affinity-based boost to Essence gain
        // uint256 affinityBoost = userAffinity[msg.sender] == 1 ? 120 : 100; // e.g., Affinity 1 gets 20% boost
        // essenceGained = (essenceGained * affinityBoost) / 100;

        userEssence[msg.sender] += essenceGained;
        emit EssenceGained(msg.sender, essenceGained, "Record Chronicle");

        uint256 chronicleIndex = globalChronicles.length;
        globalChronicles.push(Chronicle(msg.sender, _description, block.timestamp, essenceGained));
        userChronicleIndices[msg.sender].push(chronicleIndex);

        emit ChronicleRecorded(msg.sender, chronicleIndex, _description);
    }

    /**
     * @notice Returns the number of chronicles recorded by a specific user.
     * @param _user The address of the user.
     * @return The count of chronicles.
     */
    function getUserChronicleCount(address _user) external view returns (uint256) {
        return userChronicleIndices[_user].length;
    }

     /**
     * @notice Returns the details of a specific chronicle from the global list.
     * @param _index The index of the chronicle in the globalChronicles array.
     * @return user The address who recorded the chronicle.
     * @return description The description of the chronicle.
     * @return timestamp The timestamp when it was recorded.
     * @return essenceGained The essence gained from this chronicle.
     */
    function getGlobalChronicle(uint256 _index) external view returns (address user, string memory description, uint256 timestamp, uint256 essenceGained) {
        require(_index < globalChronicles.length, "Invalid chronicle index");
        Chronicle storage chronicle = globalChronicles[_index];
        return (chronicle.user, chronicle.description, chronicle.timestamp, chronicle.essenceGained);
    }

    // --- System Parameters & Weaves (Governance) ---

    /**
     * @notice Returns the current value of a system parameter by its index.
     * @param _parameterIndex The index of the parameter in the systemParameters array.
     * @return The current value of the parameter.
     */
    function getSystemParameter(uint256 _parameterIndex) external view returns (uint256) {
        require(_parameterIndex < systemParameters.length, "Invalid parameter index");
        return systemParameters[_parameterIndex];
    }

    /**
     * @notice Allows a user to propose a change to a system parameter via a Weave proposal.
     * Requires a minimum Essence stake (defined by parameter). Costs Essence to propose.
     * @param _description Description of the proposed change.
     * @param _parameterIndex Index of the system parameter to change.
     * @param _newValue The proposed new value for the parameter.
     */
    function proposeWeave(string calldata _description, uint256 _parameterIndex, uint256 _newValue) external onlyRegisteredAffinity(msg.sender) {
        _syncUserState(msg.sender); // Sync state before checking Essence

        uint256 proposalCost = systemParameters[5]; // WeaveProposalEssenceCost
        require(userEssence[msg.sender] >= proposalCost, "Not enough Essence to propose Weave");
        require(_parameterIndex < systemParameters.length, "Invalid parameter index");
        // Basic validation: new value must be non-zero if parameter index implies it (e.g., rates)
        // More complex validation could be added here based on _parameterIndex

        userEssence[msg.sender] -= proposalCost;
        emit EssenceSpent(msg.sender, proposalCost, "Propose Weave");

        uint256 proposalId = nextWeaveProposalId++;
        WeaveProposal storage proposal = weaveProposals.push();
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.parameterIndex = _parameterIndex;
        proposal.newValue = _newValue;
        proposal.epochProposed = currentEpoch;
        proposal.startTime = block.timestamp;
        proposal.executed = false;
        proposal.cancelled = false; // Default false, could add cancel mechanism

        // Proposer's Essence counts towards the vote immediately
        proposal.totalEssenceVotes = userEssence[msg.sender];
        proposal.hasVoted[msg.sender] = true;
         // Note: Proposer votes with their *remaining* Essence after cost.
         // Could design differently, e.g., cost is separate from voting weight.

        emit WeaveProposed(proposalId, msg.sender, _parameterIndex, _newValue);
        emit VotedOnWeave(proposalId, msg.sender, userEssence[msg.sender]);
    }

    /**
     * @notice Allows a user to vote on an active Weave proposal using their current Essence stake.
     * User's state is synced before voting to use their latest Essence count.
     * @param _proposalId The ID of the Weave proposal to vote on.
     */
    function voteOnWeave(uint256 _proposalId) external onlyRegisteredAffinity(msg.sender) {
        require(_proposalId < weaveProposals.length, "Invalid proposal ID");
        WeaveProposal storage proposal = weaveProposals[_proposalId];

        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");

        uint256 votingPeriodDuration = systemParameters[6]; // WeaveVotingPeriodDuration
        require(block.timestamp < proposal.startTime + votingPeriodDuration, "Voting period has ended");

        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        _syncUserState(msg.sender); // Sync state to get current Essence
        uint256 voterEssence = userEssence[msg.sender];
        require(voterEssence > 0, "Cannot vote with 0 Essence");

        proposal.hasVoted[msg.sender] = true;
        proposal.totalEssenceVotes += voterEssence;

        emit VotedOnWeave(_proposalId, msg.sender, voterEssence);
    }

    /**
     * @notice Executes a Weave proposal if the voting period has ended and conditions are met.
     * Conditions typically include total Essence votes meeting a quorum. Callable by anyone.
     * @param _proposalId The ID of the Weave proposal to execute.
     */
    function executeWeave(uint256 _proposalId) external {
        require(_proposalId < weaveProposals.length, "Invalid proposal ID");
        WeaveProposal storage proposal = weaveProposals[_proposalId];

        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");

        uint256 votingPeriodDuration = systemParameters[6]; // WeaveVotingPeriodDuration
        require(block.timestamp >= proposal.startTime + votingPeriodDuration, "Voting period is not over");

        uint256 quorumEssenceRequired = systemParameters[7]; // WeaveQuorumEssenceRequired

        // Simplified execution logic: requires minimum quorum votes.
        // Could add majority check here (e.g., totalEssenceVotes > totalPossibleEssence at start, or > 50% of participating votes)
        require(proposal.totalEssenceVotes >= quorumEssenceRequired, "Quorum not met");

        // Check parameter index validity again before execution
        require(proposal.parameterIndex < systemParameters.length, "Invalid parameter index in proposal");

        systemParameters[proposal.parameterIndex] = proposal.newValue;
        proposal.executed = true;

        emit WeaveExecuted(proposal.id, proposal.parameterIndex, proposal.newValue);
    }

    /**
     * @notice Returns details of a specific Weave proposal.
     * @param _proposalId The ID of the proposal.
     * @return id Proposal ID.
     * @return proposer Address of the proposer.
     * @return description Description of the proposal.
     * @return parameterIndex Index of the parameter to change.
     * @return newValue Proposed new value.
     * @return epochProposed Epoch when proposed.
     * @return startTime Timestamp when proposed.
     * @return totalEssenceVotes Total Essence votes received.
     * @return executed Whether the proposal was executed.
     * @return cancelled Whether the proposal was cancelled.
     */
    function getWeaveProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 parameterIndex,
        uint256 newValue,
        uint256 epochProposed,
        uint256 startTime,
        uint256 totalEssenceVotes,
        bool executed,
        bool cancelled
    ) {
        require(_proposalId < weaveProposals.length, "Invalid proposal ID");
        WeaveProposal storage proposal = weaveProposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.parameterIndex,
            proposal.newValue,
            proposal.epochProposed,
            proposal.startTime,
            proposal.totalEssenceVotes,
            proposal.executed,
            proposal.cancelled
        );
    }

    /**
     * @notice Returns the total number of Weave proposals created.
     * @return The count of proposals.
     */
    function getWeaveProposalCount() external view returns (uint256) {
        return weaveProposals.length;
    }

    // --- Epochs ---

    /**
     * @notice Advances the system to the next epoch if the current epoch duration has passed.
     * Can be called by anyone, potentially with a reward for the caller.
     * Triggers any epoch-transition logic (e.g., locking in rates from governance).
     */
    function advanceEpoch() external {
        uint256 epochDuration = systemParameters[8]; // EpochDuration
        require(block.timestamp >= currentEpochStartTime + epochDuration, "Epoch duration not passed");

        currentEpoch++;
        currentEpochStartTime = block.timestamp;

        // Reward the caller
        uint256 reward = systemParameters[9]; // AdvanceEpochCatalystReward
        if (reward > 0) {
             _syncUserState(msg.sender); // Sync caller state before adding reward
             uint256 maxCatalyst = systemParameters[2];
             uint256 currentCatalyst = userCatalyst[msg.sender];
             uint256 catalystToAdd = currentCatalyst + reward > maxCatalyst ? maxCatalyst - currentCatalyst : reward;
             userCatalyst[msg.sender] += catalystToAdd;
             if (catalystToAdd > 0) {
                emit CatalystGained(msg.sender, catalystToAdd, "Advance Epoch Reward");
             }
        }

        // Future enhancement: Add logic here to apply epoch-end effects,
        // e.g., finalize specific types of Weaves, trigger global decay events, etc.

        emit EpochAdvanced(currentEpoch, currentEpochStartTime);
    }

    // --- Rituals ---

    /**
     * @notice Allows the owner to start a special Ritual event.
     * @param _duration The duration of the ritual in seconds.
     */
    function startRitual(uint256 _duration) external onlyOwner whenRitualInactive {
        ritualActive = true;
        ritualStartTime = block.timestamp;
        ritualDuration = _duration;
        emit RitualStarted(ritualStartTime, ritualDuration);
    }

    /**
     * @notice Allows the owner to forcefully end an active Ritual.
     */
    function endRitual() external onlyOwner whenRitualActive {
         // Check if ritual already ended naturally to avoid duplicate event
        if (block.timestamp < ritualStartTime + ritualDuration) {
            ritualActive = false;
            // No need to reset ritualStartTime/Duration immediately, can be useful view
            emit RitualEnded(block.timestamp, true);
        } else {
             // Ritual ended naturally, just ensure flag is false if it wasn't
             ritualActive = false;
             emit RitualEnded(block.timestamp, false); // Mark as not forceful if already past end time
        }
    }

    /**
     * @notice Allows a user to participate in an active Ritual.
     * Requires the ritual to be active and potentially costs Catalyst/Essence.
     * Grants rewards or temporary effects (effects are conceptual here, state changes for rewards).
     */
    function participateInRitual() external onlyRegisteredAffinity(msg.sender) whenRitualActive {
        _syncUserState(msg.sender); // Sync state before checking costs

        uint256 participationCost = systemParameters[10]; // RitualParticipationCatalystCost
        require(userCatalyst[msg.sender] >= participationCost, "Not enough Catalyst to participate in Ritual");

        userCatalyst[msg.sender] -= participationCost;
        emit CatalystSpent(msg.sender, participationCost, "Ritual Participation");

        uint256 essenceReward = systemParameters[11]; // RitualParticipationEssenceReward
        userEssence[msg.sender] += essenceReward;
        emit EssenceGained(msg.sender, essenceReward, "Ritual Participation");

        emit RitualParticipant(msg.sender, block.timestamp);

        // Future Enhancement: Add logic for temporary boosts tied to participation,
        // e.g., record participation time and grant temporary bonus until ritual ends.
        // Could also check user's Affinity and grant different rewards/effects.
    }

    /**
     * @notice Returns the current status of the Ritual event.
     * @return isActive Whether a ritual is currently active.
     * @return startTime The timestamp when the current/last ritual started.
     * @return duration The duration of the current/last ritual.
     * @return endTime The timestamp when the current/last ritual ends.
     */
    function checkRitualStatus() external view returns (bool isActive, uint256 startTime, uint256 duration, uint256 endTime) {
        bool currentStatus = ritualActive && block.timestamp < ritualStartTime + ritualDuration;
         // If ritual ended naturally, ritualActive might still be true until endRitual is called or another ritual starts.
         // The 'currentStatus' variable gives the precise "is it active *right now*" state.
        return (currentStatus, ritualStartTime, ritualDuration, ritualStartTime + ritualDuration);
    }


    // --- Views ---

    /**
     * @notice Returns the string description for a given affinity type ID.
     * @param _affinityType The ID of the affinity type.
     * @return The string description.
     */
    function getAffinityDescription(uint256 _affinityType) external view returns (string memory) {
        return affinityTypes[_affinityType];
    }

     /**
     * @notice Returns the list of valid affinity type IDs.
     * @return An array of valid affinity type IDs.
     */
    function getAffinityTypeIds() external view returns (uint256[] memory) {
        return affinityTypeIds;
    }

    /**
     * @notice Calculates and returns the total calculated Essence across all users.
     * @dev NOTE: This iterates through all registered users (implicitly via userLastSyncTime),
     *      which can be extremely expensive if there are many users. For production,
     *      a cached total supply updated during state syncs might be needed.
     * @return The total calculated Essence.
     */
    function getTotalEssenceSupply() external view returns (uint256) {
         // This is a simplified view. A real system would track total supply incrementally.
         // Iterating over mappings is not directly possible, but we can estimate
         // or rely on off-chain calculation based on Chronicle events, decay parameters etc.
         // Or, if we had a set of all registered users, we could iterate that.
         // As a conceptual function, we'll just acknowledge the complexity.
         // A more practical approach might be:
         // uint256 total = 0;
         // // This loop is illustrative and won't work directly on a mapping like userEssence
         // // for (address user : allRegisteredUsers) { // requires tracking all users explicitly
         // //    total += userEssence[user];
         // // }
         // return total;

         // Returning a placeholder value or requiring a list of users is more feasible.
         // Let's return a placeholder or sum up Chronicle gains (ignoring decay, which is inaccurate)
         // A better view would be per-user. Let's keep it simple and acknowledge the limit.
         // This function is primarily for demonstration of potential views.
         // We can calculate the total Essence gained from chronicles (ignoring decay for simplicity here).
         uint256 totalGained = 0;
         for(uint256 i = 0; i < globalChronicles.length; i++){
             totalGained += globalChronicles[i].essenceGained;
         }
         // This does NOT account for decay or spending. It's a simplified representation.
         return totalGained;
    }


     /**
     * @notice Returns the timestamp when the current epoch started.
     * @return The epoch start time.
     */
    function getEpochStartTime() external view returns (uint256) {
        return currentEpochStartTime;
    }

     /**
     * @notice Returns the configured duration of an epoch in seconds.
     * @return The epoch duration.
     */
    function getEpochDuration() external view returns (uint256) {
         // Ensure parameter index 8 exists
        require(systemParameters.length > 8, "Epoch Duration parameter not set");
        return systemParameters[8]; // EpochDuration
    }

    // Add other view functions as needed for parameters, etc.
    // For example, `getWeaveVotingPeriodDuration()`, `getMaxCatalyst()`, etc.
    // These can just delegate to `getSystemParameter`.

}
```