```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Content NFT Marketplace with Advanced Features
 * @author Gemini AI Assistant
 * @dev This contract implements a dynamic content NFT marketplace with advanced and creative functionalities.
 * It goes beyond basic marketplaces by incorporating dynamic NFT content updates, decentralized curation,
 * fractional ownership, content streaming access, and more.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Marketplace Functions:**
 *    - `createCollection(string _collectionName, string _collectionSymbol, string _baseURI)`: Allows platform admin to create new NFT collections.
 *    - `mintNFT(uint256 _collectionId, address _recipient, string _initialContentURI, string _metadataURI)`: Mints a new NFT within a collection.
 *    - `listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price)`: Allows NFT owner to list their NFT for sale.
 *    - `buyNFT(uint256 _collectionId, uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 *    - `cancelListing(uint256 _collectionId, uint256 _tokenId)`: Allows NFT owner to cancel a listing.
 *    - `updateNFTPrice(uint256 _collectionId, uint256 _tokenId, uint256 _newPrice)`: Allows NFT owner to update the price of a listed NFT.
 *    - `getNFTDetails(uint256 _collectionId, uint256 _tokenId)`: Retrieves detailed information about a specific NFT.
 *    - `getCollectionDetails(uint256 _collectionId)`: Retrieves details about a specific collection.
 *
 * **2. Dynamic Content and Streaming Features:**
 *    - `updateNFTContentURI(uint256 _collectionId, uint256 _tokenId, string _newContentURI)`: Allows authorized entity to update the content URI of an NFT, enabling dynamic content.
 *    - `streamContent(uint256 _collectionId, uint256 _tokenId)`: Allows authorized users (e.g., NFT holders) to access/stream the dynamic content associated with an NFT. (Simulated Streaming Access).
 *
 * **3. Decentralized Curation and Content Moderation:**
 *    - `proposeContentUpdate(uint256 _collectionId, uint256 _tokenId, string _proposedContentURI)`: Allows community members to propose content updates for NFTs.
 *    - `voteOnContentUpdate(uint256 _collectionId, uint256 _tokenId, bool _approve)`: Allows NFT holders to vote on proposed content updates.
 *    - `finalizeContentUpdate(uint256 _collectionId, uint256 _tokenId)`: Allows admin to finalize content updates based on voting results.
 *
 * **4. Fractional Ownership Features:**
 *    - `fractionalizeNFT(uint256 _collectionId, uint256 _tokenId, uint256 _numberOfFractions)`: Allows NFT owner to fractionalize their NFT into ERC20 tokens.
 *    - `redeemFractionsForNFT(uint256 _collectionId, uint256 _tokenId)`: Allows fraction holders to redeem fractions to claim back the original NFT (requires majority of fractions).
 *
 * **5. Advanced Access Control and Royalties:**
 *    - `setCollectionRoyalties(uint256 _collectionId, uint256 _royaltyPercentage)`: Allows collection creator to set royalties on secondary sales.
 *    - `withdrawRoyalties(uint256 _collectionId)`: Allows collection creator to withdraw accumulated royalties.
 *    - `grantContentAccess(uint256 _collectionId, uint256 _tokenId, address _user, uint256 _durationSeconds)`: Grants temporary content access to specific users.
 *    - `revokeContentAccess(uint256 _collectionId, uint256 _tokenId, address _user)`: Revokes content access from a user.
 *
 * **6. Platform Utility Functions:**
 *    - `setPlatformFee(uint256 _feePercentage)`: Allows platform admin to set platform fees on sales.
 *    - `withdrawPlatformFees()`: Allows platform admin to withdraw accumulated platform fees.
 *    - `pauseContract()`: Allows platform admin to pause the contract in case of emergency.
 *    - `unpauseContract()`: Allows platform admin to unpause the contract.
 */

contract DynamicContentNFTMarketplace {
    // --- State Variables ---

    address public platformAdmin;
    uint256 public platformFeePercentage; // Percentage of sale price taken as platform fee

    uint256 public collectionCounter;
    mapping(uint256 => Collection) public collections;

    struct Collection {
        string name;
        string symbol;
        string baseURI;
        address creator;
        uint256 royaltyPercentage;
        uint256 royaltyBalance;
        uint256 nextTokenId;
        mapping(uint256 => NFT) nfts;
        mapping(uint256 => Listing) listings;
    }

    struct NFT {
        uint256 tokenId;
        address owner;
        string contentURI;
        string metadataURI;
        uint256 lastContentUpdateTimestamp;
        mapping(address => uint256) contentAccessExpiry; // User -> Expiry Timestamp
    }

    struct Listing {
        uint256 price;
        address seller;
        bool isActive;
    }

    mapping(uint256 => mapping(uint256 => mapping(address => Vote))) public contentUpdateVotes; // collectionId -> tokenId -> voter -> Vote
    struct Vote {
        bool approved;
        bool hasVoted;
    }

    bool public paused;

    // --- Events ---
    event CollectionCreated(uint256 collectionId, string collectionName, string collectionSymbol, address creator);
    event NFTMinted(uint256 collectionId, uint256 tokenId, address recipient, string contentURI, string metadataURI);
    event NFTListedForSale(uint256 collectionId, uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 collectionId, uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 collectionId, uint256 tokenId);
    event NFTPriceUpdated(uint256 collectionId, uint256 tokenId, uint256 newPrice);
    event NFTContentURIUpdated(uint256 collectionId, uint256 tokenId, string newContentURI);
    event ContentUpdateProposed(uint256 collectionId, uint256 tokenId, string proposedContentURI, address proposer);
    event VoteCastOnContentUpdate(uint256 collectionId, uint256 tokenId, address voter, bool approved);
    event ContentUpdateFinalized(uint256 collectionId, uint256 tokenId, string finalContentURI);
    event NFTHractionalized(uint256 collectionId, uint256 tokenId, uint256 numberOfFractions); // Placeholder event - requires ERC20 integration for actual fractions
    event FractionsRedeemedForNFT(uint256 collectionId, uint256 tokenId, address redeemer); // Placeholder event
    event CollectionRoyaltiesSet(uint256 collectionId, uint256 royaltyPercentage);
    event RoyaltiesWithdrawn(uint256 collectionId, uint256 amount, address recipient);
    event ContentAccessGranted(uint256 collectionId, uint256 tokenId, address user, uint256 expiryTimestamp);
    event ContentAccessRevoked(uint256 collectionId, uint256 tokenId, address user);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can call this function.");
        _;
    }

    modifier onlyCollectionCreator(uint256 _collectionId) {
        require(collections[_collectionId].creator == msg.sender, "Only collection creator can call this function.");
        _;
    }

    modifier onlyNFTOwner(uint256 _collectionId, uint256 _tokenId) {
        require(collections[_collectionId].nfts[_tokenId].owner == msg.sender, "Only NFT owner can call this function.");
        _;
    }

    modifier validCollection(uint256 _collectionId) {
        require(_collectionId > 0 && _collectionId <= collectionCounter, "Invalid collection ID.");
        _;
    }

    modifier validNFT(uint256 _collectionId, uint256 _tokenId) {
        require(_tokenId > 0 && collections[_collectionId].nfts[_tokenId].owner != address(0), "Invalid NFT ID.");
        _;
    }

    modifier isNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _initialPlatformFeePercentage) {
        platformAdmin = msg.sender;
        platformFeePercentage = _initialPlatformFeePercentage;
        collectionCounter = 0;
        paused = false;
        emit PlatformFeeSet(_initialPlatformFeePercentage);
    }

    // --- 1. Core Marketplace Functions ---

    /// @notice Allows platform admin to create new NFT collections.
    /// @param _collectionName The name of the collection.
    /// @param _collectionSymbol The symbol of the collection.
    /// @param _baseURI The base URI for metadata.
    function createCollection(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _baseURI
    ) external onlyPlatformAdmin isNotPaused returns (uint256 collectionId) {
        collectionCounter++;
        collectionId = collectionCounter;
        collections[collectionId] = Collection({
            name: _collectionName,
            symbol: _collectionSymbol,
            baseURI: _baseURI,
            creator: msg.sender,
            royaltyPercentage: 0, // Default royalty to 0%
            royaltyBalance: 0,
            nextTokenId: 1,
            nfts: mapping(uint256 => NFT)(),
            listings: mapping(uint256 => Listing)()
        });
        emit CollectionCreated(collectionId, _collectionName, _collectionSymbol, msg.sender);
    }

    /// @notice Mints a new NFT within a collection.
    /// @param _collectionId The ID of the collection to mint into.
    /// @param _recipient The address to receive the NFT.
    /// @param _initialContentURI The initial content URI of the NFT.
    /// @param _metadataURI The metadata URI of the NFT.
    function mintNFT(
        uint256 _collectionId,
        address _recipient,
        string memory _initialContentURI,
        string memory _metadataURI
    ) external validCollection(_collectionId) onlyCollectionCreator(_collectionId) isNotPaused returns (uint256 tokenId) {
        tokenId = collections[_collectionId].nextTokenId;
        collections[_collectionId].nfts[tokenId] = NFT({
            tokenId: tokenId,
            owner: _recipient,
            contentURI: _initialContentURI,
            metadataURI: _metadataURI,
            lastContentUpdateTimestamp: block.timestamp,
            contentAccessExpiry: mapping(address => uint256)()
        });
        collections[_collectionId].nextTokenId++;
        emit NFTMinted(_collectionId, tokenId, _recipient, _initialContentURI, _metadataURI);
    }

    /// @notice Allows NFT owner to list their NFT for sale.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listNFTForSale(
        uint256 _collectionId,
        uint256 _tokenId,
        uint256 _price
    ) external validCollection(_collectionId) validNFT(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) isNotPaused {
        collections[_collectionId].listings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit NFTListedForSale(_collectionId, _tokenId, _price, msg.sender);
    }

    /// @notice Allows anyone to buy a listed NFT.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _collectionId, uint256 _tokenId)
        external
        payable
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        isNotPaused
    {
        Listing storage listing = collections[_collectionId].listings[_tokenId];
        require(listing.isActive, "NFT is not listed for sale.");
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 platformFee = (listing.price * platformFeePercentage) / 10000; // Fee calculated in percentage
        uint256 royaltyFee = (listing.price * collections[_collectionId].royaltyPercentage) / 10000;
        uint256 sellerProceeds = listing.price - platformFee - royaltyFee;

        // Transfer proceeds to seller
        payable(listing.seller).transfer(sellerProceeds);

        // Transfer platform fees to platform admin (or collect in contract for later withdrawal)
        payable(platformAdmin).transfer(platformFee);

        // Accumulate royalties for collection creator
        collections[_collectionId].royaltyBalance += royaltyFee;

        // Transfer NFT ownership
        collections[_collectionId].nfts[_tokenId].owner = msg.sender;

        // Deactivate listing
        listing.isActive = false;

        emit NFTBought(_collectionId, _tokenId, msg.sender, listing.price);
    }

    /// @notice Allows NFT owner to cancel a listing.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to cancel listing for.
    function cancelListing(uint256 _collectionId, uint256 _tokenId)
        external
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        onlyNFTOwner(_collectionId, _tokenId)
        isNotPaused
    {
        require(collections[_collectionId].listings[_tokenId].isActive, "NFT is not listed.");
        collections[_collectionId].listings[_tokenId].isActive = false;
        emit NFTListingCancelled(_collectionId, _tokenId);
    }

    /// @notice Allows NFT owner to update the price of a listed NFT.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to update price for.
    /// @param _newPrice The new listing price in wei.
    function updateNFTPrice(
        uint256 _collectionId,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        onlyNFTOwner(_collectionId, _tokenId)
        isNotPaused
    {
        require(collections[_collectionId].listings[_tokenId].isActive, "NFT is not listed.");
        collections[_collectionId].listings[_tokenId].price = _newPrice;
        emit NFTPriceUpdated(_collectionId, _tokenId, _newPrice);
    }

    /// @notice Retrieves detailed information about a specific NFT.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT.
    /// @return NFT details (owner, contentURI, metadataURI, lastContentUpdateTimestamp).
    function getNFTDetails(uint256 _collectionId, uint256 _tokenId)
        external
        view
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        returns (address owner, string memory contentURI, string memory metadataURI, uint256 lastContentUpdateTimestamp)
    {
        NFT storage nft = collections[_collectionId].nfts[_tokenId];
        return (nft.owner, nft.contentURI, nft.metadataURI, nft.lastContentUpdateTimestamp);
    }

    /// @notice Retrieves details about a specific collection.
    /// @param _collectionId The ID of the collection.
    /// @return Collection details (name, symbol, baseURI, creator, royaltyPercentage).
    function getCollectionDetails(uint256 _collectionId)
        external
        view
        validCollection(_collectionId)
        returns (string memory name, string memory symbol, string memory baseURI, address creator, uint256 royaltyPercentage)
    {
        Collection storage collection = collections[_collectionId];
        return (collection.name, collection.symbol, collection.baseURI, collection.creator, collection.royaltyPercentage);
    }


    // --- 2. Dynamic Content and Streaming Features ---

    /// @notice Allows authorized entity (e.g., collection creator or designated updater) to update the content URI of an NFT, enabling dynamic content.
    /// @dev In a real-world scenario, authorization logic might be more complex (e.g., using roles, external oracles, etc.).
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to update content for.
    /// @param _newContentURI The new content URI for the NFT.
    function updateNFTContentURI(
        uint256 _collectionId,
        uint256 _tokenId,
        string memory _newContentURI
    ) external validCollection(_collectionId) validNFT(_collectionId, _tokenId) onlyCollectionCreator(_collectionId) isNotPaused {
        collections[_collectionId].nfts[_tokenId].contentURI = _newContentURI;
        collections[_collectionId].nfts[_tokenId].lastContentUpdateTimestamp = block.timestamp;
        emit NFTContentURIUpdated(_collectionId, _tokenId, _newContentURI);
    }

    /// @notice Allows authorized users (e.g., NFT holders, users with granted access) to access/stream the dynamic content associated with an NFT. (Simulated Streaming Access).
    /// @dev This function simulates content streaming access by checking if the sender is the owner or has granted access and returning the content URI.
    /// @dev In a real-world streaming platform, this would integrate with actual streaming infrastructure.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to stream content from.
    /// @return The content URI of the NFT if access is granted, otherwise empty string.
    function streamContent(uint256 _collectionId, uint256 _tokenId)
        external
        view
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        returns (string memory contentURI)
    {
        NFT storage nft = collections[_collectionId].nfts[_tokenId];
        if (nft.owner == msg.sender || nft.contentAccessExpiry[msg.sender] > block.timestamp) {
            return nft.contentURI;
        } else {
            return ""; // Or revert with an error for unauthorized access in a stricter implementation
        }
    }


    // --- 3. Decentralized Curation and Content Moderation ---

    /// @notice Allows community members to propose content updates for NFTs.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to propose update for.
    /// @param _proposedContentURI The proposed new content URI.
    function proposeContentUpdate(
        uint256 _collectionId,
        uint256 _tokenId,
        string memory _proposedContentURI
    ) external validCollection(_collectionId) validNFT(_collectionId, _tokenId) isNotPaused {
        emit ContentUpdateProposed(_collectionId, _tokenId, _proposedContentURI, msg.sender);
    }

    /// @notice Allows NFT holders to vote on proposed content updates.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to vote on.
    /// @param _approve True to approve the update, false to reject.
    function voteOnContentUpdate(
        uint256 _collectionId,
        uint256 _tokenId,
        bool _approve
    ) external validCollection(_collectionId) validNFT(_collectionId, _tokenId) isNotPaused {
        require(collections[_collectionId].nfts[_tokenId].owner == msg.sender, "Only NFT owner can vote."); // Only owner voting for simplicity. Can be expanded to fraction holders etc.
        require(!contentUpdateVotes[_collectionId][_tokenId][msg.sender].hasVoted, "Already voted on this proposal.");

        contentUpdateVotes[_collectionId][_tokenId][msg.sender] = Vote({
            approved: _approve,
            hasVoted: true
        });
        emit VoteCastOnContentUpdate(_collectionId, _tokenId, msg.sender, _approve);
    }

    /// @notice Allows admin to finalize content updates based on voting results (simplified majority for example).
    /// @dev  Simple majority logic is implemented here for demo purpose. More complex voting mechanisms can be integrated.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to finalize update for.
    function finalizeContentUpdate(uint256 _collectionId, uint256 _tokenId)
        external
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        onlyCollectionCreator(_collectionId) // Only collection creator can finalize for this example. Can be DAO/Governance driven.
        isNotPaused
    {
        uint256 approveVotes = 0;
        uint256 rejectVotes = 0;
        uint256 totalVoters = 0;

        // In a real scenario, you'd iterate through all voters (e.g., stored in a list or mapping)
        // For this example, we are assuming only NFT owner can vote, so we just check their vote.
        address nftOwner = collections[_collectionId].nfts[_tokenId].owner;
        if (contentUpdateVotes[_collectionId][_tokenId][nftOwner].hasVoted) {
            totalVoters++;
            if (contentUpdateVotes[_collectionId][_tokenId][nftOwner].approved) {
                approveVotes++;
            } else {
                rejectVotes++;
            }
        }

        if (approveVotes > rejectVotes && totalVoters > 0) { // Simple majority rule
            // In a real implementation, you might fetch the proposed content URI from an event or storage.
            // For simplicity, we'll assume the latest proposed URI is the one to be finalized.
            //  **Important:** Storing proposed URI on-chain securely is important in a real system.
            string memory finalContentURI = collections[_collectionId].nfts[_tokenId].contentURI; // Using current content URI as a placeholder for finalized URI.
            updateNFTContentURI(_collectionId, _tokenId, finalContentURI);
            emit ContentUpdateFinalized(_collectionId, _tokenId, finalContentURI);
        } else {
            // Content update rejected or no votes. Handle accordingly.
            // For now, do nothing. In a real system, you might emit an event.
        }
    }


    // --- 4. Fractional Ownership Features ---
    // --- Placeholder functions for Fractionalization. Requires ERC20 token contract and more complex logic ---

    /// @notice Allows NFT owner to fractionalize their NFT into ERC20 tokens. (Placeholder - requires ERC20 integration).
    /// @dev In a real implementation, this would involve deploying an ERC20 contract, locking the NFT in escrow, and distributing ERC20 tokens representing fractions.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to fractionalize.
    /// @param _numberOfFractions The number of fractions to create.
    function fractionalizeNFT(
        uint256 _collectionId,
        uint256 _tokenId,
        uint256 _numberOfFractions
    ) external validCollection(_collectionId) validNFT(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) isNotPaused {
        // --- Placeholder Logic ---
        // 1. Deploy ERC20 token contract representing fractions.
        // 2. Transfer NFT to escrow contract.
        // 3. Mint and distribute ERC20 tokens to NFT owner.
        // --- End Placeholder Logic ---
        emit NFTHractionalized(_collectionId, _tokenId, _numberOfFractions); // Placeholder event
        // In a real implementation, you would return the address of the deployed ERC20 contract.
    }

    /// @notice Allows fraction holders to redeem fractions to claim back the original NFT (requires majority of fractions). (Placeholder - requires ERC20 integration).
    /// @dev In a real implementation, this would require checking for majority fraction holding, burning fractions, and transferring NFT back from escrow.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT to redeem fractions for.
    function redeemFractionsForNFT(uint256 _collectionId, uint256 _tokenId)
        external
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        isNotPaused
    {
        // --- Placeholder Logic ---
        // 1. Check if msg.sender holds majority of fractions.
        // 2. Burn the fractions held by msg.sender and other fraction holders (if needed for majority).
        // 3. Transfer NFT from escrow back to msg.sender.
        // --- End Placeholder Logic ---
        emit FractionsRedeemedForNFT(_collectionId, _tokenId, msg.sender); // Placeholder event
    }


    // --- 5. Advanced Access Control and Royalties ---

    /// @notice Allows collection creator to set royalties on secondary sales for their collection.
    /// @param _collectionId The ID of the collection.
    /// @param _royaltyPercentage The royalty percentage (e.g., 500 for 5%).
    function setCollectionRoyalties(uint256 _collectionId, uint256 _royaltyPercentage)
        external
        validCollection(_collectionId)
        onlyCollectionCreator(_collectionId)
        isNotPaused
    {
        require(_royaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%.");
        collections[_collectionId].royaltyPercentage = _royaltyPercentage;
        emit CollectionRoyaltiesSet(_collectionId, _royaltyPercentage);
    }

    /// @notice Allows collection creator to withdraw accumulated royalties.
    /// @param _collectionId The ID of the collection.
    function withdrawRoyalties(uint256 _collectionId)
        external
        validCollection(_collectionId)
        onlyCollectionCreator(_collectionId)
        isNotPaused
    {
        uint256 royaltyBalance = collections[_collectionId].royaltyBalance;
        require(royaltyBalance > 0, "No royalties to withdraw.");
        collections[_collectionId].royaltyBalance = 0;
        payable(msg.sender).transfer(royaltyBalance);
        emit RoyaltiesWithdrawn(_collectionId, royaltyBalance, msg.sender);
    }

    /// @notice Grants temporary content access to specific users for an NFT.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT.
    /// @param _user The address to grant access to.
    /// @param _durationSeconds The duration of access in seconds.
    function grantContentAccess(
        uint256 _collectionId,
        uint256 _tokenId,
        address _user,
        uint256 _durationSeconds
    ) external validCollection(_collectionId) validNFT(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) isNotPaused {
        collections[_collectionId].nfts[_tokenId].contentAccessExpiry[_user] = block.timestamp + _durationSeconds;
        emit ContentAccessGranted(_collectionId, _tokenId, _user, block.timestamp + _durationSeconds);
    }

    /// @notice Revokes content access from a user for an NFT.
    /// @param _collectionId The ID of the collection.
    /// @param _tokenId The ID of the NFT.
    /// @param _user The address to revoke access from.
    function revokeContentAccess(uint256 _collectionId, uint256 _tokenId, address _user)
        external
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        onlyNFTOwner(_collectionId, _tokenId)
        isNotPaused
    {
        delete collections[_collectionId].nfts[_tokenId].contentAccessExpiry[_user];
        emit ContentAccessRevoked(_collectionId, _tokenId, _user);
    }


    // --- 6. Platform Utility Functions ---

    /// @notice Allows platform admin to set platform fees on sales.
    /// @param _feePercentage The platform fee percentage (e.g., 250 for 2.5%).
    function setPlatformFee(uint256 _feePercentage) external onlyPlatformAdmin isNotPaused {
        require(_feePercentage <= 10000, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Allows platform admin to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyPlatformAdmin isNotPaused {
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableFees = contractBalance; // Assuming all contract balance is platform fees for simplicity. In real world, more robust tracking might be needed.
        require(withdrawableFees > 0, "No platform fees to withdraw.");
        payable(platformAdmin).transfer(withdrawableFees);
        emit PlatformFeesWithdrawn(withdrawableFees, platformAdmin);
    }

    /// @notice Allows platform admin to pause the contract in case of emergency.
    function pauseContract() external onlyPlatformAdmin isNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Allows platform admin to unpause the contract.
    function unpauseContract() external onlyPlatformAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Fallback function to prevent accidental sending of Ether to contract ---
    receive() external payable {
        revert("This contract does not accept direct Ether payments. Use buyNFT function to purchase NFTs.");
    }
}
```