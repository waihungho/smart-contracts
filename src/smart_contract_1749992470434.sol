Okay, let's design an interesting, advanced, and creative smart contract. We'll create an "Evolving NFT" contract where NFTs have on-chain attributes, can level up/evolve through defined stages based on certain conditions (like time elapsed, staking duration, or consuming certain "feed" tokens), and whose metadata (`tokenURI`) is intended to be dynamic based on its state.

This concept incorporates:
1.  **Dynamic/Evolving State:** NFTs are not static.
2.  **On-Chain Attributes:** Storing mutable data directly in the contract.
3.  **State Machine:** The NFT progresses through defined evolution stages.
4.  **Condition-Based Evolution:** Evolution requires meeting specific criteria (time, staking, external interaction).
5.  **Interaction/Gamification:** `feedNFT`, `stakeNFT` functions.
6.  **Modular Configuration:** Evolution stages and requirements are configurable by the owner.
7.  **Fee Mechanism:** Optional fees for triggering evolution.
8.  **Trait Mapping:** A way to potentially map on-chain attributes to off-chain visual traits.

It avoids simple duplications like basic ERC-20/721/1155 templates or standard marketplace/staking contracts by combining these elements into a single NFT's lifecycle management.

---

**Outline and Function Summary: EvolvingNFTs Contract**

This contract implements an ERC-721 non-fungible token with dynamic attributes and an evolution mechanism. NFTs can progress through predefined stages based on configurable requirements.

**Contract Name:** `EvolvingNFTs`
**Inherits:** ERC721, Ownable, Pausable, ReentrancyGuard

**Key Concepts:**
*   **Attributes:** On-chain mutable key-value pairs associated with each NFT.
*   **Evolution Stages:** A sequence of predefined stages an NFT can reach.
*   **Evolution State:** The current state of an NFT regarding evolution (Idle, ReadyForEvolution, Evolved).
*   **Evolution Requirements:** Conditions (time, staking, attributes) required to move to the *next* evolution stage.
*   **Dynamic Metadata:** The `tokenURI` is intended to reflect the current evolution stage and attributes.

**Data Structures:**
*   `Attributes`: struct mapping string keys to uint256 values.
*   `EvolutionRequirements`: struct defining conditions (min time held, min staked duration, required attributes, required feed count).
*   `EvolutionStageDetails`: struct defining stage name, max attributes, and associated URI suffix.
*   `EvolutionState`: enum representing the evolution status of a token.

**State Variables:**
*   `_tokenIdCounter`: Counter for minting new tokens.
*   `_attributes`: Mapping `tokenId -> Attributes`.
*   `_evolutionState`: Mapping `tokenId -> EvolutionState`.
*   `_currentEvolutionStage`: Mapping `tokenId -> uint8` (index of current stage).
*   `_evolutionStages`: Array of `EvolutionStageDetails`.
*   `_evolutionRequirements`: Mapping `stageIndex -> EvolutionRequirements`.
*   `_baseTokenURI`: Base URI for metadata.
*   `_traitMapping`: Mapping `string traitName -> uint256 attributeIndex` (for potential off-chain mapping).
*   `_evolutionTriggerFee`: Fee required to *attempt* evolution.
*   `_feeReceiver`: Address to receive fees.
*   `_lastEvolutionAttemptTime`: Mapping `tokenId -> uint256` (timestamp of last attempt).
*   `_stakedTokens`: Mapping `tokenId -> uint256` (timestamp when staked).
*   `_feedCount`: Mapping `tokenId -> uint256` (number of times fed).

**Functions (Total: 30+):**

**ERC-721 & Basic:**
1.  `constructor()`: Initializes the contract with name, symbol, fee receiver.
2.  `tokenURI(uint256 tokenId)`: **Override** - Returns the dynamic token URI based on the NFT's state and stage. (Internal helper `_generateMetadataURI` would likely be used off-chain, but this function provides the hook).
3.  `totalSupply()`: Returns the total number of NFTs minted. (Inherited from ERC721Enumerable, if used, or custom counter).
4.  `burn(uint256 tokenId)`: Destroys an NFT.
5.  `pause()`: Pauses transfers and certain functions (Owner only).
6.  `unpause()`: Unpauses the contract (Owner only).

**Minting:**
7.  `mint(address to)`: Mints a new token with default initial attributes and stage.
8.  `batchMint(address to, uint256 count)`: Mints multiple tokens to an address.
9.  `mintWithInitialDNA(address to, uint256 initialDNA)`: Mints a token with a seed `initialDNA` which *could* influence starting attributes (implementation detail for off-chain art/on-chain attribute derivation).

**Attributes:**
10. `getAttributes(uint256 tokenId)`: Returns the current attributes of an NFT.
11. `setAttribute(uint256 tokenId, string calldata key, uint256 value)`: **Admin/Internal Only** - Sets a specific attribute for a token. (Used internally by evolution or admin).
12. `adminSetAttributes(uint256 tokenId, string[] calldata keys, uint256[] calldata values)`: Allows owner to set multiple attributes for an NFT.

**Evolution Mechanism:**
13. `addEvolutionStage(string calldata name, uint256 maxAttributes, string calldata uriSuffix)`: Adds a new evolution stage (Owner only).
14. `updateEvolutionStage(uint8 stageIndex, string calldata name, uint256 maxAttributes, string calldata uriSuffix)`: Updates details of an existing stage (Owner only).
15. `setEvolutionRequirements(uint8 stageIndex, EvolutionRequirements calldata reqs)`: Sets requirements for evolving *to* a specific stage (Owner only).
16. `getEvolutionStageDetails(uint8 stageIndex)`: Returns details of a specific evolution stage.
17. `getEvolutionRequirements(uint8 stageIndex)`: Returns requirements for a specific evolution stage.
18. `requestEvolution(uint256 tokenId)`: User-facing function to initiate the evolution process. May require a fee. Sets state to `ReadyForEvolution`.
19. `processEvolution(uint256 tokenId)`: **Internal/Admin Callable** - Checks requirements and applies evolution effects if met. Changes stage and attributes.
20. `canEvolve(uint256 tokenId)`: Checks if an NFT meets the requirements to evolve to the next stage.
21. `adminForceEvolve(uint256 tokenId)`: Allows owner to force an NFT to the next stage, bypassing requirements.
22. `adminSetEvolutionState(uint256 tokenId, EvolutionState state)`: Allows owner to set the evolution state (e.g., back to Idle, or directly to Evolved).
23. `getEvolutionState(uint256 tokenId)`: Returns the current evolution state of an NFT.
24. `getEvolutionStage(uint256 tokenId)`: Returns the index of the current evolution stage of an NFT.

**Interaction / Gamification:**
25. `stakeNFT(uint256 tokenId)`: Locks an NFT to the contract, recording the stake time.
26. `unstakeNFT(uint256 tokenId)`: Unlocks a staked NFT.
27. `isStaked(uint256 tokenId)`: Checks if an NFT is currently staked.
28. `getStakedTimestamp(uint256 tokenId)`: Returns the timestamp when an NFT was staked.
29. `feedNFT(uint256 tokenId)`: Simulates feeding the NFT, potentially incrementing a feed counter used in evolution requirements.

**Configuration & Fees:**
30. `setBaseTokenURI(string calldata uri)`: Sets the base URI for metadata (Owner only).
31. `setEvolutionTriggerFee(uint256 fee)`: Sets the fee for requesting evolution (Owner only).
32. `getEvolutionTriggerFee()`: Returns the current evolution trigger fee.
33. `withdrawFees()`: Allows the fee receiver to withdraw collected fees (Fee Receiver only).
34. `setFeeReceiver(address receiver)`: Sets the fee receiver address (Owner only).
35. `setTraitMapping(string calldata traitName, uint256 attributeIndex)`: Sets a mapping between a trait name (for metadata) and an attribute index (Owner only).
36. `getTraitMapping(string calldata traitName)`: Returns the attribute index mapped to a trait name.

**Internal Helpers:**
*   `_generateMetadataURI(uint256 tokenId)`: Internal logic to construct the dynamic URI. (Likely points to an off-chain service).
*   `_canEvolve(uint256 tokenId)`: Internal helper for `canEvolve`.
*   `_applyEvolutionEffects(uint256 tokenId, uint8 nextStageIndex)`: Internal logic to update state, stage, and potentially attributes upon successful evolution.
*   `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Override to prevent transfer of staked tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary: EvolvingNFTs Contract
// This contract implements an ERC-721 non-fungible token with dynamic attributes and an evolution mechanism.
// NFTs can progress through predefined stages based on configurable requirements (time, staking, feeding, attributes).
// The tokenURI is intended to reflect the current stage and attributes.

// Key Concepts: Dynamic State, On-Chain Attributes, State Machine, Condition-Based Evolution, Gamification, Configurable Stages, Fees.

// Data Structures:
// - Attributes: struct mapping string keys to uint256 values (simplified as mapping for demonstration).
// - EvolutionRequirements: struct defining conditions (min time held, min staked duration, required attributes, required feed count).
// - EvolutionStageDetails: struct defining stage name, max attributes allowed, and associated URI suffix.
// - EvolutionState: enum representing the evolution status of a token.

// State Variables:
// - _tokenIdCounter: Auto-incrementing counter for tokens.
// - _attributes: Mapping tokenId -> Attributes (simplified for demonstration).
// - _evolutionState: Mapping tokenId -> EvolutionState.
// - _currentEvolutionStage: Mapping tokenId -> uint8 (index of current stage).
// - _evolutionStages: Array of EvolutionStageDetails.
// - _evolutionRequirements: Mapping stageIndex -> EvolutionRequirements.
// - _baseTokenURI: Base URI for metadata service.
// - _traitMapping: Mapping string traitName -> uint256 attributeIndex (for off-chain mapping).
// - _evolutionTriggerFee: Fee to initiate evolution request.
// - _feeReceiver: Address for fees.
// - _lastEvolutionAttemptTime: Mapping tokenId -> timestamp of last attempt.
// - _stakedTokens: Mapping tokenId -> timestamp when staked (0 if not staked).
// - _feedCount: Mapping tokenId -> uint256 (number of times fed).

// Functions (Total: 36):
// ERC-721 & Basic:
// 1. constructor(string, string, address)
// 2. tokenURI(uint256) (Override)
// 3. totalSupply() (Via Counters.sol)
// 4. burn(uint256)
// 5. pause() (Owner)
// 6. unpause() (Owner)

// Minting:
// 7. mint(address) (Owner)
// 8. batchMint(address, uint256) (Owner)
// 9. mintWithInitialDNA(address, uint256) (Owner - DNA influences initial attributes)

// Attributes:
// 10. getAttributes(uint256)
// 11. setAttribute(uint256, string, uint256) (Internal/Admin helper)
// 12. adminSetAttributes(uint256, string[], uint256[]) (Owner)

// Evolution Mechanism:
// 13. addEvolutionStage(string, uint256, string) (Owner)
// 14. updateEvolutionStage(uint8, string, uint256, string) (Owner)
// 15. setEvolutionRequirements(uint8, EvolutionRequirements) (Owner)
// 16. getEvolutionStageDetails(uint8)
// 17. getEvolutionRequirements(uint8)
// 18. requestEvolution(uint256) (User-facing, potentially pays fee)
// 19. processEvolution(uint256) (Internal/Admin - applies effects)
// 20. canEvolve(uint256) (User query)
// 21. adminForceEvolve(uint256) (Owner)
// 22. adminSetEvolutionState(uint256, EvolutionState) (Owner)
// 23. getEvolutionState(uint256)
// 24. getEvolutionStage(uint256)

// Interaction / Gamification:
// 25. stakeNFT(uint256)
// 26. unstakeNFT(uint256)
// 27. isStaked(uint256)
// 28. getStakedTimestamp(uint256)
// 29. feedNFT(uint256)

// Configuration & Fees:
// 30. setBaseTokenURI(string) (Owner)
// 31. setEvolutionTriggerFee(uint256) (Owner)
// 32. getEvolutionTriggerFee()
// 33. withdrawFees() (Fee Receiver)
// 34. setFeeReceiver(address) (Owner)
// 35. setTraitMapping(string, uint256) (Owner)
// 36. getTraitMapping(string)

// Internal Helpers:
// - _generateMetadataURI(uint256) (Internal logic for tokenURI)
// - _canEvolve(uint256) (Internal helper for canEvolve)
// - _applyEvolutionEffects(uint256, uint8) (Internal logic for evolution effects)
// - _beforeTokenTransfer(address, address, uint256) (Override for staking check)

contract EvolvingNFTs is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For simple arithmetic like fee calculation

    Counters.Counter private _tokenIdCounter;

    // Simplified Attributes: Using a fixed-size array for demonstration.
    // A real implementation might use a more dynamic or structured approach.
    uint256 internal constant MAX_ATTRIBUTE_SLOTS = 10; // Max number of attribute slots per NFT
    mapping(uint256 => uint256[MAX_ATTRIBUTE_SLOTS]) private _attributes;
    mapping(string => uint256) private _traitMapping; // Maps trait name (for URI) to attribute slot index

    enum EvolutionState {
        Idle, // Not currently evolving or ready
        ReadyForEvolution, // Requirements potentially met, pending processing
        Evolved // Reached final stage (or some evolved state)
    }

    struct EvolutionRequirements {
        uint64 minTimeHeldSeconds;
        uint64 minStakedDurationSeconds;
        uint256 requiredFeedCount;
        uint256[MAX_ATTRIBUTE_SLOTS] minAttributeValues; // Minimum required values for attributes
    }

    struct EvolutionStageDetails {
        string name;
        uint256 maxAttributesAllowed; // Max number of attributes relevant for this stage's metadata/logic
        string uriSuffix; // Suffix for the tokenURI specific to this stage
    }

    mapping(uint256 => EvolutionState) private _evolutionState;
    mapping(uint256 => uint8) private _currentEvolutionStage; // 0-indexed stage
    EvolutionStageDetails[] private _evolutionStages;
    mapping(uint8 => EvolutionRequirements) private _evolutionRequirements; // Requirements to reach *this* stage (index)

    string private _baseTokenURI;
    uint256 private _evolutionTriggerFee;
    address payable private _feeReceiver;

    mapping(uint256 => uint256) private _lastEvolutionAttemptTime; // Timestamp of last request
    mapping(uint256 => uint256) private _stakedTokens; // tokenId => timestamp, 0 if not staked
    mapping(uint256 => uint256) private _feedCount; // tokenId => count

    // Errors
    error EvolvingNFTs__NotOwnerOfToken(uint256 tokenId, address caller);
    error EvolvingNFTs__InvalidStageIndex(uint8 stageIndex);
    error EvolvingNFTs__StageRequirementsNotSet(uint8 stageIndex);
    error EvolvingNFTs__EvolutionRequirementsNotMet(uint256 tokenId);
    error EvolvingNFTs__EvolutionAlreadyComplete(uint256 tokenId);
    error EvolvingNFTs__EvolutionNotRequested(uint256 tokenId);
    error EvolvingNFTs__FeeNotMet(uint256 tokenId, uint256 requiredFee);
    error EvolvingNFTs__TokenAlreadyStaked(uint256 tokenId);
    error EvolvingNFTs__TokenNotStaked(uint256 tokenId);
    error EvolvingNFTs__StageAttributeLimitExceeded(uint8 stageIndex, uint256 currentAttributes, uint256 maxAttributes);
    error EvolvingNFTs__InsufficientFeesCollected();
    error EvolvingNFTs__InvalidAttributeIndex(uint256 attributeIndex);
    error EvolvingNFTs__AttributeArrayLengthMismatch();

    event NFTMinted(uint256 indexed tokenId, address indexed owner, uint256 initialDNA);
    event NFTAttributesUpdated(uint256 indexed tokenId, string[] keys, uint256[] values);
    event EvolutionStageAdded(uint8 indexed stageIndex, string name);
    event EvolutionStageUpdated(uint8 indexed stageIndex, string name);
    event EvolutionRequirementsSet(uint8 indexed stageIndex);
    event EvolutionRequested(uint256 indexed tokenId, uint256 feePaid);
    event NFTProcessedForEvolution(uint256 indexed tokenId, bool success, uint8 newStageIndex);
    event NFTStaked(uint256 indexed tokenId, uint256 timestamp);
    event NFTUnstaked(uint256 indexed tokenId, uint256 timestamp);
    event NFTFed(uint256 indexed tokenId, uint256 newFeedCount);
    event EvolutionTriggerFeeUpdated(uint256 newFee);
    event BaseTokenURIUpdated(string uri);
    event TraitMappingUpdated(string traitName, uint256 attributeIndex);
    event FeesWithdrawn(address indexed receiver, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        address payable feeReceiver
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        require(feeReceiver != address(0), "Invalid fee receiver");
        _feeReceiver = feeReceiver;

        // Add a default initial stage (Stage 0)
        addEvolutionStage("Initial", 5, "initial/"); // Default initial stage
    }

    // --- ERC-721 Overrides ---

    /// @dev See {ERC721-tokenURI}. Dynamically generates URI based on state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensures token exists and caller might be owner

        // Construct the URI pointing to an external metadata service.
        // The service will query this contract's state (stage, attributes)
        // and generate the appropriate JSON metadata and image URL.
        uint8 stageIndex = _currentEvolutionStage[tokenId];
        string memory stageSuffix = "";
        if (stageIndex < _evolutionStages.length) {
            stageSuffix = _evolutionStages[stageIndex].uriSuffix;
        }

        // Example: baseURI/stageSuffix/tokenId
        // An off-chain service at baseURI would interpret the path.
        // e.g., https://myevolvingnft.com/metadata/initial/123
        // or https://myevolvingnft.com/metadata/stage1/456
        return string.concat(_baseTokenURI, stageSuffix, toString(tokenId));
    }

    /// @dev Burns a specific token.
    function burn(uint256 tokenId) public payable {
        // Check if the caller is the owner or approved
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");

        // Ensure token is not staked before burning
        if (_stakedTokens[tokenId] != 0) {
            revert EvolvingNFTs__TokenAlreadyStaked(tokenId); // Or add an admin function to force unstake/burn
        }

        _burn(tokenId);

        // Clean up storage associated with the token
        delete _attributes[tokenId];
        delete _evolutionState[tokenId];
        delete _currentEvolutionStage[tokenId];
        delete _lastEvolutionAttemptTime[tokenId];
        delete _feedCount[tokenId];

        // Note: _stakedTokens[tokenId] is checked above and implicitly handled by delete if unstaked
    }

    /// @dev Pauses transfers and most state-changing operations.
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Minting Functions ---

    /// @dev Mints a new token to the specified address.
    function mint(address to) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        _evolutionState[newItemId] = EvolutionState.Idle;
        _currentEvolutionStage[newItemId] = 0; // Start at stage 0
        // Initial attributes are all 0 by default for the simplified mapping.
        // Can be set immediately after minting if needed.
        emit NFTMinted(newItemId, to, 0); // No DNA used in this simple mint
        return newItemId;
    }

    /// @dev Mints multiple tokens to the specified address.
    function batchMint(address to, uint256 count) public onlyOwner whenNotPaused {
        require(count > 0, "Cannot mint 0 tokens");
        for (uint256 i = 0; i < count; i++) {
            mint(to); // Reuses the single mint logic
        }
    }

    /// @dev Mints a token with an initial DNA seed. This seed is not used in the on-chain attributes here,
    /// but could be used by the off-chain metadata service or future contract logic
    /// to determine initial appearance or hidden traits derived from the DNA.
    function mintWithInitialDNA(address to, uint256 initialDNA) public onlyOwner whenNotPaused returns (uint256) {
         _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        _evolutionState[newItemId] = EvolutionState.Idle;
        _currentEvolutionStage[newItemId] = 0; // Start at stage 0
        // initialDNA itself is not stored on-chain in this minimal example,
        // but it's passed in the event for external listeners.
        // You could potentially derive and set some initial attributes here based on DNA.
        emit NFTMinted(newItemId, to, initialDNA);
        return newItemId;
    }


    // --- Attribute Functions ---

    /// @dev Gets the attributes of a specific token.
    function getAttributes(uint256 tokenId) public view returns (uint256[MAX_ATTRIBUTE_SLOTS] memory) {
        _requireOwned(tokenId);
        return _attributes[tokenId];
    }

    /// @dev Internal helper to set an attribute by its index (slot).
    /// @param tokenId The token ID.
    /// @param attributeIndex The index of the attribute slot (0 to MAX_ATTRIBUTE_SLOTS - 1).
    /// @param value The new value for the attribute.
    function _setAttribute(uint256 tokenId, uint256 attributeIndex, uint256 value) internal {
        if (attributeIndex >= MAX_ATTRIBUTE_SLOTS) {
            revert EvolvingNFTs__InvalidAttributeIndex(attributeIndex);
        }
         uint8 currentStage = _currentEvolutionStage[tokenId];
         if (currentStage >= _evolutionStages.length) revert EvolvingNFTs__InvalidStageIndex(currentStage);
         if (attributeIndex >= _evolutionStages[currentStage].maxAttributesAllowed) {
              revert EvolvingNFTs__StageAttributeLimitExceeded(currentStage, attributeIndex, _evolutionStages[currentStage].maxAttributesAllowed);
         }

        _attributes[tokenId][attributeIndex] = value;
        // Emit event with placeholder keys/values as we don't have string keys on-chain here easily.
        // A real implementation might pass the index and value directly.
        string[] memory keys = new string[](1);
        uint256[] memory values = new uint256[](1);
        keys[0] = string.concat("Attribute", toString(attributeIndex));
        values[0] = value;
        emit NFTAttributesUpdated(tokenId, keys, values);
    }


    /// @dev Allows the owner to set multiple attributes for a token.
    /// This is a powerful admin tool and should be used carefully.
    /// Expects keys to correspond to indices set via `setTraitMapping`.
    function adminSetAttributes(uint256 tokenId, string[] calldata keys, uint256[] calldata values) public onlyOwner whenNotPaused {
        _requireOwned(tokenId);
        if (keys.length != values.length) {
            revert EvolvingNFTs__AttributeArrayLengthMismatch();
        }
        uint8 currentStage = _currentEvolutionStage[tokenId];
         if (currentStage >= _evolutionStages.length) revert EvolvingNFTs__InvalidStageIndex(currentStage);


        for (uint i = 0; i < keys.length; i++) {
            uint256 attributeIndex = _traitMapping[keys[i]];
            if (attributeIndex == 0 && bytes(keys[i]).length > 0) {
                 // If mapping not found, potentially revert or ignore based on policy.
                 // Reverting is safer to prevent setting attributes to slot 0 accidentally if mapping is missing.
                 // A mapping value of 0 is ambiguous if 0 is a valid attribute index.
                 // Better approach: mapping(string => uint256) attributeNameToIndex;
                 // For this simplified version, we rely on _traitMapping having non-zero values for valid indices.
                 // Let's assume _traitMapping stores 1-based index and we subtract 1 internally.
                 // Or, better, use a different sentinel value than 0 for 'not found'. Let's use a large value.
                 uint256 mappedIndex = _traitMapping[keys[i]];
                 if (mappedIndex == 0 && bytes(keys[i]).length > 0) revert EvolvingNFTs__InvalidAttributeIndex(type(uint256).max); // Indicate mapping not found
                 attributeIndex = mappedIndex - 1; // Assuming 1-based mapping for clarity

            } else if (bytes(keys[i]).length == 0 && attributeIndex == 0) {
                // Handle case where mapping was set for empty string key -> index 0 explicitly, if needed
                 attributeIndex = 0;
            }

            if (attributeIndex >= MAX_ATTRIBUTE_SLOTS) {
                 revert EvolvingNFTs__InvalidAttributeIndex(attributeIndex);
            }
             if (attributeIndex >= _evolutionStages[currentStage].maxAttributesAllowed) {
                revert EvolvingNFTs__StageAttributeLimitExceeded(currentStage, attributeIndex, _evolutionStages[currentStage].maxAttributesAllowed);
            }
            _attributes[tokenId][attributeIndex] = values[i];
        }
        emit NFTAttributesUpdated(tokenId, keys, values);
    }


    // --- Evolution Mechanism ---

    /// @dev Adds a new evolution stage. Must be added in order.
    function addEvolutionStage(string calldata name, uint256 maxAttributes, string calldata uriSuffix) public onlyOwner {
        require(maxAttributes <= MAX_ATTRIBUTE_SLOTS, "Max attributes exceeds contract limit");
        _evolutionStages.push(EvolutionStageDetails(name, maxAttributes, uriSuffix));
        emit EvolutionStageAdded(uint8(_evolutionStages.length - 1), name);
    }

    /// @dev Updates an existing evolution stage's details.
    function updateEvolutionStage(uint8 stageIndex, string calldata name, uint256 maxAttributes, string calldata uriSuffix) public onlyOwner {
        if (stageIndex >= _evolutionStages.length) {
            revert EvolvingNFTs__InvalidStageIndex(stageIndex);
        }
         require(maxAttributes <= MAX_ATTRIBUTE_SLOTS, "Max attributes exceeds contract limit");
        _evolutionStages[stageIndex] = EvolutionStageDetails(name, maxAttributes, uriSuffix);
        emit EvolutionStageUpdated(stageIndex, name);
    }

    /// @dev Sets the requirements needed to evolve *to* the specified stage.
    /// Requires are checked when evaluating evolution from stage `stageIndex - 1` to `stageIndex`.
    function setEvolutionRequirements(uint8 stageIndex, EvolutionRequirements calldata reqs) public onlyOwner {
        // Requirements are for reaching stageIndex, so stageIndex must exist
        if (stageIndex == 0 || stageIndex >= _evolutionStages.length) {
             // Cannot set requirements for stage 0 (initial stage) or non-existent stages
            revert EvolvingNFTs__InvalidStageIndex(stageIndex);
        }
         // Optional: Validate reqs.minAttributeValues length or relevant indices
        _evolutionRequirements[stageIndex] = reqs;
        emit EvolutionRequirementsSet(stageIndex);
    }

    /// @dev Gets the details of a specific evolution stage.
    function getEvolutionStageDetails(uint8 stageIndex) public view returns (EvolutionStageDetails memory) {
         if (stageIndex >= _evolutionStages.length) {
            revert EvolvingNFTs__InvalidStageIndex(stageIndex);
        }
        return _evolutionStages[stageIndex];
    }

    /// @dev Gets the requirements to evolve *to* a specific stage.
    function getEvolutionRequirements(uint8 stageIndex) public view returns (EvolutionRequirements memory) {
        if (stageIndex == 0 || stageIndex >= _evolutionStages.length) {
             revert EvolvingNFTs__InvalidStageIndex(stageIndex);
        }
        return _evolutionRequirements[stageIndex];
    }


    /// @dev User requests to check and process evolution for their token.
    /// Requires sending the evolution trigger fee.
    /// Sets the state to ReadyForEvolution and records attempt time.
    /// Actual evolution processing happens potentially later, or can be triggered by admin/specific calls.
    /// This separation allows for gas cost management if evolution logic is complex.
    function requestEvolution(uint256 tokenId) public payable whenNotPaused nonReentrant {
        _requireOwned(tokenId);

        uint8 currentStage = _currentEvolutionStage[tokenId];
        if (currentStage >= _evolutionStages.length - 1) {
            revert EvolvingNFTs__EvolutionAlreadyComplete(tokenId);
        }

        // Check fee
        if (msg.value < _evolutionTriggerFee) {
            revert EvolvingNFTs__FeeNotMet(tokenId, _evolutionTriggerFee);
        }

        // Transfer fee to receiver
        if (_evolutionTriggerFee > 0) {
             (bool success,) = _feeReceiver.call{value: _evolutionTriggerFee}("");
             require(success, "Fee transfer failed"); // Basic check, robust handling needed for production
        }


        _evolutionState[tokenId] = EvolutionState.ReadyForEvolution;
        _lastEvolutionAttemptTime[tokenId] = block.timestamp;

        emit EvolutionRequested(tokenId, msg.value);

        // Optional: Automatically attempt processEvolution here if gas permits
        // If the logic is simple, you could call _processEvolution(tokenId) directly.
        // For complexity, keep them separate.
    }

     /// @dev Internal function to check evolution requirements.
    function _canEvolve(uint256 tokenId) internal view returns (bool) {
        uint8 currentStage = _currentEvolutionStage[tokenId];
        uint8 nextStage = currentStage + 1;

        // Cannot evolve if already at the last stage or if next stage requirements aren't set
        if (nextStage >= _evolutionStages.length) {
            return false; // Already at max stage
        }
         if (_evolutionRequirements[nextStage].minTimeHeldSeconds == 0 &&
             _evolutionRequirements[nextStage].minStakedDurationSeconds == 0 &&
             _evolutionRequirements[nextStage].requiredFeedCount == 0 &&
             allZero(_evolutionRequirements[nextStage].minAttributeValues)) {
             // No requirements set for the next stage, assume cannot evolve without requirements
             return false; // Requires explicit requirements
         }

        EvolutionRequirements memory reqs = _evolutionRequirements[nextStage];

        // Check time held requirement (from mint time)
        uint256 mintTime = _tokenMints[tokenId]; // Assuming OpenZeppelin ERC721 has _tokenMints or similar
        if (mintTime == 0) return false; // Should not happen for a valid token
        if (block.timestamp - mintTime < reqs.minTimeHeldSeconds) {
            return false;
        }

        // Check staked duration requirement
        uint256 stakeTime = _stakedTokens[tokenId];
        if (reqs.minStakedDurationSeconds > 0) {
             if (stakeTime == 0) return false; // Must be staked if duration is required
             if (block.timestamp - stakeTime < reqs.minStakedDurationSeconds) {
                return false;
             }
        }


        // Check feed count requirement
        if (_feedCount[tokenId] < reqs.requiredFeedCount) {
            return false;
        }

        // Check attribute requirements
        uint256[MAX_ATTRIBUTE_SLOTS] storage currentAttributes = _attributes[tokenId];
        for (uint i = 0; i < MAX_ATTRIBUTE_SLOTS; i++) {
            if (currentAttributes[i] < reqs.minAttributeValues[i]) {
                 return false;
            }
        }

        // All requirements met
        return true;
    }

    /// @dev Checks if an NFT currently meets the requirements to evolve to the next stage.
    function canEvolve(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId); // Token must exist
         return _canEvolve(tokenId);
    }


    /// @dev Processes the evolution for a token if requirements are met.
    /// Can be called by the owner (e.g., via a batch script) or potentially internally
    /// after a requestEvolution or interaction.
    function processEvolution(uint256 tokenId) public onlyOwner whenNotPaused nonReentrant {
         // Allows owner to trigger processing for any token
        _requireOwned(tokenId); // Ensure token exists

        uint8 currentStage = _currentEvolutionStage[tokenId];
        uint8 nextStage = currentStage + 1;

        if (nextStage >= _evolutionStages.length) {
             revert EvolvingNFTs__EvolutionAlreadyComplete(tokenId);
        }

        // Check state - only process if Idle or ReadyForEvolution
        if (_evolutionState[tokenId] != EvolutionState.Idle &&
            _evolutionState[tokenId] != EvolutionState.ReadyForEvolution) {
             // Already Evolved or in another state, skip processing
             emit NFTProcessedForEvolution(tokenId, false, currentStage);
             return;
        }

        if (_canEvolve(tokenId)) {
            _applyEvolutionEffects(tokenId, nextStage);
             _evolutionState[tokenId] = nextStage == _evolutionStages.length - 1 ? EvolutionState.Evolved : EvolutionState.Idle; // Mark as Evolved if final stage, otherwise back to Idle
            _currentEvolutionStage[tokenId] = nextStage;
             emit NFTProcessedForEvolution(tokenId, true, nextStage);
        } else {
             // Requirements not met, keep state (maybe ReadyForEvolution or Idle)
             // If it was ReadyForEvolution, it stays ReadyForEvolution until conditions change or admin resets.
             emit NFTProcessedForEvolution(tokenId, false, currentStage);
        }
    }

     /// @dev Internal helper to apply evolution effects.
    function _applyEvolutionEffects(uint256 tokenId, uint8 nextStageIndex) internal {
         // This is where you'd implement logic like:
         // - Resetting feed count: _feedCount[tokenId] = 0;
         // - Resetting staked time: if (_stakedTokens[tokenId] != 0) _stakedTokens[tokenId] = block.timestamp; // Reset timer if staked
         // - Applying attribute changes: e.g., increase a random attribute, or increase specific attributes
         //   Example: Increase attribute slot 0 by 10
         //  _attributes[tokenId][0] += 10;
         //  _setAttribute(tokenId, 0, _attributes[tokenId][0] + 10); // Using helper to respect limits

         // Example: Increase specific attributes based on the next stage (requires storing this logic)
         // This example doesn't have complex on-chain attribute logic per stage,
         // but you could add mappings like `stageIndex -> AttributeModifier[]`.

         // For demonstration, let's just increment a single attribute slot (e.g., index 0 "Level")
         _setAttribute(tokenId, 0, _attributes[tokenId][0] + 1); // Increment 'Level' or similar
    }

    /// @dev Allows the owner to force an NFT to evolve to the next stage, bypassing requirements.
    /// Useful for testing, fixing issues, or specific promotions.
    function adminForceEvolve(uint256 tokenId) public onlyOwner whenNotPaused nonReentrant {
        _requireOwned(tokenId);
        uint8 currentStage = _currentEvolutionStage[tokenId];
        uint8 nextStage = currentStage + 1;

        if (nextStage >= _evolutionStages.length) {
            revert EvolvingNFTs__EvolutionAlreadyComplete(tokenId);
        }

        _applyEvolutionEffects(tokenId, nextStage);
         _evolutionState[tokenId] = nextStage == _evolutionStages.length - 1 ? EvolutionState.Evolved : EvolutionState.Idle; // Mark as Evolved if final stage, otherwise back to Idle
        _currentEvolutionStage[tokenId] = nextStage;

        emit NFTProcessedForEvolution(tokenId, true, nextStage);
    }

     /// @dev Allows the owner to manually set the evolution state of an NFT.
    function adminSetEvolutionState(uint256 tokenId, EvolutionState state) public onlyOwner {
         _requireOwned(tokenId);
         _evolutionState[tokenId] = state;
    }


    /// @dev Returns the current evolution state of a token.
    function getEvolutionState(uint256 tokenId) public view returns (EvolutionState) {
        _requireOwned(tokenId);
        return _evolutionState[tokenId];
    }

    /// @dev Returns the current evolution stage index of a token.
    function getEvolutionStage(uint256 tokenId) public view returns (uint8) {
         _requireOwned(tokenId);
        return _currentEvolutionStage[tokenId];
    }


    // --- Interaction / Gamification ---

    /// @dev Stakes the NFT, preventing transfers and recording the staking time.
    /// Staking duration can be used as an evolution requirement.
    function stakeNFT(uint256 tokenId) public whenNotPaused nonReentrant {
        _requireOwned(tokenId);
        if (_stakedTokens[tokenId] != 0) {
            revert EvolvingNFTs__TokenAlreadyStaked(tokenId);
        }
        _stakedTokens[tokenId] = block.timestamp;
        emit NFTStaked(tokenId, block.timestamp);
    }

    /// @dev Unstakes the NFT, allowing transfers again.
    function unstakeNFT(uint256 tokenId) public whenNotPaused nonReentrant {
        _requireOwned(tokenId);
        if (_stakedTokens[tokenId] == 0) {
            revert EvolvingNFTs__TokenNotStaked(tokenId);
        }
        uint256 timestamp = _stakedTokens[tokenId];
        _stakedTokens[tokenId] = 0;
        emit NFTUnstaked(tokenId, timestamp);
    }

     /// @dev Checks if an NFT is currently staked.
    function isStaked(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId); // Token must exist
        return _stakedTokens[tokenId] != 0;
    }

     /// @dev Gets the timestamp when an NFT was staked. Returns 0 if not staked.
    function getStakedTimestamp(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Token must exist
        return _stakedTokens[tokenId];
    }

    /// @dev Simulates feeding the NFT, incrementing a counter.
    /// This could be extended to require payment or a specific token.
    function feedNFT(uint256 tokenId) public whenNotPaused nonReentrant {
        _requireOwned(tokenId);
        _feedCount[tokenId]++;
        emit NFTFed(tokenId, _feedCount[tokenId]);

        // Optional: Automatically attempt evolution processing after feeding if it's a trigger
        // processEvolution(tokenId);
    }


    // --- Configuration & Fees ---

    /// @dev Sets the base URI for token metadata.
    function setBaseTokenURI(string calldata uri) public onlyOwner {
        _baseTokenURI = uri;
        emit BaseTokenURIUpdated(uri);
    }

    /// @dev Sets the fee required to request evolution.
    function setEvolutionTriggerFee(uint256 fee) public onlyOwner {
        _evolutionTriggerFee = fee;
        emit EvolutionTriggerFeeUpdated(fee);
    }

    /// @dev Gets the current evolution trigger fee.
    function getEvolutionTriggerFee() public view returns (uint256) {
        return _evolutionTriggerFee;
    }

    /// @dev Allows the designated fee receiver to withdraw accumulated fees.
    function withdrawFees() public nonReentrant {
        require(msg.sender == _feeReceiver, "Only fee receiver can withdraw");
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert EvolvingNFTs__InsufficientFeesCollected();
        }
        (bool success, ) = _feeReceiver.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(_feeReceiver, balance);
    }

    /// @dev Sets the address that receives evolution fees.
    function setFeeReceiver(address payable receiver) public onlyOwner {
        require(receiver != address(0), "Invalid fee receiver");
        _feeReceiver = receiver;
    }

    /// @dev Sets a mapping between a trait name (used by metadata service) and an attribute slot index.
    /// This helps the metadata service know which on-chain attribute corresponds to which trait.
    /// Attribute index is 0-based. Stored as 1-based to distinguish from unitialized mapping (which is 0).
    function setTraitMapping(string calldata traitName, uint256 attributeIndex) public onlyOwner {
        require(attributeIndex < MAX_ATTRIBUTE_SLOTS, "Invalid attribute index");
        _traitMapping[traitName] = attributeIndex + 1; // Store as 1-based
        emit TraitMappingUpdated(traitName, attributeIndex);
    }

     /// @dev Gets the attribute slot index mapped to a trait name.
    /// Returns 0 if no mapping exists or mapping is to index 0.
    function getTraitMapping(string calldata traitName) public view returns (uint256) {
         uint256 mappedIndex = _traitMapping[traitName];
         return mappedIndex > 0 ? mappedIndex - 1 : type(uint256).max; // Return 0-based index or a large sentinel if not found
    }


    // --- Internal Helpers ---

    /// @dev Internal: Checks if the caller is the owner of the token or approved.
    function _requireOwned(uint256 tokenId) internal view {
         address owner = ownerOf(tokenId);
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert EvolvingNFTs__NotOwnerOfToken(tokenId, msg.sender);
         }
    }

    /// @dev See {ERC721-_beforeTokenTransfer}. Prevents transfer of staked tokens.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && _stakedTokens[tokenId] != 0) {
            revert EvolvingNFTs__TokenAlreadyStaked(tokenId);
        }
         // If transferring to address(0) (burn), it's handled in the burn function itself.
    }

    /// @dev Helper to check if all elements in a uint256 array are zero.
    function allZero(uint256[MAX_ATTRIBUTE_SLOTS] memory arr) internal pure returns (bool) {
        for (uint i = 0; i < MAX_ATTRIBUTE_SLOTS; i++) {
            if (arr[i] != 0) return false;
        }
        return true;
    }

    // Helper to convert uint256 to string
    function toString(uint256 value) internal pure returns (string memory) {
        // From OpenZeppelin's Strings.sol (can't import directly if not inherited)
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
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // The actual token URI generation logic is complex due to on-chain attributes
    // and dynamic stage changes. A typical pattern is:
    // 1. Contract stores a base URI and stage-specific suffixes/prefixes.
    // 2. Contract's tokenURI function returns a URL like `baseURI/stageSuffix/tokenId`.
    // 3. An off-chain service (API) listens for these requests.
    // 4. The API queries the contract for the token's *current* stage and attributes using the contract's view functions (`getEvolutionStage`, `getAttributes`).
    // 5. The API uses this on-chain data to dynamically generate the appropriate JSON metadata and image URL.
    // Implementing the full metadata generation *on-chain* is prohibitively expensive and complex,
    // involving string manipulation, JSON formatting, potentially SVG generation etc.
    // This structure enables dynamic metadata while keeping complex computation off-chain.
    // The `_generateMetadataURI` helper is conceptual here, as the actual logic for the
    // external service is not in Solidity. The `tokenURI` override points to this external service.

    // function _generateMetadataURI(uint256 tokenId) internal view returns (string memory) {
    //     // This function conceptually describes what an off-chain service would do.
    //     // The contract's `tokenURI` simply provides the URL pointing to this service.
    //     uint8 currentStage = _currentEvolutionStage[tokenId];
    //     string memory stageSuffix = "";
    //      if (currentStage < _evolutionStages.length) {
    //          stageSuffix = _evolutionStages[currentStage].uriSuffix;
    //      }
    //     // Concatenate base URI, stage suffix, and token ID.
    //     return string.concat(_baseTokenURI, stageSuffix, toString(tokenId));
    // }
}
```