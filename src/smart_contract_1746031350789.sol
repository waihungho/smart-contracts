Okay, let's design an advanced and creative smart contract. We'll build a *Dynamic NFT Marketplace with Integrated Staking and State Evolution*.

**Concept:**

This contract isn't just a place to buy and sell NFTs. It allows users to stake their NFTs *within* the marketplace contract itself. While staked, the NFT's properties ("dynamic state") can evolve based on staking duration, accumulated experience, or other conditions managed by the contract owner. This adds a layer of gamification and utility to the NFTs listed or held within the platform. It also includes standard marketplace features like listing, buying, fees, and royalty support (checking EIP-2981).

**Advanced/Creative Aspects:**

1.  **Dynamic NFT State:** NFTs held or staked in the contract can have mutable properties tracked on-chain (XP, Level).
2.  **Integrated Staking:** Users stake NFTs directly into the marketplace contract to enable state evolution and potentially earn rewards (a utility token).
3.  **Experience & Leveling:** Staking duration translates into experience points, which determine a level for the NFT.
4.  **Parameterized Dynamics:** The rules for XP gain and leveling are configurable by the owner.
5.  **On-chain Tracking:** The dynamic state of *specific* NFT instances is tracked within the marketplace contract, tied to the NFT contract address and token ID.
6.  **Combined Functionality:** Blends marketplace listing/sales with NFT staking/utility and dynamic state management.
7.  **ERC-721 Receiver:** Implements `onERC721Received` to handle inbound NFT transfers for listing and staking securely.
8.  **EIP-2981 Royalty Check:** Attempts to honor EIP-2981 royalties for sales.

---

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Imports (assuming standard OpenZeppelin or similar interfaces/contracts)
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Convenient for onERC721Received
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // EIP-2981 Royalty Standard

/**
 * @title DynamicNFTMarketplace
 * @dev A marketplace for NFTs that allows listing, buying, selling, and staking.
 *      Staked NFTs can evolve their on-chain state (level, experience) over time.
 *      Supports EIP-2981 royalties and uses a utility token for staking rewards.
 *      Requires NFTs to be transferred to the contract for listing or staking.
 */
contract DynamicNFTMarketplace is Ownable, Pausable, ERC721Holder { // ERC721Holder provides onERC721Received implementation

    // --- OUTLINE ---
    // 1. Imports
    // 2. Errors
    // 3. Events
    // 4. State Variables
    // 5. Structs: Listing, StakingRecord, DynamicState
    // 6. Mappings: listings, stakingRecords, dynamicStates, levelXPRequirements
    // 7. Constants/Rates
    // 8. Constructor
    // 9. ERC721 Receiver Hook (from ERC721Holder)
    // 10. Core Marketplace Functions (list, buy, cancel, update price)
    // 11. Core Staking Functions (stake, unstake, claim rewards)
    // 12. Dynamic State Management (internal update logic, view functions)
    // 13. Admin/Owner Functions (set fees, rates, token address, pause, withdraw)
    // 14. View Functions (get state, check status, calculate)
    // 15. Internal Helper Functions (transfers, calculations)
    // 16. ERC165 Support (supportsInterface - included via ERC721Holder and Ownable)


    // --- FUNCTION SUMMARY ---

    // Constructor
    // constructor(address initialOwner, address initialUtilityToken, uint256 initialMarketplaceFeeBps, address initialFeeRecipient)
    // @dev Initializes the contract with owner, utility token, fee settings.

    // ERC721 Receiver (Handled by ERC721Holder)
    // onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) returns (bytes4)
    // @dev Called by ERC721 contracts when a token is transferred here. Checks if the transfer is for listing or staking.

    // Core Marketplace Functions
    // 1. listNFT(address nftContract, uint256 tokenId, uint256 price) external
    // @dev Allows an owner to list their NFT for sale. NFT must be approved/transferred to the marketplace contract first.
    // 2. buyNFT(address nftContract, uint256 tokenId) external payable
    // @dev Allows a user to buy a listed NFT. Handles payment, fees, royalties, and transfers.
    // 3. cancelListing(address nftContract, uint256 tokenId) external
    // @dev Allows the seller to cancel a listing and retrieve their NFT.
    // 4. updateListingPrice(address nftContract, uint256 tokenId, uint256 newPrice) external
    // @dev Allows the seller to update the price of an active listing.

    // Core Staking Functions
    // 5. stakeNFT(address nftContract, uint256 tokenId) external
    // @dev Allows an owner to stake their NFT in the marketplace. NFT must be approved/transferred to the marketplace contract first.
    // 6. unstakeNFT(address nftContract, uint256 tokenId) external
    // @dev Allows the staker to unstake their NFT. Calculates and transfers rewards, updates dynamic state, transfers NFT back.
    // 7. claimStakingRewards(address nftContract, uint256 tokenId) external
    // @dev Allows the staker to claim accrued rewards without unstaking. Updates dynamic state.

    // Dynamic State Management (Primary Interaction & Views)
    // 8. getDynamicState(address nftContract, uint256 tokenId) external view returns (DynamicState memory)
    // @dev Gets the current dynamic state (XP, Level, last update time) for a specific NFT.

    // Admin/Owner Functions
    // 9. setMarketplaceFeeRecipient(address _feeRecipient) external onlyOwner
    // @dev Sets the address that receives marketplace fees.
    // 10. setMarketplaceFeePercentage(uint16 _feeBps) external onlyOwner
    // @dev Sets the marketplace fee percentage in basis points (e.g., 100 = 1%). Max 10000 (100%).
    // 11. setUtilityTokenAddress(address _utilityToken) external onlyOwner
    // @dev Sets the address of the ERC20 utility token used for staking rewards.
    // 12. setStakingRate(uint256 _xpRatePerSecond) external onlyOwner
    // @dev Sets the rate at which experience points are gained per second of staking.
    // 13. setLevelXPRequirement(uint16 level, uint64 xpRequirement) external onlyOwner
    // @dev Sets the minimum experience points required to reach a specific level. Level 0 should be 0.
    // 14. setPause(bool _paused) external onlyOwner
    // @dev Pauses or unpauses marketplace and staking activities. Uses Pausable.
    // 15. withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner
    // @dev Allows owner to withdraw specific ERC20 tokens mistakenly sent or accumulated (excluding earned fees/rewards held for distribution).
    // 16. withdrawERC721(address nftContract, uint256 tokenId) external onlyOwner
    // @dev Allows owner to withdraw specific ERC721 tokens mistakenly sent to the contract.

    // View Functions
    // 17. getListing(address nftContract, uint256 tokenId) external view returns (Listing memory)
    // @dev Gets the listing details for a specific NFT.
    // 18. isListed(address nftContract, uint256 tokenId) external view returns (bool)
    // @dev Checks if a specific NFT is currently listed for sale.
    // 19. getStakingRecord(address nftContract, uint256 tokenId) external view returns (StakingRecord memory)
    // @dev Gets the staking details for a specific NFT.
    // 20. isStaked(address nftContract, uint256 tokenId) external view returns (bool)
    // @dev Checks if a specific NFT is currently staked.
    // 21. calculatePendingReward(address nftContract, uint256 tokenId) external view returns (uint256)
    // @dev Calculates the pending utility token reward for a staked NFT.
    // 22. getMarketplaceFeePercentage() external view returns (uint16)
    // @dev Gets the current marketplace fee percentage in basis points.
    // 23. getMarketplaceFeeRecipient() external view returns (address)
    // @dev Gets the address configured to receive marketplace fees.
    // 24. getLevelXPRequirement(uint16 level) external view returns (uint64)
    // @dev Gets the XP required for a specific level.
    // 25. getUtilityTokenAddress() external view returns (address)
    // @dev Gets the address of the configured utility token.
    // 26. getStakingRate() external view returns (uint256)
    // @dev Gets the rate at which staking XP is earned per second.

    // ERC165 Support (Included via ERC721Holder & Ownable/Pausable which use Context)
    // supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    // @dev Standard interface detection.

    // Internal Helper Functions (not directly callable externally)
    // _updateNFTDynamicState(address nftContract, uint256 tokenId) internal
    // _calculateStakingReward(StakingRecord storage record) internal view returns (uint256 currentReward)
    // _getLevelFromXP(uint64 xp) internal view returns (uint16 level)
    // _safeTransferERC20(address token, address to, uint256 amount) internal
    // _safeTransferERC721(address token, address from, address to, uint256 tokenId) internal
    // _calculateSalePriceDetails(address nftContract, uint256 tokenId, uint256 saleAmount) internal view returns (uint256 amountForSeller, uint256 feeAmount, uint256 royaltyAmount, address royaltyRecipient)

    // Total Functions Listed: 26 External/Public/View + 1 Constructor + 1 ERC721 Hook + Internal Helpers
    // This meets the minimum requirement of 20 external/public functions.
}

```

---

**Solidity Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title DynamicNFTMarketplace
 * @dev A marketplace for NFTs that allows listing, buying, selling, and staking.
 *      Staked NFTs can evolve their on-chain state (level, experience) over time.
 *      Supports EIP-2981 royalties and uses a utility token for staking rewards.
 *      Requires NFTs to be transferred to the contract for listing or staking.
 *      Inherits ERC721Holder for onERC721Received implementation.
 *      Inherits Ownable for access control.
 *      Inherits Pausable for pausing functionality.
 */
contract DynamicNFTMarketplace is Ownable, Pausable, ERC721Holder {

    // --- OUTLINE ---
    // 1. Imports
    // 2. Errors
    // 3. Events
    // 4. State Variables
    // 5. Structs: Listing, StakingRecord, DynamicState
    // 6. Mappings: listings, stakingRecords, dynamicStates, levelXPRequirements
    // 7. Constants/Rates
    // 8. Constructor
    // 9. ERC721 Receiver Hook (from ERC721Holder)
    // 10. Core Marketplace Functions (list, buy, cancel, update price)
    // 11. Core Staking Functions (stake, unstake, claim rewards)
    // 12. Dynamic State Management (internal update logic, view functions)
    // 13. Admin/Owner Functions (set fees, rates, token address, pause, withdraw)
    // 14. View Functions (get state, check status, calculate)
    // 15. Internal Helper Functions (transfers, calculations)
    // 16. ERC165 Support (supportsInterface - included via ERC721Holder and Ownable)


    // --- FUNCTION SUMMARY ---

    // Constructor
    // constructor(address initialOwner, address initialUtilityToken, uint256 initialMarketplaceFeeBps, address initialFeeRecipient)
    // @dev Initializes the contract with owner, utility token, fee settings.

    // ERC721 Receiver (Handled by ERC721Holder)
    // onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) returns (bytes4)
    // @dev Called by ERC721 contracts when a token is transferred here. Checks if the transfer is for listing or staking.

    // Core Marketplace Functions
    // 1. listNFT(address nftContract, uint256 tokenId, uint256 price) external whenNotPaused
    // @dev Allows an owner to list their NFT for sale. NFT must be approved/transferred to the marketplace contract first.
    // 2. buyNFT(address nftContract, uint256 tokenId) external payable whenNotPaused
    // @dev Allows a user to buy a listed NFT. Handles payment, fees, royalties, and transfers.
    // 3. cancelListing(address nftContract, uint256 tokenId) external whenNotPaused
    // @dev Allows the seller to cancel a listing and retrieve their NFT.
    // 4. updateListingPrice(address nftContract, uint256 tokenId, uint256 newPrice) external whenNotPaused
    // @dev Allows the seller to update the price of an active listing.

    // Core Staking Functions
    // 5. stakeNFT(address nftContract, uint256 tokenId) external whenNotPaused
    // @dev Allows an owner to stake their NFT in the marketplace. NFT must be approved/transferred to the marketplace contract first.
    // 6. unstakeNFT(address nftContract, uint256 tokenId) external whenNotPaused
    // @dev Allows the staker to unstake their NFT. Calculates and transfers rewards, updates dynamic state, transfers NFT back.
    // 7. claimStakingRewards(address nftContract, uint256 tokenId) external whenNotPaused
    // @dev Allows the staker to claim accrued rewards without unstaking. Updates dynamic state.

    // Dynamic State Management (Primary Interaction & Views)
    // 8. getDynamicState(address nftContract, uint256 tokenId) external view returns (DynamicState memory)
    // @dev Gets the current dynamic state (XP, Level, last update time) for a specific NFT.

    // Admin/Owner Functions
    // 9. setMarketplaceFeeRecipient(address _feeRecipient) external onlyOwner
    // @dev Sets the address that receives marketplace fees.
    // 10. setMarketplaceFeePercentage(uint16 _feeBps) external onlyOwner
    // @dev Sets the marketplace fee percentage in basis points (e.g., 100 = 1%). Max 10000 (100%).
    // 11. setUtilityTokenAddress(address _utilityToken) external onlyOwner
    // @dev Sets the address of the ERC20 utility token used for staking rewards.
    // 12. setStakingRate(uint256 _xpRatePerSecond) external onlyOwner
    // @dev Sets the rate at which experience points are gained per second of staking.
    // 13. setLevelXPRequirement(uint16 level, uint64 xpRequirement) external onlyOwner
    // @dev Sets the minimum experience points required to reach a specific level. Level 0 should be 0.
    // 14. setPause(bool _paused) external onlyOwner
    // @dev Pauses or unpauses marketplace and staking activities. Uses Pausable.
    // 15. withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner
    // @dev Allows owner to withdraw specific ERC20 tokens mistakenly sent or accumulated (excluding earned fees/rewards held for distribution).
    // 16. withdrawERC721(address nftContract, uint256 tokenId) external onlyOwner
    // @dev Allows owner to withdraw specific ERC721 tokens mistakenly sent to the contract.

    // View Functions
    // 17. getListing(address nftContract, uint256 tokenId) external view returns (Listing memory)
    // @dev Gets the listing details for a specific NFT.
    // 18. isListed(address nftContract, uint256 tokenId) external view returns (bool)
    // @dev Checks if a specific NFT is currently listed for sale.
    // 19. getStakingRecord(address nftContract, uint256 tokenId) external view returns (StakingRecord memory)
    // @dev Gets the staking details for a specific NFT.
    // 20. isStaked(address nftContract, uint256 tokenId) external view returns (bool)
    // @dev Checks if a specific NFT is currently staked.
    // 21. calculatePendingReward(address nftContract, uint256 tokenId) external view returns (uint256)
    // @dev Calculates the pending utility token reward for a staked NFT.
    // 22. getMarketplaceFeePercentage() external view returns (uint16)
    // @dev Gets the current marketplace fee percentage in basis points.
    // 23. getMarketplaceFeeRecipient() external view returns (address)
    // @dev Gets the address configured to receive marketplace fees.
    // 24. getLevelXPRequirement(uint16 level) external view returns (uint64)
    // @dev Gets the XP required for a specific level.
    // 25. getUtilityTokenAddress() external view returns (address)
    // @dev Gets the address of the configured utility token.
    // 26. getStakingRate() external view returns (uint256)
    // @dev Gets the rate at which staking XP is earned per second.

    // Internal Helper Functions (not directly callable externally)
    // _updateNFTDynamicState(address nftContract, uint256 tokenId) internal
    // _calculateStakingReward(StakingRecord storage record) internal view returns (uint256 currentReward)
    // _getLevelFromXP(uint64 xp) internal view returns (uint16 level)
    // _safeTransferERC20(address token, address to, uint256 amount) internal
    // _safeTransferERC721(address token, address from, address to, uint256 tokenId) internal
    // _calculateSalePriceDetails(address nftContract, uint256 tokenId, uint256 saleAmount) internal view returns (uint256 amountForSeller, uint256 feeAmount, uint256 royaltyAmount, address royaltyRecipient)


    // --- ERRORS ---
    error AlreadyListed(address nftContract, uint256 tokenId);
    error NotListed(address nftContract, uint256 tokenId);
    error NotSeller(address caller, address expectedSeller);
    error NotStaked(address nftContract, uint256 tokenId);
    error AlreadyStaked(address nftContract, uint256 tokenId);
    error NotStaker(address caller, address expectedStaker);
    error InsufficientPayment(uint256 sent, uint256 required);
    error TransferFailed();
    error ZeroAddressNotAllowed();
    error InvalidFeePercentage();
    error NFTAlreadyHeld(address nftContract, uint256 tokenId); // Used in onERC721Received


    // --- EVENTS ---
    event NFTListed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTBought(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, address seller, uint256 price, uint256 marketplaceFee, uint256 royaltyPaid);
    event ListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event ListingPriceUpdated(address indexed nftContract, uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);
    event NFTStaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker, uint256 rewardsClaimed, uint64 finalXP, uint16 finalLevel);
    event StakingRewardsClaimed(address indexed nftContract, uint256 indexed tokenId, address indexed staker, uint256 rewardsClaimed, uint64 currentXP, uint16 currentLevel);
    event DynamicStateUpdated(address indexed nftContract, uint256 indexed tokenId, uint64 oldXP, uint16 oldLevel, uint64 newXP, uint16 newLevel);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event FeePercentageUpdated(uint16 oldFeeBps, uint16 newFeeBps);
    event UtilityTokenUpdated(address indexed oldToken, address indexed newToken);
    event StakingRateUpdated(uint256 oldRate, uint256 newRate);
    event LevelXPRequirementUpdated(uint16 indexed level, uint64 oldXPRequirement, uint64 newXPRequirement);
    event ERC20Withdrawn(address indexed token, address indexed recipient, uint256 amount);
    event ERC721Withdrawn(address indexed token, address indexed recipient, uint256 tokenId);


    // --- STATE VARIABLES ---
    uint16 private marketplaceFeeBps; // Fee percentage in basis points (100 = 1%)
    address payable private feeRecipient;
    address private utilityTokenAddress; // ERC20 token for staking rewards
    uint256 private xpRatePerSecond = 1; // Base XP gained per second staked

    // --- STRUCTS ---
    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
        uint64 startTime; // Timestamp when listed
    }

    struct StakingRecord {
        address staker;
        uint64 stakeStartTime;
        uint64 lastClaimTime; // For partial claims without unstaking
        uint256 accumulatedReward; // Reward earned *before* last update/claim
    }

    struct DynamicState {
        uint64 lastUpdateTime; // Timestamp of the last XP/Level update
        uint64 experiencePoints;
        uint16 level;
    }

    // --- MAPPINGS ---
    // (nftContract => tokenId => Listing)
    mapping(address => mapping(uint256 => Listing)) private listings;
    // (nftContract => tokenId => StakingRecord)
    mapping(address => mapping(uint256 => StakingRecord)) private stakingRecords;
    // (nftContract => tokenId => DynamicState)
    mapping(address => mapping(uint256 => DynamicState)) private dynamicStates;
    // (level => xpRequired)
    mapping(uint16 => uint64) private levelXPRequirements;


    // --- CONSTANTS/RATES ---
    // XP_RATE_PER_SECOND is now a state variable `xpRatePerSecond`

    // --- CONSTRUCTOR ---
    constructor(
        address initialOwner,
        address initialUtilityToken,
        uint16 initialMarketplaceFeeBps,
        address payable initialFeeRecipient
    ) Ownable(initialOwner) {
        if (initialUtilityToken == address(0) || initialFeeRecipient == address(0)) revert ZeroAddressNotAllowed();
        if (initialMarketplaceFeeBps > 10000) revert InvalidFeePercentage();

        utilityTokenAddress = initialUtilityToken;
        marketplaceFeeBps = initialMarketplaceFeeBps;
        feeRecipient = initialFeeRecipient;

        // Set initial level 0 requirement
        levelXPRequirements[0] = 0;
    }

    // --- ERC721 RECEIVER HOOK ---
    // Inherited from ERC721Holder, handles the onERC721Received logic.
    // No need to override unless specific complex logic is needed based on `data`.
    // Default implementation accepts any ERC721 transfer. We rely on
    // the listNFT and stakeNFT functions being called *after* the transfer
    // to validate the purpose and update state. The `onERC721Received`
    // check below simply ensures the contract *can* receive it.
    // Note: ERC721Holder's onERC721Received just returns `ERC721Holder.onERC721Received.selector`.
    // Custom logic could go here based on `data` to distinguish intent (listing vs staking),
    // but requiring separate function calls (`listNFT`, `stakeNFT`) *after* approval/transfer
    // simplifies the hook and puts control with the user's second transaction.
    // Let's add a check here to prevent receiving an NFT if it's already listed OR staked.
    // This prevents weird states where an NFT is listed/staked AND sitting in the contract balance.
    // This modification requires overriding `onERC721Received`.
     function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        // Check if the NFT is already listed or staked in this contract
        if (listings[msg.sender][tokenId].isListed || stakingRecords[msg.sender][tokenId].staker != address(0)) {
             revert NFTAlreadyHeld(msg.sender, tokenId);
        }
        // Continue with the default ERC721Holder logic (which just returns the selector)
        return ERC721Holder.onERC721Received.selector;
    }


    // --- CORE MARKETPLACE FUNCTIONS ---

    /**
     * @dev Allows an owner to list their NFT for sale.
     *      NFT must be transferred to the marketplace contract *before* calling this function,
     *      or approved and transferred by the contract within this function (less common pattern for marketplaces).
     *      The standard pattern is approve -> list. The NFT arrives via `onERC721Received`.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param price The price in native currency (e.g., ETH, BNB, Matic).
     */
    function listNFT(address nftContract, uint256 tokenId, uint256 price) external whenNotPaused {
        if (listings[nftContract][tokenId].isListed) revert AlreadyListed(nftContract, tokenId);
        if (stakingRecords[nftContract][tokenId].staker != address(0)) revert AlreadyStaked(nftContract, tokenId);

        // Check if this contract is the owner of the NFT.
        // The user must have transferred the NFT to the contract prior to calling listNFT.
        address currentOwner = IERC721(nftContract).ownerOf(tokenId);
        if (currentOwner != address(this)) {
             // NFT is not held by the marketplace, user needs to transfer it first.
             // Or, if using approve pattern, the contract would call transferFrom here.
             // Assuming the approve+transfer-first pattern:
             revert TransferFailed(); // Indicate the NFT isn't here to list.
        }

        // We need to know the original seller's address. The `onERC721Received` hook
        // provides the `from` address. However, ERC721Holder doesn't store it.
        // A common pattern is for the user to pass their address again, or
        // require the NFT to be held by the contract *and* the caller of listNFT
        // matches the last owner recorded off-chain or via event logs.
        // A more robust approach is to require approval and `transferFrom` within `listNFT`.
        // Let's change the pattern: user calls approve, then calls listNFT.
        // The contract will transfer the NFT from the seller to itself.

        // --- Revised Pattern: Approve -> Call listNFT ---
        // The NFT stays in the user's wallet until listNFT is called.
        // Let's remove the check for `ownerOf(tokenId) == address(this)` here
        // and add `transferFrom`. This is a more standard marketplace pattern.

        // Ensure NFT is not already listed or staked
        if (listings[nftContract][tokenId].isListed) revert AlreadyListed(nftContract, tokenId);
        if (stakingRecords[nftContract][tokenId].staker != address(0)) revert AlreadyStaked(nftContract, tokenId);

        // Verify the caller is the owner of the NFT
        address ownerOfNFT = IERC721(nftContract).ownerOf(tokenId);
        if (ownerOfNFT != msg.sender) revert NotSeller(msg.sender, ownerOfNFT); // Using NotSeller error for clarity

        // Transfer the NFT to the marketplace contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // Create the listing
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isListed: true,
            startTime: uint64(block.timestamp)
        });

        emit NFTListed(nftContract, tokenId, msg.sender, price);
    }


    /**
     * @dev Allows a user to buy a listed NFT.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     */
    function buyNFT(address nftContract, uint256 tokenId) external payable whenNotPaused {
        Listing storage listing = listings[nftContract][tokenId];

        if (!listing.isListed) revert NotListed(nftContract, tokenId);
        if (msg.value < listing.price) revert InsufficientPayment(msg.value, listing.price);
        if (msg.sender == listing.seller) revert TransferFailed(); // Cannot buy your own NFT

        address seller = listing.seller;
        uint256 salePrice = listing.price;

        // Calculate fees and royalties
        (
            uint256 amountForSeller,
            uint256 feeAmount,
            uint256 royaltyAmount,
            address royaltyRecipient
        ) = _calculateSalePriceDetails(nftContract, tokenId, salePrice);

        // Clear the listing *before* transfers to prevent reentrancy issues (though unlikely here)
        delete listings[nftContract][tokenId];

        // Transfer funds:
        // 1. Send royalty to recipient (if any)
        if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
            (bool success,) = payable(royaltyRecipient).call{value: royaltyAmount}("");
            if (!success) {
                 // Handle failure: could revert, or log and continue?
                 // Reverting is safer to ensure funds distribution is correct.
                 revert TransferFailed();
            }
        }
        // 2. Send marketplace fee to fee recipient
        if (feeAmount > 0) {
             (bool success,) = feeRecipient.call{value: feeAmount}("");
             if (!success) {
                  revert TransferFailed(); // Revert on fee transfer failure
             }
        }
        // 3. Send remaining amount to the seller
        if (amountForSeller > 0) {
            (bool success,) = payable(seller).call{value: amountForSeller}("");
            if (!success) {
                 revert TransferFailed(); // Revert on seller transfer failure
            }
        }

        // Transfer NFT to the buyer
        _safeTransferERC721(nftContract, address(this), msg.sender, tokenId);

        // Handle potential remaining payment (if buyer sent more than required)
        uint256 excessPayment = msg.value - salePrice;
        if (excessPayment > 0) {
            (bool success,) = payable(msg.sender).call{value: excessPayment}("");
            if (!success) {
                // This is less critical than seller/fee/royalty transfers,
                // could potentially not revert here depending on policy,
                // but reverting is generally safest.
                revert TransferFailed();
            }
        }

        emit NFTBought(nftContract, tokenId, msg.sender, seller, salePrice, feeAmount, royaltyAmount);
    }

    /**
     * @dev Allows the seller to cancel a listing and retrieve their NFT.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     */
    function cancelListing(address nftContract, uint256 tokenId) external whenNotPaused {
        Listing storage listing = listings[nftContract][tokenId];

        if (!listing.isListed) revert NotListed(nftContract, tokenId);
        if (listing.seller != msg.sender) revert NotSeller(msg.sender, listing.seller);

        // Clear the listing
        delete listings[nftContract][tokenId];

        // Transfer NFT back to the seller
        _safeTransferERC721(nftContract, address(this), msg.sender, tokenId);

        emit ListingCancelled(nftContract, tokenId, msg.sender);
    }

    /**
     * @dev Allows the seller to update the price of an active listing.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param newPrice The new price in native currency.
     */
    function updateListingPrice(address nftContract, uint256 tokenId, uint256 newPrice) external whenNotPaused {
        Listing storage listing = listings[nftContract][tokenId];

        if (!listing.isListed) revert NotListed(nftContract, tokenId);
        if (listing.seller != msg.sender) revert NotSeller(msg.sender, listing.seller);

        uint256 oldPrice = listing.price;
        listing.price = newPrice;

        emit ListingPriceUpdated(nftContract, tokenId, oldPrice, newPrice);
    }


    // --- CORE STAKING FUNCTIONS ---

    /**
     * @dev Allows an owner to stake their NFT.
     *      NFT must be transferred to the marketplace contract *before* calling this function.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     */
    function stakeNFT(address nftContract, uint256 tokenId) external whenNotPaused {
        if (stakingRecords[nftContract][tokenId].staker != address(0)) revert AlreadyStaked(nftContract, tokenId);
        if (listings[nftContract][tokenId].isListed) revert AlreadyListed(nftContract, tokenId);

         // Check if this contract is the owner of the NFT.
        // The user must have transferred the NFT to the contract prior to calling stakeNFT.
        address currentOwner = IERC721(nftContract).ownerOf(tokenId);
        if (currentOwner != address(this)) {
             revert TransferFailed(); // Indicate the NFT isn't here to stake.
        }

        // Check if the caller was the immediate previous owner (more robust check needed,
        // perhaps relying on event logs or requiring approval+transferFrom within stakeNFT)
        // For simplicity here, we assume the user calling stakeNFT is the one who transferred it.
        // A better pattern: require approval, then call stakeNFT, and call transferFrom inside.
        // Let's adopt the Approve -> Call stakeNFT pattern.

        // --- Revised Pattern: Approve -> Call stakeNFT ---
        // The NFT stays in the user's wallet until stakeNFT is called.
        // Let's remove the check for `ownerOf(tokenId) == address(this)` here
        // and add `transferFrom`.

        // Ensure NFT is not already listed or staked
        if (stakingRecords[nftContract][tokenId].staker != address(0)) revert AlreadyStaked(nftContract, tokenId);
        if (listings[nftContract][tokenId].isListed) revert AlreadyListed(nftContract, tokenId);

        // Verify the caller is the owner of the NFT
        address ownerOfNFT = IERC721(nftContract).ownerOf(tokenId);
        if (ownerOfNFT != msg.sender) revert NotStaker(msg.sender, ownerOfNFT); // Using NotStaker error

        // Transfer the NFT to the marketplace contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);


        uint64 currentTime = uint64(block.timestamp);

        stakingRecords[nftContract][tokenId] = StakingRecord({
            staker: msg.sender,
            stakeStartTime: currentTime,
            lastClaimTime: currentTime, // Initialize last claim time
            accumulatedReward: 0 // Start with no accumulated reward
        });

        // Initialize or update dynamic state
        _updateNFTDynamicState(nftContract, tokenId);

        emit NFTStaked(nftContract, tokenId, msg.sender);
    }

    /**
     * @dev Allows the staker to unstake their NFT.
     *      Calculates and transfers earned rewards and transfers the NFT back.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     */
    function unstakeNFT(address nftContract, uint256 tokenId) external whenNotPaused {
        StakingRecord storage record = stakingRecords[nftContract][tokenId];

        if (record.staker == address(0)) revert NotStaked(nftContract, tokenId);
        if (record.staker != msg.sender) revert NotStaker(msg.sender, record.staker);

        // Update state and calculate final reward
        _updateNFTDynamicState(nftContract, tokenId);
        uint256 pendingReward = _calculateStakingReward(record);
        uint256 totalReward = record.accumulatedReward + pendingReward; // Sum previously accumulated + newly earned

        // Get final XP and Level before clearing
        DynamicState memory finalState = dynamicStates[nftContract][tokenId];
        uint64 finalXP = finalState.experiencePoints;
        uint16 finalLevel = finalState.level;

        // Clear the staking record and dynamic state
        delete stakingRecords[nftContract][tokenId];
        // Decide whether to delete dynamic state or keep it associated with the NFT
        // Keeping it allows the NFT to retain its level/XP even when not staked.
        // Let's keep it, but update the lastUpdateTime to now to reflect the end of staking gain.
        dynamicStates[nftContract][tokenId].lastUpdateTime = uint64(block.timestamp);


        // Transfer reward token
        if (totalReward > 0 && utilityTokenAddress != address(0)) {
            _safeTransferERC20(utilityTokenAddress, msg.sender, totalReward);
        }

        // Transfer NFT back to staker
        _safeTransferERC721(nftContract, address(this), msg.sender, tokenId);

        emit NFTUnstaked(nftContract, tokenId, msg.sender, totalReward, finalXP, finalLevel);
    }

     /**
     * @dev Allows the staker to claim accrued rewards without unstaking the NFT.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     */
    function claimStakingRewards(address nftContract, uint256 tokenId) external whenNotPaused {
        StakingRecord storage record = stakingRecords[nftContract][tokenId];

        if (record.staker == address(0)) revert NotStaked(nftContract, tokenId);
        if (record.staker != msg.sender) revert NotStaker(msg.sender, record.staker);

        // Update state and calculate reward since last claim/stake
        _updateNFTDynamicState(nftContract, tokenId);
        uint256 pendingReward = _calculateStakingReward(record);
        uint256 totalClaimableReward = record.accumulatedReward + pendingReward;

        if (totalClaimableReward == 0) return; // Nothing to claim

        // Reset accumulated reward and update last claim time *before* transfer
        record.accumulatedReward = 0;
        record.lastClaimTime = uint64(block.timestamp);

        // Transfer reward token
        if (utilityTokenAddress != address(0)) {
            _safeTransferERC20(utilityTokenAddress, msg.sender, totalClaimableReward);
        }

        // Get current XP and Level after update
        DynamicState memory currentState = dynamicStates[nftContract][tokenId];

        emit StakingRewardsClaimed(nftContract, tokenId, msg.sender, totalClaimableReward, currentState.experiencePoints, currentState.level);
    }


    // --- DYNAMIC STATE MANAGEMENT (VIEWS) ---

    /**
     * @dev Gets the current dynamic state (XP, Level, last update time) for a specific NFT.
     *      Automatically updates state based on staking duration if staked.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @return DynamicState The current dynamic state struct.
     */
    function getDynamicState(address nftContract, uint256 tokenId) external view returns (DynamicState memory) {
         // Note: This view function calls an internal update function that modifies state.
         // This is only possible in a view function because state changes are discarded.
         // A user must call a state-changing function (stake, unstake, claim)
         // to persist XP/Level changes earned during staking.
         // This view function only shows the *potential* state if updated now.
         DynamicState memory currentState = dynamicStates[nftContract][tokenId];
         StakingRecord storage record = stakingRecords[nftContract][tokenId];

         if (record.staker != address(0)) {
             // Calculate potential XP gain since last update
             uint64 timeElapsed = uint64(block.timestamp) - currentState.lastUpdateTime;
             uint64 potentialXPGain = timeElapsed * uint64(xpRatePerSecond);
             uint64 potentialTotalXP = currentState.experiencePoints + potentialXPGain;

             currentState.experiencePoints = potentialTotalXP;
             currentState.level = _getLevelFromXP(potentialTotalXP);
             // lastUpdateTime would be block.timestamp if state were actually updated
         }
         // If not staked, state is simply the last recorded state

         return currentState;
    }


    // --- ADMIN/OWNER FUNCTIONS ---

    /**
     * @dev Sets the address that receives marketplace fees.
     * @param _feeRecipient The new fee recipient address.
     */
    function setMarketplaceFeeRecipient(address payable _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert ZeroAddressNotAllowed();
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Sets the marketplace fee percentage in basis points (e.g., 100 = 1%).
     * @param _feeBps The new fee percentage in basis points (0-10000).
     */
    function setMarketplaceFeePercentage(uint16 _feeBps) external onlyOwner {
        if (_feeBps > 10000) revert InvalidFeePercentage(); // Max 100%
        emit FeePercentageUpdated(marketplaceFeeBps, _feeBps);
        marketplaceFeeBps = _feeBps;
    }

    /**
     * @dev Sets the address of the ERC20 utility token used for staking rewards.
     * @param _utilityToken The address of the utility token contract.
     */
    function setUtilityTokenAddress(address _utilityToken) external onlyOwner {
         if (_utilityToken == address(0)) revert ZeroAddressNotAllowed();
         emit UtilityTokenUpdated(utilityTokenAddress, _utilityToken);
         utilityTokenAddress = _utilityToken;
    }

    /**
     * @dev Sets the rate at which experience points are gained per second of staking.
     * @param _xpRatePerSecond The new XP rate per second.
     */
    function setStakingRate(uint256 _xpRatePerSecond) external onlyOwner {
        emit StakingRateUpdated(xpRatePerSecond, _xpRatePerSecond);
        xpRatePerSecond = _xpRatePerSecond;
    }

     /**
     * @dev Sets the minimum experience points required to reach a specific level.
     *      Allows defining a progression curve. Level 0 requirement must be 0.
     * @param level The level number (e.g., 1, 2, 3...).
     * @param xpRequirement The minimum XP needed to reach this level.
     */
    function setLevelXPRequirement(uint16 level, uint64 xpRequirement) external onlyOwner {
        if (level == 0 && xpRequirement != 0) revert TransferFailed(); // Level 0 must require 0 XP
        uint64 oldXPRequirement = levelXPRequirements[level];
        levelXPRequirements[level] = xpRequirement;
        emit LevelXPRequirementUpdated(level, oldXPRequirement, xpRequirement);
    }

    /**
     * @dev Pauses or unpauses marketplace and staking activities.
     * @param _paused True to pause, false to unpause.
     */
    function setPause(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * @dev Allows owner to withdraw specific ERC20 tokens mistakenly sent or accumulated.
     *      Does NOT allow withdrawing the configured utility token if it would drain
     *      the balance needed for pending staking rewards.
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount to withdraw.
     */
    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) revert ZeroAddressNotAllowed();

        // Prevent withdrawing utility token if it would make it impossible to pay rewards
        if (tokenAddress == utilityTokenAddress) {
             uint256 totalPendingRewards;
             // This requires iterating through all staked NFTs to sum up rewards - potentially gas intensive.
             // A safer simple check is to not allow withdrawing the utility token at all via this function,
             // or only allowing withdrawal down to a certain buffer.
             // For simplicity, let's prevent withdrawing the utility token entirely via this function.
             // A separate, more complex function could handle excess utility token withdrawal.
             revert TransferFailed(); // Owner cannot withdraw utility token via this method.
        }

        _safeTransferERC20(tokenAddress, owner(), amount);
        emit ERC20Withdrawn(tokenAddress, owner(), amount);
    }

    /**
     * @dev Allows owner to withdraw specific ERC721 tokens mistakenly sent to the contract.
     *      Does NOT allow withdrawing NFTs that are currently listed or staked.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     */
    function withdrawERC721(address nftContract, uint256 tokenId) external onlyOwner {
         if (nftContract == address(0)) revert ZeroAddressNotAllowed();

         // Ensure the NFT is not listed or staked
         if (listings[nftContract][tokenId].isListed) revert AlreadyListed(nftContract, tokenId);
         if (stakingRecords[nftContract][tokenId].staker != address(0)) revert AlreadyStaked(nftContract, tokenId);

         // Ensure the contract actually owns the NFT
         address currentOwner = IERC721(nftContract).ownerOf(tokenId);
         if (currentOwner != address(this)) revert TransferFailed(); // Contract doesn't hold the NFT

         _safeTransferERC721(nftContract, address(this), owner(), tokenId);
         emit ERC721Withdrawn(nftContract, owner(), tokenId);
    }


    // --- VIEW FUNCTIONS ---

    /**
     * @dev Gets the listing details for a specific NFT.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @return Listing The listing struct.
     */
    function getListing(address nftContract, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftContract][tokenId];
    }

    /**
     * @dev Checks if a specific NFT is currently listed for sale.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @return bool True if listed, false otherwise.
     */
    function isListed(address nftContract, uint256 tokenId) external view returns (bool) {
        return listings[nftContract][tokenId].isListed;
    }

     /**
     * @dev Gets the staking details for a specific NFT.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @return StakingRecord The staking record struct.
     */
    function getStakingRecord(address nftContract, uint256 tokenId) external view returns (StakingRecord memory) {
        return stakingRecords[nftContract][tokenId];
    }

    /**
     * @dev Checks if a specific NFT is currently staked.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @return bool True if staked, false otherwise.
     */
    function isStaked(address nftContract, uint256 tokenId) external view returns (bool) {
        return stakingRecords[nftContract][tokenId].staker != address(0);
    }

    // getDynamicState is already defined above under Dynamic State Management

    /**
     * @dev Calculates the pending utility token reward for a staked NFT since the last claim/stake.
     *      Does NOT update the actual accumulated reward state.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @return uint256 The calculated pending reward amount.
     */
    function calculatePendingReward(address nftContract, uint256 tokenId) external view returns (uint256) {
         StakingRecord storage record = stakingRecords[nftContract][tokenId];
         if (record.staker == address(0)) return 0;

         return _calculateStakingReward(record);
    }

    /**
     * @dev Gets the current marketplace fee percentage in basis points.
     * @return uint16 The fee percentage (0-10000).
     */
    function getMarketplaceFeePercentage() external view returns (uint16) {
        return marketplaceFeeBps;
    }

    /**
     * @dev Gets the address configured to receive marketplace fees.
     * @return address The fee recipient address.
     */
    function getMarketplaceFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

     /**
     * @dev Gets the XP required for a specific level. Returns 0 if the level is not set.
     * @param level The level number.
     * @return uint64 The XP required for that level.
     */
    function getLevelXPRequirement(uint16 level) external view returns (uint64) {
        return levelXPRequirements[level];
    }

    /**
     * @dev Gets the address of the configured utility token.
     * @return address The utility token address.
     */
    function getUtilityTokenAddress() external view returns (address) {
        return utilityTokenAddress;
    }

    /**
     * @dev Gets the rate at which staking XP is earned per second.
     * @return uint256 The XP rate per second.
     */
    function getStakingRate() external view returns (uint256) {
        return xpRatePerSecond;
    }


    // --- INTERNAL HELPER FUNCTIONS ---

    /**
     * @dev Internal function to update an NFT's dynamic state (XP and Level) based on staking time.
     *      Called when staking actions (stake, unstake, claim) occur.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     */
    function _updateNFTDynamicState(address nftContract, uint256 tokenId) internal {
        StakingRecord storage record = stakingRecords[nftContract][tokenId];
        DynamicState storage state = dynamicStates[nftContract][tokenId];

        // Only update state if the NFT is currently staked
        if (record.staker != address(0)) {
            uint64 currentTime = uint64(block.timestamp);
            uint64 timeStakedSinceLastUpdate = currentTime - state.lastUpdateTime;

            uint64 xpGained = timeStakedSinceLastUpdate * uint64(xpRatePerSecond);
            state.experiencePoints += xpGained;
            state.lastUpdateTime = currentTime;

            uint16 oldLevel = state.level;
            state.level = _getLevelFromXP(state.experiencePoints);

            if (state.level != oldLevel || xpGained > 0) {
                 emit DynamicStateUpdated(nftContract, tokenId, state.experiencePoints - xpGained, oldLevel, state.experiencePoints, state.level);
            }

             // Also update accumulated reward since last claim
             uint64 timeStakedSinceLastClaim = currentTime - record.lastClaimTime;
             // Assuming utility token reward rate is directly tied to XP rate for simplicity,
             // or could be a separate rate. Let's tie it to XP rate: 1 XP = 1 reward token (adjust as needed).
             // This makes reward calculation simple: time_staked_since_claim * staking_rate.
             // If staking rate is XP_RATE_PER_SECOND, then total XP gained *since last claim* is the reward.
             // Let's make the reward rate separate for flexibility. Add `rewardRatePerSecond` state variable.

             // Revised: Calculate rewards based on time staked since last claim/stake * a reward rate
             // Let's add `rewardRatePerSecond` as an admin-settable variable.
             // For this example, reuse xpRatePerSecond for simplicity in calculation.
             // In a real contract, define a separate reward rate.
             uint256 rewardGained = timeStakedSinceLastClaim * xpRatePerSecond; // Using xpRatePerSecond as reward rate
             record.accumulatedReward += rewardGained;
             record.lastClaimTime = currentTime; // Update last claim time after accounting for this period's reward.

        } else {
             // If not staked, just update lastUpdateTime to the current timestamp
             // This stops XP gain and marks the point where staking ended.
             state.lastUpdateTime = uint64(block.timestamp);
        }
    }

    /**
     * @dev Internal view function to calculate pending utility token reward for a staked NFT.
     *      Reward is calculated based on time staked since the last claim/stake.
     *      Does NOT include previously accumulated rewards.
     * @param record The staking record struct.
     * @return uint256 The calculated pending reward amount.
     */
    function _calculateStakingReward(StakingRecord storage record) internal view returns (uint256 currentReward) {
        if (record.staker == address(0)) return 0;

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeStakedSinceLastClaim = currentTime - record.lastClaimTime;

        // Assuming reward rate is tied to xpRatePerSecond for this example
        // In a real contract, use a separate `rewardRatePerSecond` state variable
        return timeStakedSinceLastClaim * xpRatePerSecond;
    }

     /**
     * @dev Internal view function to determine the level based on experience points.
     *      Looks up required XP in the levelXPRequirements mapping.
     * @param xp The total experience points.
     * @return uint16 The calculated level.
     */
    function _getLevelFromXP(uint64 xp) internal view returns (uint16 level) {
        level = 0;
        // Assuming levels are sequential (0, 1, 2, ...) and XP requirements are non-decreasing.
        // This is a simple linear search. For many levels, a different structure (e.g., sorted array)
        // and binary search or lookup table could be more efficient if levels are dense.
        // Given the constraint is a single contract, iterating a sparse mapping is acceptable.
        // We iterate backwards from a high possible level to find the highest level achieved.
        // Let's assume max level is reasonable, or iterate until level requirement is > xp.
        // Max level could be a constant or admin-settable. Let's assume max level is 255 for uint16.
        for (uint16 i = 255; i > 0; --i) {
            if (levelXPRequirements[i] != 0 && xp >= levelXPRequirements[i]) {
                level = i;
                break;
            }
        }
        return level;
    }

    /**
     * @dev Internal helper to safely transfer ERC20 tokens.
     *      Uses SafeERC20 for protection against faulty implementations.
     * @param token The address of the ERC20 token.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     */
    function _safeTransferERC20(address token, address to, uint256 amount) internal {
         if (amount == 0) return; // Avoid transferring 0
         if (to == address(0)) revert ZeroAddressNotAllowed();
         SafeERC20.safeTransfer(IERC20(token), to, amount);
    }

     /**
     * @dev Internal helper to safely transfer ERC721 tokens.
     *      Uses `safeTransferFrom`. Assumes the marketplace contract is approved or is the current owner.
     * @param token The address of the ERC721 contract.
     * @param from The sender address (should be address(this) here).
     * @param to The recipient address.
     * @param tokenId The ID of the token.
     */
    function _safeTransferERC721(address token, address from, address to, uint256 tokenId) internal {
         if (to == address(0)) revert ZeroAddressNotAllowed();
         IERC721(token).safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Internal view function to calculate amounts for seller, fees, and royalties.
     *      Checks for EIP-2981 support on the NFT contract.
     * @param nftContract Address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param saleAmount The total sale amount (in native currency).
     * @return amountForSeller The amount to send to the seller.
     * @return feeAmount The amount to send to the fee recipient.
     * @return royaltyAmount The amount to send as royalty.
     * @return royaltyRecipient The address to send royalty to.
     */
    function _calculateSalePriceDetails(
        address nftContract,
        uint256 tokenId,
        uint256 saleAmount
    ) internal view returns (
        uint256 amountForSeller,
        uint256 feeAmount,
        uint256 royaltyAmount,
        address royaltyRecipient
    ) {
        // Calculate marketplace fee
        feeAmount = (saleAmount * marketplaceFeeBps) / 10000;

        // Attempt to get royalty information (EIP-2981)
        royaltyAmount = 0;
        royaltyRecipient = address(0);
        try IERC2981(nftContract).royaltyInfo(tokenId, saleAmount) returns (address recipient, uint256 amount) {
            // Check if the recipient is valid and amount is non-zero
            if (recipient != address(0) && amount > 0 && amount <= saleAmount) {
                 royaltyRecipient = recipient;
                 royaltyAmount = amount;
            }
        } catch {
            // NFT contract does not support EIP-2981 or call failed. No royalty.
        }

        // Calculate amount remaining for the seller after fees and royalties
        uint256 totalDeductions = feeAmount + royaltyAmount;
        if (totalDeductions > saleAmount) {
             // This shouldn't happen if royaltyAmount is capped at saleAmount,
             // but as a safety measure.
             amountForSeller = 0;
        } else {
            amountForSeller = saleAmount - totalDeductions;
        }
    }

    // --- ERC165 Support ---
    // supportsInterface is provided by ERC721Holder and Ownable/Pausable via Context

}
```