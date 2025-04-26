Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts beyond standard templates. It focuses on "Mutable Digital Artifacts" (MDAs) which are unique assets whose state and capabilities can change based on user reputation, time, interaction, and meeting specific on-chain conditions.

**Theme:** A system where unique digital assets (Artifacts) are not static but evolve, decay, combine, and unlock functionality based on dynamic rules tied to owner interaction and reputation.

**Concepts Covered:**
1.  **Dynamic NFTs/Assets:** Artifacts have changing states and properties.
2.  **On-Chain Reputation System:** Users have a mutable reputation score affecting their abilities.
3.  **Conditional Execution:** Functions require specific artifact states, user reputation, or time-based conditions to succeed.
4.  **Time-Based Mechanics:** Artifact states or parameters change based on elapsed time.
5.  **Asset Combination/Forging:** Burning multiple artifacts to create a new one.
6.  **Delegated Control:** Granting temporary, limited control of an artifact.
7.  **Decentralized State Triggering:** Allowing anyone to trigger state changes (like decay) if conditions are met.
8.  **Role-Based Access (Implicit):** Certain actions require owner privilege or specific reputation/achievement thresholds.
9.  **Structs and Enums:** Complex data modeling.
10. **Mapping Manipulation:** Storing and updating complex relationships (artifact data, ownership, reputation, conditions, delegations).
11. **Error Handling:** Using custom errors for clarity.
12. **Events:** Emitting logs for key state changes.
13. **View Functions:** Providing read-only access to contract state.
14. **State Transitions:** Defining valid paths for artifact evolution/decay.
15. **Provenance Tracking (Basic):** Recording the initial creator.
16. **Parameter Tuning:** Owner adjustable parameters for mechanics (e.g., base reputation).
17. **ERC-721 Inspired (but custom):** Manages unique token IDs and ownership, but with custom logic instead of full interface implementation.
18. **Function Selectors (`bytes4`):** Using selectors to identify functions for conditional access rules.
19. **Basic Access Control (`Ownable`):** For administrative functions.
20. **Withdrawal Pattern:** Safe handling of collected Ether (if any).

---

**Outline:**

1.  **Pragma and Imports**
2.  **Errors**
3.  **Events**
4.  **Enums** (MDAState)
5.  **Structs** (MDA, ActionCondition)
6.  **State Variables** (Owner, Counters, Mappings for Artifacts, Owners, Reputation, Achievements, Conditions, Delegations, Parameters)
7.  **Constructor**
8.  **Modifiers** (Inherited from Ownable)
9.  **Core Artifact Management**
    *   `forgeGenesisArtifact` (Owner creates initial artifacts)
    *   `forgeArtifact` (User creates artifact, potentially costing reputation)
    *   `transferArtifact`
    *   `getArtifactDetails` (View)
    *   `getArtifactOwner` (View)
    *   `getTotalArtifacts` (View)
    *   `getArtifactState` (View)
10. **Reputation System**
    *   `getUserReputation` (View)
    *   `awardReputation` (Admin)
    *   `deductReputation` (Admin)
    *   `grantAchievement` (Admin)
    *   `hasAchievement` (View)
    *   `checkReputationThreshold` (View)
11. **Artifact State & Property Manipulation**
    *   `setArtifactActionCondition` (Admin sets rules for state transitions/actions)
    *   `getArtifactActionCondition` (View)
    *   `attemptStateEvolutionWithConditions` (User attempts to evolve based on rules)
    *   `attemptActivationWithConditions` (User attempts to activate based on rules)
    *   `attuneArtifactWithConditions` (User attempts to change property based on rules)
    *   `combineArtifactsWithConditions` (User attempts to combine two artifacts based on rules)
    *   `performTimedReleaseAction` (Action unlocked after specific time)
    *   `triggerArtifactDecayIfDue` (Anyone can trigger decay if time condition met)
13. **Delegation**
    *   `delegateArtifactControl`
    *   `removeDelegateControl`
    *   `isDelegatedForAction` (View)
14. **Time-Based Calculations**
    *   `getTimeElapsedSinceCreation` (View)
    *   `getTimeElapsedSinceLastInteraction` (View)
15. **Admin/Utility**
    *   `setBaseReputationAward` (Admin sets parameters)
    *   `withdrawFunds` (Admin)

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets the owner.
2.  `forgeGenesisArtifact(uint256 initialCount)`: Owner-only function to mint the very first artifacts.
3.  `forgeArtifact(uint256 stateSeed)`: Allows a user to mint a new artifact. Could potentially cost reputation or require certain conditions.
4.  `transferArtifact(address to, uint256 artifactId)`: Transfers ownership of an artifact.
5.  `getArtifactDetails(uint256 artifactId)`: Returns comprehensive data about an artifact.
6.  `getArtifactOwner(uint256 artifactId)`: Returns the current owner of an artifact.
7.  `getTotalArtifacts()`: Returns the total number of artifacts minted.
8.  `getArtifactState(uint256 artifactId)`: Returns the current state of an artifact.
9.  `getUserReputation(address user)`: Returns the reputation score of a user.
10. `awardReputation(address user, uint256 amount)`: Admin function to increase a user's reputation.
11. `deductReputation(address user, uint256 amount)`: Admin function to decrease a user's reputation.
12. `grantAchievement(address user, uint256 achievementId)`: Admin function to grant a specific achievement badge to a user, potentially boosting reputation.
13. `hasAchievement(address user, uint256 achievementId)`: Checks if a user has a specific achievement.
14. `checkReputationThreshold(address user, uint256 requiredReputation)`: Checks if a user meets a minimum reputation threshold.
15. `setArtifactActionCondition(uint256 artifactId, bytes4 actionSelector, uint256 requiredReputation, MDAState requiredState)`: Admin sets the conditions (minimum reputation, required state) for a specific action (identified by its function selector) to be executable on a given artifact type or ID.
16. `getArtifactActionCondition(uint256 artifactId, bytes4 actionSelector)`: Retrieves the conditions set for a specific artifact action.
17. `attemptStateEvolutionWithConditions(uint256 artifactId)`: User attempts to evolve an artifact. Success depends on meeting pre-set conditions (`requiredReputation`, `requiredState`) and valid state transitions.
18. `attemptActivationWithConditions(uint256 artifactId)`: User attempts to change an artifact's state to `Active`, subject to conditions.
19. `attuneArtifactWithConditions(uint256 artifactId, uint256 tuneParameter)`: User attempts to modify a numeric property (`coreProperty`) of an artifact, subject to conditions.
20. `combineArtifactsWithConditions(uint256 artifactId1, uint256 artifactId2)`: User attempts to combine two artifacts (burning them) to forge a new one, subject to conditions on the input artifacts.
21. `performTimedReleaseAction(uint256 artifactId)`: User can execute an action on an artifact only after a specific timestamp associated with it has passed.
22. `triggerArtifactDecayIfDue(uint256 artifactId)`: Anyone can call this function. It checks if an artifact is overdue for decay based on inactivity and triggers the decay state change if true.
23. `delegateArtifactControl(uint256 artifactId, address delegatee, uint256 duration)`: Allows the artifact owner to grant another address temporary control over specific artifact actions.
24. `removeDelegateControl(uint256 artifactId, address delegatee)`: Owner or delegatee removes the delegation.
25. `isDelegatedForAction(uint256 artifactId, address delegatee, bytes4 actionSelector)`: Checks if an address is currently delegated to perform a specific action on an artifact.
26. `getTimeElapsedSinceCreation(uint256 artifactId)`: Returns the time in seconds since the artifact was created.
27. `getTimeElapsedSinceLastInteraction(uint256 artifactId)`: Returns the time in seconds since the artifact was last interacted with (state change, attunement, etc.).
28. `setBaseReputationAward(uint256 amount)`: Admin function to set a base amount of reputation awarded for certain actions (e.g., forging).
29. `withdrawFunds()`: Admin function to withdraw any Ether held by the contract (e.g., from potential future fees).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Custom Errors for better readability and gas efficiency
error ChronicleForge__ArtifactNotFound(uint256 artifactId);
error ChronicleForge__NotArtifactOwner(uint256 artifactId, address caller);
error ChronicleForge__InvalidArtifactState(uint256 artifactId, MDAState currentState, MDAState requiredState);
error ChronicleForge__InsufficientReputation(address user, uint256 currentReputation, uint256 requiredReputation);
error ChronicleForge__ActionConditionNotSet(uint256 artifactId, bytes4 actionSelector);
error ChronicleForge__InvalidStateTransition(uint256 artifactId, MDAState currentState, MDAState targetState);
error ChronicleForge__ActionNotReady(uint256 artifactId);
error ChronicleForge__DelegationExpired(uint256 artifactId, address delegatee);
error ChronicleForge__NotArtifactDelegate(uint256 artifactId, address delegatee);
error ChronicleForge__CannotCombineArtifacts(uint256 artifactId1, uint256 artifactId2, string reason);
error ChronicleForge__DecayNotDue(uint256 artifactId);

contract ChronicleForge is Ownable {

    // --- Events ---
    event ArtifactForged(uint256 indexed artifactId, address indexed creator, MDAState initialState, uint256 creationTime);
    event ArtifactTransferred(uint256 indexed artifactId, address indexed from, address indexed to);
    event ArtifactStateChanged(uint256 indexed artifactId, MDAState oldState, MDAState newState);
    event UserReputationChanged(address indexed user, uint256 oldReputation, uint256 newReputation);
    event AchievementGranted(address indexed user, uint256 indexed achievementId);
    event ArtifactAttuned(uint256 indexed artifactId, uint256 newCoreProperty);
    event ArtifactCombined(uint256 indexed burnedArtifact1, uint256 indexed burnedArtifact2, uint256 indexed newArtifactId);
    event ArtifactDelegated(uint256 indexed artifactId, address indexed delegatee, uint256 expiryTime);
    event ArtifactDelegateRemoved(uint256 indexed artifactId, address indexed delegatee);
    event ActionConditionSet(uint256 indexed artifactId, bytes4 indexed actionSelector, uint256 requiredReputation, MDAState requiredState);


    // --- Enums ---
    enum MDAState {
        Dormant,   // Initial or inactive state
        Active,    // Ready for interactions
        Evolved,   // Advanced state through process
        Decaying,  // Degenerating over time/inactivity
        Fused      // Result of combination
    }

    // --- Structs ---
    struct MDA {
        uint256 id;
        address creator;
        MDAState state;
        uint256 creationTime;
        uint256 lastInteractionTime; // Timestamp of last state change, attunement, etc.
        uint256 temporalParameter;   // Parameter influenced by time (e.g., decay counter, bonus)
        uint256 coreProperty;        // A mutable numeric property
        bool exists;                 // To check if an artifact ID is valid
    }

    struct ActionCondition {
        uint256 requiredReputation; // Minimum reputation required
        MDAState requiredState;    // Required artifact state
        bool isSet;                 // Flag to check if condition is defined
    }

    // --- State Variables ---
    uint256 private _nextTokenId; // Counter for unique artifact IDs
    uint256 private constant DECAY_INTERVAL = 30 days; // Time after which decay *can* be triggered (example: 30 days)
    uint256 private constant TIMED_ACTION_DELAY = 7 days; // Example delay for timed actions

    mapping(uint256 => MDA) private artifacts; // Artifact ID => MDA data
    mapping(uint256 => address) private artifactOwner; // Artifact ID => Owner Address
    mapping(address => uint256) private userReputation; // User Address => Reputation Score
    mapping(address => mapping(uint256 => bool)) private userAchievements; // User Address => Achievement ID => Has Achievement
    mapping(uint256 => mapping(bytes4 => ActionCondition)) private artifactActionConditions; // Artifact ID => Function Selector => Conditions
    mapping(uint256 => mapping(address => uint256)) private artifactDelegations; // Artifact ID => Delegatee Address => Expiry Timestamp

    uint256 private baseReputationAward = 10; // Default reputation awarded for forging, etc.

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {
        _nextTokenId = 1; // Start artifact IDs from 1
    }

    // --- Internal Helpers ---
    function _exists(uint256 artifactId) internal view returns (bool) {
        return artifacts[artifactId].exists;
    }

    function _getArtifact(uint256 artifactId) internal view returns (MDA storage) {
        if (!_exists(artifactId)) {
            revert ChronicleForge__ArtifactNotFound(artifactId);
        }
        return artifacts[artifactId];
    }

    function _updateArtifactState(uint256 artifactId, MDAState newState) internal {
        MDA storage artifact = _getArtifact(artifactId);
        MDAState oldState = artifact.state;
        if (oldState == newState) {
            return; // No change needed
        }
        artifact.state = newState;
        artifact.lastInteractionTime = block.timestamp; // Interaction timestamp update
        emit ArtifactStateChanged(artifactId, oldState, newState);
    }

    function _checkActionCondition(uint256 artifactId, bytes4 actionSelector) internal view returns (bool) {
        ActionCondition storage condition = artifactActionConditions[artifactId][actionSelector];

        if (!condition.isSet) {
            // No specific condition set for this artifact/action, allow by default or based on generic rules
            // For this example, if not set, no condition means action is not conditionally restricted
            return true;
        }

        address caller = _msgSender();
        uint256 currentReputation = userReputation[caller];
        MDAState currentState = _getArtifact(artifactId).state;

        if (currentReputation < condition.requiredReputation) {
            revert ChronicleForge__InsufficientReputation(caller, currentReputation, condition.requiredReputation);
        }
        if (currentState != condition.requiredState) {
            revert ChronicleForge__InvalidArtifactState(artifactId, currentState, condition.requiredState);
        }
        return true; // Conditions met
    }

     // --- Core Artifact Management ---

    /**
     * @dev Creates the initial set of artifacts. Only callable by the contract owner.
     * @param initialCount The number of genesis artifacts to mint.
     */
    function forgeGenesisArtifact(uint256 initialCount) public onlyOwner {
        require(initialCount > 0, "Initial count must be positive");
        for (uint256 i = 0; i < initialCount; i++) {
            uint256 newId = _nextTokenId++;
            artifacts[newId] = MDA({
                id: newId,
                creator: address(this), // Contract is the creator of genesis artifacts
                state: MDAState.Dormant,
                creationTime: block.timestamp,
                lastInteractionTime: block.timestamp,
                temporalParameter: 0,
                coreProperty: 100, // Starting core property
                exists: true
            });
            artifactOwner[newId] = owner(); // Owner gets genesis artifacts
            emit ArtifactForged(newId, address(this), MDAState.Dormant, block.timestamp);
            emit ArtifactTransferred(newId, address(0), owner());
        }
    }

    /**
     * @dev Allows a user to forge a new artifact. May require reputation cost in future.
     * @param stateSeed A seed value to potentially influence the initial state or properties.
     */
    function forgeArtifact(uint256 stateSeed) public {
        // Future: Could add reputation cost here, or require an achievement
        // require(userReputation[_msgSender()] >= forgingCost, "Not enough reputation to forge");
        // userReputation[_msgSender()] -= forgingCost;

        uint256 newId = _nextTokenId++;
        MDAState initialState = (stateSeed % 2 == 0) ? MDAState.Dormant : MDAState.Active; // Simple seed logic
         artifacts[newId] = MDA({
            id: newId,
            creator: _msgSender(),
            state: initialState,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            temporalParameter: 0,
            coreProperty: 50 + (stateSeed % 50), // Influenced by seed
            exists: true
        });
        artifactOwner[newId] = _msgSender();

        // Award some reputation for creating
        userReputation[_msgSender()] += baseReputationAward;
        emit UserReputationChanged(_msgSender(), userReputation[_msgSender] - baseReputationAward, userReputation[_msgSender]);

        emit ArtifactForged(newId, _msgSender(), initialState, block.timestamp);
        emit ArtifactTransferred(newId, address(0), _msgSender());
    }

    /**
     * @dev Transfers ownership of an artifact.
     * @param to The recipient address.
     * @param artifactId The ID of the artifact to transfer.
     */
    function transferArtifact(address to, uint256 artifactId) public {
        require(to != address(0), "Transfer to zero address");
        address currentOwner = artifactOwner[artifactId];
        if (currentOwner != _msgSender() && !_isApprovedOrDelegate(currentOwner, artifactId, _msgSender())) {
             revert ChronicleForge__NotArtifactOwner(artifactId, _msgSender());
        }
        if (!_exists(artifactId)) {
             revert ChronicleForge__ArtifactNotFound(artifactId);
        }

        // Clear any existing delegations upon transfer
        delete artifactDelegations[artifactId];

        artifactOwner[artifactId] = to;
        emit ArtifactTransferred(artifactId, currentOwner, to);
    }

    /**
     * @dev Gets detailed information about an artifact.
     * @param artifactId The ID of the artifact.
     * @return MDA struct containing artifact data.
     */
    function getArtifactDetails(uint256 artifactId) public view returns (MDA memory) {
        return _getArtifact(artifactId);
    }

    /**
     * @dev Gets the owner of an artifact.
     * @param artifactId The ID of the artifact.
     * @return The owner address.
     */
    function getArtifactOwner(uint256 artifactId) public view returns (address) {
         if (!_exists(artifactId)) {
             revert ChronicleForge__ArtifactNotFound(artifactId);
        }
        return artifactOwner[artifactId];
    }

    /**
     * @dev Gets the total number of artifacts that have been forged.
     * @return The total count.
     */
    function getTotalArtifacts() public view returns (uint256) {
        return _nextTokenId - 1; // Exclude the next available ID
    }

    /**
     * @dev Gets the current state of an artifact.
     * @param artifactId The ID of the artifact.
     * @return The MDAState enum value.
     */
    function getArtifactState(uint256 artifactId) public view returns (MDAState) {
         return _getArtifact(artifactId).state;
    }

    // --- Reputation System ---

    /**
     * @dev Gets a user's current reputation score.
     * @param user The user's address.
     * @return The reputation score.
     */
    function getUserReputation(address user) public view returns (uint256) {
        return userReputation[user];
    }

     /**
     * @dev Awards reputation to a user. Callable by the contract owner.
     * @param user The address to award reputation to.
     * @param amount The amount of reputation to award.
     */
    function awardReputation(address user, uint256 amount) public onlyOwner {
        uint256 oldReputation = userReputation[user];
        userReputation[user] += amount;
        emit UserReputationChanged(user, oldReputation, userReputation[user]);
    }

    /**
     * @dev Deducts reputation from a user. Callable by the contract owner.
     * @param user The address to deduct reputation from.
     * @param amount The amount of reputation to deduct.
     */
    function deductReputation(address user, uint256 amount) public onlyOwner {
        uint256 oldReputation = userReputation[user];
        userReputation[user] = userReputation[user] > amount ? userReputation[user] - amount : 0;
        emit UserReputationChanged(user, oldReputation, userReputation[user]);
    }

    /**
     * @dev Grants an achievement badge to a user. Callable by the contract owner.
     * @param user The user's address.
     * @param achievementId The ID of the achievement.
     */
    function grantAchievement(address user, uint256 achievementId) public onlyOwner {
        if (!userAchievements[user][achievementId]) {
            userAchievements[user][achievementId] = true;
            // Could automatically award reputation for certain achievements
            userReputation[user] += baseReputationAward * 5; // Example bonus
             emit UserReputationChanged(user, userReputation[user] - baseReputationAward * 5, userReputation[user]);
            emit AchievementGranted(user, achievementId);
        }
    }

    /**
     * @dev Checks if a user has a specific achievement.
     * @param user The user's address.
     * @param achievementId The ID of the achievement.
     * @return True if the user has the achievement, false otherwise.
     */
    function hasAchievement(address user, uint256 achievementId) public view returns (bool) {
        return userAchievements[user][achievementId];
    }

    /**
     * @dev Checks if a user's reputation meets a minimum threshold.
     * @param user The user's address.
     * @param requiredReputation The minimum reputation needed.
     * @return True if reputation is sufficient, false otherwise.
     */
    function checkReputationThreshold(address user, uint256 requiredReputation) public view returns (bool) {
        return userReputation[user] >= requiredReputation;
    }

    // --- Artifact State & Property Manipulation (Conditional) ---

    /**
     * @dev Owner sets the conditions required to execute a specific action (identified by function selector)
     * on a given artifact ID. These conditions are checked in functions like `attemptStateEvolutionWithConditions`.
     * @param artifactId The ID of the artifact to set conditions for. Use 0 for global conditions (not implemented here, but possible).
     * @param actionSelector The function selector (`bytes4`) of the target action function.
     * @param requiredReputation Minimum reputation required for the action.
     * @param requiredState Required artifact state for the action.
     */
    function setArtifactActionCondition(uint256 artifactId, bytes4 actionSelector, uint256 requiredReputation, MDAState requiredState) public onlyOwner {
        artifactActionConditions[artifactId][actionSelector] = ActionCondition({
            requiredReputation: requiredReputation,
            requiredState: requiredState,
            isSet: true
        });
        emit ActionConditionSet(artifactId, actionSelector, requiredReputation, requiredState);
    }

     /**
     * @dev Gets the conditions set for a specific action on an artifact.
     * @param artifactId The artifact ID.
     * @param actionSelector The function selector of the action.
     * @return ActionCondition struct.
     */
    function getArtifactActionCondition(uint256 artifactId, bytes4 actionSelector) public view returns (ActionCondition memory) {
        return artifactActionConditions[artifactId][actionSelector];
    }

    /**
     * @dev Attempts to evolve an artifact's state to Evolved. Requires artifact ownership/delegation and meeting pre-set conditions.
     * State Transition Rule: Dormant -> Active -> Evolved. Can't evolve from Decaying or Fused.
     * @param artifactId The ID of the artifact to evolve.
     */
    function attemptStateEvolutionWithConditions(uint256 artifactId) public {
        address currentOwner = artifactOwner[artifactId];
        bytes4 actionSelector = this.attemptStateEvolutionWithConditions.selector;
        if (currentOwner != _msgSender() && !_isApprovedOrDelegate(currentOwner, artifactId, _msgSender(), actionSelector)) {
            revert ChronicleForge__NotArtifactOwner(artifactId, _msgSender());
        }

        _checkActionCondition(artifactId, actionSelector); // Check Reputation and State conditions

        MDA storage artifact = _getArtifact(artifactId);
        // Specific state transition check for evolution
        if (artifact.state == MDAState.Dormant || artifact.state == MDAState.Decaying || artifact.state == MDAState.Fused) {
             revert ChronicleForge__InvalidStateTransition(artifactId, artifact.state, MDAState.Evolved);
        }

        _updateArtifactState(artifactId, MDAState.Evolved);
        userReputation[_msgSender()] += baseReputationAward * 2; // Reward for evolving
        emit UserReputationChanged(_msgSender(), userReputation[_msgSender] - baseReputationAward * 2, userReputation[_msgSender]);
    }

    /**
     * @dev Attempts to activate an artifact. Requires artifact ownership/delegation and meeting pre-set conditions.
     * State Transition Rule: Dormant -> Active.
     * @param artifactId The ID of the artifact to activate.
     */
    function attemptActivationWithConditions(uint256 artifactId) public {
        address currentOwner = artifactOwner[artifactId];
        bytes4 actionSelector = this.attemptActivationWithConditions.selector;
        if (currentOwner != _msgSender() && !_isApprovedOrDelegate(currentOwner, artifactId, _msgSender(), actionSelector)) {
            revert ChronicleForge__NotArtifactOwner(artifactId, _msgSender());
        }

        _checkActionCondition(artifactId, actionSelector);

        MDA storage artifact = _getArtifact(artifactId);
        if (artifact.state != MDAState.Dormant) {
             revert ChronicleForge__InvalidStateTransition(artifactId, artifact.state, MDAState.Active);
        }

        _updateArtifactState(artifactId, MDAState.Active);
        userReputation[_msgSender()] += baseReputationAward; // Reward for activating
        emit UserReputationChanged(_msgSender(), userReputation[_msgSender] - baseReputationAward, userReputation[_msgSender]);
    }

     /**
     * @dev Attempts to attune an artifact (change its core property). Requires artifact ownership/delegation and meeting pre-set conditions.
     * Can be done in Active or Evolved state.
     * @param artifactId The ID of the artifact.
     * @param tuneParameter A parameter influencing the attunement outcome.
     */
    function attuneArtifactWithConditions(uint256 artifactId, uint256 tuneParameter) public {
        address currentOwner = artifactOwner[artifactId];
        bytes4 actionSelector = this.attuneArtifactWithConditions.selector;
         if (currentOwner != _msgSender() && !_isApprovedOrDelegate(currentOwner, artifactId, _msgSender(), actionSelector)) {
            revert ChronicleForge__NotArtifactOwner(artifactId, _msgSender());
        }

        _checkActionCondition(artifactId, actionSelector);

        MDA storage artifact = _getArtifact(artifactId);
        // Attunement only possible in Active or Evolved states
        if (artifact.state != MDAState.Active && artifact.state != MDAState.Evolved) {
            revert ChronicleForge__InvalidArtifactState(artifactId, artifact.state, artifact.state); // Indicate it needs to be Active or Evolved
        }

        // Example attunement logic: modifies core property based on parameter and state
        if (artifact.state == MDAState.Active) {
            artifact.coreProperty += (tuneParameter % 10) + 1;
        } else if (artifact.state == MDAState.Evolved) {
             artifact.coreProperty += (tuneParameter % 20) + 5; // Greater effect when Evolved
        }
         artifact.lastInteractionTime = block.timestamp; // Interaction timestamp update
        emit ArtifactAttuned(artifactId, artifact.coreProperty);

        userReputation[_msgSender()] += baseReputationAward / 2; // Smaller reward for attuning
        emit UserReputationChanged(_msgSender(), userReputation[_msgSender] - baseReputationAward / 2, userReputation[_msgSender]);
    }

    /**
     * @dev Attempts to combine two artifacts into a new, fused artifact. Requires ownership/delegation of both and meeting conditions.
     * Burns the two input artifacts.
     * Conditions can be set for the *resulting* action on the input artifacts.
     * @param artifactId1 The ID of the first artifact.
     * @param artifactId2 The ID of the second artifact.
     */
    function combineArtifactsWithConditions(uint256 artifactId1, uint256 artifactId2) public {
        require(artifactId1 != artifactId2, "Cannot combine artifact with itself");

        address owner1 = artifactOwner[artifactId1];
        address owner2 = artifactOwner[artifactId2];

         // Ensure caller owns or is delegated for *both* artifacts for this action
        bytes4 actionSelector = this.combineArtifactsWithConditions.selector;
         if (owner1 != _msgSender() && !_isApprovedOrDelegate(owner1, artifactId1, _msgSender(), actionSelector)) {
             revert ChronicleForge__NotArtifactOwner(artifactId1, _msgSender());
         }
        if (owner2 != _msgSender() && !_isApprovedOrDelegate(owner2, artifactId2, _msgSender(), actionSelector)) {
             revert ChronicleForge__NotArtifactOwner(artifactId2, _msgSender());
         }

        // Check conditions for *each* artifact involved in the combination
        _checkActionCondition(artifactId1, actionSelector);
        _checkActionCondition(artifactId2, actionSelector);

        MDA storage artifact1 = _getArtifact(artifactId1);
        MDA storage artifact2 = _getArtifact(artifactId2);

        // Example Combination Logic: Must be Active or Evolved to combine
        if ((artifact1.state != MDAState.Active && artifact1.state != MDAState.Evolved) ||
            (artifact2.state != MDAState.Active && artifact2.state != MDAState.Evolved))
        {
             revert ChronicleForge__CannotCombineArtifacts(artifactId1, artifactId2, "Inputs must be Active or Evolved");
        }

        // Burn the input artifacts
        delete artifacts[artifactId1];
        delete artifactOwner[artifactId1];
        delete artifactDelegations[artifactId1]; // Clear delegations on burned artifact
        emit ArtifactTransferred(artifactId1, owner1, address(0)); // Signal burn

        delete artifacts[artifactId2];
        delete artifactOwner[artifactId2];
         delete artifactDelegations[artifactId2]; // Clear delegations on burned artifact
        emit ArtifactTransferred(artifactId2, owner2, address(0)); // Signal burn

        // Forge the new, fused artifact
        uint256 newId = _nextTokenId++;
         artifacts[newId] = MDA({
            id: newId,
            creator: _msgSender(), // The combiner is the creator of the fused artifact
            state: MDAState.Fused, // New state
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            temporalParameter: (artifact1.temporalParameter + artifact2.temporalParameter) / 2, // Example fusion logic
            coreProperty: artifact1.coreProperty + artifact2.coreProperty, // Example fusion logic
            exists: true
        });
        artifactOwner[newId] = _msgSender();

        userReputation[_msgSender()] += baseReputationAward * 10; // Big reward for fusing
         emit UserReputationChanged(_msgSender(), userReputation[_msgSender] - baseReputationAward * 10, userReputation[_msgSender]);
        emit ArtifactCombined(artifactId1, artifactId2, newId);
        emit ArtifactForged(newId, _msgSender(), MDAState.Fused, block.timestamp);
        emit ArtifactTransferred(newId, address(0), _msgSender());
    }

    /**
     * @dev Allows an action to be performed on an artifact only after a specific time delay from creation.
     * Requires artifact ownership/delegation.
     * @param artifactId The ID of the artifact.
     */
    function performTimedReleaseAction(uint256 artifactId) public {
        address currentOwner = artifactOwner[artifactId];
         bytes4 actionSelector = this.performTimedReleaseAction.selector;
         if (currentOwner != _msgSender() && !_isApprovedOrDelegate(currentOwner, artifactId, _msgSender(), actionSelector)) {
            revert ChronicleForge__NotArtifactOwner(artifactId, _msgSender());
        }

        MDA storage artifact = _getArtifact(artifactId);
        if (block.timestamp < artifact.creationTime + TIMED_ACTION_DELAY) {
             revert ChronicleForge__ActionNotReady(artifactId);
        }

        // Example Action: Boost core property significantly
        artifact.coreProperty += 50;
        artifact.lastInteractionTime = block.timestamp; // Interaction timestamp update

        // Could also change state, grant achievement, etc.
        // _updateArtifactState(artifactId, MDAState.Active); // Example: auto-activate after delay

        emit ArtifactAttuned(artifactId, artifact.coreProperty); // Using Attuned event for property change
        userReputation[_msgSender()] += baseReputationAward * 3; // Reward
         emit UserReputationChanged(_msgSender(), userReputation[_msgSender] - baseReputationAward * 3, userReputation[_msgSender]);
    }

    /**
     * @dev Allows anyone to trigger an artifact's decay state change if it has been inactive for too long.
     * Decentralized maintenance/game mechanic.
     * @param artifactId The ID of the artifact to check and decay.
     */
    function triggerArtifactDecayIfDue(uint256 artifactId) public {
         MDA storage artifact = _getArtifact(artifactId);

        // Only trigger decay if not already Decaying or Fused
        if (artifact.state == MDAState.Decaying || artifact.state == MDAState.Fused) {
             revert ChronicleForge__InvalidStateTransition(artifactId, artifact.state, MDAState.Decaying);
        }

        // Check if enough time has passed since last interaction
        if (block.timestamp < artifact.lastInteractionTime + DECAY_INTERVAL) {
             revert ChronicleForge__DecayNotDue(artifactId);
        }

        _updateArtifactState(artifactId, MDAState.Decaying);

        // Could award a small amount of reputation to the triggerer for maintenance
        // userReputation[_msgSender()] += 1; // Example minimal reward
        // emit UserReputationChanged(_msgSender(), userReputation[_msgSender], userReputation[_msgSender] + 1);
    }


    // --- Delegation ---

    /**
     * @dev Allows the artifact owner to delegate control over the artifact to another address for a duration.
     * The delegatee can perform certain actions as if they were the owner (subject to isApprovedOrDelegate checks).
     * @param artifactId The ID of the artifact.
     * @param delegatee The address to delegate control to.
     * @param duration The duration in seconds for the delegation.
     */
    function delegateArtifactControl(uint256 artifactId, address delegatee, uint256 duration) public {
        address currentOwner = artifactOwner[artifactId];
        if (currentOwner != _msgSender()) {
             revert ChronicleForge__NotArtifactOwner(artifactId, _msgSender());
        }
         require(delegatee != address(0), "Delegatee cannot be zero address");
         require(delegatee != currentOwner, "Cannot delegate to self");
         require(duration > 0, "Delegation duration must be positive");

        uint256 expiryTime = block.timestamp + duration;
        artifactDelegations[artifactId][delegatee] = expiryTime;

        emit ArtifactDelegated(artifactId, delegatee, expiryTime);
    }

    /**
     * @dev Removes a specific delegation. Can be called by the owner or the delegatee.
     * @param artifactId The ID of the artifact.
     * @param delegatee The address whose delegation to remove.
     */
    function removeDelegateControl(uint256 artifactId, address delegatee) public {
         address currentOwner = artifactOwner[artifactId];
         require(_msgSender() == currentOwner || _msgSender() == delegatee, "Only owner or delegatee can remove delegation");

        delete artifactDelegations[artifactId][delegatee];
        emit ArtifactDelegateRemoved(artifactId, delegatee);
    }

    /**
     * @dev Internal helper to check if an address is the owner, approved (not implemented standard ERC721 approve here), or a valid delegate for an action.
     * @param currentOwner The owner of the artifact.
     * @param artifactId The artifact ID.
     * @param caller The address attempting the action.
     * @param actionSelector The selector of the action being attempted. Optional, defaults to any delegation if omitted.
     * @return True if the caller is authorized.
     */
    function _isApprovedOrDelegate(address currentOwner, uint256 artifactId, address caller, bytes4 actionSelector) internal view returns (bool) {
        if (caller == currentOwner) {
            return true;
        }
        // Check delegation expiry
        if (artifactDelegations[artifactId][caller] > block.timestamp) {
            // Future: Could add logic here to check if delegation is specific to actionSelector
            // For now, any active delegation allows the caller to act as owner for conditioned actions
            return true;
        }
        return false;
    }

     /**
     * @dev Public view function to check if an address is currently delegated for an artifact.
     * Note: This doesn't check if the delegation is *specific* to a certain actionSelector, just if the general delegation is active.
     * @param artifactId The artifact ID.
     * @param delegatee The address to check.
     * @return True if the address is a valid delegate, false otherwise.
     */
    function isDelegatedForAction(uint256 artifactId, address delegatee, bytes4 /* actionSelector */) public view returns (bool) {
         // Note: Does not check actionSelector specificity in this version.
         return artifactDelegations[artifactId][delegatee] > block.timestamp;
    }


    // --- Time-Based Calculations ---

    /**
     * @dev Calculates the time elapsed since an artifact was created.
     * @param artifactId The artifact ID.
     * @return Time elapsed in seconds.
     */
    function getTimeElapsedSinceCreation(uint256 artifactId) public view returns (uint256) {
         return block.timestamp - _getArtifact(artifactId).creationTime;
    }

    /**
     * @dev Calculates the time elapsed since an artifact was last interacted with (state change, attunement etc.).
     * @param artifactId The artifact ID.
     * @return Time elapsed in seconds.
     */
    function getTimeElapsedSinceLastInteraction(uint256 artifactId) public view returns (uint256) {
         return block.timestamp - _getArtifact(artifactId).lastInteractionTime;
    }


    // --- Admin/Utility ---

    /**
     * @dev Sets the base amount of reputation awarded for actions like forging.
     * @param amount The new base amount.
     */
    function setBaseReputationAward(uint256 amount) public onlyOwner {
        baseReputationAward = amount;
    }

    /**
     * @dev Allows the contract owner to withdraw any Ether balance.
     */
    function withdrawFunds() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // Fallback function to receive Ether if needed for future mechanics
    receive() external payable {}
    // Payable function to receive Ether if sent directly
    fallback() external payable {}
}
```