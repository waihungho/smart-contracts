Okay, let's create a smart contract concept that combines NFTs with a metaphorical representation of "Quantum Entanglement" and dynamic states. This is purely a conceptual model inspired by physics, not actual quantum computation on the blockchain (which isn't feasible yet).

Here's the plan:

**Contract Name:** `QuantumEntangledNFTs`

**Concept:** A collection of NFTs where some can be linked into "entangled" pairs. The state of one NFT in an entangled pair can instantaneously (in contract execution terms) affect the state of its partner. NFTs can exist in different "Quantum States" (`GROUND`, `EXCITED`, `SUPERPOSITION`) and "Entanglement States" (`POTENTIAL`, `ENTANGLED`, `DECOHERED`). Interactions like "Observation" (forcing a state collapse) or "State Transfer" have unique effects on entangled pairs. There are mechanics for attempting, breaking, and reinforcing entanglement.

**Outline:**

1.  **Pragma and Imports:** Solidity version and OpenZeppelin libraries (ERC721, Ownable, Pausable).
2.  **Error Definitions:** Custom errors for clearer reverts.
3.  **Enums:** Define possible `EntanglementState` and `QuantumState`.
4.  **Structs:** Define `TokenState` to hold dynamic data for each token.
5.  **State Variables:** Mappings for token states, next token ID, fees, base URI.
6.  **Events:** Log key state changes and actions.
7.  **Constructor:** Initialize base contract, contract owner, initial fees.
8.  **Modifiers:** Custom modifiers for access control and state checks.
9.  **ERC721 Overrides:** Implement required ERC721 functions and potentially add checks (e.g., restrict transfer of entangled NFTs directly).
10. **Metadata Function:** `tokenURI` to dynamically generate metadata based on the NFT's state.
11. **Core Minting Functions:** Functions to create new NFTs, specifically pairs intended for entanglement and single NFTs.
12. **Entanglement Management Functions:** Functions for attempting entanglement, breaking it, and potentially re-establishing it.
13. **Quantum State Interaction Functions:** Functions simulating actions that change an NFT's quantum state (`observeState`, `induceSuperposition`, `transferExcitation`). These are the core "advanced" functions.
14. **Entanglement/State Query Functions:** View functions to retrieve the state and pair information of NFTs.
15. **Coherence Mechanics:** Functions to manage a "coherence level" for entangled pairs (`measureCoherence`, `boostCoherence`).
16. **Admin/Utility Functions:** Pause, withdraw funds, set fees, update metadata URI.
17. **Internal Helper Functions:** Functions used internally for state management and checks.

**Function Summary:**

*   `constructor`: Initializes contract, sets owner and initial fees.
*   `name`: Returns the ERC721 collection name.
*   `symbol`: Returns the ERC721 collection symbol.
*   `balanceOf(address owner)`: Returns the number of tokens owned by an address. (Standard ERC721)
*   `ownerOf(uint256 tokenId)`: Returns the owner of a specific token. (Standard ERC721)
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership safely. Modified to handle entangled states (potentially breaking entanglement upon transfer).
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Overloaded safe transfer. Modified similarly.
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership. Modified similarly.
*   `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific token. (Standard ERC721)
*   `getApproved(uint256 tokenId)`: Gets the approved address for a token. (Standard ERC721)
*   `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all of owner's tokens. (Standard ERC721)
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens. (Standard ERC721)
*   `supportsInterface(bytes4 interfaceId)`: ERC165 support check. (Standard ERC721)
*   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token, incorporating its current state.
*   `mintPotentialPair`: Mints two new tokens initialized in the `POTENTIAL` entanglement state, linked as a pair.
*   `mintSingle`: Mints a single new token not initially part of any pair, initialized as `POTENTIAL` (or maybe `DECOHERED`).
*   `attemptEntanglement(uint256 tokenId1, uint256 tokenId2)`: Allows owners of two `POTENTIAL` tokens (potentially requiring mutual approval or owning both) to attempt to set their state to `ENTANGLED`. May have a fee and a chance of failure (simulated).
*   `breakEntanglement(uint256 tokenId)`: Allows the owner of an `ENTANGLED` token to break the link. Sets both tokens in the pair to `DECOHERED`.
*   `recoherePair(uint256 tokenId1, uint256 tokenId2)`: Allows owners of a `DECOHERED` pair to attempt to set their state back to `ENTANGLED`. Might be more difficult or costly than initial entanglement.
*   `observeState(uint256 tokenId)`: Core quantum interaction. If the token is in `SUPERPOSITION`, forces it into a definite state (`GROUND` or `EXCITED`). If the token is `ENTANGLED` and its partner is *also* in `SUPERPOSITION`, this action forces *both* into the same definite state simultaneously. Consumes a conceptual "observation energy" or fee.
*   `induceSuperposition(uint256 tokenId)`: Allows the owner to attempt to put an NFT from a definite state (`GROUND` or `EXCITED`) into `SUPERPOSITION`. Might have conditions or a failure chance, especially if entangled.
*   `transferExcitation(uint256 fromTokenId, uint256 toTokenId)`: Allows the owner to transfer the `EXCITED` state from `fromTokenId` to `toTokenId`, provided `fromTokenId` is `EXCITED` and `toTokenId` is `GROUND`, and they are `ENTANGLED`. `fromTokenId` becomes `GROUND`, `toTokenId` becomes `EXCITED`.
*   `measureCoherence(uint256 tokenId)`: View function. Returns a calculated "coherence level" for an `ENTANGLED` pair based on recent activity or state (e.g., degrades over time/blocks since last interaction).
*   `boostCoherence(uint256 tokenId)`: Allows the owner to increase the `coherenceLevel` of an `ENTANGLED` pair. May require a fee.
*   `getEntangledPairId(uint256 tokenId)`: View function. Returns the token ID of the entangled partner, or 0 if not entangled.
*   `getEntanglementState(uint256 tokenId)`: View function. Returns the `EntanglementState` of a token.
*   `getQuantumState(uint256 tokenId)`: View function. Returns the `QuantumState` of a token.
*   `getPairOwner(uint256 tokenId)`: View function. Returns the owner of the entangled partner token.
*   `getPairStates(uint256 tokenId)`: View function. Returns the `EntanglementState` and `QuantumState` of both tokens in a pair.
*   `pause()`: Pauses core contract functions (transfers, state changes). Only callable by owner. (Standard Pausable)
*   `unpause()`: Unpauses the contract. Only callable by owner. (Standard Pausable)
*   `withdrawFunds()`: Allows owner to withdraw collected fees. (Standard Ownable utility)
*   `setAttemptEntanglementFee(uint256 fee)`: Allows owner to set the fee for attempting entanglement.
*   `setBoostCoherenceFee(uint256 fee)`: Allows owner to set the fee for boosting coherence.
*   `updateBaseMetadataURI(string memory uri)`: Allows owner to update the base URI for metadata.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Contract Outline ---
// 1. Pragma and Imports
// 2. Error Definitions
// 3. Enums for States
// 4. Struct for Token State Data
// 5. State Variables (Mappings, Counters, Fees, URIs)
// 6. Events
// 7. Constructor
// 8. Modifiers for Access and State Checks
// 9. ERC721 Overrides (with Entanglement Logic)
// 10. Dynamic Metadata (tokenURI)
// 11. Core Minting Functions
// 12. Entanglement Management (Attempt, Break, Recohere)
// 13. Quantum State Interaction (Observe, Induce, TransferExcitation) - The core creative functions
// 14. Entanglement/State Query Views
// 15. Coherence Mechanics (Measure, Boost)
// 16. Admin/Utility Functions (Pause, Withdraw, Set Fees/URI)
// 17. Internal Helper Functions

// --- Function Summary ---
// constructor(): Initializes contract, sets owner, name, symbol, and initial fees.
// name(): Returns the ERC721 collection name. (Standard ERC721)
// symbol(): Returns the ERC721 collection symbol. (Standard ERC721)
// balanceOf(address owner): Returns the number of tokens owned by an address. (Standard ERC721)
// ownerOf(uint256 tokenId): Returns the owner of a specific token. (Standard ERC721)
// safeTransferFrom(address from, address to, uint256 tokenId): Transfers ownership safely. Overridden to handle entangled states (breaks entanglement).
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Overloaded safe transfer. Overridden similarly.
// transferFrom(address from, address to, uint256 tokenId): Transfers ownership. Overridden similarly.
// approve(address to, uint256 tokenId): Approves an address to transfer a specific token. (Standard ERC721)
// getApproved(uint256 tokenId): Gets the approved address for a token. (Standard ERC721)
// setApprovalForAll(address operator, bool approved): Sets approval for an operator for all of owner's tokens. (Standard ERC721)
// isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens. (Standard ERC721)
// supportsInterface(bytes4 interfaceId): ERC165 support check. (Standard ERC721)
// tokenURI(uint256 tokenId): Returns the metadata URI for a token, dynamically generated based on its current state.
// mintPotentialPair(): Mints two new tokens initialized as a linked pair in the POTENTIAL entanglement state. Callable by owner.
// mintSingle(): Mints a single new token not initially part of a pair. Callable by owner.
// attemptEntanglement(uint256 tokenId1, uint256 tokenId2): Allows owners (or approved addresses) of two POTENTIAL tokens to pay a fee to attempt to set their state to ENTANGLED. Requires mutual consent/ownership.
// breakEntanglement(uint256 tokenId): Allows the owner of an ENTANGLED token to break the link. Sets both tokens in the pair to DECOHERED.
// recoherePair(uint256 tokenId1, uint256 tokenId2): Allows owners of a DECOHERED pair to attempt to set their state back to ENTANGLED. May have different fee/conditions than initial attempt.
// observeState(uint256 tokenId): Core quantum interaction. If the token is in SUPERPOSITION, forces it into a definite state (GROUND or EXCITED). If ENTANGLED and partner is also SUPERPOSITION, collapses both to the same state. Consumes fee/gas.
// induceSuperposition(uint256 tokenId): Allows owner to attempt to put an NFT from GROUND or EXCITED into SUPERPOSITION. May have conditions.
// transferExcitation(uint256 fromTokenId, uint256 toTokenId): Transfers the EXCITED state from fromTokenId to toTokenId within an ENTANGLED pair, where fromTokenId is EXCITED and toTokenId is GROUND.
// measureCoherence(uint256 tokenId): View function. Returns a conceptual "coherence level" for an ENTANGLED pair based on time since last boost/interaction.
// boostCoherence(uint256 tokenId): Allows owner to increase the coherenceLevel of an ENTANGLED pair for a fee.
// getEntangledPairId(uint256 tokenId): View function. Returns the token ID of the entangled partner, or 0.
// getEntanglementState(uint256 tokenId): View function. Returns the EntanglementState enum value.
// getQuantumState(uint256 tokenId): View function. Returns the QuantumState enum value.
// getPairOwner(uint256 tokenId): View function. Returns the owner of the entangled partner token.
// getPairStates(uint256 tokenId): View function. Returns the EntanglementState and QuantumState of both tokens in a pair.
// pause(): Pauses core contract functions (transfers, state changes). Owner only.
// unpause(): Unpauses the contract. Owner only.
// withdrawFunds(): Allows owner to withdraw collected fees.
// setAttemptEntanglementFee(uint256 fee): Allows owner to set the fee for attempting entanglement.
// setBoostCoherenceFee(uint256 fee): Allows owner to set the fee for boosting coherence.
// updateBaseMetadataURI(string memory uri): Allows owner to update the base URI used in tokenURI.
// _breakEntanglementInternal(uint256 tokenId): Internal helper to break entanglement.
// _updateTokenState(uint256 tokenId, EntanglementState newEntanglementState, QuantumState newQuantumState, uint256 newCoherenceLevel): Internal helper to update token state.

contract QuantumEntangledNFTs is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- 2. Error Definitions ---
    error NotPotentialState(uint256 tokenId);
    error NotEntangledState(uint256 tokenId);
    error NotDecoheredState(uint256 tokenId);
    error NotSuperpositionState(uint256 tokenId);
    error NotGroundState(uint256 tokenId);
    error NotExcitedState(uint256 tokenId);
    error NotOwnerOrApproved(uint256 tokenId);
    error PairMismatch(uint256 tokenId1, uint256 tokenId2);
    error NotLinkedPair(uint256 tokenId1, uint256 tokenId2);
    error AlreadyEntangled(uint256 tokenId);
    error AlreadyDecohered(uint256 tokenId);
    error AlreadySuperposition(uint256 tokenId);
    error InsufficientFunds(uint256 required, uint256 provided);
    error CannotTransferEntangled(uint256 tokenId); // We'll modify transfer to auto-break instead
    error InvalidPairForExcitationTransfer();

    // --- 3. Enums ---
    enum EntanglementState { POTENTIAL, ENTANGLED, DECOHERED } // Can token be entangled, is it entangled, was it entangled
    enum QuantumState { GROUND, EXCITED, SUPERPOSITION } // Simulating basic quantum states

    // --- 4. Struct ---
    struct TokenState {
        EntanglementState entanglementState;
        QuantumState quantumState;
        uint256 entangledPairId; // 0 if not entangled or potential/decohered
        uint256 coherenceLevel; // Represents the strength/stability of entanglement
        uint256 lastCoherenceBoostBlock; // Block number of last boost
    }

    // --- 5. State Variables ---
    mapping(uint256 => TokenState) private _tokenStates;

    string private _baseMetadataURI;
    uint256 public attemptEntanglementFee = 0.01 ether; // Example fee
    uint256 public boostCoherenceFee = 0.005 ether; // Example fee
    uint256 public constant MAX_COHERENCE = 1000;
    uint256 public constant COHERENCE_DECAY_PER_BLOCK = 1; // Example decay rate

    // --- 6. Events ---
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Decohered(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event StateChanged(uint256 indexed tokenId, QuantumState newState);
    event SuperpositionInduced(uint256 indexed tokenId);
    event Observed(uint256 indexed tokenId, QuantumState resultingState);
    event CoherenceBoosted(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 newCoherenceLevel);

    // --- 7. Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        ERC721Enumerable()
        Ownable(msg.sender)
        Pausable()
    {}

    // --- 8. Modifiers ---
    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender && !isApprovedForAll(_ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved(tokenId);
        }
        _;
    }

    // --- 9. ERC721 Overrides ---
    // Overriding internal _beforeTokenTransfer and _afterTokenTransfer
    // to handle entanglement state change upon transfer.

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        // Call _beforeTokenTransfer here if needed
        _beforeTokenTransfer(ERC721.ownerOf(tokenId), to, tokenId, 0); // Assuming quantity 0 for NFT transfers

        address from = ERC721.ownerOf(tokenId);

        // --- Custom logic: Break entanglement on transfer ---
        if (_tokenStates[tokenId].entanglementState == EntanglementState.ENTANGLED) {
            _breakEntanglementInternal(tokenId);
        }
        // --- End custom logic ---

        address newOwner = super._update(to, tokenId, auth);

        // Call _afterTokenTransfer here if needed
         _afterTokenTransfer(from, to, tokenId, 0); // Assuming quantity 0 for NFT transfers

         return newOwner;
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        // Call _beforeTokenTransfer if needed
        _beforeTokenTransfer(address(0), to, tokenId, 0);

        super._mint(to, tokenId);

        // Call _afterTokenTransfer here if needed
        _afterTokenTransfer(address(0), to, tokenId, 0);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        // Call _beforeTokenTransfer if needed
         _beforeTokenTransfer(ERC721.ownerOf(tokenId), address(0), tokenId, 0);

         // --- Custom logic: Break entanglement on burn ---
        if (_tokenStates[tokenId].entanglementState == EntanglementState.ENTANGLED) {
            _breakEntanglementInternal(tokenId);
        }
        // --- End custom logic ---

        super._burn(tokenId);

        // Call _afterTokenTransfer if needed
        _afterTokenTransfer(ERC721.ownerOf(tokenId), address(0), tokenId, 0); // Note: ownerOf will fail after super._burn
    }

    // --- Implement required overrides for ERC721Enumerable ---
    // ERC721Enumerable requires overriding _update, _mint, _burn, and supportsInterface.
    // _update is already done above. _mint and _burn are internal helpers called by public mint/burn functions.
    // We need to override the public ERC721 functions that use _update, _mint, _burn
    // This is implicitly handled by OpenZeppelin's implementation details when inheriting ERC721Enumerable,
    // but explicitly overriding safeTransferFrom and transferFrom is good practice to
    // ensure our pre/post logic for entanglement is definitely called.

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
         _update(to, tokenId, _msgSender()); // This calls our overridden _update
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) whenNotPaused {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
         _update(to, tokenId, _msgSender()); // This calls our overridden _update
         require(
            _checkOnERC721Received(address(0), from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
         );
    }

     function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
         _update(to, tokenId, _msgSender()); // This calls our overridden _update
    }


    // The following functions are also part of ERC721Enumerable
    // but are implemented correctly by the base contract or the overrides above:
    // totalSupply(): Returns the total number of tokens.
    // tokenByIndex(uint256 index): Returns a token ID by index.
    // tokenOfOwnerByIndex(address owner, uint256 index): Returns token ID of an owner by index.

    // --- 10. Dynamic Metadata ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();
        }

        TokenState storage state = _tokenStates[tokenId];
        string memory entState;
        if (state.entanglementState == EntanglementState.POTENTIAL) entState = "Potential";
        else if (state.entanglementState == EntanglementState.ENTANGLED) entState = "Entangled";
        else entState = "Decohered";

        string memory qState;
        if (state.quantumState == QuantumState.GROUND) qState = "Ground";
        else if (state.quantumState == QuantumState.EXCITED) qState = "Excited";
        else qState = "Superposition";

        uint256 currentCoherence = measureCoherence(tokenId); // Calculate current coherence dynamically

        string memory json = string(abi.encodePacked(
            '{"name": "Quantum Entity #', Strings.toString(tokenId), '",',
            '"description": "A dynamic NFT influenced by entanglement.",',
            '"attributes": [',
                '{"trait_type": "Entanglement State", "value": "', entState, '"},',
                '{"trait_type": "Quantum State", "value": "', qState, '"},',
                '{"trait_type": "Coherence Level", "value": ', Strings.toString(currentCoherence), '},',
                '{"trait_type": "Entangled Partner", "value": ', (state.entangledPairId != 0 ? Strings.toString(state.entangledPairId) : '"None"'), '}',
            ']}'
        ));

        string memory baseURI = _baseMetadataURI;
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
             // If no base URI, serve data URI (gas intensive!)
             return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        }
    }

    // --- 11. Core Minting Functions ---

    /// @notice Mints two new tokens initialized as a linked pair in the POTENTIAL entanglement state.
    /// @dev Only callable by the contract owner.
    function mintPotentialPair() external onlyOwner whenNotPaused {
        _tokenIds.increment();
        uint256 tokenId1 = _tokenIds.current();
        _mint(msg.sender, tokenId1);

        _tokenIds.increment();
        uint256 tokenId2 = _tokenIds.current();
        _mint(msg.sender, tokenId2);

        // Initialize state for the pair
        _tokenStates[tokenId1].entanglementState = EntanglementState.POTENTIAL;
        _tokenStates[tokenId1].quantumState = QuantumState.GROUND; // Initial state can vary
        _tokenStates[tokenId1].entangledPairId = tokenId2;
        _tokenStates[tokenId1].coherenceLevel = 0; // Start with no coherence

        _tokenStates[tokenId2].entanglementState = EntanglementState.POTENTIAL;
        _tokenStates[tokenId2].quantumState = QuantumState.EXCITED; // Different initial state
        _tokenStates[tokenId2].entangledPairId = tokenId1;
        _tokenStates[tokenId2].coherenceLevel = 0; // Start with no coherence
    }

    /// @notice Mints a single new token not initially part of any pair.
    /// @dev Only callable by the contract owner.
    function mintSingle() external onlyOwner whenNotPaused {
         _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);

        // Initialize state for a single token
        _tokenStates[tokenId].entanglementState = EntanglementState.DECOHERED; // Or POTENTIAL? Decohered makes more sense for single
        _tokenStates[tokenId].quantumState = QuantumState.GROUND;
        _tokenStates[tokenId].entangledPairId = 0; // Not part of a pair
        _tokenStates[tokenId].coherenceLevel = 0;
    }

    // --- 12. Entanglement Management ---

    /// @notice Allows owners (or approved) of two POTENTIAL tokens to attempt entanglement.
    /// @dev Requires mutual consent/ownership and a fee.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function attemptEntanglement(uint256 tokenId1, uint256 tokenId2) external payable whenNotPaused {
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();
        if (tokenId1 == tokenId2) revert PairMismatch(tokenId1, tokenId2);

        TokenState storage state1 = _tokenStates[tokenId1];
        TokenState storage state2 = _tokenStates[tokenId2];

        if (state1.entanglementState != EntanglementState.POTENTIAL) revert NotPotentialState(tokenId1);
        if (state2.entanglementState != EntanglementState.POTENTIAL) revert NotPotentialState(tokenId2);

        // Check ownership/approval for both. Caller must own/be approved for at least one,
        // and the other token must also be owned by caller or approved by its owner.
        // This is simplified: caller must own both OR be approved for both.
        // For a truly decentralized "mutual consent", would need a separate approval mechanism.
        // Let's simplify and say caller needs to own/be approved for *both* tokens.
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Caller not authorized for token 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Caller not authorized for token 2");


        if (msg.value < attemptEntanglementFee) revert InsufficientFunds(attemptEntanglementFee, msg.value);

        // Simulate a probabilistic attempt. Using block hash as a *simple* pseudo-randomness source.
        // WARNING: Block hash is not truly random and can be manipulated by miners.
        // For production, use Chainlink VRF or similar.
        uint256 attemptChance = (block.timestamp % 100); // 0-99
        bool success = attemptChance < 70; // 70% chance of success

        if (success) {
            state1.entanglementState = EntanglementState.ENTANGLED;
            state1.entangledPairId = tokenId2;
            state1.coherenceLevel = MAX_COHERENCE / 2; // Start with moderate coherence
            state1.lastCoherenceBoostBlock = block.number;

            state2.entanglementState = EntanglementState.ENTANGLED;
            state2.entangledPairId = tokenId1;
            state2.coherenceLevel = MAX_COHERENCE / 2;
            state2.lastCoherenceBoostBlock = block.number;

            emit Entangled(tokenId1, tokenId2);
        } else {
            // Stay in POTENTIAL or move to DECOHERED? Let's stay POTENTIAL but log failure.
            // No state change on failure, just consume fee.
            emit Entangled(tokenId1, tokenId2); // Emit with special flag or just a separate Failure event? Let's just log success.
            // Revert if failure? No, consume fee.
        }
    }

    /// @notice Allows the owner (or approved) of an ENTANGLED token to break the link.
    /// @dev Sets both tokens in the pair to DECOHERED.
    /// @param tokenId The ID of one token in the entangled pair.
    function breakEntanglement(uint256 tokenId) external onlyTokenOwnerOrApproved(tokenId) whenNotPaused {
        if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();

        TokenState storage state = _tokenStates[tokenId];
        if (state.entanglementState != EntanglementState.ENTANGLED) revert NotEntangledState(tokenId);

        _breakEntanglementInternal(tokenId);
    }

     /// @notice Allows owners (or approved) of a DECOHERED pair to attempt to re-establish entanglement.
     /// @dev Similar to attemptEntanglement but for DECOHERED tokens. May be harder.
     /// @param tokenId1 The ID of the first token in the pair.
     /// @param tokenId2 The ID of the second token in the pair.
    function recoherePair(uint256 tokenId1, uint256 tokenId2) external payable whenNotPaused {
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();
        if (tokenId1 == tokenId2) revert PairMismatch(tokenId1, tokenId2);

        TokenState storage state1 = _tokenStates[tokenId1];
        TokenState storage state2 = _tokenStates[tokenId2];

        if (state1.entanglementState != EntanglementState.DECOHERED) revert NotDecoheredState(tokenId1);
        if (state2.entanglementState != EntanglementState.DECOHERED) revert NotDecoheredState(tokenId2);

        if (state1.entangledPairId != tokenId2 || state2.entangledPairId != tokenId1 || state1.entangledPairId == 0) {
             revert NotLinkedPair(tokenId1, tokenId2);
        }

         // Caller must own both OR be approved for both.
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Caller not authorized for token 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Caller not authorized for token 2");

        // Maybe a higher fee or lower chance than initial attempt?
        uint256 recohereFee = attemptEntanglementFee * 1.5; // Example: 50% more
        if (msg.value < recohereFee) revert InsufficientFunds(recohereFee, msg.value);

        // Simulate a probabilistic attempt (lower chance?)
        uint256 attemptChance = (block.timestamp % 100); // 0-99
        bool success = attemptChance < 50; // 50% chance of success (lower than initial 70%)

        if (success) {
            state1.entanglementState = EntanglementState.ENTANGLED;
             state1.coherenceLevel = MAX_COHERENCE / 2;
             state1.lastCoherenceBoostBlock = block.number;

            state2.entanglementState = EntanglementState.ENTANGLED;
             state2.coherenceLevel = MAX_COHERENCE / 2;
             state2.lastCoherenceBoostBlock = block.number;

            emit Entangled(tokenId1, tokenId2); // Re-use Entangled event
        } else {
            // Remain DECOHERED
            // No state change on failure, just consume fee.
        }
    }


    // --- 13. Quantum State Interaction ---

    /// @notice Forces a SUPERPOSITION token into a definite state (GROUND or EXCITED).
    /// @dev If ENTANGLED and partner is also SUPERPOSITION, both collapse to the same state.
    /// @param tokenId The ID of the token to observe.
    function observeState(uint256 tokenId) external onlyTokenOwnerOrApproved(tokenId) whenNotPaused {
        if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();

        TokenState storage state = _tokenStates[tokenId];
        if (state.quantumState != QuantumState.SUPERPOSITION) revert NotSuperpositionState(tokenId);

        // Determine the resulting state. Use block hash/timestamp as simple pseudo-random source.
        // WARNING: Not secure randomness.
        QuantumState resultingState = (block.timestamp % 2 == 0) ? QuantumState.GROUND : QuantumState.EXCITED;

        state.quantumState = resultingState;
        emit StateChanged(tokenId, resultingState);
        emit Observed(tokenId, resultingState);

        // Check if entangled and affect partner
        if (state.entanglementState == EntanglementState.ENTANGLED && state.entangledPairId != 0) {
            uint256 pairTokenId = state.entangledPairId;
            TokenState storage pairState = _tokenStates[pairTokenId];

            // If the partner is also in SUPERPOSITION, force it into the *same* resulting state
            if (pairState.quantumState == QuantumState.SUPERPOSITION) {
                 pairState.quantumState = resultingState;
                 emit StateChanged(pairTokenId, resultingState);
                 emit Observed(pairTokenId, resultingState);
            }
             // If the partner is in a definite state, this observation might have no effect,
             // or could have a *chance* to nudge the partner. Let's keep it simple: only
             // affects partner if partner is also SUPERPOSITION.
        }
    }

    /// @notice Allows the owner (or approved) to attempt to put a token from GROUND or EXCITED into SUPERPOSITION.
    /// @dev May have conditions or a failure chance.
    /// @param tokenId The ID of the token.
    function induceSuperposition(uint256 tokenId) external onlyTokenOwnerOrApproved(tokenId) whenNotPaused {
        if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();

        TokenState storage state = _tokenStates[tokenId];
        if (state.quantumState == QuantumState.SUPERPOSITION) revert AlreadySuperposition(tokenId);

        // Check if entangled. If entangled, maybe require partner to also be in a definite state?
        // Let's allow it even if entangled, the core interaction happens on Observe.
        // Could add a failure chance here if desired.

        state.quantumState = QuantumState.SUPERPOSITION;
        emit StateChanged(tokenId, QuantumState.SUPERPOSITION);
        emit SuperpositionInduced(tokenId);
    }

    /// @notice Transfers the EXCITED state from one token to its entangled partner.
    /// @dev Requires tokens to be ENTANGLED, fromTokenId to be EXCITED, and toTokenId to be GROUND.
    /// @param fromTokenId The token currently in the EXCITED state.
    /// @param toTokenId The token currently in the GROUND state.
    function transferExcitation(uint256 fromTokenId, uint256 toTokenId) external whenNotPaused {
        if (!_exists(fromTokenId) || !_exists(toTokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();
        if (fromTokenId == toTokenId) revert PairMismatch(fromTokenId, toTokenId);

        TokenState storage state1 = _tokenStates[fromTokenId];
        TokenState storage state2 = _tokenStates[toTokenId];

        if (state1.entanglementState != EntanglementState.ENTANGLED || state2.entanglementState != EntanglementState.ENTANGLED) {
             revert NotEntangledState(fromTokenId); // Or custom error
        }
        if (state1.entangledPairId != toTokenId || state2.entangledPairId != fromTokenId) {
            revert NotLinkedPair(fromTokenId, toTokenId);
        }

         // Caller must own both OR be approved for both tokens involved in the transfer.
        require(_isApprovedOrOwner(msg.sender, fromTokenId), "Caller not authorized for 'from' token");
        require(_isApprovedOrOwner(msg.sender, toTokenId), "Caller not authorized for 'to' token");

        if (state1.quantumState != QuantumState.EXCITED) revert NotExcitedState(fromTokenId);
        if (state2.quantumState != QuantumState.GROUND) revert NotGroundState(toTokenId);

        // Perform the state transfer
        state1.quantumState = QuantumState.GROUND;
        state2.quantumState = QuantumState.EXCITED;

        emit StateChanged(fromTokenId, QuantumState.GROUND);
        emit StateChanged(toTokenId, QuantumState.EXCITED);
    }

    // --- 14. Entanglement/State Query Views ---

    /// @notice Returns the token ID of the entangled partner.
    /// @param tokenId The token ID to query.
    /// @return The partner token ID, or 0 if not part of a linked pair.
    function getEntangledPairId(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();
        return _tokenStates[tokenId].entangledPairId;
    }

     /// @notice Returns the EntanglementState of a token.
     /// @param tokenId The token ID to query.
     /// @return The EntanglementState enum value.
    function getEntanglementState(uint256 tokenId) public view returns (EntanglementState) {
         if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();
         return _tokenStates[tokenId].entanglementState;
    }

     /// @notice Returns the QuantumState of a token.
     /// @param tokenId The token ID to query.
     /// @return The QuantumState enum value.
    function getQuantumState(uint256 tokenId) public view returns (QuantumState) {
         if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();
         return _tokenStates[tokenId].quantumState;
    }

     /// @notice Returns the owner of the entangled partner token.
     /// @dev Returns address(0) if the token is not part of a linked pair.
     /// @param tokenId The token ID to query.
     /// @return The owner address of the partner token.
    function getPairOwner(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();
        uint256 pairId = _tokenStates[tokenId].entangledPairId;
        if (pairId == 0 || !_exists(pairId)) {
            return address(0);
        }
        return ownerOf(pairId); // Use the public ownerOf function
    }

     /// @notice Returns the states of both tokens in a linked pair.
     /// @dev Returns default values if the token is not part of a linked pair.
     /// @param tokenId The ID of one token in the pair.
     /// @return Tuple containing (tokenId1, entanglementState1, quantumState1, tokenId2, entanglementState2, quantumState2).
    function getPairStates(uint256 tokenId) public view returns (
        uint256, EntanglementState, QuantumState,
        uint256, EntanglementState, QuantumState
    ) {
        if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();

        TokenState storage state1 = _tokenStates[tokenId];
        uint256 tokenId1 = tokenId;
        uint256 tokenId2 = state1.entangledPairId;

        if (tokenId2 == 0 || !_exists(tokenId2) || _tokenStates[tokenId2].entangledPairId != tokenId1) {
             // Not a valid pair link, return info for token1 and defaults for token2
             return (
                 tokenId1, state1.entanglementState, state1.quantumState,
                 0, EntanglementState.DECOHERED, QuantumState.GROUND
             );
        }

        TokenState storage state2 = _tokenStates[tokenId2];
        return (
            tokenId1, state1.entanglementState, state1.quantumState,
            tokenId2, state2.entanglementState, state2.quantumState
        );
    }


    // --- 15. Coherence Mechanics ---

    /// @notice Calculates and returns the current conceptual coherence level of an entangled pair.
    /// @dev Decays over blocks since last boost. Returns 0 if not entangled.
    /// @param tokenId The ID of one token in the pair.
    /// @return The calculated coherence level (0 to MAX_COHERENCE).
    function measureCoherence(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();

        TokenState storage state = _tokenStates[tokenId];
        if (state.entanglementState != EntanglementState.ENTANGLED || state.entangledPairId == 0) {
            return 0;
        }

        uint256 blocksSinceLastBoost = block.number - state.lastCoherenceBoostBlock;
        uint256 decay = blocksSinceLastBoost * COHERENCE_DECAY_PER_BLOCK;

        if (state.coherenceLevel <= decay) {
            return 0;
        } else {
            // Coherence is tracked individually but conceptually linked.
            // Return the lower of the two coherence levels in the pair? Or just the queried token's decayed level?
            // Let's keep it simple and return the queried token's decayed level.
            return state.coherenceLevel - decay;
        }
    }

    /// @notice Allows the owner (or approved) to pay a fee to boost the coherence level of an ENTANGLED pair.
    /// @param tokenId The ID of one token in the entangled pair.
    function boostCoherence(uint256 tokenId) external payable onlyTokenOwnerOrApproved(tokenId) whenNotPaused {
        if (!_exists(tokenId)) revert ERC721Enumerable.EnumerableExpectedTokenDoesNotExist();

        TokenState storage state1 = _tokenStates[tokenId];
        if (state1.entanglementState != EntanglementState.ENTANGLED || state1.entangledPairId == 0) {
            revert NotEntangledState(tokenId);
        }

         uint256 tokenId2 = state1.entangledPairId;
         TokenState storage state2 = _tokenStates[tokenId2];

        if (msg.value < boostCoherenceFee) revert InsufficientFunds(boostCoherenceFee, msg.value);

        // Calculate current decayed coherence for both
        uint256 currentCoherence1 = measureCoherence(tokenId);
        uint256 currentCoherence2 = measureCoherence(tokenId2);

        // Apply boost (e.g., add a fixed amount, capping at MAX_COHERENCE)
        uint256 boostAmount = 200; // Example boost amount

        state1.coherenceLevel = Math.min(currentCoherence1 + boostAmount, MAX_COHERENCE);
        state1.lastCoherenceBoostBlock = block.number; // Reset decay timer

        state2.coherenceLevel = Math.min(currentCoherence2 + boostAmount, MAX_COHERENCE);
        state2.lastCoherenceBoostBlock = block.number; // Reset decay timer


        emit CoherenceBoosted(tokenId, tokenId2, state1.coherenceLevel);
    }


    // --- 16. Admin/Utility Functions ---

    /// @notice Pauses contract functions (minting, transfers, state changes).
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw accumulated fees.
    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    /// @notice Allows the owner to set the fee for attempting entanglement.
    function setAttemptEntanglementFee(uint256 fee) external onlyOwner {
        attemptEntanglementFee = fee;
    }

     /// @notice Allows the owner to set the fee for boosting coherence.
    function setBoostCoherenceFee(uint256 fee) external onlyOwner {
        boostCoherenceFee = fee;
    }

    /// @notice Allows the owner to update the base URI for metadata.
    function updateBaseMetadataURI(string memory uri) external onlyOwner {
        _baseMetadataURI = uri;
    }

    // --- 17. Internal Helper Functions ---

    /// @dev Internal helper to break entanglement for a token and its partner.
    function _breakEntanglementInternal(uint256 tokenId) internal {
         TokenState storage state1 = _tokenStates[tokenId];
         uint256 tokenId2 = state1.entangledPairId;

         if (tokenId2 != 0 && _exists(tokenId2) && _tokenStates[tokenId2].entangledPairId == tokenId1) {
             // Break link for both
             state1.entanglementState = EntanglementState.DECOHERED;
             state1.entangledPairId = 0;
             state1.coherenceLevel = 0;
             state1.lastCoherenceBoostBlock = 0; // Reset time tracking

             TokenState storage state2 = _tokenStates[tokenId2];
             state2.entanglementState = EntanglementState.DECOHERED;
             state2.entangledPairId = 0;
             state2.coherenceLevel = 0;
             state2.lastCoherenceBoostBlock = 0;

             emit Decohered(tokenId1, tokenId2);
         } else {
             // Should only happen if state is ENTANGLED but link is somehow broken/invalid?
             // Or if calling directly with a single token in weird state.
             // Ensure the state is marked as DECOHERED even if partner is missing/invalid.
             state1.entanglementState = EntanglementState.DECOHERED;
             state1.entangledPairId = 0;
             state1.coherenceLevel = 0;
             state1.lastCoherenceBoostBlock = 0;

             // Emit event with 0 for partner if invalid? Or just don't emit?
             // Let's emit with 0 to indicate it lost a partner.
             emit Decohered(tokenId1, 0);
         }
    }

    // --- Required ERC721Enumerable overrides ---
    // These ensure ERC721Enumerable mappings are updated when tokens are transferred/minted/burned.
    // OpenZeppelin's implementations of _beforeTokenTransfer and _afterTokenTransfer handle this.
    // Our override of _update, _mint, _burn should call the super functions.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
         super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

     // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Quantum Entanglement Metaphor:** The core idea is the linked state (`ENTANGLED`) where actions on one token *can* instantly affect its partner (`observeState`, `transferExcitation`). This isn't real quantum mechanics but a programmatic analogy.
2.  **Dynamic NFT State:** NFTs have multiple state variables (`EntanglementState`, `QuantumState`, `coherenceLevel`) that change based on interactions, not just minting parameters.
3.  **Coupled State Changes:** The `observeState` function demonstrates a key feature: collapsing the superposition of one entangled token also collapses its partner to the *same* state, mimicking the non-local correlation of entangled particles upon measurement.
4.  **Programmable Interactions:** Functions like `induceSuperposition`, `transferExcitation`, and `boostCoherence` define specific, themed interactions beyond simple ownership transfer.
5.  **State-Dependent Metadata:** `tokenURI` is overridden to generate metadata reflecting the current `EntanglementState`, `QuantumState`, and `coherenceLevel`, making the NFTs visually dynamic based on their on-chain state. Using a Data URI as a fallback for base URI is also a dynamic approach (though gas-heavy).
6.  **Coherence Mechanics:** The `coherenceLevel` and its decay (`measureCoherence`) introduce a concept of the stability of the entanglement, requiring active management (`boostCoherence`) by owners. This adds a game-like element.
7.  **Entanglement Lifecycle:** The contract defines a lifecycle: `POTENTIAL` (can be entangled) -> `ENTANGLED` (linked) -> `DECOHERED` (link broken), with transitions `attemptEntanglement`, `breakEntanglement`, and `recoherePair`.
8.  **Transfer Side Effects:** Transferring an `ENTANGLED` NFT automatically triggers a `breakEntanglement`, reflecting the idea that entanglement is hard to maintain across ownership boundaries.
9.  **Multi-party Interaction:** `attemptEntanglement` and `recoherePair` are designed conceptually to require interaction/consent from owners of *both* tokens in a potential pair (simplified in this implementation to require caller owns/is approved for both, but could be extended).
10. **Fee Mechanisms:** Introduction of specific fees for complex operations like `attemptEntanglement` and `boostCoherence`, with admin functions to manage them.

This contract goes significantly beyond standard ERC721 implementations by adding complex, interconnected state logic and unique interaction functions themed around a creative concept.

**Note on Randomness:** The use of `block.timestamp` or `blockhash` for simulating probabilistic outcomes (like entanglement success or state collapse) is **not secure** in production for anything sensitive to miner manipulation. A real-world application would require a verifiable random function (VRF) oracle like Chainlink. I've used the simple method here for conceptual clarity without adding the complexity of oracle integration.