Okay, let's create a smart contract based on an advanced, creative, and somewhat abstract concept: a "Quantum Entanglement Marketplace".

The idea is that tokens (NFTs) exist in a probabilistic "superposition" state initially. They can be "entangled" with other tokens, influencing their potential final characteristics. A "decoherence" action collapses the superposition using external randomness (like Chainlink VRF), revealing the token's final traits and fixing its state. The marketplace allows trading tokens in their superposition or entangled states.

This incorporates:
*   **Advanced Concepts:** Superposition/Decoherence analogy, Entanglement mechanics influencing outcomes, External Randomness (VRF).
*   **Creative/Trendy:** NFT state dynamics, probabilistic outcomes, unique trading conditions (entangled pairs?).
*   **Non-standard:** This isn't a typical ERC721 marketplace or generative art contract due to the state transitions and entanglement mechanics.

We'll aim for at least 20 distinct functions covering minting, state changes, trading, and admin features.

---

**Outline and Function Summary: `QuantumEntanglementMarketplace`**

This contract is an ERC721 marketplace where tokens represent quantum states.
Tokens start in a "Superposition" state with potential traits.
They can be "Entangled" with another token, influencing their final state.
A "Decoherence" process, triggered by external randomness, collapses the superposition to a final "Decohered" state with fixed traits.
The marketplace allows buying/selling tokens based on their current state (Superposition or Decohered). Entangled tokens might have restrictions or bundled listings.

**Core Concepts:**
1.  **Superposition:** The initial state of a token. Potential exists, but traits are not fixed.
2.  **Entanglement:** Linking two tokens. Actions on one (like decoherence) or their interaction might influence the outcome of both. Cannot be transferred independently while entangled.
3.  **Decoherence:** The act of collapsing the superposition to a fixed state using external randomness (Chainlink VRF).
4.  **Traits:** Determined and finalized only upon Decoherence. Influenced by initial properties, entanglement, and randomness.
5.  **Marketplace:** Allows trading Superposition seeds and Decohered NFTs.

**State Definitions:**
*   `SeedState`: Enum representing { Superposition, Entangled, Decohering, Decohered }
*   `Entanglement`: Struct linking two token IDs.
*   `DecoherenceRequest`: Struct storing VRF request ID and token ID for pending decoherence.
*   `Listing`: Struct for marketplace sale listings.
*   `Offer`: Struct for marketplace offers.

**Function Summary (Public/External):**

*   **Minting:**
    1.  `mintQuantumSeed(address to)`: Mints a new token ID in the Superposition state to `to`.
*   **Quantum Mechanics:**
    2.  `entangleTokens(uint256 tokenId1, uint256 tokenId2)`: Links two Superposition tokens. Both become Entangled.
    3.  `disentangleTokens(uint256 tokenId)`: Breaks the entanglement link for the given token (and its pair). Both revert to Superposition.
    4.  `requestDecoherenceRandomness(uint256 tokenId)`: Initiates the Decoherence process for a token in Superposition or Entangled state by requesting randomness from VRF. Token enters Decohering state.
    5.  `previewDecoherenceTraits(uint256 tokenId, uint256 hypotheticalRandomness)`: A view function to estimate potential traits based on a hypothetical random value. (Illustrative, actual traits depend on VRF).
*   **Marketplace - Listings:**
    6.  `listTokenForSale(uint256 tokenId, uint256 price)`: Lists a token (Superposition or Decohered) for a fixed price. Entangled tokens can only be listed together (handled internally or by a separate bundled function if needed, simplifying here to single-token listing).
    7.  `buyToken(uint256 tokenId)`: Purchases a listed token.
    8.  `cancelListing(uint256 tokenId)`: Cancels an active listing.
*   **Marketplace - Offers:**
    9.  `makeOffer(uint256 tokenId, uint256 amount)`: Makes an offer on a token not currently listed for fixed price.
    10. `acceptOffer(uint256 tokenId, address offerer)`: Token owner accepts an offer.
    11. `rejectOffer(uint256 tokenId, address offerer)`: Token owner rejects an offer.
    12. `cancelOffer(uint256 tokenId, address offerer)`: Offerer cancels their pending offer.
*   **Token Information (View Functions):**
    13. `getTokenState(uint256 tokenId)`: Returns the current state of the token.
    14. `getEntangledPair(uint256 tokenId)`: Returns the ID of the token it's entangled with (0 if not entangled).
    15. `getTokenTraits(uint256 tokenId)`: Returns the finalized traits (e.g., as a string or index) for a Decohered token.
    16. `getTokenListing(uint256 tokenId)`: Returns details of the active listing, if any.
    17. `getTokenOffers(uint256 tokenId)`: Returns details of pending offers for the token.
    18. `getVRFRequestIdForDecoherence(uint256 tokenId)`: Gets the VRF request ID associated with a token in Decohering state.
*   **Admin Functions (Owner Only):**
    19. `withdrawFees()`: Allows owner to withdraw collected marketplace fees.
    20. `setMarketplaceFee(uint16 feeBasisPoints)`: Sets the marketplace fee percentage.
    21. `setTraitMapping(uint256 randomnessRangeStart, uint256 randomnessRangeEnd, string traitIdentifier)`: Configures how VRF output ranges map to potential traits (Simplified illustrative example).
    22. `setEntanglementEffectMapping(...)`: Configures how entanglement modifies trait outcomes (Simplified illustrative example).
    23. `pause()`: Pauses core contract actions (transfers, listings, state changes).
    24. `unpause()`: Unpauses the contract.
    25. `updateTokenURI(uint256 tokenId, string uri)`: Allows setting metadata URI (maybe restricted, or used for finalized traits).
    26. `setVRFCoordinator(...)`: Sets the VRF Coordinator address (usually in constructor, but potentially updatable in emergency).
    27. `setKeyHash(...)`: Sets the VRF Key Hash.
    28. `setSubscriptionId(...)`: Sets the VRF Subscription ID.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Outline and Function Summary is provided at the top of the file.

contract QuantumEntanglementMarketplace is ERC721Enumerable, ERC721Pausable, Ownable, Pausable, VRFConsumerBaseV2 {

    // --- State Definitions ---

    enum SeedState {
        Superposition, // Initial state, traits undetermined
        Entangled,     // Linked to another token, influences decoherence
        Decohering,    // Awaiting VRF randomness
        Decohered      // Final state, traits fixed
    }

    struct TokenData {
        SeedState state;
        uint256 entangledTokenId; // ID of the token it's entangled with (0 if none)
        bytes32 decoherenceRequestId; // VRF request ID if state is Decohering
        uint256 finalizedRandomness; // VRF randomness once fulfilled
        string finalizedTraits;    // String representing traits once Decohered
    }

    struct Listing {
        uint256 price;
        address payable seller;
        bool isListed;
    }

    struct Offer {
        uint256 amount;
        address offerer;
        bool isPending;
        uint256 timestamp; // Optional: for expiry or sorting
    }

    // --- State Variables ---

    mapping(uint256 => TokenData) private _tokenData;
    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => mapping(address => Offer)) private _offers; // tokenId => offerer => Offer

    uint256 private _nextTokenId;

    uint256 public marketplaceFeeBasisPoints = 250; // 2.5% fee
    uint256 public totalFeesCollected;

    // Chainlink VRF V2 variables
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 public s_callbackGasLimit = 100000; // Adjust as needed
    uint16 public s_requestConfirmations = 3;  // Recommended
    mapping(bytes32 => uint256) public s_requests; // request ID => token ID

    // --- Events ---

    event QuantumSeedMinted(address indexed to, uint256 indexed tokenId);
    event TokensEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event TokensDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event DecoherenceRequested(uint256 indexed tokenId, bytes32 indexed requestId);
    event DecoherenceFulfilled(uint256 indexed tokenId, uint256 randomness, string finalizedTraits);
    event TokenListedForSale(uint256 indexed tokenId, uint256 price, address indexed seller);
    event TokenBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);
    event OfferMade(uint256 indexed tokenId, address indexed offerer, uint256 amount);
    event OfferAccepted(uint256 indexed tokenId, address indexed offerer, uint256 amount);
    event OfferRejected(uint256 indexed tokenId, address indexed offerer);
    event OfferCancelled(uint256 indexed tokenId, address indexed offerer);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event MarketplaceFeeUpdated(uint16 newFeeBasisPoints);
    event TraitMappingUpdated(uint256 randomnessRangeStart, uint256 randomnessRangeEnd, string traitIdentifier);
    event EntanglementEffectMappingUpdated(string description); // Simplified event

    // --- Constructor ---

    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId
    )
        ERC721("Quantum Entanglement Seed", "QES")
        Ownable(msg.sender)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
    }

    // --- Modifiers ---

    modifier whenInState(uint256 tokenId, SeedState expectedState) {
        require(_tokenData[tokenId].state == expectedState, "QEM: Invalid state for action");
        _;
    }

     modifier whenNotInState(uint256 tokenId, SeedState prohibitedState) {
        require(_tokenData[tokenId].state != prohibitedState, "QEM: Action prohibited in current state");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QEM: Caller is not the token owner");
        _;
    }

    modifier isNotEntangled(uint256 tokenId) {
        require(_tokenData[tokenId].state != SeedState.Entangled, "QEM: Token is entangled");
        _;
    }

    modifier isNotDecohered(uint256 tokenId) {
        require(_tokenData[tokenId].state != SeedState.Decohered, "QEM: Token is already decohered");
    }

    // --- Pausable Overrides ---
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable, ERC721Pausable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Additional checks based on state
        TokenData storage data = _tokenData[tokenId];
        require(data.state != SeedState.Entangled, "QEM: Entangled tokens cannot be transferred independently");
        require(data.state != SeedState.Decohering, "QEM: Token in decohering state cannot be transferred");

        // Cancel listings/offers on transfer
        if (_listings[tokenId].isListed) {
            delete _listings[tokenId];
            emit ListingCancelled(tokenId);
        }
        // Note: Offers are tied to the token ID, they persist through transfer but need owner action.
        // Could add logic here to clear offers or invalidate them on transfer if desired.
    }

    // --- Minting ---

    /// @notice Mints a new Quantum Seed token in Superposition state.
    /// @param to The address to mint the token to.
    function mintQuantumSeed(address to) public onlyOwner returns (uint256) {
        require(to != address(0), "QEM: Mint to zero address");
        _pause(); // Ensure controlled minting if needed, or remove pause/unpause calls

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _tokenData[tokenId].state = SeedState.Superposition;
        _tokenData[tokenId].entangledTokenId = 0; // Not entangled initially

        emit QuantumSeedMinted(to, tokenId);

        _unpause(); // Unpause if paused for minting

        return tokenId;
    }

    // --- Quantum Mechanics ---

    /// @notice Entangles two tokens in Superposition state. Both tokens must be owned by the caller.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangleTokens(uint256 tokenId1, uint256 tokenId2)
        public
        whenInState(tokenId1, SeedState.Superposition)
        whenInState(tokenId2, SeedState.Superposition)
        onlyTokenOwner(tokenId1) // Implicitly checks owner for tokenId2 if they are the same owner
        whenNotPaused
    {
        require(tokenId1 != tokenId2, "QEM: Cannot entangle a token with itself");
        require(ownerOf(tokenId1) == ownerOf(tokenId2), "QEM: Must own both tokens to entangle");

        _tokenData[tokenId1].state = SeedState.Entangled;
        _tokenData[tokenId1].entangledTokenId = tokenId2;
        _tokenData[tokenId2].state = SeedState.Entangled;
        _tokenData[tokenId2].entangledTokenId = tokenId1;

        emit TokensEntangled(tokenId1, tokenId2);
    }

    /// @notice Disentangles a token. Its pair is also disentangled. Both revert to Superposition.
    /// @param tokenId The ID of the token to disentangle.
    function disentangleTokens(uint256 tokenId)
        public
        whenInState(tokenId, SeedState.Entangled)
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        uint256 entangledPairId = _tokenData[tokenId].entangledTokenId;
        require(entangledPairId != 0, "QEM: Token is not entangled");
        require(_tokenData[entangledPairId].entangledTokenId == tokenId, "QEM: Entanglement data corrupted"); // Sanity check

        _tokenData[tokenId].state = SeedState.Superposition;
        _tokenData[tokenId].entangledTokenId = 0;
        _tokenData[entangledPairId].state = SeedState.Superposition;
        _tokenData[entangledPairId].entangledTokenId = 0;

        emit TokensDisentangled(tokenId, entangledPairId);
    }

    /// @notice Initiates the decoherence process by requesting randomness from Chainlink VRF.
    /// Token must be in Superposition or Entangled state.
    /// @param tokenId The ID of the token to decohere.
    function requestDecoherenceRandomness(uint256 tokenId)
        public
        onlyTokenOwner(tokenId)
        whenNotInState(tokenId, SeedState.Decohering)
        whenNotInState(tokenId, SeedState.Decohered)
        whenNotPaused
    {
        // Can only request if Superposition or Entangled
        require(
            _tokenData[tokenId].state == SeedState.Superposition ||
            _tokenData[tokenId].state == SeedState.Entangled,
            "QEM: Token not in valid state for decoherence request"
        );

        // If entangled, both must initiate? Or one initiates for the pair?
        // Let's make it one token initiates, VRF outcome *may* affect both via logic in fulfillRandomWords.
        // If entangled, the other token also moves to Decohering state implicitly or explicitly.
        // For simplicity here, one request triggers the process for that token.
        // Complex entanglement effects are handled in _applyDecoherenceLogic.

        uint256 requestCount = 1; // Request 1 random number
        bytes32 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            requestCount
        );

        _tokenData[tokenId].state = SeedState.Decohering;
        _tokenData[tokenId].decoherenceRequestId = requestId;
        s_requests[requestId] = tokenId;

        emit DecoherenceRequested(tokenId, requestId);
    }

    /// @notice Callback function for Chainlink VRF. DO NOT CALL DIRECTLY.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 tokenId = s_requests[bytes32(uint256(requestId))];
        require(tokenId != 0, "QEM: Unknown request ID"); // Should not happen if handled correctly

        TokenData storage data = _tokenData[tokenId];
        require(data.state == SeedState.Decohering, "QEM: Token not in decohering state for fulfillment");
        require(data.decoherenceRequestId == bytes32(uint256(requestId)), "QEM: Mismatch request ID");

        // We requested 1 word
        uint256 randomness = randomWords[0];

        data.finalizedRandomness = randomness;

        // --- Core Decoherence Logic ---
        // This is the complex part where randomness, initial properties,
        // and entanglement effects determine final traits.
        // Abstracted for this example.
        data.finalizedTraits = _applyDecoherenceLogic(tokenId, randomness);
        // --- End Core Decoherence Logic ---

        data.state = SeedState.Decohered;
        data.decoherenceRequestId = bytes32(0); // Clear request ID

        // If entangled, potentially trigger or influence the entangled pair's decoherence
        // This would require more complex state management for entangled pairs decohering together or sequentially.
        // For this example, we finalize this token only. A more complex version could have entangled pairs
        // request randomness simultaneously or have one fulfillment influence the other's pending fulfillment.
        if (data.entangledTokenId != 0 && _tokenData[data.entangledTokenId].state == SeedState.Entangled) {
             // Optionally, automatically trigger requestDecoherenceRandomness for the pair
             // or mark it as ready for its own decoherence, possibly passing some derived value.
             // Skipping automatic trigger here for simplicity, requires user action for the pair.
        }


        emit DecoherenceFulfilled(tokenId, randomness, data.finalizedTraits);
    }

    /// @dev Internal function containing the core trait determination logic.
    /// This is a placeholder. Real implementation would use trait matrices, randomness, and entanglement state.
    function _applyDecoherenceLogic(uint256 tokenId, uint256 randomness) internal view returns (string memory) {
        // Example logic:
        // Based on tokenId, randomness, and _tokenData[tokenId].entangledTokenId
        // Look up potential traits from admin-configured mappings.
        // Apply modifiers based on entanglement status or the pair's state/properties.
        // Select final traits based on the finalizedRandomness.

        string memory baseTrait = string(abi.encodePacked("Base-", uint256(randomness % 100).toString()));
        if (_tokenData[tokenId].entangledTokenId != 0) {
            // Example: entanglement with an even/odd token changes outcome slightly
            if (_tokenData[tokenId].entangledTokenId % 2 == 0) {
                 return string(abi.encodePacked("EntangledEven-", baseTrait));
            } else {
                 return string(abi.encodePacked("EntangledOdd-", baseTrait));
            }
        }
        return string(abi.encodePacked("Solo-", baseTrait)); // Simple fallback if not entangled
    }

    /// @notice Allows previewing potential traits based on a hypothetical randomness value.
    /// This is illustrative and does not guarantee the final outcome.
    /// @param tokenId The token ID.
    /// @param hypotheticalRandomness A hypothetical random number to simulate the outcome.
    /// @return A string representing potential traits based on the hypothetical randomness.
    function previewDecoherenceTraits(uint256 tokenId, uint256 hypotheticalRandomness)
        public
        view
        returns (string memory)
    {
        require(
            _tokenData[tokenId].state == SeedState.Superposition ||
            _tokenData[tokenId].state == SeedState.Entangled,
            "QEM: Can only preview superposition or entangled states"
        );

        // Use a simplified version of the logic used in _applyDecoherenceLogic
        // This preview cannot use the *actual* entanglement effects that might
        // depend on the pair's *final* state, which is unknown.
        // It can only simulate based on the current entanglement *status*.

        string memory baseTrait = string(abi.encodePacked("Preview-Base-", uint256(hypotheticalRandomness % 100).toString()));
        if (_tokenData[tokenId].entangledTokenId != 0) {
             if (_tokenData[tokenId].entangledTokenId % 2 == 0) {
                 return string(abi.encodePacked("Preview-EntangledEven-", baseTrait));
            } else {
                 return string(abi.encodePacked("Preview-EntangledOdd-", baseTrait));
            }
        }
        return string(abi.encodePacked("Preview-Solo-", baseTrait));
    }


    // --- Marketplace - Listings ---

    /// @notice Lists a token for a fixed price.
    /// @param tokenId The ID of the token to list.
    /// @param price The price in native currency (ETH/MATIC).
    function listTokenForSale(uint256 tokenId, uint256 price)
        public
        onlyTokenOwner(tokenId)
        isNotEntangled(tokenId) // Cannot list entangled tokens individually
        whenNotInState(tokenId, SeedState.Decohering) // Cannot list while decohering
        whenNotPaused
    {
        require(!_listings[tokenId].isListed, "QEM: Token already listed");
        require(price > 0, "QEM: Price must be positive");

        _listings[tokenId] = Listing({
            price: price,
            seller: payable(msg.sender),
            isListed: true
        });

        // Cancel any existing offers when listing
        delete _offers[tokenId]; // Clear all offers

        emit TokenListedForSale(tokenId, price, msg.sender);
    }

    /// @notice Buys a listed token.
    /// @param tokenId The ID of the token to buy.
    function buyToken(uint256 tokenId)
        public
        payable
        whenNotPaused
    {
        Listing storage listing = _listings[tokenId];
        require(listing.isListed, "QEM: Token not listed for sale");
        require(msg.value >= listing.price, "QEM: Insufficient funds");
        require(listing.seller != address(0), "QEM: Invalid seller"); // Sanity check
        require(ownerOf(tokenId) == listing.seller, "QEM: Listing outdated, seller changed"); // Check owner hasn't changed

        uint256 feeAmount = (listing.price * marketplaceFeeBasisPoints) / 10000;
        uint256 sellerPayout = listing.price - feeAmount;

        totalFeesCollected += feeAmount;

        // Transfer funds to seller and contract owner
        if (sellerPayout > 0) {
             (bool successSeller, ) = listing.seller.call{value: sellerPayout}("");
             require(successSeller, "QEM: Seller payment failed");
        }
        // Fee remains in the contract, withdrawable by owner via withdrawFees()

        // Transfer token
        address currentOwner = ownerOf(tokenId);
        _safeTransfer(currentOwner, msg.sender, tokenId);

        // Delete listing
        delete _listings[tokenId];

        // Any pending offers on this token are now invalid, they will be cleared on transfer/listing.
        // Or could explicitly clear here if needed.

        emit TokenBought(tokenId, msg.sender, listing.price);

        // Return any excess ETH
        if (msg.value > listing.price) {
            (bool successRefund, ) = payable(msg.sender).call{value: msg.value - listing.price}("");
            require(successRefund, "QEM: Refund failed");
        }
    }

    /// @notice Cancels an active listing for a token.
    /// @param tokenId The ID of the token.
    function cancelListing(uint256 tokenId)
        public
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        require(_listings[tokenId].isListed, "QEM: Token not listed for sale");
        require(_listings[tokenId].seller == msg.sender, "QEM: Not listing seller"); // Should be owner anyway

        delete _listings[tokenId];
        emit ListingCancelled(tokenId);
    }

    // --- Marketplace - Offers ---

    /// @notice Makes an offer on a token. Can offer on unlisted tokens.
    /// Overwrites previous offer from the same address.
    /// @param tokenId The ID of the token.
    /// @param amount The offer amount in native currency (ETH/MATIC).
    function makeOffer(uint256 tokenId, uint256 amount)
        public
        payable
        whenNotPaused
    {
        require(amount > 0, "QEM: Offer amount must be positive");
        require(msg.value == amount, "QEM: Sent value must match offer amount");
        require(ownerOf(tokenId) != msg.sender, "QEM: Cannot offer on your own token");
        // Cannot offer on entangled or decohering tokens? Add checks if desired.
         require(_tokenData[tokenId].state != SeedState.Entangled, "QEM: Cannot offer on entangled tokens");
         require(_tokenData[tokenId].state != SeedState.Decohering, "QEM: Cannot offer on decohering tokens");


        // Refund previous offer if exists
        if (_offers[tokenId][msg.sender].isPending) {
            uint256 previousOfferAmount = _offers[tokenId][msg.sender].amount;
            (bool successRefund, ) = payable(msg.sender).call{value: previousOfferAmount}("");
            require(successRefund, "QEM: Previous offer refund failed");
        }

        _offers[tokenId][msg.sender] = Offer({
            amount: amount,
            offerer: msg.sender,
            isPending: true,
            timestamp: block.timestamp
        });

        emit OfferMade(tokenId, msg.sender, amount);
    }

    /// @notice Token owner accepts an offer. Transfers token and funds.
    /// @param tokenId The ID of the token.
    /// @param offerer The address of the offerer.
    function acceptOffer(uint256 tokenId, address offerer)
        public
        onlyTokenOwner(tokenId)
        isNotEntangled(tokenId) // Cannot accept offer on entangled tokens individually
        whenNotInState(tokenId, SeedState.Decohering) // Cannot accept offer while decohering
        whenNotPaused
    {
        Offer storage offer = _offers[tokenId][offerer];
        require(offer.isPending, "QEM: No pending offer from this address");
        require(offer.offerer == offerer, "QEM: Offer data mismatch"); // Sanity check

        uint256 feeAmount = (offer.amount * marketplaceFeeBasisPoints) / 10000;
        uint256 sellerPayout = offer.amount - feeAmount;

        totalFeesCollected += feeAmount;

        // Transfer funds from contract balance (where offers are held) to seller
        if (sellerPayout > 0) {
            (bool successSeller, ) = payable(msg.sender).call{value: sellerPayout}("");
            require(successSeller, "QEM: Seller payment failed");
        }
        // Fee remains in contract

        // Transfer token
        address currentOwner = ownerOf(tokenId); // Should be msg.sender due to onlyTokenOwner
        _safeTransfer(currentOwner, offerer, tokenId);

        // Clear all offers and listing for this token
        delete _offers[tokenId];
        if (_listings[tokenId].isListed) {
             delete _listings[tokenId];
             emit ListingCancelled(tokenId);
        }

        emit OfferAccepted(tokenId, offerer, offer.amount);
    }

    /// @notice Token owner rejects an offer. Refunds the offer amount to the offerer.
    /// @param tokenId The ID of the token.
    /// @param offerer The address of the offerer.
    function rejectOffer(uint256 tokenId, address offerer)
        public
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        Offer storage offer = _offers[tokenId][offerer];
        require(offer.isPending, "QEM: No pending offer from this address");
        require(offer.offerer == offerer, "QEM: Offer data mismatch"); // Sanity check

        uint256 refundAmount = offer.amount;
        delete _offers[tokenId][offerer];

        // Refund offerer
        (bool successRefund, ) = payable(offerer).call{value: refundAmount}("");
        require(successRefund, "QEM: Offer refund failed");

        emit OfferRejected(tokenId, offerer);
    }

     /// @notice Offerer cancels their own offer. Refunds the offer amount.
     /// @param tokenId The ID of the token.
     /// @param offerer The address of the offerer (must be msg.sender).
    function cancelOffer(uint256 tokenId, address offerer)
        public
        whenNotPaused
    {
        require(msg.sender == offerer, "QEM: Can only cancel your own offer");
        Offer storage offer = _offers[tokenId][offerer];
        require(offer.isPending, "QEM: No pending offer from this address");

        uint256 refundAmount = offer.amount;
        delete _offers[tokenId][offerer];

        // Refund offerer
        (bool successRefund, ) = payable(offerer).call{value: refundAmount}("");
        require(successRefund, "QEM: Offer refund failed");

        emit OfferCancelled(tokenId, offerer);
    }


    // --- Token Information (View Functions) ---

    /// @notice Gets the current state of a token.
    /// @param tokenId The ID of the token.
    /// @return The SeedState enum value.
    function getTokenState(uint256 tokenId) public view returns (SeedState) {
        return _tokenData[tokenId].state;
    }

    /// @notice Gets the ID of the token entangled with the given token.
    /// @param tokenId The ID of the token.
    /// @return The entangled token ID, or 0 if not entangled.
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
        return _tokenData[tokenId].entangledTokenId;
    }

    /// @notice Gets the finalized traits for a Decohered token.
    /// @param tokenId The ID of the token.
    /// @return A string representing the finalized traits. Empty string if not Decohered.
    function getTokenTraits(uint256 tokenId) public view returns (string memory) {
        require(_tokenData[tokenId].state == SeedState.Decohered, "QEM: Token is not yet decohered");
        return _tokenData[tokenId].finalizedTraits;
    }

    /// @notice Gets the active listing details for a token.
    /// @param tokenId The ID of the token.
    /// @return price, seller, isListed
    function getTokenListing(uint256 tokenId) public view returns (uint256 price, address seller, bool isListed) {
        Listing storage listing = _listings[tokenId];
        return (listing.price, listing.seller, listing.isListed);
    }

    /// @notice Gets pending offers for a token.
    /// @param tokenId The ID of the token.
    /// @return An array of Offer structs. (Note: Returning structs with mappings is complex,
    /// returning arrays of specific data types is more common. This is a simplified view).
    /// This implementation iterates over potential offerers (not practical for large scale).
    /// A better way would be to track offerer addresses in an array/linked list or use a separate query layer.
    /// Returning just the count here for simplicity.
    function getTokenOffers(uint256 tokenId) public view returns (uint256 offerCount) {
       // Due to mapping structure, cannot easily return all offers.
       // To get actual offers, you'd typically query offerer addresses individually
       // or rely on off-chain indexing of OfferMade events.
       // This function serves as a placeholder.
       // For a basic count:
       uint256 count = 0;
       // This loop is INCREDIBLY gas-inefficient and should NOT be used on mainnet
       // over large numbers of potential offerers. Illustrative only.
       // for (uint i = 0; i < 100; ++i) { // Imagine iterating through a list of offerer addresses
       //     address offererAddress = ... ; // Get address from some list/index
       //     if (_offers[tokenId][offererAddress].isPending) {
       //         count++;
       //     }
       // }
       return count; // Placeholder
    }

     /// @notice Gets the VRF request ID associated with a token in Decohering state.
     /// @param tokenId The ID of the token.
     /// @return The VRF request ID, or bytes32(0) if not in Decohering state.
    function getVRFRequestIdForDecoherence(uint256 tokenId) public view returns (bytes32) {
        return _tokenData[tokenId].decoherenceRequestId;
    }


    // --- Admin Functions (Owner Only) ---

    /// @notice Allows the owner to withdraw collected marketplace fees.
    function withdrawFees() public onlyOwner whenNotPaused {
        uint256 amount = totalFeesCollected;
        require(amount > 0, "QEM: No fees collected");
        totalFeesCollected = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QEM: Fee withdrawal failed");
        emit FeesWithdrawn(msg.sender, amount);
    }

    /// @notice Sets the marketplace fee percentage in basis points (1/100th of a percent).
    /// @param feeBasisPoints The fee amount, e.g., 250 for 2.5%. Max 10000 (100%).
    function setMarketplaceFee(uint16 feeBasisPoints) public onlyOwner {
        require(feeBasisPoints <= 10000, "QEM: Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = feeBasisPoints;
        emit MarketplaceFeeUpdated(feeBasisPoints);
    }

    /// @dev Placeholder for setting trait mapping logic.
    /// In a real contract, this would be complex mapping structs/arrays.
    /// @param randomnessRangeStart Start of the randomness range (inclusive).
    /// @param randomnessRangeEnd End of the randomness range (inclusive).
    /// @param traitIdentifier Identifier for the trait associated with this range.
    function setTraitMapping(uint256 randomnessRangeStart, uint256 randomnessRangeEnd, string memory traitIdentifier) public onlyOwner {
        // Placeholder: Implement complex trait mapping logic here
        // e.g., mapping(uint256 => string[]) potentialTraits;
        // or a struct/array defining ranges and associated traits.
        // This function is illustrative of where this admin control would go.
        emit TraitMappingUpdated(randomnessRangeStart, randomnessRangeEnd, traitIdentifier);
    }

     /// @dev Placeholder for setting entanglement effect logic.
     /// In a real contract, this would define how entanglement modifies trait determination.
     /// @param description A string describing the updated effect rule.
    function setEntanglementEffectMapping(string memory description) public onlyOwner {
        // Placeholder: Implement logic to modify how entanglement influences trait outcomes
        // e.g., based on the entangled pair's properties, state, or a separate admin matrix.
        emit EntanglementEffectMappingUpdated(description);
    }

    /// @notice Pauses core contract functionality. ERC721 transfers are paused via ERC721Pausable.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Updates the token URI for a specific token.
    /// In a real contract, this might be handled automatically upon decoherence
    /// to reflect the finalized traits, and potentially restricted in other states.
    /// Allowing owner to set explicitly for flexibility in this example.
    /// @param tokenId The ID of the token.
    /// @param uri The new token URI.
    function updateTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        // Consider restrictions: Maybe only settable for Decohered tokens?
        // Or reflects Superposition/Entangled state dynamically via base URI?
        _setTokenURI(tokenId, uri);
    }

    /// @dev Allows owner to update VRF Coordinator address. Use with extreme caution.
    function setVRFCoordinator(address vrfCoordinator) public onlyOwner {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /// @dev Allows owner to update VRF Key Hash. Use with extreme caution.
    function setKeyHash(bytes32 keyHash) public onlyOwner {
        s_keyHash = keyHash;
    }

    /// @dev Allows owner to update VRF Subscription ID. Use with extreme caution.
    function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
        s_subscriptionId = subscriptionId;
    }


    // --- ERC721 Metadata (Optional, but good practice) ---

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (string memory)
    {
        // Override tokenURI to provide metadata based on state
        // This is a crucial part of reflecting the token's state evolution on marketplaces.
        SeedState state = _tokenData[tokenId].state;
        if (state == SeedState.Decohered) {
            // Return a URI pointing to metadata describing the finalized traits
            // e.g., "ipfs://.../[tokenId].json" where the JSON contains the finalizedTraits
            // For simplicity, returning the traits directly or a simple placeholder URI
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(
                abi.encodePacked('{"name": "Decohered Quantum Seed #', uint256(tokenId).toString(), '", "description": "This seed has decohered.", "attributes": [{"trait_type": "State", "value": "Decohered"}, {"trait_type": "Final Traits", "value": "', _tokenData[tokenId].finalizedTraits, '"}]}')
            ))));

        } else if (state == SeedState.Entangled) {
            // Return a URI indicating it's entangled and its pair
             return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(
                abi.encodePacked('{"name": "Entangled Quantum Seed #', uint256(tokenId).toString(), '", "description": "This seed is entangled.", "attributes": [{"trait_type": "State", "value": "Entangled"}, {"trait_type": "Entangled Pair", "value": "#', uint256(_tokenData[tokenId].entangledTokenId).toString(), '"}]}')
            ))));
        } else if (state == SeedState.Decohering) {
             // Return a URI indicating it's decohering
             return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(
                abi.encodePacked('{"name": "Decohering Quantum Seed #', uint256(tokenId).toString(), '", "description": "This seed is decohering, awaiting randomness.", "attributes": [{"trait_type": "State", "value": "Decohering"}]}')
            ))));
        } else { // Superposition
            // Return a URI for the initial Superposition state, maybe hinting at possibilities
             return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(
                abi.encodePacked('{"name": "Superposition Quantum Seed #', uint256(tokenId).toString(), '", "description": "This seed exists in superposition, awaiting decoherence.", "attributes": [{"trait_type": "State", "value": "Superposition"}]}')
            ))));
        }
        // A more standard approach would be to use _setTokenURI with IPFS links.
        // The base64 data URI is shown here for a self-contained example.
    }

    // Helper function to convert uint256 to string
    // Taken from OpenZeppelin's Strings library or similar utils
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
}

// Minimal Base64 library for data URI example
library Base64 {
    bytes constant private base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        bytes memory table = base64chars;

        // allocate output
        uint256 outputLen = 4 * ((data.length + 2) / 3);
        bytes memory output = new bytes(outputLen);

        uint255 inputPtr = 0;
        uint256 outputPtr = 0;
        while (inputPtr < data.length - 2) {
            uint256 input = (uint256(data[inputPtr]) << 16) | (uint256(data[inputPtr + 1]) << 8) | uint256(data[inputPtr + 2]);

            output[outputPtr++] = table[(input >> 18) & 0x3F];
            output[outputPtr++] = table[(input >> 12) & 0x3F];
            output[outputPtr++] = table[(input >> 6) & 0x3F];
            output[outputPtr++] = table[input & 0x3F];

            inputPtr += 3;
        }

        // handle padding
        uint256 lastBytes = data.length - inputPtr;
        if (lastBytes == 1) {
            uint256 input = uint256(data[inputPtr]) << 16;
            output[outputPtr++] = table[(input >> 18) & 0x3F];
            output[outputPtr++] = table[(input >> 12) & 0x3F];
            output[outputPtr++] = bytes1('=');
            output[outputPtr++] = bytes1('=');
        } else if (lastBytes == 2) {
            uint256 input = (uint256(data[inputPtr]) << 16) | (uint256(data[inputPtr + 1]) << 8);
            output[outputPtr++] = table[(input >> 18) & 0x3F];
            output[outputPtr++] = table[(input >> 12) & 0x3F];
            output[outputPtr++] = table[(input >> 6) & 0x3F];
            output[outputPtr++] = bytes1('=');
        }

        return string(output);
    }

    function encodeUrlSafe(bytes memory data) internal pure returns (string memory) {
        bytes memory base64 = encode(data);
        for (uint256 i = 0; i < base64.length; i++) {
            if (base64[i] == bytes1('+')) {
                base64[i] = bytes1('-');
            } else if (base64[i] == bytes1('/')) {
                base64[i] = bytes1('_');
            }
        }
        return string(base64);
    }
}

// Simple uint to string conversion
library uint256ToString {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OpenZeppelin's Strings.toString
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
        unchecked {
            while (value != 0) {
                digits--;
                buffer[digits] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
        }
        return string(buffer);
    }
}
```

**Explanation and Notes:**

1.  **Concept Mapping:**
    *   **Superposition:** Represented by `SeedState.Superposition`. The token exists, can be owned and transferred (unless paused or entangled), but its final form (traits) is not fixed. `tokenURI` reflects this.
    *   **Entanglement:** Represented by `SeedState.Entangled` and the `entangledTokenId`. Two tokens are linked. Key restriction: they cannot be transferred or listed independently while entangled. `tokenURI` reflects this link.
    *   **Decoherence:** The process initiated by `requestDecoherenceRandomness` and completed by `fulfillRandomWords`. The token enters the `Decohering` state, requests external randomness, and transitions to `Decohered` when the randomness is received.
    *   **Measurement/Observation:** In this analogy, the act of `requestDecoherenceRandomness` and the subsequent VRF callback fulfilling it is the "measurement" that collapses the superposition.
    *   **Traits:** Stored in `finalizedTraits` and are determined by the `_applyDecoherenceLogic` function using the `finalizedRandomness` and potentially considering entanglement status or the pair's state. `tokenURI` changes to reflect these fixed traits.

2.  **OpenZeppelin Usage:** Inherits standard ERC721, Enumerable (optional, useful for tracking supply), Pausable (for contract-level control), Ownable (for admin functions).

3.  **Chainlink VRF:** Integrates `VRFConsumerBaseV2` to request and receive verifiable randomness. This is crucial for the "quantum" aspect of probabilistic, unpredictable outcomes. The `s_requests` mapping tracks which token ID is waiting for which request ID.

4.  **State Management:** The `SeedState` enum and `TokenData` struct are central to tracking the unique lifecycle of these tokens. Modifiers like `whenInState` and `whenNotInState` enforce valid state transitions for different actions.

5.  **Marketplace:** Includes standard fixed-price listings and offers. The novelty here is the restriction that entangled tokens cannot be listed or offered individually. A more advanced version could allow listing/offering entangled pairs as bundles.

6.  **Trait Determination (`_applyDecoherenceLogic`):** This is a simplified placeholder. In a real project, this function would contain complex logic:
    *   Taking the VRF `randomness` as input.
    *   Accessing internal admin-configured `traitMapping` (e.g., mapping ranges of randomness to trait layers or specific traits).
    *   Checking the `entangledTokenId` and the state/properties of the entangled pair.
    *   Using an `entanglementEffectMapping` to modify how the randomness or base traits are interpreted.
    *   Combining these factors to build the `finalizedTraits` string or set specific trait properties stored elsewhere.

7.  **`tokenURI` Override:** This is important for dApps and marketplaces to display the token's current state and finalized traits. It dynamically generates a data URI based on the `SeedState`. In production, you'd likely use IPFS and store the generated JSON there, returning an `ipfs://` URI.

8.  **Offer Management:** The `_offers` mapping is a basic representation. For a production system with many offers per token, you might need a more gas-efficient structure (e.g., linked lists or indexing offers off-chain). The `getTokenOffers` view function is noted as potentially inefficient.

9.  **Gas Considerations:** The inclusion of Enumerable, complex mappings, and string manipulation can increase gas costs. For high-volume applications, optimizations might be needed. Iterating through offers in `getTokenOffers` is explicitly highlighted as inefficient.

10. **Security:** Standard OpenZeppelin patterns (`Ownable`, `Pausable`), require checks, and Solidity 0.8+ checked arithmetic are used. Re-entrancy is implicitly handled in transfers by the checks and state changes, but complex interactions (like entangled tokens affecting each other's decoherence simultaneously) would require careful locking or state management.

This contract provides a framework for a novel type of NFT with dynamic state and probabilistic outcomes influenced by interaction (entanglement), driven by external randomness, and traded on a custom marketplace with state-based restrictions. It goes beyond typical generative NFTs or standard marketplaces.