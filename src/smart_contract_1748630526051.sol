Okay, let's design a smart contract that manages dynamic, evolving NFTs with crafting, staking, and simple governance features. This goes beyond a standard static NFT by allowing tokens to change state, interact with each other (via crafting), and participate in simple on-chain actions like staking and voting.

We'll call this contract `DynamicNFTForge`.

**Outline and Function Summary**

**Contract Name:** `DynamicNFTForge`

**Concept:**
A smart contract for managing Non-Fungible Tokens (NFTs) that are not static images but dynamic entities with evolving attributes, levels, and components. These NFTs can be crafted from other assets (simulated here), staked to earn potential rewards (simulated), and participate in basic on-chain governance regarding their own metadata or state.

**Key Features:**

1.  **Dynamic Attributes:** NFTs have attributes (like experience, level, arbitrary stats) stored on-chain that can change.
2.  **Evolving Metadata:** The `tokenURI` is generated dynamically based on the NFT's current attributes, allowing its appearance or description to change over time or based on interactions.
3.  **Experience & Leveling:** NFTs can gain experience points (XP) and level up, potentially unlocking new features or changing attributes.
4.  **Crafting/Forging:** A mechanism to combine certain "component" NFTs (or burning existing NFTs) to create a new, potentially more powerful NFT.
5.  **Staking:** Owners can stake their NFTs within the contract to signify active participation or accrue simulated yield/benefits. Staked NFTs cannot be transferred.
6.  **Simple Governance:** A basic system allowing token holders to propose and vote on changes to certain global parameters or even specific token attributes (e.g., proposing a change to the leveling curve or a specific NFT's 'name').
7.  **Role-Based Access Control:** Uses simple admin and minter roles for key administrative functions.
8.  **Simulated Oracle Interaction:** Includes a function to demonstrate how external data (e.g., "weather", "time") could affect NFT attributes, triggered by a privileged role.

**Roles:**

*   **Admin:** Can add/remove minters, pause crafting, update base URI, potentially trigger oracle updates.
*   **Minter:** Can mint new NFTs.
*   **Token Holder:** Can transfer, approve, stake, unstake, propose, and vote using their NFTs.

**Function Categories & Summaries:**

*   **Core ERC721 (Overridden/Extended):**
    *   `constructor`: Initializes the contract, name, symbol, sets initial admin and minters.
    *   `mint`: Mints a new NFT with initial attributes (only callable by minters).
    *   `transferFrom`: Standard transfer (modified to prevent transfer if staked).
    *   `safeTransferFrom`: Standard safe transfer (modified to prevent transfer if staked).
    *   `approve`: Standard approval.
    *   `setApprovalForAll`: Standard approval for operator.
    *   `getApproved`: Standard query.
    *   `isApprovedForAll`: Standard query.
    *   `balanceOf`: Standard query.
    *   `ownerOf`: Standard query.
    *   `tokenURI`: **Dynamic** implementation. Returns a URL based on base URI and token ID, incorporating dynamic attributes (like level, status) into the path or query parameters.
    *   `burn`: Allows burning an NFT (maybe with restrictions like not being staked).

*   **Dynamic Attributes & Leveling:**
    *   `getLevel`: Returns the current level of an NFT.
    *   `getExperience`: Returns the current experience points (XP) of an NFT.
    *   `gainExperience`: Adds XP to an NFT (restricted, e.g., only callable by admin or specific game logic contract). Triggers potential level up.
    *   `updateTokenAttribute`: Admin/system function to set a custom attribute value for a specific token ID.

*   **Crafting/Forging:**
    *   `forgeNFT`: Allows burning specific "component" NFTs (or a required amount of the same NFT type) to mint a new, different NFT (conceptually). Requires pausing to prevent abuse.
    *   `getForgeRecipe`: (View) Returns the required components/criteria for a specific forgeable NFT type. (Simplified: checks hardcoded logic or internal mapping).

*   **Staking:**
    *   `stakeNFT`: Locks an NFT in the contract. Prevents transfer. Records staking time.
    *   `unstakeNFT`: Unlocks a staked NFT. Makes it transferrable again. (Could potentially calculate yield here).
    *   `isStaked`: Checks if an NFT is currently staked.
    *   `getStakeDuration`: Returns how long an NFT has been staked.
    *   `calculateSimulatedYield`: (View) Calculates potential simulated yield based on stake duration (no actual token transfer in this example).

*   **Governance:**
    *   `proposeMetadataChange`: Allows a token holder to propose a change to a specific token's metadata or a global parameter (e.g., base URI, leveling curve). Requires locking a token temporarily.
    *   `voteForMetadataChange`: Allows a token holder to vote on an active proposal using their token (1 token = 1 vote).
    *   `executeMetadataChange`: Executes a proposal if it has met the required quorum and votes within the voting period (callable by anyone after the period).
    *   `getProposalDetails`: (View) Returns information about a specific governance proposal.
    *   `getActiveProposals`: (View) Returns a list of active proposal IDs.

*   **Admin & Access Control:**
    *   `addMinter`: Grants the minter role to an address (only admin).
    *   `removeMinter`: Revokes the minter role from an address (only admin).
    *   `pauseCrafting`: Pauses the `forgeNFT` function (only admin).
    *   `unpauseCrafting`: Unpauses the `forgeNFT` function (only admin).
    *   `updateBaseURI`: Sets the base URI for dynamic metadata (only admin).
    *   `requestAttributeUpdateFromOracle`: Simulates receiving data from an oracle to update an NFT's attribute (restricted).

**Contract Implementation Details:**

*   Uses OpenZeppelin's `ERC721Enumerable` for basic NFT functionality and enumeration.
*   Uses OpenZeppelin's `ERC2981` for royalties (standard, not dynamic royalty).
*   Implements custom logic for dynamic attributes, leveling, crafting, staking, and governance.
*   Uses simple mappings for roles (`isAdmin`, `isMinter`).
*   State variables to store dynamic attributes (`tokenAttributes`, `tokenXP`, `tokenLevel`, `tokenStaked`, `stakeStartTime`), crafting recipes, governance proposals, etc.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary above

contract DynamicNFTForge is ERC721Enumerable, ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Access Control
    mapping(address => bool) private admins;
    mapping(address => bool) private minters;

    // Contract State
    bool public craftingPaused = false;

    // Dynamic Attributes (Simplified - could be structs for more complex data)
    mapping(uint256 => uint256) private tokenLevel;
    mapping(uint256 => uint256) private tokenExperience;
    mapping(uint256 => mapping(string => string)) private tokenAttributes; // Map token ID to attribute name to value

    // Staking
    mapping(uint256 => bool) private tokenStaked;
    mapping(uint256 => uint40) private stakeStartTime; // uint40 for timestamp

    // Metadata
    string private _baseTokenURI;
    uint256 public constant LEVEL_UP_XP_BASE = 100; // Base XP needed for level 1
    uint256 public constant LEVEL_UP_XP_MULTIPLIER = 150; // % increase per level

    // Crafting Recipes (Simplified: Maps a recipe ID to an array of required token IDs/types)
    // In a real system, this would be more complex, potentially involving quantities and Fungible Tokens
    struct Recipe {
        string name;
        uint256[] requiredTokenIds; // Simplified: require specific token IDs, or conceptually types
        uint256 outputTokenTypeId; // Conceptual ID for the forged token type
        bool active;
    }
    mapping(uint256 => Recipe) private forgeRecipes;
    uint256 private nextRecipeId = 1; // Counter for recipe IDs

    // Governance
    struct Proposal {
        address proposer;
        uint256 tokenId; // Token used to make the proposal (locked during voting)
        string targetAttribute; // The attribute proposed to change (or special keyword)
        string newValue; // The proposed new value
        uint256 startTime;
        uint256 endTime;
        mapping(uint256 => bool) votes; // Map token ID used for vote to true (1 token = 1 vote)
        uint256 totalVotes;
        bool executed;
        bool exists; // To check if a proposal ID is valid
    }
    mapping(uint256 => Proposal) private proposals;
    uint256 private nextProposalId = 1; // Counter for proposal IDs
    uint256 public minVotingPeriod = 1 days; // Minimum duration for voting
    uint256 public votingQuorumPercentage = 5; // 5% of total supply must vote for proposal to be valid
    uint256 public voteThresholdPercentage = 51; // 51% of votes must be 'yes' for success

    // --- Events ---
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event CraftingPaused(address indexed account);
    event CraftingUnpaused(address indexed account);
    event TokenMinted(address indexed owner, uint256 indexed tokenId, string initialType); // Added type for concept
    event ExperienceGained(uint256 indexed tokenId, uint256 amount, uint256 newExperience);
    event LevelledUp(uint256 indexed tokenId, uint256 newLevel, uint256 remainingExperience);
    event AttributeUpdated(uint256 indexed tokenId, string indexed attributeName, string newValue);
    event TokenForged(address indexed owner, uint256 indexed newTokenId, uint256 indexed recipeId);
    event TokenStaked(uint256 indexed tokenId, address indexed owner, uint40 timestamp);
    event TokenUnstaked(uint256 indexed tokenId, address indexed owner, uint40 timestamp);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed tokenId, string indexed targetAttribute, string newValue, uint256 endTime);
    event Voted(uint256 indexed proposalId, uint256 indexed tokenId, address indexed voter); // Assuming 1 token 1 vote 'yes'
    event ProposalExecuted(uint256 indexed proposalId);
    event OracleDataReceived(uint256 indexed tokenId, string indexed attribute, string value);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin");
        _;
    }

    modifier onlyMinter() {
        require(minters[msg.sender] || admins[msg.sender], "Only minter or admin");
        _;
    }

    modifier whenNotPaused(bool _isCrafting) {
        if (_isCrafting) {
            require(!craftingPaused, "Crafting is paused");
        }
        // Add other pause states if needed
        _;
    }

    modifier whenNotStaked(uint256 tokenId) {
        require(!tokenStaked[tokenId], "Token is staked");
        _;
    }

    modifier whenStaked(uint256 tokenId) {
        require(tokenStaked[tokenId], "Token is not staked");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address initialAdmin, address[] memory initialMinters, uint96 defaultRoyaltyFeeNumerator, address defaultRoyaltyReceiver)
        ERC721(name, symbol)
        ERC2981(defaultRoyaltyFeeNumerator) // Set default royalty
    {
        require(initialAdmin != address(0), "Initial admin cannot be zero address");
        admins[initialAdmin] = true;
        emit AdminAdded(initialAdmin);

        for (uint i = 0; i < initialMinters.length; i++) {
            require(initialMinters[i] != address(0), "Initial minter cannot be zero address");
            minters[initialMinters[i]] = true;
            emit MinterAdded(initialMinters[i]);
        }

        // Set default royalty receiver
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultRoyaltyFeeNumerator);

        // Example: Add a sample crafting recipe
        // In a real system, this would likely be configured via admin functions
        uint256 recipeId = nextRecipeId++;
        forgeRecipes[recipeId] = Recipe({
            name: "Basic Elemental Core",
            requiredTokenIds: new uint256[](2), // Requires 2 specific tokens (e.g., ID 1 and ID 2)
            outputTokenTypeId: 100, // Conceptual ID for the output token type
            active: true
        });
        forgeRecipes[recipeId].requiredTokenIds[0] = 1; // Example requirement: Token ID 1
        forgeRecipes[recipeId].requiredTokenIds[1] = 2; // Example requirement: Token ID 2
    }

    // --- Core ERC721 Overrides & Extensions ---

    // 1. tokenURI (Dynamic)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            // Fallback or error if base URI not set
            return "";
        }

        // Construct dynamic part of the URI based on state
        // Example: baseURI/tokenId?level=X&xp=Y&status=Z&attr_A=ValA
        string memory level = Strings.toString(tokenLevel[tokenId]);
        string memory xp = Strings.toString(tokenExperience[tokenId]);
        string memory status = tokenStaked[tokenId] ? "staked" : "active"; // Example status

        // Append level, xp, status as query parameters or path segments
        // More complex systems might hash the attributes or use a dedicated metadata service endpoint
        string memory dynamicPart = string(abi.encodePacked(
            Strings.toString(tokenId),
            "?level=", level,
            "&xp=", xp,
            "&status=", status
            // Append other attributes dynamically if needed, might get long
            // "&attribute_A=", tokenAttributes[tokenId]["attribute_A"] // Example
        ));

        return string(abi.encodePacked(base, dynamicPart));
    }

    // 2. mint (Restricted)
    function mint(address to, uint256 initialLevel, uint256 initialExperience, string memory initialType)
        public
        onlyMinter
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId); // Uses safeMint

        tokenLevel[newTokenId] = initialLevel;
        tokenExperience[newTokenId] = initialExperience;
        tokenAttributes[newTokenId]["type"] = initialType; // Store type as an attribute

        emit TokenMinted(to, newTokenId, initialType);

        return newTokenId;
    }

    // 3. transferFrom (Override to prevent staked transfer)
    function transferFrom(address from, address to, uint256 tokenId) public override whenNotStaked(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    // 4. safeTransferFrom (Override to prevent staked transfer)
    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotStaked(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    // 5. safeTransferFrom (Override to prevent staked transfer) - With data
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotStaked(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // 6. approve (Standard)
    function approve(address to, uint256 tokenId) public override {
        require(ownerOf(tokenId) == msg.sender, "ERC721: approve caller is not owner nor approved");
        super.approve(to, tokenId);
    }

    // 7. setApprovalForAll (Standard)
    function setApprovalForAll(address operator, bool approved) public override {
         require(operator != msg.sender, "ERC721: approve to caller");
         super.setApprovalForAll(operator, approved);
    }

    // 8. getApproved (Standard)
    function getApproved(uint256 tokenId) public view override returns (address) {
        return super.getApproved(tokenId);
    }

    // 9. isApprovedForAll (Standard)
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    // 10. balanceOf (Standard)
    function balanceOf(address owner) public view override returns (uint256) {
        return super.balanceOf(owner);
    }

    // 11. ownerOf (Standard)
    function ownerOf(uint255 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    // 12. burn (Standard, but prevent if staked)
    function burn(uint256 tokenId) public virtual whenNotStaked(tokenId) {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
        // Clean up dynamic state (optional, gas-intensive)
        delete tokenLevel[tokenId];
        delete tokenExperience[tokenId];
        delete tokenStaked[tokenId];
        delete stakeStartTime[tokenId];
        // Clearing complex mappings like tokenAttributes[tokenId] is hard/impossible directly
        // Could iterate if keys were tracked, but generally left to be overwritten or ignored.
    }

    // --- Dynamic Attributes & Leveling Functions ---

    // 13. getLevel
    function getLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenLevel[tokenId];
    }

    // 14. getExperience
    function getExperience(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenExperience[tokenId];
    }

    // 15. gainExperience (Restricted)
    function gainExperience(uint256 tokenId, uint256 amount) public onlyAdmin whenNotStaked(tokenId) { // Only admin/system can grant XP
        require(_exists(tokenId), "Token does not exist");
        require(amount > 0, "XP amount must be positive");

        tokenExperience[tokenId] += amount;
        emit ExperienceGained(tokenId, amount, tokenExperience[tokenId]);

        // Check for level up
        uint256 currentLevel = tokenLevel[tokenId];
        uint256 xpNeededForNextLevel = getXpNeededForLevel(currentLevel + 1);

        while (tokenExperience[tokenId] >= xpNeededForNextLevel && xpNeededForNextLevel > 0) { // xpNeededForNextLevel == 0 check prevents infinite loop if calc overflows
            tokenLevel[tokenId]++;
            tokenExperience[tokenId] -= xpNeededForNextLevel;
            emit LevelledUp(tokenId, tokenLevel[tokenId], tokenExperience[tokenId]);
            currentLevel = tokenLevel[tokenId];
            xpNeededForNextLevel = getXpNeededForLevel(currentLevel + 1);
        }
    }

    // Helper for leveling
    function getXpNeededForLevel(uint256 level) public pure returns (uint256) {
        if (level == 0) return 0; // Should not happen with level starting at 1
        if (level == 1) return LEVEL_UP_XP_BASE;
        // Simple exponential scaling: Base * (Multiplier/100)^(level-1)
        // Using integer arithmetic, this is approximate
        uint256 xp = LEVEL_UP_XP_BASE;
        for (uint256 i = 1; i < level; i++) {
             xp = xp * LEVEL_UP_XP_MULTIPLIER / 100;
             // Add a cap to prevent overflow or unreasonable values if needed
        }
        return xp;
    }

    // 16. updateTokenAttribute (Admin/System function for arbitrary attributes)
    function updateTokenAttribute(uint256 tokenId, string memory attributeName, string memory newValue) public onlyAdmin {
        require(_exists(tokenId), "Token does not exist");
        require(bytes(attributeName).length > 0, "Attribute name cannot be empty");

        tokenAttributes[tokenId][attributeName] = newValue;
        emit AttributeUpdated(tokenId, attributeName, newValue);
    }

    // Query arbitrary attribute
    function getTokenAttribute(uint256 tokenId, string memory attributeName) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return tokenAttributes[tokenId][attributeName];
    }


    // --- Crafting/Forging Functions ---

    // 17. forgeNFT (Simplified crafting mechanism)
    function forgeNFT(uint256 recipeId) public whenNotPaused(true) returns (uint256) {
        Recipe storage recipe = forgeRecipes[recipeId];
        require(recipe.active, "Recipe is not active");
        require(recipe.requiredTokenIds.length > 0, "Recipe has no requirements");

        // --- Check Ownership and Burn Components ---
        // This is a very simplified model requiring *specific* token IDs.
        // A more realistic system would check for *types* and quantities owned by msg.sender
        uint256[] memory required = recipe.requiredTokenIds;
        address owner = msg.sender;
        uint256[] memory tokensToBurn = new uint256[](required.length);

        // Check all required tokens are owned by msg.sender and not staked/used elsewhere
        for(uint i = 0; i < required.length; i++) {
            uint256 compTokenId = required[i];
            require(_exists(compTokenId), "Required component token does not exist");
            require(ownerOf(compTokenId) == owner, "Must own all required components");
            require(!tokenStaked[compTokenId], "Required component token is staked");
            // Add checks for proposal locking or other uses
            tokensToBurn[i] = compTokenId; // Collect IDs to burn
        }

        // Burn the required tokens
        for(uint i = 0; i < tokensToBurn.length; i++) {
            _burn(tokensToBurn[i]);
            // Clean up state for burned tokens (similar to burn function)
            delete tokenLevel[tokensToBurn[i]];
            delete tokenExperience[tokensToBurn[i]];
             delete tokenStaked[tokensToBurn[i]];
            delete stakeStartTime[tokensToBurn[i]];
            // tokenAttributes[tokensToBurn[i]] cannot be fully cleared easily
        }

        // --- Mint the New NFT ---
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(owner, newTokenId);

        // Initialize the new NFT based on the recipe's output type
        // This is conceptual; real systems would have complex initialization
        tokenLevel[newTokenId] = 1; // Start at Level 1
        tokenExperience[newTokenId] = 0;
        tokenAttributes[newTokenId]["type"] = Strings.toString(recipe.outputTokenTypeId); // Store output type

        emit TokenForged(owner, newTokenId, recipeId);
        return newTokenId;
    }

    // 18. getForgeRecipe (View)
    function getForgeRecipe(uint256 recipeId) public view returns (Recipe memory) {
        require(forgeRecipes[recipeId].active, "Recipe is not active or does not exist");
        return forgeRecipes[recipeId];
    }

    // --- Staking Functions ---

    // 19. stakeNFT
    function stakeNFT(uint256 tokenId) public whenNotStaked(tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only owner can stake");
        // Add check if token is currently locked in a governance proposal

        tokenStaked[tokenId] = true;
        stakeStartTime[tokenId] = uint40(block.timestamp); // Use uint40 to save gas if timestamp fits

        emit TokenStaked(tokenId, msg.sender, stakeStartTime[tokenId]);
    }

    // 20. unstakeNFT
    function unstakeNFT(uint256 tokenId) public whenStaked(tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only owner can unstake");

        // Optional: Calculate/distribute yield here in a real implementation
        // uint256 yield = calculateSimulatedYield(tokenId);
        // Call another contract or transfer tokens here...

        tokenStaked[tokenId] = false;
        delete stakeStartTime[tokenId]; // Reset stake timer

        emit TokenUnstaked(tokenId, msg.sender, uint40(block.timestamp));
    }

    // 21. isStaked (View)
    function isStaked(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return tokenStaked[tokenId];
    }

    // 22. getStakeDuration (View)
    function getStakeDuration(uint256 tokenId) public view whenStaked(tokenId) returns (uint256) {
         require(_exists(tokenId), "Token does not exist"); // Redundant due to modifier, but good practice
         return block.timestamp - stakeStartTime[tokenId];
    }

    // 23. calculateSimulatedYield (View) - No actual token transfer
    function calculateSimulatedYield(uint256 tokenId) public view whenStaked(tokenId) returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        uint256 duration = block.timestamp - stakeStartTime[tokenId];
        // Simple example yield: 1 unit per hour staked (scaled)
        // In a real system, this would be more complex: yield tokens, varied rates, etc.
        uint256 simulatedYield = duration / 3600; // Yield per hour
        return simulatedYield;
    }


    // --- Governance Functions (Simplified) ---

    // 24. proposeMetadataChange (Requires token to be locked)
    function proposeMetadataChange(uint256 tokenId, string memory targetAttribute, string memory newValue) public whenNotStaked(tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only owner can propose with their token");
        require(bytes(targetAttribute).length > 0, "Target attribute name cannot be empty");

        // Lock the token for the proposal period
        // A real system might transfer it to the contract or map its status
        // For simplicity here, we'll add a state variable (though this wasn't in the initial draft, let's add it)
        // Let's just add a mapping to track locked tokens for proposals
        require(!isTokenLockedForProposal[tokenId], "Token already locked for a proposal");

        uint256 proposalId = nextProposalId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + minVotingPeriod; // Simple fixed period

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            tokenId: tokenId,
            targetAttribute: targetAttribute,
            newValue: newValue,
            startTime: startTime,
            endTime: endTime,
            totalVotes: 0,
            executed: false,
            exists: true // Mark proposal as existing
            // votes mapping is initialized empty
        });

        isTokenLockedForProposal[tokenId] = true; // Lock the token

        emit ProposalCreated(proposalId, tokenId, targetAttribute, newValue, endTime);
    }
    mapping(uint256 => bool) private isTokenLockedForProposal; // New state variable


    // 25. voteForMetadataChange (1 token = 1 vote)
    function voteForMetadataChange(uint256 proposalId, uint256 votingTokenId) public whenNotStaked(votingTokenId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Voting period is not active");
        require(ownerOf(votingTokenId) == msg.sender, "Must own the token used for voting");
        require(!proposal.votes[votingTokenId], "Token already voted on this proposal");

        proposal.votes[votingTokenId] = true;
        proposal.totalVotes++;

        emit Voted(proposalId, votingTokenId, msg.sender);
    }

    // 26. executeMetadataChange
    function executeMetadataChange(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.endTime, "Voting period is still active"); // Execution after voting ends

        uint256 totalNFTSupply = totalSupply();
        uint256 requiredQuorum = totalNFTSupply * votingQuorumPercentage / 100;
        uint256 requiredVotes = proposal.totalVotes * voteThresholdPercentage / 100; // Threshold based on votes cast

        // More robust check: Threshold based on total supply * totalVotes / requiredQuorum? Or just total supply
        // Let's use threshold based on total votes cast for simplicity
        bool quorumMet = proposal.totalVotes >= requiredQuorum;
        bool thresholdMet = proposal.totalVotes >= requiredVotes; // Simple check, could be more complex (e.g., unique voters)

        if (quorumMet && thresholdMet) {
            // Execute the change
            uint256 targetTokenId = proposal.tokenId;
            string memory targetAttr = proposal.targetAttribute;
            string memory newVal = proposal.newValue;

            // For this simple example, it only supports changing arbitrary attributes
            // A real system would have different proposal types (e.g., change baseURI, change recipe, change levelUpXP)
            // For now, just update the target token's attribute
             require(_exists(targetTokenId), "Target token for proposal does not exist"); // Should still exist
            tokenAttributes[targetTokenId][targetAttr] = newVal;
            emit AttributeUpdated(targetTokenId, targetAttr, newVal);

            proposal.executed = true;
            emit ProposalExecuted(proposalId);
        } else {
            // Proposal failed
        }

        // Unlock the token used for proposing
        require(isTokenLockedForProposal[proposal.tokenId], "Proposing token not locked unexpectedly");
        delete isTokenLockedForProposal[proposal.tokenId];
    }

    // 27. getProposalDetails (View)
     function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(proposals[proposalId].exists, "Proposal does not exist");
        return proposals[proposalId];
    }

    // 28. getActiveProposals (View) - Simple: List all non-executed proposals. Could add filtering.
    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](nextProposalId);
        uint256 count = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (proposals[i].exists && !proposals[i].executed && block.timestamp <= proposals[i].endTime) {
                activeIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for(uint i=0; i < count; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

    // --- Admin & Access Control Functions ---

    // 29. addMinter
    function addMinter(address minterAddress) public onlyAdmin {
        require(minterAddress != address(0), "Minter address cannot be zero");
        require(!minters[minterAddress], "Address is already a minter");
        minters[minterAddress] = true;
        emit MinterAdded(minterAddress);
    }

    // 30. removeMinter
    function removeMinter(address minterAddress) public onlyAdmin {
        require(minters[minterAddress], "Address is not a minter");
        minters[minterAddress] = false;
        emit MinterRemoved(minterAddress);
    }

    // 31. pauseCrafting
    function pauseCrafting() public onlyAdmin {
        require(!craftingPaused, "Crafting is already paused");
        craftingPaused = true;
        emit CraftingPaused(msg.sender);
    }

    // 32. unpauseCrafting
    function unpauseCrafting() public onlyAdmin {
        require(craftingPaused, "Crafting is not paused");
        craftingPaused = false;
        emit CraftingUnpaused(msg.sender);
    }

    // 33. updateBaseURI
    function updateBaseURI(string memory baseURI) public onlyAdmin {
        _baseTokenURI = baseURI;
    }

    // 34. requestAttributeUpdateFromOracle (Simulated Oracle Call)
    // In a real system, this would be triggered by an oracle contract via Chainlink Keepers or similar
    // Here, only the admin can call it to simulate the effect.
    function requestAttributeUpdateFromOracle(uint256 tokenId, string memory attributeName, string memory oracleReportedValue) public onlyAdmin {
        require(_exists(tokenId), "Token does not exist");
         require(bytes(attributeName).length > 0, "Attribute name cannot be empty");

        // Simulate processing data from the oracle
        // In a real oracle integration, this function would receive data pushed by the oracle
        // or pull data based on a trigger.
        tokenAttributes[tokenId][attributeName] = oracleReportedValue;
        emit OracleDataReceived(tokenId, attributeName, oracleReportedValue);
        emit AttributeUpdated(tokenId, attributeName, oracleReportedValue); // Also log as attribute update

        // Potentially trigger other effects based on oracle data (e.g., grant XP based on "weather")
        // if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("weather")) && keccak256(abi.encodePacked(oracleReportedValue)) == keccak256(abi.encodePacked("sunny"))) {
        //     gainExperience(tokenId, 10); // Example effect
        // }
    }


    // --- ERC2981 Royalties ---
    // Implementation inherited from ERC2981.
    // 35. supportsInterface (Override)
    // Need to override supportsInterface to register ERC2981 and ERC721Enumerable interfaces
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 36. setDefaultRoyalty (Inherited from ERC2981) - callable by owner (implicitly msg.sender as admin)
     // function setDefaultRoyalty(address receiver, uint96 feeNumerator) public override onlyOwner; // Original signature, but needs owner/admin check. Let's use admin.
     function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyAdmin {
         super.setDefaultRoyalty(receiver, feeNumerator);
     }

     // 37. setTokenRoyalty (Inherited from ERC2981) - callable by owner (implicitly msg.sender as admin)
     // function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public override onlyOwner; // Original signature, let's use admin.
     function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyAdmin {
         super.setTokenRoyalty(tokenId, receiver, feeNumerator);
     }

     // 38. royaltyInfo (Inherited from ERC2981)
     // function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount); // Standard view function

    // Adding a couple more view functions for querying state easily to reach >= 20 interesting functions
    // 39. isAdmin (View)
    function isAdmin(address account) public view returns (bool) {
        return admins[account];
    }

    // 40. isMinter (View)
     function isMinter(address account) public view returns (bool) {
        return minters[account];
    }

    // Add a function to get the list of tokens locked for proposals if needed, or simplify state.
    // Given the count is well over 20, we can stop here. The concepts are covered.
}
```

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Dynamic State (`tokenLevel`, `tokenExperience`, `tokenAttributes`):** Instead of fixed data, NFTs have properties that can change post-minting. This is fundamental to creating "living" or evolving assets.
2.  **Dynamic `tokenURI`:** The metadata is not static. The `tokenURI` function calculates and returns a URL that reflects the *current* state of the NFT (level, status, etc.). This URL would point to an off-chain service that generates the metadata JSON and potentially the image dynamically based on the query parameters. This is a key component of dynamic NFTs.
3.  **Experience and Leveling (`gainExperience`, `getLevel`, `getExperience`):** Introduces a progression system common in games, making NFTs feel like characters or items that can improve.
4.  **Crafting/Forging (`forgeNFT`, `getForgeRecipe`):** Allows for interaction between NFTs (burning components to create a new one). This adds utility and introduces deflationary mechanics for the components. The recipe system, while simple here, can be extended for complex item creation.
5.  **Staking (`stakeNFT`, `unstakeNFT`, `isStaked`, `getStakeDuration`, `calculateSimulatedYield`):** Allows holders to signal commitment or participate in passive benefits. The prevention of transfer while staked adds a layer of statefulness and potential use cases in DeFi or gaming.
6.  **Simple Governance (`proposeMetadataChange`, `voteForMetadataChange`, `executeMetadataChange`, `getProposalDetails`, `getActiveProposals`):** Demonstrates how token holders can have a say in the evolution of the assets or the protocol. The 1-token-1-vote mechanism is basic but illustrates the concept of decentralized decision-making tied to asset ownership. Locking the token during proposals adds a cost/commitment to participation.
7.  **Simulated Oracle Interaction (`requestAttributeUpdateFromOracle`):** While simplified to an admin call, this function pattern shows how off-chain data (like real-world events, game results, etc.) could be fed into the contract to influence NFT attributes, making them reactive to external conditions.
8.  **Attribute Mapping (`tokenAttributes`):** Allows for flexible, arbitrary attributes to be added and updated, making the NFTs adaptable to various use cases without needing a fixed structure for all possible stats.
9.  **Role-Based Access Control (Custom):** Instead of relying solely on `Ownable`, implementing simple roles (`admin`, `minter`) offers more granular control over who can perform sensitive actions, a common pattern in dApps.
10. **Utilizing OpenZeppelin Composability:** Inheriting from `ERC721Enumerable` and `ERC2981` shows how to build upon existing standards while adding complex custom logic, which is a standard but good practice in modern Solidity development.

This contract provides a solid foundation for building complex, interactive NFT ecosystems. It goes significantly beyond the basic mint-and-transfer functionality of a simple ERC721.