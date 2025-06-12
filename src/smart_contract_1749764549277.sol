Okay, let's create a smart contract that models "Quantum" NFTs. This concept will involve ideas like superposition (an NFT existing in multiple potential states simultaneously), measurement (collapsing the superposition into a single determined state), entanglement (linking two NFTs such that measuring one affects the other), and probabilistic state changes.

This goes beyond standard ERC721 by adding complex state management, interaction effects, and probabilistic elements.

Here is the outline and function summary, followed by the Solidity code.

---

**Contract Name:** QuantumNFT

**Description:**
This smart contract implements an ERC721-compliant NFT with added "quantum" properties. Tokens can exist in a state of Superposition (probabilistic mixture of outcomes) or be Measured (collapsed into a single, fixed outcome). Functions allow for entering superposition, performing measurements, applying "quantum gate" like operations to influence probabilities, entangling tokens, and simulating decoherence (decay of superposition).

**Outline:**

1.  **Interfaces:** ERC721, Ownable, Pausable
2.  **Libraries:** Counters
3.  **Error Codes:** Custom errors for clarity
4.  **Enums:** `State { Superposition, Measured }`
5.  **Structs:** `StateProperties` (defines traits for each possible outcome state)
6.  **State Variables:** Mappings and arrays to track token state, probabilities, measured outcome, entanglement, decoherence, possible states, state properties, and base probabilities.
7.  **Events:** To signal key state changes (Mint, Measurement, Entanglement, StateChange, GateApplied, Decay, etc.)
8.  **Modifiers:** Custom modifiers (`whenSuperposition`, `whenMeasured`, `whenNotEntangled`, `whenEntangled`, `onlyEntropySource`)
9.  **Constructor:** Initializes contract owner, name, symbol, base URI, and initial possible states/properties.
10. **ERC721 Functions:** Implement standard ERC721 methods (`balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `tokenURI`).
11. **Owner/Admin Functions:** (`pause`, `unpause`, `withdrawFunds`, `setBaseURI`, `addPossibleState`, `setStateProperties`, `setBaseProbabilityWeights`, `setEntropySource`)
12. **Core Quantum Functions:**
    *   `mintQuantumNFT`: Mints a new token into Superposition with base probabilities.
    *   `enterSuperposition`: Allows a Measured token to return to Superposition.
    *   `measureQuantumState`: Collapses a Superposition token to a specific Measured outcome based on current probabilities and entropy.
    *   `getCurrentProbabilities`: Views the probability distribution for a token in Superposition.
    *   `getMeasuredState`: Views the fixed outcome for a Measured token.
    *   `getTokenCurrentProperties`: Views the properties based on the token's current state (probabilistic in superposition, fixed when measured).
13. **Quantum Operation (Gate) Functions:**
    *   `applyHadamardGate`: Applies a "randomizing" operation to probabilities.
    *   `applyPhaseShiftGate`: Shifts probabilities towards a specific state.
    *   `applyCustomGate`: Allows a more complex, predefined transformation of probabilities.
14. **Entanglement Functions:**
    *   `entangleTokens`: Links two tokens, requiring both to be in Superposition.
    *   `disentangleTokens`: Breaks the entanglement link.
    *   `getEntangledPair`: Gets the token entangled with a given token.
15. **Decoherence Functions:**
    *   `simulateQuantumDecay`: Reduces Superposition strength over time, increasing bias towards likely states or potentially forcing measurement.
    *   `checkDecoherenceLevel`: Views the current decoherence level of a token.
16. **Helper/Internal Functions:** (`_calculateMeasurementOutcome`, `_propagateMeasurementToEntangledPair`, `_applyProbabilityTransformation`, etc.)

**Function Summary (At least 20 functions):**

1.  `constructor()`: Initializes contract.
2.  `balanceOf(address owner) view returns (uint256)`: ERC721 Standard.
3.  `ownerOf(uint256 tokenId) view returns (address)`: ERC721 Standard.
4.  `approve(address to, uint256 tokenId)`: ERC721 Standard.
5.  `getApproved(uint256 tokenId) view returns (address)`: ERC721 Standard.
6.  `setApprovalForAll(address operator, bool approved)`: ERC721 Standard.
7.  `isApprovedForAll(address owner, address operator) view returns (bool)`: ERC721 Standard.
8.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 Standard.
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 Standard.
10. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 Standard (overloaded).
11. `tokenURI(uint256 tokenId) view returns (string memory)`: ERC721 Standard (dynamic based on state).
12. `totalSupply() view returns (uint256)`: Returns the total number of tokens.
13. `pause()`: Owner pauses contract (Pausable).
14. `unpause()`: Owner unpauses contract (Pausable).
15. `withdrawFunds(address payable recipient)`: Owner withdraws balance.
16. `setBaseURI(string memory baseURI)`: Owner sets base URI for metadata.
17. `addPossibleState(string memory stateName, StateProperties calldata properties)`: Owner adds a new possible measured outcome state.
18. `setStateProperties(string memory stateName, StateProperties calldata properties)`: Owner updates properties for an existing state.
19. `setBaseProbabilityWeights(string[] memory stateNames, uint256[] memory weights)`: Owner sets initial probabilities for new tokens.
20. `setEntropySource(address source)`: Owner sets address allowed to provide entropy (e.g., Oracle).
21. `mintQuantumNFT(address to)`: Mints a token into Superposition.
22. `enterSuperposition(uint256 tokenId)`: Moves a Measured token back to Superposition.
23. `measureQuantumState(uint256 tokenId, uint256 entropy)`: Collapses a token from Superposition to Measured using provided entropy. (Entropy should ideally come from a trusted source like Chainlink VRF, simulated here).
24. `getCurrentProbabilities(uint256 tokenId) view returns (string[] memory states, uint256[] memory probabilities)`: Gets current state probabilities.
25. `getMeasuredState(uint256 tokenId) view returns (string memory)`: Gets the final state for a Measured token.
26. `getTokenCurrentProperties(uint256 tokenId) view returns (StateProperties memory)`: Gets properties based on the token's current state.
27. `applyHadamardGate(uint256 tokenId)`: Applies a probability randomization gate.
28. `applyPhaseShiftGate(uint256 tokenId, string memory targetState, uint256 shiftAmount)`: Shifts probabilities towards a target state.
29. `applyCustomGate(uint256 tokenId, string[] memory stateNames, uint256[] memory transformationMatrix)`: Applies a custom probability transformation. (Simplified representation of a matrix).
30. `entangleTokens(uint256 tokenIdA, uint256 tokenIdB)`: Links two tokens requiring Superposition.
31. `disentangleTokens(uint256 tokenId)`: Breaks entanglement for a token.
32. `getEntangledPair(uint256 tokenId) view returns (uint256)`: Gets the ID of the entangled token, if any.
33. `simulateQuantumDecay(uint256 tokenId)`: Simulates decay, shifting probabilities and increasing decoherence.
34. `checkDecoherenceLevel(uint256 tokenId) view returns (uint256)`: Gets the decoherence level (0-100).
35. `burn(uint256 tokenId)`: Burns a token (requires it to be disentangled and not in superposition). (Standard ERC721 function often added).

*(Note: Some functions like `safeTransferFrom` are overloaded but counted distinctly in the summary list to show the breadth of implementation).*

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For random number simulation helper

// Outline:
// 1. Interfaces: ERC721, Ownable, Pausable
// 2. Libraries: Counters, Strings, Math
// 3. Error Codes: Custom errors for clarity
// 4. Enums: State { Superposition, Measured }
// 5. Structs: StateProperties (defines traits for each possible outcome state)
// 6. State Variables: Mappings and arrays to track token state, probabilities, measured outcome, entanglement, decoherence, possible states, state properties, and base probabilities.
// 7. Events: To signal key state changes (Mint, Measurement, Entanglement, StateChange, GateApplied, Decay, etc.)
// 8. Modifiers: Custom modifiers (whenSuperposition, whenMeasured, whenNotEntangled, whenEntangled, onlyEntropySource)
// 9. Constructor: Initializes contract owner, name, symbol, base URI, and initial possible states/properties.
// 10. ERC721 Functions: Implement standard ERC721 methods (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, tokenURI).
// 11. Owner/Admin Functions: (pause, unpause, withdrawFunds, setBaseURI, addPossibleState, setStateProperties, setBaseProbabilityWeights, setEntropySource)
// 12. Core Quantum Functions: mintQuantumNFT, enterSuperposition, measureQuantumState, getCurrentProbabilities, getMeasuredState, getTokenCurrentProperties.
// 13. Quantum Operation (Gate) Functions: applyHadamardGate, applyPhaseShiftGate, applyCustomGate.
// 14. Entanglement Functions: entangleTokens, disentangleTokens, getEntangledPair.
// 15. Decoherence Functions: simulateQuantumDecay, checkDecoherenceLevel.
// 16. Helper/Internal Functions: _calculateMeasurementOutcome, _propagateMeasurementToEntangledPair, _applyProbabilityTransformation, etc.
// 17. Burn function.

// Function Summary (At least 20 functions):
// 1. constructor()
// 2. balanceOf(address owner)
// 3. ownerOf(uint256 tokenId)
// 4. approve(address to, uint256 tokenId)
// 5. getApproved(uint256 tokenId)
// 6. setApprovalForAll(address operator, bool approved)
// 7. isApprovedForAll(address owner, address operator)
// 8. transferFrom(address from, address to, uint256 tokenId)
// 9. safeTransferFrom(address from, address to, uint256 tokenId)
// 10. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// 11. tokenURI(uint256 tokenId)
// 12. totalSupply()
// 13. pause()
// 14. unpause()
// 15. withdrawFunds(address payable recipient)
// 16. setBaseURI(string memory baseURI)
// 17. addPossibleState(string memory stateName, StateProperties calldata properties)
// 18. setStateProperties(string memory stateName, StateProperties calldata properties)
// 19. setBaseProbabilityWeights(string[] memory stateNames, uint256[] memory weights)
// 20. setEntropySource(address source)
// 21. mintQuantumNFT(address to)
// 22. enterSuperposition(uint256 tokenId)
// 23. measureQuantumState(uint256 tokenId, uint256 entropy)
// 24. getCurrentProbabilities(uint256 tokenId)
// 25. getMeasuredState(uint256 tokenId)
// 26. getTokenCurrentProperties(uint256 tokenId)
// 27. applyHadamardGate(uint256 tokenId)
// 28. applyPhaseShiftGate(uint256 tokenId, string memory targetState, uint256 shiftAmount)
// 29. applyCustomGate(uint256 tokenId, string[] memory stateNames, uint256[] memory transformationMatrix)
// 30. entangleTokens(uint256 tokenIdA, uint256 tokenIdB)
// 31. disentangleTokens(uint256 tokenId)
// 32. getEntangledPair(uint256 tokenId)
// 33. simulateQuantumDecay(uint256 tokenId)
// 34. checkDecoherenceLevel(uint256 tokenId)
// 35. burn(uint256 tokenId)

contract QuantumNFT is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- Error Codes ---
    error TokenNotFound(uint256 tokenId);
    error InvalidState(uint256 tokenId, State requiredState);
    error InvalidEntropySource();
    error StateDoesNotExist(string stateName);
    error InvalidProbabilitySum();
    error NotEntangled(uint256 tokenId);
    error AlreadyEntangled(uint256 tokenId);
    error SelfEntanglement();
    error TokensNotReadyForEntanglement();
    error InvalidTransformationMatrix(); // For custom gate

    // --- Enums ---
    enum State {
        Superposition, // Probabilistic mixture of outcomes
        Measured // Collapsed into a single outcome
    }

    // --- Structs ---
    struct StateProperties {
        string name;
        string description;
        uint256 rarityScore; // e.g., 1-1000
        string ipfsHash; // Link to metadata/image specific to this state
    }

    // --- State Variables ---
    mapping(uint256 => State) private _tokenState;
    mapping(uint256 => string) private _measuredOutcome; // Only set if State is Measured
    // Stores probability percent (0-100) for each possible state for a token in Superposition
    mapping(uint256 => mapping(string => uint256)) private _stateProbabilities;
    mapping(uint256 => uint256) private _entangledPair; // tokenId -> entangled tokenId (0 if none)
    mapping(uint256 => uint256) private _decoherenceLevel; // 0 (pure superposition) to 100 (fully decohered/likely to collapse)

    string[] public possibleStates; // List of all possible measured outcomes
    mapping(string => StateProperties) public stateProperties; // Properties for each possible state
    // Base probabilities for new tokens or when re-entering superposition, sums to 100
    mapping(string => uint256) private _baseProbabilityWeights;

    address public entropySource; // Address allowed to provide entropy for measurement

    // --- Events ---
    event TokenMinted(uint256 indexed tokenId, address indexed owner, State initialState);
    event StateChanged(uint256 indexed tokenId, State newState, string measuredOutcome);
    event ProbabilitiesUpdated(uint256 indexed tokenId, string[] states, uint256[] probabilities);
    event GateApplied(uint256 indexed tokenId, string gateName);
    event TokensEntangled(uint256 indexed tokenIdA, uint256 indexed tokenIdB);
    event TokenDisentangled(uint256 indexed tokenId);
    event DecoherenceIncreased(uint256 indexed tokenId, uint256 newLevel);
    event EntropySourceUpdated(address indexed newSource);

    // --- Modifiers ---
    modifier whenSuperposition(uint256 tokenId) {
        if (_tokenState[tokenId] != State.Superposition) revert InvalidState(tokenId, State.Superposition);
        _;
    }

    modifier whenMeasured(uint256 tokenId) {
        if (_tokenState[tokenId] != State.Measured) revert InvalidState(tokenId, State.Measured);
        _;
    }

    modifier whenNotEntangled(uint256 tokenId) {
        if (_entangledPair[tokenId] != 0) revert AlreadyEntangled(tokenId);
        _;
    }

    modifier whenEntangled(uint256 tokenId) {
        if (_entangledPair[tokenId] == 0) revert NotEntangled(tokenId);
        _;
    }

    modifier onlyEntropySource() {
        if (msg.sender != entropySource) revert InvalidEntropySource();
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        _setBaseURI(baseURI);
        // Initial possible states - Owner should add more meaningful ones
        addPossibleState("Common", StateProperties({
            name: "Common",
            description: "A standard state.",
            rarityScore: 100,
            ipfsHash: "ipfs://common_metadata"
        }));
         addPossibleState("Rare", StateProperties({
            name: "Rare",
            description: "A less common state.",
            rarityScore: 500,
            ipfsHash: "ipfs://rare_metadata"
        }));
        // Set initial base probabilities (sums to 100)
        string[] memory initialStates = new string[](2);
        initialStates[0] = "Common";
        initialStates[1] = "Rare";
        uint256[] memory initialWeights = new uint256[](2);
        initialWeights[0] = 80; // 80% chance Common
        initialWeights[1] = 20; // 20% chance Rare
        _setBaseProbabilityWeights(initialStates, initialWeights);

        entropySource = msg.sender; // Initially owner is the entropy source, recommended to change to an oracle
    }

    // --- ERC721 Standard Implementations ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom handled by ERC721

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return "";
        }

        string memory stateHash;
        if (_tokenState[tokenId] == State.Measured) {
            stateHash = stateProperties[_measuredOutcome[tokenId]].ipfsHash;
        } else {
            // In Superposition, represent based on dominant state or a generic superposition state hash
             (string[] memory states, uint256[] memory probabilities) = getCurrentProbabilities(tokenId);
             uint256 maxProb = 0;
             string memory dominantState = "Superposition"; // Default if no states or zero prob

             if (states.length > 0) {
                 dominantState = states[0]; // Start with the first state
                 maxProb = probabilities[0];
                 for(uint i = 1; i < states.length; i++) {
                     if (probabilities[i] > maxProb) {
                         maxProb = probabilities[i];
                         dominantState = states[i];
                     }
                 }
             }

            // You could have a generic 'Superposition' IPFS hash,
            // or base it on the most probable state, or a combination.
            // Here, we'll use the dominant state's hash as a placeholder for dynamism.
            // A more advanced version might use Chainlink to fetch dynamic JSON metadata.
            if (bytes(stateProperties[dominantState].ipfsHash).length > 0) {
                 stateHash = stateProperties[dominantState].ipfsHash;
            } else {
                // Fallback generic hash if dominant state has no specific hash
                 stateHash = "ipfs://generic_superposition_metadata"; // Replace with your actual hash
            }
        }

        return string(abi.encodePacked(base, stateHash));
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    // --- Owner/Admin Functions ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawFunds(address payable recipient) public onlyOwner {
        (bool success,) = recipient.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function addPossibleState(string memory stateName, StateProperties calldata properties) public onlyOwner {
        if (bytes(stateProperties[stateName].name).length != 0) {
             revert("State already exists");
        }
        possibleStates.push(stateName);
        stateProperties[stateName] = properties;
    }

    function setStateProperties(string memory stateName, StateProperties calldata properties) public onlyOwner {
        // Check if state exists
        bool exists = false;
        for(uint i = 0; i < possibleStates.length; i++) {
            if (bytes(possibleStates[i]).keccak256 == bytes(stateName).keccak256) {
                exists = true;
                break;
            }
        }
        if (!exists) revert StateDoesNotExist(stateName);

        stateProperties[stateName] = properties;
    }

    function setBaseProbabilityWeights(string[] memory stateNames, uint256[] memory weights) public onlyOwner {
        if (stateNames.length != weights.length || stateNames.length == 0) revert("Invalid input arrays");

        uint256 totalWeight = 0;
        // Validate states and sum weights
        for(uint i = 0; i < stateNames.length; i++) {
             bool exists = false;
             for(uint j = 0; j < possibleStates.length; j++) {
                 if (bytes(stateNames[i]).keccak256 == bytes(possibleStates[j]).keccak256) {
                     exists = true;
                     break;
                 }
             }
             if (!exists) revert StateDoesNotExist(stateNames[i]);

             totalWeight += weights[i];
        }

        if (totalWeight != 100) revert InvalidProbabilitySum();

        // Clear previous base weights and set new ones
        for(uint i = 0; i < possibleStates.length; i++) {
            delete _baseProbabilityWeights[possibleStates[i]];
        }
        for(uint i = 0; i < stateNames.length; i++) {
            _baseProbabilityWeights[stateNames[i]] = weights[i];
        }
    }

    function setEntropySource(address source) public onlyOwner {
        entropySource = source;
        emit EntropySourceUpdated(source);
    }

    // --- Core Quantum Functions ---
    function mintQuantumNFT(address to) public payable whenNotPaused {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _safeMint(to, newItemId);
        _tokenState[newItemId] = State.Superposition;
        _decoherenceLevel[newItemId] = 0; // Start with no decoherence

        // Initialize probabilities based on base weights
        for(uint i = 0; i < possibleStates.length; i++) {
             _stateProbabilities[newItemId][possibleStates[i]] = _baseProbabilityWeights[possibleStates[i]];
        }

        emit TokenMinted(newItemId, to, State.Superposition);
        emit ProbabilitiesUpdated(newItemId, possibleStates, getCurrentProbabilities(newItemId).probabilities);
    }

    function enterSuperposition(uint256 tokenId) public payable whenMeasured(tokenId) whenNotPaused {
        _requireOwnedOrApproved(tokenId); // Only owner or approved can initiate

        // Reset state
        _tokenState[tokenId] = State.Superposition;
        _measuredOutcome[tokenId] = "";
        _decoherenceLevel[tokenId] = 0;

        // Reset probabilities to base weights
        for(uint i = 0; i < possibleStates.length; i++) {
             _stateProbabilities[tokenId][possibleStates[i]] = _baseProbabilityWeights[possibleStates[i]];
        }

        emit StateChanged(tokenId, State.Superposition, "");
        emit ProbabilitiesUpdated(tokenId, possibleStates, getCurrentProbabilities(tokenId).probabilities);
    }

    // Note: True randomness is hard on blockchain. Entropy should ideally come from a VRF Oracle.
    // This implementation uses a basic hash for simulation.
    function measureQuantumState(uint255 tokenId, uint256 entropy) public whenSuperposition(tokenId) whenNotPaused {
        _requireOwnedOrApproved(tokenId); // Only owner or approved can initiate
        // Allow only the designated entropySource or the token owner/approved to call this
        if (msg.sender != ownerOf(tokenId) && getApproved(tokenId) != msg.sender && msg.sender != entropySource) {
            revert InvalidEntropySource(); // Reusing error name for clarity
        }


        // Calculate outcome based on current probabilities and entropy
        string memory outcome = _calculateMeasurementOutcome(tokenId, entropy);

        // Collapse state
        _tokenState[tokenId] = State.Measured;
        _measuredOutcome[tokenId] = outcome;
        _decoherenceLevel[tokenId] = 100; // Fully decohered upon measurement

        // Clear probabilities (optional, but makes state clearer)
        for(uint i = 0; i < possibleStates.length; i++) {
             delete _stateProbabilities[tokenId][possibleStates[i]];
        }

        emit StateChanged(tokenId, State.Measured, outcome);
        emit MeasurementTaken(tokenId, outcome); // Custom event for measurement

        // If entangled, propagate the measurement
        uint256 entangledId = _entangledPair[tokenId];
        if (entangledId != 0 && _tokenState[entangledId] == State.Superposition) {
            _propagateMeasurementToEntangledPair(tokenId, entangledId, outcome);
        }
    }

     // Custom event for measurement, distinct from generic StateChanged
    event MeasurementTaken(uint256 indexed tokenId, string measuredOutcome);


    function getCurrentProbabilities(uint256 tokenId) public view whenSuperposition(tokenId) returns (string[] memory states, uint256[] memory probabilities) {
        states = new string[](possibleStates.length);
        probabilities = new uint256[](possibleStates.length);
        for(uint i = 0; i < possibleStates.length; i++) {
            states[i] = possibleStates[i];
            probabilities[i] = _stateProbabilities[tokenId][possibleStates[i]];
        }
        return (states, probabilities);
    }

    function getMeasuredState(uint256 tokenId) public view whenMeasured(tokenId) returns (string memory) {
        return _measuredOutcome[tokenId];
    }

     function getTokenCurrentProperties(uint256 tokenId) public view returns (StateProperties memory) {
         _requireOwnedOrApproved(tokenId); // Check if token exists implicitly via ownerOf

         if (_tokenState[tokenId] == State.Measured) {
             return stateProperties[_measuredOutcome[tokenId]];
         } else {
            // In Superposition, return properties of the most probable state
            (string[] memory states, uint256[] memory probabilities) = getCurrentProbabilities(tokenId);
            uint256 maxProb = 0;
            string memory mostProbableState = ""; // Could return a default "Superposition State" properties

            for(uint i = 0; i < states.length; i++) {
                if (probabilities[i] > maxProb) {
                    maxProb = probabilities[i];
                    mostProbableState = states[i];
                }
            }
            // If no states or all have 0 prob (shouldn't happen if base weights sum to 100)
            if (bytes(mostProbableState).length == 0 && possibleStates.length > 0) {
                 mostProbableState = possibleStates[0]; // Fallback to the first state defined
            }
            if (bytes(mostProbableState).length == 0) { // No states defined at all
                 return StateProperties({name: "Unknown", description: "No states defined", rarityScore: 0, ipfsHash: ""});
            }

            return stateProperties[mostProbableState];
         }
     }


    // --- Quantum Operation (Gate) Functions ---
    // Apply a 'Hadamard-like' gate: Tends to make probabilities more equal
    function applyHadamardGate(uint256 tokenId) public payable whenSuperposition(tokenId) whenNotPaused {
        _requireOwnedOrApproved(tokenId);

        uint256 numStates = possibleStates.length;
        if (numStates == 0) return; // Nothing to do

        uint265 currentProbSum = 0;
        for(uint i = 0; i < numStates; i++) {
             currentProbSum += _stateProbabilities[tokenId][possibleStates[i]];
        }

        if (currentProbSum == 0) { // Handle case where somehow all probs are 0
             currentProbSum = 100; // Assume probabilities should sum to 100
             for(uint i = 0; i < numStates; i++) {
                _stateProbabilities[tokenId][possibleStates[i]] = 100 / numStates;
             }
             // Redistribute remainder if 100/numStates has a remainder
             uint256 remainder = 100 % numStates;
             for(uint i = 0; i < remainder; i++) {
                 _stateProbabilities[tokenId][possibleStates[i]]++;
             }
        }


        // Simple simulation: shift probabilities towards average,
        // with a decay based on decoherence level (higher decoherence means less effect)
        uint256 decoherenceFactor = _decoherenceLevel[tokenId]; // 0-100
        uint256 effectMultiplier = 100 - decoherenceFactor; // 100% effect at 0, 0% effect at 100

        // Calculate target probability (average)
        uint256 averageProb = currentProbSum / numStates; // Use currentProbSum to avoid errors if it's not 100

        // Apply transformation
        for(uint i = 0; i < numStates; i++) {
            uint256 currentProb = _stateProbabilities[tokenId][possibleStates[i]];
            // Calculate shift needed to reach average
            int256 shift = int256(averageProb) - int256(currentProb);

            // Apply only a fraction of the shift based on effectMultiplier
            int256 appliedShift = (shift * int256(effectMultiplier)) / 100;

            // Update probability, ensuring it doesn't go below 0 (or a small epsilon)
            int256 newProb = int256(currentProb) + appliedShift;
             // Ensure minimum probability (e.g., 1 to keep state viable)
            _stateProbabilities[tokenId][possibleStates[i]] = uint256(Math.max(newProb, 1));
        }

        // Re-normalize probabilities to sum to 100 after the transformation
        _normalizeProbabilities(tokenId);


        emit GateApplied(tokenId, "Hadamard");
        emit ProbabilitiesUpdated(tokenId, possibleStates, getCurrentProbabilities(tokenId).probabilities);
    }

    // Apply a 'Phase-Shift-like' gate: Increases probability of a target state
    function applyPhaseShiftGate(uint256 tokenId, string memory targetState, uint256 shiftAmount) public payable whenSuperposition(tokenId) whenNotPaused {
        _requireOwnedOrApproved(tokenId);

        bool stateExists = false;
        for(uint i = 0; i < possibleStates.length; i++) {
            if (bytes(possibleStates[i]).keccak256 == bytes(targetState).keccak256) {
                stateExists = true;
                break;
            }
        }
        if (!stateExists) revert StateDoesNotExist(targetState);

        uint265 currentProbSum = 0;
        for(uint i = 0; i < possibleStates.length; i++) {
             currentProbSum += _stateProbabilities[tokenId][possibleStates[i]];
        }
        if (currentProbSum == 0) currentProbSum = 100; // Assume sum should be 100

        // Simple simulation: increase target state probability, decrease others proportionally
        uint256 decoherenceFactor = _decoherenceLevel[tokenId];
        uint256 effectMultiplier = 100 - decoherenceFactor; // 100% effect at 0, 0% effect at 100

        uint256 actualShift = (shiftAmount * effectMultiplier) / 100; // Apply only a fraction of shift

        uint256 targetProb = _stateProbabilities[tokenId][targetState];
        uint224 otherProbsSum = currentProbSum - targetProb;

        // Calculate how much to increase the target, limited by available "probability mass"
        uint256 increaseAmount = Math.min(actualShift, 100 - targetProb);

        if (increaseAmount > 0) {
             _stateProbabilities[tokenId][targetState] += increaseAmount;

             // Decrease other probabilities proportionally
             if (otherProbsSum > 0) {
                 uint256 decreaseAmountPerOther = (increaseAmount * 1e18) / otherProbsSum; // Use fixed point for precision
                 uint256 decreasedTotal = 0;
                 for(uint i = 0; i < possibleStates.length; i++) {
                      if (bytes(possibleStates[i]).keccak256 != bytes(targetState).keccak256) {
                          uint256 currentOtherProb = _stateProbabilities[tokenId][possibleStates[i]];
                          uint256 decrease = (currentOtherProb * decreaseAmountPerOther) / 1e18;
                          decrease = Math.min(decrease, currentOtherProb > 0 ? currentOtherProb -1 : 0); // Ensure minimum 1% or don't decrease below current if 0
                          _stateProbabilities[tokenId][possibleStates[i]] -= decrease;
                          decreasedTotal += decrease;
                      }
                 }
                 // Redistribute any leftover increaseAmount if proportional decrease didn't use it all
                 // This is complex, simpler to just normalize afterwards
             }
              _normalizeProbabilities(tokenId); // Ensure sums to 100
        }


        emit GateApplied(tokenId, "PhaseShift");
        emit ProbabilitiesUpdated(tokenId, possibleStates, getCurrentProbabilities(tokenId).probabilities);
    }

     // Apply a Custom Gate: Allows defining arbitrary (within reason) probability transformations.
     // Simplified: maps current state probability to a new value directly.
     // transformationMatrix format: [state1_old_prob, state1_new_prob, state2_old_prob, state2_new_prob, ...]
     // This is NOT a matrix multiplication simulation, just a mapping.
     // A real gate simulation is complex and requires advanced math/libraries beyond basic Solidity.
    function applyCustomGate(uint256 tokenId, string[] memory stateNames, uint256[] memory transformationMatrix) public payable whenSuperposition(tokenId) whenNotPaused {
        _requireOwnedOrApproved(tokenId);

        if (stateNames.length * 2 != transformationMatrix.length || stateNames.length == 0) {
             revert InvalidTransformationMatrix();
        }

        uint265 currentProbSum = 0;
        for(uint i = 0; i < possibleStates.length; i++) {
             currentProbSum += _stateProbabilities[tokenId][possibleStates[i]];
        }
        if (currentProbSum == 0) currentProbSum = 100;

         mapping(string => uint256) memory newProbabilities;
         uint256 tempSum = 0;

        // Apply the transformation mapping
        for(uint i = 0; i < stateNames.length; i++) {
             string memory stateName = stateNames[i];
             uint256 oldProb = transformationMatrix[i * 2];
             uint256 newProb = transformationMatrix[i * 2 + 1];

             bool stateExists = false;
             for(uint j = 0; j < possibleStates.length; j++) {
                if (bytes(possibleStates[j]).keccak256 == bytes(stateName).keccak256) {
                    stateExists = true;
                    break;
                }
            }
            if (!stateExists) revert StateDoesNotExist(stateName);

            // Simple check: ensure the current probability matches the 'old_prob' in the mapping (or allow some tolerance)
            // Or, a different approach: newProb is simply the NEW probability for stateName, regardless of old.
            // Let's use the simpler approach for this example: newProb is the target probability.
            newProbabilities[stateName] = newProb;
            tempSum += newProb;
        }

         if (tempSum != 100) revert InvalidProbabilitySum(); // Transformed probabilities must still sum to 100

        // Apply the new probabilities, scaled by decoherence
        uint256 decoherenceFactor = _decoherenceLevel[tokenId];
        uint256 effectMultiplier = 100 - decoherenceFactor;

        // Create a copy of current probabilities to blend with new ones
        mapping(string => uint256) memory currentProbabilitiesSnapshot;
         for(uint i = 0; i < possibleStates.length; i++) {
            currentProbabilitiesSnapshot[possibleStates[i]] = _stateProbabilities[tokenId][possibleStates[i]];
         }


        for(uint i = 0; i < stateNames.length; i++) {
             string memory stateName = stateNames[i];
             uint256 targetProb = newProbabilities[stateName];
             uint256 currentProb = currentProbabilitiesSnapshot[stateName];

            // Blend current prob with target prob based on effectMultiplier
            // new_actual_prob = (current_prob * decoherenceFactor + target_prob * effectMultiplier) / 100
            // (using uint256 requires care with scaling)
            _stateProbabilities[tokenId][stateName] = ((currentProb * decoherenceFactor) + (targetProb * effectMultiplier)) / 100;
             // Ensure minimum probability
             if (_stateProbabilities[tokenId][stateName] == 0) _stateProbabilities[tokenId][stateName] = 1;
        }
        // Ensure sums to 100 after blending and min check
        _normalizeProbabilities(tokenId);


        emit GateApplied(tokenId, "Custom");
        emit ProbabilitiesUpdated(tokenId, possibleStates, getCurrentProbabilities(tokenId).probabilities);
    }


    // --- Entanglement Functions ---
    function entangleTokens(uint256 tokenIdA, uint256 tokenIdB) public payable whenNotPaused {
        _requireOwnedOrApproved(tokenIdA); // Caller must own/be approved for A
        _requireOwnedOrApproved(tokenIdB); // Caller must own/be approved for B

        if (tokenIdA == tokenIdB) revert SelfEntanglement();
        if (_entangledPair[tokenIdA] != 0 || _entangledPair[tokenIdB] != 0) revert AlreadyEntangled(tokenIdA); // Check both

        // Both must be in superposition to be entangled in this model
        if (_tokenState[tokenIdA] != State.Superposition || _tokenState[tokenIdB] != State.Superposition) {
             revert TokensNotReadyForEntanglement();
        }

        _entangledPair[tokenIdA] = tokenIdB;
        _entangledPair[tokenIdB] = tokenIdA;

        // When entangled, their probability states might become linked.
        // A simple model: average their current probabilities.
        uint256 numStates = possibleStates.length;
        mapping(string => uint256) memory avgProbabilities;
        uint256 avgProbSum = 0;

        for(uint i = 0; i < numStates; i++) {
             string memory stateName = possibleStates[i];
             uint256 probA = _stateProbabilities[tokenIdA][stateName];
             uint256 probB = _stateProbabilities[tokenIdB][stateName];
             avgProbabilities[stateName] = (probA + probB) / 2;
             avgProbSum += avgProbabilities[stateName];
        }

         // Re-distribute remainder if sum is not 100
         uint256 remainder = 100 - avgProbSum;
         for(uint i = 0; i < remainder; i++) {
             avgProbabilities[possibleStates[i % numStates]]++; // Add 1% to states cyclically
         }


        // Apply averaged probabilities to both tokens
        for(uint i = 0; i < numStates; i++) {
            string memory stateName = possibleStates[i];
            _stateProbabilities[tokenIdA][stateName] = avgProbabilities[stateName];
            _stateProbabilities[tokenIdB][stateName] = avgProbabilities[stateName];
        }

        emit TokensEntangled(tokenIdA, tokenIdB);
        emit ProbabilitiesUpdated(tokenIdA, possibleStates, getCurrentProbabilities(tokenIdA).probabilities);
        emit ProbabilitiesUpdated(tokenIdB, possibleStates, getCurrentProbabilities(tokenIdB).probabilities);
    }

    function disentangleTokens(uint256 tokenId) public payable whenEntangled(tokenId) whenNotPaused {
        _requireOwnedOrApproved(tokenId);

        uint256 entangledId = _entangledPair[tokenId];
        // Check if the other token is still valid and entangled back
        if (entangledId != 0 && _entangledPair[entangledId] == tokenId) {
            delete _entangledPair[tokenId];
            delete _entangledPair[entangledId];
            emit TokenDisentangled(tokenId);
            emit TokenDisentangled(entangledId);
        } else {
            // This case indicates an inconsistency, but we still clear the link for tokenId
            delete _entangledPair[tokenId];
             emit TokenDisentangled(tokenId);
        }

        // Optional: Applying disentanglement could cause a probability change or increase decoherence
        // For simplicity, we just break the link here.
    }

    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
        // No ownership check needed to just view the link
         // Check if token exists to avoid returning link for non-existent token
        _requireOwned(tokenId); // Reverts if token doesn't exist or caller not owner (simplistic check)
         // A better check would just see if token exists: ownerOf(tokenId) != address(0)
         // Let's use the simpler _requireOwned for demo purposes.
        return _entangledPair[tokenId];
    }

    // --- Decoherence Functions ---
    // Simulates gradual loss of superposition over time or external factors
    // Can be called by anyone, but its effect is limited by token state/decoherence level
    function simulateQuantumDecay(uint256 tokenId) public payable whenSuperposition(tokenId) whenNotPaused {
        _requireOwnedOrApproved(tokenId); // Can only decay if owner/approved allows interaction

        // Decay increases the decoherence level
        // Simple model: increase by a fixed amount, capped at 100
        uint256 decayIncrease = 5; // Example: increase decoherence by 5% per call
        _decoherenceLevel[tokenId] = Math.min(_decoherenceLevel[tokenId] + decayIncrease, 100);

        uint256 currentDecoherence = _decoherenceLevel[tokenId];

        // Effect of decay: Probabilities shift towards the most probable state
        // If decoherence is high, the probabilities are heavily skewed towards the most likely outcome.
        (string[] memory states, uint256[] memory probabilities) = getCurrentProbabilities(tokenId);
        uint256 numStates = states.length;
        if (numStates == 0) return;

        uint256 maxProb = 0;
        string memory mostProbableState = "";
        uint256 currentProbSum = 0; // Sum before shifting

        for(uint i = 0; i < numStates; i++) {
            uint256 prob = probabilities[i];
            currentProbSum += prob;
            if (prob > maxProb) {
                maxProb = prob;
                mostProbableState = states[i];
            }
        }
        if (currentProbSum == 0) currentProbSum = 100; // Assume sum should be 100

        // How much probability mass needs to shift towards the most probable state?
        // Example: Shift an amount proportional to the decoherence level away from less probable states
        uint256 totalShiftTarget = (currentDecoherence * (currentProbSum - maxProb)) / 100;

        uint256 shiftedAmount = 0;

        // Decrease less probable states
        for(uint i = 0; i < numStates; i++) {
             string memory stateName = states[i];
             if (bytes(stateName).keccak256 != bytes(mostProbableState).keccak256) {
                 uint256 currentProb = _stateProbabilities[tokenId][stateName];
                 // Calculate how much to shift from this state
                 uint256 shiftFromThisState = (currentProb * totalShiftTarget) / (currentProbSum - maxProb > 0 ? currentProbSum - maxProb : 1); // Avoid division by zero

                 uint256 decrease = Math.min(shiftFromThisState, currentProb > 0 ? currentProb - 1 : 0); // Ensure min probability of 1%

                 _stateProbabilities[tokenId][stateName] -= decrease;
                 shiftedAmount += decrease;
             }
        }

        // Increase the most probable state's probability by the total amount shifted
         _stateProbabilities[tokenId][mostProbableState] += shiftedAmount;

         // Ensure sums to 100
         _normalizeProbabilities(tokenId);


        emit DecoherenceIncreased(tokenId, currentDecoherence);
        emit ProbabilitiesUpdated(tokenId, possibleStates, getCurrentProbabilities(tokenId).probabilities);

        // Optional: If decoherence reaches 100, force measurement
        if (_decoherenceLevel[tokenId] == 100) {
             // Use block.timestamp as a simple entropy source here for auto-measurement
             // In production, consider a more robust source.
            _measureQuantumState(tokenId, block.timestamp + block.difficulty);
        }
    }

    function checkDecoherenceLevel(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId); // Check if token exists
        return _decoherenceLevel[tokenId];
    }

    // --- Burn Function ---
    function burn(uint256 tokenId) public payable {
        _requireOwnedOrApproved(tokenId);
        if (_tokenState[tokenId] == State.Superposition) revert("Cannot burn token in Superposition");
        if (_entangledPair[tokenId] != 0) revert("Cannot burn entangled token");

        _burn(tokenId);

        // Clean up state variables
        delete _tokenState[tokenId];
        delete _measuredOutcome[tokenId];
        // Probabilities should already be cleared if Measured
        delete _decoherenceLevel[tokenId];
        // Entanglement should already be 0 based on checks
    }


    // --- Internal Helper Functions ---

    // Requires tokenId to be in Superposition and entropy provided
    // Calculates which state is chosen based on probabilities and entropy
    function _calculateMeasurementOutcome(uint256 tokenId, uint256 entropy) internal view whenSuperposition(tokenId) returns (string memory) {
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(tokenId, entropy, block.timestamp, block.difficulty, block.coinbase)));
        uint256 randomValue = randomSeed % 100; // Get a value between 0 and 99

        uint256 cumulativeProbability = 0;
        for(uint i = 0; i < possibleStates.length; i++) {
            string memory stateName = possibleStates[i];
            uint256 probability = _stateProbabilities[tokenId][stateName];

            cumulativeProbability += probability;

            if (randomValue < cumulativeProbability) {
                return stateName; // This state is chosen
            }
        }

        // Fallback in case probabilities don't sum exactly to 100 or rounding issues
        // Should return the last state or a default state
        if (possibleStates.length > 0) {
             return possibleStates[possibleStates.length - 1];
        }
        // Should not happen if contract is initialized correctly
         revert("No possible states defined");
    }

    // Propagates the measurement outcome from sourceTokenId to entangledTargetId
    // This is the core 'quantum entanglement' effect simulation
    function _propagateMeasurementToEntangledPair(uint256 sourceTokenId, uint256 entangledTargetId, string memory sourceOutcome) internal {
        // Ensure target is still entangled and in superposition (could have been measured/disentangled by another tx)
        if (_entangledPair[entangledTargetId] != sourceTokenId || _tokenState[entangledTargetId] != State.Superposition) {
             return; // Entanglement broken or target already measured, no propagation
        }

        // Simple simulation of propagation:
        // Force the entangled token's probabilities to heavily favor the measured outcome
        // The more entangled (lower decoherence? - not tracked per link here), the stronger the correlation.
        // We'll use a high probability bias here.

        uint256 biasProbability = 90; // 90% chance of matching the source outcome
        uint256 remainingProbability = 100 - biasProbability; // 10% distributed among others

        uint256 numOtherStates = possibleStates.length > 1 ? possibleStates.length - 1 : 1; // Avoid division by zero

        // Set new probabilities for the target token
        for(uint i = 0; i < possibleStates.length; i++) {
            string memory stateName = possibleStates[i];
            if (bytes(stateName).keccak256 == bytes(sourceOutcome).keccak256) {
                _stateProbabilities[entangledTargetId][stateName] = biasProbability;
            } else {
                // Distribute remaining probability among other states
                 _stateProbabilities[entangledTargetId][stateName] = remainingProbability / numOtherStates;
            }
        }

        // Ensure sums to 100 after bias and division
        _normalizeProbabilities(entangledTargetId);


        emit ProbabilitiesUpdated(entangledTargetId, possibleStates, getCurrentProbabilities(entangledTargetId).probabilities);

        // Note: This doesn't *force* measurement on the entangled token, just updates its probabilities.
        // It still needs to be measured explicitly. This represents the instantaneous state correlation.
    }

    // Helper to normalize probabilities to sum to exactly 100 after operations
    function _normalizeProbabilities(uint256 tokenId) internal {
        uint256 currentSum = 0;
        for(uint i = 0; i < possibleStates.length; i++) {
             currentSum += _stateProbabilities[tokenId][possibleStates[i]];
        }

        if (currentSum == 100 || possibleStates.length == 0) {
             return; // Already normalized or nothing to normalize
        }

        int256 diff = int256(100) - int256(currentSum);
        uint256 numStates = possibleStates.length;

        if (diff > 0) { // Need to increase probabilities
            uint256 increasePerState = uint256(diff) / numStates;
            uint256 remainder = uint256(diff) % numStates;
             for(uint i = 0; i < numStates; i++) {
                 _stateProbabilities[tokenId][possibleStates[i]] += increasePerState;
             }
             // Add remainder to first states
             for(uint i = 0; i < remainder; i++) {
                 _stateProbabilities[tokenId][possibleStates[i]]++;
             }
        } else { // Need to decrease probabilities
             uint256 decreasePerState = uint256(-diff) / numStates;
             uint256 remainder = uint256(-diff) % numStates;
             for(uint i = 0; i < numStates; i++) {
                 uint256 currentProb = _stateProbabilities[tokenId][possibleStates[i]];
                 uint224 decrease = decreasePerState;
                 // Ensure minimum 1% probability after decrease
                 if (currentProb > 1) {
                     decrease = Math.min(decrease, currentProb - 1);
                 } else {
                     decrease = 0; // Cannot decrease below 1
                 }
                 _stateProbabilities[tokenId][possibleStates[i]] -= decrease;
             }
             // Decrease remainder from first states (if still > 1%)
             for(uint i = 0; i < remainder; i++) {
                 uint256 currentProb = _stateProbabilities[tokenId][possibleStates[i]];
                 if (currentProb > 1) {
                      _stateProbabilities[tokenId][possibleStates[i]]--;
                 }
             }
        }
        // Final check to ensure it sums to 100 (can still be off slightly due to integer division/min check)
        // A final pass might be needed, but this is a decent approximation for percentage representation.
    }


    // Helper to require ownership or approval for state-changing functions
    function _requireOwnedOrApproved(uint256 tokenId) internal view {
        address tokenOwner = ownerOf(tokenId); // ownerOf checks existence
        if (msg.sender != tokenOwner && getApproved(tokenId) != msg.sender && !isApprovedForAll(tokenOwner, msg.sender)) {
             revert ERC721Unauthorized(msg.sender, tokenId); // Using standard ERC721 error
        }
    }

     // Helper to require just ownership (used for view functions where approval doesn't grant viewing rights)
    function _requireOwned(uint256 tokenId) internal view {
        address tokenOwner = ownerOf(tokenId); // ownerOf checks existence
        if (msg.sender != tokenOwner) {
             revert ERC721Unauthorized(msg.sender, tokenId);
        }
    }

}
```