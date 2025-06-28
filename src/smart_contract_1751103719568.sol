Okay, here is a smart contract concept called `QuantumPixelCanvas`.

This contract represents a large, shared pixel canvas where each pixel is a unique, dynamic NFT (ERC721). The "quantum" aspect is metaphorical: each pixel has an internal state ("potential energy," "rule signature") that influences its unpredictable (based on on-chain "randomness" or time-based evolution) color/state changes unless observed/modified by its owner. The evolution rules are also defined on-chain and can be complex. Anyone can trigger the evolution of any pixel, receiving a small reward for performing the computation (decentralized execution).

This combines:
1.  **Dynamic NFTs:** Pixel state (color, energy, rule) changes over time.
2.  **On-Chain Generative Art:** Pixel evolution rules are defined and executed within the contract.
3.  **Decentralized Computation:** Anyone can trigger evolution, incentivized by a reward.
4.  **Shared State/World:** A single canvas where owned pixels exist and interact (conceptually, though neighbor interaction isn't strictly implemented for V1 gas limits, it's a natural extension).
5.  **Configurable Rules:** Evolution rules can be defined and updated by the admin.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for listing tokens, but can be gas intensive
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max if needed
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title QuantumPixelCanvas
 * @dev A dynamic, generative pixel canvas on the blockchain.
 * Each pixel is a dynamic ERC721 NFT whose state (color, energy, rule)
 * evolves over time based on on-chain rules, unless modified by the owner.
 * Evolution can be triggered by anyone for a reward.
 */
contract QuantumPixelCanvas is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Address for address;

    // --- OUTLINE & FUNCTION SUMMARY ---
    //
    // 1. State Variables:
    //    - Canvas dimensions (width, height)
    //    - Pixel data (color, energy, last evolved time, rule ID) mapped by token ID
    //    - Evolution rules mapped by rule ID
    //    - Counters for tokens and rules
    //    - Configuration (mint price, draw cost, evolution reward, energy recharge rate)
    //    - Paused state
    //
    // 2. Structures:
    //    - PixelState: Represents a pixel's dynamic data.
    //    - EvolutionRule: Defines how a pixel evolves.
    //
    // 3. Events:
    //    - PixelMinted: When a pixel is claimed/minted.
    //    - PixelColorSet: When a pixel's color is changed by owner.
    //    - PixelStateChanged: When a pixel's state (color, energy, rule) changes, typically via evolution.
    //    - EvolutionRuleDefined: When a new rule is created or updated.
    //    - PixelRuleSet: When a pixel's rule is changed by owner.
    //    - CanvasResized: When the canvas dimensions are changed (admin).
    //    - ConfigUpdated: When core contract configs change (admin).
    //    - Paused/Unpaused: Standard pause events.
    //
    // 4. Core ERC721 Functions:
    //    - constructor: Initialize contract, dimensions, admin.
    //    - balanceOf: Get number of tokens owned by address.
    //    - ownerOf: Get owner of token ID.
    //    - safeTransferFrom / transferFrom: Transfer token ownership.
    //    - approve / setApprovalForAll / getApproved / isApprovedForAll: Manage token approvals.
    //    - supportsInterface: ERC165 interface support.
    //    - tokenURI: Get metadata URI for a token (potentially dynamic).
    //    - _beforeTokenTransfer / _afterTokenTransfer: Internal hooks for ERC721Enumerable.
    //
    // 5. Pixel Management & Interaction Functions:
    //    - getTokenIdFromCoords(uint256 x, uint256 y): Get token ID for coordinates.
    //    - getCoordsFromTokenId(uint256 tokenId): Get coordinates for token ID.
    //    - mintPixel(uint256 x, uint256 y): Claim/mint an unclaimed pixel at coords.
    //    - setPixelColor(uint256 tokenId, uint32 color): Set the color of an owned pixel.
    //    - setPixelRule(uint256 tokenId, uint16 ruleId): Set the evolution rule for an owned pixel.
    //    - rechargePixelEnergy(uint256 tokenId, uint256 amount): Manually add energy to a pixel.
    //
    // 6. Evolution Functions:
    //    - evolvePixel(uint256 tokenId): Trigger evolution for a single pixel (anyone can call).
    //    - evolveBatch(uint256[] calldata tokenIds): Trigger evolution for multiple pixels (anyone can call).
    //    - getEnergyReplenishAmount(uint256 lastEvolvedTime): Calculate energy replenished since last evolution.
    //
    // 7. Query Functions:
    //    - getPixelState(uint256 tokenId): Get full state data for a pixel.
    //    - getPixelColor(uint256 tokenId): Get just the color.
    //    - getPixelEnergy(uint256 tokenId): Get just the energy.
    //    - getEvolutionRule(uint16 ruleId): Get the definition of an evolution rule.
    //    - isPixelClaimed(uint256 x, uint256 y): Check if a pixel is minted.
    //    - getTotalPixels(): Get total number of pixels on the canvas.
    //    - getClaimedPixelsCount(): Get number of minted pixels.
    //    - getRuleCount(): Get number of defined evolution rules.
    //
    // 8. Admin & Configuration Functions:
    //    - setCanvasSize(uint256 newWidth, uint256 newHeight): Resize canvas (careful: potential state issues if shrinking).
    //    - defineEvolutionRule(uint16 ruleId, uint32 colorTransformFactor, uint16 energyDecayFactor, uint64 minEvolutionInterval, string memory description): Define or update an evolution rule.
    //    - setPixelStateAdmin(uint256 tokenId, uint32 color, uint256 energy, uint16 ruleId, uint64 lastEvolvedTime): Force set pixel state (powerful, for maintenance).
    //    - setMintPrice(uint256 price): Set the cost to mint a pixel.
    //    - setDrawCost(uint256 cost): Set the cost to change pixel color.
    //    - setEvolutionReward(uint256 reward): Set the reward for calling evolvePixel/evolveBatch.
    //    - setEnergyRechargeRate(uint256 rate): Set how quickly energy replenishes per second.
    //    - withdrawFees(address payable recipient): Withdraw collected fees.
    //    - pause(): Pause core interactions (mint, draw, evolve).
    //    - unpause(): Unpause core interactions.
    //    - setBaseURI(string memory baseURI_): Set the base URI for token metadata.
    //
    // Total >= 20 unique external/public functions: Yes.

    // --- STATE VARIABLES ---

    // Canvas dimensions
    uint256 public canvasWidth;
    uint256 public canvasHeight;

    // Pixel data: color (RGBA, 4 bytes), energy (arbitrary units), rule ID, last evolved timestamp
    struct PixelState {
        uint32 color; // e.g., 0xAABBCCDD (AA=Red, BB=Green, CC=Blue, DD=Alpha)
        uint256 energy; // Represents potential for evolution or actions
        uint16 ruleId;   // ID of the evolution rule governing this pixel
        uint64 lastEvolvedTime; // Unix timestamp when pixel last evolved or state was set
    }
    mapping(uint256 => PixelState) private pixelStates; // token ID => PixelState

    // Evolution rules: color transformation parameters, energy decay, minimum evolution interval
    struct EvolutionRule {
        uint32 colorTransformFactor; // Parameter for color calculation in evolution
        uint16 energyDecayFactor;    // How much energy is consumed/lost per evolution
        uint64 minEvolutionInterval; // Minimum time in seconds between evolutions for this rule
        string description;          // Human-readable description of the rule
        bool defined;                // True if this ruleId is defined
    }
    mapping(uint16 => EvolutionRule) private evolutionRules; // rule ID => EvolutionRule
    Counters.Counter private _ruleIds;

    // Configuration parameters
    uint256 public mintPrice;
    uint256 public drawCost;         // Cost to set pixel color
    uint256 public evolutionReward;  // Reward for calling evolvePixel/evolveBatch
    uint256 public energyRechargeRate; // Energy units replenished per second per pixel

    // Paused state
    bool public paused = false;

    // Token counter
    Counters.Counter private _tokenIdCounter;

    // --- EVENTS ---

    event PixelMinted(address indexed owner, uint256 indexed tokenId, uint256 x, uint256 y);
    event PixelColorSet(uint256 indexed tokenId, uint32 oldColor, uint32 newColor);
    event PixelStateChanged(uint256 indexed tokenId, uint32 newColor, uint256 newEnergy, uint16 newRuleId);
    event EvolutionRuleDefined(uint16 indexed ruleId, uint32 colorTransformFactor, uint16 energyDecayFactor, uint64 minEvolutionInterval, string description);
    event PixelRuleSet(uint256 indexed tokenId, uint16 oldRuleId, uint16 newRuleId);
    event EnergyRecharged(uint256 indexed tokenId, uint256 amount, uint256 newEnergy);
    event CanvasResized(uint256 oldWidth, uint256 oldHeight, uint256 newWidth, uint256 newHeight);
    event ConfigUpdated(string configName, uint256 oldValue, uint256 newValue); // Generic config update
    event Paused(address account);
    event Unpaused(address account);

    // --- MODIFIERS ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyPixelOwner(uint256 tokenId) {
        require(_exists(tokenId) && ownerOf(tokenId) == _msgSender(), "Caller is not pixel owner");
        _;
    }

    modifier isValidCoords(uint256 x, uint256 y) {
        require(x < canvasWidth && y < canvasHeight, "Invalid coordinates");
        _;
    }

    modifier isValidRuleId(uint16 ruleId) {
        require(evolutionRules[ruleId].defined, "Invalid ruleId");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(uint256 initialWidth, uint256 initialHeight, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(initialWidth > 0 && initialHeight > 0, "Canvas dimensions must be positive");
        canvasWidth = initialWidth;
        canvasHeight = initialHeight;

        // Define a default rule (ruleId 0)
        _ruleIds.increment(); // Rule ID 1 will be the first defined rule
        defineEvolutionRule(0, 0x01010101, 1, 1 seconds, "Default static rule (slow decay)"); // Example default
    }

    // --- INTERNAL UTILITIES ---

    /**
     * @dev Converts coordinates (x, y) to a unique token ID.
     * Uses row-major mapping: tokenId = y * width + x
     */
    function _coordsToTokenId(uint256 x, uint256 y) internal view returns (uint256) {
        require(x < canvasWidth && y < canvasHeight, "Coordinates out of bounds");
        return y * canvasWidth + x;
    }

    /**
     * @dev Converts a token ID back to coordinates (x, y).
     */
    function _tokenIdToCoords(uint256 tokenId) internal view returns (uint256 x, uint256 y) {
        require(tokenId < canvasWidth * canvasHeight, "Token ID out of bounds");
        x = tokenId % canvasWidth;
        y = tokenId / canvasWidth;
    }

    // --- ERC721 REQUIRED OVERRIDES ---

    // The following functions are required for ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- CORE PIXEL MANAGEMENT ---

    /**
     * @dev Mints a new pixel NFT at specified coordinates.
     * Requires payment of mintPrice. Pixel gets initial state.
     */
    function mintPixel(uint256 x, uint256 y)
        external
        payable
        whenNotPaused
        isValidCoords(x, y)
    {
        uint256 tokenId = _coordsToTokenId(x, y);
        require(!_exists(tokenId), "Pixel already claimed");
        require(msg.value >= mintPrice, "Insufficient funds for minting");

        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();

        // Initialize pixel state
        pixelStates[tokenId] = PixelState({
            color: 0x000000FF, // Default initial color (black with full alpha)
            energy: 1000,      // Starting energy
            ruleId: 0,         // Default rule
            lastEvolvedTime: uint64(block.timestamp) // Initialize timestamp
        });

        if (msg.value > mintPrice) {
            // Refund excess payment
            payable(msg.sender).transfer(msg.value - mintPrice);
        }

        emit PixelMinted(msg.sender, tokenId, x, y);
        emit PixelStateChanged(tokenId, pixelStates[tokenId].color, pixelStates[tokenId].energy, pixelStates[tokenId].ruleId);
    }

    /**
     * @dev Sets the color of an owned pixel.
     * Requires payment of drawCost and potentially energy.
     */
    function setPixelColor(uint256 tokenId, uint32 color)
        external
        payable
        whenNotPaused
        onlyPixelOwner(tokenId)
    {
        require(msg.value >= drawCost, "Insufficient funds for drawing");
        // Add energy consumption for drawing later if needed, check pixelStates[tokenId].energy

        uint32 oldColor = pixelStates[tokenId].color;
        pixelStates[tokenId].color = color;

        // Update timestamp as owner action "observes" and potentially resets some evolution clock
        pixelStates[tokenId].lastEvolvedTime = uint64(block.timestamp);

        if (msg.value > drawCost) {
            payable(msg.sender).transfer(msg.value - drawCost);
        }

        emit PixelColorSet(tokenId, oldColor, color);
        emit PixelStateChanged(tokenId, pixelStates[tokenId].color, pixelStates[tokenId].energy, pixelStates[tokenId].ruleId);
    }

    /**
     * @dev Sets the evolution rule for an owned pixel.
     * Requires energy or a cost.
     */
    function setPixelRule(uint256 tokenId, uint16 ruleId)
        external
        whenNotPaused
        onlyPixelOwner(tokenId)
        isValidRuleId(ruleId)
    {
        // Could add energy cost or ETH cost here
        // require(pixelStates[tokenId].energy >= ruleChangeEnergyCost, "Insufficient pixel energy");

        uint16 oldRuleId = pixelStates[tokenId].ruleId;
        pixelStates[tokenId].ruleId = ruleId;

        // Update timestamp as state was modified
        pixelStates[tokenId].lastEvolvedTime = uint64(block.timestamp);

        emit PixelRuleSet(tokenId, oldRuleId, ruleId);
        emit PixelStateChanged(tokenId, pixelStates[tokenId].color, pixelStates[tokenId].energy, pixelStates[tokenId].ruleId);
    }

    /**
     * @dev Allows the owner to manually recharge a pixel's energy.
     * Could potentially require payment or a resource.
     */
    function rechargePixelEnergy(uint256 tokenId, uint256 amount)
        external
        whenNotPaused
        onlyPixelOwner(tokenId)
    {
        require(amount > 0, "Recharge amount must be positive");
        // Could add cost: require(msg.value >= energyRechargeCost(amount), "Insufficient funds");

        pixelStates[tokenId].energy += amount;

        // Optional: Update timestamp if recharge impacts evolution timing / energy decay model
        // pixelStates[tokenId].lastEvolvedTime = uint64(block.timestamp);

        emit EnergyRecharged(tokenId, amount, pixelStates[tokenId].energy);
        emit PixelStateChanged(tokenId, pixelStates[tokenId].color, pixelStates[tokenId].energy, pixelStates[tokenId].ruleId);
    }


    // --- EVOLUTION MECHANISMS ---

    /**
     * @dev Calculates the energy replenished for a pixel based on time elapsed.
     */
    function getEnergyReplenishAmount(uint64 lastEvolvedTime) internal view returns (uint256) {
        uint64 timeElapsed = block.timestamp > lastEvolvedTime ? block.timestamp - lastEvolvedTime : 0;
        // Simple linear replenishment: time * rate
        // Could add cap: return Math.min(timeElapsed * energyRechargeRate, maxEnergyCap - currentEnergy);
        return uint256(timeElapsed) * energyRechargeRate;
    }

    /**
     * @dev Evolves a single pixel's state based on its rule and time elapsed.
     * Anyone can call this function to trigger evolution.
     * The caller receives a small reward (paid by the contract).
     */
    function evolvePixel(uint256 tokenId)
        external
        whenNotPaused
        payable // Allow caller to cover potential gas, though reward is sent later
    {
        // Ensure pixel exists
        require(_exists(tokenId), "Pixel does not exist");

        PixelState storage pixel = pixelStates[tokenId];
        EvolutionRule storage rule = evolutionRules[pixel.ruleId];

        // Check if enough time has passed for this rule
        require(block.timestamp >= pixel.lastEvolvedTime + rule.minEvolutionInterval, "Evolution interval not met");

        // --- Evolution Logic ---
        // Add replenished energy
        pixel.energy += getEnergyReplenishAmount(pixel.lastEvolvedTime);

        // Check if pixel has enough energy to evolve
        require(pixel.energy >= rule.energyDecayFactor, "Insufficient energy to evolve");

        // Apply energy decay
        pixel.energy -= rule.energyDecayFactor;

        // Apply rule's color transformation - Example: Simple XOR with a factor
        pixel.color = pixel.color ^ rule.colorTransformFactor;

        // Update timestamp
        pixel.lastEvolvedTime = uint64(block.timestamp);

        // --- Reward Caller ---
        // Send the evolution reward to the caller
        if (evolutionReward > 0) {
             // Check balance before transfer to avoid running out of funds mid-batch
            require(address(this).balance >= evolutionReward, "Contract has insufficient funds for reward");
            payable(msg.sender).transfer(evolutionReward);
        }


        // --- Emit Event ---
        emit PixelStateChanged(tokenId, pixel.color, pixel.energy, pixel.ruleId);
        // Note: PixelColorSet is not emitted here as color changed via evolution, not owner setting
    }

    /**
     * @dev Triggers evolution for a batch of pixels.
     * Anyone can call this. Useful for off-chain bots/keepers to maintain the canvas state.
     * Caller receives a reward for each pixel successfully evolved.
     * IMPORTANT: Be mindful of gas limits for batch size.
     */
    function evolveBatch(uint256[] calldata tokenIds)
        external
        whenNotPaused
        payable // Allow caller to cover potential gas
    {
        uint256 successfulEvolutions = 0;
        uint256 totalReward = 0;

        // Check if contract has enough balance for potential maximum reward
        require(address(this).balance >= evolutionReward * tokenIds.length, "Contract has insufficient funds for batch rewards");


        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            // Use try-catch to allow batch to continue even if one pixel fails (e.g., not enough time, insufficient energy)
            try this.evolvePixel(tokenId) {
                // If evolvePixel succeeds internally (including its require checks),
                // it will transfer the reward and emit the event.
                successfulEvolutions++;
                totalReward += evolutionReward; // Note: The reward is transferred *inside* evolvePixel now.
                                                // We just count for a potential summary event (not implemented here)
            } catch Error(string memory reason) {
                // Optionally log failed evolution with reason
                // emit EvolutionFailed(tokenId, reason);
            } catch {
                // Optionally log unknown evolution failure
                // emit EvolutionFailed(tokenId, "Unknown error");
            }
        }

        // Note: Rewards are transferred within the try-catch block in evolvePixel.
        // No need for a separate reward transfer here for *successful* evolutions.
        // You might add a refund for any remaining msg.value if payable.
    }


    // --- RULE MANAGEMENT (ADMIN ONLY) ---

    /**
     * @dev Defines or updates an evolution rule. Admin function.
     * Rule ID 0 is reserved for the default static rule.
     * colorTransformFactor: How the color changes (e.g., used in XOR, add, multiply logic).
     * energyDecayFactor: Energy consumed by this rule's evolution.
     * minEvolutionInterval: Minimum time (seconds) between evolutions for this rule.
     */
    function defineEvolutionRule(
        uint16 ruleId,
        uint32 colorTransformFactor,
        uint16 energyDecayFactor,
        uint64 minEvolutionInterval,
        string memory description
    )
        external
        onlyOwner
    {
        require(ruleId != 0, "Rule ID 0 is reserved for the default rule"); // Rule 0 is set in constructor
        // If ruleId > 0 and not yet defined, increment rule counter
        if (ruleId > 0 && !evolutionRules[ruleId].defined) {
             // Ensure ruleId is the next available, or allow defining arbitrary IDs?
             // Allowing arbitrary IDs is more flexible, but needs care. Let's allow for now.
             // Potentially update _ruleIds counter if a high ID is set? Or just use it as a max?
             // Let's use the counter just for queryable 'next available ID', mapping is authoritative.
             if (ruleId >= _ruleIds.current()) {
                 _ruleIds.add(ruleId - _ruleIds.current() + 1);
             }
        }


        evolutionRules[ruleId] = EvolutionRule({
            colorTransformFactor: colorTransformFactor,
            energyDecayFactor: energyDecayFactor,
            minEvolutionInterval: minEvolutionInterval,
            description: description,
            defined: true
        });

        emit EvolutionRuleDefined(ruleId, colorTransformFactor, energyDecayFactor, minEvolutionInterval, description);
    }

    // --- ADMIN & CONFIGURATION (ADMIN ONLY) ---

    /**
     * @dev Sets the canvas dimensions. Use with extreme caution, especially when shrinking.
     * Shrinking can make some token IDs invalid/inaccessible.
     */
    function setCanvasSize(uint256 newWidth, uint256 newHeight)
        external
        onlyOwner
    {
        require(newWidth > 0 && newHeight > 0, "Canvas dimensions must be positive");
        // Add checks if shrinking would invalidate existing tokens if needed
        // require(newWidth * newHeight >= _tokenIdCounter.current(), "New size is smaller than current token count");

        uint256 oldWidth = canvasWidth;
        uint256 oldHeight = canvasHeight;
        canvasWidth = newWidth;
        canvasHeight = newHeight;

        // Note: This does NOT automatically relocate existing pixels or delete overflowed ones.
        // Management of pixels outside the new bounds would need separate functions or manual admin intervention.

        emit CanvasResized(oldWidth, oldHeight, newWidth, newHeight);
    }

    /**
     * @dev Admin function to force set the state of a pixel. Useful for maintenance or initial setup.
     */
    function setPixelStateAdmin(
        uint256 tokenId,
        uint32 color,
        uint256 energy,
        uint16 ruleId,
        uint64 lastEvolvedTime
    )
        external
        onlyOwner
    {
        require(_exists(tokenId), "Pixel does not exist");
        require(evolutionRules[ruleId].defined, "Invalid ruleId");

        pixelStates[tokenId] = PixelState({
            color: color,
            energy: energy,
            ruleId: ruleId,
            lastEvolvedTime: lastEvolvedTime
        });

         emit PixelStateChanged(tokenId, color, energy, ruleId);
    }

    /**
     * @dev Sets the price to mint a new pixel.
     */
    function setMintPrice(uint256 price) external onlyOwner {
        emit ConfigUpdated("mintPrice", mintPrice, price);
        mintPrice = price;
    }

    /**
     * @dev Sets the cost to change a pixel's color.
     */
    function setDrawCost(uint256 cost) external onlyOwner {
        emit ConfigUpdated("drawCost", drawCost, cost);
        drawCost = cost;
    }

    /**
     * @dev Sets the reward paid to callers of evolvePixel/evolveBatch per pixel.
     */
    function setEvolutionReward(uint256 reward) external onlyOwner {
        emit ConfigUpdated("evolutionReward", evolutionReward, reward);
        evolutionReward = reward;
    }

    /**
     * @dev Sets the rate at which pixel energy replenishes per second.
     */
    function setEnergyRechargeRate(uint256 rate) external onlyOwner {
        emit ConfigUpdated("energyRechargeRate", energyRechargeRate, rate);
        energyRechargeRate = rate;
    }


    /**
     * @dev Withdraws collected fees (mint price, draw cost).
     * Evolution rewards are paid out immediately from the contract's balance.
     */
    function withdrawFees(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        // Note: This withdraws ALL contract balance. Be careful if balance is used for rewards.
        // A more robust approach might track explicit fee revenue vs funds for rewards.
        // For this example, assuming reward funds are sent separately or balance management is external.
        // Alternatively, ensure reward funds are maintained separately or track fees explicitly.
        // Let's assume collected fees are distinct from reward funds for simplicity here.
        // In a real scenario, you'd likely need a dedicated treasury/accounting.
        payable(recipient).transfer(balance);
    }

    /**
     * @dev Pauses the contract, preventing minting, drawing, and evolution.
     */
    function pause() external onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Unpauses the contract, re-enabling core functionality.
     */
    function unpause() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev See {ERC721URIStorage-setBaseURI}. Standard ERC721 function.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
         _setBaseURI(baseURI_); // Inherited from ERC721
    }

    // --- QUERY FUNCTIONS ---

    /**
     * @dev Gets the full state data for a pixel.
     */
    function getPixelState(uint256 tokenId)
        public
        view
        returns (uint32 color, uint256 energy, uint16 ruleId, uint64 lastEvolvedTime)
    {
        require(_exists(tokenId), "Pixel does not exist");
        PixelState storage pixel = pixelStates[tokenId];
        return (pixel.color, pixel.energy, pixel.ruleId, pixel.lastEvolvedTime);
    }

    /**
     * @dev Gets just the color of a pixel.
     */
    function getPixelColor(uint256 tokenId) public view returns (uint32) {
        require(_exists(tokenId), "Pixel does not exist");
        return pixelStates[tokenId].color;
    }

     /**
     * @dev Gets just the energy of a pixel, including potential replenishment since last interaction.
     */
    function getPixelEnergy(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Pixel does not exist");
        PixelState storage pixel = pixelStates[tokenId];
        uint256 replenished = getEnergyReplenishAmount(pixel.lastEvolvedTime);
        return pixel.energy + replenished;
    }


    /**
     * @dev Gets the definition of an evolution rule.
     */
    function getEvolutionRule(uint16 ruleId)
        public
        view
        returns (uint32 colorTransformFactor, uint16 energyDecayFactor, uint64 minEvolutionInterval, string memory description, bool defined)
    {
        EvolutionRule storage rule = evolutionRules[ruleId];
        return (rule.colorTransformFactor, rule.energyDecayFactor, rule.minEvolutionInterval, rule.description, rule.defined);
    }

    /**
     * @dev Checks if a pixel at given coordinates has been claimed/minted.
     */
    function isPixelClaimed(uint256 x, uint256 y)
        public
        view
        isValidCoords(x, y)
        returns (bool)
    {
        uint256 tokenId = _coordsToTokenId(x, y);
        return _exists(tokenId);
    }

    /**
     * @dev Gets the total number of possible pixels on the canvas based on dimensions.
     */
    function getTotalPixels() public view returns (uint256) {
        return canvasWidth * canvasHeight;
    }

     /**
     * @dev Gets the current number of claimed/minted pixels.
     */
    function getClaimedPixelsCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Gets the total number of defined evolution rules (including rule 0).
     */
    function getRuleCount() public view returns (uint16) {
        return uint16(_ruleIds.current()); // Or based on mapping iteration if IDs aren't contiguous
    }

    // --- ERC721 METADATA ---
    // Note: tokenURI should ideally return a URL pointing to dynamic metadata
    // server that fetches the pixel state via getPixelState and generates
    // the JSON metadata on the fly, potentially including an image representation.

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        // Append token ID and potentially a query param for current state cache busting if needed
        // return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        // A dynamic URI might look like: baseURI + tokenId + "/metadata"
        // Or include state hash: baseURI + tokenId + "?stateHash=" + keccak256(abi.encodePacked(getPixelState(tokenId)))
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), "/metadata"));
    }

    // --- Fallback to receive Ether ---
    receive() external payable {}
    fallback() external payable {}

    // --- Other potential functions (not strictly required for the 20+ count, but good ideas) ---
    // - transferPixelEnergy: Allow transferring energy between owned pixels.
    // - burnPixel: Allow owner to destroy a pixel NFT.
    // - setPixelMetadataURI: Allow owner to set a specific metadata URI for their pixel (overriding baseURI).
    // - bulkSetPixelColor: Allow owner to set color for multiple owned pixels (batch gas).
    // - createRandomRule: Admin function to generate a rule based on a seed.
    // - getPixelsInRect: Query function to get states of pixels within a bounding box.
    // - getPixelsByOwner: Get all token IDs owned by a specific address (ERC721Enumerable helps, but iterate carefully).
    // - setRuleEnabled: Admin function to temporarily disable a rule.
    // - Rule dependency logic: Modify evolutionRule struct to reference other rules or neighbor states (gas intensive).
    // - On-chain random number generation for evolution (e.g., using Chainlink VRF - adds complexity/dependencies).
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFTs (dNFTs):** Each pixel is an NFT whose state (`color`, `energy`, `ruleId`) is stored and can change directly on-chain. This isn't just metadata pointing to an external source; the core properties evolve within the contract itself.
2.  **On-Chain State Evolution:** The `evolvePixel` function contains logic that modifies the pixel's state (`color`, `energy`) based on its `ruleId` and time elapsed. This makes the art/state generative and time-dependent.
3.  **Configurable On-Chain Rules:** The `EvolutionRule` struct and `defineEvolutionRule` function allow the contract owner (or potentially a DAO in a future version) to define complex rules that govern how different pixels evolve. This allows for diverse and changing generative patterns on the canvas. Rule 0 acts as a static default.
4.  **Decentralized Execution Incentive:** The `evolvePixel` and `evolveBatch` functions can be called by *anyone*. The caller is rewarded with Ether (or potentially another token) from the contract's balance. This incentivizes users or bots ("keepers") to execute the evolution logic regularly, preventing the canvas from becoming stagnant and distributing the computational burden.
5.  **Energy System:** The `energy` variable and `energyRechargeRate` introduce a resource system for pixels. Evolution consumes energy (`energyDecayFactor`), and energy replenishes over time. This adds a constraint and dynamic element to how often and how much a pixel can evolve. Manual `rechargePixelEnergy` adds an owner interaction point.
6.  **Coordinate-Mapped Tokens:** Token IDs are directly mapped to (x, y) coordinates on the canvas (`_coordsToTokenId`, `_tokenIdToCoords`). This provides a clear spatial relationship for the NFTs.
7.  **Batch Processing:** `evolveBatch` allows triggering evolution for multiple pixels in a single transaction, improving efficiency for keepers, though batch size is limited by gas.
8.  **Metaphorical "Quantum" State:** The "quantum" aspect is represented by the pixel's potential energy and rule. Unless "observed" (state modified by owner or evolved by the function), its future state is determined by these internal parameters and the passage of time, evolving semi-autonomously. Owner actions or explicit evolution steps collapse (or update) this potential towards a new concrete state and timestamp.

This contract goes beyond standard token or NFT examples by incorporating dynamic state, on-chain logic for state changes, configurable generative rules, and an incentive mechanism for decentralized upkeep. The canvas itself becomes a living, evolving entity influenced by time, rules, and user interaction.