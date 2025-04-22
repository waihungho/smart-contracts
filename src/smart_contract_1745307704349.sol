```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized NFT marketplace with dynamic NFT capabilities,
 *      advanced trading mechanisms, and community-driven features. It goes beyond basic NFT marketplaces
 *      by introducing dynamic metadata updates, NFT rentals, staking, and governance aspects.
 *
 * Function Summary:
 *
 * **NFT Collection Management:**
 * 1. `addSupportedNFTCollection(address _nftCollection, string memory _collectionName)`:  Allows the contract owner to add a supported NFT collection to the marketplace.
 * 2. `removeSupportedNFTCollection(address _nftCollection)`: Allows the contract owner to remove a supported NFT collection from the marketplace.
 * 3. `isSupportedNFTCollection(address _nftCollection) public view returns (bool)`: Checks if an NFT collection is supported in the marketplace.
 * 4. `getCollectionName(address _nftCollection) public view returns (string memory)`: Retrieves the name of a supported NFT collection.
 *
 * **NFT Listing and Delisting:**
 * 5. `listItemForSale(address _nftCollection, uint256 _tokenId, uint256 _price)`: Allows an NFT owner to list their NFT for sale in the marketplace.
 * 6. `delistItemForSale(address _nftCollection, uint256 _tokenId)`: Allows an NFT owner to delist their NFT from sale.
 * 7. `isItemListed(address _nftCollection, uint256 _tokenId) public view returns (bool)`: Checks if an NFT is currently listed for sale.
 *
 * **NFT Purchasing and Selling:**
 * 8. `buyItem(address _nftCollection, uint256 _tokenId)`: Allows a user to purchase a listed NFT.
 * 9. `directOffer(address _nftCollection, uint256 _tokenId, uint256 _price)`: Allows a user to make a direct offer on an NFT, even if not listed.
 * 10. `acceptOffer(address _nftCollection, uint256 _tokenId, address _offerer)`: Allows the NFT owner to accept a direct offer on their NFT.
 *
 * **Dynamic NFT Metadata Updates:**
 * 11. `updateNFTMetadata(address _nftCollection, uint256 _tokenId, string memory _newMetadataURI)`:  Allows the marketplace to update the metadata URI of an NFT (requires specific conditions or admin role - can be extended based on logic).
 * 12. `getNFTMetadataURI(address _nftCollection, uint256 _tokenId) public view returns (string memory)`: Retrieves the current metadata URI of an NFT managed by the marketplace.
 *
 * **NFT Rentals:**
 * 13. `listItemForRent(address _nftCollection, uint256 _tokenId, uint256 _rentPricePerDay)`: Allows an NFT owner to list their NFT for rent.
 * 14. `rentItem(address _nftCollection, uint256 _tokenId, uint256 _rentDays)`: Allows a user to rent an NFT for a specified number of days.
 * 15. `returnRentedItem(address _nftCollection, uint256 _tokenId)`: Allows a renter to return a rented NFT before the rental period ends.
 * 16. `getRentalInfo(address _nftCollection, uint256 _tokenId) public view returns (address renter, uint256 rentEndTime)`: Retrieves rental information for an NFT.
 *
 * **NFT Staking (Example - Simple Staking for Marketplace Utility Token):**
 * 17. `stakeNFT(address _nftCollection, uint256 _tokenId)`: Allows users to stake their NFTs to earn marketplace utility tokens (placeholder logic).
 * 18. `unstakeNFT(address _nftCollection, uint256 _tokenId)`: Allows users to unstake their NFTs and claim earned tokens.
 * 19. `calculateStakingRewards(address _nftCollection, uint256 _tokenId) public view returns (uint256)`: Calculates staking rewards for a given NFT (placeholder logic).
 *
 * **Marketplace Governance (Example - Simple Parameter Change Proposal):**
 * 20. `proposeMarketplaceParameterChange(string memory _parameterName, uint256 _newValue)`: Allows users to propose changes to marketplace parameters (e.g., fees, staking rates - placeholder logic).
 * 21. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows users to vote on marketplace parameter change proposals (placeholder logic).
 * 22. `executeProposal(uint256 _proposalId)`: Allows the contract owner (or governance mechanism) to execute a passed proposal (placeholder logic).
 * 23. `getProposalDetails(uint256 _proposalId) public view returns (string memory parameterName, uint256 newValue, uint256 votesFor, uint256 votesAgainst, bool executed)`: Retrieves details of a marketplace parameter change proposal.
 *
 * **Admin and Utility Functions:**
 * 24. `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 * 25. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 * 26. `pauseMarketplace()`: Allows the contract owner to pause marketplace functionalities.
 * 27. `unpauseMarketplace()`: Allows the contract owner to unpause marketplace functionalities.
 * 28. `isMarketplacePaused() public view returns (bool)`: Checks if the marketplace is currently paused.
 */
contract DynamicNFTMarketplace {
    // --- State Variables ---

    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address payable public feeWallet; // Wallet to receive marketplace fees
    bool public paused = false;

    mapping(address => string) public supportedNFTCollections; // Collection Address => Collection Name
    mapping(address => bool) public isCollectionSupported;
    address[] public supportedCollectionAddresses;

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }
    mapping(address => mapping(uint256 => Listing)) public nftListings; // NFT Collection => TokenId => Listing Info

    struct Offer {
        address offerer;
        uint256 price;
        bool isActive;
    }
    mapping(address => mapping(uint256 => mapping(address => Offer))) public nftOffers; // NFT Collection => TokenId => Offerer => Offer Info

    struct Rental {
        address renter;
        uint256 rentPricePerDay;
        uint256 rentEndTime;
        bool isRented;
    }
    mapping(address => mapping(uint256 => Rental)) public nftRentals; // NFT Collection => TokenId => Rental Info

    mapping(address => mapping(uint256 => string)) public nftMetadataURIs; // NFT Collection => TokenId => Metadata URI (Dynamic Updates)

    // Example Staking - Placeholder (Needs more complex implementation for real token rewards)
    mapping(address => mapping(uint256 => bool)) public nftStakingStatus; // NFT Collection => TokenId => Is Staked
    mapping(address => uint256) public userStakingPoints; // User Address => Staking Points (Example Reward System)

    // Example Governance - Placeholder (Needs more robust voting and proposal mechanism)
    uint256 public proposalCount = 0;
    struct Proposal {
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => Proposal) public marketplaceProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // ProposalId => Voter => Voted (true/false)

    // --- Events ---
    event CollectionAdded(address nftCollection, string collectionName);
    event CollectionRemoved(address nftCollection);
    event ItemListed(address nftCollection, uint256 tokenId, address seller, uint256 price);
    event ItemDelisted(address nftCollection, uint256 tokenId, address seller);
    event ItemSold(address nftCollection, uint256 tokenId, address seller, address buyer, uint256 price);
    event OfferMade(address nftCollection, uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(address nftCollection, uint256 tokenId, address seller, address offerer, uint256 price);
    event MetadataUpdated(address nftCollection, uint256 tokenId, string newMetadataURI);
    event ItemListedForRent(address nftCollection, uint256 tokenId, address renter, uint256 rentPricePerDay);
    event ItemRented(address nftCollection, uint256 tokenId, address renter, uint256 rentDays, uint256 rentEndTime);
    event ItemReturned(address nftCollection, uint256 tokenId, address renter);
    event NFTStaked(address nftCollection, uint256 tokenId, address staker);
    event NFTUnstaked(address nftCollection, uint256 tokenId, address unstaker);
    event ProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event MarketplaceFeeSet(uint256 feePercentage);
    event FeesWithdrawn(uint256 amount);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused.");
        _;
    }

    modifier onlySupportedCollection(address _nftCollection) {
        require(isCollectionSupported[_nftCollection], "Collection is not supported.");
        _;
    }

    modifier onlyNFTOwner(address _nftCollection, uint256 _tokenId) {
        IERC721 nftContract = IERC721(_nftCollection);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    // --- Constructor ---
    constructor(address payable _feeWallet) {
        owner = msg.sender;
        feeWallet = _feeWallet;
    }

    // --- NFT Collection Management Functions ---

    function addSupportedNFTCollection(address _nftCollection, string memory _collectionName) external onlyOwner {
        require(!isCollectionSupported[_nftCollection], "Collection already supported.");
        supportedNFTCollections[_nftCollection] = _collectionName;
        isCollectionSupported[_nftCollection] = true;
        supportedCollectionAddresses.push(_nftCollection);
        emit CollectionAdded(_nftCollection, _collectionName);
    }

    function removeSupportedNFTCollection(address _nftCollection) external onlyOwner {
        require(isCollectionSupported[_nftCollection], "Collection is not supported.");
        delete supportedNFTCollections[_nftCollection];
        isCollectionSupported[_nftCollection] = false;

        // Remove from supportedCollectionAddresses array (inefficient for large arrays, consider alternative if performance critical)
        for (uint i = 0; i < supportedCollectionAddresses.length; i++) {
            if (supportedCollectionAddresses[i] == _nftCollection) {
                supportedCollectionAddresses[i] = supportedCollectionAddresses[supportedCollectionAddresses.length - 1];
                supportedCollectionAddresses.pop();
                break;
            }
        }
        emit CollectionRemoved(_nftCollection);
    }

    function isSupportedNFTCollection(address _nftCollection) public view returns (bool) {
        return isCollectionSupported[_nftCollection];
    }

    function getCollectionName(address _nftCollection) public view returns (string memory) {
        return supportedNFTCollections[_nftCollection];
    }

    // --- NFT Listing and Delisting Functions ---

    function listItemForSale(address _nftCollection, uint256 _tokenId, uint256 _price) external
        whenNotPaused
        onlySupportedCollection(_nftCollection)
        onlyNFTOwner(_nftCollection, _tokenId)
    {
        IERC721 nftContract = IERC721(_nftCollection);
        require(nftContract.getApproved(_tokenId) == address(this) || nftContract.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT.");
        require(!nftListings[_nftCollection][_tokenId].isListed, "Item already listed for sale.");

        nftListings[_nftCollection][_tokenId] = Listing({
            seller: msg.sender,
            price: _price,
            isListed: true
        });
        emit ItemListed(_nftCollection, _tokenId, msg.sender, _price);
    }

    function delistItemForSale(address _nftCollection, uint256 _tokenId) external
        whenNotPaused
        onlySupportedCollection(_nftCollection)
        onlyNFTOwner(_nftCollection, _tokenId)
    {
        require(nftListings[_nftCollection][_tokenId].isListed, "Item is not listed for sale.");
        require(nftListings[_nftCollection][_tokenId].seller == msg.sender, "Only the seller can delist the item.");

        delete nftListings[_nftCollection][_tokenId]; // Reset listing struct to default values (isListed becomes false)
        emit ItemDelisted(_nftCollection, _tokenId, msg.sender);
    }

    function isItemListed(address _nftCollection, uint256 _tokenId) public view returns (bool) {
        return nftListings[_nftCollection][_tokenId].isListed;
    }

    // --- NFT Purchasing and Selling Functions ---

    function buyItem(address _nftCollection, uint256 _tokenId) external payable
        whenNotPaused
        onlySupportedCollection(_nftCollection)
    {
        require(nftListings[_nftCollection][_tokenId].isListed, "Item is not listed for sale.");
        Listing memory listing = nftListings[_nftCollection][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy item.");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        IERC721 nftContract = IERC721(_nftCollection);

        // Transfer NFT to buyer
        nftContract.safeTransferFrom(listing.seller, msg.sender, _tokenId);

        // Transfer proceeds to seller and marketplace fees to fee wallet
        payable(listing.seller).transfer(sellerProceeds);
        feeWallet.transfer(marketplaceFee);

        delete nftListings[_nftCollection][_tokenId]; // Delist after purchase

        emit ItemSold(_nftCollection, _tokenId, listing.seller, msg.sender, listing.price);
    }

    function directOffer(address _nftCollection, uint256 _tokenId, uint256 _price) external payable
        whenNotPaused
        onlySupportedCollection(_nftCollection)
    {
        require(msg.value >= _price, "Insufficient funds for offer.");
        require(nftOffers[_nftCollection][_tokenId][msg.sender].price == 0, "You already have an active offer for this NFT."); // Only one active offer per user per NFT

        nftOffers[_nftCollection][_tokenId][msg.sender] = Offer({
            offerer: msg.sender,
            price: _price,
            isActive: true
        });
        emit OfferMade(_nftCollection, _tokenId, msg.sender, _price);
    }

    function acceptOffer(address _nftCollection, uint256 _tokenId, address _offerer) external
        whenNotPaused
        onlySupportedCollection(_nftCollection)
        onlyNFTOwner(_nftCollection, _tokenId)
    {
        require(nftOffers[_nftCollection][_tokenId][_offerer].isActive, "Offer is not active or does not exist.");
        Offer memory offer = nftOffers[_nftCollection][_tokenId][_offerer];

        uint256 marketplaceFee = (offer.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = offer.price - marketplaceFee;

        IERC721 nftContract = IERC721(_nftCollection);

        // Transfer NFT to offerer
        nftContract.safeTransferFrom(msg.sender, offer.offerer, _tokenId);

        // Transfer proceeds to seller and marketplace fees to fee wallet
        payable(msg.sender).transfer(sellerProceeds);
        feeWallet.transfer(marketplaceFee);

        delete nftOffers[_nftCollection][_tokenId][_offerer]; // Invalidate offer after acceptance

        emit OfferAccepted(_nftCollection, _tokenId, msg.sender, offer.offerer, offer.price);
    }

    // --- Dynamic NFT Metadata Updates ---

    // Example: Admin/Marketplace can update metadata (Logic can be expanded based on use-case)
    function updateNFTMetadata(address _nftCollection, uint256 _tokenId, string memory _newMetadataURI) external onlyOwner whenNotPaused onlySupportedCollection(_nftCollection) {
        nftMetadataURIs[_nftCollection][_tokenId] = _newMetadataURI;
        emit MetadataUpdated(_nftCollection, _tokenId, _newMetadataURI);
    }

    function getNFTMetadataURI(address _nftCollection, uint256 _tokenId) public view returns (string memory) {
        string memory uri = nftMetadataURIs[_nftCollection][_tokenId];
        if (bytes(uri).length > 0) {
            return uri; // Return dynamic URI if set
        } else {
            // Fallback to default NFT contract URI if dynamic URI not set (optional - depends on requirements)
            IERC721Metadata nftContract = IERC721Metadata(_nftCollection);
            return nftContract.tokenURI(_tokenId);
        }
    }

    // --- NFT Rentals Functions ---

    function listItemForRent(address _nftCollection, uint256 _tokenId, uint256 _rentPricePerDay) external
        whenNotPaused
        onlySupportedCollection(_nftCollection)
        onlyNFTOwner(_nftCollection, _tokenId)
    {
        IERC721 nftContract = IERC721(_nftCollection);
        require(nftContract.getApproved(_tokenId) == address(this) || nftContract.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT for rent.");
        require(!nftRentals[_nftCollection][_tokenId].isRented, "Item is already rented or listed for rent.");

        nftRentals[_nftCollection][_tokenId] = Rental({
            renter: address(0), // No renter initially
            rentPricePerDay: _rentPricePerDay,
            rentEndTime: 0,
            isRented: false
        });
        emit ItemListedForRent(_nftCollection, _tokenId, msg.sender, _rentPricePerDay);
    }

    function rentItem(address _nftCollection, uint256 _tokenId, uint256 _rentDays) external payable
        whenNotPaused
        onlySupportedCollection(_nftCollection)
    {
        require(!nftRentals[_nftCollection][_tokenId].isRented, "Item is already rented.");
        require(nftRentals[_nftCollection][_tokenId].rentPricePerDay > 0, "Item is not listed for rent."); // Ensure it's actually listed for rent

        uint256 rentPrice = nftRentals[_nftCollection][_tokenId].rentPricePerDay * _rentDays;
        require(msg.value >= rentPrice, "Insufficient funds for rent.");

        uint256 marketplaceFee = (rentPrice * marketplaceFeePercentage) / 100;
        uint256 ownerRentProceeds = rentPrice - marketplaceFee;

        IERC721 nftContract = IERC721(_nftCollection);

        // Transfer NFT to the marketplace (for rental management - can be different logic based on requirements)
        address nftOwner = nftContract.ownerOf(_tokenId);
        nftContract.safeTransferFrom(nftOwner, address(this), _tokenId);

        nftRentals[_nftCollection][_tokenId] = Rental({
            renter: msg.sender,
            rentPricePerDay: nftRentals[_nftCollection][_tokenId].rentPricePerDay,
            rentEndTime: block.timestamp + (_rentDays * 1 days), // Rent ends after _rentDays
            isRented: true
        });

        // Transfer rent proceeds to owner and marketplace fees to fee wallet
        payable(nftOwner).transfer(ownerRentProceeds);
        feeWallet.transfer(marketplaceFee);

        emit ItemRented(_nftCollection, _tokenId, msg.sender, _rentDays, nftRentals[_nftCollection][_tokenId].rentEndTime);
    }

    function returnRentedItem(address _nftCollection, uint256 _tokenId) external
        whenNotPaused
        onlySupportedCollection(_nftCollection)
    {
        require(nftRentals[_nftCollection][_tokenId].isRented, "Item is not currently rented.");
        require(nftRentals[_nftCollection][_tokenId].renter == msg.sender, "Only the renter can return the item.");
        require(block.timestamp <= nftRentals[_nftCollection][_tokenId].rentEndTime, "Rental period has expired."); // Optional: Allow return after expiry with penalty/extra fee

        IERC721 nftContract = IERC721(_nftCollection);

        // Transfer NFT back to owner (original owner before rental) - Logic needs to be tracked if original owner is required.  Simplified here to return to contract owner.
        address nftOwner = IERC721(_nftCollection).ownerOf(_tokenId); // Owner of NFT in marketplace contract
        nftContract.safeTransferFrom(address(this), nftOwner, _tokenId);

        delete nftRentals[_nftCollection][_tokenId]; // Reset rental struct

        emit ItemReturned(_nftCollection, _tokenId, msg.sender);
    }

    function getRentalInfo(address _nftCollection, uint256 _tokenId) public view returns (address renter, uint256 rentEndTime) {
        return (nftRentals[_nftCollection][_tokenId].renter, nftRentals[_nftCollection][_tokenId].rentEndTime);
    }

    // --- NFT Staking Functions (Example - Placeholder) ---

    function stakeNFT(address _nftCollection, uint256 _tokenId) external
        whenNotPaused
        onlySupportedCollection(_nftCollection)
        onlyNFTOwner(_nftCollection, _tokenId)
    {
        require(!nftStakingStatus[_nftCollection][_tokenId], "NFT is already staked.");
        IERC721 nftContract = IERC721(_nftCollection);
        require(nftContract.getApproved(_tokenId) == address(this) || nftContract.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT for staking.");

        // Transfer NFT to marketplace for staking (optional - logic can be different)
        nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);

        nftStakingStatus[_nftCollection][_tokenId] = true;
        userStakingPoints[msg.sender] += 1; // Example: Simple staking points reward
        emit NFTStaked(_nftCollection, _tokenId, msg.sender);
    }

    function unstakeNFT(address _nftCollection, uint256 _tokenId) external
        whenNotPaused
        onlySupportedCollection(_nftCollection)
    {
        require(nftStakingStatus[_nftCollection][_tokenId], "NFT is not staked.");
        require(IERC721(_nftCollection).ownerOf(_tokenId) == address(this), "Marketplace is not the current owner of the NFT."); // Ensure marketplace owns the staked NFT

        IERC721 nftContract = IERC721(_nftCollection);

        // Transfer NFT back to user
        nftContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        nftStakingStatus[_nftCollection][_tokenId] = false;
        uint256 rewards = calculateStakingRewards(_nftCollection, _tokenId); // Placeholder reward calculation
        // Implement reward token transfer logic here (e.g., transfer marketplace utility tokens to user)
        userStakingPoints[msg.sender] -= 1; // Example - reduce points on unstake
        emit NFTUnstaked(_nftCollection, _tokenId, msg.sender);
    }

    function calculateStakingRewards(address _nftCollection, uint256 _tokenId) public view returns (uint256) {
        // Placeholder reward calculation - Replace with actual staking logic
        if (nftStakingStatus[_nftCollection][_tokenId]) {
            return 10; // Example: Fixed reward of 10 tokens (replace with dynamic calculation)
        } else {
            return 0;
        }
    }

    // --- Marketplace Governance Functions (Example - Placeholder) ---

    function proposeMarketplaceParameterChange(string memory _parameterName, uint256 _newValue) external whenNotPaused {
        proposalCount++;
        marketplaceProposals[proposalCount] = Proposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalCount, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        require(!marketplaceProposals[_proposalId].executed, "Proposal has already been executed.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            marketplaceProposals[_proposalId].votesFor++;
        } else {
            marketplaceProposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(!marketplaceProposals[_proposalId].executed, "Proposal already executed.");
        Proposal storage proposal = marketplaceProposals[_proposalId];

        // Example: Simple majority for execution (can be more complex governance logic)
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0 && proposal.votesFor > proposal.votesAgainst, "Proposal does not have enough votes to pass.");

        // Example parameter changes - Expand based on parameters you want to govern
        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("marketplaceFeePercentage"))) {
            setMarketplaceFee(proposal.newValue);
        }
        // Add more parameter change logic here based on proposal.parameterName

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId) public view returns (string memory parameterName, uint256 newValue, uint256 votesFor, uint256 votesAgainst, bool executed) {
        Proposal memory proposal = marketplaceProposals[_proposalId];
        return (proposal.parameterName, proposal.newValue, proposal.votesFor, proposal.votesAgainst, proposal.executed);
    }

    // --- Admin and Utility Functions ---

    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw.");
        feeWallet.transfer(balance);
        emit FeesWithdrawn(balance);
    }

    function pauseMarketplace() external onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() external onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }

    function isMarketplacePaused() public view returns (bool) {
        return paused;
    }

    // --- Fallback Function (Optional - for receiving ETH directly to contract) ---
    receive() external payable {}
}

// --- Interfaces ---
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
```