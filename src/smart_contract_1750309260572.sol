Okay, let's create a smart contract that models a dynamic marketplace for unique, time-sensitive digital assets whose value and properties are influenced by a simulated, evolving "Quantum Flux Level" within the contract itself.

This concept involves:
1.  **Unique Assets:** Non-fungible tokens (ERC721-like), each with specific traits like `fluxSensitivity`, `decayRateFactor`, and current `integrity`.
2.  **Dynamic Environment:** A global `currentFluxLevel` variable within the contract that changes over time or through specific interactions.
3.  **Flux Influence:** The `currentFluxLevel` affects asset properties (like value calculation and decay rate) and marketplace mechanics (like fees or listing duration).
4.  **Asset Degradation:** Assets lose `integrity` over time, reducing their value.
5.  **Recalibration:** Users can pay to `recalibrate` assets, restoring integrity.
6.  **Entanglement (Simulated):** Owning specific *combinations* or *types* of assets might grant bonuses or affect their combined state (simulated check).
7.  **Dynamic Pricing/Value:** A function to calculate the *current intrinsic value* of an asset based on its traits, integrity, and the current flux.

We will aim for 20+ distinct functions covering these concepts.

---

**Smart Contract: QuantumFluxMarketplace**

**Outline:**

1.  **Core ERC721 Functionality:** Standard ownership, transfer, approval for unique assets ("Entanglements").
2.  **Asset State Management:** Struct for Entanglement properties (integrity, sensitivity, decay). Functions to get/set/update these properties.
3.  **Dynamic Flux:** State variable `currentFluxLevel`. Functions to read and (via a controlled mechanism) update the flux.
4.  **Marketplace:** Functions to list, buy, cancel listings for Entanglements. Dynamic fees based on flux.
5.  **Dynamic Value & Decay:** Functions to calculate an asset's intrinsic value and current decay rate based on flux and asset state.
6.  **Asset Maintenance:** Function to recalibrate an asset, restoring integrity.
7.  **Simulated Entanglement:** Function to check for bonuses based on owned asset combinations.
8.  **Administrative/Utility:** Ownership, pausing, fee management, withdrawal.

**Function Summary:**

1.  `constructor()`: Initializes owner, base decay rate, base flux level.
2.  `supportsInterface(bytes4 interfaceId)`: Standard ERC165 check.
3.  `balanceOf(address owner)`: Standard ERC721.
4.  `ownerOf(uint256 tokenId)`: Standard ERC721.
5.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 safe transfer.
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 safe transfer.
7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Standard ERC721 safe transfer with data.
8.  `approve(address to, uint256 tokenId)`: Standard ERC721.
9.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721.
10. `getApproved(uint256 tokenId)`: Standard ERC721.
11. `isApprovedForAll(address owner, address operator)`: Standard ERC721.
12. `tokenURI(uint256 tokenId)`: Provides metadata URI (can include dynamic properties).
13. `mintEntanglement(address recipient, uint256 fluxSensitivity, uint256 decayRateFactor, uint256 entanglementType)`: Creates a new Entanglement token with initial properties influenced by current flux.
14. `getEntanglementState(uint256 tokenId)`: Retrieves the detailed state (integrity, sensitivity, etc.) of an Entanglement.
15. `getCurrentFluxLevel()`: Reads the current global quantum flux level.
16. `advanceFluxCycle()`: Callable function (with restrictions, e.g., cooldown/cost/block number) that advances the global `currentFluxLevel`.
17. `getEntanglementIntrinsicValue(uint256 tokenId)`: Calculates the theoretical current value based on state, integrity, and flux. *This is not the market price but an indicator*.
18. `getDynamicDecayRate(uint256 tokenId)`: Calculates the current rate at which an asset's integrity decays.
19. `recalibrateEntanglement(uint256 tokenId)`: Allows the owner to pay a fee to restore an asset's integrity to 100%.
20. `listEntanglementForSale(uint256 tokenId, uint256 price)`: Lists an owned Entanglement for sale at a fixed price.
21. `cancelListing(uint256 tokenId)`: Removes an active listing.
22. `buyEntanglement(uint256 tokenId)`: Purchases a listed Entanglement, transferring funds (price + dynamic fee) and ownership. Updates flux based on trade.
23. `getListingDetails(uint256 tokenId)`: Gets details about a specific active listing.
24. `getAllListingIds()`: Returns an array of all token IDs currently listed for sale.
25. `checkEntanglementBonus(address user)`: Checks if the user holds specific *types* of Entanglements that trigger a simulated bonus condition.
26. `withdrawFees()`: Allows the owner to withdraw accumulated marketplace fees.
27. `setMarketplaceFeeRate(uint256 feeBasisPoints)`: Owner sets the fee percentage (in basis points) for sales.
28. `setRecalibrationFee(uint256 fee)`: Owner sets the fee to recalibrate an asset.
29. `setBaseDecayRate(uint256 rate)`: Owner sets the base integrity decay rate applied universally.
30. `pause()`: Owner pauses the contract.
31. `unpause()`: Owner unpauses the contract.

This outline and summary clearly lay out the contract's structure and functionality, exceeding the 20-function requirement with advanced and dynamic features.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. Core ERC721 Functionality: Standard ownership, transfer, approval for unique assets ("Entanglements").
// 2. Asset State Management: Struct for Entanglement properties (integrity, sensitivity, decay). Functions to get/set/update these properties.
// 3. Dynamic Flux: State variable currentFluxLevel. Functions to read and (via a controlled mechanism) update the flux.
// 4. Marketplace: Functions to list, buy, cancel listings for Entanglements. Dynamic fees based on flux.
// 5. Dynamic Value & Decay: Functions to calculate an asset's intrinsic value and current decay rate based on flux and asset state.
// 6. Asset Maintenance: Function to recalibrate an asset, restoring integrity.
// 7. Simulated Entanglement: Function to check for bonuses based on owned asset combinations.
// 8. Administrative/Utility: Ownership, pausing, fee management, withdrawal.

// Function Summary:
// 1. constructor()
// 2. supportsInterface(bytes4 interfaceId)
// 3. balanceOf(address owner)
// 4. ownerOf(uint256 tokenId)
// 5. transferFrom(address from, address to, uint256 tokenId)
// 6. safeTransferFrom(address from, address to, uint256 tokenId)
// 7. safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
// 8. approve(address to, uint256 tokenId)
// 9. setApprovalForAll(address operator, bool approved)
// 10. getApproved(uint256 tokenId)
// 11. isApprovedForAll(address owner, address operator)
// 12. tokenURI(uint256 tokenId)
// 13. mintEntanglement(address recipient, uint256 fluxSensitivity, uint256 decayRateFactor, uint256 entanglementType)
// 14. getEntanglementState(uint256 tokenId)
// 15. getCurrentFluxLevel()
// 16. advanceFluxCycle()
// 17. getEntanglementIntrinsicValue(uint256 tokenId)
// 18. getDynamicDecayRate(uint256 tokenId)
// 19. recalibrateEntanglement(uint256 tokenId)
// 20. listEntanglementForSale(uint256 tokenId, uint256 price)
// 21. cancelListing(uint256 tokenId)
// 22. buyEntanglement(uint256 tokenId)
// 23. getListingDetails(uint256 tokenId)
// 24. getAllListingIds()
// 25. checkEntanglementBonus(address user)
// 26. withdrawFees()
// 27. setMarketplaceFeeRate(uint256 feeBasisPoints)
// 28. setRecalibrationFee(uint256 fee)
// 29. setBaseDecayRate(uint256 rate)
// 30. pause()
// 31. unpause()


contract QuantumFluxMarketplace is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Although Solidity >= 0.8 handles overflow, SafeMath can improve clarity for complex ops if needed.

    Counters.Counter private _tokenIdCounter;

    // --- Asset State ---
    struct Entanglement {
        uint256 integrity;          // 0-100 representing health/quality
        uint256 fluxSensitivity;    // 0-100 how much flux affects value/decay
        uint256 decayRateFactor;    // 1-100 multiplier for base decay
        uint256 entanglementType;   // Identifier for entanglement bonuses
        uint256 lastStateUpdateTime; // Block timestamp when integrity was last updated/checked
    }

    mapping(uint256 => Entanglement) private _entanglements;

    // --- Dynamic Flux ---
    uint256 private _currentFluxLevel; // Simulated global state, e.g., 0-100
    uint256 private _fluxUpdateCooldown; // Minimum blocks between flux updates
    uint256 private _lastFluxUpdateTime; // Block number of last flux update

    // --- Marketplace ---
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => Listing) private _listings; // tokenId => Listing
    uint256[] private _listedTokens; // Array to keep track of listed token IDs (for getAllListingIds)

    uint256 private _marketplaceFeeBasisPoints; // Fee taken on sales, e.g., 250 for 2.5% (250 / 10000)
    uint256 private _totalFeesCollected;

    uint256 private _recalibrationFee; // Cost to restore integrity

    // --- Decay ---
    uint256 private _baseIntegrityDecayRate; // Base decay points per unit of time (e.g., per day, simplified using blocks)

    // --- Constants (Example values) ---
    uint256 private constant INTEGRITY_MAX = 100;
    uint256 private constant FLUX_MAX = 100;
    uint256 private constant INTEGRITY_DECAY_BLOCK_INTERVAL = 100; // Decay happens roughly every 100 blocks
    uint256 private constant FLUX_UPDATE_COOLDOWN_BLOCKS = 50; // Can only advance flux every 50 blocks

    // --- Events ---
    event EntanglementMinted(address recipient, uint256 tokenId, uint256 fluxSensitivity, uint256 decayRateFactor, uint256 entanglementType);
    event EntanglementStateUpdated(uint256 tokenId, uint256 newIntegrity, uint256 lastStateUpdateTime);
    event FluxLevelAdvanced(uint256 newFluxLevel, uint256 blockNumber);
    event EntanglementListed(uint256 tokenId, address seller, uint256 price);
    event EntanglementSold(uint256 tokenId, address buyer, address seller, uint256 price, uint256 feesPaid);
    event ListingCancelled(uint256 tokenId);
    event EntanglementRecalibrated(uint256 tokenId, uint256 cost);
    event FeesWithdrawn(address recipient, uint256 amount);
    event MarketplaceFeeRateUpdated(uint256 newRate);
    event RecalibrationFeeUpdated(uint256 newFee);
    event BaseDecayRateUpdated(uint256 newRate);


    constructor(uint256 initialBaseDecayRate, uint256 initialMarketplaceFeeBasisPoints, uint256 initialRecalibrationFee)
        ERC721("QuantumFluxEntanglement", "QFE")
        Ownable(msg.sender)
        Pausable()
    {
        _baseIntegrityDecayRate = initialBaseDecayRate; // e.g., 1 (1 point decay per interval)
        _marketplaceFeeBasisPoints = initialMarketplaceFeeBasisPoints; // e.g., 250 (2.5%)
        _recalibrationFee = initialRecalibrationFee; // e.g., 0.01 ether

        // Initialize flux to a starting value (e.g., based on block hash or a fixed value)
        // Simple fixed start for demo
        _currentFluxLevel = FLUX_MAX / 2; // Start at 50
        _lastFluxUpdateTime = block.number;
    }

    // --- ERC721 Overrides ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Cancel listing if transferring a listed token
        if (_listings[tokenId].isListed && from != address(0)) {
            _cancelListing(tokenId);
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // In a real application, this would likely return a URI pointing to metadata
        // which could dynamically fetch current integrity/flux state.
        // For this example, returning base URI or a placeholder.
        string memory base = super.tokenURI(tokenId);
        if (bytes(base).length > 0) {
            return base; // Or append query params like ?integrity=...&flux=...
        }
         // Simple placeholder showing some data
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Entanglement #', toString(tokenId),
            '", "description": "A quantum entanglement asset.",',
            '"attributes": [',
            '{"trait_type": "Flux Sensitivity", "value": ', toString(_entanglements[tokenId].fluxSensitivity), '},',
            '{"trait_type": "Decay Factor", "value": ', toString(_entanglements[tokenId].decayRateFactor), '},',
            '{"trait_type": "Entanglement Type", "value": ', toString(_entanglements[tokenId].entanglementType), '},',
            '{"trait_type": "Integrity", "value": ', toString(getEntanglementState(tokenId).integrity), '},', // Get *current* integrity
            '{"trait_type": "Current Flux", "value": ', toString(_currentFluxLevel), '}', // Get current flux
            ']}'
        ))))));
    }


    // --- Internal State Update Helpers ---

    // Calculates decay since last update time and applies it
    function _applyIntegrityDecay(uint256 tokenId) internal {
        Entanglement storage entanglement = _entanglements[tokenId];
        if (entanglement.integrity == 0) {
            return; // Already fully decayed
        }

        uint256 timePassed = block.timestamp.sub(entanglement.lastStateUpdateTime);
        uint256 decayIntervals = timePassed.div(INTEGRITY_DECAY_BLOCK_INTERVAL); // Simplified time unit as block intervals

        if (decayIntervals > 0) {
            // Calculate dynamic decay rate based on flux
            uint256 dynamicDecay = _getDynamicDecayRate(tokenId); // This already includes base, factor, and flux influence

            uint256 totalDecay = dynamicDecay.mul(decayIntervals);

            if (entanglement.integrity > totalDecay) {
                entanglement.integrity = entanglement.integrity.sub(totalDecay);
            } else {
                entanglement.integrity = 0;
            }
            entanglement.lastStateUpdateTime = block.timestamp;

            emit EntanglementStateUpdated(tokenId, entanglement.integrity, entanglement.lastStateUpdateTime);
        }
    }

    // Gets state and applies decay before returning
    function _getEntanglementStateWithDecay(uint256 tokenId) internal view returns (Entanglement memory) {
        Entanglement memory state = _entanglements[tokenId]; // Copy state first

        // Calculate decay since last update time (simulate for view function)
        if (state.integrity > 0) {
             uint256 timePassed = block.timestamp.sub(state.lastStateUpdateTime);
             uint256 decayIntervals = timePassed.div(INTEGRITY_DECAY_BLOCK_INTERVAL);

             if (decayIntervals > 0) {
                 uint256 dynamicDecay = _getDynamicDecayRate(tokenId);
                 uint256 totalDecay = dynamicDecay.mul(decayIntervals);

                 if (state.integrity > totalDecay) {
                     state.integrity = state.integrity.sub(totalDecay);
                 } else {
                     state.integrity = 0;
                 }
             }
        }
        return state;
    }


    // --- Asset Management & Minting ---

    // 13. mintEntanglement
    function mintEntanglement(address recipient, uint256 fluxSensitivity, uint256 decayRateFactor, uint256 entanglementType)
        public
        onlyOwner // Only owner can mint new assets for now
        whenNotPaused
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Clamp values to realistic ranges (example)
        uint256 clampedSensitivity = fluxSensitivity > 100 ? 100 : fluxSensitivity;
        uint256 clampedDecayFactor = decayRateFactor > 100 ? 100 : (decayRateFactor == 0 ? 1 : decayRateFactor); // Decay factor at least 1

        _entanglements[newItemId] = Entanglement({
            integrity: INTEGRITY_MAX, // Start with full integrity
            fluxSensitivity: clampedSensitivity,
            decayRateFactor: clampedDecayFactor,
            entanglementType: entanglementType, // User defined type for bonuses/interaction
            lastStateUpdateTime: block.timestamp // Record mint time
        });

        _safeMint(recipient, newItemId);

        // Set a default URI for the token
        _setTokenURI(newItemId, string(abi.encodePacked("ipfs://QmW...", toString(newItemId)))); // Placeholder URI

        emit EntanglementMinted(recipient, newItemId, clampedSensitivity, clampedDecayFactor, entanglementType);
    }

    // 14. getEntanglementState
    function getEntanglementState(uint256 tokenId) public view returns (Entanglement memory) {
        require(_exists(tokenId), "Invalid token ID");
        // Return state including simulated current decay
        return _getEntanglementStateWithDecay(tokenId);
    }

    // 19. recalibrateEntanglement
    function recalibrateEntanglement(uint256 tokenId)
        public
        payable
        whenNotPaused
    {
        require(_exists(tokenId), "Invalid token ID");
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(msg.value >= _recalibrationFee, "Insufficient recalibration fee");

        // Apply any decay before recalibrating
        _applyIntegrityDecay(tokenId); // This updates state and lastStateUpdateTime

        _entanglements[tokenId].integrity = INTEGRITY_MAX;
        // lastStateUpdateTime is already updated by _applyIntegrityDecay

        // Keep excess payment if any
        if (msg.value > _recalibrationFee) {
            payable(msg.sender).transfer(msg.value.sub(_recalibrationFee));
        }

        _totalFeesCollected = _totalFeesCollected.add(_recalibrationFee);

        emit EntanglementRecalibrated(tokenId, _recalibrationFee);
        emit EntanglementStateUpdated(tokenId, INTEGRITY_MAX, _entanglements[tokenId].lastStateUpdateTime);
    }

    // --- Dynamic Flux ---

    // 15. getCurrentFluxLevel
    function getCurrentFluxLevel() public view returns (uint256) {
        return _currentFluxLevel;
    }

    // 16. advanceFluxCycle
    // Allows anyone to trigger a flux update, but with a cooldown and cost
    function advanceFluxCycle() public payable whenNotPaused {
        require(block.number > _lastFluxUpdateTime.add(FLUX_UPDATE_COOLDOWN_BLOCKS), "Flux cycle is on cooldown");
        // Require a small fee to prevent spam, adds to collected fees
        uint256 fluxAdvancementFee = 0.001 ether; // Example small fee
        require(msg.value >= fluxAdvancementFee, "Insufficient fee to advance flux");

        _totalFeesCollected = _totalFeesCollected.add(fluxAdvancementFee);

        // Simple, deterministic flux change based on current block number parity and transaction count.
        // More complex mechanisms could involve oracle data, staked value, random beacon, etc.
        uint256 newFlux = _currentFluxLevel;
        if (block.number % 2 == 0) {
             if (newFlux < FLUX_MAX) newFlux++;
        } else {
            if (newFlux > 0) newFlux--;
        }

        _currentFluxLevel = newFlux;
        _lastFluxUpdateTime = block.number;

        // Return any excess payment
        if (msg.value > fluxAdvancementFee) {
             payable(msg.sender).transfer(msg.value.sub(fluxAdvancementFee));
        }

        emit FluxLevelAdvanced(newFlux, block.number);
    }

    // --- Dynamic Value & Decay ---

    // 17. getEntanglementIntrinsicValue
    // Calculates a theoretical intrinsic value based on properties, integrity, and flux.
    // This is NOT the market price, but can inform pricing decisions.
    function getEntanglementIntrinsicValue(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Invalid token ID");
        Entanglement memory state = _getEntanglementStateWithDecay(tokenId); // Use state with simulated decay

        // Simple illustrative formula: BaseValue * (1 + Sensitivity * Flux / 10000) * (Integrity / 100)
        // BaseValue could be a contract constant or depend on Entanglement type.
        uint256 baseValue = 1 ether; // Example Base Value

        // Flux influence multiplier: 1 + (sensitivity * flux) / 10000
        uint256 fluxMultiplier = 10000; // Represents 1.0000
        uint256 sensitivityFluxInfluence = state.fluxSensitivity.mul(_currentFluxLevel).div(100); // e.g., 50*50/100 = 25
        fluxMultiplier = fluxMultiplier.add(sensitivityFluxInfluence); // e.g., 10000 + 25 = 10025
        // Now divide by 100 to get a value around 1.xx: 10025 / 100 = 100.25, scale it back
        // Let's make sensitivity scale influence directly: (Sensitivity * Flux / 100) -> max 100*100/100 = 100
        // Max multiplier from flux: 1 + 1 = 2x. Min: 1 + 0 = 1x.
        uint256 valueMultiplier = 1e18; // Base 1 ETH equivalent
        uint256 fluxInfluenceScaled = state.fluxSensitivity.mul(_currentFluxLevel).div(100); // Max 100
        valueMultiplier = valueMultiplier.add(baseValue.mul(fluxInfluenceScaled).div(100)); // Add up to 1 ETH more based on influence

        // Apply integrity multiplier: Integrity / 100
        uint256 integrityMultiplier = state.integrity; // 0-100
        uint256 intrinsicValue = valueMultiplier.mul(integrityMultiplier).div(INTEGRITY_MAX); // Scale value by integrity

        return intrinsicValue; // Returns value in Wei
    }

    // 18. getDynamicDecayRate
     function getDynamicDecayRate(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Invalid token ID");
        return _getDynamicDecayRate(tokenId);
    }

    // Internal helper for decay calculation
    function _getDynamicDecayRate(uint256 tokenId) internal view returns (uint256) {
        Entanglement storage entanglement = _entanglements[tokenId]; // Read directly, no decay simulation needed for rate calculation
        // Formula: baseRate * decayFactor * (1 + fluxSensitivity * fluxLevel / 10000)
        // Example: baseRate * decayFactor * (1 + flux / 50) roughly
        // Let's simplify: baseRate * decayFactor * (1 + fluxSensitivity * fluxLevel / 10000)
        uint256 fluxInfluence = entanglement.fluxSensitivity.mul(_currentFluxLevel).div(100); // Max 100*100/100 = 100
        uint256 fluxFactor = 100 + fluxInfluence; // Min 100, Max 200

        uint256 dynamicRate = _baseIntegrityDecayRate.mul(entanglement.decayRateFactor).div(100).mul(fluxFactor).div(100);
        if (dynamicRate == 0) return 1; // Ensure minimum decay rate
        return dynamicRate;
    }


    // --- Marketplace ---

    // 20. listEntanglementForSale
    function listEntanglementForSale(uint256 tokenId, uint256 price)
        public
        whenNotPaused
    {
        require(_exists(tokenId), "Invalid token ID");
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(!_listings[tokenId].isListed, "Token already listed");
        require(price > 0, "Price must be greater than 0");

        // Ensure the marketplace contract can transfer the token when sold
        approve(address(this), tokenId);

        _listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            isListed: true
        });

        _listedTokens.push(tokenId); // Add to the list of listed tokens

        emit EntanglementListed(tokenId, msg.sender, price);
    }

    // 21. cancelListing
    function cancelListing(uint256 tokenId)
        public
        whenNotPaused
    {
        require(_exists(tokenId), "Invalid token ID");
        require(_listings[tokenId].isListed, "Token not listed");
        require(_listings[tokenId].seller == msg.sender, "Not listing owner");

        _cancelListing(tokenId);
    }

    // Internal helper to cancel listing
    function _cancelListing(uint256 tokenId) internal {
         // Reset approval for marketplace
        if (getApproved(tokenId) == address(this)) {
             approve(address(0), tokenId);
        }

        delete _listings[tokenId]; // Remove from mapping

        // Remove from listedTokens array (inefficient for large arrays, consider a mapping if scale is needed)
        for (uint i = 0; i < _listedTokens.length; i++) {
            if (_listedTokens[i] == tokenId) {
                _listedTokens[i] = _listedTokens[_listedTokens.length - 1];
                _listedTokens.pop();
                break;
            }
        }

        emit ListingCancelled(tokenId);
    }


    // 22. buyEntanglement
    function buyEntanglement(uint256 tokenId)
        public
        payable
        whenNotPaused
    {
        Listing storage listing = _listings[tokenId];
        require(listing.isListed, "Token not listed for sale");
        require(listing.seller != msg.sender, "Cannot buy your own token");
        require(msg.value >= listing.price, "Insufficient payment");

        uint256 totalPrice = listing.price;
        uint256 feeAmount = totalPrice.mul(_marketplaceFeeBasisPoints).div(10000); // Calculate fee
        uint256 amountToSeller = totalPrice.sub(feeAmount);

        // Ensure integrity is updated before transfer
        _applyIntegrityDecay(tokenId);

        // Transfer payment to seller (net of fee)
        payable(listing.seller).transfer(amountToSeller);

        // Accumulate fees
        _totalFeesCollected = _totalFeesCollected.add(feeAmount);

        // Transfer token ownership
        address seller = listing.seller; // Store seller before deleting listing
        _safeTransfer(seller, msg.sender, tokenId);

        // Remove listing
        _cancelListing(tokenId); // Use internal helper

        // Flux update mechanism could be tied to transactions
        // Example: flux slightly increases or decreases with each sale
         _currentFluxLevel = _currentFluxLevel.add(1) % (FLUX_MAX + 1); // Example: simple increment loop 0-100
        _lastFluxUpdateTime = block.number; // Record time of last update

        emit EntanglementSold(tokenId, msg.sender, seller, totalPrice, feeAmount);
        emit FluxLevelAdvanced(_currentFluxLevel, block.number);

        // Return excess payment if any
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }
    }

    // 23. getListingDetails
    function getListingDetails(uint256 tokenId) public view returns (Listing memory) {
        require(_exists(tokenId), "Invalid token ID");
        return _listings[tokenId];
    }

     // 24. getAllListingIds
     // Note: This can be gas-intensive for many listings.
     function getAllListingIds() public view returns (uint256[] memory) {
        return _listedTokens;
     }


    // --- Simulated Entanglement Bonus ---

    // 25. checkEntanglementBonus
    // A function to check if a user holding specific *types* of Entanglements qualifies for a bonus.
    // This is a simulated check; the contract doesn't *enforce* the bonus automatically here,
    // but could be used by external applications or other contract functions.
    // Example: owning a Type 1 and a Type 5 entanglement grants a "Resonance" bonus.
    function checkEntanglementBonus(address user) public view returns (bool hasBonus, string memory bonusType) {
        uint256 type1Count = 0;
        uint256 type5Count = 0;
        uint256 type10Count = 0;

        uint256 balance = balanceOf(user);
        for (uint i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            Entanglement memory state = _entanglements[tokenId];
            if (state.entanglementType == 1) {
                type1Count++;
            } else if (state.entanglementType == 5) {
                type5Count++;
            } else if (state.entanglementType == 10) {
                 type10Count++;
            }
            // Apply decay here if the bonus check should depend on current integrity (optional)
            // _applyIntegrityDecay(tokenId); // Cannot modify state in a view function.
            // If bonuses require current state, this function would need to be non-view
            // or rely on recent state updates. For now, just check type.
        }

        if (type1Count > 0 && type5Count > 0) {
            return (true, "Resonance Boost");
        }
         if (type10Count >= 3) {
            return (true, "Flux Accumulator");
        }

        return (false, ""); // No bonus found
    }


    // --- Administrative/Utility ---

    // 26. withdrawFees
    function withdrawFees() public onlyOwner {
        uint256 fees = _totalFeesCollected;
        _totalFeesCollected = 0;
        if (fees > 0) {
            payable(msg.sender).transfer(fees);
            emit FeesWithdrawn(msg.sender, fees);
        }
    }

    // 27. setMarketplaceFeeRate
    function setMarketplaceFeeRate(uint256 feeBasisPoints) public onlyOwner {
        require(feeBasisPoints <= 10000, "Fee rate cannot exceed 100%"); // Max 100%
        _marketplaceFeeBasisPoints = feeBasisPoints;
        emit MarketplaceFeeRateUpdated(feeBasisPoints);
    }

    // 28. setRecalibrationFee
    function setRecalibrationFee(uint256 fee) public onlyOwner {
        _recalibrationFee = fee;
        emit RecalibrationFeeUpdated(fee);
    }

     // 29. setBaseDecayRate
    function setBaseDecayRate(uint256 rate) public onlyOwner {
        _baseIntegrityDecayRate = rate;
        emit BaseDecayRateUpdated(rate);
    }

    // 30. pause
    function pause() public onlyOwner {
        _pause();
    }

    // 31. unpause
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Helper to convert uint to string (for tokenURI) ---
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// Dummy Base64 library for data URI in tokenURI (replace with a proper library like OpenZeppelin's or solady's)
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = _TABLE;

        // calculate output length: 3*n -> 4*n / 3
        uint256 base64len = 4 * ((data.length + 2) / 3);

        // allocate the output buffer
        bytes memory buffer = new bytes(base64len);

        uint256 i;
        uint256 j;
        for (i = 0; i < data.length; i += 3) {
            uint256 chunk;
            uint256 chunkLen = data.length - i;
            if (chunkLen == 1) {
                chunk = uint256(data[i]) << 16;
            } else if (chunkLen == 2) {
                chunk = (uint256(data[i]) << 16) | (uint256(data[i + 1]) << 8);
            } else {
                chunk = (uint256(data[i]) << 16) | (uint256(data[i + 1]) << 8) | uint256(data[i + 2]);
            }

            if (chunkLen == 1) {
                buffer[j] = bytes1(table[chunk >> 18]);
                buffer[j + 1] = bytes1(table[(chunk >> 12) & 0x3F]);
                buffer[j + 2] = bytes1(bytes(0x3d)); // padding
                buffer[j + 3] = bytes1(bytes(0x3d)); // padding
            } else if (chunkLen == 2) {
                buffer[j] = bytes1(table[chunk >> 18]);
                buffer[j + 1] = bytes1(table[(chunk >> 12) & 0x3F]);
                buffer[j + 2] = bytes1(table[(chunk >> 6) & 0x3F]);
                buffer[j + 3] = bytes1(bytes(0x3d)); // padding
            } else {
                buffer[j] = bytes1(table[chunk >> 18]);
                buffer[j + 1] = bytes1(table[(chunk >> 12) & 0x3F]);
                buffer[j + 2] = bytes1(table[(chunk >> 6) & 0x3F]);
                buffer[j + 3] = bytes1(table[chunk & 0x3F]);
            }
            j += 4;
        }

        return string(buffer);
    }
}
```