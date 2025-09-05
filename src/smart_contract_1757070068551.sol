This smart contract, `AuraWeaver`, introduces a novel concept: **Self-Evolving, Reputation-Bound, Generative NFTs influenced by on-chain actions and external 'Environmental' Oracles, fostering a unique social dynamic through patronage and catalyst roles.**

Unlike static NFTs, AuraWeaves are born, live, and **mutate their core attributes** (represented as abstract `formAttributes` like Color, Texture, Lumina, Shape) over time. This evolution is driven by:
1.  **Staked `AuraEssence` tokens:** The lifeblood of an AuraWeave.
2.  **User `AuraScore`:** A non-transferable reputation score earned through positive interactions.
3.  **Patronage:** Users can "patronize" other AuraWeaves, boosting their evolution potential.
4.  **External `Global Influence`:** Oracle-fed environmental factors that universally affect mutation probabilities and outcomes, mimicking real-world adaptation.

The goal is to create a dynamic, interconnected NFT ecosystem where user actions, social interaction, and external data collectively sculpt the digital life forms.

---

## AuraWeaver Smart Contract Outline & Function Summary

**Contract Name:** `AuraWeaver`

**Core Concept:** Self-Evolving, Reputation-Bound Generative NFTs with Adaptive Social Mechanics.

---

### **Outline:**

1.  **Dependencies:** ERC-721, ERC-721Metadata, AccessControl (Ownable)
2.  **Error Handling:** Custom errors for clarity.
3.  **Structs & Enums:**
    *   `AuraWeaveAttributes`: Defines the evolving characteristics of an NFT.
    *   `AuraWeave`: Main NFT data structure including attributes, essence stake, and evolution history.
    *   `InteractionType`: Enum for different types of AuraScore-generating interactions.
4.  **State Variables:**
    *   NFT data mappings, AuraScore mapping, Evolution parameters, Oracle address.
    *   Internal `AuraEssence` token (simplified ERC-20).
5.  **Events:** For key actions (Mint, Evolve, Patronize, Influence).
6.  **Modifiers:** `onlyOracle`, `whenNotPaused`.
7.  **Constructor:** Initializes the contract, sets up owner, initial parameters.
8.  **Internal ERC-20 (`AuraEssence`) Functions:** (Simplified for this example)
9.  **ERC-721 Standard Functions:**
10. **AuraWeaver Specific NFT Functions:** (Core Evolving Logic)
11. **AuraScore & Reputation Functions:**
12. **Social Interaction Functions:** (Patronage, Catalyst)
13. **Oracle & Environmental Influence Functions:**
14. **Utility & View Functions:**
15. **Admin & System Control Functions:**

---

### **Function Summary (26 Functions):**

**I. ERC-721 Standard Functions (10 functions):**
1.  `constructor()`: Initializes the contract and its ERC-721/Ownable components.
2.  `balanceOf(address owner)`: Returns the number of NFTs owned by `owner`.
3.  `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId`.
4.  `approve(address to, uint256 tokenId)`: Approves `to` to manage `tokenId`.
5.  `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`.
6.  `setApprovalForAll(address operator, bool approved)`: Enables/disables `operator` for all NFTs.
7.  `isApprovedForAll(address owner, address operator)`: Checks if `operator` is approved for `owner`.
8.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer, checks `to` for ERC-721 receiver support.
10. `supportsInterface(bytes4 interfaceId)`: Indicates which ERC interfaces the contract supports.

**II. AuraWeaver Specific NFT Functions (5 functions):**
11. `tokenURI(uint256 tokenId)`: **Advanced/Dynamic:** Generates a dynamic URI based on the AuraWeave's current `formAttributes` and `evolutionGen`.
12. `weaveNewAuraWeave(uint256 initialEssenceStake)`: **Creative/Core:** Mints a new AuraWeave, requiring the caller to stake `AuraEssence` tokens to bring it to life. Initial attributes are randomly assigned.
13. `initiateEvolution(uint256 tokenId)`: **Advanced/Core:** Allows an AuraWeave owner to attempt to evolve their NFT. Success depends on staked Essence, AuraScore, and global influence.
14. `getAuraWeaveAttributes(uint256 tokenId)`: **View:** Retrieves the current `formAttributes` (Color, Texture, Lumina, Shape) of a specific AuraWeave.
15. `getEvolutionGeneration(uint256 tokenId)`: **View:** Returns the current evolution generation count of an AuraWeave.

**III. AuraEssence Token & Staking (3 functions):**
16. `stakeEssenceToWeave(uint256 tokenId, uint256 amount)`: **Trendy/Utility:** Allows a user to stake more `AuraEssence` into an AuraWeave, increasing its potential for evolution and stability.
17. `unstakeEssenceFromWeave(uint256 tokenId, uint256 amount)`: **Utility:** Allows a user to retrieve staked `AuraEssence` from their AuraWeave (with potential cooldown/fees in a full version).
18. `burnEssenceForAura(uint256 amount)`: **Creative/Utility:** Allows a user to burn `AuraEssence` tokens directly to increase their personal `AuraScore`, signaling commitment.

**IV. AuraScore & Reputation (2 functions):**
19. `getAuraScore(address user)`: **View:** Returns the non-transferable `AuraScore` of a specific user.
20. `recordInteraction(address targetUser, InteractionType interactionType)`: **Advanced/Internal:** An internal or whitelisted function to programmatically update `AuraScore` based on positive ecosystem interactions (e.g., successful patronage, catalyst actions).

**V. Social & Dynamic Mechanics (3 functions):**
21. `patronizeAuraWeave(uint256 tokenId, uint256 essenceAmount)`: **Creative/Social:** Allows a user to contribute `AuraEssence` to *another* user's AuraWeave, boosting its evolution chances. Both patron and weave owner gain `AuraScore`.
22. `registerAsCatalyst(uint256 tokenId)`: **Creative/Social:** A user declares a special, non-transferable, and binding connection to an AuraWeave, signifying deep engagement and potentially unlocking future influence or rewards.
23. `receiveGlobalInfluence(bytes32 influenceHash, uint256 influenceValue)`: **Advanced/Oracle:** An `onlyOracle` function to update global environmental factors that affect all AuraWeave evolution probabilities and attribute mutations.

**VI. Administrative & System Control (3 functions):**
24. `setEvolutionConstants(bytes32 paramKey, uint256 value)`: **Admin:** Allows the contract owner to fine-tune various parameters governing evolution (e.g., base success chance, AuraScore impact).
25. `setOracleAddress(address _oracleAddress)`: **Admin:** Sets or updates the address of the trusted oracle allowed to submit global influence data.
26. `pauseSystem(bool _paused)`: **Admin:** An emergency function to pause critical contract functionalities, such as minting and evolution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For interacting with AuraEssence
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For internal calculations

// --- AuraWeaver Smart Contract Outline & Function Summary ---
//
// Contract Name: `AuraWeaver`
// Core Concept: Self-Evolving, Reputation-Bound Generative NFTs with Adaptive Social Mechanics.
//
// --- Outline:
// 1. Dependencies: ERC-721, ERC-721Metadata, AccessControl (Ownable)
// 2. Error Handling: Custom errors for clarity.
// 3. Structs & Enums:
//    - AuraWeaveAttributes: Defines the evolving characteristics of an NFT.
//    - AuraWeave: Main NFT data structure including attributes, essence stake, and evolution history.
//    - InteractionType: Enum for different types of AuraScore-generating interactions.
// 4. State Variables:
//    - NFT data mappings, AuraScore mapping, Evolution parameters, Oracle address.
//    - Internal AuraEssence token (simplified ERC-20).
// 5. Events: For key actions (Mint, Evolve, Patronize, Influence).
// 6. Modifiers: onlyOracle, whenNotPaused.
// 7. Constructor: Initializes the contract, sets up owner, initial parameters.
// 8. Internal ERC-20 (`AuraEssence`) Functions: (Simplified for this example)
// 9. ERC-721 Standard Functions:
// 10. AuraWeaver Specific NFT Functions: (Core Evolving Logic)
// 11. AuraScore & Reputation Functions:
// 12. Social Interaction Functions: (Patronage, Catalyst)
// 13. Oracle & Environmental Influence Functions:
// 14. Utility & View Functions:
// 15. Admin & System Control Functions:
//
// --- Function Summary (26 Functions):
//
// I. ERC-721 Standard Functions (10 functions):
// 1. constructor(): Initializes the contract and its ERC-721/Ownable components.
// 2. balanceOf(address owner): Returns the number of NFTs owned by `owner`.
// 3. ownerOf(uint256 tokenId): Returns the owner of the `tokenId`.
// 4. approve(address to, uint256 tokenId): Approves `to` to manage `tokenId`.
// 5. getApproved(uint256 tokenId): Returns the approved address for `tokenId`.
// 6. setApprovalForAll(address operator, bool approved): Enables/disables `operator` for all NFTs.
// 7. isApprovedForAll(address owner, address operator): Checks if `operator` is approved for `owner`.
// 8. transferFrom(address from, address to, uint256 tokenId): Transfers `tokenId` from `from` to `to`.
// 9. safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer, checks `to` for ERC-721 receiver support.
// 10. supportsInterface(bytes4 interfaceId): Indicates which ERC interfaces the contract supports.
//
// II. AuraWeaver Specific NFT Functions (5 functions):
// 11. tokenURI(uint256 tokenId): Advanced/Dynamic: Generates a dynamic URI based on the AuraWeave's current `formAttributes` and `evolutionGen`.
// 12. weaveNewAuraWeave(uint256 initialEssenceStake): Creative/Core: Mints a new AuraWeave, requiring the caller to stake `AuraEssence` tokens to bring it to life. Initial attributes are randomly assigned.
// 13. initiateEvolution(uint256 tokenId): Advanced/Core: Allows an AuraWeave owner to attempt to evolve their NFT. Success depends on staked Essence, AuraScore, and global influence.
// 14. getAuraWeaveAttributes(uint256 tokenId): View: Retrieves the current `formAttributes` (Color, Texture, Lumina, Shape) of a specific AuraWeave.
// 15. getEvolutionGeneration(uint256 tokenId): View: Returns the current evolution generation count of an AuraWeave.
//
// III. AuraEssence Token & Staking (3 functions):
// 16. stakeEssenceToWeave(uint256 tokenId, uint256 amount): Trendy/Utility: Allows a user to stake more `AuraEssence` into an AuraWeave, increasing its potential for evolution and stability.
// 17. unstakeEssenceFromWeave(uint256 tokenId, uint256 amount): Utility: Allows a user to retrieve staked `AuraEssence` from their AuraWeave (with potential cooldown/fees in a full version).
// 18. burnEssenceForAura(uint256 amount): Creative/Utility: Allows a user to burn `AuraEssence` tokens directly to increase their personal `AuraScore`, signaling commitment.
//
// IV. AuraScore & Reputation (2 functions):
// 19. getAuraScore(address user): View: Returns the non-transferable `AuraScore` of a specific user.
// 20. recordInteraction(address targetUser, InteractionType interactionType): Advanced/Internal: An internal or whitelisted function to programmatically update `AuraScore` based on positive ecosystem interactions (e.g., successful patronage, catalyst actions).
//
// V. Social & Dynamic Mechanics (3 functions):
// 21. patronizeAuraWeave(uint256 tokenId, uint256 essenceAmount): Creative/Social: Allows a user to contribute `AuraEssence` to *another* user's AuraWeave, boosting its evolution chances. Both patron and weave owner gain `AuraScore`.
// 22. registerAsCatalyst(uint256 tokenId): Creative/Social: A user declares a special, non-transferable, and binding connection to an AuraWeave, signifying deep engagement and potentially unlocking future influence or rewards.
// 23. receiveGlobalInfluence(bytes32 influenceHash, uint256 influenceValue): Advanced/Oracle: An `onlyOracle` function to update global environmental factors that affect all AuraWeave evolution probabilities and attribute mutations.
//
// VI. Administrative & System Control (3 functions):
// 24. setEvolutionConstants(bytes32 paramKey, uint256 value): Admin: Allows the contract owner to fine-tune various parameters governing evolution (e.g., base success chance, AuraScore impact).
// 25. setOracleAddress(address _oracleAddress): Admin: Sets or updates the address of the trusted oracle allowed to submit global influence data.
// 26. pauseSystem(bool _paused): Admin: An emergency function to pause critical contract functionalities, such as minting and evolution.
//
// ---

// Interface for a hypothetical AuraEssence ERC-20 token
interface IAuraEssence is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract AuraWeaver is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    // --- Custom Errors ---
    error InvalidEssenceStake();
    error NotEnoughEssenceStaked();
    error NotOwnerOfAuraWeave();
    error EvolutionCooldownActive();
    error AuraWeaveDoesNotExist();
    error EvolutionFailed();
    error InvalidEvolutionParameter();
    error SystemPaused();
    error AlreadyACatalyst();
    error OnlyCatalystCanPerformAction();
    error NotEnoughEssence();
    error TransferFailed();
    error ApprovalFailed();

    // --- Enums and Structs ---

    enum InteractionType {
        PatronageGiven,
        PatronageReceived,
        CatalystRegistered,
        EssenceBurned
        // More types can be added later
    }

    // Represents the mutable attributes of an AuraWeave NFT
    struct AuraWeaveAttributes {
        uint8 color;   // 0-255, e.g., representing hue
        uint8 texture; // 0-255, e.g., representing pattern complexity
        uint8 lumina;  // 0-255, e.g., representing brightness/glow
        uint8 shape;   // 0-255, e.g., representing structural form
    }

    // Main data structure for each AuraWeave NFT
    struct AuraWeave {
        AuraWeaveAttributes attributes;
        uint256 essenceStaked;
        uint256 evolutionGen;
        uint256 lastEvolutionTime;
        address[] patrons; // Addresses that have patronized this AuraWeave
        address catalyst;  // Special binding role
        uint256 totalPatronageReceived; // Sum of essence received from patrons
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => AuraWeave) public auraWeaves;
    mapping(address => uint256) public auraScores; // Non-transferable reputation score
    mapping(address => mapping(uint256 => bool)) public isCatalystFor; // catalyst address => tokenId => bool

    IAuraEssence public auraEssence; // Address of the AuraEssence ERC-20 contract
    address public oracleAddress; // Address of the trusted oracle

    // Global parameters influencing evolution outcomes
    mapping(bytes32 => uint256) public evolutionConstants;

    bool public paused; // System pause state

    // --- Events ---

    event AuraWeaveWeaved(uint256 indexed tokenId, address indexed owner, uint256 initialEssence);
    event AuraWeaveEvolved(uint256 indexed tokenId, uint256 newGeneration, AuraWeaveAttributes newAttributes);
    event AuraEssenceStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event AuraEssenceUnstaked(uint256 indexed tokenId, address indexed unstaker, uint256 amount);
    event AuraScoreUpdated(address indexed user, uint256 newScore, InteractionType interactionType);
    event AuraWeavePatronized(uint256 indexed tokenId, address indexed patron, uint256 essenceAmount);
    event CatalystRegistered(uint256 indexed tokenId, address indexed catalyst);
    event GlobalInfluenceReceived(bytes32 indexed influenceHash, uint256 influenceValue);
    event SystemPausedStatus(bool indexed newStatus);

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable's error for consistency
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert SystemPaused();
        _;
    }

    // --- Constructor ---

    constructor(address _auraEssenceAddress, address _oracleAddress)
        ERC721("AuraWeaver", "AW")
        Ownable(msg.sender) // Owner is the deployer
    {
        if (_auraEssenceAddress == address(0)) revert InvalidEssenceStake(); // Reusing error
        if (_oracleAddress == address(0)) revert InvalidEssenceStake(); // Reusing error

        auraEssence = IAuraEssence(_auraEssenceAddress);
        oracleAddress = _oracleAddress;

        // Initialize default evolution constants
        evolutionConstants["BASE_EVOLUTION_CHANCE"] = 500;  // 5% (500 / 10000)
        evolutionConstants["AURA_SCORE_MULTIPLIER"] = 10;   // 10 points per AuraScore
        evolutionConstants["ESSENCE_STAKE_MULTIPLIER"] = 5; // 5 points per 1000 Essence (assuming 18 decimals)
        evolutionConstants["MIN_ESSENCE_FOR_EVOLUTION"] = 10 * (10 ** 18); // 10 Essence
        evolutionConstants["EVOLUTION_COOLDOWN_SECONDS"] = 1 days; // 1 day
        evolutionConstants["GLOBAL_INFLUENCE_WEIGHT"] = 200; // 2% (200 / 10000)
        evolutionConstants["PATRONAGE_AURA_REWARD"] = 50; // 50 AuraScore for patron & owner per patronage

        paused = false;
    }

    // --- Internal ERC-20 (AuraEssence) Interactions ---
    // Note: AuraEssence is assumed to be a separate, pre-deployed ERC-20 token.
    // This contract interacts with it using IERC20 interface.

    function _transferEssenceIn(address from, uint256 amount) internal {
        if (!auraEssence.transferFrom(from, address(this), amount)) {
            revert TransferFailed();
        }
    }

    function _transferEssenceOut(address to, uint256 amount) internal {
        if (!auraEssence.transfer(to, amount)) {
            revert TransferFailed();
        }
    }

    // --- ERC-721 Standard Functions ---
    // These are implemented by ERC721 and ERC721URIStorage
    // (1) constructor() is above
    // (2) balanceOf(address owner)
    // (3) ownerOf(uint256 tokenId)
    // (4) approve(address to, uint256 tokenId)
    // (5) getApproved(uint256 tokenId)
    // (6) setApprovalForAll(address operator, bool approved)
    // (7) isApprovedForAll(address owner, address operator)
    // (8) transferFrom(address from, address to, uint256 tokenId)
    // (9) safeTransferFrom(address from, address to, uint256 tokenId)
    // (10) supportsInterface(bytes4 interfaceId)

    // Overriding _baseURI and tokenURI for dynamic generation
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://auraweaver/metadata/"; // Base for potential IPFS content
    }

    /// @notice Generates a dynamic token URI reflecting the AuraWeave's current attributes.
    /// @dev This function is key to the "generative" aspect. In a real application, this JSON
    /// would point to an SVG or image generated from these attributes.
    /// @param tokenId The ID of the AuraWeave.
    /// @return The JSON metadata URI.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();

        AuraWeave storage weave = auraWeaves[tokenId];
        AuraWeaveAttributes memory attrs = weave.attributes;

        string memory json = string.concat(
            '{"name": "AuraWeave #', tokenId.toString(),
            '", "description": "A self-evolving digital life form.",',
            '"attributes": [',
            '{"trait_type": "Generation", "value": "', weave.evolutionGen.toString(), '"},',
            '{"trait_type": "Color", "value": "', attrs.color.toString(), '"},',
            '{"trait_type": "Texture", "value": "', attrs.texture.toString(), '"},',
            '{"trait_type": "Lumina", "value": "', attrs.lumina.toString(), '"},',
            '{"trait_type": "Shape", "value": "', attrs.shape.toString(), '"},',
            '{"trait_type": "Essence Staked", "value": "', weave.essenceStaked.toString(), '"}',
            ']}'
        );

        string memory baseURI = _baseURI();
        return string.concat(baseURI, Base64.encode(bytes(json)));
    }

    // --- AuraWeaver Specific NFT Functions ---

    /// @notice Weaves a new AuraWeave NFT, requiring an initial stake of AuraEssence.
    /// @dev This is the primary minting function, where a new evolving NFT is created.
    /// @param initialEssenceStake The amount of AuraEssence to stake initially.
    /// @return The ID of the newly woven AuraWeave.
    function weaveNewAuraWeave(uint256 initialEssenceStake)
        public
        whenNotPaused
        returns (uint256)
    {
        if (initialEssenceStake < evolutionConstants["MIN_ESSENCE_FOR_EVOLUTION"]) {
            revert InvalidEssenceStake();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _transferEssenceIn(msg.sender, initialEssenceStake);

        // Pseudo-random initial attributes (simplified for example)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId)));
        AuraWeaveAttributes memory initialAttrs = AuraWeaveAttributes({
            color: uint8(seed % 256),
            texture: uint8((seed / 256) % 256),
            lumina: uint8((seed / (256 * 256)) % 256),
            shape: uint8((seed / (256 * 256 * 256)) % 256)
        });

        auraWeaves[newTokenId] = AuraWeave({
            attributes: initialAttrs,
            essenceStaked: initialEssenceStake,
            evolutionGen: 1,
            lastEvolutionTime: block.timestamp,
            patrons: new address[](0),
            catalyst: address(0),
            totalPatronageReceived: 0
        });

        _safeMint(msg.sender, newTokenId);
        _recordInteraction(msg.sender, InteractionType.EssenceBurned); // Implicitly burning by staking

        emit AuraWeaveWeaved(newTokenId, msg.sender, initialEssenceStake);
        return newTokenId;
    }

    /// @notice Allows an AuraWeave owner to attempt to evolve their NFT.
    /// @dev The success of evolution depends on various factors: staked Essence, owner's AuraScore,
    ///      global environmental influence, and a cooldown period.
    /// @param tokenId The ID of the AuraWeave to evolve.
    function initiateEvolution(uint256 tokenId)
        public
        whenNotPaused
    {
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfAuraWeave();
        AuraWeave storage weave = auraWeaves[tokenId];
        if (block.timestamp < weave.lastEvolutionTime + evolutionConstants["EVOLUTION_COOLDOWN_SECONDS"]) {
            revert EvolutionCooldownActive();
        }
        if (weave.essenceStaked < evolutionConstants["MIN_ESSENCE_FOR_EVOLUTION"]) {
            revert NotEnoughEssenceStaked();
        }

        uint256 successChance = evolutionConstants["BASE_EVOLUTION_CHANCE"]; // Base chance (e.g., 500 = 5%)
        successChance = successChance.add(auraScores[msg.sender].mul(evolutionConstants["AURA_SCORE_MULTIPLIER"]).div(1000)); // AuraScore impact
        successChance = successChance.add(weave.essenceStaked.div(10**18).mul(evolutionConstants["ESSENCE_STAKE_MULTIPLIER"])); // Staked Essence impact

        // Integrate global influence (assumed to be updated by oracle)
        uint256 globalFactor = evolutionConstants["LAST_GLOBAL_INFLUENCE"]; // Assuming this is set by receiveGlobalInfluence
        successChance = successChance.add(globalFactor.mul(evolutionConstants["GLOBAL_INFLUENCE_WEIGHT"]).div(10000));

        // Use blockhash for pseudo-randomness (not suitable for high-security applications)
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId))) % 10000;

        if (randomValue < successChance) {
            // Evolution successful! Mutate attributes
            uint256 mutationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, "mutation")));
            
            // Mutate each attribute with some probability
            if (mutationSeed % 100 < 60) weave.attributes.color = uint8((weave.attributes.color + (mutationSeed % 50) + 1) % 256);
            if ((mutationSeed / 100) % 100 < 60) weave.attributes.texture = uint8((weave.attributes.texture + ((mutationSeed / 100) % 50) + 1) % 256);
            if ((mutationSeed / 10000) % 100 < 60) weave.attributes.lumina = uint8((weave.attributes.lumina + ((mutationSeed / 10000) % 50) + 1) % 256);
            if ((mutationSeed / 1000000) % 100 < 60) weave.attributes.shape = uint8((weave.attributes.shape + ((mutationSeed / 1000000) % 50) + 1) % 256);
            
            weave.evolutionGen++;
            weave.lastEvolutionTime = block.timestamp;

            emit AuraWeaveEvolved(tokenId, weave.evolutionGen, weave.attributes);
        } else {
            // Evolution failed, but still consume the attempt
            weave.lastEvolutionTime = block.timestamp; // Update cooldown
            emit EvolutionFailed(); // Or a more specific event
            // Optionally, penalize Essence or AuraScore
        }
    }

    /// @notice View function to retrieve the current generative attributes of an AuraWeave.
    /// @param tokenId The ID of the AuraWeave.
    /// @return The AuraWeaveAttributes struct containing color, texture, lumina, and shape.
    function getAuraWeaveAttributes(uint256 tokenId)
        public
        view
        returns (AuraWeaveAttributes memory)
    {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();
        return auraWeaves[tokenId].attributes;
    }

    /// @notice View function to get the current evolution generation of an AuraWeave.
    /// @param tokenId The ID of the AuraWeave.
    /// @return The current evolution generation number.
    function getEvolutionGeneration(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();
        return auraWeaves[tokenId].evolutionGen;
    }

    // --- AuraEssence Token & Staking ---

    /// @notice Stakes more AuraEssence tokens into an existing AuraWeave.
    /// @param tokenId The ID of the AuraWeave.
    /// @param amount The amount of Essence to stake.
    function stakeEssenceToWeave(uint256 tokenId, uint256 amount)
        public
        whenNotPaused
    {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfAuraWeave();
        if (amount == 0) revert InvalidEssenceStake();

        _transferEssenceIn(msg.sender, amount);
        auraWeaves[tokenId].essenceStaked = auraWeaves[tokenId].essenceStaked.add(amount);

        emit AuraEssenceStaked(tokenId, msg.sender, amount);
    }

    /// @notice Unstakes AuraEssence tokens from an AuraWeave.
    /// @param tokenId The ID of the AuraWeave.
    /// @param amount The amount of Essence to unstake.
    function unstakeEssenceFromWeave(uint256 tokenId, uint256 amount)
        public
        whenNotPaused
    {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfAuraWeave();
        if (amount == 0) revert InvalidEssenceStake();
        if (auraWeaves[tokenId].essenceStaked < amount) revert NotEnoughEssenceStaked();

        auraWeaves[tokenId].essenceStaked = auraWeaves[tokenId].essenceStaked.sub(amount);
        _transferEssenceOut(msg.sender, amount);

        emit AuraEssenceUnstaked(tokenId, msg.sender, amount);
    }

    /// @notice Burns AuraEssence tokens to directly increase the caller's AuraScore.
    /// @param amount The amount of Essence to burn.
    function burnEssenceForAura(uint256 amount) public whenNotPaused {
        if (amount == 0) revert NotEnoughEssence();
        if (auraEssence.balanceOf(msg.sender) < amount) revert NotEnoughEssence();

        // Transfer to zero address to burn
        if (!auraEssence.transferFrom(msg.sender, address(0), amount)) {
            revert TransferFailed();
        }

        // Increase AuraScore based on burned essence
        // This factor can be tuned via evolutionConstants
        uint256 auraGain = amount.div(10**18).mul(evolutionConstants["ESSENCE_BURN_AURA_RATE"]);
        if (auraGain == 0) auraGain = 1; // Ensure a minimum gain for any burn

        auraScores[msg.sender] = auraScores[msg.sender].add(auraGain);
        emit AuraScoreUpdated(msg.sender, auraScores[msg.sender], InteractionType.EssenceBurned);
    }

    // --- AuraScore & Reputation ---

    /// @notice Retrieves the non-transferable AuraScore of a specific user.
    /// @param user The address of the user.
    /// @return The AuraScore of the user.
    function getAuraScore(address user) public view returns (uint256) {
        return auraScores[user];
    }

    /// @dev Internal helper function to update AuraScores based on interactions.
    ///      This is typically called by other functions within the contract.
    /// @param targetUser The address whose AuraScore is being updated.
    /// @param interactionType The type of interaction that occurred.
    function _recordInteraction(address targetUser, InteractionType interactionType) internal {
        uint256 scoreIncrease = 0;
        if (interactionType == InteractionType.PatronageGiven) {
            scoreIncrease = evolutionConstants["PATRONAGE_AURA_REWARD"];
        } else if (interactionType == InteractionType.PatronageReceived) {
            scoreIncrease = evolutionConstants["PATRONAGE_AURA_REWARD"];
        } else if (interactionType == InteractionType.CatalystRegistered) {
            scoreIncrease = evolutionConstants["CATALYST_AURA_REWARD"]; // Define this constant
        } else if (interactionType == InteractionType.EssenceBurned) {
            scoreIncrease = evolutionConstants["ESSENCE_BURN_AURA_RATE"]; // Define this constant
        }
        // Add more interaction types and their respective score increases

        if (scoreIncrease > 0) {
            auraScores[targetUser] = auraScores[targetUser].add(scoreIncrease);
            emit AuraScoreUpdated(targetUser, auraScores[targetUser], interactionType);
        }
    }

    // --- Social & Dynamic Mechanics ---

    /// @notice Allows a user to patronize another user's AuraWeave by contributing AuraEssence.
    /// @dev Both the patron and the AuraWeave owner receive AuraScore, fostering community support.
    /// @param tokenId The ID of the AuraWeave to patronize.
    /// @param essenceAmount The amount of AuraEssence to contribute.
    function patronizeAuraWeave(uint256 tokenId, uint256 essenceAmount)
        public
        whenNotPaused
    {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();
        if (essenceAmount == 0) revert InvalidEssenceStake(); // Reusing error
        if (ownerOf(tokenId) == msg.sender) revert NotOwnerOfAuraWeave(); // Cannot patronize your own

        _transferEssenceIn(msg.sender, essenceAmount);
        auraWeaves[tokenId].essenceStaked = auraWeaves[tokenId].essenceStaked.add(essenceAmount);
        auraWeaves[tokenId].totalPatronageReceived = auraWeaves[tokenId].totalPatronageReceived.add(essenceAmount);
        auraWeaves[tokenId].patrons.push(msg.sender);

        _recordInteraction(msg.sender, InteractionType.PatronageGiven);
        _recordInteraction(ownerOf(tokenId), InteractionType.PatronageReceived);

        emit AuraWeavePatronized(tokenId, msg.sender, essenceAmount);
    }

    /// @notice Allows a user to declare themselves a "catalyst" for a specific AuraWeave.
    /// @dev This creates a non-transferable bond, similar to a Soulbound Token link,
    ///      potentially unlocking future abilities or influence over the AuraWeave's evolution.
    /// @param tokenId The ID of the AuraWeave to become a catalyst for.
    function registerAsCatalyst(uint256 tokenId)
        public
        whenNotPaused
    {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();
        if (isCatalystFor[msg.sender][tokenId]) revert AlreadyACatalyst();
        if (ownerOf(tokenId) == msg.sender) revert NotOwnerOfAuraWeave(); // Cannot be catalyst for own

        auraWeaves[tokenId].catalyst = msg.sender;
        isCatalystFor[msg.sender][tokenId] = true;

        _recordInteraction(msg.sender, InteractionType.CatalystRegistered);

        emit CatalystRegistered(tokenId, msg.sender);
    }

    /// @notice Allows the trusted oracle to submit global environmental influence data.
    /// @dev This data can affect the evolution probabilities and outcomes of all AuraWeaves.
    /// @param influenceHash A hash representing the type or source of influence.
    /// @param influenceValue The numerical value of the influence (e.g., 0-10000).
    function receiveGlobalInfluence(bytes32 influenceHash, uint256 influenceValue)
        public
        onlyOracle
        whenNotPaused
    {
        // Store the latest global influence, possibly by type.
        // For simplicity, let's just use one "LAST_GLOBAL_INFLUENCE" for now.
        evolutionConstants["LAST_GLOBAL_INFLUENCE"] = influenceValue;

        emit GlobalInfluenceReceived(influenceHash, influenceValue);
    }

    // --- Utility & View Functions ---

    /// @notice Gets the amount of AuraEssence currently staked in a specific AuraWeave.
    /// @param tokenId The ID of the AuraWeave.
    /// @return The amount of Essence staked.
    function getCurrentEssenceStake(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();
        return auraWeaves[tokenId].essenceStaked;
    }

    /// @notice View function to check who is the catalyst for a given AuraWeave.
    /// @param tokenId The ID of the AuraWeave.
    /// @return The address of the catalyst, or address(0) if none.
    function getCatalyst(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert AuraWeaveDoesNotExist();
        return auraWeaves[tokenId].catalyst;
    }


    // --- Admin & System Control Functions ---

    /// @notice Allows the contract owner to fine-tune various parameters governing evolution.
    /// @dev This can be used to adjust the difficulty or dynamics of the system.
    /// @param paramKey A bytes32 identifier for the parameter (e.g., "BASE_EVOLUTION_CHANCE").
    /// @param value The new value for the parameter.
    function setEvolutionConstants(bytes32 paramKey, uint256 value) public onlyOwner {
        if (value > 10000 && (paramKey == "BASE_EVOLUTION_CHANCE" || paramKey == "GLOBAL_INFLUENCE_WEIGHT")) {
            revert InvalidEvolutionParameter(); // Ensure percentages are within bounds
        }
        evolutionConstants[paramKey] = value;
    }

    /// @notice Sets or updates the address of the trusted oracle.
    /// @param _oracleAddress The new address for the oracle.
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        if (_oracleAddress == address(0)) revert InvalidEssenceStake(); // Reusing error
        oracleAddress = _oracleAddress;
    }

    /// @notice An emergency function to pause or unpause critical contract functionalities.
    /// @param _paused The new pause status (true for paused, false for unpaused).
    function pauseSystem(bool _paused) public onlyOwner {
        paused = _paused;
        emit SystemPausedStatus(_paused);
    }

    // The following functions are required by ERC721URIStorage to be implemented
    // However, since we are overriding tokenURI directly, and not using _setTokenURI,
    // they don't need explicit content beyond what's inherited, but keeping them for clarity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _approve(address to, uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._approve(to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._transfer(from, to, tokenId);
    }
}

// Minimal Base64 library for on-chain JSON encoding (from OpenZeppelin contracts-upgradeable)
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load not more than 3x bytes at the time to encode
        bytes memory buffer = new bytes(data.length * 4 / 3 + 3);
        uint256 ptr = 0;
        uint256 idx = 0;

        for (idx = 0; idx < data.length - 2; idx += 3) {
            buffer[ptr++] = _TABLE[(uint8(data[idx]) >> 2)];
            buffer[ptr++] = _TABLE[((uint8(data[idx]) & 0x03) << 4) | (uint8(data[idx + 1]) >> 4)];
            buffer[ptr++] = _TABLE[((uint8(data[idx + 1]) & 0x0F) << 2) | (uint8(data[idx + 2]) >> 6)];
            buffer[ptr++] = _TABLE[(uint8(data[idx + 2]) & 0x3F)];
        }

        if (data.length - idx == 1) {
            buffer[ptr++] = _TABLE[(uint8(data[idx]) >> 2)];
            buffer[ptr++] = _TABLE[((uint8(data[idx]) & 0x03) << 4)];
            buffer[ptr++] = '=';
            buffer[ptr++] = '=';
        } else if (data.length - idx == 2) {
            buffer[ptr++] = _TABLE[(uint8(data[idx]) >> 2)];
            buffer[ptr++] = _TABLE[((uint8(data[idx]) & 0x03) << 4) | (uint8(data[idx + 1]) >> 4)];
            buffer[ptr++] = _TABLE[((uint8(data[idx + 1]) & 0x0F) << 2)];
            buffer[ptr++] = '=';
        }

        return string(buffer);
    }
}
```