Okay, here is a Solidity smart contract implementing a "Dynamic NFT Marketplace with AI-Enhanced Traits".

This contract combines several concepts:
1.  **Dynamic NFTs (DNFTs):** NFT traits can change over time.
2.  **Marketplace:** Users can list, buy, and bid on DNFTs.
3.  **AI Integration (Simulated):** An designated "AI Oracle" address can update DNFT traits based on off-chain AI analysis or events.
4.  **Staking:** Owners can stake their DNFTs to potentially earn rewards or influence trait changes.
5.  **Royalties:** Configurable royalties for creators/minters on secondary sales.
6.  **Trait Gating:** Certain features or access might be linked to specific DNFT traits.

The AI integration is simulated by having a trusted `aiOracleAddress` that is authorized to call the trait update function. In a real-world scenario, this would likely be connected to an off-chain service that runs AI models and uses an oracle network (like Chainlink) or a secure relay mechanism to trigger the on-chain state changes.

This contract uses OpenZeppelin libraries for standard patterns like `Ownable`, `ERC721`, and `ReentrancyGuard` (though not strictly necessary for all functions, it's good practice for payments). The ERC721 implementation is custom here to directly manage the `DNFT` struct, which is slightly different from extending the standard library one directly, but includes the necessary interfaces.

---

**Contract: DynamicNFTMarketplaceWithAIIntegration**

**Outline:**

1.  **License and Pragma**
2.  **Imports:** OpenZeppelin libraries (Ownable, ReentrancyGuard, Counters, ERC721 interfaces/helpers)
3.  **Error Definitions**
4.  **Event Definitions:** For key actions (Mint, List, Buy, Bid, TraitUpdate, Stake, RoyaltyPaid, etc.)
5.  **Struct Definitions:**
    *   `DNFT`: Represents a single dynamic NFT.
    *   `TraitDefinition`: Defines a possible trait type (name, data type, mutability).
    *   `Listing`: Represents an NFT listing on the marketplace.
    *   `Bid`: Represents a bid on an NFT listing.
    *   `StakingInfo`: Stores staking details for a DNFT.
6.  **State Variables:**
    *   Contract owner, AI Oracle address.
    *   Marketplace state variables (fees, paused).
    *   Counters for token IDs.
    *   Mappings for DNFT data, ownership, approvals (ERC721).
    *   Mappings for marketplace listings, bids.
    *   Mappings for trait definitions and values.
    *   Mappings for staking info, accumulated rewards.
    *   Mapping for royalty percentages.
7.  **Modifiers:** Access control (`onlyOwner`, `onlyAIOracle`, `whenNotPaused`), state checks (`onlyDNFTOwner`, `onlyApprovedOrOwner`).
8.  **Constructor:** Initializes owner, AI Oracle, fees.
9.  **Core ERC721 Functions (Custom Implementation):** `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `totalSupply`, `tokenURI` (basic placeholder).
10. **Minting:** `mintDNFT`
11. **Trait Management:**
    *   `addPossibleTrait`
    *   `removePossibleTrait`
    *   `submitAIUpdatedTraits` (AI Oracle call)
    *   `freezeTraits`
    *   `unfreezeTraits`
    *   `getPossibleTraits` (View)
    *   `getDNFTTraits` (View)
    *   `getDNFTTraitHistory` (View - simple version)
12. **Marketplace Functions:**
    *   `listDNFTForSale`
    *   `cancelListing`
    *   `buyDNFT` (Payable)
    *   `placeBid` (Payable)
    *   `acceptBid`
    *   `removeBid`
    *   `getListing` (View)
    *   `getBids` (View)
13. **Staking Functions:**
    *   `stakeDNFT`
    *   `unstakeDNFT`
    *   `claimStakingRewards` (Placeholder reward calculation)
    *   `getStakingInfo` (View)
    *   `getStakingRewards` (View - Placeholder)
14. **Royalty Functions:**
    *   `setRoyaltyPercentage`
    *   `withdrawRoyalties`
    *   `getRoyaltyInfo` (View)
15. **Utility/Gating Functions:**
    *   `isFeatureUnlocked` (Based on traits)
    *   `burnDNFT`
16. **Admin Functions:**
    *   `setAIOracleAddress`
    *   `setMarketplaceFee`
    *   `togglePause`
    *   `setMinTraitUpdateInterval`
    *   `emergencyWithdraw`
17. **Internal Helpers:** (`_transfer`, `_mint`, `_burn`, `_updateTraits`, `_calculateRoyalty`, `_calculateStakingReward` - placeholder)

**Function Summary (20+ functions):**

1.  `constructor(address initialAIOracle)`: Initializes the contract, setting the initial AI Oracle address and owner.
2.  `mintDNFT(address to, string memory initialMetadataURI, string[] memory initialTraitNames, string[] memory initialTraitValues)`: Mints a new Dynamic NFT with initial metadata and traits.
3.  `balanceOf(address owner)`: Returns the number of NFTs owned by an address (ERC721).
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT (ERC721).
5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an NFT (ERC721).
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership safely (ERC721).
7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Transfers ownership safely with data (ERC721).
8.  `approve(address to, uint256 tokenId)`: Approves an address to manage an NFT (ERC721).
9.  `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all owner's NFTs (ERC721).
10. `getApproved(uint256 tokenId)`: Returns the approved address for an NFT (ERC721).
11. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner (ERC721).
12. `totalSupply()`: Returns the total number of NFTs minted (ERC721).
13. `tokenURI(uint256 tokenId)`: Returns the metadata URI for an NFT (ERC721, placeholder).
14. `addPossibleTrait(string memory traitName, uint8 dataType, bool isMutable)`: Defines a new possible trait type. Only callable by owner. `dataType` could map to internal types (e.g., 0 for string, 1 for uint).
15. `removePossibleTrait(string memory traitName)`: Removes a possible trait definition. Only callable by owner.
16. `submitAIUpdatedTraits(uint256 tokenId, string[] memory traitNames, string[] memory traitValues)`: Allows the designated AI Oracle to update specific traits for a DNFT. Checks mutability and update intervals.
17. `freezeTraits(uint256 tokenId, string[] memory traitNames)`: Freezes specific traits on a DNFT, preventing further AI updates until unfrozen. Callable by owner or potentially DNFT owner/approved.
18. `unfreezeTraits(uint256 tokenId, string[] memory traitNames)`: Unfreezes specific traits. Callable by owner or potentially DNFT owner/approved.
19. `getPossibleTraits()`: View function returning the list of defined possible traits.
20. `getDNFTTraits(uint256 tokenId)`: View function returning the current values of all traits for a specific DNFT.
21. `getDNFTTraitHistory(uint256 tokenId, string memory traitName)`: View function returning a simple history (e.g., last few updates) for a specific trait. (Simplified implementation for demo).
22. `listDNFTForSale(uint256 tokenId, uint256 price)`: Lists an owned NFT for sale on the marketplace at a fixed price. Requires NFT approval.
23. `cancelListing(uint256 tokenId)`: Cancels an active listing for an owned NFT.
24. `buyDNFT(uint256 tokenId)`: Purchases an NFT listed for sale. Handles payment and transfers, including marketplace fees and royalties.
25. `placeBid(uint256 tokenId)`: Places a bid on an NFT listing (requires sending ether >= current highest bid + minimum increment, not implemented).
26. `acceptBid(uint256 tokenId, address bidder)`: Accepts a bid from a specific bidder. Handles payment and transfers, fees, royalties. Only callable by seller.
27. `removeBid(uint256 tokenId)`: Removes the caller's bid on an NFT.
28. `getListing(uint256 tokenId)`: View function returning details of an active listing for an NFT.
29. `getBids(uint256 tokenId)`: View function returning a list of active bids for an NFT. (Simplified, maybe just highest bid).
30. `stakeDNFT(uint256 tokenId)`: Stakes an owned DNFT to enable staking-related features/rewards. Requires NFT approval.
31. `unstakeDNFT(uint256 tokenId)`: Unstakes a previously staked DNFT.
32. `claimStakingRewards(uint256 tokenId)`: Claims accumulated staking rewards for a specific DNFT. (Placeholder calculation).
33. `getStakingInfo(uint256 tokenId)`: View function returning staking details for a DNFT.
34. `getStakingRewards(uint256 tokenId)`: View function returning potential accumulated rewards for staking (Placeholder calculation).
35. `setRoyaltyPercentage(uint256 tokenId, uint96 percentage)`: Sets the royalty percentage for a specific DNFT (usually set at mint, but allowing override by owner/minter). `percentage` is out of 10,000 (e.g., 500 for 5%).
36. `withdrawRoyalties()`: Allows minters/creators to withdraw accumulated royalty earnings.
37. `getRoyaltyInfo(uint256 tokenId, uint256 salePrice)`: View function calculating the royalty amount for a potential sale.
38. `isFeatureUnlocked(uint256 tokenId, string memory requiredTraitName, string memory requiredTraitValue)`: Utility function checking if a DNFT has a specific trait value, potentially used for gating access to external features.
39. `burnDNFT(uint256 tokenId)`: Destroys an owned DNFT.
40. `setAIOracleAddress(address newOracle)`: Sets the address authorized to submit AI trait updates. Only callable by owner.
41. `setMarketplaceFee(uint256 feePercentage)`: Sets the marketplace fee percentage. Only callable by owner.
42. `togglePause()`: Pauses/unpauses core contract functionality (minting, trading). Only callable by owner.
43. `setMinTraitUpdateInterval(uint256 intervalInSeconds)`: Sets the minimum time interval between AI trait updates for a single DNFT. Only callable by owner.
44. `emergencyWithdraw()`: Allows the owner to withdraw contract balance in an emergency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title DynamicNFTMarketplaceWithAIIntegration
/// @author [Your Name/Handle]
/// @notice A smart contract for a marketplace handling Dynamic NFTs (DNFTs) with AI-updatable traits, staking, and royalties.
/// @dev This contract simulates AI integration via a trusted AI Oracle address. Off-chain infrastructure would be needed for actual AI analysis and oracle calls.

// Outline:
// 1. License and Pragma
// 2. Imports
// 3. Error Definitions
// 4. Event Definitions
// 5. Struct Definitions (DNFT, TraitDefinition, Listing, Bid, StakingInfo)
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Core ERC721 Functions (Custom Implementation)
// 10. Minting
// 11. Trait Management (AI Integration Point)
// 12. Marketplace Functions
// 13. Staking Functions
// 14. Royalty Functions
// 15. Utility/Gating Functions
// 16. Admin Functions
// 17. Internal Helpers

// Function Summary (20+ functions):
// constructor(address initialAIOracle)
// mintDNFT(address to, string memory initialMetadataURI, string[] memory initialTraitNames, string[] memory initialTraitValues)
// balanceOf(address owner)
// ownerOf(uint256 tokenId)
// transferFrom(address from, address to, uint256 tokenId)
// safeTransferFrom(address from, address to, uint256 tokenId)
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// approve(address to, uint256 tokenId)
// setApprovalForAll(address operator, bool approved)
// getApproved(uint256 tokenId)
// isApprovedForAll(address owner, address operator)
// totalSupply()
// tokenURI(uint256 tokenId) // Placeholder
// addPossibleTrait(string memory traitName, uint8 dataType, bool isMutable)
// removePossibleTrait(string memory traitName)
// submitAIUpdatedTraits(uint256 tokenId, string[] memory traitNames, string[] memory traitValues)
// freezeTraits(uint256 tokenId, string[] memory traitNames)
// unfreezeTraits(uint256 tokenId, string[] memory traitNames)
// getPossibleTraits()
// getDNFTTraits(uint256 tokenId)
// getDNFTTraitHistory(uint256 tokenId, string memory traitName) // Simple history
// listDNFTForSale(uint256 tokenId, uint256 price)
// cancelListing(uint256 tokenId)
// buyDNFT(uint256 tokenId)
// placeBid(uint256 tokenId)
// acceptBid(uint256 tokenId, address bidder)
// removeBid(uint256 tokenId)
// getListing(uint256 tokenId)
// getBids(uint256 tokenId) // Simple, e.g., highest bid
// stakeDNFT(uint256 tokenId)
// unstakeDNFT(uint256 tokenId)
// claimStakingRewards(uint256 tokenId) // Placeholder reward calculation
// getStakingInfo(uint256 tokenId)
// getStakingRewards(uint256 tokenId) // Placeholder calculation
// setRoyaltyPercentage(uint256 tokenId, uint96 percentage)
// withdrawRoyalties()
// getRoyaltyInfo(uint256 tokenId, uint256 salePrice)
// isFeatureUnlocked(uint256 tokenId, string memory requiredTraitName, string memory requiredTraitValue)
// burnDNFT(uint256 tokenId)
// setAIOracleAddress(address newOracle)
// setMarketplaceFee(uint256 feePercentage)
// togglePause()
// setMinTraitUpdateInterval(uint256 intervalInSeconds)
// emergencyWithdraw()

contract DynamicNFTMarketplaceWithAIIntegration is Ownable, ReentrancyGuard, IERC721, IERC721Metadata {
    using Counters for Counters.Counter;
    using Address for address payable;

    // --- Error Definitions ---
    error InvalidTraitData();
    error TraitNotFound();
    error TraitNotMutable(string traitName);
    error TraitUpdateTooFrequent(uint256 nextUpdateTime);
    error NotApprovedOrOwner();
    error NotApprovedOrOperator();
    error TokenDoesNotExist();
    error NotForSale();
    error InsufficientPayment();
    error InvalidSeller();
    error ListingCancelled();
    error NoActiveBid();
    error BidTooLow(); // For placeBid, not implemented in detail
    error NotStaked();
    error AlreadyStaked();
    error NotOwner();
    error NotMinter(); // Assuming minter is the first owner
    error InvalidRoyaltyPercentage();
    error NoRoyaltiesDue();
    error ContractPaused();
    error InvalidTraitDataType(string traitName, uint8 expectedType, uint8 receivedType); // Added for robustness

    // --- Events ---
    event DNFTMinted(uint256 indexed tokenId, address indexed owner, string metadataURI);
    event TraitDefinitionAdded(string indexed traitName, uint8 dataType, bool isMutable);
    event TraitDefinitionRemoved(string indexed traitName);
    event DNFTTraitUpdated(uint256 indexed tokenId, string indexed traitName, string oldValue, string newValue, uint256 timestamp); // Using string for simplicity
    event TraitsFrozen(uint256 indexed tokenId, string[] traitNames);
    event TraitsUnfrozen(uint256 indexed tokenId, string[] traitNames);
    event DNFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event DNFTListingCancelled(uint256 indexed tokenId);
    event DNFTBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price, uint256 feeAmount, uint256 royaltyAmount);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event BidAccepted(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event BidRemoved(uint256 indexed tokenId, address indexed bidder);
    event DNFTStaked(uint256 indexed tokenId, address indexed owner);
    event DNFTUnstaked(uint256 indexed tokenId, address indexed owner);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 rewardAmount);
    event RoyaltyPercentageSet(uint256 indexed tokenId, uint96 percentage);
    event RoyaltiesWithdrawn(address indexed minter, uint256 amount);
    event AIOracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event MarketplaceFeeUpdated(uint256 oldFee, uint256 newFee);
    event Paused(address account);
    event Unpaused(address account);
    event MinTraitUpdateIntervalUpdated(uint256 oldInterval, uint256 newInterval);
    event DNFTBurned(uint256 indexed tokenId);

    // --- Struct Definitions ---

    struct DNFT {
        address owner;
        string initialMetadataURI;
        // Using string to store trait values for simplicity across data types (will need careful parsing off-chain)
        mapping(string => string) currentTraits;
        // Simple history mapping: traitName => array of [timestamp, value] (string)
        mapping(string => string[]) traitHistory; // Simplified history
        mapping(string => uint256) lastTraitUpdateTime; // To enforce min update interval
        mapping(string => bool) frozenTraits; // Traits that cannot be updated by AI Oracle
        address minter; // To track who receives royalties
    }

    struct TraitDefinition {
        uint8 dataType; // 0: string, 1: uint256, 2: bool, etc. (Define mapping elsewhere)
        bool isMutable; // Can this trait be updated by the AI Oracle?
        // Future: Add validation rules or possible values here
    }

    struct Listing {
        address seller;
        uint256 price;
        bool isCancelled;
        uint256 startTime;
    }

    struct Bid {
        address bidder;
        uint256 amount; // Bid amount in wei
        uint256 timestamp;
    }

    struct StakingInfo {
        address owner; // Redundant, but useful
        uint256 startTime;
        bool isStaked;
        // Placeholder: accumulated rewards - real staking might be more complex
        uint256 accumulatedRewards;
    }

    // --- State Variables ---

    address public aiOracleAddress;
    uint256 public marketplaceFeePercentage = 250; // 2.5% (out of 10000)
    uint256 public minTraitUpdateInterval = 1 hours; // Minimum time between AI updates per trait
    bool public paused = false;

    Counters.Counter private _tokenIdCounter;

    // ERC721 Core Storage
    mapping(uint256 => DNFT) private _d窑NFTS;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Trait Definitions & State
    mapping(string => TraitDefinition) public possibleTraits;
    string[] private _possibleTraitNames; // To iterate over defined traits

    // Marketplace Storage
    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => mapping(address => Bid)) private _bids; // tokenId => bidder => Bid
    mapping(uint256 => address[]) private _bidders; // To iterate over bidders for a token

    // Staking Storage
    mapping(uint256 => StakingInfo) private _stakingInfo;
    // Placeholder: Staking reward rate (e.g., per second per token)
    uint256 public stakingRewardRate = 100; // Example: 100 wei per second per staked token

    // Royalty Storage
    mapping(uint256 => uint96) private _royaltyPercentages; // percentage out of 10000
    mapping(address => uint256) private _pendingRoyalties;

    // --- Modifiers ---

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert OwnableUnauthorizedAccount(msg.sender); // Use Ownable's error for clarity
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert ContractPaused();
        }
        _;
    }

    modifier onlyDNFTOwner(uint256 tokenId) {
        if (_d窑NFTS[tokenId].owner != msg.sender) {
             revert NotOwner();
        }
        _;
    }

     modifier onlyApprovedOrOwner(uint256 tokenId) {
        if (_d窑NFTS[tokenId].owner != msg.sender && !isApprovedForAll(_d窑NFTS[tokenId].owner, msg.sender) && _tokenApprovals[tokenId] != msg.sender) {
             revert NotApprovedOrOwner();
        }
        _;
    }

    // --- Constructor ---

    constructor(address initialAIOracle) Ownable(msg.sender) {
        if (initialAIOracle == address(0)) revert OwnableInvalidOwner(address(0)); // Using Ownable's error
        aiOracleAddress = initialAIOracle;
        emit AIOracleAddressUpdated(address(0), initialAIOracle);
    }

    // --- Core ERC721 Functions (Custom Implementation) ---

    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ERC721InvalidOwner(address(0)); // Using ERC721 error
        return _balances[owner];
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _d窑NFTS[tokenId].owner;
        if (owner == address(0)) revert TokenDoesNotExist(); // Custom error for clarity
        return owner;
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (!_isApprovedOrOwner(_d窑NFTS[tokenId].owner, tokenId)) revert NotApprovedOrOwner(); // Custom check
        if (from != _d窑NFTS[tokenId].owner) revert ERC777InvalidSender(from); // Using ERC777 error (standard practice)
        if (to == address(0)) revert ERC721InvalidReceiver(address(0));

        _transfer(from, to, tokenId);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (!_isApprovedOrOwner(_d窑NFTS[tokenId].owner, tokenId)) revert NotApprovedOrOwner(); // Custom check
        if (from != _d窑NFTS[tokenId].owner) revert ERC777InvalidSender(from);
        if (to == address(0)) revert ERC721InvalidReceiver(address(0));

        _transfer(from, to, tokenId);
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to); // Using ERC721 error
                }
            } catch (bytes memory reason) {
                revert ERC721InvalidReceiver(to); // Using ERC721 error
            }
        }
    }

    /// @dev See {IERC721-approve}.
    function approve(address to, uint256 tokenId) public override whenNotPaused {
        address owner = _d窑NFTS[tokenId].owner;
        if (owner == address(0)) revert TokenDoesNotExist();
        if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) {
            revert NotApprovedOrOwner(); // Custom error
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert ERC721InvalidOperator(address(0)); // Using ERC721 error
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _tokenApprovals[tokenId];
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @dev See {IERC721Metadata-tokenURI}. (Placeholder)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        // In a real implementation, construct URI based on _dNFTs[tokenId].initialMetadataURI and current traits
        return _d窑NFTS[tokenId].initialMetadataURI;
    }

    /// @notice Returns the total number of tokens in existence.
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- Minting ---

    /// @notice Mints a new Dynamic NFT.
    /// @param to The address to mint the NFT to.
    /// @param initialMetadataURI The initial metadata URI for the NFT.
    /// @param initialTraitNames The names of the initial traits.
    /// @param initialTraitValues The values of the initial traits.
    function mintDNFT(
        address to,
        string memory initialMetadataURI,
        string[] memory initialTraitNames,
        string[] memory initialTraitValues
    ) public onlyOwner whenNotPaused returns (uint256) {
        if (initialTraitNames.length != initialTraitValues.length) revert InvalidTraitData();
        if (to == address(0)) revert ERC721InvalidReceiver(address(0));

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        DNFT storage newDNFT = _d窑NFTS[newItemId];
        newDNFT.owner = to;
        newDNFT.initialMetadataURI = initialMetadataURI;
        newDNFT.minter = msg.sender; // Minter is the contract deployer in this case

        // Set initial traits and record history
        for (uint i = 0; i < initialTraitNames.length; i++) {
            string memory name = initialTraitNames[i];
            string memory value = initialTraitValues[i];

            if (bytes(name).length == 0) revert InvalidTraitData();

            // No need to check possibleTraits definition on mint, allow any initial traits
            newDNFT.currentTraits[name] = value;
            newDNFT.traitHistory[name].push(string(abi.encodePacked(uint256(block.timestamp), ":", value))); // Simple encoding
            newDNFT.lastTraitUpdateTime[name] = block.timestamp;
        }

        _balances[to]++;
        emit DNFTMinted(newItemId, to, initialMetadataURI);
        emit Transfer(address(0), to, newItemId); // ERC721 Transfer event for minting

        return newItemId;
    }

    // --- Trait Management ---

    /// @notice Defines a new possible trait type that DNFTs can have.
    /// @param traitName The name of the trait (e.g., "Mood", "PowerLevel").
    /// @param dataType An identifier for the trait's data type (0: string, 1: uint256, 2: bool, etc.).
    /// @param isMutable Whether this trait can be updated by the AI Oracle.
    function addPossibleTrait(string memory traitName, uint8 dataType, bool isMutable) public onlyOwner {
        if (bytes(traitName).length == 0) revert InvalidTraitData();
        if (possibleTraits[traitName].dataType != 0 || !possibleTraits[traitName].isMutable) { // Check if it already exists
             _possibleTraitNames.push(traitName);
        }
        possibleTraits[traitName] = TraitDefinition(dataType, isMutable);
        emit TraitDefinitionAdded(traitName, dataType, isMutable);
    }

    /// @notice Removes a possible trait definition.
    /// @dev This does NOT remove the trait from existing NFTs, only prevents future definition use.
    /// @param traitName The name of the trait to remove.
    function removePossibleTrait(string memory traitName) public onlyOwner {
        if (bytes(traitName).length == 0 || possibleTraits[traitName].dataType == 0 && !possibleTraits[traitName].isMutable) { // Check if it exists
            revert TraitNotFound();
        }

        delete possibleTraits[traitName];

        // Remove from the names array (inefficient for large arrays, but ok for modest trait counts)
        for (uint i = 0; i < _possibleTraitNames.length; i++) {
            if (keccak256(abi.encodePacked(_possibleTraitNames[i])) == keccak256(abi.encodePacked(traitName))) {
                _possibleTraitNames[i] = _possibleTraitNames[_possibleTraitNames.length - 1];
                _possibleTraitNames.pop();
                break;
            }
        }
        emit TraitDefinitionRemoved(traitName);
    }

    /// @notice Allows the AI Oracle to update specific traits for a DNFT.
    /// @dev Only callable by the designated AI Oracle address.
    /// @param tokenId The ID of the DNFT to update.
    /// @param traitNames The names of the traits to update.
    /// @param traitValues The new values for the traits (as strings).
    function submitAIUpdatedTraits(uint256 tokenId, string[] memory traitNames, string[] memory traitValues) public onlyAIOracle whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (traitNames.length != traitValues.length) revert InvalidTraitData();

        DNFT storage dnft = _d窑NFTS[tokenId];

        for (uint i = 0; i < traitNames.length; i++) {
            string memory name = traitNames[i];
            string memory value = traitValues[i];

            TraitDefinition storage definition = possibleTraits[name];

            // Check if trait is defined and mutable
            if (definition.dataType == 0 && !definition.isMutable && bytes(name).length > 0) { // Assuming default struct is all zeros/false
                revert TraitNotFound(); // Or maybe allow adding new traits via AI? For this contract, require definition first.
            }
            if (!definition.isMutable) {
                 revert TraitNotMutable(name);
            }
             if (dnft.frozenTraits[name]) {
                // Skip if trait is frozen
                continue;
            }

            // Check update interval
            if (block.timestamp < dnft.lastTraitUpdateTime[name] + minTraitUpdateInterval) {
                revert TraitUpdateTooFrequent(dnft.lastTraitUpdateTime[name] + minTraitUpdateInterval);
            }

            // Validate value format against dataType (basic check - string allows anything)
            // More complex validation needed for uint/bool etc. For simplicity, storing all as string.
            // if (definition.dataType == 1) { // uint256
            //     try uint256(bytes(value)) {} catch { revert InvalidTraitDataType(name, definition.dataType, ...); }
            // }

            string memory oldValue = dnft.currentTraits[name];
            dnft.currentTraits[name] = value;
            dnft.traitHistory[name].push(string(abi.encodePacked(uint256(block.timestamp), ":", value))); // Simple encoding
            dnft.lastTraitUpdateTime[name] = block.timestamp;

            emit DNFTTraitUpdated(tokenId, name, oldValue, value, block.timestamp);
        }
    }

    /// @notice Freezes specific traits on a DNFT, preventing AI updates.
    /// @param tokenId The ID of the DNFT.
    /// @param traitNames The names of the traits to freeze.
    function freezeTraits(uint256 tokenId, string[] memory traitNames) public onlyApprovedOrOwner(tokenId) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         DNFT storage dnft = _d窑NFTS[tokenId];
         for(uint i=0; i < traitNames.length; i++){
             string memory name = traitNames[i];
             if (bytes(name).length == 0 || possibleTraits[name].dataType == 0 && !possibleTraits[name].isMutable) {
                 revert TraitNotFound();
             }
             dnft.frozenTraits[name] = true;
         }
         emit TraitsFrozen(tokenId, traitNames);
    }

    /// @notice Unfreezes specific traits on a DNFT, allowing AI updates again.
    /// @param tokenId The ID of the DNFT.
    /// @param traitNames The names of the traits to unfreeze.
     function unfreezeTraits(uint256 tokenId, string[] memory traitNames) public onlyApprovedOrOwner(tokenId) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         DNFT storage dnft = _d窑NFTS[tokenId];
         for(uint i=0; i < traitNames.length; i++){
             string memory name = traitNames[i];
             if (bytes(name).length == 0 || possibleTraits[name].dataType == 0 && !possibleTraits[name].isMutable) {
                 revert TraitNotFound();
             }
             dnft.frozenTraits[name] = false;
         }
         emit TraitsUnfrozen(tokenId, traitNames);
    }

    /// @notice Gets the list of all defined possible trait names and their definitions.
    /// @return An array of trait names, data types, and mutability flags.
    function getPossibleTraits() public view returns (string[] memory, uint8[] memory, bool[] memory) {
        uint256 count = _possibleTraitNames.length;
        string[] memory names = new string[](count);
        uint8[] memory dataTypes = new uint8[](count);
        bool[] memory mutability = new bool[](count);

        for(uint i = 0; i < count; i++) {
            string memory name = _possibleTraitNames[i];
            names[i] = name;
            TraitDefinition storage definition = possibleTraits[name];
            dataTypes[i] = definition.dataType;
            mutability[i] = definition.isMutable;
        }
        return (names, dataTypes, mutability);
    }

    /// @notice Gets the current trait values for a specific DNFT.
    /// @param tokenId The ID of the DNFT.
    /// @return An array of trait names and their current values (as strings).
    function getDNFTTraits(uint256 tokenId) public view returns (string[] memory, string[] memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        DNFT storage dnft = _d窑NFTS[tokenId];
        uint256 traitCount = 0;
        // Count existing traits on the token (might differ from possibleTraits)
        for (uint i = 0; i < _possibleTraitNames.length; i++) {
            if (bytes(dnft.currentTraits[_possibleTraitNames[i]]).length > 0) {
                 traitCount++;
            }
        }
        // Also count traits not in possibleTraits but existing on token
        // This requires iterating mapping keys, which is not directly possible.
        // A better approach would be to store trait names in the DNFT struct itself.
        // For this example, we'll return only the traits defined in possibleTraits that the token has.
        string[] memory names = new string[](traitCount);
        string[] memory values = new string[](traitCount);
        uint currentIdx = 0;
         for (uint i = 0; i < _possibleTraitNames.length; i++) {
            string memory name = _possibleTraitNames[i];
            if (bytes(dnft.currentTraits[name]).length > 0) {
                names[currentIdx] = name;
                values[currentIdx] = dnft.currentTraits[name];
                currentIdx++;
            }
        }
        // Note: Traits added to a token without being defined in possibleTraits won't appear here currently.
        return (names, values);
    }

    /// @notice Gets the history of values for a specific trait on a DNFT.
    /// @dev This returns a simplified history (e.g., last few updates).
    /// @param tokenId The ID of the DNFT.
    /// @param traitName The name of the trait.
    /// @return An array of timestamped trait values (as strings).
    function getDNFTTraitHistory(uint256 tokenId, string memory traitName) public view returns (string[] memory) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         // Simple history stored as concatenated strings
         return _d窑NFTS[tokenId].traitHistory[traitName];
    }


    // --- Marketplace Functions ---

    /// @notice Lists an owned DNFT for sale on the marketplace.
    /// @param tokenId The ID of the DNFT to list.
    /// @param price The asking price in wei.
    function listDNFTForSale(uint256 tokenId, uint256 price) public whenNotPaused onlyDNFTOwner(tokenId) {
        if (_exists(tokenId)) {
            address owner = _d窑NFTS[tokenId].owner;
             if (owner != msg.sender) revert NotOwner(); // Redundant due to modifier, but explicit
             // Must be approved for the marketplace contract to transfer
             if (getApproved(tokenId) != address(this) && !isApprovedForAll(owner, address(this))) {
                 revert NotApprovedOrOperator();
             }
        } else {
            revert TokenDoesNotExist();
        }

        // Cancel any existing listing first
        if (_listings[tokenId].seller != address(0)) {
            _listings[tokenId].isCancelled = true;
             emit DNFTListingCancelled(tokenId);
        }

        _listings[tokenId] = Listing(msg.sender, price, false, block.timestamp);
        emit DNFTListed(tokenId, msg.sender, price);
    }

    /// @notice Cancels an active listing for an owned DNFT.
    /// @param tokenId The ID of the DNFT listing to cancel.
    function cancelListing(uint256 tokenId) public whenNotPaused nonReentrant onlyDNFTOwner(tokenId) {
        Listing storage listing = _listings[tokenId];
        if (listing.seller == address(0) || listing.isCancelled) revert NotForSale();
        if (listing.seller != msg.sender) revert InvalidSeller();

        listing.isCancelled = true;
        // Could also clear bids here, but not strictly necessary if listing is cancelled

        emit DNFTListingCancelled(tokenId);
    }

    /// @notice Buys a listed DNFT at the fixed price.
    /// @param tokenId The ID of the DNFT to buy.
    function buyDNFT(uint256 tokenId) public payable whenNotPaused nonReentrant {
        Listing storage listing = _listings[tokenId];
        if (listing.seller == address(0) || listing.isCancelled) revert NotForSale();
        if (_exists(tokenId) && _d窑NFTS[tokenId].owner == listing.seller) {
            // Check ownership consistency
        } else {
             revert TokenDoesNotExist(); // Or listing invalid state
        }

        uint256 price = listing.price;
        if (msg.value < price) revert InsufficientPayment();

        address seller = listing.seller;
        address buyer = msg.sender;

        listing.isCancelled = true; // Mark as sold by cancelling listing

        // Calculate fees and royalties
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 10000;
        uint256 royaltyAmount = _calculateRoyalty(tokenId, price);
        uint256 amountToSeller = price - marketplaceFee - royaltyAmount;

        // Clear approvals before transfer
        _tokenApprovals[tokenId] = address(0);

        // Perform transfer
        _transfer(seller, buyer, tokenId); // This also updates internal _dNFTs owner & balances

        // Distribute funds
        payable(owner()).sendValue(marketplaceFee); // Marketplace fee to contract owner
        if (royaltyAmount > 0) {
            address minter = _d窑NFTS[tokenId].minter;
            if (minter != address(0)) {
                _pendingRoyalties[minter] += royaltyAmount;
                emit RoyaltyPaid(tokenId, minter, royaltyAmount);
            } else {
                 // Should not happen if minter is set on mint
                payable(seller).sendValue(royaltyAmount); // Send to seller if minter unknown
            }
        }
        payable(seller).sendValue(amountToSeller); // Seller receives the rest

        // Refund any overpayment
        if (msg.value > price) {
            payable(msg.sender).sendValue(msg.value - price);
        }

        emit DNFTBought(tokenId, buyer, seller, price, marketplaceFee, royaltyAmount);

        // Optional: Clear bids after a sale
        // delete _bids[tokenId]; // Requires iterating bidders or storing map of bidders
        // delete _bidders[tokenId];
    }

    /// @notice Places a bid on a listed DNFT.
    /// @dev Simple implementation: Only the highest bid is tracked per bidder.
    /// @param tokenId The ID of the DNFT to bid on.
    function placeBid(uint256 tokenId) public payable whenNotPaused nonReentrant {
        Listing storage listing = _listings[tokenId];
        if (listing.seller == address(0) || listing.isCancelled) revert NotForSale();
        if (listing.seller == msg.sender) revert InvalidSeller(); // Cannot bid on your own listing
        if (msg.value == 0) revert BidTooLow(); // Basic minimum bid

        // Refund previous bid if exists
        if (_bids[tokenId][msg.sender].amount > 0) {
            payable(msg.sender).sendValue(_bids[tokenId][msg.sender].amount);
        } else {
            // Add bidder to list if new bid
            _bidders[tokenId].push(msg.sender); // Inefficient for many bidders, consider alternative
        }

        _bids[tokenId][msg.sender] = Bid(msg.sender, msg.value, block.timestamp);
        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    /// @notice Accepts a specific bid on a listed DNFT.
    /// @param tokenId The ID of the DNFT listing.
    /// @param bidder The address of the bidder whose bid is accepted.
    function acceptBid(uint256 tokenId, address bidder) public whenNotPaused nonReentrant onlyDNFTOwner(tokenId) {
        Listing storage listing = _listings[tokenId];
        if (listing.seller == address(0) || listing.isCancelled || listing.seller != msg.sender) revert NotForSale(); // Check seller validity again
        Bid storage bid = _bids[tokenId][bidder];
        if (bid.amount == 0) revert NoActiveBid(); // No bid exists or already processed

        address seller = msg.sender; // Owner is seller
        address buyer = bidder;
        uint256 price = bid.amount; // Sale price is the bid amount

        listing.isCancelled = true; // Mark as sold

        // Calculate fees and royalties
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 10000;
        uint256 royaltyAmount = _calculateRoyalty(tokenId, price);
        uint256 amountToSeller = price - marketplaceFee - royaltyAmount;

        // Clear approvals before transfer
        _tokenApprovals[tokenId] = address(0);

        // Perform transfer
        _transfer(seller, buyer, tokenId); // This also updates internal _dNFTs owner & balances

        // Distribute funds (from the bid amount held by the contract)
        payable(owner()).sendValue(marketplaceFee); // Marketplace fee
         if (royaltyAmount > 0) {
            address minter = _d窑NFTS[tokenId].minter;
            if (minter != address(0)) {
                _pendingRoyalties[minter] += royaltyAmount;
                emit RoyaltyPaid(tokenId, minter, royaltyAmount);
            } else {
                 payable(seller).sendValue(royaltyAmount);
            }
        }
        payable(seller).sendValue(amountToSeller); // Seller

        // Refund other bidders
        address[] memory biddersToRefund = _bidders[tokenId];
        for(uint i = 0; i < biddersToRefund.length; i++) {
            address currentBidder = biddersToRefund[i];
            if (currentBidder != bidder) {
                 if (_bids[tokenId][currentBidder].amount > 0) {
                    payable(currentBidder).sendValue(_bids[tokenId][currentBidder].amount);
                    delete _bids[tokenId][currentBidder];
                 }
            }
        }
        // Delete the accepted bid and bidders list
        delete _bids[tokenId][bidder];
        delete _bidders[tokenId];


        emit BidAccepted(tokenId, bidder, price);
        emit DNFTBought(tokenId, buyer, seller, price, marketplaceFee, royaltyAmount); // Use Buy event for bid acceptance too
    }

    /// @notice Removes the caller's bid on an NFT.
    /// @param tokenId The ID of the DNFT.
    function removeBid(uint256 tokenId) public whenNotPaused nonReentrant {
         if (_bids[tokenId][msg.sender].amount == 0) revert NoActiveBid();

         uint256 bidAmount = _bids[tokenId][msg.sender].amount;
         delete _bids[tokenId][msg.sender];

         // Remove bidder from the list (inefficient)
         address[] storage bidders = _bidders[tokenId];
         for(uint i = 0; i < bidders.length; i++) {
             if (bidders[i] == msg.sender) {
                 bidders[i] = bidders[bidders.length - 1];
                 bidders.pop();
                 break;
             }
         }

         payable(msg.sender).sendValue(bidAmount);
         emit BidRemoved(tokenId, msg.sender);
    }

    /// @notice Gets details about a listing.
    /// @param tokenId The ID of the DNFT.
    /// @return seller The seller's address.
    /// @return price The listing price.
    /// @return isCancelled Whether the listing is cancelled/sold.
    /// @return startTime The listing start time.
    function getListing(uint256 tokenId) public view returns (address seller, uint256 price, bool isCancelled, uint256 startTime) {
        Listing storage listing = _listings[tokenId];
        return (listing.seller, listing.price, listing.isCancelled, listing.startTime);
    }

    /// @notice Gets the highest bid and its details for a listing.
    /// @dev Returns a simple highest bid structure. To get all bids, would need to iterate _bidders.
    /// @param tokenId The ID of the DNFT.
    /// @return bidder The address of the highest bidder.
    /// @return amount The highest bid amount.
    /// @return timestamp The timestamp of the highest bid.
    function getBids(uint256 tokenId) public view returns (address bidder, uint256 amount, uint256 timestamp) {
        // Iterate through bidders list to find highest bid
        uint256 highestAmount = 0;
        address highestBidder = address(0);
        uint256 highestTimestamp = 0;

        address[] memory bidders = _bidders[tokenId]; // Copy to memory for iteration
        for(uint i = 0; i < bidders.length; i++) {
            address currentBidder = bidders[i];
            Bid storage currentBid = _bids[tokenId][currentBidder];
            if (currentBid.amount > highestAmount) {
                highestAmount = currentBid.amount;
                highestBidder = currentBidder;
                highestTimestamp = currentBid.timestamp;
            }
        }
        return (highestBidder, highestAmount, highestTimestamp);
    }

    // --- Staking Functions ---

    /// @notice Stakes an owned DNFT.
    /// @param tokenId The ID of the DNFT to stake.
    function stakeDNFT(uint256 tokenId) public whenNotPaused nonReentrant onlyDNFTOwner(tokenId) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         if (_stakingInfo[tokenId].isStaked) revert AlreadyStaked();

         // Clear any listing/approval before staking
         if (_listings[tokenId].seller != address(0) && !_listings[tokenId].isCancelled) {
             _listings[tokenId].isCancelled = true;
             emit DNFTListingCancelled(tokenId);
         }
         _tokenApprovals[tokenId] = address(0); // Revoke any approval

         _stakingInfo[tokenId] = StakingInfo(msg.sender, block.timestamp, true, _stakingInfo[tokenId].accumulatedRewards); // Keep previous rewards
         // Ownership is NOT transferred to the contract, only state changes
         emit DNFTStaked(tokenId, msg.sender);
    }

    /// @notice Unstakes a previously staked DNFT.
    /// @param tokenId The ID of the DNFT to unstake.
     function unstakeDNFT(uint256 tokenId) public whenNotPaused nonReentrant onlyDNFTOwner(tokenId) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (!_stakingInfo[tokenId].isStaked) revert NotStaked();

        // Claim rewards automatically or require separate call? Let's require separate call for clarity.
        // _calculateStakingReward(tokenId); // Update accumulated rewards before unstaking

        _stakingInfo[tokenId].isStaked = false;
        _stakingInfo[tokenId].startTime = 0; // Reset start time
        // Do NOT reset accumulatedRewards here, claimStakingRewards will handle it

        emit DNFTUnstaked(tokenId, msg.sender);
     }

    /// @notice Claims accumulated staking rewards for a staked DNFT.
    /// @dev Placeholder: Reward calculation is very basic.
    /// @param tokenId The ID of the DNFT.
     function claimStakingRewards(uint256 tokenId) public whenNotPaused nonReentrant {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        address owner = _d窑NFTS[tokenId].owner;
        if (owner != msg.sender) revert NotOwner();
        if (!_stakingInfo[tokenId].isStaked) revert NotStaked();

        uint256 rewards = _calculateStakingReward(tokenId); // Calculate up to current time

        if (rewards == 0) revert NoRoyaltiesDue(); // Use similar error

        // Add rewards to accumulated and reset calculation period
        _stakingInfo[tokenId].accumulatedRewards += rewards;
        _stakingInfo[tokenId].startTime = block.timestamp; // Reset start time for future calculation

        uint256 totalRewardsToClaim = _stakingInfo[tokenId].accumulatedRewards;
        _stakingInfo[tokenId].accumulatedRewards = 0; // Clear for next cycle

        // Transfer rewards (assuming contract holds rewards)
        // In a real system, rewards might come from a separate token or pool.
        // For this example, assume contract has ETH balance.
        if (address(this).balance < totalRewardsToClaim) {
             // Handle insufficient balance - maybe send what's available or revert
             totalRewardsToClaim = address(this).balance;
             if (totalRewardsToClaim == 0) revert NoRoyaltiesDue();
        }

        payable(msg.sender).sendValue(totalRewardsToClaim);

        emit StakingRewardsClaimed(tokenId, msg.sender, totalRewardsToClaim);
     }

    /// @notice Gets the staking information for a DNFT.
    /// @param tokenId The ID of the DNFT.
    /// @return owner The owner's address.
    /// @return startTime The staking start time.
    /// @return isStaked Whether the DNFT is currently staked.
     function getStakingInfo(uint256 tokenId) public view returns (address owner, uint256 startTime, bool isStaked) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         StakingInfo storage info = _stakingInfo[tokenId];
         return (info.owner, info.startTime, info.isStaked);
     }

    /// @notice Gets the currently accrued, unclaimed staking rewards for a DNFT.
    /// @dev Placeholder calculation.
    /// @param tokenId The ID of the DNFT.
     function getStakingRewards(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
         if (!_stakingInfo[tokenId].isStaked) return _stakingInfo[tokenId].accumulatedRewards; // Return accumulated even if not staked

        return _stakingInfo[tokenId].accumulatedRewards + _calculateStakingReward(tokenId);
     }


    // --- Royalty Functions ---

    /// @notice Sets the royalty percentage for a specific DNFT.
    /// @param tokenId The ID of the DNFT.
    /// @param percentage The royalty percentage out of 10,000 (e.g., 500 for 5%).
    function setRoyaltyPercentage(uint256 tokenId, uint96 percentage) public onlyOwner { // Maybe minter?
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        // Only owner (contract deployer) can set royalties on creation for simplicity
        // If minter != owner, would need minter check here.
        if (percentage > 10000) revert InvalidRoyaltyPercentage(); // Max 100%

        _royaltyPercentages[tokenId] = percentage;
        emit RoyaltyPercentageSet(tokenId, percentage);
    }

    /// @notice Allows minters to withdraw their pending royalty earnings.
    function withdrawRoyalties() public nonReentrant {
        address minter = msg.sender; // Assumes the caller is a minter
        uint256 amount = _pendingRoyalties[minter];

        if (amount == 0) revert NoRoyaltiesDue();

        _pendingRoyalties[minter] = 0; // Reset before sending

        // Check contract balance before sending
        if (address(this).balance < amount) {
             amount = address(this).balance; // Send partial if insufficient balance
             if (amount == 0) revert NoRoyaltiesDue(); // Still zero?
        }

        payable(minter).sendValue(amount);

        emit RoyaltiesWithdrawn(minter, amount);
    }

    /// @notice Gets the royalty information for a specific DNFT and potential sale price.
    /// @param tokenId The ID of the DNFT.
    /// @param salePrice The potential sale price.
    /// @return receiver The address receiving royalties (the minter).
    /// @return royaltyAmount The calculated royalty amount.
    function getRoyaltyInfo(uint256 tokenId, uint256 salePrice) public view returns (address receiver, uint256 royaltyAmount) {
        if (!_exists(tokenId)) {
             // Return zero royalty for non-existent tokens
             return (address(0), 0);
        }
        address minter = _d窑NFTS[tokenId].minter;
        uint96 percentage = _royaltyPercentages[tokenId];
        uint256 calculatedAmount = (salePrice * percentage) / 10000;
        return (minter, calculatedAmount);
    }


    // --- Utility/Gating Functions ---

    /// @notice Checks if a DNFT has a specific trait with a specific value.
    /// @dev Can be used by external applications for feature gating based on traits.
    /// @param tokenId The ID of the DNFT.
    /// @param requiredTraitName The name of the required trait.
    /// @param requiredTraitValue The required value for the trait (as string).
    /// @return True if the DNFT has the trait and its value matches.
    function isFeatureUnlocked(uint256 tokenId, string memory requiredTraitName, string memory requiredTraitValue) public view returns (bool) {
        if (!_exists(tokenId)) return false;
        string memory currentValue = _d窑NFTS[tokenId].currentTraits[requiredTraitName];
        // Compare strings
        return keccak256(abi.encodePacked(currentValue)) == keccak256(abi.encodePacked(requiredTraitValue));
    }

    /// @notice Destroys a DNFT.
    /// @param tokenId The ID of the DNFT to burn.
    function burnDNFT(uint256 tokenId) public whenNotPaused nonReentrant onlyApprovedOrOwner(tokenId) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();

         address owner = _d窑NFTS[tokenId].owner;

         // Clear any listing, bids, staking, approvals
         if (_listings[tokenId].seller != address(0) && !_listings[tokenId].isCancelled) {
             _listings[tokenId].isCancelled = true;
             emit DNFTListingCancelled(tokenId);
         }
        // Refund bids if any (inefficient without iterating) - better handle via event/offchain
        // delete _bids[tokenId]; delete _bidders[tokenId];
         if (_stakingInfo[tokenId].isStaked) {
              // Potentially forfeit staking rewards or claim automatically? Forfeit for burn simplicity.
             delete _stakingInfo[tokenId]; // Remove staking info
             emit DNFTUnstaked(tokenId, owner); // Emit unstake event
         }
         _tokenApprovals[tokenId] = address(0); // Clear approval

         _burn(tokenId); // Use internal helper to update balances/ownership

         emit DNFTBurned(tokenId);
    }

    // --- Admin Functions ---

    /// @notice Sets the address authorized to submit AI trait updates.
    /// @param newOracle The address of the new AI Oracle.
    function setAIOracleAddress(address newOracle) public onlyOwner {
        if (newOracle == address(0)) revert OwnableInvalidOwner(address(0)); // Use Ownable error style
        address oldOracle = aiOracleAddress;
        aiOracleAddress = newOracle;
        emit AIOracleAddressUpdated(oldOracle, newOracle);
    }

    /// @notice Sets the marketplace fee percentage on sales.
    /// @param feePercentage The fee percentage out of 10,000 (e.g., 250 for 2.5%).
    function setMarketplaceFee(uint256 feePercentage) public onlyOwner {
        if (feePercentage > 10000) revert InvalidRoyaltyPercentage(); // Use royalty error
        uint256 oldFee = marketplaceFeePercentage;
        marketplaceFeePercentage = feePercentage;
        emit MarketplaceFeeUpdated(oldFee, feePercentage);
    }

    /// @notice Pauses core contract functionality (minting, trading, staking).
    function togglePause() public onlyOwner {
        paused = !paused;
        if (paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    /// @notice Sets the minimum time interval between AI trait updates for a single DNFT trait.
    /// @param intervalInSeconds The minimum interval in seconds.
    function setMinTraitUpdateInterval(uint256 intervalInSeconds) public onlyOwner {
        uint256 oldInterval = minTraitUpdateInterval;
        minTraitUpdateInterval = intervalInSeconds;
        emit MinTraitUpdateIntervalUpdated(oldInterval, intervalInSeconds);
    }

    /// @notice Allows the owner to withdraw the contract's ETH balance in case of emergency.
    function emergencyWithdraw() public onlyOwner nonReentrant {
         uint256 balance = address(this).balance;
         if (balance > 0) {
             payable(owner()).transfer(balance); // Use transfer for safety
         }
    }

    // --- Internal Helpers ---

    /// @dev Checks if a token exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _d窑NFTS[tokenId].owner != address(0);
    }

    /// @dev Checks if `msg.sender` is the owner or approved for `tokenId`.
    function _isApprovedOrOwner(address owner, uint256 tokenId) internal view returns (bool) {
        return (msg.sender == owner || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender));
    }

    /// @dev Transfers ownership of a token.
    ///      Clears approvals, updates balances and owner mappings in _dNFTs.
    function _transfer(address from, address to, uint256 tokenId) internal {
        // require(_dNFTs[tokenId].owner == from, "TransferFrom incorrect owner"); // Checked by caller
        // require(to != address(0), "Transfer to the zero address"); // Checked by caller

        _tokenApprovals[tokenId] = address(0); // Clear approvals

        _balances[from]--;
        _balances[to]++;
        _d窑NFTS[tokenId].owner = to; // Update owner in struct

        emit Transfer(from, to, tokenId);
    }

    /// @dev Mints a token. (Not used directly by mintDNFT, but standard helper pattern)
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert ERC721InvalidReceiver(address(0));
        if (_exists(tokenId)) revert ERC721AlreadyMinted(tokenId);

        _balances[to]++;
        _d窑NFTS[tokenId].owner = to; // Set owner in struct

        emit Transfer(address(0), to, tokenId);
    }

    /// @dev Burns a token.
     function _burn(uint256 tokenId) internal {
         address owner = _d窑NFTS[tokenId].owner;
         if (owner == address(0)) revert TokenDoesNotExist();

         _tokenApprovals[tokenId] = address(0); // Clear approval

         _balances[owner]--;
         delete _d窑NFTS[tokenId]; // Remove from storage

         emit Transfer(owner, address(0), tokenId);
     }


    /// @dev Internal helper to calculate royalty amount.
    function _calculateRoyalty(uint256 tokenId, uint256 salePrice) internal view returns (uint256) {
         uint96 percentage = _royaltyPercentages[tokenId];
         return (salePrice * percentage) / 10000;
    }

    /// @dev Internal helper to calculate staking rewards up to the current time.
    ///      This is a placeholder calculation.
    function _calculateStakingReward(uint256 tokenId) internal view returns (uint256) {
         StakingInfo storage info = _stakingInfo[tokenId];
         if (!info.isStaked || stakingRewardRate == 0) {
             return 0;
         }
         uint256 timeStaked = block.timestamp - info.startTime;
         return timeStaked * stakingRewardRate;
    }

     // Required for ERC721 compatibility, indicates which interfaces are supported.
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, Ownable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
             interfaceId == type(Ownable).interfaceId || // Ownable also supports IERC165
            super.supportsInterface(interfaceId);
    }

    // Fallback function to receive Ether, needed for marketplace payments and bids
    receive() external payable {}
    fallback() external payable {}
}
```