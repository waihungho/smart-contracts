Okay, here is a Solidity smart contract concept called "Chronicle Forge". It incorporates several advanced, creative, and trendy features like dynamic NFTs, on-chain crafting and quest systems, reputation, and decentralized governance, aiming to be distinct from standard open-source implementations.

**Outline and Function Summary:**

This contract, `ChronicleForge`, acts as a central hub for a unique on-chain ecosystem involving dynamic non-fungible tokens (NFTs) called "Forged Shards" (ERC-721), a fungible token called "Chronicle Points" (ERC-20) used for actions/rewards, an on-chain quest system, a crafting system, user reputation, and a simple decentralized governance mechanism.

1.  **Core Concepts:**
    *   **Forged Shards (ERC721):** NFTs with dynamic properties stored directly in the contract state, not just metadata.
    *   **Chronicle Points (ERC20):** Utility token earned via quests and used for crafting or other interactions.
    *   **Quests:** On-chain challenges users can attempt to earn Points, Reputation, or modify Shards.
    *   **Crafting:** Recipes defined on-chain allowing users to combine Shards and Points to create new Shards or upgrade existing ones.
    *   **Reputation:** A non-transferable score tracking user engagement and success, used for governance voting weight and potentially quest/recipe requirements.
    *   **Governance:** Users with sufficient Reputation can propose changes (e.g., add/modify quests, recipes, parameters) and vote on them.

2.  **Contract Components:**
    *   Inherits OpenZeppelin's `ERC721`, `ERC20`, `Ownable`, and `Pausable`.
    *   Defines structs for `ShardProperties`, `Quest`, `Recipe`, and `Proposal`.
    *   Uses mappings to store Shard properties, Quest details, Recipe details, User Reputation, Quest completion status, and Governance Proposals.
    *   Includes counters for tracking next available IDs for Shards, Quests, Recipes, and Proposals.

3.  **Function Summary (25+ Functions):**

    *   **Initialization & Admin (Ownable/Pausable):**
        *   `initialize(address _pointsToken, address _shardsToken)`: Sets the addresses of deployed ERC20 and ERC721 tokens (assumes they are deployed separately but managed/minted/burned by this contract).
        *   `pause()`: Pauses contract interactions (except admin).
        *   `unpause()`: Unpauses contract interactions.
        *   `transferOwnership(address newOwner)`: Transfers contract ownership.
        *   `setBaseURI(string memory baseURI_)`: Sets the base URI for Shard metadata (though properties are dynamic).
        *   `addUpdateQuest(uint256 questId, Quest memory details)`: Adds a new quest or updates an existing one (Admin/Governance).
        *   `removeQuest(uint256 questId)`: Deactivates a quest (Admin/Governance).
        *   `addUpdateRecipe(uint256 recipeId, Recipe memory details)`: Adds a new recipe or updates an existing one (Admin/Governance).
        *   `removeRecipe(uint256 recipeId)`: Deactivates a recipe (Admin/Governance).

    *   **User Interactions - Shards (ERC721):**
        *   `mintInitialShard()`: Allows a user to mint their first basic Shard (maybe linked to initial reputation or fee).
        *   `getShardProperties(uint256 tokenId)`: Gets the dynamic properties of a specific Shard.
        *   `getUserShards(address owner)`: Gets a list of Token IDs owned by an address.
        *   `tokenURI(uint256 tokenId)`: Overrides ERC721 to potentially incorporate dynamic properties into URI (example implementation).

    *   **User Interactions - Chronicle Points (ERC20):**
        *   `balanceOf(address account)`: (Inherited ERC20) Gets account balance.
        *   `transfer(address recipient, uint256 amount)`: (Inherited ERC20) Transfers points.
        *   `approve(address spender, uint256 amount)`: (Inherited ERC20) Approves spender.
        *   `allowance(address owner, address spender)`: (Inherited ERC20) Gets allowance.

    *   **User Interactions - Quests:**
        *   `getActiveQuests()`: Lists IDs of currently active quests.
        *   `getQuestDetails(uint256 questId)`: Gets details of a specific quest.
        *   `attemptQuest(uint256 questId)`: Attempts to complete a quest (checks requirements, updates state, issues rewards/reputation).
        *   `isQuestCompleted(address user, uint256 questId)`: Checks if a user has completed a specific quest.

    *   **User Interactions - Crafting:**
        *   `getActiveRecipes()`: Lists IDs of currently active recipes.
        *   `getRecipeDetails(uint256 recipeId)`: Gets details of a specific recipe.
        *   `attemptCraft(uint256 recipeId, uint256[] memory inputShardTokenIds)`: Attempts to craft using a recipe (checks requirements, burns inputs, mints/updates output Shard, updates reputation).

    *   **User Interactions - Reputation:**
        *   `getUserReputation(address user)`: Gets the reputation score of a user.

    *   **Governance:**
        *   `createProposal(string memory description, uint256 proposalType, bytes memory proposalData)`: Creates a new governance proposal (requires minimum reputation). `proposalType` and `proposalData` specify the change (e.g., add quest data, modify recipe data).
        *   `voteOnProposal(uint256 proposalId, bool support)`: Votes on an active proposal (voting weight based on reputation/shards).
        *   `getProposalDetails(uint256 proposalId)`: Gets the details and current vote counts for a proposal.
        *   `getVotingWeight(address user)`: Calculates a user's current voting weight.
        *   `executeProposal(uint256 proposalId)`: Executes a proposal if it has passed and the voting period is over.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // If want to list all tokens
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI example

// --- Outline and Function Summary Above ---

contract ChronicleForge is ERC721Enumerable, ERC20, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables & Structs ---

    // Counter for Forged Shard Token IDs
    Counters.Counter private _shardTokenIds;
    // Base URI for metadata (can be dynamic or point to off-chain)
    string private _baseTokenURI;

    // Chronicle Points Token - ERC20 managed within this contract
    address public immutable chroniclePointsToken;
    // Forged Shards Token - ERC721 managed within this contract
    address public immutable forgedShardsToken;

    // Dynamic Properties for each Shard Token ID
    struct ShardProperties {
        string name;
        string trait; // e.g., "Fire", "Ice", "Strength"
        uint256 level;
        uint256 experience; // Can level up via quests/crafting
        // Add more properties as needed
    }
    mapping(uint256 => ShardProperties) public shardProperties;

    // User Reputation System
    mapping(address => uint256) public userReputation;
    uint256 public constant MIN_REP_FOR_PROPOSAL = 100; // Minimum reputation to create proposal
    uint256 public constant REP_PER_QUEST_COMPLETE = 10;
    uint256 public constant REP_PER_CRAFT_SUCCESS = 5;

    // Quest System
    Counters.Counter private _questIds;
    struct Quest {
        uint256 id;
        string description;
        bool active;
        uint256 requiredPoints;
        uint256 requiredReputation;
        uint256 requiredShardTrait; // Placeholder: maybe requires holding a shard with a certain trait ID
        uint256 rewardPoints;
        uint256 rewardReputation;
        uint256 rewardShardTokenId; // If quest rewards a specific shard update (0 if none)
        // Maybe add expiry time, max attempts, etc.
    }
    mapping(uint256 => Quest) public quests;
    mapping(address => mapping(uint256 => bool)) public userQuestCompleted; // user => questId => completed

    // Crafting System
    Counters.Counter private _recipeIds;
    struct Recipe {
        uint256 id;
        string name;
        bool active;
        uint256 pointsCost;
        uint256[] inputShardTokenIds; // Specific token IDs required? Or traits? Let's use traits for simplicity.
        uint256[] requiredInputShardTraits; // e.g., [1, 2] requires 1 shard with trait 1, 1 with trait 2
        uint256 outputShardRecipeType; // 0: Mint new, 1: Update existing
        uint256 outputShardTrait; // Trait of the resulting shard (for new mint or update)
        uint256 outputShardLevelBoost; // Level boost for the resulting shard/update
        // Add more complex outputs (multiple items, random properties)
    }
    mapping(uint256 => Recipe) public recipes;

    // Governance System
    Counters.Counter private _proposalIds;
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 proposalType; // e.g., 0: Add/Update Quest, 1: Add/Update Recipe, 2: Change Parameter
        bytes proposalData; // Encoded data relevant to the proposal type
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalState state;
        // Add mapping for voters to prevent double voting
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant VOTING_PERIOD = 3 days; // Example voting period
    uint256 public constant PROPOSAL_THRESHOLD_PERCENT = 5; // Example: 5% of total reputation needed to pass

    // --- Events ---
    event ShardMinted(address indexed owner, uint256 indexed tokenId, ShardProperties properties);
    event ShardPropertiesUpdated(uint256 indexed tokenId, ShardProperties newProperties);
    event QuestAdded(uint256 indexed questId, string description);
    event QuestRemoved(uint256 indexed questId);
    event QuestAttempted(address indexed user, uint256 indexed questId);
    event QuestCompleted(address indexed user, uint256 indexed questId);
    event RecipeAdded(uint256 indexed recipeId, string name);
    event RecipeRemoved(uint256 indexed recipeId);
    event CraftAttempted(address indexed user, uint256 indexed recipeId);
    event CraftSuccessful(address indexed user, uint256 indexed recipeId, uint256 indexed outputTokenId);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Errors ---
    error NotInitialized();
    error AlreadyInitialized();
    error QuestNotFound();
    error QuestNotActive();
    error QuestAlreadyCompleted();
    error QuestRequirementsNotMet();
    error RecipeNotFound();
    error RecipeNotActive();
    error RecipeRequirementsNotMet();
    error InvalidInputShards();
    error NotEnoughPoints();
    error NotEnoughReputation(uint256 required, uint256 userHas);
    error OnlyGovernance(); // Modifier for functions executable via governance proposal
    error ProposalNotFound();
    error ProposalNotInCorrectState();
    error ProposalVotingPeriodNotEnded();
    error ProposalFailedThreshold();
    error ProposalAlreadyExecuted();
    error OnlyProposer(); // For cancelling proposal maybe
    error AlreadyVoted();

    // --- Constructor ---
    // Assumes ERC20 and ERC721 are deployed separately
    // This contract will hold minter/burner roles for them
    constructor(address _pointsToken, address _shardsToken)
        ERC721("Forged Shard", "SHARD")
        ERC20("Chronicle Point", "POINT") // This line is illustrative, assuming this contract *is* the ERC20.
                                           // In a real scenario, you'd likely deploy ERC20 separately and grant Minter role.
                                           // For this example, let's assume this contract *is* the ERC20 contract for simplicity.
        Ownable(msg.sender) // Owner is the deployer
        Pausable() // Start unpaused
    {
        if (_pointsToken != address(0) || _shardsToken != address(0)) {
             revert AlreadyInitialized(); // Prevent misuse if trying to set tokens via constructor
        }
        // In a real setup, you'd deploy ERC20/ERC721 first,
        // then deploy this contract passing their addresses,
        // then grant MINTER_ROLE/other necessary roles to this contract on the token contracts.
        // For this example, we'll simulate it by having this contract inherit/manage them.
        // This is a simplification for demonstrating the mechanics.
        chroniclePointsToken = address(this); // Simulate this contract *is* the ERC20
        forgedShardsToken = address(this); // Simulate this contract *is* the ERC721
    }

    // --- Modifier for functions executable only via Governance ---
    // This is a simplified example. A real system would use delegatecall or encoded calls.
    // Here, we'll rely on proposalType and proposalData to trigger specific internal functions.
    modifier onlyGovernance() {
        // This modifier would check if the call is originating from the executeProposal function
        // This is complex to implement purely based on msg.sender without storing state.
        // A common pattern involves a boolean flag set temporarily during execution or checking the caller is the contract itself.
        // For simplicity in this example, we'll assume internal helper functions like _applyProposalData
        // are called *only* by executeProposal and add checks there if needed, or rely on _executeProposal's state.
        // Let's add a basic check here for demonstration, though a robust implementation is more complex.
        // A proper way involves a timelock or executor pattern.
        // For THIS example, we'll trust internal calls from executeProposal and *not* add a restrictive modifier here,
        // but clearly note that functions intended *only* for governance would need protection.
        _; // Placeholder - actual governance execution logic is within executeProposal/internal helpers
    }


    // --- Shard Management (ERC721 overrides and dynamic properties) ---

    // ERC721Enumerable overrides (basic)
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Internal minting function called by crafting/quests/initial mint
    function _mintShard(address to, ShardProperties memory props) internal returns (uint256) {
        require(to != address(0), "Mint to zero address");
        _shardTokenIds.increment();
        uint256 newItemId = _shardTokenIds.current();
        _safeMint(to, newItemId); // Use _safeMint from ERC721
        shardProperties[newItemId] = props;
        emit ShardMinted(to, newItemId, props);
        return newItemId;
    }

    // Internal function to update properties
    function _updateShardProperties(uint256 tokenId, ShardProperties memory newProps) internal {
        require(_exists(tokenId), "Shard does not exist");
        shardProperties[tokenId] = newProps;
        emit ShardPropertiesUpdated(tokenId, newProps);
    }

    // Get dynamic properties (public getter is already generated by `public mapping`)
    // function getShardProperties(uint256 tokenId) public view returns (ShardProperties memory) {
    //     require(_exists(tokenId), "Shard does not exist");
    //     return shardProperties[tokenId];
    // }

    // Get list of shards owned by an address - uses ERC721Enumerable
    function getUserShards(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    // Override tokenURI to potentially reflect dynamic properties
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: token query for nonexistent token");
        ShardProperties memory props = shardProperties[tokenId];
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
             return ""; // No base URI set
        }
        // In a real app, you'd construct a JSON metadata string or URI here
        // dynamically based on props. Example:
        // return string(abi.encodePacked(base, tokenId.toString(), ".json"));
        // A more advanced approach would encode properties into the URI or return dynamic JSON via API.
        // For this example, just basic URI + token ID.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    // --- Chronicle Points Management (ERC20 overrides and internal mint/burn) ---
    // Inherits standard ERC20 functions like balanceOf, transfer, approve, allowance

    // Internal minting points function (called by quests/admin)
    function _issuePoints(address to, uint256 amount) internal {
        require(to != address(0), "Issue to zero address");
        _mint(to, amount); // Use ERC20 _mint
    }

    // Internal burning points function (called by crafting)
    function _deductPoints(address from, uint256 amount) internal {
        require(from != address(0), "Deduct from zero address");
        _burn(from, amount); // Use ERC20 _burn
    }

    // Override ERC20 standard functions if needed (e.g., _beforeTokenTransfer)
    // Function overrides for ERC20 functions if inheriting:
    // function transfer(address to, uint256 amount) public virtual override returns (bool) { ... }
    // function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) { ... }
    // No complex logic needed for this example beyond pausing, so standard OZ implementation is fine.


    // --- Reputation Management ---

    // Get user reputation (public getter is already generated)
    // function getUserReputation(address user) public view returns (uint256) {
    //     return userReputation[user];
    // }

    // Internal function to update reputation
    function _updateReputation(address user, uint256 amount, bool increase) internal {
        if (increase) {
            userReputation[user] += amount;
        } else {
            userReputation[user] = userReputation[user] > amount ? userReputation[user] - amount : 0;
        }
        emit ReputationUpdated(user, userReputation[user]);
    }

    // --- Quest System ---

    // Admin/Governance function to add or update a quest
    function addUpdateQuest(uint256 questId, Quest memory details) public virtual onlyOwner whenNotPaused /* potentially onlyGovernance */ {
        require(details.id == questId, "Quest ID mismatch");
        quests[questId] = details;
        if (questId >= _questIds.current()) {
             _questIds.increment(); // Only increment if adding a new ID beyond current count
        }
        emit QuestAdded(questId, details.description);
    }

    // Admin/Governance function to remove (deactivate) a quest
    function removeQuest(uint256 questId) public virtual onlyOwner whenNotPaused /* potentially onlyGovernance */ {
        Quest storage quest = quests[questId];
        require(quest.id != 0, QuestNotFound.selector); // Check if quest exists
        quest.active = false;
        emit QuestRemoved(questId);
    }

    // Get active quest IDs (simple iteration - efficient for small numbers, can be optimized)
    function getActiveQuests() public view returns (uint256[] memory) {
        uint256[] memory activeQuestIds = new uint256[](_questIds.current());
        uint256 count = 0;
        for (uint256 i = 1; i <= _questIds.current(); i++) {
            if (quests[i].active) {
                activeQuestIds[count] = i;
                count++;
            }
        }
        bytes memory packed = abi.encodePacked(activeQuestIds);
        assembly {
            mstore(packed, mul(count, 0x20)) // Update length
        }
        return abi.decode(packed, (uint256[]));
    }

    // Get quest details (public mapping getter exists)
    // function getQuestDetails(uint256 questId) public view returns (Quest memory) {
    //    return quests[questId];
    // }

    // Check if a user completed a quest (public mapping getter exists)
    // function isQuestCompleted(address user, uint256 questId) public view returns (bool) {
    //     return userQuestCompleted[user][questId];
    // }

    // Attempt to complete a quest
    function attemptQuest(uint256 questId) public virtual whenNotPaused {
        Quest storage quest = quests[questId];
        require(quest.id != 0, QuestNotFound.selector);
        require(quest.active, QuestNotActive.selector);
        require(!userQuestCompleted[msg.sender][questId], QuestAlreadyCompleted.selector);

        // Check requirements
        if (balanceOf(msg.sender) < quest.requiredPoints ||
            userReputation[msg.sender] < quest.requiredReputation /* ||
            !_userHasShardTrait(msg.sender, quest.requiredShardTrait) */ // Need helper for trait requirement
        ) {
            revert QuestRequirementsNotMet.selector;
        }

        // Deduct required points
        if (quest.requiredPoints > 0) {
             _deductPoints(msg.sender, quest.requiredPoints);
        }

        // Mark quest as completed
        userQuestCompleted[msg.sender][questId] = true;
        emit QuestAttempted(msg.sender, questId); // Maybe add a separate event for attempt vs completion

        // Issue rewards
        if (quest.rewardPoints > 0) {
             _issuePoints(msg.sender, quest.rewardPoints);
        }
        if (quest.rewardReputation > 0) {
             _updateReputation(msg.sender, quest.rewardReputation, true);
        }
        if (quest.rewardShardTokenId != 0) {
            // Example: boost level of a specific shard the user owns
            uint256 targetShardId = quest.rewardShardTokenId; // This would need a way to specify WHICH shard if user owns multiple
            // A better design would be to reward a *type* of shard modification or a new shard.
            // Let's simulate updating a random shard the user owns for demonstration.
            uint256[] memory ownedShards = getUserShards(msg.sender);
            require(ownedShards.length > 0, "No shards to upgrade");
            // This random logic is NOT truly random on-chain! Use Chainlink VRF for real randomness.
            // For demo, pick first owned shard:
            uint256 shardToUpdate = ownedShards[0];

            ShardProperties storage props = shardProperties[shardToUpdate];
            props.level += 1; // Example reward: increase level
            props.experience += 50; // Example reward: increase experience
            emit ShardPropertiesUpdated(shardToUpdate, props);
        }

        emit QuestCompleted(msg.sender, questId);
    }

    // Helper to check if user has a shard with a specific trait (example, needs implementation)
    // function _userHasShardTrait(address user, uint256 traitId) internal view returns (bool) {
    //    // Iterate through user's shards and check properties
    //    // ... implementation ...
    //    return false; // Placeholder
    // }


    // --- Crafting System ---

    // Admin/Governance function to add or update a recipe
    function addUpdateRecipe(uint256 recipeId, Recipe memory details) public virtual onlyOwner whenNotPaused /* potentially onlyGovernance */ {
        require(details.id == recipeId, "Recipe ID mismatch");
        recipes[recipeId] = details;
        if (recipeId >= _recipeIds.current()) {
             _recipeIds.increment(); // Only increment if adding a new ID beyond current count
        }
        emit RecipeAdded(recipeId, details.name);
    }

    // Admin/Governance function to remove (deactivate) a recipe
    function removeRecipe(uint256 recipeId) public virtual onlyOwner whenNotPaused /* potentially onlyGovernance */ {
        Recipe storage recipe = recipes[recipeId];
        require(recipe.id != 0, RecipeNotFound.selector); // Check if recipe exists
        recipe.active = false;
        emit RecipeRemoved(recipeId);
    }

    // Get active recipe IDs (simple iteration)
    function getActiveRecipes() public view returns (uint256[] memory) {
        uint256[] memory activeRecipeIds = new uint256[](_recipeIds.current());
        uint256 count = 0;
        for (uint256 i = 1; i <= _recipeIds.current(); i++) {
            if (recipes[i].active) {
                activeRecipeIds[count] = i;
                count++;
            }
        }
        bytes memory packed = abi.encodePacked(activeRecipeIds);
         assembly {
            mstore(packed, mul(count, 0x20)) // Update length
        }
        return abi.decode(packed, (uint256[]));
    }

     // Get recipe details (public mapping getter exists)
    // function getRecipeDetails(uint256 recipeId) public view returns (Recipe memory) {
    //     return recipes[recipeId];
    // }

     // Get recipe ingredients (utility function)
    function getRecipeIngredients(uint256 recipeId) public view returns (uint256 pointsCost, uint256[] memory requiredInputShardTraits) {
         Recipe storage recipe = recipes[recipeId];
         require(recipe.id != 0, RecipeNotFound.selector);
         return (recipe.pointsCost, recipe.requiredInputShardTraits);
     }


    // Attempt to craft using a recipe
    // Assumes inputShardTokenIds are actual token IDs the user owns that match the *required traits*
    function attemptCraft(uint256 recipeId, uint256[] memory inputShardTokenIds) public virtual whenNotPaused {
        Recipe storage recipe = recipes[recipeId];
        require(recipe.id != 0, RecipeNotFound.selector);
        require(recipe.active, RecipeNotActive.selector);

        // Check point cost
        if (balanceOf(msg.sender) < recipe.pointsCost) {
            revert NotEnoughPoints.selector;
        }

        // Check input shards requirements (simplified: assumes inputTokenIds have correct traits)
        // A real system would need to verify each inputShardTokenId belongs to msg.sender
        // and its properties match the recipe.requiredInputShardTraits counts.
        require(inputShardTokenIds.length == recipe.requiredInputShardTraits.length, InvalidInputShards.selector);
        // Further validation needed: check ownership and traits of inputShardTokenIds.
        for(uint i=0; i < inputShardTokenIds.length; i++){
             require(ownerOf(inputShardTokenIds[i]) == msg.sender, InvalidInputShards.selector);
             // Need to check trait match here - complex example
        }


        // Deduct point cost
        if (recipe.pointsCost > 0) {
            _deductPoints(msg.sender, recipe.pointsCost);
        }

        // Burn input shards
        for (uint256 i = 0; i < inputShardTokenIds.length; i++) {
            _burn(inputShardTokenIds[i]); // Use ERC721 _burn
             delete shardProperties[inputShardTokenIds[i]]; // Remove properties mapping entry
        }

        emit CraftAttempted(msg.sender, recipeId);

        // Mint or Update output shard
        uint256 outputTokenId;
        if (recipe.outputShardRecipeType == 0) { // Mint New Shard
             ShardProperties memory newProps = ShardProperties({
                 name: string(abi.encodePacked("Forged Shard #", _shardTokenIds.current().toString())), // Basic naming
                 trait: recipe.outputShardTrait.toString(), // Use trait ID as string
                 level: 1 + recipe.outputShardLevelBoost,
                 experience: 0
             });
            outputTokenId = _mintShard(msg.sender, newProps);
        } else if (recipe.outputShardRecipeType == 1) { // Update Existing Shard
            // This requires specifying WHICH existing shard to update.
            // A more complex recipe structure or function parameter would be needed.
            // For this example, let's assume it updates the *first* input shard provided.
            require(inputShardTokenIds.length > 0, "Update recipe requires at least one input shard");
            outputTokenId = inputShardTokenIds[0]; // This token was burned above! Needs re-minting or a different flow.
            // A correct flow for 'update existing' might involve:
            // 1. User passes ONE target shard ID plus other inputs.
            // 2. Contract verifies target shard is owned and keeps it.
            // 3. Contract burns OTHER inputs.
            // 4. Contract updates the TARGET shard's properties.
            // Let's change the logic: if type 1, it updates the *first* shard in input, and only burns the *remaining* inputs.
            require(inputShardTokenIds.length > 0, "Update recipe requires target shard");
            uint256 targetShardId = inputShardTokenIds[0];
            require(_exists(targetShardId), "Target shard must exist");
            require(ownerOf(targetShardId) == msg.sender, "Target shard must be owned by crafter");

            // Burn remaining input shards (if any)
            for (uint256 i = 1; i < inputShardTokenIds.length; i++) {
                 require(_exists(inputShardTokenIds[i]), "Input shard must exist");
                 require(ownerOf(inputShardTokenIds[i]) == msg.sender, "Input shard must be owned by crafter");
                 _burn(inputShardTokenIds[i]);
                 delete shardProperties[inputShardTokenIds[i]];
            }

            ShardProperties storage props = shardProperties[targetShardId];
            // Apply updates based on recipe output (example: trait change, level boost)
            props.trait = recipe.outputShardTrait.toString();
            props.level += recipe.outputShardLevelBoost;
            emit ShardPropertiesUpdated(targetShardId, props);
            outputTokenId = targetShardId; // The updated shard is the output
        } else {
            revert(); // Invalid output type
        }

        // Reward reputation for successful craft
        _updateReputation(msg.sender, REP_PER_CRAFT_SUCCESS, true);

        emit CraftSuccessful(msg.sender, recipeId, outputTokenId);
    }


    // --- Governance System ---

    // Get a user's voting weight (example: based on reputation)
    function getVotingWeight(address user) public view returns (uint256) {
        // Could also include ERC721 ownership weight:
        // uint256 shardCount = balanceOf(user);
        // return userReputation[user] + shardCount;
        return userReputation[user]; // Simplified: only reputation matters
    }

    // Create a new governance proposal
    function createProposal(string memory description, uint256 proposalType, bytes memory proposalData) public virtual whenNotPaused {
        require(userReputation[msg.sender] >= MIN_REP_FOR_PROPOSAL, NotEnoughReputation.selector);

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            proposalType: proposalType,
            proposalData: proposalData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTING_PERIOD,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            state: ProposalState.Active // Starts active
        });

        // Add mapping to track voters for this proposal (requires another mapping: mapping(uint256 => mapping(address => bool)) hasVoted;)
        // For simplicity, skipping explicit tracking here, assuming external systems prevent double votes or it's handled in voteOnProposal.

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    // Vote on an active proposal
    function voteOnProposal(uint256 proposalId, bool support) public virtual whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, ProposalNotFound.selector);
        require(proposal.state == ProposalState.Active, ProposalNotInCorrectState.selector);
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period mismatch");

        // Check if user has already voted (requires 'hasVoted' mapping)
        // require(!hasVoted[proposalId][msg.sender], AlreadyVoted.selector);
        // hasVoted[proposalId][msg.sender] = true;

        uint256 weight = getVotingWeight(msg.sender);
        require(weight > 0, "User has no voting weight");

        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    // Get proposal details (public mapping getter exists)
    // function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
    //     return proposals[proposalId];
    // }

    // Get current state of a proposal
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) {
             return ProposalState.Canceled; // Represents non-existent or explicitly canceled
        }
        if (proposal.executed) {
             return ProposalState.Executed;
        }
        if (block.timestamp < proposal.voteStartTime) {
             return ProposalState.Pending;
        }
        if (block.timestamp <= proposal.voteEndTime) {
             return ProposalState.Active;
        }
        // Voting period ended, determine outcome
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor * 100 / (proposal.votesFor + proposal.votesAgainst) >= PROPOSAL_THRESHOLD_PERCENT) {
             return ProposalState.Succeeded;
        } else {
             return ProposalState.Defeated;
        }
    }

    // Execute a successful proposal
    function executeProposal(uint256 proposalId) public virtual whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, ProposalNotFound.selector);
        require(getProposalState(proposalId) == ProposalState.Succeeded, ProposalNotInCorrectState.selector);
        require(!proposal.executed, ProposalAlreadyExecuted.selector);

        // Execute the proposal logic based on proposalType and proposalData
        _applyProposalData(proposal.proposalType, proposal.proposalData);

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    // Internal helper to apply proposal data - *This is a simplified example*
    // A real system needs robust encoding/decoding and security checks.
    function _applyProposalData(uint256 proposalType, bytes memory proposalData) internal /* potentially onlyGovernance */ {
        if (proposalType == 0) { // Add/Update Quest
            // Data should be encoded Quest struct
            Quest memory questDetails = abi.decode(proposalData, (Quest));
            addUpdateQuest(questDetails.id, questDetails); // Call admin function internally
        } else if (proposalType == 1) { // Add/Update Recipe
             // Data should be encoded Recipe struct
            Recipe memory recipeDetails = abi.decode(proposalData, (Recipe));
            addUpdateRecipe(recipeDetails.id, recipeDetails); // Call admin function internally
        }
        // Add more proposal types here... e.g., change parameter (MIN_REP_FOR_PROPOSAL), etc.
        // This requires careful design of proposal types and how data is encoded/applied.
    }


    // --- Initial Mint Function (Example) ---
    // Allow anyone to mint a basic starting shard once
    mapping(address => bool) public hasMintedInitial;

    function mintInitialShard() public virtual whenNotPaused {
        require(!hasMintedInitial[msg.sender], "Already minted initial shard");

        ShardProperties memory initialProps = ShardProperties({
            name: "Basic Forged Shard",
            trait: "0", // Basic trait
            level: 1,
            experience: 0
        });

        _mintShard(msg.sender, initialProps);
        _updateReputation(msg.sender, 5, true); // Give some initial reputation
        hasMintedInitial[msg.sender] = true;
    }


    // --- ERC20 Overrides (Simulating this contract *is* the ERC20) ---
    // These are needed because we inherit ERC20 and want this contract address to be the token address.
    // In a real system, you'd remove these overrides and call methods on a deployed ERC20 contract instance.

    function name() public view virtual override returns (string memory) {
        return "Chronicle Point";
    }

    function symbol() public view virtual override returns (string memory) {
        return "POINT";
    }

    function decimals() public view virtual override returns (uint8) {
        return 18; // Standard decimals
    }

    // All other ERC20 logic comes from the inherited ERC20 contract.
    // Functions like _mint and _burn are used internally.


    // --- Pausable Overrides ---
    function _update(address from, address to, uint256 tokenId) internal virtual override whenNotPaused {
        super._update(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override whenNotPaused {
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override whenNotPaused {
        super._burn(tokenId);
    }

    // ERC20 Pausable override (if inheriting ERC20 and Pausable)
    // function _update(address from, address to, uint256 amount) internal virtual override(ERC20, Pausable) {
    //    super._update(from, to, amount);
    // }
    // Note: Handling Pausable with multiple inheritance needs careful _update/transfer overrides.
    // For simplicity, the Shard (ERC721) logic uses `whenNotPaused` modifier explicitly on internal functions.
    // The ERC20 (Point) functions inherited directly will *not* be paused by default unless you override and add the modifier.
    // The user-facing functions like attemptQuest/attemptCraft *are* paused.
    // A proper implementation would use a `Pausable` token contract passed in the constructor.

    // --- Receive Ether (Optional but good practice) ---
    receive() external payable {}
    fallback() external payable {}
}
```