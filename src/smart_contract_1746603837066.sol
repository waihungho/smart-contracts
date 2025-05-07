Okay, here's a concept for an advanced, creative, and non-standard smart contract: **QuantumEntangledNFTs**.

**Concept:** This contract manages a unique type of NFT where tokens can be "entangled" in pairs. Entangled tokens are bound together: they must be owned by the same address, and transferring one token automatically transfers its entangled partner. They also share some dynamic properties influenced by this entanglement and owner interactions, like a "charge" level. Unentangling is possible but might have costs or cooldowns.

This goes beyond standard ERC721 by adding:
1.  **Paired State:** Tracking entanglement between specific token IDs.
2.  **Atomic Paired Transfer:** Forcing two tokens to move together in a single logical operation.
3.  **Dynamic Property:** The `charge` level, which changes based on state and interaction.
4.  **Interaction Mechanic:** A function for owners to "interact" with an entangled pair, affecting their shared state.
5.  **Entanglement/Unentanglement Lifecycle:** Specific functions with potential fees/cooldowns to manage the pair state.
6.  **Restricted Transfers:** Blocking standard `transferFrom`/`safeTransferFrom` for entangled tokens to enforce the paired transfer rule.

---

**Outline:**

1.  **SPDX License and Pragma**
2.  **Imports:** ERC721, Ownable, Pausable, SafeMath/Math, ReentrancyGuard (optional but good practice if fees were more complex). Using OpenZeppelin implementations.
3.  **Error Handling:** Custom errors for clarity.
4.  **Events:** `Entangled`, `Unentangled`, `PairTransferred`, `ChargeUpdated`, `PairInteracted`, `PairBurned`.
5.  **State Variables:**
    *   ERC721 standard variables (handled by inheritance)
    *   `_entangledWith`: mapping token ID to its partner token ID.
    *   `_isEntangled`: mapping token ID to a boolean indicating if it's currently entangled.
    *   `_tokenCharge`: mapping token ID to its current charge level (e.g., 0-100).
    *   `_pairInteractionCount`: mapping pair key (min token ID) to interaction count.
    *   `_lastPairInteractionTime`: mapping pair key to timestamp of last interaction.
    *   `_lastUnentangleTime`: mapping token ID to timestamp of last unentanglement (for cooldown).
    *   `_entanglementFee`: fee required to entangle a pair.
    *   `_collectedFees`: total collected fees.
    *   `_interactionChargeEffect`: amount charge changes on interaction (can be negative).
    *   `_unentanglementCooldownDuration`: minimum time required between unentanglements for a token.
    *   `_baseTokenURI`: base URI for metadata.
    *   `_nextTokenId`: counter for minting.
    *   `Pausable` state
    *   `Ownable` state
6.  **Constructor:** Initializes base URI, owner, and configurations.
7.  **Modifiers:** Custom modifiers (e.g., `onlyEntangledPairOwner`).
8.  **Internal Helpers:**
    *   `_getPairKey`: determines a canonical key for a pair.
    *   `_requireUnentangled`: check if a token is not entangled.
    *   `_requireEntangled`: check if a token is entangled.
    *   `_requireOwnedBy`: check if token is owned by address.
    *   `_requireEntangledWith`: check if two tokens are entangled with each other.
    *   `_updateCharge`: internal function to safely update charge within bounds (0-100).
    *   `_beforeTokenTransfer`: Override OZ hook to restrict standard transfers for entangled tokens.
    *   `_transfer`: Override OZ `_transfer` if needed, or rely on `_beforeTokenTransfer` hook.
9.  **Public/External Functions (Aiming for 20+ including overridden/view):**
    *   **Minting:**
        1.  `mint(address to)`: Mints a single, unentangled token.
        2.  `batchMint(address to, uint256 count)`: Mints multiple unentangled tokens.
    *   **Entanglement Lifecycle:**
        3.  `entangle(uint256 tokenId1, uint256 tokenId2)`: Binds two unentangled tokens. Requires fee.
        4.  `unentangle(uint256 tokenId)`: Breaks the bond of an entangled pair. Subject to cooldown.
    *   **Transfer:**
        5.  `transferEntangledPair(address from, address to, uint256 tokenId1)`: Transfers an entire entangled pair atomically.
    *   **Interaction:**
        6.  `interactWithPair(uint256 tokenId)`: Allows the owner of an entangled pair to interact, potentially affecting charge and interaction stats. Subject to cooldown.
    *   **Burning:**
        7.  `burn(uint256 tokenId)`: Burns a single, unentangled token. (Override ERC721)
        8.  `burnEntangledPair(uint256 tokenId1)`: Burns an entire entangled pair.
    *   **Configuration (Owner Only):**
        9.  `setEntanglementFee(uint256 fee)`
        10. `setInteractionChargeEffect(int256 effect)`
        11. `setUnentanglementCooldownDuration(uint40 duration)`
        12. `setBaseURI(string memory baseURI_)`
        13. `pause()`: Pauses most operations (minting, transfer, entanglement, interaction).
        14. `unpause()`: Unpauses.
        15. `withdrawFees(address payable recipient)`: Withdraw collected fees.
    *   **View Functions (>20 total functions):**
        16. `getEntangledPartner(uint256 tokenId)`
        17. `isEntangled(uint256 tokenId)`
        18. `getTokenCharge(uint256 tokenId)`
        19. `getPairInteractionCount(uint256 tokenId)`: Returns interaction count for the pair.
        20. `getLastPairInteractionTime(uint256 tokenId)`: Returns last interaction time for the pair.
        21. `getTimeUntilUnentanglePossible(uint256 tokenId)`: Calculates remaining cooldown time.
        22. `getEntanglementFee()`
        23. `getInteractionChargeEffect()`
        24. `getUnentanglementCooldownDuration()`
        25. `getBaseURI()`
        26. `totalCollectedFees()`
        *   (Plus inherited ERC721 views: `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `supportsInterface`, `tokenURI` - which we override to potentially add dynamic data)

---

**Function Summary:**

1.  `mint(address to)`: Creates a new, individual QENFT owned by `to`.
2.  `batchMint(address to, uint256 count)`: Creates multiple new, individual QENFTs owned by `to`.
3.  `entangle(uint256 tokenId1, uint256 tokenId2)`: Attempts to link two unentangled tokens, requiring they are owned by the caller and paying the `_entanglementFee`.
4.  `unentangle(uint256 tokenId)`: Attempts to break the link for an entangled pair. Requires ownership of one token in the pair and respects the unentanglement cooldown for that token.
5.  `transferEntangledPair(address from, address to, uint256 tokenId1)`: Transfers an entangled token and its partner from `from` to `to`. This is the *only* way to transfer entangled tokens.
6.  `interactWithPair(uint256 tokenId)`: Allows the owner of an entangled pair to perform an interaction, updating the pair's charge level and interaction stats. Subject to a pair-wide cooldown.
7.  `burn(uint256 tokenId)`: Destroys a single, unentangled token. (Standard ERC721 function, overridden for clarity/hooks).
8.  `burnEntangledPair(uint256 tokenId1)`: Destroys an entangled token and its partner.
9.  `setEntanglementFee(uint256 fee)`: Owner-only function to set the cost for entangling tokens.
10. `setInteractionChargeEffect(int256 effect)`: Owner-only function to configure how `interactWithPair` affects the charge level (can increase or decrease).
11. `setUnentanglementCooldownDuration(uint40 duration)`: Owner-only function to set the minimum time between a token being unentangled and being able to be unentangled again (if it gets re-entangled).
12. `setBaseURI(string memory baseURI_)`: Owner-only function to set the base URI for token metadata.
13. `pause()`: Owner-only function to pause core contract functionality (minting, entanglement, transfers, interactions).
14. `unpause()`: Owner-only function to resume core contract functionality.
15. `withdrawFees(address payable recipient)`: Owner-only function to withdraw accumulated entanglement fees to a specified address.
16. `getEntangledPartner(uint256 tokenId)`: View function returning the token ID of the partner if entangled, or 0 otherwise.
17. `isEntangled(uint256 tokenId)`: View function returning true if the token is entangled, false otherwise.
18. `getTokenCharge(uint256 tokenId)`: View function returning the current charge level (0-100) of the token.
19. `getPairInteractionCount(uint256 tokenId)`: View function returning the number of times the pair containing this token has been interacted with.
20. `getLastPairInteractionTime(uint256 tokenId)`: View function returning the timestamp of the last interaction for the pair.
21. `getTimeUntilUnentanglePossible(uint256 tokenId)`: View function calculating how much time is left before this token can be unentangled again (0 if no cooldown applies or active).
22. `getEntanglementFee()`: View function returning the current fee to entangle a pair.
23. `getInteractionChargeEffect()`: View function returning the configured charge effect of interaction.
24. `getUnentanglementCooldownDuration()`: View function returning the configured duration of the unentanglement cooldown.
25. `getBaseURI()`: View function returning the base URI used for token metadata.
26. `totalCollectedFees()`: View function returning the total accumulated entanglement fees waiting to be withdrawn.
    *(Plus inherited ERC721 functions: `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `supportsInterface`, `tokenURI` (overridden))*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// Custom Errors for clarity
error NotOwner();
error NotEntangled();
error AlreadyEntangled(uint256 tokenId);
error NotEntangledWith(uint256 tokenId1, uint256 tokenId2);
error SameTokenID();
error CannotTransferEntangledTokenDirectly();
error UnentanglementCooldown(uint40 timeRemaining);
error InteractionCooldown(uint40 timeRemaining);
error NotEntangledPairOwner();

/// @title QuantumEntangledNFT
/// @dev An ERC721-compliant contract with unique entanglement mechanics.
/// Tokens can be paired (entangled) and must be transferred together.
/// Entangled pairs have dynamic properties like 'charge' affected by owner interaction.
contract QuantumEntangledNFT is ERC721, Ownable, Pausable {

    // --- State Variables ---

    /// @dev Maps a token ID to the token ID of its entangled partner. 0 if not entangled.
    mapping(uint256 => uint256) private _entangledWith;

    /// @dev Maps a token ID to a boolean indicating if it is currently entangled.
    mapping(uint256 => bool) private _isEntangled;

    /// @dev Maps a token ID to its current charge level (0-100).
    mapping(uint256 => uint8) private _tokenCharge; // Using uint8 as charge is 0-100

    /// @dev Maps a pair key (min(tokenId1, tokenId2)) to the number of times the pair has been interacted with.
    mapping(uint256 => uint256) private _pairInteractionCount;

    /// @dev Maps a pair key (min(tokenId1, tokenId2)) to the timestamp of the last interaction with the pair.
    mapping(uint256 => uint40) private _lastPairInteractionTime;

    /// @dev Maps a token ID to the timestamp it was last unentangled. Used for cooldown.
    mapping(uint256 => uint40) private _lastUnentangleTime;

    /// @dev The fee required to entangle a pair of tokens.
    uint256 private _entanglementFee;

    /// @dev Total fees collected from entanglement.
    uint256 private _collectedFees;

    /// @dev The amount the charge changes when a pair is interacted with. Can be negative.
    int256 private _interactionChargeEffect;

    /// @dev The minimum duration a token must wait after being unentangled before it can be unentangled again (if re-entangled).
    uint40 private _unentanglementCooldownDuration;

    /// @dev Cooldown duration required between interactions for a pair.
    uint40 public interactionCooldownDuration; // Public as it's not just config, part of game mechanic

    /// @dev The base URI for token metadata.
    string private _baseTokenURI;

    /// @dev Counter for new token IDs.
    uint256 private _nextTokenId;

    // --- Events ---

    /// @dev Emitted when two tokens become entangled.
    event Entangled(uint256 tokenId1, uint256 tokenId2);

    /// @dev Emitted when an entangled pair is broken.
    event Unentangled(uint256 tokenId1, uint256 tokenId2);

    /// @dev Emitted when an entangled pair is transferred together.
    event PairTransferred(address indexed from, address indexed to, uint256 tokenId1, uint256 tokenId2);

    /// @dev Emitted when a token's charge level is updated.
    event ChargeUpdated(uint256 indexed tokenId, uint8 newCharge);

    /// @dev Emitted when an entangled pair is interacted with by its owner.
    event PairInteracted(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 newInteractionCount, uint8 newCharge1, uint8 newCharge2);

    /// @dev Emitted when an entangled pair is burned.
    event PairBurned(uint256 indexed tokenId1, uint256 indexed tokenId2);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI_;
        _nextTokenId = 1; // Start token IDs from 1
        _entanglementFee = 0; // Default no fee
        _interactionChargeEffect = 5; // Default interaction adds 5 charge
        _unentanglementCooldownDuration = 0; // Default no cooldown
        interactionCooldownDuration = 0; // Default no interaction cooldown
    }

    // --- Modifiers ---

    /// @dev Requires that the specified token is not currently entangled.
    modifier _requireUnentangled(uint256 tokenId) {
        if (_isEntangled[tokenId]) {
            revert AlreadyEntangled(tokenId);
        }
        _;
    }

    /// @dev Requires that the specified token is currently entangled.
    modifier _requireEntangled(uint256 tokenId) {
        if (!_isEntangled[tokenId]) {
            revert NotEntangled();
        }
        _;
    }

    /// @dev Requires that the specified address owns the specified token.
    modifier _requireOwnedBy(uint256 tokenId, address ownerAddress) {
        if (ownerOf(tokenId) != ownerAddress) {
             revert NotOwner(); // Or a more specific error like NotTokenOwner
        }
        _;
    }

    /// @dev Requires that the caller owns the specified token.
    modifier _requireOwnedByCaller(uint256 tokenId) {
        _requireOwnedBy(tokenId, _msgSender());
        _;
    }

     /// @dev Requires that two tokens are entangled with each other.
    modifier _requireEntangledWith(uint256 tokenId1, uint256 tokenId2) {
        if (!_isEntangled[tokenId1] || _entangledWith[tokenId1] != tokenId2 || _entangledWith[tokenId2] != tokenId1) {
             revert NotEntangledWith(tokenId1, tokenId2);
        }
        _;
    }

    /// @dev Requires that the caller owns both tokens in an entangled pair.
    modifier onlyEntangledPairOwner(uint256 tokenId) {
        _requireEntangled(tokenId);
        uint256 partnerId = _entangledWith[tokenId];
        address pairOwner = ownerOf(tokenId);
        if (pairOwner != _msgSender() || ownerOf(partnerId) != pairOwner) {
             revert NotEntangledPairOwner();
        }
        _;
    }


    // --- Internal Helpers ---

    /// @dev Gets a canonical key for an entangled pair using the minimum token ID.
    function _getPairKey(uint256 tokenId1, uint256 tokenId2) internal pure returns (uint256) {
        return Math.min(tokenId1, tokenId2);
    }

    /// @dev Internal function to safely update a token's charge level within bounds [0, 100].
    function _updateCharge(uint256 tokenId, int256 amount) internal {
        int256 currentCharge = int256(_tokenCharge[tokenId]);
        int256 newCharge = currentCharge + amount;

        if (newCharge < 0) {
            newCharge = 0;
        } else if (newCharge > 100) {
            newCharge = 100;
        }

        _tokenCharge[tokenId] = uint8(newCharge);
        emit ChargeUpdated(tokenId, uint8(newCharge));
    }


    // --- ERC721 Overrides & Hooks ---

    /// @dev Overrides the base URI function.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Overrides the standard tokenURI to potentially include dynamic data.
    /// Note: Implementing truly dynamic JSON metadata often requires an API service
    /// referenced by the URI. This simply returns the base URI + token ID.
    /// A real implementation might append query parameters or route differently
    /// based on token state (_isEntangled, _tokenCharge, etc.) which the URI service reads.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, toString(tokenId)));
        // To include dynamic data, you might modify this, e.g.:
        // string memory dynamicData = string(abi.encodePacked(
        //     "?entangled=", toString(_isEntangled[tokenId]),
        //     "&charge=", toString(_tokenCharge[tokenId])
        // ));
        // return string(abi.encodePacked(currentBaseURI, toString(tokenId), dynamicData));
    }

    /// @dev Overrides the OpenZeppelin hook to prevent standard transfers of entangled tokens.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent standard transfer methods (transferFrom, safeTransferFrom)
        // for entangled tokens. They MUST use transferEntangledPair.
        // This hook runs *before* the owner mapping is updated.
        // from != address(0) excludes minting. to != address(0) excludes burning via _transfer (burn uses _burn).
        if (from != address(0) && to != address(0)) {
            if (_isEntangled[tokenId]) {
                 revert CannotTransferEntangledTokenDirectly();
            }
        }
    }

    // --- Core Mechanics ---

    /// @summary Mints a single new, unentangled Quantum Entangled NFT.
    /// @param to The address to mint the NFT to.
    function mint(address to) external onlyOwner whenNotPaused {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        // Initialize state
        _isEntangled[tokenId] = false;
        _entangledWith[tokenId] = 0;
        _tokenCharge[tokenId] = 50; // Mint with default charge
        _lastUnentangleTime[tokenId] = 0; // No cooldown initially
    }

    /// @summary Mints multiple new, unentangled Quantum Entangled NFTs in a batch.
    /// @param to The address to mint the NFTs to.
    /// @param count The number of NFTs to mint.
    function batchMint(address to, uint256 count) external onlyOwner whenNotPaused {
        require(count > 0, "Count must be greater than 0");
        for (uint i = 0; i < count; i++) {
             uint256 tokenId = _nextTokenId++;
            _safeMint(to, tokenId);
            // Initialize state
            _isEntangled[tokenId] = false;
            _entangledWith[tokenId] = 0;
            _tokenCharge[tokenId] = 50; // Mint with default charge
            _lastUnentangleTime[tokenId] = 0; // No cooldown initially
        }
    }

    /// @summary Entangles two unentangled tokens owned by the caller.
    /// @dev Requires both tokens to be unentangled, owned by the caller, and pays the entanglement fee.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangle(uint256 tokenId1, uint256 tokenId2) external payable whenNotPaused
        _requireOwnedByCaller(tokenId1)
        _requireOwnedByCaller(tokenId2)
        _requireUnentangled(tokenId1)
        _requireUnentangled(tokenId2)
    {
        if (tokenId1 == tokenId2) {
             revert SameTokenID();
        }
        if (msg.value < _entanglementFee) {
             revert ERC721InsufficientPayment(msg.value, _entanglementFee); // Using OZ error
        }

        _collectedFees += msg.value;

        // Set entanglement links
        _entangledWith[tokenId1] = tokenId2;
        _entangledWith[tokenId2] = tokenId1;
        _isEntangled[tokenId1] = true;
        _isEntangled[tokenId2] = true;

        // Potentially modify charge upon entanglement? e.g., average charges
        // _tokenCharge[tokenId1] = _tokenCharge[tokenId2] = uint8((uint256(_tokenCharge[tokenId1]) + uint256(_tokenCharge[tokenId2])) / 2);

        emit Entangled(tokenId1, tokenId2);
    }

    /// @summary Unentangles a pair of tokens.
    /// @dev Requires the caller to own one of the tokens in the pair.
    /// Subject to the unentanglement cooldown for the token used in the call.
    /// @param tokenId The ID of one token in the pair to unentangle.
    function unentangle(uint256 tokenId) external whenNotPaused _requireOwnedByCaller(tokenId) _requireEntangled(tokenId) {
        uint256 partnerId = _entangledWith[tokenId];

        // Check if the partner is also owned by the caller (should be, due to transfer restriction)
        _requireOwnedByCaller(partnerId);

        // Check cooldown for *this* token specifically
        uint40 lastUnentangle = _lastUnentangleTime[tokenId];
        uint40 timeSinceLastUnentangle = uint40(block.timestamp) - lastUnentangle;
        if (lastUnentangle != 0 && timeSinceLastUnentangle < _unentanglementCooldownDuration) {
             revert UnentanglementCooldown(_unentanglementCooldownDuration - timeSinceLastUnentangle);
        }

        // Break entanglement links
        _entangledWith[tokenId] = 0;
        _entangledWith[partnerId] = 0;
        _isEntangled[tokenId] = false;
        _isEntangled[partnerId] = false;

        // Record unentanglement time for cooldown
        _lastUnentangleTime[tokenId] = uint40(block.timestamp);
        _lastUnentangleTime[partnerId] = uint40(block.timestamp); // Cooldown applies to both tokens independently

        emit Unentangled(tokenId, partnerId);
    }

    /// @summary Transfers an entangled token and its partner together.
    /// @dev This is the required method for transferring entangled tokens.
    /// Uses the internal _transfer which should respect the Pausable state.
    /// @param from The address transferring the tokens.
    /// @param to The address receiving the tokens.
    /// @param tokenId1 The ID of one token in the entangled pair to transfer.
    function transferEntangledPair(address from, address to, uint256 tokenId1) external whenNotPaused {
        _requireEntangled(tokenId1);
        uint256 tokenId2 = _entangledWith[tokenId1];

        // Ensure caller is authorized (owner or approved for all)
        if (!_isApprovedOrOwner(_msgSender(), tokenId1) || !_isApprovedOrOwner(_msgSender(), tokenId2)) {
            revert ERC721InsufficientApproval(msg.sender, tokenId1); // Use OZ error
        }

        // Ensure 'from' actually owns both tokens
        _requireOwnedBy(tokenId1, from);
        _requireOwnedBy(tokenId2, from);

        if (to == address(0)) revert ERC721InvalidReceiver(address(0));

        // Perform the transfers using the internal OZ method
        // The _beforeTokenTransfer hook check for _isEntangled is skipped here
        // because we are calling _transfer directly *within* this function,
        // and the hook's logic is designed to push users towards *this* function.
        // We rely on the logic *within this function* to ensure pairing.
        _transfer(from, to, tokenId1);
        _transfer(from, to, tokenId2);

        emit PairTransferred(from, to, tokenId1, tokenId2);
    }

    /// @summary Allows the owner of an entangled pair to interact with it.
    /// @dev Affects the charge level and updates interaction stats. Subject to pair cooldown.
    /// @param tokenId The ID of one token in the entangled pair.
    function interactWithPair(uint256 tokenId) external whenNotPaused onlyEntangledPairOwner(tokenId) {
        uint256 partnerId = _entangledWith[tokenId];
        uint256 pairKey = _getPairKey(tokenId, partnerId);

        // Check pair interaction cooldown
        uint40 lastInteraction = _lastPairInteractionTime[pairKey];
        uint40 timeSinceLastInteraction = uint40(block.timestamp) - lastInteraction;
        if (lastInteraction != 0 && timeSinceLastInteraction < interactionCooldownDuration) {
             revert InteractionCooldown(interactionCooldownDuration - timeSinceLastInteraction);
        }

        // Apply charge effect to both tokens in the pair
        _updateCharge(tokenId, _interactionChargeEffect);
        _updateCharge(partnerId, _interactionChargeEffect); // Partner charge updates too

        // Update interaction stats
        _pairInteractionCount[pairKey]++;
        _lastPairInteractionTime[pairKey] = uint40(block.timestamp);

        emit PairInteracted(tokenId, partnerId, _pairInteractionCount[pairKey], _tokenCharge[tokenId], _tokenCharge[partnerId]);
    }

    /// @summary Destroys a single, unentangled token.
    /// @dev Requires the caller to be the owner or approved.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) public override whenNotPaused _requireOwnedByCaller(tokenId) _requireUnentangled(tokenId) {
        _burn(tokenId);
        // Clean up custom state (though mappings default to zero/false, explicit is fine)
        delete _isEntangled[tokenId];
        delete _entangledWith[tokenId]; // Should already be 0
        delete _tokenCharge[tokenId];
        delete _lastUnentangleTime[tokenId];
    }

    /// @summary Destroys an entangled token and its partner.
    /// @dev Requires the caller to own one of the tokens in the pair.
    /// @param tokenId1 The ID of one token in the entangled pair to burn.
    function burnEntangledPair(uint256 tokenId1) external whenNotPaused onlyEntangledPairOwner(tokenId1) {
        uint256 tokenId2 = _entangledWith[tokenId1];
        uint256 pairKey = _getPairKey(tokenId1, tokenId2);

        // Clean up custom state *before* burning (especially entanglement)
        _entangledWith[tokenId1] = 0;
        _entangledWith[tokenId2] = 0;
        _isEntangled[tokenId1] = false;
        _isEntangled[tokenId2] = false;
        delete _tokenCharge[tokenId1];
        delete _tokenCharge[tokenId2];
        delete _lastUnentangleTime[tokenId1];
        delete _lastUnentangleTime[tokenId2];
        delete _pairInteractionCount[pairKey];
        delete _lastPairInteractionTime[pairKey];


        // Burn both tokens
        _burn(tokenId1);
        _burn(tokenId2);

        emit PairBurned(tokenId1, tokenId2);
    }


    // --- Configuration Functions (Owner Only) ---

    /// @summary Sets the fee required to entangle two tokens.
    /// @param fee The new entanglement fee in wei.
    function setEntanglementFee(uint256 fee) external onlyOwner {
        _entanglementFee = fee;
    }

    /// @summary Sets the amount charge changes when a pair is interacted with.
    /// @param effect The new charge effect. Can be negative (e.g., -10 to decrease charge).
    function setInteractionChargeEffect(int256 effect) external onlyOwner {
        _interactionChargeEffect = effect;
    }

    /// @summary Sets the cooldown duration after unentangling before a token can be unentangled again.
    /// @param duration The new cooldown duration in seconds.
    function setUnentanglementCooldownDuration(uint40 duration) external onlyOwner {
        _unentanglementCooldownDuration = duration;
    }

     /// @summary Sets the cooldown duration required between interactions for a pair.
    /// @param duration The new cooldown duration in seconds.
    function setInteractionCooldownDuration(uint40 duration) external onlyOwner {
        interactionCooldownDuration = duration;
    }

    /// @summary Sets the base URI for token metadata.
    /// @param baseURI_ The new base URI.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /// @summary Pauses contract operations (minting, entanglement, transfers, interaction).
    function pause() external onlyOwner {
        _pause();
    }

    /// @summary Unpauses contract operations.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @summary Withdraws collected entanglement fees to a recipient address.
    /// @param recipient The address to send the fees to.
    function withdrawFees(address payable recipient) external onlyOwner {
        uint256 fees = _collectedFees;
        _collectedFees = 0;
        (bool success, ) = recipient.call{value: fees}("");
        require(success, "Fee withdrawal failed");
    }

    // --- View Functions ---

    /// @summary Returns the token ID of the entangled partner.
    /// @param tokenId The token ID to query.
    /// @return The partner token ID, or 0 if not entangled.
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        return _entangledWith[tokenId];
    }

    /// @summary Checks if a token is currently entangled.
    /// @param tokenId The token ID to query.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return _isEntangled[tokenId];
    }

    /// @summary Returns the current charge level of a token.
    /// @param tokenId The token ID to query.
    /// @return The charge level (0-100).
    function getTokenCharge(uint256 tokenId) public view returns (uint8) {
        return _tokenCharge[tokenId];
    }

    /// @summary Returns the total interaction count for the pair containing the token.
    /// @param tokenId The token ID to query.
    /// @return The interaction count for the pair.
    function getPairInteractionCount(uint256 tokenId) public view returns (uint256) {
        if (!_isEntangled[tokenId]) return 0;
        uint256 partnerId = _entangledWith[tokenId];
        return _pairInteractionCount[_getPairKey(tokenId, partnerId)];
    }

    /// @summary Returns the timestamp of the last interaction for the pair containing the token.
    /// @param tokenId The token ID to query.
    /// @return The timestamp of the last pair interaction.
    function getLastPairInteractionTime(uint256 tokenId) public view returns (uint40) {
         if (!_isEntangled[tokenId]) return 0;
        uint256 partnerId = _entangledWith[tokenId];
        return _lastPairInteractionTime[_getPairKey(tokenId, partnerId)];
    }

     /// @summary Calculates the time remaining on the unentanglement cooldown for a token.
    /// @param tokenId The token ID to query.
    /// @return The time remaining in seconds. Returns 0 if no cooldown is active or applies.
    function getTimeUntilUnentanglePossible(uint256 tokenId) public view returns (uint40) {
        uint40 lastUnentangle = _lastUnentangleTime[tokenId];
        if (lastUnentangle == 0 || block.timestamp >= lastUnentangle + _unentanglementCooldownDuration) {
            return 0;
        }
        return uint40(lastUnentangle + _unentanglementCooldownDuration - block.timestamp);
    }

    /// @summary Returns the current fee required to entangle two tokens.
    function getEntanglementFee() public view returns (uint256) {
        return _entanglementFee;
    }

    /// @summary Returns the current charge effect amount when interacting with a pair.
    function getInteractionChargeEffect() public view returns (int256) {
        return _interactionChargeEffect;
    }

     /// @summary Returns the current unentanglement cooldown duration.
    function getUnentanglementCooldownDuration() public view returns (uint40) {
        return _unentanglementCooldownDuration;
    }

    /// @summary Returns the base URI used for token metadata.
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /// @summary Returns the total amount of fees collected from entanglement.
    function totalCollectedFees() public view returns (uint256) {
        return _collectedFees;
    }

    // Helper function to convert uint256 to string (from OpenZeppelin's Strings.sol)
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

    // The standard transferFrom and safeTransferFrom methods are handled by ERC721
    // in conjunction with the _beforeTokenTransfer hook, which prevents their
    // use for entangled tokens, forcing the use of transferEntangledPair.
    // We explicitly list them here for clarity that their behavior is modified.

    // /// @inheritdoc ERC721
    // function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
    //     super.transferFrom(from, to, tokenId); // This calls _beforeTokenTransfer
    // }

    // /// @inheritdoc ERC721
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
    //      super.safeTransferFrom(from, to, tokenId); // This calls _beforeTokenTransfer
    // }

    // /// @inheritdoc ERC721
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) {
    //      super.safeTransferFrom(from, to, tokenId, data); // This calls _beforeTokenTransfer
    // }

    // Functions inherited and implicitly available from ERC721, contributing to the function count:
    // - balanceOf(address owner) public view virtual override returns (uint256)
    // - ownerOf(uint256 tokenId) public view virtual override returns (address)
    // - approve(address to, uint256 tokenId) public virtual override
    // - getApproved(uint256 tokenId) public view virtual override returns (address)
    // - setApprovalForAll(address operator, bool approved) public virtual override
    // - isApprovedForAll(address owner, address operator) public view virtual override returns (bool)
    // - supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    // - _exists(uint256 tokenId) internal view virtual returns (bool)

    // Total functions: 26 explicitly coded + at least 8 implicitly available from ERC721 = 34+ functions.
}
```