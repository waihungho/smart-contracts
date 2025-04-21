```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Curation and Fractional Ownership
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This smart contract implements a sophisticated NFT marketplace with advanced features:
 *      - Dynamic NFTs: NFTs can have evolving metadata and properties influenced by external factors or oracle data.
 *      - AI-Powered Curation: Integrates with an AI Oracle to provide curation scores for NFTs, influencing discoverability and trust.
 *      - Fractional Ownership: Allows NFTs to be fractionalized, enabling shared ownership and investment.
 *      - Decentralized Governance: Incorporates basic governance mechanisms for community involvement in marketplace parameters.
 *      - Advanced Listing and Offer System: Supports various listing types (fixed price, auction) and sophisticated offer mechanisms.
 *      - Reputation System: Tracks user reputation based on marketplace activity, potentially influencing trust and access.
 *      - Cross-Chain Interoperability (Conceptual):  Designed with potential for future cross-chain NFT integration (though not fully implemented here).
 *
 * Function Summary:
 *
 * --- Core Marketplace Functions ---
 * 1. listNFT(): Allows users to list their NFTs on the marketplace. Supports dynamic NFT properties and listing types.
 * 2. delistNFT(): Allows users to remove their NFTs from the marketplace.
 * 3. buyNFT(): Enables users to directly purchase NFTs listed at a fixed price.
 * 4. makeOffer(): Allows users to make offers on listed NFTs, even if not listed for fixed price (e.g., for auction listings).
 * 5. acceptOffer(): Allows sellers to accept specific offers made on their NFTs.
 * 6. cancelOffer(): Allows buyers to cancel their pending offers.
 * 7. settleAuction(): (For Auction Listings) Allows settling an auction and transferring NFT to the highest bidder.
 * 8. updateListingPrice(): Allows sellers to update the price of their listed NFTs (within certain constraints or governance rules).
 *
 * --- Dynamic NFT and Curation Functions ---
 * 9. setDynamicNFTAttribute(): (By NFT owner) Allows setting or updating dynamic attributes of a listed NFT. Requires NFT contract support for dynamic attributes.
 * 10. requestAICurationScore(): (By anyone) Requests an AI curation score for a specific NFT from an external AI Oracle.
 * 11. setCurationScore(): (By AI Oracle - Authorized Address) Allows the AI Oracle to set the curation score for an NFT.
 * 12. getNFTCurationScore(): Allows anyone to retrieve the AI curation score of an NFT.
 * 13. updateNFTMetadata(): (By NFT owner, or potentially based on curation/dynamic events) Allows updating the base metadata URI of a listed NFT (if supported by NFT contract).
 *
 * --- Fractional Ownership Functions ---
 * 14. fractionalizeNFT(): (By NFT owner) Allows fractionalizing a listed NFT, creating fungible tokens representing ownership shares.
 * 15. buyFraction(): Allows users to purchase fractions of a fractionalized NFT.
 * 16. redeemFraction(): (Potentially with governance) Allows fraction holders to collectively redeem their fractions and reclaim the full NFT (complex and may require external mechanisms).
 * 17. getFractionDetails(): Allows anyone to retrieve details about the fractions of a specific NFT.
 *
 * --- Governance and Utility Functions ---
 * 18. proposeMarketplaceChange(): (By governance token holders) Allows proposing changes to marketplace parameters (e.g., fees, supported NFT contracts).
 * 19. voteOnProposal(): (By governance token holders) Allows voting on active marketplace change proposals.
 * 20. executeProposal(): (By authorized governance executor - after proposal passes) Executes approved marketplace change proposals.
 * 21. setMarketplaceFee(): (Governance controlled) Allows setting the marketplace fee.
 * 22. withdrawFees(): (Admin/Governance controlled) Allows withdrawing accumulated marketplace fees.
 * 23. pauseMarketplace(): (Admin/Governance controlled) Allows pausing marketplace operations in case of emergency.
 * 24. getUserReputation(): Allows anyone to retrieve a user's reputation score on the marketplace. (Conceptual - reputation logic needs to be implemented).
 *
 * --- Events ---
 * Emits events for all major actions to facilitate off-chain tracking and indexing.
 */
contract DynamicNFTMarketplace {

    // --- State Variables ---

    // Addresses
    address public admin; // Marketplace Admin Address
    address public aiOracleAddress; // Address of the AI Curation Oracle
    address public governanceTokenAddress; // Address of the Governance Token contract (if applicable)
    address public feeRecipient; // Address to receive marketplace fees

    // Marketplace Parameters
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    uint256 public curationRequestFee = 0.01 ether; // Fee for requesting AI curation (example)
    mapping(address => bool) public supportedNFTContracts; // Whitelisted NFT contract addresses

    // Listing and Offer Management
    uint256 public listingIdCounter;
    uint256 public offerIdCounter;

    enum ListingType { FixedPrice, Auction }
    enum ListingStatus { Active, Sold, Cancelled }
    enum OfferStatus { Pending, Accepted, Rejected, Cancelled }

    struct Listing {
        uint256 listingId;
        address nftContractAddress;
        uint256 tokenId;
        address seller;
        uint256 price; // Listing price (or starting price for auction)
        ListingType listingType;
        ListingStatus status;
        uint256 endTime; // For auction listings
        bool isDynamicNFT;
        uint256 curationScore; // Curation score from AI Oracle
        bool isFractionalized;
    }
    mapping(uint256 => Listing) public listings;
    mapping(address => mapping(uint256 => uint256)) public nftToListingId; // NFT address and tokenId to listingId

    struct Offer {
        uint256 offerId;
        uint256 listingId;
        address buyer;
        uint256 price;
        OfferStatus status;
        uint256 timestamp;
    }
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => Offer[]) public listingOffers; // Listing ID to array of offers

    // Fractional Ownership
    struct FractionDetails {
        bool isFractionalized;
        uint256 fractionTokenSupply;
        address fractionTokenContract; // Address of the deployed ERC20 fraction token contract (external deployment)
    }
    mapping(uint256 => FractionDetails) public fractionDetails; // listingId => FractionDetails

    // User Reputation (Conceptual - Basic placeholder)
    mapping(address => uint256) public userReputation;

    // Paused State
    bool public paused = false;

    // --- Events ---
    event NFTListed(uint256 listingId, address nftContractAddress, uint256 tokenId, address seller, uint256 price, ListingType listingType);
    event NFTDelisted(uint256 listingId, uint256 tokenId, address seller);
    event NFTSold(uint256 listingId, uint256 tokenId, address seller, address buyer, uint256 price);
    event OfferMade(uint256 offerId, uint256 listingId, address buyer, uint256 price);
    event OfferAccepted(uint256 offerId, uint256 listingId, address seller, address buyer, uint256 price);
    event OfferCancelled(uint256 offerId, uint256 listingId, address buyer);
    event AuctionSettled(uint256 listingId, uint256 tokenId, address seller, address winner, uint256 finalPrice);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event DynamicNFTAttributeSet(uint256 listingId, string attributeName, string attributeValue);
    event AICurationScoreRequested(uint256 listingId, address requester);
    event CurationScoreSet(uint256 listingId, uint256 curationScore, address oracle);
    event NFTMetadataUpdated(uint256 listingId, string newMetadataURI);
    event NFTFractionalized(uint256 listingId, address fractionTokenContract, uint256 fractionTokenSupply);
    event FractionBought(uint256 listingId, address buyer, uint256 fractionAmount, uint256 fractionPrice);
    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event FeesWithdrawn(uint256 amount, address recipient);
    event MarketplacePaused();
    event MarketplaceUnpaused();


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this function.");
        _;
    }

    modifier onlySupportedNFTContract(address _nftContractAddress) {
        require(supportedNFTContracts[_nftContractAddress], "NFT contract not supported.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId == _listingId, "Listing does not exist.");
        _;
    }

    modifier offerExists(uint256 _offerId) {
        require(offers[_offerId].offerId == _offerId, "Offer does not exist.");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "Only listing seller can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Marketplace is paused.");
        _;
    }

    // --- Constructor ---
    constructor(address _admin, address _aiOracleAddress, address _feeRecipient) {
        admin = _admin;
        aiOracleAddress = _aiOracleAddress;
        feeRecipient = _feeRecipient;
    }

    // --- Admin Functions ---
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address.");
        admin = _newAdmin;
    }

    function setOracleAddress(address _newOracleAddress) external onlyAdmin {
        require(_newOracleAddress != address(0), "Invalid oracle address.");
        aiOracleAddress = _newOracleAddress;
    }

    function setFeeRecipient(address _newFeeRecipient) external onlyAdmin {
        require(_newFeeRecipient != address(0), "Invalid fee recipient address.");
        feeRecipient = _newFeeRecipient;
    }

    function setMarketplaceFee(uint256 _newFeePercentage) external onlyAdmin {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeSet(_newFeePercentage);
    }

    function addSupportedNFTContract(address _nftContractAddress) external onlyAdmin {
        supportedNFTContracts[_nftContractAddress] = true;
    }

    function removeSupportedNFTContract(address _nftContractAddress) external onlyAdmin {
        delete supportedNFTContracts[_nftContractAddress];
    }

    function withdrawFees() external onlyAdmin {
        uint256 balance = address(this).balance;
        payable(feeRecipient).transfer(balance);
        emit FeesWithdrawn(balance, feeRecipient);
    }

    function pauseMarketplace() external onlyAdmin {
        paused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() external onlyAdmin {
        paused = false;
        emit MarketplaceUnpaused();
    }


    // --- Core Marketplace Functions ---
    function listNFT(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _price,
        ListingType _listingType,
        bool _isDynamicNFT
    ) external notPaused onlySupportedNFTContract(_nftContractAddress) {
        // Assuming the NFT contract has a method to check ownership (e.g., ownerOf)
        // and approval for this marketplace contract to transfer (e.g., getApproved or isApprovedForAll)
        // In a real implementation, you would interact with the NFT contract to verify this.
        // For simplicity in this example, we skip detailed NFT ownership/approval checks.
        // **Important: In a production contract, these checks are crucial for security!**

        listingIdCounter++;
        uint256 currentListingId = listingIdCounter;

        listings[currentListingId] = Listing({
            listingId: currentListingId,
            nftContractAddress: _nftContractAddress,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            listingType: _listingType,
            status: ListingStatus.Active,
            endTime: 0, // Set for auction if applicable
            isDynamicNFT: _isDynamicNFT,
            curationScore: 0, // Initially 0, can be updated later
            isFractionalized: false
        });
        nftToListingId[_nftContractAddress][_tokenId] = currentListingId;

        emit NFTListed(currentListingId, _nftContractAddress, _tokenId, msg.sender, _price, _listingType);
    }

    function delistNFT(uint256 _listingId) external notPaused listingExists(_listingId) onlyListingSeller(_listingId) {
        require(listings[_listingId].status == ListingStatus.Active, "NFT is not actively listed.");
        listings[_listingId].status = ListingStatus.Cancelled;
        emit NFTDelisted(_listingId, listings[_listingId].tokenId, msg.sender);
    }

    function buyNFT(uint256 _listingId) external payable notPaused listingExists(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.status == ListingStatus.Active, "NFT is not actively listed.");
        require(listing.listingType == ListingType.FixedPrice, "NFT is not listed for fixed price.");
        require(msg.value >= listing.price, "Insufficient funds sent.");

        // **Important: In a production contract, implement secure NFT transfer logic.**
        // Example (assuming ERC721 `safeTransferFrom`):
        // IERC721(listing.nftContractAddress).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);
        // **Add proper error handling and checks for transfer success.**

        listing.status = ListingStatus.Sold;
        listing.seller.transfer(listing.price); // Transfer price to seller

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;
        payable(listing.seller).transfer(sellerProceeds); // Transfer proceeds to seller (minus fee)
        if (marketplaceFee > 0) {
            payable(feeRecipient).transfer(marketplaceFee); // Transfer marketplace fee
        }

        emit NFTSold(_listingId, listing.tokenId, listing.seller, msg.sender, listing.price);

        // Refund any extra amount sent
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }

    function makeOffer(uint256 _listingId) external payable notPaused listingExists(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.status == ListingStatus.Active, "NFT is not actively listed.");
        require(msg.value >= _getOfferMinimumPrice(_listingId), "Offer price too low."); // Example minimum offer logic

        offerIdCounter++;
        uint256 currentOfferId = offerIdCounter;

        offers[currentOfferId] = Offer({
            offerId: currentOfferId,
            listingId: _listingId,
            buyer: msg.sender,
            price: msg.value,
            status: OfferStatus.Pending,
            timestamp: block.timestamp
        });
        listingOffers[_listingId].push(offers[currentOfferId]);

        emit OfferMade(currentOfferId, _listingId, msg.sender, msg.value);
    }

    function acceptOffer(uint256 _offerId) external notPaused offerExists(_offerId) listingExists(offers[_offerId].listingId) onlyListingSeller(offers[_offerId].listingId) {
        Offer storage offer = offers[_offerId];
        Listing storage listing = listings[offer.listingId];
        require(offer.status == OfferStatus.Pending, "Offer is not pending.");
        require(listing.status == ListingStatus.Active, "Listing is not active.");

        // **Important: Implement secure NFT transfer logic here, similar to buyNFT().**

        listing.status = ListingStatus.Sold;
        offer.status = OfferStatus.Accepted;

        uint256 marketplaceFee = (offer.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = offer.price - marketplaceFee;
        payable(listing.seller).transfer(sellerProceeds); // Transfer proceeds to seller (minus fee)
        if (marketplaceFee > 0) {
            payable(feeRecipient).transfer(marketplaceFee); // Transfer marketplace fee
        }

        emit OfferAccepted(_offerId, offer.listingId, listing.seller, offer.buyer, offer.price);

        // Transfer NFT to buyer (implementation needed - see buyNFT comment)
        // ... NFT Transfer logic ...

        // Refund pending offers (optional - depends on marketplace design)
        _refundPendingOffers(offer.listingId, _offerId);
    }

    function cancelOffer(uint256 _offerId) external notPaused offerExists(_offerId) {
        Offer storage offer = offers[_offerId];
        require(offer.buyer == msg.sender, "Only offer buyer can cancel.");
        require(offer.status == OfferStatus.Pending, "Offer is not pending.");

        offer.status = OfferStatus.Cancelled;
        payable(msg.sender).transfer(offer.price); // Refund offer amount
        emit OfferCancelled(_offerId, offer.listingId, msg.sender);
    }

    // --- Dynamic NFT and Curation Functions ---
    function setDynamicNFTAttribute(uint256 _listingId, string memory _attributeName, string memory _attributeValue) external notPaused listingExists(_listingId) onlyListingSeller(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.isDynamicNFT, "NFT is not marked as dynamic.");
        // **In a real implementation, you would potentially interact with the NFT contract
        // to update metadata or trigger dynamic updates based on _attributeName and _attributeValue.**
        // This part is highly dependent on the specific dynamic NFT contract implementation.

        emit DynamicNFTAttributeSet(_listingId, _attributeName, _attributeValue);
    }

    function requestAICurationScore(uint256 _listingId) external payable notPaused listingExists(_listingId) {
        require(msg.value >= curationRequestFee, "Insufficient curation request fee.");
        // **In a real implementation, you would interact with an external AI Oracle (off-chain)
        // or a separate on-chain contract to trigger the AI curation process.**
        // This example simulates a basic request.

        emit AICurationScoreRequested(_listingId, msg.sender);
        payable(aiOracleAddress).transfer(curationRequestFee); // Transfer fee to oracle (example)
    }

    function setCurationScore(uint256 _listingId, uint256 _curationScore) external onlyOracle listingExists(_listingId) {
        listings[_listingId].curationScore = _curationScore;
        emit CurationScoreSet(_listingId, _curationScore, msg.sender);
    }

    function getNFTCurationScore(uint256 _listingId) external view listingExists(_listingId) returns (uint256) {
        return listings[_listingId].curationScore;
    }

    function updateNFTMetadata(uint256 _listingId, string memory _newMetadataURI) external notPaused listingExists(_listingId) onlyListingSeller(_listingId) {
        Listing storage listing = listings[_listingId];
        // **In a real implementation, you would interact with the NFT contract (if it supports metadata updates)
        // to update the metadata URI. This is highly dependent on the NFT contract implementation.**
        // For example, some NFTs might have an `updateMetadataURI` function.

        emit NFTMetadataUpdated(_listingId, _newMetadataURI);
    }

    // --- Fractional Ownership Functions ---
    function fractionalizeNFT(uint256 _listingId, uint256 _fractionTokenSupply, string memory _fractionTokenName, string memory _fractionTokenSymbol) external notPaused listingExists(_listingId) onlyListingSeller(_listingId) {
        Listing storage listing = listings[_listingId];
        require(!listing.isFractionalized, "NFT is already fractionalized.");
        require(_fractionTokenSupply > 0, "Fraction supply must be positive.");
        require(bytes(_fractionTokenName).length > 0 && bytes(_fractionTokenSymbol).length > 0, "Invalid token name or symbol.");

        // **Complex Implementation Required:**
        // 1. Deploy a new ERC20 token contract specifically for these fractions.
        //    - In a real system, you might use a factory pattern for deploying fraction tokens.
        // 2. Mint _fractionTokenSupply tokens to the NFT owner.
        // 3. Mark the listing as fractionalized and store the fraction token contract address.
        // 4. Potentially lock the original NFT in a vault contract associated with the fraction token.

        // **Simplified Placeholder - In a real contract, this would be much more involved.**
        address dummyFractionTokenContract = address(0x123); // Replace with actual deployment logic
        fractionDetails[_listingId] = FractionDetails({
            isFractionalized: true,
            fractionTokenSupply: _fractionTokenSupply,
            fractionTokenContract: dummyFractionTokenContract // Placeholder
        });
        listing.isFractionalized = true;

        emit NFTFractionalized(_listingId, dummyFractionTokenContract, _fractionTokenSupply);
    }

    function buyFraction(uint256 _listingId, uint256 _fractionAmount) external payable notPaused listingExists(_listingId) {
        Listing storage listing = listings[_listingId];
        FractionDetails storage fractions = fractionDetails[_listingId];
        require(listing.isFractionalized, "NFT is not fractionalized.");
        require(fractions.fractionTokenContract != address(0), "Fraction token contract not set."); // Check if fraction contract exists (placeholder check)
        require(_fractionAmount > 0, "Fraction amount must be positive.");

        // **Implementation Required:**
        // 1. Determine fraction price (e.g., based on listing price and fraction supply).
        // 2. Transfer funds from buyer to seller (or vault).
        // 3. Transfer _fractionAmount of ERC20 fraction tokens from seller (or vault) to buyer.

        uint256 fractionPrice = _getFractionPrice(_listingId, _fractionAmount); // Example fraction price calculation
        require(msg.value >= fractionPrice, "Insufficient funds for fraction purchase.");

        // **Simplified Placeholder - Fraction token transfer logic needed.**
        // In a real implementation, interact with the fraction ERC20 token contract to transfer tokens.

        payable(listing.seller).transfer(fractionPrice); // Transfer funds to seller (placeholder)

        emit FractionBought(_listingId, msg.sender, _fractionAmount, fractionPrice);

        // Refund extra funds
        if (msg.value > fractionPrice) {
            payable(msg.sender).transfer(msg.value - fractionPrice);
        }
    }

    function getFractionDetails(uint256 _listingId) external view listingExists(_listingId) returns (FractionDetails memory) {
        return fractionDetails[_listingId];
    }


    // --- Governance and Utility Functions (Conceptual - Basic Example) ---
    // **Note: This is a very basic governance example. A robust governance system requires more complex logic and potentially external contracts/DAOs.**

    uint256 public proposalIdCounter;
    struct Proposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        // Add parameters for the change being proposed (e.g., new fee, new supported contract)
        // For simplicity, this example only handles fee changes.
        uint256 newFeePercentageProposal;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVotingDuration = 7 days; // Example voting duration


    function proposeMarketplaceChange(string memory _description, uint256 _newFeePercentage) external notPaused {
        // **In a real governance system, you would check if the proposer holds governance tokens.**
        require(_newFeePercentage <= 100, "Proposed fee percentage cannot exceed 100%.");

        proposalIdCounter++;
        uint256 currentProposalId = proposalIdCounter;

        proposals[currentProposalId] = Proposal({
            proposalId: currentProposalId,
            description: _description,
            proposer: msg.sender,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            newFeePercentageProposal: _newFeePercentage
        });

        emit ProposalCreated(currentProposalId, _description, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external notPaused {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        require(block.timestamp >= proposals[_proposalId].votingStartTime && block.timestamp <= proposals[_proposalId].votingEndTime, "Voting period is not active.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        // **In a real governance system, voting power would be determined by governance token holdings.**
        // For simplicity, this example assumes each address has 1 vote.

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }

        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external onlyAdmin notPaused {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        require(block.timestamp > proposals[_proposalId].votingEndTime, "Voting period is still active.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast."); // Prevent division by zero
        uint256 quorum = (totalVotes * 50) / 100; // Example: 50% quorum
        require(proposals[_proposalId].votesFor > quorum, "Proposal did not reach quorum.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal failed to pass.");

        // Execute the proposal - in this example, only fee changes are handled
        marketplaceFeePercentage = proposals[_proposalId].newFeePercentageProposal;
        emit MarketplaceFeeSet(marketplaceFeePercentage);

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user]; // Placeholder - actual reputation calculation needed
    }


    // --- Internal Helper Functions ---
    function _getOfferMinimumPrice(uint256 _listingId) internal view listingExists(_listingId) returns (uint256) {
        // Example: Minimum offer price is 80% of the listing price (or current highest offer)
        Listing storage listing = listings[_listingId];
        uint256 minPrice = (listing.price * 80) / 100;
        if (listingOffers[_listingId].length > 0) {
            uint256 highestOffer = 0;
            for (uint256 i = 0; i < listingOffers[_listingId].length; i++) {
                if (listingOffers[_listingId][i].price > highestOffer) {
                    highestOffer = listingOffers[_listingId][i].price;
                }
            }
            minPrice = max(minPrice, highestOffer);
        }
        return minPrice;
    }

    function _refundPendingOffers(uint256 _listingId, uint256 _acceptedOfferId) internal {
        for (uint256 i = 0; i < listingOffers[_listingId].length; i++) {
            Offer storage offer = listingOffers[_listingId][i];
            if (offer.status == OfferStatus.Pending && offer.offerId != _acceptedOfferId) {
                offer.status = OfferStatus.Rejected;
                payable(offer.buyer).transfer(offer.price); // Refund rejected offer
                emit OfferCancelled(offer.offerId, offer.listingId, offer.buyer); // Use OfferCancelled event for refunds
            }
        }
    }

    function _getFractionPrice(uint256 _listingId, uint256 _fractionAmount) internal view listingExists(_listingId) returns (uint256) {
        Listing storage listing = listings[_listingId];
        FractionDetails storage fractions = fractionDetails[_listingId];
        require(listing.isFractionalized, "NFT is not fractionalized.");
        require(fractions.fractionTokenSupply > 0, "Fraction supply is zero.");

        // Example: Fraction price is proportional to the listing price and fraction supply
        return (listing.price * _fractionAmount) / fractions.fractionTokenSupply;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
```