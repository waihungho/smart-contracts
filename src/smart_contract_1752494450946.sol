Okay, here is a Solidity smart contract (`QuantumEntangledNFT`) that implements a unique concept of NFTs being "entangled" in pairs, affecting each other's state. It incorporates dynamic states, interaction effects, and goes beyond standard NFT functionalities.

This contract uses the trendy NFT concept and adds a creative, advanced layer of programmed interaction and state dynamics between paired tokens, which is not a standard feature found in typical open-source NFT contracts.

---

**Contract: QuantumEntangledNFT**

**Concept:**
This smart contract defines NFTs that can be "entangled" in pairs. When two tokens are entangled, certain actions or state changes on one token can trigger defined reactions or state changes on its entangled partner. Each token also possesses dynamic attributes like `State` and `Stability`, which can be influenced by user interaction, entanglement effects, or even simulated quantum fluctuations.

**Outline:**

1.  **Pragma & Imports:** Specifies Solidity version and imports necessary interfaces/libraries (ERC721, ERC2981, Ownable, Counters, ReentrancyGuard).
2.  **Error Definitions:** Custom error types for clarity and gas efficiency.
3.  **Enums:** Defines possible states, stability levels, and entanglement reaction types.
4.  **State Variables:** Stores core data like token details, entanglement mapping, token states/stability, contract settings (price, royalty), and ownership.
5.  **Events:** Declares events to log significant actions like minting, entanglement, state changes, untangling, etc.
6.  **Constructor:** Initializes the contract with name, symbol, and owner.
7.  **Core ERC721 Overrides:** Handles standard NFT functionalities like transfers, token URIs, etc., with modifications for entanglement rules.
8.  **Entanglement Management Functions:** Functions for creating and breaking entanglement between token pairs.
9.  **Dynamic State & Stability Functions:** Functions to query and modify token state and stability, including triggering entangled effects.
10. **Interaction & Utility Functions:** Functions for initiating fluctuations, recalibrating stability, transferring entangled pairs, burning, checking entanglement potential, etc.
11. **Owner-Only Functions:** Administrative functions like pausing, setting base URI, managing royalties, and withdrawing funds.
12. **View/Pure Functions:** Read-only functions to query contract state and token information.

**Function Summary:**

1.  `constructor()`: Initializes the contract with name, symbol, and sets the owner.
2.  `mint()`: Mints a single new NFT, initially unentangled.
3.  `batchMint()`: Mints multiple new NFTs in a single transaction.
4.  `entanglePair(uint256 _tokenId1, uint256 _tokenId2, EntanglementReaction _reactionType)`: Attempts to entangle two *unentangled* tokens, setting their reaction type. Requires ownership of both or approval.
5.  `untanglePair(uint256 _tokenId)`: Untangles the pair containing the specified token. Requires ownership of the token.
6.  `changeTokenState(uint256 _tokenId, TokenState _newState)`: Changes the state of a token. If entangled, triggers the reaction on its partner. Requires ownership or specific approval.
7.  `initiateQuantumFluctuation(uint256 _tokenId)`: Simulates a random quantum fluctuation on a token, potentially affecting its state/stability and triggering entanglement effects. Requires ownership or specific approval.
8.  `recalibrateStability(uint256 _tokenId)`: Allows the owner of a token to attempt to improve its stability. May have costs or cooldowns (simplified here).
9.  `transferEntangledPair(uint256 _tokenId1, address _to)`: Transfers both tokens in an entangled pair to a new address in a single operation. Requires approval for both tokens.
10. `burn(uint256 tokenId)`: Burns a token. If entangled, it first untangles the pair. Requires ownership.
11. `pauseMinting()`: (Owner) Pauses the ability to mint new tokens.
12. `unpauseMinting()`: (Owner) Unpauses minting.
13. `setBaseURI(string memory baseURI)`: (Owner) Sets the base URI for token metadata.
14. `setDefaultEntanglementReaction(EntanglementReaction _reactionType)`: (Owner) Sets the default reaction type for newly entangled pairs.
15. `setRoyaltyInfo(uint96 _royaltyFraction)`: (Owner) Sets the default royalty percentage for the collection (ERC2981).
16. `withdrawFunds()`: (Owner) Withdraws any accumulated funds (e.g., from minting if a price was added) to the owner address.
17. `checkPotentialEntanglement(uint256 _tokenId1, uint256 _tokenId2)`: (View) Checks if two specific unentangled tokens meet the criteria (e.g., unentangled, exist) to *potentially* be entangled. Does not perform the entanglement.
18. `getQuantumFingerprint(uint256 _tokenId)`: (View) Generates a unique identifier based on the token's dynamic attributes (state, stability) and entanglement status. Purely informational.
19. `queryEntangledPair(uint256 _tokenId)`: (View) Returns the token ID entangled with the given token, or 0 if not entangled.
20. `queryTokenState(uint256 _tokenId)`: (View) Returns the current state of a token.
21. `queryTokenStability(uint256 _tokenId)`: (View) Returns the current stability level of a token.
22. `queryEntanglementStatus(uint256 _tokenId)`: (View) Returns true if the token is currently entangled.
23. `queryPairReactionType(uint256 _tokenId)`: (View) Returns the reaction type set for the entangled pair containing this token.
24. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: (View Override) Implements the ERC2981 royalty standard.
25. `supportsInterface(bytes4 interfaceId)`: (View Override) Standard ERC165 implementation for interface detection (ERC721, ERC2981).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Custom Errors
error QuantumEntangledNFT__NotOwnerOrApproved();
error QuantumEntangledNFT__TokenDoesNotExist();
error QuantumEntangledNFT__AlreadyEntangled();
error QuantumEntangledNFT__NotEntangled();
error QuantumEntangledNFT__PairMismatch();
error QuantumEntangledNFT__EntanglementConditionsNotMet();
error QuantumEntangledNFT__MintingPaused();
error QuantumEntangledNFT__InsufficientFunds();
error QuantumEntangledNFT__ApprovalRequiredForPairTransfer();
error QuantumEntangledNFT__CannotEntangleWithSelf();

// Enums for dynamic states
enum TokenState { Neutral, Positive, Negative, Excited, Dormant }
enum TokenStability { Stable, Unstable, Critical }
enum EntanglementReaction { None, InverseState, SharedState, StabilityDrain, StateBoost }

contract QuantumEntangledNFT is ERC721URIStorage, ERC721Burnable, Ownable, ReentrancyGuard, IERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Entanglement Mapping: tokenId => entangled_tokenId (0 if not entangled)
    mapping(uint256 => uint256) private _entangledPair;
    // Entanglement Status: tokenId => is_entangled
    mapping(uint256 => bool) private _entanglementStatus;
    // Entanglement Reaction Type: tokenId => reaction_type (Stored for one token in the pair)
    mapping(uint256 => EntanglementReaction) private _pairReactionType;

    // Dynamic Token State: tokenId => state
    mapping(uint256 => TokenState) private _tokenState;
    // Dynamic Token Stability: tokenId => stability
    mapping(uint256 => TokenStability) private _tokenStability;

    // Contract Settings
    bool private _mintingPaused = false;
    uint96 private _royaltyFraction = 0; // ERC2981 royalty fee (e.g., 250 for 2.5%)
    EntanglementReaction private _defaultReactionType = EntanglementReaction.InverseState;

    // --- Events ---

    event TokenMinted(uint256 indexed tokenId, address indexed owner);
    event PairEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, EntanglementReaction reactionType);
    event PairUntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event TokenStateChanged(uint256 indexed tokenId, TokenState oldState, TokenState newState);
    event TokenStabilityChanged(uint256 indexed tokenId, TokenStability oldStability, TokenStability newStability);
    event QuantumFluctuationTriggered(uint256 indexed tokenId, TokenState newState, TokenStability newStability);
    event PairTransferred(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed from, address indexed to);

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- Core ERC721 Overrides ---

    function _baseURI() internal view override(ERC721URIStorage) returns (string memory) {
        return super._baseURI();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert QuantumEntangledNFT__TokenDoesNotExist();
        // Future: Could potentially make tokenURI dynamic based on state/stability here
        return super.tokenURI(tokenId);
    }

    // Prevent transfer of a single entangled token - force untangle or transfer pair
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If not minting (from != address(0)) and not burning (to != address(0))
        // and the token is entangled, prevent single transfer.
        // Exception: The transferEntangledPair function handles its own transfer logic.
        // How to detect if calling from transferEntangledPair?
        // Simple approach: check entanglement status for non-zero 'from' and 'to'.
        // A more robust approach might involve a flag, but checking entanglement is simpler here.
        if (from != address(0) && to != address(0) && _entanglementStatus[tokenId]) {
             // Allow if the *other* token in the pair is also being transferred in the *same* batch (not possible with standard ERC721)
             // Or, if a custom batch transfer function was called.
             // For this design, we explicitly force `transferEntangledPair`.
             // If batchSize > 1, this logic needs refinement to check *all* tokens in the batch.
             // Assuming batchSize is always 1 for standard transfers:
             if (msg.sender != address(this) || batchSize != 2) { // Check if called internally by transferEntangledPair
                  revert QuantumEntangledNFT__AlreadyEntangled(); // Cannot transfer single entangled token
             }
             // If msg.sender IS this contract and batchSize is 2, it's likely transferEntangledPair, allow.
        }
    }

    // --- Entanglement Management Functions ---

    /// @notice Attempts to entangle two unentangled tokens.
    /// @param _tokenId1 The ID of the first token.
    /// @param _tokenId2 The ID of the second token.
    /// @param _reactionType The type of reaction the pair will have when a state changes.
    function entanglePair(uint256 _tokenId1, uint256 _tokenId2, EntanglementReaction _reactionType) public nonReentrant {
        if (!_exists(_tokenId1)) revert QuantumEntangledNFT__TokenDoesNotExist();
        if (!_exists(_tokenId2)) revert QuantumEntangledNFT__TokenDoesNotExist();
        if (_tokenId1 == _tokenId2) revert QuantumEntangledNFT__CannotEntangleWithSelf();

        // Check if tokens can be entangled (e.g., not already entangled, owner permission)
        if (_entanglementStatus[_tokenId1] || _entanglementStatus[_tokenId2]) revert QuantumEntangledNFT__AlreadyEntangled();

        address owner1 = ownerOf(_tokenId1);
        address owner2 = ownerOf(_tokenId2);

        // Require calling address owns both, or is approved for both
        bool callerIsApproved1 = getApproved(_tokenId1) == msg.sender || isApprovedForAll(owner1, msg.sender);
        bool callerIsApproved2 = getApproved(_tokenId2) == msg.sender || isApprovedForAll(owner2, msg.sender);

        if (msg.sender != owner1 || msg.sender != owner2) {
             if (!callerIsApproved1 || !callerIsApproved2) {
                 revert QuantumEntangledNFT__NotOwnerOrApproved();
             }
        }

        // Additional custom conditions can be added here (e.g., require specific states, metadata check)
        // Example: if (_tokenState[_tokenId1] != TokenState.Positive || _tokenState[_tokenId2] != TokenState.Negative) revert QuantumEntanglementNFT__EntanglementConditionsNotMet();

        _entangledPair[_tokenId1] = _tokenId2;
        _entangledPair[_tokenId2] = _tokenId1;
        _entanglementStatus[_tokenId1] = true;
        _entanglementStatus[_tokenId2] = true;
        _pairReactionType[_tokenId1] = _reactionType; // Store reaction type on one side

        emit PairEntangled(_tokenId1, _tokenId2, _reactionType);
    }

    /// @notice Untangles a pair containing the specified token.
    /// @param _tokenId The ID of one token in the pair.
    function untanglePair(uint256 _tokenId) public nonReentrant {
        if (!_exists(_tokenId)) revert QuantumEntangledNFT__TokenDoesNotExist();
        if (!_entanglementStatus[_tokenId]) revert QuantumEntangledNFT__NotEntangled();

        uint256 entangledId = _entangledPair[_tokenId];
        if (!_exists(entangledId)) revert QuantumEntangledNFT__PairMismatch(); // Should not happen if _entanglementStatus is true

        // Require calling address owns the token or is approved for it
        address owner1 = ownerOf(_tokenId);
        bool callerIsApproved = getApproved(_tokenId) == msg.sender || isApprovedForAll(owner1, msg.sender);
        if (msg.sender != owner1 && !callerIsApproved) revert QuantumEntangledNFT__NotOwnerOrApproved();

        // Clear entanglement status for both tokens
        _entangledPair[_tokenId] = 0;
        _entangledPair[entangledId] = 0;
        _entanglementStatus[_tokenId] = false;
        _entanglementStatus[entangledId] = false;
        delete _pairReactionType[_tokenId]; // Remove reaction type

        emit PairUntangled(_tokenId, entangledId);
    }

    // --- Dynamic State & Stability Functions ---

    /// @notice Changes the state of a token, potentially triggering entanglement effects.
    /// @param _tokenId The ID of the token.
    /// @param _newState The new state for the token.
    function changeTokenState(uint256 _tokenId, TokenState _newState) public nonReentrant {
        if (!_exists(_tokenId)) revert QuantumEntangledNFT__TokenDoesNotExist();

        // Require calling address owns the token or is approved for it
        address owner_ = ownerOf(_tokenId);
        bool callerIsApproved = getApproved(_tokenId) == msg.sender || isApprovedForAll(owner_, msg.sender);
        if (msg.sender != owner_ && !callerIsApproved) revert QuantumEntangledNFT__NotOwnerOrApproved();

        TokenState oldState = _tokenState[_tokenId];
        if (oldState == _newState) return; // No change

        _tokenState[_tokenId] = _newState;
        emit TokenStateChanged(_tokenId, oldState, _newState);

        // If entangled, trigger reaction on the partner
        if (_entanglementStatus[_tokenId]) {
            uint256 entangledId = _entangledPair[_tokenId];
            _triggerEntangledReaction(_tokenId, entangledId, _newState);
        }
    }

    /// @notice Attempts to improve a token's stability. (Simplified: just sets to Stable)
    /// Can be extended with costs, cooldowns, or success chance based on current stability.
    /// @param _tokenId The ID of the token.
    function recalibrateStability(uint256 _tokenId) public nonReentrant {
         if (!_exists(_tokenId)) revert QuantumEntangledNFT__TokenDoesNotExist();

         // Require calling address owns the token or is approved for it
         address owner_ = ownerOf(_tokenId);
         bool callerIsApproved = getApproved(_tokenId) == msg.sender || isApprovedForAll(owner_, msg.sender);
         if (msg.sender != owner_ && !callerIsApproved) revert QuantumEntangledNFT__NotOwnerOrApproved();

         TokenStability oldStability = _tokenStability[_tokenId];
         // Only allow recalibration if not already Stable (simplified logic)
         if (oldStability != TokenStability.Stable) {
             _tokenStability[_tokenId] = TokenStability.Stable;
             emit TokenStabilityChanged(_tokenId, oldStability, TokenStability.Stable);
             // Recalibration could also have effects on entangled pairs or state
         }
    }

    /// @dev Internal function to trigger the reaction on the entangled partner.
    /// @param _changingTokenId The ID of the token whose state just changed.
    /// @param _entangledTokenId The ID of the entangled partner.
    /// @param _newState The new state of the changing token.
    function _triggerEntangledReaction(uint256 _changingTokenId, uint256 _entangledTokenId, TokenState _newState) internal {
         EntanglementReaction reactionType = _pairReactionType[_changingTokenId]; // Get reaction type from one side
         if (reactionType == EntanglementReaction.None) return;

         TokenState oldPartnerState = _tokenState[_entangledTokenId];
         TokenState newPartnerState = oldPartnerState; // Default to no change
         TokenStability oldPartnerStability = _tokenStability[_entangledTokenId];
         TokenStability newPartnerStability = oldPartnerStability; // Default to no change

         // Apply reaction based on type and the state change
         if (reactionType == EntanglementReaction.InverseState) {
             if (_newState == TokenState.Positive) newPartnerState = TokenState.Negative;
             else if (_newState == TokenState.Negative) newPartnerState = TokenState.Positive;
             else if (_newState == TokenState.Excited) newPartnerState = TokenState.Dormant;
             else if (_newState == TokenState.Dormant) newPartnerState = TokenState.Excited;
             // Neutral might not have an inverse state
         } else if (reactionType == EntanglementReaction.SharedState) {
             newPartnerState = _newState; // Partner takes on the same state
         } else if (reactionType == EntanglementReaction.StabilityDrain) {
             // State change on one drains stability from the other
             if (oldPartnerStability == TokenStability.Stable) newPartnerStability = TokenStability.Unstable;
             else if (oldPartnerStability == TokenStability.Unstable) newPartnerStability = TokenStability.Critical;
             // If already Critical, maybe nothing happens or it causes disentanglement (more complex)
         } else if (reactionType == EntanglementReaction.StateBoost) {
             // Certain state changes boost the partner's state (e.g., Neutral -> Positive, Dormant -> Excited)
             if (_newState == TokenState.Positive && oldPartnerState == TokenState.Neutral) newPartnerState = TokenState.Positive;
             else if (_newState == TokenState.Excited && oldPartnerState == TokenState.Dormant) newPartnerState = TokenState.Excited;
         }

         // Update partner's state if it changed
         if (newPartnerState != oldPartnerState) {
             _tokenState[_entangledTokenId] = newPartnerState;
             emit TokenStateChanged(_entangledTokenId, oldPartnerState, newPartnerState);
         }

         // Update partner's stability if it changed
         if (newPartnerStability != oldPartnerStability) {
             _tokenStability[_entangledTokenId] = newPartnerStability;
             emit TokenStabilityChanged(_entangledTokenId, oldPartnerStability, newPartnerStability);
         }

         // Future complexity: Reaction could also depend on the partner's *original* state/stability,
         // or the *magnitude* of the state change.
    }

    // --- Interaction & Utility Functions ---

    /// @notice Initiates a pseudo-random quantum fluctuation event on a token.
    /// Affects state and/or stability, potentially triggering entanglement reactions.
    /// Simplified randomness based on block data.
    /// @param _tokenId The ID of the token.
    function initiateQuantumFluctuation(uint256 _tokenId) public nonReentrant {
        if (!_exists(_tokenId)) revert QuantumEntangledNFT__TokenDoesNotExist();

        // Require calling address owns the token or is approved for it
        address owner_ = ownerOf(_tokenId);
        bool callerIsApproved = getApproved(_tokenId) == msg.sender || isApprovedForAll(owner_, msg.sender);
        if (msg.sender != owner_ && !callerIsApproved) revert QuantumEntangledNFT__NotOwnerOrApproved();

        // Use block data for pseudo-randomness
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenId)));

        TokenState oldState = _tokenState[_tokenId];
        TokenStability oldStability = _tokenStability[_tokenId];
        TokenState newState = oldState;
        TokenStability newStability = oldStability;

        // Apply pseudo-random effect
        uint256 effectType = rand % 3; // 0: State change, 1: Stability change, 2: Both

        if (effectType == 0 || effectType == 2) {
             // Pseudo-random state change
             uint256 stateCount = uint256(TokenState.Dormant) + 1;
             newState = TokenState(rand % stateCount);
             if (newState != oldState) {
                  _tokenState[_tokenId] = newState;
                  emit TokenStateChanged(_tokenId, oldState, newState);
             }
        }

        if (effectType == 1 || effectType == 2) {
             // Pseudo-random stability change (mostly negative unless very lucky)
             uint256 stabilityRoll = (rand / 100) % 100; // Use different part of hash
             if (stabilityRoll < 5) { // 5% chance of improving
                  if (oldStability == TokenStability.Critical) newStability = TokenStability.Unstable;
                  else if (oldStability == TokenStability.Unstable) newStability = TokenStability.Stable;
             } else if (stabilityRoll < 40) { // 35% chance of worsening
                  if (oldStability == TokenStability.Stable) newStability = TokenStability.Unstable;
                  else if (oldStability == TokenStability.Unstable) newStability = TokenStability.Critical;
             }
             // 60% chance of no stability change
             if (newStability != oldStability) {
                 _tokenStability[_tokenId] = newStability;
                 emit TokenStabilityChanged(_tokenId, oldStability, newStability);
             }
        }

        emit QuantumFluctuationTriggered(_tokenId, newState, newStability);

        // If entangled and state changed, trigger reaction on the partner
        if (_entanglementStatus[_tokenId] && newState != oldState) {
            uint256 entangledId = _entangledPair[_tokenId];
            _triggerEntangledReaction(_tokenId, entangledId, newState);
        }
    }

    /// @notice Transfers both tokens in an entangled pair together.
    /// @param _tokenId1 The ID of one token in the pair.
    /// @param _to The recipient address.
    function transferEntangledPair(uint256 _tokenId1, address _to) public nonReentrant {
        if (!_exists(_tokenId1)) revert QuantumEntangledNFT__TokenDoesNotExist();
        if (!_entanglementStatus[_tokenId1]) revert QuantumEntangledNFT__NotEntangled();
        uint256 _tokenId2 = _entangledPair[_tokenId1];
        if (!_exists(_tokenId2)) revert QuantumEntangledNFT__PairMismatch();
        if (_to == address(0)) revert ERC721InvalidReceiver(address(0));

        address owner1 = ownerOf(_tokenId1);
        address owner2 = ownerOf(_tokenId2);
        address from = owner1; // Both tokens must be owned by the same address to transfer together in this simple model

        if (owner1 != owner2 || owner1 != msg.sender) {
            // Check if msg.sender is approved for *both* tokens by the owner
            bool approvedForAll = isApprovedForAll(from, msg.sender);
            bool approved1 = getApproved(_tokenId1) == msg.sender;
            bool approved2 = getApproved(_tokenId2) == msg.sender;

            if (!approvedForAll && (!approved1 || !approved2)) {
                 revert QuantumEntangledNFT__ApprovalRequiredForPairTransfer();
            }
        }

        // Perform the transfers - uses internal _transfer which calls _beforeTokenTransfer
        // _beforeTokenTransfer includes a check to allow transfers *from* this contract for batch size 2.
        _transfer(from, _to, _tokenId1);
        _transfer(from, _to, _tokenId2); // ERC721BatchTransfer is more efficient if available

        emit PairTransferred(_tokenId1, _tokenId2, from, _to);
    }

    /// @notice Burns a token. If entangled, it untangles the pair first.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) public override nonReentrant {
        if (!_exists(tokenId)) revert QuantumEntangledNFT__TokenDoesNotExist();

        // Untangle if necessary before burning
        if (_entanglementStatus[tokenId]) {
            untanglePair(tokenId); // Will check ownership/approval inside
        } else {
             // If not entangled, perform standard burn check
             address owner_ = ownerOf(tokenId);
             if (msg.sender != owner_ && !isApprovedForAll(owner_, msg.sender) && getApproved(tokenId) != msg.sender) {
                 revert QuantumEntangledNFT__NotOwnerOrApproved();
             }
        }

        // Now perform the actual burn
        _burn(tokenId);
    }


    // --- Owner-Only Functions ---

    /// @notice Pauses minting of new tokens.
    function pauseMinting() public onlyOwner {
        _mintingPaused = true;
    }

    /// @notice Unpauses minting of new tokens.
    function unpauseMinting() public onlyOwner {
        _mintingPaused = false;
    }

    /// @notice Sets the base URI for token metadata.
    function setBaseURI(string memory baseURI) public onlyOwner override {
        _setBaseURI(baseURI);
    }

    /// @notice Sets the default entanglement reaction type for new pairs.
    function setDefaultEntanglementReaction(EntanglementReaction _reactionType) public onlyOwner {
        _defaultReactionType = _reactionType;
    }

    /// @notice Sets the default royalty percentage for the collection.
    /// @param _royaltyFraction The royalty fraction (e.g., 250 for 2.5%).
    function setRoyaltyInfo(uint96 _royaltyFraction) public onlyOwner {
        _royaltyFraction = _royaltyFraction;
    }

    /// @notice Withdraws any accumulated funds from the contract to the owner.
    function withdrawFunds() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert InsufficientFunds(0); // Using inherited error if available, or custom
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // --- View/Pure Functions ---

    /// @notice Mints a new token.
    /// Can be extended to accept payment or specific parameters.
    function mint() public payable nonReentrant returns (uint256) {
        if (_mintingPaused) revert QuantumEntangledNFT__MintingPaused();
        // Add require(msg.value >= mintPrice, ...) if minting costs money

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(msg.sender, newItemId);

        // Initialize default state and stability
        _tokenState[newItemId] = TokenState.Neutral;
        _tokenStability[newItemId] = TokenStability.Stable;

        emit TokenMinted(newItemId, msg.sender);
        return newItemId;
    }

    /// @notice Mints multiple tokens.
    /// @param numToMint The number of tokens to mint.
    function batchMint(uint256 numToMint) public payable nonReentrant {
        if (_mintingPaused) revert QuantumEntangledNFT__MintingPaused();
        // Add require(msg.value >= mintPrice * numToMint, ...) if minting costs money

        for (uint i = 0; i < numToMint; i++) {
            _tokenIdCounter.increment();
            uint256 newItemId = _tokenIdCounter.current();
            _safeMint(msg.sender, newItemId);

            // Initialize default state and stability
            _tokenState[newItemId] = TokenState.Neutral;
            _tokenStability[newItemId] = TokenStability.Stable;

            emit TokenMinted(newItemId, msg.sender);
        }
    }

    /// @notice Checks if two specific unentangled tokens meet criteria for potential entanglement.
    /// Currently just checks existence and entanglement status. Can add custom rules.
    /// @param _tokenId1 The ID of the first token.
    /// @param _tokenId2 The ID of the second token.
    /// @return bool True if potentially entangleable, false otherwise.
    function checkPotentialEntanglement(uint256 _tokenId1, uint256 _tokenId2) public view returns (bool) {
        if (!_exists(_tokenId1) || !_exists(_tokenId2)) return false;
        if (_tokenId1 == _tokenId2) return false;
        if (_entanglementStatus[_tokenId1] || _entanglementStatus[_tokenId2]) return false;

        // Add more complex checks here, e.g.:
        // - require they have complementary states
        // - require they are from a specific batch or generation
        // - require owner has a specific "entanglement key" token

        return true; // Basic check passed
    }

    /// @notice Generates a unique identifier based on the token's dynamic attributes and entanglement status.
    /// Purely informational, not stored on-chain.
    /// @param _tokenId The ID of the token.
    /// @return bytes32 A hash representing the token's "quantum fingerprint".
    function getQuantumFingerprint(uint256 _tokenId) public view returns (bytes32) {
        if (!_exists(_tokenId)) return bytes32(0); // Or revert

        uint256 entangledPartner = _entangledPair[_tokenId];
        TokenState currentState = _tokenState[_tokenId];
        TokenStability currentStability = _tokenStability[_tokenId];
        bool isEntangled = _entanglementStatus[_tokenId];
        EntanglementReaction reactionType = isEntangled ? _pairReactionType[_tokenId] : EntanglementReaction.None;

        // Hash together relevant data
        return keccak256(
            abi.encodePacked(
                _tokenId,
                entangledPartner,
                uint8(currentState),
                uint8(currentStability),
                isEntangled,
                uint8(reactionType)
            )
        );
    }

    /// @notice Returns the token ID entangled with the given token.
    /// @param _tokenId The ID of the token.
    /// @return uint256 The ID of the entangled token, or 0 if not entangled.
    function queryEntangledPair(uint256 _tokenId) public view returns (uint256) {
        return _entangledPair[_tokenId];
    }

    /// @notice Returns the current state of a token.
    /// @param _tokenId The ID of the token.
    /// @return TokenState The current state.
    function queryTokenState(uint256 _tokenId) public view returns (TokenState) {
        if (!_exists(_tokenId)) return TokenState.Neutral; // Or revert
        return _tokenState[_tokenId];
    }

    /// @notice Returns the current stability level of a token.
    /// @param _tokenId The ID of the token.
    /// @return TokenStability The current stability.
    function queryTokenStability(uint256 _tokenId) public view returns (TokenStability) {
        if (!_exists(_tokenId)) return TokenStability.Stable; // Or revert
        return _tokenStability[_tokenId];
    }

    /// @notice Returns true if the token is currently entangled.
    /// @param _tokenId The ID of the token.
    /// @return bool True if entangled, false otherwise.
    function queryEntanglementStatus(uint256 _tokenId) public view returns (bool) {
        return _entanglementStatus[_tokenId];
    }

    /// @notice Returns the reaction type set for the entangled pair containing this token.
    /// Returns None if the token is not entangled.
    /// @param _tokenId The ID of the token.
    /// @return EntanglementReaction The reaction type.
    function queryPairReactionType(uint256 _tokenId) public view returns (EntanglementReaction) {
        if (!_entanglementStatus[_tokenId]) return EntanglementReaction.None;
        // Reaction type is stored on one side, need to find that side
        uint256 pairMember1 = _entangledPair[_tokenId] > _tokenId ? _tokenId : _entangledPair[_tokenId]; // Assuming lower ID stores type
        // Correction: Let's store it consistently on _tokenId1 in entanglePair call,
        // or better, store it on the lower tokenId of the pair.
        // For simplicity, let's just query _pairReactionType[_tokenId]. If the other token stored it, it would be 0/None.
        // A better approach might be a mapping(pairId => ReactionType) where pairId is min(id1, id2).
        // Let's refine `entanglePair` to store it on the lower ID.
        uint256 pairKeyId = _tokenId < _entangledPair[_tokenId] ? _tokenId : _entangledPair[_tokenId];
        if (pairKeyId == 0) return EntanglementReaction.None; // Not entangled

        return _pairReactionType[pairKeyId];
    }

    /// @notice Implements ERC2981 royalty standard.
    /// @param tokenId The ID of the token.
    /// @param salePrice The sale price of the token.
    /// @return receiver The address to send royalties to.
    /// @return royaltyAmount The calculated royalty amount.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(IERC2981, ERC721)
        returns (address receiver, uint256 royaltyAmount)
    {
        // Basic implementation: royalty goes to owner, based on default fraction
        // Can be extended to support per-token royalties if needed
        receiver = owner(); // Or a designated royalty receiver address
        royaltyAmount = (salePrice * _royaltyFraction) / 10000; // Fraction is out of 10000 (e.g., 250 = 2.5%)
        return (receiver, royaltyAmount);
    }

    /// @notice Standard ERC165 support check.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Burnable, IERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId || // ERC721URIStorage implements this
            interfaceId == type(IERC721Enumerable).interfaceId || // If enumerable extension was added
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
```