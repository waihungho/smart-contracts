Okay, here is a Solidity smart contract implementing a system of "Stateful Relics". These are dynamic non-fungible tokens (NFTs) that evolve over time and based on interactions, possessing properties and unlockable features.

The concept focuses on:
1.  **Dynamic State:** Relics have different `RelicState`s that change based on conditions.
2.  **Time-Based Mechanics:** Relics can decay or mature over time, affecting their properties and state.
3.  **Interaction Mechanics:** Users can interact with relics (e.g., `feedRelic`, `repairRelic`) to influence their state and properties.
4.  **Programmable Properties:** Relics have quantifiable properties (`RelicProperties`) that change.
5.  **Unlockable Features:** Specific states and property thresholds can unlock special features associated with a relic.
6.  **Complex Actions:** Relics can undergo more complex transformations like `combineRelics` or `splitRelic` under specific conditions.
7.  **Attunement:** Relics can be temporarily bound to an owner, preventing transfer but potentially offering benefits (simulated).
8.  **Admin Controls:** Functions for initial minting, setting parameters, and simulating external impacts or overriding state for management/correction.
9.  **Non-Standard NFT:** While inspired by ERC-721, the core NFT functions (mint, transfer, ownership, approval) are implemented manually within this contract to avoid directly duplicating a standard library, focusing on the *unique* stateful logic.

**Outline:**

1.  **License and Pragma**
2.  **Error Definitions**
3.  **Events**
4.  **Enums**
5.  **Structs**
6.  **State Variables**
7.  **Modifiers**
8.  **Constructor**
9.  **Admin & Pausing Functions**
10. **Ownership Functions**
11. **Feeder Access Control Functions**
12. **Core NFT Functions (Manual Implementation)**
13. **Relic State & Property Management Functions**
14. **Feature Management Functions**
15. **Complex Relic Interaction Functions**
16. **Query Functions**
17. **Internal/Helper Functions**

**Function Summary:**

*   `constructor()`: Initializes the contract owner.
*   `transferOwnership(address newOwner)`: Transfers contract ownership to a new address (Admin).
*   `renounceOwnership()`: Relinquishes contract ownership (Admin).
*   `pause()`: Pauses contract actions affected by `whenNotPaused` (Admin).
*   `unpause()`: Unpauses the contract (Admin).
*   `addAllowedFeeder(address feeder)`: Grants an address permission to call `feedRelic` (Admin).
*   `removeAllowedFeeder(address feeder)`: Revokes feeder permission (Admin).
*   `isAllowedFeeder(address feeder)`: Checks if an address is an allowed feeder (Query).
*   `setDecayRatePerUnitTime(uint rate)`: Sets the rate at which relic integrity decays (Admin).
*   `setFeedingIntegrityBoost(uint boost)`: Sets the integrity boost from feeding (Admin).
*   `setAttunementDuration(uint duration)`: Sets the duration for relic attunement (Admin).
*   `setFeatureRequirements(uint featureId, RelicState requiredState, uint requiredIntegrity, uint requiredEssence)`: Sets the conditions required to unlock a specific feature (Admin).
*   `simulateExternalImpact(uint tokenId, int integrityDelta, int purityDelta, int essenceDelta, uint impactSeverity)`: Simulates an external event affecting a relic's properties (Admin).
*   `migrateRelicState(uint tokenId, RelicState newState)`: Allows admin to override a relic's state (Admin).
*   `migrateRelicProperties(uint tokenId, RelicProperties memory newProperties)`: Allows admin to override a relic's properties (Admin).
*   `forceUnlockFeature(uint tokenId, uint featureId)`: Forces a specific feature to be unlocked for a relic (Admin).
*   `lockFeature(uint tokenId, uint featureId)`: Locks a specific feature for a relic (Admin).
*   `mintRelic(address to, RelicProperties initialProperties)`: Mints a new relic with initial properties (Admin).
*   `ownerOf(uint tokenId)`: Returns the owner of a relic (Query).
*   `balanceOf(address owner)`: Returns the number of relics owned by an address (Query).
*   `approve(address to, uint tokenId)`: Approves an address to transfer a specific relic (NFT Core).
*   `getApproved(uint tokenId)`: Gets the approved address for a relic (Query).
*   `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all of sender's relics (NFT Core).
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all of an owner's relics (Query).
*   `transferFrom(address from, address to, uint tokenId)`: Transfers a relic from one address to another (NFT Core).
*   `getTotalSupply()`: Returns the total number of relics minted (Query).
*   `getRelicState(uint tokenId)`: Returns the current state of a relic (Query).
*   `getRelicProperties(uint tokenId)`: Returns the current properties of a relic (Query).
*   `getLastStateChangeTime(uint tokenId)`: Returns the last time a relic's state/properties were significantly updated (Query).
*   `getRelicCreationTime(uint tokenId)`: Returns the creation time of a relic (Query).
*   `updateRelicState(uint tokenId)`: Applies time-based decay and updates the relic's state based on current properties (User/Approved).
*   `feedRelic(uint tokenId)`: Feeds a relic, increasing its integrity (User/Approved/Feeder).
*   `repairRelic(uint tokenId)`: Repairs a decaying relic, restoring integrity and changing state (User/Approved).
*   `attuneRelic(uint tokenId)`: Attunes a relic to its owner for a period, changing state (Owner).
*   `breakAttunement(uint tokenId)`: Breaks a relic's attunement early, changing state and applying penalty (Owner).
*   `combineRelics(uint tokenId1, uint tokenId2)`: Combines two relics, burning one and boosting the properties of the other (Owner).
*   `splitRelic(uint tokenId)`: Splits a relic, creating a new one and reducing the essence of the original (Owner).
*   `redeemEssence(uint tokenId, uint amount)`: Burns essence from a relic, potentially as a cost for some off-chain action (Owner).
*   `tryUnlockFeature(uint tokenId, uint featureId)`: Checks if conditions are met to unlock a specific feature and unlocks it if so (User/Approved).
*   `isFeatureUnlocked(uint tokenId, uint featureId)`: Checks if a specific feature is unlocked for a relic (Query).
*   `getFeatureRequirements(uint featureId)`: Returns the required state and properties to unlock a specific feature (Query).
*   `checkRelicCompatibility(uint tokenId1, uint tokenId2)`: Checks if two relics can be combined and returns a reason if not (Query).
*   `getCurrentAttunementStatus(uint tokenId)`: Checks if a relic is currently attuned and how much time remains (Query).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. License and Pragma
// 2. Error Definitions
// 3. Events
// 4. Enums
// 5. Structs
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Admin & Pausing Functions
// 10. Ownership Functions
// 11. Feeder Access Control Functions
// 12. Core NFT Functions (Manual Implementation)
// 13. Relic State & Property Management Functions
// 14. Feature Management Functions
// 15. Complex Relic Interaction Functions
// 16. Query Functions
// 17. Internal/Helper Functions

// --- Function Summary ---
// constructor()
// transferOwnership(address newOwner)
// renounceOwnership()
// pause()
// unpause()
// addAllowedFeeder(address feeder)
// removeAllowedFeeder(address feeder)
// isAllowedFeeder(address feeder)
// setDecayRatePerUnitTime(uint rate)
// setFeedingIntegrityBoost(uint boost)
// setAttunementDuration(uint duration)
// setFeatureRequirements(uint featureId, RelicState requiredState, uint requiredIntegrity, uint requiredEssence)
// simulateExternalImpact(uint tokenId, int integrityDelta, int purityDelta, int essenceDelta, uint impactSeverity)
// migrateRelicState(uint tokenId, RelicState newState)
// migrateRelicProperties(uint tokenId, RelicProperties memory newProperties)
// forceUnlockFeature(uint tokenId, uint featureId)
// lockFeature(uint tokenId, uint featureId)
// mintRelic(address to, RelicProperties initialProperties)
// ownerOf(uint tokenId)
// balanceOf(address owner)
// approve(address to, uint tokenId)
// getApproved(uint tokenId)
// setApprovalForAll(address operator, bool approved)
// isApprovedForAll(address owner, address operator)
// transferFrom(address from, address to, uint tokenId)
// getTotalSupply()
// getRelicState(uint tokenId)
// getRelicProperties(uint tokenId)
// getLastStateChangeTime(uint tokenId)
// getRelicCreationTime(uint tokenId)
// updateRelicState(uint tokenId)
// feedRelic(uint tokenId)
// repairRelic(uint tokenId)
// attuneRelic(uint tokenId)
// breakAttunement(uint tokenId)
// combineRelics(uint tokenId1, uint tokenId2)
// splitRelic(uint tokenId)
// redeemEssence(uint tokenId, uint amount)
// tryUnlockFeature(uint tokenId, uint featureId)
// isFeatureUnlocked(uint tokenId, uint featureId)
// getFeatureRequirements(uint featureId)
// checkRelicCompatibility(uint tokenId1, uint tokenId2)
// getCurrentAttunementStatus(uint tokenId)


contract StatefulRelics {

    // --- Error Definitions ---
    error NotOwnerOrApproved();
    error OnlyOwnerCanAttune();
    error RelicDoesNotExist(uint tokenId);
    error InvalidRecipient();
    error TransferCallerNotOwnerApproved();
    error RelicAttuned(uint tokenId);
    error RelicNotAttuned(uint tokenId);
    error RelicCannotPerformActionInState(uint tokenId, RelicState currentState);
    error NotEnoughProperties(uint tokenId, uint requiredIntegrity, uint requiredEssence);
    error FeatureAlreadyUnlocked(uint tokenId, uint featureId);
    error FeatureRequirementsNotMet(uint tokenId, uint featureId);
    error InvalidFeatureId(uint featureId);
    error NotEnoughEssence(uint tokenId, uint requiredAmount);
    error RelicsNotCompatible(uint tokenId1, uint tokenId2, string reason);
    error ZeroAddress();
    error SelfApproval();


    // --- Events ---
    event RelicMinted(address indexed to, uint indexed tokenId, RelicState initialState, RelicProperties initialProperties);
    event RelicStateChanged(uint indexed tokenId, RelicState oldState, RelicState newState);
    event RelicPropertiesChanged(uint indexed tokenId, RelicProperties oldProperties, RelicProperties newProperties);
    event FeatureUnlocked(uint indexed tokenId, uint indexed featureId);
    event RelicAttuned(uint indexed tokenId, address indexed owner, uint attunementEndTime);
    event AttunementBroken(uint indexed tokenId, address indexed owner);
    event RelicsCombined(uint indexed tokenId1, uint indexed tokenId2, uint indexed newTokenId1, RelicProperties newProperties1); // tokenId2 burned
    event RelicSplit(uint indexed oldTokenId, uint indexed newTokenId, RelicProperties oldRelicNewProperties, RelicProperties newRelicProperties);
    event EssenceRedeemed(uint indexed tokenId, uint amount, uint remainingEssence);
    event DecayRateUpdated(uint newRate);
    event FeedingBoostUpdated(uint newBoost);
    event AttunementDurationUpdated(uint newDuration);
    event FeatureRequirementsUpdated(uint indexed featureId, RelicState requiredState, uint requiredIntegrity, uint requiredEssence);
    event ExternalImpactSimulated(uint indexed tokenId, int integrityDelta, int purityDelta, int essenceDelta);
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event AllowedFeederUpdated(address indexed feeder, bool isAllowed);
    event Paused(address account);
    event Unpaused(address account);


    // --- Enums ---
    enum RelicState { Sealed, Active, Decaying, Attuned, Broken, Fused } // Example states


    // --- Structs ---
    struct RelicProperties {
        uint strength;
        uint agility;
        uint integrity; // Decays over time
        uint purity;    // Boosted by feeding, reduced by decay
        uint essence;   // Used for splitting/redeeming
    }

    struct RelicData {
        uint creationTime;
        RelicState currentState;
        RelicProperties properties;
        uint lastStateChangeTime; // Timestamp for decay/time-based calculations
        uint attunementEndTime;   // Timestamp when attunement ends (0 if not attuned)
        mapping(uint => bool) unlockedFeatures; // Mapping from featureId => unlocked status
    }

    struct FeatureRequirement {
        RelicState requiredState;
        uint requiredIntegrity;
        uint requiredEssence;
    }


    // --- State Variables ---
    address private _owner;
    bool private _paused;

    uint private _nextTokenId;
    uint private _totalSupply;

    // Manual NFT mappings (to avoid duplicating OpenZeppelin libraries directly)
    mapping(uint => address) private _ownerOf;
    mapping(address => uint) private _balanceOf;
    mapping(uint => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint => RelicData) private _relics;

    // Configuration parameters
    uint public decayRatePerUnitTime; // Integrity points lost per second
    uint public feedingIntegrityBoost; // Integrity points gained per feed
    uint public attunementDuration;   // Duration of attunement in seconds

    // Feature requirements
    mapping(uint => FeatureRequirement) private _featureRequirements;

    // Feeder permissions
    mapping(address => bool) public allowedFeeders;


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Only owner");
        }
        _;
    }

    modifier whenNotPaused() {
        if (_paused) {
            revert("Paused");
        }
        _;
    }

    modifier whenPaused() {
        if (!_paused) {
            revert("Not paused");
        }
        _;
    }

    modifier onlyRelicOwnerOrApproved(uint tokenId) {
        if (_ownerOf[tokenId] != msg.sender && _tokenApprovals[tokenId] != msg.sender && !_operatorApprovals[_ownerOf[tokenId]][msg.sender]) {
            revert NotOwnerOrApproved();
        }
        _;
    }

    modifier onlyRelicOwner(uint tokenId) {
         if (_ownerOf[tokenId] != msg.sender) {
            revert NotOwnerOrApproved();
        }
        _;
    }

     modifier relicExists(uint tokenId) {
        if (!_exists(tokenId)) {
            revert RelicDoesNotExist(tokenId);
        }
        _;
    }


    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _paused = false;
        _nextTokenId = 1; // Start token IDs from 1
        decayRatePerUnitTime = 1; // Default decay rate (can be changed by owner)
        feedingIntegrityBoost = 10; // Default boost
        attunementDuration = 7 days; // Default attunement duration
    }


    // --- Admin & Pausing Functions ---

    /**
     * @notice Pauses the contract, preventing most state-changing operations.
     * @dev Only the owner can call this.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing state-changing operations again.
     * @dev Only the owner can call this.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Sets the decay rate for relic integrity.
     * @param rate The new decay rate (integrity points lost per second).
     * @dev Only the owner can call this.
     */
    function setDecayRatePerUnitTime(uint rate) external onlyOwner {
        decayRatePerUnitTime = rate;
        emit DecayRateUpdated(rate);
    }

    /**
     * @notice Sets the integrity boost gained from feeding a relic.
     * @param boost The new integrity boost value.
     * @dev Only the owner can call this.
     */
    function setFeedingIntegrityBoost(uint boost) external onlyOwner {
        feedingIntegrityBoost = boost;
        emit FeedingBoostUpdated(boost);
    }

    /**
     * @notice Sets the duration for relic attunement.
     * @param duration The new attunement duration in seconds.
     * @dev Only the owner can call this.
     */
    function setAttunementDuration(uint duration) external onlyOwner {
        attunementDuration = duration;
        emit AttunementDurationUpdated(duration);
    }

    /**
     * @notice Sets the required conditions (state and properties) to unlock a specific feature.
     * @param featureId The ID of the feature.
     * @param requiredState The state the relic must be in.
     * @param requiredIntegrity The minimum integrity required.
     * @param requiredEssence The minimum essence required.
     * @dev Only the owner can call this.
     */
    function setFeatureRequirements(uint featureId, RelicState requiredState, uint requiredIntegrity, uint requiredEssence) external onlyOwner {
        _featureRequirements[featureId] = FeatureRequirement(requiredState, requiredIntegrity, requiredEssence);
        emit FeatureRequirementsUpdated(featureId, requiredState, requiredIntegrity, requiredEssence);
    }

    /**
     * @notice Simulates an external impact (positive or negative) on a relic's properties.
     * @param tokenId The ID of the relic.
     * @param integrityDelta Change in integrity (+/-).
     * @param purityDelta Change in purity (+/-).
     * @param essenceDelta Change in essence (+/-).
     * @param impactSeverity An arbitrary value indicating impact magnitude (for logging/indexing).
     * @dev Only the owner can call this. Bypasses normal state update logic.
     */
    function simulateExternalImpact(uint tokenId, int integrityDelta, int purityDelta, int essenceDelta, uint impactSeverity) external onlyOwner relicExists(tokenId) {
        RelicData storage relic = _relics[tokenId];
        RelicProperties memory oldProperties = relic.properties;

        // Apply deltas carefully to avoid underflows/overflows with signed integers
        relic.properties.integrity = uint(int(relic.properties.integrity) + integrityDelta);
        relic.properties.purity = uint(int(relic.properties.purity) + purityDelta);
        relic.properties.essence = uint(int(relic.properties.essence) + essenceDelta);

        // Ensure properties don't go below zero (although uint handles this, safer logic might exist)
        if (int(relic.properties.integrity) < 0) relic.properties.integrity = 0;
        if (int(relic.properties.purity) < 0) relic.properties.purity = 0;
        if (int(relic.properties.essence) < 0) relic.properties.essence = 0;

        relic.lastStateChangeTime = block.timestamp; // Mark state as changed
        emit ExternalImpactSimulated(tokenId, integrityDelta, purityDelta, essenceDelta);
        emit RelicPropertiesChanged(tokenId, oldProperties, relic.properties);
    }

    /**
     * @notice Allows the owner to manually set a relic's state. Use with caution.
     * @param tokenId The ID of the relic.
     * @param newState The new state to set.
     * @dev Only the owner can call this. Bypasses normal state transition logic.
     */
    function migrateRelicState(uint tokenId, RelicState newState) external onlyOwner relicExists(tokenId) {
        RelicData storage relic = _relics[tokenId];
        RelicState oldState = relic.currentState;
        if (oldState != newState) {
            relic.currentState = newState;
            relic.lastStateChangeTime = block.timestamp;
            emit RelicStateChanged(tokenId, oldState, newState);
        }
    }

    /**
     * @notice Allows the owner to manually set a relic's properties. Use with caution.
     * @param tokenId The ID of the relic.
     * @param newProperties The new properties to set.
     * @dev Only the owner can call this. Bypasses normal property change logic.
     */
    function migrateRelicProperties(uint tokenId, RelicProperties memory newProperties) external onlyOwner relicExists(tokenId) {
        RelicData storage relic = _relics[tokenId];
        RelicProperties memory oldProperties = relic.properties;
        relic.properties = newProperties;
        relic.lastStateChangeTime = block.timestamp;
        emit RelicPropertiesChanged(tokenId, oldProperties, newProperties);
    }

    /**
     * @notice Forces a specific feature to be unlocked for a relic, bypassing requirements. Use with caution.
     * @param tokenId The ID of the relic.
     * @param featureId The ID of the feature to unlock.
     * @dev Only the owner can call this.
     */
    function forceUnlockFeature(uint tokenId, uint featureId) external onlyOwner relicExists(tokenId) {
        RelicData storage relic = _relics[tokenId];
        if (!relic.unlockedFeatures[featureId]) {
            relic.unlockedFeatures[featureId] = true;
            emit FeatureUnlocked(tokenId, featureId);
        }
    }

     /**
     * @notice Locks a specific feature for a relic. Use with caution.
     * @param tokenId The ID of the relic.
     * @param featureId The ID of the feature to lock.
     * @dev Only the owner can call this.
     */
    function lockFeature(uint tokenId, uint featureId) external onlyOwner relicExists(tokenId) {
        RelicData storage relic = _relics[tokenId];
         if (relic.unlockedFeatures[featureId]) {
            relic.unlockedFeatures[featureId] = false;
            // Consider emitting a FeatureLocked event if needed
        }
    }


    // --- Ownership Functions ---

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @param newOwner The address of the new owner.
     * @dev Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        _owner = newOwner;
        // Consider emitting an event like OwnershipTransferred
    }

    /**
     * @notice Renounces the owner role for the contract.
     * @dev Grants renounced ownership to the zero address.
     *      Only the owner can call this.
     */
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
         // Consider emitting an event like OwnershipTransferred
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function getOwner() external view returns (address) {
        return _owner;
    }


    // --- Feeder Access Control Functions ---

    /**
     * @notice Adds an address to the list of allowed feeders who can call `feedRelic`.
     * @param feeder The address to add.
     * @dev Only the owner can call this.
     */
    function addAllowedFeeder(address feeder) external onlyOwner {
        if (feeder == address(0)) revert ZeroAddress();
        allowedFeeders[feeder] = true;
        emit AllowedFeederUpdated(feeder, true);
    }

    /**
     * @notice Removes an address from the list of allowed feeders.
     * @param feeder The address to remove.
     * @dev Only the owner can call this.
     */
    function removeAllowedFeeder(address feeder) external onlyOwner {
        allowedFeeders[feeder] = false;
        emit AllowedFeederUpdated(feeder, false);
    }

    /**
     * @notice Checks if an address is currently an allowed feeder.
     * @param feeder The address to check.
     * @return A boolean indicating if the address is an allowed feeder.
     * @dev Can be called by anyone.
     */
    function isAllowedFeeder(address feeder) external view returns (bool) {
        return allowedFeeders[feeder];
    }


    // --- Core NFT Functions (Manual Implementation) ---

    /**
     * @notice Mints a new relic.
     * @param to The address to mint the relic to.
     * @param initialProperties The initial properties of the relic.
     * @return The ID of the newly minted relic.
     * @dev Only the owner can call this. Assigns a unique token ID.
     */
    function mintRelic(address to, RelicProperties memory initialProperties) external onlyOwner whenNotPaused returns (uint) {
        if (to == address(0)) revert InvalidRecipient();

        uint tokenId = _nextTokenId;
        _nextTokenId++;

        _mint(to, tokenId, initialProperties);

        return tokenId;
    }

    /**
     * @notice Returns the owner of the relic with the given token ID.
     * @param tokenId The ID of the relic.
     * @return The address of the relic's owner.
     * @dev Reverts if the token ID does not exist.
     */
    function ownerOf(uint tokenId) public view relicExists(tokenId) returns (address) {
        return _ownerOf[tokenId];
    }

    /**
     * @notice Returns the number of relics owned by an address.
     * @param owner The address to query the balance of.
     * @return The number of relics owned by the address.
     */
    function balanceOf(address owner) public view returns (uint) {
        return _balanceOf[owner];
    }

    /**
     * @notice Approves another address to transfer a specific relic on behalf of the owner.
     * @param to The address to approve.
     * @param tokenId The ID of the relic to approve.
     * @dev Requires the sender to be the owner of the relic.
     *      Reverts if the token does not exist or if attempting to approve the current owner.
     */
    function approve(address to, uint tokenId) external whenNotPaused relicExists(tokenId) {
        address owner = _ownerOf[tokenId];
        if (msg.sender != owner) {
            revert NotOwnerOrApproved(); // Only owner can approve
        }
         if (to == owner) {
            revert SelfApproval();
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @notice Gets the approved address for a specific relic.
     * @param tokenId The ID of the relic.
     * @return The approved address, or address(0) if no address is approved.
     * @dev Reverts if the token ID does not exist.
     */
    function getApproved(uint tokenId) public view relicExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @notice Approves or disapproves an operator for all relics owned by the sender.
     * @param operator The address of the operator.
     * @param approved True to approve, false to disapprove.
     * @dev The operator can manage all relics owned by the sender.
     */
    function setApprovalForAll(address operator, bool approved) external whenNotPaused {
        if (operator == address(0)) revert ZeroAddress();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Checks if an operator is approved for all relics owned by a specific owner.
     * @param owner The address of the owner.
     * @param operator The address of the operator.
     * @return True if the operator is approved, false otherwise.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice Transfers a relic from one address to another.
     * @param from The address of the current owner.
     * @param to The address of the recipient.
     * @param tokenId The ID of the relic to transfer.
     * @dev The sender must be the current owner, the approved address, or an authorized operator.
     *      Reverts if the token does not exist, the owner is not `from`, or `to` is the zero address.
     */
    function transferFrom(address from, address to, uint tokenId) public whenNotPaused relicExists(tokenId) {
        address owner = _ownerOf[tokenId];
        if (owner != from) revert TransferCallerNotOwnerApproved();
        if (to == address(0)) revert InvalidRecipient();

        // Check if sender is owner, approved, or operator
        if (msg.sender != owner && _tokenApprovals[tokenId] != msg.sender && !_operatorApprovals[owner][msg.sender]) {
            revert TransferCallerNotOwnerApproved();
        }

        // Ensure relic is not attuned
        if (_isRelicAttuned(tokenId)) {
             revert RelicAttuned(tokenId);
        }

        _transfer(from, to, tokenId);
    }

    /**
     * @notice Returns the total number of existing relics.
     * @dev This includes burned relics unless the burned count is explicitly tracked (not in this simple example).
     *      Here it refers to total ever minted minus explicit burns.
     */
    function getTotalSupply() external view returns (uint) {
        return _totalSupply;
    }


    // --- Relic State & Property Management Functions ---

    /**
     * @notice Returns the current state of a relic.
     * @param tokenId The ID of the relic.
     * @return The current RelicState.
     * @dev Reverts if the token does not exist.
     */
    function getRelicState(uint tokenId) external view relicExists(tokenId) returns (RelicState) {
        return _relics[tokenId].currentState;
    }

    /**
     * @notice Returns the current properties of a relic.
     * @param tokenId The ID of the relic.
     * @return A memory struct containing the relic's properties.
     * @dev Reverts if the token does not exist.
     */
    function getRelicProperties(uint tokenId) external view relicExists(tokenId) returns (RelicProperties memory) {
        return _relics[tokenId].properties;
    }

     /**
     * @notice Returns the timestamp of the last significant state or property change for a relic.
     * @param tokenId The ID of the relic.
     * @return The timestamp (Unix epoch).
     * @dev Reverts if the token does not exist.
     */
    function getLastStateChangeTime(uint tokenId) external view relicExists(tokenId) returns (uint) {
        return _relics[tokenId].lastStateChangeTime;
    }

     /**
     * @notice Returns the creation timestamp of a relic.
     * @param tokenId The ID of the relic.
     * @return The timestamp (Unix epoch).
     * @dev Reverts if the token does not exist.
     */
    function getRelicCreationTime(uint tokenId) external view relicExists(tokenId) returns (uint) {
        return _relics[tokenId].creationTime;
    }


    /**
     * @notice Applies time-based decay and updates the relic's state based on its current properties.
     * @param tokenId The ID of the relic.
     * @dev Can be called by the owner or approved address. This is a core function
     *      to keep relics 'alive' and evolving. Calls `_applyTimeBasedDecay`.
     */
    function updateRelicState(uint tokenId) external whenNotPaused relicExists(tokenId) onlyRelicOwnerOrApproved(tokenId) {
        RelicData storage relic = _relics[tokenId];
        RelicState oldState = relic.currentState;

        // Apply decay first based on *last* update time
        _applyTimeBasedDecay(tokenId);

        // Now evaluate state based on current properties after decay
        RelicState newState = oldState; // Assume no change initially

        if (relic.currentState == RelicState.Attuned && block.timestamp >= relic.attunementEndTime) {
            // Attunement expired
            newState = RelicState.Active;
            relic.attunementEndTime = 0; // Reset attunement end time
        } else if (relic.properties.integrity == 0) {
            newState = RelicState.Broken;
        } else if (relic.properties.integrity < 20 && relic.currentState != RelicState.Broken) {
            newState = RelicState.Decaying;
        } else if (relic.properties.integrity >= 50 && relic.currentState != RelicState.Active && relic.currentState != RelicState.Attuned && relic.currentState != RelicState.Fused) {
             newState = RelicState.Active; // Restore from Decaying/Broken if repaired/boosted
        }
        // Add more complex state transitions based on other properties if desired

        if (newState != oldState) {
            relic.currentState = newState;
            emit RelicStateChanged(tokenId, oldState, newState);
        }

        // Update lastStateChangeTime if any logic was applied or significant time passed
         relic.lastStateChangeTime = block.timestamp;
    }

    /**
     * @notice Feeds a relic, increasing its purity or integrity.
     * @param tokenId The ID of the relic.
     * @dev Can be called by the owner, approved address, or an allowed feeder.
     *      Requires the relic not to be Sealed or Broken.
     */
    function feedRelic(uint tokenId) external whenNotPaused relicExists(tokenId) {
         RelicData storage relic = _relics[tokenId];

         // Check sender is owner, approved, or allowed feeder
         if (_ownerOf[tokenId] != msg.sender && _tokenApprovals[tokenId] != msg.sender && !_operatorApprovals[_ownerOf[tokenId]][msg.sender] && !allowedFeeders[msg.sender]) {
             revert NotOwnerOrApproved();
         }

         if (relic.currentState == RelicState.Sealed || relic.currentState == RelicState.Broken) {
             revert RelicCannotPerformActionInState(tokenId, relic.currentState);
         }

         RelicProperties memory oldProperties = relic.properties;

         // Apply decay before feeding effect
         _applyTimeBasedDecay(tokenId);

         // Apply feeding boost (e.g., increase integrity)
         relic.properties.integrity += feedingIntegrityBoost;
         // Optional: cap properties
         // relic.properties.integrity = Math.min(relic.properties.integrity, MAX_INTEGRITY);

         // Update last state change time
         relic.lastStateChangeTime = block.timestamp;

         emit RelicPropertiesChanged(tokenId, oldProperties, relic.properties);
         // Consider emitting a specific Feed event if needed
    }

    /**
     * @notice Repairs a decaying relic, restoring its integrity and potentially changing its state to Active.
     * @param tokenId The ID of the relic.
     * @dev Can be called by the owner or approved address.
     *      Requires the relic to be in the Decaying or Broken state.
     */
    function repairRelic(uint tokenId) external whenNotPaused relicExists(tokenId) onlyRelicOwnerOrApproved(tokenId) {
        RelicData storage relic = _relics[tokenId];

        if (relic.currentState != RelicState.Decaying && relic.currentState != RelicState.Broken) {
             revert RelicCannotPerformActionInState(tokenId, relic.currentState);
        }

        RelicState oldState = relic.currentState;
        RelicProperties memory oldProperties = relic.properties;

        // Fully restore integrity (example logic)
        relic.properties.integrity = 100; // Example: Max integrity is 100

        // Update state if integrity is high enough
        if (relic.properties.integrity >= 50) {
             relic.currentState = RelicState.Active;
        }

        relic.lastStateChangeTime = block.timestamp;

        if (relic.currentState != oldState) {
            emit RelicStateChanged(tokenId, oldState, relic.currentState);
        }
        emit RelicPropertiesChanged(tokenId, oldProperties, relic.properties);
        // Consider emitting a specific Repair event
    }

    /**
     * @notice Attunes a relic to its owner, making it non-transferable for a duration.
     * @param tokenId The ID of the relic.
     * @dev Can only be called by the relic's owner.
     *      Requires the relic to be in the Active state and not currently Attuned.
     */
    function attuneRelic(uint tokenId) external whenNotPaused relicExists(tokenId) onlyRelicOwner(tokenId) {
        RelicData storage relic = _relics[tokenId];

        if (relic.currentState != RelicState.Active || _isRelicAttuned(tokenId)) {
             revert RelicCannotPerformActionInState(tokenId, relic.currentState);
        }

        RelicState oldState = relic.currentState;
        relic.currentState = RelicState.Attuned;
        relic.attunementEndTime = block.timestamp + attunementDuration;
        relic.lastStateChangeTime = block.timestamp;

        emit RelicStateChanged(tokenId, oldState, RelicState.Attuned);
        emit RelicAttuned(tokenId, msg.sender, relic.attunementEndTime);
    }

    /**
     * @notice Breaks a relic's attunement early.
     * @param tokenId The ID of the relic.
     * @dev Can only be called by the relic's owner.
     *      Requires the relic to be in the Attuned state. May incur a penalty.
     */
    function breakAttunement(uint tokenId) external whenNotPaused relicExists(tokenId) onlyRelicOwner(tokenId) {
        RelicData storage relic = _relics[tokenId];

        if (!_isRelicAttuned(tokenId)) {
            revert RelicNotAttuned(tokenId);
        }

        RelicState oldState = relic.currentState;
        relic.currentState = RelicState.Active; // Return to Active state
        relic.attunementEndTime = 0; // Reset attunement

        // Apply a penalty (example: reduce integrity)
        RelicProperties memory oldProperties = relic.properties;
        if (relic.properties.integrity > 10) { // Avoid underflow
             relic.properties.integrity -= 10; // Example penalty
        } else {
             relic.properties.integrity = 0;
        }


        relic.lastStateChangeTime = block.timestamp;

        if (relic.currentState != oldState) {
            emit RelicStateChanged(tokenId, oldState, relic.currentState);
        }
        emit RelicPropertiesChanged(tokenId, oldProperties, relic.properties);
        emit AttunementBroken(tokenId, msg.sender);
    }


    // --- Feature Management Functions ---

     /**
     * @notice Attempts to unlock a specific feature for a relic if the requirements are met.
     * @param tokenId The ID of the relic.
     * @param featureId The ID of the feature to try and unlock.
     * @dev Can be called by the owner or approved address. First applies decay.
     */
    function tryUnlockFeature(uint tokenId, uint featureId) external whenNotPaused relicExists(tokenId) onlyRelicOwnerOrApproved(tokenId) {
        RelicData storage relic = _relics[tokenId];

        // Apply decay before checking requirements
        _applyTimeBasedDecay(tokenId);

        // Check if feature is already unlocked
        if (relic.unlockedFeatures[featureId]) {
            revert FeatureAlreadyUnlocked(tokenId, featureId);
        }

        // Get feature requirements
        FeatureRequirement memory requirements = _featureRequirements[featureId];
        // Check if requirements exist for this feature ID (non-zero requiredState implies requirements are set)
        if (requirements.requiredState == RelicState.Sealed && requirements.requiredIntegrity == 0 && requirements.requiredEssence == 0 && featureId != 0) {
             revert InvalidFeatureId(featureId); // No requirements set for this ID (assuming featureId 0 is invalid or has trivial requirements)
        }

        // Check if requirements are met
        if (relic.currentState != requirements.requiredState ||
            relic.properties.integrity < requirements.requiredIntegrity ||
            relic.properties.essence < requirements.requiredEssence)
        {
            revert FeatureRequirementsNotMet(tokenId, featureId);
        }

        // Unlock the feature
        relic.unlockedFeatures[featureId] = true;
        emit FeatureUnlocked(tokenId, featureId);

        // Optional: Consume some relic properties upon unlocking
        // relic.properties.essence -= requirements.requiredEssence; // Example cost
        // relic.lastStateChangeTime = block.timestamp; // Update time if properties changed
    }


     /**
     * @notice Checks if a specific feature is unlocked for a relic.
     * @param tokenId The ID of the relic.
     * @param featureId The ID of the feature.
     * @return A boolean indicating if the feature is unlocked.
     * @dev Reverts if the token does not exist.
     */
    function isFeatureUnlocked(uint tokenId, uint featureId) external view relicExists(tokenId) returns (bool) {
        return _relics[tokenId].unlockedFeatures[featureId];
    }


     /**
     * @notice Returns the required conditions to unlock a specific feature.
     * @param featureId The ID of the feature.
     * @return requiredState The required state.
     * @return requiredIntegrity The required minimum integrity.
     * @return requiredEssence The required minimum essence.
     * @dev Returns default values if requirements for the featureId have not been set.
     */
    function getFeatureRequirements(uint featureId) external view returns (RelicState requiredState, uint requiredIntegrity, uint requiredEssence) {
        FeatureRequirement memory requirements = _featureRequirements[featureId];
        return (requirements.requiredState, requirements.requiredIntegrity, requirements.requiredEssence);
    }


    // --- Complex Relic Interaction Functions ---

    /**
     * @notice Combines two relics into one, boosting the properties of the first relic
     *         and burning the second.
     * @param tokenId1 The ID of the primary relic (properties are boosted).
     * @param tokenId2 The ID of the secondary relic (this relic is burned).
     * @dev Can only be called by the owner of both relics.
     *      Requires both relics to be in the Active state (or other suitable state).
     *      Checks compatibility before combining.
     */
    function combineRelics(uint tokenId1, uint tokenId2) external whenNotPaused relicExists(tokenId1) relicExists(tokenId2) onlyRelicOwner(tokenId1) {
        if (tokenId1 == tokenId2) revert RelicsNotCompatible(tokenId1, tokenId2, "Cannot combine a relic with itself");
        if (_ownerOf[tokenId2] != msg.sender) revert NotOwnerOrApproved(); // Ensure owner of second relic too

        RelicData storage relic1 = _relics[tokenId1];
        RelicData storage relic2 = _relics[tokenId2];

        // Check if relics are in a state that allows combining
        if (relic1.currentState != RelicState.Active || relic2.currentState != RelicState.Active) {
             revert RelicsNotCompatible(tokenId1, tokenId2, "Both relics must be Active");
        }

        // Apply decay before combining
        _applyTimeBasedDecay(tokenId1);
        _applyTimeBasedDecay(tokenId2); // Apply decay before reading properties

        RelicProperties memory oldProperties1 = relic1.properties;

        // Example combining logic: Add a fraction of relic2's properties to relic1
        relic1.properties.strength += relic2.properties.strength / 2;
        relic1.properties.agility += relic2.properties.agility / 2;
        relic1.properties.integrity = (relic1.properties.integrity + relic2.properties.integrity) / 2; // Average integrity
        relic1.properties.purity = (relic1.properties.purity + relic2.properties.purity) / 2;         // Average purity
        relic1.properties.essence += relic2.properties.essence / 2;

        // Optional: Change state of relic1 to Fused or similar
        RelicState oldState1 = relic1.currentState;
        relic1.currentState = RelicState.Fused; // Example: Combined relics get Fused state

        relic1.lastStateChangeTime = block.timestamp;

        // Burn the second relic
        _burn(tokenId2);

        if (relic1.currentState != oldState1) {
            emit RelicStateChanged(tokenId1, oldState1, relic1.currentState);
        }
        emit RelicPropertiesChanged(tokenId1, oldProperties1, relic1.properties);
        emit RelicsCombined(tokenId1, tokenId2, tokenId1, relic1.properties);
    }

    /**
     * @notice Splits a relic into two, burning the original and minting two new ones
     *         with derived properties. (Alternative: Keep original, mint one new, cost essence)
     *         Let's implement the alternative: keep original, mint one new, cost essence.
     * @param tokenId The ID of the relic to split.
     * @dev Can only be called by the owner.
     *      Requires the relic to be in a suitable state (e.g., Active or Fused)
     *      and have sufficient essence.
     */
    function splitRelic(uint tokenId) external whenNotPaused relicExists(tokenId) onlyRelicOwner(tokenId) {
        RelicData storage relic = _relics[tokenId];

        // Example: Requires Fused state and minimum essence
        if (relic.currentState != RelicState.Fused) {
             revert RelicCannotPerformActionInState(tokenId, relic.currentState);
        }
         uint splitEssenceCost = 50; // Example cost
        if (relic.properties.essence < splitEssenceCost) {
             revert NotEnoughProperties(tokenId, 0, splitEssenceCost);
        }

        // Apply decay before splitting
        _applyTimeBasedDecay(tokenId);

        RelicProperties memory oldProperties = relic.properties;

        // Define properties for the new relic (example: a fraction of the original)
        RelicProperties memory newRelicProperties;
        newRelicProperties.strength = relic.properties.strength / 3;
        newRelicProperties.agility = relic.properties.agility / 3;
        newRelicProperties.integrity = 100; // New relic starts fresh
        newRelicProperties.purity = 100;     // New relic starts fresh
        newRelicProperties.essence = relic.properties.essence / 3;

        // Adjust properties of the original relic (example: reduce essence and other properties)
        relic.properties.strength -= newRelicProperties.strength;
        relic.properties.agility -= newRelicProperties.agility;
        relic.properties.essence -= splitEssenceCost; // Consume essence

        // Mint the new relic to the original owner
        uint newRelicId = _nextTokenId;
        _nextTokenId++;
        _mint(msg.sender, newRelicId, newRelicProperties);

        // Change state of the original relic (example: back to Active)
        RelicState oldState = relic.currentState;
        relic.currentState = RelicState.Active;

        relic.lastStateChangeTime = block.timestamp;


        if (relic.currentState != oldState) {
            emit RelicStateChanged(tokenId, oldState, relic.currentState);
        }
        emit RelicPropertiesChanged(tokenId, oldProperties, relic.properties);
        emit RelicSplit(tokenId, newRelicId, relic.properties, newRelicProperties);
    }


    /**
     * @notice Allows the owner to redeem essence from a relic.
     * @param tokenId The ID of the relic.
     * @param amount The amount of essence to redeem.
     * @dev Can only be called by the owner.
     *      Requires the relic to have at least the specified amount of essence.
     *      Doesn't result in a state change itself, but reduces a property.
     */
    function redeemEssence(uint tokenId, uint amount) external whenNotPaused relicExists(tokenId) onlyRelicOwner(tokenId) {
        RelicData storage relic = _relics[tokenId];

        if (relic.properties.essence < amount) {
            revert NotEnoughEssence(tokenId, amount);
        }
        if (amount == 0) return; // No change

        RelicProperties memory oldProperties = relic.properties;

        // Apply decay before redeeming
        _applyTimeBasedDecay(tokenId);

        relic.properties.essence -= amount;
        relic.lastStateChangeTime = block.timestamp; // Mark state as changed due to property reduction

        emit EssenceRedeemed(tokenId, amount, relic.properties.essence);
        emit RelicPropertiesChanged(tokenId, oldProperties, relic.properties);
    }


    // --- Query Functions ---

    /**
     * @notice Checks if two relics are compatible for combining and provides a reason if not.
     * @param tokenId1 The ID of the first relic.
     * @param tokenId2 The ID of the second relic.
     * @return canCombine True if compatible, false otherwise.
     * @return reason A string explaining why they are not compatible (empty string if compatible).
     * @dev Can be called by anyone. Does not apply decay or change state.
     */
    function checkRelicCompatibility(uint tokenId1, uint tokenId2) external view returns (bool canCombine, string memory reason) {
        if (!_exists(tokenId1)) return (false, "Relic 1 does not exist");
        if (!_exists(tokenId2)) return (false, "Relic 2 does not exist");
        if (tokenId1 == tokenId2) return (false, "Cannot combine a relic with itself");
        if (_ownerOf[tokenId1] != msg.sender || _ownerOf[tokenId2] != msg.sender) return (false, "Sender must own both relics");

        RelicData storage relic1 = _relics[tokenId1];
        RelicData storage relic2 = _relics[tokenId2];

        // Example compatibility check: Both must be Active state
        if (relic1.currentState != RelicState.Active || relic2.currentState != RelicState.Active) {
            return (false, "Both relics must be in the Active state");
        }

        // Add more complex checks here (e.g., minimum properties, specific types/attributes)
        // if (relic1.properties.integrity < 50 || relic2.properties.integrity < 50) return (false, "Both relics must have high integrity");

        return (true, ""); // Compatible
    }

    /**
     * @notice Checks the current attunement status of a relic.
     * @param tokenId The ID of the relic.
     * @return isAttuned True if currently attuned.
     * @return timeRemaining Seconds remaining until attunement ends (0 if not attuned or expired).
     * @dev Can be called by anyone. Reverts if the token does not exist.
     */
    function getCurrentAttunementStatus(uint tokenId) external view relicExists(tokenId) returns (bool isAttuned, uint timeRemaining) {
        RelicData storage relic = _relics[tokenId];
        if (relic.currentState == RelicState.Attuned && relic.attunementEndTime > block.timestamp) {
            return (true, relic.attunementEndTime - block.timestamp);
        } else {
            return (false, 0);
        }
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev Internal mint function. Handles the actual state updates for minting.
     */
    function _mint(address to, uint tokenId, RelicProperties memory initialProperties) internal {
        // Check if token ID is already used (shouldn't happen with _nextTokenId)
        // if (_exists(tokenId)) revert("ERC721: token already minted"); // Example check

        _ownerOf[tokenId] = to;
        _balanceOf[to]++;
        _relics[tokenId] = RelicData({
            creationTime: block.timestamp,
            currentState: RelicState.Sealed, // Start in Sealed state
            properties: initialProperties,
            lastStateChangeTime: block.timestamp,
            attunementEndTime: 0,
            unlockedFeatures: new mapping(uint => bool)() // Initialize mapping
        });

        _totalSupply++;

        emit Transfer(address(0), to, tokenId);
        emit RelicMinted(to, tokenId, RelicState.Sealed, initialProperties);
    }

    /**
     * @dev Internal transfer function. Handles the actual state updates for transfer.
     *      Assumes checks for existence, ownership, approval, and attunement are done by caller.
     */
    function _transfer(address from, address to, uint tokenId) internal {
        // Clear approvals for the transferring token
        _tokenApprovals[tokenId] = address(0);

        _balanceOf[from]--;
        _balanceOf[to]++;
        _ownerOf[tokenId] = to;
        _relics[tokenId].lastStateChangeTime = block.timestamp; // Mark state changed on transfer

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal burn function. Removes a relic from existence.
     *      Assumes checks for existence are done by caller.
     */
    function _burn(uint tokenId) internal {
        address owner = _ownerOf[tokenId]; // Assumes _exists(tokenId) is true

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        // Clear ownership
        _balanceOf[owner]--;
        _ownerOf[tokenId] = address(0); // Set owner to zero address

        // Clear relic data
        delete _relics[tokenId]; // Removes the struct data

        _totalSupply--;

        emit Transfer(owner, address(0), tokenId);
        // Consider emitting a dedicated Burn event
    }

    /**
     * @dev Checks if a relic with the given token ID exists.
     */
    function _exists(uint tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    /**
     * @dev Applies time-based decay to a relic's properties based on the time elapsed
     *      since the last state change time.
     * @param tokenId The ID of the relic.
     * @dev Internal helper function. Does not change relic state enum, only properties.
     */
    function _applyTimeBasedDecay(uint tokenId) internal {
        RelicData storage relic = _relics[tokenId];
        uint timeElapsed = block.timestamp - relic.lastStateChangeTime;

        // Only apply decay if time has passed and integrity is not already zero
        if (timeElapsed > 0 && relic.properties.integrity > 0) {
            uint decayAmount = timeElapsed * decayRatePerUnitTime;
            if (relic.properties.integrity > decayAmount) {
                 relic.properties.integrity -= decayAmount;
            } else {
                 relic.properties.integrity = 0;
            }
             // Decay can also reduce purity over time
            uint purityDecayAmount = timeElapsed * (decayRatePerUnitTime / 2); // Example: Purity decays slower
            if (relic.properties.purity > purityDecayAmount) {
                 relic.properties.purity -= purityDecayAmount;
            } else {
                 relic.properties.purity = 0;
            }

            // No need to update lastStateChangeTime here, the calling function will do it
            // after evaluating state based on the *new* properties.
            // This prevents decay from being applied multiple times within a single function call.
        }
    }

     /**
     * @dev Internal helper to check if a relic is currently attuned.
     */
    function _isRelicAttuned(uint tokenId) internal view returns (bool) {
        RelicData storage relic = _relics[tokenId];
        return relic.currentState == RelicState.Attuned && relic.attunementEndTime > block.timestamp;
    }

     // Potential future helper: _updateRelicStateEnum() - called after property changes
     // based on integrity thresholds etc. to avoid duplicating logic.
     // Currently, this logic is within updateRelicState and other functions that change properties.
}
```