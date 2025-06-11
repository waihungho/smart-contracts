Okay, here is a concept for an advanced, creative, and trendy Solidity smart contract: a **Generative NFT Factory with Dynamic Traits and Community Curation**.

This contract combines:
1.  **Generative NFTs:** Traits for NFTs are determined programmatically on-chain (or pointers are assigned) at mint time, influenced by on-chain randomness.
2.  **Dynamic Metadata:** The `tokenURI` can change or be generated based on the NFT's assigned traits.
3.  **Trait Rarity & Weighting:** Configurable weights influence the probability of different traits being assigned.
4.  **Community Trait Curation:** A decentralized mechanism allows existing NFT holders to propose and vote on adding *new* traits that can be included in *future* mints.
5.  **Secure Randomness:** Integration with Chainlink VRF for provably fair and secure random number generation.

It's more than just minting; it's a system for evolving NFT collections based on community input and on-chain logic.

---

**Contract Name:** `GenerativeNFTFactory`

**Concept:** A factory contract to manage the creation, minting, and evolution of a generative NFT collection. NFT traits are determined upon minting using secure randomness. The collection's potential traits can be expanded through a community proposal and voting mechanism.

**Advanced Concepts & Creativity:**
*   **On-chain Trait Assignment influenced by VRF:** Traits aren't predefined per token ID, but assigned dynamically.
*   **Dynamic `tokenURI`:** Metadata is constructed based on assigned traits, potentially pointing to an API that renders the image or serves JSON based on these traits.
*   **Community Curation/DAO-like feature:** NFT holders can propose and vote on new traits, adding a layer of decentralized governance over the collection's future aesthetics/attributes.
*   **Trait Weighting & Rarity Simulation:** Implementation of weighted random selection.
*   **Provenance Tracking:** Storing the random seed used for each token's trait assignment.

**Outline & Function Summary:**

1.  **Imports:** Necessary OpenZeppelin libraries (ERC721, Ownable, Pausable, ReentrancyGuard) and Chainlink VRF interfaces/helpers.
2.  **Errors & Events:** Custom errors for clarity, events for significant actions (Mint, TraitAdded, ProposalCreated, VoteCast, etc.).
3.  **Enums & Structs:**
    *   `SaleState`: Enum (Paused, WhitelistOnly, PublicSale).
    *   `ProposalState`: Enum (Pending, Active, Succeeded, Failed, Executed).
    *   `TraitCategory`: Struct defining a category of traits (e.g., "Background", "Eyes"), total weight for randomness.
    *   `Trait`: Struct defining a specific trait within a category (name, URI component, rarity weight).
    *   `NFTAttributes`: Struct storing the assigned trait IDs for a specific token ID.
    *   `TraitProposal`: Struct for community proposals to add new traits (proposer, details, votes, state, expiration).
4.  **State Variables:** Mappings for trait categories, traits, NFT attributes, whitelists, trait proposals, VRF data; counters for token IDs, trait IDs, proposal IDs; contract configuration (name, symbol, max supply, price, base URI, VRF details); sale state; voting parameters.
5.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `onlySaleState`, `onlyNFTAmmountForVoting`.
6.  **Constructor:** Initializes ERC721, Ownable, VRF, name, symbol, max supply.
7.  **VRF Integration (`fulfillRandomness` override):** Callback function from Chainlink VRF, triggers the trait assignment logic.
8.  **Core Generative Logic (Internal):** Function to select traits based on weights and the random number.
9.  **External/Public Functions (> 20 total including inherited ERC721):**

    *   **ERC721 Standard (Inherited & Overridden):**
        1.  `balanceOf(address owner) view returns (uint256)`
        2.  `ownerOf(uint256 tokenId) view returns (address)`
        3.  `approve(address to, uint256 tokenId)`
        4.  `getApproved(uint256 tokenId) view returns (address)`
        5.  `setApprovalForAll(address operator, bool approved)`
        6.  `isApprovedForAll(address owner, address operator) view returns (bool)`
        7.  `transferFrom(address from, address to, uint256 tokenId)`
        8.  `safeTransferFrom(address from, address to, uint256 tokenId)`
        9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`
        10. `tokenURI(uint256 tokenId) view returns (string memory)` (OVERRIDDEN for dynamic metadata)

    *   **Ownership & Control (Ownable & Pausable):**
        11. `transferOwnership(address newOwner)`
        12. `pause()`
        13. `unpause()`
        14. `withdrawFunds()`

    *   **Factory Configuration:**
        15. `setBaseURI(string memory newBaseURI)`: Sets the base part of the `tokenURI`.
        16. `addTraitCategory(string memory name)`: Adds a new category like "Background".
        17. `addTraitToCategory(uint256 categoryId, string memory name, string memory uriComponent, uint256 weight)`: Adds a specific trait to a category with its visual identifier part and rarity weight.
        18. `updateTraitWeight(uint256 categoryId, uint256 traitId, uint256 newWeight)`: Adjusts the rarity weight of an existing trait.
        19. `setCategoryWeight(uint256 categoryId, uint256 totalWeight)`: Sets the total weight for a category for randomness calculation (can simplify if total is just sum of trait weights).

    *   **Sale Management:**
        20. `setPrice(uint256 newPrice)`: Sets the minting price.
        21. `toggleSaleState(SaleState newState)`: Moves between Paused, WhitelistOnly, PublicSale.
        22. `addToWhitelist(address[] memory addresses)`: Adds addresses for whitelist sale.
        23. `removeFromWhitelist(address[] memory addresses)`: Removes addresses from whitelist.
        24. `isWhitelisted(address wallet) view returns (bool)`: Checks if an address is whitelisted.

    *   **Minting:**
        25. `mint()`: Allows anyone (if in PublicSale) or whitelisted addresses (if in WhitelistOnly) to mint an NFT by paying the price. Requests VRF randomness.
        26. `mintWhitelist()`: Specific function for whitelist minting (optional, can be integrated into `mint`). *Let's keep `mint` and check state/whitelist inside.*

    *   **Community Trait Curation (The advanced part):**
        27. `proposeNewTrait(uint256 categoryId, string memory name, string memory uriComponent)`: Allows an NFT holder to propose a new trait for an existing category. Requires minimum NFT count.
        28. `voteForTraitProposal(uint256 proposalId, bool approve)`: Allows an NFT holder to vote on an active proposal (e.g., 1 NFT = 1 Vote). Votes are weighted by NFT holdings at the time of voting.
        29. `executeTraitProposal(uint256 proposalId)`: Executed by owner or a DAO mechanism (for simplicity, let's start with Owner after sufficient votes) if a proposal meets the threshold and expiration. Adds the proposed trait to the available traits.

    *   **Query/View Functions:**
        30. `getNFTAttributes(uint256 tokenId) view returns (uint256[] memory traitIds)`: Returns the array of trait IDs assigned to a specific token.
        31. `getTraitDetails(uint256 categoryId, uint256 traitId) view returns (string memory name, string memory uriComponent, uint256 weight)`: Gets details for a specific trait.
        32. `getTraitCategoryDetails(uint256 categoryId) view returns (string memory name, uint256 totalWeight, uint256[] memory traitIds)`: Gets details for a trait category including all trait IDs within it.
        33. `getTraitProposalDetails(uint256 proposalId) view returns (address proposer, uint256 categoryId, string memory name, string memory uriComponent, uint256 votesFor, uint256 votesAgainst, ProposalState state, uint256 expiration)`: Gets details of a trait proposal.
        34. `getTraitProposalVoteCount(uint256 proposalId) view returns (uint256 votesFor, uint256 votesAgainst)`: Gets current vote counts for a proposal.
        35. `getTotalMinted() view returns (uint256)`: Returns the current total supply.
        36. `getMaxSupply() view returns (uint256)`: Returns the maximum number of NFTs that can be minted.
        37. `getPrice() view returns (uint256)`: Returns the current minting price.
        38. `getSaleState() view returns (SaleState)`: Returns the current state of the sale.
        39. `getPausedState() view returns (bool)`: Returns whether the contract is paused.
        40. `getTraitProposalVoteThreshold() view returns (uint256)`: Returns the minimum votes required for a proposal to pass.
        41. `getTraitProposalExpiration() view returns (uint256)`: Returns the duration (in seconds) for proposal voting.

    *   **Internal Helper Functions:**
        *   `_assignTraitsToToken(uint256 tokenId, uint256 randomNumber)`: Selects traits based on weights and randomness and stores them for the token. (Called by `fulfillRandomness`)
        *   `_requestRandomWords()`: Handles the VRF request logic. (Called by `mint`)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/AbstractVRFConsumerV2.sol";

// --- Outline & Function Summary ---
//
// Contract: GenerativeNFTFactory
// Concept: A factory contract for a generative NFT collection. NFT traits are assigned on-chain at mint time using secure randomness (Chainlink VRF). The available trait pool can be expanded through a community trait proposal and voting system by existing NFT holders.
//
// Advanced Concepts: On-chain generative logic, VRF integration, Dynamic Metadata (via tokenURI override), Community Curation (DAO-like trait voting), Weighted Randomness.
//
// State: Paused, WhitelistOnly, PublicSale.
//
// Enums & Structs:
// - SaleState: Current state of the NFT sale.
// - ProposalState: State of a community trait proposal.
// - TraitCategory: Defines a category of traits (e.g., Backgrounds).
// - Trait: Defines a specific trait within a category (name, URI component, rarity weight).
// - NFTAttributes: Stores the assigned trait IDs for a token.
// - TraitProposal: Details of a community proposal to add a new trait.
//
// State Variables:
// - Core ERC721/NFT: _totalSupply, maxSupply, _tokenAttributes, _baseTokenURI.
// - Sale: price, saleState, _whitelist.
// - Generative/Traits: _nextTraitCategoryId, _nextTraitId, _traitCategories, _traits, _categoryTraitIds.
// - VRF: vrfCoordinator, keyHash, subscriptionId, requestConfirmations, s_requests, s_randomWords.
// - Community Curation: _nextProposalId, _traitProposals, _votedOnProposal.
// - Access Control: Ownable.
// - State Control: Pausable.
//
// Functions (> 20 total, including inherited):
//
// -- ERC721 Standard (Inherited & Overridden) --
// 1.  balanceOf(address owner) view returns (uint256)
// 2.  ownerOf(uint256 tokenId) view returns (address)
// 3.  approve(address to, uint256 tokenId)
// 4.  getApproved(uint256 tokenId) view returns (address)
// 5.  setApprovalForAll(address operator, bool approved)
// 6.  isApprovedForAll(address owner, address operator) view returns (bool)
// 7.  transferFrom(address from, address to, uint256 tokenId)
// 8.  safeTransferFrom(address from, address to, uint256 tokenId)
// 9.  safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// 10. tokenURI(uint256 tokenId) view returns (string memory) - OVERRIDDEN for dynamic metadata
//
// -- Ownership & Control (Ownable & Pausable) --
// 11. transferOwnership(address newOwner)
// 12. pause()
// 13. unpause()
// 14. withdrawFunds()
//
// -- Factory Configuration --
// 15. setBaseURI(string memory newBaseURI) - Sets the base URL for metadata.
// 16. addTraitCategory(string memory name) - Adds a new category (e.g., "Body").
// 17. addTraitToCategory(uint256 categoryId, string memory name, string memory uriComponent, uint256 weight) - Adds a specific trait with its properties.
// 18. updateTraitWeight(uint256 categoryId, uint256 traitId, uint256 newWeight) - Adjusts trait rarity.
// 19. setCategoryWeight(uint256 categoryId, uint256 totalWeight) - Sets total weight for random selection within a category.
//
// -- Sale Management --
// 20. setPrice(uint256 newPrice) - Sets minting price.
// 21. toggleSaleState(SaleState newState) - Manages public/whitelist sale state.
// 22. addToWhitelist(address[] memory addresses) - Adds addresses for whitelisted minting.
// 23. removeFromWhitelist(address[] memory addresses) - Removes addresses from whitelist.
// 24. isWhitelisted(address wallet) view returns (bool) - Checks whitelist status.
//
// -- Minting --
// 25. mint() - Mints an NFT, requests VRF randomness, assigns token ID to the request.
//
// -- VRF Callback --
// 26. fulfillRandomness(uint64 requestId, uint256[] memory randomWords) - Chainlink VRF callback, assigns traits based on random number.
//
// -- Community Trait Curation --
// 27. proposeNewTrait(uint256 categoryId, string memory name, string memory uriComponent) - Allows holder to propose a trait addition.
// 28. voteForTraitProposal(uint256 proposalId, bool support) - Allows holder to vote on a proposal.
// 29. executeTraitProposal(uint256 proposalId) - Owner/System executes a passed proposal to add the trait.
//
// -- Query/View Functions --
// 30. getNFTAttributes(uint256 tokenId) view returns (uint256[] memory traitIds) - Gets assigned trait IDs for a token.
// 31. getTraitDetails(uint256 categoryId, uint256 traitId) view returns (string memory name, string memory uriComponent, uint256 weight) - Gets details of a specific trait.
// 32. getTraitCategoryDetails(uint256 categoryId) view returns (string memory name, uint256 totalWeight, uint256[] memory traitIds) - Gets details of a trait category.
// 33. getTraitProposalDetails(uint256 proposalId) view returns (address proposer, uint256 categoryId, string memory name, string memory uriComponent, uint256 votesFor, uint256 votesAgainst, ProposalState state, uint256 expiration) - Gets proposal details.
// 34. getTraitProposalVoteCount(uint256 proposalId) view returns (uint256 votesFor, uint256 votesAgainst) - Gets vote counts for a proposal.
// 35. getTotalMinted() view returns (uint256) - Current total supply.
// 36. getMaxSupply() view returns (uint256) - Max total supply.
// 37. getPrice() view returns (uint256) - Current mint price.
// 38. getSaleState() view returns (SaleState) - Current sale state.
// 39. getPausedState() view returns (bool) - Contract paused status.
// 40. getTraitProposalVoteThreshold() view returns (uint256) - Votes needed to pass proposal.
// 41. getTraitProposalExpiration() view returns (uint256) - Proposal voting duration.
//
// -- Internal Helper Functions --
// - _assignTraitsToToken(uint256 tokenId, uint256 randomNumber) - Selects and assigns traits using randomness.
// - _requestRandomWords() - Handles VRF request.
//
// --- End Outline & Function Summary ---


contract GenerativeNFTFactory is ERC721, Ownable, Pausable, ReentrancyGuard, AbstractVRFConsumerV2 {

    // --- Errors ---
    error MintPriceMismatch(uint256 requiredPrice, uint256 msgValue);
    error MaxSupplyReached();
    error NotWhitelisted();
    error AlreadyMintedForRandomness();
    error VRFRequestFailed(string reason);
    error TraitCategoryNotFound(uint256 categoryId);
    error TraitNotFound(uint256 categoryId, uint256 traitId);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotActive(uint256 proposalId);
    error ProposalAlreadyVoted(uint256 proposalId, address voter);
    error ProposalThresholdNotMet(uint256 proposalId);
    error ProposalStillActive(uint256 proposalId);
    error ProposalExpired(uint256 proposalId);
    error OnlyNFTHolders();
    error NotEnoughNFTsForProposalOrVoting(uint256 required, uint256 owned);
    error InvalidTraitWeight(uint256 weight);
    error TraitAlreadyExists(uint256 categoryId, string name);
    error InvalidTraitOrCategoryData();


    // --- Events ---
    event NFTMinted(uint256 indexed tokenId, address indexed minter, uint64 indexed requestId);
    event TraitsAssigned(uint256 indexed tokenId, uint256 indexed requestId, uint256[] traitIds);
    event SaleStateChanged(SaleState newState);
    event PriceChanged(uint256 newPrice);
    event BaseURIChanged(string newBaseURI);
    event TraitCategoryAdded(uint256 indexed categoryId, string name);
    event TraitAdded(uint256 indexed categoryId, uint256 indexed traitId, string name, string uriComponent, uint256 weight);
    event TraitWeightUpdated(uint256 indexed categoryId, uint256 indexed traitId, uint256 newWeight);
    event CategoryWeightUpdated(uint256 indexed categoryId, uint256 totalWeight);
    event TraitProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 categoryId, string name);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint252 voteWeight, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event WhitelistUpdated(address indexed wallet, bool added);

    // --- Enums ---
    enum SaleState { Paused, WhitelistOnly, PublicSale }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---
    struct TraitCategory {
        string name;
        uint256 totalWeight; // Total weight for random selection within this category
        uint256[] traitIds;  // List of trait IDs belonging to this category
    }

    struct Trait {
        string name;
        string uriComponent; // Part of the URI pointing to the visual representation (e.g., "blue_background.png")
        uint256 weight;      // Rarity weight for random selection
    }

    struct NFTAttributes {
        uint256[] traitIds; // traitIds are global IDs across all categories
        uint256 randomnessSeed; // The random number used for this token
    }

    struct TraitProposal {
        address proposer;
        uint256 categoryId;
        string name;
        string uriComponent;
        uint256 weight; // Proposed initial weight
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        uint256 expiration; // Timestamp when voting ends
    }

    // --- State Variables ---

    // NFT Core
    uint256 private _totalSupply;
    uint256 public immutable maxSupply;
    mapping(uint256 => NFTAttributes) private _tokenAttributes;
    string private _baseTokenURI; // Base URI for metadata, e.g., "ipfs://..." or "https://api.example.com/token/"

    // Sale
    uint256 private price; // Price in Wei
    SaleState public saleState;
    mapping(address => bool) private _whitelist;

    // Generative Traits
    uint256 private _nextTraitCategoryId = 1; // Start from 1
    mapping(uint256 => TraitCategory) private _traitCategories;
    mapping(uint256 => Trait) private _traits; // Global mapping of traits by a unique traitId
    mapping(uint256 => uint256[]) private _categoryTraitIds; // categoryId => array of traitIds
    uint256 private _nextTraitId = 1; // Start from 1

    // Chainlink VRF
    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    uint64 public immutable subscriptionId;
    bytes32 public immutable keyHash;
    uint32 public immutable requestConfirmations;
    uint32 public immutable callbackGasLimit = 200000; // Reasonable gas limit for the fulfillRandomness callback

    // Mapping requestId to the token ID being minted
    mapping(uint64 => uint256) private s_requests;
    // Mapping requestId to the address that requested the randomness
    mapping(uint64 => address) private s_requestAddress;

    // Community Curation (Trait Proposals)
    uint256 private _nextProposalId = 1; // Start from 1
    mapping(uint256 => TraitProposal) private _traitProposals;
    // proposalId => voterAddress => true (voted)
    mapping(uint256 => mapping(address => bool)) private _votedOnProposal;
    uint256 public traitProposalVoteThreshold = 50; // Minimum total vote weight (e.g., sum of token balances) to pass
    uint256 public traitProposalExpiration = 7 days; // Duration for voting on a proposal

    // Minimum NFT count required to propose or vote
    uint256 public minNFTsToPropose = 1;
    uint256 public minNFTsToVote = 1;


    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _price,
        address vrfCoordinatorV2,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _requestConfirmations
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
        AbstractVRFConsumerV2(vrfCoordinatorV2)
    {
        require(_maxSupply > 0, "Max supply must be > 0");
        maxSupply = _maxSupply;
        price = _price;
        saleState = SaleState.Paused; // Start paused

        // Chainlink VRF setup
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        requestConfirmations = _requestConfirmations;

        // Note: Subscription must be created and funded externally
        // Also, add this contract as a consumer on the VRF subscription
    }

    // --- Modifiers ---
    modifier onlySaleState(SaleState _state) {
        require(saleState == _state, "Invalid sale state");
        _;
    }

    modifier onlyNFTAmmountForProposal() {
        require(balanceOf(msg.sender) >= minNFTsToPropose, NotEnoughNFTsForProposalOrVoting(minNFTsToPropose, balanceOf(msg.sender)));
        _;
    }

     modifier onlyNFTAmmountForVoting() {
        require(balanceOf(msg.sender) >= minNFTsToVote, NotEnoughNFTsForProposalOrVoting(minNFTsToVote, balanceOf(msg.sender)));
        _;
    }

    // --- ERC721 Overrides ---

    /**
     * @dev Returns the URI for a given token ID. This is dynamic based on assigned traits.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        NFTAttributes storage attributes = _tokenAttributes[tokenId];
        if (attributes.traitIds.length == 0) {
            // Traits not yet assigned (e.g., VRF request pending)
            // Return a placeholder URI or an error indicator
            // For simplicity, return base URI + token ID with a pending indicator
             return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), "/pending"));
        }

        // Construct the metadata URI based on assigned traits
        // This assumes the base URI points to an API or gateway that
        // can interpret the list of trait IDs and return the correct metadata/image.
        // Example: "base_uri/token/123?traits=1,5,10" or "base_uri/metadata/123"
        // where the API looks up the traits stored on-chain via RPC.
        // Or, the base URI can point to a service that uses the trait URIs directly.

        string memory traitQuery = "";
        for (uint i = 0; i < attributes.traitIds.length; i++) {
            uint256 traitId = attributes.traitIds[i];
             // Validate trait existence defensively, though they should exist if assigned
            require(_traits[traitId].weight > 0, "Invalid assigned traitId"); // Check if trait exists (weight > 0 implies it was added)

            // Append trait URI component (assuming base URI handles formatting)
            // Example: constructing "traitComponent1/traitComponent2/..." or "?trait=ID1&trait=ID2..."
            // A common pattern is base_uri/tokenId -> API looks up attributes via RPC
            // or base_uri/tokenId/traitId1/traitId2/... -> API interprets path segments
             if (i > 0) {
                 traitQuery = string(abi.encodePacked(traitQuery, "/")); // Or "&trait=", etc.
             }
             traitQuery = string(abi.encodePacked(traitQuery, _traits[traitId].uriComponent));
        }

        // Example: Combining base URI with token ID and trait query
        // The final structure depends on your off-chain metadata/image hosting setup.
        // A simple pattern: base_uri/tokenId.json where the server queries the chain for traits
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
        // More complex example utilizing trait components directly (if off-chain service supports):
        // return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), "/", traitQuery, ".json"));
    }


    // --- Ownership & Control ---

    // transferOwnership is inherited from Ownable

    /**
     * @dev Pauses minting and other state-changing operations.
     * Only callable by the owner.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations again.
     * Only callable by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated funds.
     * Uses ReentrancyGuard.
     */
    function withdrawFunds() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    // --- Factory Configuration ---

    /**
     * @dev Sets the base URI for token metadata.
     * Only callable by the owner.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    /**
     * @dev Adds a new category for traits (e.g., "Eyes", "Mouth").
     * Only callable by the owner.
     * @param name The name of the trait category.
     */
    function addTraitCategory(string memory name) public onlyOwner {
        uint256 newCategoryId = _nextTraitCategoryId++;
        _traitCategories[newCategoryId] = TraitCategory(name, 0, new uint256[](0)); // totalWeight starts at 0
        emit TraitCategoryAdded(newCategoryId, name);
    }

    /**
     * @dev Adds a new trait to an existing category.
     * Only callable by the owner or via executed proposal.
     * @param categoryId The ID of the category to add the trait to.
     * @param name The name of the trait (e.g., "Blue Eyes").
     * @param uriComponent The URI component representing this trait (e.g., "blue_eyes.png").
     * @param weight The rarity weight of the trait. Must be > 0.
     */
    function addTraitToCategory(
        uint256 categoryId,
        string memory name,
        string memory uriComponent,
        uint256 weight
    ) public virtual onlyOwner { // Made virtual to allow overriding by execution function
        if (_traitCategories[categoryId].name.length == 0) revert TraitCategoryNotFound(categoryId);
        if (weight == 0) revert InvalidTraitWeight(0);
        if (bytes(name).length == 0 || bytes(uriComponent).length == 0) revert InvalidTraitOrCategoryData();

        // Optional: Check for duplicate trait names within the category if desired
        // require(!_traitExistsInCategory(categoryId, name), TraitAlreadyExists(categoryId, name));

        uint256 newTraitId = _nextTraitId++;
        _traits[newTraitId] = Trait(name, uriComponent, weight);
        _categoryTraitIds[categoryId].push(newTraitId);
        _traitCategories[categoryId].totalWeight += weight; // Update category total weight

        emit TraitAdded(categoryId, newTraitId, name, uriComponent, weight);
    }

    /**
     * @dev Updates the rarity weight of an existing trait.
     * Only callable by the owner.
     * @param categoryId The ID of the trait category.
     * @param traitId The ID of the trait to update.
     * @param newWeight The new weight. Must be > 0.
     */
    function updateTraitWeight(uint256 categoryId, uint256 traitId, uint256 newWeight) public onlyOwner {
         if (_traitCategories[categoryId].name.length == 0) revert TraitCategoryNotFound(categoryId);
         if (_traits[traitId].weight == 0) revert TraitNotFound(categoryId, traitId); // Check if trait exists globally

         // Ensure the traitId is actually in this category's list (defensive)
         bool found = false;
         for (uint i = 0; i < _categoryTraitIds[categoryId].length; i++) {
             if (_categoryTraitIds[categoryId][i] == traitId) {
                 found = true;
                 break;
             }
         }
         require(found, TraitNotFound(categoryId, traitId));

        uint256 oldWeight = _traits[traitId].weight;
        if (newWeight == 0) revert InvalidTraitWeight(0);

        _traits[traitId].weight = newWeight;
        _traitCategories[categoryId].totalWeight = _traitCategories[categoryId].totalWeight - oldWeight + newWeight;

        emit TraitWeightUpdated(categoryId, traitId, newWeight);
    }

    /**
     * @dev Manually sets the total weight for a trait category. Use with caution.
     * Usually, this weight is the sum of constituent trait weights. This allows overrides.
     * Only callable by the owner.
     * @param categoryId The ID of the trait category.
     * @param totalWeight The new total weight for randomness calculation in this category.
     */
    function setCategoryWeight(uint256 categoryId, uint256 totalWeight) public onlyOwner {
        if (_traitCategories[categoryId].name.length == 0) revert TraitCategoryNotFound(categoryId);
        _traitCategories[categoryId].totalWeight = totalWeight;
        emit CategoryWeightUpdated(categoryId, totalWeight);
    }


    // --- Sale Management ---

    /**
     * @dev Sets the price for minting an NFT.
     * Only callable by the owner.
     * @param newPrice The new price in Wei.
     */
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
        emit PriceChanged(newPrice);
    }

    /**
     * @dev Toggles the sale state (Paused, WhitelistOnly, PublicSale).
     * Only callable by the owner.
     * @param newState The target sale state.
     */
    function toggleSaleState(SaleState newState) public onlyOwner {
        saleState = newState;
        emit SaleStateChanged(newState);
    }

    /**
     * @dev Adds addresses to the whitelist.
     * Only callable by the owner.
     * @param addresses Array of addresses to add.
     */
    function addToWhitelist(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            if (!_whitelist[addresses[i]]) {
                _whitelist[addresses[i]] = true;
                emit WhitelistUpdated(addresses[i], true);
            }
        }
    }

    /**
     * @dev Removes addresses from the whitelist.
     * Only callable by the owner.
     * @param addresses Array of addresses to remove.
     */
    function removeFromWhitelist(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            if (_whitelist[addresses[i]]) {
                _whitelist[addresses[i]] = false;
                 emit WhitelistUpdated(addresses[i], false);
            }
        }
    }

    /**
     * @dev Checks if an address is on the whitelist.
     * @param wallet The address to check.
     * @return bool True if whitelisted, false otherwise.
     */
    function isWhitelisted(address wallet) public view returns (bool) {
        return _whitelist[wallet];
    }

    // --- Minting ---

    /**
     * @dev Mints a new NFT. Price must be paid. Sale state must allow minting.
     * Requests VRF randomness. Traits are assigned later in the VRF callback.
     * Uses ReentrancyGuard and Pausable.
     */
    function mint() public payable whenNotPaused nonReentrant {
        if (saleState == SaleState.WhitelistOnly && !_whitelist[msg.sender]) revert NotWhitelisted();
        if (saleState == SaleState.Paused) revert InvalidSaleState(); // Should be caught by whenNotPaused, but double check
        if (msg.value < price) revert MintPriceMismatch(price, msg.value);
        if (_totalSupply >= maxSupply) revert MaxSupplyReached();

        _totalSupply++;
        uint256 newTokenId = _totalSupply; // Token IDs are 1-based

        // ERC721 minting function handles ownership and existence checks
        _safeMint(msg.sender, newTokenId);

        // Request randomness for this token
        uint64 requestId = _requestRandomWords();
        s_requests[requestId] = newTokenId; // Map request ID to token ID
        s_requestAddress[requestId] = msg.sender; // Map request ID to minter address

        emit NFTMinted(newTokenId, msg.sender, requestId);

        // Note: Traits are NOT assigned here. They will be assigned in fulfillRandomness.
        // The tokenURI will initially return placeholder data until fulfillment.
    }

    // --- VRF Callback ---

    /**
     * @dev Callback function for Chainlink VRF. Receives random words.
     * Assigns traits to the pending token ID associated with the request.
     */
    function fulfillRandomness(
        uint64 requestId,
        uint256[] memory randomWords
    ) internal override {
        // Ensure the request ID is pending trait assignment
        uint256 tokenId = s_requests[requestId];
        address minter = s_requestAddress[requestId];
        require(tokenId > 0 && minter != address(0), "RequestId not pending");

        // Use the first random word for trait assignment
        uint256 randomNumber = randomWords[0];

        // Assign traits based on the random number
        _assignTraitsToToken(tokenId, randomNumber);

        // Clean up request data
        delete s_requests[requestId];
        delete s_requestAddress[requestId];

        emit TraitsAssigned(tokenId, requestId, _tokenAttributes[tokenId].traitIds);
    }

    /**
     * @dev Internal function to request random words from Chainlink VRF.
     * @return uint64 The request ID.
     */
    function _requestRandomWords() internal returns (uint64) {
         if (_totalSupply >= maxSupply) revert MaxSupplyReached(); // Double check supply before requesting
        uint64 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 // Request just one random word
        );
        return requestId;
    }

    /**
     * @dev Internal function to assign traits to a token ID based on a random number.
     * This is where the core generative logic happens.
     * @param tokenId The ID of the token to assign traits to.
     * @param randomNumber The random number from VRF.
     */
    function _assignTraitsToToken(uint256 tokenId, uint256 randomNumber) internal {
        require(_exists(tokenId), "Token does not exist");
        require(_tokenAttributes[tokenId].traitIds.length == 0, "Traits already assigned"); // Ensure traits aren't double assigned

        uint256[] memory assignedTraitIds = new uint256[](_nextTraitCategoryId - 1); // Allocate array based on number of categories
        uint256 randomSeed = randomNumber; // Use the random number as the seed

        // Iterate through each trait category
        for (uint256 categoryId = 1; categoryId < _nextTraitCategoryId; categoryId++) {
            TraitCategory storage category = _traitCategories[categoryId];
            require(category.name.length > 0, "Invalid trait category data"); // Should exist

            if (category.totalWeight == 0 || category.traitIds.length == 0) {
                // Handle categories with no traits or zero total weight (e.g., assign a default or skip)
                // For this example, we'll assign a placeholder or skip the category if no traits are defined.
                // A more robust system would require at least one trait per category or a 'None' trait.
                 continue;
            }

            // Weighted random selection within the category
            uint256 cumulativeWeight = 0;
            uint256 randomChoice = randomSeed % category.totalWeight; // Use modulo with the current seed
            randomSeed = uint256(keccak256(abi.encodePacked(randomSeed, tokenId, categoryId))); // Update seed for next category

            uint256 selectedTraitId = 0; // Placeholder for the selected trait ID

            for (uint i = 0; i < category.traitIds.length; i++) {
                uint256 currentTraitId = category.traitIds[i];
                 // Ensure trait exists and has weight > 0
                if (_traits[currentTraitId].weight > 0) {
                    cumulativeWeight += _traits[currentTraitId].weight;
                    if (randomChoice < cumulativeWeight) {
                        selectedTraitId = currentTraitId;
                        break; // Trait selected
                    }
                }
            }

            // Assign the selected trait ID (should always find one if totalWeight > 0)
            require(selectedTraitId > 0, "Trait selection failed");
            assignedTraitIds[categoryId - 1] = selectedTraitId; // Store using category ID index offset

        }

        _tokenAttributes[tokenId] = NFTAttributes(assignedTraitIds, randomNumber);
    }

    // --- Community Trait Curation ---

    /**
     * @dev Allows an NFT holder to propose adding a new trait to a category.
     * Requires owning at least `minNFTsToPropose` NFTs.
     * @param categoryId The ID of the category to add the trait to.
     * @param name The name of the proposed trait.
     * @param uriComponent The URI component for the proposed trait.
     */
    function proposeNewTrait(
        uint256 categoryId,
        string memory name,
        string memory uriComponent
    ) public whenNotPaused onlyNFTAmmountForProposal {
        if (_traitCategories[categoryId].name.length == 0) revert TraitCategoryNotFound(categoryId);
        if (bytes(name).length == 0 || bytes(uriComponent).length == 0) revert InvalidTraitOrCategoryData();

        uint256 proposalId = _nextProposalId++;
        uint256 defaultWeight = 100; // Default weight for new proposals, can be changed on execution

        _traitProposals[proposalId] = TraitProposal({
            proposer: msg.sender,
            categoryId: categoryId,
            name: name,
            uriComponent: uriComponent,
            weight: defaultWeight, // Initial proposed weight
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            expiration: block.timestamp + traitProposalExpiration // Voting window starts now
        });

        emit TraitProposalCreated(proposalId, msg.sender, categoryId, name);
    }

    /**
     * @dev Allows an NFT holder to vote on an active trait proposal.
     * Requires owning at least `minNFTsToVote` NFTs.
     * Each owned NFT counts as 1 vote weight.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes', false for 'no'.
     */
    function voteForTraitProposal(uint256 proposalId, bool support) public whenNotPaused onlyNFTAmmountForVoting {
        TraitProposal storage proposal = _traitProposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(proposalId);
        if (block.timestamp > proposal.expiration) revert ProposalExpired(proposalId);
        if (_votedOnProposal[proposalId][msg.sender]) revert ProposalAlreadyVoted(proposalId, msg.sender);

        uint256 voterNFTBalance = balanceOf(msg.sender);
        require(voterNFTBalance > 0, "Must hold NFTs to vote"); // Should be caught by modifier, but defensive

        _votedOnProposal[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor += voterNFTBalance;
        } else {
            proposal.votesAgainst += voterNFTBalance;
        }

        emit VoteCast(proposalId, msg.sender, uint252(voterNFTBalance), support);

        // Optional: Automatically mark as succeeded/failed if threshold reached before expiration
        // if (proposal.votesFor >= traitProposalVoteThreshold) {
        //     proposal.state = ProposalState.Succeeded;
        // } else if (proposal.votesAgainst >= traitProposalVoteThreshold) { // Example: Could also have a threshold for 'against'
        //      proposal.state = ProposalState.Failed;
        // }
    }

    /**
     * @dev Executes a trait proposal that has reached its expiration and met the vote threshold.
     * Adds the proposed trait to the trait pool.
     * Can be called by anyone to finalize expired proposals, but only owner can finalize failed ones.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeTraitProposal(uint256 proposalId) public nonReentrant {
        TraitProposal storage proposal = _traitProposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(proposalId);
        if (block.timestamp <= proposal.expiration) revert ProposalStillActive(proposalId);

        if (proposal.votesFor >= traitProposalVoteThreshold) {
            proposal.state = ProposalState.Succeeded;

            // Add the proposed trait using the base addTraitToCategory logic
            // Use a new internal function or override `addTraitToCategory` to allow non-owner calls *only* from here.
            // For simplicity, let's add a new internal function for execution logic.
            _addTraitFromProposal(proposal.categoryId, proposal.name, proposal.uriComponent, proposal.weight);

            emit ProposalExecuted(proposalId, true);

        } else {
            // Proposal failed to meet threshold
            proposal.state = ProposalState.Failed;
            emit ProposalExecuted(proposalId, false);
        }
    }

    /**
     * @dev Internal helper to add a trait from a successfully executed proposal.
     * Separated from addTraitToCategory to control access.
     * @param categoryId The ID of the category.
     * @param name The trait name.
     * @param uriComponent The trait URI component.
     * @param weight The trait weight.
     */
    function _addTraitFromProposal(
        uint256 categoryId,
        string memory name,
        string memory uriComponent,
        uint256 weight
    ) internal {
         if (_traitCategories[categoryId].name.length == 0) revert TraitCategoryNotFound(categoryId); // Should not happen if proposal is valid
         if (weight == 0) revert InvalidTraitWeight(0); // Should not happen if proposal is valid
         if (bytes(name).length == 0 || bytes(uriComponent).length == 0) revert InvalidTraitOrCategoryData(); // Should not happen

        uint256 newTraitId = _nextTraitId++;
        _traits[newTraitId] = Trait(name, uriComponent, weight);
        _categoryTraitIds[categoryId].push(newTraitId);
        _traitCategories[categoryId].totalWeight += weight;

         // Use a different event or add a flag if needed to distinguish manual adds vs proposal adds
        emit TraitAdded(categoryId, newTraitId, name, uriComponent, weight);
    }


    // --- Query/View Functions ---

    /**
     * @dev Returns the array of trait IDs assigned to a specific token.
     * @param tokenId The ID of the token.
     * @return uint256[] An array of trait IDs. Empty if not found or traits not yet assigned.
     */
    function getNFTAttributes(uint256 tokenId) public view returns (uint256[] memory traitIds) {
        if (!_exists(tokenId)) return new uint256[](0);
        return _tokenAttributes[tokenId].traitIds;
    }

    /**
     * @dev Gets details for a specific trait.
     * @param categoryId The ID of the trait category.
     * @param traitId The ID of the trait.
     * @return string Name of the trait.
     * @return string URI component of the trait.
     * @return uint256 Rarity weight of the trait.
     */
    function getTraitDetails(uint256 categoryId, uint256 traitId) public view returns (string memory name, string memory uriComponent, uint256 weight) {
        if (_traitCategories[categoryId].name.length == 0) revert TraitCategoryNotFound(categoryId);
        Trait storage trait = _traits[traitId];
        if (trait.weight == 0) revert TraitNotFound(categoryId, traitId); // TraitId might exist, but weight 0 implies it wasn't added properly

        // Optional: Add check if traitId belongs to categoryId for stricter validation
        // require(isTraitInCategory(categoryId, traitId), "Trait ID not in category"); // Requires implementing isTraitInCategory helper

        return (trait.name, trait.uriComponent, trait.weight);
    }

    /**
     * @dev Gets details for a trait category.
     * @param categoryId The ID of the trait category.
     * @return string Name of the category.
     * @return uint256 Total weight for randomness selection in this category.
     * @return uint256[] Array of trait IDs within this category.
     */
    function getTraitCategoryDetails(uint256 categoryId) public view returns (string memory name, uint256 totalWeight, uint256[] memory traitIds) {
        TraitCategory storage category = _traitCategories[categoryId];
        if (category.name.length == 0) revert TraitCategoryNotFound(categoryId);
        return (category.name, category.totalWeight, category.traitIds);
    }

    /**
     * @dev Gets details for a trait proposal.
     * @param proposalId The ID of the proposal.
     * @return address Proposer address.
     * @return uint256 Category ID.
     * @return string Trait name.
     * @return string Trait URI component.
     * @return uint256 Votes for the proposal.
     * @return uint256 Votes against the proposal.
     * @return ProposalState Current state of the proposal.
     * @return uint256 Timestamp of proposal expiration.
     */
    function getTraitProposalDetails(uint256 proposalId) public view returns (
        address proposer,
        uint256 categoryId,
        string memory name,
        string memory uriComponent,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state,
        uint256 expiration
    ) {
        TraitProposal storage proposal = _traitProposals[proposalId];
        if (proposal.proposer == address(0) && proposalId != 0) revert ProposalNotFound(proposalId); // ID 0 is invalid

        return (
            proposal.proposer,
            proposal.categoryId,
            proposal.name,
            proposal.uriComponent,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.state,
            proposal.expiration
        );
    }

    /**
     * @dev Gets current vote counts for a proposal.
     * @param proposalId The ID of the proposal.
     * @return uint256 Votes for the proposal.
     * @return uint256 Votes against the proposal.
     */
    function getTraitProposalVoteCount(uint256 proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
         TraitProposal storage proposal = _traitProposals[proposalId];
        if (proposal.proposer == address(0) && proposalId != 0) revert ProposalNotFound(proposalId);
         return (proposal.votesFor, proposal.votesAgainst);
    }


    // Standard ERC721 functions inherited: ownerOf, balanceOf, getApproved, isApprovedForAll, etc.

    /**
     * @dev Returns the total number of NFTs minted.
     */
    function getTotalMinted() public view returns (uint256) {
        return _totalSupply;
    }

    // getMaxSupply() is a public state variable

    // getPrice() is a public state variable

    // getSaleState() is a public state variable

    // getPausedState() is inherited from Pausable (paused())

    // traitProposalVoteThreshold is a public state variable

    // traitProposalExpiration is a public state variable

    /**
     * @dev Returns the next available trait category ID. Useful for off-chain tools.
     */
     function getNextTraitCategoryId() public view returns (uint256) {
         return _nextTraitCategoryId;
     }

     /**
      * @dev Returns the next available trait ID. Useful for off-chain tools.
      */
      function getNextTraitId() public view returns (uint256) {
          return _nextTraitId;
      }

    /**
     * @dev Returns the next available proposal ID. Useful for off-chain tools.
     */
     function getNextProposalId() public view returns (uint256) {
         return _nextProposalId;
     }

    /**
     * @dev Check if a specific address has voted on a proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address of the voter.
     * @return bool True if the address has voted, false otherwise.
     */
     function hasVotedOnProposal(uint256 proposalId, address voter) public view returns (bool) {
         return _votedOnProposal[proposalId][voter];
     }

    // minNFTsToPropose and minNFTsToVote are public state variables

}
```