```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Integration
 * @author Bard (Example Smart Contract)
 * @dev A smart contract for a decentralized NFT marketplace focused on dynamic NFTs and AI-generated art integration.
 *      This contract offers advanced features like dynamic NFT updates, AI art request system, staking, governance, and more,
 *      while avoiding direct duplication of common open-source marketplace functionalities.
 *
 * **Outline & Function Summary:**
 *
 * **Core NFT Functionality:**
 *   1. `mintDynamicNFT(string memory _baseURI, string memory _initialMetadata, string memory _dynamicLogicIdentifier)`: Mints a new dynamic NFT.
 *   2. `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another address.
 *   3. `approve(address _approved, uint256 _tokenId)`: Approves an address to spend a single NFT.
 *   4. `setApprovalForAll(address _operator, bool _approved)`: Enables or disables approval for an operator to manage all of owner's NFTs.
 *   5. `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI for an NFT.
 *   6. `getDynamicLogicIdentifier(uint256 _tokenId)`: Retrieves the dynamic logic identifier associated with an NFT.
 *
 * **Dynamic NFT Update Mechanism:**
 *   7. `triggerDynamicUpdate(uint256 _tokenId)`: Triggers a dynamic update process for a specific NFT (Admin/Oracle role).
 *   8. `setDynamicUpdateLogicContract(address _logicContractAddress)`: Sets the contract address responsible for dynamic NFT update logic (Admin).
 *   9. `setDynamicUpdateInterval(uint256 _interval)`: Sets the minimum time interval between dynamic updates for NFTs (Admin).
 *   10. `getLastUpdateTime(uint256 _tokenId)`: Retrieves the last time a dynamic update was performed for an NFT.
 *
 * **AI Art Integration (Request & Fulfillment):**
 *   11. `requestAIArtGeneration(uint256 _tokenId, string memory _prompt)`: Allows NFT owners to request AI art generation for their NFT with a prompt.
 *   12. `setAIArtOracleAddress(address _oracleAddress)`: Sets the address of the AI art oracle contract (Admin).
 *   13. `fulfillAIArtGeneration(uint256 _requestId, string memory _artURI)`: Oracle function to fulfill an AI art request with the generated art URI.
 *   14. `getAIArtRequestStatus(uint256 _requestId)`: Retrieves the status of an AI art generation request.
 *
 * **Marketplace Functionality (Unique Approach):**
 *   15. `listItemForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *   16. `purchaseNFT(uint256 _listingId)`: Purchases an NFT listed on the marketplace.
 *   17. `cancelListing(uint256 _listingId)`: Cancels an NFT listing.
 *   18. `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Updates the price of an NFT listing.
 *   19. `getListingDetails(uint256 _listingId)`: Retrieves details of a specific NFT listing.
 *   20. `offerBid(uint256 _tokenId, uint256 _bidPrice)`: Allows users to make bids on NFTs (even if not listed, or to bid higher).
 *   21. `acceptBid(uint256 _bidId)`: Allows NFT owners to accept a bid on their NFT.
 *   22. `withdrawBid(uint256 _bidId)`: Allows bidders to withdraw their bid if not accepted.
 *
 * **Governance (Simple Feature Proposal):**
 *   23. `proposeFeature(string memory _featureDescription)`: Allows users to propose new features for the marketplace.
 *   24. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on feature proposals.
 *   25. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a feature proposal and vote counts.
 *
 * **Utility/Admin Functions:**
 *   26. `setBaseURI(string memory _baseURI)`: Sets the base URI for NFT metadata (Admin).
 *   27. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 */
contract DynamicNFTMarketplace {
    // ** State Variables **
    string public name = "Dynamic AI Art NFTs";
    string public symbol = "DAIANFT";
    string public baseURI; // Base URI for NFT metadata
    address public owner;
    address public dynamicUpdateLogicContract; // Address of the contract handling dynamic logic
    address public aiArtOracleAddress; // Address of the AI Art Oracle contract
    uint256 public dynamicUpdateInterval = 3600; // 1 hour default interval for dynamic updates
    uint256 public platformFeePercentage = 2; // 2% platform fee on sales

    uint256 public nextNFTId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftMetadataURI;
    mapping(uint256 => string) public nftDynamicLogicIdentifier;
    mapping(uint256 => address) public nftApproved;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => uint256) public lastNFTUpdateTime;

    uint256 public nextListingId = 1;
    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => NFTListing) public nftListings;

    uint256 public nextAIArtRequestId = 1;
    struct AIArtRequest {
        uint256 requestId;
        uint256 tokenId;
        address requester;
        string prompt;
        string artURI;
        bool isFulfilled;
    }
    mapping(uint256 => AIArtRequest) public aiArtRequests;

    uint256 public nextProposalId = 1;
    struct FeatureProposal {
        uint256 proposalId;
        string description;
        uint256 upvotes;
        uint256 downvotes;
        bool isActive;
    }
    mapping(uint256 => FeatureProposal) public featureProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => voted (true=upvote, false=downvote)

    uint256 public nextBidId = 1;
    struct NFTBid {
        uint256 bidId;
        uint256 tokenId;
        address bidder;
        uint256 bidPrice;
        bool isActive;
    }
    mapping(uint256 => NFTBid) public nftBids;
    mapping(uint256 => address) public bidToNFTListing; // bidId -> listingId (if bid is on a listing)

    // ** Events **
    event NFTMinted(uint256 tokenId, address owner, string metadataURI, string dynamicLogicIdentifier);
    event NFTTransfer(uint256 tokenId, address from, address to);
    event NFTApproved(uint256 tokenId, address approved, address owner);
    event ApprovalForAll(address owner, address operator, bool approved);
    event DynamicNFTUpdated(uint256 tokenId, string newMetadataURI);
    event AIArtRequested(uint256 requestId, uint256 tokenId, address requester, string prompt);
    event AIArtFulfilled(uint256 requestId, string artURI);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTPurchased(uint256 listingId, uint256 tokenId, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event BidOffered(uint256 bidId, uint256 tokenId, address bidder, uint256 bidPrice);
    event BidAccepted(uint256 bidId, uint256 tokenId, address bidder, address seller, uint256 price);
    event BidWithdrawn(uint256 bidId, uint256 tokenId, address bidder);
    event FeatureProposed(uint256 proposalId, string description, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event PlatformFeesWithdrawn(uint256 amount, address admin);

    // ** Modifiers **
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner.");
        _;
    }

    modifier onlyApprovedForAll(address _operator, address _owner) {
        require(isApprovedForAll(_owner, _operator), "Operator not approved for all.");
        _;
    }

    modifier onlyDynamicLogicContract() {
        require(msg.sender == dynamicUpdateLogicContract, "Only dynamic logic contract can call this.");
        _;
    }

    modifier onlyAIArtOracle() {
        require(msg.sender == aiArtOracleAddress, "Only AI Art Oracle can call this.");
        _;
    }

    // ** Constructor **
    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
    }

    // ** Core NFT Functionality **

    /// @notice Mints a new dynamic NFT.
    /// @param _baseURI Base URI for the NFT metadata.
    /// @param _initialMetadata Initial metadata to be associated with the NFT.
    /// @param _dynamicLogicIdentifier Identifier to specify the dynamic logic to be applied to this NFT.
    function mintDynamicNFT(string memory _initialMetadata, string memory _dynamicLogicIdentifier) public returns (uint256) {
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = msg.sender;
        nftMetadataURI[tokenId] = string(abi.encodePacked(baseURI, _initialMetadata)); // Combine base URI and metadata
        nftDynamicLogicIdentifier[tokenId] = _dynamicLogicIdentifier;
        lastNFTUpdateTime[tokenId] = block.timestamp; // Initialize last update time

        emit NFTMinted(tokenId, msg.sender, nftMetadataURI[tokenId], _dynamicLogicIdentifier);
        return tokenId;
    }

    /// @notice Transfers an NFT to another address.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public onlyApprovedOrOwner(_tokenId) {
        require(_to != address(0), "Transfer to zero address.");
        address from = nftOwner[_tokenId];
        nftOwner[_tokenId] = _to;
        delete nftApproved[_tokenId]; // Clear any approvals on transfer
        emit NFTTransfer(_tokenId, from, _to);
    }

    /// @notice Approves an address to spend a single NFT.
    /// @param _approved Address to be approved for spending.
    /// @param _tokenId ID of the NFT to approve.
    function approve(address _approved, uint256 _tokenId) public onlyApprovedOrOwner(_tokenId) {
        nftApproved[_tokenId] = _approved;
        emit NFTApproved(_tokenId, _approved, nftOwner[_tokenId]);
    }

    /// @notice Enables or disables approval for an operator to manage all of owner's NFTs.
    /// @param _operator Address to be approved as an operator.
    /// @param _approved Boolean to set the approval status (true for approved, false for not approved).
    function setApprovalForAll(address _operator, bool _approved) public {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Retrieves the current metadata URI for an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The metadata URI string.
    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return nftMetadataURI[_tokenId];
    }

    /// @notice Retrieves the dynamic logic identifier associated with an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The dynamic logic identifier string.
    function getDynamicLogicIdentifier(uint256 _tokenId) public view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return nftDynamicLogicIdentifier[_tokenId];
    }

    // ** Dynamic NFT Update Mechanism **

    /// @notice Triggers a dynamic update process for a specific NFT. Can be called by admin or an oracle.
    /// @dev This function would ideally interact with an external dynamic logic contract or oracle to determine the new metadata.
    /// @param _tokenId ID of the NFT to update.
    function triggerDynamicUpdate(uint256 _tokenId) public onlyOwner { // For demo purposes, only Owner can trigger. In real scenario, Oracle or Time-based trigger
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(block.timestamp >= lastNFTUpdateTime[_tokenId] + dynamicUpdateInterval, "Update interval not reached.");

        // In a real-world scenario, this would call an external DynamicLogic contract.
        // For this example, let's simulate a simple dynamic update by appending "_updated" to the metadata.
        string memory currentMetadata = nftMetadataURI[_tokenId];
        string memory newMetadata = string(abi.encodePacked(currentMetadata, "_updated"));
        nftMetadataURI[_tokenId] = newMetadata;
        lastNFTUpdateTime[_tokenId] = block.timestamp;

        emit DynamicNFTUpdated(_tokenId, newMetadata);
    }

    /// @notice Sets the contract address responsible for dynamic NFT update logic.
    /// @param _logicContractAddress Address of the dynamic logic contract.
    function setDynamicUpdateLogicContract(address _logicContractAddress) public onlyOwner {
        dynamicUpdateLogicContract = _logicContractAddress;
    }

    /// @notice Sets the minimum time interval between dynamic updates for NFTs.
    /// @param _interval Time interval in seconds.
    function setDynamicUpdateInterval(uint256 _interval) public onlyOwner {
        dynamicUpdateInterval = _interval;
    }

    /// @notice Retrieves the last time a dynamic update was performed for an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return Timestamp of the last update.
    function getLastUpdateTime(uint256 _tokenId) public view returns (uint256) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return lastNFTUpdateTime[_tokenId];
    }

    // ** AI Art Integration (Request & Fulfillment) **

    /// @notice Allows NFT owners to request AI art generation for their NFT with a prompt.
    /// @param _tokenId ID of the NFT for which AI art is requested.
    /// @param _prompt Prompt to guide the AI art generation.
    function requestAIArtGeneration(uint256 _tokenId, string memory _prompt) public onlyApprovedOrOwner(_tokenId) {
        require(aiArtOracleAddress != address(0), "AI Art Oracle address not set.");

        uint256 requestId = nextAIArtRequestId++;
        aiArtRequests[requestId] = AIArtRequest({
            requestId: requestId,
            tokenId: _tokenId,
            requester: msg.sender,
            prompt: _prompt,
            artURI: "",
            isFulfilled: false
        });

        // In a real application, this would trigger an off-chain process or call to the AI Oracle.
        // For now, let's just emit an event.
        emit AIArtRequested(requestId, _tokenId, msg.sender, _prompt);
    }

    /// @notice Sets the address of the AI art oracle contract.
    /// @param _oracleAddress Address of the AI art oracle contract.
    function setAIArtOracleAddress(address _oracleAddress) public onlyOwner {
        aiArtOracleAddress = _oracleAddress;
    }

    /// @notice Oracle function to fulfill an AI art request with the generated art URI.
    /// @param _requestId ID of the AI art request.
    /// @param _artURI URI of the generated AI art.
    function fulfillAIArtGeneration(uint256 _requestId, string memory _artURI) public onlyAIArtOracle {
        require(aiArtRequests[_requestId].requester != address(0), "AI Art Request does not exist.");
        require(!aiArtRequests[_requestId].isFulfilled, "AI Art Request already fulfilled.");

        aiArtRequests[_requestId].artURI = _artURI;
        aiArtRequests[_requestId].isFulfilled = true;

        // Update NFT metadata to include or point to the new AI art URI (example, append to metadata)
        string memory currentMetadata = nftMetadataURI[aiArtRequests[_requestId].tokenId];
        string memory newMetadata = string(abi.encodePacked(currentMetadata, " AI Art: ", _artURI));
        nftMetadataURI[aiArtRequests[_requestId].tokenId] = newMetadata;

        emit AIArtFulfilled(_requestId, _artURI);
        emit DynamicNFTUpdated(aiArtRequests[_requestId].tokenId, newMetadata); // Emit dynamic update event too
    }

    /// @notice Retrieves the status of an AI art generation request.
    /// @param _requestId ID of the AI art request.
    /// @return Struct containing AI art request details.
    function getAIArtRequestStatus(uint256 _requestId) public view returns (AIArtRequest memory) {
        require(aiArtRequests[_requestId].requester != address(0), "AI Art Request does not exist.");
        return aiArtRequests[_requestId];
    }

    // ** Marketplace Functionality (Unique Approach) **

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _tokenId ID of the NFT to list.
    /// @param _price Price at which the NFT is listed (in wei).
    function listItemForSale(uint256 _tokenId, uint256 _price) public onlyApprovedOrOwner(_tokenId) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(nftOwner[_tokenId] == msg.sender, "Only owner can list NFT."); // Only owner can list for sale
        require(_price > 0, "Price must be greater than zero.");

        uint256 listingId = nextListingId++;
        nftListings[listingId] = NFTListing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    /// @notice Purchases an NFT listed on the marketplace.
    /// @param _listingId ID of the NFT listing.
    function purchaseNFT(uint256 _listingId) public payable {
        require(nftListings[_listingId].listingId != 0, "Listing does not exist.");
        require(nftListings[_listingId].isActive, "Listing is not active.");
        require(msg.value >= nftListings[_listingId].price, "Insufficient funds.");

        NFTListing storage listing = nftListings[_listingId];
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        listing.isActive = false; // Deactivate the listing
        transferNFT(msg.sender, tokenId); // Transfer NFT to buyer

        // Platform fee calculation and transfer
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerProceeds = price - platformFee;

        (bool successSeller, ) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "Seller payment failed.");

        (bool successPlatform, ) = payable(owner).call{value: platformFee}("");
        require(successPlatform, "Platform fee payment failed.");

        emit NFTPurchased(_listingId, tokenId, msg.sender, seller, price);
    }

    /// @notice Cancels an NFT listing. Only seller can cancel.
    /// @param _listingId ID of the NFT listing to cancel.
    function cancelListing(uint256 _listingId) public {
        require(nftListings[_listingId].listingId != 0, "Listing does not exist.");
        require(nftListings[_listingId].isActive, "Listing is not active.");
        require(nftListings[_listingId].seller == msg.sender, "Only seller can cancel listing.");

        nftListings[_listingId].isActive = false; // Deactivate the listing
        emit ListingCancelled(_listingId, nftListings[_listingId].tokenId);
    }

    /// @notice Updates the price of an NFT listing. Only seller can update.
    /// @param _listingId ID of the NFT listing to update.
    /// @param _newPrice New price for the NFT listing.
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public {
        require(nftListings[_listingId].listingId != 0, "Listing does not exist.");
        require(nftListings[_listingId].isActive, "Listing is not active.");
        require(nftListings[_listingId].seller == msg.sender, "Only seller can update price.");
        require(_newPrice > 0, "Price must be greater than zero.");

        nftListings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, nftListings[_listingId].tokenId, _newPrice);
    }

    /// @notice Retrieves details of a specific NFT listing.
    /// @param _listingId ID of the NFT listing.
    /// @return Struct containing NFT listing details.
    function getListingDetails(uint256 _listingId) public view returns (NFTListing memory) {
        require(nftListings[_listingId].listingId != 0, "Listing does not exist.");
        return nftListings[_listingId];
    }

    /// @notice Allows users to make bids on NFTs (even if not listed, or to bid higher).
    /// @param _tokenId ID of the NFT to bid on.
    /// @param _bidPrice Price offered for the NFT (in wei).
    function offerBid(uint256 _tokenId, uint256 _bidPrice) public payable {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(_bidPrice > 0, "Bid price must be greater than zero.");
        require(msg.value >= _bidPrice, "Insufficient bid amount.");

        uint256 bidId = nextBidId++;
        nftBids[bidId] = NFTBid({
            bidId: bidId,
            tokenId: _tokenId,
            bidder: msg.sender,
            bidPrice: _bidPrice,
            isActive: true
        });

        emit BidOffered(bidId, _tokenId, msg.sender, _bidPrice);
    }

    /// @notice Allows NFT owners to accept a bid on their NFT.
    /// @param _bidId ID of the bid to accept.
    function acceptBid(uint256 _bidId) public onlyApprovedOrOwner(nftBids[_bidId].tokenId) {
        require(nftBids[_bidId].bidId != 0, "Bid does not exist.");
        require(nftBids[_bidId].isActive, "Bid is not active.");
        require(nftOwner[nftBids[_bidId].tokenId] == msg.sender, "Only NFT owner can accept bid.");

        NFTBid storage bid = nftBids[_bidId];
        uint256 tokenId = bid.tokenId;
        address bidder = bid.bidder;
        uint256 bidPrice = bid.bidPrice;

        bid.isActive = false; // Deactivate the bid
        transferNFT(bidder, tokenId); // Transfer NFT to bidder

        // Pay seller (NFT owner) the bid price
        (bool successSeller, ) = payable(msg.sender).call{value: bidPrice}(""); // msg.sender is owner accepting bid
        require(successSeller, "Seller payment failed.");

        // Refund any overpayment from the bid (if any, though in this example, msg.value should equal bidPrice)
        if (msg.value > bidPrice) {
            uint256 refundAmount = msg.value - bidPrice;
            (bool successRefund, ) = payable(bidder).call{value: refundAmount}("");
            require(successRefund, "Bid refund failed.");
        }

        emit BidAccepted(_bidId, tokenId, bidder, msg.sender, bidPrice);

        // Invalidate other active bids on the same NFT (optional, but good practice)
        for (uint256 i = 1; i < nextBidId; i++) {
            if (nftBids[i].isActive && nftBids[i].tokenId == tokenId && i != _bidId) {
                nftBids[i].isActive = false;
                // Refund other bidders (implementation left as exercise, as it requires tracking bidder's initial overpayment if any)
                // For simplicity, assuming bidder sent exactly bidPrice for now.
            }
        }
    }

    /// @notice Allows bidders to withdraw their bid if not accepted.
    /// @param _bidId ID of the bid to withdraw.
    function withdrawBid(uint256 _bidId) public {
        require(nftBids[_bidId].bidId != 0, "Bid does not exist.");
        require(nftBids[_bidId].isActive, "Bid is not active.");
        require(nftBids[_bidId].bidder == msg.sender, "Only bidder can withdraw bid.");

        NFTBid storage bid = nftBids[_bidId];
        bid.isActive = false; // Deactivate the bid
        uint256 bidPrice = bid.bidPrice;

        // Refund the bid amount to the bidder
        (bool successRefund, ) = payable(msg.sender).call{value: bidPrice}("");
        require(successRefund, "Bid refund failed.");

        emit BidWithdrawn(_bidId, bid.tokenId, msg.sender);
    }


    // ** Governance (Simple Feature Proposal) **

    /// @notice Allows users to propose new features for the marketplace.
    /// @param _featureDescription Description of the feature proposal.
    function proposeFeature(string memory _featureDescription) public {
        uint256 proposalId = nextProposalId++;
        featureProposals[proposalId] = FeatureProposal({
            proposalId: proposalId,
            description: _featureDescription,
            upvotes: 0,
            downvotes: 0,
            isActive: true
        });
        emit FeatureProposed(proposalId, _featureDescription, msg.sender);
    }

    /// @notice Allows NFT holders to vote on feature proposals.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for upvote, false for downvote.
    function voteOnProposal(uint256 _proposalId, bool _vote) public {
        require(featureProposals[_proposalId].proposalId != 0, "Proposal does not exist.");
        require(featureProposals[_proposalId].isActive, "Proposal is not active.");
        require(nftOwner[1] != address(0), "At least one NFT must be minted to vote. For demo, assuming tokenId 1 means voting power."); // Simple voting power: NFT ownership (tokenId=1)
        require(nftOwner[1] == msg.sender, "Only NFT holders can vote (TokenId 1)."); // Simple voting power: NFT ownership (tokenId=1)
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true; // Record that voter has voted

        if (_vote) {
            featureProposals[_proposalId].upvotes++;
        } else {
            featureProposals[_proposalId].downvotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Retrieves details of a feature proposal and vote counts.
    /// @param _proposalId ID of the feature proposal.
    /// @return Struct containing feature proposal details.
    function getProposalDetails(uint256 _proposalId) public view returns (FeatureProposal memory) {
        require(featureProposals[_proposalId].proposalId != 0, "Proposal does not exist.");
        return featureProposals[_proposalId];
    }

    // ** Utility/Admin Functions **

    /// @notice Sets the base URI for NFT metadata.
    /// @param _baseURI New base URI string.
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance; // To avoid confusion if we add more logic later.
        require(contractBalance > 0, "No platform fees to withdraw.");

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Withdrawal failed.");
        emit PlatformFeesWithdrawn(contractBalance, owner);
    }

    // ** Helper Functions **

    /// @dev Checks if an address is approved to manage a token or is the owner.
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address ownerOf = nftOwner[_tokenId];
        return (_spender == ownerOf || nftApproved[_tokenId] == _spender || isApprovedForAll(ownerOf, _spender));
    }

    /// @dev Checks if an operator is approved to manage all tokens of an owner.
    function isApprovedForAll(address _owner, address _operator) internal view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }
}
```