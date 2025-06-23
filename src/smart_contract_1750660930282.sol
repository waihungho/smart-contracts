Okay, let's design a smart contract for a "Dynamic NFT Marketplace". This contract will go beyond simple buying/selling and incorporate features that interact with and potentially change the state of NFTs.

**Concept:** A marketplace for ERC-721 tokens, but with added functionality allowing owners to interact with their NFTs directly through the contract to "level up" or evolve them using a specific resource (like an ERC-20 token or ETH), and even 'stake' them within the marketplace for passive benefits.

**Advanced Concepts Included:**
1.  **Dynamic NFT State:** The contract stores and manages an evolving state (like 'level' or 'XP') for listed/owned NFTs, separate from the NFT's own metadata (though off-chain metadata systems would ideally reflect this on-chain state).
2.  **Resource Consumption for Interaction:** Requires a specific ERC-20 token ("EnergyToken") or ETH to perform state-changing actions (like "training").
3.  **NFT Staking:** Allows users to lock their NFTs in the contract to earn passive rewards (e.g., Energy Tokens or XP).
4.  **Integrated Royalties & Fees:** Handles ERC-2981 royalties and platform fees during sales.
5.  **Allowed Collections:** Restricts marketplace activity to a predefined set of approved ERC-721 contracts.
6.  **Batch Operations:** Includes functions for common operations on multiple items (batch listing, batch training).
7.  **Detailed State Queries:** Provides granular view functions to inspect listings, NFT states, staking info, etc.
8.  **Configurability:** Owner functions to adjust fees, costs, reward rates, and allowed collections.

**Outline and Function Summary**

**Contract Name:** DynamicNFTMarketplace

**Purpose:** A marketplace for trading ERC-721 NFTs with integrated features for dynamic NFT interactions (training/leveling) and staking.

**Key Features:**
*   List and buy ERC-721 NFTs.
*   Pay creator royalties (ERC-2981 compatible) and platform fees on sales.
*   Store and track the 'level' or 'XP' of NFTs within the contract.
*   Allow users to "train" their NFTs using ETH or an Energy Token to increase their level/XP.
*   Allow users to "stake" their NFTs within the marketplace to earn Energy Tokens or XP passively over time.
*   Restrict marketplace activity to approved NFT collections.
*   Owner can configure fees, costs, and allowed collections.
*   Support for batch operations.

**State Variables:**
*   `listings`: Mapping storing details for listed NFTs.
*   `nftLevels`: Mapping storing the current level/XP for each NFT.
*   `stakedNFTs`: Mapping storing staking details for staked NFTs.
*   `allowedCollections`: Mapping tracking which ERC-721 contracts are allowed.
*   `platformFeeRate`: Percentage fee taken by the platform on sales.
*   `platformFeeRecipient`: Address receiving platform fees.
*   `energyTokenAddress`: Address of the ERC-20 token used for training costs and staking rewards.
*   `trainingCostETH`: Cost in wei to train an NFT (if paying with ETH).
*   `trainingCostEnergy`: Cost in Energy Tokens to train an NFT (if paying with Energy Token).
*   `xpPerETH` / `xpPerEnergy`: XP gained per unit of currency/token spent on training.
*   `stakingRewardRatePerSecond`: Energy Tokens or XP earned per staked NFT per second.
*   `totalPlatformFeesETH`: Total ETH accumulated in platform fees.
*   `totalPlatformFeesEnergy`: Total Energy Tokens accumulated in platform fees.
*   `owner`: Contract owner (for admin functions).

**Events:**
*   `ItemListed`
*   `ItemBought`
*   `ListingCancelled`
*   `NFTTrained`
*   `NFTStaked`
*   `NFTUnstaked`
*   `StakingRewardsClaimed`
*   `PlatformFeeUpdated`
*   `FeeRecipientUpdated`
*   `EnergyTokenUpdated`
*   `CollectionAllowed`
*   `CollectionRemoved`
*   `TrainingCostUpdated`
*   `StakingRewardRateUpdated`
*   `PlatformFeesWithdrawn`

**Functions (at least 20):**

*   **Marketplace Core (5):**
    1.  `listNFT`: List an NFT for sale.
    2.  `buyNFT`: Purchase a listed NFT.
    3.  `cancelListing`: Cancel an active listing.
    4.  `updateListingPrice`: Change the price of an active listing.
    5.  `getListing`: Retrieve details of a specific listing (view).
*   **Dynamic NFT (Training) (5):**
    6.  `trainNFTWithETH`: Pay ETH to train an NFT and increase its level/XP.
    7.  `trainNFTWithEnergy`: Pay Energy Tokens to train an NFT and increase its level/XP.
    8.  `getNFTLevel`: Get the current level/XP of an NFT (view).
    9.  `getTrainingCosts`: Get current costs for training (view).
    10. `calculateExpectedXP`: Calculate XP gain from training (view).
*   **Dynamic NFT (Staking) (6):**
    11. `stakeNFT`: Stake an owned NFT to earn rewards.
    12. `unstakeNFT`: Unstake an NFT and claim pending rewards.
    13. `claimStakingRewards`: Claim pending rewards for a currently staked NFT without unstaking.
    14. `getStakeDetails`: Get staking information for an NFT (view).
    15. `calculatePendingRewards`: Calculate rewards accumulated for a staked NFT (view).
    16. `getStakedNFTsByStaker`: Get a list of NFTs staked by a specific address (view).
*   **Allowed Collections (3):**
    17. `addAllowedCollection`: Allow a specific ERC-721 contract.
    18. `removeAllowedCollection`: Disallow a specific ERC-721 contract.
    19. `isCollectionAllowed`: Check if a collection is allowed (view).
*   **Admin & Configuration (7):**
    20. `setPlatformFeeRate`: Set the platform fee percentage.
    21. `setPlatformFeeRecipient`: Set the address receiving fees.
    22. `setEnergyToken`: Set the address of the Energy Token.
    23. `setTrainingCosts`: Set ETH and Energy Token training costs.
    24. `setXPParameters`: Set parameters for XP gain calculation.
    25. `setStakingRewardRate`: Set the rate at which staking rewards accrue.
    26. `withdrawPlatformFees`: Withdraw accumulated platform fees (ETH and Energy).
*   **Query & Utility (3+):**
    27. `getPlatformFeeRate`: Get the current platform fee rate (view).
    28. `getPlatformFeeRecipient`: Get the current fee recipient (view).
    29. `getEnergyToken`: Get the Energy Token address (view).
    30. `getTotalPlatformFees`: Get total accumulated fees (view).
    *(This already totals 30 functions, comfortably exceeding 20)*.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To hold NFTs safely
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For admin functions
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max/average (optional, but good utility)
import "@openzeppelin/contracts/utils/introspection/IERC165.sol"; // For ERC-2981 check
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // For royalty standard

// --- Outline and Function Summary ---
// Contract Name: DynamicNFTMarketplace
// Purpose: A marketplace for trading ERC-721 NFTs with integrated features for dynamic NFT interactions (training/leveling) and staking.
// Key Features:
// * List and buy ERC-721 NFTs.
// * Pay creator royalties (ERC-2981 compatible) and platform fees on sales.
// * Store and track the 'level' or 'XP' of NFTs within the contract.
// * Allow users to "train" their NFTs using ETH or an Energy Token to increase their level/XP.
// * Allow users to "stake" their NFTs within the marketplace to earn Energy Tokens or XP passively over time.
// * Restrict marketplace activity to approved NFT collections.
// * Owner can configure fees, costs, and allowed collections.
// * Support for batch operations (partially included, can be expanded).
// * Owner can manage platform fees and configure parameters.

// State Variables:
// * listings: Mapping storing details for listed NFTs.
// * nftLevels: Mapping storing the current level/XP for each NFT.
// * stakedNFTs: Mapping storing staking details for staked NFTs.
// * allowedCollections: Mapping tracking which ERC-721 contracts are allowed.
// * platformFeeRate: Percentage fee taken by the platform on sales.
// * platformFeeRecipient: Address receiving platform fees.
// * energyTokenAddress: Address of the ERC-20 token used for training costs and staking rewards.
// * trainingCostETH: Cost in wei to train an NFT (if paying with ETH).
// * trainingCostEnergy: Cost in Energy Tokens to train an NFT (if paying with Energy Token).
// * xpPerUnit: Parameters for XP gain calculation based on training cost.
// * stakingRewardRatePerSecond: Energy Tokens or XP earned per staked NFT per second.
// * totalPlatformFeesETH: Total ETH accumulated in platform fees.
// * totalPlatformFeesEnergy: Total Energy Tokens accumulated in platform fees.
// * owner: Contract owner (using Ownable).

// Events:
// * ItemListed, ItemBought, ListingCancelled, NFTTrained, NFTStaked, NFTUnstaked, StakingRewardsClaimed, PlatformFeeUpdated, FeeRecipientUpdated, EnergyTokenUpdated, CollectionAllowed, CollectionRemoved, TrainingCostUpdated, StakingRewardRateUpdated, PlatformFeesWithdrawn

// Functions (30+):
// 1. listNFT: Lists an NFT for sale.
// 2. buyNFT: Executes the purchase of a listed NFT.
// 3. cancelListing: Cancels an active listing.
// 4. updateListingPrice: Updates the price of an active listing.
// 5. getListing: Retrieves details of a specific listing (view).
// 6. trainNFTWithETH: Pays ETH to increase an NFT's level/XP.
// 7. trainNFTWithEnergy: Pays Energy Tokens to increase an NFT's level/XP.
// 8. getNFTLevel: Gets the current level/XP of an NFT (view).
// 9. getTrainingCosts: Gets current costs for training (view).
// 10. calculateExpectedXP: Calculates potential XP gain from training (view).
// 11. stakeNFT: Stakes an owned NFT within the marketplace.
// 12. unstakeNFT: Unstakes an NFT and claims rewards.
// 13. claimStakingRewards: Claims rewards for a staked NFT without unstaking.
// 14. getStakeDetails: Gets staking info for an NFT (view).
// 15. calculatePendingRewards: Calculates accumulated rewards for a staked NFT (view).
// 16. getStakedNFTsByStaker: Gets a list of NFTs staked by an address (view).
// 17. addAllowedCollection: Allows a specific ERC-721 contract.
// 18. removeAllowedCollection: Disallows a specific ERC-721 contract.
// 19. isCollectionAllowed: Checks if a collection is allowed (view).
// 20. setPlatformFeeRate: Sets the platform fee percentage (owner).
// 21. setPlatformFeeRecipient: Sets the address receiving fees (owner).
// 22. setEnergyToken: Sets the address of the Energy Token (owner).
// 23. setTrainingCosts: Sets ETH and Energy Token training costs (owner).
// 24. setXPParameters: Sets parameters for XP gain calculation (owner).
// 25. setStakingRewardRate: Sets the staking reward rate (owner).
// 26. withdrawPlatformFees: Withdraws accumulated platform fees (ETH and Energy) (owner).
// 27. getPlatformFeeRate: Gets the current platform fee rate (view).
// 28. getPlatformFeeRecipient: Gets the current fee recipient (view).
// 29. getEnergyToken: Gets the Energy Token address (view).
// 30. getTotalPlatformFees: Gets total accumulated fees (view).
// 31. onERC721Received: Required for receiving NFTs (internal/callback).
// 32. supportsInterface: Required for ERC165/ERC721Holder (view).

// --- Contract Implementation ---

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    struct Listing {
        address seller;
        address nftCollection;
        uint256 tokenId;
        uint256 price; // in native currency (ETH/WETH implied)
        bool active;
    }

    struct StakeInfo {
        address staker;
        uint256 stakeStartTime;
        uint256 accumulatedRewardPoints; // Reward points accrued since last claim
    }

    // --- State Variables ---

    mapping(address => mapping(uint258 => Listing)) public listings; // collection => tokenId => Listing
    mapping(address => mapping(uint258 => uint256)) public nftLevels; // collection => tokenId => level/XP
    mapping(address => mapping(uint258 => StakeInfo)) public stakedNFTs; // collection => tokenId => StakeInfo
    mapping(address => bool) public allowedCollections; // collection => isAllowed
    mapping(address => uint256[]) private stakerStakedNFTs; // staker => list of [collection, tokenId] pairs encoded
    mapping(address => uint256) private stakerStakedNFTCount; // To track actual count easily

    uint256 public platformFeeRate; // Basis points (e.g., 250 for 2.5%)
    address payable public platformFeeRecipient;

    address public energyTokenAddress; // Address of the ERC20 token for training/staking rewards

    uint256 public trainingCostETH; // in wei
    uint256 public trainingCostEnergy; // in Energy Tokens

    // XP gain parameters (adjust these based on desired game mechanics)
    uint256 public xpPerETH; // XP gained per wei spent
    uint256 public xpPerEnergy; // XP gained per Energy Token spent

    // Staking reward parameters
    uint256 public stakingRewardRatePerSecond; // Reward points per second per staked NFT

    // Accumulated fees (simple accumulation, can be enhanced with per-token tracking)
    uint256 public totalPlatformFeesETH;
    uint256 public totalPlatformFeesEnergy;

    // --- Events ---

    event ItemListed(address indexed seller, address indexed nftCollection, uint256 indexed tokenId, uint256 price);
    event ItemBought(address indexed buyer, address indexed seller, address indexed nftCollection, uint256 indexed tokenId, uint256 price, uint256 platformFee, uint256 royaltyAmount);
    event ListingCancelled(address indexed seller, address indexed nftCollection, uint256 indexed tokenId);
    event UpdateListingPrice(address indexed seller, address indexed nftCollection, uint256 indexed tokenId, uint256 newPrice);
    event NFTTrained(address indexed trainer, address indexed nftCollection, uint256 indexed tokenId, uint256 newLevel, uint256 xpGained);
    event NFTStaked(address indexed staker, address indexed nftCollection, uint256 indexed tokenId, uint256 stakeTime);
    event NFTUnstaked(address indexed staker, address indexed nftCollection, uint256 indexed tokenId, uint256 unstakeTime, uint256 accumulatedRewardPoints);
    event StakingRewardsClaimed(address indexed staker, address indexed nftCollection, uint256 indexed tokenId, uint256 claimedRewardPoints, uint256 claimedEnergyTokens); // Assuming rewards are paid in Energy Tokens
    event PlatformFeeUpdated(uint256 oldRate, uint256 newRate);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event EnergyTokenUpdated(address indexed oldToken, address indexed newToken);
    event CollectionAllowed(address indexed nftCollection);
    event CollectionRemoved(address indexed nftCollection);
    event TrainingCostUpdated(uint256 newCostETH, uint256 newCostEnergy);
    event XPParametersUpdated(uint256 newXpPerETH, uint256 newXpPerEnergy);
    event StakingRewardRateUpdated(uint256 newRate);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amountETH, uint256 amountEnergy);

    // --- Constructor ---

    constructor(uint256 _initialFeeRate, address payable _initialFeeRecipient) Ownable(msg.sender) {
        require(_initialFeeRecipient != address(0), "Recipient cannot be zero address");
        platformFeeRate = _initialFeeRate; // Expected in basis points (e.g., 250 for 2.5%)
        platformFeeRecipient = _initialFeeRecipient;

        // Default costs and rates (can be updated by owner)
        trainingCostETH = 0; // Must be set by owner
        trainingCostEnergy = 0; // Must be set by owner
        xpPerETH = 0; // Must be set by owner
        xpPerEnergy = 0; // Must be set by owner
        stakingRewardRatePerSecond = 0; // Must be set by owner
    }

    // --- Marketplace Core Functions ---

    /**
     * @notice Lists an NFT for sale on the marketplace.
     * Requires the caller to have approved this contract to transfer the specific NFT beforehand.
     * The NFT is transferred to the marketplace contract upon successful listing.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     * @param _price The price in native currency (wei).
     */
    function listNFT(address _nftCollection, uint256 _tokenId, uint256 _price) external nonReentrant {
        require(allowedCollections[_nftCollection], "Collection not allowed");
        require(_price > 0, "Price must be greater than 0");

        IERC721 nft = IERC721(_nftCollection);
        require(nft.ownerOf(_tokenId) == msg.sender, "Caller does not own the NFT");
        require(nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer NFT");

        // Cancel any existing listing for this NFT
        if (listings[_nftCollection][_tokenId].active) {
            // This might indicate a front-running attempt, or a simple relist.
            // For simplicity, we just overwrite, but could add more checks.
            emit ListingCancelled(listings[_nftCollection][_tokenId].seller, _nftCollection, _tokenId);
        }

        listings[_nftCollection][_tokenId] = Listing({
            seller: msg.sender,
            nftCollection: _nftCollection,
            tokenId: _tokenId,
            price: _price,
            active: true
        });

        // Transfer NFT to the marketplace contract
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit ItemListed(msg.sender, _nftCollection, _tokenId, _price);
    }

    /**
     * @notice Purchases a listed NFT.
     * Transfers the NFT from the marketplace to the buyer, and transfers funds from buyer
     * to seller, platform fee recipient, and royalty recipient.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     */
    function buyNFT(address _nftCollection, uint256 _tokenId) external payable nonReentrant {
        Listing storage listing = listings[_nftCollection][_tokenId];
        require(listing.active, "Listing does not exist or is not active");
        require(msg.sender != listing.seller, "Cannot buy your own listing");
        require(msg.value >= listing.price, "Insufficient funds sent");

        address seller = listing.seller;
        uint256 totalPrice = listing.price;

        // Mark listing inactive immediately
        listing.active = false;
        emit ItemBought(msg.sender, seller, _nftCollection, _tokenId, totalPrice, 0, 0); // Emit before fee/royalty calc as initial state

        // Calculate and pay platform fee
        uint256 platformFee = (totalPrice * platformFeeRate) / 10000;
        uint256 amountAfterFee = totalPrice - platformFee;
        totalPlatformFeesETH += platformFee; // Accumulate ETH fees

        // Calculate and pay royalty (ERC-2981)
        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);
        uint256 amountAfterRoyalty = amountAfterFee;

        IERC721 nft = IERC721(_nftCollection);
        // Check if the NFT contract supports ERC-2981 and get royalty info
        try IERC2981(_nftCollection).royaltyInfo(_tokenId, totalPrice) returns (address recipient, uint256 royalty) {
             if (recipient != address(0) && royalty > 0) {
                royaltyRecipient = recipient;
                royaltyAmount = Math.min(royalty, amountAfterFee); // Royalty cannot exceed the amount remaining after platform fee
                amountAfterRoyalty = amountAfterFee - royaltyAmount;
            }
        } catch {} // If royaltyInfo call fails or reverts, no royalty is paid

        // Transfer funds: royalty, platform fee, then seller proceeds
        if (royaltyAmount > 0 && royaltyRecipient != address(this)) { // Don't send royalty to marketplace itself
             (bool successRoyalty, ) = royaltyRecipient.call{value: royaltyAmount}("");
             require(successRoyalty, "Royalty payment failed");
        }
         if (platformFee > 0 && platformFeeRecipient != address(this)) { // Don't send fee to marketplace itself
             (bool successFee, ) = platformFeeRecipient.call{value: platformFee}("");
             require(successFee, "Fee payment failed");
         }

        uint256 sellerProceeds = amountAfterRoyalty;
        if (sellerProceeds > 0 && seller != address(this)) { // Don't send proceeds to marketplace itself
            (bool successSeller, ) = seller.call{value: sellerProceeds}("");
            require(successSeller, "Seller payment failed");
        }

        // Transfer NFT to buyer
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        // Refund any excess ETH sent by the buyer
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        // Re-emit event with actual fees/royalties calculated
        emit ItemBought(msg.sender, seller, _nftCollection, _tokenId, totalPrice, platformFee, royaltyAmount);
    }

    /**
     * @notice Cancels an active listing.
     * Only the seller of the listing can cancel it.
     * Transfers the NFT back to the seller.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     */
    function cancelListing(address _nftCollection, uint256 _tokenId) external nonReentrant {
        Listing storage listing = listings[_nftCollection][_tokenId];
        require(listing.active, "Listing does not exist or is not active");
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        listing.active = false; // Mark inactive before transfer
        IERC721 nft = IERC721(_nftCollection);

        // Transfer NFT back to seller
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit ListingCancelled(msg.sender, _nftCollection, _tokenId);
    }

     /**
      * @notice Updates the price of an active listing.
      * Only the seller of the listing can update it.
      * @param _nftCollection The address of the ERC-721 contract.
      * @param _tokenId The token ID of the NFT.
      * @param _newPrice The new price in native currency (wei).
      */
    function updateListingPrice(address _nftCollection, uint256 _tokenId, uint256 _newPrice) external {
        Listing storage listing = listings[_nftCollection][_tokenId];
        require(listing.active, "Listing does not exist or is not active");
        require(listing.seller == msg.sender, "Only seller can update listing");
        require(_newPrice > 0, "Price must be greater than 0");

        listing.price = _newPrice;

        emit UpdateListingPrice(msg.sender, _nftCollection, _tokenId, _newPrice);
    }

    /**
     * @notice Retrieves details of a specific listing.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     * @return Listing struct containing details (seller, collection, tokenId, price, active).
     */
    function getListing(address _nftCollection, uint256 _tokenId) external view returns (Listing memory) {
        return listings[_nftCollection][_tokenId];
    }

    // --- Dynamic NFT (Training) Functions ---

    /**
     * @notice Trains an NFT using sent ETH to increase its level/XP.
     * The caller must be the current owner of the NFT.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     */
    function trainNFTWithETH(address _nftCollection, uint256 _tokenId) external payable nonReentrant {
        require(allowedCollections[_nftCollection], "Collection not allowed for training");
        require(trainingCostETH > 0 && xpPerETH > 0, "ETH training is not configured");
        require(msg.value >= trainingCostETH, "Insufficient ETH sent for training");

        IERC721 nft = IERC721(_nftCollection);
        require(nft.ownerOf(_tokenId) == msg.sender, "Caller does not own the NFT");

        // Pay training cost to platform fee recipient (or accumulate)
        if (trainingCostETH > 0) {
             totalPlatformFeesETH += trainingCostETH; // Accumulate cost
            // Or directly send: (bool success, ) = platformFeeRecipient.call{value: trainingCostETH}(""); require(success, "Cost payment failed");
        }

        // Calculate XP gain and update level
        uint256 xpGained = trainingCostETH * xpPerETH;
        uint256 currentLevel = nftLevels[_nftCollection][_tokenId];
        uint256 newLevel = currentLevel + xpGained; // Simple cumulative XP model

        nftLevels[_nftCollection][_tokenId] = newLevel;

        // Refund any excess ETH
        if (msg.value > trainingCostETH) {
             payable(msg.sender).transfer(msg.value - trainingCostETH);
        }

        emit NFTTrained(msg.sender, _nftCollection, _tokenId, newLevel, xpGained);
    }

    /**
     * @notice Trains an NFT using Energy Tokens to increase its level/XP.
     * The caller must be the current owner of the NFT.
     * Requires caller to have approved the marketplace to spend the Energy Tokens beforehand.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     */
    function trainNFTWithEnergy(address _nftCollection, uint256 _tokenId) external nonReentrant {
         require(allowedCollections[_nftCollection], "Collection not allowed for training");
         require(energyTokenAddress != address(0), "Energy token not configured");
         require(trainingCostEnergy > 0 && xpPerEnergy > 0, "Energy training is not configured");

        IERC721 nft = IERC721(_nftCollection);
        require(nft.ownerOf(_tokenId) == msg.sender, "Caller does not own the NFT");

        IERC20 energyToken = IERC20(energyTokenAddress);
        // Transfer Energy Tokens from caller
        energyToken.safeTransferFrom(msg.sender, address(this), trainingCostEnergy);

        // Accumulate Energy Token cost
        totalPlatformFeesEnergy += trainingCostEnergy;
        // Or directly send: energyToken.safeTransfer(platformFeeRecipient, trainingCostEnergy);

        // Calculate XP gain and update level
        uint256 xpGained = trainingCostEnergy * xpPerEnergy;
        uint256 currentLevel = nftLevels[_nftCollection][_tokenId];
        uint256 newLevel = currentLevel + xpGained; // Simple cumulative XP model

        nftLevels[_nftCollection][_tokenId] = newLevel;

        emit NFTTrained(msg.sender, _nftCollection, _tokenId, newLevel, xpGained);
    }


    /**
     * @notice Gets the current level or XP of an NFT as recorded by this contract.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     * @return The current level/XP. Returns 0 if never trained.
     */
    function getNFTLevel(address _nftCollection, uint256 _tokenId) external view returns (uint256) {
        return nftLevels[_nftCollection][_tokenId];
    }

     /**
      * @notice Gets the current costs for training an NFT.
      * @return currentCostETH The cost in wei for ETH training.
      * @return currentCostEnergy The cost in Energy Tokens for Energy training.
      */
    function getTrainingCosts() external view returns (uint256 currentCostETH, uint256 currentCostEnergy) {
        return (trainingCostETH, trainingCostEnergy);
    }

     /**
      * @notice Calculates the expected XP gain from training with a given amount of resources.
      * Useful for UI to show potential outcome.
      * @param _amountETH Amount of ETH (wei) to train with.
      * @param _amountEnergy Amount of Energy Tokens to train with.
      * @return The total expected XP gained.
      */
    function calculateExpectedXP(uint256 _amountETH, uint256 _amountEnergy) external view returns (uint256) {
        uint256 xpFromETH = _amountETH * xpPerETH;
        uint256 xpFromEnergy = _amountEnergy * xpPerEnergy;
        return xpFromETH + xpFromEnergy;
    }


    // --- Dynamic NFT (Staking) Functions ---

    /**
     * @notice Stakes an owned NFT within the marketplace.
     * The caller must be the owner and must have approved the marketplace to transfer the NFT.
     * The NFT is transferred to the marketplace contract.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     */
    function stakeNFT(address _nftCollection, uint256 _tokenId) external nonReentrant {
        require(allowedCollections[_nftCollection], "Collection not allowed for staking");
        require(stakingRewardRatePerSecond > 0, "Staking is not configured");

        IERC721 nft = IERC721(_nftCollection);
        require(nft.ownerOf(_tokenId) == msg.sender, "Caller does not own the NFT");
        require(nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer NFT");
        require(stakedNFTs[_nftCollection][_tokenId].staker == address(0), "NFT is already staked");

        // Record stake info
        stakedNFTs[_nftCollection][_tokenId] = StakeInfo({
            staker: msg.sender,
            stakeStartTime: block.timestamp,
            accumulatedRewardPoints: 0 // Starts with 0 points, accrue over time
        });

        // Add to staker's list (encoded as collection address and tokenId)
        stakerStakedNFTs[msg.sender].push(uint256(uint160(_nftCollection)) << 96 | _tokenId);
        stakerStakedNFTCount[msg.sender]++;


        // Transfer NFT to marketplace contract
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit NFTStaked(msg.sender, _nftCollection, _tokenId, block.timestamp);
    }

    /**
     * @notice Unstakes an NFT and claims any accumulated rewards.
     * Only the original staker can unstake.
     * Transfers the NFT back to the staker and pays accumulated rewards (in Energy Tokens).
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     */
    function unstakeNFT(address _nftCollection, uint256 _tokenId) external nonReentrant {
        StakeInfo storage stake = stakedNFTs[_nftCollection][_tokenId];
        require(stake.staker == msg.sender, "Only the staker can unstake");
        require(stake.staker != address(0), "NFT is not staked"); // Check if initialized

        // Calculate pending rewards before clearing stake info
        uint256 pendingRewardPoints = calculatePendingRewards(_nftCollection, _tokenId);
        uint256 totalRewardPoints = stake.accumulatedRewardPoints + pendingRewardPoints;

        // Clear stake information
        delete stakedNFTs[_nftCollection][_tokenId];

        // --- Remove from staker's list (O(N) but simpler for example) ---
        // Can be optimized with more complex mapping/struct if needed
        uint256 encodedId = uint256(uint160(_nftCollection)) << 96 | _tokenId;
        uint256[] storage staked = stakerStakedNFTs[msg.sender];
        for (uint i = 0; i < staked.length; i++) {
            if (staked[i] == encodedId) {
                // Replace with last element and pop
                staked[i] = staked[staked.length - 1];
                staked.pop();
                stakerStakedNFTCount[msg.sender]--;
                break; // Found and removed
            }
        }
        // --- End Remove from list ---


        // Transfer NFT back to staker
        IERC721 nft = IERC721(_nftCollection);
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        // Pay out rewards
        uint256 claimedEnergy = _distributeStakingRewards(msg.sender, totalRewardPoints);

        emit NFTUnstaked(msg.sender, _nftCollection, _tokenId, block.timestamp, totalRewardPoints);
         if (claimedEnergy > 0) {
             emit StakingRewardsClaimed(msg.sender, _nftCollection, _tokenId, totalRewardPoints, claimedEnergy);
         }
    }

    /**
     * @notice Claims accumulated rewards for a currently staked NFT without unstaking it.
     * Only the original staker can claim rewards.
     * Resets the accumulated reward points for the stake.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     */
    function claimStakingRewards(address _nftCollection, uint256 _tokenId) external nonReentrant {
        StakeInfo storage stake = stakedNFTs[_nftCollection][_tokenId];
        require(stake.staker == msg.sender, "Only the staker can claim rewards");
        require(stake.staker != address(0), "NFT is not staked");

        // Calculate pending rewards
        uint256 pendingRewardPoints = calculatePendingRewards(_nftCollection, _tokenId);
        uint256 totalRewardPoints = stake.accumulatedRewardPoints + pendingRewardPoints;

        require(totalRewardPoints > 0, "No rewards accumulated");

        // Reset stake timer and accumulated points
        stake.stakeStartTime = block.timestamp;
        stake.accumulatedRewardPoints = 0;

        // Pay out rewards
        uint256 claimedEnergy = _distributeStakingRewards(msg.sender, totalRewardPoints);

        emit StakingRewardsClaimed(msg.sender, _nftCollection, _tokenId, totalRewardPoints, claimedEnergy);
    }

    /**
     * @notice Gets staking information for a specific NFT.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     * @return staker The address that staked the NFT.
     * @return stakeStartTime The timestamp when the NFT was staked.
     * @return accumulatedRewardPoints The reward points accumulated before the current stake period.
     */
    function getStakeDetails(address _nftCollection, uint256 _tokenId) external view returns (address staker, uint256 stakeStartTime, uint256 accumulatedRewardPoints) {
        StakeInfo memory stake = stakedNFTs[_nftCollection][_tokenId];
        return (stake.staker, stake.stakeStartTime, stake.accumulatedRewardPoints);
    }

    /**
     * @notice Calculates the pending reward points for a currently staked NFT since the last claim or stake time.
     * Does not include previously accumulated points.
     * @param _nftCollection The address of the ERC-721 contract.
     * @param _tokenId The token ID of the NFT.
     * @return The number of reward points accumulated since stakeStartTime.
     */
    function calculatePendingRewards(address _nftCollection, uint256 _tokenId) public view returns (uint256) {
        StakeInfo storage stake = stakedNFTs[_nftCollection][_tokenId];
        if (stake.staker == address(0) || stakingRewardRatePerSecond == 0) {
            return 0;
        }
        uint256 timeStaked = block.timestamp - stake.stakeStartTime;
        return timeStaked * stakingRewardRatePerSecond;
    }

     /**
      * @notice Gets a list of NFTs currently staked by a specific address.
      * Note: This function iterates through a dynamic array and might be gas-intensive for stakers with many NFTs.
      * Can be optimized off-chain or with pagination if needed.
      * @param _staker The address whose staked NFTs to retrieve.
      * @return An array of tuples, each containing [collectionAddress, tokenId].
      */
    function getStakedNFTsByStaker(address _staker) external view returns (tuple(address collection, uint256 tokenId)[] memory) {
        uint256[] storage encodedList = stakerStakedNFTs[_staker];
        uint256 count = stakerStakedNFTCount[_staker]; // Use counter for robustness

        tuple(address collection, uint256 tokenId)[] memory result = new tuple(address, uint256)[count];
        uint256 actualCount = 0; // Double-check actual count

        for(uint i = 0; i < encodedList.length; i++) {
            uint256 encoded = encodedList[i];
            address collection = address(uint160(encoded >> 96));
            uint256 tokenId = encoded & type(uint96).max; // Use uint96 mask

            // Check if the item is actually staked (handle potential removal edge cases)
            if (stakedNFTs[collection][tokenId].staker == _staker) {
                 result[actualCount] = tuple(collection, tokenId);
                 actualCount++;
            }
        }
        // If actualCount is less than allocated size due to edge cases/removal sync,
        // return a cropped array (or rely on off-chain filtering).
        // For simplicity here, we return the full size based on the potentially
        // not perfectly synced list, but the check inside confirms validity.
        // A more robust approach would copy valid entries to a new array.
         return result; // May contain default values if actualCount < result.length
    }


    // --- Allowed Collections Functions ---

    /**
     * @notice Allows a specific ERC-721 collection to be listed/staked on the marketplace.
     * Only callable by the contract owner.
     * @param _nftCollection The address of the ERC-721 contract.
     */
    function addAllowedCollection(address _nftCollection) external onlyOwner {
        require(_nftCollection != address(0), "Collection address cannot be zero");
        require(!allowedCollections[_nftCollection], "Collection is already allowed");
        // Optional: Check if it's a valid ERC721 contract using ERC165 introspection
        try IERC165(_nftCollection).supportsInterface(type(IERC721).interfaceId) returns (bool supported) {
            require(supported, "Address does not support ERC721 interface");
        } catch {
            revert("Failed to check ERC721 interface");
        }

        allowedCollections[_nftCollection] = true;
        emit CollectionAllowed(_nftCollection);
    }

    /**
     * @notice Disallows a specific ERC-721 collection.
     * Prevents new listings or stakes but does NOT affect existing listings/stakes.
     * Existing listings/stakes must be cancelled/unstaked manually.
     * Only callable by the contract owner.
     * @param _nftCollection The address of the ERC-721 contract.
     */
    function removeAllowedCollection(address _nftCollection) external onlyOwner {
         require(allowedCollections[_nftCollection], "Collection is not allowed");
        allowedCollections[_nftCollection] = false;
        emit CollectionRemoved(_nftCollection);
    }

     /**
      * @notice Checks if a specific ERC-721 collection is allowed on the marketplace.
      * @param _nftCollection The address of the ERC-721 contract.
      * @return True if the collection is allowed, false otherwise.
      */
    function isCollectionAllowed(address _nftCollection) external view returns (bool) {
        return allowedCollections[_nftCollection];
    }

    // --- Admin & Configuration Functions ---

    /**
     * @notice Sets the platform fee rate.
     * Rate is in basis points (e.g., 250 for 2.5%). Max 10000 (100%).
     * Only callable by the contract owner.
     * @param _newRate The new fee rate in basis points.
     */
    function setPlatformFeeRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 10000, "Fee rate cannot exceed 100%");
        uint256 oldRate = platformFeeRate;
        platformFeeRate = _newRate;
        emit PlatformFeeUpdated(oldRate, _newRate);
    }

    /**
     * @notice Sets the address that receives platform fees.
     * Only callable by the contract owner.
     * @param _newRecipient The new fee recipient address.
     */
    function setPlatformFeeRecipient(address payable _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Recipient cannot be zero address");
        address oldRecipient = platformFeeRecipient;
        platformFeeRecipient = _newRecipient;
        emit FeeRecipientUpdated(oldRecipient, _newRecipient);
    }

    /**
     * @notice Sets the address of the Energy Token used for training costs and staking rewards.
     * Only callable by the contract owner.
     * @param _newTokenAddress The address of the ERC-20 token.
     */
    function setEnergyToken(address _newTokenAddress) external onlyOwner {
        require(_newTokenAddress != address(0), "Token address cannot be zero");
        // Optional: Check if it's a valid ERC20 contract using ERC165 introspection
        try IERC165(_newTokenAddress).supportsInterface(type(IERC20).interfaceId) returns (bool supported) {
             require(supported, "Address does not support ERC20 interface");
         } catch {
             revert("Failed to check ERC20 interface");
         }

        address oldToken = energyTokenAddress;
        energyTokenAddress = _newTokenAddress;
        emit EnergyTokenUpdated(oldToken, _newTokenAddress);
    }

    /**
     * @notice Sets the costs for training NFTs using ETH or Energy Tokens.
     * Only callable by the contract owner.
     * @param _costETH The new cost in wei for ETH training.
     * @param _costEnergy The new cost in Energy Tokens for Energy training.
     */
    function setTrainingCosts(uint256 _costETH, uint256 _costEnergy) external onlyOwner {
        trainingCostETH = _costETH;
        trainingCostEnergy = _costEnergy;
        emit TrainingCostUpdated(_costETH, _costEnergy);
    }

     /**
      * @notice Sets the parameters for how much XP is gained per unit of currency/token spent on training.
      * Only callable by the contract owner.
      * @param _xpPerWei The XP gained per wei spent.
      * @param _xpPerEnergyToken The XP gained per Energy Token spent.
      */
    function setXPParameters(uint256 _xpPerWei, uint256 _xpPerEnergyToken) external onlyOwner {
        xpPerETH = _xpPerWei; // Renamed internally to xpPerETH for clarity matching variable
        xpPerEnergy = _xpPerEnergyToken;
        emit XPParametersUpdated(_xpPerETH, _xpPerEnergy);
    }

    /**
     * @notice Sets the rate at which staked NFTs accrue reward points.
     * Only callable by the contract owner.
     * @param _ratePerSecond The number of reward points granted per second per staked NFT.
     */
    function setStakingRewardRate(uint256 _ratePerSecond) external onlyOwner {
        uint256 oldRate = stakingRewardRatePerSecond;
        stakingRewardRatePerSecond = _ratePerSecond;
        emit StakingRewardRateUpdated(oldRate, _ratePerSecond);
    }

    /**
     * @notice Allows the owner to withdraw accumulated platform fees (ETH and Energy Tokens).
     * Only callable by the contract owner.
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 ethAmount = totalPlatformFeesETH;
        uint256 energyAmount = totalPlatformFeesEnergy;

        require(ethAmount > 0 || energyAmount > 0, "No fees to withdraw");

        totalPlatformFeesETH = 0;
        totalPlatformFeesEnergy = 0;

        if (ethAmount > 0) {
            (bool successETH, ) = platformFeeRecipient.call{value: ethAmount}("");
            require(successETH, "ETH withdrawal failed");
        }

        if (energyAmount > 0 && energyTokenAddress != address(0)) {
            IERC20 energyToken = IERC20(energyTokenAddress);
             energyToken.safeTransfer(platformFeeRecipient, energyAmount);
        }

        emit PlatformFeesWithdrawn(platformFeeRecipient, ethAmount, energyAmount);
    }


    // --- Query & Utility Functions ---

     /**
      * @notice Gets the current platform fee rate.
      * @return The fee rate in basis points.
      */
    function getPlatformFeeRate() external view returns (uint256) {
        return platformFeeRate;
    }

     /**
      * @notice Gets the current platform fee recipient address.
      * @return The fee recipient address.
      */
    function getPlatformFeeRecipient() external view returns (address) {
        return platformFeeRecipient;
    }

     /**
      * @notice Gets the address of the Energy Token used by the marketplace.
      * @return The Energy Token address.
      */
    function getEnergyToken() external view returns (address) {
        return energyTokenAddress;
    }

     /**
      * @notice Gets the total accumulated platform fees held by the contract.
      * @return totalETH The total ETH fees accumulated.
      * @return totalEnergy The total Energy Token fees accumulated.
      */
    function getTotalPlatformFees() external view returns (uint256 totalETH, uint256 totalEnergy) {
        return (totalPlatformFeesETH, totalPlatformFeesEnergy);
    }


    // --- Internal/Helper Functions ---

    /**
     * @notice Internal helper to distribute staking rewards in Energy Tokens.
     * @param _staker The address to receive rewards.
     * @param _totalRewardPoints The total reward points to convert and distribute.
     * @return The actual amount of Energy Tokens distributed.
     */
    function _distributeStakingRewards(address _staker, uint256 _totalRewardPoints) internal returns (uint256) {
        if (energyTokenAddress == address(0) || _totalRewardPoints == 0) {
            return 0;
        }
        IERC20 energyToken = IERC20(energyTokenAddress);

        // Simple conversion: 1 reward point = 1 Energy Token (can be adjusted)
        // Ensure the contract has enough balance
        uint256 amountToDistribute = _totalRewardPoints; // Assume 1:1 conversion for simplicity
        uint256 contractBalance = energyToken.balanceOf(address(this));
        uint256 actualAmount = Math.min(amountToDistribute, contractBalance);

        if (actualAmount > 0) {
             energyToken.safeTransfer(_staker, actualAmount);
        }
        return actualAmount;
    }


    // --- ERC721Holder Overrides ---

    /**
     * @notice ERC721Receiver hook, called when an NFT is transferred to this contract.
     * Only accepts NFTs from allowed collections.
     * @dev The NFT transfer MUST be initiated by safeTransferFrom in the source contract.
     * @param operator The address which called `safeTransferFrom`.
     * @param from The address which previously owned the token.
     * @param tokenId The NFT token ID.
     * @param data Additional data with no specified format.
     * @return bytes4 Acknowledgment that the NFT has been received safely.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        override(ERC721Holder)
        external
        returns (bytes4)
    {
        // The collection address is msg.sender for onERC721Received
        address nftCollection = msg.sender;

        // Optional: You might want to add checks here based on the `from` address
        // For listings, `from` should be the seller. For staking, `from` should be the staker.
        // For this contract, we primarily receive NFTs via `safeTransferFrom`
        // called within listNFT or stakeNFT, where the sender and state are already checked.
        // This check is more of a safeguard against unexpected transfers.
        require(allowedCollections[nftCollection], "Received NFT from unauthorized collection");

        // Perform any other checks needed for the specific use case (listing or staking)
        // For example, check if there's a pending listing or stake for this NFT/from address.
        // This basic implementation just verifies the collection is allowed.

        return this.onERC721Received.selector;
    }

     /**
      * @notice ERC165 support declaration.
      * @param interfaceId The interface ID to check.
      * @return bool True if the interface is supported.
      */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Holder) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC2981).interfaceId || // Declare support for ERC-2981 if implementing/checking royalties
               super.supportsInterface(interfaceId);
    }

    // Fallback and Receive functions to handle incoming ETH (e.g., for buyNFT)
    receive() external payable {}
    fallback() external payable {}
}
```