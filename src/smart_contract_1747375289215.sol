Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts beyond standard token functionalities. It's designed as a "Creative Fusion Forge" where users can combine unique digital assets (NFTs) to create new ones, manage dynamic attributes, stake tokens for utility delegation, and interact with a generative minting process.

It aims to avoid direct duplication of full, standard open-source patterns like OpenZeppelin's `AccessControl` or `ERC721Enumerable`, instead implementing simpler custom versions or focusing on novel mechanics built *on top* of basic standards.

**Outline:**

1.  **SPDX License & Pragma**
2.  **Imports:** ERC721 standard
3.  **Contract Definition**
4.  **Constants:** Role identifiers, contract state
5.  **Enums:** Contract State
6.  **State Variables:**
    *   Contract ownership and state
    *   Role management
    *   Token Counters
    *   Token Attributes (dynamic)
    *   Attribute Modifiers (temporary/conditional)
    *   Fusion Recipes (inputs -> output)
    *   Staking Information
    *   Utility Delegation
    *   Token URI base
    *   Fusion Fee
    *   Paused state
7.  **Events:**
    *   Minting (Generative, Fusion)
    *   Fusion Recipe Management
    *   Attribute Updates/Evolution
    *   Staking/Unstaking
    *   Utility Delegation
    *   Role Management
    *   State Changes (Pause, Unpause)
    *   Ownership Transfer
    *   Fee Updates
8.  **Modifiers:** Access control checks (roles, paused)
9.  **Constructor:** Initializes contract, owner, base URI, initial roles.
10. **ERC721 Standard Overrides:** (`supportsInterface`, `tokenURI`)
11. **Core NFT Management Functions:**
    *   `mintGenerative`: Mints a new NFT based on pseudo-randomness/inputs.
    *   `burnToken`: Destroys an NFT (with checks).
    *   `updateAttribute`: Manually sets an attribute for a token.
    *   `evolveAttribute`: Triggers a predefined attribute evolution logic.
    *   `getAttribute`: Retrieves a specific attribute value.
    *   `getTokenDetails`: Retrieves all main attributes for a token.
12. **Fusion System Functions:**
    *   `defineFusionRecipe`: Creates or updates a recipe requiring specific tokens/attributes as input for a new output token type.
    *   `removeFusionRecipe`: Deletes a recipe.
    *   `performFusion`: Executes a recipe, burning inputs, minting output, collecting fee.
    *   `getFusionRecipe`: Retrieves details of a recipe.
    *   `getAvailableRecipes`: Lists existing recipe identifiers.
    *   `setFusionFee`: Sets the fee for performing fusion.
    *   `getFusionFee`: Gets the current fusion fee.
13. **Staking & Utility Functions:**
    *   `stakeToken`: Locks a token in the contract.
    *   `unstakeToken`: Unlocks a staked token.
    *   `isTokenStaked`: Checks if a token is staked.
    *   `getStakedBy`: Gets the address that staked a token.
    *   `delegateUtility`: Allows a staker to delegate utility access to another address.
    *   `revokeUtilityDelegation`: Revokes utility delegation.
    *   `isUtilityDelegatedTo`: Checks if utility of a token is delegated to a specific address.
    *   `checkAccess`: Determines if an address has utility access for a token (owner OR staker OR delegatee).
14. **Dynamic Attributes & Modifiers:**
    *   `setAttributeModifier`: Applies a temporary/conditional modifier to an attribute.
    *   `removeAttributeModifier`: Removes a modifier.
    *   `getAttributeModifier`: Gets details of a modifier.
    *   `calculateEffectiveAttribute`: Calculates the final attribute value considering modifiers.
15. **Role Management Functions:** (Custom simple implementation)
    *   `grantRole`: Grants a specific role to an address.
    *   `revokeRole`: Revokes a specific role from an address.
    *   `hasRole`: Checks if an address has a specific role.
    *   `getRoleAdmin`: (Optional - for complex systems, omit for simple)
16. **Contract Management Functions:**
    *   `pauseContract`: Sets the contract state to Paused.
    *   `unpauseContract`: Sets the contract state to Active.
    *   `getContractState`: Gets the current state (Active/Paused).
    *   `withdrawFunds`: Allows owner/admin to withdraw collected Ether fees.
    *   `transferOwnership`: Transfers contract ownership.
    *   `getOwner`: Gets the current contract owner.

**Function Summary:**

*   `constructor(string memory name, string memory symbol, string memory baseURI)`: Initializes the contract name, symbol, base URI, and sets the deployer as owner and initial admin.
*   `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: Standard ERC165 interface detection.
*   `tokenURI(uint256 tokenId) public view override returns (string memory)`: Returns the metadata URI for a token, incorporating dynamic aspects or just base URI + ID.
*   `mintGenerative(address to, uint256 specificSeed) external onlyRole(MINTER_ROLE) nonpayable returns (uint256 newTokenId)`: Creates a new, unique token using a combination of contract state, block data (pseudo-randomness), and a user-provided seed.
*   `burnToken(uint256 tokenId) public`: Burns (destroys) a token, requiring owner/approved status.
*   `updateAttribute(uint256 tokenId, string memory attributeName, uint256 newValue) external onlyRole(ATTRIBUTE_MANAGER_ROLE)`: Allows authorized roles to directly set a token's attribute value.
*   `evolveAttribute(uint256 tokenId) external nonpayable`: Triggers a specific attribute evolution process based on internal logic (e.g., cooldown, interaction count).
*   `getAttribute(uint256 tokenId, string memory attributeName) public view returns (uint256)`: Gets the base value of a token's attribute.
*   `getTokenDetails(uint256 tokenId) public view returns (uint256 evolutionStage, uint256 lastEvolutionTime)`: Gets core dynamic properties of a token.
*   `defineFusionRecipe(uint256 recipeId, InputItem[] memory inputs, uint256 outputTokenIdType) external onlyRole(RECIPE_MANAGER_ROLE)`: Defines or updates a recipe by specifying required input tokens/attributes and the resulting output token type.
*   `removeFusionRecipe(uint256 recipeId) external onlyRole(RECIPE_MANAGER_ROLE)`: Removes a fusion recipe.
*   `performFusion(uint256 recipeId, uint256[] memory inputTokenIds) external payable nonpaused`: Executes a fusion recipe using provided token IDs as inputs, burns them, mints the output token, and collects a fee.
*   `getFusionRecipe(uint256 recipeId) public view returns (InputItem[] memory inputs, uint256 outputTokenIdType, bool exists)`: Retrieves details of a specific fusion recipe.
*   `getAvailableRecipes() public view returns (uint256[] memory)`: Returns a list of all defined fusion recipe IDs.
*   `setFusionFee(uint256 fee) external onlyOwner`: Sets the ETH fee required for performing fusion.
*   `getFusionFee() public view returns (uint256)`: Returns the current fusion fee.
*   `stakeToken(uint256 tokenId) external nonpaused`: Allows a token owner to stake their token in the contract.
*   `unstakeToken(uint256 tokenId) external nonpaused`: Allows a staker to unstake their token.
*   `isTokenStaked(uint256 tokenId) public view returns (bool)`: Checks if a token is currently staked.
*   `getStakedBy(uint256 tokenId) public view returns (address)`: Returns the address that staked a specific token (address(0) if not staked).
*   `delegateUtility(uint256 tokenId, address delegatee) external nonpaused`: Allows the staker of a token to delegate its utility benefits to another address.
*   `revokeUtilityDelegation(uint256 tokenId) external nonpaused`: Revokes any existing utility delegation for a staked token.
*   `isUtilityDelegatedTo(uint256 tokenId, address delegatee) public view returns (bool)`: Checks if utility of a staked token is delegated to a specific address.
*   `checkAccess(uint256 tokenId, address addr) public view returns (bool)`: Determines if `addr` has utility access for `tokenId` (owner, staker, or delegatee).
*   `setAttributeModifier(uint256 tokenId, string memory attributeName, int256 modifierValue, uint256 expiryTimestamp) external onlyRole(ATTRIBUTE_MANAGER_ROLE)`: Applies a temporary modifier to an attribute's effective value.
*   `removeAttributeModifier(uint256 tokenId, string memory attributeName) external onlyRole(ATTRIBUTE_MANAGER_ROLE)`: Removes a modifier from an attribute.
*   `getAttributeModifier(uint256 tokenId, string memory attributeName) public view returns (int256 modifierValue, uint256 expiryTimestamp)`: Retrieves details of a modifier.
*   `calculateEffectiveAttribute(uint256 tokenId, string memory attributeName) public view returns (uint256)`: Calculates the final attribute value considering the base value and active modifier.
*   `grantRole(string memory roleName, address account) public onlyOwner`: Grants a custom role to an address.
*   `revokeRole(string memory roleName, address account) public onlyOwner`: Revokes a custom role from an address.
*   `hasRole(string memory roleName, address account) public view returns (bool)`: Checks if an address has a specific custom role.
*   `pauseContract() external onlyRole(PAUSER_ROLE)`: Pauses core contract actions.
*   `unpauseContract() external onlyRole(PAUSER_ROLE)`: Unpauses core contract actions.
*   `getContractState() public view returns (ContractState)`: Gets the current operational state.
*   `withdrawFunds() external onlyOwner`: Allows the owner to withdraw accumulated Ether fees.
*   `transferOwnership(address newOwner) external onlyOwner`: Transfers contract ownership.
*   `getOwner() public view returns (address)`: Returns the current contract owner.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. SPDX License & Pragma
// 2. Imports (ERC721, IERC721Receiver, Strings, SafeMath)
// 3. Contract Definition (CreativeFusionForge inherits ERC721, IERC721Receiver)
// 4. Constants (Role identifiers, contract state values)
// 5. Enums (Contract State)
// 6. State Variables (Owner, Roles, Counters, Attributes, Recipes, Staking, Delegation, URI, Fee, Paused)
// 7. Structs (InputItem for recipes, AttributeModifier)
// 8. Events (Mint, Fusion, Attribute, Staking, Delegation, Role, State, Ownership, Fee)
// 9. Modifiers (Access Control, Paused Check)
// 10. Constructor
// 11. ERC721 Standard Overrides (supportsInterface, tokenURI)
// 12. Core NFT Management (mintGenerative, burnToken, updateAttribute, evolveAttribute, getAttribute, getTokenDetails)
// 13. Fusion System (defineFusionRecipe, removeFusionRecipe, performFusion, getFusionRecipe, getAvailableRecipes, setFusionFee, getFusionFee)
// 14. Staking & Utility (stakeToken, unstakeToken, isTokenStaked, getStakedBy, delegateUtility, revokeUtilityDelegation, isUtilityDelegatedTo, checkAccess)
// 15. Dynamic Attributes & Modifiers (setAttributeModifier, removeAttributeModifier, getAttributeModifier, calculateEffectiveAttribute)
// 16. Role Management (grantRole, revokeRole, hasRole) - Custom simple implementation
// 17. Contract Management (pauseContract, unpauseContract, getContractState, withdrawFunds, transferOwnership, getOwner)

// Function Summary:
// constructor(string memory name, string memory symbol, string memory baseURI): Initializes contract.
// supportsInterface(bytes4 interfaceId): Standard ERC165.
// tokenURI(uint256 tokenId): Returns metadata URI, can be dynamic.
// mintGenerative(address to, uint256 specificSeed): Mints a new NFT based on pseudo-randomness/inputs.
// burnToken(uint256 tokenId): Destroys an NFT.
// updateAttribute(uint256 tokenId, string memory attributeName, uint256 newValue): Sets an attribute value.
// evolveAttribute(uint256 tokenId): Triggers attribute evolution logic.
// getAttribute(uint256 tokenId, string memory attributeName): Gets base attribute value.
// getTokenDetails(uint256 tokenId): Gets core dynamic properties.
// defineFusionRecipe(uint256 recipeId, InputItem[] memory inputs, uint256 outputTokenIdType): Creates/updates a fusion recipe.
// removeFusionRecipe(uint256 recipeId): Removes a recipe.
// performFusion(uint256 recipeId, uint256[] memory inputTokenIds): Executes a fusion recipe, burns inputs, mints output, collects fee.
// getFusionRecipe(uint256 recipeId): Gets recipe details.
// getAvailableRecipes(): Lists recipe IDs.
// setFusionFee(uint256 fee): Sets fusion fee.
// getFusionFee(): Gets fusion fee.
// stakeToken(uint256 tokenId): Locks a token.
// unstakeToken(uint256 tokenId): Unlocks a token.
// isTokenStaked(uint256 tokenId): Checks if staked.
// getStakedBy(uint256 tokenId): Gets staker address.
// delegateUtility(uint256 tokenId, address delegatee): Delegates utility access.
// revokeUtilityDelegation(uint256 tokenId): Revokes delegation.
// isUtilityDelegatedTo(uint256 tokenId, address delegatee): Checks if delegated to address.
// checkAccess(uint256 tokenId, address addr): Checks utility access (owner, staker, delegatee).
// setAttributeModifier(uint256 tokenId, string memory attributeName, int256 modifierValue, uint256 expiryTimestamp): Applies a temporary attribute modifier.
// removeAttributeModifier(uint256 tokenId, string memory attributeName): Removes a modifier.
// getAttributeModifier(uint256 tokenId, string memory attributeName): Gets modifier details.
// calculateEffectiveAttribute(uint256 tokenId, string memory attributeName): Gets attribute value including active modifier.
// grantRole(string memory roleName, address account): Grants a custom role.
// revokeRole(string memory roleName, address account): Revokes a custom role.
// hasRole(string memory roleName, address account): Checks for a role.
// pauseContract(): Pauses contract actions.
// unpauseContract(): Unpauses contract actions.
// getContractState(): Gets current state.
// withdrawFunds(): Withdraws ETH fees.
// transferOwnership(address newOwner): Transfers ownership.
// getOwner(): Gets current owner.

contract CreativeFusionForge is ERC721, IERC721Receiver {
    using Strings for uint256;
    using SafeMath for uint256;

    // --- Constants ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant RECIPE_MANAGER_ROLE = keccak256("RECIPE_MANAGER_ROLE");
    bytes32 public constant ATTRIBUTE_MANAGER_ROLE = keccak256("ATTRIBUTE_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- Enums ---
    enum ContractState { Active, Paused }

    // --- State Variables ---

    // Ownership & Roles (simple custom implementation)
    address private _owner;
    mapping(address => mapping(bytes32 => bool)) private _roles;

    // Token Counters
    uint256 private _nextTokenId; // Counter for unique token IDs

    // Dynamic Token Attributes
    mapping(uint256 => mapping(string => uint256)) private tokenAttributes; // tokenId => attributeName => value
    mapping(uint256 => uint256) private tokenEvolutionStage; // tokenId => stage
    mapping(uint256 => uint256) private tokenLastEvolutionTime; // tokenId => timestamp

    // Attribute Modifiers
    struct AttributeModifier {
        int256 modifierValue; // Can be negative for reduction
        uint256 expiryTimestamp; // When the modifier expires (0 for non-expiring, but we enforce > block.timestamp or 0)
        bool isActive; // Flag to indicate if a modifier is set
    }
    mapping(uint256 => mapping(string => AttributeModifier)) private tokenAttributeModifiers; // tokenId => attributeName => modifier

    // Fusion System
    struct InputItem {
        uint256 tokenTypeId; // Type of token required (e.g., a specific base type or attribute combo)
        string requiredAttributeName; // Optional: require token to have specific attribute
        uint256 requiredAttributeValue; // Optional: require specific attribute value (use 0 for 'any value' or 'attribute not required')
        uint256 quantity; // How many are needed (for NFT fusion, typically 1 per item)
    }
    struct FusionRecipe {
        InputItem[] inputs;
        uint256 outputTokenIdType; // Identifier for the output token's 'type' or base ID for generation
        bool exists; // Flag to check if recipe is defined
    }
    mapping(uint256 => FusionRecipe) private fusionRecipes; // recipeId => Recipe details
    uint256[] private definedRecipeIds; // List of active recipe IDs

    uint256 private _fusionFee; // Fee required in Ether to perform fusion

    // Staking & Utility Delegation
    mapping(uint256 => address) private stakedTokens; // tokenId => staker address (address(0) if not staked)
    mapping(uint256 => address) private utilityDelegation; // tokenId => delegatee address (address(0) if no delegation)

    // Metadata
    string private _baseTokenURI;

    // Contract State
    ContractState private _contractState;

    // --- Events ---

    event TokenGenerativeMinted(address indexed to, uint256 indexed tokenId, uint256 seedUsed);
    event TokenFusionMinted(address indexed to, uint256 indexed tokenId, uint256 indexed recipeId, uint256[] inputTokenIds);
    event TokenBurned(uint256 indexed tokenId, address indexed from);

    event AttributeUpdated(uint256 indexed tokenId, string attributeName, uint256 oldValue, uint256 newValue);
    event AttributeEvolved(uint256 indexed tokenId, uint256 newStage, uint256 evolutionTime);
    event AttributeModifierSet(uint256 indexed tokenId, string attributeName, int256 modifierValue, uint256 expiryTimestamp);
    event AttributeModifierRemoved(uint256 indexed tokenId, string attributeName);

    event FusionRecipeDefined(uint256 indexed recipeId, uint256 outputTokenIdType);
    event FusionRecipeRemoved(uint256 indexed recipeId);
    event FusionPerformed(address indexed user, uint256 indexed recipeId, uint256 indexed outputTokenId, uint256[] inputTokenIds, uint256 feePaid);
    event FusionFeeSet(uint256 oldFee, uint256 newFee);

    event TokenStaked(uint256 indexed tokenId, address indexed staker);
    event TokenUnstaked(uint256 indexed tokenId, address indexed staker);
    event UtilityDelegated(uint256 indexed tokenId, address indexed staker, address indexed delegatee);
    event UtilityDelegationRevoked(uint256 indexed tokenId, address indexed staker, address indexed delegatee);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    event ContractPaused(address account);
    event ContractUnpaused(address account);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(_roles[msg.sender][role], "Caller is missing required role");
        _;
    }

    modifier nonpaused() {
        require(_contractState == ContractState.Active, "Contract is paused");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
    {
        _owner = msg.sender;
        _baseTokenURI = baseURI;
        _contractState = ContractState.Active;

        // Grant initial roles to the owner
        _roles[msg.sender][MINTER_ROLE] = true;
        _roles[msg.sender][RECIPE_MANAGER_ROLE] = true;
        _roles[msg.sender][ATTRIBUTE_MANAGER_ROLE] = true;
        _roles[msg.sender][PAUSER_ROLE] = true;

        emit RoleGranted(MINTER_ROLE, msg.sender, msg.sender);
        emit RoleGranted(RECIPE_MANAGER_ROLE, msg.sender, msg.sender);
        emit RoleGranted(ATTRIBUTE_MANAGER_ROLE, msg.sender, msg.sender);
        emit RoleGranted(PAUSER_ROLE, msg.sender, msg.sender);
    }

    // --- ERC721 Standard Overrides ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId || // Support receiving tokens if needed
               super.supportsInterface(interfaceId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for a given token ID
     * will be the concatenation of the `baseURI` and the token ID.
     * Can be overridden to implement custom URI generation, e.g., including dynamic attributes.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ERC721-tokenURI}.
     * Overridden to show how dynamic attributes could influence metadata (even if pointer is static).
     * A real implementation would have an off-chain service resolving this URI to dynamic JSON.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Example of how you *could* pass dynamic data to the URI handler
        // string memory dynamicPart = string.concat(
        //     "&stage=", tokenEvolutionStage[tokenId].toString(),
        //     "&lastEvo=", tokenLastEvolutionTime[tokenId].toString()
        // );

        string memory base = _baseURI();
        return bytes(base).length > 0
            ? string.concat(base, tokenId.toString()) // , dynamicPart) // Uncomment dynamicPart if base handler supports it
            : "";
    }

    // --- Core NFT Management Functions ---

    /**
     * @dev Mints a new token with potentially generative attributes.
     * Uses block data and a specific seed for pseudo-randomness.
     * WARNING: This is NOT cryptographically secure randomness. Do not use for high-stakes applications.
     * A proper random source would use a VRF (e.g., Chainlink VRF) or other off-chain oracle.
     */
    function mintGenerative(address to, uint256 specificSeed) external onlyRole(MINTER_ROLE) nonpayable returns (uint256 newTokenId) {
        require(to != address(0), "Mint to the zero address");

        newTokenId = _nextTokenId++;

        // Simple pseudo-randomness based on volatile data
        uint256 baseSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // block.difficulty is deprecated on PoS, use block.number or chainid instead
            block.number,
            msg.sender,
            newTokenId,
            specificSeed
        )));

        // Assign initial attributes based on the seed
        tokenAttributes[newTokenId]["Strength"] = (baseSeed % 100) + 1; // 1-100
        tokenAttributes[newTokenId]["Dexterity"] = ((baseSeed / 100) % 100) + 1; // 1-100
        tokenAttributes[newTokenId]["Luck"] = ((baseSeed / 10000) % 50) + 1; // 1-50
        tokenAttributes[newTokenId]["Type"] = (baseSeed % 5) + 1; // 1-5 (e.g., Element type)

        tokenEvolutionStage[newTokenId] = 1;
        tokenLastEvolutionTime[newTokenId] = block.timestamp;

        _safeMint(to, newTokenId);

        emit TokenGenerativeMinted(to, newTokenId, specificSeed);
    }

    /**
     * @dev Burns (destroys) a token.
     * Requires the sender to be the owner or approved for the token.
     */
    function burnToken(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");

        // Clean up associated data before burning
        // Note: Mappings don't need explicit deletion, but it's good practice if gas is critical
        // or if data needs to be reset precisely upon deletion.
        // In this case, accessing burned token data will implicitly return default values.

        _burn(tokenId);
        emit TokenBurned(tokenId, owner);
    }

    /**
     * @dev Allows setting a specific attribute for a token.
     * Only callable by addresses with the ATTRIBUTE_MANAGER_ROLE.
     */
    function updateAttribute(uint256 tokenId, string memory attributeName, uint256 newValue) external onlyRole(ATTRIBUTE_MANAGER_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        uint256 oldValue = tokenAttributes[tokenId][attributeName];
        tokenAttributes[tokenId][attributeName] = newValue;
        emit AttributeUpdated(tokenId, attributeName, oldValue, newValue);
    }

     /**
     * @dev Triggers the evolution logic for a token's stage.
     * Example logic: Can only evolve every 24 hours. Increments stage.
     * Can be called by anyone if logic permits, or restricted.
     * Current example: callable by anyone, simple time check.
     * A more complex version might require tokens/items, staking time, etc.
     */
    function evolveAttribute(uint256 tokenId) external nonpayable {
        require(_exists(tokenId), "Token does not exist");
        require(block.timestamp >= tokenLastEvolutionTime[tokenId] + 24 hours, "Evolution cooldown active");

        tokenEvolutionStage[tokenId] += 1;
        tokenLastEvolutionTime[tokenId] = block.timestamp;

        // Example: Increase a specific attribute upon evolution
        string memory attributeToBoost = "Strength"; // Or make this dynamic
        uint256 currentStrength = tokenAttributes[tokenId][attributeToBoost];
        tokenAttributes[tokenId][attributeToBoost] = currentStrength + 5; // Boost by 5

        emit AttributeEvolved(tokenId, tokenEvolutionStage[tokenId], tokenLastEvolutionTime[tokenId]);
         emit AttributeUpdated(tokenId, attributeToBoost, currentStrength, tokenAttributes[tokenId][attributeToBoost]);

        // Future idea: Add effects based on new stage or pseudo-randomness
        // uint256 evoSeed = uint256(keccak256(abi.encodePacked(tokenId, tokenEvolutionStage[tokenId], block.timestamp)));
        // if (evoSeed % 10 == 0) { grant a temporary boost }
    }

    /**
     * @dev Gets the base value of a specific attribute for a token.
     * Does not include temporary modifiers.
     */
    function getAttribute(uint256 tokenId, string memory attributeName) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenAttributes[tokenId][attributeName];
    }

    /**
     * @dev Gets core dynamic properties of a token.
     */
    function getTokenDetails(uint256 tokenId) public view returns (uint256 evolutionStage, uint256 lastEvolutionTime) {
        require(_exists(tokenId), "Token does not exist");
        return (tokenEvolutionStage[tokenId], tokenLastEvolutionTime[tokenId]);
    }


    // --- Fusion System Functions ---

    /**
     * @dev Defines or updates a fusion recipe.
     * Requires RECIPE_MANAGER_ROLE.
     * @param recipeId A unique identifier for the recipe.
     * @param inputs An array detailing the required input tokens/attributes.
     * @param outputTokenIdType An identifier used to determine the type/attributes of the output token.
     */
    function defineFusionRecipe(uint256 recipeId, InputItem[] memory inputs, uint256 outputTokenIdType) external onlyRole(RECIPE_MANAGER_ROLE) {
        require(inputs.length > 0, "Recipe requires at least one input");
        // Add input validation if needed (e.g., non-zero quantities, valid token types)

        bool wasDefined = fusionRecipes[recipeId].exists;

        fusionRecipes[recipeId] = FusionRecipe(inputs, outputTokenIdType, true);

        if (!wasDefined) {
             definedRecipeIds.push(recipeId); // Add to list if new
        }

        emit FusionRecipeDefined(recipeId, outputTokenIdType);
    }

    /**
     * @dev Removes a fusion recipe.
     * Requires RECIPE_MANAGER_ROLE.
     * Note: Removing from `definedRecipeIds` array is gas-expensive for large arrays.
     * For simplicity, we just mark as non-existent in the map. `getAvailableRecipes` will filter.
     */
    function removeFusionRecipe(uint256 recipeId) external onlyRole(RECIPE_MANAGER_ROLE) {
        require(fusionRecipes[recipeId].exists, "Recipe does not exist");

        // Mark as non-existent. Cleaning the array `definedRecipeIds` is omitted for gas efficiency.
        // A better approach for many recipes would be a linked list or managing a mapping of bools.
        fusionRecipes[recipeId].exists = false;
        // Optionally, clear the recipe details from storage to save gas on future access
        delete fusionRecipes[recipeId]; // This is fine after setting exists=false

        emit FusionRecipeRemoved(recipeId);
    }


    /**
     * @dev Performs a fusion based on a defined recipe.
     * Requires the user to own/approve the input tokens and pay the fusion fee.
     * Burns the input tokens and mints a new output token.
     * @param recipeId The ID of the recipe to use.
     * @param inputTokenIds The specific token IDs being used as input. Order might matter depending on recipe interpretation (not strictly enforced here).
     */
    function performFusion(uint256 recipeId, uint256[] memory inputTokenIds) external payable nonpaused {
        FusionRecipe storage recipe = fusionRecipes[recipeId];
        require(recipe.exists, "Recipe does not exist");
        require(msg.value >= _fusionFee, "Insufficient fusion fee");

        // Basic check: Number of input tokens must match recipe requirements
        // A more complex check would match *types* and *quantities* from recipe.inputs
        require(inputTokenIds.length == recipe.inputs.length, "Incorrect number of input tokens");

        // Verify ownership/approval and burn input tokens
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 inputTokenId = inputTokenIds[i];
            address inputTokenOwner = ownerOf(inputTokenId);
            require(inputTokenOwner == msg.sender || isApprovedForAll(inputTokenOwner, msg.sender), "Caller is not owner or approved for input token");

            // Optional: Add checks against recipe.inputs[i] requirements (tokenTypeId, attribute values)
            // This would make recipes more specific than just needing *N* inputs.
            // Example: require(tokenAttributes[inputTokenId][recipe.inputs[i].requiredAttributeName] >= recipe.inputs[i].requiredAttributeValue);
            // ... and check recipe.inputs[i].tokenTypeId if applicable.

            burnToken(inputTokenId); // Burns the token and handles ERC721 state
        }

        // Mint the output token
        uint256 outputTokenId = _nextTokenId++;
        _safeMint(msg.sender, outputTokenId);

        // Assign initial attributes to the output token based on recipe output type
        // This logic would be specific to your token types. Example:
        tokenAttributes[outputTokenId]["Type"] = recipe.outputTokenIdType;
        tokenAttributes[outputTokenId]["Strength"] = 50 + recipe.outputTokenIdType * 10; // Example: Strength based on type
        tokenEvolutionStage[outputTokenId] = 1;
        tokenLastEvolutionTime[outputTokenId] = block.timestamp;

        // Future idea: Inherit/average/combine attributes from input tokens

        emit FusionPerformed(msg.sender, recipeId, outputTokenId, inputTokenIds, msg.value);
    }

    /**
     * @dev Retrieves details of a specific fusion recipe.
     * @param recipeId The ID of the recipe to retrieve.
     * @return inputs The required input items.
     * @return outputTokenIdType The type identifier for the output token.
     * @return exists True if the recipe is defined, false otherwise.
     */
    function getFusionRecipe(uint256 recipeId) public view returns (InputItem[] memory inputs, uint256 outputTokenIdType, bool exists) {
        FusionRecipe storage recipe = fusionRecipes[recipeId];
        return (recipe.inputs, recipe.outputTokenIdType, recipe.exists);
    }

    /**
     * @dev Returns a list of currently defined fusion recipe IDs.
     * Note: This iterates over the `definedRecipeIds` array.
     * This can be gas-expensive if the number of recipes is very large.
     * Consider off-chain indexing or a different data structure for scalability.
     */
    function getAvailableRecipes() public view returns (uint256[] memory) {
        // Filter out recipes that were "removed" by setting exists=false
        uint256 count = 0;
        for(uint i = 0; i < definedRecipeIds.length; i++) {
            if(fusionRecipes[definedRecipeIds[i]].exists) {
                count++;
            }
        }

        uint256[] memory activeRecipes = new uint256[](count);
        uint256 current = 0;
        for(uint i = 0; i < definedRecipeIds.length; i++) {
            if(fusionRecipes[definedRecipeIds[i]].exists) {
                 activeRecipes[current] = definedRecipeIds[i];
                 current++;
            }
        }
        return activeRecipes;
    }

    /**
     * @dev Sets the fee required in Ether for performing a fusion.
     * Requires onlyOwner.
     */
    function setFusionFee(uint256 fee) external onlyOwner {
        uint256 oldFee = _fusionFee;
        _fusionFee = fee;
        emit FusionFeeSet(oldFee, newFee);
    }

    /**
     * @dev Returns the current fusion fee.
     */
    function getFusionFee() public view returns (uint256) {
        return _fusionFee;
    }

    // --- Staking & Utility Functions ---

    /**
     * @dev Allows a token owner to stake their token in the contract.
     * Transfers the token to the contract and records the staker.
     * @param tokenId The ID of the token to stake.
     */
    function stakeToken(uint256 tokenId) external nonpaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        require(stakedTokens[tokenId] == address(0), "Token is already staked");

        // Transfer token to the contract
        safeTransferFrom(msg.sender, address(this), tokenId);

        // Record the staker
        stakedTokens[tokenId] = msg.sender;

        emit TokenStaked(tokenId, msg.sender);
    }

    /**
     * @dev Allows a staker to unstake their token.
     * Transfers the token back to the original staker.
     * @param tokenId The ID of the token to unstake.
     */
    function unstakeToken(uint256 tokenId) external nonpaused {
        require(_exists(tokenId), "Token does not exist");
        require(stakedTokens[tokenId] == msg.sender, "Caller is not the staker of this token");
        require(ownerOf(tokenId) == address(this), "Token is not held by the contract (not staked)");

        address staker = stakedTokens[tokenId];

        // Transfer token back to the staker
        safeTransferFrom(address(this), staker, tokenId);

        // Clear staking info and delegation
        delete stakedTokens[tokenId];
        delete utilityDelegation[tokenId]; // Revoke delegation upon unstaking

        emit TokenUnstaked(tokenId, staker);
        emit UtilityDelegationRevoked(tokenId, staker, address(0)); // Indicate delegation removed
    }

     /**
     * @dev Checks if a token is currently staked.
     * @param tokenId The ID of the token to check.
     * @return bool True if the token is staked, false otherwise.
     */
    function isTokenStaked(uint256 tokenId) public view returns (bool) {
        return stakedTokens[tokenId] != address(0);
    }

    /**
     * @dev Gets the address that staked a specific token.
     * @param tokenId The ID of the token to check.
     * @return address The staker's address, or address(0) if not staked.
     */
    function getStakedBy(uint256 tokenId) public view returns (address) {
        return stakedTokens[tokenId];
    }


    /**
     * @dev Allows the staker of a token to delegate its utility benefits to another address.
     * The staker must be the one who staked the token.
     * @param tokenId The ID of the staked token.
     * @param delegatee The address to delegate utility access to.
     */
    function delegateUtility(uint256 tokenId, address delegatee) external nonpaused {
        require(_exists(tokenId), "Token does not exist");
        require(stakedTokens[tokenId] == msg.sender, "Caller is not the staker of this token");
        require(delegatee != address(0), "Delegatee cannot be the zero address");
        require(delegatee != msg.sender, "Cannot delegate utility to self");

        utilityDelegation[tokenId] = delegatee;

        emit UtilityDelegated(tokenId, msg.sender, delegatee);
    }

    /**
     * @dev Revokes any existing utility delegation for a staked token.
     * Only the staker can revoke delegation.
     * @param tokenId The ID of the staked token.
     */
    function revokeUtilityDelegation(uint256 tokenId) external nonpaused {
        require(_exists(tokenId), "Token does not exist");
        require(stakedTokens[tokenId] == msg.sender, "Caller is not the staker of this token");
        require(utilityDelegation[tokenId] != address(0), "No active utility delegation for this token");

        address delegatee = utilityDelegation[tokenId];
        delete utilityDelegation[tokenId];

        emit UtilityDelegationRevoked(tokenId, msg.sender, delegatee);
    }

     /**
     * @dev Checks if utility of a staked token is delegated to a specific address.
     * @param tokenId The ID of the token.
     * @param delegatee The address to check for delegation.
     * @return bool True if delegated to the address, false otherwise.
     */
    function isUtilityDelegatedTo(uint256 tokenId, address delegatee) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return stakedTokens[tokenId] != address(0) && utilityDelegation[tokenId] == delegatee;
    }

    /**
     * @dev Determines if an address has utility access for a token.
     * Access is granted to the owner, the staker, or the delegated address.
     * @param tokenId The ID of the token to check.
     * @param addr The address to check access for.
     * @return bool True if the address has access, false otherwise.
     */
    function checkAccess(uint256 tokenId, address addr) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        address currentOwner = ownerOf(tokenId);
        address staker = stakedTokens[tokenId];
        address delegatee = utilityDelegation[tokenId];

        return currentOwner == addr || // Is the owner
               staker == addr ||     // Is the staker
               delegatee == addr;     // Is the delegated address
    }


    // --- Dynamic Attributes & Modifiers ---

    /**
     * @dev Applies a temporary or conditional modifier to a specific attribute.
     * Modifiers can be positive or negative and can expire.
     * Requires ATTRIBUTE_MANAGER_ROLE.
     * @param tokenId The ID of the token.
     * @param attributeName The name of the attribute to modify.
     * @param modifierValue The value to add to the base attribute (can be negative).
     * @param expiryTimestamp The timestamp when the modifier expires. Use 0 for a non-expiring modifier (until removed).
     */
    function setAttributeModifier(uint256 tokenId, string memory attributeName, int256 modifierValue, uint256 expiryTimestamp) external onlyRole(ATTRIBUTE_MANAGER_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        if (expiryTimestamp > 0) {
            require(expiryTimestamp > block.timestamp, "Expiry timestamp must be in the future");
        }

        tokenAttributeModifiers[tokenId][attributeName] = AttributeModifier(modifierValue, expiryTimestamp, true);

        emit AttributeModifierSet(tokenId, attributeName, modifierValue, expiryTimestamp);
    }

    /**
     * @dev Removes an attribute modifier from a token.
     * Requires ATTRIBUTE_MANAGER_ROLE.
     * @param tokenId The ID of the token.
     * @param attributeName The name of the attribute whose modifier to remove.
     */
    function removeAttributeModifier(uint256 tokenId, string memory attributeName) external onlyRole(ATTRIBUTE_MANAGER_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        require(tokenAttributeModifiers[tokenId][attributeName].isActive, "No active modifier for this attribute");

        delete tokenAttributeModifiers[tokenId][attributeName]; // Resets to default struct (isActive=false)

        emit AttributeModifierRemoved(tokenId, attributeName);
    }

    /**
     * @dev Retrieves details of an attribute modifier.
     * @param tokenId The ID of the token.
     * @param attributeName The name of the attribute.
     * @return modifierValue The modifier value.
     * @return expiryTimestamp The expiry timestamp.
     * @return isActive True if a modifier is currently active.
     */
    function getAttributeModifier(uint256 tokenId, string memory attributeName) public view returns (int256 modifierValue, uint256 expiryTimestamp, bool isActive) {
        require(_exists(tokenId), "Token does not exist");
        AttributeModifier memory modifierData = tokenAttributeModifiers[tokenId][attributeName];

        // Check if active and not expired
        bool currentActive = modifierData.isActive && (modifierData.expiryTimestamp == 0 || modifierData.expiryTimestamp > block.timestamp);

        return (modifierData.modifierValue, modifierData.expiryTimestamp, currentActive);
    }


    /**
     * @dev Calculates the effective value of an attribute, considering base value and active modifier.
     * @param tokenId The ID of the token.
     * @param attributeName The name of the attribute.
     * @return uint256 The effective attribute value. Returns 0 if token doesn't exist.
     */
    function calculateEffectiveAttribute(uint256 tokenId, string memory attributeName) public view returns (uint256) {
        if (!_exists(tokenId)) {
            return 0; // Or handle error, depending on desired behavior for non-existent tokens
        }

        uint256 baseValue = tokenAttributes[tokenId][attributeName];
        AttributeModifier memory modifierData = tokenAttributeModifiers[tokenId][attributeName];

        // Check if modifier is active and not expired
        bool modifierIsActive = modifierData.isActive && (modifierData.expiryTimestamp == 0 || modifierData.expiryTimestamp > block.timestamp);

        if (modifierIsActive) {
            int256 modifiedValue = int256(baseValue) + modifierData.modifierValue;
             // Ensure the effective value doesn't go below zero
            return modifiedValue > 0 ? uint256(modifiedValue) : 0;
        } else {
            return baseValue;
        }
    }


    // --- Role Management Functions (Custom Simple Implementation) ---

    /**
     * @dev Grants a role to an account.
     * Only the owner can grant roles in this simple implementation.
     */
    function grantRole(string memory roleName, address account) public onlyOwner {
        bytes32 role = keccak256(bytes(roleName));
        require(account != address(0), "Role granted to the zero address");
        require(!_roles[account][role], "Account already has the role");
        _roles[account][role] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Revokes a role from an account.
     * Only the owner can revoke roles. Cannot revoke owner's own roles easily with this structure.
     */
    function revokeRole(string memory roleName, address account) public onlyOwner {
        bytes32 role = keccak256(bytes(roleName));
        require(_roles[account][role], "Account does not have the role");
        // Prevent owner from revoking critical roles from themselves without a plan
        // Simplified: assume owner can revoke any role from anyone, including themselves (use carefully)
        _roles[account][role] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @dev Checks if an account has a role.
     */
    function hasRole(string memory roleName, address account) public view returns (bool) {
        bytes32 role = keccak256(bytes(roleName));
        return _roles[account][role];
    }

    // --- Contract Management Functions ---

    /**
     * @dev Pauses the contract, preventing certain actions.
     * Requires PAUSER_ROLE.
     */
    function pauseContract() external onlyRole(PAUSER_ROLE) {
        require(_contractState != ContractState.Paused, "Contract is already paused");
        _contractState = ContractState.Paused;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing actions again.
     * Requires PAUSER_ROLE.
     */
    function unpauseContract() external onlyRole(PAUSER_ROLE) {
        require(_contractState != ContractState.Active, "Contract is already active");
        _contractState = ContractState.Active;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Gets the current state of the contract (Active or Paused).
     */
    function getContractState() public view returns (ContractState) {
        return _contractState;
    }

    /**
     * @dev Allows the owner to withdraw collected Ether fees.
     * Requires onlyOwner.
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Transfers ownership of the contract.
     * Requires onlyOwner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        // Note: In this simple role system, new owner needs roles granted manually.
        // In a more robust system like OpenZeppelin's Ownable, owner has root role.
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Gets the current contract owner.
     */
    function getOwner() public view returns (address) {
        return _owner;
    }

    // --- IERC721Receiver Interface Implementation ---
    // This allows the contract to receive ERC721 tokens (specifically needed for staking).

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     * This function is called when a token is transferred to the contract via `safeTransferFrom`.
     * Allows us to optionally react to token transfers *into* the contract.
     * We just return the required selector here, assuming we are always willing to receive.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Check if the caller is the ERC721 contract we expect to receive from (optional)
        // require(msg.sender == address(this), "Can only receive from self?"); // Or check against known token contracts

        // Do any logic needed upon receiving a token.
        // For staking, the staking logic is handled in stakeToken, which calls safeTransferFrom.
        // This function is just the receiver hook.
        // The `data` parameter could be used to pass context, e.g., indicating staking intent.

        // Return the selector to indicate successful receipt
        return this.onERC721Received.selector;
    }
}
```

**Explanation of Concepts:**

1.  **Generative Minting (`mintGenerative`):** Instead of a simple counter mint, this function creates new tokens with initial attributes based on inputs including a user-provided seed and (pseudo)random factors derived from block data. **Important:** The randomness here is *not* secure and should not be used for high-value outcomes easily predictable by miners. A production system would integrate with a VRF oracle.
2.  **Dynamic Attributes (`tokenAttributes`, `updateAttribute`, `evolveAttribute`):** Token properties are stored directly on-chain in mappings, allowing them to change after minting. `updateAttribute` is an admin function, while `evolveAttribute` represents an on-chain mechanic (e.g., leveling up, time decay, interaction-based changes) that alters attributes according to predefined rules.
3.  **Attribute Modifiers (`tokenAttributeModifiers`, `setAttributeModifier`, `removeAttributeModifier`, `calculateEffectiveAttribute`):** Introduces temporary buffs or debuffs to attributes. Modifiers have an expiry timestamp and can be positive or negative, affecting the *effective* attribute value used in gameplay or checks, while the base attribute remains untouched. `calculateEffectiveAttribute` provides the final, modified value.
4.  **Fusion System (`defineFusionRecipe`, `performFusion`):** A crafting-like mechanism where users must burn specific input NFTs (or NFTs with certain attributes) to create a new output NFT based on a defined recipe. This creates token sinks, introduces strategic decisions, and allows for complex ecosystem loops. Includes an ETH fee for the process.
5.  **Staking for Utility Delegation (`stakeToken`, `unstakeToken`, `delegateUtility`, `checkAccess`):** Users can stake their NFTs, transferring ownership to the contract temporarily. While staked, they can delegate the *utility* of that token (access rights, in this simple case) to another address. This is different from standard ERC721 approval and allows the staker to retain control while lending benefits. `checkAccess` shows how utility (like accessing a gated feature) could be verified on-chain.
6.  **Custom Role-Based Access Control (`_roles`, `grantRole`, `revokeRole`, `hasRole`, `onlyRole`):** Instead of relying on a standard library like OpenZeppelin's `AccessControl`, a simple mapping-based role system is implemented. This demonstrates the concept without copying the full pattern, allowing for granular permissions (e.g., only MINTER_ROLE can call `mintGenerative`).
7.  **Pausable State (`_contractState`, `pauseContract`, `unpauseContract`, `nonpaused`):** Allows privileged roles to pause certain contract functionalities in case of upgrades, bugs, or maintenance.
8.  **ERC721Receiver Implementation (`onERC721Received`):** Necessary to safely receive NFTs into the contract, particularly for the staking mechanism using `safeTransferFrom`.
9.  **Gas Efficiency Considerations:** While not fully optimized, the design uses mappings for O(1) lookups where possible. Iterating over `definedRecipeIds` in `getAvailableRecipes` is noted as potentially gas-heavy for a very large number of recipes, suggesting alternative data structures for larger scale.

This contract combines several distinct ideas into a single system, providing a base for a game, a generative art platform, or a unique digital asset ecosystem with evolving properties and collaborative utility.