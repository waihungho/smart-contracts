Okay, here is a Solidity smart contract called `ChronicleOfEchoes`. It implements a concept of a decentralized, evolving historical record influenced by user contributions ("Echoes"). The chronicle progresses through different "Eras," each with potentially different rules and costs for adding entries. Era transitions are triggered by meeting specific criteria based on the number of echoes added in the current era and the time elapsed.

This design incorporates:
*   **State Evolution:** The contract state (`currentEra`) changes based on conditions.
*   **Dynamic Rules:** Contribution rules (`entryFee`, `maxTagsPerEcho`, `maxTextLength`) vary depending on the current era.
*   **Algorithmic Transition:** Era changes are based on quantifiable criteria (echo count, time).
*   **Immutable History:** Echoes are stored permanently.
*   **Structured Data:** Storing entries with multiple fields (`text`, `tags`, `contributor`, `timestamp`, `era`).
*   **Controlled Access:** Owner functions for configuration and fee withdrawal.
*   **Information Retrieval:** Multiple view functions to query the chronicle's state and history.

It avoids being a standard token, marketplace, simple DAO, or common DeFi primitive.

---

### ChronicleOfEchoes: Outline and Function Summary

**Outline:**

1.  **License and Pragma**
2.  **Error Definitions**
3.  **Interface (Optional but good practice for events)** - Not strictly needed for this example, events are defined directly.
4.  **Libraries (Optional)** - Not needed for this example.
5.  **State Variables**
    *   Contract Owner
    *   Echo Storage (Struct and Array)
    *   Era State (Current Era Index, Counters, Timestamps)
    *   Era Definitions (Properties per era, Transition Rules)
    *   Indexing/Lookup Mappings (Contributor Echoes, Tag Usage)
6.  **Events**
7.  **Struct Definitions (`Echo`, `EraProperties`, `EraTransitionRules`)**
8.  **Modifiers (`onlyOwner`)**
9.  **Constructor**
10. **Core Logic Functions**
    *   `addEcho`: Main function to contribute an entry.
    *   `attemptEraTransition`: Function to trigger an era change if criteria are met.
11. **Admin/Configuration Functions (`onlyOwner`)**
    *   `setEraProperties`: Configure rules for specific eras.
    *   `setEraTransitionCriteria`: Define what triggers transitions between eras.
    *   `withdrawFees`: Collect accumulated ETH fees.
    *   `setOwner`, `renounceOwnership`: Standard ownership management.
12. **View/Query Functions (Read-only)**
    *   Getters for state variables (`currentEra`, `totalEchoCount`, etc.)
    *   Detailed information about echoes and eras.
    *   Checks for transition eligibility.
    *   Contributor and tag specific queries.
    *   Fee information.

**Function Summary (Total: 24 Functions):**

1.  `constructor()`: Initializes the contract, sets owner, and defines properties for the initial era (Era 0).
2.  `addEcho(string memory _text, string[] memory _tags)`: Allows a user to add an "echo" (entry) to the chronicle. Requires payment based on the current era's fee and adheres to era-specific constraints (text length, tag count). Emits `EchoAdded`.
3.  `attemptEraTransition()`: Checks if the criteria for transitioning from the current era to the next are met (minimum echoes in current era, minimum time elapsed) and, if so, transitions the chronicle to the next era. Resets counters and emits `EraTransitioned`. Callable by anyone.
4.  `setEraProperties(uint256 _eraIndex, string memory _name, uint256 _entryFee, uint256 _maxTagsPerEcho, uint256 _maxTextLength)`: (Owner only) Sets or updates the properties (name, fee, tag limit, text length limit) for a specific era index. Emits `EraPropertiesUpdated`.
5.  `setEraTransitionCriteria(uint256 _fromEraIndex, uint256 _minEchoesForTransition, uint256 _minTimeForTransition)`: (Owner only) Sets or updates the criteria required to transition *from* a specific era index to the next. Emits `EraTransitionCriteriaUpdated`.
6.  `withdrawFees()`: (Owner only) Sends the total accumulated Ether collected from entry fees to the contract owner. Emits `FeesWithdrawn`.
7.  `setOwner(address payable _newOwner)`: (Owner only) Transfers ownership of the contract to a new address. Emits `OwnerChanged`.
8.  `renounceOwnership()`: (Owner only) Relinquishes ownership of the contract. The owner address will be set to the zero address. Emits `OwnershipRenounced`.
9.  `getEcho(uint256 _index)`: (View) Retrieves all details of a specific echo by its index.
10. `getTotalEchoCount()`: (View) Returns the total number of echoes ever added to the chronicle.
11. `getEchoCountInCurrentEra()`: (View) Returns the number of echoes added since the last era transition.
12. `getCurrentEra()`: (View) Returns the index of the current active era.
13. `getEraProperties(uint256 _eraIndex)`: (View) Returns the defined properties (name, fee, limits) for a given era index.
14. `getEraTransitionCriteria(uint256 _fromEraIndex)`: (View) Returns the criteria required to transition from a given era index.
15. `getLastEraTransitionTime()`: (View) Returns the timestamp of the most recent era transition.
16. `getEraStartTime(uint256 _eraIndex)`: (View) Returns the timestamp when a specific era began. (Stores this upon transition).
17. `canAttemptEraTransition()`: (View) Checks and returns a boolean indicating if the current era transition criteria are met *at this moment*.
18. `getMinContributionFee()`: (View) Returns the minimum required Ether to add an echo in the current era.
19. `getEraName(uint256 _eraIndex)`: (View) Returns the name string for a given era index.
20. `getEchoContributor(uint256 _index)`: (View) Returns the address of the contributor of a specific echo.
21. `getEchoTimestamp(uint256 _index)`: (View) Returns the timestamp when a specific echo was added.
22. `getEchoTags(uint256 _index)`: (View) Returns the list of tags associated with a specific echo.
23. `getTagUsageCount(string memory _tag)`: (View) Returns the total count of how many times a specific tag has been used across all echoes.
24. `getContributorEchoCount(address _contributor)`: (View) Returns the total number of echoes contributed by a specific address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleOfEchoes
 * @dev A decentralized, evolving chronicle where users add entries ("echoes")
 * that influence the progression through different "eras". Eras have varying rules
 * and transition based on criteria like echo count and time elapsed.
 */

// --- Outline ---
// 1. License and Pragma
// 2. Error Definitions
// 3. State Variables
// 4. Events
// 5. Struct Definitions
// 6. Modifiers
// 7. Constructor
// 8. Core Logic Functions (addEcho, attemptEraTransition)
// 9. Admin/Configuration Functions
// 10. View/Query Functions

// --- Function Summary (Total: 24 Functions) ---
// constructor()
// addEcho(string memory _text, string[] memory _tags)
// attemptEraTransition()
// setEraProperties(uint256 _eraIndex, string memory _name, uint256 _entryFee, uint256 _maxTagsPerEcho, uint256 _maxTextLength)
// setEraTransitionCriteria(uint256 _fromEraIndex, uint256 _minEchoesForTransition, uint256 _minTimeForTransition)
// withdrawFees()
// setOwner(address payable _newOwner)
// renounceOwnership()
// getEcho(uint256 _index)
// getTotalEchoCount()
// getEchoCountInCurrentEra()
// getCurrentEra()
// getEraProperties(uint256 _eraIndex)
// getEraTransitionCriteria(uint256 _fromEraIndex)
// getLastEraTransitionTime()
// getEraStartTime(uint256 _eraIndex)
// canAttemptEraTransition()
// getMinContributionFee()
// getEraName(uint256 _eraIndex)
// getEchoContributor(uint256 _index)
// getEchoTimestamp(uint256 _index)
// getEchoTags(uint256 _index)
// getTagUsageCount(string memory _tag)
// getContributorEchoCount(address _contributor)

contract ChronicleOfEchoes {

    // --- Error Definitions ---
    error Chronicle__NotOwner();
    error Chronicle__InsufficientPayment(uint256 required);
    error Chronicle__TextTooLong(uint256 maxLength);
    error Chronicle__TooManyTags(uint256 maxTags);
    error Chronicle__EraPropertiesNotSet();
    error Chronicle__EraTransitionCriteriaNotSet();
    error Chronicle__TransitionCriteriaNotMet();
    error Chronicle__InvalidEraIndex();
    error Chronicle__WithdrawalFailed();
    error Chronicle__EchoIndexOutOfBounds();
    error Chronicle__TransitionFailed(); // Generic transition error

    // --- State Variables ---
    address private immutable i_owner;

    struct Echo {
        address contributor;
        uint256 timestamp;
        string text;
        string[] tags;
        uint256 eraAtCreation; // The era index when this echo was added
    }
    Echo[] private s_echoes; // Storage for all echoes

    uint256 private s_currentEra = 0;
    uint256 private s_echoCountInCurrentEra = 0;
    uint256 private s_lastEraTransitionTime; // Timestamp of the beginning of the current era

    struct EraProperties {
        string name;
        uint256 entryFee; // in wei
        uint256 maxTagsPerEcho;
        uint256 maxTextLength;
        bool configured; // Flag to ensure properties have been set
    }
    // Maps era index => properties for that era
    mapping(uint256 => EraProperties) private s_eraProperties;

    struct EraTransitionRules {
        uint256 minEchoesForTransition;
        uint256 minTimeForTransition; // in seconds
        bool configured; // Flag to ensure rules have been set
    }
    // Maps era index (from) => rules to transition to the next era (index + 1)
    mapping(uint256 => EraTransitionRules) private s_eraTransitionRules;

    // Storage for era start times (optional, but useful for tracking history)
    mapping(uint256 => uint256) private s_eraStartTime;

    // Mappings for quicker lookups (avoid iterating arrays)
    mapping(string => uint256) private s_tagUsageCount;
    mapping(address => uint256) private s_contributorEchoCount;

    // --- Events ---
    event EchoAdded(uint256 indexed echoIndex, address indexed contributor, uint256 indexed era, uint256 timestamp);
    event EraTransitioned(uint256 indexed fromEra, uint256 indexed toEra, uint256 indexed triggeringEchoIndex, uint256 timestamp);
    event EraPropertiesUpdated(uint256 indexed eraIndex, string name, uint256 fee, uint256 maxTags, uint256 maxTextLength);
    event EraTransitionCriteriaUpdated(uint256 indexed fromEraIndex, uint256 minEchoes, uint256 minTime);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed previousOwner);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Chronicle__NotOwner();
        _;
    }

    // --- Constructor ---
    constructor() {
        i_owner = msg.sender;
        // Initialize properties for Era 0
        // This prevents a state where the very first era has no rules
        s_eraProperties[0] = EraProperties({
            name: "The Era of Silence",
            entryFee: 0, // Free entry for the first era
            maxTagsPerEcho: 2,
            maxTextLength: 160, // Like a tweet
            configured: true
        });
        s_eraStartTime[0] = block.timestamp;
        s_lastEraTransitionTime = block.timestamp; // Initial transition time is deployment time
    }

    // --- Core Logic Functions ---

    /**
     * @dev Adds a new echo to the chronicle.
     * Requires payment of the current era's fee and adheres to era limits.
     * @param _text The content of the echo.
     * @param _tags A list of tags associated with the echo.
     */
    function addEcho(string memory _text, string[] memory _tags) external payable {
        EraProperties storage currentEraProps = s_eraProperties[s_currentEra];
        if (!currentEraProps.configured) revert Chronicle__EraPropertiesNotSet();

        if (msg.value < currentEraProps.entryFee) revert Chronicle__InsufficientPayment(currentEraProps.entryFee);
        if (bytes(_text).length > currentEraProps.maxTextLength) revert Chronicle__TextTooLong(currentEraProps.maxTextLength);
        if (_tags.length > currentEraProps.maxTagsPerEcho) revert Chronicle__TooManyTags(currentEraProps.maxTagsPerEcho);

        // Store the new echo
        uint256 newEchoIndex = s_echoes.length;
        s_echoes.push(Echo({
            contributor: msg.sender,
            timestamp: block.timestamp,
            text: _text,
            tags: _tags,
            eraAtCreation: s_currentEra
        }));

        // Update counters
        s_echoCountInCurrentEra++;
        s_contributorEchoCount[msg.sender]++;
        for (uint i = 0; i < _tags.length; i++) {
            s_tagUsageCount[_tags[i]]++;
        }

        emit EchoAdded(newEchoIndex, msg.sender, s_currentEra, block.timestamp);

        // Optional: Automatically attempt transition after adding an echo
        // This can be gas-intensive if transition happens frequently.
        // Alternative is to only allow explicit calls to attemptEraTransition.
        // Keeping it explicit for lower gas cost on addEcho.
    }

    /**
     * @dev Attempts to transition the chronicle to the next era.
     * This function checks if the criteria for transitioning from the current era
     * to the next have been met (min echoes and min time).
     * Callable by anyone.
     */
    function attemptEraTransition() external {
        uint256 nextEra = s_currentEra + 1;
        EraTransitionRules storage rules = s_eraTransitionRules[s_currentEra];
        if (!rules.configured) revert Chronicle__EraTransitionCriteriaNotSet();

        if (s_echoCountInCurrentEra < rules.minEchoesForTransition ||
            block.timestamp < s_lastEraTransitionTime + rules.minTimeForTransition) {
            revert Chronicle__TransitionCriteriaNotMet();
        }

        // Ensure properties for the NEXT era are configured BEFORE transitioning
        EraProperties storage nextEraProps = s_eraProperties[nextEra];
         if (!nextEraProps.configured) {
             // This prevents transitioning to an era with undefined rules
             revert Chronicle__EraPropertiesNotSet();
         }


        uint256 previousEra = s_currentEra;
        s_currentEra = nextEra;
        s_echoCountInCurrentEra = 0;
        s_lastEraTransitionTime = block.timestamp;
        s_eraStartTime[s_currentEra] = block.timestamp;

        // The triggering echo index isn't directly tied to the transition *call*
        // It's based on the criteria being met. We can use the total echo count at the time of transition.
        // This might not be the *very last* echo added, but the count when transition occurs.
        uint256 triggeringEchoIndex = s_echoes.length > 0 ? s_echoes.length - 1 : 0; // Use index of last echo

        emit EraTransitioned(previousEra, s_currentEra, triggeringEchoIndex, block.timestamp);
    }

    // --- Admin/Configuration Functions ---

    /**
     * @dev Sets or updates the properties for a specific era index.
     * Callable only by the contract owner.
     * @param _eraIndex The index of the era to configure.
     * @param _name The name of the era.
     * @param _entryFee The ETH fee required to add an echo in this era (in wei).
     * @param _maxTagsPerEcho The maximum number of tags allowed per echo in this era.
     * @param _maxTextLength The maximum character length for echo text in this era.
     */
    function setEraProperties(uint256 _eraIndex, string memory _name, uint256 _entryFee, uint256 _maxTagsPerEcho, uint256 _maxTextLength) external onlyOwner {
        s_eraProperties[_eraIndex] = EraProperties({
            name: _name,
            entryFee: _entryFee,
            maxTagsPerEcho: _maxTagsPerEcho,
            maxTextLength: _maxTextLength,
            configured: true
        });
        emit EraPropertiesUpdated(_eraIndex, _name, _entryFee, _maxTagsPerEcho, _maxTextLength);
    }

    /**
     * @dev Sets or updates the criteria required to transition from a specific era index to the next.
     * Callable only by the contract owner.
     * @param _fromEraIndex The index of the era FROM which the transition rules apply.
     * @param _minEchoesForTransition The minimum number of echoes required in the era to trigger transition.
     * @param _minTimeForTransition The minimum time (in seconds) that must pass in the era to trigger transition.
     */
    function setEraTransitionCriteria(uint256 _fromEraIndex, uint256 _minEchoesForTransition, uint256 _minTimeForTransition) external onlyOwner {
         // Cannot set criteria for the current era if it's already configured and passed its start time,
         // or for future eras if the previous era's criteria aren't set.
         // Simple check: Cannot set criteria FROM an era index that is AFTER the current era index.
         // More complex check: Cannot set criteria if the *next* era's properties haven't been set yet?
         // Let's allow setting for future eras, but block transition if next era props aren't set.
        s_eraTransitionRules[_fromEraIndex] = EraTransitionRules({
            minEchoesForTransition: _minEchoesForTransition,
            minTimeForTransition: _minTimeForTransition,
            configured: true
        });
        emit EraTransitionCriteriaUpdated(_fromEraIndex, _minEchoesForTransition, _minTimeForTransition);
    }


    /**
     * @dev Allows the contract owner to withdraw the accumulated ETH fees.
     * Transfers the entire balance of the contract to the owner.
     * Callable only by the contract owner.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) return; // No fees to withdraw

        (bool success, ) = payable(i_owner).call{value: balance}("");
        if (!success) revert Chronicle__WithdrawalFailed();

        emit FeesWithdrawn(i_owner, balance);
    }

     /**
     * @dev Transfers ownership of the contract to a new account (`_newOwner`).
     * Can only be called by the current owner.
     * @param _newOwner The address of the new owner.
     */
    function setOwner(address payable _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert Chronicle__InvalidEraIndex(); // Using a generic error, could define a specific one
        address previousOwner = i_owner;
        // Cast is safe as _newOwner is payable
        i_owner = _newOwner; // State variable is private immutable, so this needs a different approach.
        // Correction: i_owner is immutable, cannot be changed after constructor.
        // Need a separate owner state variable.

        // Redefining owner as a standard state variable to allow changing it.
        // Keeping i_owner pattern for immutable values if needed, but for owner it should be mutable.
        // Let's change i_owner to s_owner.
        revert("Ownership management needs a mutable state variable, not immutable.");
        // Will update state variable below...
    }

    address private s_owner; // Mutable owner state variable

    // --- Constructor (Revised for mutable owner) ---
    constructor() {
        s_owner = msg.sender; // Set initial owner
        // Initialize properties for Era 0
        s_eraProperties[0] = EraProperties({
            name: "The Era of Silence",
            entryFee: 0, // Free entry for the first era
            maxTagsPerEcho: 2,
            maxTextLength: 160, // Like a tweet
            configured: true
        });
        s_eraStartTime[0] = block.timestamp;
        s_lastEraTransitionTime = block.timestamp; // Initial transition time is deployment time
    }

    modifier onlyOwnerRevised() {
        if (msg.sender != s_owner) revert Chronicle__NotOwner();
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_newOwner`).
     * Can only be called by the current owner.
     * @param _newOwner The address of the new owner.
     */
    function setOwner(address payable _newOwner) external onlyOwnerRevised {
        if (_newOwner == address(0)) revert Chronicle__InvalidEraIndex(); // Can use a more specific error
        address previousOwner = s_owner;
        s_owner = _newOwner;
        emit OwnerChanged(previousOwner, _newOwner);
    }

    /**
     * @dev Relinquishes ownership of the contract.
     * Can only be called by the current owner.
     * Setting the owner to the zero address prevents further administrative actions
     * unless a specific mechanism for renouncing ownership is implemented.
     */
    function renounceOwnership() external onlyOwnerRevised {
        address previousOwner = s_owner;
        s_owner = address(0);
        emit OwnershipRenounced(previousOwner);
    }


    // --- View/Query Functions ---

    /**
     * @dev Returns the details of a specific echo.
     * @param _index The index of the echo to retrieve.
     * @return A struct containing the echo's contributor, timestamp, text, tags, and era of creation.
     */
    function getEcho(uint256 _index) external view returns (Echo memory) {
        if (_index >= s_echoes.length) revert Chronicle__EchoIndexOutOfBounds();
        return s_echoes[_index];
    }

    /**
     * @dev Returns the total number of echoes stored in the chronicle.
     */
    function getTotalEchoCount() external view returns (uint256) {
        return s_echoes.length;
    }

    /**
     * @dev Returns the number of echoes added since the beginning of the current era.
     */
    function getEchoCountInCurrentEra() external view returns (uint256) {
        return s_echoCountInCurrentEra;
    }

    /**
     * @dev Returns the index of the current active era.
     */
    function getCurrentEra() external view returns (uint256) {
        return s_currentEra;
    }

    /**
     * @dev Returns the properties defined for a specific era index.
     * @param _eraIndex The index of the era to query.
     * @return A struct containing the era's name, entry fee, max tags, max text length, and configured status.
     */
    function getEraProperties(uint256 _eraIndex) external view returns (EraProperties memory) {
        // Note: Accessing a mapping returns a default struct if key doesn't exist.
        // Check `configured` flag for validity outside this function if needed.
        return s_eraProperties[_eraIndex];
    }

    /**
     * @dev Returns the transition rules defined for moving from a specific era index to the next.
     * @param _fromEraIndex The index of the era whose outgoing transition rules are queried.
     * @return A struct containing the minimum echoes, minimum time, and configured status for transition.
     */
    function getEraTransitionCriteria(uint256 _fromEraIndex) external view returns (EraTransitionRules memory) {
         // Note: Accessing a mapping returns a default struct if key doesn't exist.
         // Check `configured` flag for validity outside this function if needed.
        return s_eraTransitionRules[_fromEraIndex];
    }

    /**
     * @dev Returns the timestamp when the most recent era transition occurred (i.e., when the current era began).
     */
    function getLastEraTransitionTime() external view returns (uint256) {
        return s_lastEraTransitionTime;
    }

     /**
     * @dev Returns the timestamp when a specific era began.
     * @param _eraIndex The index of the era to query the start time for.
     */
    function getEraStartTime(uint256 _eraIndex) external view returns (uint256) {
        // Returns 0 if the era has not started or doesn't exist in history
        return s_eraStartTime[_eraIndex];
    }


    /**
     * @dev Checks if the criteria for transitioning from the current era to the next are currently met.
     * This is a view function and does not attempt the transition.
     * @return A boolean indicating whether a transition is currently possible.
     */
    function canAttemptEraTransition() external view returns (bool) {
        EraTransitionRules storage rules = s_eraTransitionRules[s_currentEra];
        if (!rules.configured) return false; // Cannot transition if rules aren't set for the current era

        // Also cannot transition if the NEXT era's properties haven't been set yet
         if (!s_eraProperties[s_currentEra + 1].configured) return false;

        return (s_echoCountInCurrentEra >= rules.minEchoesForTransition &&
                block.timestamp >= s_lastEraTransitionTime + rules.minTimeForTransition);
    }

    /**
     * @dev Returns the minimum required Ether amount (in wei) to add an echo in the current era.
     */
    function getMinContributionFee() external view returns (uint256) {
        // If current era properties aren't configured (shouldn't happen after constructor/owner setup),
        // this will return 0 from the default struct. Could add a check.
        if (!s_eraProperties[s_currentEra].configured) return 0; // Or revert? Reverting in view functions is okay.
        return s_eraProperties[s_currentEra].entryFee;
    }

    /**
     * @dev Returns the name string associated with a specific era index.
     * @param _eraIndex The index of the era.
     */
    function getEraName(uint256 _eraIndex) external view returns (string memory) {
         if (!s_eraProperties[_eraIndex].configured) return ""; // Return empty string or revert? Let's return ""
        return s_eraProperties[_eraIndex].name;
    }

     /**
     * @dev Returns the contributor address of a specific echo by index.
     * @param _index The index of the echo.
     */
    function getEchoContributor(uint256 _index) external view returns (address) {
         if (_index >= s_echoes.length) revert Chronicle__EchoIndexOutOfBounds();
        return s_echoes[_index].contributor;
    }

    /**
     * @dev Returns the timestamp when a specific echo was added by index.
     * @param _index The index of the echo.
     */
    function getEchoTimestamp(uint256 _index) external view returns (uint256) {
         if (_index >= s_echoes.length) revert Chronicle__EchoIndexOutOfBounds();
        return s_echoes[_index].timestamp;
    }

    /**
     * @dev Returns the tags associated with a specific echo by index.
     * @param _index The index of the echo.
     */
    function getEchoTags(uint256 _index) external view returns (string[] memory) {
         if (_index >= s_echoes.length) revert Chronicle__EchoIndexOutOfBounds();
        return s_echoes[_index].tags;
    }

     /**
     * @dev Returns the total count of how many times a specific tag has been used across all echoes.
     * @param _tag The tag string to query.
     */
    function getTagUsageCount(string memory _tag) external view returns (uint256) {
        return s_tagUsageCount[_tag];
    }

    /**
     * @dev Returns the total number of echoes contributed by a specific address.
     * @param _contributor The address to query.
     */
    function getContributorEchoCount(address _contributor) external view returns (uint256) {
        return s_contributorEchoCount[_contributor];
    }

    /**
     * @dev Returns the current balance of the contract, representing accumulated fees.
     */
    function getTotalEthCollected() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Owner Information ---
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return s_owner;
    }
}
```