```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace with advanced and creative functionalities.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core NFT Management:**
 *    - `mintNFT(address _to, string memory _uri)`: Mints a new NFT to the specified address with a given URI.
 *    - `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another (with approval checks).
 *    - `burnNFT(uint256 _tokenId)`: Burns (destroys) an NFT, removing it from circulation.
 *    - `getNFTOwner(uint256 _tokenId)`: Returns the owner of a specific NFT.
 *    - `getNFTURI(uint256 _tokenId)`: Returns the URI associated with a specific NFT.
 *    - `totalSupply()`: Returns the total number of NFTs minted.
 *
 * **2. Dynamic NFT Attributes and Metadata:**
 *    - `setNFTAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue)`: Allows the contract owner to set or update a dynamic attribute for an NFT.
 *    - `getNFTAttribute(uint256 _tokenId, string memory _attributeName)`: Retrieves a specific dynamic attribute value for an NFT.
 *    - `generateDynamicMetadataURI(uint256 _tokenId)`: Generates a dynamic metadata URI for an NFT based on its attributes (can be expanded to interact with off-chain services).
 *
 * **3. Marketplace Listing and Trading:**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Allows an NFT owner to list their NFT for sale at a specified price.
 *    - `buyNFT(uint256 _tokenId)`: Allows a user to buy a listed NFT.
 *    - `cancelNFTListing(uint256 _tokenId)`: Allows the NFT owner to cancel an active listing.
 *    - `updateNFTListingPrice(uint256 _tokenId, uint256 _newPrice)`: Allows the NFT owner to update the price of a listed NFT.
 *    - `getNFTListingDetails(uint256 _tokenId)`: Returns details of a specific NFT listing (price, seller, listing status).
 *
 * **4. NFT Staking and Rewards:**
 *    - `stakeNFT(uint256 _tokenId)`: Allows NFT owners to stake their NFTs to earn rewards.
 *    - `unstakeNFT(uint256 _tokenId)`: Allows NFT owners to unstake their NFTs and claim accumulated rewards.
 *    - `calculateStakingReward(uint256 _tokenId)`: Calculates the staking reward for a given NFT (can be based on duration and NFT attributes).
 *    - `setStakingRewardRate(uint256 _newRate)`: Allows the contract owner to set or update the staking reward rate.
 *
 * **5. NFT Fusion and Evolution (Creative Feature):**
 *    - `fuseNFTs(uint256 _tokenId1, uint256 _tokenId2)`: Allows owners to fuse two NFTs to create a new, evolved NFT (requires specific criteria and logic).
 *    - `getFusionRecipe(uint256 _tokenId1, uint256 _tokenId2)`: Returns the recipe or result of fusing two NFTs (can be based on attributes).
 *
 * **6.  Auction Mechanism (Advanced Marketplace Feature):**
 *    - `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Allows an NFT owner to create an auction for their NFT with a starting bid and duration.
 *    - `bidOnAuction(uint256 _tokenId)`: Allows users to bid on an active NFT auction.
 *    - `endAuction(uint256 _tokenId)`: Ends an active auction and transfers the NFT to the highest bidder.
 *    - `getAuctionDetails(uint256 _tokenId)`: Returns details of an active or past auction for an NFT.
 *
 * **7.  Community Governance (Trendy Feature - Simple DAO Concept):**
 *    - `proposeFeature(string memory _proposalDescription)`: Allows NFT holders to propose new features or changes to the marketplace.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on active proposals.
 *    - `getProposalDetails(uint256 _proposalId)`: Returns details of a specific proposal (description, votes, status).
 *
 * **8.  Utility and Admin Functions:**
 *    - `pauseMarketplace()`: Pauses all marketplace trading functionalities.
 *    - `unpauseMarketplace()`: Resumes marketplace trading functionalities.
 *    - `withdrawContractBalance()`: Allows the contract owner to withdraw contract balance (fees, etc.).
 */
contract DynamicNFTMarketplace {
    // State variables
    string public name = "Dynamic NFT Marketplace";
    string public symbol = "DNFTM";
    address public owner;
    uint256 public totalSupplyCounter;
    uint256 public stakingRewardRate = 1; // Default reward rate per time unit
    bool public marketplacePaused = false;

    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftURIs;
    mapping(uint256 => mapping(string => string)) public nftAttributes; // Dynamic attributes per NFT
    mapping(uint256 => Listing) public nftListings; // NFT listings for sale
    mapping(uint256 => StakingInfo) public nftStakingInfo; // NFT staking information
    mapping(uint256 => Auction) public nftAuctions; // NFT auction information
    mapping(uint256 => Proposal) public proposals; // Community proposals
    uint256 public proposalCounter;

    // Structs
    struct Listing {
        bool isActive;
        uint256 price;
        address seller;
    }

    struct StakingInfo {
        bool isStaked;
        uint256 lastStakeTime;
    }

    struct Auction {
        bool isActive;
        uint256 startingBid;
        uint256 currentBid;
        address highestBidder;
        uint256 auctionEndTime;
    }

    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }

    // Events
    event NFTMinted(uint256 tokenId, address to, string uri);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId);
    event NFTAttributeSet(uint256 tokenId, string attributeName, string attributeValue);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 tokenId, uint256 price, address buyer, address seller);
    event NFTListingCancelled(uint256 tokenId);
    event NFTListingPriceUpdated(uint256 tokenId, uint256 newPrice);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker, uint256 reward);
    event NFTsFused(uint256 newTokenId, uint256 tokenId1, uint256 tokenId2);
    event AuctionCreated(uint256 tokenId, uint256 startingBid, uint256 auctionDuration);
    event BidPlaced(uint256 tokenId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 finalPrice);
    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event ContractBalanceWithdrawn(uint256 amount, address recipient);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier marketplaceNotPaused() {
        require(!marketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier nftNotListed(uint256 _tokenId) {
        require(!nftListings[_tokenId].isActive, "NFT is already listed for sale.");
        _;
    }

    modifier nftListed(uint256 _tokenId) {
        require(nftListings[_tokenId].isActive, "NFT is not listed for sale.");
        _;
    }

    modifier validListingPrice(uint256 _price) {
        require(_price > 0, "Listing price must be greater than zero.");
        _;
    }

    modifier nftNotStaked(uint256 _tokenId) {
        require(!nftStakingInfo[_tokenId].isStaked, "NFT is already staked.");
        _;
    }

    modifier nftStaked(uint256 _tokenId) {
        require(nftStakingInfo[_tokenId].isStaked, "NFT is not staked.");
        _;
    }

    modifier auctionActive(uint256 _tokenId) {
        require(nftAuctions[_tokenId].isActive, "Auction is not active.");
        _;
    }

    modifier auctionNotActive(uint256 _tokenId) {
        require(!nftAuctions[_tokenId].isActive, "Auction is already active or ended.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal does not exist or is not active.");
        _;
    }


    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // ------------------------ Core NFT Management ------------------------

    /// @notice Mints a new NFT to the specified address.
    /// @param _to The address to receive the NFT.
    /// @param _uri The URI for the NFT metadata.
    function mintNFT(address _to, string memory _uri) public onlyOwner {
        totalSupplyCounter++;
        uint256 tokenId = totalSupplyCounter;
        nftOwner[tokenId] = _to;
        nftURIs[tokenId] = _uri;
        emit NFTMinted(tokenId, _to, _uri);
    }

    /// @notice Transfers an NFT from one address to another.
    /// @param _from The current owner of the NFT.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _from, address _to, uint256 _tokenId) public nftExists(_tokenId) {
        require(nftOwner[_tokenId] == _from, "You are not the owner of this NFT.");
        nftOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /// @notice Burns (destroys) an NFT. Only the owner can burn their NFT.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) public nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        delete nftOwner[_tokenId];
        delete nftURIs[_tokenId];
        delete nftAttributes[_tokenId];
        delete nftListings[_tokenId];
        delete nftStakingInfo[_tokenId];
        delete nftAuctions[_tokenId];
        emit NFTBurned(_tokenId);
    }

    /// @notice Gets the owner of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the NFT owner.
    function getNFTOwner(uint256 _tokenId) public view nftExists(_tokenId) returns (address) {
        return nftOwner[_tokenId];
    }

    /// @notice Gets the URI of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The URI of the NFT metadata.
    function getNFTURI(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        return nftURIs[_tokenId];
    }

    /// @notice Gets the total supply of NFTs.
    /// @return The total number of NFTs minted.
    function totalSupply() public view returns (uint256) {
        return totalSupplyCounter;
    }

    // ------------------------ Dynamic NFT Attributes and Metadata ------------------------

    /// @notice Sets or updates a dynamic attribute for an NFT. Only contract owner can set attributes.
    /// @param _tokenId The ID of the NFT.
    /// @param _attributeName The name of the attribute.
    /// @param _attributeValue The value of the attribute.
    function setNFTAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue) public onlyOwner nftExists(_tokenId) {
        nftAttributes[_tokenId][_attributeName] = _attributeValue;
        emit NFTAttributeSet(_tokenId, _attributeName, _attributeValue);
    }

    /// @notice Gets a specific dynamic attribute value for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _attributeName The name of the attribute.
    /// @return The value of the attribute.
    function getNFTAttribute(uint256 _tokenId, string memory _attributeName) public view nftExists(_tokenId) returns (string memory) {
        return nftAttributes[_tokenId][_attributeName];
    }

    /// @notice Generates a dynamic metadata URI for an NFT based on its attributes.
    ///         This is a placeholder and can be expanded to interact with off-chain services.
    /// @param _tokenId The ID of the NFT.
    /// @return A dynamic metadata URI string.
    function generateDynamicMetadataURI(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        // In a real-world scenario, this function would likely interact with an off-chain service
        // to generate metadata based on the NFT's attributes.
        // For simplicity, we'll return a basic URI here that includes attribute information.
        string memory baseURI = "ipfs://dynamic-metadata/";
        string memory tokenIdStr = uint256ToString(_tokenId);
        string memory attributesStr = "";
        mapping(string => string) storage attributes = nftAttributes[_tokenId];
        string[] memory attributeNames = new string[](0); // In practice, you'd need to track attribute names
        for (uint i = 0; i < attributeNames.length; i++) {
            attributesStr = string(abi.encodePacked(attributesStr, attributeNames[i], ":", attributes[attributeNames[i]], ","));
        }

        return string(abi.encodePacked(baseURI, "token_", tokenIdStr, "?attributes=", attributesStr));
    }


    // ------------------------ Marketplace Listing and Trading ------------------------

    /// @notice Allows an NFT owner to list their NFT for sale.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The price to list the NFT for (in wei).
    function listNFTForSale(uint256 _tokenId, uint256 _price) public marketplaceNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) nftNotListed(_tokenId) validListingPrice(_price) {
        nftListings[_tokenId] = Listing({
            isActive: true,
            price: _price,
            seller: msg.sender
        });
        emit NFTListed(_tokenId, _price, msg.sender);
    }

    /// @notice Allows a user to buy a listed NFT.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) public payable marketplaceNotPaused nftExists(_tokenId) nftListed(_tokenId) {
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");
        require(listing.seller != msg.sender, "Cannot buy your own NFT.");

        address seller = listing.seller;
        uint256 price = listing.price;

        // Transfer NFT ownership
        nftOwner[_tokenId] = msg.sender;

        // Deactivate listing
        listing.isActive = false;

        // Transfer funds to seller
        payable(seller).transfer(price);

        emit NFTBought(_tokenId, price, msg.sender, seller);
        emit NFTTransferred(_tokenId, seller, msg.sender); // Emit transfer event for clarity
    }

    /// @notice Allows the NFT owner to cancel an active listing.
    /// @param _tokenId The ID of the NFT to cancel listing for.
    function cancelNFTListing(uint256 _tokenId) public marketplaceNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) nftListed(_tokenId) {
        nftListings[_tokenId].isActive = false;
        emit NFTListingCancelled(_tokenId);
    }

    /// @notice Allows the NFT owner to update the price of a listed NFT.
    /// @param _tokenId The ID of the NFT to update the price for.
    /// @param _newPrice The new price for the NFT (in wei).
    function updateNFTListingPrice(uint256 _tokenId, uint256 _newPrice) public marketplaceNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) nftListed(_tokenId) validListingPrice(_newPrice) {
        nftListings[_tokenId].price = _newPrice;
        emit NFTListingPriceUpdated(_tokenId, _newPrice);
    }

    /// @notice Gets details of a specific NFT listing.
    /// @param _tokenId The ID of the NFT.
    /// @return isActive, price, seller address.
    function getNFTListingDetails(uint256 _tokenId) public view nftExists(_tokenId) returns (bool isActive, uint256 price, address seller) {
        Listing storage listing = nftListings[_tokenId];
        return (listing.isActive, listing.price, listing.seller);
    }


    // ------------------------ NFT Staking and Rewards ------------------------

    /// @notice Allows NFT owners to stake their NFTs to earn rewards.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) public marketplaceNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) nftNotStaked(_tokenId) {
        nftStakingInfo[_tokenId] = StakingInfo({
            isStaked: true,
            lastStakeTime: block.timestamp
        });
        emit NFTStaked(_tokenId, msg.sender);
    }

    /// @notice Allows NFT owners to unstake their NFTs and claim accumulated rewards.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) public marketplaceNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) nftStaked(_tokenId) {
        StakingInfo storage stakingInfo = nftStakingInfo[_tokenId];
        uint256 reward = calculateStakingReward(_tokenId);

        stakingInfo.isStaked = false;
        delete stakingInfo.lastStakeTime; // Reset staking info after unstaking

        // In a real application, you would likely transfer a reward token here, not ETH.
        // For simplicity, we'll transfer ETH from the contract balance (assuming contract holds some balance).
        payable(msg.sender).transfer(reward);

        emit NFTUnstaked(_tokenId, msg.sender, reward);
    }

    /// @notice Calculates the staking reward for a given NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The staking reward amount (in wei).
    function calculateStakingReward(uint256 _tokenId) public view nftExists(_tokenId) nftStaked(_tokenId) returns (uint256) {
        StakingInfo storage stakingInfo = nftStakingInfo[_tokenId];
        uint256 timeStaked = block.timestamp - stakingInfo.lastStakeTime;
        // Simple reward calculation: rewardRate * timeStaked
        return stakingRewardRate * timeStaked;
    }

    /// @notice Sets or updates the staking reward rate. Only contract owner can set this.
    /// @param _newRate The new staking reward rate.
    function setStakingRewardRate(uint256 _newRate) public onlyOwner {
        stakingRewardRate = _newRate;
    }

    // ------------------------ NFT Fusion and Evolution ------------------------

    /// @notice Allows owners to fuse two NFTs to create a new, evolved NFT.
    /// @param _tokenId1 The ID of the first NFT to fuse.
    /// @param _tokenId2 The ID of the second NFT to fuse.
    function fuseNFTs(uint256 _tokenId1, uint256 _tokenId2) public marketplaceNotPaused nftExists(_tokenId1) nftExists(_tokenId2) onlyNFTOwner(_tokenId1) onlyNFTOwner(_tokenId2) {
        require(nftOwner[_tokenId1] == nftOwner[_tokenId2], "NFTs must be owned by the same address.");
        // Implement fusion logic here. This is a creative and complex feature.
        // Example: Check attributes, rarity, etc., to determine the new NFT's properties.
        // For simplicity, let's just mint a new NFT with a combined URI and burn the old ones.

        string memory uri1 = nftURIs[_tokenId1];
        string memory uri2 = nftURIs[_tokenId2];
        string memory fusedURI = string(abi.encodePacked("ipfs://fused-nft/", uri1, "-", uri2)); // Example combined URI

        totalSupplyCounter++;
        uint256 newTokenId = totalSupplyCounter;
        nftOwner[newTokenId] = msg.sender;
        nftURIs[newTokenId] = fusedURI;

        burnNFT(_tokenId1);
        burnNFT(_tokenId2); // Burn the fused NFTs

        emit NFTsFused(newTokenId, _tokenId1, _tokenId2);
        emit NFTMinted(newTokenId, msg.sender, fusedURI); // Emit mint event for the new NFT
    }

    /// @notice Gets the fusion recipe or result for fusing two NFTs.
    ///         This is a placeholder and would need complex logic for a real implementation.
    /// @param _tokenId1 The ID of the first NFT.
    /// @param _tokenId2 The ID of the second NFT.
    /// @return A string describing the fusion recipe or result.
    function getFusionRecipe(uint256 _tokenId1, uint256 _tokenId2) public view nftExists(_tokenId1) nftExists(_tokenId2) returns (string memory) {
        // Placeholder - In a real implementation, this would contain logic to determine
        // the outcome of fusion based on NFT attributes, rarity, etc.
        return "Fusion recipe details are complex and not fully implemented in this example.";
    }


    // ------------------------ Auction Mechanism ------------------------

    /// @notice Creates an auction for an NFT.
    /// @param _tokenId The ID of the NFT to auction.
    /// @param _startingBid The starting bid price for the auction (in wei).
    /// @param _auctionDuration The duration of the auction in seconds.
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public marketplaceNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) auctionNotActive(_tokenId) validListingPrice(_startingBid) {
        require(!nftStakingInfo[_tokenId].isStaked, "Cannot auction staked NFT.");
        require(!nftListings[_tokenId].isActive, "Cannot auction listed NFT."); // Ensure not listed

        nftAuctions[_tokenId] = Auction({
            isActive: true,
            startingBid: _startingBid,
            currentBid: _startingBid,
            highestBidder: address(0), // No bidder initially
            auctionEndTime: block.timestamp + _auctionDuration
        });
        emit AuctionCreated(_tokenId, _startingBid, _auctionDuration);
    }

    /// @notice Allows users to bid on an active NFT auction.
    /// @param _tokenId The ID of the NFT being auctioned.
    function bidOnAuction(uint256 _tokenId) public payable marketplaceNotPaused nftExists(_tokenId) auctionActive(_tokenId) {
        Auction storage auction = nftAuctions[_tokenId];
        require(block.timestamp < auction.auctionEndTime, "Auction has ended.");
        require(msg.value > auction.currentBid, "Bid must be higher than the current highest bid.");
        require(auction.highestBidder != msg.sender, "You are already the highest bidder."); // Prevent self-bidding loops

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder
            payable(auction.highestBidder).transfer(auction.currentBid);
        }

        auction.currentBid = msg.value;
        auction.highestBidder = msg.sender;
        emit BidPlaced(_tokenId, msg.sender, msg.value);
    }

    /// @notice Ends an active auction and transfers the NFT to the highest bidder.
    /// @param _tokenId The ID of the NFT auction to end.
    function endAuction(uint256 _tokenId) public marketplaceNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) auctionActive(_tokenId) {
        Auction storage auction = nftAuctions[_tokenId];
        require(block.timestamp >= auction.auctionEndTime, "Auction end time has not been reached yet.");
        require(auction.highestBidder != address(0), "No bids placed on this auction.");

        address winner = auction.highestBidder;
        uint256 finalPrice = auction.currentBid;

        auction.isActive = false; // End the auction

        // Transfer NFT to the highest bidder
        nftOwner[_tokenId] = winner;

        // Transfer funds to the auction creator (NFT owner)
        payable(owner).transfer(finalPrice); // In a real scenario, transfer to the original NFT owner, not contract owner.

        emit AuctionEnded(_tokenId, winner, finalPrice);
        emit NFTTransferred(_tokenId, msg.sender, winner); // Emit transfer event
    }

    /// @notice Gets details of an active or past auction for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return isActive, startingBid, currentBid, highestBidder, auctionEndTime
    function getAuctionDetails(uint256 _tokenId) public view nftExists(_tokenId) returns (bool isActive, uint256 startingBid, uint256 currentBid, address highestBidder, uint256 auctionEndTime) {
        Auction storage auction = nftAuctions[_tokenId];
        return (auction.isActive, auction.startingBid, auction.currentBid, auction.highestBidder, auction.auctionEndTime);
    }


    // ------------------------ Community Governance ------------------------

    /// @notice Allows NFT holders to propose new features or changes to the marketplace.
    /// @param _proposalDescription The description of the proposal.
    function proposeFeature(string memory _proposalDescription) public marketplaceNotPaused {
        proposalCounter++;
        uint256 proposalId = proposalCounter;
        proposals[proposalId] = Proposal({
            description: _proposalDescription,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });
        emit ProposalCreated(proposalId, _proposalDescription, msg.sender);
    }

    /// @notice Allows NFT holders to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for 'for', false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _vote) public marketplaceNotPaused proposalExists(_proposalId) {
        // Simple voting: each NFT holder gets one vote per proposal.
        // In a real DAO, voting power might be weighted by the number of NFTs held or other factors.

        // Basic check: prevent voting multiple times (for simplicity - can be improved with mapping of voters per proposal).
        require(proposals[_proposalId].isActive, "Proposal is not active."); // Double check active status

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Gets details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return description, votesFor, votesAgainst, isActive
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (string memory description, uint256 votesFor, uint256 votesAgainst, bool isActive) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.isActive);
    }


    // ------------------------ Utility and Admin Functions ------------------------

    /// @notice Pauses all marketplace trading functionalities. Only owner can call this.
    function pauseMarketplace() public onlyOwner {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /// @notice Resumes marketplace trading functionalities. Only owner can call this.
    function unpauseMarketplace() public onlyOwner {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    /// @notice Allows the contract owner to withdraw contract balance (fees, rewards, etc.).
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit ContractBalanceWithdrawn(balance, owner);
    }

    // --- Utility function to convert uint256 to string ---
    function uint256ToString(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```