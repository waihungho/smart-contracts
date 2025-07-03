Okay, let's design a smart contract that incorporates a unique, advanced concept: "Quantum Entanglement Tokens" (QET).

This concept imagines NFTs that can be linked in pairs, and actions performed on one token in an entangled pair have a *probabilistic* chance of affecting the other token simultaneously, simulating a simplified, metaphorical version of quantum entanglement on the blockchain. Additionally, tokens will have a "Potential" state that must be "Revealed" to become their "Actual" state, adding another layer of interaction.

This goes beyond standard ERC-721 by adding custom state (`potential`/`actual`), pairing mechanics, probabilistic effects triggered by standard actions, and a unique 'resonance' feature. It requires careful state management for entangled pairs.

**Concept:** Quantum Entanglement Tokens (QET)
**Mechanism:** ERC-721 based NFTs with added state (`potential`, `actual`), entanglement pairing, probabilistic linked effects (transfer, burn), and resonance boosting.

---

## Smart Contract: QuantumEntanglementTokens

This contract implements an ERC-721 compliant token with unique "quantum-inspired" features:
1.  **Potential & Actual States:** Each token is minted with a `potentialValue` and `potentialType`. These are hidden until the token owner performs a `revealPotential` action, which permanently sets `actualValue` and `actualType` based on the potential, potentially applying a `resonanceModifier`.
2.  **Entanglement:** Two distinct tokens can be entangled by their owners (with consent/fees). Entangled tokens are linked in a symmetric relationship.
3.  **Probabilistic Linked Effects:** Standard actions like transferring or burning an *entangled* token have a configurable probability of *also* performing the same action on its entangled partner.
4.  **Resonance:** Entangled and revealed tokens can trigger a `resonatePair` action, granting a temporary `resonanceBoost` based on their combined properties.
5.  **Fees & Administration:** Basic owner-controlled configuration for fees and probabilities.

---

### Outline:

1.  **License & Pragma**
2.  **Imports** (ERC721, Ownable, SafeMath - or use Solidity 0.8+ built-in overflow checks)
3.  **Errors**
4.  **Events**
5.  **Structs** (`TokenData`)
6.  **State Variables**
    *   ERC-721 state (`_balances`, `_owners`, etc. - handled by base)
    *   Token specific data (`_tokenData`)
    *   Entanglement mapping (`_entangledPartner`)
    *   Entanglement fees (`entanglementFee`, `disentanglementFee`)
    *   Probabilistic effect configuration (`entanglementProbability`)
    *   Resonance configuration (`resonanceEffectDuration`, `resonanceBoostAmount`)
    *   Admin address (`feeCollector`)
    *   Total entangled pairs counter
    *   Next token ID counter
7.  **Modifiers** (Optional, using requires for clarity)
8.  **Constructor**
9.  **ERC-721 Standard Functions (Overrides)**
    *   `supportsInterface`
    *   `_beforeTokenTransfer` (To handle entanglement side effects)
    *   `_burn` (To handle entanglement side effects)
10. **Core QET Functions**
    *   **Minting:** `mintPotential`
    *   **State Management:** `revealPotential`, `upgradePotential`
    *   **Entanglement:** `entanglePair`, `disentanglePair`
    *   **Probabilistic Effects:** `transferWithEntanglement` (override/wrapper), `burnWithEntanglement` (wrapper)
    *   **Resonance:** `resonatePair`
11. **Query/View Functions**
    *   `isEntangled`
    *   `getEntangledToken`
    *   `isPairedWith`
    *   `getTokenState` (Potential/Actual values, types, timestamps)
    *   `getPotential` (View only)
    *   `getActual` (View only)
    *   `checkResonanceBoost`
    *   `getPairStatus` (Combined entanglement info)
    *   `getTotalEntangledPairs`
    *   `getEntanglementFee`
    *   `getDisentanglementFee`
    *   `getEntanglementProbability`
    *   `getResonanceEffectDuration`
    *   `getResonanceBoostAmount`
12. **Admin Functions** (`onlyOwner`)
    *   `setEntanglementFee`
    *   `setDisentanglementFee`
    *   `setEntanglementProbability`
    *   `setResonanceEffectDuration`
    *   `setResonanceBoostAmount`
    *   `withdrawFees`
13. **Internal Helper Functions**
    *   `_triggerProbabilisticEffect`

---

### Function Summary:

1.  `constructor(string name, string symbol, address feeCollectorAddress)`: Initializes the ERC-721 contract, sets name, symbol, and the fee collector address.
2.  `supportsInterface(bytes4 interfaceId)`: Returns true if the contract supports the ERC-721 or ERC-165 interface, and potentially others.
3.  `balanceOf(address owner)`: Returns the number of tokens owned by an address. (Inherited)
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token. (Inherited)
5.  `approve(address to, uint256 tokenId)`: Approves an address to spend a token. (Inherited)
6.  `getApproved(uint256 tokenId)`: Gets the approved address for a token. (Inherited)
7.  `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all owner's tokens. (Inherited)
8.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner. (Inherited)
9.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token. (Inherited)
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers a token. (Inherited)
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers a token with data. (Inherited)
12. `mintPotential(address to, uint256 potentialValue, uint8 potentialType)`: Mints a new token initialized only with potential state.
13. `revealPotential(uint256 tokenId)`: Owner reveals the potential of a token, setting its actual state permanently. Can only be called once.
14. `upgradePotential(uint256 tokenId, uint256 newPotentialValue, uint8 newPotentialType)`: Owner can update the potential state of a token *before* it is revealed.
15. `entanglePair(uint256 tokenId1, uint256 tokenId2)`: Entangles two tokens. Requires both tokens to be owned by the caller or approved, not already entangled, and payment of the entanglement fee. Establishes a symmetric link.
16. `disentanglePair(uint256 tokenId)`: Disentangles a pair of tokens given one token's ID. Requires ownership of the token and payment of the disentanglement fee. Breaks the symmetric link.
17. `transferWithEntanglement(address to, uint256 tokenId)`: Initiates a transfer of `tokenId`. If `tokenId` is entangled, there's a probability its partner is also transferred to the same recipient. Requires ownership/approval.
18. `burnWithEntanglement(uint256 tokenId)`: Initiates burning of `tokenId`. If `tokenId` is entangled, there's a probability its partner is also burned. Requires ownership/approval.
19. `resonatePair(uint256 tokenId)`: If `tokenId` is entangled and both tokens in the pair are revealed, this triggers a temporary resonance boost effect based on their actual states. Requires ownership of the token.
20. `isEntangled(uint256 tokenId)`: Returns true if the token is entangled.
21. `getEntangledToken(uint256 tokenId)`: Returns the ID of the token entangled with `tokenId`, or 0 if not entangled.
22. `isPairedWith(uint256 tokenId1, uint256 tokenId2)`: Returns true if `tokenId1` and `tokenId2` are entangled together.
23. `getTokenState(uint256 tokenId)`: Returns all state data for a token: potential/actual values, types, revelation timestamp, resonance expiry.
24. `getPotential(uint256 tokenId)`: Returns the potential value and type of a token.
25. `getActual(uint256 tokenId)`: Returns the actual value and type of a token. (Only meaningful after revelation).
26. `checkResonanceBoost(uint256 tokenId)`: Returns the current resonance boost amount for a token, considering expiry.
27. `getPairStatus(uint256 tokenId)`: Returns a struct containing entanglement status and partner ID.
28. `getTotalEntangledPairs()`: Returns the total number of active entangled pairs.
29. `getEntanglementFee()`: Returns the current fee to entangle a pair.
30. `getDisentanglementFee()`: Returns the current fee to disentangle a pair.
31. `getEntanglementProbability()`: Returns the probability (0-100) of the entangled effect triggering.
32. `getResonanceEffectDuration()`: Returns the duration of the resonance boost in seconds.
33. `getResonanceBoostAmount()`: Returns the fixed amount added during resonance boost.
34. `setEntanglementFee(uint256 fee)`: (Admin) Sets the fee to entangle tokens.
35. `setDisentanglementFee(uint256 fee)`: (Admin) Sets the fee to disentangle tokens.
36. `setEntanglementProbability(uint256 probability)`: (Admin) Sets the probability (0-100) for entangled effects.
37. `setResonanceEffectDuration(uint64 duration)`: (Admin) Sets the duration of the resonance boost in seconds.
38. `setResonanceBoostAmount(uint256 amount)`: (Admin) Sets the amount added during resonance boost.
39. `withdrawFees(address payable recipient)`: (Admin) Allows the fee collector to withdraw collected fees.

*(Total functions listed: 39. Exceeds the minimum 20)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although not strictly needed in 0.8+, good practice with potential calculations

// --- Smart Contract: QuantumEntanglementTokens ---
// This contract implements an ERC-721 compliant token with unique "quantum-inspired" features:
// 1. Potential & Actual States: Each token is minted with a potentialValue and potentialType. These are hidden until revelation.
// 2. Entanglement: Two distinct tokens can be entangled, linking them symmetrically.
// 3. Probabilistic Linked Effects: Actions (transfer, burn) on an entangled token have a chance of affecting its partner.
// 4. Resonance: Entangled and revealed tokens can trigger a temporary resonance boost effect.
// 5. Fees & Administration: Basic owner-controlled configuration.
//
// --- Outline ---
// 1. License & Pragma
// 2. Imports (ERC721, Ownable, Context, Counters, SafeMath)
// 3. Errors
// 4. Events
// 5. Structs (TokenData)
// 6. State Variables
// 7. Constructor
// 8. ERC-721 Standard Functions (Overrides)
// 9. Core QET Functions (Minting, State, Entanglement, Effects, Resonance)
// 10. Query/View Functions
// 11. Admin Functions
// 12. Internal Helper Functions
//
// --- Function Summary ---
// 1.  constructor: Initializes the contract.
// 2.  supportsInterface: ERC-165 interface check.
// 3.  balanceOf: ERC-721: Number of tokens owned by an address. (Inherited)
// 4.  ownerOf: ERC-721: Owner of a token. (Inherited)
// 5.  approve: ERC-721: Approve address for token. (Inherited)
// 6.  getApproved: ERC-721: Get approved address. (Inherited)
// 7.  setApprovalForAll: ERC-721: Set operator approval. (Inherited)
// 8.  isApprovedForAll: ERC-721: Check operator approval. (Inherited)
// 9.  transferFrom: ERC-721: Transfer token. (Inherited)
// 10. safeTransferFrom: ERC-721: Safe transfer token. (Inherited)
// 11. safeTransferFrom: ERC-721: Safe transfer token with data. (Inherited)
// 12. mintPotential: Mints a new token with only potential state.
// 13. revealPotential: Owner reveals the potential of a token.
// 14. upgradePotential: Owner updates token potential before revelation.
// 15. entanglePair: Entangles two tokens (requires fee).
// 16. disentanglePair: Disentangles a pair (requires fee).
// 17. transferWithEntanglement: Transfers token, possibly partner (probabilistic).
// 18. burnWithEntanglement: Burns token, possibly partner (probabilistic).
// 19. resonatePair: Triggers temporary resonance boost for an entangled pair.
// 20. isEntangled: Checks if a token is entangled.
// 21. getEntangledToken: Gets the partner ID for an entangled token.
// 22. isPairedWith: Checks if two specific tokens are entangled.
// 23. getTokenState: Gets all state data for a token.
// 24. getPotential: Gets potential value/type.
// 25. getActual: Gets actual value/type.
// 26. checkResonanceBoost: Gets current resonance boost (considering expiry).
// 27. getPairStatus: Gets entanglement status and partner.
// 28. getTotalEntangledPairs: Gets total active entangled pairs count.
// 29. getEntanglementFee: Gets current entanglement fee.
// 30. getDisentanglementFee: Gets current disentanglement fee.
// 31. getEntanglementProbability: Gets current entangled effect probability.
// 32. getResonanceEffectDuration: Gets resonance duration.
// 33. getResonanceBoostAmount: Gets resonance boost amount.
// 34. setEntanglementFee: (Admin) Sets entanglement fee.
// 35. setDisentanglementFee: (Admin) Sets disentanglement fee.
// 36. setEntanglementProbability: (Admin) Sets probability.
// 37. setResonanceEffectDuration: (Admin) Sets resonance duration.
// 38. setResonanceBoostAmount: (Admin) Sets resonance boost amount.
// 39. withdrawFees: (Admin) Withdraws collected fees.

contract QuantumEntanglementTokens is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For potential future calculations, though 0.8+ handles simple cases

    Counters.Counter private _nextTokenId;

    // --- Errors ---
    error TokenDoesNotExist(uint256 tokenId);
    error TokenAlreadyExists(uint256 tokenId); // Should not happen with Counters
    error NotTokenOwnerOrApproved(uint256 tokenId);
    error TokenAlreadyRevealed(uint256 tokenId);
    error TokenNotRevealed(uint256 tokenId);
    error TokensMustBeDifferent(uint256 tokenId1, uint256 tokenId2);
    error TokensMustBeOwnedOrApproved(uint256 tokenId1, uint256 tokenId2);
    error TokensAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
    error TokenNotEntangled(uint256 tokenId);
    error InvalidProbability(uint256 probability);
    error EntanglementFeeNotPaid(uint256 required, uint256 sent);
    error DisentanglementFeeNotPaid(uint256 required, uint256 sent);
    error ResonanceConditionNotMet(uint256 tokenId);

    // --- Events ---
    event PotentialMinted(address indexed owner, uint256 indexed tokenId, uint256 potentialValue, uint8 potentialType);
    event PotentialRevealed(uint256 indexed tokenId, uint256 actualValue, uint8 actualType);
    event PotentialUpgraded(uint256 indexed tokenId, uint256 newPotentialValue, uint8 newPotentialType);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Disentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event ProbabilisticEffectTriggered(uint256 indexed primaryTokenId, uint256 indexed secondaryTokenId, string effect); // e.g., "transfer", "burn"
    event ResonanceTriggered(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 boostAmount, uint64 duration);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Structs ---
    struct TokenData {
        uint256 potentialValue;
        uint256 actualValue; // Set on reveal
        uint8 potentialType;
        uint8 actualType; // Set on reveal
        uint64 revelationTimestamp; // 0 if not revealed
        uint64 resonanceBoostExpiry; // Timestamp when boost ends
    }

    // --- State Variables ---
    mapping(uint256 => TokenData) private _tokenData;
    mapping(uint256 => uint256) private _entangledPartner; // tokenId => entangled_tokenId (0 if not entangled)

    uint256 public entanglementFee = 0; // Fee to entangle a pair
    uint256 public disentanglementFee = 0; // Fee to disentangle a pair
    uint256 public entanglementProbability = 50; // Probability (0-100) of probabilistic effect triggering
    uint64 public resonanceEffectDuration = 1 days; // Duration of resonance boost in seconds
    uint256 public resonanceBoostAmount = 100; // Example boost amount (can be interpreted based on dapp logic)

    address payable public feeCollector;
    uint256 private _totalEntangledPairs;

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address payable feeCollectorAddress)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(feeCollectorAddress != address(0), "Invalid fee collector address");
        feeCollector = feeCollectorAddress;
    }

    // --- ERC-721 Standard Functions (Overrides) ---

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // Internal function called before any token transfer
    // We can use this to potentially trigger entanglement transfer effect
    // Note: This override approach intercepts ALL transfers, including safeTransferFrom
    // This simplifies the logic for transferWithEntanglement but requires care.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (batchSize > 1) revert("Batch transfers not supported with entanglement mechanics"); // Prevent issues with batch transfers

        if (from == address(0)) {
            // Minting - handled in _safeMint which calls this
            // No entanglement transfer needed here
        } else if (to == address(0)) {
            // Burning - handled by _burn override which calls this
            // Probabilistic burn handled in burnWithEntanglement wrapper
        } else {
            // Transferring
            // If a token is transferred *without* transferWithEntanglement,
            // should entanglement persist? Let's say yes, but the *probabilistic linked transfer*
            // only happens via transferWithEntanglement.
            // We need to ensure entangled partners are NOT transferred via standard transferFrom
            // or safeTransferFrom unless explicitly linked via transferWithEntanglement.
            // The logic for probabilistic transfer should be in a wrapper function,
            // not triggered *within* _beforeTokenTransfer for standard transfers.
            // Let's refine: standard transfers move ONLY the specified token.
            // transferWithEntanglement will call _safeTransfer internally if probability triggers.
        }
    }

    // Internal function called after a token is burned
    // We can use this to potentially trigger entanglement burn effect
    function _burn(uint256 tokenId) internal virtual override {
        // Before burning, check if it's entangled and trigger probabilistic burn *if* called
        // by burnWithEntanglement. However, we need a way to know if the burn is intentional
        // or a probabilistic cascade. A flag or separate internal function is needed.
        // Let's assume `burnWithEntanglement` is the *only* way to burn entangled tokens.
        // Standard _burn called by ERC721 functions (like transfer to address(0)) should
        // disentangle first.
        uint256 partnerId = _entangledPartner[tokenId];
        if (partnerId != 0) {
             // Token is entangled, disentangle it before the burn completes.
             // This ensures a standard burn doesn't leave a dangling partner.
             _disentanglePair(tokenId, partnerId);
        }

        // Clear token data before burning
        delete _tokenData[tokenId];

        super._burn(tokenId);
    }


    // --- Core QET Functions ---

    /// @notice Mints a new token initialized with only its potential state.
    /// @param to The address to mint the token to.
    /// @param potentialValue The initial potential value.
    /// @param potentialType The initial potential type.
    function mintPotential(address to, uint256 potentialValue, uint8 potentialType) public onlyOwner {
        _nextTokenId.increment();
        uint256 newTokenId = _nextTokenId.current();

        _tokenData[newTokenId] = TokenData({
            potentialValue: potentialValue,
            actualValue: 0, // Unset
            potentialType: potentialType,
            actualType: 0, // Unset
            revelationTimestamp: 0, // Not revealed
            resonanceBoostExpiry: 0 // No boost
        });

        _safeMint(to, newTokenId);
        emit PotentialMinted(to, newTokenId, potentialValue, potentialType);
    }

    /// @notice Allows the owner or approved address to reveal the potential of a token.
    /// This action is permanent and sets the actual value and type.
    /// @param tokenId The ID of the token to reveal.
    function revealPotential(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotTokenOwnerOrApproved(tokenId);
        }
        if (_tokenData[tokenId].revelationTimestamp != 0) {
            revert TokenAlreadyRevealed(tokenId);
        }

        TokenData storage data = _tokenData[tokenId];
        data.actualValue = data.potentialValue; // Simple example, could be complex calculation
        data.actualType = data.potentialType;   // Simple example
        data.revelationTimestamp = uint64(block.timestamp);

        emit PotentialRevealed(tokenId, data.actualValue, data.actualType);
    }

    /// @notice Allows the owner or approved address to upgrade the potential state of a token before it is revealed.
    /// @param tokenId The ID of the token to upgrade.
    /// @param newPotentialValue The new potential value.
    /// @param newPotentialType The new potential type.
    function upgradePotential(uint256 tokenId, uint256 newPotentialValue, uint8 newPotentialType) public {
        address owner = ownerOf(tokenId);
         if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotTokenOwnerOrApproved(tokenId);
        }
        if (_tokenData[tokenId].revelationTimestamp != 0) {
            revert TokenAlreadyRevealed(tokenId);
        }

        TokenData storage data = _tokenData[tokenId];
        data.potentialValue = newPotentialValue;
        data.potentialType = newPotentialType;

        emit PotentialUpgraded(tokenId, newPotentialValue, newPotentialType);
    }

    /// @notice Entangles two distinct tokens, requiring payment of the entanglement fee.
    /// Both tokens must be owned by the caller or approved.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entanglePair(uint256 tokenId1, uint256 tokenId2) public payable {
        if (tokenId1 == tokenId2) {
            revert TokensMustBeDifferent(tokenId1, tokenId2);
        }
        if (_entangledPartner[tokenId1] != 0 || _entangledPartner[tokenId2] != 0) {
            revert TokensAlreadyEntangled(tokenId1, tokenId2);
        }
        if (msg.value < entanglementFee) {
            revert EntanglementFeeNotPaid(entanglementFee, msg.value);
        }

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        if (owner1 != _msgSender() && !isApprovedForAll(owner1, _msgSender())) {
            revert TokensMustBeOwnedOrApproved(tokenId1, tokenId2);
        }
         if (owner2 != _msgSender() && !isApprovedForAll(owner2, _msgSender())) {
            revert TokensMustBeOwnedOrApproved(tokenId1, tokenId2);
        }

        _entangledPartner[tokenId1] = tokenId2;
        _entangledPartner[tokenId2] = tokenId1;
        _totalEntangledPairs++;

        // Send paid fee to the collector
        if (msg.value > 0) {
             (bool success, ) = feeCollector.call{value: msg.value}("");
             require(success, "Fee transfer failed");
        }


        emit Entangled(tokenId1, tokenId2);
    }

    /// @notice Disentangles a pair of tokens given the ID of one token, requiring payment of the disentanglement fee.
    /// The caller must own or be approved for the token.
    /// @param tokenId The ID of one token in the entangled pair.
    function disentanglePair(uint256 tokenId) public payable {
        uint256 partnerId = _entangledPartner[tokenId];
        if (partnerId == 0) {
            revert TokenNotEntangled(tokenId);
        }

        address owner = ownerOf(tokenId);
         if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotTokenOwnerOrApproved(tokenId);
        }

        if (msg.value < disentanglementFee) {
            revert DisentanglementFeeNotPaid(disentanglementFee, msg.value);
        }

        _disentanglePair(tokenId, partnerId);

         // Send paid fee to the collector
        if (msg.value > 0) {
             (bool success, ) = feeCollector.call{value: msg.value}("");
             require(success, "Fee transfer failed");
        }

        emit Disentangled(tokenId, partnerId);
    }

    /// @notice Transfers the specified token. If entangled, has a probability of also transferring its partner to the same recipient.
    /// Requires ownership or approval of the token.
    /// @param to The address to transfer the token(s) to.
    /// @param tokenId The ID of the token to transfer.
    function transferWithEntanglement(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
         if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotTokenOwnerOrApproved(tokenId);
        }

        uint256 partnerId = _entangledPartner[tokenId];

        // Always transfer the primary token
        _safeTransfer(owner, to, tokenId);

        if (partnerId != 0) {
            // If entangled, trigger probabilistic effect for the partner
            if (_triggerProbabilisticEffect()) {
                 // Check if partner still exists and is owned by the original owner of tokenId
                 // (Could be transferred away between the first transfer and here, though unlikely in a single tx)
                 // Or, more simply, just attempt the transfer and let ERC721 handle ownership checks
                 // Let's attempt transfer - ERC721 _transfer will check ownership.
                 // However, the *intent* is to move the partner if the *original* owner owned it.
                 // Let's require the partner to also be owned by the original owner of tokenId
                 // when the transferWithEntanglement function is called.
                 address partnerOwner = ownerOf(partnerId);
                 if (partnerOwner == owner) {
                      _safeTransfer(partnerOwner, to, partnerId);
                      emit ProbabilisticEffectTriggered(tokenId, partnerId, "transfer");
                 } else {
                     // Log or handle case where partner changed owner?
                     // For simplicity, if owner changed, entanglement effect fails.
                 }

            }
        }
    }

    /// @notice Burns the specified token. If entangled, has a probability of also burning its partner.
    /// Requires ownership or approval of the token.
    /// @param tokenId The ID of the token to burn.
    function burnWithEntanglement(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
         if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotTokenOwnerOrApproved(tokenId);
        }

        uint256 partnerId = _entangledPartner[tokenId];

        // Always burn the primary token
        // _burn will automatically disentangle it
        _burn(tokenId);

        if (partnerId != 0) {
            // If entangled, trigger probabilistic effect for the partner
            // Check if partner still exists and was owned by the original owner
            // when burnWithEntanglement was called.
             address partnerOwner = ownerOf(partnerId); // ownerOf will revert if token doesn't exist
             if (partnerOwner == owner) { // Check if partner owner is same as original owner of tokenId
                if (_triggerProbabilisticEffect()) {
                    // Use internal _burn function for the partner
                     _burn(partnerId); // This will trigger disentanglement for the partner too
                     emit ProbabilisticEffectTriggered(tokenId, partnerId, "burn");
                }
            } else {
                // Partner is no longer owned by the same person, effect fails.
            }
        }
    }

     /// @notice If the token is entangled and both tokens in the pair are revealed, triggers a temporary resonance boost.
     /// Requires ownership or approval of the token.
     /// @param tokenId The ID of one token in the entangled pair.
    function resonatePair(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
         if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotTokenOwnerOrApproved(tokenId);
        }

        uint256 partnerId = _entangledPartner[tokenId];
        if (partnerId == 0) {
            revert TokenNotEntangled(tokenId);
        }

        // Get state for both tokens
        TokenData storage data1 = _tokenData[tokenId];
        TokenData storage data2 = _tokenData[partnerId];

        // Check if both tokens are revealed
        if (data1.revelationTimestamp == 0 || data2.revelationTimestamp == 0) {
            revert ResonanceConditionNotMet(tokenId); // e.g., "Pair not revealed"
        }

        // Trigger resonance boost
        uint64 expiryTimestamp = uint64(block.timestamp + resonanceEffectDuration);
        data1.resonanceBoostExpiry = expiryTimestamp;
        data2.resonanceBoostExpiry = expiryTimestamp; // Boost applies to both

        // The boost amount and interpretation depend on external logic/dapp
        // Contract just records the expiry.
        emit ResonanceTriggered(tokenId, partnerId, resonanceBoostAmount, resonanceEffectDuration);
    }


    // --- Query/View Functions ---

    /// @notice Checks if a token is currently entangled.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        // Revert if token doesn't exist (standard ERC721 ownerOf behavior)
        ownerOf(tokenId); // Implicit existence check
        return _entangledPartner[tokenId] != 0;
    }

    /// @notice Gets the partner token ID if the token is entangled.
    /// @param tokenId The ID of the token.
    /// @return The partner token ID, or 0 if not entangled.
    function getEntangledToken(uint256 tokenId) public view returns (uint256) {
         ownerOf(tokenId); // Implicit existence check
        return _entangledPartner[tokenId];
    }

    /// @notice Checks if two specific tokens are entangled together.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    /// @return True if the tokens are entangled with each other, false otherwise.
    function isPairedWith(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
         ownerOf(tokenId1); // Implicit existence check
         ownerOf(tokenId2); // Implicit existence check
        return _entangledPartner[tokenId1] == tokenId2 && _entangledPartner[tokenId2] == tokenId1 && tokenId1 != 0 && tokenId2 != 0;
    }

    /// @notice Gets all state data for a token.
    /// @param tokenId The ID of the token.
    /// @return A struct containing the token's state data.
    function getTokenState(uint256 tokenId) public view returns (TokenData memory) {
         ownerOf(tokenId); // Implicit existence check
        return _tokenData[tokenId];
    }

    /// @notice Gets the potential value and type of a token.
    /// @param tokenId The ID of the token.
    /// @return potentialValue The potential value.
    /// @return potentialType The potential type.
    function getPotential(uint256 tokenId) public view returns (uint256 potentialValue, uint8 potentialType) {
        ownerOf(tokenId); // Implicit existence check
        TokenData storage data = _tokenData[tokenId];
        return (data.potentialValue, data.potentialType);
    }

     /// @notice Gets the actual value and type of a token. Only meaningful after revelation.
    /// @param tokenId The ID of the token.
    /// @return actualValue The actual value.
    /// @return actualType The actual type.
    function getActual(uint256 tokenId) public view returns (uint256 actualValue, uint8 actualType) {
        ownerOf(tokenId); // Implicit existence check
        TokenData storage data = _tokenData[tokenId];
        return (data.actualValue, data.actualType);
    }

    /// @notice Checks the current resonance boost amount for a token, considering expiry.
    /// @param tokenId The ID of the token.
    /// @return The active resonance boost amount (0 if expired or not boosted).
    function checkResonanceBoost(uint256 tokenId) public view returns (uint256) {
         ownerOf(tokenId); // Implicit existence check
         TokenData storage data = _tokenData[tokenId];
         if (data.resonanceBoostExpiry > 0 && data.resonanceBoostExpiry >= block.timestamp) {
             return resonanceBoostAmount;
         }
         return 0;
    }

     /// @notice Gets the entanglement status and partner ID for a token.
    /// @param tokenId The ID of the token.
    /// @return isEntangled_ True if entangled.
    /// @return partnerTokenId The partner's ID (0 if not entangled).
    function getPairStatus(uint256 tokenId) public view returns (bool isEntangled_, uint256 partnerTokenId) {
        ownerOf(tokenId); // Implicit existence check
        uint256 partnerId = _entangledPartner[tokenId];
        return (partnerId != 0, partnerId);
    }

    /// @notice Gets the total number of active entangled pairs.
    /// @return The count of entangled pairs.
    function getTotalEntangledPairs() public view returns (uint256) {
        return _totalEntangledPairs;
    }

    /// @notice Gets the current entanglement fee.
    /// @return The fee amount in wei.
    function getEntanglementFee() public view returns (uint256) {
        return entanglementFee;
    }

    /// @notice Gets the current disentanglement fee.
    /// @return The fee amount in wei.
    function getDisentanglementFee() public view returns (uint256) {
        return disentanglementFee;
    }

     /// @notice Gets the current probability (0-100) for entangled effects to trigger.
    /// @return The probability percentage.
    function getEntanglementProbability() public view returns (uint256) {
        return entanglementProbability;
    }

    /// @notice Gets the duration of the resonance boost in seconds.
    /// @return The duration in seconds.
    function getResonanceEffectDuration() public view returns (uint64) {
        return resonanceEffectDuration;
    }

    /// @notice Gets the amount added during resonance boost.
    /// @return The boost amount.
    function getResonanceBoostAmount() public view returns (uint256) {
        return resonanceBoostAmount;
    }


    // --- Admin Functions ---

    /// @notice (Admin) Sets the fee required to entangle a pair of tokens.
    /// @param fee The new entanglement fee in wei.
    function setEntanglementFee(uint256 fee) public onlyOwner {
        entanglementFee = fee;
    }

    /// @notice (Admin) Sets the fee required to disentangle a pair of tokens.
    /// @param fee The new disentanglement fee in wei.
    function setDisentanglementFee(uint256 fee) public onlyOwner {
        disentanglementFee = fee;
    }

    /// @notice (Admin) Sets the probability (0-100) for probabilistic entangled effects to trigger.
    /// @param probability The new probability percentage (0-100).
    function setEntanglementProbability(uint256 probability) public onlyOwner {
        if (probability > 100) {
            revert InvalidProbability(probability);
        }
        entanglementProbability = probability;
    }

     /// @notice (Admin) Sets the duration of the resonance boost in seconds.
    /// @param duration The new duration in seconds.
    function setResonanceEffectDuration(uint64 duration) public onlyOwner {
        resonanceEffectDuration = duration;
    }

    /// @notice (Admin) Sets the amount added during resonance boost.
    /// @param amount The new boost amount.
    function setResonanceBoostAmount(uint256 amount) public onlyOwner {
        resonanceBoostAmount = amount;
    }


    /// @notice (Admin) Allows the designated fee collector to withdraw accumulated fees.
    /// @param recipient The address to send the fees to.
    function withdrawFees(address payable recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(recipient, balance);
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to trigger the probabilistic effect based on configured probability.
    /// NOTE: Using blockhash is NOT cryptographically secure and should not be used for
    /// high-value decisions in production. Chainlink VRF or similar is recommended for real randomness.
    /// @return True if the probabilistic effect should trigger, false otherwise.
    function _triggerProbabilisticEffect() internal view returns (bool) {
        // Simple, insecure pseudo-randomness for demonstration
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, block.number))) % 100;
        return randomNumber < entanglementProbability;
    }

    /// @dev Internal function to disentangle a pair, updating mappings and counters.
    /// Assumes validity checks (entangled, ownership) have been done by the caller.
    /// @param tokenId1 The ID of the first token in the pair.
    /// @param tokenId2 The ID of the second token in the pair.
    function _disentanglePair(uint256 tokenId1, uint256 tokenId2) internal {
        delete _entangledPartner[tokenId1];
        delete _entangledPartner[tokenId2];
        _totalEntangledPairs--;
    }
}
```