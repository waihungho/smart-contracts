Okay, let's design an interesting, advanced smart contract. We'll create a "Dynamic Chronicle NFT" system.

This contract will manage ERC-721 tokens that aren't static JPEGs. Instead, they represent a user's "Chronicle" within an ecosystem. The NFT's attributes, level, and potential metadata will change based on actions, achievements, and interactions attested to the contract.

It incorporates concepts like:
1.  **Dynamic State:** NFT attributes change based on user activity.
2.  **Reputation/Experience System:** Points tied to the NFT that unlock progression.
3.  **Achievement Tracking:** Marking milestones directly on the NFT.
4.  **Forging/Upgrading:** Burning reputation/achievements to permanently level up the NFT.
5.  **Attestation Mechanism:** A secure way for trusted third parties (or other contracts) to record interactions or events that affect a Chronicle.
6.  **Delegated Permissions:** Allowing the contract owner or even NFT owners to delegate specific rights.
7.  **Metadata Generation:** The `tokenURI` reflects the current dynamic state.

This combination provides a rich, non-standard NFT utility beyond simple ownership and transfer.

---

### Chronicle Forge Smart Contract: Outline and Function Summary

**Contract Name:** `ChronicleForge`

**Purpose:** Manages a collection of dynamic ERC-721 "Chronicle" NFTs. These NFTs track user progress, reputation, and achievements within a specific ecosystem. Their state and potential metadata evolve based on attested interactions and forging actions.

**Core Concepts:**
*   **Chronicle:** An ERC-721 token representing a user's historical journey, state, and reputation.
*   **Reputation:** A non-transferable score tied to a specific Chronicle, earned through interactions.
*   **Achievements:** Specific milestones that can be attained by a Chronicle.
*   **Forging:** The process of consuming Reputation/Achievements to upgrade a Chronicle's permanent level and attributes.
*   **Attestation:** A mechanism for trusted entities to securely record events/interactions that impact a Chronicle.

**State Variables & Mappings:**
*   `_nextTokenId`: Counter for new Chronicles.
*   `chronicleStates`: Maps `tokenId` to its dynamic state (`reputation`, `level`, etc.).
*   `attainedAchievements`: Maps `tokenId` to a mapping of `achievementId` to a boolean (whether attained).
*   `achievementDetails`: Maps `achievementId` to its definition (`name`, requirements, etc.).
*   `trustedInteractors`: Maps address to boolean (can perform certain actions like attesting).
*   `attestationDelegations`: Maps `interactionType` string to an address that can attest for it.
*   `interactionCounts`: Maps `tokenId` to `interactionType` string to count (how many times this interaction occurred for this token).
*   `forgeParameters`: Struct holding global parameters like reputation per level, forging costs, etc.
*   `_baseTokenURI`: Base string for metadata URIs.

**Structs:**
*   `ChronicleState`: Holds dynamic data per NFT (uint256 reputation, uint256 level).
*   `AchievementDetails`: Defines an achievement (string name, uint256 requiredReputation, mapping interactionType to count).
*   `ForgeParameters`: Configurable parameters for the forging/reputation system.

**Events:**
*   `ChronicleMinted`: When a new Chronicle is created.
*   `ChronicleBurned`: When a Chronicle is destroyed.
*   `ReputationGained`: When a Chronicle's reputation increases.
*   `AchievementAttained`: When a Chronicle reaches an achievement.
*   `ChronicleUpgraded`: When a Chronicle is forged to a new level.
*   `InteractionAttested`: When a specific interaction is recorded for a Chronicle.
*   `AttestationDelegated`: When permission to attest for an interaction type is delegated.
*   `AttestationRevoked`: When attestation delegation is removed.
*   `TrustedInteractorSet`: When an address is marked as trusted.
*   `TrustedInteractorRemoved`: When an address is removed from trusted.
*   `ForgeParametersUpdated`: When global forging parameters are changed.
*   `Paused`, `Unpaused`: Contract pause state change.

**Function Summary (20+ Unique Functions):**

1.  `createChronicle()`: Mints a new Chronicle NFT to the caller, initializing its state.
2.  `burnChronicle(uint256 tokenId)`: Allows a Chronicle owner to burn their NFT and associated state.
3.  `getChronicleState(uint256 tokenId) public view`: Retrieves the current dynamic state of a Chronicle (reputation, level).
4.  `getChronicleAttributes(uint256 tokenId) public view`: Placeholder/Example: Returns sample dynamic attributes based on state (e.g., calculated "Power" based on reputation and level).
5.  `tokenURI(uint256 tokenId) public view override`: Generates the metadata URI for a Chronicle, designed to reflect its dynamic state.
6.  `forgeUpgrade(uint256 tokenId) public`: Allows a Chronicle owner to attempt to upgrade their NFT's level by consuming reputation and meeting requirements.
7.  `queryAchievementStatus(uint256 tokenId, uint256 achievementId) public view`: Checks if a specific achievement has been attained by a Chronicle.
8.  `queryReputationLevel(uint256 tokenId) public view`: Gets the current reputation points of a Chronicle.
9.  `queryChronicleLevel(uint256 tokenId) public view`: Gets the current forge level of a Chronicle.
10. `setBaseURI(string memory baseURI) public onlyOwner`: Sets the base URI for metadata generation.
11. `setAchievementDetails(uint256 achievementId, AchievementDetails memory details) public onlyOwner`: Defines or updates the requirements and details of a specific achievement.
12. `getAchievementDetails(uint256 achievementId) public view`: Retrieves the details of a specific achievement.
13. `canForgeUpgrade(uint256 tokenId) public view`: Checks if a Chronicle meets the current requirements to attempt a forge upgrade.
14. `getTotalChroniclesMinted() public view`: Returns the total number of Chronicles minted.
15. `setTrustedInteractor(address interactor, bool isTrusted) public onlyOwner`: Grants or revokes trusted status to an address, allowing them to call certain functions (like `attestInteraction`).
16. `isTrustedInteractor(address interactor) public view`: Checks if an address is marked as a trusted interactor.
17. `attestInteraction(uint256 tokenId, string memory interactionType, uint256 reputationAward) public onlyTrustedOrAttestationDelegate`: Records a specific interaction for a Chronicle, awards reputation, and potentially triggers achievement checks. Callable by owner, trusted interactors, or the specific attestation delegate for that interaction type.
18. `queryInteractionHistory(uint256 tokenId, string memory interactionType) public view`: Gets the count of a specific type of interaction recorded for a Chronicle.
19. `setForgeParameters(ForgeParameters memory params) public onlyOwner`: Updates the global parameters governing forging costs and reputation gain.
20. `getForgeParameters() public view`: Retrieves the current global forging parameters.
21. `delegateAttestationPower(string memory interactionType, address delegate) public onlyOwner`: Delegates the right to call `attestInteraction` for a specific interaction type to another address.
22. `revokeAttestationPower(string memory interactionType) public onlyOwner`: Removes attestation delegation for a specific interaction type.
23. `queryAttestationDelegation(string memory interactionType) public view`: Checks which address is delegated attestation power for a specific interaction type.
24. `pauseForgeActions() public onlyOwner`: Pauses critical state-changing actions like creating, burning, forging, and attesting.
25. `unpauseForgeActions() public onlyOwner`: Unpauses the contract actions.
26. `hasAttainedAchievement(uint256 tokenId, uint256 achievementId) public view`: Alias for `queryAchievementStatus`. (Added for redundancy/clearer naming).
27. `batchSetTrustedInteractors(address[] memory interactors, bool isTrusted) public onlyOwner`: Set trusted status for multiple addresses at once. (Added for utility).
28. `batchDelegateAttestationPower(string[] memory interactionTypes, address[] memory delegates) public onlyOwner`: Delegate attestation power for multiple interaction types at once. (Added for utility, requires arrays to match length).
29. `getChronicleOwner(uint256 tokenId) public view`: Standard ERC721 getter, included as it's essential state query. (While standard, combined with custom state it's part of the overall picture). *Self-correction: Let's stick to the non-standard ones primarily for the count.* We have 26 unique ones listed above this line. We need at least 20 *unique concept* functions.
30. `queryAchievementRequirements(uint256 achievementId) public view`: View function returning *only* the requirements part of `AchievementDetails`.
31. `getChronicleForOwner(address owner) public view returns (uint256[] memory)`: Returns an array of token IDs owned by an address (standard ERC721Enumerable requires this, or manual tracking). Let's add a simple version that just returns *one* if an owner is expected to have only one Chronicle, or requires manual tracking if multiple are allowed. Let's assume one per owner for simplicity in state mapping, but the minting allows multiple. A mapping `_ownerToTokenId` would be needed if one per owner. Let's *not* assume one per owner and skip this complex index unless explicitly needed, focusing on token-centric functions.
32. Let's add some more complex views based on state: `getReputationNeededForNextLevel(uint256 tokenId) public view`.
33. `getAchievementsAttainedCount(uint256 tokenId) public view`.
34. `getPossibleAchievements() public view returns (uint256[] memory)`. (Requires tracking all achievement IDs).

Okay, 30+ functions covering creation, destruction, dynamic state query, static config query, state mutation via user action (forging), state mutation via trusted attestation, permissioning (trusted, delegation), and pausing. This list exceeds 20 unique, concept-driven functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Chronicle Forge Smart Contract ---
// Purpose: Manages a collection of dynamic ERC-721 "Chronicle" NFTs.
// These NFTs track user progress, reputation, and achievements within a specific ecosystem.
// Their state and potential metadata evolve based on attested interactions and forging actions.
//
// Core Concepts:
// - Chronicle: An ERC-721 token representing a user's historical journey, state, and reputation.
// - Reputation: A non-transferable score tied to a specific Chronicle, earned through interactions.
// - Achievements: Specific milestones that can be attained by a Chronicle.
// - Forging: The process of consuming Reputation/Achievements to permanently level up the NFT.
// - Attestation: A mechanism for trusted entities to securely record events/interactions impacting a Chronicle.
// - Dynamic Metadata: tokenURI reflects the current dynamic state of the NFT.
//
// Function Summary (20+ Unique Functions):
// 1. createChronicle(): Mints a new Chronicle NFT to the caller.
// 2. burnChronicle(uint256 tokenId): Allows a Chronicle owner to burn their NFT.
// 3. getChronicleState(uint256 tokenId): Retrieves dynamic state (reputation, level).
// 4. getChronicleAttributes(uint256 tokenId): Returns sample dynamic attributes based on state.
// 5. tokenURI(uint256 tokenId): Generates dynamic metadata URI based on state.
// 6. forgeUpgrade(uint256 tokenId): Allows owner to upgrade Chronicle level by consuming state.
// 7. queryAchievementStatus(uint256 tokenId, uint256 achievementId): Checks if an achievement is attained.
// 8. queryReputationLevel(uint256 tokenId): Gets current reputation.
// 9. queryChronicleLevel(uint256 tokenId): Gets current forge level.
// 10. setBaseURI(string memory baseURI): Sets the base URI for metadata.
// 11. setAchievementDetails(uint256 achievementId, AchievementDetails memory details): Defines an achievement.
// 12. getAchievementDetails(uint256 achievementId): Retrieves achievement details.
// 13. canForgeUpgrade(uint256 tokenId): Checks if upgrade requirements are met.
// 14. getTotalChroniclesMinted(): Returns total minted Chronicles.
// 15. setTrustedInteractor(address interactor, bool isTrusted): Grants/revokes trusted status.
// 16. isTrustedInteractor(address interactor): Checks trusted status.
// 17. attestInteraction(uint256 tokenId, string memory interactionType, uint256 reputationAward): Records interaction, awards reputation, checks achievements.
// 18. queryInteractionHistory(uint256 tokenId, string memory interactionType): Gets count of a specific interaction type for a token.
// 19. setForgeParameters(ForgeParameters memory params): Updates global forging parameters.
// 20. getForgeParameters(): Retrieves global forging parameters.
// 21. delegateAttestationPower(string memory interactionType, address delegate): Delegates attestation rights for an interaction type.
// 22. revokeAttestationPower(string memory interactionType): Revokes attestation delegation.
// 23. queryAttestationDelegation(string memory interactionType): Checks attestation delegate for an interaction type.
// 24. pauseForgeActions(): Pauses key contract functions.
// 25. unpauseForgeActions(): Unpauses key contract functions.
// 26. hasAttainedAchievement(uint256 tokenId, uint256 achievementId): Alias for queryAchievementStatus.
// 27. batchSetTrustedInteractors(address[] memory interactors, bool isTrusted): Sets trusted status for multiple addresses.
// 28. batchDelegateAttestationPower(string[] memory interactionTypes, address[] memory delegates): Delegates attestation power for multiple interaction types.
// 29. getReputationNeededForNextLevel(uint256 tokenId): Calculates reputation needed for the next forge level.
// 30. getAchievementsAttainedCount(uint256 tokenId): Counts total achievements attained by a token.
// 31. getPossibleAchievements(): Returns all defined achievement IDs.

contract ChronicleForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Tracks the next token ID to be minted
    Counters.Counter private _nextTokenId;

    // Stores the dynamic state of each Chronicle NFT
    struct ChronicleState {
        uint256 reputation;
        uint256 level;
        // Add other dynamic attributes here as needed, e.g., uint256 strength, uint256 insight;
    }
    mapping(uint256 => ChronicleState) private chronicleStates;

    // Tracks achievements attained by each Chronicle NFT
    // mapping: tokenId => mapping: achievementId => attained (bool)
    mapping(uint256 => mapping(uint256 => bool)) private attainedAchievements;
    // Simple list to track existing achievement IDs (for getPossibleAchievements)
    uint256[] private _achievementIds;
    mapping(uint256 => bool) private _achievementIdExists;


    // Defines the details and requirements for each achievement
    struct AchievementDetails {
        string name;
        uint256 requiredReputation;
        // Required counts for specific interaction types to unlock this achievement
        mapping(string => uint256) requiredInteractionCounts;
        // Add other requirements here
    }
    mapping(uint256 => AchievementDetails) private achievementDetails;

    // Addresses marked as trusted interactors (e.g., game servers, other authorized contracts)
    mapping(address => bool) private trustedInteractors;

    // Addresses delegated specific attestation power for an interaction type
    mapping(string => address) private attestationDelegations;

    // Counts how many times a specific interaction type has been attested for a Chronicle
    // mapping: tokenId => mapping: interactionType => count
    mapping(uint256 => mapping(string => uint256)) private interactionCounts;

    // Global parameters for the forging and reputation system
    struct ForgeParameters {
        uint256 baseReputationPerLevel; // How much reputation roughly equates to a level
        uint256 reputationExponent; // Exponent for scaling reputation requirement (e.g., 2 for quadratic)
        uint256 forgeReputationCostMultiplier; // How much reputation is consumed during forging
        // Add other global parameters
    }
    ForgeParameters public forgeParameters;

    // Base URI for generating dynamic token metadata
    string private _baseTokenURI;

    // --- Events ---

    event ChronicleMinted(address indexed owner, uint256 indexed tokenId);
    event ChronicleBurned(address indexed owner, uint256 indexed tokenId);
    event ReputationGained(uint256 indexed tokenId, uint256 amount, uint256 newReputation);
    event AchievementAttained(uint256 indexed tokenId, uint256 indexed achievementId);
    event ChronicleUpgraded(uint256 indexed tokenId, uint256 newLevel, uint256 reputationSpent);
    event InteractionAttested(uint256 indexed tokenId, string interactionType, uint256 reputationAwarded, address indexed attester);
    event AttestationDelegated(string interactionType, address indexed delegate);
    event AttestationRevoked(string interactionType);
    event TrustedInteractorSet(address indexed interactor, bool indexed isTrusted);
    event ForgeParametersUpdated(ForgeParameters newParameters);

    // --- Modifiers ---

    modifier onlyTrustedOrAttestationDelegate(uint256 tokenId, string memory interactionType) {
        address attester = _msgSender();
        require(
            trustedInteractors[attester] || attestationDelegations[interactionType] == attester || owner() == attester,
            "ChronicleForge: Not authorized to attest"
        );
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(_msgSender())
        Pausable()
    {
        _baseTokenURI = baseURI;
        // Set some initial default parameters
        forgeParameters = ForgeParameters({
            baseReputationPerLevel: 100,
            reputationExponent: 2, // Quadratic scaling: cost = base * level^exponent
            forgeReputationCostMultiplier: 10 // Forging consumes 10x (level^2) reputation
        });
    }

    // --- ERC721 Overrides ---

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // This is where you'd typically construct a dynamic URI pointing to a service
        // that generates metadata based on the token's state.
        // For this example, we return a simplified URI indicating state.
        // In a real application, this would query off-chain data or generate JSON on the fly.

        ChronicleState storage state = chronicleStates[tokenId];
        string memory stateString = string(abi.encodePacked(
            "reputation=", state.reputation.toString(),
            "&level=", state.level.toString()
            // Add other dynamic attributes here
        ));

        // Example: "https://your-metadata-server.com/chronicle/1?reputation=150&level=1"
        if (bytes(_baseTokenURI).length > 0) {
             return string(abi.encodePacked(
                _baseTokenURI,
                tokenId.toString(),
                "?",
                stateString
            ));
        } else {
            // Fallback or indicate dynamic nature without base URI
            return string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(abi.encodePacked(
                    '{"name": "Chronicle #', tokenId.toString(), '",',
                    '"description": "A dynamic chronicle representing user journey.",',
                    '"attributes": [',
                       '{"trait_type": "Level", "value": ', state.level.toString(), '},',
                       '{"trait_type": "Reputation", "value": ', state.reputation.toString(), '}',
                       // Add other attributes dynamically
                    ']}'
                )))
            ));
        }
    }

    // --- Core Chronicle Functions ---

    /// @notice Mints a new Chronicle NFT to the caller.
    function createChronicle() public whenNotPaused returns (uint256) {
        _nextTokenId.increment();
        uint256 newItemId = _nextTokenId.current();
        _safeMint(_msgSender(), newItemId);

        // Initialize state for the new chronicle
        chronicleStates[newItemId] = ChronicleState({
            reputation: 0,
            level: 0
            // Initialize other attributes
        });

        emit ChronicleMinted(_msgSender(), newItemId);
        return newItemId;
    }

    /// @notice Allows a Chronicle owner to burn their NFT and associated state.
    /// @param tokenId The ID of the Chronicle to burn.
    function burnChronicle(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ChronicleForge: Caller is not owner nor approved");

        // Before burning, clean up state mappings (optional but good practice for storage)
        delete chronicleStates[tokenId];
        // Note: Deleting mappings of mappings is complex. A simple flag or iterating known achievement IDs might be needed
        // depending on how many achievements/interaction types you expect.
        // For this example, we'll leave nested mapping deletion as a consideration.
        // delete attainedAchievements[tokenId]; // Would only delete the outer mapping
        // delete interactionCounts[tokenId]; // Would only delete the outer mapping

        _burn(tokenId);

        emit ChronicleBurned(_msgSender(), tokenId);
    }

    /// @notice Retrieves the current dynamic state of a Chronicle.
    /// @param tokenId The ID of the Chronicle.
    /// @return reputation The current reputation points.
    /// @return level The current forge level.
    function getChronicleState(uint256 tokenId) public view returns (uint256 reputation, uint256 level) {
        require(_exists(tokenId), "ChronicleForge: Token does not exist");
        ChronicleState storage state = chronicleStates[tokenId];
        return (state.reputation, state.level);
    }

    /// @notice Returns sample dynamic attributes based on a Chronicle's state.
    /// This function demonstrates how attributes could be derived from state.
    /// @param tokenId The ID of the Chronicle.
    /// @return power An example derived attribute based on reputation and level.
    function getChronicleAttributes(uint256 tokenId) public view returns (uint256 power) {
        require(_exists(tokenId), "ChronicleForge: Token does not exist");
        ChronicleState storage state = chronicleStates[tokenId];
        // Example calculation: Power = (Reputation / 100) + (Level * 50)
        power = (state.reputation / 100) + (state.level * 50);
        // Add more calculations for other derived attributes
    }

    /// @notice Allows a Chronicle owner to attempt to upgrade their NFT's level.
    /// Requires sufficient reputation and other potential criteria.
    /// @param tokenId The ID of the Chronicle to upgrade.
    function forgeUpgrade(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ChronicleForge: Caller is not owner nor approved");
        require(_exists(tokenId), "ChronicleForge: Token does not exist");

        ChronicleState storage state = chronicleStates[tokenId];
        uint256 currentLevel = state.level;
        uint256 nextLevel = currentLevel + 1;

        uint256 reputationCost = _calculateForgeReputationCost(currentLevel);

        require(state.reputation >= reputationCost, "ChronicleForge: Insufficient reputation for forge");
        // Add other requirements here (e.g., specific achievements required)
        // require(queryAchievementStatus(tokenId, requiredAchievementId), "ChronicleForge: Required achievement not attained");


        // Consume resources/reputation
        state.reputation -= reputationCost;

        // Upgrade the level
        state.level = nextLevel;

        // Potentially update other derived attributes stored in state or trigger other effects
        // state.strength += 10; // Example

        emit ChronicleUpgraded(tokenId, nextLevel, reputationCost);
        // Consider adding an event if attributes change significantly beyond level/reputation
        // emit ChronicleAttributesChanged(tokenId, state.level, state.reputation, ...);
    }

    /// @notice Calculates the reputation cost for the next forge level based on parameters.
    /// @param currentLevel The current level of the Chronicle.
    /// @return The reputation cost for the next level.
    function _calculateForgeReputationCost(uint256 currentLevel) internal view returns (uint256) {
        // Cost scales with level, using exponent
        uint256 base = forgeParameters.baseReputationPerLevel;
        uint256 exponent = forgeParameters.reputationExponent;
        uint256 multiplier = forgeParameters.forgeReputationCostMultiplier;

        // Simple power calculation: cost = base * (currentLevel + 1)^exponent * multiplier
        // Be cautious with large numbers and potential overflow if levels or exponents are very high.
        // For small exponents like 2, simple multiplication is fine.
        uint256 levelTerm = (currentLevel + 1);
        uint256 cost = base;
        for(uint i = 0; i < exponent; i++) {
            cost = cost * levelTerm;
        }
        cost = cost * multiplier;

        return cost;
    }

    /// @notice Checks if a Chronicle meets the current requirements to attempt a forge upgrade.
    /// @param tokenId The ID of the Chronicle.
    /// @return bool True if upgrade is possible, false otherwise.
    function canForgeUpgrade(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) return false;

        ChronicleState storage state = chronicleStates[tokenId];
        uint256 currentLevel = state.level;
        uint256 reputationCost = _calculateForgeReputationCost(currentLevel);

        if (state.reputation < reputationCost) return false;

        // Add checks for other requirements here (e.g., specific achievements)
        // Example: Check if achievement 123 is required for the next level
        // uint256 requiredAchievementForLevel = currentLevel + 1 == 5 ? 123 : 0; // Example logic
        // if (requiredAchievementForLevel > 0 && !queryAchievementStatus(tokenId, requiredAchievementForLevel)) return false;

        return true;
    }


    // --- Achievement & Reputation Functions ---

    /// @notice Defines or updates the requirements and details of a specific achievement.
    /// Only callable by the contract owner.
    /// @param achievementId A unique ID for the achievement.
    /// @param details The details of the achievement.
    function setAchievementDetails(uint256 achievementId, AchievementDetails memory details) public onlyOwner {
        achievementDetails[achievementId] = details;
        if (!_achievementIdExists[achievementId]) {
            _achievementIds.push(achievementId);
            _achievementIdExists[achievementId] = true;
        }
        // Event? Maybe overkill unless parameters are complex.
    }

    /// @notice Retrieves the details of a specific achievement.
    /// @param achievementId The ID of the achievement.
    /// @return details The details of the achievement.
    function getAchievementDetails(uint256 achievementId) public view returns (AchievementDetails memory) {
        // Note: Returning a struct with mappings can be tricky. We return a memory copy.
        // Required interaction counts map cannot be returned directly from storage.
        // A separate view function might be better for interaction requirements.
        return achievementDetails[achievementId];
    }

    /// @notice Retrieves only the requirements part of a specific achievement.
    /// @param achievementId The ID of the achievement.
    /// @return requiredReputation The reputation required.
    /// @return requiredInteractionType The interaction type string required.
    /// @return requiredInteractionCount The count of the required interaction type.
    function queryAchievementRequirements(uint256 achievementId) public view returns (uint256 requiredReputation, string memory requiredInteractionType, uint256 requiredInteractionCount) {
         AchievementDetails storage details = achievementDetails[achievementId];
         // Note: This assumes *one* primary interaction type requirement per achievement for simplicity.
         // If multiple interaction types are required, the struct/query needs to be more complex.
         // We'll return the first one found in the map (order not guaranteed in mappings).
         // A better design might use an array of structs for requirements.
         string memory firstInteractionType = "";
         uint256 firstInteractionCount = 0;
         // This loop is inefficient for many interaction types. Redesign AchievementDetails if needed.
         assembly {
             let mapPtr := sload(details.requiredInteractionCounts.slot) // Get the slot of the mapping
             let head := 0 // Start searching from the beginning of the mapping structure
             // We cannot iterate mappings in Solidity directly. This requires a better struct design
             // like mapping(uint256 => string[]) achievementRequiredInteractionTypes;
             // and mapping(uint256 => uint256[]) achievementRequiredInteractionCounts;
         }
         // Placeholder return for now, assuming a single interaction type requirement is checked internally.
         return (details.requiredReputation, "", 0);
    }


    /// @notice Checks if a specific achievement has been attained by a Chronicle.
    /// @param tokenId The ID of the Chronicle.
    /// @param achievementId The ID of the achievement.
    /// @return bool True if the achievement is attained, false otherwise.
    function queryAchievementStatus(uint256 tokenId, uint256 achievementId) public view returns (bool) {
        require(_exists(tokenId), "ChronicleForge: Token does not exist");
        return attainedAchievements[tokenId][achievementId];
    }

    /// @notice Alias for `queryAchievementStatus` for clearer naming.
    function hasAttainedAchievement(uint256 tokenId, uint256 achievementId) public view returns (bool) {
        return queryAchievementStatus(tokenId, achievementId);
    }

    /// @notice Gets the current reputation points of a Chronicle.
    /// @param tokenId The ID of the Chronicle.
    /// @return The reputation points.
    function queryReputationLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronicleForge: Token does not exist");
        return chronicleStates[tokenId].reputation;
    }

    /// @notice Gets the current forge level of a Chronicle.
    /// @param tokenId The ID of the Chronicle.
    /// @return The forge level.
    function queryChronicleLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronicleForge: Token does not exist");
        return chronicleStates[tokenId].level;
    }

    /// @notice Calculates the reputation needed for a Chronicle to reach the next forge level.
    /// Returns 0 if the token doesn't exist or is already at a theoretical max level (though levels are unbounded here).
    /// @param tokenId The ID of the Chronicle.
    /// @return The reputation points needed.
    function getReputationNeededForNextLevel(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) return 0;
        ChronicleState storage state = chronicleStates[tokenId];
        uint256 costForNextLevel = _calculateForgeReputationCost(state.level);
        if (state.reputation >= costForNextLevel) return 0; // Already has enough
        return costForNextLevel - state.reputation;
    }

    /// @notice Counts the number of achievements attained by a Chronicle.
    /// Note: This requires iterating over known achievement IDs, which can be gas-intensive if there are many.
    /// A separate counter in ChronicleState would be more efficient.
    /// @param tokenId The ID of the Chronicle.
    /// @return The count of attained achievements.
    function getAchievementsAttainedCount(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronicleForge: Token does not exist");
        uint256 count = 0;
        for(uint i = 0; i < _achievementIds.length; i++) {
            if (attainedAchievements[tokenId][_achievementIds[i]]) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns a list of all achievement IDs that have been defined.
    /// Note: Iterating over this list off-chain can query details for each achievement.
    /// @return An array of achievement IDs.
    function getPossibleAchievements() public view returns (uint256[] memory) {
        return _achievementIds;
    }


    // --- Attestation & Interaction Tracking Functions ---

    /// @notice Records a specific interaction for a Chronicle, awards reputation, and checks for achievements.
    /// Only callable by the contract owner, a trusted interactor, or the specific attestation delegate for that interaction type.
    /// @param tokenId The ID of the Chronicle.
    /// @param interactionType A string identifier for the type of interaction (e.g., "quest_completed", "enemy_slain").
    /// @param reputationAward The amount of reputation to award for this interaction.
    function attestInteraction(uint256 tokenId, string memory interactionType, uint256 reputationAward)
        public
        whenNotPaused
        onlyTrustedOrAttestationDelegate(tokenId, interactionType) // Note: tokenId check inside modifier is difficult, ensure _exists(tokenId) is done first or inside. Let's keep _exists check explicit.
    {
        require(_exists(tokenId), "ChronicleForge: Token does not exist");
        address attester = _msgSender(); // Get attester before any state changes

        // Award Reputation
        _awardReputation(tokenId, reputationAward);

        // Track Interaction Count
        interactionCounts[tokenId][interactionType]++;

        // Check and Award Achievements based on new state
        _checkAndAwardAchievements(tokenId);

        emit InteractionAttested(tokenId, interactionType, reputationAward, attester);
    }

    /// @notice Internal helper to award reputation to a Chronicle.
    /// @param tokenId The ID of the Chronicle.
    /// @param amount The amount of reputation to add.
    function _awardReputation(uint256 tokenId, uint256 amount) internal {
        ChronicleState storage state = chronicleStates[tokenId];
        state.reputation += amount; // Handle potential overflow in higher solidity versions if needed

        emit ReputationGained(tokenId, amount, state.reputation);
    }

    /// @notice Internal helper to check if any achievements are met and award them.
    /// Iterates through defined achievements and checks criteria against the current state.
    /// Note: This can be gas-intensive if many achievements or complex requirements exist.
    /// @param tokenId The ID of the Chronicle.
    function _checkAndAwardAchievements(uint256 tokenId) internal {
        ChronicleState storage state = chronicleStates[tokenId];

        for(uint i = 0; i < _achievementIds.length; i++) {
            uint256 achievementId = _achievementIds[i];
            // Skip if already attained
            if (attainedAchievements[tokenId][achievementId]) {
                continue;
            }

            AchievementDetails storage details = achievementDetails[achievementId];

            // Check Reputation Requirement
            if (state.reputation < details.requiredReputation) {
                continue;
            }

            // Check Interaction Count Requirements (iterating mapping is not possible directly, need a defined list of required interactions)
            // Assuming AchievementDetails was designed to have a list of required interaction types and counts:
            // For this example, let's re-query the details to access the map (inefficient but works for example)
            bool requirementsMet = true;
             // This loop is inefficient for many interaction types per achievement.
             // A better design for AchievementDetails is needed for many requirements.
             // For demonstration, we'll just check if reputation is met.
             // To check interaction counts reliably, the AchievementDetails struct would need to store
             // the required interaction types in an array, e.g., string[] requiredInteractionKeys.
            // For now, we'll only check the reputation requirement for simplicity of the example code.
            // If you uncomment the interaction count check, you need a mechanism to iterate requiredInteractionCounts keys.

            /*
            // Example of how you *would* check if you had a list of keys:
            for(uint j = 0; j < details.requiredInteractionKeys.length; j++) {
                 string memory interactionKey = details.requiredInteractionKeys[j];
                 uint256 requiredCount = details.requiredInteractionCounts[interactionKey]; // Requires mapping key exist
                 if (interactionCounts[tokenId][interactionKey] < requiredCount) {
                     requirementsMet = false;
                     break;
                 }
            }
            */

            // If all requirements are met (currently just reputation)
            if (requirementsMet) {
                attainedAchievements[tokenId][achievementId] = true;
                emit AchievementAttained(tokenId, achievementId);
                // Add any rewards for attaining achievement here (e.g., grant small reputation boost, unlock ability)
                // _awardReputation(tokenId, details.rewardReputation); // Example if reward was in struct
            }
        }
    }


    /// @notice Gets the count of a specific type of interaction recorded for a Chronicle.
    /// @param tokenId The ID of the Chronicle.
    /// @param interactionType The type of interaction.
    /// @return The count of that interaction type for the token.
    function queryInteractionHistory(uint256 tokenId, string memory interactionType) public view returns (uint256) {
        require(_exists(tokenId), "ChronicleForge: Token does not exist");
        return interactionCounts[tokenId][interactionType];
    }


    // --- Permission & Control Functions ---

    /// @notice Grants or revokes trusted status to an address.
    /// Trusted interactors can call `attestInteraction` for any interaction type.
    /// Only callable by the contract owner.
    /// @param interactor The address to set trusted status for.
    /// @param isTrusted True to grant, false to revoke.
    function setTrustedInteractor(address interactor, bool isTrusted) public onlyOwner {
        trustedInteractors[interactor] = isTrusted;
        emit TrustedInteractorSet(interactor, isTrusted);
    }

    /// @notice Grants or revokes trusted status for multiple addresses at once.
    /// @param interactors An array of addresses.
    /// @param isTrusted True to grant, false to revoke.
    function batchSetTrustedInteractors(address[] memory interactors, bool isTrusted) public onlyOwner {
        for(uint i = 0; i < interactors.length; i++) {
            trustedInteractors[interactors[i]] = isTrusted;
            emit TrustedInteractorSet(interactors[i], isTrusted);
        }
    }


    /// @notice Checks if an address is marked as a trusted interactor.
    /// @param interactor The address to check.
    /// @return bool True if the address is trusted, false otherwise.
    function isTrustedInteractor(address interactor) public view returns (bool) {
        return trustedInteractors[interactor];
    }

    /// @notice Delegates the right to call `attestInteraction` for a specific interaction type to another address.
    /// This allows different entities to be responsible for attesting different types of events.
    /// Only callable by the contract owner.
    /// @param interactionType The type of interaction (e.g., "guild_quest").
    /// @param delegate The address to delegate attestation power to for this type.
    function delegateAttestationPower(string memory interactionType, address delegate) public onlyOwner {
        attestationDelegations[interactionType] = delegate;
        emit AttestationDelegated(interactionType, delegate);
    }

    /// @notice Revokes attestation delegation for a specific interaction type.
    /// Only callable by the contract owner.
    /// @param interactionType The type of interaction.
    function revokeAttestationPower(string memory interactionType) public onlyOwner {
        delete attestationDelegations[interactionType];
        emit AttestationRevoked(interactionType);
    }

    /// @notice Delegates attestation power for multiple interaction types at once.
    /// Requires interactionTypes and delegates arrays to have the same length.
    /// @param interactionTypes An array of interaction type strings.
    /// @param delegates An array of addresses to delegate power to.
    function batchDelegateAttestationPower(string[] memory interactionTypes, address[] memory delegates) public onlyOwner {
        require(interactionTypes.length == delegates.length, "ChronicleForge: Array length mismatch");
         for(uint i = 0; i < interactionTypes.length; i++) {
            attestationDelegations[interactionTypes[i]] = delegates[i];
            emit AttestationDelegated(interactionTypes[i], delegates[i]);
        }
    }


    /// @notice Checks which address is delegated attestation power for a specific interaction type.
    /// Returns address(0) if no delegation exists.
    /// @param interactionType The type of interaction.
    /// @return The delegated address.
    function queryAttestationDelegation(string memory interactionType) public view returns (address) {
        return attestationDelegations[interactionType];
    }

    /// @notice Pauses critical state-changing actions (create, burn, forge, attest).
    /// Only callable by the contract owner.
    function pauseForgeActions() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract actions.
    /// Only callable by the contract owner.
    function unpauseForgeActions() public onlyOwner {
        _unpause();
    }

    // --- Configuration Functions ---

    /// @notice Updates the global parameters governing forging costs and reputation gain.
    /// Only callable by the contract owner.
    /// @param params The new ForgeParameters struct.
    function setForgeParameters(ForgeParameters memory params) public onlyOwner {
        forgeParameters = params;
        emit ForgeParametersUpdated(params);
    }

    /// @notice Retrieves the current global forging parameters.
    /// @return The current ForgeParameters struct.
    function getForgeParameters() public view returns (ForgeParameters memory) {
        return forgeParameters;
    }

    // --- Helper Functions ---

     /// @notice Returns the total number of Chronicles minted.
    function getTotalChroniclesMinted() public view returns (uint256) {
        return _nextTokenId.current();
    }

    // --- Base URI Function (Standard ERC721, but included in summary) ---

    /// @notice Sets the base URI for generating dynamic token metadata.
    /// Only callable by the contract owner.
    /// @param baseURI The new base URI string.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // The following functions are standard ERC721 functions required for compliance.
    // They are inherited but not counted in the "20 unique functions" as they are generic.
    // function balanceOf(address owner) public view virtual override returns (uint256)
    // function ownerOf(uint256 tokenId) public view virtual override returns (address)
    // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override
    // function transferFrom(address from, address to, uint256 tokenId) public virtual override
    // function approve(address to, uint256 tokenId) public virtual override
    // function getApproved(uint256 tokenId) public view virtual override returns (address)
    // function setApprovalForAll(address operator, bool approved) public virtual override
    // function isApprovedForAll(address owner, address operator) public view virtual override returns (bool)
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)

    // Internal helper needed by ERC721 when not overriding _increaseBalance (which is not available in 0.8.20 base)
     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

     // Internal helper needed by ERC721
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

     // Internal helper needed by ERC721
    function _containerChainId() internal view override(ERC721) returns (uint256) {
        return super._containerChainId();
    }
}

// Helper contract for Base64 encoding (from OpenZeppelin contracts/utils/Base64.sol)
// Included here for self-containment of the example, but typically imported.
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // allocate the resulting bytes array using the known length
        uint256 len = data.length;
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory encoded = new bytes(encodedLen);
        uint256 ptr = 0;
        bytes1 table0 = table[0];

        assembly {
            let tablePtr := add(table, 1)

            for { let i := 0 } lt(i, len) { } {
                // load 3 bytes at a time into the bitstream
                let bitstream := shl(160, mload(add(data, i)))

                // isolate the bits for the first byte
                encoded.store(ptr, byte(and(shr(18, bitstream), 0x3F), tablePtr))
                inc(ptr)

                // isolate the bits for the second byte
                encoded.store(ptr, byte(and(shr(12, bitstream), 0x3F), tablePtr))
                inc(ptr)

                // isolate the bits for the third byte
                encoded.store(ptr, byte(and(shr(6, bitstream), 0x3F), tablePtr))
                inc(ptr)

                // isolate the bits for the fourth byte
                encoded.store(ptr, byte(and(bitstream, 0x3F), tablePtr))
                inc(ptr)

                // increase the counter
                i := add(i, 3)
            }

            // padding with '='
            switch mod(len, 3)
            case 1 {
                mstore(add(encoded, sub(encodedLen, 1)), 0x3d)
                mstore(add(encoded, sub(encodedLen, 2)), 0x3d)
            }
            case 2 {
                mstore(add(encoded, sub(encodedLen, 1)), 0x3d)
            }
        }

        return string(encoded);
    }
}

```