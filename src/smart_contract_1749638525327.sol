Okay, here is a Solidity smart contract design that incorporates several advanced, creative, and trendy concepts beyond basic token functionality. It focuses on dynamic NFTs, crafting, community-driven parameter changes, and pseudo-random elements within a "Creative Realm" theme.

**Disclaimer:** This contract is designed for complexity and concept demonstration. It includes simplified mechanics (like pseudo-randomness via blockhash) which are *not* secure for high-value applications requiring true unpredictability. Production systems would require Chainlink VRF or similar oracles. It also omits some standard ERC-721 security checks for brevity in illustrating the *creative* functions. Thorough testing and security audits are crucial for any production deployment.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// --- Outline and Function Summary ---
//
// I. Contract Details
//    - Name: CreativeNFTRealm
//    - Symbol: CREA
//    - Inherits: ERC721, Ownable, Pausable
//
// II. State Variables
//    - tokenIdCounter: Counter for unique NFT IDs.
//    - shardAttributes: Mapping from token ID to its dynamic attributes.
//    - shardXP: Mapping from token ID to its experience points.
//    - shardLevel: Mapping from token ID to its level.
//    - xpThresholds: Array defining XP needed for each level.
//    - craftingFee: Fee required to initiate crafting.
//    - baseTokenURI: Base URL for dynamic metadata API.
//    - currentProposal: Details of the active community proposal.
//    - proposalVotes: Mapping from proposal ID to vote counts (yes/no).
//    - votedOnProposal: Mapping from address to boolean indicating if they voted on the current proposal.
//    - votingPeriodEnd: Timestamp when the current voting period ends.
//    - acceptedCraftingRecipes: Mapping defining valid crafting recipes (Input element combination -> Output element).
//
// III. Structs & Enums
//     - ShardAttributes: Defines the dynamic traits of an NFT (e.g., element, power, luck, generation).
//     - Element: Enum for possible elemental types.
//     - Proposal: Defines a community proposal (parameter type, new value, proposal ID, state).
//     - ProposalState: Enum for proposal lifecycle.
//     - ParameterType: Enum for parameters that can be changed via voting.
//
// IV. Events
//    - ShardMinted: Emitted when a new shard NFT is minted.
//    - XPReceived: Emitted when a shard gains XP.
//    - ShardLeveledUp: Emitted when a shard levels up.
//    - ShardsCrafted: Emitted when NFTs are combined via crafting.
//    - CraftingFeeUpdated: Emitted when the crafting fee changes.
//    - BaseURIUpdated: Emitted when the base token URI changes.
//    - XPThresholdsUpdated: Emitted when XP thresholds change.
//    - ProposalSubmitted: Emitted when a new proposal is created.
//    - VoteCast: Emitted when a user casts a vote.
//    - ProposalResolved: Emitted when a proposal ends (success or failure).
//    - AttributesUpdated: Emitted when a shard's attributes change.
//    - ShardBurned: Emitted when a shard NFT is burned.
//    - TraitRolled: Emitted when a trait upgrade roll occurs.
//
// V. Modifiers
//    - onlyShardOwner: Ensures the caller owns the specified token ID.
//    - onlyShardHolder: Ensures the caller is the owner or an approved/operator for the specified token ID. (Less strict than owner)
//    - whenVotingActive: Ensures a function is called during an active voting period.
//    - whenVotingInactive: Ensures a function is called outside an active voting period.
//    - isValidCraftingRecipe: Internal modifier to check if inputs match a recipe.
//
// VI. Constructor
//    - Initializes the contract, sets owner, initial fee, thresholds, and base URI.
//
// VII. ERC721 Overrides & Standard Functions
//    - tokenURI(uint256 tokenId): Overrides the standard to return a dynamic URI based on attributes.
//    - supportsInterface(bytes4 interfaceId): Standard override for ERC721, Ownable, Pausable.
//    - (Inherited from ERC721: ownerOf, balanceOf, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll) - These are standard but count towards the overall functionality provided by the contract.
//
// VIII. Core Creative & Dynamic Functions (Custom) - [~15 functions]
//    1. mintInitialShard(address recipient, Element initialElement): Mints the first generation of a shard (owner/permissioned).
//    2. requestNewShard(Element desiredElement) payable: Allows anyone to request a new shard, potentially with a fee.
//    3. getShardAttributes(uint256 tokenId) view: Returns the dynamic attributes of a shard.
//    4. getShardXP(uint256 tokenId) view: Returns the current XP of a shard.
//    5. getShardLevel(uint256 tokenId) view: Returns the current level of a shard.
//    6. addXPToShard(uint256 tokenId, uint256 amount): Adds XP to a specific shard (owner/permissioned, or triggered by actions).
//    7. triggerLevelUpCheck(uint256 tokenId): Allows a user to explicitly check and trigger a level up if eligible.
//    8. craftShards(uint256[] calldata inputTokenIds, Element desiredOutputElement) payable: Burns input shards to mint a new one based on a recipe and potentially randomness, requires fee.
//    9. rollForTraitUpgrade(uint256 tokenId) payable: Uses pseudo-randomness to potentially upgrade a shard's trait, requires fee/XP.
//   10. burnShard(uint256 tokenId): Allows a shard owner to burn their shard.
//   11. proposeParameterChange(ParameterType paramType, uint256 newValue): Allows a shard holder to propose changing a contract parameter.
//   12. voteOnProposal(uint256 proposalId, bool support): Allows a shard holder to vote on an active proposal.
//   13. tallyVotes(): Calculates the result of the current proposal and applies changes if successful (owner/permissioned).
//   14. setCraftingRecipe(Element[] calldata inputElements, Element outputElement): Owner sets valid crafting recipes.
//   15. updateShardAttribute(uint256 tokenId, uint8 attributeIndex, uint256 newValue): Owner can update a specific attribute (e.g., post-event, winning vote).
//
// IX. Admin & Owner Functions [~5 functions]
//    1. setCraftingFee(uint256 newFee): Owner sets the fee for crafting.
//    2. setBaseURI(string memory uri): Owner sets the base URI for metadata.
//    3. setXPThresholds(uint256[] calldata thresholds): Owner sets XP requirements for levels.
//    4. setVotingPeriod(uint64 duration): Owner sets the duration for voting periods.
//    5. withdrawFees(): Owner can withdraw accumulated fees.
//    (Inherited from Ownable: renounceOwnership, transferOwnership) - standard.
//    (Inherited from Pausable: pause, unpause) - standard.
//
// X. View & Query Functions [~10 functions]
//    1. getShardAttributes(uint256 tokenId) view: (Listed above, repeated for clarity)
//    2. getShardXP(uint256 tokenId) view: (Listed above)
//    3. getShardLevel(uint256 tokenId) view: (Listed above)
//    4. getCraftingFee() view: Returns the current crafting fee.
//    5. getXPThresholds() view: Returns the current XP thresholds.
//    6. getBaseURI() view: Returns the current base URI.
//    7. getCurrentProposal() view: Returns details of the active proposal.
//    8. getProposalVotes(uint256 proposalId) view: Returns vote counts for a proposal.
//    9. hasVotedOnProposal(address account, uint256 proposalId) view: Checks if an address has voted on a proposal.
//   10. isValidCraftingRecipe(Element[] calldata inputElements, Element outputElement) view: Checks if a specific combination is a valid recipe.
//   11. simulateCraftingOutcome(uint256[] calldata inputTokenIds) view: Simulates the likely outcome of a crafting attempt without executing.
//   12. getLatestTokenId() view: Returns the ID of the last minted token.
//
// XI. Internal Helper Functions [~5 functions]
//    - _generateTokenURI(uint256 tokenId): Internal helper for tokenURI generation.
//    - _updateLevel(uint256 tokenId): Internal helper to check and update level based on XP.
//    - _getRandomNumber(uint256 seed) pure: Pseudo-random number generation (INSECURE for high-value).
//    - _calculateCraftingOutcome(uint256[] memory inputTokenIds): Internal logic for crafting result based on inputs & random.
//    - _applyProposalResult(Proposal memory proposal): Internal logic to apply a successful proposal's changes.
//
// Total Custom Defined Functions (Public/External/View): ~30+ (including constructor and view functions)
// Total Functions (Including Inherited & Standard Overrides): ~35+

// --- Start of Source Code ---

contract CreativeNFTRealm is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---
    struct ShardAttributes {
        Element element;
        uint8 power;
        uint8 luck;
        uint8 generation; // How many times crafted/evolved
    }

    enum Element {
        Fire,
        Water,
        Earth,
        Air,
        Spirit,
        Void
    }

    struct Proposal {
        uint256 proposalId;
        ParameterType paramType;
        uint256 newValue;
        uint64 startTime;
        uint64 endTime;
        ProposalState state;
        uint256 yesVotes;
        uint256 noVotes;
        address proposer;
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    enum ParameterType {
        CraftingFee,
        XPThresholdMultiplier, // Example: change a multiplier applied to thresholds
        TraitUpgradeChance    // Example: change the base probability of rolling a trait upgrade
    }

    mapping(uint256 => ShardAttributes) private shardAttributes;
    mapping(uint256 => uint256) private shardXP;
    mapping(uint256 => uint8) private shardLevel;
    uint256[] private xpThresholds; // xpThresholds[0] for level 1, xpThresholds[1] for level 2, etc.

    uint256 private craftingFee;
    string private baseTokenURI;

    Proposal public currentProposal;
    mapping(uint256 => mapping(address => bool)) private votedOnProposal; // proposalId => voter => voted
    uint64 private votingPeriodDuration;
    uint256 private latestProposalId;

    // Map input elements (sorted) to output element
    mapping(bytes32 => Element) private acceptedCraftingRecipes;

    // --- Events ---
    event ShardMinted(address indexed recipient, uint256 indexed tokenId, Element initialElement);
    event XPReceived(uint256 indexed tokenId, uint256 amount, uint256 newXP);
    event ShardLeveledUp(uint256 indexed tokenId, uint8 newLevel);
    event ShardsCrafted(address indexed crafter, uint256[] indexed inputTokenIds, uint256 indexed outputTokenId, Element outputElement);
    event CraftingFeeUpdated(uint256 newFee);
    event BaseURIUpdated(string newURI);
    event XPThresholdsUpdated(uint256[] newThresholds);
    event ProposalSubmitted(uint256 indexed proposalId, ParameterType indexed paramType, uint256 newValue, uint64 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalResolved(uint256 indexed proposalId, ProposalState finalState);
    event AttributesUpdated(uint256 indexed tokenId, ShardAttributes newAttributes);
    event ShardBurned(uint256 indexed tokenId);
    event TraitRolled(uint256 indexed tokenId, bool success, string traitAffected);

    // --- Modifiers ---
    modifier onlyShardOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not shard owner or approved");
        _;
    }

    modifier whenVotingActive() {
        require(currentProposal.state == ProposalState.Active, "No active proposal");
        require(block.timestamp <= currentProposal.endTime, "Voting period has ended");
        _;
    }

    modifier whenVotingInactive() {
        require(currentProposal.state != ProposalState.Active, "Voting is currently active");
        _;
    }

    // Internal modifier check for crafting recipe
    modifier isValidCraftingRecipe(Element[] memory inputElements, Element outputElement) {
         bytes32 recipeHash = _hashCraftingRecipe(inputElements);
         require(acceptedCraftingRecipes[recipeHash] == outputElement, "Invalid crafting recipe");
         _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 initialCraftingFee, uint256[] memory initialXPThresholds, string memory initialBaseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        craftingFee = initialCraftingFee;
        xpThresholds = initialXPThresholds; // e.g., [100, 300, 600, 1000]
        baseTokenURI = initialBaseURI;
        votingPeriodDuration = 7 days; // Default voting period
        latestProposalId = 0;
    }

    // --- ERC721 Overrides ---

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        _requireOwned(tokenId); // Ensures token exists and caller can view
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
        // Note: The actual dynamic metadata JSON & image would be served by an off-chain API
        // running at baseTokenURI, querying the contract for attributes using view functions.
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(Ownable).interfaceId ||
               interfaceId == type(Pausable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Core Creative & Dynamic Functions ---

    /// @notice Mints the first generation of a shard (owner/permissioned).
    /// @param recipient The address to mint the shard to.
    /// @param initialElement The element of the initial shard.
    function mintInitialShard(address recipient, Element initialElement) external onlyOwner whenNotPaused {
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(recipient, newItemId);

        shardAttributes[newItemId] = ShardAttributes({
            element: initialElement,
            power: uint8(10), // Base attributes
            luck: uint8(10),
            generation: 1
        });
        shardXP[newItemId] = 0;
        shardLevel[newItemId] = 1;

        emit ShardMinted(recipient, newItemId, initialElement);
    }

     /// @notice Allows anyone to request a new shard, potentially with a fee and random element.
     /// @param desiredElement A user's preferred element (might influence random outcome slightly).
     function requestNewShard(Element desiredElement) external payable whenNotPaused {
        require(msg.value >= craftingFee, "Insufficient payment for new shard"); // Re-using craftingFee concept, could be a separate mint fee

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), newItemId);

        // Pseudo-random element assignment, slightly biased by desiredElement
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newItemId, desiredElement)));
        Element finalElement = Element(seed % uint256(type(Element).max) + 1); // Get random element, +1 if 0 is not a valid enum value

        // Simple bias: if random element is 0 and desired is not, try again or adjust.
        // More complex bias logic could be added here.
         if (finalElement == Element(0)) { // Assuming Element(0) is the first enum value
             finalElement = desiredElement; // Use desired if random is the first enum
         }


        shardAttributes[newItemId] = ShardAttributes({
            element: finalElement,
            power: uint8(5 + (_getRandomNumber(seed) % 10)), // Some random base power
            luck: uint8(5 + (_getRandomNumber(seed + 1) % 10)), // Some random base luck
            generation: 1
        });
        shardXP[newItemId] = 0;
        shardLevel[newItemId] = 1;

        emit ShardMinted(_msgSender(), newItemId, finalElement);
     }


    /// @notice Returns the dynamic attributes of a shard.
    /// @param tokenId The ID of the shard.
    /// @return The ShardAttributes struct.
    function getShardAttributes(uint256 tokenId) public view returns (ShardAttributes memory) {
        // require(_exists(tokenId), "Shard does not exist"); // ERC721 checks handle existence implicitly in _requireOwned/ownerOf
        return shardAttributes[tokenId];
    }

    /// @notice Returns the current XP of a shard.
    /// @param tokenId The ID of the shard.
    /// @return The current XP.
    function getShardXP(uint256 tokenId) public view returns (uint256) {
        // require(_exists(tokenId), "Shard does not exist");
        return shardXP[tokenId];
    }

    /// @notice Returns the current level of a shard.
    /// @param tokenId The ID of the shard.
    /// @return The current level.
    function getShardLevel(uint256 tokenId) public view returns (uint8) {
        // require(_exists(tokenId), "Shard does not exist");
        return shardLevel[tokenId];
    }

    /// @notice Adds XP to a specific shard. Can be called by owner or triggered by other contract actions.
    /// @param tokenId The ID of the shard.
    /// @param amount The amount of XP to add.
    function addXPToShard(uint256 tokenId, uint256 amount) external onlyOwner whenNotPaused {
        require(_exists(tokenId), "Shard does not exist");
        uint256 newXP = shardXP[tokenId] + amount;
        shardXP[tokenId] = newXP;
        emit XPReceived(tokenId, amount, newXP);
        _updateLevel(tokenId); // Check for level up after adding XP
    }

     /// @notice Allows a user to explicitly check and trigger a level up if eligible.
     /// @param tokenId The ID of the shard.
     function triggerLevelUpCheck(uint256 tokenId) external onlyShardOwner(tokenId) whenNotPaused {
         _updateLevel(tokenId);
     }

    /// @notice Burns input shards to mint a new, potentially higher-generation one based on a recipe, requires fee.
    /// @param inputTokenIds The IDs of the shards to burn.
    /// @param desiredOutputElement The element of the shard to mint (must match recipe).
    function craftShards(uint256[] calldata inputTokenIds, Element desiredOutputElement) external payable whenNotPaused isValidCraftingRecipe(_getElementsFromTokenIds(inputTokenIds), desiredOutputElement) {
        require(inputTokenIds.length > 1, "Crafting requires multiple shards");
        require(msg.value >= craftingFee, "Insufficient crafting fee");

        // Ensure sender owns or is approved for all input tokens
        for (uint i = 0; i < inputTokenIds.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), inputTokenIds[i]), "Caller not authorized for input shard");
        }

        // Burn input shards
        for (uint i = 0; i < inputTokenIds.length; i++) {
            _burn(inputTokenIds[i]);
            emit ShardBurned(inputTokenIds[i]);
        }

        // Mint new shard
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), newItemId);

        // Calculate new shard attributes based on inputs and potentially random elements
        shardAttributes[newItemId] = _calculateCraftingOutcome(inputTokenIds);
        shardXP[newItemId] = 0; // Crafted shards start fresh XP? Or inherit/average from inputs? Let's start fresh for simplicity.
        shardLevel[newItemId] = 1; // Starts at level 1

        emit ShardsCrafted(_msgSender(), inputTokenIds, newItemId, desiredOutputElement);
        emit ShardMinted(_msgSender(), newItemId, desiredOutputElement); // Also emit Minted event for the new token
    }

     /// @notice Uses pseudo-randomness to potentially upgrade a shard's trait. Requires payment or XP.
     /// @param tokenId The ID of the shard.
     function rollForTraitUpgrade(uint256 tokenId) external onlyShardOwner(tokenId) payable whenNotPaused {
        // Example cost: 0.01 ETH or 100 XP. Let's require ETH for simplicity in example.
        require(msg.value >= craftingFee / 10, "Insufficient payment for roll"); // Example: 1/10th of crafting fee

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, shardXP[tokenId])));
        uint256 roll = _getRandomNumber(seed) % 100; // Roll between 0-99

        ShardAttributes storage attrs = shardAttributes[tokenId];
        bool success = false;
        string memory traitAffected = "None"; // Default

        // Get current trait upgrade chance (can be adjusted by voting)
        uint256 baseChance = 20; // 20% base chance
        // Note: Applying voted parameters here would read from a state var set by _applyProposalResult

        if (roll < baseChance + (attrs.luck / 2)) { // Example: Base chance + luck bonus
             success = true;
             uint256 traitRoll = _getRandomNumber(seed + 1) % 3; // 0: Power, 1: Luck, 2: Generation (less likely?)

             if (traitRoll == 0) {
                 attrs.power = attrs.power < 255 ? attrs.power + 1 : 255;
                 traitAffected = "Power";
             } else if (traitRoll == 1) {
                 attrs.luck = attrs.luck < 255 ? attrs.luck + 1 : 255;
                 traitAffected = "Luck";
             } else { // Maybe increase XP or add a special flag
                 uint256 xpGain = 50; // Example XP gain
                 shardXP[tokenId] += xpGain;
                 emit XPReceived(tokenId, xpGain, shardXP[tokenId]);
                 _updateLevel(tokenId);
                 traitAffected = "XP";
             }
             emit AttributesUpdated(tokenId, attrs);
         }

         emit TraitRolled(tokenId, success, traitAffected);
     }

     /// @notice Allows a shard owner to burn their shard.
     /// @param tokenId The ID of the shard to burn.
     function burnShard(uint256 tokenId) external onlyShardOwner(tokenId) whenNotPaused {
         _burn(tokenId);
         delete shardAttributes[tokenId];
         delete shardXP[tokenId];
         delete shardLevel[tokenId];
         emit ShardBurned(tokenId);
     }

    /// @notice Allows a shard holder to propose changing a contract parameter.
    /// Requires holding at least one shard. Only one active proposal at a time.
    /// @param paramType The type of parameter to change.
    /// @param newValue The proposed new value for the parameter.
    function proposeParameterChange(ParameterType paramType, uint256 newValue) external onlyShardHolder(0) whenVotingInactive { // requires holding ANY shard
        require(balanceOf(_msgSender()) > 0, "Must hold at least one shard to propose"); // Explicit check

        latestProposalId++;
        uint64 endTime = uint64(block.timestamp) + votingPeriodDuration;

        currentProposal = Proposal({
            proposalId: latestProposalId,
            paramType: paramType,
            newValue: newValue,
            startTime: uint64(block.timestamp),
            endTime: endTime,
            state: ProposalState.Active,
            yesVotes: 0,
            noVotes: 0,
            proposer: _msgSender()
        });

        // Reset voted status for the new proposal
        // Note: This simple mapping reset works only if we only care about the *current* proposal.
        // For historical tracking or multiple simultaneous proposals, this needs a different structure.
        // For this example, we only support one active proposal at a time.
        // Clear previous proposal votes (simple way assuming only one active at a time)
        // A more robust way would be mapping(address => uint256[]) votedProposalIds
        // Let's keep it simple for this example and rely on the `votedOnProposal[proposalId][voter]` check.

        emit ProposalSubmitted(latestProposalId, paramType, newValue, endTime);
    }

    /// @notice Allows a shard holder to vote on an active proposal. 1 NFT = 1 Vote weight (simplified).
    /// Requires holding at least one shard.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for Yes, False for No.
    function voteOnProposal(uint256 proposalId, bool support) external onlyShardHolder(0) whenVotingActive {
        require(currentProposal.proposalId == proposalId, "Proposal ID does not match active proposal");
        require(!votedOnProposal[proposalId][_msgSender()], "Already voted on this proposal");
        require(balanceOf(_msgSender()) > 0, "Must hold at least one shard to vote"); // Explicit check

        uint256 voteWeight = balanceOf(_msgSender()); // 1 token = 1 vote weight

        if (support) {
            currentProposal.yesVotes += voteWeight;
        } else {
            currentProposal.noVotes += voteWeight;
        }

        votedOnProposal[proposalId][_msgSender()] = true;

        emit VoteCast(proposalId, _msgSender(), support);
    }

    /// @notice Calculates the result of the current proposal and applies changes if successful.
    /// Can be called by anyone after the voting period ends.
    function tallyVotes() external whenVotingActive {
        require(block.timestamp > currentProposal.endTime, "Voting period is not over yet");

        ProposalState finalState;
        if (currentProposal.yesVotes > currentProposal.noVotes) {
            finalState = ProposalState.Succeeded;
            _applyProposalResult(currentProposal); // Apply the proposed change
        } else {
            finalState = ProposalState.Failed;
        }

        currentProposal.state = finalState;
        if (finalState == ProposalState.Succeeded) {
             currentProposal.state = ProposalState.Executed; // Mark as executed after applying
        }

        emit ProposalResolved(currentProposal.proposalId, finalState);
    }

    /// @notice Owner sets valid crafting recipes. Maps sorted input elements to an output element.
    /// @param inputElements The elements required as input (order doesn't matter, will be sorted).
    /// @param outputElement The element of the resulting shard.
    function setCraftingRecipe(Element[] calldata inputElements, Element outputElement) external onlyOwner {
        require(inputElements.length > 0, "Input elements cannot be empty");
        bytes32 recipeHash = _hashCraftingRecipe(inputElements);
        acceptedCraftingRecipes[recipeHash] = outputElement;
        // Consider emitting an event for added/updated recipes
    }

     /// @notice Owner can update a specific attribute of a shard (e.g., post-event, winning vote).
     /// Attribute indices: 0=element, 1=power, 2=luck, 3=generation
     /// @param tokenId The ID of the shard.
     /// @param attributeIndex The index of the attribute to update (0-3).
     /// @param newValue The new value for the attribute.
     function updateShardAttribute(uint256 tokenId, uint8 attributeIndex, uint256 newValue) external onlyOwner whenNotPaused {
         require(_exists(tokenId), "Shard does not exist");
         ShardAttributes storage attrs = shardAttributes[tokenId];

         if (attributeIndex == 0) {
             attrs.element = Element(uint8(newValue));
         } else if (attributeIndex == 1) {
             attrs.power = uint8(newValue);
         } else if (attributeIndex == 2) {
             attrs.luck = uint8(newValue);
         } else if (attributeIndex == 3) {
             attrs.generation = uint8(newValue);
         } else {
             revert("Invalid attribute index");
         }
         emit AttributesUpdated(tokenId, attrs);
     }

    // --- Admin & Owner Functions ---

    function setCraftingFee(uint256 newFee) external onlyOwner {
        craftingFee = newFee;
        emit CraftingFeeUpdated(newFee);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
        emit BaseURIUpdated(uri);
    }

    function setXPThresholds(uint256[] calldata thresholds) external onlyOwner {
         // Basic validation: thresholds should be increasing
         for(uint i = 0; i < thresholds.length; i++) {
             if (i > 0) require(thresholds[i] > thresholds[i-1], "XP thresholds must be increasing");
             // Optionally add upper bounds check uint256 vs uint8 level cap
         }
        xpThresholds = thresholds;
        emit XPThresholdsUpdated(thresholds);
    }

     function setVotingPeriod(uint64 duration) external onlyOwner {
         require(duration > 0, "Voting period must be positive");
         votingPeriodDuration = duration;
     }


    function withdrawFees() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Fee withdrawal failed");
    }

    // --- View & Query Functions ---

    function getCraftingFee() external view returns (uint256) {
        return craftingFee;
    }

    function getXPThresholds() external view returns (uint256[] memory) {
        return xpThresholds;
    }

     function getBaseURI() external view returns (string memory) {
         return baseTokenURI;
     }

     function getVotingPeriodDuration() external view returns (uint64) {
         return votingPeriodDuration;
     }

     function getCurrentProposal() external view returns (Proposal memory) {
         return currentProposal;
     }

     function getProposalVotes(uint256 proposalId) external view returns (uint256 yes, uint256 no) {
         if (currentProposal.proposalId == proposalId) {
             return (currentProposal.yesVotes, currentProposal.noVotes);
         }
         // Note: This only works for the *current* proposal tracked in state.
         // For historical proposals, a different storage mechanism would be needed.
         return (0, 0); // Return 0 for proposals not currently tracked
     }

     function hasVotedOnProposal(address account, uint256 proposalId) external view returns (bool) {
          // Requires a mapping that tracks votes per proposal ID, not just for the current one.
          // Using the current implementation's simple map, this only checks the CURRENT proposal.
          // For robustness with multiple/historical proposals, votedOnProposal map would need to be proposalId => address => bool.
          // Let's assume proposalId is checked against currentProposal.proposalId for simplicity here.
          if (currentProposal.proposalId == proposalId) {
              return votedOnProposal[proposalId][account];
          }
          return false; // Not voted on this proposal (or it's not the current one)
     }

    /// @notice Checks if a specific combination is a valid crafting recipe.
    /// @param inputElements The elements required as input.
    /// @param outputElement The element of the resulting shard.
    /// @return True if it's a valid recipe, false otherwise.
    function isValidCraftingRecipe(Element[] calldata inputElements, Element outputElement) public view returns (bool) {
         if (inputElements.length == 0) return false;
         bytes32 recipeHash = _hashCraftingRecipe(inputElements);
         return acceptedCraftingRecipes[recipeHash] == outputElement;
    }

     /// @notice Simulates the likely outcome of a crafting attempt based on inputs and current recipes.
     /// Does NOT account for randomness in attributes, only the output element based on recipe.
     /// @param inputTokenIds The IDs of the shards to be used as input.
     /// @return The likely output element. Returns Element.Void if no recipe matches.
     function simulateCraftingOutcome(uint256[] calldata inputTokenIds) external view returns (Element) {
         if (inputTokenIds.length == 0) return Element.Void;
         Element[] memory inputElements = _getElementsFromTokenIds(inputTokenIds);
         bytes32 recipeHash = _hashCraftingRecipe(inputElements);
         return acceptedCraftingRecipes[recipeHash]; // Returns default (Void) if no match
     }

    function getLatestTokenId() external view returns (uint256) {
         // Returns the ID of the NEXT token to be minted. Subtract 1 for the last *minted*.
         return _tokenIdCounter.current(); // Or _tokenIdCounter.current() - 1 if you want the last one minted. Let's return the next one.
     }


    // --- Internal Helper Functions ---

    /// @dev Internal helper to check and update level based on XP.
    function _updateLevel(uint256 tokenId) internal {
        uint256 currentXP = shardXP[tokenId];
        uint8 currentLevel = shardLevel[tokenId];
        uint8 newLevel = currentLevel;

        for (uint i = currentLevel -1; i < xpThresholds.length; i++) {
            if (currentXP >= xpThresholds[i]) {
                newLevel = uint8(i + 2); // Level 1 threshold is xpThresholds[0] -> level 2. index i = level i+1 threshold -> level i+2
            } else {
                break; // XP not enough for the next level
            }
        }

        if (newLevel > currentLevel) {
            shardLevel[tokenId] = newLevel;
            // Optional: Add attribute points or other bonuses on level up
            shardAttributes[tokenId].power += (newLevel - currentLevel); // Example: +1 power per level
             shardAttributes[tokenId].luck += (newLevel - currentLevel); // Example: +1 luck per level
            emit ShardLeveledUp(tokenId, newLevel);
             emit AttributesUpdated(tokenId, shardAttributes[tokenId]);
        }
    }

    /// @dev Pseudo-random number generator based on block data. INSECURE for adversarial use cases.
    function _getRandomNumber(uint256 seed) internal view returns (uint256) {
         // Use a seed that includes caller, timestamp, difficulty, block number for variation
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, msg.sender, block.number, seed)));
    }

    /// @dev Calculates the outcome of a crafting attempt based on inputs and random chance.
    /// @param inputTokenIds The IDs of the shards used as input.
    /// @return The ShardAttributes for the new crafted shard.
    function _calculateCraftingOutcome(uint256[] memory inputTokenIds) internal view returns (ShardAttributes memory) {
        // Example logic:
        // - Determine output element based on recipe (already checked by modifier)
        // - Average stats from input shards
        // - Add a random bonus/penalty based on luck of inputs
        // - Increment generation count

        Element[] memory inputElements = _getElementsFromTokenIds(inputTokenIds);
        bytes32 recipeHash = _hashCraftingRecipe(inputElements);
        Element outputElement = acceptedCraftingRecipes[recipeHash]; // Get the required output element

        uint256 totalPower;
        uint256 totalLuck;
        uint256 maxGeneration = 0;

        for (uint i = 0; i < inputTokenIds.length; i++) {
            ShardAttributes storage attrs = shardAttributes[inputTokenIds[i]];
            totalPower += attrs.power;
            totalLuck += attrs.luck;
            if (attrs.generation > maxGeneration) {
                maxGeneration = attrs.generation;
            }
        }

        uint8 avgPower = uint8(totalPower / inputTokenIds.length);
        uint8 avgLuck = uint8(totalLuck / inputTokenIds.length);

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, inputTokenIds)));
        int256 luckModifier = int256(_getRandomNumber(seed) % 10) - 5; // Random modifier between -5 and +4 based on luck? (Simplified)
        // More advanced: scale modifier based on average luck.

        uint8 finalPower = uint8(int256(avgPower) + luckModifier);
        uint8 finalLuck = uint8(int256(avgLuck) + luckModifier);

        // Ensure attributes stay within reasonable bounds (e.g., 0-255)
        if (finalPower > 255) finalPower = 255; if (finalPower < 5) finalPower = 5; // Example bounds
        if (finalLuck > 255) finalLuck = 255; if (finalLuck < 5) finalLuck = 5;


        return ShardAttributes({
            element: outputElement,
            power: finalPower,
            luck: finalLuck,
            generation: uint8(maxGeneration + 1) // Increment generation
        });
    }

     /// @dev Internal helper to apply the result of a successful proposal.
     function _applyProposalResult(Proposal memory proposal) internal {
         if (proposal.paramType == ParameterType.CraftingFee) {
             craftingFee = proposal.newValue;
             emit CraftingFeeUpdated(proposal.newValue);
         } else if (proposal.paramType == ParameterType.XPThresholdMultiplier) {
             // Example: Apply a multiplier to thresholds. This requires re-calculating the xpThresholds array.
             // Or, if newValue is a multiplier, store it and apply it whenever checking XP.
             // Let's assume newValue is a new crafting fee or chance for simplicity in applying directly.
             // A multiplier would need a dedicated state variable and logic throughout _updateLevel etc.
             // Example: Assume newValue is a direct fee or chance value.
             // If it were a multiplier, let's say 1000 = 1x, 1500 = 1.5x.
             // uint256 multiplier = proposal.newValue;
             // // Store this multiplier in a state variable e.g., xpMultiplier = multiplier;
             // // Then in _updateLevel: if (currentXP >= (xpThresholds[i] * xpMultiplier) / 1000) ...
         } else if (proposal.paramType == ParameterType.TraitUpgradeChance) {
             // Assuming newValue is the base chance percentage (0-100)
             // Store this in a state variable used in rollForTraitUpgrade
             // uint256 baseChance = proposal.newValue;
             // // Store this in a state variable e.g., traitUpgradeBaseChance = baseChance;
             // // Then in rollForTraitUpgrade: uint256 baseChance = traitUpgradeBaseChance;
         }
         // Add more cases for other parameter types
     }

     /// @dev Internal helper to get elements from a list of token IDs.
     function _getElementsFromTokenIds(uint256[] memory tokenIds) internal view returns (Element[] memory) {
         Element[] memory elements = new Element[](tokenIds.length);
         for(uint i = 0; i < tokenIds.length; i++) {
             require(_exists(tokenIds[i]), "Input shard does not exist");
             elements[i] = shardAttributes[tokenIds[i]].element;
         }
         return elements;
     }

    /// @dev Internal helper to hash a crafting recipe (input elements + output element), inputs are sorted for consistent hash.
    function _hashCraftingRecipe(Element[] memory inputElements) internal pure returns (bytes32) {
        // Sort input elements to ensure consistent hash regardless of input order
        Element[] memory sortedInputs = new Element[](inputElements.length);
        for (uint i = 0; i < inputElements.length; i++) {
            sortedInputs[i] = inputElements[i];
        }

        // Simple bubble sort for demonstration (not efficient for large arrays)
        for (uint i = 0; i < sortedInputs.length; i++) {
            for (uint j = 0; j < sortedInputs.length - 1 - i; j++) {
                if (sortedInputs[j] > sortedInputs[j+1]) {
                    Element temp = sortedInputs[j];
                    sortedInputs[j] = sortedInputs[j+1];
                    sortedInputs[j+1] = temp;
                }
            }
        }

        return keccak256(abi.encodePacked(sortedInputs)); // Hash only sorted inputs
        // If output element was part of the hash key, would need to include it.
        // Current mapping uses hash of inputs -> output element value.
    }

    // --- Overrides for Pausable and Owner checks (standard, but good to include for clarity) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Internal modifier implementation check for `onlyShardHolder(0)` used in voting/proposals
     modifier onlyShardHolder(uint256) {
        require(balanceOf(_msgSender()) > 0, "Caller must hold at least one shard");
        _;
     }

     // Override _burn and _safeMint to handle internal state cleanup/setup if needed,
     // but OpenZeppelin's versions are generally sufficient when paired with mappings.
     // Keeping explicit burn function allows owner/approved burn without full ERC721 _burn override.
}
```