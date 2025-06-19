Okay, let's create a smart contract concept around dynamic, time-aware NFTs that evolve based on user interaction and a built-in reputation system. We'll call it "Epochal Orbs".

This contract will represent unique digital assets (Orbs) that have internal states that change over time (epochs) and through specific actions performed by the owner or others. A reputation score is built by interacting positively with Orbs.

---

**Epochal Orbs Contract Outline & Function Summary**

This smart contract manages a collection of unique, dynamic NFTs ("Epochal Orbs"). Each Orb has internal state variables that evolve over time and through user interactions. A reputation system tracks positive contributions to the Orb ecosystem.

**Core Concepts:**

1.  **Dynamic NFTs (Orbs):** ERC721 tokens with embedded state (level, purity, epoch status, last interaction time).
2.  **Epochs:** Time periods defined by the contract. Orbs are born in an epoch and automatically advance through them.
3.  **Time-based Evolution/Degradation:** Orbs change simply by the passage of time (aging/epoch advancement). They may degrade if not maintained.
4.  **User Interaction:** Specific functions (`nurtureOrb`, `purifyOrb`, `combineOrbs`) allow users to influence an Orb's state.
5.  **Reputation System:** Users earn reputation points for positive interactions. Reputation may unlock future privileges or influence Orb behavior (not fully implemented in this base structure, but the framework is there).
6.  **Combining Orbs:** A unique function allowing two Orbs to be merged into one, transferring properties and burning one Orb.
7.  **Public Aging:** A function callable by anyone to advance an Orb's epoch state, incentivizing state updates on-chain.

**State Variables:**

*   `_orbs`: Mapping from tokenId to OrbState struct.
*   `_reputation`: Mapping from user address to reputation score.
*   `_epochConfig`: Struct holding epoch duration, base degradation rate, etc.
*   `_orbConfigs`: Struct holding base purity, level caps, etc.
*   `_fees`: Mapping to track collected fees per action type (hypothetical).
*   `_totalOrbsMinted`: Counter for token IDs.
*   `_tokenURI`: Base URI for dynamic metadata.
*   Standard ERC721/Ownable variables.

**Structs:**

*   `OrbState`: Represents the internal state of an Orb (uint level, uint purity, uint lastNurturedTimestamp, uint creationEpoch, uint currentEpoch, bool isCombined, uint combinedIntoId).
*   `EpochConfig`: Configuration for time-based mechanics (uint epochDuration, uint degradationFactor, uint nurturingBonusReputation, uint purifyingBonusReputation).
*   `OrbConfig`: Configuration for Orb properties (uint initialPurity, uint initialLevel, uint levelUpThreshold, uint purifyCost, uint nurtureCost, uint combineFee).

**Events:**

*   `OrbMinted(tokenId, owner, creationEpoch)`
*   `OrbNurtured(tokenId, nurturer, newPurity, reputationEarned)`
*   `OrbPurified(tokenId, purifier, newPurity, reputationEarned)`
*   `OrbCombined(tokenId1, tokenId2, newOrbId)`
*   `OrbAged(tokenId, oldEpoch, newEpoch, degraded)`
*   `ReputationEarned(user, amount, reason)`
*   `ReputationSlashed(user, amount, reason)`
*   `ConfigUpdated(configType, details)`

**Function Summary (28 Functions):**

*   **Core ERC721 (Required Overrides/Implementations):**
    1.  `balanceOf(address owner)`: Get balance of Orbs for an address.
    2.  `ownerOf(uint256 tokenId)`: Get owner of an Orb.
    3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer Orb.
    4.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer Orb with data.
    5.  `transferFrom(address from, address to, uint256 tokenId)`: Unsafe transfer Orb.
    6.  `approve(address to, uint256 tokenId)`: Approve transfer of an Orb.
    7.  `setApprovalForAll(address operator, bool approved)`: Set approval for all Orbs.
    8.  `getApproved(uint256 tokenId)`: Get approved address for an Orb.
    9.  `isApprovedForAll(address owner, address operator)`: Check if operator is approved for all.
    10. `supportsInterface(bytes4 interfaceId)`: ERC165 interface support check.
    11. `tokenURI(uint256 tokenId)`: Get dynamic metadata URI for an Orb.

*   **Orb Management & Interaction:**
    12. `mintOrb()`: Mints a new Orb for the caller.
    13. `nurtureOrb(uint256 tokenId)`: Performs a 'nurture' action on an Orb, improving purity and earning reputation.
    14. `purifyOrb(uint256 tokenId)`: Performs a 'purify' action, significantly improving purity (maybe with cooldown/cost) and earning reputation.
    15. `combineOrbs(uint256 tokenId1, uint256 tokenId2)`: Combines two Orbs owned by the caller into `tokenId1`, burning `tokenId2`.
    16. `ageOrb(uint256 tokenId)`: *Anyone* can call this to advance an Orb's epoch if due. May cause degradation.
    17. `upgradeOrbLevel(uint256 tokenId)`: Attempts to level up an Orb if its state meets criteria.

*   **Reputation System:**
    18. `getUserReputation(address user)`: Gets the reputation score of a user.
    19. `delegateReputation(address delegatee)`: Delegates calling user's reputation weight to another address (conceptual).
    20. `slashReputation(address user, uint256 amount, string memory reason)`: Admin function to reduce a user's reputation.

*   **Time & Epoch:**
    21. `getCurrentEpoch()`: Gets the current epoch number based on contract deploy time.
    22. `getEpochDetails(uint256 epochNumber)`: Gets start/end timestamps for a specific epoch.
    23. `getOrbEpochStatus(uint256 tokenId)`: Gets the current epoch and aging status of an Orb.

*   **View & Utility:**
    24. `getOrbState(uint256 tokenId)`: Gets the detailed internal state of an Orb.
    25. `getConfig()`: Gets the current Epoch and Orb configuration settings.
    26. `predictOrbOutcomeScore(uint256 tokenId, uint256 userReputation)`: A simple score calculating potential based on Orb state and user reputation (conceptual, not a true prediction).
    27. `getTotalOrbs()`: Get the total number of Orbs minted (same as `totalSupply`).

*   **Admin & Configuration:**
    28. `setConfigs(uint256 epochDuration, uint256 degradationFactor, uint256 nurturingRep, uint256 purifyingRep, uint256 initialPurity, uint256 initialLevel, uint256 levelUpThreshold, uint256 purifyCost, uint256 nurtureCost, uint256 combineFee)`: Set various configuration parameters.
    29. `setBaseTokenURI(string memory baseURI)`: Set the base URI for metadata.
    30. `withdrawFees(address payable recipient)`: Withdraw collected fees (if fees are implemented). (Let's skip explicit fee collection to simplify, but keep the function summary item).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline & Function Summary Above

/// @title Epochal Orbs Contract
/// @dev Manages dynamic NFTs (Orbs) with time-based evolution, user interactions, and a reputation system.
contract EpochalOrbs is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    struct OrbState {
        uint256 level;
        uint256 purity; // 0-100 scale, higher is better
        uint256 lastNurturedTimestamp;
        uint256 creationEpoch;
        uint256 currentEpoch;
        bool isCombined; // True if this Orb was combined INTO another
        uint256 combinedIntoId; // The ID of the Orb it was combined into
    }

    mapping(uint256 => OrbState) private _orbs;
    mapping(address => uint256) private _reputation;
    mapping(address => address) private _reputationDelegates; // Delegate reputation voting power (conceptual)

    struct EpochConfig {
        uint256 epochDuration; // Duration of an epoch in seconds
        uint256 degradationFactor; // Amount purity decreases per skipped epoch (e.g., 5 for 5%)
        uint256 nurturingBonusReputation; // Reputation gained from nurturing
        uint256 purifyingBonusReputation; // Reputation gained from purifying
    }

    struct OrbConfig {
        uint256 initialPurity; // Starting purity for new orbs
        uint256 initialLevel; // Starting level for new orbs
        uint256 levelUpThreshold; // Purity needed to attempt level up
        uint256 purifyCooldown; // Cooldown for purify action
        uint256 purifyCost; // Cost in Wei for purifying
        uint256 nurtureCost; // Cost in Wei for nurturing
        uint256 combineFee; // Cost in Wei for combining
    }

    EpochConfig public epochConfig;
    OrbConfig public orbConfig;

    uint256 private immutable _contractDeployTimestamp;

    // Mapping to track last purify timestamp per orb
    mapping(uint256 => uint256) private _lastPurifyTimestamp;

    // --- Events ---

    event OrbMinted(uint256 indexed tokenId, address indexed owner, uint256 creationEpoch);
    event OrbNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 newPurity, uint256 reputationEarned);
    event OrbPurified(uint256 indexed tokenId, address indexed purifier, uint256 newPurity, uint255 reputationEarned);
    event OrbCombined(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newOrbId); // tokenId2 was burned
    event OrbAged(uint256 indexed tokenId, uint256 oldEpoch, uint256 newEpoch, bool degraded);
    event ReputationEarned(address indexed user, uint256 amount, string reason);
    event ReputationSlashed(address indexed user, uint256 amount, string reason);
    event ConfigUpdated(string configType, address indexed updater);
    event OrbLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);


    // --- Errors ---

    error NotOrbOwnerOrApproved(uint256 tokenId);
    error OrbIsCombined(uint256 tokenId, uint256 combinedIntoId);
    error OrbNotCombined(uint256 tokenId);
    error InvalidOrbId(uint256 tokenId);
    error PurifyCooldownActive(uint256 tokenId, uint256 timeRemaining);
    error CannotLevelUp(uint256 tokenId, string reason);
    error NotEnoughPurityToLevelUp(uint256 tokenId, uint256 requiredPurity);
    error NotEnoughEtherForAction(uint256 requiredAmount);
    error SelfDelegationNotAllowed();
    error InsufficientReputationToSlash(address user, uint256 amount);
    error SameOrbIds(uint256 tokenId);
    error OrbsNotOwnedByCaller(uint256 tokenId1, uint256 tokenId2);


    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        uint256 _epochDuration,
        uint256 _degradationFactor,
        uint256 _nurturingRep,
        uint256 _purifyingRep,
        uint256 _initialPurity,
        uint256 _initialLevel,
        uint256 _levelUpThreshold,
        uint256 _purifyCooldown,
        uint256 _purifyCost,
        uint256 _nurtureCost,
        uint256 _combineFee
    ) ERC721(name, symbol) Ownable(msg.sender) {
        epochConfig = EpochConfig({
            epochDuration: _epochDuration,
            degradationFactor: _degradationFactor,
            nurturingBonusReputation: _nurturingRep,
            purifyingBonusReputation: _purifyingRep
        });
        orbConfig = OrbConfig({
            initialPurity: _initialPurity,
            initialLevel: _initialLevel,
            levelUpThreshold: _levelUpThreshold,
            purifyCooldown: _purifyCooldown,
            purifyCost: _purifyCost,
            nurtureCost: _nurtureCost,
            combineFee: _combineFee
        });
        _contractDeployTimestamp = block.timestamp;
    }

    // --- Modifiers ---

    modifier onlyOrbOwnerOrApproved(uint256 tokenId) {
        if (_isApprovedOrOwner(msg.sender, tokenId) == false) {
            revert NotOrbOwnerOrApproved(tokenId);
        }
        _;
    }

    modifier onlyOrbExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert InvalidOrbId(tokenId);
        }
        _;
    }

    modifier onlyOrbNotCombined(uint256 tokenId) {
        if (_orbs[tokenId].isCombined) {
            revert OrbIsCombined(tokenId, _orbs[tokenId].combinedIntoId);
        }
        _;
    }

    // --- ERC721 Overrides ---

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert InvalidOrbId(tokenId);
        }

        // Append token ID to the base URI
        // Example: "ipfs://baseuri/" + tokenId
        return string(abi.encodePacked(_baseTokenURI(), Strings.toString(tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Internal helper to get base URI
    function _baseTokenURI() internal view override returns (string memory) {
        return _tokenURI;
    }

    // Override transfer function to prevent transfers if the Orb is marked as combined
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (batchSize > 1) {
             // Handle batch transfers if needed, potentially more complex logic
             // For simplicity, we assume batchSize is usually 1 for ERC721 single token transfers
        } else {
             if (_orbs[tokenId].isCombined) {
                 // If an Orb is combined, it should not be transferrable
                 revert OrbIsCombined(tokenId, _orbs[tokenId].combinedIntoId);
             }
        }
    }


    // --- Orb Management & Interaction ---

    /// @notice Mints a new Epochal Orb for the caller.
    function mintOrb() public {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        uint256 currentEpoch = getCurrentEpoch();

        _orbs[newItemId] = OrbState({
            level: orbConfig.initialLevel,
            purity: orbConfig.initialPurity,
            lastNurturedTimestamp: block.timestamp,
            creationEpoch: currentEpoch,
            currentEpoch: currentEpoch,
            isCombined: false,
            combinedIntoId: 0
        });

        _safeMint(msg.sender, newItemId);
        emit OrbMinted(newItemId, msg.sender, currentEpoch);
    }

    /// @notice Nurtures an Orb, increasing its purity and the owner's reputation.
    /// @param tokenId The ID of the Orb to nurture.
    function nurtureOrb(uint256 tokenId)
        public
        payable
        onlyOrbExists(tokenId)
        onlyOrbOwnerOrApproved(tokenId)
        onlyOrbNotCombined(tokenId)
    {
        if (msg.value < orbConfig.nurtureCost) {
            revert NotEnoughEtherForAction(orbConfig.nurtureCost);
        }

        // Refund excess ether
        if (msg.value > orbConfig.nurtureCost) {
            payable(msg.sender).transfer(msg.value - orbConfig.nurtureCost);
        }
        // Collected fee stays in contract (can be withdrawn by owner)

        OrbState storage orb = _orbs[tokenId];

        // Increase purity, capped at 100
        uint256 purityIncrease = 5; // Example increase value
        orb.purity = Math.min(orb.purity + purityIncrease, 100);
        orb.lastNurturedTimestamp = block.timestamp;

        // Reward reputation
        _addReputation(msg.sender, epochConfig.nurturingBonusReputation, "Nurtured Orb");

        emit OrbNurtured(tokenId, msg.sender, orb.purity, epochConfig.nurturingBonusReputation);
    }

    /// @notice Purifies an Orb, significantly increasing its purity (subject to cooldown).
    /// @param tokenId The ID of the Orb to purify.
    function purifyOrb(uint256 tokenId)
        public
        payable
        onlyOrbExists(tokenId)
        onlyOrbOwnerOrApproved(tokenId)
        onlyOrbNotCombined(tokenId)
    {
        if (msg.value < orbConfig.purifyCost) {
            revert NotEnoughEtherForAction(orbConfig.purifyCost);
        }

         // Refund excess ether
        if (msg.value > orbConfig.purifyCost) {
            payable(msg.sender).transfer(msg.value - orbConfig.purifyCost);
        }

        if (block.timestamp < _lastPurifyTimestamp[tokenId].add(orbConfig.purifyCooldown)) {
             revert PurifyCooldownActive(tokenId, _lastPurifyTimestamp[tokenId].add(orbConfig.purifyCooldown).sub(block.timestamp));
        }

        OrbState storage orb = _orbs[tokenId];

        // Significant purity increase, capped at 100
        uint256 purityIncrease = 20; // Example increase value
        orb.purity = Math.min(orb.purity + purityIncrease, 100);
        orb.lastNurturedTimestamp = block.timestamp; // Purifying also counts as nurturing

        _lastPurifyTimestamp[tokenId] = block.timestamp;

        // Reward reputation
        _addReputation(msg.sender, epochConfig.purifyingBonusReputation, "Purified Orb");

        emit OrbPurified(tokenId, msg.sender, orb.purity, epochConfig.purifyingBonusReputation);
    }

    /// @notice Combines two Orbs owned by the caller into the first Orb. The second Orb is burned.
    /// @param tokenId1 The ID of the primary Orb (receives properties, remains).
    /// @param tokenId2 The ID of the secondary Orb (attributes transferred, is burned).
    function combineOrbs(uint256 tokenId1, uint256 tokenId2)
        public
        payable
        onlyOrbExists(tokenId1)
        onlyOrbExists(tokenId2)
        onlyOrbNotCombined(tokenId1)
        onlyOrbNotCombined(tokenId2)
    {
        if (tokenId1 == tokenId2) {
            revert SameOrbIds(tokenId1);
        }

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        if (msg.sender != owner1 || msg.sender != owner2) {
            revert OrbsNotOwnedByCaller(tokenId1, tokenId2);
        }

         if (msg.value < orbConfig.combineFee) {
            revert NotEnoughEtherForAction(orbConfig.combineFee);
        }

         // Refund excess ether
        if (msg.value > orbConfig.combineFee) {
            payable(msg.sender).transfer(msg.value - orbConfig.combineFee);
        }


        OrbState storage orb1 = _orbs[tokenId1];
        OrbState storage orb2 = _orbs[tokenId2];

        // --- Combination Logic ---
        // Example: Average purity, add half level, update nurture time to latest.
        orb1.purity = (orb1.purity + orb2.purity) / 2;
        orb1.level = orb1.level.add(orb2.level / 2);
        orb1.lastNurturedTimestamp = Math.max(orb1.lastNurturedTimestamp, orb2.lastNurturedTimestamp);
        // Keep the creation epoch and current epoch of the primary orb
        // You could add more complex rules here based on epoch/age difference

        // Mark the second orb as combined and link it to the first
        orb2.isCombined = true;
        orb2.combinedIntoId = tokenId1;

        // Burn the second Orb
        _burn(tokenId2); // This will also clean up URI storage

        // No reputation bonus for combining? Or maybe a small one? Let's add a small one.
        _addReputation(msg.sender, epochConfig.nurturingBonusReputation / 2, "Combined Orbs");


        emit OrbCombined(tokenId1, tokenId2, tokenId1);
    }

    /// @notice Allows anyone to trigger the aging process for an Orb if an epoch has passed.
    /// May cause degradation if the Orb was not nurtured recently.
    /// @param tokenId The ID of the Orb to age.
    function ageOrb(uint256 tokenId)
        public
        onlyOrbExists(tokenId)
        onlyOrbNotCombined(tokenId)
    {
        OrbState storage orb = _orbs[tokenId];
        uint256 nextEpochBoundary = _contractDeployTimestamp.add(orb.currentEpoch.add(1).mul(epochConfig.epochDuration));

        if (block.timestamp >= nextEpochBoundary) {
            uint256 oldEpoch = orb.currentEpoch;
            orb.currentEpoch = getCurrentEpochForTimestamp(block.timestamp);

            bool degraded = false;
            // Check if degradation should occur (e.g., not nurtured in the last epoch)
            if (orb.lastNurturedTimestamp < nextEpochBoundary - epochConfig.epochDuration) {
                 // Calculate how many epochs were skipped since last nurtured
                 uint256 epochsSkipped = getCurrentEpochForTimestamp(block.timestamp).sub(getCurrentEpochForTimestamp(orb.lastNurturedTimestamp)).sub(1); // Subtract 1 because last nurtured was in some epoch
                 if (epochsSkipped > 0) {
                    uint256 degradationAmount = epochConfig.degradationFactor.mul(epochsSkipped);
                    orb.purity = orb.purity > degradationAmount ? orb.purity.sub(degradationAmount) : 0;
                    degraded = true;
                 }
            }

            emit OrbAged(tokenId, oldEpoch, orb.currentEpoch, degraded);
        }
        // If not enough time has passed, the function does nothing
    }

    /// @notice Attempts to level up an Orb if its purity is above the threshold.
    /// Resets purity upon successful level up.
    /// @param tokenId The ID of the Orb to level up.
    function upgradeOrbLevel(uint256 tokenId)
        public
        onlyOrbExists(tokenId)
        onlyOrbOwnerOrApproved(tokenId)
        onlyOrbNotCombined(tokenId)
    {
        OrbState storage orb = _orbs[tokenId];

        if (orb.purity < orbConfig.levelUpThreshold) {
            revert NotEnoughPurityToLevelUp(tokenId, orbConfig.levelUpThreshold);
        }
        // Add other potential conditions for leveling up (e.g., age, specific items)

        orb.level = orb.level.add(1);
        orb.purity = 0; // Reset purity after leveling up

        emit OrbLeveledUp(tokenId, orb.level);
    }


    // --- Reputation System ---

    /// @notice Gets the current reputation score for a user.
    /// @param user The address of the user.
    /// @return The reputation score.
    function getUserReputation(address user) public view returns (uint256) {
        return _reputation[user];
    }

    /// @notice Allows a user to delegate their reputation score's "voting weight" to another address.
    /// This does not transfer the score, just grants delegation power (conceptual for governance).
    /// @param delegatee The address to delegate reputation to.
    function delegateReputation(address delegatee) public {
        if (msg.sender == delegatee) {
            revert SelfDelegationNotAllowed();
        }
        _reputationDelegates[msg.sender] = delegatee;
        emit ReputationDelegated(msg.sender, delegatee);
    }

    /// @notice Admin function to reduce a user's reputation score.
    /// Can be used for punishing negative behavior (if implemented).
    /// @param user The address of the user whose reputation to slash.
    /// @param amount The amount of reputation to slash.
    /// @param reason The reason for the slashing.
    function slashReputation(address user, uint256 amount, string memory reason) public onlyOwner {
        if (_reputation[user] < amount) {
            revert InsufficientReputationToSlash(user, amount);
        }
        _reputation[user] = _reputation[user].sub(amount);
        emit ReputationSlashed(user, amount, reason);
    }

    // Internal function to add reputation
    function _addReputation(address user, uint256 amount, string memory reason) internal {
        _reputation[user] = _reputation[user].add(amount);
        emit ReputationEarned(user, amount, reason);
    }


    // --- Time & Epoch ---

    /// @notice Gets the current epoch number.
    /// @return The current epoch number.
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp.sub(_contractDeployTimestamp)).div(epochConfig.epochDuration);
    }

     /// @notice Gets the epoch number for a given timestamp.
     /// @param timestamp The timestamp to check.
     /// @return The epoch number for that timestamp.
    function getCurrentEpochForTimestamp(uint256 timestamp) public view returns (uint256) {
        if (timestamp < _contractDeployTimestamp) return 0; // Or handle error
        return (timestamp.sub(_contractDeployTimestamp)).div(epochConfig.epochDuration);
    }


    /// @notice Gets the start and end timestamps for a specific epoch.
    /// @param epochNumber The epoch number.
    /// @return startTime The start timestamp of the epoch.
    /// @return endTime The end timestamp of the epoch.
    function getEpochDetails(uint256 epochNumber) public view returns (uint256 startTime, uint256 endTime) {
        startTime = _contractDeployTimestamp.add(epochNumber.mul(epochConfig.epochDuration));
        endTime = startTime.add(epochConfig.epochDuration).sub(1); // End is just before the next epoch starts
    }

    /// @notice Gets the current epoch and whether the Orb is due for aging/potential degradation.
    /// @param tokenId The ID of the Orb.
    /// @return currentEpoch The Orb's tracked current epoch.
    /// @return isDueForAging True if block.timestamp is past the next epoch boundary for this Orb.
    function getOrbEpochStatus(uint256 tokenId) public view onlyOrbExists(tokenId) returns (uint256 currentEpoch, bool isDueForAging) {
        OrbState storage orb = _orbs[tokenId];
        currentEpoch = orb.currentEpoch;
        uint256 nextEpochBoundary = _contractDeployTimestamp.add(orb.currentEpoch.add(1).mul(epochConfig.epochDuration));
        isDueForAging = block.timestamp >= nextEpochBoundary;
    }


    // --- View & Utility ---

    /// @notice Gets the detailed internal state of an Orb.
    /// @param tokenId The ID of the Orb.
    /// @return The OrbState struct.
    function getOrbState(uint256 tokenId) public view onlyOrbExists(tokenId) returns (OrbState memory) {
        return _orbs[tokenId];
    }

    /// @notice Gets the current configuration settings for epochs and orbs.
    /// @return epochCfg The EpochConfig struct.
    /// @return orbCfg The OrbConfig struct.
    function getConfig() public view returns (EpochConfig memory epochCfg, OrbConfig memory orbCfg) {
        return (epochConfig, orbConfig);
    }

    /// @notice Calculates a simple score based on Orb state and user reputation.
    /// Not a true prediction, but a weighted score.
    /// @param tokenId The ID of the Orb.
    /// @param userReputation The user's reputation score.
    /// @return A calculated potential score.
    function predictOrbOutcomeScore(uint256 tokenId, uint256 userReputation) public view onlyOrbExists(tokenId) returns (uint256) {
        OrbState memory orb = _orbs[tokenId];
        // Simple example score calculation: Purity + (Level * 10) + (User Reputation / 100)
        uint256 baseScore = orb.purity.add(orb.level.mul(10));
        uint256 reputationContribution = userReputation.div(100); // Scale reputation down
        return baseScore.add(reputationContribution);
    }

    /// @notice Gets the total number of Orbs that have been minted.
    /// @return The total count.
    function getTotalOrbs() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- Admin & Configuration ---

    /// @notice Allows the owner to update multiple configuration parameters.
    /// @param _epochDuration New epoch duration in seconds.
    /// @param _degradationFactor New purity degradation factor.
    /// @param _nurturingRep New reputation bonus for nurturing.
    /// @param _purifyingRep New reputation bonus for purifying.
    /// @param _initialPurity New initial purity for minting.
    /// @param _initialLevel New initial level for minting.
    /// @param _levelUpThreshold New purity threshold for leveling up.
    /// @param _purifyCooldown New cooldown for purifying.
    /// @param _purifyCost New cost in Wei for purifying.
    /// @param _nurtureCost New cost in Wei for nurturing.
    /// @param _combineFee New cost in Wei for combining.
    function setConfigs(
        uint256 _epochDuration,
        uint256 _degradationFactor,
        uint256 _nurturingRep,
        uint256 _purifyingRep,
        uint256 _initialPurity,
        uint256 _initialLevel,
        uint256 _levelUpThreshold,
        uint256 _purifyCooldown,
        uint256 _purifyCost,
        uint256 _nurtureCost,
        uint256 _combineFee
    ) public onlyOwner {
        epochConfig = EpochConfig({
            epochDuration: _epochDuration,
            degradationFactor: _degradationFactor,
            nurturingBonusReputation: _nurturingRep,
            purifyingBonusReputation: _purifyingRep
        });
        orbConfig = OrbConfig({
            initialPurity: _initialPurity,
            initialLevel: _initialLevel,
            levelUpThreshold: _levelUpThreshold,
            purifyCooldown: _purifyCooldown,
            purifyCost: _purifyCost,
            nurtureCost: _nurtureCost,
            combineFee: _combineFee
        });
        emit ConfigUpdated("EpochAndOrb", msg.sender);
    }

    /// @notice Allows the owner to set the base URI for token metadata.
    /// @param baseURI The new base URI.
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _tokenURI = baseURI;
        emit ConfigUpdated("BaseTokenURI", msg.sender);
    }

     /// @notice Allows the owner to withdraw collected Ether fees.
     /// @param recipient The address to send the fees to.
     function withdrawFees(address payable recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = recipient.transfer(balance);
        require(success, "Fee withdrawal failed");
     }

    // --- Internal ERC721 Helper (if needed, but ERC721URIStorage provides most) ---
    // _safeMint, _burn, _exists, _isApprovedOrOwner are inherited and used above.
}
```