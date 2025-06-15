Okay, here is a Solidity smart contract concept focusing on a "Multi-Dimensional NFT" (MD-NFT). This concept combines dynamic attributes, time-based evolution (resonance), different "Essence" components that affect the NFT, a global "Era" state that influences all NFTs, and even potential "Entanglement" between specific NFTs.

It avoids simple ERC721/ERC1155 copies, staking, or basic generative art (though it *enables* dynamic art via metadata based on state).

**Outline & Function Summary: Chronicles of Aethelgard**

This contract represents a collection of unique, dynamic NFTs called "Artifacts". Each Artifact exists within the "Chronicles of Aethelgard" and is influenced by various factors: its innate Essences, accrued Resonance, and the current global Era.

**Core Concepts:**

1.  **Artifacts (NFTs):** ERC721 tokens representing unique items in the chronicles.
2.  **Essences:** Non-transferable (or perhaps ERC1155 fungible) components that can be attuned to Artifacts, granting attributes and affecting behavior. Stored as counts per user per type.
3.  **Resonance:** A numerical value specific to each Artifact that increases over time, modified by Essences and the current Era. High Resonance can unlock visual changes or future abilities.
4.  **Eras:** Global states of the contract that cycle, affecting resonance accrual rates and potentially other mechanics. Controlled by the contract owner.
5.  **Entanglement:** A unique link that can be forged between two specific Artifacts, enabling special interactions or shared effects.

---

**Function Summary:**

**I. ERC721 Standard Functions (Inherited from ERC721 & ERC721Enumerable):**
*   `balanceOf(address owner)`: Get number of tokens owned by an address.
*   `ownerOf(uint256 tokenId)`: Get owner of a specific token.
*   `approve(address to, uint256 tokenId)`: Approve an address to manage a token.
*   `getApproved(uint256 tokenId)`: Get the approved address for a token.
*   `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all tokens.
*   `isApprovedForAll(address owner, address operator)`: Check if an operator is approved.
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfer token.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer token.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer token with data.
*   `totalSupply()`: Get total supply of tokens.
*   `tokenByIndex(uint256 index)`: Get token ID by index (Enumerable).
*   `tokenOfOwnerByIndex(address owner, uint256 index)`: Get token ID of owner by index (Enumerable).
*   `tokenURI(uint256 tokenId)`: *Overridden*. Generates dynamic metadata URI based on Artifact state.

**II. Artifact Management & State (Custom):**
1.  `mintArtifact(address to, uint256 initialEraIndex)`: Creates a new Artifact token for `to`, setting its initial state and era. Requires special permission.
2.  `getArtifactState(uint256 tokenId)`: Returns the detailed state of an Artifact (Essences, Resonance, creation time, era).
3.  `applyResonance(uint256 tokenId)`: Calculates accrued Resonance since last update and applies it to the Artifact's state.
4.  `getAccruableResonance(uint256 tokenId)`: Calculates how much Resonance an Artifact has accrued since the last update without applying it.
5.  `getArtifactVisualAttributes(uint256 tokenId)`: Computes abstract attributes that influence the visual representation (used by `tokenURI`).

**III. Essence System:**
6.  `forgeEssence(address to, EssenceType essenceType, uint256 amount)`: Creates new Essences of a specific type for a user. Requires special permission.
7.  `attuneEssenceToArtifact(uint256 tokenId, EssenceType essenceType, uint256 count)`: Attaches a user's owned Essences to their Artifact. Consumes user's Essence count.
8.  `removeEssenceFromArtifact(uint256 tokenId, EssenceType essenceType, uint256 count)`: Detaches Essences from an Artifact, returning them to the user's inventory.
9.  `mergeEssences(EssenceType essenceType, uint256 amount)`: Combines user-owned Essences of the same type (e.g., burns 3 basic, gets 1 enhanced).
10. `getUserEssences(address user)`: Returns the counts of each Essence type owned by a user.
11. `getEssenceDetails(EssenceType essenceType)`: Returns static parameters for a specific Essence type.
12. `canAttuneEssence(uint256 tokenId, EssenceType essenceType, uint256 count)`: Checks if attuning is possible (user owns enough, artifact slots available, etc.).

**IV. Era System:**
13. `getCurrentEra()`: Returns the index and details of the current global Era.
14. `catalyzeEraShift(uint256 nextEraIndex)`: Owner-only function to transition to a new global Era.
15. `getEraParameters(uint256 eraIndex)`: Returns the configuration parameters for a specific Era.

**V. Entanglement System:**
16. `requestEntanglement(uint256 tokenId, uint256 targetTokenId)`: Initiates an entanglement request between two Artifacts.
17. `acceptEntanglement(uint256 tokenId)`: Accepts an incoming entanglement request for `tokenId`.
18. `breakEntanglement(uint256 tokenId)`: Breaks the entanglement involving `tokenId`.
19. `getEntangledArtifact(uint256 tokenId)`: Returns the token ID of the Artifact entangled with `tokenId`, or 0 if none.
20. `getEntanglementStatus(uint256 tokenIdA, uint256 tokenIdB)`: Checks if two specific Artifacts are currently entangled with each other.
21. `isArtifactEntangled(uint256 tokenId)`: Checks if an Artifact is currently entangled with *any* other Artifact.

**VI. Admin / Configuration (Owner-Only):**
22. `setEraParameters(uint256 eraIndex, EraParameters memory params)`: Sets the parameters for a specific Era.
23. `setEssenceParameters(EssenceType essenceType, EssenceParameters memory params)`: Sets the parameters for a specific Essence type (e.g., resonance boost, visual weight).
24. `setMintingPermissions(address minter, bool allowed)`: Grants or revokes permission to call `mintArtifact` and `forgeEssence`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// --- Outline & Function Summary ---
// (See above block)
// --- End Outline & Function Summary ---


contract ChroniclesOfAethelgard is ERC721Enumerable, Ownable, IERC721Receiver {

    // --- Constants & State Variables ---

    uint256 private constant BASE_RESONANCE_RATE = 1e14; // Base rate per second (adjust scaling)
    uint256 private constant MAX_ESSENCES_PER_ARTIFACT = 5; // Max unique essence types per artifact
    uint256 private constant MAX_ESSENCE_COUNT_PER_TYPE = 100; // Max count of one essence type per artifact

    enum Era { Dawn, Flux, Zenith, Dusk }

    enum EssenceType { ElementalFire, ElementalWater, ElementalEarth, ElementalAir, TemporalShift, TemporalStasis, CognitiveInsight, CognitiveHarmony, StructuralIntegrity, StructuralAdaptability }

    struct ArtifactState {
        uint256 creationTimestamp;
        uint256 lastResonanceAppliedTimestamp;
        uint256 resonance; // Scaled, e.g., 1e18 for 1.0
        uint256 creationEraIndex;
        mapping(EssenceType => uint256) attunedEssences; // Count of each essence type attuned
        uint256 attunedEssenceCount; // Total count of unique essence types
    }

    struct EraParameters {
        uint256 resonanceRateMultiplier; // Affects how fast resonance accrues (e.g., 100 for 1x)
        uint256 maxResonance; // Max resonance achievable in this era (scaled)
        bool canAttuneNewEssences; // Can new essences be added in this era?
        // Add more era-specific parameters here...
    }

    struct EssenceParameters {
        string name;
        uint256 resonanceBoostPerUnit; // Resonance boost per attuned essence (scaled)
        uint256 mergeCost; // How many needed to merge to next level (concept - merge not implemented fully here)
        // Add visual weights or other effects here...
    }

    mapping(uint256 => ArtifactState) private _artifactStates;
    mapping(address => mapping(EssenceType => uint256)) private _userEssences; // User inventory of essences (non-NFT)

    mapping(uint256 => uint256) private _entangledWith; // tokenId => entangled tokenId (bidirectional)
    mapping(uint256 => uint256) private _entanglementRequests; // tokenId => requestedTargetTokenId

    uint256[] private _eraCycle; // Sequence of eras (e.g., [0, 1, 2, 3, 0, ...])
    uint256 private _currentEraIndexInCycle;
    uint256 private _eraStartTime;
    mapping(uint256 => EraParameters) private _eraParameters;
    mapping(EssenceType => EssenceParameters) private _essenceParameters;

    mapping(address => bool) private _minterPermissions; // Addresses allowed to mint artifacts/essences

    // --- Events ---

    event ArtifactMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEraIndex);
    event ResonanceApplied(uint256 indexed tokenId, uint256 oldResonance, uint256 newResonance, uint256 accruedAmount);
    event EssenceForged(address indexed owner, EssenceType essenceType, uint256 amount);
    event EssenceAttuned(uint256 indexed tokenId, EssenceType essenceType, uint256 amount, uint256 newCount);
    event EssenceRemoved(uint256 indexed tokenId, EssenceType essenceType, uint256 amount, uint256 newCount);
    event EssencesMerged(address indexed owner, EssenceType essenceType, uint256 inputAmount, uint256 outputAmount);
    event EraShifted(uint256 indexed oldEraIndex, uint256 indexed newEraIndex, uint256 eraStartTime);
    event EntanglementRequested(uint256 indexed tokenIdA, uint256 indexed tokenIdB);
    event EntanglementAccepted(uint256 indexed tokenIdA, uint256 indexed tokenIdB); // Emitted from accepting side
    event EntanglementBroken(uint256 indexed tokenIdA, uint256 indexed tokenIdB); // Emitted from breaking side
    event MintingPermissionSet(address indexed minter, bool allowed);

    // --- Constructor ---

    constructor(address initialOwner)
        ERC721("ChroniclesOfAethelgard", "AETH")
        Ownable(initialOwner)
    {
        // Define the standard era cycle (can be changed by owner if needed)
        _eraCycle = [uint256(Era.Dawn), uint256(Era.Flux), uint256(Era.Zenith), uint256(Era.Dusk)];
        _currentEraIndexInCycle = 0; // Start at Dawn
        _eraStartTime = block.timestamp;

        // Set some default parameters (owner should configure properly post-deployment)
        _eraParameters[uint256(Era.Dawn)] = EraParameters(150, 1e20, true); // 1.5x rate, lower max
        _eraParameters[uint256(Era.Flux)] = EraParameters(100, 5e20, true); // 1.0x rate, medium max
        _eraParameters[uint256(Era.Zenith)] = EraParameters(200, 1e21, false); // 2.0x rate, high max, no new attunement
        _eraParameters[uint256(Era.Dusk)] = EraParameters(50, 2e20, false); // 0.5x rate, medium max, no new attunement

        _essenceParameters[EssenceType.ElementalFire] = EssenceParameters("Fire Essence", 5e16, 3);
        _essenceParameters[EssenceType.TemporalShift] = EssenceParameters("Shift Essence", 2e16, 5);
        // ... initialize other essences

        // Owner has minting permissions by default
        _minterPermissions[initialOwner] = true;
    }

    // --- ERC721 Overrides ---

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Enumerable.ERC721EnumerableNonexistentToken();
        }

        ArtifactState storage artifact = _artifactStates[tokenId];
        (uint256 visualLevel, string memory eraName, string[] memory essenceNames) = getArtifactVisualAttributes(tokenId);

        // Calculate current resonance for metadata display (without applying)
        uint256 currentEra = _eraCycle[_currentEraIndexInCycle];
        EraParameters storage eraParams = _eraParameters[currentEra];
        uint256 timeElapsed = block.timestamp - artifact.lastResonanceAppliedTimestamp;
        uint256 currentAccrued = (BASE_RESONANCE_RATE * timeElapsed * eraParams.resonanceRateMultiplier) / 100;
        uint256 effectiveResonance = artifact.resonance + currentAccrued;
        uint256 displayResonance = effectiveResonance / 1e18; // Scale down for display

        string memory description = string(abi.encodePacked(
            "An Artifact from the Chronicles, currently in the ", eraName, " Era.",
            " Resonance: ", Strings.toString(displayResonance), ".",
            " It is imbued with ", Strings.toString(artifact.attunedEssenceCount), " unique Essences."
        ));

        string memory attributes = "[";
        attributes = string(abi.encodePacked(attributes, '{"trait_type": "Creation Era", "value": "', string(abi.encodePacked("Era ", Strings.toString(artifact.creationEraIndex + 1))), '"},'));
        attributes = string(abi.encodePacked(attributes, '{"trait_type": "Current Era", "value": "', eraName, '"},'));
        attributes = string(abi.encodePacked(attributes, '{"trait_type": "Resonance Level", "value": ', Strings.toString(displayResonance), '},'));
        attributes = string(abi.encodePacked(attributes, '{"trait_type": "Visual Level", "value": ', Strings.toString(visualLevel), '}'));

        for (uint i = 0; i < essenceNames.length; i++) {
             attributes = string(abi.encodePacked(attributes, ',', '{"trait_type": "Essence", "value": "', essenceNames[i], '"}'));
        }
         if (_entangledWith[tokenId] != 0) {
             attributes = string(abi.encodePacked(attributes, ',', '{"trait_type": "Entangled With", "value": "', Strings.toString(_entangledWith[tokenId]), '"}'));
         }

        attributes = string(abi.encodePacked(attributes, "]"));


        string memory json = string(abi.encodePacked(
            '{"name": "Aethelgard Artifact #', Strings.toString(tokenId), '", "description": "', description, '", "image": "ipfs://<dynamic_image_cid_based_on_attributes>/', Strings.toString(visualLevel), '.png", "attributes": ', attributes, '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- II. Artifact Management & State (Custom) ---

    /// @notice Mints a new Artifact token and sets its initial state.
    /// @param to The address to mint the artifact to.
    /// @param initialEraIndex The index of the era the artifact is created in (must match current era index).
    function mintArtifact(address to, uint256 initialEraIndex) public onlyMinter {
        uint256 newTokenId = totalSupply() + 1; // Simple incremental ID

        uint256 currentGlobalEraIndex = _eraCycle[_currentEraIndexInCycle];
        require(initialEraIndex == currentGlobalEraIndex, "Minting must occur in the specified initial era.");

        _safeMint(to, newTokenId);

        _artifactStates[newTokenId].creationTimestamp = block.timestamp;
        _artifactStates[newTokenId].lastResonanceAppliedTimestamp = block.timestamp;
        _artifactStates[newTokenId].resonance = 0;
        _artifactStates[newTokenId].creationEraIndex = currentGlobalEraIndex;
        _artifactStates[newTokenId].attunedEssenceCount = 0; // No essences initially

        emit ArtifactMinted(newTokenId, to, currentGlobalEraIndex);
    }

    /// @notice Gets the detailed state of a specific Artifact.
    /// @param tokenId The ID of the Artifact.
    /// @return artifactState The detailed state struct.
    /// @return attunedEssenceTypes List of essence types attuned.
    /// @return attunedEssenceCounts List of counts for corresponding types.
    function getArtifactState(uint256 tokenId) public view returns (ArtifactState memory artifactState, EssenceType[] memory attunedEssenceTypes, uint256[] memory attunedEssenceCounts) {
         require(_exists(tokenId), "Artifact does not exist.");
         artifactState = _artifactStates[tokenId];

         // Iterate through all possible essence types to build arrays
         EssenceType[] memory allTypes = _getAllEssenceTypes(); // Helper function needed
         uint264 _attunedCount = 0;
         for(uint i = 0; i < allTypes.length; i++) {
             if (artifactState.attunedEssences[allTypes[i]] > 0) {
                 _attunedCount++;
             }
         }

         attunedEssenceTypes = new EssenceType[](_attunedCount);
         attunedEssenceCounts = new uint256[](_attunedCount);
         uint256 currentIndex = 0;
          for(uint i = 0; i < allTypes.length; i++) {
             if (artifactState.attunedEssences[allTypes[i]] > 0) {
                 attunedEssenceTypes[currentIndex] = allTypes[i];
                 attunedEssenceCounts[currentIndex] = artifactState.attunedEssences[allTypes[i]];
                 currentIndex++;
             }
         }
    }

    /// @notice Calculates and applies accrued Resonance to an Artifact.
    /// @param tokenId The ID of the Artifact.
    function applyResonance(uint256 tokenId) public {
        require(_exists(tokenId), "Artifact does not exist.");
        require(msg.sender == ownerOf(tokenId), "Only owner can apply resonance.");

        ArtifactState storage artifact = _artifactStates[tokenId];
        uint256 accrued = getAccruableResonance(tokenId);

        if (accrued > 0) {
            uint256 oldResonance = artifact.resonance;
            artifact.resonance += accrued;

            // Apply essence boosts
            EssenceType[] memory allTypes = _getAllEssenceTypes();
            for(uint i = 0; i < allTypes.length; i++) {
                 uint256 essenceCount = artifact.attunedEssences[allTypes[i]];
                 if (essenceCount > 0) {
                     uint256 boost = _essenceParameters[allTypes[i]].resonanceBoostPerUnit * essenceCount;
                     artifact.resonance += boost;
                 }
            }

            // Apply era max limit *after* boosts
            uint256 currentGlobalEraIndex = _eraCycle[_currentEraEraIndexInCycle];
            artifact.resonance = Math.min(artifact.resonance, _eraParameters[currentGlobalEraIndex].maxResonance);


            artifact.lastResonanceAppliedTimestamp = block.timestamp;

            emit ResonanceApplied(tokenId, oldResonance, artifact.resonance, accrued);
        }
    }

     /// @notice Calculates how much Resonance an Artifact has accrued since the last update. Does not apply.
    /// @param tokenId The ID of the Artifact.
    /// @return accruedAmount The amount of resonance accrued.
    function getAccruableResonance(uint256 tokenId) public view returns (uint256 accruedAmount) {
        require(_exists(tokenId), "Artifact does not exist.");
        ArtifactState storage artifact = _artifactStates[tokenId];

        uint256 timeElapsed = block.timestamp - artifact.lastResonanceAppliedTimestamp;
        if (timeElapsed == 0) {
            return 0;
        }

        uint256 currentGlobalEraIndex = _eraCycle[_currentEraIndexInCycle];
        EraParameters storage eraParams = _eraParameters[currentGlobalEraIndex];

        // Base accrual based on time and era multiplier
        accruedAmount = (BASE_RESONANCE_RATE * timeElapsed * eraParams.resonanceRateMultiplier) / 100; // Scaled rate

        // Note: Essence boosts are applied during `applyResonance`, not just accrual calculation.
        // This function just gives the base accrual amount.

        // Prevent exceeding max resonance of the *current* era with just accrual
        // The max limit is enforced fully in applyResonance *after* boosts
        uint264 currentGlobalEraIndex = _eraCycle[_currentEraIndexInCycle];
        EraParameters storage currentEraParams = _eraParameters[currentGlobalEraIndex];
        accruedAmount = Math.min(accruedAmount, currentEraParams.maxResonance - artifact.resonance);

        return accruedAmount;
    }


    /// @notice Computes abstract attributes influencing visual representation.
    /// @param tokenId The ID of the Artifact.
    /// @return visualLevel A level derived from resonance and essences.
    /// @return eraName The name of the current era.
    /// @return essenceNames The names of attuned essences.
    function getArtifactVisualAttributes(uint256 tokenId) public view returns (uint256 visualLevel, string memory eraName, string[] memory essenceNames) {
         require(_exists(tokenId), "Artifact does not exist.");
         ArtifactState storage artifact = _artifactStates[tokenId];

         // Example logic for visual level: combine resonance and total essence count
         // Scale resonance down for level calculation
         uint256 effectiveResonance = artifact.resonance / 1e17; // Example scaling

         visualLevel = (effectiveResonance + artifact.attunedEssenceCount * 100) / 100; // Example calculation
         // Cap visual level? visualLevel = Math.min(visualLevel, 100);

         // Get current era name
         uint256 currentGlobalEraIndex = _eraCycle[_currentEraIndexInCycle];
         if (currentGlobalEraIndex == uint256(Era.Dawn)) eraName = "Dawn";
         else if (currentGlobalEraIndex == uint256(Era.Flux)) eraName = "Flux";
         else if (currentGlobalEraIndex == uint256(Era.Zenith)) eraName = "Zenith";
         else if (currentGlobalEraIndex == uint256(Era.Dusk)) eraName = "Dusk";
         else eraName = "Unknown"; // Should not happen

         // Get attuned essence names
         EssenceType[] memory allTypes = _getAllEssenceTypes(); // Helper function needed
         uint264 _attunedCount = 0;
         for(uint i = 0; i < allTypes.length; i++) {
             if (artifact.attunedEssences[allTypes[i]] > 0) {
                 _attunedCount++;
             }
         }

         essenceNames = new string[](_attunedCount);
         uint264 currentIndex = 0;
          for(uint i = 0; i < allTypes.length; i++) {
             if (artifact.attunedEssences[allTypes[i]] > 0) {
                 essenceNames[currentIndex] = _essenceParameters[allTypes[i]].name;
                 currentIndex++;
             }
         }
    }


    // --- III. Essence System ---

    /// @notice Creates new Essences for a user. Requires minter permission.
    /// @param to The address to grant the essences to.
    /// @param essenceType The type of essence to forge.
    /// @param amount The number of essences to forge.
    function forgeEssence(address to, EssenceType essenceType, uint256 amount) public onlyMinter {
        require(amount > 0, "Amount must be greater than zero.");
        _userEssences[to][essenceType] += amount;
        emit EssenceForged(to, essenceType, amount);
    }

    /// @notice Attaches user-owned Essences to their Artifact. Consumes user's essence count.
    /// @param tokenId The ID of the Artifact.
    /// @param essenceType The type of essence to attune.
    /// @param count The number of essences to attune (per type).
    function attuneEssenceToArtifact(uint256 tokenId, EssenceType essenceType, uint256 count) public {
        require(msg.sender == ownerOf(tokenId), "Only owner can attune essences.");
        require(count > 0, "Count must be greater than zero.");
        require(canAttuneEssence(tokenId, essenceType, count), "Cannot attune essence due to rules.");

        ArtifactState storage artifact = _artifactStates[tokenId];
        uint264 currentGlobalEraIndex = _eraCycle[_currentEraIndexInCycle];
        require(_eraParameters[currentGlobalEraIndex].canAttuneNewEssences, "Cannot attune essences in current era.");

        if (artifact.attunedEssences[essenceType] == 0) {
            require(artifact.attunedEssenceCount < MAX_ESSENCES_PER_ARTIFACT, "Artifact has max unique essence types.");
            artifact.attunedEssenceCount++;
        }
        require(artifact.attunedEssences[essenceType] + count <= MAX_ESSENCE_COUNT_PER_TYPE, "Exceeds max essence count per type.");


        _userEssences[msg.sender][essenceType] -= count;
        artifact.attunedEssences[essenceType] += count;

        emit EssenceAttuned(tokenId, essenceType, count, artifact.attunedEssences[essenceType]);
    }

    /// @notice Detaches Essences from an Artifact, returning them to the user's inventory.
    /// @param tokenId The ID of the Artifact.
    /// @param essenceType The type of essence to remove.
    /// @param count The number of essences to remove.
    function removeEssenceFromArtifact(uint256 tokenId, EssenceType essenceType, uint256 count) public {
        require(msg.sender == ownerOf(tokenId), "Only owner can remove essences.");
        require(count > 0, "Count must be greater than zero.");

        ArtifactState storage artifact = _artifactStates[tokenId];
        require(artifact.attunedEssences[essenceType] >= count, "Artifact does not have enough essences of this type.");

        artifact.attunedEssences[essenceType] -= count;
        _userEssences[msg.sender][essenceType] += count;

        if (artifact.attunedEssences[essenceType] == 0) {
             artifact.attunedEssenceCount--;
        }

        emit EssenceRemoved(tokenId, essenceType, count, artifact.attunedEssences[essenceType]);
    }

    /// @notice Merges multiple essences of the same type into a potentially 'upgraded' state or reduces count.
    /// (Placeholder logic - actual merge effect needs definition)
    /// @param essenceType The type of essence to merge.
    /// @param amount The number of essences to attempt to merge (must be >= mergeCost).
    function mergeEssences(EssenceType essenceType, uint256 amount) public {
        EssenceParameters storage params = _essenceParameters[essenceType];
        require(params.mergeCost > 0, "This essence type cannot be merged.");
        require(amount >= params.mergeCost, "Not enough essences to perform merge.");
        require(_userEssences[msg.sender][essenceType] >= amount, "User does not own enough essences.");

        // Example: Burn 'amount', get 'amount / mergeCost' back of the *same* type (simplistic)
        // A real implementation might mint a new 'Enhanced' essence type or modify artifact state directly.
        uint264 resultAmount = amount / params.mergeCost;

        _userEssences[msg.sender][essenceType] -= amount;
        _userEssences[msg.sender][essenceType] += resultAmount; // Or mint a new type

        emit EssencesMerged(msg.sender, essenceType, amount, resultAmount);
    }

    /// @notice Returns the counts of each Essence type owned by a user.
    /// @param user The address of the user.
    /// @return essenceTypes List of essence types owned.
    /// @return essenceCounts List of counts for corresponding types.
    function getUserEssences(address user) public view returns (EssenceType[] memory essenceTypes, uint256[] memory essenceCounts) {
        EssenceType[] memory allTypes = _getAllEssenceTypes(); // Helper function needed
        uint264 ownedCount = 0;
        for(uint i = 0; i < allTypes.length; i++) {
            if (_userEssences[user][allTypes[i]] > 0) {
                ownedCount++;
            }
        }

        essenceTypes = new EssenceType[](ownedCount);
        essenceCounts = new uint256[](ownedCount);
        uint264 currentIndex = 0;
        for(uint i = 0; i < allTypes.length; i++) {
            if (_userEssences[user][allTypes[i]] > 0) {
                essenceTypes[currentIndex] = allTypes[i];
                essenceCounts[currentIndex] = _userEssences[user][allTypes[i]];
                currentIndex++;
            }
        }
    }

    /// @notice Returns static parameters for a specific Essence type.
    /// @param essenceType The type of essence.
    /// @return params The EssenceParameters struct.
    function getEssenceDetails(EssenceType essenceType) public view returns (EssenceParameters memory params) {
         // Validate essenceType? Enum values are fixed.
         params = _essenceParameters[essenceType];
    }

     /// @notice Checks if an essence can be attuned to an artifact based on current state and rules.
     /// @param tokenId The ID of the Artifact.
     /// @param essenceType The type of essence.
     /// @param count The number of essences to attune.
     /// @return canAttune True if attuning is possible.
    function canAttuneEssence(uint256 tokenId, EssenceType essenceType, uint256 count) public view returns (bool) {
        if (!_exists(tokenId)) return false;
        if (msg.sender != ownerOf(tokenId)) return false;
        if (count == 0) return false;
        if (_userEssences[msg.sender][essenceType] < count) return false;

        ArtifactState storage artifact = _artifactStates[tokenId];
        uint264 currentGlobalEraIndex = _eraCycle[_currentEraIndexInCycle];
        if (!_eraParameters[currentGlobalEraIndex].canAttuneNewEssences) return false;

        // Check unique essence type limit
        if (artifact.attunedEssences[essenceType] == 0) {
             if (artifact.attunedEssenceCount >= MAX_ESSENCES_PER_ARTIFACT) return false;
        }

        // Check count limit per type
        if (artifact.attunedEssences[essenceType] + count > MAX_ESSENCE_COUNT_PER_TYPE) return false;

        // Add other custom attunement rules here (e.g., level requirements, era specifics)

        return true;
    }


    // --- IV. Era System ---

    /// @notice Returns the current global Era index, start time, and parameters.
    /// @return currentEraIndexInCycle The index in the era cycle.
    /// @return currentEraTypeIndex The enum index of the current era type.
    /// @return startTime The timestamp when the current era began.
    /// @return params Parameters for the current era.
    function getCurrentEra() public view returns (uint256 currentEraIndexInCycle, uint256 currentEraTypeIndex, uint256 startTime, EraParameters memory params) {
        currentEraIndexInCycle = _currentEraIndexInCycle;
        currentEraTypeIndex = _eraCycle[_currentEraIndexInCycle];
        startTime = _eraStartTime;
        params = _eraParameters[currentEraTypeIndex];
    }

    /// @notice Transitions the contract to the next Era in the defined cycle. Owner only.
    /// @param nextEraCycleIndex The index in the _eraCycle array to transition to.
    function catalyzeEraShift(uint256 nextEraCycleIndex) public onlyOwner {
        require(nextEraCycleIndex < _eraCycle.length, "Invalid era cycle index.");

        uint264 oldEraIndex = _eraCycle[_currentEraIndexInCycle];
        _currentEraIndexInCycle = nextEraCycleIndex;
        uint264 newEraIndex = _eraCycle[_currentEraIndexInCycle];
        _eraStartTime = block.timestamp;

        // Potentially add logic here to affect all artifacts during an era shift
        // (e.g., reset temporary effects, apply global boosts/penalties)
        // For simplicity, we'll rely on get/applyResonance to use the new parameters.

        emit EraShifted(oldEraIndex, newEraIndex, _eraStartTime);
    }

    /// @notice Gets the parameters for a specific Era type.
    /// @param eraIndex The enum index of the Era type.
    /// @return params The EraParameters struct.
    function getEraParameters(uint256 eraIndex) public view returns (EraParameters memory params) {
        // Validate eraIndex?
        params = _eraParameters[eraIndex];
    }

    // --- V. Entanglement System ---

    /// @notice Owner of tokenIdA requests entanglement with targetTokenId (owned by someone else).
    /// @param tokenId The ID of the Artifact requesting entanglement.
    /// @param targetTokenId The ID of the Artifact being requested.
    function requestEntanglement(uint256 tokenId, uint256 targetTokenId) public {
        require(_exists(tokenId), "Requesting Artifact does not exist.");
        require(_exists(targetTokenId), "Target Artifact does not exist.");
        require(tokenId != targetTokenId, "Cannot entangle an artifact with itself.");
        require(msg.sender == ownerOf(tokenId), "Only owner of requesting artifact can request.");
        require(_entangledWith[tokenId] == 0, "Requesting artifact is already entangled.");
        require(_entangledWith[targetTokenId] == 0, "Target artifact is already entangled.");
        require(_entanglementRequests[tokenId] == 0, "Requesting artifact already has an active request.");
         // Allow multiple requests *to* targetTokenId? Or only one at a time? Let's allow multiple incoming.

        _entanglementRequests[tokenId] = targetTokenId;
        emit EntanglementRequested(tokenId, targetTokenId);
    }

    /// @notice Owner of tokenIdB accepts an incoming entanglement request from tokenIdA.
    /// @param tokenId The ID of the Artifact accepting the request.
    function acceptEntanglement(uint256 tokenId) public {
        require(_exists(tokenId), "Accepting Artifact does not exist.");
        require(msg.sender == ownerOf(tokenId), "Only owner of accepting artifact can accept.");
        require(_entangledWith[tokenId] == 0, "Accepting artifact is already entangled.");

        // Find the request targeting this artifact
        uint264 requestingTokenId = 0;
        EssenceType[] memory allTypes = _getAllEssenceTypes(); // Need to iterate through potential requesters - inefficient.
        // A better approach might be a mapping `_pendingRequests[targetTokenId] => requestingTokenId[]`
        // For simplicity in example, let's just assume the latest valid request is the one being accepted.
        // A real implementation would need a more robust request tracking system.
        // Let's find the request where this token is the target.
         for (uint256 i = 1; i <= totalSupply(); i++) { // Inefficient iteration for large supply
             if (_entanglementRequests[i] == tokenId) {
                 requestingTokenId = i;
                 break; // Accept the first one found for simplicity
             }
         }


        require(requestingTokenId != 0, "No pending entanglement request found for this artifact.");
        require(_entangledWith[requestingTokenId] == 0, "Requesting artifact became entangled while request was pending."); // Check if requester got entangled with someone else

        // Establish entanglement (bidirectional)
        _entangledWith[tokenId] = requestingTokenId;
        _entangledWith[requestingTokenId] = tokenId;

        // Clear the request
        delete _entanglementRequests[requestingTokenId];

        emit EntanglementAccepted(requestingTokenId, tokenId);

        // Add entanglement effects here (e.g., temporary resonance boost, visual change)
    }

    /// @notice Breaks the entanglement involving this Artifact. Either owner can call.
    /// @param tokenId The ID of the Artifact breaking the entanglement.
    function breakEntanglement(uint256 tokenId) public {
        require(_exists(tokenId), "Artifact does not exist.");
        require(msg.sender == ownerOf(tokenId), "Only owner can break entanglement for their artifact.");
        require(_entangledWith[tokenId] != 0, "Artifact is not entangled.");

        uint264 entangledTokenId = _entangledWith[tokenId];
        require(_exists(entangledTokenId), "Entangled artifact does not exist (state corrupted?).");

        // Break entanglement from both sides
        delete _entangledWith[tokenId];
        delete _entangledWith[entangledTokenId];

        emit EntanglementBroken(tokenId, entangledTokenId);

        // Add logic for breaking effects (e.g., resonance penalty, cooldown)
    }

    /// @notice Gets the token ID of the Artifact entangled with the given one.
    /// @param tokenId The ID of the Artifact.
    /// @return entangledTokenId The ID of the entangled Artifact, or 0 if none.
    function getEntangledArtifact(uint256 tokenId) public view returns (uint256) {
        return _entangledWith[tokenId];
    }

    /// @notice Checks if two specific Artifacts are currently entangled with each other.
    /// @param tokenIdA The ID of the first Artifact.
    /// @param tokenIdB The ID of the second Artifact.
    /// @return isEntangled True if they are entangled with each other.
    function getEntanglementStatus(uint256 tokenIdA, uint256 tokenIdB) public view returns (bool) {
         if (!_exists(tokenIdA) || !_exists(tokenIdB) || tokenIdA == tokenIdB) return false;
         return _entangledWith[tokenIdA] == tokenIdB && _entangledWith[tokenIdB] == tokenIdA;
    }

     /// @notice Checks if an Artifact is currently entangled with *any* other Artifact.
     /// @param tokenId The ID of the Artifact.
     /// @return isEntangled True if it is entangled.
    function isArtifactEntangled(uint256 tokenId) public view returns (bool) {
         return _entangledWith[tokenId] != 0;
    }


    // --- VI. Admin / Configuration (Owner-Only) ---

    /// @notice Sets the parameters for a specific Era type. Owner only.
    /// @param eraIndex The enum index of the Era type.
    /// @param params The EraParameters struct to set.
    function setEraParameters(uint256 eraIndex, EraParameters memory params) public onlyOwner {
        // Add validation for eraIndex bounds if necessary
        _eraParameters[eraIndex] = params;
    }

    /// @notice Sets the parameters for a specific Essence type. Owner only.
    /// @param essenceType The type of essence.
    /// @param params The EssenceParameters struct to set.
    function setEssenceParameters(EssenceType essenceType, EssenceParameters memory params) public onlyOwner {
         _essenceParameters[essenceType] = params;
    }

    /// @notice Grants or revokes permission for an address to mint artifacts and essences. Owner only.
    /// @param minter The address to grant/revoke permission.
    /// @param allowed Whether to allow or disallow minting.
    function setMintingPermissions(address minter, bool allowed) public onlyOwner {
        _minterPermissions[minter] = allowed;
        emit MintingPermissionSet(minter, allowed);
    }


    // --- Internal / Helper Functions ---

    /// @dev Checks if the caller has minting permission.
    modifier onlyMinter() {
        require(_minterPermissions[msg.sender], "Caller is not a minter.");
        _;
    }

    /// @dev Helper to return all possible EssenceType enum values. (Manual approach)
    function _getAllEssenceTypes() private pure returns (EssenceType[] memory) {
         EssenceType[] memory allTypes = new EssenceType[](10); // Hardcoded count
         allTypes[0] = EssenceType.ElementalFire;
         allTypes[1] = EssenceType.ElementalWater;
         allTypes[2] = EssenceType.ElementalEarth;
         allTypes[3] = EssenceType.ElementalAir;
         allTypes[4] = EssenceType.TemporalShift;
         allTypes[5] = EssenceType.TemporalStasis;
         allTypes[6] = EssenceType.CognitiveInsight;
         allTypes[7] = EssenceType.CognitiveHarmony;
         allTypes[8] = EssenceType.StructuralIntegrity;
         allTypes[9] = EssenceType.StructuralAdaptability;
         return allTypes;
    }


    // --- ERC721 Receiver ---

    /// @notice Used to accept `safeTransferFrom` with data.
    /// ERC721 tokens transferred to this contract are *burned*. This prevents locking tokens.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
         // This contract is not designed to hold ERC721 tokens other than its own.
         // Any foreign ERC721 sent here will be effectively burned.
         // Consider adding a specific receiver function if you want to *receive* other NFTs.
         // For this example, we'll return the magic value to signal we accept,
         // but the token will likely be lost unless specific handling is added based on `data`.
         // A safer approach is to revert if unexpected tokens are received.
         // require(msg.sender == address(this), "Cannot receive foreign ERC721 tokens."); // Revert to be safe

         // If you *did* want to enable interactions where sending an NFT triggers something:
         // Parse `data` to determine action.
         // E.g., data could specify merging this token into an Artifact.

         // For this simple MD-NFT example, just accepting means tokens sent here are gone.
         // It might be better to `revert("Receiving foreign NFTs not supported");`

        // Returning the magic value indicates successful receipt according to ERC721 spec
        return this.onERC721Received.selector;
    }

    // --- Placeholder / Concepts for Future Expansion ---
    // struct ForgeParameters { ... } // Define materials needed for minting/forging
    // mapping(EssenceType => EssenceType) private _essenceMergeResults; // What happens when merging?
    // mapping(uint256 => mapping(string => bytes)) private _artifactTemporaryEffects; // Effects from entanglement, era shifts etc.
    // function harvestTemporaryState(uint256 tokenId) public returns (uint256 newEphemeralTokenId) { ... } // Create a temp NFT based on current state
    // function resolveConflict(uint256 tokenIdA, uint256 tokenIdB) public { ... } // Mechanic for entangled artifacts

}

// --- Library Includes (Simulated for clarity, use actual imports) ---
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Base64.sol";
// import "@openzeppelin/contracts/utils/Strings.sol"; // Needed for tokenURI
// import "@openzeppelin/contracts/utils/math/Math.sol"; // Needed for Math.min
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Note: You will need to install OpenZeppelin Contracts:
// `npm install @openzeppelin/contracts` or `yarn add @openzeppelin/contracts`
// And include the actual import paths at the top.
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic/Mutable NFTs:** The Artifact's state (`resonance`, `attunedEssences`) changes over time and through interaction. The `tokenURI` is overridden to reflect this dynamic state, allowing external metadata/images to change.
2.  **Layered/Component-Based NFTs:** Artifacts are not monolithic; their attributes are heavily influenced by the `Essences` attached to them. This creates a modular structure where the NFT's "appearance" or "stats" are a composition of its base state and its components.
3.  **Time-Based Evolution (Resonance):** The `resonance` value accrues passively over time, introducing a time-locking or aging mechanic that directly impacts the NFT's state and potentially its value or visual representation. The `applyResonance` function is a user-triggered state update based on elapsed time.
4.  **Global State Influence (Eras):** The contract introduces a global state machine (`Era`) that affects all NFTs in the collection simultaneously. This allows for planned seasonal changes, events, or economic shifts within the ecosystem, making the collection react to a shared environment.
5.  **Non-NFT Components (Essence Inventory):** Users hold `Essences` in a simple contract-internal inventory mapping (`_userEssences`), which they can then "burn" from their inventory to "attune" onto their NFTs. This separates the collectible/tradable component (NFT Artifacts) from the utility/consumable component (Essences).
6.  **NFT Entanglement:** A novel concept allowing two specific NFTs to form a unique, bidirectional link. This opens possibilities for paired effects, joint achievements, shared state, or unique interactions only possible when entangled. It adds a social/relationship layer between tokens.
7.  **On-Chain Attributes for Metadata:** Key state variables (`resonance`, `era`, `attunedEssences`, `entangledWith`) are directly queried by the `tokenURI` function to generate dynamic metadata attributes, ensuring the on-chain state dictates the off-chain representation.
8.  **Permissioned Minting/Forging:** Using a minter role (`onlyMinter`) separates creation from ownership, allowing for controlled supply or distribution mechanisms (e.g., a game where certain actions grant forging permission).
9.  **Gas Considerations:** The `applyResonance` function requires the owner to pay gas to update the state, externalizing some computation cost. Query functions (`getArtifactState`, `getAccruableResonance`, `tokenURI`) are view/pure and free to call. Iterating through all `EssenceType` enums in `getArtifactState` and `getUserEssences`, or iterating through `totalSupply` in `acceptEntanglement`, can become gas-intensive for large numbers of essence types or tokens. A real-world implementation might need more optimized storage patterns (e.g., linked lists for attuned essences) or alternative data structures for entanglement requests.

This contract provides a foundation for a rich, interactive NFT ecosystem where tokens are not static images but evolving entities with internal states and relationships influenced by game-like mechanics.