```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Inspiration
 * @author Bard (Example Smart Contract - Educational Purpose)
 * @dev This smart contract implements a dynamic NFT marketplace with features for AI-inspired art,
 * dynamic metadata updates, community governance, staking, auctions, and more.
 * It is designed to be creative and showcase advanced concepts, avoiding direct duplication of common open-source contracts.
 *
 * **Outline and Function Summary:**
 *
 * **NFT Management:**
 * 1. `createNFTCollection(string memory _name, string memory _symbol, string memory _baseURI)`: Allows the contract owner to create a new NFT collection.
 * 2. `mintNFT(uint256 _collectionId, address _to, string memory _initialMetadata)`: Mints a new NFT within a specified collection to a given address.
 * 3. `updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _newMetadata)`: Allows the NFT owner to update the metadata of their NFT.
 * 4. `transferNFT(uint256 _collectionId, address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another.
 * 5. `burnNFT(uint256 _collectionId, uint256 _tokenId)`: Allows the NFT owner to burn (destroy) their NFT.
 * 6. `getNFTMetadata(uint256 _collectionId, uint256 _tokenId)`: Retrieves the metadata of a specific NFT.
 * 7. `getTotalNFTsInCollection(uint256 _collectionId)`: Returns the total number of NFTs minted in a collection.
 * 8. `getCollectionOwner(uint256 _collectionId)`: Returns the owner of a specific NFT collection (initially the contract owner).
 *
 * **Marketplace Functionality:**
 * 9. `listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale on the marketplace.
 * 10. `buyNFT(uint256 _collectionId, uint256 _tokenId)`: Allows users to buy NFTs listed for sale.
 * 11. `cancelNFTSale(uint256 _collectionId, uint256 _tokenId)`: Allows NFT owners to cancel their NFT listing.
 * 12. `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 * 13. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 * 14. `isNFTListed(uint256 _collectionId, uint256 _tokenId)`: Checks if an NFT is currently listed for sale.
 *
 * **AI Art Inspiration & Dynamic Features:**
 * 15. `requestAIArtInspiration(uint256 _collectionId, uint256 _tokenId, string memory _inspirationPrompt)`: Allows NFT owners to request AI art inspiration for their NFT (metadata update based on external AI service - concept).
 * 16. `triggerDynamicMetadataUpdate(uint256 _collectionId, uint256 _tokenId, string memory _updateReason)`: Triggers a dynamic metadata update based on contract logic or external events (e.g., time-based, community voting - concept).
 * 17. `setDynamicUpdateLogic(uint256 _collectionId, function(uint256, string memory) external view returns (string memory) _logicContract)`: (Advanced Concept) Allows setting a separate contract address to handle dynamic metadata update logic for a collection.
 *
 * **Community & Governance (Simple Example):**
 * 18. `proposeFeature(string memory _featureProposal)`: Allows users to propose new features for the marketplace.
 * 19. `voteOnFeatureProposal(uint256 _proposalId, bool _vote)`: Allows users to vote on feature proposals.
 * 20. `executeApprovedFeature(uint256 _proposalId)`: (Owner only) Executes an approved feature proposal if it's feasible within the contract's scope.
 *
 * **Staking (Basic Example):**
 * 21. `stakeTokens(uint256 _amount)`: Allows users to stake tokens to participate in governance or earn rewards (placeholder - token and reward logic not fully implemented).
 * 22. `unstakeTokens(uint256 _amount)`: Allows users to unstake their tokens.
 *
 * **Auctions (Simple Example):**
 * 23. `createAuction(uint256 _collectionId, uint256 _tokenId, uint256 _startingBid, uint256 _durationInHours)`: Allows NFT owners to create auctions for their NFTs.
 * 24. `bidOnAuction(uint256 _auctionId)`: Allows users to bid on active auctions.
 * 25. `finalizeAuction(uint256 _auctionId)`: Ends an auction and transfers the NFT to the highest bidder.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTMarketplace is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Data Structures ---

    struct NFTCollection {
        string name;
        string symbol;
        string baseURI;
        Counters.Counter nftCounter;
        mapping(uint256 => string) nftMetadata; // tokenId => metadata URI
        mapping(uint256 => address) nftOwner;    // tokenId => owner address
    }

    struct Listing {
        uint256 collectionId;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct FeatureProposal {
        string proposalText;
        uint256 upvotes;
        uint256 downvotes;
        bool isApproved;
        bool isExecuted;
    }

    struct Auction {
        uint256 collectionId;
        uint256 tokenId;
        address seller;
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    // --- State Variables ---

    mapping(uint256 => NFTCollection) public nftCollections;
    Counters.Counter public collectionCounter;

    mapping(uint256 => Listing) public nftListings;
    Counters.Counter public listingCounter;

    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee

    mapping(uint256 => FeatureProposal) public featureProposals;
    Counters.Counter public proposalCounter;

    mapping(uint256 => Auction) public activeAuctions;
    Counters.Counter public auctionCounter;

    mapping(address => uint256) public stakedBalances; // Basic staking example - no reward logic

    // --- Events ---

    event CollectionCreated(uint256 collectionId, string name, string symbol, string baseURI);
    event NFTMinted(uint256 collectionId, uint256 tokenId, address to, string metadata);
    event NFTMetadataUpdated(uint256 collectionId, uint256 tokenId, string newMetadata);
    event NFTTransferred(uint256 collectionId, uint256 tokenId, address from, address to);
    event NFTBurnt(uint256 collectionId, uint256 tokenId);
    event NFTListedForSale(uint256 listingId, uint256 collectionId, uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 listingId, uint256 collectionId, uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTSaleCancelled(uint256 listingId, uint256 collectionId, uint256 tokenId);
    event MarketplaceFeeUpdated(uint256 feePercentage);
    event FeatureProposalCreated(uint256 proposalId, string proposalText, address proposer);
    event FeatureProposalVoted(uint256 proposalId, address voter, bool vote);
    event FeatureProposalExecuted(uint256 proposalId);
    event TokensStaked(address staker, uint256 amount);
    event TokensUnstaked(address unstaker, uint256 amount);
    event AuctionCreated(uint256 auctionId, uint256 collectionId, uint256 tokenId, address seller, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, address winner, uint256 winningBid);

    // --- Modifiers ---

    modifier collectionExists(uint256 _collectionId) {
        require(_collectionId > 0 && _collectionId <= collectionCounter.current(), "Collection does not exist");
        _;
    }

    modifier nftExists(uint256 _collectionId, uint256 _tokenId) {
        require(nftCollections[_collectionId].nftOwner[_tokenId] != address(0), "NFT does not exist");
        _;
    }

    modifier onlyNFTOwner(uint256 _collectionId, uint256 _tokenId) {
        require(nftCollections[_collectionId].nftOwner[_tokenId] == msg.sender, "Not NFT owner");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(_listingId > 0 && _listingId <= listingCounter.current() && nftListings[_listingId].isActive, "Listing does not exist or is inactive");
        _;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(_auctionId > 0 && _auctionId <= auctionCounter.current() && activeAuctions[_auctionId].isActive, "Auction does not exist or is inactive");
        _;
    }

    modifier notNFTOwnerInAuction(uint256 _auctionId) {
        require(activeAuctions[_auctionId].seller != msg.sender, "Seller cannot bid on their own auction");
        _;
    }

    modifier validBidAmount(uint256 _auctionId, uint256 _bidAmount) {
        require(_bidAmount > activeAuctions[_auctionId].highestBid && _bidAmount >= activeAuctions[_auctionId].startingBid, "Bid amount too low");
        _;
    }

    modifier auctionNotEnded(uint256 _auctionId) {
        require(block.timestamp < activeAuctions[_auctionId].endTime, "Auction has ended");
        _;
    }

    modifier auctionEnded(uint256 _auctionId) {
        require(block.timestamp >= activeAuctions[_auctionId].endTime, "Auction has not ended yet");
        _;
    }

    // --- NFT Management Functions ---

    /**
     * @dev Creates a new NFT collection. Only callable by the contract owner.
     * @param _name The name of the NFT collection.
     * @param _symbol The symbol of the NFT collection.
     * @param _baseURI The base URI for metadata of NFTs in this collection.
     */
    function createNFTCollection(string memory _name, string memory _symbol, string memory _baseURI) external onlyOwner {
        collectionCounter.increment();
        uint256 collectionId = collectionCounter.current();
        nftCollections[collectionId] = NFTCollection({
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI,
            nftCounter: Counters.Counter(0),
            nftMetadata: mapping(uint256 => string)(),
            nftOwner: mapping(uint256 => address)()
        });
        emit CollectionCreated(collectionId, _name, _symbol, _baseURI);
    }

    /**
     * @dev Mints a new NFT within a specified collection.
     * @param _collectionId The ID of the NFT collection.
     * @param _to The address to mint the NFT to.
     * @param _initialMetadata The initial metadata URI for the NFT.
     */
    function mintNFT(uint256 _collectionId, address _to, string memory _initialMetadata) external collectionExists(_collectionId) onlyOwner {
        NFTCollection storage collection = nftCollections[_collectionId];
        collection.nftCounter.increment();
        uint256 tokenId = collection.nftCounter.current();
        collection.nftMetadata[tokenId] = _initialMetadata;
        collection.nftOwner[tokenId] = _to;
        emit NFTMinted(_collectionId, tokenId, _to, _initialMetadata);
    }

    /**
     * @dev Updates the metadata of an NFT. Only callable by the NFT owner.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @param _newMetadata The new metadata URI for the NFT.
     */
    function updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _newMetadata) external collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) {
        nftCollections[_collectionId].nftMetadata[_tokenId] = _newMetadata;
        emit NFTMetadataUpdated(_collectionId, _tokenId, _newMetadata);
    }

    /**
     * @dev Transfers an NFT to a new owner. Only callable by the NFT owner.
     * @param _collectionId The ID of the NFT collection.
     * @param _from The current owner of the NFT (should be msg.sender).
     * @param _to The new owner of the NFT.
     * @param _tokenId The ID of the NFT.
     */
    function transferNFT(uint256 _collectionId, address _from, address _to, uint256 _tokenId) external collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) {
        require(_from == msg.sender, "From address must be sender");
        nftCollections[_collectionId].nftOwner[_tokenId] = _to;
        emit NFTTransferred(_collectionId, _tokenId, _from, _to);
    }

    /**
     * @dev Burns (destroys) an NFT. Only callable by the NFT owner.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     */
    function burnNFT(uint256 _collectionId, uint256 _tokenId) external collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) {
        delete nftCollections[_collectionId].nftMetadata[_tokenId];
        delete nftCollections[_collectionId].nftOwner[_tokenId];
        emit NFTBurnt(_collectionId, _tokenId);
    }

    /**
     * @dev Gets the metadata of an NFT.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI of the NFT.
     */
    function getNFTMetadata(uint256 _collectionId, uint256 _tokenId) external view collectionExists(_collectionId) nftExists(_collectionId, _tokenId) returns (string memory) {
        return nftCollections[_collectionId].nftMetadata[_tokenId];
    }

    /**
     * @dev Gets the total number of NFTs in a collection.
     * @param _collectionId The ID of the NFT collection.
     * @return The total number of NFTs in the collection.
     */
    function getTotalNFTsInCollection(uint256 _collectionId) external view collectionExists(_collectionId) returns (uint256) {
        return nftCollections[_collectionId].nftCounter.current();
    }

    /**
     * @dev Gets the owner of an NFT collection.
     * @param _collectionId The ID of the NFT collection.
     * @return The owner address of the NFT collection.
     */
    function getCollectionOwner(uint256 _collectionId) external view collectionExists(_collectionId) returns (address) {
        return owner(); // Collection owner is initially contract owner
    }

    // --- Marketplace Functions ---

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price to list the NFT for (in wei).
     */
    function listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price) external collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) {
        listingCounter.increment();
        uint256 listingId = listingCounter.current();
        nftListings[listingId] = Listing({
            collectionId: _collectionId,
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit NFTListedForSale(listingId, _collectionId, _tokenId, _price, msg.sender);
    }

    /**
     * @dev Allows a user to buy an NFT listed for sale.
     * @param _listingId The ID of the NFT listing.
     */
    function buyNFT(uint256 _listingId) external payable listingExists(_listingId) {
        Listing storage listing = nftListings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - marketplaceFee;

        // Transfer marketplace fee to contract owner
        payable(owner()).transfer(marketplaceFee);
        // Transfer payout to seller
        payable(listing.seller).transfer(sellerPayout);

        nftCollections[listing.collectionId].nftOwner[listing.tokenId] = msg.sender;
        listing.isActive = false; // Deactivate listing

        emit NFTBought(_listingId, listing.collectionId, listing.tokenId, msg.sender, listing.seller, listing.price);
        emit NFTTransferred(listing.collectionId, listing.tokenId, listing.seller, msg.sender);

        // Refund any extra ETH sent
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }

    /**
     * @dev Cancels an NFT listing. Only callable by the NFT seller.
     * @param _listingId The ID of the NFT listing.
     */
    function cancelNFTSale(uint256 _listingId) external listingExists(_listingId) {
        require(nftListings[_listingId].seller == msg.sender, "Only seller can cancel listing");
        nftListings[_listingId].isActive = false;
        emit NFTSaleCancelled(_listingId, nftListings[_listingId].collectionId, nftListings[_listingId].tokenId);
    }

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance); // Withdraw all contract balance as fees
    }

    /**
     * @dev Checks if an NFT is currently listed for sale.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @return True if the NFT is listed, false otherwise.
     */
    function isNFTListed(uint256 _collectionId, uint256 _tokenId) external view collectionExists(_collectionId) nftExists(_collectionId, _tokenId) returns (bool) {
        for (uint256 i = 1; i <= listingCounter.current(); i++) {
            if (nftListings[i].isActive && nftListings[i].collectionId == _collectionId && nftListings[i].tokenId == _tokenId) {
                return true;
            }
        }
        return false;
    }

    // --- AI Art Inspiration & Dynamic Features ---

    /**
     * @dev Allows NFT owners to request AI art inspiration for their NFT.
     *      This is a conceptual function. In a real implementation, this would trigger an off-chain AI service
     *      to generate inspiration based on the prompt and then the metadata would be updated based on the AI output.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @param _inspirationPrompt The prompt to send to the AI service for inspiration.
     */
    function requestAIArtInspiration(uint256 _collectionId, uint256 _tokenId, string memory _inspirationPrompt) external collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) {
        // In a real implementation:
        // 1. Store the _inspirationPrompt associated with the NFT.
        // 2. Trigger an off-chain process (e.g., using events and a listener) to send the prompt to an AI service.
        // 3. The AI service generates inspiration (e.g., new metadata URI, attributes, description).
        // 4. The off-chain process calls `updateNFTMetadata` function with the AI-generated metadata.

        // For this example, we'll just emit an event indicating the request.
        emit NFTMetadataUpdated(_collectionId, _tokenId, string(abi.encodePacked("AI Inspiration Requested: ", _inspirationPrompt)));
    }

    /**
     * @dev Triggers a dynamic metadata update for an NFT based on some logic or external event.
     *      This is a conceptual function. The actual logic would be more complex and potentially involve oracles or off-chain services.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @param _updateReason A string describing the reason for the dynamic update.
     */
    function triggerDynamicMetadataUpdate(uint256 _collectionId, uint256 _tokenId, string memory _updateReason) external collectionExists(_collectionId) nftExists(_collectionId, _tokenId) {
        // In a real implementation:
        // 1. Define dynamic update logic (e.g., time-based changes, community voting outcomes, external data from oracles).
        // 2. Implement the logic here or in a separate contract (see `setDynamicUpdateLogic` concept).
        // 3. Based on the logic and _updateReason, generate new metadata or fetch from an external source.
        // 4. Call `updateNFTMetadata` with the new metadata.

        // For this example, we'll just update with a timestamp and reason.
        string memory newMetadata = string(abi.encodePacked("Dynamic Update: ", _updateReason, " at ", Strings.toString(block.timestamp)));
        updateNFTMetadata(_collectionId, _tokenId, newMetadata);
    }

    /**
     * @dev (Advanced Concept) Allows setting a separate contract address to handle dynamic metadata update logic for a collection.
     *      This allows for more complex and potentially upgradable dynamic NFT behavior.
     * @param _collectionId The ID of the NFT collection.
     * @param _logicContract Address of the contract that implements the dynamic metadata update logic.
     */
    // function setDynamicUpdateLogic(uint256 _collectionId, function(uint256, string memory) external view returns (string memory) _logicContract) external onlyOwner collectionExists(_collectionId) {
    //     // Placeholder for setting dynamic logic contract - implementation would require more design and interfaces.
    //     // Example:  dynamicLogicContracts[_collectionId] = _logicContract;
    //     // Then, `triggerDynamicMetadataUpdate` could call the logic contract to get new metadata.
    // }

    // --- Community & Governance Functions (Simple Example) ---

    /**
     * @dev Allows users to propose new features for the marketplace.
     * @param _featureProposal The text of the feature proposal.
     */
    function proposeFeature(string memory _featureProposal) external {
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current();
        featureProposals[proposalId] = FeatureProposal({
            proposalText: _featureProposal,
            upvotes: 0,
            downvotes: 0,
            isApproved: false,
            isExecuted: false
        });
        emit FeatureProposalCreated(proposalId, _featureProposal, msg.sender);
    }

    /**
     * @dev Allows users to vote on feature proposals.
     * @param _proposalId The ID of the feature proposal to vote on.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnFeatureProposal(uint256 _proposalId, bool _vote) external {
        require(_proposalId > 0 && _proposalId <= proposalCounter.current(), "Proposal does not exist");
        require(!featureProposals[_proposalId].isExecuted, "Proposal already executed");
        require(!featureProposals[_proposalId].isApproved, "Proposal already approved"); // Prevent voting after approval

        if (_vote) {
            featureProposals[_proposalId].upvotes++;
        } else {
            featureProposals[_proposalId].downvotes++;
        }
        emit FeatureProposalVoted(_proposalId, msg.sender, _vote);

        // Simple approval logic: more upvotes than downvotes
        if (featureProposals[_proposalId].upvotes > featureProposals[_proposalId].downvotes) {
            featureProposals[_proposalId].isApproved = true;
        }
    }

    /**
     * @dev (Owner only) Executes an approved feature proposal if it's feasible within the contract's scope.
     * @param _proposalId The ID of the feature proposal to execute.
     */
    function executeApprovedFeature(uint256 _proposalId) external onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCounter.current(), "Proposal does not exist");
        require(featureProposals[_proposalId].isApproved, "Proposal not approved yet");
        require(!featureProposals[_proposalId].isExecuted, "Proposal already executed");

        // In a real implementation, you would parse the proposal text and implement the feature.
        // This is a placeholder - for simplicity, we just mark it as executed and emit an event.
        featureProposals[_proposalId].isExecuted = true;
        emit FeatureProposalExecuted(_proposalId);
    }

    // --- Staking Functions (Basic Example) ---

    /**
     * @dev Allows users to stake tokens (ETH in this example) to participate in governance.
     * @param _amount The amount of tokens to stake (in wei).
     */
    function stakeTokens(uint256 _amount) external payable {
        require(msg.value >= _amount, "Insufficient ETH sent to stake");
        stakedBalances[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);
        if (msg.value > _amount) {
            payable(msg.sender).transfer(msg.value - _amount); // Refund extra ETH
        }
    }

    /**
     * @dev Allows users to unstake their tokens.
     * @param _amount The amount of tokens to unstake (in wei).
     */
    function unstakeTokens(uint256 _amount) external {
        require(stakedBalances[msg.sender] >= _amount, "Insufficient staked balance");
        stakedBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit TokensUnstaked(msg.sender, _amount);
    }

    // --- Auction Functions (Simple Example) ---

    /**
     * @dev Creates a new auction for an NFT.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT to auction.
     * @param _startingBid The starting bid price for the auction (in wei).
     * @param _durationInHours The duration of the auction in hours.
     */
    function createAuction(uint256 _collectionId, uint256 _tokenId, uint256 _startingBid, uint256 _durationInHours) external collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) {
        auctionCounter.increment();
        uint256 auctionId = auctionCounter.current();
        activeAuctions[auctionId] = Auction({
            collectionId: _collectionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startingBid: _startingBid,
            endTime: block.timestamp + (_durationInHours * 1 hours),
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit AuctionCreated(auctionId, _collectionId, _tokenId, msg.sender, _startingBid, activeAuctions[auctionId].endTime);
    }

    /**
     * @dev Allows users to place a bid on an active auction.
     * @param _auctionId The ID of the auction to bid on.
     */
    function bidOnAuction(uint256 _auctionId) external payable auctionExists(_auctionId) auctionNotEnded(_auctionId) notNFTOwnerInAuction(_auctionId) validBidAmount(_auctionId, msg.value) {
        Auction storage auction = activeAuctions[_auctionId];

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /**
     * @dev Finalizes an auction, transferring the NFT to the highest bidder and paying the seller.
     * @param _auctionId The ID of the auction to finalize.
     */
    function finalizeAuction(uint256 _auctionId) external auctionExists(_auctionId) auctionEnded(_auctionId) {
        Auction storage auction = activeAuctions[_auctionId];
        require(auction.isActive, "Auction is not active");

        auction.isActive = false; // Mark auction as inactive

        if (auction.highestBidder != address(0)) {
            uint256 marketplaceFee = (auction.highestBid * marketplaceFeePercentage) / 100;
            uint256 sellerPayout = auction.highestBid - marketplaceFee;

            // Transfer marketplace fee to contract owner
            payable(owner()).transfer(marketplaceFee);
            // Transfer payout to seller
            payable(auction.seller).transfer(sellerPayout);

            nftCollections[auction.collectionId].nftOwner[auction.tokenId] = auction.highestBidder;
            emit AuctionFinalized(_auctionId, auction.highestBidder, auction.highestBid);
            emit NFTTransferred(auction.collectionId, auction.tokenId, auction.seller, auction.highestBidder);
        } else {
            // No bids placed, return NFT to seller (optional - could also relist in marketplace)
            nftCollections[auction.collectionId].nftOwner[auction.tokenId] = auction.seller;
            // No funds to transfer in this case.
            emit AuctionFinalized(_auctionId, address(0), 0); // Indicate no winner
            emit NFTTransferred(auction.collectionId, auction.tokenId, address(0), auction.seller); // From address 0 as conceptually returning to seller
        }
    }
}
```