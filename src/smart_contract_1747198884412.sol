Okay, here is a Solidity smart contract concept focusing on dynamic, attribute-driven NFTs with complex crafting ("Alchemy") influenced by an on-chain "environment" that users can potentially influence. It combines elements of dynamic NFTs, crafting/simulation, and environmental interaction in a novel way.

It's important to note that simulating complex physics or truly unpredictable outcomes perfectly on a blockchain is difficult and costly. This contract uses numerical attributes, weighted outcomes, and pseudo-randomness based on transaction data (`keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, inputIds, environmentalState))` - *note: block.difficulty is deprecated/0 on PoS, block.timestamp and msg.sender/inputIds are better inputs for pseudo-randomness, still predictable to miners/validators*), which is a standard approach for on-chain probabilistic events. For truly secure randomness, a VRF (like Chainlink VRF) would be needed, adding more complexity and dependencies.

This contract also uses ERC721Enumerable to easily list tokens by owner, which adds complexity and gas cost compared to just ERC721, but is useful for demonstrating the system.

**Concept: QuantumAlchemy**

A system managing two types of dynamic NFTs: "Essences" and "Quantum Artifacts". Essences have mutable numerical attributes (Energy, Stability, Purity, Chaos). Users can combine Essences in a "Quantum Reactor" (`performQuantumAlchemy`). The outcome (success/fail, new Essence, specific Artifact, environmental shift) is determined by the combined attributes of the inputs, the current contract-wide "Environmental State", and internal configuration parameters. Quantum Artifacts are rare outputs that can possess unique "Influence" attributes that *affect future alchemy outcomes* or potentially the environment when used. Users can also interact with Essences/Artifacts or the environment in specific ways (`imbueEssenceWithEnergy`, `triggerEnvironmentalShift`).

**Outline:**

1.  **Contract Definition:** Inherits ERC721Enumerable and Ownable.
2.  **Data Structures:**
    *   `EssenceAttributes`: Struct for Energy, Stability, Purity, Chaos.
    *   `ArtifactData`: Struct for Type, Influence Magnitude, Influence Type.
    *   `AlchemyConfig`: Struct for various parameters controlling alchemy outcomes, state shifts, decay rates, etc.
    *   `TokenData`: Struct to track token type (Essence/Artifact), creation time, last alchemy time.
3.  **State Variables:**
    *   Mappings to store `EssenceAttributes`, `ArtifactData`, `TokenData` by `tokenId`.
    *   `_currentTokenId`: Counter for total minted tokens.
    *   `_tokenIsEssence`: Mapping `tokenId => bool` for quick type check.
    *   `_environmentalState`: Numerical state variable influencing alchemy outcomes.
    *   `_alchemyConfig`: Instance of `AlchemyConfig`.
    *   `_userAlchemyStats`: Mapping `address => struct { uint success; uint fail; }`.
    *   `_feeRecipient`: Address to receive protocol fees.
    *   `_feeAmount`: Amount of ETH required for alchemy.
    *   `_latestAlchemyResult`: Stores details of the last successful reaction.
4.  **Events:**
    *   `AlchemySuccess`: Log successful reactions (inputs, outputs, outcome type).
    *   `AlchemyFailed`: Log failed reactions (inputs, reason).
    *   `EnvironmentalShift`: Log changes to the environmental state.
    *   `AttributesChanged`: Log attribute changes for a token.
    *   `ConfigUpdated`: Log parameter changes.
    *   `FeeWithdrawal`: Log fee withdrawals.
5.  **Modifiers:**
    *   `onlyEssence`: Restrict function to Essence tokens.
    *   `onlyArtifact`: Restrict function to Artifact tokens.
    *   `onlyAliveToken`: Ensure token exists.
6.  **Functions (Categorized):**
    *   **ERC721 Standard (8):** `balanceOf`, `ownerOf`, `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `tokenURI`. (Inherited/Standard implementation)
    *   **Minting & Creation (Admin Only) (2):** `mintInitialEssences`, `mintInitialArtifacts`.
    *   **Token Information & State (View) (6):** `getAttributes`, `getAttribute`, `getArtifactData`, `getTokenType`, `getTokenCreationTime`, `getDecayFactor`.
    *   **Core Alchemy Logic (2):** `performQuantumAlchemy`, `simulateAlchemyOutcome`.
    *   **Environmental Interaction (2):** `getEnvironmentalState`, `triggerEnvironmentalShift`.
    *   **Token Interaction (2):** `imbueEssenceWithEnergy`, `attuneArtifact`.
    *   **Configuration & Fees (Admin) (2):** `setAlchemyConfigParam`, `withdrawFees`.
    *   **Query & Stats (View) (3):** `getUserAlchemyStats`, `getTotalTokensMinted`, `getLatestSuccessfulAlchemyResult`.
    *   **Internal Helpers (Used by other functions):** `_burn`, `_mint`, `_calculateOutcome`, `_applyDecay`, `_updateEnvironmentalState`, `_calculateAttributeInfluence`.

**Function Summary:**

1.  `constructor(string name, string symbol, address initialFeeRecipient)`: Initializes the contract, ERC721, Ownable, fee recipient.
2.  `balanceOf(address owner) public view override returns (uint256)`: Returns the number of tokens owned by an address (ERC721).
3.  `ownerOf(uint256 tokenId) public view override returns (address)`: Returns the owner of a token (ERC721).
4.  `transferFrom(address from, address to, uint256 tokenId) public override`: Transfers ownership of a token (ERC721).
5.  `approve(address to, uint256 tokenId) public override`: Approves an address to manage a token (ERC721).
6.  `getApproved(uint256 tokenId) public view override returns (address)`: Gets the approved address for a token (ERC721).
7.  `setApprovalForAll(address operator, bool approved) public override`: Sets approval for an operator for all tokens (ERC721).
8.  `isApprovedForAll(address owner, address operator) public view override returns (bool)`: Checks if an operator is approved for all tokens (ERC721).
9.  `tokenURI(uint256 tokenId) public view override returns (string)`: Returns the metadata URI for a token (ERC721). *Placeholder implementation.*
10. `totalSupply() public view override returns (uint256)`: Returns the total number of tokens in existence (ERC721Enumerable).
11. `tokenByIndex(uint256 index) public view override returns (uint256)`: Returns the token ID at a given index (ERC721Enumerable).
12. `tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256)`: Returns the token ID at a given index for an owner (ERC721Enumerable).
13. `mintInitialEssences(address[] recipients, uint256[] energies, uint256[] stabilities, uint256[] purities, uint256[] chaoses) external onlyOwner`: Allows admin to mint initial Essence tokens with specified attributes to multiple recipients.
14. `mintInitialArtifacts(address[] recipients, uint256[] artifactTypes, uint256[] influenceMagnitudes) external onlyOwner`: Allows admin to mint initial Artifact tokens with specified data to multiple recipients.
15. `getAttributes(uint256 tokenId) public view onlyEssence onlyAliveToken returns (EssenceAttributes memory)`: Returns the current attributes of an Essence token, adjusted for decay.
16. `getAttribute(uint256 tokenId, string memory attributeName) public view onlyEssence onlyAliveToken returns (uint256)`: Returns a specific attribute of an Essence token by name.
17. `getArtifactData(uint256 tokenId) public view onlyArtifact onlyAliveToken returns (ArtifactData memory)`: Returns the data associated with an Artifact token.
18. `getTokenType(uint256 tokenId) public view returns (TokenType)`: Returns whether the token is an Essence, Artifact, or Invalid.
19. `getTokenCreationTime(uint256 tokenId) public view onlyAliveToken returns (uint256)`: Returns the timestamp when a token was created.
20. `getDecayFactor(uint256 tokenId) public view onlyEssence onlyAliveToken returns (uint256)`: Calculates and returns the current decay factor for an Essence based on time.
21. `getEnvironmentalState() public view returns (uint256)`: Returns the current value of the global environmental state.
22. `getUserAlchemyStats(address user) public view returns (uint256 success, uint256 fail)`: Returns the number of successful and failed alchemies for a user.
23. `getTotalTokensMinted() public view returns (uint256)`: Returns the total count of tokens minted.
24. `getLatestSuccessfulAlchemyResult() public view returns (uint256[] memory inputTokenIds, uint256[] memory outputTokenIds, uint256 outcomeType, uint256 timestamp)`: Returns details about the most recent successful alchemy reaction.
25. `setAlchemyConfigParam(AlchemyConfig memory newConfig) external onlyOwner`: Allows admin to update the global alchemy configuration parameters.
26. `withdrawFees() external onlyOwner`: Allows admin to withdraw collected ETH fees.
27. `performQuantumAlchemy(uint256[] calldata inputTokenIds) external payable`: The core function. Consumes input Essences/Artifacts, calculates outcomes based on combined attributes, environment, and config, potentially mints new tokens or shifts the environment. Requires a fee.
28. `simulateAlchemyOutcome(uint256[] calldata inputTokenIds) external view returns (SimulatedOutcome memory)`: A view function to simulate the potential outcome of an alchemy reaction without changing state. Returns potential outputs and state changes.
29. `triggerEnvironmentalShift(uint256 energyInput) external payable`: Allows a user to influence the environmental state by providing "energy" (e.g., ETH or burning a high-energy Essence).
30. `imbueEssenceWithEnergy(uint256 essenceId) external payable onlyEssence onlyAliveToken`: Allows a user to permanently increase an Essence's Energy attribute by paying ETH.
31. `attuneArtifact(uint256 artifactId, int256 adjustment) external payable onlyArtifact onlyAliveToken`: Allows a user to slightly adjust an Artifact's influence magnitude within a range, potentially requiring a fee or specific conditions (not fully implemented complex conditions here).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Less critical in 0.8+, but good practice for clarity in calculations
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline ---
// 1. Contract Definition: Inherits ERC721Enumerable, Ownable.
// 2. Data Structures: EssenceAttributes, ArtifactData, AlchemyConfig, TokenData, SimulatedOutcome.
// 3. State Variables: Token mappings, Counters, Environmental State, Alchemy Config, Fee State, Stats, Latest Result.
// 4. Events: AlchemySuccess, AlchemyFailed, EnvironmentalShift, AttributesChanged, ConfigUpdated, FeeWithdrawal.
// 5. Modifiers: onlyEssence, onlyArtifact, onlyAliveToken.
// 6. Functions (Categorized):
//    - ERC721 Standard (8): balanceOf, ownerOf, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll, tokenURI.
//    - ERC721Enumerable Standard (3): totalSupply, tokenByIndex, tokenOfOwnerByIndex.
//    - Minting & Creation (Admin Only) (2): mintInitialEssences, mintInitialArtifacts.
//    - Token Information & State (View) (6): getAttributes, getAttribute, getArtifactData, getTokenType, getTokenCreationTime, getDecayFactor.
//    - Core Alchemy Logic (2): performQuantumAlchemy, simulateAlchemyOutcome.
//    - Environmental Interaction (2): getEnvironmentalState, triggerEnvironmentalShift.
//    - Token Interaction (2): imbueEssenceWithEnergy, attuneArtifact.
//    - Configuration & Fees (Admin) (2): setAlchemyConfigParam, withdrawFees.
//    - Query & Stats (View) (4): getUserAlchemyStats, getTotalTokensMinted, getLatestSuccessfulAlchemyResult, getAlchemyConfig.
//    - Internal Helpers (Used by other functions).

// --- Function Summary ---
// 1. constructor: Initializes the contract, ERC721, Ownable, fee recipient.
// 2. balanceOf: Returns token count for owner (ERC721).
// 3. ownerOf: Returns owner of token (ERC721).
// 4. transferFrom: Transfers token ownership (ERC721).
// 5. approve: Approves address for token (ERC721).
// 6. getApproved: Gets approved address (ERC721).
// 7. setApprovalForAll: Sets operator approval (ERC721).
// 8. isApprovedForAll: Checks operator approval (ERC721).
// 9. tokenURI: Returns token metadata URI (ERC721).
// 10. totalSupply: Returns total tokens (ERC721Enumerable).
// 11. tokenByIndex: Returns token ID by index (ERC721Enumerable).
// 12. tokenOfOwnerByIndex: Returns token ID by owner index (ERC721Enumerable).
// 13. mintInitialEssences: Admin mints initial Essences.
// 14. mintInitialArtifacts: Admin mints initial Artifacts.
// 15. getAttributes: Gets Essence attributes, adjusted for decay.
// 16. getAttribute: Gets a specific Essence attribute by name.
// 17. getArtifactData: Gets Artifact specific data.
// 18. getTokenType: Returns token type (Essence/Artifact/Invalid).
// 19. getTokenCreationTime: Returns token creation timestamp.
// 20. getDecayFactor: Calculates Essence decay factor.
// 21. getEnvironmentalState: Gets current environmental state.
// 22. getUserAlchemyStats: Gets user's alchemy success/fail count.
// 23. getTotalTokensMinted: Gets total tokens minted.
// 24. getLatestSuccessfulAlchemyResult: Gets details of the last successful alchemy.
// 25. setAlchemyConfigParam: Admin updates alchemy configuration.
// 26. withdrawFees: Admin withdraws collected fees.
// 27. performQuantumAlchemy: Core function: burns inputs, calculates complex outcome based on inputs/environment/config, mints output(s) or shifts environment, requires fee.
// 28. simulateAlchemyOutcome: View function to predict outcome of performQuantumAlchemy.
// 29. triggerEnvironmentalShift: User pays/burns to influence the environmental state.
// 30. imbueEssenceWithEnergy: User pays/burns to increase Essence Energy attribute.
// 31. attuneArtifact: User pays/burns/meets condition to slightly adjust Artifact influence.
// 32. getAlchemyConfig: View current alchemy configuration.

contract QuantumAlchemy is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _currentTokenId;

    enum TokenType { Invalid, Essence, Artifact }

    struct EssenceAttributes {
        uint256 energy;
        uint256 stability;
        uint256 purity;
        uint256 chaos;
    }

    struct ArtifactData {
        uint256 artifactType; // Enum or ID representing type (e.g., 1: Orb of Influence, 2: Stabilizer Node)
        uint256 influenceMagnitude; // How strong its effect is
        uint256 influenceType; // What aspect it influences (e.g., 1: Alchemy Success, 2: Environmental Shift)
        // Could add more complex influence parameters here
    }

    struct AlchemyConfig {
        uint256 baseAlchemyFee; // ETH required per reaction
        uint256 environmentalShiftFee; // ETH required to trigger shift
        uint256 energyImbueFee; // ETH required to imbue energy
        uint256 attuneArtifactFee; // ETH required to attune artifact
        uint256 baseDecayRate; // How fast essences decay over time
        uint256 maxEssenceAttribute; // Max value for an essence attribute
        uint256 maxEnvironmentalState; // Max value for environmental state
        uint256 environmentalShiftMagnitude; // How much env state changes per trigger
        // Thresholds and probabilities for outcomes based on combined attributes and environment
        uint256 essenceToArtifactThreshold;
        uint256 environmentalShiftThreshold;
        uint256 newEssenceMinAttributes; // Min attributes for newly minted essence
        uint256 newEssenceMaxAttributes; // Max attributes for newly minted essence
        uint256 artifactMinInfluence;
        uint256 artifactMaxInfluence;
        uint256 maxArtifactInfluenceAdjustment; // Max attunement adjustment
        // Add more config parameters as complexity grows
    }

    struct TokenData {
        TokenType tokenType;
        uint256 creationTime;
        uint256 lastAlchemyTime; // Last time involved in alchemy
    }

    struct UserAlchemyStats {
        uint256 success;
        uint256 fail;
    }

    struct AlchemyResult {
        uint256[] inputTokenIds;
        uint256[] outputTokenIds; // New tokens minted
        uint256 outcomeType; // Enum: 1=NewEssence, 2=NewArtifact, 3=EnvShift, 4=NoOutput
        uint256 timestamp;
    }

    struct SimulatedOutcome {
        uint256 potentialOutcomeType;
        string description;
        EssenceAttributes potentialNewEssenceAttributes;
        ArtifactData potentialNewArtifactData;
        uint256 potentialEnvironmentalStateChange;
        string warning; // e.g., "Outcome is probabilistic"
    }

    // --- State Variables ---
    mapping(uint256 => EssenceAttributes) private _essenceAttributes;
    mapping(uint256 => ArtifactData) private _artifactData;
    mapping(uint256 => TokenData) private _tokenData;

    mapping(address => UserAlchemyStats) private _userAlchemyStats;

    uint256 private _environmentalState;
    AlchemyConfig private _alchemyConfig;

    address payable private _feeRecipient;
    uint256 private _totalCollectedFees;

    AlchemyResult private _latestSuccessfulAlchemyResult;

    // --- Events ---
    event AlchemySuccess(address indexed user, uint256[] inputTokenIds, uint256[] outputTokenIds, uint256 outcomeType);
    event AlchemyFailed(address indexed user, uint256[] inputTokenIds, string reason);
    event EnvironmentalShift(address indexed user, uint256 oldState, uint256 newState, uint256 shiftMagnitude);
    event AttributesChanged(uint256 indexed tokenId, EssenceAttributes oldAttributes, EssenceAttributes newAttributes);
    event ConfigUpdated(AlchemyConfig newConfig);
    event FeeWithdrawal(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyEssence(uint256 tokenId) {
        require(_tokenData[tokenId].tokenType == TokenType.Essence, "Not an Essence token");
        _;
    }

    modifier onlyArtifact(uint256 tokenId) {
        require(_tokenData[tokenId].tokenType == TokenType.Artifact, "Not an Artifact token");
        _;
    }

    modifier onlyAliveToken(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address payable initialFeeRecipient)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _feeRecipient = initialFeeRecipient;
        _environmentalState = 50; // Initial state (e.g., 0-100 scale)

        // Set initial default config
        _alchemyConfig = AlchemyConfig({
            baseAlchemyFee: 0.01 ether,
            environmentalShiftFee: 0.05 ether,
            energyImbueFee: 0.005 ether,
            attuneArtifactFee: 0.005 ether,
            baseDecayRate: 1, // 1% decay per day (example)
            maxEssenceAttribute: 1000,
            maxEnvironmentalState: 100,
            environmentalShiftMagnitude: 10,
            essenceToArtifactThreshold: 800, // Combined attribute threshold
            environmentalShiftThreshold: 900, // Combined attribute threshold
            newEssenceMinAttributes: 50,
            newEssenceMaxAttributes: 500,
            artifactMinInfluence: 1,
            artifactMaxInfluence: 100,
            maxArtifactInfluenceAdjustment: 5
        });
    }

    // --- ERC721 & Enumerable Implementations (Mostly inherited) ---
    // tokenURI requires custom implementation
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Placeholder: In a real DApp, this would point to a metadata server
        // or generate a data URI with token attributes.
        string memory baseURI = "ipfs://YOUR_METADATA_BASE_URI/";
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // ERC721Enumerable functions totalSupply, tokenByIndex, tokenOfOwnerByIndex are inherited

    // --- Internal Token Management ---
    function _mint(address to, uint256 tokenId, TokenType tokenType, EssenceAttributes memory attributes, ArtifactData memory artifact) internal {
        _safeMint(to, tokenId);
        _tokenData[tokenId] = TokenData({
            tokenType: tokenType,
            creationTime: block.timestamp,
            lastAlchemyTime: 0 // Not used in alchemy initially
        });
        if (tokenType == TokenType.Essence) {
            _essenceAttributes[tokenId] = attributes;
             // Cap attributes at max
            _essenceAttributes[tokenId].energy = Math.min(attributes.energy, _alchemyConfig.maxEssenceAttribute);
            _essenceAttributes[tokenId].stability = Math.min(attributes.stability, _alchemyConfig.maxEssenceAttribute);
            _essenceAttributes[tokenId].purity = Math.min(attributes.purity, _alchemyConfig.maxEssenceAttribute);
            _essenceAttributes[tokenId].chaos = Math.min(attributes.chaos, _alchemyConfig.maxEssenceAttribute);
        } else if (tokenType == TokenType.Artifact) {
            _artifactData[tokenId] = artifact;
             // Cap influence
            _artifactData[tokenId].influenceMagnitude = Math.min(artifact.influenceMagnitude, _alchemyConfig.artifactMaxInfluence);
        }
    }

    function _burn(uint256 tokenId) internal {
        require(_exists(tokenId), "Token does not exist");
        // Clean up mappings explicitly to save gas on deletion
        if (_tokenData[tokenId].tokenType == TokenType.Essence) {
            delete _essenceAttributes[tokenId];
        } else if (_tokenData[tokenId].tokenType == TokenType.Artifact) {
            delete _artifactData[tokenId];
        }
        delete _tokenData[tokenId];
        _burn(tokenId); // Call ERC721 burn
    }


    // --- Minting & Creation (Admin Only) ---
    function mintInitialEssences(
        address[] calldata recipients,
        uint256[] calldata energies,
        uint256[] calldata stabilities,
        uint256[] calldata purities,
        uint256[] calldata chaoses
    ) external onlyOwner {
        require(recipients.length == energies.length && recipients.length == stabilities.length &&
                recipients.length == purities.length && recipients.length == chaoses.length,
                "Input array lengths must match");

        for (uint256 i = 0; i < recipients.length; i++) {
            _currentTokenId.increment();
            uint256 newItemId = _currentTokenId.current();
            EssenceAttributes memory attrs = EssenceAttributes(energies[i], stabilities[i], purities[i], chaoses[i]);
            _mint(recipients[i], newItemId, TokenType.Essence, attrs, ArtifactData(0,0,0)); // Pass default artifact data
        }
    }

    function mintInitialArtifacts(
        address[] calldata recipients,
        uint256[] calldata artifactTypes,
        uint256[] calldata influenceMagnitudes
    ) external onlyOwner {
        require(recipients.length == artifactTypes.length && recipients.length == influenceMagnitudes.length,
                "Input array lengths must match");

        for (uint256 i = 0; i < recipients.length; i++) {
            _currentTokenId.increment();
            uint256 newItemId = _currentTokenId.current();
             ArtifactData memory artifact = ArtifactData(artifactTypes[i], influenceMagnitudes[i], 0); // InfluenceType placeholder
            _mint(recipients[i], newItemId, TokenType.Artifact, EssenceAttributes(0,0,0,0), artifact); // Pass default essence data
        }
    }

    // --- Token Information & State (View) ---
    function getAttributes(uint256 tokenId) public view onlyEssence onlyAliveToken returns (EssenceAttributes memory) {
        EssenceAttributes memory currentAttrs = _essenceAttributes[tokenId];
        uint256 decayFactor = getDecayFactor(tokenId);

        // Apply decay (simple linear example)
        currentAttrs.energy = currentAttrs.energy.mul(100 - decayFactor).div(100);
        currentAttrs.stability = currentAttrs.stability.mul(100 - decayFactor).div(100);
        currentAttrs.purity = currentAttrs.purity.mul(100 - decayFactor).div(100);
        currentAttrs.chaos = currentAttrs.chaos.mul(100 - decayFactor).div(100);

        return currentAttrs;
    }

    function getAttribute(uint256 tokenId, string memory attributeName) public view onlyEssence onlyAliveToken returns (uint256) {
        EssenceAttributes memory attrs = getAttributes(tokenId); // Get decay-adjusted attributes
        if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("energy"))) {
            return attrs.energy;
        } else if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("stability"))) {
            return attrs.stability;
        } else if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("purity"))) {
            return attrs.purity;
        } else if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("chaos"))) {
            return attrs.chaos;
        }
        revert("Invalid attribute name");
    }

    function getArtifactData(uint256 tokenId) public view onlyArtifact onlyAliveToken returns (ArtifactData memory) {
        return _artifactData[tokenId];
    }

    function getTokenType(uint256 tokenId) public view returns (TokenType) {
        if (!_exists(tokenId)) {
            return TokenType.Invalid;
        }
        return _tokenData[tokenId].tokenType;
    }

     function getTokenCreationTime(uint256 tokenId) public view onlyAliveToken returns (uint256) {
        return _tokenData[tokenId].creationTime;
    }

    // Simple time-based decay example (percentage per day)
    function getDecayFactor(uint256 tokenId) public view onlyEssence onlyAliveToken returns (uint256) {
        uint256 timeSinceCreation = block.timestamp.sub(_tokenData[tokenId].creationTime);
        uint256 daysSinceCreation = timeSinceCreation.div(1 days);
        uint256 decay = daysSinceCreation.mul(_alchemyConfig.baseDecayRate);
        return Math.min(decay, 100); // Cap decay at 100%
    }

    // --- Environmental Interaction ---
    function getEnvironmentalState() public view returns (uint256) {
        return _environmentalState;
    }

    function triggerEnvironmentalShift(uint256 energyInput) external payable {
        require(msg.value >= _alchemyConfig.environmentalShiftFee, "Insufficient fee");
        // Simulate shift based on input energy and current state
        // More complex logic could involve burning a specific high-energy Essence token instead of ETH
        uint256 shiftAmount = energyInput.div(10); // Example: energy input influences magnitude
        uint256 newEnvironmentalState = _environmentalState.add(shiftAmount).sub(_alchemyConfig.environmentalShiftMagnitude); // Example calculation
        _environmentalState = Math.max(0, newEnvironmentalState);
        _environmentalState = Math.min(_environmentalState, _alchemyConfig.maxEnvironmentalState);

        _totalCollectedFees = _totalCollectedFees.add(msg.value);
        emit EnvironmentalShift(msg.sender, _environmentalState.sub(newEnvironmentalState.sub(_environmentalState)), _environmentalState, shiftAmount);
    }

    // --- Token Interaction ---
    function imbueEssenceWithEnergy(uint256 essenceId) external payable onlyEssence onlyAliveToken {
        require(ownerOf(essenceId) == msg.sender, "Not your Essence");
        require(msg.value >= _alchemyConfig.energyImbueFee, "Insufficient fee");

        EssenceAttributes memory oldAttrs = _essenceAttributes[essenceId];
        EssenceAttributes memory newAttrs = oldAttrs;
        newAttrs.energy = Math.min(oldAttrs.energy.add(msg.value.div(10000000000000)), _alchemyConfig.maxEssenceAttribute); // Example: 0.001 ETH adds 10 Energy

        _essenceAttributes[essenceId] = newAttrs;
        _totalCollectedFees = _totalCollectedFees.add(msg.value);

        emit AttributesChanged(essenceId, oldAttrs, newAttrs);
    }

     function attuneArtifact(uint256 artifactId, int256 adjustment) external payable onlyArtifact onlyAliveToken {
        require(ownerOf(artifactId) == msg.sender, "Not your Artifact");
        require(msg.value >= _alchemyConfig.attuneArtifactFee, "Insufficient fee");
        require(adjustment <= int256(_alchemyConfig.maxArtifactInfluenceAdjustment) && adjustment >= int256(-_alchemyConfig.maxArtifactInfluenceAdjustment), "Adjustment out of range");

        ArtifactData memory oldData = _artifactData[artifactId];
        ArtifactData memory newData = oldData;

        int256 currentInfluence = int256(oldData.influenceMagnitude);
        int256 adjustedInfluence = currentInfluence.add(adjustment);

        newData.influenceMagnitude = uint256(Math.max(0, adjustedInfluence)); // Ensure non-negative
        newData.influenceMagnitude = Math.min(newData.influenceMagnitude, _alchemyConfig.artifactMaxInfluence); // Cap at max

        _artifactData[artifactId] = newData;
         _totalCollectedFees = _totalCollectedFees.add(msg.value);

        // Note: AttributesChanged event is for Essences. Might need a new event for ArtifactData changes.
         emit ConfigUpdated(_alchemyConfig); // Re-use ConfigUpdated for simplicity, or create ArtifactDataChanged
    }


    // --- Query & Stats (View) ---
    function getUserAlchemyStats(address user) public view returns (uint256 success, uint256 fail) {
        return (_userAlchemyStats[user].success, _userAlchemyStats[user].fail);
    }

    function getTotalTokensMinted() public view returns (uint256) {
        return _currentTokenId.current();
    }

    function getLatestSuccessfulAlchemyResult() public view returns (uint256[] memory inputTokenIds, uint256[] memory outputTokenIds, uint256 outcomeType, uint256 timestamp) {
        return (_latestSuccessfulAlchemyResult.inputTokenIds, _latestSuccessfulAlchemyResult.outputTokenIds, _latestSuccessfulAlchemyResult.outcomeType, _latestSuccessfulAlchemyResult.timestamp);
    }

     function getAlchemyConfig() public view returns (AlchemyConfig memory) {
        return _alchemyConfig;
    }

    // --- Configuration & Fees (Admin) ---
    function setAlchemyConfigParam(AlchemyConfig memory newConfig) external onlyOwner {
        _alchemyConfig = newConfig;
        emit ConfigUpdated(newConfig);
    }

    function withdrawFees() external onlyOwner {
        uint256 amount = _totalCollectedFees;
        _totalCollectedFees = 0;
        (bool success,) = _feeRecipient.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeeWithdrawal(_feeRecipient, amount);
    }


    // --- Core Alchemy Logic ---

    // Helper to calculate combined attributes from input Essences
    function _calculateCombinedAttributes(uint256[] memory inputTokenIds) internal view returns (EssenceAttributes memory combined) {
        combined = EssenceAttributes(0, 0, 0, 0);
        uint256 essenceCount = 0;

        for (uint256 i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            if (_exists(tokenId) && _tokenData[tokenId].tokenType == TokenType.Essence) {
                essenceCount++;
                EssenceAttributes memory attrs = getAttributes(tokenId); // Use decay-adjusted attributes
                combined.energy = combined.energy.add(attrs.energy);
                combined.stability = combined.stability.add(attrs.stability);
                combined.purity = combined.purity.add(attrs.purity);
                combined.chaos = combined.chaos.add(attrs.chaos);
            }
             // Artifact influence is handled separately in outcome calculation
        }

        // Simple example: Average or Weighted Average
        if (essenceCount > 0) {
            combined.energy = combined.energy.div(essenceCount);
            combined.stability = combined.stability.div(essenceCount);
            combined.purity = combined.purity.div(essenceCount);
            combined.chaos = combined.chaos.div(essenceCount);
        }
        // More complex averaging or weighted sum based on input count/types could be here
    }

     // Helper to calculate total artifact influence on alchemy
     function _calculateAttributeInfluence(uint256[] memory inputTokenIds, uint256 targetInfluenceType) internal view returns (int256 totalInfluence) {
        totalInfluence = 0;
         for (uint256 i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
             if (_exists(tokenId) && _tokenData[tokenId].tokenType == TokenType.Artifact) {
                ArtifactData memory artifact = _artifactData[tokenId];
                if (artifact.influenceType == targetInfluenceType) {
                    // Example: Positive influence adds, negative (if allowed) subtracts
                    totalInfluence = totalInfluence.add(int256(artifact.influenceMagnitude));
                }
                 // Could add influence based on artifacts *in the user's wallet*, not just inputs
                 // This would require iterating owned tokens or tracking user's artifact influence separately
            }
         }
     }


    // Main Alchemy function
    function performQuantumAlchemy(uint256[] calldata inputTokenIds) external payable {
        require(inputTokenIds.length >= 2, "Requires at least 2 input tokens");
        require(msg.value >= _alchemyConfig.baseAlchemyFee, "Insufficient alchemy fee");

        // Verify ownership and burn inputs
        for (uint256 i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            require(_exists(tokenId), string(abi.encodePacked("Input token does not exist: ", Strings.toString(tokenId))));
            require(ownerOf(tokenId) == msg.sender, string(abi.encodePacked("Input token not owned by sender: ", Strings.toString(tokenId))));
            // Check if any artifact inputs influence *this* process or environment
             // Artifact influence is calculated, inputs are still burned in this basic version
            _burn(tokenId);
        }

        _totalCollectedFees = _totalCollectedFees.add(msg.value);

        // Calculate combined attributes from Essence inputs
        EssenceAttributes memory combinedAttrs = _calculateCombinedAttributes(inputTokenIds);

        // Calculate Artifact influence on the outcome
        int256 alchemySuccessInfluence = _calculateAttributeInfluence(inputTokenIds, 1); // Assuming 1 is Alchemy Success influence type
        int256 envShiftInfluence = _calculateAttributeInfluence(inputTokenIds, 2); // Assuming 2 is Env Shift influence type


        // Determine outcome based on combined attributes, environment, config, and randomness
        uint256 outcomeSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, inputTokenIds, _environmentalState)));
        uint256 randomFactor = outcomeSeed % 1000; // Simple pseudo-random factor (0-999)

        uint256 totalAttributeSum = combinedAttrs.energy.add(combinedAttrs.stability).add(combinedAttrs.purity).add(combinedAttrs.chaos);

        uint256 outcomeType = 4; // Default: No Output (failure/dissipation)
        uint256[] memory outputTokenIds = new uint256[](0);
        EssenceAttributes memory newEssenceAttrs = EssenceAttributes(0,0,0,0);
        ArtifactData memory newArtifactData = ArtifactData(0,0,0);
        bool envShiftTriggered = false;

        // --- Outcome Logic (Example - highly simplified) ---
        // Introduce probabilities and thresholds influenced by combined attributes, environment, and random factor

        uint256 successProbability = totalAttributeSum.mul(100).div(_alchemyConfig.maxEssenceAttribute.mul(4)); // Higher sum = higher success chance
        successProbability = successProbability.add(uint256(Math.max(-50, Math.min(50, envShiftInfluence)))); // Artifacts can shift probability
        successProbability = Math.min(successProbability, 95); // Cap probability

        if (randomFactor < successProbability.mul(10)) { // 1000 total, so successProbability * 10
             // Potential Success - Now determine *what* kind of success
            if (totalAttributeSum >= _alchemyConfig.environmentalShiftThreshold && randomFactor % 100 < 30 + uint256(Math.max(-20, Math.min(20, envShiftInfluence)))) { // Higher threshold + chance can trigger env shift
                outcomeType = 3; // Environmental Shift
                envShiftTriggered = true;
            } else if (totalAttributeSum >= _alchemyConfig.essenceToArtifactThreshold && randomFactor % 100 < 20 + uint256(Math.max(-10, Math.min(10, alchemySuccessInfluence)))) { // Higher threshold + chance can yield Artifact
                outcomeType = 2; // New Artifact
                 // Determine artifact properties based on input attributes
                newArtifactData = ArtifactData({
                    artifactType: (combinedAttrs.purity > combinedAttrs.chaos ? 1 : 2), // Example: Purity > Chaos -> Stabilizer, else Disruptor
                    influenceMagnitude: Math.min(totalAttributeSum.div(20), _alchemyConfig.artifactMaxInfluence),
                    influenceType: (combinedAttrs.stability > combinedAttrs.energy ? 1 : 2) // Example: Stability > Energy -> Success Influence, else Env Shift Influence
                });
            } else {
                outcomeType = 1; // New Essence
                 // Determine new Essence attributes based on inputs
                 newEssenceAttrs = EssenceAttributes({
                     energy: Math.min(combinedAttrs.energy.mul(120).div(100), _alchemyConfig.maxEssenceAttribute), // Example: slight boost
                     stability: Math.min(combinedAttrs.stability.mul(110).div(100), _alchemyConfig.maxEssenceAttribute),
                     purity: Math.min(combinedAttrs.purity.mul(105).div(100), _alchemyConfig.maxEssenceAttribute),
                     chaos: Math.min(combinedAttrs.chaos.mul(115).div(100), _alchemyConfig.maxEssenceAttribute)
                 });
                 // Add some randomness to the output attributes
                 newEssenceAttrs.energy = newEssenceAttrs.energy.add(randomFactor % 50).sub(25); // +/- 25 example
                 // ... apply randomness to others
            }
        }
        // --- End Outcome Logic ---

        // Process outcome
        if (outcomeType == 1 || outcomeType == 2) { // Mint new token
            _currentTokenId.increment();
            uint256 newItemId = _currentTokenId.current();
            if (outcomeType == 1) {
                 _mint(msg.sender, newItemId, TokenType.Essence, newEssenceAttrs, ArtifactData(0,0,0));
                 outputTokenIds = new uint256[](1);
                 outputTokenIds[0] = newItemId;
            } else { // outcomeType == 2
                 _mint(msg.sender, newItemId, TokenType.Artifact, EssenceAttributes(0,0,0,0), newArtifactData);
                  outputTokenIds = new uint256[](1);
                 outputTokenIds[0] = newItemId;
            }
            _userAlchemyStats[msg.sender].success++;
            _latestSuccessfulAlchemyResult = AlchemyResult(inputTokenIds, outputTokenIds, outcomeType, block.timestamp);
             emit AlchemySuccess(msg.sender, inputTokenIds, outputTokenIds, outcomeType);

        } else if (outcomeType == 3) { // Environmental Shift
             uint256 oldState = _environmentalState;
            // Example shift: based on chaos and random factor
             int256 envShift = int256(combinedAttrs.chaos.div(10)).add(int256(randomFactor % 20)).sub(10); // Chaos + random influences shift amount
             envShift = envShift.add(envShiftInfluence); // Artifact influence
             _environmentalState = uint256(Math.max(0, int256(_environmentalState).add(envShift)));
             _environmentalState = Math.min(_environmentalState, _alchemyConfig.maxEnvironmentalState);

            _userAlchemyStats[msg.sender].success++; // Shifting environment is a successful outcome type
            _latestSuccessfulAlchemyResult = AlchemyResult(inputTokenIds, new uint256[](0), outcomeType, block.timestamp);
             emit EnvironmentalShift(msg.sender, oldState, _environmentalState, uint256(Math.abs(envShift)));
             emit AlchemySuccess(msg.sender, inputTokenIds, new uint256[](0), outcomeType);

        } else { // outcomeType == 4 (No Output/Failure)
            _userAlchemyStats[msg.sender].fail++;
            emit AlchemyFailed(msg.sender, inputTokenIds, "Reaction dissipated without stable outcome");
        }

         // Update last alchemy time for inputs (even though burned, could be useful for history tracking off-chain)
         // For on-chain, this isn't needed as tokens are burned.

    }

    // Simulate Alchemy function
    function simulateQuantumAlchemyOutcome(uint256[] calldata inputTokenIds) external view returns (SimulatedOutcome memory) {
        require(inputTokenIds.length >= 2, "Requires at least 2 input tokens");

         // Perform checks similar to performQuantumAlchemy without state changes
        for (uint256 i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
             if (!_exists(tokenId)) return SimulatedOutcome(TokenType.Invalid, string(abi.encodePacked("Error: Input token does not exist: ", Strings.toString(tokenId))), EssenceAttributes(0,0,0,0), ArtifactData(0,0,0), 0, "Simulation failed");
             if (ownerOf(tokenId) != msg.sender) return SimulatedOutcome(TokenType.Invalid, string(abi.encodePacked("Error: Input token not owned by sender: ", Strings.toString(tokenId))), EssenceAttributes(0,0,0,0), ArtifactData(0,0,0), 0, "Simulation failed");
        }

        // Calculate combined attributes (decay adjusted)
        EssenceAttributes memory combinedAttrs = _calculateCombinedAttributes(inputTokenIds);

        // Calculate Artifact influence
        int256 alchemySuccessInfluence = _calculateAttributeInfluence(inputTokenIds, 1);
        int256 envShiftInfluence = _calculateAttributeInfluence(inputTokenIds, 2);

        // Simulate outcome logic (using a fixed seed or simple calculation for determinism in view function)
        // Note: This simulation cannot use block.timestamp/difficulty/sender for randomness if aiming for a predictable view.
        // A simple deterministic calculation based on inputs and environment is used here.
        uint256 totalAttributeSum = combinedAttrs.energy.add(combinedAttrs.stability).add(combinedAttrs.purity).add(combinedAttrs.chaos);

        uint256 potentialOutcomeType = 4; // Default: No Output
        EssenceAttributes memory potentialNewEssenceAttributes;
        ArtifactData memory potentialNewArtifactData;
        int256 potentialEnvironmentalStateChange = 0;

         // Deterministic simulation logic (example)
         // Thresholds are key here, probabilities from performQuantumAlchemy are hard to predict deterministically
        string memory description = "Simulated outcome: Dissipation (No Output)";
        string memory warning = "Note: Actual outcome is probabilistic and influenced by on-chain randomness.";

        if (totalAttributeSum >= _alchemyConfig.environmentalShiftThreshold.add(uint256(Math.max(0, envShiftInfluence * 5)))) { // Higher threshold if negative influence, lower if positive
             // High chance of Env Shift if thresholds met
            potentialOutcomeType = 3;
            description = "Simulated outcome: Environmental Shift";
            // Estimate shift amount (deterministic calculation)
            int256 estimatedShift = int256(combinedAttrs.chaos.div(10)).add(envShiftInfluence);
            potentialEnvironmentalStateChange = estimatedShift;

        } else if (totalAttributeSum >= _alchemyConfig.essenceToArtifactThreshold.add(uint256(Math.max(0, alchemySuccessInfluence * 5)))) {
            // High chance of Artifact if thresholds met
            potentialOutcomeType = 2;
            description = "Simulated outcome: New Artifact";
             potentialNewArtifactData = ArtifactData({
                artifactType: (combinedAttrs.purity > combinedAttrs.chaos ? 1 : 2),
                influenceMagnitude: Math.min(totalAttributeSum.div(20), _alchemyConfig.artifactMaxInfluence),
                influenceType: (combinedAttrs.stability > combinedAttrs.energy ? 1 : 2)
            });

        } else if (totalAttributeSum > (_alchemyConfig.newEssenceMinAttributes * 4)) { // Simple check for minimum viable total attributes
            // High chance of New Essence
             potentialOutcomeType = 1;
            description = "Simulated outcome: New Essence";
             potentialNewEssenceAttributes = EssenceAttributes({
                 energy: combinedAttrs.energy.mul(120).div(100), // Example: slight boost
                 stability: combinedAttrs.stability.mul(110).div(100),
                 purity: combinedAttrs.purity.mul(105).div(100),
                 chaos: combinedAttrs.chaos.mul(115).div(100)
             });
             // Note: Simulation doesn't apply the random factor to output attributes like the actual function
        }
        // --- End Simulation Logic ---


        return SimulatedOutcome(
            potentialOutcomeType,
            description,
            potentialNewEssenceAttributes,
            potentialNewArtifactData,
            potentialEnvironmentalStateChange,
            warning
        );
    }
}

```