Okay, let's design an interesting, advanced, and creative smart contract that goes beyond standard patterns. We'll create a "Decay-Based Reputation Badge NFT" system.

This contract issues NFTs that represent a user's reputation or activity level within a specific ecosystem. The unique twist is that this reputation (represented by Experience Points, XP, and Level) *decays over time* if the user is inactive, encouraging continuous engagement. Reputation can be earned via external reports (simulating actions taken off-chain or in other contracts/layers), and anyone can trigger the "processing" of a badge to update its state (level, XP) based on time elapsed and accumulated activity. The NFT metadata will be dynamic, reflecting the current state.

Here's the outline and function summary:

---

**Outline: Decay-Based Reputation Badge NFT**

1.  **Core Concept:** An ERC721 NFT representing a dynamic, decaying reputation score (XP & Level).
2.  **State:** Each NFT tracks its current XP, Level, last update timestamp, and a configurable Badge Type.
3.  **Mechanisms:**
    *   **Minting:** Create new badges of specific types.
    *   **Activity Reporting:** Designated "Reporter" addresses can add/subtract XP for badges based on external actions.
    *   **Evolution Processing:** Any user can trigger an update for a specific badge. This process applies time-based decay to XP and recalculates the Level based on current XP thresholds.
    *   **Dynamic Metadata:** `tokenURI` reflects the current state (Level, XP).
    *   **Configuration:** Admin can define badge types, decay rates, level thresholds, and reporters.
    *   **Access Control:** Admin and Reporter roles. Pause mechanism.
4.  **ERC721 Compliance:** Basic ERC721 functions implemented.

**Function Summary:**

*   **ERC721 Standard (9 functions):** Implement the required interface functions for ownership, transfers, approvals, and interface support.
*   **Badge State Getters (5 functions):** View the specific data (Level, XP, Type, last updated time) associated with a badge NFT.
*   **Badge Core Logic (3 functions):** Minting new badges, reporting external activities, and triggering the state evolution process for a badge.
*   **Reputation Calculation (2 functions):** View functions to calculate a badge's state *without* modifying state, useful for previews.
*   **Configuration & Admin (9 functions):** Functions for the admin to set up badge types, decay rates, level thresholds, manage reporters, and pause/unpause the system.
*   **Other (5 functions):** Getters for configuration, burning badges, checking pause status, etc.

**Total Public/External Functions:** 9 + 5 + 3 + 2 + 9 + 5 = **33 functions** (Exceeds the minimum 20).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Needed for safeTransferFrom
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Custom Errors for clarity and gas efficiency
error NotAdmin();
error NotReporter();
error Paused();
error NotOwnerOrApproved();
error InvalidRecipient();
error ZeroAddressRecipient();
error TokenDoesNotExist();
error InvalidBadgeType();
error InvalidLevelThresholds();
error LevelThresholdsMismatch(uint256 expectedLevels, uint256 providedThresholds);

// Structs
struct BadgeData {
    uint256 level;
    int256 experience; // Use int256 to allow negative gain/decay, but cap at 0
    uint40 lastUpdated; // Use uint40 for efficiency, sufficient for seconds since epoch until ~2242
    uint256 badgeType;
}

struct BadgeTypeConfig {
    uint256 initialLevel;
    int256 initialExperience;
    uint256 decayRatePerSecond; // How much XP decays per second
    uint256 maxLevel;
    bool exists; // Flag to indicate if the type is configured
}

contract DecayBadgeNFT is Context, IERC721, IERC165 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // --- State Variables ---

    // ERC721 Core
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Badge Specific Data
    mapping(uint256 => BadgeData) private _tokenData;
    mapping(uint256 => BadgeTypeConfig) private _badgeTypeConfigs;
    uint256[] private _levelThresholds; // XP required for each level (index 0 is level 1 threshold, etc.)

    // Access Control & State
    address private _admin;
    mapping(address => bool) private _reporters;
    bool private _paused;
    string private _baseURI;

    // --- Events ---

    // ERC721 Standard Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Badge Specific Events
    event BadgeMinted(address indexed recipient, uint256 indexed tokenId, uint256 badgeType, uint256 initialLevel, int256 initialXP);
    event ActivityReported(uint256 indexed tokenId, uint256 activityType, int256 value, int256 newXP);
    event BadgeProcessed(uint256 indexed tokenId, uint256 oldLevel, int256 oldXP, uint256 newLevel, int256 newXP, uint256 timeElapsed);
    event BadgeTypeConfigUpdated(uint256 indexed typeId, uint256 initialLevel, int256 initialXP, uint256 decayRatePerSecond, uint256 maxLevel);
    event LevelThresholdsUpdated(uint256[] newThresholds);
    event ReporterStatusUpdated(address indexed reporter, bool status);
    event PausedStatusUpdated(bool paused);

    // --- Constructor ---

    constructor(string memory baseURI_, uint256[] memory initialLevelThresholds) {
        _admin = _msgSender();
        _baseURI = baseURI_;
        if (initialLevelThresholds.length == 0) revert InvalidLevelThresholds();
        _levelThresholds = initialLevelThresholds; // Threshold for level N is _levelThresholds[N-1]
        emit LevelThresholdsUpdated(_levelThresholds);
    }

    // --- Modifiers ---

    modifier onlyAdmin() {
        if (_msgSender() != _admin) revert NotAdmin();
        _;
    }

    modifier onlyReporter() {
        if (!_reporters[_msgSender()]) revert NotReporter();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    // --- ERC721 Implementation ---

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, IERC721) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddressRecipient(); // Standard ERC721 requires this check for input
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // Throws if token does not exist
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert NotOwnerOrApproved();
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        ownerOf(tokenId); // Throws if token does not exist
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        if (_msgSender() != from && !isApprovedForAll(from, _msgSender()) && getApproved(tokenId) != _msgSender()) {
             revert NotOwnerOrApproved();
        }
        // The ERC721 spec allows for `to` to be address(0) for burning, but we'll handle burning separately.
        // For transfers, require valid recipient.
        if (to == address(0)) revert InvalidRecipient();
        
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
         if (_msgSender() != from && !isApprovedForAll(from, _msgSender()) && getApproved(tokenId) != _msgSender()) {
             revert NotOwnerOrApproved();
        }
        if (to == address(0)) revert InvalidRecipient();

        _transfer(from, to, tokenId);

        // Check if the recipient is a contract and can receive ERC721 tokens
        if (to.code.length > 0) {
            // Use a try-catch block to handle potential revert from onERC721Received
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert InvalidRecipient(); // Recipient contract rejected the token
                }
            } catch (bytes memory reason) {
                // Revert with the reason from the recipient contract if available
                 assembly { revert(add(32, reason), mload(reason)) }
            }
        }
    }

    // --- Internal ERC721 Helpers ---

    function _transfer(address from, address to, uint256 tokenId) internal {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        if (owner != from) revert NotOwnerOrApproved(); // Should already be checked by caller

        // Clear approvals from the previous owner
        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
         if (to == address(0)) revert ZeroAddressRecipient();
         if (_owners[tokenId] != address(0)) revert TokenDoesNotExist(); // Should be zero address for minting

        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

     function _burn(uint256 tokenId) internal {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[owner]--;
        delete _owners[tokenId];
        delete _tokenData[tokenId]; // Also remove badge-specific data

        emit Transfer(owner, address(0), tokenId);
    }


    // --- Badge State Getters (5 functions) ---

    function getBadgeLevel(uint256 tokenId) public view returns (uint256) {
        ownerOf(tokenId); // Check if token exists
        return _tokenData[tokenId].level;
    }

    function getBadgeExperience(uint256 tokenId) public view returns (int256) {
        ownerOf(tokenId); // Check if token exists
        return _tokenData[tokenId].experience;
    }

    function getBadgeType(uint256 tokenId) public view returns (uint256) {
        ownerOf(tokenId); // Check if token exists
        return _tokenData[tokenId].badgeType;
    }

    function getBadgeLastUpdated(uint256 tokenId) public view returns (uint40) {
        ownerOf(tokenId); // Check if token exists
        return _tokenData[tokenId].lastUpdated;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         ownerOf(tokenId); // Check if token exists

        BadgeData memory badge = _tokenData[tokenId];
        BadgeTypeConfig memory config = _badgeTypeConfigs[badge.badgeType];

        // Example dynamic URI: could point to an API endpoint that generates JSON metadata
        // based on the query parameters (tokenId, level, xp, type, etc.)
        // e.g., https://myapi.com/metadata?id=123&level=5&xp=150&type=1

        string memory levelStr = Strings.toString(badge.level);
        string memory xpStr = Strings.toString(badge.experience); // Note: Need a toString for int256 if using standard libraries
        string memory typeStr = Strings.toString(badge.badgeType);

        // Simple concatenation for demonstration. A real implementation might use StringUtils or ABI encoding.
        // For int256 toString, we'd need a custom helper or library. Let's simplify xpStr for now.
        // Let's just include level and type in the URI for simplicity, or better, just pass the tokenId
        // and let the backend handle all state lookups via provider/RPC.
        // Using baseURI + tokenId is standard and relies on an external metadata server.

        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }

    // --- Badge Core Logic (3 functions) ---

    function mintBadge(address recipient, uint256 badgeType) public onlyAdmin whenNotPaused returns (uint256) {
        if (recipient == address(0)) revert ZeroAddressRecipient();
        BadgeTypeConfig memory config = _badgeTypeConfigs[badgeType];
        if (!config.exists) revert InvalidBadgeType();

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(recipient, newTokenId);

        _tokenData[newTokenId] = BadgeData({
            level: config.initialLevel,
            experience: config.initialExperience,
            lastUpdated: uint40(block.timestamp),
            badgeType: badgeType
        });

        emit BadgeMinted(recipient, newTokenId, badgeType, config.initialLevel, config.initialExperience);
        return newTokenId;
    }

    // Allows a designated reporter to add/subtract experience points
    function reportActivity(uint256 tokenId, uint256 activityType, int256 value) public onlyReporter whenNotPaused {
        ownerOf(tokenId); // Check if token exists

        BadgeData storage badge = _tokenData[tokenId];

        // Apply decay before applying new activity
        _applyDecay(tokenId);

        int256 newXP = badge.experience + value;
        if (newXP < 0) { // Cap XP at 0
            newXP = 0;
        }
        badge.experience = newXP;

        // Note: Level change is NOT applied here. It happens during `processEvolution`.
        // This decouples reporting from potentially gas-heavy level calculation.

        emit ActivityReported(tokenId, activityType, value, badge.experience);
    }

    // Triggers the update process for a badge: applies decay and recalculates level
    function processEvolution(uint256 tokenId) public whenNotPaused {
        ownerOf(tokenId); // Check if token exists

        BadgeData storage badge = _tokenData[tokenId];
        uint256 oldLevel = badge.level;
        int256 oldXP = badge.experience;

        // Apply decay based on time since last update
        _applyDecay(tokenId);

        // Recalculate level based on new XP
        _checkLevelUpLogic(tokenId);

        emit BadgeProcessed(
            tokenId,
            oldLevel,
            oldXP,
            badge.level,
            badge.experience,
            block.timestamp - badge.lastUpdated // Time elapsed
        );
    }

    // --- Internal Helpers ---

    // Applies time-based decay to a badge's XP
    function _applyDecay(uint256 tokenId) internal {
        BadgeData storage badge = _tokenData[tokenId];
        BadgeTypeConfig memory config = _badgeTypeConfigs[badge.badgeType];

        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - badge.lastUpdated;

        if (timeElapsed > 0 && config.decayRatePerSecond > 0) {
            uint256 decayAmount = timeElapsed * config.decayRatePerSecond;

            // Prevent XP from going below zero due to decay
            if (badge.experience > 0) {
                if (decayAmount > uint256(badge.experience)) {
                     badge.experience = 0;
                } else {
                     badge.experience -= int256(decayAmount);
                }
            }
        }
        badge.lastUpdated = currentTime;
    }

    // Checks and updates the level based on current XP and thresholds
    function _checkLevelUpLogic(uint256 tokenId) internal {
        BadgeData storage badge = _tokenData[tokenId];
        BadgeTypeConfig memory config = _badgeTypeConfigs[badge.badgeType];

        uint256 currentLevel = badge.level;
        int256 currentXP = badge.experience;
        uint256 newLevel = currentLevel;

        // Check for level up
        while (newLevel < config.maxLevel && newLevel < _levelThresholds.length && currentXP >= int256(_levelThresholds[newLevel])) {
            newLevel++;
        }

        // Check for level down
        // Note: Threshold for level N is the *minimum* XP to be level N.
        // So, if XP drops below threshold N-1, you drop to N-1.
         while (newLevel > 1 && currentXP < int256(_levelThresholds[newLevel - 2])) { // Level 1 threshold is _levelThresholds[0]. Level N threshold is _levelThresholds[N-1]. Level N-1 threshold is _levelThresholds[N-2]
            newLevel--;
        }
         // Special case for dropping below Level 1 threshold (XP < threshold[0]), goes to level 0?
         // Let's define Level 1 as the lowest level, and threshold[0] is the XP *required* for Level 1.
         // If XP is < threshold[0], level is effectively 0 or invalid. Let's cap at Level 1.
         if (newLevel == 1 && currentXP < int26(_levelThresholds[0])) {
            // Maybe handle this differently? Stay at level 1 with low XP? Or drop to a "base" level?
            // Let's say level 1 is the minimum achievable level with any non-negative XP.
            // The thresholds _levelThresholds[N-1] define the minimum XP for level N.
            // Level 1: XP >= threshold[0]
            // Level 2: XP >= threshold[1]
            // ...
            // Level N: XP >= threshold[N-1]
            // If XP < threshold[0], level stays at 1, or define a level 0?
            // Let's assume Level 1 is the absolute minimum *valid* level for a badge.
            // The thresholds define the *minimum XP to reach the NEXT level*.
            // Level 1: 0 <= XP < _levelThresholds[0] (or initial XP)
            // Level 2: _levelThresholds[0] <= XP < _levelThresholds[1]
            // Level N: _levelThresholds[N-2] <= XP < _levelThresholds[N-1]
            // Level Max: XP >= _levelThresholds[maxLevel-2] (assuming maxLevel > 1) or XP >= _levelThresholds[0] if maxLevel is 1

            // Re-evaluate level calculation based on the standard convention:
            // Level is N if XP >= threshold[N-1] and (N == maxLevel or XP < threshold[N]).
            uint256 calculatedLevel = 1; // Start at base level
            for (uint256 i = 0; i < _levelThresholds.length; i++) {
                // Check if current XP meets or exceeds the threshold for the *next* level (i + 2)
                 // threshold[i] is for level i+1
                if (currentXP >= int256(_levelThresholds[i])) {
                    calculatedLevel = i + 2;
                    // Cap at max level
                    if (calculatedLevel > config.maxLevel) {
                        calculatedLevel = config.maxLevel;
                        break; // Cannot go higher
                    }
                } else {
                    // XP is below this threshold, so the level is the previous one calculated
                    break;
                }
            }
            newLevel = calculatedLevel;
        }


        if (newLevel != currentLevel) {
            badge.level = newLevel;
        }
    }


    // --- Reputation Calculation (View Functions) ---

    // Calculates the current level including decay, but *without* state change
    function calculateCurrentLevel(uint256 tokenId) public view returns (uint256) {
        ownerOf(tokenId); // Check if token exists

        BadgeData memory badge = _tokenData[tokenId];
        BadgeTypeConfig memory config = _badgeTypeConfigs[badge.badgeType];

        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - badge.lastUpdated;

        int256 currentXP = badge.experience;
        if (timeElapsed > 0 && config.decayRatePerSecond > 0) {
            uint256 decayAmount = timeElapsed * config.decayRatePerSecond;
             if (currentXP > 0) {
                if (decayAmount > uint256(currentXP)) {
                     currentXP = 0;
                } else {
                     currentXP -= int256(decayAmount);
                }
            }
        }

        // Re-use level calculation logic from _checkLevelUpLogic
        uint256 calculatedLevel = 1;
         for (uint256 i = 0; i < _levelThresholds.length; i++) {
            if (currentXP >= int256(_levelThresholds[i])) {
                calculatedLevel = i + 2;
                if (calculatedLevel > config.maxLevel) {
                    calculatedLevel = config.maxLevel;
                    break;
                }
            } else {
                break;
            }
        }
        return calculatedLevel;
    }

    // Calculates the current experience points including decay, but *without* state change
    function calculateExperienceAfterDecay(uint256 tokenId) public view returns (int256) {
         ownerOf(tokenId); // Check if token exists

        BadgeData memory badge = _tokenData[tokenId];
        BadgeTypeConfig memory config = _badgeTypeConfigs[badge.badgeType];

        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - badge.lastUpdated;

        int256 currentXP = badge.experience;
         if (timeElapsed > 0 && config.decayRatePerSecond > 0) {
            uint256 decayAmount = timeElapsed * config.decayRatePerSecond;
             if (currentXP > 0) {
                if (decayAmount > uint256(currentXP)) {
                     currentXP = 0;
                } else {
                     currentXP -= int256(decayAmount);
                }
            }
        }
        return currentXP;
    }


    // --- Configuration & Admin (9 functions) ---

    function addBadgeType(
        uint256 typeId,
        uint256 initialLevel,
        int256 initialExperience,
        uint256 decayRatePerSecond,
        uint256 maxLevel
    ) public onlyAdmin {
        // Basic validation
        if (initialLevel == 0 || initialLevel > maxLevel || maxLevel == 0) revert InvalidBadgeType(); // Level 0 isn't a badge level
         if (maxLevel > _levelThresholds.length + 1) revert InvalidBadgeType(); // Cannot have max level higher than supported by thresholds (+1 because thresholds[N-1] is for level N)


        _badgeTypeConfigs[typeId] = BadgeTypeConfig({
            initialLevel: initialLevel,
            initialExperience: initialExperience,
            decayRatePerSecond: decayRatePerSecond,
            maxLevel: maxLevel,
            exists: true
        });

        emit BadgeTypeConfigUpdated(typeId, initialLevel, initialExperience, decayRatePerSecond, maxLevel);
    }

    // Update an existing badge type configuration
     function updateBadgeType(
        uint256 typeId,
        uint256 initialLevel, // May not be used after mint, but kept for consistency
        int256 initialExperience, // May not be used after mint
        uint256 decayRatePerSecond,
        uint256 maxLevel
    ) public onlyAdmin {
        BadgeTypeConfig storage config = _badgeTypeConfigs[typeId];
        if (!config.exists) revert InvalidBadgeType();

        if (initialLevel == 0 || initialLevel > maxLevel || maxLevel == 0) revert InvalidBadgeType();
        if (maxLevel > _levelThresholds.length + 1) revert InvalidBadgeType();

        config.initialLevel = initialLevel; // Initial state for new mints
        config.initialExperience = initialExperience; // Initial state for new mints
        config.decayRatePerSecond = decayRatePerSecond;
        config.maxLevel = maxLevel;

        emit BadgeTypeConfigUpdated(typeId, initialLevel, initialExperience, decayRatePerSecond, maxLevel);
    }


    // Sets the XP thresholds required for each level (Level 1 requires >= thresholds[0], Level 2 >= thresholds[1], etc.)
    function updateLevelThresholds(uint256[] memory newThresholds) public onlyAdmin {
        if (newThresholds.length == 0) revert InvalidLevelThresholds();
         // Optional: Add check for monotonically increasing thresholds if required
        _levelThresholds = newThresholds;
        emit LevelThresholdsUpdated(newThresholds);
    }

    function setReporter(address reporterAddress, bool status) public onlyAdmin {
        _reporters[reporterAddress] = status;
        emit ReporterStatusUpdated(reporterAddress, status);
    }

    function setAdmin(address adminAddress) public onlyAdmin {
        if (adminAddress == address(0)) revert ZeroAddressRecipient();
        _admin = adminAddress;
        // Consider emitting an event for admin transfer
    }

    function setBaseURI(string memory newURI) public onlyAdmin {
        _baseURI = newURI;
        // Consider emitting an event
    }

    function pauseActivityReporting(bool pausedStatus) public onlyAdmin {
        _paused = pausedStatus;
        emit PausedStatusUpdated(pausedStatus);
    }

    // --- Other (5 functions) ---

    function burnBadge(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId); // Throws if token does not exist
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert NotOwnerOrApproved();
        }
        _burn(tokenId);
    }

    function getAdmin() public view returns (address) {
        return _admin;
    }

    function getReporterStatus(address queryAddress) public view returns (bool) {
        return _reporters[queryAddress];
    }

    function isActivityReportingPaused() public view returns (bool) {
        return _paused;
    }

    function getBadgeTypeConfig(uint256 typeId) public view returns (BadgeTypeConfig memory) {
        // Does not throw if typeId doesn't exist, will return default struct with exists=false
        return _badgeTypeConfigs[typeId];
    }

     function getLevelThresholds() public view returns (uint256[] memory) {
        return _levelThresholds;
    }

    // --- Optional: Add total supply if needed (requires tracking total supply) ---
    // Counters.Counter private _totalSupply;
    // function totalSupply() public view returns (uint256) {
    //     return _totalSupply.current();
    // }
    // Adjust _mint to _totalSupply.increment(); _burn to _totalSupply.decrement();

}

// Helper library for uint256 to string conversion (from OpenZeppelin)
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "012345678123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Note: toString for int256 is more complex and not included here
    // if you need int256 in tokenURI, consider passing tokenId and doing lookup off-chain
    // or implement int256 to string conversion which requires handling negative sign.
}

// Note on Level Calculation: The logic in `_checkLevelUpLogic` and `calculateCurrentLevel`
// defines how XP maps to levels. The threshold array `_levelThresholds` is zero-indexed.
// `_levelThresholds[0]` is the minimum XP needed to reach Level 2.
// `_levelThresholds[1]` is the minimum XP needed to reach Level 3.
// `_levelThresholds[N-1]` is the minimum XP needed to reach Level N+1.
// This means Level 1 is the base level, achieved with XP >= initial XP (often 0) and < `_levelThresholds[0]`.
// Level N is achieved with XP >= `_levelThresholds[N-2]` and < `_levelThresholds[N-1]` (for N > 1).
// Level N is achieved with XP >= `_levelThresholds[N-2]` if N is the max level.
// The code implements this logic: Start at level 1, iterate through thresholds. If XP >= threshold[i], the level is at least i+2. Continue checking higher thresholds.

```

**Explanation of Advanced/Creative Concepts:**

1.  **Decaying State:** The core mechanic is the time-based decay of `experience`. This isn't static state like a typical NFT trait but requires interaction (`processEvolution`) to update based on the passage of time. This encourages regular interaction or "activity" within the system the badge represents.
2.  **User-Triggered Processing:** Instead of the contract automatically updating state on every block or every `reportActivity` (which would be gas-prohibitive), the update logic (`processEvolution`) is pulled into a separate function that any user can call. This externalizes the gas cost of state updates to those who care about the badge's current level, while still allowing reporters to add XP without processing.
3.  **Role-Based Activity Reporting:** The `onlyReporter` modifier allows external systems (like oracles, game servers, other smart contracts, or trusted off-chain services) to feed activity data into the badge system without giving them full admin control.
4.  **Dynamic Metadata (Implicit):** The `tokenURI` function returns a base URI concatenated with the `tokenId`. A metadata server listening for requests at this URI would dynamically generate the JSON metadata (including traits for level, XP, type, etc.) by querying the contract's state functions (`getBadgeLevel`, `getBadgeExperience`, etc.). This makes the visual/data representation of the NFT truly dynamic based on its on-chain state.
5.  **Configurable Badge Types:** The `BadgeTypeConfig` struct and related admin functions allow for different categories of badges with varying initial states, decay rates, and max levels, providing flexibility for the ecosystem using these badges.
6.  **Level Thresholds:** Level progression is not hardcoded but driven by a configurable array of XP thresholds, allowing the difficulty of leveling up (or down) to be adjusted by the admin.
7.  **Minimalistic Timestamp:** Using `uint40` for `lastUpdated` is a gas optimization compared to `uint256`, sufficient for timestamps well into the future.
8.  **Custom Errors:** Using `error` definitions instead of `require` strings is a modern Solidity practice that is more gas-efficient and provides clearer error handling in applications.

This contract provides a framework for an engaging, dynamic, and potentially game-theoretic reputation system where inactivity has a cost, and the status of the NFT changes over time based on both reported actions and the simple passage of time.