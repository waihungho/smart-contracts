Okay, let's create a smart contract that implements a novel concept: **Quantum Entanglement NFTs**. These NFTs will exist in pairs, and measuring the state of one will instantly affect the state of its entangled partner, simulating a core concept from quantum mechanics (albeit simplified and deterministic on-chain). They will also have dynamic attributes based on observations.

This contract will combine ERC721 ownership with custom state management, entanglement logic, and dynamic attributes.

---

**Smart Contract: QuantumEntanglementNFT**

**Outline:**

1.  **Contract Setup:**
    *   Inherits ERC721, Ownable, Pausable.
    *   Defines NFT state (`Superposition`, `SpinUp`, `SpinDown`).
    *   Stores mapping for token state, entangled partner, observation count, and custom attributes.
    *   Internal counter for token IDs.
    *   Base URI for metadata.
    *   Events for key actions.

2.  **Core ERC721 Functionality:**
    *   Standard ownership and transfer functions (`ownerOf`, `balanceOf`, `transferFrom`, `safeTransferFrom`, approvals).
    *   Overrides for `_update` and `_burn` to handle entanglement during transfers/burns.
    *   `tokenURI` to generate metadata based on state, entanglement, etc.

3.  **Minting Functions:**
    *   `mintSingle`: Creates a single, unentangled NFT in Superposition.
    *   `mintPair`: Creates two NFTs, instantly entangling them in Superposition.

4.  **Entanglement Management:**
    *   `entanglePair`: Attempts to entangle two existing, unentangled tokens owned by the caller.
    *   `disentangle`: Breaks the entanglement between two tokens owned by the caller.
    *   `preparePairForSplitTransfer`: A function to disentangle a pair *before* a transfer, allowing one half to be sent without the other.

5.  **Quantum State Management (Simulation):**
    *   `measureSingleState`: "Observes" an unentangled token, collapsing its state from Superposition to either SpinUp or SpinDown (simulated randomness).
    *   `measureEntangledState`: "Observes" one token of an entangled pair, collapsing its state and forcing the partner into the opposite state (SpinUp/SpinDown).
    *   `batchMeasureEntangledPairs`: Allows measuring multiple entangled pairs in a single transaction.

6.  **Dynamic Attributes & Observations:**
    *   `measureAndRecordObservation`: Measures a token (single or entangled) and, if it collapses to `SpinUp`, increments a per-token observation counter.
    *   `resetObservationCount`: Resets the observation counter for a token.
    *   `setTokenAttribute`: Allows the token owner to set a custom string attribute for their token.
    *   `evolveStateBasedAttribute`: Changes a special attribute based on the current state and/or observation count. (Example implementation).

7.  **Query Functions:**
    *   `getTokenState`: Returns the current state of a token.
    *   `getEntangledPartner`: Returns the ID of the token entangled with the given token (0 if none).
    *   `isTokenEntangled`: Checks if a token is currently entangled.
    *   `getPairIDs`: Returns the IDs of an entangled pair given one ID.
    *   `getObservationCount`: Returns the observation count for a token.
    *   `getTokenAttribute`: Returns the custom string attribute for a token.
    *   `getBaseURI`: Returns the contract's base metadata URI.

8.  **Admin Functions:**
    *   `pause`/`unpause`: Pauses/unpauses certain contract functionalities (like transfers, measurements, minting).
    *   `setBaseURI`: Sets the base URI for metadata.
    *   `withdraw`: Allows the owner to withdraw contract balance (e.g., if minting cost Ether).

**Function Summary:**

*   `constructor(string name, string symbol, string baseURI)`: Initializes the contract.
*   `pause()`: Pauses the contract (Owner only).
*   `unpause()`: Unpauses the contract (Owner only).
*   `setBaseURI(string newBaseURI)`: Sets the metadata base URI (Owner only).
*   `withdraw(address payable to)`: Withdraws contract balance (Owner only).
*   `mintSingle(address to)`: Mints one unentangled NFT (Owner only).
*   `mintPair(address to)`: Mints two entangled NFTs (Owner only).
*   `entanglePair(uint256 tokenId1, uint256 tokenId2)`: Entangles two owned, unentangled tokens.
*   `disentangle(uint256 tokenId1, uint256 tokenId2)`: Disentangles two owned, entangled tokens.
*   `preparePairForSplitTransfer(uint256 tokenId1, uint256 tokenId2)`: Disentangles an owned, entangled pair specifically before transferring one part.
*   `measureSingleState(uint256 tokenId)`: Measures an unentangled token.
*   `measureEntangledState(uint256 tokenId)`: Measures one token of an entangled pair.
*   `batchMeasureEntangledPairs(uint256[] tokenIds)`: Measures multiple entangled pairs.
*   `measureAndRecordObservation(uint256 tokenId)`: Measures and records observation count if SpinUp.
*   `resetObservationCount(uint256 tokenId)`: Resets a token's observation count.
*   `setTokenAttribute(uint256 tokenId, string attribute)`: Sets a custom attribute for a token (Token Owner only).
*   `evolveStateBasedAttribute(uint256 tokenId)`: Updates a special attribute based on state/observations (Token Owner only).
*   `getTokenState(uint256 tokenId)`: Gets a token's current state.
*   `getEntangledPartner(uint256 tokenId)`: Gets a token's entangled partner ID.
*   `isTokenEntangled(uint256 tokenId)`: Checks if a token is entangled.
*   `getPairIDs(uint256 tokenId)`: Gets both IDs in an entangled pair.
*   `getObservationCount(uint256 tokenId)`: Gets a token's observation count.
*   `getTokenAttribute(uint256 tokenId)`: Gets a token's custom attribute.
*   `getBaseURI()`: Gets the base URI.
*   `tokenURI(uint256 tokenId)`: Generates the metadata URI for a token.
*   `supportsInterface(bytes4 interfaceId)`: ERC165 compliance.
*   `_update(address to, uint256 tokenId)`: Internal ERC721 hook.
*   `_burn(uint256 tokenId)`: Internal ERC721 hook (modified to disentangle partner).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @title QuantumEntanglementNFT
/// @dev A novel NFT contract exploring simulated quantum entanglement and dynamic attributes.
///      NFTs can be minted in pairs or singly. Entangled pairs share a correlated state
///      that collapses upon measurement. Attributes can change based on observation history.
contract QuantumEntanglementNFT is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _currentTokenId;

    // --- State Definitions ---
    enum State {
        Superposition, // Unknown state before measurement
        SpinUp,        // Collapsed state
        SpinDown       // Collapsed state (opposite of SpinUp for entangled partner)
    }

    // --- State Variables ---
    mapping(uint256 => State) private _tokenStates;
    mapping(uint256 => uint256) private _entangledPartner; // tokenId => partnerTokenId (0 if not entangled)
    mapping(uint256 => uint256) private _observationCounts; // tokenId => count of SpinUp observations
    mapping(uint256 => string) private _tokenAttributes; // tokenId => custom string attribute

    string private _baseTokenURI;

    // --- Events ---
    event StateMeasured(uint256 indexed tokenId, State newState, uint256 indexed partnerTokenId, State partnerNewState);
    event PairEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event PairDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event AttributeChanged(uint256 indexed tokenId, string newAttribute);
    event ObservationRecorded(uint256 indexed tokenId, uint256 newCount);

    // --- Modifiers ---
    modifier onlyTokenOwner(uint256 tokenId) {
        require(_exists(tokenId), "QENFT: token does not exist");
        require(_ownerOf(tokenId) == _msgSender(), "QENFT: caller is not token owner");
        _;
    }

    modifier onlyUnentangled(uint256 tokenId) {
        require(!isTokenEntangled(tokenId), "QENFT: token is already entangled");
        _;
    }

    modifier onlyEntangledPair(uint256 tokenId1, uint256 tokenId2) {
        require(tokenId1 != tokenId2, "QENFT: cannot use same token ID");
        require(isTokenEntangled(tokenId1) && _entangledPartner[tokenId1] == tokenId2, "QENFT: tokens are not an entangled pair");
        require(isTokenEntangled(tokenId2) && _entangledPartner[tokenId2] == tokenId1, "QENFT: tokens are not an entangled pair");
        _;
    }

    modifier onlySuperposition(uint256 tokenId) {
        require(_tokenStates[tokenId] == State.Superposition, "QENFT: token is not in Superposition");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
    }

    // --- Admin Functions ---

    /// @dev Pauses contract functionality. Only callable by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpauses contract functionality. Only callable by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev Sets the base URI for token metadata. Only callable by the owner.
    /// @param newBaseURI The new base URI.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @dev Allows the owner to withdraw any Ether held by the contract.
    /// @param to The address to send the Ether to.
    function withdraw(address payable to) public onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "QENFT: withdrawal failed");
    }

    // --- Minting Functions ---

    /// @dev Mints a single, unentangled NFT.
    /// @param to The address to mint the token to.
    function mintSingle(address to) public onlyOwner whenNotPaused returns (uint256) {
        uint256 newTokenId = _currentTokenId.current();
        _currentTokenId.increment();
        _safeMint(to, newTokenId);
        _tokenStates[newTokenId] = State.Superposition; // Start in Superposition
        _entangledPartner[newTokenId] = 0; // Not entangled
        _observationCounts[newTokenId] = 0;
        _tokenAttributes[newTokenId] = ""; // Default empty attribute
        return newTokenId;
    }

    /// @dev Mints a pair of entangled NFTs.
    /// @param to The address to mint the tokens to.
    function mintPair(address to) public onlyOwner whenNotPaused returns (uint256, uint256) {
        uint256 tokenId1 = _currentTokenId.current();
        _currentTokenId.increment();
        uint256 tokenId2 = _currentTokenId.current();
        _currentTokenId.increment();

        _safeMint(to, tokenId1);
        _safeMint(to, tokenId2);

        // Entangle them immediately
        _entangle(tokenId1, tokenId2); // Internal helper handles state and partner linking

        emit PairEntangled(tokenId1, tokenId2);
        return (tokenId1, tokenId2);
    }

    // --- Entanglement Management ---

    /// @dev Attempts to entangle two existing, unentangled tokens owned by the caller.
    ///      Requires both tokens to be in Superposition state.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entanglePair(uint256 tokenId1, uint256 tokenId2) public whenNotPaused onlyTokenOwner(tokenId1) onlyTokenOwner(tokenId2) onlyUnentangled(tokenId1) onlyUnentangled(tokenId2) onlySuperposition(tokenId1) onlySuperposition(tokenId2) {
        require(tokenId1 != tokenId2, "QENFT: cannot entangle token with itself");
        _entangle(tokenId1, tokenId2);
        emit PairEntangled(tokenId1, tokenId2);
    }

    /// @dev Breaks the entanglement between two tokens owned by the caller.
    /// @param tokenId1 The ID of the first token in the pair.
    /// @param tokenId2 The ID of the second token in the pair.
    function disentangle(uint256 tokenId1, uint256 tokenId2) public whenNotPaused onlyTokenOwner(tokenId1) onlyTokenOwner(tokenId2) onlyEntangledPair(tokenId1, tokenId2) {
        _disentangle(tokenId1, tokenId2);
        emit PairDisentangled(tokenId1, tokenId2);
    }

    /// @dev Disentangles an owned, entangled pair, specifically to prepare them for individual transfer.
    ///      Requires both tokens to be owned by the caller.
    /// @param tokenId1 The ID of the first token in the pair.
    /// @param tokenId2 The ID of the second token in the pair.
    function preparePairForSplitTransfer(uint256 tokenId1, uint256 tokenId2) public whenNotPaused onlyTokenOwner(tokenId1) onlyTokenOwner(tokenId2) onlyEntangledPair(tokenId1, tokenId2) {
         // This function simply calls disentangle, explicitly stating the intent
        _disentangle(tokenId1, tokenId2);
        emit PairDisentangled(tokenId1, tokenId2); // Emit same event
    }


    // --- Quantum State Management (Simulation) ---

    /// @dev Measures the state of an unentangled token, collapsing it from Superposition.
    ///      Simulates random collapse to SpinUp or SpinDown.
    /// @param tokenId The ID of the token to measure.
    function measureSingleState(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) onlyUnentangled(tokenId) onlySuperposition(tokenId) {
        // Simulate quantum collapse (deterministic randomness on-chain)
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, tx.origin))) % 2;

        State newState = (randomNumber == 0) ? State.SpinUp : State.SpinDown;
        _tokenStates[tokenId] = newState;

        emit StateMeasured(tokenId, newState, 0, State.Superposition); // Partner 0 for single token
    }

    /// @dev Measures the state of one token in an entangled pair, collapsing the state
    ///      of both tokens. Simulates anti-correlated collapse (one SpinUp, one SpinDown).
    ///      Requires the token to be part of an entangled pair and in Superposition.
    /// @param tokenId The ID of one token in the entangled pair.
    function measureEntangledState(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) onlySuperposition(tokenId) {
        uint256 partnerTokenId = _entangledPartner[tokenId];
        require(partnerTokenId != 0 && partnerTokenId != tokenId, "QENFT: token is not part of an entangled pair");
        require(_exists(partnerTokenId), "QENFT: entangled partner does not exist");
        require(_ownerOf(partnerTokenId) == _msgSender(), "QENFT: caller does not own both tokens of the pair"); // Must own both to measure entangled state
        require(_tokenStates[partnerTokenId] == State.Superposition, "QENFT: entangled partner is not in Superposition"); // Both must be in superposition for measurement

        // Simulate quantum collapse (deterministic randomness on-chain)
        // The outcome for the pair is random, but the individual outcomes are correlated.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, partnerTokenId, tx.origin))) % 2;

        State state1, state2;
        if (randomNumber == 0) {
            state1 = State.SpinUp;
            state2 = State.SpinDown;
        } else {
            state1 = State.SpinDown;
            state2 = State.SpinUp;
        }

        // Assign states based on which token was the input
        if (tokenId == tokenId) { // Always true, but makes logic clear
            _tokenStates[tokenId] = state1;
            _tokenStates[partnerTokenId] = state2;
            emit StateMeasured(tokenId, state1, partnerTokenId, state2);
        } else {
            // Should not happen with the 'onlyEntangledPair' check logic earlier,
            // but being explicit for safety if modifier logic changes
             _tokenStates[tokenId] = state2;
             _tokenStates[partnerTokenId] = state1;
             emit StateMeasured(tokenId, state2, partnerTokenId, state1);
        }
    }

    /// @dev Measures the state of multiple entangled pairs in a single transaction.
    ///      Requires caller to own all tokens in all pairs and for all tokens
    ///      to be in Superposition.
    /// @param tokenIds An array containing one token ID from each entangled pair to measure.
    ///                 The array length must be even and contain pairs.
    function batchMeasureEntangledPairs(uint256[] memory tokenIds) public whenNotPaused {
        require(tokenIds.length > 0, "QENFT: array is empty");
        require(tokenIds.length % 2 == 0, "QENFT: array must contain pairs (even length)"); // Expecting pairs

        for (uint i = 0; i < tokenIds.length; i += 2) {
            uint256 tokenId1 = tokenIds[i];
            uint256 tokenId2 = tokenIds[i+1];

            // Check ownership, entanglement, and superposition for the pair
            require(_exists(tokenId1), "QENFT: token does not exist");
            require(_exists(tokenId2), "QENFT: token does not exist");
            require(_ownerOf(tokenId1) == _msgSender(), "QENFT: caller does not own pair part 1");
            require(_ownerOf(tokenId2) == _msgSender(), "QENFT: caller does not own pair part 2");
            require(isTokenEntangled(tokenId1) && _entangledPartner[tokenId1] == tokenId2, "QENFT: tokens are not an entangled pair");
            require(_tokenStates[tokenId1] == State.Superposition, "QENFT: pair part 1 not in Superposition");
            require(_tokenStates[tokenId2] == State.Superposition, "QENFT: pair part 2 not in Superposition");

            // Perform the measurement for this pair
            // Simulate quantum collapse (deterministic randomness on-chain for the pair)
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId1, tokenId2, tx.origin, i))) % 2; // Add index for variation

            State state1, state2;
            if (randomNumber == 0) {
                state1 = State.SpinUp;
                state2 = State.SpinDown;
            } else {
                state1 = State.SpinDown;
                state2 = State.SpinUp;
            }

            _tokenStates[tokenId1] = state1;
            _tokenStates[tokenId2] = state2;
            emit StateMeasured(tokenId1, state1, tokenId2, state2);
        }
    }


    // --- Dynamic Attributes & Observations ---

    /// @dev Measures the state of a token (single or entangled) and records an
    ///      observation if the resulting state is SpinUp.
    /// @param tokenId The ID of the token to measure and record observation for.
    function measureAndRecordObservation(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) {
         require(_exists(tokenId), "QENFT: token does not exist");
         State initialState = _tokenStates[tokenId];
         uint256 partnerTokenId = _entangledPartner[tokenId];

         if (initialState == State.Superposition) {
             if (partnerTokenId == 0) {
                 // Single token, in superposition - measure it
                 measureSingleState(tokenId); // This updates state and emits StateMeasured
             } else {
                 // Entangled token, in superposition - measure the pair
                 measureEntangledState(tokenId); // This updates state and emits StateMeasured for both
             }
         }
         // If not in Superposition, state remains the same upon "observation" (no collapse occurs)

        // Check the resulting state after potential measurement
        if (_tokenStates[tokenId] == State.SpinUp) {
            _observationCounts[tokenId]++;
            emit ObservationRecorded(tokenId, _observationCounts[tokenId]);
        }
    }

    /// @dev Resets the SpinUp observation count for a token.
    /// @param tokenId The ID of the token.
    function resetObservationCount(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) {
        require(_exists(tokenId), "QENFT: token does not exist");
        _observationCounts[tokenId] = 0;
        emit ObservationRecorded(tokenId, 0);
    }

    /// @dev Sets a custom string attribute for a token.
    /// @param tokenId The ID of the token.
    /// @param attribute The string value for the attribute.
    function setTokenAttribute(uint256 tokenId, string memory attribute) public whenNotPaused onlyTokenOwner(tokenId) {
        require(_exists(tokenId), "QENFT: token does not exist");
        _tokenAttributes[tokenId] = attribute;
        emit AttributeChanged(tokenId, attribute);
    }

    /// @dev Evolves a token's special attribute based on its current state and observation count.
    ///      This is an example of dynamic, state-dependent attributes.
    /// @param tokenId The ID of the token.
    function evolveStateBasedAttribute(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) {
         require(_exists(tokenId), "QENFT: token does not exist");

         string memory evolvedAttr;
         State currentState = _tokenStates[tokenId];
         uint256 observationCount = _observationCounts[tokenId];

         if (currentState == State.Superposition) {
             evolvedAttr = "Waiting for Observation...";
         } else if (currentState == State.SpinUp && observationCount > 10) {
             evolvedAttr = string(abi.encodePacked("Ascended (Obs: ", Strings.toString(observationCount), ")"));
         } else if (currentState == State.SpinUp) {
             evolvedAttr = string(abi.encodePacked("Energized (Obs: ", Strings.toString(observationCount), ")"));
         } else if (currentState == State.SpinDown && observationCount > 0) {
              evolvedAttr = string(abi.encodePacked("Stabilized (Obs: ", Strings.toString(observationCount), ")"));
         }
         else {
             evolvedAttr = "Idle";
         }

         if (bytes(_tokenAttributes[tokenId]).length == 0 || !keccak256(abi.encodePacked(_tokenAttributes[tokenId])) == keccak256(abi.encodePacked(evolvedAttr))) {
             _tokenAttributes[tokenId] = evolvedAttr;
             emit AttributeChanged(tokenId, evolvedAttr);
         }
    }


    // --- Query Functions ---

    /// @dev Returns the current state of a token.
    /// @param tokenId The ID of the token.
    /// @return The state of the token (Superposition, SpinUp, or SpinDown).
    function getTokenState(uint256 tokenId) public view returns (State) {
        require(_exists(tokenId), "QENFT: token does not exist");
        return _tokenStates[tokenId];
    }

    /// @dev Returns the ID of the token entangled with the given token.
    /// @param tokenId The ID of the token.
    /// @return The partner token ID (0 if not entangled).
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: token does not exist");
        return _entangledPartner[tokenId];
    }

    /// @dev Checks if a token is currently entangled with another token.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isTokenEntangled(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "QENFT: token does not exist");
        return _entangledPartner[tokenId] != 0 && _entangledPartner[tokenId] != tokenId;
    }

    /// @dev Given one token ID of an entangled pair, returns both token IDs.
    /// @param tokenId The ID of a token in an entangled pair.
    /// @return A tuple containing the two token IDs of the pair.
    function getPairIDs(uint256 tokenId) public view returns (uint256, uint256) {
        require(isTokenEntangled(tokenId), "QENFT: token is not entangled");
        uint256 partnerId = _entangledPartner[tokenId];
        // Ensure the other half points back, although `isTokenEntangled` should cover this
        require(_entangledPartner[partnerId] == tokenId, "QENFT: inconsistent entanglement data");
        // Return IDs in consistent order (e.g., smallest first)
        return tokenId < partnerId ? (tokenId, partnerId) : (partnerId, tokenId);
    }

    /// @dev Returns the SpinUp observation count for a token.
    /// @param tokenId The ID of the token.
    /// @return The observation count.
    function getObservationCount(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QENFT: token does not exist");
         return _observationCounts[tokenId];
    }

    /// @dev Returns the custom string attribute for a token.
    /// @param tokenId The ID of the token.
    /// @return The custom attribute string.
    function getTokenAttribute(uint256 tokenId) public view returns (string memory) {
         require(_exists(tokenId), "QENFT: token does not exist");
         return _tokenAttributes[tokenId];
    }

    /// @dev Returns the contract's base metadata URI.
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // --- ERC721 Overrides ---

    /// @dev See {IERC721Metadata-tokenURI}. Generates a dynamic URI based on token state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }

        string memory stateString;
        State currentState = _tokenStates[tokenId];
        if (currentState == State.Superposition) stateString = "Superposition";
        else if (currentState == State.SpinUp) stateString = "SpinUp";
        else stateString = "SpinDown";

        uint256 partnerId = _entangledPartner[tokenId];
        string memory entanglementStatus = partnerId == 0 ? "Unentangled" : string(abi.encodePacked("Entangled with ", Strings.toString(partnerId)));

        string memory attributeString = _tokenAttributes[tokenId];

        string memory json = string(abi.encodePacked(
            '{"name": "Quantum Entanglement NFT #', Strings.toString(tokenId), '",',
            '"description": "A token representing a simulated quantum particle.",',
            '"attributes": [',
                '{"trait_type": "State", "value": "', stateString, '"},',
                '{"trait_type": "Entanglement", "value": "', entanglementStatus, '"},',
                '{"trait_type": "Observation Count", "value": ', Strings.toString(_observationCounts[tokenId]), '}',
                // Add custom attribute if present
                bytes(attributeString).length > 0 ? string(abi.encodePacked(',{"trait_type": "Custom Attribute", "value": "', attributeString, '"}')) : "",
            ']}'
        ));

        // Encode JSON as Base64 data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @dev See {ERC721-_update}. Modified to pause operations during updates.
    function _update(address to, uint256 tokenId) internal override whenNotPaused returns (address) {
        // Entanglement persists through transfers. No need to disentangle partner here.
        // Disentanglement logic is handled in _burn if applicable.
        return super._update(to, tokenId);
    }

    /// @dev See {ERC721-_burn}. Modified to disentangle partner if the burned token was part of a pair.
    function _burn(uint256 tokenId) internal override {
        uint256 partnerId = _entangledPartner[tokenId];
        if (partnerId != 0) {
            // Burned token was part of a pair, disentangle the partner
             // Check if the partner still exists and is entangled with THIS token
             if (_exists(partnerId) && _entangledPartner[partnerId] == tokenId) {
                 _disentangle(tokenId, partnerId); // Use internal helper
                 emit PairDisentangled(tokenId, partnerId); // Emit event
             }
        }
        // Clear state and attribute data for the burned token
        delete _tokenStates[tokenId];
        delete _entangledPartner[tokenId];
        delete _observationCounts[tokenId];
        delete _tokenAttributes[tokenId];

        super._burn(tokenId);
    }

    // --- Internal Helper Functions ---

    /// @dev Internal helper to manage entanglement link creation.
    function _entangle(uint256 tokenId1, uint256 tokenId2) internal {
        _entangledPartner[tokenId1] = tokenId2;
        _entangledPartner[tokenId2] = tokenId1;
        // When newly entangled, set state to Superposition
        _tokenStates[tokenId1] = State.Superposition;
        _tokenStates[tokenId2] = State.Superposition;
         // Reset observation counts upon entanglement (optional, depends on game theory)
        _observationCounts[tokenId1] = 0;
        _observationCounts[tokenId2] = 0;
    }

    /// @dev Internal helper to manage entanglement link breaking.
    function _disentangle(uint256 tokenId1, uint256 tokenId2) internal {
        // Note: Does NOT reset state to Superposition. State remains whatever it was
        // upon disentanglement (could be SpinUp/Down if measured, or Superposition).
        delete _entangledPartner[tokenId1];
        delete _entangledPartner[tokenId2];
         // Observation counts persist.
    }

    // --- Pausable Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

     // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        // Add ERC721Enumerable and ERC721URIStorage interfaces if using them
        // Currently only supporting standard ERC721 + ERC165
        return super.supportsInterface(interfaceId);
    }
}
```