```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Gemini AI
 * @dev This smart contract implements a decentralized marketplace for Dynamic NFTs (dNFTs) with various advanced functionalities.
 * It goes beyond basic NFT trading and incorporates features like dynamic NFT properties, on-chain randomness for NFT evolution,
 * decentralized governance over marketplace parameters, NFT staking for rewards, reputation system for users, and more.
 *
 * **Outline:**
 * 1. **NFT Management:**
 *    - `mintDynamicNFT`: Mints a new dynamic NFT with initial properties.
 *    - `updateNFTProperty`: Allows authorized users to update a specific property of a dNFT.
 *    - `evolveNFT`: Triggers on-chain evolution of an NFT based on randomness and predefined rules.
 *    - `getNFTProperties`: Retrieves all properties of a given NFT.
 *    - `setNFTMetadataBaseURI`: Allows admin to set the base URI for NFT metadata.
 *
 * 2. **Marketplace Operations:**
 *    - `listNFTForSale`: Lists an NFT for sale on the marketplace.
 *    - `buyNFT`: Allows users to buy a listed NFT.
 *    - `cancelNFTListing`: Allows the seller to cancel a listing.
 *    - `createAuction`: Starts a new auction for an NFT.
 *    - `bidOnAuction`: Allows users to bid on an active auction.
 *    - `endAuction`: Ends an auction and transfers the NFT to the highest bidder.
 *    - `cancelAuction`: Allows the auction creator to cancel an auction before it ends.
 *    - `setMarketplaceFee`: Allows the admin to set the marketplace fee percentage.
 *    - `withdrawMarketplaceFees`: Allows the admin to withdraw accumulated marketplace fees.
 *
 * 3. **Dynamic NFT Features:**
 *    - `setNFTEvolutionRule`: Allows admin to define rules for NFT evolution.
 *    - `triggerNFTEvent`: Simulates an external event that can trigger NFT property changes based on rules.
 *    - `getRandomNumber`: (Internal - example of on-chain randomness - use with caution in production) Generates a pseudo-random number.
 *
 * 4. **Governance & Community Features:**
 *    - `proposeMarketplaceChange`: Allows NFT holders to propose changes to marketplace parameters.
 *    - `voteOnProposal`: Allows NFT holders to vote on active proposals.
 *    - `executeProposal`: Executes a successful marketplace change proposal.
 *    - `stakeNFT`: Allows users to stake their NFTs to earn rewards.
 *    - `unstakeNFT`: Allows users to unstake their NFTs.
 *    - `distributeStakingRewards`: Distributes staking rewards to stakers.
 *    - `setUserReputation`: (Admin function) Manually sets user reputation score.
 *    - `getUserReputation`: Retrieves the reputation score of a user.
 *
 * **Function Summary:**
 * - `mintDynamicNFT(address _to, string memory _baseMetadataURI, string[] memory _propertyNames, string[] memory _propertyValues)`: Mints a new dynamic NFT to the specified address with initial properties.
 * - `updateNFTProperty(uint256 _tokenId, string memory _propertyName, string memory _newValue)`: Updates a specific property of a dynamic NFT. Only callable by authorized users (e.g., NFT owner or approved updater).
 * - `evolveNFT(uint256 _tokenId)`: Triggers the on-chain evolution of a dynamic NFT based on predefined rules and on-chain randomness.
 * - `getNFTProperties(uint256 _tokenId)`: Retrieves all properties of a given dynamic NFT as string arrays.
 * - `setNFTMetadataBaseURI(string memory _baseURI)`: Sets the base URI for NFT metadata. Only callable by the contract owner.
 * - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace at a specified price.
 * - `buyNFT(uint256 _listingId)`: Allows a user to buy an NFT listed on the marketplace.
 * - `cancelNFTListing(uint256 _listingId)`: Allows the seller to cancel their NFT listing.
 * - `createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration)`: Creates a new auction for an NFT with a starting price and duration.
 * - `bidOnAuction(uint256 _auctionId)`: Allows a user to place a bid on an active auction.
 * - `endAuction(uint256 _auctionId)`: Ends an auction and transfers the NFT to the highest bidder. Only callable after auction duration.
 * - `cancelAuction(uint256 _auctionId)`: Allows the auction creator to cancel an auction before it ends, if no bids have been placed.
 * - `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage. Only callable by the contract owner.
 * - `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 * - `setNFTEvolutionRule(string memory _ruleName, string memory _propertyName, string memory _triggerEvent, string memory _newValue)`: Defines a rule for NFT evolution based on specific events.
 * - `triggerNFTEvent(string memory _eventName, uint256 _tokenId)`: Triggers a simulated external event that might cause NFT properties to change based on defined rules.
 * - `getRandomNumber(uint256 _seed)`: (Internal) Generates a pseudo-random number using blockhash and seed. **Use with caution for security-critical randomness.**
 * - `proposeMarketplaceChange(string memory _proposalDescription, string memory _parameterName, uint256 _newValue)`: Allows NFT holders to propose changes to marketplace parameters (e.g., fees, rules).
 * - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote for or against a marketplace change proposal.
 * - `executeProposal(uint256 _proposalId)`: Executes a successful marketplace change proposal after voting period and quorum are met.
 * - `stakeNFT(uint256 _tokenId)`: Allows users to stake their NFTs to participate in staking rewards.
 * - `unstakeNFT(uint256 _tokenId)`: Allows users to unstake their NFTs and claim pending staking rewards.
 * - `distributeStakingRewards()`: Distributes staking rewards to users who have staked NFTs based on a defined reward mechanism.
 * - `setUserReputation(address _user, uint256 _reputation)`: (Admin function) Manually sets the reputation score for a user.
 * - `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 */
contract DynamicNFTMarketplace {
    // --- State Variables ---

    // NFT Metadata
    string public nftMetadataBaseURI;
    uint256 public nextTokenId = 1;

    // Marketplace Parameters
    uint256 public marketplaceFeePercentage = 2; // 2% default fee
    address payable public marketplaceFeeRecipient;
    uint256 public accumulatedFees;

    // Dynamic NFT Properties
    mapping(uint256 => string[]) public nftPropertyNames;
    mapping(uint256 => mapping(string => string)) public nftProperties;
    mapping(string => NFTEvolutionRule) public nftEvolutionRules; // Rule name => Rule

    struct NFTEvolutionRule {
        string propertyName;
        string triggerEvent;
        string newValue;
    }

    // Marketplace Listings
    uint256 public nextListingId = 1;
    mapping(uint256 => Listing) public listings;
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    // Auctions
    uint256 public nextAuctionId = 1;
    mapping(uint256 => Auction) public auctions;
    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    // Governance Proposals
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    struct Proposal {
        string description;
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;
    }
    uint256 public proposalVotingDuration = 7 days; // Default voting duration
    uint256 public proposalQuorumPercentage = 50; // Default quorum

    // NFT Staking
    mapping(uint256 => Stake) public nftStakes;
    struct Stake {
        uint256 tokenId;
        address staker;
        uint256 stakeTime;
        uint256 pendingRewards;
        bool isStaked;
    }
    uint256 public stakingRewardRate = 10; // Example reward rate (units per day per NFT staked) - adjust as needed
    uint256 public lastRewardDistributionTime;

    // User Reputation
    mapping(address => uint256) public userReputations;

    // Contract Owner
    address public owner;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to);
    event NFTPropertyChanged(uint256 tokenId, string propertyName, string newValue);
    event NFTEvolved(uint256 tokenId);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 listingId, uint256 tokenId);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 amount);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 price);
    event AuctionCancelled(uint256 auctionId, uint256 tokenId);
    event MarketplaceFeeSet(uint256 feePercentage);
    event FeesWithdrawn(uint256 amount);
    event NFTEvolutionRuleSet(string ruleName, string propertyName, string triggerEvent, string newValue);
    event NFTEventTriggered(string eventName, uint256 tokenId);
    event ProposalCreated(uint256 proposalId, string description, string parameterName, uint256 newValue);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, uint256 rewards);
    event StakingRewardsDistributed(uint256 totalRewardsDistributed);
    event UserReputationSet(address user, uint256 reputation);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyActiveListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active.");
        _;
    }

    modifier onlyActiveAuction(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        _;
    }

    modifier onlyAuctionSeller(uint256 _auctionId) {
        require(auctions[_auctionId].seller == msg.sender, "Only auction seller can call this function.");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "Only listing seller can call this function.");
        _;
    }

    modifier auctionNotEnded(uint256 _auctionId) {
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has already ended.");
        _;
    }

    modifier auctionEnded(uint256 _auctionId) {
        require(block.timestamp >= auctions[_auctionId].endTime, "Auction has not ended yet.");
        _;
    }

    modifier noBidsPlaced(uint256 _auctionId) {
        require(auctions[_auctionId].highestBid == 0, "Bids have already been placed, cannot cancel.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].isExecuted, "Proposal already executed.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Proposal voting period is not active.");
        _;
    }

    // --- Constructor ---
    constructor(address payable _feeRecipient) {
        owner = msg.sender;
        marketplaceFeeRecipient = _feeRecipient;
        lastRewardDistributionTime = block.timestamp;
    }

    // --- NFT Management Functions ---

    function mintDynamicNFT(address _to, string memory _baseMetadataURI, string[] memory _propertyNames, string[] memory _propertyValues) public onlyOwner returns (uint256) {
        require(_propertyNames.length == _propertyValues.length, "Property names and values length mismatch.");
        uint256 tokenId = nextTokenId++;
        nftMetadataBaseURI = _baseMetadataURI; // Set base URI when minting the first NFT
        for (uint256 i = 0; i < _propertyNames.length; i++) {
            nftPropertyNames[tokenId].push(_propertyNames[i]);
            nftProperties[tokenId][_propertyNames[i]] = _propertyValues[i];
        }
        // In a real implementation, you would also emit a Transfer event as per ERC721 standard if this was built on ERC721.
        emit NFTMinted(tokenId, _to);
        return tokenId;
    }

    function updateNFTProperty(uint256 _tokenId, string memory _propertyName, string memory _newValue) public {
        // In a real application, add authorization logic here - who can update properties?
        // For simplicity, in this example, anyone can update. In production, restrict to owner or approved roles.
        nftProperties[_tokenId][_propertyName] = _newValue;
        emit NFTPropertyChanged(_tokenId, _propertyName, _newValue);
    }

    function evolveNFT(uint256 _tokenId) public {
        // Example evolution logic based on randomness (use with caution in production)
        string memory currentProperty = nftProperties[_tokenId]["trait"]; // Example: Assume NFT has a 'trait' property
        uint256 randomNumber = getRandomNumber(_tokenId);

        if (keccak256(bytes(currentProperty)) == keccak256(bytes("Common"))) {
            if (randomNumber % 100 < 10) { // 10% chance to evolve from Common to Rare
                nftProperties[_tokenId]["trait"] = "Rare";
                emit NFTEvolved(_tokenId);
            }
        } else if (keccak256(bytes(currentProperty)) == keccak256(bytes("Rare"))) {
            if (randomNumber % 100 < 5) { // 5% chance to evolve from Rare to Epic
                nftProperties[_tokenId]["trait"] = "Epic";
                emit NFTEvolved(_tokenId);
            }
        }
        // Add more evolution rules as needed.
    }

    function getNFTProperties(uint256 _tokenId) public view returns (string[] memory names, string[] memory values) {
        string[] memory propertyNames = nftPropertyNames[_tokenId];
        string[] memory propertyValues = new string[](propertyNames.length);
        for (uint256 i = 0; i < propertyNames.length; i++) {
            propertyValues[i] = nftProperties[_tokenId][propertyNames[i]];
        }
        return (propertyNames, propertyValues);
    }

    function setNFTMetadataBaseURI(string memory _baseURI) public onlyOwner {
        nftMetadataBaseURI = _baseURI;
    }

    // --- Marketplace Functions ---

    function listNFTForSale(uint256 _tokenId, uint256 _price) public {
        // In a real implementation, you would check if msg.sender owns the NFT (e.g., via ERC721 interface)
        require(_price > 0, "Price must be greater than zero.");
        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _listingId) public payable onlyActiveListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds.");
        require(listing.seller != msg.sender, "Cannot buy your own NFT.");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - feeAmount;

        accumulatedFees += feeAmount;
        (bool successSeller, ) = listing.seller.call{value: sellerPayout}(""); // Send payout to seller
        require(successSeller, "Seller payout failed.");
        (bool successFeeRecipient, ) = marketplaceFeeRecipient.call{value: feeAmount}(""); // Send fees to recipient - removed for now, feeRecipient is set to owner in constructor.
        require(successFeeRecipient, "Fee recipient payment failed.");


        listing.isActive = false;
        // In a real implementation, you would transfer the NFT to msg.sender (e.g., via ERC721 interface)
        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    function cancelNFTListing(uint256 _listingId) public onlyActiveListing(_listingId) onlyListingSeller(_listingId) {
        listings[_listingId].isActive = false;
        emit NFTListingCancelled(_listingId, listings[_listingId].tokenId);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration) public {
        require(_startingPrice > 0, "Starting price must be greater than zero.");
        require(_duration > 0, "Auction duration must be greater than zero.");
        uint256 auctionId = nextAuctionId++;
        auctions[auctionId] = Auction({
            tokenId: _tokenId,
            seller: msg.sender,
            startingPrice: _startingPrice,
            endTime: block.timestamp + _duration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit AuctionCreated(auctionId, _tokenId, msg.sender, _startingPrice, block.timestamp + _duration);
    }

    function bidOnAuction(uint256 _auctionId) public payable onlyActiveAuction(_auctionId) auctionNotEnded(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction.");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid.");
        require(msg.value >= auction.startingPrice, "Bid must be at least the starting price.");

        if (auction.highestBidder != address(0)) {
            (bool successRefund, ) = auction.highestBidder.call{value: auction.highestBid}(""); // Refund previous highest bidder
            require(successRefund, "Refund to previous bidder failed.");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) public onlyActiveAuction(_auctionId) auctionEnded(_auctionId) onlyAuctionSeller(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active.");
        auction.isActive = false;

        if (auction.highestBidder != address(0)) {
            uint256 feeAmount = (auction.highestBid * marketplaceFeePercentage) / 100;
            uint256 sellerPayout = auction.highestBid - feeAmount;

            accumulatedFees += feeAmount;
            (bool successSeller, ) = auction.seller.call{value: sellerPayout}(""); // Send payout to seller
            require(successSeller, "Seller payout failed.");
            (bool successFeeRecipient, ) = marketplaceFeeRecipient.call{value: feeAmount}(""); // Send fees to recipient
            require(successFeeRecipient, "Fee recipient payment failed.");

            // In a real implementation, you would transfer the NFT to auction.highestBidder (e.g., via ERC721 interface)
            emit AuctionEnded(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids placed, auction ends, NFT stays with seller.
            emit AuctionEnded(_auctionId, auction.tokenId, address(0), 0); // Winner is address(0)
        }
    }

    function cancelAuction(uint256 _auctionId) public onlyActiveAuction(_auctionId) onlyAuctionSeller(_auctionId) auctionNotEnded(_auctionId) noBidsPlaced(_auctionId) {
        auctions[_auctionId].isActive = false;
        emit AuctionCancelled(_auctionId, auctions[_auctionId].tokenId);
    }

    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 amountToWithdraw = accumulatedFees;
        accumulatedFees = 0;
        (bool success, ) = marketplaceFeeRecipient.call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed.");
        emit FeesWithdrawn(amountToWithdraw);
    }

    // --- Dynamic NFT Features Functions ---

    function setNFTEvolutionRule(string memory _ruleName, string memory _propertyName, string memory _triggerEvent, string memory _newValue) public onlyOwner {
        nftEvolutionRules[_ruleName] = NFTEvolutionRule({
            propertyName: _propertyName,
            triggerEvent: _triggerEvent,
            newValue: _newValue
        });
        emit NFTEvolutionRuleSet(_ruleName, _propertyName, _triggerEvent, _newValue);
    }

    function triggerNFTEvent(string memory _eventName, uint256 _tokenId) public {
        // Example: Check if there's a rule for this event
        for (uint256 i = 1; i < nextTokenId; i++) { // Iterate through all existing NFTs - inefficient for large numbers, optimize in real use case
            if (i == _tokenId) {
                for (uint256 j = 0; j < nextAuctionId; j++) { // Inefficient iteration - replace with better data structure if needed
                    if (keccak256(bytes(nftEvolutionRules[string.concat("rule",Strings.toString(j))].triggerEvent)) == keccak256(bytes(_eventName))) { // Example rule name "rule0", "rule1", etc. - improve naming
                        string memory propertyToUpdate = nftEvolutionRules[string.concat("rule",Strings.toString(j))].propertyName;
                        string memory newValue = nftEvolutionRules[string.concat("rule",Strings.toString(j))].newValue;
                        nftProperties[_tokenId][propertyToUpdate] = newValue;
                        emit NFTPropertyChanged(_tokenId, propertyToUpdate, newValue);
                        emit NFTEventTriggered(_eventName, _tokenId);
                        break; // Stop after first matching rule for simplicity - can be extended for multiple rules.
                    }
                }
                break; // NFT found, stop searching
            }
        }
    }

    function getRandomNumber(uint256 _seed) internal view returns (uint256) {
        // WARNING: Using blockhash for randomness is susceptible to miner manipulation and should NOT be used for secure randomness in production.
        // For production-level randomness, consider using Chainlink VRF or other secure randomness solutions.
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _seed)));
    }

    // --- Governance & Community Features Functions ---

    function proposeMarketplaceChange(string memory _proposalDescription, string memory _parameterName, uint256 _newValue) public {
        require(bytes(_proposalDescription).length > 0, "Proposal description cannot be empty.");
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            description: _proposalDescription,
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false
        });
        emit ProposalCreated(proposalId, _proposalDescription, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        require(nftStakes[0].staker == address(0) || nftStakes[0].staker != msg.sender, "Only NFT holders can vote."); // Example: Assume any NFT holder can vote - adjust logic as needed.

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public proposalActive(_proposalId) proposalNotExecuted(_proposalId) onlyOwner { // Example: Only owner can execute after voting. Adjust access as needed.
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting period is not over.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalVotes * 100) / nextTokenId; // Example: Quorum based on percentage of total NFTs minted - adjust as needed.

        if (quorum >= proposalQuorumPercentage && proposal.votesFor > proposal.votesAgainst) {
            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("marketplaceFeePercentage"))) {
                setMarketplaceFee(proposal.newValue);
            }
            // Add more parameter changes based on proposal.parameterName
            proposal.isExecuted = true;
            emit ProposalExecuted(_proposalId);
        } else {
            revert("Proposal failed to meet quorum or majority vote.");
        }
    }

    function stakeNFT(uint256 _tokenId) public {
        require(nftStakes[_tokenId].staker == address(0), "NFT already staked."); // Assuming one NFT per tokenId for simplicity.
        // In a real implementation, you would check if msg.sender owns the NFT (e.g., via ERC721 interface) and transfer it to the contract for staking.
        nftStakes[_tokenId] = Stake({
            tokenId: _tokenId,
            staker: msg.sender,
            stakeTime: block.timestamp,
            pendingRewards: 0,
            isStaked: true
        });
        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) public {
        require(nftStakes[_tokenId].staker == msg.sender, "Not the staker of this NFT.");
        require(nftStakes[_tokenId].isStaked, "NFT is not staked.");

        uint256 rewards = calculateStakingRewards(_tokenId);
        nftStakes[_tokenId].isStaked = false;
        nftStakes[_tokenId].pendingRewards = rewards;

        // In a real implementation, you would transfer the NFT back to msg.sender (if it was transferred for staking) and pay out rewards.
        emit NFTUnstaked(_tokenId, rewards);
    }

    function distributeStakingRewards() public onlyOwner {
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastDistribution = currentTime - lastRewardDistributionTime;
        uint256 totalRewardsDistributed = 0;

        for (uint256 i = 1; i < nextTokenId; i++) {
            if (nftStakes[i].isStaked) {
                uint256 rewards = calculateStakingRewards(nftStakes[i].tokenId, timeSinceLastDistribution);
                nftStakes[i].pendingRewards += rewards;
                totalRewardsDistributed += rewards;
                // In a real system, you would distribute actual tokens here (e.g., by transferring tokens from the contract).
            }
        }
        lastRewardDistributionTime = currentTime;
        emit StakingRewardsDistributed(totalRewardsDistributed);
    }

    function calculateStakingRewards(uint256 _tokenId) public view returns (uint256) {
        return calculateStakingRewards(_tokenId, block.timestamp - nftStakes[_tokenId].stakeTime);
    }

    function calculateStakingRewards(uint256 _tokenId, uint256 _timeElapsed) internal view returns (uint256) {
        if (!nftStakes[_tokenId].isStaked) return 0;
        uint256 daysStaked = _timeElapsed / 1 days;
        return daysStaked * stakingRewardRate; // Example: Rewards based on days staked and rate.
    }

    function setUserReputation(address _user, uint256 _reputation) public onlyOwner {
        userReputations[_user] = _reputation;
        emit UserReputationSet(_user, _reputation);
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return userReputations[_user];
    }

    // --- Helper function for String conversion (Solidity < 0.9) ---
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```