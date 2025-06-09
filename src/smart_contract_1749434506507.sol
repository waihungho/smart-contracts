Okay, let's design a smart contract that incorporates several advanced concepts like dynamic NFTs, governed crafting/forging recipes, token staking for governance power, a basic on-chain marketplace with royalties, and treasury management, all within a single contract (though in practice, complex systems are often split).

We'll call this contract the "Aethelgard Forge".

**Core Concepts:**

1.  **Token Trio:** Manages three integrated token types:
    *   `AETHEL` (ERC-20): Utility and staking token.
    *   `FORGE_ITEM` (ERC-1155): Represents various components used in forging.
    *   `ARTIFACT` (ERC-721): Unique, dynamic NFTs created through forging.
2.  **Staking & Governance:** Stake `AETHEL` to gain internal `vAETHEL` power, used for governance proposals and voting on aspects like new forging recipes or treasury actions.
3.  **Governed Forging:** Users can propose new `ARTIFACT` recipes using `FORGE_ITEM`s and `AETHEL`. Governance votes on these. Approved recipes can be used by stakers to forge `ARTIFACT`s, potentially involving randomness and success chance.
4.  **Dynamic NFTs:** `ARTIFACT` NFTs have properties stored on-chain that can change based on external triggers or the owner's actions (e.g., staking more AETHEL).
5.  **On-Chain Marketplace:** Basic functionality to list and buy `ARTIFACT`s and `FORGE_ITEM`s within the contract, enforcing royalties on `ARTIFACT` sales.
6.  **Treasury:** Collects forging fees and marketplace royalties, managed by governance.
7.  **Access Control & Pausability:** Role-based permissions and ability to pause certain operations.

**Outline:**

1.  **License & Pragma**
2.  **Imports:** OpenZeppelin contracts for ERC20, ERC721, ERC1155, Pausable, AccessControl, ReentrancyGuard.
3.  **Interfaces (Optional but good practice for clarity):** Although tokens are integrated, listing interfaces can help.
4.  **Errors:** Custom error types.
5.  **Events:** Log key actions (Mint, Burn, Stake, Forge, List, Buy, Vote, etc.).
6.  **Structs:** Define complex data types (ForgeRecipe, ArtifactProperties, Listing, GovernanceProposal).
7.  **Enums:** Define states (ProposalState, TokenType).
8.  **State Variables:** Mappings for balances, approvals, staked amounts, recipes, artifacts properties, listings, governance proposals, cooldowns, roles, fees, etc.
9.  **Constructor:** Initialize tokens, roles, set initial parameters.
10. **Pausable Functions:** `pause`, `unpause`, `paused`.
11. **Access Control Functions:** (Inherited) `hasRole`, `grantRole`, `revokeRole`.
12. **ERC-20 (AETHEL) Implementations/Overrides:** Handle _mint/_burn for staking/forging.
13. **ERC-1155 (FORGE_ITEM) Implementations/Overrides:** Handle _mint/_burn for forging.
14. **ERC-721 (ARTIFACT) Implementations/Overrides:** Handle _mint/_burn for forging, implement royalty info.
15. **Staking Functions:** `stakeAethel`, `unstakeAethel`, `balanceOfAethelStaked`, `balanceOfVAethel`.
16. **Forging Recipe Governance:** `proposeForgeRecipe`, `voteOnForgeRecipe`, `executeForgeRecipeProposal`, `getForgeRecipeDetails`.
17. **Forging Functions:** `forgeArtifact`, `getForgingCooldown`.
18. **Artifact Dynamic Properties:** `getArtifactProperties`, `triggerArtifactPropertyUpdate` (requires ORACLE_ROLE), `getArtifactTraitValue`.
19. **Marketplace Functions:** `listItemForSale`, `cancelListing`, `buyItem`, `getListingDetails`, `getUserListings`.
20. **Treasury & Fees:** `getTreasuryBalance`, `collectTreasuryFunds` (callable by TREASURY_ROLE based on proposal), `proposeTreasuryWithdrawal`, `voteOnTreasuryProposal`, `executeTreasuryProposal`, `distributeRoyalties`.
21. **Utility/View Functions:** Get contract parameters, token addresses (even though internal), etc.

**Function Summary (Minimum 20+):**

1.  `constructor`: Initializes the contract, mints initial tokens, sets up roles.
2.  `pause()`: Pauses contract operations (requires `PAUSER_ROLE`).
3.  `unpause()`: Unpauses contract operations (requires `PAUSER_ROLE`).
4.  `setRoyaltyRate(uint96 _rate)`: Sets the marketplace royalty percentage (requires `GOVERNANCE_ROLE`).
5.  `getRoyaltyRate()`: Returns the current royalty rate.
6.  `stakeAethel(uint256 amount)`: Locks AETHEL tokens to gain vAETHEL power.
7.  `unstakeAethel(uint256 amount)`: Unlocks staked AETHEL tokens (may have cooldown).
8.  `balanceOfAethelStaked(address account)`: Returns the amount of AETHEL an account has staked.
9.  `balanceOfVAethel(address account)`: Returns the calculated vAETHEL power for an account (based on staked amount).
10. `proposeForgeRecipe(ForgeRecipe memory recipe)`: Creates a governance proposal for a new forging recipe (requires minimum vAETHEL).
11. `voteOnForgeRecipe(uint256 proposalId, bool vote)`: Casts a vote on a recipe proposal (requires vAETHEL).
12. `executeForgeRecipeProposal(uint256 proposalId)`: Executes a recipe proposal if it passed voting.
13. `getForgeRecipeDetails(uint256 recipeId)`: Returns details of a specific forge recipe.
14. `forgeArtifact(uint256 recipeId, bytes32 randomSeed)`: Crafts an ARTIFACT based on a recipe, consuming inputs and potentially failing based on chance. Mints the ARTIFACT NFT.
15. `getForgingCooldown(address account)`: Returns the timestamp when the account can forge again.
16. `getArtifactProperties(uint256 artifactId)`: Returns the current dynamic properties of an ARTIFACT.
17. `triggerArtifactPropertyUpdate(uint256 artifactId)`: Updates dynamic properties of an ARTIFACT based on predefined logic (requires `ORACLE_ROLE` or similar).
18. `getArtifactTraitValue(uint256 artifactId, string memory traitName)`: Returns the value of a specific dynamic trait for an ARTIFACT.
19. `listItemForSale(TokenType tokenKind, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price)`: Creates a marketplace listing for an ARTIFACT or FORGE_ITEM.
20. `cancelListing(uint256 listingId)`: Cancels an active marketplace listing.
21. `buyItem(uint256 listingId)`: Purchases an item from a listing, handling token transfers, payment, and royalties (requires `payable`).
22. `getListingDetails(uint256 listingId)`: Returns details of a marketplace listing.
23. `getUserListings(address user)`: Returns a list of active listing IDs for a user.
24. `getTreasuryBalance(address tokenAddress)`: Returns the balance of a specific token held by the contract treasury.
25. `collectTreasuryFunds(address tokenAddress, uint256 amount, address recipient)`: Allows Treasury role to withdraw funds based on a successful proposal.
26. `proposeTreasuryWithdrawal(address tokenAddress, uint256 amount, address recipient, string memory description)`: Creates a governance proposal to withdraw treasury funds (requires minimum vAETHEL).
27. `voteOnTreasuryProposal(uint256 proposalId, bool vote)`: Casts a vote on a treasury withdrawal proposal (requires vAETHEL).
28. `executeTreasuryProposal(uint256 proposalId)`: Executes a treasury withdrawal proposal if it passed voting.
29. `mintForgeItems(uint256 itemId, uint256 amount, address recipient)`: Mints new FORGE_ITEMs (requires `MINTER_ROLE`).
30. `setForgeFee(uint256 fee)`: Sets the AETHEL fee required for forging (requires `GOVERNANCE_ROLE`).
31. `getForgeFee()`: Returns the current forging fee.
32. `getArtifactTotalSupply()`: Returns the total number of ARTIFACTs minted.

This structure provides a rich set of interconnected functionalities exceeding the 20+ function requirement and combining several interesting concepts.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For sending Ether

/**
 * @title Aethelgard Forge
 * @dev An advanced smart contract integrating ERC-20 (AETHEL), ERC-1155 (Forge Items),
 *      and Dynamic ERC-721 (Artifacts) with staking, governed forging recipes,
 *      an on-chain marketplace with royalties, treasury management, and governance.
 *      This monolithic structure is for demonstration purposes; in production,
 *      it might be split into multiple contracts.
 */
contract AethelgardForge is
    ERC20,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty,
    ERC1155,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Math for uint256;
    using Address for address payable;

    /*═════════════════════════════════════════════════════════════════════
    ║                               OUTLINE                               ║
    ═════════════════════════════════════════════════════════════════════*/
    // 1. License & Pragma
    // 2. Imports
    // 3. Errors
    // 4. Events
    // 5. Structs & Enums
    // 6. Roles
    // 7. State Variables
    // 8. Constructor
    // 9. ERC-20 (AETHEL) Overrides (Handled by inheritance mostly)
    // 10. ERC-721 (ARTIFACT) Overrides (URIStorage, Enumerable, Royalty)
    // 11. ERC-1155 (FORGE_ITEM) Overrides
    // 12. Pausable Functions
    // 13. Access Control (Inherited)
    // 14. Staking Functions
    // 15. Forging Recipe Governance
    // 16. Forging Functions
    // 17. Artifact Dynamic Properties
    // 18. Marketplace Functions
    // 19. Treasury & Fees
    // 20. Utility & View Functions

    /*═════════════════════════════════════════════════════════════════════
    ║                             FUNCTIONS SUMMARY                           ║
    ═════════════════════════════════════════════════════════════════════*/
    // (Minimum 20+ unique system logic functions)
    // constructor() - Initializes contract, tokens, roles.
    // pause() - Pauses system (PAUSER_ROLE).
    // unpause() - Unpauses system (PAUSER_ROLE).
    // getPausedState() - Returns pause status.
    // setRoyaltyRate(uint96 _rate) - Sets market royalty (GOVERNANCE_ROLE).
    // getRoyaltyRate() - Returns royalty rate.
    // stakeAethel(uint256 amount) - Stakes AETHEL for vAETHEL.
    // unstakeAethel(uint256 amount) - Unstakes AETHEL.
    // balanceOfAethelStaked(address account) - Staked AETHEL balance.
    // balanceOfVAethel(address account) - vAETHEL power balance.
    // proposeForgeRecipe(ForgeRecipe memory recipe) - Proposes new recipe (min vAETHEL).
    // voteOnForgeRecipe(uint256 proposalId, bool vote) - Votes on recipe proposal (vAETHEL).
    // executeForgeRecipeProposal(uint256 proposalId) - Executes winning recipe proposal.
    // getForgeRecipeDetails(uint256 recipeId) - Views recipe details.
    // forgeArtifact(uint256 recipeId, bytes32 randomSeed) - Crafts Artifact from recipe (consumes inputs, random chance, cooldown).
    // getForgingCooldown(address account) - User's forging cooldown end time.
    // getArtifactProperties(uint256 artifactId) - Views dynamic properties of an Artifact.
    // triggerArtifactPropertyUpdate(uint256 artifactId) - Updates dynamic properties (ORACLE_ROLE).
    // getArtifactTraitValue(uint256 artifactId, string memory traitName) - Gets specific trait value.
    // listItemForSale(...) - Lists an item on the internal marketplace.
    // cancelListing(uint256 listingId) - Cancels a listing.
    // buyItem(uint256 listingId) - Buys a listed item (handles payment, transfers, royalties).
    // getListingDetails(uint256 listingId) - Views listing details.
    // getUserListings(address user) - Views user's active listings.
    // getTreasuryBalance(address tokenAddress) - Contract's balance of a specific token.
    // collectTreasuryFunds(...) - Withdraws treasury funds (TREASURY_ROLE via proposal).
    // proposeTreasuryWithdrawal(...) - Proposes treasury withdrawal (min vAETHEL).
    // voteOnTreasuryProposal(...) - Votes on treasury withdrawal proposal (vAETHEL).
    // executeTreasuryProposal(...) - Executes winning treasury withdrawal proposal.
    // mintForgeItems(...) - Mints FORGE_ITEMs (MINTER_ROLE).
    // setForgeFee(uint256 fee) - Sets forging AETHEL fee (GOVERNANCE_ROLE).
    // getForgeFee() - Returns forging fee.
    // getArtifactTotalSupply() - Total ARTIFACTs minted.
    // tokenURI(uint256 tokenId) (Override) - Provides metadata URI for Artifacts, potentially reflecting dynamic state.
    // supportsInterface(bytes4 interfaceId) (Override) - Supports required interfaces.
    // _baseURI() (Override) - Base URI for Artifact metadata.
    // uri(uint256 id) (Override) - URI for Forge Items.
    // _update(address to, uint256 tokenId, address auth) (Override) - ERC721 hook.
    // _increaseBalance(address account, uint256 amount) (Override) - ERC20 hook.
    // _decreaseBalance(address account, uint256 amount) (Override) - ERC20 hook.
    // royaltyInfo(...) (Override) - ERC721 royalty info.

    /*═════════════════════════════════════════════════════════════════════
    ║                               ERRORS                                ║
    ═════════════════════════════════════════════════════════════════════*/
    error AethelgardForge__InvalidAmount();
    error AethelgardForge__InsufficientAethel();
    error AethelgardForge__InsufficientStakedAethel();
    error AethelgardForge__InsufficientVAethel();
    error AethelgardForge__StakingCooldownActive();
    error AethelgardForge__UnstakingAmountExceedsStaked();
    error AethelgardForge__ForgingCooldownActive();
    error AethelgardForge__InvalidRecipe();
    error AethelgardForge__InsufficientForgeItems();
    error AethelgardForge__InsufficientAethelFee();
    error AethelgardForge__ForgingFailed(); // For chance-based failure
    error AethelgardForge__ArtifactDoesNotExist();
    error AethelgardForge__InvalidListingId();
    error AethelgardForge__ListingNotActive();
    error AethelgardForge__ListingOwnerMismatch();
    error AethelgardForge__BuyerIsSeller();
    error AethelgardForge__InsufficientPayment();
    error AethelgardForge__TokenTransferFailed();
    error AethelgardForge__EtherTransferFailed();
    error AethelgardForge__InvalidTokenTypeForListing();
    error AethelgardForge__InvalidProposalId();
    error AethelgardForge__ProposalNotActive();
    error AethelgardForge__ProposalAlreadyVoted();
    error AethelgardForge__ProposalCannotBeExecuted();
    error AethelgardForge__ProposalAlreadyExecuted();
    error AethelgardForge__QuorumNotReached();
    error AethelgardForge__MajorityNotReached();
    error AethelgardForge__InsufficientTreasuryBalance();
    error AethelgardForge__InvalidRecipient();
    error AethelgardForge__UnsupportedTrait();
    error AethelgardForge__CannotTransferStakedArtifact(); // Example dynamic constraint

    /*═════════════════════════════════════════════════════════════════════
    ║                               EVENTS                                ║
    ═════════════════════════════════════════════════════════════════════*/
    event AethelStaked(address indexed user, uint256 amount, uint256 totalStaked);
    event AethelUnstaked(address indexed user, uint256 amount, uint256 totalStaked);
    event ForgeRecipeProposed(uint256 indexed proposalId, address indexed proposer, uint256 recipeId);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);
    event ArtifactForged(uint256 indexed artifactId, address indexed owner, uint256 recipeId);
    event ArtifactPropertiesUpdated(uint256 indexed artifactId);
    event ItemListed(uint256 indexed listingId, address indexed seller, uint256 tokenId, uint256 price);
    event ItemSold(uint256 indexed listingId, address indexed buyer, uint256 seller, uint256 price);
    event ListingCancelled(uint256 indexed listingId);
    event TreasuryFundsCollected(address indexed tokenAddress, uint256 amount, address indexed recipient);
    event TreasuryWithdrawalProposed(uint256 indexed proposalId, address indexed proposer, address tokenAddress, uint256 amount, address recipient);
    event RoyaltyPaid(uint256 indexed artifactId, uint256 amount, address indexed recipient);

    /*═════════════════════════════════════════════════════════════════════
    ║                             STRUCTS & ENUMS                           ║
    ═════════════════════════════════════════════════════════════════════*/

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum TokenType { ERC721, ERC1155 }

    struct InputItem {
        uint256 itemId; // ERC1155 ID
        uint256 amount;
    }

    struct ForgeRecipe {
        uint256 recipeId;
        InputItem[] inputs; // Required Forge Items
        uint256 aethelCost; // AETHEL burned per attempt
        // Output: Defines which type/properties of Artifact is minted
        // (Simplified: just an ID here, but could be more complex struct/params)
        uint256 outputArtifactType;
        uint256 successChanceBps; // Success chance in Basis Points (0-10000)
        uint256 minVAethelRequired; // Min vAETHEL to use this recipe
        bool isActive; // Set to true after governance approval
    }

    struct ArtifactProperties {
        // Example Dynamic Properties
        uint256 creationTime;
        uint256 forgingSeed;
        uint256 ownerStakedAethelAtLastUpdate; // Dynamic trait example
        uint256 level; // Another dynamic trait example
        string currentMetadataURI; // Can be updated to reflect state
        // Add more properties as needed
    }

    struct Listing {
        uint256 listingId;
        TokenType tokenKind;
        address tokenAddress; // Address of the token contract (self, but for clarity)
        uint256 tokenId; // ERC721 Token ID or ERC1155 Item ID
        uint256 amount; // Relevant for ERC1155 listings
        uint256 price; // Price in Ether
        address payable seller;
        bool active;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string description;
        // Data related to the proposal payload
        bytes data; // Can encode recipe details, treasury withdrawal params, etc.
        ProposalState state;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotesYes;
        uint256 totalVotesNo;
        mapping(address => bool) hasVoted;
        // Specific proposal data pointers/values could be added here
        uint256 targetRecipeId; // Used for recipe proposals
        address targetTokenAddress; // Used for treasury proposals
        uint256 targetAmount;       // Used for treasury proposals
        address targetRecipient;    // Used for treasury proposals
    }


    /*═════════════════════════════════════════════════════════════════════
    ║                                ROLES                                ║
    ═════════════════════════════════════════════════════════════════════*/
    // DEFAULT_ADMIN_ROLE has all initial permissions (grant/revoke other roles)
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Can mint new Forge Items
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Can pause/unpause
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE"); // Can manage parameters like royalty, forge fee
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // Can trigger dynamic property updates
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE"); // Can execute treasury withdrawals

    /*═════════════════════════════════════════════════════════════════════
    ║                             STATE VARIABLES                           ║
    ═════════════════════════════════════════════════════════════════════*/

    // AETHEL & Staking
    uint256 private _totalAethelSupply;
    mapping(address => uint256) private _stakedAethel;
    mapping(address => uint256) private _vAethelBalance; // Derived power, simpler 1:1 in this example
    uint256 public minAethelToPropose = 1000 * (10 ** 18); // Example minimum staked AETHEL to propose

    // FORGE_ITEM
    uint256 private _forgeItemSupplyCounter; // Counter for unique item IDs? Or fixed IDs? Let's use fixed IDs for types.
    // ERC1155 balances handled by inheritance.

    // ARTIFACT
    Counters.Counter private _artifactIds; // Counter for unique Artifact IDs (ERC721)
    mapping(uint256 => ArtifactProperties) private _artifactProperties;
    mapping(address => uint256) private _forgingCooldowns; // Timestamp when cooldown ends
    uint256 public forgingCooldownDuration = 1 days; // Example cooldown

    // Forging Recipes
    Counters.Counter private _recipeIds;
    mapping(uint256 => ForgeRecipe) public forgeRecipes;
    uint256 public forgeFee = 50 * (10 ** 18); // Example AETHEL fee per forging attempt

    // Marketplace
    Counters.Counter private _listingIds;
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256[]) private _userActiveListings; // Helper mapping

    // Royalty
    uint96 private _royaltyRateBps = 500; // 5% in Basis Points (500/10000)
    address payable public royaltyRecipient; // Address receiving royalties (can be treasury or another address)

    // Governance
    Counters.Counter private _proposalIds;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public constant MIN_VOTING_PERIOD = 1 days; // Minimum voting period
    uint256 public constant PROPOSAL_QUORUM_BPS = 400; // 4% of total vAETHEL must vote
    uint256 public constant PROPOSAL_MAJORITY_BPS = 5000; // 50% + 1 of votes must be Yes

    // Treasury
    // Funds are held directly in the contract's balance.
    // ETH balance: address(this).balance
    // Token balances: ERC20(tokenAddress).balanceOf(address(this)), ERC1155/ERC721 balances handled by inheritance.


    /*═════════════════════════════════════════════════════════════════════
    ║                               CONSTRUCTOR                             ║
    ═════════════════════════════════════════════════════════════════════*/
    constructor(
        address defaultAdmin,
        address _royaltyRecipient,
        uint256 initialAethelSupply,
        uint256 initialForgeItemTypeCount
    )
        ERC20("Aethel Token", "AETHEL")
        ERC721("Aethelgard Artifact", "ARTIFACT")
        ERC1155("https://aethelgard.io/items/{id}.json") // Example Base URI for ERC1155
        ERC721URIStorage()
        ERC721Enumerable()
        ERC721Royalty("Aethelgard Artifact", "ARTIFACT") // Correct parameters
        Pausable()
        ReentrancyGuard()
    {
        // Set up access control roles
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _setupRole(PAUSER_ROLE, defaultAdmin); // Admin is initially Pauser
        _setupRole(MINTER_ROLE, defaultAdmin); // Admin is initially Minter
        _setupRole(GOVERNANCE_ROLE, defaultAdmin); // Admin is initially Governance
        _setupRole(ORACLE_ROLE, defaultAdmin); // Admin is initially Oracle
        _setupRole(TREASURY_ROLE, defaultAdmin); // Admin is initially Treasury

        // Mint initial supply of AETHEL
        _mint(defaultAdmin, initialAethelSupply);
        _totalAethelSupply = initialAethelSupply;

        // Mint some initial Forge Items (Example: mint 100 of first `initialForgeItemTypeCount` types to admin)
        for (uint256 i = 0; i < initialForgeItemTypeCount; i++) {
             _mint(defaultAdmin, i, 100, ""); // Mint 100 of item ID 'i'
        }
        // Note: ERC1155 IDs are just identifiers, not necessarily sequential counters
        // The URI for each ID should be set up externally or via another function.

        // Set the royalty recipient
        if (_royaltyRecipient == address(0)) revert AethelgardForge__InvalidRecipient();
        royaltyRecipient = payable(_royaltyRecipient);
    }

    /*═════════════════════════════════════════════════════════════════════
    ║                  ERC Overrides & Helper Functions                     ║
    ═════════════════════════════════════════════════════════════════════*/

    // ERC20 Overrides (AETHEL) - Most handled by inheriting ERC20
    // We'll override _update to hook into AETHEL transfers for staking calculations if needed,
    // but a simple staked balance mapping is used here for vAETHEL.

    function _increaseBalance(address account, uint256 amount) internal override(ERC20) {
        // This hooks into _mint and _transfer (recipient side) for AETHEL
        super._increaseBalance(account, amount);
        // If needed, could update vAETHEL based on total AETHEL balance here
        // _vAethelBalance[account] = balanceOf(account); // Simple 1:1 power
    }

    function _decreaseBalance(address account, uint256 amount) internal override(ERC20) {
        // This hooks into _burn and _transfer (sender side) for AETHEL
        super._decreaseBalance(account, amount);
        // If needed, could update vAETHEL based on total AETHEL balance here
        // _vAethelBalance[account] = balanceOf(account); // Simple 1:1 power
    }

    // ERC721 Overrides (ARTIFACT)
    function _baseURI() internal pure override(ERC721URIStorage) returns (string memory) {
        return "https://aethelgard.io/artifacts/"; // Example base URI for ERC721 metadata
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
         if (!_exists(tokenId)) revert AethelgardForge__ArtifactDoesNotExist();
        // Here you would ideally fetch or construct a URI that reflects the dynamic state
        // Example: Append state identifier or use a dynamic metadata service
        // For simplicity, just returning the base URI + ID for now.
        // A more advanced implementation would fetch _artifactProperties[tokenId]
        // and generate a unique URI pointing to a dynamic metadata endpoint.
        // e.g., return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), "?state=", _artifactProperties[tokenId].level));

        // For this example, let's show a basic implementation that *could* be dynamic
        // string memory base = _baseURI();
        // // Fetch some property to include (simplified)
        // uint256 level = _artifactProperties[tokenId].level;
        // return string(abi.encodePacked(base, Strings.toString(tokenId), ".json", "?level=", Strings.toString(level)));

        // Simplest static version as per ERC721URIStorage standard:
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty, ERC1155, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId || // Includes URIStorage
               interfaceId == type(IERC721Royalty).interfaceId ||
               interfaceId == type(IERC1155).interfaceId || // ERC1155 standard
               interfaceId == type(IAccessControl).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) {
         // Hook for ERC721 transfers
        super._update(to, tokenId, auth);
        // Example: When an Artifact is transferred, maybe reset a dynamic property or update state
        // _artifactProperties[tokenId].ownerStakedAethelAtLastUpdate = 0; // Reset example
        emit ArtifactPropertiesUpdated(tokenId); // Indicate potential state change
    }

    // ERC1155 Overrides (FORGE_ITEM)
     function uri(uint256 id) public view override(ERC1155) returns (string memory) {
        // This points to the metadata JSON for each item ID
        // Example: https://aethelgard.io/items/1.json, https://aethelgard.io/items/2.json etc.
        return string(abi.encodePacked(super.uri(id), Strings.toString(id), ".json"));
     }

    /*═════════════════════════════════════════════════════════════════════
    ║                            PAUSABLE FUNCTIONS                         ║
    ═════════════════════════════════════════════════════════════════════*/
    function pause() public virtual onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public virtual onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function getPausedState() public view returns (bool) {
        return paused();
    }

    /*═════════════════════════════════════════════════════════════════════
    ║                             STAKING FUNCTIONS                         ║
    ═════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Stakes AETHEL tokens to gain vAETHEL voting/forging power.
     * Requires user to approve this contract to spend their AETHEL.
     */
    function stakeAethel(uint256 amount) public whenNotPaused nonReentrant {
        if (amount == 0) revert AethelgardForge__InvalidAmount();
        // ERC20 transferFrom pulls tokens from the user
        bool success = transferFrom(msg.sender, address(this), amount);
        if (!success) revert AethelgardForge__InsufficientAethel(); // transferFrom should revert on failure, but safety check

        _stakedAethel[msg.sender] += amount;
        _vAethelBalance[msg.sender] += amount; // Simple 1:1 power calculation

        emit AethelStaked(msg.sender, amount, _stakedAethel[msg.sender]);
    }

    /**
     * @dev Unstakes AETHEL tokens.
     */
    function unstakeAethel(uint256 amount) public whenNotPaused nonReentrant {
        if (amount == 0) revert AethelgardForge__InvalidAmount();
        if (_stakedAethel[msg.sender] < amount) revert AethelgardForge__UnstakingAmountExceedsStaked();

        _stakedAethel[msg.sender] -= amount;
        _vAethelBalance[msg.sender] -= amount; // Simple 1:1 power calculation

        // ERC20 transfer sends tokens back to the user
        bool success = transfer(msg.sender, amount);
        if (!success) revert AethelgardForge__TokenTransferFailed(); // Should not fail if contract has balance

        emit AethelUnstaked(msg.sender, amount, _stakedAethel[msg.sender]);
    }

    /**
     * @dev Returns the amount of AETHEL an account has currently staked.
     */
    function balanceOfAethelStaked(address account) public view returns (uint256) {
        return _stakedAethel[account];
    }

    /**
     * @dev Returns the vAETHEL power for an account. In this example, it's 1:1 with staked AETHEL.
     */
    function balanceOfVAethel(address account) public view returns (uint256) {
        return _vAethelBalance[account];
    }

    /*═════════════════════════════════════════════════════════════════════
    ║                      FORGING RECIPE GOVERNANCE                      ║
    ═════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Proposes a new forge recipe. Requires minimum staked AETHEL.
     * @param recipe The details of the proposed recipe.
     * @param description A description for the proposal.
     */
    function proposeForgeRecipe(ForgeRecipe memory recipe, string memory description) public whenNotPaused nonReentrant {
        if (_vAethelBalance[msg.sender] < minAethelToPropose) revert AethelgardForge__InsufficientVAethel();

        uint256 proposalId = _proposalIds.current();
        _proposalIds.increment();

        // Create the recipe proposal
        uint256 recipeId = _recipeIds.current();
        _recipeIds.increment();
        recipe.recipeId = recipeId;
        recipe.isActive = false; // Not active until approved

        // Store the recipe temporarily or link it to the proposal
        // For simplicity, store it directly and mark inactive
        forgeRecipes[recipeId] = recipe;

        // Create the governance proposal
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        // Encode recipe ID as data payload (simple example)
        proposal.data = abi.encode(recipeId);
        proposal.state = ProposalState.Active;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + MIN_VOTING_PERIOD; // Use minimum period for example
        proposal.targetRecipeId = recipeId; // Link recipe ID

        emit ForgeRecipeProposed(proposalId, msg.sender, recipeId);
    }

    /**
     * @dev Casts a vote on a governance proposal (recipe or treasury).
     * @param proposalId The ID of the proposal.
     * @param vote True for Yes, False for No.
     */
    function voteOnProposal(uint256 proposalId, bool vote) public whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        if (proposal.state != ProposalState.Active) revert AethelgardForge__ProposalNotActive();
        if (proposal.voteEndTime < block.timestamp) revert AethelgardForge__ProposalNotActive(); // Check if voting period ended

        if (proposal.hasVoted[msg.sender]) revert AethelgardForge__ProposalAlreadyVoted();
        uint256 voterPower = _vAethelBalance[msg.sender];
        if (voterPower == 0) revert AethelgardForge__InsufficientVAethel();

        if (vote) {
            proposal.totalVotesYes += voterPower;
        } else {
            proposal.totalVotesNo += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, vote);
    }

    /**
     * @dev Executes a governance proposal if it has passed the voting period and thresholds.
     * Can be called by anyone after the voting period ends.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        if (proposal.state != ProposalState.Active) revert AethelgardForge__ProposalNotActive();
        if (proposal.voteEndTime >= block.timestamp) revert AethelgardForge__ProposalCannotBeExecuted(); // Voting still active

        uint256 totalVotes = proposal.totalVotesYes + proposal.totalVotesNo;
        uint256 totalVAethelSupply = _totalAethelSupply; // Assuming 1:1 staked = total supply for simplicity

        // Check quorum: total votes must be >= QUORUM_BPS of total vAETHEL supply
        if (totalVAethelSupply == 0 || totalVotes * 10000 < totalVAethelSupply * PROPOSAL_QUORUM_BPS) {
             proposal.state = ProposalState.Failed;
             emit ProposalExecuted(proposalId);
             return;
        }

        // Check majority: total YES votes must be >= MAJORITY_BPS of total votes
        if (proposal.totalVotesYes * 10000 < totalVotes * PROPOSAL_MAJORITY_BPS) {
             proposal.state = ProposalState.Failed;
             emit ProposalExecuted(proposalId);
             return;
        }

        // Proposal Passed - Execute based on type
        if (proposal.targetRecipeId != 0 && forgeRecipes[proposal.targetRecipeId].recipeId == proposal.targetRecipeId) {
            // This is a Forge Recipe Proposal
            forgeRecipes[proposal.targetRecipeId].isActive = true; // Activate the recipe
        } else if (proposal.targetTokenAddress != address(0) && proposal.targetRecipient != address(0)) {
            // This is a Treasury Withdrawal Proposal
            // The actual withdrawal requires TREASURY_ROLE and links to this successful proposal
            // Handled in collectTreasuryFunds
        } else {
            // Handle other proposal types if added
             proposal.state = ProposalState.Failed; // Mark failed if execution logic is missing/invalid
             emit ProposalExecuted(proposalId);
             return;
        }

        proposal.state = ProposalState.Succeeded; // Mark as Succeeded before execution
        // Actual execution might happen in a separate function called by a role,
        // or directly here if the logic is simple and safe.
        // For treasury, we'll make `collectTreasuryFunds` require a successful proposal ID.

        emit ProposalExecuted(proposalId);
    }

     /**
     * @dev Executes a winning Forge Recipe proposal. Specialised execute function.
     * @param proposalId The ID of the recipe proposal.
     */
     function executeForgeRecipeProposal(uint256 proposalId) public whenNotPaused nonReentrant {
         GovernanceProposal storage proposal = governanceProposals[proposalId];
         if (proposal.state != ProposalState.Active) revert AethelgardForge__ProposalNotActive();
         if (proposal.voteEndTime >= block.timestamp) revert AethelgardForge__ProposalCannotBeExecuted(); // Voting still active

         uint256 totalVotes = proposal.totalVotesYes + proposal.totalVotesNo;
         uint256 totalVAethelSupply = _totalAethelSupply;

         // Check quorum and majority
         if (totalVAethelSupply == 0 || totalVotes * 10000 < totalVAethelSupply * PROPOSAL_QUORUM_BPS ||
             proposal.totalVotesYes * 10000 < totalVotes * PROPOSAL_MAJORITY_BPS)
         {
              proposal.state = ProposalState.Failed;
         } else {
             // Proposal Passed
             uint256 recipeId;
             // Decode the recipe ID from data payload
             try abi.decode(proposal.data, (uint256)) returns (uint256 decodedRecipeId) {
                 recipeId = decodedRecipeId;
             } catch {
                 proposal.state = ProposalState.Failed; // Decoding failed
                 emit ProposalExecuted(proposalId);
                 return;
             }

             ForgeRecipe storage recipe = forgeRecipes[recipeId];
             if (recipe.recipeId == 0) { // Check if recipe exists
                 proposal.state = ProposalState.Failed;
             } else {
                 recipe.isActive = true; // Activate the recipe
                 proposal.state = ProposalState.Executed; // Recipe proposals are executed immediately
             }
         }

         emit ProposalExecuted(proposalId);
     }


    /**
     * @dev Gets the details of a specific forge recipe.
     * @param recipeId The ID of the recipe.
     * @return ForgeRecipe struct.
     */
    function getForgeRecipeDetails(uint256 recipeId) public view returns (ForgeRecipe memory) {
        return forgeRecipes[recipeId];
    }

    /*═════════════════════════════════════════════════════════════════════
    ║                              FORGING FUNCTIONS                        ║
    ═════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Attempts to forge an ARTIFACT using a specific recipe.
     * Consumes input items and AETHEL fee, includes a success chance and cooldown.
     * @param recipeId The ID of the recipe to use.
     * @param randomSeed A seed provided by the user/frontend (should be combined with block data).
     */
    function forgeArtifact(uint256 recipeId, bytes32 randomSeed) public whenNotPaused nonReentrant {
        ForgeRecipe storage recipe = forgeRecipes[recipeId];
        if (recipe.recipeId == 0 || !recipe.isActive) revert AethelgardForge__InvalidRecipe();
        if (_vAethelBalance[msg.sender] < recipe.minVAethelRequired) revert AethelgardForge__InsufficientVAethel();
        if (_forgingCooldowns[msg.sender] > block.timestamp) revert AethelgardForge__ForgingCooldownActive();

        // --- Consume Inputs ---
        // Consume Forge Items (ERC1155)
        for (uint i = 0; i < recipe.inputs.length; i++) {
            InputItem memory input = recipe.inputs[i];
            if (balanceOf(msg.sender, input.itemId) < input.amount) revert AethelgardForge__InsufficientForgeItems();
            // The user must have approved this contract to manage their ERC1155 tokens
            // via setApprovalForAll on the contract itself.
            _burn(msg.sender, input.itemId, input.amount);
        }

        // Consume AETHEL fee (ERC20)
        if (balanceOf(msg.sender) < forgeFee) revert AethelgardForge__InsufficientAethelFee();
         _transfer(msg.sender, address(this), forgeFee); // Transfer fee to treasury/contract balance
        // Note: This AETHEL fee is separate from any AETHEL *input* required by the recipe itself,
        // which would be burned using _burn(msg.sender, recipe.aethelCost). Let's assume recipe.aethelCost is burned.
        if (recipe.aethelCost > 0) {
             // User must have approved the contract to spend recipe.aethelCost
             // bool successBurn = transferFrom(msg.sender, address(this), recipe.aethelCost); // No, burn directly from user approved balance
             // User must approve contract to BURN AETHEL for forging.
             // Or, burn directly from user's balance *after* they've transferred the inputs + fee.
             // Let's assume the user approves the forgeFee and recipe.aethelCost to the contract.
             // simpler: check user balance first, then burn from contract's 'allowance' pool.
             // Or most common: User approves contract, contract pulls.
             // bool successBurn = transferFrom(msg.sender, address(this), recipe.aethelCost); // Transfer to contract then burn from contract
             // _burn(address(this), recipe.aethelCost);

             // Safest: User approves contract for TOTAL_COST = forgeFee + recipe.aethelCost.
             // Then transfer total cost to contract, then distribute/burn from contract balance.
             // This requires the user to approve `forgeFee + recipe.aethelCost`.

             // Alternative simpler approach: Check total balance, then burn directly.
             // This requires user to approve contract to burn their AETHEL balance.
             // OpenZeppelin's _burn function is only for *contract* balance by default.
             // Need to implement user burning logic or transfer to contract first.

             // Let's stick to transferring to the contract first, then managing from there.
             // The forgeFee was transferred above. Now transfer the recipe cost.
             bool successRecipeCost = transferFrom(msg.sender, address(this), recipe.aethelCost);
             if (!successRecipeCost) revert AethelgardForge__InsufficientAethelFee(); // Assuming this covers insufficient balance/allowance
             // Now the contract holds the recipe cost. We can burn it or add to treasury.
             // Burning is common for utility tokens like this in crafting.
             // _burn(address(this), recipe.aethelCost); // Burn from contract's balance
             // Or, add to treasury:
             // Treasury already holds the fee and recipe cost now.
        }


        // --- Determine Success ---
        // Use block hash, block number, and user seed for pseudo-randomness
        bytes32 combinedSeed = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender, randomSeed));
        uint256 randomNumber = uint256(combinedSeed) % 10000; // Number between 0 and 9999

        bool success = randomNumber < recipe.successChanceBps;

        // --- Handle Outcome ---
        _forgingCooldowns[msg.sender] = block.timestamp + forgingCooldownDuration; // Apply cooldown regardless of success

        if (!success) {
            // Inputs and fee are still consumed on failure
            revert AethelgardForge__ForgingFailed();
        }

        // --- Mint Artifact on Success ---
        uint256 newItemId = _artifactIds.current();
        _artifactIds.increment();

        _safeMint(msg.sender, newItemId); // Mints the ERC721 Artifact

        // Initialize dynamic properties
        ArtifactProperties storage props = _artifactProperties[newItemId];
        props.creationTime = block.timestamp;
        props.forgingSeed = combinedSeed; // Store the seed used
        // Initialize other properties (can be based on recipe.outputArtifactType)
        props.level = 1; // Example initial level
        props.ownerStakedAethelAtLastUpdate = _stakedAethel[msg.sender]; // Store owner's staked balance at creation
        //props.currentMetadataURI = ...; // Set initial URI

        // Set royalty information for the new artifact
        _setDefaultRoyalty(royaltyRecipient, _royaltyRateBps); // Apply default royalty to new mints
        // _setTokenRoyalty(newItemId, royaltyRecipient, _royaltyRateBps); // Can set per token if needed

        emit ArtifactForged(newItemId, msg.sender, recipeId);
    }

    /**
     * @dev Returns the timestamp when the user can forge again.
     */
    function getForgingCooldown(address account) public view returns (uint256) {
        return _forgingCooldowns[account];
    }

    /*═════════════════════════════════════════════════════════════════════
    ║                       ARTIFACT DYNAMIC PROPERTIES                     ║
    ═════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Gets the dynamic properties struct for a specific Artifact.
     * @param artifactId The ID of the ARTIFACT.
     */
    function getArtifactProperties(uint256 artifactId) public view returns (ArtifactProperties memory) {
        if (!_exists(artifactId)) revert AethelgardForge__ArtifactDoesNotExist();
        return _artifactProperties[artifactId];
    }

     /**
      * @dev Gets the value of a specific dynamic trait.
      * @param artifactId The ID of the ARTIFACT.
      * @param traitName The name of the trait (e.g., "level", "ownerStakedAethel").
      */
     function getArtifactTraitValue(uint256 artifactId, string memory traitName) public view returns (uint256) {
         if (!_exists(artifactId)) revert AethelgardForge__ArtifactDoesNotExist();
         ArtifactProperties storage props = _artifactProperties[artifactId];

         bytes32 traitHash = keccak256(abi.encodePacked(traitName));

         if (traitHash == keccak256("level")) {
             return props.level;
         } else if (traitHash == keccak256("ownerStakedAethel")) {
             // For this trait, maybe return the current staked amount of the *current* owner
             // This is where the "dynamic" part can be calculated on the fly or triggered.
             address currentOwner = ownerOf(artifactId);
             return _stakedAethel[currentOwner]; // Example: Reflects current owner's stake
             // Or return the stored value from last update: return props.ownerStakedAethelAtLastUpdate;
         }
         // Add more traits here
         revert AethelgardForge__UnsupportedTrait();
     }


    /**
     * @dev Triggers an update to an Artifact's dynamic properties.
     * This function would typically be called by a trusted oracle or an automated system.
     * @param artifactId The ID of the ARTIFACT to update.
     */
    function triggerArtifactPropertyUpdate(uint256 artifactId) public whenNotPaused onlyRole(ORACLE_ROLE) {
        if (!_exists(artifactId)) revert AethelgardForge__ArtifactDoesNotExist();

        ArtifactProperties storage props = _artifactProperties[artifactId];
        address currentOwner = ownerOf(artifactId);

        // Example update logic:
        // 1. Update based on current owner's staked AETHEL
        props.ownerStakedAethelAtLastUpdate = _stakedAethel[currentOwner];

        // 2. Update level based on external factor or time since creation
        // uint256 timePassed = block.timestamp - props.creationTime;
        // props.level = 1 + timePassed / (7 days); // Gain a level every 7 days

        // 3. Update URI if the state change affects metadata
        // props.currentMetadataURI = constructDynamicURI(artifactId, props); // Call helper to build new URI

        emit ArtifactPropertiesUpdated(artifactId);
    }

    // Helper function to construct dynamic URI (example)
    // function constructDynamicURI(uint256 artifactId, ArtifactProperties storage props) internal view returns (string memory) {
    //     // Logic to build URI based on props.level, etc.
    //     return string(abi.encodePacked(_baseURI(), Strings.toString(artifactId), ".json?level=", Strings.toString(props.level)));
    // }


    /*═════════════════════════════════════════════════════════════════════
    ║                            MARKETPLACE FUNCTIONS                      ║
    ═════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Lists an item (ARTIFACT or FORGE_ITEM) for sale on the internal marketplace.
     * Requires seller to approve transfer for the item(s).
     * @param tokenKind The type of token being listed (ERC721 or ERC1155).
     * @param tokenId The ID of the token (Artifact ID or Forge Item ID).
     * @param amount For ERC1155, the quantity to list; for ERC721, must be 1.
     * @param price The price in Ether.
     */
    function listItemForSale(TokenType tokenKind, uint256 tokenId, uint256 amount, uint256 price) public whenNotPaused nonReentrant {
        if (amount == 0 || price == 0) revert AethelgardForge__InvalidAmount();
        if (tokenKind == TokenType.ERC721 && amount != 1) revert AethelgardForge__InvalidAmount();
        if (tokenKind != TokenType.ERC721 && tokenKind != TokenType.ERC1155) revert AethelgardForge__InvalidTokenTypeForListing();

        address itemOwner;
        if (tokenKind == TokenType.ERC721) {
            itemOwner = ownerOf(tokenId); // Check ERC721 owner
            if (itemOwner != msg.sender) revert AethelgardForge__ListingOwnerMismatch();
             // Seller must approve this contract or transfer to it first (transfer to contract is simpler for marketplace)
            // For this simple marketplace, we require the item to be transferred to the contract *upon listing*.
            // This is safer than relying on approvals.
            // If you prefer approval model, remove the transfer here and check allowance/approval in buyItem.
             transferFrom(msg.sender, address(this), tokenId); // Transfer Artifact to contract
        } else { // ERC1155
             // Check user balance for ERC1155
            if (balanceOf(msg.sender, tokenId) < amount) revert AethelgardForge__InsufficientForgeItems();
             // Seller must setApprovalForAll for the contract address
             // Transfer items to the contract upon listing
            safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        }

        uint256 listingId = _listingIds.current();
        _listingIds.increment();

        listings[listingId] = Listing({
            listingId: listingId,
            tokenKind: tokenKind,
            tokenAddress: address(this), // The tokens are held within THIS contract
            tokenId: tokenId,
            amount: amount,
            price: price,
            seller: payable(msg.sender),
            active: true
        });

        _userActiveListings[msg.sender].push(listingId); // Add to user's active listings

        emit ItemListed(listingId, msg.sender, tokenId, price);
    }

    /**
     * @dev Cancels an active marketplace listing. Only callable by the seller.
     * Transfers the item(s) back to the seller.
     * @param listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 listingId) public whenNotPaused nonReentrant {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active) revert AethelgardForge__ListingNotActive();
        if (listing.seller != msg.sender) revert AethelgardForge__ListingOwnerMismatch();

        listing.active = false; // Mark listing as inactive

        // Transfer item(s) back to the seller
        if (listing.tokenKind == TokenType.ERC721) {
             // Ensure contract owns the Artifact before transferring
            require(ownerOf(listing.tokenId) == address(this), "Contract does not own artifact");
            _transfer(address(this), listing.seller, listing.tokenId); // Internal ERC721 transfer
        } else { // ERC1155
             // Ensure contract has sufficient balance for ERC1155
            require(balanceOf(address(this), listing.tokenId) >= listing.amount, "Contract insufficient item balance");
            _safeTransferFrom(address(this), listing.seller, listing.tokenId, listing.amount, ""); // Internal ERC1155 transfer
        }

        // Remove listing ID from user's active listings (simple removal, not gas efficient for many listings)
        uint256[] storage userListings = _userActiveListings[msg.sender];
        for (uint i = 0; i < userListings.length; i++) {
            if (userListings[i] == listingId) {
                userListings[i] = userListings[userListings.length - 1];
                userListings.pop();
                break;
            }
        }

        emit ListingCancelled(listingId);
    }

    /**
     * @dev Buys an item from an active marketplace listing.
     * Sends ETH payment, transfers item(s) and handles royalties.
     * @param listingId The ID of the listing to buy.
     */
    function buyItem(uint256 listingId) public payable whenNotPaused nonReentrant {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active) revert AethelgardForge__ListingNotActive();
        if (listing.seller == msg.sender) revert AethelgardForge__BuyerIsSeller();
        if (msg.value < listing.price) revert AethelgardForge__InsufficientPayment();

        listing.active = false; // Mark listing as inactive immediately

        uint256 payment = listing.price;
        uint256 royaltyAmount = 0;
        uint256 sellerProceeds = payment;

        // Calculate and handle royalties for ARTIFACTs (ERC721)
        if (listing.tokenKind == TokenType.ERC721) {
             // Using ERC721Royalty extension's royaltyInfo function
             (address receiver, uint256 royaltyValue) = royaltyInfo(listing.tokenId, payment);

             if (royaltyValue > 0 && receiver != address(0)) {
                 royaltyAmount = royaltyValue;
                 sellerProceeds = payment - royaltyAmount;

                 // Send royalty to the recipient (e.g., treasury or artist)
                 // Use Address.sendValue for safety
                 (bool success, ) = payable(receiver).call{value: royaltyAmount}("");
                 if (!success) {
                    // Handle failure - maybe pause contract, log error, or send royalty to treasury
                    // For this example, we allow the sale but log the failed royalty payment.
                    // A more robust system might revert or escrow the royalty.
                    // Reverting would be safest: revert AethelgardForge__EtherTransferFailed();
                    emit RoyaltyPaid(listing.tokenId, royaltyAmount, receiver); // Still emit even if potentially failed for logging
                 } else {
                     emit RoyaltyPaid(listing.tokenId, royaltyAmount, receiver);
                 }
             }
        }

        // Send proceeds to the seller
        if (sellerProceeds > 0) {
            (bool success, ) = listing.seller.call{value: sellerProceeds}("");
             if (!success) {
                 // Again, decide failure handling. Reverting is safest.
                 // revert AethelgardForge__EtherTransferFailed();
             }
        }

        // Handle any excess payment (refund buyer)
        uint256 excessPayment = msg.value - payment;
        if (excessPayment > 0) {
            (bool success, ) = payable(msg.sender).call{value: excessPayment}("");
             if (!success) {
                 // Failure to refund is critical. Revert.
                 revert AethelgardForge__EtherTransferFailed();
             }
        }

        // Transfer item(s) to the buyer
        if (listing.tokenKind == TokenType.ERC721) {
             // Ensure contract owns the Artifact before transferring
            require(ownerOf(listing.tokenId) == address(this), "Contract does not own artifact for sale");
            _transfer(address(this), msg.sender, listing.tokenId); // Internal ERC721 transfer
        } else { // ERC1155
             // Ensure contract has sufficient balance for ERC1155
             require(balanceOf(address(this), listing.tokenId) >= listing.amount, "Contract insufficient item balance for sale");
            _safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.amount, ""); // Internal ERC1155 transfer
        }

        // Remove listing ID from user's active listings (simple removal)
        uint256[] storage userListings = _userActiveListings[listing.seller];
         for (uint i = 0; i < userListings.length; i++) {
             if (userListings[i] == listingId) {
                 userListings[i] = userListings[userListings.length - 1];
                 userListings.pop();
                 break;
             }
         }


        emit ItemSold(listingId, msg.sender, listing.seller, payment);
    }

    /**
     * @dev Gets the details of a specific marketplace listing.
     * @param listingId The ID of the listing.
     * @return Listing struct.
     */
    function getListingDetails(uint256 listingId) public view returns (Listing memory) {
        // Check if listing exists and is active before returning
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active) revert AethelgardForge__InvalidListingId();
        return listing;
    }

     /**
      * @dev Gets a list of active listing IDs for a user.
      * @param user The address of the user.
      * @return Array of listing IDs.
      */
     function getUserListings(address user) public view returns (uint256[] memory) {
         uint256[] storage activeListings = _userActiveListings[user];
         uint256 activeCount = 0;
         for(uint i = 0; i < activeListings.length; i++) {
             if(listings[activeListings[i]].active) {
                 activeCount++;
             }
         }

         uint256[] memory result = new uint256[](activeCount);
         uint256 resultIndex = 0;
         for(uint i = 0; i < activeListings.length; i++) {
             if(listings[activeListings[i]].active) {
                 result[resultIndex] = activeListings[i];
                 resultIndex++;
             }
         }
         return result;
     }


    /*═════════════════════════════════════════════════════════════════════
    ║                            TREASURY & FEES                          ║
    ═════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Gets the balance of a specific token held by the contract treasury.
     * Includes ETH balance implicitly.
     * @param tokenAddress The address of the token (or address(0) for ETH).
     * @return The balance amount.
     */
    function getTreasuryBalance(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance; // ETH balance
        } else if (tokenAddress == address(this)) {
            // This contract holds the tokens itself (AETHEL, Forge Items, Artifacts)
             // Returning balance of AETHEL held by contract
            return balanceOf(address(this)); // Assuming ERC20 balance
             // For ERC1155/ERC721 held by contract, you'd need to specify the token ID.
             // This function is better for fungible tokens (ETH, AETHEL, other ERC20s).
        } else {
            // Assuming this is an ERC20 token
             return ERC20(tokenAddress).balanceOf(address(this));
        }
    }

    /**
     * @dev Proposes a withdrawal of funds from the treasury.
     * @param tokenAddress Address of the token to withdraw (address(0) for ETH).
     * @param amount The amount to withdraw.
     * @param recipient The address to send the funds to.
     * @param description A description for the proposal.
     */
    function proposeTreasuryWithdrawal(address tokenAddress, uint256 amount, address recipient, string memory description) public whenNotPaused nonReentrant {
        if (amount == 0 || recipient == address(0)) revert AethelgardForge__InvalidAmount();
        if (_vAethelBalance[msg.sender] < minAethelToPropose) revert AethelgardForge__InsufficientVAethel();

        uint256 proposalId = _proposalIds.current();
        _proposalIds.increment();

        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.data = bytes(""); // No specific data payload needed for this type, unless adding complexity
        proposal.state = ProposalState.Active;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + MIN_VOTING_PERIOD;
        proposal.targetTokenAddress = tokenAddress;
        proposal.targetAmount = amount;
        proposal.targetRecipient = recipient;

        emit TreasuryWithdrawalProposed(proposalId, msg.sender, tokenAddress, amount, recipient);
    }

    // Voting on treasury proposals is handled by the generic `voteOnProposal` function.

    /**
     * @dev Executes a winning treasury withdrawal proposal.
     * Requires the TREASURY_ROLE.
     * @param proposalId The ID of the treasury proposal.
     */
    function executeTreasuryProposal(uint256 proposalId) public whenNotPaused nonReentrant onlyRole(TREASURY_ROLE) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        if (proposal.state != ProposalState.Succeeded) revert AethelgardForge__ProposalCannotBeExecuted(); // Must have passed voting
        if (proposal.targetRecipient == address(0)) revert AethelgardForge__InvalidRecipient(); // Safety check

        address tokenAddress = proposal.targetTokenAddress;
        uint256 amount = proposal.targetAmount;
        address recipient = proposal.targetRecipient;

        if (tokenAddress == address(0)) {
            // Withdraw ETH
            if (address(this).balance < amount) revert AethelgardForge__InsufficientTreasuryBalance();
            (bool success, ) = payable(recipient).call{value: amount}("");
            if (!success) revert AethelgardForge__EtherTransferFailed();

        } else if (tokenAddress == address(this)) {
             // Withdraw AETHEL (ERC20) held by the contract
             if (balanceOf(address(this)) < amount) revert AethelgardForge__InsufficientTreasuryBalance();
             bool success = transfer(recipient, amount); // Transfer AETHEL
             if (!success) revert AethelgardForge__TokenTransferFailed();

        } else {
            // Withdraw other ERC20 tokens
            IERC20 externalToken = IERC20(tokenAddress);
            if (externalToken.balanceOf(address(this)) < amount) revert AethelgardForge__InsufficientTreasuryBalance();
            bool success = externalToken.transfer(recipient, amount); // Transfer external ERC20
            if (!success) revert AethelgardForge__TokenTransferFailed();
        }

        proposal.state = ProposalState.Executed; // Mark as executed

        emit TreasuryFundsCollected(tokenAddress, amount, recipient);
        emit ProposalExecuted(proposalId);
    }

     /**
      * @dev Sets the address that receives marketplace royalties.
      * Can be updated via governance.
      * @param _royaltyRecipient The new recipient address.
      */
     function setRoyaltyRecipient(address payable _royaltyRecipient) public onlyRole(GOVERNANCE_ROLE) {
         if (_royaltyRecipient == address(0)) revert AethelgardForge__InvalidRecipient();
         royaltyRecipient = _royaltyRecipient;
     }

     /**
      * @dev Sets the percentage of royalties collected from marketplace sales.
      * Can be updated via governance.
      * @param _rate The royalty rate in basis points (100 = 1%). Max 10000 (100%).
      */
     function setRoyaltyRate(uint96 _rate) public onlyRole(GOVERNANCE_ROLE) {
         if (_rate > 10000) revert AethelgardForge__InvalidAmount(); // Cap at 100%
         _royaltyRateBps = _rate;
     }

     /**
      * @dev Gets the current royalty rate in basis points.
      */
     function getRoyaltyRate() public view returns (uint96) {
         return _royaltyRateBps;
     }

     /**
      * @dev Sets the AETHEL fee required for attempting to forge an Artifact.
      * Can be updated via governance.
      * @param fee The new fee amount.
      */
     function setForgeFee(uint256 fee) public onlyRole(GOVERNANCE_ROLE) {
         forgeFee = fee;
     }

      /**
      * @dev Gets the current AETHEL fee for forging.
      */
     function getForgeFee() public view returns (uint256) {
         return forgeFee;
     }


    /*═════════════════════════════════════════════════════════════════════
    ║                          UTILITY & VIEW FUNCTIONS                     ║
    ═════════════════════════════════════════════════════════════════════*/

     /**
      * @dev Mints new FORGE_ITEMs. Callable by MINTER_ROLE.
      * @param itemId The ID of the item type to mint.
      * @param amount The number of items to mint.
      * @param recipient The address to mint the items to.
      */
     function mintForgeItems(uint256 itemId, uint256 amount, address recipient) public onlyRole(MINTER_ROLE) {
         if (amount == 0 || recipient == address(0)) revert AethelgardForge__InvalidAmount();
         _mint(recipient, itemId, amount, ""); // Mint ERC1155
     }

     /**
      * @dev Returns the total number of ARTIFACTs minted.
      */
     function getArtifactTotalSupply() public view returns (uint256) {
         return _artifactIds.current();
     }

    // Required ERC721Enumerable overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Example dynamic constraint: Prevent transfer if the owner is staking the artifact (requires tracking)
        // This is complex as it requires mapping staked AETHEL to specific artifacts.
        // A simpler approach: If an Artifact trait indicates it's 'bound' by staking, prevent transfer.
        // if (ownerOf(tokenId) == from && _artifactProperties[tokenId].isBoundByStake) {
        //     revert AethelgardForge__CannotTransferStakedArtifact();
        // }
    }

     // Royalty Implementation for ERC721
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(ERC721Royalty)
        returns (address receiver, uint256 royaltyAmount)
    {
        // This uses the default royalty set via _setDefaultRoyalty or _setTokenRoyalty
        // when the artifact was minted. If you wanted dynamic royalties per artifact,
        // you could add logic here based on _artifactProperties[tokenId].
        return super.royaltyInfo(tokenId, salePrice);
    }


    // The contract is also the address for AETHEL, FORGE_ITEM, and ARTIFACT tokens
    // You can get their addresses by simply using `address(this)`.

    /**
     * @dev Returns the address of the AETHEL token (this contract).
     */
    function getAethelTokenAddress() public view returns (address) {
        return address(this);
    }

     /**
      * @dev Returns the address of the FORGE_ITEM token (this contract).
      */
     function getForgeItemTokenAddress() public view returns (address) {
         return address(this);
     }

     /**
      * @dev Returns the address of the ARTIFACT token (this contract).
      */
     function getArtifactTokenAddress() public view returns (address) {
         return address(this);
     }

     /**
      * @dev Returns the address representing vAETHEL staking power (this contract).
      * Note: vAETHEL is an internal concept, not a separate token contract address.
      */
     function getVAethelStakingTokenAddress() public view returns (address) {
         // This function is just for user clarity; vAETHEL isn't a separate contract.
         return address(this);
     }


     // Fallback function to receive Ether (for marketplace payments)
     receive() external payable {}

     // Optional: Add a withdrawETH function callable by TREASURY_ROLE if ETH balance
     // isn't solely managed via the governance proposal mechanism.
     // function withdrawETH(uint256 amount, address payable recipient) public onlyRole(TREASURY_ROLE) {
     //     if (address(this).balance < amount) revert AethelgardForge__InsufficientTreasuryBalance();
     //     recipient.sendValue(amount);
     // }
}
```