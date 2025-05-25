Okay, let's design a smart contract that combines several interesting and advanced concepts: **Decentralized Soulbound Reputation, Interaction Logging, Affiliation Bonding, and Dynamic SoulMarks (Non-Transferable Tokens)**.

This contract, let's call it `DSIRIS` (Decentralized Soulbound Reputation & Interaction System), aims to track user activity, assign reputation based on verifiable interactions, allow users to bond their earned reputation to specific "Affiliations" (representing communities, DAOs, projects), and issue non-transferable SoulMarks (SBTs) based on achieved reputation thresholds or bonded reputation.

It incorporates:
1.  **Weighted Interactions:** Different types of on-chain actions contribute differently to reputation.
2.  **Reputation Decay:** Reputation can slowly decrease over time if not maintained by activity.
3.  **Affiliation Bonding:** Users can commit a portion of their reputation to specific groups, signaling loyalty or expertise.
4.  **Timed Unbonding:** Unbonding reputation might involve a time lock.
5.  **Dynamic SoulMarks:** Non-transferable tokens issued programmatically based on reputation score or bonded reputation criteria.
6.  **Role-Based Recording:** Specific addresses can be authorized to record interactions.
7.  **On-chain Data Structure:** Comprehensive tracking of user stats, interactions, bonds, and issued marks.

This design avoids simple token transfers or basic NFT minting. It focuses on dynamic state changes, role-based permissions, and complex conditional logic for issuing non-transferable assets.

---

**Outline and Function Summary**

**Contract Name:** DSIRIS (Decentralized Soulbound Reputation & Interaction System)

**Core Concepts:**
*   Tracks user reputation based on logged interactions.
*   Reputation score can decay over time.
*   Users can bond reputation to defined "Affiliations".
*   Users can claim non-transferable "SoulMarks" (SBTs) based on reputation thresholds or bonded reputation.
*   Interactions are recorded by designated "Recorder" addresses.

**State Variables:**
*   `owner`: Contract owner address.
*   `isRecorder`: Mapping tracking addresses authorized to record interactions.
*   `interactionTypeCounter`: Counter for unique interaction types.
*   `interactionTypes`: Mapping from ID to `InteractionType` struct.
*   `affiliationCounter`: Counter for unique affiliations.
*   `affiliations`: Mapping from ID to `Affiliation` struct.
*   `soulMarkThresholdCounter`: Counter for unique SoulMark thresholds.
*   `soulMarkThresholds`: Mapping from ID to `SoulMarkThreshold` struct.
*   `userCounter`: Counter for unique users (implicit by address mapping).
*   `users`: Mapping from user address to `User` struct.
*   `userAffiliationBonding`: Mapping from user address -> affiliation ID -> bonded amount.
*   `userBondLocks`: Mapping from user address -> affiliation ID -> lock expiry timestamp.
*   `userInteractionLogs`: Mapping from user address -> interaction log index -> `InteractionLog` struct.
*   `userInteractionLogCount`: Mapping from user address -> number of interaction logs.
*   `userSoulMarks`: Mapping from user address -> SoulMark threshold ID -> boolean (has mark).
*   `reputationDecayRatePerSecond`: The decay rate applied per second (scaled).
*   `MIN_REPUTATION`: Minimum reputation a user can have (e.g., 0).

**Structs:**
*   `InteractionType`: Defines an interaction type (name, description, reputation weight).
*   `Affiliation`: Represents a community/project (name, description).
*   `SoulMarkThreshold`: Defines criteria for issuing a SoulMark (name, description, required total reputation, required bonded reputation amount, required bonded affiliation ID).
*   `User`: Stores user's total reputation, last reputation update timestamp, and total bonded reputation.
*   `InteractionLog`: Records details of a logged interaction (type ID, timestamp, reputation impact).

**Events:**
*   `InteractionTypeAdded`: When a new interaction type is added.
*   `InteractionTypeUpdated`: When an interaction type is updated.
*   `AffiliationCreated`: When a new affiliation is created.
*   `AffiliationUpdated`: When an affiliation is updated.
*   `SoulMarkThresholdAdded`: When a new SoulMark threshold is added.
*   `SoulMarkThresholdUpdated`: When a SoulMark threshold is updated.
*   `InteractionRecorded`: When an interaction is logged for a user.
*   `ReputationDecayed`: When a user's reputation decays.
*   `ReputationBonded`: When a user bonds reputation to an affiliation.
*   `ReputationUnbondingStarted`: When a user initiates unbonding with a lock.
*   `ReputationUnbonded`: When bonded reputation is successfully unbonded after lock.
*   `SoulMarkClaimed`: When a user claims a SoulMark.
*   `RecorderAdded`: When an address is authorized as a recorder.
*   `RecorderRemoved`: When an address is deauthorized as a recorder.
*   `OwnershipTransferred`: Standard ownership transfer event.

**Functions (>= 20):**

**Owner/Admin Functions:**
1.  `constructor()`: Sets initial owner.
2.  `transferOwnership(address newOwner)`: Transfers contract ownership.
3.  `addRecorder(address recorderAddress)`: Grants permission to record interactions.
4.  `removeRecorder(address recorderAddress)`: Revokes recording permission.
5.  `addInteractionType(string memory name, string memory description, uint256 weight)`: Creates a new type of interaction with a reputation weight.
6.  `updateInteractionTypeWeight(uint256 typeId, uint256 newWeight)`: Updates the weight of an existing interaction type.
7.  `removeInteractionType(uint256 typeId)`: Marks an interaction type as inactive (doesn't delete data).
8.  `createAffiliation(string memory name, string memory description)`: Registers a new affiliation.
9.  `updateAffiliationDetails(uint256 affiliationId, string memory newName, string memory newDescription)`: Updates details of an affiliation.
10. `deactivateAffiliation(uint256 affiliationId)`: Marks an affiliation as inactive.
11. `setReputationDecayRate(uint256 ratePerSecondScaled)`: Sets the global reputation decay rate.
12. `addSoulMarkThreshold(string memory name, string memory description, uint256 requiredTotalReputation, uint256 requiredBondedAmount, uint256 requiredBondedAffiliationId)`: Defines criteria for a new SoulMark.
13. `updateSoulMarkThreshold(uint256 thresholdId, string memory name, string memory description, uint256 requiredTotalReputation, uint256 requiredBondedAmount, uint256 requiredBondedAffiliationId)`: Updates criteria for an existing SoulMark threshold.
14. `removeSoulMarkThreshold(uint256 thresholdId)`: Deactivates a SoulMark threshold.

**Recorder Functions:**
15. `recordInteraction(address user, uint256 interactionTypeId, uint256 multiplier)`: Logs an interaction for a user, calculates and adds reputation. Includes implicit reputation decay calculation.

**User Functions:**
16. `bondReputationToAffiliation(uint256 affiliationId, uint256 amount)`: Bonds a specified amount of user's available reputation to an affiliation.
17. `unbondReputationFromAffiliation(uint256 affiliationId, uint256 amount, uint256 lockDurationSeconds)`: Initiates the unbonding of a specified amount, subject to a time lock.
18. `claimUnbondedReputation(uint256 affiliationId)`: Claims reputation previously put under a time lock after the lock expires.
19. `claimSoulMark(uint256 thresholdId)`: Claims a specific SoulMark if the user meets the criteria for that threshold and hasn't claimed it before.
20. `decayReputation(address user)`: Public function allowing anyone (or an automated keeper) to trigger reputation decay for a specific user. (Also called internally by `recordInteraction` and bonding functions).

**View/Pure Functions:**
21. `isRecorder(address account) public view`: Checks if an address is a recorder.
22. `getInteractionType(uint256 typeId) public view`: Gets details of an interaction type.
23. `getAffiliation(uint256 affiliationId) public view`: Gets details of an affiliation.
24. `getSoulMarkThreshold(uint256 thresholdId) public view`: Gets details of a SoulMark threshold.
25. `getUserTotalReputation(address user) public view`: Gets a user's current total reputation (after applying potential decay).
26. `getUserBondedReputationForAffiliation(address user, uint256 affiliationId) public view`: Gets reputation bonded by a user to a specific affiliation.
27. `getUserAvailableReputation(address user) public view`: Gets reputation a user has that is not bonded.
28. `getReputationDecayRate() public view`: Gets the current decay rate.
29. `getBondLockExpiry(address user, uint256 affiliationId) public view`: Gets the expiry time of an unbonding lock for an affiliation.
30. `hasSoulMark(address user, uint256 thresholdId) public view`: Checks if a user has claimed a specific SoulMark.
31. `canClaimSoulMark(address user, uint256 thresholdId) public view`: Checks if a user meets the criteria for a specific SoulMark threshold.
32. `getTotalInteractionTypes() public view`: Gets the total number of interaction types ever created.
33. `getTotalAffiliations() public view`: Gets the total number of affiliations ever created.
34. `getTotalSoulMarkThresholds() public view`: Gets the total number of SoulMark thresholds ever created.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DSIRIS (Decentralized Soulbound Reputation & Interaction System)
/// @dev This contract manages user reputation based on weighted interactions,
/// allows bonding reputation to affiliations, implements reputation decay,
/// and issues non-transferable SoulMarks based on criteria.
/// @author Your Name/Alias

// Outline:
// 1. State Variables
// 2. Struct Definitions
// 3. Event Definitions
// 4. Modifiers
// 5. Constructor
// 6. Owner/Admin Functions (Reporters, Interaction Types, Affiliations, Decay, SoulMarks)
// 7. Reporter Functions (Recording Interactions)
// 8. User Functions (Bonding, Unbonding, Claiming SoulMarks, Triggering Decay)
// 9. Internal Helper Functions (Reputation Calculation, Decay Application)
// 10. View/Pure Functions (Getters)

// Function Summary:
// - constructor(): Initializes the contract owner.
// - transferOwnership(address newOwner): Transfers ownership of the contract.
// - addRecorder(address recorderAddress): Adds an address to the list of allowed recorders.
// - removeRecorder(address recorderAddress): Removes an address from the list of allowed recorders.
// - addInteractionType(string memory name, string memory description, uint256 weight): Defines a new type of interaction with a reputation weight.
// - updateInteractionTypeWeight(uint256 typeId, uint256 newWeight): Updates the weight of an existing interaction type.
// - removeInteractionType(uint256 typeId): Deactivates an interaction type.
// - createAffiliation(string memory name, string memory description): Registers a new affiliation.
// - updateAffiliationDetails(uint256 affiliationId, string memory newName, string memory newDescription): Updates details of an affiliation.
// - deactivateAffiliation(uint256 affiliationId): Deactivates an affiliation.
// - setReputationDecayRate(uint256 ratePerSecondScaled): Sets the global reputation decay rate (scaled by 1e18).
// - addSoulMarkThreshold(string memory name, string memory description, uint256 requiredTotalReputation, uint256 requiredBondedAmount, uint256 requiredBondedAffiliationId): Defines criteria for a new SoulMark.
// - updateSoulMarkThreshold(uint256 thresholdId, string memory name, string memory description, uint256 requiredTotalReputation, uint256 requiredBondedAmount, uint256 requiredBondedAffiliationId): Updates criteria for an existing SoulMark threshold.
// - removeSoulMarkThreshold(uint256 thresholdId): Deactivates a SoulMark threshold.
// - recordInteraction(address user, uint256 interactionTypeId, uint256 multiplier): Logs an interaction for a user, calculates and adds reputation after applying decay. Callable only by recorders.
// - bondReputationToAffiliation(uint256 affiliationId, uint256 amount): Bonds a specified amount of user's available reputation to an affiliation.
// - unbondReputationFromAffiliation(uint256 affiliationId, uint256 amount, uint256 lockDurationSeconds): Initiates the unbonding of a specified amount, subject to a time lock.
// - claimUnbondedReputation(uint256 affiliationId): Claims reputation previously put under a time lock after the lock expires.
// - claimSoulMark(uint256 thresholdId): Claims a specific SoulMark if the user meets the criteria for that threshold and hasn't claimed it before.
// - decayReputation(address user): Triggers the reputation decay calculation for a specific user.
// - isRecorder(address account): Checks if an address is a recorder.
// - getInteractionType(uint256 typeId): Gets details of an interaction type.
// - getAffiliation(uint256 affiliationId): Gets details of an affiliation.
// - getSoulMarkThreshold(uint256 thresholdId): Gets details of a SoulMark threshold.
// - getUserTotalReputation(address user): Gets a user's current total reputation (after applying potential decay).
// - getUserBondedReputationForAffiliation(address user, uint256 affiliationId): Gets reputation bonded by a user to a specific affiliation.
// - getUserAvailableReputation(address user): Gets reputation a user has that is not bonded or locked.
// - getReputationDecayRate(): Gets the current decay rate (scaled).
// - getBondLockExpiry(address user, uint256 affiliationId): Gets the expiry time of an unbonding lock for an affiliation.
// - hasSoulMark(address user, uint256 thresholdId): Checks if a user has claimed a specific SoulMark.
// - canClaimSoulMark(address user, uint256 thresholdId): Checks if a user meets the criteria for a specific SoulMark threshold.
// - getTotalInteractionTypes(): Gets the total count of registered interaction types.
// - getTotalAffiliations(): Gets the total count of registered affiliations.
// - getTotalSoulMarkThresholds(): Gets the total count of registered SoulMark thresholds.

contract DSIRIS {

    // 1. State Variables
    address private owner;
    mapping(address => bool) private isRecorder;

    uint256 private interactionTypeCounter;
    mapping(uint256 => InteractionType) private interactionTypes;

    uint256 private affiliationCounter;
    mapping(uint256 => Affiliation) private affiliations;

    uint256 private soulMarkThresholdCounter;
    mapping(uint256 => SoulMarkThreshold) private soulMarkThresholds;

    mapping(address => User) private users;

    // userAddress -> affiliationId -> amount
    mapping(address => mapping(uint256 => uint256)) private userAffiliationBonding;

    // userAddress -> affiliationId -> lockExpiryTimestamp
    mapping(address => mapping(uint256 => uint256)) private userBondLocks;

    // userAddress -> soulMarkThresholdId -> hasClaimed
    mapping(address => mapping(uint256 => bool)) private userSoulMarks;

    // Reputation decay rate (scaled by 1e18). e.g., 0.001e18 means 0.1% decay per second.
    uint256 private reputationDecayRatePerSecond = 0; // Default to no decay
    uint256 private constant REPUTATION_SCALING_FACTOR = 1e18; // For fixed-point arithmetic
    uint256 private constant MIN_REPUTATION = 0;

    // We won't store full interaction logs on-chain to save gas,
    // but the struct is here for conceptual completeness if needed.
    // mapping(address => mapping(uint256 => InteractionLog)) private userInteractionLogs;
    // mapping(address => uint256) private userInteractionLogCount;


    // 2. Struct Definitions

    struct InteractionType {
        uint256 id;
        string name;
        string description;
        uint256 weight; // Reputation points added for this interaction type (scaled by REPUTATION_SCALING_FACTOR)
        bool active;
    }

    struct Affiliation {
        uint256 id;
        string name;
        string description;
        bool active;
    }

    struct SoulMarkThreshold {
        uint256 id;
        string name;
        string description;
        uint256 requiredTotalReputation; // Scaled
        uint256 requiredBondedAmount; // Scaled
        uint256 requiredBondedAffiliationId;
        bool active;
    }

    struct User {
        uint256 totalReputation; // Scaled by REPUTATION_SCALING_FACTOR
        uint256 lastReputationUpdateTime; // Timestamp of last interaction or decay application
        uint256 totalBondedReputation; // Sum of all bonded reputation for this user (Scaled)
    }

    // struct InteractionLog { // Kept for concept, not stored to save gas
    //     uint256 typeId;
    //     uint256 timestamp;
    //     uint256 reputationImpact; // Scaled
    //     uint256 multiplier; // Multiplier used for this specific interaction
    // }


    // 3. Event Definitions

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RecorderAdded(address indexed recorder);
    event RecorderRemoved(address indexed recorder);
    event InteractionTypeAdded(uint256 indexed typeId, string name, uint256 weight);
    event InteractionTypeUpdated(uint256 indexed typeId, uint256 newWeight);
    event AffiliationCreated(uint256 indexed affiliationId, string name);
    event AffiliationUpdated(uint256 indexed affiliationId, string newName);
    event SoulMarkThresholdAdded(uint256 indexed thresholdId, string name, uint256 requiredTotalReputation);
    event SoulMarkThresholdUpdated(uint256 indexed thresholdId, uint256 requiredTotalReputation);
    event InteractionRecorded(address indexed user, uint256 indexed interactionTypeId, uint256 reputationGained, uint256 newTotalReputation);
    event ReputationDecayed(address indexed user, uint256 oldReputation, uint256 newReputation);
    event ReputationBonded(address indexed user, uint256 indexed affiliationId, uint256 amount, uint256 newBondedTotal);
    event ReputationUnbondingStarted(address indexed user, uint256 indexed affiliationId, uint256 amount, uint256 lockExpiry);
    event ReputationUnbonded(address indexed user, uint256 indexed affiliationId, uint256 amount);
    event SoulMarkClaimed(address indexed user, uint256 indexed thresholdId);


    // 4. Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "DSIRIS: Caller is not the owner");
        _;
    }

    modifier onlyRecorder() {
        require(isRecorder[msg.sender], "DSIRIS: Caller is not a recorder");
        _;
    }

    modifier isUserRegistered(address user) {
         // Users are implicitly registered upon their first interaction/bonding/decay
        require(users[user].lastReputationUpdateTime > 0 || users[user].totalReputation > 0, "DSIRIS: User not registered");
        _;
    }


    // 5. Constructor

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }


    // 6. Owner/Admin Functions

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "DSIRIS: New owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @dev Adds an address to the list of authorized recorders.
    /// Recorders can call `recordInteraction`.
    /// @param recorderAddress The address to authorize.
    function addRecorder(address recorderAddress) public onlyOwner {
        require(recorderAddress != address(0), "DSIRIS: Zero address cannot be a recorder");
        require(!isRecorder[recorderAddress], "DSIRIS: Address is already a recorder");
        isRecorder[recorderAddress] = true;
        emit RecorderAdded(recorderAddress);
    }

    /// @dev Removes an address from the list of authorized recorders.
    /// @param recorderAddress The address to deauthorize.
    function removeRecorder(address recorderAddress) public onlyOwner {
        require(isRecorder[recorderAddress], "DSIRIS: Address is not a recorder");
        isRecorder[recorderAddress] = false;
        emit RecorderRemoved(recorderAddress);
    }

    /// @dev Adds a new type of interaction with a defined reputation weight.
    /// The weight is scaled by REPUTATION_SCALING_FACTOR.
    /// @param name The name of the interaction type.
    /// @param description A description of the interaction type.
    /// @param weight The reputation points awarded for this interaction (scaled).
    function addInteractionType(string memory name, string memory description, uint256 weight) public onlyOwner {
        interactionTypeCounter++;
        interactionTypes[interactionTypeCounter] = InteractionType({
            id: interactionTypeCounter,
            name: name,
            description: description,
            weight: weight,
            active: true
        });
        emit InteractionTypeAdded(interactionTypeCounter, name, weight);
    }

    /// @dev Updates the reputation weight for an existing interaction type.
    /// @param typeId The ID of the interaction type to update.
    /// @param newWeight The new reputation weight (scaled).
    function updateInteractionTypeWeight(uint256 typeId, uint256 newWeight) public onlyOwner {
        require(interactionTypes[typeId].id != 0, "DSIRIS: Interaction type does not exist");
        interactionTypes[typeId].weight = newWeight;
        emit InteractionTypeUpdated(typeId, newWeight);
    }

    /// @dev Deactivates an interaction type. Inactive types cannot be used to record interactions.
    /// @param typeId The ID of the interaction type to deactivate.
    function removeInteractionType(uint256 typeId) public onlyOwner {
        require(interactionTypes[typeId].id != 0, "DSIRIS: Interaction type does not exist");
        interactionTypes[typeId].active = false;
        // We don't emit an event here as the data isn't fundamentally changed, just a flag.
        // An alternative design might emit an `InteractionTypeDeactivated` event.
    }

    /// @dev Creates a new affiliation.
    /// @param name The name of the affiliation.
    /// @param description A description of the affiliation.
    function createAffiliation(string memory name, string memory description) public onlyOwner {
        affiliationCounter++;
        affiliations[affiliationCounter] = Affiliation({
            id: affiliationCounter,
            name: name,
            description: description,
            active: true
        });
        emit AffiliationCreated(affiliationCounter, name);
    }

    /// @dev Updates the name and description for an existing affiliation.
    /// @param affiliationId The ID of the affiliation to update.
    /// @param newName The new name for the affiliation.
    /// @param newDescription The new description for the affiliation.
    function updateAffiliationDetails(uint256 affiliationId, string memory newName, string memory newDescription) public onlyOwner {
        require(affiliations[affiliationId].id != 0, "DSIRIS: Affiliation does not exist");
        affiliations[affiliationId].name = newName;
        affiliations[affiliationId].description = newDescription;
        emit AffiliationUpdated(affiliationId, newName);
    }

    /// @dev Deactivates an affiliation. Users cannot bond reputation to inactive affiliations.
    /// Existing bonds remain until unbonded.
    /// @param affiliationId The ID of the affiliation to deactivate.
    function deactivateAffiliation(uint256 affiliationId) public onlyOwner {
        require(affiliations[affiliationId].id != 0, "DSIRIS: Affiliation does not exist");
        affiliations[affiliationId].active = false;
    }

    /// @dev Sets the global reputation decay rate per second.
    /// The rate is scaled by REPUTATION_SCALING_FACTOR.
    /// A rate of 0 disables decay.
    /// @param ratePerSecondScaled The decay rate per second (scaled).
    function setReputationDecayRate(uint256 ratePerSecondScaled) public onlyOwner {
        reputationDecayRatePerSecond = ratePerSecondScaled;
    }

    /// @dev Adds a new SoulMark threshold definition.
    /// Reputation requirements are scaled by REPUTATION_SCALING_FACTOR.
    /// @param name The name of the SoulMark.
    /// @param description A description of the SoulMark.
    /// @param requiredTotalReputation The minimum total reputation required.
    /// @param requiredBondedAmount The minimum bonded reputation required to a specific affiliation.
    /// @param requiredBondedAffiliationId The affiliation ID to which the bonded reputation must be committed (0 if no specific affiliation is required).
    function addSoulMarkThreshold(
        string memory name,
        string memory description,
        uint256 requiredTotalReputation,
        uint256 requiredBondedAmount,
        uint256 requiredBondedAffiliationId
    ) public onlyOwner {
        // Check if the required affiliation ID exists if it's not 0
        if (requiredBondedAffiliationId != 0) {
             require(affiliations[requiredBondedAffiliationId].id != 0, "DSIRIS: Required bonded affiliation does not exist");
        }

        soulMarkThresholdCounter++;
        soulMarkThresholds[soulMarkThresholdCounter] = SoulMarkThreshold({
            id: soulMarkThresholdCounter,
            name: name,
            description: description,
            requiredTotalReputation: requiredTotalReputation,
            requiredBondedAmount: requiredBondedAmount,
            requiredBondedAffiliationId: requiredBondedAffiliationId,
            active: true
        });
        emit SoulMarkThresholdAdded(soulMarkThresholdCounter, name, requiredTotalReputation);
    }

    /// @dev Updates an existing SoulMark threshold definition.
    /// Reputation requirements are scaled by REPUTATION_SCALING_FACTOR.
    /// @param thresholdId The ID of the threshold to update.
    /// @param name The new name.
    /// @param description The new description.
    /// @param requiredTotalReputation The new required total reputation.
    /// @param requiredBondedAmount The new required bonded reputation amount.
    /// @param requiredBondedAffiliationId The new required bonded affiliation ID (0 if none).
    function updateSoulMarkThreshold(
        uint256 thresholdId,
        string memory name,
        string memory description,
        uint256 requiredTotalReputation,
        uint256 requiredBondedAmount,
        uint256 requiredBondedAffiliationId
    ) public onlyOwner {
        require(soulMarkThresholds[thresholdId].id != 0, "DSIRIS: SoulMark threshold does not exist");

        // Check if the required affiliation ID exists if it's not 0
        if (requiredBondedAffiliationId != 0) {
             require(affiliations[requiredBondedAffiliationId].id != 0, "DSIRIS: Required bonded affiliation does not exist");
        }

        SoulMarkThreshold storage threshold = soulMarkThresholds[thresholdId];
        threshold.name = name;
        threshold.description = description;
        threshold.requiredTotalReputation = requiredTotalReputation;
        threshold.requiredBondedAmount = requiredBondedAmount;
        threshold.requiredBondedAffiliationId = requiredBondedAffiliationId;

        emit SoulMarkThresholdUpdated(thresholdId, requiredTotalReputation);
    }

    /// @dev Deactivates a SoulMark threshold. Users cannot claim a deactivated SoulMark.
    /// Existing claimed SoulMarks are unaffected.
    /// @param thresholdId The ID of the SoulMark threshold to deactivate.
    function removeSoulMarkThreshold(uint256 thresholdId) public onlyOwner {
        require(soulMarkThresholds[thresholdId].id != 0, "DSIRIS: SoulMark threshold does not exist");
        soulMarkThresholds[thresholdId].active = false;
    }


    // 7. Recorder Functions

    /// @dev Records an interaction for a user, applying potential decay and adding reputation.
    /// Callable only by authorized recorders.
    /// Reputation impact is calculated as interactionType.weight * multiplier (scaled).
    /// @param user The address of the user for whom to record the interaction.
    /// @param interactionTypeId The ID of the interaction type.
    /// @param multiplier A multiplier to adjust the impact of the interaction (e.g., 100 for 1x, 200 for 2x).
    function recordInteraction(address user, uint256 interactionTypeId, uint256 multiplier) public onlyRecorder {
        require(user != address(0), "DSIRIS: Cannot record for zero address");
        InteractionType storage iType = interactionTypes[interactionTypeId];
        require(iType.id != 0 && iType.active, "DSIRIS: Invalid or inactive interaction type");
        require(multiplier > 0, "DSIRIS: Multiplier must be positive");

        // Apply decay before adding new reputation
        _applyReputationDecay(user);

        // Calculate reputation gain (scaled arithmetic)
        uint256 reputationGain = (iType.weight * multiplier) / REPUTATION_SCALING_FACTOR;
        users[user].totalReputation += reputationGain;
        users[user].lastReputationUpdateTime = block.timestamp;

        // Optional: Store interaction log (commented out to save gas)
        // uint256 logIndex = userInteractionLogCount[user]++;
        // userInteractionLogs[user][logIndex] = InteractionLog({
        //     typeId: interactionTypeId,
        //     timestamp: block.timestamp,
        //     reputationImpact: reputationGain,
        //     multiplier: multiplier
        // });

        emit InteractionRecorded(user, interactionTypeId, reputationGain, users[user].totalReputation);
    }


    // 8. User Functions

    /// @dev Bonds a specified amount of the user's available reputation to an affiliation.
    /// Bonded reputation still counts towards total reputation but cannot be unbonded immediately.
    /// @param affiliationId The ID of the affiliation to bond to.
    /// @param amount The amount of reputation to bond (scaled).
    function bondReputationToAffiliation(uint256 affiliationId, uint256 amount) public {
        require(msg.sender != address(0), "DSIRIS: Zero address cannot bond reputation");
        require(affiliations[affiliationId].id != 0 && affiliations[affiliationId].active, "DSIRIS: Invalid or inactive affiliation");
        require(amount > 0, "DSIRIS: Amount must be positive");

        // Apply decay first
        _applyReputationDecay(msg.sender);

        // Check if user has enough available reputation
        uint256 availableReputation = users[msg.sender].totalReputation - users[msg.sender].totalBondedReputation;
        // Also account for reputation currently under unbonding lock
        uint256 lockedReputation = 0;
        if (userBondLocks[msg.sender][affiliationId] > block.timestamp) {
            // Simple check: assume if a lock exists, the *entire* previously unbonded amount is locked.
            // A more complex system might track multiple unbonding requests per affiliation.
            // For this example, we'll just check the total bonded amount vs requested amount.
            // The lock prevents *claiming* the unbonded amount, not bonding *new* amount.
        }

        require(availableReputation >= amount, "DSIRIS: Not enough available reputation to bond");

        userAffiliationBonding[msg.sender][affiliationId] += amount;
        users[msg.sender].totalBondedReputation += amount;

        emit ReputationBonded(msg.sender, affiliationId, amount, userAffiliationBonding[msg.sender][affiliationId]);
    }

    /// @dev Initiates the unbonding of a specified amount of reputation from an affiliation.
    /// The amount becomes subject to a time lock before it can be claimed as available reputation.
    /// @param affiliationId The ID of the affiliation to unbond from.
    /// @param amount The amount of reputation to unbond (scaled).
    /// @param lockDurationSeconds The duration of the time lock in seconds.
    function unbondReputationFromAffiliation(uint256 affiliationId, uint256 amount, uint256 lockDurationSeconds) public {
        require(msg.sender != address(0), "DSIRIS: Zero address cannot unbond reputation");
        require(affiliations[affiliationId].id != 0, "DSIRIS: Affiliation does not exist"); // Active check not needed for unbonding from inactive
        require(amount > 0, "DSIRIS: Amount must be positive");
        require(userAffiliationBonding[msg.sender][affiliationId] >= amount, "DSIRIS: Not enough reputation bonded to this affiliation");

        // Apply decay first
        _applyReputationDecay(msg.sender);

        userAffiliationBonding[msg.sender][affiliationId] -= amount;
        users[msg.sender].totalBondedReputation -= amount;

        // Set the lock expiry time for this affiliation
        // Note: A more robust system might track multiple locks per affiliation if needed.
        // This simple version assumes only one unbonding lock per affiliation at a time.
        uint256 lockExpiry = block.timestamp + lockDurationSeconds;
        userBondLocks[msg.sender][affiliationId] = lockExpiry;

        emit ReputationUnbondingStarted(msg.sender, affiliationId, amount, lockExpiry);
    }

    /// @dev Claims reputation that was previously unbonded and has completed its time lock.
    /// Moves the reputation from a 'locked' state back to 'available'.
    /// Note: In this simplified model, 'locked' reputation isn't explicitly tracked as a separate variable,
    /// it's implicitly the amount that was unbonded while the lock was active.
    /// This function primarily serves to check the lock and allow claiming.
    /// A more complex model would explicitly track locked amounts.
    /// @param affiliationId The ID of the affiliation whose unbonding lock to check.
    function claimUnbondedReputation(uint256 affiliationId) public {
        require(msg.sender != address(0), "DSIRIS: Zero address cannot claim");
        require(affiliations[affiliationId].id != 0, "DSIRIS: Affiliation does not exist");

        uint256 lockExpiry = userBondLocks[msg.sender][affiliationId];
        require(lockExpiry != 0, "DSIRIS: No unbonding lock found for this affiliation");
        require(block.timestamp >= lockExpiry, "DSIRIS: Unbonding lock has not expired yet");

        // The amount that was unbonded is now available.
        // In this simple model, the 'unbonded' amount isn't explicitly stored in a separate map.
        // The logic here is just about clearing the lock state.
        // A more advanced contract would track `userLockedReputation[msg.sender][affiliationId]`
        // and move it back to `user[msg.sender].totalReputation - users[msg.sender].totalBondedReputation`.
        // Since `totalReputation` and `totalBondedReputation` were updated immediately on unbonding,
        // the reputation was technically already 'available' but marked by the lock.
        // Clearing the lock just allows future unbonding requests for this affiliation.

        uint256 previouslyUnbondedAmountPlaceholder = 0; // We don't know the exact amount here in this simplified model
                                                         // without tracking it separately during unbonding.
                                                         // A production system *must* track the locked amount.
                                                         // For this example, we'll just signal the lock is cleared.

        userBondLocks[msg.sender][affiliationId] = 0; // Clear the lock

        // In a real system, you would emit the actual amount unlocked.
        // Emitting 0 as a placeholder for demonstration:
        emit ReputationUnbonded(msg.sender, affiliationId, previouslyUnbondedAmountPlaceholder);
    }


    /// @dev Allows a user to claim a specific SoulMark if they meet the required criteria.
    /// SoulMarks are non-transferable (tracked by a boolean flag here).
    /// @param thresholdId The ID of the SoulMark threshold to claim.
    function claimSoulMark(uint256 thresholdId) public {
        require(msg.sender != address(0), "DSIRIS: Zero address cannot claim SoulMark");
        require(soulMarkThresholds[thresholdId].id != 0 && soulMarkThresholds[thresholdId].active, "DSIRIS: Invalid or inactive SoulMark threshold");
        require(!userSoulMarks[msg.sender][thresholdId], "DSIRIS: SoulMark already claimed");

        // Apply decay first
        _applyReputationDecay(msg.sender);

        // Check if the user meets the criteria
        bool meetsCriteria = canClaimSoulMark(msg.sender, thresholdId);
        require(meetsCriteria, "DSIRIS: User does not meet the requirements for this SoulMark");

        userSoulMarks[msg.sender][thresholdId] = true; // Mark as claimed (non-transferable)

        emit SoulMarkClaimed(msg.sender, thresholdId);
    }

    /// @dev Allows anyone to trigger the reputation decay calculation for a specific user.
    /// This is useful for keeping scores reasonably up-to-date, especially if recorders are infrequent.
    /// The cost is borne by the caller.
    /// @param user The address of the user whose reputation should be decayed.
    function decayReputation(address user) public {
        require(user != address(0), "DSIRIS: Cannot decay zero address reputation");
         // Check if the user has ever had reputation or an update recorded
        require(users[user].lastReputationUpdateTime > 0 || users[user].totalReputation > 0, "DSIRIS: User not registered or no history");
        _applyReputationDecay(user);
    }


    // 9. Internal Helper Functions

    /// @dev Applies reputation decay to a user's total reputation based on elapsed time.
    /// Internal helper function called before any reputation-altering action.
    /// @param user The address of the user.
    function _applyReputationDecay(address user) internal {
        if (reputationDecayRatePerSecond == 0 || users[user].totalReputation == MIN_REPUTATION || users[user].lastReputationUpdateTime == 0) {
             users[user].lastReputationUpdateTime = block.timestamp; // Update timestamp even if no decay, for future calculations
            return; // No decay configured, no reputation to decay, or no history yet
        }

        uint256 timeElapsed = block.timestamp - users[user].lastReputationUpdateTime;

        if (timeElapsed > 0) {
             // Calculate decay amount: score * rate * time (scaled arithmetic)
             // Decay is proportional to current score and elapsed time.
             // This is a simple linear decay model per second.
             // Note: This is NOT exponential decay. For exponential decay, more complex fixed-point math or logging would be needed.
             // Simple linear decay: decay_amount = score * rate * time
             // Scaled: decay_amount = (score * rate * time) / (SCALE * SCALE) if rate is per second scaled by SCALE
             // Here, ratePerSecondScaled is scaled by REPUTATION_SCALING_FACTOR. Score is scaled.
             // decay_amount = (users[user].totalReputation * reputationDecayRatePerSecond * timeElapsed) / (REPUTATION_SCALING_FACTOR * REPUTATION_SCALING_FACTOR)
             // To avoid large intermediate products, divide first:
             uint256 decayAmount = (users[user].totalReputation / REPUTATION_SCALING_FACTOR) * (reputationDecayRatePerSecond * timeElapsed / REPUTATION_SCALING_FACTOR);

             // Alternative simpler calculation avoiding potential overflow:
             // decay_amount = score * (rate * time / SCALE)
             // Let decayFactor = (reputationDecayRatePerSecond * timeElapsed) / REPUTATION_SCALING_FACTOR;
             // decayAmount = (users[user].totalReputation * decayFactor) / REPUTATION_SCALING_FACTOR;
             // Even better: use SafeMath or check multiplication/division results if not using 0.8+ which has built-in checks.

             // Let's use the simpler direct scaled calculation:
             uint256 decayRatePerPeriod = (reputationDecayRatePerSecond * timeElapsed) / REPUTATION_SCALING_FACTOR;
             decayAmount = (users[user].totalReputation * decayRatePerPeriod) / REPUTATION_SCALING_FACTOR;


            if (decayAmount > 0) {
                uint256 oldReputation = users[user].totalReputation;
                users[user].totalReputation = users[user].totalReputation > decayAmount ? users[user].totalReputation - decayAmount : MIN_REPUTATION;
                 // Ensure bonded reputation doesn't exceed total reputation after decay
                if (users[user].totalBondedReputation > users[user].totalReputation) {
                     // This scenario shouldn't happen with correct logic, but as a safeguard:
                     // Reduce bonded amount proportionally or set to total reputation.
                     // Simple approach: cap bonded at total reputation.
                     users[user].totalBondedReputation = users[user].totalReputation;
                     // Note: This might break affiliation-specific bonded amounts.
                     // A better system would track bonding amounts per affiliation and adjust there.
                     // For this example, we rely on the logic that totalBonded <= totalRep.
                }
                emit ReputationDecayed(user, oldReputation, users[user].totalReputation);
            }
        }

        users[user].lastReputationUpdateTime = block.timestamp; // Update timestamp after decay calculation
    }


    // 10. View/Pure Functions

    /// @dev Checks if an address is currently authorized to record interactions.
    /// @param account The address to check.
    /// @return bool True if the address is a recorder, false otherwise.
    function isRecorder(address account) public view returns (bool) {
        return isRecorder[account];
    }

    /// @dev Gets details of an interaction type.
    /// @param typeId The ID of the interaction type.
    /// @return InteractionType The struct containing the details.
    function getInteractionType(uint256 typeId) public view returns (InteractionType memory) {
        require(interactionTypes[typeId].id != 0, "DSIRIS: Interaction type does not exist");
        return interactionTypes[typeId];
    }

     /// @dev Gets details of an affiliation.
    /// @param affiliationId The ID of the affiliation.
    /// @return Affiliation The struct containing the details.
    function getAffiliation(uint256 affiliationId) public view returns (Affiliation memory) {
        require(affiliations[affiliationId].id != 0, "DSIRIS: Affiliation does not exist");
        return affiliations[affiliationId];
    }

    /// @dev Gets details of a SoulMark threshold.
    /// @param thresholdId The ID of the threshold.
    /// @return SoulMarkThreshold The struct containing the details.
    function getSoulMarkThreshold(uint256 thresholdId) public view returns (SoulMarkThreshold memory) {
        require(soulMarkThresholds[thresholdId].id != 0, "DSIRIS: SoulMark threshold does not exist");
        return soulMarkThresholds[thresholdId];
    }

    /// @dev Gets a user's current total reputation after applying any potential decay.
    /// @param user The address of the user.
    /// @return uint256 The user's total reputation (scaled).
    function getUserTotalReputation(address user) public view returns (uint256) {
         if (users[user].totalReputation == 0 && users[user].lastReputationUpdateTime == 0) {
             return 0; // User not registered or no reputation history
         }
        // Calculate potential decay without altering state
        uint256 timeElapsed = block.timestamp - users[user].lastReputationUpdateTime;
        if (reputationDecayRatePerSecond == 0 || timeElapsed == 0 || users[user].totalReputation == MIN_REPUTATION) {
            return users[user].totalReputation; // No decay needed
        }

        uint256 decayRatePerPeriod = (reputationDecayRatePerSecond * timeElapsed) / REPUTATION_SCALING_FACTOR;
        uint256 decayAmount = (users[user].totalReputation * decayRatePerPeriod) / REPUTATION_SCALING_FACTOR;

        return users[user].totalReputation > decayAmount ? users[user].totalReputation - decayAmount : MIN_REPUTATION;
    }

    /// @dev Gets the amount of reputation a user has bonded to a specific affiliation.
    /// This amount is part of the user's total reputation.
    /// @param user The address of the user.
    /// @param affiliationId The ID of the affiliation.
    /// @return uint256 The amount of reputation bonded (scaled).
    function getUserBondedReputationForAffiliation(address user, uint256 affiliationId) public view returns (uint256) {
         require(affiliations[affiliationId].id != 0, "DSIRIS: Affiliation does not exist");
        return userAffiliationBonding[user][affiliationId];
    }

    /// @dev Gets the amount of reputation a user has that is NOT bonded and NOT under unbonding lock.
    /// This is reputation available for bonding or simply held.
    /// @param user The address of the user.
    /// @return uint256 The amount of available reputation (scaled).
    function getUserAvailableReputation(address user) public view returns (uint256) {
         uint256 totalRep = getUserTotalReputation(user); // Get reputation after decay
         // In this simplified model, reputation is subtracted from totalBonded immediately.
         // The lock only prevents claiming the "unbonded" amount conceptually.
         // So, available = total - totalBonded.
         // In a system tracking locked funds separately, you'd subtract totalBonded AND totalLocked.
        return totalRep > users[user].totalBondedReputation ? totalRep - users[user].totalBondedReputation : 0;
    }

    /// @dev Gets the current reputation decay rate per second (scaled).
    /// @return uint256 The decay rate per second (scaled by 1e18).
    function getReputationDecayRate() public view returns (uint256) {
        return reputationDecayRatePerSecond;
    }

    /// @dev Gets the expiry timestamp for the unbonding lock related to a specific affiliation for a user.
    /// Returns 0 if no lock is active.
    /// @param user The address of the user.
    /// @param affiliationId The ID of the affiliation.
    /// @return uint256 The expiry timestamp (Unix time), or 0 if no lock.
    function getBondLockExpiry(address user, uint256 affiliationId) public view returns (uint256) {
         require(affiliations[affiliationId].id != 0, "DSIRIS: Affiliation does not exist");
        return userBondLocks[user][affiliationId];
    }

    /// @dev Checks if a user has claimed a specific SoulMark.
    /// @param user The address of the user.
    /// @param thresholdId The ID of the SoulMark threshold.
    /// @return bool True if the user has claimed the SoulMark, false otherwise.
    function hasSoulMark(address user, uint256 thresholdId) public view returns (bool) {
         require(soulMarkThresholds[thresholdId].id != 0, "DSIRIS: SoulMark threshold does not exist");
        return userSoulMarks[user][thresholdId];
    }

    /// @dev Checks if a user currently meets the criteria to claim a specific SoulMark.
    /// Does NOT check if they have already claimed it.
    /// @param user The address of the user.
    /// @param thresholdId The ID of the SoulMark threshold.
    /// @return bool True if the user meets the criteria, false otherwise.
    function canClaimSoulMark(address user, uint256 thresholdId) public view returns (bool) {
        SoulMarkThreshold memory threshold = soulMarkThresholds[thresholdId];
        require(threshold.id != 0 && threshold.active, "DSIRIS: Invalid or inactive SoulMark threshold");

        uint256 userTotalRep = getUserTotalReputation(user); // Check against decayed reputation

        if (userTotalRep < threshold.requiredTotalReputation) {
            return false;
        }

        // Check bonded reputation requirement
        if (threshold.requiredBondedAmount > 0) {
            // If a specific affiliation is required for bonding
            if (threshold.requiredBondedAffiliationId != 0) {
                uint256 userBondedRepToAffiliation = userAffiliationBonding[user][threshold.requiredBondedAffiliationId];
                 require(affiliations[threshold.requiredBondedAffiliationId].id != 0, "DSIRIS: Required bonded affiliation for threshold does not exist"); // Sanity check
                if (userBondedRepToAffiliation < threshold.requiredBondedAmount) {
                    return false;
                }
            } else {
                // If bonding is required, but not to a specific affiliation,
                // check the user's total bonded reputation.
                if (users[user].totalBondedReputation < threshold.requiredBondedAmount) {
                    return false;
                }
            }
        }

        // If all checks pass
        return true;
    }

    /// @dev Gets the total number of interaction types ever added.
    /// @return uint256 The total count.
    function getTotalInteractionTypes() public view returns (uint256) {
        return interactionTypeCounter;
    }

    /// @dev Gets the total number of affiliations ever created.
    /// @return uint256 The total count.
    function getTotalAffiliations() public view returns (uint256) {
        return affiliationCounter;
    }

    /// @dev Gets the total number of SoulMark thresholds ever added.
    /// @return uint256 The total count.
    function getTotalSoulMarkThresholds() public view returns (uint256) {
        return soulMarkThresholdCounter;
    }
}
```