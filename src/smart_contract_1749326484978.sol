Okay, this sounds like a fun challenge! Let's design a smart contract that manages unique digital entities ("Quirks") whose attributes are influenced by simulated quantum fluctuations, AI insights (represented by hashes), and user interactions. It won't be a standard token or NFT, focusing purely on the unique state mechanics and interactions.

**Concept:** **QuantumQuirkNexus**

A contract managing non-fungible "Quirks". Each Quirk has immutable "Genetic Code" and evolving "Dynamic Attributes". Attributes change over time via deterministic "Fluctuations" (inspired by quantum randomness, using block data as seed), can be influenced by external "AI Insights" (hashes recorded by designated oracles), and can be altered by specific user actions ("Mutation", "Challenge").

**Outline:**

1.  **Contract Information:** SPDX License, Pragma.
2.  **Interfaces:** (None for this unique logic to avoid duplication).
3.  **Libraries:** (None needed for basic arithmetic in 0.8+, will avoid complex ones).
4.  **Errors:** Custom error definitions.
5.  **Events:** Logging key state changes and actions.
6.  **Enums:** Quirk Statuses, Mutation Hints.
7.  **Structs:** Quirk Dynamic Attributes, Quirk main struct.
8.  **State Variables:**
    *   Owner, Paused state.
    *   Quirk storage (mapping).
    *   Quirk counter.
    *   Ownership and Approval mappings (simple).
    *   Oracle Role management.
    *   Configuration parameters (cooldowns, fees, bounds, influence factors).
9.  **Modifiers:** `onlyOwner`, `paused`, `notPaused`, `onlyOracle`.
10. **Constructor:** Initialize owner, basic parameters.
11. **Core Logic Functions:**
    *   `createQuirk`: Mint a new Quirk.
    *   `triggerFluctuation`: Apply fluctuation logic to a single Quirk.
    *   `triggerFluctuationForBatch`: Apply fluctuation to multiple Quirks (Oracle/Owner).
    *   `mutateQuirk`: User attempts to mutate a Quirk.
    *   `applyAIInsight`: Oracle records an AI insight hash for a Quirk.
    *   `challengeQuirkStability`: User challenges a Quirk's stability.
12. **Helper/Internal Functions:**
    *   `_mintQuirk`: Internal minting logic.
    *   `_transferQuirk`: Internal transfer logic.
    *   `_applyFluctuationLogic`: Calculates attribute changes based on fluctuation.
    *   `_applyAIInfluence`: Calculates attribute changes based on AI insight.
    *   `_applyExternalInfluence`: Calculates attribute changes based on external event hash.
    *   `_applyMutationLogic`: Calculates mutation outcome.
    *   `_applyChallengeOutcome`: Calculates challenge outcome.
    *   `_generateDeterministicSeed`: Creates a seed from multiple inputs.
    *   `_updateQuirkStatus`: Updates status based on attributes/state.
13. **Admin/Management Functions:**
    *   `mintInitialQuirks`: Owner mints initial Quirks.
    *   `setFluctuationCooldown`: Set minimum blocks between fluctuations.
    *   `setMutationFee`: Set fee for mutation.
    *   `setChallengeFee`: Set fee for challenge.
    *   `setInfluenceParameters`: Adjust how AI/External hashes affect attributes.
    *   `setQuirkAttributeBounds`: Set min/max values for dynamic attributes.
    *   `setFluctuationMagnitude`: Set scale of changes during fluctuation.
    *   `addOracle`: Grant Oracle role.
    *   `removeOracle`: Revoke Oracle role.
    *   `pauseContract`: Pause key interactions.
    *   `unpauseContract`: Unpause contract.
    *   `withdrawFees`: Withdraw collected fees.
14. **Query Functions:**
    *   `getQuirkDetails`: Get full Quirk data.
    *   `getQuirkDynamicAttributes`: Get just dynamic attributes.
    *   `getQuirkStatus`: Get Quirk status.
    *   `getQuirkOwner`: Get Quirk owner.
    *   `totalSupply`: Total Quirks minted.
    *   `getFluctuationCooldown`: Get current fluctuation cooldown.
    *   `canTriggerFluctuation`: Check if fluctuation is possible for a Quirk.
    *   `predictFluctuationOutcomeHash`: Simulate fluctuation seed hash for prediction.
    *   `analyzeGeneticCode`: Get derived data from genetic code.
    *   `calculateQuirkResonanceScore`: Compute a score based on attributes.
    *   `getPendingAIInsightHash`: Get the last recorded AI insight hash.
    *   `getOracleStatus`: Check if an address is an Oracle.
15. **Token/Ownership Functions (Simplified):**
    *   `transferQuirk`: Transfer ownership.
    *   `approveQuirkTransfer`: Approve one address for transfer.
    *   `getApproved`: Get approved address.

**Function Summary:**

1.  `createQuirk(bytes32 initialSeed)`: Allows anyone to mint a new Quirk by providing an initial seed, paying a fee. Generates a unique ID and sets initial state.
2.  `mintInitialQuirks(address[] calldata owners, bytes32[] calldata seeds)`: Owner-only function to mint a batch of initial Quirks for specified owners with specific seeds.
3.  `triggerFluctuation(uint256 quirkId)`: Allows anyone to trigger a "Quantum Fluctuation" on a specific Quirk if the cooldown has passed. Updates dynamic attributes and status based on a deterministic seed derived from block data and Quirk state.
4.  `triggerFluctuationForBatch(uint256[] calldata quirkIds)`: Owner/Oracle only function to trigger fluctuation for multiple specified Quirks, bypassing cooldown.
5.  `mutateQuirk(uint256 quirkId, Enums.MutationHint hint)`: Allows a Quirk owner to attempt a targeted mutation, paying a fee. Outcome depends on the hint, Quirk's current state, and a probabilistic element.
6.  `applyAIInsight(uint256 quirkId, bytes32 insightHash)`: Oracle-only function to record a hash representing an external AI's analysis or prediction for a specific Quirk. This hash influences future fluctuations.
7.  `challengeQuirkStability(uint256 quirkId)`: Allows any user to challenge a Quirk's stability, paying a fee. Has a chance to alter the Quirk's stability attribute or status based on its current state.
8.  `mintInitialQuirks(...)`: See #2.
9.  `setFluctuationCooldown(uint256 _cooldownBlocks)`: Owner sets the minimum number of blocks between fluctuations for any single Quirk.
10. `setMutationFee(uint256 _fee)`: Owner sets the fee required to attempt a mutation.
11. `setChallengeFee(uint256 _fee)`: Owner sets the fee required to challenge a Quirk's stability.
12. `setInfluenceParameters(uint256 _aiInfluenceFactor, uint256 _externalInfluenceFactor)`: Owner sets parameters controlling the magnitude of change derived from recorded AI and external event hashes during fluctuation.
13. `setQuirkAttributeBounds(uint256[] calldata mins, uint256[] calldata maxs)`: Owner sets the minimum and maximum possible values for the dynamic attributes. Must match the number of dynamic attributes.
14. `setFluctuationMagnitude(uint256 _magnitude)`: Owner sets a general scaling factor for how much dynamic attributes change during a standard fluctuation.
15. `addOracle(address oracleAddress)`: Owner grants the Oracle role to an address.
16. `removeOracle(address oracleAddress)`: Owner revokes the Oracle role from an address.
17. `pauseContract()`: Owner pauses certain interactions (creation, mutation, challenge, single fluctuation).
18. `unpauseContract()`: Owner unpauses the contract.
19. `withdrawFees()`: Owner withdraws accumulated Ether fees.
20. `getQuirkDetails(uint256 quirkId)`: Public view function to get all stored data for a Quirk.
21. `getQuirkDynamicAttributes(uint256 quirkId)`: Public view function to get just the dynamic attributes of a Quirk.
22. `getQuirkStatus(uint256 quirkId)`: Public view function to get the current status of a Quirk.
23. `getQuirkOwner(uint256 quirkId)`: Public view function to get the owner of a Quirk.
24. `totalSupply()`: Public view function returning the total number of Quirks minted.
25. `getFluctuationCooldown()`: Public view function returning the current fluctuation cooldown block count.
26. `canTriggerFluctuation(uint256 quirkId)`: Public view function checking if enough blocks have passed since the last fluctuation for a specific Quirk.
27. `predictFluctuationOutcomeHash(uint256 quirkId, uint256 futureBlockNumber)`: Public view function that calculates the deterministic seed hash that *would* be used if fluctuation were triggered at a *hypothetical* future block, allowing off-chain prediction/analysis. Does *not* guarantee the state changes, only the input seed.
28. `analyzeGeneticCode(uint256 quirkId)`: Public view function that derives and returns some predefined properties or a "potential" score based *only* on the Quirk's immutable genetic code.
29. `calculateQuirkResonanceScore(uint256 quirkId)`: Public view function that calculates a composite "Resonance Score" based on the Quirk's *current* dynamic attributes.
30. `getPendingAIInsightHash(uint256 quirkId)`: Public view function to see the last recorded AI insight hash for a Quirk.
31. `getOracleStatus(address account)`: Public view function to check if an account has the Oracle role.
32. `transferQuirk(address to, uint256 quirkId)`: Allows Quirk owner to transfer ownership.
33. `approveQuirkTransfer(address approved, uint256 quirkId)`: Allows Quirk owner to approve a single address to transfer their Quirk.
34. `getApproved(uint256 quirkId)`: Public view function to get the approved address for a Quirk.
35. `recordExternalEventInfluence(bytes32 eventHash)`: Oracle-only function to record a hash representing a significant external event. This hash influences *all* subsequent fluctuations until updated.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumQuirkNexus
 * @dev A smart contract managing unique digital entities ("Quirks")
 *      with evolving attributes influenced by simulated quantum fluctuations,
 *      AI insights, external events, and user interactions.
 *      Focuses on unique state transition logic rather than standard token features.
 *
 * Outline:
 * 1. Contract Information (SPDX, Pragma)
 * 2. Errors
 * 3. Events
 * 4. Enums
 * 5. Structs
 * 6. State Variables
 * 7. Modifiers
 * 8. Constructor
 * 9. Core Logic Functions (Create, Fluctuate, Mutate, AI/External Influence, Challenge)
 * 10. Helper/Internal Functions (Deterministic Seed, State Updates, Transfers, etc.)
 * 11. Admin/Management Functions (Set Params, Roles, Pause, Withdraw)
 * 12. Query Functions (Get Quirk Data, Status, Checks)
 * 13. Token/Ownership Functions (Simplified Transfer/Approval)
 *
 * Function Summary:
 * 1. createQuirk(bytes32 initialSeed): Mint a new Quirk with a user-provided seed.
 * 2. mintInitialQuirks(address[] calldata owners, bytes32[] calldata seeds): Owner mints initial Quirks.
 * 3. triggerFluctuation(uint256 quirkId): Trigger state fluctuation for one Quirk based on block data & state.
 * 4. triggerFluctuationForBatch(uint256[] calldata quirkIds): Owner/Oracle triggers fluctuation for a batch.
 * 5. mutateQuirk(uint256 quirkId, Enums.MutationHint hint): Owner attempts attribute mutation.
 * 6. applyAIInsight(uint256 quirkId, bytes32 insightHash): Oracle records AI data hash for a Quirk.
 * 7. challengeQuirkStability(uint256 quirkId): User challenges a Quirk's stability.
 * 8. setFluctuationCooldown(uint256 _cooldownBlocks): Owner sets fluctuation cooldown.
 * 9. setMutationFee(uint256 _fee): Owner sets mutation fee.
 * 10. setChallengeFee(uint256 _fee): Owner sets challenge fee.
 * 11. setInfluenceParameters(uint256 _aiInfluenceFactor, uint256 _externalInfluenceFactor): Owner sets AI/External influence factors.
 * 12. setQuirkAttributeBounds(uint256[] calldata mins, uint256[] calldata maxs): Owner sets bounds for dynamic attributes.
 * 13. setFluctuationMagnitude(uint256 _magnitude): Owner sets fluctuation change magnitude.
 * 14. addOracle(address oracleAddress): Owner grants Oracle role.
 * 15. removeOracle(address oracleAddress): Owner revokes Oracle role.
 * 16. pauseContract(): Owner pauses interactions.
 * 17. unpauseContract(): Owner unpauses interactions.
 * 18. withdrawFees(): Owner withdraws contract balance.
 * 19. getQuirkDetails(uint256 quirkId): Get full Quirk data.
 * 20. getQuirkDynamicAttributes(uint256 quirkId): Get dynamic attributes.
 * 21. getQuirkStatus(uint256 quirkId): Get Quirk status.
 * 22. getQuirkOwner(uint256 quirkId): Get Quirk owner.
 * 23. totalSupply(): Get total number of Quirks.
 * 24. getFluctuationCooldown(): Get fluctuation cooldown setting.
 * 25. canTriggerFluctuation(uint256 quirkId): Check if fluctuation is possible for a Quirk.
 * 26. predictFluctuationOutcomeHash(uint256 quirkId, uint256 futureBlockNumber): Predict fluctuation seed hash for a future block.
 * 27. analyzeGeneticCode(uint256 quirkId): Analyze derived properties from genetic code.
 * 28. calculateQuirkResonanceScore(uint256 quirkId): Calculate score based on dynamic attributes.
 * 29. getPendingAIInsightHash(uint256 quirkId): Get last recorded AI insight hash.
 * 30. getOracleStatus(address account): Check Oracle role status.
 * 31. transferQuirk(address to, uint256 quirkId): Transfer Quirk ownership.
 * 32. approveQuirkTransfer(address approved, uint256 quirkId): Approve address for transfer.
 * 33. getApproved(uint256 quirkId): Get approved address for a Quirk.
 * 34. recordExternalEventInfluence(bytes32 eventHash): Oracle records a global external event hash.
 * 35. getQuirkCreationBlock(uint256 quirkId): Get the creation block of a Quirk.
 */

contract QuantumQuirkNexus {

    // --- Errors ---
    error NotOwner();
    error Paused();
    error NotPaused();
    error NotOracle();
    error QuirkDoesNotExist(uint256 quirkId);
    error NotQuirkOwner(uint256 quirkId);
    error TransferNotApproved(uint256 quirkId);
    error FluctuationCooldownNotPassed(uint256 quirkId, uint256 readyBlock);
    error InvalidAttributeBounds(string message);
    error ArrayLengthMismatch(string message);
    error InsufficientPayment(uint256 required);
    error InvalidAddress(address addr);

    // --- Events ---
    event QuirkCreated(uint256 indexed quirkId, address indexed owner, bytes32 geneticCode, uint256 creationBlock);
    event QuirkFluctuated(uint256 indexed quirkId, bytes32 fluctuationSeed, QuirkDynamicAttributes oldAttributes, QuirkDynamicAttributes newAttributes, Enums.QuirkStatus newStatus);
    event QuirkMutated(uint256 indexed quirkId, address indexed mutator, Enums.MutationHint indexed hint, bool success, QuirkDynamicAttributes oldAttributes, QuirkDynamicAttributes newAttributes);
    event AIInsightApplied(uint256 indexed quirkId, address indexed oracle, bytes32 insightHash);
    event ExternalEventRecorded(address indexed oracle, bytes32 eventHash);
    event QuirkStabilityChallenged(uint256 indexed quirkId, address indexed challenger, uint256 outcomeType, QuirkDynamicAttributes oldAttributes, QuirkDynamicAttributes newAttributes);
    event StatusChanged(uint256 indexed quirkId, Enums.QuirkStatus oldStatus, Enums.QuirkStatus newStatus);
    event QuirkTransferred(uint256 indexed quirkId, address indexed from, address indexed to);
    event Approval(uint256 indexed quirkId, address indexed owner, address indexed approved);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event PausedContract(address indexed by);
    event UnpausedContract(address indexed by);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event ParamsUpdated(string paramName, uint256 value); // Generic for simple param changes
    event BoundsUpdated(uint256[] mins, uint256[] maxs);

    // --- Enums ---
    enum Enums {
        Stable,
        Fluctuating,
        Resonating,
        Dormant,
        Challenged,
        MutationHintA,
        MutationHintB,
        MutationHintC // Example hints
    }

    // --- Structs ---
    struct QuirkDynamicAttributes {
        uint256 quirkiness; // How prone to unpredictable change
        uint256 stability;  // Resistance to change and challenges
        uint256 resonance;  // How strongly it interacts with external factors (AI/Events)
        uint256 complexity; // Overall attribute depth/range
        // Add more dynamic attributes here as needed, update array access in logic
    }

    struct Quirk {
        uint256 creationBlock;
        uint256 lastFluctuationBlock;
        bytes32 geneticCode; // Immutable seed
        QuirkDynamicAttributes attributes;
        Enums.QuirkStatus status;
        bytes32 lastAIInsightHash; // Last applied AI hash
        uint256 lastAIInsightBlock; // Block when last AI hash was applied
    }

    // --- State Variables ---
    address private immutable i_owner;
    bool private s_paused;

    mapping(uint256 => Quirk) private s_quirks;
    uint256 private s_nextQuirkId;

    // Basic ownership and approval - NOT full ERC721
    mapping(uint256 => address) private s_quirkOwners;
    mapping(uint256 => address) private s_quirkApproved;
    mapping(address => uint256) private s_ownerQuirkCount; // Track count, not IDs (gas)

    mapping(address => bool) private s_oracles;
    uint256 private s_oracleCount;

    uint256 private s_fluctuationCooldownBlocks = 10; // Blocks between fluctuations for a single Quirk
    uint256 private s_mutationFee = 0.01 ether;
    uint256 private s_challengeFee = 0.005 ether;
    uint256 private s_createFee = 0.02 ether;

    uint256 private s_aiInfluenceFactor = 5; // How much AI hash influences attribute changes
    uint256 private s_externalInfluenceFactor = 8; // How much external event hash influences
    uint256 private s_fluctuationMagnitude = 10; // Base amount attributes change during fluctuation

    uint256[] private s_attributeMins = [0, 0, 0, 0]; // Must match QuirkDynamicAttributes fields
    uint256[] private s_attributeMaxs = [100, 100, 100, 100]; // Must match QuirkDynamicAttributes fields

    bytes32 private s_lastExternalEventHash; // Global external event hash

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    modifier paused() {
        if (!s_paused) {
            revert NotPaused();
        }
        _;
    }

    modifier notPaused() {
        if (s_paused) {
            revert Paused();
        }
        _;
    }

     modifier onlyOracle() {
        if (!s_oracles[msg.sender] && msg.sender != i_owner) {
            revert NotOracle();
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        i_owner = msg.sender;
        // Initial parameters are set by state variables, can be updated by owner
    }

    // --- Core Logic Functions ---

    /**
     * @dev Creates a new Quirk. Requires a fee.
     * @param initialSeed A user-provided seed for the genetic code.
     */
    function createQuirk(bytes32 initialSeed) external payable notPaused {
        if (msg.value < s_createFee) {
            revert InsufficientPayment(s_createFee);
        }
        _mintQuirk(msg.sender, initialSeed);
    }

    /**
     * @dev Triggers a quantum fluctuation for a specific Quirk.
     *      Can be called by anyone if the cooldown has passed.
     *      Applies fluctuation, AI, and external event influence.
     * @param quirkId The ID of the Quirk to fluctuate.
     */
    function triggerFluctuation(uint256 quirkId) external notPaused {
        Quirk storage quirk = s_quirks[quirkId];
        if (quirk.creationBlock == 0) { // Simple check if Quirk exists
            revert QuirkDoesNotExist(quirkId);
        }
        if (block.number < quirk.lastFluctuationBlock + s_fluctuationCooldownBlocks) {
            revert FluctuationCooldownNotPassed(quirkId, quirk.lastFluctuationBlock + s_fluctuationCooldownBlocks);
        }

        quirk.lastFluctuationBlock = block.number;

        // Apply fluctuations
        _applyFluctuationLogic(quirkId);

        // Apply AI Insight influence (if any recorded)
        _applyAIInfluence(quirkId);

        // Apply External Event influence (if any recorded)
        _applyExternalInfluence(quirkId);

        // Update status based on new attributes
        _updateQuirkStatus(quirkId);

        emit QuirkFluctuated(
            quirkId,
            _generateDeterministicSeed(quirkId, block.number), // Emit the seed used for this fluctuation
            quirk.attributes, // Old attributes captured before updates
            quirk.attributes, // New attributes after updates
            quirk.status
        );
    }

    /**
     * @dev Owner/Oracle function to trigger fluctuation for a batch of Quirks.
     *      Bypasses cooldown. Use carefully as gas costs scale with batch size.
     * @param quirkIds Array of Quirk IDs to fluctuate.
     */
    function triggerFluctuationForBatch(uint256[] calldata quirkIds) external onlyOracle {
        for (uint256 i = 0; i < quirkIds.length; i++) {
            uint256 quirkId = quirkIds[i];
            Quirk storage quirk = s_quirks[quirkId];
            if (quirk.creationBlock == 0) continue; // Skip non-existent

            quirk.lastFluctuationBlock = block.number; // Update cooldown for each

            _applyFluctuationLogic(quirkId);
            _applyAIInfluence(quirkId);
            _applyExternalInfluence(quirkId);
            _updateQuirkStatus(quirkId);

             // Emit event for each fluctuated Quirk
             emit QuirkFluctuated(
                quirkId,
                _generateDeterministicSeed(quirkId, block.number),
                quirk.attributes, // Note: This will show state *before* batch processing, not per-item
                quirk.attributes,
                quirk.status
            );
        }
        // Consider a single batch event for large batches if per-quirk is too noisy
    }


    /**
     * @dev Allows a Quirk owner to attempt a mutation. Requires a fee.
     *      Outcome is probabilistic based on Quirk state and hint.
     * @param quirkId The ID of the Quirk to mutate.
     * @param hint A hint suggesting the type of mutation to encourage.
     */
    function mutateQuirk(uint256 quirkId, Enums.MutationHint hint) external payable notPaused {
        if (msg.value < s_mutationFee) {
             revert InsufficientPayment(s_mutationFee);
        }
        if (s_quirkOwners[quirkId] != msg.sender) {
            revert NotQuirkOwner(quirkId);
        }
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }

        // Store attributes before mutation attempt
        QuirkDynamicAttributes memory oldAttributes = s_quirks[quirkId].attributes;

        // Apply mutation logic - outcome depends on state, hint, and pseudo-randomness
        bool success = _applyMutationLogic(quirkId, hint);

        // Update status if needed (mutation might change it)
        _updateQuirkStatus(quirkId);

        emit QuirkMutated(
            quirkId,
            msg.sender,
            hint,
            success,
            oldAttributes,
            s_quirks[quirkId].attributes
        );
    }

    /**
     * @dev Oracle-only function to record a hash representing external AI insight.
     *      This hash will influence subsequent fluctuations for this Quirk.
     * @param quirkId The ID of the Quirk.
     * @param insightHash The hash representing the AI insight.
     */
    function applyAIInsight(uint256 quirkId, bytes32 insightHash) external onlyOracle {
        Quirk storage quirk = s_quirks[quirkId];
        if (quirk.creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }

        quirk.lastAIInsightHash = insightHash;
        quirk.lastAIInsightBlock = block.number;

        emit AIInsightApplied(quirkId, msg.sender, insightHash);
    }

    /**
     * @dev Allows any user to challenge a Quirk's stability. Requires a fee.
     *      Outcome is probabilistic and can affect the Quirk's state.
     * @param quirkId The ID of the Quirk to challenge.
     */
    function challengeQuirkStability(uint256 quirkId) external payable notPaused {
        if (msg.value < s_challengeFee) {
            revert InsufficientPayment(s_challengeFee);
        }
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }

        Quirk storage quirk = s_quirks[quirkId];
        QuirkDynamicAttributes memory oldAttributes = quirk.attributes;

        // Apply challenge logic - outcome depends on stability and pseudo-randomness
        uint256 outcomeType = _applyChallengeOutcome(quirkId); // 0: No Effect, 1: Stability Down, 2: Stability Up, 3: Status Change

        // Update status if needed
         _updateQuirkStatus(quirkId); // Status might change based on challenge outcome

        emit QuirkStabilityChallenged(
            quirkId,
            msg.sender,
            outcomeType,
            oldAttributes,
            quirk.attributes
        );
    }

    /**
     * @dev Oracle-only function to record a hash representing a global external event.
     *      This hash influences all subsequent fluctuations across all Quirks.
     * @param eventHash The hash representing the external event.
     */
    function recordExternalEventInfluence(bytes32 eventHash) external onlyOracle {
        s_lastExternalEventHash = eventHash;
        emit ExternalEventRecorded(msg.sender, eventHash);
    }

    // --- Helper/Internal Functions ---

    /**
     * @dev Mints a new Quirk internally.
     * @param owner The address that will own the new Quirk.
     * @param geneticCode The immutable genetic code for the Quirk.
     */
    function _mintQuirk(address owner, bytes32 geneticCode) internal {
        if (owner == address(0)) revert InvalidAddress(address(0));

        uint256 newQuirkId = s_nextQuirkId++;

        // Initial dynamic attributes derived simply from genetic code and block
        uint256 seed = uint256(keccak256(abi.encodePacked(geneticCode, block.number, block.timestamp)));
        QuirkDynamicAttributes memory initialAttributes = QuirkDynamicAttributes({
            quirkiness: (uint256(seed) % (s_attributeMaxs[0] - s_attributeMins[0] + 1)) + s_attributeMins[0],
            stability: (uint256(seed >> 32) % (s_attributeMaxs[1] - s_attributeMins[1] + 1)) + s_attributeMins[1],
            resonance: (uint256(seed >> 64) % (s_attributeMaxs[2] - s_attributeMins[2] + 1)) + s_attributeMins[2],
            complexity: (uint256(seed >> 96) % (s_attributeMaxs[3] - s_attributeMins[3] + 1)) + s_attributeMins[3]
            // Add more attributes if added to struct
        });

        s_quirks[newQuirkId] = Quirk({
            creationBlock: block.number,
            lastFluctuationBlock: block.number, // Starts with fluctuation on creation
            geneticCode: geneticCode,
            attributes: initialAttributes,
            status: Enums.QuirkStatus.Stable, // Initial status
            lastAIInsightHash: bytes32(0), // No initial AI insight
            lastAIInsightBlock: 0
        });

        _transferQuirk(address(this), owner, newQuirkId); // Transfer from contract (minter) to owner

        emit QuirkCreated(newQuirkId, owner, geneticCode, block.number);
    }

    /**
     * @dev Internal function to generate a deterministic seed for fluctuations.
     *      Uses Quirk state and block data.
     * @param quirkId The ID of the Quirk.
     * @param blockNum The block number for the seed.
     * @return A 256-bit seed value.
     */
    function _generateDeterministicSeed(uint256 quirkId, uint256 blockNum) internal view returns (bytes32) {
        Quirk storage quirk = s_quirks[quirkId];
        // Use blockhash of current or previous block if available, combine with state
        // Note: blockhash(block.number - 1) is only available for the last 256 blocks.
        // Using block.timestamp is also an option, but less robust for fast fluctuations.
        // For simplicity and determinism *within* the block, let's combine multiple known values.
        bytes32 blockMix = block.number > 0 ? blockhash(block.number - 1) : bytes32(block.timestamp);

        return keccak256(abi.encodePacked(
            quirk.geneticCode,
            quirk.attributes.quirkiness,
            quirk.attributes.stability,
            quirk.attributes.resonance,
            quirk.attributes.complexity,
            blockMix, // Pseudorandom source
            block.number,
            block.timestamp,
            msg.sender // Include msg.sender to make triggerer influence seed slightly
        ));
    }

     /**
     * @dev Applies the core fluctuation logic to a Quirk's attributes.
     *      Changes are based on a deterministic seed and magnitude.
     * @param quirkId The ID of the Quirk.
     */
    function _applyFluctuationLogic(uint256 quirkId) internal {
        Quirk storage quirk = s_quirks[quirkId];
        bytes32 seed = _generateDeterministicSeed(quirkId, block.number);
        uint256 seedInt = uint256(seed);

        // Apply changes based on different parts of the seed
        // Ensure attribute bounds are respected
        quirk.attributes.quirkiness = _applyChange(quirk.attributes.quirkiness, seedInt, s_attributeMins[0], s_attributeMaxs[0], s_fluctuationMagnitude);
        quirk.attributes.stability = _applyChange(quirk.attributes.stability, seedInt >> 64, s_attributeMins[1], s_attributeMaxs[1], s_fluctuationMagnitude);
        quirk.attributes.resonance = _applyChange(quirk.attributes.resonance, seedInt >> 128, s_attributeMins[2], s_attributeMaxs[2], s_fluctuationMagnitude);
        quirk.attributes.complexity = _applyChange(quirk.attributes.complexity, seedInt >> 192, s_attributeMins[3], s_attributeMaxs[3], s_fluctuationMagnitude);
        // Add logic for other attributes if added
    }

    /**
     * @dev Helper to apply a change to an attribute based on a seed part and magnitude, respecting bounds.
     * @param currentValue The current attribute value.
     * @param seedPart A segment of the random seed.
     * @param min The minimum bound.
     * @param max The maximum bound.
     * @param magnitude The scale of the change.
     * @return The new attribute value after applying the change and clamping.
     */
    function _applyChange(uint256 currentValue, uint256 seedPart, uint256 min, uint256 max, uint256 magnitude) internal pure returns (uint256) {
        // Simple change logic: (seedPart % (2*magnitude+1)) - magnitude
        // This results in a change between -magnitude and +magnitude
        int256 change = int256(seedPart % (2 * magnitude + 1)) - int256(magnitude);
        int256 newValue = int256(currentValue) + change;

        // Clamp value within bounds
        if (newValue < int256(min)) return min;
        if (newValue > int256(max)) return max;
        return uint256(newValue);
    }


    /**
     * @dev Applies influence from the last recorded AI insight hash.
     *      Called internally by _applyFluctuationLogic.
     * @param quirkId The ID of the Quirk.
     */
    function _applyAIInfluence(uint256 quirkId) internal {
         Quirk storage quirk = s_quirks[quirkId];
         // Only apply if there's a recent insight hash recorded
         if (quirk.lastAIInsightHash == bytes32(0) /* || block.number > quirk.lastAIInsightBlock + s_aiInfluencePotencyBlocks */) {
             return; // Optional: Add time decay for AI insight potency
         }

         bytes32 aiSeed = keccak256(abi.encodePacked(quirk.attributes, quirk.lastAIInsightHash, block.number));
         uint256 aiSeedInt = uint256(aiSeed);

         // Influence attributes based on AI seed and s_aiInfluenceFactor
         quirk.attributes.quirkiness = _applyInfluenceChange(quirk.attributes.quirkiness, aiSeedInt, s_attributeMins[0], s_attributeMaxs[0], s_aiInfluenceFactor);
         quirk.attributes.stability = _applyInfluenceChange(quirk.attributes.stability, aiSeedInt >> 64, s_attributeMins[1], s_attributeMaxs[1], s_aiInfluenceFactor);
         quirk.attributes.resonance = _applyInfluenceChange(quirk.attributes.resonance, aiSeedInt >> 128, s_attributeMins[2], s_attributeMaxs[2], s_aiInfluenceFactor * 2); // Maybe AI affects resonance more?
         quirk.attributes.complexity = _applyInfluenceChange(quirk.attributes.complexity, aiSeedInt >> 192, s_attributeMins[3], s_attributeMaxs[3], s_aiInfluenceFactor);
         // Add logic for other attributes if added
    }

     /**
     * @dev Applies influence from the last recorded global external event hash.
     *      Called internally by _applyFluctuationLogic.
     * @param quirkId The ID of the Quirk.
     */
    function _applyExternalInfluence(uint256 quirkId) internal {
         if (s_lastExternalEventHash == bytes32(0)) {
             return; // No external event recorded yet
         }
         Quirk storage quirk = s_quirks[quirkId];

         bytes32 externalSeed = keccak256(abi.encodePacked(quirk.attributes, s_lastExternalEventHash, block.number, quirkId));
         uint256 externalSeedInt = uint256(externalSeed);

         // Influence attributes based on external seed and s_externalInfluenceFactor
         // Maybe external events affect different attributes or have different patterns
         quirk.attributes.quirkiness = _applyInfluenceChange(quirk.attributes.quirkiness, externalSeedInt >> 32, s_attributeMins[0], s_attributeMaxs[0], s_externalInfluenceFactor);
         quirk.attributes.stability = _applyInfluenceChange(quirk.attributes.stability, externalSeedInt >> 96, s_attributeMins[1], s_attributeMaxs[1], s_externalInfluenceFactor);
         quirk.attributes.resonance = _applyInfluenceChange(quirk.attributes.resonance, externalSeedInt, s_attributeMins[2], s_attributeMaxs[2], s_externalInfluenceFactor); // Maybe resonance reacts directly?
         quirk.attributes.complexity = _applyInfluenceChange(quirk.attributes.complexity, externalSeedInt >> 160, s_attributeMins[3], s_attributeMaxs[3], s_externalInfluenceFactor);
         // Add logic for other attributes if added
    }

    /**
     * @dev Helper to apply a change based on influence factors and a seed part, respecting bounds.
     * @param currentValue The current attribute value.
     * @param seedPart A segment of the random seed.
     * @param min The minimum bound.
     * @param max The maximum bound.
     * @param influenceFactor The scale of the influence change.
     * @return The new attribute value after applying the change and clamping.
     */
    function _applyInfluenceChange(uint256 currentValue, uint256 seedPart, uint256 min, uint256 max, uint256 influenceFactor) internal pure returns (uint256) {
         // Influence logic: currentValue + (seedPart % (2*influenceFactor+1) - influenceFactor)
         int256 change = int256(seedPart % (2 * influenceFactor + 1)) - int256(influenceFactor);
         int256 newValue = int256(currentValue) + change;

         // Clamp value within bounds
         if (newValue < int256(min)) return min;
         if (newValue > int256(max)) return max;
         return uint256(newValue);
    }


    /**
     * @dev Applies the mutation logic. Outcome depends on hint, state, and randomness.
     * @param quirkId The ID of the Quirk.
     * @param hint The mutation hint.
     * @return bool True if the mutation had a noticeable effect, false otherwise.
     */
    function _applyMutationLogic(uint256 quirkId, Enums.MutationHint hint) internal returns (bool) {
        Quirk storage quirk = s_quirks[quirkId];
        bytes32 seed = keccak256(abi.encodePacked(quirk.geneticCode, quirk.attributes, hint, block.timestamp, tx.origin)); // Use tx.origin for user-specific interaction seed

        uint256 successRoll = uint256(seed) % 100;
        uint256 baseSuccessRate = 50; // Base chance

        // Influence success rate by stability (higher stability = lower mutation chance?) or quirkiness (higher quirkiness = higher chance?)
        // Let's make higher quirkiness/lower stability increase chance
        uint256 adjustedSuccessRate = baseSuccessRate + (quirk.attributes.quirkiness / 5) - (quirk.attributes.stability / 10);
        if (adjustedSuccessRate > 95) adjustedSuccessRate = 95; // Cap success rate
        if (adjustedSuccessRate < 10) adjustedSuccessRate = 10; // Min success rate

        bool success = successRoll < adjustedSuccessRate;
        if (!success) return false; // Mutation failed

        // If successful, apply attribute changes based on hint and seed
        uint256 changeSeed = uint256(seed >> 128); // Use a different part of the seed

        // Example mutation logic based on hint
        if (hint == Enums.MutationHint.MutationHintA) {
            quirk.attributes.quirkiness = _applyChange(quirk.attributes.quirkiness, changeSeed, s_attributeMins[0], s_attributeMaxs[0], 20); // Larger change for MutA
            quirk.attributes.stability = _applyChange(quirk.attributes.stability, changeSeed >> 32, s_attributeMins[1], s_attributeMaxs[1], 5); // Smaller change for MutA
        } else if (hint == Enums.MutationHint.MutationHintB) {
            quirk.attributes.stability = _applyChange(quirk.attributes.stability, changeSeed, s_attributeMins[1], s_attributeMaxs[1], 20);
            quirk.attributes.resonance = _applyChange(quirk.attributes.resonance, changeSeed >> 32, s_attributeMins[2], s_attributeMaxs[2], 5);
        } else if (hint == Enums.MutationHint.MutationHintC) {
            quirk.attributes.resonance = _applyChange(quirk.attributes.resonance, changeSeed, s_attributeMins[2], s_attributeMaxs[2], 15);
            quirk.attributes.complexity = _applyChange(quirk.attributes.complexity, changeSeed >> 32, s_attributeMins[3], s_attributeMaxs[3], 15);
        }
        // Add more hint logic here

        return true; // Mutation was successful
    }

     /**
     * @dev Applies the challenge logic. Outcome depends on stability and randomness.
     * @param quirkId The ID of the Quirk.
     * @return uint256 representing the outcome type (0: No Effect, 1: Stability Down, 2: Stability Up, 3: Status Change).
     */
    function _applyChallengeOutcome(uint256 quirkId) internal returns (uint256) {
        Quirk storage quirk = s_quirks[quirkId];
        bytes32 seed = keccak256(abi.encodePacked(quirk.attributes, quirk.geneticCode, block.timestamp, tx.origin));

        uint256 outcomeRoll = uint256(seed) % 100;
        uint256 stabilityScore = quirk.attributes.stability;

        // Outcome probabilities influenced by stability (higher stability = less likely to change negatively)
        if (outcomeRoll < 10 + (stabilityScore / 5)) { // e.g., 10% to 30% chance (low stability helps)
            // Outcome: Stability decreases
             quirk.attributes.stability = _applyChange(quirk.attributes.stability, seed >> 32, s_attributeMins[1], s_attributeMaxs[1], 10); // Decrease by up to 10
             if (quirk.attributes.stability > s_attributeMins[1] + 5) quirk.attributes.stability -= 5; // Ensure a minimum decrease on fail
            return 1; // Stability Down
        } else if (outcomeRoll > 90 - (stabilityScore / 5)) { // e.g., 70% to 90% chance (high stability helps)
            // Outcome: Stability increases (successful defense)
             quirk.attributes.stability = _applyChange(quirk.attributes.stability, seed >> 64, s_attributeMins[1], s_attributeMaxs[1], 5); // Increase by up to 5
             if (quirk.attributes.stability < s_attributeMaxs[1] - 5) quirk.attributes.stability += 5; // Ensure a minimum increase on success
            return 2; // Stability Up
        } else if (outcomeRoll > 60 && stabilityScore < 50) {
             // Outcome: Status change (more likely for unstable Quirks)
             // Example: Maybe switch between Fluctuating/Resonating or Dormant
             if (quirk.status == Enums.QuirkStatus.Fluctuating) quirk.status = Enums.QuirkStatus.Resonating;
             else if (quirk.status == Enums.QuirkStatus.Resonating) quirk.status = Enums.QuirkStatus.Fluctuating;
             else if (quirk.status == Enums.QuirkStatus.Stable && quirk.attributes.quirkiness > 70) quirk.status = Enums.QuirkStatus.Fluctuating;
             else quirk.status = Enums.QuirkStatus.Challenged; // Default change on special outcome

            emit StatusChanged(quirkId, Enums.QuirkStatus.Stable, quirk.status); // Emit specific status change
            return 3; // Status Change
        } else {
            // Outcome: No significant effect
            return 0; // No Effect
        }
    }

    /**
     * @dev Updates a Quirk's status based on its current dynamic attributes.
     * @param quirkId The ID of the Quirk.
     */
    function _updateQuirkStatus(uint256 quirkId) internal {
        Quirk storage quirk = s_quirks[quirkId];
        Enums.QuirkStatus oldStatus = quirk.status;
        Enums.QuirkStatus newStatus = oldStatus; // Default to no change

        // Define status transition logic based on attributes
        if (quirk.attributes.stability > 80 && quirk.attributes.quirkiness < 30) {
            newStatus = Enums.QuirkStatus.Stable;
        } else if (quirk.attributes.quirkiness > 70 && quirk.attributes.stability < 40) {
            newStatus = Enums.QuirkStatus.Fluctuating;
        } else if (quirk.attributes.resonance > 70 && quirk.attributes.complexity > 60) {
            newStatus = Enums.QuirkStatus.Resonating;
        } else if (quirk.attributes.complexity < 30 && quirk.attributes.quirkiness < 30 && quirk.attributes.stability < 30) {
            newStatus = Enums.QuirkStatus.Dormant;
        } else {
            // Revert to stable or maintain if none of the above match clear states
            if (newStatus != Enums.QuirkStatus.Challenged) { // Don't override Challenge status easily
                 newStatus = Enums.QuirkStatus.Stable;
            }
        }

        if (oldStatus != newStatus) {
            quirk.status = newStatus;
            emit StatusChanged(quirkId, oldStatus, newStatus);
        }
    }

    /**
     * @dev Internal function to handle Quirk transfer logic.
     * @param from The sender address.
     * @param to The recipient address.
     * @param quirkId The ID of the Quirk.
     */
    function _transferQuirk(address from, address to, uint256 quirkId) internal {
        if (to == address(0)) revert InvalidAddress(address(0));
        if (s_quirkOwners[quirkId] != from) revert NotQuirkOwner(quirkId);

        // Clear approval for the old Quirk ID
        address approvedAddress = s_quirkApproved[quirkId];
        if (approvedAddress != address(0)) {
            s_quirkApproved[quirkId] = address(0);
            emit Approval(quirkId, from, address(0));
        }

        s_ownerQuirkCount[from]--;
        s_quirkOwners[quirkId] = to;
        s_ownerQuirkCount[to]++;

        emit QuirkTransferred(quirkId, from, to);
    }


    // --- Admin/Management Functions ---

    /**
     * @dev Owner-only function to mint a batch of initial Quirks.
     * @param owners Array of addresses to receive Quirks.
     * @param seeds Array of genetic seeds for the Quirks. Must match owners length.
     */
    function mintInitialQuirks(address[] calldata owners, bytes32[] calldata seeds) external onlyOwner {
        if (owners.length != seeds.length) {
            revert ArrayLengthMismatch("owners and seeds");
        }
        for (uint256 i = 0; i < owners.length; i++) {
            _mintQuirk(owners[i], seeds[i]);
        }
    }

    /**
     * @dev Owner sets the minimum number of blocks that must pass between fluctuation calls for a single Quirk.
     */
    function setFluctuationCooldown(uint256 _cooldownBlocks) external onlyOwner {
        s_fluctuationCooldownBlocks = _cooldownBlocks;
        emit ParamsUpdated("fluctuationCooldownBlocks", _cooldownBlocks);
    }

    /**
     * @dev Owner sets the fee required to attempt a mutation.
     */
    function setMutationFee(uint256 _fee) external onlyOwner {
        s_mutationFee = _fee;
         emit ParamsUpdated("mutationFee", _fee);
    }

    /**
     * @dev Owner sets the fee required to challenge a Quirk's stability.
     */
    function setChallengeFee(uint256 _fee) external onlyOwner {
        s_challengeFee = _fee;
        emit ParamsUpdated("challengeFee", _fee);
    }

    /**
     * @dev Owner sets the fee required to create a Quirk.
     */
    function setCreateFee(uint256 _fee) external onlyOwner {
        s_createFee = _fee;
        emit ParamsUpdated("createFee", _fee);
    }

    /**
     * @dev Owner sets factors determining how much AI and external event hashes influence attributes during fluctuation.
     * @param _aiInfluenceFactor New AI influence factor.
     * @param _externalInfluenceFactor New external event influence factor.
     */
    function setInfluenceParameters(uint256 _aiInfluenceFactor, uint256 _externalInfluenceFactor) external onlyOwner {
        s_aiInfluenceFactor = _aiInfluenceFactor;
        s_externalInfluenceFactor = _externalInfluenceFactor;
        // Emit more specific events if needed
    }

    /**
     * @dev Owner sets the min and max possible values for dynamic attributes.
     *      Arrays must match the number of dynamic attributes.
     * @param mins Array of minimum values.
     * @param maxs Array of maximum values.
     */
    function setQuirkAttributeBounds(uint256[] calldata mins, uint256[] calldata maxs) external onlyOwner {
        // Ensure the arrays match the number of dynamic attributes
        // This requires manual update if QuirkDynamicAttributes struct changes
        uint256 expectedAttributes = 4; // quirkiness, stability, resonance, complexity
        if (mins.length != expectedAttributes || maxs.length != expectedAttributes) {
            revert InvalidAttributeBounds("Arrays must match number of dynamic attributes");
        }
         for (uint256 i = 0; i < expectedAttributes; i++) {
             if (mins[i] > maxs[i]) {
                 revert InvalidAttributeBounds("Min value cannot be greater than max value");
             }
         }

        s_attributeMins = mins;
        s_attributeMaxs = maxs;
        emit BoundsUpdated(mins, maxs);
    }

    /**
     * @dev Owner sets the base magnitude of change during fluctuation.
     */
    function setFluctuationMagnitude(uint256 _magnitude) external onlyOwner {
        s_fluctuationMagnitude = _magnitude;
        emit ParamsUpdated("fluctuationMagnitude", _magnitude);
    }

    /**
     * @dev Owner grants the Oracle role to an address. Oracles can record AI/external influences and trigger batch fluctuations.
     */
    function addOracle(address oracleAddress) external onlyOwner {
        if (oracleAddress == address(0)) revert InvalidAddress(address(0));
        if (!s_oracles[oracleAddress]) {
            s_oracles[oracleAddress] = true;
            s_oracleCount++;
            emit OracleAdded(oracleAddress);
        }
    }

    /**
     * @dev Owner revokes the Oracle role from an address.
     */
    function removeOracle(address oracleAddress) external onlyOwner {
         if (oracleAddress == address(0)) revert InvalidAddress(address(0));
        if (s_oracles[oracleAddress]) {
            s_oracles[oracleAddress] = false;
            s_oracleCount--;
            emit OracleRemoved(oracleAddress);
        }
    }

    /**
     * @dev Owner pauses core user interactions (create, mutate, challenge, single fluctuation).
     */
    function pauseContract() external onlyOwner {
        if (!s_paused) {
            s_paused = true;
            emit PausedContract(msg.sender);
        }
    }

    /**
     * @dev Owner unpauses the contract.
     */
    function unpauseContract() external onlyOwner {
        if (s_paused) {
            s_paused = false;
            emit UnpausedContract(msg.sender);
        }
    }

     /**
     * @dev Owner withdraws the entire contract balance (collected fees).
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success,) = payable(i_owner).call{value: balance}("");
            require(success, "Withdrawal failed");
            emit FeesWithdrawn(i_owner, balance);
        }
    }

    // --- Query Functions ---

    /**
     * @dev Gets all details for a specific Quirk.
     */
    function getQuirkDetails(uint256 quirkId) external view returns (Quirk memory) {
        if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        return s_quirks[quirkId];
    }

    /**
     * @dev Gets the dynamic attributes for a specific Quirk.
     */
    function getQuirkDynamicAttributes(uint256 quirkId) external view returns (QuirkDynamicAttributes memory) {
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        return s_quirks[quirkId].attributes;
    }

    /**
     * @dev Gets the current status of a specific Quirk.
     */
    function getQuirkStatus(uint256 quirkId) external view returns (Enums.QuirkStatus) {
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        return s_quirks[quirkId].status;
    }

    /**
     * @dev Gets the owner of a specific Quirk.
     */
    function getQuirkOwner(uint256 quirkId) public view returns (address) {
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        return s_quirkOwners[quirkId];
    }

    /**
     * @dev Gets the total number of Quirks minted.
     */
    function totalSupply() external view returns (uint256) {
        return s_nextQuirkId;
    }

    /**
     * @dev Gets the configured fluctuation cooldown in blocks.
     */
    function getFluctuationCooldown() external view returns (uint256) {
        return s_fluctuationCooldownBlocks;
    }

    /**
     * @dev Checks if enough blocks have passed for a Quirk to be fluctuated again.
     */
    function canTriggerFluctuation(uint256 quirkId) external view returns (bool) {
         if (s_quirks[quirkId].creationBlock == 0) {
            return false; // Does not exist
        }
        return block.number >= s_quirks[quirkId].lastFluctuationBlock + s_fluctuationCooldownBlocks;
    }

    /**
     * @dev Predicts the deterministic seed hash that *would* be used for fluctuation
     *      at a hypothetical future block number. Does not guarantee state changes.
     * @param quirkId The ID of the Quirk.
     * @param futureBlockNumber The block number to simulate the fluctuation at.
     * @return The deterministic seed hash.
     */
    function predictFluctuationOutcomeHash(uint256 quirkId, uint256 futureBlockNumber) external view returns (bytes32) {
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        // Cannot use blockhash(futureBlockNumber) as it's not available in view function.
        // Instead, we generate a seed based on known future data if possible (like timestamp if block.timestamp was predictable, but it's not).
        // For this simulation, we'll just use the current state and a derivation based on the *future* block number.
        // This is a *prediction* of the seed calculation *formula*, not the *actual* future seed value which depends on future blockhash.
         Quirk storage quirk = s_quirks[quirkId];
         // Simplified prediction seed: combines current state hash with future block number
         return keccak256(abi.encodePacked(
            keccak256(abi.encodePacked(
                quirk.geneticCode,
                quirk.attributes.quirkiness,
                quirk.attributes.stability,
                quirk.attributes.resonance,
                quirk.attributes.complexity
            )),
            futureBlockNumber
        ));
    }

     /**
     * @dev Analyzes the immutable genetic code to derive potential properties or a score.
     *      Example: Summing bytes, checking for patterns.
     * @param quirkId The ID of the Quirk.
     * @return uint256 A derived score based on the genetic code.
     */
    function analyzeGeneticCode(uint256 quirkId) external view returns (uint256) {
        if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        bytes32 geneticCode = s_quirks[quirkId].geneticCode;
        uint256 score = 0;
        // Simple example: sum bytes, maybe check parity
        for(uint256 i = 0; i < 32; i++) {
            score += uint8(geneticCode[i]);
        }
        // More complex logic possible here
        return score;
    }

     /**
     * @dev Calculates a composite "Resonance Score" based on current dynamic attributes.
     * @param quirkId The ID of the Quirk.
     * @return uint256 The calculated resonance score.
     */
    function calculateQuirkResonanceScore(uint256 quirkId) external view returns (uint256) {
        if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        QuirkDynamicAttributes memory attrs = s_quirks[quirkId].attributes;
        // Example score calculation: weighted sum
        uint256 score = (attrs.quirkiness * 2 + attrs.stability * 1 + attrs.resonance * 3 + attrs.complexity * 2) / 8;
        return score;
    }

     /**
     * @dev Gets the last recorded AI insight hash for a specific Quirk.
     */
    function getPendingAIInsightHash(uint256 quirkId) external view returns (bytes32) {
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        return s_quirks[quirkId].lastAIInsightHash;
    }

     /**
     * @dev Checks if an account has the Oracle role.
     */
    function isOracle(address account) external view returns (bool) {
        return s_oracles[account];
    }

    /**
     * @dev Get the creation block of a Quirk.
     */
    function getQuirkCreationBlock(uint256 quirkId) external view returns (uint256) {
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        return s_quirks[quirkId].creationBlock;
    }


    // --- Token/Ownership Functions (Simplified) ---

    /**
     * @dev Transfers ownership of a Quirk.
     * @param to The recipient address.
     * @param quirkId The ID of the Quirk.
     */
    function transferQuirk(address to, uint256 quirkId) external notPaused {
        _transferQuirk(msg.sender, to, quirkId);
    }

    /**
     * @dev Approves an address to transfer a specific Quirk on the owner's behalf.
     * @param approved The address to approve.
     * @param quirkId The ID of the Quirk.
     */
    function approveQuirkTransfer(address approved, uint256 quirkId) external notPaused {
         if (s_quirkOwners[quirkId] != msg.sender) {
            revert NotQuirkOwner(quirkId);
        }
        s_quirkApproved[quirkId] = approved;
        emit Approval(quirkId, msg.sender, approved);
    }

     /**
     * @dev Gets the approved address for a specific Quirk.
     */
    function getApproved(uint256 quirkId) external view returns (address) {
         if (s_quirks[quirkId].creationBlock == 0) {
            revert QuirkDoesNotExist(quirkId);
        }
        return s_quirkApproved[quirkId];
    }

    // Fallback function to receive Ether for fees
    receive() external payable {}
    fallback() external payable {}
}
```