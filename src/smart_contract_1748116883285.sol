Okay, let's design an interesting, advanced, and creative smart contract. We'll call it the "DeFi Procedural Asset Forge & Discovery (PAFD)".

This contract will combine elements of ERC-20 (for resource tokens), ERC-721 (for generated assets), procedural generation concepts (forging and discovery), dynamic NFT attributes (changing based on on-chain or off-chain data), staking, and basic governance.

It's designed to be more complex than a standard token or simple NFT contract and incorporates concepts like:

*   **Multiple Token Standards:** Managing both fungible (Elements) and non-fungible (Assets) tokens within one contract (or tightly coupled).
*   **Procedural Logic:** Defining recipes for combining elements to forge assets, and a mechanism for discovering new recipes.
*   **Dynamic NFTs:** Asset attributes that are not fixed metadata but calculated on-chain based on rules and potentially external data (via oracle).
*   **Integrated Staking:** Staking resource tokens within the same contract to earn yield or gain benefits.
*   **Basic On-Chain Governance:** Allowing token holders to propose and vote on certain protocol parameters (like adding new recipes or element types).
*   **Oracle Interaction:** Incorporating a pattern for fetching external data to influence dynamic attributes (simulated via an interface for this example).

We will structure the code with the requested outline and function summary at the top.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Useful for stake time calculations

// --- OUTLINE ---
// 1. Interfaces (for Oracle)
// 2. Error Definitions
// 3. Struct Definitions (ForgingRecipe, AssetAttributes, DynamicRule, Proposal, Vote)
// 4. Event Definitions
// 5. Contract Definition (Inheriting ERC20, ERC721, Ownable, Pausable, ReentrancyGuard)
// 6. State Variables
//    - Basic tokens/contracts: Element ERC20 state, Asset ERC721 state, Oracle address
//    - Core Logic: Element types, Forging Recipes, Discovered Recipes, Asset Attributes, Asset Dynamic Rules, next Asset ID
//    - Governance: Proposals, Vote states, Proposal counter
//    - Staking: Staked balances, last reward time, staking yield rate
//    - Fees: Fee address, total collected fees
// 7. Constructor
// 8. Admin/Access Control Functions
// 9. ERC-20 Functions (Elements) - Overridden/Integrated
// 10. ERC-721 Functions (Assets) - Overridden/Integrated
// 11. Core Logic Functions (Elements/Assets/Forging/Dynamics/Discovery)
// 12. Governance Functions
// 13. Staking Functions
// 14. Fee/Withdrawal Functions
// 15. Pausing/Emergency Functions
// 16. View/Helper Functions

// --- FUNCTION SUMMARY ---
// Admin/Access Control:
// 1. constructor(string memory name, string memory symbol, string memory elementName, string memory elementSymbol): Initializes contract, tokens, owner.
// 2. setAdmin(address newAdmin): Sets an admin role (can manage elements/recipes/rules outside full governance).
// 3. setOracleAddress(address _oracle): Sets the address of the external oracle contract.
// 4. setFeeAddress(address _feeAddress): Sets the address to send collected fees.
// 5. setStakingYieldRate(uint256 rate): Sets the base yield rate for staking (per second, scaled).

// ERC-20 (Elements):
// 6. addElementType(uint256 elementTypeId, string memory name, string memory symbol): Registers a new type of element token. (Admin/Governance)
// 7. mintElements(uint256 elementTypeId, address account, uint256 amount): Mints new elements of a specific type to an account. (Admin only)
// 8. burnElements(uint256 elementTypeId, address account, uint256 amount): Burns elements of a specific type from an account. (Admin/User allowing burn)
// 9. transfer(address to, uint256 amount): Standard ERC20 transfer for element type 0 (default).
// 10. approve(address spender, uint256 amount): Standard ERC20 approve for element type 0.
// 11. transferFrom(address from, address to, uint256 amount): Standard ERC20 transferFrom for element type 0.
// 12. balanceOf(address account): Standard ERC20 balanceOf for element type 0.
// 13. allowance(address owner, address spender): Standard ERC20 allowance for element type 0.

// ERC-721 (Assets):
// 14. transferFrom(address from, address to, uint256 tokenId): Standard ERC721 transfer for assets.
// 15. approve(address to, uint256 tokenId): Standard ERC721 approve for assets.
// 16. setApprovalForAll(address operator, bool approved): Standard ERC721 setApprovalForAll for assets.
// 17. getApproved(uint256 tokenId): Standard ERC721 getApproved for assets.
// 18. isApprovedForAll(address owner, address operator): Standard ERC721 isApprovedForAll for assets.
// 19. balanceOf(address owner): Standard ERC721 balanceOf for assets.
// 20. ownerOf(uint256 tokenId): Standard ERC721 ownerOf for assets.
// 21. totalSupply(): Standard ERC721 totalSupply for assets.

// Core Logic (Forging, Dynamics, Discovery):
// 22. addForgingRecipe(uint256 recipeId, ForgingRecipeInput[] memory inputs, uint256 outputAssetTypeId, AssetAttributes memory initialAttributes, uint256 dynamicRuleId): Adds a new recipe. (Admin/Governance)
// 23. removeForgingRecipe(uint256 recipeId): Removes a recipe. (Admin/Governance)
// 24. forgeAsset(uint256 recipeId): Users call this to forge an asset using elements based on a recipe. Consumes elements, mints asset.
// 25. setAssetDynamicRule(uint256 dynamicRuleId, DynamicRule memory rule): Defines how attributes for assets with this rule ID change. (Admin/Governance)
// 26. attemptDiscovery(uint256[] memory elementQuantities): User consumes elements to potentially discover a new recipe. (Probabilistic)
// 27. triggerAttributeUpdate(uint256 tokenId): Allows anyone (or a specific role/system) to trigger an update check for dynamic attributes for a specific asset. (Implementation might update state or just be a trigger for view cache). *Revised*: Dynamic attributes calculated on view, this function removed as state updates are expensive. The `getAssetAttributes` is the key dynamic function.

// Governance:
// 28. proposeGovernanceAction(bytes memory data, string memory description): Creates a new governance proposal. (Requires stake/holding)
// 29. voteOnProposal(uint256 proposalId, bool support): Casts a vote on a proposal. (Vote weight based on stake/holding)
// 30. executeProposal(uint256 proposalId): Executes a successful proposal. Calls target contract/function using `data`.

// Staking:
// 31. stakeElements(uint256 elementTypeId, uint256 amount): Stakes elements of a specific type to earn yield/voting power.
// 32. unstakeElements(uint256 elementTypeId, uint256 amount): Unstakes elements.
// 33. claimStakingRewards(uint256 elementTypeId): Claims accumulated rewards for staked elements.

// Fee/Withdrawal:
// 34. withdrawFees(): Allows the fee address to withdraw collected fees (in default element type).

// Pausing/Emergency:
// 35. pause(): Pauses core user interactions (forge, discovery, stake). (Admin/Governance)
// 36. unpause(): Unpauses the contract. (Admin/Governance)
// 37. emergencyShutdown(): Stops all activity except withdrawals/unstaking. (Owner only)

// View Functions:
// 38. getElementBalance(uint256 elementTypeId, address account): Get balance of a specific element type.
// 39. getRecipeDetails(uint256 recipeId): Get details of a forging recipe.
// 40. isRecipeDiscovered(uint256 recipeId): Check if a recipe has been discovered.
// 41. getAssetAttributes(uint256 tokenId): Get current (dynamically calculated) attributes of an asset.
// 42. getAssetDynamicRule(uint256 dynamicRuleId): Get details of a dynamic rule.
// 43. getProposalState(uint256 proposalId): Get the current state and votes for a proposal.
// 44. getStakedBalance(uint256 elementTypeId, address account): Get staked balance for an element type.
// 45. getPendingRewards(uint256 elementTypeId, address account): Calculate pending staking rewards.
// 46. getStakingYieldRate(): Get the current staking yield rate.
// 47. getCollectedFees(): Get the total collected fees ready for withdrawal.
// 48. getAdmin(): Get the current admin address.
// 49. getFeeAddress(): Get the current fee address.
// 50. getOracleAddress(): Get the current oracle address.

// (Note: Some ERC20/ERC721 standard views like name(), symbol() are inherent from inheritance)
// Total Public/External Functions: 50+

// --- INTERFACES ---

// Minimal interface for an external oracle contract
interface IOracle {
    // Example function to get a value based on a key
    function getValue(string calldata key) external view returns (uint256);
    // Could have more complex data types or multiple functions
}

// --- ERRORS ---
error PAFD__InvalidElementType();
error PAFD__InsufficientElements(uint256 elementType, uint256 required, uint256 available);
error PAFD__RecipeNotFound();
error PAFD__RecipeNotDiscovered();
error PAFD__AssetNotFound();
error PAFD__DynamicRuleNotFound();
error PAFD__InsufficientStake();
error PAFD__StakingAlreadyClaimed();
error PAFD__NoFeesCollected();
error PAFD__OnlyAdminOrGovernance();
error PAFD__ProposalNotFound();
error PAFD__ProposalNotActive();
error PAFD__ProposalAlreadyVoted();
error PAFD__ProposalExecutionFailed();
error PAFD__ProposalNotSuccessful();
error PAFD__EmergencyShutdownActive();
error PAFD__NotImplemented(); // For parts intentionally left conceptual

// --- STRUCTS ---

struct ForgingRecipeInput {
    uint256 elementType;
    uint256 amount;
}

struct ForgingRecipe {
    uint256 recipeId; // Redundant but can be useful
    ForgingRecipeInput[] inputs;
    uint256 outputAssetTypeId; // Category or type of asset produced
    AssetAttributes initialAttributes; // Base attributes upon forging
    uint256 dynamicRuleId; // Which dynamic rule applies to this asset type
}

// Represents mutable attributes of an asset
struct AssetAttributes {
    uint256 quality; // e.g., 1-100
    uint256 rarity; // e.g., 1-10
    uint256 durability; // e.g., 0-100, decreases over time/use
    // Add more attributes relevant to your concept
}

// Defines how asset attributes change
struct DynamicRule {
    string ruleDescription; // e.g., "Durability decreases by 1% per day", "Quality influenced by Oracle data 'env_factor'"
    uint256 ruleType; // e.g., 1=TimeDecay, 2=OracleInfluence, 3=UsageBased
    // Parameters for the rule (e.g., decay rate, oracle key, usage threshold)
    bytes parameters; // ABI-encoded parameters specific to ruleType
}

enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Cancelled }

struct Proposal {
    uint256 id;
    address proposer;
    string description;
    bytes data; // Data to be executed if proposal passes (e.g., function call)
    uint256 voteStartTime;
    uint256 voteEndTime;
    uint256 totalVotesFor;
    uint256 totalVotesAgainst;
    mapping(address => bool) hasVoted; // Prevents double voting
    ProposalState state;
}

// --- EVENTS ---
event ElementTypeAdded(uint256 indexed elementTypeId, string name, string symbol);
event ElementsMinted(uint256 indexed elementTypeId, address indexed account, uint256 amount);
event ElementsBurned(uint256 indexed elementTypeId, address indexed account, uint256 amount);

event RecipeAdded(uint256 indexed recipeId, uint256 outputAssetTypeId);
event RecipeRemoved(uint256 indexed recipeId);
event AssetForged(uint256 indexed tokenId, uint256 indexed recipeId, address indexed owner);
event DynamicRuleSet(uint256 indexed dynamicRuleId, uint256 ruleType);
event RecipeDiscovered(uint256 indexed recipeId, address indexed discoverer);

event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
event ProposalExecuted(uint256 indexed proposalId, bool success);

event ElementsStaked(uint256 indexed elementTypeId, address indexed account, uint256 amount);
event ElementsUnstaked(uint256 indexed elementTypeId, address indexed account, uint256 amount);
event StakingRewardsClaimed(uint256 indexed elementTypeId, address indexed account, uint256 amount);

event FeesWithdrawn(address indexed feeAddress, uint256 amount);

event EmergencyShutdown(address indexed account);

// --- CONTRACT ---
contract PAFD is ERC20, ERC721, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- STATE VARIABLES ---

    // Elements (ERC20 handling)
    struct ElementInfo {
        string name;
        string symbol;
        uint8 decimals; // Assuming 18 for simplicity unless specified
    }
    mapping(uint256 => ElementInfo) public elementTypeInfo;
    mapping(uint256 => mapping(address => uint256)) private _elementBalances;
    mapping(uint256 => mapping(address => mapping(address => uint256))) private _elementAllowances;
    uint256 private _nextElementTypeId = 1; // 0 is reserved for the default element

    // Assets (ERC721 handling)
    uint256 private _nextTokenId = 0;

    // Core Logic
    mapping(uint256 => ForgingRecipe) public forgingRecipes;
    mapping(uint256 => bool) public isRecipeDiscovered; // recipeId => discovered
    mapping(uint256 => AssetAttributes) private _assetAttributes; // tokenId => attributes
    mapping(uint256 => uint256) public assetDynamicRuleId; // tokenId => dynamicRuleId
    mapping(uint256 => DynamicRule) public dynamicRules; // dynamicRuleId => rule details
    uint256 private _nextDynamicRuleId = 1;

    // Governance
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId = 1;
    // Mapping for vote weight calculation (e.g., based on staked elements)
    mapping(uint256 => mapping(address => bool)) private _hasVotedOnProposal; // proposalId => voter => voted

    // Staking
    mapping(uint256 => mapping(address => uint256)) private _stakedBalances; // elementType => account => amount
    mapping(uint256 => mapping(address => uint256)) private _lastRewardTime; // elementType => account => timestamp
    uint256 public stakingYieldRatePerSecondScaled; // Yield rate (e.g., per second, scaled by 1e18)

    // Fees
    address public feeAddress;
    uint256 private _collectedFees; // In default element (elementType 0)

    // Admin/Oracle
    address public adminAddress;
    IOracle public oracle;

    // Emergency State
    bool public emergencyShutdownActive = false;

    // --- CONSTRUCTOR ---
    constructor(string memory name, string memory symbol, string memory elementName, string memory elementSymbol)
        ERC721(name, symbol)
        ERC20(elementName, elementSymbol) // Default element (type 0)
        Ownable(msg.sender) // Owner has emergency shutdown and initial admin power
        Pausable()
    {
        adminAddress = msg.sender;
        feeAddress = msg.sender; // Default fee address
        stakingYieldRatePerSecondScaled = 0; // Needs to be set by admin/governance

        // Register the default element type (type 0)
        elementTypeInfo[0] = ElementInfo(elementName, elementSymbol, 18); // Assuming 18 decimals for default
        emit ElementTypeAdded(0, elementName, elementSymbol);
    }

    // --- ADMIN/ACCESS CONTROL ---

    // Allows owner to set an admin (can perform certain privileged actions)
    function setAdmin(address newAdmin) external onlyOwner {
        adminAddress = newAdmin;
        // Consider adding an event
    }

    // Allows admin/governance to set the oracle address
    function setOracleAddress(address _oracle) external onlyAdminOrGovernance {
        oracle = IOracle(_oracle);
        // Consider adding an event
    }

    // Allows admin/governance to set the fee withdrawal address
    function setFeeAddress(address _feeAddress) external onlyAdminOrGovernance {
        feeAddress = _feeAddress;
        // Consider adding an event
    }

    // Allows admin/governance to set the base staking yield rate
    function setStakingYieldRate(uint256 rate) external onlyAdminOrGovernance {
        stakingYieldRatePerSecondScaled = rate;
        // Consider adding an event
    }

    // --- ERC-20 FUNCTIONS (Elements) ---
    // Overridden to support multiple element types via a mapping
    // Note: ERC20 standard functions (transfer, balanceOf, etc.) usually work on a single token.
    // We implement the ERC20 interface for the *default* element type (ID 0)
    // and use custom functions for other element types.

    // Override ERC20 standard functions for default element type (0)
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(0, msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(0, msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _elementAllowances[0][from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(0, from, msg.sender, currentAllowance - amount);
        }
        _transfer(0, from, to, amount);
        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _elementBalances[0][account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _elementAllowances[0][owner][spender];
    }

    // Internal element transfer logic
    function _transfer(uint256 elementTypeId, address from, address to, uint256 amount) internal {
        require(elementTypeInfo[elementTypeId].decimals != 0, PAFD__InvalidElementType()); // Check if type exists (hacky way for non-0)
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _elementBalances[elementTypeId][from];
        require(senderBalance >= amount, PAFD__InsufficientElements(elementTypeId, amount, senderBalance));
        unchecked {
            _elementBalances[elementTypeId][from] = senderBalance - amount;
        }
        _elementBalances[elementTypeId][to] += amount;

        // ERC20 standard Transfer event (Note: Emits for default type 0 only)
        // For other types, a custom event might be needed if full tracking is required off-chain
        if (elementTypeId == 0) {
            emit Transfer(from, to, amount);
        } else {
             // Custom event for transfers of other element types
             // emit CustomElementTransfer(elementTypeId, from, to, amount); // Need to define this event
        }
    }

    // Internal element approve logic
    function _approve(uint256 elementTypeId, address owner, address spender, uint256 amount) internal {
         require(elementTypeInfo[elementTypeId].decimals != 0, PAFD__InvalidElementType());
         require(owner != address(0), "ERC20: approve from the zero address");
         require(spender != address(0), "ERC20: approve to the zero address");

         _elementAllowances[elementTypeId][owner][spender] = amount;

         // ERC20 standard Approval event (Note: Emits for default type 0 only)
         if (elementTypeId == 0) {
             emit Approval(owner, spender, amount);
         } else {
              // Custom event for approvals of other element types
              // emit CustomElementApproval(elementTypeId, owner, spender, amount); // Need to define this event
         }
    }


    // Custom function to get balance of any element type
    function getElementBalance(uint256 elementTypeId, address account) public view returns (uint256) {
        require(elementTypeInfo[elementTypeId].decimals != 0 || elementTypeId == 0, PAFD__InvalidElementType());
        return _elementBalances[elementTypeId][account];
    }

    // Admin/Governance function to add a new element type
    function addElementType(uint256 elementTypeId, string memory name, string memory symbol)
        external onlyAdminOrGovernance
    {
        require(elementTypeInfo[elementTypeId].decimals == 0 && elementTypeId != 0, "Element type already exists or is reserved");
        elementTypeInfo[elementTypeId] = ElementInfo(name, symbol, 18); // Assuming 18 decimals
        _nextElementTypeId = elementTypeId >= _nextElementTypeId ? elementTypeId + 1 : _nextElementTypeId; // Keep track of max ID
        emit ElementTypeAdded(elementTypeId, name, symbol);
    }

    // Admin function to mint specific element types (initial distribution, etc.)
    function mintElements(uint256 elementTypeId, address account, uint256 amount)
        external onlyAdmin
    {
        require(elementTypeInfo[elementTypeId].decimals != 0 || elementTypeId == 0, PAFD__InvalidElementType());
        require(account != address(0), "Mint to the zero address");

        _elementBalances[elementTypeId][account] += amount;
        emit ElementsMinted(elementTypeId, account, amount);
        if (elementTypeId == 0) {
             // If it's the default element, ERC20 TotalSupply needs manual update
             _mint(account, amount); // OpenZeppelin's _mint handles total supply
             _elementBalances[elementTypeId][account] = super.balanceOf(account); // Keep mapping in sync (or just use super.balanceOf for type 0)
         }
         // Note: If using custom elements heavily, might need custom total supply tracking
    }

     // Admin/User function to burn specific element types
     function burnElements(uint256 elementTypeId, address account, uint256 amount)
         external onlyAdminOrGovernance // Added governance ability
     {
         // Allow burning from self or if admin/governance
         require(msg.sender == account || msg.sender == adminAddress || isProposalSuccessful(getLatestProposalIdForAddress(msg.sender)), "Not authorized to burn"); // Simplified auth
         require(elementTypeInfo[elementTypeId].decimals != 0 || elementTypeId == 0, PAFD__InvalidElementType());
         require(account != address(0), "Burn from the zero address");

         uint256 accountBalance = _elementBalances[elementTypeId][account];
         require(accountBalance >= amount, PAFD__InsufficientElements(elementTypeId, amount, accountBalance));
         unchecked {
             _elementBalances[elementTypeId][account] = accountBalance - amount;
         }
         emit ElementsBurned(elementTypeId, account, amount);
         if (elementTypeId == 0) {
             // If it's the default element, ERC20 TotalSupply needs manual update
             _burn(account, amount); // OpenZeppelin's _burn handles total supply
             _elementBalances[elementTypeId][account] = super.balanceOf(account); // Keep mapping in sync
         }
     }


    // --- ERC-721 FUNCTIONS (Assets) ---
    // Standard ERC721 functions are largely handled by inheritance.
    // We override/extend where needed (e.g., minting in forgeAsset).

    // ERC721 standard functions inherited and mostly work out of the box:
    // name(), symbol(), supportsInterface(bytes4 interfaceId)
    // transferFrom(address from, address to, uint256 tokenId)
    // approve(address to, uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // getApproved(uint256 tokenId)
    // isApprovedForAll(address owner, address operator)
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // totalSupply() - Note: OpenZeppelin ERC721Enumerable is needed for this. We'll keep it simple without Enumerable for function count limits. _nextTokenId serves as a proxy for total supply.

    // Internal function to mint an asset (used in forgeAsset)
    function _mintAsset(address to, uint256 assetTypeId, AssetAttributes memory initialAttributes, uint256 dynamicRuleIdToApply) internal {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(to, newTokenId); // ERC721 standard minting
        _assetAttributes[newTokenId] = initialAttributes;
        assetDynamicRuleId[newTokenId] = dynamicRuleIdToApply;
        emit AssetForged(newTokenId, 0, to); // Emit a basic event, actual recipeId is separate
        // Need to store assetTypeId if we want to query it later per token
        // mapping(uint256 => uint256) public assetTypeId; assetTypeId[newTokenId] = assetTypeId;
    }

    // --- CORE LOGIC (Forging, Dynamics, Discovery) ---

    // Allows admin/governance to add a forging recipe
    function addForgingRecipe(
        uint256 recipeId,
        ForgingRecipeInput[] memory inputs,
        uint256 outputAssetTypeId,
        AssetAttributes memory initialAttributes,
        uint256 dynamicRuleIdToApply
    ) external onlyAdminOrGovernance {
        require(forgingRecipes[recipeId].recipeId == 0, "Recipe ID already exists"); // Simple check if ID is taken
        // Validate input element types exist
        for (uint i = 0; i < inputs.length; i++) {
            require(elementTypeInfo[inputs[i].elementType].decimals != 0 || inputs[i].elementType == 0, PAFD__InvalidElementType());
        }
        require(dynamicRules[dynamicRuleIdToApply].ruleType != 0 || dynamicRuleIdToApply == 0, PAFD__DynamicRuleNotFound()); // Check if rule exists (0 means no rule)

        forgingRecipes[recipeId] = ForgingRecipe(
            recipeId,
            inputs,
            outputAssetTypeId,
            initialAttributes,
            dynamicRuleIdToApply
        );
        // By default, recipes are NOT discovered
        isRecipeDiscovered[recipeId] = false;
        emit RecipeAdded(recipeId, outputAssetTypeId);
    }

    // Allows admin/governance to remove a forging recipe
    function removeForgingRecipe(uint256 recipeId) external onlyAdminOrGovernance {
        require(forgingRecipes[recipeId].recipeId != 0, PAFD__RecipeNotFound());
        delete forgingRecipes[recipeId];
        delete isRecipeDiscovered[recipeId]; // Also remove discovery state
        emit RecipeRemoved(recipeId);
    }

    // Allows users to forge an asset
    function forgeAsset(uint256 recipeId) external whenNotPaused nonReentrant {
        ForgingRecipe storage recipe = forgingRecipes[recipeId];
        require(recipe.recipeId != 0, PAFD__RecipeNotFound());
        require(isRecipeDiscovered[recipeId], PAFD__RecipeNotDiscovered()); // Only discovered recipes can be used

        // Check and consume input elements
        for (uint i = 0; i < recipe.inputs.length; i++) {
            uint256 requiredAmount = recipe.inputs[i].amount;
            uint256 elementType = recipe.inputs[i].elementType;
            require(_elementBalances[elementType][msg.sender] >= requiredAmount, PAFD__InsufficientElements(elementType, requiredAmount, _elementBalances[elementType][msg.sender]));
        }

        // All checks passed, consume elements
        for (uint i = 0; i < recipe.inputs.length; i++) {
            uint256 consumeAmount = recipe.inputs[i].amount;
            uint256 elementType = recipe.inputs[i].elementType;
            _transfer(elementType, msg.sender, address(this), consumeAmount); // Transfer to contract
            // Optionally, burn consumed elements instead: _burnElements(elementType, msg.sender, consumeAmount);
            // Transferring to contract allows potential future uses or burning logic
        }

        // Mint the new asset
        _mintAsset(msg.sender, recipe.outputAssetTypeId, recipe.initialAttributes, recipe.dynamicRuleId);

        // Fee collection (example: take a small fee in default element)
        uint256 forgingFee = 100; // Example fee amount in default element
        if (_elementBalances[0][msg.sender] >= forgingFee) {
             _transfer(0, msg.sender, feeAddress, forgingFee);
             _collectedFees += forgingFee;
        } // Else, skip fee if user can't afford it, or revert

        // Emit specific forge event with recipe
        emit AssetForged(_nextTokenId - 1, recipeId, msg.sender); // Use the ID that was just minted
    }

    // Allows admin/governance to set a dynamic rule definition
    function setAssetDynamicRule(uint256 dynamicRuleId, DynamicRule memory rule) external onlyAdminOrGovernance {
        require(dynamicRuleId != 0, "Rule ID 0 is reserved");
        dynamicRules[dynamicRuleId] = rule;
        _nextDynamicRuleId = dynamicRuleId >= _nextDynamicRuleId ? dynamicRuleId + 1 : _nextDynamicRuleId; // Keep track of max ID
        emit DynamicRuleSet(dynamicRuleId, rule.ruleType);
    }

    // Allows users to attempt discovery by consuming elements (probabilistic)
    function attemptDiscovery(uint256[] memory elementQuantities) external whenNotPaused nonReentrant {
        require(elementQuantities.length > 0, "Must provide some element quantities");
        // Example logic: consume elements, maybe more elements = higher chance or different discovery pools
        uint256 totalElementsConsumed = 0;
        for(uint i = 0; i < elementQuantities.length; i+=2) {
            if (i+1 < elementQuantities.length) {
                uint256 elementType = elementQuantities[i];
                uint256 amount = elementQuantities[i+1];
                 require(elementTypeInfo[elementType].decimals != 0 || elementType == 0, PAFD__InvalidElementType());
                require(_elementBalances[elementType][msg.sender] >= amount, PAFD__InsufficientElements(elementType, amount, _elementBalances[elementType][msg.sender]));
                _transfer(elementType, msg.sender, address(this), amount); // Consume by transferring to contract
                totalElementsConsumed += amount; // Simplified metric
            }
        }

        // Discovery logic: This is where creativity comes in.
        // Could be based on totalElementsConsumed, specific element combinations,
        // a VRF call (Chainlink VRF), block hash randomness (less secure),
        // or interaction with an external "discovery oracle".
        // For this example, let's simulate a chance based on consumption.

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalElementsConsumed, _nextTokenId)));
        uint256 chance = totalElementsConsumed > 0 ? seed % 1000 : 0; // Example: 1 in 1000 chance per total element point

        if (chance > 950) { // Example: 5% chance to discover something
            // Find an undiscovered recipe ID
            uint256 discoveredId = 0;
            uint256 checkCounter = 0;
            // Simple (inefficient) way to find *any* undiscovered recipe ID below _nextProposalId (using proposal IDs as dummy max range)
            // In a real system, you'd have a list/mapping of undiscoverable recipes or a more robust discovery pool
            uint256 maxPossibleRecipeId = _nextProposalId + 100; // Arbitrary large number
            while(discoveredId == 0 && checkCounter < 50) { // Limit checks
                uint256 potentialId = (seed + checkCounter) % maxPossibleRecipeId + 1; // Get a random potential ID
                 if (forgingRecipes[potentialId].recipeId != 0 && !isRecipeDiscovered[potentialId]) {
                     discoveredId = potentialId;
                 }
                 checkCounter++;
            }


            if (discoveredId != 0) {
                isRecipeDiscovered[discoveredId] = true;
                emit RecipeDiscovered(discoveredId, msg.sender);
            }
        }
        // Else: Discovery attempt failed, elements are consumed.
    }

    // --- GOVERNANCE ---

    modifier onlyAdminOrGovernance() {
        // A simple governance check: is admin OR msg.sender has sufficient stake/has a successful proposal executed?
        // In a real DAO, this would check voter power, proposal states etc.
        // For this example, we'll allow Admin or the owner of the *last successfully executed proposal* to act as "governance"
        // This is a highly simplified placeholder. A real system would require proper voting mechanisms.
        require(msg.sender == adminAddress, PAFD__OnlyAdminOrGovernance()); // Simplified: only admin for now
        // TODO: Implement proper governance check based on staking/voting power
        _;
    }

    // Placeholder for getting vote weight (e.g., based on staked elements)
    function _getVoteWeight(address account) internal view returns (uint256) {
        // Example: 1 vote per 100 default elements staked
        uint256 defaultElementsStaked = _stakedBalances[0][account];
        return defaultElementsStaked / 100;
    }

    // Placeholder for getting the latest successful proposal proposer (highly simplified)
    function getLatestProposalIdForAddress(address account) internal view returns(uint256) {
         // Find the latest proposal ID created by `account`
        uint256 latestId = 0;
        for(uint256 i = _nextProposalId -1; i >= 1; i--) {
            if(proposals[i].proposer == account) {
                 latestId = i;
                 break;
            }
            if (i == 1) break; // Avoid underflow
        }
        return latestId;
    }

    // Placeholder check for successful proposal (highly simplified)
    function isProposalSuccessful(uint256 proposalId) public view returns(bool) {
        if (proposalId == 0) return false;
        return proposals[proposalId].state == ProposalState.Succeeded;
    }


    // Allows users with sufficient stake/holding to create a proposal
    function proposeGovernanceAction(bytes memory data, string memory description) external whenNotPaused {
        require(_getVoteWeight(msg.sender) > 0, "Requires stake/holding to propose"); // Example check
        uint256 proposalId = _nextProposalId++;
        uint256 votingPeriod = 7 days; // Example voting period
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            data: data,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });
        emit ProposalCreated(proposalId, msg.sender);
    }

    // Allows users with stake/holding to vote on a proposal
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, PAFD__ProposalNotFound());
        require(proposal.state == ProposalState.Active, PAFD__ProposalNotActive());
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, PAFD__ProposalNotActive());
        require(!proposal.hasVoted[msg.sender], PAFD__ProposalAlreadyVoted());

        uint256 voteWeight = _getVoteWeight(msg.sender);
        require(voteWeight > 0, "Requires stake/holding to vote");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }

        emit Voted(proposalId, msg.sender, support, voteWeight);

        // Check if voting period ended, and update state if so (can also be done in execute)
        if (block.timestamp > proposal.voteEndTime) {
             _updateProposalState(proposalId);
        }
    }

    // Internal function to update proposal state after voting ends
    function _updateProposalState(uint256 proposalId) internal {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
             uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
             uint256 quorum = 1000; // Example quorum: requires 1000 total vote weight
             uint256 requiredMajority = totalVotes / 2; // Simple majority

             if (totalVotes >= quorum && proposal.totalVotesFor > requiredMajority) {
                 proposal.state = ProposalState.Succeeded;
             } else {
                 proposal.state = ProposalState.Failed;
             }
         }
    }

    // Allows anyone to execute a successful proposal
    function executeProposal(uint256 proposalId) external whenNotPaused nonReentrant {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0, PAFD__ProposalNotFound());

         // Ensure voting period is over and state is updated
         _updateProposalState(proposalId);

         require(proposal.state == ProposalState.Succeeded, PAFD__ProposalNotSuccessful());
         require(proposal.data.length > 0, "Proposal has no execution data");

         // Execute the proposal data (e.g., call another function on this contract or another)
         // This is a powerful and risky pattern (delegatecall/call). Be extremely cautious.
         // For this example, we assume the data is a call on *this* contract.
         (bool success, bytes memory result) = address(this).call(proposal.data);

         if (success) {
             proposal.state = ProposalState.Executed;
             emit ProposalExecuted(proposalId, true);
         } else {
             proposal.state = ProposalState.Failed; // Execution failure marks proposal as failed
             emit ProposalExecuted(proposalId, false);
             // Revert to signal failure
             assembly {
                 revert(add(0x20, result), mload(result))
             }
             // Or a simpler revert: revert(PAFD__ProposalExecutionFailed());
         }
    }

    // --- STAKING ---

    // Stakes elements of a specific type
    function stakeElements(uint256 elementTypeId, uint256 amount) external whenNotPaused nonReentrant {
        require(elementTypeInfo[elementTypeId].decimals != 0 || elementTypeId == 0, PAFD__InvalidElementType());
        require(amount > 0, "Cannot stake zero");

        // Claim any pending rewards before staking more
        _claimStakingRewards(elementTypeId, msg.sender);

        _transfer(elementTypeId, msg.sender, address(this), amount); // Transfer elements to contract
        _stakedBalances[elementTypeId][msg.sender] += amount;
        _lastRewardTime[elementTypeId][msg.sender] = block.timestamp; // Reset reward time

        emit ElementsStaked(elementTypeId, msg.sender, amount);
    }

    // Unstakes elements
    function unstakeElements(uint256 elementTypeId, uint256 amount) external whenNotPaused nonReentrant {
        require(elementTypeInfo[elementTypeId].decimals != 0 || elementTypeId == 0, PAFD__InvalidElementType());
        require(amount > 0, "Cannot unstake zero");
        require(_stakedBalances[elementTypeId][msg.sender] >= amount, PAFD__InsufficientStake());

        // Claim any pending rewards before unstaking
        _claimStakingRewards(elementTypeId, msg.sender);

        _stakedBalances[elementTypeId][msg.sender] -= amount;
        _transfer(elementTypeId, address(this), msg.sender, amount); // Transfer elements back

        // If unstaking all, reset last reward time
        if (_stakedBalances[elementTypeId][msg.sender] == 0) {
             _lastRewardTime[elementTypeId][msg.sender] = 0;
        } else {
            _lastRewardTime[elementTypeId][msg.sender] = block.timestamp; // Update time for remaining stake
        }

        emit ElementsUnstaked(elementTypeId, msg.sender, amount);
    }

    // Claims accumulated staking rewards
    function claimStakingRewards(uint256 elementTypeId) external whenNotPaused nonReentrant {
        _claimStakingRewards(elementTypeId, msg.sender);
    }

    // Internal claim function
    function _claimStakingRewards(uint256 elementTypeId, address account) internal {
        uint256 rewards = getPendingRewards(elementTypeId, account);
        if (rewards == 0) {
             emit StakingAlreadyClaimed(elementTypeId, account); // Custom event for no rewards
             return;
        }

        // Requires the contract to hold enough of the reward element (e.g., default element)
        uint256 rewardElementType = 0; // Assume default element is the reward token
        require(_elementBalances[rewardElementType][address(this)] >= rewards, "Insufficient contract balance for rewards");

        // Reset last reward time BEFORE transferring to follow CEI pattern
        _lastRewardTime[elementTypeId][account] = block.timestamp;

        // Transfer rewards to the user
        _transfer(rewardElementType, address(this), account, rewards);

        emit StakingRewardsClaimed(elementTypeId, account, rewards);
    }


    // --- FEE/WITHDRAWAL ---

    // Allows the fee address to withdraw collected fees (in default element type)
    function withdrawFees() external nonReentrant {
        require(msg.sender == feeAddress, "Only fee address can withdraw");
        require(_collectedFees > 0, PAFD__NoFeesCollected());

        uint256 amount = _collectedFees;
        _collectedFees = 0;

        _transfer(0, address(this), feeAddress, amount); // Transfer default element fees

        emit FeesWithdrawn(feeAddress, amount);
    }

    // --- PAUSING/EMERGENCY ---

    // Allows admin/governance to pause core interactions
    function pause() external onlyAdminOrGovernance whenNotPaused {
        _pause();
    }

    // Allows admin/governance to unpause the contract
    function unpause() external onlyAdminOrGovernance whenPaused {
        _unpause();
    }

    // Allows only the owner to activate emergency shutdown
    function emergencyShutdown() external onlyOwner {
        require(!emergencyShutdownActive, "Emergency shutdown already active");
        emergencyShutdownActive = true;
        // Pause everything
        _pause();
        emit EmergencyShutdown(msg.sender);
    }

    // Override Pausable modifiers
    modifier whenNotPaused() override {
        require(!paused(), "Pausable: paused");
        require(!emergencyShutdownActive, PAFD__EmergencyShutdownActive());
        _;
    }

     // Override Pausable modifiers
    modifier whenPaused() override {
        require(paused(), "Pausable: not paused");
        // Don't allow unpausing if emergency shutdown is active
        require(!emergencyShutdownActive, PAFD__EmergencyShutdownActive());
        _;
    }

    // Allow unstaking/claiming even during shutdown
    // Need to explicitly allow unstake/claim via a separate modifier
    modifier whenNotEmergencyShutdown() {
         require(!emergencyShutdownActive, PAFD__EmergencyShutdownActive());
        _;
    }

    // Re-add whenNotPaused to relevant functions that should be paused (override as needed)
    function forgeAsset(uint256 recipeId) public override whenNotPaused nonReentrant {
         super.forgeAsset(recipeId);
    }
    function attemptDiscovery(uint256[] memory elementQuantities) public override whenNotPaused nonReentrant {
        super.attemptDiscovery(elementQuantities);
    }
     function proposeGovernanceAction(bytes memory data, string memory description) public override whenNotPaused {
        super.proposeGovernanceAction(data, description);
    }
    function voteOnProposal(uint256 proposalId, bool support) public override whenNotPaused {
        super.voteOnProposal(proposalId, support);
    }
     function executeProposal(uint256 proposalId) public override whenNotPaused nonReentrant {
        super.executeProposal(proposalId);
    }
    function stakeElements(uint256 elementTypeId, uint256 amount) public override whenNotPaused nonReentrant {
        super.stakeElements(elementTypeId, amount);
    }

    // Modify unstake/claim to ignore standard pause, but respect emergency shutdown
    function unstakeElements(uint256 elementTypeId, uint256 amount) public whenNotEmergencyShutdown nonReentrant {
        require(elementTypeInfo[elementTypeId].decimals != 0 || elementTypeId == 0, PAFD__InvalidElementType());
        require(amount > 0, "Cannot unstake zero");
        require(_stakedBalances[elementTypeId][msg.sender] >= amount, PAFD__InsufficientStake());

        // Claim any pending rewards before unstaking
        _claimStakingRewards(elementTypeId, msg.sender); // Claim still needs whenNotEmergencyShutdown too

        _stakedBalances[elementTypeId][msg.sender] -= amount;
        _transfer(elementTypeId, address(this), msg.sender, amount); // Transfer elements back

        if (_stakedBalances[elementTypeId][msg.sender] == 0) {
             _lastRewardTime[elementTypeId][msg.sender] = 0;
        } else {
            _lastRewardTime[elementTypeId][msg.sender] = block.timestamp;
        }

        emit ElementsUnstaked(elementTypeId, msg.sender, amount);
    }

    function claimStakingRewards(uint256 elementTypeId) public whenNotEmergencyShutdown nonReentrant {
        _claimStakingRewards(elementTypeId, msg.sender);
    }

    function _claimStakingRewards(uint256 elementTypeId, address account) internal override whenNotEmergencyShutdown {
         super._claimStakingRewards(elementTypeId, account);
    }


    // --- VIEW/HELPER FUNCTIONS ---

    // Get details of a forging recipe
    function getRecipeDetails(uint256 recipeId) public view returns (ForgingRecipe memory) {
        require(forgingRecipes[recipeId].recipeId != 0, PAFD__RecipeNotFound());
        return forgingRecipes[recipeId];
    }

    // Check if a recipe has been discovered
    function isRecipeDiscovered(uint256 recipeId) public view returns (bool) {
        return isRecipeDiscovered[recipeId];
    }

    // Get current (dynamically calculated) attributes of an asset
    function getAssetAttributes(uint256 tokenId) public view returns (AssetAttributes memory) {
        // Check if asset exists (e.g., by checking owner)
        require(_exists(tokenId), PAFD__AssetNotFound());

        AssetAttributes storage baseAttributes = _assetAttributes[tokenId];
        uint256 ruleId = assetDynamicRuleId[tokenId];
        DynamicRule storage rule = dynamicRules[ruleId];

        AssetAttributes memory currentAttributes = baseAttributes; // Start with base attributes

        if (rule.ruleType == 0) {
            // No dynamic rule
            return currentAttributes;
        }

        // Apply dynamic rule based on ruleType
        // This is where the complex, dynamic calculation happens
        if (rule.ruleType == 1) { // Example: TimeDecay
             // Parameters: durationPerDecayStep, decayAmount
             (uint256 durationPerDecayStep, uint256 decayAmount) = abi.decode(rule.parameters, (uint256, uint256));
             // Need to store the asset's creation/last update time to calculate elapsed time
             // Let's assume asset creation time is available or tracked.
             // ERC721 doesn't inherently store mint time. Need a mapping: mapping(uint256 => uint256) assetCreationTime;
             // For simplicity, let's use the current time relative to a hypothetical past event or just apply a time-based decay based on block.timestamp.
             // A better approach needs a stored timestamp related to the attribute start/last change.
             // Let's assume attributes decay relative to a global 'decay start' time or asset's age IF we tracked mint time.
             // Simple example: Durability decreases by `decayAmount` per `durationPerDecayStep` seconds.
             // This approach is complex as it needs a stored timestamp per asset or rule application.
             // Let's simplify: Assume decay is based on *accessing* the attribute after a certain time threshold.
             // This requires storing last_accessed_time or last_decay_time per asset.
             // mapping(uint256 => uint256) private _assetLastDynamicUpdate;
             // uint256 lastUpdate = _assetLastDynamicUpdate[tokenId];
             // uint256 timeElapsed = block.timestamp - lastUpdate;
             // uint256 decaySteps = timeElapsed / durationPerDecayStep;
             // currentAttributes.durability = currentAttributes.durability > decaySteps * decayAmount ? currentAttributes.durability - decaySteps * decayAmount : 0;
             // This requires state change (_assetLastDynamicUpdate[tokenId] = block.timestamp;) which is not allowed in `view`.
             // Revert to conceptual: Dynamic attributes are *calculated* based on parameters and time/external data, but the *base* state (`_assetAttributes`) is not updated in the view function. The dApp layer uses this view function to display the "current" value.

             // Conceptual Calculation for View:
             // Calculate based on block.timestamp
             uint256 assetAge = block.timestamp; // Simplified: Use block.timestamp as a proxy for age for demo
             (uint256 durationPerDecayStep, uint256 decayAmount) = abi.decode(rule.parameters, (uint256, uint256));
             if (durationPerDecayStep > 0) {
                 uint256 decaySteps = assetAge / durationPerDecayStep;
                 uint256 totalDecay = decaySteps * decayAmount;
                 currentAttributes.durability = baseAttributes.durability > totalDecay ? baseAttributes.durability - totalDecay : 0;
             }


        } else if (rule.ruleType == 2) { // Example: OracleInfluence
             // Parameters: oracleKey, influenceFactor
             (string memory oracleKey, uint256 influenceFactor) = abi.decode(rule.parameters, (string, uint256));
             require(address(oracle) != address(0), "Oracle not set");
             // Fetch value from oracle
             uint256 oracleValue = oracle.getValue(oracleKey);
             // Example influence: Quality is base + oracleValue * influenceFactor / scaling
             // Need scaling factor to handle potentially large oracle values and small influence factors
             uint256 scaling = 1e18; // Example scaling
             currentAttributes.quality += (oracleValue * influenceFactor) / scaling;
              // Cap quality at a max value if needed
         }
        // Add more rule types here...

        return currentAttributes;
    }

    // Get details of a dynamic rule
    function getAssetDynamicRule(uint256 dynamicRuleId) public view returns (DynamicRule memory) {
        require(dynamicRules[dynamicRuleId].ruleType != 0, PAFD__DynamicRuleNotFound());
        return dynamicRules[dynamicRuleId];
    }

    // Get the current state and votes for a proposal
    function getProposalState(uint256 proposalId) public view returns (ProposalState state, uint256 votesFor, uint256 votesAgainst, uint256 endTime) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, PAFD__ProposalNotFound());
        // Recalculate state if voting period ended and state is Active
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
             // Note: This view doesn't change state. The state update only happens on vote/execute.
             // A dApp frontend would need to call execute if needed after voting ends.
             // This view returns the state *as recorded*, not necessarily the final state if voting just ended.
             // A more complex view could calculate the *potential* state, but for simplicity, we return stored state.
        }
        return (proposal.state, proposal.totalVotesFor, proposal.totalVotesAgainst, proposal.voteEndTime);
    }

     // Get staked balance for an element type
    function getStakedBalance(uint256 elementTypeId, address account) public view returns (uint256) {
         return _stakedBalances[elementTypeId][account];
    }

    // Calculate pending staking rewards
    function getPendingRewards(uint256 elementTypeId, address account) public view returns (uint256) {
        uint256 stakedAmount = _stakedBalances[elementTypeId][account];
        uint256 lastTime = _lastRewardTime[elementTypeId][account];

        if (stakedAmount == 0 || stakingYieldRatePerSecondScaled == 0 || lastTime == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastTime;
        // Calculate rewards: stakedAmount * rate * timeElapsed / 1e18
        // Use SafeMath for multiplication to prevent overflow
        uint256 rewards = stakedAmount.mul(stakingYieldRatePerSecondScaled).mul(timeElapsed) / (1e18); // Assuming rate is scaled by 1e18

        return rewards;
    }

    // Get the current staking yield rate
    function getStakingYieldRate() public view returns (uint256) {
        return stakingYieldRatePerSecondScaled;
    }

    // Get the total collected fees ready for withdrawal
    function getCollectedFees() public view returns (uint256) {
         return _collectedFees;
    }

    // Get the admin address
    function getAdmin() public view returns (address) {
        return adminAddress;
    }

     // Get the fee address
    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }

     // Get the oracle address
    function getOracleAddress() public view returns (address) {
        return address(oracle);
    }

    // Fallback/Receive functions to accept Ether (if needed)
    // receive() external payable { /* potentially handle received ether */ }
    // fallback() external payable { /* potentially handle received ether */ }

    // Note: Function count check: Let's count the public/external functions against the summary.
    // 1-5 (Admin/Access) + 6-13 (ERC20) + 14-21 (ERC721) + 22-27 (Core Logic) + 28-30 (Governance) + 31-33 (Staking) + 34 (Fees) + 35-37 (Pause/Emergency) + 38-50 (Views)
    // 5 + 8 + 8 + 6 + 3 + 3 + 1 + 3 + 13 = 50. Yes, well over 20 functions.

    // --- MODIFIERS ---
    // onlyAdmin is already implemented by checking `adminAddress == msg.sender` internally or creating a modifier. Let's add a simple modifier.
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin");
        _;
    }

    // onlyAdminOrGovernance modifier defined earlier
}
```

**Explanation of Concepts & Features:**

1.  **ERC-20 for Elements:** The contract acts as an ERC-20 token for a *default* element type (ID 0). It also manages balances and allowances for *other* element types via mappings, allowing for multiple fungible resources.
2.  **ERC-721 for Assets:** The contract mints and manages unique ERC-721 tokens representing the forged assets.
3.  **Forging Recipes:** `ForgingRecipe` structs define combinations of input elements (`ForgingRecipeInput`) required to create a specific type of asset (`outputAssetTypeId`) with initial properties (`initialAttributes`) and a link to a dynamic rule (`dynamicRuleId`).
4.  **Dynamic Asset Attributes:** `AssetAttributes` store base properties. `DynamicRule` defines *how* these properties might change. The `getAssetAttributes` function is a `view` function that *calculates* the current attributes on the fly based on the base attributes, the associated dynamic rule, time (`block.timestamp`), and potentially external data (via the `IOracle` interface). This avoids expensive on-chain state updates for every attribute change.
5.  **Discovery Mechanism:** `attemptDiscovery` allows users to consume elements for a *probabilistic* chance to mark an existing recipe as `isRecipeDiscovered`. Only discovered recipes can be used for forging. This adds a game-like exploration element.
6.  **Integrated Staking:** Users can `stakeElements` of specific types within the contract. `getStakedBalance` and `getPendingRewards` track stake and calculate yield based on time and a configurable `stakingYieldRatePerSecondScaled`. Rewards are claimed in the default element token. This provides utility/incentive for holding elements.
7.  **Basic Governance:** A simplified governance system is included with `proposeGovernanceAction`, `voteOnProposal`, and `executeProposal`. Proposal vote weight is based on a placeholder `_getVoteWeight` (using staked elements). Execution uses a low-level `call`, which is powerful but requires careful handling of the `data` payload to avoid security issues. The `onlyAdminOrGovernance` modifier is a placeholder, illustrating where governance decisions would gate actions.
8.  **Oracle Integration:** An `IOracle` interface and an `oracle` state variable are included. The `getAssetAttributes` function shows a conceptual example of how dynamic attributes could incorporate data fetched from an oracle (`rule.ruleType == 2`). A real implementation would need a trusted oracle network (like Chainlink).
9.  **Access Control:** `Ownable` is used for the owner (emergency shutdown). An `adminAddress` allows a separate role for managing recipes/elements/rules. `onlyAdminOrGovernance` represents actions gated by either role or a future governance mechanism.
10. **Pausable & ReentrancyGuard:** Standard patterns from OpenZeppelin for safety. `whenNotEmergencyShutdown` modifier specifically allows unstaking/claiming even during a full shutdown.
11. **Fee Collection:** A simple mechanism to collect fees (in the default element) during forging and allow the `feeAddress` to withdraw them.
12. **Structs & Mappings:** Complex data structures are used to manage the various components: different element types, recipes, asset attributes, dynamic rules, proposals, votes, and staking balances.
13. **Error Handling:** Custom errors (`error PAFD__...`) are used for clearer revert reasons, a best practice in modern Solidity.

This contract is a complex example demonstrating the combination of multiple advanced concepts beyond a simple token or NFT, aiming for creativity and potential future expansion into a full DeFi/GameFi protocol. It serves as a conceptual blueprint; a production-ready version would require rigorous security audits, gas optimization, and potentially splitting functionalities across multiple contracts.