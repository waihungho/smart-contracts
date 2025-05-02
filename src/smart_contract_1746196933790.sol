Okay, here is a smart contract designed with several interesting, advanced, creative, and trendy concepts combined: dynamic NFT states, energy accumulation requiring user interaction, state evolution based on conditions, metaphorical "entanglement" between NFTs, a built-in marketplace, and batch processing.

It's named `QuantumQuasarMarketplace` to reflect the dynamic and somewhat abstract nature of the assets and their interactions. The assets (`Quasar Shards`) evolve, accumulate energy, and can be entangled.

---

**Outline and Function Summary**

**Contract Name:** `QuantumQuasarMarketplace`

**Concept:** A marketplace for dynamic, evolving NFTs ("Quasar Shards"). Shards accumulate "Quantum Energy" over time (requiring user interaction to claim/update), which is needed to trigger state "Evolution". Shards can also be "Entangled" with another shard, linking their fates or potentially affecting energy accumulation. Includes a basic marketplace for buying and selling.

**Key Features & Advanced Concepts:**

1.  **Dynamic NFT State:** NFTs (`Quasar Shards`) have multiple potential states (`ShardState`) that can change based on logic within the contract.
2.  **User-Triggered Dynamics:** Energy accumulation and evolution are not automatic; users must interact with the contract (`accumulateEnergy`, `triggerEvolution`) to advance their shard's state.
3.  **Time-Based Energy Accumulation:** Shards accumulate energy based on the time elapsed since their last update.
4.  **State Evolution:** Shards can evolve to a new state if they meet energy requirements and are in a valid pre-evolution state. The outcome might depend on parameters.
5.  **Metaphorical Entanglement:** Two shards can be linked (`entangled`). Breaking entanglement is possible. Future logic could make entanglement affect energy, evolution, or marketplace interactions.
6.  **Built-in Marketplace:** Users can list and buy shards directly within the contract.
7.  **Batch Operations:** Includes a function to perform energy accumulation on multiple owned shards at once.
8.  **Configurable Parameters:** Owner can adjust evolution requirements, fees, etc.

**Inheritance:**
*   `ERC721Enumerable`: For standard NFT functionality, including listing tokens owned by an address.
*   `Ownable`: For administrative control.
*   `Pausable`: For pausing critical operations in emergencies.

**Function Categories & Summary (Total > 20 Functions):**

1.  **Admin & Setup (Owner-only):**
    *   `constructor`: Initializes contract, mints genesis shards.
    *   `pause`: Pauses core contract functions.
    *   `unpause`: Unpauses contract functions.
    *   `withdrawFees`: Allows owner to withdraw collected fees.
    *   `setEvolutionParameters`: Configure energy requirements for evolution.
    *   `setEntanglementFee`: Set the fee required to propose entanglement.
    *   `setMarketplaceFeeRate`: Set the percentage fee for marketplace sales.
    *   `setShardMetadataURI`: Set the base URI for token metadata.
    *   `setAllowedEvolutionTargets`: Define which states can evolve into which other states.
    *   `createGenesisShards`: Mint initial shards (potentially only once).

2.  **Minting:**
    *   `userMintShard`: Allows users to mint new shards by paying a fee.

3.  **Shard Dynamics & Evolution:**
    *   `accumulateEnergy`: Updates a shard's energy based on elapsed time (user-callable).
    *   `triggerEvolution`: Attempts to evolve a shard's state if energy requirements are met (user-callable).
    *   `bulkAccumulateEnergy`: Calls `accumulateEnergy` for a list of owned shards.

4.  **Entanglement:**
    *   `proposeEntanglement`: Initiates an entanglement proposal between two shards (requires fee).
    *   `acceptEntanglement`: Accepts a pending entanglement proposal.
    *   `breakEntanglement`: Terminates an active entanglement between two shards.

5.  **Marketplace:**
    *   `listShardForSale`: Lists an owned shard on the marketplace at a specific price.
    *   `buyShard`: Purchases a shard listed on the marketplace.
    *   `cancelListing`: Removes an owned shard from the marketplace listing.

6.  **Utility & Burning:**
    *   `burnShard`: Allows the owner of a shard to destroy it.

7.  **View & Query (Read-only):**
    *   `getShardState`: Get the current state of a shard.
    *   `getShardEnergy`: Get the current energy level of a shard.
    *   `getShardLastUpdateTime`: Get the timestamp of the last energy update.
    *   `getEntangledShard`: Get the ID of the shard entangled with a given shard.
    *   `getPendingEntanglementProposal`: Check details of a pending entanglement proposal.
    *   `getListing`: Get details of a specific marketplace listing.
    *   `getAllListings`: Get details for all active marketplace listings (basic implementation).
    *   `previewEvolutionOutcome`: Predict the potential outcome state of evolution for a shard.
    *   `checkEvolutionEligibility`: Check if a shard currently meets the criteria to *attempt* evolution.
    *   `getUserShardHoldings`: Get the list of shard IDs owned by an address (from ERC721Enumerable).
    *   `tokenURI`: Get the metadata URI for a shard (Standard ERC721).
    *   `supportsInterface`: Check supported interfaces (Standard ERC165).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary:
// Contract Name: QuantumQuasarMarketplace
// Concept: A marketplace for dynamic, evolving NFTs ("Quasar Shards").
// Shards accumulate "Quantum Energy" over time (requiring user interaction to claim/update),
// which is needed to trigger state "Evolution". Shards can also be "Entangled" with
// another shard, linking their fates or potentially affecting energy accumulation.
// Includes a basic marketplace for buying and selling.
//
// Key Features & Advanced Concepts:
// 1. Dynamic NFT State
// 2. User-Triggered Dynamics (Energy Accumulation, Evolution)
// 3. Time-Based Energy Accumulation
// 4. State Evolution (Conditional)
// 5. Metaphorical Entanglement (Propose, Accept, Break)
// 6. Built-in Marketplace
// 7. Batch Operations (Bulk Energy Accumulation)
// 8. Configurable Parameters (Admin controlled)
//
// Inheritance: ERC721Enumerable, Ownable, Pausable
//
// Function Categories & Summary (Total > 20 Functions):
// 1. Admin & Setup (Owner-only):
//    - constructor: Initializes contract, mints genesis shards.
//    - pause: Pauses core contract functions.
//    - unpause: Unpauses contract functions.
//    - withdrawFees: Allows owner to withdraw collected fees.
//    - setEvolutionParameters: Configure energy requirements for evolution.
//    - setEntanglementFee: Set the fee required to propose entanglement.
//    - setMarketplaceFeeRate: Set the percentage fee for marketplace sales.
//    - setShardMetadataURI: Set the base URI for token metadata.
//    - setAllowedEvolutionTargets: Define which states can evolve into which other states.
//    - createGenesisShards: Mint initial shards (potentially only once).
// 2. Minting:
//    - userMintShard: Allows users to mint new shards by paying a fee.
// 3. Shard Dynamics & Evolution:
//    - accumulateEnergy: Updates a shard's energy based on elapsed time (user-callable).
//    - triggerEvolution: Attempts to evolve a shard's state if energy requirements are met (user-callable).
//    - bulkAccumulateEnergy: Calls accumulateEnergy for a list of owned shards.
// 4. Entanglement:
//    - proposeEntanglement: Initiates an entanglement proposal (requires fee).
//    - acceptEntanglement: Accepts a pending entanglement proposal.
//    - breakEntanglement: Terminates an active entanglement.
// 5. Marketplace:
//    - listShardForSale: Lists an owned shard on the marketplace.
//    - buyShard: Purchases a listed shard.
//    - cancelListing: Removes a listing.
// 6. Utility & Burning:
//    - burnShard: Allows owner to destroy a shard.
// 7. View & Query (Read-only):
//    - getShardState: Get state.
//    - getShardEnergy: Get energy.
//    - getShardLastUpdateTime: Get last update time.
//    - getEntangledShard: Get entangled shard ID.
//    - getPendingEntanglementProposal: Check proposal details.
//    - getListing: Get listing details.
//    - getAllListings: Get all listings (basic).
//    - previewEvolutionOutcome: Predict evolution outcome.
//    - checkEvolutionEligibility: Check if eligible for evolution attempt.
//    - getUserShardHoldings: Get user's token IDs. (From ERC721Enumerable)
//    - tokenURI: Get metadata URI. (Standard ERC721)
//    - supportsInterface: Check supported interfaces. (Standard ERC165)

contract QuantumQuasarMarketplace is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Definitions ---
    enum ShardState {
        Primordial,     // Initial state
        NebulaFragment, // First evolved state
        QuasarCore,     // Second evolved state
        VoidDust        // State after burning or certain events
    }

    struct ShardData {
        ShardState state;
        uint256 energy; // Accumulated 'quantum energy'
        uint256 lastUpdateTime; // Timestamp of last energy accumulation
        uint256 entangledWith; // Token ID of entangled shard (0 if none)
    }

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
    }

    struct EntanglementProposal {
        uint256 proposerShardId;
        uint256 targetShardId;
        address proposer;
        uint256 expirationTimestamp;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => ShardData) private _shardData;
    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => EntanglementProposal) private _pendingEntanglementProposals; // targetShardId => Proposal

    uint256 public energyAccumulationRate = 100; // Energy per second per shard (example rate)
    uint256 public evolutionEnergyThreshold = 100000; // Energy needed to attempt evolution
    uint256 public entanglementFee = 0.05 ether; // Fee to propose entanglement
    uint256 public marketplaceFeeRate = 200; // 2% (stored as basis points, 10000 = 100%)
    uint256 public constant ENTANGLEMENT_PROPOSAL_DURATION = 1 days; // How long a proposal is valid

    // Mapping from current state to potential next states
    mapping(ShardState => ShardState[]) public allowedEvolutionTargets;

    string private _baseTokenURI;

    // --- Events ---
    event ShardMinted(uint256 indexed tokenId, address indexed owner, ShardState initialState);
    event EnergyAccumulated(uint256 indexed tokenId, uint256 energyAdded, uint256 totalEnergy);
    event ShardEvolved(uint256 indexed tokenId, ShardState fromState, ShardState toState);
    event EntanglementProposed(uint256 indexed proposerShardId, uint256 indexed targetShardId, address indexed proposer);
    event EntanglementAccepted(uint256 indexed shard1Id, uint256 indexed shard2Id);
    event EntanglementBroken(uint256 indexed shard1Id, uint256 indexed shard2Id);
    event ShardBurned(uint256 indexed tokenId, ShardState finalState);
    event ShardListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ShardSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, uint256 feeAmount);
    event ListingCancelled(uint256 indexed tokenId);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        // Set initial evolution paths (example)
        allowedEvolutionTargets[ShardState.Primordial] = [ShardState.NebulaFragment];
        allowedEvolutionTargets[ShardState.NebulaFragment] = [ShardState.QuasarCore];
        // QuasarCore might not evolve further, or could have multiple paths
        // VoidDust is a terminal state

        // Mint some initial shards for the owner
        _tokenIdCounter.increment();
        _mint(msg.sender, _tokenIdCounter.current());
        _shardData[_tokenIdCounter.current()] = ShardData({
            state: ShardState.Primordial,
            energy: 0,
            lastUpdateTime: block.timestamp,
            entangledWith: 0
        });
        emit ShardMinted(_tokenIdCounter.current(), msg.sender, ShardState.Primordial);

         _tokenIdCounter.increment();
        _mint(msg.sender, _tokenIdCounter.current());
        _shardData[_tokenIdCounter.current()] = ShardData({
            state: ShardState.Primordial,
            energy: 0,
            lastUpdateTime: block.timestamp,
            entangledWith: 0
        });
        emit ShardMinted(_tokenIdCounter.current(), msg.sender, ShardState.Primordial);
    }

    // --- Admin Functions (Owner Only) ---

    /// @dev Pauses the contract, preventing most state-changing operations.
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract, allowing state-changing operations again.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev Allows the owner to withdraw collected marketplace fees.
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner(), balance);
    }

    /// @dev Sets the energy threshold required for a shard to attempt evolution.
    /// @param threshold The new energy threshold.
    function setEvolutionParameters(uint256 threshold, uint256 rate) public onlyOwner {
        require(threshold > 0 && rate > 0, "Threshold and rate must be positive");
        evolutionEnergyThreshold = threshold;
        energyAccumulationRate = rate;
    }

    /// @dev Sets the fee required to propose entanglement between two shards.
    /// @param fee The new entanglement fee.
    function setEntanglementFee(uint256 fee) public onlyOwner {
        entanglementFee = fee;
    }

    /// @dev Sets the marketplace fee rate (in basis points, e.g., 200 for 2%).
    /// @param rate The new fee rate in basis points (0-10000).
    function setMarketplaceFeeRate(uint256 rate) public onlyOwner {
        require(rate <= 10000, "Rate cannot exceed 100%");
        marketplaceFeeRate = rate;
    }

    /// @dev Sets the base URI for token metadata.
    /// @param uri The new base URI.
    function setShardMetadataURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    /// @dev Defines the states a specific ShardState can evolve into.
    /// @param fromState The current state.
    /// @param toStates An array of possible states it can evolve into.
    function setAllowedEvolutionTargets(ShardState fromState, ShardState[] memory toStates) public onlyOwner {
         // Simple validation: ensure states are within defined enum bounds.
         // More complex validation could check against a list of all valid states.
        allowedEvolutionTargets[fromState] = toStates;
    }

     /// @dev Mints a fixed number of initial genesis shards. Can potentially only be called once or a limited number of times.
     /// @param count The number of genesis shards to mint.
     /// @param recipient The address to mint the shards to.
    function createGenesisShards(uint256 count, address recipient) public onlyOwner {
        // Add logic here to potentially restrict calls (e.g., using a flag `genesisMinted`).
        for (uint i = 0; i < count; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _mint(recipient, newTokenId);
            _shardData[newTokenId] = ShardData({
                state: ShardState.Primordial,
                energy: 0,
                lastUpdateTime: block.timestamp,
                entangledWith: 0
            });
            emit ShardMinted(newTokenId, recipient, ShardState.Primordial);
        }
    }


    // --- Minting Functions ---

    /// @dev Allows a user to mint a new Primordial shard by paying a fee.
    function userMintShard() public payable whenNotPaused {
        require(msg.value > 0, "Mint fee is required"); // Example: require a non-zero fee

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(msg.sender, newTokenId);
        _shardData[newTokenId] = ShardData({
            state: ShardState.Primordial,
            energy: 0,
            lastUpdateTime: block.timestamp,
            entangledWith: 0
        });

        // Fee is automatically collected by the contract being payable

        emit ShardMinted(newTokenId, msg.sender, ShardState.Primordial);
    }


    // --- Shard Dynamics & Evolution ---

    /// @dev Allows the shard owner to accumulate energy based on time elapsed.
    /// @param tokenId The ID of the shard to update.
    function accumulateEnergy(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Shard does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not your shard");

        ShardData storage shard = _shardData[tokenId];
        uint256 timeElapsed = block.timestamp - shard.lastUpdateTime;

        if (timeElapsed > 0) {
            uint256 energyGained = timeElapsed * energyAccumulationRate;
             // Cap energy gain to prevent overflow issues with very large timestamps/rates
            uint256 maxEnergyGain = type(uint256).max - shard.energy;
            energyGained = energyGained > maxEnergyGain ? maxEnergyGain : energyGained;


            shard.energy += energyGained;
            shard.lastUpdateTime = block.timestamp;
            emit EnergyAccumulated(tokenId, energyGained, shard.energy);
        }
    }

    /// @dev Attempts to evolve a shard to a new state if conditions are met.
    /// Requires sufficient energy and a valid current state for evolution.
    /// @param tokenId The ID of the shard to evolve.
    function triggerEvolution(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Shard does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not your shard");
        require(_shardData[tokenId].energy >= evolutionEnergyThreshold, "Not enough energy to evolve");

        ShardData storage shard = _shardData[tokenId];
        ShardState currentState = shard.state;
        ShardState[] memory possibleNextStates = allowedEvolutionTargets[currentState];

        require(possibleNextStates.length > 0, "Shard cannot evolve from its current state");

        // Simple evolution: evolves to the first target state if multiple are defined.
        // Advanced: could add randomness, require multiple entangled shards, burn resources, etc.
        ShardState nextState = possibleNextStates[0]; // Example: deterministic evolution to the first listed target

        shard.state = nextState;
        shard.energy = 0; // Reset energy after evolution
        shard.lastUpdateTime = block.timestamp; // Reset timer

        emit ShardEvolved(tokenId, currentState, nextState);
    }

     /// @dev Allows a user to trigger accumulateEnergy for multiple owned shards in a single transaction.
     /// @param tokenIds An array of shard IDs owned by the caller.
    function bulkAccumulateEnergy(uint256[] memory tokenIds) public whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Ensure the user actually owns the token before processing
            if (_exists(tokenId) && ownerOf(tokenId) == msg.sender) {
                 accumulateEnergy(tokenId); // Calls the single accumulate function
            }
        }
    }


    // --- Entanglement Functions ---

    /// @dev Proposes entanglement between the caller's shard and another shard.
    /// Requires a fee and the target shard to be unentangled.
    /// @param proposerShardId The caller's shard ID.
    /// @param targetShardId The target shard ID.
    function proposeEntanglement(uint256 proposerShardId, uint256 targetShardId) public payable whenNotPaused {
        require(_exists(proposerShardId), "Proposer shard does not exist");
        require(_exists(targetShardId), "Target shard does not exist");
        require(ownerOf(proposerShardId) == msg.sender, "Proposer shard not owned by caller");
        require(proposerShardId != targetShardId, "Cannot entangle a shard with itself");
        require(_shardData[proposerShardId].entangledWith == 0, "Proposer shard is already entangled");
        require(_shardData[targetShardId].entangledWith == 0, "Target shard is already entangled");
        require(_pendingEntanglementProposals[targetShardId].targetShardId == 0, "Pending proposal already exists for target shard"); // No pending proposal for the target
        require(msg.value >= entanglementFee, "Insufficient entanglement fee");

        _pendingEntanglementProposals[targetShardId] = EntanglementProposal({
            proposerShardId: proposerShardId,
            targetShardId: targetShardId,
            proposer: msg.sender,
            expirationTimestamp: block.timestamp + ENTANGLEMENT_PROPOSAL_DURATION
        });

        // Fee is automatically collected

        emit EntanglementProposed(proposerShardId, targetShardId, msg.sender);
    }

    /// @dev Accepts a pending entanglement proposal for the caller's shard.
    /// @param targetShardId The caller's shard ID (the target of the proposal).
    function acceptEntanglement(uint256 targetShardId) public whenNotPaused {
        require(_exists(targetShardId), "Target shard does not exist");
        require(ownerOf(targetShardId) == msg.sender, "Target shard not owned by caller");

        EntanglementProposal storage proposal = _pendingEntanglementProposals[targetShardId];
        require(proposal.targetShardId != 0, "No pending proposal for this shard"); // proposal exists
        require(block.timestamp <= proposal.expirationTimestamp, "Entanglement proposal expired");
        require(_shardData[proposal.proposerShardId].entangledWith == 0, "Proposer shard became entangled");
        require(_shardData[targetShardId].entangledWith == 0, "Target shard became entangled");


        // Establish entanglement
        _shardData[proposal.proposerShardId].entangledWith = targetShardId;
        _shardData[targetShardId].entangledWith = proposal.proposerShardId;

        // Clear the proposal
        delete _pendingEntanglementProposals[targetShardId];

        emit EntanglementAccepted(proposal.proposerShardId, targetShardId);
    }

    /// @dev Breaks the entanglement between two shards. Can be called by the owner of either shard.
    /// @param shardId The ID of one of the entangled shards.
    function breakEntanglement(uint256 shardId) public whenNotPaused {
        require(_exists(shardId), "Shard does not exist");
        require(ownerOf(shardId) == msg.sender, "Not your shard");

        uint256 entangledWithId = _shardData[shardId].entangledWith;
        require(entangledWithId != 0, "Shard is not entangled");

        // Break the link on both sides
        _shardData[shardId].entangledWith = 0;
        _shardData[entangledWithId].entangledWith = 0;

        emit EntanglementBroken(shardId, entangledWithId);
    }


    // --- Marketplace Functions ---

    /// @dev Lists an owned shard for sale on the marketplace.
    /// @param tokenId The ID of the shard to list.
    /// @param price The price in native currency (wei) for the shard.
    function listShardForSale(uint256 tokenId, uint256 price) public whenNotPaused {
        require(_exists(tokenId), "Shard does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not your shard");
        require(_shardData[tokenId].entangledWith == 0, "Cannot list entangled shard"); // Cannot list entangled shards (example rule)
        require(price > 0, "Price must be greater than zero");
        require(_listings[tokenId].active == false, "Shard is already listed");

        // ERC721 requires approval or setApprovalForAll for the marketplace contract
        // The seller must have called `approve(address(this), tokenId)` or `setApprovalForAll(address(this), true)`
        require(isApprovedForAll(msg.sender, address(this)) || getApproved(tokenId) == address(this), "Marketplace contract not approved");

        _listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true
        });

        emit ShardListed(tokenId, msg.sender, price);
    }

    /// @dev Buys a listed shard from the marketplace.
    /// @param tokenId The ID of the shard to buy.
    function buyShard(uint256 tokenId) public payable whenNotPaused {
        Listing storage listing = _listings[tokenId];
        require(listing.active, "Shard not listed or already sold");
        require(listing.seller != msg.sender, "Cannot buy your own shard");
        require(msg.value >= listing.price, "Insufficient payment");

        uint256 feeAmount = (listing.price * marketplaceFeeRate) / 10000; // Calculate fee
        uint256 payoutAmount = listing.price - feeAmount;

        // Transfer payment to seller (minus fee)
        (bool sellerSuccess, ) = payable(listing.seller).call{value: payoutAmount}("");
        require(sellerSuccess, "Payment to seller failed");

        // Transfer the NFT to the buyer
        _transfer(listing.seller, msg.sender, tokenId);

        // Deactivate the listing
        listing.active = false;

        // Refund any overpayment
        if (msg.value > listing.price) {
             (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - listing.price}("");
             require(refundSuccess, "Refund failed"); // Important: handle refund failures or use different transfer method
        }


        emit ShardSold(tokenId, listing.seller, msg.sender, listing.price, feeAmount);
    }

    /// @dev Cancels a shard listing on the marketplace.
    /// @param tokenId The ID of the listed shard.
    function cancelListing(uint256 tokenId) public whenNotPaused {
        Listing storage listing = _listings[tokenId];
        require(listing.active, "Shard not listed");
        require(listing.seller == msg.sender, "Not your listing");

        listing.active = false;

        emit ListingCancelled(tokenId);
    }


    // --- Utility & Burning ---

    /// @dev Allows the owner of a shard to permanently destroy it.
    /// @param tokenId The ID of the shard to burn.
    function burnShard(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Shard does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not your shard");
         // Ensure the shard is not entangled before burning
        require(_shardData[tokenId].entangledWith == 0, "Cannot burn entangled shard");
         // Ensure the shard is not listed before burning
        require(_listings[tokenId].active == false, "Cannot burn listed shard");


        ShardState finalState = _shardData[tokenId].state;

        // Clean up storage related to the shard
        delete _shardData[tokenId];
        // If there was a pending entanglement proposal *from* this shard (shouldn't happen if not entangled, but safety)
        // delete _pendingEntanglementProposals[_shardData[tokenId].entangledWith]; // This is wrong logic
        // If this shard was the *target* of a pending proposal:
         if (_pendingEntanglementProposals[tokenId].targetShardId != 0) {
             delete _pendingEntanglementProposals[tokenId];
         }


        _burn(tokenId); // Use OpenZeppelin's burn function

        emit ShardBurned(tokenId, finalState);
    }

    // --- View & Query Functions (Read-only) ---

    /// @dev Gets the current state of a shard.
    /// @param tokenId The ID of the shard.
    /// @return The ShardState enum value.
    function getShardState(uint256 tokenId) public view returns (ShardState) {
         require(_exists(tokenId), "Shard does not exist");
         return _shardData[tokenId].state;
    }

    /// @dev Gets the current energy level of a shard.
    /// @param tokenId The ID of the shard.
    /// @return The energy amount.
    function getShardEnergy(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Shard does not exist");
         // Optionally calculate potential energy based on time since last update if accumulateEnergy wasn't called
         // This is a simplified view; actual energy is only updated on accumulateEnergy call.
         return _shardData[tokenId].energy;
    }

     /// @dev Gets the timestamp of the last energy update for a shard.
     /// @param tokenId The ID of the shard.
     /// @return The timestamp.
    function getShardLastUpdateTime(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Shard does not exist");
         return _shardData[tokenId].lastUpdateTime;
    }

    /// @dev Gets the ID of the shard currently entangled with the given shard.
    /// @param tokenId The ID of the shard.
    /// @return The ID of the entangled shard (0 if none).
    function getEntangledShard(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Shard does not exist");
         return _shardData[tokenId].entangledWith;
    }

    /// @dev Checks if there is a pending entanglement proposal targeting this shard.
    /// @param targetShardId The ID of the potential target shard.
    /// @return A tuple containing the proposer shard ID, proposer address, and expiration timestamp (0, address(0), 0 if no proposal).
    function getPendingEntanglementProposal(uint256 targetShardId) public view returns (uint256 proposerShardId, address proposer, uint256 expirationTimestamp) {
        EntanglementProposal storage proposal = _pendingEntanglementProposals[targetShardId];
        return (proposal.proposerShardId, proposal.proposer, proposal.expirationTimestamp);
    }


    /// @dev Gets the details of a specific marketplace listing.
    /// @param tokenId The ID of the listed shard.
    /// @return A tuple containing seller, price, and active status.
    function getListing(uint256 tokenId) public view returns (address seller, uint256 price, bool active) {
        Listing storage listing = _listings[tokenId];
        return (listing.seller, listing.price, listing.active);
    }

    /// @dev Gets details for all active marketplace listings.
    /// NOTE: This function can be gas-intensive for many listings.
    /// For production, consider pagination or a dedicated subgraph.
    /// @return An array of Listing structs for active listings.
    function getAllListings() public view returns (Listing[] memory) {
        uint256 totalListings = _tokenIdCounter.current();
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= totalListings; i++) {
            if (_listings[i].active) {
                activeCount++;
            }
        }

        Listing[] memory listings = new Listing[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= totalListings; i++) {
            if (_listings[i].active) {
                listings[currentIndex] = _listings[i];
                currentIndex++;
            }
        }
        return listings;
    }


    /// @dev Previews the potential state outcome(s) if a shard were to evolve now.
    /// This is a view function and does not change state.
    /// @param tokenId The ID of the shard to preview.
    /// @return An array of possible next ShardState enum values.
    function previewEvolutionOutcome(uint256 tokenId) public view returns (ShardState[] memory) {
         require(_exists(tokenId), "Shard does not exist");
         ShardState currentState = _shardData[tokenId].state;
         // Returns the potential targets defined by the owner, regardless of energy level for prediction.
         // Actual evolution still requires energy.
         return allowedEvolutionTargets[currentState];
    }

    /// @dev Checks if a shard currently meets the criteria to *attempt* evolution (i.e., has enough energy and is in an evolvable state).
    /// Does not guarantee successful evolution if random factors or other conditions were involved.
    /// @param tokenId The ID of the shard to check.
    /// @return True if eligible to attempt evolution, false otherwise.
    function checkEvolutionEligibility(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "Shard does not exist");
         ShardData storage shard = _shardData[tokenId];
         if (shard.energy < evolutionEnergyThreshold) {
             return false;
         }
         ShardState currentState = shard.state;
         return allowedEvolutionTargets[currentState].length > 0;
    }

     /// @dev Gets the list of token IDs owned by a specific address.
     /// This function is provided by ERC721Enumerable.
     /// @param owner The address to query.
     /// @return An array of token IDs.
    function getUserShardHoldings(address owner) public view returns (uint256[] memory) {
         return ERC721Enumerable.tokensOfOwner(owner);
    }


    // --- ERC721 Overrides ---

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         // Could add logic here to vary URI based on shard state, energy, entanglement, etc.
         // For now, it appends token ID to base URI.
         string memory base = _baseURI();
         return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
    }

     // The following functions are standard ERC721Enumerable / Pausable / Ownable implementations.
     // Listing them explicitly as required or overridden functions:
     // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool)
     // function ownerOf(uint256 tokenId) public view override returns (address)
     // function balanceOf(address owner) public view override returns (uint256)
     // function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721)
     // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721)
     // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721, IERC721)
     // function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721)
     // function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721)
     // function getApproved(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address operator)
     // function isApprovedForAll(address owner, address operator) public view virtual override(ERC721, IERC721) returns (bool)

    /// @dev Internal hook called before any token transfer.
    /// Used here to manage entanglement and marketplace listings.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the token is being transferred and it's entangled, break entanglement
        if (_shardData[tokenId].entangledWith != 0) {
             breakEntanglement(tokenId); // Break entanglement if transferred
        }

        // If the token is being transferred and it's listed, cancel the listing
        if (_listings[tokenId].active) {
             _listings[tokenId].active = false; // Deactivate listing
             emit ListingCancelled(tokenId); // Emit event manually
        }
    }

    // Add standard ERC721 view/internal functions explicitly if not fully covered by inheritance
    // from ERC721Enumerable. OpenZeppelin usually handles this.

    // List all external/public functions manually to count and confirm:
    // 1. constructor (internal, but called on deployment)
    // 2. pause (public)
    // 3. unpause (public)
    // 4. withdrawFees (public)
    // 5. setEvolutionParameters (public)
    // 6. setEntanglementFee (public)
    // 7. setMarketplaceFeeRate (public)
    // 8. setShardMetadataURI (public)
    // 9. setAllowedEvolutionTargets (public)
    // 10. createGenesisShards (public)
    // 11. userMintShard (public payable)
    // 12. accumulateEnergy (public)
    // 13. triggerEvolution (public)
    // 14. bulkAccumulateEnergy (public)
    // 15. proposeEntanglement (public payable)
    // 16. acceptEntanglement (public)
    // 17. breakEntanglement (public)
    // 18. listShardForSale (public)
    // 19. buyShard (public payable)
    // 20. cancelListing (public)
    // 21. burnShard (public)
    // 22. getShardState (public view)
    // 23. getShardEnergy (public view)
    // 24. getShardLastUpdateTime (public view)
    // 25. getEntangledShard (public view)
    // 26. getPendingEntanglementProposal (public view)
    // 27. getListing (public view)
    // 28. getAllListings (public view)
    // 29. previewEvolutionOutcome (public view)
    // 30. checkEvolutionEligibility (public view)
    // 31. getUserShardHoldings (public view, from ERC721Enumerable)
    // 32. tokenURI (public view override)
    // 33. supportsInterface (public view virtual override)
    // 34. ownerOf (public view override)
    // 35. balanceOf (public view override)
    // 36. transferFrom (public virtual override)
    // 37. safeTransferFrom (public virtual override, 2 versions) -> counting as 1 entry point
    // 38. approve (public virtual override)
    // 39. setApprovalForAll (public virtual override)
    // 40. getApproved (public view virtual override)
    // 41. isApprovedForAll (public view virtual override)

    // This confirms significantly more than 20 public/external functions.
}
```