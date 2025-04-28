Okay, here is a Solidity smart contract for a concept I'm calling `QuantumGradientNFT`. This contract explores ideas around dynamic state, interaction between tokens (entanglement), probabilistic outcomes (superposition), and time-based evolution, moving beyond standard static NFTs.

It's designed to be interesting and demonstrate several interconnected mechanics. Note that secure, decentralized randomness is a complex topic in Solidity; the random number generation here is illustrative and would require a robust oracle solution (like Chainlink VRF) for any serious production use case.

---

## Contract Outline & Function Summary

**Contract Name:** `QuantumGradientNFT`

**Core Concept:** A non-fungible token representing an evolving, abstract "quantum gradient" entity. Each NFT has a unique, dynamic state influenced by owner actions, time, and potential interactions with other `QuantumGradientNFT`s. The state can enter superposition (probabilistic) and tokens can become entangled (states influence each other).

**Interfaces Implemented (Partially for Concept):**
*   Mimics core ERC-721 functionalities for ownership and transfer.
*   Mimics core ERC-721Metadata functionalities for tokenURI, name, symbol.
*   Mimics core ERC-165 (`supportsInterface`).

**State Variables:**
*   `_tokenCounter`: Tracks the next available token ID.
*   `_owners`: Maps token ID to owner address.
*   `_balances`: Maps owner address to token count.
*   `_tokenApprovals`: Maps token ID to approved address.
*   `_operatorApprovals`: Maps owner to operator address to approval status.
*   `_tokenState`: Maps token ID to its unique `QuantumState` struct.
*   `owner`: Contract owner address (for administrative functions).
*   `isEvolutionPaused`: Global flag to pause time/charge-based evolution.
*   `baseQuantumParameterModifier`: A global modifier affecting the 'quantumParameter' calculation during evolution.

**Structs:**
*   `QuantumState`: Holds the dynamic state of an individual NFT, including charge, quantum parameter, generation, entropy, interaction time, superposition status, and entanglement partner.

**Events:**
*   `Mint`: Emitted when a new token is created.
*   `Transfer`: Emitted when token ownership changes.
*   `Approval`: Emitted when a single token is approved.
*   `ApprovalForAll`: Emitted when an operator is approved for all tokens.
*   `Charge`: Emitted when an NFT is charged.
*   `Evolve`: Emitted when an NFT undergoes evolution.
*   `SuperpositionTriggered`: Emitted when an NFT enters superposition.
*   `SuperpositionResolved`: Emitted when a superposition state is collapsed.
*   `Entangled`: Emitted when two NFTs become entangled.
*   `Decohered`: Emitted when entanglement between two NFTs is broken.
*   `EntropyIncreased`: Emitted when an NFT's entropy increases.
*   `EntropyReduced`: Emitted when an NFT's entropy decreases.
*   `Burn`: Emitted when a token is burned.
*   `GradientApplied`: Emitted when the visual gradient is calculated/applied (conceptually).
*   `BaseQuantumParameterModifierUpdated`: Emitted when the admin modifier changes.
*   `EvolutionPaused`: Emitted when evolution is paused/unpaused.

**Functions (29+):**

1.  `constructor()`: Sets the contract deployer as the owner.
2.  `supportsInterface(bytes4 interfaceId) view returns (bool)`: ERC-165 standard for interface detection (partial implementation).
3.  `balanceOf(address owner) view returns (uint256)`: ERC-721 standard - Returns the number of tokens owned by an address.
4.  `ownerOf(uint256 tokenId) view returns (address)`: ERC-721 standard - Returns the owner of a specific token.
5.  `transferFrom(address from, address to, uint256 tokenId)`: ERC-721 standard - Transfers a token from one address to another.
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC-721 standard - Safe transfer (checks if recipient can receive ERC721 tokens).
7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC-721 standard - Safe transfer with data.
8.  `approve(address to, uint256 tokenId)`: ERC-721 standard - Approves an address to spend a specific token.
9.  `setApprovalForAll(address operator, bool approved)`: ERC-721 standard - Approves or removes an operator for all owner's tokens.
10. `getApproved(uint256 tokenId) view returns (address)`: ERC-721 standard - Gets the approved address for a token.
11. `isApprovedForAll(address owner, address operator) view returns (bool)`: ERC-721 standard - Checks if an operator is approved for an owner.
12. `name() view returns (string memory)`: ERC-721 Metadata standard - Returns the contract name.
13. `symbol() view returns (string memory)`: ERC-721 Metadata standard - Returns the contract symbol.
14. `tokenURI(uint256 tokenId) view returns (string memory)`: ERC-721 Metadata standard - Returns the URI for a token's metadata. This implementation is conceptual and would link to off-chain metadata describing the dynamic state.
15. `mint()`: Mints a new `QuantumGradientNFT` to the caller with initial random-ish state.
16. `burn(uint256 tokenId)`: Destroys a token, owned by the caller or approved address.
17. `chargeNFT(uint256 tokenId, uint256 amount)`: Adds 'charge' to an NFT, potentially consuming caller's resources (e.g., requires Ether, not implemented here but shown conceptually). Increases `chargeLevel`.
18. `evolveNFT(uint256 tokenId)`: Triggers the evolution process for an NFT based on its charge level, time, and entropy. Modifies `quantumParameter`, increases `generation`.
19. `triggerSuperposition(uint256 tokenId)`: Attempts to put an NFT into a superposition state if conditions are met (e.g., high charge, low entropy).
20. `observeNFT(uint256 tokenId)`: Collapses an NFT's superposition state probabilistically, resulting in a state change. Can also trigger minor state updates if not superposed.
21. `entangleNFTs(uint256 tokenId1, uint256 tokenId2)`: Links two NFTs together, causing their states to influence each other during evolution. Requires ownership/approval of both.
22. `decohereNFT(uint256 tokenId)`: Breaks the entanglement link for a given NFT (and its partner).
23. `getQuantumState(uint256 tokenId) view returns (QuantumState memory)`: Returns the full `QuantumState` struct for an NFT.
24. `getEntangledPartner(uint256 tokenId) view returns (uint256)`: Returns the token ID of the NFT's entangled partner (0 if none).
25. `isEntangled(uint256 tokenId) view returns (bool)`: Checks if an NFT is currently entangled.
26. `applyGradientColor(uint256 tokenId) view returns (uint8 r, uint8 g, uint8 b)`: Deterministically calculates an RGB color representation based on the NFT's `quantumParameter` and `generation`. This is the "gradient" visual aspect.
27. `decayEntropy(uint256 tokenId)`: Increases the entropy of an NFT if a certain amount of time has passed since the last interaction.
28. `resetEntropy(uint256 tokenId)`: Reduces an NFT's entropy, typically as a result of owner interaction like charging or observing.
29. `adminSetBaseQuantumParameterModifier(uint256 modifierValue)`: (Owner only) Sets a global modifier for the quantum parameter calculation.
30. `adminPauseEvolution(bool paused)`: (Owner only) Pauses/unpauses global evolution triggered by time/charge.
31. `_requireOwnedOrApproved(uint256 tokenId)`: Internal helper to check ownership or approval.
32. `_updateTokenState(uint256 tokenId, QuantumState memory newState)`: Internal helper to update a token's state and interaction time.
33. `_generateRandomNumber(uint256 seed) internal view returns (uint256)`: **(WARNING: Insecure for production!)** Simple internal random number generation helper using block data.
34. `_mint(address to, uint256 tokenId)`: Internal minting logic.
35. `_burn(uint256 tokenId)`: Internal burning logic.
36. `_transfer(address from, address to, uint256 tokenId)`: Internal transfer logic.
37. `_safeTransfer(address from, address to, uint256 tokenId, bytes memory data)`: Internal safe transfer logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// Note: This contract does *not* inherit directly from OpenZeppelin's ERC721
// to demonstrate custom implementation and avoid direct boilerplate duplication
// as requested, while still providing necessary interfaces for compatibility concepts.

/**
 * @title QuantumGradientNFT
 * @dev A dynamic NFT exploring concepts of state, evolution, superposition, and entanglement.
 *      Each NFT represents an abstract entity whose state (`QuantumState`) changes
 *      based on owner interaction, time, entropy, and potential entanglement with
 *      other NFTs.
 *
 *      WARNING: The random number generation used in this contract for concepts
 *      like superposition collapse is based on block data and is INSECURE
 *      for production use cases where unpredictability is critical. For a
 *      production system, integrate a secure oracle like Chainlink VRF.
 */
contract QuantumGradientNFT is IERC165 {

    // --- State Variables ---

    uint256 private _tokenCounter; // Total number of tokens minted
    mapping(uint256 => address) private _owners; // Token ID to owner address
    mapping(address => uint256) private _balances; // Owner address to token count

    mapping(uint256 => address) private _tokenApprovals; // Token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner to operator to approval status

    struct QuantumState {
        uint256 chargeLevel; // Energy level for evolution
        uint256 quantumParameter; // The core numeric state parameter that evolves
        uint256 generation; // Number of significant evolutions
        uint256 entropy; // Measure of state randomness/decay potential
        uint256 lastInteractionTime; // Timestamp of last owner interaction or state change
        bool isSuperposed; // Is the state probabilistic?
        uint256 entangledWith; // Token ID of entangled partner (0 if none)
    }

    mapping(uint256 => QuantumState) public tokenState; // Token ID to its QuantumState

    address public owner; // Contract owner (for administrative functions)
    bool public isEvolutionPaused; // Global flag to pause time/charge-based evolution

    // A global modifier that influences the quantumParameter calculation during evolution
    // Can be updated by the contract owner to introduce external influence or phases.
    uint256 public baseQuantumParameterModifier = 1000;

    // --- Events ---

    event Mint(address indexed to, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Custom Events
    event Charge(uint256 indexed tokenId, uint256 amount, uint256 newChargeLevel);
    event Evolve(uint256 indexed tokenId, uint256 newQuantumParameter, uint256 newGeneration);
    event SuperpositionTriggered(uint256 indexed tokenId);
    event SuperpositionResolved(uint256 indexed tokenId, uint256 resolvedParameter);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Decohered(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntropyIncreased(uint256 indexed tokenId, uint256 newEntropy);
    event EntropyReduced(uint256 indexed tokenId, uint256 newEntropy);
    event Burn(uint256 indexed tokenId);
    event GradientApplied(uint256 indexed tokenId, uint8 r, uint8 g, uint8 b); // Conceptual visual change
    event BaseQuantumParameterModifierUpdated(uint256 modifierValue);
    event EvolutionPaused(bool paused);

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _tokenCounter = 0;
        isEvolutionPaused = false;
    }

    // --- ERC-165 Interface Support ---

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // Minimal ERC721 interface support
        return interfaceId == 0x80ac58cd || // ERC721
               interfaceId == 0x5b5e139f || // ERC721Metadata
               super.supportsInterface(interfaceId);
    }

    // --- Core ERC-721 Like Functions (Custom Implementation) ---

    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "balance query for zero address");
        return _balances[_owner];
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view returns (address) {
        address ownerAddress = _owners[tokenId];
        require(ownerAddress != address(0), "owner query for nonexistent token");
        return ownerAddress;
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(address from, address to, uint256 tokenId) public {
        // Check ownership and approval
        require(_isApprovedOrOwner(_msgSender(), tokenId), "transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "transfer from incorrect owner");
        require(to != address(0), "transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        // Check ownership and approval
        require(_isApprovedOrOwner(_msgSender(), tokenId), "transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "transfer from incorrect owner");
        require(to != address(0), "transfer to the zero address");

        _safeTransfer(from, to, tokenId, data);
    }

    /// @dev See {IERC721-approve}.
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(_msgSender() == tokenOwner || isApprovedForAll(tokenOwner, _msgSender()), "approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != _msgSender(), "approve forall to operator the caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "approval query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address _owner, address operator) public view returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    // --- ERC-721 Metadata Like Functions (Custom Implementation) ---

    /// @dev See {IERC721Metadata-name}.
    function name() public view returns (string memory) {
        return "QuantumGradient";
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view returns (string memory) {
        return "QGNT";
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    /// @dev This is a conceptual implementation. In a real application, this
    ///      would return a URL pointing to dynamic metadata (e.g., a JSON file)
    ///      hosted off-chain or generated by a service reflecting the current
    ///      on-chain state of the NFT (charge, quantum parameter, etc.).
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Example: A base URI pointing to a metadata service + token ID
        // return string(abi.encodePacked("ipfs://YOUR_BASE_URI/", _toString(tokenId)));
        // For this example, return a placeholder indicating it's dynamic
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(string(abi.encodePacked(
            '{"name":"QuantumGradient #', _toString(tokenId),
            '", "description": "An evolving Quantum Gradient entity.",',
            '"attributes": [',
                '{"trait_type": "Generation", "value": ', _toString(tokenState[tokenId].generation), '},',
                '{"trait_type": "Charge Level", "value": ', _toString(tokenState[tokenId].chargeLevel), '},',
                '{"trait_type": "Quantum Parameter", "value": ', _toString(tokenState[tokenId].quantumParameter), '},',
                '{"trait_type": "Entropy", "value": ', _toString(tokenState[tokenId].entropy), '},',
                '{"trait_type": "Is Superposed", "value": ', tokenState[tokenId].isSuperposed ? "true" : "false", '},',
                '{"trait_type": "Is Entangled", "value": ', tokenState[tokenId].entangledWith != 0 ? "true" : "false", '}',
            ']}'
        ))))));
    }


    // --- Quantum Gradient Mechanics Functions ---

    /// @dev Mints a new QuantumGradientNFT to the caller.
    ///      Initial state is seeded with a value based on the block and token ID.
    function mint() public {
        uint256 newTokenId = _tokenCounter;
        _mint(_msgSender(), newTokenId);

        // Initialize state for the new token
        // Use a simple 'random' seed based on block and token ID
        uint256 initialSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, newTokenId)));

        tokenState[newTokenId] = QuantumState({
            chargeLevel: 100, // Start with some initial charge
            quantumParameter: initialSeed % 10000, // Initial parameter based on seed
            generation: 1,
            entropy: 0,
            lastInteractionTime: block.timestamp,
            isSuperposed: false,
            entangledWith: 0
        });

        _tokenCounter++;
        emit Mint(_msgSender(), newTokenId);
    }

    /// @dev Burns a token. Can only be called by the owner or an approved address.
    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "burn of nonexistent token");
        _requireOwnedOrApproved(tokenId);

        // If entangled, decohere first
        if (tokenState[tokenId].entangledWith != 0) {
            decohereNFT(tokenId); // Automatically decoheres the partner
        }

        _burn(tokenId);
        emit Burn(tokenId);
    }


    /// @dev Charges an NFT, increasing its energy level.
    ///      Conceptual: Could require Ether or another token in a real implementation.
    function chargeNFT(uint256 tokenId, uint256 amount) public {
        require(_exists(tokenId), "charge of nonexistent token");
        _requireOwnedOrApproved(tokenId);
        require(amount > 0, "charge amount must be positive");

        QuantumState storage state = tokenState[tokenId];
        state.chargeLevel += amount;
        _updateTokenState(tokenId, state); // Updates lastInteractionTime

        emit Charge(tokenId, amount, state.chargeLevel);
    }

    /// @dev Triggers the evolution process for an NFT.
    ///      Requires sufficient charge and time elapsed since last interaction/evolution.
    ///      Evolution changes the quantumParameter and increments generation.
    ///      Affected by entropy and global modifier.
    function evolveNFT(uint256 tokenId) public {
        require(_exists(tokenId), "evolve of nonexistent token");
        _requireOwnedOrApproved(tokenId);
        require(!isEvolutionPaused, "evolution is globally paused");

        QuantumState storage state = tokenState[tokenId];
        uint256 timeSinceLastInteraction = block.timestamp - state.lastInteractionTime;

        // Evolution conditions: sufficient charge AND sufficient time AND not superposed
        uint256 minChargeForEvolution = 200 + state.generation * 10; // Evolution gets harder
        uint256 minTimeForEvolution = 1 days; // Needs time to 'process'

        require(state.chargeLevel >= minChargeForEvolution, "not enough charge for evolution");
        require(timeSinceLastInteraction >= minTimeForEvolution, "not enough time elapsed for evolution");
        require(!state.isSuperposed, "cannot evolve while in superposition");

        // Calculate new quantum parameter based on current state, charge, entropy, and modifier
        // This formula is illustrative and can be made more complex
        uint256 evolutionSeed = _generateRandomNumber(uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, state.chargeLevel, state.entropy))));
        uint256 evolutionFactor = (state.chargeLevel / minChargeForEvolution) * (timeSinceLastInteraction / minTimeForEvolution);

        uint256 newQuantumParameter = (state.quantumParameter * evolutionFactor + evolutionSeed + baseQuantumParameterModifier) % 100000;

        // Apply entanglement influence if entangled
        if (state.entangledWith != 0) {
            QuantumState storage partnerState = tokenState[state.entangledWith];
            // Partner's parameter influences the evolution
            newQuantumParameter = (newQuantumParameter + partnerState.quantumParameter / 10) % 100000;
            // Entanglement can also affect charge or entropy transfer
            if (state.chargeLevel > partnerState.chargeLevel) {
                uint256 chargeTransfer = (state.chargeLevel - partnerState.chargeLevel) / 10; // 10% transfer
                state.chargeLevel -= chargeTransfer;
                partnerState.chargeLevel += chargeTransfer;
            }
        }

        // Update state after evolution
        state.quantumParameter = newQuantumParameter;
        state.generation++;
        state.chargeLevel = state.chargeLevel > minChargeForEvolution ? state.chargeLevel - minChargeForEvolution : 0; // Consume charge
        state.entropy = state.entropy > 0 ? state.entropy - 5 : 0; // Evolution reduces entropy
        _updateTokenState(tokenId, state);

        // Update partner state if entangled (needs separate update due to storage reference)
        if (state.entangledWith != 0) {
             _updateTokenState(state.entangledWith, tokenState[state.entangledWith]);
        }


        emit Evolve(tokenId, state.quantumParameter, state.generation);
    }

    /// @dev Attempts to put an NFT into a superposition state.
    ///      Requires sufficient charge and low entropy.
    function triggerSuperposition(uint256 tokenId) public {
        require(_exists(tokenId), "trigger superposition on nonexistent token");
        _requireOwnedOrApproved(tokenId);
        require(!tokenState[tokenId].isSuperposed, "token is already superposed");
        require(tokenState[tokenId].chargeLevel >= 500, "not enough charge to enter superposition"); // Requires significant charge
        require(tokenState[tokenId].entropy <= 20, "entropy too high for superposition"); // Requires low entropy

        QuantumState storage state = tokenState[tokenId];
        state.isSuperposed = true;
        state.chargeLevel -= 500; // Consume charge
        _updateTokenState(tokenId, state);

        emit SuperpositionTriggered(tokenId);
    }

    /// @dev Observes a superposed NFT, collapsing its state probabilistically.
    ///      Can also trigger a minor state update or entropy reduction if not superposed.
    function observeNFT(uint256 tokenId) public {
        require(_exists(tokenId), "observe of nonexistent token");
        _requireOwnedOrApproved(tokenId);

        QuantumState storage state = tokenState[tokenId];

        if (state.isSuperposed) {
            // Simulate superposition collapse with insecure randomness
            uint256 collapseSeed = _generateRandomNumber(uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, state.quantumParameter))));
            uint256 outcome = collapseSeed % 100; // 0-99

            uint256 resolvedParameter;
            // Example outcomes:
            if (outcome < 30) { // 30% chance: Parameter increases slightly
                resolvedParameter = state.quantumParameter + (collapseSeed % 100);
            } else if (outcome < 60) { // 30% chance: Parameter decreases slightly
                resolvedParameter = state.quantumParameter > (collapseSeed % 50) ? state.quantumParameter - (collapseSeed % 50) : 0;
            } else if (outcome < 90) { // 30% chance: Parameter jumps significantly
                 resolvedParameter = (state.quantumParameter + (collapseSeed % 1000) + baseQuantumParameterModifier) % 100000;
            } else { // 10% chance: Parameter resets or undergoes unexpected shift
                resolvedParameter = collapseSeed % 500;
            }

            state.quantumParameter = resolvedParameter;
            state.isSuperposed = false; // Collapse happens
            state.entropy = state.entropy > 10 ? state.entropy - 10 : 0; // Observing reduces entropy
            _updateTokenState(tokenId, state);

            emit SuperpositionResolved(tokenId, resolvedParameter);

        } else {
            // If not superposed, simply interacting reduces entropy and updates time
            state.entropy = state.entropy > 5 ? state.entropy - 5 : 0;
             _updateTokenState(tokenId, state);
            emit EntropyReduced(tokenId, state.entropy);
            // Optionally emit a simple "Observed" event
        }
    }

    /// @dev Entangles two NFTs. Their states will influence each other during evolution.
    ///      Requires ownership or approval for both tokens.
    function entangleNFTs(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "tokenId1 does not exist");
        require(_exists(tokenId2), "tokenId2 does not exist");
        require(tokenId1 != tokenId2, "cannot entangle a token with itself");
        require(_requireOwnedOrApproved(tokenId1), "caller not authorized for tokenId1");
        require(_requireOwnedOrApproved(tokenId2), "caller not authorized for tokenId2");
        require(tokenState[tokenId1].entangledWith == 0, "tokenId1 is already entangled");
        require(tokenState[tokenId2].entangledWith == 0, "tokenId2 is already entangled");

        // Prevent entanglement if either is superposed (quantum rule!)
        require(!tokenState[tokenId1].isSuperposed, "cannot entangle a superposed token");
        require(!tokenState[tokenId2].isSuperposed, "cannot entangle a superposed token");


        QuantumState storage state1 = tokenState[tokenId1];
        QuantumState storage state2 = tokenState[tokenId2];

        state1.entangledWith = tokenId2;
        state2.entangledWith = tokenId1;

        // Entangling might cost charge or increase entropy slightly
        state1.chargeLevel = state1.chargeLevel > 50 ? state1.chargeLevel - 50 : 0;
        state2.chargeLevel = state2.chargeLevel > 50 ? state2.chargeLevel - 50 : 0;
        state1.entropy += 5;
        state2.entropy += 5;

        _updateTokenState(tokenId1, state1);
        _updateTokenState(tokenId2, state2);

        emit Entangled(tokenId1, tokenId2);
    }

    /// @dev Breaks the entanglement link for an NFT and its partner.
    function decohereNFT(uint256 tokenId) public {
        require(_exists(tokenId), "decohere of nonexistent token");
        _requireOwnedOrApproved(tokenId);

        QuantumState storage state = tokenState[tokenId];
        uint256 partnerTokenId = state.entangledWith;

        require(partnerTokenId != 0, "token is not entangled");

        // Decoherence might slightly alter the parameter or increase entropy
        state.quantumParameter = (state.quantumParameter + state.entropy) % 100000;
        state.entropy += 10; // Decoherence increases entropy

        state.entangledWith = 0; // Break link

         _updateTokenState(tokenId, state);

        // Update partner state (needs to be done separately)
        QuantumState storage partnerState = tokenState[partnerTokenId];
        partnerState.entangledWith = 0; // Break partner's link
        partnerState.quantumParameter = (partnerState.quantumParameter + partnerState.entropy) % 100000;
        partnerState.entropy += 10;
        _updateTokenState(partnerTokenId, partnerState);


        emit Decohered(tokenId, partnerTokenId);
    }

    /// @dev Returns the full QuantumState struct for a given token ID.
    function getQuantumState(uint256 tokenId) public view returns (QuantumState memory) {
        require(_exists(tokenId), "query for nonexistent token");
        return tokenState[tokenId];
    }

    /// @dev Returns the token ID of the entangled partner (0 if none).
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "query for nonexistent token");
         return tokenState[tokenId].entangledWith;
    }

     /// @dev Checks if a token is currently entangled.
    function isEntangled(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "query for nonexistent token");
         return tokenState[tokenId].entangledWith != 0;
    }

    /// @dev Deterministically calculates an RGB color representation based on the NFT's state.
    ///      This provides a simple 'visual' gradient based on the quantumParameter and generation.
    function applyGradientColor(uint256 tokenId) public view returns (uint8 r, uint8 g, uint8 b) {
        require(_exists(tokenId), "query for nonexistent token");
        QuantumState memory state = tokenState[tokenId];

        // Simple mapping of state to color - replace with complex logic for visual representation
        uint256 param = state.quantumParameter;
        uint256 gen = state.generation;
        uint256 maxParam = 100000; // Max possible quantum parameter
        uint256 maxGen = 100; // Assume a max generation for scaling color

        // Scale parameters to 0-255 range
        r = uint8((param * 255) / maxParam);
        g = uint8((gen * 255) / maxGen);
        b = uint8(((param + gen) % maxParam * 255) / maxParam); // Combination of param and gen

        // Add some influence from charge/entropy
        r = uint8(r + state.chargeLevel / 100 > 255 ? 255 : r + state.chargeLevel / 100);
        g = uint8(g + state.entropy > 255 ? 255 : g + state.entropy);

        // Clamp values
        r = r > 255 ? 255 : r;
        g = g > 255 ? 255 : g;
        b = b > 255 ? 255 : b;

        emit GradientApplied(tokenId, r, g, b); // Emit event conceptually for off-chain use

        return (r, g, b);
    }

    /// @dev Increases the entropy of an NFT if enough time has passed since last interaction.
    function decayEntropy(uint256 tokenId) public {
        require(_exists(tokenId), "decay entropy of nonexistent token");

        QuantumState storage state = tokenState[tokenId];
        uint256 timeSinceLastInteraction = block.timestamp - state.lastInteractionTime;
        uint256 entropyDecayInterval = 6 hours; // Entropy increases every 6 hours without interaction
        uint256 maxEntropy = 100;

        if (timeSinceLastInteraction >= entropyDecayInterval && state.entropy < maxEntropy) {
            uint256 potentialIncrease = timeSinceLastInteraction / entropyDecayInterval;
            uint256 actualIncrease = state.entropy + potentialIncrease > maxEntropy ? maxEntropy - state.entropy : potentialIncrease;
            state.entropy += actualIncrease;
            _updateTokenState(tokenId, state); // Update interaction time only if entropy increased

            emit EntropyIncreased(tokenId, state.entropy);
        }
        // Note: This function can be called by anyone, but it only affects state if time has passed.
        // A more advanced version might use a keeper network to trigger this reliably.
    }

    /// @dev Reduces the entropy of an NFT. Typically called internally after owner interactions,
    ///      but exposed here for explicit management if needed (e.g., 'cleaning' the NFT).
    function resetEntropy(uint256 tokenId) public {
         require(_exists(tokenId), "reset entropy of nonexistent token");
        _requireOwnedOrApproved(tokenId);

        QuantumState storage state = tokenState[tokenId];
        state.entropy = state.entropy > 10 ? state.entropy - 10 : 0; // Reduce by a fixed amount
        _updateTokenState(tokenId, state);

        emit EntropyReduced(tokenId, state.entropy);
    }

    // --- Administrative Functions (Owner Only) ---

    /// @dev Allows the contract owner to update the global modifier affecting quantum parameter evolution.
    /// @param modifierValue The new value for the base quantum parameter modifier.
    function adminSetBaseQuantumParameterModifier(uint256 modifierValue) public onlyOwner {
        baseQuantumParameterModifier = modifierValue;
        emit BaseQuantumParameterModifierUpdated(modifierValue);
    }

    /// @dev Allows the contract owner to pause/unpause global evolution triggered by time/charge.
    /// @param paused True to pause evolution, false to unpause.
    function adminPauseEvolution(bool paused) public onlyOwner {
        isEvolutionPaused = paused;
        emit EvolutionPaused(paused);
    }

    // --- Internal Helper Functions ---

    /// @dev Checks if a token exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /// @dev Checks if the caller is the owner or an approved address for the token.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }

    /// @dev Internal function to update a token's state and refresh its last interaction time.
    function _updateTokenState(uint256 tokenId, QuantumState memory newState) internal {
        tokenState[tokenId] = newState;
        tokenState[tokenId].lastInteractionTime = block.timestamp; // Update interaction time on any state change
    }

    /// @dev Internal random number generation helper. INSECURE FOR PRODUCTION.
    /// @param seed An additional seed for variation.
    ///      Uses block hash, block timestamp, and caller address which are easily manipulable.
    function _generateRandomNumber(uint256 seed) internal view returns (uint256) {
         // WARNING: This is for demonstration ONLY. Do NOT use this for anything
         // where security or real unpredictability is required in production.
         // Use Chainlink VRF or a similar provably fair randomness solution.
         return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, msg.sender, seed)));
    }


    /// @dev Internal mint logic.
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "token already minted");

        _owners[tokenId] = to;
        _balances[to]++;
        // Initial state will be set in the public mint() function
    }

    /// @dev Internal burn logic.
    function _burn(uint256 tokenId) internal {
        address tokenOwner = ownerOf(tokenId);

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[tokenOwner]--;
        _owners[tokenId] = address(0);
        delete tokenState[tokenId]; // Remove state data
    }

    /// @dev Internal transfer logic.
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "transfer from incorrect owner");
        require(to != address(0), "transfer to the zero address");

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        // Note: Transfer does not automatically trigger evolution or other state changes,
        // but it updates the lastInteractionTime via _updateTokenState if called within a state-changing function.
        // For a simple transfer, no state update is inherently needed unless designed otherwise.
        // The lastInteractionTime is updated by functions that modify state.
    }

    /// @dev Internal safe transfer logic.
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
         _transfer(from, to, tokenId);

         // Check if the recipient is a contract and can receive ERC721 tokens
         uint256 codeSize;
         assembly { codeSize := extcodesize(to) }

         if (codeSize > 0) {
             require(
                 IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) == IERC721Receiver.onERC721Received.selector,
                 "transfer to non ERC721Receiver implementer"
             );
         }
    }

    // --- Utility Helpers ---

    /// @dev Converts a uint256 to a string. From OpenZeppelin.
    function _toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    // --- Base64 Utility (Minimal for conceptual tokenURI) ---
    // From OpenZeppelin's ERC721URIStorage

    bytes internal constant _BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function Base64_encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // store the original data length
        uint256 dataLength = data.length;

        // Calculate the number of blocks
        uint256 blocks = dataLength / 3;
        uint256 extra = dataLength % 3; // amount of trailing bytes
        bytes memory encoded = new bytes(4 * blocks + (extra == 0 ? 0 : extra + 1) + (extra == 2 ? 1 : 0));

        // Encode full blocks
        for (uint256 i = 0; i < blocks; i++) {
            encoded[i * 4] = _BASE64_ALPHABET[(uint8(data[i * 3]) >> 2)];
            encoded[i * 4 + 1] = _BASE64_ALPHABET[((uint8(data[i * 3]) & 0x03) << 4) | (uint8(data[i * 3 + 1]) >> 4)];
            encoded[i * 4 + 2] = _BASE64_ALPHABET[((uint8(data[i * 3 + 1]) & 0x0f) << 2) | (uint8(data[i * 3 + 2]) >> 6)];
            encoded[i * 4 + 3] = _BASE64_ALPHABET[(uint8(data[i * 3 + 2]) & 0x3f)];
        }

        // Handle trailing bytes
        if (extra == 1) {
            encoded[blocks * 4] = _BASE64_ALPHABET[(uint8(data[blocks * 3]) >> 2)];
            encoded[blocks * 4 + 1] = _BASE64_ALPHABET[(uint8(data[blocks * 3]) & 0x03) << 4];
            encoded[blocks * 4 + 2] = '=';
            encoded[blocks * 4 + 3] = '=';
        } else if (extra == 2) {
            encoded[blocks * 4] = _BASE64_ALPHABET[(uint8(data[blocks * 3]) >> 2)];
            encoded[blocks * 4 + 1] = _BASE64_ALPHABET[((uint8(data[blocks * 3]) & 0x03) << 4) | (uint8(data[blocks * 3 + 1]) >> 4)];
            encoded[blocks * 4 + 2] = _BASE64_ALPHABET[(uint8(data[blocks * 3 + 1]) & 0x0f) << 2];
            encoded[blocks * 4 + 3] = '=';
        }

        return string(encoded);
    }
}

// Simple implementation of minimal IERC721Receiver for safeTransferFrom compatibility
// This would typically be imported or defined elsewhere if transferring to other contracts.
// Included here for self-contained conceptual example.
abstract contract MinimalERC721Receiver is IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external virtual override returns (bytes4) {
        // By default, assume contract can receive NFTs unless overridden
        return IERC721Receiver.onERC721Received.selector;
    }
}
```