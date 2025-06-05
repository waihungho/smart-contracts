```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title QuantumLock - A Conceptual Smart Contract Exploring Entangled States and Conditional Access
 * @author YourName (or a pseudonym)
 * @notice This contract is a conceptual exploration of advanced state management,
 *         simulating quantum-inspired 'entanglement' between digital states (QubitStates).
 *         It utilizes complex conditional logic based on state observations, decay,
 *         and unique non-fungible keys for access. It is *not* a true simulation
 *         of quantum mechanics but rather a creative use of blockchain state transitions
 *         to model linked, interdependent digital states.
 *
 * Outline:
 * 1. State Definitions (Structs for Qubits, Pairs, Keys)
 * 2. Storage Mappings and Counters
 * 3. Events for State Changes and Actions
 * 4. Access Control (Ownable)
 * 5. Core Logic:
 *    - Pair and Qubit Creation
 *    - Key Minting and Management
 *    - Observing Qubit States (Triggering Entanglement)
 *    - Entanglement Effect Logic
 *    - State Decay Simulation
 *    - Advanced State Manipulation (Merging, Splitting - Conceptual)
 *    - View Functions for Information Retrieval
 *    - Owner/Maintenance Functions
 *
 * Function Summary (Total: 24 functions):
 *
 * --- Setup & Creation (3 functions) ---
 * 1. constructor(): Initializes the contract owner.
 * 2. createEntanglementPair(): Creates a new pair of entangled QubitStates with initial properties.
 * 3. mintEntanglementKey(): Mints a new EntanglementKey, linking it to a specific QubitState for access.
 *
 * --- Core Interaction & State Evolution (4 functions) ---
 * 4. observeQubitState(): Attempts to "observe" (unlock/access) a specific QubitState using a key and providing required "entropy" (via ETH). Triggers the entanglement effect.
 * 5. applyEntanglementEffect(): Internal helper function. Applies the entanglement rule to the linked QubitState based on the observation.
 * 6. decayQubitState(): Manually triggers the decay process for a specific QubitState, reducing its unlock entropy over time.
 * 7. configureEntanglementRule(): Owner function to set the logic rule (represented by an ID) for how entanglement affects paired states.
 *
 * --- Key Management (4 functions) ---
 * 8. transferEntanglementKey(): Allows a key owner to transfer ownership of a key.
 * 9. burnEntanglementKey(): Allows a key owner to burn (destroy) their key.
 * 10. getKeyDetails(): View function to retrieve details about a specific EntanglementKey.
 * 11. listKeysByOwner(): View function to list all EntanglementKey IDs owned by an address.
 *
 * --- State Information & Views (7 functions) ---
 * 12. getQubitStateDetails(): View function to retrieve detailed information about a specific QubitState.
 * 13. getPairDetails(): View function to retrieve detailed information about an EntanglementPair.
 * 14. listEntangledPairs(): View function to get a list of all EntanglementPair IDs.
 * 15. listQubitStates(): View function to get a list of all QubitState IDs.
 * 16. getQubitOwner(): View function to find the conceptual owner of a specific QubitState.
 * 17. isKeyOwner(): View function to check if an address owns a specific key.
 * 18. predictEntanglementOutcome(): View function that returns the current state details of the qubit entangled with the provided one, conceptually simulating a "prediction".
 *
 * --- Advanced/Conceptual Manipulation (3 functions) ---
 * 19. mergeEntanglementPairs(): Conceptual function to "merge" properties of two different EntanglementPairs, potentially affecting their states or creating a new key. (Simplified implementation).
 * 20. splitEntanglementKey(): Conceptual function to "split" an EntanglementKey, creating a new key linked to the *paired* qubit state. (Simplified implementation).
 * 21. donateEntropy(): Allows anyone to send ETH to increase the unlock entropy of a specific QubitState, making it harder to observe. (Requires ETH).
 *
 * --- Maintenance & Owner Functions (3 functions) ---
 * 22. updateUnlockEntropy(): Owner function to manually adjust the unlock entropy of a QubitState.
 * 23. togglePairEntanglement(): Owner function to enable or disable the entanglement effect for a specific pair.
 * 24. withdrawStuckETH(): Owner function to withdraw any accidental ETH sent to the contract.
 */
contract QuantumLock is Ownable {

    // --- State Definitions ---

    struct QubitState {
        uint256 id;
        uint256 pairId; // Reference to the entangled pair
        uint256 linkedQubitId; // ID of the entangled partner
        bool locked; // True if the state is locked and requires observation
        uint256 unlockEntropy; // Required "effort" or value to observe/unlock
        uint256 decayRate; // How much unlockEntropy decays per time unit (e.g., block or second)
        uint48 lastDecayTimestamp; // Timestamp of the last decay process
        address owner; // Conceptual owner of this state/access right
    }

    struct EntanglementPair {
        uint256 id;
        uint256 qubitIdA;
        uint256 qubitIdB;
        bool entanglementEnabled; // Can be toggled by owner
        uint256 entanglementRuleId; // Dictates how observation affects the linked state
    }

    struct EntanglementKey {
        uint256 id;
        address owner; // Address that can use or transfer this key
        uint256 linkedQubitId; // The specific QubitState this key can interact with
        uint64 creationTimestamp; // When the key was minted
    }

    // --- Storage ---

    mapping(uint256 => QubitState) public qubitStates;
    uint256 private _nextQubitId;

    mapping(uint256 => EntanglementPair) public entanglementPairs;
    uint256 private _nextPairId;

    mapping(uint256 => EntanglementKey) public entanglementKeys;
    mapping(address => uint256[]) private _keysByOwner; // Helper mapping
    uint256 private _nextKeyId;

    // --- Events ---

    event QubitStateCreated(uint256 indexed qubitId, uint256 indexed pairId, address indexed owner);
    event EntanglementPairCreated(uint256 indexed pairId, uint256 qubitIdA, uint256 qubitIdB);
    event EntanglementKeyMinted(uint256 indexed keyId, address indexed owner, uint256 indexed linkedQubitId);
    event EntanglementKeyTransferred(uint256 indexed keyId, address indexed from, address indexed to);
    event EntanglementKeyBurned(uint256 indexed keyId, address indexed owner);

    event QubitStateObserved(uint256 indexed qubitId, address indexed observer, uint256 entropyProvided, uint256 blockTimestamp);
    event EntanglementEffectApplied(uint256 indexed pairId, uint256 indexed affectedQubitId, uint256 indexed triggeringQubitId, uint256 newEntropy, uint256 blockTimestamp);
    event QubitStateDecayed(uint256 indexed qubitId, uint256 oldEntropy, uint256 newEntropy, uint256 decayAmount);
    event QubitStateReset(uint256 indexed qubitId);

    event EntanglementRuleUpdated(uint256 indexed pairId, uint256 oldRuleId, uint256 newRuleId);
    event PairEntanglementToggled(uint256 indexed pairId, bool enabled);

    event QubitEntropyUpdated(uint256 indexed qubitId, uint256 oldEntropy, uint256 newEntropy);
    event EntropyDonated(uint256 indexed qubitId, address indexed donor, uint256 amount);

    event PairsMerged(uint256 indexed pairIdA, uint256 indexed pairIdB, uint256 indexed resultingQubitId);
    event KeySplit(uint256 indexed originalKeyId, uint256 indexed newKeyId);


    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Core Logic: Setup & Creation ---

    /**
     * @notice Creates a new EntanglementPair consisting of two linked QubitStates.
     * @param _initialEntropyA Initial unlock entropy for Qubit A.
     * @param _initialDecayRateA Initial decay rate for Qubit A.
     * @param _initialEntropyB Initial unlock entropy for Qubit B.
     * @param _initialDecayRateB Initial decay rate for Qubit B.
     * @param _entanglementRuleId Rule ID governing how observation affects the linked state (e.g., 1 for inverse effect, 2 for direct effect).
     */
    function createEntanglementPair(
        uint256 _initialEntropyA,
        uint256 _initialDecayRateA,
        uint256 _initialEntropyB,
        uint256 _initialDecayRateB,
        uint256 _entanglementRuleId
    ) external onlyOwner returns (uint256 pairId, uint256 qubitIdA, uint256 qubitIdB) {
        pairId = _nextPairId++;
        qubitIdA = _nextQubitId++;
        qubitIdB = _nextQubitId++;

        QubitState storage qubitA = qubitStates[qubitIdA];
        qubitA.id = qubitIdA;
        qubitA.pairId = pairId;
        qubitA.linkedQubitId = qubitIdB;
        qubitA.locked = true;
        qubitA.unlockEntropy = _initialEntropyA;
        qubitA.decayRate = _initialDecayRateA;
        qubitA.lastDecayTimestamp = uint48(block.timestamp); // Use uint48 for efficiency if timestamp < 2^48-1
        qubitA.owner = address(0); // Initially unowned conceptually

        QubitState storage qubitB = qubitStates[qubitIdB];
        qubitB.id = qubitIdB;
        qubitB.pairId = pairId;
        qubitB.linkedQubitId = qubitIdA;
        qubitB.locked = true;
        qubitB.unlockEntropy = _initialEntropyB;
        qubitB.decayRate = _initialDecayRateB;
        qubitB.lastDecayTimestamp = uint48(block.timestamp);
        qubitB.owner = address(0);

        EntanglementPair storage pair = entanglementPairs[pairId];
        pair.id = pairId;
        pair.qubitIdA = qubitIdA;
        pair.qubitIdB = qubitIdB;
        pair.entanglementEnabled = true; // Entanglement is enabled by default
        pair.entanglementRuleId = _entanglementRuleId; // Define rules off-chain or in comments

        emit QubitStateCreated(qubitIdA, pairId, address(0));
        emit QubitStateCreated(qubitIdB, pairId, address(0));
        emit EntanglementPairCreated(pairId, qubitIdA, qubitIdB);

        return (pairId, qubitIdA, qubitIdB);
    }

    /**
     * @notice Mints a new EntanglementKey and assigns it to an address, linking it to a specific QubitState.
     * @param _to The address to mint the key to.
     * @param _qubitId The ID of the QubitState this key can interact with.
     */
    function mintEntanglementKey(address _to, uint256 _qubitId) external onlyOwner returns (uint256 keyId) {
        require(qubitStates[_qubitId].id != 0, "QL: Qubit does not exist");

        keyId = _nextKeyId++;
        EntanglementKey storage key = entanglementKeys[keyId];
        key.id = keyId;
        key.owner = _to;
        key.linkedQubitId = _qubitId;
        key.creationTimestamp = uint64(block.timestamp);

        _keysByOwner[_to].push(keyId);

        // Assign ownership of the linked qubit state conceptually
        qubitStates[_qubitId].owner = _to;

        emit EntanglementKeyMinted(keyId, _to, _qubitId);
        return keyId;
    }

    // --- Core Interaction & State Evolution ---

    /**
     * @notice Attempts to "observe" (unlock/access) a specific QubitState using a key.
     * The observation requires providing ETH equal to the current unlockEntropy.
     * Successful observation triggers the entanglement effect on the linked state.
     * @param _keyId The ID of the EntanglementKey used for observation.
     * @dev Requires the sender to own the key and provide sufficient ETH (`msg.value`).
     * @dev The provided ETH is conceptually consumed as "entropy" and sent to the contract. It can be retrieved by the owner.
     */
    function observeQubitState(uint256 _keyId) external payable {
        EntanglementKey storage key = entanglementKeys[_keyId];
        require(key.owner != address(0), "QL: Key does not exist");
        require(key.owner == msg.sender, "QL: Not key owner");

        uint256 qubitId = key.linkedQubitId;
        QubitState storage qubit = qubitStates[qubitId];
        require(qubit.id != 0, "QL: Linked Qubit does not exist");
        require(qubit.locked, "QL: Qubit is already observed (unlocked)");

        // Apply decay before checking entropy requirement
        _applyDecay(qubitId);

        require(msg.value >= qubit.unlockEntropy, "QL: Insufficient entropy provided (ETH)");

        // State transition: Unlock
        qubit.locked = false;
        // Any excess ETH is kept by the contract

        emit QubitStateObserved(qubitId, msg.sender, msg.value, block.timestamp);

        // Apply entanglement effect to the paired qubit
        applyEntanglementEffect(qubitId);
    }

    /**
     * @notice Internal function to apply the entanglement effect to the linked qubit state.
     * The effect depends on the EntanglementPair's rule ID.
     * @param _triggeringQubitId The ID of the qubit that was just observed.
     * @dev This function should only be called internally after a successful observation.
     */
    function applyEntanglementEffect(uint256 _triggeringQubitId) internal {
        QubitState storage triggeringQubit = qubitStates[_triggeringQubitId];
        uint256 pairId = triggeringQubit.pairId;
        EntanglementPair storage pair = entanglementPairs[pairId];

        if (!pair.entanglementEnabled) {
            return; // Entanglement is disabled for this pair
        }

        uint256 affectedQubitId = triggeringQubit.linkedQubitId;
        QubitState storage affectedQubit = qubitStates[affectedQubitId];

        uint256 newEntropy = affectedQubit.unlockEntropy; // Start with current entropy

        // Apply entanglement logic based on the rule ID
        // Rule 1: Observation of A increases entropy of B
        // Rule 2: Observation of A decreases entropy of B
        // Rule 3: Observation of A sets entropy of B based on triggering entropy (conceptual, simplified)
        if (pair.entanglementRuleId == 1) {
            // Increase entropy of the linked qubit
            newEntropy = affectedQubit.unlockEntropy + triggeringQubit.unlockEntropy / 2; // Example rule
        } else if (pair.entanglementRuleId == 2) {
            // Decrease entropy of the linked qubit (but not below 0)
            uint256 decreaseAmount = triggeringQubit.unlockEntropy / 3; // Example rule
            newEntropy = affectedQubit.unlockEntropy > decreaseAmount ? affectedQubit.unlockEntropy - decreaseAmount : 0;
        } else if (pair.entanglementRuleId == 3) {
             // Set entropy based on the triggering qubit (e.g., to a percentage)
             newEntropy = triggeringQubit.unlockEntropy / 4; // Example rule
        }
        // Add more complex rules here as needed

        // Ensure entropy doesn't overflow (though unlikely with uint256 unless astronomical)
        // and apply the update
        affectedQubit.unlockEntropy = newEntropy;

        emit EntanglementEffectApplied(pairId, affectedQubitId, _triggeringQubitId, newEntropy, block.timestamp);
    }

    /**
     * @notice Manually triggers the decay process for a specific QubitState.
     * Decay reduces the unlockEntropy over time, making it easier to observe.
     * Anyone can call this, but it only applies decay based on the elapsed time since last decay.
     * @param _qubitId The ID of the QubitState to decay.
     */
    function decayQubitState(uint256 _qubitId) external {
        QubitState storage qubit = qubitStates[_qubitId];
        require(qubit.id != 0, "QL: Qubit does not exist");
        require(qubit.decayRate > 0, "QL: Qubit has no decay rate");

        _applyDecay(_qubitId);
    }

    /**
     * @notice Internal helper function to calculate and apply entropy decay.
     * @param _qubitId The ID of the QubitState to decay.
     */
    function _applyDecay(uint256 _qubitId) internal {
        QubitState storage qubit = qubitStates[_qubitId];
        uint256 timeElapsed = block.timestamp - qubit.lastDecayTimestamp;

        if (timeElapsed == 0) {
            return; // No time elapsed since last decay
        }

        uint256 decayAmount = timeElapsed * qubit.decayRate;
        uint256 oldEntropy = qubit.unlockEntropy;

        if (qubit.unlockEntropy > decayAmount) {
            qubit.unlockEntropy -= decayAmount;
        } else {
            qubit.unlockEntropy = 0;
        }

        qubit.lastDecayTimestamp = uint48(block.timestamp);

        if (qubit.unlockEntropy != oldEntropy) {
             emit QubitStateDecayed(_qubitId, oldEntropy, qubit.unlockEntropy, decayAmount);
        }
    }

    /**
     * @notice Owner function to configure the entanglement logic rule for a specific pair.
     * @param _pairId The ID of the EntanglementPair to configure.
     * @param _newRuleId The new rule ID to apply. (Refer to contract documentation/comments for rule definitions).
     */
    function configureEntanglementRule(uint256 _pairId, uint256 _newRuleId) external onlyOwner {
        EntanglementPair storage pair = entanglementPairs[_pairId];
        require(pair.id != 0, "QL: Pair does not exist");
        uint256 oldRuleId = pair.entanglementRuleId;
        pair.entanglementRuleId = _newRuleId;
        emit EntanglementRuleUpdated(_pairId, oldRuleId, _newRuleId);
    }

    // --- Key Management ---

    /**
     * @notice Allows a key owner to transfer ownership of an EntanglementKey.
     * @param _to The recipient address.
     * @param _keyId The ID of the key to transfer.
     */
    function transferEntanglementKey(address _to, uint256 _keyId) external {
        EntanglementKey storage key = entanglementKeys[_keyId];
        require(key.owner != address(0), "QL: Key does not exist");
        require(key.owner == msg.sender, "QL: Not key owner");
        require(_to != address(0), "QL: Cannot transfer to zero address");

        address from = key.owner;
        key.owner = _to;

        // Update _keysByOwner mapping (less efficient for removal, but simple for add)
        // Finding and removing from _keysByOwner[from] is gas intensive.
        // For simplicity and gas efficiency on transfer, we might just push to new owner
        // and rely on `listKeysByOwner` to iterate and filter.
        // A more robust implementation would use indexed lists or linked lists.
        // Keeping it simple for demonstration: just push for now, filtering in view.
        _keysByOwner[_to].push(_keyId);

        // Note: We don't remove from _keysByOwner[from] array to save gas.
        // `listKeysByOwner` must filter out keys whose owner is no longer `from`.

        emit EntanglementKeyTransferred(_keyId, from, _to);
    }

    /**
     * @notice Allows a key owner to burn (destroy) their EntanglementKey.
     * @param _keyId The ID of the key to burn.
     */
    function burnEntanglementKey(uint256 _keyId) external {
        EntanglementKey storage key = entanglementKeys[_keyId];
        require(key.owner != address(0), "QL: Key does not exist");
        require(key.owner == msg.sender, "QL: Not key owner");

        address owner = key.owner;
        uint256 linkedQubitId = key.linkedQubitId;

        // Reset key struct
        delete entanglementKeys[_keyId];

        // We rely on listKeysByOwner filtering for the mapping update.

        // Potentially revoke conceptual ownership of the qubit if this was the only key?
        // Let's keep it simple and not auto-revoke qubit ownership on key burn.

        emit EntanglementKeyBurned(_keyId, owner);
    }

    /**
     * @notice View function to retrieve details of an EntanglementKey.
     * @param _keyId The ID of the key.
     * @return The EntanglementKey struct.
     */
    function getKeyDetails(uint256 _keyId) external view returns (EntanglementKey memory) {
        return entanglementKeys[_keyId];
    }

    /**
     * @notice View function to list all EntanglementKey IDs owned by an address.
     * Filters out keys that have been transferred away or burned (due to gas-saving in transfer/burn).
     * @param _owner The address whose keys to list.
     * @return An array of key IDs owned by the address.
     */
    function listKeysByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] storage ownerKeys = _keysByOwner[_owner];
        uint256 validCount = 0;
        for (uint i = 0; i < ownerKeys.length; i++) {
            if (entanglementKeys[ownerKeys[i]].owner == _owner && entanglementKeys[ownerKeys[i]].id != 0) {
                validCount++;
            }
        }

        uint256[] memory ownedKeys = new uint256[](validCount);
        uint256 currentIndex = 0;
        for (uint i = 0; i < ownerKeys.length; i++) {
            if (entanglementKeys[ownerKeys[i]].owner == _owner && entanglementKeys[ownerKeys[i]].id != 0) {
                ownedKeys[currentIndex++] = ownerKeys[i];
            }
        }
        return ownedKeys;
    }


    // --- State Information & Views ---

    /**
     * @notice View function to get details of a specific QubitState.
     * @param _qubitId The ID of the QubitState.
     * @return The QubitState struct.
     */
    function getQubitStateDetails(uint256 _qubitId) external view returns (QubitState memory) {
         return qubitStates[_qubitId];
    }

    /**
     * @notice View function to get details of an EntanglementPair.
     * @param _pairId The ID of the pair.
     * @return The EntanglementPair struct.
     */
    function getPairDetails(uint256 _pairId) external view returns (EntanglementPair memory) {
        return entanglementPairs[_pairId];
    }

    /**
     * @notice View function to get a list of all existing EntanglementPair IDs.
     * @return An array of EntanglementPair IDs.
     */
    function listEntangledPairs() external view returns (uint256[] memory) {
        uint256 totalPairs = _nextPairId;
        uint256[] memory pairIds = new uint256[](totalPairs);
        for (uint i = 0; i < totalPairs; i++) {
            pairIds[i] = i; // IDs are sequential starting from 0
        }
        return pairIds;
    }

     /**
     * @notice View function to get a list of all existing QubitState IDs.
     * @return An array of QubitState IDs.
     */
    function listQubitStates() external view returns (uint256[] memory) {
        uint256 totalQubits = _nextQubitId;
        uint256[] memory qubitIds = new uint256[](totalQubits);
        for (uint i = 0; i < totalQubits; i++) {
            qubitIds[i] = i; // IDs are sequential starting from 0
        }
        return qubitIds;
    }

    /**
     * @notice View function to get the conceptual owner of a specific QubitState.
     * The owner is typically the address holding the key linked to this state.
     * @param _qubitId The ID of the QubitState.
     * @return The owner address.
     */
    function getQubitOwner(uint256 _qubitId) external view returns (address) {
        return qubitStates[_qubitId].owner;
    }

     /**
     * @notice View function to check if an address is the current owner of a specific key.
     * @param _keyId The ID of the key.
     * @param _addr The address to check.
     * @return True if the address owns the key, false otherwise.
     */
    function isKeyOwner(uint256 _keyId, address _addr) external view returns (bool) {
        return entanglementKeys[_keyId].owner == _addr;
    }

    /**
     * @notice View function that returns the current state details of the qubit entangled with the provided one.
     * Conceptually simulates predicting the entangled outcome based on current information.
     * @param _qubitId The ID of the qubit whose entangled partner's state is requested.
     * @return The QubitState struct of the linked qubit.
     */
    function predictEntanglementOutcome(uint256 _qubitId) external view returns (QubitState memory) {
         QubitState storage qubit = qubitStates[_qubitId];
         require(qubit.id != 0, "QL: Qubit does not exist");
         return qubitStates[qubit.linkedQubitId];
    }


    // --- Advanced/Conceptual Manipulation ---

    /**
     * @notice Conceptual function to "merge" properties of two different EntanglementPairs.
     * In this simplified implementation, it averages the entropies of one qubit from each pair
     * and creates a new, un-entangled qubit state with that average entropy, minting a key for it.
     * @param _pairIdA The ID of the first pair.
     * @param _pairIdB The ID of the second pair.
     * @param _to Address to mint the new key to.
     * @dev This is a highly simplified model of a complex operation.
     */
    function mergeEntanglementPairs(uint256 _pairIdA, uint256 _pairIdB, address _to) external onlyOwner returns (uint256 newQubitId, uint256 newKeyId) {
        EntanglementPair storage pairA = entanglementPairs[_pairIdA];
        EntanglementPair storage pairB = entanglementPairs[_pairIdB];
        require(pairA.id != 0 && pairB.id != 0, "QL: One or both pairs do not exist");
        require(_pairIdA != _pairIdB, "QL: Cannot merge a pair with itself");
        require(_to != address(0), "QL: Cannot mint key to zero address");

        // Simple merging logic: average the entropy of Qubit A from each pair
        uint256 avgEntropy = (qubitStates[pairA.qubitIdA].unlockEntropy + qubitStates[pairB.qubitIdA].unlockEntropy) / 2;

        // Create a new, un-entangled qubit state
        newQubitId = _nextQubitId++;
        QubitState storage newQubit = qubitStates[newQubitId];
        newQubit.id = newQubitId;
        newQubit.pairId = 0; // Not part of a pair
        newQubit.linkedQubitId = 0; // No linked partner
        newQubit.locked = true;
        newQubit.unlockEntropy = avgEntropy;
        newQubit.decayRate = 0; // Doesn't decay initially
        newQubit.lastDecayTimestamp = uint48(block.timestamp);
        newQubit.owner = _to;

        emit QubitStateCreated(newQubitId, 0, _to); // 0 indicates no pair

        // Mint a key for the new qubit
        newKeyId = mintEntanglementKey(_to, newQubitId); // Calls the internal mint logic

        emit PairsMerged(_pairIdA, _pairIdB, newQubitId);

        return (newQubitId, newKeyId);
    }

    /**
     * @notice Conceptual function to "split" an EntanglementKey.
     * Creates a new key linked to the *paired* qubit state of the original key.
     * This allows access to both sides of an entangled pair using separate keys.
     * @param _keyId The ID of the key to split.
     * @param _to Address to mint the new key to (can be the same as original key owner).
     */
    function splitEntanglementKey(uint256 _keyId, address _to) external returns (uint256 newKeyId) {
        EntanglementKey storage originalKey = entanglementKeys[_keyId];
        require(originalKey.owner != address(0), "QL: Original key does not exist");
        require(originalKey.owner == msg.sender, "QL: Not original key owner");
        require(_to != address(0), "QL: Cannot mint key to zero address");

        uint256 originalQubitId = originalKey.linkedQubitId;
        QubitState storage originalQubit = qubitStates[originalQubitId];
        require(originalQubit.pairId != 0, "QL: Original qubit is not part of an entangled pair");

        uint256 linkedQubitId = originalQubit.linkedQubitId;
        require(qubitStates[linkedQubitId].id != 0, "QL: Linked qubit does not exist");

        // Mint a new key for the linked qubit
        newKeyId = _nextKeyId++;
        EntanglementKey storage newKey = entanglementKeys[newKeyId];
        newKey.id = newKeyId;
        newKey.owner = _to;
        newKey.linkedQubitId = linkedQubitId;
        newKey.creationTimestamp = uint64(block.timestamp);

        _keysByOwner[_to].push(newKeyId);

        // Assign ownership of the linked qubit state conceptually to the new key owner
        qubitStates[linkedQubitId].owner = _to;

        emit EntanglementKeyMinted(newKeyId, _to, linkedQubitId);
        emit KeySplit(_keyId, newKeyId);

        return newKeyId;
    }

    /**
     * @notice Allows any user to donate ETH to increase the unlock entropy of a QubitState.
     * This makes the state harder to observe/unlock.
     * @param _qubitId The ID of the QubitState to donate entropy to.
     * @dev The donated ETH is conceptually converted into entropy and added to the qubit's requirement.
     */
    function donateEntropy(uint256 _qubitId) external payable {
        require(msg.value > 0, "QL: Must send ETH to donate entropy");
        QubitState storage qubit = qubitStates[_qubitId];
        require(qubit.id != 0, "QL: Qubit does not exist");

        // Convert ETH to entropy. 1 ETH = 10^18 Wei. Let's say 1 Wei = 1 unit of entropy.
        // Add it to the current entropy. Overflow is possible with large values,
        // but unlikely with uint256 unless astronomical.
        uint256 oldEntropy = qubit.unlockEntropy;
        qubit.unlockEntropy += msg.value;

        emit EntropyDonated(_qubitId, msg.sender, msg.value);
        emit QubitEntropyUpdated(_qubitId, oldEntropy, qubit.unlockEntropy);
    }

    // --- Maintenance & Owner Functions ---

    /**
     * @notice Owner function to manually adjust the unlock entropy of a QubitState.
     * @param _qubitId The ID of the QubitState.
     * @param _newEntropy The new unlock entropy value.
     */
    function updateUnlockEntropy(uint256 _qubitId, uint256 _newEntropy) external onlyOwner {
        QubitState storage qubit = qubitStates[_qubitId];
        require(qubit.id != 0, "QL: Qubit does not exist");
        uint256 oldEntropy = qubit.unlockEntropy;
        qubit.unlockEntropy = _newEntropy;
        emit QubitEntropyUpdated(_qubitId, oldEntropy, _newEntropy);
    }

    /**
     * @notice Owner function to enable or disable the entanglement effect for a specific pair.
     * If disabled, observing one qubit in the pair will not affect the state of the other.
     * @param _pairId The ID of the pair.
     * @param _enabled True to enable, false to disable.
     */
    function togglePairEntanglement(uint256 _pairId, bool _enabled) external onlyOwner {
        EntanglementPair storage pair = entanglementPairs[_pairId];
        require(pair.id != 0, "QL: Pair does not exist");
        pair.entanglementEnabled = _enabled;
        emit PairEntanglementToggled(_pairId, _enabled);
    }

    /**
     * @notice Owner function to reset a QubitState back to its initial locked condition.
     * Can also set a new initial entropy.
     * @param _qubitId The ID of the QubitState to reset.
     * @param _newInitialEntropy The entropy value to set upon reset.
     */
    function resetQubitState(uint256 _qubitId, uint256 _newInitialEntropy) external onlyOwner {
        QubitState storage qubit = qubitStates[_qubitId];
        require(qubit.id != 0, "QL: Qubit does not exist");

        qubit.locked = true;
        uint256 oldEntropy = qubit.unlockEntropy;
        qubit.unlockEntropy = _newInitialEntropy;
        qubit.lastDecayTimestamp = uint48(block.timestamp); // Reset decay timer

        emit QubitStateReset(_qubitId);
        emit QubitEntropyUpdated(_qubitId, oldEntropy, qubit.unlockEntropy);
    }

     /**
     * @notice Owner function to withdraw any accidental ETH sent to the contract.
     */
    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}
```