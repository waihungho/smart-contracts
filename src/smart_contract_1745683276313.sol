Okay, here is a smart contract concept called "Genesis Artifacts". It's a dynamic, interactive NFT system where artifacts evolve based on user interaction, time, and potentially random events. It blends ERC-721 ownership with state-changing mechanics and derived traits, aiming for a creative, non-standard approach.

It includes features like:
*   **Dynamic Traits:** Artifacts have internal states (essence, attunement, power) that change.
*   **Derived Traits:** Power level is calculated, not just stored.
*   **Interactive Evolution:** Users must "attune" their artifacts to increase stats and accumulate essence.
*   **Resource Management:** Artifacts accumulate "essence" which can be extracted or used for other actions.
*   **Merging:** Combine two artifacts, potentially burning one and transferring properties to the other.
*   **Refinement:** Change an artifact's core "Essence Type" under certain conditions.
*   **Random Events:** Pseudo-random on-chain events can affect artifact state.
*   **Unlockable Abilities:** Artifacts can reach thresholds to unlock special states/abilities.
*   **Dynamic Metadata:** `tokenURI` reflects the artifact's current state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Contract: GenesisArtifact ---
//
// Outline:
// 1. State Variables: Define core artifact properties, configuration, and counters.
// 2. Structs: Define the structure for storing artifact data.
// 3. Events: Declare events for state changes and actions.
// 4. Errors: Define custom error types for clarity.
// 5. Constructor: Initialize contract with name, symbol, and owner.
// 6. Modifiers: Custom modifiers for access control and state checks.
// 7. Internal Logic: Helper functions for core mechanics (essence calculation, power calculation, data generation).
// 8. ERC721 Overrides: Implement standard ERC721 functions, including dynamic tokenURI.
// 9. Core Interaction Functions: Functions allowing users to interact with their artifacts (attune, extract, merge, refine, trigger event).
// 10. Query Functions: Functions to retrieve detailed artifact data.
// 11. Owner/Configuration Functions: Functions for the contract owner to manage parameters and state.
//
// Function Summary (at least 20 functions):
// ERC721 Standard (inherited/overridden):
// - name() external view returns (string memory)
// - symbol() external view returns (string memory)
// - balanceOf(address owner) external view returns (uint256)
// - ownerOf(uint256 tokenId) external view returns (address)
// - approve(address to, uint256 tokenId) external
// - getApproved(uint256 tokenId) external view returns (address)
// - setApprovalForAll(address operator, bool approved) external
// - isApprovedForAll(address owner, address operator) external view returns (bool)
// - transferFrom(address from, address to, uint256 tokenId) external
// - safeTransferFrom(address from, address to, uint256 tokenId) external
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external
// - tokenURI(uint256 tokenId) public view override returns (string memory) // Overridden for dynamic metadata

// Custom Functions:
// - mintGenesisArtifact(address recipient, uint256 generationSeed) external // Mint a new genesis artifact
// - getArtifactData(uint256 tokenId) public view returns (ArtifactData memory) // Get all core artifact data
// - getArtifactEssenceAmount(uint256 tokenId) public view returns (uint256) // Get current essence (updated)
// - getArtifactPowerLevel(uint256 tokenId) public view returns (uint256) // Get current power (calculated)
// - getArtifactAttunement(uint256 tokenId) public view returns (uint256) // Get current attunement score
// - attuneArtifact(uint256 tokenId) external // Nurture the artifact, increasing attunement over time
// - extractEssence(uint256 tokenId, uint256 amount) external // Extract essence from the artifact
// - mergeArtifacts(uint256 tokenId1, uint256 tokenId2) external // Merge two artifacts (burns tokenId2, boosts tokenId1)
// - refineEssenceType(uint256 tokenId, EssenceType newType) external // Change artifact's essence type at a cost
// - triggerRandomEvent(uint256 tokenId) external // Trigger a pseudo-random event affecting the artifact
// - unlockSpecialAbility(uint256 tokenId) external // Attempt to unlock a special ability based on power/attunement
// - setAttunementCooldown(uint256 blocks) external onlyOwner // Set cooldown for attuning
// - setEssencePerBlock(uint256 amount) external onlyOwner // Set essence gain per block per attunement point
// - setMergeEssenceCost(uint256 cost) external onlyOwner // Set essence cost for merging
// - setRefineEssenceCost(uint256 cost) external onlyOwner // Set essence cost for refining
// - setBasePower(uint256 power) external onlyOwner // Set the base power value
// - setAbilityUnlockThreshold(uint256 powerThreshold, uint256 attunementThreshold) external onlyOwner // Set ability unlock requirements
// - setArtifactMetadataURI(string memory newBaseURI) external onlyOwner // Set the base URI for metadata
// - withdrawFunds(address payable recipient) external onlyOwner // Withdraw collected ETH from the contract
// - pauseContract() external onlyOwner // Pause core interactions
// - unpauseContract() external onlyOwner // Unpause core interactions

using Counters for Counters.Counter;
using SafeMath for uint256; // Although 0.8+ handles overflow, SafeMath adds clarity/safety for older patterns
using Strings for uint256; // For tokenURI

contract GenesisArtifact is ERC721, Ownable, Pausable {
    Counters.Counter private _tokenIds;

    enum EssenceType { NONE, FIRE, WATER, EARTH, AIR, AETHER } // NONE for unassigned/initial state

    struct ArtifactData {
        EssenceType essenceType;
        uint256 generationParameters; // Seed + other factors influencing initial state
        uint256 essenceAmount;        // Accumulated resource within the artifact
        uint256 attunementScore;      // Represents how 'nurtured' the artifact is
        uint40 lastAttunedBlock;     // Block number of the last attunement
        uint256 powerLevel;           // Calculated power level (derived)
    }

    mapping(uint256 => ArtifactData) private _artifactData;
    mapping(uint256 => bool) private _unlockedAbilities; // Simple flag for unlocked state

    // Configuration Variables
    uint256 public attunementCooldownBlocks;
    uint256 public essencePerAttuneBlock; // Essence gained per block per point of attunement
    uint256 public mergeEssenceCost;      // Essence cost on primary artifact for merge
    uint256 public refineEssenceCost;     // Essence cost for type refinement
    uint256 public basePower;             // Base power added to all artifacts
    uint256 public abilityUnlockPowerThreshold; // Min power to attempt ability unlock
    uint256 public abilityUnlockAttunementThreshold; // Min attunement to attempt ability unlock

    // Metadata URI base
    string private _baseTokenURI;

    // --- Events ---
    event ArtifactMinted(uint256 indexed tokenId, address indexed owner, EssenceType initialType);
    event ArtifactAttuned(uint256 indexed tokenId, uint256 newAttunementScore, uint256 essenceGained);
    event EssenceExtracted(uint256 indexed tokenId, uint256 amountExtracted, uint256 remainingEssence);
    event ArtifactMerged(uint256 indexed primaryTokenId, uint256 indexed burntTokenId, uint256 newPowerLevel);
    event EssenceTypeRefined(uint256 indexed tokenId, EssenceType oldType, EssenceType newType);
    event RandomEventTriggered(uint256 indexed tokenId, uint256 outcomeCode, string description);
    event SpecialAbilityUnlocked(uint256 indexed tokenId);
    event ConfigUpdated(string paramName, uint256 value);

    // --- Errors ---
    error InvalidTokenId();
    error NotTokenOwner();
    error AttunementCooldownActive(uint256 remainingBlocks);
    error InsufficientEssence(uint256 required, uint256 available);
    error CannotMergeSelf();
    error MergeConditionsNotMet();
    error RefineConditionsNotMet();
    error AbilityUnlockConditionsNotMet();
    error AbilityAlreadyUnlocked();
    error NothingToWithdraw();


    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialAttuneCooldown,
        uint256 initialEssencePerBlock,
        uint256 initialMergeCost,
        uint256 initialRefineCost,
        uint256 initialBasePower,
        uint256 initialAbilityPowerThreshold,
        uint256 initialAbilityAttunementThreshold,
        string memory initialBaseURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        attunementCooldownBlocks = initialAttuneCooldown;
        essencePerAttuneBlock = initialEssencePerBlock;
        mergeEssenceCost = initialMergeCost;
        refineEssenceCost = initialRefineCost;
        basePower = initialBasePower;
        abilityUnlockPowerThreshold = initialAbilityPowerThreshold;
        abilityUnlockAttunementThreshold = initialAbilityAttunementThreshold;
        _baseTokenURI = initialBaseURI;
    }

    // --- Modifiers ---
    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        _;
    }

    // --- Internal Logic ---

    /**
     * @dev Generates initial data for a new artifact based on seeds.
     * Uses block data and generationSeed for pseudo-randomness.
     * In a real application, consider Chainlink VRF for stronger randomness.
     */
    function _generateArtifactData(uint256 tokenId, uint256 generationSeed) internal view returns (ArtifactData memory) {
        uint256 initialEntropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Use block.number if difficulty is 0 on PoS
            msg.sender,
            tokenId,
            generationSeed,
            block.gaslimit,
            tx.origin,
            block.number
        )));

        ArtifactData memory newData;
        newData.generationParameters = initialEntropy; // Store initial entropy/seed
        newData.essenceAmount = 0;
        newData.attunementScore = 0;
        newData.lastAttunedBlock = uint40(block.number); // Set initial last attune block
        newData.powerLevel = basePower; // Base power initially

        // Determine initial EssenceType (simple pseudo-random distribution)
        uint256 typeDeterminant = uint256(keccak256(abi.encodePacked(initialEntropy, "type")));
        if (typeDeterminant % 100 < 15) { // 15% chance
            newData.essenceType = EssenceType.FIRE;
        } else if (typeDeterminant % 100 < 30) { // 15% chance
            newData.essenceType = EssenceType.WATER;
        } else if (typeDeterminant % 100 < 45) { // 15% chance
            newData.essenceType = EssenceType.EARTH;
        } else if (typeDeterminant % 100 < 60) { // 15% chance
            newData.essenceType = EssenceType.AIR;
        } else if (typeDeterminant % 100 < 70) { // 10% chance
             newData.essenceType = EssenceType.AETHER; // Rarer type
        } else { // 30% chance
            newData.essenceType = EssenceType.NONE; // Undetermined or Neutral
        }

        // Initial power tweak based on type/parameters (example logic)
         if (newData.essenceType == EssenceType.AETHER) {
            newData.powerLevel = newData.powerLevel.add(basePower.div(2)); // Aether gets a boost
        } else if (newData.essenceType == EssenceType.NONE) {
            newData.powerLevel = newData.powerLevel.sub(basePower.div(4)); // Neutral starts weaker
        }
        // Further power modification based on generationParameters could be added here

        return newData;
    }

    /**
     * @dev Calculates the potential essence gain since last update/attunement.
     * Updates the essence amount and lastAttunedBlock.
     */
    function _updateEssence(uint256 tokenId) internal {
        ArtifactData storage artifact = _artifactData[tokenId];
        uint256 blocksPassed = block.number.sub(artifact.lastAttunedBlock);

        if (blocksPassed > 0 && artifact.attunementScore > 0) {
            uint256 essenceGained = blocksPassed.mul(artifact.attunementScore).mul(essencePerAttuneBlock);
            artifact.essenceAmount = artifact.essenceAmount.add(essenceGained);
        }
        artifact.lastAttunedBlock = uint40(block.number); // Always update block number
    }

     /**
     * @dev Calculates the artifact's current power level based on its state.
     * This is a derived property.
     */
    function _calculatePower(uint256 tokenId) internal view returns (uint256) {
        ArtifactData storage artifact = _artifactData[tokenId];
        uint256 currentPower = basePower;

        // Add power from essence (diminishing returns example)
        currentPower = currentPower.add(artifact.essenceAmount.div(100)); // 100 essence = 1 power

        // Add power from attunement (linear example)
        currentPower = currentPower.add(artifact.attunementScore.mul(2)); // 1 attunement = 2 power

        // Add power from essence type (example bonuses)
        if (artifact.essenceType == EssenceType.FIRE) currentPower = currentPower.add(50);
        else if (artifact.essenceType == EssenceType.WATER) currentPower = currentPower.add(55); // Slightly different bonuses
        else if (artifact.essenceType == EssenceType.EARTH) currentPower = currentPower.add(60);
        else if (artifact.essenceType == EssenceType.AIR) currentPower = currentPower.add(65);
        else if (artifact.essenceType == EssenceType.AETHER) currentPower = currentPower.add(150); // Significant bonus

        // Add power based on initial generation parameters (example)
        // uint256 initialSeedInfluence = artifact.generationParameters % 100;
        // currentPower = currentPower.add(initialSeedInfluence);

        // Minimum power level
        return currentPower > basePower ? currentPower : basePower;
    }

    /**
     * @dev Checks if a token ID exists by trying to get its owner.
     * @param tokenId The token ID to check.
     * @return bool True if the token exists, false otherwise.
     */
     function _exists(uint256 tokenId) internal view returns (bool) {
         return super.ownerOf(tokenId) != address(0);
     }


    // --- ERC721 Overrides ---

    /**
     * @dev See {ERC721-tokenURI}.
     * This implementation generates a dynamic JSON based on the artifact's current state.
     * Note: This is a simplified example. A real implementation might serve JSON from a gateway
     * like IPFS or a dedicated metadata service, linking via the returned URI.
     * Returning base64 encoded JSON directly is gas-intensive for complex metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
             revert InvalidTokenId();
        }
        ArtifactData memory artifact = _artifactData[tokenId];

        // Recalculate power for the metadata view
        uint256 currentPower = _calculatePower(tokenId);
        bool unlocked = _unlockedAbilities[tokenId];

        // Map EssenceType enum to string
        string memory essenceTypeString;
        if (artifact.essenceType == EssenceType.NONE) essenceTypeString = "None";
        else if (artifact.essenceType == EssenceType.FIRE) essenceTypeString = "Fire";
        else if (artifact.essenceType == EssenceType.WATER) essenceTypeString = "Water";
        else if (artifact.essenceType == EssenceType.EARTH) essenceTypeString = "Earth";
        else if (artifact.essenceType == EssenceType.AIR) essenceTypeString = "Air";
        else if (artifact.essenceType == EssenceType.AETHER) essenceTypeString = "Aether";


        // Construct the JSON metadata string
        // Example structure - minimal
        string memory json = string(abi.encodePacked(
            '{"name": "Genesis Artifact #', tokenId.toString(), '",',
            '"description": "A dynamic digital artifact that evolves with interaction.",',
            '"image": "', _baseTokenURI, tokenId.toString(), '.png",', // Example image path
            '"attributes": [',
                '{"trait_type": "Essence Type", "value": "', essenceTypeString, '"},',
                '{"trait_type": "Power Level", "value": ', currentPower.toString(), '},',
                '{"trait_type": "Attunement Score", "value": ', artifact.attunementScore.toString(), '},',
                '{"trait_type": "Essence Amount", "value": ', artifact.essenceAmount.toString(), '},',
                 '{"trait_type": "Ability Unlocked", "value": ', (unlocked ? "true" : "false"), '}',
             ']}'
        ));

        // You could base64 encode this JSON and prepend "data:application/json;base64,"
        // using utility libraries, but direct return is simpler for demonstration.
        // return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        return string(abi.encodePacked("data:application/json,", json));
    }


    // --- Core Interaction Functions ---

    /**
     * @dev Mints a new Genesis Artifact. Can only be called by the owner initially (e.g., for a genesis drop).
     * Includes a seed parameter for initial generation uniqueness.
     */
    function mintGenesisArtifact(address recipient, uint256 generationSeed) external onlyOwner whenNotPaused {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        ArtifactData memory initialData = _generateArtifactData(newItemId, generationSeed);
        _artifactData[newItemId] = initialData;
        _artifactData[newItemId].powerLevel = _calculatePower(newItemId); // Calculate initial power

        _safeMint(recipient, newItemId);

        emit ArtifactMinted(newItemId, recipient, initialData.essenceType);
    }

     /**
     * @dev Allows the owner of an artifact to attune it.
     * Increases attunement score and accumulates essence based on time since last attunement.
     * Subject to a cooldown.
     * Requires some ETH as a 'cost' or 'effort' (can be removed or replaced with token burn).
     */
    function attuneArtifact(uint256 tokenId) external payable whenNotPaused onlyTokenOwner(tokenId) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        ArtifactData storage artifact = _artifactData[tokenId];
        uint256 blocksPassed = block.number.sub(artifact.lastAttunedBlock);

        if (blocksPassed < attunementCooldownBlocks) {
            revert AttunementCooldownActive(attunementCooldownBlocks.sub(blocksPassed));
        }

        // Ensure essence is updated before attunement score is potentially used for essence gain calculation
        _updateEssence(tokenId); // Updates essence based on *previous* score and blocksPassed

        artifact.attunementScore = artifact.attunementScore.add(1); // Simple increment example
        // Could add scaling here: artifact.attunementScore = artifact.attunementScore.add(msg.value / 1e15); // example: 1 attune per 0.001 ETH

        // Re-calculate and store the new power level
        artifact.powerLevel = _calculatePower(tokenId);

        // Note: The essence gained by this attunement point starts accumulating from the *next* block.
        // The _updateEssence call above calculated gain up to *this* block using the *old* attunement score.
        // The next time _updateEssence is called, it will use the *new* score.

        emit ArtifactAttuned(tokenId, artifact.attunementScore, blocksPassed.mul(artifact.attunementScore.sub(1)).mul(essencePerAttuneBlock)); // Emit essence gained based on previous score and blocks passed
    }

    /**
     * @dev Allows the owner to extract a specific amount of essence from their artifact.
     * This essence could potentially be used in other systems or traded.
     * Decreases the artifact's essence amount and potentially its power.
     */
    function extractEssence(uint256 tokenId, uint256 amount) external whenNotPaused onlyTokenOwner(tokenId) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        ArtifactData storage artifact = _artifactData[tokenId];

        // Ensure essence is up-to-date before checking balance
        _updateEssence(tokenId);

        if (artifact.essenceAmount < amount) {
            revert InsufficientEssence(amount, artifact.essenceAmount);
        }

        artifact.essenceAmount = artifact.essenceAmount.sub(amount);

        // Re-calculate and store the new power level
        artifact.powerLevel = _calculatePower(tokenId);

        // Optional: Transfer a utility token or emit event for off-chain reward based on amount
        // emit EssenceTokensMinted(msg.sender, amount);

        emit EssenceExtracted(tokenId, amount, artifact.essenceAmount);
    }

     /**
     * @dev Allows the owner to merge two artifacts they own.
     * tokenId1 is the primary artifact, tokenId2 is consumed (burnt).
     * Properties from tokenId2 are transferred to tokenId1.
     * Requires sufficient essence on tokenId1.
     */
    function mergeArtifacts(uint256 tokenId1, uint256 tokenId2) external whenNotPaused {
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert InvalidTokenId();
        if (tokenId1 == tokenId2) revert CannotMergeSelf();

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        if (owner1 != msg.sender || owner2 != msg.sender) {
            revert NotTokenOwner(); // Must own both tokens
        }

        ArtifactData storage artifact1 = _artifactData[tokenId1];
        ArtifactData storage artifact2 = _artifactData[tokenId2];

         // Ensure essence is up-to-date on both before merge
        _updateEssence(tokenId1);
        _updateEssence(tokenId2);

        // Example Merge Logic:
        // 1. Check cost
        if (artifact1.essenceAmount < mergeEssenceCost) {
            revert InsufficientEssence(mergeEssenceCost, artifact1.essenceAmount);
        }
        artifact1.essenceAmount = artifact1.essenceAmount.sub(mergeEssenceCost);

        // 2. Transfer a portion of stats from artifact2 to artifact1
        // Example: Transfer 50% essence, 25% attunement
        artifact1.essenceAmount = artifact1.essenceAmount.add(artifact2.essenceAmount.div(2));
        artifact1.attunementScore = artifact1.attunementScore.add(artifact2.attunementScore.div(4));

        // 3. Potentially influence essence type or parameters (more complex logic possible)
        // Example: 50% chance to inherit type if artifact2's power is higher
        // uint256 mergeDeterminant = uint256(keccak256(abi.encodePacked(block.number, tokenId1, tokenId2, artifact1.powerLevel, artifact2.powerLevel)));
        // if (artifact2.powerLevel > artifact1.powerLevel && mergeDeterminant % 2 == 0) {
        //     artifact1.essenceType = artifact2.essenceType;
        // }

        // 4. Burn the second artifact
        _burn(tokenId2);

        // 5. Re-calculate and store the new power level for the primary artifact
        artifact1.powerLevel = _calculatePower(tokenId1);


        emit ArtifactMerged(tokenId1, tokenId2, artifact1.powerLevel);
    }

    /**
     * @dev Allows the owner to change the EssenceType of an artifact.
     * Requires sufficient essence and potentially a high attunement score.
     */
    function refineEssenceType(uint256 tokenId, EssenceType newType) external whenNotPaused onlyTokenOwner(tokenId) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         if (newType == EssenceType.NONE) revert RefineConditionsNotMet(); // Cannot refine to NONE

        ArtifactData storage artifact = _artifactData[tokenId];

        // Ensure essence is up-to-date
        _updateEssence(tokenId);

        // Example Refine Conditions:
        if (artifact.essenceAmount < refineEssenceCost || artifact.attunementScore < 50) { // Requires cost and minimum attunement
             revert RefineConditionsNotMet();
        }

        EssenceType oldType = artifact.essenceType;
        artifact.essenceAmount = artifact.essenceAmount.sub(refineEssenceCost);
        artifact.essenceType = newType;

        // Re-calculate and store the new power level
        artifact.powerLevel = _calculatePower(tokenId);

        emit EssenceTypeRefined(tokenId, oldType, newType);
    }

    /**
     * @dev Triggers a pseudo-random event that can positively or negatively affect the artifact.
     * Requires a small essence cost.
     */
    function triggerRandomEvent(uint256 tokenId) external whenNotPaused onlyTokenOwner(tokenId) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        ArtifactData storage artifact = _artifactData[tokenId];

        // Ensure essence is up-to-date
        _updateEssence(tokenId);

        uint256 eventCost = refineEssenceCost.div(2); // Example: Half the refine cost
         if (artifact.essenceAmount < eventCost) {
            revert InsufficientEssence(eventCost, artifact.essenceAmount);
        }
        artifact.essenceAmount = artifact.essenceAmount.sub(eventCost);


        // Pseudo-randomness based on block data and artifact state
        uint256 randomness = uint256(keccak256(abi.encodePacked(
            block.number,
            block.timestamp,
            tokenId,
            artifact.essenceAmount,
            artifact.attunementScore,
            artifact.powerLevel
        )));

        uint256 outcome = randomness % 100; // 0-99

        string memory description;
        uint256 outcomeCode; // For logging/event interpretation

        // Example Event Outcomes
        if (outcome < 10) { // 10% chance: Small positive boost
            uint256 boost = artifact.powerLevel.div(20); // 5% power boost
            artifact.powerLevel = artifact.powerLevel.add(boost);
            description = "A cosmic alignment boosts its power slightly.";
            outcomeCode = 1;
        } else if (outcome < 20) { // 10% chance: Gain some essence
             uint256 essenceBoost = 100;
             artifact.essenceAmount = artifact.essenceAmount.add(essenceBoost);
             description = "Absorbed stray energy, gaining essence.";
             outcomeCode = 2;
        } else if (outcome < 30) { // 10% chance: Gain some attunement
             artifact.attunementScore = artifact.attunementScore.add(5);
             description = "Inner harmony improved attunement.";
             outcomeCode = 3;
        } else if (outcome < 40) { // 10% chance: Small negative effect
            uint256 loss = artifact.powerLevel.div(30); // ~3% power loss
            artifact.powerLevel = artifact.powerLevel.sub(loss); // Use SafeMath sub or check for underflow
            description = "A minor disruption weakens it.";
            outcomeCode = 4;
        } else if (outcome < 50) { // 10% chance: Lose some essence
             uint256 essenceLoss = 50;
             if (artifact.essenceAmount > essenceLoss) {
                 artifact.essenceAmount = artifact.essenceAmount.sub(essenceLoss);
             } else {
                 artifact.essenceAmount = 0;
             }
             description = "Energy fluctuations caused essence drain.";
             outcomeCode = 5;
        } else if (outcome < 60) { // 10% chance: Lose some attunement
            if (artifact.attunementScore > 2) {
                 artifact.attunementScore = artifact.attunementScore.sub(2);
             } else {
                 artifact.attunementScore = 0;
             }
            description = "Distractions reduced attunement.";
            outcomeCode = 6;
        } else { // 40% chance: Nothing significant happens
            description = "Nothing notable occurred.";
            outcomeCode = 0;
        }

        // Ensure power is recalculated if effects changed essence/attunement, or if it was directly changed
         artifact.powerLevel = _calculatePower(tokenId); // Always recalculate after potential state changes

        emit RandomEventTriggered(tokenId, outcomeCode, description);
    }


    /**
     * @dev Allows the owner to attempt to unlock a special ability for the artifact.
     * Requires meeting minimum power and attunement thresholds. Once unlocked, stays unlocked.
     */
    function unlockSpecialAbility(uint256 tokenId) external whenNotPaused onlyTokenOwner(tokenId) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        ArtifactData storage artifact = _artifactData[tokenId];

        // Ensure essence is up-to-date (as power depends on it)
        _updateEssence(tokenId);

        // Re-calculate power before checking threshold
        artifact.powerLevel = _calculatePower(tokenId);


        if (_unlockedAbilities[tokenId]) {
            revert AbilityAlreadyUnlocked();
        }

        if (artifact.powerLevel < abilityUnlockPowerThreshold || artifact.attunementScore < abilityUnlockAttunementThreshold) {
            revert AbilityUnlockConditionsNotMet();
        }

        _unlockedAbilities[tokenId] = true;

        emit SpecialAbilityUnlocked(tokenId);
    }


    // --- Query Functions ---

    /**
     * @dev Gets the full ArtifactData struct for a given token ID.
     * Note: The powerLevel returned here is the *last stored* value.
     * Use getArtifactPowerLevel for the dynamically calculated current value.
     * EssenceAmount returned here is also the *last stored* value.
     * Use getArtifactEssenceAmount for the value including accrued essence.
     */
    function getArtifactData(uint256 tokenId) public view returns (ArtifactData memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _artifactData[tokenId];
    }

    /**
     * @dev Gets the current essence amount for an artifact, including accrued essence.
     * This function calls _updateEssence internally in a view context to calculate the current amount
     * without saving the state change.
     */
    function getArtifactEssenceAmount(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        ArtifactData storage artifact = _artifactData[tokenId];
        uint256 blocksPassed = block.number.sub(artifact.lastAttunedBlock);
        uint256 accruedEssence = blocksPassed.mul(artifact.attunementScore).mul(essencePerAttuneBlock);
        return artifact.essenceAmount.add(accruedEssence);
    }

     /**
     * @dev Gets the dynamically calculated current power level for an artifact.
     * This function calls _calculatePower internally.
     * Note: This does NOT update the stored powerLevel state variable.
     */
    function getArtifactPowerLevel(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // To calculate power accurately, we first need to know the current essence amount.
        // Call the view function that calculates current essence.
        // This is slightly less efficient than if _calculatePower could access the internal _updateEssence state.
        // A pattern for views needing updated state is to pass the updated state *into* the calculation function.
        // For simplicity here, we call the public view getter for essence.
        uint256 currentEssence = getArtifactEssenceAmount(tokenId);
        ArtifactData storage artifact = _artifactData[tokenId];

        // Recalculate using current essence amount (which is not stored in artifact)
        uint256 currentPower = basePower;
        currentPower = currentPower.add(currentEssence.div(100));
        currentPower = currentPower.add(artifact.attunementScore.mul(2));

        if (artifact.essenceType == EssenceType.FIRE) currentPower = currentPower.add(50);
        else if (artifact.essenceType == EssenceType.WATER) currentPower = currentPower.add(55);
        else if (artifact.essenceType == EssenceType.EARTH) currentPower = currentPower.add(60);
        else if (artifact.essenceType == EssenceType.AIR) currentPower = currentPower.add(65);
        else if (artifact.essenceType == EssenceType.AETHER) currentPower = currentPower.add(150);

        return currentPower > basePower ? currentPower : basePower;
    }


    /**
     * @dev Gets the current attunement score for an artifact.
     */
    function getArtifactAttunement(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _artifactData[tokenId].attunementScore;
    }

    /**
     * @dev Checks if a special ability is unlocked for an artifact.
     */
     function hasSpecialAbility(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _unlockedAbilities[tokenId];
     }


    // --- Owner/Configuration Functions ---

    function setAttunementCooldown(uint256 blocks) external onlyOwner {
        attunementCooldownBlocks = blocks;
        emit ConfigUpdated("attunementCooldownBlocks", blocks);
    }

    function setEssencePerBlock(uint256 amount) external onlyOwner {
        essencePerAttuneBlock = amount;
        emit ConfigUpdated("essencePerAttuneBlock", amount);
    }

     function setMergeEssenceCost(uint256 cost) external onlyOwner {
        mergeEssenceCost = cost;
        emit ConfigUpdated("mergeEssenceCost", cost);
    }

     function setRefineEssenceCost(uint256 cost) external onlyOwner {
        refineEssenceCost = cost;
        emit ConfigUpdated("refineEssenceCost", cost);
    }

     function setBasePower(uint256 power) external onlyOwner {
        basePower = power;
        emit ConfigUpdated("basePower", power);
    }

    function setAbilityUnlockThreshold(uint256 powerThreshold, uint256 attunementThreshold) external onlyOwner {
        abilityUnlockPowerThreshold = powerThreshold;
        abilityUnlockAttunementThreshold = attunementThreshold;
        emit ConfigUpdated("abilityUnlockPowerThreshold", powerThreshold);
        emit ConfigUpdated("abilityUnlockAttunementThreshold", attunementThreshold);
    }

     function setArtifactMetadataURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
         // No event for string change, or create a dedicated one
    }

    /**
     * @dev Allows the owner to withdraw ETH collected from attunement fees or other sources.
     */
    function withdrawFunds(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NothingToWithdraw();
        }
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev See {Pausable-pause}.
     * Allows the owner to pause interactions like minting and user actions.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     * Allows the owner to unpause the contract.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    // Simply calling the parent implementation is sufficient.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(Ownable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

     function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        // This function is called by _beforeTokenTransfer after state changes
        // Can add hooks here if needed before transferring
        return super._update(to, tokenId, auth);
     }

    function _incrementTokenId() internal override(ERC721) {
         // OpenZeppelin ERC721Enumerable used this, but base ERC721 doesn't.
         // Our custom _tokenIds counter handles ID management.
         // This function override is technically not needed for base ERC721 but good practice if using Enumerable later.
    }

     /**
      * @dev Hook that is called before any token transfer. This includes minting and burning.
      * Allows for state updates based on transfers.
      */
     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // When transferring (not minting/burning), update essence right before transfer.
        // This accrues essence for the *current* owner one last time before transfer.
        if (from != address(0) && to != address(0)) {
            if (_exists(tokenId)) { // Ensure token exists before accessing data
                 _updateEssence(tokenId);
                 // Power calculation could also happen here if needed for transfer effects
                 _artifactData[tokenId].powerLevel = _calculatePower(tokenId);
            }
        }
        // No specific action needed for minting (from == address(0))
        // No specific action needed for burning (to == address(0)), data is lost anyway.
     }


    // Required for receiving ERC721 tokens, though this contract doesn't receive NFTs itself.
    // Included for completeness if interaction with other NFT contracts was intended.
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure returns (bytes4) {
        // This contract does not accept incoming NFTs
        revert("Cannot receive NFTs");
        // return this.onERC721Received.selector; // Standard return value if you *did* want to receive
    }
}
```