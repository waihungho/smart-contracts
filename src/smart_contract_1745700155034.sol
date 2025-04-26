Okay, this is an exciting challenge! Let's design a smart contract around a concept of "Dynamic Digital Creatures" with a lifecycle, properties that change based on interaction, and some complex mechanics like fusion and rebirth, integrating concepts like state machines, oracles, and delegated control.

We'll call it `CryptoPhoenix` - a creature NFT that goes through life stages, can "die" (turn to Ash), and potentially be reborn or fused.

Here's the outline and function summary, followed by the Solidity code.

---

## CryptoPhoenix Smart Contract Outline & Function Summary

**Concept:** `CryptoPhoenix` is an ERC721 Non-Fungible Token (NFT) representing a dynamic digital creature that evolves through different life stages (Egg, Hatchling, Adult, Elder, Ash). Its properties (Health, Energy, Attributes) change based on user interactions (feeding, training, resting), simulated time progression, and random events (via Oracle). It includes mechanisms for creature fusion and rebirth.

**Key Features & Advanced Concepts:**

1.  **Dynamic NFTs:** Token metadata (properties, attributes) changes based on on-chain actions and state.
2.  **State Machine:** Phoenixes transition between distinct life states (`Egg`, `Hatchling`, etc.) triggered by conditions or actions.
3.  **Simulated Lifecycle/Aging:** A mechanism (`agePhoenix`) causes creatures to age and potentially transition states, affecting properties. *Note: This simplified example requires explicit calls or external triggers; a real system might use an oracle or time-based logic integrated elsewhere.*
4.  **Oracle Integration (Chainlink VRF):** Used for random attribute generation when hatching or rebirthing.
5.  **Token Interaction:** Actions like `feedPhoenix` require a specific ERC20 "Food" token (simulated requirement in this example).
6.  **Delegated Control (Guardian):** Allows an owner to delegate certain interactions (like feeding/training) to another address or contract.
7.  **Complex Mechanics:** `fusePhoenixes` and `attemptRebirth` involve specific conditions, potentially consuming resources, and altering the NFT state or minting new ones.
8.  **Internal Property Decay/Growth:** Health/Energy decrease with actions (training) or age, increase with others (feeding, resting). Attributes can grow with training.

**Outline:**

1.  **Imports:** OpenZeppelin ERC721, ERC721Enumerable, ERC721URIStorage, Counters, ReentrancyGuard. Chainlink VRF.
2.  **State Variables:**
    *   Phoenix Data: Mappings for `PhoenixState`, `PhoenixProperties`, `PhoenixAttributes`.
    *   Token Control: `_tokenIds`, `_guardians`.
    *   Contract Parameters: Growth rates, consumption rates, age thresholds, Oracle setup.
3.  **Structs & Enums:** Define `PhoenixProperties`, `PhoenixAttributes`, `PhoenixState` enum.
4.  **Events:** For state changes, actions, oracle requests/fullfilment.
5.  **Modifiers:** `onlyOwner`, state-based modifiers.
6.  **ERC721 Core Functions:** `balanceOf`, `ownerOf`, `safeTransferFrom`, `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`.
7.  **ERC721 Enumerable/Metadata Functions:** `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`, `tokenURI`.
8.  **Lifecycle Management Functions:** `mintEgg`, `requestRandomnessForHatch`, `fulfillRandomnessForHatch` (handles hatching), `agePhoenix`, `checkPhoenixVitality` (internal helper, potentially external view), `fusePhoenixes`, `attemptRebirth`.
9.  **Interaction Functions:** `feedPhoenix`, `trainPhoenix`, `restPhoenix`.
10. **Delegation Functions:** `setGuardian`, `getGuardian`.
11. **Query/View Functions:** `getPhoenixState`, `getPhoenixProperties`, `getPhoenixAttributes`, `getFusionRequirements`, `getRebirthRequirements`.
12. **Admin/Parameter Functions:** `setBaseGrowthRates`, `setConsumptionRates`, `setAgeThresholds`, `setOracleConfig`.
13. **Utility:** `supportsInterface`.

**Function Summary (Aiming for >20 total):**

*   `constructor()`: Initializes contract, sets admin, VRF config.
*   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 support check.
*   `balanceOf(address owner)`: Returns count of tokens owned by `owner`. (ERC721)
*   `ownerOf(uint256 tokenId)`: Returns owner of `tokenId`. (ERC721)
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers token, checks receiver. (ERC721)
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers token (less safe). (ERC721)
*   `approve(address to, uint256 tokenId)`: Grants approval for one token. (ERC721)
*   `getApproved(uint256 tokenId)`: Returns approved address for token. (ERC721)
*   `setApprovalForAll(address operator, bool approved)`: Grants/revokes operator approval. (ERC721)
*   `isApprovedForAll(address owner, address operator)`: Checks if operator is approved for owner. (ERC721)
*   `totalSupply()`: Returns total number of tokens minted. (ERC721Enumerable)
*   `tokenByIndex(uint256 index)`: Returns token ID by index. (ERC721Enumerable)
*   `tokenOfOwnerByIndex(address owner, uint256 index)`: Returns token ID of owner by index. (ERC721Enumerable)
*   `tokenURI(uint256 tokenId)`: Returns URI for token metadata (should point to dynamic source). (ERC721URIStorage)
*   `mintEgg(address owner)`: Allows owner/admin to mint a new Phoenix Egg NFT.
*   `requestRandomnessForHatch(uint256 tokenId)`: Initiates VRF request for a specific Egg's hatching attributes. Only callable by owner/guardian of an Egg.
*   `fulfillRandomnessForHatch(bytes32 requestId, uint256 randomWord)`: VRF callback. Uses random word to generate attributes and transition Egg to Hatchling state.
*   `agePhoenix(uint256 tokenId)`: Simulates aging. Increments age, potentially changes state (Hatchling -> Adult, Adult -> Elder, Elder -> Ash) based on thresholds. Affects properties. *Simplified trigger.*
*   `feedPhoenix(uint256 tokenId, uint256 amount)`: Feeds the Phoenix. Requires a "Food" token (simulated). Increases Health/Energy, may slightly boost attributes. Callable by owner or guardian.
*   `trainPhoenix(uint256 tokenId, uint256 duration)`: Trains the Phoenix. Consumes Energy. Increases Attributes. Callable by owner or guardian. Duration simulates training intensity.
*   `restPhoenix(uint256 tokenId, uint256 duration)`: Rests the Phoenix. Increases Energy over time. Callable by owner or guardian.
*   `setGuardian(uint256 tokenId, address guardian)`: Sets an address as a guardian for a specific Phoenix, allowing them to call interaction functions.
*   `getGuardian(uint256 tokenId)`: Returns the guardian address for a Phoenix.
*   `getPhoenixState(uint256 tokenId)`: Returns the current lifecycle state of the Phoenix.
*   `getPhoenixProperties(uint256 tokenId)`: Returns the current Health, Energy, and Age.
*   `getPhoenixAttributes(uint256 tokenId)`: Returns the current Strength, Agility, Intellect, Vitality.
*   `checkPhoenixVitality(uint256 tokenId)`: *Internal helper view* - calculates a vitality score based on properties/attributes. Could be external view for debugging.
*   `fusePhoenixes(uint256 tokenId1, uint256 tokenId2)`: Attempts to fuse two Phoenixes (e.g., both in Ash state). If successful, burns the two and mints a new Egg with potentially combined/improved attributes. Complex logic. Requires specific conditions.
*   `attemptRebirth(uint256 tokenId)`: Attempts to rebirth an Ash Phoenix. Requires resources (simulated). If successful, transitions from Ash back to Egg/Hatchling state with modified properties/attributes.
*   `getFusionRequirements(uint256 tokenId1, uint256 tokenId2)`: View function describing what's needed to fuse these specific Phoenixes.
*   `getRebirthRequirements(uint256 tokenId)`: View function describing what's needed to rebirth this specific Phoenix.
*   `setBaseGrowthRates(uint256 baseHealthGrowth, ...)`: Admin function to set parameters affecting property changes.
*   `setConsumptionRates(uint256 trainingEnergyCost, ...)`: Admin function to set parameters affecting resource consumption.
*   `setAgeThresholds(uint224 hatchlingAge, uint224 adultAge, uint224 elderAge)`: Admin function to set age boundaries for state transitions.
*   `setOracleConfig(address vrfCoordinator, address linkToken, bytes32 keyHash, uint64 subscriptionId)`: Admin function to configure Chainlink VRF.

*Total Functions: 35+* (More than 20, including standard ERC721).

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRF/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

// --- Outline & Function Summary ---
// Concept: CryptoPhoenix is a dynamic ERC721 NFT creature with a lifecycle, properties that change based on
//          interaction and time, and mechanics like fusion and rebirth.
// Features: Dynamic NFTs, State Machine, Simulated Lifecycle/Aging, Oracle Integration (Chainlink VRF),
//           Token Interaction (simulated), Delegated Control (Guardian), Complex Mechanics (Fusion/Rebirth).
//
// State Variables:
// - Phoenix Data: Mappings for PhoenixState, PhoenixProperties, PhoenixAttributes.
// - Token Control: _tokenIds, _guardians.
// - Contract Parameters: Growth rates, consumption rates, age thresholds, Oracle setup.
//
// Structs & Enums: PhoenixProperties, PhoenixAttributes, PhoenixState enum.
// Events: For state changes, actions, oracle requests/fullfilment.
// Modifiers: onlyOwner, state-based modifiers.
//
// ERC721 Core Functions: balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll.
// ERC721 Enumerable/Metadata Functions: totalSupply, tokenByIndex, tokenOfOwnerByIndex, tokenURI.
// Lifecycle Management Functions: mintEgg, requestRandomnessForHatch, fulfillRandomnessForHatch (handles hatching), agePhoenix, checkPhoenixVitality (internal/view), fusePhoenixes, attemptRebirth.
// Interaction Functions: feedPhoenix, trainPhoenix, restPhoenix.
// Delegation Functions: setGuardian, getGuardian.
// Query/View Functions: getPhoenixState, getPhoenixProperties, getPhoenixAttributes, getFusionRequirements, getRebirthRequirements.
// Admin/Parameter Functions: setBaseGrowthRates, setConsumptionRates, setAgeThresholds, setOracleConfig.
// Utility: supportsInterface.
//
// Total Function Count: ~35+

contract CryptoPhoenix is ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- Enums and Structs ---

    enum PhoenixState {
        Egg,
        Hatchling,
        Adult,
        Elder,
        Ash // Dead state
    }

    struct PhoenixProperties {
        uint224 health; // Max 2^224 - 1
        uint224 energy;
        uint224 age;
        uint8 generation;
        uint64 lastInteractionTimestamp; // Timestamp of last feed/train/rest action
        uint64 lastStateChangeTimestamp; // Timestamp of last state transition
    }

    struct PhoenixAttributes {
        uint8 strength; // Max 255
        uint8 agility;
        uint8 intellect;
        uint8 vitality;
    }

    // --- State Variables ---

    mapping(uint256 => PhoenixState) private _phoenixState;
    mapping(uint256 => PhoenixProperties) private _phoenixProperties;
    mapping(uint256 => PhoenixAttributes) private _phoenixAttributes;
    mapping(uint256 => address) private _guardians; // Delegated control

    // Contract Parameters (Admin configurable)
    uint256 public baseHealthGrowthRate = 10; // Health gained per feed (simulated amount)
    uint256 public baseEnergyRestRate = 5;   // Energy gained per rest (simulated duration)
    uint256 public trainingEnergyCost = 10;  // Energy consumed per train (simulated duration)
    uint256 public trainingAttributeGain = 1; // Attribute points gained per train
    uint224 public maxHealth = 1000;
    uint224 public maxEnergy = 500;
    uint8 public maxAttribute = 100;

    // Age Thresholds (Admin configurable)
    uint224 public hatchlingAgeThreshold = 30; // Age to become Adult
    uint224 public adultAgeThreshold = 100;  // Age to become Elder
    uint224 public elderAgeThreshold = 200;  // Age to become Ash (death by old age)

    // Fusion & Rebirth Parameters (Admin configurable)
    uint256 public fusionCostSimulated = 100; // Simulated cost (e.g., requires 100 Food tokens)
    uint256 public rebirthCostSimulated = 200; // Simulated cost
    uint8 public fusionMinAttributeBoost = 1; // Min attribute points gained from fusion
    uint8 public fusionMaxAttributeBoost = 5; // Max attribute points gained from fusion
    uint8 public rebirthAttributePenalty = 10; // Attribute penalty upon rebirth

    // Oracle (Chainlink VRF)
    bytes32 public immutable i_keyHash;
    uint64 public immutable i_subscriptionId;
    uint32 public immutable i_callbackGasLimit = 100000; // Adjust as needed
    uint16 public constant REQUEST_CONFIRMATIONS = 3; // Adjust as needed

    // Mapping request IDs to token IDs
    mapping(uint256 => uint256) public s_requests;
    LinkTokenInterface public s_linkToken;


    // --- Events ---

    event PhoenixMinted(uint256 indexed tokenId, address indexed owner, PhoenixState initialState);
    event PhoenixStateChanged(uint256 indexed tokenId, PhoenixState oldState, PhoenixState newState, uint64 timestamp);
    event PhoenixPropertiesUpdated(uint256 indexed tokenId, uint224 health, uint224 energy, uint224 age);
    event PhoenixAttributesUpdated(uint256 indexed tokenId, uint8 strength, uint8 agility, uint8 intellect, uint8 vitality);
    event PhoenixFed(uint256 indexed tokenId, address indexed feeder, uint256 amount);
    event PhoenixTrained(uint256 indexed tokenId, address indexed trainer, uint256 duration);
    event PhoenixRested(uint256 indexed tokenId, address indexed rester, uint256 duration);
    event GuardianSet(uint256 indexed tokenId, address indexed oldGuardian, address indexed newGuardian);
    event RandomnessRequested(uint256 indexed tokenId, bytes32 indexed requestId);
    event RandomnessFulfilled(uint256 indexed tokenId, bytes32 indexed requestId, uint256 randomWord);
    event PhoenixFused(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newEggTokenId);
    event PhoenixRebirthed(uint256 indexed tokenId, uint256 newEggTokenId); // Rebirth often leads to a new generation/ID conceptually


    // --- Modifiers ---

    modifier onlyPhoenixOwnerOrGuardian(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || _guardians[tokenId] == _msgSender(), "Not owner, approved, or guardian");
        _;
    }

    modifier whenPhoenixStateIs(uint256 tokenId, PhoenixState expectedState) {
        require(_phoenixState[tokenId] == expectedState, "Phoenix is not in the required state");
        _;
    }

    modifier whenPhoenixStateIsNot(uint256 tokenId, PhoenixState excludedState) {
        require(_phoenixState[tokenId] != excludedState, "Phoenix is in an excluded state");
        _;
    }

    // --- Constructor ---

    constructor(address vrfCoordinator, address linkToken, bytes32 keyHash, uint64 subscriptionId)
        ERC721("CryptoPhoenix", "PHX")
        Ownable(msg.sender)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        s_linkToken = LinkTokenInterface(linkToken);
    }

    // --- ERC721 Overrides (Required for ERC721Enumerable and ERC721URIStorage) ---

    function _baseURI() internal view override returns (string memory) {
        // This should point to a service that provides dynamic metadata based on the token ID
        // For this example, we'll return a placeholder.
        // A real implementation would likely point to an API endpoint like https://api.example.com/phoenix/{tokenId}
        return "https://crypto-phoenix-metadata.example.com/token/";
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // The base URI + tokenId results in something like:
        // https://crypto-phoenix-metadata.example.com/token/123
        // This endpoint should dynamically generate metadata (JSON) based on the Phoenix's current state,
        // properties, and attributes queried from the contract via an indexer or direct calls.
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, _toString(tokenId))) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(ERC721Enumerable).interfaceId ||
               interfaceId == type(ERC721URIStorage).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
        // Clear guardian when token is transferred
        if (from != address(0)) {
             _guardians[tokenId] = address(0); // Guardian is tied to ownership
             emit GuardianSet(tokenId, _guardians[tokenId], address(0));
        }
    }

    // The following two are required by ERC721Enumerable.
    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _ownersTokens(address owner) internal view override(ERC721, ERC721Enumerable) returns (uint256[] storage) {
        return super._ownersTokens(owner);
    }


    // --- Core Lifecycle Management ---

    /// @notice Mints a new Phoenix in the Egg state. Only callable by the contract owner.
    /// @param owner The address that will receive the new Egg NFT.
    function mintEgg(address owner) public onlyOwner nonReentrant {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _safeMint(owner, newItemId);

        _phoenixState[newItemId] = PhoenixState.Egg;
        _phoenixProperties[newItemId] = PhoenixProperties({
            health: maxHealth,
            energy: maxEnergy,
            age: 0,
            generation: 1,
            lastInteractionTimestamp: uint64(block.timestamp),
            lastStateChangeTimestamp: uint64(block.timestamp)
        });
        // Attributes are zero initially, set upon hatching via VRF

        emit PhoenixMinted(newItemId, owner, PhoenixState.Egg);
        emit PhoenixStateChanged(newItemId, PhoenixState.Ash, PhoenixState.Egg, uint64(block.timestamp)); // Use Ash as 'null' previous state
    }

    /// @notice Requests randomness from Chainlink VRF to determine attributes for a hatching Egg.
    /// @param tokenId The ID of the Phoenix Egg NFT.
    function requestRandomnessForHatch(uint256 tokenId) public onlyPhoenixOwnerOrGuardian(tokenId) whenPhoenixStateIs(tokenId, PhoenixState.Egg) nonReentrant {
        // Check LINK balance and fund subscription if necessary in a real deployment
        // require(s_linkToken.balanceOf(address(this)) >= VRF_REQUEST_COST, "Not enough LINK to request randomness"); // Example check if paying per request

        uint256 requestId = requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            1 // Request 1 random word
        );
        s_requests[requestId] = tokenId;
        emit RandomnessRequested(tokenId, bytes32(requestId));
    }

    /// @notice VRF Callback function. Sets attributes and hatches the Egg.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords An array containing the requested random words.
    function fulfillRandomness(bytes32 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = s_requests[uint256(requestId)];
        require(tokenId != 0, "Request ID not found");
        delete s_requests[uint256(requestId)];

        uint256 randomWord = randomWords[0];

        // Use the random word to generate attributes (example logic)
        _phoenixAttributes[tokenId] = PhoenixAttributes({
            strength: uint8((randomWord % maxAttribute) + 1), // Attributes 1-maxAttribute
            agility: uint8(((randomWord / maxAttribute) % maxAttribute) + 1),
            intellect: uint8(((randomWord / (maxAttribute * maxAttribute)) % maxAttribute) + 1),
            vitality: uint8(((randomWord / (maxAttribute * maxAttribute * maxAttribute)) % maxAttribute) + 1)
        });

        // Transition state from Egg to Hatchling
        _phoenixState[tokenId] = PhoenixState.Hatchling;
        _phoenixProperties[tokenId].lastStateChangeTimestamp = uint64(block.timestamp);

        emit RandomnessFulfilled(tokenId, requestId, randomWord);
        emit PhoenixAttributesUpdated(tokenId,
            _phoenixAttributes[tokenId].strength,
            _phoenixAttributes[tokenId].agility,
            _phoenixAttributes[tokenId].intellect,
            _phoenixAttributes[tokenId].vitality
        );
        emit PhoenixStateChanged(tokenId, PhoenixState.Egg, PhoenixState.Hatchling, uint64(block.timestamp));
    }

    /// @notice Simulates aging for a Phoenix. Can trigger state transitions and property changes.
    /// @dev This is a simplified model. In a real Dapp, this might be called by an external service,
    ///      triggered by user actions, or based on time elapsed since last age update.
    ///      Repeated calls within a short period will increment age quickly.
    /// @param tokenId The ID of the Phoenix NFT.
    function agePhoenix(uint256 tokenId) public nonReentrant { // Make callable by anyone to progress time, but add rate limiting if needed
        require(_exists(tokenId), "Phoenix does not exist");
        PhoenixState currentState = _phoenixState[tokenId];
        PhoenixProperties storage props = _phoenixProperties[tokenId];

        // Only age if not Ash or Egg (Eggs don't age like living creatures)
        if (currentState == PhoenixState.Ash || currentState == PhoenixState.Egg) {
            return;
        }

        uint64 timeSinceLastInteraction = uint64(block.timestamp) - props.lastInteractionTimestamp;
        uint64 timeSinceLastStateChange = uint64(block.timestamp) - props.lastStateChangeTimestamp;
        uint224 ageIncrease = uint224((timeSinceLastInteraction + timeSinceLastStateChange) / 1 days); // Example: gain 1 age per 2 days of combined inactivity. Adjust logic as needed.
        if (ageIncrease == 0) {
             // Add at least 1 age per call if significant time has passed, e.g., > 1 hour
            if ((timeSinceLastInteraction + timeSinceLastStateChange) > 1 hours) {
                 ageIncrease = 1;
            } else {
                 return; // No significant age change
            }
        }

        props.age += ageIncrease;
        props.lastInteractionTimestamp = uint64(block.timestamp); // Reset timer after aging logic applied

        PhoenixState newState = currentState;
        if (currentState == PhoenixState.Hatchling && props.age >= hatchlingAgeThreshold) {
            newState = PhoenixState.Adult;
        } else if (currentState == PhoenixState.Adult && props.age >= adultAgeThreshold) {
            newState = PhoenixState.Elder;
        } else if (currentState == PhoenixState.Elder && props.age >= elderAgeThreshold) {
            newState = PhoenixState.Ash; // Death by old age!
        }

        // Apply age-related health/energy decay (example: lose health/energy per age unit gained)
        uint224 healthDecay = ageIncrease * 5; // Example decay rate
        uint224 energyDecay = ageIncrease * 3; // Example decay rate

        if (props.health > healthDecay) {
            props.health -= healthDecay;
        } else {
            props.health = 0;
        }
        if (props.energy > energyDecay) {
            props.energy -= energyDecay;
        } else {
            props.energy = 0;
        }


        if (newState != currentState) {
            PhoenixState oldState = currentState;
            _phoenixState[tokenId] = newState;
            props.lastStateChangeTimestamp = uint64(block.timestamp);
            emit PhoenixStateChanged(tokenId, oldState, newState, uint64(block.timestamp));

            // Additional effects on state change (e.g., stat boosts/penalties)
            if (newState == PhoenixState.Ash) {
                 // When a Phoenix turns to Ash, it cannot be interacted with until rebirthed or fused.
                 // Its properties effectively become irrelevant until then.
                 props.health = 0;
                 props.energy = 0;
                 // Attributes might be preserved for fusion/rebirth calculations.
            }
        }

         // Check if vitality causes earlier death (e.g., low health/energy)
        if (newState != PhoenixState.Ash && checkPhoenixVitality(tokenId) < 10) { // Example threshold
             PhoenixState oldState = currentState;
            _phoenixState[tokenId] = PhoenixState.Ash;
            props.lastStateChangeTimestamp = uint64(block.timestamp);
            props.health = 0;
            props.energy = 0;
            emit PhoenixStateChanged(tokenId, oldState, PhoenixState.Ash, uint64(block.timestamp));
        }


        emit PhoenixPropertiesUpdated(tokenId, props.health, props.energy, props.age);
    }

    /// @notice Attempts to fuse two Ash Phoenixes into a new Egg. Requires the owner/guardian of both.
    /// @dev This is a complex process. Requires both Phoenixes to be in the Ash state.
    ///      Burns the two input NFTs and potentially mints a new one with combined/boosted attributes.
    /// @param tokenId1 The ID of the first Phoenix (must be Ash).
    /// @param tokenId2 The ID of the second Phoenix (must be Ash).
    function fusePhoenixes(uint256 tokenId1, uint256 tokenId2) public nonReentrant {
        require(tokenId1 != tokenId2, "Cannot fuse a Phoenix with itself");
        require(_exists(tokenId1), "Phoenix 1 does not exist");
        require(_exists(tokenId2), "Phoenix 2 does not exist");
        require(_isApprovedOrOwner(_msgSender(), tokenId1) || _guardians[tokenId1] == _msgSender(), "Not owner, approved, or guardian of Phoenix 1");
        require(_isApprovedOrOwner(_msgSender(), tokenId2) || _guardians[tokenId2] == _msgSender(), "Not owner, approved, or guardian of Phoenix 2");
        require(_phoenixState[tokenId1] == PhoenixState.Ash, "Phoenix 1 is not in Ash state");
        require(_phoenixState[tokenId2] == PhoenixState.Ash, "Phoenix 2 is not in Ash state");

        // --- Simulated Cost ---
        // In a real contract, this would involve ERC20 transfers or other resource checks
        // Example: Require the sender to transfer fusionCostSimulated amount of a "Spark" token
        // require(sparkToken.transferFrom(msg.sender, address(this), fusionCostSimulated), "Fusion cost payment failed");
        // Or: require(sparkToken.balanceOf(msg.sender) >= fusionCostSimulated, "Not enough Spark tokens");
        // For this example, we just check the concept:
        // require(checkSimulatedResource(msg.sender, fusionCostSimulated), "Simulated fusion cost not met");
        // --- End Simulated Cost ---

        // Burn the two Ash Phoenixes
        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        // Determine recipient of the new egg (e.g., owner of tokenId1, or a new owner?)
        address newEggOwner = owner1; // Example: owner of the first Phoenix gets the egg

        _burn(tokenId1);
        _burn(tokenId2);

        // Mint a new Egg
        _tokenIds.increment();
        uint256 newEggTokenId = _tokenIds.current();
        _safeMint(newEggOwner, newEggTokenId);

        // Inherit/Combine/Boost Attributes (example logic)
        PhoenixAttributes memory attrs1 = _phoenixAttributes[tokenId1];
        PhoenixAttributes memory attrs2 = _phoenixAttributes[tokenId2];

        // Simple average + random boost
        uint8 newStrength = uint8((attrs1.strength + attrs2.strength) / 2);
        uint8 newAgility = uint8((attrs1.agility + attrs2.agility) / 2);
        uint8 newIntellect = uint8((attrs1.intellect + attrs2.intellect) / 2);
        uint8 newVitality = uint8((attrs1.vitality + attrs2.vitality) / 2);

        // Add random boost within a range (requires randomness - potential VRF call here too?)
        // For simplicity in this example, we'll use a deterministic boost or require a separate randomness request *before* calling fuse
        // Example deterministic boost:
        newStrength = newStrength > maxAttribute - fusionMinAttributeBoost ? maxAttribute : newStrength + fusionMinAttributeBoost;
        newAgility = newAgility > maxAttribute - fusionMinAttributeBoost ? maxAttribute : newAgility + fusionMinAttributeBoost;
        newIntellect = newIntellect > maxAttribute - fusionMinAttributeBoost ? maxAttribute : newIntellect + fusionMinAttributeBoost;
        newVitality = newVitality > maxAttribute - fusionMinAttributeBoost ? maxAttribute : newVitality + fusionMinAttributeBoost;
        // Note: A proper implementation might require another VRF request during fusion for a truly random boost.

        _phoenixAttributes[newEggTokenId] = PhoenixAttributes({
            strength: newStrength,
            agility: newAgility,
            intellect: newIntellect,
            vitality: newVitality
        });

        // Set initial properties for the new Egg
        _phoenixState[newEggTokenId] = PhoenixState.Egg;
        _phoenixProperties[newEggTokenId] = PhoenixProperties({
            health: maxHealth,
            energy: maxEnergy,
            age: 0,
            generation: uint8(Math.max(attrs1.generation, attrs2.generation) + 1), // Increment generation
            lastInteractionTimestamp: uint64(block.timestamp),
            lastStateChangeTimestamp: uint64(block.timestamp)
        });

        // Clean up data for burned tokens (though technically not needed as mappings default to zero)
        delete _phoenixState[tokenId1];
        delete _phoenixState[tokenId2];
        delete _phoenixProperties[tokenId1];
        delete _phoenixProperties[tokenId2];
        delete _phoenixAttributes[tokenId1];
        delete _phoenixAttributes[tokenId2];
        delete _guardians[tokenId1];
        delete _guardians[tokenId2];

        emit PhoenixFused(tokenId1, tokenId2, newEggTokenId);
        emit PhoenixMinted(newEggTokenId, newEggOwner, PhoenixState.Egg);
        emit PhoenixStateChanged(newEggTokenId, PhoenixState.Ash, PhoenixState.Egg, uint64(block.timestamp)); // From Ash (conceptually)
        emit PhoenixAttributesUpdated(newEggTokenId, newStrength, newAgility, newIntellect, newVitality);
    }

    /// @notice Attempts to rebirth an Ash Phoenix. Requires the owner/guardian and resources.
    /// @dev Transitions a specific Ash Phoenix back to Egg or Hatchling state with penalties/changes.
    /// @param tokenId The ID of the Phoenix (must be Ash).
    function attemptRebirth(uint256 tokenId) public onlyPhoenixOwnerOrGuardian(tokenId) whenPhoenixStateIs(tokenId, PhoenixState.Ash) nonReentrant {
         // --- Simulated Cost ---
        // In a real contract, this would involve ERC20 transfers or other resource checks
        // Example: Require the sender to transfer rebirthCostSimulated amount of a "Spark" token
        // require(sparkToken.transferFrom(msg.sender, address(this), rebirthCostSimulated), "Rebirth cost payment failed");
        // Or: require(sparkToken.balanceOf(msg.sender) >= rebirthCostSimulated, "Not enough Spark tokens");
        // For this example, we just check the concept:
        // require(checkSimulatedResource(msg.sender, rebirthCostSimulated), "Simulated rebirth cost not met");
        // --- End Simulated Cost ---

        // Rebirth logic:
        // Option 1: Reuse same tokenId, reset state and properties, apply penalties.
        // Option 2: Burn old tokenId, mint new one (like fusion, but single input). This is often cleaner.
        // Let's go with Option 2 for conceptual clarity (simulating a new life, possibly new generation).

        address owner = ownerOf(tokenId);
        PhoenixAttributes memory oldAttrs = _phoenixAttributes[tokenId];
        uint8 oldGeneration = _phoenixProperties[tokenId].generation;

        // Burn the old Ash Phoenix
        _burn(tokenId);

         // Mint a new Egg
        _tokenIds.increment();
        uint256 newEggTokenId = _tokenIds.current();
        _safeMint(owner, newEggTokenId);

        // Apply attribute penalty upon rebirth (example)
        uint8 newStrength = oldAttrs.strength > rebirthAttributePenalty ? oldAttrs.strength - rebirthAttributePenalty : 0;
        uint8 newAgility = oldAttrs.agility > rebirthAttributePenalty ? oldAttrs.agility - rebirthAttributePenalty : 0;
        uint8 newIntellect = oldAttrs.intellect > rebirthAttributePenalty ? oldAttrs.intellect - rebirthAttributePenalty : 0;
        uint8 newVitality = oldAttrs.vitality > rebirthAttributePenalty ? oldAttrs.vitality - rebirthAttributePenalty : 0;

         _phoenixAttributes[newEggTokenId] = PhoenixAttributes({
            strength: newStrength,
            agility: newAgility,
            intellect: newIntellect,
            vitality: newVitality
        });

         // Set initial properties for the new Egg/Hatchling
        _phoenixState[newEggTokenId] = PhoenixState.Egg; // Starts as Egg again
         _phoenixProperties[newEggTokenId] = PhoenixProperties({
            health: maxHealth,
            energy: maxEnergy,
            age: 0,
            generation: oldGeneration + 1, // Increment generation
            lastInteractionTimestamp: uint64(block.timestamp),
            lastStateChangeTimestamp: uint64(block.timestamp)
        });

        // Clean up old token data (already done by _burn conceptually, but explicit mapping deletion is safer)
        delete _phoenixState[tokenId];
        delete _phoenixProperties[tokenId];
        delete _phoenixAttributes[tokenId];
        delete _guardians[tokenId];

        emit PhoenixRebirthed(tokenId, newEggTokenId);
        emit PhoenixMinted(newEggTokenId, owner, PhoenixState.Egg);
        emit PhoenixStateChanged(newEggTokenId, PhoenixState.Ash, PhoenixState.Egg, uint64(block.timestamp)); // From Ash (conceptually)
        emit PhoenixAttributesUpdated(newEggTokenId, newStrength, newAgility, newIntellect, newVitality);
    }


    // --- Interaction Functions ---

    /// @notice Feeds a Phoenix to restore Health and Energy. Requires owner or guardian.
    /// @dev Simulates consumption of a 'Food' token.
    /// @param tokenId The ID of the Phoenix.
    /// @param amount The simulated amount of food used.
    function feedPhoenix(uint256 tokenId, uint256 amount) public onlyPhoenixOwnerOrGuardian(tokenId) whenPhoenixStateIsNot(tokenId, PhoenixState.Egg) whenPhoenixStateIsNot(tokenId, PhoenixState.Ash) nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        // --- Simulated Cost ---
        // In a real contract, this would involve an ERC20 transfer from msg.sender
        // Example: require(foodToken.transferFrom(msg.sender, address(this), amount), "Food cost payment failed");
        // For this example, we just check the concept:
        // require(checkSimulatedResource(msg.sender, amount), "Simulated food cost not met");
        // --- End Simulated Cost ---

        PhoenixProperties storage props = _phoenixProperties[tokenId];
        PhoenixAttributes storage attrs = _phoenixAttributes[tokenId];

        // Health and energy gain (example: scales with amount and vitality)
        uint224 healthGain = uint224(amount * baseHealthGrowthRate * (attrs.vitality + 1) / 100); // Vitality boosts gain
        uint224 energyGain = uint224(amount * baseHealthGrowthRate * (attrs.vitality + 1) / 100);

        props.health = Math.min(props.health + healthGain, maxHealth);
        props.energy = Math.min(props.energy + energyGain, maxEnergy);

        // Small chance of minor attribute boost from good food (example)
        if (amount > 10 && (block.timestamp % 10) < 1) { // ~10% chance if fed enough
             attrs.vitality = Math.min(attrs.vitality + 1, maxAttribute);
             emit PhoenixAttributesUpdated(tokenId, attrs.strength, attrs.agility, attrs.intellect, attrs.vitality);
        }

        props.lastInteractionTimestamp = uint64(block.timestamp);
        emit PhoenixFed(tokenId, _msgSender(), amount);
        emit PhoenixPropertiesUpdated(tokenId, props.health, props.energy, props.age);
    }

    /// @notice Trains a Phoenix to increase attributes. Consumes Energy. Requires owner or guardian.
    /// @param tokenId The ID of the Phoenix.
    /// @param duration The simulated duration/intensity of training (affects energy cost and attribute gain).
    function trainPhoenix(uint256 tokenId, uint256 duration) public onlyPhoenixOwnerOrGuardian(tokenId) whenPhoenixStateIsNot(tokenId, PhoenixState.Egg) whenPhoenixStateIsNot(tokenId, PhoenixState.Ash) nonReentrant {
        require(duration > 0, "Duration must be greater than zero");

        PhoenixProperties storage props = _phoenixProperties[tokenId];
        PhoenixAttributes storage attrs = _phoenixAttributes[tokenId];

        uint256 energyCost = duration * trainingEnergyCost;
        require(props.energy >= energyCost, "Not enough energy to train");

        props.energy -= uint224(energyCost);

        // Attribute gain based on duration and current attributes (example)
        uint8 attributeGain = uint8(duration * trainingAttributeGain);

        // Randomly boost attributes based on training type (example: can choose to focus str, agi, or int)
        // For this simple example, we'll spread the gain
        uint8 gainPerAttribute = attributeGain / 3;
        attrs.strength = Math.min(attrs.strength + gainPerAttribute, maxAttribute);
        attrs.agility = Math.min(attrs.agility + gainPerAttribute, maxAttribute);
        attrs.intellect = Math.min(attrs.intellect + gainPerAttribute, maxAttribute);
        // Vitality isn't directly trained, but might be affected by health/energy levels
        if (checkPhoenixVitality(tokenId) > 50 && duration > 5) { // Example: good vitality and intense training might boost vitality slightly
             attrs.vitality = Math.min(attrs.vitality + 1, maxAttribute);
        }


        props.lastInteractionTimestamp = uint64(block.timestamp);
        emit PhoenixTrained(tokenId, _msgSender(), duration);
        emit PhoenixPropertiesUpdated(tokenId, props.health, props.energy, props.age);
        emit PhoenixAttributesUpdated(tokenId, attrs.strength, attrs.agility, attrs.intellect, attrs.vitality);
    }

    /// @notice Rests a Phoenix to restore Energy over time. Requires owner or guardian.
    /// @dev Duration simulates rest period - longer rest recovers more energy.
    /// @param tokenId The ID of the Phoenix.
    /// @param duration The simulated duration of rest.
    function restPhoenix(uint256 tokenId, uint256 duration) public onlyPhoenixOwnerOrGuardian(tokenId) whenPhoenixStateIsNot(tokenId, PhoenixState.Egg) whenPhoenixStateIsNot(tokenId, PhoenixState.Ash) nonReentrant {
         require(duration > 0, "Duration must be greater than zero");

        PhoenixProperties storage props = _phoenixProperties[tokenId];

        // Energy gain based on duration and current energy level (example: faster recovery when very low energy)
        uint224 energyGain = uint224(duration * baseEnergyRestRate);
        // Add a multiplier based on missing energy (example: recover faster when health/energy is low)
        uint256 recoveryBoost = (maxEnergy - props.energy) / 10; // Example boost calculation
        energyGain += uint224(duration * recoveryBoost / 10);

        props.energy = Math.min(props.energy + energyGain, maxEnergy);

        props.lastInteractionTimestamp = uint64(block.timestamp);
        emit PhoenixRested(tokenId, _msgSender(), duration);
        emit PhoenixPropertiesUpdated(tokenId, props.health, props.energy, props.age);
    }


    // --- Delegation Functions ---

    /// @notice Sets or removes a guardian address for a specific Phoenix.
    /// @dev Only the owner can set/remove a guardian. The guardian can perform interactions (feed, train, rest).
    /// @param tokenId The ID of the Phoenix.
    /// @param guardian The address to set as guardian (address(0) to remove).
    function setGuardian(uint256 tokenId, address guardian) public nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only owner or approved can set guardian");
        address oldGuardian = _guardians[tokenId];
        _guardians[tokenId] = guardian;
        emit GuardianSet(tokenId, oldGuardian, guardian);
    }

    /// @notice Gets the current guardian address for a Phoenix.
    /// @param tokenId The ID of the Phoenix.
    /// @return The guardian address.
    function getGuardian(uint256 tokenId) public view returns (address) {
        return _guardians[tokenId];
    }


    // --- Query/View Functions ---

    /// @notice Gets the current state of a Phoenix.
    /// @param tokenId The ID of the Phoenix.
    /// @return The Phoenix's state enum.
    function getPhoenixState(uint256 tokenId) public view returns (PhoenixState) {
        require(_exists(tokenId), "Phoenix does not exist");
        return _phoenixState[tokenId];
    }

    /// @notice Gets the current properties (Health, Energy, Age, etc.) of a Phoenix.
    /// @param tokenId The ID of the Phoenix.
    /// @return The Phoenix's properties struct.
    function getPhoenixProperties(uint256 tokenId) public view returns (PhoenixProperties memory) {
        require(_exists(tokenId), "Phoenix does not exist");
        return _phoenixProperties[tokenId];
    }

    /// @notice Gets the current attributes (Strength, Agility, etc.) of a Phoenix.
    /// @param tokenId The ID of the Phoenix.
    /// @return The Phoenix's attributes struct.
    function getPhoenixAttributes(uint256 tokenId) public view returns (PhoenixAttributes memory) {
        require(_exists(tokenId), "Phoenix does not exist");
        // Return default attributes if not set (e.g., for Egg)
        if (_phoenixState[tokenId] == PhoenixState.Egg) {
             return PhoenixAttributes(0, 0, 0, 0);
        }
        return _phoenixAttributes[tokenId];
    }

    /// @notice Calculates a simplified vitality score (internal helper).
    /// @dev Can be exposed as external view for debugging/display.
    /// @param tokenId The ID of the Phoenix.
    /// @return A uint256 representing the vitality score.
    function checkPhoenixVitality(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Phoenix does not exist");
        PhoenixProperties storage props = _phoenixProperties[tokenId];
        PhoenixAttributes storage attrs = _phoenixAttributes[tokenId];

        if (_phoenixState[tokenId] == PhoenixState.Ash) return 0;
        if (_phoenixState[tokenId] == PhoenixState.Egg) return 100; // Eggs are peak potential

        // Example vitality calculation: Weighted average of health, energy, vitality attribute, and age penalty
        uint256 vitalityScore = (props.health * 20 / maxHealth) + // Up to 20
                                (props.energy * 15 / maxEnergy) + // Up to 15
                                (attrs.vitality * 50 / maxAttribute); // Up to 50

        // Apply age penalty (more penalty as they get older)
        if (props.age > hatchlingAgeThreshold) { // Apply penalty after Hatchling phase
            uint256 agePenalty = (props.age - hatchlingAgeThreshold) * 10 / (elderAgeThreshold - hatchlingAgeThreshold + 1); // Example scaling
            if (vitalityScore > agePenalty) {
                 vitalityScore -= agePenalty;
            } else {
                 vitalityScore = 0;
            }
        }

        return vitalityScore; // Max possible score roughly 20+15+50 = 85 before age penalty
    }

    /// @notice Provides information on the requirements to fuse two specific Phoenixes.
    /// @param tokenId1 The ID of the first Phoenix.
    /// @param tokenId2 The ID of the second Phoenix.
    /// @return isPossible Whether fusion is currently possible.
    /// @return requirementDetails A string describing why or why not, and costs.
    function getFusionRequirements(uint256 tokenId1, uint256 tokenId2) public view returns (bool isPossible, string memory requirementDetails) {
         if (tokenId1 == tokenId2) return (false, "Cannot fuse with self");
        if (!_exists(tokenId1) || !_exists(tokenId2)) return (false, "One or both Phoenixes do not exist");
        if (_phoenixState[tokenId1] != PhoenixState.Ash || _phoenixState[tokenId2] != PhoenixState.Ash) return (false, "Both Phoenixes must be in Ash state");
        // Check ownership/guardianship - done in fusePhoenixes, but can add a check here for clarity
         if (!_isApprovedOrOwner(_msgSender(), tokenId1) && _guardians[tokenId1] != _msgSender()) return (false, "Not owner/guardian of Phoenix 1");
         if (!_isApprovedOrOwner(_msgSender(), tokenId2) && _guardians[tokenId2] != _msgSender()) return (false, "Not owner/guardian of Phoenix 2");

        // Add check for simulated resource if needed:
        // if (!checkSimulatedResource(msg.sender, fusionCostSimulated)) return (false, string(abi.encodePacked("Requires ", _toString(fusionCostSimulated), " simulated resource")));


        return (true, string(abi.encodePacked("Requires both in Ash state. Simulated cost: ", _toString(fusionCostSimulated), ".")));
    }

    /// @notice Provides information on the requirements to rebirth a specific Phoenix.
    /// @param tokenId The ID of the Phoenix.
    /// @return isPossible Whether rebirth is currently possible.
    /// @return requirementDetails A string describing why or why not, and costs.
    function getRebirthRequirements(uint256 tokenId) public view returns (bool isPossible, string memory requirementDetails) {
        if (!_exists(tokenId)) return (false, "Phoenix does not exist");
        if (_phoenixState[tokenId] != PhoenixState.Ash) return (false, "Phoenix must be in Ash state");
         if (!_isApprovedOrOwner(_msgSender(), tokenId) && _guardians[tokenId] != _msgSender()) return (false, "Not owner/guardian");

        // Add check for simulated resource if needed:
        // if (!checkSimulatedResource(msg.sender, rebirthCostSimulated)) return (false, string(abi.encodePacked("Requires ", _toString(rebirthCostSimulated), " simulated resource")));


        return (true, string(abi.encodePacked("Requires Ash state. Simulated cost: ", _toString(rebirthCostSimulated), ". Rebirth penalty: ", _toString(rebirthAttributePenalty), " attribute points.")));
    }


    // --- Admin/Parameter Functions ---

    /// @notice Admin function to set base rates for health/energy growth and attribute gain.
    function setBaseGrowthRates(uint256 _baseHealthGrowth, uint256 _baseEnergyRest, uint256 _trainingAttributeGain) public onlyOwner {
        baseHealthGrowthRate = _baseHealthGrowth;
        baseEnergyRestRate = _baseEnergyRest;
        trainingAttributeGain = _trainingAttributeGain;
    }

    /// @notice Admin function to set consumption rates for actions.
    function setConsumptionRates(uint256 _trainingEnergyCost) public onlyOwner {
        trainingEnergyCost = _trainingEnergyCost;
    }

    /// @notice Admin function to set the age thresholds for state transitions.
    function setAgeThresholds(uint224 _hatchlingAge, uint224 _adultAge, uint224 _elderAge) public onlyOwner {
         require(_hatchlingAge < _adultAge && _adultAge < _elderAge, "Age thresholds must be increasing");
        hatchlingAgeThreshold = _hatchlingAge;
        adultAgeThreshold = _adultAge;
        elderAgeThreshold = _elderAge;
    }

    /// @notice Admin function to configure Chainlink VRF settings.
    function setOracleConfig(address vrfCoordinator, address linkToken, bytes32 keyHash, uint64 subscriptionId) public onlyOwner {
        // Need to re-initialize VRFConsumerBaseV2 if coordinator changes.
        // For simplicity here, we assume coordinator doesn't change often.
        // A more robust approach might involve an upgrade pattern or a dedicated config struct.
        i_keyHash = keyHash; // Note: immutable can only be set in constructor, this would need state variables.
        // Making i_keyHash mutable state variable for this function to work.
        // Same for i_subscriptionId, i_callbackGasLimit, s_linkToken.
        // bytes32 public s_keyHash;
        // uint64 public s_subscriptionId;
        // uint32 public s_callbackGasLimit;
        // s_keyHash = keyHash;
        // s_subscriptionId = subscriptionId;
        // s_callbackGasLimit = callbackGasLimit; // Need to add this state variable if needed.
        s_linkToken = LinkTokenInterface(linkToken);

         // Revert VRFConsumerBaseV2 initialization if changing coordinator
        // VRFConsumerBaseV2.reInit(vrfCoordinator); // This method does not exist, requires custom handling or upgrade.

        revert("Setting Oracle Config after deployment requires mutable VRF parameters. This function is illustrative.");
        // A safer pattern is to set these via constructor or have state variables instead of immutable.
    }

    // --- Internal/Helper Functions (if any) ---

    /// @dev This is a placeholder function to simulate resource requirements.
    /// In a real Dapp, this would check ERC20 balance, transfer tokens, etc.
    function checkSimulatedResource(address user, uint256 amount) internal pure returns (bool) {
        // Example: return user has enough of a specific token or ether
        // return IERC20(FOOD_TOKEN_ADDRESS).balanceOf(user) >= amount;
        // Or check if the user has approved this contract to spend tokens
        // return IERC20(FOOD_TOKEN_ADDRESS).allowance(user, address(this)) >= amount;
        // For this example, always return true to allow the logic to proceed conceptually.
        user; // avoid unused warning
        amount; // avoid unused warning
        return true;
    }

    // Required by VRFConsumerBaseV2 - just providing an empty implementation if not used elsewhere
    // function rawFulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) internal override {
    //    fulfillRandomness(requestId, randomWords); // Call our specific handler
    // }
     // ^ The above is not needed, fulfillRandomness is the required override.

     // Helper function to convert uint256 to string (used in getRequirements)
    function _toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// A placeholder for the Math library if not using a standard one like OpenZeppelin's SafeMath or a custom one.
// For Solidity 0.8+, standard arithmetic checks for overflow/underflow are built-in.
// We need Math.max for the fusion generation calculation. OpenZeppelin's `SafeCast` or `Math` could be used.
// Using a simple manual max here for demonstration if OZ Math is not imported explicitly for this func.
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
     function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }
     function min(uint224 a, uint224 b) internal pure returns (uint224) {
        return a <= b ? a : b;
    }
     function min(uint8 a, uint8 b) internal pure returns (uint8) {
        return a <= b ? a : b;
    }
}

```

**Explanation and Further Considerations:**

1.  **Complexity:** This contract integrates ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard, and Chainlink VRF. It manages multiple states and complex structs, with functions that interact across these data structures. The logic for aging, feeding, training, fusion, and rebirth provides depth.
2.  **Dynamic Metadata (`tokenURI`):** The `tokenURI` function is crucial for dynamic NFTs. It doesn't return the JSON directly but points to a URL. A separate service would run off-chain, listen for contract events, query the contract state via RPC, and serve the metadata JSON dynamically for each token ID. This JSON would include the current state, properties, and attributes.
3.  **Aging Mechanism (`agePhoenix`):** The current `agePhoenix` function is simplified. In a production system, triggering this reliably and fairly for all tokens is a challenge. Options include:
    *   **External Keeper:** A trusted service or Chainlink Keeper calls `agePhoenix` periodically for eligible tokens.
    *   **User Triggered:** Users call it, perhaps incentivized, but might lead to uneven aging.
    *   **Time-Based Calculation in Getters:** Properties like age, health, and energy could be calculated *on the fly* in view functions based on time elapsed since the last state change or interaction. This avoids needing a trigger but makes getter functions more complex and state updates less explicit.
    *   **Batch Processing:** An admin or keeper calls a function that ages a batch of Phoenixes.
4.  **Token Interaction:** The `feedPhoenix`, `fusePhoenixes`, and `attemptRebirth` functions include comments about "Simulated Cost." In a real Dapp, you would deploy an ERC20 "Food" or "Spark" token and integrate its contract, requiring users to approve this `CryptoPhoenix` contract to spend their tokens or using `transferFrom`.
5.  **Chainlink VRF:** Requires setting up a Chainlink VRF Subscription and funding it with LINK. The `fulfillRandomness` function is the callback from the VRF Coordinator. Attributes are set upon this callback, completing the hatching process.
6.  **Gas Costs:** Complex functions like `fusePhoenixes` and `attemptRebirth` involve multiple state writes (burning, minting, deleting mappings, updating state/properties) and will have significant gas costs.
7.  **Edge Cases & Refinements:** This is a foundational example. A production contract would require:
    *   More robust error handling and input validation.
    *   Detailed balancing of property changes, costs, and gains.
    *   Consideration of how attributes affect gameplay/utility.
    *   Potential for pausing the contract.
    *   More sophisticated attribute generation or combination logic in fusion/rebirth.
    *   Handling potential VRF call failures or delays.

This contract provides a solid framework for a dynamic NFT project with several advanced concepts, going well beyond a standard static collectible or simple game asset.