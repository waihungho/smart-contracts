Okay, this sounds like a fun challenge! Let's create a smart contract that simulates a "Quantum Entanglement Marketplace and Experimentation Lab". It will involve unique Soulbound-like tokens representing Entangled Pairs, a tradable resource representing "Quantum Processing Time" (QPUTime), and various functions to interact with these assets in simulated quantum experiments.

This concept is creative, blends advanced-sounding themes (quantum), uses a trendy token type (soulbound/non-transferable NFTs), and introduces complex interactions beyond simple trading.

**Outline & Function Summary**

**Contract Name:** `QuantumEntanglementMarketplace`

**Concept:** A decentralized platform for interacting with simulated "Quantum Entanglement Pairs" (Soulbound Tokens) and trading "Quantum Processing Time" (QPUTime - a consumable resource). Users can acquire pairs, spend QPUTime to perform simulated experiments, observe pair states, collaborate, and earn rewards (`QPReward`).

**Core Components:**
1.  **Entanglement Pairs (EP):** Non-transferable tokens representing theoretical entangled quantum pairs. Each has a unique state and history.
2.  **Quantum Processing Time (QPUTime):** A fungible resource required to perform actions/experiments. Can be acquired and traded on the internal marketplace.
3.  **QPReward:** A fungible token earned by participating in successful experiments or observations. Transferable.
4.  **Marketplace:** Simple listing/buying for QPUTime.
5.  **Experimentation Lab:** Functions allowing users to interact with their Entanglement Pairs using QPUTime.
6.  **Reputation:** A simple score reflecting user participation and success.

**Function Categories & Summary:**

1.  **Admin & Core Setup:**
    *   `constructor`: Initialize contract owner, set initial fees, pause status.
    *   `setMarketplaceFeeBasisPoints`: Set the fee percentage for QPUTime marketplace sales (Admin only).
    *   `withdrawFees`: Withdraw collected fees (Admin only).
    *   `pauseContract`: Pause all core user interactions (Admin only).
    *   `unpauseContract`: Unpause the contract (Admin only).
    *   `setQPUTimeMintLimit`: Set a limit on total QPUTime that can be minted (Admin only).
    *   `mintQPUTimeLicense`: Admin function to create initial QPUTime supply and distribute (Simulates resource generation).

2.  **Entanglement Pair (EP) Management (Soulbound ERC721-like):**
    *   `mintEntanglementPair`: Create a new, unique Entanglement Pair token and assign it to the caller (cannot be transferred later).
    *   `getPairState`: View the current simulated state of a specific Entanglement Pair.
    *   `getPairOwner`: Get the owner of a specific Entanglement Pair (standard ERC721 view).
    *   `getPairHistory`: View the recorded history of interactions/results for a specific pair.
    *   `getTotalPairsMinted`: View the total number of Entanglement Pairs created.
    *   *Note:* Standard ERC721 transfer/approval functions are deliberately excluded/disabled to enforce soulbound nature.

3.  **QPUTime Resource Management:**
    *   `getUserQPUTimeBalance`: View the QPUTime balance of an address.
    *   `delegateQPUTimeUsage`: Allow another address to spend your QPUTime.
    *   `revokeQPUTimeDelegation`: Revoke QPUTime spending delegation.
    *   `getQPUTimeDelegate`: View who an address has delegated QPUTime spending to.

4.  **QPUTime Marketplace:**
    *   `listQPUTimeForSale`: List a specified amount of your QPUTime for sale at a specific price in native token (e.g., ETH).
    *   `buyQPUTimeFromListing`: Purchase QPUTime from an active listing. Requires sending the exact native token amount.
    *   `cancelQPUTimeListing`: Cancel an active QPUTime listing you created.
    *   `getListing`: View details of a specific QPUTime listing.
    *   `getTotalListings`: View the total number of QPUTime listings ever created (including inactive/sold).

5.  **Experimentation & Interaction Lab:**
    *   `observePair`: Perform a simulated "observation" on an Entanglement Pair. Costs QPUTime. May change the pair's state, add to history, and potentially yield QPReward.
    *   `simulateQuantumExperiment`: Perform a more complex simulated experiment involving a single pair. Costs more QPUTime. Can have various outcomes (state change, history, QPReward).
    *   `entanglePairsSimulated`: Attempt to simulate entangling two separate Entanglement Pairs. Requires consent from both owners (or delegates) and significant QPUTime. If successful, links the pairs' states.
    *   `disentanglePairSimulated`: Attempt to simulate disentangling two previously entangled pairs. Requires owner/delegate consent and QPUTime.
    *   `explorePairParameterSpace`: Spend QPUTime to "explore" theoretical parameters or potential future states of a pair. Adds to history, may yield data (simulated via event/reward).
    *   `collaborateOnPairs`: Perform a simulated multi-user experiment requiring multiple specific pairs and QPUTime from each participant (or their delegates). Success updates multiple histories/states and distributes rewards.

6.  **QPReward Token Management:**
    *   `getQPRewardBalance`: View the QPReward balance of an address.
    *   `transferQPReward`: Transfer your QPReward balance to another address.

7.  **Reputation System:**
    *   `getUserReputation`: View the simulated reputation score of an address. (Reputation increases with successful experiments/collaborations).

**Total Functions:** 26 (Exceeds the 20 minimum)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementMarketplace
 * @dev A contract simulating a marketplace for Quantum Processing Time (QPUTime)
 * and an experimentation lab for interacting with Soulbound-like Quantum Entanglement Pairs (EPs).
 * Features include non-transferable EPs, tradable/delegatable QPUTime, simulated quantum experiments,
 * collaboration mechanics, earnable QPReward tokens, and a simple reputation system.
 */

// Outline & Function Summary:
// 1. Admin & Core Setup:
//    - constructor(): Initialize contract owner, fees, pause status.
//    - setMarketplaceFeeBasisPoints(uint256 _feeBasisPoints): Set QPUTime marketplace fee.
//    - withdrawFees(): Withdraw collected fees.
//    - pauseContract(): Pause core user interactions.
//    - unpauseContract(): Unpause contract.
//    - setQPUTimeMintLimit(uint256 _limit): Set total QPUTime mint limit.
//    - mintQPUTimeLicense(address _to, uint256 _amount): Admin function to mint QPUTime.
// 2. Entanglement Pair (EP) Management (Soulbound ERC721-like):
//    - mintEntanglementPair(): Create non-transferable EP.
//    - getPairState(uint256 _tokenId): View EP state.
//    - getPairOwner(uint256 _tokenId): View EP owner.
//    - getPairHistory(uint256 _tokenId): View EP interaction history.
//    - getTotalPairsMinted(): View total EPs created.
//    - (Standard ERC721 transfer/approval excluded for soulbound)
// 3. QPUTime Resource Management:
//    - getUserQPUTimeBalance(address _user): View QPUTime balance.
//    - delegateQPUTimeUsage(address _delegate): Allow address to spend your QPUTime.
//    - revokeQPUTimeDelegation(): Revoke QPUTime delegation.
//    - getQPUTimeDelegate(address _user): View QPUTime delegate.
// 4. QPUTime Marketplace:
//    - listQPUTimeForSale(uint256 _amount, uint256 _pricePerUnit): List QPUTime for sale.
//    - buyQPUTimeFromListing(uint256 _listingId): Buy QPUTime listing.
//    - cancelQPUTimeListing(uint256 _listingId): Cancel QPUTime listing.
//    - getListing(uint256 _listingId): View listing details.
//    - getTotalListings(): View total listing count.
// 5. Experimentation & Interaction Lab:
//    - observePair(uint256 _tokenId): Perform simulated observation.
//    - simulateQuantumExperiment(uint256 _tokenId, bytes32 _experimentParams): Perform simulated experiment.
//    - entanglePairsSimulated(uint256 _tokenId1, uint256 _tokenId2): Simulate entangling two pairs.
//    - disentanglePairSimulated(uint256 _tokenId): Simulate disentangling a pair.
//    - explorePairParameterSpace(uint256 _tokenId): Explore parameters of a pair.
//    - collaborateOnPairs(uint256[] memory _tokenIds, address[] memory _participants): Perform multi-user collaboration.
// 6. QPReward Token Management:
//    - getQPRewardBalance(address _user): View QPReward balance.
//    - transferQPReward(address _to, uint256 _amount): Transfer QPReward.
// 7. Reputation System:
//    - getUserReputation(address _user): View user reputation score.

contract QuantumEntanglementMarketplace {
    address public owner;
    bool public paused;

    // --- Configuration ---
    uint256 public marketplaceFeeBasisPoints; // Fee / 10000 (e.g., 100 = 1%)
    uint256 public totalQPUTimeMinted;
    uint256 public qpuTimeMintLimit; // Limit total QPUTime supply

    // --- Counters ---
    uint256 private _pairTokenIdCounter;
    uint256 private _listingIdCounter;

    // --- Data Structures ---

    struct EntanglementPair {
        address owner; // Owner of the soulbound token
        uint256 state; // Simulated quantum state (e.g., 0, 1, 2... or more complex struct)
        uint256 creationTime;
        uint256[] history; // Array of event IDs or results (simulated)
        uint256 entangledWith; // Token ID of the pair it's entangled with (0 if not entangled)
    }

    struct QPUTimeListing {
        address seller;
        uint256 amount;
        uint256 pricePerUnit; // Price in native token (wei) per unit of QPUTime
        bool active;
    }

    // --- Mappings ---

    // Entanglement Pairs (Soulbound ERC721-like)
    mapping(uint256 => EntanglementPair) private _entanglementPairs;
    mapping(uint256 => address) private _pairIdToOwner; // Explicit owner mapping for soulbound

    // QPUTime Resource (Fungible)
    mapping(address => uint256) private _qpuTimeBalances;
    mapping(address => address) private _qpuTimeDelegates; // User => Delegate

    // QPUTime Marketplace
    mapping(uint256 => QPUTimeListing) private _qpuTimeListings;

    // QPReward Token (Fungible)
    mapping(address => uint256) private _qpRewardBalances;

    // Reputation System
    mapping(address => uint256) private _userReputation;

    // --- Events ---

    event EntanglementPairMinted(uint256 indexed tokenId, address indexed owner);
    event QPUTimeMinted(address indexed to, uint256 amount, address indexed minter);
    event QPUTimeListed(uint256 indexed listingId, address indexed seller, uint256 amount, uint256 pricePerUnit);
    event QPUTimePurchased(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 amount, uint256 totalPrice);
    event QPUTimeListingCancelled(uint256 indexed listingId, address indexed seller);
    event QPUTimeConsumed(address indexed user, uint256 amount, string action);
    event QPUTimeDelegated(address indexed delegator, address indexed delegatee);
    event QPUTimeDelegationRevoked(address indexed delegator, address indexed delegateee);
    event PairObserved(uint256 indexed tokenId, address indexed observer, uint256 newState, uint256 rewardAmount);
    event ExperimentPerformed(uint256 indexed tokenId, address indexed participant, bytes32 experimentParams, bool success, uint256 rewardAmount);
    event PairsSimulatedEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed initiator);
    event PairSimulatedDisentangled(uint256 indexed tokenId, address indexed initiator);
    event ParameterSpaceExplored(uint256 indexed tokenId, address indexed explorer, uint256 dataYield);
    event CollaborationPerformed(uint256[] indexed tokenIds, address[] indexed participants, bool success, uint256 totalReward);
    event QPRewardIssued(address indexed to, uint256 amount, string reason);
    event QPRewardTransferred(address indexed from, address indexed to, uint256 amount);
    event FeeWithdrawn(address indexed recipient, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // --- Errors ---

    error CallerIsNotOwner();
    error ContractIsPaused();
    error InvalidFeeBasisPoints();
    error AmountMustBePositive();
    error QPUTimeLimitReached(uint256 limit);
    error QPUTimeDoesNotExist(address user);
    error InsufficientQPUTime(uint256 required, uint256 available);
    error ListingDoesNotExist(uint256 listingId);
    error ListingIsNotActive();
    error ListingSellerCannotBuy();
    error InsufficientPayment(uint256 required, uint256 sent);
    error ListingNotOwnedByUser();
    error PairDoesNotExist(uint256 tokenId);
    error PairNotOwnedByUser(uint256 tokenId, address user);
    error CallerIsNotOwnerOrDelegate(address user, uint256 tokenId); // For EP interactions
    error CannotDelegateToSelf();
    error DelegationDoesNotExist(address user);
    error CannotDelegateToZeroAddress();
    error PairsAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
    error PairsNotEntangled(uint256 tokenId);
    error InvalidParticipantsCount();
    error ParticipantMismatch(address participant, uint256 expectedTokens);
    error InsufficientCollaborationQPUTime(address participant, uint256 required);
    error InvalidRecipient();

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert CallerIsNotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractIsPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert ContractIsPaused();
        _;
    }

    modifier onlyPairOwnerOrDelegate(uint256 _tokenId) {
        address pairOwner = _pairIdToOwner[_tokenId];
        address delegate = _qpuTimeDelegates[pairOwner];
        if (msg.sender != pairOwner && msg.sender != delegate) revert CallerIsNotOwnerOrDelegate(pairOwner, _tokenId);
        _;
    }

    // --- Constructor ---

    constructor(uint256 initialFeeBasisPoints, uint256 _qpuTimeGlobalLimit) {
        owner = msg.sender;
        paused = false;
        if (initialFeeBasisPoints > 10000) revert InvalidFeeBasisPoints();
        marketplaceFeeBasisPoints = initialFeeBasisPoints;
        qpuTimeMintLimit = _qpuTimeGlobalLimit;
    }

    // --- Admin & Core Setup ---

    /// @notice Sets the fee percentage for QPUTime marketplace sales.
    /// @param _feeBasisPoints The fee amount in basis points (e.g., 100 = 1%). Max 10000 (100%).
    function setMarketplaceFeeBasisPoints(uint256 _feeBasisPoints) external onlyOwner {
        if (_feeBasisPoints > 10000) revert InvalidFeeBasisPoints();
        marketplaceFeeBasisPoints = _feeBasisPoints;
    }

    /// @notice Allows the owner to withdraw accumulated marketplace fees.
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(owner).call{value: balance}("");
            require(success, "Fee withdrawal failed");
            emit FeeWithdrawn(owner, balance);
        }
    }

    /// @notice Pauses core user interactions with the contract.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses core user interactions with the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Sets the global limit for total QPUTime that can ever be minted by the admin.
    /// @param _limit The maximum allowed total QPUTime.
    function setQPUTimeMintLimit(uint256 _limit) external onlyOwner {
        qpuTimeMintLimit = _limit;
    }


    /// @notice Admin function to mint new QPUTime tokens (simulating resource generation).
    /// @param _to The address to receive the QPUTime.
    /// @param _amount The amount of QPUTime to mint.
    function mintQPUTimeLicense(address _to, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert AmountMustBePositive();
        if (totalQPUTimeMinted + _amount > qpuTimeMintLimit) revert QPUTimeLimitReached(qpuTimeMintLimit);

        _qpuTimeBalances[_to] += _amount;
        totalQPUTimeMinted += _amount;
        emit QPUTimeMinted(_to, _amount, msg.sender);
    }

    // --- Internal Resource Management ---

    /// @dev Internal function to consume a user's QPUTime, respecting delegation.
    /// @param _user The user whose QPUTime should be consumed.
    /// @param _amount The amount to consume.
    /// @param _action A string describing the action consuming QPUTime.
    function _consumeQPUTime(address _user, uint256 _amount, string memory _action) internal {
        address payer = msg.sender; // Default to caller

        // Check if caller is a delegate for the user
        if (_qpuTimeDelegates[_user] == msg.sender) {
             payer = _user; // If caller is the delegate, charge the delegator
        } else {
             // If not a delegate, the caller must be the user themselves
             if (msg.sender != _user) revert CallerIsNotOwnerOrDelegate(_user, 0); // 0 here signifies no specific pair
             payer = _user;
        }

        if (_qpuTimeBalances[payer] < _amount) revert InsufficientQPUTime(_amount, _qpuTimeBalances[payer]);
        if (_amount == 0) return; // No consumption needed

        _qpuTimeBalances[payer] -= _amount;
        emit QPUTimeConsumed(payer, _amount, _action);
    }

    /// @dev Internal function to issue QPReward tokens.
    /// @param _to The address to receive the reward.
    /// @param _amount The amount of reward.
    /// @param _reason A string describing why the reward was issued.
    function _issueQPReward(address _to, uint256 _amount, string memory _reason) internal {
        if (_amount == 0) return;
        _qpRewardBalances[_to] += _amount;
        emit QPRewardIssued(_to, _amount, _reason);
    }

    /// @dev Internal function to update user reputation.
    /// @param _user The user whose reputation to update.
    /// @param _points The points to add (can be negative for future extensions).
    function _updateUserReputation(address _user, uint256 _points) internal {
        _userReputation[_user] += _points; // Simple additive reputation for now
    }

    /// @dev Internal function to record history for a pair.
    /// @param _tokenId The pair token ID.
    /// @param _eventCode A code representing the event type (e.g., 1 for observation, 2 for experiment).
    function _recordPairHistory(uint256 _tokenId, uint256 _eventCode) internal {
        _entanglementPairs[_tokenId].history.push(_eventCode);
    }


    // --- Entanglement Pair (EP) Management ---

    /// @notice Mints a new Entanglement Pair token, which is soulbound to the caller.
    /// @dev This token cannot be transferred or sold through standard means.
    function mintEntanglementPair() external whenNotPaused {
        _pairTokenIdCounter++;
        uint256 newTokenId = _pairTokenIdCounter;

        _entanglementPairs[newTokenId] = EntanglementPair({
            owner: msg.sender,
            state: uint256(keccak256(abi.encodePacked(newTokenId, block.timestamp, msg.sender))) % 100, // Simulated initial random-ish state
            creationTime: block.timestamp,
            history: new uint256[](0),
            entangledWith: 0 // Not entangled initially
        });
        _pairIdToOwner[newTokenId] = msg.sender;

        emit EntanglementPairMinted(newTokenId, msg.sender);
    }

    /// @notice Gets the current simulated state of an Entanglement Pair.
    /// @param _tokenId The ID of the Entanglement Pair.
    /// @return The simulated state value.
    function getPairState(uint256 _tokenId) external view returns (uint256) {
         if (_pairIdToOwner[_tokenId] == address(0)) revert PairDoesNotExist(_tokenId);
         return _entanglementPairs[_tokenId].state;
    }

    /// @notice Gets the owner of an Entanglement Pair (soulbound).
    /// @param _tokenId The ID of the Entanglement Pair.
    /// @return The owner's address.
    function getPairOwner(uint256 _tokenId) external view returns (address) {
        address ownerAddress = _pairIdToOwner[_tokenId];
         if (ownerAddress == address(0)) revert PairDoesNotExist(_tokenId);
         return ownerAddress;
    }

    /// @notice Gets the history of interactions for an Entanglement Pair.
    /// @param _tokenId The ID of the Entanglement Pair.
    /// @return An array of history event codes.
    function getPairHistory(uint256 _tokenId) external view returns (uint256[] memory) {
         if (_pairIdToOwner[_tokenId] == address(0)) revert PairDoesNotExist(_tokenId);
        return _entanglementPairs[_tokenId].history;
    }

    /// @notice Gets the total number of Entanglement Pairs that have been minted.
    /// @return The total count of minted pairs.
    function getTotalPairsMinted() external view returns (uint256) {
        return _pairTokenIdCounter;
    }

    // --- QPUTime Resource Management ---

    /// @notice Gets the QPUTime balance for a specific address.
    /// @param _user The address to check the balance for.
    /// @return The QPUTime balance.
    function getUserQPUTimeBalance(address _user) external view returns (uint256) {
        return _qpuTimeBalances[_user];
    }

    /// @notice Delegates the ability to spend the caller's QPUTime balance to another address.
    /// @param _delegate The address that is allowed to spend QPUTime.
    function delegateQPUTimeUsage(address _delegate) external whenNotPaused {
        if (_delegate == msg.sender) revert CannotDelegateToSelf();
        if (_delegate == address(0)) revert CannotDelegateToZeroAddress();
        _qpuTimeDelegates[msg.sender] = _delegate;
        emit QPUTimeDelegated(msg.sender, _delegate);
    }

    /// @notice Revokes the QPUTime spending delegation for the caller.
    function revokeQPUTimeDelegation() external whenNotPaused {
        if (_qpuTimeDelegates[msg.sender] == address(0)) revert DelegationDoesNotExist(msg.sender);
        address delegatee = _qpuTimeDelegates[msg.sender];
        delete _qpuTimeDelegates[msg.sender];
        emit QPUTimeDelegationRevoked(msg.sender, delegatee);
    }

    /// @notice Gets the address currently delegated to spend the user's QPUTime.
    /// @param _user The address whose delegation is being checked.
    /// @return The delegate's address, or address(0) if no delegate is set.
    function getQPUTimeDelegate(address _user) external view returns (address) {
        return _qpuTimeDelegates[_user];
    }

    // --- QPUTime Marketplace ---

    /// @notice Lists a specified amount of the caller's QPUTime for sale.
    /// @param _amount The amount of QPUTime to list.
    /// @param _pricePerUnit The price in native token (wei) for each unit of QPUTime.
    function listQPUTimeForSale(uint256 _amount, uint256 _pricePerUnit) external whenNotPaused {
        if (_amount == 0 || _pricePerUnit == 0) revert AmountMustBePositive();
        if (_qpuTimeBalances[msg.sender] < _amount) revert InsufficientQPUTime(_amount, _qpuTimeBalances[msg.sender]);

        _qpuTimeBalances[msg.sender] -= _amount; // Hold QPUTime in contract during listing

        _listingIdCounter++;
        uint256 newListingId = _listingIdCounter;

        _qpuTimeListings[newListingId] = QPUTimeListing({
            seller: msg.sender,
            amount: _amount,
            pricePerUnit: _pricePerUnit,
            active: true
        });

        emit QPUTimeListed(newListingId, msg.sender, _amount, _pricePerUnit);
    }

    /// @notice Purchases QPUTime from an active listing. Requires sending the correct native token amount.
    /// @param _listingId The ID of the listing to purchase from.
    function buyQPUTimeFromListing(uint256 _listingId) external payable whenNotPaused {
        QPUTimeListing storage listing = _qpuTimeListings[_listingId];

        if (!listing.active) revert ListingIsNotActive();
        if (listing.seller == address(0)) revert ListingDoesNotExist(_listingId); // Double check existence
        if (listing.seller == msg.sender) revert ListingSellerCannotBuy();

        uint256 totalPrice = listing.amount * listing.pricePerUnit;
        if (msg.value < totalPrice) revert InsufficientPayment(totalPrice, msg.value);

        listing.active = false; // Mark listing as inactive immediately

        // Transfer QPUTime to buyer
        _qpuTimeBalances[msg.sender] += listing.amount;

        // Calculate and distribute payment (seller gets price - fee, fee goes to contract balance)
        uint256 feeAmount = (totalPrice * marketplaceFeeBasisPoints) / 10000;
        uint256 sellerReceiveAmount = totalPrice - feeAmount;

        (bool successSeller, ) = payable(listing.seller).call{value: sellerReceiveAmount}("");
        // Any remaining value (overpayment or dust) stays in contract, withdrawable by admin
        require(successSeller, "Seller payment failed");

        emit QPUTimePurchased(_listingId, msg.sender, listing.seller, listing.amount, totalPrice);

        // Refund any overpayment
        if (msg.value > totalPrice) {
             (bool successRefund, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
             require(successRefund, "Overpayment refund failed");
        }
    }

    /// @notice Cancels an active QPUTime listing you created. Returns the QPUTime to the seller.
    /// @param _listingId The ID of the listing to cancel.
    function cancelQPUTimeListing(uint256 _listingId) external whenNotPaused {
        QPUTimeListing storage listing = _qpuTimeListings[_listingId];

        if (!listing.active) revert ListingIsNotActive();
        if (listing.seller == address(0)) revert ListingDoesNotExist(_listingId); // Double check existence
        if (listing.seller != msg.sender) revert ListingNotOwnedByUser();

        listing.active = false; // Mark listing as inactive

        // Return QPUTime to seller
        _qpuTimeBalances[msg.sender] += listing.amount;

        emit QPUTimeListingCancelled(_listingId, msg.sender);
    }

    /// @notice Gets the details of a specific QPUTime marketplace listing.
    /// @param _listingId The ID of the listing.
    /// @return seller The seller's address.
    /// @return amount The amount of QPUTime listed.
    /// @return pricePerUnit The price per unit in native token (wei).
    /// @return active Whether the listing is currently active.
    function getListing(uint256 _listingId) external view returns (address seller, uint256 amount, uint256 pricePerUnit, bool active) {
        QPUTimeListing storage listing = _qpuTimeListings[_listingId];
        if (listing.seller == address(0)) revert ListingDoesNotExist(_listingId);
        return (listing.seller, listing.amount, listing.pricePerUnit, listing.active);
    }

    /// @notice Gets the total number of QPUTime listings created (including inactive ones).
    /// @return The total listing count.
    function getTotalListings() external view returns (uint256) {
        return _listingIdCounter;
    }

    // --- Experimentation & Interaction Lab ---

    /// @notice Performs a simulated "observation" on an Entanglement Pair.
    /// Costs QPUTime, can change state, add history, and potentially yield QPReward.
    /// @param _tokenId The ID of the Entanglement Pair to observe.
    function observePair(uint256 _tokenId) external whenNotPaused onlyPairOwnerOrDelegate(_tokenId) {
        if (_pairIdToOwner[_tokenId] == address(0)) revert PairDoesNotExist(_tokenId);

        uint256 qpuCost = 10; // Simulated cost
        _consumeQPUTime(_pairIdToOwner[_tokenId], qpuCost, "ObservePair");

        // Simulate state collapse/change (simple logic)
        uint256 oldState = _entanglementPairs[_tokenId].state;
        uint256 newState = (oldState + uint256(keccak256(abi.encodePacked(_tokenId, block.timestamp, msg.sender, qpuCost)))) % 100;
        _entanglementPairs[_tokenId].state = newState;

        // Simulate reward based on observation outcome (e.g., observing a rare state)
        uint256 rewardAmount = (newState % 10 == 7) ? 5 : 1; // Example: Reward 5 for state ending in 7, else 1
        _issueQPReward(msg.sender, rewardAmount, "ObservationReward");

        _recordPairHistory(_tokenId, 1); // Record observation event (code 1)
        _updateUserReputation(msg.sender, 1); // Increase reputation

        emit PairObserved(_tokenId, msg.sender, newState, rewardAmount);
    }

     /// @notice Performs a more complex simulated quantum experiment on an Entanglement Pair.
     /// Costs more QPUTime and has different potential outcomes.
     /// @param _tokenId The ID of the Entanglement Pair for the experiment.
     /// @param _experimentParams Simulated parameters for the experiment (arbitrary bytes).
    function simulateQuantumExperiment(uint256 _tokenId, bytes32 _experimentParams) external whenNotPaused onlyPairOwnerOrDelegate(_tokenId) {
         if (_pairIdToOwner[_tokenId] == address(0)) revert PairDoesNotExist(_tokenId);

        uint256 qpuCost = 50; // Simulated cost
        _consumeQPUTime(_pairIdToOwner[_tokenId], qpuCost, "SimulateQuantumExperiment");

        // Simulate experiment outcome (more complex logic)
        uint256 outcomeHash = uint256(keccak256(abi.encodePacked(_tokenId, block.timestamp, msg.sender, qpuCost, _experimentParams)));
        bool success = outcomeHash % 5 != 0; // 80% chance of 'success'
        uint256 rewardAmount = 0;
        uint256 historyCode = 2; // Experiment event (code 2)

        if (success) {
            // Simulate state evolution
             _entanglementPairs[_tokenId].state = ( _entanglementPairs[_tokenId].state + (outcomeHash % 20) ) % 100;
            rewardAmount = 10 + (outcomeHash % 10); // Variable reward
            _issueQPReward(msg.sender, rewardAmount, "ExperimentSuccessReward");
            _updateUserReputation(msg.sender, 3); // Larger reputation gain
        } else {
            // Simulate failed outcome (maybe state change or penalty)
             _entanglementPairs[_tokenId].state = outcomeHash % 100; // Random state change on failure
            historyCode = 3; // Experiment failed event (code 3)
             // No reward for failure
        }

        _recordPairHistory(_tokenId, historyCode);
        emit ExperimentPerformed(_tokenId, msg.sender, _experimentParams, success, rewardAmount);
    }

    /// @notice Attempts to simulate entangling two separate Entanglement Pairs.
    /// Requires consent from both owners/delegates and significant QPUTime.
    /// If successful, links the pairs' `entangledWith` fields.
    /// @param _tokenId1 The ID of the first Entanglement Pair.
    /// @param _tokenId2 The ID of the second Entanglement Pair.
    function entanglePairsSimulated(uint256 _tokenId1, uint256 _tokenId2) external whenNotPaused {
        if (_tokenId1 == _tokenId2) revert InvalidRecipient(); // Cannot entangle with self
        if (_pairIdToOwner[_tokenId1] == address(0)) revert PairDoesNotExist(_tokenId1);
        if (_pairIdToOwner[_tokenId2] == address(0)) revert PairDoesNotExist(_tokenId2);

        // Check ownership/delegation for BOTH pairs by the caller
        address owner1 = _pairIdToOwner[_tokenId1];
        address owner2 = _pairIdToOwner[_tokenId2];
        if (msg.sender != owner1 && _qpuTimeDelegates[owner1] != msg.sender) revert CallerIsNotOwnerOrDelegate(owner1, _tokenId1);
        if (msg.sender != owner2 && _qpuTimeDelegates[owner2] != msg.sender) revert CallerIsNotOwnerOrDelegate(owner2, _tokenId2);

        if (_entanglementPairs[_tokenId1].entangledWith != 0 || _entanglementPairs[_tokenId2].entangledWith != 0) {
            revert PairsAlreadyEntangled(_tokenId1, _tokenId2);
        }

        uint256 qpuCost = 200; // High simulated cost
        // Consume QPUTime from both owners or the delegate if caller is a delegate for both
        if (msg.sender == _qpuTimeDelegates[owner1] && msg.sender == _qpuTimeDelegates[owner2]) {
             _consumeQPUTime(owner1, qpuCost / 2, "SimulateEntanglement"); // Split cost
             _consumeQPUTime(owner2, qpuCost / 2, "SimulateEntanglement");
        } else if (msg.sender == owner1 && msg.sender == owner2) {
             _consumeQPUTime(msg.sender, qpuCost, "SimulateEntanglement"); // Single owner of both
        } else if (msg.sender == owner1 && msg.sender == _qpuTimeDelegates[owner2]) {
             _consumeQPUTime(owner1, qpuCost / 2, "SimulateEntanglement");
             _consumeQPUTime(owner2, qpuCost / 2, "SimulateEntanglement");
        } // ... handle all combinations, or simplify: require caller has sufficient QPUTime *if* they are delegate for both,
          // or require owners fund *if* they are calling. Let's simplify and require caller has enough QPUTime if they are the single delegate or owner of both.
          // If separate owners/delegates call this *together* (which is hard on chain), we'd need a multi-sig pattern.
          // Let's assume the caller is either the owner of both, or a delegate for both, or one owner is also the delegate for the other.
          // A simpler approach: require the caller to have the total QPU cost, consuming it from *their* balance,
          // and perhaps distribute reward/reputation to *both* owners/delegates involved.
          // Or, require *each* owner/delegate to have a portion and consume from their respective balances.
          // Let's go with requiring caller has QPUTime, but distribute rewards/reputation to owners.

        // Let's re-structure the QPU consumption for clarity and fairness:
        // Each owner (or their delegate if caller is delegate) must provide half the QPU cost.
        address payer1 = (msg.sender == _qpuTimeDelegates[owner1]) ? owner1 : msg.sender;
        address payer2 = (msg.sender == _qpuTimeDelegates[owner2]) ? owner2 : msg.sender;

        _consumeQPUTime(payer1, qpuCost / 2, "SimulateEntanglement_P1");
        _consumeQPUTime(payer2, qpuCost - (qpuCost / 2), "SimulateEntanglement_P2"); // Handle odd costs

        // Simulate success chance (e.g., 60%)
        bool success = uint256(keccak256(abi.encodePacked(_tokenId1, _tokenId2, block.timestamp, msg.sender))) % 10 < 6;

        if (success) {
            _entanglementPairs[_tokenId1].entangledWith = _tokenId2;
            _entanglementPairs[_tokenId2].entangledWith = _tokenId1;
            // Simulate state correlation (e.g., force states to be similar or opposite)
            _entanglementPairs[_tokenId1].state = _entanglementPairs[_tokenId2].state; // Example correlation
            _recordPairHistory(_tokenId1, 4); // Entangled event (code 4)
            _recordPairHistory(_tokenId2, 4);
             _updateUserReputation(owner1, 5);
             if(owner1 != owner2) _updateUserReputation(owner2, 5);
             _issueQPReward(owner1, 20, "EntanglementSuccessReward");
             if(owner1 != owner2) _issueQPReward(owner2, 20, "EntanglementSuccessReward");

            emit PairsSimulatedEntangled(_tokenId1, _tokenId2, msg.sender);
        } else {
             _recordPairHistory(_tokenId1, 5); // Entanglement failed event (code 5)
             _recordPairHistory(_tokenId2, 5);
             // No reward for failure
             // States remain independent
        }
    }

    /// @notice Attempts to simulate disentangling an Entanglement Pair from its partner.
    /// Requires consent from the owner/delegate and QPUTime.
    /// @param _tokenId The ID of the Entanglement Pair to disentangle.
    function disentanglePairSimulated(uint256 _tokenId) external whenNotPaused onlyPairOwnerOrDelegate(_tokenId) {
        if (_pairIdToOwner[_tokenId] == address(0)) revert PairDoesNotExist(_tokenId);

        uint256 entangledWithId = _entanglementPairs[_tokenId].entangledWith;
        if (entangledWithId == 0 || _pairIdToOwner[entangledWithId] == address(0)) {
            revert PairsNotEntangled(_tokenId);
        }
        // Check if the other pair also thinks it's entangled with this one
        if (_entanglementPairs[entangledWithId].entangledWith != _tokenId) {
             // This is an inconsistent state, maybe revert or fix? Let's revert.
             revert PairsNotEntangled(_tokenId);
        }

        uint256 qpuCost = 150; // Simulated cost
        _consumeQPUTime(_pairIdToOwner[_tokenId], qpuCost, "SimulateDisentanglement");

        // Simulate success chance (e.g., 70%)
        bool success = uint256(keccak256(abi.encodePacked(_tokenId, block.timestamp, msg.sender))) % 10 < 7;

        if (success) {
            _entanglementPairs[_tokenId].entangledWith = 0;
            _entanglementPairs[entangledWithId].entangledWith = 0;
             _recordPairHistory(_tokenId, 6); // Disentangled event (code 6)
             _recordPairHistory(entangledWithId, 6);
             _updateUserReputation(msg.sender, 2);
             _issueQPReward(msg.sender, 15, "DisentanglementSuccessReward");
            emit PairSimulatedDisentangled(_tokenId, msg.sender);
        } else {
             _recordPairHistory(_tokenId, 7); // Disentanglement failed event (code 7)
             _recordPairHistory(entangledWithId, 7);
             // No reward for failure
        }
    }

    /// @notice Spends QPUTime to explore theoretical parameters or potential states of a pair.
    /// Adds to the pair's history and may yield simulated "data" (represented by QPReward).
    /// @param _tokenId The ID of the Entanglement Pair to explore.
    function explorePairParameterSpace(uint256 _tokenId) external whenNotPaused onlyPairOwnerOrDelegate(_tokenId) {
        if (_pairIdToOwner[_tokenId] == address(0)) revert PairDoesNotExist(_tokenId);

        uint256 qpuCost = 75; // Simulated cost
        _consumeQPUTime(_pairIdToOwner[_tokenId], qpuCost, "ExploreParameterSpace");

        // Simulate data yield
        uint256 dataYield = uint256(keccak256(abi.encodePacked(_tokenId, block.timestamp, msg.sender, qpuCost))) % 50 + 10; // Yields 10-60
        _issueQPReward(msg.sender, dataYield, "ParameterExplorationYield");

        _recordPairHistory(_tokenId, 8); // Parameter exploration event (code 8)
        _updateUserReputation(msg.sender, 1);

        emit ParameterSpaceExplored(_tokenId, msg.sender, dataYield);
    }


    /// @notice Performs a simulated multi-user collaboration experiment.
    /// Requires multiple participants, each contributing a specific Entanglement Pair and QPUTime.
    /// Participants array length must match _tokenIds length. Each participant must own/delegate their respective token.
    /// @param _tokenIds An array of Entanglement Pair IDs involved.
    /// @param _participants An array of addresses, where _participants[i] is the owner/delegate for _tokenIds[i].
    function collaborateOnPairs(uint256[] memory _tokenIds, address[] memory _participants) external whenNotPaused {
        if (_tokenIds.length != _participants.length) revert InvalidParticipantsCount();
        if (_tokenIds.length < 2) revert InvalidParticipantsCount(); // Requires at least 2 pairs/participants

        uint256 qpuCostPerParticipant = 100; // Simulated cost per participant

        // Validate participants and pairs, consume QPUTime
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 currentTokenId = _tokenIds[i];
            address participantAddress = _participants[i];

            if (_pairIdToOwner[currentTokenId] == address(0)) revert PairDoesNotExist(currentTokenId);

            address pairOwner = _pairIdToOwner[currentTokenId];
            address delegate = _qpuTimeDelegates[pairOwner];

            // The participant listed must be the owner or the delegate for this specific pair
            if (participantAddress != pairOwner && participantAddress != delegate) {
                 revert ParticipantMismatch(participantAddress, currentTokenId);
            }
            // The caller must be the *same* address as the participant listed for *their* token
            if (msg.sender != participantAddress) revert ParticipantMismatch(msg.sender, currentTokenId);


            // Consume QPUTime from the participant's balance (or their delegator's balance if they are a delegate)
            address payer = (participantAddress == delegate) ? pairOwner : participantAddress;
            _consumeQPUTime(payer, qpuCostPerParticipant, "Collaboration");
        }

        // Simulate collaboration outcome (e.g., 75% success chance)
        bytes32 outcomeSeed = keccak256(abi.encodePacked(_tokenIds, _participants, block.timestamp));
        bool success = uint256(outcomeSeed) % 4 != 0; // 75% success

        uint256 totalReward = 0;
        uint256 historyCode = 9; // Collaboration event (code 9)
        if (!success) historyCode = 10; // Collaboration failed (code 10)

        // Update pairs, issue rewards, update reputation for all participants
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 currentTokenId = _tokenIds[i];
            address participantAddress = _participants[i]; // This is the address whose reputation/reward is updated

            if (success) {
                 // Simulate state update based on collaboration
                 _entanglementPairs[currentTokenId].state = uint256(keccak256(abi.encodePacked(currentTokenId, outcomeSeed, i))) % 100;
                 uint256 participantReward = 30 + (uint256(keccak256(abi.encodePacked(outcomeSeed, i))) % 20); // Variable reward per participant
                 _issueQPReward(participantAddress, participantReward, "CollaborationSuccessReward");
                 totalReward += participantReward;
                 _updateUserReputation(participantAddress, 5); // Higher reputation gain
            } else {
                 // Optional: Simulate minor state perturbation on failure
                  _entanglementPairs[currentTokenId].state = uint256(keccak256(abi.encodePacked(currentTokenId, outcomeSeed, i, "fail"))) % 100;
                 // No reward for failure
            }
            _recordPairHistory(currentTokenId, historyCode);
        }

        emit CollaborationPerformed(_tokenIds, _participants, success, totalReward);
    }

    // --- QPReward Token Management ---

    /// @notice Gets the QPReward token balance for a specific address.
    /// @param _user The address to check the balance for.
    /// @return The QPReward balance.
    function getQPRewardBalance(address _user) external view returns (uint256) {
        return _qpRewardBalances[_user];
    }

    /// @notice Transfers QPReward tokens from the caller's balance to another address.
    /// @param _to The recipient of the QPReward tokens.
    /// @param _amount The amount of QPReward tokens to transfer.
    function transferQPReward(address _to, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert AmountMustBePositive();
        if (_to == address(0)) revert InvalidRecipient();
        if (_qpRewardBalances[msg.sender] < _amount) revert InsufficientQPUTime(_amount, _qpRewardBalances[msg.sender]); // Reusing error for brevity

        _qpRewardBalances[msg.sender] -= _amount;
        _qpRewardBalances[_to] += _amount;

        emit QPRewardTransferred(msg.sender, _to, _amount);
    }

    // --- Reputation System ---

    /// @notice Gets the simulated reputation score for a specific address.
    /// Reputation increases through successful participation in experiments and collaborations.
    /// @param _user The address to check the reputation for.
    /// @return The reputation score.
    function getUserReputation(address _user) external view returns (uint256) {
        return _userReputation[_user];
    }

    // --- Soulbound / Non-Transferable NFT Implementation Notes ---
    // Standard ERC721 transferFrom, safeTransferFrom, approve, setApprovalForAll
    // methods are NOT implemented here. This is intentional to make the Entanglement
    // Pairs non-transferable, acting as Soulbound Tokens tied to the minting address.
    // The owner is stored in _pairIdToOwner mapping, which is set only during minting.
    // Any interaction requires the caller to be the owner *or* their designated QPUTime delegate.
}
```