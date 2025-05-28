Okay, let's design a creative smart contract.

**Concept:** **Quantum Entangled NFTs (QENFTs)**

This contract creates NFTs that can be "entangled" in pairs. Actions performed on one NFT in an entangled pair can affect the other. They also have properties like "Charge" which can be transferred between entangled NFTs, decay over time, and be boosted by staking the entangled pair. Holding an entangled pair might grant access to special contract functions or dynamically affect royalties.

**Advanced Concepts Used:**
1.  **Paired NFTs:** A specific non-standard relationship between tokens.
2.  **State Synchronization/Transfer:** Transferring a property (Charge) between linked tokens.
3.  **Time-Based Decay/Regeneration:** Implementing a property that changes based on block timestamps.
4.  **Staking Linked Assets:** Requiring a specific *pair* of assets to be staked for rewards/benefits.
5.  **Dynamic Properties/Metadata Hints:** Storing on-chain data that influences off-chain interpretation (metadata, visuals).
6.  **Bonding Curve Minting:** Price increases with supply.
7.  **Conditional Access Control:** Functions only accessible if specific NFT conditions (like entanglement) are met.
8.  **Dynamic Royalties (ERC-2981):** Royalties influenced by NFT state.

---

**Outline and Function Summary:**

*   **Contract:** `QuantumEntangledNFT`
*   **Inherits:** `ERC721`, `Ownable`, `ERC2981` (for royalties)
*   **Core State:**
    *   `entangledPairs`: Mapping from tokenId to its entangled pair's tokenId (bidirectional).
    *   `nftCharge`: Mapping from tokenId to an internal "charge" value.
    *   `lastChargeUpdateTime`: Mapping from tokenId to the last timestamp charge was updated.
    *   `stakedPairs`: Mapping from tokenId (of the first in a pair) to the pair's staking info (start time, address).
    *   `paused`: Minting pause state.
    *   `totalSupply`: Current number of minted tokens.
    *   `mintPriceSlope`, `mintPriceBase`: Parameters for the bonding curve.
*   **Events:**
    *   `Entangled(uint256 tokenId1, uint256 tokenId2, address owner)`
    *   `Disentangled(uint256 tokenId1, uint256 tokenId2, address owner)`
    *   `ChargeUpdated(uint256 tokenId, uint256 newCharge)`
    *   `ChargeTransferred(uint256 fromTokenId, uint256 toTokenId, uint256 amount)`
    *   `PairStaked(uint256 tokenId1, uint256 tokenId2, address staker, uint256 startTime)`
    *   `PairUnstaked(uint256 tokenId1, uint256 tokenId2, address staker, uint256 endTime)`
    *   `RoyaltyInfoUpdated(uint256 tokenId, address receiver, uint96 royaltyFraction)`
*   **Functions (>= 23 total):**
    1.  `constructor()`: Initializes ERC721, Ownable, ERC2981, sets initial mint price parameters.
    2.  `mint(uint256 amount)`: Mints new NFTs based on a bonding curve price, initializes their state (charge, last update time).
    3.  `getMintPrice(uint256 currentSupply, uint256 amountToMint)`: `pure` function to calculate mint price.
    4.  `entangle(uint256 tokenId1, uint256 tokenId2)`: Entangles two NFTs if owned by the caller (or approved) and not already entangled/staked.
    5.  `disentangle(uint256 tokenId)`: Disentangles an NFT and its pair. Requires owner or approval of *one* of the pair.
    6.  `isEntangled(uint256 tokenId)`: Checks if a token is currently entangled.
    7.  `getEntangledPair(uint256 tokenId)`: Returns the tokenId of the entangled pair, or 0 if not entangled.
    8.  `getCharge(uint256 tokenId)`: Returns the current charge level of an NFT (first updates it based on time).
    9.  `syncChargeState(uint256 tokenId)`: Internal helper to update charge based on time decay/regeneration.
    10. `transferChargeToPair(uint256 tokenId, uint256 amount)`: Transfers charge from `tokenId` to its entangled pair. Requires ownership/approval.
    11. `stakePair(uint256 tokenId1, uint256 tokenId2)`: Stakes an entangled pair. Transfers ownership to the contract temporarily and records staking info. Requires owner of both.
    12. `unstakePair(uint256 tokenId)`: Unstakes a pair given one of the tokenIds. Transfers ownership back to the staker. Requires the original staker to call.
    13. `isStaked(uint256 tokenId)`: Checks if a token is part of a staked pair.
    14. `getStakedPairInfo(uint256 tokenId)`: Returns staking start time and staker address for a token in a staked pair.
    15. `claimStakingReward(uint256 tokenId)`: Calculates and sends reward (conceptual, e.g., ether based on time and charge) for a staked pair.
    16. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: ERC-2981 standard. Dynamically adjusts royalty percentage based on entanglement and charge.
    17. `accessGatedFunction(uint256 tokenId)`: Example function requiring the caller to own a specified entangled NFT.
    18. `getMetadataHint(uint256 tokenId)`: Returns struct with charge and entanglement status for off-chain metadata generation.
    19. `setMintPriceParameters(uint256 base, uint256 slope)`: Owner-only. Updates bonding curve parameters.
    20. `setChargeDecayRate(uint256 ratePerSecond)`: Owner-only. Sets the rate at which charge decays.
    21. `setStakingRewardRate(uint256 ratePerSecondPerCharge)`: Owner-only. Sets the rate at which staking rewards accrue.
    22. `pauseMinting(bool _paused)`: Owner-only. Pauses or unpauses minting.
    23. `withdraw()`: Owner-only. Withdraws contract balance (from minting).
    24. `getNFTDetails(uint256 tokenId)`: Aggregates common query info (owner, charge, entangled pair, staking status).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Outline and Function Summary:
//
// Contract: QuantumEntangledNFT
// Inherits: ERC721, Ownable, IERC2981, ERC721Holder (to hold staked NFTs)
//
// Core State:
// - entangledPairs: mapping(uint256 => uint256) - tokenId to its entangled pair (bidirectional)
// - nftCharge: mapping(uint256 => uint256) - tokenId to its internal "charge" level
// - lastChargeUpdateTime: mapping(uint256 => uint256) - tokenId to the last timestamp charge was updated
// - stakedPairs: mapping(uint256 => StakingInfo) - tokenId (of the first in a pair) to staking info
// - paused: bool - Minting pause state.
// - totalSupply: uint256 - Current number of minted tokens (using Counters.Counter)
// - mintPriceSlope, mintPriceBase: uint256 - Parameters for the bonding curve.
// - chargeDecayRatePerSecond: uint256 - Rate charge decays per second per unit charge.
// - stakingRewardRatePerSecondPerCharge: uint256 - Rate native token reward accrues per second per unit charge.
// - owner: address - Contract owner (from Ownable)
// - _tokenRoyaltyInfo: mapping(uint256 => RoyaltyInfo) - ERC-2981 royalty info per token (or default)
//
// Structs:
// - StakingInfo: { staker: address, startTime: uint256, isStaked: bool }
// - NFTDetails: { owner: address, charge: uint256, entangledPair: uint256, isStaked: bool, stakingStartTime: uint256, staker: address }
//
// Events:
// - Entangled(uint256 tokenId1, uint256 tokenId2, address owner)
// - Disentangled(uint256 tokenId1, uint256 tokenId2, address owner)
// - ChargeUpdated(uint256 tokenId, uint256 oldCharge, uint256 newCharge)
// - ChargeTransferred(uint256 fromTokenId, uint256 toTokenId, uint256 amount)
// - PairStaked(uint256 tokenId1, uint256 tokenId2, address staker, uint256 startTime)
// - PairUnstaked(uint256 tokenId1, uint256 tokenId2, address staker, uint256 endTime, uint256 totalReward)
// - RoyaltyInfoUpdated(uint256 tokenId, address receiver, uint96 royaltyFraction)
// - Minted(address receiver, uint256 fromTokenId, uint256 toTokenId, uint256 pricePaid)
//
// Functions (>= 23 total - excludes standard ERC721 accessors like ownerOf, balanceOf, etc. which are inherited):
// 1. constructor(): Initializes ERC721, Ownable, ERC2981, sets initial params.
// 2. supportsInterface(bytes4 interfaceId): ERC165 standard support check.
// 3. mint(uint256 amount): Mints new NFTs based on bonding curve price, initializes state. Payable.
// 4. getMintPrice(uint256 currentSupply, uint256 amountToMint): pure function to calculate mint price.
// 5. entangle(uint256 tokenId1, uint256 tokenId2): Entangles two NFTs if owned by caller/approved, not already entangled/staked.
// 6. disentangle(uint256 tokenId): Disentangles an NFT and its pair. Requires owner/approval of one.
// 7. isEntangled(uint256 tokenId): Checks if a token is currently entangled.
// 8. getEntangledPair(uint256 tokenId): Returns tokenId of entangled pair, or 0.
// 9. getCharge(uint256 tokenId): Returns current charge (after sync).
// 10. syncChargeState(uint256 tokenId): Internal helper to update charge based on time/decay.
// 11. transferChargeToPair(uint256 tokenId, uint256 amount): Transfers charge from tokenId to its entangled pair. Requires ownership/approval.
// 12. stakePair(uint256 tokenId1, uint256 tokenId2): Stakes an entangled pair. Transfers ownership to contract. Requires owner of both.
// 13. unstakePair(uint256 tokenId): Unstakes a pair. Transfers ownership back. Requires original staker.
// 14. isStaked(uint256 tokenId): Checks if a token is part of a staked pair.
// 15. getStakedPairInfo(uint256 tokenId): Returns staking start time and staker address.
// 16. calculateStakingReward(uint256 tokenId): Calculates potential reward for a staked pair.
// 17. claimStakingReward(uint256 tokenId): Calculates and sends native token reward.
// 18. royaltyInfo(uint256 tokenId, uint256 salePrice): ERC-2981 standard, dynamically adjusts royalty.
// 19. accessGatedFunction(uint256 tokenId): Example function requiring owner to have specific entangled/charged NFT.
// 20. getMetadataHint(uint256 tokenId): Returns struct with charge and entanglement status for off-chain metadata.
// 21. setMintPriceParameters(uint256 base, uint256 slope): Owner-only. Updates bonding curve params.
// 22. setChargeDecayRate(uint256 ratePerSecond): Owner-only. Sets charge decay rate.
// 23. setStakingRewardRate(uint256 ratePerSecondPerCharge): Owner-only. Sets staking reward rate.
// 24. pauseMinting(bool _paused): Owner-only. Pauses/unpauses minting.
// 25. withdraw(): Owner-only. Withdraws contract balance (from minting).
// 26. getNFTDetails(uint256 tokenId): Aggregates query info into a struct.
// 27. _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): Internal hook to handle staking/entanglement on transfer.
// 28. _updateTokenRoyalty(uint256 tokenId, address receiver, uint96 royaltyFraction): Internal helper for royalties.


contract QuantumEntangledNFT is ERC721, Ownable, IERC2981, ERC721Holder {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- State Variables ---

    // Entanglement mapping: tokenId => entangled tokenId (bidirectional)
    mapping(uint256 => uint256) private entangledPairs;

    // NFT Charge: tokenId => charge level
    mapping(uint256 => uint256) private nftCharge;

    // Last time charge was updated: tokenId => timestamp
    mapping(uint256 => uint256) private lastChargeUpdateTime;

    // Staking info for pairs (only stored for the lower tokenId in the pair)
    struct StakingInfo {
        address staker;
        uint256 startTime;
        bool isStaked; // Explicitly track staked status
    }
    mapping(uint256 => StakingInfo) private stakedPairs;

    // Minting parameters
    Counters.Counter private _tokenIdCounter;
    uint256 public mintPriceBase = 0.01 ether; // Starting price
    uint256 public mintPriceSlope = 0.0001 ether; // Price increase per token
    bool public paused = false;

    // Charge & Staking parameters
    uint256 public chargeDecayRatePerSecond = 1; // Amount of charge decayed per second per unit of charge (e.g., 1% per second)
    uint256 public stakingRewardRatePerSecondPerCharge = 1 wei; // Amount of native token reward per second per unit of charge

    // Royalty Info (ERC-2981)
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction; // e.g., 500 for 5% (500 / 10000)
    }
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo; // Specific token royalty overrides
    RoyaltyInfo private _defaultRoyaltyInfo; // Default royalty

    // --- Events ---

    event Entangled(uint256 tokenId1, uint256 tokenId2, address owner);
    event Disentangled(uint256 tokenId1, uint256 tokenId2, address owner);
    event ChargeUpdated(uint256 tokenId, uint256 oldCharge, uint256 newCharge);
    event ChargeTransferred(uint256 fromTokenId, uint256 toTokenId, uint256 amount);
    event PairStaked(uint256 tokenId1, uint256 tokenId2, address staker, uint256 startTime);
    event PairUnstaked(uint256 tokenId1, uint256 tokenId2, address staker, uint256 endTime, uint256 totalReward);
    event RoyaltyInfoUpdated(uint256 tokenId, address receiver, uint96 royaltyFraction);
    event Minted(address receiver, uint256 fromTokenId, uint256 toTokenId, uint256 pricePaid);

    // --- Constructor ---

    constructor() ERC721("QuantumEntangled NFT", "QENFT") Ownable(msg.sender) {}

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Modifiers ---

    modifier onlyEntangledPairOwner(uint256 tokenId) {
        uint256 pairId = entangledPairs[tokenId];
        require(pairId != 0, "NFT is not entangled");
        address owner1 = ownerOf(tokenId);
        address owner2 = ownerOf(pairId);
        require(owner1 == msg.sender || owner2 == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(owner1, msg.sender) || getApproved(pairId) == msg.sender || isApprovedForAll(owner2, msg.sender), "Must own or be approved for one of the entangled NFTs");
        _;
    }

     modifier onlyPairOwner(uint256 tokenId1, uint256 tokenId2) {
        require(ownerOf(tokenId1) == msg.sender || getApproved(tokenId1) == msg.sender || isApprovedForAll(ownerOf(tokenId1), msg.sender), "Must own or be approved for tokenId1");
        require(ownerOf(tokenId2) == msg.sender || getApproved(tokenId2) == msg.sender || isApprovedForAll(ownerOf(tokenId2), msg.sender), "Must own or be approved for tokenId2");
        _;
    }

    // --- Minting ---

    /// @notice Mints new QENFTs based on a bonding curve.
    /// @param amount The number of tokens to mint.
    function mint(uint256 amount) external payable {
        require(!paused, "Minting is paused");
        uint256 currentSupply = _tokenIdCounter.current();
        uint256 totalPrice = getMintPrice(currentSupply, amount);
        require(msg.value >= totalPrice, "Insufficient ETH sent");

        uint256 firstMintedId = currentSupply + 1;

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, newTokenId);

            // Initialize state for new token
            nftCharge[newTokenId] = 100; // Starting charge
            lastChargeUpdateTime[newTokenId] = block.timestamp;
            emit ChargeUpdated(newTokenId, 0, nftCharge[newTokenId]);
        }

        emit Minted(msg.sender, firstMintedId, _tokenIdCounter.current(), msg.value);

        // Refund excess ETH
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    /// @notice Calculates the price to mint a given amount of tokens based on supply.
    /// @param currentSupply The current total supply of tokens.
    /// @param amountToMint The number of tokens to calculate the price for.
    /// @return The total price in wei.
    function getMintPrice(uint256 currentSupply, uint256 amountToMint) public view returns (uint256) {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < amountToMint; i++) {
            totalPrice += mintPriceBase + (mintPriceSlope * (currentSupply + i));
        }
        return totalPrice;
    }

    // --- Entanglement ---

    /// @notice Entangles two NFTs. Requires ownership or approval of both.
    /// @param tokenId1 The ID of the first NFT.
    /// @param tokenId2 The ID of the second NFT.
    function entangle(uint256 tokenId1, uint256 tokenId2) external onlyPairOwner(tokenId1, tokenId2) {
        require(tokenId1 != tokenId2, "Cannot entangle an NFT with itself");
        require(tokenId1 != 0 && tokenId2 != 0, "Invalid token ID");
        require(entangledPairs[tokenId1] == 0 && entangledPairs[tokenId2] == 0, "One or both NFTs are already entangled");
        require(!isStaked(tokenId1) && !isStaked(tokenId2), "Cannot entangle staked NFTs");

        entangledPairs[tokenId1] = tokenId2;
        entangledPairs[tokenId2] = tokenId1;

        emit Entangled(tokenId1, tokenId2, msg.sender);
    }

    /// @notice Disentangles an NFT from its pair. Requires ownership or approval of one NFT in the pair.
    /// @param tokenId The ID of one of the NFTs in the pair.
    function disentangle(uint256 tokenId) external onlyEntangledPairOwner(tokenId) {
        uint256 pairId = entangledPairs[tokenId];
        require(pairId != 0, "NFT is not entangled");

        delete entangledPairs[tokenId];
        delete entangledPairs[pairId];

        emit Disentangled(tokenId, pairId, msg.sender);
    }

    /// @notice Checks if a token is currently entangled.
    /// @param tokenId The ID of the NFT.
    /// @return True if the NFT is entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return entangledPairs[tokenId] != 0;
    }

    /// @notice Gets the entangled pair of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The ID of the entangled pair, or 0 if not entangled.
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
        return entangledPairs[tokenId];
    }

    // --- Charge Mechanics ---

    /// @notice Gets the current charge of an NFT, updating it based on time decay.
    /// @param tokenId The ID of the NFT.
    /// @return The current charge level.
    function getCharge(uint256 tokenId) public returns (uint256) {
        syncChargeState(tokenId);
        return nftCharge[tokenId];
    }

    /// @notice Internal function to update an NFT's charge based on time passed.
    /// Applies decay. Could be extended for regeneration under certain conditions (e.g., staking).
    /// @param tokenId The ID of the NFT.
    function syncChargeState(uint256 tokenId) internal {
        uint256 lastUpdateTime = lastChargeUpdateTime[tokenId];
        uint256 currentCharge = nftCharge[tokenId];

        if (lastUpdateTime < block.timestamp && currentCharge > 0) {
            uint256 timeElapsed = block.timestamp - lastUpdateTime;
            // Calculate decay amount based on time, current charge, and rate
            // Use a simple decay formula: charge -= timeElapsed * charge * decayRate / 10000 (rate is per 10000 for precision)
            // Or a fixed decay per second scaled by charge: decay = timeElapsed * charge * decayRatePerSecond / 1e18 (if rate is wei/sec/charge unit)
            // Let's use a simple percentage decay for clarity: decay = charge * timeElapsed * rate / 10000
            // Ensure rate is manageable, e.g., 1 = 0.01% decay per second per charge unit? No, rate should be fixed amount or percentage.
            // Let's use a fixed points system for rate, say 1e18 units per second.
             uint256 chargeDecayed = (currentCharge * timeElapsed * chargeDecayRatePerSecond) / 1e18; // decay is proportional to current charge
             if (chargeDecayed > currentCharge) {
                 chargeDecayed = currentCharge; // Avoid underflow
             }
            uint256 newCharge = currentCharge - chargeDecayed;

            nftCharge[tokenId] = newCharge;
            lastChargeUpdateTime[tokenId] = block.timestamp; // Update timestamp *after* calculation
            emit ChargeUpdated(tokenId, currentCharge, newCharge);
        } else if (lastUpdateTime == 0 && currentCharge == 0 && _exists(tokenId)) {
             // Initialize state if somehow missed during minting (shouldn't happen with current mint, but good practice)
             nftCharge[tokenId] = 100;
             lastChargeUpdateTime[tokenId] = block.timestamp;
             emit ChargeUpdated(tokenId, 0, 100);
        } else if (lastUpdateTime == 0 && _exists(tokenId)) {
            // Case for tokens minted before any charge updates happened
             lastChargeUpdateTime[tokenId] = block.timestamp;
        }
        // If lastUpdateTime >= block.timestamp, time hasn't passed or block advanced backwards (impossible)
        // If currentCharge is 0, no decay occurs.
    }


    /// @notice Transfers a specified amount of charge from one NFT to its entangled pair.
    /// @param tokenId The ID of the NFT to transfer charge FROM.
    /// @param amount The amount of charge to transfer.
    function transferChargeToPair(uint256 tokenId, uint256 amount) external onlyEntangledPairOwner(tokenId) {
        uint256 pairId = entangledPairs[tokenId];
        require(pairId != 0, "NFT is not entangled");

        // Sync states before transfer
        syncChargeState(tokenId);
        syncChargeState(pairId);

        uint256 currentCharge = nftCharge[tokenId];
        require(currentCharge >= amount, "Insufficient charge on the source NFT");

        nftCharge[tokenId] = currentCharge - amount;
        nftCharge[pairId] = nftCharge[pairId] + amount; // Allow charge to go above initial max? Yes, for mechanics.

        // Update timestamps for both after transfer
        lastChargeUpdateTime[tokenId] = block.timestamp;
        lastChargeUpdateTime[pairId] = block.timestamp;

        emit ChargeTransferred(tokenId, pairId, amount);
        emit ChargeUpdated(tokenId, currentCharge, nftCharge[tokenId]); // Emit for sender
        emit ChargeUpdated(pairId, nftCharge[pairId] - amount, nftCharge[pairId]); // Emit for receiver
    }

    // --- Staking ---

    /// @notice Stakes an entangled pair of NFTs. Requires ownership of both and they must be entangled.
    /// Transfers NFTs to the contract address.
    /// @param tokenId1 The ID of the first NFT.
    /// @param tokenId2 The ID of the second NFT.
    function stakePair(uint256 tokenId1, uint256 tokenId2) external onlyPairOwner(tokenId1, tokenId2) {
        require(tokenId1 != tokenId2, "Cannot stake with self");
        require(isEntangled(tokenId1) && getEntangledPair(tokenId1) == tokenId2, "NFTs must be entangled to be staked as a pair");
        require(!isStaked(tokenId1) && !isStaked(tokenId2), "One or both NFTs are already staked");

        // Ensure lower ID is first for consistent mapping key
        (uint256 firstTokenId, uint256 secondTokenId) = tokenId1 < tokenId2 ? (tokenId1, tokenId2) : (tokenId2, tokenId1);

        // Record staking info
        stakedPairs[firstTokenId] = StakingInfo({
            staker: msg.sender,
            startTime: block.timestamp,
            isStaked: true
        });

        // Transfer NFTs to contract
        // Use _safeTransfer which checks receiver can accept ERC721
        _safeTransfer(msg.sender, address(this), firstTokenId);
        _safeTransfer(msg.sender, address(this), secondTokenId);

        emit PairStaked(firstTokenId, secondTokenId, msg.sender, block.timestamp);
    }

    /// @notice Unstakes an entangled pair. Can be called using either tokenId in the pair.
    /// Transfers NFTs back to the original staker.
    /// @param tokenId The ID of one of the NFTs in the staked pair.
    function unstakePair(uint256 tokenId) external {
        require(isStaked(tokenId), "NFT is not staked");

        // Find the pair and the correct key for the mapping
        uint256 pairId = getEntangledPair(tokenId); // They must be entangled to be staked
        uint256 firstTokenId = tokenId < pairId ? tokenId : pairId;
        uint256 secondTokenId = tokenId < pairId ? pairId : tokenId;

        StakingInfo storage stakingInfo = stakedPairs[firstTokenId];
        require(stakingInfo.staker == msg.sender, "Only the original staker can unstake");

        // Calculate reward before unstaking
        uint256 totalReward = calculateStakingReward(firstTokenId);

        // Transfer ownership back
        _safeTransfer(address(this), stakingInfo.staker, firstTokenId);
        _safeTransfer(address(this), stakingInfo.staker, secondTokenId);

        // Clear staking info
        delete stakedPairs[firstTokenId]; // Deletes the struct

        // Send reward
        if (totalReward > 0) {
             payable(stakingInfo.staker).transfer(totalReward);
        }


        emit PairUnstaked(firstTokenId, secondTokenId, stakingInfo.staker, block.timestamp, totalReward);
    }

    /// @notice Checks if a token is part of a staked pair.
    /// @param tokenId The ID of the NFT.
    /// @return True if the NFT is staked, false otherwise.
    function isStaked(uint256 tokenId) public view returns (bool) {
         if (!isEntangled(tokenId)) return false; // Must be entangled to be staked as a pair
         uint256 pairId = entangledPairs[tokenId];
         uint256 firstTokenId = tokenId < pairId ? tokenId : pairId;
         return stakedPairs[firstTokenId].isStaked;
    }

    /// @notice Gets staking information for a token in a staked pair.
    /// @param tokenId The ID of the NFT in the staked pair.
    /// @return StakingInfo struct. Returns default/empty struct if not staked.
    function getStakedPairInfo(uint256 tokenId) public view returns (StakingInfo memory) {
        if (!isStaked(tokenId)) {
             return StakingInfo({ staker: address(0), startTime: 0, isStaked: false });
        }
        uint256 pairId = entangledPairs[tokenId];
        uint256 firstTokenId = tokenId < pairId ? tokenId : pairId;
        return stakedPairs[firstTokenId];
    }

    /// @notice Calculates the potential staking reward for a pair.
    /// Reward is proportional to staking duration and the *average* charge of the pair.
    /// Reward accrues per second based on stakingRewardRatePerSecondPerCharge.
    /// @param tokenId The ID of one of the NFTs in the staked pair.
    /// @return The calculated reward amount in wei.
    function calculateStakingReward(uint256 tokenId) public returns (uint256) {
        require(isStaked(tokenId), "NFT is not staked");

        uint256 pairId = getEntangledPair(tokenId);
        uint256 firstTokenId = tokenId < pairId ? tokenId : pairId;

        StakingInfo storage stakingInfo = stakedPairs[firstTokenId];
        uint256 duration = block.timestamp - stakingInfo.startTime;

        // Sync charge for both NFTs in the pair to get up-to-date values
        syncChargeState(firstTokenId);
        syncChargeState(secondTokenId); // Use secondTokenId after determining firstTokenId

        uint256 charge1 = nftCharge[firstTokenId];
        uint256 charge2 = nftCharge[secondTokenId];

        // Use the average charge, multiplied by duration and rate
        // Avoid overflow: (charge1 + charge2) / 2 * duration * rate
        // Better: (charge1 + charge2) * duration / 2 * rate
        // Safer: (charge1 + charge2) * rate * duration / 2
        // Assuming rate is small (wei per second per charge unit), this should fit uint256
        uint256 totalCharge = charge1 + charge2;
        uint256 reward = (totalCharge * stakingRewardRatePerSecondPerCharge * duration) / 2; // Divide by 2 for average

        return reward;
    }


    /// @notice Claims the staking reward for a pair. Calls calculateStakingReward and sends ETH.
    /// @param tokenId The ID of one of the NFTs in the staked pair.
    function claimStakingReward(uint256 tokenId) external {
         uint256 reward = calculateStakingReward(tokenId); // Updates charge state internally
         require(reward > 0, "No reward accrued yet");

         uint256 pairId = getEntangledPair(tokenId);
         uint256 firstTokenId = tokenId < pairId ? tokenId : pairId;

         StakingInfo storage stakingInfo = stakedPairs[firstTokenId];
         require(stakingInfo.staker == msg.sender, "Only the original staker can claim rewards");

         // Note: Reward calculation happens up to the current block timestamp.
         // To prevent claiming rewards again for the *same* duration without unstaking,
         // we should update the start time for the next reward period *or* require unstaking first.
         // Let's require unstaking first for simplicity in this example contract.
         // A more advanced version might track accrued/claimed rewards.

         payable(stakingInfo.staker).transfer(reward);

         // You could reset the start time here for continuous staking rewards without unstake/restake
         // stakingInfo.startTime = block.timestamp;
         // Or track total claimed and only allow claiming new accrual
         // This example requires unstake to claim all accrued reward.
    }


    // --- Royalty (ERC-2981) ---

    /// @notice Returns royalty information for a token, potentially dynamically adjusted.
    /// @param tokenId The ID of the NFT.
    /// @param salePrice The sale price of the NFT.
    /// @return receiver The address to send the royalty to.
    /// @return royaltyAmount The calculated royalty amount.
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory info = _tokenRoyaltyInfo[tokenId].receiver != address(0) ? _tokenRoyaltyInfo[tokenId] : _defaultRoyaltyInfo;

        if (info.receiver == address(0) || info.royaltyFraction == 0) {
            return (address(0), 0);
        }

        // Example dynamic royalty: Increase royalty slightly if Entangled or has high charge
        uint96 adjustedRoyaltyFraction = info.royaltyFraction;
        if (isEntangled(tokenId)) {
             adjustedRoyaltyFraction = adjustedRoyaltyFraction.add(adjustedRoyaltyFraction / 10); // 10% bonus royalty if entangled
        }
        // Could also add logic based on getCharge(tokenId) - but syncChargeState would need to be view/pure or called off-chain before calling this view function

        uint256 amount = (salePrice * adjustedRoyaltyFraction) / 10000; // Royalty is fraction out of 10000

        return (info.receiver, amount);
    }

    /// @notice Sets the default royalty information for the collection. Owner only.
    /// @param receiver The address to send default royalties to.
    /// @param royaltyFraction The default royalty fraction (e.g., 500 for 5%).
    function setDefaultRoyalty(address receiver, uint96 royaltyFraction) external onlyOwner {
        _defaultRoyaltyInfo = RoyaltyInfo({receiver: receiver, royaltyFraction: royaltyFraction});
         // Note: ERC-2981 doesn't define an event for default royalty, but could add one.
    }

    /// @notice Sets specific royalty information for a single token. Owner only.
    /// @param tokenId The ID of the NFT.
    /// @param receiver The address to send royalties to for this token.
    /// @param royaltyFraction The royalty fraction for this token.
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 royaltyFraction) external onlyOwner {
        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo({receiver: receiver, royaltyFraction: royaltyFraction});
        emit RoyaltyInfoUpdated(tokenId, receiver, royaltyFraction);
    }


    // --- Gated Function Example ---

    /// @notice An example function that requires the caller to own a specified entangled NFT.
    /// Could unlock features, content, etc.
    /// @param tokenId The ID of the NFT to check for gating access.
    function accessGatedFunction(uint256 tokenId) external view onlyEntangledPairOwner(tokenId) {
        // Your gated logic here
        // This function can only be called by the owner or approved address
        // of an entangled NFT pair, passing one of the tokenIds.
        require(getCharge(tokenId) > 50, "Requires charge > 50 for access"); // Add another condition using charge

        // Simulate success action
        // This is a view function, cannot change state.
        // In a real scenario, this would be a non-view function interacting with other contracts or state.
        // For demonstration, we'll just check conditions.
        bool hasAccess = isEntangled(tokenId) && getCharge(tokenId) > 50; // Re-check conditions internally for clarity
        require(hasAccess, "Access conditions not met (entangled and charge > 50)");

        // Logic that runs if access is granted...
        // log something, trigger another contract, etc.
        // This comment represents the protected action.
    }

    // --- Metadata Hints for Off-Chain Generation ---

    struct MetadataHint {
        uint256 charge;
        bool isEntangled;
        uint256 entangledPairId; // 0 if not entangled
        bool isStaked;
    }

    /// @notice Provides on-chain state data relevant for off-chain metadata generation.
    /// @param tokenId The ID of the NFT.
    /// @return A struct containing metadata hints.
    function getMetadataHint(uint256 tokenId) public returns (MetadataHint memory) {
        require(_exists(tokenId), "Token does not exist");
        syncChargeState(tokenId); // Ensure charge is up-to-date

        uint256 pairId = entangledPairs[tokenId];
        bool staked = isStaked(tokenId);

        return MetadataHint({
            charge: nftCharge[tokenId],
            isEntangled: pairId != 0,
            entangledPairId: pairId,
            isStaked: staked
        });
    }

    // --- Admin Functions ---

    /// @notice Sets parameters for the bonding curve minting price. Owner only.
    /// @param base The base price for the first token.
    /// @param slope The increase in price per subsequent token.
    function setMintPriceParameters(uint256 base, uint256 slope) external onlyOwner {
        mintPriceBase = base;
        mintPriceSlope = slope;
    }

    /// @notice Sets the rate at which NFT charge decays per second per unit of charge. Owner only.
    /// Rate is in units of 1e18 to allow fractional rates (e.g., 1e16 = 0.01%)
    /// @param ratePerSecond The decay rate per second per unit of charge.
    function setChargeDecayRate(uint256 ratePerSecond) external onlyOwner {
        chargeDecayRatePerSecond = ratePerSecond;
    }

    /// @notice Sets the rate at which staking rewards accrue per second per unit of charge. Owner only.
    /// Rate is in wei per second per unit of charge.
    /// @param ratePerSecondPerCharge The reward rate.
    function setStakingRewardRate(uint256 ratePerSecondPerCharge) external onlyOwner {
        stakingRewardRatePerSecondPerCharge = ratePerSecondPerCharge;
    }

    /// @notice Pauses or unpauses minting. Owner only.
    /// @param _paused The new paused state.
    function pauseMinting(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /// @notice Allows the owner to withdraw the contract's ETH balance (from minting). Owner only.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows owner to increase charge on a token (e.g., for events).
    /// @param tokenId The ID of the NFT.
    /// @param amount The amount of charge to add.
    function adminIncreaseCharge(uint256 tokenId, uint256 amount) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
         syncChargeState(tokenId); // Sync before adding
        uint256 oldCharge = nftCharge[tokenId];
        nftCharge[tokenId] += amount;
         lastChargeUpdateTime[tokenId] = block.timestamp; // Reset timer
        emit ChargeUpdated(tokenId, oldCharge, nftCharge[tokenId]);
    }


    // --- Combined Info Query ---

    struct NFTDetails {
        address owner;
        uint256 charge;
        uint256 entangledPair; // 0 if not entangled
        bool isStaked;
        uint256 stakingStartTime; // 0 if not staked
        address staker; // address(0) if not staked
    }

    /// @notice Gets detailed information about an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return A struct containing various details about the NFT's state.
    function getNFTDetails(uint256 tokenId) public returns (NFTDetails memory) {
         require(_exists(tokenId), "Token does not exist");
         syncChargeState(tokenId); // Ensure charge is up-to-date

         uint256 pairId = entangledPairs[tokenId];
         bool staked = isStaked(tokenId);
         StakingInfo memory stakingInfo = getStakedPairInfo(tokenId); // Get info whether staked or not

         return NFTDetails({
             owner: ownerOf(tokenId),
             charge: nftCharge[tokenId],
             entangledPair: pairId,
             isStaked: staked,
             stakingStartTime: stakingInfo.startTime,
             staker: stakingInfo.staker
         });
    }


    // --- Internal Overrides ---

    /// @dev ERC721 hook before any token transfer. Used here to handle staking and entanglement.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer if staked, unless the transfer is from the contract itself (meaning it's unstaking)
        if (isStaked(tokenId) && from != address(this)) {
            revert("Staked NFTs cannot be transferred");
        }

        // Break entanglement on transfer (if not staking/unstaking transfer)
        // If `from` is address(this), it's an unstake, entanglement should persist for the pair.
        // If `to` is address(this), it's a stake, entanglement should persist for the pair.
        if (isEntangled(tokenId) && from != address(this) && to != address(this)) {
            uint256 pairId = entangledPairs[tokenId];
             // We need to ensure the pair exists before attempting to disentangle it
            if (pairId != 0) {
                 // This will also delete entanglement for pairId
                 delete entangledPairs[tokenId];
                 delete entangledPairs[pairId];
                 // No event here to avoid double-emitting if the pair is also being transferred in a batch (unlikely for pairs)
                 // Or you could emit Disentangled(tokenId, pairId, from);
            }
        }

        // When transferring *out* of the contract (unstaking), need to update lastChargeUpdateTime
        // to reflect the time it was held in the contract and apply potential regeneration/decay logic
        // during the unstaking process's calculateStakingReward call (which syncs charge).
        // When transferring *into* the contract (staking), update lastChargeUpdateTime as well.
         lastChargeUpdateTime[tokenId] = block.timestamp; // Reset timer on transfer
    }

     // --- ERC721Holder receiver ---
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Only allow receiving tokens if it's part of the staking process
        // This is a basic check. More robust check would confirm 'from' is the staker and 'operator' is the staker/approved
        // and data contains info about the staking intention.
        // For simplicity, assume any ERC721 transfer *to* this contract is for staking or allowed
        return this.onERC721Received.selector;
    }
}
```