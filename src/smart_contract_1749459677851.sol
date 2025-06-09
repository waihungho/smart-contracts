Okay, here is a Solidity smart contract implementing a "ChronoBadge" - a programmable, reputation-aware soulbound (or conditionally transferable) asset with dynamic attributes that change based on interactions within a simulated ecosystem. It incorporates concepts like dynamic NFTs, conditional logic, role-based access, simulated external data feeds (oracles), internal utility tokens, and complex state transitions like merging.

This contract aims for creativity by building a cohesive system around a single asset type with many interlocking functions, rather than just listing 20 disparate features. It avoids duplicating standard ERC721/ERC20 implementations entirely by building necessary ownership/balance tracking manually, though it uses OpenZeppelin's `AccessControl` and `Pausable` for robust access control and safety patterns.

---

**ChronoBadge: Programmable Reputation Shard**

**Outline & Function Summary:**

This contract manages "ChronoBadges", unique, dynamically evolving non-transferable (Soulbound) assets. ChronoBadges possess several attributes that change based on on-chain actions, simulated external events (via Oracles), and interaction within the contract's defined ecosystem. These attributes grant specific permissions or benefits within the system. Badges can be temporarily "Attuned" (conditionally transferred) under specific circumstances. An internal utility token ("Essence") can be earned and spent to influence badge attributes or unlock features.

**Core Concepts:**

1.  **Dynamic Attributes:** Badges have quantifiable attributes (`InteractionScore`, `WisdomLevel`, `AttunementFactor`, `AccumulatedTime`) that change over time and through function calls.
2.  **Soulbound with Attunement:** Badges are non-transferable by default but can be temporarily granted to another address (`Attunement`) under specific conditions, simulating delegated permission or temporary lending.
3.  **Conditional Logic:** Many functions require specific attribute thresholds, temporal conditions, or Attunement status to execute.
4.  **Role-Based Ecosystem Interaction:** Different roles (`MINTER_ROLE`, `ATTRIBUTE_ORACLE_ROLE`, `TASK_MASTER_ROLE`, `CONFIG_ROLE`) simulate interaction with external systems (creation, attribute updates, task completion, configuration).
5.  **Internal Utility Token (Essence):** Users can earn Essence based on badge attributes and spend it for benefits.
6.  **State Transitions:** Complex functions like `mergeBadges` create new state based on multiple existing assets.
7.  **Time-Based Mechanics:** Attributes can decay, and Essence accrues over time based on badge state. Attunement is time-limited.
8.  **Simulated Oracles/External Feeds:** Functions like `updateAttributeBasedOnOracle` simulate receiving data that affects badge state.

**Function Summary (Total: 26 functions):**

*   **Badge Lifecycle & Core (6 functions):**
    *   `mintBadge`: Creates a new ChronoBadge for a recipient.
    *   `burnBadge`: Destroys a ChronoBadge.
    *   `ownerOf`: Returns the owner of a badge (ERC721-like).
    *   `balanceOf`: Returns the number of badges owned by an address (ERC721-like).
    *   `getBadgeAttributes`: Retrieves the current dynamic attributes of a badge.
    *   `isSoulbound`: Checks if a badge is permanently non-transferable (initially true).

*   **Attunement & Conditional Transfer (3 functions):**
    *   `attuneBadge`: Temporarily transfers/delegates a badge to another address under conditions.
    *   `releaseAttunement`: Ends an active Attunement.
    *   `isAttuned`: Checks if a badge is currently Attuned and to whom.

*   **Attribute Management & Dynamics (7 functions):**
    *   `incrementInteractionScore`: Increases a badge's InteractionScore.
    *   `gainAccumulatedTime`: Simulates the passage of time/activity, increasing AccumulatedTime.
    *   `learnFromKnowledgePool`: Increases WisdomLevel based on conditions and current Wisdom.
    *   `performTask`: Increases AttunementFactor and potentially rewards Essence based on conditions.
    *   `applyBlessing`: Temporarily boosts specific attributes (simulating external buff).
    *   `decayAttributes`: Triggers attribute decay based on time elapsed since last check.
    *   `updateAttributeBasedOnOracle`: Allows an Oracle role to update attributes based on simulated external data.

*   **Ecosystem & Utility (7 functions):**
    *   `claimEssence`: Calculates and grants accumulated Essence based on badge attributes over time.
    *   `depositEssenceForBoost`: Allows spending Essence to apply a temporary attribute boost.
    *   `requestOracleBlessing`: Simulates requesting a blessing (potentially requiring Essence).
    *   `proposeTraitUpgrade`: Allows proposing a simulated governance action based on WisdomLevel.
    *   `mergeBadges`: Combines two badges into a new one with derived attributes, burning the originals.
    *   `derivePermission`: Checks if a badge's current attributes meet the requirements for a specific permission identifier.
    *   `lockBadgeForQuest`: Temporarily locks a badge, preventing attribute-modifying actions.
    *   `completeQuest`: Unlocks a locked badge and updates attributes/rewards based on simulated quest outcome.

*   **Configuration & Access Control (3 functions):**
    *   `setDecayRate`: Sets the rate at which attributes decay (CONFIG_ROLE).
    *   `setEssenceMintRate`: Sets the rate at which Essence accrues (CONFIG_ROLE).
    *   `setQuestDuration`: Sets the duration for simulated quests (CONFIG_ROLE).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ERC165.sol";

// Outline & Function Summary is provided above the contract code.

contract ChronoBadge is ERC165, AccessControl, Pausable {

    // --- Errors ---
    error BadgeNotFound(uint256 tokenId);
    error NotBadgeOwnerOrAttuned(uint256 tokenId, address caller);
    error NotBadgeOwner(uint256 tokenId, address caller);
    error BadgeAlreadyAttuned(uint256 tokenId);
    error BadgeNotAttuned(uint256 tokenId);
    error AttunementNotExpired(uint256 tokenId);
    error AttunementActive(uint256 tokenId);
    error InsufficientEssence(address account, uint256 requiredAmount);
    error AttributeConditionNotMet(string requiredCondition);
    error BadgeLocked(uint256 tokenId);
    error BadgeNotLocked(uint256 tokenId);
    error CannotMergeAttunedBadges(uint256 tokenId);
    error CannotMergeSameBadge();
    error OracleUpdateInvalid(uint256 tokenId, string reason);


    // --- State Variables ---
    uint256 private _tokenIdCounter;

    // Basic ERC721-like tracking (simplified, not full standard)
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;

    // ChronoBadge specific data
    struct BadgeAttributes {
        uint64 interactionScore; // Earned through various interactions
        uint64 wisdomLevel;      // Earned through learning/quests
        uint64 attunementFactor; // Increases chances of successful attunement, task success
        uint64 accumulatedTime;  // Simulated time spent/activity level
        uint64 lastUpdatedTimestamp; // Timestamp of last attribute change/decay check
    }
    mapping(uint256 => BadgeAttributes) private _badgeAttributes;

    mapping(uint256 => bool) private _isSoulbound; // Initially true, might change conditionally? (Currently always true)
    mapping(uint256 => address) private _attunedTo; // Address badge is temporarily attuned to
    mapping(uint256 => uint40) private _attunementExpiration; // Timestamp when attunement ends

    mapping(address => uint256) private _essenceBalance; // Internal utility token balance

    mapping(uint256 => bool) private _badgeLocked; // Flag for quests or other states
    mapping(uint256 => uint40) private _lockedUntil; // Timestamp until badge is locked

    // Configuration Variables (Role controlled)
    uint256 public decayRatePerUnitTime; // Amount of attribute decay per second/hour (example)
    uint256 public essenceMintRatePerTimePerAttribute; // Essence per sec/hr based on a combined attribute score
    uint256 public questDuration; // Default duration for simulated quests

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ATTRIBUTE_ORACLE_ROLE = keccak256("ATTRIBUTE_ORACLE_ROLE"); // Can update attributes based on external data
    bytes32 public constant TASK_MASTER_ROLE = keccak256("TASK_MASTER_ROLE"); // Can trigger task completion/rewards
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE"); // Can set configuration variables
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Can pause the contract

    // --- Events ---
    event BadgeMinted(uint256 indexed tokenId, address indexed owner);
    event BadgeBurned(uint256 indexed tokenId, address indexed owner);
    event AttributesUpdated(uint256 indexed tokenId, BadgeAttributes newAttributes);
    event BadgeAttuned(uint256 indexed tokenId, address indexed originalOwner, address indexed attunedTo, uint40 expiration);
    event AttunementReleased(uint256 indexed tokenId, address indexed originalOwner, address indexed previousAttunedTo);
    event EssenceClaimed(address indexed owner, uint256 amount);
    event EssenceDepositedForBoost(address indexed owner, uint256 tokenId, uint256 amount);
    event BadgesMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId);
    event BadgeLockedForQuest(uint256 indexed tokenId, uint40 lockedUntil);
    event BadgeUnlocked(uint256 indexed tokenId);


    // --- Constructor ---
    constructor(uint256 _initialDecayRate, uint256 _initialEssenceRate, uint256 _initialQuestDuration) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(CONFIG_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        decayRatePerUnitTime = _initialDecayRate;
        essenceMintRatePerTimePerAttribute = _initialEssenceRate;
        questDuration = _initialQuestDuration;

        _tokenIdCounter = 0; // Token IDs start from 1
    }

    // --- ERC165 Support ---
    // Supports basic ERC721 functions via manual implementation
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // ERC165 interface ID
        bytes4 interfaceIdERC165 = 0x01ffc9a7;
        // This is a simplified ERC721 implementation, not supporting transfers or approvals fully.
        // We'll only declare support for ERC165 itself and maybe a custom interface later if needed.
        return interfaceId == interfaceIdERC165 || super.supportsInterface(interfaceId);
    }

    // --- Access Control & Pausability ---
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // --- Badge Lifecycle & Core ---

    /// @notice Creates a new ChronoBadge for a recipient.
    /// @param recipient The address to mint the badge to.
    /// @param initialAttributes The starting attributes for the new badge.
    function mintBadge(address recipient, BadgeAttributes calldata initialAttributes)
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        uint256 newTokenId = ++_tokenIdCounter;
        _ownerOf[newTokenId] = recipient;
        _balanceOf[recipient]++;
        _badgeAttributes[newTokenId] = initialAttributes;
        _badgeAttributes[newTokenId].lastUpdatedTimestamp = uint64(block.timestamp); // Set initial update time
        _isSoulbound[newTokenId] = true; // Badges are soulbound by default
        emit BadgeMinted(newTokenId, recipient);
    }

    /// @notice Destroys a ChronoBadge. Only callable by owner or attuned address if conditions met.
    /// @param tokenId The ID of the badge to burn.
    function burnBadge(uint256 tokenId) external whenNotPaused {
        address owner = _ownerOf[tokenId];
        if (owner == address(0)) revert BadgeNotFound(tokenId);

        // Only owner can burn soulbound badge unless specific conditions allowed attunement burn (not implemented here)
        if (_isSoulbound[tokenId]) {
             if (msg.sender != owner) revert NotBadgeOwner(tokenId, msg.sender);
        } else {
            // If not soulbound, check owner or attuned
            address attuned = _attunedTo[tokenId];
            if (msg.sender != owner && msg.sender != attuned) revert NotBadgeOwnerOrAttuned(tokenId, msg.sender);
        }

        // Cannot burn if locked or attuned
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);
        if (_attunedTo[tokenId] != address(0)) revert AttunementActive(tokenId);


        delete _ownerOf[tokenId];
        _balanceOf[owner]--;
        delete _badgeAttributes[tokenId];
        delete _isSoulbound[tokenId];
        delete _attunedTo[tokenId];
        delete _attunementExpiration[tokenId];
        delete _badgeLocked[tokenId];
        delete _lockedUntil[tokenId];

        emit BadgeBurned(tokenId, owner);
    }


    /// @notice Returns the owner of the badge.
    /// @param tokenId The ID of the badge.
    /// @return The address of the badge owner.
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _ownerOf[tokenId];
        if (owner == address(0)) revert BadgeNotFound(tokenId);
        return owner;
    }

    /// @notice Returns the number of badges owned by an account.
    /// @param owner The address to query.
    /// @return The number of badges owned by the address.
    function balanceOf(address owner) public view returns (uint256) {
        return _balanceOf[owner];
    }

     /// @notice Retrieves the current dynamic attributes of a badge.
     /// @param tokenId The ID of the badge.
     /// @return The BadgeAttributes struct for the badge.
     function getBadgeAttributes(uint256 tokenId) public view returns (BadgeAttributes memory) {
         if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
         // Apply potential decay conceptually before returning, though state update happens on change/poke
         return _badgeAttributes[tokenId];
     }

    /// @notice Checks if a badge is soulbound (non-transferable).
    /// @param tokenId The ID of the badge.
    /// @return True if soulbound, false otherwise.
    function isSoulbound(uint256 tokenId) public view returns (bool) {
         if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
         return _isSoulbound[tokenId];
    }


    // --- Attunement & Conditional Transfer ---

    /// @notice Temporarily attunes a badge to another address.
    /// Requires owner to call, badge not already attuned, and owner meets attribute threshold.
    /// @param tokenId The ID of the badge.
    /// @param to The address to attune the badge to.
    /// @param durationSeconds The duration of the attunement in seconds.
    function attuneBadge(uint256 tokenId, address to, uint40 durationSeconds)
        external
        whenNotPaused
    {
        address owner = _ownerOf[tokenId];
        if (owner == address(0)) revert BadgeNotFound(tokenId);
        if (msg.sender != owner) revert NotBadgeOwner(tokenId, msg.sender);
        if (_attunedTo[tokenId] != address(0)) revert BadgeAlreadyAttuned(tokenId);
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        // Example Condition: Requires a certain AttunementFactor to attune
        _applyDecay(tokenId); // Apply decay before checking attributes
        if (_badgeAttributes[tokenId].attunementFactor < 50) { // Example threshold
             revert AttributeConditionNotMet("AttunementFactor >= 50");
        }

        _attunedTo[tokenId] = to;
        _attunementExpiration[tokenId] = uint40(block.timestamp + durationSeconds);
        emit BadgeAttuned(tokenId, owner, to, _attunementExpiration[tokenId]);
    }

    /// @notice Releases an active attunement. Can be called by owner or attuned address after expiration.
    /// @param tokenId The ID of the badge.
    function releaseAttunement(uint256 tokenId) external whenNotPaused {
        address owner = _ownerOf[tokenId];
        if (owner == address(0)) revert BadgeNotFound(tokenId);
        address attuned = _attunedTo[tokenId];
        if (attuned == address(0)) revert BadgeNotAttuned(tokenId);

        // Can be released by owner anytime, or by attuned address AFTER expiration
        bool isOwner = msg.sender == owner;
        bool isAttunedExpired = msg.sender == attuned && block.timestamp >= _attunementExpiration[tokenId];

        if (!isOwner && !isAttunedExpired) {
            if (msg.sender == attuned) {
                 revert AttunementNotExpired(tokenId);
            } else {
                 revert NotBadgeOwnerOrAttuned(tokenId, msg.sender);
            }
        }

        address prevAttunedTo = _attunedTo[tokenId];
        delete _attunedTo[tokenId];
        delete _attunementExpiration[tokenId];
        emit AttunementReleased(tokenId, owner, prevAttunedTo);
    }

    /// @notice Checks if a badge is currently attuned and returns the attuned address and expiration.
    /// @param tokenId The ID of the badge.
    /// @return attunedAddress The address the badge is attuned to (address(0) if not attuned).
    /// @return expirationTimestamp The timestamp when attunement expires (0 if not attuned).
    function isAttuned(uint256 tokenId) public view returns (address attunedAddress, uint40 expirationTimestamp) {
         if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
         return (_attunedTo[tokenId], _attunementExpiration[tokenId]);
    }


    // --- Attribute Management & Dynamics ---

    /// @notice Increments the InteractionScore of a badge. Callable by TASK_MASTER_ROLE.
    /// @param tokenId The ID of the badge.
    /// @param amount The amount to increment by.
    function incrementInteractionScore(uint256 tokenId, uint64 amount)
        external
        onlyRole(TASK_MASTER_ROLE)
        whenNotPaused
    {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        _applyDecay(tokenId);
        _badgeAttributes[tokenId].interactionScore += amount;
        _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
        emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]);
    }

    /// @notice Simulates passage of time/activity for a badge, increasing AccumulatedTime. Callable by TASK_MASTER_ROLE.
    /// @param tokenId The ID of the badge.
    /// @param timeUnits Simulated units of time spent.
    function gainAccumulatedTime(uint256 tokenId, uint64 timeUnits)
        external
        onlyRole(TASK_MASTER_ROLE)
        whenNotPaused
    {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        _applyDecay(tokenId);
        _badgeAttributes[tokenId].accumulatedTime += timeUnits;
         _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
        emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]);
    }

    /// @notice Increases WisdomLevel of a badge. Requires a minimum InteractionScore. Callable by TASK_MASTER_ROLE.
    /// @param tokenId The ID of the badge.
    function learnFromKnowledgePool(uint256 tokenId)
        external
        onlyRole(TASK_MASTER_ROLE)
        whenNotPaused
    {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        _applyDecay(tokenId);
        if (_badgeAttributes[tokenId].interactionScore < 100) { // Example threshold
             revert AttributeConditionNotMet("InteractionScore >= 100");
        }

        _badgeAttributes[tokenId].wisdomLevel++; // Simple increment
         _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
        emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]);
    }

    /// @notice Simulates performing a task, potentially increasing AttunementFactor and rewarding Essence. Callable by TASK_MASTER_ROLE.
    /// Requires a minimum WisdomLevel.
    /// @param tokenId The ID of the badge.
    /// @param successFactor A simulated measure of task success (e.g., 0-100).
    function performTask(uint256 tokenId, uint64 successFactor)
        external
        onlyRole(TASK_MASTER_ROLE)
        whenNotPaused
    {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        _applyDecay(tokenId);
        if (_badgeAttributes[tokenId].wisdomLevel < 10) { // Example threshold
            revert AttributeConditionNotMet("WisdomLevel >= 10");
        }

        // Update AttunementFactor based on success
        _badgeAttributes[tokenId].attunementFactor += successFactor / 10; // Example logic

        // Reward Essence based on success and existing attributes
        uint256 essenceReward = (uint256(successFactor) * (_badgeAttributes[tokenId].accumulatedTime + _badgeAttributes[tokenId].interactionScore)) / 1000; // Example logic
        if (essenceReward > 0) {
            _essenceBalance[_ownerOf[tokenId]] += essenceReward;
        }

         _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
        emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]);
    }

    /// @notice Applies a temporary blessing (attribute boost) to a badge. Callable by ATTRIBUTE_ORACLE_ROLE.
    /// This implementation is simplified; a real boost might use separate mapping with expiration.
    /// Here it's a direct additive update for demonstration.
    /// @param tokenId The ID of the badge.
    /// @param boostAttributes The attributes to add as a boost.
    function applyBlessing(uint256 tokenId, BadgeAttributes calldata boostAttributes)
        external
        onlyRole(ATTRIBUTE_ORACLE_ROLE)
        whenNotPaused
    {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
         if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        _applyDecay(tokenId); // Apply decay before boosting

        _badgeAttributes[tokenId].interactionScore += boostAttributes.interactionScore;
        _badgeAttributes[tokenId].wisdomLevel += boostAttributes.wisdomLevel;
        _badgeAttributes[tokenId].attunementFactor += boostAttributes.attunementFactor;
        _badgeAttributes[tokenId].accumulatedTime += boostAttributes.accumulatedTime;
         _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
        emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]);
    }

    /// @notice Triggers attribute decay calculation for a specific badge based on time elapsed.
    /// This function can be called by anyone (gas pull) but only updates if enough time has passed.
    /// @param tokenId The ID of the badge.
    function decayAttributes(uint256 tokenId) external whenNotPaused {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        // No lock check needed, decay happens regardless

        _applyDecay(tokenId);
        // No need to emit event if only decay is applied and no other changes happen
    }

    /// @notice Allows an Oracle role to update attributes based on simulated external data.
    /// Example: Update based on simulated weather, market conditions, etc.
    /// @param tokenId The ID of the badge.
    /// @param attributeName The name of the attribute to update (e.g., "wisdomLevel").
    /// @param newValue The new value for the attribute.
    /// @param oracleDataHash A hash of the simulated oracle data for verification (not fully implemented here).
    function updateAttributeBasedOnOracle(
        uint256 tokenId,
        string calldata attributeName,
        uint64 newValue,
        bytes32 oracleDataHash // Simulated data integrity proof
    )
        external
        onlyRole(ATTRIBUTE_ORACLE_ROLE)
        whenNotPaused
    {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

         _applyDecay(tokenId); // Apply decay before applying oracle update

        bytes32 nameHash = keccak256(bytes(attributeName));
        bool updated = false;

        // --- Apply Oracle Update Based on Name ---
        // In a real system, this would involve verifying oracle signature/data.
        // Here, we just simulate different updates based on a string name.
        if (nameHash == keccak256("interactionScore")) {
             _badgeAttributes[tokenId].interactionScore = newValue;
             updated = true;
        } else if (nameHash == keccak256("wisdomLevel")) {
             _badgeAttributes[tokenId].wisdomLevel = newValue;
             updated = true;
        } else if (nameHash == keccak256("attunementFactor")) {
             _badgeAttributes[tokenId].attunementFactor = newValue;
             updated = true;
        } else if (nameHash == keccak256("accumulatedTime")) {
             _badgeAttributes[tokenId].accumulatedTime = newValue;
             updated = true;
        } else {
            revert OracleUpdateInvalid(tokenId, "Unknown attribute name");
        }

        if (updated) {
             _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
             emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]);
        }
    }


    // --- Ecosystem & Utility ---

    /// @notice Calculates and allows the owner to claim accumulated Essence based on badge attributes and time.
    /// Essence is calculated since the last attribute update/claim. Requires minimum AttunementFactor.
    /// @param tokenId The ID of the badge.
    function claimEssence(uint256 tokenId) external whenNotPaused {
         address owner = _ownerOf[tokenId];
         if (owner == address(0)) revert BadgeNotFound(tokenId);
         // Callable by owner or attuned address
         address currentActor = msg.sender;
         address attuned = _attunedTo[tokenId];
         bool isOwner = currentActor == owner;
         bool isAttunedActor = currentActor == attuned && block.timestamp < _attunementExpiration[tokenId]; // Attuned can claim during attunement

         if (!isOwner && !isAttunedActor) revert NotBadgeOwnerOrAttuned(tokenId, currentActor);
         if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

         // Apply decay and calculate time elapsed since last update
         _applyDecay(tokenId); // Apply decay, also updates lastUpdatedTimestamp

         // Example: Essence accrues based on a combination of attributes and time
         // This is a simplified formula; more complex models possible.
         uint256 timeElapsed = block.timestamp - _badgeAttributes[tokenId].lastUpdatedTimestamp;
         uint256 combinedScore = uint256(_badgeAttributes[tokenId].wisdomLevel + _badgeAttributes[tokenId].attunementFactor);
         uint256 pendingEssence = (combinedScore * timeElapsed * essenceMintRatePerTimePerAttribute) / 1000000; // Adjust divisor based on desired rate

         // Example Condition: Requires a minimum AttunementFactor to claim
         if (_badgeAttributes[tokenId].attunementFactor < 20) { // Example threshold
              revert AttributeConditionNotMet("AttunementFactor >= 20 for claiming Essence");
         }

         if (pendingEssence > 0) {
             // Essence goes to the original owner, regardless of attunement
             _essenceBalance[owner] += pendingEssence;
             emit EssenceClaimed(owner, pendingEssence);
         }
         // Update timestamp AFTER calculation and claim
         _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
          emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]); // Attributes might have changed due to decay
    }

    /// @notice Allows spending Essence to apply a temporary attribute boost to a badge.
    /// This implementation is simplified; a real boost might use separate mapping with expiration.
    /// Here it's a direct additive update for demonstration, balanced by Essence cost.
    /// @param tokenId The ID of the badge.
    /// @param essenceAmount The amount of Essence to spend.
    function depositEssenceForBoost(uint256 tokenId, uint256 essenceAmount)
        external
        whenNotPaused
    {
        address owner = _ownerOf[tokenId];
        if (owner == address(0)) revert BadgeNotFound(tokenId);
        // Callable by owner or attuned address
         address currentActor = msg.sender;
         address attuned = _attunedTo[tokenId];
         bool isOwner = currentActor == owner;
         bool isAttunedActor = currentActor == attuned && block.timestamp < _attunementExpiration[tokenId]; // Attuned can spend during attunement

         if (!isOwner && !isAttunedActor) revert NotBadgeOwnerOrAttuned(tokenId, currentActor);
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        if (_essenceBalance[currentActor] < essenceAmount) revert InsufficientEssence(currentActor, essenceAmount);

        _applyDecay(tokenId); // Apply decay before boosting

        // Example Boost Logic: Essence buys a combination of boosts
        uint64 boostValue = uint64(essenceAmount / 100); // 100 Essence per boost point (example rate)
        _badgeAttributes[tokenId].interactionScore += boostValue;
        _badgeAttributes[tokenId].wisdomLevel += boostValue / 2; // Wisdom is harder to boost
        _badgeAttributes[tokenId].attunementFactor += boostValue / 5; // Attunement is hardest

        _essenceBalance[currentActor] -= essenceAmount; // Burn Essence

        _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
        emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]);
        emit EssenceDepositedForBoost(currentActor, tokenId, essenceAmount);
    }

    /// @notice Simulates requesting a blessing, potentially consuming Essence or requiring attributes.
    /// The actual blessing application is handled by `applyBlessing` (Oracle role).
    /// This function just models the user's request and checks conditions.
    /// @param tokenId The ID of the badge.
    /// @param blessingType Identifier for the type of blessing requested.
    function requestOracleBlessing(uint256 tokenId, string calldata blessingType)
        external
        whenNotPaused
    {
         address owner = _ownerOf[tokenId];
         if (owner == address(0)) revert BadgeNotFound(tokenId);
         // Callable by owner or attuned address
         address currentActor = msg.sender;
         address attuned = _attunedTo[tokenId];
         bool isOwner = currentActor == owner;
         bool isAttunedActor = currentActor == attuned && block.timestamp < _attunementExpiration[tokenId];

         if (!isOwner && !isAttunedActor) revert NotBadgeOwnerOrAttuned(tokenId, currentActor);
         if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        _applyDecay(tokenId); // Apply decay before checking conditions

        // Example Condition: Requires Essence OR High Wisdom to request certain blessings
        bytes32 blessingHash = keccak256(bytes(blessingType));
        if (blessingHash == keccak256("majorBoost")) {
             if (_essenceBalance[currentActor] < 500 && _badgeAttributes[tokenId].wisdomLevel < 50) {
                 revert AttributeConditionNotMet("Requires 500 Essence or WisdomLevel >= 50");
             }
             // If essence is required, burn it here
             if (_essenceBalance[currentActor] >= 500) {
                  _essenceBalance[currentActor] -= 500;
             }
        }
        // Event can be emitted here to signal request to oracle system
        // emit BlessingRequested(tokenId, currentActor, blessingType);
        // The actual blessing (applyBlessing) happens via the Oracle role separately
    }

    /// @notice Allows proposing a simulated trait upgrade (e.g., via governance).
    /// Requires high WisdomLevel and AttunementFactor. Does not implement actual governance.
    /// @param tokenId The ID of the badge.
    /// @param proposedChangeDescription A description of the proposed change.
    function proposeTraitUpgrade(uint256 tokenId, string calldata proposedChangeDescription)
        external
        whenNotPaused
    {
         address owner = _ownerOf[tokenId];
         if (owner == address(0)) revert BadgeNotFound(tokenId);
         // Callable by owner or attuned address
         address currentActor = msg.sender;
         address attuned = _attunedTo[tokenId];
         bool isOwner = currentActor == owner;
         bool isAttunedActor = currentActor == attuned && block.timestamp < _attunementExpiration[tokenId];

         if (!isOwner && !isAttunedActor) revert NotBadgeOwnerOrAttuned(tokenId, currentActor);
         if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId);

        _applyDecay(tokenId); // Apply decay before checking conditions

        // Example Condition: Requires high attributes to propose
        if (_badgeAttributes[tokenId].wisdomLevel < 75 || _badgeAttributes[tokenId].attunementFactor < 60) {
            revert AttributeConditionNotMet("Requires WisdomLevel >= 75 and AttunementFactor >= 60 to propose");
        }

        // In a real system, this would interact with a governance contract.
        // Here, it's just a signal event.
        // emit TraitUpgradeProposed(tokenId, currentActor, proposedChangeDescription);
    }

    /// @notice Merges two ChronoBadges into a new one, combining/deriving attributes.
    /// Burns the two input badges. Requires caller to own both (or be attuned with permission).
    /// @param tokenId1 The ID of the first badge.
    /// @param tokenId2 The ID of the second badge.
    /// @return The ID of the newly minted badge.
    function mergeBadges(uint256 tokenId1, uint256 tokenId2)
        external
        onlyRole(MINTER_ROLE) // Merging is a minting process, controlled by Minter
        whenNotPaused
        returns (uint256 newTokenId)
    {
        if (tokenId1 == tokenId2) revert CannotMergeSameBadge();

        address owner1 = _ownerOf[tokenId1];
        address owner2 = _ownerOf[tokenId2];

        if (owner1 == address(0)) revert BadgeNotFound(tokenId1);
        if (owner2 == address(0)) revert BadgeNotFound(tokenId2);

        // In this simple implementation, Minter role triggers merge,
        // assuming external logic (e.g., a separate contract or UI)
        // verified the user's ownership/attunement of both BEFORE calling this.
        // A more robust version might check msg.sender ownership directly here.

        if (_badgeLocked[tokenId1] || _badgeLocked[tokenId2]) revert BadgeLocked(tokenId1); // Or tokenId2
        if (_attunedTo[tokenId1] != address(0) || _attunedTo[tokenId2] != address(0)) revert CannotMergeAttunedBadges(tokenId1); // Or tokenId2


        _applyDecay(tokenId1); // Apply decay before merging
        _applyDecay(tokenId2);

        BadgeAttributes memory attrs1 = _badgeAttributes[tokenId1];
        BadgeAttributes memory attrs2 = _badgeAttributes[tokenId2];

        // --- Example Merge Logic ---
        // New attributes could be sum, average, max, or a weighted formula.
        // Let's do a simple weighted average/sum for demonstration.
        BadgeAttributes memory newAttrs;
        newAttrs.interactionScore = (attrs1.interactionScore + attrs2.interactionScore) / 2 + 10; // Average + bonus
        newAttrs.wisdomLevel = (attrs1.wisdomLevel > attrs2.wisdomLevel ? attrs1.wisdomLevel : attrs2.wisdomLevel) + 5; // Max + bonus
        newAttrs.attunementFactor = (attrs1.attunementFactor + attrs2.attunementFactor) * 6 / 10; // Weighted sum
        newAttrs.accumulatedTime = attrs1.accumulatedTime + attrs2.accumulatedTime; // Sum
        newAttrs.lastUpdatedTimestamp = uint64(block.timestamp); // Set new timestamp

        // Ensure attributes don't overflow uint64 (though unlikely with these values)
        // In a real contract, consider checked arithmetic or capping.

        // Burn old badges (simplified burn logic)
        delete _ownerOf[tokenId1];
        _balanceOf[owner1]--;
        delete _badgeAttributes[tokenId1];
        delete _isSoulbound[tokenId1];
        delete _attunedTo[tokenId1];
        delete _attunementExpiration[tokenId1];
        delete _badgeLocked[tokenId1];
        delete _lockedUntil[tokenId1];
        emit BadgeBurned(tokenId1, owner1);


        // Assuming owner1 and owner2 could be different. The new badge should probably go to one of them.
        // Let's say it goes to owner1 for simplicity.
        delete _ownerOf[tokenId2];
        _balanceOf[owner2]--; // Decrement balance of owner2
        delete _badgeAttributes[tokenId2];
        delete _isSoulbound[tokenId2];
        delete _attunedTo[tokenId2];
        delete _attunementExpiration[tokenId2];
        delete _badgeLocked[tokenId2];
        delete _lockedUntil[tokenId2];
        emit BadgeBurned(tokenId2, owner2);


        // Mint the new badge to owner1
        newTokenId = ++_tokenIdCounter;
        _ownerOf[newTokenId] = owner1; // New owner is owner1
        _balanceOf[owner1]++; // Increment balance of new owner
        _badgeAttributes[newTokenId] = newAttrs;
        _isSoulbound[newTokenId] = true; // Merged badges are also soulbound
        emit BadgeMinted(newTokenId, owner1);
        emit AttributesUpdated(newTokenId, newAttrs);
        emit BadgesMerged(tokenId1, tokenId2, newTokenId);

        return newTokenId;
    }

    /// @notice Checks if a badge's attributes meet the criteria for a specific permission.
    /// This is a view function used by external systems to check capabilities.
    /// @param tokenId The ID of the badge.
    /// @param permissionId A string identifier for the permission (e.g., "accessKnowledgeTier2", "canVoteOnProposals").
    /// @return True if the badge grants the permission, false otherwise.
    function derivePermission(uint256 tokenId, string calldata permissionId)
        public
        view
        returns (bool)
    {
        if (_ownerOf[tokenId] == address(0)) return false; // Cannot have permission if badge doesn't exist

        BadgeAttributes storage attrs = _badgeAttributes[tokenId];
        bytes32 permissionHash = keccak256(bytes(permissionId));

        // --- Example Permission Logic ---
        if (permissionHash == keccak256("accessKnowledgeTier2")) {
            return attrs.wisdomLevel >= 30 && attrs.interactionScore >= 200;
        } else if (permissionHash == keccak256("canVoteOnProposals")) {
            return attrs.wisdomLevel >= 70 && attrs.accumulatedTime >= 500;
        } else if (permissionHash == keccak256("unlockSecretArea")) {
            return attrs.attunementFactor >= 90 && attrs.wisdomLevel >= 60 && attrs.interactionScore >= 500;
        }
        // Add more permission checks here...

        return false; // Unknown permission ID or conditions not met
    }

    /// @notice Locks a badge for a simulated quest or activity. Callable by TASK_MASTER_ROLE.
    /// Prevents attribute changes or transfers while locked.
    /// @param tokenId The ID of the badge to lock.
    /// @param lockDurationSeconds The duration to lock the badge for.
    function lockBadgeForQuest(uint256 tokenId, uint40 lockDurationSeconds)
        external
        onlyRole(TASK_MASTER_ROLE)
        whenNotPaused
    {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        if (_badgeLocked[tokenId]) revert BadgeLocked(tokenId); // Already locked
        if (_attunedTo[tokenId] != address(0)) revert AttunementActive(tokenId); // Cannot lock if attuned

        _badgeLocked[tokenId] = true;
        _lockedUntil[tokenId] = uint40(block.timestamp + lockDurationSeconds);
        emit BadgeLockedForQuest(tokenId, _lockedUntil[tokenId]);
    }

    /// @notice Completes a simulated quest, unlocking the badge and applying rewards. Callable by TASK_MASTER_ROLE.
    /// Rewards depend on original badge attributes and simulated outcome.
    /// @param tokenId The ID of the badge to unlock.
    /// @param questOutcomeRewardAttributes Attributes to add as reward.
    /// @param essenceReward Amount of Essence to reward.
    function completeQuest(
        uint256 tokenId,
        BadgeAttributes calldata questOutcomeRewardAttributes,
        uint256 essenceReward
    )
        external
        onlyRole(TASK_MASTER_ROLE)
        whenNotPaused
    {
        if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        if (!_badgeLocked[tokenId]) revert BadgeNotLocked(tokenId);

        // Optional: Check if lock duration has passed or allow early completion by role
        // if (block.timestamp < _lockedUntil[tokenId]) { /* potentially allow with override role */ }

        _applyDecay(tokenId); // Apply decay before adding rewards

        // Apply rewards
        _badgeAttributes[tokenId].interactionScore += questOutcomeRewardAttributes.interactionScore;
        _badgeAttributes[tokenId].wisdomLevel += questOutcomeRewardAttributes.wisdomLevel;
        _badgeAttributes[tokenId].attunementFactor += questOutcomeRewardAttributes.attunementFactor;
        _badgeAttributes[tokenId].accumulatedTime += questOutcomeRewardAttributes.accumulatedTime;

        // Reward Essence
        if (essenceReward > 0) {
             _essenceBalance[_ownerOf[tokenId]] += essenceReward; // Essence goes to owner
        }

        // Unlock the badge
        delete _badgeLocked[tokenId];
        delete _lockedUntil[tokenId];

         _badgeAttributes[tokenId].lastUpdatedTimestamp = uint64(block.timestamp);
        emit AttributesUpdated(tokenId, _badgeAttributes[tokenId]);
        emit BadgeUnlocked(tokenId);
        if (essenceReward > 0) {
             emit EssenceClaimed(_ownerOf[tokenId], essenceReward); // Emit Essence claimed event
        }
    }

    // --- Configuration ---

    /// @notice Sets the rate at which badge attributes decay.
    /// @param rate The new decay rate per unit of time.
    function setDecayRate(uint256 rate) external onlyRole(CONFIG_ROLE) {
        decayRatePerUnitTime = rate;
    }

    /// @notice Sets the rate at which Essence is minted.
    /// @param rate The new Essence mint rate per time unit per combined attribute score.
    function setEssenceMintRate(uint256 rate) external onlyRole(CONFIG_ROLE) {
        essenceMintRatePerTimePerAttribute = rate;
    }

    /// @notice Sets the default duration for simulated quests.
    /// @param durationSeconds The default quest duration in seconds.
    function setQuestDuration(uint256 durationSeconds) external onlyRole(CONFIG_ROLE) {
        questDuration = durationSeconds;
    }


    // --- Internal Helper Functions ---

    /// @dev Applies attribute decay to a badge based on time elapsed since last update.
    /// Updates the lastUpdatedTimestamp.
    function _applyDecay(uint256 tokenId) internal {
        uint64 currentTime = uint64(block.timestamp);
        uint64 lastUpdate = _badgeAttributes[tokenId].lastUpdatedTimestamp;

        if (currentTime > lastUpdate) {
            uint64 timeElapsed = currentTime - lastUpdate;
            uint256 decayAmount = (uint256(timeElapsed) * decayRatePerUnitTime) / 1000000; // Adjust divisor based on rate interpretation

            if (decayAmount > 0) {
                // Apply decay, ensuring attributes don't go below zero
                _badgeAttributes[tokenId].interactionScore = uint64(_badgeAttributes[tokenId].interactionScore > decayAmount ? _badgeAttributes[tokenId].interactionScore - decayAmount : 0);
                _badgeAttributes[tokenId].wisdomLevel = uint64(_badgeAttributes[tokenId].wisdomLevel > decayAmount / 2 ? _badgeAttributes[tokenId].wisdomLevel - decayAmount / 2 : 0); // Wisdom decays slower
                _badgeAttributes[tokenId].attunementFactor = uint64(_badgeAttributes[tokenId].attunementFactor > decayAmount ? _badgeAttributes[tokenId].attunementFactor - decayAmount : 0);
                // AccumulatedTime might not decay, or decay differently. Let's not decay AccumulatedTime for now.
                // _badgeAttributes[tokenId].accumulatedTime = uint64(_badgeAttributes[tokenId].accumulatedTime > decayAmount ? _badgeAttributes[tokenId].accumulatedTime - decayAmount : 0);
            }
             _badgeAttributes[tokenId].lastUpdatedTimestamp = currentTime;
        }
    }

    // --- Additional view functions ---

    /// @notice Get the Essence balance for an account.
    /// @param account The address to query.
    /// @return The Essence balance.
    function getEssenceBalance(address account) external view returns (uint256) {
        return _essenceBalance[account];
    }

    /// @notice Check if a badge is currently locked.
    /// @param tokenId The ID of the badge.
    /// @return True if locked, false otherwise.
    function isBadgeLocked(uint256 tokenId) external view returns (bool) {
         if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
        return _badgeLocked[tokenId];
    }

    /// @notice Get the timestamp until a badge is locked.
    /// @param tokenId The ID of the badge.
    /// @return The timestamp until the badge is locked (0 if not locked).
     function getLockedUntil(uint256 tokenId) external view returns (uint40) {
         if (_ownerOf[tokenId] == address(0)) revert BadgeNotFound(tokenId);
         return _lockedUntil[tokenId];
     }
}
```