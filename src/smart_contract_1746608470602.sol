Okay, here is a smart contract concept for a dynamic, interactive NFT collection called "Quantum Pixel Forge". It combines ERC721 with on-chain dynamic state, time-based mechanics, interaction-based changes, and a unique "entanglement" feature.

It avoids simple ERC721 extensions, standard yield farming, or basic fractionalization, focusing instead on a complex, stateful NFT with multiple ways to interact and influence its properties over time.

**Contract Name:** `QuantumPixelForge`

**Outline:**

1.  **Interfaces & Imports:** ERC721, Ownable.
2.  **Errors:** Custom errors for specific conditions.
3.  **Enums:** `PixelState` (e.g., Dormant, Active, Quantum).
4.  **Structs:** `Pixel` (stores dynamic attributes like color, energy, state, timestamps, entanglement info).
5.  **State Variables:** Mappings for pixel data, configurations (costs, rates, thresholds), token counter, base URI, etc.
6.  **Events:** For minting, state changes, interactions (influence, recharge), entanglement, configuration updates, withdrawals.
7.  **ERC721 Implementation:** Standard methods (`balanceOf`, `ownerOf`, `transfer`, `approve`, etc.) and `tokenURI` (linking to dynamic metadata).
8.  **Core Logic (Internal):**
    *   `_applyDecay`: Calculates and applies energy decay based on time since last interaction.
    *   `_updatePixelState`: Determines the `PixelState` based on current energy levels.
    *   `_getMutatedPixel`: Applies decay and updates state before returning pixel data for external read/interaction.
9.  **Public/External Functions (Interactions):**
    *   `mintQuantumPixel`: Allows users to mint a new pixel with random initial state.
    *   `influencePixel`: Allows users to change a pixel's properties (like color) by spending tokens/ETH, affecting its energy and state.
    *   `rechargePixel`: Allows users to increase a pixel's energy by spending tokens/ETH.
    *   `entanglePixels`: Links two pixels together. Interacting with one entangled pixel provides a slight boost to the other.
    *   `disentanglePixel`: Breaks the link between two entangled pixels.
10. **Public/External Functions (Querying):**
    *   `getPixelState`: Retrieves the *current*, time-decayed state of a pixel.
    *   `getCurrentColor`, `getCurrentEnergy`, `getCurrentState`, `getEntangledWith`: Convenience getters.
    *   `getTotalSupply`: Total minted pixels.
11. **Owner/Admin Functions:**
    *   Set various configuration parameters (mint price, interaction costs, decay rate, energy thresholds, base URI).
    *   Withdraw collected funds.
12. **Internal Hooks:**
    *   `_beforeTokenTransfer`: Ensures entangled status is handled correctly or potentially reset on transfer.

**Function Summary (Total >= 20 Functions):**

1.  `constructor()`: Initializes contract with owner and initial configs.
2.  `supportsInterface(bytes4 interfaceId)`: ERC721 standard interface support.
3.  `balanceOf(address owner)`: ERC721 standard: Gets number of NFTs owned by an address.
4.  `ownerOf(uint256 tokenId)`: ERC721 standard: Gets the owner of a token ID.
5.  `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard: Transfers token, checks receiver support.
6.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: ERC721 standard: Transfers token with data.
7.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard: Transfers token.
8.  `approve(address to, uint256 tokenId)`: ERC721 standard: Approves address to transfer token.
9.  `setApprovalForAll(address operator, bool approved)`: ERC721 standard: Sets operator approval.
10. `getApproved(uint256 tokenId)`: ERC721 standard: Gets the approved address for a token.
11. `isApprovedForAll(address owner, address operator)`: ERC721 standard: Checks operator approval status.
12. `tokenURI(uint256 tokenId)`: ERC721 standard: Returns URI for token metadata (points to dynamic source).
13. `mintQuantumPixel()`: (Payable) Mints a new Quantum Pixel NFT for the caller with initial random state.
14. `getPixelState(uint256 tokenId)`: Returns the `Pixel` struct data for a token, applying decay and state update calculation *before* returning.
15. `influencePixel(uint256 tokenId, uint256 newColor)`: (Payable) Allows owner/approved to change pixel color, costs funds, impacts energy/state. Applies decay and updates state.
16. `rechargePixel(uint256 tokenId)`: (Payable) Allows owner/approved to increase pixel energy, costs funds, impacts state. Applies decay and updates state.
17. `entanglePixels(uint256 tokenId1, uint256 tokenId2)`: (Payable) Allows owner/approved to link two pixels, costs funds, requires minimum energy/state.
18. `disentanglePixel(uint256 tokenId)`: Allows owner/approved to break a pixel's entanglement link.
19. `getCurrentColor(uint256 tokenId)`: Convenience getter for the current color (after decay/state update logic).
20. `getCurrentEnergy(uint256 tokenId)`: Convenience getter for the current energy (after decay/state update logic).
21. `getCurrentState(uint256 tokenId)`: Convenience getter for the current state (after decay/state update logic).
22. `getEntangledWith(uint256 tokenId)`: Convenience getter for the token ID a pixel is entangled with (0 if none).
23. `setBaseURI(string memory baseURI)`: Owner-only: Sets the base URI for token metadata.
24. `setMintPrice(uint256 price)`: Owner-only: Sets the cost to mint a new pixel.
25. `setInfluenceCost(uint256 cost)`: Owner-only: Sets the cost to influence a pixel.
26. `setRechargeCost(uint256 cost)`: Owner-only: Sets the cost to recharge a pixel.
27. `setEntangleCost(uint256 cost)`: Owner-only: Sets the cost to entangle two pixels.
28. `setDecayRate(uint256 rate)`: Owner-only: Sets the energy decay rate per second.
29. `setEnergyThresholds(uint256 dormant, uint256 active, uint256 quantum)`: Owner-only: Sets energy thresholds for different states.
30. `withdrawFunds()`: Owner-only: Withdraws collected ETH/tokens from the contract.
31. `_applyDecay(Pixel storage pixel)`: Internal: Calculates and applies energy decay based on time elapsed.
32. `_updatePixelState(Pixel storage pixel)`: Internal: Updates the pixel's state enum based on its current energy level.
33. `_getMutatedPixel(uint256 tokenId)`: Internal helper: Fetches pixel, applies decay/state update, returns updated data (used by getters and interaction functions).
34. `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Internal ERC721 hook: Can be used to handle entanglement state on transfer (e.g., auto-disentangle).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Contract Name: QuantumPixelForge ---
//
// This contract is a dynamic and interactive ERC721 NFT collection.
// Each NFT represents a "Quantum Pixel" with properties that decay over time
// and can be influenced or recharged by users. Pixels can also be "entangled"
// creating a unique interaction mechanic between linked NFTs.
//
// --- Outline ---
// 1. Interfaces & Imports: ERC721, Ownable.
// 2. Errors: Custom errors.
// 3. Enums: PixelState (Dormant, Active, Quantum).
// 4. Structs: Pixel (dynamic attributes).
// 5. State Variables: Mappings for pixel data, configurations, counter, URI.
// 6. Events: Minting, state changes, interactions, entanglement, config, withdrawals.
// 7. ERC721 Implementation: Standard methods + tokenURI.
// 8. Core Logic (Internal): Decay, state update, fetching mutated state.
// 9. Public/External Functions (Interactions): Mint, Influence, Recharge, Entangle, Disentangle.
// 10. Public/External Functions (Querying): Get pixel state, individual attributes, total supply.
// 11. Owner/Admin Functions: Set configs, withdraw funds.
// 12. Internal Hooks: _beforeTokenTransfer.
//
// --- Function Summary (>= 20 Functions) ---
// 1. constructor(): Initializes contract.
// 2. supportsInterface(bytes4 interfaceId): ERC721 standard.
// 3. balanceOf(address owner): ERC721 standard.
// 4. ownerOf(uint256 tokenId): ERC721 standard.
// 5. safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// 6. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): ERC721 standard.
// 7. transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// 8. approve(address to, uint256 tokenId): ERC721 standard.
// 9. setApprovalForAll(address operator, bool approved): ERC721 standard.
// 10. getApproved(uint256 tokenId): ERC721 standard.
// 11. isApprovedForAll(address owner, address operator): ERC721 standard.
// 12. tokenURI(uint256 tokenId): ERC721 standard, dynamic metadata URI.
// 13. mintQuantumPixel(): Payable, mints a new Pixel.
// 14. getPixelState(uint256 tokenId): Returns dynamic pixel state, applies decay/update.
// 15. influencePixel(uint256 tokenId, uint256 newColor): Payable, changes color, affects energy/state.
// 16. rechargePixel(uint256 tokenId): Payable, increases energy, affects state.
// 17. entanglePixels(uint256 tokenId1, uint256 tokenId2): Payable, links two pixels.
// 18. disentanglePixel(uint256 tokenId): Breaks entanglement link.
// 19. getCurrentColor(uint256 tokenId): Getter for current color (after logic).
// 20. getCurrentEnergy(uint256 tokenId): Getter for current energy (after logic).
// 21. getCurrentState(uint256 tokenId): Getter for current state (after logic).
// 22. getEntangledWith(uint256 tokenId): Getter for entangled partner ID.
// 23. setBaseURI(string memory _baseURI): Owner-only, sets metadata base URI.
// 24. setMintPrice(uint256 price): Owner-only, sets mint cost.
// 25. setInfluenceCost(uint256 cost): Owner-only, sets influence cost.
// 26. setRechargeCost(uint256 cost): Owner-only, sets recharge cost.
// 27. setEntangleCost(uint256 cost): Owner-only, sets entangle cost.
// 28. setDecayRate(uint256 ratePerSecond): Owner-only, sets energy decay rate.
// 29. setEnergyThresholds(uint256 dormant, uint256 active, uint256 quantum): Owner-only, sets state thresholds.
// 30. withdrawFunds(): Owner-only, withdraws contract balance.
// 31. _applyDecay(Pixel storage pixel): Internal, calculates and applies energy decay.
// 32. _updatePixelState(Pixel storage pixel): Internal, updates state based on energy.
// 33. _getMutatedPixel(uint256 tokenId): Internal helper, applies decay/update and returns state.
// 34. _beforeTokenTransfer(address from, address to, uint256 tokenId): Internal hook for transfer logic (e.g., disentanglement).

// --- Source Code ---

error InvalidTokenId(uint256 tokenId);
error NotPixelOwnerOrApproved(uint256 tokenId);
error InsufficientPayment(uint256 required);
error CannotEntangleSamePixel(uint256 tokenId);
error PixelsAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
error PixelsNotEntangled(uint256 tokenId);
error InsufficientEnergyForEntanglement(uint256 tokenId, uint256 required);

enum PixelState {
    Dormant, // Low energy
    Active,  // Sufficient energy for basic interaction
    Quantum  // High energy or entangled state
}

struct Pixel {
    uint256 color;             // Represents the visual color (e.g., hex integer)
    uint256 energy;            // Represents vitality, decays over time
    uint64 lastInteractionTime; // Timestamp of the last interaction
    PixelState state;          // Current state based on energy
    uint256 entangledWith;     // Token ID of the entangled pixel (0 if none)
}

contract QuantumPixelForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Pixel) private _pixels;

    // Configuration Parameters
    uint256 public mintPrice = 0.01 ether;
    uint256 public influenceCost = 0.005 ether;
    uint256 public rechargeCost = 0.003 ether;
    uint256 public entangleCost = 0.008 ether;
    uint256 public decayRatePerSecond = 10; // Units of energy lost per second
    uint256 public entanglementBonusEnergy = 500; // Energy bonus when entangled partner is influenced/recharged

    // Energy thresholds for states
    uint256 public dormantEnergyThreshold = 1000;
    uint256 public activeEnergyThreshold = 5000;
    uint256 public quantumEnergyThreshold = 10000; // Or linked to entanglement

    // Base URI for dynamic metadata service
    string private _baseTokenURI;

    // --- Constructor ---
    constructor() ERC721("QuantumPixelForge", "QPF") Ownable(msg.sender) {
        // Initial configuration can be set here or via owner functions later
    }

    // --- ERC721 Standard Implementations ---

    // 2. supportsInterface - Standard ERC721 implementation
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 3. balanceOf
    // 4. ownerOf
    // 5. safeTransferFrom (address,address,uint256)
    // 6. safeTransferFrom (address,address,uint256,bytes)
    // 7. transferFrom
    // 8. approve
    // 9. setApprovalForAll
    // 10. getApproved
    // 11. isApprovedForAll
    // (All handled by ERC721 inheritance)

    // 12. tokenURI - Points to an external service for dynamic metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Metadata__URI_queryForNonexistentToken();
        }
        // Assumes an off-chain service at baseURI that can fetch the dynamic
        // state using the tokenId and return the appropriate JSON metadata.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // --- Core Logic (Internal Helpers) ---

    // 31. _applyDecay - Calculates and applies energy decay
    function _applyDecay(Pixel storage pixel) internal view {
        uint64 timeElapsed = uint64(block.timestamp) - pixel.lastInteractionTime;
        uint256 energyLoss = uint256(timeElapsed) * decayRatePerSecond;
        if (pixel.energy > energyLoss) {
            pixel.energy -= energyLoss;
        } else {
            pixel.energy = 0;
        }
        // Note: We don't update lastInteractionTime here, only during actual interactions.
        // This ensures decay is calculated from the LAST time a user touched it.
    }

    // 32. _updatePixelState - Determines the pixel's state based on energy
    function _updatePixelState(Pixel storage pixel) internal {
        if (pixel.energy >= quantumEnergyThreshold || pixel.entangledWith != 0) {
             // A pixel can be Quantum if it has very high energy OR if it's entangled
            pixel.state = PixelState.Quantum;
        } else if (pixel.energy >= activeEnergyThreshold) {
            pixel.state = PixelState.Active;
        } else {
            pixel.state = PixelState.Dormant;
        }
    }

     // 33. _getMutatedPixel - Fetches pixel, applies decay, updates state, and returns it
    function _getMutatedPixel(uint256 tokenId) internal view returns (Pixel memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        Pixel storage pixel = _pixels[tokenId];
        
        // Create a temporary mutable copy to calculate current state without saving
        Pixel memory currentPixelState = pixel;

        _applyDecay(currentPixelState); // Apply decay calculation
        _updatePixelState(currentPixelState); // Update state based on *current* energy

        return currentPixelState;
    }


    // --- Public/External Functions (Interactions) ---

    // 13. mintQuantumPixel - Allows anyone to mint a new pixel
    function mintQuantumPixel() public payable {
        if (msg.value < mintPrice) {
            revert InsufficientPayment(mintPrice);
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Generate initial random-ish state (limited entropy on-chain)
        uint256 initialColor = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId, block.difficulty))) % (2**24); // Simulate RGB color
        uint256 initialEnergy = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, newTokenId, block.gaslimit))) % 2000 + 500; // Initial energy 500-2500

        _pixels[newTokenId] = Pixel({
            color: initialColor,
            energy: initialEnergy,
            lastInteractionTime: uint64(block.timestamp),
            state: PixelState.Dormant, // Will be updated by _updatePixelState logic on interaction/query
            entangledWith: 0 // Not entangled initially
        });

        // Apply decay and update state immediately after creation for accuracy
        _applyDecay(_pixels[newTokenId]);
        _updatePixelState(_pixels[newTokenId]);


        _safeMint(msg.sender, newTokenId);

        emit Mint(newTokenId, msg.sender, initialColor, initialEnergy, _pixels[newTokenId].state);
    }

    // 15. influencePixel - Changes pixel color, costs funds, adds energy
    function influencePixel(uint256 tokenId, uint256 newColor) public payable {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotPixelOwnerOrApproved(tokenId);
        }
        if (msg.value < influenceCost) {
            revert InsufficientPayment(influenceCost);
        }

        Pixel storage pixel = _pixels[tokenId];
        PixelState oldState = pixel.state;

        _applyDecay(pixel); // Apply decay before interaction
        pixel.color = newColor;
        pixel.energy += 2000; // Add energy on influence (example value)
        pixel.lastInteractionTime = uint64(block.timestamp);
        _updatePixelState(pixel); // Update state after interaction

        // Entanglement bonus: If entangled, give partner a small energy boost
        if (pixel.entangledWith != 0) {
             if (_exists(pixel.entangledWith)) { // Check if entangled partner still exists
                 Pixel storage entangledPixel = _pixels[pixel.entangledWith];
                 PixelState oldEntangledState = entangledPixel.state;
                 _applyDecay(entangledPixel); // Apply decay to partner too
                 entangledPixel.energy += entanglementBonusEnergy;
                 entangledPixel.lastInteractionTime = uint64(block.timestamp); // Partner also gets interaction time update
                 _updatePixelState(entangledPixel);
                 if (oldEntangledState != entangledPixel.state) {
                    emit StateChanged(pixel.entangledWith, entangledPixel.state);
                 }
             } else {
                 // Auto-disentangle if partner is gone (burned or transferred out-of-protocol)
                 pixel.entangledWith = 0;
                 _updatePixelState(pixel); // Re-evaluate state based on no entanglement
                 emit Disentanglement(tokenId, 0);
             }
        }


        emit Influenced(tokenId, msg.sender, newColor, pixel.energy);
        if (oldState != pixel.state) {
            emit StateChanged(tokenId, pixel.state);
        }
    }

    // 16. rechargePixel - Increases pixel energy, costs funds
    function rechargePixel(uint256 tokenId) public payable {
        address owner = ownerOf(tokenId);
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotPixelOwnerOrApproved(tokenId);
        }
        if (msg.value < rechargeCost) {
            revert InsufficientPayment(rechargeCost);
        }

        Pixel storage pixel = _pixels[tokenId];
        PixelState oldState = pixel.state;

        _applyDecay(pixel); // Apply decay before interaction
        pixel.energy += 5000; // Add more energy on recharge (example value)
        pixel.lastInteractionTime = uint64(block.timestamp);
        _updatePixelState(pixel); // Update state after interaction

         // Entanglement bonus: If entangled, give partner a small energy boost
        if (pixel.entangledWith != 0) {
             if (_exists(pixel.entangledWith)) { // Check if entangled partner still exists
                 Pixel storage entangledPixel = _pixels[pixel.entangledWith];
                 PixelState oldEntangledState = entangledPixel.state;
                 _applyDecay(entangledPixel); // Apply decay to partner too
                 entangledPixel.energy += entanglementBonusEnergy;
                 entangledPixel.lastInteractionTime = uint64(block.timestamp); // Partner also gets interaction time update
                 _updatePixelState(entangledPixel);
                  if (oldEntangledState != entangledPixel.state) {
                    emit StateChanged(pixel.entangledWith, entangledPixel.state);
                 }
             } else {
                 // Auto-disentangle if partner is gone
                 pixel.entangledWith = 0;
                 _updatePixelState(pixel);
                 emit Disentanglement(tokenId, 0);
             }
        }

        emit Recharged(tokenId, msg.sender, pixel.energy);
         if (oldState != pixel.state) {
            emit StateChanged(tokenId, pixel.state);
        }
    }

    // 17. entanglePixels - Links two pixels together
    function entanglePixels(uint256 tokenId1, uint256 tokenId2) public payable {
        if (tokenId1 == tokenId2) {
            revert CannotEntangleSamePixel(tokenId1);
        }

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Require caller is owner or approved for *both* tokens
         if (msg.sender != owner1 && !isApprovedForAll(owner1, msg.sender) && getApproved(tokenId1) != msg.sender) {
            revert NotPixelOwnerOrApproved(tokenId1);
        }
         if (msg.sender != owner2 && !isApprovedForAll(owner2, msg.sender) && getApproved(tokenId2) != msg.sender) {
            revert NotPixelOwnerOrApproved(tokenId2);
        }

        if (msg.value < entangleCost) {
             revert InsufficientPayment(entangleCost);
        }

        Pixel storage pixel1 = _pixels[tokenId1];
        Pixel storage pixel2 = _pixels[tokenId2];

        if (pixel1.entangledWith != 0 || pixel2.entangledWith != 0) {
            revert PixelsAlreadyEntangled(tokenId1, tokenId2);
        }

        // Require sufficient energy (example logic)
        _applyDecay(pixel1);
        _applyDecay(pixel2);

        if (pixel1.energy < activeEnergyThreshold || pixel2.energy < activeEnergyThreshold) {
             revert InsufficientEnergyForEntanglement(tokenId1, activeEnergyThreshold); // Use active threshold as example minimum
        }

        PixelState oldState1 = pixel1.state;
        PixelState oldState2 = pixel2.state;

        pixel1.entangledWith = tokenId2;
        pixel2.entangledWith = tokenId1;

        // Entanglement counts as an interaction for both
        pixel1.lastInteractionTime = uint64(block.timestamp);
        pixel2.lastInteractionTime = uint64(block.timestamp);

        _updatePixelState(pixel1);
        _updatePixelState(pixel2);

        emit Entanglement(tokenId1, tokenId2);
        if (oldState1 != pixel1.state) emit StateChanged(tokenId1, pixel1.state);
        if (oldState2 != pixel2.state) emit StateChanged(tokenId2, pixel2.state);
    }

    // 18. disentanglePixel - Breaks an entanglement link
    function disentanglePixel(uint256 tokenId) public {
         address owner = ownerOf(tokenId);
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotPixelOwnerOrApproved(tokenId);
        }

        Pixel storage pixel = _pixels[tokenId];

        if (pixel.entangledWith == 0) {
            revert PixelsNotEntangled(tokenId);
        }

        uint256 entangledTokenId = pixel.entangledWith;
        Pixel storage entangledPixel = _pixels[entangledTokenId];

        PixelState oldState1 = pixel.state;
        PixelState oldState2 = entangledPixel.state;

        pixel.entangledWith = 0;
        entangledPixel.entangledWith = 0;

        // Disentanglement also counts as an interaction for decay purposes
        pixel.lastInteractionTime = uint64(block.timestamp);
        entangledPixel.lastInteractionTime = uint64(block.timestamp);

        _updatePixelState(pixel);
        _updatePixelState(entangledPixel);

        emit Disentanglement(tokenId, entangledTokenId);
        if (oldState1 != pixel.state) emit StateChanged(tokenId, pixel.state);
        if (oldState2 != entangledPixel.state) emit StateChanged(entangledTokenId, entangledPixel.state);
    }


    // --- Public/External Functions (Querying) ---

    // 14. getPixelState - Returns the current, dynamic state of a pixel
    function getPixelState(uint256 tokenId) public view returns (Pixel memory) {
       return _getMutatedPixel(tokenId);
    }

    // 19. getCurrentColor - Convenience getter
    function getCurrentColor(uint256 tokenId) public view returns (uint256) {
        return _getMutatedPixel(tokenId).color;
    }

    // 20. getCurrentEnergy - Convenience getter
    function getCurrentEnergy(uint256 tokenId) public view returns (uint256) {
        return _getMutatedPixel(tokenId).energy;
    }

    // 21. getCurrentState - Convenience getter
    function getCurrentState(uint256 tokenId) public view returns (PixelState) {
        return _getMutatedPixel(tokenId).state;
    }

     // 22. getEntangledWith - Convenience getter
    function getEntangledWith(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        return _pixels[tokenId].entangledWith;
    }

    // 23. getTotalSupply - Convenience getter
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Owner/Admin Functions ---

    // 23. setBaseURI - Sets the base URI for dynamic metadata
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURISet(baseURI);
    }

    // 24. setMintPrice - Sets the price to mint a pixel
    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
        emit ConfigUpdated("mintPrice", price);
    }

    // 25. setInfluenceCost - Sets the cost to influence a pixel
    function setInfluenceCost(uint256 cost) public onlyOwner {
        influenceCost = cost;
         emit ConfigUpdated("influenceCost", cost);
    }

    // 26. setRechargeCost - Sets the cost to recharge a pixel
    function setRechargeCost(uint256 cost) public onlyOwner {
        rechargeCost = cost;
         emit ConfigUpdated("rechargeCost", cost);
    }

    // 27. setEntangleCost - Sets the cost to entangle pixels
    function setEntangleCost(uint256 cost) public onlyOwner {
        entangleCost = cost;
         emit ConfigUpdated("entangleCost", cost);
    }

     // 28. setDecayRate - Sets the energy decay rate per second
    function setDecayRate(uint256 ratePerSecond) public onlyOwner {
        decayRatePerSecond = ratePerSecond;
         emit ConfigUpdated("decayRatePerSecond", ratePerSecond);
    }

    // 29. setEnergyThresholds - Sets the energy levels required for each state
    function setEnergyThresholds(uint256 dormant, uint256 active, uint256 quantum) public onlyOwner {
        dormantEnergyThreshold = dormant;
        activeEnergyThreshold = active;
        quantumEnergyThreshold = quantum;
        emit EnergyThresholdsSet(dormant, active, quantum);
    }

    // 30. withdrawFunds - Allows owner to withdraw contract balance
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(owner(), address(this).balance);
    }

    // --- Internal Hooks ---

    // 34. _beforeTokenTransfer - Hook called before any transfer
    // Potentially useful to handle state changes on transfer, e.g., auto-disentangle
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Example logic: If transferring an entangled pixel, disentangle it
        if (_pixels[tokenId].entangledWith != 0) {
            // This logic needs to be careful if batchSize > 1, but for standard ERC721
            // transfers, batchSize is usually 1. Let's implement auto-disentangle.
            uint256 entangledTokenId = _pixels[tokenId].entangledWith;
             // Only attempt if the entangled partner exists and is actually entangled *back*
            if (_exists(entangledTokenId) && _pixels[entangledTokenId].entangledWith == tokenId) {
                 _pixels[tokenId].entangledWith = 0;
                 _pixels[entangledTokenId].entangledWith = 0;
                 _updatePixelState(_pixels[tokenId]);
                 _updatePixelState(_pixels[entangledTokenId]); // Update partner's state too

                 emit Disentanglement(tokenId, entangledTokenId);
                 emit StateChanged(tokenId, _pixels[tokenId].state);
                 emit StateChanged(entangledTokenId, _pixels[entangledTokenId].state);
            } else {
                // If partner was already not entangled or didn't exist, just fix this pixel's state
                _pixels[tokenId].entangledWith = 0;
                _updatePixelState(_pixels[tokenId]);
                emit Disentanglement(tokenId, entangledTokenId); // Log the attempt/resolution
                emit StateChanged(tokenId, _pixels[tokenId].state);
            }
        }
         // Decay and update state on transfer could also be done here,
         // but doing it on read/interaction is more "quantum" metaphor.
    }


    // --- Events ---
    event Mint(uint256 indexed tokenId, address indexed owner, uint256 initialColor, uint256 initialEnergy, PixelState initialState);
    event StateChanged(uint256 indexed tokenId, PixelState newState);
    event Influenced(uint256 indexed tokenId, address indexed by, uint256 newColor, uint256 currentEnergy);
    event Recharged(uint256 indexed tokenId, address indexed by, uint256 currentEnergy);
    event Entanglement(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Disentanglement(uint256 indexed tokenId1, uint256 indexed tokenId2); // tokenId2 is the partner, 0 if partner didn't exist/was already disentangled
    event BaseURISet(string newBaseURI);
    event ConfigUpdated(string paramName, uint256 newValue); // Generic for simple value config updates
    event EnergyThresholdsSet(uint256 dormant, uint256 active, uint256 quantum);
    event FundsWithdrawn(address indexed to, uint256 amount);
}
```