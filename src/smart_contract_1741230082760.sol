```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Marketplace with Advanced Features - "Chameleon NFTs"
 * @author Bard (AI Assistant)
 * @dev A decentralized marketplace for NFTs with dynamic metadata, auctions, staking, rentals, and governance features.
 *      This contract introduces "Chameleon NFTs" - NFTs whose properties and metadata can evolve based on on-chain or off-chain events,
 *      making them more engaging and interactive. It's designed to be more than just a marketplace, offering a platform for NFT utility and community engagement.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Marketplace Functions:**
 *    - `listItemForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owner to list their NFT for sale at a fixed price.
 *    - `buyItem(uint256 _tokenId)`: Allows anyone to purchase a listed NFT.
 *    - `cancelListing(uint256 _tokenId)`: Allows the seller to cancel their NFT listing.
 *    - `updateListingPrice(uint256 _tokenId, uint256 _newPrice)`: Allows the seller to update the price of a listed NFT.
 *    - `getListing(uint256 _tokenId)`: Returns details of an NFT listing (price, seller, isListed).
 *
 * **2. Dynamic NFT Metadata Management (Chameleon Feature):**
 *    - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`: (Admin/Creator controlled) Allows updating the metadata URI of an NFT, simulating dynamic evolution.
 *    - `setDynamicCondition(uint256 _tokenId, string memory _conditionIdentifier, string memory _conditionValue)`: (NFT Creator) Sets a dynamic condition for an NFT. This is a placeholder concept, actual dynamic logic would require oracles/external triggers.
 *    - `triggerDynamicUpdate(uint256 _tokenId, string memory _conditionIdentifier, string memory _newValue)`: (External Trigger - simulated) Simulates an external event triggering a dynamic update (in a real scenario, this could be called by an oracle or another contract).
 *    - `getNFTDynamicConditions(uint256 _tokenId)`: Returns the set dynamic conditions for an NFT.
 *    - `getCurrentNFTMetadata(uint256 _tokenId)`:  Returns the current metadata URI of an NFT.
 *
 * **3. Auction Functionality:**
 *    - `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _duration)`: Allows listing an NFT for auction with a starting bid and duration.
 *    - `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active auction.
 *    - `finalizeAuction(uint256 _auctionId)`: Ends an auction and transfers the NFT to the highest bidder.
 *    - `getAuctionDetails(uint256 _auctionId)`: Returns details of an auction (tokenId, startTime, endTime, highestBid, bidder, isActive).
 *
 * **4. NFT Staking for Platform Rewards:**
 *    - `stakeNFT(uint256 _tokenId)`: Allows NFT owners to stake their NFTs to earn platform rewards.
 *    - `unstakeNFT(uint256 _tokenId)`: Allows unstaking NFTs.
 *    - `claimStakingRewards(uint256 _tokenId)`: Allows users to claim accumulated staking rewards.
 *    - `getStakingDetails(uint256 _tokenId)`: Returns staking details for an NFT (isStaked, lastClaimTime, accumulatedRewards).
 *
 * **5. NFT Rental/Leasing Functionality:**
 *    - `rentNFT(uint256 _tokenId, uint256 _rentalPeriod)`: Allows NFT owners to rent out their NFTs for a specified period.
 *    - `returnRentedNFT(uint256 _tokenId)`: Allows renters to return NFTs before the rental period ends (or automatically after).
 *    - `getRentalDetails(uint256 _tokenId)`: Returns rental details for an NFT (isRented, renter, rentalEndTime).
 *
 * **6. Platform Governance (Simple Example):**
 *    - `proposeParameterChange(string memory _parameterName, uint256 _newValue)`: (Token Holders - simulated) Allows token holders to propose changes to platform parameters (e.g., platform fee percentage).
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: (Token Holders - simulated) Allows token holders to vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: (Admin) Executes a passed proposal after a voting period.
 *    - `getParameterValue(string memory _parameterName)`: Returns the current value of a platform parameter.
 *
 * **7. Admin & Utility Functions:**
 *    - `setPlatformFee(uint256 _newFeePercentage)`: (Admin) Sets the platform fee percentage for marketplace sales.
 *    - `withdrawPlatformFees()`: (Admin) Allows the platform admin to withdraw accumulated marketplace fees.
 *    - `pauseContract()`: (Admin) Pauses core marketplace functionalities for emergency situations.
 *    - `unpauseContract()`: (Admin) Resumes marketplace functionalities.
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChameleonNFTMarketplace is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    IERC721 public nftContract; // Address of the NFT contract this marketplace is for
    uint256 public platformFeePercentage = 2; // Platform fee percentage (e.g., 2% of sale price)
    address payable public platformFeeRecipient; // Address to receive platform fees
    Counters.Counter private _listingCounter;
    Counters.Counter private _auctionCounter;
    Counters.Counter private _proposalCounter;

    // Structs to hold marketplace data
    struct Listing {
        uint256 price;
        address payable seller;
        bool isListed;
    }

    struct Auction {
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address payable highestBidder;
        bool isActive;
    }

    struct StakingInfo {
        bool isStaked;
        uint256 lastClaimTime;
        uint256 accumulatedRewards; // Placeholder - reward calculation would be more complex in reality
    }

    struct RentalInfo {
        bool isRented;
        address payable renter;
        uint256 rentalEndTime;
    }

    struct DynamicCondition {
        string conditionIdentifier;
        string conditionValue;
    }

    struct Proposal {
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    // Mappings to store marketplace data
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => StakingInfo) public stakingInfo;
    mapping(uint256 => RentalInfo) public rentalInfo;
    mapping(uint256 => DynamicCondition[]) public nftDynamicConditions; // Array of conditions per NFT
    mapping(uint256 => Proposal) public proposals;
    mapping(string => uint256) public platformParameters; // Example: platform fees, etc.

    // --- Events ---

    event ItemListed(uint256 tokenId, uint256 price, address seller);
    event ItemBought(uint256 tokenId, uint256 price, address seller, address buyer);
    event ListingCancelled(uint256 tokenId, address seller);
    event ListingPriceUpdated(uint256 tokenId, uint256 newPrice, address seller);
    event MetadataUpdated(uint256 tokenId, string newMetadataURI);
    event DynamicConditionSet(uint256 tokenId, string conditionIdentifier, string conditionValue);
    event DynamicUpdateTriggered(uint256 tokenId, string conditionIdentifier, string newValue);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event RewardsClaimed(uint256 tokenId, address claimer, uint256 rewardAmount);
    event NFTRented(uint256 tokenId, address renter, uint256 rentalEndTime);
    event NFTReturned(uint256 tokenId, address renter, uint256 owner);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContractPaused();
    event ContractUnpaused();
    event PlatformFeeSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);


    // --- Modifiers ---

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftContract.ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        _;
    }

    modifier onlyListed(uint256 _tokenId) {
        require(listings[_tokenId].isListed, "NFT not listed for sale");
        _;
    }

    modifier notListed(uint256 _tokenId) {
        require(!listings[_tokenId].isListed, "NFT already listed for sale");
        _;
    }

    modifier auctionActive(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction is not active");
        _;
    }

    modifier validBid(uint256 _auctionId) {
        require(msg.value > auctions[_auctionId].highestBid, "Bid must be higher than current highest bid");
        _;
    }

    modifier notRented(uint256 _tokenId) {
        require(!rentalInfo[_tokenId].isRented, "NFT is currently rented");
        _;
    }

    modifier onlyRenter(uint256 _tokenId) {
        require(rentalInfo[_tokenId].isRented && rentalInfo[_tokenId].renter == _msgSender(), "Not the current renter");
        _;
    }

    modifier rentalPeriodElapsed(uint256 _tokenId) {
        require(rentalInfo[_tokenId].isRented && block.timestamp >= rentalInfo[_tokenId].rentalEndTime, "Rental period has not elapsed");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(!proposals[_proposalId].executed && block.timestamp < proposals[_proposalId].endTime, "Proposal is not active or already executed");
        _;
    }

    // --- Constructor ---
    constructor(address _nftContractAddress, address payable _platformFeeRecipient) payable Ownable() {
        nftContract = IERC721(_nftContractAddress);
        platformFeeRecipient = _platformFeeRecipient;
        platformParameters["platformFeePercentage"] = platformFeePercentage; // Initialize parameter
    }

    // --- 1. Core Marketplace Functions ---

    function listItemForSale(uint256 _tokenId, uint256 _price) external whenNotPaused onlyNFTOwner(_tokenId) notListed(_tokenId) notRented(_tokenId) {
        _listingCounter.increment();
        listings[_tokenId] = Listing({
            price: _price,
            seller: payable(_msgSender()),
            isListed: true
        });
        emit ItemListed(_tokenId, _price, _msgSender());
    }

    function buyItem(uint256 _tokenId) external payable whenNotPaused onlyListed(_tokenId) {
        Listing storage currentListing = listings[_tokenId];
        require(msg.value >= currentListing.price, "Insufficient funds to buy NFT");

        uint256 platformFee = (currentListing.price * platformFeePercentage) / 100;
        uint256 sellerProceeds = currentListing.price - platformFee;

        // Transfer NFT to buyer
        nftContract.safeTransferFrom(currentListing.seller, _msgSender(), _tokenId);

        // Transfer funds to seller and platform
        payable(currentListing.seller).transfer(sellerProceeds);
        platformFeeRecipient.transfer(platformFee);

        // Clear listing
        delete listings[_tokenId];

        emit ItemBought(_tokenId, currentListing.price, currentListing.seller, _msgSender());
    }

    function cancelListing(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) onlyListed(_tokenId) {
        delete listings[_tokenId];
        emit ListingCancelled(_tokenId, _msgSender());
    }

    function updateListingPrice(uint256 _tokenId, uint256 _newPrice) external whenNotPaused onlyNFTOwner(_tokenId) onlyListed(_tokenId) {
        listings[_tokenId].price = _newPrice;
        emit ListingPriceUpdated(_tokenId, _newPrice, _msgSender());
    }

    function getListing(uint256 _tokenId) external view returns (uint256 price, address seller, bool isListed) {
        Listing storage listing = listings[_tokenId];
        return (listing.price, listing.seller, listing.isListed);
    }

    // --- 2. Dynamic NFT Metadata Management (Chameleon Feature) ---

    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyOwner { // Admin controlled for simplicity - can be made more complex
        // In a real scenario, this could be triggered based on on-chain events or oracle data
        // Here, we are simulating a direct update by the platform admin/contract creator.
        // This function would typically interact with an off-chain metadata storage or service.
        // For this example, we're just emitting an event. In a real application, you might update storage
        // or trigger an off-chain process to regenerate metadata.
        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }

    function setDynamicCondition(uint256 _tokenId, string memory _conditionIdentifier, string memory _conditionValue) external onlyOwner { // NFT Creator can set conditions
        nftDynamicConditions[_tokenId].push(DynamicCondition({
            conditionIdentifier: _conditionIdentifier,
            conditionValue: _conditionValue
        }));
        emit DynamicConditionSet(_tokenId, _conditionIdentifier, _conditionValue);
    }

    function triggerDynamicUpdate(uint256 _tokenId, string memory _conditionIdentifier, string memory _newValue) external onlyOwner { // Simulated external trigger
        // In a real dynamic NFT, this would be triggered by an oracle or another contract based on external events
        // Here, for demonstration, we simulate an admin-triggered update.
        emit DynamicUpdateTriggered(_tokenId, _conditionIdentifier, _newValue);
        // In a real application, this would likely update the metadata URI based on conditions and new values.
        // This might involve interacting with an off-chain service to generate new metadata.
    }

    function getNFTDynamicConditions(uint256 _tokenId) external view returns (DynamicCondition[] memory) {
        return nftDynamicConditions[_tokenId];
    }

    function getCurrentNFTMetadata(uint256 _tokenId) external view returns (string memory) {
        // Placeholder - in a real dynamic NFT, you'd fetch the current metadata URI based on conditions.
        // For this example, we are just returning a static message as we are not implementing complex metadata generation.
        return string(abi.encodePacked("ipfs://dynamic-metadata-base/", _tokenId.toString())); // Example - dynamic URI generation concept
    }


    // --- 3. Auction Functionality ---

    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _duration) external whenNotPaused onlyNFTOwner(_tokenId) notListed(_tokenId) notRented(_tokenId) {
        require(_startingBid > 0, "Starting bid must be greater than 0");
        require(_duration > 0, "Auction duration must be greater than 0");

        _auctionCounter.increment();
        uint256 auctionId = _auctionCounter.current();
        auctions[auctionId] = Auction({
            tokenId: _tokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            highestBid: _startingBid,
            highestBidder: payable(address(0)), // No bidder initially
            isActive: true
        });
        emit AuctionCreated(auctionId, _tokenId, _startingBid, block.timestamp + _duration);
    }

    function bidOnAuction(uint256 _auctionId) external payable whenNotPaused auctionActive(_auctionId) validBid(_auctionId) {
        Auction storage currentAuction = auctions[_auctionId];

        // Refund previous bidder (if any)
        if (currentAuction.highestBidder != address(0)) {
            payable(currentAuction.highestBidder).transfer(currentAuction.highestBid);
        }

        // Update auction with new bid
        currentAuction.highestBid = msg.value;
        currentAuction.highestBidder = payable(_msgSender());
        emit BidPlaced(_auctionId, _msgSender(), msg.value);
    }

    function finalizeAuction(uint256 _auctionId) external whenNotPaused auctionActive(_auctionId) {
        Auction storage currentAuction = auctions[_auctionId];
        require(block.timestamp >= currentAuction.endTime, "Auction time not elapsed yet");

        currentAuction.isActive = false; // Mark auction as inactive

        if (currentAuction.highestBidder != address(0)) {
            uint256 platformFee = (currentAuction.highestBid * platformFeePercentage) / 100;
            uint256 sellerProceeds = currentAuction.highestBid - platformFee;

            // Transfer NFT to highest bidder
            nftContract.safeTransferFrom(nftContract.ownerOf(currentAuction.tokenId), currentAuction.highestBidder, currentAuction.tokenId);

            // Transfer funds to seller and platform
            payable(nftContract.ownerOf(currentAuction.tokenId)).transfer(sellerProceeds); // Seller is still owner until transfer happens
            platformFeeRecipient.transfer(platformFee);

            emit AuctionFinalized(_auctionId, currentAuction.tokenId, currentAuction.highestBidder, currentAuction.highestBid);
        } else {
            // No bids, auction ends without sale - NFT remains with owner
            // Optionally, implement logic for what happens if no bids (e.g., relist, return to owner)
        }
    }

    function getAuctionDetails(uint256 _auctionId) external view returns (uint256 tokenId, uint256 startTime, uint256 endTime, uint256 highestBid, address highestBidder, bool isActive) {
        Auction storage auction = auctions[_auctionId];
        return (auction.tokenId, auction.startTime, auction.endTime, auction.highestBid, auction.highestBidder, auction.isActive);
    }

    // --- 4. NFT Staking for Platform Rewards ---

    function stakeNFT(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) notListed(_tokenId) notRented(_tokenId) {
        require(!stakingInfo[_tokenId].isStaked, "NFT already staked");
        stakingInfo[_tokenId].isStaked = true;
        stakingInfo[_tokenId].lastClaimTime = block.timestamp;
        emit NFTStaked(_tokenId, _msgSender());
    }

    function unstakeNFT(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(stakingInfo[_tokenId].isStaked, "NFT not staked");
        stakingInfo[_tokenId].isStaked = false;
        // In a real staking system, you'd calculate and potentially transfer rewards here.
        emit NFTUnstaked(_tokenId, _msgSender());
    }

    function claimStakingRewards(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(stakingInfo[_tokenId].isStaked, "NFT not staked");
        // --- Reward calculation and transfer logic would go here ---
        // This is a simplified example. Real reward calculation would depend on staking duration, APR, etc.
        uint256 rewardAmount = 1 ether; // Example reward - replace with actual calculation
        stakingInfo[_tokenId].lastClaimTime = block.timestamp; // Update last claim time
        stakingInfo[_tokenId].accumulatedRewards = 0; // Reset accumulated rewards (after claiming)
        payable(_msgSender()).transfer(rewardAmount); // Transfer reward to staker
        emit RewardsClaimed(_tokenId, _msgSender(), rewardAmount);
    }

    function getStakingDetails(uint256 _tokenId) external view returns (bool isStaked, uint256 lastClaimTime, uint256 accumulatedRewards) {
        StakingInfo storage stake = stakingInfo[_tokenId];
        return (stake.isStaked, stake.lastClaimTime, stake.accumulatedRewards);
    }

    // --- 5. NFT Rental/Leasing Functionality ---

    function rentNFT(uint256 _tokenId, uint256 _rentalPeriod) external payable whenNotPaused onlyNFTOwner(_tokenId) notListed(_tokenId) notRented(_tokenId) {
        require(_rentalPeriod > 0, "Rental period must be greater than 0");
        uint256 rentalFee = _rentalPeriod * 1 ether; // Example rental fee calculation - adjust logic
        require(msg.value >= rentalFee, "Insufficient rental fee");

        rentalInfo[_tokenId] = RentalInfo({
            isRented: true,
            renter: payable(_msgSender()),
            rentalEndTime: block.timestamp + _rentalPeriod
        });
        emit NFTRented(_tokenId, _msgSender(), block.timestamp + _rentalPeriod);
        payable(_msgSender()).transfer(rentalFee); // Owner receives rental fee immediately in this simple example
    }

    function returnRentedNFT(uint256 _tokenId) external whenNotPaused onlyRenter(_tokenId) {
        rentalInfo[_tokenId].isRented = false;
        rentalInfo[_tokenId].renter = payable(address(0));
        rentalInfo[_tokenId].rentalEndTime = 0;
        emit NFTReturned(_tokenId, _msgSender(), nftContract.ownerOf(_tokenId));
    }

    function getRentalDetails(uint256 _tokenId) external view returns (bool isRented, address renter, uint256 rentalEndTime) {
        RentalInfo storage rental = rentalInfo[_tokenId];
        return (rental.isRented, rental.renter, rental.rentalEndTime);
    }

    // --- 6. Platform Governance (Simple Example) ---

    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external whenNotPaused { //  Token holders (simulated) propose changes
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();
        proposals[proposalId] = Proposal({
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit ParameterProposalCreated(proposalId, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused proposalActive(_proposalId) { // Token holders (simulated) vote
        // In a real governance system, voting power would be based on token holdings or other criteria.
        // Here, we are simply allowing any address to vote once per proposal.
        // In a real system, prevent double voting per address.
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, _msgSender(), _vote);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused { // Admin executes proposal if passed
        Proposal storage currentProposal = proposals[_proposalId];
        require(!currentProposal.executed, "Proposal already executed");
        require(block.timestamp >= currentProposal.endTime, "Voting period not ended");

        // Simple majority for approval (can be changed)
        uint256 totalVotes = currentProposal.yesVotes + currentProposal.noVotes;
        require(currentProposal.yesVotes > currentProposal.noVotes, "Proposal not approved"); // Simple majority

        platformParameters[currentProposal.parameterName] = currentProposal.newValue;
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId, currentProposal.parameterName, currentProposal.newValue);
    }

    function getParameterValue(string memory _parameterName) external view returns (uint256) {
        return platformParameters[_parameterName];
    }

    // --- 7. Admin & Utility Functions ---

    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%");
        platformFeePercentage = _newFeePercentage;
        platformParameters["platformFeePercentage"] = _newFeePercentage; // Update parameter value
        emit PlatformFeeSet(_newFeePercentage);
    }

    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No platform fees to withdraw");
        platformFeeRecipient.transfer(balance);
        emit PlatformFeesWithdrawn(balance, platformFeeRecipient);
    }

    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    // --- Fallback and Receive functions for direct ETH transfers (if needed for platform fees) ---
    receive() external payable {}
    fallback() external payable {}
}
```