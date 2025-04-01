```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Marketplace with Reputation and Evolving Traits
 * @author Gemini AI Assistant
 * @dev A decentralized marketplace for Dynamic NFTs with a reputation system and NFTs that can evolve based on on-chain events.
 *
 * Outline and Function Summary:
 *
 * 1.  **DynamicNFT Contract (ERC721):**
 *     - `mintDynamicNFT(address recipient, string memory baseURI)`: Mints a new Dynamic NFT with initial traits and metadata base URI.
 *     - `setBaseURI(string memory newBaseURI)`: Allows the contract owner to set the base URI for NFT metadata.
 *     - `tokenURI(uint256 tokenId)`: Returns the dynamic token URI for a given token ID, incorporating evolving traits.
 *     - `evolveNFT(uint256 tokenId)`: Triggers the evolution of an NFT based on predefined evolution logic. (Example: time-based, interaction-based).
 *     - `getNFTEvolutionStage(uint256 tokenId)`: Returns the current evolution stage of an NFT.
 *     - `setEvolutionLogic(uint256 tokenId, bytes memory logicData)`:  (Advanced) Allows setting custom evolution logic for specific NFTs.
 *
 * 2.  **Marketplace Contract:**
 *     - `listNFTForSale(uint256 tokenId, address nftContractAddress, uint256 price)`: Lists an NFT for sale on the marketplace.
 *     - `buyNFT(uint256 listingId)`: Allows a user to buy an NFT listed on the marketplace.
 *     - `cancelListing(uint256 listingId)`: Allows the seller to cancel a listing.
 *     - `updateListingPrice(uint256 listingId, uint256 newPrice)`: Allows the seller to update the price of a listing.
 *     - `getListingDetails(uint256 listingId)`: Returns details of a specific marketplace listing.
 *     - `getAllListings()`: Returns a list of all active marketplace listings.
 *     - `getListingsBySeller(address seller)`: Returns a list of listings by a specific seller.
 *     - `getListingsByNFTContract(address nftContractAddress)`: Returns listings for a specific NFT contract.
 *
 * 3.  **Reputation System:**
 *     - `rateSeller(address seller, uint8 rating, string memory review)`: Allows buyers to rate sellers after a successful purchase.
 *     - `getSellerReputation(address seller)`: Returns the average reputation score and review count for a seller.
 *     - `getUserProfile(address user)`: Returns a user's profile, including reputation and activity history.
 *     - `reportUser(address user, string memory reason)`: Allows users to report other users for inappropriate behavior. (Requires moderation logic off-chain).
 *     - `moderateReport(uint256 reportId, bool isMalicious)`: (Admin) Moderates user reports, potentially impacting user reputation.
 *
 * 4.  **Platform Management & Utility:**
 *     - `setPlatformFee(uint256 feePercentage)`: (Admin) Sets the platform fee percentage for marketplace sales.
 *     - `withdrawPlatformFees()`: (Admin) Allows the platform owner to withdraw accumulated platform fees.
 *     - `pauseMarketplace()`: (Admin) Pauses the marketplace, preventing new listings and purchases.
 *     - `unpauseMarketplace()`: (Admin) Resumes the marketplace.
 *     - `emergencyStop()`: (Admin) Halts all core functionalities in case of critical issues.
 *     - `setAllowedNFTContract(address nftContractAddress, bool allowed)`: (Admin) Allows or disallows specific NFT contracts to be listed on the marketplace.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    // --- State Variables ---

    string private _baseURI;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint8) public nftEvolutionStage; // TokenId => Evolution Stage
    mapping(uint256 => bytes) public nftEvolutionLogic; // TokenId => Custom Evolution Logic (Advanced)

    struct Listing {
        uint256 id;
        uint256 tokenId;
        address nftContractAddress;
        address seller;
        uint256 price;
        bool isActive;
    }
    Counters.Counter private _listingIdCounter;
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256[]) public sellerListings; // Seller Address => Array of Listing IDs
    mapping(address => uint256[]) public nftContractListings; // NFT Contract Address => Array of Listing IDs

    struct UserProfile {
        uint256 reputationScore; // Aggregate reputation score
        uint256 reviewCount;      // Number of reviews received
        // Add more profile details if needed (e.g., activity history)
    }
    mapping(address => UserProfile) public userProfiles;

    struct SellerRating {
        uint8 rating;
        string review;
        address buyer;
        uint256 timestamp;
    }
    mapping(address => SellerRating[]) public sellerRatings; // Seller Address => Array of Ratings

    struct UserReport {
        uint256 id;
        address reporter;
        address reportedUser;
        string reason;
        uint256 timestamp;
        bool isMalicious; // Moderated by admin
        bool isResolved;
    }
    Counters.Counter private _reportIdCounter;
    mapping(uint256 => UserReport) public userReports;

    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address payable public platformFeeRecipient; // Address to receive platform fees
    bool public marketplacePaused = false;
    bool public emergencyStopped = false;
    mapping(address => bool) public allowedNFTContracts; // Allowed NFT contract addresses for listing

    // --- Events ---

    event NFTMinted(uint256 tokenId, address recipient);
    event NFTEvolved(uint256 tokenId, uint8 newStage);
    event NFTListed(uint256 listingId, uint256 tokenId, address nftContractAddress, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address nftContractAddress, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 listingId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event SellerRated(address seller, address buyer, uint8 rating, string review);
    event UserReported(uint256 reportId, address reporter, address reportedUser, string reason);
    event ReportModerated(uint256 reportId, bool isMalicious);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event EmergencyStopped();
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event AllowedNFTContractSet(address nftContractAddress, bool allowed);

    // --- Modifiers ---

    modifier onlyWhenNotPaused() {
        require(!marketplacePaused, "Marketplace is paused");
        _;
    }

    modifier onlyWhenNotEmergencyStopped() {
        require(!emergencyStopped, "Contract is in emergency stop mode");
        _;
    }

    modifier listingExists(uint256 listingId) {
        require(listings[listingId].id == listingId, "Listing does not exist");
        _;
    }

    modifier listingIsActive(uint256 listingId) {
        require(listings[listingId].isActive, "Listing is not active");
        _;
    }

    modifier onlyListingSeller(uint256 listingId) {
        require(listings[listingId].seller == msg.sender, "Only the seller can perform this action");
        _;
    }

    modifier allowedNFT(address nftContractAddress) {
        require(allowedNFTContracts[nftContractAddress], "NFT contract is not allowed on marketplace");
        _;
    }


    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _baseURI = baseURI;
        platformFeeRecipient = payable(msg.sender); // Owner is default fee recipient
    }

    // --- 1. DynamicNFT Contract Functions ---

    /**
     * @dev Mints a new Dynamic NFT with initial traits and metadata base URI.
     * @param recipient The address to receive the NFT.
     * @param baseURI The base URI for the NFT metadata.
     */
    function mintDynamicNFT(address recipient, string memory baseURI) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(recipient, tokenId);
        _baseURI = baseURI; // Contract level base URI, can be overridden for individual NFTs later (advanced feature)
        nftEvolutionStage[tokenId] = 1; // Initial evolution stage
        emit NFTMinted(tokenId, recipient);
        return tokenId;
    }

    /**
     * @dev Allows the contract owner to set the base URI for NFT metadata.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

    /**
     * @dev Returns the dynamic token URI for a given token ID, incorporating evolving traits.
     * @param tokenId The ID of the NFT token.
     * @return The token URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI;
        uint8 stage = nftEvolutionStage[tokenId];
        // Example dynamic URI logic: Append stage to base URI.  Can be more complex.
        return string(abi.encodePacked(currentBaseURI, "/", tokenId.toString(), "-stage-", uint256(stage).toString(), ".json"));
    }

    /**
     * @dev Triggers the evolution of an NFT based on predefined evolution logic. (Example: time-based, interaction-based).
     * @param tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 tokenId) public onlyWhenNotEmergencyStopped {
        require(_exists(tokenId), "NFT does not exist");
        uint8 currentStage = nftEvolutionStage[tokenId];
        uint8 nextStage = currentStage + 1; // Simple linear evolution. Can be replaced with more complex logic.

        // Example evolution trigger: Time-based (simplistic example - real implementation would be more robust)
        if (block.timestamp % 86400 == 0) { // Evolve every day at midnight (UTC, approximate)
            nftEvolutionStage[tokenId] = nextStage;
            emit NFTEvolved(tokenId, nextStage);
        } else {
            // Evolution conditions not met.
            // In a real application, you might provide more informative feedback.
            revert("NFT evolution conditions not met yet.");
        }

        // Advanced: Custom Evolution Logic (if set)
        if (nftEvolutionLogic[tokenId].length > 0) {
            // Decode and execute custom logic (complex and potentially risky - needs careful design)
            // Example:  (For demonstration only - avoid complex on-chain logic for gas reasons in real applications)
            // bytes memory logicData = nftEvolutionLogic[tokenId];
            // (bool success, bytes memory returnData) = address(this).delegatecall(logicData);
            // if (success) {
            //    // Process returnData if needed
            //    nftEvolutionStage[tokenId] = nextStage; // Example update based on custom logic
            //    emit NFTEvolved(tokenId, nextStage);
            //}
        }
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param tokenId The ID of the NFT.
     * @return The current evolution stage.
     */
    function getNFTEvolutionStage(uint256 tokenId) public view returns (uint8) {
        require(_exists(tokenId), "NFT does not exist");
        return nftEvolutionStage[tokenId];
    }

    /**
     * @dev (Advanced) Allows setting custom evolution logic for specific NFTs.
     *  **Warning:** Use with extreme caution. Complex on-chain logic can be gas-intensive and potentially vulnerable.
     *  This is a placeholder for advanced, potentially off-chain driven evolution.
     * @param tokenId The ID of the NFT.
     * @param logicData Opaque data representing the evolution logic (e.g., bytecode, function selector, parameters).
     */
    function setEvolutionLogic(uint256 tokenId, bytes memory logicData) public onlyOwner {
        require(_exists(tokenId), "NFT does not exist");
        nftEvolutionLogic[tokenId] = logicData;
        // In a real application, you would likely have more structured logic and validation.
    }

    // --- 2. Marketplace Contract Functions ---

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param tokenId The ID of the NFT token.
     * @param nftContractAddress The address of the NFT contract.
     * @param price The listing price in wei.
     */
    function listNFTForSale(uint256 tokenId, address nftContractAddress, uint256 price)
        public
        onlyWhenNotPaused
        onlyWhenNotEmergencyStopped
        allowedNFT(nftContractAddress)
    {
        IERC721 nftContract = IERC721(nftContractAddress);
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not owner of NFT");
        require(price > 0, "Price must be greater than zero");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = Listing({
            id: listingId,
            tokenId: tokenId,
            nftContractAddress: nftContractAddress,
            seller: msg.sender,
            price: price,
            isActive: true
        });
        sellerListings[msg.sender].push(listingId);
        nftContractListings[nftContractAddress].push(listingId);

        // Transfer NFT to marketplace contract to escrow (optional, can be direct sale with approval)
        IERC721(nftContractAddress).transferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(listingId, tokenId, nftContractAddress, msg.sender, price);
    }

    /**
     * @dev Allows a user to buy an NFT listed on the marketplace.
     * @param listingId The ID of the marketplace listing.
     */
    function buyNFT(uint256 listingId)
        public
        payable
        onlyWhenNotPaused
        onlyWhenNotEmergencyStopped
        listingExists(listingId)
        listingIsActive(listingId)
    {
        Listing storage listing = listings[listingId];
        require(msg.value >= listing.price, "Insufficient funds");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        uint256 platformFee = listing.price.mul(platformFeePercentage).div(100);
        uint256 sellerProceeds = listing.price.sub(platformFee);

        // Transfer funds
        payable(listing.seller).transfer(sellerProceeds);
        platformFeeRecipient.transfer(platformFee);

        // Transfer NFT to buyer
        IERC721(listing.nftContractAddress).transferFrom(address(this), msg.sender, listing.tokenId);

        // Update listing status
        listing.isActive = false;

        emit NFTBought(listingId, listing.tokenId, listing.nftContractAddress, msg.sender, listing.seller, listing.price);
    }

    /**
     * @dev Allows the seller to cancel a listing.
     * @param listingId The ID of the marketplace listing to cancel.
     */
    function cancelListing(uint256 listingId)
        public
        onlyWhenNotPaused
        onlyWhenNotEmergencyStopped
        listingExists(listingId)
        listingIsActive(listingId)
        onlyListingSeller(listingId)
    {
        Listing storage listing = listings[listingId];
        listing.isActive = false;

        // Return NFT to seller from escrow (if escrow used)
        IERC721(listing.nftContractAddress).transferFrom(address(this), listing.seller, listing.tokenId);

        emit ListingCancelled(listingId);
    }

    /**
     * @dev Allows the seller to update the price of a listing.
     * @param listingId The ID of the marketplace listing.
     * @param newPrice The new listing price in wei.
     */
    function updateListingPrice(uint256 listingId, uint256 newPrice)
        public
        onlyWhenNotPaused
        onlyWhenNotEmergencyStopped
        listingExists(listingId)
        listingIsActive(listingId)
        onlyListingSeller(listingId)
    {
        require(newPrice > 0, "Price must be greater than zero");
        listings[listingId].price = newPrice;
        emit ListingPriceUpdated(listingId, newPrice);
    }

    /**
     * @dev Returns details of a specific marketplace listing.
     * @param listingId The ID of the marketplace listing.
     * @return Listing details.
     */
    function getListingDetails(uint256 listingId) public view listingExists(listingId) returns (Listing memory) {
        return listings[listingId];
    }

    /**
     * @dev Returns a list of all active marketplace listings.
     * @return Array of active listing IDs.
     */
    function getAllListings() public view returns (uint256[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        uint256[] memory activeListings = new uint256[](listingCount);
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive) {
                activeListings[activeCount] = i;
                activeCount++;
            }
        }
        // Resize array to remove empty elements
        assembly {
            mstore(activeListings, activeCount)
        }
        return activeListings;
    }

    /**
     * @dev Returns a list of listings by a specific seller.
     * @param seller The address of the seller.
     * @return Array of listing IDs by the seller.
     */
    function getListingsBySeller(address seller) public view returns (uint256[] memory) {
        return sellerListings[seller];
    }

    /**
     * @dev Returns listings for a specific NFT contract.
     * @param nftContractAddress The address of the NFT contract.
     * @return Array of listing IDs for the NFT contract.
     */
    function getListingsByNFTContract(address nftContractAddress) public view returns (uint256[] memory) {
        return nftContractListings[nftContractAddress];
    }


    // --- 3. Reputation System Functions ---

    /**
     * @dev Allows buyers to rate sellers after a successful purchase.
     * @param seller The address of the seller to rate.
     * @param rating The rating given by the buyer (e.g., 1-5 stars).
     * @param review Optional review text.
     */
    function rateSeller(address seller, uint8 rating, string memory review) public onlyWhenNotEmergencyStopped {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(seller != msg.sender, "Cannot rate yourself");

        SellerRating memory newRating = SellerRating({
            rating: rating,
            review: review,
            buyer: msg.sender,
            timestamp: block.timestamp
        });
        sellerRatings[seller].push(newRating);

        // Update Seller Profile Reputation
        UserProfile storage profile = userProfiles[seller];
        uint256 currentTotalScore = profile.reputationScore * profile.reviewCount;
        profile.reviewCount++;
        profile.reputationScore = (currentTotalScore + rating) / profile.reviewCount; // Recalculate average

        emit SellerRated(seller, msg.sender, rating, review);
    }

    /**
     * @dev Returns the average reputation score and review count for a seller.
     * @param seller The address of the seller.
     * @return Reputation score and review count.
     */
    function getSellerReputation(address seller) public view returns (uint256 reputationScore, uint256 reviewCount) {
        return (userProfiles[seller].reputationScore, userProfiles[seller].reviewCount);
    }

    /**
     * @dev Returns a user's profile, including reputation and activity history.
     * @param user The address of the user.
     * @return User profile data.
     */
    function getUserProfile(address user) public view returns (UserProfile memory) {
        return userProfiles[user];
    }

    /**
     * @dev Allows users to report other users for inappropriate behavior. (Requires moderation logic off-chain).
     * @param user The address of the user being reported.
     * @param reason The reason for the report.
     */
    function reportUser(address user, string memory reason) public onlyWhenNotEmergencyStopped {
        require(user != msg.sender, "Cannot report yourself");
        require(bytes(reason).length > 0, "Reason cannot be empty");

        _reportIdCounter.increment();
        uint256 reportId = _reportIdCounter.current();

        userReports[reportId] = UserReport({
            id: reportId,
            reporter: msg.sender,
            reportedUser: user,
            reason: reason,
            timestamp: block.timestamp,
            isMalicious: false, // Initially false, needs moderation
            isResolved: false
        });

        emit UserReported(reportId, msg.sender, user, reason);
    }

    /**
     * @dev (Admin) Moderates user reports, potentially impacting user reputation.
     * @param reportId The ID of the user report.
     * @param isMalicious True if the report is deemed malicious or valid, false otherwise.
     */
    function moderateReport(uint256 reportId, bool isMalicious) public onlyOwner onlyWhenNotEmergencyStopped {
        require(!userReports[reportId].isResolved, "Report already resolved");
        userReports[reportId].isMalicious = isMalicious;
        userReports[reportId].isResolved = true;

        // Example: Negative impact on reputation if report is malicious (can be customized)
        if (isMalicious) {
            UserProfile storage profile = userProfiles[userReports[reportId].reportedUser];
            if (profile.reputationScore > 0) {
                profile.reputationScore = profile.reputationScore.sub(1); // Simple reputation penalty
            }
        }

        emit ReportModerated(reportId, isMalicious);
    }


    // --- 4. Platform Management & Utility Functions ---

    /**
     * @dev (Admin) Sets the platform fee percentage for marketplace sales.
     * @param feePercentage The new platform fee percentage (e.g., 2 for 2%).
     */
    function setPlatformFee(uint256 feePercentage) public onlyOwner {
        require(feePercentage <= 100, "Fee percentage cannot exceed 100%");
        platformFeePercentage = feePercentage;
        emit PlatformFeeSet(feePercentage);
    }

    /**
     * @dev (Admin) Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No platform fees to withdraw");
        platformFeeRecipient.transfer(balance);
        emit PlatformFeesWithdrawn(balance, platformFeeRecipient);
    }

    /**
     * @dev (Admin) Pauses the marketplace, preventing new listings and purchases.
     */
    function pauseMarketplace() public onlyOwner {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev (Admin) Resumes the marketplace.
     */
    function unpauseMarketplace() public onlyOwner {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    /**
     * @dev (Admin) Halts all core functionalities in case of critical issues.
     *  Emergency stop is irreversible in this simplified example. More advanced implementations
     *  might have a recovery mechanism.
     */
    function emergencyStop() public onlyOwner {
        emergencyStopped = true;
        marketplacePaused = true; // Also pause marketplace
        emit EmergencyStopped();
    }

    /**
     * @dev (Admin) Allows or disallows specific NFT contracts to be listed on the marketplace.
     * @param nftContractAddress The address of the NFT contract.
     * @param allowed True to allow, false to disallow.
     */
    function setAllowedNFTContract(address nftContractAddress, bool allowed) public onlyOwner {
        allowedNFTContracts[nftContractAddress] = allowed;
        emit AllowedNFTContractSet(nftContractAddress, allowed);
    }

    // --- ERC721 Support (Optional - if you want to mint NFTs from this contract) ---
    // _beforeTokenTransfer, _approve, _setApprovalForAll, getApproved, isApprovedForAll - Inherited from ERC721

    // --- Receive Function for ETH (in case someone sends ETH directly) ---
    receive() external payable {}
    fallback() external payable {}
}

// --- Interface for external ERC721 contracts ---
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address approved, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
```