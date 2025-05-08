Okay, let's design a smart contract that embodies several advanced, creative, and trendy concepts. We'll create a **"ChronoMorph"** NFT – a generative, evolving digital asset whose appearance and state dynamically change based on time, user interactions, and simulated external environmental factors (like an oracle feed). It will use on-chain data to influence its generated SVG metadata.

This combines:
1.  **Dynamic NFTs:** Metadata changes over time/interaction.
2.  **On-chain Generative Art Parameters:** Contract state directly influences the output image.
3.  **Time-Based Mechanics:** Evolution depends on elapsed time.
4.  **Interaction Mechanics:** User actions (feeding, training) influence the state.
5.  **External Data Influence:** State can be updated by an authorized source (simulating an oracle).
6.  **Role-Based Access Control:** Different actions require specific permissions (admin, minter, oracle updater).
7.  **Configurability:** Admin can tune evolution parameters.

We will leverage OpenZeppelin libraries for standard components like ERC721 and AccessControl, but the core evolution and dynamic metadata logic will be custom.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For tokenByIndex/tokenOfOwnerByIndex
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For custom tokenURI handling (though we override it)
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- ChronoMorph Contract: Outline and Summary ---
// Project: ChronoMorph - Dynamic, Evolving NFTs
// Description: An ERC721 token representing a digital entity that evolves
//              based on time elapsed, owner interactions, and external factors.
//              Its appearance (metadata/SVG) is generated on-chain reflecting
//              its current state and evolution stage.

// Core Concepts:
// - Dynamic NFT Metadata: tokenURI generates fresh data based on current state.
// - On-chain State & Evolution: Internal variables track energy, skill, stress,
//   environmental influence, and calculate evolution points/stage.
// - Time Sensitivity: State naturally degrades or improves over time.
// - User Interaction: Specific functions allow owners to influence state.
// - Simulated Oracle Feed: An authorized role can push external environmental data.
// - Generative Appearance: Token state determines parameters for a simple on-chain SVG representation.
// - Role-Based Access Control: Admin, Minter, Oracle roles manage permissions.

// Contract Structure:
// - Inheritance: ERC721Enumerable, ERC721URIStorage (though tokenURI is overridden), AccessControl.
// - Roles: DEFAULT_ADMIN_ROLE, MINTER_ROLE, ORACLE_UPDATER_ROLE.
// - Data Structures:
//   - struct MorphState: Holds evolution-relevant data for each token ID.
//   - mappings: tokenId to MorphState, tokenId existence check.
// - Configuration Variables: Evolution thresholds, time sensitivity factor, multipliers for interactions.
// - Counters: Tracks total minted tokens.
// - Events: Signify minting, state changes, configuration updates, role grants.

// Function Summary (Public & External Functions - Total >= 20):
// 1. constructor(string name, string symbol): Initializes contract, roles.
// 2. grantRole(bytes32 role, address account): Grants a specific role (Admin only). (Inherited from AccessControl)
// 3. revokeRole(bytes32 role, address account): Revokes a specific role (Admin only). (Inherited from AccessControl)
// 4. renounceRole(bytes32 role): User revokes their own role. (Inherited from AccessControl)
// 5. hasRole(bytes32 role, address account): Checks if account has role. (Inherited from AccessControl)
// 6. getRoleAdmin(bytes32 role): Gets the admin role for a given role. (Inherited from AccessControl)
// 7. mint(address recipient): Mints a new ChronoMorph (Minter role required).
// 8. feedMorph(uint256 tokenId, uint256 energyAmount): Increases morph energy state (Owner/Approved required).
// 9. trainMorph(uint256 tokenId): Increases morph skill, decreases stress (Owner/Approved required).
// 10. restMorph(uint256 tokenId): Decreases morph stress state (Owner/Approved required).
// 11. exposeToEnvironment(uint256 tokenId, uint256 newFactor): Updates environment factor for morph (Oracle Updater role required).
// 12. triggerTemporalShift(uint256 tokenId): Forces an immediate state recalculation based on time elapsed (Owner/Approved required, might consume gas).
// 13. tokenURI(uint256 tokenId): OVERRIDDEN - Generates and returns dynamic metadata URI (base64 encoded JSON with SVG).
// 14. getMorphState(uint256 tokenId): View function - Returns detailed current state struct.
// 15. getEvolutionStage(uint256 tokenId): View function - Returns the current evolution stage index.
// 16. getMorphSVG(uint256 tokenId): View function - Returns the calculated SVG string directly.
// 17. getLastInteractionTime(uint256 tokenId): View function - Returns the timestamp of the last interaction.
// 18. setEvolutionParameters(uint256 timeSensitivityFactor, uint256 feedMultiplier, uint256 trainSkillGain, uint256 trainStressGain, uint256 restStressReduction): Admin function - Sets evolution formula parameters.
// 19. setEvolutionThresholds(uint256[] thresholds): Admin function - Sets the points required for each evolution stage.
// 20. setOracleAddress(address oracle): Admin function - Sets the address authorized for oracle updates (alternatively grants ORACLE_UPDATER_ROLE). (Note: Using AccessControl roles is more flexible, this is an alternative or supplementary setting). Let's stick to roles.
// 21. withdrawFunds(address tokenAddress): Admin function - Withdraws ERC20 or Ether collected (e.g., from feeding fees).
// 22. supportsInterface(bytes4 interfaceId): Checks ERC compliance. (Inherited/implemented by OZ)
// --- Inherited/Standard ERC721 Functions (also count towards >= 20): ---
// 23. balanceOf(address owner): Returns owner's NFT count.
// 24. ownerOf(uint256 tokenId): Returns owner of token.
// 25. transferFrom(address from, address to, uint256 tokenId): Transfers token.
// 26. safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer.
// 27. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer with data.
// 28. approve(address to, uint256 tokenId): Approves address to transfer token.
// 29. setApprovalForAll(address operator, bool approved): Approves operator for all owner's tokens.
// 30. getApproved(uint256 tokenId): Gets approved address for token.
// 31. isApprovedForAll(address owner, address operator): Checks if operator is approved for all.
// 32. name(): Returns contract name.
// 33. symbol(): Returns contract symbol.
// --- Inherited ERC721Enumerable Functions (optional but included): ---
// 34. totalSupply(): Returns total number of tokens minted.
// 35. tokenByIndex(uint256 index): Returns token ID by index.
// 36. tokenOfOwnerByIndex(address owner, uint256 index): Returns owner's token ID by index.

// Note on Gas Costs: Generating complex SVG data on-chain can be very expensive.
// This example provides a simple SVG generation logic. For production, a more
// complex contract might store SVG parameters on-chain and use an off-chain
// service for rendering the final image pointed to by the tokenURI base.
// This implementation generates the *full* SVG string on-chain.
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For max/min

contract ChronoMorph is ERC721Enumerable, ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE");

    // --- Data Structures ---
    struct MorphState {
        uint64 creationTime;         // When the morph was minted
        uint64 lastInteractionTime;  // Last time feed/train/rest/env update/trigger happened
        uint256 energy;              // Represents vitality, gained by feeding
        uint256 skill;               // Represents capability, gained by training
        uint256 stress;              // Represents fatigue, gained by training, reduced by resting
        uint256 environmentFactor;   // External data influencing state (e.g., weather, market mood)
        uint256 evolutionPoints;     // Calculated score determining stage
        uint8 currentStage;          // Index of the current evolution stage
    }

    mapping(uint256 => MorphState) private _morphStates;

    // --- Configuration ---
    // Thresholds for evolution stages (points needed for each stage)
    uint256[] private _evolutionThresholds;

    // Parameters influencing state changes and evolution calculation
    uint256 private _timeSensitivityFactor = 10; // How much time decay/growth affects points (per day, scaled)
    uint256 private _feedMultiplier = 50;        // Energy gained per unit of 'feed' amount
    uint256 private _trainSkillGain = 10;        // Skill gained per training session
    uint256 private _trainStressGain = 15;       // Stress gained per training session
    uint256 private _restStressReduction = 20;   // Stress reduced per rest session

    // --- Events ---
    event MorphMinted(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event MorphStateUpdated(uint256 indexed tokenId, uint8 newStage, uint256 newPoints, uint64 timestamp);
    event MorphFed(uint256 indexed tokenId, uint256 amount, uint256 newEnergy);
    event MorphTrained(uint256 indexed tokenId, uint256 newSkill, uint256 newStress);
    event MorphRested(uint256 indexed tokenId, uint256 newStress);
    event EnvironmentUpdated(uint256 indexed tokenId, uint256 newFactor);
    event EvolutionParametersUpdated(uint256 timeSensitivityFactor, uint256 feedMultiplier, uint256 trainSkillGain, uint256 trainStressGain, uint256 restStressReduction);
    event EvolutionThresholdsUpdated(uint256[] thresholds);

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        ERC721Enumerable()
        ERC721URIStorage() // Allows overriding tokenURI while using OZ storage
        AccessControl()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender); // Grant initial minter role
        _grantRole(ORACLE_UPDATER_ROLE, msg.sender); // Grant initial oracle role

        // Set initial evolution thresholds (e.g., Stage 0 < 100, Stage 1 >= 100, Stage 2 >= 500, Stage 3 >= 1500)
        // The length of this array defines the number of stage transitions.
        // Stage N requires points >= thresholds[N-1]. Stage 0 is default below thresholds[0].
        _evolutionThresholds = [100, 500, 1500, 5000];
    }

    // --- AccessControl Overrides ---
    // Need to expose supportsInterface for AccessControl (ERC165)
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Core ChronoMorph Logic ---

    // Internal function to update morph state based on time and current values
    function _updateMorphState(uint256 tokenId) internal {
        MorphState storage morph = _morphStates[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Calculate time elapsed since last interaction/update in seconds
        uint66 elapsedSeconds = currentTime - morph.lastInteractionTime;

        // --- Apply Time Effects ---
        // Simulate state decay/growth over time. Example: stress increases, energy decreases.
        // Scaling time to prevent huge changes from small time differences.
        // Using a simple linear decay/growth per unit of scaled time (e.g., per hour or day)
        uint256 timeUnits = elapsedSeconds / 1 hours; // Or 1 days, depending on desired speed

        if (timeUnits > 0) {
            // Stress increases over time, capped at a reasonable max (e.g., 1000)
            morph.stress = Math.min(morph.stress + (timeUnits * _timeSensitivityFactor / 10), 1000);
            // Energy decreases over time, capped at 0
            morph.energy = morph.energy > (timeUnits * _timeSensitivityFactor / 5) ? morph.energy - (timeUnits * _timeSensitivityFactor / 5) : 0;
        }

        // Ensure stats don't go negative (uint underflow) - handled by the check above for energy, stress capped.
        // Skill might also decay if not trained, but let's keep it simple for now.

        // --- Calculate Evolution Points ---
        // This formula defines the evolution logic. Make it somewhat interesting.
        // Example: Points increase with energy and skill, decrease with stress. Environment adds a bonus.
        // Use 1e18 scaling for potential fractional results if more complex math needed, but keep it simple here.
        uint256 basePoints = (morph.energy + morph.skill);
        if (morph.stress > 0) {
            basePoints = basePoints * 100 / (morph.stress + 100); // Stress reduces points, less reduction for higher stress
        } else {
             basePoints = basePoints; // No stress penalty
        }

        // Environment factor adds a bonus proportional to its value
        morph.evolutionPoints = basePoints + (morph.environmentFactor * _timeSensitivityFactor / 10); // EnvFactor also scales by time sensitivity

        // --- Determine Evolution Stage ---
        uint8 newStage = 0;
        for (uint i = 0; i < _evolutionThresholds.length; i++) {
            if (morph.evolutionPoints >= _evolutionThresholds[i]) {
                newStage = uint8(i) + 1; // Stage 1 if >= threshold[0], Stage 2 if >= threshold[1], etc.
            } else {
                break; // Points not high enough for this stage
            }
        }

        // Update stage if it changed
        if (newStage != morph.currentStage) {
            morph.currentStage = newStage;
            emit MorphStateUpdated(tokenId, newStage, morph.evolutionPoints, currentTime);
        }

        // Always update last interaction time after state calculation/update
        morph.lastInteractionTime = currentTime;
    }

    // --- ERC721 Overrides ---

    // Override _update to ensure state is checked/updated on transfer (optional, but good for active morphs)
    // Not strictly necessary for just tokenURI, but if state affects transferability/rights, do it here.
    // For this example, we'll rely on tokenURI calling _updateMorphState.

    // Override tokenURI to provide dynamic metadata
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage) // Need to declare override for both if using URIStorage
        returns (string memory)
    {
        _requireOwned(tokenId); // Ensure token exists and is valid

        // --- Generate Dynamic Metadata ---
        // Fetch latest state (simulate update for view function - state isn't changed permanently here!)
        // In a real scenario, you'd need a mechanism to ensure state is fresh *before* URI fetch,
        // potentially by requiring a user action or relying on off-chain rendering service.
        // For this example, we'll generate based on *current* stored state + assumed time passage.
        // A better approach for view functions might be to calculate *potential* state if updated now.
        // Let's calculate based on current state and elapsed time since last update.
        MorphState memory currentState = _morphStates[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint66 elapsedSeconds = currentTime - currentState.lastInteractionTime;

        // Recalculate points/stage considering time effects since last update *for view purposes*
        uint256 currentEnergy = currentState.energy > (elapsedSeconds * _timeSensitivityFactor / 5 / 1 hours) ? currentState.energy - (elapsedSeconds * _timeSensitivityFactor / 5 / 1 hours) : 0;
        uint256 currentStress = Math.min(currentState.stress + (elapsedSeconds * _timeSensitivityFactor / 10 / 1 hours), 1000);
        uint256 currentSkill = currentState.skill; // Assume skill doesn't decay just for view
        uint256 currentEnvFactor = currentState.environmentFactor;

        uint256 currentBasePoints = (currentEnergy + currentSkill);
         if (currentStress > 0) {
            currentBasePoints = currentBasePoints * 100 / (currentStress + 100);
        }
        uint256 currentEvolutionPoints = currentBasePoints + (currentEnvFactor * _timeSensitivityFactor / 10);

        uint8 currentCalculatedStage = 0;
        for (uint i = 0; i < _evolutionThresholds.length; i++) {
            if (currentEvolutionPoints >= _evolutionThresholds[i]) {
                currentCalculatedStage = uint8(i) + 1;
            } else {
                break;
            }
        }

        // --- Generate SVG based on Calculated State ---
        string memory svg = _generateSVG(currentCalculatedStage, currentEvolutionPoints, currentEnergy, currentSkill, currentStress, currentEnvFactor);

        // --- Construct JSON Metadata ---
        string memory json = string(abi.encodePacked(
            '{',
                '"name": "ChronoMorph #', Strings.toString(tokenId), '",',
                '"description": "A metamorphic digital entity evolving through time, interaction, and environment.",',
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
                '"attributes": [',
                    '{', '"trait_type": "Stage", "value": ', Strings.toString(currentCalculatedStage), ' }', ',',
                    '{', '"trait_type": "Evolution Points", "value": ', Strings.toString(currentEvolutionPoints), ' }', ',',
                    '{', '"trait_type": "Energy", "value": ', Strings.toString(currentEnergy), ' }', ',',
                    '{', '"trait_type": "Skill", "value": ', Strings.toString(currentSkill), ' }', ',',
                    '{', '"trait_type": "Stress", "value": ', Strings.toString(currentStress), ' }', ',',
                    '{', '"trait_type": "Environment Factor", "value": ', Strings.toString(currentEnvFactor), ' }', ',',
                    '{', '"trait_type": "Time Since Interaction (s)", "value": ', Strings.toString(elapsedSeconds), ' }',
                ']',
            '}'
        ));

        // --- Return Data URI ---
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // Internal helper to generate simple SVG based on state parameters
    function _generateSVG(uint8 stage, uint256 points, uint256 energy, uint256 skill, uint256 stress, uint256 environmentFactor) internal pure returns (string memory) {
        // Simple SVG logic: change color and size based on stage and points.
        // Add elements based on stats.
        string memory bgColor;
        string memory circleColor;
        uint256 circleRadius = 30 + (points / 100); // Radius increases with points

        if (stage == 0) { bgColor = "#e0e0e0"; circleColor = "#a0a0a0"; } // Gray, basic
        else if (stage == 1) { bgColor = "#d0f0c0"; circleColor = "#4CAF50"; } // Greenish, growing
        else if (stage == 2) { bgColor = "#c0e0f0"; circleColor = "#2196F3"; } // Blueish, developed
        else if (stage == 3) { bgColor = "#f0d0c0"; circleColor = "#FF9800"; } // Orangish, mature
        else { bgColor = "#f0c0d0"; circleColor = "#F44336"; } // Reddish/other, advanced/special

        // Clamping radius to prevent excessively large SVGs
        circleRadius = Math.min(circleRadius, 100);

        // Add simple elements based on stats (example: dots for energy, lines for skill)
        string memory additionalElements = "";
        // Energy dots (up to 10 dots, scaling energy to 0-10 range)
        uint256 energyDots = Math.min(energy / 100, 10);
        for(uint i = 0; i < energyDots; i++) {
            additionalElements = string(abi.encodePacked(additionalElements,
                '<circle cx="', Strings.toString(70 + i*5), '" cy="30" r="2" fill="yellow"/>'
            ));
        }
        // Skill lines (up to 5 lines, scaling skill to 0-5 range)
        uint256 skillLines = Math.min(skill / 200, 5);
         for(uint i = 0; i < skillLines; i++) {
            additionalElements = string(abi.encodePacked(additionalElements,
                '<line x1="30" y1="', Strings.toString(70 + i*5), '" x2="70" y2="', Strings.toString(70 + i*5), '" stroke="purple" stroke-width="2"/>'
            ));
        }
        // Stress indicator (e.g., a red cross if stress is high)
        if (stress > 500) { // High stress threshold
             additionalElements = string(abi.encodePacked(additionalElements,
                '<line x1="40" y1="40" x2="60" y2="60" stroke="red" stroke-width="3"/>',
                '<line x1="60" y1="40" x2="40" y2="60" stroke="red" stroke-width="3"/>'
            ));
        }
        // Environment factor visual (e.g., a small shape based on factor)
        if (environmentFactor > 0) {
             string memory envShapeColor = environmentFactor > 100 ? "cyan" : "blue";
             additionalElements = string(abi.encodePacked(additionalElements,
                '<rect x="5" y="5" width="10" height="10" fill="', envShapeColor, '"/>'
            ));
        }


        // Basic SVG structure
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">',
                '<rect width="100%" height="100%" fill="', bgColor, '"/>',
                '<circle cx="50" cy="50" r="', Strings.toString(circleRadius), '" fill="', circleColor, '"/>',
                additionalElements, // Add dynamically generated elements
                '<text x="50" y="55" font-size="15" text-anchor="middle" fill="white">', Strings.toString(stage), '</text>',
            '</svg>'
        ));
    }


    // --- Minter Functions ---

    /// @notice Mints a new ChronoMorph token to the specified recipient.
    /// @param recipient The address to receive the new token.
    function mint(address recipient) public onlyRole(MINTER_ROLE) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(recipient, newTokenId);

        uint64 currentTime = uint64(block.timestamp);
        _morphStates[newTokenId] = MorphState({
            creationTime: currentTime,
            lastInteractionTime: currentTime,
            energy: 100, // Starting energy
            skill: 0,
            stress: 0,
            environmentFactor: 0,
            evolutionPoints: 0,
            currentStage: 0 // Starts at stage 0
        });

        // Initial state update to calculate points/stage based on starting stats
        _updateMorphState(newTokenId);

        emit MorphMinted(newTokenId, recipient, currentTime);
    }

    // --- Owner/Approved Interaction Functions ---

    /// @notice Increases the energy state of a ChronoMorph.
    /// @param tokenId The ID of the morph token.
    /// @param amount The amount representing 'feed' (can be conceptual or tied to a token).
    function feedMorph(uint256 tokenId, uint256 amount) public {
        _requireOwned(tokenId);
        MorphState storage morph = _morphStates[tokenId];

        // Require some minimum amount or payment if desired
        // require(amount > 0, "Feed amount must be > 0");
        // If tied to Ether/Token: payable function, transfer Ether/Token here
        // require(msg.value >= requiredFee, "Insufficient payment");

        morph.energy += amount * _feedMultiplier;

        _updateMorphState(tokenId);
        emit MorphFed(tokenId, amount, morph.energy);
    }

    /// @notice Increases the skill state and stress state of a ChronoMorph.
    /// @param tokenId The ID of the morph token.
    function trainMorph(uint256 tokenId) public {
        _requireOwned(tokenId);
        MorphState storage morph = _morphStates[tokenId];

        // Add cooldown for training?
        // require(block.timestamp >= morph.lastTrainingTime + trainingCooldown, "Training on cooldown");
        // morph.lastTrainingTime = block.timestamp;

        morph.skill += _trainSkillGain;
        morph.stress += _trainStressGain;

        _updateMorphState(tokenId);
        emit MorphTrained(tokenId, morph.skill, morph.stress);
    }

    /// @notice Decreases the stress state of a ChronoMorph.
    /// @param tokenId The ID of the morph token.
    function restMorph(uint256 tokenId) public {
         _requireOwned(tokenId);
        MorphState storage morph = _morphStates[tokenId];

        // Add cooldown for resting?

        if (morph.stress > _restStressReduction) {
            morph.stress -= _restStressReduction;
        } else {
            morph.stress = 0;
        }

        _updateMorphState(tokenId);
        emit MorphRested(tokenId, morph.stress);
    }

    /// @notice Forces an immediate state recalculation for the morph.
    /// Useful if time has passed but no other interaction has occurred,
    /// ensuring the evolution points/stage are up-to-date.
    /// @param tokenId The ID of the morph token.
    function triggerTemporalShift(uint256 tokenId) public {
        _requireOwned(tokenId);
        // No state changes occur *before* the update, it just forces the _updateMorphState calculation.
        _updateMorphState(tokenId);
        // Emit a specific event if needed, or rely on MorphStateUpdated
    }


    // --- Oracle Updater Function ---

    /// @notice Updates the environmental factor for a specific ChronoMorph.
    /// Requires the ORACLE_UPDATER_ROLE. Simulates an oracle pushing data per-token.
    /// @param tokenId The ID of the morph token.
    /// @param newFactor The new environmental factor value.
    function exposeToEnvironment(uint256 tokenId, uint256 newFactor) public onlyRole(ORACLE_UPDATER_ROLE) {
        _requireMinted(tokenId); // Ensure token exists
        MorphState storage morph = _morphStates[tokenId];

        // Could add validation for newFactor range

        morph.environmentFactor = newFactor;

        _updateMorphState(tokenId);
        emit EnvironmentUpdated(tokenId, newFactor);
    }

    // --- Admin/Configuration Functions ---

    /// @notice Sets the parameters used in the morph evolution formulas.
    /// Requires DEFAULT_ADMIN_ROLE.
    function setEvolutionParameters(
        uint256 timeSensitivityFactor,
        uint256 feedMultiplier,
        uint256 trainSkillGain,
        uint256 trainStressGain,
        uint256 restStressReduction
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _timeSensitivityFactor = timeSensitivityFactor;
        _feedMultiplier = feedMultiplier;
        _trainSkillGain = trainSkillGain;
        _trainStressGain = trainStressGain;
        _restStressReduction = restStressReduction;

        emit EvolutionParametersUpdated(
            _timeSensitivityFactor,
            _feedMultiplier,
            _trainSkillGain,
            _trainStressGain,
            _restStressReduction
        );
    }

    /// @notice Sets the evolution point thresholds required to reach each stage.
    /// Requires DEFAULT_ADMIN_ROLE. The length of the array determines the number of stages beyond Stage 0.
    /// @param thresholds An array of point thresholds. Should be strictly increasing.
    function setEvolutionThresholds(uint256[] memory thresholds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(thresholds.length > 0, "Thresholds cannot be empty");
        for(uint i = 1; i < thresholds.length; i++) {
            require(thresholds[i] > thresholds[i-1], "Thresholds must be increasing");
        }
        _evolutionThresholds = thresholds;
        emit EvolutionThresholdsUpdated(thresholds);
    }

     /// @notice Allows admin to withdraw collected Ether or specified ERC20 tokens.
     /// Useful if interaction functions like `feedMorph` require payment.
     /// Requires DEFAULT_ADMIN_ROLE.
     /// @param tokenAddress The address of the ERC20 token (address(0) for Ether).
    function withdrawFunds(address tokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(0)) {
            // Withdraw Ether
            uint256 balance = address(this).balance;
            require(balance > 0, "No Ether balance to withdraw");
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success, "Ether withdrawal failed");
        } else {
            // Withdraw ERC20
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "No ERC20 balance to withdraw");
            token.transfer(msg.sender, balance);
        }
    }

    // --- View Functions ---

    /// @notice Returns the detailed state of a specific ChronoMorph.
    /// @param tokenId The ID of the morph token.
    /// @return MorphState struct containing energy, skill, stress, env factor, points, stage.
    function getMorphState(uint256 tokenId) public view returns (MorphState memory) {
         _requireMinted(tokenId); // Ensure token exists
        // Note: This returns the stored state. For a view of *potentially* updated state
        // based on time elapsed since last interaction, use tokenURI or a dedicated view function.
        return _morphStates[tokenId];
    }

     /// @notice Returns the current evolution stage of a specific ChronoMorph.
     /// @param tokenId The ID of the morph token.
     /// @return The current evolution stage (uint8).
    function getEvolutionStage(uint256 tokenId) public view returns (uint8) {
        _requireMinted(tokenId);
        return _morphStates[tokenId].currentStage;
    }

     /// @notice Returns the raw SVG string generated for a specific ChronoMorph's state.
     /// Note: This generates based on the *current stored state* without considering
     /// time decay since last interaction. For time-sensitive view, use tokenURI.
     /// @param tokenId The ID of the morph token.
     /// @return The SVG string.
    function getMorphSVG(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);
        MorphState storage morph = _morphStates[tokenId];
        // Generate SVG based on the *current* state stored in storage
         return _generateSVG(morph.currentStage, morph.evolutionPoints, morph.energy, morph.skill, morph.stress, morph.environmentFactor);
    }

     /// @notice Returns the timestamp of the last interaction (or creation) for a morph.
     /// @param tokenId The ID of the morph token.
     /// @return The timestamp (uint64).
    function getLastInteractionTime(uint256 tokenId) public view returns (uint64) {
        _requireMinted(tokenId);
        return _morphStates[tokenId].lastInteractionTime;
    }

    /// @notice Returns the current evolution point thresholds.
    /// @return An array of point thresholds.
    function getEvolutionStageThresholds() public view returns (uint256[] memory) {
        return _evolutionThresholds;
    }

    /// @notice Returns the current evolution parameters.
    /// @return A tuple of configuration parameters.
    function getEvolutionParameters() public view returns (
        uint256 timeSensitivityFactor,
        uint256 feedMultiplier,
        uint256 trainSkillGain,
        uint256 trainStressGain,
        uint256 restStressReduction
    ) {
        return (
            _timeSensitivityFactor,
            _feedMultiplier,
            _trainSkillGain,
            _trainStressGain,
            _restStressReduction
        );
    }

    // Internal helper to check if a token ID has been minted
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "ChronoMorph: token not minted");
    }

     // Internal helper to check if sender is owner or approved
     function _requireOwned(uint256 tokenId) internal view {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoMorph: caller is not owner nor approved");
     }

     // The following functions are overrides required by Solidity.
     // We inherit from ERC721Enumerable, ERC721URIStorage, and AccessControl.
     // ERC721Enumerable requires _beforeTokenTransfer and _afterTokenTransfer.
     // ERC721URIStorage requires _burn.
     // AccessControl requires _setupRole.

     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
         internal
         override(ERC721Enumerable, ERC721)
     {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);
     }

     function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
         internal
         override(ERC721Enumerable, ERC721)
     {
         super._afterTokenTransfer(from, to, tokenId, batchSize);
         // Consider updating state here if transfers should also trigger state changes,
         // or if lastInteractionTime should reset on transfer.
         // For now, we rely on interaction functions or triggerTemporalShift.
     }

     function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
         super._burn(tokenId);
         delete _morphStates[tokenId]; // Clean up state data
     }

     // Initial role setup
     function _setupRole(bytes32 role, address account) internal override(AccessControl) {
         super._setupRole(role, account);
     }
}

// IERC20 interface for withdrawFunds
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
```

**Explanation of Advanced Concepts and Features:**

1.  **Dynamic Metadata (tokenURI Override):** Instead of returning a static JSON file, the `tokenURI` function is overridden. It calculates the current state (including time-based decay/growth *at the time of the call* for view purposes) and generates the SVG and JSON metadata *on-chain*. This ensures the NFT's appearance is always a reflection of its latest state.
2.  **On-chain State Management:** Each token ID has a dedicated `MorphState` struct stored in a mapping. This struct contains numerical parameters (`energy`, `skill`, `stress`, `environmentFactor`) that drive the evolution.
3.  **Evolution Logic (`_updateMorphState`):** This internal function is the heart of the evolution. It:
    *   Calculates elapsed time since the last update.
    *   Applies time-sensitive changes (e.g., stress increases, energy decreases).
    *   Calculates `evolutionPoints` based on a custom formula combining all state variables. This formula defines *how* the morph evolves.
    *   Compares `evolutionPoints` against configurable `_evolutionThresholds` to determine the `currentStage`.
    *   Updates the stored state and `lastInteractionTime`.
4.  **Time Sensitivity:** The `_updateMorphState` function explicitly includes `block.timestamp` to calculate elapsed time and apply effects scaled by `_timeSensitivityFactor`. This makes the morph's state dynamic even without user interaction.
5.  **User Interaction Functions (`feedMorph`, `trainMorph`, `restMorph`):** These functions allow the owner (or an approved address) to spend gas and call the contract to modify the core state variables (`energy`, `skill`, `stress`). Each call triggers `_updateMorphState`, potentially causing the morph to evolve.
6.  **Simulated Oracle (`exposeToEnvironment`):** This function allows an address with the `ORACLE_UPDATER_ROLE` to push external data (`newFactor`) into a specific token's state. This simulates an oracle feeding information (like real-world weather, market prices, game scores) that influences the morph's evolution points.
7.  **On-chain SVG Generation (`_generateSVG`):** A simple internal pure function generates an SVG string based on the calculated state parameters (stage, points, stats). This SVG is then base64 encoded and embedded directly into the `tokenURI` output as a data URI image. *Note: Complex SVGs can be very gas-intensive.*
8.  **Role-Based Access Control:** Using OpenZeppelin's `AccessControl`, we define distinct roles (`MINTER_ROLE`, `ORACLE_UPDATER_ROLE`, `DEFAULT_ADMIN_ROLE`) with specific permissions. This provides a secure and structured way to manage who can perform sensitive actions like minting, updating environment data, or changing contract configurations.
9.  **Configurability (Admin Functions):** Functions like `setEvolutionParameters` and `setEvolutionThresholds` allow the contract admin (or an authorized DAO) to tune the evolution mechanics *after* deployment. This makes the contract more flexible and adaptable without requiring a full upgrade (if designed with upgradability patterns like proxies, though not included here to keep the example focused).
10. **Standard Compliance:** Inherits and correctly implements ERC721, ERC721Enumerable (for explorer compatibility), and ERC165 (via AccessControl).

This ChronoMorph contract provides a robust example of a dynamic, interactive NFT system where the asset's properties and appearance are intrinsically linked to on-chain state, time, user actions, and external data feeds, going beyond static image NFTs.