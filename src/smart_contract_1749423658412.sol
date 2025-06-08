Okay, let's create a smart contract with an interesting, advanced concept: a "Quantum Entanglement Marketplace" where users can mint unique digital assets (called "Shards"), entangle them in pairs, trade them, and manage a scarce resource ("Catalyst") needed for operations. The core advanced concept will be the "entanglement pull" mechanism during transfers and the dynamic resource management of Catalyst.

This contract will not be a standard ERC-20 or ERC-721 implementation, although it shares some token-like features internally. Its logic for entanglement, probabilistic transfers, resource accrual, and paired listings aims to be distinct from common open-source examples.

---

**Contract Name:** QuantumEntanglementMarketplace

**Concept:** A marketplace for unique digital assets (Shards) that can be entangled in pairs. Entanglement introduces shared properties and a probabilistic "pull" effect during transfers or sales, where the entangled partner *might* also be transferred to the same recipient. Operations like Entanglement, Untanglement, and asset creation require a finite resource called Catalyst, which users can accrue over time or by staking assets.

**Outline:**

1.  **State Variables:** Mappings and variables to store Shard data (owner, properties, entangled status), Catalyst balances, listing information, staking data, global parameters, and contract ownership.
2.  **Structs:** Definitions for `Shard`, `Listing`, and `PairListing`.
3.  **Events:** To signal important state changes (Mint, Transfer, Entangle, Untangle, List, Buy, CatalystAccrued, Stake, Unstake).
4.  **Errors:** Custom error types for clearer failure reasons.
5.  **Modifiers:** Access control (owner-only, require-catalyst).
6.  **Core Logic:**
    *   Shard creation (`mintShard`)
    *   Shard transfer with entanglement check (`transferShard`, used internally by buy)
    *   Entanglement and Untanglement mechanics (`entangleShards`, `untangleShard`)
    *   Marketplace functions (`listShardForSale`, `cancelShardListing`, `buyShard`, `listEntangledPairForSale`, `cancelEntangledPairListing`, `buyEntangledPair`)
    *   Catalyst resource management (`accrueCatalyst`, `stakeForCatalystBonus`, `unstakeForCatalystBonus`)
    *   Query functions to view state.
    *   Owner functions to manage global parameters and withdraw funds.
7.  **Pseudorandomness:** Simple on-chain pseudo-randomness for the entanglement pull, with disclaimer.

**Function Summary (28 Functions):**

1.  `constructor()`: Initializes contract owner and initial parameters.
2.  `mintShard(string memory initialProperties)`: Creates a new Shard, assigns initial properties and ownership to `msg.sender`. Requires Catalyst.
3.  `getShardDetails(uint256 shardId)`: Views the detailed state of a specific Shard.
4.  `getOwnerOfShard(uint256 shardId)`: Views the owner of a specific Shard.
5.  `balanceOf(address owner)`: Counts the number of Shards owned by an address.
6.  `entangleShards(uint256 shardId1, uint256 shardId2)`: Links two distinct Shards, provided user owns both and they aren't already entangled. Requires Catalyst.
7.  `untangleShard(uint256 shardId)`: Breaks the entanglement link for a Shard and its partner. Requires user to own the Shard and costs Catalyst.
8.  `isEntangled(uint256 shardId)`: Checks if a specific Shard is currently entangled.
9.  `getEntangledPartner(uint256 shardId)`: Retrieves the ID of the Shard's entangled partner, if any.
10. `listShardForSale(uint256 shardId, uint256 price)`: Lists a single Shard for sale at a specified price. Requires ownership.
11. `cancelShardListing(uint256 shardId)`: Removes a single Shard from the marketplace listing. Requires ownership.
12. `buyShard(uint256 shardId)`: Purchases a single listed Shard. Handles payment, transfer, and triggers the probabilistic entanglement pull if the shard is entangled.
13. `getListing(uint256 shardId)`: Views the details of a single Shard listing.
14. `listEntangledPairForSale(uint256 shardId1, uint256 price)`: Lists an entangled pair for sale as a single unit. Requires ownership of both and that they are entangled. Price applies to the pair.
15. `cancelEntangledPairListing(uint256 shardId1)`: Removes an entangled pair listing. Requires ownership of one of the Shards in the pair.
16. `buyEntangledPair(uint256 pairShardId)`: Purchases a listed entangled pair. Handles payment and transfers both Shards.
17. `getPairListing(uint256 pairShardId)`: Views the details of an entangled pair listing.
18. `accrueCatalyst()`: Allows a user to calculate and claim their accrued Catalyst based on time and staked assets.
19. `getCatalystBalance(address user)`: Views the Catalyst balance for a specific address.
20. `stakeForCatalystBonus(uint256 shardId)`: Stakes a Shard to increase the user's Catalyst accrual rate. Requires ownership, Shard must not be listed or entangled.
21. `unstakeForCatalystBonus(uint256 shardId)`: Unstakes a previously staked Shard. Requires ownership.
22. `getStakingDetails(uint256 shardId)`: Views details about a staked Shard, including stake time and bonus rate.
23. `getUserStakedShards(address user)`: Returns a list of Shard IDs currently staked by a user.
24. `evolveShardProperties(uint256 shardId, string memory newProperties)`: Allows the owner of a Shard to update its properties. May cost Catalyst or have other conditions (simplified here).
25. `setEntanglementPullChance(uint256 newChanceBasisPoints)`: (Owner Only) Sets the probability (in basis points) of the entanglement pull effect during `transferShard`.
26. `setCatalystAccrualRatePerSecond(uint256 rate)`: (Owner Only) Sets the base rate at which Catalyst accrues per second per user.
27. `setStakingBonusRatePerSecondPerShard(uint256 rate)`: (Owner Only) Sets the *additional* rate at which Catalyst accrues per second per staked Shard.
28. `withdrawFunds()`: (Owner Only) Allows the contract owner to withdraw collected Ether (from sales fees, if implemented, or just accrued balance).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementMarketplace
 * @dev A marketplace for unique digital assets (Shards) with Entanglement mechanics.
 * Entangled Shards share properties and have a probabilistic transfer pull effect.
 * Operations require 'Catalyst', a time-accruing resource.
 *
 * Concept: A marketplace for unique digital assets (Shards) that can be entangled in pairs.
 * Entanglement introduces shared properties and a probabilistic "pull" effect during transfers
 * or sales, where the entangled partner *might* also be transferred to the same recipient.
 * Operations like Entanglement, Untanglement, and asset creation require a finite resource
 * called Catalyst, which users can accrue over time or by staking assets.
 * This contract is NOT a standard ERC-20 or ERC-721 implementation.
 *
 * Outline:
 * 1. State Variables: Mappings and variables for Shard data, Catalyst balances, listings, staking, parameters, ownership.
 * 2. Structs: Definitions for Shard, Listing, and PairListing.
 * 3. Events: Signaling state changes.
 * 4. Errors: Custom error types.
 * 5. Modifiers: Access control and condition checks.
 * 6. Core Logic: Minting, Transferring (with pull), Entangling/Untangling, Marketplace (single/pair listings), Catalyst management (accrual, staking), Queries, Owner functions.
 * 7. Pseudorandomness: Simple on-chain pseudo-randomness for entanglement pull.
 *
 * Function Summary (28 Functions):
 * 1. constructor()
 * 2. mintShard(string memory initialProperties)
 * 3. getShardDetails(uint256 shardId)
 * 4. getOwnerOfShard(uint256 shardId)
 * 5. balanceOf(address owner)
 * 6. entangleShards(uint256 shardId1, uint256 shardId2)
 * 7. untangleShard(uint256 shardId)
 * 8. isEntangled(uint256 shardId)
 * 9. getEntangledPartner(uint256 shardId)
 * 10. listShardForSale(uint256 shardId, uint256 price)
 * 11. cancelShardListing(uint256 shardId)
 * 12. buyShard(uint256 shardId)
 * 13. getListing(uint256 shardId)
 * 14. listEntangledPairForSale(uint256 shardId1, uint256 price)
 * 15. cancelEntangledPairListing(uint256 pairShardId)
 * 16. buyEntangledPair(uint256 pairShardId)
 * 17. getPairListing(uint256 pairShardId)
 * 18. accrueCatalyst()
 * 19. getCatalystBalance(address user)
 * 20. stakeForCatalystBonus(uint256 shardId)
 * 21. unstakeForCatalystBonus(uint256 shardId)
 * 22. getStakingDetails(uint256 shardId)
 * 23. getUserStakedShards(address user)
 * 24. evolveShardProperties(uint256 shardId, string memory newProperties)
 * 25. setEntanglementPullChance(uint256 newChanceBasisPoints)
 * 26. setCatalystAccrualRatePerSecond(uint256 rate)
 * 27. setStakingBonusRatePerSecondPerShard(uint256 rate)
 * 28. withdrawFunds()
 */
contract QuantumEntanglementMarketplace {

    address public owner;
    uint256 private _nextTokenId;

    // --- Structs ---

    struct Shard {
        uint256 id;
        address owner;
        string properties; // e.g., "color:red, energy:low"
        uint256 entangledPartnerId; // 0 if not entangled
        bool isStaked;
    }

    struct Listing {
        uint256 shardId;
        address seller;
        uint256 price; // in wei
        bool isListed;
    }

    struct PairListing {
        uint256 shardId1; // The primary ID for the pair listing
        uint256 shardId2;
        address seller;
        uint256 price; // in wei for the pair
        bool isListed;
    }

    // --- State Variables ---

    mapping(uint256 => Shard) public shards;
    mapping(address => uint256) private _shardBalances; // For balanceOf
    mapping(address => uint256) public catalystBalances;
    mapping(address => uint256) private _lastCatalystAccrualTimestamp;
    mapping(uint256 => Listing) public shardListings;
    mapping(uint256 => PairListing) public pairListings; // Key is shardId1 of the pair

    mapping(address => uint256[]) private _userShards; // Simple list, inefficient for many shards, but works for example
    mapping(address => uint256[]) private _userStakedShards; // List of staked shard IDs

    // Catalyst Parameters
    uint256 public catalystMintCost = 1 ether; // Cost in Catalyst to mint a shard
    uint256 public catalystEntangleCost = 0.5 ether; // Cost in Catalyst to entangle
    uint256 public catalystUntangleCost = 0.2 ether; // Cost in Catalyst to untangle
    uint256 public catalystAccrualRatePerSecond = 1 ether / 10000; // 1e14 wei per second base rate
    uint256 public stakingBonusRatePerSecondPerShard = 1 ether / 5000; // 2e14 wei per second per staked shard

    // Entanglement Pull Parameter (in basis points, 0-10000)
    uint256 public entanglementPullChanceBasisPoints = 3000; // 30% chance

    // --- Events ---

    event ShardMinted(uint256 shardId, address owner, string properties);
    event ShardTransfer(uint256 shardId, address from, address to);
    event ShardEntangled(uint256 shardId1, uint256 shardId2);
    event ShardUntangled(uint256 shardId1, uint256 shardId2);
    event ShardListed(uint256 shardId, address seller, uint256 price);
    event ShardCancelled(uint256 shardId);
    event ShardBought(uint256 shardId, address buyer, address seller, uint256 price);
    event PairListed(uint256 shardId1, uint256 shardId2, address seller, uint256 price);
    event PairCancelled(uint256 shardId1, uint256 shardId2);
    event PairBought(uint256 shardId1, uint256 shardId2, address buyer, address seller, uint256 price);
    event CatalystAccrued(address user, uint256 amount);
    event ShardStaked(uint256 shardId, address owner);
    event ShardUnstaked(uint256 shardId, address owner);
    event PropertiesEvolved(uint256 shardId, string newProperties);
    event EntanglementPullChanceSet(uint256 newChanceBasisPoints);
    event CatalystRateSet(uint256 baseRate, uint256 stakingBonusRate);

    // --- Errors ---

    error NotOwner();
    error NotShardOwner(uint256 shardId);
    error ShardNotFound(uint256 shardId);
    error InsufficientCatalyst(uint256 required, uint256 possessed);
    error InvalidShardPair(uint256 shardId1, uint256 shardId2);
    error ShardsAlreadyEntangled(uint256 shardId1, uint256 shardId2);
    error ShardsNotEntangled(uint256 shardId);
    error ShardNotListed(uint256 shardId);
    error PairNotListed(uint256 shardId);
    error InsufficientPayment(uint256 required, uint256 provided);
    error CannotStakeListedOrEntangledShard(uint256 shardId);
    error ShardNotStaked(uint256 shardId);
    error Unauthorized();

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier requireShardOwner(uint256 shardId) {
        if (shards[shardId].owner != msg.sender) revert NotShardOwner(shardId);
        _;
    }

    modifier requireCatalyst(uint256 amount) {
        accrueCatalystInternal(msg.sender); // Ensure Catalyst is up-to-date
        if (catalystBalances[msg.sender] < amount) {
            revert InsufficientCatalyst(amount, catalystBalances[msg.sender]);
        }
        catalystBalances[msg.sender] -= amount;
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _nextTokenId = 1; // Start Shard IDs from 1
    }

    // --- Internal Helper Functions ---

    function _transfer(address from, address to, uint256 shardId) internal {
        address currentOwner = shards[shardId].owner;
        if (currentOwner != from) revert Unauthorized(); // Should not happen if called correctly

        // Update balances
        _shardBalances[from]--;
        _shardBalances[to]++;

        // Update ownership mapping
        shards[shardId].owner = to;

        // Simple list updates (inefficient for large scale)
        _removeShardFromUserList(_userShards[from], shardId);
        _userShards[to].push(shardId);

        // Check if staked and unstake if owner changes
        if (shards[shardId].isStaked) {
            // Only unstake if the *previous* owner staked it.
            // If the recipient already owned it (e.g., transferring back), keep staked?
            // Let's simplify: transfer always unstakes.
            shards[shardId].isStaked = false;
            _removeShardFromUserList(_userStakedShards[from], shardId); // Remove from old owner's staked list
             // Don't add to new owner's staked list automatically
            emit ShardUnstaked(shardId, from); // Emit unstake event for the previous owner
        }

        emit ShardTransfer(shardId, from, to);
    }

    function _handleEntanglementPull(uint256 transferredShardId, address originalOwner, address recipient) internal {
        uint256 partnerId = shards[transferredShardId].entangledPartnerId;

        // Only proceed if entangled and the partner exists and is owned by the original owner
        if (partnerId != 0 && shards[partnerId].owner == originalOwner) {
            // Check if the partner is NOT the shard being transferred (should always be true if partnerId != 0)
            // and if the original owner actually owned BOTH shards before this transfer.
            // Also, the recipient should not be the original owner (no pull needed for self-transfers).
            if (partnerId != transferredShardId && originalOwner != recipient) {
                // --- Simple On-Chain Pseudo-Randomness ---
                // WARNING: This is NOT cryptographically secure randomness.
                // Deterministic on-chain randomness can be manipulated by miners/validators.
                // For real applications requiring secure randomness, use Chainlink VRF or similar.
                uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, originalOwner, recipient, transferredShardId, partnerId, block.number)));
                uint256 chanceThreshold = (randomNumber % 10000) + 1; // Value between 1 and 10000

                if (chanceThreshold <= entanglementPullChanceBasisPoints) {
                    // The entanglement pull occurs! Transfer the partner as well.
                    _transfer(originalOwner, recipient, partnerId);
                    // Note: This recursive _transfer call could potentially trigger another pull
                    // if the partner is also entangled (forming a chain), but our current
                    // struct only supports pairs, so a partner's partner is the original shard.
                    // The logic correctly handles this by checking `originalOwner`.
                }
            }
        }
    }

    // Helper to remove from dynamic array (inefficient for large arrays)
    function _removeShardFromUserList(uint256[] storage list, uint256 shardId) internal {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == shardId) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }

    function accrueCatalystInternal(address user) internal {
        uint256 lastTimestamp = _lastCatalystAccrualTimestamp[user];
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp > lastTimestamp) {
            uint256 timeElapsed = currentTimestamp - lastTimestamp;
            uint256 baseAccrual = timeElapsed * catalystAccrualRatePerSecond;
            uint256 stakedShardCount = _userStakedShards[user].length;
            uint256 stakingBonus = stakedShardCount * timeElapsed * stakingBonusRatePerSecondPerShard;

            catalystBalances[user] += baseAccrual + stakingBonus;
            _lastCatalystAccrualTimestamp[user] = currentTimestamp;

            if (baseAccrual + stakingBonus > 0) {
                 emit CatalystAccrued(user, baseAccrual + stakingBonus);
            }
        }
    }


    // --- Core Asset Management ---

    /**
     * @dev Creates a new Shard and assigns it to the caller. Costs Catalyst.
     * @param initialProperties String representation of the shard's initial properties.
     */
    function mintShard(string memory initialProperties) public requireCatalyst(catalystMintCost) {
        uint256 tokenId = _nextTokenId++;
        shards[tokenId] = Shard({
            id: tokenId,
            owner: msg.sender,
            properties: initialProperties,
            entangledPartnerId: 0,
            isStaked: false
        });
        _shardBalances[msg.sender]++;
        _userShards[msg.sender].push(tokenId);

        emit ShardMinted(tokenId, msg.sender, initialProperties);
    }

    /**
     * @dev Gets the detailed state of a specific Shard.
     * @param shardId The ID of the Shard to query.
     * @return Shard struct containing id, owner, properties, entangledPartnerId, isStaked.
     */
    function getShardDetails(uint256 shardId) public view returns (Shard memory) {
        if (shards[shardId].id == 0) revert ShardNotFound(shardId);
        return shards[shardId];
    }

    /**
     * @dev Gets the owner of a specific Shard.
     * @param shardId The ID of the Shard to query.
     * @return The address of the Shard's owner.
     */
    function getOwnerOfShard(uint256 shardId) public view returns (address) {
        if (shards[shardId].id == 0) revert ShardNotFound(shardId);
        return shards[shardId].owner;
    }

    /**
     * @dev Counts the number of Shards owned by an address.
     * @param owner The address to query.
     * @return The total number of Shards owned by the address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _shardBalances[owner];
    }

    // --- Entanglement Mechanics ---

    /**
     * @dev Entangles two distinct Shards. Requires the caller to own both and they must not be entangled. Costs Catalyst.
     * @param shardId1 The ID of the first Shard.
     * @param shardId2 The ID of the second Shard.
     */
    function entangleShards(uint256 shardId1, uint256 shardId2) public requireCatalyst(catalystEntangleCost) {
        if (shardId1 == shardId2) revert InvalidShardPair(shardId1, shardId2);
        if (shards[shardId1].id == 0 || shards[shardId2].id == 0) revert ShardNotFound(shards[shardId1].id == 0 ? shardId1 : shardId2);
        if (shards[shardId1].owner != msg.sender || shards[shardId2].owner != msg.sender) revert NotShardOwner(shards[shardId1].owner != msg.sender ? shardId1 : shardId2);
        if (shards[shardId1].entangledPartnerId != 0 || shards[shardId2].entangledPartnerId != 0) revert ShardsAlreadyEntangled(shardId1, shardId2);
        if (shardListings[shardId1].isListed || shardListings[shardId2].isListed) revert InvalidShardPair(shardId1, shardId2); // Cannot entangle listed shards

        shards[shardId1].entangledPartnerId = shardId2;
        shards[shardId2].entangledPartnerId = shardId1;

        // Note: Properties could be synced here or have shared logic (advanced)
        // Example: Make properties match the 'dominant' shard, or combine them.
        // For simplicity, let's just link them for now.

        emit ShardEntangled(shardId1, shardId2);
    }

    /**
     * @dev Breaks the entanglement link for a Shard and its partner. Costs Catalyst. Requires caller to own the Shard.
     * @param shardId The ID of one of the entangled Shards.
     */
    function untangleShard(uint256 shardId) public requireCatalyst(catalystUntangleCost) {
        if (shards[shardId].id == 0) revert ShardNotFound(shardId);
        if (shards[shardId].owner != msg.sender) revert NotShardOwner(shardId);
        if (shards[shardId].entangledPartnerId == 0) revert ShardsNotEntangled(shardId);

        uint256 partnerId = shards[shardId].entangledPartnerId;
        // Note: We only require the caller to own *one* of the entangled shards to untangle the pair.
        // This assumes owning one gives you control over the link. Alternative: require owning both.

        shards[shardId].entangledPartnerId = 0;
        shards[partnerId].entangledPartnerId = 0;

        // Check and remove pair listing if it exists
        if (pairListings[shardId].isListed) {
             delete pairListings[shardId];
             emit PairCancelled(shardId, partnerId);
        } else if (pairListings[partnerId].isListed) {
             delete pairListings[partnerId];
             emit PairCancelled(partnerId, shardId);
        }


        emit ShardUntangled(shardId, partnerId);
    }

    /**
     * @dev Checks if a specific Shard is currently entangled.
     * @param shardId The ID of the Shard to query.
     * @return True if the Shard is entangled, false otherwise.
     */
    function isEntangled(uint256 shardId) public view returns (bool) {
        if (shards[shardId].id == 0) return false; // Or revert ShardNotFound? Let's return false for non-existent.
        return shards[shardId].entangledPartnerId != 0;
    }

    /**
     * @dev Retrieves the ID of the Shard's entangled partner, if any.
     * @param shardId The ID of the Shard to query.
     * @return The ID of the entangled partner, or 0 if not entangled.
     */
    function getEntangledPartner(uint256 shardId) public view returns (uint256) {
        if (shards[shardId].id == 0) return 0; // Return 0 for non-existent
        return shards[shardId].entangledPartnerId;
    }

    // --- Marketplace ---

    /**
     * @dev Lists a single Shard for sale.
     * @param shardId The ID of the Shard to list.
     * @param price The price in wei.
     */
    function listShardForSale(uint256 shardId, uint256 price) public requireShardOwner(shardId) {
        if (shards[shardId].isStaked) revert CannotStakeListedOrEntangledShard(shardId); // Cannot list if staked
        if (shards[shardId].entangledPartnerId != 0) {
             // Also check if the *pair* is listed. Cannot list single if pair is listed.
             uint256 partnerId = shards[shardId].entangledPartnerId;
             if(pairListings[shardId].isListed || pairListings[partnerId].isListed) {
                 revert InvalidShardPair(shardId, partnerId); // Cannot list single shard if its pair is listed
             }
             // Note: Can list a single shard if it's entangled, but this comes with the pull risk for the buyer!
             // This is a core feature.
        }

        shardListings[shardId] = Listing({
            shardId: shardId,
            seller: msg.sender,
            price: price,
            isListed: true
        });

        emit ShardListed(shardId, msg.sender, price);
    }

    /**
     * @dev Cancels a single Shard listing.
     * @param shardId The ID of the listed Shard.
     */
    function cancelShardListing(uint256 shardId) public {
        if (!shardListings[shardId].isListed) revert ShardNotListed(shardId);
        if (shardListings[shardId].seller != msg.sender) revert Unauthorized();

        delete shardListings[shardId];
        emit ShardCancelled(shardId);
    }

    /**
     * @dev Purchases a single listed Shard. Handles payment, transfer, and potential entanglement pull.
     * @param shardId The ID of the Shard to buy.
     */
    function buyShard(uint255 shardId) public payable {
        Listing memory listing = shardListings[shardId];
        if (!listing.isListed) revert ShardNotListed(shardId);
        if (msg.value < listing.price) revert InsufficientPayment(listing.price, msg.value);
        if (listing.seller == msg.sender) revert Unauthorized(); // Cannot buy your own listing

        // Ensure the seller still owns the shard
        if (shards[shardId].owner != listing.seller) {
             // This listing is stale, maybe the shard was transferred directly?
             // Or the owner sold the entangled partner which pulled this one?
             // Remove the stale listing.
             delete shardListings[shardId];
             revert ShardNotListed(shardId); // Indicate it's no longer available
        }

        address originalOwner = listing.seller; // Store seller before transfer
        address buyer = msg.sender;
        uint256 totalPrice = listing.price;

        // --- Perform Transfer ---
        _transfer(originalOwner, buyer, shardId);

        // --- Handle Potential Entanglement Pull ---
        _handleEntanglementPull(shardId, originalOwner, buyer);

        // Remove the listing
        delete shardListings[shardId];

        // Send payment to seller
        // (Could add a fee here if desired)
        payable(originalOwner).transfer(totalPrice);

        emit ShardBought(shardId, buyer, originalOwner, totalPrice);
    }

    /**
     * @dev Views the details of a single Shard listing.
     * @param shardId The ID of the Shard.
     * @return Listing struct details (shardId, seller, price, isListed).
     */
    function getListing(uint256 shardId) public view returns (Listing memory) {
        return shardListings[shardId];
    }

    /**
     * @dev Lists an entangled pair for sale as a single unit. Price applies to both.
     * @param shardId1 The ID of one of the Shards in the entangled pair.
     * @param price The total price in wei for both Shards.
     */
    function listEntangledPairForSale(uint256 shardId1, uint256 price) public requireShardOwner(shardId1) {
        if (shards[shardId1].entangledPartnerId == 0) revert ShardsNotEntangled(shardId1);
        uint256 shardId2 = shards[shardId1].entangledPartnerId;

        // Ensure caller owns both and they are still entangled
        if (shards[shardId2].owner != msg.sender || shards[shardId2].entangledPartnerId != shardId1) {
             revert InvalidShardPair(shardId1, shardId2); // Ownership changed or entanglement broke
        }

        if (shards[shardId1].isStaked || shards[shardId2].isStaked) revert CannotStakeListedOrEntangledShard(shards[shardId1].isStaked ? shardId1 : shardId2);
        if (shardListings[shardId1].isListed || shardListings[shardId2].isListed) revert InvalidShardPair(shardId1, shardId2); // Cannot list pair if single shard is listed

        // Use shardId1 as the primary key for the pair listing
        pairListings[shardId1] = PairListing({
            shardId1: shardId1,
            shardId2: shardId2,
            seller: msg.sender,
            price: price,
            isListed: true
        });

        // Optional: Could also map shardId2 -> shardId1 in another mapping for easier lookup,
        // but using shardId1 as key is sufficient.

        emit PairListed(shardId1, shardId2, msg.sender, price);
    }

    /**
     * @dev Cancels an entangled pair listing.
     * @param pairShardId The ID of one of the Shards used as the key for the pair listing (usually shardId1).
     */
    function cancelEntangledPairListing(uint256 pairShardId) public {
        PairListing memory listing = pairListings[pairShardId];
        if (!listing.isListed) revert PairNotListed(pairShardId);
        if (listing.seller != msg.sender) revert Unauthorized();

        // Ensure the pair is still valid (owned by seller, still entangled) before deleting
        if (shards[listing.shardId1].owner != msg.sender ||
            shards[listing.shardId2].owner != msg.sender ||
            shards[listing.shardId1].entangledPartnerId != listing.shardId2 ||
            shards[listing.shardId2].entangledPartnerId != listing.shardId1)
        {
            // Pair state is invalid, listing is stale. Just delete.
        }

        delete pairListings[pairShardId];
        emit PairCancelled(listing.shardId1, listing.shardId2);
    }

    /**
     * @dev Purchases a listed entangled pair. Handles payment and transfers both Shards.
     * @param pairShardId The ID of one of the Shards used as the key for the pair listing (usually shardId1).
     */
    function buyEntangledPair(uint256 pairShardId) public payable {
        PairListing memory listing = pairListings[pairShardId];
        if (!listing.isListed) revert PairNotListed(pairShardId);
        if (msg.value < listing.price) revert InsufficientPayment(listing.price, msg.value);
        if (listing.seller == msg.sender) revert Unauthorized(); // Cannot buy your own listing

        // Ensure the seller still owns both shards and they are still entangled
        if (shards[listing.shardId1].owner != listing.seller ||
            shards[listing.shardId2].owner != listing.seller ||
            shards[listing.shardId1].entangledPartnerId != listing.shardId2 ||
            shards[listing.shard2].entangledPartnerId != listing.shardId1)
        {
            // Listing is stale
            delete pairListings[pairShardId];
            revert PairNotListed(pairShardId);
        }

        address originalOwner = listing.seller;
        address buyer = msg.sender;
        uint256 totalPrice = listing.price;

        // Transfer both shards
        _transfer(originalOwner, buyer, listing.shardId1);
        _transfer(originalOwner, buyer, listing.shardId2);

        // Remove the listing
        delete pairListings[pairShardId];

        // Send payment to seller
        payable(originalOwner).transfer(totalPrice);

        emit PairBought(listing.shardId1, listing.shardId2, buyer, originalOwner, totalPrice);

        // Note: Entanglement pull logic (_handleEntanglementPull) is *not* called here
        // because we are transferring the *entire pair* from the same owner. The pull
        // is designed for transferring *one* shard and potentially pulling its partner
        // if the partner is *also* owned by the same person just before the transfer.
    }

    /**
     * @dev Views the details of an entangled pair listing.
     * @param pairShardId The ID of one of the Shards used as the key for the pair listing (usually shardId1).
     * @return PairListing struct details (shardId1, shardId2, seller, price, isListed).
     */
    function getPairListing(uint256 pairShardId) public view returns (PairListing memory) {
         return pairListings[pairShardId];
    }


    // --- Catalyst Resource Management ---

    /**
     * @dev Allows a user to calculate and claim their accrued Catalyst.
     * Catalyst accrues based on time and staked Shards since the last accrual.
     */
    function accrueCatalyst() public {
        accrueCatalystInternal(msg.sender);
    }

    /**
     * @dev Views the Catalyst balance for a specific address.
     * Calling this also triggers internal accrual calculation first for up-to-date balance.
     * @param user The address to query.
     * @return The current Catalyst balance.
     */
    function getCatalystBalance(address user) public returns (uint256) {
        accrueCatalystInternal(user); // Update balance before returning
        return catalystBalances[user];
    }

    /**
     * @dev Stakes a Shard to increase the user's Catalyst accrual rate.
     * Shard must be owned by caller and not listed or entangled.
     * @param shardId The ID of the Shard to stake.
     */
    function stakeForCatalystBonus(uint256 shardId) public requireShardOwner(shardId) {
        if (shards[shardId].isStaked) revert ShardNotStaked(shardId); // Already staked
        if (shardListings[shardId].isListed) revert CannotStakeListedOrEntangledShard(shardId);
        if (shards[shardId].entangledPartnerId != 0) revert CannotStakeListedOrEntangledShard(shardId);

        shards[shardId].isStaked = true;
        _userStakedShards[msg.sender].push(shardId);

        // Accrue any pending catalyst before updating staking status affects future accrual
        accrueCatalystInternal(msg.sender);

        emit ShardStaked(shardId, msg.sender);
    }

    /**
     * @dev Unstakes a previously staked Shard.
     * Shard must be owned by caller and currently staked.
     * @param shardId The ID of the Shard to unstake.
     */
    function unstakeForCatalystBonus(uint256 shardId) public requireShardOwner(shardId) {
        if (shards[shardId].id == 0) revert ShardNotFound(shardId); // Check existence first
        if (!shards[shardId].isStaked) revert ShardNotStaked(shardId);

        shards[shardId].isStaked = false;
        _removeShardFromUserList(_userStakedShards[msg.sender], shardId);

        // Accrue any pending catalyst before updating staking status
        accrueCatalystInternal(msg.sender);

        emit ShardUnstaked(shardId, msg.sender);
    }

    /**
     * @dev Views details about a staked Shard.
     * @param shardId The ID of the Shard.
     * @return isStaked Whether the shard is currently staked.
     */
    function getStakingDetails(uint256 shardId) public view returns (bool isStaked) {
        if (shards[shardId].id == 0) revert ShardNotFound(shardId);
        return shards[shardId].isStaked;
    }

     /**
      * @dev Returns a list of Shard IDs currently staked by a user.
      * @param user The address to query.
      * @return An array of Shard IDs.
      */
    function getUserStakedShards(address user) public view returns (uint256[] memory) {
        return _userStakedShards[user];
    }


    // --- Other Functionality ---

    /**
     * @dev Allows the owner of a Shard to update its properties.
     * Could potentially cost Catalyst or require certain conditions (simplified here).
     * @param shardId The ID of the Shard.
     * @param newProperties The new string representation of properties.
     */
    function evolveShardProperties(uint256 shardId, string memory newProperties) public requireShardOwner(shardId) {
        if (shards[shardId].id == 0) revert ShardNotFound(shardId); // Redundant check due to modifier, but safe.
        // Could add requireCatalyst(cost) here
        shards[shardId].properties = newProperties;
        emit PropertiesEvolved(shardId, newProperties);
    }

    // --- Owner Functions ---

    /**
     * @dev (Owner Only) Sets the probability of the entanglement pull effect during `transferShard`.
     * @param newChanceBasisPoints The new chance in basis points (0-10000).
     */
    function setEntanglementPullChance(uint256 newChanceBasisPoints) public onlyOwner {
        if (newChanceBasisPoints > 10000) revert Unauthorized(); // Or specific error for invalid value
        entanglementPullChanceBasisPoints = newChanceBasisPoints;
        emit EntanglementPullChanceSet(newChanceBasisPoints);
    }

    /**
     * @dev (Owner Only) Sets the base rate at which Catalyst accrues per second per user.
     * @param rate The new rate (in Catalyst units per second).
     */
    function setCatalystAccrualRatePerSecond(uint256 rate) public onlyOwner {
        catalystAccrualRatePerSecond = rate;
        emit CatalystRateSet(catalystAccrualRatePerSecond, stakingBonusRatePerSecondPerShard);
    }

    /**
     * @dev (Owner Only) Sets the additional rate at which Catalyst accrues per second per staked Shard.
     * @param rate The new bonus rate (in Catalyst units per second per staked shard).
     */
    function setStakingBonusRatePerSecondPerShard(uint256 rate) public onlyOwner {
        stakingBonusRatePerSecondPerShard = rate;
         emit CatalystRateSet(catalystAccrualRatePerSecond, stakingBonusRatePerSecondPerShard);
    }

    /**
     * @dev (Owner Only) Allows the contract owner to withdraw collected Ether (e.g., from marketplace fees, if implemented).
     * Currently, no fees are collected, so this withdraws the raw contract balance.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner).transfer(balance);
        }
    }
}
```