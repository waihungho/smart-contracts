Okay, let's design a smart contract system that's a bit different from standard patterns. We'll create a system around dynamic, stateful assets called "Aetherial Relics" that require ongoing interaction and resource management, tied to a utility token "Essence".

The concept involves:
1.  **Essence ($ESS):** A non-standard internal balance token (for simplicity, not a full ERC-20 to avoid duplication, but representing a resource).
2.  **Aetherial Relics:** Dynamic NFTs (ERC-721 based) with mutable properties like Level and Entropy.
3.  **Entropy:** A decaying state on Relics that increases over time and with specific actions (like upgrading). High Entropy degrades the Relic's effectiveness (e.g., Power Score) and needs to be managed by "Stabilizing" the Relic using Essence.
4.  **Power Score:** A calculated value for each Relic based on its Level and current Entropy, representing its utility or value within the system.
5.  **Actions:** Users can Forge new Relics (costing Essence), Upgrade Relics (increasing Level but also Entropy, costing Essence), Stabilize Relics (reducing Entropy, costing Essence), and manage their Essence.

This design incorporates concepts like state decay, resource sinks, dynamic metadata representation (via `tokenURI`), and interaction-driven asset modification.

---

**Outline: Aetherium Forge Contract**

1.  **Overview:** A system for forging, managing, and interacting with dynamic NFT assets (Aetherial Relics) using a resource token (Essence). Relics have mutable state (Level, Entropy) which affects their computed Power Score.
2.  **Components:**
    *   **Essence Balances:** Internal mapping tracking user balances of the Essence resource.
    *   **Aetherial Relics:** ERC-721 compliant NFTs with attached mutable state (struct).
    *   **Parameters:** Configurable costs and rates (e.g., forging cost, upgrade cost, entropy rate, stabilization efficiency).
3.  **Core State:**
    *   Mapping from token ID to Relic state data.
    *   Mapping from address to Essence balance.
    *   Global counter for total minted Relics.
    *   Configurable system parameters.
4.  **Key Operations:**
    *   Essence Management (Minting/Burning/Transferring internal balance).
    *   Relic Lifecycle (Forging, Upgrading, Stabilizing, Burning).
    *   Relic State Querying (Get state, calculate derived properties like Power Score and current Entropy).
    *   ERC-721 Standard Operations (Transfer, Approval, Ownership).
    *   Parameter Administration (Setting costs and rates by owner).

---

**Function Summary**

This contract implements a system with the following functionalities, ensuring well over 20 distinct functions:

**ERC-721 Standard Functions (Inherited/Overridden for Relics):**
1.  `balanceOf(address owner) view returns (uint256)`: Returns the number of Relics owned by an address.
2.  `ownerOf(uint256 tokenId) view returns (address)`: Returns the owner of a specific Relic.
3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers a Relic, checking if recipient can receive.
4.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a Relic (less safe version).
5.  `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific Relic.
6.  `getApproved(uint256 tokenId) view returns (address)`: Returns the approved address for a specific Relic.
7.  `setApprovalForAll(address operator, bool approved)`: Approves or disapproves an operator for all owner's Relics.
8.  `isApprovedForAll(address owner, address operator) view returns (bool)`: Checks if an operator is approved for all owner's Relics.
9.  `supportsInterface(bytes4 interfaceId) view returns (bool)`: Standard ERC-165 interface support check.
10. `tokenURI(uint256 tokenId) view returns (string)`: Returns the dynamic metadata URI for a Relic, incorporating its current state.

**ERC-721 Enumerable Functions (Inherited):**
11. `totalSupply() view returns (uint256)`: Returns the total number of Relics in existence.
12. `tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)`: Returns a Relic's token ID by index for a given owner.
13. `tokenByIndex(uint256 index) view returns (uint256)`: Returns a Relic's token ID by index across all tokens.

**Essence Management (Internal Balance Tracking):**
14. `mintEssence(uint256 amount)`: Allows the contract owner (or a designated minter role) to create new Essence and assign it to a balance (simplified faucet for demonstration).
15. `transferEssence(address recipient, uint256 amount)`: Allows users to transfer their internal Essence balance to another address.
16. `getEssenceBalance(address account) view returns (uint256)`: Returns the Essence balance of an address.

**Aetherial Relic Management:**
17. `forgeRelic(address recipient, uint8 relicType)`: Forges a new Relic of a specified type for the recipient, consuming Essence.
18. `upgradeRelic(uint256 tokenId)`: Upgrades a Relic's level, consuming Essence and increasing its base Entropy.
19. `stabilizeRelic(uint256 tokenId)`: Reduces a Relic's current Entropy, consuming Essence.
20. `burnRelic(uint256 tokenId)`: Burns a Relic, removing it from existence (might have an associated cost/refund).

**Aetherial Relic State Querying (Custom Logic):**
21. `getRelicState(uint256 tokenId) view returns (uint256 level, uint256 baseEntropy, uint256 lastInteractionTime, uint8 relicType)`: Returns the raw stored state of a Relic.
22. `calculateCurrentEntropy(uint256 tokenId) view returns (uint256 currentEntropy)`: Calculates the effective Entropy of a Relic including time-based decay.
23. `calculatePowerScore(uint256 tokenId) view returns (uint256 powerScore)`: Calculates the Power Score of a Relic based on its level and *current* entropy.

**Parameter Administration (Owner Functions):**
24. `setBaseForgeCost(uint256 cost)`: Sets the base Essence cost for forging a new Relic.
25. `setUpgradeCostPerLevel(uint256 cost)`: Sets the additional Essence cost for each level when upgrading.
26. `setStabilizeCostPerPoint(uint256 cost)`: Sets the Essence cost per point of Entropy stabilized.
27. `setEntropyRatePerSecond(uint256 rate)`: Sets the rate at which Entropy decays per second.
28. `setBaseEntropyIncreasePerUpgrade(uint256 increase)`: Sets the amount of base Entropy added upon upgrading.
29. `setBaseURI(string baseURI)`: Sets the base URI for the dynamic metadata endpoint.

**Total Distinct Functions: 29**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Aetherium Forge
/// @author YourNameHere
/// @notice A smart contract system for managing dynamic NFT assets (Aetherial Relics)
///         with mutable state (Level, Entropy) tied to an internal Essence resource.
///         Entropy decays over time and increases upon upgrades, requiring stabilization.
///         A calculated Power Score reflects a Relic's current state.
///
/// Outline:
/// 1. Overview: System for dynamic NFTs (Aetherial Relics) and internal resource (Essence).
/// 2. Components: Essence Balances, Aetherial Relics (ERC-721 + state), Parameters.
/// 3. Core State: Relic data mapping, Essence balances mapping, Global counters, Config params.
/// 4. Key Operations: Essence Mgmt, Relic Lifecycle (Forge, Upgrade, Stabilize, Burn), Relic State Queries, ERC-721 standard, Parameter Admin.

/// Function Summary:
/// ERC-721 Standard Functions (Inherited/Overridden for Relics):
/// 1. balanceOf(address owner) view returns (uint256)
/// 2. ownerOf(uint256 tokenId) view returns (address)
/// 3. safeTransferFrom(address from, address to, uint256 tokenId)
/// 4. transferFrom(address from, address to, uint256 tokenId)
/// 5. approve(address to, uint256 tokenId)
/// 6. getApproved(uint256 tokenId) view returns (address)
/// 7. setApprovalForAll(address operator, bool approved)
/// 8. isApprovedForAll(address owner, address operator) view returns (bool)
/// 9. supportsInterface(bytes4 interfaceId) view returns (bool)
/// 10. tokenURI(uint256 tokenId) view returns (string) - Dynamic metadata

/// ERC-721 Enumerable Functions (Inherited):
/// 11. totalSupply() view returns (uint256)
/// 12. tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)
/// 13. tokenByIndex(uint256 index) view returns (uint256)

/// Essence Management (Internal Balance Tracking):
/// 14. mintEssence(uint256 amount)
/// 15. transferEssence(address recipient, uint256 amount)
/// 16. getEssenceBalance(address account) view returns (uint256)

/// Aetherial Relic Management:
/// 17. forgeRelic(address recipient, uint8 relicType)
/// 18. upgradeRelic(uint256 tokenId)
/// 19. stabilizeRelic(uint256 tokenId)
/// 20. burnRelic(uint256 tokenId)

/// Aetherial Relic State Querying (Custom Logic):
/// 21. getRelicState(uint256 tokenId) view returns (uint256 level, uint256 baseEntropy, uint256 lastInteractionTime, uint8 relicType)
/// 22. calculateCurrentEntropy(uint256 tokenId) view returns (uint256 currentEntropy)
/// 23. calculatePowerScore(uint256 tokenId) view returns (uint256 powerScore)

/// Parameter Administration (Owner Functions):
/// 24. setBaseForgeCost(uint256 cost)
/// 25. setUpgradeCostPerLevel(uint256 cost)
/// 26. setStabilizeCostPerPoint(uint256 cost)
/// 27. setEntropyRatePerSecond(uint256 rate)
/// 28. setBaseEntropyIncreasePerUpgrade(uint256 increase)
/// 29. setBaseURI(string baseURI)

contract AetheriumForge is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Custom Errors ---
    error InvalidTokenId();
    error NotRelicOwner();
    error InsufficientEssence();
    error InvalidRecipient();
    error InvalidAmount();
    error NotApprovedOrOwner();
    error InvalidRelicType();
    error MaximumLevelReached(uint256 currentLevel);
    error InsufficientEntropyToStabilize();

    // --- Enums ---
    enum RelicType {
        Amulet,
        Ring,
        Tome,
        Orb
        // Add more relic types as needed
    }

    // --- Structs ---
    struct RelicState {
        uint256 level;             // Level of the relic
        uint256 baseEntropy;       // Entropy accumulated through actions (upgrades)
        uint256 lastInteractionTime; // Timestamp of the last upgrade or stabilize action
        uint8 relicType;         // Type of the relic (corresponds to RelicType enum index)
    }

    // --- State Variables ---
    Counters.Counter private _nextTokenId;

    mapping(uint256 => RelicState) private _relics; // tokenId => RelicState
    mapping(address => uint256) private _essenceBalances; // owner => essence balance

    uint256 public baseForgeCost = 100; // Essence cost to forge a new relic
    uint256 public upgradeCostPerLevel = 50; // Additional Essence cost per level for upgrading
    uint256 public stabilizeCostPerPoint = 1; // Essence cost per point of Entropy stabilized
    uint256 public entropyRatePerSecond = 1; // How much Entropy decays per second
    uint256 public baseEntropyIncreasePerUpgrade = 100; // How much base Entropy increases upon upgrade
    uint256 public maxRelicLevel = 10; // Maximum level a relic can reach

    string private _baseTokenURI; // Base URI for metadata endpoint

    // --- Events ---
    event EssenceMinted(address indexed account, uint256 amount);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event RelicForged(address indexed owner, uint256 indexed tokenId, uint8 relicType, uint256 initialLevel);
    event RelicUpgraded(uint256 indexed tokenId, uint256 newLevel, uint256 essenceSpent, uint256 entropyIncrease);
    event RelicStabilized(uint256 indexed tokenId, uint256 essenceSpent, uint256 entropyReduced);
    event RelicBurned(uint256 indexed tokenId, address indexed owner);
    event ParameterUpdated(string name, uint256 newValue);
    event BaseURIUpdated(string baseURI);


    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Initial parameters can be set here or via admin functions
        // e.g., baseForgeCost = 100;
    }

    // --- Internal Helpers ---

    /// @dev Safely subtracts essence from an account's balance.
    function _burnEssence(address account, uint256 amount) internal {
        if (_essenceBalances[account] < amount) {
            revert InsufficientEssence();
        }
        unchecked {
            _essenceBalances[account] -= amount;
        }
    }

    /// @dev Safely adds essence to an account's balance.
    function _mintEssence(address account, uint256 amount) internal {
         if (account == address(0)) revert InvalidRecipient();
         if (amount == 0) revert InvalidAmount(); // Prevent minting zero

        unchecked {
            _essenceBalances[account] += amount;
        }
    }

    /// @dev Internal function to get a relic's state, including calculating current entropy.
    function _getRelicState(uint256 tokenId) internal view returns (RelicState memory state, uint256 currentEntropy) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        state = _relics[tokenId];
        currentEntropy = _calculateCurrentEntropy(state);
    }

    /// @dev Internal function to calculate the current entropy of a relic struct state.
    function _calculateCurrentEntropy(RelicState memory state) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - state.lastInteractionTime;
        uint256 decay = timeElapsed * entropyRatePerSecond;
        return state.baseEntropy > decay ? state.baseEntropy - decay : 0;
    }

    /// @dev Internal function to update relic state and last interaction time.
    function _updateRelicState(uint256 tokenId, uint256 newLevel, uint256 newBaseEntropy) internal {
        RelicState storage state = _relics[tokenId];
        state.level = newLevel;
        state.baseEntropy = newBaseEntropy;
        state.lastInteractionTime = block.timestamp;
    }

    /// @dev Internal function to check if the caller is the owner or approved for the token.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    // --- ERC-721 Overrides ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        RelicState memory state = _relics[tokenId];
        uint256 currentEntropy = _calculateCurrentEntropy(state);
        uint256 powerScore = calculatePowerScore(tokenId); // Use public view function

        // Construct a dynamic URI (e.g., pointing to a service that generates JSON metadata)
        // Example format: baseURI/tokenId?level=X&entropy=Y&power=Z&type=T
        // This is a simplified example; a real implementation would use a dedicated metadata service.
        string memory dynamicParams = string(abi.encodePacked(
            "?level=", state.level.toString(),
            "&entropy=", currentEntropy.toString(),
            "&power=", powerScore.toString(),
            "&type=", state.relicType.toString()
        ));

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), dynamicParams));
    }

    // Override _beforeTokenTransfer to potentially handle logic pre/post transfer (not strictly needed for this design)
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // --- Essence Management ---

    /// @notice Allows the contract owner to mint new Essence. (Simple faucet model for testing)
    /// @param amount The amount of Essence to mint.
    function mintEssence(address recipient, uint256 amount) external onlyOwner {
        _mintEssence(recipient, amount);
        emit EssenceMinted(recipient, amount);
    }

    /// @notice Allows a user to transfer their internal Essence balance.
    /// @param recipient The address to transfer Essence to.
    /// @param amount The amount of Essence to transfer.
    function transferEssence(address recipient, uint256 amount) external {
         if (recipient == address(0)) revert InvalidRecipient();
         if (amount == 0) revert InvalidAmount(); // Prevent transferring zero

        _burnEssence(msg.sender, amount);
        _mintEssence(recipient, amount); // Use _mintEssence to add to recipient balance
        emit EssenceTransferred(msg.sender, recipient, amount);
    }

    /// @notice Gets the Essence balance for an account.
    /// @param account The address to query.
    /// @return The Essence balance.
    function getEssenceBalance(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    // --- Aetherial Relic Management ---

    /// @notice Forges a new Aetherial Relic.
    /// @dev Burns Essence, mints a new ERC-721 token, initializes its state.
    /// @param recipient The address to receive the new Relic.
    /// @param relicType The type of Relic to forge (0=Amulet, 1=Ring, etc.).
    function forgeRelic(address recipient, uint8 relicType) external {
        if (recipient == address(0)) revert InvalidRecipient();
        if (relicType >= uint8(RelicType.Orb) + 1) revert InvalidRelicType(); // Check against enum bounds

        _burnEssence(msg.sender, baseForgeCost);

        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(recipient, newTokenId); // Mints the ERC-721 token

        // Initialize relic state
        _relics[newTokenId] = RelicState({
            level: 1,
            baseEntropy: 0,
            lastInteractionTime: block.timestamp,
            relicType: relicType
        });

        emit RelicForged(recipient, newTokenId, relicType, 1);
    }

    /// @notice Upgrades an Aetherial Relic's level.
    /// @dev Burns Essence, increases Relic level and base Entropy, updates interaction time.
    /// @param tokenId The ID of the Relic to upgrade.
    function upgradeRelic(uint256 tokenId) external {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (ownerOf(tokenId) != msg.sender && !_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();

        RelicState storage state = _relics[tokenId];
        if (state.level >= maxRelicLevel) revert MaximumLevelReached(state.level);

        uint256 cost = baseForgeCost + state.level * upgradeCostPerLevel; // Example scaling cost
        _burnEssence(msg.sender, cost);

        uint256 newLevel = state.level + 1;
        uint256 newBaseEntropy = state.baseEntropy + baseEntropyIncreasePerUpgrade; // Increase base entropy

        _updateRelicState(tokenId, newLevel, newBaseEntropy);

        emit RelicUpgraded(tokenId, newLevel, cost, baseEntropyIncreasePerUpgrade);
    }

    /// @notice Stabilizes an Aetherial Relic, reducing its current Entropy.
    /// @dev Burns Essence, reduces effective Entropy by updating interaction time.
    /// @param tokenId The ID of the Relic to stabilize.
    function stabilizeRelic(uint256 tokenId) external {
        if (!_exists(tokenId)) revert InvalidTokenId();
         if (ownerOf(tokenId) != msg.sender && !_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();

        RelicState memory currentState = _relics[tokenId];
        uint256 currentEntropy = _calculateCurrentEntropy(currentState);

        if (currentEntropy == 0) revert InsufficientEntropyToStabilize();

        // Calculate cost based on current entropy needing stabilization
        // Option 1: Stabilize partially/fully based on user input (more complex UI)
        // Option 2: Stabilize to 0 entropy (simpler, implemented here)
        uint256 stabilizationAmount = currentEntropy; // Stabilize all current entropy
        uint256 cost = stabilizationAmount * stabilizeCostPerPoint;

        _burnEssence(msg.sender, cost);

        // By updating the lastInteractionTime, the calculated current entropy effectively resets
        // to the *base* entropy + any entropy added since this action, minus new decay.
        // If stabilizing to 0 means setting baseEntropy to 0 and updating time:
        // For simplicity, we'll just update the time, which effectively resets the *decay calculation*.
        // The base entropy accumulated from upgrades remains, but the decay clock is reset.
        // A different approach would be to reduce the *base* entropy here. Let's reduce base entropy.
        uint256 newBaseEntropy = currentState.baseEntropy > stabilizationAmount ? currentState.baseEntropy - stabilizationAmount : 0;

        _updateRelicState(tokenId, currentState.level, newBaseEntropy);

        emit RelicStabilized(tokenId, cost, stabilizationAmount);
    }

    /// @notice Burns an Aetherial Relic, removing it from existence.
    /// @dev Burns Essence (optional cost), burns the ERC-721 token, removes state.
    /// @param tokenId The ID of the Relic to burn.
    function burnRelic(uint256 tokenId) external {
         if (!_exists(tokenId)) revert InvalidTokenId();
         if (ownerOf(tokenId) != msg.sender && !_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();

        // Optional: require Essence cost to burn
        // _burnEssence(msg.sender, burnCost);

        address owner = ownerOf(tokenId);
        _burn(tokenId); // Burns the ERC-721 token

        // Remove relic state
        delete _relics[tokenId];

        emit RelicBurned(tokenId, owner);
    }

    // --- Aetherial Relic State Querying ---

    /// @notice Gets the raw stored state data of a Relic.
    /// @param tokenId The ID of the Relic.
    /// @return level The stored level.
    /// @return baseEntropy The stored base entropy from actions.
    /// @return lastInteractionTime The timestamp of the last upgrade/stabilize.
    /// @return relicType The type of the relic (0-indexed enum).
    function getRelicState(uint256 tokenId) public view returns (uint256 level, uint256 baseEntropy, uint256 lastInteractionTime, uint8 relicType) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        RelicState memory state = _relics[tokenId];
        return (state.level, state.baseEntropy, state.lastInteractionTime, state.relicType);
    }

    /// @notice Calculates the current effective Entropy of a Relic, including time-based decay.
    /// @param tokenId The ID of the Relic.
    /// @return The current effective Entropy.
    function calculateCurrentEntropy(uint256 tokenId) public view returns (uint256 currentEntropy) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        RelicState memory state = _relics[tokenId];
        return _calculateCurrentEntropy(state);
    }

    /// @notice Calculates the Power Score of a Relic based on its Level and current Entropy.
    /// @param tokenId The ID of the Relic.
    /// @return The calculated Power Score.
    function calculatePowerScore(uint256 tokenId) public view returns (uint256 powerScore) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        RelicState memory state = _relics[tokenId];
        uint256 currentEntropy = _calculateCurrentEntropy(state);

        // Example calculation: Higher level is good, higher entropy is bad.
        // Ensure power score doesn't go below zero in calculation (though uint will wrap, be mindful in usage)
        uint256 basePower = state.level * 100; // Example base per level
        uint256 entropyPenalty = currentEntropy * 10; // Example penalty per entropy point

        return basePower > entropyPenalty ? basePower - entropyPenalty : 0;
    }

    // --- Parameter Administration (Owner Functions) ---

    /// @notice Sets the base Essence cost for forging a new Relic.
    /// @param cost The new base forge cost.
    function setBaseForgeCost(uint256 cost) external onlyOwner {
        baseForgeCost = cost;
        emit ParameterUpdated("baseForgeCost", cost);
    }

    /// @notice Sets the additional Essence cost per level when upgrading a Relic.
    /// @param cost The new upgrade cost per level.
    function setUpgradeCostPerLevel(uint256 cost) external onlyOwner {
        upgradeCostPerLevel = cost;
         emit ParameterUpdated("upgradeCostPerLevel", cost);
    }

    /// @notice Sets the Essence cost per point of Entropy stabilized.
    /// @param cost The new stabilize cost per point.
    function setStabilizeCostPerPoint(uint256 cost) external onlyOwner {
        stabilizeCostPerPoint = cost;
         emit ParameterUpdated("stabilizeCostPerPoint", cost);
    }

    /// @notice Sets the rate at which Entropy decays per second.
    /// @param rate The new entropy decay rate per second.
    function setEntropyRatePerSecond(uint256 rate) external onlyOwner {
        entropyRatePerSecond = rate;
        emit ParameterUpdated("entropyRatePerSecond", rate);
    }

    /// @notice Sets the amount of base Entropy added upon upgrading a Relic.
    /// @param increase The new base entropy increase per upgrade.
    function setBaseEntropyIncreasePerUpgrade(uint256 increase) external onlyOwner {
        baseEntropyIncreasePerUpgrade = increase;
        emit ParameterUpdated("baseEntropyIncreasePerUpgrade", increase);
    }

    /// @notice Sets the maximum level a Relic can reach.
    /// @param maxLevel The new maximum relic level.
    function setMaxRelicLevel(uint256 maxLevel) external onlyOwner {
        maxRelicLevel = maxLevel;
        emit ParameterUpdated("maxRelicLevel", maxLevel);
    }

    /// @notice Sets the base URI for the dynamic metadata endpoint.
    /// @dev This base URI will be prepended to the token ID and query parameters in `tokenURI`.
    /// @param baseURI The new base URI string.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }
}
```