Okay, let's design a smart contract that represents evolving digital entities, influenced by time, user interaction, and potentially external data (like weather, market conditions, etc., via an oracle). We'll call it "ChronoEssence Genesis Engine".

This contract will manage Non-Fungible Tokens (NFTs) that have mutable attributes. Their state can change based on:

1.  **Chrono (Time):** Attributes might decay, grow, or change based on block timestamps since creation or last update.
2.  **Essence (Internal Resource):** Users can "infuse" a conceptual "essence" (managed internally, not an external token for simplicity here) into their entities, boosting certain attributes or triggering events.
3.  **Aura (Oracle Influence):** The entity can absorb "aura" based on data fetched from an external oracle, impacting specific attributes or allowing unique actions.
4.  **User Actions:** Crafting new attributes, merging entities, evolving, etc.

This combines dynamic NFTs, resource sinks, oracle interaction patterns, and potential gaming/metaverse mechanics.

---

**Contract: ChronoEssence Genesis Engine**

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721, Ownable, ReentrancyGuard (good practice). We'll implement ERC721 rather than inherit fully for more control over internal functions like `_beforeTokenTransfer`.
3.  **Error Definitions**
4.  **Structs:**
    *   `ChronoEntity`: Holds all data for an NFT (creation time, last updated time, essence, aura, attribute mappings, status flags).
    *   `CraftingRecipe`: Defines what's needed to craft something.
    *   `EvolutionRequirement`: Defines what's needed to evolve.
    *   `MergeResult`: Defines the outcome of merging two entities.
5.  **Enums/Constants:** Attribute types, Status flags, Crafting types, Evolution stages.
6.  **State Variables:**
    *   Token counter, mappings for token data, ownership, approvals.
    *   Admin addresses (using Ownable).
    *   Oracle address.
    *   Global parameters (e.g., essence decay rate, aura impact factor).
    *   Mapping for crafting recipes, evolution requirements, merge rules.
    *   Governance-related state (proposals, votes, state changes).
7.  **Events:** Minting, State Update, Essence Infused, Aura Updated, Evolution, Crafting, Merging, Parameter Change Proposed/Voted/Executed.
8.  **Modifiers:** `onlyOracle`, `whenReadyForEvolution`, `whenCraftingPossible`.
9.  **Core ERC721 Implementation:** (Minimal required for compliance and custom logic)
    *   `balanceOf`
    *   `ownerOf`
    *   `approve`
    *   `getApproved`
    *   `setApprovalForAll`
    *   `isApprovedForAll`
    *   `transferFrom`
    *   `safeTransferFrom` (overloaded)
    *   `totalSupply`
    *   `tokenByIndex` (optional, useful)
    *   `tokenOfOwnerByIndex` (optional, useful)
    *   `tokenURI` (critical for dynamic metadata)
10. **Internal Helpers:**
    *   `_mint`: Create a new entity.
    *   `_burn`: Destroy an entity.
    *   `_transfer`: Handle transfer logic.
    *   `_beforeTokenTransfer`: Hook for pre-transfer logic (e.g., un-staking).
    *   `_calculateDynamicAttributes`: Core logic to compute dynamic attributes based on current state.
    *   `_generateMetadataURI`: Create a URI based on entity state (could point to an API).
11. **Entity State Management:**
    *   `mintInitialEntity`: Mints a new entity.
    *   `infuseEssence`: Adds essence, potentially burning caller's essence balance (if integrated) or just increasing internal counter.
    *   `updateAuraInfluence`: Called by the oracle to update aura value.
    *   `syncEntityState`: Public/internal function to manually trigger a state sync (updating dynamic attributes based on time/essence/aura).
12. **Dynamics & Evolution:**
    *   `evolveEntity`: Triggers evolution if requirements met, changes entity stage and attributes.
    *   `checkEvolutionReadiness`: View function to see if an entity meets evolution requirements.
13. **Crafting & Utility:**
    *   `defineCraftingRecipe`: Admin function to set up recipes.
    *   `craftItem`: Allows owner to consume entity essence/attributes based on a recipe to "craft" a new attribute or status.
    *   `mergeEntities`: Merge two entities into potentially a new one, burning the originals.
14. **Oracle Integration:**
    *   `setOracleAddress`: Admin function.
    *   `requestAuraUpdate`: User or contract can request an oracle update for a specific entity (simulated request).
    *   `fulfillAuraUpdate`: Oracle callback function.
15. **Governance (Simple):**
    *   `proposeParameterChange`: Anyone can propose changing a global parameter.
    *   `voteOnProposal`: Token holders (or a specific group) can vote.
    *   `executeProposal`: Execute a proposal if it passes.
16. **View Functions:**
    *   `getEntityDetails`: Get full struct data.
    *   `getBaseAttribute`: Get a specific base attribute value.
    *   `getDynamicAttribute`: Get a specific dynamic attribute value (might require state sync first).
    *   `getStatusFlag`: Get a specific status flag.
    *   `getCraftingRecipe`: View details of a recipe.
    *   `getEvolutionRequirements`: View details of evolution requirements.
    *   `getMergeResultRules`: View details of merge outcomes.
    *   `getProposalDetails`: View details of a governance proposal.
17. **Admin/Configuration:**
    *   `setBaseAttributeAdmin`: Admin can force-set base attributes.
    *   `setStatusFlagAdmin`: Admin can force-set status flags.
    *   `registerAttributeType`: Admin defines friendly names for attribute type IDs.
    *   `getRegisteredAttributeName`: View registered attribute name.
    *   `setGlobalParameter`: Admin sets global parameters directly (or via governance).

---

**Function Summary:**

*   **Core ERC721 (Implicit/Implemented):**
    1.  `balanceOf(address owner)`: Get number of tokens owned by an address.
    2.  `ownerOf(uint256 tokenId)`: Get the owner of a specific token.
    3.  `approve(address to, uint256 tokenId)`: Approve another address to transfer a token.
    4.  `getApproved(uint256 tokenId)`: Get the approved address for a token.
    5.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all tokens.
    6.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for an owner.
    7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token (standard).
    8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfer token (safe).
    9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfer token (safe with data).
    10. `supportsInterface(bytes4 interfaceId)`: ERC165 standard.
    11. `name()`: Get contract name.
    12. `symbol()`: Get contract symbol.
    13. `totalSupply()`: Get total number of tokens.
*   **Entity State Management:**
    14. `mintInitialEntity(address recipient, uint256 initialEssence)`: Mints a new entity NFT for `recipient` with `initialEssence`.
    15. `infuseEssence(uint256 tokenId, uint256 amount)`: Increases the internal essence count of `tokenId`. Requires token ownership.
    16. `updateAuraInfluence(uint256 tokenId, uint256 auraValue)`: *Internal* function, called by `fulfillAuraUpdate`. Updates the aura value for `tokenId`.
    17. `syncEntityState(uint256 tokenId)`: Recalculates and updates the dynamic attributes and status flags based on current time, essence, and aura. Can be called by owner or potentially anyone to refresh state.
*   **Dynamics & Evolution:**
    18. `calculateDynamicAttributes(uint256 tokenId)`: *Internal* pure/view function to calculate dynamic attribute values based on an entity's struct data. Used by `syncEntityState` and view functions.
    19. `evolveEntity(uint256 tokenId)`: Attempts to evolve the entity to the next stage if it meets predefined `EvolutionRequirement`s.
    20. `checkEvolutionReadiness(uint256 tokenId)`: View function to check if an entity currently meets its evolution requirements.
*   **Crafting & Utility:**
    21. `defineCraftingRecipe(uint256 recipeId, CraftingRecipe calldata recipe)`: Admin function to define a crafting recipe, specifying resource costs (essence, attributes) and results (new attributes, status flags).
    22. `craftItem(uint256 tokenId, uint256 recipeId)`: Allows the token owner to apply a crafting recipe, consuming resources and modifying the entity's state.
    23. `defineMergeRules(uint256 ruleId, MergeResult calldata result)`: Admin function to define the outcome of merging two entity types/stages based on `ruleId`.
    24. `mergeEntities(uint256 tokenId1, uint256 tokenId2)`: Burns `tokenId1` and `tokenId2` and potentially mints a new entity based on predefined merge rules. Requires ownership of both tokens.
    25. `burnEntity(uint256 tokenId)`: Allows the token owner to burn their entity.
*   **Oracle Integration:**
    26. `setOracleAddress(address _oracle)`: Admin function to set the trusted oracle address.
    27. `requestAuraUpdate(uint256 tokenId, bytes memory callbackData)`: Simulates a request to an external oracle for data relevant to `tokenId`. Emits an event for the oracle listener.
    28. `fulfillAuraUpdate(uint256 requestId, uint256 auraValue)`: Callback function, callable only by the trusted oracle address. Updates the aura influence for the entity associated with the `requestId`.
*   **Governance (Simple Parameter Voting):**
    29. `proposeParameterChange(uint256 paramType, uint256 newValue)`: Allows a designated role or token holder (depending on implementation) to propose changing a global contract parameter.
    30. `voteOnProposal(uint256 proposalId, bool support)`: Allows voting on an active proposal. Voting power could be based on staked tokens, owned entities, etc. (Simple 1 address = 1 vote here).
    31. `executeProposal(uint256 proposalId)`: Executes the proposed change if the proposal has met the required quorum and threshold.
*   **View Functions:**
    32. `getEntityDetails(uint256 tokenId)`: Returns the complete `ChronoEntity` struct for `tokenId`.
    33. `getBaseAttribute(uint256 tokenId, uint256 attributeType)`: Returns a specific base attribute value.
    34. `getDynamicAttribute(uint256 tokenId, uint256 attributeType)`: Returns a specific dynamic attribute value. *Note: This might show a stale value if `syncEntityState` hasn't been called recently.*
    35. `getStatusFlag(uint256 tokenId, uint256 statusType)`: Returns the boolean status flag value.
    36. `getCraftingRecipe(uint256 recipeId)`: Returns the details of a crafting recipe.
    37. `getEvolutionRequirements(uint256 evolutionStage)`: Returns the requirements for a specific evolution stage.
    38. `getMergeResultRules(uint256 ruleId)`: Returns the details of a merge outcome rule.
    39. `getProposalDetails(uint256 proposalId)`: Returns the details of a governance proposal.
    40. `getRegisteredAttributeName(uint256 attributeType)`: Returns the human-readable name for an attribute type ID.
*   **Admin/Configuration:**
    41. `setBaseAttributeAdmin(uint256 tokenId, uint256 attributeType, uint256 value)`: Admin function to set a base attribute value.
    42. `setStatusFlagAdmin(uint256 tokenId, uint256 statusType, bool status)`: Admin function to set a status flag.
    43. `registerAttributeType(uint256 attributeType, string memory name)`: Admin function to register and name attribute type IDs for easier interpretation off-chain.
    44. `setGlobalParameter(uint256 paramType, uint256 newValue)`: Admin function to set global parameters directly (can be restricted or replaced by governance).
    45. `withdrawAdminFunds(address tokenAddress, uint256 amount)`: Admin utility to withdraw any accidental token transfers to the contract (excluding native ETH, which would need a `receive` or `fallback` and separate withdrawal).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ChronoEssence Genesis Engine
 * @dev A dynamic NFT contract where entities evolve based on time, essence, aura (oracle), and user actions.
 * Features include dynamic attributes, crafting, merging, simple governance for parameters, and oracle integration patterns.
 * ERC721 compliance is implemented manually for granular control.
 */
contract ChronoEssenceGenesisEngine is Ownable, ReentrancyGuard, IERC721, IERC721Metadata, IERC721Receiver {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Error Definitions ---
    error InvalidTokenId();
    error NotTokenOwnerOrApproved();
    error NotApprovedForAll();
    error TransferToZeroAddress();
    error SelfApproval();
    error ApprovalToCurrentOwner();
    error TransferToERC721ReceiverRejected();
    error CraftingRequirementsNotMet();
    error EvolutionRequirementsNotMet();
    error MergeRequirementsNotMet();
    error InvalidRecipeId();
    error InvalidEvolutionStage();
    error InvalidMergeRuleId();
    error OracleCallbackFailed();
    error OnlyOracle();
    error ProposalAlreadyExistsOrActive();
    error ProposalNotFoundOrInactive();
    error AlreadyVoted();
    error ProposalThresholdNotMet();
    error ProposalExecutionFailed();
    error InvalidParameterType();
    error AttributeTypeNotRegistered();

    // --- Structs ---

    struct ChronoEntity {
        uint256 creationBlock;      // Block when the entity was minted
        uint256 lastUpdatedBlock;   // Block when syncEntityState was last called
        uint256 essenceInfused;     // Cumulative essence infused over time
        uint256 auraInfluence;      // Cumulative aura influence from oracle
        uint256 currentStage;       // Evolution stage (e.g., 1, 2, 3...)

        // Base attributes are fixed or changed via admin/governance/specific events
        mapping(uint256 => uint256) baseAttributes;
        // Dynamic attributes are calculated based on time, essence, aura, etc.
        mapping(uint256 => uint256) dynamicAttributes;
        // Boolean flags for various statuses (e.g., staked, boosted, cursed)
        mapping(uint256 => bool) statusFlags;

        // Metadata URI - can be generated based on state or set
        string metadataURI;
    }

    struct CraftingRecipe {
        bool exists; // Sentinel to check if recipe is defined
        mapping(uint256 => uint256) requiredEssence; // Essence cost by type (if types exist)
        mapping(uint256 => uint256) requiredBaseAttributes; // Base attribute minimums
        mapping(uint256 => uint256) requiredDynamicAttributes; // Dynamic attribute minimums
        mapping(uint256 => bool) requiredStatusFlags; // Required status flags
        mapping(uint256 => uint256) consumedEssence; // Essence consumed
        mapping(uint256 => uint256) consumedBaseAttributes; // Base attributes consumed
        mapping(uint256 => uint256) resultAddedBaseAttributes; // Base attributes added
        mapping(uint256 => uint256) resultAddedDynamicAttributes; // Dynamic attributes added
        mapping(uint256 => bool) resultSetStatusFlags; // Status flags to set
        mapping(uint256 => bool) resultClearStatusFlags; // Status flags to clear
    }

     struct EvolutionRequirement {
        bool exists; // Sentinel
        uint256 requiredEssence;
        uint256 requiredAura;
        uint256 minBlocksSinceCreation;
        mapping(uint256 => uint256) requiredBaseAttributes;
        mapping(uint256 => uint256) requiredDynamicAttributes;
        mapping(uint256 => bool) requiredStatusFlags;
        mapping(uint256 => uint256) addedBaseAttributes; // Attributes added upon evolution
        mapping(uint256 => uint256) addedDynamicAttributes;
        mapping(uint256 => bool) setStatusFlags;
        mapping(uint256 => bool) clearStatusFlags;
        string newMetadataUri; // New URI or URI pattern upon evolution
     }

    struct MergeResult {
        bool exists; // Sentinel
        uint256 requiredEssenceTotal; // Total essence from both entities
        uint256 requiredAuraTotal; // Total aura from both entities
        uint256 resultingStage; // Stage of the new entity
        mapping(uint256 => uint256) resultingBaseAttributes; // Base attributes for new entity
        mapping(uint256 => uint256) resultingDynamicAttributes; // Dynamic attributes for new entity
        mapping(uint256 => bool) resultingStatusFlags; // Status flags for new entity
        string newMetadataUri; // URI for the new entity
    }

    struct GovernanceProposal {
        bool active;
        uint256 proposalId;
        uint256 paramType; // Type of parameter being changed
        uint256 newValue;    // The proposed new value
        uint256 voteCount;   // Votes in favor (simple majority here)
        uint256 votingDeadline; // Block number when voting ends
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // --- Enums/Constants ---

    // Example Attribute Types (could be more specific)
    uint256 constant ATTRIBUTE_TYPE_STRENGTH = 1;
    uint256 constant ATTRIBUTE_TYPE_DEXTERITY = 2;
    uint256 constant ATTRIBUTE_TYPE_CONSTITUTION = 3;
    uint256 constant ATTRIBUTE_TYPE_INTELLECT = 4;
    uint256 constant ATTRIBUTE_TYPE_WISDOM = 5;
    uint256 constant ATTRIBUTE_TYPE_CHARISMA = 6;
    uint256 constant ATTRIBUTE_TYPE_ESSENCE_EFFICIENCY = 101; // Dynamic attribute related to essence
    uint256 constant ATTRIBUTE_TYPE_AURA_RESISTANCE = 102;    // Dynamic attribute related to aura

    // Example Status Flags
    uint256 constant STATUS_FLAG_IS_STAKED = 1;
    uint256 constant STATUS_FLAG_IS_CURSED = 2;
    uint256 constant STATUS_FLAG_IS_BOOSTED = 3;

    // Example Parameter Types for Governance
    uint256 constant PARAM_TYPE_ESSENCE_DECAY_RATE = 1;
    uint256 constant PARAM_TYPE_AURA_IMPACT_FACTOR = 2;
    uint256 constant PARAM_TYPE_GOVERNANCE_VOTE_THRESHOLD = 3; // Percentage / 100
    uint256 constant PARAM_TYPE_GOVERNANCE_VOTING_PERIOD_BLOCKS = 4;

    // --- State Variables ---

    string private _name;
    string private _symbol;
    uint256 private _nextTokenId;

    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => ChronoEntity) private _entities;

    address private _oracleAddress;
    uint256 private _oracleRequestIdCounter;
    mapping(uint256 => uint256) private _oracleRequestIdToTokenId;

    mapping(uint256 => CraftingRecipe) private _craftingRecipes;
    mapping(uint256 => EvolutionRequirement) private _evolutionRequirements;
    mapping(uint256 => MergeResult) private _mergeResults;

    mapping(uint256 => uint256) public globalParameters;

    uint256 private _nextProposalId;
    mapping(uint256 => GovernanceProposal) private _proposals;
    mapping(uint256 => string) private _attributeNames; // Mapping attribute ID to human-readable name

    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event EntityMinted(address indexed recipient, uint256 indexed tokenId, uint256 initialEssence);
    event EntityStateSynced(uint256 indexed tokenId, uint256 newEssence, uint256 newAura, uint256 newStage);
    event EssenceInfused(uint256 indexed tokenId, uint256 amount);
    event AuraInfluenceUpdated(uint256 indexed tokenId, uint256 auraValue, uint256 requestId);
    event EvolutionTriggered(uint256 indexed tokenId, uint256 newStage);
    event ItemCrafted(uint256 indexed tokenId, uint256 indexed recipeId);
    event EntitiesMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId);
    event EntityBurned(uint256 indexed tokenId);
    event OracleAuraUpdateRequest(uint256 indexed requestId, uint256 indexed tokenId, bytes callbackData);
    event ParameterChangeProposed(uint256 indexed proposalId, uint256 indexed paramType, uint256 newValue, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AttributeTypeRegistered(uint256 indexed attributeType, string name);

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != _oracleAddress) revert OnlyOracle();
        _;
    }

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, address initialOracle) Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
        _nextTokenId = 1;
        _nextProposalId = 1;
        _oracleAddress = initialOracle;

        // Set initial global parameters
        globalParameters[PARAM_TYPE_ESSENCE_DECAY_RATE] = 1; // Example: 1 essence per block decay (simplified)
        globalParameters[PARAM_TYPE_AURA_IMPACT_FACTOR] = 10; // Example: Aura adds 1/10th to some dynamic attribute
        globalParameters[PARAM_TYPE_GOVERNANCE_VOTE_THRESHOLD] = 6000; // 60% threshold (6000/10000)
        globalParameters[PARAM_TYPE_GOVERNANCE_VOTING_PERIOD_BLOCKS] = 100; // Voting lasts 100 blocks
    }

    // --- Core ERC721 Implementation ---
    // Note: Standard functions implemented manually for direct control over mappings

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert InvalidTokenId();
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // Checks if tokenId exists
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotTokenOwnerOrApproved();
        if (to == owner) revert ApprovalToCurrentOwner();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        ownerOf(tokenId); // Checks if tokenId exists
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert SelfApproval();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
        _transfer(from, to, tokenId);
        if (to.code.length > 0 && !IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "")) {
             revert TransferToERC721ReceiverRejected();
        }
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override nonReentrant {
        _transfer(from, to, tokenId);
        if (to.code.length > 0 && !IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data)) {
             revert TransferToERC721ReceiverRejected();
        }
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.sub(1); // Assumes tokenIds start from 1
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ChronoEntity storage entity = _entities[tokenId];
        if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId(); // Ensure token exists
        // Option 1: Static URI
        // return entity.metadataURI;

        // Option 2: Generate URI based on state (more complex, requires off-chain processing or on-chain SVG)
        // For this example, we'll use a simple base URI + tokenId, assuming an API serves metadata
        // Or you could return a data URI for simple SVG/JSON directly on-chain
         return string(abi.encodePacked("ipfs://QmT[...]/", tokenId.toString())); // Example placeholder
    }

    // Required for safeTransferFrom to contracts
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Implement logic if THIS contract needs to receive NFTs (e.g., for merging, staking)
        // For this contract, we assume entities are held by external addresses.
        // Returning the magic value indicates acceptance.
        return IERC721Receiver.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Implement standard ERC721, ERC721Metadata, and ERC165 interfaces
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId; // If contract receives NFTs
    }


    // --- Internal Helpers ---

    function _mint(address to, uint256 tokenId, uint256 initialEssence, string memory initialUri) internal {
        if (to == address(0)) revert TransferToZeroAddress();
        _tokenOwners[tokenId] = to;
        _balanceOf[to]++;
        delete _tokenApprovals[tokenId]; // Clear approvals

        // Initialize entity data
        _entities[tokenId].creationBlock = block.number;
        _entities[tokenId].lastUpdatedBlock = block.number;
        _entities[tokenId].essenceInfused = initialEssence;
        _entities[tokenId].auraInfluence = 0;
        _entities[tokenId].currentStage = 1; // Start at stage 1
        _entities[tokenId].metadataURI = initialUri;

        // Initialize some base attributes (example)
        _entities[tokenId].baseAttributes[ATTRIBUTE_TYPE_STRENGTH] = 10;
        _entities[tokenId].baseAttributes[ATTRIBUTE_TYPE_INTELLECT] = 10;

        // Calculate initial dynamic attributes
        _calculateDynamicAttributes(tokenId); // Initialize dynamic attributes

        emit Transfer(address(0), to, tokenId);
        emit EntityMinted(to, tokenId, initialEssence);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Checks existence
        delete _tokenOwners[tokenId];
        _balanceOf[owner]--;
        delete _tokenApprovals[tokenId]; // Clear approvals for burned token
        delete _entities[tokenId];       // Delete entity data

        emit Transfer(owner, address(0), tokenId);
        emit EntityBurned(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert NotTokenOwnerOrApproved(); // Checks existence and ownership
        if (to == address(0)) revert TransferToZeroAddress();

        // Check approval
        if (msg.sender != from && getApproved(tokenId) != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }

        _beforeTokenTransfer(from, to, tokenId); // Hook for pre-transfer logic

        delete _tokenApprovals[tokenId]; // Clear approval on transfer
        _balanceOf[from]--;
        _balanceOf[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // Hook that is called before any token transfer, including minting and burning.
    // This is useful for implementing e.g. staking mechanisms.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Example: If the entity is staked (check status flag), prevent transfer unless specific conditions are met
        // if (from != address(0) && _entities[tokenId].statusFlags[STATUS_FLAG_IS_STAKED]) {
        //     // require(!_entities[tokenId].statusFlags[STATUS_FLAG_IS_STAKED], "Staked entities cannot be transferred");
        //     // Instead of reverting here, you might unstake it depending on logic
        // }
        // If transfering FROM address(0) (minting) or TO address(0) (burning), no staking check needed.
        require(!_entities[tokenId].statusFlags[STATUS_FLAG_IS_STAKED], "Staked entities cannot be transferred");
    }

    /**
     * @dev Calculates dynamic attributes based on current entity state and global parameters.
     * This is a PURE or VIEW function, it does NOT change state.
     * Call syncEntityState to apply the results to the entity's state.
     */
    function _calculateDynamicAttributes(uint256 tokenId) internal view returns (mapping(uint256 => uint256) memory) {
        ChronoEntity storage entity = _entities[tokenId];
        mapping(uint256 => uint256) memory calculatedDynamics; // Use a memory variable

        uint256 blocksPassed = block.number - entity.lastUpdatedBlock;
        uint256 essence = entity.essenceInfused;
        uint256 aura = entity.auraInfluence;

        // Example calculations (simplified)
        // Essence decays over time
        uint256 decayedEssence = essence > (blocksPassed * globalParameters[PARAM_TYPE_ESSENCE_DECAY_RATE])
                                ? essence - (blocksPassed * globalParameters[PARAM_TYPE_ESSENCE_DECAY_RATE])
                                : 0;

        // Dynamic attribute 1: Essence Efficiency
        // Influenced positively by decayed essence
        calculatedDynamics[ATTRIBUTE_TYPE_ESSENCE_EFFICIENCY] = decayedEssence.div(100).add(entity.baseAttributes[ATTRIBUTE_TYPE_INTELLECT].div(2));

        // Dynamic attribute 2: Aura Resistance
        // Influenced positively by aura and constitution, negatively by curse status
        uint256 auraResistance = aura.div(globalParameters[PARAM_TYPE_AURA_IMPACT_FACTOR]).add(entity.baseAttributes[ATTRIBUTE_TYPE_CONSTITUTION].div(2));
        if (entity.statusFlags[STATUS_FLAG_IS_CURSED]) {
             auraResistance = auraResistance > 20 ? auraResistance - 20 : 0; // Example penalty
        }
        calculatedDynamics[ATTRIBUTE_TYPE_AURA_RESISTANCE] = auraResistance;

        // Add other dynamic attributes based on other base attributes, flags, stage, etc.
        // For example, add a dynamic "Combat Power" based on Str, Dex, Int, Essence Efficiency, etc.

        return calculatedDynamics;
    }

    // Internal helper to generate a simple metadata URI based on entity state
    function _generateMetadataURI(uint256 tokenId) internal view returns (string memory) {
        // In a real application, this would be a complex function
        // that queries entity state and constructs a URI pointing to an API endpoint
        // that serves a JSON metadata file compliant with ERC721Metadata JSON Schema.
        // For this example, we'll just return a placeholder indicating it's dynamic.
         ChronoEntity storage entity = _entities[tokenId];
         return string(abi.encodePacked("data:application/json;base64,...", // Base64 encoded JSON
                                         '{ "name": "ChronoEntity #', tokenId.toString(),
                                         '", "stage": ', entity.currentStage.toString(),
                                         ', "essence": ', entity.essenceInfused.toString(),
                                         // ... other key attributes ...
                                         ' }' )); // Simplified JSON structure
    }

    // --- Entity State Management ---

    /**
     * @dev Mints a new ChronoEntity NFT.
     * @param recipient The address to mint the token to.
     * @param initialEssence The starting essence for the new entity.
     * @param initialUri Initial metadata URI (can be overwritten by _generateMetadataURI or updates).
     */
    function mintInitialEntity(address recipient, uint256 initialEssence, string memory initialUri) public onlyOwner {
        uint256 newTokenId = _nextTokenId++;
        _mint(recipient, newTokenId, initialEssence, initialUri);
    }

    /**
     * @dev Allows the token owner to infuse essence into their entity.
     * @param tokenId The ID of the entity token.
     * @param amount The amount of essence to infuse.
     */
    function infuseEssence(uint256 tokenId, uint256 amount) public nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved(); // Checks ownership

        _entities[tokenId].essenceInfused = _entities[tokenId].essenceInfused.add(amount);
        emit EssenceInfused(tokenId, amount);

        // Optionally sync state immediately after infusing
        syncEntityState(tokenId);
    }

    /**
     * @dev Public function for anyone to trigger a state synchronization for a token.
     * This recalculates dynamic attributes and updates the lastUpdatedBlock.
     * Could be incentivized in a real system.
     * @param tokenId The ID of the entity token.
     */
    function syncEntityState(uint256 tokenId) public {
        if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId(); // Checks existence

        ChronoEntity storage entity = _entities[tokenId];

        // Calculate essence decay based on time since last update
        uint256 blocksPassed = block.number - entity.lastUpdatedBlock;
        uint256 decayedEssence = entity.essenceInfused > (blocksPassed * globalParameters[PARAM_TYPE_ESSENCE_DECAY_RATE])
                                ? blocksPassed * globalParameters[PARAM_TYPE_ESSENCE_DECAY_RATE]
                                : entity.essenceInfused;
        entity.essenceInfused = entity.essenceInfused.sub(decayedEssence);

        // Calculate and update dynamic attributes
        mapping(uint256 => uint256) memory calculatedDynamics = _calculateDynamicAttributes(tokenId);
        entity.dynamicAttributes = calculatedDynamics; // Overwrite dynamic attributes

        entity.lastUpdatedBlock = block.number; // Update last sync time

        // Re-generate metadata URI if it's dynamic
        entity.metadataURI = _generateMetadataURI(tokenId);

        emit EntityStateSynced(tokenId, entity.essenceInfused, entity.auraInfluence, entity.currentStage);
    }


    // --- Dynamics & Evolution ---

    /**
     * @dev Defines the requirements and results for evolving an entity to the next stage.
     * @param fromStage The current stage to evolve from.
     * @param requirement Details of the evolution requirements and results.
     */
    function defineEvolutionRequirements(uint256 fromStage, EvolutionRequirement calldata requirement) public onlyOwner {
        require(fromStage > 0, "Stage must be positive");
        _evolutionRequirements[fromStage] = requirement;
        _evolutionRequirements[fromStage].exists = true; // Mark as existing
    }

    /**
     * @dev Attempts to evolve an entity to the next stage.
     * @param tokenId The ID of the entity token.
     */
    function evolveEntity(uint256 tokenId) public nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved();
        syncEntityState(tokenId); // Ensure state is up-to-date before checking requirements

        ChronoEntity storage entity = _entities[tokenId];
        uint256 currentStage = entity.currentStage;
        EvolutionRequirement storage req = _evolutionRequirements[currentStage];

        if (!req.exists) revert InvalidEvolutionStage();
        if (!checkEvolutionReadiness(tokenId)) revert EvolutionRequirementsNotMet();

        // Apply costs (if any, though requirements are usually minimums, not costs)
        // E.g., require 1000 essence, consume 500 essence during evolution:
        // entity.essenceInfused = entity.essenceInfused.sub(500);

        // Apply results
        entity.currentStage = entity.currentStage.add(1);
        entity.essenceInfused = entity.essenceInfused.add(req.addedBaseAttributes[ATTRIBUTE_TYPE_ESSENCE_EFFICIENCY]); // Example of adding essence based on evolution
        // Add/update base attributes
        for (uint256 i = 0; i < 256; i++) { // Iterate through potential attribute types (inefficient, use specific loops for real use)
            if (req.addedBaseAttributes[i] > 0) {
                entity.baseAttributes[i] = entity.baseAttributes[i].add(req.addedBaseAttributes[i]);
            }
             if (req.addedDynamicAttributes[i] > 0) {
                // Directly setting dynamic attributes here after sync might be confusing.
                // Better to add base attributes that INFLUENCE dynamic ones, or handle in _calculateDynamicAttributes.
                // For simplicity, let's assume evolution adds to BASE attributes, and sync re-calculates dynamics.
                // entity.dynamicAttributes[i] = entity.dynamicAttributes[i].add(req.addedDynamicAttributes[i]);
            }
        }
         // Set/clear status flags
        for (uint256 i = 0; i < 256; i++) { // Iterate through potential flag types
            if (req.setStatusFlags[i]) entity.statusFlags[i] = true;
            if (req.clearStatusFlags[i]) entity.statusFlags[i] = false;
        }

        // Update metadata URI if specified for the next stage
        if (bytes(req.newMetadataUri).length > 0) {
             entity.metadataURI = req.newMetadataUri;
        } else {
            // Or re-generate if it's always dynamic
             entity.metadataURI = _generateMetadataURI(tokenId);
        }


        // Recalculate dynamic attributes after evolution
        syncEntityState(tokenId);

        emit EvolutionTriggered(tokenId, entity.currentStage);
    }

    /**
     * @dev Checks if an entity meets the requirements for evolution to the next stage.
     * @param tokenId The ID of the entity token.
     * @return bool True if ready for evolution, false otherwise.
     */
    function checkEvolutionReadiness(uint256 tokenId) public view returns (bool) {
        if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId();
        ChronoEntity storage entity = _entities[tokenId];
        EvolutionRequirement storage req = _evolutionRequirements[entity.currentStage];

        if (!req.exists) return false; // No evolution defined for this stage

        // Check time elapsed
        if (block.number - entity.creationBlock < req.minBlocksSinceCreation) return false;

        // Check essence and aura
        if (entity.essenceInfused < req.requiredEssence) return false;
        if (entity.auraInfluence < req.requiredAura) return false;

        // Check base attributes
        for (uint256 i = 0; i < 256; i++) {
            if (req.requiredBaseAttributes[i] > 0 && entity.baseAttributes[i] < req.requiredBaseAttributes[i]) return false;
        }

        // Check dynamic attributes (sync first if needed, but for view functions, assume caller synced or accept stale)
        // Let's calculate dynamic attributes fresh for the check
        mapping(uint256 => uint256) memory currentDynamicAttributes = _calculateDynamicAttributes(tokenId);
         for (uint256 i = 0; i < 256; i++) {
            if (req.requiredDynamicAttributes[i] > 0 && currentDynamicAttributes[i] < req.requiredDynamicAttributes[i]) return false;
        }

        // Check status flags
         for (uint256 i = 0; i < 256; i++) {
            if (req.requiredStatusFlags[i] && !entity.statusFlags[i]) return false;
        }

        return true; // All requirements met
    }


    // --- Crafting & Utility ---

    /**
     * @dev Defines a crafting recipe that can be applied to an entity.
     * @param recipeId A unique ID for the recipe.
     * @param recipe Details of the recipe.
     */
    function defineCraftingRecipe(uint256 recipeId, CraftingRecipe calldata recipe) public onlyOwner {
        _craftingRecipes[recipeId] = recipe;
        _craftingRecipes[recipeId].exists = true; // Mark as existing
    }

    /**
     * @dev Allows the token owner to apply a crafting recipe to their entity.
     * Consumes essence and/or attributes and modifies the entity's state.
     * @param tokenId The ID of the entity token.
     * @param recipeId The ID of the crafting recipe to apply.
     */
    function craftItem(uint256 tokenId, uint256 recipeId) public nonReentrant {
         if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved();
         syncEntityState(tokenId); // Ensure state is up-to-date

         ChronoEntity storage entity = _entities[tokenId];
         CraftingRecipe storage recipe = _craftingRecipes[recipeId];

         if (!recipe.exists) revert InvalidRecipeId();

         // Check requirements
         if (entity.essenceInfused < recipe.requiredEssence[0]) revert CraftingRequirementsNotMet(); // Assuming a single essence type 0

         // Check base attributes minimums
         for (uint256 i = 0; i < 256; i++) {
             if (recipe.requiredBaseAttributes[i] > 0 && entity.baseAttributes[i] < recipe.requiredBaseAttributes[i]) revert CraftingRequirementsNotMet();
         }
         // Check dynamic attributes minimums (using current synced values)
          for (uint256 i = 0; i < 256; i++) {
             if (recipe.requiredDynamicAttributes[i] > 0 && entity.dynamicAttributes[i] < recipe.requiredDynamicAttributes[i]) revert CraftingRequirementsNotMet();
         }
         // Check status flags
         for (uint256 i = 0; i < 256; i++) {
             if (recipe.requiredStatusFlags[i] && !entity.statusFlags[i]) revert CraftingRequirementsNotMet();
         }

         // Apply costs (consume resources/attributes)
         entity.essenceInfused = entity.essenceInfused.sub(recipe.consumedEssence[0]); // Consume essence
          for (uint256 i = 0; i < 256; i++) {
             if (recipe.consumedBaseAttributes[i] > 0) {
                 // Ensure attribute doesn't go below zero (use SafeMath for subtraction)
                 entity.baseAttributes[i] = entity.baseAttributes[i].sub(recipe.consumedBaseAttributes[i]);
             }
         }

         // Apply results (add attributes, set/clear flags)
         for (uint256 i = 0; i < 256; i++) {
             if (recipe.resultAddedBaseAttributes[i] > 0) {
                 entity.baseAttributes[i] = entity.baseAttributes[i].add(recipe.resultAddedBaseAttributes[i]);
             }
              if (recipe.resultAddedDynamicAttributes[i] > 0) {
                 // Same note as evolution: better to add base attributes that influence dynamics.
                 // entity.dynamicAttributes[i] = entity.dynamicAttributes[i].add(recipe.resultAddedDynamicAttributes[i]);
             }
         }
          for (uint256 i = 0; i < 256; i++) {
             if (recipe.resultSetStatusFlags[i]) entity.statusFlags[i] = true;
             if (recipe.resultClearStatusFlags[i]) entity.statusFlags[i] = false;
         }

         // Re-generate metadata URI if state changes affect it
         entity.metadataURI = _generateMetadataURI(tokenId);

         // Recalculate dynamic attributes after crafting
         syncEntityState(tokenId); // Re-sync to reflect attribute changes

         emit ItemCrafted(tokenId, recipeId);
    }

    /**
     * @dev Defines the rules for merging two entities based on their types/stages.
     * @param ruleId A unique ID for the merge rule.
     * @param result Details of the resulting entity.
     */
    function defineMergeRules(uint256 ruleId, MergeResult calldata result) public onlyOwner {
        _mergeResults[ruleId] = result;
         _mergeResults[ruleId].exists = true; // Mark as existing
    }

     /**
     * @dev Allows the owner to merge two entities they own.
     * Burns the two source entities and mints a new one based on merge rules.
     * Requires specific rule ID input for lookup.
     * @param tokenId1 The ID of the first entity token to merge.
     * @param tokenId2 The ID of the second entity token to merge.
     * @param ruleId The ID of the merge rule to apply.
     */
    function mergeEntities(uint256 tokenId1, uint256 tokenId2, uint256 ruleId) public nonReentrant {
        // Must own both tokens
        if (ownerOf(tokenId1) != msg.sender) revert NotTokenOwnerOrApproved();
        if (ownerOf(tokenId2) != msg.sender) revert NotTokenOwnerOrApproved();
        if (tokenId1 == tokenId2) revert InvalidTokenId(); // Cannot merge an entity with itself

        syncEntityState(tokenId1); // Ensure state is up-to-date
        syncEntityState(tokenId2);

        ChronoEntity storage entity1 = _entities[tokenId1];
        ChronoEntity storage entity2 = _entities[tokenId2];
        MergeResult storage rule = _mergeResults[ruleId];

        if (!rule.exists) revert InvalidMergeRuleId();

        // Check merge requirements (e.g., minimum total essence, aura, specific stages/attributes)
        uint256 totalEssence = entity1.essenceInfused.add(entity2.essenceInfused);
        uint256 totalAura = entity1.auraInfluence.add(entity2.auraInfluence);

        if (totalEssence < rule.requiredEssenceTotal) revert MergeRequirementsNotMet();
        if (totalAura < rule.requiredAuraTotal) revert MergeRequirementsNotMet();

        // Add checks for required stages, attributes, etc. based on the `rule` struct if needed

        // Burn the two source entities
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint the new resulting entity
        uint256 newTokenId = _nextTokenId++;
        address recipient = msg.sender; // Mint to the merger

        _tokenOwners[newTokenId] = recipient;
        _balanceOf[recipient]++;

        // Initialize new entity data from the merge rule results
        _entities[newTokenId].creationBlock = block.number; // New creation time
        _entities[newTokenId].lastUpdatedBlock = block.number;
        _entities[newTokenId].essenceInfused = totalEssence; // Could be based on rule or sum
        _entities[newTokenId].auraInfluence = totalAura;     // Could be based on rule or sum
        _entities[newTokenId].currentStage = rule.resultingStage;
        _entities[newTokenId].metadataURI = rule.newMetadataUri; // Use URI defined in rule

         // Set base attributes for the new entity from the rule
         for (uint256 i = 0; i < 256; i++) {
             if (rule.resultingBaseAttributes[i] > 0) {
                 _entities[newTokenId].baseAttributes[i] = rule.resultingBaseAttributes[i];
             }
         }
         // Set status flags for the new entity from the rule
         for (uint256 i = 0; i < 256; i++) {
              if (rule.resultingStatusFlags[i]) _entities[newTokenId].statusFlags[i] = true;
         }

        // Calculate initial dynamic attributes for the new entity
        _calculateDynamicAttributes(newTokenId); // Recalculate dynamic attributes for the new entity

        emit Transfer(address(0), recipient, newTokenId); // Mint event for the new token
        emit EntitiesMerged(tokenId1, tokenId2, newTokenId);
    }

    /**
     * @dev Allows the owner of a token to permanently destroy it.
     * @param tokenId The ID of the entity token to burn.
     */
    function burnEntity(uint256 tokenId) public nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved();
        _burn(tokenId);
    }

    // --- Oracle Integration ---

    /**
     * @dev Sets the address of the trusted oracle contract.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        _oracleAddress = _oracle;
    }

    /**
     * @dev Simulates requesting an aura update for a specific entity from the oracle.
     * Emits an event that the oracle listener watches.
     * @param tokenId The ID of the entity token.
     * @param callbackData Additional data for the oracle callback.
     */
    function requestAuraUpdate(uint256 tokenId, bytes memory callbackData) public {
        // Basic check if token exists
        if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId();

        // In a real Chainlink integration, you'd build the request here.
        // For this example, we just generate a request ID and emit an event.
        uint256 requestId = _oracleRequestIdCounter++;
        _oracleRequestIdToTokenId[requestId] = tokenId;

        emit OracleAuraUpdateRequest(requestId, tokenId, callbackData);
    }

    /**
     * @dev Callback function for the oracle to update the aura influence for an entity.
     * Can only be called by the designated oracle address.
     * @param requestId The ID of the original request.
     * @param auraValue The aura value provided by the oracle.
     */
    function fulfillAuraUpdate(uint256 requestId, uint256 auraValue) external onlyOracle {
        uint256 tokenId = _oracleRequestIdToTokenId[requestId];
        // Check if request ID is valid/exists (e.g., not 0 if 0 is not used, or use a mapping of requestIds to processed status)
        // For simplicity, assuming requestId > 0 and is unique per request.
        if (_tokenOwners[tokenId] == address(0)) {
             // Handle error - token might have been burned or ID invalid
             // Could log an error or ignore, depending on desired behavior.
             // For now, revert to indicate oracle sent data for non-existent token/request.
             revert OracleCallbackFailed();
        }

        // Update the entity's aura influence
        _entities[tokenId].auraInfluence = _entities[tokenId].auraInfluence.add(auraValue); // Accumulate aura

        // Optionally sync state immediately after aura update
        syncEntityState(tokenId);

        emit AuraInfluenceUpdated(tokenId, auraValue, requestId);
    }

    // --- Governance (Simple Parameter Voting) ---

    /**
     * @dev Allows a designated proposer role (or anyone, configurable) to propose changing a global parameter.
     * Requires the parameter type to be registered or known.
     * @param paramType The type of parameter to change (e.g., PARAM_TYPE_ESSENCE_DECAY_RATE).
     * @param newValue The new value proposed for the parameter.
     */
    function proposeParameterChange(uint256 paramType, uint256 newValue) public {
         // Restrict proposer role if needed: only(ProposerRole) or check some balance/NFT ownership
         // For simplicity, anyone can propose for now

         // Check if parameter type is valid (can add more checks if needed)
        if (paramType == 0 || paramType > 100) revert InvalidParameterType(); // Example basic check

         uint256 proposalId = _nextProposalId++;
         _proposals[proposalId] = GovernanceProposal({
             active: true,
             proposalId: proposalId,
             paramType: paramType,
             newValue: newValue,
             voteCount: 0,
             votingDeadline: block.number.add(globalParameters[PARAM_TYPE_GOVERNANCE_VOTING_PERIOD_BLOCKS]),
             executed: false,
             hasVoted: new mapping(address => bool) // Initialize empty mapping
         });

         emit ParameterChangeProposed(proposalId, paramType, newValue, msg.sender);
    }

    /**
     * @dev Allows eligible voters (e.g., token owners) to vote on an active proposal.
     * Simple 1 address = 1 vote for this example.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote in favor, false for against (simple majority/threshold assumed).
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        GovernanceProposal storage proposal = _proposals[proposalId];

        if (!proposal.active || block.number > proposal.votingDeadline || proposal.executed) revert ProposalNotFoundOrInactive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        // Check if voter is eligible (e.g., must own at least one entity, or have a certain balance of a governance token)
        // require(balanceOf(msg.sender) > 0, "Must own an entity to vote"); // Example requirement

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.voteCount++; // Simple count
        }
        // Votes against are implicit or counted separately in more complex systems.
        // Here, we just track 'yes' votes against a threshold of *total possible* votes (or active voters).
        // For simplicity, let's assume the threshold is based on `voteCount` needing to reach a percentage of *something*
        // e.g., total token supply, or a fixed quorum number. Let's use a simple vote count threshold for this example.

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a proposal if the voting period is over and it met the threshold.
     * Anyone can call this after the voting deadline.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        GovernanceProposal storage proposal = _proposals[proposalId];

        if (!proposal.active || block.number <= proposal.votingDeadline || proposal.executed) revert ProposalNotFoundOrInactive();

        // Calculate if threshold is met.
        // This is tricky with simple counts. A real system needs a defined voting power (token balance, NFT count, stake)
        // and a defined quorum (minimum participation) and threshold (percentage of votes needed).
        // Let's use a simplified example: voteCount must exceed a fixed number or percentage of total entities minted.
        // Example: Needs votes > 10% of total supply
        // uint256 requiredVotes = totalSupply().mul(globalParameters[PARAM_TYPE_GOVERNANCE_VOTE_THRESHOLD]).div(10000);
        // if (proposal.voteCount < requiredVotes) revert ProposalThresholdNotMet();

        // Example simplified threshold: requires a fixed number of YES votes, OR requires 60% of *those who voted* were yes.
        // This simple `voteCount` approach works best if the threshold is a fixed number,
        // or if you track total participants vs yes votes.
        // Let's assume a fixed number of YES votes is required for this example:
        uint256 fixedVoteThreshold = 5; // Example: Needs at least 5 yes votes
        if (proposal.voteCount < fixedVoteThreshold) revert ProposalThresholdNotMet();


        // Execute the proposed change
        uint256 paramType = proposal.paramType;
        uint256 newValue = proposal.newValue;

         // Apply the parameter change
         if (paramType == PARAM_TYPE_ESSENCE_DECAY_RATE) {
             globalParameters[PARAM_TYPE_ESSENCE_DECAY_RATE] = newValue;
         } else if (paramType == PARAM_TYPE_AURA_IMPACT_FACTOR) {
             globalParameters[PARAM_TYPE_AURA_IMPACT_FACTOR] = newValue;
         } // Add more parameter types here

        proposal.active = false;
        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }


    // --- View Functions ---

    /**
     * @dev Returns the full details of a ChronoEntity.
     * @param tokenId The ID of the entity token.
     * @return ChronoEntity The entity struct.
     */
    function getEntityDetails(uint256 tokenId) public view returns (ChronoEntity memory) {
        if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId();
        // Note: Mappings within a struct cannot be returned directly.
        // We need to construct a memory struct and copy data, EXCEPT the nested mappings.
        // To view mapping data, use specific getter functions (getBaseAttribute, getDynamicAttribute, getStatusFlag).
        ChronoEntity storage entity = _entities[tokenId];
        ChronoEntity memory entityMemory = entity; // Copy basic fields
        // Mappings are NOT copied by this assignment.
        return entityMemory; // Caller needs to use separate calls for mappings
    }

     /**
     * @dev Returns a specific base attribute value for an entity.
     * @param tokenId The ID of the entity token.
     * @param attributeType The type of base attribute to get.
     * @return uint256 The base attribute value.
     */
    function getBaseAttribute(uint256 tokenId, uint256 attributeType) public view returns (uint256) {
         if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId();
         return _entities[tokenId].baseAttributes[attributeType];
    }

    /**
     * @dev Returns a specific dynamic attribute value for an entity.
     * Note: This value might be stale if syncEntityState hasn't been called recently.
     * @param tokenId The ID of the entity token.
     * @param attributeType The type of dynamic attribute to get.
     * @return uint256 The dynamic attribute value.
     */
    function getDynamicAttribute(uint256 tokenId, uint256 attributeType) public view returns (uint256) {
        if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId();
        // Option 1: Return potentially stale stored value
        // return _entities[tokenId].dynamicAttributes[attributeType];

        // Option 2: Calculate fresh value (can be resource intensive for complex logic)
        // Let's return the stored value as per the struct definition.
        return _entities[tokenId].dynamicAttributes[attributeType];
    }

    /**
     * @dev Returns a specific status flag value for an entity.
     * @param tokenId The ID of the entity token.
     * @param statusType The type of status flag to get.
     * @return bool The status flag value.
     */
    function getStatusFlag(uint256 tokenId, uint256 statusType) public view returns (bool) {
         if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId();
         return _entities[tokenId].statusFlags[statusType];
    }

    /**
     * @dev Returns the details of a crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return CraftingRecipe The recipe struct.
     */
    function getCraftingRecipe(uint256 recipeId) public view returns (CraftingRecipe memory) {
        CraftingRecipe storage recipe = _craftingRecipes[recipeId];
        if (!recipe.exists) revert InvalidRecipeId();
        // Same limitation as getEntityDetails: mappings within the struct cannot be returned.
        // A helper function to return specific mapping values would be needed if they are complex.
        // For simplicity, just return the main struct fields.
        CraftingRecipe memory recipeMemory = recipe;
        return recipeMemory;
    }

    /**
     * @dev Returns the requirements for a specific evolution stage.
     * @param evolutionStage The stage to check requirements for.
     * @return EvolutionRequirement The requirement struct.
     */
    function getEvolutionRequirements(uint256 evolutionStage) public view returns (EvolutionRequirement memory) {
         EvolutionRequirement storage req = _evolutionRequirements[evolutionStage];
         if (!req.exists) revert InvalidEvolutionStage();
          // Same limitation: mappings not returned.
         EvolutionRequirement memory reqMemory = req;
         return reqMemory;
    }

    /**
     * @dev Returns the rules for a specific merge outcome.
     * @param ruleId The ID of the merge rule.
     * @return MergeResult The merge rule struct.
     */
    function getMergeResultRules(uint256 ruleId) public view returns (MergeResult memory) {
         MergeResult storage rule = _mergeResults[ruleId];
         if (!rule.exists) revert InvalidMergeRuleId();
          // Same limitation: mappings not returned.
         MergeResult memory ruleMemory = rule;
         return ruleMemory;
    }

    /**
     * @dev Returns the details of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return GovernanceProposal The proposal struct.
     */
    function getProposalDetails(uint256 proposalId) public view returns (GovernanceProposal memory) {
        GovernanceProposal storage proposal = _proposals[proposalId];
        if (!proposal.active && !proposal.executed && proposal.proposalId == 0) revert ProposalNotFoundOrInactive(); // Basic existence check
        // Same limitation: `hasVoted` mapping not returned.
        GovernanceProposal memory proposalMemory = proposal;
        return proposalMemory;
    }

    /**
     * @dev Returns the human-readable name registered for an attribute type ID.
     * @param attributeType The ID of the attribute type.
     * @return string The registered name.
     */
    function getRegisteredAttributeName(uint256 attributeType) public view returns (string memory) {
        string memory name_ = _attributeNames[attributeType];
        if (bytes(name_).length == 0) revert AttributeTypeNotRegistered();
        return name_;
    }


    // --- Admin/Configuration ---

    /**
     * @dev Admin function to forcefully set a base attribute value for an entity.
     * Use with caution. Could be restricted to governance.
     * @param tokenId The ID of the entity token.
     * @param attributeType The type of base attribute to set.
     * @param value The new value for the attribute.
     */
    function setBaseAttributeAdmin(uint256 tokenId, uint256 attributeType, uint256 value) public onlyOwner {
        if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId();
        _entities[tokenId].baseAttributes[attributeType] = value;
        // Recalculate dynamic attributes after changing base attribute
        syncEntityState(tokenId);
    }

     /**
     * @dev Admin function to forcefully set a status flag for an entity.
     * Use with caution. Could be restricted to governance.
     * @param tokenId The ID of the entity token.
     * @param statusType The type of status flag to set.
     * @param status The new status value (true/false).
     */
    function setStatusFlagAdmin(uint256 tokenId, uint256 statusType, bool status) public onlyOwner {
        if (_tokenOwners[tokenId] == address(0)) revert InvalidTokenId();
        _entities[tokenId].statusFlags[statusType] = status;
         // Recalculate dynamic attributes if flags influence them
        syncEntityState(tokenId);
    }

    /**
     * @dev Admin function to register a human-readable name for an attribute type ID.
     * Useful for off-chain tools to interpret attribute IDs.
     * @param attributeType The ID of the attribute type.
     * @param name The human-readable name.
     */
    function registerAttributeType(uint256 attributeType, string memory name) public onlyOwner {
        require(attributeType > 0, "Attribute type must be positive");
        _attributeNames[attributeType] = name;
        emit AttributeTypeRegistered(attributeType, name);
    }


    /**
     * @dev Admin function to set a global contract parameter directly.
     * Could be restricted or replaced by the governance mechanism.
     * @param paramType The type of parameter to set.
     * @param newValue The new value.
     */
    function setGlobalParameter(uint256 paramType, uint256 newValue) public onlyOwner {
        // Basic check if parameter type is valid
        if (paramType == 0 || paramType > 100) revert InvalidParameterType(); // Example basic check

        globalParameters[paramType] = newValue;
    }

    /**
     * @dev Admin function to withdraw any tokens accidentally sent to the contract.
     * Does not handle native ETH (requires receive/fallback).
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawAdminFunds(address tokenAddress, uint256 amount) public onlyOwner {
        // Check if it's a standard ERC20 token
        require(tokenAddress != address(0) && tokenAddress.code.length > 0, "Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Token transfer failed");
    }

    // Fallback and Receive to handle potential ETH transfers (optional but good practice)
    receive() external payable {}
    fallback() external payable {}

    // Admin withdrawal for Native ETH
    function withdrawEther(uint256 amount) public onlyOwner {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}

// Mock ERC20 interface for withdrawAdminFunds - in a real project, import @openzeppelin/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Mock IERC165 interface - import @openzeppelin/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```

**Explanation of Concepts and Features:**

1.  **Dynamic Attributes:** Entity attributes (`dynamicAttributes`) are not fixed values stored directly, but are *calculated* based on the entity's current state (`essenceInfused`, `auraInfluence`, `baseAttributes`, `statusFlags`) and time (`block.number`). The `_calculateDynamicAttributes` internal function encapsulates this logic.
2.  **State Sync (`syncEntityState`):** Because dynamic attributes change with time and cumulative resources, a function is needed to trigger the recalculation and update the on-chain state. This is crucial because view functions cannot modify state, and calling the calculation logic in a view function might be too gas-intensive for complex calculations. `syncEntityState` applies decay (like essence decay) and updates the stored dynamic values. It's designed so anyone can call it to refresh an entity's state, enabling off-chain tools to always display the latest values after a sync.
3.  **Internal Resource (`essenceInfused`):** The contract tracks "essence" infused into each entity. This acts as a sink – users spend *something* (conceptually, it could be burning an external token, or just an internal cost) to increase this value, which then boosts dynamic attributes.
4.  **Oracle Integration Pattern:** The contract includes `requestAuraUpdate` and `fulfillAuraUpdate`. This is the standard pattern for interacting with off-chain data sources like Chainlink. The contract emits an event (`OracleAuraUpdateRequest`) when it needs data for a specific `tokenId`. An off-chain listener (like a Chainlink node) picks up this event, fetches the real-world data, and calls `fulfillAuraUpdate` on the contract with the result. The `onlyOracle` modifier ensures only the trusted oracle can provide data.
5.  **Evolution (`evolveEntity`):** Entities can transition between stages (`currentStage`) if they meet certain criteria defined by `EvolutionRequirement` structs. This consumes the requirements and modifies the entity's state (adding base attributes, changing flags, updating metadata).
6.  **Crafting (`craftItem`):** Users can apply predefined `CraftingRecipe`s to their entities. This consumes internal resources (essence, potentially attributes) and adds/changes other attributes or status flags, allowing for customization or progression paths.
7.  **Merging (`mergeEntities`):** A more complex interaction where two entities are consumed to produce a new one, potentially with combined or new attributes based on `MergeResult` rules. This is another resource sink/progression mechanic.
8.  **Governance (`proposeParameterChange`, `voteOnProposal`, `executeProposal`):** A simple voting mechanism is included to allow some level of community input on global parameters that affect entity dynamics (e.g., essence decay rate, aura impact). This adds a decentralized governance layer, albeit simplified (1 address = 1 vote, basic threshold).
9.  **Structured Data:** Using `struct` and `mapping` allows for storing complex, multi-faceted data for each NFT, going beyond simple key-value pairs often seen in basic token metadata.
10. **Manual ERC721 Implementation:** Instead of inheriting OpenZeppelin's `ERC721`, core functions like `_transfer`, `_mint`, `_burn` are implemented directly. This allows tighter integration with the entity's internal state management and lifecycle hooks like `_beforeTokenTransfer`.
11. **Attribute Naming:** `registerAttributeType` and `getRegisteredAttributeName` allow the contract owner (or governance) to provide human-readable names for the numeric attribute IDs, making integration easier for frontends and off-chain tools without hardcoding names.
12. **Safety:** Includes `Ownable` for administrative functions, `ReentrancyGuard` for complex state-changing functions, and basic input validation. `SafeMath` is used for arithmetic.

This contract provides a foundation for a dynamic NFT ecosystem with various interactive and evolving elements, suitable for gaming, digital collectibles, or novel art projects.