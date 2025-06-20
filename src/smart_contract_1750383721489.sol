Okay, let's design a smart contract that simulates a conceptual idea inspired by quantum entanglement, applied to NFTs. These NFTs will have internal states that can be linked, and actions on one can instantaneously affect its "entangled" partner, even if owned by different addresses. This goes beyond standard ERC721 by adding complex state management and interaction rules between tokens.

We'll call it `QuantumEntangledNFTs`.

---

**Outline and Function Summary:**

**Contract Name:** `QuantumEntangledNFTs`

**Description:**
An ERC721-compliant smart contract for managing unique digital assets (NFTs) with dynamic internal states (`energy`, `status`, `chargeCycles`). The core advanced concept is the ability to "entangle" pairs of these NFTs. When entangled, actions performed on one token in a pair can trigger corresponding, often inverse or complementary, state changes or resource consumption on its entangled partner. This simulates a deterministic, contract-level linkage independent of ownership or physical distance (represented by unrelated wallet addresses).

**Core Concepts:**
1.  **Dynamic NFT State:** Each token has mutable properties (`energy`, `status`).
2.  **Quantum Entanglement Simulation:** A state linkage between two specific tokens.
3.  **Paired Actions/Effects:** Functions that behave differently or affect both tokens when they are entangled.
4.  **Shared Resources:** Entangled pairs might share or jointly consume resources (`chargeCycles`).
5.  **Entanglement Lifecycle:** Requesting, confirming, and disentangling pairs.
6.  **Admin Controls:** Pausing, fee management, emergency disentanglement.

**Inheritance:**
*   `ERC721`: Standard NFT functionality.
*   `Ownable`: Contract ownership management.
*   `Pausable`: Allows pausing critical contract operations.

**State Variables:**
*   `_tokenStates`: Maps token ID to its dynamic state struct (`TokenState`).
*   `_entangledPartner`: Maps token ID to its entangled partner's ID (0 if not entangled).
*   `_pairChargeCycles`: Maps the lower ID of an entangled pair to their shared charge cycles.
*   `_pendingEntanglementRequest`: Maps requester token ID to the requested token ID.
*   `_entanglementCooldown`: Time required between disentanglements for a pair.
*   `_lastDisentangleTime`: Maps the lower ID of an entangled pair to the timestamp of their last disentanglement.
*   `_feeRecipient`: Address receiving collected fees.
*   `_rechargeFee`: Fee amount required to recharge pair cycles.
*   `MAX_ENERGY`, `MIN_ENERGY`, `MAX_CHARGE_CYCLES`, `ACTION_COOLDOWN`: Constants defining state limits and cooldowns.

**Structs:**
*   `TokenState`: Holds `energy` (uint), `status` (bool), and `lastActionTimestamp` (uint).

**Events:**
*   `Minted`: Log when token(s) are minted.
*   `StateChanged`: Log changes to a token's state.
*   `PairCyclesChanged`: Log changes to an entangled pair's charge cycles.
*   `EntanglementRequested`: Log a new entanglement request.
*   `EntanglementConfirmed`: Log a successful entanglement.
*   `EntanglementRejected`: Log a rejected entanglement request.
*   `Disentangled`: Log when tokens are disentangled.
*   `ActionPerformed`: Log when `performAction` is called on a token.
*   `FeeWithdrawn`: Log fee withdrawal.
*   `BaseURISet`: Log base URI update.
*   `FeeRecipientSet`: Log fee recipient update.
*   `RechargeFeeSet`: Log recharge fee update.
*   `EntanglementCooldownSet`: Log entanglement cooldown update.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `whenNotPaused`: Prevents execution when paused.
*   `whenPaused`: Allows execution only when paused (less common, but possible for specific admin tasks).
*   `onlyTokenOwnerOrApproved`: Restricts access to the token owner or an approved address/operator.
*   `onlyEntangled`: Requires the target token to be entangled.
*   `notEntangled`: Requires the target token *not* to be entangled.
*   `pairNotOnCooldown`: Requires the entangled pair not to be on disentanglement cooldown.

**Function Summary (20+ Functions):**

**I. Standard ERC721 Functions (Modified/Overridden):**
1.  `balanceOf(address owner)`: Returns the number of tokens owned by an address. (Standard)
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a token. (Standard)
3.  `approve(address to, uint256 tokenId)`: Grants approval to one address for a specific token. (Standard)
4.  `getApproved(uint256 tokenId)`: Returns the approved address for a token. (Standard)
5.  `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for an operator to manage all tokens. (Standard)
6.  `isApprovedForAll(address owner, address operator)`: Checks if an operator has approval for all tokens of an owner. (Standard)
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a token. *Modified:* Will disentangle the token if entangled.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer, checks recipient. *Modified:* Will disentangle the token if entangled.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data, checks recipient. *Modified:* Will disentangle the token if entangled.
10. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token. (Standard, uses base URI).

**II. Minting Functions:**
11. `mint(address to)`: Mints a single new token to an address. (Owner only). Initializes state.
12. `batchMint(address to, uint256 count)`: Mints multiple new tokens to an address. (Owner only). Initializes state.

**III. Dynamic State Management Functions:**
13. `getTokenState(uint256 tokenId)`: View function to retrieve a token's current state (`energy`, `status`, `lastActionTimestamp`).
14. `modifyEnergy(uint256 tokenId, int256 amount)`: Changes the `energy` state of a token. Requires owner/approved. *Effect:* If entangled, partner's energy changes by `-amount`. Energy is capped between MIN/MAX.
15. `toggleStatus(uint256 tokenId)`: Flips the boolean `status` state of a token. Requires owner/approved. *Effect:* If entangled, partner's status is also toggled.
16. `performAction(uint256 tokenId)`: Represents a complex action using the token. Requires owner/approved, not on cooldown. *Effect:* If entangled, consumes from the shared pair's `chargeCycles`. If not entangled, might consume energy or have a different cost/effect (let's make it *only* possible if entangled for this concept). Consumes action cooldown.

**IV. Entanglement Management Functions:**
17. `requestEntanglement(uint256 requesterTokenId, uint256 requestedTokenId)`: Initiates an entanglement request from one token's owner to another. Requires sender owns/is approved for `requesterTokenId`. `requestedTokenId` must not be entangled or have pending requests.
18. `cancelEntanglementRequest(uint256 requesterTokenId)`: Cancels a previously sent entanglement request. Requires sender owns/is approved for `requesterTokenId`.
19. `confirmEntanglement(uint256 requestedTokenId, uint256 requesterTokenId)`: Confirms a pending entanglement request. Requires sender owns/is approved for `requestedTokenId`. Both tokens must not be entangled or have other pending requests. Establishes the entanglement link and initializes shared cycles.
20. `rejectEntanglement(uint256 requestedTokenId, uint256 requesterTokenId)`: Rejects a pending entanglement request. Requires sender owns/is approved for `requestedTokenId`.
21. `disentangleTokens(uint256 tokenId1, uint256 tokenId2)`: Breaks the entanglement between two tokens. Requires sender owns/is approved for *both* tokens, or contract owner override. Pair must be entangled and not on disentanglement cooldown. Clears entanglement state and shared cycles.

**V. Entanglement State & Interaction Functions:**
22. `isEntangled(uint256 tokenId)`: View function to check if a token is currently entangled.
23. `getEntangledPartner(uint256 tokenId)`: View function to get the ID of the entangled partner (0 if none).
24. `getPairChargeCycles(uint256 tokenId)`: View function to get the shared charge cycles for the pair the token belongs to.
25. `rechargePairCycles(uint256 tokenId)`: Adds charge cycles to an entangled pair. Requires sender owns/is approved for the token. Requires payment of `_rechargeFee`. Cycles are capped at `MAX_CHARGE_CYCLES`.
26. `amplifyEnergy(uint256 tokenId, uint256 amount)`: Increases energy for both tokens in an entangled pair by a specified amount. Requires sender owns/is approved for the token and it must be entangled.
27. `transferEnergyToPartner(uint256 tokenId, uint256 amount)`: Transfers energy from one token to its entangled partner. Requires sender owns/is approved for the token and it must be entangled. Checks source energy balance.

**VI. Admin & Utility Functions:**
28. `pause()`: Pauses transfer and state-changing functions. (Owner only).
29. `unpause()`: Unpauses the contract. (Owner only).
30. `setBaseURI(string memory baseURI)`: Sets the base URI for token metadata. (Owner only).
31. `withdrawFees(address payable recipient)`: Withdraws collected fees to a specified address. (Owner only).
32. `setFeeRecipient(address recipient)`: Sets the address for fee withdrawal. (Owner only).
33. `setRechargeFee(uint256 fee)`: Sets the fee required for recharging pair cycles. (Owner only).
34. `setEntanglementCooldown(uint256 cooldown)`: Sets the cooldown period after disentanglement. (Owner only).
35. `forceDisentangle(uint256 tokenId1, uint256 tokenId2)`: Owner override to disentangle tokens immediately, ignoring cooldowns/approvals. (Owner only).
36. `burn(uint256 tokenId)`: Destroys a token. Requires owner/approved. *Modified:* Will disentangle the token if entangled before burning.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Outline and Function Summary above the code.

contract QuantumEntangledNFTs is ERC721, Ownable, Pausable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---
    struct TokenState {
        uint256 energy;             // Dynamic energy level
        bool status;                // Binary status (e.g., Active/Inactive)
        uint256 lastActionTimestamp; // Timestamp of the last performAction call
    }

    // Mapping token ID to its state
    mapping(uint256 => TokenState) private _tokenStates;

    // Mapping token ID to its entangled partner (0 if not entangled)
    mapping(uint256 => uint256) private _entangledPartner;

    // Mapping minimum token ID of a pair to their shared charge cycles
    mapping(uint256 => uint256) private _pairChargeCycles;

    // Mapping requester token ID to the requested token ID for entanglement
    mapping(uint256 => uint256) private _pendingEntanglementRequest;

    // Entanglement cooldown period after disentanglement
    uint256 public entanglementCooldown;

    // Mapping minimum token ID of a pair to the timestamp of their last disentanglement
    mapping(uint256 => uint256) private _lastDisentangleTime;

    // Address to receive collected fees
    address payable public feeRecipient;

    // Fee required to recharge pair cycles
    uint256 public rechargeFee;

    // --- Constants ---
    uint256 public constant MAX_ENERGY = 1000;
    uint256 public constant MIN_ENERGY = 0;
    uint256 public constant MAX_CHARGE_CYCLES = 100;
    uint256 public constant ACTION_COOLDOWN = 1 hours; // Cooldown for performAction

    // --- Events ---
    event Minted(address indexed to, uint256 indexed tokenId);
    event BatchMinted(address indexed to, uint256 indexed fromTokenId, uint256 indexed toTokenId);
    event StateChanged(uint256 indexed tokenId, uint256 energy, bool status);
    event PairCyclesChanged(uint256 indexed pairMinTokenId, uint256 cycles);
    event EntanglementRequested(uint256 indexed requesterTokenId, uint256 indexed requestedTokenId);
    event EntanglementCancelled(uint256 indexed requesterTokenId, uint256 indexed requestedTokenId);
    event EntanglementConfirmed(uint256 indexed token1Id, uint256 indexed token2Id);
    event EntanglementRejected(uint256 indexed requestedTokenId, uint256 indexed requesterTokenId);
    event Disentangled(uint256 indexed token1Id, uint256 indexed token2Id);
    event ActionPerformed(uint256 indexed tokenId, uint256 cyclesConsumed);
    event EnergyAmplified(uint256 indexed token1Id, uint256 indexed token2Id, uint256 amount);
    event EnergyTransferred(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 amount);
    event FeeWithdrawn(address indexed recipient, uint256 amount);
    event BaseURISet(string baseURI);
    event FeeRecipientSet(address indexed recipient);
    event RechargeFeeSet(uint256 fee);
    event EntanglementCooldownSet(uint256 cooldown);

    // --- Modifiers ---
    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");
        _;
    }

    modifier onlyEntangled(uint256 tokenId) {
        require(_entangledPartner[tokenId] != 0, "Token is not entangled");
        _;
    }

    modifier notEntangled(uint256 tokenId) {
        require(_entangledPartner[tokenId] == 0, "Token is already entangled");
        _;
        require(_getPendingRequestTokenId(tokenId) == 0 && _getPendingConfirmationTokenId(tokenId) == 0, "Token has pending entanglement");
        _;
    }

    modifier pairNotOnCooldown(uint256 tokenId1, uint256 tokenId2) {
        uint256 minId = _minTokenId(tokenId1, tokenId2);
        require(block.timestamp >= _lastDisentangleTime[minId] + entanglementCooldown, "Pair on disentanglement cooldown");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address payable initialFeeRecipient, uint256 initialRechargeFee, uint256 initialEntanglementCooldown)
        ERC721(name, symbol)
        Ownable(_msgSender())
        Pausable()
    {
        feeRecipient = initialFeeRecipient;
        rechargeFee = initialRechargeFee;
        entanglementCooldown = initialEntanglementCooldown;
    }

    // --- Internal Helpers ---

    function _minTokenId(uint256 id1, uint256 id2) internal pure returns (uint256) {
        return id1 < id2 ? id1 : id2;
    }

    function _getPairMinId(uint256 tokenId) internal view returns (uint256) {
        uint256 partnerId = _entangledPartner[tokenId];
        require(partnerId != 0, "Token is not entangled");
        return _minTokenId(tokenId, partnerId);
    }

    function _getPendingRequestTokenId(uint256 tokenId) internal view returns (uint256) {
        for (uint256 reqId = 1; reqId < _tokenIdCounter.current() + 1; reqId++) {
            if (_pendingEntanglementRequest[reqId] == tokenId) {
                return reqId;
            }
        }
        return 0;
    }

     function _getPendingConfirmationTokenId(uint256 tokenId) internal view returns (uint256) {
        return _pendingEntanglementRequest[tokenId];
    }

    // Hook before transfers (standard ERC721 override)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the token is entangled and being transferred (not minting/burning)
        if (from != address(0) && to != address(0) && _entangledPartner[tokenId] != 0) {
            uint256 partnerId = _entangledPartner[tokenId];
            // Automatically disentangle the pair on transfer
            _disentanglePair(tokenId, partnerId);
            // Note: This disentanglement doesn't enforce cooldown as it's a forced break due to transfer.
            // We could optionally add a penalty or cooldown here if needed, but automatic break is simpler.
            delete _lastDisentangleTime[_minTokenId(tokenId, partnerId)]; // Clear cooldown for this pair
            emit Disentangled(tokenId, partnerId);
        }
    }

    // Hook before burning (ERC721Burnable override)
    function _beforeTokenBurn(uint256 tokenId) internal override {
        super._beforeTokenBurn(tokenId);
        // If the token is entangled
        if (_entangledPartner[tokenId] != 0) {
             uint256 partnerId = _entangledPartner[tokenId];
            // Automatically disentangle the pair before burning one member
            _disentanglePair(tokenId, partnerId);
             delete _lastDisentangleTime[_minTokenId(tokenId, partnerId)]; // Clear cooldown for this pair
            emit Disentangled(tokenId, partnerId);
        }
    }


    // Internal function to establish entanglement
    function _establishEntanglement(uint256 tokenId1, uint256 tokenId2) internal {
        require(tokenId1 != tokenId2, "Cannot entangle a token with itself");
        require(_exists(tokenId1), "Token 1 does not exist");
        require(_exists(tokenId2), "Token 2 does not exist");
        require(_entangledPartner[tokenId1] == 0, "Token 1 is already entangled");
        require(_entangledPartner[tokenId2] == 0, "Token 2 is already entangled");
        require(_getPendingRequestTokenId(tokenId1) == 0 && _getPendingConfirmationTokenId(tokenId1) == 0, "Token 1 has pending entanglement");
        require(_getPendingRequestTokenId(tokenId2) == 0 && _getPendingConfirmationTokenId(tokenId2) == 0, "Token 2 has pending entanglement");
        require(block.timestamp >= _lastDisentangleTime[_minTokenId(tokenId1, tokenId2)] + entanglementCooldown, "Pair on disentanglement cooldown");


        _entangledPartner[tokenId1] = tokenId2;
        _entangledPartner[tokenId2] = tokenId1;

        // Initialize shared charge cycles
        _pairChargeCycles[_minTokenId(tokenId1, tokenId2)] = MAX_CHARGE_CYCLES / 2; // Start with half capacity

        emit EntanglementConfirmed(tokenId1, tokenId2);
        emit PairCyclesChanged(_minTokenId(tokenId1, tokenId2), _pairChargeCycles[_minTokenId(tokenId1, tokenId2)]);
    }

    // Internal function to break entanglement
    function _disentanglePair(uint256 tokenId1, uint256 tokenId2) internal {
        require(_entangledPartner[tokenId1] == tokenId2 && _entangledPartner[tokenId2] == tokenId1, "Tokens are not entangled with each other");

        delete _entangledPartner[tokenId1];
        delete _entangledPartner[tokenId2];

        // Store disentangle time for cooldown
        _lastDisentangleTime[_minTokenId(tokenId1, tokenId2)] = block.timestamp;

        // Delete shared state
        delete _pairChargeCycles[_minTokenId(tokenId1, tokenId2)];

        // emit Disentangled(tokenId1, tokenId2); // Already emitted in _beforeTokenTransfer or burn hook
    }


    // --- ERC721 Overrides / Standard Functions ---

    // Functions 1-9 are standard ERC721 functions. The key overrides are `transferFrom`, `safeTransferFrom`
    // and `_beforeTokenTransfer` which includes the disentanglement logic.
    // `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll` are handled by the inherited ERC721.

    // 10. Get token URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return super.tokenURI(tokenId);
    }

    // --- Minting Functions ---

    // 11. Mint a single token
    function mint(address to) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);

        // Initialize token state
        _tokenStates[newTokenId] = TokenState({
            energy: MAX_ENERGY / 2, // Start with half energy
            status: false,          // Start inactive
            lastActionTimestamp: 0
        });

        emit Minted(to, newTokenId);
        emit StateChanged(newTokenId, _tokenStates[newTokenId].energy, _tokenStates[newTokenId].status);
        return newTokenId;
    }

    // 12. Batch mint tokens
    function batchMint(address to, uint256 count) public onlyOwner whenNotPaused {
        require(count > 0, "Count must be greater than 0");
        uint256 startingTokenId = _tokenIdCounter.current() + 1;
        for (uint256 i = 0; i < count; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _safeMint(to, newTokenId);

            // Initialize token state
             _tokenStates[newTokenId] = TokenState({
                energy: MAX_ENERGY / 2,
                status: false,
                lastActionTimestamp: 0
            });
             emit StateChanged(newTokenId, _tokenStates[newTokenId].energy, _tokenStates[newTokenId].status);
        }
        emit BatchMinted(to, startingTokenId, _tokenIdCounter.current());
    }

    // --- Dynamic State Management Functions ---

    // 13. Get token state
    function getTokenState(uint256 tokenId) public view returns (TokenState memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenStates[tokenId];
    }

    // 14. Modify energy
    function modifyEnergy(uint256 tokenId, int256 amount)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(tokenId)
        returns (uint256 newEnergy)
    {
        require(_exists(tokenId), "Token does not exist");
        TokenState storage state = _tokenStates[tokenId];

        // Apply energy change, respecting min/max bounds
        int256 currentEnergy = int256(state.energy);
        int256 nextEnergy = currentEnergy + amount;
        state.energy = uint256(Math.max(MIN_ENERGY, Math.min(MAX_ENERGY, nextEnergy)));

        newEnergy = state.energy;

        // Apply effect to entangled partner if exists
        uint256 partnerId = _entangledPartner[tokenId];
        if (partnerId != 0) {
             TokenState storage partnerState = _tokenStates[partnerId];
             int256 partnerCurrentEnergy = int256(partnerState.energy);
             // Inverse effect on partner
             int256 partnerNextEnergy = partnerCurrentEnergy - amount;
             partnerState.energy = uint256(Math.max(MIN_ENERGY, Math.min(MAX_ENERGY, partnerNextEnergy)));
             emit StateChanged(partnerId, partnerState.energy, partnerState.status);
        }

        emit StateChanged(tokenId, state.energy, state.status);
        return newEnergy;
    }

    // 15. Toggle status
    function toggleStatus(uint256 tokenId)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(tokenId)
    {
        require(_exists(tokenId), "Token does not exist");
        TokenState storage state = _tokenStates[tokenId];
        state.status = !state.status;

        // Apply effect to entangled partner if exists
        uint256 partnerId = _entangledPartner[tokenId];
        if (partnerId != 0) {
            TokenState storage partnerState = _tokenStates[partnerId];
            partnerState.status = !partnerState.status; // Toggle partner's status too
            emit StateChanged(partnerId, partnerState.energy, partnerState.status);
        }

        emit StateChanged(tokenId, state.energy, state.status);
    }

    // 16. Perform an action (primarily for entangled pairs)
    function performAction(uint256 tokenId)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(tokenId)
        onlyEntangled(tokenId) // This action *requires* entanglement
    {
        require(_exists(tokenId), "Token does not exist");
        TokenState storage state = _tokenStates[tokenId];

        // Check action cooldown
        require(block.timestamp >= state.lastActionTimestamp + ACTION_COOLDOWN, "Action is on cooldown");

        // Consume shared charge cycles for the pair
        uint256 pairMinId = _getPairMinId(tokenId);
        require(_pairChargeCycles[pairMinId] > 0, "Pair has no charge cycles");

        _pairChargeCycles[pairMinId]--; // Consume 1 cycle
        state.lastActionTimestamp = block.timestamp; // Update cooldown for *this* token

        emit ActionPerformed(tokenId, 1);
        emit PairCyclesChanged(pairMinId, _pairChargeCycles[pairMinId]);

        // Note: This action doesn't directly change partner state,
        // but it consumes a shared resource.
        // Other effects could be added here (e.g., small energy boost to both).
    }

    // --- Entanglement Management Functions ---

    // 17. Request entanglement
    function requestEntanglement(uint256 requesterTokenId, uint256 requestedTokenId)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(requesterTokenId)
        notEntangled(requesterTokenId) // Requester must not be entangled or pending
        notEntangled(requestedTokenId) // Requested must not be entangled or pending
    {
        require(_exists(requesterTokenId), "Requester token does not exist");
        require(_exists(requestedTokenId), "Requested token does not exist");
        require(requesterTokenId != requestedTokenId, "Cannot request entanglement with self");
        require(ownerOf(requesterTokenId) != ownerOf(requestedTokenId), "Cannot request entanglement with self (same owner)"); // Optional: Prevent self-entanglement even if different tokens

        // Ensure no pending request already exists for either token ID
         require(_getPendingRequestTokenId(requesterTokenId) == 0 && _getPendingConfirmationTokenId(requesterTokenId) == 0, "Requester token has pending request");
         require(_getPendingRequestTokenId(requestedTokenId) == 0 && _getPendingConfirmationTokenId(requestedTokenId) == 0, "Requested token has pending request");


        // Check disentanglement cooldown for this potential pair
        require(block.timestamp >= _lastDisentangleTime[_minTokenId(requesterTokenId, requestedTokenId)] + entanglementCooldown, "Pair on disentanglement cooldown");


        _pendingEntanglementRequest[requesterTokenId] = requestedTokenId;

        emit EntanglementRequested(requesterTokenId, requestedTokenId);
    }

    // 18. Cancel entanglement request
    function cancelEntanglementRequest(uint256 requesterTokenId)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(requesterTokenId)
    {
        uint256 requestedTokenId = _pendingEntanglementRequest[requesterTokenId];
        require(requestedTokenId != 0, "No pending entanglement request from this token");

        delete _pendingEntanglementRequest[requesterTokenId];

        emit EntanglementCancelled(requesterTokenId, requestedTokenId);
    }

    // 19. Confirm entanglement
    function confirmEntanglement(uint256 requestedTokenId, uint256 requesterTokenId)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(requestedTokenId)
    {
        require(_pendingEntanglementRequest[requesterTokenId] == requestedTokenId, "No pending request from requester token ID to requested token ID");

        // Check both tokens are still eligible for entanglement
        require(_exists(requesterTokenId), "Requester token does not exist");
        require(_exists(requestedTokenId), "Requested token does not exist");
        require(_entangledPartner[requesterTokenId] == 0, "Requester token already entangled");
        require(_entangledPartner[requestedTokenId] == 0, "Requested token already entangled");

         require(_getPendingRequestTokenId(requesterTokenId) == 0 && _getPendingConfirmationTokenId(requesterTokenId) == 0, "Requester token has other pending request");
         require(_getPendingRequestTokenId(requestedTokenId) == 0 && _getPendingConfirmationTokenId(requestedTokenId) == 0, "Requested token has other pending request");


         // Check disentanglement cooldown again before confirming
        require(block.timestamp >= _lastDisentangleTime[_minTokenId(requesterTokenId, requestedTokenId)] + entanglementCooldown, "Pair on disentanglement cooldown");


        // Remove the pending request
        delete _pendingEntanglementRequest[requesterTokenId];

        // Establish entanglement
        _establishEntanglement(requesterTokenId, requestedTokenId);

        // Emit event is handled inside _establishEntanglement
    }

     // 20. Reject entanglement request
    function rejectEntanglement(uint256 requestedTokenId, uint256 requesterTokenId)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(requestedTokenId)
    {
        require(_pendingEntanglementRequest[requesterTokenId] == requestedTokenId, "No pending request from requester token ID to requested token ID");

        delete _pendingEntanglementRequest[requesterTokenId];

        emit EntanglementRejected(requestedTokenId, requesterTokenId);
    }


    // 21. Disentangle tokens
    function disentangleTokens(uint256 tokenId1, uint256 tokenId2)
        public
        whenNotPaused
        pairNotOnCooldown(tokenId1, tokenId2)
    {
        require(_entangledPartner[tokenId1] == tokenId2 && _entangledPartner[tokenId2] == tokenId1, "Tokens are not entangled with each other");

        // Require approval from *both* owners or the contract owner
        bool callerIsOwner1OrApproved = _isApprovedOrOwner(_msgSender(), tokenId1);
        bool callerIsOwner2OrApproved = _isApprovedOrOwner(_msgSender(), tokenId2);

        require(callerIsOwner1OrApproved && callerIsOwner2OrApproved || owner() == _msgSender(), "Must own/be approved for both tokens or be contract owner");

        _disentanglePair(tokenId1, tokenId2);
        emit Disentangled(tokenId1, tokenId2);
    }

    // --- Entanglement State & Interaction Functions ---

    // 22. Check if entangled
    function isEntangled(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return _entangledPartner[tokenId] != 0;
    }

    // 23. Get entangled partner
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _entangledPartner[tokenId];
    }

    // 24. Get pair charge cycles
    function getPairChargeCycles(uint256 tokenId) public view onlyEntangled(tokenId) returns (uint256) {
        require(_exists(tokenId), "Token does not exist"); // Check exists first
        uint256 pairMinId = _getPairMinId(tokenId); // uses _entangledPartner implicitly
        return _pairChargeCycles[pairMinId];
    }

    // 25. Recharge pair cycles
    function rechargePairCycles(uint256 tokenId)
        public payable
        whenNotPaused
        onlyTokenOwnerOrApproved(tokenId)
        onlyEntangled(tokenId) // Can only recharge if entangled
    {
        require(msg.value >= rechargeFee, "Insufficient fee");
        require(_exists(tokenId), "Token does not exist"); // Check exists first

        uint256 pairMinId = _getPairMinId(tokenId); // uses _entangledPartner implicitly

        uint256 currentCycles = _pairChargeCycles[pairMinId];
        uint256 newCycles = Math.min(currentCycles + 10, MAX_CHARGE_CYCLES); // Add 10 cycles, capped at max

        _pairChargeCycles[pairMinId] = newCycles;

        // Excess fee is not refunded in this simple example. Could add refund logic.
        // If msg.value > rechargeFee, the excess stays in the contract until withdrawn by owner.

        emit PairCyclesChanged(pairMinId, newCycles);
    }

    // 26. Amplify energy (entangled pairs only)
    function amplifyEnergy(uint256 tokenId, uint256 amount)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(tokenId)
        onlyEntangled(tokenId)
    {
        require(_exists(tokenId), "Token does not exist"); // Check exists first
        require(amount > 0, "Amount must be positive");

        uint256 partnerId = _entangledPartner[tokenId];
        TokenState storage state = _tokenStates[tokenId];
        TokenState storage partnerState = _tokenStates[partnerId];

        // Increase energy for both, capped at MAX_ENERGY
        state.energy = Math.min(state.energy + amount, MAX_ENERGY);
        partnerState.energy = Math.min(partnerState.energy + amount, MAX_ENERGY);

        emit EnergyAmplified(tokenId, partnerId, amount);
        emit StateChanged(tokenId, state.energy, state.status);
        emit StateChanged(partnerId, partnerState.energy, partnerState.status);
    }

    // 27. Transfer energy to partner (entangled pairs only)
     function transferEnergyToPartner(uint256 fromTokenId, uint256 amount)
        public
        whenNotPaused
        onlyTokenOwnerOrApproved(fromTokenId)
        onlyEntangled(fromTokenId)
    {
        require(_exists(fromTokenId), "From token does not exist"); // Check exists first
        require(amount > 0, "Amount must be positive");

        TokenState storage fromState = _tokenStates[fromTokenId];
        uint256 toTokenId = _entangledPartner[fromTokenId];
        TokenState storage toState = _tokenStates[toTokenId];

        // Ensure enough energy to transfer
        require(fromState.energy >= amount, "Insufficient energy in source token");

        // Perform transfer
        fromState.energy -= amount;
        toState.energy = Math.min(toState.energy + amount, MAX_ENERGY); // Cap destination energy

        emit EnergyTransferred(fromTokenId, toTokenId, amount);
        emit StateChanged(fromTokenId, fromState.energy, fromState.status);
        emit StateChanged(toTokenId, toState.energy, toState.status);
    }

    // --- Admin & Utility Functions ---

    // 28. Pause contract
    function pause() public onlyOwner {
        _pause();
    }

    // 29. Unpause contract
    function unpause() public onlyOwner {
        _unpause();
    }

    // 30. Set base URI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
        emit BaseURISet(baseURI);
    }

    // 31. Withdraw fees
    function withdrawFees(address payable recipient) public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No fees to withdraw");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeeWithdrawn(recipient, amount);
    }

     // 32. Set fee recipient
    function setFeeRecipient(address payable recipient) public onlyOwner {
        feeRecipient = recipient;
        emit FeeRecipientSet(recipient);
    }

    // 33. Set recharge fee
    function setRechargeFee(uint256 fee) public onlyOwner {
        rechargeFee = fee;
        emit RechargeFeeSet(fee);
    }

    // 34. Set entanglement cooldown
    function setEntanglementCooldown(uint256 cooldown) public onlyOwner {
        entanglementCooldown = cooldown;
        emit EntanglementCooldownSet(cooldown);
    }

    // 35. Force disentangle (owner override)
    function forceDisentangle(uint256 tokenId1, uint256 tokenId2)
        public
        onlyOwner
    {
        // Ensure they are actually entangled with each other before forcing
        require(_entangledPartner[tokenId1] == tokenId2 && _entangledPartner[tokenId2] == tokenId1, "Tokens are not entangled with each other");

        _disentanglePair(tokenId1, tokenId2);
        // Owner force disentangle clears cooldown
        delete _lastDisentangleTime[_minTokenId(tokenId1, tokenId2)];
        emit Disentangled(tokenId1, tokenId2);
    }

    // 36. Burn a token
    // Uses ERC721Burnable's burn. _beforeTokenBurn hook handles disentanglement.
    function burn(uint256 tokenId) public override onlyTokenOwnerOrApproved(tokenId) {
        super.burn(tokenId);
        // _tokenStates data persists until overwritten, could explicitly delete if needed
        // delete _tokenStates[tokenId];
    }

    // --- ERC165 Support (Standard) ---
    // Override supportsInterface to declare support for ERC721, ERC721Enumerable (if added),
    // ERC721Metadata, Ownable (less common), Pausable (less common).
    // ERC721, ERC721Metadata are included by default by OpenZeppelin's ERC721.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Receive/Fallback ---
    // Required to receive Ether for rechargeFee
    receive() external payable {}
    fallback() external payable {}

    // Helper functions for pending requests (view only)
    function getPendingEntanglementRequest(uint256 requesterTokenId) public view returns (uint256 requestedTokenId) {
         return _pendingEntanglementRequest[requesterTokenId];
    }

    function getPendingRequestToToken(uint256 requestedTokenId) public view returns (uint256 requesterTokenId) {
         return _getPendingRequestTokenId(requestedTokenId);
    }

    // Added a couple more view functions for completeness to exceed 20 clearly.
    // 37. Get last disentanglement time for a pair
    function getLastDisentangleTime(uint256 tokenId1, uint256 tokenId2) public view returns (uint256) {
        return _lastDisentangleTime[_minTokenId(tokenId1, tokenId2)];
    }

    // 38. Get current max token ID
    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}

// Helper library for min/max
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```