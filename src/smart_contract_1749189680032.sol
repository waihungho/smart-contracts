Okay, this sounds like a fun challenge! Let's design a smart contract system that models a collection of dynamic digital entities, "Quanta," whose states are influenced by randomness, interaction, and 'entanglement,' drawing loosely on quantum mechanics analogies but implemented with deterministic blockchain logic.

We'll use Chainlink VRF for controlled randomness, build upon ERC721 for ownership, and add custom state-changing mechanics. We'll aim for uniqueness by combining these elements into a system where token attributes are not static but evolve based on on-chain events.

**Concept:**

The `QuantumFluctuations` contract will manage dynamic NFTs (ERC721 tokens) called "Quanta". Each Quanta has internal attributes representing its "state" (e.g., energy, frequency, spin). This state can exist in "superposition" (multiple potential states) until "observed", at which point it collapses to a single state. State changes ("fluctuations") are triggered by user interaction or internal processes, influenced by verifiable random numbers. Quanta can also be "entangled" in pairs, meaning a fluctuation in one can influence the state of its entangled partner.

**Advanced Concepts Used:**

1.  **Dynamic NFTs:** Token metadata/attributes change over time based on contract logic.
2.  **Verifiable Randomness (Chainlink VRF v2):** Securely obtaining unpredictable, auditable random numbers on-chain to drive state changes.
3.  **State Superposition & Collapse (Analogy):** Modeling a system where internal states are volatile until "observed" (via a specific function call), fixing the state temporarily.
4.  **Quantum Entanglement (Analogy):** Implementing linked state changes between pairs of tokens.
5.  **Complex State Transitions:** State changes are determined by a combination of randomness, current state, interaction history (implicit via function calls), and entanglement.
6.  **On-chain Parameters:** System behavior (e.g., intensity of fluctuations, decay rate) is controlled by parameters manageable by the contract admin.
7.  **Callback Patterns:** Handling asynchronous random word fulfillment from Chainlink VRF.
8.  **Inheritance & Interfaces:** Using ERC721 and VRFConsumerBaseV2 standards.
9.  **Custom Errors:** Providing specific error information.
10. **Dynamic TokenURI:** Generating metadata on the fly based on the current state.

---

**Smart Contract: QuantumFluctuations**

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721, ERC721URIStorage, Ownable, VRFConsumerBaseV2, ReentrancyGuard (optional, good practice), console.log (for testing).
3.  **Custom Errors**
4.  **Events:** For key state changes and actions.
5.  **Structs:**
    *   `QuantaState`: Represents the observed state attributes.
    *   `PotentialState`: Represents attributes of a potential state in superposition.
    *   `FluctuationParameters`: Controls how fluctuations/decay occur.
6.  **State Variables:**
    *   ERC721 token data (`_tokenIds`, mappings from ERC721).
    *   VRF V2 configuration (`s_vrfCoordinator`, `s_keyHash`, `s_subscriptionId`, `s_callbackGasLimit`, `s_requestConfirmations`).
    *   Mappings for Quanta data (`_quantaStates`, `_potentialStates`, `_entangledPair`).
    *   Mapping for VRF request tracking (`s_requestIdToTokenId`).
    *   Token counter (`_nextTokenId`).
    *   Fluctuation Parameters (`_fluctuationParameters`).
    *   Mapping to track last observation time (`_lastObserved`).
    *   Owner (`_owner`).
7.  **Constructor:** Initializes ERC721, VRF Consumer, and sets initial parameters.
8.  **Modifiers:** `onlyOwner` (inherited).
9.  **Functions:**
    *   **ERC721 Required/Helper Functions:** `supportsInterface`, `_baseURI`, `tokenURI`, `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`.
    *   **VRF Consumer Required/Helper Functions:** `rawFulfillRandomWords`, `createSubscription`, `addConsumer`, `removeConsumer`, `requestSubscriptionDetails`, `fundSubscription`, `withdrawFromSubscription`, `getSubscriptionId`.
    *   **Quanta Core Logic:**
        *   `mintQuanta`: Mints a new Quanta token, initializes state and potential states.
        *   `requestFluctuation`: Triggers a randomness request for a single Quanta.
        *   `requestEntangledFluctuation`: Triggers a randomness request affecting both Quanta in an entangled pair.
        *   `observeQuanta`: Collapses superposition, setting the observed state and clearing potential states.
        *   `entangleQuanta`: Forms an entangled pair between two Quanta.
        *   `breakEntanglement`: Breaks an existing entangled pair.
        *   `triggerDecay`: Applies a time-based decay effect to a Quanta's state.
        *   `updateFluctuationParameters`: Allows owner to adjust system parameters.
    *   **View Functions:**
        *   `getQuantaState`: Returns the current observed state of a Quanta.
        *   `getPotentialStates`: Returns the potential states (superposition) of a Quanta.
        *   `getEntangledPartner`: Returns the entangled partner ID (0 if none).
        *   `totalSupply`: Returns the total number of Quanta minted.
        *   `getFluctuationParameters`: Returns the current system parameters.

**Function Summary:**

1.  `constructor()`: Initializes the contract with ERC721 name/symbol, VRF coordinator/keyhash, and initial parameters.
2.  `supportsInterface(bytes4 interfaceId) external view override`: ERC165 standard function.
3.  `_baseURI() internal view override`: Returns the base URI for metadata.
4.  `tokenURI(uint256 tokenId) public view override`: Generates and returns the metadata URI for a given Quanta, reflecting its current observed state.
5.  `balanceOf(address owner) public view override`: Returns the number of Quanta owned by an address.
6.  `ownerOf(uint256 tokenId) public view override`: Returns the owner of a specific Quanta.
7.  `approve(address to, uint256 tokenId) public override`: Approves another address to transfer a specific Quanta.
8.  `getApproved(uint256 tokenId) public view override`: Gets the approved address for a specific Quanta.
9.  `setApprovalForAll(address operator, bool approved) public override`: Sets approval to manage all tokens for an operator.
10. `isApprovedForAll(address owner, address operator) public view override`: Checks if an operator is approved for all tokens of an owner.
11. `transferFrom(address from, address to, uint256 tokenId) public override`: Transfers a Quanta token (basic).
12. `safeTransferFrom(address from, address to, uint256 tokenId) public override`: Transfers a Quanta token safely (checks receiver).
13. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override`: Transfers a Quanta token safely with data.
14. `rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override`: Chainlink VRF callback. Processes random numbers to update Quanta states based on the logic (fluctuation, entanglement effect).
15. `createSubscription() public onlyOwner returns (uint64)`: Owner creates a VRF subscription.
16. `addConsumer(uint64 subId, address consumer) public onlyOwner`: Owner adds a contract consumer to the subscription.
17. `removeConsumer(uint64 subId, address consumer) public onlyOwner`: Owner removes a consumer from the subscription.
18. `requestSubscriptionDetails(uint64 subId) public view onlyOwner returns (uint96 balance, uint64 reqCount, address[] memory consumers)`: Owner views subscription details.
19. `fundSubscription(uint64 subId) public payable onlyOwner`: Owner funds the VRF subscription with LINK or ETH (depends on VRF network config).
20. `withdrawFromSubscription(uint64 subId, address to, uint256 amount) public onlyOwner`: Owner withdraws funds from the subscription.
21. `getSubscriptionId() public view returns (uint64)`: Returns the active VRF subscription ID.
22. `mintQuanta() public returns (uint256)`: Mints a new Quanta token to the caller, initializing its state and superposition.
23. `requestFluctuation(uint256 tokenId) public`: Allows the owner of a Quanta to request a state fluctuation, triggering a VRF request.
24. `requestEntangledFluctuation(uint256 tokenId) public`: Allows the owner of a Quanta to trigger a fluctuation that affects both the target token and its entangled partner.
25. `observeQuanta(uint256 tokenId) public`: Collapses the superposition of a Quanta, finalizing its observed state and clearing potential states.
26. `entangleQuanta(uint256 tokenId1, uint256 tokenId2) public`: Entangles two Quanta tokens. Requires ownership or approval for both.
27. `breakEntanglement(uint256 tokenId) public`: Breaks the entanglement of the specified Quanta and its partner. Requires ownership or approval.
28. `triggerDecay(uint256 tokenId) public`: Applies a decay effect to a Quanta's state based on the time elapsed since its last observation. Callable by anyone (gas permitting) to encourage state change.
29. `updateFluctuationParameters(FluctuationParameters memory params) public onlyOwner`: Updates the system parameters controlling fluctuations and decay.
30. `getQuantaState(uint256 tokenId) public view returns (QuantaState memory)`: Returns the current observed state attributes of a Quanta.
31. `getPotentialStates(uint256 tokenId) public view returns (PotentialState[] memory)`: Returns the potential states of a Quanta if it's in superposition.
32. `getEntangledPartner(uint256 tokenId) public view returns (uint256)`: Returns the token ID of the Quanta's entangled partner, or 0 if not entangled.
33. `totalSupply() public view returns (uint256)`: Returns the total number of Quanta tokens minted.
34. `getFluctuationParameters() public view returns (FluctuationParameters memory)`: Returns the current system fluctuation parameters.

*(Note: The actual implementation of state update logic within `rawFulfillRandomWords` will be a simplified deterministic process based on the random words, parameters, and current state. The "quantum" nature is the analogy for the *behavior* - unpredictable (due to randomness), state-dependent, and linked - not a literal simulation of quantum mechanics on-chain.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice if payable functions were more complex

// Uncomment the line below for testing on a local development network
// import "hardhat/console.sol";

/**
 * @title QuantumFluctuations
 * @dev A dynamic NFT contract where token states ("Quanta") are influenced
 * by randomness, interaction, superposition, entanglement, and decay,
 * drawing loose analogies from quantum mechanics. Utilizes Chainlink VRF v2
 * for verifiable randomness.
 */
contract QuantumFluctuations is ERC721URIStorage, VRFConsumerBaseV2, Ownable {

    // --- Custom Errors ---
    error QuantumFluctuations__TokenDoesNotExist(uint256 tokenId);
    error QuantumFluctuations__NotQuantaOwnerOrApproved(uint256 tokenId);
    error QuantumFluctuations__AlreadyEntangled(uint256 tokenId);
    error QuantumFluctuations__NotEntangled(uint256 tokenId);
    error QuantumFluctuations__TokensCannotBeSame();
    error QuantumFluctuations__CannotRequestFluctuationForSelf();
    error QuantumFluctuations__VRFRequestFailed(uint256 requestId);
    error QuantumFluctuations__InsufficientPotentialStates(uint256 tokenId);
    error QuantumFluctuations__InvalidParameter(string paramName, uint256 value);
    error QuantumFluctuations__SubscriptionNotSet();
    error QuantumFluctuations__PotentialStateLimitExceeded(uint256 tokenId, uint256 limit);

    // --- Events ---
    event QuantaMinted(uint256 indexed tokenId, address indexed owner);
    event FluctuationRequested(uint256 indexed tokenId, uint256 indexed requestId);
    event StateObserved(uint256 indexed tokenId, address indexed observer, QuantaState newState);
    event QuantaEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event StateFluctuated(uint256 indexed tokenId, QuantaState newState);
    event DecayTriggered(uint256 indexed tokenId, QuantaState newState);
    event ParametersUpdated(FluctuationParameters newParams);
    event VRFSubscriptionCreated(uint64 indexed subId);
    event VRFConsumerAdded(uint64 indexed subId, address indexed consumer);

    // --- Structs ---

    /// @dev Represents the observed state attributes of a Quanta.
    struct QuantaState {
        uint16 energy;     // Represents intensity (e.g., 0-1000)
        uint16 frequency;  // Represents speed/vibration (e.g., 0-1000)
        uint8 spin;       // Represents orientation (e.g., 0-3, like 0, 90, 180, 270 degrees)
        uint8 color_phase; // Represents visual aspect (e.g., 0-255 for hue)
    }

    /// @dev Represents a potential state in superposition.
    struct PotentialState {
         uint16 energy;
        uint16 frequency;
        uint8 spin;
        uint8 color_phase;
    }

    /// @dev Parameters controlling state changes and decay.
    struct FluctuationParameters {
        uint16 maxEnergy;          // Max value for energy/frequency
        uint8 maxSpin;             // Max value for spin (e.g., 3 for 0-3)
        uint8 maxColorPhase;       // Max value for color_phase (e.g., 255)
        uint16 fluctuationIntensity; // How much attributes can change per fluctuation (percentage of max)
        uint16 decayRate;          // Percentage decrease per decay period
        uint64 decayPeriod;        // Time in seconds for one decay step
        uint8 maxPotentialStates;  // Maximum number of potential states allowed
    }

    // --- State Variables ---

    // ERC721 token counter
    uint256 private _nextTokenId;

    // VRF V2 variables
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    bytes32 immutable i_keyHash;
    uint64 s_subscriptionId;
    uint32 immutable i_callbackGasLimit;
    uint16 immutable i_requestConfirmations;
    uint32 constant NUM_WORDS = 2; // Request 2 random numbers per fluctuation

    // Mapping from VRF request ID to the token ID it affects
    mapping(uint256 => uint256) public s_requestIdToTokenId;

    // Quanta state data
    mapping(uint256 => QuantaState) private _quantaStates;
    mapping(uint256 => PotentialState[]) private _potentialStates; // Array of potential states
    mapping(uint256 => uint256) private _entangledPair; // 0 if not entangled, token ID of partner if entangled

    // System parameters
    FluctuationParameters private _fluctuationParameters;

    // Mapping to track the last time a Quanta was observed
    mapping(uint256 => uint64) private _lastObserved;

    // --- Constructor ---

    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint16 requestConfirmations
    ) ERC721("QuantumQuanta", "QQ") VRFConsumerBaseV2(vrfCoordinator) Ownable(msg.sender) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = requestConfirmations;

        // Set initial default fluctuation parameters
        _fluctuationParameters = FluctuationParameters({
            maxEnergy: 1000,
            maxFrequency: 1000,
            maxSpin: 3,          // 0, 1, 2, 3
            maxColorPhase: 255, // 0-255
            fluctuationIntensity: 50, // 5% change max per fluctuation
            decayRate: 100,      // 10% decay per period
            decayPeriod: 86400,  // 1 day in seconds
            maxPotentialStates: 5 // Max 5 potential states
        });

        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- ERC721 Required/Helper Functions ---

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(ERC721URIStorage).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /// @dev ERC721URIStorage base URI (can be empty if tokenURI is fully dynamic)
    function _baseURI() internal view override returns (string memory) {
        return ""; // Fully dynamic tokenURI
    }

    /// @inheritdoc ERC721URIStorage
    /// @dev Generates a dynamic token URI based on the current observed state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
             revert ERC721NonexistentToken(tokenId);
        }

        QuantaState memory currentState = _quantaStates[tokenId];
        address currentOwner = ownerOf(tokenId);
        uint256 entangledPartnerId = _entangledPair[tokenId];

        // Build JSON metadata string
        string memory json = string(abi.encodePacked(
            '{"name": "Quantum Quanta #', toString(tokenId),
            '", "description": "A dynamic digital entity whose state fluctuates.",',
            '"owner": "', Strings.toHexString(uint160(currentOwner), 20), '",',
            '"attributes": [',
            '{"trait_type": "Energy", "value": ', toString(currentState.energy), '},',
            '{"trait_type": "Frequency", "value": ', toString(currentState.frequency), '},',
            '{"trait_type": "Spin", "value": ', toString(currentState.spin), '},',
            '{"trait_type": "Color Phase", "value": ', toString(currentState.color_phase), '},',
            '{"trait_type": "Entangled", "value": ', (entangledPartnerId != 0 ? "true" : "false"), '}'
        ));

        if (entangledPartnerId != 0) {
             json = string(abi.encodePacked(json, ', {"trait_type": "Entangled Partner", "value": ', toString(entangledPartnerId), '}'));
        }

        if (_potentialStates[tokenId].length > 0) {
             json = string(abi.encodePacked(json, ', {"trait_type": "Superposition", "value": "true"}'));
             json = string(abi.encodePacked(json, ', {"trait_type": "Potential States Count", "value": ', toString(_potentialStates[tokenId].length), '}'));
        } else {
             json = string(abi.encodePacked(json, ', {"trait_type": "Superposition", "value": "false"}'));
        }

         json = string(abi.encodePacked(json, ']}'));

        // Prepend data URL scheme
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // ERC721 standard functions inherited and publicly available:
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll
    // transferFrom, safeTransferFrom (both overloads)
    // These contribute to the 20+ function count.

    // --- VRF Consumer Required/Helper Functions ---

    /// @inheritdoc VRFConsumerBaseV2
    /// @dev Callback function used by VRF Coordinator to return random words.
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 tokenId = s_requestIdToTokenId[requestId];
        if (tokenId == 0 || !_exists(tokenId)) {
            // Should not happen if request mapping is managed correctly,
            // but good safety check. Or handle specific VRF error.
            revert QuantumFluctuations__VRFRequestFailed(requestId);
        }

        delete s_requestIdToTokenId[requestId]; // Clear request mapping

        // --- State Update Logic based on Randomness ---

        // Use randomWords[0] for general fluctuation
        // Use randomWords[1] for selecting potential state or entangled effect

        QuantaState storage currentState = _quantaStates[tokenId];
        PotentialState[] storage potentialStates = _potentialStates[tokenId];
        FluctuationParameters memory params = _fluctuationParameters;

        uint256 randomness1 = randomWords[0];
        uint256 randomness2 = randomWords[1];

        // 1. Handle Superposition Collapse/Selection (if in superposition)
        if (potentialStates.length > 0) {
            uint256 selectedIndex = randomness2 % potentialStates.length;
            currentState.energy = potentialStates[selectedIndex].energy;
            currentState.frequency = potentialStates[selectedIndex].frequency;
            currentState.spin = potentialStates[selectedIndex].spin;
            currentState.color_phase = potentialStates[selectedIndex].color_phase;

            // Clear potential states after collapse via randomness
            delete potentialStates;
            emit StateObserved(tokenId, address(this), currentState); // Contract acts as observer
        }

        // 2. Apply General Fluctuation
        // Calculate max change based on intensity
        uint16 energyChange = uint16((uint256(params.maxEnergy) * params.fluctuationIntensity) / 1000); // fluctuationIntensity is parts per thousand
        uint16 freqChange = uint16((uint256(params.maxFrequency) * params.fluctuationIntensity) / 1000);
        uint8 spinChange = uint8((uint256(params.maxSpin) * params.fluctuationIntensity) / 1000);
        uint8 colorChange = uint8((uint256(params.maxColorPhase) * params.fluctuationIntensity) / 1000);


        // Apply changes pseudo-randomly (add or subtract)
        // Energy:
        if (randomness1 % 2 == 0) currentState.energy = uint16(Math.min(uint256(currentState.energy) + (randomness1 % energyChange), params.maxEnergy));
        else currentState.energy = uint16(Math.max(int256(currentState.energy) - int256(randomness1 % energyChange), 0));

        // Frequency:
        if ((randomness1 / 2) % 2 == 0) currentState.frequency = uint16(Math.min(uint256(currentState.frequency) + ((randomness1 / 2) % freqChange), params.maxFrequency));
        else currentState.frequency = uint16(Math.max(int256(currentState.frequency) - int256(((randomness1 / 2) % freqChange)), 0));

        // Spin (discrete values, rotate)
        uint8 spinDelta = (randomness1 / 4) % (spinChange + 1); // Add up to spinChange
        if ((randomness1 / 8) % 2 == 0) currentState.spin = (currentState.spin + spinDelta) % (params.maxSpin + 1);
        else currentState.spin = (currentState.spin - spinDelta + (params.maxSpin + 1)) % (params.maxSpin + 1); // handle wrap around negative

        // Color Phase
        uint8 colorDelta = (randomness1 / 16) % (colorChange + 1);
        if ((randomness1 / 32) % 2 == 0) currentState.color_phase = uint8(Math.min(uint256(currentState.color_phase) + colorDelta, params.maxColorPhase));
        else currentState.color_phase = uint8(Math.max(int256(currentState.color_phase) - colorDelta, 0));

        // Ensure spin stays within bounds [0, maxSpin] (already handled by modulo, but belt & suspenders)
        currentState.spin = currentState.spin % (params.maxSpin + 1);
         currentState.color_phase = uint8(Math.min(uint256(currentState.color_phase), params.maxColorPhase));

        emit StateFluctuated(tokenId, currentState);

        // 3. Handle Entanglement Effect (if entangled)
        uint256 entangledPartnerId = _entangledPair[tokenId];
        if (entangledPartnerId != 0 && _exists(entangledPartnerId)) {
             // Apply a correlated fluctuation to the partner using the *same* randomness
             // This creates the "entangled" effect - their changes are linked.
             // The logic here is simplified: apply similar changes to the partner.
             QuantaState storage partnerState = _quantaStates[entangledPartnerId];

             // Example correlated change: add/subtract same amount as the primary token,
             // but maybe invert the direction or scale slightly differently based on randomness2
             uint256 correlationFactor = randomness2 % 100; // 0-99

             // Apply changes to partner based on randomness1 and correlationFactor
             // Energy:
             uint16 partnerEnergyChange = uint16((uint256(energyChange) * correlationFactor) / 100);
             if (randomness1 % 2 == 0) partnerState.energy = uint16(Math.min(uint256(partnerState.energy) + partnerEnergyChange, params.maxEnergy));
             else partnerState.energy = uint16(Math.max(int256(partnerState.energy) - int256(partnerEnergyChange), 0));

             // Frequency:
             uint16 partnerFreqChange = uint16((uint256(freqChange) * correlationFactor) / 100);
             if ((randomness1 / 2) % 2 == 0) partnerState.frequency = uint16(Math.min(uint256(partnerState.frequency) + partnerFreqChange, params.maxFrequency));
             else partnerState.frequency = uint16(Math.max(int256(partnerState.frequency) - int256(partnerFreqChange), 0));

             // Spin (discrete values, rotate)
             uint8 partnerSpinDelta = uint8((uint256(spinDelta) * correlationFactor) / 100);
              if ((randomness1 / 8) % 2 == 0) partnerState.spin = (partnerState.spin + partnerSpinDelta) % (params.maxSpin + 1);
              else partnerState.spin = (partnerState.spin - partnerSpinDelta + (params.maxSpin + 1)) % (params.maxSpin + 1);

             // Color Phase
             uint8 partnerColorDelta = uint8((uint256(colorDelta) * correlationFactor) / 100);
              if ((randomness1 / 32) % 2 == 0) partnerState.color_phase = uint8(Math.min(uint256(partnerState.color_phase) + partnerColorDelta, params.maxColorPhase));
              else partnerState.color_phase = uint8(Math.max(int256(partnerState.color_phase) - int256(partnerColorDelta), 0));

             // Ensure spin stays within bounds
             partnerState.spin = partnerState.spin % (params.maxSpin + 1);
             partnerState.color_phase = uint8(Math.min(uint256(partnerState.color_phase), params.maxColorPhase));

             emit StateFluctuated(entangledPartnerId, partnerState);

             // Note: This logic is simplified. More complex entanglement could involve
             // state correlations (e.g., if token A spin is X, token B spin tends towards Y),
             // or even shared potential states.
        }

        // 4. Potentially generate new potential states (simple example: add one new random potential state)
        if (potentialStates.length < params.maxPotentialStates) {
            potentialStates.push(PotentialState({
                 energy: uint16(randomWords[0] % (params.maxEnergy + 1)),
                frequency: uint16(randomWords[1] % (params.maxFrequency + 1)),
                 spin: uint8((randomWords[0] / 100) % (params.maxSpin + 1)),
                 color_phase: uint8((randomWords[1] / 100) % (params.maxColorPhase + 1))
            }));
        }
    }

    // --- VRF Subscription Management Functions ---

    /// @notice Allows the owner to create a new VRF Subscription.
    /// @dev Needs to be funded separately.
    function createSubscription() public onlyOwner returns (uint64) {
        s_subscriptionId = i_vrfCoordinator.createSubscription();
        emit VRFSubscriptionCreated(s_subscriptionId);
        return s_subscriptionId;
    }

    /// @notice Allows the owner to add a consumer to the subscription.
    /// @param subId The subscription ID.
    /// @param consumer Address of the consumer contract.
    function addConsumer(uint64 subId, address consumer) public onlyOwner {
        require(subId == s_subscriptionId, "Invalid subscription ID"); // Ensure using active sub
        i_vrfCoordinator.addConsumer(subId, consumer);
        emit VRFConsumerAdded(subId, consumer);
    }

    /// @notice Allows the owner to remove a consumer from the subscription.
    /// @param subId The subscription ID.
    /// @param consumer Address of the consumer contract.
    function removeConsumer(uint64 subId, address consumer) public onlyOwner {
         require(subId == s_subscriptionId, "Invalid subscription ID"); // Ensure using active sub
        // require(consumer != address(this), "Cannot remove self"); // Prevent accidental self-removal
        i_vrfCoordinator.removeConsumer(subId, consumer);
    }

     /// @notice Allows the owner to request details about the subscription.
     /// @param subId The subscription ID.
    function requestSubscriptionDetails(uint64 subId) public view onlyOwner
        returns (uint96 balance, uint64 reqCount, address[] memory consumers)
    {
         require(subId == s_subscriptionId, "Invalid subscription ID"); // Ensure using active sub
        (balance, reqCount, consumers) = i_vrfCoordinator.getSubscription(subId);
    }

    /// @notice Allows the owner to fund the VRF subscription.
    /// @param subId The subscription ID.
    /// @dev Accepts ETH which will be transferred to the VRF Coordinator.
    /// Assumes VRF Coordinator accepts native currency.
    function fundSubscription(uint64 subId) public payable onlyOwner {
        require(subId == s_subscriptionId, "Invalid subscription ID"); // Ensure using active sub
        i_vrfCoordinator.fundSubscription{value: msg.value}(subId);
    }

    /// @notice Allows the owner to withdraw remaining funds from the subscription.
    /// @param subId The subscription ID.
    /// @param to Address to send the funds to.
    /// @param amount Amount to withdraw.
    function withdrawFromSubscription(uint64 subId, address to, uint256 amount) public onlyOwner {
        require(subId == s_subscriptionId, "Invalid subscription ID"); // Ensure using active sub
        i_vrfCoordinator.withdrawSubscription(subId, to, amount);
    }

    /// @notice Returns the currently active VRF subscription ID.
    function getSubscriptionId() public view returns (uint64) {
        return s_subscriptionId;
    }

    // --- Quanta Core Logic ---

    /// @notice Mints a new Quanta token.
    /// @return The ID of the newly minted token.
    function mintQuanta() public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        // Initialize state (could be random or fixed)
        _quantaStates[tokenId] = QuantaState({
            energy: 100,
            frequency: 100,
            spin: 0,
            color_phase: 0
        });

        // Initialize potential states (a few random ones)
        FluctuationParameters memory params = _fluctuationParameters;
         // Note: Initial potential states here are simple, non-random.
         // In a real deployment, you might want an initial VRF request for this,
         // or generate them off-chain and pass hashes, or use minimal on-chain pseudo-randomness.
        _potentialStates[tokenId].push(PotentialState({energy: 120, frequency: 90, spin: 1, color_phase: 50}));
        _potentialStates[tokenId].push(PotentialState({energy: 80, frequency: 110, spin: 2, color_phase: 200}));


        // Initialize last observed time
        _lastObserved[tokenId] = uint64(block.timestamp);

        emit QuantaMinted(tokenId, msg.sender);
        return tokenId;
    }

    /// @notice Requests a fluctuation for a single Quanta, updating its state based on randomness.
    /// @dev Only the owner or approved address can trigger this.
    /// @param tokenId The ID of the Quanta.
    function requestFluctuation(uint256 tokenId) public {
        if (!_exists(tokenId)) revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
             revert QuantumFluctuations__NotQuantaOwnerOrApproved(tokenId);
        }
        if (s_subscriptionId == 0) revert QuantumFluctuations__SubscriptionNotSet();

        // Request randomness
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            s_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToTokenId[requestId] = tokenId; // Map request to token

        emit FluctuationRequested(tokenId, requestId);
    }

     /// @notice Requests a fluctuation that affects both Quanta in an entangled pair.
     /// @dev Callable by the owner or approved address of *either* token in the pair.
     /// Uses a single VRF request but applies logic to both in the callback.
     /// @param tokenId The ID of one Quanta in the entangled pair.
    function requestEntangledFluctuation(uint256 tokenId) public {
        if (!_exists(tokenId)) revert QuantumFluctuations__TokenDoesNotExist(tokenId);
         uint256 partnerId = _entangledPair[tokenId];
         if (partnerId == 0) revert QuantumFluctuations__NotEntangled(tokenId);

        // Check if caller owns or is approved for *either* token
        bool isOwnerOrApproved = (ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender)) ||
                                 (ownerOf(partnerId) == msg.sender || isApprovedForAll(ownerOf(partnerId), msg.sender));
        if (!isOwnerOrApproved) {
             revert QuantumFluctuations__NotQuantaOwnerOrApproved(tokenId); // Revert with one ID is sufficient
        }
        if (s_subscriptionId == 0) revert QuantumFluctuations__SubscriptionNotSet();

        // Request randomness - this request ID will be associated with the primary tokenId,
        // and the callback logic knows to update the partner too.
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            s_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            NUM_WORDS // Need enough randomness for potential state selection AND state updates for two tokens
        );

        s_requestIdToTokenId[requestId] = tokenId; // Map request to the primary token

        emit FluctuationRequested(tokenId, requestId);
        // Could emit another event indicating entangled fluctuation started
    }


    /// @notice Collapses the superposition of a Quanta, finalizing its observed state.
    /// @dev Sets the current observed state as the only potential state and clears the rest.
    /// Can be called by the owner or approved address.
    /// @param tokenId The ID of the Quanta.
    function observeQuanta(uint256 tokenId) public {
        if (!_exists(tokenId)) revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
             revert QuantumFluctuations__NotQuantaOwnerOrApproved(tokenId);
        }

        // Set observed state from potential states (using the first one as the "default" collapse)
        // Or, simply use the current _quantaStates value and clear potential states.
        // Let's use the latter for simplicity: Observation fixes the *current* state.
        PotentialState[] storage potentialStates = _potentialStates[tokenId];

        // Clear potential states
        delete potentialStates;

        // Update last observed time
        _lastObserved[tokenId] = uint64(block.timestamp);

        emit StateObserved(tokenId, msg.sender, _quantaStates[tokenId]);
    }


    /// @notice Entangles two Quanta tokens.
    /// @dev Requires ownership or approval for *both* tokens. Tokens cannot be the same.
    /// Neither token can already be entangled.
    /// @param tokenId1 The ID of the first Quanta.
    /// @param tokenId2 The ID of the second Quanta.
    function entangleQuanta(uint256 tokenId1, uint256 tokenId2) public {
        if (!_exists(tokenId1)) revert QuantumFluctuations__TokenDoesNotExist(tokenId1);
        if (!_exists(tokenId2)) revert QuantumFluctuations__TokenDoesNotExist(tokenId2);
        if (tokenId1 == tokenId2) revert QuantumFluctuations__TokensCannotBeSame();

        // Check ownership/approval for token 1
         if (ownerOf(tokenId1) != msg.sender && !isApprovedForAll(ownerOf(tokenId1), msg.sender)) {
             revert QuantumFluctuations__NotQuantaOwnerOrApproved(tokenId1);
         }
        // Check ownership/approval for token 2
        if (ownerOf(tokenId2) != msg.sender && !isApprovedForAll(ownerOf(tokenId2), msg.sender)) {
             revert QuantumFluctuations__NotQuantaOwnerOrApproved(tokenId2);
        }

        if (_entangledPair[tokenId1] != 0) revert QuantumFluctuations__AlreadyEntangled(tokenId1);
        if (_entangledPair[tokenId2] != 0) revert QuantumFluctuations__AlreadyEntangled(tokenId2);

        _entangledPair[tokenId1] = tokenId2;
        _entangledPair[tokenId2] = tokenId1;

        emit QuantaEntangled(tokenId1, tokenId2);
    }

    /// @notice Breaks the entanglement of a Quanta and its partner.
    /// @dev Requires ownership or approval for the token.
    /// @param tokenId The ID of the Quanta.
    function breakEntanglement(uint256 tokenId) public {
         if (!_exists(tokenId)) revert QuantumFluctuations__TokenDoesNotExist(tokenId);
         if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
             revert QuantumFluctuations__NotQuantaOwnerOrApproved(tokenId);
        }

        uint256 partnerId = _entangledPair[tokenId];
        if (partnerId == 0) revert QuantumFluctuations__NotEntangled(tokenId);
        if (!_exists(partnerId) || _entangledPair[partnerId] != tokenId) {
             // Safety check: Ensure the partner mapping is consistent
            delete _entangledPair[tokenId];
            if (_exists(partnerId)) delete _entangledPair[partnerId];
            revert QuantumFluctuations__NotEntangled(tokenId); // Revert even if cleared
        }


        delete _entangledPair[tokenId];
        delete _entangledPair[partnerId];

        emit EntanglementBroken(tokenId, partnerId);
    }

    /// @notice Applies a time-based decay effect to a Quanta's state.
    /// @dev State attributes decrease over time since the last observation/interaction.
    /// Can be called by anyone, encouraging users to interact.
    /// @param tokenId The ID of the Quanta.
    function triggerDecay(uint256 tokenId) public {
        if (!_exists(tokenId)) revert QuantumFluctuations__TokenDoesNotExist(tokenId);

        uint64 lastObservedTime = _lastObserved[tokenId];
        FluctuationParameters memory params = _fluctuationParameters;

        if (params.decayPeriod == 0) {
             // Decay is disabled if period is 0
             return;
        }

        uint64 timeElapsed = uint64(block.timestamp) - lastObservedTime;
        uint256 decaySteps = timeElapsed / params.decayPeriod;

        if (decaySteps == 0) {
            // Not enough time has passed for decay
            return;
        }

        // Limit decay steps to prevent overflow and excessive state degradation
        // E.g., max decay for 1 year (365 days)
        uint256 maxPossibleDecaySteps = (365 * 86400) / params.decayPeriod;
        decaySteps = Math.min(decaySteps, maxPossibleDecaySteps);

        QuantaState storage currentState = _quantaStates[tokenId];

        // Apply decay to attributes (percentage based)
        uint256 decayFactor = params.decayRate; // This is percentage * 10
                                                // e.g. 100 means 10% per step
        uint256 decayMultiplier = 10000 - (decayFactor * decaySteps); // Example: 10000 - (100 * 5 steps) = 9500
        if (decayMultiplier < 0) decayMultiplier = 0; // Cannot have negative decay factor

        // Decay calculation: current = current * decayMultiplier / 10000 (assuming decayFactor is in 0-1000 range)
        // Example: energy 1000, decayFactor 100 (10%), 5 steps -> 1000 * (10000 - 500) / 10000 = 1000 * 9500 / 10000 = 950

        currentState.energy = uint16((uint256(currentState.energy) * decayMultiplier) / 10000);
        currentState.frequency = uint16((uint256(currentState.frequency) * decayMultiplier) / 10000);
        // Spin and ColorPhase decay might be different (e.g., trend towards a default)
        // For simplicity, apply proportional decay like energy/frequency
         currentState.spin = uint8((uint256(currentState.spin) * decayMultiplier) / 10000);
        currentState.color_phase = uint8((uint256(currentState.color_phase) * decayMultiplier) / 10000);

        // Reset last observed time *to the start of the decay period calculated*
        // This prevents triggering decay multiple times for the same period
        _lastObserved[tokenId] += uint64(decaySteps * params.decayPeriod);


        emit DecayTriggered(tokenId, currentState);
    }

    /// @notice Allows the owner to update the system parameters for fluctuations and decay.
    /// @param params The new FluctuationParameters struct.
    function updateFluctuationParameters(FluctuationParameters memory params) public onlyOwner {
        // Add validation for parameters if necessary (e.g., decayRate < 1000, fluctuationIntensity < 1000)
        if (params.fluctuationIntensity > 1000) revert QuantumFluctuations__InvalidParameter("fluctuationIntensity", params.fluctuationIntensity);
        if (params.decayRate > 1000) revert QuantumFluctuations__InvalidParameter("decayRate", params.decayRate);
         if (params.maxSpin > 255) revert QuantumFluctuations__InvalidParameter("maxSpin", params.maxSpin); // Max uint8 value
        if (params.maxColorPhase > 255) revert QuantumFluctuations__InvalidParameter("maxColorPhase", params.maxColorPhase); // Max uint8 value
         if (params.maxPotentialStates > 10) revert QuantumFluctuations__InvalidParameter("maxPotentialStates", params.maxPotentialStates); // Arbitrary limit for gas

        _fluctuationParameters = params;
        emit ParametersUpdated(params);
    }


    // --- View Functions ---

    /// @notice Returns the current observed state of a Quanta.
    /// @param tokenId The ID of the Quanta.
    /// @return A memory struct representing the Quanta's state.
    function getQuantaState(uint256 tokenId) public view returns (QuantaState memory) {
        if (!_exists(tokenId)) revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        return _quantaStates[tokenId];
    }

     /// @notice Returns the potential states (superposition) of a Quanta.
     /// @param tokenId The ID of the Quanta.
     /// @return An array of potential state structs. Empty if not in superposition.
    function getPotentialStates(uint256 tokenId) public view returns (PotentialState[] memory) {
         if (!_exists(tokenId)) revert QuantumFluctuations__TokenDoesNotExist(tokenId);
         return _potentialStates[tokenId];
    }

    /// @notice Returns the token ID of the Quanta's entangled partner.
    /// @param tokenId The ID of the Quanta.
    /// @return The partner's token ID, or 0 if not entangled.
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) return 0; // Or revert, depending on desired behavior for non-existent
        return _entangledPair[tokenId];
    }

    /// @notice Returns the total number of Quanta tokens minted.
    /// @return The total supply.
    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    /// @notice Returns the current fluctuation and decay parameters.
    /// @return The FluctuationParameters struct.
    function getFluctuationParameters() public view returns (FluctuationParameters memory) {
        return _fluctuationParameters;
    }

    // Helper function to convert uint256 to string (for tokenURI)
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}

// Helper library for Base64 encoding for data URIs
// Needed for dynamic tokenURI
library Base64 {
    string internal constant alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/examples/Base64.sol
        // Base64 encoding adds padding to make the encoded string's length a multiple of 4 bytes.
        int256 encodedLen = int256(data.length / 3) * 4 + (data.length % 3 == 0 ? 0 : 4);

        bytes memory buffer = new bytes(uint256(encodedLen));
        uint256 i;
        uint256 j;

        for (i = 0; i + 2 < data.length; i += 3) {
            buffer[j] = alphabet[uint8(data[i] >> 2)];
            buffer[j + 1] = alphabet[uint8(((data[i] & 3) << 4) | (data[i + 1] >> 4))];
            buffer[j + 2] = alphabet[uint8(((data[i + 1] & 15) << 2) | (data[i + 2] >> 6))];
            buffer[j + 3] = alphabet[uint8(data[i + 2] & 63)];
            j += 4;
        }

        if (data.length % 3 == 1) {
            buffer[j] = alphabet[uint8(data[i] >> 2)];
            buffer[j + 1] = alphabet[uint8((data[i] & 3) << 4)];
            buffer[j + 2] = bytes1('=');
            buffer[j + 3] = bytes1('=');
        } else if (data.length % 3 == 2) {
            buffer[j] = alphabet[uint8(data[i] >> 2)];
            buffer[j + 1] = alphabet[uint8(((data[i] & 3) << 4) | (data[i + 1] >> 4))];
            buffer[j + 2] = alphabet[uint8((data[i + 1] & 15) << 2)];
            buffer[j + 3] = bytes1('=');
        }

        return string(buffer);
    }
}

// Helper library for common math operations (like min/max for state attributes)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }
}
```