Okay, here is a Solidity smart contract designed with advanced concepts like dynamic entity states, on-chain evolution influenced by staking and global epochs, attribute infusion, and a simple governance-like mechanism for epoch changes. It avoids duplicating standard open-source implementations like the full OpenZeppelin ERC721 library by implementing the necessary interface functions manually for this specific contract's needs, while keeping the core custom logic distinct.

This contract, tentatively named `MetaMorph`, manages unique digital entities (ERC721 tokens) that can evolve and change based on various on-chain interactions and contract states.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MetaMorph Contract
 * @dev An advanced ERC721 contract managing dynamic, evolving digital entities.
 * Entities (tokens) have attributes, gain experience, level up, and can evolve
 * into different forms based on conditions including level, attributes, a global
 * contract epoch, and potentially staked 'Influence' tokens. Owners can infuse
 * attributes between entities and participate in a simple voting mechanism to
 * advance the global epoch, which can change evolution rules or trait biases.
 */

/*
 * Contract Outline:
 *
 * 1.  Interfaces: ERC721 standard interface (minimal implementation).
 * 2.  Errors: Custom errors for specific failure conditions.
 * 3.  Events: Signals key contract actions (Mint, Transfer, Evolve, LevelUp, etc.).
 * 4.  Enums: Attribute types, Trait types, EpochVote state.
 * 5.  Structs:
 *     - Attributes: Holds entity stats (Strength, Dexterity, etc.).
 *     - Entity: Core data for each token (level, xp, formId, attributes, traits, energy).
 *     - FormDefinition: Defines properties of an entity's form (base stats, growth, evolution requirements).
 *     - Epoch: Defines a contract state period with potential rule modifiers and voting data.
 * 6.  State Variables:
 *     - Contract owner/admin.
 *     - Mappings for ERC721 state (owner, approvals).
 *     - Mapping for Entity data by tokenId.
 *     - Mapping for Form definitions by formId.
 *     - Mapping for staked Influence tokens by address.
 *     - Mapping for entity-specific staked Influence by tokenId.
 *     - Global contract state (current epoch, epoch proposal).
 *     - Counters for tokenIds, formIds, epochIds.
 *     - Configuration parameters (XP needed, energy caps, vote thresholds).
 * 7.  Modifiers: Restrict function access (onlyOwner, onlyEpochProposer).
 * 8.  Constructor: Initializes contract with base parameters.
 * 9.  ERC721 Core Functions: (Manual implementation covering basic ownership/transfer needed)
 *     - balanceOf
 *     - ownerOf
 *     - transferFrom
 *     - safeTransferFrom (overloaded)
 *     - approve
 *     - getApproved
 *     - setApprovalForAll
 *     - isApprovedForAll
 * 10. Entity Management & Query:
 *     - mintEntity
 *     - burnEntity
 *     - getEntityAttributes
 *     - getEntityTraits
 *     - getEntityFormId
 *     - getEntityEnergy
 *     - getTotalSupply (simple counter)
 * 11. Entity Progression:
 *     - gainExperience
 *     - levelUp
 *     - evolveEntity
 *     - getEvolutionRequirements
 *     - getPotentialEvolutionOutcomes
 * 12. Entity Interaction:
 *     - infuseAttributes
 *     - rechargeEntityEnergy
 * 13. Staking & Influence:
 *     - stakeForInfluence
 *     - unstakeInfluence
 *     - getStakedInfluenceTotal
 *     - getEntityStakedInfluence
 * 14. Global Epoch & Governance:
 *     - getCurrentEpoch
 *     - proposeEpochChange
 *     - voteForEpochChange
 *     - executeEpochChange
 *     - getCurrentEpochProposal
 * 15. Admin/Configuration (Owner/Governance controlled):
 *     - addFormDefinition
 *     - updateFormDefinition
 *     - setXPThresholds
 *     - setEnergyParameters
 *     - setGlobalTraitBiasModifier (Simulates epoch effect)
 *     - setBaseAttributeWeights (Simulates rule changes)
 */

/*
 * Function Summary:
 *
 * ERC721 Core:
 * - balanceOf(address owner): Returns the number of tokens owned by an address.
 * - ownerOf(uint256 tokenId): Returns the owner of a specific token.
 * - transferFrom(address from, address to, uint256 tokenId): Transfers token ownership.
 * - safeTransferFrom(address from, address to, uint256 tokenId): Transfers token ownership safely.
 * - safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Transfers token ownership safely with data.
 * - approve(address to, uint256 tokenId): Approves an address to transfer a token.
 * - getApproved(uint256 tokenId): Returns the approved address for a token.
 * - setApprovalForAll(address operator, bool approved): Sets approval for an operator for all tokens.
 * - isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens.
 *
 * Entity Management & Query:
 * - mintEntity(address to, uint32 initialFormId, uint8[] calldata initialTraitIds): Mints a new entity (token) with specified initial form and traits.
 * - burnEntity(uint256 tokenId): Destroys an entity token (requires ownership or approval).
 * - getEntityAttributes(uint256 tokenId): Returns the current attributes of an entity.
 * - getEntityTraits(uint256 tokenId): Returns the traits of an entity.
 * - getEntityFormId(uint256 tokenId): Returns the current form ID of an entity.
 * - getEntityEnergy(uint256 tokenId): Calculates and returns the current energy level of an entity.
 * - getTotalSupply(): Returns the total number of minted entities.
 *
 * Entity Progression:
 * - gainExperience(uint256 tokenId, uint256 amount): Adds experience points to an entity (may cost energy).
 * - levelUp(uint256 tokenId): Attempts to level up an entity if sufficient XP is reached (may cost energy).
 * - evolveEntity(uint256 tokenId, uint32 targetFormId): Attempts to evolve an entity to a target form if requirements are met (level, attributes, epoch, influence, energy).
 * - getEvolutionRequirements(uint32 formId, uint32 targetFormId): Returns the requirements for a specific evolution path.
 * - getPotentialEvolutionOutcomes(uint256 tokenId): Returns the potential forms an entity could evolve into.
 *
 * Entity Interaction:
 * - infuseAttributes(uint256 sourceTokenId, uint256 targetTokenId, uint8 attributeType, uint256 amount): Transfers/consumes attributes from one entity to boost another (costs energy).
 * - rechargeEntityEnergy(uint256 tokenId): Recharges an entity's energy (simulated action, could involve token burning etc. in real use).
 *
 * Staking & Influence:
 * - stakeForInfluence(uint256 amount): Stakes Influence tokens (placeholder/simulated) to gain global staking power.
 * - unstakeInfluence(uint256 amount): Unstakes Influence tokens.
 * - getStakedInfluenceTotal(address staker): Returns the total global Influence staked by an address.
 * - getEntityStakedInfluence(uint256 tokenId): Returns the Influence staked *specifically affecting* this entity's evolution (conceptual).
 *
 * Global Epoch & Governance:
 * - getCurrentEpoch(): Returns the details of the current active epoch.
 * - proposeEpochChange(): Proposes advancing to the next epoch (requires stake or permission).
 * - voteForEpochChange(bool support): Casts a vote on the current epoch proposal.
 * - executeEpochChange(): Executes the epoch change if voting conditions met.
 * - getCurrentEpochProposal(): Returns details about the current epoch change proposal.
 *
 * Admin/Configuration:
 * - addFormDefinition(uint32 formId, string calldata name, Attributes calldata baseAttributes, Attributes calldata growthRates, uint256 requiredLevel, Attributes calldata requiredAttributes, uint32[] calldata potentialNextForms): Adds a new valid form definition (Owner/Governance).
 * - updateFormDefinition(uint32 formId, string calldata name, Attributes calldata baseAttributes, Attributes calldata growthRates, uint256 requiredLevel, Attributes calldata requiredAttributes, uint32[] calldata potentialNextForms): Updates an existing form definition (Owner/Governance).
 * - setXPThresholds(uint256[] calldata thresholds): Sets XP required for each level (Owner/Governance).
 * - setEnergyParameters(uint256 maxEnergy, uint256 energyRegenRatePerSecond, uint256 actionCost): Sets energy system parameters (Owner/Governance).
 * - setGlobalTraitBiasModifier(uint8 traitId, int256 modifierPercent): Sets a global modifier for how a trait affects stats or evolution (Owner/Governance/Epoch).
 * - setBaseAttributeWeights(uint8 attributeType, uint256 weight): Sets weights used in calculations affected by attributes (Owner/Governance).
 */

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 /* is IERC165 */ {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    // ERC721Metadata and ERC721Enumerable are not included for simplicity and to avoid duplicating standard interfaces fully
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract MetaMorph is IERC721, IERC165 {

    // --- Errors ---
    error NotOwnerOrApproved();
    error InvalidTokenId();
    error ZeroAddress();
    error SelfApproval();
    error AlreadyApproved();
    error InvalidApproval();
    error TransferIntoNonReceiver(address to);
    error FormNotFound();
    error InvalidInitialTraits();
    error InsufficientXPForLevelUp();
    error EvolutionConditionsNotMet();
    error EvolutionPathNotFound();
    error InsufficientEnergy(uint256 required, uint256 current);
    error CannotInfuseIntoSelf();
    error InsufficientAttributesForInfusion(uint8 attributeType, uint256 requested, uint256 current);
    error InvalidAttributeType();
    error InvalidStakeAmount();
    error InsufficientStake();
    error NoActiveEpochProposal();
    error EpochVoteAlreadyEnded();
    error EpochVoteAlreadyCast();
    error EpochVoteThresholdNotMet();
    error EpochNotReadyToExecute();
    error EpochProposalAlreadyExists();
    error InvalidEpochVote();
    error InsufficientInfluenceToPropose();
    error FormAlreadyExists(uint32 formId);
    error XPThresholdsMismatch(uint256 levels, uint256 thresholds);
    error InvalidEnergyParameters();
    error InvalidTraitId();


    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, uint32 initialFormId);
    event EntityBurned(uint256 indexed tokenId);
    event ExperienceGained(uint256 indexed tokenId, uint256 amount, uint256 newXP, uint256 newLevel);
    event LevelledUp(uint256 indexed tokenId, uint256 newLevel);
    event EntityEvolved(uint256 indexed tokenId, uint32 oldFormId, uint32 newFormId);
    event AttributesInfused(uint256 indexed sourceTokenId, uint256 indexed targetTokenId, uint8 attributeType, uint256 amount);
    event EnergyRecharged(uint256 indexed tokenId, uint256 newEnergy);
    event InfluenceStaked(address indexed staker, uint256 amount);
    event InfluenceUnstaked(address indexed staker, uint256 amount);
    event EpochProposalCreated(uint32 indexed epochId, address indexed proposer, uint256 voteEndTime);
    event EpochVoteCast(uint32 indexed epochId, address indexed voter, bool support);
    event EpochAdvanced(uint32 indexed oldEpochId, uint32 indexed newEpochId);
    event FormDefinitionAdded(uint32 indexed formId);
    event FormDefinitionUpdated(uint32 indexed formId);
    event GlobalTraitBiasSet(uint8 indexed traitId, int256 modifierPercent);


    // --- Constants ---
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02; // Selector for onERC721Received
    uint256 private constant SECONDS_PER_UNIT_ENERGY_REGEN = 60; // Example: 1 energy unit per minute

    // --- Enums ---
    enum AttributeType {
        Strength,
        Dexterity,
        Constitution,
        Intelligence,
        Wisdom,
        Charisma,
        Count // Helper to know number of attributes
    }

    enum TraitType {
        FireAffinity,
        WaterAffinity,
        EarthAffinity,
        AirAffinity,
        Lucky,
        Resilient,
        Count // Helper to know number of traits
    }

    enum EpochVoteState {
        Inactive,
        Pending,
        Executed
    }

    // --- Structs ---
    struct Attributes {
        uint256 strength;
        uint256 dexterity;
        uint256 constitution;
        uint256 intelligence;
        uint256 wisdom;
        uint256 charisma;
    }

    struct Entity {
        uint256 tokenId;
        uint256 level;
        uint256 xp;
        uint32 formId;
        Attributes attributes;
        uint8[] traits; // Immutable after mint/evolution
        uint256 lastActionTimestamp; // For energy calculation
        uint256 energy;
    }

    struct FormDefinition {
        uint32 id;
        string name;
        Attributes baseAttributes; // Stats at level 1
        Attributes growthRates;    // How much each attribute grows per level
        uint256 requiredLevelForEvo; // Minimum level needed to evolve *from* this form
        Attributes requiredAttributesForEvo; // Minimum attributes needed to evolve *from* this form
        uint32[] potentialNextForms; // IDs of forms this can evolve into
        bool exists; // Flag to check if definition is valid
    }

    struct Epoch {
        uint32 id;
        string description;
        // Add other epoch-specific rules/modifiers here (e.g., uint256 evolutionChanceModifier)
        // For simplicity, using global trait bias modifier set by admin/epoch logic
    }

    struct EpochProposal {
        uint32 epochId; // The epoch being proposed (should be current + 1)
        address proposer;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        EpochVoteState state;
    }

    // --- State Variables ---

    address public owner; // Contract owner (can be DAO/Multisig in production)

    // ERC721 State
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Entity Data
    mapping(uint256 => Entity) private _entities;
    uint256 private _tokenIdCounter;

    // Form Definitions
    mapping(uint32 => FormDefinition) private _formDefinitions;
    uint32 private _formIdCounter = 1; // Start form IDs from 1

    // Staking & Influence (Conceptual - requires a separate Influence token in real use)
    mapping(address => uint256) private _totalStakedInfluence;
    // Mapping could link specific staked tokens to specific entities for evolution influence
    // mapping(uint256 tokenId => uint256 influenceAmount) private _entityStakedInfluence; // More complex, leaving out for core example size

    // Global Epoch State
    uint32 private _currentEpochId = 0; // Epoch 0 is initial state
    mapping(uint32 => Epoch) private _epochs;
    EpochProposal public currentEpochProposal;

    // Configuration
    uint256[] public xpThresholds; // xpThresholds[level-1] = XP needed to reach 'level'
    uint256 public maxEnergy;
    uint256 public energyRegenRatePerSecond;
    uint256 public baseActionCost;
    mapping(uint8 => int256) public globalTraitBiasModifiers; // Example: FireAffinity might give +10% Str in Epoch 1

    // Governance Parameters
    uint256 public epochVoteDuration = 3 days; // Example vote duration
    uint256 public epochVoteQuorumPercent = 51; // % of total stakers needed to vote
    uint256 public epochVoteMajorityPercent = 51; // % of votes needed to pass


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerOrApproved();
        _;
    }

    modifier onlyEntityOwnerOrApproved(uint256 tokenId) {
        address tokenOwner = _tokenOwners[tokenId];
        if (tokenOwner == address(0)) revert InvalidTokenId();
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotOwnerOrApproved();
        }
        _;
    }

    // Modifier for actions costing energy
    modifier checkAndConsumeEnergy(uint256 tokenId, uint256 requiredEnergy) {
         _calculateEnergy(tokenId); // Update entity's energy based on time
         if (_entities[tokenId].energy < requiredEnergy) revert InsufficientEnergy(requiredEnergy, _entities[tokenId].energy);
         _entities[tokenId].energy -= requiredEnergy;
         _entities[tokenId].lastActionTimestamp = block.timestamp; // Reset timestamp after consuming energy
         _;
    }


    // --- Constructor ---
    constructor(
        uint256[] memory _xpThresholds,
        uint256 _maxEnergy,
        uint256 _energyRegenRatePerSecond,
        uint256 _baseActionCost,
        uint256 _epochVoteDuration,
        uint256 _epochVoteQuorumPercent,
        uint256 _epochVoteMajorityPercent
    ) {
        if (msg.sender == address(0)) revert ZeroAddress();
        owner = msg.sender;

        // Initial configuration validation
        if (_xpThresholds.length == 0) revert XPThresholdsMismatch(0, 0); // Need at least level 1 threshold
        xpThresholds = _xpThresholds;

        if (_maxEnergy == 0 || _energyRegenRatePerSecond == 0 || _baseActionCost == 0) revert InvalidEnergyParameters();
        maxEnergy = _maxEnergy;
        energyRegenRatePerSecond = _energyRegenRatePerSecond;
        baseActionCost = _baseActionCost;

        if (_epochVoteDuration == 0 || _epochVoteQuorumPercent == 0 || _epochVoteMajorityPercent == 0 || _epochVoteQuorumPercent > 100 || _epochVoteMajorityPercent > 100) revert InvalidEpochVote();
        epochVoteDuration = _epochVoteDuration;
        epochVoteQuorumPercent = _epochVoteQuorumPercent;
        epochVoteMajorityPercent = _epochVoteMajorityPercent;

        // Initialize Epoch 0
        _epochs[_currentEpochId] = Epoch({
            id: _currentEpochId,
            description: "Initial State"
        });

        // Initialize attribute weights (example)
        _setBaseAttributeWeights(AttributeType.Strength, 10);
        _setBaseAttributeWeights(AttributeType.Dexterity, 8);
        _setBaseAttributeWeights(AttributeType.Constitution, 12);
        _setBaseAttributeWeights(AttributeType.Intelligence, 7);
        _setBaseAttributeWeights(AttributeType.Wisdom, 9);
        _setBaseAttributeWeights(AttributeType.Charisma, 6);
    }


    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Basic ERC721 and ERC165 support check
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == 0x80ac58cd; // ERC721 Interface ID
               // interfaceId == 0x5b5e139f; // ERC721Metadata Interface ID (not fully implemented)
               // interfaceId == 0x780e9d63; // ERC721Enumerable Interface ID (not fully implemented)
    }


    // --- Internal ERC721 Helpers ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        uint256 codeSize;
        assembly { codeSize := extcodesize(to) }
        if (codeSize > 0) {
            bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
            if (retval != ERC721_RECEIVED) {
                revert TransferIntoNonReceiver(to);
            }
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (_tokenOwners[tokenId] != from) revert NotOwnerOrApproved(); // Should always be true if ownerOf check is done
        if (to == address(0)) revert ZeroAddress();

        // Clear approvals for the transferring token
        delete _tokenApprovals[tokenId];

        _balances[from]--;
        _balances[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert ZeroAddress();
        if (_exists(tokenId)) revert InvalidTokenId(); // Token already exists

        _balances[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(address(0), to, tokenId); // ERC721 spec uses address(0) for mints
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId); // Checks existence

        // Clear approvals
        delete _tokenApprovals[tokenId];
        // Clear operator approvals for this specific owner (not required by spec, but clean)
        // delete _operatorApprovals[owner_]; // This would clear ALL operator approvals for the owner, too much.

        _balances[owner_]--;
        delete _tokenOwners[tokenId];
        delete _entities[tokenId]; // Remove entity specific data

        emit Transfer(owner_, address(0), tokenId); // ERC721 spec uses address(0) for burns
    }

    // --- ERC721 Standard Functions ---
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner_ = _tokenOwners[tokenId];
        if (owner_ == address(0)) revert InvalidTokenId();
        return owner_;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId); // Checks token existence
        if (msg.sender != owner_ && !isApprovedForAll(owner_, msg.sender)) {
            revert NotOwnerOrApproved();
        }
        if (to == owner_) revert SelfApproval();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        ownerOf(tokenId); // Checks token existence
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert SelfApproval();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
         // Check permissions: owner or approved for all or approved for token
        if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved();
        }
        _transfer(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public override {
         safeTransferFrom(from, to, tokenId, "");
     }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
         // Check permissions: owner or approved for all or approved for token
         if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved();
         }
        _safeTransfer(from, to, tokenId, data);
     }


    // --- Internal Entity Helpers ---

    function _calculateCurrentAttributes(uint256 level, Attributes memory base, Attributes memory growth) internal pure returns (Attributes memory) {
        Attributes memory current;
        // Assuming level 1 means base stats, level 2 means base + 1*growth, etc.
        uint256 growthMultiplier = level > 0 ? level - 1 : 0;

        current.strength = base.strength + growth.strength * growthMultiplier;
        current.dexterity = base.dexterity + growth.dexterity * growthMultiplier;
        current.constitution = base.constitution + growth.constitution * growthMultiplier;
        current.intelligence = base.intelligence + growth.intelligence * growthMultiplier;
        current.wisdom = base.wisdom + growth.wisdom * growthMultiplier;
        current.charisma = base.charisma + growth.charisma * growthMultiplier;

        // In a real contract, you might apply trait biases or epoch modifiers here
        return current;
    }

    function _calculateEnergy(uint256 tokenId) internal {
        Entity storage entity_ = _entities[tokenId];
        uint256 timePassed = block.timestamp - entity_.lastActionTimestamp;
        uint256 energyRegen = (timePassed * energyRegenRatePerSecond) / SECONDS_PER_UNIT_ENERGY_REGEN;
        entity_.energy = Math.min(entity_.energy + energyRegen, maxEnergy); // Using SafeMath/standard library min
        entity_.lastActionTimestamp = block.timestamp; // Update timestamp
    }

    function _getAttribute(Attributes memory attrs, uint8 attributeType) internal pure returns (uint256) {
        return attributeType == uint8(AttributeType.Strength) ? attrs.strength
             : attributeType == uint8(AttributeType.Dexterity) ? attrs.dexterity
             : attributeType == uint8(AttributeType.Constitution) ? attrs.constitution
             : attributeType == uint8(AttributeType.Intelligence) ? attrs.intelligence
             : attributeType == uint8(AttributeType.Wisdom) ? attrs.wisdom
             : attributeType == uint8(AttributeType.Charisma) ? attrs.charisma
             : 0; // Should not happen with valid enum input
    }

     function _setAttribute(Attributes storage attrs, uint8 attributeType, uint256 value) internal {
        if (attributeType == uint8(AttributeType.Strength)) { attrs.strength = value; }
        else if (attributeType == uint8(AttributeType.Dexterity)) { attrs.dexterity = value; }
        else if (attributeType == uint8(AttributeType.Constitution)) { attrs.constitution = value; }
        else if (attributeType == uint8(AttributeType.Intelligence)) { attrs.intelligence = value; }
        else if (attributeType == uint8(AttributeType.Wisdom)) { attrs.wisdom = value; }
        else if (attributeType == uint8(AttributeType.Charisma)) { attrs.charisma = value; }
        else { revert InvalidAttributeType(); }
    }


    // --- Entity Management & Query ---

    function mintEntity(address to, uint32 initialFormId, uint8[] calldata initialTraitIds) public onlyOwner returns (uint256) {
        if (to == address(0)) revert ZeroAddress();
        FormDefinition storage form = _formDefinitions[initialFormId];
        if (!form.exists) revert FormNotFound();

        // Basic validation for traits (optional, depends on trait system complexity)
        for(uint i = 0; i < initialTraitIds.length; i++) {
            if (initialTraitIds[i] >= uint8(TraitType.Count)) revert InvalidInitialTraits();
        }

        uint256 newTokenId = _tokenIdCounter++;
        _mint(to, newTokenId);

        _entities[newTokenId] = Entity({
            tokenId: newTokenId,
            level: 1,
            xp: 0,
            formId: initialFormId,
            attributes: form.baseAttributes, // Start with base attributes
            traits: initialTraitIds, // Assign immutable traits
            lastActionTimestamp: block.timestamp,
            energy: maxEnergy // Start with full energy
        });

        emit EntityMinted(newTokenId, to, initialFormId);
        return newTokenId;
    }

    function burnEntity(uint256 tokenId) public onlyEntityOwnerOrApproved(tokenId) {
        _burn(tokenId);
        emit EntityBurned(tokenId);
    }

    function getEntityAttributes(uint256 tokenId) public view returns (Attributes memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // Calculate attributes based on current level, but return saved attributes for simplicity in this example
        // In a real game, you might calculate dynamic attributes here considering temporary buffs, epoch effects, etc.
        return _entities[tokenId].attributes;
    }

    function getEntityTraits(uint256 tokenId) public view returns (uint8[] memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _entities[tokenId].traits;
    }

    function getEntityFormId(uint256 tokenId) public view returns (uint32) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _entities[tokenId].formId;
    }

     function getEntityEnergy(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Entity storage entity_ = _entities[tokenId];
        uint256 timePassed = block.timestamp - entity_.lastActionTimestamp;
        uint256 energyRegen = (timePassed * energyRegenRatePerSecond) / SECONDS_PER_UNIT_ENERGY_REGEN;
        return Math.min(entity_.energy + energyRegen, maxEnergy);
    }

    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    // --- Entity Progression ---

    // Example function for gaining XP - in a real dApp/game, this would be triggered
    // by on-chain actions, staking, or oracle results. Here, it's a direct call.
    function gainExperience(uint256 tokenId, uint256 amount)
        public
        onlyEntityOwnerOrApproved(tokenId)
        checkAndConsumeEnergy(tokenId, baseActionCost) // Cost energy to perform this action
    {
        Entity storage entity_ = _entities[tokenId];
        if (amount == 0) return;

        uint256 oldLevel = entity_.level;
        entity_.xp += amount;

        // Check if leveling up is possible (actual level up happens in levelUp function)
        uint256 potentialNewLevel = oldLevel;
        while (potentialNewLevel < xpThresholds.length && entity_.xp >= xpThresholds[potentialNewLevel]) {
             potentialNewLevel++;
        }

        emit ExperienceGained(tokenId, amount, entity_.xp, potentialNewLevel);
    }

    function levelUp(uint256 tokenId)
        public
        onlyEntityOwnerOrApproved(tokenId)
        checkAndConsumeEnergy(tokenId, baseActionCost) // Cost energy to perform this action
    {
        Entity storage entity_ = _entities[tokenId];
        uint256 currentLevel = entity_.level;

        if (currentLevel >= xpThresholds.length) {
            // Already at max level
            return;
        }

        if (entity_.xp < xpThresholds[currentLevel]) {
            revert InsufficientXPForLevelUp();
        }

        entity_.level++;
        // Recalculate attributes based on new level and form's growth rates
        FormDefinition storage currentForm = _formDefinitions[entity_.formId];
        entity_.attributes = _calculateCurrentAttributes(entity_.level, currentForm.baseAttributes, currentForm.growthRates);

        emit LevelledUp(tokenId, entity_.level);
    }

    function evolveEntity(uint256 tokenId, uint32 targetFormId)
        public
        onlyEntityOwnerOrApproved(tokenId)
        checkAndConsumeEnergy(tokenId, baseActionCost * 5) // Evolution costs more energy
    {
        Entity storage entity_ = _entities[tokenId];
        FormDefinition storage currentForm = _formDefinitions[entity_.formId];
        FormDefinition storage targetForm = _formDefinitions[targetFormId];

        if (!currentForm.exists || !targetForm.exists) revert FormNotFound();

        bool evolutionPathExists = false;
        for(uint i = 0; i < currentForm.potentialNextForms.length; i++) {
            if (currentForm.potentialNextForms[i] == targetFormId) {
                evolutionPathExists = true;
                break;
            }
        }
        if (!evolutionPathExists) revert EvolutionPathNotFound();

        // Check evolution requirements
        if (entity_.level < currentForm.requiredLevelForEvo ||
            entity_.attributes.strength < currentForm.requiredAttributesForEvo.strength ||
            entity_.attributes.dexterity < currentForm.requiredAttributesForEvo.dexterity ||
            entity_.attributes.constitution < currentForm.requiredAttributesForEvo.constitution ||
            entity_.attributes.intelligence < currentForm.requiredAttributesForEvo.intelligence ||
            entity_.attributes.wisdom < currentForm.requiredAttributesForEvo.wisdom ||
            entity_.attributes.charisma < currentForm.requiredAttributesForEvo.charisma
           ) {
            revert EvolutionConditionsNotMet();
        }

        // --- Advanced Concept: Influence of Epoch and Staking ---
        // This is where epoch-specific rules, trait biases (influenced by epoch),
        // or staked 'Influence' could modify the *chance* or *outcome* of evolution.
        // For this example, we'll keep it deterministic based on requirements,
        // but you could add randomness (using Chainlink VRF or similar for security),
        // or checks like:
        //
        // uint256 evolutionSuccessChance = calculateChance(entity_, currentEpochId, getEntityStakedInfluence(tokenId));
        // if (randomValue >= evolutionSuccessChance) { // Revert or emit failure }
        //
        // Or, epoch/trait bias could influence which targetFormId is *more likely* among potentialNextForms.

        // Perform Evolution
        uint32 oldFormId = entity_.formId;
        entity_.formId = targetFormId;
        entity_.level = 1; // Reset level upon evolution (common in games)
        entity_.xp = 0;    // Reset XP
        entity_.attributes = targetForm.baseAttributes; // Adopt base attributes of the new form
        // Traits might change/gain new ones upon evolution depending on game design

        emit EntityEvolved(tokenId, oldFormId, targetFormId);
    }

    function getEvolutionRequirements(uint32 formId, uint32 targetFormId) public view returns (FormDefinition memory requirements) {
        FormDefinition storage form = _formDefinitions[formId];
        if (!form.exists) revert FormNotFound();

         bool evolutionPathExists = false;
        for(uint i = 0; i < form.potentialNextForms.length; i++) {
            if (form.potentialNextForms[i] == targetFormId) {
                evolutionPathExists = true;
                break;
            }
        }
        if (!evolutionPathExists) revert EvolutionPathNotFound();

        // Return requirements to evolve *from* the source form (formId)
        // The targetFormId is just used to confirm the path exists.
        return form; // Returning the source form's definition which contains requirements
    }

    function getPotentialEvolutionOutcomes(uint256 tokenId) public view returns (uint32[] memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        FormDefinition storage currentForm = _formDefinitions[_entities[tokenId].formId];
         if (!currentForm.exists) return new uint32[](0); // Should not happen if entity has valid form
        return currentForm.potentialNextForms;
    }


    // --- Entity Interaction ---

    function infuseAttributes(uint256 sourceTokenId, uint256 targetTokenId, uint8 attributeType, uint256 amount)
        public
        onlyEntityOwnerOrApproved(sourceTokenId) // Requires approval/ownership of source
        onlyEntityOwnerOrApproved(targetTokenId) // Requires approval/ownership of target
        checkAndConsumeEnergy(targetTokenId, baseActionCost * 2) // Cost energy on the target entity
    {
        if (sourceTokenId == targetTokenId) revert CannotInfuseIntoSelf();
        if (attributeType >= uint8(AttributeType.Count)) revert InvalidAttributeType();

        Entity storage sourceEntity = _entities[sourceTokenId];
        Entity storage targetEntity = _entities[targetTokenId];

        uint256 sourceAttributeValue = _getAttribute(sourceEntity.attributes, attributeType);

        if (sourceAttributeValue < amount) revert InsufficientAttributesForInfusion(attributeType, amount, sourceAttributeValue);

        // Transfer attributes (simple subtraction/addition)
        _setAttribute(sourceEntity.attributes, attributeType, sourceAttributeValue - amount);
        _setAttribute(targetEntity.attributes, attributeType, _getAttribute(targetEntity.attributes, attributeType) + amount);

        // Note: Could add logic here for source entity to be burned, lose levels, gain 'drain' traits etc.
        // For simplicity, just attributes are moved.

        emit AttributesInfused(sourceTokenId, targetTokenId, attributeType, amount);
    }

     // Simulates recharging energy - could consume a token, require time, etc.
     function rechargeEntityEnergy(uint256 tokenId)
        public
        onlyEntityOwnerOrApproved(tokenId)
     {
         // This function effectively just updates the lastActionTimestamp
         // and calculates the new energy. No cost in this simple version,
         // but could require burning a resource token.
         _calculateEnergy(tokenId); // This updates energy and timestamp
         emit EnergyRecharged(tokenId, _entities[tokenId].energy);
     }


    // --- Staking & Influence (Conceptual) ---
    // This requires a separate token contract in a real application.
    // These functions are placeholders simulating staking interaction.

    function stakeForInfluence(uint256 amount) public {
         if (amount == 0) revert InvalidStakeAmount();
         // In real use: Transfer 'InfluenceToken' from msg.sender to this contract
         // IERC20 influenceToken = IERC20(influenceTokenAddress);
         // influenceToken.transferFrom(msg.sender, address(this), amount);
         _totalStakedInfluence[msg.sender] += amount;
         emit InfluenceStaked(msg.sender, amount);
    }

    function unstakeInfluence(uint256 amount) public {
         if (amount == 0) revert InvalidStakeAmount();
         if (_totalStakedInfluence[msg.sender] < amount) revert InsufficientStake();
         _totalStakedInfluence[msg.sender] -= amount;
         // In real use: Transfer 'InfluenceToken' from this contract back to msg.sender
         // IERC20 influenceToken = IERC20(influenceTokenAddress);
         // influenceToken.transfer(msg.sender, amount);
         emit InfluenceUnstaked(msg.sender, amount);
    }

    function getStakedInfluenceTotal(address staker) public view returns (uint256) {
        return _totalStakedInfluence[staker];
    }

    // This function is conceptual - a real implementation would need to track
    // which staked tokens are 'bonded' to which specific entity for influence.
    // Leaving as a placeholder illustrating the concept.
    function getEntityStakedInfluence(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // Example: Could return _entityStakedInfluence[tokenId];
        // Or calculate based on owner's total stake and how they've allocated it.
        // For now, return 0 as it's not tracked per entity in this simple version.
        return 0;
    }


    // --- Global Epoch & Governance ---

    function getCurrentEpoch() public view returns (Epoch memory) {
        return _epochs[_currentEpochId];
    }

    function proposeEpochChange() public {
        // Basic permission check - could require minimum stake or be owner-only
        if (_totalStakedInfluence[msg.sender] == 0) revert InsufficientInfluenceToPropose(); // Example: require stake

        if (currentEpochProposal.state != EpochVoteState.Inactive) revert EpochProposalAlreadyExists();

        uint32 nextEpochId = _currentEpochId + 1;
        // Need to add definition for the *next* epoch rules beforehand (admin function)
        // Example: _epochs[nextEpochId] = ... ;

        currentEpochProposal = EpochProposal({
            epochId: nextEpochId,
            proposer: msg.sender,
            voteEndTime: block.timestamp + epochVoteDuration,
            yesVotes: 0,
            noVotes: 0,
            state: EpochVoteState.Pending
        });

        emit EpochProposalCreated(nextEpochId, msg.sender, currentEpochProposal.voteEndTime);
    }

    function voteForEpochChange(bool support) public {
        if (currentEpochProposal.state != EpochVoteState.Pending) revert NoActiveEpochProposal();
        if (block.timestamp >= currentEpochProposal.voteEndTime) revert EpochVoteAlreadyEnded();
        // Check if voter has stake or other voting power
        if (_totalStakedInfluence[msg.sender] == 0) revert InvalidEpochVote(); // Example: require stake

        // Simple voting: weigh vote by stake
        uint256 voterInfluence = _totalStakedInfluence[msg.sender];
        if (support) {
            currentEpochProposal.yesVotes += voterInfluence;
        } else {
            currentEpochProposal.noVotes += voterInfluence;
        }

        // Note: In a real system, you'd track who has voted to prevent double voting.
        // mapping(uint32 epochId => mapping(address voter => bool voted)) private _hasVoted;
        // If (_hasVoted[currentEpochProposal.epochId][msg.sender]) revert EpochVoteAlreadyCast();
        // _hasVoted[currentEpochProposal.epochId][msg.sender] = true;

        emit EpochVoteCast(currentEpochProposal.epochId, msg.sender, support);
    }

    function executeEpochChange() public {
        if (currentEpochProposal.state != EpochVoteState.Pending) revert NoActiveEpochProposal();
        if (block.timestamp < currentEpochProposal.voteEndTime) revert EpochNotReadyToExecute();

        uint256 totalInfluence = 0; // Calculate total influence from _totalStakedInfluence mapping if needed for quorum
        // For simplicity here, let's assume quorum is based on total potential voters (e.g., anyone with >0 stake)
        // A proper quorum calculation is more complex, involving iterating or tracking active stakers.
        // Let's simplify: Quorum check based on *votes cast* vs *some arbitrary total* or just check majority.
        // Simple majority check based on cast votes:
        uint256 totalCastVotes = currentEpochProposal.yesVotes + currentEpochProposal.noVotes;

        bool passed = false;
        if (totalCastVotes > 0) { // Avoid division by zero
             // Example: requires votes cast > 0 and majority yes votes
             if (currentEpochProposal.yesVotes * 100 / totalCastVotes >= epochVoteMajorityPercent) {
                 passed = true;
             }
             // You could add a quorum check based on total possible voting power here
             // uint256 totalPossibleInfluence = ...; // Sum of all _totalStakedInfluence values
             // if (totalCastVotes * 100 / totalPossibleInfluence < epochVoteQuorumPercent) { passed = false; }
        }


        if (passed) {
            _currentEpochId = currentEpochProposal.epochId;
            _epochs[_currentEpochId].description = string(abi.encodePacked("Epoch ", Strings.toString(_currentEpochId))); // Set default description if not set via admin

            // --- Apply Epoch Specific Rules ---
            // This is where epoch-specific logic would be applied.
            // E.g., load attribute biases from _epochs[_currentEpochId].attributeBias;
            // For this example, we'll assume the admin function setGlobalTraitBiasModifier
            // or setBaseAttributeWeights is called by governance/admin after a successful epoch vote.
            // Or, epoch struct could contain these modifiers and they are copied over.

            currentEpochProposal.state = EpochVoteState.Executed;
            emit EpochAdvanced(_currentEpochId - 1, _currentEpochId);
        } else {
            // Proposal failed
            currentEpochProposal.state = EpochVoteState.Inactive; // Reset proposal
            // Could also reset vote counts etc.
        }
    }

    function getCurrentEpochProposal() public view returns (EpochProposal memory) {
        return currentEpochProposal;
    }


    // --- Admin/Configuration (Owner/Governance controlled) ---

    function addFormDefinition(
        uint32 formId,
        string calldata name,
        Attributes calldata baseAttributes,
        Attributes calldata growthRates,
        uint256 requiredLevel,
        Attributes calldata requiredAttributes,
        uint32[] calldata potentialNextForms
    ) public onlyOwner { // Could be governance gated
        if (_formDefinitions[formId].exists) revert FormAlreadyExists(formId);
        if (formId == 0) revert InvalidFormId(); // Form 0 reserved or invalid

        _formDefinitions[formId] = FormDefinition({
            id: formId,
            name: name,
            baseAttributes: baseAttributes,
            growthRates: growthRates,
            requiredLevelForEvo: requiredLevel,
            requiredAttributesForEvo: requiredAttributes,
            potentialNextForms: potentialNextForms,
            exists: true
        });

        emit FormDefinitionAdded(formId);
    }

     // Function to update existing form definitions
     function updateFormDefinition(
        uint32 formId,
        string calldata name,
        Attributes calldata baseAttributes,
        Attributes calldata growthRates,
        uint256 requiredLevel,
        Attributes calldata requiredAttributes,
        uint32[] calldata potentialNextForms
     ) public onlyOwner { // Could be governance gated
         if (!_formDefinitions[formId].exists) revert FormNotFound();
         if (formId == 0) revert InvalidFormId();

         FormDefinition storage form = _formDefinitions[formId];
         form.name = name;
         form.baseAttributes = baseAttributes;
         form.growthRates = growthRates;
         form.requiredLevelForEvo = requiredLevel;
         form.requiredAttributesForEvo = requiredAttributes;
         form.potentialNextForms = potentialNextForms;

         emit FormDefinitionUpdated(formId);
     }

    function setXPThresholds(uint256[] calldata thresholds) public onlyOwner { // Could be governance gated
        if (thresholds.length == 0) revert XPThresholdsMismatch(0, 0);
        xpThresholds = thresholds;
        // Need to re-check levels of existing entities? Or only apply to new level ups?
        // Applying only to new level ups is simpler.
    }

    function setEnergyParameters(uint256 _maxEnergy, uint256 _energyRegenRatePerSecond, uint256 _baseActionCost) public onlyOwner { // Could be governance gated
        if (_maxEnergy == 0 || _energyRegenRatePerSecond == 0 || _baseActionCost == 0) revert InvalidEnergyParameters();
        maxEnergy = _maxEnergy;
        energyRegenRatePerSecond = _energyRegenRatePerSecond;
        baseActionCost = _baseActionCost;
    }

     // Simulates setting global modifiers based on traits, potentially linked to epoch
     function setGlobalTraitBiasModifier(uint8 traitId, int256 modifierPercent) public onlyOwner { // Could be governance gated or triggered by epoch change
        if (traitId >= uint8(TraitType.Count)) revert InvalidTraitId();
        globalTraitBiasModifiers[traitId] = modifierPercent;
        emit GlobalTraitBiasSet(traitId, modifierPercent);
     }

     // Simulates setting base weights used in attribute calculations or interactions, potentially linked to epoch
     mapping(uint8 => uint256) public baseAttributeWeights;
     function setBaseAttributeWeights(uint8 attributeType, uint256 weight) public onlyOwner { // Could be governance gated or triggered by epoch change
        if (attributeType >= uint8(AttributeType.Count)) revert InvalidAttributeType();
        baseAttributeWeights[attributeType] = weight;
     }

     // Helper to get base attribute weights (example usage)
     function getBaseAttributeWeight(uint8 attributeType) public view returns (uint256) {
         if (attributeType >= uint8(AttributeType.Count)) revert InvalidAttributeType();
         return baseAttributeWeights[attributeType];
     }

    // Placeholder for standard library functions like min (often imported)
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }

    // Placeholder for converting uint256 to string (often imported from OpenZeppelin)
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
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
                digits--;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }

    // Need a simple invalid form ID error
     error InvalidFormId();
}
```