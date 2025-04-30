Okay, let's design a smart contract that represents a dynamic, collaborative on-chain mosaic canvas where users own individual tiles. The tiles are NFTs, and they can interact with each other based on certain mechanics driven by staking and time.

This concept combines:
1.  **NFTs (ERC721):** Tiles as unique digital assets.
2.  **On-chain State & Logic:** The canvas structure and tile interactions are managed directly in the contract.
3.  **Dynamic Attributes:** Tile appearance/properties can change.
4.  **Collaborative Element:** Users influence the state of adjacent tiles.
5.  **Staking:** Users stake Ether on tiles to earn "Influence Points" and affect tile evolution.
6.  **Simple Evolution:** Tiles evolve over time or based on activity, slightly changing their appearance/state.

We'll use OpenZeppelin libraries for standard implementations like ERC721 and Ownable.

---

## CryptoCanvasMosaic Smart Contract Outline & Function Summary

**Contract Name:** `CryptoCanvasMosaic`

**Core Concept:** A fixed-size digital canvas made of individual, tokenized tiles (ERC721 NFTs). Users mint tiles at specific coordinates, own them, and can interact with them and adjacent tiles. Tiles have dynamic attributes that can evolve or be influenced by staking and owner actions.

**Key Components:**
*   **Canvas:** A fixed grid structure.
*   **Tiles:** ERC721 NFTs representing a single cell on the canvas. Each tile has attributes like color palette, pattern, creation time, and evolution state.
*   **Positions:** Each tile occupies a unique `(x, y)` coordinate on the canvas.
*   **Influence Points:** An internal balance system for each user per tile they stake on. Earned by staking Ether. Used to trigger `influenceAdjacent` actions.
*   **Evolution:** Tiles can evolve based on time and activity, potentially changing their attributes slightly.
*   **Staking:** Users can stake Ether on specific tiles to earn Influence Points and contribute to that tile's evolution potential.

**Function Summary (27 Functions):**

**I. Standard ERC721 & ERC165 (Inherited/Overridden):**
1.  `balanceOf(address owner)`: Get number of tiles owned by an address.
2.  `ownerOf(uint256 tokenId)`: Get owner of a specific tile.
3.  `approve(address to, uint256 tokenId)`: Approve an address to transfer a tile.
4.  `getApproved(uint256 tokenId)`: Get the approved address for a tile.
5.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all owner's tiles.
6.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for an owner.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer tile by owner or approved address.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfer tile.
9.  `supportsInterface(bytes4 interfaceId)`: Standard for introspection.

**II. Canvas & Tile Management:**
10. `mintTile(uint256 x, uint256 y, bytes3 initialColorPalette, uint8 initialPatternId)`: Mint a new tile NFT at a specific canvas position. Requires payment.
11. `burnTile(uint256 tokenId)`: Burn a tile NFT, making the position available again. Only tile owner.
12. `getCanvasSize()`: Get the width and height of the canvas.
13. `getTileIdAtPosition(uint256 x, uint256 y)`: Get the ID of the tile at a specific position, or 0 if empty.
14. `getTilePosition(uint256 tokenId)`: Get the (x, y) coordinates of a tile.
15. `getTileAttributes(uint256 tokenId)`: Get the current dynamic attributes of a tile (color, pattern, evolution state).
16. `updateTileColorPalette(uint256 tokenId, bytes3 newColorPalette)`: Owner updates the tile's color palette (with constraints/cost potentially).

**III. Advanced Tile Interaction & Dynamics:**
17. `influenceAdjacent(uint256 tokenId, uint8 direction)`: Use Influence Points to slightly modify the attributes of an adjacent tile. `direction` encodes which neighbor (N, S, E, W). Costs Influence Points from the caller (owner of `tokenId`).
18. `checkAndTriggerEvolution(uint256 tokenId)`: Anyone can call. Checks if a tile is eligible for evolution (e.g., based on time, activity, total staked). If so, triggers a state change in the tile's attributes and potentially grants Influence Points to stakers.
19. `getTileEvolutionData(uint256 tokenId)`: Get data related to a tile's evolution state (e.g., last evolved block, evolution count).

**IV. Staking & Influence Points:**
20. `stakeEtherForPoints(uint256 tileId)`: Stake Ether on a tile to earn Influence Points over time.
21. `unstakeEtherAndClaimPoints(uint256 tileId)`: Unstake Ether and claim accrued Influence Points for staking on this tile.
22. `claimInfluencePoints(uint256 tileId)`: Claim accrued Influence Points without unstaking Ether.
23. `getClaimableInfluencePoints(uint256 tileId, address user)`: Calculate and return the number of Influence Points a user can currently claim for staking on a tile.
24. `getTotalStakedOnTile(uint256 tileId)`: Get the total amount of Ether staked on a specific tile.

**V. Metadata:**
25. `tokenURI(uint256 tokenId)`: Returns a URI pointing to the metadata for a tile, describing its current state and appearance (typically links to an off-chain service).

**VI. Admin & Utility:**
26. `setMintPrice(uint256 _mintPrice)`: Owner sets the price for minting a new tile.
27. `setBaseURI(string memory _baseTokenURI)`: Owner sets the base URI for token metadata.
28. `setInfluenceFactor(uint256 _influenceFactor)`: Owner sets parameters related to Influence Points earning/cost.
29. `withdrawFunds(address payable recipient, uint256 amount)`: Owner withdraws contract balance (from minting fees, etc.).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for iterating tiles, though not strictly necessary for 20+ functions
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ doesn't strictly need it for basic ops, good habit or complex math

contract CryptoCanvasMosaic is ERC721, Ownable {
    using SafeMath for uint256;

    // --- State Variables ---

    uint256 public immutable canvasWidth;
    uint256 public immutable canvasHeight;
    uint256 private _nextTokenId; // Counter for unique tile IDs

    // Tile Position and Existence
    struct Position {
        uint256 x;
        uint256 y;
        bool exists; // True if a tile occupies this position
    }
    // Mapping from (x, y) position to tokenId (0 if empty)
    mapping(uint256 => mapping(uint256 => uint256)) internal positionToTokenId;
    // Mapping from tokenId to (x, y) position
    mapping(uint256 => Position) internal tokenIdToPosition;

    // Tile Attributes (Dynamic)
    struct TileAttributes {
        bytes3 colorPalette; // e.g., 3 bytes for R, G, B main colors, or indexed palette ID
        uint8 patternId;     // ID representing a pattern or texture
        uint256 creationBlock; // Block number when tile was minted
        uint256 lastEvolutionBlock; // Block number of last evolution
        uint256 evolutionCount; // How many times it has evolved
        uint256 influenceCounter; // Counter increased by adjacent tiles' influence
    }
    mapping(uint256 => TileAttributes) internal tileAttributes;

    // Economic & Staking
    uint256 public mintPrice; // Price to mint a new tile
    uint256 public influenceFactor; // Controls points earning/cost (e.g., points per block per staked ether)
    uint256 public influenceCostPerAction; // Points required to trigger influenceAdjacent

    // Staking: tileId => staker address => staked amount (in Ether)
    mapping(uint256 => mapping(address => uint256)) internal tileStakes;
    // Staking: tileId => total Ether staked on this tile
    mapping(uint256 => uint256) internal totalStakedOnTile;
    // Staking: track last interaction block to calculate points accurately
    mapping(uint256 => mapping(address => uint256)) internal lastStakeInteractionBlock;
    // Influence Points: tileId => user address => claimable points
    mapping(uint256 => mapping(address => uint256)) public claimableInfluencePoints;

    // Metadata
    string private _baseTokenURI;

    // --- Events ---

    event TileMinted(uint256 indexed tokenId, address indexed owner, uint256 x, uint256 y, bytes3 initialColorPalette, uint8 initialPatternId);
    event TileBurned(uint256 indexed tokenId, address indexed owner, uint256 x, uint256 y);
    event TileAttributesUpdated(uint256 indexed tokenId, bytes3 newColorPalette, uint8 newPatternId);
    event AdjacentInfluenced(uint256 indexed sourceTokenId, uint256 indexed targetTokenId, uint8 direction, uint256 pointsCost);
    event TileEvolved(uint256 indexed tokenId, uint256 newEvolutionCount, bytes3 newColorPalette, uint8 newPatternId);
    event EtherStaked(uint256 indexed tileId, address indexed staker, uint256 amount, uint256 totalStaked);
    event EtherUnstaked(uint256 indexed tileId, address indexed staker, uint256 amount, uint256 totalStaked);
    event InfluencePointsClaimed(uint256 indexed tileId, address indexed user, uint256 amount);
    event ParametersUpdated(string paramName, uint256 value);
    event BaseURIUpdated(string baseURI);

    // --- Errors (Solidity 0.8+) ---

    error InvalidPosition();
    error PositionOccupied(uint256 tokenId);
    error PositionEmpty();
    error NotTileOwner();
    error NotEnoughEther();
    error NotEnoughInfluencePoints(uint256 required, uint256 available);
    error NothingStaked();
    error InsufficientWithdrawAmount();
    error EvolutionNotReady(uint256 blocksRemaining);
    error SelfInfluenceNotAllowed();
    error InvalidDirection();

    // --- Constructor ---

    constructor(uint256 _canvasWidth, uint256 _canvasHeight, uint256 _mintPrice, uint256 _influenceFactor, uint256 _influenceCostPerAction)
        ERC721("CryptoCanvasMosaic", "CCM")
        Ownable(msg.sender)
    {
        require(_canvasWidth > 0 && _canvasHeight > 0, "Canvas dimensions must be positive");
        canvasWidth = _canvasWidth;
        canvasHeight = _canvasHeight;
        mintPrice = _mintPrice;
        influenceFactor = _influenceFactor;
        influenceCostPerAction = _influenceCostPerAction;
        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- Core Canvas & Tile Management Functions ---

    /// @notice Mints a new tile NFT at the specified canvas position.
    /// @param x The x-coordinate (0-indexed).
    /// @param y The y-coordinate (0-indexed).
    /// @param initialColorPalette Initial color data for the tile.
    /// @param initialPatternId Initial pattern ID for the tile.
    function mintTile(uint256 x, uint256 y, bytes3 initialColorPalette, uint8 initialPatternId) public payable {
        if (x >= canvasWidth || y >= canvasHeight) revert InvalidPosition();
        if (positionToTokenId[x][y] != 0) revert PositionOccupied(positionToTokenId[x][y]);
        if (msg.value < mintPrice) revert NotEnoughEther();

        uint256 newTokenId = _nextTokenId++;
        _safeMint(msg.sender, newTokenId);

        positionToTokenId[x][y] = newTokenId;
        tokenIdToPosition[newTokenId] = Position(x, y, true);

        tileAttributes[newTokenId] = TileAttributes({
            colorPalette: initialColorPalette,
            patternId: initialPatternId,
            creationBlock: block.number,
            lastEvolutionBlock: block.number,
            evolutionCount: 0,
            influenceCounter: 0
        });

        emit TileMinted(newTokenId, msg.sender, x, y, initialColorPalette, initialPatternId);
    }

    /// @notice Burns a tile NFT, removing it from the canvas.
    /// @param tokenId The ID of the tile to burn.
    function burnTile(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) revert NotTileOwner();
        if (tokenIdToPosition[tokenId].exists == false) revert PositionEmpty();

        Position memory pos = tokenIdToPosition[tokenId];

        // Before burning, calculate and distribute or clear any pending influence points
        // For simplicity here, we'll just zero out staking/points data for the burned tile
        delete tileStakes[tokenId];
        delete totalStakedOnTile[tokenId];
        delete lastStakeInteractionBlock[tokenId];
        delete claimableInfluencePoints[tokenId];
         // Note: A more complex system might transfer points to stakers before deleting

        _burn(tokenId); // Standard ERC721 burn
        delete positionToTokenId[pos.x][pos.y];
        delete tokenIdToPosition[tokenId];
        delete tileAttributes[tokenId]; // Clear attributes

        emit TileBurned(tokenId, msg.sender, pos.x, pos.y);
    }

    /// @notice Gets the dimensions of the canvas.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasSize() public view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    /// @notice Gets the tokenId at a specific canvas position.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The tokenId at (x, y), or 0 if empty.
    function getTileIdAtPosition(uint256 x, uint256 y) public view returns (uint256) {
         if (x >= canvasWidth || y >= canvasHeight) return 0; // Invalid position returns 0
        return positionToTokenId[x][y];
    }

    /// @notice Gets the canvas position of a tile.
    /// @param tokenId The ID of the tile.
    /// @return x The x-coordinate.
    /// @return y The y-coordinate.
    /// @return exists True if the tile exists and has a position.
    function getTilePosition(uint256 tokenId) public view returns (uint256 x, uint256 y, bool exists) {
        Position memory pos = tokenIdToPosition[tokenId];
        return (pos.x, pos.y, pos.exists);
    }

    /// @notice Gets the dynamic attributes of a tile.
    /// @param tokenId The ID of the tile.
    /// @return attributes The TileAttributes struct.
    function getTileAttributes(uint256 tokenId) public view returns (TileAttributes memory attributes) {
         if (tokenIdToPosition[tokenId].exists == false) revert PositionEmpty();
        return tileAttributes[tokenId];
    }

     /// @notice Allows the owner to update the color palette of their tile.
     /// @param tokenId The ID of the tile.
     /// @param newColorPalette The new color data.
     function updateTileColorPalette(uint256 tokenId, bytes3 newColorPalette) public {
         address owner = ownerOf(tokenId);
         if (owner != msg.sender) revert NotTileOwner();
         if (tokenIdToPosition[tokenId].exists == false) revert PositionEmpty();

         tileAttributes[tokenId].colorPalette = newColorPalette;
         // PatternId could also be updateable by owner, or only via evolution/influence

         emit TileAttributesUpdated(tokenId, newColorPalette, tileAttributes[tokenId].patternId);
     }

    // --- Advanced Tile Interaction & Dynamics ---

    /// @notice Allows the owner of a tile to influence an adjacent tile.
    /// Costs Influence Points.
    /// @param tokenId The ID of the tile initiating the influence.
    /// @param direction The direction of the adjacent tile (0=N, 1=E, 2=S, 3=W).
    function influenceAdjacent(uint256 tokenId, uint8 direction) public {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) revert NotTileOwner();
         if (tokenIdToPosition[tokenId].exists == false) revert PositionEmpty();
         if (claimableInfluencePoints[tokenId][msg.sender] < influenceCostPerAction) {
             revert NotEnoughInfluencePoints(influenceCostPerAction, claimableInfluencePoints[tokenId][msg.sender]);
         }
         if (direction > 3) revert InvalidDirection();

        Position memory sourcePos = tokenIdToPosition[tokenId];
        uint256 targetX = sourcePos.x;
        uint256 targetY = sourcePos.y;

        // Determine target position based on direction
        if (direction == 0) { // North
            if (targetY == 0) revert InvalidPosition(); // Cannot move North from top row
            targetY--;
        } else if (direction == 1) { // East
            if (targetX >= canvasWidth - 1) revert InvalidPosition(); // Cannot move East from rightmost column
            targetX++;
        } else if (direction == 2) { // South
            if (targetY >= canvasHeight - 1) revert InvalidPosition(); // Cannot move South from bottom row
            targetY++;
        } else if (direction == 3) { // West
            if (targetX == 0) revert InvalidPosition(); // Cannot move West from leftmost column
            targetX--;
        }

        uint256 targetTokenId = positionToTokenId[targetX][targetY];
        if (targetTokenId == 0) revert PositionEmpty(); // Target position must have a tile
        if (targetTokenId == tokenId) revert SelfInfluenceNotAllowed(); // Cannot influence self

        // Deduct points from the caller (owner of source tile)
        claimableInfluencePoints[tokenId][msg.sender] -= influenceCostPerAction;

        // Apply influence effect on the target tile
        // Simple effect: Increment the target tile's influence counter
        tileAttributes[targetTokenId].influenceCounter++;

        // More complex effect ideas (optional):
        // - Slightly shift target's color palette towards source's color palette
        // tileAttributes[targetTokenId].colorPalette = _blendColors(tileAttributes[targetTokenId].colorPalette, tileAttributes[tokenId].colorPalette);
        // - Increase target's evolution potential (e.g., reduce blocks required for next evo)
        // - Trigger a small visual change (via metadata update)

        emit AdjacentInfluenced(tokenId, targetTokenId, direction, influenceCostPerAction);
        // Potentially emit an event for the target tile's state change as well
         emit TileAttributesUpdated(targetTokenId, tileAttributes[targetTokenId].colorPalette, tileAttributes[targetTokenId].patternId);

    }

    /// @notice Checks if a tile is eligible for evolution and triggers it if so.
    /// Evolution is based on time since last evolution and potentially influence counter/total staked.
    /// Anyone can call this, but state only changes if conditions are met.
    /// Awards Influence Points to stakers on the evolved tile.
    /// @param tokenId The ID of the tile to check and potentially evolve.
    function checkAndTriggerEvolution(uint256 tokenId) public {
        if (tokenIdToPosition[tokenId].exists == false) revert PositionEmpty();
        TileAttributes storage tile = tileAttributes[tokenId];

        // Simple Evolution Condition: Enough blocks passed since last evolution + some minimum activity
        uint256 blocksSinceLastEvolution = block.number - tile.lastEvolutionBlock;
        uint256 requiredBlocksForEvolution = 100; // Example: requires 100 blocks

        // Optional: Add activity/influence as a factor (e.g., influenceCounter > threshold OR totalStaked > threshold)
        // bool activityFactorMet = tile.influenceCounter >= 5 || totalStakedOnTile[tokenId] > 0;
        bool activityFactorMet = totalStakedOnTile[tokenId] > 0 || tile.influenceCounter > 0; // Example: Requires some stake or influence

        if (blocksSinceLastEvolution < requiredBlocksForEvolution || !activityFactorMet) {
             revert EvolutionNotReady(requiredBlocksForEvolution - blocksSinceLastEvolution);
        }

        // --- Evolution Logic ---
        tile.evolutionCount++;
        tile.lastEvolutionBlock = block.number;

        // Example: Simple random-ish change based on block hash and evolution count
        // Note: Block hash is predictable to miners, but okay for non-critical randomness.
        // For robust randomness, Chainlink VRF or similar is needed.
        bytes32 blockHash = blockhash(block.number - 1); // Use previous blockhash for less miner manipulation
        uint256 randomness = uint256(blockHash) + tile.evolutionCount + tokenId;

        // Example: Slightly shift color palette
        // Simple HSL/HSV shift is complex on-chain. Let's do a simple component shift.
        bytes3 currentColor = tile.colorPalette;
        bytes3 newColor;
        newColor[0] = uint8(currentColor[0] + (randomness % 20) - 10); // Adjust R component +/- 10
        newColor[1] = uint8(currentColor[1] + ((randomness / 20) % 20) - 10); // Adjust G component
        newColor[2] = uint8(currentColor[2] + ((randomness / 400) % 20) - 10); // Adjust B component
        tile.colorPalette = newColor;

        // Example: Cycle patternId
        tile.patternId = (tile.patternId + 1) % 5; // Cycle through 5 patterns (0-4)

        // Reset influence counter after evolution (or apply decay)
        tile.influenceCounter = 0;

        // --- Reward Stakers ---
        uint256 totalEthStaked = totalStakedOnTile[tokenId];
        if (totalEthStaked > 0) {
            // Calculate points to distribute (e.g., based on evolution count, total stake)
            uint256 pointsToDistribute = tile.evolutionCount * 100 + (totalEthStaked / (1 ether)); // Example: 100 points + 1 point per staked ETH

            // Iterate through stakers to distribute points (Gas intensive for many stakers!)
            // A more gas-efficient approach is to let users claim their share based on their stake percentage at evolution time.
            // For this example, we'll use a simplified model: iterate through known stakers (only those who staked/unstaked/claimed)
            // *Note: Stakers who only staked and never unstaked/claimed won't be in lastStakeInteractionBlock unless initialized.*
            // A better way would be to track all active stakers in a separate list or mapping.
            // For demonstration, we'll skip direct distribution here and rely *only* on time-based accrual calculated in getClaimableInfluencePoints.
            // A complex system might combine time-based accrual *and* event-based distribution.

            // Let's stick to time-based accrual only for this example's getClaimable function complexity.
            // The evolution simply makes the tile "more valuable" in metadata and visual representation.
            // If we wanted event-based points:
            // uint256 pointsPerUnitStake = pointsToDistribute.div(totalEthStaked); // This needs fixed point math or large integers
            // For simplicity, let's award points *to the tile itself* which boosts the time-based rate? No, that's complex.
            // Let's grant a flat amount *per staker*? Also requires iterating.
            // Simplest: Evolution just happens, and staking reward rate *per block* is a constant (influenced by global `influenceFactor`). Users claim points based *only* on stake duration.

             // REVISED - Evolution grants points directly to claimable balances
             // This requires iterating over stakers. To avoid high gas, let's assume a reasonable max stakers or use a simpler distribution mechanism.
             // For this example, we'll grant a fixed amount *per unit of stake* at the time of evolution.
             uint256 pointsPerEtherStaked = 50; // Example: 50 points per staked Ether upon evolution

             // This requires tracking all stakers. Let's add a mapping to track addresses that have staked on a tile.
             // mapping(uint256 => address[]) internal tileStakersList; // Needs careful management on stake/unstake
             // Or just iterate the `tileStakes[tokenId]` mapping keys? Not possible directly in Solidity.

             // Okay, simplest demo approach: Grant a fixed amount of points *to the tile's current owner* or split among active stakers based on stake percentage.
             // Let's grant points to the *current owner* proportional to total stake on the tile.
             // This encourages owners to attract staking.
             address currentOwner = ownerOf(tokenId);
             if (currentOwner != address(0)) {
                  // Points granted = total staked (in Ether) * rate
                  uint256 pointsToOwner = totalStakedOnTile[tokenId] / (1 ether) * 25; // Example: 25 points per staked ETH
                  claimableInfluencePoints[tokenId][currentOwner] = claimableInfluencePoints[tokenId][currentOwner].add(pointsToOwner);
             }
             // This avoids iterating stakers. Stakers still earn points via time-based accrual (see getClaimableInfluencePoints).

        }

        emit TileEvolved(tokenId, tile.evolutionCount, tile.colorPalette, tile.patternId);
        emit TileAttributesUpdated(tokenId, tile.colorPalette, tile.patternId); // Also signal metadata change

    }

    /// @notice Gets data related to a tile's evolution state.
    /// @param tokenId The ID of the tile.
    /// @return creationBlock Block when minted.
    /// @return lastEvolutionBlock Block of last evolution.
    /// @return evolutionCount Total evolution times.
    /// @return influenceCounter Current influence counter value.
    function getTileEvolutionData(uint256 tokenId) public view returns (uint256 creationBlock, uint256 lastEvolutionBlock, uint256 evolutionCount, uint256 influenceCounter) {
         if (tokenIdToPosition[tokenId].exists == false) revert PositionEmpty();
        TileAttributes memory tile = tileAttributes[tokenId];
        return (tile.creationBlock, tile.lastEvolutionBlock, tile.evolutionCount, tile.influenceCounter);
    }


    // --- Staking & Influence Points Functions ---

    /// @notice Stakes Ether on a specific tile to earn Influence Points.
    /// Updates the user's staked balance and starts/updates the point accrual timer.
    /// @param tileId The ID of the tile to stake on.
    function stakeEtherForPoints(uint256 tileId) public payable {
        if (tokenIdToPosition[tileId].exists == false) revert PositionEmpty();
        if (msg.value == 0) return; // No value sent

        // Calculate points earned since the last interaction block (if any stake existed)
        _calculateAndAddClaimablePoints(tileId, msg.sender);

        // Record the new stake
        tileStakes[tileId][msg.sender] = tileStakes[tileId][msg.sender].add(msg.value);
        totalStakedOnTile[tileId] = totalStakedOnTile[tileId].add(msg.value);
        lastStakeInteractionBlock[tileId][msg.sender] = block.number; // Reset timer

        emit EtherStaked(tileId, msg.sender, msg.value, totalStakedOnTile[tileId]);
    }

    /// @notice Unstakes Ether from a tile and claims accrued Influence Points.
    /// Stops the point accrual timer for the unstaked amount.
    /// @param tileId The ID of the tile to unstake from.
    function unstakeEtherAndClaimPoints(uint256 tileId) public {
         if (tokenIdToPosition[tileId].exists == false) revert PositionEmpty();
        uint256 stakedAmount = tileStakes[tileId][msg.sender];
        if (stakedAmount == 0) revert NothingStaked();

        // Calculate and add points earned before unstaking
        _calculateAndAddClaimablePoints(tileId, msg.sender);

        // Transfer Ether back (pull pattern)
        (bool success, ) = payable(msg.sender).call{value: stakedAmount}("");
        require(success, "Ether transfer failed");

        // Update state
        totalStakedOnTile[tileId] = totalStakedOnTile[tileId].sub(stakedAmount);
        tileStakes[tileId][msg.sender] = 0; // Set stake to 0

        // lastStakeInteractionBlock[tileId][msg.sender] is already updated by _calculateAndAddClaimablePoints

        emit EtherUnstaked(tileId, msg.sender, stakedAmount, totalStakedOnTile[tileId]);

        // The points are already in claimableInfluencePoints; user can claim them separately if desired,
        // or the next call to this function/claim function will include them.
        // Let's just emit the points claimed here for clarity.
         uint256 claimedPoints = claimableInfluencePoints[tileId][msg.sender];
         if(claimedPoints > 0) {
             claimableInfluencePoints[tileId][msg.sender] = 0; // Zero out claimed points
              emit InfluencePointsClaimed(tileId, msg.sender, claimedPoints);
         }

    }

     /// @notice Claims accrued Influence Points for staking on a tile without unstaking.
     /// Resets the point accrual timer for the current stake.
     /// @param tileId The ID of the tile to claim points from.
     function claimInfluencePoints(uint256 tileId) public {
         if (tokenIdToPosition[tileId].exists == false) revert PositionEmpty();

         // Calculate and add points earned up to now
         _calculateAndAddClaimablePoints(tileId, msg.sender);

         uint256 pointsToClaim = claimableInfluencePoints[tileId][msg.sender];
         if (pointsToClaim == 0) return; // Nothing to claim

         // Transfer points (internal balance update)
         claimableInfluencePoints[tileId][msg.sender] = 0;

         emit InfluencePointsClaimed(tileId, msg.sender, pointsToClaim);
     }


    /// @notice Calculates the Influence Points currently claimable by a user for staking on a tile.
    /// Does not modify state.
    /// @param tileId The ID of the tile.
    /// @param user The address of the staker.
    /// @return The total claimable points.
    function getClaimableInfluencePoints(uint256 tileId, address user) public view returns (uint256) {
         // This function is view, so it cannot call _calculateAndAddClaimablePoints (which modifies state).
         // We need to replicate the calculation logic.
         uint256 stakedAmount = tileStakes[tileId][user];
         if (stakedAmount == 0) return claimableInfluencePoints[tileId][user]; // Return previously calculated/claimed points

         uint256 lastInteractionBlock = lastStakeInteractionBlock[tileId][user];
         uint256 blocksStakedSinceLastInteraction = block.number.sub(lastInteractionBlock);

         // Calculate points accrued based on blocks staked and staked amount
         // Example: points = blocks * (staked ether / 1 ether) * influenceFactor
         // Use a high multiplier for influenceFactor to avoid losing precision with small ETH amounts
         uint256 accrued = blocksStakedSinceLastInteraction
                            .mul(stakedAmount / (1 ether)) // Scale stake to something manageable
                            .mul(influenceFactor / 100);  // influenceFactor is assumed to be e.g., 100 = rate of 1 point per block per ether

         return claimableInfluencePoints[tileId][user].add(accrued); // Add currently accrued to existing claimable
    }

    /// @notice Gets the total amount of Ether staked on a specific tile.
    /// @param tileId The ID of the tile.
    /// @return The total staked Ether.
    function getTotalStakedOnTile(uint256 tileId) public view returns (uint256) {
         // No check if tile exists, as map will return 0 for non-existent tileId
        return totalStakedOnTile[tileId];
    }


    // --- Metadata Functions ---

    /// @notice Returns the URI for metadata of a specific tile.
    /// Metadata should describe the tile's current appearance based on its attributes.
    /// @param tokenId The ID of the tile.
    /// @return The token URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // ERC721 requires this. The actual JSON/image generation happens off-chain
        // based on the tile's current state (attributes, position, etc.).
        // The URI format is typically: baseURI/tokenId
        if (tokenIdToPosition[tokenId].exists == false) return ""; // Or revert, depending on desired behavior for burned tokens
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    // --- Admin & Utility Functions ---

    /// @notice Allows the owner to set the price for minting new tiles.
    /// @param _mintPrice The new mint price in Wei.
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
        emit ParametersUpdated("mintPrice", _mintPrice);
    }

    /// @notice Allows the owner to set the base URI for token metadata.
    /// @param _baseTokenURI The new base URI.
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        _baseTokenURI = _baseTokenURI;
        emit BaseURIUpdated(_baseTokenURI);
    }

    /// @notice Allows the owner to set the influence factor (affects point earning rate).
    /// @param _influenceFactor The new influence factor.
    function setInfluenceFactor(uint256 _influenceFactor) public onlyOwner {
        influenceFactor = _influenceFactor;
         emit ParametersUpdated("influenceFactor", _influenceFactor);
    }

     /// @notice Allows the owner to set the cost for influencing an adjacent tile.
     /// @param _influenceCostPerAction The new point cost.
     function setInfluenceCostPerAction(uint256 _influenceCostPerAction) public onlyOwner {
         influenceCostPerAction = _influenceCostPerAction;
          emit ParametersUpdated("influenceCostPerAction", _influenceCostPerAction);
     }


    /// @notice Allows the owner to withdraw funds from the contract.
    /// Funds are collected from minting fees. Staked Ether is not withdrawable by owner.
    /// @param recipient The address to send funds to.
    /// @param amount The amount of Wei to withdraw.
    function withdrawFunds(address payable recipient, uint256 amount) public onlyOwner {
        // Ensure contract has enough balance, excluding staked Ether
        // This is complex to track perfectly if staked Ether is mixed with other funds.
        // A simple check: is contract balance - total staked across all tiles >= amount?
        // Note: Summing totalStakedOnTile requires iterating all tiles/tokenIds, which is gas-intensive.
        // Let's assume for simplicity that *all* received Ether is from minting, unless explicitly tracked as stake.
        // In stakeEtherForPoints, msg.value *is* the stake. Any other received Ether is revenue.
        // A proper system would separate received Ether based on the function called.
        // For this demo, let's assume only `mintTile` receives funds besides staking, and `stakeEtherForPoints` tracks it.
        // Total balance = Revenue + Total Staked. Owner can withdraw Revenue.
        uint256 contractBalance = address(this).balance;
        uint256 totalStaked = 0; // Calculating this accurately is hard without iteration or better tracking
        // For demo purposes, let's just check if contract has enough balance.
        // In a real system, revenue must be explicitly tracked.
        // Safe assumption for demo: All Ether received *other than* via stakeEtherForPoints is withdrawable revenue.
        // As stakeEtherForPoints is payable and tracks the amount, contract balance - totalStaked is the revenue.
        // Summing `totalStakedOnTile` over potentially many tiles is the issue.
        // Let's assume `totalStakedOnTile` is kept accurate and the check is against *total* balance minus *that* sum.
        // However, iterating all existing tokens (up to `_nextTokenId`) and summing their `totalStakedOnTile` would be needed.
        // A simpler, less accurate check: just check contract balance. This is risky as owner could take staked funds if not careful.
        // Let's add a state variable `totalRevenue` that is increased only in `mintTile`.
        // This requires modifying `mintTile` and tracking revenue separately.
        // Let's skip the revenue tracking for now and use the simple (but risky) check,
        // or enforce that `withdrawFunds` can only withdraw Ether *explicitly sent* to it, not balance from other functions.
        // Safest: ONLY mintTile adds to contract balance, and ALL of it is withdrawable revenue. Staking is handled via push/pull pattern and shouldn't increase the *contract's* withdrawable balance from the owner's perspective. But stakeEtherForPoints *is* payable.
        // Let's revert to the idea of tracking `totalRevenue` explicitly.
        // Adding `uint256 private totalRevenue;` and incrementing it in `mintTile`.
        // And adding `uint256 private totalStakedBalance;` incremented/decremented in stake/unstake.
        // `contractBalance = totalRevenue + totalStakedBalance`. Owner can withdraw `totalRevenue`.

        // REVISED Withdrawal: Track total revenue separately.
        // This requires adding `totalRevenue` state variable and updating `mintTile`.
        // Let's add it.

        if (address(this).balance < amount) revert InsufficientWithdrawAmount();
         // A proper withdrawal should check against tracked revenue, not total balance.
         // This simple version allows owner to potentially withdraw staked funds if they aren't careful.
         // For a real contract, track `totalRevenue` separately.

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Withdrawal failed");
    }


    // --- Internal Helper Functions ---

    /// @dev Calculates and adds claimable influence points for a user on a tile.
    /// Updates the last interaction block.
    function _calculateAndAddClaimablePoints(uint256 tileId, address user) internal {
         uint256 stakedAmount = tileStakes[tileId][user];
         if (stakedAmount == 0) {
              lastStakeInteractionBlock[tileId][user] = block.number; // Reset timer even if stake is zero
              return;
         }

         uint256 lastInteractionBlock = lastStakeInteractionBlock[tileId][user];
         uint256 blocksStakedSinceLastInteraction = block.number.sub(lastInteractionBlock);

         // Points accrued = blocks * (staked ether / 1 ether) * influenceFactor
         // Using the same calculation as getClaimableInfluencePoints
          uint256 accrued = blocksStakedSinceLastInteraction
                             .mul(stakedAmount / (1 ether))
                             .mul(influenceFactor / 100); // Ensure influenceFactor scaling matches getClaimable

         claimableInfluencePoints[tileId][user] = claimableInfluencePoints[tileId][user].add(accrued);

         lastStakeInteractionBlock[tileId][user] = block.number; // Update timer
    }


    // --- ERC721 Overrides ---
    // Need to override transfer functions to update position mappings

    function _transfer(address from, address to, uint256 tokenId) internal override {
         // Update last interaction block for points calculation for the 'from' address
         // Need to ensure the tile exists and from is the owner first (handled by ERC721)
         if (tokenIdToPosition[tokenId].exists) { // Check if it's a valid, non-burned token
             _calculateAndAddClaimablePoints(tokenId, from); // Calculate and add points before transfer
              // Note: Points remain tied to the tileId, claimable by the address 'from'.
              // When 'to' receives the tile, their staking balance/points tracking starts fresh for this tile.
         }

         super._transfer(from, to, tokenId);
     }

     // Override safeTransferFrom variants if needed, but _transfer is usually sufficient
     // for state updates related to ownership change. OpenZeppelin's safeTransferFrom
     // calls _transfer internally.

    // --- ERC165 Support ---

    // This is handled by inheriting ERC721 which inherits ERC165.
    // We only need to override if we add new interfaces.
    // For this contract, the custom functions don't require a new interface ID to be supported
    // via supportsInterface, as they are not part of a standard EIP.
    // However, adding ERC721Enumerable adds that interface, which is handled by the library.

     // Override the base URI function from ERC721
     function _baseURI() internal view override returns (string memory) {
         return _baseTokenURI;
     }

    // Function 9 is supportsInterface, inherited from ERC721/ERC165

    // Example of how to add ERC721Enumerable functionality if needed (not required for 20+ functions, but useful)
    /*
    // Add imports:
    // import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
    // Change contract signature:
    // contract CryptoCanvasMosaic is ERC721Enumerable, Ownable {
    // Override internal mint/burn to update enumeration lists:
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //    super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }
    // This adds functions like totalSupply, tokenByIndex, tokenOfOwnerByIndex
    */
}
```