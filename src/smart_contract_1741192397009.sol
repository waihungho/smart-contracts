```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Marketplace with Social & Governance Features - "Evolving Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace with social interactions, on-chain governance,
 *      and evolving NFT properties. This marketplace is designed to be more than just a trading platform;
 *      it's a community hub where NFTs can evolve, interact, and be governed by its users.
 *
 * **Contract Outline and Function Summary:**
 *
 * **1. NFT Collection Management:**
 *    - `createNFTCollection(string _name, string _symbol, string _baseURI)`: Allows platform owner to create new NFT collections.
 *    - `setCollectionBaseURI(uint256 _collectionId, string _baseURI)`: Allows collection owner to update the base URI of a collection.
 *    - `setCollectionRoyalties(uint256 _collectionId, uint256 _royaltyPercentage)`: Allows collection owner to set royalties for secondary sales.
 *
 * **2. NFT Minting & Metadata:**
 *    - `mintNFT(uint256 _collectionId, address _recipient, string _tokenURI, bytes _initialData)`: Mints a new NFT within a collection with initial data.
 *    - `updateNFTMetadata(uint256 _tokenId, string _newTokenURI)`: Allows NFT owner to update the token URI (metadata) of their NFT.
 *    - `updateNFTData(uint256 _tokenId, bytes _newData)`: Allows NFT owner to update dynamic, on-chain data associated with their NFT.
 *    - `getNFTData(uint256 _tokenId)`: Retrieves the dynamic, on-chain data associated with an NFT.
 *
 * **3. Marketplace Listing & Trading:**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owner to list their NFT for sale in the marketplace.
 *    - `buyNFT(uint256 _listingId)`: Allows anyone to purchase an NFT listed in the marketplace.
 *    - `delistNFT(uint256 _listingId)`: Allows NFT owner to delist their NFT from the marketplace.
 *    - `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows NFT owner to update the price of their listed NFT.
 *    - `cancelListing(uint256 _listingId)`: Allows NFT owner to cancel a listing and reclaim the NFT.
 *
 * **4. Social Interaction Features:**
 *    - `likeNFT(uint256 _tokenId)`: Allows users to "like" an NFT, tracked on-chain.
 *    - `commentOnNFT(uint256 _tokenId, string _comment)`: Allows users to leave comments on NFTs, stored on-chain.
 *    - `getUserNFTLikes(address _user)`: Retrieves a list of NFTs liked by a specific user.
 *    - `getNFTComments(uint256 _tokenId)`: Retrieves comments associated with a specific NFT.
 *
 * **5. Governance & Platform Control:**
 *    - `submitGovernanceProposal(string _title, string _description, bytes _payload)`: Allows token holders to submit governance proposals.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows token holders to vote on active governance proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal (if conditions are met).
 *    - `setPlatformFee(uint256 _newFeePercentage)`: Governance-controlled function to set the platform fee.
 *    - `withdrawPlatformFees()`: Allows platform owner (or governance if delegated) to withdraw accumulated platform fees.
 *
 * **6. Utility Functions:**
 *    - `getListingDetails(uint256 _listingId)`: Retrieves details of a specific marketplace listing.
 *    - `getCollectionDetails(uint256 _collectionId)`: Retrieves details of a specific NFT collection.
 *    - `getTotalListings()`: Returns the total number of active listings in the marketplace.
 *    - `getPlatformFee()`: Returns the current platform fee percentage.
 */

contract EvolvingCanvasMarketplace {
    // --- State Variables ---

    address public platformOwner; // Address of the platform owner
    uint256 public platformFeePercentage = 2; // Platform fee percentage (e.g., 2% default)
    uint256 public governanceTokenSupply = 1000000; // Example Governance Token supply (ERC20 could be used in real case)
    mapping(address => uint256) public governanceTokenBalance; // Balance of governance tokens for users

    uint256 public nextCollectionId = 1;
    struct NFTCollection {
        uint256 id;
        string name;
        string symbol;
        string baseURI;
        address owner; // Owner who created the collection
        uint256 royaltyPercentage; // Royalty percentage for secondary sales
    }
    mapping(uint256 => NFTCollection) public nftCollections;

    uint256 public nextNFTId = 1;
    struct NFT {
        uint256 id;
        uint256 collectionId;
        address owner;
        string tokenURI;
        bytes data; // Dynamic, on-chain data associated with the NFT
    }
    mapping(uint256 => NFT) public nfts;
    mapping(uint256 => address) public nftApprovals; // NFT approvals for transfers

    uint256 public nextListingId = 1;
    struct MarketplaceListing {
        uint256 id;
        uint256 nftId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => MarketplaceListing) public listings;
    uint256 public activeListingCount = 0;

    mapping(uint256 => address[]) public nftLikes; // Mapping tokenId to array of addresses who liked it
    mapping(uint256 => string[]) public nftComments; // Mapping tokenId to array of comments

    uint256 public nextProposalId = 1;
    struct GovernanceProposal {
        uint256 id;
        string title;
        string description;
        bytes payload; // Data for proposal execution
        address proposer;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public proposalVotingDuration = 7 days; // Default proposal voting duration

    // --- Events ---
    event CollectionCreated(uint256 collectionId, string name, string symbol, address owner);
    event NFTMinted(uint256 tokenId, uint256 collectionId, address recipient);
    event NFTMetadataUpdated(uint256 tokenId, string newTokenURI);
    event NFTDataUpdated(uint256 tokenId, uint256 nftId);
    event NFTListed(uint256 listingId, uint256 nftId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 nftId, address buyer, uint256 price);
    event NFTDelisted(uint256 listingId, uint256 nftId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event ListingCancelled(uint256 listingId, uint256 nftId);
    event NFTLiked(uint256 tokenId, address user);
    event NFTCommented(uint256 tokenId, address user, string comment);
    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner allowed");
        _;
    }

    modifier onlyCollectionOwner(uint256 _collectionId) {
        require(nftCollections[_collectionId].owner == msg.sender, "Only collection owner allowed");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nfts[_tokenId].owner == msg.sender, "Only NFT owner allowed");
        _;
    }

    modifier onlyListedNFTOwner(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "Only listed NFT owner allowed");
        _;
    }

    modifier onlyActiveListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier onlyGovernanceTokenHolders() {
        require(governanceTokenBalance[msg.sender] > 0, "Must hold governance tokens");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp >= governanceProposals[_proposalId].votingStartTime && block.timestamp <= governanceProposals[_proposalId].votingEndTime, "Proposal voting not active");
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        require(block.timestamp > governanceProposals[_proposalId].votingEndTime, "Voting not yet ended");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed");
        require(governanceProposals[_proposalId].yesVotes > governanceProposals[_proposalId].noVotes, "Proposal did not pass"); // Simple majority for example
        _;
    }

    // --- Constructor ---
    constructor() {
        platformOwner = msg.sender;
        // Distribute initial governance tokens (example - could be more sophisticated)
        governanceTokenBalance[msg.sender] = governanceTokenSupply; // Platform owner gets all initial tokens
    }

    // --- 1. NFT Collection Management ---
    function createNFTCollection(string memory _name, string memory _symbol, string memory _baseURI) external onlyOwner returns (uint256 collectionId) {
        collectionId = nextCollectionId++;
        nftCollections[collectionId] = NFTCollection({
            id: collectionId,
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI,
            owner: msg.sender, // Creator of the collection is the owner
            royaltyPercentage: 5 // Default royalty percentage, can be changed later
        });
        emit CollectionCreated(collectionId, _name, _symbol, msg.sender);
    }

    function setCollectionBaseURI(uint256 _collectionId, string memory _baseURI) external onlyCollectionOwner(_collectionId) {
        nftCollections[_collectionId].baseURI = _baseURI;
    }

    function setCollectionRoyalties(uint256 _collectionId, uint256 _royaltyPercentage) external onlyCollectionOwner(_collectionId) {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        nftCollections[_collectionId].royaltyPercentage = _royaltyPercentage;
    }

    // --- 2. NFT Minting & Metadata ---
    function mintNFT(uint256 _collectionId, address _recipient, string memory _tokenURI, bytes memory _initialData) external onlyCollectionOwner(_collectionId) returns (uint256 tokenId) {
        tokenId = nextNFTId++;
        nfts[tokenId] = NFT({
            id: tokenId,
            collectionId: _collectionId,
            owner: _recipient,
            tokenURI: _tokenURI,
            data: _initialData // Store initial dynamic data
        });
        emit NFTMinted(tokenId, _collectionId, _recipient);
    }

    function updateNFTMetadata(uint256 _tokenId, string memory _newTokenURI) external onlyNFTOwner(_tokenId) {
        nfts[_tokenId].tokenURI = _newTokenURI;
        emit NFTMetadataUpdated(_tokenId, _newTokenURI);
    }

    function updateNFTData(uint256 _tokenId, bytes memory _newData) external onlyNFTOwner(_tokenId) {
        nfts[_tokenId].data = _newData;
        emit NFTDataUpdated(_tokenId, _tokenId);
    }

    function getNFTData(uint256 _tokenId) external view returns (bytes memory) {
        return nfts[_tokenId].data;
    }

    // --- 3. Marketplace Listing & Trading ---
    function listNFTForSale(uint256 _tokenId, uint256 _price) external onlyNFTOwner(_tokenId) {
        require(nfts[_tokenId].owner == msg.sender, "Not NFT owner"); // Redundant check, modifier already does this
        require(listings[_tokenId].id == 0 || !listings[_tokenId].isActive, "NFT already listed or listing ID conflict"); // Assuming token ID and listing ID correlation is not strictly enforced, but good to check for potential future logic.

        uint256 listingId = nextListingId++;
        listings[listingId] = MarketplaceListing({
            id: listingId,
            nftId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        activeListingCount++;
        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _listingId) external payable onlyActiveListing(_listingId) {
        MarketplaceListing storage listing = listings[_listingId];
        NFT storage nft = nfts[listing.nftId];

        require(msg.value >= listing.price, "Insufficient funds");
        require(nft.owner != msg.sender, "Cannot buy your own NFT");

        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - platformFee;

        // Transfer proceeds to seller
        payable(listing.seller).transfer(sellerProceeds);

        // Transfer platform fee to platform owner
        payable(platformOwner).transfer(platformFee);

        // Transfer NFT to buyer
        nft.owner = msg.sender;

        // Deactivate listing
        listing.isActive = false;
        activeListingCount--;

        emit NFTBought(_listingId, listing.nftId, msg.sender, listing.price);

        // Royalty payment (example - more complex logic might be needed)
        uint256 royaltyPercentage = nftCollections[nft.collectionId].royaltyPercentage;
        if (royaltyPercentage > 0) {
            uint256 royaltyAmount = (listing.price * royaltyPercentage) / 100;
            payable(nftCollections[nft.collectionId].owner).transfer(royaltyAmount);
            sellerProceeds -= royaltyAmount; // Reduce seller proceeds by royalty amount
             payable(listing.seller).transfer(sellerProceeds - platformFee); // Re-transfer seller proceeds after royalty deduction
        }
    }

    function delistNFT(uint256 _listingId) external onlyListedNFTOwner(_listingId) onlyActiveListing(_listingId) {
        listings[_listingId].isActive = false;
        activeListingCount--;
        emit NFTDelisted(_listingId, listings[_listingId].nftId);
    }

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) external onlyListedNFTOwner(_listingId) onlyActiveListing(_listingId) {
        listings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, _newPrice);
    }

    function cancelListing(uint256 _listingId) external onlyListedNFTOwner(_listingId) onlyActiveListing(_listingId) {
        listings[_listingId].isActive = false;
        activeListingCount--;
        emit ListingCancelled(_listingId, listings[_listingId].nftId);
    }

    // --- 4. Social Interaction Features ---
    function likeNFT(uint256 _tokenId) external {
        // Prevent double liking from the same user
        for (uint256 i = 0; i < nftLikes[_tokenId].length; i++) {
            if (nftLikes[_tokenId][i] == msg.sender) {
                return; // User already liked this NFT
            }
        }
        nftLikes[_tokenId].push(msg.sender);
        emit NFTLiked(_tokenId, msg.sender);
    }

    function commentOnNFT(uint256 _tokenId, string memory _comment) external {
        nftComments[_tokenId].push(_comment);
        emit NFTCommented(_tokenId, msg.sender, _comment);
    }

    function getUserNFTLikes(address _user) external view returns (uint256[] memory likedTokenIds) {
        likedTokenIds = new uint256[](0);
        for (uint256 tokenId = 1; tokenId < nextNFTId; tokenId++) {
            for (uint256 i = 0; i < nftLikes[tokenId].length; i++) {
                if (nftLikes[tokenId][i] == _user) {
                    uint256[] memory temp = new uint256[](likedTokenIds.length + 1);
                    for(uint256 j=0; j<likedTokenIds.length; j++){
                        temp[j] = likedTokenIds[j];
                    }
                    temp[likedTokenIds.length] = tokenId;
                    likedTokenIds = temp;
                    break; // Move to next tokenId once a like is found
                }
            }
        }
        return likedTokenIds;
    }

    function getNFTComments(uint256 _tokenId) external view returns (string[] memory) {
        return nftComments[_tokenId];
    }

    // --- 5. Governance & Platform Control ---
    function submitGovernanceProposal(string memory _title, string memory _description, bytes memory _payload) external onlyGovernanceTokenHolders {
        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            title: _title,
            description: _description,
            payload: _payload,
            proposer: msg.sender,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit GovernanceProposalCreated(proposalId, _title, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernanceTokenHolders proposalActive(_proposalId) {
        require(governanceProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal"); // Optional: Prohibit proposer voting
        uint256 voteWeight = governanceTokenBalance[msg.sender]; // Simple voting weight based on token balance
        if (_support) {
            governanceProposals[_proposalId].yesVotes += voteWeight;
        } else {
            governanceProposals[_proposalId].noVotes += voteWeight;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner proposalExecutable(_proposalId) {
        governanceProposals[_proposalId].executed = true;
        // Example: Decode payload and execute action - for simplicity, let's assume payload is function signature and parameters
        // In a real application, more robust and secure execution logic is needed.
        (bool success, bytes memory returnData) = address(this).delegatecall(governanceProposals[_proposalId].payload);
        require(success, "Proposal execution failed");
        emit GovernanceProposalExecuted(_proposalId);
    }

    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner { // Can be changed to governance-controlled in executeProposal
        require(_newFeePercentage <= 100, "Platform fee cannot exceed 100%");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(platformOwner).transfer(balance);
        emit PlatformFeesWithdrawn(platformOwner, balance);
    }


    // --- 6. Utility Functions ---
    function getListingDetails(uint256 _listingId) external view returns (MarketplaceListing memory) {
        return listings[_listingId];
    }

    function getCollectionDetails(uint256 _collectionId) external view returns (NFTCollection memory) {
        return nftCollections[_collectionId];
    }

    function getTotalListings() external view returns (uint256) {
        return activeListingCount;
    }

    function getPlatformFee() external view returns (uint256) {
        return platformFeePercentage;
    }

    // --- Fallback and Receive (Optional - for receiving ETH for buyNFT) ---
    receive() external payable {}
    fallback() external payable {}
}
```