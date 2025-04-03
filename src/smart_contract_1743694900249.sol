```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Data NFT Marketplace with AI-Powered Recommendations
 * @author Bard (Example Smart Contract - Conceptual and for illustrative purposes only)
 *
 * @dev This smart contract implements a dynamic data NFT marketplace with simulated AI-powered recommendations.
 * It allows users to mint, list, buy, and sell Data NFTs.
 * The "AI recommendation" is a simplified, on-chain simulation for demonstration purposes.
 *
 * Function Summary:
 * -----------------
 * **Data NFT Management:**
 * 1. mintDataNFT(string memory _metadataURI): Mints a new Data NFT with associated metadata.
 * 2. transferDataNFT(address _to, uint256 _tokenId): Transfers ownership of a Data NFT.
 * 3. updateDataNFTMetadata(uint256 _tokenId, string memory _newMetadataURI): Updates the metadata URI of a Data NFT (Dynamic Data aspect).
 * 4. getDataNFTMetadata(uint256 _tokenId): Retrieves the metadata URI of a Data NFT.
 * 5. burnDataNFT(uint256 _tokenId): Allows the NFT owner to burn (destroy) a Data NFT.
 *
 * **Marketplace Functionality:**
 * 6. listItemForSale(uint256 _tokenId, uint256 _price): Lists a Data NFT for sale on the marketplace.
 * 7. buyDataNFT(uint256 _listingId): Allows a user to buy a Data NFT listed on the marketplace.
 * 8. cancelListing(uint256 _listingId): Allows the seller to cancel a listing before it's bought.
 * 9. getListingDetails(uint256 _listingId): Retrieves details of a specific marketplace listing.
 * 10. getAllListings(): Retrieves a list of all active marketplace listings.
 *
 * **Bidding System (Advanced Marketplace Feature):**
 * 11. placeBid(uint256 _listingId, uint256 _bidAmount): Allows users to place bids on listed Data NFTs.
 * 12. acceptBid(uint256 _listingId, uint256 _bidId): Allows the seller to accept a specific bid and finalize the sale.
 * 13. cancelBid(uint256 _listingId, uint256 _bidId): Allows a bidder to cancel their bid before it's accepted.
 * 14. getBidsForListing(uint256 _listingId): Retrieves a list of bids placed on a specific listing.
 *
 * **"AI" Recommendation Simulation (Conceptual):**
 * 15. requestRecommendation(string memory _userPreferences): Simulates a request for NFT recommendations based on user preferences.
 * 16. generateRecommendation(): (Internal) - Simulates an AI recommendation algorithm (very basic example here).
 * 17. getRecommendedNFTs(): Retrieves a list of Data NFT IDs recommended for the requester.
 *
 * **Governance/Community Features (Optional - can be expanded):**
 * 18. proposeFeature(string memory _featureProposal): Allows users to propose new features for the marketplace (governance aspect).
 * 19. voteOnProposal(uint256 _proposalId, bool _vote): Allows NFT holders to vote on feature proposals (simple voting).
 * 20. executeProposal(uint256 _proposalId): (Admin/Governance controlled) - Executes an approved feature proposal (placeholder).
 *
 * **Utility/Admin Functions:**
 * 21. setMarketplaceFee(uint256 _feePercentage): Allows the contract owner to set the marketplace fee.
 * 22. withdrawMarketplaceFees(): Allows the contract owner to withdraw accumulated marketplace fees.
 * 23. pauseContract(): Allows the contract owner to pause the contract in case of emergency.
 * 24. unpauseContract(): Allows the contract owner to unpause the contract.
 */

contract DynamicDataNFTMarketplace {
    // State Variables

    // NFT related
    mapping(uint256 => address) public nftOwner; // Token ID to Owner Address
    mapping(uint256 => string) public nftMetadataURI; // Token ID to Metadata URI
    uint256 public nextTokenId = 1; // Counter for token IDs

    // Marketplace related
    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
        uint256 listingId;
    }
    mapping(uint256 => Listing) public listings; // Listing ID to Listing Details
    uint256 public nextListingId = 1; // Counter for Listing IDs
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee (adjust as needed)
    address payable public marketplaceFeeRecipient; // Address to receive marketplace fees

    // Bidding System related
    struct Bid {
        uint256 bidId;
        uint256 listingId;
        address bidder;
        uint256 bidAmount;
        bool isActive;
    }
    mapping(uint256 => Bid) public bids; // Bid ID to Bid Details
    mapping(uint256 => Bid[]) public listingBids; // Listing ID to Array of Bids
    uint256 public nextBidId = 1; // Counter for Bid IDs

    // "AI" Recommendation (Simplified Simulation)
    string[] public recommendedNFTs; // Array to store recommended NFT IDs (very basic simulation)

    // Governance (Simple Proposal System)
    struct Proposal {
        uint256 proposalId;
        string proposalText;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isExecuted;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;

    // Contract Admin/Utility
    address public owner;
    bool public paused;

    // Events
    event NFTMinted(uint256 tokenId, address owner, string metadataURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTBurned(uint256 tokenId, address owner);
    event NFTListed(uint256 listingId, uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 listingId);
    event BidPlaced(uint256 bidId, uint256 listingId, address bidder, uint256 bidAmount);
    event BidAccepted(uint256 bidId, uint256 listingId, address seller, address buyer, uint256 price);
    event BidCancelled(uint256 bidId);
    event RecommendationRequested(address requester, string preferences);
    event RecommendationGenerated(address requester, uint256[] recommendedTokenIds);
    event FeatureProposed(uint256 proposalId, address proposer, string proposalText);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();
    event MarketplaceFeeSet(uint256 feePercentage);
    event FeesWithdrawn(uint256 amount, address recipient);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId == _listingId && listings[_listingId].isActive, "Listing does not exist or is not active.");
        _;
    }

    modifier bidExists(uint256 _bidId) {
        require(bids[_bidId].bidId == _bidId && bids[_bidId].isActive, "Bid does not exist or is not active.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId && proposals[_proposalId].isActive && !proposals[_proposalId].isExecuted, "Proposal does not exist, is not active, or is executed.");
        _;
    }

    modifier isNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    // Constructor
    constructor(address payable _feeRecipient) payable {
        owner = msg.sender;
        marketplaceFeeRecipient = _feeRecipient;
    }

    // ------------------------------------------------------------
    // Data NFT Management Functions
    // ------------------------------------------------------------

    /// @notice Mints a new Data NFT with associated metadata.
    /// @param _metadataURI URI pointing to the metadata of the NFT.
    function mintDataNFT(string memory _metadataURI) external whenNotPaused {
        uint256 tokenId = nextTokenId++;
        nftOwner[tokenId] = msg.sender;
        nftMetadataURI[tokenId] = _metadataURI;
        emit NFTMinted(tokenId, msg.sender, _metadataURI);
    }

    /// @notice Transfers ownership of a Data NFT.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId ID of the Data NFT to transfer.
    function transferDataNFT(address _to, uint256 _tokenId) external whenNotPaused isNFTOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        nftOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @notice Updates the metadata URI of a Data NFT (Dynamic Data aspect).
    /// @param _tokenId ID of the Data NFT to update.
    /// @param _newMetadataURI New URI pointing to the updated metadata.
    function updateDataNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) external whenNotPaused isNFTOwner(_tokenId) {
        nftMetadataURI[_tokenId] = _newMetadataURI;
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /// @notice Retrieves the metadata URI of a Data NFT.
    /// @param _tokenId ID of the Data NFT to retrieve metadata for.
    /// @return string Metadata URI of the Data NFT.
    function getDataNFTMetadata(uint256 _tokenId) external view returns (string memory) {
        return nftMetadataURI[_tokenId];
    }

    /// @notice Allows the NFT owner to burn (destroy) a Data NFT.
    /// @param _tokenId ID of the Data NFT to burn.
    function burnDataNFT(uint256 _tokenId) external whenNotPaused isNFTOwner(_tokenId) {
        delete nftOwner[_tokenId];
        delete nftMetadataURI[_tokenId];
        emit NFTBurned(_tokenId, msg.sender);
    }


    // ------------------------------------------------------------
    // Marketplace Functionality
    // ------------------------------------------------------------

    /// @notice Lists a Data NFT for sale on the marketplace.
    /// @param _tokenId ID of the Data NFT to list.
    /// @param _price Price in Wei to list the NFT for.
    function listItemForSale(uint256 _tokenId, uint256 _price) external whenNotPaused isNFTOwner(_tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(_price > 0, "Price must be greater than zero.");
        require(listings[nextListingId].listingId == 0, "Listing ID collision, try again."); // Very unlikely, but as a safety.

        listings[nextListingId] = Listing({
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true,
            listingId: nextListingId
        });

        emit NFTListed(nextListingId, _tokenId, _price, msg.sender);
        nextListingId++;
    }

    /// @notice Allows a user to buy a Data NFT listed on the marketplace.
    /// @param _listingId ID of the listing to buy.
    function buyDataNFT(uint256 _listingId) external payable whenNotPaused listingExists(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");
        require(listing.seller != msg.sender, "Seller cannot buy their own NFT.");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = listing.price - feeAmount;

        // Transfer NFT ownership
        nftOwner[listing.tokenId] = msg.sender;
        emit NFTTransferred(listing.tokenId, listing.seller, msg.sender);

        // Transfer funds to seller (minus fee)
        payable(listing.seller).transfer(sellerAmount);

        // Transfer marketplace fee
        marketplaceFeeRecipient.transfer(feeAmount);

        // Deactivate the listing
        listing.isActive = false;
        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.seller, listing.price);
    }

    /// @notice Allows the seller to cancel a listing before it's bought.
    /// @param _listingId ID of the listing to cancel.
    function cancelListing(uint256 _listingId) external whenNotPaused listingExists(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only the seller can cancel the listing.");
        listing.isActive = false;
        emit ListingCancelled(_listingId);
    }

    /// @notice Retrieves details of a specific marketplace listing.
    /// @param _listingId ID of the listing to get details for.
    /// @return Listing struct containing listing details.
    function getListingDetails(uint256 _listingId) external view listingExists(_listingId) returns (Listing memory) {
        return listings[_listingId];
    }

    /// @notice Retrieves a list of all active marketplace listings.
    /// @return Listing[] Array of active Listing structs.
    function getAllListings() external view returns (Listing[] memory) {
        uint256 listingCount = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive) {
                listingCount++;
            }
        }

        Listing[] memory activeListings = new Listing[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive) {
                activeListings[index] = listings[i];
                index++;
            }
        }
        return activeListings;
    }


    // ------------------------------------------------------------
    // Bidding System (Advanced Marketplace Feature)
    // ------------------------------------------------------------

    /// @notice Allows users to place bids on listed Data NFTs.
    /// @param _listingId ID of the listing to bid on.
    /// @param _bidAmount Amount in Wei the user is bidding.
    function placeBid(uint256 _listingId, uint256 _bidAmount) external payable whenNotPaused listingExists(_listingId) {
        require(msg.value >= _bidAmount, "Bid amount must be sent with the transaction.");
        require(listings[_listingId].seller != msg.sender, "Seller cannot bid on their own listing.");
        require(_bidAmount > 0, "Bid amount must be positive.");

        Bid memory newBid = Bid({
            bidId: nextBidId,
            listingId: _listingId,
            bidder: msg.sender,
            bidAmount: _bidAmount,
            isActive: true
        });
        bids[nextBidId] = newBid;
        listingBids[_listingId].push(newBid);

        emit BidPlaced(nextBidId, _listingId, msg.sender, _bidAmount);
        nextBidId++;
    }

    /// @notice Allows the seller to accept a specific bid and finalize the sale.
    /// @param _listingId ID of the listing where the bid is placed.
    /// @param _bidId ID of the bid to accept.
    function acceptBid(uint256 _listingId, uint256 _bidId) external whenNotPaused listingExists(_listingId) bidExists(_bidId) {
        Listing storage listing = listings[_listingId];
        Bid storage bid = bids[_bidId];

        require(listing.seller == msg.sender, "Only the seller can accept bids.");
        require(bid.listingId == _listingId, "Bid is not for this listing.");
        require(bid.isActive, "Bid is not active.");

        uint256 feeAmount = (bid.bidAmount * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = bid.bidAmount - feeAmount;

        // Transfer NFT ownership
        nftOwner[listing.tokenId] = bid.bidder;
        emit NFTTransferred(listing.tokenId, listing.seller, bid.bidder);

        // Transfer funds to seller (minus fee)
        payable(listing.seller).transfer(sellerAmount);

        // Transfer marketplace fee
        marketplaceFeeRecipient.transfer(feeAmount);

        // Deactivate listing and bid
        listing.isActive = false;
        bid.isActive = false;

        // Refund other bidders (optional, can be implemented for better UX) - not implemented in this example for simplicity

        emit BidAccepted(_bidId, _listingId, listing.seller, bid.bidder, bid.bidAmount);
    }

    /// @notice Allows a bidder to cancel their bid before it's accepted. Refunds the bid amount.
    /// @param _listingId ID of the listing where the bid was placed.
    /// @param _bidId ID of the bid to cancel.
    function cancelBid(uint256 _listingId, uint256 _bidId) external whenNotPaused listingExists(_listingId) bidExists(_bidId) {
        Bid storage bid = bids[_bidId];
        require(bid.bidder == msg.sender, "Only the bidder can cancel their bid.");
        require(bid.listingId == _listingId, "Bid is not for this listing.");
        require(bid.isActive, "Bid is not active.");

        bid.isActive = false;
        payable(msg.sender).transfer(bid.bidAmount); // Refund the bid amount
        emit BidCancelled(_bidId);
    }

    /// @notice Retrieves a list of bids placed on a specific listing.
    /// @param _listingId ID of the listing to get bids for.
    /// @return Bid[] Array of Bid structs for the listing.
    function getBidsForListing(uint256 _listingId) external view listingExists(_listingId) returns (Bid[] memory) {
        return listingBids[_listingId];
    }


    // ------------------------------------------------------------
    // "AI" Recommendation Simulation (Conceptual)
    // ------------------------------------------------------------

    /// @notice Simulates a request for NFT recommendations based on user preferences.
    /// @param _userPreferences String representing user preferences (e.g., "data science", "art", "finance").
    function requestRecommendation(string memory _userPreferences) external whenNotPaused {
        emit RecommendationRequested(msg.sender, _userPreferences);
        generateRecommendation(); // Simulate AI recommendation generation
        emit RecommendationGenerated(msg.sender, getRecommendedNFTs()); // Emit recommended NFTs
    }

    /// @notice (Internal) - Simulates an AI recommendation algorithm (very basic example here).
    /// In a real application, this would be much more complex and likely off-chain.
    function generateRecommendation() internal {
        // In a real AI system, this would be based on user preferences, NFT metadata, etc.
        // For this example, we'll just return a few NFTs randomly (or based on a very simple criteria).

        // Clear previous recommendations
        delete recommendedNFTs;

        // Very basic example: Recommend NFTs with metadata containing "data"
        uint256[] memory recommendedTokenIds;
        uint256 count = 0;
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (nftMetadataURI[i].find("data") != type(uint256).max) { // Simple string search for "data" in metadata
                recommendedTokenIds[count] = i; // Inefficient in Solidity, just for demonstration
                count++;
                if (count >= 3) break; // Limit recommendations to 3 for this example.
            }
        }
        // In reality, you'd use a more sophisticated algorithm and data structure.
        // For simplicity, we just push the token IDs to the public array.
        for(uint i=0; i<recommendedTokenIds.length; ++i) {
            recommendedNFTs.push(string(abi.encodePacked(uint2str(recommendedTokenIds[i])))); // Convert uint to string for simplicity in example
        }
    }

    // Simple uint to string conversion (for demonstration purposes only - not gas efficient for production)
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }


    /// @notice Retrieves a list of Data NFT IDs recommended for the requester.
    /// @return string[] Array of recommended Data NFT IDs (as strings for simplicity in this example).
    function getRecommendedNFTs() public view returns (string[] memory) {
        return recommendedNFTs;
    }


    // ------------------------------------------------------------
    // Governance/Community Features (Optional - can be expanded)
    // ------------------------------------------------------------

    /// @notice Allows users to propose new features for the marketplace (governance aspect).
    /// @param _featureProposal Text describing the feature proposal.
    function proposeFeature(string memory _featureProposal) external whenNotPaused {
        require(bytes(_featureProposal).length > 0, "Proposal text cannot be empty.");

        proposals[nextProposalId] = Proposal({
            proposalId: nextProposalId,
            proposalText: _featureProposal,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            isExecuted: false
        });
        emit FeatureProposed(nextProposalId, msg.sender, _featureProposal);
        nextProposalId++;
    }

    /// @notice Allows NFT holders to vote on feature proposals (simple voting).
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for 'yes' vote, false for 'no' vote.
    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused proposalExists(_proposalId) {
        require(nftOwner[1] != address(0), "Only NFT holders can vote. (Simple example: Check if NFT ID 1 exists as a holder proxy)"); // Very basic example - in real governance, you'd have a better system.
        require(proposals[_proposalId].isActive, "Proposal is not active.");

        Proposal storage proposal = proposals[_proposalId];
        // In a real governance system, voting power would be weighted (e.g., based on number of NFTs held).
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice (Admin/Governance controlled) - Executes an approved feature proposal (placeholder).
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.yesVotes > proposal.noVotes, "Proposal not approved by majority.");
        require(!proposal.isExecuted, "Proposal already executed.");

        proposal.isExecuted = true;
        proposal.isActive = false; // Deactivate after execution
        emit ProposalExecuted(_proposalId);
        // In a real system, this function would implement the actual feature change.
        // For this example, it's just a placeholder.
        // Example: Could be used to change contract parameters, upgrade logic, etc.
    }


    // ------------------------------------------------------------
    // Utility/Admin Functions
    // ------------------------------------------------------------

    /// @notice Allows the contract owner to set the marketplace fee percentage.
    /// @param _feePercentage New marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10, "Fee percentage cannot exceed 10%."); // Example limit
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Deduct msg.value if any ETH sent with tx

        require(contractBalance > 0, "No marketplace fees to withdraw.");
        marketplaceFeeRecipient.transfer(contractBalance);
        emit FeesWithdrawn(contractBalance, marketplaceFeeRecipient);
    }

    /// @notice Allows the contract owner to pause the contract in case of emergency.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Allows the contract owner to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // Fallback function to receive ETH (for marketplace fees, etc.)
    receive() external payable {}
}
```