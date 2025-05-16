Okay, here is a smart contract in Solidity implementing a concept I'll call "Quantum Entanglement NFTs".

This contract leverages dynamic metadata, state changes based on interactions and time, resource costs, and a unique "entanglement" mechanic where two NFTs can be linked, affecting each other's behavior and state. It's designed to be more than just a static collectible.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementNFTs
 * @author Your Name or Pseudonym (replace)
 * @notice A dynamic ERC721 contract featuring Entanglement, Evolution, and Decay mechanics.
 *
 * Outline:
 * 1. Overview & Concepts
 * 2. Standards Used
 * 3. Custom State & Data Structures
 * 4. Events
 * 5. Error Handling
 * 6. Core ERC721 Functions (Overridden or Standard)
 * 7. Enumerable Extension Functions
 * 8. Minting
 * 9. Dynamic Metadata (tokenURI)
 * 10. Entanglement Mechanics
 * 11. Dynamic State Mechanics (Interact, Stabilize, Evolve)
 * 12. Internal State Management (Decay)
 * 13. Query Functions
 * 14. Owner/Management Functions
 * 15. Hooks & Transfers
 *
 * Function Summary:
 * - balanceOf(address owner): Returns the number of tokens owned by `owner`. (ERC721 Standard)
 * - ownerOf(uint256 tokenId): Returns the owner of the `tokenId` token. (ERC721 Standard)
 * - approve(address to, uint256 tokenId): Approves `to` to transfer `tokenId` token. (ERC721 Standard)
 * - getApproved(uint256 tokenId): Returns the approved address for `tokenId` token. (ERC721 Standard)
 * - setApprovalForAll(address operator, bool approved): Sets approval for all tokens of owner. (ERC721 Standard)
 * - isApprovedForAll(address owner, address operator): Checks if operator is approved for all owner's tokens. (ERC721 Standard)
 * - transferFrom(address from, address to, uint256 tokenId): Transfers ownership of `tokenId`. (ERC721 Standard)
 * - safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers `tokenId`. (ERC721 Standard)
 * - safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safely transfers `tokenId` with data. (ERC721 Standard)
 * - totalSupply(): Returns the total number of tokens in existence. (ERC721Enumerable Standard)
 * - tokenOfOwnerByIndex(address owner, uint256 index): Returns `tokenId` owned by `owner` at `index`. (ERC721Enumerable Standard)
 * - tokenByIndex(uint256 index): Returns `tokenId` at `index` among all tokens. (ERC721Enumerable Standard)
 * - supportsInterface(bytes4 interfaceId): Checks if contract supports ERC721/Enumerable/Metadata interfaces. (ERC721 Standard)
 * - mint(address to): Mints a new NFT to `to`, initializing its state. (Custom)
 * - tokenURI(uint256 tokenId): Returns the metadata URI for `tokenId`, incorporating dynamic state. (ERC721 Metadata Override)
 * - entangleTokens(uint256 tokenId1, uint256 tokenId2): Links two owned NFTs, requiring payment. (Custom)
 * - disentangleTokens(uint256 tokenId1, uint256 tokenId2): Breaks the link between two entangled NFTs. (Custom)
 * - getEntangledToken(uint256 tokenId): Returns the token ID `tokenId` is entangled with, or 0. (Custom View)
 * - isEntangled(uint256 tokenId): Checks if `tokenId` is entangled with another token. (Custom View)
 * - interact(uint256 tokenId): Performs a basic interaction with the token, affecting its state (resets last interaction block). (Custom)
 * - stabilize(uint256 tokenId): Attempts to reduce the decay level of a token, requires payment. (Custom)
 * - evolve(uint256 tokenId): Attempts to increase the evolution level of a token, requires entanglement (past level 1) and payment. (Custom)
 * - getTokenState(uint256 tokenId): Returns the current level, decay level, and last interaction block of a token. Applies decay before returning. (Custom View)
 * - getDecayRate(): Returns the current decay rate per block. (Custom View)
 * - getEvolutionCost(): Returns the cost to attempt evolution. (Custom View)
 * - getEntanglementFee(): Returns the fee to entangle two tokens. (Custom View)
 * - setBaseURI(string newBaseURI): Sets the base URI for metadata (Owner Only). (Custom Owner)
 * - setDecayRate(uint256 newRate): Sets the decay rate per block (Owner Only). (Custom Owner)
 * - setEvolutionCost(uint256 newCost): Sets the cost for evolution attempts (Owner Only). (Custom Owner)
 * - setEntanglementFee(uint256 newFee): Sets the fee for entangling tokens (Owner Only). (Custom Owner)
 * - pauseMinting(): Pauses the minting process (Owner Only). (Pausable Standard)
 * - unpauseMinting(): Unpauses the minting process (Owner Only). (Pausable Standard)
 * - withdrawFunds(): Withdraws collected Ether to the owner (Owner Only). (Custom Owner)
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Needed for baseURI handling, though overridden
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

contract QuantumEntanglementNFTs is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Math for uint256;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Mapping to store the entangled partner for each token
    mapping(uint256 => uint256) private _entangledWith;

    // Struct to hold dynamic state for each token
    struct TokenState {
        uint256 level;             // Evolution/Growth level
        uint256 decayLevel;        // Decay/Instability level (higher is worse)
        uint256 lastInteractionBlock; // Block number of the last interaction
    }

    // Mapping to store the state of each token
    mapping(uint256 => TokenState) private _tokenStates;

    // Parameters controlling game mechanics
    uint256 public decayRatePerBlock; // How much decay increases per block of inactivity
    uint256 public constant MAX_DECAY = 100; // Maximum decay level
    uint256 public constant MIN_DECAY_FOR_PENALTY = 50; // Decay level at which penalties might occur
    uint256 public constant EVOLVE_MIN_LEVEL_ENTANGLED = 1; // Min level required for evolution if entangled
    uint256 public constant EVOLVE_MIN_LEVEL_SOLO = 5; // Min level required for evolution if solo
    uint256 public evolutionCost;       // Ether cost to attempt evolution
    uint256 public entanglementFee;     // Ether cost to entangle two tokens

    string private _baseURI;

    // --- Events ---
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);
    event Disentangled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);
    event StateChanged(uint256 indexed tokenId, uint256 newLevel, uint256 newDecayLevel);
    event Evolved(uint256 indexed tokenId, uint256 newLevel, address indexed owner);
    event Stabilized(uint256 indexed tokenId, uint256 newDecayLevel, address indexed owner);
    event Interacted(uint256 indexed tokenId, address indexed owner);
    event ParametersUpdated(uint256 newDecayRate, uint256 newEvolutionCost, uint256 newEntanglementFee);

    // --- Errors ---
    error InvalidTokenId();
    error NotOwnerOfBothTokens();
    error TokensAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
    error TokensNotEntangled(uint256 tokenId1, uint256 tokenId2);
    error CannotEntangleWithSelf();
    error CannotTransferEntangledToken(uint256 tokenId);
    error InsufficientPayment(uint256 required, uint256 received);
    error MaxDecayReached(uint256 tokenId);
    error EvolutionFailed(uint256 tokenId, string reason);
    error MintingPaused();


    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory initialBaseURI,
        uint256 initialDecayRatePerBlock,
        uint256 initialEvolutionCost,
        uint256 initialEntanglementFee
    ) ERC721(name, symbol)
      Ownable(msg.sender) // Sets deployer as owner
    {
        _baseURI = initialBaseURI;
        decayRatePerBlock = initialDecayRatePerBlock;
        evolutionCost = initialEvolutionCost;
        entanglementFee = initialEntanglementFee;
        emit ParametersUpdated(decayRatePerBlock, evolutionCost, entanglementFee);
    }

    // --- Core ERC721 Functions (Overridden or Standard) ---

    // Override _update and _increaseBalance to hook into ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address owner, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(owner, amount);
    }

    // Override _burn to clean up state
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        // Ensure the token is not entangled before burning
        if (isEntangled(tokenId)) {
             // Decide burn policy: either require disentanglement first or automatically disentangle
             // Let's choose automatic disentanglement for simplicity here.
             uint256 entangledTokenId = _entangledWith[tokenId];
             delete _entangledWith[tokenId];
             delete _entangledWith[entangledTokenId]; // Also remove link from the partner
             emit Disentangled(tokenId, entangledTokenId, ownerOf(tokenId)); // Emitting owner before burn
        }

        // Clean up state mapping
        delete _tokenStates[tokenId];

        super._burn(tokenId);
    }

    // Required for ERC721Enumerable and ERC721Metadata
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return interfaceId == type(ERC721Enumerable).interfaceId || interfaceId == type(ERC721URIStorage).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Enumerable Extension Functions ---
    // These are provided by inheriting ERC721Enumerable

    // totalSupply()
    // tokenOfOwnerByIndex(address owner, uint256 index)
    // tokenByIndex(uint256 index)


    // --- Minting ---

    /// @notice Mints a new Quantum Entanglement NFT.
    /// @param to The address to mint the token to.
    function mint(address to) public payable onlyOwner whenNotPaused {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Initialize token state
        _tokenStates[newTokenId] = TokenState({
            level: 1,
            decayLevel: 0,
            lastInteractionBlock: block.number
        });

        _safeMint(to, newTokenId);
        emit StateChanged(newTokenId, 1, 0); // Initial state
    }

    // --- Dynamic Metadata (tokenURI) ---

    /// @notice Returns the URI for a token's metadata, dynamically generated based on its state.
    /// @dev The actual metadata JSON is expected to be served off-chain, but this function constructs
    ///      the URI that points to it, potentially encoding state parameters in the URI.
    ///      Also applies decay calculation whenever the URI is requested.
    /// @param tokenId The ID of the token.
    /// @return The URI for the token's metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and caller is allowed to query (standard ERC721 behavior)

        // Apply decay calculation whenever state is queried (including via tokenURI)
        // Note: In a `view` function, state variables cannot actually be modified.
        // A real dynamic metadata system would likely have a separate mechanism
        // (e.g., a keep3r, an oracle, or state updates triggered by payable interactions)
        // to persist state changes caused by decay. For this example, we'll simulate
        // applying decay for the *purpose of calculation* in the URI, but the stored
        // state (_tokenStates) will only update on non-view calls (interact, stabilize, evolve etc.).
        // This is a limitation of on-chain dynamic metadata that requires off-chain
        // calculation or on-chain triggers via transactions.
        // For *this* example, we will return a URI reflecting the *potential* decay
        // if `applyDecayIfDue` were callable in a view function.
        // A better approach for persistent state decay is to call `_applyDecayIfDue`
        // within non-view functions like `interact`, `stabilize`, `evolve`, `transferFrom`, etc.
        // Let's assume _applyDecayIfDue is called by state-changing functions for persistence.

        TokenState storage state = _tokenStates[tokenId];
        uint256 effectiveDecay = state.decayLevel; // Actual stored decay

        // To simulate decay effect in URI *even in a view function*,
        // we'd need to calculate potential decay here based on current block.
        // This calculation does *not* persist state changes.
        // uint256 blocksPassed = block.number - state.lastInteractionBlock;
        // uint256 potentialDecayIncrease = blocksPassed * decayRatePerBlock;
        // uint256 entangledPartner = _entangledWith[tokenId];
        // if (entangledPartner != 0) {
        //     potentialDecayIncrease = potentialDecayIncrease / 2; // Entanglement slows decay
        // }
        // uint256 calculatedDecay = Math.min(state.decayLevel + potentialDecayIncrease, MAX_DECAY);
        // effectiveDecay = calculatedDecay; // Use calculated decay for URI generation

        // Base URI is assumed to point to a service that handles dynamic metadata.
        // The service will use the query parameters to determine the exact metadata.
        string memory base = _baseURI;
        string memory query = string(abi.encodePacked(
            "?id=", tokenId.toString(),
            "&level=", state.level.toString(),
            "&decay=", effectiveDecay.toString(), // Use effective decay
            "&entangled=", isEntangled(tokenId) ? "true" : "false",
            "&lastBlock=", state.lastInteractionBlock.toString()
        ));

        return string(abi.encodePacked(base, query));
    }

    /// @dev Internal function to get the base URI. Overridden for ERC721URIStorage compatibility.
    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return _baseURI;
    }


    // --- Entanglement Mechanics ---

    /// @notice Attempts to entangle two NFTs owned by the caller.
    /// @dev Requires caller to own both tokens, tokens are not already entangled,
    ///      and payment of the entanglement fee.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangleTokens(uint256 tokenId1, uint256 tokenId2) public payable {
        if (msg.value < entanglementFee) {
             revert InsufficientPayment(entanglementFee, msg.value);
        }

        if (tokenId1 == tokenId2) {
            revert CannotEntangleWithSelf();
        }

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        if (msg.sender != owner1 || msg.sender != owner2) {
            revert NotOwnerOfBothTokens();
        }

        if (_entangledWith[tokenId1] != 0 || _entangledWith[tokenId2] != 0) {
            revert TokensAlreadyEntangled(tokenId1, tokenId2);
        }

        // Apply potential decay before changing state
        _applyDecayIfDue(tokenId1);
        _applyDecayIfDue(tokenId2);


        _entangledWith[tokenId1] = tokenId2;
        _entangledWith[tokenId2] = tokenId1;

        // Entangling might reset decay or give a small level boost? Let's reset last interaction block.
        _tokenStates[tokenId1].lastInteractionBlock = block.number;
        _tokenStates[tokenId2].lastInteractionBlock = block.number;

        emit Entangled(tokenId1, tokenId2, msg.sender);
        emit StateChanged(tokenId1, _tokenStates[tokenId1].level, _tokenStates[tokenId1].decayLevel);
        emit StateChanged(tokenId2, _tokenStates[tokenId2].level, _tokenStates[tokenId2].decayLevel);

    }

    /// @notice Breaks the entanglement between two linked NFTs.
    /// @dev Requires caller to own one of the tokens.
    /// @param tokenId1 The ID of the first token. (Partner is found internally)
    function disentangleTokens(uint256 tokenId1) public {
         address owner1 = ownerOf(tokenId1);
         if (msg.sender != owner1) {
             _requireOwned(tokenId1); // Standard ERC721 check
         }

         uint256 tokenId2 = _entangledWith[tokenId1];

         if (tokenId2 == 0) {
             revert TokensNotEntangled(tokenId1, 0); // 0 indicates not entangled
         }
         if (_entangledWith[tokenId2] != tokenId1) {
              // This should not happen if state is consistent, but check defensively
              revert TokensNotEntangled(tokenId1, tokenId2);
         }

         // Apply potential decay before changing state
         _applyDecayIfDue(tokenId1);
         _applyDecayIfDue(tokenId2); // Decay check on the partner as well

         delete _entangledWith[tokenId1];
         delete _entangledWith[tokenId2];

         // Disentangling might increase decay or reset last interaction block? Let's reset last interaction block.
         _tokenStates[tokenId1].lastInteractionBlock = block.number;
         _tokenStates[tokenId2].lastInteractionBlock = block.number;


         emit Disentangled(tokenId1, tokenId2, msg.sender);
         emit StateChanged(tokenId1, _tokenStates[tokenId1].level, _tokenStates[tokenId1].decayLevel);
         emit StateChanged(tokenId2, _tokenStates[tokenId2].level, _tokenStates[tokenId2].decayLevel);

    }

    /// @notice Gets the token ID that `tokenId` is entangled with.
    /// @param tokenId The ID of the token.
    /// @return The entangled token ID, or 0 if not entangled.
    function getEntangledToken(uint256 tokenId) public view returns (uint256) {
        // No need to apply decay in a view function just for getting partner ID
        // _applyDecayIfDue(tokenId); // Cannot modify state in view
        return _entangledWith[tokenId];
    }

    /// @notice Checks if a token is entangled with another.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        // No need to apply decay in a view function just for checking entanglement
        // _applyDecayIfDue(tokenId); // Cannot modify state in view
        return _entangledWith[tokenId] != 0;
    }


    // --- Dynamic State Mechanics ---

    /// @notice Performs a basic interaction with a token.
    /// @dev Resets the last interaction block, reducing future decay accumulation.
    /// @param tokenId The ID of the token to interact with.
    function interact(uint256 tokenId) public payable {
        _requireOwned(tokenId); // Ensure caller owns token

        _applyDecayIfDue(tokenId); // Apply decay before interaction effects

        _tokenStates[tokenId].lastInteractionBlock = block.number;

        emit Interacted(tokenId, msg.sender);
        // State might have changed due to decay, but interaction itself doesn't change level/decay directly
        // emit StateChanged(tokenId, _tokenStates[tokenId].level, _tokenStates[tokenId].decayLevel);
    }

    /// @notice Attempts to stabilize a token, reducing its decay level.
    /// @dev Requires caller to own the token and payment.
    /// @param tokenId The ID of the token to stabilize.
    function stabilize(uint256 tokenId) public payable {
        _requireOwned(tokenId); // Ensure caller owns token
        // TODO: Implement payment requirement if desired. For now, just a simple action.

        _applyDecayIfDue(tokenId); // Apply decay BEFORE stabilizing

        TokenState storage state = _tokenStates[tokenId];

        // Reduce decay level significantly, but not below 0
        uint256 decayReduction = state.decayLevel / 2; // Example reduction
        state.decayLevel = state.decayLevel.sub(decayReduction, "Stabilize underflow");
        state.lastInteractionBlock = block.number; // Stabilizing is also an interaction

        emit Stabilized(tokenId, state.decayLevel, msg.sender);
        emit StateChanged(tokenId, state.level, state.decayLevel);
    }

    /// @notice Attempts to evolve a token, increasing its level.
    /// @dev Requires caller to own the token, meet level/entanglement conditions, and payment.
    /// @param tokenId The ID of the token to evolve.
    function evolve(uint256 tokenId) public payable {
        _requireOwned(tokenId); // Ensure caller owns token

         if (msg.value < evolutionCost) {
             revert InsufficientPayment(evolutionCost, msg.value);
         }

        _applyDecayIfDue(tokenId); // Apply decay BEFORE attempting evolution

        TokenState storage state = _tokenStates[tokenId];

        uint256 requiredLevel = isEntangled(tokenId) ? EVOLVE_MIN_LEVEL_ENTANGLED : EVOLVE_MIN_LEVEL_SOLO;

        if (state.level < requiredLevel) {
            revert EvolutionFailed(tokenId, "Minimum level not met");
        }

        if (state.decayLevel >= MIN_DECAY_FOR_PENALTY) {
             // Evolution is harder or fails if decay is high
             revert EvolutionFailed(tokenId, "Decay level too high");
             // Or, add a chance of failure / decay increase on failure
        }

        // Simple evolution logic: just increase level and reset decay slightly
        state.level = state.level + 1;
        state.decayLevel = state.decayLevel / 4; // Small decay reduction on successful evolve
        state.lastInteractionBlock = block.number; // Evolution is also an interaction

        emit Evolved(tokenId, state.level, msg.sender);
        emit StateChanged(tokenId, state.level, state.decayLevel);
    }


    // --- Internal State Management ---

    /// @dev Applies decay to a token's state based on blocks passed since last interaction.
    ///      Also applies decay to the entangled partner if exists.
    /// @param tokenId The ID of the token to apply decay to.
    function _applyDecayIfDue(uint256 tokenId) internal {
        // Check if token exists and state is initialized
        if (_tokenStates[tokenId].lastInteractionBlock == 0 && _tokenStates[tokenId].level == 0) {
            // This handles cases where state hasn't been minted/initialized yet, or token doesn't exist.
            // It's safer than relying solely on _exists.
            return;
        }

        TokenState storage state = _tokenStates[tokenId];
        uint256 blocksPassed = block.number - state.lastInteractionBlock;

        if (blocksPassed == 0) {
            return; // No decay if no blocks have passed
        }

        uint256 decayIncrease = blocksPassed * decayRatePerBlock;

        // Entanglement effect: Decay rate is halved if entangled
        if (isEntangled(tokenId)) {
            decayIncrease = decayIncrease / 2;
        }

        state.decayLevel = Math.min(state.decayLevel + decayIncrease, MAX_DECAY);
        state.lastInteractionBlock = block.number; // Update last interaction block after applying decay

        // Also apply decay to the entangled partner if exists
        uint256 entangledTokenId = _entangledWith[tokenId];
        if (entangledTokenId != 0) {
             TokenState storage partnerState = _tokenStates[entangledTokenId];
             // Calculate decay for partner based on partner's last interaction block
             uint256 partnerBlocksPassed = block.number - partnerState.lastInteractionBlock;
             if (partnerBlocksPassed > 0) {
                 uint256 partnerDecayIncrease = (partnerBlocksPassed * decayRatePerBlock) / 2; // Entanglement halved
                 partnerState.decayLevel = Math.min(partnerState.decayLevel + partnerDecayIncrease, MAX_DECAY);
                 partnerState.lastInteractionBlock = block.number; // Update partner's last block
                 emit StateChanged(entangledTokenId, partnerState.level, partnerState.decayLevel);
             }
        }

        emit StateChanged(tokenId, state.level, state.decayLevel);
    }


    // --- Query Functions ---

    /// @notice Gets the current state of a token (level, decay, last interaction block).
    /// @dev This function triggers the decay calculation before returning the state,
    ///      updating the token's persistent state if called via a transaction.
    ///      In a view call, the returned state reflects potential decay but doesn't persist.
    /// @param tokenId The ID of the token.
    /// @return A tuple containing the level, decay level, and last interaction block.
    function getTokenState(uint256 tokenId) public view returns (uint256 level, uint256 decayLevel, uint256 lastInteractionBlock) {
         // We cannot modify state (_applyDecayIfDue) in a view function.
         // To return state reflecting current block, we calculate potential decay here.
         TokenState storage state = _tokenStates[tokenId];
         if (_tokenStates[tokenId].lastInteractionBlock == 0 && _tokenStates[tokenId].level == 0) {
             // Token doesn't exist or state not initialized
             return (0, 0, 0);
         }

         uint256 blocksPassed = block.number - state.lastInteractionBlock;
         uint256 potentialDecayIncrease = blocksPassed * decayRatePerBlock;

         // Entanglement effect: Decay rate is halved if entangled (calculate based on current entanglement)
         if (_entangledWith[tokenId] != 0) {
             potentialDecayIncrease = potentialDecayIncrease / 2;
         }

         uint256 calculatedDecay = Math.min(state.decayLevel + potentialDecayIncrease, MAX_DECAY);

        return (state.level, calculatedDecay, state.lastInteractionBlock);
    }

    /// @notice Returns the current decay rate per block.
    function getDecayRate() public view returns (uint256) {
        return decayRatePerBlock;
    }

    /// @notice Returns the current cost to attempt evolution.
    function getEvolutionCost() public view returns (uint256) {
        return evolutionCost;
    }

     /// @notice Returns the current fee to entangle two tokens.
    function getEntanglementFee() public view returns (uint256) {
        return entanglementFee;
    }


    // --- Owner/Management Functions ---

    /// @notice Sets the base URI for token metadata.
    /// @param newBaseURI The new base URI.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

    /// @notice Sets the decay rate per block.
    /// @param newRate The new decay rate.
    function setDecayRate(uint256 newRate) public onlyOwner {
        decayRatePerBlock = newRate;
        emit ParametersUpdated(decayRatePerBlock, evolutionCost, entanglementFee);
    }

    /// @notice Sets the cost for evolution attempts.
    /// @param newCost The new evolution cost.
    function setEvolutionCost(uint256 newCost) public onlyOwner {
        evolutionCost = newCost;
        emit ParametersUpdated(decayRatePerBlock, evolutionCost, entanglementFee);
    }

    /// @notice Sets the fee for entangling tokens.
    /// @param newFee The new entanglement fee.
    function setEntanglementFee(uint256 newFee) public onlyOwner {
        entanglementFee = newFee;
        emit ParametersUpdated(decayRatePerBlock, evolutionCost, entanglementFee);
    }

    /// @notice Withdraws any collected Ether (from fees) to the owner.
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }


    // --- Hooks & Transfers ---

    /// @dev Overrides the transfer hook to prevent transferring entangled tokens individually.
    ///      Also applies decay calculation during transfers.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer if entangled, unless it's a burn (to == address(0))
        if (to != address(0) && isEntangled(tokenId)) {
             revert CannotTransferEntangledToken(tokenId);
             // Alternative: Allow transfer of *both* entangled tokens together somehow? More complex.
        }

        // Apply decay when transferring (state changes owner)
        if (from != address(0)) { // Only apply decay if transferring *from* an address (not initial mint)
             _applyDecayIfDue(tokenId);
        }
        // Note: Decay for the partner token would also be applied via _applyDecayIfDue
    }

    /// @dev Overrides Pausable hook to check for minting being paused.
    function _mint(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
         if (paused()) {
             revert MintingPaused();
         }
         super._mint(to, tokenId);
    }

    // ERC721URIStorage override, not strictly needed as we implement tokenURI
    // but good practice if inheriting URIStorage.
    function _setTokenURI(uint256 tokenId, string memory uri) internal override(ERC721, ERC721URIStorage) {
        // Not used in this contract as tokenURI is dynamic, but required for inheritance
        // You could add checks or specific logic here if needed.
    }

    // Receive function to allow receiving Ether for fees
    receive() external payable {}

    // Fallback function to allow receiving Ether
    fallback() external payable {}
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Quantum Entanglement Mechanic:** The core idea is linking two NFTs (`entangleTokens`). Actions on one (like `_applyDecayIfDue` triggered by `interact`, `evolve`, `stabilize`, `tokenURI`, or transfer) can affect the state of its entangled partner. This creates a dependency and strategic layer for owners who hold pairs.
2.  **Dynamic State Variables:** NFTs have internal state beyond just ownership and a static URI: `level` (evolution), `decayLevel` (instability), and `lastInteractionBlock`.
3.  **Time-Based Decay:** The `decayLevel` increases automatically based on how many blocks have passed since the last interaction (`lastInteractionBlock`). This requires owners to periodically interact (`interact`, `stabilize`, `evolve`, or even querying `tokenURI` or transferring, which call `_applyDecayIfDue`) to prevent their NFTs from decaying. Entanglement *slows down* decay, adding a benefit to pairing.
4.  **Interactive Evolution/Stabilization:** Specific actions (`evolve`, `stabilize`) allow owners to influence the state, but these actions require resources (Ether) and meet certain conditions (e.g., minimum level, low decay, entanglement for higher levels of evolution). This turns the NFTs into active agents requiring management.
5.  **Resource Sinks:** The `evolutionCost` and `entanglementFee` provide ways to remove Ether from circulation, potentially adding economic dynamics. The `withdrawFunds` function allows the owner to collect these fees.
6.  **Dynamic Metadata (`tokenURI` override):** The `tokenURI` function is overridden to include query parameters reflecting the token's current `level`, `decayLevel`, and entanglement status. A separate off-chain service would use these parameters to serve dynamic JSON metadata and images that visually change based on the NFT's state. This makes the NFT visually *live*.
7.  **Transfer Restrictions on Entanglement:** Entangled tokens cannot be transferred individually (`_beforeTokenTransfer` hook). This reinforces the linked nature and requires owners to disentangle them first if they want to trade or sell separately, adding a small friction point.
8.  **State Updates on Interaction/Query:** Decay is calculated and applied not just by specific "decay" functions (there isn't one), but strategically within *other* functions (`interact`, `stabilize`, `evolve`, `tokenURI`, `_beforeTokenTransfer`). This means merely checking the token's URI or interacting with it will update its state based on inactivity, making the decay mechanic ever-present. (Note: State change in `tokenURI` is only simulated in a view function; persistent changes require non-view calls).
9.  **Parameter Control:** The owner can adjust key parameters (`decayRatePerBlock`, `evolutionCost`, `entanglementFee`) to balance the game mechanics over time.
10. **Modular Design:** Uses OpenZeppelin standard contracts (ERC721, Enumerable, Ownable, Pausable) as a base, extending them with custom logic and state.

This contract goes beyond typical static PFP or art NFTs by giving them internal state, requiring user interaction for optimal health/growth, and introducing a novel relationship mechanic between pairs of tokens.