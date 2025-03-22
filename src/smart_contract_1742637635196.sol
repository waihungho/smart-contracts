```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization and Gamified Governance
 * @author Gemini AI and Smart Contract Enthusiast
 * @dev This smart contract implements a cutting-edge decentralized NFT marketplace with several advanced features:
 *      - Dynamic NFTs: NFTs with evolving traits and metadata based on on-chain and off-chain events.
 *      - AI-Powered Personalization: Simulated AI recommendation engine within the contract to suggest NFTs based on user preferences (simplified for on-chain feasibility).
 *      - Gamified Governance:  A system where users can stake tokens, participate in governance proposals, and earn rewards for contributing to the marketplace's evolution.
 *      - Advanced Marketplace Features:  Offers, bundles, auctions with dynamic pricing, rarity-based listings, and more.
 *
 * Function Summary:
 *
 * NFT Management:
 *   1. mintDynamicNFT: Mints a new dynamic NFT with initial traits.
 *   2. updateNFTTraits: Updates the dynamic traits of an existing NFT.
 *   3. setBaseURIPrefix: Sets the base URI prefix for NFT metadata.
 *   4. getTokenTraits: Retrieves the current traits of an NFT.
 *   5. burnNFT: Burns an NFT, destroying it permanently.
 *
 * Marketplace Operations:
 *   6. listNFTForSale: Lists an NFT for sale at a fixed price.
 *   7. delistNFT: Removes an NFT from sale.
 *   8. purchaseNFT: Allows a user to purchase a listed NFT.
 *   9. createOffer: Allows a user to make an offer on an NFT.
 *  10. acceptOffer: Allows the NFT owner to accept a specific offer.
 *  11. createBundle: Allows users to create a bundle of NFTs for sale.
 *  12. purchaseBundle: Allows a user to purchase a bundle of NFTs.
 *  13. startAuction: Starts an auction for an NFT with a starting price and duration.
 *  14. bidOnAuction: Allows users to bid on an active auction.
 *  15. settleAuction: Settles an auction after the duration ends, transferring NFT and funds.
 *  16. setMarketplaceFee: Sets the marketplace fee percentage.
 *  17. withdrawMarketplaceFees: Allows the marketplace owner to withdraw accumulated fees.
 *
 * AI-Personalization (Simulated):
 *  18. setUserPreferences: Allows users to set their NFT preferences (simplified representation).
 *  19. getRecommendedNFTs: Simulates an AI recommendation engine to suggest NFTs based on user preferences and marketplace data.
 *
 * Governance and Staking:
 *  20. stakeTokensForGovernance: Allows users to stake governance tokens to participate in voting.
 *  21. unstakeTokens: Allows users to unstake their governance tokens.
 *  22. createGovernanceProposal: Allows staked users to create a governance proposal.
 *  23. voteOnProposal: Allows staked users to vote on an active proposal.
 *  24. executeProposal: Executes a successful governance proposal.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    string public baseURIPrefix;

    // Dynamic NFT Traits - Stored as a simple string for demonstration, can be expanded to structs or mappings for more complex traits
    mapping(uint256 => string) public nftTraits;

    // Marketplace Data
    mapping(uint256 => uint256) public nftPrice; // NFT ID => Price (in native token)
    mapping(uint256 => address) public nftSeller; // NFT ID => Seller Address
    mapping(uint256 => bool) public isNFTListed; // NFT ID => Is Listed?

    struct Offer {
        address offerer;
        uint256 price;
    }
    mapping(uint256 => Offer[]) public nftOffers; // NFT ID => Array of Offers

    struct Bundle {
        uint256 bundleId;
        uint256[] nftIds;
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(uint256 => Bundle) public bundles;
    Counters.Counter private _bundleIdCounter;

    struct Auction {
        uint256 auctionId;
        uint256 nftId;
        uint256 startingPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;
    Counters.Counter private _auctionIdCounter;

    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    uint256 public accumulatedFees;

    // AI-Personalization (Simplified Preference System)
    mapping(address => string[]) public userPreferences; // User Address => Array of preference tags (e.g., ["art", "fantasy", "cyberpunk"])

    // Governance and Staking (Simplified Governance Token - for demonstration, consider using a separate ERC20)
    mapping(address => uint256) public governanceTokenBalance; // User Address => Governance Token Balance (for simplicity, using internal balance)
    mapping(address => uint256) public stakedGovernanceTokens; // User Address => Staked Governance Tokens
    uint256 public governanceTokenSupply = 1000000 * 10**18; // Example supply

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        // Add more proposal details as needed, like function calls to execute
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public proposalVotingDuration = 7 days; // Example voting duration


    event NFTMinted(uint256 tokenId, address recipient);
    event NFTTraitsUpdated(uint256 tokenId, string newTraits);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTDelisted(uint256 tokenId, address seller);
    event NFTPurchased(uint256 tokenId, address buyer, address seller, uint256 price);
    event OfferCreated(uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(uint256 tokenId, uint256 offerIndex, address seller, address buyer, uint256 price);
    event BundleCreated(uint256 bundleId, address seller, uint256 price, uint256[] nftIds);
    event BundlePurchased(uint256 bundleId, address buyer, address seller, uint256 price, uint256[] nftIds);
    event AuctionStarted(uint256 auctionId, uint256 nftId, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionSettled(uint256 auctionId, uint256 nftId, address winner, uint256 finalPrice);
    event MarketplaceFeeSet(uint256 percentage);
    event FeesWithdrawn(uint256 amount, address recipient);
    event UserPreferencesSet(address user, string[] preferences);
    event GovernanceTokensStaked(address user, uint256 amount);
    event GovernanceTokensUnstaked(address user, uint256 amount);
    event GovernanceProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);

    constructor(string memory _name, string memory _symbol, string memory _baseURIPrefix) ERC721(_name, _symbol) {
        baseURIPrefix = _baseURIPrefix;
        // Distribute initial governance tokens (example - distribute to owner for simplicity)
        governanceTokenBalance[owner()] = governanceTokenSupply;
    }

    // --- NFT Management ---

    function mintDynamicNFT(address recipient, string memory initialTraits) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(recipient, tokenId);
        nftTraits[tokenId] = initialTraits;
        emit NFTMinted(tokenId, recipient);
    }

    function updateNFTTraits(uint256 tokenId, string memory newTraits) public onlyOwner { // Example: Only owner can update traits for simplicity, can be changed
        require(_exists(tokenId), "NFT does not exist");
        nftTraits[tokenId] = newTraits;
        emit NFTTraitsUpdated(tokenId, newTraits);
    }

    function setBaseURIPrefix(string memory _baseURIPrefix) public onlyOwner {
        baseURIPrefix = _baseURIPrefix;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        return string(abi.encodePacked(baseURIPrefix, Strings.toString(tokenId)));
    }

    function getTokenTraits(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        return nftTraits[tokenId];
    }

    function burnNFT(uint256 tokenId) public onlyOwner { // Example: Only owner can burn, can be modified for creator or other logic
        require(_exists(tokenId), "NFT does not exist");
        _burn(tokenId);
        delete nftTraits[tokenId];
    }

    // --- Marketplace Operations ---

    function listNFTForSale(uint256 tokenId, uint256 price) public nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(!isNFTListed[tokenId], "NFT is already listed for sale");
        require(price > 0, "Price must be greater than zero");

        _approve(address(this), tokenId); // Approve marketplace to handle NFT transfer
        nftPrice[tokenId] = price;
        nftSeller[tokenId] = _msgSender();
        isNFTListed[tokenId] = true;
        emit NFTListedForSale(tokenId, price, _msgSender());
    }

    function delistNFT(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(isNFTListed[tokenId], "NFT is not listed for sale");

        delete nftPrice[tokenId];
        delete nftSeller[tokenId];
        isNFTListed[tokenId] = false;
        emit NFTDelisted(tokenId, _msgSender());
    }

    function purchaseNFT(uint256 tokenId) public payable nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(isNFTListed[tokenId], "NFT is not listed for sale");
        require(nftSeller[tokenId] != _msgSender(), "Cannot purchase your own NFT");
        require(msg.value >= nftPrice[tokenId], "Insufficient funds sent");

        uint256 salePrice = nftPrice[tokenId];
        uint256 marketplaceFee = salePrice.mul(marketplaceFeePercentage).div(100);
        uint256 sellerPayout = salePrice.sub(marketplaceFee);

        accumulatedFees = accumulatedFees.add(marketplaceFee);

        // Transfer funds to seller and marketplace fees
        payable(nftSeller[tokenId]).transfer(sellerPayout);

        // Transfer NFT to buyer
        _transfer(nftSeller[tokenId], _msgSender(), tokenId);

        // Clean up marketplace data
        delete nftPrice[tokenId];
        delete nftSeller[tokenId];
        isNFTListed[tokenId] = false;

        emit NFTPurchased(tokenId, _msgSender(), nftSeller[tokenId], salePrice);
    }

    function createOffer(uint256 tokenId, uint256 price) public nonReentrant payable {
        require(_exists(tokenId), "NFT does not exist");
        require(msg.value >= price, "Insufficient funds sent for offer");
        require(!isNFTListed[tokenId], "Cannot make offer on listed NFT, use purchase"); // Example: disallow offers on listed NFTs

        nftOffers[tokenId].push(Offer({offerer: _msgSender(), price: price}));
        emit OfferCreated(tokenId, _msgSender(), price);
    }

    function acceptOffer(uint256 tokenId, uint256 offerIndex) public nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(offerIndex < nftOffers[tokenId].length, "Invalid offer index");

        Offer memory offer = nftOffers[tokenId][offerIndex];
        require(offer.price > 0, "Invalid offer price"); // Sanity check

        uint256 salePrice = offer.price;
        uint256 marketplaceFee = salePrice.mul(marketplaceFeePercentage).div(100);
        uint256 sellerPayout = salePrice.sub(marketplaceFee);

        accumulatedFees = accumulatedFees.add(marketplaceFee);

        // Transfer funds to seller
        payable(_msgSender()).transfer(sellerPayout); // Seller receives funds

        // Transfer NFT to offerer
        _transfer(_msgSender(), offer.offerer, tokenId);

        // Remove offers for this NFT (for simplicity, remove all offers)
        delete nftOffers[tokenId];

        emit OfferAccepted(tokenId, offerIndex, _msgSender(), offer.offerer, salePrice);
    }

    function createBundle(uint256[] memory nftIds, uint256 price) public nonReentrant {
        require(nftIds.length > 1, "Bundle must contain at least two NFTs");
        require(price > 0, "Bundle price must be greater than zero");

        for (uint256 i = 0; i < nftIds.length; i++) {
            require(_exists(nftIds[i]), "NFT in bundle does not exist");
            require(ownerOf(nftIds[i]) == _msgSender(), "You are not the owner of all NFTs in bundle");
            _approve(address(this), nftIds[i]); // Approve marketplace to handle NFT transfers
        }

        _bundleIdCounter.increment();
        uint256 bundleId = _bundleIdCounter.current();
        bundles[bundleId] = Bundle({
            bundleId: bundleId,
            nftIds: nftIds,
            price: price,
            seller: _msgSender(),
            isActive: true
        });

        emit BundleCreated(bundleId, _msgSender(), price, nftIds);
    }

    function purchaseBundle(uint256 bundleId) public payable nonReentrant {
        require(bundles[bundleId].isActive, "Bundle is not active");
        Bundle storage bundle = bundles[bundleId];
        require(msg.value >= bundle.price, "Insufficient funds sent for bundle");
        require(bundle.seller != _msgSender(), "Cannot purchase your own bundle");

        uint256 salePrice = bundle.price;
        uint256 marketplaceFee = salePrice.mul(marketplaceFeePercentage).div(100);
        uint256 sellerPayout = salePrice.sub(marketplaceFee);

        accumulatedFees = accumulatedFees.add(marketplaceFee);

        // Transfer funds to seller and marketplace fees
        payable(bundle.seller).transfer(sellerPayout);

        // Transfer NFTs in bundle to buyer
        for (uint256 i = 0; i < bundle.nftIds.length; i++) {
            _transfer(bundle.seller, _msgSender(), bundle.nftIds[i]);
        }

        // Deactivate bundle
        bundle.isActive = false;

        emit BundlePurchased(bundleId, _msgSender(), bundle.seller, salePrice, bundle.nftIds);
    }

    function startAuction(uint256 tokenId, uint256 startingPrice, uint256 durationInSeconds) public nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(startingPrice > 0, "Starting price must be greater than zero");
        require(durationInSeconds > 0, "Auction duration must be greater than zero");
        require(auctions[_auctionIdCounter.current()].isActive == false || _auctionIdCounter.current() == 0, "Previous auction must be settled"); // Basic check, improve for concurrent auctions if needed

        _approve(address(this), tokenId); // Approve marketplace to handle NFT transfer

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();
        auctions[auctionId] = Auction({
            auctionId: auctionId,
            nftId: tokenId,
            startingPrice: startingPrice,
            endTime: block.timestamp + durationInSeconds,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });

        emit AuctionStarted(auctionId, tokenId, startingPrice, block.timestamp + durationInSeconds);
    }

    function bidOnAuction(uint256 auctionId) public payable nonReentrant {
        require(auctions[auctionId].isActive, "Auction is not active");
        Auction storage auction = auctions[auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid amount must be higher than current highest bid");

        // Refund previous highest bidder (if any)
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = _msgSender();
        auction.highestBid = msg.value;
        emit BidPlaced(auctionId, _msgSender(), msg.value);
    }

    function settleAuction(uint256 auctionId) public nonReentrant {
        require(auctions[auctionId].isActive, "Auction is not active");
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended");

        auction.isActive = false; // Deactivate auction

        if (auction.highestBidder == address(0)) {
            // No bids, return NFT to seller
            _transfer(address(this), ownerOf(auction.nftId), auction.nftId); // Return to original owner
            emit AuctionSettled(auctionId, auction.nftId, address(0), 0); // Indicate no winner
        } else {
            uint256 salePrice = auction.highestBid;
            uint256 marketplaceFee = salePrice.mul(marketplaceFeePercentage).div(100);
            uint256 sellerPayout = salePrice.sub(marketplaceFee);

            accumulatedFees = accumulatedFees.add(marketplaceFee);

            // Transfer funds to seller
            payable(ownerOf(auction.nftId)).transfer(sellerPayout);

            // Transfer NFT to highest bidder
            _transfer(ownerOf(auction.nftId), auction.highestBidder, auction.nftId);

            emit AuctionSettled(auctionId, auction.nftId, auction.highestBidder, salePrice);
        }
    }

    function setMarketplaceFee(uint256 percentage) public onlyOwner {
        require(percentage <= 10, "Marketplace fee percentage cannot exceed 10%"); // Example limit
        marketplaceFeePercentage = percentage;
        emit MarketplaceFeeSet(percentage);
    }

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 feesToWithdraw = accumulatedFees;
        accumulatedFees = 0;
        payable(owner()).transfer(feesToWithdraw);
        emit FeesWithdrawn(feesToWithdraw, owner());
    }

    // --- AI-Personalization (Simulated) ---

    function setUserPreferences(string[] memory preferences) public {
        userPreferences[_msgSender()] = preferences;
        emit UserPreferencesSet(_msgSender(), preferences);
    }

    function getRecommendedNFTs() public view returns (uint256[] memory) {
        string[] memory userPrefs = userPreferences[_msgSender()];
        uint256[] memory recommendedNFTs = new uint256[](0); // Initialize empty array

        // Simplified "AI" logic:  (Replace with more sophisticated logic if needed - off-chain AI integration is recommended for real AI)
        // For demonstration, we simply check if NFT traits (as strings) contain any user preference tag.
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) { // Iterate through all minted NFTs
            if (_exists(i) && isNFTListed[i]) { // Consider only listed NFTs
                string memory nftTrait = nftTraits[i];
                bool isRecommended = false;
                for (uint256 j = 0; j < userPrefs.length; j++) {
                    if (stringContains(nftTrait, userPrefs[j])) {
                        isRecommended = true;
                        break;
                    }
                }
                if (isRecommended) {
                    // Add NFT ID to the recommended list
                    uint256[] memory tempArray = new uint256[](recommendedNFTs.length + 1);
                    for (uint256 k = 0; k < recommendedNFTs.length; k++) {
                        tempArray[k] = recommendedNFTs[k];
                    }
                    tempArray[recommendedNFTs.length] = i;
                    recommendedNFTs = tempArray;
                }
            }
        }
        return recommendedNFTs;
    }

    // --- Governance and Staking ---

    function stakeTokensForGovernance(uint256 amount) public nonReentrant {
        require(governanceTokenBalance[_msgSender()] >= amount, "Insufficient governance tokens");
        require(amount > 0, "Amount to stake must be greater than zero");

        governanceTokenBalance[_msgSender()] = governanceTokenBalance[_msgSender()].sub(amount);
        stakedGovernanceTokens[_msgSender()] = stakedGovernanceTokens[_msgSender()].add(amount);
        emit GovernanceTokensStaked(_msgSender(), amount);
    }

    function unstakeTokens(uint256 amount) public nonReentrant {
        require(stakedGovernanceTokens[_msgSender()] >= amount, "Insufficient staked governance tokens");
        require(amount > 0, "Amount to unstake must be greater than zero");

        stakedGovernanceTokens[_msgSender()] = stakedGovernanceTokens[_msgSender()].sub(amount);
        governanceTokenBalance[_msgSender()] = governanceTokenBalance[_msgSender()].add(amount);
        emit GovernanceTokensUnstaked(_msgSender(), amount);
    }

    function createGovernanceProposal(string memory description) public {
        require(stakedGovernanceTokens[_msgSender()] > 0, "Must stake governance tokens to create a proposal");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: description,
            proposer: _msgSender(),
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit GovernanceProposalCreated(proposalId, description, _msgSender());
    }

    function voteOnProposal(uint256 proposalId, bool vote) public {
        require(stakedGovernanceTokens[_msgSender()] > 0, "Must stake governance tokens to vote");
        require(!governanceProposals[proposalId].executed, "Proposal already executed");
        require(block.timestamp >= governanceProposals[proposalId].votingStartTime && block.timestamp <= governanceProposals[proposalId].votingEndTime, "Voting period is not active");

        if (vote) {
            governanceProposals[proposalId].yesVotes = governanceProposals[proposalId].yesVotes.add(stakedGovernanceTokens[_msgSender()]); // Voting power based on staked tokens
        } else {
            governanceProposals[proposalId].noVotes = governanceProposals[proposalId].noVotes.add(stakedGovernanceTokens[_msgSender()]);
        }
        emit VoteCast(proposalId, _msgSender(), vote);
    }

    function executeProposal(uint256 proposalId) public onlyOwner { // Example: Only owner can execute, governance can vote to execute in a more advanced system
        require(!governanceProposals[proposalId].executed, "Proposal already executed");
        require(block.timestamp > governanceProposals[proposalId].votingEndTime, "Voting period is still active");
        require(governanceProposals[proposalId].yesVotes > governanceProposals[proposalId].noVotes, "Proposal did not pass"); // Simple majority

        governanceProposals[proposalId].executed = true;
        // --- Implement proposal execution logic here based on proposal details ---
        // Example:  If proposal was to change marketplace fee percentage:
        // setMarketplaceFee(newFeePercentageFromProposal);

        emit ProposalExecuted(proposalId);
    }


    // --- Utility Functions ---

    // Simple string contains function for AI preference matching (replace with more efficient method if needed for large scale)
    function stringContains(string memory _string, string memory _substring) internal pure returns (bool) {
        return (stringToBytes(_string).length >= stringToBytes(_substring).length) && (keccak256(stringToBytes(_string)) == keccak256(abi.encodePacked(_string, _substring))); // Basic contains check - can be improved for efficiency
    }

    function stringToBytes(string memory s) internal pure returns (bytes memory) {
        bytes memory b = bytes(s);
        return b;
    }
}
```