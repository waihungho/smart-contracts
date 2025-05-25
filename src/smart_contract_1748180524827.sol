Okay, let's design a smart contract centered around evolving digital entities with dynamic attributes, procedural generation elements (for visual representation), and complex interaction mechanics. This goes beyond basic NFT creation or DeFi staking.

We'll call it "ChronoGenesis". The core idea is that users mint unique "Essences" that have internal states (energy, stability, affinity) and attributes (`formHash`) that can change over time or through interactions (like "synthesizing" two Essences).

Here's the requested outline and function summary, followed by the Solidity code.

---

**Contract Name:** ChronoGenesis

**Concept:** A smart contract for managing unique, evolving digital entities called "Essences". Essences possess dynamic attributes that change through time-based decay/growth, user-initiated actions (energize, stabilize, trigger mutation), and a synthesis process where two Essences can be combined to potentially create a new one or alter an existing one, influenced by their attributes and a degree of randomness. The contract incorporates aspects of generative art (via `formHash`), state management, and complex interaction logic.

**Key Advanced Concepts:**
*   **Dynamic State:** Essence attributes are not static like traditional NFTs but change based on logic.
*   **Procedural/Generative Element:** A `formHash` is derived deterministically from attributes but intended to represent a basis for off-chain visual/audio generation.
*   **Complex Interactions:** Synthesis logic involves combining attributes and potentially burning/minting tokens.
*   **Time-Based Effects:** Attributes decay/grow requiring an authorized relayer or user interaction to process time delta.
*   **Attribute-Based Logic:** Mutation and Synthesis outcomes are influenced by current attribute values.
*   **Custom Locking Mechanism:** Allows owners to prevent specific interactions on an Essence.

**Outline:**
1.  **Pragma and Imports:** Solidity version and OpenZeppelin libraries (ERC721, Ownable, Pausable, ReentrancyGuard).
2.  **Errors:** Custom errors for better clarity and gas efficiency.
3.  **Events:** Log key actions like minting, mutation, synthesis, state changes.
4.  **Structs:** Define the `EssenceAttributes` structure.
5.  **State Variables:** Storage for Essence data, configuration parameters, counters, authorized addresses.
6.  **Modifiers:** Custom modifiers if needed (e.g., for locked state checks - better handled via errors in functions).
7.  **Constructor:** Initialize ERC721 and set initial state/config.
8.  **ERC721 Overrides:** Implement necessary ERC721 functions, potentially adding checks (e.g., `whenNotPaused`).
9.  **Core Interaction Functions:** `mint`, `synthesize`, `mutate`, `energize`, `stabilize`, `processTimeEffect`.
10. **Query/View Functions:** Get Essence data, configuration, contract state.
11. **Configuration Functions:** `onlyOwner` functions to set contract parameters.
12. **Admin Functions:** `onlyOwner` functions for pausing, withdrawing funds, setting authorized relayer.
13. **Utility Functions:** Internal helpers for attribute calculation, hash generation, etc.

**Function Summary:**

1.  `constructor(string memory name, string memory symbol)`: Initializes the contract, sets ERC721 name/symbol, and default configurations.
2.  `mintGenesisEssence(address recipient, uint256 initialEnergy, uint256 initialStability, uint256 initialAffinity)`: Creates a new, base Essence token and assigns initial attributes.
3.  `synthesizeEssences(uint256 essenceId1, uint256 essenceId2)`: Combines two specified Essences. Burns the input Essences and potentially mints a new one with derived attributes, or significantly alters one of the inputs. Requires payment or resource.
4.  `triggerMutation(uint256 essenceId)`: Attempts to trigger a mutation on an Essence. Success and outcome depend on the Essence's current attributes (like energy, stability) and configuration.
5.  `energizeEssence(uint256 essenceId, uint256 amount)`: Increases the energy level of an Essence. May require payment.
6.  `stabilizeEssence(uint256 essenceId, uint256 amount)`: Increases the stability level of an Essence. May require payment.
7.  `processTimeEffect(uint256 essenceId)`: Allows an authorized relayer (or potentially the owner, or anyone paying a fee) to process time-based decay/growth effects on an Essence's attributes since the last update.
8.  `toggleEssenceLock(uint256 essenceId)`: Allows the owner of an Essence to lock or unlock it, preventing certain interactions like transfer, synthesis, or mutation.
9.  `getEssenceAttributes(uint256 essenceId) view`: Returns the current dynamic attributes of a specific Essence.
10. `getEssenceFormHash(uint256 essenceId) view`: Returns the `formHash` which is derived from the Essence's attributes.
11. `getTotalEssences() view`: Returns the total number of Essences minted (same as `totalSupply`).
12. `getTotalMutationCount() view`: Returns the total number of successful mutations across all Essences.
13. `getSynthesisParameters() view`: Returns current configuration parameters related to synthesis.
14. `getMutationParameters() view`: Returns current configuration parameters related to mutation.
15. `getTimeEffectParameters() view`: Returns current configuration parameters related to time effects.
16. `isEssenceLocked(uint256 essenceId) view`: Checks if a specific Essence is currently locked.
17. `setMutationThreshold(uint256 threshold) onlyOwner`: Sets the energy threshold required for a successful mutation attempt.
18. `setEnergyDecayRate(uint256 rate) onlyOwner`: Sets the rate at which Energy decays over time.
19. `setStabilityDecayRate(uint256 rate) onlyOwner`: Sets the rate at which Stability decays over time.
20. `setAuthorizedRelayer(address relayer) onlyOwner`: Sets the address authorized to call `processTimeEffect`.
21. `setSynthesisCost(uint256 cost) onlyOwner`: Sets the cost (in native token or other resource) for synthesizing Essences.
22. `setFormGenerationSalt(bytes32 salt) onlyOwner`: Sets a salt value used in generating `formHash` to ensure uniqueness even with identical attributes initially.
23. `withdrawFunds() onlyOwner`: Allows the contract owner to withdraw collected funds (e.g., from synthesis costs).
24. `pause() onlyOwner`: Pauses core contract interactions (`whenNotPaused` modifier).
25. `unpause() onlyOwner`: Unpauses the contract.
26. `ownerOf(uint256 essenceId) view`: (Inherited ERC721) Returns the owner of the Essence.
27. `balanceOf(address owner) view`: (Inherited ERC721) Returns the number of Essences owned by an address.
28. `transferFrom(address from, address to, uint256 essenceId) payable`: (Inherited ERC721) Transfers ownership of an Essence (adds locked check).
29. `safeTransferFrom(address from, address to, uint256 essenceId) payable`: (Inherited ERC721) Transfers ownership safely (adds locked check).
30. `safeTransferFrom(address from, address to, uint256 essenceId, bytes memory data) payable`: (Inherited ERC721) Transfers ownership safely with data (adds locked check).
31. `approve(address to, uint256 essenceId)`: (Inherited ERC721) Approves an address to transfer an Essence (adds locked check).
32. `setApprovalForAll(address operator, bool approved)`: (Inherited ERC721) Approves/disapproves an operator for all owner's Essences.
33. `getApproved(uint256 essenceId) view`: (Inherited ERC721) Gets the approved address for an Essence.
34. `isApprovedForAll(address owner, address operator) view`: (Inherited ERC721) Checks if an operator is approved for all of an owner's Essences.

*(Note: Some inherited ERC721 functions like `tokenByIndex`, `tokenOfOwnerByIndex`, `totalSupply` might be included if inheriting `ERC721Enumerable`, but we count the basic ERC721 functions which are sufficient for uniqueness and ownership).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title ChronoGenesis
/// @dev A smart contract for managing unique, evolving digital entities called "Essences".
/// Essences have dynamic attributes that change through time, user interactions, and synthesis.
/// Incorporates procedural elements, state management, and complex interaction logic.
contract ChronoGenesis is ERC721, ERC721Burnable, ERC721Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    /// @dev Custom errors for gas efficiency and clarity.
    error InvalidEssenceId();
    error EssenceLocked(uint256 essenceId);
    error InsufficientEnergy(uint256 essenceId, int64 currentEnergy, int64 requiredEnergy);
    error InsufficientStability(uint256 essenceId, int64 currentStability, int64 requiredStability);
    error NotAuthorizedRelayer();
    error CannotSynthesizeWithSelf();
    error SynthesisRequiresMoreEnergy();
    error NotEnoughFunds(uint256 required, uint256 available);
    error ProcessTimeAlreadyRecent(uint256 essenceId);

    /// @dev Represents the dynamic attributes of an Essence.
    struct EssenceAttributes {
        uint256 genesisTime;       // Timestamp of creation
        uint64 mutationCount;      // Number of successful mutations
        int64 energyLevel;         // Dynamic energy level (can be positive or negative)
        int64 affinity;            // Influences synthesis outcomes
        int64 stability;           // Affects mutation probability and time decay resistance
        bytes32 formHash;          // Deterministic hash for off-chain representation
        bool isLocked;             // Prevents transfers, synthesis inputs, mutations
        uint256 lastProcessedTime; // Timestamp when time effects were last applied
    }

    /// @dev Mapping from token ID to its attributes.
    mapping(uint256 => EssenceAttributes) private _essences;

    /// @dev Counter for unique Essence IDs.
    Counters.Counter private _essenceIds;

    /// @dev Total count of successful mutations across all Essences.
    uint256 private _totalMutationCount;

    /// @dev Address authorized to trigger time effect processing.
    address public authorizedRelayer;

    /// @dev Configuration parameters
    uint256 public mutationThreshold;       // Min energy for mutation attempt
    int64 public energyDecayRatePerSecond;  // Rate at which energy decays
    int64 public stabilityDecayRatePerSecond; // Rate at which stability decays
    uint256 public baseMutationChance;      // Base chance out of 10000 for mutation success
    uint256 public synthesisCost;           // Cost in native token for synthesis
    bytes32 public formGenerationSalt;      // Salt for formHash generation

    /// @dev Time threshold to prevent frequent time processing on the same Essence.
    uint256 public constant TIME_PROCESS_COOLDOWN = 1 minutes;

    /// @dev Events
    event EssenceMinted(uint256 indexed essenceId, address indexed owner, uint256 genesisTime, bytes32 formHash);
    event EssenceSynthesized(uint256 indexed inputId1, uint256 indexed inputId2, uint256 indexed outputId, address indexed owner, bytes32 newFormHash);
    event EssenceMutated(uint256 indexed essenceId, uint64 newMutationCount, bytes32 newFormHash);
    event EssenceEnergized(uint256 indexed essenceId, int64 newEnergyLevel);
    event EssenceStabilized(uint256 indexed essenceId, int64 newStabilityLevel);
    event EssenceStateChanged(uint256 indexed essenceId, int64 newEnergy, int64 newStability, int64 newAffinity, bytes32 newFormHash);
    event EssenceLocked(uint256 indexed essenceId, bool locked);
    event TimeEffectProcessed(uint256 indexed essenceId, uint256 processedTime, int64 energyDelta, int64 stabilityDelta);

    /// @param name The ERC721 name.
    /// @param symbol The ERC721 symbol.
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        // Initial configuration defaults (can be changed by owner)
        mutationThreshold = 100; // Example: requires 100 energy
        energyDecayRatePerSecond = -1; // Example: loses 1 energy per second
        stabilityDecayRatePerSecond = -1; // Example: loses 1 stability per second
        baseMutationChance = 500; // Example: 5% base chance
        synthesisCost = 0.01 ether; // Example: 0.01 ETH
        formGenerationSalt = keccak256("ChronoGenesisInitialSalt"); // Initial random salt
        authorizedRelayer = owner(); // By default, owner is relayer
    }

    /// @dev Helper to retrieve Essence attributes.
    /// @param essenceId The ID of the Essence.
    /// @return The EssenceAttributes struct.
    function _getEssence(uint256 essenceId) internal view returns (EssenceAttributes storage) {
        if (!_exists(essenceId)) {
            revert InvalidEssenceId();
        }
        return _essences[essenceId];
    }

    /// @dev Checks if an essence is locked and reverts if it is.
    /// @param essenceId The ID of the Essence.
    modifier whenNotLocked(uint256 essenceId) {
        if (_getEssence(essenceId).isLocked) {
            revert EssenceLocked(essenceId);
        }
        _;
    }

    /// @dev Internal function to mint a new Essence with initial attributes.
    /// @param recipient The address to mint the Essence to.
    /// @param initialEnergy Initial energy level.
    /// @param initialStability Initial stability level.
    /// @param initialAffinity Initial affinity level.
    /// @return The ID of the newly minted Essence.
    function _mintNewEssence(address recipient, int64 initialEnergy, int64 initialStability, int64 initialAffinity) internal returns (uint256) {
        _essenceIds.increment();
        uint256 newTokenId = _essenceIds.current();
        uint256 currentTime = block.timestamp;

        EssenceAttributes storage newEssence = _essences[newTokenId];
        newEssence.genesisTime = currentTime;
        newEssence.mutationCount = 0;
        newEssence.energyLevel = initialEnergy;
        newEssence.affinity = initialAffinity;
        newEssence.stability = initialStability;
        newEssence.isLocked = false;
        newEssence.lastProcessedTime = currentTime; // Set initial process time

        // Generate form hash based on initial attributes and salt
        newEssence.formHash = _generateFormHash(
            newTokenId,
            newEssence.genesisTime,
            newEssence.mutationCount,
            newEssence.energyLevel,
            newEssence.affinity,
            newEssence.stability
        );

        _safeMint(recipient, newTokenId);

        emit EssenceMinted(newTokenId, recipient, newEssence.genesisTime, newEssence.formHash);
        emit EssenceStateChanged(newTokenId, newEssence.energyLevel, newEssence.stability, newEssence.affinity, newEssence.formHash);

        return newTokenId;
    }

    /// @dev Internal function to apply time-based decay/growth to attributes.
    /// @param essence The EssenceAttributes storage reference.
    /// @param essenceId The ID of the Essence.
    function _applyTimeEffects(EssenceAttributes storage essence, uint256 essenceId) internal {
        uint256 currentTime = block.timestamp;
        uint256 timeDelta = currentTime.sub(essence.lastProcessedTime);

        if (timeDelta == 0) {
             // No time has passed since last process or first mint
             return;
        }

        // Prevent processing effects too frequently if cooldown is set
        if (timeDelta < TIME_PROCESS_COOLDOWN && essence.lastProcessedTime != essence.genesisTime) {
             revert ProcessTimeAlreadyRecent(essenceId);
        }

        int64 energyDelta = energyDecayRatePerSecond.mul(int64(timeDelta));
        int64 stabilityDelta = stabilityDecayRatePerSecond.mul(int64(timeDelta));

        essence.energyLevel += energyDelta;
        essence.stability += stabilityDelta;

        essence.lastProcessedTime = currentTime;

        emit TimeEffectProcessed(essenceId, timeDelta, energyDelta, stabilityDelta);
        emit EssenceStateChanged(essenceId, essence.energyLevel, essence.stability, essence.affinity, essence.formHash);
    }

    /// @dev Internal function to regenerate the form hash based on current attributes.
    /// @param essenceId The ID of the Essence.
    /// @param genesisTime The genesis time.
    /// @param mutationCount The mutation count.
    /// @param energyLevel The current energy level.
    /// @param affinity The current affinity level.
    /// @param stability The current stability level.
    /// @return The newly generated form hash.
    function _generateFormHash(
        uint256 essenceId,
        uint256 genesisTime,
        uint64 mutationCount,
        int64 energyLevel,
        int64 affinity,
        int64 stability
    ) internal view returns (bytes32) {
        // Use keccak256 to create a hash from attributes and a salt.
        // This hash should serve as a seed for off-chain generative processes.
        return keccak256(abi.encodePacked(
            essenceId,
            genesisTime,
            mutationCount,
            energyLevel,
            affinity,
            stability,
            formGenerationSalt // Include the salt for uniqueness across attribute ranges
        ));
    }

    /// @notice Creates a new, base Essence token.
    /// @dev Only callable when the contract is not paused.
    /// @param recipient The address to mint the Essence to.
    /// @param initialEnergy Initial energy level.
    /// @param initialStability Initial stability level.
    /// @param initialAffinity Initial affinity level.
    /// @return The ID of the newly minted Essence.
    function mintGenesisEssence(address recipient, int64 initialEnergy, int64 initialStability, int64 initialAffinity)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        return _mintNewEssence(recipient, initialEnergy, initialStability, initialAffinity);
    }

    /// @notice Combines two Essences to potentially create a new one or alter one, burning inputs.
    /// @dev This function has complex logic for combining attributes and outcomes.
    /// Requires `msg.sender` to own both input Essences.
    /// Requires a synthesis cost payment.
    /// Inputs cannot be the same Essence or be locked.
    /// @param essenceId1 The ID of the first Essence.
    /// @param essenceId2 The ID of the second Essence.
    function synthesizeEssences(uint256 essenceId1, uint256 essenceId2)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        if (essenceId1 == essenceId2) {
            revert CannotSynthesizeWithSelf();
        }

        require(msg.value >= synthesisCost, "Not enough ETH sent for synthesis cost"); // Using native token for cost

        EssenceAttributes storage essence1 = _getEssence(essenceId1);
        EssenceAttributes storage essence2 = _getEssence(essenceId2);

        address owner1 = ownerOf(essenceId1);
        address owner2 = ownerOf(essenceId2);

        if (msg.sender != owner1 || msg.sender != owner2) {
             revert ERC721InsufficientApproval(msg.sender, synthesisCost); // Re-using ERC721 error, or define custom
        }

        whenNotLocked(essenceId1); // Check lock status
        whenNotLocked(essenceId2);

        // Apply time effects before synthesis based on current state
        _applyTimeEffects(essence1, essenceId1);
        _applyTimeEffects(essence2, essenceId2);

        // --- Synthesis Logic (Simplified Example) ---
        // A more advanced version could involve:
        // - Probabilistic outcomes (new essence, mutated input, destruction)
        // - Complex attribute combination formulas
        // - Required minimum energy/stability levels
        // - Different synthesis 'recipes' based on affinity/attributes

        // Basic logic: Burn both, create a new one.
        // Attributes of new essence are average + random element + influence from affinity.

        int64 newEnergy = (essence1.energyLevel + essence2.energyLevel) / 2;
        int64 newStability = (essence1.stability + essence2.stability) / 2;
        int64 newAffinity = (essence1.affinity + essence2.affinity) / 2;

        // Add some variance based on block properties (not truly random, but adds variation)
        uint256 blockEntropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)));
        newEnergy += int64((blockEntropy % 100) - 50); // Add/subtract up to 50
        newStability += int64((blockEntropy % 100) - 50);
        newAffinity += int64((blockEntropy % 100) - 50);

        // Affinity influence example: High affinity boosts stats, low affinity reduces
        if (newAffinity > 50) {
             newEnergy += (newAffinity / 10);
             newStability += (newAffinity / 10);
        } else if (newAffinity < -50) {
             newEnergy -= (newAffinity / -10);
             newStability -= (newAffinity / -10);
        }

        // Burn the input essences
        _burn(essenceId1);
        _burn(essenceId2);

        // Mint the new resulting essence
        uint256 outputId = _mintNewEssence(msg.sender, newEnergy, newStability, newAffinity);

        emit EssenceSynthesized(essenceId1, essenceId2, outputId, msg.sender, _essences[outputId].formHash);
    }

    /// @notice Attempts to trigger a mutation on an Essence.
    /// @dev Outcome depends on the Essence's state and contract configuration.
    /// Requires `msg.sender` to own the Essence.
    /// Requires the Essence to not be locked.
    /// @param essenceId The ID of the Essence to mutate.
    function triggerMutation(uint256 essenceId)
        external
        whenNotPaused
        nonReentrant
    {
        EssenceAttributes storage essence = _getEssence(essenceId);

        if (msg.sender != ownerOf(essenceId)) {
             revert ERC721InsufficientApproval(msg.sender, essenceId); // Re-using ERC721 error
        }

        whenNotLocked(essenceId);

        // Apply time effects before attempting mutation
        _applyTimeEffects(essence, essenceId);

        // Mutation requirements and probability
        if (essence.energyLevel < int64(mutationThreshold)) {
            revert InsufficientEnergy(essenceId, essence.energyLevel, int64(mutationThreshold));
        }

        // Introduce some randomness based on block properties (not cryptographically secure RNG)
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tx.origin, essenceId))) % 10000;

        // Chance of mutation is influenced by stability (higher stability = lower chance)
        uint256 currentMutationChance = baseMutationChance;
        if (essence.stability > 0) {
            // Example: Reduce chance by 1% per 10 stability
             uint256 stabilityReduction = uint256(essence.stability).div(10);
             if (stabilityReduction > currentMutationChance) {
                  stabilityReduction = currentMutationChance; // Don't go below 0 chance
             }
             currentMutationChance = currentMutationChance.sub(stabilityReduction);
        } else if (essence.stability < 0) {
            // Example: Increase chance by 1% per 10 negative stability
             uint256 stabilityIncrease = uint256(essence.stability * -1).div(10);
             currentMutationChance = currentMutationChance.add(stabilityIncrease);
        }

        // Ensure chance is within bounds
        if (currentMutationChance > 10000) currentMutationChance = 10000;


        if (randomness < currentMutationChance) {
            // --- Successful Mutation ---
            essence.mutationCount++;
            _totalMutationCount++;

            // Example attribute change based on mutation: slight random shifts
            int64 energyChange = int64(randomness % 50) - 25; // +/- 25
            int64 stabilityChange = int64(randomness % 50) - 25;
            int64 affinityChange = int64(randomness % 50) - 25;

            essence.energyLevel += energyChange;
            essence.stability += stabilityChange;
            essence.affinity += affinityChange;

            // Drain some energy for the mutation cost
            essence.energyLevel -= int64(mutationThreshold); // Use up the required energy

            // Regenerate form hash after mutation
            essence.formHash = _generateFormHash(
                essenceId,
                essence.genesisTime,
                essence.mutationCount,
                essence.energyLevel,
                essence.affinity,
                essence.stability
            );

            emit EssenceMutated(essenceId, essence.mutationCount, essence.formHash);
            emit EssenceStateChanged(essenceId, essence.energyLevel, essence.stability, essence.affinity, essence.formHash);

        } else {
            // --- Failed Mutation Attempt ---
            // Still costs energy
            essence.energyLevel -= int64(mutationThreshold / 2); // Half cost on failure?

            emit EssenceStateChanged(essenceId, essence.energyLevel, essence.stability, essence.affinity, essence.formHash);
            // No specific event for failed mutation unless desired
        }
    }

    /// @notice Increases the energy level of an Essence.
    /// @dev Requires `msg.sender` to own the Essence.
    /// Requires the Essence to not be locked.
    /// @param essenceId The ID of the Essence.
    /// @param amount The amount of energy to add.
    function energizeEssence(uint256 essenceId, uint256 amount)
        external
        whenNotPaused
        nonReentrant // If payment/resource required, use nonReentrant
    {
        EssenceAttributes storage essence = _getEssence(essenceId);

        if (msg.sender != ownerOf(essenceId)) {
             revert ERC721InsufficientApproval(msg.sender, essenceId);
        }

        whenNotLocked(essenceId);

        // Apply time effects before energizing
        _applyTimeEffects(essence, essenceId);

        // Add energy (careful with potential overflow if using int64 with large uint256 input)
        // Simplification: Direct addition, assume int64 capacity is sufficient or cap it.
        essence.energyLevel += int64(amount); // Cast uint256 to int64

        emit EssenceEnergized(essenceId, essence.energyLevel);
        emit EssenceStateChanged(essenceId, essence.energyLevel, essence.stability, essence.affinity, essence.formHash);
    }

    /// @notice Increases the stability level of an Essence.
    /// @dev Requires `msg.sender` to own the Essence.
    /// Requires the Essence to not be locked.
    /// @param essenceId The ID of the Essence.
    /// @param amount The amount of stability to add.
    function stabilizeEssence(uint256 essenceId, uint256 amount)
        external
        whenNotPaused
        nonReentrant // If payment/resource required, use nonReentrant
    {
        EssenceAttributes storage essence = _getEssence(essenceId);

        if (msg.sender != ownerOf(essenceId)) {
             revert ERC721InsufficientApproval(msg.sender, essenceId);
        }

        whenNotLocked(essenceId);

        // Apply time effects before stabilizing
        _applyTimeEffects(essence, essenceId);

        // Add stability (careful with overflow)
        essence.stability += int64(amount); // Cast uint256 to int64

        emit EssenceStabilized(essenceId, essence.stability);
        emit EssenceStateChanged(essenceId, essence.energyLevel, essence.stability, essence.affinity, essence.formHash);
    }

    /// @notice Processes time-based decay/growth effects for a specific Essence.
    /// @dev Can only be called by the authorized relayer.
    /// Allows updating essence state based on elapsed time.
    /// @param essenceId The ID of the Essence to process.
    function processTimeEffect(uint256 essenceId)
        external
        nonReentrant // Protect against reentrancy if callbacks are added later
    {
        if (msg.sender != authorizedRelayer) {
            revert NotAuthorizedRelayer();
        }

        EssenceAttributes storage essence = _getEssence(essenceId);

        // Apply the time effects
        _applyTimeEffects(essence, essenceId);

        // Note: No event emitted by _applyTimeEffects if timeDelta is 0
        // The EssenceStateChanged event is emitted within _applyTimeEffects if changes occur
    }

    /// @notice Toggles the locked status of an Essence.
    /// @dev When locked, certain actions (like transfer, synthesis input, mutation, energize, stabilize) are blocked.
    /// Requires `msg.sender` to be the owner of the Essence.
    /// @param essenceId The ID of the Essence.
    function toggleEssenceLock(uint256 essenceId)
        external
        nonReentrant // Protect against reentrancy if state changes enable callbacks
    {
        EssenceAttributes storage essence = _getEssence(essenceId);

        if (msg.sender != ownerOf(essenceId)) {
             revert ERC721InsufficientApproval(msg.sender, essenceId);
        }

        essence.isLocked = !essence.isLocked;

        emit EssenceLocked(essenceId, essence.isLocked);
    }


    // --- Query/View Functions ---

    /// @notice Returns the current dynamic attributes of a specific Essence.
    /// @param essenceId The ID of the Essence.
    /// @return EssenceAttributes struct containing all current attributes.
    function getEssenceAttributes(uint256 essenceId)
        public
        view
        returns (EssenceAttributes memory)
    {
        if (!_exists(essenceId)) {
            revert InvalidEssenceId();
        }
        // Note: This returns a memory copy, so the lastProcessedTime might be slightly old.
        // For precise calculations involving time, processTimeEffect should be called first.
        return _essences[essenceId];
    }

    /// @notice Returns the formHash of a specific Essence.
    /// @dev This hash is intended for off-chain generative representation.
    /// @param essenceId The ID of the Essence.
    /// @return The bytes32 formHash.
    function getEssenceFormHash(uint256 essenceId)
        public
        view
        returns (bytes32)
    {
        return getEssenceAttributes(essenceId).formHash; // Uses the function above
    }

    /// @notice Returns the total number of Essences minted.
    /// @return The total supply of Essences.
    function getTotalEssences() public view returns (uint256) {
        return _essenceIds.current();
    }

    /// @notice Returns the total count of successful mutations across all Essences.
    /// @return The total mutation count.
    function getTotalMutationCount() public view returns (uint256) {
        return _totalMutationCount;
    }

    /// @notice Returns current configuration parameters related to synthesis.
    /// @return synthesisCost The cost to synthesize in native token.
    function getSynthesisParameters() public view returns (uint256 synthCost) {
        synthCost = synthesisCost;
    }

     /// @notice Returns current configuration parameters related to mutation.
    /// @return threshold The min energy for mutation.
    /// @return baseChance The base chance (out of 10000).
    function getMutationParameters() public view returns (uint256 threshold, uint256 baseChance) {
        threshold = mutationThreshold;
        baseChance = baseMutationChance;
    }

     /// @notice Returns current configuration parameters related to time effects.
    /// @return energyDecay The rate of energy decay per second.
    /// @return stabilityDecay The rate of stability decay per second.
    /// @return relayer The authorized relayer address.
    function getTimeEffectParameters() public view returns (int64 energyDecay, int64 stabilityDecay, address relayer) {
        energyDecay = energyDecayRatePerSecond;
        stabilityDecay = stabilityDecayRatePerSecond;
        relayer = authorizedRelayer;
    }

    /// @notice Checks if a specific Essence is currently locked.
    /// @param essenceId The ID of the Essence.
    /// @return True if locked, false otherwise.
    function isEssenceLocked(uint256 essenceId) public view returns (bool) {
        if (!_exists(essenceId)) {
            revert InvalidEssenceId();
        }
        return _essences[essenceId].isLocked;
    }


    // --- Configuration Functions (Owner Only) ---

    /// @notice Sets the minimum energy threshold required for a mutation attempt.
    /// @dev Only callable by the contract owner.
    /// @param threshold The new energy threshold.
    function setMutationThreshold(uint256 threshold) external onlyOwner {
        mutationThreshold = threshold;
    }

    /// @notice Sets the rate at which Energy decays per second.
    /// @dev Only callable by the contract owner.
    /// @param rate The new decay rate (can be positive for growth).
    function setEnergyDecayRate(int64 rate) external onlyOwner {
        energyDecayRatePerSecond = rate;
    }

    /// @notice Sets the rate at which Stability decays per second.
    /// @dev Only callable by the contract owner.
    /// @param rate The new decay rate (can be positive for growth).
    function setStabilityDecayRate(int64 rate) external onlyOwner {
        stabilityDecayRatePerSecond = rate;
    }

    /// @notice Sets the address authorized to call `processTimeEffect`.
    /// @dev Only callable by the contract owner.
    /// @param relayer The address of the authorized relayer.
    function setAuthorizedRelayer(address relayer) external onlyOwner {
        authorizedRelayer = relayer;
    }

    /// @notice Sets the cost in native token required to synthesize Essences.
    /// @dev Only callable by the contract owner.
    /// @param cost The new synthesis cost in wei.
    function setSynthesisCost(uint256 cost) external onlyOwner {
        synthesisCost = cost;
    }

    /// @notice Sets the salt used in generating the `formHash`.
    /// @dev Changing the salt will change the formHash for all Essences on subsequent updates/mutations.
    /// Only callable by the contract owner.
    /// @param salt The new bytes32 salt value.
    function setFormGenerationSalt(bytes32 salt) external onlyOwner {
        formGenerationSalt = salt;
    }

    // --- Admin Functions (Owner Only) ---

    /// @notice Allows the contract owner to withdraw collected funds (e.g., from synthesis costs).
    /// @dev Only callable by the contract owner.
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }

    /// @notice Pauses the contract, preventing core interactions.
    /// @dev Only callable by the contract owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    /// @dev Only callable by the contract owner.
    function unpause() external onlyOwner {
        _unpause();
    }


    // --- ERC721 Overrides ---

    /// @dev See {ERC721-_beforeTokenTransfer}.
    /// Added checks for locked status before any transfer.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Pausable)
        whenNotPaused // Inherited from ERC721Pausable
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the token exists (not a burn from 'from' == address(0)) and is locked
        if (from != address(0) && _exists(tokenId) && _essences[tokenId].isLocked) {
             revert EssenceLocked(tokenId);
        }
    }

    // --- Inherited ERC721/Ownable Functions (Public/External) ---
    // These functions are public/external and count towards the function count:
    // ownerOf(uint256 essenceId) view
    // balanceOf(address owner) view
    // transferFrom(address from, address to, uint256 essenceId) payable
    // safeTransferFrom(address from, address to, uint256 essenceId) payable
    // safeTransferFrom(address from, address to, uint256 essenceId, bytes memory data) payable
    // approve(address to, uint256 essenceId)
    // setApprovalForAll(address operator, bool approved)
    // getApproved(uint256 essenceId) view
    // isApprovedForAll(address owner, address operator) view
    // paused() view (from Pausable)
    // owner() view (from Ownable)
    // transferOwnership(address newOwner) (from Ownable)

    // Note: tokenURI is typically implemented for NFT metadata.
    // A simple placeholder is provided.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireOwned(tokenId);
        // This should ideally point to a JSON file describing the token metadata.
        // The JSON file should include the formHash and potentially other attributes
        // or reference an off-chain system that interprets the formHash.
        return string(abi.encodePacked("ipfs://[your-metadata-cid]/", tokenId.toString()));
    }
}
```