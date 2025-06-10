Okay, let's design a smart contract that manages dynamic, non-fungible digital entities whose state 'fluctuates' based on user interactions, external data (simulated), and controlled pseudo-randomness, and can even 'entangle' with other entities, influencing each other. We'll call it `QuantumFluctuator`.

This contract will be an ERC721 derivative where each token represents a "Fluctuator Unit". Each unit has internal "Quantum Attributes" (QAs) that change over time and through interactions.

**Disclaimer:** The "randomness" used in Solidity based on block data is **not truly random** and is susceptible to miner manipulation, especially in high-value scenarios. For production systems requiring secure randomness, consider Chainlink VRF or similar oracle solutions. This contract uses simple block data for illustrative purposes only. Also, time-based actions (like decay) require external triggers (like a keeper bot) as contracts cannot execute functions autonomously based on wall-clock time.

---

**Outline and Function Summary**

**Contract Name:** QuantumFluctuator

**Description:** An ERC721 smart contract managing unique digital entities ("Fluctuator Units") with dynamic, fluctuating internal states ("Quantum Attributes"). Interactions, external influences, and pseudo-randomness drive state changes, and units can form "entanglements" influencing each other.

**Core Concepts:**
1.  **ERC721 Standard:** Manages ownership and transferability of Fluctuator Units.
2.  **Dynamic State:** Each token has unique, mutable "Quantum Attributes".
3.  **Fluctuation Mechanics:** State changes triggered by specific user actions, simulated external data, and pseudo-randomness.
4.  **Entanglement:** Units can be linked, causing their states to influence each other.
5.  **Controlled Environment:** Owner can set interaction costs and influencing parameters.

**Function Categories & Summary:**

1.  **ERC721 Standard Functions (Inherited/Overridden):**
    *   `balanceOf(address owner)`: Get number of tokens held by an address.
    *   `ownerOf(uint256 tokenId)`: Get owner of a specific token.
    *   `approve(address to, uint256 tokenId)`: Approve address to manage a token.
    *   `getApproved(uint256 tokenId)`: Get approved address for a token.
    *   `setApprovalForAll(address operator, bool approved)`: Set approval for an operator for all tokens.
    *   `isApprovedForAll(address owner, address operator)`: Check if operator is approved for all tokens.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer token ownership.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks recipient).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
    *   `tokenURI(uint256 tokenId)`: Get URI for token metadata (Placeholder).

2.  **Minting & Supply:**
    *   `mintFluctuator(uint256 initialVolatility) payable`: Allows anyone to purchase and mint a new Fluctuator Unit with an initial volatility setting.

3.  **Quantum Attribute (State) Interaction:**
    *   `getQuantumAttributes(uint256 tokenId)`: View the current Quantum Attributes of a token.
    *   `stimulateFluctuator(uint256 tokenId) payable`: Pay to interact, potentially increasing energy/volatility.
    *   `stabilizeFluctuator(uint256 tokenId) payable`: Pay to interact, potentially decreasing entropy/volatility.
    *   `resonateWithBlock(uint256 tokenId)`: Trigger state change influenced by current block data (pseudo-random).
    *   `observeFluctuator(uint256 tokenId)`: A passive interaction, might reveal transient data or slightly affect state.
    *   `quantumJump(uint256 tokenId) payable`: Pay for a high-risk, drastic, pseudo-random state change.
    *   `decayFluctuator(uint256 tokenId)`: Allows anyone to trigger decay if enough time has passed since last fluctuation.
    *   `synchronizeFluctuator(uint256 tokenId, uint256 externalFactor)`: Simulate syncing with external data (`externalFactor`) to influence state.

4.  **Entanglement Mechanics:**
    *   `entangleFluctuators(uint256 tokenId1, uint256 tokenId2) payable`: Pay to entangle two Fluctuator Units, linking their state changes.
    *   `detangleFluctuator(uint256 tokenId)`: Detangle a specific Fluctuator Unit from its partner.
    *   `getEntangledPartner(uint256 tokenId)`: View which token a unit is entangled with (0 if none).

5.  **Utility & Information:**
    *   `getTotalFluctuators()`: Get the total number of Fluctuator Units minted.
    *   `getVolatilityLevel(uint256 tokenId)`: Get a computed volatility score for a token.
    *   `getLastFluctuationTime(uint256 tokenId)`: Get the timestamp of the last significant state change.
    *   `getInteractionCount(uint256 tokenId)`: Get the total number of state-changing interactions for a token.

6.  **Owner & Configuration:**
    *   `setMintCost(uint256 cost)`: Set the cost to mint a new unit.
    *   `setStimulationCost(uint256 cost)`: Set the cost for the `stimulateFluctuator` function.
    *   `setStabilizationCost(uint256 cost)`: Set the cost for the `stabilizeFluctuator` function.
    *   `setEntanglementCost(uint256 cost)`: Set the cost for the `entangleFluctuators` function.
    *   `setQuantumJumpCost(uint256 cost)`: Set the cost for the `quantumJump` function.
    *   `withdrawFunds()`: Withdraw collected Ether from interaction costs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max/abs if needed
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI (placeholder)

// Outline and Function Summary - See above comment block for details.

contract QuantumFluctuator is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using Strings for uint256; // For tokenURI (placeholder)

    // --- State Variables ---

    struct QuantumAttributes {
        int256 energy;      // Represents vitality/potential
        int256 entropy;     // Represents disorder/instability
        bool coherent;      // Represents a stable state
        uint256 lastRandomSeed; // Seed used in the last pseudo-random fluctuation
    }

    // Mapping from token ID to its Quantum Attributes
    mapping(uint256 => QuantumAttributes) private _quantumAttributes;

    // Mapping from token ID to a volatility factor affecting state changes
    mapping(uint256 => uint256) private _volatilityFactor; // Capped at a certain range (e.g., 1-100)

    // Mapping from token ID to its entangled partner token ID (0 if not entangled)
    mapping(uint256 => uint256) private _entangledWith;

    // Mapping from token ID to the timestamp of its last significant fluctuation
    mapping(uint256 => uint256) private _lastFluctuationTime;

    // Mapping from token ID to the count of interactions that modified its state
    mapping(uint256 => uint256) private _interactionCount;

    // Costs for various interactions
    uint256 public mintCost;
    uint256 public stimulationCost;
    uint256 public stabilizationCost;
    uint256 public entanglementCost;
    uint256 public quantumJumpCost;

    // Constants for fluctuation logic (can be made configurable by owner)
    uint256 public constant MIN_VOLATILITY_FACTOR = 1;
    uint256 public constant MAX_VOLATILITY_FACTOR = 100;
    uint256 public constant DECAY_PERIOD = 7 days; // Time period before decay can be triggered
    int256 public constant ATTRIBUTE_CHANGE_BOUND = 100; // Max change per attribute per standard interaction

    // --- Events ---

    event FluctuatorMinted(address indexed owner, uint256 indexed tokenId, uint256 initialVolatility);
    event QuantumAttributesChanged(uint256 indexed tokenId, int256 oldEnergy, int256 newEnergy, int256 oldEntropy, int256 newEntropy, bool oldCoherent, bool newCoherent, string changeType);
    event VolatilityChanged(uint256 indexed tokenId, uint256 oldVolatility, uint256 newVolatility);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Detangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event InteractionCountIncreased(uint256 indexed tokenId, uint256 newCount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Errors ---

    error InvalidTokenId();
    error NotOwnerOrApproved();
    error InsufficientPayment(uint256 required, uint256 provided);
    error AlreadyEntangled(uint256 tokenId);
    error NotEntangled(uint256 tokenId);
    error CannotEntangleSelf();
    error DecayPeriodNotElapsed(uint256 timeRemaining);
    error InvalidVolatilityFactor(uint256 volatility);


    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Set initial costs (can be changed by owner later)
        mintCost = 0.01 ether;
        stimulationCost = 0.001 ether;
        stabilizationCost = 0.001 ether;
        entanglementCost = 0.005 ether;
        quantumJumpCost = 0.003 ether;
    }

    // --- Internal Helpers ---

    /**
     * @dev Checks if a token ID exists.
     */
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        _;
    }

     /**
     * @dev Checks if the sender is the owner or an approved operator for the token.
     */
    modifier isOwnerOrApproved(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved();
        }
        _;
    }

     /**
     * @dev Generates a pseudo-random number based on block data and token state.
     * @param tokenId The token ID.
     * @param extraEntropy Additional data to mix into the hash.
     * @return A pseudo-random uint256.
     */
    function _generatePseudoRandom(uint256 tokenId, uint256 extraEntropy) private returns (uint256) {
        // Mix block data, sender, token ID, interaction count, and extra entropy
        // NOTE: This is NOT cryptographically secure randomness. Do not use for high-value or unpredictable outcomes if miners can influence the result.
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            msg.sender,
            tokenId,
            _interactionCount[tokenId],
            extraEntropy,
            _quantumAttributes[tokenId].lastRandomSeed // Use the previous seed
        )));
        _quantumAttributes[tokenId].lastRandomSeed = seed; // Update the seed for the next call
        return seed;
    }

    /**
     * @dev Applies fluctuation logic to a token's quantum attributes.
     * This is a core internal function called by state-changing interactions.
     * @param tokenId The token ID.
     * @param volatilityChange The amount to change the volatility factor by.
     * @param energyChange The base amount to change energy by.
     * @param entropyChange The base amount to change entropy by.
     * @param typeOfChange Description of the change for the event log.
     */
    function _applyFluctuation(
        uint256 tokenId,
        int256 volatilityChange,
        int256 energyChange,
        int256 entropyChange,
        string memory typeOfChange
    ) private {
        QuantumAttributes storage qa = _quantumAttributes[tokenId];
        uint256 oldVolatility = _volatilityFactor[tokenId];
        int256 oldEnergy = qa.energy;
        int256 oldEntropy = qa.entropy;
        bool oldCoherent = qa.coherent;

        // Apply base changes modified by volatility
        int256 effectiveEnergyChange = (energyChange * int256(_volatilityFactor[tokenId])) / MAX_VOLATILITY_FACTOR;
        int256 effectiveEntropyChange = (entropyChange * int256(_volatilityFactor[tokenId])) / MAX_VOLATILITY_FACTOR;

        qa.energy += effectiveEnergyChange;
        qa.entropy += effectiveEntropyChange;

        // Apply volatility change
        _volatilityFactor[tokenId] = Math.clamp(
            _volatilityFactor[tokenId] + uint256(Math.max(int256(MIN_VOLATILITY_FACTOR), Math.min(int256(MAX_VOLATILITY_FACTOR), volatilityChange))),
            MIN_VOLATILITY_FACTOR,
            MAX_VOLATILITY_FACTOR
        );

        // Update coherence state based on attributes (example logic)
        // Coherent if energy and entropy are within a certain balance relative to volatility
        int256 balanceFactor = qa.energy - qa.entropy;
        int256 coherenceThreshold = int256(_volatilityFactor[tokenId]) * 5; // Threshold depends on volatility
        qa.coherent = Math.abs(balanceFactor) <= coherenceThreshold;

        _lastFluctuationTime[tokenId] = block.timestamp;
        _interactionCount[tokenId]++;

        // If entangled, apply a portion of the change to the partner
        uint256 partnerId = _entangledWith[tokenId];
        if (partnerId != 0 && _exists(partnerId)) {
             QuantumAttributes storage partnerQA = _quantumAttributes[partnerId];
             // Apply a smaller, possibly reversed, change
             partnerQA.energy += effectiveEntropyChange / 2; // Chaos in one might bring energy to partner? Example logic.
             partnerQA.entropy += effectiveEnergyChange / 2; // Energy in one might bring chaos? Example logic.
             partnerQA.coherent = (partnerQA.energy - partnerQA.entropy) <= int256(_volatilityFactor[partnerId]) * 5; // Update partner coherence
             _lastFluctuationTime[partnerId] = block.timestamp; // Partner also affected by the interaction time
             // Don't increment partner's interaction count for this derived change? Or maybe? Let's not for now.
             emit QuantumAttributesChanged(partnerId, oldEnergy, partnerQA.energy, oldEntropy, partnerQA.entropy, oldCoherent, partnerQA.coherent, string(abi.encodePacked("EntangledInfluenceFrom#", tokenId.toString())));
        }


        emit QuantumAttributesChanged(tokenId, oldEnergy, qa.energy, oldEntropy, qa.entropy, oldCoherent, qa.coherent, typeOfChange);
        emit VolatilityChanged(tokenId, oldVolatility, _volatilityFactor[tokenId]);
        emit InteractionCountIncreased(tokenId, _interactionCount[tokenId]);
    }


    // --- ERC721 Standard Implementations ---

    // All standard ERC721 functions like balanceOf, ownerOf, transferFrom, etc.
    // are inherited and work out-of-the-box with the internal _mint and _transfer calls.
    // We only need to override if we add custom checks or logic around transfer.
    // For this example, standard ERC721 behavior is assumed via OpenZeppelin.

    /**
     * @dev See {IERC721Metadata-tokenURI}. Placeholder implementation.
     * Returns a generic URI. Real implementation would return unique metadata URI per token.
     */
    function tokenURI(uint256 tokenId) public view override tokenExists(tokenId) returns (string memory) {
         // Replace with actual IPFS/HTTP link logic that includes token state in the future
        return string(abi.encodePacked("ipfs://QmcPlaceholderHash/", tokenId.toString()));
    }


    // --- Minting & Supply ---

    /**
     * @dev Mints a new Fluctuator Unit. Requires payment. Initial state based on input.
     * @param initialVolatility The desired initial volatility factor (clamped).
     */
    function mintFluctuator(uint256 initialVolatility) public payable {
        if (msg.value < mintCost) {
            revert InsufficientPayment(mintCost, msg.value);
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, newTokenId);

        // Initialize Quantum Attributes - Example starting state
        _quantumAttributes[newTokenId] = QuantumAttributes({
            energy: 50,
            entropy: 50,
            coherent: true, // Start stable
            lastRandomSeed: uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, newTokenId))) // Initial seed
        });

        // Clamp initial volatility within valid range
        _volatilityFactor[newTokenId] = Math.clamp(initialVolatility, MIN_VOLATILITY_FACTOR, MAX_VOLATILITY_FACTOR);

        _entangledWith[newTokenId] = 0; // Not entangled initially
        _lastFluctuationTime[newTokenId] = block.timestamp;
        _interactionCount[newTokenId] = 0;

        emit FluctuatorMinted(msg.sender, newTokenId, _volatilityFactor[newTokenId]);

        // Refund any excess payment
        if (msg.value > mintCost) {
            payable(msg.sender).transfer(msg.value - mintCost);
        }
    }

    /**
     * @dev Returns the total number of Fluctuator Units minted.
     */
    function getTotalFluctuators() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Quantum Attribute (State) Interaction ---

    /**
     * @dev Returns the current Quantum Attributes for a Fluctuator Unit.
     * @param tokenId The token ID.
     */
    function getQuantumAttributes(uint256 tokenId) public view tokenExists(tokenId) returns (QuantumAttributes memory) {
        return _quantumAttributes[tokenId];
    }

    /**
     * @dev Interacts with a Fluctuator Unit to stimulate its state. May increase energy and volatility.
     * Requires payment and ownership/approval.
     * @param tokenId The token ID.
     */
    function stimulateFluctuator(uint256 tokenId) public payable tokenExists(tokenId) isOwnerOrApproved(tokenId) {
        if (msg.value < stimulationCost) {
            revert InsufficientPayment(stimulationCost, msg.value);
        }

        // Example fluctuation logic: Increase energy, slightly increase entropy and volatility
        _applyFluctuation(tokenId, 5, 20, 5, "Stimulate");

        // Refund any excess payment
        if (msg.value > stimulationCost) {
            payable(msg.sender).transfer(msg.value - stimulationCost);
        }
    }

    /**
     * @dev Interacts with a Fluctuator Unit to stabilize its state. May decrease entropy and volatility.
     * Requires payment and ownership/approval.
     * @param tokenId The token ID.
     */
    function stabilizeFluctuator(uint256 tokenId) public payable tokenExists(tokenId) isOwnerOrApproved(tokenId) {
        if (msg.value < stabilizationCost) {
            revert InsufficientPayment(stabilizationCost, msg.value);
        }

        // Example fluctuation logic: Decrease entropy, slightly decrease energy and volatility
        _applyFluctuation(tokenId, -5, -5, -20, "Stabilize");

        // Refund any excess payment
        if (msg.value > stabilizationCost) {
            payable(msg.sender).transfer(msg.value - stabilizationCost);
        }
    }

    /**
     * @dev Triggers a state change influenced by current block data (pseudo-random).
     * Can be called by anyone for any token.
     * @param tokenId The token ID.
     */
    function resonateWithBlock(uint256 tokenId) public tokenExists(tokenId) {
        // Use pseudo-randomness derived from block and token state
        uint256 randomness = _generatePseudoRandom(tokenId, 0); // No extra entropy needed here

        int256 energyChange = int256(randomness % (ATTRIBUTE_CHANGE_BOUND * 2)) - ATTRIBUTE_CHANGE_BOUND; // Random value between -ATT_BOUND and +ATT_BOUND
        int256 entropyChange = int256(randomness % (ATTRIBUTE_CHANGE_BOUND * 2)) - ATTRIBUTE_CHANGE_BOUND;
        int256 volatilityChange = int256(randomness % 11) - 5; // Random value between -5 and +5

        _applyFluctuation(tokenId, volatilityChange, energyChange, entropyChange, "ResonateWithBlock");
    }

    /**
     * @dev A passive interaction that might reveal or subtly affect state.
     * Currently, it primarily updates last interaction time and increments count.
     * Can be called by anyone for any token.
     * @param tokenId The token ID.
     */
    function observeFluctuator(uint256 tokenId) public tokenExists(tokenId) {
         // A simple observation doesn't change core attributes drastically,
         // but acknowledges interaction and updates time/count.
         _lastFluctuationTime[tokenId] = block.timestamp;
         _interactionCount[tokenId]++;
         emit InteractionCountIncreased(tokenId, _interactionCount[tokenId]);
         // Future: Could potentially emit an event with transient data or hints.
    }

    /**
     * @dev Triggers a high-risk, high-reward pseudo-random state jump.
     * Requires payment and ownership/approval.
     * @param tokenId The token ID.
     */
    function quantumJump(uint256 tokenId) public payable tokenExists(tokenId) isOwnerOrApproved(tokenId) {
        if (msg.value < quantumJumpCost) {
            revert InsufficientPayment(quantumJumpCost, msg.value);
        }

        // Use pseudo-randomness for a larger, unpredictable change
        uint256 randomness = _generatePseudoRandom(tokenId, 1); // Add some extra entropy

        int256 energyChange = int256(randomness % (ATTRIBUTE_CHANGE_BOUND * 10)) - (ATTRIBUTE_CHANGE_BOUND * 5); // Large random change
        int256 entropyChange = int256(randomness % (ATTRIBUTE_CHANGE_BOUND * 10)) - (ATTRIBUTE_CHANGE_BOUND * 5);
        int256 volatilityChange = int256(randomness % 21) - 10; // Larger volatility change

        _applyFluctuation(tokenId, volatilityChange, energyChange, entropyChange, "QuantumJump");

        // Refund any excess payment
        if (msg.value > quantumJumpCost) {
            payable(msg.sender).transfer(msg.value - quantumJumpCost);
        }
    }

    /**
     * @dev Allows triggering decay on a token if the decay period has elapsed since its last fluctuation.
     * Simulates natural degradation over time. Can be called by anyone.
     * @param tokenId The token ID.
     */
    function decayFluctuator(uint256 tokenId) public tokenExists(tokenId) {
        uint256 lastFluctuation = _lastFluctuationTime[tokenId];
        uint256 timeSinceLastFluctuation = block.timestamp - lastFluctuation;

        if (timeSinceLastFluctuation < DECAY_PERIOD) {
            revert DecayPeriodNotElapsed(DECAY_PERIOD - timeSinceLastFluctuation);
        }

        // Example decay logic: Increase entropy, decrease energy and volatility
        // Decay effect scales with time since last interaction
        uint256 decayFactor = timeSinceLastFluctuation / DECAY_PERIOD; // How many decay periods have passed
        decayFactor = Math.min(decayFactor, 10); // Cap the decay effect multiplier

        int256 volatilityChange = int256(decayFactor) * -3;
        int256 energyChange = int256(decayFactor) * -10;
        int256 entropyChange = int256(decayFactor) * 15;

        _applyFluctuation(tokenId, volatilityChange, energyChange, entropyChange, "Decay");
    }

    /**
     * @dev Simulates influence from external data (e.g., an oracle feed).
     * Influences state based on a provided external factor. Can be called by anyone.
     * @param tokenId The token ID.
     * @param externalFactor A value simulating external input (e.g., a price feed delta, weather data, etc.).
     */
    function synchronizeFluctuator(uint256 tokenId, uint256 externalFactor) public tokenExists(tokenId) {
        // Example synchronization logic: Adjust energy/entropy based on the external factor
        // The effect magnitude could relate to volatility
        int256 effectiveFactor = int256(externalFactor % ATTRIBUTE_CHANGE_BOUND); // Example: Use factor's remainder
        int256 energyChange = effectiveFactor * int256(_volatilityFactor[tokenId]) / MAX_VOLATILITY_FACTOR;
        int256 entropyChange = -effectiveFactor * int256(_volatilityFactor[tokenId]) / MAX_VOLATILITY_FACTOR; // Opposite effect

        _applyFluctuation(tokenId, 0, energyChange, entropyChange, "Synchronize"); // Volatility unchanged by sync
    }


    // --- Entanglement Mechanics ---

    /**
     * @dev Entangles two Fluctuator Units. Their state changes will mutually influence each other.
     * Requires payment and ownership/approval for both tokens. Tokens cannot be already entangled.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function entangleFluctuators(uint256 tokenId1, uint256 tokenId2) public payable tokenExists(tokenId1) tokenExists(tokenId2) {
        if (msg.value < entanglementCost) {
            revert InsufficientPayment(entanglementCost, msg.value);
        }
        if (tokenId1 == tokenId2) {
            revert CannotEntangleSelf();
        }
        if (_entangledWith[tokenId1] != 0) {
            revert AlreadyEntangled(tokenId1);
        }
        if (_entangledWith[tokenId2] != 0) {
            revert AlreadyEntangled(tokenId2);
        }

        // Check ownership/approval for *both* tokens
        if (ownerOf(tokenId1) != msg.sender && !isApprovedForAll(ownerOf(tokenId1), msg.sender) && getApproved(tokenId1) != msg.sender) {
            revert NotOwnerOrApproved();
        }
         if (ownerOf(tokenId2) != msg.sender && !isApprovedForAll(ownerOf(tokenId2), msg.sender) && getApproved(tokenId2) != msg.sender) {
            revert NotOwnerOrApproved();
        }


        _entangledWith[tokenId1] = tokenId2;
        _entangledWith[tokenId2] = tokenId1; // Entanglement is mutual

        emit Entangled(tokenId1, tokenId2);

         // Refund any excess payment
        if (msg.value > entanglementCost) {
            payable(msg.sender).transfer(msg.value - entanglementCost);
        }
    }

    /**
     * @dev Detangles a Fluctuator Unit from its partner.
     * Requires ownership/approval of the token to be detangled.
     * @param tokenId The ID of the token to detangle.
     */
    function detangleFluctuator(uint256 tokenId) public tokenExists(tokenId) isOwnerOrApproved(tokenId) {
        uint256 partnerId = _entangledWith[tokenId];
        if (partnerId == 0) {
            revert NotEntangled(tokenId);
        }
        if (!_exists(partnerId)) { // Handle case where partner was burned/transferred improperly
             _entangledWith[tokenId] = 0; // Clean up entanglement link if partner doesn't exist
             emit Detangled(tokenId, 0);
             return; // Token is now detangled from a non-existent partner
        }


        _entangledWith[tokenId] = 0;
        _entangledWith[partnerId] = 0;

        emit Detangled(tokenId, partnerId);
        emit Detangled(partnerId, tokenId); // Emit for both sides
    }

    /**
     * @dev Returns the token ID of the partner a unit is entangled with.
     * Returns 0 if not entangled or partner doesn't exist.
     * @param tokenId The token ID.
     */
    function getEntangledPartner(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return _entangledWith[tokenId];
    }


    // --- Utility & Information ---

    /**
     * @dev Computes and returns a volatility score for a token.
     * This is a simplified example based on the volatility factor and attribute spread.
     * @param tokenId The token ID.
     * @return A score representing volatility.
     */
    function getVolatilityLevel(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        QuantumAttributes storage qa = _quantumAttributes[tokenId];
        uint256 volatilityFactor = _volatilityFactor[tokenId];

        // Example calculation: higher volatility factor + larger difference between energy/entropy = higher volatility level
        int256 attributeSpread = Math.abs(qa.energy - qa.entropy);

        // Ensure calculation doesn't overflow or revert, keep it simple
        uint256 level = volatilityFactor + uint256(attributeSpread / 10); // Integer division

        return level;
    }

    /**
     * @dev Returns the timestamp of the last significant state change for a token.
     * @param tokenId The token ID.
     */
    function getLastFluctuationTime(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return _lastFluctuationTime[tokenId];
    }

    /**
     * @dev Returns the total count of interactions that modified a token's state.
     * @param tokenId The token ID.
     */
    function getInteractionCount(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return _interactionCount[tokenId];
    }

    // Getters for costs
    function getMintCost() public view returns (uint256) { return mintCost; }
    function getStimulationCost() public view returns (uint256) { return stimulationCost; }
    function getStabilizationCost() public view returns (uint256) { return stabilizationCost; }
    function getEntanglementCost() public view returns (uint256) { return entanglementCost; }
    function getQuantumJumpCost() public view returns (uint256) { return quantumJumpCost; }


    // --- Owner & Configuration ---

    /**
     * @dev Allows the owner to set the cost for minting new units.
     * @param cost The new minting cost in Wei.
     */
    function setMintCost(uint256 cost) public onlyOwner {
        mintCost = cost;
    }

    /**
     * @dev Allows the owner to set the cost for the `stimulateFluctuator` function.
     * @param cost The new cost in Wei.
     */
    function setStimulationCost(uint256 cost) public onlyOwner {
        stimulationCost = cost;
    }

    /**
     * @dev Allows the owner to set the cost for the `stabilizeFluctuator` function.
     * @param cost The new cost in Wei.
     */
    function setStabilizationCost(uint256 cost) public onlyOwner {
        stabilizationCost = cost;
    }

    /**
     * @dev Allows the owner to set the cost for the `entangleFluctuators` function.
     * @param cost The new cost in Wei.
     */
    function setEntanglementCost(uint256 cost) public onlyOwner {
        entanglementCost = cost;
    }

    /**
     * @dev Allows the owner to set the cost for the `quantumJump` function.
     * @param cost The new cost in Wei.
     */
    function setQuantumJumpCost(uint256 cost) public onlyOwner {
        quantumJumpCost = cost;
    }

    /**
     * @dev Allows the owner to withdraw accumulated Ether from interaction costs.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        emit FundsWithdrawn(owner(), balance);
        payable(owner()).transfer(balance);
    }

    // --- Override _transfer and _beforeTokenTransfer to handle entanglement ---
    // Note: This is a basic example. More complex logic might be needed
    // if you don't want entangled tokens to be transferable separately, etc.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If the token being transferred is entangled, detangle it first.
        // This prevents entanglement links from spanning across different owners or zero addresses.
        // Alternative: Prevent transfer entirely if entangled. This version auto-detangles.
        uint256 partnerId = _entangledWith[tokenId];
        if (partnerId != 0) {
            // Detangle both sides
            _entangledWith[tokenId] = 0;
            if (_exists(partnerId)) { // Check if partner still exists
                 _entangledWith[partnerId] = 0;
                 emit Detangled(partnerId, tokenId); // Emit for partner
            }
             emit Detangled(tokenId, partnerId); // Emit for the token being transferred
        }
    }

    // Override `supportsInterface` for ERC721 and potentially ERC165 if adding more interfaces
     function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


}
```